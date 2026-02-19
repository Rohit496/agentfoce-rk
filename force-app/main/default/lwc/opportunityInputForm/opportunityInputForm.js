import { LightningElement, api } from 'lwc';

export default class OpportunityInputForm extends LightningElement {
    opportunityName = '';
    accountName = '';
    amount = null;
    closeDate = '';

    @api
    get value() {
        // Return CreateOpportunityRequest shape – the editor overrides the
        // root ($) of opportunityInputRequest, so we must include the oppdata
        // wrapper that the Apex invocable method expects.
        return {
            oppdata: {
                opportunityName: this.opportunityName,
                accountName: this.accountName,
                amount: this.amount,
                closeDate: this.closeDate || null
            }
        };
    }

    set value(val) {
        if (!val) {
            return;
        }
        // Support both envelope { oppdata: { ... } } and flat shape
        const payload = val.oppdata ? val.oppdata : val;

        this.opportunityName = payload.opportunityName || '';
        this.accountName = payload.accountName || '';
        this.amount = payload.amount != null ? payload.amount : null;
        this.closeDate = payload.closeDate || '';
    }

    handleInputChange(event) {
        const field = event.target.name;
        const value = event.target.value;

        if (field === 'opportunityName') {
            this.opportunityName = value;
        } else if (field === 'accountName') {
            this.accountName = value;
        } else if (field === 'amount') {
            // Handle amount field from regular input
            this.amount =
                value !== null && value !== '' ? parseFloat(value) : null;
        }
        this.notifyValueChange();
    }

    handleLightningInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;

        if (field === 'amount') {
            this.amount =
                value !== null && value !== '' ? parseFloat(value) : null;
        } else if (field === 'closeDate') {
            this.closeDate = value;
        }
        this.notifyValueChange();
    }

    notifyValueChange() {
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: { value: this.value }
            })
        );
    }
}
