import { createElement } from '@lwc/engine-dom';
import ExternalComponent from 'c/externalComponent';
import { loadScript } from 'lightning/platformResourceLoader';
import { executeMutation, graphql } from 'lightning/graphql';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import Toast from 'lightning/toast';

// Define the real third-party element, as the static resource would in the org.
require('../../../staticresources/w27RatingStars.js');

jest.mock(
    'lightning/platformResourceLoader',
    () => ({ loadScript: jest.fn() }),
    { virtual: true }
);

// sfdx-lwc-jest has no stub for lightning/graphql yet.
jest.mock(
    'lightning/graphql',
    () => {
        const {
            createTestWireAdapter
        } = require('@salesforce/wire-service-jest-util');
        return {
            gql: (strings) => strings.join(''),
            graphql: createTestWireAdapter(jest.fn()),
            executeMutation: jest.fn()
        };
    },
    { virtual: true }
);

// What the LatestStarRating query returns for a record with (or without) a saved rating.
const latestRating = (rating) => ({
    data: {
        uiapi: {
            query: {
                Star_Rating__c: {
                    edges:
                        rating === undefined
                            ? []
                            : [
                                  {
                                      node: {
                                          Id: 'a0Bxx0000000009AAA',
                                          Rating__c: { value: rating }
                                      }
                                  }
                              ]
                }
            }
        }
    },
    errors: undefined,
    refresh: jest.fn().mockResolvedValue()
});

const savedRecord = (id, name) => ({
    Id: id,
    Name: { value: name },
    LastModifiedDate: { value: '2026-10-15T10:30:00.000Z' }
});

const SAVED_RESPONSE = {
    data: {
        uiapi: {
            Star_Rating__cCreate: {
                Record: savedRecord('a0Bxx0000000001AAA', 'SR-000001')
            }
        }
    },
    errors: []
};

const UPDATED_RESPONSE = {
    data: {
        uiapi: {
            Star_Rating__cUpdate: {
                Record: savedRecord('a0Bxx0000000009AAA', 'SR-000009')
            }
        }
    },
    errors: []
};

// Answers like the org: create and update mutations return their own shapes.
const isUpdate = (call) => call.query.includes('Star_Rating__cUpdate');
const mutationResponse = (call) =>
    Promise.resolve(isUpdate(call) ? UPDATED_RESPONSE : SAVED_RESPONSE);

const flushPromises = async () => {
    await Promise.resolve();
    await Promise.resolve();
};

const mount = async (recordId) => {
    const element = createElement('c-external-component', {
        is: ExternalComponent
    });
    element.recordId = recordId;
    document.body.appendChild(element);
    await flushPromises();
    return element;
};

const stateText = (element) =>
    element.shadowRoot
        .querySelector('p[aria-live]')
        .textContent.replace(/\s+/g, ' ');

const saveStatus = (element) =>
    element.shadowRoot
        .querySelector('[data-id="save-status"]')
        .textContent.replace(/\s+/g, ' ')
        .trim();

const clickStar = async (element, index) => {
    const stars = element.shadowRoot.querySelector('w27-rating-stars');
    stars.shadowRoot.querySelectorAll('button')[index].click();
    await flushPromises();
    await flushPromises();
};

describe('c-external-component', () => {
    beforeEach(() => {
        jest.spyOn(Toast, 'show').mockImplementation(() => {});
    });

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
        expect(stars.getAttribute('value')).toBe('0');
        expect(stars.getAttribute('max')).toBe('5');
        expect(stars.getAttribute('title')).toBe('Product rating');
        expect(stars.shadowRoot.querySelectorAll('button.on')).toHaveLength(0);
        expect(stateText(element)).toContain('rating = 0 / 5');
        expect(stateText(element)).not.toContain('🔥');
    });

    it('shows the latest saved rating for the record page it is on', async () => {
        loadScript.mockResolvedValue();
        const element = await mount('003xx000004TmiQAAS');

        graphql.emit(latestRating(5));
        await flushPromises();

        const stars = element.shadowRoot.querySelector('w27-rating-stars');
        expect(graphql.getLastConfig().variables).toEqual({
            recordId: '003xx000004TmiQAAS'
        });
        expect(stars.getAttribute('value')).toBe('5');
        expect(stars.shadowRoot.querySelectorAll('button.on')).toHaveLength(5);
        expect(stars.className).toBe('rating_high');
        expect(stateText(element)).toContain('rating = 5 / 5 🔥');
        expect(saveStatus(element)).toBe('Click a star to save a rating.');
    });

    it('starts with no stars when the record has no saved rating', async () => {
        loadScript.mockResolvedValue();
        const element = await mount('003xx000004TmiQAAS');

        graphql.emit(latestRating(undefined));
        await flushPromises();

        const stars = element.shadowRoot.querySelector('w27-rating-stars');
        expect(stars.getAttribute('value')).toBe('0');
        expect(saveStatus(element)).toBe('Click a star to save a rating.');
    });

    it('does not look up a saved rating when the page has no record', async () => {
        loadScript.mockResolvedValue();
        await mount();

        expect(graphql.getLastConfig()?.query).toBeUndefined();
    });

    it('colours the stars red for 1-2, yellow for 3 and green for 4-5', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
        const element = await mount();
        const stars = element.shadowRoot.querySelector('w27-rating-stars');

        const classFor = async (index) => {
            await clickStar(element, index);
            return stars.className;
        };

        expect(await classFor(0)).toBe('rating_low');
        expect(await classFor(1)).toBe('rating_low');
        expect(await classFor(2)).toBe('rating_medium');
        expect(await classFor(3)).toBe('rating_high');
        expect(await classFor(4)).toBe('rating_high');
    });

    it('refreshes the saved rating after a save so it stays current', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
        const element = await mount('003xx000004TmiQAAS');
        const loaded = latestRating(2);
        graphql.emit(loaded);
        await flushPromises();

        await clickStar(element, 4);

        expect(loaded.refresh).toHaveBeenCalledTimes(1);
    });

    it("updates the record's existing rating instead of creating another one", async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
        const element = await mount('003xx000004TmiQAAS');
        graphql.emit(latestRating(2));
        await flushPromises();

        await clickStar(element, 4);

        expect(executeMutation).toHaveBeenCalledTimes(1);
        const call = executeMutation.mock.calls[0][0];
        expect(isUpdate(call)).toBe(true);
        expect(call.variables).toEqual({
            input: {
                Id: 'a0Bxx0000000009AAA',
                Star_Rating__c: {
                    Rating__c: 5,
                    Max_Rating__c: 5,
                    Related_Object__c: null,
                    Related_Record_Name__c: null
                }
            }
        });
        expect(Toast.show.mock.calls[0][0]).toEqual({
            variant: 'success',
            label: 'Rating updated',
            message: expect.stringContaining('5 / 5 saved as SR-000009 at ')
        });
    });

    it('creates the first rating, then updates that same record on the next click', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
        const element = await mount('003xx000004TmiQAAS');
        graphql.emit(latestRating(undefined));
        await flushPromises();

        await clickStar(element, 1);
        await clickStar(element, 2);

        expect(executeMutation).toHaveBeenCalledTimes(2);
        const [first, second] = executeMutation.mock.calls.map((c) => c[0]);
        expect(isUpdate(first)).toBe(false);
        expect(isUpdate(second)).toBe(true);
        expect(second.variables.input.Id).toBe('a0Bxx0000000001AAA');
        expect(Toast.show.mock.calls.map((c) => c[0].label)).toEqual([
            'Rating saved',
            'Rating updated'
        ]);
    });

    it('updates the existing rating named in the duplicate error when another tab or user rated first', async () => {
        loadScript.mockResolvedValue();
        const element = await mount('003xx000004TmiQAAS');
        // The record looks unrated on load; someone rates it before this click.
        const loaded = latestRating(undefined);
        graphql.emit(loaded);
        await flushPromises();
        const duplicateError = {
            data: null,
            errors: [
                {
                    message:
                        'duplicate value found: Related_Record_Id__c duplicates value on record with id: a0Bxx0000000009AAA'
                }
            ]
        };
        executeMutation.mockImplementation((call) => {
            return Promise.resolve(
                isUpdate(call) ? UPDATED_RESPONSE : duplicateError
            );
        });

        await clickStar(element, 2);
        await flushPromises();

        const calls = executeMutation.mock.calls.map((c) => c[0]);
        expect(calls.map(isUpdate)).toEqual([false, true]);
        expect(calls[1].variables.input.Id).toBe('a0Bxx0000000009AAA');
        // The Id came from the error message: the update ran before any reload. The only
        // refresh is the usual sync after a successful save.
        expect(loaded.refresh).toHaveBeenCalledTimes(1);
        expect(executeMutation.mock.invocationCallOrder[1]).toBeLessThan(
            loaded.refresh.mock.invocationCallOrder[0]
        );
        expect(Toast.show).toHaveBeenCalledTimes(1);
        expect(Toast.show.mock.calls[0][0]).toEqual({
            variant: 'success',
            label: 'Rating updated',
            message: expect.stringContaining('3 / 5 saved as SR-000009 at ')
        });
        expect(saveStatus(element)).toBe('Click a star to save a rating.');
    });

    it('falls back to reloading the rating when the duplicate error has no record Id', async () => {
        loadScript.mockResolvedValue();
        const element = await mount('003xx000004TmiQAAS');
        const loaded = latestRating(undefined);
        loaded.refresh.mockImplementation(async () => {
            graphql.emit(latestRating(4));
        });
        graphql.emit(loaded);
        await flushPromises();
        const duplicateError = {
            data: null,
            errors: [{ message: 'DUPLICATE_VALUE: duplicate value found' }]
        };
        executeMutation.mockImplementation((call) => {
            return Promise.resolve(
                isUpdate(call) ? UPDATED_RESPONSE : duplicateError
            );
        });

        await clickStar(element, 4);
        await flushPromises();

        const calls = executeMutation.mock.calls.map((c) => c[0]);
        expect(loaded.refresh).toHaveBeenCalled();
        expect(calls.map(isUpdate)).toEqual([false, true]);
        expect(calls[1].variables.input.Id).toBe('a0Bxx0000000009AAA');
        expect(Toast.show.mock.calls[0][0].label).toBe('Rating updated');
    });

    it('warns when the saved rating cannot be loaded', async () => {
        loadScript.mockResolvedValue();
        await mount('003xx000004TmiQAAS');

        graphql.emit({
            data: undefined,
            errors: [{ message: 'No access to Star Rating.' }],
            refresh: jest.fn()
        });
        await flushPromises();

        expect(Toast.show.mock.calls[0][0]).toEqual({
            variant: 'warning',
            label: 'Saved rating not loaded',
            message: 'No access to Star Rating.'
        });
    });

    it('shows a prompt before any rating is saved', async () => {
        loadScript.mockResolvedValue();
        const element = await mount();

        expect(executeMutation).not.toHaveBeenCalled();
        expect(saveStatus(element)).toBe('Click a star to save a rating.');
    });

    it('saves the clicked rating with the page record id and shows when it was saved', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
        const element = await mount('001xx000003DGb2AAG');

        await clickStar(element, 2);

        expect(executeMutation).toHaveBeenCalledTimes(1);
        expect(executeMutation.mock.calls[0][0].variables).toEqual({
            input: {
                Star_Rating__c: {
                    Rating__c: 3,
                    Max_Rating__c: 5,
                    Related_Record_Id__c: '001xx000003DGb2AAG',
                    Related_Object__c: null,
                    Related_Record_Name__c: null
                }
            }
        });
        // The saved record and time go in the toast only, not on the card.
        expect(saveStatus(element)).toBe('Click a star to save a rating.');
        expect(element.shadowRoot.textContent).not.toContain('SR-000001');
        expect(Toast.show).toHaveBeenCalledTimes(1);
        expect(Toast.show.mock.calls[0][0]).toEqual({
            variant: 'success',
            label: 'Rating saved',
            message: expect.stringContaining('3 / 5 saved as SR-000001 at ')
        });
    });

    it('shows a warning toast when the rating is saved but Salesforce also reports a problem', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockResolvedValue({
            ...SAVED_RESPONSE,
            errors: [{ message: 'Field Related_Object__c is not readable.' }]
        });
        const element = await mount();

        await clickStar(element, 3);

        expect(saveStatus(element)).toBe('Click a star to save a rating.');
        expect(Toast.show.mock.calls[0][0]).toEqual({
            variant: 'warning',
            label: 'Rating saved with a warning',
            message: expect.stringContaining(
                'Field Related_Object__c is not readable.'
            )
        });
    });

    it('falls back to the record page URL when the platform leaves recordId unset', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
        const element = await mount();
        CurrentPageReference.emit({
            type: 'standard__recordPage',
            attributes: {
                recordId: '001xx000003DGb2AAG',
                objectApiName: 'Account',
                actionName: 'view'
            }
        });

        await clickStar(element, 0);

        expect(
            executeMutation.mock.calls[0][0].variables.input.Star_Rating__c
                .Related_Record_Id__c
        ).toBe('001xx000003DGb2AAG');
    });

    it('saves the related object and record name so the list can link to the record', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
        const element = await mount('001xx000003DGb2AAG');
        element.objectApiName = 'Account';
        await flushPromises();
        getRecord.emit({
            apiName: 'Account',
            id: '001xx000003DGb2AAG',
            fields: { Name: { value: 'Acme Corp', displayValue: null } }
        });

        await clickStar(element, 3);

        expect(
            executeMutation.mock.calls[0][0].variables.input.Star_Rating__c
        ).toEqual({
            Rating__c: 4,
            Max_Rating__c: 5,
            Related_Record_Id__c: '001xx000003DGb2AAG',
            Related_Object__c: 'Account',
            Related_Record_Name__c: 'Acme Corp'
        });
        expect(getRecord.getLastConfig()).toEqual({
            recordId: '001xx000003DGb2AAG',
            optionalFields: ['Account.Name']
        });
    });

    it('saves the object from the page reference when the record has no Name field', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
        const element = await mount();
        CurrentPageReference.emit({
            type: 'standard__recordPage',
            attributes: {
                recordId: '500xx000000AbcdAAA',
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
        getRecord.emit({
            apiName: 'Case',
            id: '500xx000000AbcdAAA',
            fields: {}
        });

        await clickStar(element, 1);

        const saved =
            executeMutation.mock.calls[0][0].variables.input.Star_Rating__c;
        expect(saved.Related_Record_Id__c).toBe('500xx000000AbcdAAA');
        expect(saved.Related_Object__c).toBe('Case');
        expect(saved.Related_Record_Name__c).toBeNull();
    });

    it('sends a null record id when the component is not on a record page', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
        const element = await mount();

        CurrentPageReference.emit({
            type: 'standard__navItemPage',
            attributes: { apiName: 'Third_Party_Web_Component' }
        });

        await clickStar(element, 4);

        expect(
            executeMutation.mock.calls[0][0].variables.input.Star_Rating__c
        ).toEqual({
            Rating__c: 5,
            Max_Rating__c: 5,
            Related_Record_Id__c: null,
            Related_Object__c: null,
            Related_Record_Name__c: null
        });
    });

    it('shows the GraphQL error when the save is rejected', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockResolvedValue({
            data: null,
            errors: [
                { message: 'Rating must be between 1 and the maximum rating.' }
            ]
        });
        const element = await mount();

        await clickStar(element, 0);

        expect(saveStatus(element)).toBe(
            'Not saved: Rating must be between 1 and the maximum rating.'
        );
        expect(stateText(element)).toContain('rating = 1 / 5');
        expect(Toast.show.mock.calls[0][0]).toEqual({
            variant: 'error',
            label: 'Rating not saved',
            message: 'Rating must be between 1 and the maximum rating.'
        });
    });

    it('shows the error when the save request fails', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockRejectedValue(new Error('Network down'));
        const element = await mount();

        await clickStar(element, 1);

        expect(saveStatus(element)).toBe('Not saved: Network down');
        expect(Toast.show.mock.calls[0][0]).toEqual({
            variant: 'error',
            label: 'Rating not saved',
            message: 'Network down'
        });
    });

    it('updates LWC state when the element fires a rate event', async () => {
        loadScript.mockResolvedValue();
        executeMutation.mockImplementation(mutationResponse);
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
        expect(Toast.show.mock.calls[0][0]).toEqual({
            variant: 'error',
            label: 'Rating stars unavailable',
            message: 'boom'
        });
    });
});
