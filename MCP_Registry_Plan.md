# ZSoftly MCP Registry - Technical Plan

## 1. Executive Summary

This document outlines a technical plan for building a **ZSoftly Model Context Protocol (MCP) Registry**. The goal is to create a private, internal registry to host and manage ZSoftly's proprietary AI Agents and Tools. This registry will function as a central discovery mechanism, allowing applications and other AI agents to dynamically find, understand, and connect to the capabilities offered by registered agents.

The proposed solution is a lightweight, secure, and cloud-native RESTful service that manages metadata for our AI agents. This plan covers the core concepts, proposed architecture, agent lifecycle management, security considerations, and deployment strategy. It is intended to be a roadmap for an engineering team to implement the registry.

## 2. MCP Registry Concept Explained

An MCP Registry is **not** a hosting platform for AI models. Instead, it is a **discovery service** or a **catalog**. Its primary purpose is to answer the question: "What AI capabilities are available, and how do I use them?"

It works by storing metadata about "MCP Servers" (in our case, ZSoftly AI Agents). Each agent is described by a manifest file (e.g., `agent.json`) which contains:

-   **Identity:** Name, version, owner, description.
-   **Contract:** An OpenAPI (or similar) specification that defines the agent's capabilities as a set of callable tools or functions.
-   **Location:** The network endpoint (URL) where the agent can be reached.

Client applications query the registry to find agents that meet their needs (e.g., "find an agent that can summarize text"). The registry returns the manifest of the matching agent(s), and the client then uses that information to communicate directly with the agent.

For ZSoftly, a private MCP registry provides a secure, centralized way to manage our growing ecosystem of internal AI agents, promoting reuse, standardization, and governance.

## 3. Agent Lifecycle Management

The lifecycle of a ZSoftly AI Agent within the registry involves three key stages: **Registration**, **Discovery**, and **Versioning**. This process is managed via a RESTful API and a standardized manifest file.

### 3.1 The `agent.json` Manifest

This file is the source of truth for an agent's metadata. Each agent project MUST include an `agent.json` file at its root.

**Fields:**

-   `name` (string, required): A unique, machine-readable name for the agent (e.g., `document-summarizer`, `user-profile-service`).
-   `version` (string, required): The semantic version of the agent (e.g., `1.0.0`).
-   `displayName` (string, optional): A human-readable name for display in UIs.
-   `description` (string, required): A clear, concise summary of the agent's purpose and capabilities.
-   `owner` (string, required): The ZSoftly team or individual responsible for the agent (e.g., `team-alpha`, `user@zsoftly.com`).
-   `endpoint` (string, required): The base URL where the agent's service can be accessed.
-   `openapi` (object, required): A valid OpenAPI 3.x specification object describing the agent's available `paths` and `components`. This is the contract for using the agent.
-   `environment` (enum, required): The environment this agent is deployed to. (`dev`, `stage`, or `prod`). This is critical for multi-environment support.
-   `tags` (array of strings, optional): Keywords to improve discoverability (e.g., `["nlp", "text", "summary"]`).

### 3.2 Registry API Endpoints

The registry will expose the following core endpoints:

**Agent Registration**

-   `POST /agents`
    -   **Action:** Publishes or updates an agent. The request body will be the `agent.json` manifest.
    -   **Logic:** The registry validates the manifest against a schema. If an agent with the same `name` and `version` already exists, it is updated. Otherwise, a new version is created. The `name` and `version` from the manifest are used as the unique identifier.
    -   **Auth:** Requires a publisher role.

**Agent Discovery**

-   `GET /agents`
    -   **Action:** Returns a paginated list of all registered agents (latest version of each).
    -   **Auth:** Requires a reader role.

-   `GET /agents/{name}`
    -   **Action:** Returns a list of all available versions for a specific agent.
    -   **Auth:** Requires a reader role.

-   `GET /agents/{name}/{version}`
    -   **Action:** Returns the specific `agent.json` for the given name and version (e.g., `/agents/document-summarizer/1.2.0`). Use `latest` as the version to get the most recently published version.
    -   **Auth:** Requires a reader role.

**Agent Search**

-   `GET /search?q={query}`
    -   **Action:** Searches for agents. The query will match against `name`, `displayName`, `description`, and `tags`.
    -   **Example:** `/search?q=summarize`
    -   **Auth:** Requires a reader role.

**Agent Deletion**

-   `DELETE /agents/{name}/{version}`
    -   **Action:** Deletes a specific version of an agent. This is a soft-delete to prevent breaking dependencies. A hard-delete mechanism can be decided on later.
    -   **Auth:** Requires a publisher/admin role.

### 3.3 Versioning Strategy

-   The registry will use **Semantic Versioning (SemVer)** as specified in the `agent.json` (`major.minor.patch`).
-   A combination of `name` and `version` uniquely identifies an agent manifest.
-   Clients should be encouraged to request a specific major version (e.g., `1.x`) or use the `latest` tag with caution in development environments. The registry can resolve `1.x` to the latest non-breaking version.
-   The `latest` tag will always point to the most recently published version, regardless of whether it's a breaking change.

## 4. Proposed Architecture

The MCP Registry will be a simple, robust, and scalable system composed of three core components. The architecture prioritizes statelessness and cloud-native principles.

![Architecture Diagram](https://i.imgur.com/gY1xL5E.png)

### 4.1 System Components

1.  **REST API (Registry Service):**
    -   **Description:** The heart of the system, this service exposes all the endpoints defined in the "Agent Lifecycle Management" section. It handles incoming requests, authentication, and communication with the database.
    -   **Technology:** A stateless web application.
    -   **Recommendation:** **FastAPI (Python)**. Its native support for Pydantic models makes validation of incoming `agent.json` manifests trivial. Its automatic generation of OpenAPI documentation is also a significant benefit.

2.  **Database:**
    -   **Description:** A persistent storage layer for all agent manifests and their versions. It needs to support structured data, indexing for fast lookups, and full-text search capabilities for the `GET /search` endpoint.
    -   **Recommendation:** **PostgreSQL**. Its robustness, support for JSONB data types, and powerful indexing features make it a perfect fit. Using a managed cloud service (like AWS RDS) is highly recommended.

3.  **Validation Logic:**
    -   **Description:** Before any data is written to the database, incoming `agent.json` manifests must be validated. This includes checking for required fields, correct data types, and ensuring the embedded OpenAPI contract is syntactically valid.
    -   **Implementation:** This logic will be implemented directly within the REST API service, leveraging the data validation features of the chosen framework (e.g., Pydantic models in FastAPI).

### 4.2 Data Model

A primary `agents` table will store the core metadata.

-   `id` (PK)
-   `name` (Indexed)
-   `version` (Indexed)
-   `display_name`
-   `description`
-   `owner`
-   `endpoint`
-   `environment` (Indexed)
-   `tags` (Indexed, using GIN index on a JSONB field)
-   `openapi_spec` (JSONB)
-   `created_at`
-   `is_deleted` (for soft deletes)

A unique constraint will be placed on `(name, version)` to enforce uniqueness.

## 5. Hosting and Deployment

Our hosting strategy should be cloud-first, prioritizing managed services to reduce operational overhead.

### 5.1 Primary Recommendation: Serverless Containers

This approach offers the best balance of performance, scalability, and ease of management.

-   **Compute:** **AWS Fargate**.
    -   The FastAPI application will be packaged into a **Docker container**.
    -   These platforms automatically manage scaling (including scaling to zero), patching, and server infrastructure.
-   **Database:** **AWS RDS for PostgreSQL**.
    -   A managed database service handles backups, failover, and maintenance.
-   **CI/CD:** The process of publishing the registry itself (and agents to it) should be automated. A GitHub Actions or GitLab CI pipeline would build the Docker image, push it to a container registry (e.g., ECR), and trigger a deployment in Fargate.

### 5.2 Alternative: Serverless Functions

For potentially lower-traffic scenarios or as a cost-saving measure, a purely serverless function architecture could be used.

-   **Compute:** **AWS Lambda**.
    -   Each API endpoint or a group of related endpoints would be a separate function.
-   **Gateway:** **Amazon API Gateway** would be used to manage the public-facing API routes and trigger the appropriate functions.
-   **Database:** **AWS Aurora Serverless** or **DynamoDB**.

**Conclusion:** The **Serverless Container** approach is the recommended path as it offers a more cohesive development experience and simpler application structure compared to managing numerous individual functions.

## 6. Security and Access Control

Security is a critical component of the registry, ensuring that only authorized users and services can publish or access agent information.

### 6.1 Authentication: API Keys

All requests to the registry API must be authenticated. The proposed method is via **API Keys**.

-   **Mechanism:** Clients will pass their key in the `Authorization: Bearer <API_KEY>` HTTP header.
-   **Management:**
    -   API keys will be generated and associated with a specific role (`Reader`, `Publisher`, or `Admin`).
    -   Keys will be stored securely in the database using a strong hashing algorithm (e.g., SHA-256). They will not be retrievable in plaintext.
    -   An internal administrative interface or CLI command will be created for managing keys.

### 6.2 Authorization: Role-Based Access Control (RBAC)

Once authenticated, the registry will authorize actions based on pre-defined roles.

-   **Roles:**
    1.  **Reader:** Can perform read-only operations (`GET` endpoints for discovery and search). This role is intended for agent consumers (applications, other agents).
    2.  **Publisher:** Has `Reader` permissions plus the ability to create, update, and delete agent registrations (`POST`, `DELETE`). This role is intended for developers and CI/CD pipelines responsible for publishing agents.
    3.  **Admin:** Has full permissions, including the ability to manage API keys.

-   **Enforcement:** This will be implemented as a middleware within the API service. The middleware will inspect the role associated with the authenticated API key and verify it against the required role for the requested endpoint.

### 6.3 Multi-Environment Support

The registry will support multiple environments (`dev`, `stage`, `prod`) within a single deployed instance.

-   **Mechanism:** The `environment` field in the `agent.json` manifest is the primary mechanism for distinguishing agents.
-   **Access Strategy:**
    -   Discovery endpoints (`/agents`, `/search`) will be enhanced with an optional `environment` query parameter (e.g., `GET /agents?environment=prod`).
    -   Clients (agent consumers) are responsible for requesting the correct environment. For example, a service running in production should be configured to only fetch agents from the `prod` environment.
    -   This approach provides flexibility. A future enhancement could be to create environment-specific API keys (e.g., `prod-reader`) to enforce stricter isolation if needed.

### 6.4 Network Security

-   **VPC:** The entire registry service (API, database) should be deployed within a secure Virtual Private Cloud (VPC).
-   **Access:** By default, the registry API endpoint should only be accessible from within the VPC. If access from outside the VPC is required (e.g., for developers), it should be managed through a secure API Gateway with appropriate controls.

## 7. Tooling and Dependencies

This section summarizes the recommended technologies and tools required to build, deploy, and maintain the MCP Registry, focusing on an AWS-native implementation.

### 7.1 Core Application

-   **Programming Language:** Python (3.11+)
-   **API Framework:** FastAPI
-   **Data Validation:** Pydantic (included with FastAPI)
-   **Database Interaction:** SQLAlchemy (with `asyncpg` for asynchronous support)
-   **Web Server:** Uvicorn

### 7.2 Database

-   **System:** PostgreSQL (15+)
-   **Recommended Hosting:** AWS RDS for PostgreSQL

### 7.3 Infrastructure and Deployment

-   **Containerization:** Docker
-   **Container Registry:** AWS Elastic Container Registry (ECR)
-   **Compute Hosting:** AWS Fargate
-   **CI/CD Pipeline:** GitHub Actions or GitLab CI

### 7.4 Developer Experience

-   **Registry CLI:** A critical support tool will be a dedicated CLI to streamline interaction with the registry.
    -   **Technology:** **Typer** or **Click** (Python).
    -   **Features:**
        -   `mcp-cli validate`: Validates the structure and schema of a local `agent.json` file.
        -   `mcp-cli publish`: Publishes an `agent.json` file to the registry. Reads API key from an environment variable.
        -   `mcp-cli search <query>`: A command-line interface for searching the registry.
-   **Code Quality:**
    -   **Linter:** Ruff
    -   **Formatter:** Black
    -   **Testing Framework:** Pytest

## 8. Implementation Roadmap

This roadmap outlines a phased approach to delivering the MCP Registry.

### Phase 1: Core MVP (2-3 Sprints)

-   **Goal:** A functional, deployed registry service for a single environment.
-   **Tasks:**
    -   Set up the core FastAPI application structure.
    -   Implement the data model in PostgreSQL.
    -   Develop API endpoints for `POST /agents` and `GET /agents/{name}/{version}`.
    -   Implement API Key authentication (`Reader` and `Publisher` roles).
    -   Set up the initial CI/CD pipeline to deploy the service as a container on AWS Fargate.
    -   Onboard 1-2 pilot AI agent teams.

### Phase 2: CLI and Search (1-2 Sprints)

-   **Goal:** Improve developer experience and discoverability.
-   **Tasks:**
    -   Develop the `mcp-cli` tool with `validate` and `publish` commands.
    -   Integrate the `publish` command into the CI/CD pipelines of the pilot agent teams.
    -   Implement the remaining `GET` endpoints (`/agents`, `/agents/{name}`).
    -   Implement the `GET /search` endpoint with full-text search on key metadata fields.

### Phase 3: Hardening and Rollout (Ongoing)

-   **Goal:** Prepare for full production use and wider adoption.
-   **Tasks:**
    -   Implement soft-delete (`DELETE`) functionality.
    -   Add the `Admin` role and a secure mechanism for managing API keys.
    -   Enhance monitoring, logging, and alerting for the registry service.
    -   Create comprehensive user documentation for both the API and the CLI.
    -   Onboard all ZSoftly AI agent teams.
