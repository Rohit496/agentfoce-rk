/**
 * Tests for the CaseInputController "Create Case from Case Information" Agentforce action.
 */
@IsTest
private class CaseInputControllerTest {
    @TestSetup
    static void setupTestData() {
        Account account = TestDataFactory.createAccount();
        insert TestDataFactory.buildContacts(account.Id, 1);
    }

    private static CaseInputController.CreateCaseRequest request(String status, String priority) {
        CaseInputController.CaseData data = new CaseInputController.CaseData();
        data.caseSubject = 'Router keeps rebooting';
        data.caseDescription = 'Happens every hour';
        data.status = status;
        data.priority = priority;
        data.caseOrigin = 'Web';
        CaseInputController.CreateCaseRequest req = new CaseInputController.CreateCaseRequest();
        req.casedata = data;
        return req;
    }

    private static List<CaseInputController.CreateCaseResponse> create(List<CaseInputController.CreateCaseRequest> requests) {
        return CaseInputController.createCase(requests);
    }

    @IsTest
    static void shouldCreateCase_WithAllProvidedFields() {
        // Given
        Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
        CaseInputController.CreateCaseRequest req = request('Working', 'High');
        req.casedata.contactId = contact.Id;
        req.casedata.accountId = contact.AccountId;
        req.casedata.type = 'Problem';
        req.casedata.caseReason = 'Performance';

        // When
        Test.startTest();
        List<CaseInputController.CreateCaseResponse> responses = create(new List<CaseInputController.CreateCaseRequest>{ req });
        Test.stopTest();

        // Then
        CaseInputController.CaseResult result = responses[0].caseresult;
        Case created = [SELECT CaseNumber, Subject, Description, Status, Priority, Origin, Type, Reason, ContactId, AccountId FROM Case WHERE Id = :result.caseId];
        Assert.areEqual('Router keeps rebooting', created.Subject, 'Subject should be saved');
        Assert.areEqual('Happens every hour', created.Description, 'Description should be saved');
        Assert.areEqual('Working', created.Status, 'Status should be saved');
        Assert.areEqual('Problem', created.Type, 'Type should be saved');
        Assert.areEqual('Performance', created.Reason, 'Reason should be saved');
        Assert.areEqual(contact.Id, created.ContactId, 'Contact should be linked');
        Assert.areEqual(contact.AccountId, created.AccountId, 'Account should be linked');
        Assert.areEqual(created.CaseNumber, result.caseNumber, 'The result should carry the CaseNumber');
        Assert.areEqual('Case ' + created.CaseNumber + ' was created successfully.', result.prompt, 'The prompt should confirm the CaseNumber');
        Assert.areEqual('Within 24 hours', result.estimatedResponse, 'High priority means a 24-hour response');
        Assert.isNotNull(result.createdDate, 'The created date should be formatted for display');
    }

    @IsTest
    static void shouldDefaultStatusAndPriority_WhenBlank() {
        // When
        Test.startTest();
        List<CaseInputController.CreateCaseResponse> responses = create(new List<CaseInputController.CreateCaseRequest>{ request('', null) });
        Test.stopTest();

        // Then
        CaseInputController.CaseResult result = responses[0].caseresult;
        Assert.areEqual('New', result.status, 'A blank status defaults to New');
        Assert.areEqual('Medium', result.priority, 'A blank priority defaults to Medium');
        Assert.areEqual('Within 48 hours', result.estimatedResponse, 'Medium priority means a 48-hour response');
    }

    @IsTest
    static void shouldEstimateSeventyTwoHours_ForLowPriority() {
        // When
        Test.startTest();
        List<CaseInputController.CreateCaseResponse> responses = create(new List<CaseInputController.CreateCaseRequest>{ request('New', 'Low') });
        Test.stopTest();

        // Then
        Assert.areEqual('Within 72 hours', responses[0].caseresult.estimatedResponse, 'Low priority means a 72-hour response');
    }

    @IsTest
    static void shouldCreateEveryCase_WhenBulk() {
        // Given
        List<CaseInputController.CreateCaseRequest> requests = new List<CaseInputController.CreateCaseRequest>();
        for (Integer i = 0; i < 201; i++) {
            requests.add(request('New', 'Medium'));
        }

        // When
        Test.startTest();
        List<CaseInputController.CreateCaseResponse> responses = create(requests);
        Test.stopTest();

        // Then
        Assert.areEqual(201, responses.size(), 'Every request should get a response');
        Assert.areEqual(201, [SELECT COUNT() FROM Case], 'All 201 Cases should be inserted in one DML');
    }
}
