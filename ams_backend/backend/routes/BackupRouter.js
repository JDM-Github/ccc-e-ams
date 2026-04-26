// Author: JDM
require("dotenv").config();
const express = require("express");
const {
	User,
	Schedule,
	Summary,
	SupervisorUser,
	Office,
	ActivityRecord,
	Log,
	SchoolYear,
	SuperAdminLog,
	OfficeBackup,
} = require("../models/Models");
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

/**
 * Strips Sequelize-managed fields so we never re-insert auto-generated PKs,
 * timestamps, etc. when re-creating rows from a backup.
 */
const SEQUELIZE_AUTO_FIELDS = ["id", "createdAt", "updatedAt"];
const strip = (obj) => {
	const copy = { ...obj };
	SEQUELIZE_AUTO_FIELDS.forEach((k) => delete copy[k]);
	return copy;
};

/**
 * Builds the schedule_record_date key (YYYYMMDD + ccc_id).
 *
 * Splits the DATEONLY string directly instead of using new Date() to avoid
 * timezone issues. new Date("2026-01-15") parses as UTC midnight, and
 * getDate() in a UTC- timezone would return the previous day — wrong key,
 * missed records.
 */
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
	const minutes = String(d.getMinutes()).padStart(2, "0");
	const seconds = String(d.getSeconds()).padStart(2, "0");

	return `${year}${month}${day}${hours}${minutes}${seconds}`;
};
// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────

class BackupRouter {
	constructor() {
		this.router = express.Router();
		this.getRouter();
		this.postRouter();
	}

	getRouter() {
		/**
		 * GET /backup/office/:office_id
		 *
		 * Creates a full backup snapshot of the office and ALL its related data,
		 * then stores it in the OfficeBackup table as a single JSON blob.
		 *
		 * The integrity_hash is computed over the payload and stored INSIDE
		 * json_backup alongside the payload — no extra DB columns needed.
		 *
		 * Returns a lightweight summary. The client must use the returned
		 * backup object when calling POST /backup/restore.
		 * The full payload is NEVER accepted from the client on restore.
		 *
		 * json_backup shape stored in DB:
		 * {
		 *   integrity_hash: string,
		 *   payload: {
		 *     meta:        { office_id, backed_up_at }
		 *     office:      { ...officeRow }
		 *     school_year: { ...schoolYearRow } | null
		 *     users: [
		 *       {
		 *         ...userRow,
		 *         supervisor_record: { ...supervisorUserRow } | null,
		 *         schedules: [
		 *           {
		 *             ...scheduleRow,
		 *             activities: [ ...activityRecordRows ],
		 *             summaries:  [ ...summaryRows ]
		 *           }
		 *         ]
		 *       }
		 *     ],
		 *     logs: [ ...logRows ]
		 *   }
		 * }
		 */
		this.router.get("/office/:office_id", async (req, res) => {
			
			try {
				if (!process.env.BACKUP_SECRET) {
					throw new Error(
						"[BackupRouter] BACKUP_SECRET environment variable is not set. " +
						"Add it to your .env file."
					);
				}

				const { office_id } = req.params;

				// ── 1. Office ────────────────────────────────────────────────────
				const office = await Office.findOne({ where: { office_id }, raw: true });
				if (!office) {
					return res.status(404).json({
						success: false,
						message: `Office with id "${office_id}" not found.`,
					});
				}

				// ── 2. SchoolYear ────────────────────────────────────────────────
				const school_year = await SchoolYear.findOne({ where: { office_id }, raw: true });

				// ── 3. Users ─────────────────────────────────────────────────────
				const userRows = await User.findAll({ where: { office_id }, raw: true });
				const cccIds = userRows.map((u) => u.ccc_id);

				// ── 4. SupervisorUser records ────────────────────────────────────
				// Guard: Sequelize generates invalid SQL for IN ([]) on some versions.
				const supervisorRows =
					cccIds.length > 0
						? await SupervisorUser.findAll({ where: { ccc_id: cccIds }, raw: true })
						: [];

				const supervisorMap = {};
				supervisorRows.forEach((s) => (supervisorMap[s.ccc_id] = s));

				// ── 5. Schedules ─────────────────────────────────────────────────
				const scheduleRows =
					cccIds.length > 0
						? await Schedule.findAll({ where: { ccc_id: cccIds }, raw: true })
						: [];

				// ── 6. ActivityRecords & Summaries ───────────────────────────────
				const scheduleRecordDates = scheduleRows.map((s) =>
					buildRecordDate(s.date, s.ccc_id)
				);

				const [activityRows, summaryRows] =
					scheduleRecordDates.length > 0
						? await Promise.all([
							ActivityRecord.findAll({
								where: { schedule_record_date: scheduleRecordDates },
								raw: true,
							}),
							Summary.findAll({
								where: { schedule_record_date: scheduleRecordDates },
								raw: true,
							}),
						])
						: [[], []];

				// Index by schedule_record_date for O(1) lookup
				const activityMap = {};
				activityRows.forEach((a) => {
					(activityMap[a.schedule_record_date] ??= []).push(a);
				});
				const summaryMap = {};
				summaryRows.forEach((s) => {
					(summaryMap[s.schedule_record_date] ??= []).push(s);
				});

				// ── 7. Logs ──────────────────────────────────────────────────────
				const logs =
					cccIds.length > 0
						? await Log.findAll({ where: { user_ccc_id: cccIds }, raw: true })
						: [];

				// ── 8. Assemble ──────────────────────────────────────────────────
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

				// ── 9. Sign the payload ──────────────────────────────────────────
				const backed_up_at = new Date().toISOString();
				const payload = {
					meta: { office_id, backed_up_at },
					office,
					school_year: school_year || null,
					users,
					logs,
				};

				const integrity_hash = CryptoJS.HmacSHA256(
					stringify(payload),
					process.env.BACKUP_SECRET
				).toString(CryptoJS.enc.Hex);

				// ── 10. Persist to OfficeBackup ──────────────────────────────────
				// integrity_hash lives INSIDE json_backup alongside the payload.
				// On restore the server reads this row — the client never supplies the data.
				const lastBackup = await OfficeBackup.findOne({
					where: { office_id },
					order: [["version", "DESC"]],
				});
				const nextVersion = lastBackup ? lastBackup.version + 1 : 1;

				const unique_id = formatDateId();
				const backupRow = await OfficeBackup.create({
					unique_id,
					office_id,
					version: nextVersion,
					json_backup: { integrity_hash, payload },
				});
				

				await createSuperAdminLog(
					"backup",
					`Backup #${backupRow.id} (v${nextVersion}) created for office "${office.office_name}" (${office_id}) with ${users.length} users.`
				);

				return res.json({
					success: true,
					message: `Backup for office "${office_id}" completed successfully.`,
					backup: {
						unique_id: unique_id,
						version: nextVersion,
						office_id,
						backed_up_at,
					},
				});
			} catch (err) {
				console.error("[BackupRouter] GET /office/:office_id →", err);
				return res.status(500).json({
					success: false,
					message: "Internal server error while creating backup.",
				});
			}
		});

		/**
		 * GET /backup/list/:office_id
		 *
		 * Returns all stored backups for an office so the client can pick
		 * which one to pass to POST /backup/restore.
		 */
		this.router.get("/list/:office_id", async (req, res) => {
			try {
				const { office_id } = req.params;

				const backups = await OfficeBackup.findAll({
					where: { office_id },
					attributes: ["id", "unique_id", "version", "office_id", "createdAt"],
					order: [["createdAt", "DESC"]],
					raw: true,
				});

				return res.json({ success: true, backups });
			} catch (err) {
				console.error("[BackupRouter] GET /list/:office_id →", err);
				return res.status(500).json({ success: false, message: "Internal server error." });
			}
		});
	}

	postRouter() {
		/**
		 * POST /backup/restore
		 *
		 * Body: { backup: { unique_id, office_id, version, backed_up_at } }
		 *
		 * The `backup` object is the exact JSON returned by GET /backup/office/:office_id.
		 * Only unique_id and office_id are used — the full payload is ALWAYS
		 * read from the DB, never trusted from the client.
		 *
		 * Restore strategy — wipe-then-insert inside a single transaction:
		 *
		 *   1. Accept only { backup } from the client.
		 *      Destructure unique_id and office_id from it.
		 *      The full payload is NEVER trusted from the client.
		 *   2. Load the OfficeBackup row from the DB by unique_id + office_id.
		 *   3. Re-verify the integrity_hash stored inside json_backup.
		 *   4. Inside a single transaction:
		 *        a. DELETE everything tied to the office in FK-safe order:
		 *             ActivityRecord → Summary → Schedule →
		 *             SupervisorUser → Log → User → SchoolYear → Office
		 *        b. INSERT everything from the backup in reverse FK order.
		 *        c. COMMIT — only at this point does anything change on disk.
		 *   5. If ANY step throws, the transaction rolls back automatically.
		 *      The DB is left exactly as it was before the restore started.
		 */
		this.router.post("/restore", async (req, res) => {
			if (!process.env.BACKUP_SECRET) {
				throw new Error(
					"[BackupRouter] BACKUP_SECRET environment variable is not set. " +
					"Add it to your .env file."
				);
			}

			const { backup } = req.body;

			// ── 1. Input validation ──────────────────────────────────────────
			if (!backup || typeof backup !== "object") {
				return res.status(400).json({
					success: false,
					message: "Body must contain { backup: { unique_id, office_id, ... } }.",
				});
			}

			const { unique_id, office_id } = backup;
			if (!unique_id || !office_id) {
				return res.status(400).json({
					success: false,
					message: "backup object must contain unique_id and office_id.",
				});
			}

			// ── 2. Load backup from DB — never from client ───────────────────
			// Also verifies office_id matches so one office can't restore
			// another office's backup.
			const backupRecord = await OfficeBackup.findOne({
				where: { unique_id, office_id },
				raw: true,
			});

			if (!backupRecord) {
				return res.status(404).json({
					success: false,
					message: `No backup found with unique_id "${unique_id}" for office "${office_id}".`,
				});
			}

			// ── 3. Re-verify integrity hash ──────────────────────────────────
			const { integrity_hash, payload } = backupRecord.json_backup;

			if (!integrity_hash || !payload) {
				return res.status(400).json({
					success: false,
					message: "Backup record is malformed. Missing integrity_hash or payload.",
				});
			}

			const expectedHash = CryptoJS.HmacSHA256(
				stringify(payload),
				process.env.BACKUP_SECRET
			).toString(CryptoJS.enc.Hex);

			if (expectedHash !== integrity_hash) {
				console.error(`[BackupRouter] Integrity check FAILED for backup "${unique_id}"`);
				return res.status(400).json({
					success: false,
					message: "Backup integrity check failed. The stored backup may be corrupted.",
				});
			}

			const { office, school_year, users = [], logs = [] } = payload;
			const sequelize = Office.sequelize;
			const t = await sequelize.transaction();

			try {
				// ── 4a. WIPE — delete in FK-safe order ───────────────────────
				const existingUsers = await User.findAll({
					where: { office_id },
					attributes: ["ccc_id"],
					raw: true,
					transaction: t,
				});
				const existingCccIds = existingUsers.map((u) => u.ccc_id);

				if (existingCccIds.length > 0) {
					const existingSchedules = await Schedule.findAll({
						where: { ccc_id: existingCccIds },
						attributes: ["date", "ccc_id"],
						raw: true,
						transaction: t,
					});

					const existingRecordDates = [
						...new Set(
							existingSchedules.map((s) => buildRecordDate(s.date, s.ccc_id))
						),
					];

					if (existingRecordDates.length > 0) {
						await ActivityRecord.destroy({
							where: { schedule_record_date: existingRecordDates },
							transaction: t,
						});
						await Summary.destroy({
							where: { schedule_record_date: existingRecordDates },
							transaction: t,
						});
					}

					await Schedule.destroy({ where: { ccc_id: existingCccIds }, transaction: t });
					await SupervisorUser.destroy({ where: { ccc_id: existingCccIds }, transaction: t });
					await Log.destroy({ where: { user_ccc_id: existingCccIds }, transaction: t });
				}

				await User.destroy({ where: { office_id }, transaction: t });
				await SchoolYear.destroy({ where: { office_id }, transaction: t });
				await Office.destroy({ where: { office_id }, transaction: t });

				// ── 4b. INSERT — re-create in reverse FK order ───────────────
				await Office.create(strip(office), { transaction: t });

				if (school_year) {
					await SchoolYear.create(
						strip({ ...school_year, office_id: office.office_id }),
						{ transaction: t }
					);
				}

				for (const userBackup of users) {
					const { supervisor_record, schedules = [], ...userRow } = userBackup;

					await User.create(strip(userRow), { transaction: t });

					if (supervisor_record) {
						await SupervisorUser.create(strip(supervisor_record), { transaction: t });
					}

					for (const scheduleBackup of schedules) {
						const { activities = [], summaries = [], ...scheduleRow } = scheduleBackup;

						await Schedule.create(strip(scheduleRow), { transaction: t });

						if (activities.length > 0) {
							await ActivityRecord.bulkCreate(
								activities.map((a) => strip(a)),
								{ transaction: t }
							);
						}

						if (summaries.length > 0) {
							await Summary.bulkCreate(
								summaries.map((s) => strip(s)),
								{ transaction: t }
							);
						}
					}
				}

				if (logs.length > 0) {
					await Log.bulkCreate(
						logs.map((l) => strip(l)),
						{ transaction: t }
					);
				}

				// ── 4c. COMMIT — only now does anything change on disk ───────
				await t.commit();

				await createSuperAdminLog(
					"restore",
					`Office "${office.office_name}" (${office_id}) restored from backup "${unique_id}" with ${users.length} users.`
				);

				return res.json({
					success: true,
					message: `Office "${office_id}" restored successfully from backup "${unique_id}".`,
				});
			} catch (err) {
				await t.rollback();
				console.error("[BackupRouter] POST /restore →", err);

				return res.status(500).json({
					success: false,
					message: "Restore failed. All changes have been rolled back. Your data is untouched.",
					error: err.message,
				});
			}
		});
	}
}

module.exports = new BackupRouter().router;