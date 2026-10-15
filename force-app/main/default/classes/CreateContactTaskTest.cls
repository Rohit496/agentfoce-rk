/**
 * Tests for the CreateContactTask "Create Task for Contact" invocable: validation, partial success, result mapping.
 */
@IsTest
private class CreateContactTaskTest {
    private static final Date DUE_DATE = Date.today().addDays(7);

    @TestSetup
    static void setupTestData() {
        Account account = TestDataFactory.createAccount();
        insert TestDataFactory.buildContacts(account.Id, 1);
    }

    private static CreateContactTask.TaskRequest validRequest() {
        CreateContactTask.TaskRequest req = new CreateContactTask.TaskRequest();
        req.contactId = [SELECT Id FROM Contact LIMIT 1].Id;
        req.subject = 'Follow up on renewal';
        req.dueDate = DUE_DATE;
        req.priority = 'High';
        req.status = 'Not Started';
        req.description = 'Call about the renewal quote';
        return req;
    }

    private static CreateContactTask.TaskResponse runOne(CreateContactTask.TaskRequest req) {
        return CreateContactTask.createTask(new List<CreateContactTask.TaskRequest>{ req })[0];
    }

    @IsTest
    static void shouldCreateTask_WhenRequestValid() {
        // Given
        CreateContactTask.TaskRequest req = validRequest();

        // When
        Test.startTest();
        CreateContactTask.TaskResponse response = runOne(req);
        Test.stopTest();

        // Then
        Assert.isTrue(response.success, 'A valid request should succeed');
        Task created = [SELECT WhoId, Subject, ActivityDate, Priority, Status, Description FROM Task WHERE Id = :response.taskId];
        Assert.areEqual(req.contactId, created.WhoId, 'The Task should be linked to the Contact');
        Assert.areEqual('Follow up on renewal', created.Subject, 'Subject should be saved');
        Assert.areEqual(DUE_DATE, created.ActivityDate, 'Due date should be saved');
        Assert.areEqual('High', created.Priority, 'Priority should be saved');
        Assert.areEqual('Not Started', created.Status, 'Status should be saved');
        Assert.areEqual('Task created successfully with ID: ' + created.Id, response.message, 'The message should include the Task Id');
    }

    @IsTest
    static void shouldRejectRequest_WhenContactIdMissing() {
        CreateContactTask.TaskRequest req = validRequest();
        req.contactId = '';
        CreateContactTask.TaskResponse response = runOne(req);
        Assert.isFalse(response.success, 'A missing Contact Id should fail');
        Assert.areEqual('Contact ID is required', response.message, 'The message should name the missing field');
    }

    @IsTest
    static void shouldRejectRequest_WhenSubjectMissing() {
        CreateContactTask.TaskRequest req = validRequest();
        req.subject = null;
        CreateContactTask.TaskResponse response = runOne(req);
        Assert.isFalse(response.success, 'A missing subject should fail');
        Assert.areEqual('Subject is required', response.message, 'The message should name the missing field');
    }

    @IsTest
    static void shouldRejectRequest_WhenDueDateMissing() {
        CreateContactTask.TaskRequest req = validRequest();
        req.dueDate = null;
        CreateContactTask.TaskResponse response = runOne(req);
        Assert.isFalse(response.success, 'A missing due date should fail');
        Assert.areEqual('Due Date is required', response.message, 'The message should name the missing field');
    }

    @IsTest
    static void shouldRejectRequest_WhenPriorityMissing() {
        CreateContactTask.TaskRequest req = validRequest();
        req.priority = ' ';
        CreateContactTask.TaskResponse response = runOne(req);
        Assert.isFalse(response.success, 'A blank priority should fail');
        Assert.areEqual('Priority is required', response.message, 'The message should name the missing field');
    }

    @IsTest
    static void shouldRejectRequest_WhenStatusMissing() {
        CreateContactTask.TaskRequest req = validRequest();
        req.status = null;
        CreateContactTask.TaskResponse response = runOne(req);
        Assert.isFalse(response.success, 'A missing status should fail');
        Assert.areEqual('Status is required', response.message, 'The message should name the missing field');
    }

    @IsTest
    static void shouldRejectRequest_WhenPriorityNotAllowed() {
        CreateContactTask.TaskRequest req = validRequest();
        req.priority = 'Urgent';
        CreateContactTask.TaskResponse response = runOne(req);
        Assert.isFalse(response.success, 'An unknown priority should fail');
        Assert.areEqual('Priority must be one of: High, Medium, Low, Normal', response.message, 'The allowed values should be listed');
        Assert.areEqual(0, [SELECT COUNT() FROM Task], 'No Task should be created for an invalid request');
    }

    @IsTest
    static void shouldReportInsertFailure_WhenContactDoesNotExist() {
        // Given: a well-formed Id that matches no Contact, so the insert fails
        CreateContactTask.TaskRequest req = validRequest();
        req.contactId = TestDataFactory.generateFakeId(Contact.SObjectType);

        // When
        Test.startTest();
        CreateContactTask.TaskResponse response = runOne(req);
        Test.stopTest();

        // Then
        Assert.isFalse(response.success, 'A Task for a missing Contact should fail');
        Assert.isTrue(response.message.startsWith('Failed to create task: '), 'The database error should be reported');
        Assert.isNull(response.taskId, 'No Task Id should be returned');
    }

    @IsTest
    static void shouldMapEachResultToItsRequest_WhenMixedValidAndInvalid() {
        // Given: invalid, valid, invalid, valid
        CreateContactTask.TaskRequest invalidFirst = validRequest();
        invalidFirst.subject = '';
        CreateContactTask.TaskRequest validSecond = validRequest();
        validSecond.subject = 'Second';
        CreateContactTask.TaskRequest invalidThird = validRequest();
        invalidThird.priority = 'Urgent';
        CreateContactTask.TaskRequest validFourth = validRequest();
        validFourth.subject = 'Fourth';

        // When
        Test.startTest();
        List<CreateContactTask.TaskResponse> responses = CreateContactTask.createTask(
            new List<CreateContactTask.TaskRequest>{ invalidFirst, validSecond, invalidThird, validFourth }
        );
        Test.stopTest();

        // Then
        Assert.areEqual(4, responses.size(), 'One response per request, in order');
        Assert.isFalse(responses[0].success, 'Request 1 is invalid');
        Assert.isTrue(responses[1].success, 'Request 2 is valid');
        Assert.isFalse(responses[2].success, 'Request 3 is invalid');
        Assert.isTrue(responses[3].success, 'Request 4 is valid');
        Assert.areEqual('Second', [SELECT Subject FROM Task WHERE Id = :responses[1].taskId].Subject, 'Response 2 must point to the Task from request 2');
        Assert.areEqual('Fourth', [SELECT Subject FROM Task WHERE Id = :responses[3].taskId].Subject, 'Response 4 must point to the Task from request 4');
    }
}
