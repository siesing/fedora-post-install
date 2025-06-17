#!/bin/bash

# Enhanced Nerd Fonts Installer for Fedora
# Author: Fredrik Siesing
# Version: 2.0
# This script safely downloads and installs Nerd Fonts with proper error handling

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly OWNER="ryanoasis"
readonly REPO="nerd-fonts"
readonly API_URL="https://api.github.com/repos/$OWNER/$REPO/releases/latest"
readonly FONTS_DIR="${HOME}/.local/share/fonts"
readonly TEMP_DIR=$(mktemp -d)
readonly LOG_FILE="${TEMP_DIR}/install-nerd-fonts.log"

# Default configuration
VERBOSE=false
DRY_RUN=false
BACKUP_EXISTING=true
VERIFY_DOWNLOADS=true

# Font selection - can be overridden via command line
declare -a DEFAULT_FONTS=(
    "FiraCode"
    "JetBrainsMono" 
    "Mononoki"
    "Ubuntu"
    "UbuntuMono"
)

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    local exit_code=$?
    if [[ -d "$TEMP_DIR" ]]; then
        log_info "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
    exit $exit_code
}

# Set up trap for cleanup
trap cleanup EXIT INT TERM

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" >&2
}

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" | tee -a "$LOG_FILE"
    fi
}

# Print usage information
show_help() {
    cat << EOF
$SCRIPT_NAME - Enhanced Nerd Fonts Installer

USAGE:
    $SCRIPT_NAME [OPTIONS] [FONTS...]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --dry-run       Show what would be done without executing
    -n, --no-backup     Don't backup existing fonts
    -f, --force         Skip verification prompts
    --no-verify         Skip download verification
    --list-fonts        List available fonts and exit

FONTS:
    Space-separated list of font names to install.
    If not specified, installs: ${DEFAULT_FONTS[*]}
    
    Available fonts include: FiraCode, JetBrainsMono, Mononoki, 
    Ubuntu, UbuntuMono, Hack, SourceCodePro, RobotoMono, and more.
    
    Use --list-fonts to see all available options.

EXAMPLES:
    $SCRIPT_NAME                          # Install default fonts
    $SCRIPT_NAME FiraCode Hack            # Install specific fonts
    $SCRIPT_NAME --dry-run --verbose      # Preview installation
    $SCRIPT_NAME --no-backup FiraCode     # Install without backup

EOF
}

# Check if required commands are available
check_dependencies() {
    local missing_deps=()
    
    local required_commands=("curl" "unzip" "fc-cache" "mktemp")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Install them with: sudo dnf install ${missing_deps[*]}"
        return 1
    fi
    
    log_debug "All dependencies satisfied"
    return 0
}

# Get latest release version from GitHub API
get_latest_version() {
    # Send debug output to stderr so it doesn't interfere with command substitution
    log_debug "Fetching latest release information..." >&2
    
    local response
    if ! response=$(curl -s --fail --max-time 30 "$API_URL" 2>>"$LOG_FILE"); then
        log_error "Failed to fetch release information from GitHub API" >&2
        log_error "Check your internet connection and GitHub API status" >&2
        return 1
    fi
    
    if [[ -z "$response" ]]; then
        log_error "Empty response from GitHub API" >&2
        return 1
    fi
    
    # Try to parse JSON with multiple methods
    local version=""
    
    # Method 1: Try jq if available
    if command -v jq &> /dev/null; then
        version=$(echo "$response" | jq -r '.tag_name' 2>/dev/null || true)
    fi
    
    # Method 2: Fallback to grep/sed (more robust than awk)
    if [[ -z "$version" || "$version" == "null" ]]; then
        version=$(echo "$response" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    
    # Validate version format
    if [[ -z "$version" || ! "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
        log_error "Could not parse valid version from API response" >&2
        log_debug "Response: $response" >&2
        return 1
    fi
    
    log_debug "Latest version: $version" >&2
    # Only output the version to stdout
    echo "$version"
}

# Verify download integrity
verify_download() {
    local file="$1"
    local url="$2"
    
    if [[ ! -f "$file" ]]; then
        log_error "Downloaded file not found: $file"
        return 1
    fi
    
    # Check file size (should be > 1KB for font archives)
    local size
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    
    if [[ "$size" -lt 1024 ]]; then
        log_error "Downloaded file too small ($size bytes): $file"
        log_error "This might indicate a failed download or error response"
        return 1
    fi
    
    # Try to verify it's a valid zip file
    if ! unzip -t "$file" &>/dev/null; then
        log_error "Downloaded file is not a valid ZIP archive: $file"
        return 1
    fi
    
    log_debug "Download verification passed for $file ($size bytes)"
    return 0
}

# Download a single font
download_font() {
    local font="$1"
    local version="$2"
    local zip_file="${font}.zip"
    local download_url="https://github.com/$OWNER/$REPO/releases/download/${version}/${zip_file}"
    local target_file="${TEMP_DIR}/${zip_file}"
    
    log_info "Downloading $font..."
    log_debug "URL: $download_url"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would download: $download_url"
        return 0
    fi
    
    # Download with progress bar and timeout
    if ! curl -L --fail --max-time 300 --progress-bar \
         -o "$target_file" "$download_url" 2>>"$LOG_FILE"; then
        log_error "Failed to download $font from $download_url"
        return 1
    fi
    
    # Verify download if requested
    if [[ "$VERIFY_DOWNLOADS" == true ]]; then
        if ! verify_download "$target_file" "$download_url"; then
            log_error "Download verification failed for $font"
            return 1
        fi
    fi
    
    log_debug "Successfully downloaded $font"
    return 0
}

# Install a single font
install_font() {
    local font="$1"
    local zip_file="${font}.zip"
    local source_file="${TEMP_DIR}/${zip_file}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would extract $font to $FONTS_DIR"
        return 0
    fi
    
    log_info "Installing $font..."
    
    # Create fonts directory if it doesn't exist
    if [[ ! -d "$FONTS_DIR" ]]; then
        log_debug "Creating fonts directory: $FONTS_DIR"
        mkdir -p "$FONTS_DIR"
    fi
    
    # Backup existing fonts if requested
    if [[ "$BACKUP_EXISTING" == true ]]; then
        local backup_dir="${FONTS_DIR}/.backup-$(date +%Y%m%d-%H%M%S)"
        local existing_fonts
        existing_fonts=$(find "$FONTS_DIR" -name "*${font}*" -type f 2>/dev/null || true)
        
        if [[ -n "$existing_fonts" ]]; then
            log_info "Backing up existing $font fonts to $(basename "$backup_dir")"
            mkdir -p "$backup_dir"
            echo "$existing_fonts" | while IFS= read -r font_file; do
                if [[ -n "$font_file" ]]; then
                    cp "$font_file" "$backup_dir/"
                fi
            done
        fi
    fi
    
    # Extract fonts
    if ! unzip -o "$source_file" -d "$FONTS_DIR" &>>"$LOG_FILE"; then
        log_error "Failed to extract $font"
        return 1
    fi
    
    log_debug "Successfully installed $font"
    return 0
}

# Clean up Windows-compatible fonts
cleanup_windows_fonts() {
    if [[ "$DRY_RUN" == true ]]; then
        local windows_fonts
        windows_fonts=$(find "$FONTS_DIR" -name '*Windows Compatible*' 2>/dev/null || true)
        if [[ -n "$windows_fonts" ]]; then
            log_info "[DRY RUN] Would remove Windows-compatible fonts:"
            echo "$windows_fonts" | while IFS= read -r font_file; do
                log_info "[DRY RUN]   - $(basename "$font_file")"
            done
        fi
        return 0
    fi
    
    log_info "Removing Windows-compatible font variants..."
    
    local removed_count=0
    while IFS= read -r -d '' font_file; do
        log_debug "Removing: $(basename "$font_file")"
        rm "$font_file"
        ((removed_count++))
    done < <(find "$FONTS_DIR" -name '*Windows Compatible*' -print0 2>/dev/null || true)
    
    if [[ $removed_count -gt 0 ]]; then
        log_info "Removed $removed_count Windows-compatible font files"
    fi
}

# Refresh font cache
refresh_font_cache() {
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would refresh font cache"
        return 0
    fi
    
    log_info "Refreshing font cache..."
    
    if ! fc-cache -fv &>>"$LOG_FILE"; then
        log_warn "Font cache refresh failed, but fonts should still work"
        return 0
    fi
    
    log_debug "Font cache refreshed successfully"
}

# List available fonts (placeholder - would need API call to get full list)
list_available_fonts() {
    cat << EOF
Common Nerd Font families (use exact names):

Programming Fonts:
  - FiraCode
  - JetBrainsMono
  - Hack
  - SourceCodePro
  - Inconsolata
  - Mononoki

System Fonts:
  - Ubuntu
  - UbuntuMono
  - RobotoMono
  - DejaVuSansMono

Retro/Terminal:
  - Terminus
  - ProggyClean
  - Gohu

For the complete list, visit: https://www.nerdfonts.com/font-downloads

EOF
}


# Main function
main() {
    local -a fonts_to_install=()
    
    # Parse arguments directly in main to avoid subshell issues
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --list-fonts)
                list_available_fonts
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -n|--no-backup)
                BACKUP_EXISTING=false
                shift
                ;;
            -f|--force)
                # For future use
                shift
                ;;
            --no-verify)
                VERIFY_DOWNLOADS=false
                shift
                ;;
            -*)
                echo "ERROR: Unknown option: $1" >&2
                exit 1
                ;;
            *)
                fonts_to_install+=("$1")
                shift
                ;;
        esac
    done
    
    # Use default fonts if none specified
    if [[ ${#fonts_to_install[@]} -eq 0 ]]; then
        fonts_to_install=("${DEFAULT_FONTS[@]}")
    fi
    
    log_info "Enhanced Nerd Fonts Installer v2.0"
    log_info "Log file: $LOG_FILE"
    
    log_info "Fonts to install: ${fonts_to_install[*]}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Get latest version
    local latest_version
    if ! latest_version=$(get_latest_version); then
        exit 1
    fi
    
    log_info "Using Nerd Fonts version: $latest_version"
    
    # Download fonts
    local failed_downloads=()
    for font in "${fonts_to_install[@]}"; do
        if ! download_font "$font" "$latest_version"; then
            failed_downloads+=("$font")
        fi
    done
    
    # Report download failures
    if [[ ${#failed_downloads[@]} -gt 0 ]]; then
        log_warn "Failed to download: ${failed_downloads[*]}"
    fi
    
    # Install successfully downloaded fonts
    local failed_installs=()
    for font in "${fonts_to_install[@]}"; do
        # Skip if download failed
        if [[ " ${failed_downloads[*]} " =~ " ${font} " ]]; then
            continue
        fi
        
        if ! install_font "$font"; then
            failed_installs+=("$font")
        fi
    done
    
    # Clean up Windows fonts
    cleanup_windows_fonts
    
    # Refresh font cache
    refresh_font_cache
    
    # Final report
    local successful_installs=()
    for font in "${fonts_to_install[@]}"; do
        if [[ ! " ${failed_downloads[*]} " =~ " ${font} " ]] && \
           [[ ! " ${failed_installs[*]} " =~ " ${font} " ]]; then
            successful_installs+=("$font")
        fi
    done
    
    if [[ ${#successful_installs[@]} -gt 0 ]]; then
        log_info "Successfully installed: ${successful_installs[*]}"
    fi
    
    if [[ ${#failed_downloads[@]} -gt 0 ]] || [[ ${#failed_installs[@]} -gt 0 ]]; then
        log_warn "Some fonts failed to install. Check the log for details: $LOG_FILE"
        exit 1
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        log_info "Font installation completed successfully!"
        log_info "You may need to restart applications to see the new fonts."
    else
        log_info "Dry run completed. Use without --dry-run to actually install fonts."
    fi
}

# Run main function with all arguments
main "$@"