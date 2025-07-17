# Quick test of the Grant Application & Funding Lifecycle Management API
$baseUrl = "http://localhost:5001"

Write-Host "Testing Grant Application Lifecycle API..." -ForegroundColor Green

# Test 1: Create Grant Lifecycle Workflow
$grantWorkflow = @{
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
    Write-Host "1. Creating grant lifecycle workflow..." -ForegroundColor Cyan
    $workflow = Invoke-RestMethod -Uri "$baseUrl/workflows" -Method Post -Body $grantWorkflow -ContentType "application/json"
    Write-Host "✅ Grant lifecycle created: $($workflow.id)" -ForegroundColor Green
    
    Write-Host "2. Starting grant application..." -ForegroundColor Cyan
    $instance = Invoke-RestMethod -Uri "$baseUrl/workflows/grant-lifecycle/instances" -Method Post
    Write-Host "✅ Grant application started: $($instance.id)" -ForegroundColor Green
    Write-Host "   Current state: $($instance.currentStateId)" -ForegroundColor White
    
    Write-Host "3. Submitting application for review..." -ForegroundColor Cyan
    $submitAction = @{ actionId = "submit-application" } | ConvertTo-Json
    $submitted = Invoke-RestMethod -Uri "$baseUrl/instances/$($instance.id)/execute" -Method Post -Body $submitAction -ContentType "application/json"
    Write-Host "✅ Application submitted: $($submitted.currentStateId)" -ForegroundColor Green
    
    Write-Host "4. Beginning internal review..." -ForegroundColor Cyan
    $reviewAction = @{ actionId = "begin-internal-review" } | ConvertTo-Json
    $reviewed = Invoke-RestMethod -Uri "$baseUrl/instances/$($instance.id)/execute" -Method Post -Body $reviewAction -ContentType "application/json"
    Write-Host "✅ Internal review started: $($reviewed.currentStateId)" -ForegroundColor Green
    
    Write-Host "5. Approving for submission..." -ForegroundColor Cyan
    $approveAction = @{ actionId = "approve-for-submission" } | ConvertTo-Json
    $approved = Invoke-RestMethod -Uri "$baseUrl/instances/$($instance.id)/execute" -Method Post -Body $approveAction -ContentType "application/json"
    Write-Host "✅ Approved for submission: $($approved.currentStateId)" -ForegroundColor Green
    
    Write-Host "6. Awarding grant..." -ForegroundColor Cyan
    $awardAction = @{ actionId = "award-grant" } | ConvertTo-Json
    $awarded = Invoke-RestMethod -Uri "$baseUrl/instances/$($instance.id)/execute" -Method Post -Body $awardAction -ContentType "application/json"
    Write-Host "✅ Grant awarded! Final state: $($awarded.currentStateId)" -ForegroundColor Green
    Write-Host "   History entries: $($awarded.history.Count)" -ForegroundColor White
    
    Write-Host "`n🎉 SUCCESS! Grant Application Lifecycle API is working perfectly!" -ForegroundColor Green
    Write-Host "✅ Frontend: $baseUrl/" -ForegroundColor Yellow
    Write-Host "✅ Swagger: $baseUrl/swagger" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
} 