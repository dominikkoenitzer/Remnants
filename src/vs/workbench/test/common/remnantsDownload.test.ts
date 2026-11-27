/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import assert from 'assert';
import { ensureNoDisposablesAreLeakedInTestSuite } from '../../../base/test/common/utils.js';
import { getMacDownloadUrl } from '../../common/remnantsDownload.js';

suite('remnantsDownload', () => {
	ensureNoDisposablesAreLeakedInTestSuite();

	suite('getMacDownloadUrl', () => {

		test('is the download address plus /download/mac, path kept', () => {
			assert.strictEqual(getMacDownloadUrl('https://downloads.example.com/get/remnants'), 'https://downloads.example.com/get/remnants/download/mac');
			assert.strictEqual(getMacDownloadUrl('https://downloads.example.com/get/remnants/?from=app#top'), 'https://downloads.example.com/get/remnants/download/mac');
			assert.strictEqual(getMacDownloadUrl('https://downloads.example.com'), 'https://downloads.example.com/download/mac');
		});

		test('is never the Windows ARM page', () => {
			assert.ok(!getMacDownloadUrl('https://downloads.example.com/get/remnants')!.includes('windows'));
		});

		test('is nothing without an https download address', () => {
			for (const value of [undefined, '', 'downloads.example.com', 'http://downloads.example.com', 'file:///C:/remnants', 'https://']) {
				assert.strictEqual(getMacDownloadUrl(value), undefined, value);
			}
		});
	});
});
