{
  lib,
  symlinkJoin,
  writeShellScriptBin,
}:

let
  jj-ws-init = writeShellScriptBin "jj-ws-init" ''
    set -euo pipefail

    usage() {
      cat <<'EOF'
    Usage: jj-ws-init <workspace-path> <bookmark> [-s|--symlink <path>]...

    Create a jj workspace and check out a bookmark (branch).
    Tracked files are managed by jj normally.
    Only specified ignored/untracked files are symlinked from the main repo.

    If the bookmark exists on a remote, fetches latest and checks out
    the remote version. Falls back to local bookmark if no remote exists.

    Requires .jj-ws/ directory in the repo root.

    Symlink sources (combined, deduplicated):
      1. .jj-ws/symlinks file (one path per line, # comments)
      2. -s/--symlink flags on the command line

    Options:
      -s, --symlink <path>   Extra file/dir to symlink from the main repo
      -h, --help             Show this help

    Examples:
      jj-ws-init ../my-feature my-bookmark
      jj-ws-init ../my-feature my-bookmark -s .env.local -s .data

    Post-init hook:
      If .jj-ws/hook exists (and is executable),
      it runs inside the new workspace after setup.
    EOF
      exit 0
    }

    # --- Parse args ---
    WS_PATH=""
    BOOKMARK=""
    EXTRA_SYMLINKS=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -h|--help) usage ;;
        -s|--symlink)
          [[ -z "''${2:-}" ]] && { echo "Error: --symlink requires a path"; exit 1; }
          EXTRA_SYMLINKS+=("$2"); shift 2 ;;
        -*)
          echo "Unknown option: $1"; exit 1 ;;
        *)
          if [[ -z "$WS_PATH" ]]; then
            WS_PATH="$1"
          elif [[ -z "$BOOKMARK" ]]; then
            BOOKMARK="$1"
          else
            echo "Error: unexpected argument: $1"; exit 1
          fi
          shift ;;
      esac
    done

    if [[ -z "$WS_PATH" || -z "$BOOKMARK" ]]; then
      echo "Error: workspace path and bookmark are required"
      echo "Run 'jj-ws-init --help' for usage"
      exit 1
    fi

    MAIN_REPO="$(jj workspace root 2>/dev/null)" || {
      echo "Error: not inside a jj repository"
      exit 1
    }
    MAIN_ABS="$(realpath "$MAIN_REPO")"
    WS_CONFIG_DIR="$MAIN_ABS/.jj-ws"

    if [[ ! -d "$WS_CONFIG_DIR" ]]; then
      echo "Error: .jj-ws/ directory not found in repo root ($MAIN_ABS)"
      echo ""
      echo "Create it with:"
      echo "  mkdir .jj-ws"
      echo "  echo '.env' > .jj-ws/symlinks    # files to symlink"
      echo "  # optional: create .jj-ws/hook    # post-init script"
      exit 1
    fi

    # --- Collect symlink targets ---
    declare -A SYMLINK_SET

    # From config file
    CONFIG="$WS_CONFIG_DIR/symlinks"
    if [[ -f "$CONFIG" ]]; then
      while IFS= read -r line; do
        line="''${line%%#*}"       # strip comments
        line="''${line##*( )}"     # trim leading spaces
        line="''${line%%*( )}"     # trim trailing spaces
        [[ -z "$line" ]] && continue
        SYMLINK_SET["$line"]=1
      done < "$CONFIG"
    fi

    # From CLI
    for s in "''${EXTRA_SYMLINKS[@]+"''${EXTRA_SYMLINKS[@]}"}"; do
      SYMLINK_SET["$s"]=1
    done

    # --- Fetch from main repo (workspace git can't reach remotes) ---
    echo "→ Fetching latest for bookmark: $BOOKMARK"
    (cd "$MAIN_ABS" && jj git fetch --branch "$BOOKMARK" 2>/dev/null) || true

    # --- Create workspace ---
    echo "→ Creating workspace at $WS_PATH..."
    jj workspace add "$WS_PATH"

    # --- Determine checkout target: prefer remote, fall back to local ---
    remote_rev="$(jj log --no-graph -r "$BOOKMARK@origin" -T 'commit_id.short(12)' 2>/dev/null || true)"
    local_rev="$(jj log --no-graph -r "$BOOKMARK" -T 'commit_id.short(12)' 2>/dev/null || true)"

    if [[ -n "$remote_rev" ]]; then
      echo "→ Checking out bookmark: $BOOKMARK@origin ($remote_rev)"
      (cd "$WS_PATH" && jj new "$BOOKMARK@origin")

      # Ensure tracking
      bookmark_info="$(jj bookmark list --all 2>/dev/null | grep -E "^$BOOKMARK" || true)"
      if echo "$bookmark_info" | grep -q "(untracked)"; then
        jj bookmark track "$BOOKMARK@origin"
        echo "  ✓ Now tracking $BOOKMARK@origin"
      fi

      # Warn about local divergence
      if [[ -n "$local_rev" && "$local_rev" != "$remote_rev" ]]; then
        echo "  ⚠ Local bookmark has diverged from remote"
        echo "    local:  $BOOKMARK ($local_rev)"
        echo "    remote: $BOOKMARK@origin ($remote_rev)"
        echo "    Workspace is on the remote version."
        echo ""
        echo "    To reconcile in main repo:"
        echo "      jj bookmark set $BOOKMARK -r $BOOKMARK@origin  # reset to remote"
        echo "      jj git push -b $BOOKMARK                       # push local"
      else
        echo "  ✓ $BOOKMARK is in sync with origin"
      fi
    elif [[ -n "$local_rev" ]]; then
      echo "  ⚠ No remote bookmark found for '$BOOKMARK' (local only)"
      echo "→ Checking out bookmark: $BOOKMARK ($local_rev)"
      (cd "$WS_PATH" && jj new "$BOOKMARK")
    else
      echo "Error: bookmark '$BOOKMARK' not found locally or on remote"
      # Clean up the workspace we just created
      jj workspace forget "$(basename "$(realpath "$WS_PATH")")" 2>/dev/null || true
      rm -rf "$WS_PATH"
      exit 1
    fi

    WS_ABS="$(realpath "$WS_PATH")"

    # --- Symlink specified files ---
    symlinked=0
    skipped=()

    for name in "''${!SYMLINK_SET[@]}"; do
      source="$MAIN_ABS/$name"
      target="$WS_ABS/$name"

      if [[ ! -e "$source" ]]; then
        skipped+=("$name (not found in main repo)")
        continue
      fi

      # Create parent dirs if needed (for nested paths like config/.env)
      target_dir="$(dirname "$target")"
      [[ -d "$target_dir" ]] || mkdir -p "$target_dir"

      # Remove workspace version if it exists
      if [[ -e "$target" || -L "$target" ]]; then
        rm -rf "$target"
      fi

      ln -sf "$source" "$target"
      echo "  ✓ $name"
      symlinked=$((symlinked + 1))
    done

    echo "→ Symlinked $symlinked item(s)"

    if [[ ''${#skipped[@]} -gt 0 ]]; then
      echo "→ Skipped:"
      for s in "''${skipped[@]}"; do
        echo "    ⚠ $s"
      done
    fi

    # --- Run post-init hook ---
    HOOK="$WS_CONFIG_DIR/hook"
    if [[ -f "$HOOK" ]]; then
      [[ -x "$HOOK" ]] || chmod +x "$HOOK"
      echo "→ Running post-init hook..."
      (cd "$WS_ABS" && "$HOOK")
    fi

    echo ""
    echo "✓ Workspace ready at $WS_ABS"
    echo "  Checked out: ''${BOOKMARK:-"(default)"}"
    echo ""
    echo "  cd $WS_PATH"
  '';

  jj-ws-cleanup = writeShellScriptBin "jj-ws-cleanup" ''
    set -euo pipefail

    if [[ $# -lt 1 ]]; then
      echo "Usage: jj-ws-cleanup <workspace-name-or-path>"
      exit 1
    fi

    TARGET="$1"

    if [[ -d "$TARGET" ]]; then
      WS_ABS="$(realpath "$TARGET")"
      WS_NAME="$(basename "$WS_ABS")"
    else
      WS_NAME="$TARGET"
      WS_ABS=""
    fi

    echo "→ Forgetting workspace: $WS_NAME"
    jj workspace forget "$WS_NAME" 2>/dev/null || echo "  (workspace already forgotten or not found)"

    if [[ -n "$WS_ABS" && -d "$WS_ABS" ]]; then
      echo "→ Removing directory: $WS_ABS"
      # Remove symlinks first (instant, no data loss)
      find "$WS_ABS" -maxdepth 1 -type l -delete
      # Then remove the rest
      rm -rf "$WS_ABS"
      echo "✓ Cleaned up $WS_ABS"
    elif [[ -z "$WS_ABS" ]]; then
      echo "  (pass the workspace path to also delete the directory)"
    fi
  '';
in
symlinkJoin {
  name = "jj-ws";
  paths = [
    jj-ws-init
    jj-ws-cleanup
  ];

  meta = {
    description = "Create and clean up jj workspaces with selective symlinks for ignored files";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
