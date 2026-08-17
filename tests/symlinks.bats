#!/usr/bin/env bats
#
# The symlink layer: creation, idempotency, backups, and the dry-run
# guarantee. This is the code that writes into $HOME, so it carries the
# heaviest coverage.

load helpers/common

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

# --- creation ---------------------------------------------------------------

@test "installing links the core dotfiles" {
    run_install --minimal --dotfiles
    assert_success

    assert_symlink "$TEST_HOME/.bashrc"
    assert_symlink "$TEST_HOME/.bash_profile"
    assert_symlink "$TEST_HOME/.vimrc"
    assert_symlink "$TEST_HOME/.gitconfig"
    assert_symlink "$TEST_HOME/.tmux.conf"
}

@test "installing links config directories" {
    run_install --minimal --dotfiles
    assert_success

    assert_symlink "$TEST_HOME/.config/shell"
    assert_symlink "$TEST_HOME/.config/htop"
    assert_symlink "$TEST_HOME/.config/ranger"
}

@test "symlinks resolve to the repository" {
    run_install --minimal --dotfiles
    assert_success

    local target
    target="$(readlink -f "$TEST_HOME/.bashrc")"
    [ "$target" = "$(readlink -f "$REPO_ROOT/.bashrc")" ]
}

@test "bin scripts land in ~/.local/bin" {
    run_install --minimal --dotfiles
    assert_success
    assert_symlink "$TEST_HOME/.local/bin/wallpaper-shuffle.sh"
}

# --- idempotency ------------------------------------------------------------

@test "a second install changes nothing" {
    run_install --minimal --dotfiles
    assert_success
    local first_backups
    first_backups="$(count_backups)"

    run_install --minimal --dotfiles
    assert_success

    # Nothing was replaced, so nothing was backed up.
    assert_output_not_contains "Backed up"
    assert_output_contains "Already linked"
    [ "$(count_backups)" -eq "$first_backups" ]
}

@test "repeated installs do not accumulate backup directories" {
    run_install --minimal --dotfiles
    run_install --minimal --dotfiles
    run_install --minimal --dotfiles
    assert_success

    # A fresh sandbox has no pre-existing configs, so no backup is ever needed.
    [ "$(count_backups)" -eq 0 ]
}

# --- backups ----------------------------------------------------------------

@test "an existing regular file is backed up before being replaced" {
    echo "ORIGINAL CONTENT" > "$TEST_HOME/.bashrc"

    run_install --minimal --dotfiles
    assert_success
    assert_output_contains "Backed up"

    assert_symlink "$TEST_HOME/.bashrc"
    [ "$(count_backups)" -eq 1 ]

    local backup
    backup="$(find "$TEST_HOME" -maxdepth 1 -name '.dotfiles_backup_*' | head -1)"
    assert_file_contains "$backup/.bashrc" "ORIGINAL CONTENT"
}

@test "the backup manifest records both backups and links" {
    echo "ORIGINAL" > "$TEST_HOME/.bashrc"
    run_install --minimal --dotfiles
    assert_success

    local manifest
    manifest="$(find "$TEST_HOME" -maxdepth 1 -name '.dotfiles_backup_*' | head -1)/.manifest"

    assert_file_contains "$manifest" "backed_up"
    assert_file_contains "$manifest" "linked"
    assert_file_contains "$manifest" ".bashrc"
}

@test "no backup directory is created when nothing is replaced" {
    run_install --minimal --dotfiles
    assert_success
    [ "$(count_backups)" -eq 0 ]
}

@test "--check creates no backup directory" {
    # Regression: main() used to mkdir the backup dir unconditionally, so every
    # invocation littered $HOME with an empty .dotfiles_backup_* directory.
    run_install --check
    assert_success
    [ "$(count_backups)" -eq 0 ]
}

# --- dry-run purity ---------------------------------------------------------

@test "dry-run creates no symlinks" {
    run_install --dry-run --minimal --dotfiles
    assert_success

    assert_not_exists "$TEST_HOME/.bashrc"
    assert_not_exists "$TEST_HOME/.vimrc"
    assert_not_exists "$TEST_HOME/.config/shell"
}

@test "dry-run creates no backup directory" {
    echo "ORIGINAL" > "$TEST_HOME/.bashrc"
    run_install --dry-run --minimal --dotfiles
    assert_success

    [ "$(count_backups)" -eq 0 ]
    assert_file_contains "$TEST_HOME/.bashrc" "ORIGINAL"
}

@test "dry-run does not create the gitconfig template" {
    run_install --dry-run --minimal --dotfiles
    assert_success
    assert_not_exists "$TEST_HOME/.gitconfig.local"
}

@test "dry-run of a full install leaves the home directory empty" {
    run_install --dry-run --all
    assert_success

    # Only the log directory may exist; nothing else should have appeared.
    local strays
    strays=$(find "$TEST_HOME" -maxdepth 1 -mindepth 1 -not -name '.local' | wc -l)
    [ "$strays" -eq 0 ]
}

@test "dry-run announces its intentions" {
    run_install --dry-run --minimal --dotfiles
    assert_success
    assert_output_contains "[DRY-RUN]"
    assert_output_contains "Would link"
}

# --- generated files --------------------------------------------------------

@test "a gitconfig.local template is created when absent" {
    run_install --minimal --dotfiles
    assert_success

    [ -f "$TEST_HOME/.gitconfig.local" ]
    assert_file_contains "$TEST_HOME/.gitconfig.local" "[user]"
}

@test "an existing gitconfig.local is never overwritten" {
    printf '[user]\n\tname = Real Person\n' > "$TEST_HOME/.gitconfig.local"

    run_install --minimal --dotfiles
    assert_success

    assert_file_contains "$TEST_HOME/.gitconfig.local" "Real Person"
}

@test "the gitconfig.local template is not world readable" {
    run_install --minimal --dotfiles
    assert_success

    local mode
    mode=$(stat -c '%a' "$TEST_HOME/.gitconfig.local")
    [ "$mode" = "600" ]
}
