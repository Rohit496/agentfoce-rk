import { onHostEvent, sendToHost, watchUiState } from './embedding.js';

// How long to wait for Salesforce to confirm a rating change before giving up.
const CONFIRM_TIMEOUT_MS = 8000;
const FEEDBACK_MS = 3000;
const HIGHLIGHT_MS = 1600;
const FIELD_KEYS = ['name', 'rating', 'type', 'industry', 'phone', 'website'];

const els = {
    app: document.getElementById('app'),
    statusDot: document.getElementById('status-dot'),
    status: document.getElementById('status'),
    actions: document.getElementById('actions'),
    feedback: document.getElementById('feedback'),
    updates: document.getElementById('updates'),
    fields: Object.fromEntries(
        FIELD_KEYS.map((key) => [key, document.querySelector(`[data-field="${key}"]`)])
    ),
    buttons: [...document.querySelectorAll('button[data-rating]')]
};

const state = {
    account: {},
    embedded: false,
    updates: 0,
    pendingRating: null
};

let pendingTimer;
let feedbackTimer;
let highlightTimer;

function websiteHref(website) {
    return /^https?:\/\//i.test(website) ? website : `https://${website}`;
}

// Values come from Salesforce records, so they are written as text nodes, never as HTML.
function fieldContent(key, value) {
    if (!value) {
        return key === 'name' ? 'Account' : '—';
    }
    if (key === 'rating') {
        const pill = document.createElement('span');
        pill.className = `pill pill--${value.toLowerCase()}`;
        pill.textContent = value;
        return pill;
    }
    if (key === 'website') {
        const link = document.createElement('a');
        link.href = websiteHref(value);
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        link.textContent = `${value} ↗`;
        return link;
    }
    return value;
}

function render() {
    const { account, embedded, updates, pendingRating } = state;
    const connected = Boolean(account.recordId);

    els.app.dataset.rating = account.rating?.toLowerCase() ?? 'none';
    els.statusDot.classList.toggle('is-connected', connected);
    if (connected) {
        els.status.textContent = 'Connected to Salesforce';
    } else {
        els.status.textContent = embedded
            ? 'Embedded — place this component on an Account record page.'
            : 'Not embedded — open this app from an Account record page.';
    }

    for (const key of FIELD_KEYS) {
        els.fields[key].replaceChildren(fieldContent(key, account[key]));
    }

    els.actions.disabled = !connected || Boolean(pendingRating);
    for (const button of els.buttons) {
        const rating = button.dataset.rating;
        const isCurrent = rating === account.rating;
        const isPending = rating === pendingRating;
        button.classList.toggle('is-current', isCurrent);
        button.classList.toggle('is-pending', isPending);
        button.setAttribute('aria-pressed', String(isCurrent));
        let hint = button.dataset.hint;
        if (isPending) {
            hint = 'Saving…';
        } else if (isCurrent) {
            hint = 'Current';
        }
        button.querySelector('.rating__hint').textContent = hint;
    }

    els.updates.hidden = updates === 0;
    els.updates.textContent = `${updates} live update${updates === 1 ? '' : 's'} received from Salesforce`;
}

function showFeedback(text, tone = 'success') {
    els.feedback.textContent = text;
    els.feedback.className = `feedback feedback--${tone}`;
    clearTimeout(feedbackTimer);
    feedbackTimer = setTimeout(() => {
        els.feedback.textContent = '';
    }, FEEDBACK_MS);
}

// Briefly highlight fields that changed in a live update from Salesforce.
function highlightChanges(previous, next) {
    // Skip the first load: nothing has "changed" yet.
    if (!previous.name) {
        return;
    }
    const changed = FIELD_KEYS.filter((key) => next[key] !== previous[key]);
    if (changed.length === 0) {
        return;
    }
    for (const key of FIELD_KEYS) {
        els.fields[key].classList.toggle('is-changed', changed.includes(key));
    }
    clearTimeout(highlightTimer);
    highlightTimer = setTimeout(() => {
        for (const key of FIELD_KEYS) {
            els.fields[key].classList.remove('is-changed');
        }
    }, HIGHLIGHT_MS);
}

// Mirror the host's CSS custom properties so the app matches Salesforce styling.
function applyStyles(styles = {}) {
    for (const [name, value] of Object.entries(styles.variables ?? {})) {
        document.documentElement.style.setProperty(name, value);
    }
}

function onUiState(uiState, isUpdate) {
    const previous = state.account;
    state.account = uiState.props ?? {};
    state.embedded = true;
    if (isUpdate) {
        state.updates += 1;
    }
    applyStyles(uiState.styles);

    // The button stays in "Saving…" until the new rating comes back from Salesforce in props.
    if (state.pendingRating && state.account.rating === state.pendingRating) {
        state.pendingRating = null;
        clearTimeout(pendingTimer);
        showFeedback(`Rating saved as ${state.account.rating}`);
    }

    render();
    highlightChanges(previous, state.account);
}

// Surfaces on <lightning-ui-embedding> as a "ratingchange" DOM event; the wrapper saves it.
function onSelectRating(rating) {
    if (rating === state.account.rating) {
        return;
    }
    state.pendingRating = rating;
    render();
    sendToHost('ratingchange', { rating });
    clearTimeout(pendingTimer);
    pendingTimer = setTimeout(() => {
        // Still pending means Salesforce never sent the new rating back.
        if (state.pendingRating) {
            state.pendingRating = null;
            render();
            showFeedback('No confirmation from Salesforce — check the toast for details.', 'warning');
        }
    }, CONFIRM_TIMEOUT_MS);
}

els.actions.addEventListener('click', (event) => {
    const rating = event.target.closest('button[data-rating]')?.dataset.rating;
    if (rating) {
        onSelectRating(rating);
    }
});

// The wrapper LWC sends the user's locale after the embedding is ready.
onHostEvent('localeInformation', (detail) => {
    document.documentElement.lang = detail?.locale ?? 'en';
});

// The page shows "Connecting to Salesforce…" until the SDK resolves.
await watchUiState(onUiState);
render();
