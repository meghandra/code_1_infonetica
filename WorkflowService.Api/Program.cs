using WorkflowService.Api.Domain;
using WorkflowService.Api.Models;
using WorkflowService.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { 
        Title = "Grant Application & Funding Lifecycle Management API", 
        Version = "v1",
        Description = "A .NET 8 state machine service for managing research grant applications and funding workflows with real-time state transitions, compliance tracking, and comprehensive validation."
    });
});

// Add CORS for frontend (same port scenario)
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Register our custom services
builder.Services.AddSingleton<IDataStore, InMemoryDataStore>();
builder.Services.AddScoped<WorkflowEngineService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Grant Lifecycle Management API v1");
        c.RoutePrefix = "swagger";
        c.DocumentTitle = "Grant Application & Funding Lifecycle Management API";
    });
}

// Enable static file serving (for frontend)
app.UseStaticFiles();

// Enable CORS
app.UseCors();

// Enhanced middleware to handle our custom exceptions with better formatting
app.Use(async (context, next) =>
{
    try
    {
        await next(context);
    }
    catch (KeyNotFoundException ex)
    {
        context.Response.StatusCode = 404;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { error = ex.Message });
    }
    catch (WorkflowValidationException ex)
    {
        context.Response.StatusCode = 400;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { error = ex.Message });
    }
    catch (InvalidTransitionException ex)
    {
        context.Response.StatusCode = 400;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { error = ex.Message });
    }
    catch (Exception ex)
    {
        context.Response.StatusCode = 500;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { error = "An unexpected error occurred.", details = ex.Message });
    }
});

// --- Root endpoint (serve frontend interface) ---
app.MapGet("/", () => Results.Redirect("/index.html"))
    .WithTags("Frontend")
    .WithSummary("Redirect to interactive frontend interface");

// --- Workflow Definition Endpoints ---
app.MapPost("/workflows", (WorkflowDefinition definition, WorkflowEngineService engine) =>
{
    var created = engine.CreateAndValidateDefinition(definition);
    return Results.Created($"/workflows/{created.Id}", created);
})
.WithTags("Workflow Definitions")
.WithSummary("Create a new workflow definition")
.WithDescription("Creates a new workflow definition with states and actions. Used to define grant application lifecycle processes.");

app.MapGet("/workflows/{definitionId}", (string definitionId, IDataStore store) =>
{
    var definition = store.GetDefinition(definitionId);
    return definition is not null ? Results.Ok(definition) : Results.NotFound(new { error = "Workflow definition not found." });
})
.WithTags("Workflow Definitions")
.WithSummary("Retrieve a workflow definition by ID")
.WithDescription("Gets the complete workflow definition including all states and actions for the specified workflow ID.");

// --- Workflow Instance Endpoints ---
app.MapPost("/workflows/{definitionId}/instances", (string definitionId, WorkflowEngineService engine) =>
{
    var instance = engine.StartInstance(definitionId);
    return Results.Created($"/instances/{instance.Id}", instance);
})
.WithTags("Workflow Instances")
.WithSummary("Start a new workflow instance")
.WithDescription("Creates a new workflow instance (grant application) and initializes it in the initial state.");

app.MapGet("/instances/{instanceId}", (Guid instanceId, IDataStore store) =>
{
    var instance = store.GetInstance(instanceId);
    return instance is not null ? Results.Ok(instance) : Results.NotFound(new { error = "Workflow instance not found." });
})
.WithTags("Workflow Instances")
.WithSummary("Get workflow instance details and history")
.WithDescription("Retrieves the current state and complete history of a workflow instance (grant application).");

app.MapPost("/instances/{instanceId}/execute", (Guid instanceId, ExecuteActionRequest request, WorkflowEngineService engine) =>
{
    var updatedInstance = engine.ExecuteAction(instanceId, request.ActionId);
    return Results.Ok(updatedInstance);
})
.WithTags("Workflow Instances")
.WithSummary("Execute an action on a workflow instance")
.WithDescription("Transitions a workflow instance (grant application) to a new state by executing the specified action.");

app.Run(); 