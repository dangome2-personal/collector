#!/bin/bash

################################################################################
# Service Request Monitor Script
# Purpose: Monitor /tmp/cisco/collector for new SR files and process them
# Version: 1.0.0
# Date: December 17, 2025
################################################################################

# Configuration
COLLECTOR_DIR="/tmp/cisco/collector"
PROCESSED_LOG="/tmp/cisco/collector/.processed_srs"
ERROR_LOG="/tmp/cisco/collector/.error_log"
ARCHIVE_DIR="/tmp/cisco/collector/archive"
LOCK_FILE="/tmp/cisco/collector/.sr_monitor.lock"
MAX_RETRIES=3
RETRY_DELAY=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# Function: log_message
# Purpose: Log messages with timestamps
################################################################################
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$ERROR_LOG"
}

################################################################################
# Function: acquire_lock
# Purpose: Prevent multiple instances from running simultaneously
################################################################################
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE")
        if ps -p "$lock_pid" > /dev/null 2>&1; then
            log_message "WARN" "Another instance is running (PID: $lock_pid)"
            return 1
        else
            log_message "INFO" "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
    return 0
}

################################################################################
# Function: release_lock
# Purpose: Remove lock file when done
################################################################################
release_lock() {
    rm -f "$LOCK_FILE"
}

################################################################################
# Function: initialize_directories
# Purpose: Create necessary directories and files
################################################################################
initialize_directories() {
    mkdir -p "$COLLECTOR_DIR" "$ARCHIVE_DIR"
    touch "$PROCESSED_LOG" "$ERROR_LOG"
    
    # Create logs directory required by msft_collector
    mkdir -p logs
    
    # Initialize git repo if not already initialized
    if [ ! -d "$COLLECTOR_DIR/.git" ]; then
        log_message "INFO" "Initializing git repository in $COLLECTOR_DIR"
        cd "$COLLECTOR_DIR" || exit 1
        git init
        git config user.email "msft-collector@automation.local"
        git config user.name "MSFT Collector Automation"
    fi
}

################################################################################
# Function: is_processed
# Purpose: Check if SR number has already been processed
################################################################################
is_processed() {
    local sr_number="$1"
    grep -q "^${sr_number}$" "$PROCESSED_LOG" 2>/dev/null
    return $?
}

################################################################################
# Function: mark_processed
# Purpose: Add SR number to processed list
################################################################################
mark_processed() {
    local sr_number="$1"
    echo "$sr_number" >> "$PROCESSED_LOG"
    log_message "INFO" "Marked SR $sr_number as processed"
}

################################################################################
# Function: validate_file_format
# Purpose: Validate that file contains expected format
# Returns: 0 if valid, 1 if invalid
################################################################################
validate_file_format() {
    local file="$1"
    local content=$(cat "$file")
    
    # Check if file has exactly 3 space-separated fields
    local field_count=$(echo "$content" | wc -w | tr -d ' ')
    if [ "$field_count" -ne 3 ]; then
        log_message "ERROR" "Invalid format in $file: Expected 3 fields, got $field_count"
        return 1
    fi
    
    # Extract fields
    local hostname=$(echo "$content" | awk '{print $1}')
    local sr_number=$(echo "$content" | awk '{print $2}')
    local token=$(echo "$content" | awk '{print $3}')
    
    # Validate SR number is 9 digits
    if ! [[ "$sr_number" =~ ^[0-9]{9}$ ]]; then
        log_message "ERROR" "Invalid SR number format in $file: $sr_number (expected 9 digits)"
        return 1
    fi
    
    # Validate hostname is not empty
    if [ -z "$hostname" ]; then
        log_message "ERROR" "Empty hostname in $file"
        return 1
    fi
    
    # Validate token is not empty
    if [ -z "$token" ]; then
        log_message "ERROR" "Empty token in $file"
        return 1
    fi
    
    return 0
}

################################################################################
# Function: parse_sr_file
# Purpose: Extract hostname, SR number, and token from file
################################################################################
parse_sr_file() {
    local file="$1"
    local content=$(cat "$file")
    
    HOSTNAME=$(echo "$content" | awk '{print $1}')
    SR_NUMBER=$(echo "$content" | awk '{print $2}')
    CXD_TOKEN=$(echo "$content" | awk '{print $3}')
    
    log_message "INFO" "Parsed: hostname=$HOSTNAME, SR=$SR_NUMBER, token=${CXD_TOKEN:0:5}..."
}

################################################################################
# Function: run_collector
# Purpose: Execute msft_collector with retry logic
# Returns: 0 on success, 1 on failure
################################################################################
run_collector() {
    local hostname="$1"
    local sr_number="$2"
    local token="$3"
    local attempt=1
    
    # Find msft_collector - check common locations
    local collector_cmd=""
    if command -v msft_collector &> /dev/null; then
        collector_cmd="msft_collector"
    elif [ -f "$HOME/bin/msft_collector" ]; then
        collector_cmd="$HOME/bin/msft_collector"
    elif [ -f "./msft_collector" ]; then
        collector_cmd="./msft_collector"
    else
        log_message "ERROR" "msft_collector not found in PATH or common locations"
        return 1
    fi
    
    while [ $attempt -le $MAX_RETRIES ]; do
        log_message "INFO" "Running collector for SR $sr_number (attempt $attempt/$MAX_RETRIES)"
        
        # Run the collector command
        if $collector_cmd --playbook lc-fc.playbook "$hostname" "$sr_number" "$token"; then
            log_message "SUCCESS" "Collector completed successfully for SR $sr_number"
            return 0
        else
            local exit_code=$?
            log_message "ERROR" "Collector failed with exit code $exit_code (attempt $attempt/$MAX_RETRIES)"
            
            if [ $attempt -lt $MAX_RETRIES ]; then
                log_message "INFO" "Waiting ${RETRY_DELAY}s before retry..."
                sleep $RETRY_DELAY
            fi
        fi
        
        ((attempt++))
    done
    
    log_message "ERROR" "Collector failed after $MAX_RETRIES attempts for SR $sr_number"
    return 1
}

################################################################################
# Function: git_commit_and_push
# Purpose: Commit file removal and push to remote with retry logic
# Returns: 0 on success, 1 on failure
################################################################################
git_commit_and_push() {
    local filename="$1"
    local sr_number="$2"
    local attempt=1
    
    cd "$COLLECTOR_DIR" || return 1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        log_message "INFO" "Git operations for $filename (attempt $attempt/$MAX_RETRIES)"
        
        # Add file to git if not tracked
        if ! git ls-files --error-unmatch "$filename" > /dev/null 2>&1; then
            log_message "INFO" "File $filename not tracked in git, adding it first"
            git add "$filename"
            git commit -m "Adding SR file $filename before removal" || true
        fi
        
        # Remove from git
        if git rm --cached "$filename" 2>/dev/null; then
            # Commit the removal
            if git commit -m "Removing $filename - SR $sr_number collection completed successfully"; then
                # Try to push
                if git push 2>&1; then
                    log_message "SUCCESS" "Git push completed for SR $sr_number"
                    return 0
                else
                    log_message "WARN" "Git push failed (attempt $attempt/$MAX_RETRIES)"
                fi
            else
                log_message "WARN" "Git commit failed (attempt $attempt/$MAX_RETRIES)"
            fi
        else
            log_message "WARN" "Git rm failed - file may not be tracked"
            # If file wasn't tracked, that's okay, continue
            return 0
        fi
        
        if [ $attempt -lt $MAX_RETRIES ]; then
            log_message "INFO" "Waiting ${RETRY_DELAY}s before retry..."
            sleep $RETRY_DELAY
        fi
        
        ((attempt++))
    done
    
    log_message "ERROR" "Git operations failed after $MAX_RETRIES attempts"
    return 1
}

################################################################################
# Function: archive_file
# Purpose: Move processed file to archive directory
################################################################################
archive_file() {
    local filename="$1"
    local sr_number="$2"
    local status="$3"  # "success" or "failed"
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local archive_name="${sr_number}_${timestamp}_${status}"
    
    if mv "$COLLECTOR_DIR/$filename" "$ARCHIVE_DIR/$archive_name"; then
        log_message "INFO" "Archived $filename as $archive_name"
        return 0
    else
        log_message "ERROR" "Failed to archive $filename"
        return 1
    fi
}

################################################################################
# Function: process_sr_file
# Purpose: Main processing logic for a single SR file
################################################################################
process_sr_file() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    
    log_message "INFO" "Processing file: $filename"
    
    # Validate file format
    if ! validate_file_format "$filepath"; then
        log_message "ERROR" "Skipping invalid file: $filename"
        archive_file "$filename" "invalid" "failed"
        return 1
    fi
    
    # Parse the file
    parse_sr_file "$filepath"
    
    # Check if already processed
    if is_processed "$SR_NUMBER"; then
        log_message "WARN" "SR $SR_NUMBER already processed, skipping"
        archive_file "$filename" "$SR_NUMBER" "duplicate"
        return 0
    fi
    
    # Run the collector
    if run_collector "$HOSTNAME" "$SR_NUMBER" "$CXD_TOKEN"; then
        # Mark as processed immediately after successful collection
        mark_processed "$SR_NUMBER"
        
        # Attempt git operations (non-critical)
        if ! git_commit_and_push "$filename" "$SR_NUMBER"; then
            log_message "WARN" "Git operations failed but collection was successful"
        fi
        
        # Archive the file
        archive_file "$filename" "$SR_NUMBER" "success"
        
        log_message "SUCCESS" "Successfully processed SR $SR_NUMBER"
        return 0
    else
        log_message "ERROR" "Failed to process SR $SR_NUMBER"
        archive_file "$filename" "$SR_NUMBER" "failed"
        return 1
    fi
}

################################################################################
# Function: git_pull_updates
# Purpose: Pull latest files from git repository before scanning
################################################################################
git_pull_updates() {
    cd "$COLLECTOR_DIR" || return 1
    
    # Check if this is a git repository
    if [ ! -d ".git" ]; then
        log_message "WARN" "Not a git repository, skipping git pull"
        return 0
    fi
    
    log_message "INFO" "Pulling latest updates from git repository"
    
    # Attempt git pull with retry logic
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        if git pull 2>&1; then
            log_message "SUCCESS" "Git pull completed successfully"
            return 0
        else
            log_message "WARN" "Git pull failed (attempt $attempt/$MAX_RETRIES)"
            if [ $attempt -lt $MAX_RETRIES ]; then
                sleep $RETRY_DELAY
            fi
        fi
        ((attempt++))
    done
    
    log_message "ERROR" "Git pull failed after $MAX_RETRIES attempts"
    # Don't fail the scan, just log the warning
    return 0
}

################################################################################
# Function: scan_directory
# Purpose: Scan for new SR files and process them
################################################################################
scan_directory() {
    # Pull latest updates from git first
    git_pull_updates
    
    log_message "INFO" "Scanning $COLLECTOR_DIR for new SR files"
    
    local processed_count=0
    local failed_count=0
    
    # Find all 9-digit named files (SR numbers)
    for file in "$COLLECTOR_DIR"/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]; do
        # Check if file exists (pattern may not match anything)
        [ -f "$file" ] || continue
        
        if process_sr_file "$file"; then
            ((processed_count++))
        else
            ((failed_count++))
        fi
    done
    
    if [ $processed_count -gt 0 ] || [ $failed_count -gt 0 ]; then
        log_message "INFO" "Scan complete: $processed_count processed, $failed_count failed"
    fi
}

################################################################################
# Function: watch_mode
# Purpose: Continuously monitor directory for new files
################################################################################
watch_mode() {
    local interval="${1:-30}"  # Default 30 seconds
    
    log_message "INFO" "Starting watch mode (checking every ${interval}s)"
    echo -e "${GREEN}Monitoring $COLLECTOR_DIR for new SR files...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"
    
    while true; do
        scan_directory
        sleep "$interval"
    done
}

################################################################################
# Function: cleanup
# Purpose: Cleanup on script exit
################################################################################
cleanup() {
    log_message "INFO" "Shutting down SR monitor"
    release_lock
    exit 0
}

################################################################################
# Function: show_usage
# Purpose: Display usage information
################################################################################
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Monitor /tmp/cisco/collector for new Service Request files and process them.

OPTIONS:
    -h, --help          Show this help message
    -s, --scan          Scan once and exit (no continuous monitoring)
    -w, --watch [SEC]   Watch mode - continuously monitor (default: 30 seconds)
    -c, --cleanup       Clean up old archive files (older than 30 days)
    -l, --list          List all processed SR numbers
    -r, --reset SR      Reset SR number (remove from processed list)

EXAMPLES:
    $0 --scan                  # Scan once
    $0 --watch                 # Continuous monitoring (30s interval)
    $0 --watch 60              # Continuous monitoring (60s interval)
    $0 --list                  # Show processed SRs
    $0 --reset 700197076       # Allow SR to be reprocessed

FILES:
    Expected file format: <SR_NUMBER> (9 digits)
    File content: <HOSTNAME> <SR_NUMBER> <CXD_TOKEN>
    Example: CHI21-0101-0200-14T2 700197076 JjsCaNeNHDw5VWxP

EOF
}

################################################################################
# Function: cleanup_archives
# Purpose: Remove old archive files
################################################################################
cleanup_archives() {
    log_message "INFO" "Cleaning up archives older than 30 days"
    find "$ARCHIVE_DIR" -type f -mtime +30 -delete
    log_message "INFO" "Archive cleanup complete"
}

################################################################################
# Function: list_processed
# Purpose: List all processed SR numbers
################################################################################
list_processed() {
    if [ ! -f "$PROCESSED_LOG" ] || [ ! -s "$PROCESSED_LOG" ]; then
        echo "No processed SR numbers found"
        return
    fi
    
    echo "Processed SR Numbers:"
    echo "===================="
    cat "$PROCESSED_LOG" | sort -n
    echo ""
    echo "Total: $(wc -l < "$PROCESSED_LOG")"
}

################################################################################
# Function: reset_sr
# Purpose: Remove SR from processed list to allow reprocessing
################################################################################
reset_sr() {
    local sr_number="$1"
    
    if [ -z "$sr_number" ]; then
        echo "Error: SR number required"
        return 1
    fi
    
    if ! [[ "$sr_number" =~ ^[0-9]{9}$ ]]; then
        echo "Error: Invalid SR number format (expected 9 digits)"
        return 1
    fi
    
    if grep -q "^${sr_number}$" "$PROCESSED_LOG" 2>/dev/null; then
        sed -i.bak "/^${sr_number}$/d" "$PROCESSED_LOG"
        log_message "INFO" "Reset SR $sr_number - removed from processed list"
        echo "SR $sr_number has been reset and can be reprocessed"
    else
        echo "SR $sr_number was not found in processed list"
    fi
}

################################################################################
# Main Script
################################################################################
main() {
    # Trap signals for cleanup
    trap cleanup SIGINT SIGTERM
    
    # Initialize
    initialize_directories
    
    # Parse command line arguments
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -s|--scan)
            if ! acquire_lock; then
                exit 1
            fi
            scan_directory
            release_lock
            ;;
        -w|--watch)
            if ! acquire_lock; then
                exit 1
            fi
            local interval="${2:-30}"
            watch_mode "$interval"
            ;;
        -c|--cleanup)
            cleanup_archives
            ;;
        -l|--list)
            list_processed
            ;;
        -r|--reset)
            reset_sr "$2"
            ;;
        "")
            # Default: watch mode
            if ! acquire_lock; then
                exit 1
            fi
            watch_mode 30
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
