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

### setup klipper
if [ ! -d ~/klipper ]; then
    echo "##### Cloning Klipper ..."
    git clone $klipper_git --single-branch --branch ${klipper_branch}
    echo "##### Done!"
else
    echo "##### Klipper found! Continue ..."
fi

### build klippy-env
if [ ! -d ~/klippy-env ]; then
    echo "##### Building Klipper virtualenv ..."
    virtualenv -p python3 ~/klippy-env
    ~/klippy-env/bin/pip install -r ~/klipper/scripts/klippy-requirements.txt
    echo "##### Done!"
else
    echo "##### Klipper virtualenv found! Continue ..."
fi

### setup moonraker
if [ ! -d ~/moonraker ]; then
    echo "##### Cloning Moonraker ..."
    git clone $moonraker_git --single-branch --branch ${moonraker_branch}
    echo "##### Done!"
else
    echo "##### Moonraker found! Continue ..."
fi

### build moonraker-env
if [ ! -d ~/moonraker-env ]; then
    echo "##### Building Moonraker virtualenv ..."
    virtualenv -p python3 ~/moonraker-env
    ~/moonraker-env/bin/pip install -r ~/moonraker/scripts/moonraker-requirements.txt
    echo "##### Done!"
else
    echo "##### Moonraker virtualenv found! Continue ..."
fi

### build simulavr firmware
if [ ! -f ~/klipper/simulavr.elf ]; then
    echo "##### Building Klipper firmware ..."
    cd ~/klipper || exit 1
    cp $simulavr_cfg .config && make PYTHON=python3
    cp out/klipper.elf simulavr.elf
    rm -f .config && make clean
    cd ~ || exit 1
    echo "##### Done!"
else
    echo "##### Klipper firmware already built! Continue ..."
fi

### setup simulavr
if [ ! -d ~/simulavr ]; then
    echo "##### Cloning Simulavr ..."
    git clone $simulavr_git
    echo "##### Done!"
else
    echo "##### Simulavr found! Continue ..."
fi

## build simulavr python module
if [ ! -d ~/simulavr/build ]; then
    echo "##### Building Simulavr ..."
    cd ~/simulavr || exit 1
    make clean && make python && make build
    echo "##### Done!"
else
    echo "##### Simulavr already built! Continue ..."
fi

sudo -S rm /bin/systemctl
sudo -S ln -s /usr/bin/supervisorctl /bin/systemctl

cd ~ && echo "Everything is ready ... Starting ..."
/usr/bin/supervisord