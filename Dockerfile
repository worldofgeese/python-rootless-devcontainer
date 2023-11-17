FROM mcr.microsoft.com/devcontainers/python:1-3.12-bullseye

USER root
RUN addgroup --system nixbld \
  && adduser vscode nixbld \
  && for i in $(seq 1 30); do useradd -ms /bin/bash nixbld$i &&  adduser nixbld$i nixbld; done \
  && mkdir -m 0755 /nix && chown vscode /nix \
  && mkdir -p /etc/nix && echo 'sandbox = false' > /etc/nix/nix.conf

USER vscode
ENV USER vscode
WORKDIR /home/${USER}

# Combine Nix installation and environment setup
ARG NIX_VERSION=2.18.1
ARG GARDEN_VERSION=0.13.20
RUN touch .bash_profile \
 && curl https://nixos.org/releases/nix/nix-${NIX_VERSION}/install | sh \
 && echo '. /home/$USER/.nix-profile/etc/profile.d/nix.sh' >> /home/$USER/.bashrc \
 && . /home/$USER/.nix-profile/etc/profile.d/nix.sh \
 && nix-env -iA cachix -f https://cachix.org/api/v1/install \
 && cachix use cachix \
 && nix-channel --add https://nixos.org/channels/nixpkgs-unstable unstable \
 && nix-channel --update \
 && nix-env -iA nixpkgs.nixUnstable \
 && nix-env -i devbox direnv \
 && direnv hook bash >> /home/$USER/.bashrc \
 && (command -v garden &> /dev/null || \
    curl -sSL "https://github.com/garden-io/garden/releases/download/${GARDEN_VERSION}/garden-${GARDEN_VERSION}-linux-amd64.tar.gz" | \
    sudo tar --strip-components=1 -xz -C /usr/local/bin -f - linux-amd64/garden)

WORKDIR /workspace
COPY --chown=$USER devbox.json devbox.lock ./

# Install devbox project and set shell environment
RUN . /home/$USER/.nix-profile/etc/profile.d/nix.sh \
  && devbox run -- echo "Installed Packages." \
  && devbox shellenv --init-hook >> ~/.profile
