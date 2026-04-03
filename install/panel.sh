#!/bin/bash
# Configure Cinnamon panel favorites
#
# Pin the apps the user should see immediately and remove Terminal from the
# launchable favorites set.

FAVORITES="['google-chrome.desktop', 'word.desktop', 'excel.desktop', 'powerpoint.desktop', 'mintinstall.desktop']"

echo "  Pinning Chrome, Word, Excel, PowerPoint, and App Store to the panel..."
gsettings set org.cinnamon favorite-apps "$FAVORITES"
