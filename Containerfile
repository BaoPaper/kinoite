FROM quay.io/fedora/fedora-kinoite:44

LABEL org.opencontainers.image.title="kinoite" \
      org.opencontainers.image.description="BaoPaper's Fedora Kinoite 44" \
      org.opencontainers.image.source="https://github.com/BaoPaper/kinoite"

COPY cosign.pub /etc/pki/containers/baopaper.pub
COPY policy.json /etc/containers/policy.json
COPY ghcr-sigstore.yaml /etc/containers/registries.d/ghcr.yaml

# RPM Fusion 提供完整 ffmpeg 与硬件解码驱动。
# /var 挂成 tmpfs：DNF 状态只存在于本次 RUN，最终镜像的 /var 保持基础镜像原样；
# /var/cache 用嵌套 cache mount 保留构建缓存。
RUN --mount=type=tmpfs,dst=/var \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/dnf \
    curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo -o /etc/yum.repos.d/tailscale.repo && \
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
        trash-cli && \
    dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
    dnf install -y mesa-va-drivers-freeworld && \
    dnf swap -y --allowerasing mesa-vulkan-drivers mesa-vulkan-drivers-freeworld && \
    dnf install -y intel-media-driver && \
    dnf install -y libva-utils && \
    rm -rf /run/dnf && \
    find /tmp -mindepth 1 -delete

# warning 也视为构建失败。
RUN --network=none \
    bootc container lint --fatal-warnings --no-truncate
