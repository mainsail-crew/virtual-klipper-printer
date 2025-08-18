[![License](https://img.shields.io/github/license/mainsail-crew/virtual-klipper-printer.svg)](https://github.com/mainsail-crew/virtual-klipper-printer/blob/master/LICENSE 'License')
---
# Virtual-Klipper-Printer

This project provides a Docker container that simulates a Klipper 3D printer,
allowing you to test and develop Klipper Components without needing a physical
printer. It also includes Moonraker, a dummy webcam, and a pre-configured
Klipper instance.

---

## Setup Instructions
There are two ways to set up the Virtual-Klipper-Printer. You can use the
pre-built Docker image from GitHub Container Registry or build the image
yourself using the provided Dockerfile.

### Prerequisites
* Docker and Docker Compose installed on your system (see
  [Docker Installation Guide](https://docs.docker.com/get-docker/))
* A terminal or command line interface to run Docker commands

### Option 1: Using Pre-built Docker Image (Recommended)
The recommended way to set up the Virtual-Klipper-Printer is to use the
pre-built Docker image available on GitHub Container Registry. This method is
simpler and faster, as it does not require building the image yourself.

1. Clone this repository
2. Open a terminal in the cloned folder
3. Run `docker compose up -d` to build the docker image and start the container
   in detached mode

### Option 2: Building the Docker Image Yourself
This option allows you to build the Docker image from the provided Dockerfile.
This is useful if you want to customize the image or if you prefer to build it
yourself. It's possible to change the Klipper Repo URL with this method. 

1. Clone this repository
2. Rename the `docker-compose.build.yml` file to `docker-compose.override.yml`
3. Edit the `docker-compose.override.yml` file to change the `KLIPPER_REPO_URL`
   variable to your desired Klipper repository URL (default is the official
   Klipper repository)
4. Open a terminal in the cloned folder
5. Run `docker compose up -d --build` to build the docker image and start the
   container in detached mode

---

## Configure a Dummy-Webcam
To configure a dummy-webcam, use the following URLs:
   * Stream: `http://localhost:8110/?action=stream`
   * Snapshot: `http://localhost:8110/?action=snapshot`

---

## Common Docker commands
* Get all container IDs: `docker ps -a`
* Get only the ID of running containers: `docker ps`
* Access a containers shell: `docker exec -it <CONTAINER ID> bash`
* Start/Restart/Stop a container: `docker container start/restart/stop <CONTAINER ID>`
* Remove a container: `docker container rm <CONTAINER ID>`
