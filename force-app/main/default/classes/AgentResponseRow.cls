/**
 * One parsed line of an Agentforce reply, shaped for the standard Flow
 * Data Table component.
 *
 * Top-level (not an inner class) and every field is @AuraEnabled, both of
 * which the Apex-defined data type requires to be usable as a Flow collection.
 */
public class AgentResponseRow {
    // Plain public fields, not properties - Flow's Apex-defined type
    // introspection only recognises annotated member variables.
    @AuraEnabled
    public Integer position;

    @AuraEnabled
    public String name;

    @AuraEnabled
    public String detail;

    public AgentResponseRow() {
    }

    public AgentResponseRow(Integer position, String name, String detail) {
        this.position = position;
        this.name = name;
        this.detail = detail;
    }
}