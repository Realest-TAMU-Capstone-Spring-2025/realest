// Firebase Function to promote a qualified lead
const { onCall, HttpsError } = require("firebase-functions/v1/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const sgMail = require("@sendgrid/mail");
const crypto = require("crypto");

// Import Firebase Functions as ES module
import * as functions from "firebase-functions";

// Configure SendGrid with API key from Firebase config
sgMail.setApiKey(functions.config().sendgrid.api_key);

/**
 * Generates a random alphanumeric password of specified length.
 * @param {number} [length=10] - Length of the password.
 * @returns {string} A random alphanumeric password.
 */
function generateRandomPassword(length = 10) {
  return crypto.randomBytes(length)
    .toString('base64')
    .replace(/[^a-zA-Z0-9]/g, '')
    .slice(0, length);
}

// Initialize Firebase Admin SDK
initializeApp();

/**
 * Firebase Callable Function to promote a user to a qualified lead.
 * Creates a Firebase Auth user, sets up their Firestore profile, updates investor status,
 * and sends a welcome email with temporary credentials.
 * @param data - Expected to contain `uid` (string) and `email` (string) of the user to promote.
 * @param context - Firebase function context, including auth info.
 * @returns {Promise<{ success: boolean, uid: string, password: string }>} Success response with user details.
 * @throws {HttpsError} If caller is not authenticated, lacks realtor role, or an error occurs.
 */
exports.promoteQualifiedLead = onCall(async (data: any, context: any) => {
  // Ensure caller is authenticated
  if (!context.auth) {
    throw new Error("Only authenticated users can call this.");
  }

  const callerUid = context.auth.uid;
  const db = getFirestore();

  // Verify caller is a realtor
  const callerDoc = await db.collection("users").doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data().role !== "realtor") {
    throw new Error("Only realtors can promote users to qualified lead.");
  }

  const { uid, email } = data;
  const password = generateRandomPassword(10);

  try {
    // Create Firebase Auth user
    await getAuth().createUser({
      uid,
      email,
      password,
    });

    // Set user profile in Firestore
    await db.collection("users").doc(uid).set({
      email,
      role: "investor",
      completedSetup: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    // Update investor status to qualified-lead
    await db.collection("investors").doc(uid).update({
      status: "qualified-lead",
      tempPassword: password,
    });

    // Send welcome email with temporary credentials
    const msg = {
      to: email,
      from: "noreply.mailer.realest@gmail.com", // Verified sender email
      subject: "Welcome to the Real Estate App!",
      html: `
        <h2>Your account has been created</h2>
        <p>We've created your account with the following credentials:</p>
        <ul>
          <li><strong>Email:</strong> ${email}</li>
          <li><strong>Temporary Password:</strong> ${password}</li>
        </ul>
        <p>Please log in and complete your setup.</p> `,
    };
    await sgMail.send(msg);

    return { success: true, uid, password };
  } catch (error: any) {
    console.error("Error promoting user", uid, "to qualified-lead:", error.message, error?.response?.body || error);
    throw new HttpsError("internal", error.message || "Unknown error occurred");
  }
});