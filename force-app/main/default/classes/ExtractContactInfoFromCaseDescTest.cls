/**
 * Tests for ExtractContactInfoFromCaseDescription. The Einstein prompt-template call (ConnectApi.EinsteinLLM)
 * can't run in Apex tests, so these tests cover the parsing and Case update via applyCustomerInfo.
 */
@IsTest
private class ExtractContactInfoFromCaseDescTest {
    @TestSetup
    static void setupTestData() {
        insert TestDataFactory.buildCases(null, 1, 'New');
    }

    @IsTest
    static void shouldSaveNameEmailAndPhone_FromPromptJson() {
        // Given
        Case existing = [SELECT Id FROM Case LIMIT 1];
        String llmText = '{"name": "Jane Doe", "email": "jane@example.com", "phone": "555-0142"}';

        // When
        Test.startTest();
        ExtractContactInfoFromCaseDescription.applyCustomerInfo(existing.Id, llmText);
        Test.stopTest();

        // Then
        Case updated = [SELECT SuppliedName, SuppliedEmail, SuppliedPhone FROM Case WHERE Id = :existing.Id];
        Assert.areEqual('Jane Doe', updated.SuppliedName, 'The extracted name should be saved');
        Assert.areEqual('jane@example.com', updated.SuppliedEmail, 'The extracted email should be saved');
        Assert.areEqual('555-0142', updated.SuppliedPhone, 'The extracted phone should be saved');
    }

    @IsTest
    static void shouldStripNonPrintableCharacters_BeforeParsing() {
        // Given: LLM output with a non-breaking space and a newline around the JSON
        Case existing = [SELECT Id FROM Case LIMIT 1];
        String llmText = ' \n{"name": "Sam Lee", "email": "sam@example.com", "phone": null}\n';

        // When
        Test.startTest();
        ExtractContactInfoFromCaseDescription.applyCustomerInfo(existing.Id, llmText);
        Test.stopTest();

        // Then
        Case updated = [SELECT SuppliedName, SuppliedPhone FROM Case WHERE Id = :existing.Id];
        Assert.areEqual('Sam Lee', updated.SuppliedName, 'JSON wrapped in invisible characters should still parse');
        Assert.isNull(updated.SuppliedPhone, 'A null phone should be saved as empty');
    }

    @IsTest
    static void shouldThrowJsonException_WhenPromptReturnsNonJson() {
        // Given
        Case existing = [SELECT Id FROM Case LIMIT 1];

        // When / Then
        Test.startTest();
        try {
            ExtractContactInfoFromCaseDescription.applyCustomerInfo(existing.Id, 'Sorry, I could not find contact details.');
            Assert.fail('Expected JSONException for a non-JSON prompt answer');
        } catch (JSONException e) {
            Assert.isNotNull(e.getMessage(), 'The parse error should be reported');
        }
        Test.stopTest();
    }
}
