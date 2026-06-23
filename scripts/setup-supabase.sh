#!/usr/bin/env bash
# Apply Supabase migrations and generate TypeScript types.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

load_env
ensure_path

missing=0
for var in SUPABASE_ACCESS_TOKEN SUPABASE_PROJECT_REF; do
  if [[ -z "${!var:-}" ]]; then
    err "未设置 ${var}"
    missing=1
  fi
done
if [[ "$missing" == "1" ]]; then
  supabase_missing_env_help
  exit 1
fi

log "验证 Supabase Access Token"
supabase_token_ok || die "Token 无效或 PROJECT_REF 错误"
ok "已连接项目 ${SUPABASE_PROJECT_REF}"

  # Fetch URL, anon key, and service_role from API when missing
  keys_json=$(supabase_fetch_api_keys)
  if [[ -z "${NEXT_PUBLIC_SUPABASE_URL:-}" || -z "${NEXT_PUBLIC_SUPABASE_ANON_KEY:-}" || -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
    log "从 API 获取项目 URL / API keys"
    if [[ -z "${NEXT_PUBLIC_SUPABASE_URL:-}" ]]; then
      project_json=$(supabase_api GET "/projects/${SUPABASE_PROJECT_REF}")
      api_url=$(echo "$project_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('api_url',''))")
      if [[ -n "$api_url" ]]; then
        set_env_var "NEXT_PUBLIC_SUPABASE_URL" "$api_url"
        export NEXT_PUBLIC_SUPABASE_URL="$api_url"
        ok "已写入 NEXT_PUBLIC_SUPABASE_URL"
      fi
    fi
    read -r anon_key service_key <<< "$(echo "$keys_json" | python3 -c "
import sys, json
keys = json.load(sys.stdin)
anon = service = ''
for k in keys:
    name = (k.get('name') or '').lower()
    typ = (k.get('type') or '').lower()
    val = k.get('api_key', '')
    if name == 'anon' or typ == 'anon':
        anon = val
    if name == 'service_role' or typ == 'service_role':
        service = val
print(anon, service)
")"
    if [[ -n "$anon_key" && -z "${NEXT_PUBLIC_SUPABASE_ANON_KEY:-}" ]]; then
      set_env_var "NEXT_PUBLIC_SUPABASE_ANON_KEY" "$anon_key"
      export NEXT_PUBLIC_SUPABASE_ANON_KEY="$anon_key"
      ok "已写入 NEXT_PUBLIC_SUPABASE_ANON_KEY"
    fi
    if [[ -n "$service_key" && -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
      set_env_var "SUPABASE_SERVICE_ROLE_KEY" "$service_key"
      export SUPABASE_SERVICE_ROLE_KEY="$service_key"
      ok "已写入 SUPABASE_SERVICE_ROLE_KEY"
    fi
  fi

MIGRATIONS_DIR="${ROOT_DIR}/supabase/migrations"
shopt -s nullglob
migration_files=("${MIGRATIONS_DIR}"/*.sql)
shopt -u nullglob

if [[ ${#migration_files[@]} -eq 0 ]]; then
  die "未找到迁移文件: ${MIGRATIONS_DIR}/*.sql"
fi

log "应用数据库迁移"
for f in "${migration_files[@]}"; do
  log "  → $(basename "$f")"
  supabase_run_sql_file "$f"
  ok "$(basename "$f")"
done

log "生成 TypeScript 类型"
TYPES_FILE="${ROOT_DIR}/src/lib/database.types.ts"
mkdir -p "$(dirname "$TYPES_FILE")"
types_raw=$(supabase_api GET "/projects/${SUPABASE_PROJECT_REF}/types/typescript" 2>/dev/null || true)
if [[ -n "$types_raw" && "$types_raw" != *"message"* ]]; then
  printf '%s' "$types_raw" | python3 -c "
import sys, json
raw = sys.stdin.read().strip()
if raw.startswith('{'):
    data = json.loads(raw)
    print(data.get('types', raw))
else:
    print(raw)
" > "$TYPES_FILE"
  ok "已写入 ${TYPES_FILE}"
else
  err "无法通过 API 生成类型，尝试 Supabase CLI..."
  if npx --yes supabase@latest gen types typescript \
    --project-id "${SUPABASE_PROJECT_REF}" \
    > "$TYPES_FILE" 2>/dev/null; then
    ok "已通过 CLI 写入 ${TYPES_FILE}"
  else
    err "类型生成失败 — 迁移已应用，可稍后手动运行: npm run setup:supabase"
  fi
fi

ok "Supabase 设置完成"
