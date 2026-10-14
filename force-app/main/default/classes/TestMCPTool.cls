global class TestMCPTool {
    global class Input {
        @InvocableVariable(required=true)
        global String name;
    }

    global class Output {
        @InvocableVariable
        global String result;
    }

    @InvocableMethod(label='Test Tool' description='Test MCP tool')
    global static List<Output> run(List<Input> inputs) {
        List<Output> outputs = new List<Output>();

        for (Input i : inputs) {
            Output o = new Output();
            o.result = 'Hello ' + i.name;
            System.debug(
                'TestMCPTool: Input name = ' +
                    i.name +
                    ', Output result = ' +
                    o.result
            );
            outputs.add(o);
        }

        return outputs;
    }
}