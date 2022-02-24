FROM python:3.10-slim-bullseye AS builder

RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    --no-install-suggests \
    ### non specific packages
    git \
    sudo \
    swig \
    virtualenv \
    ### klipper
    avr-libc \
    binutils-avr \
    build-essential \
    cmake \
    gcc-avr \
    ### moonraker
    supervisor \
    curl \
    iproute2 \
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
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

WORKDIR /build

### Prepare our applications
#### Klipper
RUN git clone --depth=1 https://github.com/klipper3d/klipper && \
    rm -rf klipper/docs klipper/test klipper/.github && \
    virtualenv -p python3 /build/klippy-env && \
    /build/klippy-env/bin/pip install -r /build/klipper/scripts/klippy-requirements.txt && \
    rm -rf lib

#### Simulavr
COPY docker/simulavr.config /usr/src
RUN git clone -b master git://git.savannah.nongnu.org/simulavr.git && \
    # Build the firmware
    cd klipper && \
    cp /usr/src/simulavr.config .config && \
    make PYTHON=python3 && \
    cp out/klipper.elf /build/simulavr.elf && \
    rm -f .config && make PYTHON=python3 clean && \
    # Build simulavr
    cd ../simulavr && \
    make python && \
    make build && \
    make clean

#### Moonraker
RUN git clone --depth=1 https://github.com/Arksine/moonraker && \
    rm -rf moonraker/docs moonraker/tests moonraker/.github && \
    virtualenv -p python3 /build/moonraker-env && \
    /build/moonraker-env/bin/pip install -r /build/moonraker/scripts/moonraker-requirements.txt

## --------- This is the runner image

FROM python:3.10-slim-bullseye AS runner
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    --no-install-suggests \
    ### non specific packages
    git \
    supervisor \
    sudo \
    swig \
    ### moonraker
    curl \
    iproute2 \
    python3-libgpiod \
    libcurl4-openssl-dev \
    libjpeg-dev \
    liblmdb-dev \
    libopenjp2-7 \
    libsodium-dev \
    libssl-dev \
    ### clean up
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN groupadd --force -g 1000 printer \
    && useradd -rm -d /home/printer -g 1000 -u 1000 printer \
    && usermod -aG dialout,tty,sudo printer \
    && echo 'printer ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers.d/printer

### copy all required files
COPY docker/supervisord.conf /etc/supervisor/supervisord.conf
COPY docker/service_control.sh /bin/service_control
COPY docker/start.sh /bin/start

### make entrypoint executable
RUN chmod +x /bin/start

USER printer
WORKDIR /home/printer

# Copy our prebuilt applications from the builder stage
COPY --from=builder --chown=printer:printer /build/klippy-env ./klippy-env
COPY --from=builder --chown=printer:printer /build/klipper ./klipper
COPY --from=builder --chown=printer:printer /build/moonraker ./moonraker
COPY --from=builder --chown=printer:printer /build/moonraker-env ./moonraker-env
COPY --from=builder --chown=printer:printer /build/simulavr ./simulavr

COPY ./example-configs/ ./example-configs/

ENTRYPOINT ["/bin/start"]
