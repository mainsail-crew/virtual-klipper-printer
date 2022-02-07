FROM python:3.10-slim-bullseye AS base
#FROM debian:bullseye-slim AS base

ARG libsim="http://download.savannah.nongnu.org/releases/simulavr/libsim_1.1.0_amd64.deb"

RUN apt-get update && apt-get install -y --no-install-recommends \
    # non specific packages
    git sudo swig wget supervisor virtualenv \
    # klipper
    avr-libc binutils-avr build-essential cmake gcc-avr \
    # moonraker
    python3-virtualenv python3-dev libopenjp2-7 python3-libgpiod \
    curl libcurl4-openssl-dev libssl-dev liblmdb-dev \
    libsodium-dev zlib1g-dev libjpeg-dev

RUN cd /usr/src \
    && wget ${libsim} \
    && apt-get install -y ./libsim_1.1.0_amd64.deb \
    && rm -f libsim_1.1.0_amd64.deb

### copy simulavr firmware config
COPY simulavr.config /usr/src

### add user "printer"
RUN groupadd --force -g 1000 printer \
    && useradd -rm -d /home/printer -g 1000 -u 1000 printer \
    && usermod -aG dialout,tty,sudo printer \
    && echo 'printer ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers.d/printer

### cleanup
RUN apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY start.sh /bin/start
RUN chmod +x /bin/start

USER printer
WORKDIR /home/printer

ENTRYPOINT ["/bin/start"]