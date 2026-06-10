const { Op } = require("sequelize");
const { User, Schedule, SchoolYear, ActivityRecord, Summary } = require("../../models/Models");
const { createLog, createSuperAdminLog } = require("../utils/helpers");
const cloudinary = require("../../service/Cloudinary");

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

// ─── GET /schedules ───────────────────────────────────────────────────────────
async function getAllSchedules(req, res) {
    try {
        const schedules = await Schedule.findAll();
        return res.json({ success: true, schedules });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false });
    }
}

// ─── GET /schedules/:ccc_id ───────────────────────────────────────────────────
async function getSchedulesByUser(req, res) {
    try {
        const { ccc_id } = req.params;
        const schedules = await Schedule.findAll({ where: { ccc_id } });
        return res.json({ success: true, schedules });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false });
    }
}

// ─── POST /get-schedules-with-details ─────────────────────────────────────────
async function getSchedulesWithDetails(req, res) {
    try {
        const { ccc_id, startDate, endDate } = req.body;
        if (!ccc_id) return res.status(400).json({ success: false, message: "ccc_id is required" });

        const user = await User.findOne({ where: { ccc_id } });
        if (!user) return res.status(400).json({ success: false, message: "Student not found." });

        const schedules = await Schedule.findAll({
            where: {
                ccc_id,
                ...(startDate && endDate ? { date: { [Op.between]: [startDate, endDate] } } : {}),
            },
            order: [["date", "ASC"]],
        });

        if (!schedules.length) return res.json({ success: true, data: [] });

        const keys = schedules.map((s) => {
            const d = new Date(s.date);
            return d.getFullYear().toString() + String(d.getMonth() + 1).padStart(2, "0") + String(d.getDate()).padStart(2, "0") + s.ccc_id;
        });

        const [activities, summaries] = await Promise.all([
            ActivityRecord.findAll({ where: { schedule_record_date: { [Op.in]: keys } } }),
            Summary.findAll({ where: { schedule_record_date: { [Op.in]: keys } } }),
        ]);

        const activityMap = {};
        activities.forEach((a) => { (activityMap[a.schedule_record_date] ??= []).push(a.image_url); });
        const summaryMap = {};
        summaries.forEach((s) => { summaryMap[s.schedule_record_date] = s.summary_text; });

        const data = schedules.map((s) => {
            const d = new Date(s.date);
            const key = d.getFullYear().toString() + String(d.getMonth() + 1).padStart(2, "0") + String(d.getDate()).padStart(2, "0") + s.ccc_id;
            return {
                ccc_id: s.ccc_id, date: s.date, time_in: s.time_in, time_out: s.time_out,
                proof_in: s.proof_in, proof_out: s.proof_out,
                isAcceptedEarly: s.isAcceptedEarly, isAcceptedWorkFromHome: s.isAcceptedWorkFromHome, isWorkFromHome: s.isWorkFromHome,
                activities: activityMap[key] || [],
                summary_text: summaryMap[key] || null,
            };
        });

        return res.json({ success: true, data, full_name: `${user.first_name} ${user.middle_name} ${user.last_name}`, course: user.course });
    } catch (err) {
        console.error("Fetch schedules failed:", err);
        return res.status(500).json({ success: false, message: "Failed to fetch schedules" });
    }
}

// ─── POST /schedule (time-in) ─────────────────────────────────────────────────
async function timeIn(req, res) {
    try {
        const { ccc_id, date, time_in, proof_in, isInOffice } = req.body;
        const schedule = await Schedule.create({ ccc_id, date, time_in, proof_in, isWorkFromHome: !isInOffice });
        await createLog("timeIn", `Time in recorded for ${date}`, ccc_id);
        return res.json({ success: true, schedule });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

// ─── PUT /schedule/timeout ────────────────────────────────────────────────────
async function timeOut(req, res) {
    try {
        const { id, ccc_id, date, time_out, proof_out } = req.body;

        const existing = await Schedule.findOne({ where: { ccc_id, date, id } });
        if (existing?.proof_out) await destroyCloudinaryImage(existing.proof_out);
        const updated = await Schedule.update({ time_out, proof_out }, { where: { ccc_id, date, id } });
        await createLog("timeOut", `Time out recorded for ${date}`, ccc_id);
        return res.json({ success: true, updated });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

// ─── POST /schedule/add ───────────────────────────────────────────────────────
async function addSchedule(req, res) {
    try {
        const { ccc_id, date, time_in, time_out, isInOffice, isAcceptedEarly, isAcceptedWorkFromHome } = req.body;
        if (!ccc_id || !date || !time_in) {
            return res.status(400).json({ success: false, message: "ccc_id, date, and time_in are required" });
        }

        const existing = await Schedule.findOne({ where: { ccc_id, date } });
        if (existing) return res.status(409).json({ success: false, message: "A schedule already exists for this date." });

        const newRecord = await Schedule.create({ ccc_id, date, time_in, time_out: time_out ?? null, isWorkFromHome: !isInOffice, isAcceptedEarly, isAcceptedWorkFromHome });
        await createLog("create", `Schedule manually added for ${date}`, ccc_id);
        return res.json({ success: true, message: "Schedule added", schedule: newRecord });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false, message: err.message });
    }
}

// ─── POST /schedule/update ────────────────────────────────────────────────────
async function updateSchedule(req, res) {
    try {
        const { id, time_in, time_out, isInOffice, isAcceptedEarly, isAcceptedWorkFromHome, proof_in, proof_out } = req.body;
        if (!id) return res.status(400).json({ success: false, message: "Schedule ID is required" });

        const existing = await Schedule.findOne({ where: { id } });
        if (!existing) return res.status(404).json({ success: false, message: "Schedule not found" });

        if (proof_in && proof_in !== existing.proof_in) await destroyCloudinaryImage(existing.proof_in);
        if (proof_out && proof_out !== existing.proof_out) await destroyCloudinaryImage(existing.proof_out);

        const [updated] = await Schedule.update(
            { time_in, time_out: time_out ?? null, isWorkFromHome: !isInOffice, isAcceptedEarly, isAcceptedWorkFromHome },
            { where: { id } }
        );
        if (!updated) return res.status(404).json({ success: false, message: "Schedule not found" });

        await createLog("update", "Schedule updated", null);
        return res.json({ success: true, message: "Schedule updated successfully" });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to update schedule" });
    }
}

// ─── DELETE /schedule/:id ─────────────────────────────────────────────────────
async function deleteSchedule(req, res) {
    try {
        const { id } = req.params;
        if (!id) return res.status(400).json({ success: false, message: "Schedule ID is required" });

        const existing = await Schedule.findOne({ where: { id } });
        if (!existing) return res.status(404).json({ success: false, message: "Schedule not found" });

        await destroyCloudinaryImage(existing.proof_in);
        await destroyCloudinaryImage(existing.proof_out);

        const deleted = await Schedule.destroy({ where: { id } });
        if (!deleted) return res.status(404).json({ success: false, message: "Schedule not found" });

        await createLog("delete", "Schedule deleted", null);
        return res.json({ success: true, message: "Schedule deleted successfully" });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to delete schedule" });
    }
}

// ─── POST /schedule/sync ──────────────────────────────────────────────────────
async function syncSchedules(req, res) {
    try {
        const { ccc_id, schedules } = req.body;
        for (const record of schedules) {
            await Schedule.upsert({
                ccc_id,
                date: record.date,
                time_in: record.time_in,
                time_out: record.time_out ?? null,
                proof_in: record.proof_in ?? null,
                proof_out: record.proof_out ?? null,
            });
        }
        return res.json({ success: true, message: "Schedules synced" });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

// ─── POST /advance-iteration/:ccc_id ─────────────────────────────────────────
async function advanceIteration(req, res) {
    try {
        const { ccc_id } = req.params;

        const user = await User.findOne({ where: { ccc_id } });
        if (!user) return res.status(404).json({ success: false, message: "User not found" });
        if (user.status === "pending_for_delete") return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        if (user.status === "deleted") return res.status(403).json({ success: false, message: "This account has been deleted." });

        const schoolYear = await SchoolYear.findOne({ where: { office_id: user.office_id } });
        if (!schoolYear) return res.status(500).json({ success: false, message: "School year not configured" });

        const oldIteration = schoolYear.current_iteration;
        const newIteration = oldIteration + 1;

        await SchoolYear.update({ current_iteration: newIteration }, { where: { office_id: user.office_id } });

        await createLog("update", `Advanced to iteration ${newIteration} for office ${user.office_id}`, ccc_id);
        await createSuperAdminLog("update", `Iteration advanced from ${oldIteration} to ${newIteration} for office ${user.office_id} by user ${ccc_id}`);

        return res.json({ success: true, current_sy: schoolYear.current_sy, current_iteration: newIteration });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to advance iteration" });
    }
}

module.exports = {
    getAllSchedules, getSchedulesByUser, getSchedulesWithDetails,
    timeIn, timeOut, addSchedule, updateSchedule, deleteSchedule, syncSchedules,
    advanceIteration,
};