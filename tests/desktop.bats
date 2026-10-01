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
