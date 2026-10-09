/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { Registry } from '../../../../platform/registry/common/platform.js';
import { Extensions as ConfigurationExtensions, IConfigurationRegistry } from '../../../../platform/configuration/common/configurationRegistry.js';

// Remnants defaults: a quiet, fast editor out of the box. These are *default*
// overrides only; any value the user sets in their own settings still wins.
// Keep this list small, deliberate, and reversible.
Registry.as<IConfigurationRegistry>(ConfigurationExtensions.Configuration).registerDefaultConfigurations([{
	overrides: {
		// Quiet chrome. The activity bar is hidden; its views are switched from the
		// status bar dock (remnantsDock.contribution.ts). The title shows the folder
		// and the git branch, the menu folds into one button, and there is no
		// command center pill, minimap, or separate breadcrumb row.
		'workbench.activityBar.location': 'hidden',
		'window.menuBarVisibility': 'compact',
		'window.commandCenter': false,
		'window.title': '${dirty}${rootName}${separator}${activeRepositoryBranchName}',
		'editor.minimap.enabled': false,
		'breadcrumbs.enabled': false,
		'workbench.editor.tabSizing': 'shrink',
		'workbench.layoutControl.enabled': false,
		'editor.overviewRulerBorder': false,
		'editor.hideCursorInOverviewRuler': true,

		// Start straight into the work: no welcome page, tips, or recommendation prompts.
		'workbench.startupEditor': 'none',
		'workbench.tips.enabled': false,
		'extensions.ignoreRecommendations': true,

		// Dense and flat: no floating cards or gaps between the parts, compact tabs.
		'workbench.experimental.modernUI': false,
		'window.density.editorTabHeight': 'compact',

		// Instant response: scrolling and the caret move without easing.
		'editor.smoothScrolling': false,
		'workbench.list.smoothScrolling': false,
		'terminal.integrated.smoothScrolling': false,
		'editor.cursorSmoothCaretAnimation': 'off',
		'editor.cursorBlinking': 'phase',

		// Roomy typography and spacing.
		'editor.lineHeight': 1.6,
		'editor.fontLigatures': true,
		'editor.padding.top': 8,
		'editor.guides.bracketPairs': 'active',

		// Slimmer scrollbars and a tighter tree indent.
		'editor.scrollbar.verticalScrollbarSize': 10,
		'editor.scrollbar.horizontalScrollbarSize': 10,
		'workbench.tree.indent': 14,

		// Less background work: dependency and build output folders are not watched,
		// search does not follow symlinks, and hovering a package does not fetch
		// its details online.
		'files.watcherExclude': {
			'.git/objects/**': true,
			'.git/subtree-cache/**': true,
			'.hg/store/**': true,
			'*/.git/objects/**': true,
			'*/.git/subtree-cache/**': true,
			'*/.hg/store/**': true,
			'**/node_modules/**': true,
			'**/target/**': true,
		},
		'search.followSymlinks': false,
		'npm.fetchOnlinePackageInfo': false,
	}
}]);
