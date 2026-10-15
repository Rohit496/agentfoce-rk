global class LightningForgotPasswordController {

    public LightningForgotPasswordController() {

    }

    @AuraEnabled
    public static String forgotPassword(String username, String checkEmailUrl) {
        try {
            Site.forgotPassword(username);
            ApexPages.PageReference checkEmailRef = new PageReference(toSafeRelativeUrl(checkEmailUrl));
            if(!Site.isValidUsername(username)) {
                return Label.Site.invalid_email;
            }
            aura.redirect(checkEmailRef);
            return null;
        }
        catch (Exception ex) {
            return ex.getMessage();
        }
    }

    @AuraEnabled
    global static String setExperienceId(String expId) {    
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);               
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }        
    }

    /**
     * Returns the URL only if it is a relative path on this site, so redirects can't be used to send
     * users to another domain (open redirect). Null is passed through so PageReference keeps its own
     * "Argument 1 cannot be null" error.
     * @param url Caller-supplied redirect target
     * @return The same URL when it is safe
     * @throws IllegalArgumentException when the URL is absolute or protocol-relative
     */
    @TestVisible
    private static String toSafeRelativeUrl(String url) {
        if (url == null) {
            return null;
        }
        Boolean isRelative = url.startsWith('/') && !url.startsWith('//') && !url.contains('\\');
        if (!isRelative) {
            throw new IllegalArgumentException('Redirect URL must be a relative path on this site.');
        }
        return url;
    }
}
