# Enterphone display: plan

Replace the paper directory by the front door with a 7.8" e-ink panel driven by
a Raspberry Pi. The directory comes from `Contacts & Roles.xlsx`, so there is one
list to maintain. Status as of 2026-10-25.

## Decisions

| Topic | Decision |
|---|---|
| Panel | 7.8" e-ink, 1872x1404, about 6.2 x 4.7 in (close to the 5 x 5 in paper inset) |
| Controller | Waveshare 7.8" HAT, IT8951 (to confirm on the vendor page before buying) |
| Computer | Raspberry Pi 3 B+ (already owned); a Zero 2 W would also work |
| Layout | 3 columns of 14 rows, about 14 pt text (2 columns of 21 also supported) |
| Data | `Contacts & Roles.xlsx`, sheet `All Units`, split names on `/`, sorted |
| Power and network | PoE over the existing Cat5 run to the door, shared with the fob IR receiver (see below) |
| Update trigger | `program_enterphone.sh`, opt-in via `ENTERPHONE_DISPLAY_HOST` |
| Climate | Vancouver: rain and condensation matter more than cold |

## Software status

Done and committed:

- `directory.mjs`: builds the sorted directory and a pure black and white PNG
  (one font size for the whole sheet, long names shrink the font to fit).
- `publish.sh`: rebuilds the image and copies it to the Pi with `scp`.
- `pi/display.py`: redraws the panel only when the image hash changes; failures
  leave the panel as it is and retry later. `--force` clears and redraws;
  `--dry-run` skips the driver. Tested without the panel.
- `pi/` systemd units: check every 15 minutes, and a nightly 03:30 full refresh
  to clear ghosting.
- `program_enterphone.sh` calls `publish.sh` after a successful run when
  `ENTERPHONE_DISPLAY_HOST` is set. A failure only warns.

Not verified until the hardware arrives:

- The IT8951 driver calls in `pi/display.py` (`AutoEPDDisplay`, `frame_buf.paste`,
  `draw_full(GC16)`), the `vcom` value and the rotation.
- The Pi setup steps in `pi/README.md`.

Still to do:

- Decide what to show for a suite with no name yet (currently `?`, sorted first).
- Rebuild automatically when `Contacts & Roles.xlsx` changes (today: run
  `publish.sh`, or `program_enterphone.sh` with the host variable set).
- Fixed address or DHCP reservation for the Pi; set the host name in the config.

## Hardware plan

1. Confirm the panel, its controller and Pi compatibility on the vendor page.
   Note the `vcom` value printed on the panel's flex cable.
2. Bench test: fit the HAT to the Pi, install Raspberry Pi OS Lite, enable SPI,
   install the driver, run `display.py` on a desk with a test image.
3. The Cat5 run to the door already carries the fob IR receiver's network connection, so it is shared, not free:
   - MESH lists two Freedom Bridge 2-Rdr/R2/Supv controllers (probably two
     readers and two relays each) on the 123 network. The network device is the
     Bridge, not the reader: the reader is probably wired to the Bridge with a
     reader cable (e.g. Wiegand), possibly over Cat5. Find out where the Bridge
     is and whether the Cat5 at the door is a network cable or a reader cable.
     Do NOT put PoE on it until that is known.
   - Find out what the receiver is and how it connects: plain Ethernet, or
     power on spare pairs. Ask the installer or check the MESH docs.
   - Put a small switch at the door, with the IR receiver on one port and the Pi
     on another. Do not route the receiver through the Pi, so fob access keeps
     working if the Pi is off or crashes.
   - Test all 8 wires with a cable tester and check the terminations.
4. PoE: an 802.3af switch or injector at the network end (not a passive 24 V
   injector, which can damage a device that does not expect power), and at the
   door a small PoE-powered switch (or a PoE splitter feeding a small switch)
   with the Pi on an isolated 5 V splitter. The receiver is not a PoE device, so
   check that the switch only powers ports that ask for it. Check the power
   budget, especially if the camera is on the same switch.
5. Enclosure (IP65 or better, clear window, anti-glare, lockable, vented or with
   desiccant):
   - Measure the old LCD opening and the depth behind it.
   - Mount the panel so the ribbon cable is not stressed.
   - Decide about night lighting, since e-ink has no backlight.

## Risks and cautions

- **Keep fob access independent of the display.** Do not bridge the receiver's network through the Pi, and do not power it from the display's supply. A Pi crash or reboot must not cut the fob reader.
- **Do not power the Pi from the door solenoid supply.** The solenoid is an
  inductive load that can spike or dip the voltage, and extra load could make
  the door unlock unreliably. Any change to door wiring goes through the
  property manager, the installer or an electrician.
- **Privacy:** the image and `directory.json` list residents. They are
  gitignored and should stay on the local network. The repo is public.
- **Weather:** rain and condensation are the main risks; cold is minor in
  Vancouver (panels are rated 0 to 50 C, so occasional frost only slows refresh).
- **Stale display:** if the Pi cannot fetch or draw, the old image stays up.
  Consider showing a last-updated mark, and check `journalctl -u enterphone-display`.

## Open questions

- Which panel exactly, and where is the other end of the Cat5 run?
- What exactly is the fob IR receiver, and does it use any spare pairs on the Cat5 run?
- Where is the Bridge mounted, and which cable at the door goes to it?
- Pull (`url` in the Pi config) or push (`publish.sh`)? Push is implemented.
- What to show for a vacant or unnamed suite?
