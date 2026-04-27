// Author: JDM
// Created on: 2026-01-12T15:11:15.176Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");
const Office = require("./OfficeModel.js");

const User = sequelize.define(
    "User",
    {
        first_name: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        middle_name: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        last_name: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        suffix_name: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        extension_name: {
            type: DataTypes.STRING,
            allowNull: true,
        },
        ccc_id: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
        },
        email: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
            validate: {
                isEmail: true,
            },
        },
        password: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        role: {
            type: DataTypes.ENUM("student", "supervisor"),
            allowNull: false,
        },
        profile_link: {
            type: DataTypes.STRING,
            allowNull: true
        },
        course: {
            type: DataTypes.STRING,
            allowNull: false,
            defaulValue: "Bachelor of Science in Computer Science"
        },
        target_hours: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 450
        },
        custom_id: {
            type: DataTypes.STRING,
            allowNull: false,
            defaultValue: ""
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
        isAdmin: {
            type: DataTypes.BOOLEAN,
            allowNull: false,
            defaultValue: false
        },

        // this is mainly used for soft deletion and filtering out users in the UI without actually deleting their records from the database, which can cause issues with foreign key constraints and historical data integrity if we were to hard delete them.
        status: {
            type: DataTypes.ENUM("active", "pending_for_delete", "deleted"),
            allowNull: false,
            defaultValue: "active"
        },
        current_sy: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 2025
        }
    },
    {
        timestamps: true,
    }
);

module.exports = User;
