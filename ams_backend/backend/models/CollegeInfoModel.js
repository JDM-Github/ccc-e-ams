// Author: JDM
// Created on: 2026-06-08

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");

const CollegeInfo = sequelize.define(
    "CollegeInfo",
    {
        vision: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        mission: {
            type: DataTypes.TEXT,
            allowNull: true,
        }
    },
    {
        timestamps: true,
    }
);

module.exports = CollegeInfo;