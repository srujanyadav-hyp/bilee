const admin = require('firebase-admin');

const db = admin.firestore();
db.settings({ databaseId: 'bilee' });

/**
 * Expire old active sessions (older than their expiresAt time)
 */
async function expireOldSessions() {
  const now = admin.firestore.Timestamp.now();

  // Find expired active sessions
  const expiredSessionsQuery = await db
    .collection('billingSessions')
    .where('status', '==', 'ACTIVE')
    .where('expiresAt', '<', now)
    .get();

  if (expiredSessionsQuery.empty) {
    return 0;
  }

  // Batch update to EXPIRED
  const batch = db.batch();
  let count = 0;

  expiredSessionsQuery.docs.forEach(doc => {
    batch.update(doc.ref, {
      status: 'EXPIRED',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    count++;
  });

  await batch.commit();
  console.log(`Expired ${count} old sessions`);
  return count;
}

/**
 * Cleanup very old expired sessions (archive to separate collection)
 * This keeps the main collection clean and improves query performance
 */
async function cleanupExpiredSessions() {
  // Find expired sessions older than 30 days
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const cutoffTime = admin.firestore.Timestamp.fromDate(thirtyDaysAgo);

  const oldSessionsQuery = await db
    .collection('billingSessions')
    .where('status', '==', 'EXPIRED')
    .where('expiresAt', '<', cutoffTime)
    .limit(500) // Process in batches
    .get();

  if (oldSessionsQuery.empty) {
    return 0;
  }

  const batch = db.batch();
  let count = 0;

  // Move to archive collection
  for (const doc of oldSessionsQuery.docs) {
    const data = doc.data();
    
    // Add to archive
    const archiveRef = db.collection('archivedSessions').doc(doc.id);
    batch.set(archiveRef, {
      ...data,
      archivedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Delete from main collection
    batch.delete(doc.ref);
    count++;
  }

  await batch.commit();
  console.log(`Archived ${count} old expired sessions`);
  return count;
}

module.exports = { expireOldSessions, cleanupExpiredSessions };
