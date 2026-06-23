# Adventure 全自动设置指南

一条命令完成：Node、依赖、Git、GitHub、Supabase、Vercel、质量检查。

## 快速开始

### 1. 填写 `.env.local`

从 `.env.example` 复制，按需填写：

```bash
# GitHub（必需，用于推送）
GITHUB_PERSONAL_ACCESS_TOKEN=...

# Supabase（建表）
SUPABASE_ACCESS_TOKEN=...      # Account → Access Tokens
SUPABASE_PROJECT_REF=...       # 项目 Settings → Reference ID

# Vercel（部署）
VERCEL_TOKEN=...               # Account → Settings → Tokens
```

**不要把 token 发到聊天或提交到 Git。**

### 2. 一键向导（推荐）

只需粘贴 **2 个 token**，其余全自动：

```bash
cd ~/Projects/adventure
npm run setup:wizard
```

向导会：
1. 打开 Supabase / Vercel 网页
2. 你粘贴 **Supabase Access Token** → 自动列出项目供选择
3. 自动获取 URL、anon key、service_role → 建表 → 生成类型
4. 你粘贴 **Vercel Token** → 关联项目 → 预览部署
5. 自动同步 GitHub Actions Secrets（Vercel CI）

### 3. 一键设置（已填好 .env.local 时）

```bash
cd ~/Projects/adventure
npm run setup
```

或分步执行：

```bash
npm run setup:github     # GitHub 建库 + 推送
npm run setup:supabase   # 数据库迁移 + 类型生成
npm run setup:vercel     # Vercel 关联 + 预览部署
```

### 3. 可选环境变量

| 变量 | 说明 |
|------|------|
| `SKIP_GITHUB=1` | 跳过 GitHub |
| `SKIP_SUPABASE=1` | 跳过 Supabase |
| `SKIP_VERCEL=1` | 跳过 Vercel |
| `SKIP_INSTALL=1` | 跳过 npm install |
| `RUN_DEV=1` | 设置完成后启动 dev server |
| `DEPLOY_PROD=1` | Vercel 生产部署 |

```bash
SKIP_VERCEL=1 npm run setup          # 只做到 Supabase
DEPLOY_PROD=1 npm run setup:vercel   # 生产部署
```

---

## GitHub

| 设置 | 值 |
|------|-----|
| Repository access | **All repositories** |
| Contents | Read and write |
| Workflows | Read and write |
| Administration（可选） | Read and write |

仓库：https://github.com/ESCK2021/adventure

---

## Supabase 自动建表

### 获取密钥

1. 创建项目：https://supabase.com/dashboard
2. **Access Token**：Account → Access Tokens
3. **Project ref**：Project Settings → General → Reference ID
4. **API keys**：Project Settings → API（URL、anon、service_role）

### 运行

```bash
npm run setup:supabase
```

脚本会：

1. 验证 `SUPABASE_ACCESS_TOKEN` 和 `SUPABASE_PROJECT_REF`
2. 自动补全 `NEXT_PUBLIC_SUPABASE_URL` / anon key（若缺失）
3. 按顺序执行 `supabase/migrations/*.sql`
4. 生成 `src/lib/database.types.ts`

### v1 数据模型

- `trips` — 旅行（user_id、标题、地点、日期）
- `trip_checklist_items` — 清单项
- `journal_entries` — 日志（正文、位置、照片 URL）
- RLS：用户只能访问自己的数据
- Storage：`journal-photos` 私有桶

---

## Vercel 自动部署

### 获取 Token

https://vercel.com/account/settings/tokens

### 运行

```bash
npm run setup:vercel           # 预览部署
DEPLOY_PROD=1 npm run setup:vercel   # 生产部署
```

脚本会：

1. 验证 `VERCEL_TOKEN`
2. `vercel link` 关联项目
3. 将 Supabase 等公开 env 同步到 Vercel
4. 部署并输出预览 URL
5. 将 `VERCEL_ORG_ID`、`VERCEL_PROJECT_ID` 写入 `.env.local`

### GitHub CI 自动预览 / 生产

在 GitHub 仓库 **Settings → Secrets** 添加：

| Secret | 来源 |
|--------|------|
| `VERCEL_TOKEN` | `.env.local` |
| `VERCEL_ORG_ID` | `setup:vercel` 后自动写入 |
| `VERCEL_PROJECT_ID` | `setup:vercel` 后自动写入 |

- PR → `preview.yml` 自动预览 + 评论链接
- `release/*` → `release.yml` 生产部署

### 备选：Vercel 网页导入

https://vercel.com/new → 导入 `ESCK2021/adventure`

---

## 仍需手动的部分

| 项目 | 原因 |
|------|------|
| Xcode CLI Tools | 系统弹窗 |
| 各平台 Token 创建 | 安全，网页操作一次 |
| Figma MCP | Cursor 设置中启用 |

---

## Agent 记忆

| 技能 | 路径 |
|------|------|
| GitHub | `~/.cursor/skills/github-automation/SKILL.md` |
| Supabase + Vercel | `~/.cursor/skills/deployment-automation/SKILL.md` |
| 项目规则 | `.claude/CLAUDE.md` |

## 安全提醒

- 所有 token 只存在 `.env.local`（已在 `.gitignore`）
- 若 token 曾泄露，请 Revoke 后重新生成
