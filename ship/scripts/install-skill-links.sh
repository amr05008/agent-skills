#!/bin/sh
set -eu

# Links the skill directory that contains this script into the global Pi and
# Claude Code skill directories. Generic on purpose: the skill name is the
# directory name, so this file is byte-identical across skills.

usage() {
  cat <<'USAGE'
Usage:
  scripts/install-skill-links.sh --dry-run
  scripts/install-skill-links.sh --yes [--force]

Links this checkout's skill (the directory above scripts/) into the global Pi
and Claude Code skill directories:

  ~/.agents/skills/<name>   (Pi)
  ~/.claude/skills/<name>   (Claude Code)

--dry-run  Show intended changes without writing anything.
--yes      Apply changes.
--force    Repoint existing symlinks that target another checkout. Never
           overwrites regular files or directories.
USAGE
}

MODE=
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      [ -z "$MODE" ] || { echo "install-skill-links: choose either --dry-run or --yes" >&2; exit 2; }
      MODE=dry-run
      ;;
    --yes)
      [ -z "$MODE" ] || { echo "install-skill-links: choose either --dry-run or --yes" >&2; exit 2; }
      MODE=apply
      ;;
    --force) FORCE=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "install-skill-links: unknown option $arg" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$MODE" ]; then
  usage >&2
  exit 3
fi
if [ "$FORCE" -eq 1 ] && [ "$MODE" != apply ]; then
  echo "install-skill-links: --force is only valid with --yes" >&2
  exit 2
fi

SCRIPT_DIR=$(CDPATH= cd -P -- "$(dirname -- "$0")" && pwd)
SKILL_SOURCE=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
SKILL_NAME=$(basename -- "$SKILL_SOURCE")

[ -f "$SKILL_SOURCE/SKILL.md" ] || {
  echo "install-skill-links: missing $SKILL_SOURCE/SKILL.md" >&2
  exit 2
}

link_one() {
  source=$1
  target=$2

  if [ -L "$target" ]; then
    if [ "$target" -ef "$source" ]; then
      echo "ok       $target -> $source"
      return
    fi
    if [ "$FORCE" -ne 1 ]; then
      echo "conflict $target is a symlink to $(readlink "$target")" >&2
      echo "         rerun with --yes --force to repoint it" >&2
      return 1
    fi
    if [ "$MODE" = dry-run ]; then
      echo "repoint  $target -> $source"
      return
    fi
    rm "$target"
  elif [ -e "$target" ]; then
    echo "conflict $target exists and is not a symlink; refusing to overwrite" >&2
    return 1
  elif [ "$MODE" = dry-run ]; then
    echo "create   $target -> $source"
    return
  fi

  mkdir -p "$(dirname -- "$target")"
  ln -s "$source" "$target"
  echo "created  $target -> $source"
}

status=0
link_one "$SKILL_SOURCE" "$HOME/.agents/skills/$SKILL_NAME" || status=1
link_one "$SKILL_SOURCE" "$HOME/.claude/skills/$SKILL_NAME" || status=1

exit "$status"
