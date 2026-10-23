FROM quay.io/fedora/fedora-kinoite:44

# 供 GHCR 把镜像关联到仓库页面（Packages 里能直接跳转源码）
LABEL org.opencontainers.image.title="kinoite" \
      org.opencontainers.image.description="Fedora Kinoite 44 + Tailscale / fcitx5-rime / distrobox" \
      org.opencontainers.image.source="https://github.com/BaoPaper/kinoite"

# 1. 注入你的防篡改公钥与签名验证策略
COPY cosign.pub /etc/pki/containers/baopaper.pub
COPY policy.json /etc/containers/policy.json

# 2. 添加 Tailscale 官方源
RUN curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo -o /etc/yum.repos.d/tailscale.repo

# 3. 固化你的专属软件包（在 Fedora 44 中 dnf 已原生适配容器构建）
RUN dnf install -y \
        distrobox \
        fcitx5-rime \
        kcm-fcitx5 \
        fish \
        helix \
        kitty-terminfo \
        tailscale \
        webkit2gtk4.1 && \
    dnf clean all && \
    rm -rf /var/cache/* /var/log/* /tmp/*

# 4. 开启系统级守护进程（开机自启 Tailscale）
RUN systemctl enable tailscaled.service

# 5. 提交并校验 OSTree 容器文件树规范
RUN ostree container commit && bootc container lint
