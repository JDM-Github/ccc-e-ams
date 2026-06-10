const cloudinary = require("../../service/Cloudinary");

// ─── POST /upload-proof ───────────────────────────────────────────────────────
async function uploadProof(req, res) {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: "No file provided" });

        const stream = cloudinary.uploader.upload_stream(
            { folder: "ccc-ojt-proofs", resource_type: "image" },
            (error, result) => {
                if (error) return res.status(500).json({ success: false, message: "Upload failed" });
                return res.json({ success: true, url: result.secure_url });
            }
        );
        stream.end(req.file.buffer);
    } catch (err) {
        return res.status(500).json({ success: false, message: "Upload failed" });
    }
}

module.exports = { uploadProof };