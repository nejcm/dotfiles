---
name: api-validator
description: API contract testing, OpenAPI validation, and schema compliance verification
compatibility: opencode
metadata:
  version: "2.0.0"
  category: testing
---

# API Validator Skill

Comprehensive API validation including OpenAPI specs, contract testing, schema validation, and API compliance verification.

## Purpose

- Validate OpenAPI/Swagger specifications (3.0, 3.1)
- Test API contract compliance
- Verify request/response schemas
- Check API documentation accuracy
- Detect breaking changes
- Generate mock servers from specs

## Quick Start

```bash
# Validate OpenAPI spec
npx swagger-cli validate openapi.yaml

# Contract testing
dredd openapi.yaml http://localhost:3000

# Lint with Spectral (advanced)
npx @stoplight/spectral-cli lint openapi.yaml
```

---

## Comprehensive Validation Rules

### OpenAPI 3.0 vs 3.1 Differences

**OpenAPI 3.0.x:**
- JSON Schema Draft 4 (Wright Draft 00)
- `nullable: true` for optional fields
- `examples` (plural) for multiple examples
- `type` must be a string

**OpenAPI 3.1.x:**
- JSON Schema 2020-12 (full compatibility)
- Use `type: ['string', 'null']` instead of `nullable`
- `example` (singular) for single example
- `type` can be an array

**Example:**
```yaml
# OpenAPI 3.0
name:
  type: string
  nullable: true
  examples:
    - "John"
    - "Jane"

# OpenAPI 3.1
name:
  type: [string, null]  # Or: type: string with no nullable
  examples:
    - "John"
    - "Jane"
```

### Schema Validation Patterns

#### 1. Required Fields

```yaml
# All users must have email and name
User:
  type: object
  required:
    - email
    - name
  properties:
    email:
      type: string
      format: email
    name:
      type: string
      minLength: 1
    age:
      type: integer
      minimum: 0
```

**Validation:**
```javascript
// ✓ Valid
{ "email": "user@example.com", "name": "John" }

// ✗ Invalid - missing required field
{ "email": "user@example.com" }  // Missing 'name'

// ✗ Invalid - empty string
{ "email": "user@example.com", "name": "" }  // Violates minLength
```

#### 2. Type Constraints

```yaml
# Strict type validation
Product:
  type: object
  properties:
    id:
      type: integer
    price:
      type: number
      multipleOf: 0.01  # Precision to 2 decimal places
    status:
      type: string
      enum: [draft, published, archived]
    tags:
      type: array
      items:
        type: string
      minItems: 1
      maxItems: 10
```

**Validation:**
```javascript
// ✓ Valid
{
  "id": 123,
  "price": 19.99,
  "status": "published",
  "tags": ["electronics", "featured"]
}

// ✗ Invalid - wrong types
{
  "id": "123",        // String instead of integer
  "price": 19.999,    // Not multiple of 0.01
  "status": "active", // Not in enum
  "tags": []          // Violates minItems
}
```

#### 3. Regex Patterns

```yaml
# Pattern matching
User:
  type: object
  properties:
    username:
      type: string
      pattern: '^[a-zA-Z0-9_]{3,20}$'  # Alphanumeric, 3-20 chars
    phone:
      type: string
      pattern: '^\+?[1-9]\d{1,14}$'    # E.164 phone format
    slug:
      type: string
      pattern: '^[a-z0-9-]+$'           # URL-friendly slug
```

**Examples:**
```javascript
// ✓ Valid
{ "username": "john_doe123", "phone": "+1234567890", "slug": "my-article" }

// ✗ Invalid
{ "username": "ab", "phone": "555-1234", "slug": "My Article!" }
```

#### 4. Conditional Validation

```yaml
# oneOf - exactly one schema must match
Payment:
  oneOf:
    - type: object  # Credit card payment
      required: [type, card_number]
      properties:
        type:
          enum: [credit_card]
        card_number:
          type: string
    - type: object  # Bank transfer payment
      required: [type, bank_account]
      properties:
        type:
          enum: [bank_transfer]
        bank_account:
          type: string
```

**Validation:**
```javascript
// ✓ Valid - matches first schema
{ "type": "credit_card", "card_number": "4111111111111111" }

// ✗ Invalid - matches both schemas (should match exactly one)
{ "type": "credit_card", "card_number": "4111", "bank_account": "12345" }
```

### Security Definitions

```yaml
components:
  securitySchemes:
    # Bearer token (JWT)
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

    # API Key
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key

    # OAuth2
    OAuth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://example.com/oauth/authorize
          tokenUrl: https://example.com/oauth/token
          scopes:
            read: Read access
            write: Write access

    # OpenID Connect
    OpenID:
      type: openIdConnect
      openIdConnectUrl: https://example.com/.well-known/openid-configuration

# Apply security globally
security:
  - BearerAuth: []

# Override for specific endpoint
paths:
  /public/health:
    get:
      security: []  # No authentication required
```

### Error Response Validation

```yaml
# Standardized error responses
responses:
  400BadRequest:
    description: Bad request
    content:
      application/json:
        schema:
          type: object
          required: [error, message]
          properties:
            error:
              type: string
              example: "VALIDATION_ERROR"
            message:
              type: string
              example: "Invalid email format"
            details:
              type: array
              items:
                type: object
                properties:
                  field:
                    type: string
                  message:
                    type: string

  404NotFound:
    description: Resource not found
    content:
      application/json:
        schema:
          type: object
          required: [error, message]
          properties:
            error:
              type: string
              example: "NOT_FOUND"
            message:
              type: string
              example: "User not found"

  500InternalError:
    description: Internal server error
    content:
      application/json:
        schema:
          type: object
          required: [error, message]
          properties:
            error:
              type: string
              example: "INTERNAL_ERROR"
            message:
              type: string
              example: "An unexpected error occurred"
            request_id:
              type: string
              example: "req-abc123"
```

**Usage:**
```yaml
paths:
  /api/users/{id}:
    get:
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/400BadRequest'
        '404':
          $ref: '#/components/responses/404NotFound'
        '500':
          $ref: '#/components/responses/500InternalError'
```

---

## Contract Testing Guide

### Dredd Setup and Configuration

**Installation:**
```bash
npm install -g dredd
```

**Basic Configuration (dredd.yml):**
```yaml
dry-run: false
hookfiles: ./hooks.js
language: nodejs
server: npm start
server-wait: 3
init: false
custom:
  apiUrl: http://localhost:3000
names: false
only: []
reporter: [cli, html]
output: [reports/dredd.html]
header: []
sorted: false
user: null
inline-errors: false
details: true
method: []
color: true
level: info
timestamp: false
silent: false
path: []
blueprint: openapi.yaml
endpoint: 'http://localhost:3000'
```

**Hooks (hooks.js):**
```javascript
const hooks = require('hooks');

// Skip certain tests
hooks.before('/api/admin > GET', (transaction, done) => {
  transaction.skip = true;
  done();
});

// Add authentication
hooks.beforeEach((transaction, done) => {
  transaction.request.headers['Authorization'] = 'Bearer test-token';
  done();
});

// Modify request
hooks.before('/api/users > POST', (transaction, done) => {
  const body = JSON.parse(transaction.request.body);
  body.email = `test-${Date.now()}@example.com`;
  transaction.request.body = JSON.stringify(body);
  done();
});

// Validate response
hooks.after('/api/users/{id} > GET', (transaction, done) => {
  const response = JSON.parse(transaction.real.body);
  if (!response.id) {
    transaction.fail = 'Response missing ID field';
  }
  done();
});
```

**Run:**
```bash
# Basic run
dredd openapi.yaml http://localhost:3000

# With configuration
dredd -c dredd.yml

# Only specific endpoints
dredd openapi.yaml http://localhost:3000 --only '/api/users > GET'
```

### Postman/Newman Collection Testing

**Export Postman Collection:**
```bash
# From Postman: Export → Collection v2.1
```

**Run with Newman:**
```bash
# Install Newman
npm install -g newman newman-reporter-htmlextra

# Run collection
newman run collection.json \
  --environment environment.json \
  --reporters cli,htmlextra \
  --reporter-htmlextra-export reports/newman.html

# With data file (for parameterized tests)
newman run collection.json \
  --iteration-data test-data.csv \
  --iteration-count 10
```

**Environment Variables (environment.json):**
```json
{
  "name": "Production",
  "values": [
    { "key": "baseUrl", "value": "https://api.example.com", "enabled": true },
    { "key": "apiKey", "value": "{{$randomUUID}}", "enabled": true },
    { "key": "userId", "value": "", "enabled": true }
  ]
}
```

**Test Data (test-data.csv):**
```csv
username,email,age
john_doe,john@example.com,25
jane_smith,jane@example.com,30
bob_jones,bob@example.com,35
```

### Pact - Consumer-Driven Contracts

**Consumer Side (Frontend):**
```javascript
import { PactV3 } from '@pact-foundation/pact';

const provider = new PactV3({
  consumer: 'FrontendApp',
  provider: 'UserAPI',
});

describe('User API', () => {
  it('should return user by ID', async () => {
    await provider
      .given('user exists with ID 123')
      .uponReceiving('a request for user 123')
      .withRequest({
        method: 'GET',
        path: '/api/users/123',
        headers: { 'Authorization': 'Bearer token' }
      })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: {
          id: 123,
          name: 'John Doe',
          email: 'john@example.com'
        }
      });

    await provider.executeTest(async (mockServer) => {
      const response = await fetch(`${mockServer.url}/api/users/123`);
      const user = await response.json();
      expect(user.id).toBe(123);
    });
  });
});
```

**Provider Side (Backend):**
```javascript
import { Verifier } from '@pact-foundation/pact';

new Verifier({
  providerBaseUrl: 'http://localhost:3000',
  pactUrls: ['./pacts/FrontendApp-UserAPI.json'],
  providerStatesSetupUrl: 'http://localhost:3000/_pact/provider-states',
  publishVerificationResult: true,
  providerVersion: '1.2.3'
}).verifyProvider();
```

### Mock Server Generation

**Prism (OpenAPI Mock Server):**
```bash
# Install
npm install -g @stoplight/prism-cli

# Run mock server
prism mock openapi.yaml

# Mock server with validation
prism mock -d openapi.yaml  # -d = dynamic responses

# Mock server on specific port
prism mock -p 4010 openapi.yaml
```

**Features:**
- Auto-generates responses from examples
- Validates requests against spec
- Returns realistic error responses
- Supports dynamic path parameters

---

## Real-World Examples

### Example 1: REST API Validation

**OpenAPI Spec (openapi.yaml):**
```yaml
openapi: 3.1.0
info:
  title: E-commerce API
  version: 1.0.0

paths:
  /api/products:
    get:
      summary: List products
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            minimum: 1
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
      responses:
        '200':
          description: Products list
          content:
            application/json:
              schema:
                type: object
                properties:
                  products:
                    type: array
                    items:
                      $ref: '#/components/schemas/Product'
                  total:
                    type: integer
                  page:
                    type: integer

    post:
      summary: Create product
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProductInput'
      responses:
        '201':
          description: Product created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
        '400':
          $ref: '#/components/responses/400BadRequest'

components:
  schemas:
    Product:
      type: object
      required: [id, name, price]
      properties:
        id:
          type: integer
        name:
          type: string
        price:
          type: number
          minimum: 0
        category:
          type: string

    ProductInput:
      type: object
      required: [name, price]
      properties:
        name:
          type: string
          minLength: 1
        price:
          type: number
          minimum: 0
        category:
          type: string
```

**Validation:**
```bash
# Lint spec
npx @stoplight/spectral-cli lint openapi.yaml

# Validate against spec
swagger-cli validate openapi.yaml

# Contract test
dredd openapi.yaml http://localhost:3000
```

### Example 2: GraphQL Schema Validation

**Schema (schema.graphql):**
```graphql
type Query {
  user(id: ID!): User
  users(limit: Int = 20): [User!]!
}

type Mutation {
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User
}

input CreateUserInput {
  name: String!
  email: String!
  age: Int
}

type User {
  id: ID!
  name: String!
  email: String!
  age: Int
  createdAt: DateTime!
}

scalar DateTime
```

**Validation:**
```bash
# Install validator
npm install -g graphql-schema-linter

# Lint schema
graphql-schema-linter schema.graphql

# Validate queries
npm install -g @graphql-inspector/cli
graphql-inspector validate 'query.graphql' 'schema.graphql'
```

### Example 3: WebSocket Validation

**AsyncAPI Spec (asyncapi.yaml):**
```yaml
asyncapi: 2.6.0
info:
  title: Chat WebSocket API
  version: 1.0.0

servers:
  production:
    url: wss://chat.example.com
    protocol: ws

channels:
  /chat/{roomId}:
    parameters:
      roomId:
        schema:
          type: string
    subscribe:
      message:
        payload:
          type: object
          properties:
            type:
              type: string
              enum: [message, join, leave]
            content:
              type: string
            user:
              type: string
```

### Example 4: gRPC Validation

**Proto File (user.proto):**
```protobuf
syntax = "proto3";

package user;

service UserService {
  rpc GetUser (GetUserRequest) returns (User);
  rpc ListUsers (ListUsersRequest) returns (ListUsersResponse);
  rpc CreateUser (CreateUserRequest) returns (User);
}

message User {
  int64 id = 1;
  string name = 2;
  string email = 3;
}

message GetUserRequest {
  int64 id = 1;
}

message ListUsersRequest {
  int32 page = 1;
  int32 limit = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  int32 total = 2;
}

message CreateUserRequest {
  string name = 1;
  string email = 2;
}
```

**Validation:**
```bash
# Lint proto file
buf lint

# Breaking change detection
buf breaking --against '.git#branch=main'
```

---

## CI/CD Integration

### Pre-commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash

# Validate OpenAPI spec
npx swagger-cli validate openapi.yaml || exit 1

echo "✓ OpenAPI spec validation passed"
```

### GitHub Actions

```yaml
name: API Validation

on:
  pull_request:
    paths:
      - 'openapi.yaml'
      - 'src/api/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate OpenAPI Spec
        run: npx swagger-cli validate openapi.yaml

      - name: Lint with Spectral
        run: npx @stoplight/spectral-cli lint openapi.yaml

      - name: Check Breaking Changes
        run: |
          git fetch origin main
          npx oasdiff breaking origin/main:openapi.yaml openapi.yaml

      - name: Contract Testing
        run: |
          npm start &
          sleep 5
          dredd openapi.yaml http://localhost:3000

      - name: Generate Mock Server
        run: prism mock -d openapi.yaml &
```

### Breaking Change Detection

```bash
# Install oasdiff
npm install -g oasdiff

# Check for breaking changes
oasdiff breaking old-spec.yaml new-spec.yaml

# Output:
# Breaking changes:
#   - Removed endpoint: DELETE /api/users/{id}
#   - Changed required field: email is now required in User schema
#   - Removed response status code: 201 from POST /api/users
```

### Documentation Drift Detection

```bash
# Check if code matches spec
npx openapi-enforcer-middleware validate \
  --spec openapi.yaml \
  --routes src/routes
```

---

## Configuration Files

See `config/` directory for:
- `dredd.yml` - Dredd configuration
- `openapi-lint.yaml` - Spectral linting rules
- `.spectral.yaml` - Custom validation rules

---

## Best Practices

### DO

✅ **Version your API specs** - Track changes in git
✅ **Validate in CI/CD** - Catch issues before deployment
✅ **Use contract testing** - Ensure frontend/backend compatibility
✅ **Define error responses** - Document all error scenarios
✅ **Provide examples** - Make specs easy to understand
✅ **Check for breaking changes** - Prevent API regressions

### DON'T

❌ **Don't skip validation** - Specs can drift from implementation
❌ **Don't commit without linting** - Catch errors early
❌ **Don't ignore warnings** - They often indicate real problems
❌ **Don't deploy breaking changes** - Without proper versioning

---

## Related

- **Templates:** `specs/api-endpoint-template.md`
- **Skills:** `code-quality`, `run-tests`
- **Examples:** `examples/api-validation-example.md`
- **Agent:** `@builder`, `@reviewer`

---

*Version 2.0.0 - Comprehensive API validation with contract testing*
