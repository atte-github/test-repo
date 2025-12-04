# Buildkite Cluster Secrets - Development Documentation

## Overview
This document covers the implementation of cluster secrets functionality in the Buildkite Terraform provider, including development workflow, testing procedures, and troubleshooting.

## File Structure and Purpose

### 1. `cluster_secrets.go`
**Purpose:** API client functions for interacting with the Buildkite REST API

**Functions:**
- `GetClusterSecret()` - Retrieves a secret by ID
- `CreateClusterSecret()` - Creates a new secret
- `UpdateClusterSecret()` - Updates secret description and policy
- `UpdateClusterSecretValue()` - Updates secret value
- `DeleteClusterSecret()` - Deletes a secret

**Key Details:**
- Uses REST API endpoints (`/v2/organizations/{org}/clusters/{cluster}/secrets/...`)
- Returns `ClusterSecret` struct with fields: ID, Key, Value, Description, Policy, CreatedAt, UpdatedAt
- Note: The API never returns the `value` field in responses for security reasons

### 2. `resource_cluster_secret.go`
**Purpose:** Terraform resource implementation for managing cluster secrets

**Key Components:**
- `clusterSecretResource` - Main resource struct
- `clusterSecretResourceModel` - Data model matching Terraform schema
- CRUD operations: Create, Read, Update, Delete
- Import functionality

**Important Implementation Details:**

#### Schema Attributes:
- `id` - Computed, uses `UseStateForUnknown()` plan modifier
- `cluster_id` - Required, triggers replace on change
- `key` - Required, triggers replace on change
- `value` - Required, Sensitive, never returned by API
- `description` - Optional
- `policy` - Optional, YAML format
- `created_at` - Computed, uses `UseStateForUnknown()` plan modifier
- `updated_at` - Computed, uses `UseStateForUnknown()` plan modifier

#### Critical Fixes Applied:

**1. Preserving `created_at` on Updates (Line 238-239)**
```go
// In Update function, preserve created_at from existing state
plan.CreatedAt = state.CreatedAt
plan.UpdatedAt = types.StringValue(updated.UpdatedAt)
```

**2. Plan Modifiers for Computed Attributes**
Both `created_at` and `updated_at` need `UseStateForUnknown()` to prevent drift:
```go
PlanModifiers: []planmodifier.String{
    stringplanmodifier.UseStateForUnknown(),
},
```

**3. Preserving `value` in Read Function**
Since API never returns the value, Read function keeps it from state (Line 187-188):
```go
// Note: Value is never returned by API, so we keep the plan value
```

### 3. `cluster_secrets_test.go`
**Purpose:** Unit tests for API client functions

**Tests:**
- `TestGetClusterSecret` - Tests retrieving a secret
- `TestCreateClusterSecret` - Tests creating a secret
- `TestUpdateClusterSecret` - Tests updating description/policy
- `TestUpdateClusterSecretValue` - Tests updating value
- `TestDeleteClusterSecret` - Tests deleting a secret

**Characteristics:**
- Uses `httptest.NewServer()` to mock HTTP responses
- No real API calls required
- Fast execution
- No credentials needed

### 4. `resource_cluster_secret_test.go`
**Purpose:** Acceptance tests for the Terraform resource

**Tests:**
- `TestAccBuildkiteClusterSecret_basic` - Basic create/read/delete lifecycle
- `TestAccBuildkiteClusterSecret_update` - Tests updates to description and value
- `TestAccBuildkiteClusterSecret_withPolicy` - Tests policy creation and updates

**Key Implementation Details:**

**Destroy Check with Authentication:**
```go
func testAccCheckClusterSecretDestroy(s *terraform.State) error {
    org := getenv("BUILDKITE_ORGANIZATION_SLUG")
    apiToken := os.Getenv("BUILDKITE_API_TOKEN")
    httpClient := &http.Client{}
    
    // Manually construct authenticated requests
    req.Header.Set("Authorization", "Bearer "+apiToken)
    // ...
}
```

**Configuration Helpers:**
- `testAccClusterSecretConfig()` - Basic secret configuration
- `testAccClusterSecretConfigWithPolicy()` - Secret with policy configuration

## Development Workflow

### Making Changes to the Provider

1. **Edit the relevant files:**
   - API changes → `cluster_secrets.go`
   - Resource logic → `resource_cluster_secret.go`
   - Schema changes → `resource_cluster_secret.go` (Schema function)

2. **Rebuild the provider:**
```bash
   go build -o terraform-provider-buildkite
```
   - Silent output = successful build
   - Errors will be displayed if build fails

3. **Install locally (for manual testing):**
```bash
   # Linux/Mac
   mkdir -p ~/.terraform.d/plugins/local/buildkite/buildkite/1.0.0/linux_amd64/
   cp terraform-provider-buildkite ~/.terraform.d/plugins/local/buildkite/buildkite/1.0.0/linux_amd64/
```

4. **Update Terraform configuration to use local provider:**
```hcl
   terraform {
     required_providers {
       buildkite = {
         source  = "local/buildkite/buildkite"
         version = "1.0.0"
       }
     }
   }
```

5. **Reinitialize Terraform:**
```bash
   terraform init -upgrade
```

## Testing

### Unit Tests (Fast, No API Required)

**Purpose:** Test API client functions with mocked HTTP responses

**Run all unit tests:**
```bash
cd buildkite
go test -v -run "ClusterSecret"
```

**Run specific unit test:**
```bash
go test -v -run "^TestGetClusterSecret$"
go test -v -run "^TestCreateClusterSecret$"
```

**Expected output:**
```
=== RUN   TestGetClusterSecret
--- PASS: TestGetClusterSecret (0.00s)
=== RUN   TestCreateClusterSecret
--- PASS: TestCreateClusterSecret (0.00s)
...
PASS
```

### Acceptance Tests (Slow, Real API Required)

**Purpose:** Test full Terraform resource lifecycle against real Buildkite API

**Prerequisites:**
1. Valid Buildkite API token
2. Organization slug
3. `TF_ACC=1` environment variable (enables acceptance tests)

**Setup:**
```bash
export BUILDKITE_API_TOKEN="your-token-here"
export BUILDKITE_ORGANIZATION_SLUG="your-org-slug"
```

**Run all acceptance tests:**
```bash
TF_ACC=1 go test -v -run TestAccBuildkiteClusterSecret -timeout 30m
```

**Run specific acceptance test:**
```bash
TF_ACC=1 go test -v -run TestAccBuildkiteClusterSecret_basic -timeout 30m
TF_ACC=1 go test -v -run TestAccBuildkiteClusterSecret_update -timeout 30m
TF_ACC=1 go test -v -run TestAccBuildkiteClusterSecret_withPolicy -timeout 30m
```

**What acceptance tests do:**
1. Create real clusters and secrets in your Buildkite organization
2. Verify resource state matches expectations
3. Test updates and modifications
4. Clean up resources (destroy check)
5. Verify resources were properly deleted

**Expected output (success):**
```
=== RUN   TestAccBuildkiteClusterSecret_basic
--- PASS: TestAccBuildkiteClusterSecret_basic (5.33s)
=== RUN   TestAccBuildkiteClusterSecret_update
--- PASS: TestAccBuildkiteClusterSecret_update (8.15s)
=== RUN   TestAccBuildkiteClusterSecret_withPolicy
--- PASS: TestAccBuildkiteClusterSecret_withPolicy (5.19s)
PASS
```

## Applying Terraform Changes

### Manual Testing Workflow

1. **Create a test Terraform configuration:**
```hcl
   provider "buildkite" {
     # API token from environment variable BUILDKITE_API_TOKEN
     organization = "your-org-slug"
   }

   resource "buildkite_cluster" "test" {
     name        = "Test Cluster"
     description = "Testing cluster secrets"
   }

   resource "buildkite_cluster_secret" "test" {
     cluster_id  = buildkite_cluster.test.uuid
     key         = "MY_TEST_SECRET"
     value       = "secret-value"
     description = "Test secret"
     
     policy = <<-EOT
   - pipeline_slug: my-pipeline
     build_branch: main
   EOT
   }
```

2. **Initialize Terraform:**
```bash
   terraform init
```

3. **Plan changes:**
```bash
   terraform plan
```

4. **Apply changes:**
```bash
   terraform apply
```

5. **Update the secret (modify your .tf file):**
```hcl
   resource "buildkite_cluster_secret" "test" {
     cluster_id  = buildkite_cluster.test.uuid
     key         = "MY_TEST_SECRET"
     value       = "new-secret-value"  # Changed
     description = "Updated description"  # Changed
     
     policy = <<-EOT
   - pipeline_slug: updated-pipeline  # Changed
     build_branch: develop  # Changed
   EOT
   }
```

6. **Apply update:**
```bash
   terraform apply
```

7. **Verify no drift:**
```bash
   terraform plan  # Should show "No changes"
```

8. **Clean up:**
```bash
   terraform destroy
```

## Common Issues and Solutions

### Issue 1: `created_at` Showing as "known after apply"

**Symptom:**
```
~ created_at = "2025-12-04T19:43:27.296Z" -> (known after apply)
```

**Cause:** Missing `UseStateForUnknown()` plan modifier

**Solution:** Add plan modifier to schema:
```go
"created_at": schema.StringAttribute{
    Computed:            true,
    MarkdownDescription: "The time when the secret was created.",
    PlanModifiers: []planmodifier.String{
        stringplanmodifier.UseStateForUnknown(),
    },
},
```

### Issue 2: `updated_at` Causing Drift

**Symptom:**
```
~ updated_at = "2025-12-04T19:43:27.681Z" -> (known after apply)
```

**Solution:** Same as Issue 1 - add plan modifier

### Issue 3: Hidden Attribute Changes (Sensitive Value Drift)

**Symptom:**
```
~ resource "buildkite_cluster_secret" "test" {
      id = "..."
      # (7 unchanged attributes hidden)
  }
```

**Cause:** `value` attribute drift (it's sensitive so hidden in output)

**Solution:** Ensure Read function preserves value from state since API doesn't return it

### Issue 4: Authentication Error in Destroy Check

**Symptom:**
```
Error: Authentication required. Please supply a valid API Access Token
```

**Cause:** Destroy check not including Authorization header

**Solution:** Manually set auth header in destroy check:
```go
req.Header.Set("Authorization", "Bearer "+apiToken)
```

### Issue 5: Inconsistent `updated_at` After Apply

**Symptom:**
```
Error: Provider produced inconsistent result after apply
.updated_at: was cty.StringVal("2025-12-04T20:06:07.487Z"), 
but now cty.StringVal("2025-12-04T20:06:09.144Z")
```

**Cause:** Reading secret after update causes timestamp race condition

**Solution:** Don't read secret in Update function - let Terraform's automatic refresh handle it, or use `UseStateForUnknown()` plan modifier

## Key Learnings from Development

1. **Computed attributes need plan modifiers** - Use `UseStateForUnknown()` for any computed attribute that shouldn't change unexpectedly (like `created_at`)

2. **Preserve values the API doesn't return** - Since `value` is never returned, explicitly keep it from state in Read function

3. **Preserve `created_at` on updates** - In Update function, copy `created_at` from existing state to plan

4. **Authentication in tests** - Destroy checks need manual authentication setup since they don't use the provider's client

5. **Avoid reading after updates** - Let Terraform's automatic refresh handle state updates to avoid timestamp race conditions

## API Behavior Notes

- **Value field**: Never returned by API for security (GET requests return all fields except `value`)
- **Timestamps**: API returns ISO 8601 format (`2025-12-04T19:43:27.296Z`)
- **Policy format**: YAML string with specific structure
- **Updates**: Separate endpoints for value updates vs description/policy updates

## Testing Strategy

1. **Unit tests first** - Fast feedback, no external dependencies
2. **Build the provider** - Verify code compiles
3. **Acceptance tests** - Full integration testing with real API
4. **Manual testing** - Final verification in real-world scenarios

## File Checklist for Changes

When making changes, consider impact on:
- [ ] `cluster_secrets.go` - API client functions
- [ ] `resource_cluster_secret.go` - Resource implementation
- [ ] `cluster_secrets_test.go` - Unit tests
- [ ] `resource_cluster_secret_test.go` - Acceptance tests
- [ ] Rebuild provider after changes
- [ ] Run unit tests
- [ ] Run acceptance tests
- [ ] Manual testing with Terraform

## Quick Reference Commands
```bash
# Build provider
go build -o terraform-provider-buildkite

# Run unit tests
go test -v -run "ClusterSecret"

# Run acceptance tests
export BUILDKITE_API_TOKEN="token"
export BUILDKITE_ORGANIZATION_SLUG="org"
TF_ACC=1 go test -v -run TestAccBuildkiteClusterSecret -timeout 30m

# Terraform workflow
terraform init
terraform plan
terraform apply
terraform destroy
```

## Success Criteria

✅ All unit tests pass
✅ All acceptance tests pass
✅ `terraform plan` shows no changes after apply
✅ `created_at` remains stable during updates
✅ Secrets can be created, updated, and deleted successfully
✅ Policy updates work correctly
✅ Value updates work correctly (but value is never readable)
