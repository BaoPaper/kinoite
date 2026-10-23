# kinoite

基于 Fedora Kinoite 的自用 bootc 镜像，预装 tailscale、fcitx5-rime、distrobox 等。

镜像：`ghcr.io/baopaper/kinoite:44`（每次构建都用 cosign 签名）

## 切换

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker://ghcr.io/baopaper/kinoite:44
sudo systemctl reboot
```

## 补上签名验证（首次切换后）

首次 `rpm-ostree rebase` 后 origin 是 `ostree-unverified-registry:`，之后升级不再验签。
确认要长期使用后，补上严格策略并切到签名 transport（镜像已在本地，不会重新下载）：

```bash
sudo tee /etc/containers/policy.json >/dev/null <<'EOF'
{
  "default": [{ "type": "reject" }],
  "transports": {
    "docker": {
      "ghcr.io/baopaper/kinoite": [
        { "type": "sigstoreSigned", "keyPath": "/etc/pki/containers/baopaper.pub",
          "signedIdentity": { "type": "matchRepository" } }
      ],
      "ghcr.io": [{ "type": "insecureAcceptAnything" }],
      "docker.io": [{ "type": "insecureAcceptAnything" }],
      "quay.io": [{ "type": "insecureAcceptAnything" }],
      "registry.fedoraproject.org": [{ "type": "insecureAcceptAnything" }]
    },
    "containers-storage": { "": [{ "type": "insecureAcceptAnything" }] }
  }
}
EOF

sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/baopaper/kinoite:44
sudo systemctl reboot
```

重启后确认第一行变成 `ostree-image-signed:docker://…`，之后升级即强制验签：

```bash
rpm-ostree status | head -1
sudo rpm-ostree upgrade --check
```

## 验证签名

```bash
cosign verify \
  --key https://raw.githubusercontent.com/BaoPaper/kinoite/main/cosign.pub \
  ghcr.io/baopaper/kinoite:44
```

## 更新

```bash
sudo rpm-ostree upgrade --check   # 只看有没有新版本
sudo rpm-ostree upgrade           # 拉取并在下次重启生效
sudo systemctl reboot
```

## 回滚

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## 镜像站（可选）

国内拉取慢可加 registry mirror：

```bash
sudo mkdir -p /etc/containers/registries.conf.d
sudo tee /etc/containers/registries.conf.d/10-ghcr-mirror.conf <<'EOF'
[[registry]]
location = "ghcr.io"
[[registry.mirror]]
location = "ghcr.nju.edu.cn"
EOF
```

注意：用镜像站时必须同时有 `/etc/containers/registries.d/ghcr.yaml` 里的
`default-docker: use-sigstore-attachments: true`（镜像内已自带），否则验签找不到签名。
