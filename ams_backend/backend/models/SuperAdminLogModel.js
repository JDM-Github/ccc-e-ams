// Author: JDM
// Created on: 2026-01-14T22:35:41.019Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");

const SuperAdminLog = sequelize.define(
    "SuperAdminLog",
    {
        log_type: {
            type: DataTypes.ENUM(
                'create', // For key
                'backup',
                'restore',
                'deactivate',
                'update', // eg. Password, Profile, 
                'info' // Something for basic
            ),
            allowNull: false,
        },
        message: {
            type: DataTypes.TEXT,
            allowNull: false,
        },
    },
    {
        timestamps: true,
    }
);

module.exports = SuperAdminLog;