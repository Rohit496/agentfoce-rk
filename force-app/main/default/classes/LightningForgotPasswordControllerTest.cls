@IsTest
public with sharing class LightningForgotPasswordControllerTest {

 /* Verifies that ForgotPasswordController handles invalid usernames appropriately */
 @IsTest
 static void testLightningForgotPasswordControllerInvalidUserName() {
  Assert.areEqual(Label.Site.invalid_email, LightningForgotPasswordController.forgotPassword('fakeUser', '/s/check-email'), 'Expected LightningForgotPasswordController.forgotPassword(\'fakeUser\', \'/s/check-email\') to equal Label.Site.invalid_email');
  Assert.areEqual(Label.Site.invalid_email, LightningForgotPasswordController.forgotPassword(null, '/s/check-email'), 'Expected LightningForgotPasswordController.forgotPassword(null, \'/s/check-email\') to equal Label.Site.invalid_email');
  Assert.areEqual(Label.Site.invalid_email, LightningForgotPasswordController.forgotPassword('a', '/home/home.jsp'), 'Expected LightningForgotPasswordController.forgotPassword(\'a\', \'/home/home.jsp\') to equal Label.Site.invalid_email');
 }

 /* Verifies that null checkEmailRef url throws proper exception. */
 @IsTest
 static void testLightningForgotPasswordControllerWithNullCheckEmailRef() {
  Assert.areEqual('Argument 1 cannot be null', LightningForgotPasswordController.forgotPassword('a', null), 'Expected LightningForgotPasswordController.forgotPassword(\'a\', null) to equal \'Argument 1 cannot be null\'');
  Assert.areEqual('Argument 1 cannot be null', LightningForgotPasswordController.forgotPassword('a@salesforce.com', null), 'Expected LightningForgotPasswordController.forgotPassword(\'a@salesforce.com\', null) to equal \'Argument 1 cannot be null\'');
 }

 /* Verifies that LightningForgotPasswordController object is instantiated correctly. */
 @IsTest
 static void LightningForgotPasswordControllerInstantiation() {
  LightningForgotPasswordController controller = new LightningForgotPasswordController();
  Assert.isNotNull(controller, 'Expected a value (not null): controller');
 }

 /* The redirect target must stay on this site (open-redirect protection). */
 @IsTest
 static void shouldRejectAbsoluteRedirectUrl() {
  try {
   LightningForgotPasswordController.toSafeRelativeUrl('https://evil.example.com/phish');
   Assert.fail('An absolute URL must be rejected');
  } catch (IllegalArgumentException e) {
   Assert.isTrue(e.getMessage().contains('relative path'), 'Error should explain the URL must be relative');
  }
 }
 @IsTest
 static void shouldRejectProtocolRelativeRedirectUrl() {
  try {
   LightningForgotPasswordController.toSafeRelativeUrl('//evil.example.com');
   Assert.fail('A protocol-relative URL must be rejected');
  } catch (IllegalArgumentException e) {
   Assert.isTrue(e.getMessage().contains('relative path'), 'Error should explain the URL must be relative');
  }
 }
 @IsTest
 static void shouldAllowRelativeRedirectUrl() {
  Assert.areEqual('/s/check-email', LightningForgotPasswordController.toSafeRelativeUrl('/s/check-email'), 'A same-site path is allowed');
  Assert.isNull(LightningForgotPasswordController.toSafeRelativeUrl(null), 'Null is passed through unchanged');
 }
}
