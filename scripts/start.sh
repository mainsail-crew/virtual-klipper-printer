#!/bin/bash
[ ! -e /bin/systemctl ] && sudo -S ln -s /bin/true /bin/systemctl

cd ~ || exit 1
[ ! -d ~/klipper_config ] && mkdir klipper_config
[ ! -d ~/klipper_logs ] && mkdir klipper_logs
[ ! -d ~/gcode_files ] && mkdir gcode_files

download_configs(){
    cd ~/klipper_config || exit 1
    [ ! -f ~/klipper_config/printer.cfg ] && cp /home/printer/example-configs/printer.cfg .
    [ ! -f ~/klipper_config/moonraker.conf ] && cp /home/printer/example-configs/moonraker.conf .
    cd ~ || exit 1
}

regain_ownership(){
    sudo chown -R printer:printer ~/klipper_config
    sudo chown -R printer:printer ~/klipper_logs
    sudo chown -R printer:printer ~/gcode_files
}

download_configs
regain_ownership

sudo -S rm /bin/systemctl
sudo -S ln -s /bin/service_control /bin/systemctl

cd ~ && echo "Everything is ready ... Starting ..."
/usr/bin/supervisord