#!/bin/bash
[ ! -e /bin/systemctl ] && sudo -S ln -s /bin/true /bin/systemctl

cd ~ || exit
[ ! -d ~/klipper_config ] && mkdir klipper_config
[ ! -d ~/klipper_logs ] && mkdir klipper_logs
[ ! -d ~/gcode_files ] && mkdir gcode_files
[ ! -d ~/webcam_images ] && mkdir webcam_images
[ ! -d ~/.moonraker_database ] && mkdir .moonraker_database

if find ~/klipper_config -type d -empty; then
  cd ~/example-configs || exit 1
  sudo cp -r ./* ~/klipper_config
fi

if find ~/webcam_images -type d -empty; then
  cd ~/mjpg_streamer_images || exit 1
  sudo cp -r ./* ~/webcam_images
fi

sudo chown -R printer:printer ~/klipper_config
sudo chown -R printer:printer ~/klipper_logs
sudo chown -R printer:printer ~/gcode_files
sudo chown -R printer:printer ~/webcam_images
sudo chown -R printer:printer ~/.moonraker_database

sudo -S rm /bin/systemctl
sudo -S ln -s /bin/service_control /bin/systemctl

cd ~ && echo "Everything is ready ... Starting ..."
/usr/bin/supervisord