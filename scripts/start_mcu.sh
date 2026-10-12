#!/usr/bin/env bash
# Starts the Linux MCU and gives it realtime priority (SCHED_FIFO) if the container allows it
# (docker run --cap-add SYS_NICE). Without realtime scheduling the MCU process can be delayed
# by the host and shuts down with "Stepper too far in past".
# klipper.elf -r would try this itself, but the MCU runs as user "printer" and exits on EPERM.
sleep 10
/home/printer/klipper/out/klipper.elf &
pid=$!
if sudo -n chrt -f -p 50 "$pid" 2>/dev/null; then
  echo "klipper_mcu: realtime priority SCHED_FIFO 50"
else
  echo "klipper_mcu: no realtime priority (start the container with --cap-add SYS_NICE)"
fi
trap 'kill "$pid" 2>/dev/null' TERM INT
wait "$pid"
