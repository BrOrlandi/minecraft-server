#!/bin/bash

# Exit script if any command fails
set -e

# Display Help
Help() {
  echo
  echo "docker-volume-backup"
  echo "####################"
  echo
  echo "Description: Backup docker volumes, including named volumes and bind mounts."
  echo "Syntax: docker-volume-backup [-v|-a|-o|-c|help]"
  echo "Example: docker-volume-backup -v postgres_data01 -o /tmp -c postgres01"
  echo "options:"
  echo "  -v    Comma-separated list of volume names or paths."
  echo "  -a    Backup all volumes (named or bind mounts) from the container."
  echo "  -o    Output directory. Defaults to '/var/tmp'."
  echo "  -c    Docker container name."
  echo "  -r    Clear output directory? true/false (default: false)."
  echo "  -d    Delete files older than this many days (set 0 to keep all)."
  echo "  help  Show docker-volume-backup manual."
}

# Show help and exit
if [[ $1 == 'help' ]]; then
    Help
    exit
fi

# Initialize variables
ALL='false'
DIR='/var/tmp'
CLEAR='false'
DAYSBACK=0

# Process params
while getopts ":ac:v:o:r:d:" opt; do
  case $opt in
    a) ALL='true'
    ;;
    c) CONTAINER="$OPTARG"
    ;;
    v) VOLUMES="$OPTARG"
    ;;
    o) DIR="$OPTARG"
    ;;
    r) CLEAR="$OPTARG"
    ;;
    d) DAYSBACK="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
  esac
done

echo "Backup started at $(date '+%Y-%m-%d %H:%M:%S')"
echo "Backup parameters:"
echo "  Volumes: $VOLUMES"
echo "  All volumes: $ALL"
echo "  Output directory: $DIR"
echo "  Container: $CONTAINER"
echo "  Clear output directory: $CLEAR"
echo "  Delete files older than: $DAYSBACK days"


# Verify required parameters
if [[ -z "$VOLUMES" && "$ALL" != "true" ]]; then
    echo "Error: Parameter -v (volumes) or -a (all) must be set."
    exit 1
fi

if [[ -z "$DIR" ]]; then
    echo "Error: Parameter -o (output directory) is empty."
    exit 1
fi

if [[ -z "$CONTAINER" ]]; then
    echo "Error: Parameter -c (container name) is empty."
    exit 1
fi

# Normalize output directory path and create it if necessary
DIR=$(realpath "$DIR")
mkdir -p "$DIR/$CONTAINER"

# Delete files older than specified days, if applicable
if (( DAYSBACK > 0 )) ; then
    find "${DIR}/${CONTAINER}" -type f -mtime +$DAYSBACK -delete || true
fi

# Cleanup backup folder if requested
if [[ "$CLEAR" == 'true' ]]; then
    rm -rf "${DIR}/${CONTAINER:?}"/*
fi

# Handle '-a' option to get all volumes (named or bind mounts) from the container
if [[ "$ALL" == 'true' ]]; then
    # Extract both named volumes and bind mounts using docker inspect
    VOLUME_LIST=($(docker inspect --format '{{ range .Mounts }}{{ .Source }} {{ end }}' "$CONTAINER"))

    if [[ ${#VOLUME_LIST[@]} == 0 ]]; then
        echo "Error: No volumes or bind mounts found for container $CONTAINER or container does not exist."
        exit 1
    fi
else
    # Split provided volume names/paths into an array
    IFS=',' read -r -a VOLUME_LIST <<< "$VOLUMES"
fi

# Backup each volume or bind mount path
for VOLUME in "${VOLUME_LIST[@]}"; do
    # Determine if it's a named volume or a bind mount path by checking its existence on the host system.
    if docker volume inspect "$VOLUME" &>/dev/null; then
        # Named volume case:
        echo "Backing up named Docker volume $VOLUME..."
        docker run --rm \
            --volume "$VOLUME:/_data" \
            --volume "${DIR}/${CONTAINER}:/backup" \
            ubuntu tar cf "/backup/${VOLUME}_$(date '+%Y-%m-%d_%H%M%S').tar" /_data || {
                echo "Error backing up named volume $VOLUME."
                exit 1
            }
    elif [[ -d "$VOLUME" || -f "$VOLUME" ]]; then
        # Bind mount case:
        BASENAME=$(basename "$VOLUME")
        echo "Backing up bind mount path $VOLUME..."
        tar cf "${DIR}/${CONTAINER}/${BASENAME}_$(date '+%Y-%m-%d_%H%M%S').tar" -C "$(dirname "$VOLUME")" "$(basename "$VOLUME")" || {
            echo "Error backing up bind mount path $VOLUME."
            exit 1
        }
    else
        # Unknown case:
        echo "Warning: Skipping unknown volume or path $VOLUME. It does not exist as a named volume or valid host path."
        continue
    fi
done

# Notify if backup has finished successfully.
echo "The Docker volume backup has finished. Files are located in: ${DIR}/${CONTAINER}/"
