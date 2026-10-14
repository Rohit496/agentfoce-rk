import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import locale from '@salesforce/i18n/locale';
import NAME from '@salesforce/schema/Account.Name';
import RATING from '@salesforce/schema/Account.Rating';
import TYPE from '@salesforce/schema/Account.Type';
import INDUSTRY from '@salesforce/schema/Account.Industry';
import PHONE from '@salesforce/schema/Account.Phone';
import WEBSITE from '@salesforce/schema/Account.Website';

const FIELDS = [NAME, RATING, TYPE, INDUSTRY, PHONE, WEBSITE];

// Events from the iframe are untrusted input; only accept known picklist values.
const ALLOWED_RATINGS = new Set(['Hot', 'Warm', 'Cold']);

export default class AccountEmbeddedNextjsApp extends LightningElement {
    @api recordId;
    @api baseUrl = 'http://localhost:5184';

    // Reassigned only when record data changes, so re-renders don't push duplicate snapshots.
    account = {};
    isLoading = true;
    errorMessage;
    hasWiredEvents = false;

    connectedCallback() {
        this.account = { recordId: this.recordId };
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            this.account = {
                recordId: this.recordId,
                name: getFieldValue(data, NAME),
                rating: getFieldValue(data, RATING),
                type: getFieldValue(data, TYPE),
                industry: getFieldValue(data, INDUSTRY),
                phone: getFieldValue(data, PHONE),
                website: getFieldValue(data, WEBSITE)
            };
        } else if (error) {
            this.errorMessage = error?.body?.message ?? 'Unable to load the Account.';
        }
    }

    // src binds the embedding session; it must not change after mount.
    get computedSrc() {
        return this.baseUrl;
    }

    // Event names contain dots, so they can't be bound with on* template attributes.
    renderedCallback() {
        if (this.hasWiredEvents) {
            return;
        }
        this.hasWiredEvents = true;

        const el = this.refs.embedding;
        el.addEventListener('sf-embedding.component.ready', this.handleReady);
        el.addEventListener('sf-embedding.component.error', this.handleError);
    }

    handleReady = () => {
        this.isLoading = false;
        this.errorMessage = undefined;
        this.refs.embedding.dispatchEvent(
            new CustomEvent('localeInformation', { detail: { locale } })
        );
    };

    handleError = (event) => {
        const { phase, code, message } = event.detail ?? {};
        this.isLoading = false;
        this.errorMessage = `Embedded app failed to load (${phase}/${code}): ${message}`;
    };

    async handleRatingChange(event) {
        const { rating } = event.detail ?? {};
        if (!this.recordId || !ALLOWED_RATINGS.has(rating)) {
            return;
        }
        try {
            await updateRecord({ fields: { Id: this.recordId, Rating: rating } });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Account updated',
                    message: `Rating set to ${rating}.`,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Update failed',
                    message: error?.body?.message ?? error?.message ?? 'Unknown error',
                    variant: 'error'
                })
            );
        }
    }
}
