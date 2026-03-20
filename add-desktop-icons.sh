#!/bin/sh

# Add Desktop icons -- only for xfce
for f in /usr/share/applications/chromium.desktop \
    /usr/share/applications/xfce4-terminal.desktop
do
    cp $f /config/Desktop
    ff="/config/Desktop/$(basename $f)"
    chmod +x $ff
    chown abc: $ff
    gio set -t string "$ff" metadata::xfce-exe-checksum "$(sha256sum "$ff" | awk '{print $1}')"
done