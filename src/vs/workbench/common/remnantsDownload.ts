/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

// Where the product's download site is, for anything in the workbench that
// sends the user there. Kept in workbench/common so the window code may use it
// without reaching into a contribution.

/**
 * The https `downloadUrl` with its path, no query or trailing slash; undefined turns the notice off.
 */
export function getDownloadSite(downloadUrl: string | undefined): string | undefined {
	if (!downloadUrl) {
		return undefined;
	}
	let url: URL;
	try {
		url = new URL(downloadUrl);
	} catch {
		return undefined;
	}
	return url.protocol === 'https:' ? url.origin + url.pathname.replace(/\/+$/, '') : undefined;
}

/**
 * The page with the macOS download, for a build running under Rosetta. Undefined
 * when there is no https download site, so the button does nothing.
 */
export function getMacDownloadUrl(downloadUrl: string | undefined): string | undefined {
	const site = getDownloadSite(downloadUrl);
	return site ? `${site}/download/mac` : undefined;
}
