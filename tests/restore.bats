#!/usr/bin/env bats
#
# Backup restoration and cleanup. These paths delete and overwrite user data,
# so their guard rails matter as much as their happy path.

load helpers/common

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

# Install once over a pre-existing file, producing a backup to restore from.
install_with_backup() {
    echo "ORIGINAL BASHRC" > "$TEST_HOME/.bashrc"
    "$INSTALL" --minimal --dotfiles >/dev/null 2>&1
}

# --- restore ----------------------------------------------------------------

@test "restore puts the original file back" {
    install_with_backup
    assert_symlink "$TEST_HOME/.bashrc"

    run bash -c "echo 1 | '$INSTALL' --restore"
    assert_success

    [ ! -L "$TEST_HOME/.bashrc" ]
    assert_file_contains "$TEST_HOME/.bashrc" "ORIGINAL BASHRC"
}

@test "restore removes the symlinks the run created" {
    install_with_backup
    assert_symlink "$TEST_HOME/.vimrc"

    run bash -c "echo 1 | '$INSTALL' --restore"
    assert_success

    # .vimrc had no original to restore, so it should simply be gone.
    assert_not_exists "$TEST_HOME/.vimrc"
}

@test "restore lists the available backups" {
    install_with_backup

    run bash -c "echo 0 | '$INSTALL' --restore"
    assert_success
    assert_output_contains "Available backups"
}

@test "selecting 0 cancels the restore" {
    install_with_backup

    run bash -c "echo 0 | '$INSTALL' --restore"
    assert_success
    assert_output_contains "cancelled"

    # Still installed.
    assert_symlink "$TEST_HOME/.bashrc"
}

@test "an out-of-range selection cancels rather than restoring" {
    install_with_backup

    run bash -c "echo 99 | '$INSTALL' --restore"
    assert_success
    assert_output_contains "cancelled"
    assert_symlink "$TEST_HOME/.bashrc"
}

@test "restore reports when there is nothing to restore" {
    # Having nothing to restore is a reportable state, not a script failure:
    # the run still exits 0, consistent with the other query commands.
    run_install --restore
    assert_success
    assert_output_contains "No backups found"
}

@test "restore refuses to run without a TTY unless ASSUME_YES is set" {
    install_with_backup

    # Without ASSUME_YES and without a TTY, confirm() must answer with its
    # default (no) rather than destroying the current configuration.
    run env -u ASSUME_YES bash -c "echo 1 | '$INSTALL' --restore"
    assert_success
    assert_output_contains "cancelled"
    assert_symlink "$TEST_HOME/.bashrc"
}

@test "dry-run restore changes nothing" {
    install_with_backup

    run bash -c "echo 1 | '$INSTALL' --dry-run --restore"
    assert_success

    # Still a symlink; the original was not put back.
    assert_symlink "$TEST_HOME/.bashrc"
}

# --- cleanup ----------------------------------------------------------------

@test "cleanup reports when there are no backups" {
    run_install --cleanup
    assert_success
    assert_output_contains "No backups to clean up"
}

@test "cleanup keeps backups when under the retention limit" {
    local i
    for i in 1 2 3; do
        mkdir -p "$TEST_HOME/.dotfiles_backup_2020010${i}_000000"
    done

    run_install --cleanup
    assert_success
    assert_output_contains "nothing to remove"
    [ "$(count_backups)" -eq 3 ]
}

@test "cleanup removes the oldest backups beyond the retention limit" {
    local i
    for i in $(seq 1 9); do
        mkdir -p "$TEST_HOME/.dotfiles_backup_2020010${i}_000000"
        touch -d "2020-01-0${i}" "$TEST_HOME/.dotfiles_backup_2020010${i}_000000"
    done
    [ "$(count_backups)" -eq 9 ]

    run_install --cleanup
    assert_success

    # Retention is 5.
    [ "$(count_backups)" -eq 5 ]

    # The newest must survive, the oldest must not.
    [ -d "$TEST_HOME/.dotfiles_backup_20200109_000000" ]
    [ ! -d "$TEST_HOME/.dotfiles_backup_20200101_000000" ]
}

@test "dry-run cleanup deletes nothing" {
    local i
    for i in $(seq 1 9); do
        mkdir -p "$TEST_HOME/.dotfiles_backup_2020010${i}_000000"
        touch -d "2020-01-0${i}" "$TEST_HOME/.dotfiles_backup_2020010${i}_000000"
    done

    run_install --dry-run --cleanup
    assert_success
    assert_output_contains "[DRY-RUN]"
    [ "$(count_backups)" -eq 9 ]
}
