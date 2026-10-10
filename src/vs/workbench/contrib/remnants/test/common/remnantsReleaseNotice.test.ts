/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import assert from 'assert';
import { ensureNoDisposablesAreLeakedInTestSuite } from '../../../../../base/test/common/utils.js';
import { CHECK_INTERVAL, compareVersions, getDownloadSite, getLatestReleaseUrl, isCheckAllowed, isCheckDue, parseLatestRelease, shouldNotify } from '../../common/remnantsReleaseNotice.js';

suite('remnantsReleaseNotice', () => {
	ensureNoDisposablesAreLeakedInTestSuite();

	suite('compareVersions', () => {

		function sign(a: string, b: string): number | undefined {
			const result = compareVersions(a, b);
			return result === undefined ? undefined : Math.sign(result);
		}

		test('equal versions', () => {
			assert.strictEqual(sign('1.139.1', '1.139.1'), 0);
			assert.strictEqual(sign('v1.139.1', '1.139.1'), 0);
			assert.strictEqual(sign(' 1.139.1\n', '1.139.1'), 0);
		});

		test('tolerates a leading v on either side', () => {
			assert.strictEqual(sign('v1.140.0', '1.139.1'), 1);
			assert.strictEqual(sign('V1.140.0', '1.139.1'), 1);
			assert.strictEqual(sign('1.139.1', 'v1.140.0'), -1);
		});

		test('compares major, minor and patch numerically', () => {
			assert.strictEqual(sign('2.0.0', '1.999.999'), 1);
			assert.strictEqual(sign('1.140.0', '1.99.0'), 1);
			assert.strictEqual(sign('1.139.10', '1.139.9'), 1);
			assert.strictEqual(sign('1.139.0', '1.139.1'), -1);
		});

		test('a fork suffix sorts after the plain version of the same base', () => {
			assert.strictEqual(sign('v1.125.0-remnants.1', '1.125.0'), 1);
			assert.strictEqual(sign('1.125.0', 'v1.125.0-remnants.1'), -1);
			assert.strictEqual(sign('v1.126.0', '1.125.0-remnants.3'), 1);
			assert.strictEqual(sign('v1.124.9-remnants.3', '1.125.0'), -1);
		});

		test('suffixes compare part by part', () => {
			assert.strictEqual(sign('1.125.0-remnants.2', '1.125.0-remnants.1'), 1);
			assert.strictEqual(sign('1.125.0-remnants.10', '1.125.0-remnants.9'), 1);
			assert.strictEqual(sign('1.125.0-remnants.1', '1.125.0-remnants.1'), 0);
			assert.strictEqual(sign('1.125.0-remnants', '1.125.0-remnants.1'), -1);
			assert.strictEqual(sign('1.125.0-1', '1.125.0-a'), -1);
			assert.strictEqual(sign('1.125.0-beta', '1.125.0-alpha'), 1);
		});

		test('ignores build metadata', () => {
			assert.strictEqual(sign('1.140.0+abc', '1.140.0'), 0);
			assert.strictEqual(sign('v1.140.0-remnants.1+abc', '1.140.0-remnants.1'), 0);
		});

		test('returns undefined for anything that is not a version', () => {
			for (const value of ['', 'latest', '1.140', '1.140.0.1', '1.140.0-', 'x1.140.0', 'v', '1.140.0-a..b']) {
				assert.strictEqual(compareVersions(value, '1.139.1'), undefined, value);
				assert.strictEqual(compareVersions('1.139.1', value), undefined, value);
			}
		});
	});

	suite('shouldNotify', () => {

		test('notifies for a newer release', () => {
			assert.strictEqual(shouldNotify('v1.140.0', '1.139.1', undefined), true);
		});

		test('stays quiet for the same or an older release', () => {
			assert.strictEqual(shouldNotify('v1.139.1', '1.139.1', undefined), false);
			assert.strictEqual(shouldNotify('v1.125.0', '1.139.1', undefined), false);
		});

		test('stays quiet for a tag that is not a version', () => {
			assert.strictEqual(shouldNotify('nightly', '1.139.1', undefined), false);
		});

		test('stays quiet for a rebuild of the running base, which may be the build already installed', () => {
			assert.strictEqual(shouldNotify('v1.139.1-remnants.1', '1.139.1', undefined), false);
			assert.strictEqual(shouldNotify('v1.140.0-remnants.1', '1.139.1', undefined), true);
		});

		test('a dismissed tag stays dismissed', () => {
			assert.strictEqual(shouldNotify('v1.140.0', '1.139.1', 'v1.140.0'), false);
		});

		test('the next release shows again after a dismissal', () => {
			assert.strictEqual(shouldNotify('v1.141.0', '1.139.1', 'v1.140.0'), true);
			assert.strictEqual(shouldNotify('v1.140.0-remnants.1', '1.139.1', 'v1.140.0'), true);
		});
	});

	suite('isCheckDue', () => {

		const now = Date.UTC(2026, 9, 1, 12, 0, 0);

		test('due when there was no check yet', () => {
			assert.strictEqual(isCheckDue(undefined, now), true);
			assert.strictEqual(isCheckDue(NaN, now), true);
		});

		test('not due within a day of the last check', () => {
			assert.strictEqual(isCheckDue(now, now), false);
			assert.strictEqual(isCheckDue(now - 60 * 1000, now), false);
			assert.strictEqual(isCheckDue(now - CHECK_INTERVAL + 1, now), false);
		});

		test('due once a day has passed', () => {
			assert.strictEqual(isCheckDue(now - CHECK_INTERVAL, now), true);
			assert.strictEqual(isCheckDue(now - 7 * CHECK_INTERVAL, now), true);
		});

		test('due when the last check lies in the future', () => {
			assert.strictEqual(isCheckDue(now + 60 * 1000, now), true);
		});
	});

	suite('isCheckAllowed', () => {

		test('off unless the setting is on', () => {
			assert.strictEqual(isCheckAllowed(false, 'default'), false);
			assert.strictEqual(isCheckAllowed(undefined, 'default'), false);
			assert.strictEqual(isCheckAllowed('true', 'default'), false);
		});

		test('on with update.mode default or start', () => {
			assert.strictEqual(isCheckAllowed(true, 'default'), true);
			assert.strictEqual(isCheckAllowed(true, 'start'), true);
			assert.strictEqual(isCheckAllowed(true, undefined), true);
		});

		test('update.mode none or manual suppresses the check', () => {
			assert.strictEqual(isCheckAllowed(true, 'none'), false);
			assert.strictEqual(isCheckAllowed(true, 'manual'), false);
			assert.strictEqual(isCheckAllowed(false, 'none'), false);
		});
	});

	suite('getDownloadSite', () => {

		test('reads the origin of an https download URL', () => {
			assert.strictEqual(getDownloadSite('https://downloads.example.com'), 'https://downloads.example.com');
			assert.strictEqual(getDownloadSite('https://downloads.example.com/'), 'https://downloads.example.com');
			assert.strictEqual(getDownloadSite('https://downloads.example.com/remnants/?from=app#top'), 'https://downloads.example.com');
		});

		test('ignores anything that is not an https URL', () => {
			for (const value of [undefined, '', 'downloads.example.com', 'http://downloads.example.com', 'file:///C:/remnants', 'command:workbench.action.quit', 'https://']) {
				assert.strictEqual(getDownloadSite(value), undefined, value);
			}
		});
	});

	test('getLatestReleaseUrl', () => {
		assert.strictEqual(getLatestReleaseUrl('https://downloads.example.com'), 'https://downloads.example.com/latest');
	});

	suite('parseLatestRelease', () => {

		test('reads the tag', () => {
			assert.deepStrictEqual(parseLatestRelease({ tag_name: 'v1.140.0', html_url: 'https://github.com/example-owner/Remnants/releases/tag/v1.140.0', draft: false }), { tag: 'v1.140.0' });
		});

		test('rejects responses without a tag', () => {
			for (const value of [null, undefined, 'v1.140.0', 42, {}, { tag_name: '' }, { tag_name: 1 }, { message: 'Not Found' }]) {
				assert.strictEqual(parseLatestRelease(value), undefined);
			}
		});
	});
});
