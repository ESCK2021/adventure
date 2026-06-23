#!/usr/bin/env bash
# One-command bootstrap: Node, deps, git, GitHub, quality checks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SKIP_GITHUB="${SKIP_GITHUB:-0}"
SKIP_SUPABASE="${SKIP_SUPABASE:-0}"
SKIP_VERCEL="${SKIP_VERCEL:-0}"
SKIP_INSTALL="${SKIP_INSTALL:-0}"
RUN_DEV="${RUN_DEV:-0}"

cd "$ROOT_DIR"

log "Adventure 全自动设置"
ok "项目目录: ${ROOT_DIR}"

# 1. Node.js
install_node_if_missing
ensure_path
require_cmd npm

# 2. Env file
if [[ ! -f "$ENV_FILE" ]]; then
  cp "${ROOT_DIR}/.env.example" "$ENV_FILE"
  ok "已从 .env.example 创建 .env.local"
fi
load_env

# 3. Dependencies
if [[ "$SKIP_INSTALL" != "1" ]]; then
  log "安装 npm 依赖"
  npm install
  ok "依赖安装完成"
fi

# 4. Git
if command -v git >/dev/null 2>&1; then
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log "初始化 Git 仓库"
    git init
    git checkout -b develop
    git add .
    git commit -m "chore: bootstrap Adventure project" || true
    git branch main 2>/dev/null || true
    ok "Git 已初始化 (develop + main)"
  else
    ok "Git 仓库已存在"
  fi
else
  err "未找到 git — 请运行 xcode-select --install"
fi

# 5. Quality checks
log "运行质量检查"
npm run typecheck
npm run test
npm run lint
ok "类型检查 / 单元测试 / Lint 通过"

# 6. GitHub
if [[ "$SKIP_GITHUB" != "1" ]]; then
  if [[ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
    bash "${SCRIPT_DIR}/setup-github.sh"
  else
    err "跳过 GitHub：.env.local 中未设置 GITHUB_PERSONAL_ACCESS_TOKEN"
    err "设置后运行: npm run setup:github"
  fi
else
  ok "已跳过 GitHub (SKIP_GITHUB=1)"
fi

# 7. Supabase
if [[ "$SKIP_SUPABASE" != "1" ]]; then
  if [[ -n "${SUPABASE_ACCESS_TOKEN:-}" && -n "${SUPABASE_PROJECT_REF:-}" ]]; then
    bash "${SCRIPT_DIR}/setup-supabase.sh"
  else
    err "跳过 Supabase：.env.local 中未设置 SUPABASE_ACCESS_TOKEN / SUPABASE_PROJECT_REF"
    err "设置后运行: npm run setup:supabase"
  fi
else
  ok "已跳过 Supabase (SKIP_SUPABASE=1)"
fi

# 8. Vercel
if [[ "$SKIP_VERCEL" != "1" ]]; then
  if [[ -n "${VERCEL_TOKEN:-}" ]]; then
    bash "${SCRIPT_DIR}/setup-vercel.sh"
  else
    err "跳过 Vercel：.env.local 中未设置 VERCEL_TOKEN"
    err "设置后运行: npm run setup:vercel"
  fi
else
  ok "已跳过 Vercel (SKIP_VERCEL=1)"
fi

log "设置完成"
echo ""
echo "  开发服务器:   npm run dev"
echo "  GitHub:       npm run setup:github"
echo "  Supabase:     npm run setup:supabase"
echo "  Vercel:       npm run setup:vercel"
echo "  文档:         docs/setup-zh.md"
echo ""

if [[ "$RUN_DEV" == "1" ]]; then
  exec npm run dev
fi
