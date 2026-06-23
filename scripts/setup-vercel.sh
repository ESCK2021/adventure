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

log "关联 Vercel 项目"
link_args=(--yes --token "$VERCEL_TOKEN")
[[ -n "${VERCEL_ORG_ID:-}" ]] && link_args+=(--scope "$VERCEL_ORG_ID")
if [[ ! -f "${ROOT_DIR}/.vercel/project.json" ]]; then
  npx --yes vercel@latest link "${link_args[@]}" 2>/dev/null || \
    npx --yes vercel@latest link "${link_args[@]}"
  ok "项目已关联"
else
  ok "项目已关联 (.vercel/project.json)"
fi

# Persist org/project ids for CI
if [[ -f "${ROOT_DIR}/.vercel/project.json" ]]; then
  proj_id=$(python3 -c "import json; print(json.load(open('${ROOT_DIR}/.vercel/project.json')).get('projectId',''))")
  org_id=$(python3 -c "import json; print(json.load(open('${ROOT_DIR}/.vercel/project.json')).get('orgId',''))")
  if [[ -n "$proj_id" ]]; then
    grep -q '^VERCEL_PROJECT_ID=' "$ENV_FILE" 2>/dev/null || \
      printf 'VERCEL_PROJECT_ID=%s\n' "$proj_id" >> "$ENV_FILE"
  fi
  if [[ -n "$org_id" ]]; then
    grep -q '^VERCEL_ORG_ID=' "$ENV_FILE" 2>/dev/null || \
      printf 'VERCEL_ORG_ID=%s\n' "$org_id" >> "$ENV_FILE"
  fi
  ok "已保存 VERCEL_ORG_ID / VERCEL_PROJECT_ID 到 .env.local"
fi

sync_env_var() {
  local name="$1" value="${2:-}"
  [[ -n "$value" ]] || return 0
  if npx --yes vercel@latest env ls --token "$VERCEL_TOKEN" 2>/dev/null | grep -q "^${name}"; then
    ok "Vercel env 已存在: ${name}"
  else
    printf '%s' "$value" | npx --yes vercel@latest env add "$name" production preview development \
      --token "$VERCEL_TOKEN" --yes 2>/dev/null || \
      printf '%s' "$value" | npx --yes vercel@latest env add "$name" production \
      --token "$VERCEL_TOKEN" --yes 2>/dev/null || \
      err "无法自动添加 ${name} — 请在 Vercel Dashboard 手动配置"
  fi
}

log "同步环境变量到 Vercel"
sync_env_var "NEXT_PUBLIC_SUPABASE_URL" "${NEXT_PUBLIC_SUPABASE_URL:-}"
sync_env_var "NEXT_PUBLIC_SUPABASE_ANON_KEY" "${NEXT_PUBLIC_SUPABASE_ANON_KEY:-}"
sync_env_var "NEXT_PUBLIC_SENTRY_DSN" "${NEXT_PUBLIC_SENTRY_DSN:-}"

log "部署到 Vercel"
deploy_args=(--token "$VERCEL_TOKEN" --yes)
if [[ "$DEPLOY_PROD" == "1" ]]; then
  npx --yes vercel@latest deploy --prod "${deploy_args[@]}"
  ok "生产环境部署完成"
else
  url=$(npx --yes vercel@latest deploy "${deploy_args[@]}" 2>&1 | tail -1)
  ok "预览部署完成: ${url}"
  echo ""
  echo "  生产部署:  DEPLOY_PROD=1 npm run setup:vercel"
  echo "  GitHub CI: 在仓库 Secrets 配置 VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID"
fi
