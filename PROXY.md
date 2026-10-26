# 代理使用手册

> 本 repo 是公开的：这里**不写**订阅链接、UUID、IP。

**完整图文教程（含订阅链接，有密码）：<https://jianshuo.dev/setup/>**

## 一句话

客户端用 **Jamjams**（JMS 官方推荐），导入 JMS **标准订阅**，选 **VLESS/Reality** 节点（s2 / s3 / s4 / s5 / s801）。s1 是旧 Shadowsocks，即将下线。**不再用 Clash Verge**——退出并取消开机自启，两个同时开会抢系统代理和路由。

## Mac 要点

- 官网版首次要批准系统扩展：系统设置 → 通用 → 登录项与扩展 → **网络扩展** → 打开 Jamjams。没批准会报「VPN 配置所使用的 VPN App 尚未安装」。
- 订阅：⚙ 设置 → Subscriptions → Add Subscription → Subscription URL。开自动更新（JMS 会换 IP）。
- 分流：⚙ 设置 → Routing → 打开 GeoIP routing（China 直连）。

## 终端

- Jamjams 默认开**透明代理**（整机隧道），终端不用设 `*_proxy` 变量。
- `proxy.sh` 只在 `127.0.0.1:7897`（Clash Verge 的端口）在监听时才 export；不开 Clash 就自动是 OFF。`shellrc` 里 source 那行也已注释。
- 想让个别程序显式走代理：Jamjams ⚙ → Network → 打开 **HTTP Proxy Server**（默认 `8080`），然后 `export https_proxy=http://127.0.0.1:8080`。

## 排查

```bash
env | grep -i proxy                         # 残留变量（如 7897）→ unset 或重开终端
scutil --nc list                            # Jamjams VPN 是否 Connected
systemextensionsctl list | grep -i jamjams  # 要 [activated enabled]
scutil --proxy                              # 系统代理状态
```
