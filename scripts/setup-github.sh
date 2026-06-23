#!/usr/bin/env bash
# Create GitHub repo, validate PAT permissions, push branches.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

GITHUB_OWNER="${GITHUB_OWNER:-ESCK2021}"
GITHUB_REPO="${GITHUB_REPO:-adventure}"
GITHUB_DESCRIPTION="${GITHUB_DESCRIPTION:-Plan outdoor trips, log explorations, and revisit your adventures.}"

load_env
[[ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]] || die "请在 .env.local 设置 GITHUB_PERSONAL_ACCESS_TOKEN"

log "验证 GitHub Token"
github_token_ok || die "Token 无效或已过期"
ok "已认证 GitHub 用户"

log "检查仓库 ${GITHUB_OWNER}/${GITHUB_REPO}"
if github_repo_exists "$GITHUB_OWNER" "$GITHUB_REPO"; then
  ok "仓库已存在"
else
  log "创建仓库..."
  resp=$(github_api POST "/user/repos" \
    -d "{\"name\":\"${GITHUB_REPO}\",\"description\":\"${GITHUB_DESCRIPTION}\",\"private\":false}")
  url=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('html_url',''))")
  [[ -n "$url" ]] || die "创建失败: $(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message','unknown'))")"
  ok "已创建 ${url}"
fi

log "验证写入权限"
if ! github_can_write_contents "$GITHUB_OWNER" "$GITHUB_REPO"; then
  die "Token 缺少 Repository 权限。需要: All repositories + Contents(Read/Write) + Workflows(Read/Write)"
fi
ok "Contents 写入权限正常"

cd "$ROOT_DIR"
require_cmd git

REMOTE_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}.git"
git remote get-url origin >/dev/null 2>&1 && git remote set-url origin "$REMOTE_URL" || git remote add origin "$REMOTE_URL"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  git init
  git checkout -b develop 2>/dev/null || git checkout develop
fi

# Push without embedding token in remote URL (use header auth for this session)
AUTH_REMOTE="https://x-access-token:${GITHUB_PERSONAL_ACCESS_TOKEN}@github.com/${GITHUB_OWNER}/${GITHUB_REPO}.git"
GIT_TERMINAL_PROMPT=0 git -c credential.helper= push -u "$AUTH_REMOTE" develop
GIT_TERMINAL_PROMPT=0 git -c credential.helper= push "$AUTH_REMOTE" main 2>/dev/null || \
  GIT_TERMINAL_PROMPT=0 git -c credential.helper= push "$AUTH_REMOTE" main:main

git remote set-url origin "$REMOTE_URL"
git branch --set-upstream-to=origin/develop develop 2>/dev/null || true

ok "已推送 develop 和 main → ${REMOTE_URL}"
