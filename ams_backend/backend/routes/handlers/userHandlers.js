const bcrypt = require("bcryptjs");
const { Op } = require("sequelize");
const { User, Schedule, SupervisorUser, Office, SchoolYear, SpecialKey } = require("../../models/Models");
const { createLog, createSuperAdminLog } = require("../utils/helpers");
const { attachProgress } = require("../utils/progress");
const cloudinary = require("../../service/Cloudinary");

// ─── Shared name validation ────────────────────────────────────────────────────
const nameRegex = /^[a-zA-ZñÑ\s\-']+$/;

function validateNames({ first_name, last_name, middle_name }) {
    if (first_name.trim().length < 2 || !nameRegex.test(first_name.trim()))
        return "Invalid first name. Use letters only, minimum 2 characters.";
    if (last_name.trim().length < 2 || !nameRegex.test(last_name.trim()))
        return "Invalid last name. Use letters only, minimum 2 characters.";
    if (middle_name && middle_name.trim().length > 0 && !nameRegex.test(middle_name.trim()))
        return "Invalid middle name. Use letters only.";
    return null;
}

// ─── GET /get-all ──────────────────────────────────────────────────────────────
async function getAllUsers(req, res) {
    try {
        const users = await User.findAll({ attributes: { exclude: ["password"] } });
        return res.json({ success: true, users });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Internal server error" });
    }
}

// ─── GET /get-all-users/:ccc_id/:current_iteration ────────────────────────────
async function getAllUsersForUser(req, res) {
    try {
        const { ccc_id, current_iteration } = req.params;

        const requestingUser = await User.findOne({ where: { ccc_id } });
        if (!requestingUser) return res.status(404).json({ success: false, message: "User not found" });

        if (requestingUser.status === "pending_for_delete") {
            return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        }
        if (requestingUser.status === "deleted") {
            return res.status(403).json({ success: false, message: "This account has been deleted." });
        }

        const schoolYear = await SchoolYear.findOne({ where: { office_id: requestingUser.office_id } });
        if (!schoolYear) return res.status(500).json({ success: false, message: "School year not configured" });

        const parsedIteration = parseInt(current_iteration, 10);
        if (isNaN(parsedIteration) || parsedIteration < 1) {
            return res.status(400).json({ success: false, message: "Invalid current_iteration" });
        }

        const activeSY = schoolYear.current_sy + parsedIteration - 1;

        const studentAttrs = ["id", "first_name", "middle_name", "last_name", "extension_name", "suffix_name", "ccc_id", "email", "course", "profile_link", "custom_id", "target_hours", "current_sy", "createdAt", "role", "status"];
        const supervisorAttrs = [...studentAttrs, "isAdmin"];

        if (requestingUser.role === "supervisor") {
            const supervisor = await SupervisorUser.findOne({ where: { ccc_id } });
            if (!supervisor) return res.json({ success: true, users: [] });

            const students = await User.findAll({
                where: { ccc_id: supervisor.all_users, current_sy: activeSY },
                attributes: studentAttrs,
            });
            const coSupervisors = await User.findAll({
                where: { role: "supervisor", office_id: requestingUser.office_id, ccc_id: { [Op.ne]: ccc_id } },
                attributes: supervisorAttrs,
            });

            const users = await attachProgress([...students, ...coSupervisors]);
            return res.json({ success: true, users });
        }

        // Student path
        const supervisor = await SupervisorUser.findOne({
            where: { all_users: { [Op.contains]: [ccc_id] } },
        });
        if (!supervisor) return res.json({ success: true, users: [] });

        const peerUsers = await User.findAll({
            where: { ccc_id: { [Op.in]: supervisor.all_users, [Op.ne]: ccc_id }, current_sy: requestingUser.current_sy },
            attributes: studentAttrs,
        });
        const supervisorUsers = await User.findAll({
            where: { role: "supervisor", office_id: requestingUser.office_id, ccc_id: { [Op.ne]: ccc_id } },
            attributes: supervisorAttrs,
        });

        const users = await attachProgress([...peerUsers, ...supervisorUsers]);
        return res.json({ success: true, users: users.filter(Boolean) });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Server error" });
    }
}

// ─── GET /me/:ccc_id ───────────────────────────────────────────────────────────
async function getMe(req, res) {
    try {
        const { ccc_id } = req.params;
        const user = await User.findOne({ where: { ccc_id } });
        if (!user) return res.status(404).json({ success: false });

        if (user.status === "pending_for_delete") {
            return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        }
        if (user.status === "deleted") {
            return res.status(403).json({ success: false, message: "This account has been deleted." });
        }

        const office = await Office.findOne({ where: { office_id: user.office_id } });
        const schoolYear = await SchoolYear.findOne({ where: { office_id: office.office_id } });

        return res.json({
            success: true,
            user: {
                ccc_id: user.ccc_id,
                email: user.email,
                first_name: user.first_name,
                middle_name: user.middle_name,
                last_name: user.last_name,
                extension_name: user.extension_name,
                suffix_name: user.suffix_name,
                role: user.role,
                isAdmin: user.isAdmin,
                profile_link: user.profile_link,
                course: user.course,
                target_hours: user.target_hours,
                office_id: office?.office_id,
                office_name: office?.office_name,
                latitude: parseFloat(office?.office_latitude),
                longitude: parseFloat(office?.office_longitude),
                altitude: parseFloat(office?.office_altitude),
                user_sy: user.current_sy,
                current_sy: schoolYear?.current_sy,
                current_iteration: schoolYear?.current_iteration,
                custom_id: user.custom_id,
                still_active_sy: schoolYear.current_sy + schoolYear.current_iteration - 1 === user.current_sy,
                time_in_start: office.time_in_start,
                time_in_start_wfh: office.time_in_start_wfh,
                time_in_end: office.time_in_end,
                time_out_cap: office.time_out_cap,
                allow_weekend: office.allow_weekend,
            },
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false });
    }
}

// ─── POST /register-admin ──────────────────────────────────────────────────────
async function registerAdmin(req, res) {
    try {
        const { first_name, middle_name, last_name, suffix_name, extension_name, ccc_id, custom_id, email, password, office_name, special_key } = req.body;

        if (!first_name || !last_name || !ccc_id || !custom_id || !email || !password || !office_name || !special_key) {
            return res.status(400).json({ success: false, message: "Missing required fields" });
        }

        // Clean up expired keys first
        await SpecialKey.destroy({ where: { expires_at: { [Op.lt]: new Date() } } });

        const foundKey = await SpecialKey.findOne({ where: { key: special_key, email } });
        if (!foundKey) {
            return res.status(403).json({ success: false, message: "Invalid or expired special key, or key does not match the provided email." });
        }

        const existingUser = await User.findOne({ where: { [Op.or]: [{ ccc_id }, { email }, { custom_id }] } });
        if (existingUser) {
            let conflictField = "User";
            if (existingUser.ccc_id === ccc_id) conflictField = "CCC ID";
            else if (existingUser.email === email) conflictField = "Email";
            else if (existingUser.custom_id === custom_id) conflictField = "Custom ID";
            return res.status(409).json({ success: false, message: `${conflictField} already exists` });
        }

        const officeSlug = office_name.split(" ").filter((w) => /^[A-Z]/.test(w)).map((w) => w[0].toUpperCase()).join("");
        const office_id = `${officeSlug}-${Date.now()}`;

        const office = await Office.create({ office_id, office_name, office_acronym: officeSlug, office_latitude: 0, office_longitude: 0, office_altitude: 0 });

        const currentYear = new Date().getFullYear();
        await SchoolYear.create({ office_id: office.office_id, current_sy: currentYear, current_iteration: 1 });

        const hashedPassword = await bcrypt.hash(password, 10);
        const admin = await User.create({
            first_name, middle_name, last_name, suffix_name, extension_name,
            ccc_id, custom_id, email,
            password: hashedPassword,
            role: "supervisor", course: "", target_hours: 0,
            office_id: office.office_id, isAdmin: true, current_sy: currentYear,
        });

        await SupervisorUser.create({ ccc_id: admin.ccc_id, all_users: [] });
        await SpecialKey.destroy({ where: { key: special_key } });

        await createLog("create", `Admin account created: ${first_name} ${last_name} (Office: ${office_name})`, ccc_id);
        await createSuperAdminLog("create", `New admin registered: ${first_name} ${last_name} (${email}) with office "${office_name}"`);

        return res.json({
            success: true,
            admin: {
                id: admin.id, first_name: admin.first_name, last_name: admin.last_name,
                middle_name: admin.middle_name, suffix_name: admin.suffix_name, extension_name: admin.extension_name,
                ccc_id: admin.ccc_id, custom_id: admin.custom_id, email: admin.email,
                office_id: office.office_id, office_name: office.office_name, office_acronym: office.office_acronym,
            },
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to create admin account" });
    }
}

// ─── POST /register-supervisor ────────────────────────────────────────────────
async function registerSupervisor(req, res) {
    try {
        const { supervisor_ccc_id, first_name, middle_name, last_name, suffix_name, extension_name, ccc_id, custom_id, email, password, office_id } = req.body;

        if (!first_name || !last_name || !ccc_id || !custom_id || !email || !password) {
            return res.status(400).json({ success: false, message: "Missing required fields" });
        }
        const nameError = validateNames({ first_name, last_name, middle_name });
        if (nameError) return res.status(400).json({ success: false, message: nameError });

        if (ccc_id.trim().length < 3) return res.status(400).json({ success: false, message: "CCC ID must be at least 3 characters." });
        if (custom_id.trim().length < 2) return res.status(400).json({ success: false, message: "Custom ID must be at least 2 characters." });
        if (password.length < 6) return res.status(400).json({ success: false, message: "Password must be at least 6 characters." });

        const existingUser = await User.findOne({ where: { [Op.or]: [{ ccc_id: ccc_id.trim() }, { email: email.trim() }, { custom_id: custom_id.trim() }] } });
        if (existingUser) {
            let conflictField = "User";
            if (existingUser.ccc_id === ccc_id.trim()) conflictField = "CCC ID";
            else if (existingUser.email === email.trim()) conflictField = "Email";
            else if (existingUser.custom_id === custom_id.trim()) conflictField = "Custom ID";
            return res.status(409).json({ success: false, message: `${conflictField} already exists` });
        }

        let parentSupervisor = null;
        let inheritedUsers = [];
        if (supervisor_ccc_id) {
            parentSupervisor = await User.findOne({ where: { ccc_id: supervisor_ccc_id, role: "supervisor" } });
            if (!parentSupervisor) return res.status(403).json({ success: false, message: "Invalid supervisor" });
            const supervisorLink = await SupervisorUser.findOne({ where: { ccc_id: supervisor_ccc_id } });
            if (supervisorLink) inheritedUsers = supervisorLink.all_users;
        }

        const resolvedOfficeId = (supervisor_ccc_id && parentSupervisor) ? parentSupervisor.office_id : office_id;
        const office = await Office.findOne({ where: { office_id: resolvedOfficeId } });
        if (!office) return res.status(404).json({ success: false, message: "Office not found." });

        const school_year = await SchoolYear.findOne({ where: { office_id: office.office_id } });
        if (!school_year) return res.status(403).json({ success: false, message: "School year not found." });

        const hashedPassword = await bcrypt.hash(password, 10);
        const supervisor = await User.create({
            first_name: first_name.trim(), middle_name: middle_name ? middle_name.trim() : null,
            last_name: last_name.trim(), suffix_name: suffix_name ? suffix_name.trim() : null,
            extension_name: extension_name ? extension_name.trim() : null,
            ccc_id: ccc_id.trim(), custom_id: custom_id.trim(), email: email.trim(),
            password: hashedPassword, role: "supervisor", course: "",
            office_id: resolvedOfficeId,
            current_sy: school_year.current_sy + school_year.current_iteration - 1,
        });

        await SupervisorUser.create({ ccc_id: supervisor.ccc_id, all_users: [...inheritedUsers] });
        await createLog("create", `Supervisor account created: ${first_name.trim()} ${last_name.trim()}`, supervisor_ccc_id);

        return res.json({
            success: true,
            supervisor: {
                id: supervisor.id, first_name: supervisor.first_name, last_name: supervisor.last_name,
                middle_name: supervisor.middle_name, suffix_name: supervisor.suffix_name, extension_name: supervisor.extension_name,
                ccc_id: supervisor.ccc_id, custom_id: supervisor.custom_id, email: supervisor.email,
            },
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to create supervisor account" });
    }
}

// ─── POST /register-student ───────────────────────────────────────────────────
async function registerStudent(req, res) {
    try {
        const { supervisor_ccc_id, first_name, middle_name, last_name, suffix_name, extension_name, ccc_id, custom_id, email, course, target_hours, password } = req.body;

        if (!supervisor_ccc_id || !first_name || !last_name || !ccc_id || !custom_id || !email || !password) {
            return res.status(400).json({ success: false, message: "Missing required fields" });
        }
        const nameError = validateNames({ first_name, last_name, middle_name });
        if (nameError) return res.status(400).json({ success: false, message: nameError });

        if (ccc_id.trim().length < 3) return res.status(400).json({ success: false, message: "CCC ID must be at least 3 characters." });
        if (custom_id.trim().length < 2) return res.status(400).json({ success: false, message: "Custom ID must be at least 2 characters." });
        if (!course || course.trim().length < 2) return res.status(400).json({ success: false, message: "Course is required." });

        const parsedHours = parseInt(target_hours, 10);
        if (isNaN(parsedHours) || parsedHours < 1 || parsedHours > 99999) {
            return res.status(400).json({ success: false, message: "Target hours must be between 1 and 99999." });
        }
        if (password.length < 6) return res.status(400).json({ success: false, message: "Password must be at least 6 characters." });

        const supervisor = await User.findOne({ where: { ccc_id: supervisor_ccc_id, role: "supervisor" } });
        if (!supervisor) return res.status(403).json({ success: false, message: "Invalid supervisor" });

        const existingUser = await User.findOne({ where: { [Op.or]: [{ ccc_id: ccc_id.trim() }, { email: email.trim() }, { custom_id: custom_id.trim() }] } });
        if (existingUser) {
            let conflictField = "User";
            if (existingUser.ccc_id === ccc_id.trim()) conflictField = "CCC ID";
            else if (existingUser.email === email.trim()) conflictField = "Email";
            else if (existingUser.custom_id === custom_id.trim()) conflictField = "Custom ID";
            return res.status(409).json({ success: false, message: `${conflictField} already exists` });
        }

        const school_year = await SchoolYear.findOne({ where: { office_id: supervisor.office_id } });
        if (!school_year) return res.status(403).json({ success: false, message: "School year not found" });

        const hashedPassword = await bcrypt.hash(password, 10);
        const student = await User.create({
            first_name: first_name.trim(), middle_name: middle_name ? middle_name.trim() : null,
            last_name: last_name.trim(), suffix_name: suffix_name ? suffix_name.trim() : null,
            extension_name: extension_name ? extension_name.trim() : null,
            ccc_id: ccc_id.trim(), custom_id: custom_id.trim(), email: email.trim(),
            course: course.trim(), target_hours: parsedHours,
            password: hashedPassword, role: "student",
            office_id: supervisor.office_id,
            current_sy: school_year.current_sy + school_year.current_iteration - 1,
        });

        await createLog("create", `Student account created: ${first_name.trim()} ${last_name.trim()}`, supervisor_ccc_id);

        // Add to every active supervisor's list in the office
        const officeSupervisors = await User.findAll({
            where: { office_id: supervisor.office_id, role: "supervisor", status: "active" },
            attributes: ["ccc_id"],
        });
        for (const sup of officeSupervisors) {
            const link = await SupervisorUser.findOne({ where: { ccc_id: sup.ccc_id } });
            if (link) {
                await link.update({ all_users: [...new Set([...link.all_users, ccc_id.trim()])] });
            } else {
                await SupervisorUser.create({ ccc_id: sup.ccc_id, all_users: [ccc_id.trim()] });
            }
        }

        return res.json({
            success: true,
            student: {
                id: student.id, first_name: student.first_name, last_name: student.last_name,
                middle_name: student.middle_name, suffix_name: student.suffix_name, extension_name: student.extension_name,
                ccc_id: student.ccc_id, custom_id: student.custom_id, email: student.email,
            },
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to create student account" });
    }
}

// ─── POST /update-student/:id ─────────────────────────────────────────────────
async function updateStudent(req, res) {
    try {
        const studentId = req.params.id;
        const { first_name, middle_name, last_name, suffix_name, extension_name, email, custom_id, course, profile_link, target_hours } = req.body;

        if (!first_name || !last_name || !email || !custom_id) {
            return res.status(400).json({ success: false, message: "Missing required fields: first_name, last_name, email, or custom_id" });
        }
        const nameError = validateNames({ first_name, last_name, middle_name });
        if (nameError) return res.status(400).json({ success: false, message: nameError });
        if (custom_id.trim().length < 2) return res.status(400).json({ success: false, message: "Custom ID must be at least 2 characters." });

        if (target_hours !== undefined && target_hours !== null) {
            const parsed = parseInt(target_hours, 10);
            if (isNaN(parsed) || parsed < 1 || parsed > 99999) {
                return res.status(400).json({ success: false, message: "Target hours must be between 1 and 99999." });
            }
        }

        const student = await User.findOne({ where: { id: studentId, role: "student" } });
        if (!student) return res.status(404).json({ success: false, message: "Student not found" });
        if (student.status === "pending_for_delete") return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        if (student.status === "deleted") return res.status(403).json({ success: false, message: "This account has been deleted." });

        const existingEmail = await User.findOne({ where: { email: email.trim(), id: { [Op.ne]: studentId } } });
        if (existingEmail) return res.status(409).json({ success: false, message: "Email already in use by another account" });

        const existingCustomId = await User.findOne({ where: { custom_id: custom_id.trim(), id: { [Op.ne]: studentId } } });
        if (existingCustomId) return res.status(409).json({ success: false, message: "Custom ID already in use by another account" });

        await student.update({
            first_name: first_name.trim(),
            middle_name: middle_name ? middle_name.trim() : student.middle_name,
            last_name: last_name.trim(),
            suffix_name: suffix_name ? suffix_name.trim() : student.suffix_name,
            extension_name: extension_name ? extension_name.trim() : student.extension_name,
            email: email.trim(), custom_id: custom_id.trim(),
            course: course ?? student.course,
            target_hours: target_hours !== undefined && target_hours !== null ? parseInt(target_hours, 10) : student.target_hours,
            profile_link: profile_link ?? student.profile_link,
        });

        await createLog("update", `Student updated: ${first_name.trim()} ${last_name.trim()}`, student.ccc_id);
        return res.json({
            success: true,
            student: {
                id: student.id, first_name: student.first_name, middle_name: student.middle_name,
                last_name: student.last_name, suffix_name: student.suffix_name, extension_name: student.extension_name,
                ccc_id: student.ccc_id, custom_id: student.custom_id, email: student.email,
                course: student.course, target_hours: student.target_hours,
            },
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to update student" });
    }
}

// ─── POST /update-user/:ccc_id ────────────────────────────────────────────────
async function updateUser(req, res) {
    try {
        const cccId = req.params.ccc_id;
        const { first_name, middle_name, last_name, extension_name, suffix_name, email, course, profile_link, target_hours } = req.body;

        if (!first_name || !last_name || !email) {
            return res.status(400).json({ success: false, message: "Missing required fields: first_name, last_name, or email" });
        }

        const student = await User.findOne({ where: { ccc_id: cccId } });
        if (!student) return res.status(404).json({ success: false, message: "Student not found" });
        if (student.status === "pending_for_delete") return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        if (student.status === "deleted") return res.status(403).json({ success: false, message: "This account has been deleted." });

        const existingEmail = await User.findOne({ where: { email, ccc_id: { [Op.ne]: cccId } } });
        if (existingEmail) return res.status(409).json({ success: false, message: "Email already in use by another account" });

        await User.update({
            first_name, middle_name: middle_name ?? student.middle_name,
            last_name, suffix_name: suffix_name ?? student.suffix_name,
            extension_name: extension_name ?? student.extension_name,
            email, course: course ?? student.course,
            target_hours: target_hours ?? student.target_hours,
            profile_link,
        }, { where: { ccc_id: cccId } });

        await createLog("update", `User updated: ${first_name} ${last_name}`, student.ccc_id);
        return res.json({
            success: true,
            student: {
                id: student.id, first_name: student.first_name, middle_name: student.middle_name,
                last_name: student.last_name, ccc_id: student.ccc_id,
                email: student.email, course: student.course, target_hours: student.target_hours,
            },
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to update user" });
    }
}

// ─── POST /update-status/:id ──────────────────────────────────────────────────
async function updateStatus(req, res) {
    try {
        const targetId = req.params.id;
        const { requester_ccc_id, status } = req.body;

        if (!requester_ccc_id || !status) {
            return res.status(400).json({ success: false, message: "Missing required fields: requester_ccc_id, status" });
        }

        const allowedStatuses = ["active", "pending_for_delete", "deleted"];
        if (!allowedStatuses.includes(status)) {
            return res.status(400).json({ success: false, message: `Invalid status. Must be one of: ${allowedStatuses.join(", ")}` });
        }

        const requester = await User.findOne({ where: { ccc_id: requester_ccc_id, role: "supervisor" } });
        if (!requester) return res.status(403).json({ success: false, message: "Unauthorized. Requester must be a supervisor." });
        if (requester.status === "pending_for_delete") return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        if (requester.status === "deleted") return res.status(403).json({ success: false, message: "This account has been deleted." });

        const isAdmin = requester.isAdmin === true;
        if (!isAdmin && status !== "pending_for_delete") {
            return res.status(403).json({ success: false, message: "Only admins can set status to 'deleted' or restore to 'active'." });
        }

        const target = await User.findOne({ where: { id: targetId } });
        if (!target) return res.status(404).json({ success: false, message: "User not found." });
        if (target.office_id !== requester.office_id) return res.status(403).json({ success: false, message: "You can only manage users within your own office." });
        if (target.ccc_id === requester_ccc_id) return res.status(403).json({ success: false, message: "You cannot change your own account status." });
        if (!isAdmin && target.role === "supervisor") return res.status(403).json({ success: false, message: "Supervisors cannot delete other supervisors." });

        const previousStatus = target.status;
        await target.update({ status });

        const actionLabel = status === "pending_for_delete" ? "marked for deletion" : status === "deleted" ? "permanently deleted" : "restored to active";
        await createLog("update", `User ${target.ccc_id} (${target.first_name} ${target.last_name}) ${actionLabel} by ${requester_ccc_id}`, requester_ccc_id);

        return res.json({
            success: true,
            message: `User ${actionLabel} successfully.`,
            user: { id: target.id, ccc_id: target.ccc_id, status: target.status, previous_status: previousStatus },
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ success: false, message: "Failed to update user status." });
    }
}

// ─── POST /update-profile ─────────────────────────────────────────────────────
async function updateProfile(req, res) {
    try {
        const { ccc_id, image_profile } = req.body;
        const user = await User.findOne({ where: { ccc_id } });
        if (!user) return res.status(403).json({ success: false, message: "User does not exist." });
        if (user.status === "pending_for_delete") return res.status(403).json({ success: false, message: "This account is pending for deletion. Please contact your supervisor/administrator immediately." });
        if (user.status === "deleted") return res.status(403).json({ success: false, message: "This account has been deleted." });

        if (user.profile_link && user.profile_link.includes("cloudinary.com")) {
            try {
                const urlParts = user.profile_link.split("/");
                const uploadIndex = urlParts.indexOf("upload");
                if (uploadIndex !== -1) {
                    const publicIdWithExt = urlParts.slice(uploadIndex + 2).join("/");
                    const publicId = publicIdWithExt.replace(/\.[^/.]+$/, "");
                    await cloudinary.uploader.destroy(publicId);
                }
            } catch (deleteErr) {
                console.error("Failed to delete old Cloudinary profile image:", deleteErr);
            }
        }

        await User.update({ profile_link: image_profile }, { where: { ccc_id } });
        await createLog("update", "Profile picture updated", ccc_id);
        return res.json({ success: true, user });
    } catch (err) {
        console.error(err);
        return res.status(400).json({ success: false });
    }
}

module.exports = {
    getAllUsers, getAllUsersForUser, getMe,
    registerAdmin, registerSupervisor, registerStudent,
    updateStudent, updateUser, updateStatus, updateProfile,
};