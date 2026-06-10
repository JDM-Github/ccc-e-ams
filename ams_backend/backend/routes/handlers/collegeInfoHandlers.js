const { CollegeInfo } = require("../../models/Models");

// ─── GET /college-info ────────────────────────────────────────────────────────
async function getCollegeInfo(req, res) {
    try {
        const info = await CollegeInfo.findOne();
        return res.json({ success: true, info });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

// ─── PUT /college-info ────────────────────────────────────────────────────────
async function updateCollegeInfo(req, res) {
    try {
        const { vision, mission } = req.body;
        let info = await CollegeInfo.findOne();
        if (info) {
            await info.update({ vision, mission });
        } else {
            info = await CollegeInfo.create({ vision, mission });
        }
        return res.json({ success: true, info });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

module.exports = { getCollegeInfo, updateCollegeInfo };