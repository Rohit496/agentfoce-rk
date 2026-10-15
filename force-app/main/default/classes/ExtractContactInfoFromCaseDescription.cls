public with sharing class ExtractContactInfoFromCaseDescription {

    public static void updateContactInfoFromPrompt(Id caseId) {

        // Create inputs
        Map<String, String> caseRecordIdMap = new Map<String, String>();
        caseRecordIdMap.put('id', caseId);
        ConnectApi.WrappedValue caseWrappedValue = new ConnectApi.WrappedValue();
        caseWrappedValue.value = caseRecordIdMap;
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        inputParams.put('Input:Case', caseWrappedValue);

        // Configure invocation parameters
        ConnectApi.EinsteinPromptTemplateGenerationsInput promptGenerationsInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        promptGenerationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        promptGenerationsInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
        promptGenerationsInput.isPreview = false;
        promptGenerationsInput.inputParams = inputParams;

        // Call the service
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = 
        ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate('Extract_Customer_Information_from_Case_Description', promptGenerationsInput); 

        // Parse the response
        ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
        applyCustomerInfo(caseId, response.text);
    }

    /**
     * Parses the prompt template's JSON answer ({"name", "email", "phone"}) and saves it on the Case.
     * Split from the Einstein call so it can be unit tested (ConnectApi.EinsteinLLM can't run in tests).
     * @param caseId Case to update
     * @param llmText Raw text returned by the prompt template
     */
    @TestVisible
    private static void applyCustomerInfo(Id caseId, String llmText) {
        // Clean the response: Remove non-breaking spaces and other invalid characters
        String jsonResponse = llmText.replaceAll('[^\\x20-\\x7E]', '').trim();

        // Deserialize the JSON response
        Map<String, Object> customerInfo = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);

        // Extract information
        String name = (String) customerInfo.get('name');
        String email = (String) customerInfo.get('email');
        String phone = (String) customerInfo.get('phone');

        // Update the case record
        Case caseToUpdate = new Case(
            Id = caseId,
            SuppliedName = name,
            SuppliedEmail = email,
            SuppliedPhone = phone
        );
        update as user caseToUpdate;
    }
}