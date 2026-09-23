# Prepare a laptop

Start with a laptop that has Linux Mint 22.3 Cinnamon freshly installed, nothing else. You'll need the password of the user account, an internet connection, and about twenty minutes, most of which you can spend doing something else.

## 1. Install Linux Mint

Nothing special here: the normal Mint installer, from a USB stick.

Two choices during that install matter later. The language you pick becomes the language AUCOOP Mint speaks, so if the laptop is going to a school in Mozambique, choose Portuguese now. And you can leave the "multimedia codecs" box unticked, because AUCOOP Welcome installs those later anyway.

## 2. Run one command

Open a terminal on the freshly installed machine and paste this:

```bash
wget -qO- https://raw.githubusercontent.com/aucoop/AUCOOP-Mint/master/boot.sh | bash
```

It asks for your password once, then shows what it's doing:

![The installer running](../assets/installer-running.jpg)

Seven steps, each with the time it took. On a laptop with decent internet the whole thing lands somewhere around two minutes; the office suite is the slow one, since OnlyOffice is a big download.

If you want to see the actual commands, press **D** at any point:

![Technical details](../assets/installer-details.jpg)

Press **D** again to hide them. Everything is written to `~/.local/state/aucoop-mint/install.log` either way, so nothing is hidden, it's just out of the way.

When it finishes it asks whether to restart:

![Installation finished](../assets/installer-done.jpg)

Say yes. The desktop changes only take effect after that restart.

### Prefer to clone it?

```bash
git clone https://github.com/aucoop/AUCOOP-Mint.git
cd AUCOOP-Mint
git submodule update --init --recursive
bash install.sh
```

Same thing; the one-liner just does the cloning for you. Add `--verbose` if you'd rather watch raw output than the progress screen.

## 3. Finish in AUCOOP Welcome

After the restart you log in and AUCOOP Welcome opens by itself with five steps: updates, extras, registration, done. That's the [next page](first-boot.md).

## What the command actually changes

Removed: Firefox, LibreOffice, Thunderbird, Transmission, Hypnotix, Warpinator and a few other things nobody on a shared school laptop opens.

Installed: Google Chrome, OnlyOffice with launchers named Word, Excel and PowerPoint, and Flathub wired into the Software Manager.

Changed: the theme, the wallpaper, the cursor, the taskbar with its pinned apps, the menu button, and Mint's own welcome window, which we switch off so two welcome screens don't fight at first login.

Left for later: system updates, codecs, drivers and the optional extras, all handled by AUCOOP Welcome so you can decide when to spend the bandwidth.

## Running it twice is fine

The installer is safe to repeat. Steps that are already done get skipped or redone harmlessly, so if something failed halfway, or you're not sure whether it finished, just run the same command again.

## If it fails

The failure screen names the step that broke, tells you what usually causes it, and prints the last lines of the log. Nine times out of ten it's the network. See [Troubleshooting](../troubleshooting.md) for the cases we've actually hit.

## Requirements, briefly

Linux Mint 22.x Cinnamon, a working internet connection, and you running as the normal desktop user. Not root: the script refuses, because half of what it does writes into your own desktop settings.
