// Author: JDM
// Created on: 2026-04-13T04:22:50.726Z
// Updated: use attachProgress from progress.js (mirrors get-all-users pattern).
//          Schedule queries are automatically scoped to each student's
//          current_sy inside attachProgress.

const express = require("express");
const { Op } = require("sequelize");
const {
	sequelize,
	User,
	Schedule,
	Office,
	ActivityRecord,
	Log,
	SchoolYear,
	Summary,
	SuperAdminLog,
} = require("../models/Models");
const { attachProgress, computeProgress } = require("./utils/progress");

class DashboardRouter {

	constructor() {
		this.router = express.Router();
		this.getRouter();
		this.postRouter();
	}

	getRouter() {

		// ─────────────────────────────────────────────────────────────────────
		// STUDENT DASHBOARD  GET /dashboard/student/:ccc_id
		// ─────────────────────────────────────────────────────────────────────
		this.router.get("/student/:ccc_id", async (req, res) => {
			try {
				const { ccc_id } = req.params;

				// ── 1. Student profile + office info ──────────────────────────
				const student = await User.findOne({
					where: { ccc_id, status: "active" },
					attributes: [
						"first_name", "middle_name", "last_name",
						"ccc_id", "custom_id", "email",
						"role", "course", "profile_link",
						"target_hours", "isAdmin", "current_sy", "office_id",
					],
					include: [
						{
							model: Office,
							attributes: [
								"office_id", "office_name",
								"time_in_start", "time_in_start_wfh",
								"time_in_end", "time_out_cap",
								"allow_weekend",
							],
						},
					],
				});

				if (!student) {
					return res.status(404).json({ message: "Student not found." });
				}

				// ── 2. OJT progress via attachProgress ────────────────────────
				// Mirrors get-all-users: pass the student in an array, get back
				// the same shape with completed_hours / progress / is_done etc.
				const [studentWithProgress] = await attachProgress([student], student.current_sy);

				// ── 3. Recent schedules (last 7 with a time_out, same SY) ─────
				const sy = student.current_sy;
				const recentSchedules = await Schedule.findAll({
					where: {
						ccc_id,
						date: { [Op.between]: [`${sy}-01-01`, `${sy}-12-31`] },
						time_out: { [Op.ne]: null },
					},
					attributes: [
						"date", "time_in", "time_out",
						"isWorkFromHome", "isAcceptedWorkFromHome", "isAcceptedEarly",
					],
					order: [["date", "DESC"]],
					limit: 7,
				});

				// ── 4. Today's schedule entry (if any) ────────────────────────
				const today = new Date().toISOString().split("T")[0];
				const todaySchedule = await Schedule.findOne({
					where: { ccc_id, date: today },
				});

				// ── 5. Latest activity records ────────────────────────────────
				const recentActivities = await ActivityRecord.findAll({
					where: {
						schedule_record_date: { [Op.like]: `%${ccc_id}` },
					},
					order: [["createdAt", "DESC"]],
					limit: 5,
				});

				// ── 6. Latest summary ─────────────────────────────────────────
				const latestSummary = await Summary.findOne({
					where: {
						schedule_record_date: { [Op.like]: `%${ccc_id}` },
					},
					order: [["createdAt", "DESC"]],
				});

				// ── 7. Recent personal logs ───────────────────────────────────
				const recentLogs = await Log.findAll({
					where: { user_ccc_id: ccc_id },
					order: [["createdAt", "DESC"]],
					limit: 10,
				});

				return res.status(200).json({
					success: true,
					student: studentWithProgress,
					ojt_progress: {
						target_hours: student.target_hours,
						total_rendered_hours: studentWithProgress.completed_hours,
						remaining_hours: studentWithProgress.remaining_hours,
						progress_percentage: parseFloat(((studentWithProgress.progress ?? 0) * 100).toFixed(2)),
						total_days: studentWithProgress.total_schedules,
						is_done: studentWithProgress.is_done,
					},
					today_schedule: todaySchedule,
					recent_schedules: recentSchedules,
					recent_activities: recentActivities,
					latest_summary: latestSummary,
					recent_logs: recentLogs,
				});
			} catch (error) {
				console.error("Student dashboard error:", error);
				return res.status(500).json({ message: "Internal server error.", error: error.message });
			}
		});

		// ─────────────────────────────────────────────────────────────────────
		// OFFICE / SUPERVISOR DASHBOARD  GET /dashboard/office/:office_id
		// ─────────────────────────────────────────────────────────────────────
		this.router.get("/office/:office_id", async (req, res) => {
			try {
				const { office_id } = req.params;

				// ── 1. Office info ────────────────────────────────────────────
				const office = await Office.findOne({
					where: { office_id, deactivated: false },
				});

				if (!office) {
					return res.status(404).json({ message: "Office not found or deactivated." });
				}

				// ── 2. All active students under this office ──────────────────
				const students = await User.findAll({
					where: { office_id, role: "student", status: "active" },
					attributes: [
						"first_name", "middle_name", "last_name",
						"ccc_id", "custom_id", "email",
						"course", "profile_link", "target_hours", "current_sy",
					],
				});

				const ccc_ids = students.map((s) => s.ccc_id);

				// ── 3. Today's attendance snapshot ────────────────────────────
				const today = new Date().toISOString().split("T")[0];

				const todaySchedules = await Schedule.findAll({
					where: {
						ccc_id: { [Op.in]: ccc_ids },
						date: today,
					},
					attributes: [
						"ccc_id", "date", "time_in", "time_out",
						"isWorkFromHome", "isAcceptedEarly", "isAcceptedWorkFromHome",
						"proof_in", "proof_out",
					],
				});

				const todayMap = {};
				for (const entry of todaySchedules) {
					todayMap[entry.ccc_id] = entry;
				}

				// ── 4. OJT progress per student via attachProgress ────────────
				// Mirrors get-all-users supervisor path exactly.
				// attachProgress scopes each student's schedules to their own
				// current_sy so previous-year records are excluded.
				const studentsWithProgress = await attachProgress(students);

				const studentSummaries = studentsWithProgress.map((s) => ({
					...s,
					today_schedule: todayMap[s.ccc_id] ?? null,
				}));

				// ── 5. Attendance counts for today ────────────────────────────
				const presentToday = todaySchedules.length;
				const timedOutToday = todaySchedules.filter((s) => s.time_out !== null).length;
				const wfhToday = todaySchedules.filter((s) => s.isWorkFromHome).length;
				const absentToday = ccc_ids.length - presentToday;

				// ── 6. Current school year for this office ────────────────────
				const schoolYear = await SchoolYear.findOne({ where: { office_id } });

				// ── 7. Supervisors assigned to this office ────────────────────
				const supervisors = await User.findAll({
					where: { office_id, role: "supervisor", status: "active" },
					attributes: [
						"first_name", "middle_name", "last_name",
						"ccc_id", "email", "profile_link", "isAdmin",
					],
				});

				// ── 8. Recent office-wide logs ────────────────────────────────
				const recentLogs = await Log.findAll({
					where: { user_ccc_id: { [Op.in]: ccc_ids } },
					order: [["createdAt", "DESC"]],
					limit: 20,
				});

				return res.status(200).json({
					success: true,
					office,
					school_year: schoolYear,
					supervisors,
					attendance_today: {
						total_students: ccc_ids.length,
						present: presentToday,
						timed_out: timedOutToday,
						wfh: wfhToday,
						absent: absentToday,
					},
					students: studentSummaries,
					recent_logs: recentLogs,
				});
			} catch (error) {
				console.error("Office dashboard error:", error);
				return res.status(500).json({ message: "Internal server error.", error: error.message });
			}
		});

		// ─────────────────────────────────────────────────────────────────────
		// SUPER ADMIN DASHBOARD  GET /dashboard/superadmin
		// ─────────────────────────────────────────────────────────────────────
		this.router.get("/superadmin", async (req, res) => {
			try {

				// ── 1. Office stats ───────────────────────────────────────────
				const [totalOffices, activeOffices, deactivatedOffices] = await Promise.all([
					Office.count(),
					Office.count({ where: { deactivated: false } }),
					Office.count({ where: { deactivated: true } }),
				]);

				const officeList = await Office.findAll({
					attributes: [
						"office_id", "office_name",
						"office_latitude", "office_longitude",
						"deactivated", "allow_weekend",
						"time_in_start", "time_in_end",
					],
					order: [["office_name", "ASC"]],
				});

				// ── 2. User stats ─────────────────────────────────────────────
				const [
					totalUsers,
					activeStudents,
					activeSupervisors,
					pendingDeletion,
					softDeleted,
				] = await Promise.all([
					User.count({ where: { status: { [Op.ne]: "deleted" } } }),
					User.count({ where: { role: "student", status: "active" } }),
					User.count({ where: { role: "supervisor", status: "active" } }),
					User.count({ where: { status: "pending_for_delete" } }),
					User.count({ where: { status: "deleted" } }),
				]);

				// ── 3. Platform-wide OJT progress ────────────────────────────
				const completedScheduleCount = await Schedule.count({
					where: { time_out: { [Op.ne]: null } },
				});

				const targetHoursAgg = await User.findAll({
					where: { role: "student", status: "active" },
					attributes: [
						[sequelize.fn("SUM", sequelize.col("target_hours")), "total_target_hours"],
						[sequelize.fn("COUNT", sequelize.col("ccc_id")), "student_count"],
					],
					raw: true,
				});

				// ── 4. Today's attendance across all offices ──────────────────
				const today = new Date().toISOString().split("T")[0];
				const todayTotal = await Schedule.count({ where: { date: today } });
				const todayTimedOut = await Schedule.count({ where: { date: today, time_out: { [Op.ne]: null } } });
				const todayWFH = await Schedule.count({ where: { date: today, isWorkFromHome: true } });

				// ── 5. School years across all offices ────────────────────────
				const schoolYears = await SchoolYear.findAll({
					order: [["current_sy", "DESC"]],
				});

				// ── 6. Special keys (active / expired) ───────────────────────
				const now = new Date();
				const [activeKeys, expiredKeys] = await Promise.all([
					sequelize.models.SpecialKey.count({ where: { expires_at: { [Op.gt]: now } } }),
					sequelize.models.SpecialKey.count({ where: { expires_at: { [Op.lte]: now } } }),
				]);

				// ── 7. Recent super admin audit logs ──────────────────────────
				const recentSuperAdminLogs = await SuperAdminLog.findAll({
					order: [["createdAt", "DESC"]],
					limit: 20,
				});

				// ── 8. Per-office student counts ──────────────────────────────
				const perOfficeStats = await User.findAll({
					where: { role: "student", status: "active" },
					attributes: [
						"office_id",
						[sequelize.fn("COUNT", sequelize.col("ccc_id")), "student_count"],
					],
					group: ["office_id"],
					raw: true,
				});

				const payload = {
					offices: {
						total: totalOffices,
						active: activeOffices,
						deactivated: deactivatedOffices,
						list: officeList,
					},
					users: {
						total: totalUsers,
						active_students: activeStudents,
						active_supervisors: activeSupervisors,
						pending_deletion: pendingDeletion,
						soft_deleted: softDeleted,
					},
					ojt_platform: {
						completed_schedule_entries: completedScheduleCount,
						total_target_hours: parseInt(targetHoursAgg[0]?.total_target_hours ?? 0),
						total_student_count: parseInt(targetHoursAgg[0]?.student_count ?? 0),
					},
					attendance_today: {
						timed_in: todayTotal,
						timed_out: todayTimedOut,
						wfh: todayWFH,
					},
					school_years: schoolYears,
					special_keys: {
						active: activeKeys,
						expired: expiredKeys,
					},
					per_office_stats: perOfficeStats,
					recent_super_admin_logs: recentSuperAdminLogs,
				};

				console.log(payload);
				return res.status(200).json({ success: true, ...payload });
			} catch (error) {
				console.error("Super admin dashboard error:", error);
				return res.status(500).json({ message: "Internal server error.", error: error.message });
			}
		});
	}

	postRouter() { }
}

module.exports = new DashboardRouter().router;