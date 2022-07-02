[![License](https://img.shields.io/github/license/mainsail-crew/virtual-klipper-printer.svg)](https://github.com/mainsail-crew/virtual-klipper-printer/blob/master/LICENSE 'License')
[![Project Maintenance](https://img.shields.io/maintenance/yes/2022.svg)](https://github.com/mainsail-crew/virtual-klipper-printer 'GitHub Repository')
---
# Virtual-Klipper-Printer

### **Run a simulated Klipper 3D-Printer in a Docker container.**
---

### Setup Instructions:
1. Clone this repository
2. Open a terminal in the cloned folder
3. Run `docker-compose up -d` to build the docker image and start the container in detached mode

---

### Configure a Dummy-Webcam:
To configure a dummy-webcam, use the following URLs:
   * Stream: `http://localhost:8110/?action=stream`
   * Snapshot: `http://localhost:8110/?action=snapshot`

---

### Common Docker commands:
* Get all container IDs: `docker ps -a`
* Get only the ID of running containers: `docker ps`
* Access a containers shell: `docker exec -it <CONTAINER ID> bash`
* Start/Restart/Stop a container: `docker container start/restart/stop <CONTAINER ID>`
* Rebuild image, recreate and start container : `docker-compose up -d --build`

---
Current image size: 742.72 MB
