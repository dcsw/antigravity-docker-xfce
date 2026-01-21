FROM lscr.io/linuxserver/webtop:ubuntu-kde

# Switch to root to handle installations
USER root
ARG DEBIAN_FRONTEND=noninteractive

# Update and install basic transport tools
RUN apt-get update && apt-get install -y \
    curl \
    gpg \
    apt-transport-https \
    ca-certificates

# Add the repository to sources.list.d
RUN mkdir -p /etc/apt/keyrings
# Add Google's official GPG key and the Antigravity repo
RUN curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
    gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
    tee /etc/apt/sources.list.d/antigravity.list

# Update the package cache
RUN apt update

# Install the antigravity package
RUN apt install antigravity

# Clean up to keep the image small
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the environment to allow Fuse (needed for AppImages/containers)
ENV APPIMAGE_EXTRACT_AND_RUN=1