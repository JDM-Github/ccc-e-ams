// Author: JDM
// Created on: 2026-03-15T11:34:48.035Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");

const SchoolYear = sequelize.define(
    "SchoolYear",
    {
        office_id: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
        },
        current_sy: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 2025 // will be 2025-2026 when rendered on frontend
        },
        current_iteration: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 1
        }
    },
    {
        timestamps: true,
    }
);

module.exports = SchoolYear;
