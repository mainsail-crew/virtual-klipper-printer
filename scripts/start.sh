#!/usr/bin/env bash

#=======================================================================#
# Copyright (C) 2022 mainsail-crew <https://github.com/mainsail-crew>   #
# Author: Dominik Willner <th33xitus@gmail.com>                         #
#                                                                       #
# This file is part of virtual-klipper-printer                          #
# https://github.com/mainsail-crew/virtual-klipper-printer              #
#                                                                       #
# This file may be distributed under the terms of the GNU GPLv3 license #
#=======================================================================#

set -e

REQUIRED_FOLDERS=(
  "${HOME}/printer_data"
  "${HOME}/printer_data/comms"
  "${HOME}/printer_data/config"
  "${HOME}/printer_data/logs"
  "${HOME}/printer_data/gcodes"
  "${HOME}/printer_data/webcam_images"
  "${HOME}/printer_data/timelapse"
  "${HOME}/printer_data/database"
)

# Which MCU the virtual printer runs: "linux" (Klipper Linux MCU + hardware simulator, default)
# or "avr" (Klipper AVR firmware in simulavr). Set it in docker-compose.yml or an .env file.
MCU_TYPE="${MCU_TYPE:-linux}"

function status_msg() {
  echo "###[$(date +%T)]: ${1}"
}

######
# Activate the supervisor programs for the selected MCU type
###
function select_mcu_type() {
  case "${MCU_TYPE}" in
    linux|avr) ;;
    *)
      status_msg "Unknown MCU_TYPE '${MCU_TYPE}', use 'linux' or 'avr'"
      exit 1
      ;;
  esac
  status_msg "MCU_TYPE=${MCU_TYPE}"
  sudo mkdir -p /etc/supervisor/conf.d
  sudo cp "/etc/supervisor/supervisor-mcu-${MCU_TYPE}.conf" /etc/supervisor/conf.d/mcu.conf
}

######
# Example configs matching the MCU type (pin names and serial port differ)
###
function example_config_dir() {
  if [[ ${MCU_TYPE} == "avr" ]]; then
    echo "${HOME}/example-configs-avr"
  else
    echo "${HOME}/example-configs"
  fi
}

######
# Test if all required folders exist if not create them and
# test for correct ownership of all required folders
###
function check_folder_perms_and_create() {
  status_msg "Check folders permissions ..."
  for folder in "${REQUIRED_FOLDERS[@]}"; do

    if [ ! -d "$folder" ]; then
        mkdir "$folder"
    fi

    if [[ $(stat -c "%U" "${folder}") != "printer" ]]; then
      status_msg "chown for user: 'printer' on folder: ${folder}"
      sudo chown printer:printer "${folder}"
    fi
  done
  status_msg "OK!"
}

######
# Copy example configs if ~/printer_data/config is empty
###
function copy_example_configs() {
  if [[ ! "$(ls -A "${HOME}/printer_data/config")" ]]; then
    status_msg "Directory ${HOME}/printer_data/config is empty!"
    status_msg "Copy example configs ..."
    cp -R "$(example_config_dir)"/* ~/printer_data/config
    status_msg "OK!"
  fi
}

######
# Warn if printer.cfg was made for the other MCU type (e.g. after switching MCU_TYPE)
###
function check_config_matches_mcu_type() {
  local cfg="${HOME}/printer_data/config/printer.cfg"
  local serial="/tmp/klipper_host_mcu"
  [[ ${MCU_TYPE} == "avr" ]] && serial="/tmp/pseudoserial"
  if [[ -f ${cfg} ]] && ! grep -q "^serial: *${serial}" "${cfg}"; then
    status_msg "WARNING: printer.cfg does not use 'serial: ${serial}' for MCU_TYPE=${MCU_TYPE}."
    status_msg "WARNING: It was probably made for the other MCU type, see $(example_config_dir)"
  fi
}

######
# Copy dummy images if ~/webcam_images is empty
###
function copy_dummy_images() {
  if [[ ! "$(ls -A "${HOME}/printer_data/webcam_images")" ]]; then
    status_msg "Directory ${HOME}/printer_data/webcam_images is empty!"
    status_msg "Copy dummy images ..."
    cp -R ~/mjpg_streamer_images/*.jpg ~/printer_data/webcam_images
    status_msg "OK!"
  fi
}

######
# Link moonraker-timelapse component to moonraker components
###
function link_timelapse() {
  local component_source="${HOME}/moonraker-timelapse/component/timelapse.py"
  local component_target="${HOME}/moonraker/moonraker/components/timelapse.py"
  local macro_source="${HOME}/moonraker-timelapse/klipper_macro/timelapse.cfg"
  local macro_target="${HOME}/printer_data/config/addons/timelapse.cfg"

  if [[ -f ${component_source} && ! -h ${component_target} ]]; then
    status_msg "Linking moonraker-timelapse component ..."
    ln -sf "${component_source}" "${component_target}"
    status_msg "OK!"
  fi

  if [[ -f ${macro_source} && ! -h ${macro_target} ]]; then
    status_msg "Linking timelapse.cfg ..."
    ln -sf "${macro_source}" "${macro_target}"
    status_msg "OK!"
  fi
}

#===================================================#
#===================================================#

[[ ! -e /bin/systemctl ]] && sudo -S ln -s /bin/true /bin/systemctl

check_folder_perms_and_create
select_mcu_type
copy_example_configs
check_config_matches_mcu_type
copy_dummy_images
link_timelapse

sudo -S rm /bin/systemctl
sudo -S ln -s /bin/service_control /bin/systemctl

cd ~ && status_msg "Everything is ready! Starting ..."
/usr/bin/supervisord
