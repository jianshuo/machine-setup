# machine-setup

在一台新的 **Apple Silicon Mac** 上，把王建硕（Neo 机器）的开发环境一键复刻出来。

快照来源：macOS 26.4 / arm64 / zsh / Homebrew 5.1。

## 一键安装

```bash
git clone <这个仓库> ~/code/machine-setup   # 或直接拷整个目录过去
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

## 密钥（重要）

脚本**不含**真实密钥。`.zshrc` 会自动 `source` 两个文件：

- `~/.config/secrets.env` —— 从 `secrets.env.example` 拷过去后填真实值
- `~/code/.env` —— 从旧机器整体拷过来（**别提交到公开 repo**）

需要填的：`VOLC_APPID`、`MODEL_SPEECH_API_KEY`、`X_ACCESS_TOKEN`，以及 `~/code/.env` 里的其它密钥。

## 跑完之后手动几步

1. 填 `~/.config/secrets.env`，拷 `~/code/.env`
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
