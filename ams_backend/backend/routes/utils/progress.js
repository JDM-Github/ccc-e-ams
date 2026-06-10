const { Schedule } = require("../../models/Models");

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
        if (isPastDate(record.date) && !effectiveTimeOut) effectiveTimeOut = "17:00";
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
                attributes: ["date", "time_in", "time_out", "isWorkFromHome", "isAcceptedWorkFromHome", "isAcceptedEarly"],
                raw: true,
            });
            return { ...plain, ...computeProgress(schedules, plain.target_hours) };
        })
    );
}

module.exports = { computeProgress, attachProgress };