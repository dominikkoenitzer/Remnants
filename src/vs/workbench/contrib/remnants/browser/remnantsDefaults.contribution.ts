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
		// and the git branch, the menu bar appears when Alt is pressed ('compact'
		// would fold it into the hidden activity bar and lose it), and there is no
		// command center pill or minimap. The breadcrumb row stays as a quiet path bar.
		'workbench.activityBar.location': 'hidden',
		'window.menuBarVisibility': 'toggle',
		'window.commandCenter': false,
		'window.title': '${dirty}${rootName}${separator}${activeRepositoryBranchName}',
		'window.titleSeparator': '  /  ',
		'editor.minimap.enabled': false,
		'workbench.editor.tabSizing': 'shrink',
		'workbench.layoutControl.enabled': false,
		'editor.overviewRulerBorder': false,
		'editor.hideCursorInOverviewRuler': true,

		// Start straight into the work: no welcome page or recommendation prompts.
		// The empty editor keeps its shortcut hints.
		'workbench.startupEditor': 'none',
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

		// Type: the same monospace family as the interface (remnants.css). The
		// terminal prefers a Nerd Font when one is installed so prompt glyphs render.
		'editor.fontFamily': '\'Cascadia Code\', \'JetBrains Mono\', \'SF Mono\', Menlo, \'DejaVu Sans Mono\', Consolas, monospace',
		'editor.fontSize': 15,
		'terminal.integrated.fontFamily': '\'JetBrainsMono Nerd Font\', \'JetBrainsMono NF\', \'JetBrainsMonoNL Nerd Font\', \'CaskaydiaCove Nerd Font\', \'Cascadia Mono\', Consolas, monospace',
		'terminal.integrated.fontSize': 14,
		'terminal.integrated.lineHeight': 1.2,

		// A calm panel: icons instead of a row of view names, and no command
		// status dots in the terminal gutter.
		'workbench.panel.showLabels': false,
		'terminal.integrated.shellIntegration.decorationsEnabled': 'never',

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
