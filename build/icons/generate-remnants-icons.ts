/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

// Generate every Remnants app-icon asset from the single vector source
// (resources/remnants-icon.svg). Rasterizes with headless Chromium via the
// Playwright that already ships in devDependencies, then hand-packs ICO/ICNS
// (no ImageMagick / sharp / iconutil needed).
//
//   node build/icons/generate-remnants-icons.ts
//
// If Chromium is missing, run:  npx playwright install chromium
import { chromium } from 'playwright';
import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const svg = readFileSync(join(root, 'resources', 'remnants-icon.svg'), 'utf8');

// Every distinct pixel size any target needs.
const SIZES = [16, 24, 32, 48, 64, 70, 128, 150, 192, 256, 512, 1024];

const sizedSvg = (n: number) => svg.replace(/width="512"/, `width="${n}"`).replace(/height="512"/, `height="${n}"`);

// Playwright's bundled browser revision can lag the cache; fall back to any
// full Chromium present under the ms-playwright cache.
function findChromium(): string | undefined {
	const base = process.platform === 'win32'
		? join(process.env.LOCALAPPDATA || join(homedir(), 'AppData', 'Local'), 'ms-playwright')
		: join(homedir(), process.platform === 'darwin' ? 'Library/Caches/ms-playwright' : '.cache/ms-playwright');
	if (!existsSync(base)) { return undefined; }
	const rel = process.platform === 'win32' ? 'chrome-win/chrome.exe'
		: process.platform === 'darwin' ? 'Chromium.app/Contents/MacOS/Chromium' : 'chrome-linux/chrome';
	for (const dir of readdirSync(base).filter(d => d.startsWith('chromium-')).sort().reverse()) {
		const exe = join(base, dir, rel);
		if (existsSync(exe)) { return exe; }
	}
	return undefined;
}

const png: Record<number, Buffer> = {};
let browser;
try {
	browser = await chromium.launch();
} catch {
	browser = await chromium.launch({ executablePath: findChromium() });
}
try {
	for (const n of SIZES) {
		const page = await browser.newPage({ viewport: { width: n, height: n }, deviceScaleFactor: 1 });
		await page.setContent(`<!doctype html><meta charset=utf8><style>*{margin:0;padding:0}html,body{background:transparent}</style>${sizedSvg(n)}`, { waitUntil: 'load' });
		png[n] = await page.screenshot({ omitBackground: true, clip: { x: 0, y: 0, width: n, height: n } });
		await page.close();
	}
} finally {
	await browser.close();
}

// ---- ICO (PNG-embedded; Windows Vista+) ----
function buildIco(sizes: number[]): Buffer {
	const header = Buffer.alloc(6);
	header.writeUInt16LE(1, 2);
	header.writeUInt16LE(sizes.length, 4);
	const dir = Buffer.alloc(16 * sizes.length);
	let offset = 6 + 16 * sizes.length;
	const blobs: Buffer[] = [];
	sizes.forEach((n, i) => {
		const b = i * 16, data = png[n];
		dir.writeUInt8(n >= 256 ? 0 : n, b);
		dir.writeUInt8(n >= 256 ? 0 : n, b + 1);
		dir.writeUInt16LE(1, b + 4);
		dir.writeUInt16LE(32, b + 6);
		dir.writeUInt32LE(data.length, b + 8);
		dir.writeUInt32LE(offset, b + 12);
		offset += data.length;
		blobs.push(data);
	});
	return Buffer.concat([header, dir, ...blobs]);
}

// ---- ICNS (PNG-embedded; macOS 10.7+) ----
function buildIcns(map: Record<string, number>): Buffer {
	const chunks = Object.entries(map).map(([type, n]) => {
		const data = png[n], head = Buffer.alloc(8);
		head.write(type, 0, 'ascii');
		head.writeUInt32BE(8 + data.length, 4);
		return Buffer.concat([head, data]);
	});
	const body = Buffer.concat(chunks), head = Buffer.alloc(8);
	head.write('icns', 0, 'ascii');
	head.writeUInt32BE(8 + body.length, 4);
	return Buffer.concat([head, body]);
}

const out = (...p: string[]) => join(root, 'resources', ...p);
writeFileSync(out('win32', 'code.ico'), buildIco([16, 24, 32, 48, 64, 128, 256]));
writeFileSync(out('win32', 'code_70x70.png'), png[70]);
writeFileSync(out('win32', 'code_150x150.png'), png[150]);
writeFileSync(out('linux', 'code.png'), png[512]);
writeFileSync(out('server', 'code-192.png'), png[192]);
writeFileSync(out('server', 'code-512.png'), png[512]);
writeFileSync(out('server', 'favicon.ico'), buildIco([16, 32, 48]));
writeFileSync(out('darwin', 'code.icns'), buildIcns({ icp4: 16, icp5: 32, icp6: 64, ic07: 128, ic08: 256, ic09: 512, ic10: 1024 }));

console.log('Remnants icons generated from resources/remnants-icon.svg');
