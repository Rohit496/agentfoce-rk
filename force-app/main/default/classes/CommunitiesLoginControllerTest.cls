/**
 * An apex page controller that exposes the site login functionality
 */ 
@IsTest global with sharing class CommunitiesLoginControllerTest {
    @IsTest 
    global static void testCommunitiesLoginController () {
        CommunitiesLoginController controller = new CommunitiesLoginController();
        Assert.isNull(controller.forwardToAuthPage(), 'Expected null: controller.forwardToAuthPage()');       
    }    
}