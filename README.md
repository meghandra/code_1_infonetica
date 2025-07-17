# .NET State Machine Service

A minimal backend service in .NET 8 for defining and running configurable state machine workflows with real-time state transitions and comprehensive validation.

## Features
- Define custom workflow schemas (states + actions) with validation
- Create and manage workflow instances with state tracking
- Execute actions to transition between states with full business rule enforcement
- In-memory persistence (no database required) with thread-safe operations
- Interactive frontend for visual testing and API exploration
- Comprehensive error handling with meaningful error messages
- RESTful API design with proper HTTP status codes


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

## Understanding States and State Machines

### What is a State Machine?
A **state machine** is a computational model that:
- Has a finite number of **states** (conditions or situations)
- Can transition between states based on **actions** (events or triggers)
- Has business rules about which transitions are allowed
- Tracks the current state and history of changes

### State Types
- **Initial State**: Where new workflow instances start (exactly 1 required)
- **Intermediate States**: States that can transition to other states
- **Final States**: Terminal states where the workflow ends (no outgoing actions)

### Example: Order Processing States
```
┌─────────┐    start-processing    ┌─────────────┐    complete-order    ┌───────────┐
│ PENDING │ ────────────────────► │ PROCESSING  │ ──────────────────► │ COMPLETED │
│(initial)│                       │             │                     │  (final)  │
└─────────┘                       └─────────────┘                     └───────────┘
     │                                   │
     │            cancel-order           │
     └───────────────────────────────────┼──────────────────────────────────────┐
                                         │                                      │
                                         ▼                                      ▼
                                   ┌───────────┐ ◄──────────────────────────────┘
                                   │ CANCELLED │
                                   │  (final)  │
                                   └───────────┘
```

## Step-by-Step API Building and State Transitions

### Step 1: Create a Workflow Definition

**Purpose**: Define the blueprint for your state machine with all possible states and actions.

**Request:**
```bash
curl -X POST http://localhost:5001/workflows \
  -H "Content-Type: application/json" \
  -d '{
    "id": "order-workflow",
    "name": "E-commerce Order Processing",
    "states": [
      {
        "id": "pending",
        "name": "Order Pending",
        "isInitial": true,
        "isFinal": false
      },
      {
        "id": "processing", 
        "name": "Order Processing",
        "isInitial": false,
        "isFinal": false
      },
      {
        "id": "completed",
        "name": "Order Completed",
        "isInitial": false,
        "isFinal": true
      },
      {
        "id": "cancelled",
        "name": "Order Cancelled", 
        "isInitial": false,
        "isFinal": true
      }
    ],
    "actions": [
      {
        "id": "start-processing",
        "name": "Begin Order Processing",
        "fromStates": ["pending"],
        "toState": "processing"
      },
      {
        "id": "complete-order",
        "name": "Complete Order",
        "fromStates": ["processing"],
        "toState": "completed"
      },
      {
        "id": "cancel-order",
        "name": "Cancel Order",
        "fromStates": ["pending", "processing"],
        "toState": "cancelled"
      }
    ]
  }'
```

**Response (201 Created):**
```json
{
  "id": "order-workflow",
  "name": "E-commerce Order Processing",
  "states": [
    {
      "id": "pending",
      "name": "Order Pending", 
      "isInitial": true,
      "isFinal": false
    },
    {
      "id": "processing",
      "name": "Order Processing",
      "isInitial": false, 
      "isFinal": false
    },
    {
      "id": "completed",
      "name": "Order Completed",
      "isInitial": false,
      "isFinal": true
    },
    {
      "id": "cancelled", 
      "name": "Order Cancelled",
      "isInitial": false,
      "isFinal": true
    }
  ],
  "actions": [
    {
      "id": "start-processing",
      "name": "Begin Order Processing",
      "fromStates": ["pending"],
      "toState": "processing"
    },
    {
      "id": "complete-order", 
      "name": "Complete Order",
      "fromStates": ["processing"],
      "toState": "completed"
    },
    {
      "id": "cancel-order",
      "name": "Cancel Order", 
      "fromStates": ["pending", "processing"],
      "toState": "cancelled"
    }
  ]
}
```

### Step 2: Verify Workflow Creation

**Purpose**: Confirm the workflow was stored correctly and review its structure.

**Request:**
```bash
curl -X GET http://localhost:5001/workflows/order-workflow
```

**Response (200 OK):**
```json
{
  "id": "order-workflow",
  "name": "E-commerce Order Processing",
  "states": [...],  // Same as creation response
  "actions": [...]  // Same as creation response
}
```

### Step 3: Create a Workflow Instance

**Purpose**: Start a new instance of the workflow. This creates a running "case" that begins in the initial state.

**Request:**
```bash
curl -X POST http://localhost:5001/workflows/order-workflow/instances
```

**Response (201 Created):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "definitionId": "order-workflow", 
  "currentStateId": "pending",
  "history": []
}
```

**What Happened**: 
- New instance created with unique GUID
- Automatically started in "pending" state (the initial state)
- Empty history (no actions executed yet)

### Step 4: Check Instance Status

**Purpose**: Verify the instance was created and see its current state.

**Request:**
```bash
curl -X GET http://localhost:5001/instances/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**Response (200 OK):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "definitionId": "order-workflow",
  "currentStateId": "pending", 
  "history": []
}
```

### Step 5: Execute First Action (State Transition)

**Purpose**: Move the workflow from "pending" to "processing" state.

**Request:**
```bash
curl -X POST http://localhost:5001/instances/a1b2c3d4-e5f6-7890-abcd-ef1234567890/execute \
  -H "Content-Type: application/json" \
  -d '{
    "actionId": "start-processing"
  }'
```

**Response (200 OK):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "definitionId": "order-workflow",
  "currentStateId": "processing", 
  "history": [
    {
      "actionId": "start-processing",
      "toStateId": "processing",
      "timestamp": "2025-01-17T16:30:00Z"
    }
  ]
}
```

**What Happened**:
- Current state changed: "pending" → "processing"
- History entry added with timestamp
- Action "start-processing" was successfully executed

### Step 6: Execute Second Action (Complete the Order)

**Purpose**: Move from "processing" to final "completed" state.

**Request:**
```bash
curl -X POST http://localhost:5001/instances/a1b2c3d4-e5f6-7890-abcd-ef1234567890/execute \
  -H "Content-Type: application/json" \
  -d '{
    "actionId": "complete-order"
  }'
```

**Response (200 OK):**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", 
  "definitionId": "order-workflow",
  "currentStateId": "completed",
  "history": [
    {
      "actionId": "start-processing",
      "toStateId": "processing", 
      "timestamp": "2025-01-17T16:30:00Z"
    },
    {
      "actionId": "complete-order",
      "toStateId": "completed",
      "timestamp": "2025-01-17T16:31:00Z"
    }
  ]
}
```

**What Happened**:
- Current state changed: "processing" → "completed"  
- Second history entry added
- Workflow is now in final state (no more actions possible)

### Step 7: Attempt Invalid Action (Should Fail)

**Purpose**: Demonstrate validation - trying to execute action on completed (final) instance.

**Request:**
```bash
curl -X POST http://localhost:5001/instances/a1b2c3d4-e5f6-7890-abcd-ef1234567890/execute \
  -H "Content-Type: application/json" \
  -d '{
    "actionId": "cancel-order"
  }'
```

**Response (400 Bad Request):**
```json
{
  "error": "Cannot execute action on an instance in a final state."
}
```

**What Happened**:
- Validation correctly prevented invalid action
- Business rule enforced: no actions allowed on final states
- Error message clearly explains why action was rejected

## Complete State Transition Examples

### Example A: Successful Order Flow
```
Initial State: pending
Execute "start-processing" → processing
Execute "complete-order" → completed (final)
Result: ✅ Successful order completion
```

### Example B: Cancelled Order Flow  
```
Initial State: pending
Execute "cancel-order" → cancelled (final)
Result: ✅ Order cancelled before processing
```

### Example C: Processing Cancellation
```
Initial State: pending  
Execute "start-processing" → processing
Execute "cancel-order" → cancelled (final)
Result: ✅ Order cancelled during processing
```

### Example D: Invalid Transition (Error)
```
Initial State: pending
Execute "complete-order" → ERROR! 
Reason: "complete-order" not allowed from "pending" state
Result: ❌ 400 Bad Request
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