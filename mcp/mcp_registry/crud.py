from sqlalchemy.orm import Session
from . import models, schemas

def get_agent(db: Session, agent_id: int):
    return db.query(models.Agent).filter(models.Agent.id == agent_id).first()

def get_agents(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Agent).offset(skip).limit(limit).all()

def create_agent(db: Session, agent: schemas.AgentCreate):
    db_agent = models.Agent(
        name=agent.name,
        version=agent.version,
        display_name=agent.display_name,
        description=agent.description,
        owner=agent.owner,
        endpoint=agent.endpoint,
        openapi_spec=agent.openapi_spec,
        environment=agent.environment,
        tags=agent.tags,
        openapi_spec_s3_uri=agent.openapi_spec_s3_uri,
        openapi_spec_checksum=agent.openapi_spec_checksum
    )
    for capability_data in agent.capabilities:
        capability = get_capability_by_name(db, name=capability_data.name)
        if not capability:
            capability = create_capability(db, capability_data)
        db_agent.capabilities.append(capability)

    db.add(db_agent)
    db.commit()
    db.refresh(db_agent)
    return db_agent

def get_capability(db: Session, capability_id: int):
    return db.query(models.Capability).filter(models.Capability.id == capability_id).first()

def get_capability_by_name(db: Session, name: str):
    return db.query(models.Capability).filter(models.Capability.name == name).first()

def get_capabilities(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Capability).offset(skip).limit(limit).all()

def create_capability(db: Session, capability: schemas.CapabilityCreate):
    db_capability = models.Capability(**capability.dict())
    db.add(db_capability)
    db.commit()
    db.refresh(db_capability)
    return db_capability

def get_agents_by_capability(db: Session, capability_name: str):
    return db.query(models.Agent).join(models.Agent.capabilities).filter(models.Capability.name == capability_name).all()
