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

// Inno Setup wizard art (no transparency): the shard composited onto a solid
// background, one BMP per Windows DPI scale. The `.iss` references these exact
// sizes by name (WizardImageFile / WizardSmallImageFile), so reproduce them
// verbatim — only the artwork changes. `big` = the welcome/finish side panel
// (dark navy so the blue shard pops); `small` = the inner-page header logo
// (white, to sit seamlessly in the modern wizard's white header).
const INNO_BIG: Array<[number, number, number]> = [[100, 164, 314], [125, 192, 386], [150, 246, 459], [175, 273, 556], [200, 328, 604], [225, 355, 700], [250, 410, 797]];
const INNO_SMALL: Array<[number, number, number]> = [[100, 55, 55], [125, 64, 68], [150, 83, 80], [175, 92, 97], [200, 110, 106], [225, 119, 123], [250, 138, 140]];

// Tight crop of the shard's content bounds (the source pads it inside the
// 512px square) so it fills the wizard art instead of floating small.
const SHARD_VIEWBOX = '106 40 300 448';
const SHARD_ASPECT = 300 / 448;

const innoRgba: Record<string, { w: number; h: number; buf: Buffer }> = {};

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

	// Composite the shard onto each wizard background and read back raw RGBA
	// (Canvas getImageData) so we can hand-pack BMPs without a PNG decoder.
	async function renderComposite(w: number, h: number, mode: 'big' | 'small'): Promise<Buffer> {
		const dh = Math.round(h * (mode === 'big' ? 0.46 : 0.86));
		const dw = Math.round(dh * SHARD_ASPECT);
		const dx = Math.round((w - dw) / 2);
		const dy = Math.round((h - dh) / 2);
		// Rasterize the SVG at exactly the draw size so it stays crisp (no bitmap upscale).
		const shardSvg = svg
			.replace('viewBox="0 0 512 512"', `viewBox="${SHARD_VIEWBOX}"`)
			.replace('width="512"', `width="${dw}"`)
			.replace('height="512"', `height="${dh}"`);
		const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
		const b64 = await page.evaluate(async ({ w, h, dx, dy, dw, dh, shardSvg, mode }) => {
			const canvas = document.createElement('canvas');
			canvas.width = w; canvas.height = h;
			const ctx = canvas.getContext('2d')!;
			if (mode === 'big') {
				const g = ctx.createLinearGradient(0, 0, 0, h);
				g.addColorStop(0, '#0B1220'); g.addColorStop(1, '#1E293B');
				ctx.fillStyle = g;
			} else {
				ctx.fillStyle = '#FFFFFF';
			}
			ctx.fillRect(0, 0, w, h);
			const img = new Image();
			// encodeURIComponent (not btoa) so UTF-8 in the SVG, e.g. the em dash in
			// its comment, doesn't trip btoa's Latin1-only requirement.
			img.src = 'data:image/svg+xml;charset=utf8,' + encodeURIComponent(shardSvg);
			await new Promise((res, rej) => { img.onload = res; img.onerror = rej; });
			ctx.imageSmoothingEnabled = true; ctx.imageSmoothingQuality = 'high';
			ctx.drawImage(img, dx, dy, dw, dh);
			const data = ctx.getImageData(0, 0, w, h).data;
			let bin = ''; const chunk = 0x8000;
			for (let i = 0; i < data.length; i += chunk) { bin += String.fromCharCode.apply(null, data.subarray(i, i + chunk) as unknown as number[]); }
			return btoa(bin);
		}, { w, h, dx, dy, dw, dh, shardSvg, mode });
		await page.close();
		return Buffer.from(b64, 'base64');
	}

	for (const [pct, w, h] of INNO_BIG) { innoRgba[`inno-big-${pct}`] = { w, h, buf: await renderComposite(w, h, 'big') }; }
	for (const [pct, w, h] of INNO_SMALL) { innoRgba[`inno-small-${pct}`] = { w, h, buf: await renderComposite(w, h, 'small') }; }
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

// ---- BMP (24-bit, uncompressed, bottom-up — what Inno Setup wants) ----
function buildBmp24(width: number, height: number, rgba: Buffer): Buffer {
	const rowSize = Math.ceil((width * 3) / 4) * 4; // rows padded to 4 bytes
	const imageSize = rowSize * height;
	const buf = Buffer.alloc(54 + imageSize);
	buf.write('BM', 0, 'ascii');
	buf.writeUInt32LE(54 + imageSize, 2);
	buf.writeUInt32LE(54, 10); // pixel data offset
	buf.writeUInt32LE(40, 14); // BITMAPINFOHEADER size
	buf.writeInt32LE(width, 18);
	buf.writeInt32LE(height, 22); // positive height => bottom-up
	buf.writeUInt16LE(1, 26); // planes
	buf.writeUInt16LE(24, 28); // bits per pixel
	buf.writeUInt32LE(imageSize, 34);
	buf.writeInt32LE(2835, 38); // ~72 DPI (pixels/metre)
	buf.writeInt32LE(2835, 42);
	for (let y = 0; y < height; y++) {
		const srcY = height - 1 - y; // bottom-up
		let dst = 54 + y * rowSize;
		for (let x = 0; x < width; x++) {
			const s = (srcY * width + x) * 4;
			buf[dst++] = rgba[s + 2]; // B
			buf[dst++] = rgba[s + 1]; // G
			buf[dst++] = rgba[s];     // R
		}
	}
	return buf;
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

// Default file-association icon (shown for files opened with Remnants and in
// "Open with") — use the shard so no stray Code-OSS mark survives.
writeFileSync(out('win32', 'default.ico'), buildIco([16, 24, 32, 48, 64, 128, 256]));

// Inno Setup wizard bitmaps (installer welcome/finish panel + header logo).
for (const [name, { w, h, buf }] of Object.entries(innoRgba)) {
	writeFileSync(out('win32', `${name}.bmp`), buildBmp24(w, h, buf));
}

console.log('Remnants icons generated from resources/remnants-icon.svg');
