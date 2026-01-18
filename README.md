# Antigravity Sandbox in Docker

This project provides a containerized development environment for Antigravity, built on top of a Linux Webtop (Ubuntu XFCE). It allows you to run Antigravity in a docker sandboxed, desktop-accessible container.

## Features

- **XFCE Desktop Interface**: Accessible through a browser on port 3000.
- **Antigravity Pre-installed**: Automatically installs the latest `antigravity` package from the official repository.
- **Persistent Storage**: Maps local `./config` directory for settings and code persistence.
- **Privileged Access**: Configured for system-level agent actions.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) must be installed and running on your machine.
    - [Install Docker Desktop on Windows](https://docs.docker.com/desktop/install/windows-install/)
    - [Install Docker Desktop on Mac](https://docs.docker.com/desktop/install/mac-install/)
    - [Install Docker Desktop on Linux](https://docs.docker.com/desktop/install/linux-install/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Getting Started

To build and start the sandbox, simply run the provided script:

```bash
chmod +x build-and-run.sh
./build-and-run.sh
```

Alternatively, you can use Docker Compose directly:

```bash
docker-compose up -d --build
```

Once the container is running, access the desktop UI at:
[http://localhost:3000](http://localhost:3000)

## Shutting Down the Sandbox

To stop the sandbox and remove the containers, run:

```bash
docker-compose down
```

This will stop the running services but will NOT delete your data in the `./config` directory, as it is persisted via volumes.

## Infrastructure Details

### Dockerfile Highlights
- **Base Image**: `lscr.io/linuxserver/webtop:ubuntu-xfce`
- **Package Management**: Adds the Antigravity APT repository and installs the `antigravity` package.
- **Environment**: Sets `APPIMAGE_EXTRACT_AND_RUN=1` to support containerized execution of AppImages.

### Compose Configuration
- **Container Name**: `antigravity-sandbox`
- **Privileged Mode**: `true` (Required for certain agent system actions).
- **Volumes**: `./config` is mounted to `/config` in the container.
- **Environment Variables**:
    - `PUID/PGID`: Set to `1000` for consistent file permissions.
    - `TZ`: Configured to `America/New_York` (EST/EDT).

## Persistence and Volumes

### Creating New Projects
Any new projects or files created inside the container's `/config` directory are automatically synchronized with your host's `./config` folder. This means you can use the containerized environment to develop, while your work remains safe on your local machine.

### Developing Existing Codebases
If you want to work on an existing project located elsewhere on your machine, you can mount it by adding a new volume entry to `compose.yml`:

1.  Open `compose.yml`.
2.  Add your host path and map it to a directory inside the container (e.g., under `/config/projects`).

```yaml
    volumes:
      - ./config:/config
      - /path/to/your/existing-project:/config/existing-project # Add this line
```

After modifying `compose.yml`, [shut down the sandbox](#shutting-down-the-sandbox) and then restart it:
```bash
./build-and-run.sh
```

