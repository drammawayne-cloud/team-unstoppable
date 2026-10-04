import { readFile } from 'node:fs/promises';
import { auditEquipment } from './equipment-readiness.mjs';
const root = new URL('../', import.meta.url);
const catalog = JSON.parse(await readFile(new URL('public/equipment-catalog.json', root)));
const evidence = JSON.parse(await readFile(new URL('data/pro-audio-sourcing.private.json', root)));
const report = auditEquipment(catalog, evidence);
console.log(JSON.stringify(report, null, 2));
process.exitCode = report.status === 'INVALID' ? 1 : report.status === 'READY' ? 0 : 2;
