# Log Manager Script

`log_manager.sh` is a Bash script for managing log files. It allows scanning a specified directory, splitting large log files into parts, creating backups, and optionally deleting original files.

---

## Features

- **Directory scanning** to find log files.
- **Supports "deep scan"** for subdirectories (optional).
- **Splitting log files** into parts based on the number of lines.
- **Creating archives** for backup of processed files.
- **Automatic directory creation** for backups and temporary files.
- **Option to delete original files** after backup.

---

## Usage

### Syntax
`bash
log_manager.sh -d <scan_directory> -l <line_threshold> -b <backup_directory> [OPTIONS]
`

### Options
| Parameter | Description |
|-----------|-------------|
| `-d <scan_directory>` | Directory to scan for log files or a specific log file. |
| `-l <line_threshold>` | Number of lines in a file before splitting into parts. |
| `-b <backup_directory>` | Directory to store backup archives. |
| `-a` | Enable deep scanning of subdirectories (recursive log file search). |
| `-r` | Delete the original file after backup. |
| `-h` | Display help message. |

---

## Examples

### Basic Example
Scan the `logs/` directory, split files into parts with 1000 lines each, and save archives to `backup/`:
`bash
./log_manager.sh -d logs/ -l 1000 -b backup/
`

### Recursive Log Search
Scan all subdirectories within \`logs/\`:
`bash
./log_manager.sh -d logs/ -l 500 -b backup/ -a
`

### Delete Original Files After Backup
Split files, create an archive, and delete the original files:
`bash
./log_manager.sh -d logs/ -l 1000 -b backup/ -r
`

---

## Prerequisites

### Dependencies
- Bash (version 4.0 or newer).
- `realpath` for resolving absolute paths.
- `tar` for creating archives.
- `split` for splitting files.
- `xargs` for processing command results.

### Configuration File
The `log_manager.conf` file must be in the same directory as the script. It may contain additional configuration variables, such as:
`bash
TEMP_DIRECTORY="/tmp/log_manager"
`

---

## How It Works

1. The script verifies that the specified scan (`-d`) and backup (`-b`) directories exist.
2. It locates log files in the scan directory:
   - If deep scan (`-a`) is enabled, it searches all subdirectories.
3. It checks the number of lines in each log file:
   - If the line count exceeds the threshold (`-l`), the file is split into parts.
4. All log file parts are archived in the specified backup directory.
5. Optionally, the original file is deleted after archiving if `-r` is specified.

---

## License

This script is free to use and distribute. Use it at your own discretion and responsibility.

---

### Author
An Engineer who loves keeping logs organized. 😄
