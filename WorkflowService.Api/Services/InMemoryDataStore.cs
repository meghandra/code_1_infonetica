using System.Collections.Concurrent;
using WorkflowService.Api.Domain;

namespace WorkflowService.Api.Services;

public interface IDataStore
{
    // Definition methods
    void AddDefinition(WorkflowDefinition definition);
    WorkflowDefinition? GetDefinition(string definitionId);

    // Instance methods
    void AddInstance(WorkflowInstance instance);
    WorkflowInstance? GetInstance(Guid instanceId);
}

public class InMemoryDataStore : IDataStore
{
    private readonly ConcurrentDictionary<string, WorkflowDefinition> _definitions = new();
    private readonly ConcurrentDictionary<Guid, WorkflowInstance> _instances = new();

    public void AddDefinition(WorkflowDefinition definition) => _definitions[definition.Id] = definition;
    public WorkflowDefinition? GetDefinition(string definitionId) => _definitions.GetValueOrDefault(definitionId);

    public void AddInstance(WorkflowInstance instance) => _instances[instance.Id] = instance;
    public WorkflowInstance? GetInstance(Guid instanceId) => _instances.GetValueOrDefault(instanceId);
} 