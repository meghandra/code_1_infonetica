namespace WorkflowService.Api.Domain;

// A specific state a workflow can be in.
public record State(string Id, string Name, bool IsInitial = false, bool IsFinal = false);

// A transition that can move a workflow from a set of states to a single target state.
public record Action(string Id, string Name, List<string> FromStates, string ToState);

// The blueprint for a workflow, containing all possible states and actions.
public record WorkflowDefinition(string Id, string Name, List<State> States, List<Action> Actions);

// A running instance of a workflow definition.
public record WorkflowInstance
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public string DefinitionId { get; init; } = string.Empty;
    public string CurrentStateId { get; set; } = string.Empty; // Mutable property
    public List<HistoryEntry> History { get; init; } = new();
}

// A record of an action that was executed.
public record HistoryEntry(string ActionId, string ToStateId, DateTime Timestamp); 