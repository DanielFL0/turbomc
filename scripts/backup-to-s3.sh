#!/bin/bash

set -euo pipefail

# Minecraft Server S3 Backup Script
# Backs up world and logs from Docker volumes and uploads to AWS S3

# Configuration
CONTAINER_NAME="${CONTAINER_NAME:-turbomc}"
S3_BUCKET="${S3_BUCKET:-}"
S3_PREFIX="${S3_PREFIX:-minecraft-backups}"
BACKUP_DIR="${BACKUP_DIR:-/tmp/minecraft-backup}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

# Check prerequisites
check_requirements() {
  if [ -z "$S3_BUCKET" ]; then
    error "S3_BUCKET environment variable not set"
    exit 1
  fi

  if ! command -v aws &> /dev/null; then
    error "AWS CLI is not installed. Install it from: https://aws.amazon.com/cli/"
    exit 1
  fi

  if ! command -v docker &> /dev/null; then
    error "Docker is not installed"
    exit 1
  fi

  log "Prerequisites check passed"
}

# Create backup directory
setup_backup_dir() {
  mkdir -p "$BACKUP_DIR"
  log "Using backup directory: $BACKUP_DIR"
}

# Backup function using docker cp
backup_from_container() {
  if ! docker ps --filter "name=$CONTAINER_NAME" --quiet | grep -q .; then
    warn "Container $CONTAINER_NAME is not running. Attempting to copy from volumes..."
    backup_from_volumes
    return
  fi

  log "Backing up world from running container..."
  docker cp "$CONTAINER_NAME:/minecraft/world" "$BACKUP_DIR/world" 2>/dev/null || {
    warn "Could not copy world from container, trying volumes..."
    backup_from_volumes
    return
  }

  log "Backing up logs from running container..."
  docker cp "$CONTAINER_NAME:/minecraft/logs" "$BACKUP_DIR/logs" 2>/dev/null || {
    warn "Could not copy logs from container"
  }
}

# Fallback backup from volumes
backup_from_volumes() {
  log "Attempting to copy from Docker volumes..."

  # Check if volumes exist
  if docker volume ls --quiet | grep -q "^mc-world$"; then
    log "Copying world volume..."
    docker run --rm \
      -v mc-world:/data \
      -v "$BACKUP_DIR":/backup \
      alpine cp -r /data /backup/world 2>/dev/null || {
      warn "Could not copy world volume"
    }
  else
    warn "mc-world volume not found"
  fi

  if docker volume ls --quiet | grep -q "^mc-logs$"; then
    log "Copying logs volume..."
    docker run --rm \
      -v mc-logs:/data \
      -v "$BACKUP_DIR":/backup \
      alpine cp -r /data /backup/logs 2>/dev/null || {
      warn "Could not copy logs volume"
    }
  else
    warn "mc-logs volume not found"
  fi
}

# Create archive
create_archive() {
  local timestamp
  timestamp=$(date '+%Y%m%d-%H%M%S')
  local archive_name="minecraft-backup-$timestamp.tar.gz"
  local archive_path="$BACKUP_DIR/$archive_name"

  log "Creating archive: $archive_name"

  if [ ! -d "$BACKUP_DIR/world" ] && [ ! -d "$BACKUP_DIR/logs" ]; then
    error "No data found to backup (world and logs directories missing)"
    return 1
  fi

  cd "$BACKUP_DIR"
  tar --ignore-failed-read -czf "$archive_name" world logs 2>/dev/null || {
    warn "Tar completed with warnings (some files may not have been readable)"
  }
  cd - > /dev/null

  if [ ! -f "$archive_path" ]; then
    error "Failed to create archive"
    return 1
  fi

  local size
  size=$(du -h "$archive_path" | cut -f1)
  log "Archive created: $size"
  echo "$archive_path"
}

# Upload to S3
upload_to_s3() {
  local archive_path=$1
  local archive_name
  archive_name=$(basename "$archive_path")
  local s3_path="s3://$S3_BUCKET/$S3_PREFIX/$archive_name"

  log "Uploading to S3: $s3_path"

  if aws s3 cp "$archive_path" "$s3_path" --region "$AWS_REGION"; then
    log "Upload successful"
    return 0
  else
    error "Upload failed"
    return 1
  fi
}

# Cleanup old backups
cleanup_old_backups() {
  log "Cleaning up backups older than $RETENTION_DAYS days..."

  aws s3api list-objects-v2 \
    --bucket "$S3_BUCKET" \
    --prefix "$S3_PREFIX/" \
    --query "Contents[?LastModified<='$(date -d "$RETENTION_DAYS days ago" -Iseconds)'].[Key]" \
    --output text \
    --region "$AWS_REGION" | \
  while read -r key; do
    if [ -n "$key" ]; then
      log "Deleting old backup: $key"
      aws s3 rm "s3://$S3_BUCKET/$key" --region "$AWS_REGION"
    fi
  done

  log "Cleanup complete"
}

# Cleanup local backup
cleanup_local() {
  log "Cleaning up local backup directory..."
  rm -rf "$BACKUP_DIR"
}

# Main execution
main() {
  log "Starting Minecraft server backup..."

  check_requirements
  setup_backup_dir

  begin_time=$(date +%s)

  backup_from_container
  archive_path=$(create_archive) || exit 1
  upload_to_s3 "$archive_path" || exit 1
  cleanup_old_backups
  cleanup_local

  end_time=$(date +%s)
  duration=$((end_time - begin_time))

  log "Backup completed successfully in ${duration}s"
}

# Run main function
main "$@"
