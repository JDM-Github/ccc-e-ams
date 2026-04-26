const express = require("express");
const cors = require("cors");
const serverless = require("serverless-http");
const path = require("path");
const { sequelize } = require("../models/Models.js");
const bodyParser = require("body-parser");
const app = express();
const router = express.Router();
const sendEmail = require("../service/EmailSender.js");
app.use(
	cors({
		origin: "*",
		methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
		allowedHeaders: ["Content-Type", "Authorization"],
	})
);
app.options("*", cors());
app.use(bodyParser.json());
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ extended: true, limit: "50mb" }));

// -------------------------------------------------------------------------------
// ALL ROUTES
// -------------------------------------------------------------------------------
router.get("/test", async (req, res) => {
	res.status(200).json("This is a test endpoint.");
});
router.get("/reset", async (req, res) => {
	await sequelize.sync({ force: true });
	res.send("Database reset successful.");
});
router.use("/user", require("../routes/UserRouter.js"));
router.use("/super-admin", require("../routes/SuperAdminRouter.js"));
router.use("/backup", require("../routes/BackupRouter.js"));
router.use("/dashboard", require("../routes/DashboardRouter.js"));
router.post("/send-email", async (req, res) => {
	try {
		const { to, subject, text, html } = req.body;

		if (!to || !subject || (!text && !html)) {
			return res.status(400).json({
				message: "Missing required fields: to, subject, and text or html",
			});
		}

		const info = await sendEmail(to, subject, text, html);

		res.status(200).json({
			message: "Email sent successfully",
			response: info.response,
			success: true
		});
	} catch (error) {
		console.error("Send email route error:", error);
		res.status(500).json({
			message: "Failed to send email",
			error: error.message,
			success: false
		});
	}
});

app.use(express.static(path.join(__dirname, "../client/build")));
app.use("/.netlify/functions/api", router);
module.exports.handler = serverless(app);
