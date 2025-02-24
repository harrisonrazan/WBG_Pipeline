import logging
from app.database import wait_for_db_and_tables, engine
from app.config import REQUIRED_TABLES
from app.utils.generate_models import generate_models

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def initialize_application():
    """Initialize the application by waiting for database and generating models"""
    try:
        logger.info("Starting application initialization...")
        
        # Wait for database tables
        logger.info("Waiting for required database tables...")
        wait_for_db_and_tables(engine, list(REQUIRED_TABLES.keys()))
        logger.info("All required tables are present")
        
        # Generate SQLAlchemy models
        logger.info("Generating SQLAlchemy models...")
        generate_models()
        logger.info("Successfully generated models")
        
        logger.info("Application initialization completed successfully")
        return True
        
    except Exception as e:
        logger.error(f"Failed to initialize application: {str(e)}")
        raise

if __name__ == "__main__":
    initialize_application()