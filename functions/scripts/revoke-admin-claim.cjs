const { applicationDefault, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

async function main() {
  const uid = process.argv[2];
  const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT;
  if (!uid || !projectId) {
    throw new Error(
      'Usage: GOOGLE_CLOUD_PROJECT=<project-id> node scripts/revoke-admin-claim.cjs <firebase-auth-uid>',
    );
  }

  initializeApp({ credential: applicationDefault(), projectId });
  const auth = getAuth();
  const user = await auth.getUser(uid);
  const claims = { ...user.customClaims };
  delete claims.admin;
  await auth.setCustomUserClaims(uid, claims);
  process.stdout.write(`Removed admin custom claim from ${uid} in ${projectId}.\n`);
  process.stdout.write('The user must sign out and sign in again to refresh their token.\n');
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
