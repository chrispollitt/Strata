# enterphone-display

Builds the enterphone directory (the paper sheet by the door) from
`Contacts & Roles.xlsx`, as a step towards an e-ink display driven by a
Raspberry Pi Zero on the VR180 wifi. The target panel is a 7.8" 1872x1404
e-ink display (about 6.2 x 4.7 in).

## Usage

```sh
npm install
node directory.mjs [--cols 3] [--width 1872] [--height 1404] [--out directory] [--xlsx file]
```

Defaults: the file in `~/OneDrive/!Shared/Strata/docs`, 3 columns, 1872x1404.

Outputs (git-ignored, since they contain resident names):

- `<out>.json` - the sorted entries (`name1`, `name2`, `buzz`, `suite`)
- `<out>.png` - the directory, pure black and white, ready for the panel

`--cols 2` gives the layout of the printed sheet (2 columns of 21 rows);
`--cols 3` (3 columns of 14 rows) suits the landscape panel better and gives
larger text (about 14 pt, against 10 pt on paper).

## How it works

It does what the "Enterphone Directory Inset Only" workbook does:

1. Read the `All Units` sheet.
2. Split `Enterphone Name` on `/` into two name cells.
3. Keep the rows that have a Buzz code.
4. Sort by the first name column, ignoring case.
5. Lay the rows out in columns, one font size for the whole sheet (the largest
   that fits every name), then threshold to black and white.

A warning is printed for entries with no name (for example `?`); those sort
first.

## To do

- Decide what to show for a suite with no name yet (currently `?`).
- Rebuild automatically when `Contacts & Roles.xlsx` changes.
- Pi side: fetch the image, redraw the panel only when it changes.
- Check how the panel copes with the outdoor cold, and the enclosure.
