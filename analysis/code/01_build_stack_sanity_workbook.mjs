import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const [manifestPath, requestedOutputPath, previewDir, verificationPath] =
  process.argv.slice(2);

if (!manifestPath || !requestedOutputPath || !previewDir || !verificationPath) {
  throw new Error(
    "Usage: node builder.mjs <manifest.json> <output.xlsx> <preview-dir> <verification.json>",
  );
}

const manifest = JSON.parse(await fs.readFile(manifestPath, "utf8"));
const sheetSpecs = Array.isArray(manifest.sheets)
  ? manifest.sheets
  : Object.values(manifest.sheets);

if (sheetSpecs.length !== 3) {
  throw new Error(
    `Expected exactly three sanity-check sheets; received ${sheetSpecs.length}.`,
  );
}

const workbook = Workbook.create();
const verification = {
  title: manifest.title,
  outputPath: requestedOutputPath,
  sheets: [],
  formulaErrorScan: null,
};

function excelColumn(columnNumber) {
  let number = columnNumber;
  let label = "";
  while (number > 0) {
    const remainder = (number - 1) % 26;
    label = String.fromCharCode(65 + remainder) + label;
    number = Math.floor((number - 1) / 26);
  }
  return label;
}

function normalizeValue(value) {
  if (value === null || value === undefined) return null;
  if (Array.isArray(value)) return value.join("; ");
  if (typeof value === "object") return JSON.stringify(value);
  return value;
}

function widthForColumn(header, values) {
  const textLengths = [header, ...values]
    .filter((value) => value !== null && value !== undefined)
    .map((value) => String(value).length);
  const maximum = Math.max(8, ...textLengths);

  if (/path|detail|reason|examples|fields|columns|interpretation/i.test(header)) {
    return Math.min(Math.max(maximum + 2, 24), 58);
  }
  if (/^(?:n_|rows_|keys_|matched|null|malformed|unmatched|ambiguous)/.test(header)) {
    return Math.min(Math.max(maximum + 2, 11), 18);
  }
  return Math.min(Math.max(maximum + 2, 10), 32);
}

await fs.mkdir(previewDir, { recursive: true });

for (let sheetIndex = 0; sheetIndex < sheetSpecs.length; sheetIndex += 1) {
  const spec = sheetSpecs[sheetIndex];
  const sheetName = String(spec.name).slice(0, 31);
  const columns = spec.columns.map(String);
  const rows = (spec.rows ?? []).map((row) =>
    columns.map((column) => normalizeValue(row[column])),
  );

  if (columns.length === 0) {
    throw new Error(`Sheet ${sheetName} has no columns.`);
  }

  const sheet = workbook.worksheets.add(sheetName);
  sheet.showGridLines = false;
  sheet.freezePanes.freezeRows(1);

  const matrix = [columns, ...rows];
  const endColumn = excelColumn(columns.length);
  const endRow = matrix.length;
  const usedRange = sheet.getRange(`A1:${endColumn}${endRow}`);
  usedRange.values = matrix;
  usedRange.format.font = { name: "Aptos", size: 10, color: "#1F2937" };
  usedRange.format.wrapText = true;

  const headerRange = sheet.getRange(`A1:${endColumn}1`);
  headerRange.format.fill = "#0E6E5C";
  headerRange.format.font = {
    name: "Aptos Display",
    size: 10,
    bold: true,
    color: "#FFFFFF",
  };
  headerRange.format.borders = {
    bottom: { style: "medium", color: "#09483D" },
  };
  headerRange.format.rowHeight = 30;

  if (rows.length > 0) {
    sheet.getRange(`A2:${endColumn}${endRow}`).format.borders = {
      insideHorizontal: { style: "thin", color: "#E5E7EB" },
    };
  }

  const columnWidths = [];
  for (let columnIndex = 0; columnIndex < columns.length; columnIndex += 1) {
    const columnName = excelColumn(columnIndex + 1);
    const columnValues = rows.map((row) => row[columnIndex]);
    const columnWidth = widthForColumn(columns[columnIndex], columnValues);
    columnWidths.push(columnWidth);
    const columnRange = sheet.getRange(`${columnName}1:${columnName}${endRow}`);
    columnRange.format.columnWidth = columnWidth;

    if (columns[columnIndex] === "pct_matched" && endRow >= 2) {
      sheet.getRange(`${columnName}2:${columnName}${endRow}`).format.numberFormat =
        "0.0%";
    } else if (
      /^(?:n_|rows_|keys_|matched$|null$|malformed$|unmatched$|cross_country$|ambiguous$)/.test(
        columns[columnIndex],
      ) &&
      endRow >= 2
    ) {
      sheet.getRange(`${columnName}2:${columnName}${endRow}`).format.numberFormat =
        "#,##0";
    }
  }

  for (let rowIndex = 0; rowIndex < rows.length; rowIndex += 1) {
    let estimatedLines = 1;
    for (let columnIndex = 0; columnIndex < columns.length; columnIndex += 1) {
      const value = rows[rowIndex][columnIndex];
      if (value === null || value === undefined) continue;
      const availableCharacters = Math.max(columnWidths[columnIndex] - 2, 8);
      estimatedLines = Math.max(
        estimatedLines,
        Math.ceil(String(value).length / availableCharacters),
      );
    }
    const excelRow = rowIndex + 2;
    sheet.getRange(`A${excelRow}:${endColumn}${excelRow}`).format.rowHeight =
      Math.min(Math.max(18, estimatedLines * 15), 72);
  }

  const previewEndRow = Math.min(endRow, 32);
  const previewRange = `A1:${endColumn}${previewEndRow}`;
  const preview = await workbook.render({
    sheetName,
    range: previewRange,
    scale: 1,
    format: "png",
  });
  const previewPath = path.join(
    previewDir,
    `${String(sheetIndex + 1).padStart(2, "0")}_${sheetName}.png`,
  );
  await fs.writeFile(
    previewPath,
    new Uint8Array(await preview.arrayBuffer()),
  );

  const inspection = await workbook.inspect({
    kind: "table",
    range: `${sheetName}!${previewRange}`,
    include: "values,formulas",
    tableMaxRows: Math.min(previewEndRow, 10),
    tableMaxCols: Math.min(columns.length, 12),
    maxChars: 5000,
  });

  verification.sheets.push({
    name: sheetName,
    rows: rows.length,
    columns: columns.length,
    previewPath,
    inspectedRange: previewRange,
    inspection: inspection.ndjson,
  });
}

const formulaErrors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 300 },
  summary: "final formula error scan",
  maxChars: 4000,
});
verification.formulaErrorScan = formulaErrors.ndjson;

await fs.mkdir(path.dirname(requestedOutputPath), { recursive: true });
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(requestedOutputPath);

await fs.mkdir(path.dirname(verificationPath), { recursive: true });
await fs.writeFile(
  verificationPath,
  JSON.stringify(verification, null, 2),
  "utf8",
);

process.stdout.write(
  JSON.stringify({
    outputPath: requestedOutputPath,
    sheetCount: verification.sheets.length,
    previewDir,
    verificationPath,
  }),
);
