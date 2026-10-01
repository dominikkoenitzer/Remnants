/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

// The opt-in release notice: once a day, ask GitHub for the latest release of
// the repository the product points to and say so when it is newer than the
// running build. Everything here is pure so it can be tested without services.

export const CHECK_FOR_UPDATES_SETTING = 'remnants.checkForUpdates';
export const UPDATE_MODE_SETTING = 'update.mode';

export const LAST_CHECK_STORAGE_KEY = 'remnants.releaseNotice.lastCheck';
export const DISMISSED_TAG_STORAGE_KEY = 'remnants.releaseNotice.dismissedTag';

export const CHECK_INTERVAL = 24 * 60 * 60 * 1000;

export interface IGitHubRepository {
	readonly owner: string;
	readonly name: string;
}

export interface ILatestRelease {
	readonly tag: string;
	readonly htmlUrl: string | undefined;
}

/**
 * The check needs the setting turned on, and it stays off whenever
 * `update.mode` turns update checks off.
 */
export function isCheckAllowed(checkForUpdates: unknown, updateMode: unknown): boolean {
	return checkForUpdates === true && updateMode !== 'none' && updateMode !== 'manual';
}

/**
 * Due when there was no check yet, the last one is at least a day old, or the
 * stored time lies in the future because the clock was set back.
 */
export function isCheckDue(lastCheck: number | undefined, now: number): boolean {
	if (lastCheck === undefined || !Number.isFinite(lastCheck)) {
		return true;
	}
	return now < lastCheck || now - lastCheck >= CHECK_INTERVAL;
}

/**
 * Notify only for a release newer than the running build, and never again for
 * a tag the user dismissed. A later tag shows again.
 */
export function shouldNotify(tag: string, runningVersion: string, dismissedTag: string | undefined): boolean {
	if (tag === dismissedTag) {
		return false;
	}
	const result = compareVersions(tag, runningVersion);
	return result !== undefined && result > 0;
}

interface IParsedVersion {
	readonly core: readonly number[];
	readonly suffix: readonly string[];
}

const VERSION_PATTERN = /^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9a-z-]+(?:\.[0-9a-z-]+)*))?(?:\+[0-9a-z.-]*)?$/i;

function parseVersion(value: string): IParsedVersion | undefined {
	const match = VERSION_PATTERN.exec(value.trim());
	if (!match) {
		return undefined;
	}
	return {
		core: [Number(match[1]), Number(match[2]), Number(match[3])],
		suffix: match[4] ? match[4].split('.') : []
	};
}

/**
 * Compares versions such as `1.139.1`, `v1.140.0` or `v1.140.0-remnants.1` and
 * returns a negative number, zero or a positive number, or undefined when
 * either side is not a version.
 *
 * RELEASING.md tags a second build from the same upstream base with a suffix
 * (`v1.125.0-remnants.1`), so a suffixed version sorts after the plain one,
 * which is the opposite of a semver pre-release. Two suffixes compare part by
 * part, numbers numerically and before words.
 */
export function compareVersions(a: string, b: string): number | undefined {
	const left = parseVersion(a);
	const right = parseVersion(b);
	if (!left || !right) {
		return undefined;
	}
	for (let i = 0; i < left.core.length; i++) {
		if (left.core[i] !== right.core[i]) {
			return left.core[i] - right.core[i];
		}
	}
	for (let i = 0; i < Math.min(left.suffix.length, right.suffix.length); i++) {
		const result = compareIdentifiers(left.suffix[i], right.suffix[i]);
		if (result !== 0) {
			return result;
		}
	}
	return left.suffix.length - right.suffix.length;
}

function compareIdentifiers(a: string, b: string): number {
	const aIsNumber = /^\d+$/.test(a);
	const bIsNumber = /^\d+$/.test(b);
	if (aIsNumber && bIsNumber) {
		return Number(a) - Number(b);
	}
	if (aIsNumber !== bIsNumber) {
		return aIsNumber ? -1 : 1;
	}
	return a < b ? -1 : a > b ? 1 : 0;
}

const GITHUB_REPOSITORY_PATTERN = /^https:\/\/github\.com\/([a-z0-9-]+)\/([a-z0-9._-]+?)(?:\.git)?(?:[/?#]|$)/i;

/**
 * Reads owner and repository from a GitHub URL such as the product's
 * `reportIssueUrl`.
 */
export function parseGitHubRepository(url: string | undefined): IGitHubRepository | undefined {
	const match = url ? GITHUB_REPOSITORY_PATTERN.exec(url) : null;
	return match ? { owner: match[1], name: match[2] } : undefined;
}

export function getLatestReleaseApiUrl(repository: IGitHubRepository): string {
	return `https://api.github.com/repos/${repository.owner}/${repository.name}/releases/latest`;
}

/**
 * Picks the fields the notice needs from a GitHub release response.
 */
export function parseLatestRelease(value: unknown): ILatestRelease | undefined {
	if (!value || typeof value !== 'object') {
		return undefined;
	}
	const release = value as { tag_name?: unknown; html_url?: unknown };
	if (typeof release.tag_name !== 'string' || !release.tag_name) {
		return undefined;
	}
	return {
		tag: release.tag_name,
		htmlUrl: typeof release.html_url === 'string' ? release.html_url : undefined
	};
}

/**
 * The page "Open Release Page" opens. The response's `html_url` is used only
 * when it is a release page of the same repository; otherwise the tag page is
 * built from the tag.
 */
export function getReleasePageUrl(release: ILatestRelease, repository: IGitHubRepository): string {
	const releasesUrl = `https://github.com/${repository.owner}/${repository.name}/releases/`;
	if (release.htmlUrl?.startsWith(releasesUrl)) {
		return release.htmlUrl;
	}
	return `${releasesUrl}tag/${encodeURIComponent(release.tag)}`;
}
