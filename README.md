[![Project Maintenance](https://img.shields.io/maintenance/yes/2022.svg)](https://github.com/th33xitus/klipper-printer-simulavr-docker 'GitHub Repository')
[![License](https://img.shields.io/github/license/th33xitus/klipper-printer-simulavr-docker.svg)](https://github.com/th33xitus/klipper-printer-simulavr-docker/blob/master/LICENSE 'License')
---
# Klipper-Printer-Simulavr-Docker

### **Run a simulated Klipper 3D-Printer in a Docker container.**
---

## Getting started:
### 🔵 Part 1:
1. Clone this repository
2. Open a terminal in the cloned folder
3. Run `docker-compose up` to build the docker image and start the container

### 🟢 Part 2:
During the process a folder named `printer` will appear. Inside of that folder you will find commonly known folders like `klipper_config`, `klipper_logs` and `gcode_files`.

4. Copy all configuration files from the [example-configs](example-configs) to `printer/klipper_configs`
5. Restart the container
6. Done

Klipper, Moonraker and a simulated Atmel ATmega micro-controller now run inside of the Docker container and you can use it for whatever reason you decided to clone this repository 😄.

---

Feel free to contribute if you find solutions to make the docker image even smaller (~ 700 MB as of now) or provide ideas to generally improve this project.
