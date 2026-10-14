import { Component, input, output } from '@angular/core';
import type { Rating } from '../account';

const RATINGS: readonly { value: Rating; hint: string }[] = [
  { value: 'Hot', hint: 'High priority' },
  { value: 'Warm', hint: 'Engaged' },
  { value: 'Cold', hint: 'Low activity' },
];

@Component({
  selector: 'app-rating-picker',
  templateUrl: './rating-picker.html',
})
export class RatingPicker {
  readonly current = input<string | null | undefined>(null);
  readonly pending = input<Rating | null>(null);
  readonly disabled = input(false);

  readonly ratingSelect = output<Rating>();

  protected readonly ratings = RATINGS;

  protected choose(rating: Rating): void {
    if (rating !== this.current()) {
      this.ratingSelect.emit(rating);
    }
  }

  protected hint(rating: { value: Rating; hint: string }): string {
    if (rating.value === this.pending()) {
      return 'Saving…';
    }
    return rating.value === this.current() ? 'Current' : rating.hint;
  }
}
