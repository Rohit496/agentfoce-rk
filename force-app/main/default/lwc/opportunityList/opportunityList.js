import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class OpportunityList extends NavigationMixin(
    LightningElement
) {
    opportunityData = [];
    filteredOpportunities = [];
    visibleOpportunities = [];
    currentPage = 1;
    pageSize = 3;
    searchKey = '';

    @api
    get value() {
        return this._value;
    }

    set value(value) {
        this._value = value;
    }

    connectedCallback() {
        let opportunities = this.value;

        if (opportunities && Array.isArray(opportunities)) {
            this.opportunityData = opportunities.map((opp) => ({
                ...opp,
                formattedAmount: this.formatCurrency(opp.amount),
                formattedCloseDate: this.formatDate(opp.closeDate)
            }));
            this.filteredOpportunities = [...this.opportunityData];
            this.updateVisibleOpportunities();
        } else {
            this.opportunityData = [];
            this.filteredOpportunities = [];
        }
    }

    formatCurrency(amount) {
        if (amount == null) return 'N/A';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    }

    formatDate(dateValue) {
        if (!dateValue) return 'N/A';
        const date = new Date(dateValue);
        return new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        }).format(date);
    }

    get hasOpportunities() {
        return this.filteredOpportunities.length > 0;
    }

    get totalPages() {
        return (
            Math.ceil(this.filteredOpportunities.length / this.pageSize) || 1
        );
    }

    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }

    get isPrevDisabled() {
        return this.currentPage <= 1;
    }

    updateVisibleOpportunities() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.visibleOpportunities = this.filteredOpportunities.slice(
            start,
            end
        );
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updateVisibleOpportunities();
        }
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updateVisibleOpportunities();
        }
    }

    handleSelectOpportunity(event) {
        const recordId = event.target.dataset.oppId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.filteredOpportunities = this.opportunityData.filter((opp) => {
            const name = opp.name ? opp.name.toLowerCase() : '';
            const accountName = opp.accountName
                ? opp.accountName.toLowerCase()
                : '';
            return (
                name.includes(this.searchKey) ||
                accountName.includes(this.searchKey)
            );
        });
        this.currentPage = 1;
        this.updateVisibleOpportunities();
    }
}
