[![Project Maintenance](https://img.shields.io/maintenance/yes/2022.svg)](https://github.com/th33xitus/klipper-printer-simulavr-docker 'GitHub Repository')
[![License](https://img.shields.io/github/license/th33xitus/klipper-printer-simulavr-docker.svg)](https://github.com/th33xitus/klipper-printer-simulavr-docker/blob/master/LICENSE 'License')
---
# Virtual-Klipper-Printer

### **Run a simulated Klipper 3D-Printer in a Docker container.**
---

### Instructions:
1. Clone this repository
2. Open a terminal in the cloned folder
3. Run `docker-compose up -d` to build the docker image and start the container afterwards in detached mode

---

Notes:
* The first start of the container will take a moment since all components have to be downloaded and/or compiled
* You can access the containers shell with the following command:\
`docker exec -it <CONTAINER ID> bash`
* You get the `<CONTAINER ID>` with the following command:\
`docker ps`
* Restart the container with:\
`docker container restart <CONTAINER ID>`



---
Klipper, Moonraker and a simulated Atmel ATmega micro-controller now run inside of the Docker container and you can use it for whatever reason you decided to clone this repository 😄.

The container is build in a way, that you are able to quickly "re-install" Klipper and Moonraker or can quickly re-build the python environments or the firmware if that is ever necessary. For that, simply delete the corresponding folder/file and restart the container and the required components will be "installed" again.

Feel free to contribute if you find solutions to make the docker image even smaller (~ 679 MB as of now) or provide ideas to generally improve this project.
