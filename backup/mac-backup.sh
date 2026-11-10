#!/bin/zsh
# mac-backup.sh — 每晚把本机「只在这台 Mac 上、丢了很疼」的东西加密增量备份到 R2。
#
# 工具：restic（客户端加密 + 去重 + 快照），仓库在 R2 桶 mac-backup。
# 由 launchd（com.jianshuo.mac-backup）每天 03:30 调用；也可以手动跑：
#   ~/.local/share/mac-backup/mac-backup.sh            # 备份一次
#   ~/.local/share/mac-backup/mac-backup.sh snapshots  # 任意 restic 子命令，环境已配好
#
# 需要（都不进 git）：
#   ~/code/.env 里：R2_MAC_BACKUP_ACCESS_KEY_ID / R2_MAC_BACKUP_SECRET_ACCESS_KEY
#                   R2_MAC_BACKUP_ENDPOINT（缺省沿用 R2_JIANSHUO_DEV_FILES_ENDPOINT，同一个账号）
#   ~/.config/restic/mac-backup.pass —— 仓库加密密码；另一份在 iCloud「我的账户和密码」
set -euo pipefail

# launchd 环境配方：密钥和代理都从单一真源读，绝不硬编码端口
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
[ -f "$HOME/code/.env" ] && . "$HOME/code/.env"
[ -f "$HOME/code/machine-setup/proxy.sh" ] && . "$HOME/code/machine-setup/proxy.sh" >/dev/null 2>&1

HERE="${0:A:h}"
LOG="$HOME/Library/Logs/mac-backup.log"
mkdir -p "${LOG:h}"

notify() {  # 失败时弹 Mac 通知，不然坏了也没人知道
  osascript -e "display notification \"$1\" with title \"Mac 备份\" sound name \"Basso\"" 2>/dev/null || true
}

endpoint="${R2_MAC_BACKUP_ENDPOINT:-${R2_JIANSHUO_DEV_FILES_ENDPOINT:-}}"
for v in R2_MAC_BACKUP_ACCESS_KEY_ID R2_MAC_BACKUP_SECRET_ACCESS_KEY endpoint; do
  if [ -z "${(P)v:-}" ]; then
    echo "$(date '+%F %T') 缺 ${v}（~/code/.env），未备份" >>"$LOG"
    notify "缺 ${v}，今晚没备份"
    exit 1
  fi
done
if [ ! -f "$HOME/.config/restic/mac-backup.pass" ]; then
  echo "$(date '+%F %T') 缺加密密码文件，未备份" >>"$LOG"
  notify "缺加密密码文件 ~/.config/restic/mac-backup.pass"
  exit 1
fi

export AWS_ACCESS_KEY_ID="$R2_MAC_BACKUP_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_MAC_BACKUP_SECRET_ACCESS_KEY"
export RESTIC_REPOSITORY="s3:${endpoint%/}/mac-backup"
export RESTIC_PASSWORD_FILE="$HOME/.config/restic/mac-backup.pass"
export RESTIC_CACHE_DIR="$HOME/Library/Caches/restic"

# 有参数 = 透传给 restic（查快照、恢复、check 等）
if (( $# > 0 )); then
  exec restic "$@"
fi

# 要备份的路径：只收存在的，避免一个缺失路径让整次备份失败
candidates=(
  "$HOME/.claude"                       # 对话历史、skill、settings、hooks、插件
  "$HOME/.claude.json"                  # MCP 服务器等全局配置
  "$HOME/code/.env"                     # 全部 API key
  "$HOME/.ssh"                          # 连 VPS / pro / neo 的私钥
  "$HOME/.codex/auth.json"              # Codex 订阅凭据（只用于换新机恢复，绝不拷到第二台机器同时用）
  "$HOME/.codex/config.toml"
  "$HOME/.appstoreconnect"              # App Store Connect .p8 私钥
  "$HOME/.config/gh"
  "$HOME/.gitconfig"
  "$HOME/.zshrc"
  "$HOME/.zprofile"
  "$HOME/Library/LaunchAgents"          # 所有定时任务的 plist
)
paths=()
for p in "${candidates[@]}"; do [ -e "$p" ] && paths+=("$p"); done

{
  echo "===== $(date '+%F %T') 开始备份"
  start=$SECONDS
  if restic backup --tag nightly --exclude-file "$HERE/excludes.txt" \
       --exclude-caches --one-file-system "${paths[@]}"; then
    # 保留策略：14 天日备 + 8 周周备 + 12 月月备；周日顺便 prune 回收空间
    if [ "$(date +%u)" = 7 ]; then
      restic forget --tag nightly --keep-daily 14 --keep-weekly 8 --keep-monthly 12 --prune
    else
      restic forget --tag nightly --keep-daily 14 --keep-weekly 8 --keep-monthly 12
    fi
    # 每月 1 号抽查 2% 数据确认能解密读出
    if [ "$(date +%d)" = 01 ]; then
      restic check --read-data-subset=2%
    fi
    echo "===== $(date '+%F %T') 完成，用时 $(( SECONDS - start ))s"
  else
    rc=$?
    echo "===== $(date '+%F %T') 失败 rc=${rc}"
    notify "备份失败（rc=${rc}），看 ~/Library/Logs/mac-backup.log"
    exit $rc
  fi
} >>"$LOG" 2>&1
