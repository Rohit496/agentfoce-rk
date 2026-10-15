@IsTest
public with sharing class LightningSelfRegisterControllerTest {

 /* Verifies that IsValidPassword method with various password combinations. */
 @IsTest
 static void testIsValidPassword() {
  Assert.isTrue(LightningSelfRegisterController.isValidPassword('password?@12334', 'password?@12334'), 'Expected true: LightningSelfRegisterController.isValidPassword(\'password?@12334\', \'password?@12334\')');
  Assert.isFalse(LightningSelfRegisterController.isValidPassword('password?@12334', 'dummyPassword'), 'Expected false: LightningSelfRegisterController.isValidPassword(\'password?@12334\', \'dummyPassword\')');
  Assert.isFalse(LightningSelfRegisterController.isValidPassword('password?@12334', null), 'Expected false: LightningSelfRegisterController.isValidPassword(\'password?@12334\', null)');
  Assert.isFalse(LightningSelfRegisterController.isValidPassword(null, 'fakePwd'), 'Expected false: LightningSelfRegisterController.isValidPassword(null, \'fakePwd\')');
 }

 @IsTest
 static void testSiteAsContainerEnabled() {
  Assert.isNotNull(LightningSelfRegisterController.siteAsContainerEnabled('https://portaleu1-developer-edition.eu11.force.com'), 'Expected a value (not null): LightningSelfRegisterController.siteAsContainerEnabled(\'https://portaleu1-developer-edi...');
 }

 /* Verifies the selfRegistration method flow with various invalid inputs */
 @IsTest
 static void testSelfRegistration() {
  Map < String, String > paramsMap = initializeParams();
  Assert.isNotNull(paramsMap, 'Expected a value (not null): paramsMap');
  Assert.areEqual(Label.Site.lastname_is_required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), '', paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true), 'Expected LightningSelfRegisterController.selfRegister(paramsMap.get(\'firstName\'), \'\', paramsMap.... to equal Label.Site.lastname_is_required');
  Assert.areEqual(Label.Site.email_is_required, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), '', paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true), 'Expected LightningSelfRegisterController.selfRegister(paramsMap.get(\'firstName\'), paramsMap.get(... to equal Label.Site.email_is_required');
  Assert.areEqual(Label.Site.email_is_required, LightningSelfRegisterController.selfRegister(null, paramsMap.get('lastName'), '', null, paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true), 'Expected LightningSelfRegisterController.selfRegister(null, paramsMap.get(\'lastName\'), \'\', null,... to equal Label.Site.email_is_required');
  Assert.areEqual(Label.site.passwords_dont_match, LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true), 'Expected LightningSelfRegisterController.selfRegister(paramsMap.get(\'firstName\'), paramsMap.get(... to equal Label.site.passwords_dont_match');
  Assert.isNotNull(LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), '', paramsMap.get('password'), paramsMap.get('confirmPasswordWrong'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false), 'Expected a value (not null): LightningSelfRegisterController.selfRegister(paramsMap.get(\'firstName\'), paramsMap.get(...');
 }


 /* Verifies the selfRegistration flow for valid inputs */
 @IsTest
 static void testSelfRegisterWithProperCredentials() {
  Map < String, String > paramsMap = initializeParams();
  Assert.isNull(LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), true), 'Expected null: LightningSelfRegisterController.selfRegister(paramsMap.get(\'firstName\'), paramsMap.get(...');
 }

 /* Verifies SelfRegistration flow with an accounId that is created within the test */
 @IsTest
 static void testSelfRegisterWithCreatedAccount() {
  // The org requires Account.Type (custom validation rule).
  Account acc = new Account(Name = 'test acc', Type = 'Customer - Direct');
  insert acc;
  List < Account > accounts = [SELECT Id FROM Account LIMIT 1];
  Assert.isFalse(accounts.isEmpty(), 'There must be at least one account in this environment!');
  String accountId = accounts[0].Id;
  Map < String, String > paramsMap = initializeParams();
  Assert.isNull(LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), accountId, paramsMap.get('regConfirmUrl'), null, paramsMap.get('startUrl'), false), 'Expected null: LightningSelfRegisterController.selfRegister(paramsMap.get(\'firstName\'), paramsMap.get(...');
 }

 @IsTest
 static void testGetNullExtraFields() {
  Assert.areEqual(new List < Map < String, Object >> (), LightningSelfRegisterController.getExtraFields(null));
 }

 @IsTest
 static void testGetNonEmptyExtraFields() {
  Assert.areEqual(new List < Map < String, Object >> (), LightningSelfRegisterController.getExtraFields('field1'));
 }

 /* Verifies validation of extraFields within the Self Registration flow */
 @IsTest
 static void testGetExtraFieldsInSelfRegistration() {
  List < Map < String, Object >> fieldlist = new List < Map < String, Object >> ();
  Map < String, String > paramsMap = initializeParams();
  Map < String, Object > fieldMap = new Map < String, Object > ();
  fieldMap.put('description', 'new field');
  fieldMap.put('fieldPath', 'dummyPath');
  fieldlist.add(fieldMap);
  String extraFields = JSON.serialize(fieldlist);
  Assert.isNotNull(LightningSelfRegisterController.selfRegister(paramsMap.get('firstName'), paramsMap.get('lastName'), paramsMap.get('email'), paramsMap.get('password'), paramsMap.get('confirmPasswordCorrect'), null, paramsMap.get('regConfirmUrl'), extraFields, paramsMap.get('startUrl'), true), 'Expected a value (not null): LightningSelfRegisterController.selfRegister(paramsMap.get(\'firstName\'), paramsMap.get(...');
 }

 @IsTest
 static void LightningSelfRegisterControllerInstantiation() {
  LightningSelfRegisterController controller = new LightningSelfRegisterController();
  Assert.isNotNull(controller, 'Expected a value (not null): controller');
 }

 /* Helper method to initialize the parameters required for SelfRegistration. */
 private static Map < String, String > initializeParams() {
  Map < String, String > paramsMap = new Map < String, String > ();
  String firstName = 'test';
  String lastName = 'User';
  String email = 'testUser@salesforce.com';
  String password = 'testuser123';
  String confirmPasswordCorrect = 'testuser123';
  String confirmPasswordWrong = 'wrongpassword';
  String accountId = 'testuser123';
  String regConfirmUrl = '/s/registration-confirm';
  String startUrl = 'http://my.company.salesforce.com';
  paramsMap.put('firstName', firstName);
  paramsMap.put('lastName', lastName);
  paramsMap.put('email', email);
  paramsMap.put('password', password);
  paramsMap.put('confirmPasswordCorrect', confirmPasswordCorrect);
  paramsMap.put('confirmPasswordWrong', confirmPasswordWrong);
  paramsMap.put('accountId', accountId);
  paramsMap.put('regConfirmUrl', regConfirmUrl);
  paramsMap.put('startUrl', startUrl);
  return paramsMap;
 }

 /* The registration-confirm redirect must stay on this site (open-redirect protection). */
 @IsTest
 static void shouldRejectAbsoluteRedirectUrl() {
  try {
   LightningSelfRegisterController.toSafeRelativeUrl('https://evil.example.com/phish');
   Assert.fail('An absolute URL must be rejected');
  } catch (IllegalArgumentException e) {
   Assert.isTrue(e.getMessage().contains('relative path'), 'Error should explain the URL must be relative');
  }
 }
 @IsTest
 static void shouldAllowRelativeRedirectUrl() {
  Assert.areEqual('/s/registration-confirm', LightningSelfRegisterController.toSafeRelativeUrl('/s/registration-confirm'), 'A same-site path is allowed');
 }
}
