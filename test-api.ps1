# PowerShell script to test the Workflow API
# Make sure the API is running on localhost:5000 before running this script

$baseUrl = "http://localhost:5000"

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

# Test 4: Get the Instance
Write-Host "👁️ Test 4: Retrieving instance details..." -ForegroundColor Cyan

try {
    $response4 = Invoke-RestMethod -Uri "$baseUrl/instances/$instanceId" -Method Get
    Write-Host "✅ Instance retrieved successfully!" -ForegroundColor Green
    Write-Host "Current State: $($response4.currentStateId)" -ForegroundColor White
    Write-Host "History Count: $($response4.history.Count)" -ForegroundColor White
} catch {
    Write-Host "❌ Error retrieving instance: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 5: Execute an Action
Write-Host "⚡ Test 5: Executing 'start-processing' action..." -ForegroundColor Cyan

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

# Test 6: Execute Another Action
Write-Host "⚡ Test 6: Executing 'complete' action..." -ForegroundColor Cyan

$executeAction2 = @{
    actionId = "complete"
} | ConvertTo-Json

try {
    $response6 = Invoke-RestMethod -Uri "$baseUrl/instances/$instanceId/execute" -Method Post -Body $executeAction2 -ContentType "application/json"
    Write-Host "✅ Action executed successfully!" -ForegroundColor Green
    Write-Host "Final State: $($response6.currentStateId)" -ForegroundColor White
    Write-Host "History Count: $($response6.history.Count)" -ForegroundColor White
} catch {
    Write-Host "❌ Error executing action: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 7: Try Invalid Action (should fail)
Write-Host "🚫 Test 7: Trying invalid action (should fail)..." -ForegroundColor Cyan

$invalidAction = @{
    actionId = "start-processing"
} | ConvertTo-Json

try {
    $response7 = Invoke-RestMethod -Uri "$baseUrl/instances/$instanceId/execute" -Method Post -Body $invalidAction -ContentType "application/json"
    Write-Host "❌ This should have failed!" -ForegroundColor Red
} catch {
    Write-Host "✅ Correctly rejected invalid action!" -ForegroundColor Green
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 API testing completed!" -ForegroundColor Green
Write-Host "Check the Swagger UI at: $baseUrl/swagger" -ForegroundColor Yellow 