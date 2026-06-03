#!/usr/bin/env bash
# ==========================================================================
# machine-setup — 在新 Mac（Apple Silicon）上复刻王建硕的开发环境
#
#   bash setup.sh           # 全套，逐步确认
#   bash setup.sh --yes     # 全套，不再逐步确认
#   bash setup.sh brew      # 只跑某一步：brew / runtimes / npm / dotfiles / claude / extras
#
# 幂等：每步都可重复跑。密钥不在脚本里，见 secrets.env.example。
# ==========================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_VERSION="22"          # nvm 默认 node 大版本（旧机器为 v22.22.3）

AUTO=0
[ "${1:-}" = "--yes" ] && { AUTO=1; shift; }
ONLY="${1:-all}"

c(){ printf "\033[1;36m==> %s\033[0m\n" "$*"; }
ok(){ printf "\033[1;32m  ✓ %s\033[0m\n" "$*"; }
warn(){ printf "\033[1;33m  ! %s\033[0m\n" "$*"; }
ask(){ [ "$AUTO" = 1 ] && return 0; read -r -p "  $1 [Y/n] " a; [ -z "$a" ] || [[ "$a" =~ ^[Yy] ]]; }
run(){ [ "$ONLY" = all ] || [ "$ONLY" = "$1" ]; }

# --------------------------------------------------------------------------
step_brew(){
  run brew || return 0
  c "Homebrew + Brewfile"
  if ! command -v brew >/dev/null 2>&1; then
    ask "未检测到 Homebrew，现在安装？" && \
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
  if ask "用 Brewfile 安装所有包（formulae/casks/uv/npm/vscode）？"; then
    brew bundle --file="$HERE/Brewfile" || warn "部分包失败，可重跑"
    ok "brew bundle 完成"
  fi
}

# --------------------------------------------------------------------------
step_runtimes(){
  run runtimes || return 0
  c "运行时：nvm + node + uv"
  export NVM_DIR="$HOME/.nvm"; mkdir -p "$NVM_DIR"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  if command -v nvm >/dev/null 2>&1 || type nvm >/dev/null 2>&1; then
    nvm install "$NODE_VERSION" && nvm alias default "$NODE_VERSION" && ok "node $(node -v 2>/dev/null) via nvm"
  else
    warn "nvm 还没加载，先 source ~/.zshrc 后再跑 'bash setup.sh runtimes'"
  fi
  if ! command -v uv >/dev/null 2>&1; then
    ask "安装 uv（Astral）？" && curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  ok "运行时就绪"
}

# --------------------------------------------------------------------------
step_npm(){
  run npm || return 0
  c "全局 npm 包（Brewfile 里的 npm 行已装一遍，这里兜底）"
  command -v npm >/dev/null 2>&1 || { warn "npm 不可用，先跑 runtimes"; return 0; }
  npm install -g \
    @earendil-works/pi-coding-agent \
    @openai/codex \
    ccglass \
    corepack 2>/dev/null && ok "全局 npm 包完成" || warn "部分 npm 包失败"
}

# --------------------------------------------------------------------------
backup(){ [ -e "$1" ] && cp "$1" "$1.bak.$(date +%s)" && warn "已备份 $1 → $1.bak.*"; }

step_dotfiles(){
  run dotfiles || return 0
  c "dotfiles：.zshrc / .zprofile / git / secrets"
  if ask "部署 .zshrc 和 .zprofile？（会先备份现有的）"; then
    backup "$HOME/.zshrc";    cp "$HERE/zshrc.template"    "$HOME/.zshrc"
    backup "$HOME/.zprofile"; cp "$HERE/zprofile.template" "$HOME/.zprofile"
    ok ".zshrc / .zprofile 已部署"
  fi
  mkdir -p "$HOME/.config"
  # 占位符模板（已存在就不覆盖，免得抹掉填好的真实值）
  seed(){ [ -f "$2" ] && { ok "$2 已存在，跳过"; return; }; cp "$1" "$2"; warn "已生成 $2（占位符）——记得填真实值！"; }
  seed "$HERE/secrets.env.example"      "$HOME/.config/secrets.env"
  seed "$HERE/machine-local.zsh.example" "$HOME/.config/machine-local.zsh"
  mkdir -p "$HOME/code"
  seed "$HERE/env.example"              "$HOME/code/.env"
  # git 身份：从 machine-local.zsh 读 GIT_USER_NAME / GIT_USER_EMAIL
  [ -f "$HOME/.config/machine-local.zsh" ] && source "$HOME/.config/machine-local.zsh"
  if [ -n "${GIT_USER_NAME:-}" ] && [[ "$GIT_USER_NAME" != 你的名字 ]]; then
    git config --global user.name  "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    ok "git 身份：$GIT_USER_NAME <$GIT_USER_EMAIL>"
  else
    warn "git 身份未设：填好 ~/.config/machine-local.zsh 里的 GIT_USER_* 后重跑 dotfiles"
  fi
}

# --------------------------------------------------------------------------
step_claude(){
  run claude || return 0
  c "Claude Code：CLI + marketplaces + plugins"
  bash "$HERE/claude-setup.sh" "$AUTO"
}

# --------------------------------------------------------------------------
step_extras(){
  run extras || return 0
  c "额外的独立二进制：xurl / ccline"
  if ! command -v xurl >/dev/null 2>&1; then
    warn "xurl 不是 brew 包（X 官方 CLI 的 arm64 二进制）。"
    echo "    去 https://github.com/xdevplatform/xurl/releases 下 darwin-arm64，"
    echo "    chmod +x 后放到 /opt/homebrew/bin/xurl"
  else ok "xurl 已在"; fi
  if [ ! -f "$HOME/.config/ccline/ccline.zsh" ]; then
    warn "ccline 未部署：它的二进制在 ~/.local/bin/ccline，配置在 ~/.config/ccline/。"
    echo "    从旧机器拷 ~/.local/bin/ccline 和 ~/.config/ccline/ 整个目录过来即可。"
  else ok "ccline 已在"; fi
}

# --------------------------------------------------------------------------
echo "================ machine-setup ($ONLY) ================"
step_brew
step_runtimes
step_npm
step_dotfiles
step_claude
step_extras
echo
c "完成。接下来："
echo "  1) 填密钥：编辑 ~/.config/secrets.env，并把旧机器的 ~/code/.env 拷过来"
echo "  2) 新开终端 / source ~/.zshrc"
echo "  3) 若新机无本地代理，注释掉 ~/.zshrc 顶部的代理 export 块"
echo "  4) claude /login 登录；gh auth login 登录 GitHub"
