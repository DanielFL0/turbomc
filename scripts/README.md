# Scripts

## backup.sh

Backs up the `mc-world` Docker volume to S3-compatible storage using [rclone](https://rclone.org/).

### Prerequisites

- **Docker** — used to read the world volume.
- **rclone** — used to upload the archive. Must be [installed](https://rclone.org/install/).

### Configuring rclone

A ready-to-use config template is provided at `scripts/rclone.conf.example`. Copy it to the default rclone config location and fill in your credentials:

```bash
mkdir -p ~/.config/rclone
cp scripts/rclone.conf.example ~/.config/rclone/rclone.conf
# Edit ~/.config/rclone/rclone.conf and replace the placeholder values
```

To find your credentials, go to the [Cloudflare dashboard](https://dash.cloudflare.com/) → **R2** → **Manage R2 API Tokens** and create an API token with Object Read & Write permissions. Your account ID is visible in the R2 overview page URL.

The remote name in the config file (`[r2]`) must match the prefix you use in `RCLONE_REMOTE` (e.g. `r2:mc-backups`).

Verify the remote is working before running the backup:

```bash
rclone lsd r2:
```

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
