// Author: JDM
// Created on: 2026-01-12T15:11:25.858Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");
const User = require("./UserModel.js");

const Schedule = sequelize.define(
    "Schedule",
    {
        date: {
            type: DataTypes.DATEONLY,
            allowNull: false,
        },
        time_in: {
            type: DataTypes.TIME,
            allowNull: false,
        },
        time_out: {
            type: DataTypes.TIME,
            allowNull: true,
        },
        proof_in: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        proof_out: {
            type: DataTypes.STRING,
            allowNull: true,
        },

        isAcceptedEarly: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        },
        isAcceptedWorkFromHome: {
            type: DataTypes.BOOLEAN,
            defaultValue: true
        },
        isWorkFromHome: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        },
        ccc_id: {
            type: DataTypes.STRING,
            allowNull: false,
            references: {
                model: User,
                key: "ccc_id",
            },
            onUpdate: "CASCADE",
            onDelete: "CASCADE",
        },
    },
    {
        timestamps: true,
    }
);

module.exports = Schedule;
