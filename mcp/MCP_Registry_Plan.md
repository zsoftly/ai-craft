# ZSoftly MCP Registry - Technical Plan

## 1. Executive Summary

This document outlines a technical plan for building a **ZSoftly Model Context Protocol (MCP) Registry**. The goal is to create a private, internal registry to host and manage ZSoftly's proprietary AI Agents and Tools. This registry will function as a central discovery mechanism, allowing applications and other AI agents to dynamically find, understand, and connect to the capabilities offered by registered agents.

The proposed solution is a lightweight, secure, and cloud-native RESTful service that manages metadata for our AI agents. This plan covers the core concepts, proposed architecture, agent lifecycle management, security considerations, and deployment strategy. It is intended to be a roadmap for an engineering team to implement the registry.

## 2. MCP Registry Concept Explained

An MCP Registry is **not** a hosting platform for AI models. Instead, it is a **discovery service** or a **catalog**. Its primary purpose is to answer the question: "What AI capabilities are available, and how do I use them?"

It works by storing metadata about "MCP Servers" (in our case, ZSoftly AI Agents). Each agent is described by a manifest file (e.g., `agent.json`) which contains:

- **Identity:** Name, version, owner, description.
- **Contract:** An OpenAPI (or similar) specification that defines the agent's capabilities as a set of callable tools or functions.
- **Location:** The network endpoint (URL) where the agent can be reached.

Client applications query the registry to find agents that meet their needs (e.g., "find an agent that can summarize text"). The registry returns the manifest of the matching agent(s), and the client then uses that information to communicate directly with the agent.

For ZSoftly, a private MCP registry provides a secure, centralized way to manage our growing ecosystem of internal AI agents, promoting reuse, standardization, and governance.

## 3. Agent Lifecycle Management

The lifecycle of a ZSoftly AI Agent within the registry involves three key stages: **Registration**, **Discovery**, and **Versioning**. This process is managed via a RESTful API and a standardized manifest file.

### 3.1 The `agent.json` Manifest

This file is the source of truth for an agent's metadata. Each agent project MUST include an `agent.json` file at its root.

**Fields:**

  - `name` (string, required): A unique, machine-readable name for the agent (e.g., `document-summarizer`, `user-profile-service`).
  - `version` (string, required): The semantic version of the agent (e.g., `1.0.0`).
  - `displayName` (string, optional): A human-readable name for display in UIs.
  - `description` (string, required): A clear, concise summary of the agent's purpose and capabilities.
  - `owner` (string, required): The ZSoftly team or individual responsible for the agent (e.g., `team-alpha`, `user@zsoftly.com`).
  - `endpoint` (string, required): The base URL where the agent's service can be accessed.
  - `openapi` (object, required): A valid OpenAPI 3.x specification object describing the agent's available `paths` and `components`. This is the contract for using the agent.
  - `environment` (enum, required): The environment this agent is deployed to. (`dev`, `stage`, or `prod`). This is critical for multi-environment support.
  - `tags` (array of strings, optional): Keywords to improve discoverability (e.g., `["nlp", "text", "summary"]`).

### 3.2 Registry API Endpoints

The registry will expose the following core endpoints:

#### Agent Registration

- `POST /agents`
  - **Action:** Publishes or updates an agent. The request body will be the `agent.json` manifest.
  - **Logic:** The registry validates the manifest against a schema. If an agent with the same `name` and `version` already exists, it is updated. Otherwise, a new version is created. The `name` and `version` from the manifest are used as the unique identifier.
  - **Auth:** Requires a publisher role.

#### Agent Discovery

- `GET /agents`

  - **Action:** Returns a paginated list of all registered agents (latest version of each).
  - **Auth:** Requires a reader role.

- `GET /agents/{name}`

  - **Action:** Returns a list of all available versions for a specific agent.
  - **Auth:** Requires a reader role.

- `GET /agents/{name}/{version}`
  - **Action:** Returns the specific `agent.json` for the given name and version (e.g., `/agents/document-summarizer/1.2.0`). Use `latest` as the version to get the most recently published version.
  - **Auth:** Requires a reader role.

#### Agent Search

- `GET /search?q={query}`
  - **Action:** Searches for agents. The query will match against `name`, `displayName`, `description`, and `tags`.
  - **Example:** `/search?q=summarize`
  - **Auth:** Requires a reader role.

#### Agent Deletion

- `DELETE /agents/{name}/{version}`
  - **Action:** Deletes a specific version of an agent. This is a soft-delete to prevent breaking dependencies. A hard-delete mechanism can be decided on later.
  - **Auth:** Requires a publisher/admin role.

### 3.3 Versioning Strategy

    - The registry will use **Semantic Versioning (SemVer)** as specified in the `agent.json` (`major.minor.patch`).
    - A combination of `name` and `version` uniquely identifies an agent manifest.
    - Clients should be encouraged to request a specific major version (e.g., `1.x`) or use the `latest` tag with caution.
      - **Version Range Resolution (`1.x`):** When a client requests a major version like `1.x`, the registry will resolve this to the **highest available patch version of the highest available minor version within that major version**. (e.g., for `1.x`, if `1.2.0` and `1.3.5` exist, it resolves to `1.3.5`). This ensures the most up-to-date non-breaking version is provided.
      - **`latest` Tag:** The `latest` tag will always point to the most recently published version, **regardless of whether it introduces breaking changes**. Consumers are advised to use `latest` with extreme caution in production environments, as it offers no guarantee of backward compatibility.
## 4. Proposed Architecture

The MCP Registry will be a simple, robust, and scalable system composed of three core components. The architecture prioritizes statelessness and cloud-native principles.

```text
+---------------------------------------------------------------------------------------+
|                                  MCP Registry                                         |
|                                                                                       |
|  +---------------------+      +---------------------+      +---------------------+  |
|  |     Client Apps     |<---->|  REST API           |<---->|     Database        |  |
|  | (Agent Consumers)   |      | (Registry Service)  |      | (PostgreSQL/RDS)    |  |
|  +---------------------+      |                     |      |                     |  |
|                               | - Handles Requests  |      | - Stores Agent      |  |
|                               | - Authentication    |      |   Manifests         |  |
|                               | - DB Communication  |      | - Stores Versions   |  |
|                               +---------------------+      | - Supports Search   |  |
|                                         ^                  +---------------------+  |
|                                         |                                           |
|                                         | (Validation Logic)                        |
|                                         |                                           |
|                               +---------------------+                               |
|                               | Validation Logic    |                               |
|                               | - agent.json Schema |                               |
|                               | - OpenAPI Spec      |                               |
|                               +---------------------+                               |
|                                                                                       |
+---------------------------------------------------------------------------------------+
```

### 4.1 System Components

1.  **REST API (Registry Service):**

    - **Description:** The heart of the system, this service exposes all the endpoints defined in the "Agent Lifecycle Management" section. It handles incoming requests, authentication, and communication with the database.
    - **Technology:** A stateless web application.
    - **Recommendation:** **FastAPI (Python)**. Its native support for Pydantic models makes validation of incoming `agent.json` manifests trivial. Its automatic generation of OpenAPI documentation is also a significant benefit.

2.  **Database:**

    - **Description:** A persistent storage layer for all agent **metadata**. While initially proposed to store the full `openapi_spec` in the database, a more scalable and robust approach is to offload large objects to a dedicated object store. The database will continue to support structured data, indexing for fast lookups, and full-text search capabilities for the `GET /search` endpoint.
    - **Recommendation:** **PostgreSQL**. Its robustness, support for JSONB data types for metadata, and powerful indexing features make it a perfect fit. Using a managed cloud service (like AWS RDS) is highly recommended.
    - **OpenAPI Spec Storage:** To improve auditability and reduce database load, OpenAPI specifications will be stored in **Amazon S3**. The database will store a reference to the S3 object, including a checksum, to ensure integrity. This approach also enables version immutability, as a new version of an agent will point to a new, immutable S3 object.

3.  **Validation Logic:**
    - **Description:** Before any data is written to the database, incoming `agent.json` manifests must be validated. This includes checking for required fields, correct data types, and ensuring the embedded OpenAPI contract is syntactically valid.
    - **Implementation:** This logic will be implemented directly within the REST API service, leveraging the data validation features of the chosen framework (e.g., Pydantic models in FastAPI).

### 4.2 Data Model

A primary `agents` table will store the core metadata.

  - `id` (PK)
  - `name` (Indexed)
  - `version` (Indexed)
  - `display_name`
  - `description`
  - `owner`
  - `endpoint`
  - `environment` (Indexed)
  - `tags` (Indexed, using GIN index on a JSONB field)
  - `openapi_spec_s3_uri` (string)
  - `openapi_spec_checksum` (string)
  - `created_at`
  - `is_deleted` (for soft deletes)

A unique constraint will be placed on `(name, version)` to enforce uniqueness.

### 4.3 Environment Isolation Strategy

The initial plan proposed a single registry instance for all environments, relying on an `environment` field for logical separation. However, a production-grade implementation requires stronger isolation to prevent environment bleed-through and simplify security management.

**Strong Recommendation: One Registry per Environment**

To achieve robust isolation, we will deploy a separate, independent registry instance for each environment:

-   `mcp-registry-dev`
-   `mcp-registry-stage`
-   `mcp-registry-prod`

This approach provides several key advantages:

-   **Data Isolation:** Each environment has its own dedicated database, preventing accidental access to or modification of production agent metadata from lower environments.
-   **Simplified IAM:** AWS IAM policies can be scoped directly to the resources of a single environment, simplifying access control and reducing the risk of misconfiguration.
-   **Incident Containment:** An issue in the `dev` or `stage` registry will not impact the `prod` registry, limiting the blast radius of any incidents.
-   **Clear API Scoping:** Consumers of the registry will use a different endpoint for each environment, making it explicit which set of agents they are interacting with.

If, for operational reasons, a single instance must be retained, the following controls would be mandatory:

-   **Environment-Scoped API Keys:** API keys would be generated with a specific environment scope, and the API would enforce that a `dev` key cannot be used to publish to the `prod` environment.
-   **Environment-Based Authorization:** Middleware would be required to enforce authorization based on the environment, ensuring that a user's role and the environment of the resource being accessed are both validated.


## 5. Hosting and Deployment

Our hosting strategy should be cloud-first, prioritizing managed services to reduce operational overhead.

### 5.1 Primary Recommendation: Serverless Containers

This approach offers the best balance of performance, scalability, and ease of management.

  - **Compute:** **AWS Fargate**.
    - The FastAPI application will be packaged into a **Docker container**.
    - These platforms automatically manage scaling (including scaling to zero), patching, and server infrastructure.
    - **Best Practices:**
        - Enable autoscaling based on request count or CPU utilization to handle fluctuating loads.
        - Run at least two tasks per service for high availability.
        - Implement graceful shutdown hooks in FastAPI to ensure that in-flight requests are not dropped during deployments.
  - **Database:** **AWS RDS for PostgreSQL**.
    - A managed database service handles backups, failover, and maintenance.
    - **Best Practices:**
        - Enable Multi-AZ for high availability and automated failover.
        - Configure automated backups and Point-In-Time-Recovery (PITR) to protect against data loss.
        - Enable encryption at rest using AWS KMS to protect sensitive data.
        - Implement connection pooling using PgBouncer or by tuning the SQLAlchemy pool settings to efficiently manage database connections.
  - **CI/CD:** The process of publishing the registry itself (and agents to it) should be automated. A GitHub Actions or GitLab CI pipeline would build the Docker image, push it to a container registry (e.g., ECR), and trigger a deployment in Fargate.

### 5.2 Alternative: Serverless Functions

For potentially lower-traffic scenarios or as a cost-saving measure, a purely serverless function architecture could be used.

  - **Compute:** **AWS Lambda**.
    - Each API endpoint or a group of related endpoints would be a separate function.
  - **Gateway:** **Amazon API Gateway** would be used to manage the public-facing API routes and trigger the appropriate functions.
  - **Database:** **AWS Aurora Serverless** or **DynamoDB**.

### 5.3 Infrastructure as Code

The entire infrastructure for the MCP Registry will be managed using Infrastructure as Code (IaC) to ensure consistency, repeatability, and version control.

-   **Technology:** We will use **Terraform** or **OpenTofu** to define and manage all cloud resources, including:
    -   VPC, subnets, and networking rules
    -   ECS cluster and Fargate services
    -   RDS database
    -   IAM roles and policies
    -   Secrets in AWS Secrets Manager
-   **Structure:** The IaC code will be organized into versioned modules, with separate state files for each environment (`dev`, `stage`, `prod`). This will allow for safe and predictable deployments to each environment.

### 5.4 Conclusion

## 6. Security and Access Control

Security is a critical component of the registry, ensuring that only authorized users and services can publish or access agent information.

### 6.1 Authentication: From API Keys to IAM and OIDC

The initial plan proposed API keys for authentication. While simple to implement, API keys are not sufficient for a production-grade internal platform due to the risks of key leakage, lack of identity context, and difficult rotation.

For production, we will adopt a more secure, identity-based authentication model.

**Recommended Authentication Model (Best Practice)**

-   **Primary Method: IAM + SigV4 Authentication**
    -   The registry will be deployed behind an Application Load Balancer (ALB) or API Gateway, and access will be controlled via AWS IAM.
    -   Human users and service accounts (e.g., CI/CD pipelines, other agents) will be granted specific IAM roles that allow them to assume a role to access the registry.
    -   All requests to the registry API must be signed with AWS Signature Version 4 (SigV4), which provides strong authentication and identity context.
    -   This model eliminates the need for static secrets like API keys, as authentication is based on short-lived credentials obtained by assuming an IAM role.

-   **Alternative (if IAM is not feasible): OAuth2 / OIDC**
    -   If a pure IAM-based approach is not feasible, an alternative is to use an OpenID Connect (OIDC) provider, such as GitHub Actions OIDC or an internal Identity Provider (IdP).
    -   Clients would authenticate with the IdP to obtain a short-lived JSON Web Token (JWT), which would then be passed to the registry API.
    -   The API would validate the JWT and extract the user's identity and permissions.

- **API Keys (Limited Use)**

            - API keys will be deprecated for production use and are considered a **transitional mechanism for Phase 1 MVP and development environments only**.

            - They may be retained for limited, temporary use cases, such as:

                - **Local development:** To provide a simple way for developers to interact with the `dev` registry.

                - **CLI bootstrap:** To perform initial setup or administrative tasks in development.

            - **Strict Policy:** All production environments and CI/CD pipelines (even for development environments) MUST utilize IAM + SigV4 or OIDC-based authentication. A clear migration path from API keys to IAM/OIDC will be established as part of Phase 2.

            - If used, API keys must have a clear owner, an expiration date, and be stored securely in AWS Secrets Manager.

### 6.2 Authorization: Role-Based Access Control (RBAC)

Once a user or service is authenticated, the registry will authorize actions based on pre-defined roles. While the initial plan defined roles at the endpoint level, a production-grade system requires more granular, resource-level authorization.

  - **Roles:**

    1.  **Reader:** Can perform read-only operations (`GET` endpoints for discovery and search). This role is intended for agent consumers (applications, other agents).
    2.  **Publisher:** Has `Reader` permissions plus the ability to create and update agent registrations (`POST`).
    3.  **Admin:** Has full permissions, including the ability to manage API keys and perform administrative actions.

  - **Resource-Level Authorization:**
    -   A key improvement is to enforce ownership-based permissions. A `Publisher` should only be able to publish or update agents they own. The `owner` field in the `agent.json` manifest will be used to enforce this.
    -   Admin actions, such as deleting an agent version or modifying a user's role, must be fully audited.

  - **Enforcement:** This will be implemented as a middleware within the API service. The middleware will inspect the user's identity and roles, and then verify them against the requested action and the resource being accessed.

  - **Immutability Rules:**
    -   To ensure auditability and prevent accidental overwrites, the registry will enforce version immutability.
    -   It will be forbidden to `POST` an agent with the same `name` and `version` as an existing agent.
    -   To update an agent, a new version must be published. This forces a clear version history and simplifies rollbacks.

### 6.3 Secrets Management

A robust secrets management strategy is critical to the security of the registry. The following principles will be applied:

-   **Secrets Storage:** All secrets, including API keys, database credentials, and any other sensitive information, will be stored in **AWS Secrets Manager**.
-   **No Hardcoded Secrets:** Secrets will never be hardcoded in the application code, configuration files, or environment variables.
-   **IAM Integration:** The application will be granted IAM permissions to retrieve secrets from Secrets Manager at runtime. This avoids the need to manage secrets within the application itself.
-   **Database Credentials:** If IAM authentication is used for the database, no credentials need to be managed. If username/password authentication is used, the credentials will be stored in Secrets Manager and rotated regularly.

### 6.4 Multi-Environment Support

    The plan mandates a **"One Registry per Environment"** strategy (as detailed in Section 4.3). This means each environment (`dev`, `stage`, `prod`) will have its own entirely separate and independent registry instance.

      - **Mechanism:** The `environment` field in the `agent.json` manifest will be used as metadata within its dedicated registry instance to denote the agent's target environment (e.g., an agent deployed to the `prod` AWS account would have `"environment": "prod"` in its manifest, and would be published only to the `mcp-registry-prod` instance).
      - **Access Strategy:** Clients (agent consumers) must be configured to interact with the correct environment-specific registry endpoint. For example, a service running in the `prod` AWS account will query `mcp-registry-prod` exclusively. This physically isolates environments, simplifying security and preventing cross-environment data contamination.
### 6.5 Network Security

The registry will be deployed with a defense-in-depth network security strategy.

  - **VPC:** The entire registry service (API, database) will be deployed within a secure Virtual Private Cloud (VPC).
  - **Private ALB:** The API will be fronted by a private Application Load Balancer (ALB), ensuring that it is not directly exposed to the public internet.
  - **Security Groups:** Security groups will be used to enforce the principle of least privilege. For example, the ALB security group will only allow inbound traffic on the required port from specific sources, and the Fargate service security group will only allow inbound traffic from the ALB.
  - **NACLs:** Network Access Control Lists (NACLs) will be used as a stateless firewall to provide an additional layer of security at the subnet level.
  - **WAF:** If public access is ever required, AWS WAF will be used to protect the API from common web exploits.
  - **Access:** By default, the registry API endpoint will only be accessible from within the VPC. If access from outside the VPC is required (e.g., for developers), it will be managed through a secure API Gateway with appropriate controls.

## 7. Tooling and Dependencies

This section summarizes the recommended technologies and tools required to build, deploy, and maintain the MCP Registry, focusing on an AWS-native implementation.

### 7.1 Core Application

  - **Programming Language:** Python (3.11+)
  - **API Framework:** FastAPI
  - **Data Validation:** Pydantic (included with FastAPI)
  - **Database Interaction:** SQLAlchemy (with `asyncpg` for asynchronous support)
  - **Web Server:** Uvicorn

### 7.2 Database

  - **System:** PostgreSQL (15+)
  - **Recommended Hosting:** AWS RDS for PostgreSQL

### 7.3 Infrastructure and Deployment

  - **Containerization:** Docker
  - **Container Registry:** AWS Elastic Container Registry (ECR)
  - **Compute Hosting:** AWS Fargate
  - **CI/CD Pipeline:** GitHub Actions or GitLab CI

### 7.4 Developer Experience

  - **Registry CLI:** A critical support tool will be a dedicated CLI to streamline interaction with the registry.
    - **Technology:** **Typer** or **Click** (Python).
    - **Features:**
      - `mcp-cli validate`: Validates the structure and schema of a local `agent.json` file.
      - `mcp-cli publish`: Publishes an `agent.json` file to the registry. Reads API key from an environment variable.
      - `mcp-cli search <query>`: A command-line interface for searching the registry.
  - **Code Quality:**
    - **Linter:** Ruff
    - **Formatter:** Black
    - **Testing Framework:** Pytest

## 8. CI/CD & Supply Chain Security

A secure and reliable CI/CD pipeline is critical for both the registry itself and the agents that are published to it.

### 8.1 Registry Deployment Pipeline

The pipeline that builds and deploys the MCP Registry will include the following security gates:

-   **SAST (Static Application Security Testing):** Tools like `Bandit` and `Semgrep` will be used to scan the Python code for security vulnerabilities.
-   **Dependency Scanning:** The pipeline will scan all third-party dependencies for known vulnerabilities.
-   **Container Image Scanning:** The Docker image will be scanned for vulnerabilities using tools like `Trivy` or `Grype`.
-   **Signed Images:** All container images will be signed using `cosign` to ensure their integrity and authenticity.

### 8.2 Agent Publishing Pipeline

The pipeline that publishes new agents to the registry is a critical control point. To prevent the publishing of malicious or non-compliant agents, the following controls will be implemented:

-   **Schema Validation:** The pipeline will validate the `agent.json` manifest against a strict schema.
-   **Version Immutability:** The pipeline will enforce the version immutability rule, failing any attempt to overwrite an existing version.
-   **Approval Gates for Production:** Any deployment to the `prod` registry will require a manual approval step from a designated approver.
-   **OIDC-Based Identity:** The CI/CD pipeline will use an OIDC-based identity to authenticate with the registry, eliminating the need for static API keys.

## 9. Observability & Operations

A comprehensive observability strategy is essential for maintaining the health and performance of the MCP Registry.

### 9.1 Metrics

The following key metrics will be collected and monitored:

-   **Request Count:** The number of requests to each API endpoint.
-   **Error Rate:** The percentage of requests that result in an error.
-   **Publish Frequency:** The number of new agents published over time.
-   **Search Latency:** The latency of the search API.

### 9.2 Logs

-   **Structured JSON Logs:** All logs will be in a structured JSON format to facilitate searching and analysis.
-   **Key Events:** The application will log key events, including:
    -   Agent publish/delete events
    -   Authentication failures
    -   Authorization failures

### 9.3 Tracing

-   **OpenTelemetry Support:** The application will include optional support for OpenTelemetry to enable distributed tracing.

### 9.4 Alerting

Alerts will be configured for the following conditions:

-   **Registry Unavailable:** The registry is not responding to requests.
-   **DB Connectivity Failure:** The application cannot connect to the database.
-   **Unauthorized Publish Attempts:** A user or service attempts to publish an agent without the required permissions.

## 10. Data Governance & Compliance

A clear data governance and compliance strategy is essential for ensuring the integrity and auditability of the MCP Registry.

### 10.1 Audit Log

-   **Audit Log Table:** A dedicated audit log table will be created in the database to record all significant events, including:
    -   Who published an agent
    -   When the agent was published
    -   The source IP address of the publish request
    -   What changed in the agent manifest
-   **Read-Only Historical View:** A read-only view of the audit log will be provided for compliance and debugging purposes.

### 10.2 Data Retention

-   **Retention Policy:** A retention policy will be enforced for soft-deleted agents. After a defined period, soft-deleted agents will be hard-deleted from the database.
-   **Legal Holds:** The system will provide a mechanism to place a legal hold on an agent, preventing it from being hard-deleted.

## 11. MCP-Specific Design Considerations

### 11.1 Registry Semantics

The registry's primary responsibility is discovery, not model hosting. The following enhancements will be made to the registry's semantics:

-   **Capability-Based Search:** In addition to free-text search, the registry will support capability-based search. This will allow clients to search for agents that support a specific tool or function, as defined in their OpenAPI spec.
-   **Deprecation Metadata:** The `agent.json` manifest will be extended to include deprecation metadata, such as `deprecated: true` and `sunset_date`. This will allow clients to gracefully migrate away from deprecated agents.
-   **Health Metadata:** The registry will optionally store health metadata for each agent, such as the last time the agent was seen alive. This will allow clients to avoid routing requests to unhealthy agents.

## 12. Implementation Roadmap

This roadmap outlines a phased approach to delivering the MCP Registry.

### Phase 1: Core MVP (2-3 Sprints)

  - **Goal:** A functional, deployed registry service for a single environment.
  - **Tasks:**
    - Set up the core FastAPI application structure.
    - Implement the data model in PostgreSQL.
    - Develop API endpoints for `POST /agents` and `GET /agents/{name}/{version}`.
    - Implement API Key authentication (`Reader` and `Publisher` roles).
    - Set up the initial CI/CD pipeline to deploy the service as a container on AWS Fargate.
    - Onboard 1-2 pilot AI agent teams.

### Phase 2: CLI and Search (1-2 Sprints)

  - **Goal:** Improve developer experience and discoverability.
  - **Tasks:**
    - Develop the `mcp-cli` tool with `validate` and `publish` commands.
    - Integrate the `publish` command into the CI/CD pipelines of the pilot agent teams.
    - Implement the remaining `GET` endpoints (`/agents`, `/agents/{name}`).
    - Implement the `GET /search` endpoint with full-text search on key metadata fields.

### Phase 3: Hardening and Rollout (Ongoing)

  - **Goal:** Prepare for full production use and wider adoption.
  - **Tasks:**
    - Implement soft-delete (`DELETE`) functionality.
    - Add the `Admin` role and a secure mechanism for managing API keys.
    - Enhance monitoring, logging, and alerting for the registry service.
    - Create comprehensive user documentation for both the API and the CLI.
    - Onboard all ZSoftly AI agent teams.
