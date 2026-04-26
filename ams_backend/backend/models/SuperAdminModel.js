// Author: JDM
// Created on: 2026-03-24T10:30:23.328Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");

const SuperAdmin = sequelize.define(
    "SuperAdmin",
    {
        username: {
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
    },
    {
        timestamps: true,
    }
);

module.exports = SuperAdmin;