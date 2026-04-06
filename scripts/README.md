# Scripts

## backup.sh

Backs up the `mc-world` Docker volume to S3-compatible storage using [rclone](https://rclone.org/).

### Prerequisites

- **Docker** — used to read the world volume.
- **rclone** — used to upload the archive. Must be [installed](https://rclone.org/install/) and configured with at least one remote (`rclone config`).

### Usage

```bash
RCLONE_REMOTE=<remote:bucket> ./scripts/backup.sh
```

| Variable | Required | Description |
|---|---|---|
| `RCLONE_REMOTE` | Yes | rclone remote and path (e.g. `r2:mc-backups`, `s3:my-bucket/backups`) |

### Example

```bash
# Upload to a Cloudflare R2 bucket named "mc-backups"
RCLONE_REMOTE=r2:mc-backups ./scripts/backup.sh

# Upload to an AWS S3 bucket under a prefix
RCLONE_REMOTE=aws:my-bucket/minecraft ./scripts/backup.sh
```

The script produces an archive named `turbomc-world-<timestamp>.tar.gz` (e.g. `turbomc-world-2026-04-05T12-30-00Z.tar.gz`).

### Scheduling

To run backups automatically, add a cron entry:

```
0 */6 * * * RCLONE_REMOTE=r2:mc-backups /path/to/scripts/backup.sh
```

This example runs a backup every 6 hours.
