# machine-setup

在一台新的 **Apple Silicon Mac** 上，把王建硕（Neo 机器）的开发环境一键复刻出来。

快照来源：macOS 26.4 / arm64 / zsh / Homebrew 5.1。

## 一键安装

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
| 独立二进制 | xurl（X CLI）、ccline（需手动拷）|

## 密钥 / 个人信息（重要）

本 repo **公开也安全**：不含任何真实密钥、内网 IP、SSH 别名或个人路径。`.zshrc` 会自动 `source` 三个**本地、不进 git** 的文件，安装脚本从对应 `.example` 拷占位符版过去，由你填真实值：

| 本地文件 | 模板 | 放什么 |
|---|---|---|
| `~/.config/secrets.env` | `secrets.env.example` | `VOLC_APPID`、`MODEL_SPEECH_API_KEY`、`X_ACCESS_TOKEN` |
| `~/.config/machine-local.zsh` | `machine-local.zsh.example` | git 真名邮箱、SSH 别名、工作区路径 |
| `~/code/.env` | `env.example` | 20+ 个 API key（OpenAI/Claude/火山/微信/ASC/Cloudflare/Tailscale…）|

`env.example` 里**列全了所有 key 名**（占位符 `CHANGE_ME`），照着把旧机器的真实值填进去即可，不会漏。

## 跑完之后手动几步

1. 填三个本地文件：`~/.config/secrets.env`、`~/.config/machine-local.zsh`、`~/code/.env`（都有对应 `.example`）
2. 新开终端或 `source ~/.zshrc`
3. **新机器若没有本地代理**（127.0.0.1:1087/1086），把 `.zshrc` 顶部的代理 `export` 块注释掉，否则 curl/npm 连不上
4. `claude /login`（或用 cc-switch 切号）、`gh auth login`
5. 自写 skill 不会自动来：把旧机器 `~/.claude/skills/` 整个目录、以及 `~/.claude/settings.json`（hooks / statusLine / permissions）拷过来
6. `xurl`、`ccline` 不是 brew 包，按 `extras` 步骤的提示手动放二进制

## 重新生成快照

环境变了之后，在旧机器上更新 Brewfile：

```bash
brew bundle dump --file=~/code/machine-setup/Brewfile --force --describe
```
