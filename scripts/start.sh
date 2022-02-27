#!/bin/bash
[ ! -e /bin/systemctl ] && sudo -S ln -s /bin/true /bin/systemctl

cd ~ || exit 1
[ ! -d ~/klipper_config ] && mkdir klipper_config
[ ! -d ~/klipper_logs ] && mkdir klipper_logs
[ ! -d ~/gcode_files ] && mkdir gcode_files

[ ! -f ~/klipper_config/printer.cfg ] && \
cp ~/example-configs/printer.cfg ~/klipper_config/printer.cfg
[ ! -f ~/klipper_config/moonraker.conf ] && \
cp ~/example-configs/moonraker.conf ~/klipper_config/moonraker.conf

sudo chown -R printer:printer ~/klipper_config
sudo chown -R printer:printer ~/klipper_logs
sudo chown -R printer:printer ~/gcode_files

sudo -S rm /bin/systemctl
sudo -S ln -s /bin/service_control /bin/systemctl

cd ~ && echo "Everything is ready ... Starting ..."
/usr/bin/supervisord