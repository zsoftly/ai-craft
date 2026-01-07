from typing import List, Optional
from pydantic import BaseModel

class CapabilityBase(BaseModel):
    name: str
    description: Optional[str] = None

class CapabilityCreate(CapabilityBase):
    pass

class Capability(CapabilityBase):
    id: int
    agents: List["Agent"] = []

    class Config:
        orm_mode = True

class AgentBase(BaseModel):
    name: str
    version: str
    display_name: Optional[str] = None
    description: str
    owner: str
    endpoint: str
    openapi_spec: dict
    environment: str
    tags: Optional[List[str]] = None
    openapi_spec_s3_uri: Optional[str] = None
    openapi_spec_checksum: Optional[str] = None

class AgentCreate(AgentBase):
    capabilities: List[CapabilityCreate] = []

class Agent(AgentBase):
    id: int
    capabilities: List[Capability] = []

    class Config:
        orm_mode = True

Capability.update_forward_refs()
Agent.update_forward_refs()
