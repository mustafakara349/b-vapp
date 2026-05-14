// =============================================================================
//  index.js — B&V Barber App Cloud Functions
//  Firebase Cloud Functions v5  |  Node 20  |  firebase-admin v12
// =============================================================================

"use strict";

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule }        = require("firebase-functions/v2/scheduler");
const { initializeApp }     = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging }      = require("firebase-admin/messaging");

// Admin SDK'yı bir kez başlat
initializeApp();

const db  = getFirestore();
const fcm = getMessaging();

// ---------------------------------------------------------------------------
// YARDIMCI: Tek bir cihaza FCM bildirimi gönder
// ---------------------------------------------------------------------------

/**
 * @param {string} token   - FCM registration token
 * @param {string} title   - Bildirim başlığı
 * @param {string} body    - Bildirim gövdesi
 * @param {Object} [data]  - Opsiyonel custom data (key-value string pairs)
 * @returns {Promise<string|null>} messageId veya null (hata durumunda)
 */
async function sendPush(token, title, body, data = {}) {
  if (!token || token.trim() === "") {
    console.warn("[sendPush] Boş token — atlandı.");
    return null;
  }

  const message = {
    token,
    notification: { title, body },
    apns: {
      payload: {
        aps: { sound: "default", badge: 1 },
      },
    },
    android: {
      notification: { sound: "default" },
    },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
  };

  try {
    const messageId = await fcm.send(message);
    console.log(`[sendPush] Gönderildi → ${messageId}`);
    return messageId;
  } catch (err) {
    // Geçersiz/süresi dolmuş token ise Firestore'dan temizle
    if (
      err.code === "messaging/invalid-registration-token" ||
      err.code === "messaging/registration-token-not-registered"
    ) {
      console.warn(`[sendPush] Geçersiz token, temizleniyor: ${token.slice(0, 20)}…`);
    } else {
      console.error("[sendPush] FCM hatası:", err.message);
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// YARDIMCI: Token'ı Firestore'dan al (userId'ye göre)
// ---------------------------------------------------------------------------

/**
 * @param {string} userId
 * @returns {Promise<string|null>} FCM token veya null
 */
async function getTokenForUser(userId) {
  if (!userId) return null;
  const snap = await db.collection("users").doc(userId).get();
  if (!snap.exists) {
    console.warn(`[getTokenForUser] Kullanıcı bulunamadı: ${userId}`);
    return null;
  }
  return snap.data().fcmToken || null;
}

// =============================================================================
// FUNCTION A — Randevu Oluşturulduğunda Bildirim Gönder
// Tetikleyici: appointments/{appointmentId}  onCreate
// =============================================================================

exports.onAppointmentCreated = onDocumentCreated(
  "appointments/{appointmentId}",
  async (event) => {
    const appointment = event.data.data();

    if (!appointment) {
      console.error("[onAppointmentCreated] Döküman verisi bulunamadı.");
      return;
    }

    const { userId, serviceName } = appointment;

    if (!userId || !serviceName) {
      console.warn("[onAppointmentCreated] userId veya serviceName eksik — atlandı.");
      return;
    }

    const token = await getTokenForUser(userId);

    if (!token) {
      console.warn(`[onAppointmentCreated] Kullanıcı için token yok: ${userId}`);
      return;
    }

    await sendPush(
      token,
      "Randevu Oluşturuldu",
      `${serviceName} için randevunuz alındı`,
      {
        type: "appointment_created",
        appointmentId: event.params.appointmentId,
      }
    );
  }
);

// =============================================================================
// FUNCTION B — Randevu Hatırlatma CRON (her 5 dakikada bir)
// Saat bazlı: randevuya 1 saat kalan, sadece status="active" olanlar
// reminderSent=true olanlar atlanır (çift bildirim önleme)
// =============================================================================

exports.appointmentReminder = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "Europe/Istanbul",
  },
  async () => {
    const now = new Date();

    // 55 dakika → 65 dakika arası aralığı hedefle
    // (her 5 dk'da bir çalışır; 1 saat ± 5 dk penceresi)
    const windowStart = new Date(now.getTime() + 55 * 60 * 1000); // 55 dk sonra
    const windowEnd   = new Date(now.getTime() + 65 * 60 * 1000); // 65 dk sonra

    // Tarih + saat dizelerini "yyyy-MM-dd" ve "HH:mm" formatında üret
    const pad = (n) => String(n).padStart(2, "0");

    const fmtDate = (d) =>
      `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
    const fmtTime = (d) =>
      `${pad(d.getHours())}:${pad(d.getMinutes())}`;

    const startDate = fmtDate(windowStart);
    const endDate   = fmtDate(windowEnd);

    console.log(
      `[Reminder] Pencere: ${fmtDate(windowStart)} ${fmtTime(windowStart)} — ${fmtDate(windowEnd)} ${fmtTime(windowEnd)}`
    );

    // Aktif ve henüz hatırlatılmamış randevuları çek
    // Tarih aralığı filtresi (aynı gün veya gece yarısı geçişi)
    let query = db
      .collection("appointments")
      .where("status", "==", "active")
      .where("reminderSent", "!=", true);

    // Tarih aralığı aynı gün ise tek sorgu yeterli;
    // gece yarısı geçişinde iki tarih olabilir
    if (startDate === endDate) {
      query = query
        .where("date", "==", startDate)
        .where("time", ">=", fmtTime(windowStart))
        .where("time", "<=", fmtTime(windowEnd));
    } else {
      // Basit yaklaşım: iki günü de çek, zaman kontrolünü uygulama katmanında yap
      query = query.where("date", "in", [startDate, endDate]);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      console.log("[Reminder] Bu pencerede hatırlatılacak randevu yok.");
      return;
    }

    const batch = db.batch();
    const sends = [];

    snapshot.forEach((doc) => {
      const appt = doc.data();

      // Gece yarısı geçişi durumunda manuel zaman kontrolü
      const apptDateTimeStr = `${appt.date}T${appt.time}:00`;
      const apptTime = new Date(apptDateTimeStr);

      if (apptTime < windowStart || apptTime > windowEnd) {
        return; // Bu döküman pencere dışında — atla
      }

      // reminderSent = true ile işaretle (batch write)
      batch.update(doc.ref, {
        reminderSent: true,
        updatedAt: Timestamp.now(),
      });

      // Bildirimi gönder
      const sendJob = getTokenForUser(appt.userId).then((token) => {
        if (!token) {
          console.warn(`[Reminder] Token yok: userId=${appt.userId}`);
          return;
        }
        return sendPush(
          token,
          "Randevu Hatırlatma",
          "Randevunuza 1 saat kaldı",
          {
            type: "appointment_reminder",
            appointmentId: doc.id,
            date: appt.date,
            time: appt.time,
          }
        );
      });

      sends.push(sendJob);
    });

    // Tüm bildirimleri ve batch commit'i paralel çalıştır
    await Promise.all([...sends, batch.commit()]);

    console.log(`[Reminder] ${sends.length} randevu için hatırlatma işlendi.`);
  }
);

// =============================================================================
// FUNCTION C — Broadcast (Toplu) Bildirim Sistemi
// Tetikleyici: notifications/{notificationId}  onCreate
// notifications dökümanı: { title, body, target: "all"|"users", createdAt }
// =============================================================================

exports.onBroadcastNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const notif = event.data.data();

    if (!notif) {
      console.error("[Broadcast] Döküman verisi bulunamadı.");
      return;
    }

    const { title, body, target } = notif;

    if (!title || !body) {
      console.error("[Broadcast] title veya body eksik — atlandı.");
      return;
    }

    // Hedef kullanıcıları belirle
    let usersQuery = db.collection("users").where("isActive", "==", true);

    if (target === "users") {
      // Sadece "customer" rolündeki kullanıcılar
      usersQuery = usersQuery.where("role", "==", "customer");
    }
    // target === "all" veya başka değer → tüm aktif kullanıcılar

    const usersSnap = await usersQuery.get();

    if (usersSnap.empty) {
      console.warn("[Broadcast] Hedef kullanıcı bulunamadı.");
      return;
    }

    const sends = [];
    let skipped = 0;

    usersSnap.forEach((doc) => {
      const user = doc.data();
      const token = user.fcmToken;

      if (!token || token.trim() === "") {
        skipped++;
        return;
      }

      sends.push(
        sendPush(token, title, body, {
          type: "broadcast",
          notificationId: event.params.notificationId,
        })
      );
    });

    await Promise.all(sends);

    console.log(
      `[Broadcast] ${sends.length} kullanıcıya gönderildi, ${skipped} kullanıcı token'sız atlandı.`
    );

    // Gönderim istatistiklerini notification dökümanına yaz (opsiyonel)
    await event.data.ref.update({
      sentCount: sends.length,
      skippedCount: skipped,
      processedAt: Timestamp.now(),
    });
  }
);
