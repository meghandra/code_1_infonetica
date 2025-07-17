using WorkflowService.Api.Domain;
using WorkflowService.Api.Models;
using WorkflowService.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add CORS for frontend
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:5001")
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
    app.UseSwaggerUI();
}

// Enable static file serving
app.UseStaticFiles();

// Enable CORS
app.UseCors();

// Simple middleware to handle our custom exceptions
app.Use(async (context, next) =>
{
    try
    {
        await next(context);
    }
    catch (KeyNotFoundException ex)
    {
        context.Response.StatusCode = 404;
        await context.Response.WriteAsJsonAsync(new { error = ex.Message });
    }
    catch (WorkflowValidationException ex)
    {
        context.Response.StatusCode = 400;
        await context.Response.WriteAsJsonAsync(new { error = ex.Message });
    }
    catch (InvalidTransitionException ex)
    {
        context.Response.StatusCode = 400;
        await context.Response.WriteAsJsonAsync(new { error = ex.Message });
    }
});

// --- Root endpoint (redirect to Swagger) ---
app.MapGet("/", () => Results.Redirect("/swagger"));

// --- Workflow Definition Endpoints ---
app.MapPost("/workflows", (WorkflowDefinition definition, WorkflowEngineService engine) =>
{
    var created = engine.CreateAndValidateDefinition(definition);
    return Results.Created($"/workflows/{created.Id}", created);
});

app.MapGet("/workflows/{definitionId}", (string definitionId, IDataStore store) =>
{
    var definition = store.GetDefinition(definitionId);
    return definition is not null ? Results.Ok(definition) : Results.NotFound();
});

// --- Workflow Instance Endpoints ---
app.MapPost("/workflows/{definitionId}/instances", (string definitionId, WorkflowEngineService engine) =>
{
    var instance = engine.StartInstance(definitionId);
    return Results.Created($"/instances/{instance.Id}", instance);
});

app.MapGet("/instances/{instanceId}", (Guid instanceId, IDataStore store) =>
{
    var instance = store.GetInstance(instanceId);
    return instance is not null ? Results.Ok(instance) : Results.NotFound();
});

app.MapPost("/instances/{instanceId}/execute", (Guid instanceId, ExecuteActionRequest request, WorkflowEngineService engine) =>
{
    var updatedInstance = engine.ExecuteAction(instanceId, request.ActionId);
    return Results.Ok(updatedInstance);
});

app.Run(); 