const CryptoJS = require("crypto-js");
const stringify = require("fast-json-stable-stringify");
const { Op } = require("sequelize");
const {
    User, Schedule, SupervisorUser, Office,
    ActivityRecord, Log, SchoolYear, Summary, OfficeBackup,
} = require("../../models/Models");
const { buildRecordDate, formatDateId, createLog, createSuperAdminLog } = require("./helpers");

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
                return { ...schedule, activities: activityMap[key] || [], summaries: summaryMap[key] || [] };
            });
        return { ...user, supervisor_record: supervisorMap[user.ccc_id] || null, schedules: userSchedules };
    });

    const backed_up_at = new Date().toISOString();
    const payload = { meta: { office_id, backed_up_at }, office, school_year: school_year || null, users, logs };
    return { office, payload, users, backed_up_at };
}

/**
 * Runs the auto-backup if one hasn't been created yet today (first of month).
 * Call this inside the login handler after the office is confirmed.
 */
async function runAutoBackupIfNeeded(office, user) {
    const today = new Date();
    if (today.getDate() !== 1) return;

    const startOfDay = new Date(new Date().setHours(0, 0, 0, 0));
    const endOfDay = new Date(new Date().setHours(23, 59, 59, 999));

    const existingBackup = await OfficeBackup.findOne({
        where: {
            office_id: office.office_id,
            backup_by_superadmin: true,
            createdAt: { [Op.between]: [startOfDay, endOfDay] },
        },
    });

    if (existingBackup) return;

    if (!process.env.BACKUP_SECRET) {
        console.error("BACKUP_SECRET missing - auto-backup skipped for office", office.office_id);
        return;
    }

    try {
        const { payload } = await buildOfficeBackupPayload(office.office_id);
        const integrity_hash = CryptoJS.HmacSHA256(stringify(payload), process.env.BACKUP_SECRET).toString(CryptoJS.enc.Hex);
        const lastBackup = await OfficeBackup.findOne({ where: { office_id: office.office_id }, order: [["version", "DESC"]] });
        const nextVersion = lastBackup ? lastBackup.version + 1 : 1;
        const unique_id = `SA_${formatDateId()}_${office.office_id}`;

        await OfficeBackup.create({
            unique_id,
            office_id: office.office_id,
            version: nextVersion,
            json_backup: { integrity_hash, payload },
            backup_by_superadmin: true,
        });

        await createLog("info", `Auto-backup created for office ${office.office_id} on first day of month (user ${user.ccc_id})`, user.ccc_id);
        await createSuperAdminLog("backup", `Auto-backup triggered by user ${user.ccc_id} for office ${office.office_id} on first day of month. Backup ID: ${unique_id}, version: ${nextVersion}`);
    } catch (backupErr) {
        console.error("Auto-backup failed on login:", backupErr);
    }
}

module.exports = { buildOfficeBackupPayload, runAutoBackupIfNeeded };