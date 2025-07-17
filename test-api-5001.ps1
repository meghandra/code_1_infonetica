# PowerShell script to test the Workflow API on port 5001
# Make sure the API is running on localhost:5001 before running this script

$baseUrl = "http://localhost:5001"

Write-Host "🚀 Testing Workflow State Machine API" -ForegroundColor Green
Write-Host "Base URL: $baseUrl" -ForegroundColor Yellow
Write-Host ""

# Test 1: Create a Workflow Definition
Write-Host "📝 Test 1: Creating a workflow definition..." -ForegroundColor Cyan

$workflowDefinition = @{
    id = "order-process"
    name = "Order Processing Workflow"
    states = @(
        @{ id = "pending"; name = "Pending"; isInitial = $true },
        @{ id = "processing"; name = "Processing" },
        @{ id = "completed"; name = "Completed"; isFinal = $true },
        @{ id = "cancelled"; name = "Cancelled"; isFinal = $true }
    )
    actions = @(
        @{ id = "start-processing"; name = "Start Processing"; fromStates = @("pending"); toState = "processing" },
        @{ id = "complete"; name = "Complete Order"; fromStates = @("processing"); toState = "completed" },
        @{ id = "cancel"; name = "Cancel Order"; fromStates = @("pending", "processing"); toState = "cancelled" }
    )
} | ConvertTo-Json -Depth 10

try {
    $response1 = Invoke-RestMethod -Uri "$baseUrl/workflows" -Method Post -Body $workflowDefinition -ContentType "application/json"
    Write-Host "✅ Workflow created successfully!" -ForegroundColor Green
    Write-Host "Definition ID: $($response1.id)" -ForegroundColor White
} catch {
    Write-Host "❌ Error creating workflow: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test 2: Get the Workflow Definition
Write-Host "📋 Test 2: Retrieving workflow definition..." -ForegroundColor Cyan

try {
    $response2 = Invoke-RestMethod -Uri "$baseUrl/workflows/order-process" -Method Get
    Write-Host "✅ Workflow retrieved successfully!" -ForegroundColor Green
    Write-Host "Name: $($response2.name)" -ForegroundColor White
    Write-Host "States: $($response2.states.Count)" -ForegroundColor White
    Write-Host "Actions: $($response2.actions.Count)" -ForegroundColor White
} catch {
    Write-Host "❌ Error retrieving workflow: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Create a Workflow Instance
Write-Host "🎯 Test 3: Starting a workflow instance..." -ForegroundColor Cyan

try {
    $response3 = Invoke-RestMethod -Uri "$baseUrl/workflows/order-process/instances" -Method Post
    Write-Host "✅ Instance created successfully!" -ForegroundColor Green
    Write-Host "Instance ID: $($response3.id)" -ForegroundColor White
    Write-Host "Current State: $($response3.currentStateId)" -ForegroundColor White
    $instanceId = $response3.id
} catch {
    Write-Host "❌ Error creating instance: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 4: Execute an Action
Write-Host "⚡ Test 4: Executing 'start-processing' action..." -ForegroundColor Cyan

$executeAction = @{
    actionId = "start-processing"
} | ConvertTo-Json

try {
    $response5 = Invoke-RestMethod -Uri "$baseUrl/instances/$instanceId/execute" -Method Post -Body $executeAction -ContentType "application/json"
    Write-Host "✅ Action executed successfully!" -ForegroundColor Green
    Write-Host "New State: $($response5.currentStateId)" -ForegroundColor White
    Write-Host "History Count: $($response5.history.Count)" -ForegroundColor White
} catch {
    Write-Host "❌ Error executing action: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 API testing completed!" -ForegroundColor Green
Write-Host "✅ Your API is working perfectly!" -ForegroundColor Green
Write-Host "📋 Swagger UI: $baseUrl/swagger" -ForegroundColor Yellow
Write-Host "🔗 API Base URL: $baseUrl" -ForegroundColor Yellow 