#!/bin/bash

# AI Craft - Shared Color Codes Library
# Source this file to get color definitions

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emoji support (can be disabled with USE_EMOJI=false)
USE_EMOJI=${USE_EMOJI:-true}

# Helper function to strip emojis (DRY principle)
_strip_emojis() {
    local msg="$1"
    # Error emojis
    msg="${msg//❌/[ERROR]}"
    msg="${msg//✗/[X]}"
    # Success emojis
    msg="${msg//✅/[OK]}"
    msg="${msg//✓/[OK]}"
    # Warning emojis
    msg="${msg//⚠️/[WARN]}"
    msg="${msg//⚠/[WARN]}"
    # Info emojis
    msg="${msg//ℹ️/[INFO]}"
    msg="${msg//ℹ/[INFO]}"
    msg="${msg//🔍/[INFO]}"
    # Header emojis
    msg="${msg//🚀/[*]}"
    msg="${msg//📦/[*]}"
    msg="${msg//🎯/[*]}"
    echo "$msg"
}

# Core helper function for colored output (eliminates all duplication)
_print_colored() {
    local color="$1"
    local msg="$2"
    if [ "$USE_EMOJI" = true ]; then
        echo -e "${color}${msg}${NC}"
    else
        echo -e "${color}$(_strip_emojis "$msg")${NC}"
    fi
}

# Public functions - one-liners that delegate to the core helper
print_error() { _print_colored "$RED" "$1"; }
print_success() { _print_colored "$GREEN" "$1"; }
print_warning() { _print_colored "$YELLOW" "$1"; }
print_info() { _print_colored "$BLUE" "$1"; }
print_header() { _print_colored "$CYAN" "$1"; }
