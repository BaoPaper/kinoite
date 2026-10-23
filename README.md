# kinoite

在 Fedora Kinoite 44 基础上叠加自用软件，并通过 GitHub Actions 每天自动重建、签名、推送到 GHCR 的 bootc 系统镜像。

## 镜像

```text
ghcr.io/baopaper/kinoite:44                     # 浮动的每日构建
ghcr.io/baopaper/kinoite:44-YYYYMMDD-<sha>      # 固定版本，便于回到某一天
```

每次构建先推日期 tag，**签名 + 验签通过后才移动 `:44`**，因此 `:44` 永远指向已签名的镜像。

预装内容：

- `tailscale`（`tailscaled` 已 enable，首次开机执行 `sudo tailscale up`）
- `fcitx5-rime` + `kcm-fcitx5`（Rime 输入法及其 KCM 配置模块）
- `distrobox`
- `fish`、`helix`、`kitty-terminfo`、`webkit2gtk4.1`
- `/etc/containers/policy.json` + `/etc/pki/containers/baopaper.pub`：仅对本镜像强制 cosign 验签

## 安装 / 切换

任意 bootc 系统（含官方 Fedora Kinoite 44）上执行：

```bash
sudo bootc switch --download-only ghcr.io/baopaper/kinoite:44   # 先下载、暂不应用
sudo bootc switch --from-downloaded --apply                     # 应用并重启
```

全新安装可参考 `bootc install to-disk`，或先用官方 ISO 装好再切换（这样只会下载差异部分，最快）。

> GHCR 上的 package 必须设为 **Public**（GitHub → Packages → kinoite → Package settings），
> 否则匿名拉取和上面提到的镜像站都无法工作。

> 首次切换时，宿主机用的还是 Fedora 自带的宽松策略，所以这一次并不会自动验签。
> 切换前先跑一次下面的 `cosign verify`，把信任建立在第一次操作上。

> 由于策略的 `default` 是放行，`--enforce-container-sigpolicy` 会报
> `containers-policy.json specifies a default of insecureAcceptAnything; refusing usage`。
> 这是预期行为——本镜像的验签由 `policy.json` 中针对 `ghcr.io/baopaper/kinoite`
> 的 `sigstoreSigned` 规则保证，不需要该 flag。

## 验签

```bash
cosign verify --key cosign.pub ghcr.io/baopaper/kinoite:44
```

## 更新 / 回滚

```bash
sudo bootc upgrade --check           # 只看有没有新版本
sudo bootc upgrade --download-only   # 空闲时段预下载
sudo bootc upgrade --apply           # 应用并重启
sudo bootc rollback                  # 回到上一个版本
bootc status                         # 当前镜像与 digest
```

## 加速（可选）

`/etc/containers/registries.conf.d/10-ghcr-mirror.conf`：

```toml
[[registry]]
location = "ghcr.io"

[[registry.mirror]]
location = "ghcr.nju.edu.cn"
```

镜像站只影响传输通道，返回的 digest 与主站一致，验签不受影响；`bootc` 记录的更新源仍是
`ghcr.io/baopaper/kinoite:44`。注意 `cosign verify` 不读该配置，会直连 ghcr.io。

镜像站对 tag 有解析缓存，刚构建完可能短暂拿到旧的 `:44`；要立刻切换就临时用日期 tag
或 digest。

## 安全策略说明

`policy.json` 的 `default` 是 `insecureAcceptAnything`，只对 `ghcr.io/baopaper/kinoite`
强制验签：

- 好处：日常 `podman pull` / `distrobox create` 任何源都不受影响，和原版 Fedora 一致。
- 保护范围：伪造本仓库镜像无法被安装或更新；但 `bootc switch` 到**其他**镜像时不会验签。

若希望“未放行的源一律拒绝”（fail-closed），把 `default` 改成 `reject`，并把需要的
registry 逐条加进 `transports.docker`；此时 `--enforce-container-sigpolicy` 也可用。
代价是每加一个新源都要改 `policy.json` 并重建镜像。

## 构建

- 触发：推送到 `main`/`master`、每天 UTC 22:00（北京时间 06:00）、手动 `workflow_dispatch`
- Runner：`ubuntu-latest`，构建前清理约 20 GB 预装工具链
- 流程：`podman build` → 推日期 tag → `cosign sign` → `cosign verify` → 移动 `:44`
- 需要 secrets：`GITHUB_TOKEN`（自动提供）、`SIGNING_SECRET`（cosign 私钥）
