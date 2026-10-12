// fake_hardware_bridge.c
//
// Compile: gcc -shared -fPIC -o fake_hardware_bridge.so fake_hardware_bridge.c -ldl
// Usage:   LD_PRELOAD=./fake_hardware_bridge.so ./klipper.elf
//
// Opens a Socket in FAKE_HARDWARE_SOCKET and listens for requests to simulate ADC and GPIO.
// default GPIO Value is 0, default ADC value is 0 (12-bit: 0-4095). Requests are simple text commands:
//   GET analogN          → N=0..7 for ADC, Response is ADC value (0-4095)
//   GET chipN_gpioM     → N=Chip-Number, M=Pin-Number, Response is 0 or 1
//   SET chipN_gpioM V   → N=Chip-Number, M=Pin-Number, V=0 or 1, sets the GPIO value
#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <linux/gpio.h>

#include <sys/socket.h>
#include <sys/un.h>
#define MAX_FAKE_FDS 128
#define SOCKET_PATH_ENV "FAKE_HARDWARE_SOCKET"
#define SOCKET_TIMEOUT_MS 100

/*
Bridge overrides syscalls like open, ioctl, pread, access and close to intercept calls to ADC and GPIO devices.
For ADC: when Klipper tries to open /sys/bus/iio/devices/iio:device0/in_voltageN_raw, we return a dummy fd and track it as an ADC channel
For GPIO: when Klipper tries to open /dev/gpiochipN, we return a dummy fd and track it as a GPIO chip. 
Then we handle ioctls to provide chip info, line info, and line handle requests, and we track line handles to simulate GPIO reads/writes.
*/
static int   (*real_open)(const char*, int, ...)   = NULL;
static int   (*real_close)(int)                    = NULL;
static int   (*real_ioctl)(int, unsigned long, ...) = NULL;
static int   (*real_access)(const char*, int)      = NULL;
static ssize_t (*real_pread)(int, void*, size_t, off_t) = NULL;

static void init_real_funcs(void) {
    if (!real_open)   real_open   = dlsym(RTLD_NEXT, "open");
    if (!real_close)  real_close  = dlsym(RTLD_NEXT, "close");
    if (!real_ioctl)  real_ioctl  = dlsym(RTLD_NEXT, "ioctl");
    if (!real_access) real_access = dlsym(RTLD_NEXT, "access");
    if (!real_pread)  real_pread  = dlsym(RTLD_NEXT, "pread");
}


// ─────────────────────────────────────────────────────────
// FD Tracking
// ─────────────────────────────────────────────────────────

typedef enum { FD_NONE, FD_ADC, FD_GPIO_CHIP, FD_GPIO_LINE } FdType;

typedef struct {
    int    fd;
    FdType type;
    int    channel;                      // ADC: Channel Number
    int    chip;                         // GPIO: Chip Number
    int    line_offsets[GPIOHANDLES_MAX]; // GPIO Line: which Pins
    int    num_lines;
} FakeFd;

static FakeFd fake_fds[MAX_FAKE_FDS];

static FakeFd *find_fake_fd(int fd) {
    for (int i = 0; i < MAX_FAKE_FDS; i++)
        if (fake_fds[i].type != FD_NONE && fake_fds[i].fd == fd)
            return &fake_fds[i];
    return NULL;
}

static FakeFd *alloc_fake_fd(int fd, FdType type) {
    for (int i = 0; i < MAX_FAKE_FDS; i++) {
        if (fake_fds[i].type == FD_NONE) {
            memset(&fake_fds[i], 0, sizeof(FakeFd));
            fake_fds[i].fd   = fd;
            fake_fds[i].type = type;
            return &fake_fds[i];
        }
    }
    return NULL;
}

static void free_fake_fd(int fd) {
    FakeFd *f = find_fake_fd(fd);
    if (f) f->type = FD_NONE;
}

static int make_dummy_fd(void) {
    return real_open("/dev/null", O_RDONLY);
}



// ─────────────────────────────────────────────────────────
// Socket Communication
// ─────────────────────────────────────────────────────────

static int socket_request(const char *request, char *response, size_t resp_size) {
    /*
    establishes a connection to the Python socket server and sends a request, then waits for a response.
    */
    const char *socket_path = getenv(SOCKET_PATH_ENV);
    if (!socket_path) return -1;

    int sock = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock < 0) return -1;

    struct sockaddr_un addr = {0};
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);

    if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(sock);
        return -1;
    }

    // Set timeout to prevent Klipper from blocking if Python doesn't respond
    struct timeval tv = { .tv_sec = 0, .tv_usec = SOCKET_TIMEOUT_MS * 1000 };
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    send(sock, request, strlen(request), 0);

    ssize_t n = recv(sock, response, resp_size - 1, 0);
    if (n > 0) response[n] = '\0';
    else response[0] = '\0';

    close(sock);
    return n > 0 ? 0 : -1;
}

static int read_value(const char *key, int fallback) {
    // Send a request to the Python socket server to read a value (ADC or GPIO) and return it as an integer.
    char request[64], response[32];
    snprintf(request, sizeof(request), "GET %s\n", key);

    if (socket_request(request, response, sizeof(response)) < 0)
        return fallback;

    return atoi(response);
}

static void write_value(const char *key, int value) {
    // Send a request to the Python socket server to write a value (for GPIO).
    char request[64], response[32];
    snprintf(request, sizeof(request), "SET %s %d\n", key, value);
    socket_request(request, response, sizeof(response));
}



// ─────────────────────────────────────────────────────────
// open()
// ─────────────────────────────────────────────────────────

int open(const char *path, int flags, ...) {
    init_real_funcs();
    mode_t mode = 0;
    if (flags & (O_CREAT | O_TMPFILE)) {
        va_list args;
        va_start(args, flags);
        mode = va_arg(args, mode_t);
        va_end(args);
    }

    // ADC: /sys/bus/iio/devices/iio:device0/in_voltageN_raw
    if (strstr(path, "in_voltage") && strstr(path, "_raw")) {
        int channel = 0;
        const char *p = strstr(path, "in_voltage");
        if (p) channel = atoi(p + strlen("in_voltage"));

        int fd = make_dummy_fd();
        if (fd < 0) return -1;
        FakeFd *f = alloc_fake_fd(fd, FD_ADC);
        if (!f) { real_close(fd); errno = ENOMEM; return -1; }
        f->channel = channel;
        fprintf(stderr, "[fake_hw] open ADC channel %d -> fd %d\n", channel, fd);
        return fd;
    }

    // GPIO: /dev/gpiochipN
    if (strstr(path, "/dev/gpiochip")) {
        int chip = 0;
        sscanf(path, "/dev/gpiochip%d", &chip);
        int fd = make_dummy_fd();
        if (fd < 0) return -1;
        FakeFd *f = alloc_fake_fd(fd, FD_GPIO_CHIP);
        if (!f) { real_close(fd); errno = ENOMEM; return -1; }
        f->chip = chip;
        fprintf(stderr, "[fake_hw] open gpiochip%d -> fd %d\n", chip, fd);
        return fd;
    }

    return real_open(path, flags, mode);
}

int open64(const char *path, int flags, ...) {
    mode_t mode = 0;
    if (flags & (O_CREAT | O_TMPFILE)) {
        va_list args;
        va_start(args, flags);
        mode = va_arg(args, mode_t);
        va_end(args);
    }
    return open(path, flags, mode);
}

// ─────────────────────────────────────────────────────────
// access() — Klipper checks if /dev/gpiochipN exists
// ─────────────────────────────────────────────────────────

int access(const char *path, int mode) {
    init_real_funcs();
    if (strstr(path, "/dev/gpiochip")) {
        fprintf(stderr, "[fake_hw] access(%s) -> OK\n", path);
        return 0;
    }
    return real_access(path, mode);
}

// ─────────────────────────────────────────────────────────
// pread() — Read ADC values when Klipper tries to read from the in_voltageN_raw files
// ─────────────────────────────────────────────────────────

ssize_t pread(int fd, void *buf, size_t count, off_t offset) {
    init_real_funcs();
    FakeFd *f = find_fake_fd(fd);
    if (f && f->type == FD_ADC) {
        char key[32];
        snprintf(key, sizeof(key), "analog%d", f->channel);
        int value = read_value(key, 0); // Default 0 für 12-bit ADC

        char tmp[32];
        int len = snprintf(tmp, sizeof(tmp), "%d\n", value);
        if (offset >= len) return 0;
        size_t n = (size_t)(len - offset) < count ? (size_t)(len - offset) : count;
        memcpy(buf, tmp + offset, n);
        fprintf(stderr, "[fake_hw] pread ADC channel %d = %d\n", f->channel, value);
        return (ssize_t)n;
    }
    return real_pread(fd, buf, count, offset);
}

// ─────────────────────────────────────────────────────────
// ioctl() — GPIO v1 ABI (used by Klipper)
// ─────────────────────────────────────────────────────────

int ioctl(int fd, unsigned long request, ...) {
    init_real_funcs();
    va_list args;
    va_start(args, request);
    void *arg = va_arg(args, void*);
    va_end(args);

    FakeFd *f = find_fake_fd(fd);
    if (!f) return real_ioctl(fd, request, arg);

    // ── Chip-Info ────────────────────────────────────────
    if (request == GPIO_GET_CHIPINFO_IOCTL) {
        struct gpiochip_info *info = (struct gpiochip_info *)arg;
        memset(info, 0, sizeof(*info));
        snprintf(info->name,  sizeof(info->name),  "gpiochip%d", f->chip);
        snprintf(info->label, sizeof(info->label), "fake-gpio%d", f->chip);
        info->lines = 64;
        fprintf(stderr, "[fake_hw] ioctl CHIPINFO chip%d\n", f->chip);
        return 0;
    }

    // ── Line-Info ────────────────────────────────────────
    if (request == GPIO_GET_LINEINFO_IOCTL) {
        struct gpioline_info *info = (struct gpioline_info *)arg;
        snprintf(info->name, sizeof(info->name), "gpio%u", info->line_offset);
        info->flags = 0;
        info->consumer[0] = '\0';
        return 0;
    }

    // ── Line handle request → return a new fd for the line ──
    if (request == GPIO_GET_LINEHANDLE_IOCTL) {
        struct gpiohandle_request *req = (struct gpiohandle_request *)arg;
        int line_fd = make_dummy_fd();
        if (line_fd < 0) { errno = ENOMEM; return -1; }
        FakeFd *lf = alloc_fake_fd(line_fd, FD_GPIO_LINE);
        if (!lf) { real_close(line_fd); errno = ENOMEM; return -1; }
        lf->chip      = f->chip;
        lf->num_lines = req->lines;
        for (int i = 0; i < (int)req->lines && i < GPIOHANDLES_MAX; i++)
            lf->line_offsets[i] = req->lineoffsets[i];
        req->fd = line_fd;
        fprintf(stderr, "[fake_hw] ioctl GET_LINEHANDLE lines=%d -> fd %d\n",
                req->lines, line_fd);
        return 0;
    }

    // ── read GPIO ─────────────────────────────────────────
    if (request == GPIOHANDLE_GET_LINE_VALUES_IOCTL) {
        struct gpiohandle_data *data = (struct gpiohandle_data *)arg;
        memset(data, 0, sizeof(*data));
        for (int i = 0; i < f->num_lines && i < GPIOHANDLES_MAX; i++) {
            char key[32];
            snprintf(key, sizeof(key), "chip%d_gpio%d", f->chip, f->line_offsets[i]);
            data->values[i] = read_value(key, 0) ? 1 : 0;
            fprintf(stderr, "[fake_hw] ioctl GET %s = %d\n", key, data->values[i]);
        }
        return 0;
    }

    // ── write GPIO ───────────────────────────────────────
    if (request == GPIOHANDLE_SET_LINE_VALUES_IOCTL) {
        struct gpiohandle_data *data = (struct gpiohandle_data *)arg;
        for (int i = 0; i < f->num_lines && i < GPIOHANDLES_MAX; i++) {
            char key[32];
            snprintf(key, sizeof(key), "chip%d_gpio%d", f->chip, f->line_offsets[i]);
            fprintf(stderr, "[fake_hw] ioctl SET %s = %d\n", key, data->values[i]);
            write_value(key, data->values[i]);
        }
        return 0;
    }

    // Unsupported ioctls on fake fds
    errno = ENOTTY;
    return -1;
}

// ─────────────────────────────────────────────────────────
// close()
// ─────────────────────────────────────────────────────────

int close(int fd) {
    init_real_funcs();
    free_fake_fd(fd);
    return real_close(fd);
}