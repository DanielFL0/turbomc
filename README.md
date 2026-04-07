# turbomc

[![Build and Push](https://github.com/danielfl0/turbomc/actions/workflows/docker.yml/badge.svg)](https://github.com/danielfl0/turbomc/actions/workflows/docker.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-turbomc-blue)](https://github.com/danielfl0/turbomc/pkgs/container/turbomc)

Minecraft server for my friends and me.

Runs [PaperMC](https://papermc.io/) with [Geyser](https://geysermc.org/) (Bedrock support) inside Docker. Images are built and published to ghcr.io automatically on every push to `main`.

## Requirements

- A Linux VPS with Docker installed
- The commit SHA of the image you want to run (find it in the [Actions tab](../../actions) or with `git log --oneline`)

## 1. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
```

## 2. Pull the image

Use a version tag from the [Releases page](../../releases) (recommended) or a specific commit SHA from the [Actions tab](../../actions):

```bash
docker pull ghcr.io/danielfl0/turbomc:v1.0.0
```

## 3. Fix volume permissions

The server runs as a non-root user. Run this once before starting the container so it can write to its data volumes:

```bash
docker run --rm \
  -v mc-world:/minecraft/world \
  -v mc-world-nether:/minecraft/world_nether \
  -v mc-world-the-end:/minecraft/world_the_end \
  -v mc-logs:/minecraft/logs \
  alpine chown -R 999:999 /minecraft/world /minecraft/world_nether /minecraft/world_the_end /minecraft/logs
```

## 4. Run

```bash
docker run -d \
  --name turbomc \
  --restart unless-stopped \
  -p 25565:25565/tcp \
  -p 19132:19132/udp \
  -v mc-world:/minecraft/world \
  -v mc-world-nether:/minecraft/world_nether \
  -v mc-world-the-end:/minecraft/world_the_end \
  -v mc-logs:/minecraft/logs \
  ghcr.io/danielfl0/turbomc:v1.0.0
```

- Java Edition players connect on port `25565`
- Bedrock Edition players connect on port `19132`
- World data and logs persist in named Docker volumes across restarts and updates

If port `25565` is already in use, map to a different external port (players will need to specify it when connecting):

```bash
-p 25566:25565/tcp
```

## Updating

Pull the new version tag from the [Releases page](../../releases), stop the old container, and start a new one with the same volume flags. World data is preserved in the volumes.

```bash
docker pull ghcr.io/danielfl0/turbomc:v1.1.0
docker rm -f turbomc
docker run -d \
  --name turbomc \
  --restart unless-stopped \
  -p 25565:25565/tcp \
  -p 19132:19132/udp \
  -v mc-world:/minecraft/world \
  -v mc-world-nether:/minecraft/world_nether \
  -v mc-world-the-end:/minecraft/world_the_end \
  -v mc-logs:/minecraft/logs \
  ghcr.io/danielfl0/turbomc:v1.1.0
```

## Logs

```bash
docker logs -f turbomc
```

The container reports `health: starting` for up to 2 minutes on first boot while the world generates. It will switch to `healthy` once the server is accepting connections.
