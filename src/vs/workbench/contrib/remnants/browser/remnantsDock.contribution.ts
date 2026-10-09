/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { Disposable } from '../../../../base/common/lifecycle.js';
import { themeColorFromId } from '../../../../base/common/themables.js';
import { localize } from '../../../../nls.js';
import { CommandsRegistry } from '../../../../platform/commands/common/commands.js';
import { ServicesAccessor } from '../../../../platform/instantiation/common/instantiation.js';
import { registerColor } from '../../../../platform/theme/common/colorUtils.js';
import { IWorkbenchContribution, registerWorkbenchContribution2, WorkbenchPhase } from '../../../common/contributions.js';
import { ViewContainerLocation } from '../../../common/views.js';
import { IWorkbenchLayoutService, Parts } from '../../../services/layout/browser/layoutService.js';
import { IPaneCompositePartService } from '../../../services/panecomposite/browser/panecomposite.js';
import { IStatusbarEntry, IStatusbarEntryAccessor, IStatusbarService, StatusbarAlignment } from '../../../services/statusbar/browser/statusbar.js';

// Remnants dock: the activity bar is hidden by default, so the status bar carries
// the view switches instead. Left: the side bar views. Right: terminal and settings.
// A switch sits on a soft accent pill while its view is showing; clicking a lit
// switch hides it again.

const DOCK_ACTIVE_FOREGROUND = registerColor('remnants.dockActiveForeground',
	{ dark: '#93C5FD', light: '#1D4ED8', hcDark: '#BFDBFE', hcLight: '#1E3A8A' },
	localize('remnants.dockActiveForeground', "Foreground of a status bar dock switch whose view is showing."));

const DOCK_ACTIVE_BACKGROUND = registerColor('remnants.dockActiveBackground',
	{ dark: '#3B82F633', light: '#2563EB1F', hcDark: '#60A5FA40', hcLight: '#1D4ED81F' },
	localize('remnants.dockActiveBackground', "Background of a status bar dock switch whose view is showing."));

interface IDockView {
	readonly containerId: string;
	readonly icon: string;
	readonly label: string;
}

const SIDE_BAR_VIEWS: readonly IDockView[] = [
	{ containerId: 'workbench.view.explorer', icon: 'files', label: localize('remnants.dock.explorer', "Explorer") },
	{ containerId: 'workbench.view.search', icon: 'search', label: localize('remnants.dock.search', "Search") },
	{ containerId: 'workbench.view.scm', icon: 'source-control', label: localize('remnants.dock.scm', "Source Control") },
	{ containerId: 'workbench.view.debug', icon: 'debug-alt', label: localize('remnants.dock.debug', "Run and Debug") },
	{ containerId: 'workbench.view.extensions', icon: 'extensions', label: localize('remnants.dock.extensions', "Extensions") },
];

const TOGGLE_SIDE_BAR_VIEW = 'remnants.dock.toggleSideBarView';
const TOGGLE_PANEL = 'remnants.dock.togglePanel';

CommandsRegistry.registerCommand(TOGGLE_SIDE_BAR_VIEW, async (accessor: ServicesAccessor, containerId: unknown) => {
	if (typeof containerId !== 'string') {
		return;
	}
	const layoutService = accessor.get(IWorkbenchLayoutService);
	const paneCompositeService = accessor.get(IPaneCompositePartService);
	const showing = layoutService.isVisible(Parts.SIDEBAR_PART)
		&& paneCompositeService.getActivePaneComposite(ViewContainerLocation.Sidebar)?.getId() === containerId;
	if (showing) {
		layoutService.setPartHidden(true, Parts.SIDEBAR_PART);
	} else {
		await paneCompositeService.openPaneComposite(containerId, ViewContainerLocation.Sidebar, true);
	}
});

CommandsRegistry.registerCommand(TOGGLE_PANEL, (accessor: ServicesAccessor) => {
	const layoutService = accessor.get(IWorkbenchLayoutService);
	layoutService.setPartHidden(layoutService.isVisible(Parts.PANEL_PART), Parts.PANEL_PART);
});

class RemnantsDockContribution extends Disposable implements IWorkbenchContribution {

	static readonly ID = 'workbench.contrib.remnantsDock';

	private readonly sideBarEntries = new Map<string, IStatusbarEntryAccessor>();
	private readonly panelEntry: IStatusbarEntryAccessor;

	constructor(
		@IStatusbarService statusbarService: IStatusbarService,
		@IWorkbenchLayoutService private readonly layoutService: IWorkbenchLayoutService,
		@IPaneCompositePartService private readonly paneCompositeService: IPaneCompositePartService,
	) {
		super();

		// Far left, in order: a higher priority sits further left.
		let priority = 100_000;
		for (const view of SIDE_BAR_VIEWS) {
			this.sideBarEntries.set(view.containerId, this._register(statusbarService.addEntry(this.sideBarEntry(view, false), `remnants.dock.${view.icon}`, StatusbarAlignment.LEFT, priority--)));
		}

		// Far right: a higher priority sits further right.
		this.panelEntry = this._register(statusbarService.addEntry(this.panelEntryFor(false), 'remnants.dock.panel', StatusbarAlignment.RIGHT, 100_001));
		this._register(statusbarService.addEntry({
			name: localize('remnants.dock.settings', "Settings"),
			text: '$(settings-gear)',
			ariaLabel: localize('remnants.dock.settings', "Settings"),
			tooltip: localize('remnants.dock.settings', "Settings"),
			command: 'workbench.action.openSettings',
		}, 'remnants.dock.settings', StatusbarAlignment.RIGHT, 100_000));

		this._register(this.layoutService.onDidChangePartVisibility(() => this.refresh()));
		this._register(this.paneCompositeService.onDidPaneCompositeOpen(() => this.refresh()));
		this._register(this.paneCompositeService.onDidPaneCompositeClose(() => this.refresh()));
		this.refresh();
	}

	private refresh(): void {
		const sideBarVisible = this.layoutService.isVisible(Parts.SIDEBAR_PART);
		const activeId = sideBarVisible ? this.paneCompositeService.getActivePaneComposite(ViewContainerLocation.Sidebar)?.getId() : undefined;
		for (const view of SIDE_BAR_VIEWS) {
			this.sideBarEntries.get(view.containerId)?.update(this.sideBarEntry(view, view.containerId === activeId));
		}
		this.panelEntry.update(this.panelEntryFor(this.layoutService.isVisible(Parts.PANEL_PART)));
	}

	private sideBarEntry(view: IDockView, active: boolean): IStatusbarEntry {
		return {
			name: view.label,
			text: `$(${view.icon})`,
			ariaLabel: view.label,
			tooltip: view.label,
			color: active ? themeColorFromId(DOCK_ACTIVE_FOREGROUND) : undefined,
			backgroundColor: active ? themeColorFromId(DOCK_ACTIVE_BACKGROUND) : undefined,
			command: { id: TOGGLE_SIDE_BAR_VIEW, title: view.label, arguments: [view.containerId] },
		};
	}

	private panelEntryFor(active: boolean): IStatusbarEntry {
		const label = localize('remnants.dock.panel', "Terminal and Panel");
		return {
			name: label,
			text: '$(terminal)',
			ariaLabel: label,
			tooltip: label,
			color: active ? themeColorFromId(DOCK_ACTIVE_FOREGROUND) : undefined,
			backgroundColor: active ? themeColorFromId(DOCK_ACTIVE_BACKGROUND) : undefined,
			command: TOGGLE_PANEL,
		};
	}
}

registerWorkbenchContribution2(RemnantsDockContribution.ID, RemnantsDockContribution, WorkbenchPhase.AfterRestored);
