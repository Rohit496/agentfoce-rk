const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    // LWC Jest tests live only under lwc/. The React UI bundles (Vitest/Playwright) and the
    // embedded apps have their own test runners, and their node_modules must not be scanned.
    roots: ['<rootDir>/force-app/main/default/lwc'],
    // Same transformer as sfdx-lwc-jest, with complex template expressions (GA) turned on.
    transform: {
        '^.+\\.(js|ts|html|css)$': '<rootDir>/jest/lwcTransformer.js'
    },
    modulePathIgnorePatterns: [
        '<rootDir>/.localdevserver',
        '<rootDir>/force-app/main/default/uiBundles',
        '<rootDir>/embedded-account-.*',
        '<rootDir>/expense-tracker',
        '<rootDir>/HXL-Account'
    ]
};
