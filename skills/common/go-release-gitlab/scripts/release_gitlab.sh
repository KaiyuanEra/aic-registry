#!/usr/bin/env bash
# go-release-gitlab — bundled release script
# Called by the agent after loading env from .aic/.aic-env or ~/.aic/aic-env.
# Run from the target project root directory.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage (called by agent):
  GITLAB_URL=... GITLAB_PROJECT_ID=... GITLAB_TOKEN=... \
    bash <skill>/scripts/release_gitlab.sh <version>

Optional env:
  PUSH_TAG=true             push tag to origin (default: false)
  APP_NAME=<name>           override app name (default: auto-detect from go.mod)
  GITLAB_PROJECT_PATH=<p>   override project path for package URL
                            (default: auto-detect from git remote)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage; exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing command: $1" >&2; exit 1
  fi
}

require_env() {
  local key="$1"
  if [[ -z "${!key:-}" ]]; then
    echo "missing env: $key" >&2; exit 1
  fi
}

VERSION="$1"
PUSH_TAG="${PUSH_TAG:-false}"
ROOT_DIR="$(pwd)"
DIST_DIR="${ROOT_DIR}/dist"

# Auto-detect APP_NAME from go.mod
if [[ -z "${APP_NAME:-}" ]]; then
  if [[ -f "${ROOT_DIR}/go.mod" ]]; then
    MODULE="$(awk '/^module /{print $2; exit}' "${ROOT_DIR}/go.mod")"
    APP_NAME="${MODULE##*/}"
  else
    APP_NAME="$(basename "$ROOT_DIR")"
  fi
fi

# Auto-detect GITLAB_PROJECT_PATH from git remote (for package URL)
if [[ -z "${GITLAB_PROJECT_PATH:-}" ]]; then
  REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
  if [[ "$REMOTE_URL" =~ :(.+)\.git$ ]]; then
    GITLAB_PROJECT_PATH="${BASH_REMATCH[1]}"
  elif [[ "$REMOTE_URL" =~ //[^/]+/(.+)\.git$ ]]; then
    GITLAB_PROJECT_PATH="${BASH_REMATCH[1]}"
  else
    echo "cannot detect GITLAB_PROJECT_PATH from git remote; set it manually" >&2
    exit 1
  fi
fi

require_cmd git
require_cmd curl
require_cmd make
require_env GITLAB_URL
require_env GITLAB_PROJECT_ID
require_env GITLAB_TOKEN

if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "invalid version: ${VERSION} (expect vX.Y.Z)" >&2; exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "git worktree is not clean; commit/stash changes first" >&2; exit 1
fi

echo "[1/5] build release archives (APP_NAME=${APP_NAME})..."
make clean dist VERSION="$VERSION"

echo "[2/5] ensure tag exists..."
if git rev-parse -q --verify "refs/tags/${VERSION}" >/dev/null; then
  echo "  tag ${VERSION} already exists, reuse"
else
  git tag -a "${VERSION}" -m "release ${VERSION}"
  echo "  created tag ${VERSION}"
fi

if [[ "$PUSH_TAG" == "true" ]]; then
  echo "[3/5] push tag..."
  git push origin "${VERSION}"
else
  echo "[3/5] skip push tag (set PUSH_TAG=true to push)"
fi

API_BASE="${GITLAB_URL%/}/api/v4/projects/${GITLAB_PROJECT_ID}"
RELEASE_API="${API_BASE}/releases/${VERSION}"

echo "[4/5] upload generic packages..."
for file in "${DIST_DIR}"/*.tar.gz "${DIST_DIR}"/checksums.txt; do
  [[ -f "$file" ]] || continue
  name="$(basename "$file")"
  curl --silent --show-error --fail \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --upload-file "$file" \
    "${API_BASE}/packages/generic/${APP_NAME}/${VERSION}/${name}" >/dev/null
  echo "  uploaded ${name}"
done

echo "[5/5] create/update release..."
if curl --silent --show-error --fail \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "$RELEASE_API" >/dev/null 2>&1; then
  METHOD="PUT"; TARGET="$RELEASE_API"
else
  METHOD="POST"; TARGET="${API_BASE}/releases"
fi

curl --silent --show-error --fail \
  --request "$METHOD" \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --data-urlencode "name=${APP_NAME} ${VERSION}" \
  --data-urlencode "tag_name=${VERSION}" \
  --data-urlencode "description=${APP_NAME} release ${VERSION}" \
  "$TARGET" >/dev/null

PACKAGE_BASE="${GITLAB_URL%/}/${GITLAB_PROJECT_PATH}/-/packages/generic/${APP_NAME}/${VERSION}"
for name in \
  "${APP_NAME}_${VERSION}_linux_amd64.tar.gz" \
  "${APP_NAME}_${VERSION}_linux_arm64.tar.gz" \
  "${APP_NAME}_${VERSION}_darwin_amd64.tar.gz" \
  "${APP_NAME}_${VERSION}_darwin_arm64.tar.gz" \
  "checksums.txt"; do
  curl --silent --show-error --fail \
    --request POST \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --data-urlencode "name=${name}" \
    --data-urlencode "url=${PACKAGE_BASE}/${name}" \
    "${RELEASE_API}/assets/links" >/dev/null || true
done

echo "release done: ${APP_NAME} ${VERSION}"
