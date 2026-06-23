#!/usr/bin/env bash
# Sync Vercel credentials to GitHub Actions repository secrets.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

GITHUB_OWNER="${GITHUB_OWNER:-ESCK2021}"
GITHUB_REPO="${GITHUB_REPO:-adventure}"

load_env

[[ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]] || die "需要 GITHUB_PERSONAL_ACCESS_TOKEN"

secrets_to_set=()
[[ -n "${VERCEL_TOKEN:-}" ]] && secrets_to_set+=("VERCEL_TOKEN")
[[ -n "${VERCEL_ORG_ID:-}" ]] && secrets_to_set+=("VERCEL_ORG_ID")
[[ -n "${VERCEL_PROJECT_ID:-}" ]] && secrets_to_set+=("VERCEL_PROJECT_ID")

if [[ ${#secrets_to_set[@]} -eq 0 ]]; then
  err "没有可同步的 Vercel 变量 — 请先运行 npm run setup:vercel"
  exit 1
fi

log "获取 GitHub 公钥"
pub_json=$(github_api GET "/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/secrets/public-key")
key_id=$(echo "$pub_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('key_id',''))")
pub_key=$(echo "$pub_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('key',''))")

if [[ -z "$key_id" || -z "$pub_key" ]]; then
  err "无法读取 GitHub Secrets 公钥 — PAT 需要 Secrets: Read and write 权限"
  err "手动配置: https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/settings/secrets/actions"
  exit 1
fi

encrypt_secret() {
  python3 - "$1" "$2" <<'PY'
import base64, sys
try:
    from nacl import encoding, public
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pynacl", "-q"])
    from nacl import encoding, public

secret, pub_b64 = sys.argv[1], sys.argv[2]
pub = public.PublicKey(pub_b64.encode(), encoding.Base64Encoder())
sealed = public.SealedBox(pub).encrypt(secret.encode())
print(base64.b64encode(sealed).decode())
PY
}

for name in "${secrets_to_set[@]}"; do
  value="${!name}"
  encrypted=$(encrypt_secret "$value" "$pub_key")
  http_code=$(github_api PUT "/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/secrets/${name}" \
    -d "{\"encrypted_value\":\"${encrypted}\",\"key_id\":\"${key_id}\"}" \
    -o /dev/null -w "%{http_code}")
  if [[ "$http_code" == "201" || "$http_code" == "204" ]]; then
    ok "GitHub Secret: ${name}"
  else
    err "设置 ${name} 失败 (HTTP ${http_code})"
  fi
done

ok "GitHub Actions Secrets 已同步"
