# FROM lscr.io/linuxserver/webtop:ubuntu-xfce
FROM ghcr.io/linuxserver/webtop:ubuntu-xfce

# Switch to root to handle installations
USER root
ARG DEBIAN_FRONTEND=noninteractive

# Update and install basic transport tools
RUN apt-get update && apt-get install -y \
    curl \
    gpg \
    apt-transport-https \
    ca-certificates \
    unzip \
    nodejs

# Let Docker layers see /usr/local in PATH for newly installed tool calling.
# Also, install tools to /usr/local or adjust PATH further if they fail to be found after install
ENV PATH="/usr/local:${PATH}"

# Install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | NVM_DIR=/usr/local bash

# Install bun
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local sh

# Install GitHub speckit
ENV UV_TOOL_BIN_DIR=/usr/local/bin
ENV PATH="/usr/local/bin:${PATH}"
RUN uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Add Google's Antigravity repository to sources.list.d
RUN mkdir -p /etc/apt/keyrings
# Add Google's official GPG key and the Antigravity repo
RUN curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
    gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
    tee /etc/apt/sources.list.d/antigravity.list

# Update the package cache
RUN apt-get update

# Install gemini-cli -- note, this requires google's GPG key per above
RUN bun install -g @google/gemini-cli
# Switch to abc and fix their PATH
# USER abc
ENV PATH="/config/.bun/bin:/root/.bun/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"
RUN echo 'export PATH="/config/.bun/bin:/usr/local/bin:${PATH}"' >> /config/.bashrc
# USER root

# Install the antigravity package
RUN apt-get install -y antigravity

# Clean up to keep the image small
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the environment to allow Fuse (needed for AppImages/containers)
ENV APPIMAGE_EXTRACT_AND_RUN=1