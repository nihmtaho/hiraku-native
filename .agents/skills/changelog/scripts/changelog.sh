#!/usr/bin/env sh
# Maintain CHANGELOG.md (Keep a Changelog format).
#
# Usage:
#   changelog.sh init
#   changelog.sh add <added|changed|deprecated|removed|fixed|security> <text...>
#   changelog.sh release <version>
set -eu

FILE="CHANGELOG.md"
CMD="${1:-}"
shift 2>/dev/null || true

scaffold() {
  cat > "$FILE" <<'EOF'
# Changelog

All notable changes to this project are documented here.
Format: Keep a Changelog; versioning: Semantic Versioning.

## [Unreleased]
EOF
}

case "$CMD" in
  init)
    if [ -f "$FILE" ]; then echo "$FILE already exists."; exit 0; fi
    scaffold
    echo "Created $FILE"
    ;;

  add)
    CAT_IN="${1:?usage: changelog.sh add <category> <text...>}"; shift
    TEXT="$*"
    [ -n "$TEXT" ] || { echo "ERROR: empty text." >&2; exit 1; }
    [ -f "$FILE" ] || scaffold
    case "$(printf '%s' "$CAT_IN" | tr '[:upper:]' '[:lower:]')" in
      added) CAT="Added" ;; changed) CAT="Changed" ;; deprecated) CAT="Deprecated" ;;
      removed) CAT="Removed" ;; fixed) CAT="Fixed" ;; security) CAT="Security" ;;
      *) echo "ERROR: category must be added|changed|deprecated|removed|fixed|security." >&2; exit 1 ;;
    esac
    awk -v cat="$CAT" -v text="$TEXT" '
      BEGIN { inUn=0; done=0 }
      /^## \[Unreleased\]/ { print; inUn=1; next }
      {
        if (inUn && /^## / ) {
          if (!done) { print ""; print "### " cat; print "- " text; done=1 }
          inUn=0; print; next
        }
        if (inUn && !done && /^### / ) {
          hdr=$0; sub(/^### /,"",hdr)
          if (hdr==cat) { print; print "- " text; done=1; next }
        }
        print
      }
      END { if (inUn && !done) { print ""; print "### " cat; print "- " text } }
    ' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
    echo "Added under [Unreleased] / $CAT: $TEXT"
    ;;

  release)
    VER="${1:?usage: changelog.sh release <version>}"
    [ -f "$FILE" ] || { echo "ERROR: no $FILE; run 'changelog.sh init' first." >&2; exit 1; }
    D=$(date +%Y-%m-%d)
    awk -v ver="$VER" -v date="$D" '
      BEGIN { done=0 }
      (!done && /^## \[Unreleased\]/) {
        print "## [Unreleased]"; print ""; print "## [" ver "] - " date;
        done=1; next
      }
      { print }
    ' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
    echo "Released $VER ($D). Review $FILE."
    ;;

  *)
    echo "usage: changelog.sh init | add <category> <text...> | release <version>" >&2
    exit 1
    ;;
esac
