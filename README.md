# kinoite

基于 Fedora Kinoite 的自用 bootc 镜像，预装 tailscale、fcitx5-rime、distrobox、完整 ffmpeg 与 VA-API 硬件解码驱动等。

镜像：`ghcr.io/baopaper/kinoite:44`（每次构建都用 cosign 签名）

## 切换

```bash
sudo rpm-ostree rebase ostree-unverified-registry:docker://ghcr.io/baopaper/kinoite:44
sudo systemctl reboot
```

## 切到签名 transport（首次切换后）

首次 `rpm-ostree rebase` 后 origin 是 `ostree-unverified-registry:`，之后升级不再验签。
确认要长期使用后，切到签名 transport 即可。镜像内已经自带验签配置，不需要再手写 policy：

- `/etc/containers/policy.json`：只对 `ghcr.io/baopaper/kinoite` 强制 sigstore 验签，其余镜像默认放行，避免影响 distrobox / podman 日常拉取
- `/etc/pki/containers/baopaper.pub`：验签公钥
- `/etc/containers/registries.d/ghcr.yaml`：启用 `use-sigstore-attachments`

```bash
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

## 虚拟化（virt-manager / KVM）

镜像已预装 `virt-manager`、`libvirt`、`qemu-kvm`、`edk2-ovmf`、`swtpm`，并启用了模块化 libvirt socket（`virtqemud.socket`、`virtnetworkd.socket` 等）。

首次使用前把当前用户加入 `libvirt` 组，重新登录后生效（否则 virt-manager 连 `qemu:///system` 会反复弹认证）：

```bash
sudo usermod -aG libvirt "$USER"
# 注销重新登录
```

然后打开 virt-manager，使用默认的 `QEMU/KVM` 系统连接即可。自检：

```bash
ls -l /dev/kvm
virt-host-validate qemu
virsh -c qemu:///system net-list --all   # default 网络应为 autostart
```

装 Windows 11 这类需要 UEFI + TPM 的虚拟机时，固件选 `UEFI x86_64: ... OVMF`，并添加 TPM 2.0（swtpm）。

如果 Kinoite 本身跑在虚拟机里，需要宿主机开启嵌套虚拟化，否则没有 `/dev/kvm`。

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
