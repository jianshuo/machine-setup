#!/usr/bin/env bash
# Claude Code：CLI + marketplaces + 用户级 plugins
# 被 setup.sh 调用，也可单独跑： bash claude-setup.sh
set -uo pipefail
AUTO="${1:-0}"
ask(){ [ "$AUTO" = 1 ] && return 0; read -r -p "  $1 [Y/n] " a; [ -z "$a" ] || [[ "$a" =~ ^[Yy] ]]; }
ok(){ printf "\033[1;32m  ✓ %s\033[0m\n" "$*"; }
warn(){ printf "\033[1;33m  ! %s\033[0m\n" "$*"; }

# 1) Claude Code CLI（原生安装器，落在 ~/.local/bin/claude）
if ! command -v claude >/dev/null 2>&1; then
  ask "安装 Claude Code CLI？" && curl -fsSL https://claude.ai/install.sh | bash
fi
command -v claude >/dev/null 2>&1 && ok "claude $(claude --version 2>/dev/null)" || { warn "claude 未安装，后续跳过"; exit 0; }

# 2) Plugin marketplaces
add_market(){ claude plugin marketplace add "$1" 2>/dev/null && ok "marketplace + $1" || warn "marketplace $1 可能已存在"; }
add_market "anthropics/claude-plugins-official"
add_market "anthropics/financial-services"

# 3) 用户级 plugins（来自 settings.json 的 enabledPlugins）
USER_PLUGINS=(
  superpowers@claude-plugins-official
  frontend-design@claude-plugins-official
  vercel@claude-plugins-official
  telegram@claude-plugins-official
  imessage@claude-plugins-official
  swift-lsp@claude-plugins-official
  claude-code-setup@claude-plugins-official
)
for p in "${USER_PLUGINS[@]}"; do
  claude plugin install "$p" 2>/dev/null && ok "plugin + $p" || warn "plugin $p 失败/已装"
done

# 4) financial-services 的 plugins 是 project 级（绑 ~/code/financial-services），
#    在那个 repo 里跑 claude 时按需装，这里不强装。
warn "financial-services 系列 plugin 是 project 级，进 ~/code/financial-services 后再装"

cat <<'EOF'

  Claude 这套还需手动：
   - claude /login            登录账号（或用 cc-switch 切换）
   - 你 ~/.claude/skills/ 下的大量自写 skill 不会自动过来，
     建议从旧机器把 ~/.claude/skills/ 整个目录拷过来（或各自的 git repo）。
   - ~/.claude/settings.json 里的 hooks / statusLine / permissions 也建议拷过来。
EOF
