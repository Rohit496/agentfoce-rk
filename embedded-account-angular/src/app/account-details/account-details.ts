import { Component, computed, DestroyRef, effect, inject, input, signal } from '@angular/core';
import type { AccountProps } from '../account';

type FieldKey = 'rating' | 'type' | 'industry' | 'phone' | 'website';

const FIELDS: readonly { key: FieldKey; label: string }[] = [
  { key: 'rating', label: 'Rating' },
  { key: 'type', label: 'Type' },
  { key: 'industry', label: 'Industry' },
  { key: 'phone', label: 'Phone' },
  { key: 'website', label: 'Website' },
];

const WATCHED_KEYS: readonly (FieldKey | 'name')[] = ['name', ...FIELDS.map((field) => field.key)];
const HIGHLIGHT_MS = 1600;

@Component({
  selector: 'app-account-details',
  templateUrl: './account-details.html',
})
export class AccountDetails {
  readonly account = input.required<AccountProps>();

  protected readonly rows = computed(() =>
    FIELDS.map((field) => ({ ...field, value: this.account()[field.key] })),
  );

  protected readonly websiteHref = computed(() => {
    const website = this.account().website;
    if (!website) {
      return null;
    }
    return /^https?:\/\//i.test(website) ? website : `https://${website}`;
  });

  /** Fields that changed in the latest live update from Salesforce; highlighted briefly. */
  protected readonly changed = signal<ReadonlySet<string>>(new Set());

  private previous?: AccountProps;
  private clearTimer?: ReturnType<typeof setTimeout>;

  constructor() {
    effect(() => {
      const next = this.account();
      const previous = this.previous;
      this.previous = next;
      // Skip the first load: nothing has "changed" yet.
      if (!previous?.name) {
        return;
      }
      const keys = WATCHED_KEYS.filter((key) => next[key] !== previous[key]);
      if (keys.length === 0) {
        return;
      }
      this.changed.set(new Set(keys));
      clearTimeout(this.clearTimer);
      this.clearTimer = setTimeout(() => this.changed.set(new Set()), HIGHLIGHT_MS);
    });

    inject(DestroyRef).onDestroy(() => clearTimeout(this.clearTimer));
  }
}
