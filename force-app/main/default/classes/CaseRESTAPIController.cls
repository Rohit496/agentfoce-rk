@RestResource(urlMapping='/CaseApexAPI/v1/Cases/*')
global without sharing class CaseRESTAPIController {
    @HttpPost
    global static String importCase(String subject, String description) {
        System.debug('### importCase ###');
        System.debug('subject: ' + subject);
        System.debug('description: ' + description);

        Case objCase = new Case(
            Status = 'New',
            Origin = 'Web',
            Priority = 'Low',
            Subject = subject,
            Description = description
        );

        try {
            insert objCase;
            return 'Case created for you!!!';
        } catch (DMLException e) {
            return e.getMessage();
        }
    }
}