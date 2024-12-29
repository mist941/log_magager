#!/bin/bash

SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

source "$SCRIPT_DIR/log_manager.conf"

function print_help {
    echo "Usage: log_manager.sh -d <scan_directory> -l <line_threshold> -b <backup_directory>"
    echo "Options:"
    echo "  -d <scan_directory> - directory to scan for log files"
    echo "  -l <line_threshold> - threshold of lines in log file"
    echo "  -b <backup_directory> - directory to backup log files"
    echo "  -h display this help message"
    exit 1
}

function create_backup_directory {
    mkdir -p "$1" || {
        echo "Failed to create backup directory"
        exit 1
    }
}

function validate_input_params {
    if [ ! -d $1 ]; then
        echo "Error: Directory '$SCAN_DIRECTORY' does not exist"
        exit 1
    fi

    if [ ! -d $2 ]; then
        echo "Backup directory '$2' does not exist. Creating it..."
        create_backup_directory $2
    fi

    if ! [[ $3 =~ ^[0-9]+$ ]] || [[ $3 -le 0 ]]; then
        echo "Error: Line threshold must be greater than 0"
        exit 1
    fi
}

while getopts d:l:b:h flag; do
    case "${flag}" in
    d) SCAN_DIRECTORY=${OPTARG} ;;
    l) LINE_THRESHOLD=${OPTARG} ;;
    b) BACKUP_DIRECTORY=${OPTARG} ;;
    h) print_help ;;
    esac
done

validate_input_params $SCAN_DIRECTORY $BACKUP_DIRECTORY $LINE_THRESHOLD

FILES=($(find "$SCAN_DIRECTORY" -type f -iname "*.log" 2>/dev/null))

echo "$FILES"

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No log files found in $SCAN_DIRECTORY"
    exit 1
fi
#
#for file in "${FILES[@]}"; do
#    echo "Found log file: $file"
#done
