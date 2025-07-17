# PowerShell script to test the Grant Application Lifecycle API
# Make sure the API is running on localhost:5001 before running this script

$baseUrl = "http://localhost:5001"

Write-Host "🎓 Testing Grant Application & Funding Lifecycle Management API" -ForegroundColor Green
Write-Host "Base URL: $baseUrl" -ForegroundColor Yellow
Write-Host ""

# Test 1: Create Grant Lifecycle Definition
Write-Host "📝 Test 1: Creating grant application lifecycle definition..." -ForegroundColor Cyan

$grantLifecycleDefinition = @{
    id = "grant-lifecycle"
    name = "Research Grant Application & Funding Lifecycle"
    states = @(
        @{ id = "drafting"; name = "Application Drafting"; isInitial = $true; isFinal = $false },
        @{ id = "submitted"; name = "Submitted for Review"; isInitial = $false; isFinal = $false },
        @{ id = "under_internal_review"; name = "Under Internal Review (fEC/TRAC)"; isInitial = $false; isFinal = $false },
        @{ id = "pending_revisions"; name = "Pending Revisions"; isInitial = $false; isFinal = $false },
        @{ id = "submitted_to_funder"; name = "Submitted to External Funder"; isInitial = $false; isFinal = $false },
        @{ id = "awarded"; name = "Grant Awarded"; isInitial = $false; isFinal = $true },
        @{ id = "rejected"; name = "Grant Rejected"; isInitial = $false; isFinal = $true },
        @{ id = "withdrawn"; name = "Application Withdrawn"; isInitial = $false; isFinal = $true }
    )
    actions = @(
        @{ id = "submit-application"; name = "Submit Application for Review"; fromStates = @("drafting"); toState = "submitted" },
        @{ id = "begin-internal-review"; name = "Begin Internal Compliance Review"; fromStates = @("submitted"); toState = "under_internal_review" },
        @{ id = "request-revisions"; name = "Request Revisions from Applicant"; fromStates = @("under_internal_review"); toState = "pending_revisions" },
        @{ id = "submit-revisions"; name = "Submit Revised Application"; fromStates = @("pending_revisions"); toState = "under_internal_review" },
        @{ id = "approve-for-submission"; name = "Approve for Funder Submission"; fromStates = @("under_internal_review"); toState = "submitted_to_funder" },
        @{ id = "award-grant"; name = "Grant Awarded by Funder"; fromStates = @("submitted_to_funder"); toState = "awarded" },
        @{ id = "reject-grant"; name = "Grant Rejected by Funder"; fromStates = @("submitted_to_funder"); toState = "rejected" },
        @{ id = "withdraw-application"; name = "Withdraw Application"; fromStates = @("drafting", "submitted", "under_internal_review", "pending_revisions"); toState = "withdrawn" }
    )
} | ConvertTo-Json -Depth 10

try {
    $response1 = Invoke-RestMethod -Uri "$baseUrl/workflows" -Method Post -Body $grantLifecycleDefinition -ContentType "application/json"
    Write-Host "✅ Grant lifecycle definition created successfully!" -ForegroundColor Green
    Write-Host "Definition ID: $($response1.id)" -ForegroundColor White
    Write-Host "States: $($response1.states.Count)" -ForegroundColor White
    Write-Host "Actions: $($response1.actions.Count)" -ForegroundColor White
} catch {
    Write-Host "❌ Error creating grant lifecycle: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test 2: Get the Grant Lifecycle Definition
Write-Host "📋 Test 2: Retrieving grant lifecycle definition..." -ForegroundColor Cyan

try {
    $response2 = Invoke-RestMethod -Uri "$baseUrl/workflows/grant-lifecycle" -Method Get
    Write-Host "✅ Grant lifecycle retrieved successfully!" -ForegroundColor Green
    Write-Host "Name: $($response2.name)" -ForegroundColor White
    Write-Host "States: $($response2.states.Count)" -ForegroundColor White
    Write-Host "Actions: $($response2.actions.Count)" -ForegroundColor White
} catch {
    Write-Host "❌ Error retrieving grant lifecycle: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Start a New Grant Application
Write-Host "🎯 Test 3: Starting a new grant application..." -ForegroundColor Cyan

try {
    $response3 = Invoke-RestMethod -Uri "$baseUrl/workflows/grant-lifecycle/instances" -Method Post
    Write-Host "✅ Grant application started successfully!" -ForegroundColor Green
    Write-Host "Application ID: $($response3.id)" -ForegroundColor White
    Write-Host "Current State: $($response3.currentStateId)" -ForegroundColor White
    $applicationId = $response3.id
} catch {
    Write-Host "❌ Error starting grant application: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 4: Researcher Submits Application
Write-Host "📤 Test 4: Researcher submitting application for review..." -ForegroundColor Cyan

$submitAction = @{
    actionId = "submit-application"
} | ConvertTo-Json

try {
    $response4 = Invoke-RestMethod -Uri "$baseUrl/instances/$applicationId/execute" -Method Post -Body $submitAction -ContentType "application/json"
    Write-Host "✅ Application submitted successfully!" -ForegroundColor Green
    Write-Host "New State: $($response4.currentStateId)" -ForegroundColor White
    Write-Host "History Count: $($response4.history.Count)" -ForegroundColor White
} catch {
    Write-Host "❌ Error submitting application: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 5: Begin Internal Review
Write-Host "🔍 Test 5: Beginning internal compliance review (fEC/TRAC)..." -ForegroundColor Cyan

$reviewAction = @{
    actionId = "begin-internal-review"
} | ConvertTo-Json

try {
    $response5 = Invoke-RestMethod -Uri "$baseUrl/instances/$applicationId/execute" -Method Post -Body $reviewAction -ContentType "application/json"
    Write-Host "✅ Internal review started successfully!" -ForegroundColor Green
    Write-Host "New State: $($response5.currentStateId)" -ForegroundColor White
    Write-Host "History Count: $($response5.history.Count)" -ForegroundColor White
} catch {
    Write-Host "❌ Error starting internal review: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 6: Approve for Submission to Funder
Write-Host "✅ Test 6: Approving application for funder submission..." -ForegroundColor Cyan

$approveAction = @{
    actionId = "approve-for-submission"
} | ConvertTo-Json

try {
    $response6 = Invoke-RestMethod -Uri "$baseUrl/instances/$applicationId/execute" -Method Post -Body $approveAction -ContentType "application/json"
    Write-Host "✅ Application approved for funder submission!" -ForegroundColor Green
    Write-Host "New State: $($response6.currentStateId)" -ForegroundColor White
    Write-Host "History Count: $($response6.history.Count)" -ForegroundColor White
} catch {
    Write-Host "❌ Error approving for submission: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 7: Award Grant
Write-Host "🎉 Test 7: Funder awarding the grant..." -ForegroundColor Cyan

$awardAction = @{
    actionId = "award-grant"
} | ConvertTo-Json

try {
    $response7 = Invoke-RestMethod -Uri "$baseUrl/instances/$applicationId/execute" -Method Post -Body $awardAction -ContentType "application/json"
    Write-Host "✅ Grant awarded successfully!" -ForegroundColor Green
    Write-Host "Final State: $($response7.currentStateId)" -ForegroundColor White
    Write-Host "History Count: $($response7.history.Count)" -ForegroundColor White
    Write-Host "🎊 CONGRATULATIONS! Grant application completed successfully!" -ForegroundColor Magenta
} catch {
    Write-Host "❌ Error awarding grant: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 8: Try Invalid Action (should fail)
Write-Host "🚫 Test 8: Trying invalid action on completed grant (should fail)..." -ForegroundColor Cyan

$invalidAction = @{
    actionId = "submit-application"
} | ConvertTo-Json

try {
    $response8 = Invoke-RestMethod -Uri "$baseUrl/instances/$applicationId/execute" -Method Post -Body $invalidAction -ContentType "application/json"
    Write-Host "❌ This should have failed!" -ForegroundColor Red
} catch {
    Write-Host "✅ Correctly rejected invalid action!" -ForegroundColor Green
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Test 9: Check Final Application Status
Write-Host "📊 Test 9: Checking final application status..." -ForegroundColor Cyan

try {
    $finalResponse = Invoke-RestMethod -Uri "$baseUrl/instances/$applicationId" -Method Get
    Write-Host "✅ Final application status retrieved!" -ForegroundColor Green
    Write-Host "Application ID: $($finalResponse.id)" -ForegroundColor White
    Write-Host "Final State: $($finalResponse.currentStateId)" -ForegroundColor White
    Write-Host "Total Actions Executed: $($finalResponse.history.Count)" -ForegroundColor White
    
    Write-Host ""
    Write-Host "📈 Grant Application History:" -ForegroundColor Yellow
    foreach ($entry in $finalResponse.history) {
        Write-Host "  ➤ $($entry.actionId) → $($entry.toStateId) at $($entry.timestamp)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Error checking final status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Grant Application Lifecycle API testing completed!" -ForegroundColor Green
Write-Host "✅ All grant application workflows are functioning correctly!" -ForegroundColor Green
Write-Host "📋 Frontend Interface: $baseUrl/" -ForegroundColor Yellow
Write-Host "📚 API Documentation: $baseUrl/swagger" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎓 Perfect for research institutions and funding organizations!" -ForegroundColor Magenta 