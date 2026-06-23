#!/usr/bin/env bash
# Shared helpers for Adventure setup scripts.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
ENV_FILE="${ROOT_DIR}/.env.local"
NODE_VERSION="22.16.0"
NODE_DIR="${HOME}/.local/node-v${NODE_VERSION}-darwin-$(uname -m)"

log() { printf '\n▸ %s\n' "$*"; }
ok()  { printf '  ✓ %s\n' "$*"; }
err() { printf '  ✗ %s\n' "$*" >&2; }
die() { err "$*"; exit 1; }

load_env() {
  if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
  fi
}

ensure_path() {
  if [[ -x "${NODE_DIR}/bin/node" ]]; then
    export PATH="${NODE_DIR}/bin:${PATH}"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令: $1"
}

github_api() {
  local method="$1" path="$2"
  shift 2
  curl -sS -X "$method" \
    -H "Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com${path}" "$@"
}

github_repo_exists() {
  local owner="$1" repo="$2"
  local code
  code=$(github_api GET "/repos/${owner}/${repo}" -o /dev/null -w "%{http_code}")
  [[ "$code" == "200" ]]
}

github_token_ok() {
  local login
  login=$(github_api GET "/user" | python3 -c "import sys,json; print(json.load(sys.stdin).get('login',''))")
  [[ -n "$login" && "$login" != "None" ]]
}

github_can_write_contents() {
  local owner="$1" repo="$2"
  local code msg
  code=$(github_api POST "/repos/${owner}/${repo}/git/blobs" \
    -o /tmp/adventure_blob.json -w "%{http_code}" \
    -d '{"content":"dGVzdA==","encoding":"base64"}')
  msg=$(python3 -c "import json; print(json.load(open('/tmp/adventure_blob.json')).get('message',''))" 2>/dev/null || true)
  if [[ "$code" == "201" ]]; then return 0; fi
  if [[ "$code" == "409" && "$msg" == *"empty"* ]]; then return 0; fi
  return 1
}

install_node_if_missing() {
  if command -v node >/dev/null 2>&1; then
    ok "Node.js $(node -v)"
    return
  fi
  log "安装 Node.js ${NODE_VERSION} 到 ${NODE_DIR}"
  mkdir -p "${HOME}/.local"
  local arch tarball
  arch=$(uname -m)
  tarball="node-v${NODE_VERSION}-darwin-${arch}.tar.gz"
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/${tarball}" -o "/tmp/${tarball}"
  tar -xzf "/tmp/${tarball}" -C "${HOME}/.local"
  export PATH="${NODE_DIR}/bin:${PATH}"
  if ! grep -q 'node-v22.16.0-darwin' "${HOME}/.zshrc" 2>/dev/null; then
    printf '\n# Node.js (Adventure setup)\nexport PATH="%s/bin:$PATH"\n' "$NODE_DIR" >> "${HOME}/.zshrc"
  fi
  ok "Node.js $(node -v)"
}

set_env_var() {
  local key="$1" value="$2"
  touch "$ENV_FILE"
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
      sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    fi
  else
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  fi
}

open_url() {
  local url="$1"
  if command -v open >/dev/null 2>&1; then
    open "$url" 2>/dev/null || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" 2>/dev/null || true
  fi
  ok "已打开: ${url}"
}

supabase_list_projects() {
  supabase_api GET "/projects"
}

supabase_pick_project_ref() {
  local projects_json ref name
  projects_json=$(supabase_list_projects)
  ref=$(echo "$projects_json" | python3 -c "
import sys, json
projects = json.load(sys.stdin)
if not projects:
    sys.exit(1)
if len(projects) == 1:
    print(projects[0].get('id',''))
    sys.exit(0)
print('__MULTIPLE__')
for i, p in enumerate(projects, 1):
    print(f\"{i}. {p.get('name','?')} ({p.get('id','')})\")
" 2>/dev/null) || die "无法获取项目列表 — 请确认 Access Token 有效"
  if [[ "$ref" == "__MULTIPLE__" ]]; then
    echo "$projects_json" | python3 -c "
import sys, json
for i, p in enumerate(json.load(sys.stdin), 1):
    print(f\"  {i}. {p.get('name','?')} — {p.get('id','')}\")
"
    read -rp "选择项目编号: " choice
    ref=$(echo "$projects_json" | python3 -c "
import sys, json
choice = int(sys.argv[1])
print(json.load(sys.stdin)[choice-1]['id'])
" "$choice")
  fi
  echo "$ref"
}

supabase_fetch_api_keys() {
  supabase_api GET "/projects/${SUPABASE_PROJECT_REF}/api-keys" 2>/dev/null || echo "[]"
}

supabase_missing_env_help() {
  err "缺少 Supabase 配置。请在 .env.local 填写："
  err "  SUPABASE_ACCESS_TOKEN  — https://supabase.com/dashboard/account/tokens"
  err "  SUPABASE_PROJECT_REF   — 项目 Settings → General → Reference ID"
  err "  或运行: npm run setup:wizard（自动选择项目）"
  err "填写后运行: npm run setup:supabase"
}

vercel_missing_env_help() {
  err "缺少 Vercel 配置。请在 .env.local 填写："
  err "  VERCEL_TOKEN — https://vercel.com/account/settings/tokens"
  err "可选（首次 link 后自动写入）："
  err "  VERCEL_ORG_ID、VERCEL_PROJECT_ID"
  err "填写后运行: npm run setup:vercel"
}

supabase_api() {
  local method="$1" path="$2"
  shift 2
  curl -sS -X "$method" \
    -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.supabase.com/v1${path}" "$@"
}

supabase_token_ok() {
  local code
  code=$(supabase_api GET "/projects/${SUPABASE_PROJECT_REF}" -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")
  [[ "$code" == "200" ]]
}

supabase_run_sql_file() {
  local sql_file="$1"
  local payload http_code msg
  payload=$(python3 -c "
import json, pathlib, sys
sql = pathlib.Path(sys.argv[1]).read_text()
print(json.dumps({'query': sql}))
" "$sql_file")
  http_code=$(supabase_api POST "/projects/${SUPABASE_PROJECT_REF}/database/query" \
    -d "$payload" -o /tmp/adventure_supabase_query.json -w "%{http_code}")
  if [[ "$http_code" == "201" || "$http_code" == "200" ]]; then
    return 0
  fi
  msg=$(python3 -c "import json; d=json.load(open('/tmp/adventure_supabase_query.json')); print(d.get('message', d))" 2>/dev/null || cat /tmp/adventure_supabase_query.json)
  err "SQL 执行失败 (${http_code}): ${msg}"
  return 1
}
