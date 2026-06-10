const { Log } = require("../../models/Models");

// ─── GET /logs/:ccc_id ────────────────────────────────────────────────────────
async function getLogsByUser(req, res) {
    try {
        const { ccc_id } = req.params;
        const logs = await Log.findAll({ where: { user_ccc_id: ccc_id }, order: [["createdAt", "DESC"]], limit: 100 });
        return res.json({ success: true, logs });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to fetch logs" });
    }
}

// ─── GET /logs ────────────────────────────────────────────────────────────────
async function getAllLogs(req, res) {
    try {
        const logs = await Log.findAll({ order: [["createdAt", "DESC"]], limit: 1000 });
        return res.json({ success: true, logs });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to fetch logs" });
    }
}

module.exports = { getLogsByUser, getAllLogs };