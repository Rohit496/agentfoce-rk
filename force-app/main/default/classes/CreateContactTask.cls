/**
 * Apex class with invocable method to create a Task record for a Contact.
 * This class is designed to be called from Agentforce agent custom actions.
 */
public with sharing class CreateContactTask {
    
    /**
     * Input wrapper class for the invocable method parameters
     */
    public class TaskRequest {
        @InvocableVariable(label='Contact ID' description='The ID of the Contact record' required=true)
        public String contactId;
        
        @InvocableVariable(label='Subject' description='The subject of the task' required=true)
        public String subject;
        
        @InvocableVariable(label='Due Date' description='The due date of the task' required=true)
        public Date dueDate;
        
        @InvocableVariable(label='Priority' description='The priority of the task (High, Medium, Low, Normal)' required=true)
        public String priority;
        
        @InvocableVariable(label='Description' description='The description of the task' required=false)
        public String description;

        @InvocableVariable(label='Status' description='The status of the task (for example: Not Started, In Progress, Completed)' required=true)
        public String status;
    }
    
    /**
     * Output wrapper class for the invocable method result
     */
    public class TaskResponse {
        @InvocableVariable(label='Success' description='Indicates if the task was created successfully')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Success or error message')
        public String message;
        
        @InvocableVariable(label='Task ID' description='The ID of the created task record')
        public String taskId;
    }
    
    /**
     * Invocable method to create a Task record for a Contact
     * @param requests List of TaskRequest objects containing task details
     * @return List of TaskResponse objects with the result of the operation
     */
    @InvocableMethod(label='Create Task for Contact' description='Creates a Task record for the specified Contact with subject, date, priority, status and description' category='Task')
    public static List<TaskResponse> createTask(List<TaskRequest> requests) {
        List<TaskResponse> responses = new List<TaskResponse>();
        List<Task> tasksToInsert = new List<Task>();
        
        for (TaskRequest request : requests) {
            TaskResponse response = new TaskResponse();
            
            try {
                // Validate required fields
                if (String.isBlank(request.contactId)) {
                    response.success = false;
                    response.message = 'Contact ID is required';
                    responses.add(response);
                    continue;
                }
                
                if (String.isBlank(request.subject)) {
                    response.success = false;
                    response.message = 'Subject is required';
                    responses.add(response);
                    continue;
                }
                
                if (request.dueDate == null) {
                    response.success = false;
                    response.message = 'Due Date is required';
                    responses.add(response);
                    continue;
                }
                
                if (String.isBlank(request.priority)) {
                    response.success = false;
                    response.message = 'Priority is required';
                    responses.add(response);
                    continue;
                }

                if (String.isBlank(request.status)) {
                    response.success = false;
                    response.message = 'Status is required';
                    responses.add(response);
                    continue;
                }
                
                // Validate priority value
                Set<String> validPriorities = new Set<String>{'High', 'Medium', 'Low', 'Normal'};
                if (!validPriorities.contains(request.priority)) {
                    response.success = false;
                    response.message = 'Priority must be one of: High, Medium, Low, Normal';
                    responses.add(response);
                    continue;
                }
                
                // Create the Task record
                Task newTask = new Task();
                newTask.WhoId = request.contactId; // For Contact, use WhoId
                newTask.Subject = request.subject;
                newTask.ActivityDate = request.dueDate;
                newTask.Priority = request.priority;
                newTask.Description = request.description;
                newTask.Status = request.status;
                
                tasksToInsert.add(newTask);
                
                // Prepare success response (will be updated after insert)
                response.success = true;
                response.message = 'Task created successfully';
                responses.add(response);
                
            } catch (Exception e) {
                response.success = false;
                response.message = 'Error: ' + e.getMessage();
                responses.add(response);
            }
        }
        
        // Insert all tasks
        if (!tasksToInsert.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.insert(tasksToInsert, false);
                
                // Update responses with task IDs
                Integer responseIndex = 0;
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    
                    // Find the corresponding response (skip error responses)
                    while (responseIndex < responses.size() && !responses[responseIndex].success) {
                        responseIndex++;
                    }
                    
                    if (responseIndex < responses.size()) {
                        if (result.isSuccess()) {
                            responses[responseIndex].taskId = result.getId();
                            responses[responseIndex].message = 'Task created successfully with ID: ' + result.getId();
                        } else {
                            responses[responseIndex].success = false;
                            String errorMsg = 'Failed to create task: ';
                            for (Database.Error error : result.getErrors()) {
                                errorMsg += error.getMessage() + ' ';
                            }
                            responses[responseIndex].message = errorMsg.trim();
                        }
                        responseIndex++;
                    }
                }
            } catch (Exception e) {
                // Update all pending success responses with error
                for (TaskResponse response : responses) {
                    if (response.success && String.isBlank(response.taskId)) {
                        response.success = false;
                        response.message = 'Error inserting task: ' + e.getMessage();
                    }
                }
            }
        }
        
        return responses;
    }
}