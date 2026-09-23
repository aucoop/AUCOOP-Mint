# First login: AUCOOP Welcome

The restart lands on the AUCOOP login screen. Log in, and a window opens on its own:

![AUCOOP Welcome](../assets/welcome-start.jpg)

Five steps across the top, Back and Next at the bottom, and a collapsed "Technical details" panel for anyone who wants to watch the commands. You can close the window at any point; if setup hasn't finished, it comes back at the next login.

## Step 1 and 2: updates and the essentials

Click through the welcome page and Welcome checks the connection before downloading anything:

![The setup step, with the connection check](../assets/welcome-setup.jpg)

That line is measured, not guessed. It asks apt what it would download, times a sample from the mirror that carries most of the bytes, and does the arithmetic. On a fresh Mint 22.3 install expect around 600 MB and 431 packages, because the ISO is months old by the time you use it.

What happens next depends on the connection, and this is the part worth knowing if you work with schools on bad links:

```mermaid
flowchart TD
    C{Connection?} -->|none| R["Remind me when I'm online<br/><i>watches the network, then reopens Welcome</i>"]
    C -->|mobile data| M["Warns it may cost money<br/><i>Wait for Wi-Fi, or start anyway</i>"]
    C -->|slow| S["Tonight at 22:00<br/><i>runs on its own while nobody uses the laptop</i>"]
    C -->|fine| N[Start now]
```

Press Start, type the password, and it works through three things: security updates, then the codecs that make video and music play, then hardware drivers. Each one ticks off as it goes, and the line underneath names the package it's installing right now, so a long upgrade doesn't look like a frozen spinner. There are tips rotating below it, aimed at whoever ends up using the laptop.

## Step 3: extras

![The extras step](../assets/welcome-extras.jpg)

Two optional things, both useful without internet:

**Offline Wikipedia** installs Kiwix, the reader. The content itself is a separate download, and a full Wikipedia is several gigabytes, so plan that on a good connection or copy the file from a USB stick.

**The offline AI assistant** runs a small language model on the laptop. Welcome measures the memory and the free disk and only offers models the machine can actually handle, shows which licence the model comes with, and says plainly that small assistants get things wrong. It has [its own page](../use/offline-ai.md).

Turn on what you want and press install, or skip the step entirely; you can come back to Welcome from the desktop icon later.

## Step 4: registration

This step is for AUCOOP volunteers, not for whoever receives the laptop. It runs [Workbench](https://github.com/eReuse/workbench-script), reads the hardware, and files it in Devicehub so we know where each machine ended up. You need an instance and a token. If you don't have one, skip it.

## Step 5: done

![All set](../assets/welcome-done.jpg)

The last page lists where things are: Chrome in the taskbar, the office apps beside it, and the extras you installed. If the updates ran in this session, it offers a restart to finish them.

Once you reach this page, Welcome stops opening at login. The desktop icon stays, so it's always one double-click away.
