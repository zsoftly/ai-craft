# main.py

from typing import List
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session

from . import crud, models, schemas
from .database import SessionLocal, engine, create_db_and_tables

models.Base.metadata.create_all(bind=engine)

app = FastAPI()


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.on_event("startup")
def on_startup():
    create_db_and_tables()


@app.post("/agents/", response_model=schemas.Agent)
def create_agent(agent: schemas.AgentCreate, db: Session = Depends(get_db)):
    return crud.create_agent(db=db, agent=agent)


@app.get("/agents/", response_model=List[schemas.Agent])
def read_agents(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    agents = crud.get_agents(db, skip=skip, limit=limit)
    return agents


@app.get("/search/", response_model=List[schemas.Agent])
def search_agents_by_capability(capability_name: str, db: Session = Depends(get_db)):
    return crud.get_agents_by_capability(db=db, capability_name=capability_name)


@app.post("/capabilities/", response_model=schemas.Capability)
def create_capability(
    capability: schemas.CapabilityCreate, db: Session = Depends(get_db)
):
    return crud.create_capability(db=db, capability=capability)


@app.get("/")
async def root():
    return {"message": "Hello MCP Registry!"}
