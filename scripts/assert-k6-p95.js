#!/usr/bin/env node
const fs = require('fs');

const args = require('minimist')(process.argv.slice(2));
const max = Number(args.max || 300);
const reportFile = 'k6-summary.json'; // ensure your k6 run writes this

if (!fs.existsSync(reportFile)) {
  console.error(`k6 report not found: ${reportFile}`);
  process.exit(1);
}
const report = JSON.parse(fs.readFileSync(reportFile, 'utf8'));

// Adjust parsing to your k6 output format:
const p95 = report.metrics && (report.metrics.http_req_duration?.p(95) || report.metrics.http_req_duration?.percentiles?.p95);
if (!p95) {
  console.error('Could not find p95 in k6 report.');
  process.exit(1);
}

console.log(`k6 p95: ${p95} ms (max ${max} ms)`);
if (p95 > max) {
  console.error('Performance budget failed.');
  process.exit(1);
}
console.log('Performance budget passed.');