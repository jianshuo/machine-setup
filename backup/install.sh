#!/bin/zsh
# install.sh — 安装 / 更新每晚加密备份（launchd 03:30）。可重复运行。
#   zsh backup/install.sh
# 脚本拷到 ~/.local/share/mac-backup/（本地路径；launchd 读不了 iCloud），
# 这样仓库切分支、改 worktree 都不影响定时任务。
set -euo pipefail
SRC="${0:A:h}"
DEST="$HOME/.local/share/mac-backup"
LABEL="com.jianshuo.mac-backup"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

command -v restic >/dev/null || brew install restic

mkdir -p "$DEST"
install -m 755 "$SRC/mac-backup.sh" "$DEST/mac-backup.sh"
install -m 644 "$SRC/excludes.txt" "$DEST/excludes.txt"

# 加密密码：没有就生成。务必另存一份到本机以外（iCloud / 密码管理器），否则丢机 = 备份解不开
P="$HOME/.config/restic/mac-backup.pass"
if [ ! -f "$P" ]; then
  mkdir -p "${P:h}" && chmod 700 "${P:h}"
  openssl rand -base64 32 >"$P" && chmod 600 "$P"
  echo "⚠️  新生成了加密密码 $P —— 立刻把它另存到 iCloud / 密码管理器！"
fi

cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/bin/zsh</string><string>$DEST/mac-backup.sh</string></array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>3</integer><key>Minute</key><integer>30</integer></dict>
  <key>LowPriorityIO</key><true/>
  <key>Nice</key><integer>10</integer>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/mac-backup.launchd.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/mac-backup.launchd.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "✅ 已安装：每天 03:30 备份。手动立即跑：launchctl kickstart gui/$(id -u)/$LABEL"
