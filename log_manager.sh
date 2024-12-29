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
    echo "  -a - advanced scan mode (deep scan)"
    echo "  -r - remove original log file after backup"
    echo "  -h - display this help message"
    exit 1
}

function create_backup_directory {
    mkdir -p "$1" || {
        echo "Failed to create backup directory"
        exit 1
    }
}

function validate_input_params {
    if [ ! -d $1 ] && [ ! -f $1 ]; then
        TYPE="File"
        if [ -f $1 ]; then
            TYPE="Directory"
        fi
        echo "Error: $TYPE '$SCAN_DIRECTORY' does not exist"
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
    FILES=($(find "$SCAN_DIRECTORY" -type f -iname "*.log" -print0 2>/dev/null | xargs -0 -n 1 echo | uniq))
else
    FILES=($(find "$SCAN_DIRECTORY" -maxdepth 1 -type f -iname "*.log" -print0 2>/dev/null | xargs -0 -n 1 echo | uniq))
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
    FILE_PATH=$(dirname "$file")
    echo "Processing $file with $LINE_COUNT lines"
    split --additional-suffix=.log -d -l $LINE_THRESHOLD "$file" "${TEMP_DIRECTORY}/${FILE_NAME}_part_" || {
        echo "Failed to split $file"
        exit 1
    }
    tar -czf "$BACKUP_DIRECTORY/${FILE_NAME}_$(date +%Y%m%d_%H%M%S).tar.gz" $TEMP_DIRECTORY/*.log || {
        echo "Failed to create backup archive"
        exit 1
    }
    mv "$TEMP_DIRECTORY" "$FILE_PATH/${FILE_NAME}_$(date +%Y%m%d_%H%M%S)" || {
        echo "Failed to rename $file"
        exit 1
    }
    if [ "$REMOVE_ORIGINAL" = true ]; then
        rm "$file"
    fi
done
