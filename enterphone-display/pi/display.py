#!/usr/bin/env python3
"""Redraw the e-ink enterphone directory when the image has changed.

Reads the PNG named in the config (optionally fetched from a URL first),
compares its hash with the one stored after the last successful draw, and
draws it on the panel only if it is new. A failure leaves the panel as it is.

    display.py [--config FILE] [--force] [--dry-run]

--force    redraw even if unchanged, after clearing the panel (run daily to
           remove ghosting)
--dry-run  do everything except load the panel driver and draw
"""
import argparse
import configparser
import hashlib
import os
import sys
import tempfile
import urllib.request
from pathlib import Path

from PIL import Image

DEFAULTS = {
    "image": "/var/lib/enterphone-display/directory.png",
    "url": "",              # optional: fetch the image from here first
    "state": "/var/lib/enterphone-display/last.sha256",
    "width": "1872",
    "height": "1404",
    "vcom": "-2.06",        # printed on the panel's flex cable
    "rotate": "",           # "", CW, CCW or flip
}


def log(msg):
    print(msg, file=sys.stderr, flush=True)


def load_config(path):
    cp = configparser.ConfigParser(defaults=DEFAULTS)
    cp.add_section("display")
    if path and Path(path).exists():
        cp.read(path)
    return cp["display"]


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def fetch(url, dest):
    """Download url to dest, atomically. Returns True on success."""
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            data = r.read()
    except OSError as e:
        log(f"fetch failed ({e}); using the image already on disk")
        return False
    if not data.startswith(b"\x89PNG"):
        log("fetch did not return a PNG; ignoring it")
        return False
    dest = Path(dest)
    dest.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=dest.parent, delete=False) as t:
        t.write(data)
    os.replace(t.name, dest)
    return True


def check_image(path, width, height):
    img = Image.open(path)
    if img.size != (width, height):
        raise ValueError(f"image is {img.size[0]}x{img.size[1]}, panel is {width}x{height}")
    return img.convert("L")


def draw(img, cfg, clear):
    from IT8951 import constants
    from IT8951.display import AutoEPDDisplay

    rotate = cfg["rotate"] or None
    display = AutoEPDDisplay(vcom=float(cfg["vcom"]), rotate=rotate)
    if (display.width, display.height) != img.size:
        raise ValueError(f"driver reports {display.width}x{display.height}, image is {img.size}")
    if clear:
        display.clear()
    display.frame_buf.paste(img, (0, 0))
    display.draw_full(constants.DisplayModes.GC16)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config", default="/etc/enterphone-display.conf")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    cfg = load_config(args.config)
    image, state = Path(cfg["image"]), Path(cfg["state"])
    width, height = int(cfg["width"]), int(cfg["height"])

    if cfg["url"]:
        fetch(cfg["url"], image)
    if not image.exists():
        log(f"no image at {image}")
        return 1

    try:
        img = check_image(image, width, height)
    except Exception as e:
        log(f"bad image, panel left as it is: {e}")
        return 1

    new = sha256(image)
    old = state.read_text().strip() if state.exists() else ""
    if new == old and not args.force:
        log("unchanged")
        return 0

    if args.dry_run:
        log(f"would draw {image} ({new[:12]}){' after clearing' if args.force else ''}")
        return 0

    try:
        draw(img, cfg, clear=args.force)
    except Exception as e:
        log(f"draw failed, will retry next run: {e}")
        return 1
    state.parent.mkdir(parents=True, exist_ok=True)
    state.write_text(new + "\n")
    log(f"drew {image} ({new[:12]})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
