FROM quay.io/fedora/fedora-kinoite:44

LABEL org.opencontainers.image.title="kinoite" \
      org.opencontainers.image.description="BaoPaper's Fedora Kinoite 44" \
      org.opencontainers.image.source="https://github.com/BaoPaper/kinoite"

COPY cosign.pub /etc/pki/containers/baopaper.pub
COPY policy.json /etc/containers/policy.json
COPY ghcr-sigstore.yaml /etc/containers/registries.d/ghcr.yaml

RUN curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo -o /etc/yum.repos.d/tailscale.repo

RUN dnf install -y \
        distrobox \
        fcitx5-rime \
        kcm-fcitx5 \
        fish \
        helix \
        kitty \
        tailscale \
        webkit2gtk4.1 && \
    dnf clean all && \
    rm -rf /var/cache/* /var/log/* /tmp/*

RUN ostree container commit && bootc container lint
