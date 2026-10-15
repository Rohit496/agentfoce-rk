@isTest
private class EmployeeControllerTest {
    @TestSetup
    static void setupTestData() {
        List<Employee__c> employees = new List<Employee__c>{
            new Employee__c(
                First_Name__c = 'John',
                Last_Name__c = 'Doe',
                Email__c = 'john.doe@test.com',
                Phone__c = '1234567890',
                Gender__c = 'Male'
            ),
            new Employee__c(
                First_Name__c = 'Jane',
                Last_Name__c = 'Smith',
                Email__c = 'jane.smith@test.com',
                Phone__c = '0987654321',
                Gender__c = 'Female'
            )
        };
        insert employees;
    }

    @isTest
    static void testGetEmployees_WithName_MatchesFirstName() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = 'John';

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        Assert.areEqual(1, responses.size(), 'Should return one response wrapper');
        Assert.areEqual(1, responses[0].employeeOptions.size(), 'Should find one employee matching first name');
        Assert.areEqual('John', responses[0].employeeOptions[0].firstName, 'Expected responses[0].employeeOptions[0].firstName to equal \'John\'');
    }

    @isTest
    static void testGetEmployees_WithName_MatchesLastName() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = 'Smith';

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(1, responses[0].employeeOptions.size(), 'Should find one employee matching last name');
        Assert.areEqual('Jane', responses[0].employeeOptions[0].firstName, 'Expected responses[0].employeeOptions[0].firstName to equal \'Jane\'');
    }

    @isTest
    static void testGetEmployees_WithName_NoMatch() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = 'NonExistent';

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(0, responses[0].employeeOptions.size(), 'Should return no employees for unmatched name');
    }

    @isTest
    static void testGetEmployees_WithBlankName_ReturnsAll() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = '';

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(2, responses[0].employeeOptions.size(), 'Should return all employees when name is blank');
    }

    @isTest
    static void testGetEmployees_WithNullName_ReturnsAll() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = null;

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(2, responses[0].employeeOptions.size(), 'Should return all employees when name is null');
    }

    @isTest
    static void testGetEmployees_WithNullRequest_ReturnsAll() {
        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            null
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1');
        Assert.areEqual(2, responses[0].employeeOptions.size(), 'Should return all employees when request is null');
    }

    @isTest
    static void testGetEmployees_WithEmptyRequestList_ReturnsAll() {
        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>()
        );

        Assert.areEqual(1, responses.size(), 'Expected responses.size() to equal 1'); 
        Assert.areEqual(2, responses[0].employeeOptions.size(), 'Should return all employees when request list is empty');
    }

    @isTest
    static void testEmployeeFieldMapping() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = 'John';

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        EmployeeController.Employee emp = responses[0].employeeOptions[0];
        Assert.isNotNull(emp.id, 'Id should be populated');
        Assert.areEqual('John', emp.firstName, 'Expected emp.firstName to equal \'John\'');
        Assert.areEqual('Doe', emp.lastName, 'Expected emp.lastName to equal \'Doe\'');
        Assert.areEqual('john.doe@test.com', emp.email, 'Expected emp.email to equal \'john.doe@test.com\'');
        Assert.areEqual('1234567890', emp.phone, 'Expected emp.phone to equal \'1234567890\'');
        Assert.areEqual('Male', emp.gender, 'Expected emp.gender to equal \'Male\'');
    }
}