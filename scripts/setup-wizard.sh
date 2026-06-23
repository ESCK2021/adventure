#!/usr/bin/env bash
# Interactive wizard: minimal input → Supabase migrations + Vercel deploy + GitHub secrets.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SKIP_VERCEL="${SKIP_VERCEL:-0}"
SKIP_GITHUB_SECRETS="${SKIP_GITHUB_SECRETS:-0}"

cd "$ROOT_DIR"
install_node_if_missing
ensure_path

[[ -f "$ENV_FILE" ]] || cp "${ROOT_DIR}/.env.example" "$ENV_FILE"

printf '\n╔══════════════════════════════════════╗\n'
printf '║   Adventure 全自动配置向导           ║\n'
printf '╚══════════════════════════════════════╝\n\n'
printf '只需粘贴 token，其余由脚本自动完成。\n'
printf 'Token 不会显示在聊天中，仅写入 .env.local。\n\n'

if [[ ! -t 0 ]]; then
  die "向导需要交互式终端。请在 Cursor 按 Ctrl+\` 打开终端，运行: npm run setup:wizard
或在 .env.local 填好 SUPABASE_ACCESS_TOKEN 后运行: npm run setup:supabase"
fi

# ── Supabase ──────────────────────────────────────────────
if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  log "步骤 1/3 — Supabase"
  open_url "https://supabase.com/dashboard/account/tokens"
  open_url "https://supabase.com/dashboard"
  printf '\n  1. 在浏览器创建 Access Token（若还没有）\n'
  printf '  2. 在 Dashboard 创建项目（若还没有）\n\n'
  read -rsp "粘贴 Supabase Access Token (sbp_...): " SUPABASE_ACCESS_TOKEN
  printf '\n'
  [[ -n "$SUPABASE_ACCESS_TOKEN" ]] || die "Token 不能为空"
  set_env_var "SUPABASE_ACCESS_TOKEN" "$SUPABASE_ACCESS_TOKEN"
  export SUPABASE_ACCESS_TOKEN
fi

load_env

if [[ -z "${SUPABASE_PROJECT_REF:-}" ]]; then
  log "选择 Supabase 项目"
  supabase_token_ok || die "Supabase Token 无效"
  SUPABASE_PROJECT_REF=$(supabase_pick_project_ref)
  set_env_var "SUPABASE_PROJECT_REF" "$SUPABASE_PROJECT_REF"
  export SUPABASE_PROJECT_REF
  ok "已选择项目 ${SUPABASE_PROJECT_REF}"
fi

log "运行 Supabase 建表 + 类型生成"
bash "${SCRIPT_DIR}/setup-supabase.sh"
load_env

# ── Vercel ────────────────────────────────────────────────
if [[ "$SKIP_VERCEL" != "1" ]]; then
  if [[ -z "${VERCEL_TOKEN:-}" ]]; then
    log "步骤 2/3 — Vercel"
    open_url "https://vercel.com/account/settings/tokens"
    printf '\n  在浏览器创建 Vercel Token\n\n'
    read -rsp "粘贴 Vercel Token: " VERCEL_TOKEN
    printf '\n'
    [[ -n "$VERCEL_TOKEN" ]] || die "Token 不能为空"
    set_env_var "VERCEL_TOKEN" "$VERCEL_TOKEN"
    export VERCEL_TOKEN
  fi

  log "运行 Vercel 关联 + 预览部署"
  bash "${SCRIPT_DIR}/setup-vercel.sh"
  load_env
else
  ok "已跳过 Vercel (SKIP_VERCEL=1)"
fi

# ── GitHub Actions secrets ──────────────────────────────────
if [[ "$SKIP_GITHUB_SECRETS" != "1" && -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
  log "步骤 3/3 — 同步 GitHub Actions Secrets"
  bash "${SCRIPT_DIR}/setup-github-secrets.sh" || err "GitHub Secrets 同步失败（可稍后手动配置）"
else
  err "跳过 GitHub Secrets — 需要 GITHUB_PERSONAL_ACCESS_TOKEN"
fi

printf '\n╔══════════════════════════════════════╗\n'
printf '║   全部完成！                         ║\n'
printf '╚══════════════════════════════════════╝\n\n'
printf '  本地开发:  npm run dev\n'
printf '  仓库:      https://github.com/%s/%s\n' "${GITHUB_OWNER:-ESCK2021}" "${GITHUB_REPO:-adventure}"
printf '\n'
