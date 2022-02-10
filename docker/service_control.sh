#!/bin/sh

if [ "$2" = "klipper" ]; then
	sudo /usr/bin/supervisorctl "$1" simulavr "$2"
else
	sudo /usr/bin/supervisorctl "$1" "$2"
fi
