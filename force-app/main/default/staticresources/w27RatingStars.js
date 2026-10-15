/*
 * <w27-rating-stars> - a plain, framework-free custom element.
 * It knows nothing about LWC. Packaged as an IIFE because loadScript()
 * does not support ES modules.
 *
 * Attributes: value (current rating), max (number of stars, default 5),
 *             label (accessible name, default "Rating").
 * Events:     rate - CustomEvent, detail: { value }
 * Theming:    --w27-star-size, --w27-star-color, --w27-star-empty-color,
 *             --w27-star-focus-color (inherit through the shadow root)
 */
(function () {
    'use strict';

    const TAG = 'w27-rating-stars';
    if (typeof customElements === 'undefined' || customElements.get(TAG)) {
        return;
    }

    const STYLE = `
        :host { display: inline-block; line-height: 1; }
        .stars { display: inline-flex; gap: 0.25rem; }
        button {
            all: unset;
            cursor: pointer;
            font-size: var(--w27-star-size, 2.5rem);
            color: var(--w27-star-empty-color, #c9c9c9);
            transition: transform 120ms ease, color 120ms ease;
        }
        button.on { color: var(--w27-star-color, #fe9339); }
        button:hover { transform: scale(1.12); }
        button:focus-visible {
            outline: 2px solid var(--w27-star-focus-color, #0176d3);
            outline-offset: 2px;
            border-radius: 4px;
        }`;

    const toInt = (raw, fallback) => {
        const n = parseInt(raw, 10);
        return Number.isNaN(n) ? fallback : n;
    };

    class W27RatingStars extends HTMLElement {
        static get observedAttributes() {
            return ['value', 'max', 'label'];
        }

        connectedCallback() {
            if (!this.shadowRoot) {
                const root = this.attachShadow({ mode: 'open' });
                const style = document.createElement('style');
                style.textContent = STYLE;
                this._group = document.createElement('div');
                this._group.className = 'stars';
                this._group.setAttribute('role', 'radiogroup');
                this._group.addEventListener('click', (e) => this._onClick(e));
                this._group.addEventListener('keydown', (e) => this._onKeyDown(e));
                root.append(style, this._group);
            }
            this._render();
        }

        attributeChangedCallback() {
            if (this._group) {
                this._render();
            }
        }

        get _max() {
            return Math.max(1, toInt(this.getAttribute('max'), 5));
        }

        get _value() {
            return Math.min(this._max, Math.max(0, toInt(this.getAttribute('value'), 0)));
        }

        _render() {
            const max = this._max;
            const value = this._value;
            this._group.setAttribute('aria-label', this.getAttribute('label') || 'Rating');
            this._group.textContent = '';
            for (let i = 1; i <= max; i++) {
                const star = document.createElement('button');
                star.type = 'button';
                star.textContent = '★';
                star.dataset.value = String(i);
                star.className = i <= value ? 'on' : '';
                star.setAttribute('role', 'radio');
                star.setAttribute('aria-checked', String(i === value));
                star.setAttribute('aria-label', i === 1 ? '1 star' : `${i} stars`);
                // Roving tabindex: only the selected star (or the first) is tabbable.
                star.tabIndex = i === (value || 1) ? 0 : -1;
                this._group.appendChild(star);
            }
        }

        _rate(value) {
            this.setAttribute('value', String(value));
            this._group.children[value - 1].focus();
            this.dispatchEvent(new CustomEvent('rate', { detail: { value } }));
        }

        _onClick(event) {
            const star = event.target.closest('button');
            if (star) {
                this._rate(toInt(star.dataset.value, 0));
            }
        }

        _onKeyDown(event) {
            const max = this._max;
            const value = this._value || 1;
            const next = {
                ArrowRight: Math.min(max, value + 1),
                ArrowUp: Math.min(max, value + 1),
                ArrowLeft: Math.max(1, value - 1),
                ArrowDown: Math.max(1, value - 1),
                Home: 1,
                End: max
            }[event.key];
            if (next !== undefined) {
                event.preventDefault();
                this._rate(next);
            }
        }
    }

    customElements.define(TAG, W27RatingStars);
})();
