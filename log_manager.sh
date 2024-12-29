#!/bin/bash

SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

source "$SCRIPT_DIR/log_manager.conf"

function print_help {
    echo "Usage: log_manager.sh -d <scan_directory> -l <line_threshold> -b <backup_directory>"
    echo "Options:"
    echo "  -d <scan_directory>    Directory to scan for log files."
    echo "  -l <line_threshold>    Threshold of lines in log file (must be > 0)."
    echo "  -b <backup_directory>  Directory to save backup files."
    echo "  -a                     Enable deep scan (include subdirectories)."
    echo "  -r                     Remove original log files after backup."
    echo "  -h                     Display this help message."
    echo ""
    echo "Examples:"
    echo "  ./log_manager.sh -d /var/logs -l 10000 -b /backup/logs"
    echo "  ./log_manager.sh -d /var/logs/system.log -l 5000 -b /backup/logs -r"
    exit 1
}

function create_backup_directory {
    mkdir -p "$1" || {
        echo "Failed to create backup directory: $1"
        exit 1
    }
}

function validate_input_params {
    if [ ! -e "$1" ]; then
        echo "Error: '$1' does not exist."
        exit 1
    fi

    if [ ! -d "$2" ]; then
        echo "Backup directory '$2' does not exist. Creating it..."
        create_backup_directory "$2"
    fi

    if ! [[ "$3" =~ ^[0-9]+$ ]] || [[ "$3" -le 0 ]]; then
        echo "Error: Line threshold must be a positive number."
        exit 1
    fi
}

function log_file_result {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1 $2 $3 $4" >> "$LOG_FILE"
}

while getopts d:l:b:hao flag; do
    case "${flag}" in
    d) SCAN_DIRECTORY=${OPTARG} ;;
    l) LINE_THRESHOLD=${OPTARG} ;;
    b) BACKUP_DIRECTORY=${OPTARG} ;;
    a) DEEP_SCAN=true ;;
    r) REMOVE_ORIGINAL=true ;;
    h) print_help ;;
    esac
done

validate_input_params $SCAN_DIRECTORY $BACKUP_DIRECTORY $LINE_THRESHOLD

if [ -f "$SCAN_DIRECTORY" ]; then
    FILES=("$SCAN_DIRECTORY")
elif [ "$DEEP_SCAN" = true ]; then
    FILES=($(find "$SCAN_DIRECTORY" -type f -iname "*.log" -print0 | xargs -0))
else
    FILES=($(find "$SCAN_DIRECTORY" -maxdepth 1 -type f -iname "*.log" -print0 | xargs -0))
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No log files found in $SCAN_DIRECTORY"
    exit 1
fi

for file in "${FILES[@]}"; do
    mkdir -p "$TEMP_DIRECTORY" || {
        echo "Failed to create temporary directory"
        exit 1
    }
    LINE_COUNT=$(wc -l <"$file")
    FILE_NAME=$(basename "$file" .log)
    BACKUP_FILE="$BACKUP_DIRECTORY/${FILE_NAME}_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo "Processing $file with $LINE_COUNT lines"

    split --additional-suffix=.log -d -l "$LINE_THRESHOLD" "$file" "$TEMP_DIRECTORY/${FILE_NAME}_part_" || {
        echo "Failed to split $file"
        echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: Failed to split $file" >> "$LOG_FILE"
        exit 1
    }

    tar -czf "$BACKUP_FILE" "$TEMP_DIRECTORY/"*.log || {
        echo "Failed to create backup archive"
        echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: Failed to create backup for $file" >> "$LOG_FILE"
        exit 1
    }

    log_file_result "$file" "$BACKUP_FILE" "$LINE_COUNT" "$(ls "$TEMP_DIRECTORY" | wc -l)"

    mv "$TEMP_DIRECTORY" "$FILE_PATH/${FILE_NAME}_$(date +%Y%m%d_%H%M%S)" || {
        echo "Failed to move $file"
        exit 1
    }

    if [ "$REMOVE_ORIGINAL" = true ]; then
        rm "$file" || echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: Failed to remove $file" >> "$LOG_FILE"
    fi
done
