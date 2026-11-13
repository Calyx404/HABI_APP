import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const db = getFirestore();

const reviewStatuses = new Set([
  "underReview",
  "verified",
  "rejected",
  "suspended",
]);

export const reviewEmployerVerification = onCall(async (request) => {
  if (!request.auth || request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Administrator access is required.");
  }

  const employerId = request.data?.employerId;
  const status = request.data?.status;
  const reason = typeof request.data?.reason === "string"
    ? request.data.reason.trim()
    : "";

  if (typeof employerId !== "string" || employerId.length < 1 || employerId.length > 128) {
    throw new HttpsError("invalid-argument", "A valid employer ID is required.");
  }
  if (typeof status !== "string" || !reviewStatuses.has(status)) {
    throw new HttpsError("invalid-argument", "The requested review status is invalid.");
  }
  if ((status === "rejected" || status === "suspended") && reason.length < 3) {
    throw new HttpsError("invalid-argument", "Provide a reason for this decision.");
  }
  if (reason.length > 1000) {
    throw new HttpsError("invalid-argument", "The review reason is too long.");
  }

  const employerRef = db.collection("employer_profiles").doc(employerId);
  const userRef = db.collection("users").doc(employerId);
  const userSnapshot = await userRef.get();
  if (!userSnapshot.exists || userSnapshot.get("role") !== "employer") {
    throw new HttpsError("not-found", "Employer account was not found.");
  }

  const historyRef = employerRef.collection("verification_history").doc();
  const auditRef = db.collection("admin_audit").doc();
  const notificationRef = userRef.collection("notifications").doc();
  await db.runTransaction(async (transaction) => {
    const employerSnapshot = await transaction.get(employerRef);
    if (!employerSnapshot.exists) {
      throw new HttpsError("not-found", "Employer profile was not found.");
    }
    const previousStatus = employerSnapshot.get("verificationStatus") ?? "pending";
    const event = {
      employerId,
      reviewerId: request.auth!.uid,
      previousStatus,
      status,
      reason,
      decidedAt: new Date(),
    };

    transaction.update(employerRef, {
      verificationStatus: status,
      verificationReason: reason,
      verificationReviewerId: request.auth!.uid,
      verificationUpdatedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(historyRef, event);
    transaction.create(auditRef, {
      action: "employer_verification_reviewed",
      targetType: "employer",
      targetId: employerId,
      reviewerId: request.auth!.uid,
      previousStatus,
      status,
      reason,
      createdAt: FieldValue.serverTimestamp(),
    });
    const notificationTitle = status === "verified"
      ? "Organization verification approved"
      : status === "rejected"
        ? "Organization verification update"
        : status === "suspended"
          ? "Organization account restricted"
          : "Organization verification update";
    const safeMessage = status === "verified"
      ? "Your organization profile is now verified."
      : status === "rejected"
        ? `Your verification request was not approved. ${reason}`
        : status === "suspended"
          ? `Your organization account has been restricted. ${reason}`
          : status === "underReview"
            ? "Your verification request is under review."
            : "Your organization verification status has changed.";
    transaction.create(notificationRef, {
      kind: "verification",
      title: notificationTitle,
      body: safeMessage,
      relatedType: "employerVerification",
      relatedId: employerId,
      createdAt: FieldValue.serverTimestamp(),
      read: false,
    });
  });

  return { ok: true, status };
});
