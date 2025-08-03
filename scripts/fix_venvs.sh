#!/bin/bash

# This file is derived from:
# https://github.com/mainsail-crew/MainsailOS/blob/develop/modules/raspberry/files/postrename

# delete pycache (*.pyc files)
find "/home/printer/" -name "__pycache__" -type d -exec rm -rf {} +

venvs=(klippy-env moonraker-env)

for venv in "${venvs[@]}"; do
    # repair shebangs
    while IFS= read -r file ; do
        sed -i 's|/build/'"${venv}"'|/home/printer/'"${venv}"'|g' "${file}"
    done < <(grep -iR "/build/${venv}" "/home/printer/${venv}"/* | cut -d":" -f1)
done
