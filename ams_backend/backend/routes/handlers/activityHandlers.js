const cloudinary = require("../../service/Cloudinary");
const { ActivityRecord, Summary } = require("../../models/Models");

function extractPublicId(url) {
    if (!url || !url.includes("cloudinary.com")) return null;
    const urlParts = url.split("/");
    const uploadIndex = urlParts.indexOf("upload");
    if (uploadIndex === -1) return null;
    const publicIdWithExt = urlParts.slice(uploadIndex + 2).join("/");
    return publicIdWithExt.replace(/\.[^/.]+$/, "");
}

async function destroyCloudinaryImage(url) {
    const publicId = extractPublicId(url);
    if (publicId) {
        try {
            await cloudinary.uploader.destroy(publicId);
        } catch (e) {
            console.error("Failed to delete Cloudinary image:", e);
        }
    }
}

// ─── GET /fetch-all-ar/:schedule_record ───────────────────────────────────────
async function fetchAllActivityRecords(req, res) {
    try {
        const { schedule_record } = req.params;
        const activityRecords = await ActivityRecord.findAll({ where: { schedule_record_date: schedule_record } });
        return res.json({ success: true, activityRecords });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

// ─── POST /add-ar ─────────────────────────────────────────────────────────────
async function addActivityRecord(req, res) {
    try {
        const { schedule_record_date, image_url, description } = req.body;
        const activityRecord = await ActivityRecord.create({ schedule_record_date, image_url, description });
        return res.json({ success: true, activityRecord });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

// ─── DELETE /delete-ar/:id ────────────────────────────────────────────────────
async function deleteActivityRecord(req, res) {
    try {
        const { id } = req.params;

        const record = await ActivityRecord.findOne({ where: { id } });
        if (!record) return res.status(404).json({ success: false, message: "Record not found" });

        await destroyCloudinaryImage(record.image_url);
        await ActivityRecord.destroy({ where: { id } });

        return res.json({ success: true });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

// ─── GET /fetch-summary/:schedule_record ─────────────────────────────────────
async function fetchSummary(req, res) {
    try {
        const { schedule_record } = req.params;
        const summary = await Summary.findOne({ where: { schedule_record_date: schedule_record } });
        return res.json({ success: true, id: summary ? summary.id : null, summary: summary ? summary.summary_text : "" });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

// ─── POST /add-summary ────────────────────────────────────────────────────────
async function addOrUpdateSummary(req, res) {
    try {
        const { schedule_record_date, summary_text } = req.body;
        let summary = await Summary.findOne({ where: { schedule_record_date } });
        if (summary) {
            await Summary.update({ summary_text }, { where: { schedule_record_date } });
        } else {
            summary = await Summary.create({ schedule_record_date, summary_text });
        }
        return res.json({ success: true, summary });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

// ─── DELETE /delete-summary/:id ───────────────────────────────────────────────
async function deleteSummary(req, res) {
    try {
        const { id } = req.params;
        await Summary.destroy({ where: { id } });
        return res.json({ success: true });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

module.exports = { fetchAllActivityRecords, addActivityRecord, deleteActivityRecord, fetchSummary, addOrUpdateSummary, deleteSummary };