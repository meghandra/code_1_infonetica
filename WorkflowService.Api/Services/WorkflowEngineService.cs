using WorkflowService.Api.Domain;

namespace WorkflowService.Api.Services;

// Define custom exceptions for clear error handling
public class WorkflowValidationException(string message) : Exception(message);
public class InvalidTransitionException(string message) : Exception(message);

public class WorkflowEngineService(IDataStore dataStore)
{
    // Validates and saves a new workflow definition.
    public WorkflowDefinition CreateAndValidateDefinition(WorkflowDefinition definition)
    {
        // Null checks
        if (definition == null)
            throw new WorkflowValidationException("Workflow definition cannot be null.");
        
        if (definition.States == null || !definition.States.Any())
            throw new WorkflowValidationException("Workflow definition must have at least one state.");
        
        if (definition.Actions == null)
            throw new WorkflowValidationException("Workflow definition must have an actions list (can be empty).");

        // Rule: Must have exactly one initial state.
        if (definition.States.Count(s => s.IsInitial) != 1)
        {
            throw new WorkflowValidationException("Definition must have exactly one initial state.");
        }
        // Rule: Action 'from' and 'to' states must exist in the definition.
        foreach (var action in definition.Actions)
        {
            if (!definition.States.Exists(s => s.Id == action.ToState))
                throw new WorkflowValidationException($"Action '{action.Id}' points to a non-existent ToState '{action.ToState}'.");
            foreach (var fromStateId in action.FromStates)
            {
                if (!definition.States.Exists(s => s.Id == fromStateId))
                    throw new WorkflowValidationException($"Action '{action.Id}' contains a non-existent FromState '{fromStateId}'.");
            }
        }
        dataStore.AddDefinition(definition);
        return definition;
    }

    // Starts a new workflow instance.
    public WorkflowInstance StartInstance(string definitionId)
    {
        var definition = dataStore.GetDefinition(definitionId) ?? throw new KeyNotFoundException("Workflow definition not found.");
        var initialState = definition.States.Single(s => s.IsInitial);

        var instance = new WorkflowInstance
        {
            DefinitionId = definitionId,
            CurrentStateId = initialState.Id,
        };
        dataStore.AddInstance(instance);
        return instance;
    }

    // Executes an action on a workflow instance.
    public WorkflowInstance ExecuteAction(Guid instanceId, string actionId)
    {
        var instance = dataStore.GetInstance(instanceId) ?? throw new KeyNotFoundException("Workflow instance not found.");
        var definition = dataStore.GetDefinition(instance.DefinitionId) ?? throw new InvalidOperationException("Instance has an invalid definition reference.");
        var currentState = definition.States.Single(s => s.Id == instance.CurrentStateId);
        var actionToExecute = definition.Actions.FirstOrDefault(a => a.Id == actionId) ?? throw new InvalidTransitionException("Action not found in workflow definition.");

        // Validation checks
        if (currentState.IsFinal) throw new InvalidTransitionException("Cannot execute action on an instance in a final state.");
        if (!actionToExecute.FromStates.Contains(instance.CurrentStateId)) throw new InvalidTransitionException($"Action '{actionId}' cannot be executed from state '{instance.CurrentStateId}'.");

        // Transition the state
        instance.CurrentStateId = actionToExecute.ToState;
        instance.History.Add(new HistoryEntry(actionId, actionToExecute.ToState, DateTime.UtcNow));

        return instance;
    }
} 