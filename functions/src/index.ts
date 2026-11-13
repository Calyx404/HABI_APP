import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
export { reviewEmployerVerification } from "./admin.js";

initializeApp();

const db = getFirestore();

type NotificationKind = "application" | "status" | "message" | "interview";

async function notifyUser(
  uid: string,
  eventId: string,
  data: {
    title: string;
    body: string;
    kind: NotificationKind;
    jobId?: string;
    otherUserName?: string;
    otherUserId?: string;
    conversationId?: string;
  },
): Promise<void> {
  if (!uid) return;
  const notificationId = eventId.replaceAll("/", "_");
  const user = db.collection("users").doc(uid);
  await user.collection("notifications").doc(notificationId).set({
    ...data,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  const [preferencesSnapshot, deviceSnapshot] = await Promise.all([
    user.collection("settings").doc("preferences").get(),
    user.collection("devices").limit(500).get(),
  ]);
  const preferences = preferencesSnapshot.data();
  if (preferences?.pushEnabled !== true) return;
  const preferenceKey = data.kind === "message" ? "messages" : "applicationUpdates";
  if (preferences[preferenceKey] === false || deviceSnapshot.empty) return;

  const devices = deviceSnapshot.docs.filter((doc) => typeof doc.data().fid === "string");
  if (devices.length === 0) return;
  const deliveryRef = db.collection("push_delivery_events").doc(notificationId);
  const claimed = await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(deliveryRef);
    if (existing.exists) return false;
    transaction.create(deliveryRef, {
      uid,
      kind: data.kind,
      status: "sending",
      createdAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!claimed) return;

  try {
    const response = await getMessaging().sendEachForMulticast({
      fids: devices.map((doc) => doc.data().fid as string),
      notification: { title: data.title, body: data.body },
      data: {
        notificationId,
        kind: data.kind,
        jobId: data.jobId ?? "",
        conversationId: data.conversationId ?? "",
      },
    });
    const batch = db.batch();
    response.responses.forEach((result, index) => {
      if (!result.success && result.error?.code === "messaging/installation-id-not-registered") {
        batch.delete(devices[index].ref);
      }
    });
    batch.update(deliveryRef, {
      status: response.successCount > 0 ? "sent" : "failed",
      successCount: response.successCount,
      failureCount: response.failureCount,
      updatedAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
  } catch (error) {
    await deliveryRef.update({ status: "failed", updatedAt: FieldValue.serverTimestamp() });
    console.error("FCM push delivery failed", { uid, notificationId, error });
  }
}

export const notifyNewApplication = onDocumentCreated(
  "applications/{applicationId}",
  async (event) => {
    const application = event.data?.data();
    if (!application) return;
    await notifyUser(application.employerId, event.id, {
      title: "New application",
      body: `${application.applicantName} applied for ${application.jobTitle}.`,
      kind: "application",
      jobId: application.jobId,
      otherUserName: application.applicantName,
      otherUserId: application.applicantId,
    });
  },
);

export const notifyApplicationStatus = onDocumentUpdated(
  "applications/{applicationId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;
    await notifyUser(after.applicantId, event.id, {
      title: after.statusTitle || "Application update",
      body: after.statusMessage || `${after.jobTitle} is now: ${after.status}.`,
      kind: "status",
      jobId: after.jobId,
    });
  },
);

export const notifyNewMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const conversationSnapshot = await db
      .collection("conversations")
      .doc(event.params.conversationId)
      .get();
    const conversation = conversationSnapshot.data();
    if (!conversation) return;

    const senderId = message.senderId as string;
    const recipientId = senderId === conversation.posterId
      ? conversation.applicantId as string
      : conversation.posterId as string;
    const text = (message.text as string).trim();
    const preview = text.length > 120 ? `${text.substring(0, 117)}...` : text;

    await notifyUser(recipientId, event.id, {
      title: "New message",
      body: `${message.senderName}: ${preview}`,
      kind: "message",
      jobId: conversation.jobId as string,
      otherUserName: message.senderName as string,
      otherUserId: senderId,
      conversationId: event.params.conversationId,
    });
  },
);

export const notifyInterviewCreated = onDocumentCreated(
  "interviews/{interviewId}",
  async (event) => {
    const interview = event.data?.data();
    if (!interview) return;
    const startsAt = interview.startsAt?.toDate?.() as Date | undefined;
    const when = startsAt?.toLocaleString("en-PH", { timeZone: "Asia/Manila" }) ?? "the scheduled time";
    await Promise.all([
      notifyUser(interview.applicantId, `${event.id}_applicant`, {
        title: "Interview scheduled",
        body: `${interview.jobTitle || "Your application"}: ${when}.`,
        kind: "interview",
        jobId: interview.jobId,
      }),
      notifyUser(interview.employerId, `${event.id}_employer`, {
        title: "Interview scheduled",
        body: `The interview with the applicant is scheduled for ${when}.`,
        kind: "interview",
        jobId: interview.jobId,
      }),
    ]);
  },
);

export const notifyInterviewUpdated = onDocumentUpdated(
  "interviews/{interviewId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const changedTime = before.startsAt?.toMillis?.() !== after.startsAt?.toMillis?.()
      || before.endsAt?.toMillis?.() !== after.endsAt?.toMillis?.();
    const changedStatus = before.status !== after.status;
    const changedResponse = before.applicantResponse !== after.applicantResponse;
    if (!changedTime && !changedStatus && !changedResponse) return;
    const startsAt = after.startsAt?.toDate?.() as Date | undefined;
    const when = startsAt?.toLocaleString("en-PH", { timeZone: "Asia/Manila" }) ?? "the scheduled time";
    const responseChanged = changedResponse && !changedTime && !changedStatus;
    const recipientId = responseChanged ? after.employerId as string : after.applicantId as string;
    const title = responseChanged
      ? "Applicant interview response"
      : after.status === "cancelled"
        ? "Interview cancelled"
        : after.status === "completed"
          ? "Interview completed"
          : changedTime
            ? "Interview updated"
            : "Interview status updated";
    const body = responseChanged
      ? `The applicant ${after.applicantResponse === "rescheduleRequested" ? "requested a new time" : `responded: ${after.applicantResponse}`}.`
      : after.status === "cancelled"
        ? "Your interview has been cancelled."
        : changedTime
          ? `Your interview is now scheduled for ${when}.`
          : `Your interview is marked ${after.status}.`;
    await notifyUser(recipientId, event.id, {
      title,
      body,
      kind: "interview",
      jobId: after.jobId,
    });
  },
);
