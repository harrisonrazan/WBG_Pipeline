import logging
from fastapi import FastAPI, Depends, HTTPException, Body
from sqlalchemy import text
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from .database import get_db
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pathlib import Path
from .models import (
    WbProjects, WbProjectSectors, WbProjectThemes,
    WbContractAwards, WbCreditStatements,
    WbProjectFinancers, WbProjectGeoLocations
)

class QueryRequest(BaseModel):
    query_path: str

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

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:80"],  # Add frontend URLs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
    
@app.get("/query/{query_path:path}")
async def execute_query(query_path: str, db: Session = Depends(get_db)):
    """Execute a SQL query from the queries directory and return results."""
    try:
        query_service = SQLQueryService()
        results = query_service.execute_query(db, query_path)
        return results
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Error executing query {query_path}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# Add these new endpoints
@app.get("/available_queries")
async def list_queries():
    """List all available query files"""
    try:
        queries_dir = Path("/app/queries")  # Adjust if your path is different
        query_files = []
        
        # Recursively find all .sql files
        for sql_file in queries_dir.rglob("*.sql"):
            relative_path = str(sql_file.relative_to(queries_dir))
            query_files.append(relative_path)
            
        return {
            "queries": sorted(query_files)
        }
        
    except Exception as e:
        logger.error(f"Error listing queries: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/execute_query")
async def execute_query(
    request: QueryRequest,  # Changed from query_path: str = Body(...)
    db: Session = Depends(get_db)
):
    """Execute a SQL query from file and return the results"""
    try:
        # Construct full path to query file
        queries_dir = Path("/app/queries")
        query_file = queries_dir / request.query_path  # Use request.query_path here

        # Add debug logging
        logger.info(f"Attempting to execute query from file: {query_file}")

        # Validate file exists and is within queries directory
        if not query_file.exists():
            logger.error(f"Query file not found: {query_file}")
            raise HTTPException(status_code=404, detail=f"Query file not found: {request.query_path}")
        if not str(query_file.resolve()).startswith(str(queries_dir.resolve())):
            logger.error(f"Invalid query path: {query_file}")
            raise HTTPException(status_code=403, detail="Invalid query path")

        # Read and execute query
        with open(query_file, 'r') as f:
            query_text = f.read()
            logger.info(f"Executing query: {query_text[:100]}...")  # Log first 100 chars of query
            query = text(query_text)
            
        result = db.execute(query)
        
        # Convert to list of dicts for JSON response
        columns = result.keys()
        rows = [dict(zip(columns, row)) for row in result.fetchall()]
        
        logger.info(f"Query executed successfully. Returning {len(rows)} rows")
        
        return {
            "columns": list(columns),
            "rows": rows,
            "total_rows": len(rows)
        }
        
    except Exception as e:
        logger.error(f"Error executing query: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))