import { onMounted, onUnmounted, ref, shallowRef } from 'vue';
import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK } from '@salesforce/platform-sdk/view';

// getViewSDK caches one instance, so every component that uses these composables
// shares a single connection and a single UI-state subscription.

/**
 * Reactive host UI state: `props` set on <lightning-ui-embedding> and the host `styles`.
 * Off an embedding surface the SDK resolves to an empty object, so `embedded` stays false.
 */
export function useUiState() {
    const props = shallowRef({});
    const styles = shallowRef({});
    const embedded = ref(false);
    const updates = ref(0);

    let unsubscribe;
    let active = true;

    function apply(state) {
        props.value = state.props ?? {};
        styles.value = state.styles ?? {};
    }

    onMounted(async () => {
        const sdk = await getViewSDK();
        const ui = sdk.getUiState?.();
        // The component may unmount before the SDK resolves.
        if (!active || !ui) {
            return;
        }
        embedded.value = true;
        apply(ui.state);
        unsubscribe = ui.subscribe((next) => {
            apply(next);
            updates.value += 1;
        });
    });

    onUnmounted(() => {
        active = false;
        unsubscribe?.();
    });

    return { props, styles, embedded, updates };
}

/** Listen for a custom event the host dispatches on <lightning-ui-embedding>. */
export function useHostEvent(type, handler) {
    let sdk;
    const listener = (event) => handler(event.detail);

    onMounted(async () => {
        sdk = await getViewSDK();
        sdk.addEventListener?.(type, listener);
    });

    onUnmounted(() => sdk?.removeEventListener?.(type, listener));
}

/** Send a custom event to the host; it fires on <lightning-ui-embedding> as `type`. */
export async function sendToHost(type, detail) {
    const sdk = await getViewSDK();
    sdk.dispatchEvent?.(new CustomEvent(type, { detail }));
}
