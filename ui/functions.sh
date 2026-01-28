#!/bin/bash

################################################################################
# UI Functions - Modern and Beautiful
################################################################################

# Source styles
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/styles.sh"

# Get terminal width
get_terminal_width() {
    tput cols 2>/dev/null || echo 80
}

# Center text
center_text() {
    local text="$1"
    local width=$(get_terminal_width)
    local text_length=${#text}
    local padding=$(( (width - text_length) / 2 ))
    printf "%${padding}s%s\n" "" "$text"
}

# Print horizontal line
print_line() {
    local width=$(get_terminal_width)
    printf "${BORDER_COLOR}%*s${RESET}\n" "$width" | tr ' ' "$BOX_H"
}

# Print box top
print_box_top() {
    local width=$(get_terminal_width)
    local inner_width=$((width - 2))
    echo -e "${BORDER_COLOR}${BOX_TL}$(printf '%*s' "$inner_width" | tr ' ' "$BOX_H")${BOX_TR}${RESET}"
}

# Print box bottom
print_box_bottom() {
    local width=$(get_terminal_width)
    local inner_width=$((width - 2))
    echo -e "${BORDER_COLOR}${BOX_BL}$(printf '%*s' "$inner_width" | tr ' ' "$BOX_H")${BOX_BR}${RESET}"
}

# Print box line
print_box_line() {
    local text="$1"
    local width=$(get_terminal_width)
    local text_length=${#text}
    local padding=$((width - text_length - 4))
    echo -e "${BORDER_COLOR}${BOX_V}${RESET} $text$(printf '%*s' "$padding" '')${BORDER_COLOR}${BOX_V}${RESET}"
}

# Print centered box line
print_box_line_centered() {
    local text="$1"
    local width=$(get_terminal_width)
    local text_length=${#text}
    local total_padding=$((width - text_length - 4))
    local left_padding=$((total_padding / 2))
    local right_padding=$((total_padding - left_padding))
    echo -e "${BORDER_COLOR}${BOX_V}${RESET}$(printf '%*s' "$left_padding" '')$text$(printf '%*s' "$right_padding" '')${BORDER_COLOR}${BOX_V}${RESET}"
}

# Print empty box line
print_box_empty() {
    local width=$(get_terminal_width)
    local inner_width=$((width - 4))
    echo -e "${BORDER_COLOR}${BOX_V}${RESET}$(printf '%*s' "$inner_width" '')${BORDER_COLOR}${BOX_V}${RESET}"
}

# Print divider
print_divider() {
    local width=$(get_terminal_width)
    local inner_width=$((width - 2))
    echo -e "${BORDER_COLOR}${BOX_VR}$(printf '%*s' "$inner_width" | tr ' ' "$BOX_H")${BOX_VL}${RESET}"
}

# Clear screen
clear_screen() {
    clear
    tput cup 0 0
}

# Print header
print_header() {
    local title="$1"
    clear_screen
    print_box_top
    print_box_empty
    print_box_line_centered "${HEADER_COLOR}${BOLD}$title${RESET}"
    print_box_empty
    print_box_bottom
    echo ""
}

# Print message with icon
print_message() {
    local type="$1"
    local message="$2"
    
    case "$type" in
        success)
            echo -e "${SUCCESS}${CHECK}${RESET} $message"
            ;;
        error)
            echo -e "${DANGER}${CROSS}${RESET} $message"
            ;;
        warning)
            echo -e "${WARNING}${STAR}${RESET} $message"
            ;;
        info)
            echo -e "${INFO}${DOT}${RESET} $message"
            ;;
        *)
            echo -e "${MUTED}${DOT}${RESET} $message"
            ;;
    esac
}

# Print loading animation
print_loading() {
    local message="$1"
    local duration=${2:-3}
    
    local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local end=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end ]; do
        for i in "${spinner[@]}"; do
            echo -ne "\r${PRIMARY}${i}${RESET} $message"
            sleep 0.1
        done
    done
    echo -ne "\r${SUCCESS}${CHECK}${RESET} $message\n"
}

# Print progress bar
print_progress() {
    local current=$1
    local total=$2
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${PRIMARY}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]${RESET} ${BOLD}%3d%%${RESET}" "$percentage"
    
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Print menu option
print_menu_option() {
    local number="$1"
    local title="$2"
    local description="$3"
    
    echo -e "${MENU_COLOR}${BOLD}  [$number]${RESET} ${HIGHLIGHT_COLOR}$title${RESET}"
    if [ ! -z "$description" ]; then
        echo -e "      ${MUTED}$description${RESET}"
    fi
    echo ""
}

# Print banner
print_banner() {
    print_box_top
    print_box_empty
    print_box_line_centered "${PRIMARY}${BOLD}████████╗██████╗ ███████╗██╗  ██╗███████╗${RESET}"
    print_box_line_centered "${PRIMARY}${BOLD}╚══██╔══╝██╔══██╗██╔════╝╚██╗██╔╝╚══███╔╝${RESET}"
    print_box_line_centered "${PRIMARY}${BOLD}   ██║   ██████╔╝█████╗   ╚███╔╝   ███╔╝${RESET}"
    print_box_line_centered "${PRIMARY}${BOLD}   ██║   ██╔══██╗██╔══╝   ██╔██╗  ███╔╝${RESET}"
    print_box_line_centered "${PRIMARY}${BOLD}   ██║   ██║  ██║███████╗██╔╝ ██╗███████╗${RESET}"
    print_box_line_centered "${PRIMARY}${BOLD}   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝${RESET}"
    print_box_empty
    print_box_line_centered "${ACCENT_COLOR}${BOLD}INSTALLER & MANAGEMENT SUITE${RESET}"
    print_box_empty
    print_box_bottom
}

# Confirm action
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi
    
    echo -e "${WARNING}${STAR}${RESET} $message $prompt"
    read -r response
    
    response=${response:-$default}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Get input with prompt
get_input() {
    local prompt="$1"
    local default="$2"
    local secret="${3:-false}"
    
    if [ ! -z "$default" ]; then
        echo -e "${INFO}${DOT}${RESET} $prompt ${MUTED}[$default]${RESET}"
    else
        echo -e "${INFO}${DOT}${RESET} $prompt"
    fi
    
    if [ "$secret" = "true" ]; then
        read -s -r input
        echo ""
    else
        read -r input
    fi
    
    echo "${input:-$default}"
}

# Print status
print_status() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        running)
            echo -e "${SUCCESS}[${BOLD} RUNNING ${RESET}${SUCCESS}]${RESET} $message"
            ;;
        stopped)
            echo -e "${DANGER}[${BOLD} STOPPED ${RESET}${DANGER}]${RESET} $message"
            ;;
        pending)
            echo -e "${WARNING}[${BOLD} PENDING ${RESET}${WARNING}]${RESET} $message"
            ;;
        installed)
            echo -e "${SUCCESS}[${BOLD}INSTALLED${RESET}${SUCCESS}]${RESET} $message"
            ;;
        missing)
            echo -e "${MUTED}[${BOLD} MISSING ${RESET}${MUTED}]${RESET} $message"
            ;;
        *)
            echo -e "${INFO}[${BOLD} ${status^^} ${RESET}${INFO}]${RESET} $message"
            ;;
    esac
}

# Print table header
print_table_header() {
    local col1_width=$1
    local col2_width=$2
    local col3_width=${3:-0}
    
    echo -e "${BORDER_COLOR}${BOX_TL}$(printf '%*s' "$col1_width" | tr ' ' "$BOX_H")${BOX_HD}$(printf '%*s' "$col2_width" | tr ' ' "$BOX_H")"
    
    if [ $col3_width -gt 0 ]; then
        echo -e "${BOX_HD}$(printf '%*s' "$col3_width" | tr ' ' "$BOX_H")${BOX_TR}${RESET}"
    else
        echo -e "${BOX_TR}${RESET}"
    fi
}

# Print table row
print_table_row() {
    local col1="$1"
    local col2="$2"
    local col3="${3:-}"
    
    echo -e "${BORDER_COLOR}${BOX_V}${RESET} $col1 ${BORDER_COLOR}${BOX_V}${RESET} $col2"
    
    if [ ! -z "$col3" ]; then
        echo -e "${BORDER_COLOR}${BOX_V}${RESET} $col3 ${BORDER_COLOR}${BOX_V}${RESET}"
    else
        echo -e "${BORDER_COLOR}${BOX_V}${RESET}"
    fi
}

# Print table footer
print_table_footer() {
    local col1_width=$1
    local col2_width=$2
    local col3_width=${3:-0}
    
    echo -e "${BORDER_COLOR}${BOX_BL}$(printf '%*s' "$col1_width" | tr ' ' "$BOX_H")${BOX_HU}$(printf '%*s' "$col2_width" | tr ' ' "$BOX_H")"
    
    if [ $col3_width -gt 0 ]; then
        echo -e "${BOX_HU}$(printf '%*s' "$col3_width" | tr ' ' "$BOX_H")${BOX_BR}${RESET}"
    else
        echo -e "${BOX_BR}${RESET}"
    fi
}

# Pause with message
pause() {
    local message="${1:-Press any key to continue...}"
    echo ""
    echo -e "${MUTED}$message${RESET}"
    read -n 1 -s -r
}

# Export all functions
export -f get_terminal_width center_text print_line print_box_top print_box_bottom
export -f print_box_line print_box_line_centered print_box_empty print_divider
export -f clear_screen print_header print_message print_loading print_progress
export -f print_menu_option print_banner confirm get_input print_status
export -f print_table_header print_table_row print_table_footer pause
