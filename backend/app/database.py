import time
from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError, SQLAlchemyError
import logging
import os

logger = logging.getLogger(__name__)

def wait_for_db_and_tables(engine, required_tables, max_retries=30, retry_interval=10):
    """
    Waits for the database to be ready and contain the required tables.
    """
    inspector = inspect(engine)
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            # Check if we can connect to the database
            with engine.connect() as conn:
                # Get existing tables
                existing_tables = inspector.get_table_names()
                missing_tables = set(required_tables) - set(existing_tables)
                
                if not missing_tables:
                    logger.info("All required tables are present!")
                    return True
                    
                logger.warning(f"Missing tables: {missing_tables}. Retrying in {retry_interval} seconds...")
                
        except OperationalError as e:
            logger.warning(f"Database not ready: {str(e)}. Retrying in {retry_interval} seconds...")
        except SQLAlchemyError as e:
            logger.error(f"SQLAlchemy error: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error: {str(e)}")
            raise
        
        time.sleep(retry_interval)
        retry_count += 1
    
    missing_tables = set(required_tables) - set(inspector.get_table_names())
    raise RuntimeError(f"Database tables not ready after {max_retries} retries. Missing tables: {missing_tables}")

# Create the database engine with more detailed logging
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is not set")

engine = create_engine(
    DATABASE_URL,
    echo=True,  # Enable SQL logging
    pool_pre_ping=True  # Enable connection health checks
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """Dependency for getting database sessions"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()