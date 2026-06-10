// Author: JDM
// Created on: 2026-03-15
require("dotenv").config();
const { sequelize } = require("./models/Models.js");
const fs = require("fs");
const path = require("path");
const BACKUP_DIR = path.join(__dirname, "backups");

// ─── Helpers ─────────────────────────────────────────────────────────────────

function formatValue(val) {
    if (val === null || val === undefined) return "NULL";
    if (typeof val === "number" || typeof val === "boolean") return String(val);
    // Escape single quotes inside string values
    return `'${String(val).replace(/'/g, "''")}'`;
}

function quoteIdent(name) {
    // PostgreSQL uses double quotes, MySQL uses backticks
    const dialect = sequelize.getDialect();
    return dialect === "mysql" || dialect === "mariadb"
        ? `\`${name}\``
        : `"${name}"`;
}

function buildCreateTable(table, columns) {
    const lines = columns.map((col) => {
        let line = `    ${quoteIdent(col.name)} ${col.type}`;

        if (col.allowNull === false || col.allowNull === "NO") line += " NOT NULL";
        if (col.defaultValue !== null && col.defaultValue !== undefined) {
            line += ` DEFAULT ${formatValue(col.defaultValue)}`;
        }
        if (col.primaryKey || col.primaryKey === "PRI") line += " PRIMARY KEY";
        if (col.autoIncrement) line += " AUTO_INCREMENT";

        return line;
    });

    return (
        `CREATE TABLE IF NOT EXISTS ${quoteIdent(table)} (\n` +
        lines.join(",\n") +
        `\n);`
    );
}

function buildInserts(table, rows) {
    if (!rows || rows.length === 0) return `-- (no data in "${table}")`;

    const chunks = [];
    // Batch every 100 rows so the dump stays readable
    for (let i = 0; i < rows.length; i += 100) {
        const batch = rows.slice(i, i + 100);
        const cols = Object.keys(batch[0])
            .map((c) => quoteIdent(c))
            .join(", ");
        const values = batch
            .map((row) => `(${Object.values(row).map(formatValue).join(", ")})`)
            .join(",\n    ");
        chunks.push(`INSERT INTO ${quoteIdent(table)} (${cols}) VALUES\n    ${values};`);
    }
    return chunks.join("\n\n");
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function dumpAll() {
    try {
        console.log("🚀 Connecting to database...");
        await sequelize.authenticate();
        console.log("✅ Connection established.\n");

        if (!fs.existsSync(BACKUP_DIR)) {
            fs.mkdirSync(BACKUP_DIR, { recursive: true });
            console.log(`📁 Created backup directory: ${BACKUP_DIR}`);
        }

        const qi = sequelize.getQueryInterface();
        const tables = await qi.showAllTables();
        console.log(`🗂️  Found ${tables.length} table(s): ${tables.join(", ")}\n`);

        const timestamp = new Date().toISOString();
        const dialect = sequelize.getDialect();

        // ── Header ────────────────────────────────────────────────────────────
        const lines = [];
        lines.push(`-- ============================================================`);
        lines.push(`-- Database Dump`);
        lines.push(`-- Created at : ${timestamp}`);
        lines.push(`-- Dialect    : ${dialect}`);
        lines.push(`-- Tables     : ${tables.join(", ")}`);
        lines.push(`-- ============================================================`);
        lines.push(``);
        const isMysql = dialect === "mysql" || dialect === "mariadb";
        lines.push(isMysql ? `SET FOREIGN_KEY_CHECKS = 0;` : `-- Foreign key checks disabled via CASCADE in table definitions`);
        lines.push(``);

        // ── Per-table ─────────────────────────────────────────────────────────
        for (const table of tables) {
            console.log(`📋 Dumping table: "${table}"`);

            // Table structure
            const columns = await qi.describeTable(table);
            const colArray = Object.entries(columns).map(([name, def]) => ({
                name,
                ...def,
            }));

            const rows = await sequelize.query(`SELECT * FROM ${quoteIdent(table)}`, {
                type: sequelize.QueryTypes.SELECT,
            });

            lines.push(`-- ──────────────────────────────────────────────────────────`);
            lines.push(`-- Table: \`${table}\``);
            lines.push(`-- Columns : ${colArray.length}`);
            lines.push(`-- Rows    : ${rows.length}`);
            lines.push(`-- ──────────────────────────────────────────────────────────`);
            lines.push(``);

            lines.push(`DROP TABLE IF EXISTS ${quoteIdent(table)};`);
            lines.push(buildCreateTable(table, colArray));
            lines.push(``);

            // Column reference comment so you can read the dump easily
            lines.push(`-- Columns: ${colArray.map((c) => c.name).join(" | ")}`);
            lines.push(buildInserts(table, rows));
            lines.push(``);

            console.log(`  ✅ ${rows.length} row(s) dumped.`);
        }

        lines.push(isMysql ? `SET FOREIGN_KEY_CHECKS = 1;` : `-- End of dump`);
        lines.push(``);
        lines.push(`-- ============================================================`);
        lines.push(`-- End of Dump — ${timestamp}`);
        lines.push(`-- ============================================================`);

        // ── Write file ────────────────────────────────────────────────────────
        const safeTs = timestamp.replace(/[:.]/g, "-");
        const filename = `dump-${safeTs}.sql`;
        const filepath = path.join(BACKUP_DIR, filename);

        fs.writeFileSync(filepath, lines.join("\n"), "utf-8");

        console.log(`\n✅ Dump completed!`);
        console.log(`📄 Saved to: ${filepath}`);
    } catch (error) {
        console.error("❌ Dump failed:", error);
    } finally {
        await sequelize.close();
    }
}

dumpAll();
