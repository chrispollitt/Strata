# Raspberry Pi side

`display.py` runs on the Raspberry Pi (3 B+ or Zero 2 W) behind the 7.8" 1872x1404 e-ink
panel (Waveshare 7.8" HAT, IT8951 controller). It redraws the panel only when
the directory image changes. **The panel driver code is untested** until the
hardware arrives; the rest can be tried with `--dry-run`.

## How the image gets there

On your computer, `../publish.sh [user@]host` rebuilds `directory.png` and
copies it to `/var/lib/enterphone-display/` on the Pi. Alternatively set
`url` in the config and the Pi fetches it itself. The image contains resident
names, so keep it on the local network.

## Setup on the Pi

1. Raspberry Pi OS Lite, wired Ethernet to VR180 (PoE; wifi only for the bench), SSH enabled. Enable SPI
   (`raspi-config` -> Interface Options -> SPI).
2. Install the driver and imaging libraries:
   ```sh
   sudo apt install python3-pil python3-pip git
   sudo pip3 install --break-system-packages git+https://github.com/GregDMeyer/IT8951
   ```
3. Install the files:
   ```sh
   sudo install -d /opt/enterphone-display /var/lib/enterphone-display
   sudo install -m 755 display.py /opt/enterphone-display/
   sudo install -m 644 display.conf.example /etc/enterphone-display.conf
   sudo chown pi /var/lib/enterphone-display   # user that publish.sh logs in as
   sudo install -m 644 enterphone-display*.service enterphone-display*.timer /etc/systemd/system/
   ```
4. Edit `/etc/enterphone-display.conf`: set `vcom` to the value printed on the
   panel's flex cable.
5. Enable the timers:
   ```sh
   sudo systemctl daemon-reload
   sudo systemctl enable --now enterphone-display.timer enterphone-display-refresh.timer
   ```

## Behaviour

- Every 15 minutes (and a minute after boot) it checks the image; it draws
  only if its hash differs from the last one drawn.
- Every night at 03:30 it clears the panel and redraws, to remove ghosting.
- A missing, wrongly sized or unreadable image, or a failed fetch or draw,
  leaves the panel as it is and is retried on the next run. See
  `journalctl -u enterphone-display`.

## Trying it without the panel

```sh
./display.py --config display.conf.example --dry-run
```
