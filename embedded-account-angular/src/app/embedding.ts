import { computed, DestroyRef, inject, Injectable, signal } from '@angular/core';
import '@salesforce/platform-sdk/ui-embedding';
import { getViewSDK, type ViewSDK } from '@salesforce/platform-sdk/view';
import type { AccountUiState } from './account';

/**
 * The only place that talks to the Salesforce SDK.
 *
 * getViewSDK caches one instance, so the whole app shares a single connection and a
 * single UI-state subscription. Off an embedding surface the SDK resolves to an empty
 * object, so every call is guarded with `?.` and `embedded` stays false.
 */
@Injectable({ providedIn: 'root' })
export class Embedding {
  private readonly state = signal<AccountUiState>({ props: {}, styles: {} });
  private readonly sdk: Promise<ViewSDK> = this.connect();
  private unsubscribe?: () => void;

  /** `props` set on <lightning-ui-embedding> by the wrapper LWC. */
  readonly account = computed(() => this.state().props);
  /** Host styles, including Salesforce's CSS custom properties. */
  readonly styles = computed(() => this.state().styles);
  readonly embedded = signal(false);
  readonly updates = signal(0);

  constructor() {
    inject(DestroyRef).onDestroy(() => this.unsubscribe?.());
  }

  private async connect(): Promise<ViewSDK> {
    const sdk = await getViewSDK();
    const ui = sdk.getUiState?.<AccountUiState>();
    if (ui) {
      this.embedded.set(true);
      this.state.set(ui.state);
      // Each snapshot is a full replacement, not a diff.
      this.unsubscribe = ui.subscribe((next) => {
        this.state.set(next);
        this.updates.update((count) => count + 1);
      });
    }
    return sdk;
  }

  /** Listen for a custom event the host dispatches on <lightning-ui-embedding>. Returns a remover. */
  onHostEvent<T>(type: string, handler: (detail: T | undefined) => void): () => void {
    const listener = (event: Event) => handler((event as CustomEvent<T>).detail);
    void this.sdk.then((sdk) => sdk.addEventListener?.(type, listener));
    return () => void this.sdk.then((sdk) => sdk.removeEventListener?.(type, listener));
  }

  /** Send a custom event to the host; it fires on <lightning-ui-embedding> as `type`. */
  async sendToHost(type: string, detail: unknown): Promise<void> {
    const sdk = await this.sdk;
    sdk.dispatchEvent?.(new CustomEvent(type, { detail }));
  }
}
