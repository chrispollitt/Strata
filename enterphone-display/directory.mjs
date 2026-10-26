// Build the enterphone directory from Contacts & Roles.xlsx for an e-ink panel.
// Usage: node directory.mjs [--xlsx file] [--width 1872] [--height 1404] [--cols 2|3] [--out directory]
// Writes <out>.json and <out>.png (pure black and white).
import ExcelJS from "exceljs";
import { createCanvas } from "@napi-rs/canvas";
import { writeFileSync } from "node:fs";
import { parseArgs } from "node:util";

const { values: o } = parseArgs({
  options: {
    xlsx: { type: "string", default: "C:/Users/chris/OneDrive/!Shared/Strata/docs/Contacts & Roles.xlsx" },
    width: { type: "string", default: "1872" },
    height: { type: "string", default: "1404" },
    cols: { type: "string", default: "3" },
    out: { type: "string", default: "directory" },
  },
});
const W = Number(o.width), H = Number(o.height), COLS = Number(o.cols);

const wb = new ExcelJS.Workbook();
await wb.xlsx.readFile(o.xlsx);
const ws = wb.getWorksheet("All Units");
const head = {};
ws.getRow(1).eachCell((c, i) => (head[String(c.value).trim()] = i));
const cell = (row, name) => {
  const v = row.getCell(head[name]).value;
  return v == null ? "" : String(v.result ?? v).trim();
};

// As in the spreadsheet's query: split "Enterphone Name" on "/", keep Buzz.
// Rows are kept by having a Buzz code (rather than dropping the last 2).
const rows = [];
ws.eachRow((row, n) => {
  if (n === 1) return;
  const buzz = Number(cell(row, "Buzz"));
  if (!Number.isInteger(buzz) || buzz <= 0) return;
  const [name1 = "", name2 = ""] = cell(row, "Enterphone Name").split("/").map((s) => s.trim());
  rows.push({ name1, name2, buzz, suite: Number(cell(row, "Suite")) });
});
rows.sort((a, b) => a.name1.localeCompare(b.name1, "en", { sensitivity: "base" }));
for (const r of rows) {
  if (!r.name1 || r.name1 === "?") console.warn(`warning: suite ${r.suite} has no enterphone name`);
}
writeFileSync(`${o.out}.json`, JSON.stringify(rows, null, 2));

// Layout: COLS columns filled top to bottom, like the printed sheet.
const canvas = createCanvas(W, H);
const g = canvas.getContext("2d");
g.fillStyle = "#fff";
g.fillRect(0, 0, W, H);
g.fillStyle = g.strokeStyle = "#000";
g.textBaseline = "alphabetic";

const M = Math.round(W * 0.02), GAP = Math.round(W * 0.025);
const per = Math.ceil(rows.length / COLS);
const rowH = (H - 2 * M) / per;
const colW = (W - 2 * M - GAP * (COLS - 1)) / COLS;
const font = (px) => `${px}px Arial, Helvetica, sans-serif`;
const pad = Math.round(rowH * 0.18);
const width = (text, px) => (g.font = font(px), g.measureText(text).width);

// One font size for the whole sheet: the largest that fits every cell.
let base = Math.floor(rowH * 0.62);
const buzzNeed = (px) => width("000", px) + 2 * pad;
const fits = (px) => {
  const buzzW = buzzNeed(px), nameW = colW - buzzW;
  return rows.every((r) => r.name2
    ? Math.max(width(r.name1, px), width(r.name2, px)) <= nameW / 2 - 2 * pad
    : width(r.name1, px) <= nameW - 2 * pad);
};
while (!fits(base) && base > 8) base--;
const buzzW = buzzNeed(base);

function put(text, x, y, align = "left", maxW) {
  g.font = font(base);
  g.textAlign = align;
  g.fillText(text, x, y);
}

g.lineWidth = Math.max(2, Math.round(W / 900));
rows.forEach((r, i) => {
  const ci = Math.floor(i / per), ri = i % per;
  const x = M + ci * (colW + GAP);
  const y = M + ri * rowH;
  const ty = y + rowH * 0.5 + base * 0.35;
  const nameW = colW - buzzW;
  g.strokeRect(x, y, colW, rowH);
  g.beginPath();
  g.moveTo(x + nameW, y); g.lineTo(x + nameW, y + rowH);
  if (r.name2) { g.moveTo(x + nameW / 2, y); g.lineTo(x + nameW / 2, y + rowH); }
  g.stroke();
  if (r.name2) {
    put(r.name1, x + pad, ty);
    put(r.name2, x + nameW / 2 + pad, ty);
  } else {
    put(r.name1, x + pad, ty);
  }
  put(String(r.buzz), x + colW - pad, ty, "right");
});

// Pure black and white, no anti-aliasing greys, for the e-ink panel.
const img = g.getImageData(0, 0, W, H);
for (let p = 0; p < img.data.length; p += 4) {
  const v = img.data[p] + img.data[p + 1] + img.data[p + 2] > 384 ? 255 : 0;
  img.data[p] = img.data[p + 1] = img.data[p + 2] = v;
}
g.putImageData(img, 0, 0);
writeFileSync(`${o.out}.png`, canvas.toBuffer("image/png"));
console.log(`${rows.length} entries, ${COLS} columns of ${per} -> ${o.out}.png (${W}x${H})`);
