import { useEffect, useRef, useState } from 'react';
import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK } from '@salesforce/platform-sdk/view';

// getViewSDK caches one instance, so every component that uses these hooks
// shares a single connection and a single UI-state subscription.

const EMPTY_STATE = { props: {}, styles: {} };

/**
 * Host UI state: `props` set on <lightning-ui-embedding> and the host `styles`.
 * Off an embedding surface the SDK resolves to an empty object, so `embedded` stays false.
 */
export function useUiState() {
    const [state, setState] = useState(EMPTY_STATE);
    const [embedded, setEmbedded] = useState(false);
    const [updates, setUpdates] = useState(0);

    useEffect(() => {
        let unsubscribe;
        // The component may unmount before the SDK resolves.
        let active = true;

        getViewSDK().then((sdk) => {
            const ui = sdk.getUiState?.();
            if (!active || !ui) {
                return;
            }
            setEmbedded(true);
            setState(ui.state);
            // Each snapshot is a full replacement, not a diff.
            unsubscribe = ui.subscribe((next) => {
                setState(next);
                setUpdates((count) => count + 1);
            });
        });

        return () => {
            active = false;
            unsubscribe?.();
        };
    }, []);

    return { props: state.props ?? {}, styles: state.styles ?? {}, embedded, updates };
}

/** Listen for a custom event the host dispatches on <lightning-ui-embedding>. */
export function useHostEvent(type, handler) {
    // Keep the latest handler without re-attaching the listener on every render.
    const handlerRef = useRef(handler);
    useEffect(() => {
        handlerRef.current = handler;
    });

    useEffect(() => {
        let sdk;
        let active = true;
        const listener = (event) => handlerRef.current(event.detail);

        getViewSDK().then((resolved) => {
            if (!active) {
                return;
            }
            sdk = resolved;
            sdk.addEventListener?.(type, listener);
        });

        return () => {
            active = false;
            sdk?.removeEventListener?.(type, listener);
        };
    }, [type]);
}

/** Send a custom event to the host; it fires on <lightning-ui-embedding> as `type`. */
export async function sendToHost(type, detail) {
    const sdk = await getViewSDK();
    sdk.dispatchEvent?.(new CustomEvent(type, { detail }));
}
