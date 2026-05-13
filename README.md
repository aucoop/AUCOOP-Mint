# AUCOOP Mint

<p align="center">
  <img src="assets/AUCOOP_logotip.png" alt="AUCOOP" width="420">
</p>

<p align="center"><strong>Turn a fresh Linux Mint install into a ready-to-deliver laptop for real people.</strong></p>

<p align="center">
  A lightweight, no-nonsense, windows-like OS for non-tech users with low-end refurbished hardware in mind. Built by [AUCOOP](https://aucoop.eu).
</p>


## Why this exists

AUCOOP refurbishes donated laptops and sends them [where they are needed](https://aucoop.upc.edu/projectes-internacionals/). The problem is not only hardware. The last mile is software: people generally used to windows, ofter linux distributions have too much clutter, there are too many choices, too much friction on first boot...

AUCOOP Mint fixes that.

It keeps upstream Linux Mint, then layers a small **opinionated** provisioning system on top so a donated laptop feels familiar, useful, and ready on day one.

Follows the ["omakase" philosophy](https://en.wikipedia.org/wiki/Omakase): we take care of the details so the recipient can just use the machine without worrying about setup, updates, codecs, drivers, or even internet access.

## What makes it different

| Typical laptop reinstall | AUCOOP Mint |
|---|---|
| Generic desktop | Familiar Windows-like layout |
| Many default apps | Curated set of apps that matter |
| Setup burden pushed to recipient | Setup finished before handoff |
| Internet assumed | Offline knowledge and local AI optional |
| Device history gets lost | Registration flow built in |

## What ships today

- **One-command provisioning.** Start from a standard Linux Mint 22.x Cinnamon install.
- **Familiar desktop.** Taskbar, menu, icons, wallpaper, and pointer tuned for low-friction adoption.
- **Chrome + OnlyOffice.** Browser and office suite ready out of the box.
- **Less clutter.** Unused default applications removed.
- **AUCOOP Welcome.** First-login app for updates, codecs, drivers, and optional modules.
- **Offline knowledge.** Kiwix support for downloading Wikipedia and similar content.
- **Local AI option.** Offline chat powered by [llamafile](https://github.com/Mozilla-Ocho/llamafile).
- **Traceability.** Device registration through [eReuse / Devicehub](https://www.ereuse.org/).

## Quick start

On a fresh Linux Mint 22.x Cinnamon install:

```bash
wget -qO- https://raw.githubusercontent.com/aucoop/AUCOOP-Mint/master/boot.sh | bash
```

Full docs site: [aucoop.github.io/AUCOOP-Mint](https://aucoop.github.io/AUCOOP-Mint/)

## Credits

AUCOOP Mint builds on excellent open-source work:

- [Linux Mint](https://linuxmint.com/)
- [OnlyOffice](https://www.onlyoffice.com/)
- [Kiwix](https://www.kiwix.org/)
- [llamafile](https://github.com/Mozilla-Ocho/llamafile)
- [eReuse / Devicehub](https://www.ereuse.org/)
- [Labdoo](https://labdoo.org/)

## License

Repository scripts and configuration are released under the MIT License.
Linux Mint and bundled software keep their original licenses.
