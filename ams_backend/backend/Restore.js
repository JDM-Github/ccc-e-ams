// Author: JDM
// Created on: 2026-03-15

require("dotenv").config();
const { sequelize } = require("./models/Models.js");
const fs = require("fs");
const path = require("path");

const BACKUP_DIR = path.join(__dirname, "backups");

// ─── Pick backup file ────────────────────────────────────────────────────────
// You can pass a filename as an argument:  node restore.js backup-2026-03-15.json
// If no argument is given, it will use the LATEST backup automatically.
function resolveBackupFile() {
    const arg = process.argv[2];

    if (arg) {
        const full = path.isAbsolute(arg) ? arg : path.join(BACKUP_DIR, arg);
        if (!fs.existsSync(full)) {
            console.error(`❌ File not found: ${full}`);
            process.exit(1);
        }
        return full;
    }

    // Auto-pick latest
    if (!fs.existsSync(BACKUP_DIR)) {
        console.error(`❌ Backup directory not found: ${BACKUP_DIR}`);
        process.exit(1);
    }

    const files = fs
        .readdirSync(BACKUP_DIR)
        .filter((f) => f.startsWith("backup-") && f.endsWith(".json"))
        .sort()
        .reverse();

    if (files.length === 0) {
        console.error("❌ No backup files found in:", BACKUP_DIR);
        process.exit(1);
    }

    return path.join(BACKUP_DIR, files[0]);
}

// ─── Restore ─────────────────────────────────────────────────────────────────
async function restoreAll() {
    const backupFile = resolveBackupFile();
    console.log(`📄 Using backup file: ${backupFile}`);

    let backup;
    try {
        backup = JSON.parse(fs.readFileSync(backupFile, "utf-8"));
    } catch (err) {
        console.error("❌ Failed to read backup file:", err.message);
        process.exit(1);
    }

    console.log(`🕒 Backup was created at: ${backup.createdAt}`);
    console.log(`🗂️  Tables in backup: ${Object.keys(backup.tables).join(", ")}`);

    try {
        console.log("\n🚀 Connecting to database...");
        await sequelize.authenticate();
        console.log("✅ Connection established successfully.");

        const qi = sequelize.getQueryInterface();

        for (const [table, rows] of Object.entries(backup.tables)) {
            console.log(`\n🔄 Restoring "${table}"...`);

            if (rows.length === 0) {
                console.log(`  ⚠️  No rows to restore for "${table}", skipping.`);
                continue;
            }

            await sequelize.query(`DELETE FROM \`${table}\``);
            console.log(`  🗑️  Cleared existing rows.`);
            await qi.bulkInsert(table, rows);
            console.log(`  ✅ Restored ${rows.length} row(s).`);
        }

        console.log("\n✅ Restore completed successfully!");
        console.log("💡 Your database is back to the state at:", backup.createdAt);
    } catch (error) {
        console.error("❌ Restore failed:", error);
    } finally {
        await sequelize.close();
    }
}

restoreAll();