#!/usr/bin/env node

// Reports the byte size of each <script> and <style> element in an HTML bundle file.

import { readFileSync } from 'fs'
import { resolve } from 'path'

const filePath = process.argv[2]
if (!filePath) {
  console.error('Usage: node scripts/bundle-size-report.js <path-to-html>')
  process.exit(1)
}

const html = readFileSync(resolve(filePath), 'utf8')
const fileBytes = Buffer.byteLength(html, 'utf8')

const pattern = /<(script|style)(\s[^>]*)?>[\s\S]*?<\/\1>/gi
const results = []

let match
while ((match = pattern.exec(html)) !== null) {
  const tag = match[1].toLowerCase()
  const attrs = (match[2] || '').trim()
  const full = match[0]
  const bytes = Buffer.byteLength(full, 'utf8')

  // Count whitespace bytes in the inner content only (between open and close tags)
  const innerMatch = full.match(/^<[^>]+>([\s\S]*)<\/\w+>$/)
  const inner = innerMatch ? innerMatch[1] : ''
  const wsBytes = Buffer.byteLength(inner.replace(/[^\s]/g, ''), 'utf8')

  let label = `<${tag}>`
  const srcMatch = attrs.match(/src=["']([^"']+)["']/)
  const idMatch  = attrs.match(/id=["']([^"']+)["']/)
  if (srcMatch) {
    label = `<${tag} src="${srcMatch[1]}">`
  } else if (idMatch) {
    label = `<${tag}> ${idMatch[1]}`
  } else if (attrs) {
    label = `<${tag} ${attrs}>`
  }

  results.push({ tag, label, bytes, wsBytes })
}

results.sort((a, b) => b.bytes - a.bytes)

const totalBytes = results.reduce((sum, r) => sum + r.bytes, 0)
const totalWs = results.reduce((sum, r) => sum + r.wsBytes, 0)
const pad = (s, n) => String(s).padStart(n)
const fmt = (n) => n.toLocaleString()

console.log(`\nBundle size report: ${filePath}\n`)
console.log(`${'Bytes'.padStart(12)}  ${'% of total'.padStart(10)}  ${'Whitespace'.padStart(12)}  ${'WS %'.padStart(6)}  Element`)
console.log('-'.repeat(90))

for (const { label, bytes, wsBytes } of results) {
  const pct = ((bytes / totalBytes) * 100).toFixed(1).padStart(10)
  const wsPct = bytes > 0 ? ((wsBytes / bytes) * 100).toFixed(1).padStart(6) : '   n/a'
  console.log(`${pad(fmt(bytes), 12)}  ${pct}  ${pad(fmt(wsBytes), 12)}  ${wsPct}  ${label}`)
}

const otherBytes = fileBytes - totalBytes
const fileWsBytes = Buffer.byteLength(html.replace(/[^\s]/g, ''), 'utf8')
const otherWsBytes = fileWsBytes - totalWs

const wsPct = (ws, total) => total > 0 ? ((ws / total) * 100).toFixed(1).padStart(6) : ''.padStart(6)

console.log('-'.repeat(90))
console.log(`${pad(fmt(totalBytes), 12)}  ${pad(((totalBytes / fileBytes) * 100).toFixed(1), 10)}  ${pad(fmt(totalWs), 12)}  ${wsPct(totalWs, totalBytes)}  TOTAL (${results.length} elements)`)
console.log(`${pad(fmt(otherBytes), 12)}  ${pad(((otherBytes / fileBytes) * 100).toFixed(1), 10)}  ${pad(fmt(otherWsBytes), 12)}  ${wsPct(otherWsBytes, otherBytes)}  other (HTML markup, etc.)`)
console.log(`${pad(fmt(fileBytes), 12)}  ${'100.0'.padStart(10)}  ${pad(fmt(fileWsBytes), 12)}  ${wsPct(fileWsBytes, fileBytes)}  FILE TOTAL`)
console.log()
