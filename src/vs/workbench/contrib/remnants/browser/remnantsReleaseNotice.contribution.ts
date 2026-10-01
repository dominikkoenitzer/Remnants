/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { mainWindow } from '../../../../base/browser/window.js';
import { IntervalTimer } from '../../../../base/common/async.js';
import { CancellationToken } from '../../../../base/common/cancellation.js';
import { Disposable } from '../../../../base/common/lifecycle.js';
import { URI } from '../../../../base/common/uri.js';
import { localize } from '../../../../nls.js';
import { IConfigurationService } from '../../../../platform/configuration/common/configuration.js';
import { ConfigurationScope, Extensions as ConfigurationExtensions, IConfigurationRegistry } from '../../../../platform/configuration/common/configurationRegistry.js';
import { ILogService } from '../../../../platform/log/common/log.js';
import { INotificationService, Severity } from '../../../../platform/notification/common/notification.js';
import { IOpenerService } from '../../../../platform/opener/common/opener.js';
import { IProductService } from '../../../../platform/product/common/productService.js';
import { Registry } from '../../../../platform/registry/common/platform.js';
import { asJson, IRequestService } from '../../../../platform/request/common/request.js';
import { IStorageService, StorageScope, StorageTarget } from '../../../../platform/storage/common/storage.js';
import { IWorkbenchContribution, registerWorkbenchContribution2, WorkbenchPhase } from '../../../common/contributions.js';
import { CHECK_FOR_UPDATES_SETTING, DISMISSED_TAG_STORAGE_KEY, getLatestReleaseApiUrl, getReleasePageUrl, IGitHubRepository, ILatestRelease, isCheckAllowed, isCheckDue, LAST_CHECK_STORAGE_KEY, parseGitHubRepository, parseLatestRelease, shouldNotify, UPDATE_MODE_SETTING } from '../common/remnantsReleaseNotice.js';

Registry.as<IConfigurationRegistry>(ConfigurationExtensions.Configuration).registerConfiguration({
	id: 'remnants',
	title: localize('remnantsConfigurationTitle', "Remnants"),
	type: 'object',
	properties: {
		[CHECK_FOR_UPDATES_SETTING]: {
			type: 'boolean',
			default: false,
			scope: ConfigurationScope.APPLICATION,
			markdownDescription: localize('remnants.checkForUpdates', "Once a day, ask GitHub for the latest Remnants release and show a notification when it is newer than this version. Nothing is downloaded or installed. Has no effect while `#update.mode#` is `none` or `manual`."),
			tags: ['usesOnlineServices']
		}
	}
});

// How often the daily gate is looked at again, so a window that stays open
// for days still checks once a day.
const GATE_INTERVAL = 60 * 60 * 1000;

class RemnantsReleaseNotice extends Disposable implements IWorkbenchContribution {

	static readonly ID = 'workbench.contrib.remnantsReleaseNotice';

	constructor(
		@IConfigurationService private readonly configurationService: IConfigurationService,
		@IStorageService private readonly storageService: IStorageService,
		@IRequestService private readonly requestService: IRequestService,
		@IProductService private readonly productService: IProductService,
		@INotificationService private readonly notificationService: INotificationService,
		@IOpenerService private readonly openerService: IOpenerService,
		@ILogService private readonly logService: ILogService,
	) {
		super();

		const repository = parseGitHubRepository(productService.reportIssueUrl) ?? parseGitHubRepository(productService.licenseUrl);
		if (!repository) {
			return;
		}

		this._register(configurationService.onDidChangeConfiguration(e => {
			if (e.affectsConfiguration(CHECK_FOR_UPDATES_SETTING) || e.affectsConfiguration(UPDATE_MODE_SETTING)) {
				this.checkIfDue(repository);
			}
		}));

		const timer = this._register(new IntervalTimer());
		timer.cancelAndSet(() => this.checkIfDue(repository), GATE_INTERVAL, mainWindow);

		this.checkIfDue(repository);
	}

	private checkIfDue(repository: IGitHubRepository): void {
		if (!isCheckAllowed(this.configurationService.getValue(CHECK_FOR_UPDATES_SETTING), this.configurationService.getValue(UPDATE_MODE_SETTING))) {
			return;
		}

		const now = Date.now();
		if (!isCheckDue(this.storageService.getNumber(LAST_CHECK_STORAGE_KEY, StorageScope.APPLICATION), now)) {
			return;
		}

		// Stored before the request so a failed or slow request still counts
		// as the check for today.
		this.storageService.store(LAST_CHECK_STORAGE_KEY, now, StorageScope.APPLICATION, StorageTarget.MACHINE);

		this.check(repository).catch(error => this.logService.warn('Release notice: the check failed', error));
	}

	private async check(repository: IGitHubRepository): Promise<void> {
		const context = await this.requestService.request({ type: 'GET', url: getLatestReleaseApiUrl(repository), timeout: 20000, callSite: 'remnants.releaseNotice' }, CancellationToken.None);
		if (context.res.statusCode !== 200) {
			this.logService.warn(`Release notice: GitHub answered with status ${context.res.statusCode}`);
			return;
		}

		const release = parseLatestRelease(await asJson(context));
		if (!release) {
			return;
		}

		const dismissedTag = this.storageService.get(DISMISSED_TAG_STORAGE_KEY, StorageScope.APPLICATION);
		if (shouldNotify(release.tag, this.productService.version, dismissedTag)) {
			this.notify(release, repository);
		}
	}

	private notify(release: ILatestRelease, repository: IGitHubRepository): void {
		this.notificationService.prompt(
			Severity.Info,
			localize('remnantsReleaseNotice.message', "{0} {1} is available. You are running {2}.", this.productService.nameLong, release.tag, this.productService.version),
			[{
				label: localize('remnantsReleaseNotice.open', "Open Release Page"),
				run: () => {
					this.openerService.open(URI.parse(getReleasePageUrl(release, repository)));
				}
			}, {
				label: localize('remnantsReleaseNotice.dismiss', "Don't Show Again"),
				run: () => {
					this.storageService.store(DISMISSED_TAG_STORAGE_KEY, release.tag, StorageScope.APPLICATION, StorageTarget.MACHINE);
				}
			}]
		);
	}
}

registerWorkbenchContribution2(RemnantsReleaseNotice.ID, RemnantsReleaseNotice, WorkbenchPhase.Eventually);
