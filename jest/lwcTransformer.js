/*
 * Wraps @lwc/jest-transformer so Jest compiles LWC templates the way the platform does
 * since Winter '27: complex template expressions are GA (API 66.0+), but the stock
 * transformer has no option to turn them on.
 */
const lwcCompiler = require('@lwc/compiler');

const { transformSync } = lwcCompiler;
lwcCompiler.transformSync = (src, filename, options) =>
    transformSync(src, filename, {
        ...options,
        experimentalComplexExpressions: true
    });

const lwcTransformer = require('@lwc/jest-transformer');

module.exports = {
    ...lwcTransformer,
    // Salt the cache key so templates cached without the option get recompiled.
    getCacheKey: (...args) =>
        `${lwcTransformer.getCacheKey(...args)}-complex-expressions`
};
