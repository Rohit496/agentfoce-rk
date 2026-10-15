@IsTest
 public with sharing class MicrobatchSelfRegControllerTest {
      @IsTest
     public static void testMicrobatchSelfRegController() {
         MicrobatchSelfRegController controller = new MicrobatchSelfRegController();
         controller.firstName = 'FirstName';
         controller.lastName = 'LastName';
         controller.email = 'test@force.com';
         controller.communityNickname = 'test';

         // registerUser will always return null when the page isn't accessed as a guest user
         Assert.isNull(controller.registerUser(), 'Expected null: controller.registerUser()');
     }
 }