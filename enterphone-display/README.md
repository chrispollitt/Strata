# enterphone-display

Builds the enterphone directory (the paper sheet by the door) from
`Contacts & Roles.xlsx`, as a step towards an e-ink display driven by a
Raspberry Pi Zero on the VR180 wifi.

## Usage

```sh
npm install
node directory.mjs [path/to/Contacts\ \&\ Roles.xlsx] [width] [height]
```

Defaults: the file in `~/OneDrive/!Shared/Strata/docs` and 800x480.

Outputs (both git-ignored, since they contain resident names):

- `directory.json` - the sorted entries (`name1`, `name2`, `buzz`, `suite`)
- `directory.svg` - the directory in two columns, like the printed sheet

## How it works

It does what the "Enterphone Directory Inset Only" workbook does:

1. Read the `All Units` sheet.
2. Split `Enterphone Name` on `/` into two name cells.
3. Keep the rows that have a Buzz code.
4. Sort by the first name column, ignoring case.
5. Lay out two columns of equal length.

A warning is printed for entries with no name (for example `?`).

## To do

- Look at the SVG at the real panel size and tune the layout.
- Convert to a PNG at the panel's resolution.
- Pi side: fetch the image, redraw the panel only when it changes.
- Choose the panel, and check how it copes with the outdoor cold.
