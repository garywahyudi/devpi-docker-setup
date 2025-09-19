# Devpi Docker Setup

A modular, Dockerized setup of **Devpi**, a private PyPI server.  
Includes automated initialization of users and indexes, persistent storage, and auto-restart.

## Features

- Configurable via `.env` file
- Automatically bootstraps root and default user/index
- Health check to ensure server is ready
- Persistent storage with Docker volumes
- Auto-restart on container crash or host reboot

## Getting Started

1. Copy the environment template:

```bash
cp .env.example .env
```

2. Edit .env to configure users, passwords, ports, etc.

Build the Docker Image
```bash
docker build -t devpi-server .
```

Run the Container
```bash
docker run -d \
  --name devpi-server \
  --restart unless-stopped \
  -p 3141:3141 \
  -v devpi-data:/data \
  --env-file .env \
  devpi-server
```

Verify
```bash
docker exec -it devpi-server devpi use http://127.0.0.1:3141
docker exec -it devpi-server devpi user -l
docker exec -it devpi-server devpi index -l
```

## Access Web UI
Open in browser:
```bash
http://localhost:3141
```
Login using the credentials from .env.
