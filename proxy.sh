
# ===== 代理（本机走 127.0.0.1:1087 / socks5 1086）=====
# 只在本地代理真的在监听时才启用——新机器没装代理 app 时自动跳过，curl/npm 不会被带坏。
if nc -z -w 1 127.0.0.1 1087 >/dev/null 2>&1; then
  export HTTP_PROXY="http://127.0.0.1:1087"
  export HTTPS_PROXY="http://127.0.0.1:1087"
  export ALL_PROXY="socks5://127.0.0.1:1086"
  export http_proxy="$HTTP_PROXY"
  export https_proxy="$HTTPS_PROXY"
  export all_proxy="$ALL_PROXY"
  export NODE_USE_ENV_PROXY=1
  export NO_PROXY="localhost,127.0.0.1,::1"
  export no_proxy="$NO_PROXY"
fi

alias proxy-on='export HTTP_PROXY="http://127.0.0.1:1087"; export HTTPS_PROXY="http://127.0.0.1:1087"; export ALL_PROXY="socks5://127.0.0.1:1086"; export http_proxy="$HTTP_PROXY"; export https_proxy="$HTTPS_PROXY"; export all_proxy="$ALL_PROXY"; export NODE_USE_ENV_PROXY=1; echo "Proxy ON: http 1087 / socks5 1086"'
alias proxy-off='unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy NODE_USE_ENV_PROXY; echo "Proxy OFF"'
alias proxy-test='echo "=== Proxy Test ==="; \
echo -n "Public IP: "; curl -s https://ipinfo.io/ip; echo; \
echo -n "Country: "; curl -s https://ipinfo.io/country; echo; \
echo -n "Region/City: "; curl -s https://ipinfo.io/region; echo ", "; curl -s https://ipinfo.io/city; echo; \
echo "==================="'

# 关掉 undici EnvHttpProxyAgent 的实验性警告(代理走 NODE_USE_ENV_PROXY 时会喷)
export NODE_OPTIONS="--disable-warning=UNDICI-EHPA"
