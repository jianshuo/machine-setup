# mac-backup：每晚加密备份到 R2

把「只在这台 Mac 上、丢了很疼」的东西，每天 03:30 用 restic 加密、增量备份到 Cloudflare R2 桶 `mac-backup`。

## 备份范围

| 路径 | 内容 |
|---|---|
| `~/.claude` | Claude Code 对话历史、skill、settings、hooks、插件（排除 `jobs/`、缓存、遥测，见 `excludes.txt`） |
| `~/.claude.json` | MCP 服务器等全局配置 |
| `~/code/.env` | 全部 API key |
| `~/.ssh` | SSH 私钥 |
| `~/.codex/auth.json`、`config.toml` | Codex 订阅凭据 |
| `~/.appstoreconnect` | App Store Connect `.p8` 私钥 |
| `~/.config/gh`、`~/.gitconfig`、`~/.zshrc`、`~/.zprofile` | 工具配置 |
| `~/Library/LaunchAgents` | 所有定时任务 plist |

**不在范围内**：`~/code` 里的 git 仓库（在 GitHub）、iCloud 里的文件（在 iCloud）、大视频（另想办法）。

保留：14 个日备 + 8 个周备 + 12 个月备。周日 prune，每月 1 号抽查 2% 数据。

## 安装

1. Cloudflare 后台 → R2 → Manage API tokens → Create API token：权限 **Object Read & Write**，只勾桶 `mac-backup`。把 Access Key ID 和 Secret 写进 `~/code/.env`：
   ```
   export R2_MAC_BACKUP_ACCESS_KEY_ID=...
   export R2_MAC_BACKUP_SECRET_ACCESS_KEY=...
   ```
2. `zsh backup/install.sh`（装 restic、拷脚本到 `~/.local/share/mac-backup/`、注册 launchd）
3. 第一次初始化仓库：`~/.local/share/mac-backup/mac-backup.sh init`
4. 立即跑一次：`launchctl kickstart gui/$(id -u)/com.jianshuo.mac-backup`，看 `~/Library/Logs/mac-backup.log`

## 日常

```zsh
B=~/.local/share/mac-backup/mac-backup.sh
$B snapshots                 # 列快照
$B stats latest              # 最新快照大小
$B ls latest ~/.ssh          # 看某快照里有什么
tail -f ~/Library/Logs/mac-backup.log
```

失败会弹 Mac 通知。

## 丢机后恢复（在新 Mac 上）

需要三样东西，**都不依赖旧 Mac**：

1. **加密密码**：iCloud Drive →「我的账户和密码」→ `mac-backup-restic-RESTORE.txt`（iPhone 上也能打开）
2. **R2 密钥**：登录 Cloudflare 后台新建一把 `mac-backup` 桶的 R2 token（旧的在 `.env` 里，而 `.env` 本身就在备份里）
3. **Endpoint**：同样写在上面那个 RESTORE 文件里

```zsh
brew install restic
export AWS_ACCESS_KEY_ID=新的AccessKeyID AWS_SECRET_ACCESS_KEY=新的Secret
export RESTIC_REPOSITORY="s3:<RESTORE 文件里的 endpoint>/mac-backup"
restic snapshots                                  # 会提示输入密码
restic restore latest --target /tmp/restore       # 先恢复到临时目录
# 再把需要的拷回原位，例如：
cp -R /tmp/restore/Users/jianshuo/.claude ~/
cp /tmp/restore/Users/jianshuo/code/.env ~/code/.env
cp -R /tmp/restore/Users/jianshuo/.ssh ~/ && chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*
```

注意：`~/.codex/auth.json` 只在**旧机已不再使用**时恢复，两台机器同时用同一份会互踢 401。
