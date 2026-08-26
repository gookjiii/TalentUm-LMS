const { google } = require('googleapis');

const CLIENT_ID = process.argv[2] || process.env.GOOGLE_CLIENT_ID || '';
const CLIENT_SECRET = process.argv[3] || process.env.GOOGLE_CLIENT_SECRET || '';
const CODE = process.argv[4] || process.env.GOOGLE_AUTH_CODE || '';

if (!CLIENT_ID || !CLIENT_SECRET || !CODE) {
  console.error(
    'Usage: GOOGLE_CLIENT_ID=... GOOGLE_CLIENT_SECRET=... GOOGLE_AUTH_CODE=... node scripts/exchange_code.js'
  );
  process.exit(1);
}

const oauth2Client = new google.auth.OAuth2(
  CLIENT_ID,
  CLIENT_SECRET,
  'https://developers.google.com/oauthplayground'
);

async function run() {
  try {
    const { tokens } = await oauth2Client.getToken(CODE.trim());
    console.log('\n✅ SUCCESS! Fresh OAuth2 Refresh Token acquired:\n');
    console.log(`GOOGLE_REFRESH_TOKEN="${tokens.refresh_token}"\n`);
  } catch (err) {
    console.error('❌ Failed to exchange authorization code:', err.message);
  }
}

run();
