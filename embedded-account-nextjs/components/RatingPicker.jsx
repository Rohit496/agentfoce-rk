const RATINGS = [
    { value: 'Hot', hint: 'High priority' },
    { value: 'Warm', hint: 'Engaged' },
    { value: 'Cold', hint: 'Low activity' }
];

function hintFor(rating, current, pending) {
    if (rating.value === pending) {
        return 'Saving…';
    }
    return rating.value === current ? 'Current' : rating.hint;
}

export default function RatingPicker({ current, pending, disabled, onSelect }) {
    return (
        <fieldset className="actions" disabled={disabled || Boolean(pending)}>
            <legend>Set rating in Salesforce</legend>
            {RATINGS.map((rating) => {
                const classes = ['rating', `rating--${rating.value.toLowerCase()}`];
                if (rating.value === current) {
                    classes.push('is-current');
                }
                if (rating.value === pending) {
                    classes.push('is-pending');
                }
                return (
                    <button
                        key={rating.value}
                        type="button"
                        className={classes.join(' ')}
                        aria-pressed={rating.value === current}
                        onClick={() => rating.value !== current && onSelect(rating.value)}
                    >
                        <span className="rating__title">
                            <span className="rating__dot" aria-hidden="true"></span>
                            {rating.value}
                        </span>
                        <span className="rating__hint">{hintFor(rating, current, pending)}</span>
                    </button>
                );
            })}
        </fieldset>
    );
}
