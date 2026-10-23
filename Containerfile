FROM quay.io/fedora/fedora-kinoite:44

LABEL org.opencontainers.image.title="kinoite" \
      org.opencontainers.image.description="BaoPaper's Fedora Kinoite 44" \
      org.opencontainers.image.source="https://github.com/BaoPaper/kinoite"

COPY cosign.pub /etc/pki/containers/baopaper.pub
COPY policy.json /etc/containers/policy.json
COPY ghcr-sigstore.yaml /etc/containers/registries.d/ghcr.yaml

# 基础工具与 RPM Fusion 仓库；随后替换 ffmpeg 和 Mesa 驱动。
RUN curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo -o /etc/yum.repos.d/tailscale.repo && \
    dnf install -y \
        distrobox \
        fcitx5-rime \
        kcm-fcitx5 \
        fish \
        helix \
        kitty \
        tailscale \
        syncthing \
        chezmoi \
        just \
        btop \
        fastfetch \
        trash-cli \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf install -y \
        mesa-va-drivers-freeworld \
        intel-media-driver \
        libva-utils && \
    dnf swap -y --allowerasing mesa-vulkan-drivers mesa-vulkan-drivers-freeworld && \
    dnf clean all && \
    rm -rf /var/cache/* /var/lib/dnf /run/dnf /var/log/dnf* /tmp/*

RUN bootc container lint
