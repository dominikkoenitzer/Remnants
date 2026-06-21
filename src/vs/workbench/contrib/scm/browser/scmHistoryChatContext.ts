/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { UriComponents } from '../../../../base/common/uri.js';
import { CodeDataTransfers } from '../../../../platform/dnd/browser/dnd.js';
import { ISCMHistoryItem } from '../common/history.js';

export interface SCMHistoryItemTransferData {
	readonly name: string;
	readonly resource: UriComponents;
	readonly historyItem: ISCMHistoryItem;
}

export function extractSCMHistoryItemDropData(e: DragEvent): SCMHistoryItemTransferData[] | undefined {
	if (!e.dataTransfer?.types.includes(CodeDataTransfers.SCM_HISTORY_ITEM)) {
		return undefined;
	}

	const data = e.dataTransfer?.getData(CodeDataTransfers.SCM_HISTORY_ITEM);
	if (!data) {
		return undefined;
	}

	return JSON.parse(data) as SCMHistoryItemTransferData[];
}
