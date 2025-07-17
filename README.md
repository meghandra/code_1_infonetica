# Grant Application & Funding Lifecycle Management System

A .NET 8 state machine service for managing research grant applications and funding workflows with real-time state transitions, compliance tracking, and comprehensive validation - designed for research institutions and funding organizations.

## Features
- **Grant Lifecycle Management**: Track applications from drafting to award/rejection
- **Compliance Monitoring**: Built-in validation for fEC/TRAC and institutional requirements  
- **Multi-Stage Review Process**: Support for internal reviews, revisions, and funder submissions
- **Real-time Status Tracking**: Monitor grant applications through all stages
- **Audit Trail**: Complete history of all state transitions with timestamps
- **Thread-safe Operations**: Handle concurrent grant processing safely
- **Interactive Management Interface**: Frontend for grant administrators and researchers
- **RESTful API**: Standards-compliant endpoints for integration with existing systems


## Quick Start Instructions

### 1. Install and Verify .NET 8 SDK
```bash
# Download from: https://dotnet.microsoft.com/download/dotnet/8.0
# After installation, verify:
dotnet --version
# Should show: 8.0.x
```

### 2. Clone and Navigate
```bash
git clone <your-repo-url>
cd c_assig
```

### 3. Build and Run
```bash
# Navigate to the API project
cd WorkflowService.Api

# Restore dependencies
dotnet restore

# Build the project
dotnet build

# Run the application
dotnet run --urls="http://localhost:5001"
```

### 4. Access the Application
- **Interactive Frontend**: http://localhost:5001/
- **API Documentation**: http://localhost:5001/swagger
- **Direct API**: http://localhost:5001/workflows

### 5. Test Basic Functionality
```bash
# Test if API is running
curl http://localhost:5001/swagger

# Should redirect you to Swagger UI
```

## Environment Notes
- **Development**: Runs on HTTP (not HTTPS) for simplicity
- **Port**: Default port 5001 (configurable via --urls parameter)
- **Storage**: In-memory only - data resets on application restart
- **CORS**: Enabled for localhost origins
- **Logging**: Console logging enabled in development mode

## Assumptions and Design Decisions

### Assumptions
- **Single User**: No authentication or multi-tenancy (designed for single-user scenarios)
- **In-Memory Storage**: Data doesn't persist between application restarts
- **Development Focus**: Optimized for development and testing, not production deployment
- **HTTP Only**: No HTTPS/SSL for simplicity (add reverse proxy for production)
- **Basic Validation**: Focuses on core workflow logic validation

### Shortcuts Taken
- **No Database**: Uses in-memory storage instead of persistent database
- **Minimal Error Handling**: Basic exception handling without detailed logging
- **No Authentication**: No user management or API keys
- **No Rate Limiting**: No protection against API abuse
- **No Input Sanitization**: Assumes trusted input (add validation for production)

### Known Limitations
- **Data Loss**: All data lost on application restart
- **Memory Usage**: No limits on number of workflows/instances (could cause memory issues)
- **Concurrency**: Basic thread-safety, not optimized for high-concurrency scenarios
- **No Workflow Versioning**: Cannot update existing workflow definitions
- **No Bulk Operations**: Must create/manage instances individually
- **No State Machine Visualization**: No graphical representation of workflow states
- **Fixed Port**: Hardcoded to specific port (configurable via command line only)

## API Endpoints Overview

| Method | Endpoint | Description | Status Codes |
|--------|----------|-------------|--------------|
| **POST** | `/workflows` | Create a new workflow definition | 201, 400 |
| **GET** | `/workflows/{id}` | Retrieve workflow definition | 200, 404 |
| **POST** | `/workflows/{id}/instances` | Start new workflow instance | 201, 404 |
| **GET** | `/instances/{id}` | Get instance details and history | 200, 404 |
| **POST** | `/instances/{id}/execute` | Execute action on instance | 200, 400, 404 |

## Understanding Grant Application Lifecycle

### What is a Grant State Machine?
A **grant application state machine** is a computational model that:
- Tracks **grant applications** through their entire lifecycle
- Enforces **compliance rules** and approval workflows
- Maintains **audit trails** for institutional and funder requirements
- Automates **status transitions** based on reviewer actions

### Grant Application State Types
- **Initial State**: Where new grant applications begin (Drafting)
- **Review States**: States where applications undergo evaluation
- **Revision States**: States requiring applicant input or corrections
- **Final States**: Terminal states (Awarded, Rejected) where the process ends

### Grant Application & Funding Lifecycle
```
┌──────────┐    submit-application    ┌───────────┐    approve-internal    ┌─────────────────┐
│ DRAFTING │ ─────────────────────► │ SUBMITTED │ ─────────────────► │ UNDER_INTERNAL_ │
│(initial) │                        │           │                    │     REVIEW      │
└──────────┘                        └───────────┘                    └─────────────────┘
                                                                              │
                                                                              │ request-revisions
                                                                              ▼
    ┌─────────────────┐ ◄─── submit-revisions ─── ┌─────────────────┐       │
    │ SUBMITTED_TO_   │                           │ PENDING_        │ ◄─────┘
    │    FUNDER       │                           │  REVISIONS      │
    └─────────────────┘                           └─────────────────┘
              │                                            │
              │                                            │ submit-revisions
              │                                            ▼
              │                                   ┌─────────────────┐
              │                                   │ UNDER_INTERNAL_ │
              │                                   │     REVIEW      │
              │                                   └─────────────────┘
              │
    ┌─────────┼─────────┐
    │         │         │
    ▼         ▼         ▼
┌─────────┐ ┌─────────┐ ┌──────────┐
│ AWARDED │ │REJECTED │ │WITHDRAWN │
│ (final) │ │ (final) │ │ (final)  │
└─────────┘ └─────────┘ └──────────┘
```

## Step-by-Step Grant Application API Implementation

### Step 1: Create a Grant Lifecycle Workflow

**Purpose**: Define the complete grant application lifecycle with all states, review processes, and compliance checkpoints.

**Request:**
```bash
curl -X POST http://localhost:5001/workflows \
  -H "Content-Type: application/json" \
  -d '{
    "id": "grant-lifecycle",
    "name": "Research Grant Application & Funding Lifecycle",
    "states": [
      {
        "id": "drafting",
        "name": "Application Drafting",
        "isInitial": true,
        "isFinal": false
      },
      {
        "id": "submitted", 
        "name": "Submitted for Review",
        "isInitial": false,
        "isFinal": false
      },
      {
        "id": "under_internal_review",
        "name": "Under Internal Review (fEC/TRAC)",
        "isInitial": false,
        "isFinal": false
      },
      {
        "id": "pending_revisions",
        "name": "Pending Revisions",
        "isInitial": false,
        "isFinal": false
      },
      {
        "id": "submitted_to_funder",
        "name": "Submitted to External Funder",
        "isInitial": false,
        "isFinal": false
      },
      {
        "id": "awarded",
        "name": "Grant Awarded",
        "isInitial": false,
        "isFinal": true
      },
      {
        "id": "rejected",
        "name": "Grant Rejected",
        "isInitial": false,
        "isFinal": true
      },
      {
        "id": "withdrawn",
        "name": "Application Withdrawn",
        "isInitial": false,
        "isFinal": true
      }
    ],
    "actions": [
      {
        "id": "submit-application",
        "name": "Submit Application for Review",
        "fromStates": ["drafting"],
        "toState": "submitted"
      },
      {
        "id": "begin-internal-review",
        "name": "Begin Internal Compliance Review",
        "fromStates": ["submitted"],
        "toState": "under_internal_review"
      },
      {
        "id": "request-revisions",
        "name": "Request Revisions from Applicant",
        "fromStates": ["under_internal_review"],
        "toState": "pending_revisions"
      },
      {
        "id": "submit-revisions",
        "name": "Submit Revised Application",
        "fromStates": ["pending_revisions"],
        "toState": "under_internal_review"
      },
      {
        "id": "approve-for-submission",
        "name": "Approve for Funder Submission",
        "fromStates": ["under_internal_review"],
        "toState": "submitted_to_funder"
      },
      {
        "id": "award-grant",
        "name": "Grant Awarded by Funder",
        "fromStates": ["submitted_to_funder"],
        "toState": "awarded"
      },
      {
        "id": "reject-grant",
        "name": "Grant Rejected by Funder",
        "fromStates": ["submitted_to_funder"],
        "toState": "rejected"
      },
      {
        "id": "withdraw-application",
        "name": "Withdraw Application",
        "fromStates": ["drafting", "submitted", "under_internal_review", "pending_revisions"],
        "toState": "withdrawn"
      }
    ]
  }'
```

**Response (201 Created):**
```json
{
  "id": "grant-lifecycle",
  "name": "Research Grant Application & Funding Lifecycle",
  "states": [
    {
      "id": "drafting",
      "name": "Application Drafting", 
      "isInitial": true,
      "isFinal": false
    },
    {
      "id": "submitted",
      "name": "Submitted for Review",
      "isInitial": false, 
      "isFinal": false
    },
    {
      "id": "under_internal_review",
      "name": "Under Internal Review (fEC/TRAC)",
      "isInitial": false,
      "isFinal": false
    },
    {
      "id": "pending_revisions",
      "name": "Pending Revisions",
      "isInitial": false,
      "isFinal": false
    },
    {
      "id": "submitted_to_funder",
      "name": "Submitted to External Funder",
      "isInitial": false,
      "isFinal": false
    },
    {
      "id": "awarded", 
      "name": "Grant Awarded",
      "isInitial": false,
      "isFinal": true
    },
    {
      "id": "rejected",
      "name": "Grant Rejected",
      "isInitial": false,
      "isFinal": true
    },
    {
      "id": "withdrawn",
      "name": "Application Withdrawn",
      "isInitial": false,
      "isFinal": true
    }
  ],
  "actions": [
    {
      "id": "submit-application",
      "name": "Submit Application for Review",
      "fromStates": ["drafting"],
      "toState": "submitted"
    },
    {
      "id": "begin-internal-review", 
      "name": "Begin Internal Compliance Review",
      "fromStates": ["submitted"],
      "toState": "under_internal_review"
    },
    {
      "id": "request-revisions",
      "name": "Request Revisions from Applicant", 
      "fromStates": ["under_internal_review"],
      "toState": "pending_revisions"
    },
    {
      "id": "submit-revisions",
      "name": "Submit Revised Application",
      "fromStates": ["pending_revisions"],
      "toState": "under_internal_review"
    },
    {
      "id": "approve-for-submission",
      "name": "Approve for Funder Submission",
      "fromStates": ["under_internal_review"],
      "toState": "submitted_to_funder"
    },
    {
      "id": "award-grant",
      "name": "Grant Awarded by Funder",
      "fromStates": ["submitted_to_funder"],
      "toState": "awarded"
    },
    {
      "id": "reject-grant",
      "name": "Grant Rejected by Funder",
      "fromStates": ["submitted_to_funder"],
      "toState": "rejected"
    },
    {
      "id": "withdraw-application",
      "name": "Withdraw Application",
      "fromStates": ["drafting", "submitted", "under_internal_review", "pending_revisions"],
      "toState": "withdrawn"
    }
  ]
}
```

### Step 2: Verify Grant Workflow Creation

**Purpose**: Confirm the grant lifecycle workflow was stored correctly and review compliance requirements.

**Request:**
```bash
curl -X GET http://localhost:5001/workflows/grant-lifecycle
```

**Response (200 OK):**
```json
{
  "id": "grant-lifecycle",
  "name": "Research Grant Application & Funding Lifecycle",
  "states": [...],  // Same as creation response - 8 states from drafting to final outcomes
  "actions": [...]  // Same as creation response - 8 actions for complete lifecycle management
}
```

### Step 3: Create a Grant Application Instance

**Purpose**: Start tracking a new grant application. This creates a running "case" that begins in the drafting state.

**Request:**
```bash
curl -X POST http://localhost:5001/workflows/grant-lifecycle/instances
```

**Response (201 Created):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "definitionId": "grant-lifecycle", 
  "currentStateId": "drafting",
  "history": []
}
```

**What Happened**: 
- New grant application instance created with unique GUID (serves as application ID)
- Automatically started in "drafting" state (researchers can begin preparing their application)
- Empty history (no review actions executed yet)
- Ready for researcher to submit application for institutional review

### Step 4: Check Grant Application Status

**Purpose**: Verify the grant application was created and monitor its current state in the review process.

**Request:**
```bash
curl -X GET http://localhost:5001/instances/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**Response (200 OK):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "definitionId": "grant-lifecycle",
  "currentStateId": "drafting", 
  "history": []
}
```

### Step 5: Researcher Submits Application (State Transition)

**Purpose**: Researcher submits their completed grant application for institutional review.

**Request:**
```bash
curl -X POST http://localhost:5001/instances/a1b2c3d4-e5f6-7890-abcd-ef1234567890/execute \
  -H "Content-Type: application/json" \
  -d '{
    "actionId": "submit-application"
  }'
```

**Response (200 OK):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "definitionId": "grant-lifecycle",
  "currentStateId": "submitted", 
  "history": [
    {
      "actionId": "submit-application",
      "toStateId": "submitted",
      "timestamp": "2025-01-17T16:30:00Z"
    }
  ]
}
```

**What Happened**:
- Grant application state changed: "drafting" → "submitted"
- History entry added with timestamp for audit trail
- Application is now queued for institutional compliance review (fEC/TRAC)

### Step 6: Begin Internal Compliance Review (fEC/TRAC)

**Purpose**: Institutional review office begins compliance review for fEC, TRAC, and other requirements.

**Request:**
```bash
curl -X POST http://localhost:5001/instances/a1b2c3d4-e5f6-7890-abcd-ef1234567890/execute \
  -H "Content-Type: application/json" \
  -d '{
    "actionId": "begin-internal-review"
  }'
```

**Response (200 OK):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", 
  "definitionId": "grant-lifecycle",
  "currentStateId": "under_internal_review",
  "history": [
    {
      "actionId": "submit-application",
      "toStateId": "submitted", 
      "timestamp": "2025-01-17T16:30:00Z"
    },
    {
      "actionId": "begin-internal-review",
      "toStateId": "under_internal_review",
      "timestamp": "2025-01-17T16:31:00Z"
    }
  ]
}
```

**What Happened**:
- Grant application state changed: "submitted" → "under_internal_review"  
- Second history entry added showing review process initiation
- Application is now undergoing institutional compliance checks (fEC, TRAC, etc.)
- Review office can now either approve for submission or request revisions

### Step 7: Attempt Invalid Action (Validation Demo)

**Purpose**: Demonstrate business rule validation - trying to award a grant before it's submitted to funder.

**Request:**
```bash
curl -X POST http://localhost:5001/instances/a1b2c3d4-e5f6-7890-abcd-ef1234567890/execute \
  -H "Content-Type: application/json" \
  -d '{
    "actionId": "award-grant"
  }'
```

**Response (400 Bad Request):**
```json
{
  "error": "Action 'award-grant' cannot be executed from state 'under_internal_review'."
}
```

**What Happened**:
- Validation correctly prevented invalid state transition
- Business rule enforced: grants can only be awarded after external submission
- Institutional review process must be completed before funder submission
- Error message clearly explains the compliance violation

## Complete Grant Application Lifecycle Examples

### Example A: Successful Grant Award Flow
```
Initial State: drafting
Execute "submit-application" → submitted
Execute "begin-internal-review" → under_internal_review
Execute "approve-for-submission" → submitted_to_funder
Execute "award-grant" → awarded (final)
Result: ✅ Grant successfully awarded with full compliance
```

### Example B: Grant Application with Revisions
```
Initial State: drafting
Execute "submit-application" → submitted
Execute "begin-internal-review" → under_internal_review
Execute "request-revisions" → pending_revisions
Execute "submit-revisions" → under_internal_review
Execute "approve-for-submission" → submitted_to_funder
Execute "award-grant" → awarded (final)
Result: ✅ Grant awarded after revision cycle
```

### Example C: Grant Rejection Flow
```
Initial State: drafting
Execute "submit-application" → submitted
Execute "begin-internal-review" → under_internal_review
Execute "approve-for-submission" → submitted_to_funder
Execute "reject-grant" → rejected (final)
Result: ✅ Grant rejected by external funder
```

### Example D: Early Withdrawal
```
Initial State: drafting
Execute "submit-application" → submitted
Execute "withdraw-application" → withdrawn (final)
Result: ✅ Application withdrawn during institutional review
```

### Example E: Invalid Transition (Compliance Error)
```
Initial State: under_internal_review
Execute "award-grant" → ERROR! 
Reason: "award-grant" not allowed from "under_internal_review" state
Result: ❌ 400 Bad Request - Must go through funder submission first
```

## Error Handling and Troubleshooting

### Common Error Scenarios

| Error Code | Message | Cause | Solution |
|------------|---------|-------|----------|
| **400** | "Definition must have exactly one initial state" | Multiple or no initial states | Ensure exactly one state has `"isInitial": true` |
| **400** | "Action 'X' points to a non-existent ToState 'Y'" | Invalid state reference in action | Check that `toState` references existing state ID |
| **400** | "Action not found in workflow definition" | Invalid action ID in execute request | Use valid action ID from workflow definition |
| **400** | "Cannot execute action on an instance in a final state" | Trying to execute action on completed workflow | Final states cannot transition further |
| **400** | "Action 'X' cannot be executed from state 'Y'" | Invalid state transition | Check action's `fromStates` array |
| **404** | "Workflow definition not found" | Invalid workflow ID | Use existing workflow ID or create workflow first |
| **404** | "Workflow instance not found" | Invalid instance ID | Use valid instance GUID |

### Port Conflicts
If you see `address already in use` errors:
```bash
# Use different port
dotnet run --urls="http://localhost:5002"

# Or stop existing process and restart
# Check Task Manager for dotnet.exe processes
```

### Build Issues
```bash
# Clear and rebuild
dotnet clean
dotnet restore
dotnet build
```

### CORS Issues
If frontend cannot reach API, ensure:
- Backend running on correct port (5001)
- Frontend accessing correct URL
- CORS configured for your origin

## Project Structure
```
c_assig/
├── WorkflowService.sln                   # Solution file
├── README.md                             # This documentation
├── .gitignore                           # Git ignore patterns
├── test-api.ps1                         # PowerShell test script
├── test-api-5001.ps1                    # PowerShell test script for port 5001
└── WorkflowService.Api/                 # Main API project
    ├── Domain/
    │   └── WorkflowModels.cs            # Core domain models (State, Action, WorkflowDefinition, WorkflowInstance)
    ├── Models/
    │   └── ApiModels.cs                 # API request/response models
    ├── Services/
    │   ├── InMemoryDataStore.cs         # Thread-safe in-memory data persistence
    │   └── WorkflowEngineService.cs     # Core business logic and validation engine
    ├── wwwroot/
    │   └── index.html                   # Interactive frontend interface
    ├── Properties/
    │   └── launchSettings.json          # Development launch configuration
    ├── Program.cs                       # API endpoints, middleware, and configuration
    └── WorkflowService.Api.csproj       # Project dependencies and settings
```

## Business Rules Implementation
- **Single Initial State**: Each workflow definition must have exactly one initial state
- **State Reference Validation**: All action transitions must reference existing states
- **Final State Protection**: Actions cannot be executed from final states
- **Transition Validation**: Actions can only be executed if the current state is in the action's "fromStates" list
- **History Tracking**: All state transitions are recorded with timestamps in the instance history
- **Concurrency Safety**: Thread-safe operations using ConcurrentDictionary
- **Input Validation**: Comprehensive null checks and business rule enforcement

## Technology Stack
- **.NET 8**: Latest LTS version with improved performance
- **ASP.NET Core Minimal APIs**: Lightweight, fast API endpoints
- **C# Records**: Immutable data structures for domain models
- **ConcurrentDictionary**: Thread-safe in-memory data storage
- **Swagger/OpenAPI**: Automatic API documentation generation
- **Vanilla JavaScript**: Frontend interaction without frameworks
- **HTML5/CSS3**: Modern frontend interface with responsive design

## Testing Options
1. **Interactive Frontend**: http://localhost:5001/ (Visual, user-friendly)
2. **Swagger UI**: http://localhost:5001/swagger (API documentation and testing)
3. **PowerShell Scripts**: `.\test-api-5001.ps1` (Automated testing)
4. **curl Commands**: Manual API testing via command line
5. **Postman/Insomnia**: Import OpenAPI spec for GUI testing

## Future Enhancements
- **Database Integration**: Replace in-memory storage with SQL Server/PostgreSQL
- **Authentication**: Add JWT-based API authentication
- **WebSocket Support**: Real-time workflow state notifications  
- **Visual Designer**: Drag-and-drop workflow builder interface
- **Workflow Versioning**: Support for updating workflow definitions
- **Bulk Operations**: APIs for managing multiple instances
- **Metrics Dashboard**: Workflow performance and analytics
- **Docker Support**: Containerization for easy deployment 