FROM python:3.10-slim-bullseye AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    ### non specific packages
    git \
    sudo \
    supervisor \
    swig \
    virtualenv \
    ### klipper
    avr-libc \
    binutils-avr \
    build-essential \
    cmake \
    gcc-avr \
    ### moonraker
    curl \
    libcurl4-openssl-dev \
    libjpeg-dev \
    liblmdb-dev \
    libopenjp2-7 \
    libsodium-dev \
    libssl-dev \
    python3-dev \
    python3-libgpiod \
    zlib1g-dev \
    ### clean up
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -f libsim_1.1.0_amd64.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    ### add user "printer"
    && groupadd --force -g 1000 printer \
    && useradd -rm -d /home/printer -g 1000 -u 1000 printer \
    && usermod -aG dialout,tty,sudo printer \
    && echo 'printer ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers.d/printer

### copy all required files
COPY simulavr.config /usr/src
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY service_control.sh /bin/service_control
COPY start.sh /bin/start

### make entrypoint executable
RUN chmod +x /bin/start

USER printer
WORKDIR /home/printer

ENTRYPOINT ["/bin/start"]