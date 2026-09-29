/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { URI } from '../../../../base/common/uri.js';

/**
 * GitHub REST and GraphQL endpoints, derived from an optional GitHub Enterprise
 * base URI. All values are string URIs with no trailing slash.
 */
export interface IGitHubEndpoints {
	/** REST API base (e.g. `https://api.github.com`). */
	readonly apiBaseUri: string;
	/** GraphQL endpoint (distinct from `apiBaseUri` for on-prem: `/api/graphql`, not `/api/v3/graphql`). */
	readonly graphQlUri: string;
	/** OAuth authorization server URI. */
	readonly oauthServer: string;
	/** The configured GitHub Enterprise host (authority only), or `undefined` for github.com. */
	readonly enterpriseHost: string | undefined;
}

/** Canonical github.com endpoints, used when no enterprise URI is configured. */
const GITHUB_DOT_COM_ENDPOINTS: IGitHubEndpoints = {
	apiBaseUri: 'https://api.github.com',
	graphQlUri: 'https://api.github.com/graphql',
	oauthServer: 'https://github.com/login/oauth',
	enterpriseHost: undefined,
};

/**
 * Derives the {@link IGitHubEndpoints} for a GitHub Enterprise base URI, mirroring
 * the URL derivation in the built-in `github-authentication` extension:
 *
 * - unset, empty or unparseable: github.com defaults.
 * - GitHub Enterprise Cloud (authority ends in `.ghe.com`): API on an `api.` subdomain.
 * - GitHub Enterprise Server (on-prem): API under `/api/v3`, GraphQL under `/api/graphql`.
 */
export function deriveGitHubEndpoints(enterpriseUri: string | undefined): IGitHubEndpoints {
	if (!enterpriseUri) {
		return GITHUB_DOT_COM_ENDPOINTS;
	}

	let uri: URI;
	try {
		uri = URI.parse(enterpriseUri);
	} catch {
		return GITHUB_DOT_COM_ENDPOINTS;
	}

	const authority = uri.authority;
	if (!authority) {
		return GITHUB_DOT_COM_ENDPOINTS;
	}

	// A github.com authority is never a GitHub Enterprise host; treat it as the
	// default rather than deriving a nonsensical `github.com/api/v3`. Guards the
	// case where the enterprise host can't be resolved and falls back to github.com.
	if (authority === 'github.com' || authority === 'www.github.com' || authority === 'api.github.com') {
		return GITHUB_DOT_COM_ENDPOINTS;
	}

	const scheme = uri.scheme || 'https';
	const isCloud = /\.ghe\.com$/.test(authority);
	return {
		apiBaseUri: isCloud ? `${scheme}://api.${authority}` : `${scheme}://${authority}/api/v3`,
		graphQlUri: isCloud ? `${scheme}://api.${authority}/graphql` : `${scheme}://${authority}/api/graphql`,
		oauthServer: `${scheme}://${authority}/login/oauth`,
		enterpriseHost: authority,
	};
}
