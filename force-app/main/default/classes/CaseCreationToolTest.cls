/**
 * Tests for the CaseCreationTool "Create Case" invocable.
 */
@IsTest
private class CaseCreationToolTest {
    private static CaseCreationTool.Input input(String subject) {
        CaseCreationTool.Input inp = new CaseCreationTool.Input();
        inp.subject = subject;
        inp.description = 'Created by the agent for ' + subject;
        inp.caseOrigin = 'Web';
        return inp;
    }

    @IsTest
    static void shouldCreateCase_WithGivenFields() {
        // When
        Test.startTest();
        List<CaseCreationTool.Output> outputs = CaseCreationTool.run(
            new List<CaseCreationTool.Input>{ input('Printer offline') }
        );
        Test.stopTest();

        // Then
        Assert.areEqual(1, outputs.size(), 'One input should produce one output');
        Case created = [SELECT Subject, Description, Origin FROM Case WHERE Id = :outputs[0].caseId];
        Assert.areEqual('Printer offline', created.Subject, 'Subject should be saved');
        Assert.areEqual('Created by the agent for Printer offline', created.Description, 'Description should be saved');
        Assert.areEqual('Web', created.Origin, 'Origin should be saved');
        Assert.areEqual('Case created with Id ' + created.Id, outputs[0].result, 'Result should report the new Case Id');
    }

    @IsTest
    static void shouldCreateOneCasePerInput_WhenBulk() {
        // Given
        List<CaseCreationTool.Input> inputs = new List<CaseCreationTool.Input>();
        for (Integer i = 0; i < 201; i++) {
            inputs.add(input('Bulk case ' + i));
        }

        // When
        Test.startTest();
        List<CaseCreationTool.Output> outputs = CaseCreationTool.run(inputs);
        Test.stopTest();

        // Then
        Assert.areEqual(201, outputs.size(), 'Every input should produce an output');
        Assert.areEqual(201, [SELECT COUNT() FROM Case WHERE Subject LIKE 'Bulk case %'], 'All 201 Cases should be inserted in one DML');
    }
}
