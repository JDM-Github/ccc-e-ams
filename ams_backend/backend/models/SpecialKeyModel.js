// Author: JDM
// Created on: 2026-03-24T10:29:41.958Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");

const SpecialKey = sequelize.define(
    "SpecialKey",
    {
        key: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
        },
        email: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        expires_at: {
            type: DataTypes.DATE,
            allowNull: false,
        },
    },
    {
        timestamps: true,
    }
);

module.exports = SpecialKey;