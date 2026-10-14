public class AccountTool {
    public class Input {
        @InvocableVariable(required=true)
        public String accountName;
    }

    public class Output {
        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Create Account' description='Creates an account')
    public static List<Output> createAccount(List<Input> inputs) {
        List<Account> accounts = new List<Account>();
        for (Input inp : inputs) {
            accounts.add(new Account(Name = inp.accountName));
        }

        List<Output> results = new List<Output>();
        try {
            insert accounts;
            for (Account acc : accounts) {
                Output out = new Output();
                out.message = 'Created: ' + acc.Name;
                results.add(out);
            }
        } catch (DmlException e) {
            Output out = new Output();
            out.message = 'Error creating account: ' + e.getDmlMessage(0);
            results.add(out);
        }

        return results;
    }
}