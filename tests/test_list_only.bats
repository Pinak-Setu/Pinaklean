#!/usr/bin/env bats

setup() {
  TEST_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$TEST_HOME/Library/Caches" "$TEST_HOME/Documents" "$TEST_HOME/.Trash"
  export HOME="$TEST_HOME"
}

@test "dry-run does not delete and reports actions" {
  run "$BATS_TEST_DIRNAME/../bin/pinaklean" --dry-run
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Dry run"
  [ -d "$HOME/Library/Caches" ]
}
