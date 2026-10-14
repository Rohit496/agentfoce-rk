import { Fragment, useEffect, useRef, useState } from 'react';

const FIELDS = [
    { key: 'rating', label: 'Rating' },
    { key: 'type', label: 'Type' },
    { key: 'industry', label: 'Industry' },
    { key: 'phone', label: 'Phone' },
    { key: 'website', label: 'Website' }
];

const WATCHED_KEYS = ['name', ...FIELDS.map((field) => field.key)];
const HIGHLIGHT_MS = 1600;

function websiteHref(website) {
    return /^https?:\/\//i.test(website) ? website : `https://${website}`;
}

function FieldValue({ field, value }) {
    if (!value) {
        return '—';
    }
    if (field === 'rating') {
        return <span className={`pill pill--${value.toLowerCase()}`}>{value}</span>;
    }
    if (field === 'website') {
        return (
            <a href={websiteHref(value)} target="_blank" rel="noopener noreferrer">
                {value} ↗
            </a>
        );
    }
    return value;
}

export default function AccountDetails({ account }) {
    // Fields that changed in the latest live update from Salesforce; highlighted briefly.
    const [changed, setChanged] = useState(() => new Set());
    const previous = useRef();
    const clearTimer = useRef();

    useEffect(() => {
        const prev = previous.current;
        previous.current = account;
        // Skip the first load: nothing has "changed" yet.
        if (!prev?.name) {
            return;
        }
        const keys = WATCHED_KEYS.filter((key) => account[key] !== prev[key]);
        if (keys.length === 0) {
            return;
        }
        setChanged(new Set(keys));
        clearTimeout(clearTimer.current);
        clearTimer.current = setTimeout(() => setChanged(new Set()), HIGHLIGHT_MS);
    }, [account]);

    useEffect(() => () => clearTimeout(clearTimer.current), []);

    const flash = (key) => (changed.has(key) ? 'is-changed' : undefined);

    return (
        <section>
            <h1 className={['name', flash('name')].filter(Boolean).join(' ')}>
                {account.name ?? 'Account'}
            </h1>
            <dl className="fields">
                {FIELDS.map((field) => (
                    <Fragment key={field.key}>
                        <dt>{field.label}</dt>
                        <dd className={flash(field.key)}>
                            <FieldValue field={field.key} value={account[field.key]} />
                        </dd>
                    </Fragment>
                ))}
            </dl>
        </section>
    );
}
