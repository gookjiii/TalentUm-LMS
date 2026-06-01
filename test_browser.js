const puppeteer = require('puppeteer-core');
const http = require('http');

async function run() {
  try {
    const res = await new Promise((resolve) => {
      http.get('http://localhost:58812/json/version', resolve);
    });
    let data = '';
    for await (const chunk of res) data += chunk;
    const { webSocketDebuggerUrl } = JSON.parse(data);

    const browser = await puppeteer.connect({
      browserWSEndpoint: webSocketDebuggerUrl,
      defaultViewport: null
    });
    
    const pages = await browser.pages();
    for (const page of pages) {
      const url = page.url();
      console.log('Open page:', url);
      if (url.includes('localhost') || url.includes('flutter')) {
        console.log('Found Flutter app! Fetching console logs...');
        const messages = await page.evaluate(() => {
           // We can't retroactively fetch console logs easily without devtools protocol, 
           // but we can check if there are any unhandled errors stored in window.
           return window.__flutter_errors || 'No captured errors';
        });
        console.log('Window state:', messages);
      }
    }
    await browser.disconnect();
  } catch(e) {
    console.error(e);
  }
}
run();
