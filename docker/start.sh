#!/bin/bash
sudo -S ln -s /bin/true /bin/systemctl

klipper_git="https://github.com/klipper3d/klipper"
klipper_branch="master"
moonraker_git="https://github.com/Arksine/moonraker"
moonraker_branch="master"
simulavr_git="https://git.savannah.nongnu.org/git/simulavr.git"
simulavr_cfg="/usr/src/simulavr.config"

cd ~ || exit 1
[ ! -d ~/klipper_config ] && mkdir klipper_config
[ ! -d ~/klipper_logs ] && mkdir klipper_logs
[ ! -d ~/gcode_files ] && mkdir gcode_files

setup_klipper(){
    [ -d ~/klipper ] && return
    echo "##### Cloning Klipper ..."
    git clone $klipper_git --single-branch --branch ${klipper_branch}
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
    git clone $moonraker_git --single-branch --branch ${moonraker_branch}
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
    [ -d ~/simulavr/build ] && return
    echo "##### Building Simulavr ..."
    cd ~/simulavr || exit 1
    make clean && make python && make build
    echo "##### Done!"
}

setup_klipper
build_klipper_env
setup_moonraker
build_moonraker_env
build_firmware
setup_simulavr
build_simulavr

sudo -S rm /bin/systemctl
sudo -S ln -s /usr/bin/supervisorctl /bin/systemctl

cd ~ && echo "Everything is ready ... Starting ..."
/usr/bin/supervisord