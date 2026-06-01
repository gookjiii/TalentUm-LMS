import { dbAdmin } from './utils/firebase';

async function testQuery() {
  try {
    console.log('Testing topic query...');
    const snap = await dbAdmin.collectionGroup('messages')
      .where('metadata.topicId', '==', 'test')
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();
    console.log('Query succeeded! Index is active. Found:', snap.size);
  } catch (e: any) {
    console.error('Query failed:', e.message);
  }
}

testQuery();
