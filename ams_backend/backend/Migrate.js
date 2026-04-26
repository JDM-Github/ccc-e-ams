// Author: JDM
// Created on: 2026-01-12T15:07:54.704Z

require("dotenv").config();
const { sequelize } = require("./models/Models.js");

async function migrateAll() {
    let transaction;

    try {
        console.log("🚀 Connecting to database...");
        await sequelize.authenticate();
        console.log("✅ Connection established successfully.");
        console.log("🔄 Starting transaction...");
        transaction = await sequelize.transaction();
        console.log("🔄 Running migrations safely...");
        await sequelize.sync({
            alter: true,
            transaction
        });
        console.log("✅ Migration successful, committing...");
        await transaction.commit();
        console.log("🎉 All models migrated safely!");
    } catch (error) {

        if (transaction) {
            console.log("⚠️ Error detected, rolling back...");
            await transaction.rollback();
        }

        console.error("❌ Migration failed:", error);

    } finally {
        await sequelize.close();
    }
}

migrateAll();