/**
 * Production server: serves dist/ and proxies /api/alerts to Pikud HaOref.
 * Run: node server.js
 * Then open: http://localhost:8080
 */

const http = require('http')
const https = require('https')
const fs = require('fs')
const path = require('path')

const PORT = process.env.PORT || 8080
const DIST = path.join(__dirname, 'dist')

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript',
  '.css':  'text/css',
  '.json': 'application/json',
  '.png':  'image/png',
  '.ico':  'image/x-icon',
  '.mp3':  'audio/mpeg',
  '.svg':  'image/svg+xml',
}

function serveFile(res, filePath) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404)
      res.end('Not found')
      return
    }
    const ext = path.extname(filePath)
    res.writeHead(200, { 'Content-Type': MIME[ext] ?? 'application/octet-stream' })
    res.end(data)
  })
}

function proxyAlerts(res) {
  const options = {
    hostname: 'www.oref.org.il',
    path: '/WarningMessages/alert/alerts.json',
    method: 'GET',
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'Referer': 'https://www.oref.org.il/',
      'User-Agent': 'Mozilla/5.0',
      'Accept': 'application/json',
    },
  }

  const req = https.request(options, (upstream) => {
    let body = ''
    upstream.on('data', chunk => { body += chunk })
    upstream.on('end', () => {
      res.writeHead(upstream.statusCode, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-store',
      })
      res.end(body)
    })
  })

  req.on('error', (err) => {
    res.writeHead(502)
    res.end(JSON.stringify({ error: err.message }))
  })

  req.setTimeout(4000, () => {
    req.destroy()
    res.writeHead(504)
    res.end(JSON.stringify({ error: 'timeout' }))
  })

  req.end()
}

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/api/alerts') {
    proxyAlerts(res)
    return
  }

  // Serve static files
  let urlPath = req.url.split('?')[0]
  if (urlPath === '/') urlPath = '/index.html'

  const filePath = path.join(DIST, urlPath)
  // Security: ensure we stay within DIST
  if (!filePath.startsWith(DIST)) {
    res.writeHead(403)
    res.end('Forbidden')
    return
  }

  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) {
      // SPA fallback
      serveFile(res, path.join(DIST, 'index.html'))
    } else {
      serveFile(res, filePath)
    }
  })
})

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Signage server running at http://localhost:${PORT}`)
  console.log(`Serving: ${DIST}`)
  console.log(`Pikud HaOref proxy: /api/alerts -> oref.org.il`)
})
