# Troubleshooting

Things that have actually gone wrong, and what to do about them.

## The installer stops at a step

The failure screen names the step, prints the last dozen lines of the log, and tells you where the full log is: `~/.local/state/aucoop-mint/install.log`. Running the same command again is safe and usually enough, because finished work gets skipped.

## "No internet connection" before anything starts

The installer checks the connection before asking for your password. Connect, then rerun. If the laptop says it's connected but the installer disagrees, NetworkManager is probably reporting a captive portal: open Chrome, log into the network, try again.

## Downloads fail on a network that inspects TLS

We hit this on a network running Cloudflare's Zero Trust gateway. Every HTTPS download fails, and `wget` says something like:

```
ERROR: cannot verify dl.google.com's certificate, issued by
'CN=Gateway CA - Cloudflare Managed G1 ...':
Self-signed certificate encountered.
```

The network is decrypting and re-signing traffic with its own certificate authority, which the fresh Mint install doesn't trust. Your own machine probably does trust it, which is why the same download works there. The fix is to install that CA on the laptop:

```bash
sudo cp your-gateway-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

Then rerun the installer. Corporate networks, some university campuses and school filtering appliances all do this.

## Chrome asks which search engine to use

Expected, not a bug: Chrome shows that dialog on first launch in the EU. Pick one and it goes away.

## AUCOOP Welcome doesn't open after the restart

It only opens automatically until the setup is finished. Double-click the AUCOOP Welcome icon on the desktop to bring it back, any time.

## The updates step looks frozen

It isn't, probably. Watch the line under the progress bar: it names the package being installed right now. A fresh Mint 22.3 install has around 431 updates waiting, roughly 600 MB, which takes a while on a slow link. Open "Technical details" if you want to see apt's own output.

## "Not enough disk space" when installing the AI assistant

The model plus the runtime needs more room than the laptop has left. Welcome checks before downloading rather than filling the disk and failing at the end. Pick a smaller model, or free some space.

## The AI assistant doesn't start

You'll get a notification saying so. The log is `/tmp/aucoop-local-ai.log`. Two causes we've seen: the model file was deleted or corrupted, which reinstalling fixes, and another program holding port 8091, which the launcher now works around by moving to the next free port.

## The assistant disappears after a while

By design. When no browser has been connected for ten minutes it shuts down to free the memory, since a loaded model holds its full size in RAM. Click the icon again.

## Registration fails in the last step

Check the token first, then the instance URL. Workbench needs root, which it gets through the password prompt, and it needs the network. Run it from Welcome rather than by hand so all of that is set up for you.

## Something else

Open an issue at [github.com/aucoop/AUCOOP-Mint](https://github.com/aucoop/AUCOOP-Mint/issues) and attach `~/.local/state/aucoop-mint/install.log`. It contains no passwords, just what the scripts did.
