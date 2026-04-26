// remove.js

require("dotenv").config();
const {sequelize} = require("./models/Models.js");

async function remove() {
    try {
        console.log("Connecting...");
        await sequelize.authenticate();
        console.log("Connected.");

        const [result] = await sequelize.query(
            `
            DELETE FROM "Schedules"
            WHERE ccc_id = :ccc_id
            AND date = :date
            `,
            {
                replacements: {
                    ccc_id: "2022-10934",
                    date: "2025-03-02",
                },
            }
        );

        console.log("Delete executed.");

        const [rows] = await sequelize.query(`
    SELECT ccc_id, date
    FROM "Schedules" WHERE ccc_id = '2022-10934'
`);
        console.log(rows);
    } catch (error) {
        console.error("Error:", error);
    } finally {
    }
}

remove();