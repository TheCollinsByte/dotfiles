#!/usr/bin/env bats
#
# bin/wallpaper-shuffle.sh: picks from both sources, never writes into them,
# records state and renders the lock image.

load helpers/statusbar

setup() {
    setup_statusbar
    export XDG_CACHE_HOME="$TEST_HOME/.cache" XDG_STATE_HOME="$TEST_HOME/.local/state"
    OWN="$TEST_HOME/own"; EXTRA="$TEST_HOME/extra/wallpapers/minimalistic"
    mkdir -p "$OWN" "$EXTRA"
    export WALLPAPER_DIRS="$OWN:$TEST_HOME/extra"
    stub feh
    # Every file is an image unless its name contains "bad".
    stub file 'case "$*" in *bad*) echo text/plain ;; *) echo image/jpeg ;; esac'
    # magick writes its last argument, like the real thing.
    stub magick 'for a; do out=$a; done; : > "$out"'
}
teardown() { teardown_sandbox; }

run_shuffle() { run env PATH="$STUBS:$BASE_BIN" SCREEN_SIZE=1920x1080 "$@" bash "$REPO_ROOT/bin/wallpaper-shuffle.sh"; }

@test "sets a wallpaper and records it" {
    echo x > "$OWN/one.jpg"
    run_shuffle
    [ "$status" -eq 0 ]
    assert_called "feh --no-fehbg --bg-fill $OWN/one.jpg"
    [ "$(cat "$XDG_STATE_HOME/dotfiles/wallpaper")" = "$OWN/one.jpg" ]
}

@test "picks from the nested extra source" {
    echo x > "$EXTRA/deep.png"
    run_shuffle
    assert_called "$EXTRA/deep.png"
}

@test "never writes into the wallpaper folders" {
    echo x > "$OWN/one.png"
    local before; before=$(ls -A "$OWN")
    # WALLPAPER_DIR is the old single-folder variable: the previous version
    # copied its pick to "$WALLPAPER_DIR/wallpaper.png".
    run_shuffle WALLPAPER_DIR="$OWN"
    [ "$(ls -A "$OWN")" = "$before" ]
}

@test "handles filenames with spaces" {
    echo x > "$OWN/my wall.jpg"
    run_shuffle
    [ "$(cat "$XDG_STATE_HOME/dotfiles/wallpaper")" = "$OWN/my wall.jpg" ]
}

@test "skips invalid images" {
    echo x > "$OWN/bad.jpg"
    echo x > "$OWN/good.jpg"
    run_shuffle
    [ "$(cat "$XDG_STATE_HOME/dotfiles/wallpaper")" = "$OWN/good.jpg" ]
}

@test "renders the lock image at screen size" {
    echo x > "$OWN/one.jpg"
    run_shuffle
    assert_called "magick"
    assert_called "1920x1080"
    [ -e "$XDG_CACHE_HOME/lock.png" ]
}

@test "skips the lock image without ImageMagick" {
    rm "$STUBS/magick"
    echo x > "$OWN/one.jpg"
    run_shuffle
    [ "$status" -eq 0 ]
    [ ! -e "$XDG_CACHE_HOME/lock.png" ]
}

@test "fails cleanly with no images" {
    run_shuffle
    [ "$status" -ne 0 ]
    assert_not_called feh
}

@test "the old wallpaper.png copy is not a candidate" {
    echo x > "$OWN/wallpaper.png"
    run_shuffle
    [ "$status" -ne 0 ]
    assert_not_called feh
}
