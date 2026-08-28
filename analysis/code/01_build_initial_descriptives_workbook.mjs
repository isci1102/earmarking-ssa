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

if (sheetSpecs.length === 0) {
  throw new Error("The workbook manifest contains no sheets.");
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

function safeSheetName(name, usedNames) {
  const base = String(name)
    .replace(/[\\/*?:\[\]]/g, "_")
    .slice(0, 31) || "Sheet";
  let candidate = base;
  let suffix = 1;
  while (usedNames.has(candidate)) {
    const suffixText = `_${suffix}`;
    candidate = `${base.slice(0, 31 - suffixText.length)}${suffixText}`;
    suffix += 1;
  }
  usedNames.add(candidate);
  return candidate;
}

function normalizeValue(value) {
  if (value === null || value === undefined) return null;
  if (Array.isArray(value)) return value.join("; ");
  if (typeof value === "object") {
    if (Object.keys(value).length === 0) return null;
    return JSON.stringify(value);
  }
  return value;
}

function widthForColumn(header, values) {
  const textLengths = [header, ...values]
    .filter((value) => value !== null && value !== undefined)
    .map((value) => String(value).length);
  const maximum = Math.max(8, ...textLengths);
  const numericHeader = /^(?:n_|D$|E$|P$|rows_|.*_rows$|.*_count$)/.test(
    header,
  );
  if (numericHeader) return Math.min(Math.max(maximum + 2, 11), 18);
  if (/path|reason|note|values|condition|detail/i.test(header)) {
    return Math.min(Math.max(maximum + 2, 22), 58);
  }
  return Math.min(Math.max(maximum + 2, 10), 36);
}

const usedNames = new Set();

for (let sheetIndex = 0; sheetIndex < sheetSpecs.length; sheetIndex += 1) {
  const spec = sheetSpecs[sheetIndex];
  const columns = spec.columns.map(String);
  if (columns.length === 0) {
    throw new Error(`Sheet ${spec.name} has no columns.`);
  }

  const rows = (spec.rows ?? []).map((row) =>
    columns.map((column) => normalizeValue(row[column])),
  );
  const sheetName = safeSheetName(spec.name, usedNames);
  const sheet = workbook.worksheets.add(sheetName);
  sheet.showGridLines = false;

  const matrix = [columns, ...rows];
  const endColumn = excelColumn(columns.length);
  const endRow = Math.max(matrix.length, 1);
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
  sheet.freezePanes.freezeRows(1);

  if (rows.length > 0) {
    const bodyRange = sheet.getRange(`A2:${endColumn}${endRow}`);
    bodyRange.format.borders = {
      insideHorizontal: { style: "thin", color: "#E5E7EB" },
    };
  }

  const columnWidths = [];
  for (let columnIndex = 0; columnIndex < columns.length; columnIndex += 1) {
    const columnName = excelColumn(columnIndex + 1);
    const values = rows.map((row) => row[columnIndex]);
    const columnRange = sheet.getRange(`${columnName}1:${columnName}${endRow}`);
    const columnWidth = widthForColumn(columns[columnIndex], values);
    columnWidths.push(columnWidth);
    columnRange.format.columnWidth = columnWidth;

    const header = columns[columnIndex];
    if (
      /(?:pct_|percentage|earmark_incidence|mean_within_country_share)/i.test(
        header,
      )
    ) {
      if (endRow >= 2) {
        sheet.getRange(`${columnName}2:${columnName}${endRow}`).format.numberFormat =
          "0.0%";
      }
    } else if (/allocation_density/i.test(header)) {
      if (endRow >= 2) {
        sheet.getRange(`${columnName}2:${columnName}${endRow}`).format.numberFormat =
          "0.00";
      }
    } else if (
      /^(?:D|E|P|n_.*|.*_rows|rows_.*|.*_count|.*_counts)$/.test(header)
    ) {
      if (endRow >= 2) {
        sheet.getRange(`${columnName}2:${columnName}${endRow}`).format.numberFormat =
          "#,##0";
      }
    }
  }

  for (let rowIndex = 0; rowIndex < rows.length; rowIndex += 1) {
    let maximumLines = 1;
    for (let columnIndex = 0; columnIndex < columns.length; columnIndex += 1) {
      const value = rows[rowIndex][columnIndex];
      if (value === null || value === undefined) continue;
      const availableCharacters = Math.max(columnWidths[columnIndex] - 2, 8);
      const explicitLines = String(value).split(/\r?\n/);
      const estimatedLines = explicitLines.reduce(
        (total, line) =>
          total + Math.max(1, Math.ceil(line.length / availableCharacters)),
        0,
      );
      maximumLines = Math.max(maximumLines, estimatedLines);
    }
    const rowHeight = Math.min(Math.max(18, maximumLines * 15), 72);
    const excelRow = rowIndex + 2;
    sheet.getRange(`A${excelRow}:${endColumn}${excelRow}`).format.rowHeight =
      rowHeight;
  }

  const previewEndRow = Math.min(endRow, 30);
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
  await fs.mkdir(path.dirname(previewPath), { recursive: true });
  await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));

  const inspection = await workbook.inspect({
    kind: "table",
    range: `${sheetName}!${previewRange}`,
    include: "values,formulas",
    tableMaxRows: Math.min(previewEndRow, 8),
    tableMaxCols: Math.min(columns.length, 12),
    maxChars: 4000,
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
