// Author: JDM
// Created on: 2026-03-15T16:46:55.806Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");

const Summary = sequelize.define(
    "Summary",
    {
        schedule_record_date: { // YYYYMMDD + ccc_id
            type: DataTypes.STRING,
            allowNull: false
        },
        summary_text: {
            type: DataTypes.TEXT,
            allowNull: false,
        },
    },
    {
        timestamps: true,
    }
);

module.exports = Summary;
