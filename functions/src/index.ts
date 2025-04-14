// Firebase Function to promote a client
const { onCall, HttpsError  } = require("firebase-functions/v1/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const sgMail = require("@sendgrid/mail");
const crypto = require("crypto");

// const functions = require("firebase-functions");
import * as functions from "firebase-functions";

sgMail.setApiKey(functions.config().sendgrid.api_key);



function generateRandomPassword(length = 10) {
  return crypto.randomBytes(length)
    .toString('base64')
    .replace(/[^a-zA-Z0-9]/g, '')
    .slice(0, length);
}

initializeApp();

/**
 * Promotes a client by creating a Firebase Auth user and linking it to the investor.
 * Expects: { uid, email } from the frontend.
 */
exports.promoteClient = onCall(async (data: any, context: any) => {
  if (!context.auth) {
    throw new Error("Only authenticated users can call this.");
  }

  const callerUid = context.auth.uid;
  const db = getFirestore();
  const callerDoc = await db.collection("users").doc(callerUid).get();

  if (!callerDoc.exists || callerDoc.data().role !== "realtor") {
    throw new Error("Only realtors can promote clients.");
  }

  const { uid, email } = data;
  const password = generateRandomPassword(10);

  try {
    await getAuth().createUser({
      uid,
      email,
      password,
    });

    await db.collection("users").doc(uid).set({
      email,
      role: "investor",
      completedSetup: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    //update the status feild to "client" for the user document in investors
    await db.collection("investors").doc(uid).update({
      status: "client",
      tempPassword: password,
    });

    const msg = {
          to: email,
          from: "noreply.mailer.realest@gmail.com", // ✅ Replace with your verified sender
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
      console.error("Error promoting user",uid,"to client:", error.message, error?.response?.body || error);
      throw new HttpsError("internal", error.message || "Unknown error occurred");
    }
});
