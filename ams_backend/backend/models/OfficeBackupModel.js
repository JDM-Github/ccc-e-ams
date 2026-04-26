// Author: JDM
// Created on: 2026-04-13T08:36:00.552Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");
const Office = require("./OfficeModel.js");

const OfficeBackup = sequelize.define(
    "OfficeBackup",
    {
        unique_id: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
        },
        version: {
            type: DataTypes.INTEGER,
            defaultValue: 0
        },
        office_id: {
            type: DataTypes.STRING,
            allowNull: false,
            references: {
                model: Office,
                key: "office_id",
            },
            onUpdate: "CASCADE",
            onDelete: "CASCADE",
        },
        json_backup: {
            type: DataTypes.JSON,
            allowNull: false
        },
        backup_by_superadmin: {
            type: DataTypes.BOOLEAN,
            defaultValue: false
        }
    },
    {
        timestamps: true,
    }
);

module.exports = OfficeBackup;