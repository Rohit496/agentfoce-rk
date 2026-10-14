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
        String jsonResponse = response.text;

        // Clean the response: Remove non-breaking spaces and other invalid characters
        jsonResponse = jsonResponse.replaceAll('[^\\x20-\\x7E]', '').trim();

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
        update caseToUpdate;
    }
}