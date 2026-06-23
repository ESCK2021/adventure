# Adventure 本地环境配置指南

## 已完成（自动）

- [x] Node.js 22.16.0 安装到 `~/.local/node-v22.16.0-darwin-arm64/`
- [x] `~/.zshrc` 已写入 PATH（新开终端自动生效）
- [x] `npm install` 依赖已安装
- [x] 类型检查、单元测试、Lint 已通过
- [x] `.env.local` 已创建（待填写密钥）

## 需要你手动完成

### 1. Xcode Command Line Tools（用于 Git）

系统应已弹出安装窗口。若没有，在终端执行：

```bash
xcode-select --install
```

安装完成后验证：

```bash
git --version
```

然后在项目目录初始化 Git：

```bash
cd ~/Projects/adventure
git init
git checkout -b develop
git add .
git commit -m "chore: bootstrap Adventure project"
```

### 2. 启动开发服务器

```bash
cd ~/Projects/adventure
source scripts/setup-path.sh   # 若当前终端还没有 node
npm run dev
```

浏览器打开：http://localhost:3000

### 3. GitHub 仓库

1. 在 https://github.com/new 创建仓库 `adventure`（或你喜欢的名字）
2. 创建 **Fine-grained PAT**：Settings → Developer settings → Personal access tokens
   - 权限：Contents、Pull requests、Workflows（按需）
3. 填入 `.env.local`：

```bash
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
```

4. 关联远程并推送：

```bash
git remote add origin git@github.com:你的用户名/adventure.git
git push -u origin develop
```

### 4. Supabase

1. 在 https://supabase.com/dashboard 创建项目
2. Project Settings → API 复制 URL 和 anon key
3. 填入 `.env.local`：

```bash
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_PROJECT_REF=你的项目ref
SUPABASE_ACCESS_TOKEN=从 Account → Access Tokens 获取
```

4. 重启 Cursor 或重新加载 MCP，使 `.cursor/mcp.json` 读取新环境变量

### 5. Figma MCP

1. 在 Cursor 设置中启用 Figma MCP（官方远程：`https://mcp.figma.com/mcp`）
2. 按 `docs/figma-structure.md` 创建设计文件
3. 设计审批标记：帧状态设为 **Ready for dev**

### 6. Vercel 部署（可选，推送 GitHub 后）

1. https://vercel.com 导入 GitHub 仓库
2. 在 Vercel 项目设置中添加环境变量（与 `.env.local` 相同）
3. 在 GitHub Secrets 配置 `VERCEL_TOKEN` 等（见 `.github/workflows/preview.yml` 注释）

## 常用命令

| 命令 | 说明 |
|------|------|
| `npm run dev` | 开发服务器 |
| `npm run build` | 生产构建 |
| `npm run test` | 单元测试 |
| `npm run test:e2e` | E2E 测试（需先 `npx playwright install`） |
| `npm run lint` | 代码检查 |

## 下一步

Git + 密钥配置完成后，建议顺序：

1. Figma 设计系统 + MVP 界面
2. Supabase 数据库迁移（`.claude/agents/db-migration-writer.md`）
3. 按已审批设计实现功能
