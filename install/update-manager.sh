#!/bin/bash

echo "  Disabling Update Manager welcome page..."

# Use Mint's own setting instead of trying to dismiss the dialog interactively.
gsettings set com.linuxmint.updates show-welcome-page false 2>/dev/null || true
