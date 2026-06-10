// Author: JDM
// Created on: 2026-01-12T15:07:54.701Z

require("dotenv").config();
const pg = require("pg");
const { Sequelize } = require("sequelize");

const sequelize = new Sequelize(process.env.DATABASE_URL, {
	dialect: "postgres",
	dialectModule: pg,
	dialectOptions: {
		ssl: {
			require: true,
			rejectUnauthorized: true,
		},
	},
});
module.exports = sequelize;