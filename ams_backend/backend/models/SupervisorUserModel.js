// Author: JDM
// Created on: 2026-01-13T05:37:50.901Z

const sequelize = require("./Sequelize.js");
const { DataTypes } = require("sequelize");
const User = require("./UserModel.js");

const SupervisorUser = sequelize.define(
    "SupervisorUser",
    {
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
        all_users: {
            type: DataTypes.ARRAY(DataTypes.STRING),
            defaultValue: [],
        }
    },
    {
        timestamps: true,
    }
);

module.exports = SupervisorUser;
