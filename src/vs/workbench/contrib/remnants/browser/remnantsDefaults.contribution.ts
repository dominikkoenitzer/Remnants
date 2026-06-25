/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { Registry } from '../../../../platform/registry/common/platform.js';
import { Extensions as ConfigurationExtensions, IConfigurationRegistry } from '../../../../platform/configuration/common/configurationRegistry.js';

// Remnants productized defaults — a minimal, focused out-of-the-box feel:
// quiet chrome, lots of breathing room, and smooth motion. These are *default*
// overrides only; any value the user sets in their own settings still wins.
// Keep this list small, tasteful, and reversible.
Registry.as<IConfigurationRegistry>(ConfigurationExtensions.Configuration).registerDefaultConfigurations([{
	overrides: {
		// Minimal chrome — drop the minimap and the separate breadcrumb row
		// (the file path already shows in the tab). The activity bar stays on
		// the left so the sidebar keeps its full height.
		'editor.minimap.enabled': false,
		'breadcrumbs.enabled': false,
		'workbench.editor.tabSizing': 'shrink',

		// Less clutter — no layout-toggle icons, quieter overview ruler.
		'workbench.layoutControl.enabled': false,
		'editor.overviewRulerBorder': false,
		'editor.hideCursorInOverviewRuler': true,

		// Buttery motion.
		'editor.smoothScrolling': true,
		'workbench.list.smoothScrolling': true,
		'terminal.integrated.smoothScrolling': true,
		'editor.cursorSmoothCaretAnimation': 'on',
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
	}
}]);
