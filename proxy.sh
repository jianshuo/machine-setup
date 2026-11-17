
# ===== 代理（本机走 127.0.0.1:7897 / socks5 7897）=====
# 只在本地代理真的在监听时才启用——新机器没装代理 app 时自动跳过，curl/npm 不会被带坏。
if nc -z -w 1 127.0.0.1 7897 >/dev/null 2>&1; then
  export HTTP_PROXY="http://127.0.0.1:7897"
  export HTTPS_PROXY="http://127.0.0.1:7897"
  export ALL_PROXY="socks5://127.0.0.1:7897"
  export http_proxy="$HTTP_PROXY"
  export https_proxy="$HTTPS_PROXY"
  export all_proxy="$ALL_PROXY"
  export NODE_USE_ENV_PROXY=1
  export NO_PROXY="localhost,127.0.0.1,::1"
  export no_proxy="$NO_PROXY"
  printf '\033[32m● PROXY ON\033[0m  →  http 127.0.0.1:7897 / socks5 127.0.0.1:7897\n'
else
  printf '\033[1;31m● PROXY OFF — 终端直连，流量不走代理（启动 Clash Verge 后重开终端生效）\033[0m\n'
fi

alias proxy-on='export HTTP_PROXY="http://127.0.0.1:7897"; export HTTPS_PROXY="http://127.0.0.1:7897"; export ALL_PROXY="socks5://127.0.0.1:7897"; export http_proxy="$HTTP_PROXY"; export https_proxy="$HTTPS_PROXY"; export all_proxy="$ALL_PROXY"; export NODE_USE_ENV_PROXY=1; echo "Proxy ON: http 7897 / socks5 7897"'
alias proxy-off='unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy NODE_USE_ENV_PROXY; echo "Proxy OFF"'
proxy-test() {
  local target='1.1.1.1'
  local speed_url='https://speed.cloudflare.com/__down?bytes=10485760'
  local http_p=${http_proxy:-$HTTP_PROXY}
  local https_p=${https_proxy:-$HTTPS_PROXY}

  echo '=== Proxy Env ==='
  if [[ -n $https_p ]]; then
    printf 'HTTP  proxy: %s\n' $http_p
    printf 'HTTPS proxy: %s\n' $https_p
    printf 'SOCKS proxy: %s\n' ${all_proxy:-${ALL_PROXY:-<not set>}}
  else
    echo 'No proxy env vars set (will use direct connection)'
  fi
  echo ''

  echo '=== Proxy Port Check ==='
  if [[ -n $https_p ]]; then
    local host port
    host=$(printf '%s' $https_p | sed -E 's#https?://##; s#:.*##')
    port=$(printf '%s' $https_p | sed -E 's#.*:##; s#/.*##')
    if nc -z -w 2 $host $port 2>/dev/null; then
      printf '✓ %s:%s reachable\n' $host $port
    else
      printf '✗ %s:%s NOT reachable\n' $host $port
    fi
  fi
  echo ''

  echo '=== Public IP / Geo ==='
  curl -s -m 10 https://ipinfo.io/json 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -s -m 10 https://ipinfo.io/ip
  echo ''

  printf '=== Latency (ping %s) ===\n' $target
  ping -c 5 -W 1000 $target | tail -2
  echo ''

  printf '=== Route (traceroute %s) ===\n' $target
  traceroute -q 1 -m 15 -w 2 $target 2>/dev/null || echo 'traceroute failed'
  echo ''

  echo '=== HTTP Download Speed (10 MB via proxy if set) ==='
  local out
  out=$(curl -L -o /dev/null -m 60 -s -w 'DNS lookup: %{time_namelookup}s\nTCP connect: %{time_connect}s\nTLS handshake: %{time_appconnect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\nSpeed: %{speed_download} B/s\nSize: %{size_download} bytes\nSCORE total=%{time_total} speed=%{speed_download}\n' $speed_url 2>/dev/null)
  if [[ -n $out ]] && printf '%s\n' "$out" | grep -q '^SCORE '; then
    printf '%s\n' "$out" | grep -v '^SCORE '
    local total speed score
    total=$(printf '%s\n' "$out" | grep '^SCORE ' | awk '{print $2}' | cut -d= -f2)
    speed=$(printf '%s\n' "$out" | grep '^SCORE ' | awk '{print $3}' | cut -d= -f2)
    score=$(awk -v t="$total" -v s="$speed" 'BEGIN {
      if (t == "" || s == "" || t+0 == 0) { print "N/A"; exit }
      mbps = s * 8 / 1000000
      if (t < 2 && mbps > 100) grade="A (excellent)"
      else if (t < 5 && mbps > 30) grade="B (good)"
      else if (t < 15 && mbps > 8) grade="C (ok)"
      else if (t < 30) grade="D (slow)"
      else grade="F (very slow)"
      print "Speed Score:", grade, "|", mbps, "Mbps | total", t, "s"
    }')
    echo ''
    printf '  %s\n' "$score"
  else
    echo '  Speed test failed'
  fi
  echo '==================='
}

# 关掉 undici EnvHttpProxyAgent 的实验性警告(代理走 NODE_USE_ENV_PROXY 时会喷)
export NODE_OPTIONS="--disable-warning=UNDICI-EHPA"
