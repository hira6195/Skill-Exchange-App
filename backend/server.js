const express = require("express");
const cors = require("cors");
const nodemailer = require("nodemailer");
require("dotenv").config();

// Firebase Admin Modular Imports
const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

const serviceAccount = require("./skill-exchange-app-80674-firebase-adminsdk-fbsvc-87880e7672.json");

// Firebase Admin Initialization
initializeApp({
  credential: cert(serviceAccount),
});

const app = express();

app.use(cors());
app.use(express.json());

// Gmail SMTP configuration
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Test SMTP Connection
transporter.verify((error, success) => {
  if (error) {
    console.error("❌ SMTP connection failed:", error);
  } else {
    console.log("✅ SMTP connection successful!");
  }
});

// Root Route
app.get("/", (req, res) => {
  res.json({
    message: "Skill Exchange Backend is running!",
  });
});

// 1. Send Test Email Endpoint
app.post("/send-test-email", async (req, res) => {
  try {
    const { to } = req.body;

    if (!to) {
      return res.status(400).json({
        success: false,
        message: "Recipient email is required",
      });
    }

    await transporter.sendMail({
      from: `"Skill Exchange" <${process.env.EMAIL_USER}>`,
      to: to,
      subject: "Skill Exchange - SMTP Test",
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2 style="color: #6C25A8;">Skill Exchange</h2>
          <p>This is a test email sent from your Node.js backend via Nodemailer.</p>
        </div>
      `,
    });

    res.json({
      success: true,
      message: "Test email sent successfully!",
    });
  } catch (error) {
    console.error("Email sending failed:", error);

    res.status(500).json({
      success: false,
      message: "Failed to send email",
      error: error.message,
    });
  }
});

// 2. Step 23: Send Verification Link Email Endpoint
app.post("/send-verification-email", async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    // Generate Firebase Email Verification Link (Modular Way)
    const verificationLink = await getAuth().generateEmailVerificationLink(email);

    // Send verification email through Gmail SMTP
    await transporter.sendMail({
      from: `"Skill Exchange" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Verify Your Skill Exchange Email",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 12px;">
          <h2 style="color: #6A1B9A;">Welcome to Skill Exchange!</h2>

          <p>Thank you for creating your account.</p>

          <p>Please click the button below to verify your email address:</p>

          <p style="text-align: center; margin: 25px 0;">
            <a
              href="${verificationLink}"
              style="
                display: inline-block;
                padding: 12px 28px;
                background-color: #6A1B9A;
                color: white;
                text-decoration: none;
                border-radius: 8px;
                font-weight: bold;
              "
            >
              Verify My Email
            </a>
          </p>

          <p style="font-size: 13px; color: #555;">If the button doesn't work, copy and paste this link in your browser:<br>
          <a href="${verificationLink}" style="color: #6A1B9A;">${verificationLink}</a></p>

          <p>If you did not create this account, you can ignore this email.</p>

          <p>Thanks,<br><strong>Skill Exchange Team</strong></p>
        </div>
      `,
    });

    res.json({
      success: true,
      message: "Verification email sent successfully!",
    });
  } catch (error) {
    console.error("Verification email failed:", error);

    res.status(500).json({
      success: false,
      message: "Failed to send verification email",
      error: error.message,
    });
  }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});