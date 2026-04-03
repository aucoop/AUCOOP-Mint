#!/bin/bash
# Configure Cinnamon panel favorites
#
# Pin the apps the user should see immediately and remove Terminal from the
# launchable favorites set.

FAVORITES="['google-chrome.desktop', 'nemo.desktop', 'onlyoffice-word.desktop', 'onlyoffice-excel.desktop', 'onlyoffice-powerpoint.desktop', 'mintinstall.desktop']"
PINNED_APPS='["google-chrome.desktop", "nemo.desktop", "onlyoffice-word.desktop", "onlyoffice-excel.desktop", "onlyoffice-powerpoint.desktop", "mintinstall.desktop"]'
GROUPED_WINDOW_LIST_CONFIG="$HOME/.config/cinnamon/spices/grouped-window-list@cinnamon.org/2.json"

echo "  Pinning Chrome, Word, Excel, PowerPoint, and App Store to the panel..."
gsettings set org.cinnamon favorite-apps "$FAVORITES"

if [ -f "$GROUPED_WINDOW_LIST_CONFIG" ]; then
  python3 - <<PY
import json
from pathlib import Path

path = Path(r"$GROUPED_WINDOW_LIST_CONFIG")
data = json.loads(path.read_text())
data.setdefault("pinned-apps", {})["value"] = [
    "google-chrome.desktop",
    "nemo.desktop",
    "onlyoffice-word.desktop",
    "onlyoffice-excel.desktop",
    "onlyoffice-powerpoint.desktop",
    "mintinstall.desktop",
]
path.write_text(json.dumps(data, indent=4) + "\n")
PY
fi
