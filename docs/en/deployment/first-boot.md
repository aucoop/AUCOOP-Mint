# First login: AUCOOP Welcome

The restart lands on the AUCOOP login screen. Log in, and a window opens on its own:

![AUCOOP Welcome](../assets/welcome-start.jpg)

Five steps across the top, Back and Next at the bottom, and a collapsed "Technical details" panel for anyone who wants to watch the commands. You can close the window at any point; if setup hasn't finished, it comes back at the next login.

Click **Let's go!**. Nothing downloads on this first page.

## Step 1 and 2: updates and the essentials

Click through the welcome page and Welcome checks the connection before downloading anything:

![The setup step, with the connection check](../assets/welcome-setup.jpg)

That line is measured, not guessed. It asks apt what it would download, times a sample from the mirror that carries most of the bytes, and does the arithmetic. The test machine in the screenshot found about 400 MB. Expect the number to change as the Mint ISO gets older and new updates arrive.

What happens next depends on the connection, and this is the part worth knowing if you work with schools on bad links:

```mermaid
flowchart TD
    C{Connection?} -->|none| R["Remind me when I'm online<br/><i>watches the network, then reopens Welcome</i>"]
    C -->|mobile data| M["Warns it may cost money<br/><i>Wait for Wi-Fi, or start anyway</i>"]
    C -->|slow| S["Tonight at 22:00<br/><i>runs on its own while nobody uses the laptop</i>"]
    C -->|fine| N[Start now]
```

Press Start, type the password, and it works through three things: security updates, then the codecs that make video and music play, then hardware drivers. Each one ticks off as it goes, and the line underneath names the package it's installing right now, so a long upgrade doesn't look like a frozen spinner. There are tips rotating below it, aimed at whoever ends up using the laptop.

Use **Skip (no internet)** if you only want to look through Welcome now. You can reopen it from the desktop when the connection is ready.

## Step 3: extras

Turn on either extra, or both, then click **Install selected**:

![Offline Wikipedia and the offline AI assistant selected for installation](../assets/welcome-extras.jpg)

Two optional things, both useful without internet:

**Offline Wikipedia** installs Kiwix, the reader. The content itself is a separate download, and a full Wikipedia is several gigabytes, so plan that on a good connection or copy the file from a USB stick.

**The offline AI assistant** runs a small language model on the laptop. Welcome measures the memory and the free disk and only offers models the machine can actually handle, shows which licence the model comes with, and says plainly that small assistants get things wrong. It has [its own page](../use/offline-ai.md).

Open **More options** to choose the AI model. Welcome shows the memory and download size for each one and hides models this computer can't run:

![The AI model menu on an 8 GB computer](../assets/welcome-models.jpg)

The 8 GB test machine in the screenshot can choose between four models. A weaker laptop gets a shorter list. The suggested model is a sensible default; pick a smaller one if download time matters more than answer quality.

You can skip this step entirely and come back from the AUCOOP Welcome desktop icon later.

## Step 4: registration

This step is for AUCOOP volunteers, not for whoever receives the laptop. It runs [Workbench](https://github.com/eReuse/workbench-script), reads the hardware, and files it in Devicehub so we know where each machine ended up. You need an instance and a token. If you don't have one, skip it.

![The optional Devicehub registration step](../assets/welcome-register.jpg)

The token works like a password. Don't put a real token in a screenshot, document or chat message.

## Step 5: done

![All set](../assets/welcome-done.jpg)

The last page lists where things are: Chrome in the taskbar, the office apps beside it, and the extras you installed. If the updates ran in this session, it offers a restart to finish them.

Once you reach this page, Welcome stops opening at login. The desktop icon stays, so it's always one double-click away.
