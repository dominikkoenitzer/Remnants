/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { Disposable } from '../../../base/common/lifecycle.js';
import { isMacintosh } from '../../../base/common/platform.js';
import { localize } from '../../../nls.js';
import { IDialogMainService } from '../../dialogs/electron-main/dialogMainService.js';
import { IWindowsMainService } from '../../windows/electron-main/windows.js';
import { IUpdateService, StateType } from '../common/update.js';

/**
<<<<<<< remnants/main
 * Shows a native "no updates available" dialog when an explicit update check
 * finds nothing. Shown by whichever app currently owns focus, so it appears
 * once across sibling apps (Remnants / Agents). On macOS the dialog is also
 * shown when the app is active but has no focused window (e.g. "Check for
 * Updates" invoked from the menu bar with all windows closed/minimized).
=======
 * Shows a native "no updates available" dialog after an explicit update check, but only on macOS with no open windows
 * (e.g. "Check for Updates" from the menu bar/dock with all windows closed). Otherwise the workbench shows its own
 * themed dialog from the last focused window (see `UpdateContribution`).
>>>>>>> 1.139.1
 */
export class NotAvailableUpdateDialog extends Disposable {

	constructor(
		updateService: IUpdateService,
		dialogMainService: IDialogMainService,
		windowsMainService: IWindowsMainService,
	) {
		super();

		this._register(updateService.onStateChange(state => {
			if (state.type !== StateType.Idle || !state.notAvailable || state.error) {
				return;
			}

			if (!isMacintosh || windowsMainService.getWindowCount() > 0) {
				return;
			}

			dialogMainService.showMessageBox({
				type: 'info',
				message: localize('noUpdatesAvailable', "There are currently no updates available."),
			});
		}));
	}
}
