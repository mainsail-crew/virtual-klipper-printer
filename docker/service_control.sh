#!/bin/bash

if [ "$1" = "list-units" ]; then
        echo "klipper.service     loaded   active   running   Klipper Dummy Service"
        echo "moonraker.service   loaded   active   running   Moonraker Dummy Service"
        exit 0
fi

if [ "$2" = "klipper" ]; then
	sudo /usr/bin/supervisorctl "$1" simulavr "$2"
else
	sudo /usr/bin/supervisorctl "$1" "$2"
fi
