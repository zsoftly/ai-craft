import os
from dotenv import load_dotenv

from sqlalchemy import create_engine, Column, String, Text, Boolean, DateTime, ARRAY, Integer, UniqueConstraint, Table, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime

load_dotenv() # Load environment variables from .env file

# Database connection string from environment variable
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/mcp_registry")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

agent_capability_association = Table(
    'agent_capability_association',
    Base.metadata,
    Column('agent_id', Integer, ForeignKey('agents.id')),
    Column('capability_id', Integer, ForeignKey('capabilities.id'))
)

class Agent(Base):
    __tablename__ = "agents"

    id = Column(Integer, primary_key=True, index=True) # Auto-incrementing primary key
    name = Column(String, index=True, nullable=False)
    version = Column(String, index=True, nullable=False)
    display_name = Column(String, nullable=True)
    description = Column(Text, nullable=False)
    owner = Column(String, nullable=False)
    endpoint = Column(String, nullable=False)
    openapi_spec = Column(JSONB, nullable=False) # Storing full OpenAPI spec as JSONB for now
    environment = Column(String, index=True, nullable=False)
    tags = Column(ARRAY(String), nullable=True)
    openapi_spec_s3_uri = Column(String, nullable=True)
    openapi_spec_checksum = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_deleted = Column(Boolean, default=False)

    capabilities = relationship(
        "Capability",
        secondary=agent_capability_association,
        back_populates="agents"
    )

    # Unique constraint on name and version
    __table_args__ = (
        UniqueConstraint('name', 'version', name='_name_version_uc'),
    )

    def __repr__(self):
        return f"<Agent(name='{self.name}', version='{self.version}', environment='{self.environment}')>"

class Capability(Base):
    __tablename__ = 'capabilities'

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    description = Column(Text)

    agents = relationship(
        "Agent",
        secondary=agent_capability_association,
        back_populates="capabilities"
    )

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_db_and_tables():
    Base.metadata.create_all(bind=engine)
