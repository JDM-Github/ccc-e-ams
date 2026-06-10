const bcrypt = require("bcryptjs");
const { Op } = require("sequelize");
const { User, Office, SchoolYear, SuperAdmin } = require("../../models/Models");
const { createLog } = require("../utils/helpers");
const { runAutoBackupIfNeeded } = require("../utils/backup");

// POST /login
async function login(req, res) {
    try {
        const { identifier, password } = req.body;
        const userAgent = req.headers["user-agent"] || "Unknown";
        const ip = req.ip || req.socket.remoteAddress || "Unknown";

        if (!identifier || !password) {
            return res.status(400).json({ success: false, message: "Identifier and password are required" });
        }

        const superAdmin = await SuperAdmin.findOne({
            where: { [Op.or]: [{ username: identifier }, { email: identifier }] },
        });
        if (superAdmin) {
            const isMatch = await bcrypt.compare(password, superAdmin.password);
            if (!isMatch) return res.status(401).json({ success: false, message: "Invalid credentials" });
            return res.json({
                success: true,
                is_super_admin: true,
                super_admin: { id: superAdmin.id, username: superAdmin.username, email: superAdmin.email },
            });
        }

        const isEmail = identifier.includes("@");
        const user = await User.findOne({
            where: isEmail ? { email: identifier } : { ccc_id: identifier },
        });

        if (!user) return res.status(401).json({ success: false, message: "Invalid credentials" });

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(401).json({ success: false, message: "Invalid credentials" });

        if (user.status === "pending_for_delete") {
            return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        }
        if (user.status === "deleted") {
            return res.status(403).json({ success: false, message: "This account has been deleted." });
        }

        const office = await Office.findOne({ where: { office_id: user.office_id } });
        if (!office) return res.status(401).json({ success: false, message: "Office not found." });
        if (office.deactivated) {
            return res.status(403).json({ success: false, message: "Your office has been deactivated. Please contact the system administrator." });
        }

        const schoolYear = await SchoolYear.findOne({ where: { office_id: office.office_id } });
        if (!schoolYear) return res.status(401).json({ success: false, message: "School year not found." });

        await runAutoBackupIfNeeded(office, user);
        await createLog("info", `User ${user.ccc_id} (${user.role}) logged in from IP ${ip} (${userAgent})`, user.ccc_id);

        return res.json({
            success: true,
            is_super_admin: false,
            user: {
                ccc_id: user.ccc_id,
                first_name: user.first_name,
                middle_name: user.middle_name,
                last_name: user.last_name,
                extension_name: user.extension_name,
                suffix_name: user.suffix_name,
                role: user.role,
                email: user.email,
                profile_link: user.profile_link,
                course: user.course,
                isAdmin: user.isAdmin,
                target_hours: user.target_hours,

                office_id: office.office_id,
                office_name: office.office_name,
                office_acronym: office.office_acronym,
                office_vision: office.office_vision,
                office_mission: office.office_mission,

                user_sy: user.current_sy,
                current_sy: schoolYear.current_sy,
                current_iteration: schoolYear.current_iteration,
                custom_id: user.custom_id,

                still_active_sy: schoolYear.current_sy + schoolYear.current_iteration - 1 === user.current_sy,
                latitude: parseFloat(office.office_latitude),
                longitude: parseFloat(office.office_longitude),
                altitude: parseFloat(office.office_altitude),

                time_in_start: office.time_in_start,
                time_in_start_wfh: office.time_in_start_wfh,
                time_in_end: office.time_in_end,
                time_out_cap: office.time_out_cap,
                allow_weekend: office.allow_weekend,
            },
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Server error" });
    }
}

// POST /verify-identity
async function verifyIdentity(req, res) {
    try {
        const { ccc_id, email } = req.body;
        if (!ccc_id || !email) {
            return res.status(400).json({ success: false, message: "CCC ID and email are required" });
        }
        const user = await User.findOne({ where: { ccc_id, email }, attributes: ["ccc_id", "status"] });
        if (!user) return res.status(404).json({ success: false, message: "No matching user found" });

        if (user.status === "pending_for_delete") {
            return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        }
        if (user.status === "deleted") {
            return res.status(403).json({ success: false, message: "This account has been deleted." });
        }
        return res.json({ success: true, message: "Identity verified" });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Internal server error" });
    }
}

// POST /reset-password
async function resetPassword(req, res) {
    try {
        const { ccc_id, email, new_password } = req.body;
        if (!ccc_id || !email || !new_password) {
            await createLog("error", "Password reset failed: Missing required fields", null);
            return res.status(400).json({ success: false, message: "CCC ID, email and new password are required" });
        }

        const user = await User.findOne({ where: { ccc_id, email }, attributes: ["ccc_id", "status"] });
        if (!user) {
            await createLog("error", `Password reset failed: No matching user for ${ccc_id} / ${email}`, null);
            return res.status(404).json({ success: false, message: "No matching user found" });
        }
        if (user.status === "pending_for_delete") {
            await createLog("error", `Password reset blocked: Account ${ccc_id} pending deletion`, ccc_id);
            return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        }
        if (user.status === "deleted") {
            await createLog("error", `Password reset blocked: Account ${ccc_id} already deleted`, ccc_id);
            return res.status(403).json({ success: false, message: "This account has been deleted." });
        }

        const hashedPassword = await bcrypt.hash(new_password, 10);
        await User.update({ password: hashedPassword }, { where: { ccc_id } });
        await createLog("update", `Password reset successful for user ${ccc_id}`, ccc_id);
        return res.json({ success: true, message: "Password reset successful" });
    } catch (err) {
        console.error(err);
        await createLog("error", `Password reset exception: ${err.message}`, req.body.ccc_id || null);
        return res.status(500).json({ success: false, message: "Internal server error" });
    }
}

// POST /change-password
async function changePassword(req, res) {
    try {
        const { ccc_id, current_password, new_password } = req.body;
        if (!ccc_id || !current_password || !new_password) {
            return res.status(400).json({ success: false, message: "Missing required fields" });
        }

        const user = await User.findOne({ where: { ccc_id } });
        if (!user) return res.status(403).json({ success: false, message: "User does not exist." });

        if (user.status === "pending_for_delete") {
            return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        }
        if (user.status === "deleted") {
            return res.status(403).json({ success: false, message: "This account has been deleted." });
        }

        const isMatch = await bcrypt.compare(current_password, user.password);
        if (!isMatch) return res.status(401).json({ success: false, message: "Current password is incorrect." });

        const hashedPassword = await bcrypt.hash(new_password, 10);
        await User.update({ password: hashedPassword }, { where: { ccc_id } });
        await createLog("update", "Password changed successfully", ccc_id);
        return res.json({ success: true });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

module.exports = { login, verifyIdentity, resetPassword, changePassword };