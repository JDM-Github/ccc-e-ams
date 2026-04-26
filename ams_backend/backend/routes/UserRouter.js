// Author: JDM
// Created on: 2026-01-12T15:20:33.119Z
const express = require("express");
const bcrypt = require("bcryptjs");
const multer = require("multer");
const CryptoJS = require("crypto-js");
const stringify = require("fast-json-stable-stringify");
const cloudinary = require("../service/Cloudinary");
const { Op } = require("sequelize");
const { User, Schedule, SupervisorUser, Office, ActivityRecord, Log, SchoolYear, Summary, SuperAdmin, SpecialKey, SuperAdminLog, OfficeBackup } = require("../models/Models");

const upload = multer({ storage: multer.memoryStorage() });
async function createLog(type, message, userCccId = null) {
	try {
		await Log.create({
			user_ccc_id: userCccId,
			log_type: type,
			message,
		});
	} catch (err) {
		console.error('Failed to create log:', err);
	}
}
async function createSuperAdminLog(type, message) {
	try {
		await SuperAdminLog.create({
			log_type: type,
			message,
		});
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

class UserRouter {
	constructor() {
		this.router = express.Router();
		this.getRouter();
		this.postRouter();
		this.putRouter();
	}

	getRouter() {
		this.router.get("/get-all", async (req, res) => {
			try {
				const users = await User.findAll({
					attributes: { exclude: ["password"] },
				});
				res.json({ success: true, users });
			} catch (err) {
				console.error(err);
				res.status(500).json({ success: false, message: "Internal server error" });
			}
		});

		this.router.get("/schedules", async (req, res) => {
			try {
				const schedules = await Schedule.findAll();
				res.json({ success: true, schedules });
			} catch (err) {
				console.error(err);
				res.status(500).json({ success: false });
			}
		});

		this.router.get("/schedules/:ccc_id", async (req, res) => {
			try {
				const { ccc_id } = req.params;
				const schedules = await Schedule.findAll({ where: { ccc_id } });
				res.json({ success: true, schedules });
			} catch (err) {
				console.error(err);
				res.status(500).json({ success: false });
			}
		});

		this.router.get("/get-all-users/:ccc_id/:current_iteration", async (req, res) => {
			try {
				const { ccc_id, current_iteration } = req.params;

				const requestingUser = await User.findOne({ where: { ccc_id } });
				if (!requestingUser) {
					return res.status(404).json({ success: false, message: "User not found" });
				}

				if (requestingUser.status === "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. Please contact your supervisor/administrator immediately.",
					});
				}

				if (requestingUser.status === "deleted") {
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}

				const schoolYear = await SchoolYear.findOne({where: {office_id: requestingUser.office_id}});
				if (!schoolYear) {
					return res.status(500).json({ success: false, message: "School year not configured" });
				}

				const parsedIteration = parseInt(current_iteration, 10);
				if (isNaN(parsedIteration) || parsedIteration < 1) {
					return res.status(400).json({ success: false, message: "Invalid current_iteration" });
				}

				const activeSY = schoolYear.current_sy + parsedIteration - 1;

				const studentAttrs = [
					"id", "first_name", "middle_name", "last_name",
					"ccc_id", "email", "course", "profile_link", "custom_id",
					"target_hours", "current_sy", "createdAt", "role", "status"
				];
				const supervisorAttrs = [...studentAttrs, "isAdmin"];

				function calculateHours(timeInStr, timeOutStr) {
					if (!timeInStr || !timeOutStr) return 0;
					const [inH, inM] = timeInStr.split(":").map(Number);
					const [outH, outM] = timeOutStr.split(":").map(Number);
					const timeInMinutes = inH * 60 + inM;
					const timeOutMinutes = outH * 60 + outM;
					if (timeOutMinutes <= timeInMinutes) return 0;
					let totalMinutes = timeOutMinutes - timeInMinutes;
					const lunchStart = 720;
					const lunchEnd = 780;
					if (timeOutMinutes > lunchStart && timeInMinutes < lunchEnd) {
						const overlapStart = Math.max(timeInMinutes, lunchStart);
						const overlapEnd = Math.min(timeOutMinutes, lunchEnd);
						totalMinutes -= (overlapEnd - overlapStart);
					}
					return totalMinutes / 60.0;
				}

				function getEffectiveTimeIn(record) {
					const [inH, inM] = record.time_in.split(":").map(Number);
					const isEarly = inH * 60 + inM < 8 * 60;
					if (isEarly && !record.isAcceptedEarly) return "08:00";
					return record.time_in;
				}

				function isPastDate(dateStr) {
					const today = new Date();
					today.setHours(0, 0, 0, 0);
					const d = new Date(dateStr);
					d.setHours(0, 0, 0, 0);
					return d < today;
				}

				function computeProgress(schedules, targetHours) {
					const total_schedules = schedules.length;

					const completed_hours = schedules.reduce((sum, record) => {
						if (record.isWorkFromHome && !record.isAcceptedWorkFromHome) return sum;

						const effectiveTimeIn = getEffectiveTimeIn(record);
						let effectiveTimeOut = record.time_out;

						if (isPastDate(record.date) && !effectiveTimeOut) {
							effectiveTimeOut = "17:00";
						}

						if (!effectiveTimeOut) return sum;
						return sum + calculateHours(effectiveTimeIn, effectiveTimeOut);
					}, 0);

					const target = targetHours ?? 450;
					const progress = target > 0 ? Math.min(completed_hours / target, 1.0) : 0.0;
					const remaining_hours = Math.max(target - completed_hours, 0);
					const is_done = completed_hours >= target;

					return {
						completed_hours: Math.round(completed_hours * 100) / 100,
						remaining_hours: Math.round(remaining_hours * 100) / 100,
						total_schedules,
						progress: Math.round(progress * 10000) / 10000,
						is_done,
					};
				}

				async function attachProgress(users) {
					return Promise.all(
						users.map(async (user) => {
							const plain = user.toJSON ? user.toJSON() : { ...user };

							if (plain.role === "supervisor") {
								return {
									...plain,
									completed_hours: null,
									remaining_hours: null,
									total_schedules: null,
									progress: null,
									is_done: null,
								};
							}

							const schedules = await Schedule.findAll({
								where: { ccc_id: plain.ccc_id },
								attributes: [
									"date",
									"time_in",
									"time_out",
									"isWorkFromHome",
									"isAcceptedWorkFromHome",
									"isAcceptedEarly",
								],
								raw: true,
							});

							return { ...plain, ...computeProgress(schedules, plain.target_hours) };
						})
					);
				}

				if (requestingUser.role === "supervisor") {
					const supervisor = await SupervisorUser.findOne({ where: { ccc_id } });

					if (!supervisor) {
						return res.json({ success: true, users: [] });
					}

					const students = await User.findAll({
						where: { ccc_id: supervisor.all_users, current_sy: activeSY },
						attributes: studentAttrs,
					});

					const coSupervisors = await User.findAll({
						where: {
							role: "supervisor",
							office_id: requestingUser.office_id,
							ccc_id: { [Op.ne]: ccc_id },
						},
						attributes: supervisorAttrs,
					});

					const users = await attachProgress([...students, ...coSupervisors]);
					return res.json({ success: true, users });
				}

				const supervisor = await SupervisorUser.findOne({
					where: { all_users: { [Op.contains]: [ccc_id] } },
				});

				if (!supervisor) {
					return res.json({ success: true, users: [] });
				}

				const peerUsers = await User.findAll({
					where: {
						ccc_id: { [Op.in]: supervisor.all_users, [Op.ne]: ccc_id },
						current_sy: requestingUser.current_sy,
					},
					attributes: studentAttrs,
				});

				const supervisorUsers = await User.findAll({
					where: {
						role: "supervisor",
						office_id: requestingUser.office_id,
						ccc_id: { [Op.ne]: ccc_id },
					},
					attributes: supervisorAttrs,
				});

				const users = await attachProgress([...peerUsers, ...supervisorUsers]);
				return res.json({ success: true, users: users.filter(Boolean) });

			} catch (err) {
				console.error(err);
				return res.status(500).json({ success: false, message: "Server error" });
			}
		});

		this.router.get("/logs/:ccc_id", async (req, res) => {
			try {
				const { ccc_id } = req.params;
				const logs = await Log.findAll({
					where: { user_ccc_id: ccc_id },
					order: [['createdAt', 'DESC']],
					limit: 100
				});
				res.json({ success: true, logs });
			} catch (err) {
				console.error(err);
				res.status(500).json({ success: false, message: "Failed to fetch logs" });
			}
		});

		this.router.get("/logs", async (req, res) => {
			try {
				const logs = await Log.findAll({
					order: [['createdAt', 'DESC']],
					limit: 1000
				});
				return res.json({ success: true, logs });
			} catch (err) {
				console.error(err);
				res.status(500).json({ success: false, message: "Failed to fetch logs" });
			}
		});
	}

	postRouter() {
		this.router.post('/verify-identity', async (req, res) => {
			try {
				const { ccc_id, email } = req.body;
				if (!ccc_id || !email) {
					return res.status(400).json({ success: false, message: "CCC ID and email are required" });
				}
				const user = await User.findOne({
					where: { ccc_id, email },
					attributes: ['ccc_id'],
				});
				if (user) {
					if (user.status === "pending_for_delete") {
						return res.status(403).json({
							success: false,
							message: "This account is pending for deletion. " +
								"Please contact your supervisor/administrator immediately.",
						});
					}
					if (user.status === "deleted") {
						return res.status(403).json({
							success: false,
							message: "This account has been deleted.",
						});
					}
					return res.json({ success: true, message: "Identity verified" });
				} else {
					return res.status(404).json({ success: false, message: "No matching user found" });
				}
			} catch (err) {
				console.error(err);
				res.status(500).json({ success: false, message: "Internal server error" });
			}
		});

		this.router.post('/reset-password', async (req, res) => {
			try {
				const { ccc_id, email, new_password } = req.body;
				if (!ccc_id || !email || !new_password) {
					await createLog('error', 'Password reset failed: Missing required fields', null);
					return res.status(400).json({
						success: false,
						message: "CCC ID, email and new password are required"
					});
				}

				const user = await User.findOne({
					where: { ccc_id, email },
					attributes: ['ccc_id', 'status'],
				});

				if (!user) {
					await createLog('error', `Password reset failed: No matching user for ${ccc_id} / ${email}`, null);
					return res.status(404).json({ success: false, message: "No matching user found" });
				}

				if (user.status === "pending_for_delete") {
					await createLog('error', `Password reset blocked: Account ${ccc_id} pending deletion`, ccc_id);
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. " +
							"Please contact your supervisor/administrator immediately.",
					});
				}

				if (user.status === "deleted") {
					await createLog('error', `Password reset blocked: Account ${ccc_id} already deleted`, ccc_id);
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}
				const hashedPassword = await bcrypt.hash(new_password, 10);
				await User.update({ password: hashedPassword }, { where: { ccc_id } });

				await createLog('update', `Password reset successful for user ${ccc_id}`, ccc_id);
				return res.json({ success: true, message: "Password reset successful" });

			} catch (err) {
				console.error(err);
				await createLog('error', `Password reset exception: ${err.message}`, req.body.ccc_id || null);
				res.status(500).json({ success: false, message: "Internal server error" });
			}
		});

		this.router.post("/upload-proof", upload.single("file"), async (req, res) => {
			try {
				if (!req.file) {
					return res.status(400).json({ success: false, message: "No file provided" });
				}
				const result = cloudinary.uploader.upload_stream(
					{ folder: "ccc-ojt-proofs", resource_type: "image" },
					async (error, result) => {
						if (error) {
							return res.status(500).json({ success: false, message: "Upload failed" });
						}
						return res.json({ success: true, url: result.secure_url });
					}
				);
				const stream = result;
				stream.end(req.file.buffer);

			} catch (err) {
				res.status(500).json({ success: false, message: "Upload failed" });
			}
		});

		this.router.post("/get-schedules-with-details", async (req, res) => {
			try {
				const { ccc_id, startDate, endDate } = req.body;
				if (!ccc_id) {
					return res.status(400).json({
						success: false,
						message: "ccc_id is required",
					});
				}
				const user = await User.findOne({where: { ccc_id }});
				if (!user) {
					return res.status(400).json({
						success: false,
						message: "Student not found.",
					});
				}
				const schedules = await Schedule.findAll({
					where: {
						ccc_id,
						...(startDate && endDate
							? {
								date: {
									[Op.between]: [startDate, endDate],
								},
							}
							: {}),
					},
					order: [["date", "ASC"]],
				});

				if (!schedules.length) {
					return res.json({ success: true, data: [] });
				}

				const keys = schedules.map((s) => {
					const d = new Date(s.date);
					const formatted =
						d.getFullYear().toString() +
						String(d.getMonth() + 1).padStart(2, "0") +
						String(d.getDate()).padStart(2, "0");

					return formatted + s.ccc_id;
				});

				const [activities, summaries] = await Promise.all([
					ActivityRecord.findAll({
						where: {
							schedule_record_date: {
								[Op.in]: keys,
							},
						},
					}),
					Summary.findAll({
						where: {
							schedule_record_date: {
								[Op.in]: keys,
							},
						},
					}),
				]);

				const activityMap = {};
				activities.forEach((a) => {
					if (!activityMap[a.schedule_record_date]) {
						activityMap[a.schedule_record_date] = [];
					}
					activityMap[a.schedule_record_date].push(a.image_url);
				});

				const summaryMap = {};
				summaries.forEach((s) => {
					summaryMap[s.schedule_record_date] = s.summary_text;
				});

				const data = schedules.map((s) => {
					const d = new Date(s.date);
					const formatted =
						d.getFullYear().toString() +
						String(d.getMonth() + 1).padStart(2, "0") +
						String(d.getDate()).padStart(2, "0");

					const key = formatted + s.ccc_id;
					return {
						ccc_id: s.ccc_id,
						date: s.date,
						time_in: s.time_in,
						time_out: s.time_out,
						proof_in: s.proof_in,
						proof_out: s.proof_out,
						isAcceptedEarly: s.isAcceptedEarly,
						isAcceptedWorkFromHome: s.isAcceptedWorkFromHome,
						isWorkFromHome: s.isWorkFromHome,

						activities: activityMap[key] || [],
						summary_text: summaryMap[key] || null,
					};
				});
				return res.json({
					success: true,
					data,
					full_name: user.first_name + " " + user.middle_name + " " + user.last_name,
					course: user.course
				});
			} catch (err) {
				console.error("Fetch schedules failed:", err);
				return res.status(500).json({
					success: false,
					message: "Failed to fetch schedules",
				});
			}
		});

		this.router.post("/update-office", async (req, res) => {
			try {
				const {
					ccc_id,
					office_name,
					time_in_start,
					time_in_start_wfh,
					time_in_end,
					time_out_cap,
					allow_weekend,
				} = req.body;

				if (
					!ccc_id ||
					!office_name ||
					!time_in_start ||
					!time_in_start_wfh ||
					!time_in_end ||
					!time_out_cap
				) {
					return res.status(400).json({
						success: false,
						message:
							"Missing required fields: ccc_id, office_name, time fields",
					});
				}

				const isValidTime = (t) => /^([01]\d|2[0-3]):([0-5]\d)(:[0-5]\d)?$/.test(t);

				if (
					!isValidTime(time_in_start) ||
					!isValidTime(time_in_start_wfh) ||
					!isValidTime(time_in_end) ||
					!isValidTime(time_out_cap)
				) {
					return res.status(400).json({
						success: false,
						message: "Invalid time format. Use HH:mm or HH:mm:ss",
					});
				}

				const user = await User.findOne({
					where: { ccc_id },
				});

				if (!user || (user.role !== "supervisor" && user.role !== "admin")) {
					return res.status(403).json({
						success: false,
						message: "Unauthorized. Only supervisors or admins can update office.",
					});
				}

				const office = await Office.findOne({
					where: { id: user.office_id },
				});

				if (!office) {
					return res.status(404).json({
						success: false,
						message: "Office not found.",
					});
				}

				await Office.update(
					{
						office_name: office_name.trim(),
						time_in_start,
						time_in_start_wfh,
						time_in_end,
						time_out_cap,
						allow_weekend: !!allow_weekend,
					},
					{ where: { id: office.id } }
				);
				await createLog(
					"update",
					`Office settings updated by ${ccc_id}`,
					ccc_id
				);
				return res.json({
					success: true,
					message: "Office updated successfully.",
					office: {
						id: office.id,
						office_name,
						time_in_start,
						time_in_start_wfh,
						time_in_end,
						time_out_cap,
						allow_weekend: !!allow_weekend,
					},
				});
			} catch (err) {
				console.error("Update office failed:", err);
				return res.status(500).json({
					success: false,
					message: "Failed to update office.",
				});
			}
		});

		// POST /office/set-location
		// Updates the office latitude/longitude for the supervisor's office.
		// Only supervisors and admins may call this endpoint.
		this.router.post("/set-location", async (req, res) => {
			try {
				const { ccc_id, latitude, longitude } = req.body;
				if (!ccc_id || latitude === undefined || longitude === undefined) {
					return res.status(400).json({
						success: false,
						message: "Missing required fields: ccc_id, latitude, longitude",
					});
				}

				const lat = parseFloat(latitude);
				const lng = parseFloat(longitude);

				if (isNaN(lat) || lat < -90 || lat > 90) {
					return res.status(400).json({
						success: false,
						message: "Invalid latitude. Must be a number between -90 and 90.",
					});
				}

				if (isNaN(lng) || lng < -180 || lng > 180) {
					return res.status(400).json({
						success: false,
						message: "Invalid longitude. Must be a number between -180 and 180.",
					});
				}

				const supervisor = await User.findOne({
					where: {
						ccc_id,
						role: "supervisor"
					},
				});

				if (!supervisor) {
					return res.status(403).json({
						success: false,
						message: "Unauthorized. Only supervisors or admins can set the office location.",
					});
				}

				const office = await Office.findOne({
					where: { id: supervisor.office_id },
				});

				if (!office) {
					return res.status(404).json({
						success: false,
						message: "Office not found for this supervisor.",
					});
				}
				await Office.update({ latitude: lat, longitude: lng }, { where: { id: office.id } });
				await createLog(
					"update",
					`Office location updated to (${lat}, ${lng}) by ${ccc_id}`,
					ccc_id
				);
				return res.json({
					success: true,
					message: "Office location updated successfully.",
					office: {
						id: office.id,
						latitude: office.latitude,
						longitude: office.longitude,
					},
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({
					success: false,
					message: "Failed to update office location.",
				});
			}
		});

		this.router.post("/login", async (req, res) => {
			try {
				const { identifier, password } = req.body;
				const userAgent = req.headers["user-agent"] || "Unknown";
				const ip = req.ip || req.socket.remoteAddress || "Unknown";

				if (!identifier || !password) {
					return res.status(400).json({
						success: false,
						message: "Identifier and password are required",
					});
				}
				const superAdmin = await SuperAdmin.findOne({
					where: {
						[Op.or]: [
							{ username: identifier },
							{ email: identifier },
						],
					},
				});
				if (superAdmin) {
					const isMatch = await bcrypt.compare(password, superAdmin.password);
					if (!isMatch) {
						return res.status(401).json({
							success: false,
							message: "Invalid credentials",
						});
					}
					return res.json({
						success: true,
						is_super_admin: true,
						super_admin: {
							id: superAdmin.id,
							username: superAdmin.username,
							email: superAdmin.email,
						},
					});
				}
				const isEmail = identifier.includes("@");
				const user = await User.findOne({
					where: isEmail ? { email: identifier } : { ccc_id: identifier },
				});
				if (!user) {
					return res.status(401).json({
						success: false,
						message: "Invalid credentials",
					});
				}

				const isMatch = await bcrypt.compare(password, user.password);
				if (!isMatch) {
					return res.status(401).json({
						success: false,
						message: "Invalid credentials",
					});
				}

				if (user.status === "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. Please contact your supervisor/administrator immediately.",
					});
				}

				if (user.status === "deleted") {
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}

				const office = await Office.findOne({
					where: { office_id: user.office_id },
				});

				if (!office) {
					return res.status(401).json({
						success: false,
						message: "Office not found.",
					});
				}

				if (office.deactivated) {
					return res.status(403).json({
						success: false,
						message: "Your office has been deactivated. Please contact the system administrator.",
					});
				}

				const schoolYear = await SchoolYear.findOne({
					where: {
						office_id: office.office_id,
					},
				});

				if (!schoolYear) {
					return res.status(401).json({
						success: false,
						message: "School year not found.",
					});
				}

				// ========== AUTO-BACKUP ON FIRST DAY OF MONTH ==========
				const today = new Date();
				if (today.getDate() === 1) {
					const startOfDay = new Date(today.setHours(0, 0, 0, 0));
					const endOfDay = new Date(today.setHours(23, 59, 59, 999));

					const existingBackup = await OfficeBackup.findOne({
						where: {
							office_id: office.office_id,
							backup_by_superadmin: true,
							createdAt: { [Op.between]: [startOfDay, endOfDay] }
						}
					});

					if (!existingBackup) {
						try {
							const { payload, users, backed_up_at } = await buildOfficeBackupPayload(office.office_id);
							if (process.env.BACKUP_SECRET) {
								const integrity_hash = CryptoJS.HmacSHA256(stringify(payload), process.env.BACKUP_SECRET).toString(CryptoJS.enc.Hex);
								const lastBackup = await OfficeBackup.findOne({ where: { office_id: office.office_id }, order: [["version", "DESC"]] });
								const nextVersion = lastBackup ? lastBackup.version + 1 : 1;
								const unique_id = `SA_${formatDateId()}_${office.office_id}`;

								await OfficeBackup.create({
									unique_id,
									office_id: office.office_id,
									version: nextVersion,
									json_backup: { integrity_hash, payload },
									backup_by_superadmin: true
								});
								await createLog("info", `Auto-backup created for office ${office.office_id} on first day of month (user ${user.ccc_id})`, user.ccc_id);
								await createSuperAdminLog(
									"backup",
									`Auto-backup triggered by user ${user.ccc_id} for office ${office.office_id} on first day of month. Backup ID: ${unique_id}, version: ${nextVersion}`
								);
							} else {
								console.error("BACKUP_SECRET missing - auto-backup skipped for office", office.office_id);
							}
						} catch (backupErr) {
							console.error("Auto-backup failed on login:", backupErr);
						}
					}
				}
				// ========== END AUTO-BACKUP ==========

				await createLog(
					"info",
					`User ${user.ccc_id} (${user.role}) logged in from IP ${ip} (${userAgent})`,
					user.ccc_id
				);

				res.json({
					success: true,
					is_super_admin: false,
					user: {
						ccc_id: user.ccc_id,
						first_name: user.first_name,
						middle_name: user.middle_name,
						last_name: user.last_name,
						role: user.role,
						email: user.email,
						profile_link: user.profile_link,
						course: user.course,
						isAdmin: user.isAdmin,
						target_hours: user.target_hours,

						office_id: office.office_id,
						office_name: office.office_name,

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
				res.status(500).json({ success: false, message: "Server error" });
			}
		});

		this.router.get("/me/:ccc_id", async (req, res) => {
			try {
				const { ccc_id } = req.params;
				const user = await User.findOne({ where: { ccc_id } });
				if (!user) return res.status(404).json({ success: false });
				if (user.status === "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. " +
							"Please contact your supervisor/administrator immediately.",
					});
				}
				if (user.status === "deleted") {
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}
				const office = await Office.findOne({ where: { office_id: user.office_id } });
				const schoolYear = await SchoolYear.findOne({where: {office_id: office.office_id}});
				return res.json({
					success: true,
					user: {
						ccc_id: user.ccc_id,
						email: user.email,
						first_name: user.first_name,
						middle_name: user.middle_name,
						last_name: user.last_name,
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
						allow_weekend: office.allow_weekend
					},
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({ success: false });
			}
		});

		this.router.post("/register-supervisor", async (req, res) => {
			try {
				const {
					supervisor_ccc_id,
					first_name,
					middle_name,
					last_name,
					ccc_id,
					custom_id,
					email,
					password,
					office_id,
				} = req.body;

				if (!first_name || !last_name || !ccc_id || !custom_id || !email || !password) {
					return res.status(400).json({
						success: false,
						message: "Missing required fields",
					});
				}

				const nameRegex = /^[a-zA-ZñÑ\s\-']+$/;

				if (first_name.trim().length < 2 || !nameRegex.test(first_name.trim())) {
					return res.status(400).json({
						success: false,
						message: "Invalid first name. Use letters only, minimum 2 characters.",
					});
				}

				if (last_name.trim().length < 2 || !nameRegex.test(last_name.trim())) {
					return res.status(400).json({
						success: false,
						message: "Invalid last name. Use letters only, minimum 2 characters.",
					});
				}

				if (middle_name && middle_name.trim().length > 0 && !nameRegex.test(middle_name.trim())) {
					return res.status(400).json({
						success: false,
						message: "Invalid middle name. Use letters only.",
					});
				}

				if (ccc_id.trim().length < 3) {
					return res.status(400).json({
						success: false,
						message: "CCC ID must be at least 3 characters.",
					});
				}

				if (custom_id.trim().length < 2) {
					return res.status(400).json({
						success: false,
						message: "Custom ID must be at least 2 characters.",
					});
				}

				if (password.length < 6) {
					return res.status(400).json({
						success: false,
						message: "Password must be at least 6 characters.",
					});
				}

				const existingUser = await User.findOne({
					where: {
						[Op.or]: [
							{ ccc_id: ccc_id.trim() },
							{ email: email.trim() },
							{ custom_id: custom_id.trim() },
						],
					},
				});

				if (existingUser) {
					let conflictField = "User";
					if (existingUser.ccc_id === ccc_id.trim()) conflictField = "CCC ID";
					else if (existingUser.email === email.trim()) conflictField = "Email";
					else if (existingUser.custom_id === custom_id.trim()) conflictField = "Custom ID";

					return res.status(409).json({
						success: false,
						message: `${conflictField} already exists`,
					});
				}

				let parentSupervisor = null;
				let inheritedUsers = [];

				if (supervisor_ccc_id) {
					parentSupervisor = await User.findOne({
						where: { ccc_id: supervisor_ccc_id, role: "supervisor" },
					});

					if (!parentSupervisor) {
						return res.status(403).json({
							success: false,
							message: "Invalid supervisor",
						});
					}

					const supervisorLink = await SupervisorUser.findOne({
						where: { ccc_id: supervisor_ccc_id },
					});

					if (supervisorLink) {
						inheritedUsers = supervisorLink.all_users;
					}
				}

				const resolvedOfficeId = (supervisor_ccc_id && parentSupervisor)
					? parentSupervisor.office_id
					: office_id;

				const office = await Office.findOne({
					where: { office_id: resolvedOfficeId },
				});

				if (!office) {
					return res.status(404).json({
						success: false,
						message: "Office not found.",
					});
				}

				const school_year = await SchoolYear.findOne({
					where: { office_id: office.office_id },
				});

				if (!school_year) {
					return res.status(403).json({
						success: false,
						message: "School year not found.",
					});
				}

				const hashedPassword = await bcrypt.hash(password, 10);
				const supervisor = await User.create({
					first_name: first_name.trim(),
					middle_name: middle_name ? middle_name.trim() : null,
					last_name: last_name.trim(),
					ccc_id: ccc_id.trim(),
					custom_id: custom_id.trim(),
					email: email.trim(),
					password: hashedPassword,
					role: "supervisor",
					course: "",
					office_id: resolvedOfficeId,
					current_sy: school_year.current_sy + school_year.current_iteration - 1,
				});

				await SupervisorUser.create({
					ccc_id: supervisor.ccc_id,
					all_users: [...inheritedUsers],
				});

				await createLog(
					"create",
					`Supervisor account created: ${first_name.trim()} ${last_name.trim()}`,
					supervisor_ccc_id
				);

				return res.json({
					success: true,
					supervisor: {
						id: supervisor.id,
						first_name: supervisor.first_name,
						last_name: supervisor.last_name,
						ccc_id: supervisor.ccc_id,
						custom_id: supervisor.custom_id,
						email: supervisor.email,
					},
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({
					success: false,
					message: "Failed to create supervisor account",
				});
			}
		});

		this.router.post("/register-student", async (req, res) => {
			try {
				const {
					supervisor_ccc_id,
					first_name,
					middle_name,
					last_name,
					ccc_id,
					custom_id,
					email,
					course,
					target_hours,
					password,
				} = req.body;

				if (!supervisor_ccc_id || !first_name || !last_name || !ccc_id || !custom_id || !email || !password) {
					return res.status(400).json({
						success: false,
						message: "Missing required fields",
					});
				}
				const nameRegex = /^[a-zA-ZñÑ\s\-']+$/;

				if (first_name.trim().length < 2 || !nameRegex.test(first_name.trim())) {
					return res.status(400).json({
						success: false,
						message: "Invalid first name. Use letters only, minimum 2 characters.",
					});
				}

				if (last_name.trim().length < 2 || !nameRegex.test(last_name.trim())) {
					return res.status(400).json({
						success: false,
						message: "Invalid last name. Use letters only, minimum 2 characters.",
					});
				}

				if (middle_name && middle_name.trim().length > 0 && !nameRegex.test(middle_name.trim())) {
					return res.status(400).json({
						success: false,
						message: "Invalid middle name. Use letters only.",
					});
				}

				if (ccc_id.trim().length < 3) {
					return res.status(400).json({
						success: false,
						message: "CCC ID must be at least 3 characters.",
					});
				}

				if (custom_id.trim().length < 2) {
					return res.status(400).json({
						success: false,
						message: "Custom ID must be at least 2 characters.",
					});
				}

				if (!course || course.trim().length < 2) {
					return res.status(400).json({
						success: false,
						message: "Course is required.",
					});
				}

				const parsedHours = parseInt(target_hours, 10);
				if (isNaN(parsedHours) || parsedHours < 400 || parsedHours > 800) {
					return res.status(400).json({
						success: false,
						message: "Target hours must be between 400 and 800.",
					});
				}

				if (password.length < 6) {
					return res.status(400).json({
						success: false,
						message: "Password must be at least 6 characters.",
					});
				}

				const supervisor = await User.findOne({
					where: { ccc_id: supervisor_ccc_id, role: "supervisor" },
				});

				if (!supervisor) {
					return res.status(403).json({
						success: false,
						message: "Invalid supervisor",
					});
				}

				const existingUser = await User.findOne({
					where: {
						[Op.or]: [
							{ ccc_id: ccc_id.trim() },
							{ email: email.trim() },
							{ custom_id: custom_id.trim() },
						],
					},
				});

				if (existingUser) {
					let conflictField = "User";
					if (existingUser.ccc_id === ccc_id.trim()) conflictField = "CCC ID";
					else if (existingUser.email === email.trim()) conflictField = "Email";
					else if (existingUser.custom_id === custom_id.trim()) conflictField = "Custom ID";

					return res.status(409).json({
						success: false,
						message: `${conflictField} already exists`,
					});
				}

				const school_year = await SchoolYear.findOne({
					where: { office_id: supervisor.office_id },
				});

				if (!school_year) {
					return res.status(403).json({
						success: false,
						message: "School year not found",
					});
				}

				const hashedPassword = await bcrypt.hash(password, 10);
				const student = await User.create({
					first_name: first_name.trim(),
					middle_name: middle_name ? middle_name.trim() : null,
					last_name: last_name.trim(),
					ccc_id: ccc_id.trim(),
					custom_id: custom_id.trim(),
					email: email.trim(),
					course: course.trim(),
					target_hours: parsedHours,
					password: hashedPassword,
					role: "student",
					office_id: supervisor.office_id,
					current_sy: school_year.current_sy + school_year.current_iteration - 1,
				});

				await createLog(
					"create",
					`Student account created: ${first_name.trim()} ${last_name.trim()}`,
					supervisor_ccc_id
				);

				const supervisorLink = await SupervisorUser.findOne({
					where: { ccc_id: supervisor_ccc_id },
				});

				if (supervisorLink) {
					await supervisorLink.update({
						all_users: [...new Set([...supervisorLink.all_users, ccc_id.trim()])],
					});
				} else {
					await SupervisorUser.create({
						ccc_id: supervisor_ccc_id,
						all_users: [ccc_id.trim()],
					});
				}

				return res.json({
					success: true,
					student: {
						id: student.id,
						first_name: student.first_name,
						last_name: student.last_name,
						ccc_id: student.ccc_id,
						custom_id: student.custom_id,
						email: student.email,
					},
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({
					success: false,
					message: "Failed to create student account",
				});
			}
		});

		this.router.post("/register-admin", async (req, res) => {
			try {
				const {
					first_name,
					middle_name,
					last_name,
					ccc_id,
					custom_id,
					email,
					password,
					office_name,
					special_key,
				} = req.body;

				if (!first_name || !last_name || !ccc_id || !custom_id || !email || !password
					|| !office_name || !special_key) {
					return res.status(400).json({
						success: false,
						message: "Missing required fields",
					});
				}

				await SpecialKey.destroy({
					where: {
						expires_at: { [Op.lt]: new Date() },
					},
				});

				if (!special_key) {
					return res.status(400).json({
						success: false,
						message: "A special key is required to register an office.",
					});
				}

				const foundKey = await SpecialKey.findOne({
					where: { key: special_key, email: email },
				});
				if (!foundKey) {
					return res.status(403).json({
						success: false,
						message: "Invalid or expired special key, or key does not match the provided email.",
					});
				}
				if (!foundKey) {
					return res.status(403).json({
						success: false,
						message: "Invalid or expired special key.",
					});
				}
				const existingUser = await User.findOne({
					where: {
						[Op.or]: [{ ccc_id }, { email }, { custom_id }],
					},
				});

				if (existingUser) {
					let conflictField = "User";
					if (existingUser.ccc_id === ccc_id) conflictField = "CCC ID";
					else if (existingUser.email === email) conflictField = "Email";
					else if (existingUser.custom_id === custom_id) conflictField = "Custom ID";

					return res.status(409).json({
						success: false,
						message: `${conflictField} already exists`,
					});
				}

				const officeSlug = office_name
					.split(" ")
					.filter((w) => w.length > 2)
					.map((w) => w[0].toUpperCase())
					.join("");
				const office_id = `${officeSlug}-${Date.now()}`;

				const office = await Office.create({
					office_id,
					office_name,
					office_latitude: 0,
					office_longitude: 0,
					office_altitude: 0,
				});

				const currentYear = new Date().getFullYear();
				await SchoolYear.create({
					office_id: office.office_id,
					current_sy: currentYear,
					current_iteration: 1,
				});

				const hashedPassword = await bcrypt.hash(password, 10);
				const admin = await User.create({
					first_name,
					middle_name,
					last_name,
					ccc_id,
					custom_id,
					email,
					password: hashedPassword,
					role: "supervisor",
					course: "",
					target_hours: 0,
					office_id: office.office_id,
					isAdmin: true,
					current_sy: currentYear,
				});

				await SupervisorUser.create({
					ccc_id: admin.ccc_id,
					all_users: [],
				});

				await SpecialKey.destroy({ where: { key: special_key } });
				await createLog(
					"create",
					`Admin account created: ${first_name} ${last_name} (Office: ${office_name})`,
					ccc_id
				);
				await createSuperAdminLog(
					"create",
					`New admin registered: ${first_name} ${last_name} (${email}) with office "${office_name}"`
				);
				return res.json({
					success: true,
					admin: {
						id: admin.id,
						first_name: admin.first_name,
						last_name: admin.last_name,
						ccc_id: admin.ccc_id,
						custom_id: admin.custom_id,
						email: admin.email,
						office_id: office.office_id,
						office_name: office.office_name,
					},
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({
					success: false,
					message: "Failed to create admin account",
				});
			}
		});

		this.router.post("/update-student/:id", async (req, res) => {
			try {
				const studentId = req.params.id;
				const {
					first_name,
					middle_name,
					last_name,
					email,
					custom_id,
					course,
					profile_link,
					target_hours,
				} = req.body;

				if (!first_name || !last_name || !email || !custom_id) {
					return res.status(400).json({
						success: false,
						message: "Missing required fields: first_name, last_name, email, or custom_id",
					});
				}

				const nameRegex = /^[a-zA-ZñÑ\s\-']+$/;

				if (first_name.trim().length < 2 || !nameRegex.test(first_name.trim())) {
					return res.status(400).json({
						success: false,
						message: "Invalid first name. Use letters only, minimum 2 characters.",
					});
				}

				if (last_name.trim().length < 2 || !nameRegex.test(last_name.trim())) {
					return res.status(400).json({
						success: false,
						message: "Invalid last name. Use letters only, minimum 2 characters.",
					});
				}

				if (middle_name && middle_name.trim().length > 0 && !nameRegex.test(middle_name.trim())) {
					return res.status(400).json({
						success: false,
						message: "Invalid middle name. Use letters only.",
					});
				}

				if (custom_id.trim().length < 2) {
					return res.status(400).json({
						success: false,
						message: "Custom ID must be at least 2 characters.",
					});
				}

				if (target_hours !== undefined && target_hours !== null) {
					const parsedHours = parseInt(target_hours, 10);
					if (isNaN(parsedHours) || parsedHours < 400 || parsedHours > 800) {
						return res.status(400).json({
							success: false,
							message: "Target hours must be between 400 and 800.",
						});
					}
				}

				const student = await User.findOne({ where: { id: studentId, role: "student" } });
				if (!student) {
					return res.status(404).json({
						success: false,
						message: "Student not found",
					});
				}
				if (student.status === "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. Please contact your supervisor/administrator immediately.",
					});
				}
				if (student.status === "deleted") {
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}

				const existingEmail = await User.findOne({
					where: {
						email: email.trim(),
						id: { [Op.ne]: studentId },
					},
				});
				if (existingEmail) {
					return res.status(409).json({
						success: false,
						message: "Email already in use by another account",
					});
				}

				const existingCustomId = await User.findOne({
					where: {
						custom_id: custom_id.trim(),
						id: { [Op.ne]: studentId },
					},
				});
				if (existingCustomId) {
					return res.status(409).json({
						success: false,
						message: "Custom ID already in use by another account",
					});
				}

				await student.update({
					first_name: first_name.trim(),
					middle_name: middle_name ? middle_name.trim() : student.middle_name,
					last_name: last_name.trim(),
					email: email.trim(),
					custom_id: custom_id.trim(),
					course: course ?? student.course,
					target_hours: target_hours !== undefined && target_hours !== null
						? parseInt(target_hours, 10)
						: student.target_hours,
					profile_link: profile_link ?? student.profile_link,
				});

				await createLog(
					"update",
					`Student updated: ${first_name.trim()} ${last_name.trim()}`,
					student.ccc_id,
				);

				return res.json({
					success: true,
					student: {
						id: student.id,
						first_name: student.first_name,
						middle_name: student.middle_name,
						last_name: student.last_name,
						ccc_id: student.ccc_id,
						custom_id: student.custom_id,
						email: student.email,
						course: student.course,
						target_hours: student.target_hours,
					},
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({
					success: false,
					message: "Failed to update student",
				});
			}
		});

		this.router.post("/advance-iteration/:ccc_id", async (req, res) => {
			try {
				const { ccc_id } = req.params;

				const user = await User.findOne({ where: { ccc_id } });
				if (!user) {
					return res.status(404).json({
						success: false,
						message: "User not found",
					});
				}
				if (user.status === "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. Please contact your supervisor/administrator immediately.",
					});
				}
				if (user.status === "deleted") {
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}

				const schoolYear = await SchoolYear.findOne({ where: { office_id: user.office_id } });
				if (!schoolYear) {
					return res.status(500).json({
						success: false,
						message: "School year not configured",
					});
				}

				await SchoolYear.update({
					current_iteration: schoolYear.current_iteration + 1,
				}, { where: { office_id: user.office_id } });

				await createLog(
					'update',
					`Advanced to iteration ${schoolYear.current_iteration} for office ${user.office_id}`,
					ccc_id
				);
				await createSuperAdminLog(
					'update',
					`Iteration advanced from ${oldIteration} to ${newIteration} for office ${user.office_id} by user ${ccc_id}`
				);
				return res.json({
					success: true,
					current_sy: schoolYear.current_sy,
					current_iteration: schoolYear.current_iteration,
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({
					success: false,
					message: "Failed to advance iteration",
				});
			}
		});

		this.router.post("/update-user/:ccc_id", async (req, res) => {
			try {
				const cccId = req.params.ccc_id;
				const {
					first_name,
					middle_name,
					last_name,
					email,
					course,
					profile_link,
					target_hours,
				} = req.body;

				if (!first_name || !last_name || !email) {
					return res.status(400).json({
						success: false,
						message: "Missing required fields: first_name, last_name, or email",
					});
				}

				const student = await User.findOne({ where: { ccc_id: cccId } });
				if (!student) {
					return res.status(404).json({
						success: false,
						message: "Student not found",
					});
				}
				if (student.status === "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. Please contact your supervisor/administrator immediately.",
					});
				}
				if (student.status === "deleted") {
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}

				const existingEmail = await User.findOne({
					where: {
						email,
						ccc_id: { [Op.ne]: cccId },
					},
				});
				if (existingEmail) {
					return res.status(409).json({
						success: false,
						message: "Email already in use by another account",
					});
				}

				await student.update({
					first_name,
					middle_name: middle_name ?? student.middle_name,
					last_name,
					email,
					course: course ?? student.course,
					target_hours: target_hours ?? student.target_hours,
					profile_link
				});

				await createLog(
					"update",
					`User updated: ${first_name} ${last_name}`,
					student.ccc_id,
				);

				return res.json({
					success: true,
					student: {
						id: student.id,
						first_name: student.first_name,
						middle_name: student.middle_name,
						last_name: student.last_name,
						ccc_id: student.ccc_id,
						email: student.email,
						course: student.course,
						target_hours: student.target_hours,
					},
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({
					success: false,
					message: "Failed to update user",
				});
			}
		});


		this.router.post("/schedule", async (req, res) => {
			try {
				const { ccc_id, date, time_in, proof_in, isInOffice } = req.body;
				const schedule = await Schedule.create({
					ccc_id,
					date,
					time_in,
					proof_in,
					isWorkFromHome: !isInOffice
				});
				await createLog('timeIn', `Time in recorded for ${date}`, ccc_id);
				res.json({ success: true, schedule });
			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

		this.router.get("/fetch-all-ar/:schedule_record", async (req, res) => {
			try {
				const { schedule_record } = req.params;
				const activityRecords = await ActivityRecord.findAll({
					where: { schedule_record_date: schedule_record }
				});
				res.json({ success: true, activityRecords });
			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

		this.router.get("/fetch-summary/:schedule_record", async (req, res) => {
			try {
				const { schedule_record } = req.params;

				const summary = await Summary.findOne({
					where: { schedule_record_date: schedule_record }
				});

				res.json({
					success: true,
					id: summary ? summary.id : null,
					summary: summary ? summary.summary_text : ""
				});

			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

		this.router.post("/add-summary", async (req, res) => {
			try {
				const { schedule_record_date, summary_text } = req.body;

				let summary = await Summary.findOne({
					where: { schedule_record_date }
				});

				if (summary) {
					await Summary.update({ summary_text }, { where: { schedule_record_date } });
				} else {
					summary = await Summary.create({
						schedule_record_date,
						summary_text
					});
				}
				res.json({ success: true, summary });

			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

		this.router.delete("/delete-summary/:id", async (req, res) => {
			try {
				const { id } = req.params;
				await Summary.destroy({
					where: { id }
				});
				res.json({ success: true });
			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

		this.router.post("/add-ar", async (req, res) => {
			try {
				const { schedule_record_date, image_url, description } = req.body;
				const activityRecord = await ActivityRecord.create({
					schedule_record_date,
					image_url,
					description,
				});
				res.json({ success: true, activityRecord });
			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

		this.router.delete("/delete-ar/:id", async (req, res) => {
			try {
				const { id } = req.params;
				await ActivityRecord.destroy({ where: { id } });
				res.json({ success: true });
			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});


		this.router.post("/change-password", async (req, res) => {
			try {
				const { ccc_id, current_password, new_password } = req.body;

				if (!ccc_id || !current_password || !new_password) {
					return res.status(400).json({
						success: false,
						message: "Missing required fields",
					});
				}

				const user = await User.findOne({
					where: { ccc_id },
				});
				if (user.status === "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. " +
							"Please contact your supervisor/administrator immediately.",
					});
				}
				if (user.status === "deleted") {
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}

				if (!user) {
					return res.status(403).json({
						success: false,
						message: "User does not exist.",
					});
				}

				const isMatch = await bcrypt.compare(current_password, user.password);

				if (!isMatch) {
					return res.status(401).json({
						success: false,
						message: "Current password is incorrect.",
					});
				}

				const hashedPassword = await bcrypt.hash(new_password, 10);
				await User.update(
					{ password: hashedPassword },
					{ where: { ccc_id } }
				);

				await createLog('update', 'Password changed successfully', ccc_id);
				res.json({ success: true });
			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

		// Supervisor → can only set status to "pending_for_delete"
		// Admin      → can set status to "pending_for_delete", "deleted", or "active" (restore)
		this.router.post("/update-status/:id", async (req, res) => {
			try {
				const targetId = req.params.id;
				const { requester_ccc_id, status } = req.body;

				if (!requester_ccc_id || !status) {
					return res.status(400).json({
						success: false,
						message: "Missing required fields: requester_ccc_id, status",
					});
				}

				const allowedStatuses = ["active", "pending_for_delete", "deleted"];
				if (!allowedStatuses.includes(status)) {
					return res.status(400).json({
						success: false,
						message: `Invalid status. Must be one of: ${allowedStatuses.join(", ")}`,
					});
				}

				const requester = await User.findOne({
					where: { ccc_id: requester_ccc_id, role: "supervisor" },
				});

				if (!requester) {
					return res.status(403).json({
						success: false,
						message: "Unauthorized. Requester must be a supervisor.",
					});
				}

				if (requester.status === "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. Please contact your supervisor/administrator immediately.",
					});
				}
				if (requester.status === "deleted") {
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}

				const isAdmin = requester.isAdmin === true;

				if (!isAdmin && status !== "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "Only admins can set status to 'deleted' or restore to 'active'.",
					});
				}

				const target = await User.findOne({
					where: { id: targetId },
				});

				if (!target) {
					return res.status(404).json({
						success: false,
						message: "User not found.",
					});
				}

				if (target.office_id !== requester.office_id) {
					return res.status(403).json({
						success: false,
						message: "You can only manage users within your own office.",
					});
				}

				if (target.ccc_id === requester_ccc_id) {
					return res.status(403).json({
						success: false,
						message: "You cannot change your own account status.",
					});
				}

				if (!isAdmin && target.role === "supervisor") {
					return res.status(403).json({
						success: false,
						message: "Supervisors cannot delete other supervisors.",
					});
				}

				const previousStatus = target.status;
				await target.update({ status });

				const actionLabel =
					status === "pending_for_delete" ? "marked for deletion"
						: status === "deleted" ? "permanently deleted"
							: "restored to active";

				await createLog(
					"update",
					`User ${target.ccc_id} (${target.first_name} ${target.last_name}) ${actionLabel} by ${requester_ccc_id}`,
					requester_ccc_id
				);

				return res.json({
					success: true,
					message: `User ${actionLabel} successfully.`,
					user: {
						id: target.id,
						ccc_id: target.ccc_id,
						status: target.status,
						previous_status: previousStatus,
					},
				});
			} catch (err) {
				console.error(err);
				return res.status(500).json({
					success: false,
					message: "Failed to update user status.",
				});
			}
		});

		this.router.post("/update-profile", async (req, res) => {
			try {
				const { ccc_id, image_profile } = req.body;

				const user = await User.findOne({
					where: { ccc_id: ccc_id },
				});
				if (!user) {
					return res.status(403).json({
						success: false,
						message: "User does not exists.",
					});
				}
				if (user.status === "pending_for_delete") {
					return res.status(403).json({
						success: false,
						message: "This account is pending for deletion. Please contact your supervisor/administrator immediately.",
					});
				}
				if (user.status === "deleted") {
					return res.status(403).json({
						success: false,
						message: "This account has been deleted.",
					});
				}

				User.update({
					profile_link: image_profile
				}, { where: { ccc_id } })

				await createLog('update', 'Profile picture updated', ccc_id);
				res.json({ success: true, user });

			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

		this.router.post("/schedule/sync", async (req, res) => {
			/*
				Expected payload:
				{
					ccc_id: "123",
					schedules: [
						{ date, time_in, time_out, proof_in, proof_out }
					]
				}
			*/
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

				res.json({ success: true, message: "Schedules synced" });
			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

		this.router.post("/schedule/add", async (req, res) => {
			try {
				const {
					ccc_id,
					date,
					time_in,
					time_out,
					isInOffice,
					isAcceptedEarly,
					isAcceptedWorkFromHome,
				} = req.body;

				if (!ccc_id || !date || !time_in) {
					return res.status(400).json({ success: false, message: "ccc_id, date, and time_in are required" });
				}

				const existingSchedule = await Schedule.findOne({
					where: {
						ccc_id,
						date,
					},
				});

				if (existingSchedule) {
					return res.status(409).json({
						success: false,
						message: "A schedule already exists for this date.",
					});
				}

				const newRecord = await Schedule.create({
					ccc_id,
					date,
					time_in,
					time_out: time_out ?? null,
					isWorkFromHome: !isInOffice,
					isAcceptedEarly,
					isAcceptedWorkFromHome,
				});
				await createLog('create', `Schedule manually added for ${date}`, ccc_id);

				res.json({ success: true, message: "Schedule added", schedule: newRecord });
			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false, message: err.message });
			}
		});

		this.router.post("/schedule/update", async (req, res) => {
			try {
				const {
					id,
					time_in,
					time_out,
					isInOffice,
					isAcceptedEarly,
					isAcceptedWorkFromHome,
				} = req.body;

				if (!id) {
					return res.status(400).json({
						success: false,
						message: "Schedule ID is required",
					});
				}

				const [updated] = await Schedule.update(
					{
						time_in,
						time_out: time_out ?? null,
						isWorkFromHome: !isInOffice,
						isAcceptedEarly,
						isAcceptedWorkFromHome,
					},
					{ where: { id } }
				);

				if (!updated) {
					return res.status(404).json({ success: false, message: "Schedule not found" });
				}
				await createLog('update', 'Schedule updated', null);
				res.json({
					success: true,
					message: "Schedule updated successfully",
				});
			} catch (err) {
				console.error(err);
				res.status(500).json({
					success: false,
					message: "Failed to update schedule",
				});
			}
		});

		this.router.delete("/schedule/:id", async (req, res) => {
			try {
				const { id } = req.params;

				if (!id) {
					return res.status(400).json({
						success: false,
						message: "Schedule ID is required",
					});
				}

				const deleted = await Schedule.destroy({
					where: { id },
				});
				if (!deleted) {
					return res.status(404).json({
						success: false,
						message: "Schedule not found",
					});
				}
				await createLog('delete', 'Schedule deleted', null);
				res.json({
					success: true,
					message: "Schedule deleted successfully",
				});
			} catch (err) {
				console.error(err);
				res.status(500).json({
					success: false,
					message: "Failed to delete schedule",
				});
			}
		});
	}

	putRouter() {
		this.router.put("/schedule/timeout", async (req, res) => {
			try {
				const { id, ccc_id, date, time_out, proof_out } = req.body;

				const updated = await Schedule.update(
					{ time_out, proof_out },
					{ where: { ccc_id, date, id } }
				);
				await createLog('timeOut', `Time out recorded for ${date}`, ccc_id);
				res.json({ success: true, updated });
			} catch (err) {
				console.error(err);
				res.status(400).json({ success: false });
			}
		});

	}
}

module.exports = new UserRouter().router;
