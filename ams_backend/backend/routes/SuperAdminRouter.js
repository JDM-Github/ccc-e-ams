// Author: JDM
// Created on: 2026-03-24T10:34:44.487Z

const express = require("express");
const {
	SuperAdmin,
	Office,
	SpecialKey,
	User,
	SuperAdminLog,
	SupervisorUser,
	OfficeBackup,
	Schedule,
	ActivityRecord,
	Summary,
	Log,
	SchoolYear,
} = require("../models/Models");
const sendEmail = require("../service/EmailSender");
const { Op } = require("sequelize");
const bcrypt = require("bcryptjs");
const CryptoJS = require("crypto-js");
const stringify = require("fast-json-stable-stringify");

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function createSuperAdminLog(type, message) {
	try {
		await SuperAdminLog.create({ log_type: type, message });
	} catch (err) {
		console.error("Failed to create super admin log:", err);
	}
}

const buildRecordDate = (dateValue, ccc_id) => {
	const [yyyy, mm, dd] = String(dateValue).split("-");
	return `${yyyy}${mm}${dd}${ccc_id}`;
};

const formatDateId = () => {
	const d = new Date();
	const year = d.getFullYear();
	const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	const month = months[d.getMonth()];
	const day = String(d.getDate()).padStart(2, "0");
	const hours = String(d.getHours()).padStart(2, "0");
	const mins = String(d.getMinutes()).padStart(2, "0");
	const secs = String(d.getSeconds()).padStart(2, "0");
	return `${year}${month}${day}${hours}${mins}${secs}`;
};
/**
 * Builds a complete backup payload for one office.
 * Shared by both the single-backup (BackupRouter) and backup-all routes.
 * Throws with a `.status` property if the office is not found.
 */
async function buildOfficeBackupPayload(office_id) {
	const office = await Office.findOne({ where: { office_id }, raw: true });
	if (!office) {
		const err = new Error(`Office "${office_id}" not found.`);
		err.status = 404;
		throw err;
	}

	const school_year = await SchoolYear.findOne({ where: { office_id }, raw: true });

	const userRows = await User.findAll({ where: { office_id }, raw: true });
	const cccIds = userRows.map((u) => u.ccc_id);

	const supervisorRows = cccIds.length > 0
		? await SupervisorUser.findAll({ where: { ccc_id: cccIds }, raw: true })
		: [];
	const supervisorMap = {};
	supervisorRows.forEach((s) => (supervisorMap[s.ccc_id] = s));

	const scheduleRows = cccIds.length > 0
		? await Schedule.findAll({ where: { ccc_id: cccIds }, raw: true })
		: [];

	const scheduleRecordDates = scheduleRows.map((s) => buildRecordDate(s.date, s.ccc_id));

	const [activityRows, summaryRows] = scheduleRecordDates.length > 0
		? await Promise.all([
			ActivityRecord.findAll({ where: { schedule_record_date: scheduleRecordDates }, raw: true }),
			Summary.findAll({ where: { schedule_record_date: scheduleRecordDates }, raw: true }),
		])
		: [[], []];

	const activityMap = {};
	activityRows.forEach((a) => { (activityMap[a.schedule_record_date] ??= []).push(a); });
	const summaryMap = {};
	summaryRows.forEach((s) => { (summaryMap[s.schedule_record_date] ??= []).push(s); });

	const logs = cccIds.length > 0
		? await Log.findAll({ where: { user_ccc_id: cccIds }, raw: true })
		: [];

	const users = userRows.map((user) => {
		const userSchedules = scheduleRows
			.filter((s) => s.ccc_id === user.ccc_id)
			.map((schedule) => {
				const key = buildRecordDate(schedule.date, schedule.ccc_id);
				return {
					...schedule,
					activities: activityMap[key] || [],
					summaries: summaryMap[key] || [],
				};
			});

		return {
			...user,
			supervisor_record: supervisorMap[user.ccc_id] || null,
			schedules: userSchedules,
		};
	});

	const backed_up_at = new Date().toISOString();
	const payload = {
		meta: { office_id, backed_up_at },
		office,
		school_year: school_year || null,
		users,
		logs,
	};

	return { office, payload, users, backed_up_at };
}

// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────

class SuperAdminRouter {
	constructor() {
		this.router = express.Router();
		this.getRouter();
		this.postRouter();
		this.deleteRouter();
	}

	getRouter() {

		// ── Logs ────────────────────────────────────────────────────────────────
		this.router.get("/superadmin-logs", async (req, res) => {
			try {
				const logs = await SuperAdminLog.findAll({
					order: [["createdAt", "DESC"]],
				});
				return res.status(200).json({ success: true, logs });
			} catch (error) {
				console.error("Super admin logs error:", error);
				return res.status(500).json({ message: "Internal server error.", error: error.message });
			}
		});

		// ── Offices ─────────────────────────────────────────────────────────────
		this.router.get("/offices", async (req, res) => {
			try {
				const offices = await Office.findAll({ order: [["createdAt", "DESC"]] });
				return res.json({
					success: true,
					offices: offices.map((o) => ({
						id: o.id,
						office_id: o.office_id,
						office_name: o.office_name,
						office_latitude: parseFloat(o.office_latitude),
						office_longitude: parseFloat(o.office_longitude),
						office_altitude: parseFloat(o.office_altitude),
						time_in_start: o.time_in_start,
						time_in_start_wfh: o.time_in_start_wfh,
						time_in_end: o.time_in_end,
						time_out_cap: o.time_out_cap,
						allow_weekend: o.allow_weekend,
						deactivated: o.deactivated,
						createdAt: o.createdAt,
					})),
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({ success: false, message: "Failed to fetch offices." });
			}
		});

		// ── Special Keys ────────────────────────────────────────────────────────
		this.router.get("/special-keys", async (req, res) => {
			try {
				await SpecialKey.destroy({ where: { expires_at: { [Op.lt]: new Date() } } });
				const keys = await SpecialKey.findAll({ order: [["createdAt", "DESC"]] });
				return res.json({
					success: true,
					keys: keys.map((k) => ({
						id: k.id,
						key: k.key,
						email: k.email,
						expires_at: k.expires_at,
						createdAt: k.createdAt,
					})),
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({ success: false, message: "Failed to fetch special keys." });
			}
		});

		// ── Office Members ──────────────────────────────────────────────────────
		/**
		 * GET /superadmin/office-members/:office_id?ay=2025
		 *
		 * Returns all users of an office split into three groups:
		 *   supervisors — role "supervisor" (current_sy <= ay, or all if no ay)
		 *   admins      — role "student" AND isAdmin true (always all, no AY filter)
		 *   members     — role "student" AND isAdmin false (exact current_sy === ay, or all if no ay)
		 *
		 * Deleted users (status "deleted") are excluded.
		 */
		this.router.get("/office-members/:office_id", async (req, res) => {
			try {
				const { office_id } = req.params;
				const ay = req.query.ay ? parseInt(req.query.ay, 10) : null;
				const office = await Office.findOne({ where: { office_id } });
				if (!office) {
					return res.status(404).json({ success: false, message: "Office not found." });
				}

				const baseWhere = {
					office_id,
				};
				const users = await User.findAll({
					where: baseWhere,
					raw: true,
				});

				const cccIds = users.map((u) => u.ccc_id);
				const supervisorRecords = cccIds.length > 0
					? await SupervisorUser.findAll({ where: { ccc_id: cccIds }, raw: true })
					: [];
				const supervisorMap = {};
				supervisorRecords.forEach((s) => (supervisorMap[s.ccc_id] = s));
				const sanitize = (u) => {
					const { password, ...safe } = u;
					return safe;
				};

				const supervisors = [];
				const admins = [];
				const members = [];

				for (const user of users) {
					const safe = sanitize(user);

					if (user.isAdmin) {
						admins.push(safe);
					} else if (user.role === "supervisor") {
						if (!ay || user.current_sy <= ay) {
							supervisors.push({
								...safe,
								supervisor_record: supervisorMap[user.ccc_id] || null,
							});
						}
					} else {
						if (!ay || user.current_sy === ay) {
							members.push(safe);
						}
					}
				}

				return res.json({
					success: true,
					office_id,
					office_name: office.office_name,
					ay: ay ?? null,
					counts: {
						supervisors: supervisors.length,
						admins: admins.length,
						members: members.length,
						total: supervisors.length + admins.length + members.length,
					},
					supervisors,
					admins,
					members,
				});
			} catch (err) {
				console.error("[SuperAdminRouter] GET /office-members/:office_id →", err);
				return res.status(500).json({ success: false, message: "Failed to fetch office members." });
			}
		});

		// ── Available AYs ───────────────────────────────────────────────────────
		/**
		 * GET /superadmin/office-members/:office_id/available-ay
		 *
		 * Returns all distinct academic years (current_sy) found among
		 * non-deleted users of the office, sorted ascending.
		 *
		 * Example response:
		 * {
		 *   success: true,
		 *   office_id: "OFF-001",
		 *   available_ay: [
		 *     { ay: 2025, label: "2025-2026" },
		 *     { ay: 2026, label: "2026-2027" },
		 *   ]
		 * }
		 */
		this.router.get("/office-members/:office_id/available-ay", async (req, res) => {
			try {
				const { office_id } = req.params;

				const office = await Office.findOne({ where: { office_id } });
				if (!office) {
					return res.status(404).json({ success: false, message: "Office not found." });
				}

				const rows = await User.findAll({
					attributes: [
						[sequelize.fn("DISTINCT", sequelize.col("current_sy")), "current_sy"]
					],
					where: {
						office_id,
						status: { [Op.ne]: "deleted" },
					},
					order: [["current_sy", "ASC"]],
					raw: true,
				});
				const available_ay = rows.map((r) => ({
					ay: r.current_sy,
					label: `${r.current_sy}-${r.current_sy + 1}`,
				}));

				return res.json({
					success: true,
					office_id,
					office_name: office.office_name,
					available_ay,
				});
			} catch (err) {
				console.error("[SuperAdminRouter] GET /office-members/:office_id/available-ay →", err);
				return res.status(500).json({ success: false, message: "Failed to fetch available academic years." });
			}
		});

		// ── Backup List (moved from BackupRouter) ───────────────────────────────
		/**
		 * GET /superadmin/backup/list/:office_id
		 *
		 * Returns all stored backups for an office, newest first.
		 * The full json_backup blob is never sent to the client.
		 */
		this.router.get("/backup/list/:office_id", async (req, res) => {
			try {
				const { office_id } = req.params;

				const backups = await OfficeBackup.findAll({
					where: { office_id },
					attributes: ["id", "unique_id", "version", "office_id", "backup_by_superadmin", "createdAt"],
					order: [["createdAt", "DESC"]],
					raw: true,
				});

				return res.json({ success: true, backups });
			} catch (err) {
				console.error("[SuperAdminRouter] GET /backup/list/:office_id →", err);
				return res.status(500).json({ success: false, message: "Internal server error." });
			}
		});

		// ── Backup All Offices ──────────────────────────────────────────────────
		/**
		 * GET /superadmin/backup/all
		 *
		 * Creates a fresh backup for EVERY office in the system.
		 * Each backup is stored as its own OfficeBackup row with
		 * backup_by_superadmin = true.
		 *
		 * Returns a per-office summary: succeeded / failed.
		 */
		this.router.get("/backup/all", async (req, res) => {
			if (!process.env.BACKUP_SECRET) {
				return res.status(500).json({
					success: false,
					message: "BACKUP_SECRET environment variable is not set.",
				});
			}

			try {
				const offices = await Office.findAll({ raw: true });

				if (offices.length === 0) {
					return res.json({ success: true, message: "No offices found.", results: [] });
				}

				const results = await Promise.allSettled(
					offices.map(async (office) => {
						const office_id = office.office_id;

						const { payload, users, backed_up_at } = await buildOfficeBackupPayload(office_id);

						const integrity_hash = CryptoJS.HmacSHA256(
							stringify(payload),
							process.env.BACKUP_SECRET
						).toString(CryptoJS.enc.Hex);

						// Version: increment from the latest existing backup
						const lastBackup = await OfficeBackup.findOne({
							where: { office_id },
							order: [["version", "DESC"]],
						});
						const nextVersion = lastBackup ? lastBackup.version + 1 : 1;

						const unique_id = `SA_${formatDateId()}_${office_id}`;
						await OfficeBackup.create({
							unique_id,
							office_id,
							version: nextVersion,
							json_backup: { integrity_hash, payload },
							backup_by_superadmin: true,
						});

						return {
							office_id,
							office_name: office.office_name,
							unique_id,
							version: nextVersion,
							backed_up_at,
							user_count: users.length,
						};
					})
				);

				const succeeded = [];
				const failed = [];

				results.forEach((result, i) => {
					if (result.status === "fulfilled") {
						succeeded.push(result.value);
					} else {
						failed.push({
							office_id: offices[i].office_id,
							office_name: offices[i].office_name,
							error: result.reason?.message || "Unknown error",
						});
					}
				});

				await createSuperAdminLog(
					"backup",
					`Super admin backed up all offices: ${succeeded.length} succeeded, ${failed.length} failed.`
				);

				return res.json({
					success: true,
					message: `Backup complete. ${succeeded.length}/${offices.length} offices backed up successfully.`,
					succeeded,
					failed,
				});
			} catch (err) {
				console.error("[SuperAdminRouter] GET /backup/all →", err);
				return res.status(500).json({ success: false, message: "Internal server error during full backup." });
			}
		});
	}

	postRouter() {

		// ── Toggle Office ───────────────────────────────────────────────────────
		this.router.post("/toggle-office", async (req, res) => {
			try {
				const { office_id } = req.body;

				if (!office_id) {
					return res.status(400).json({ success: false, message: "office_id is required." });
				}

				const office = await Office.findOne({ where: { office_id } });
				if (!office) {
					return res.status(404).json({ success: false, message: "Office not found." });
				}

				const newState = !office.deactivated;
				await office.update({ deactivated: newState });

				const action = newState ? "deactivated" : "reactivated";
				await createSuperAdminLog(
					newState ? "deactivate" : "update",
					`Office "${office.office_name}" (${office.office_id}) ${action}.`
				);

				return res.json({
					success: true,
					office_id: office.office_id,
					deactivated: newState,
					message: newState
						? `Office "${office.office_name}" has been deactivated.`
						: `Office "${office.office_name}" has been reactivated.`,
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({ success: false, message: "Failed to toggle office status." });
			}
		});

		// ── Create Special Key ──────────────────────────────────────────────────
		this.router.post("/create-key", async (req, res) => {
			try {
				const { email, expires_in_hours } = req.body;

				if (!email) {
					return res.status(400).json({ success: false, message: "Email is required." });
				}

				const existingUser = await User.findOne({ where: { email } });
				if (existingUser) {
					return res.status(400).json({ success: false, message: "Email is already in use." });
				}

				await SpecialKey.destroy({ where: { expires_at: { [Op.lt]: new Date() } } });

				const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
				let key = "";
				for (let i = 0; i < 12; i++) {
					key += characters.charAt(Math.floor(Math.random() * characters.length));
				}

				const hours = expires_in_hours && expires_in_hours > 0 ? expires_in_hours : 3;
				const expiresAt = new Date(Date.now() + hours * 60 * 60 * 1000);

				await SpecialKey.create({ key, email, expires_at: expiresAt });

				await sendEmail(
					email,
					"Your Special Registration Key",
					`Your special key is: ${key}\n\nThis key expires in ${hours} hour(s) on ${expiresAt.toLocaleString("en-PH", { timeZone: "Asia/Manila" })}.\n\nDo not share this key with anyone.`,
					`
					<div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #0f172a; border-radius: 12px; border: 1px solid #1e293b;">
						<h2 style="color: #ffffff; margin-bottom: 4px;">Special Registration Key</h2>
						<p style="color: #94a3b8; font-size: 13px; margin-top: 0;">Use this key to register your admin account.</p>
						<div style="background: #16a34a1a; border: 1px solid #16a34a44; border-radius: 10px; padding: 24px; text-align: center; margin: 24px 0;">
							<p style="color: #94a3b8; font-size: 12px; margin: 0 0 8px;">Your Key</p>
							<p style="color: #4ade80; font-size: 28px; font-weight: 800; letter-spacing: 6px; font-family: monospace; margin: 0;">${key}</p>
						</div>
						<table style="width: 100%; font-size: 12px; color: #94a3b8; border-collapse: collapse;">
							<tr>
								<td style="padding: 6px 0;">Expires in</td>
								<td style="text-align: right; color: #ffffff;">${hours} hour(s)</td>
							</tr>
							<tr>
								<td style="padding: 6px 0;">Expires at</td>
								<td style="text-align: right; color: #ffffff;">${expiresAt.toLocaleString("en-PH", { timeZone: "Asia/Manila" })}</td>
							</tr>
							<tr>
								<td style="padding: 6px 0;">Assigned to</td>
								<td style="text-align: right; color: #ffffff;">${email}</td>
							</tr>
						</table>
						<div style="margin-top: 24px; padding: 12px; background: #f59e0b1a; border: 1px solid #f59e0b33; border-radius: 8px;">
							<p style="color: #fbbf24; font-size: 11px; margin: 0;">⚠ This key is single-use and tied to your email. Do not share it with anyone. It will be destroyed once redeemed or expired.</p>
						</div>
					</div>
					`
				).catch((err) => console.error("Failed to send special key email:", err));

				await createSuperAdminLog(
					"create",
					`Special key generated for ${email} (expires in ${hours} hours).`
				);

				return res.json({ success: true, key, email, expires_at: expiresAt, expires_in_hours: hours });
			} catch (err) {
				console.error(err);
				return res.status(500).json({ success: false, message: "Failed to generate special key." });
			}
		});

		// ── Update Profile ──────────────────────────────────────────────────────
		this.router.post("/update-profile", async (req, res) => {
			try {
				const { id, username, email } = req.body;

				if (!id || !username || !email) {
					return res.status(400).json({
						success: false,
						message: "id, username, and email are required.",
					});
				}

				const admin = await SuperAdmin.findByPk(id);
				if (!admin) {
					return res.status(404).json({ success: false, message: "Super admin not found." });
				}

				const oldUsername = admin.username;
				const oldEmail = admin.email;

				const conflict = await SuperAdmin.findOne({
					where: {
						[Op.and]: [
							{ id: { [Op.ne]: id } },
							{ [Op.or]: [{ username }, { email }] },
						],
					},
				});

				if (conflict) {
					const field = conflict.username === username ? "Username" : "Email";
					return res.status(409).json({ success: false, message: `${field} is already in use.` });
				}

				await admin.update({ username, email });

				await createSuperAdminLog(
					"update",
					`Super admin profile updated: username "${oldUsername}" → "${username}", email "${oldEmail}" → "${email}".`
				);

				return res.json({
					success: true,
					message: "Profile updated successfully.",
					super_admin: {
						id: admin.id,
						username: admin.username,
						email: admin.email,
					},
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({ success: false, message: "Failed to update profile." });
			}
		});

		// ── Change Password ─────────────────────────────────────────────────────
		this.router.post("/change-password", async (req, res) => {
			try {
				const { id, current_password, new_password } = req.body;

				if (!id || !current_password || !new_password) {
					return res.status(400).json({
						success: false,
						message: "id, current_password, and new_password are required.",
					});
				}

				const admin = await SuperAdmin.findByPk(id);
				if (!admin) {
					return res.status(404).json({ success: false, message: "Super admin not found." });
				}

				const isMatch = await bcrypt.compare(current_password, admin.password);
				if (!isMatch) {
					return res.status(401).json({ success: false, message: "Current password is incorrect." });
				}

				if (new_password.length < 8) {
					return res.status(400).json({
						success: false,
						message: "New password must be at least 8 characters.",
					});
				}

				const hashed = await bcrypt.hash(new_password, 10);
				await admin.update({ password: hashed });

				await createSuperAdminLog(
					"update",
					`Super admin (${admin.username}) changed their password.`
				);

				return res.json({ success: true, message: "Password changed successfully." });
			} catch (err) {
				console.error(err);
				return res.status(500).json({ success: false, message: "Failed to change password." });
			}
		});


		// ─────────────────────────────────────────────────────────────────────────────
		// NEW ROUTES — paste these into SuperAdminRouter inside postRouter()
		// Author: JDM
		// ─────────────────────────────────────────────────────────────────────────────

		// ── Edit Member ─────────────────────────────────────────────────────────────
		/**
		 * PATCH /super-admin/member/:ccc_id
		 *
		 * Editable fields (all optional, only provided fields are updated):
		 *   first_name, middle_name, last_name, email,
		 *   course, target_hours, custom_id, isAdmin, role,
		 *   status ("active" | "pending_for_delete" | "deleted")
		 *
		 * Forbidden: password, ccc_id, office_id (use dedicated routes for those).
		 * Strips out any attempt to change those silently.
		 */
		this.router.post("/member/:ccc_id", async (req, res) => {
			try {
				const { ccc_id } = req.params;

				const user = await User.findOne({ where: { ccc_id } });
				if (!user) {
					return res.status(404).json({ success: false, message: "User not found." });
				}

				// Whitelist of editable fields
				const ALLOWED = [
					"first_name",
					"middle_name",
					"last_name",
					"suffix_name",
					"extension_name",
					"email",
					"course",
					"target_hours",
					"custom_id",
					"isAdmin",
					"role",
					"status",
					"current_sy",
				];

				const updates = {};
				for (const field of ALLOWED) {
					if (req.body[field] !== undefined) {
						updates[field] = req.body[field];
					}
				}

				if (Object.keys(updates).length === 0) {
					return res.status(400).json({ success: false, message: "No valid fields provided for update." });
				}

				// If email is being changed, check it isn't already taken by someone else
				if (updates.email) {
					const { Op } = require("sequelize");
					const emailConflict = await User.findOne({
						where: { email: updates.email, ccc_id: { [Op.ne]: ccc_id } },
					});
					if (emailConflict) {
						return res.status(409).json({ success: false, message: "Email is already in use." });
					}
				}

				const before = {
					first_name: user.first_name,
					middle_name: user.middle_name,
					last_name: user.last_name,
					suffix_name: user.suffix_name,
					extension_name: user.extension_name,
					email: user.email,
					role: user.role,
					isAdmin: user.isAdmin,
					status: user.status,
					course: user.course,
					target_hours: user.target_hours,
				};

				await User.update(updates, { where: { ccc_id } });
				await user.reload();

				const changed = Object.keys(updates)
					.filter((k) => before[k] !== undefined && String(before[k]) !== String(updates[k]))
					.map((k) => `${k}: "${before[k]}" → "${updates[k]}"`)
					.join(", ");

				await createSuperAdminLog(
					"update",
					`Member ${ccc_id} (${before.first_name} ${before.last_name}) updated. Changes: ${changed || "none"}.`
				);

				const { password: _, ...safe } = user.toJSON();
				return res.json({
					success: true,
					message: "Member updated successfully.",
					user: safe,
				});
			} catch (err) {
				console.error("[SuperAdminRouter] PATCH /member/:ccc_id →", err);
				return res.status(500).json({ success: false, message: "Failed to update member." });
			}
		});

		// ── Restore Member ───────────────────────────────────────────────────────────
		/**
		 * POST /super-admin/restore-member
		 *
		 * Body: { ccc_id }
		 *
		 * Sets status back to "active" for a soft-deleted user.
		 * Idempotent — calling it on an already-active user is safe (returns success).
		 */
		this.router.post("/restore-member", async (req, res) => {
			try {
				const { ccc_id } = req.body;

				if (!ccc_id) {
					return res.status(400).json({ success: false, message: "ccc_id is required." });
				}

				const user = await User.findOne({ where: { ccc_id } });
				if (!user) {
					return res.status(404).json({ success: false, message: "User not found." });
				}

				const previousStatus = user.status;
				await user.update({ status: "active" });

				await createSuperAdminLog(
					"update",
					`Member ${ccc_id} (${user.first_name} ${user.last_name}) restored from "${previousStatus}" to "active".`
				);

				const { password: _, ...safe } = user.toJSON();
				return res.json({
					success: true,
					message: `${user.first_name} ${user.last_name} has been restored.`,
					user: safe,
				});
			} catch (err) {
				console.error("[SuperAdminRouter] POST /restore-member →", err);
				return res.status(500).json({ success: false, message: "Failed to restore member." });
			}
		});
	}

	deleteRouter() {
		this.router.delete("/special-keys/:id", async (req, res) => {
			try {
				const { id } = req.params;
				const key = await SpecialKey.findByPk(id);
				if (!key) {
					return res.status(404).json({ success: false, message: "Special key not found." });
				}
				await key.destroy();
				return res.json({ success: true, message: "Special key deleted." });
			} catch (err) {
				console.error(err);
				return res.status(500).json({ success: false, message: "Failed to delete special key." });
			}
		});

		
	}
}

module.exports = new SuperAdminRouter().router;