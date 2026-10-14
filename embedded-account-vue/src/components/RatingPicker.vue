<script setup>
const props = defineProps({
    current: { type: String, default: null },
    pending: { type: String, default: null },
    disabled: { type: Boolean, default: false }
});

const emit = defineEmits(['select']);

const RATINGS = [
    { value: 'Hot', hint: 'High priority' },
    { value: 'Warm', hint: 'Engaged' },
    { value: 'Cold', hint: 'Low activity' }
];

function select(rating) {
    if (rating !== props.current) {
        emit('select', rating);
    }
}
</script>

<template>
    <fieldset class="actions" :disabled="disabled || Boolean(pending)">
        <legend>Set rating in Salesforce</legend>
        <button
            v-for="rating in RATINGS"
            :key="rating.value"
            type="button"
            :class="[
                'rating',
                `rating--${rating.value.toLowerCase()}`,
                { 'is-current': rating.value === current, 'is-pending': rating.value === pending }
            ]"
            :aria-pressed="String(rating.value === current)"
            @click="select(rating.value)"
        >
            <span class="rating__title">
                <span class="rating__dot" aria-hidden="true"></span>
                {{ rating.value }}
            </span>
            <span class="rating__hint">
                {{ rating.value === pending ? 'Saving…' : rating.value === current ? 'Current' : rating.hint }}
            </span>
        </button>
    </fieldset>
</template>
