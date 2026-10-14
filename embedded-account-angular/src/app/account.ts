import type { UiState } from '@salesforce/platform-sdk/view';

export type Rating = 'Hot' | 'Warm' | 'Cold';

/** The `props` object the wrapper LWC sets on <lightning-ui-embedding>. */
export type AccountProps = {
  recordId?: string;
  name?: string | null;
  rating?: string | null;
  type?: string | null;
  industry?: string | null;
  phone?: string | null;
  website?: string | null;
};

export interface AccountUiState extends UiState {
  props: AccountProps;
}
