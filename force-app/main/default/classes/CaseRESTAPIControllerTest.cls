/**
 * Tests for the CaseRESTAPIController REST resource (POST /CaseApexAPI/v1/Cases).
 */
@IsTest
private class CaseRESTAPIControllerTest {
    @IsTest
    static void shouldCreateNewWebCase_WhenImportCase() {
        // When
        Test.startTest();
        String result = CaseRESTAPIController.importCase('Shipping delay', 'Order 123 is late');
        Test.stopTest();

        // Then
        Assert.areEqual('Case created for you!!!', result, 'Success message should be returned');
        Case created = [SELECT Subject, Description, Status, Origin, Priority FROM Case LIMIT 1];
        Assert.areEqual('Shipping delay', created.Subject, 'Subject should be saved');
        Assert.areEqual('Order 123 is late', created.Description, 'Description should be saved');
        Assert.areEqual('New', created.Status, 'Imported cases start as New');
        Assert.areEqual('Web', created.Origin, 'Imported cases are Web origin');
        Assert.areEqual('Low', created.Priority, 'Imported cases are Low priority');
    }

    @IsTest
    static void shouldReturnErrorMessage_WhenInsertFails() {
        // Given: a subject longer than the 255-character field limit makes the DML fail
        String tooLongSubject = 'x'.repeat(300);

        // When
        Test.startTest();
        String result = CaseRESTAPIController.importCase(tooLongSubject, 'too long');
        Test.stopTest();

        // Then
        Assert.areNotEqual('Case created for you!!!', result, 'A failed insert must not report success');
        Assert.areEqual(0, [SELECT COUNT() FROM Case], 'No Case should be created');
    }
}
