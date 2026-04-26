// Author: JDM
// Created on: 2026-03-15

require("dotenv").config();
const { sequelize } = require("./models/Models.js");
const fs = require("fs");
const path = require("path");

const BACKUP_DIR = path.join(__dirname, "backups");

async function backupAll() {
    try {
        console.log("🚀 Connecting to database...");
        await sequelize.authenticate();
        console.log("✅ Connection established successfully.");

        if (!fs.existsSync(BACKUP_DIR)) {
            fs.mkdirSync(BACKUP_DIR, { recursive: true });
            console.log(`📁 Created backup directory: ${BACKUP_DIR}`);
        }

        console.log("📦 Starting backup...");
        const tables = await sequelize.getQueryInterface().showAllTables();
        console.log(`🗂️  Found ${tables.length} table(s): ${tables.join(", ")}`);

        const backup = {
            createdAt: new Date().toISOString(),
            dialect: sequelize.getDialect(),
            tables: {},
        };

        for (const table of tables) {
            const rows = await sequelize.query(`SELECT * FROM \`${table}\``, {
                type: sequelize.QueryTypes.SELECT,
            });
            backup.tables[table] = rows;
            console.log(`  ✅ Backed up "${table}" — ${rows.length} row(s)`);
        }

        const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
        const filename = `backup-${timestamp}.json`;
        const filepath = path.join(BACKUP_DIR, filename);

        fs.writeFileSync(filepath, JSON.stringify(backup, null, 2), "utf-8");

        console.log(`\n✅ Backup completed successfully!`);
        console.log(`📄 Saved to: ${filepath}`);
    } catch (error) {
        console.error("❌ Backup failed:", error);
    } finally {
        await sequelize.close();
    }
}

backupAll();