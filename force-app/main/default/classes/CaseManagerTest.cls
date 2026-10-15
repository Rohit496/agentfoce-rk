/**
 * Tests for the CaseManager REST resource (GET, POST, PUT, PATCH, DELETE /apex-rest-examples/v1/Cases/{id}).
 */
@IsTest
private class CaseManagerTest {
    @TestSetup
    static void setupTestData() {
        insert TestDataFactory.buildCases(null, 1, 'New');
    }

    private static Case existingCase() {
        return [SELECT Id, CaseNumber, Subject, Status FROM Case LIMIT 1];
    }

    private static void setRequest(String method, Id caseId, String jsonBody) {
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/apex-rest-examples/v1/Cases/' + caseId;
        request.httpMethod = method;
        if (jsonBody != null) {
            request.requestBody = Blob.valueOf(jsonBody);
        }
        RestContext.request = request;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void shouldReturnCase_WhenGetById() {
        // Given
        Case existing = existingCase();
        setRequest('GET', existing.Id, null);

        // When
        Test.startTest();
        Case result = CaseManager.getCaseById();
        Test.stopTest();

        // Then
        Assert.areEqual(existing.CaseNumber, result.CaseNumber, 'The requested Case should be returned');
        Assert.areEqual('Test Case 0', result.Subject, 'Subject should be returned');
    }

    @IsTest
    static void shouldCreateCase_WhenPost() {
        // When
        Test.startTest();
        Id newId = CaseManager.createCase('Created via POST', 'New', 'Phone', 'High');
        Test.stopTest();

        // Then
        Case created = [SELECT Subject, Status, Origin, Priority FROM Case WHERE Id = :newId];
        Assert.areEqual('Created via POST', created.Subject, 'Subject should be saved');
        Assert.areEqual('Phone', created.Origin, 'Origin should be saved');
        Assert.areEqual('High', created.Priority, 'Priority should be saved');
    }

    @IsTest
    static void shouldUpdateExistingCase_WhenPutWithId() {
        // Given
        Case existing = existingCase();

        // When
        Test.startTest();
        Id resultId = CaseManager.upsertCase('Updated via PUT', 'Working', 'Email', 'Medium', existing.Id);
        Test.stopTest();

        // Then
        Assert.areEqual(existing.Id, resultId, 'PUT with an Id should update, not insert');
        Case updated = [SELECT Subject, Status FROM Case WHERE Id = :existing.Id];
        Assert.areEqual('Updated via PUT', updated.Subject, 'Subject should be updated');
        Assert.areEqual('Working', updated.Status, 'Status should be updated');
        Assert.areEqual(1, [SELECT COUNT() FROM Case], 'No extra Case should be created');
    }

    @IsTest
    static void shouldInsertCase_WhenPutWithoutId() {
        // When
        Test.startTest();
        Id resultId = CaseManager.upsertCase('Inserted via PUT', 'New', 'Web', 'Low', null);
        Test.stopTest();

        // Then
        Assert.isNotNull(resultId, 'PUT without an Id should insert a new Case');
        Assert.areEqual(2, [SELECT COUNT() FROM Case], 'A second Case should exist');
    }

    @IsTest
    static void shouldUpdateOnlyGivenFields_WhenPatch() {
        // Given
        Case existing = existingCase();
        setRequest('PATCH', existing.Id, '{"Status": "Escalated", "Priority": "High"}');

        // When
        Test.startTest();
        Id resultId = CaseManager.updateCaseFields();
        Test.stopTest();

        // Then
        Case updated = [SELECT Subject, Status, Priority FROM Case WHERE Id = :existing.Id];
        Assert.areEqual(existing.Id, resultId, 'PATCH should return the updated Case Id');
        Assert.areEqual('Escalated', updated.Status, 'Status should be patched');
        Assert.areEqual('High', updated.Priority, 'Priority should be patched');
        Assert.areEqual('Test Case 0', updated.Subject, 'Fields not in the body must stay unchanged');
    }

    @IsTest
    static void shouldDeleteCase_WhenDelete() {
        // Given
        Case existing = existingCase();
        setRequest('DELETE', existing.Id, null);

        // When
        Test.startTest();
        CaseManager.deleteCase();
        Test.stopTest();

        // Then
        Assert.areEqual(0, [SELECT COUNT() FROM Case WHERE Id = :existing.Id], 'The Case should be deleted');
    }
}
