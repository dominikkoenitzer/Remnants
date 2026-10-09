/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

// Reads every package.json inside a packaged node_modules.asar and fails when one
// does not parse. A broken archive writer misplaces file contents (asar 3.2.0 did:
// package.json entries held license text), the app then dies at startup, and a
// `--version` smoke test never notices because it does not load node modules.
//
// Usage: node build/verify-asar.ts <path to node_modules.asar>

import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const asar: { listPackage(archive: string, options?: object): string[]; extractFile(archive: string, filename: string): Buffer } = require('@electron/asar');

const archive = process.argv[2];
if (!archive) {
	console.error('Usage: node build/verify-asar.ts <path to node_modules.asar>');
	process.exit(2);
}

const manifests = asar.listPackage(archive).filter(entry => /[\\/]package\.json$/.test(entry));
const broken: string[] = [];
for (const entry of manifests) {
	const relative = entry.replace(/^[\\/]/, '');
	try {
		JSON.parse(asar.extractFile(archive, relative).toString('utf8'));
	} catch {
		broken.push(relative);
	}
}

if (manifests.length === 0) {
	console.error(`${archive}: no package.json entries found`);
	process.exit(1);
}
if (broken.length > 0) {
	console.error(`${archive}: ${broken.length} of ${manifests.length} package.json entries do not parse, first: ${broken.slice(0, 5).join(', ')}`);
	process.exit(1);
}
console.log(`${archive}: all ${manifests.length} package.json entries parse`);
