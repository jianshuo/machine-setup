#!/usr/bin/env bash
# ==========================================================================
# publish-web.sh — 把 machine-setup 的安装文件同步发布到 https://jianshuo.dev/setup/
#
# 解决的问题：有些网络环境访问不了 github.com，新机器没法 git clone 本 repo。
# 所以把安装所需的文件镜像在自己的网站上，setup.sh 单文件即可自举（见 setup.sh 顶部）。
#
# 只发布下面 FILES 清单里明确列出的文件（取 HEAD 版本，不含 git 历史、
# 不含未提交/未跟踪内容）。产物（生成的，别手改网站里的副本）：
#   <site>/setup/setup.sh             ← curl 自举入口
#   <site>/setup/machine-setup.tar.gz ← FILES 清单打包
#
# 同步机制：.git/hooks/post-commit 每次 commit 后自动调本脚本（幂等，HEAD 没变
# 就直接退出），也可手动跑 `bash publish-web.sh`。
# ==========================================================================
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE="$HOME/code/websites/jianshuo.dev"
DEST="$SITE/setup"

# setup.sh 运行所需的全部文件（白名单，新增依赖时记得加）
FILES=(
  setup.sh
  claude-setup.sh
  Brewfile
  zshrc.template
  zprofile.template
  env.example
  README.md
)

[ -d "$SITE/.git" ] || { echo "!! 找不到网站 repo：$SITE"; exit 1; }
mkdir -p "$DEST"

REV="$(git -C "$HERE" rev-parse HEAD)"
if [ "$(cat "$DEST/.rev" 2>/dev/null)" = "$REV" ]; then
  echo "✓ jianshuo.dev/setup 已是 ${REV:0:7}，跳过"
  exit 0
fi

# 1) 从 HEAD 导出白名单文件到临时目录，打成 tar 包
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/machine-setup"
for f in "${FILES[@]}"; do
  git -C "$HERE" show "HEAD:$f" > "$TMP/machine-setup/$f"
done
chmod +x "$TMP/machine-setup/setup.sh" "$TMP/machine-setup/claude-setup.sh"
tar -czf "$DEST/machine-setup.tar.gz" -C "$TMP" machine-setup

# 2) setup.sh 单文件（自举入口），和 tar 包严格同版本
git -C "$HERE" show HEAD:setup.sh > "$DEST/setup.sh"
echo "$REV" > "$DEST/.rev"

# 3) 网站 repo 提交 + 部署到 Cloudflare Pages
cd "$SITE"
git add setup/
if git diff --cached --quiet; then
  echo "✓ 网站内容无变化"
else
  git commit -m "sync machine-setup ${REV:0:7}"
fi
npx wrangler pages deploy . --project-name jianshuo-dev --branch main
echo "✓ 已发布 https://jianshuo.dev/setup/setup.sh （machine-setup ${REV:0:7}）"
