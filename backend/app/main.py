import logging
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from .database import get_db
from .models import (
    WbProjects, WbProjectSectors, WbProjectThemes,
    WbContractAwards, WbCreditStatements,
    WbProjectFinancers, WbProjectGeoLocations
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create a single FastAPI instance with metadata
app = FastAPI(
    title="World Bank Projects API",
    description="API for accessing World Bank project data",
    version="1.0.0"
)

@app.on_event("startup")
async def startup_event():
    """Log when the application starts up"""
    logger.info("Starting up FastAPI application...")

@app.on_event("shutdown")
async def shutdown_event():
    """Log when the application shuts down"""
    logger.info("Shutting down FastAPI application...")

@app.get("/projects/")
def get_projects(db: Session = Depends(get_db)):
    """Get all World Bank projects"""
    try:
        return db.query(WbProjects).all()
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_projects: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")

@app.get("/sectors/")
def get_sectors(db: Session = Depends(get_db)):
    """Get all project sectors"""
    try:
        return db.query(WbProjectSectors).all()
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_sectors: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")

@app.get("/themes/")
def get_themes(db: Session = Depends(get_db)):
    """Get all project themes"""
    try:
        return db.query(WbProjectThemes).all()
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_themes: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")

@app.get("/contract_awards/")
def get_contract_awards(db: Session = Depends(get_db)):
    """Get all contract awards"""
    try:
        return db.query(WbContractAwards).all()
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_contract_awards: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")

@app.get("/credit_statements/")
def get_credit_statements(db: Session = Depends(get_db)):
    """Get all credit statements"""
    try:
        return db.query(WbCreditStatements).all()
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_credit_statements: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")

@app.get("/financers/")
def get_financers(db: Session = Depends(get_db)):
    """Get all project financers"""
    try:
        return db.query(WbProjectFinancers).all()
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_financers: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")

@app.get("/geo_locations/")
def get_geo_locations(db: Session = Depends(get_db)):
    """Get all project geographical locations"""
    try:
        return db.query(WbProjectGeoLocations).all()
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_geo_locations: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error occurred")

@app.get("/health")
def health_check():
    """Basic health check endpoint"""
    try:
        return {"status": "healthy", "message": "API is running normally"}
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Health check failed")