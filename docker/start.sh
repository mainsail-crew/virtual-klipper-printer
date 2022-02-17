#!/bin/bash
[ ! -e /bin/systemctl ] && sudo -S ln -s /bin/true /bin/systemctl

klipper_git="https://github.com/klipper3d/klipper"
moonraker_git="https://github.com/Arksine/moonraker"
simulavr_git="git://git.savannah.nongnu.org/simulavr.git"
simulavr_cfg="/usr/src/simulavr.config"

printer_cfg="https://raw.githubusercontent.com/th33xitus/klipper-printer-simulavr-docker/master/example-configs/printer.cfg"
moonraker_conf="https://raw.githubusercontent.com/th33xitus/klipper-printer-simulavr-docker/master/example-configs/moonraker.conf"
atmega_cfg="https://raw.githubusercontent.com/th33xitus/klipper-printer-simulavr-docker/master/example-configs/atmega644p.cfg"

cd ~ || exit 1
[ ! -d ~/klipper_config ] && mkdir klipper_config
[ ! -d ~/klipper_logs ] && mkdir klipper_logs
[ ! -d ~/gcode_files ] && mkdir gcode_files

setup_klipper(){
    [ -d ~/klipper ] && return
    echo "##### Cloning Klipper ..."
    git clone $klipper_git
    echo "##### Done!"
}

build_klipper_env(){
    [ -d ~/klippy-env ] && return
    echo "##### Building Klipper virtualenv ..."
    virtualenv -p python3 ~/klippy-env
    ~/klippy-env/bin/pip install -r ~/klipper/scripts/klippy-requirements.txt
    echo "##### Done!"
}

setup_moonraker(){
    [ -d ~/moonraker ] && return
    echo "##### Cloning Moonraker ..."
    git clone $moonraker_git
    echo "##### Done!"
}

build_moonraker_env(){
    [ -d ~/moonraker-env ] && return
    echo "##### Building Moonraker virtualenv ..."
    virtualenv -p python3 ~/moonraker-env
    ~/moonraker-env/bin/pip install -r ~/moonraker/scripts/moonraker-requirements.txt
    echo "##### Done!"
}

build_firmware(){
    [ -f ~/simulavr.elf ] && return
    echo "##### Building Klipper firmware ..."
    [ ! -d ~/klipper ] && setup_klipper
    cd ~/klipper || exit 1
    cp $simulavr_cfg .config && make PYTHON=python3
    cp out/klipper.elf ~/simulavr.elf
    rm -f .config && make clean
    cd ~ || exit 1
    echo "##### Done!"
}

setup_simulavr(){
    [ -d ~/simulavr ] && return
    echo "##### Cloning Simulavr ..."
    git clone $simulavr_git
    echo "##### Done!"
}

build_simulavr(){
    file="${HOME}/simulavr/build/pysimulavr/_pysimulavr.*.so"
    # shellcheck disable=SC2086
    [ "$(ls $file  2> /dev/null)" ] && return
    echo "##### Building Simulavr ..."
    cd ~/simulavr || exit 1
    make clean && make python && make build
    echo "##### Done!"
}

download_configs(){
    cd ~/klipper_config || exit 1
    [ ! -f ~/klipper_config/printer.cfg ] && curl -O $printer_cfg
    [ ! -f ~/klipper_config/moonraker.conf ] && curl -O $moonraker_conf
    [ ! -f ~/klipper_config/atmega644p.cfg ] && curl -O $atmega_cfg
    cd ~ || exit 1
}

setup_klipper
build_klipper_env
setup_moonraker
build_moonraker_env
build_firmware
setup_simulavr
build_simulavr
download_configs

sudo -S rm /bin/systemctl
sudo -S ln -s /bin/service_control /bin/systemctl

cd ~ && echo "Everything is ready ... Starting ..."
/usr/bin/supervisord