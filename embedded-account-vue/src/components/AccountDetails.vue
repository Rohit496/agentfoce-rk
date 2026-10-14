<script setup>
import { computed, onUnmounted, ref, watch } from 'vue';

const props = defineProps({
    account: { type: Object, required: true }
});

const FIELDS = [
    { key: 'rating', label: 'Rating' },
    { key: 'type', label: 'Type' },
    { key: 'industry', label: 'Industry' },
    { key: 'phone', label: 'Phone' },
    { key: 'website', label: 'Website' }
];

const rows = computed(() =>
    FIELDS.map((field) => ({ ...field, value: props.account[field.key] }))
);

const websiteHref = computed(() => {
    const website = props.account.website;
    if (!website) {
        return null;
    }
    return /^https?:\/\//i.test(website) ? website : `https://${website}`;
});

// Briefly highlight fields that changed in a live update from Salesforce.
const changed = ref(new Set());
let clearTimer;

watch(
    () => props.account,
    (next, prev) => {
        // Skip the first load: nothing has "changed" yet.
        if (!prev?.name) {
            return;
        }
        const keys = ['name', ...FIELDS.map((f) => f.key)].filter((k) => next[k] !== prev[k]);
        if (keys.length === 0) {
            return;
        }
        changed.value = new Set(keys);
        clearTimeout(clearTimer);
        clearTimer = setTimeout(() => {
            changed.value = new Set();
        }, 1600);
    }
);

onUnmounted(() => clearTimeout(clearTimer));
</script>

<template>
    <section>
        <h1 :class="['name', { 'is-changed': changed.has('name') }]">{{ account.name ?? 'Account' }}</h1>
        <dl class="fields">
            <template v-for="row in rows" :key="row.key">
                <dt>{{ row.label }}</dt>
                <dd :class="{ 'is-changed': changed.has(row.key) }">
                    <template v-if="!row.value">—</template>
                    <span
                        v-else-if="row.key === 'rating'"
                        :class="['pill', `pill--${row.value.toLowerCase()}`]"
                    >{{ row.value }}</span>
                    <a
                        v-else-if="row.key === 'website'"
                        :href="websiteHref"
                        target="_blank"
                        rel="noopener noreferrer"
                    >{{ row.value }} ↗</a>
                    <template v-else>{{ row.value }}</template>
                </dd>
            </template>
        </dl>
    </section>
</template>
