'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import AccountDetails from './AccountDetails.jsx';
import RatingPicker from './RatingPicker.jsx';
import { sendToHost, useHostEvent, useUiState } from '../hooks/useEmbedding.js';

// How long to wait for Salesforce to confirm a rating change before giving up.
const CONFIRM_TIMEOUT_MS = 8000;
const FEEDBACK_MS = 3000;

function statusText(connected, embedded, ready) {
    // Shown in the prerendered HTML and until the SDK resolves, instead of a wrong "Not embedded".
    if (!ready) {
        return 'Connecting to Salesforce…';
    }
    if (connected) {
        return 'Connected to Salesforce';
    }
    return embedded
        ? 'Embedded — place this component on an Account record page.'
        : 'Not embedded — open this app from an Account record page.';
}

export default function AccountInsights() {
    const { props: account, styles, embedded, updates, ready } = useUiState();
    const [pendingRating, setPendingRating] = useState(null);
    const [feedback, setFeedback] = useState({ text: '', tone: 'success' });
    // Mirrors pendingRating so the timeout callback reads the current value, not a stale one.
    const pendingRef = useRef(null);
    const pendingTimer = useRef();
    const feedbackTimer = useRef();

    const connected = Boolean(account.recordId);
    const ratingTone = account.rating?.toLowerCase() ?? 'none';

    const setPending = useCallback((rating) => {
        pendingRef.current = rating;
        setPendingRating(rating);
    }, []);

    const showFeedback = useCallback((text, tone = 'success') => {
        setFeedback({ text, tone });
        clearTimeout(feedbackTimer.current);
        feedbackTimer.current = setTimeout(() => setFeedback({ text: '', tone }), FEEDBACK_MS);
    }, []);

    // Mirror the host's CSS custom properties so the app matches Salesforce styling.
    useEffect(() => {
        for (const [name, value] of Object.entries(styles.variables ?? {})) {
            document.documentElement.style.setProperty(name, value);
        }
    }, [styles]);

    // The wrapper LWC sends the user's locale after the embedding is ready.
    useHostEvent('localeInformation', (detail) => {
        document.documentElement.lang = detail?.locale ?? 'en';
    });

    // The button stays in "Saving…" until the new rating comes back from Salesforce in props.
    useEffect(() => {
        if (pendingRating && account.rating === pendingRating) {
            setPending(null);
            clearTimeout(pendingTimer.current);
            showFeedback(`Rating saved as ${account.rating}`);
        }
    }, [account.rating, pendingRating, setPending, showFeedback]);

    useEffect(
        () => () => {
            clearTimeout(pendingTimer.current);
            clearTimeout(feedbackTimer.current);
        },
        []
    );

    // Surfaces on <lightning-ui-embedding> as a "ratingchange" DOM event; the wrapper saves it.
    function onSelectRating(rating) {
        setPending(rating);
        sendToHost('ratingchange', { rating });
        clearTimeout(pendingTimer.current);
        pendingTimer.current = setTimeout(() => {
            // Still pending means Salesforce never sent the new rating back.
            if (pendingRef.current) {
                setPending(null);
                showFeedback('No confirmation from Salesforce — check the toast for details.', 'warning');
            }
        }, CONFIRM_TIMEOUT_MS);
    }

    return (
        <main className="app" data-rating={ratingTone}>
            <header className="header">
                <span className="badge">Next.js</span>
                <span className={connected ? 'status-dot is-connected' : 'status-dot'} aria-hidden="true"></span>
                <span className="status">{statusText(connected, embedded, ready)}</span>
            </header>
            <AccountDetails account={account} />
            <RatingPicker
                current={account.rating}
                pending={pendingRating}
                disabled={!connected}
                onSelect={onSelectRating}
            />
            <p className={`feedback feedback--${feedback.tone}`} role="status" aria-live="polite">
                {feedback.text}
            </p>
            {updates > 0 && (
                <p className="updates">
                    {updates} live update{updates === 1 ? '' : 's'} received from Salesforce
                </p>
            )}
        </main>
    );
}
