#!/usr/bin/env bash
# backup.sh — Backs up the TurboMC world volume to S3-compatible storage via rclone.

# Exit immediately if any command fails (-e), treat unset variables as errors (-u),
# and ensure failures in pipelines are not masked (-o pipefail).
set -euo pipefail

# Require the RCLONE_REMOTE environment variable to be set. This should point to
# a pre-configured rclone remote and bucket path, e.g. "r2:mc-backups".
# The :? syntax causes the script to abort with the given message if the variable
# is unset or empty.
RCLONE_REMOTE="${RCLONE_REMOTE:?Set RCLONE_REMOTE (e.g. r2:mc-backups)}"

# Generate a UTC timestamp in ISO 8601 format with colons replaced by hyphens
# so the filename is safe on all filesystems (colons are illegal on Windows/NTFS).
# Example: 2026-04-05T12-30-00Z
TIMESTAMP=$(date -u +"%Y-%m-%dT%H-%M-%SZ")

# Build the archive filename using the timestamp for easy chronological sorting.
ARCHIVE="turbomc-world-${TIMESTAMP}.tar.gz"

# Spin up a throwaway Alpine container that mounts the mc-world Docker named volume
# at /data, then tar+gzip the entire contents and stream the archive to stdout.
# The output is redirected to a temp file on the host. Using --rm ensures the
# container is automatically removed after it exits.
docker run --rm -v mc-world:/data alpine tar czf - -C /data . > "/tmp/${ARCHIVE}"

# Upload the archive to the rclone remote. "copyto" copies a single file to an
# explicit destination path (as opposed to "copy" which treats the destination as
# a directory). This gives us full control over the remote filename.
rclone copyto "/tmp/${ARCHIVE}" "${RCLONE_REMOTE}/${ARCHIVE}"

# Remove the local temporary archive now that it has been successfully uploaded.
rm "/tmp/${ARCHIVE}"

# Print a confirmation message with the full remote path of the uploaded backup.
echo "Backup uploaded: ${RCLONE_REMOTE}/${ARCHIVE}"
