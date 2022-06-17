#!/bin/bash
[ ! -e /bin/systemctl ] && sudo -S ln -s /bin/true /bin/systemctl

cd ~ || exit 1
[ ! -d ~/klipper_logs ] && mkdir klipper_logs
[ ! -d ~/gcode_files ] && mkdir gcode_files
[ ! -d ~/.moonraker_database ] && mkdir .moonraker_database

if [ ! -d ~/klipper_config ] || find ~/klipper_config -type d -empty; then
  cd ~/example-configs || exit 1
  cp -r ./* ~/klipper_config
fi

sudo chown -R printer:printer ~/klipper_config
sudo chown -R printer:printer ~/klipper_logs
sudo chown -R printer:printer ~/gcode_files
sudo chown -R printer:printer ~/.moonraker_database

sudo -S rm /bin/systemctl
sudo -S ln -s /bin/service_control /bin/systemctl

cd ~ && echo "Everything is ready ... Starting ..."
/usr/bin/supervisord