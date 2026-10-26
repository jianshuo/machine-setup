# 代理使用手册（Just My Socks + Clash Verge）

> 本 repo 是公开的：这里**不写**订阅链接、UUID、IP。订阅链接里的 `id=` 等于密码，只放在 JMS 后台和 Clash Verge 里。

## 0. 一句话

用 **Clash Verge Rev** 订阅 JMS 的 **Mihomo / Clash.Meta YAML 订阅**，选 **VLESS/Reality** 节点（s2 / s3 / s4 / s5 / s801），本机代理端口 **127.0.0.1:7897**。Jamjams 是备选，两者别同时开。

## 1. 服务现状（2026-10）

| 项目 | 说明 |
|------|------|
| 服务 | Just My Socks LA 1000，1TB/月 |
| 协议 | 已全面迁到 **VLESS + Reality**（flow `xtls-rprx-vision`，fingerprint chrome，端口 443） |
| s1 | 唯一剩下的 Shadowsocks（11799），只做临时兼容，**很快下线，别选** |
| IP | JMS 会不定期换 IP——**永远用订阅，不要手抄 IP**；手里配置一旧，节点就全挂 |

后台入口：JMS Client Area → Services → My Services → 选服务 → **Subscription**。那里有两种订阅：

- **Mihomo / Clash.Meta YAML**（链接带 `format=clash`）→ 给 Clash Verge
- **标准订阅**（v2ray base64）→ 给 Jamjams / v2rayN / v2rayNG

## 2. 主力方案：Clash Verge Rev（Mac）

Clash Verge 2.5.x 内核是 mihomo，原生支持 VLESS/Reality。老的 Clash / ClashX 内核不行。

1. **导入订阅**（已导入可跳过）：订阅页 → 粘贴 Mihomo YAML 订阅链接 → 导入，设为当前配置。
2. **更新订阅**：订阅页 → 右键 JMS 订阅 → 更新。节点连不上时**第一件事就是更新订阅**。
3. **设自动更新**：编辑订阅 → 更新间隔填 `1440`（分钟）。
4. **选节点**：代理页 → `JMS` 组选 s2–s5 / s801 任一个，或用 `JMS Auto` 自动测速。不要选 s1。
5. **开代理**：
   - **系统代理**：浏览器和读系统代理的 App（Python requests、Go 程序等）生效。
   - **TUN 模式**：接管整机流量，命令行工具不设环境变量也能走代理。

本机端口（Clash Verge 设置里的值，以 `verge.yaml` 为准）：

| 端口 | 用途 |
|------|------|
| 7897 | mixed（HTTP + SOCKS5），终端/脚本用这个 |
| 7898 | SOCKS5 |
| 7895 | redir |

## 3. 终端里用代理

`proxy.sh` 负责终端环境变量。它**只在 7897 真的在监听时**才 export，并打印 `● PROXY ON` / `● PROXY OFF`。

目前 `shellrc` 里 `source proxy.sh` 那行是**注释掉的**，所以新终端默认不设代理变量（开了 TUN 模式时也不需要）。

| 想要 | 做法 |
|------|------|
| 当前终端临时开 | `source ~/code/machine-setup/proxy.sh` |
| 以后每个终端自动开 | 去掉 `shellrc` 里 `# source $HOME/code/machine-setup/proxy.sh` 的注释，重开终端 |
| 关掉 | `proxy-off`（source 过 proxy.sh 才有这个 alias），或 `unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy` |
| 测速 / 看出口 | `proxy-test`（端口检查 + 出口 IP/国家 + 延迟 + 10MB 下载打分） |

注意：环境变量在 shell **启动那一刻**就定了，改了配置要**重开终端窗口**，旧窗口会一直带着旧值。

## 4. 备选方案：Jamjams（Mac）

JMS 官方推荐的客户端，适合「整机 VPN、不折腾规则」。用**标准订阅**，不是 Clash 那个。

- **官网版**（jamjamsapp.com/macos.html，现最新 2.4.4）：首次要批准系统扩展——系统设置 → 通用 → 登录项与扩展 → **网络扩展** → 打开 Jamjams。没批准就会报「VPN 配置所使用的 VPN App 尚未安装」。
- **App Store 版**：用 App 内置的网络扩展，首次只要点「允许添加 VPN 配置」，不用批准系统扩展。换版本前先删旧 App，并删掉 系统设置 → 网络 → VPN 里的旧配置。

**Jamjams 和 Clash Verge（系统代理/TUN）不要同时开**，会抢系统代理和路由。

## 5. 排查清单

```bash
env | grep -i proxy          # 终端变量：有值 = proxy.sh 或旧窗口带的
scutil --proxy               # 系统代理：HTTPEnable : 1 = Clash Verge 系统代理开着
nc -z 127.0.0.1 7897 && echo up || echo down   # Clash Verge 是否在听
systemextensionsctl list | grep -i jamjams     # Jamjams 扩展状态，要 [activated enabled]
scutil --nc list             # VPN 配置列表（Jamjams 那条）
proxy-test                   # 出口 IP / 速度
```

| 症状 | 原因 → 处理 |
|------|-------------|
| 节点全超时 | 订阅过期（IP 换了 / 协议迁了）→ 更新订阅 |
| 只看到 s1 | 客户端太老或订阅格式不对 → 升级客户端，重新导入完整订阅，去掉排除 VLESS 的过滤 |
| 终端里代理一直是 127.0.0.1 | proxy.sh 被 source，或旧窗口，或 Clash Verge 的系统代理 → 看上面前两条命令 |
| Jamjams「VPN App 尚未安装」 | 系统扩展没批准 → 网络扩展里打开，或换 App Store 版 |
| 更新订阅本身失败 | 订阅站被墙 → 先连上一个还能用的节点再更新，或在订阅设置里勾「使用代理更新」 |

还不行就找 JMS 客服：附 App 名称+版本、系统版本、节点列表截图（**遮住凭据，不要发订阅链接**）。
