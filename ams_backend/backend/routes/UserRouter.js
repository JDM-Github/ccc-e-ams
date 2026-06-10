// Author: JDM
// Created on: 2026-01-12T15:20:33.119Z
const express = require("express");
const multer = require("multer");

// ── Handlers ──────────────────────────────────────────────────────────────────
const { login, verifyIdentity, resetPassword, changePassword } = require("./handlers/authHandlers");
const { getAllUsers, getAllUsersForUser, getMe,
	registerAdmin, registerSupervisor, registerStudent,
	updateStudent, updateUser, updateStatus, updateProfile } = require("./handlers/userHandlers");
const { getAllSchedules, getSchedulesByUser, getSchedulesWithDetails,
	timeIn, timeOut, addSchedule, updateSchedule, deleteSchedule,
	syncSchedules, advanceIteration } = require("./handlers/scheduleHandlers");
const { fetchAllActivityRecords, addActivityRecord, deleteActivityRecord,
	fetchSummary, addOrUpdateSummary, deleteSummary } = require("./handlers/activityHandlers");
const { updateOffice, setLocation } = require("./handlers/officeHandlers");
const { getLogsByUser, getAllLogs } = require("./handlers/logHandlers");
const { uploadProof } = require("./handlers/uploadHandlers");
const { getCollegeInfo, updateCollegeInfo } = require("./handlers/collegeInfoHandlers");

const upload = multer({ storage: multer.memoryStorage() });

class UserRouter {
	constructor() {
		this.router = express.Router();
		this.getRouter();
		this.postRouter();
		this.putRouter();
		this.deleteRouter();
	}

	getRouter() {
		// ── Users ──────────────────────────────────────────────────────────────
		this.router.get("/get-all", getAllUsers);
		this.router.get("/get-all-users/:ccc_id/:current_iteration", getAllUsersForUser);
		this.router.get("/me/:ccc_id", getMe);

		// ── Schedules ──────────────────────────────────────────────────────────
		this.router.get("/schedules", getAllSchedules);
		this.router.get("/schedules/:ccc_id", getSchedulesByUser);
		this.router.get("/fetch-all-ar/:schedule_record", fetchAllActivityRecords);
		this.router.get("/fetch-summary/:schedule_record", fetchSummary);

		// ── College Info ───────────────────────────────────────────────────────
		this.router.get("/college-info", getCollegeInfo);

		// ── Logs ───────────────────────────────────────────────────────────────
		this.router.get("/logs", getAllLogs);
		this.router.get("/logs/:ccc_id", getLogsByUser);
	}

	postRouter() {
		// ── Auth ───────────────────────────────────────────────────────────────
		this.router.post("/login", login);
		this.router.post("/verify-identity", verifyIdentity);
		this.router.post("/reset-password", resetPassword);
		this.router.post("/change-password", changePassword);

		// ── Registration ───────────────────────────────────────────────────────
		this.router.post("/register-admin", registerAdmin);
		this.router.post("/register-supervisor", registerSupervisor);
		this.router.post("/register-student", registerStudent);

		// ── User updates ───────────────────────────────────────────────────────
		this.router.post("/update-student/:id", updateStudent);
		this.router.post("/update-user/:ccc_id", updateUser);
		this.router.post("/update-status/:id", updateStatus);
		this.router.post("/update-profile", updateProfile);

		// ── Office ─────────────────────────────────────────────────────────────
		this.router.post("/update-office", updateOffice);
		this.router.post("/set-location", setLocation);

		// ── Schedules ──────────────────────────────────────────────────────────
		this.router.post("/schedule", timeIn);
		this.router.post("/schedule/add", addSchedule);
		this.router.post("/schedule/update", updateSchedule);
		this.router.post("/schedule/sync", syncSchedules);
		this.router.post("/get-schedules-with-details", getSchedulesWithDetails);
		this.router.post("/advance-iteration/:ccc_id", advanceIteration);

		// ── Activity records & summaries ───────────────────────────────────────
		this.router.post("/add-ar", addActivityRecord);
		this.router.post("/add-summary", addOrUpdateSummary);

		// ── Upload ─────────────────────────────────────────────────────────────
		this.router.post("/upload-proof", upload.single("file"), uploadProof);
	}

	putRouter() {
		// ── Schedules ──────────────────────────────────────────────────────────
		this.router.put("/schedule/timeout", timeOut);

		// ── College Info ───────────────────────────────────────────────────────
		this.router.put("/college-info", updateCollegeInfo);
	}

	deleteRouter() {
		// ── Schedules ──────────────────────────────────────────────────────────
		this.router.delete("/schedule/:id", deleteSchedule);

		// ── Activity records & summaries ───────────────────────────────────────
		this.router.delete("/delete-ar/:id", deleteActivityRecord);
		this.router.delete("/delete-summary/:id", deleteSummary);
	}
}

module.exports = new UserRouter().router;