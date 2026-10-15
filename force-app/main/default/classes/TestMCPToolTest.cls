/**
 * Tests for the TestMCPTool demo invocable.
 */
@IsTest
private class TestMCPToolTest {
    @IsTest
    static void shouldGreetEachInputByName() {
        // Given
        List<TestMCPTool.Input> inputs = new List<TestMCPTool.Input>();
        for (String name : new List<String>{ 'Ada', 'Grace' }) {
            TestMCPTool.Input inp = new TestMCPTool.Input();
            inp.name = name;
            inputs.add(inp);
        }

        // When
        Test.startTest();
        List<TestMCPTool.Output> outputs = TestMCPTool.run(inputs);
        Test.stopTest();

        // Then
        Assert.areEqual(2, outputs.size(), 'One output per input');
        Assert.areEqual('Hello Ada', outputs[0].result, 'First greeting should use the first name');
        Assert.areEqual('Hello Grace', outputs[1].result, 'Second greeting should use the second name');
    }

    @IsTest
    static void shouldReturnNoOutputs_WhenNoInputs() {
        // When
        Test.startTest();
        List<TestMCPTool.Output> outputs = TestMCPTool.run(new List<TestMCPTool.Input>());
        Test.stopTest();

        // Then
        Assert.isTrue(outputs.isEmpty(), 'No inputs should produce no outputs');
    }
}
