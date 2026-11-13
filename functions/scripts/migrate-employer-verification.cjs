const { applicationDefault, initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');

async function main() {
  const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT;
  if (!projectId) {
    throw new Error('Set GOOGLE_CLOUD_PROJECT to the intended Firebase project.');
  }
  initializeApp({ credential: applicationDefault(), projectId });
  const db = getFirestore();
  const snapshot = await db.collection('employer_profiles').get();
  const missing = snapshot.docs.filter((doc) => !doc.data().verificationStatus);

  process.stdout.write(
    `${missing.length} of ${snapshot.size} employer profiles need the pending default in ${projectId}.\n`,
  );
  if (!process.argv.includes('--apply')) {
    process.stdout.write('Dry run only. Review the target, then pass --apply to write.\n');
    return;
  }

  for (let start = 0; start < missing.length; start += 400) {
    const batch = db.batch();
    for (const doc of missing.slice(start, start + 400)) {
      batch.update(doc.ref, {
        verificationStatus: 'pending',
        verificationReason: '',
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
  process.stdout.write('Existing employer profiles now have pending status. Job listings were not changed.\n');
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
