# Adventure 全自动设置指南

一条命令完成：Node 安装、依赖、Git、GitHub 建库推送、质量检查。

## 快速开始

### 1. 准备 GitHub Token（只需做一次）

在 https://github.com/settings/tokens?type=beta 创建 **Fine-grained PAT**：

| 设置 | 值 |
|------|-----|
| Repository access | **All repositories** |
| Contents | Read and write |
| Workflows | Read and write |
| Administration（账户级，可选） | Read and write（用于自动建库） |

### 2. 写入 `.env.local`

```bash
GITHUB_PERSONAL_ACCESS_TOKEN=你的token
GITHUB_OWNER=ESCK2021          # 可选，默认 ESCK2021
GITHUB_REPO=adventure          # 可选，默认 adventure
```

**不要把 token 发到聊天或提交到 Git。**

### 3. 一键设置

```bash
cd ~/Projects/adventure
npm run setup
```

脚本会自动：

1. 安装 Node.js 22（若缺失）到 `~/.local/`
2. `npm install`
3. `git init` + 首次提交（若尚未初始化）
4. 验证 Token 权限
5. 创建 GitHub 仓库（若不存在）
6. 推送 `develop` 和 `main`
7. 运行 typecheck / test / lint

### 可选环境变量

| 变量 | 说明 |
|------|------|
| `SKIP_GITHUB=1` | 跳过 GitHub 步骤 |
| `SKIP_INSTALL=1` | 跳过 npm install |
| `RUN_DEV=1` | 设置完成后启动 dev server |

```bash
RUN_DEV=1 npm run setup
```

### 仅同步 GitHub

```bash
npm run setup:github
```

## 仍需手动的部分

| 项目 | 原因 |
|------|------|
| Xcode CLI Tools | 系统弹窗，无法脚本化 |
| PAT 创建 | 安全，需用户在 GitHub 网页操作一次 |
| Supabase / Figma / Vercel | 需各自账号密钥，填入 `.env.local` |

## 仓库地址

https://github.com/ESCK2021/adventure

## 安全提醒

- Token 只存在 `.env.local`（已在 `.gitignore`）
- 若 token 曾泄露，请在 GitHub **Revoke** 后重新生成并更新 `.env.local`
