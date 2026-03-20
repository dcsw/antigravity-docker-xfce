FROM ghcr.io/astral-sh/uv:latest AS uv_bin
FROM lscr.io/linuxserver/webtop:debian-kde

# Default preinstalled webtop user is abc
ARG USER=abc

#=======================================================================
# Environment Variables
#-----------------------------------------------------------------------
# Webtop env vars -- reference https://docs.linuxserver.io/images/docker-webtop/#optional-environment-variables
# ENV PIXELFLUX_WAYLAND=true

# Set the environment to allow Fuse (needed for AppImages/containers)
ENV APPIMAGE_EXTRACT_AND_RUN=1


#=======================================================================
# Install global software
#-----------------------------------------------------------------------
USER root
# Install KDE indexers
RUN apt-get update && \
    apt-get install -y nodejs desktop-file-utils shared-mime-info && \
    apt-get clean
# Add install tools
COPY --from=uv_bin /uv /uvx /usr/local/bin/
RUN npm install -g @google/gemini-cli
RUN uv tool install specify-cli --from git+https://github.com/github/spec-kit.git && \
    /config/.local/bin/specify --help

# Install antigravity
#   Add the Antigravity repository to sources.list.d
RUN mkdir -p /etc/apt/keyrings
#   Add Google's official GPG key and the Antigravity repo
RUN curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
    gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
    tee /etc/apt/sources.list.d/antigravity.list
# Install the antigravity package
RUN apt update && apt install antigravity \
    && rm -rf /var/lib/apt/lists/*

#=======================================================================
# Configure post-KDE build pre-KDE run permissions updates
#-----------------------------------------------------------------------
# RUN chown -R abc /config/.gemini && chgrp -R abc /config/.gemini <--- don't do this as init.d will override it....
RUN mkdir -p /custom-cont-init.d
COPY set-gemini-perms.sh /custom-cont-init.d
RUN chmod +x /custom-cont-init.d/set-gemini-perms.sh

#=======================================================================
# Configure speckit/Antigravity bridge global workspace rule
#-----------------------------------------------------------------------
RUN mkdir -p /config/.gemini/antigravity/global_workflows
COPY speckit-implement.md /config/.gemini/antigravity/global_workflows/speckit-implement.md

#=======================================================================
# Add desktop icon links
#-----------------------------------------------------------------------
RUN mkdir -p /config/Desktop && chown abc: /config/Desktop
RUN ln -s /usr/share/applications/chromium.desktop /config/Desktop/chromium.desktop
RUN ln -s /usr/share/applications/org.kde.konsole.desktop /config/Desktop/org.kde.konsole.desktop
RUN ln -s /usr/share/applications/antigravity.desktop /config/Desktop/antigravity.desktop

#=======================================================================
# Do User-specific actions
#-----------------------------------------------------------------------
USER $USER
WORKDIR /home/$USER
# ENV HOME=/home/$USER <--- WARNING! Do not do this or webtop will not start....

# Disable Antigravity telemetry by creating user settings file
RUN mkdir -p /home/$USER/.config/Antigravity/User
COPY antigravity-settings.json /home/$USER/.config/Antigravity/User/settings.json

# Disable VSCode telemetry by creating a similar user settings file.
RUN mkdir -p /home/$USER/.config/Code/User
COPY vscode-settings.json /home/$USER/.config/Code/User/settings.json

#=======================================================================
# Windup
#-----------------------------------------------------------------------
USER root

# Clean up to keep the image small
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# THE "FORCE-VISIBLE" MOVE
#   Move the desktop files to the high-priority local path & trigger a KDE update build
RUN mkdir -p /usr/local/share/applications && \
    cp /usr/share/applications/org.kde.konsole.desktop /usr/local/share/applications/ && \
    update-desktop-database /usr/local/share/applications

# THE XDG_CONFIG BYPASS
#   Overwrite the default menu name so the prefix "kf5-" isn't needed.
RUN ln -sf /etc/xdg/menus/kf5-applications.menu /etc/xdg/menus/applications.menu

# THE RUNTIME KDE REBUILD (The /config aware version)
RUN mkdir -p /custom-cont-init.d && \
    echo '#!/bin/with-contenv bash\n\
# Force the environment for this script\n\
export XDG_MENU_PREFIX="kf5-"\n\
export HOME="/config"\n\
\n\
# Rebuild the system-wide desktop cache\n\
/usr/bin/update-desktop-database /usr/share/applications\n\
\n\
# Ensure the /config/.cache exists and is owned by abc\n\
mkdir -p /config/.cache\n\
chown -R abc:abc /config/.cache\n\
\n\
# Force rebuild the database into the /config mount\n\
s6-setuidgid abc /usr/bin/kbuildsycoca5 --noincremental\n\
' > /custom-cont-init.d/99-config-rebuild.sh && \
    chmod +x /custom-cont-init.d/99-config-rebuild.sh

# THE ROBUST BROWSER REDIRECT
# We ensure the script is complete and handles the KIO-exec path cleaning
RUN echo '#!/bin/bash\n\
# If KIO downloaded the file, we strip the local path and extract the original URL\n\
CLEAN_URL=$(echo "$1" | sed -E "s|file:///config/.cache/kioexec/krun/[0-9_]*/||")\n\
# If it starts with "https", we use it; otherwise, we pass the original $1\n\
/usr/bin/chromium --no-sandbox --ozone-platform=x11 "$CLEAN_URL"' > /usr/local/bin/browser-force && \
    chmod +x /usr/local/bin/browser-force

# HIJACK XDG-OPEN
RUN mv /usr/bin/xdg-open /usr/bin/xdg-open.bak || true && \
    ln -sf /usr/local/bin/browser-force /usr/bin/xdg-open

# THE FINAL MENU AND PATH FIX (No typos this time!)
RUN ln -sf /etc/xdg/menus/kf5-applications.menu /etc/xdg/menus/applications.menu && \
    mkdir -p /usr/local/share/applications && \
    cp /usr/share/applications/org.kde.konsole.desktop /usr/local/share/applications/ && \
    cp /usr/share/applications/chromium.desktop /usr/local/share/applications/