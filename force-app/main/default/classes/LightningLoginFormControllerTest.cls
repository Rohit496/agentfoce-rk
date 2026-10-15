@IsTest
public with sharing class LightningLoginFormControllerTest {

 @IsTest
 static void LightningLoginFormControllerInstantiation() {
  LightningLoginFormController controller = new LightningLoginFormController();
  Assert.isNotNull(controller, 'Expected a value (not null): controller');
 }

 @IsTest
 static void testIsUsernamePasswordEnabled() {
  Assert.isTrue(LightningLoginFormController.getIsUsernamePasswordEnabled(), 'Expected true: LightningLoginFormController.getIsUsernamePasswordEnabled()');
 }

 @IsTest
 static void testIsSelfRegistrationEnabled() {
  Assert.isFalse(LightningLoginFormController.getIsSelfRegistrationEnabled(), 'Expected false: LightningLoginFormController.getIsSelfRegistrationEnabled()');
 }

 @IsTest
 static void testGetSelfRegistrationURL() {
  Assert.isNull(LightningLoginFormController.getSelfRegistrationUrl(), 'Expected null: LightningLoginFormController.getSelfRegistrationUrl()');
 }

 @IsTest
 static void testAuthConfig() {
  Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
  Assert.isNotNull(authConfig, 'Expected a value (not null): authConfig');
 }
}