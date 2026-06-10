
// Author: JDM
// Created on: 2026-01-12T15:07:54.694Z

const User = require("./UserModel.js");
const Schedule = require("./ScheduleModel.js");
const SupervisorUser = require("./SupervisorUserModel.js");
const Office = require("./OfficeModel.js");
const OfficeBackup = require("./OfficeBackupModel.js");

User.hasMany(Schedule, {
	foreignKey: "ccc_id",
	sourceKey: "ccc_id",
});
Schedule.belongsTo(User, {
	foreignKey: "ccc_id",
	targetKey: "ccc_id",
});

User.hasMany(SupervisorUser, {
	foreignKey: "ccc_id",
	sourceKey: "ccc_id",
});
SupervisorUser.belongsTo(User, {
	foreignKey: "ccc_id",
	targetKey: "ccc_id",
});

Office.hasMany(User, {
	foreignKey: "office_id",
	sourceKey: "office_id",
});
User.belongsTo(Office, {
	foreignKey: "office_id",
	targetKey: "office_id",
});

Office.hasMany(OfficeBackup, {
	foreignKey: "office_id",
	sourceKey: "office_id",
});
OfficeBackup.belongsTo(Office, {
	foreignKey: "office_id",
	targetKey: "office_id",
});

module.exports = {
	sequelize: require("./Sequelize.js"),
	User,
	Schedule,
	SupervisorUser,
	Office,
	ActivityRecord: require("./ActivityRecordModel.js"),
	Log: require("./LogModel.js"),
	SchoolYear: require("./SchoolYearModel.js"),
	Summary: require("./SummaryModel.js"),
	SpecialKey: require("./SpecialKeyModel.js"),
	SuperAdmin: require("./SuperAdminModel.js"),
	SuperAdminLog: require("./SuperAdminLogModel.js"),
	CollegeInfo: require("./CollegeInfoModel.js"),
	OfficeBackup // I uncomment this now
};