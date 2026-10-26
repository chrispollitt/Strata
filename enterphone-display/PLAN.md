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
| Power and network | PoE over the existing Cat5 run, with an isolated 802.3af splitter at the Pi |
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
3. Check the Cat5 cable to the door:
   - The old LCD system is gone, and the new system has paper, keypad, camera,
     mic and speaker. Confirm none of those uses the Cat5 run.
   - Test all 8 wires with a cable tester and terminate both ends properly.
   - Confirm with the property manager or installer that the cable is free.
4. PoE: an 802.3af switch or injector at the network end (not a passive 24 V
   injector) and an isolated PoE splitter (5 V out) at the Pi. If the camera is
   on the same PoE switch, check the power budget.
5. Enclosure (IP65 or better, clear window, anti-glare, lockable, vented or with
   desiccant):
   - Measure the old LCD opening and the depth behind it.
   - Mount the panel so the ribbon cable is not stressed.
   - Decide about night lighting, since e-ink has no backlight.

## Risks and cautions

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
- Is the Cat5 run really free of the camera, mic and speaker?
- Pull (`url` in the Pi config) or push (`publish.sh`)? Push is implemented.
- What to show for a vacant or unnamed suite?
