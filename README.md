# machine-setup

在一台新的 **Apple Silicon Mac** 上，把王建硕（Neo 机器）的开发环境一键复刻出来。

快照来源：macOS 26.4 / arm64 / zsh / Homebrew 5.1。

## 一键安装

```bash
curl -fsSL https://jianshuo.dev/setup/setup.sh | bash -s -- --yes
```

不依赖 github.com（有些网络环境访问不了）：setup.sh 会先从
`https://jianshuo.dev/setup/machine-setup.tar.gz` 自举安装所需的文件
（白名单清单，不含 git 历史）到 `~/code/machine-setup`，再继续跑全套。
镜像在每次 commit 后自动同步（见下文「发布到 jianshuo.dev」）。

能访问 GitHub 的话，传统方式也照常可用：

```bash
git clone https://github.com/jianshuo/machine-setup.git ~/code/machine-setup
cd ~/code/machine-setup
bash setup.sh            # 逐步确认
# 或
bash setup.sh --yes      # 全自动
```

也可只跑某一步：

```bash
bash setup.sh brew       # 只装 Homebrew 包
bash setup.sh runtimes   # 只装 nvm/node/uv
bash setup.sh npm        # 只装全局 npm 包
bash setup.sh dotfiles   # 只部署 .zshrc/.zprofile/git/secrets
bash setup.sh claude     # 只装 Claude Code + plugins
bash setup.sh repos      # 克隆所有 GitHub 仓库到 ~/code/
bash setup.sh extras     # xurl / ccline 提示
```

## 装了什么

| 类别 | 内容 |
|---|---|
| 包管理 | Homebrew + `Brewfile`（formulae / casks / uv / npm / VSCode 扩展全清单）|
| 运行时 | nvm → node v22、pnpm、bun、uv（kimi-cli）、ruby |
| 全局 npm | codex、wx-cli、pi-coding-agent、ccglass、corepack |
| dotfiles | `.zshrc`、`.zprofile`、git 身份 |
| Claude Code | CLI + 2 个 marketplace + 7 个用户级 plugin |
| 代码仓库 | 17 个 GitHub repo 自动 clone：通用 → `~/code/`，产品 → `~/code/products/`，网站 → `~/code/websites/` |
| 独立二进制 | xurl（X CLI）、ccline（需手动拷）|

## 密钥 / 个人信息（重要）

本 repo **公开也安全**：不含任何真实密钥、内网 IP、SSH 别名或个人路径。`.zshrc` 会自动 `source` 三个**本地、不进 git** 的文件，安装脚本从对应 `.example` 拷占位符版过去，由你填真实值：

| 本地文件 | 模板 | 放什么 |
|---|---|---|
| `~/.config/secrets.env` | `secrets.env.example` | `VOLC_APPID`、`MODEL_SPEECH_API_KEY`、`X_ACCESS_TOKEN` |
| `~/code/machine-setup/machine-local.zsh` | `machine-local.zsh.example` | git 真名邮箱、SSH 别名、工作区路径 |
| `~/code/.env` | `env.example` | 20+ 个 API key（OpenAI/Claude/火山/微信/ASC/Cloudflare/Tailscale…）|

`env.example` 里**列全了所有 key 名**（占位符 `CHANGE_ME`），照着把旧机器的真实值填进去即可，不会漏。

## 跑完之后手动几步

1. 填三个本地文件：`~/.config/secrets.env`、`~/code/machine-setup/machine-local.zsh`、`~/code/.env`（都有对应 `.example`）
2. 新开终端或 `source ~/.zshrc`
3. 代理：装好本地代理 app（监听 127.0.0.1:1087/1086）后重开终端即可——`.zshrc` 检测到 1087 在监听才会启用代理，没装也不影响直连
4. **SSH key + `~/code/.env`**：脚本**最早一步**（`step_ssh`）会自动从 iCloud `重要文档/ssh-backup-*.zip` 恢复整个 `~/.ssh/` 和 `~/code/.env`（提示输密码，自动 chmod 600）。`.env` 抢在 dotfiles 的占位符 seed 之前就位，所以恢复的是真实值、占位符自动跳过。若当时 iCloud 还没同步下来 / 没登录 iCloud，会跳过——同步好后单独重跑 `bash setup.sh ssh` 即可，`repos` 步骤也有 SSH 连通性 preflight 兜底。备份的生成方式：把旧机器 `~/.ssh/`（zip 内路径 `.ssh/*`）和 `~/code/.env`（zip 内路径 `code/.env`，都相对 `$HOME`）打成同一个加密 zip 放进 iCloud `重要文档`（文件名 `ssh-backup-YYYY-MM-DD.zip`）
5. `claude /login`（或用 cc-switch 切号）、`gh auth login`
6. 自写 skill 不会自动来：把旧机器 `~/.claude/skills/` 整个目录、以及 `~/.claude/settings.json`（hooks / statusLine / permissions）拷过来
7. `xurl`、`ccline` 不是 brew 包，按 `extras` 步骤的提示手动放二进制

## 发布到 jianshuo.dev

安装所需文件镜像在 `https://jianshuo.dev/setup/`（`setup.sh` + `machine-setup.tar.gz`），
给访问不了 github.com 的环境用。同步是自动的：

- `.git/hooks/post-commit` 在每次 commit 后调用 `publish-web.sh`；
- `publish-web.sh` 把 HEAD 版本的白名单文件（见脚本里的 `FILES`，不含 git 历史）
  打成 tar 包、拷出 `setup.sh`，提交到 `~/code/websites/jianshuo.dev` 并
  `wrangler pages deploy`（幂等，HEAD 没变直接跳过）。新增 setup.sh 的文件依赖时，
  记得把文件名加进 `FILES`。

注意：网站里 `setup/setup.sh` 和 `setup/machine-setup.tar.gz` 是**生成物**，
要改就改本 repo，别直接改网站副本。重新 clone 本 repo 后 hook 不会自带，重装一下：

```bash
cat > .git/hooks/post-commit <<'EOF'
#!/usr/bin/env bash
bash "$(git rev-parse --show-toplevel)/publish-web.sh" || echo "!! publish-web.sh 失败，手动跑一下"
EOF
chmod +x .git/hooks/post-commit
```

## 重新生成快照

环境变了之后，在旧机器上更新 Brewfile：

```bash
brew bundle dump --file=~/code/machine-setup/Brewfile --force --describe
```
