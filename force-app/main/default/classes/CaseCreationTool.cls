global with sharing class CaseCreationTool {
    global class Input {
        @InvocableVariable(required=true)
        global String subject;

        @InvocableVariable
        global String description;

        @InvocableVariable
        global String caseOrigin;
    }

    global class Output {
        @InvocableVariable
        global String caseId;

        @InvocableVariable
        global String result;
    }

    @InvocableMethod(
        label='Create Case'
        description='Creates a Case with the given Subject, Description and Case Origin'
    )
    global static List<Output> run(List<Input> inputs) {
        List<Output> outputs = new List<Output>();

        List<Case> casesToInsert = new List<Case>();
        for (Input i : inputs) {
            Case c = new Case();
            c.Subject = i.subject;
            c.Description = i.description;
            c.Origin = i.caseOrigin;
            casesToInsert.add(c);
        }

        insert as user casesToInsert;

        for (Case c : casesToInsert) {
            Output o = new Output();
            o.caseId = c.Id;
            o.result = 'Case created with Id ' + c.Id;
            System.debug(
                'CaseCreationTool: Created Case Id = ' +
                    c.Id +
                    ', Subject = ' +
                    c.Subject
            );
            outputs.add(o);
        }

        return outputs;
    }
}