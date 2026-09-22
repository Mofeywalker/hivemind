import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

admin.initializeApp();

export const notifyReminder = onDocumentCreated("reminders/{reminderId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const reminder = snapshot.data();
  const reminderId = event.params.reminderId;
  const hivemindId = reminder.hivemind_id;
  const title = reminder.title;
  const createdBy = reminder.created_by;

  if (!hivemindId || !title) return;

  // 1. Fetch parent Hivemind to get member IDs
  const hivemindDoc = await admin.firestore().collection("hiveminds").doc(hivemindId).get();
  if (!hivemindDoc.exists) return;

  const memberIds: string[] = hivemindDoc.data()?.member_ids || [];
  // Exclude the creator from getting notified about their own creation
  const targetMemberIds = memberIds.filter((id) => id !== createdBy);

  if (targetMemberIds.length === 0) return;

  // 2. Fetch FCM tokens for those members from users collection
  const tokenPromises = targetMemberIds.map((id) =>
    admin.firestore().collection("users").doc(id).get()
  );
  const userDocs = await Promise.all(tokenPromises);
  const fcmTokens: string[] = [];

  for (const doc of userDocs) {
    const token = doc.data()?.fcm_token;
    if (token && typeof token === "string" && token.trim().length > 0) {
      fcmTokens.push(token.trim());
    }
  }

  if (fcmTokens.length === 0) return;

  // 3. Format date and time trigger for notification body
  let triggerBody = "Erinnerung fällig";
  if (reminder.due_at) {
    const dueDate = new Date(reminder.due_at);
    const dateFormatted = dueDate.toLocaleDateString("de-DE", {
      day: "2-digit",
      month: "2-digit",
    });
    const timeFormatted = dueDate.toLocaleTimeString("de-DE", {
      hour: "2-digit",
      minute: "2-digit",
    });
    triggerBody = `Fällig am ${dateFormatted} um ${timeFormatted} Uhr`;
    if (reminder.rrule) {
      if (reminder.rrule.includes("FREQ=DAILY")) triggerBody += " • Täglich";
      else if (reminder.rrule.includes("FREQ=WEEKLY")) triggerBody += " • Wöchentlich";
      else if (reminder.rrule.includes("FREQ=MONTHLY")) triggerBody += " • Monatlich";
    }
  }

  // 4. Send multicast notification natively via Firebase Admin
  try {
    const response = await admin.messaging().sendEachForMulticast({
      tokens: fcmTokens,
      notification: {
        title: title,
        body: triggerBody,
      },
      data: {
        reminder_id: reminderId,
        hivemind_id: hivemindId,
        title: title,
        notes: reminder.notes || "",
        due_at: reminder.due_at || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "hivemind_activity",
          sound: "default",
        },
      },
    });

    console.log(
      `Successfully dispatched FCM reminder to ${response.successCount}/${fcmTokens.length} devices`
    );
  } catch (err) {
    console.error("Error sending multicast FCM notification:", err);
  }
});
