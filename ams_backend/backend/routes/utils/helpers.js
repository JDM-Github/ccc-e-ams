const { Log, SuperAdminLog } = require("../../models/Models");

async function createLog(type, message, userCccId = null) {
    try {
        await Log.create({ user_ccc_id: userCccId, log_type: type, message });
    } catch (err) {
        console.error("Failed to create log:", err);
    }
}

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

module.exports = { createLog, createSuperAdminLog, buildRecordDate, formatDateId };