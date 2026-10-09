/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { Disposable } from '../../../../base/common/lifecycle.js';
import { IStorageService, StorageScope, StorageTarget } from '../../../../platform/storage/common/storage.js';
import { IWorkbenchContribution, registerWorkbenchContribution2, WorkbenchPhase } from '../../../common/contributions.js';
import { IViewDescriptorService } from '../../../common/views.js';
import { IStatusbarService } from '../../../services/statusbar/browser/statusbar.js';

// Remnants quiet start: the first time a profile starts, a few status bar entries
// and Explorer sections are hidden once. Everything stays one right-click away
// (status bar or view header context menu), and a choice made there is kept.

const QUIET_STATUS_ENTRIES = [
	'status.host',               // remote indicator, left of the dock
	'status.editor.indentation', // "Spaces: 4"
	'status.editor.encoding',    // "UTF-8"
	'status.editor.eol',         // "CRLF"
	'status.scm.1',              // sync state next to the branch
];

const EXPLORER_CONTAINER_ID = 'workbench.view.explorer';
const QUIET_EXPLORER_VIEWS = ['outline', 'timeline'];

const APPLIED_KEY = 'remnants.quietStart.v1';

class RemnantsQuietStartContribution extends Disposable implements IWorkbenchContribution {

	static readonly ID = 'workbench.contrib.remnantsQuietStart';

	constructor(
		@IStorageService storageService: IStorageService,
		@IStatusbarService statusbarService: IStatusbarService,
		@IViewDescriptorService viewDescriptorService: IViewDescriptorService,
	) {
		super();

		if (storageService.getBoolean(APPLIED_KEY, StorageScope.PROFILE, false)) {
			return;
		}

		for (const id of QUIET_STATUS_ENTRIES) {
			statusbarService.updateEntryVisibility(id, false);
		}

		const explorer = viewDescriptorService.getViewContainerById(EXPLORER_CONTAINER_ID);
		if (explorer) {
			const model = viewDescriptorService.getViewContainerModel(explorer);
			for (const id of QUIET_EXPLORER_VIEWS) {
				if (model.allViewDescriptors.some(descriptor => descriptor.id === id)) {
					model.setVisible(id, false);
				}
			}
		}

		storageService.store(APPLIED_KEY, true, StorageScope.PROFILE, StorageTarget.USER);
	}
}

registerWorkbenchContribution2(RemnantsQuietStartContribution.ID, RemnantsQuietStartContribution, WorkbenchPhase.AfterRestored);
