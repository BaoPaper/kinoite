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
        btop \
        fastfetch \
        trash-cli \
        vim \
        tmux \
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

# 虚拟化：virt-manager + libvirt/QEMU (KVM)。
# Fedora 41+ 默认使用模块化 libvirt daemon，这里显式启用 socket 激活。
RUN dnf install -y \
        virt-manager \
        virt-install \
        virt-viewer \
        libvirt-daemon-kvm \
        libvirt-daemon-config-network \
        libvirt-daemon-config-nwfilter \
        libvirt-nss \
        edk2-ovmf \
        swtpm \
        swtpm-tools && \
    systemctl enable \
        virtqemud.socket \
        virtnetworkd.socket \
        virtstoraged.socket \
        virtnodedevd.socket \
        virtsecretd.socket \
        virtnwfilterd.socket \
        virtinterfaced.socket && \
    dnf clean all && \
    rm -rf /var/cache/* /var/lib/dnf /run/dnf /var/log/dnf* /tmp/*

# bootc/ostree 安装时 /var 是新建的，libvirt 运行时目录会拿到 var_lib_t 而不是
# virt_var_lib_t/virt_log_t，导致 VM 启动被 SELinux 拒绝。开机时校正这两个目录。
RUN printf '%s\n' \
        'd /var/lib/libvirt 0755 root root -' \
        'd /var/log/libvirt 0750 root root -' \
        'z /var/lib/libvirt - - - -' \
        'z /var/log/libvirt - - - -' \
        > /usr/lib/tmpfiles.d/90-libvirt-relabel.conf

RUN bootc container lint --fatal-warnings --no-truncate
