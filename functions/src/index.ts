import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";

initializeApp();

const db = getFirestore();

type NotificationKind = "application" | "status" | "message";

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
  await db.collection("users").doc(uid).collection("notifications").doc(notificationId).set({
    ...data,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
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
