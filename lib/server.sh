#!/usr/bin/env bash
# lib/server.sh — Optional server/VPS service configuration.
#
# Only runs under --server. Every step is idempotent and refuses to silently
# overwrite an administrator's existing configuration.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_SERVER_SOURCED:-}" ]] && return 0
readonly DOTFILES_SERVER_SOURCED=1

configure_server_services() {
    print_section "Configuring Server Services"

    if [[ "${SERVER_MODE:-false}" != true ]]; then
        print_status "Not in server mode — skipping (use --server)"
        return 0
    fi

    if is_dry_run; then
        print_dry "enable and start Docker, Nginx and fail2ban"
        print_dry "configure the firewall (ufw or firewalld) for ssh/http/https"
        return 0
    fi

    # Fail up front rather than half-way through, leaving services partly set up.
    if ! sudo -n true 2>/dev/null && ! sudo -v; then
        print_error "sudo is required to configure server services"
        return 1
    fi

    configure_docker
    configure_nginx
    configure_firewall
    configure_fail2ban

    print_ok "Server services configured"
    print_warn "Some changes (docker group membership) require re-login to take effect"
}

configure_docker() {
    command_exists docker || return 0
    print_status "Configuring Docker..."

    if command_exists systemctl; then
        sudo systemctl enable --now docker && print_ok "Docker enabled and started"
    fi

    if id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
        print_status "$USER already in the docker group"
    else
        sudo usermod -aG docker "$USER" && print_ok "Added $USER to the docker group"
    fi
}

configure_nginx() {
    command_exists nginx || return 0
    print_status "Configuring Nginx..."

    if command_exists systemctl; then
        sudo systemctl enable --now nginx && print_ok "Nginx enabled and started"
    fi

    sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    print_status "Nginx site directories ready"
}

# Ports sshd listens on, one per line. Firewall rules must use these rather
# than the "ssh" service name, which means port 22 — enabling a firewall on a
# host whose sshd runs elsewhere locks the operator out.
#
# Sources, unioned: the effective sshd config (`sshd -T`, falling back to
# Port lines in sshd_config), plus the port of the SSH session running this
# script, so the connection in use always survives. Defaults to 22.
detect_ssh_ports() {
    local sshd_bin ports=""
    sshd_bin=$(command -v sshd 2>/dev/null || echo /usr/sbin/sshd)

    if [[ -x "$sshd_bin" ]]; then
        ports=$(sudo "$sshd_bin" -T 2>/dev/null | awk '$1 == "port" {print $2}') || ports=""
    fi

    local config="${SSHD_CONFIG:-/etc/ssh/sshd_config}"
    if [[ -z "$ports" && -r "$config" ]]; then
        ports=$(awk 'tolower($1) == "port" {print $2}' "$config") || ports=""
    fi

    if [[ -n "${SSH_CONNECTION:-}" ]]; then
        # Fourth field: the server-side port of this session.
        ports+=$'\n'"$(awk '{print $4}' <<<"$SSH_CONNECTION")"
    fi

    [[ -n "${ports//[[:space:]]/}" ]] || ports=22
    grep -E '^[0-9]+$' <<<"$ports" | sort -un
}

configure_firewall() {
    print_status "Configuring firewall..."

    local -a ssh_ports
    mapfile -t ssh_ports < <(detect_ssh_ports)
    local port

    if command_exists ufw; then
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        # Allow SSH before enabling, or an active SSH session is cut off.
        for port in "${ssh_ports[@]}"; do
            sudo ufw allow "${port}/tcp"
        done
        command_exists nginx && sudo ufw allow 'Nginx Full' 2>/dev/null || true
        sudo ufw --force enable
        print_ok "ufw configured (ssh on ${ssh_ports[*]} allowed, inbound default deny)"
    elif command_exists firewall-cmd; then
        sudo systemctl enable --now firewalld
        sudo firewall-cmd --permanent --add-service=ssh
        for port in "${ssh_ports[@]}"; do
            [[ "$port" == 22 ]] || sudo firewall-cmd --permanent --add-port="${port}/tcp"
        done
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo firewall-cmd --reload
        print_ok "firewalld configured (ssh on ${ssh_ports[*]}, http, https allowed)"
    else
        print_warn "No supported firewall found (ufw/firewalld) — skipping"
    fi
}

configure_fail2ban() {
    command_exists fail2ban-server || return 0
    print_status "Configuring fail2ban..."

    local jail=/etc/fail2ban/jail.local

    # Never clobber an existing jail.local — an operator's tuned bans are far
    # more valuable than our defaults.
    local ssh_ports
    ssh_ports=$(detect_ssh_ports | paste -sd, -)

    if sudo test -f "$jail"; then
        print_warn "$jail already exists — leaving it untouched"
    else
        sudo tee "$jail" >/dev/null <<EOF
# Managed by dotfiles install.sh — edit freely, it will not be overwritten.
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 3

[sshd]
enabled  = true
port     = ${ssh_ports}
maxretry = 3

[nginx-http-auth]
enabled = true
port    = http,https
EOF
        print_ok "Wrote default fail2ban jail configuration"
    fi

    if command_exists systemctl; then
        sudo systemctl enable --now fail2ban && print_ok "fail2ban enabled and started"
    fi
}
