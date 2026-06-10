const { User, Office } = require("../../models/Models");
const { createLog } = require("../utils/helpers");

const isValidTime = (t) => /^([01]\d|2[0-3]):([0-5]\d)(:[0-5]\d)?$/.test(t);

// ─── POST /update-office ──────────────────────────────────────────────────────
async function updateOffice(req, res) {
    try {
        const { ccc_id, office_name, office_acronym, time_in_start, time_in_start_wfh, time_in_end, time_out_cap, allow_weekend, office_vision, office_mission } = req.body;

        if (!ccc_id || !office_acronym || !office_name || !time_in_start || !time_in_start_wfh || !time_in_end || !time_out_cap) {
            return res.status(400).json({ success: false, message: "Missing required fields: ccc_id, office_name, time fields" });
        }
        if (!isValidTime(time_in_start) || !isValidTime(time_in_start_wfh) || !isValidTime(time_in_end) || !isValidTime(time_out_cap)) {
            return res.status(400).json({ success: false, message: "Invalid time format. Use HH:mm or HH:mm:ss" });
        }

        const user = await User.findOne({ where: { ccc_id } });
        if (!user || (user.role !== "supervisor" && user.role !== "admin")) {
            return res.status(403).json({ success: false, message: "Unauthorized. Only supervisors or admins can update office." });
        }

        const office = await Office.findOne({ where: { office_id: user.office_id } });
        if (!office) return res.status(404).json({ success: false, message: "Office not found." });

        await Office.update(
            { office_name: office_name.trim(), office_acronym: office_acronym.trim(), time_in_start, time_in_start_wfh, time_in_end, time_out_cap, allow_weekend: !!allow_weekend, office_vision: office_vision ?? office.office_vision, office_mission: office_mission ?? office.office_mission },
            { where: { id: office.id } }
        );
        await createLog("update", `Office settings updated by ${ccc_id}`, ccc_id);

        return res.json({
            success: true,
            message: "Office updated successfully.",
            office: { office_id: office.office_id, office_name, office_acronym, time_in_start, time_in_start_wfh, time_in_end, time_out_cap, allow_weekend: !!allow_weekend },
        });
    } catch (err) {
        console.error("Update office failed:", err);
        return res.status(500).json({ success: false, message: "Failed to update office." });
    }
}

// ─── POST /set-location ───────────────────────────────────────────────────────
async function setLocation(req, res) {
    try {
        const { ccc_id, latitude, longitude } = req.body;
        if (!ccc_id || latitude === undefined || longitude === undefined) {
            return res.status(400).json({ success: false, message: "Missing required fields: ccc_id, latitude, longitude" });
        }

        const lat = parseFloat(latitude);
        const lng = parseFloat(longitude);

        if (isNaN(lat) || lat < -90 || lat > 90) return res.status(400).json({ success: false, message: "Invalid latitude. Must be a number between -90 and 90." });
        if (isNaN(lng) || lng < -180 || lng > 180) return res.status(400).json({ success: false, message: "Invalid longitude. Must be a number between -180 and 180." });

        const supervisor = await User.findOne({ where: { ccc_id, role: "supervisor" } });
        if (!supervisor) return res.status(403).json({ success: false, message: "Unauthorized. Only supervisors or admins can set the office location." });

        const office = await Office.findOne({ where: { office_id: supervisor.office_id } });
        if (!office) return res.status(404).json({ success: false, message: "Office not found for this supervisor." });

        await Office.update({ latitude: lat, longitude: lng }, { where: { id: office.id } });
        await createLog("update", `Office location updated to (${lat}, ${lng}) by ${ccc_id}`, ccc_id);

        return res.json({
            success: true,
            message: "Office location updated successfully.",
            office: { office_id: office.office_id, latitude: office.latitude, longitude: office.longitude },
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to update office location." });
    }
}

module.exports = { updateOffice, setLocation };