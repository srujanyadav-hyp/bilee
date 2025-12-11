const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * Update daily aggregate by recalculating from completed sessions
 */
async function updateDailyAggregate(merchantId, date) {
  // Fetch all completed sessions for the date
  const startOfDay = new Date(date + 'T00:00:00');
  const endOfDay = new Date(date + 'T23:59:59');

  const sessionsQuery = await db
    .collection('billingSessions')
    .where('merchantId', '==', merchantId)
    .where('status', '==', 'COMPLETED')
    .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
    .where('completedAt', '<=', admin.firestore.Timestamp.fromDate(endOfDay))
    .get();

  if (sessionsQuery.empty) {
    console.log(`No completed sessions for merchant ${merchantId} on ${date}`);
    return;
  }

  // Aggregate data from all sessions
  let totalRevenue = 0;
  let totalOrders = sessionsQuery.size;
  const itemsMap = new Map();

  sessionsQuery.docs.forEach(doc => {
    const session = doc.data();
    totalRevenue += session.total;

    // Aggregate items
    session.items.forEach(item => {
      if (itemsMap.has(item.name)) {
        const existing = itemsMap.get(item.name);
        itemsMap.set(item.name, {
          name: item.name,
          qty: existing.qty + item.qty,
          revenue: existing.revenue + item.total,
        });
      } else {
        itemsMap.set(item.name, {
          name: item.name,
          qty: item.qty,
          revenue: item.total,
        });
      }
    });
  });

  const itemsSold = Array.from(itemsMap.values());

  // Check if aggregate already exists
  const aggregateQuery = await db
    .collection('dailyAggregates')
    .where('merchantId', '==', merchantId)
    .where('date', '==', date)
    .limit(1)
    .get();

  const aggregateData = {
    merchantId: merchantId,
    date: date,
    total: totalRevenue,
    ordersCount: totalOrders,
    itemsSold: itemsSold,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (aggregateQuery.empty) {
    // Create new aggregate
    await db.collection('dailyAggregates').add(aggregateData);
    console.log(`Created daily aggregate for ${merchantId} on ${date}`);
  } else {
    // Update existing aggregate
    await db.collection('dailyAggregates').doc(aggregateQuery.docs[0].id).update(aggregateData);
    console.log(`Updated daily aggregate for ${merchantId} on ${date}`);
  }

  return aggregateData;
}

module.exports = { updateDailyAggregate };
