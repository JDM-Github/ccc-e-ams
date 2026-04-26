// Author: JDM
// Created on: 2026-01-14T13:17:52.384Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");

const ActivityRecord = sequelize.define(
    "ActivityRecord",
    {
        image_url: {
            type: DataTypes.STRING,
            defaultValue: ""
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        schedule_record_date: { // YYYYMMDD + ccc_id
            type: DataTypes.STRING,
            allowNull: false
        }
    },
    {
        timestamps: true,
    }
);

module.exports = ActivityRecord;
