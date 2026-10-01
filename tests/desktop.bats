#!/usr/bin/env bats
#
# Desktop pieces of the installer: dunst link, packages, AUR, wallpapers.

load helpers/common

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "dotfiles links the dunst config" {
    run_install --dotfiles
    assert_success
    assert_symlink "$TEST_HOME/.config/dunst"
}

@test "minimal mode skips the dunst config" {
    run_install --minimal --dotfiles
    assert_not_exists "$TEST_HOME/.config/dunst"
}

@test "package list includes the desktop tools" {
    run_install --dry-run --packages
    assert_output_contains "dunst"
    assert_output_contains "xss-lock"
    assert_output_contains "playerctl"
}

@test "AUR step lists i3lock-color when yay exists (dry-run)" {
    mkdir -p "$TEST_HOME/stubs"
    printf '#!/bin/sh\n' > "$TEST_HOME/stubs/yay"; chmod +x "$TEST_HOME/stubs/yay"
    run env PATH="$TEST_HOME/stubs:$PATH" bash -c "
        source '$REPO_ROOT/lib/core.sh'; source '$REPO_ROOT/lib/packages.sh'
        PACKAGE_MANAGER=pacman DRY_RUN=true install_aur_packages"
    assert_success
    assert_output_contains "i3lock-color"
}

@test "AUR step warns without yay" {
    # Empty PATH: no yay, whatever the host has installed.
    mkdir -p "$TEST_HOME/empty"
    run env PATH="$TEST_HOME/empty" "$BASH" -c "
        source '$REPO_ROOT/lib/core.sh'; source '$REPO_ROOT/lib/packages.sh'
        PACKAGE_MANAGER=pacman install_aur_packages"
    assert_success
    assert_output_contains "xtrlock"
}

@test "--wallpapers dry-run leaves no trace" {
    run_install --dry-run --wallpapers
    assert_success
    assert_not_exists "$TEST_HOME/.local/share/wallpapers"
}

@test "--wallpapers fetches only the chosen category" {
    local src="$TEST_HOME/src-repo"
    git init -q "$src"
    mkdir -p "$src/wallpapers/minimalistic" "$src/wallpapers/photography"
    echo a > "$src/wallpapers/minimalistic/a.jpg"
    echo b > "$src/wallpapers/photography/b.jpg"
    git -C "$src" add . && git -C "$src" -c user.name=t -c user.email=t@t commit -qm init

    DOTFILES_WALLPAPER_REPO="file://$src" run_install --wallpapers
    assert_success
    [ -f "$TEST_HOME/.local/share/wallpapers/gruvbox/wallpapers/minimalistic/a.jpg" ]
    assert_not_exists "$TEST_HOME/.local/share/wallpapers/gruvbox/wallpapers/photography/b.jpg"
}

@test "--wallpapers is listed in --help" {
    run_install --help
    assert_output_contains "--wallpapers"
}

@test "xinitrc starts the session in order" {
    # Line number of the first line starting with the given text.
    line() { grep -n -m1 -- "^$1" "$REPO_ROOT/.xinitrc" | cut -d: -f1; }
    local prev=0 n step
    for step in "\[ -f \"\$HOME/.config/shell/envars.sh\" \]" "setxkbmap" "xset s" "start picom" \
                "start dunst" "start xss-lock" "start redshift" "start wallpaper-shuffle" \
                "start dwmblocks" "start fix-audio" "exec dwm"; do
        n=$(line "$step")
        [ -n "$n" ] || { echo "missing: $step"; return 1; }
        [ "$n" -gt "$prev" ] || { echo "out of order: $step"; return 1; }
        prev=$n
    done
    grep -q 'start xss-lock .*-n dim-screen .*-- lock-sleep-wrapper lock' "$REPO_ROOT/.xinitrc"
    grep -q 'xset s 570 30' "$REPO_ROOT/.xinitrc"
    grep -q 'xset dpms 0 0 900' "$REPO_ROOT/.xinitrc"
}

# Bare-bones upstream repo with one wallpaper per category.
make_wallpaper_repo() {
    WP_SRC="$TEST_HOME/src-repo"
    git init -q "$WP_SRC"
    mkdir -p "$WP_SRC/wallpapers/minimalistic"
    echo a > "$WP_SRC/wallpapers/minimalistic/a.jpg"
    git -C "$WP_SRC" add . && git -C "$WP_SRC" -c user.name=t -c user.email=t@t commit -qm init
}

@test "--wallpapers re-run picks up new upstream commits" {
    make_wallpaper_repo
    DOTFILES_WALLPAPER_REPO="file://$WP_SRC" run_install --wallpapers
    assert_success

    echo c > "$WP_SRC/wallpapers/minimalistic/c.jpg"
    git -C "$WP_SRC" add . && git -C "$WP_SRC" -c user.name=t -c user.email=t@t commit -qm more

    DOTFILES_WALLPAPER_REPO="file://$WP_SRC" run_install --wallpapers
    assert_success
    assert_output_not_contains "update failed"
    [ -f "$TEST_HOME/.local/share/wallpapers/gruvbox/wallpapers/minimalistic/c.jpg" ]
}

@test "--wallpapers never deletes a user folder it did not create" {
    make_wallpaper_repo
    local dest="$TEST_HOME/.local/share/wallpapers/gruvbox"
    mkdir -p "$dest"
    echo mine > "$dest/my-own.png"

    DOTFILES_WALLPAPER_REPO="file://$WP_SRC" run_install --wallpapers
    [ "$(cat "$dest/my-own.png")" = mine ]
    assert_output_contains "not a wallpaper checkout"
}

@test "menu offers the wallpaper download" {
    run bash -c "
        source '$REPO_ROOT/lib/core.sh'; source '$REPO_ROOT/lib/ui.sh'
        clear() { :; }; press_any_key() { :; }
        fetch_wallpapers() { echo FETCHED; }
        show_menu; printf 'w\n0\n' | run_interactive_menu"
    assert_output_contains "Download wallpapers"
    assert_output_contains "FETCHED"
}

@test "xinitrc stops X blanking over the idle dim" {
    grep -q '^xset s noblank' "$REPO_ROOT/.xinitrc"
}

@test "package list includes dwmblocks-async build dependencies" {
    run_install --dry-run --packages
    assert_output_contains "xcb-util"
    assert_output_contains "pkg"
}

@test "AUR build asks before running" {
    mkdir -p "$TEST_HOME/stubs"
    printf '#!/bin/sh\necho "YAY $*"\n' > "$TEST_HOME/stubs/yay"; chmod +x "$TEST_HOME/stubs/yay"
    run env PATH="$TEST_HOME/stubs:$PATH" bash -c "
        source '$REPO_ROOT/lib/core.sh'; source '$REPO_ROOT/lib/packages.sh'
        confirm() { echo \"ASKED: \$1\"; return 1; }
        PACKAGE_MANAGER=pacman install_aur_packages"
    assert_output_contains "ASKED:"
    assert_output_not_contains "YAY"
}

@test "xinitrc loads the environment before anything else runs" {
    local env_line xrdb_line
    env_line=$(grep -n -m1 'envars.sh' "$REPO_ROOT/.xinitrc" | cut -d: -f1)
    xrdb_line=$(grep -n -m1 'xrdb' "$REPO_ROOT/.xinitrc" | cut -d: -f1)
    [ "$env_line" -lt "$xrdb_line" ]
}

@test "xinitrc hands DISPLAY to tmux and the user service manager" {
    grep -q 'tmux set-environment -g DISPLAY' "$REPO_ROOT/.xinitrc"
    grep -q 'dbus-update-activation-environment --systemd DISPLAY XAUTHORITY' "$REPO_ROOT/.xinitrc"
}

@test "xinitrc starts background programs only if installed, logging their output" {
    # Run the real start() from .xinitrc against a missing program.
    sed -n '/^start() {/,/^}/p' "$REPO_ROOT/.xinitrc" > "$TEST_HOME/start.sh"
    [ -s "$TEST_HOME/start.sh" ]
    run sh -c ". '$TEST_HOME/start.sh'; log='$TEST_HOME/xsession.log'
        start definitely-not-installed --flag; start sh -c 'echo from-child'; wait
        cat \"\$log\""
    assert_output_contains "definitely-not-installed not installed"
    assert_output_contains "from-child"
    for prog in picom dunst xss-lock redshift dwmblocks; do
        grep -qE "^start $prog( |$)" "$REPO_ROOT/.xinitrc" || { echo "not started via start(): $prog"; return 1; }
    done
}
