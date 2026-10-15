import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import RATING_STARS from '@salesforce/resourceUrl/w27RatingStars';

export default class ExternalComponent extends LightningElement {
    rating = 4;
    max = 5;
    // lwc:spread sets properties, so spread real element properties (a 'data-*' key would not become an attribute).
    starProps = { title: 'Product rating' };
    libraryLoaded = false;
    errorMessage;

    async connectedCallback() {
        try {
            await loadScript(this, RATING_STARS);
            this.libraryLoaded = true;
        } catch (error) {
            this.errorMessage =
                error?.message ??
                'Could not load the w27RatingStars static resource.';
        }
    }

    handleRate(event) {
        this.rating = event.detail.value;
    }
}
