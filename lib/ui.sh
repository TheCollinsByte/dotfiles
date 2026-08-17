#!/usr/bin/env bash
# lib/ui.sh — Interactive menu and usage text.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_UI_SOURCED:-}" ]] && return 0
readonly DOTFILES_UI_SOURCED=1

show_menu() {
    clear
    local mode=""
    [[ "${SERVER_MODE:-false}" == true ]]  && mode+=" [SERVER]"
    [[ "${MINIMAL_MODE:-false}" == true ]] && mode+=" [MINIMAL]"
    is_dry_run                             && mode+=" [DRY-RUN]"

    echo -e "${BLUE}╭──────────────────────────────────────────╮${NC}"
    echo -e "${BLUE}│${NC}       ${BOLD}Dotfiles Installation Menu${NC}         ${BLUE}│${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC}  ${GREEN}1.${NC} Install system packages              ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${GREEN}2.${NC} Set up dotfiles                      ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${GREEN}3.${NC} Set up repositories (submodules)     ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${GREEN}4.${NC} Build & install suckless tools       ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${GREEN}5.${NC} Configure server services            ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${BLUE}6.${NC} Install everything                   ${BLUE}│${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC}  ${YELLOW}7.${NC} Check dependencies                   ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${YELLOW}8.${NC} Health check                         ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${YELLOW}9.${NC} Restore from backup                  ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${YELLOW}i.${NC} Show system info                     ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${RED}0.${NC} Exit                                 ${BLUE}│${NC}"
    echo -e "${BLUE}╰──────────────────────────────────────────╯${NC}"
    [[ -n "$mode" ]] && echo -e "${YELLOW}Active modes:${NC}${mode}"
}

run_interactive_menu() {
    local choice
    while true; do
        show_menu
        read -rp "$(echo -e "\n${YELLOW}Select an option: ${NC}")" choice
        case "$choice" in
            1) install_packages       || true; press_any_key ;;
            2) setup_dotfiles         || true; press_any_key ;;
            3) setup_suckless_repos   || true; press_any_key ;;
            4) build_suckless         || true; press_any_key ;;
            5) configure_server_services || true; press_any_key ;;
            6) run_full_install       || true; press_any_key ;;
            7) check_dependencies     || true; press_any_key ;;
            8) health_check           || true; press_any_key ;;
            9) restore_backup         || true; press_any_key ;;
            i|I) show_system_info     || true; press_any_key ;;
            0) break ;;
            *) print_warn "Invalid option"; sleep 1 ;;
        esac
    done
}

press_any_key() {
    echo ""
    read -n 1 -s -r -p "$(echo -e "${YELLOW}Press any key to continue...${NC}")"
    echo ""
}

show_usage() {
    cat <<EOF
$(echo -e "${BOLD}Dotfiles installer${NC}")

$(echo -e "${BLUE}Usage:${NC}") ./install.sh [options]

$(echo -e "${BLUE}Modes${NC}") (combine with any command)
  --dry-run, --dry       Preview every change without touching the filesystem
  -s, --server           Server mode: skip GUI packages, suckless and X configs
  -m, --minimal          Minimal mode: essential packages only
  -y, --yes              Assume yes for all prompts (non-interactive)
      --profile <name>   Apply a named profile (work, home, minimal, full)
      --list-profiles    List the available profiles

$(echo -e "${BLUE}Location${NC}")
  -l, --location         Choose the dotfiles location interactively
  --set-location <path>  Move the dotfiles to <path>

$(echo -e "${BLUE}Commands${NC}")
  -c, --check            Check system dependencies before installing
  -H, --health-check     Verify an existing installation (symlinks, configs, submodules)
  -p, --packages         Install system packages
  -d, --dotfiles         Symlink dotfiles into \$HOME
  -r, --suckless-repos   Initialize and update git submodules
  -b, --suckless-build   Build and install the suckless tools
      --server-config    Configure server services (docker, nginx, firewall, fail2ban)
  -u, --update           Pull the latest dotfiles and update submodules
      --restore          Restore configs from a previous backup
      --cleanup          Delete old backups, keeping the newest 5
      --show-log         Print the most recent install log
  -a, --all              Run the full installation
  -h, --help             Show this help
  -V, --version          Show the version

$(echo -e "${BLUE}Examples${NC}")
  ./install.sh --check                 # is this machine ready?
  ./install.sh --dry-run --all         # preview a full install
  ./install.sh --all                   # full desktop install
  ./install.sh --server --all          # headless VPS install
  ./install.sh --minimal --dotfiles    # configs only, nothing else
  ./install.sh --health-check          # verify an existing install
  ./install.sh --restore               # roll back to a previous backup
  ./install.sh --profile work --all    # install using the work profile
  ./install.sh --list-profiles         # see what profiles exist
  ./install.sh --cleanup               # prune old backups

$(echo -e "${BLUE}Environment${NC}")
  NO_COLOR=1             Disable colored output
  ASSUME_YES=true        Same as --yes

Logs are written to \${XDG_STATE_HOME:-\$HOME/.local/state}/dotfiles/logs
EOF
}
