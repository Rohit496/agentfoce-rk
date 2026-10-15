/**
 * An apex class that updates details of a portal user.
   Guest users are never able to access this page.
 */
@IsTest public with sharing class MyProfilePageControllerTest {

    @IsTest static void testSave() {
        // Modify the test to query for a portal user that exists in your org
        List<User> existingPortalUsers = [SELECT id, profileId, userRoleId FROM User WHERE UserRoleId <> null AND UserType='CustomerSuccess'];

        if (existingPortalUsers.isEmpty()) {
            User currentUser = [select id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country
                                FROM User WHERE id =: UserInfo.getUserId()];
            MyProfilePageController controller = new MyProfilePageController();
            Assert.areEqual(currentUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
            Assert.isFalse(controller.getIsEdit(), 'isEdit should default to false');
            controller.edit();
            Assert.isTrue(controller.getIsEdit(), 'Expected true: controller.getIsEdit()');
            controller.cancel();
            Assert.isFalse(controller.getIsEdit(), 'Expected false: controller.getIsEdit()');
            
            Assert.isTrue(Page.ChangePassword.getUrl().equals(controller.changePassword().getUrl()), 'Expected true: Page.ChangePassword.getUrl().equals(controller.changePassword().getUrl())');
            
            String randFax = Math.rint(Math.random() * 1000) + '5551234';
            controller.getUser().Fax = randFax;
            controller.save();
            Assert.isFalse(controller.getIsEdit(), 'Expected false: controller.getIsEdit()');
            
            currentUser = [Select id, fax from User where id =: currentUser.Id];
            Assert.isTrue(currentUser.fax == randFax, 'Expected true: currentUser.fax == randFax');
        } else {
            User existingPortalUser = existingPortalUsers[0];
            String randFax = Math.rint(Math.random() * 1000) + '5551234';

            System.runAs(existingPortalUser) {
                MyProfilePageController controller = new MyProfilePageController();
                Assert.areEqual(existingPortalUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
                Assert.isFalse(controller.getIsEdit(), 'isEdit should default to false');
                controller.edit();
                Assert.isTrue(controller.getIsEdit(), 'Expected true: controller.getIsEdit()');

                controller.cancel();
                Assert.isFalse(controller.getIsEdit(), 'Expected false: controller.getIsEdit()');

                controller.getUser().Fax = randFax;
                controller.save();
                Assert.isFalse(controller.getIsEdit(), 'Expected false: controller.getIsEdit()');
            }

            // verify that the user was updated
            existingPortalUser = [Select id, fax from User where id =: existingPortalUser.Id];
            Assert.isTrue(existingPortalUser.fax == randFax, 'Expected true: existingPortalUser.fax == randFax');
        }
    }
}