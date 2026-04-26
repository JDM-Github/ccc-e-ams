// Author: JDM
// Created on: 2026-01-14T03:08:25.843Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");

const Office = sequelize.define(
    "Office",
    {
        office_id: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
        },
        office_name: {
            type: DataTypes.STRING,
            allowNull: false
        },
        office_latitude: {
            type: DataTypes.DECIMAL,
            allowNull: false
        },
        office_longitude: {
            type: DataTypes.DECIMAL,
            allowNull: false
        },
        office_altitude: {
            type: DataTypes.DECIMAL,
            allowNull: false
        },

        time_in_start: {
            type: DataTypes.TIME,
            allowNull: false,
            defaultValue: "06:00:00"
        },
        time_in_start_wfh: {
            type: DataTypes.TIME,
            allowNull: false,
            defaultValue: "08:00:00"
        },
        time_in_end: {
            type: DataTypes.TIME,
            allowNull: false,
            defaultValue: "17:00:00"
        },
        time_out_cap: {
            type: DataTypes.TIME,
            allowNull: false,
            defaultValue: "21:00:00"
        },
        allow_weekend: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        },
        deactivated: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        }
    },
    {
        timestamps: true,
    }
);

module.exports = Office;
