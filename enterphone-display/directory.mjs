// Build the enterphone directory (JSON + SVG) from Contacts & Roles.xlsx.
// Usage: node directory.mjs [path/to/Contacts & Roles.xlsx] [width] [height]
import ExcelJS from "exceljs";
import { writeFileSync } from "node:fs";

const src = process.argv[2] ??
  "C:/Users/chris/OneDrive/!Shared/Strata/docs/Contacts & Roles.xlsx";
const W = Number(process.argv[3] ?? 800);
const H = Number(process.argv[4] ?? 480);

const wb = new ExcelJS.Workbook();
await wb.xlsx.readFile(src);
const ws = wb.getWorksheet("All Units");
const head = {};
ws.getRow(1).eachCell((c, i) => (head[String(c.value).trim()] = i));
const cell = (row, name) => {
  const v = row.getCell(head[name]).value;
  return v == null ? "" : String(v.result ?? v).trim();
};

// Same as the spreadsheet's query: split "Enterphone Name" on "/"; keep Buzz.
// Rows are kept by having a numeric Buzz code (rather than dropping the last 2).
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
writeFileSync("directory.json", JSON.stringify(rows, null, 2));

// Two columns, as on the printed sheet.
const per = Math.ceil(rows.length / 2);
const cols = [rows.slice(0, per), rows.slice(per)];
const rowH = H / per;
const fs = Math.floor(rowH * 0.7);
const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");
let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">` +
  `<rect width="100%" height="100%" fill="#fff"/><g font-family="Arial, sans-serif" font-size="${fs}" fill="#000">`;
cols.forEach((col, ci) => {
  const x0 = ci * (W / 2);
  const w = W / 2;
  col.forEach((r, i) => {
    const y = (i + 1) * rowH;
    svg += `<line x1="${x0}" y1="${y}" x2="${x0 + w}" y2="${y}" stroke="#000"/>`;
    const ty = y - rowH * 0.25;
    svg += `<text x="${x0 + 4}" y="${ty}">${esc(r.name1)}</text>`;
    if (r.name2) svg += `<text x="${x0 + w * 0.5}" y="${ty}">${esc(r.name2)}</text>`;
    svg += `<text x="${x0 + w - 4}" y="${ty}" text-anchor="end">${r.buzz}</text>`;
  });
  svg += `<line x1="${x0}" y1="0" x2="${x0}" y2="${H}" stroke="#000"/>`;
});
svg += "</g></svg>\n";
writeFileSync("directory.svg", svg);
console.log(`${rows.length} entries -> directory.json, directory.svg (${W}x${H})`);
