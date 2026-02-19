// get all students
Map<String, Student__c> students = Student__c.getAll();
System.debug('Students: ' + students);

// iterate through the students and print their names
List<Student__c> studentsList = students.values();
for (Student__c student : studentsList) {
    System.debug('Student Name: ' + student);
}

// use getInstance to get a specific student
Student__c specificStudent = Student__c.getInstance('Rohit');
System.debug('Specific Student: ' + specificStudent.City__c);
System.debug('Specific Student: ' + specificStudent.Area_Of_Study__c);

// another  way
String specificStudent1 = Student__c.getInstance('Rohit').City__c;
System.debug('Specific Student City: ' + specificStudent1);

String countryPhoneCode = Country_Phone_Codes__c.getInstance('India')
    .Phone_Code__c;
System.debug('Country Phone Code: ' + countryPhoneCode);

// Custom Heirarchy settings for Oragnization
Amazon_Sales__c amazonSales = Amazon_Sales__c.getValues(
    UserInfo.getOrganizationId()
);
System.debug('Amazon Oragnization: ' + amazonSales);

// custom heirarchy settings for User
Amazon_Sales__c amazonSalesProfile = Amazon_Sales__c.getValues(
    UserInfo.getUserId()
);
System.debug('Amazon Sales User: ' + amazonSalesProfile);

// custom heirarchy settings for Profile
Amazon_Sales__c amazonSalesProfile1 = Amazon_Sales__c.getValues(
    '00egL000007dWUR'
);
System.debug('Amazon Sales Profile: ' + amazonSalesProfile1);

/////////////////////////////
// custom metadata types
/////////////////////////////

List<Country_Codes__mdt> countryCodes = [
    SELECT DeveloperName, Phone_Code__c
    FROM Country_Codes__mdt
];
for (Country_Codes__mdt countryCode : countryCodes) {
    System.debug(
        'Country Code: ' +
            countryCode.DeveloperName +
            ' - ' +
            countryCode.Phone_Code__c
    );
}

List<Country_Codes__mdt> countryCodes1 = Country_Codes__mdt.getAll().values();
for (Country_Codes__mdt countryCode : countryCodes1) {
    System.debug(
        'Country Code: ' +
            countryCode.DeveloperName +
            ' - ' +
            countryCode.Phone_Code__c
    );
}

// single record retrieval using getInstance
Country_Codes__mdt specificCountryCode = Country_Codes__mdt.getInstance(
    'India'
);
System.debug(
    'Specific Country Code: ' +
        specificCountryCode.DeveloperName +
        ' - ' +
        specificCountryCode.Phone_Code__c
);

String specificCountryCode = Country_Codes__mdt.getInstance('India')
    .Phone_Code__c;
System.debug('Specific Country Code: ' + specificCountryCode);
