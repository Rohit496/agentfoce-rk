import { createElement } from '@lwc/engine-dom';
import ExternalComponent from 'c/externalComponent';
import { loadScript } from 'lightning/platformResourceLoader';

// Define the real third-party element, as the static resource would in the org.
require('../../../staticresources/w27RatingStars.js');

jest.mock(
    'lightning/platformResourceLoader',
    () => ({ loadScript: jest.fn() }),
    { virtual: true }
);

const flushPromises = async () => {
    await Promise.resolve();
    await Promise.resolve();
};

const mount = async () => {
    const element = createElement('c-external-component', {
        is: ExternalComponent
    });
    document.body.appendChild(element);
    await flushPromises();
    return element;
};

const stateText = (element) =>
    element.shadowRoot
        .querySelector('p[aria-live]')
        .textContent.replace(/\s+/g, ' ');

describe('c-external-component', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders the third-party element with value, max and spread attributes once loaded', async () => {
        loadScript.mockResolvedValue();
        const element = await mount();

        const stars = element.shadowRoot.querySelector('w27-rating-stars');
        expect(loadScript).toHaveBeenCalledTimes(1);
        expect(stars).not.toBeNull();
        expect(stars.getAttribute('value')).toBe('4');
        expect(stars.getAttribute('max')).toBe('5');
        expect(stars.getAttribute('title')).toBe('Product rating');
        expect(stars.shadowRoot.querySelectorAll('button.on')).toHaveLength(4);
        expect(stateText(element)).toContain('rating = 4 / 5 🔥');
    });

    it('updates LWC state when the element fires a rate event', async () => {
        loadScript.mockResolvedValue();
        const element = await mount();

        const stars = element.shadowRoot.querySelector('w27-rating-stars');
        stars.shadowRoot.querySelectorAll('button')[1].click();
        await flushPromises();

        expect(stateText(element)).toContain('rating = 2 / 5');
        expect(stateText(element)).not.toContain('🔥');
        expect(stars.getAttribute('value')).toBe('2');
    });

    it('shows an error when the static resource fails to load', async () => {
        loadScript.mockRejectedValue(new Error('boom'));
        const element = await mount();

        expect(element.shadowRoot.querySelector('w27-rating-stars')).toBeNull();
        expect(
            element.shadowRoot.querySelector('[role="alert"]').textContent
        ).toBe('boom');
    });
});
