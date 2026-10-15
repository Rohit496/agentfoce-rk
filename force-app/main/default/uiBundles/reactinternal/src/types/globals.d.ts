/**
 * Copyright (c) 2026, Salesforce, Inc.
 * All rights reserved.
 * For full license text, see the LICENSE.txt file
 */

interface SfdcEnv {
	/** Salesforce org force.com URL (e.g., "https://myorg.lightning.force.com"). */
	orgUrl?: string;
	/** Base path the app is served from (e.g., "/lwr/application/ai/c-app"). */
	basePath?: string;
}

declare var SFDC_ENV: SfdcEnv | undefined;
