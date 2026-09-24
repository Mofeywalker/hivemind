import { randomInt } from "crypto";
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();

/**
 * Security model
 * --------------
 * The client is untrusted. Membership in a hivemind is ONLY granted here, with
 * the Admin SDK, which bypasses firestore.rules. `firestore.rules` forbids every
 * client write of `member_ids`, so `createHivemind` / `joinHivemind` are the only
 * two paths that can put a uid into a hivemind.
 *
 * Both callables enforce App Check (Firebase Console > App Check > Apps must have
 * the Android/iOS apps registered, otherwise calls fail with failed-precondition).
 */
// Colocated with the Cloud Firestore database (europe-west3 / Frankfurt) so that
// membership writes stay in the EU and add no cross-region latency.
const REGION = "europe-west3";

const INVITE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const INVITE_CODE_LENGTH = 6;
const INVITE_CODE_ATTEMPTS = 8;

const MAX_NAME_LENGTH = 60;
const MAX_DESCRIPTION_LENGTH = 300;
const MAX_ICON_LENGTH = 8;
const MAX_REMINDER_TITLE_LENGTH = 200;
const MAX_REMINDER_NOTES_LENGTH = 2000;
const MAX_PUSH_TOKENS = 500;
const MAX_TIMEZONE_LENGTH = 64;


function requireUid(auth: { uid: string } | undefined): string {
  if (!auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }
  return auth.uid;
}

function requireText(value: unknown, maxLength: number, field: string): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `"${field}" must be a string.`);
  }
  const trimmed = value.trim();
  if (trimmed.length === 0) {
    throw new HttpsError("invalid-argument", `"${field}" must not be empty.`);
  }
  if (trimmed.length > maxLength) {
    throw new HttpsError(
      "invalid-argument",
      `"${field}" must be at most ${maxLength} characters.`
    );
  }
  return trimmed;
}

function optionalText(
  value: unknown,
  maxLength: number,
  field: string
): string | null {
  if (value === undefined || value === null || value === "") return null;
  return requireText(value, maxLength, field);
}

async function displayNameFor(uid: string): Promise<{
  displayName: string;
  avatarUrl: string | null;
}> {
  try {
    const record = await getAuth().getUser(uid);
    return {
      displayName:
        record.displayName || record.email?.split("@")[0] || "Member",
      avatarUrl: record.photoURL ?? null,
    };
  } catch {
    return { displayName: "Member", avatarUrl: null };
  }
}

/**
 * Validates an untrusted IANA timezone name. The value is client-written, so an
 * unusable or hostile string must never reach `Intl` formatting.
 */
function safeTimeZone(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const candidate = value.trim();
  if (candidate.length === 0 || candidate.length > MAX_TIMEZONE_LENGTH) {
    return null;
  }
  try {
    new Intl.DateTimeFormat("de-DE", { timeZone: candidate });
    return candidate;
  } catch {
    return null;
  }
}

/**
 * Composes the notification's due line in the recipient's own timezone. The
 * functions runtime runs in UTC, so without an explicit `timeZone` every device
 * would be shown a UTC clock time.
 */
export function formatDueBody(
  dueAtIso: unknown,
  rrule: unknown,
  timeZone: string
): string {
  const dueAt = typeof dueAtIso === "string" ? new Date(dueAtIso) : null;
  if (!dueAt || Number.isNaN(dueAt.getTime())) return "Erinnerung fällig";

  const dateFormatted = dueAt.toLocaleDateString("de-DE", {
    day: "2-digit",
    month: "2-digit",
    timeZone,
  });
  const timeFormatted = dueAt.toLocaleTimeString("de-DE", {
    hour: "2-digit",
    minute: "2-digit",
    timeZone,
  });

  let body = `Fällig am ${dateFormatted} um ${timeFormatted} Uhr`;
  const schedule = typeof rrule === "string" ? rrule : "";
  if (schedule.includes("FREQ=DAILY")) body += " • Täglich";
  else if (schedule.includes("FREQ=WEEKLY")) body += " • Wöchentlich";
  else if (schedule.includes("FREQ=MONTHLY")) body += " • Monatlich";
  return body;
}

function generateInviteCode(): string {
  let code = "";
  for (let i = 0; i < INVITE_CODE_LENGTH; i += 1) {
    code += INVITE_ALPHABET[randomInt(INVITE_ALPHABET.length)];
  }
  return code;
}

/** Invite codes are server-generated, cryptographically random and unique. */
async function createUniqueInviteCode(): Promise<string> {
  for (let attempt = 0; attempt < INVITE_CODE_ATTEMPTS; attempt += 1) {
    const code = generateInviteCode();
    const clash = await db
      .collection("hiveminds")
      .where("invite_code", "==", code)
      .limit(1)
      .get();
    if (clash.empty) return code;
  }
  throw new HttpsError(
    "resource-exhausted",
    "Could not allocate an invite code. Please retry."
  );
}

function hivemindPayload(
  id: string,
  data: FirebaseFirestore.DocumentData
): Record<string, unknown> {
  return {
    id,
    name: data.name,
    description: data.description ?? null,
    icon: data.icon ?? "🐝",
    invite_code: data.invite_code,
    created_by: data.created_by ?? null,
    created_at: data.created_at,
  };
}

/**
 * Creates a hivemind and its owner membership document atomically.
 * The invite code never leaves the server as client input.
 */
export const createHivemind = onCall(
  { region: REGION, enforceAppCheck: true, consumeAppCheckToken: true },
  async (request) => {
    const uid = requireUid(request.auth);
    const name = requireText(request.data?.name, MAX_NAME_LENGTH, "name");
    const description = optionalText(
      request.data?.description,
      MAX_DESCRIPTION_LENGTH,
      "description"
    );
    const icon =
      optionalText(request.data?.icon, MAX_ICON_LENGTH, "icon") ?? "🐝";

    const [inviteCode, identity] = await Promise.all([
      createUniqueInviteCode(),
      displayNameFor(uid),
    ]);
    const nowIso = new Date().toISOString();
    const docRef = db.collection("hiveminds").doc();

    const hivemind = {
      name,
      description,
      icon,
      invite_code: inviteCode,
      created_by: uid,
      member_ids: [uid],
      created_at: nowIso,
    };

    const batch = db.batch();
    batch.set(docRef, hivemind);
    batch.set(docRef.collection("members").doc(uid), {
      user_id: uid,
      hivemind_id: docRef.id,
      role: "owner",
      display_name: identity.displayName,
      avatar_url: identity.avatarUrl,
      joined_at: nowIso,
    });
    await batch.commit();

    return hivemindPayload(docRef.id, hivemind);
  }
);

/**
 * Joins a hivemind by invite code. This is the only client-reachable path that
 * adds a uid to `member_ids`, and the code is verified against the stored value
 * server-side before the membership document is written.
 */
export const joinHivemind = onCall(
  { region: REGION, enforceAppCheck: true, consumeAppCheckToken: true },
  async (request) => {
    const uid = requireUid(request.auth);
    const submitted = requireText(
      request.data?.invite_code,
      MAX_NAME_LENGTH,
      "invite_code"
    ).toUpperCase();
    const code = submitted.replace(/[^A-Z0-9]/g, "");

    if (
      code.length !== INVITE_CODE_LENGTH ||
      [...code].some((char) => !INVITE_ALPHABET.includes(char))
    ) {
      throw new HttpsError("invalid-argument", "Invalid invite code.");
    }

    const snapshot = await db
      .collection("hiveminds")
      .where("invite_code", "==", code)
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new HttpsError("not-found", "Invalid invite code.");
    }

    const doc = snapshot.docs[0];
    const data = doc.data();
    const memberIds: string[] = Array.isArray(data.member_ids)
      ? data.member_ids
      : [];

    if (!memberIds.includes(uid)) {
      const identity = await displayNameFor(uid);
      const batch = db.batch();
      batch.update(doc.ref, {
        member_ids: FieldValue.arrayUnion(uid),
      });
      batch.set(doc.ref.collection("members").doc(uid), {
        user_id: uid,
        hivemind_id: doc.id,
        role: "member",
        display_name: identity.displayName,
        avatar_url: identity.avatarUrl,
        joined_at: new Date().toISOString(),
      });
      await batch.commit();
    }

    return hivemindPayload(doc.id, data);
  }
);

/**
 * Fan-out push for newly created reminders. Reminder documents are
 * client-writable, so every field used here is treated as untrusted input and
 * bounded before it reaches FCM.
 */
export const notifyReminder = onDocumentCreated(
  { document: "reminders/{reminderId}", region: REGION },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const reminder = snapshot.data();
    const reminderId = event.params.reminderId;

    const hivemindId = reminder.hivemind_id;
    const rawTitle = reminder.title;
    if (typeof hivemindId !== "string" || typeof rawTitle !== "string") return;

    const title = rawTitle.trim().slice(0, MAX_REMINDER_TITLE_LENGTH);
    if (title.length === 0) return;

    const notes = (
      typeof reminder.notes === "string" ? reminder.notes : ""
    )
      .trim()
      .slice(0, MAX_REMINDER_NOTES_LENGTH);
    const createdBy =
      typeof reminder.created_by === "string" ? reminder.created_by : null;

    // 1. Fetch parent Hivemind to get member IDs
    const hivemindDoc = await db.collection("hiveminds").doc(hivemindId).get();
    if (!hivemindDoc.exists) return;

    const memberIds: string[] = Array.isArray(hivemindDoc.data()?.member_ids)
      ? hivemindDoc.data()!.member_ids
      : [];
    // Exclude the creator from getting notified about their own creation
    const targetMemberIds = memberIds.filter((id) => id !== createdBy);

    if (targetMemberIds.length === 0) return;

    // 2. Fetch FCM tokens for those members from the users collection, grouped
    //    by each recipient's own timezone so the due time is rendered in local
    //    time on every device. The creator's zone is the fallback for members
    //    that have not reported one yet.
    const [userDocs, creatorDoc] = await Promise.all([
      Promise.all(
        targetMemberIds.map((id) => db.collection("users").doc(id).get())
      ),
      createdBy ? db.collection("users").doc(createdBy).get() : null,
    ]);
    const fallbackTimeZone = safeTimeZone(creatorDoc?.data()?.timezone) ?? "UTC";

    const tokensByTimeZone = new Map<string, string[]>();
    let tokenCount = 0;
    for (const doc of userDocs) {
      const data = doc.data();
      const token = data?.fcm_token;
      if (typeof token !== "string" || token.trim().length === 0) continue;
      if (tokenCount >= MAX_PUSH_TOKENS) break;

      const timeZone = safeTimeZone(data?.timezone) ?? fallbackTimeZone;
      const bucket = tokensByTimeZone.get(timeZone) ?? [];
      const trimmed = token.trim();
      if (!bucket.includes(trimmed)) {
        bucket.push(trimmed);
        tokenCount += 1;
      }
      tokensByTimeZone.set(timeZone, bucket);
    }

    if (tokensByTimeZone.size === 0) return;

    const dueAtIso = typeof reminder.due_at === "string" ? reminder.due_at : "";

    // 3. One multicast per timezone, each with a locally formatted due time.
    const dispatches = [...tokensByTimeZone.entries()].map(
      async ([timeZone, tokens]) => {
        const body = formatDueBody(dueAtIso, reminder.rrule, timeZone);
        try {
          const response = await getMessaging().sendEachForMulticast({
            tokens,
            notification: {
              title: title,
              body: body,
            },
            data: {
              reminder_id: reminderId,
              hivemind_id: hivemindId,
              title: title,
              notes: notes,
              due_at: dueAtIso,
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
            `Dispatched "${body}" to ${response.successCount}/${tokens.length} devices in ${timeZone}`
          );
        } catch (err) {
          console.error(`Error sending FCM reminder for ${timeZone}:`, err);
        }
      }
    );
    await Promise.all(dispatches);
  }
);
