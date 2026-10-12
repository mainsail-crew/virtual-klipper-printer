import os
import socket
import threading
import time

from .pin_handler import PinHandler
from .state_io import STATE_FILE_PATH, atomic_write_json, build_printer_state


class FakeHardwareServer:
    def __init__(
        self,
        hardware_components: list[PinHandler],
        socket_path: str = "/tmp/printer_hook.sock",
        state_file_path: str = STATE_FILE_PATH,
        min_state_write_interval: float = 0.2,
    ):
        self.hardware_components = hardware_components
        self.read_mapping: dict[str, PinHandler] = {}
        self.write_mapping: dict[str, PinHandler] = {}
        for component in hardware_components:
            for pin in component.read_pins:
                if pin in self.read_mapping:
                    raise ValueError(
                        f"Pin {pin} is already assigned to another component for reading!"
                    )
                self.read_mapping[pin] = component
            for pin in component.write_pins:
                if pin in self.write_mapping:
                    raise ValueError(
                        f"Pin {pin} is already assigned to another component for writing!"
                    )
                self.write_mapping[pin] = component
        self.socket_path = socket_path
        self.lock = threading.Lock()
        self.state_file_path = state_file_path
        self.min_state_write_interval = min_state_write_interval
        self._last_state_write_monotonic = 0.0

    def _dump_state(self, force: bool = False) -> None:
        current = time.monotonic()
        if (
            not force
            and (current - self._last_state_write_monotonic) < self.min_state_write_interval
        ):
            return
        atomic_write_json(self.state_file_path, build_printer_state(self.hardware_components))
        self._last_state_write_monotonic = current

    def set(self, key: str, value: int) -> None:
        """Set the value of a writable hardware pin.

        Parameters:
            key: The name or identifier of the hardware pin to update.
            value: The integer value to write to the specified pin.
        """
        with self.lock:
            if key in self.write_mapping:
                self.write_mapping[key].set(key, value)
                self._dump_state()
            else:
                print(f"[server] set unknown key: {key}={value}")

    def get(self, key: str) -> int:
        with self.lock:
            if key in self.read_mapping:
                value = self.read_mapping[key].get(key)
                self._dump_state()
                return value
            print(f"[server] get unknown key: {key}")
            return 0

    def _handle_client(self, conn):
        """Serve one connection; the hook keeps it open and sends one command per line.

        GET answers with the value, SET with OK, SETQ (quiet set, used for step pulses) not at all.
        SUB subscribes to a readable key: its value is sent at once as "VAL key value" and then
        again whenever it changes (after writes and by a periodic check for time-based values
        such as temperatures). The hook answers reads from these pushed values without waiting.
        """
        subscribed: dict[str, int] = {}
        send_lock = threading.Lock()
        alive = threading.Event()
        alive.set()

        def push_changes() -> None:
            for key, last in list(subscribed.items()):
                value = self.get(key)
                if value != last:
                    subscribed[key] = value
                    with send_lock:
                        conn.sendall(f"VAL {key} {value}\n".encode())

        def periodic() -> None:
            while alive.is_set():
                time.sleep(0.05)
                try:
                    push_changes()
                except OSError:
                    return

        threading.Thread(target=periodic, daemon=True).start()
        try:
            with conn, conn.makefile("rb") as lines:
                for raw in lines:
                    parts = raw.decode().split()
                    if not parts:
                        continue
                    if parts[0] == "GET" and len(parts) == 2:
                        with send_lock:
                            conn.sendall(f"{self.get(parts[1])}\n".encode())
                    elif parts[0] == "SUB" and len(parts) == 2:
                        value = self.get(parts[1])
                        subscribed[parts[1]] = value
                        with send_lock:
                            conn.sendall(f"VAL {parts[1]} {value}\n".encode())
                    elif parts[0] in ("SET", "SETQ") and len(parts) == 3:
                        self.set(parts[1], int(parts[2]))
                        if parts[0] == "SET":
                            with send_lock:
                                conn.sendall(b"OK\n")
                        if subscribed:
                            push_changes()
                    else:
                        with send_lock:
                            conn.sendall(b"ERR malformed command\n")
        except Exception as e:
            print(f"[server] error: {e}")
        finally:
            alive.clear()

    def run(self):
        if os.path.exists(self.socket_path):
            os.remove(self.socket_path)

        self._dump_state(force=True)
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(self.socket_path)
        server.listen(5)
        print(f"[server] listening on {self.socket_path}")

        while True:
            conn, _ = server.accept()
            threading.Thread(target=self._handle_client, args=(conn,), daemon=True).start()
