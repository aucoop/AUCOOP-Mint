# AUCOOP Mint

A donated laptop arrives, someone wipes it, and then the real work starts: which browser, which office suite, why is everything in English, where did the codecs go. AUCOOP Mint does all of that with one command, so the person receiving the machine gets something that already works.

![The AUCOOP Mint desktop](assets/desktop.jpg)

It isn't a new distribution. Underneath it's plain Linux Mint 22.3 Cinnamon, and updates keep coming from Mint. On top of that we remove the clutter, install Chrome and an office suite, make the desktop look familiar to anyone who grew up with Windows, and add two things that matter when the internet is bad or absent: an offline Wikipedia and a small AI assistant that runs on the laptop itself.

## The whole journey

```mermaid
flowchart LR
    A[Linux Mint USB stick] -->|normal Mint install<br/>~15 min| B[Plain Mint 22.3]
    B -->|one command<br/>~2 min| C[AUCOOP Mint]
    C -->|restart| D[AUCOOP Welcome<br/>5 guided steps]
    D -->|updates, codecs,<br/>extras| E[Ready to hand over]
```

Two of those boxes need you at the keyboard. The rest runs on its own.

## Start here

If you're preparing a laptop for someone, [Quick start](deployment/quick-start.md) is the page you want. It takes about twenty minutes from USB stick to finished machine, most of it waiting.

Already installed, and wondering what all those icons do? [What's on the laptop](use/index.md) covers that, and the [offline AI assistant](use/offline-ai.md) has its own page because it deserves the explanation.

Working on the scripts? Jump to [Architecture](architecture/index.md), then [Testing in a VM](testing/index.md). Everything is shell and a bit of Python, and you can read all of it in an afternoon.

## Who this is for

AUCOOP refurbishes donated laptops and sends them [where they're needed](https://aucoop.upc.edu/projectes-internacionals/), mostly schools. Many of those schools have slow internet, or pay for it by the megabyte, or have none at all on some days. That shapes nearly every decision here: the installer tells you how much it wants to download before it starts, it can wait until tonight, and the two headline features work with the network unplugged.

It speaks English, Spanish, Catalan, French and Portuguese, and follows whatever language the laptop was installed in.
