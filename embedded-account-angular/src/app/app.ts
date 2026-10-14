import { Component, computed, DestroyRef, effect, inject, signal } from '@angular/core';
import type { Rating } from './account';
import { AccountDetails } from './account-details/account-details';
import { Embedding } from './embedding';
import { RatingPicker } from './rating-picker/rating-picker';

// How long to wait for Salesforce to confirm a rating change before giving up.
const CONFIRM_TIMEOUT_MS = 8000;
const FEEDBACK_MS = 3000;

type Feedback = { text: string; tone: 'success' | 'warning' };

@Component({
  imports: [AccountDetails, RatingPicker],
  selector: 'app-root',
  templateUrl: './app.html',
})
export class App {
  private readonly embedding = inject(Embedding);

  protected readonly account = this.embedding.account;
  protected readonly updates = this.embedding.updates;

  protected readonly connected = computed(() => Boolean(this.account().recordId));
  protected readonly ratingTone = computed(() => this.account().rating?.toLowerCase() ?? 'none');

  protected readonly status = computed(() => {
    if (this.connected()) {
      return 'Connected to Salesforce';
    }
    return this.embedding.embedded()
      ? 'Embedded — place this component on an Account record page.'
      : 'Not embedded — open this app from an Account record page.';
  });

  protected readonly pendingRating = signal<Rating | null>(null);
  protected readonly feedback = signal<Feedback>({ text: '', tone: 'success' });

  private pendingTimer?: ReturnType<typeof setTimeout>;
  private feedbackTimer?: ReturnType<typeof setTimeout>;

  constructor() {
    // Mirror the host's CSS custom properties so the app matches Salesforce styling.
    effect(() => {
      for (const [name, value] of Object.entries(this.embedding.styles().variables ?? {})) {
        document.documentElement.style.setProperty(name, value);
      }
    });

    // The button stays in "Saving…" until the new rating comes back from Salesforce in props.
    effect(() => {
      const rating = this.account().rating;
      const pending = this.pendingRating();
      if (pending && rating === pending) {
        this.pendingRating.set(null);
        clearTimeout(this.pendingTimer);
        this.showFeedback(`Rating saved as ${rating}`);
      }
    });

    // The wrapper LWC sends the user's locale after the embedding is ready.
    const removeLocaleListener = this.embedding.onHostEvent<{ locale?: string }>(
      'localeInformation',
      (detail) => {
        document.documentElement.lang = detail?.locale ?? 'en';
      },
    );

    inject(DestroyRef).onDestroy(() => {
      removeLocaleListener();
      clearTimeout(this.pendingTimer);
      clearTimeout(this.feedbackTimer);
    });
  }

  // Surfaces on <lightning-ui-embedding> as a "ratingchange" DOM event; the wrapper saves it.
  protected onSelectRating(rating: Rating): void {
    this.pendingRating.set(rating);
    void this.embedding.sendToHost('ratingchange', { rating });
    clearTimeout(this.pendingTimer);
    this.pendingTimer = setTimeout(() => {
      if (this.pendingRating()) {
        this.pendingRating.set(null);
        this.showFeedback('No confirmation from Salesforce — check the toast for details.', 'warning');
      }
    }, CONFIRM_TIMEOUT_MS);
  }

  private showFeedback(text: string, tone: Feedback['tone'] = 'success'): void {
    this.feedback.set({ text, tone });
    clearTimeout(this.feedbackTimer);
    this.feedbackTimer = setTimeout(() => this.feedback.set({ text: '', tone }), FEEDBACK_MS);
  }
}
