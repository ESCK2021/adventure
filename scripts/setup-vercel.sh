#!/usr/bin/env bash
# Link and deploy Adventure to Vercel; sync env vars from .env.local.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

DEPLOY_PROD="${DEPLOY_PROD:-0}"

load_env
ensure_path
require_cmd npm

[[ -n "${VERCEL_TOKEN:-}" ]] || { vercel_missing_env_help; exit 1; }

cd "$ROOT_DIR"

log "验证 Vercel Token"
if ! npx --yes vercel@latest whoami --token "$VERCEL_TOKEN" >/dev/null 2>&1; then
  die "VERCEL_TOKEN 无效"
fi
ok "Vercel 已认证"

vercel_resolve_scope() {
  if [[ -n "${VERCEL_SCOPE:-}" ]]; then
    echo "$VERCEL_SCOPE"
    return
  fi
  # Legacy: slug stored in VERCEL_ORG_ID
  if [[ "${VERCEL_ORG_ID:-}" == *-projects-* ]]; then
    echo "$VERCEL_ORG_ID"
    return
  fi
  local scope
  scope=$(npx --yes vercel@latest teams ls --token "$VERCEL_TOKEN" 2>&1 \
    | grep -E '^[a-z0-9]+-projects-[a-z0-9]+' | head -1 | awk '{print $1}')
  [[ -n "$scope" ]] || die "无法解析 Vercel scope — 请在 .env.local 设置 VERCEL_SCOPE"
  set_env_var "VERCEL_SCOPE" "$scope"
  echo "$scope"
}

VERCEL_SCOPE=$(vercel_resolve_scope)
ok "Vercel scope: ${VERCEL_SCOPE}"

log "关联 Vercel 项目"
link_args=(--yes --token "$VERCEL_TOKEN" --scope "$VERCEL_SCOPE")
if [[ ! -f "${ROOT_DIR}/.vercel/project.json" ]]; then
  npx --yes vercel@latest link "${link_args[@]}"
  ok "项目已关联"
else
  ok "项目已关联 (.vercel/project.json)"
fi

# Persist team id + project id for GitHub CI (not the CLI scope slug)
if [[ -f "${ROOT_DIR}/.vercel/project.json" ]]; then
  proj_id=$(python3 -c "import json; print(json.load(open('${ROOT_DIR}/.vercel/project.json')).get('projectId',''))")
  team_id=$(python3 -c "import json; print(json.load(open('${ROOT_DIR}/.vercel/project.json')).get('orgId',''))")
  [[ -n "$proj_id" ]] && set_env_var "VERCEL_PROJECT_ID" "$proj_id"
  [[ -n "$team_id" ]] && set_env_var "VERCEL_ORG_ID" "$team_id"
  set_env_var "VERCEL_SCOPE" "$VERCEL_SCOPE"
  ok "已保存 VERCEL_ORG_ID (team) / VERCEL_PROJECT_ID / VERCEL_SCOPE"
fi

sync_env_var() {
  local name="$1" value="${2:-}"
  [[ -n "$value" ]] || return 0
  if npx --yes vercel@latest env ls "$name" --token "$VERCEL_TOKEN" --scope "$VERCEL_SCOPE" 2>/dev/null | grep -q .; then
    ok "Vercel env 已存在: ${name}"
    return 0
  fi
  for target in production preview development; do
    printf '%s' "$value" | npx --yes vercel@latest env add "$name" "$target" \
      --token "$VERCEL_TOKEN" --scope "$VERCEL_SCOPE" --yes 2>/dev/null || true
  done
  ok "已添加 Vercel env: ${name}"
}

log "同步环境变量到 Vercel"
sync_env_var "NEXT_PUBLIC_SUPABASE_URL" "${NEXT_PUBLIC_SUPABASE_URL:-}"
sync_env_var "NEXT_PUBLIC_SUPABASE_ANON_KEY" "${NEXT_PUBLIC_SUPABASE_ANON_KEY:-}"
sync_env_var "NEXT_PUBLIC_SENTRY_DSN" "${NEXT_PUBLIC_SENTRY_DSN:-}"

log "部署到 Vercel"
deploy_args=(--token "$VERCEL_TOKEN" --scope "$VERCEL_SCOPE" --yes)
# VERCEL_ORG_ID is team_* for CI; unset during deploy to avoid CLI conflict
if [[ "$DEPLOY_PROD" == "1" ]]; then
  deploy_out=$(env -u VERCEL_ORG_ID -u VERCEL_PROJECT_ID \
    npx --yes vercel@latest deploy --prod "${deploy_args[@]}" 2>&1) || die "部署失败"
  url=$(echo "$deploy_out" | python3 -c "import sys,re; t=sys.stdin.read(); m=re.search(r'https://\\S+\\.vercel\\.app', t); print(m.group(0) if m else '')")
  ok "生产环境部署完成: ${url}"
else
  deploy_out=$(env -u VERCEL_ORG_ID -u VERCEL_PROJECT_ID \
    npx --yes vercel@latest deploy "${deploy_args[@]}" 2>&1) || die "部署失败"
  url=$(echo "$deploy_out" | python3 -c "
import sys, json, re
text = sys.stdin.read()
try:
    data = json.loads(text[text.rfind('{'):])
    print(data.get('deployment', {}).get('url', ''))
except Exception:
    m = re.search(r'https://\\S+\\.vercel\\.app', text)
    print(m.group(0) if m else '')
")
  ok "预览部署完成: ${url}"
  echo ""
  echo "  生产部署:  DEPLOY_PROD=1 npm run setup:vercel"
  echo "  GitHub CI: npm run setup:secrets"
fi
