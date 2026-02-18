/**
 * Local CORS Proxy for Flutter Web Development
 * 
 * This proxy forwards requests from localhost to the backend APIs,
 * adding the required CORS headers so the browser doesn't block them.
 * 
 * Usage:
 *   node cors_proxy.js
 * 
 * Then update ApiConfig to use http://localhost:8080 as the base URL.
 * 
 * Install dependency first:
 *   npm install http-proxy
 */

const http = require('http');
const https = require('https');
const url = require('url');

const PROXY_PORT = 8080;

// Map of proxy paths to target hosts
const TARGETS = {
  '/api-chatbot/': 'https://api-chatbot.fuzionest.com',
  '/chatbot/':     'https://chatbot.fuzionest.com',
};

const CORS_HEADERS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type, Accept',
  'Access-Control-Max-Age':       '86400',
};

const server = http.createServer((req, res) => {
  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, CORS_HEADERS);
    res.end();
    return;
  }

  // Find matching target
  let targetBase = null;
  let strippedPath = req.url;

  for (const [prefix, target] of Object.entries(TARGETS)) {
    if (req.url.startsWith(prefix)) {
      targetBase = target;
      strippedPath = req.url.slice(prefix.length - 1); // keep leading /
      break;
    }
  }

  if (!targetBase) {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end(`CORS Proxy: No route for ${req.url}\nAvailable prefixes: ${Object.keys(TARGETS).join(', ')}`);
    return;
  }

  const parsed = url.parse(targetBase);
  const options = {
    hostname: parsed.hostname,
    port: parsed.port || 443,
    path: strippedPath,
    method: req.method,
    headers: {
      ...req.headers,
      host: parsed.hostname,
    },
  };

  console.log(`[PROXY] ${req.method} ${req.url} → ${targetBase}${strippedPath}`);

  const proxyReq = https.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, {
      ...proxyRes.headers,
      ...CORS_HEADERS,
    });
    proxyRes.pipe(res, { end: true });
  });

  proxyReq.on('error', (err) => {
    console.error('[PROXY ERROR]', err.message);
    res.writeHead(502, CORS_HEADERS);
    res.end(`Proxy error: ${err.message}`);
  });

  req.pipe(proxyReq, { end: true });
});

server.listen(PROXY_PORT, () => {
  console.log(`\n✅ CORS Proxy running on http://localhost:${PROXY_PORT}`);
  console.log('\nRoutes:');
  for (const [prefix, target] of Object.entries(TARGETS)) {
    console.log(`  http://localhost:${PROXY_PORT}${prefix}  →  ${target}`);
  }
  console.log('\nNow run Flutter with:');
  console.log('  flutter run -d chrome\n');
});
