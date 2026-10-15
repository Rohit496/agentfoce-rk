/**
 * Tests for the McpCreateCase REST resource used by the MCP server.
 */
@IsTest
private class McpCreateCaseTest {
    @IsTest
    static void shouldCreateWebCase_AndReturnCaseNumber() {
        // When
        Test.startTest();
        McpCreateCase.ResponseWrapper response = McpCreateCase.execute('Login issue', 'Cannot sign in', 'High');
        Test.stopTest();

        // Then
        Case created = [SELECT CaseNumber, Subject, Description, Priority, Origin FROM Case LIMIT 1];
        Assert.areEqual(created.CaseNumber, response.recordNumber, 'The response should return the new CaseNumber');
        Assert.areEqual('Success: Case created', response.message, 'The response should confirm success');
        Assert.areEqual('Login issue', created.Subject, 'Subject should be saved');
        Assert.areEqual('Cannot sign in', created.Description, 'Description should be saved');
        Assert.areEqual('High', created.Priority, 'Priority should be saved');
        Assert.areEqual('Web', created.Origin, 'MCP cases should always be Web origin');
    }
}
