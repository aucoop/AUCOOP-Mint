<div align="center">

<img src="assets/AUCOOP_logotip.png" alt="AUCOOP" width="400">

# Mint

A lightweight, no-nonsense, Windows-like OS for basic users<br>
with low-end refurbished hardware in mind.

[![Built on Linux Mint](https://img.shields.io/badge/Built%20on-Linux%20Mint%2022.x-87cf3e?style=flat-square&logo=linuxmint&logoColor=white)](https://linuxmint.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Docs](https://img.shields.io/badge/Docs-GitHub%20Pages-blue?style=flat-square)](https://aucoop.github.io/AUCOOP-Mint/)

<br>

<img src="docs/assets/aucoop_mint_homescreen.png" alt="AUCOOP Mint homescreen" width="90%">

</div>

---

## Why this exists

AUCOOP refurbishes donated laptops and sends them [where they are needed](https://aucoop.upc.edu/projectes-internacionals/). The problem is not only hardware — the last mile is software: people generally used to Windows, often Linux distributions have too much clutter, too many choices, too much friction on first boot.

**AUCOOP Mint fixes that.**

It keeps upstream Linux Mint, then layers a small **opinionated** provisioning system on top so a donated laptop feels familiar, useful, and ready on day one.

> Follows the ["omakase" philosophy](https://en.wikipedia.org/wiki/Omakase): we take care of the details so the recipient can just use the machine without worrying about setup, updates, codecs, drivers, or even internet access.

---

## Who it's for

AUCOOP Mint is designed for people who need a computer that simply works:

| Audience | Use case |
|----------|----------|
| **Basic users** | Browser, office documents, email, everyday desktop tasks |
| **Teachers & students** | Schools where reliability and familiarity matter more than customization |

---

## What makes it different

| Typical laptop reinstall | AUCOOP Mint |
|--------------------------|-------------|
| Generic desktop | Familiar Windows-like layout |
| Many default apps | Curated set of apps that matter |
| Setup burden pushed to recipient | Setup finished before handoff |
| Internet assumed | Offline knowledge and local AI optional |
| Device history gets lost | Registration flow built in |

---

## What ships today

| Feature | Description |
|---------|-------------|
| **One-command provisioning** | Start from a standard Linux Mint 22.x Cinnamon install |
| **Familiar desktop** | Taskbar, menu, icons, wallpaper, pointer tuned for low-friction adoption |
| **Chrome + OnlyOffice** | Browser and office suite ready out of the box |
| **Less clutter** | Unused default applications removed |
| **AUCOOP Welcome** | First-login app for updates, codecs, drivers, and optional modules |
| **Offline knowledge** | Kiwix support for downloading Wikipedia and similar content |
| **Local AI option** | Offline chat powered by [llamafile](https://github.com/Mozilla-Ocho/llamafile) |
| **Traceability** | Device registration through [eReuse / Devicehub](https://www.ereuse.org/) |

---

## Quick start

On a fresh Linux Mint 22.x Cinnamon install:

```bash
wget -qO- https://raw.githubusercontent.com/aucoop/AUCOOP-Mint/master/boot.sh | bash
```

<p align="center">
  <a href="https://aucoop.github.io/AUCOOP-Mint/"><strong>Read the full documentation →</strong></a>
</p>

---

## Credits

AUCOOP Mint builds on excellent open-source work:

<table>
  <tr>
    <td align="center"><a href="https://linuxmint.com/"><img src="https://img.shields.io/badge/-Linux%20Mint-87cf3e?style=flat-square&logo=linuxmint&logoColor=white" alt="Linux Mint"></a></td>
    <td align="center"><a href="https://www.onlyoffice.com/"><img src="https://img.shields.io/badge/-OnlyOffice-ff6f3d?style=flat-square" alt="OnlyOffice"></a></td>
    <td align="center"><a href="https://www.kiwix.org/"><img src="https://img.shields.io/badge/-Kiwix-00a5de?style=flat-square" alt="Kiwix"></a></td>
    <td align="center"><a href="https://github.com/Mozilla-Ocho/llamafile"><img src="https://img.shields.io/badge/-llamafile-000000?style=flat-square&logo=mozilla&logoColor=white" alt="llamafile"></a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://www.canirun.ai/"><img src="https://img.shields.io/badge/-canirun.ai-purple?style=flat-square" alt="canirun.ai"></a></td>
    <td align="center"><a href="https://www.ereuse.org/"><img src="https://img.shields.io/badge/-eReuse-green?style=flat-square" alt="eReuse"></a></td>
    <td align="center"><a href="https://labdoo.org/"><img src="https://img.shields.io/badge/-Labdoo-f5a623?style=flat-square" alt="Labdoo"></a></td>
    <td align="center"><a href="https://aucoop.eu/"><img src="https://img.shields.io/badge/-AUCOOP-00b4d8?style=flat-square" alt="AUCOOP"></a></td>
  </tr>
</table>

---

<div align="center">

**License:** MIT — Repository scripts and configuration.<br>
Linux Mint and bundled software keep their original licenses.

<br>

Built with care by [AUCOOP](https://aucoop.eu)

</div>
