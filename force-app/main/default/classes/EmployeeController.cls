public without sharing class EmployeeController {
    @InvocableMethod(
        label='Retrieve Employees'
        description='Retrieves Employee records by name. If employeeName is provided, filters by first or last name. Otherwise returns all employees.'
    )
    public static List<EmployeeResponse> getEmployees(
        List<EmployeeRequest> requests
    ) {
        List<EmployeeResponse> responses = new List<EmployeeResponse>();
        String employeeName = (requests != null && !requests.isEmpty())
            ? requests[0].employeeName
            : null;

        List<Employee__c> employees;
        if (String.isNotBlank(employeeName)) {
            String searchName = '%' + employeeName + '%';
            employees = [
                SELECT
                    Id,
                    Email__c,
                    First_Name__c,
                    Last_Name__c,
                    Gender__c,
                    Phone__c
                FROM Employee__c
                WHERE
                    First_Name__c LIKE :searchName
                    OR Last_Name__c LIKE :searchName
            ];
        } else {
            employees = [
                SELECT
                    Id,
                    Email__c,
                    First_Name__c,
                    Last_Name__c,
                    Gender__c,
                    Phone__c
                FROM Employee__c
            ];
        }

        EmployeeResponse response = new EmployeeResponse();
        response.employeeOptions = new List<Employee>();

        for (Employee__c emp : employees) {
            response.employeeOptions.add(
                new Employee(
                    emp.Id,
                    emp.Email__c,
                    emp.First_Name__c,
                    emp.Last_Name__c,
                    emp.Gender__c,
                    emp.Phone__c
                )
            );
        }

        responses.add(response);
        return responses;
    }

    public class EmployeeRequest {
        @InvocableVariable(
            required=false
            description='Optional. The name of the employee to search for. Leave empty to retrieve all employees.'
        )
        public String employeeName;
    }

    public class EmployeeResponse {
        @InvocableVariable
        public List<Employee> employeeOptions;
    }

    public class Employee {
        @InvocableVariable(label='Id' description='Employee record Id')
        public String id;
        @InvocableVariable(label='First Name' description='Employee first name')
        public String firstName;
        @InvocableVariable(label='Last Name' description='Employee last name')
        public String lastName;
        @InvocableVariable(label='Email' description='Employee email address')
        public String email;
        @InvocableVariable(label='Phone' description='Employee phone number')
        public String phone;
        @InvocableVariable(label='Gender' description='Employee gender')
        public String gender;

        public Employee(
            String id,
            String email,
            String firstName,
            String lastName,
            String gender,
            String phone
        ) {
            this.id = id;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.phone = phone;
            this.gender = gender;
        }
    }
}
