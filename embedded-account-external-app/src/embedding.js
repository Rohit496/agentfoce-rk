import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK } from '@salesforce/platform-sdk/view';

// The only module that talks to the Salesforce SDK.
// getViewSDK caches one instance, so every call here shares a single connection
// and a single UI-state subscription. Off an embedding surface the SDK resolves
// to an empty object, so every call is guarded with `?.`.

/**
 * Read the host UI state (`props` set on <lightning-ui-embedding>, plus host `styles`)
 * and keep receiving it. `onState(state, isUpdate)` runs once with the current snapshot
 * and again for every later one. Resolves to false when the app is not embedded.
 */
export async function watchUiState(onState) {
    const sdk = await getViewSDK();
    const ui = sdk.getUiState?.();
    if (!ui) {
        return false;
    }
    onState(ui.state, false);
    // Each snapshot is a full replacement, not a diff.
    ui.subscribe((next) => onState(next, true));
    return true;
}

/** Listen for a custom event the host dispatches on <lightning-ui-embedding>. */
export async function onHostEvent(type, handler) {
    const sdk = await getViewSDK();
    sdk.addEventListener?.(type, (event) => handler(event.detail));
}

/** Send a custom event to the host; it fires on <lightning-ui-embedding> as `type`. */
export async function sendToHost(type, detail) {
    const sdk = await getViewSDK();
    sdk.dispatchEvent?.(new CustomEvent(type, { detail }));
}
