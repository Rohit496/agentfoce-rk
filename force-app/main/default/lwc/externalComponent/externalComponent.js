import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { loadScript } from 'lightning/platformResourceLoader';
import { gql, graphql, executeMutation } from 'lightning/graphql';
// lightning/toast works in Lightning Experience, Experience Builder sites (including LWR)
// and the mobile app; ShowToastEvent doesn't work on LWR sites.
import Toast from 'lightning/toast';
import LOCALE from '@salesforce/i18n/locale';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import RATING_STARS from '@salesforce/resourceUrl/w27RatingStars';

// The user's Salesforce locale and time zone, for the timestamp in the success toast.
const TIME_FORMAT = new Intl.DateTimeFormat(LOCALE, {
    dateStyle: 'medium',
    timeStyle: 'medium',
    timeZone: TIME_ZONE
});

// One Star_Rating__c per record: the first rating creates it, later ratings update it.
// LastModifiedDate (server time) is when it was last rated.
const CREATE_RATING = gql`
    mutation CreateStarRating($input: Star_Rating__cCreateInput!) {
        uiapi {
            Star_Rating__cCreate(input: $input) {
                Record {
                    Id
                    Name {
                        value
                    }
                    LastModifiedDate {
                        value
                    }
                }
            }
        }
    }
`;

const UPDATE_RATING = gql`
    mutation UpdateStarRating($input: Star_Rating__cUpdateInput!) {
        uiapi {
            Star_Rating__cUpdate(input: $input) {
                Record {
                    Id
                    Name {
                        value
                    }
                    LastModifiedDate {
                        value
                    }
                }
            }
        }
    }
`;

// The page's record's rating (one per record; newest first in case of old duplicates).
const LATEST_RATING = gql`
    query LatestStarRating($recordId: String) {
        uiapi {
            query {
                Star_Rating__c(
                    where: { Related_Record_Id__c: { eq: $recordId } }
                    orderBy: {
                        LastModifiedDate: { order: DESC }
                        Name: { order: DESC }
                    }
                    first: 1
                ) {
                    edges {
                        node {
                            Id
                            Rating__c {
                                value
                            }
                        }
                    }
                }
            }
        }
    }
`;

export default class ExternalComponent extends LightningElement {
    // Set when the component is on a record page; saved with the rating.
    @api recordId;
    @api objectApiName;

    // On a full page load (e.g. right after login) the platform can leave recordId unset,
    // while the page reference still has it (seen 2026-10-15), so it's the fallback.
    @wire(CurrentPageReference)
    pageRef;

    // The page's record name, saved with each rating so the Star Ratings list can show a
    // readable link. optionalFields: objects without a Name field just return no value.
    @wire(getRecord, {
        recordId: '$contextRecordId',
        optionalFields: '$nameFields'
    })
    contextRecord;

    get contextRecordId() {
        return this.recordId ?? this.pageRef?.attributes?.recordId;
    }

    get contextObjectApiName() {
        return this.objectApiName ?? this.pageRef?.attributes?.objectApiName;
    }

    get nameFields() {
        return this.contextObjectApiName
            ? [`${this.contextObjectApiName}.Name`]
            : undefined;
    }

    // Runs only on record pages: an undefined query keeps the wire from provisioning.
    @wire(graphql, {
        query: '$latestRatingQuery',
        variables: '$latestRatingVariables'
    })
    handleLatestRating({ data, errors, refresh }) {
        this.refreshLatestRating = refresh;
        if (errors?.length) {
            this.toast(
                'warning',
                'Saved rating not loaded',
                errors[0].message ?? 'The saved rating could not be loaded.'
            );
            return;
        }
        if (!data) {
            return;
        }
        const node = data.uiapi.query.Star_Rating__c.edges[0]?.node;
        // Always keep the Id, so the next click updates this record instead of creating one.
        this.ratingRecordId = node?.Id ?? this.ratingRecordId;
        if (!this.isSaving) {
            this.rating = node?.Rating__c?.value ?? 0;
        }
    }

    get latestRatingQuery() {
        return this.contextRecordId ? LATEST_RATING : undefined;
    }

    get latestRatingVariables() {
        return { recordId: this.contextRecordId };
    }

    // 0 until the record's saved rating loads; stays 0 when it has none.
    rating = 0;
    max = 5;
    // lwc:spread sets properties, so spread real element properties (a 'data-*' key would not become an attribute).
    starProps = { title: 'Product rating' };
    libraryLoaded = false;
    errorMessage;

    isSaving = false;
    saveError;
    refreshLatestRating;
    // Id of this record's Star_Rating__c, once known (loaded or created).
    ratingRecordId;
    // Fast clicks start overlapping saves; only the newest one updates the status line.
    saveSequence = 0;

    async connectedCallback() {
        try {
            await loadScript(this, RATING_STARS);
            this.libraryLoaded = true;
        } catch (error) {
            this.errorMessage =
                error?.message ??
                'Could not load the w27RatingStars static resource.';
            this.toast('error', 'Rating stars unavailable', this.errorMessage);
        }
    }

    toast(variant, label, message) {
        Toast.show({ variant, label, message }, this);
    }

    handleRate(event) {
        this.rating = event.detail.value;
        this.saveRating(this.rating);
    }

    async saveRating(rating) {
        const sequence = ++this.saveSequence;
        this.isSaving = true;
        this.saveError = undefined;

        const { record, message, updated } = await this.writeRating({
            Rating__c: rating,
            Max_Rating__c: this.max,
            Related_Object__c:
                this.contextRecord?.data?.apiName ??
                this.contextObjectApiName ??
                null,
            Related_Record_Name__c:
                this.contextRecord?.data?.fields?.Name?.value?.slice(0, 255) ??
                null
        });
        if (record) {
            this.ratingRecordId = record.Id;
        }

        if (sequence !== this.saveSequence) {
            return;
        }
        this.isSaving = false;
        if (record) {
            const summary = `${rating} / ${this.max} saved as ${record.Name.value} at ${TIME_FORMAT.format(new Date(record.LastModifiedDate.value))}.`;
            if (message) {
                // The record was saved, but Salesforce also reported a problem.
                this.toast(
                    'warning',
                    'Rating saved with a warning',
                    `${summary} ${message}`
                );
            } else {
                this.toast(
                    'success',
                    updated ? 'Rating updated' : 'Rating saved',
                    summary
                );
            }
            // Keep the wired rating in step with the server. A failed refresh reaches
            // handleLatestRating as errors, which shows its own toast.
            this.refreshLatestRating?.()?.catch(() => {});
        } else {
            this.saveError = message ?? 'The rating could not be saved.';
            this.toast('error', 'Rating not saved', this.saveError);
        }
    }

    // Updates the record's rating if it has one, otherwise creates it.
    // Resolves to { record, message, updated }.
    async writeRating(fields) {
        if (this.ratingRecordId) {
            return this.updateRating(fields);
        }
        const created = await this.runMutation(
            CREATE_RATING,
            {
                input: {
                    Star_Rating__c: {
                        ...fields,
                        Related_Record_Id__c: this.contextRecordId ?? null
                    }
                }
            },
            'Star_Rating__cCreate'
        );
        // Related_Record_Id__c is unique. If another click, tab or user created this
        // record's rating first, update that rating instead. The duplicate error names its
        // Id ("... on record with id: a0A..."); the wired query is the fallback.
        if (
            !created.record &&
            this.contextRecordId &&
            /duplicate/i.test(created.message ?? '')
        ) {
            const existingId = created.message.match(
                /with id:\s*([a-zA-Z0-9]{15,18})/
            )?.[1];
            if (existingId) {
                this.ratingRecordId = existingId;
            } else {
                await this.refreshLatestRating?.();
            }
            if (this.ratingRecordId) {
                return this.updateRating(fields);
            }
        }
        return { ...created, updated: false };
    }

    async updateRating(fields) {
        const result = await this.runMutation(
            UPDATE_RATING,
            { input: { Id: this.ratingRecordId, Star_Rating__c: fields } },
            'Star_Rating__cUpdate'
        );
        return { ...result, updated: true };
    }

    async runMutation(query, variables, operation) {
        try {
            const { data, errors } = await executeMutation({
                query,
                variables
            });
            return {
                record: data?.uiapi?.[operation]?.Record,
                message: errors?.[0]?.message
            };
        } catch (error) {
            return {
                record: undefined,
                message: error?.body?.message ?? error?.message
            };
        }
    }
}
