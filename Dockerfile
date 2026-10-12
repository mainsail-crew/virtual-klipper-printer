FROM python:3.12-slim-bookworm AS builder

RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    --no-install-suggests \
    ### non-specific packages \
    git swig virtualenv \
    ### klipper \
    build-essential cmake libcurl4-openssl-dev \
    libssl-dev libffi-dev python3-dev python3-libgpiod python3-distutils \
    g++ make python3-wheel-whl \
    ### \
    && pip install setuptools \
    ### clean up \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

WORKDIR /home/printer

### Prepare our applications
#### Klipper
ARG KLIPPER_REPO=https://github.com/Klipper3d/klipper.git
ENV KLIPPER_REPO=${KLIPPER_REPO}
RUN git clone --depth 1 ${KLIPPER_REPO} /home/printer/klipper \
    && virtualenv -p /usr/local/bin/python3 /home/printer/python-env \
    && /home/printer/python-env/bin/pip install --no-cache-dir -r /home/printer/klipper/scripts/klippy-requirements.txt

#### Build Firmware
COPY config/linux.config /home/printer/klipper/.config
    # Build the firmware
RUN cd /home/printer/klipper \
    && make \
    && mkdir -p /home/printer/klipper_out \
    && cp out/klipper.elf /home/printer/klipper_out \
    && cp out/klipper.dict /home/printer/klipper_out \
    && rm -f .config \
    && make clean

#### Moonraker
RUN git clone --depth 1 https://github.com/Arksine/moonraker \
    && /home/printer/python-env/bin/pip install --no-cache-dir -r /home/printer/moonraker/scripts/moonraker-requirements.txt

#### Moonraker Timelapse
RUN git clone https://github.com/mainsail-crew/moonraker-timelapse

#### MJPG-Streamer
RUN git clone --depth 1 https://github.com/jacksonliam/mjpg-streamer \
    && cd mjpg-streamer \
    && cd mjpg-streamer-experimental \
    && mkdir _build \
    && cd _build \
    && cmake -DPLUGIN_INPUT_HTTP=OFF -DPLUGIN_INPUT_UVC=OFF -DPLUGIN_OUTPUT_FILE=OFF -DPLUGIN_OUTPUT_RTSP=OFF -DPLUGIN_OUTPUT_UDP=OFF .. \
    && cd .. \
    && make \
    && rm -rf _build

# split of package installation and code for better caching
COPY printer_simulator/requirements.txt /home/printer/printer_simulator/requirements.txt
RUN /home/printer/python-env/bin/pip install --no-cache-dir -r /home/printer/printer_simulator/requirements.txt
COPY printer_simulator /home/printer/printer_simulator
RUN cd /home/printer/printer_simulator && make

## --------- This is the runner image

FROM python:3.12-slim-bookworm AS runner
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    --no-install-suggests \
    ### non-specific packages \
    git \
    supervisor \
    sudo \
    ### moonraker \
    libopenjp2-7 \
    libsodium-dev \
    zlib1g-dev \
    libjpeg-dev \
    curl \
    iproute2 \
    ### klipper c_helper.so dependencies \
    gcc \
    ### clean up \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN groupadd --force -g 1000 printer \
    && useradd -rm -d /home/printer -g 1000 -u 1000 printer \
    && usermod -aG dialout,tty,sudo printer \
    && echo 'printer ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers.d/printer

### copy all required files
COPY config/supervisord.conf /etc/supervisor/supervisord.conf
COPY scripts/start.sh /bin/start
COPY scripts/service_control.sh /bin/service_control

### make entrypoint executable
RUN chmod +x /bin/start
RUN chmod +x /bin/service_control

USER printer
WORKDIR /home/printer

# Copy our prebuilt applications from the builder stage
COPY --from=builder --chown=printer:printer /home/printer/python-env ./python-env
COPY --from=builder --chown=printer:printer /home/printer/klipper/ ./klipper/
COPY --from=builder --chown=printer:printer /home/printer/moonraker ./moonraker
COPY --from=builder --chown=printer:printer /home/printer/moonraker-timelapse ./moonraker-timelapse
COPY --from=builder --chown=printer:printer /home/printer/klipper_out/ ./klipper/out/
COPY --from=builder --chown=printer:printer /home/printer/mjpg-streamer/mjpg-streamer-experimental ./mjpg-streamer
COPY --from=builder --chown=printer:printer /home/printer/printer_simulator/ ./printer_simulator/

# Copy example configs and dummy streamer images
COPY --chown=printer:printer ./example-configs/ ./example-configs/
# copy one image as placeholder
COPY --chown=printer:printer ./mjpg_streamer_images/image0.jpg ./mjpg_streamer_images/image0.jpg

USER printer
ENTRYPOINT ["/bin/start"]
