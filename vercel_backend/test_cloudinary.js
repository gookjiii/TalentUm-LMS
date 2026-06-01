const cloudinary = require('cloudinary').v2;
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables from .env.production
dotenv.config({ path: path.join(__dirname, '.env.production') });

async function test() {
  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;

  console.log('Credentials:', { cloudName, apiKey, apiSecret: !!apiSecret });

  if (cloudName && apiKey && apiSecret) {
    cloudinary.config({
      cloud_name: cloudName,
      api_key: apiKey,
      api_secret: apiSecret,
    });
    try {
      const usage = await cloudinary.api.usage();
      console.log('Full Cloudinary Usage Response:', JSON.stringify(usage, null, 2));
    } catch (e) {
      console.error('Error calling Cloudinary API:', e);
    }
  } else {
    console.error('Missing credentials');
  }
}

test();
