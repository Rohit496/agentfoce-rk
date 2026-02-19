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

        System.assertEquals(
            1,
            responses.size(),
            'Should return one response wrapper'
        );
        System.assertEquals(
            1,
            responses[0].employeeOptions.size(),
            'Should find one employee matching first name'
        );
        System.assertEquals('John', responses[0].employeeOptions[0].firstName);
    }

    @isTest
    static void testGetEmployees_WithName_MatchesLastName() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = 'Smith';

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            1,
            responses[0].employeeOptions.size(),
            'Should find one employee matching last name'
        );
        System.assertEquals('Jane', responses[0].employeeOptions[0].firstName);
    }

    @isTest
    static void testGetEmployees_WithName_NoMatch() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = 'NonExistent';

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            0,
            responses[0].employeeOptions.size(),
            'Should return no employees for unmatched name'
        );
    }

    @isTest
    static void testGetEmployees_WithBlankName_ReturnsAll() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = '';

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            2,
            responses[0].employeeOptions.size(),
            'Should return all employees when name is blank'
        );
    }

    @isTest
    static void testGetEmployees_WithNullName_ReturnsAll() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = null;

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            2,
            responses[0].employeeOptions.size(),
            'Should return all employees when name is null'
        );
    }

    @isTest
    static void testGetEmployees_WithNullRequest_ReturnsAll() {
        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            null
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            2,
            responses[0].employeeOptions.size(),
            'Should return all employees when request is null'
        );
    }

    @isTest
    static void testGetEmployees_WithEmptyRequestList_ReturnsAll() {
        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>()
        );

        System.assertEquals(1, responses.size());
        System.assertEquals(
            2,
            responses[0].employeeOptions.size(),
            'Should return all employees when request list is empty'
        );
    }

    @isTest
    static void testEmployeeFieldMapping() {
        EmployeeController.EmployeeRequest request = new EmployeeController.EmployeeRequest();
        request.employeeName = 'John';

        List<EmployeeController.EmployeeResponse> responses = EmployeeController.getEmployees(
            new List<EmployeeController.EmployeeRequest>{ request }
        );

        EmployeeController.Employee emp = responses[0].employeeOptions[0];
        System.assertNotEquals(null, emp.id, 'Id should be populated');
        System.assertEquals('John', emp.firstName);
        System.assertEquals('Doe', emp.lastName);
        System.assertEquals('john.doe@test.com', emp.email);
        System.assertEquals('1234567890', emp.phone);
        System.assertEquals('Male', emp.gender);
    }
}
