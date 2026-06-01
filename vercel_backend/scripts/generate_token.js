const { google } = require('googleapis');
const readline = require('readline');

// Instructions:
// 1. Go to Google Cloud Console (https://console.cloud.google.com)
// 2. Select your project.
// 3. Go to "APIs & Services" > "Credentials".
// 4. Click "Create Credentials" > "OAuth client ID".
// 5. Select "Desktop application" or "Web application", name it, and click "Create".
// 6. Copy your Client ID and Client Secret, and paste them below or pass them when running.

const CLIENT_ID = process.argv[2] || '';
const CLIENT_SECRET = process.argv[3] || '';

if (!CLIENT_ID || !CLIENT_SECRET) {
  console.log('\n❌ Error: Please provide your Client ID and Client Secret as arguments.');
  console.log('Usage: node scripts/generate_token.js <CLIENT_ID> <CLIENT_SECRET>\n');
  process.exit(1);
}

const oauth2Client = new google.auth.OAuth2(
  CLIENT_ID,
  CLIENT_SECRET,
  'https://developers.google.com/oauthplayground' // Redirect URI
);

const authUrl = oauth2Client.generateAuthUrl({
  access_type: 'offline',
  prompt: 'consent',
  scope: ['https://www.googleapis.com/auth/drive'],
});

console.log('\n🔑 Step 1: Open the following URL in your browser and authorize your 5TB account:');
console.log(`\n${authUrl}\n`);

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

rl.question('🔑 Step 2: After authorizing, you will be redirected to a URL. Copy the "code" query parameter from that URL and paste it here: ', async (code) => {
  rl.close();
  try {
    const { tokens } = await oauth2Client.getToken(code.trim());
    console.log('\n✅ Success! Here are your Vercel Environment Variables:\n');
    console.log(`GOOGLE_CLIENT_ID="${CLIENT_ID}"`);
    console.log(`GOOGLE_CLIENT_SECRET="${CLIENT_SECRET}"`);
    console.log(`GOOGLE_REFRESH_TOKEN="${tokens.refresh_token}"`);
    console.log('\nCopy these values and paste them into your Vercel Environment Variables dashboard!\n');
  } catch (error) {
    console.error('\n❌ Failed to generate refresh token:', error.message);
  }
});
