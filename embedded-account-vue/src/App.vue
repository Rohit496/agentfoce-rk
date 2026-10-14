<script setup>
import { computed, onUnmounted, ref, watch } from 'vue';
import AccountDetails from './components/AccountDetails.vue';
import RatingPicker from './components/RatingPicker.vue';
import { sendToHost, useHostEvent, useUiState } from './composables/useEmbedding.js';

// How long to wait for Salesforce to confirm a rating change before giving up.
const CONFIRM_TIMEOUT_MS = 8000;

const { props: account, styles, embedded, updates } = useUiState();

const connected = computed(() => Boolean(account.value.recordId));
const ratingTone = computed(() => account.value.rating?.toLowerCase() ?? 'none');

const status = computed(() => {
    if (connected.value) {
        return 'Connected to Salesforce';
    }
    return embedded.value
        ? 'Embedded — place this component on an Account record page.'
        : 'Not embedded — open this app from an Account record page.';
});

// Mirror the host's CSS custom properties so the app matches Salesforce styling.
watch(styles, (next) => {
    for (const [name, value] of Object.entries(next.variables ?? {})) {
        document.documentElement.style.setProperty(name, value);
    }
});

// The wrapper LWC sends the user's locale after the embedding is ready.
useHostEvent('localeInformation', (detail) => {
    document.documentElement.lang = detail?.locale ?? 'en';
});

const pendingRating = ref(null);
const feedback = ref({ text: '', tone: 'success' });
let pendingTimer;
let feedbackTimer;

function showFeedback(text, tone = 'success') {
    feedback.value = { text, tone };
    clearTimeout(feedbackTimer);
    feedbackTimer = setTimeout(() => {
        feedback.value = { text: '', tone };
    }, 3000);
}

// Surfaces on <lightning-ui-embedding> as a "ratingchange" DOM event; the wrapper saves it.
// The button stays in "Saving…" until the new rating comes back from Salesforce in props.
function onSelectRating(rating) {
    pendingRating.value = rating;
    sendToHost('ratingchange', { rating });
    clearTimeout(pendingTimer);
    pendingTimer = setTimeout(() => {
        if (pendingRating.value) {
            pendingRating.value = null;
            showFeedback('No confirmation from Salesforce — check the toast for details.', 'warning');
        }
    }, CONFIRM_TIMEOUT_MS);
}

watch(
    () => account.value.rating,
    (rating) => {
        if (pendingRating.value && rating === pendingRating.value) {
            pendingRating.value = null;
            clearTimeout(pendingTimer);
            showFeedback(`Rating saved as ${rating}`);
        }
    }
);

onUnmounted(() => {
    clearTimeout(pendingTimer);
    clearTimeout(feedbackTimer);
});
</script>

<template>
    <main class="app" :data-rating="ratingTone">
        <header class="header">
            <span class="badge">Vue JS</span>
            <span :class="['status-dot', { 'is-connected': connected }]" aria-hidden="true"></span>
            <span class="status">{{ status }}</span>
        </header>
        <AccountDetails :account="account" />
        <RatingPicker
            :current="account.rating"
            :pending="pendingRating"
            :disabled="!connected"
            @select="onSelectRating"
        />
        <p :class="['feedback', `feedback--${feedback.tone}`]" role="status" aria-live="polite">
            {{ feedback.text }}
        </p>
        <p v-if="updates > 0" class="updates">
            {{ updates }} live update{{ updates === 1 ? '' : 's' }} received from Salesforce
        </p>
    </main>
</template>
