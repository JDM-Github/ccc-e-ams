// Author: JDM
// Created on: 2026-01-14T22:35:41.019Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");

const Log = sequelize.define(
    "Log",
    {
        user_ccc_id: {
            type: DataTypes.STRING,
            allowNull: true, 
        },
        log_type: {
            type: DataTypes.ENUM(
                'timeIn',
                'timeOut',
                'create',
                'update',
                'delete',
                'sync',
                'error',
                'info'
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

module.exports = Log;