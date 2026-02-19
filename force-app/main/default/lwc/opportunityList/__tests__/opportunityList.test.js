import { createElement } from 'lwc';
import OpportunityList from 'c/opportunityList';

const MOCK_OPPORTUNITIES = [
    {
        id: '001',
        name: 'Enterprise Deal',
        accountName: 'Acme Corp',
        amount: 100000,
        closeDate: '2026-03-15'
    },
    {
        id: '002',
        name: 'Small Business Package',
        accountName: 'Global Industries',
        amount: 25000,
        closeDate: '2026-04-20'
    },
    {
        id: '003',
        name: 'Mid-Market Solution',
        accountName: 'TechVentures Inc',
        amount: 75000,
        closeDate: '2026-05-10'
    },
    {
        id: '004',
        name: 'Strategic Partnership',
        accountName: 'Innovation Labs',
        amount: 200000,
        closeDate: '2026-06-30'
    }
];

// Mock NavigationMixin
const mockNavigate = jest.fn();

jest.mock(
    'lightning/navigation',
    () => {
        const Navigate = Symbol('Navigate');
        const NavigationMixin = (Base) => {
            return class extends Base {
                static [Navigate] = Navigate;
                [Navigate] = mockNavigate;
            };
        };
        NavigationMixin.Navigate = Navigate;
        return { NavigationMixin };
    },
    { virtual: true }
);

function flushPromises() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    return new Promise((resolve) => setTimeout(resolve, 0));
}

function createComponent(opportunities) {
    const element = createElement('c-opportunity-list', {
        is: OpportunityList
    });
    element.value = opportunities;
    document.body.appendChild(element);
    return element;
}

describe('c-opportunity-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    describe('rendering with data', () => {
        it('renders opportunity cards when data is provided', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const opportunityCards =
                element.shadowRoot.querySelectorAll('.opportunity-card');
            // pageSize is 3, so only 3 should be visible on page 1
            expect(opportunityCards.length).toBe(3);
        });

        it('displays opportunity name for each visible opportunity', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const headings =
                element.shadowRoot.querySelectorAll('.opportunity-card h2');
            expect(headings[0].textContent).toBe('Enterprise Deal');
            expect(headings[1].textContent).toBe('Small Business Package');
            expect(headings[2].textContent).toBe('Mid-Market Solution');
        });

        it('displays account name, amount, and close date details', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const details = element.shadowRoot.querySelectorAll(
                '.opportunity-card:first-child .opp-detail'
            );
            expect(details[0].textContent).toContain('Acme Corp');
            expect(details[1].textContent).toContain('$100,000');
            expect(details[2].textContent).toContain('Mar');
        });

        it('formats currency correctly', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const amountDetails =
                element.shadowRoot.querySelectorAll('.opp-detail.amount');
            expect(amountDetails[0].textContent).toContain('$100,000');
            expect(amountDetails[1].textContent).toContain('$25,000');
        });

        it('formats date correctly', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const dateDetails = element.shadowRoot.querySelectorAll(
                '.opp-detail.close-date'
            );
            expect(dateDetails[0].textContent).toContain('2026');
        });
    });

    describe('rendering without data', () => {
        it('shows no-data message when value is empty array', async () => {
            const element = createComponent([]);
            await flushPromises();

            const noDataDiv = element.shadowRoot.querySelector(
                '.slds-text-color_weak'
            );
            expect(noDataDiv).not.toBeNull();
            expect(noDataDiv.textContent).toBe(
                'No opportunity data available.'
            );
        });

        it('shows no-data message when value is null', async () => {
            const element = createComponent(null);
            await flushPromises();

            const opportunityCards =
                element.shadowRoot.querySelectorAll('.opportunity-card');
            expect(opportunityCards.length).toBe(0);
        });

        it('handles null amount gracefully', async () => {
            const oppWithNullAmount = [
                {
                    id: '005',
                    name: 'No Amount Deal',
                    accountName: 'Test Account',
                    amount: null,
                    closeDate: '2026-07-01'
                }
            ];
            const element = createComponent(oppWithNullAmount);
            await flushPromises();

            const amountDetail =
                element.shadowRoot.querySelector('.opp-detail.amount');
            expect(amountDetail.textContent).toContain('N/A');
        });
    });

    describe('pagination', () => {
        it('displays correct page info', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const pageText = element.shadowRoot.querySelector('.page-text');
            expect(pageText.textContent).toBe('Page 1 of 2');
        });

        it('disables Previous button on first page', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const buttons =
                element.shadowRoot.querySelectorAll('lightning-button');
            const prevButton = buttons[0];
            expect(prevButton.disabled).toBe(true);
        });

        it('enables Next button when more pages exist', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const buttons =
                element.shadowRoot.querySelectorAll('lightning-button');
            const nextButton = buttons[1];
            expect(nextButton.disabled).toBe(false);
        });

        it('navigates to next page on Next click', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const nextButton =
                element.shadowRoot.querySelectorAll('lightning-button')[1];
            nextButton.click();
            await flushPromises();

            const pageText = element.shadowRoot.querySelector('.page-text');
            expect(pageText.textContent).toBe('Page 2 of 2');

            const opportunityCards =
                element.shadowRoot.querySelectorAll('.opportunity-card');
            expect(opportunityCards.length).toBe(1);

            const heading = element.shadowRoot.querySelector(
                '.opportunity-card h2'
            );
            expect(heading.textContent).toBe('Strategic Partnership');
        });

        it('navigates back on Previous click', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            // Go to page 2
            const nextButton =
                element.shadowRoot.querySelectorAll('lightning-button')[1];
            nextButton.click();
            await flushPromises();

            // Go back to page 1
            const prevButton =
                element.shadowRoot.querySelectorAll('lightning-button')[0];
            prevButton.click();
            await flushPromises();

            const pageText = element.shadowRoot.querySelector('.page-text');
            expect(pageText.textContent).toBe('Page 1 of 2');
        });

        it('disables Next button on last page', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const nextButton =
                element.shadowRoot.querySelectorAll('lightning-button')[1];
            nextButton.click();
            await flushPromises();

            expect(nextButton.disabled).toBe(true);
        });

        it('does not go beyond last page', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            // Click next twice (only 2 pages exist)
            const nextButton =
                element.shadowRoot.querySelectorAll('lightning-button')[1];
            nextButton.click();
            await flushPromises();
            nextButton.click();
            await flushPromises();

            const pageText = element.shadowRoot.querySelector('.page-text');
            expect(pageText.textContent).toBe('Page 2 of 2');
        });

        it('does not go before first page', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const prevButton =
                element.shadowRoot.querySelectorAll('lightning-button')[0];
            prevButton.click();
            await flushPromises();

            const pageText = element.shadowRoot.querySelector('.page-text');
            expect(pageText.textContent).toBe('Page 1 of 2');
        });
    });

    describe('search', () => {
        it('filters opportunities by name', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const searchInput =
                element.shadowRoot.querySelector('lightning-input');
            searchInput.value = 'enterprise';
            searchInput.dispatchEvent(
                new CustomEvent('change', { detail: { value: 'enterprise' } })
            );
            await flushPromises();

            const opportunityCards =
                element.shadowRoot.querySelectorAll('.opportunity-card');
            expect(opportunityCards.length).toBe(1);

            const heading = element.shadowRoot.querySelector(
                '.opportunity-card h2'
            );
            expect(heading.textContent).toBe('Enterprise Deal');
        });

        it('filters opportunities by account name', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const searchInput =
                element.shadowRoot.querySelector('lightning-input');
            searchInput.value = 'global';
            searchInput.dispatchEvent(
                new CustomEvent('change', { detail: { value: 'global' } })
            );
            await flushPromises();

            const opportunityCards =
                element.shadowRoot.querySelectorAll('.opportunity-card');
            expect(opportunityCards.length).toBe(1);

            const heading = element.shadowRoot.querySelector(
                '.opportunity-card h2'
            );
            expect(heading.textContent).toBe('Small Business Package');
        });

        it('resets to page 1 after search', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            // Go to page 2
            const nextButton =
                element.shadowRoot.querySelectorAll('lightning-button')[1];
            nextButton.click();
            await flushPromises();

            // Search
            const searchInput =
                element.shadowRoot.querySelector('lightning-input');
            searchInput.value = 'enterprise';
            searchInput.dispatchEvent(new CustomEvent('change'));
            await flushPromises();

            const pageText = element.shadowRoot.querySelector('.page-text');
            expect(pageText.textContent).toBe('Page 1 of 1');
        });

        it('shows no-data message when search has no results', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const searchInput =
                element.shadowRoot.querySelector('lightning-input');
            searchInput.value = 'zzzzz';
            searchInput.dispatchEvent(new CustomEvent('change'));
            await flushPromises();

            const noDataDiv = element.shadowRoot.querySelector(
                '.slds-text-color_weak'
            );
            expect(noDataDiv).not.toBeNull();
        });

        it('is case-insensitive', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const searchInput =
                element.shadowRoot.querySelector('lightning-input');
            searchInput.value = 'ACME';
            searchInput.dispatchEvent(new CustomEvent('change'));
            await flushPromises();

            const opportunityCards =
                element.shadowRoot.querySelectorAll('.opportunity-card');
            expect(opportunityCards.length).toBe(1);
        });
    });

    describe('navigation', () => {
        it('navigates to opportunity record on button click', async () => {
            const element = createComponent(MOCK_OPPORTUNITIES);
            await flushPromises();

            const selectButton = element.shadowRoot.querySelector(
                'lightning-button-icon'
            );
            selectButton.dataset.oppId = '001';
            selectButton.click();
            await flushPromises();

            expect(mockNavigate).toHaveBeenCalledWith({
                type: 'standard__recordPage',
                attributes: {
                    recordId: '001',
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            });
        });
    });

    describe('@api value property', () => {
        it('accepts value via setter', () => {
            const element = createElement('c-opportunity-list', {
                is: OpportunityList
            });
            element.value = MOCK_OPPORTUNITIES;
            expect(element.value).toEqual(MOCK_OPPORTUNITIES);
        });
    });
});
