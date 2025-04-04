import logging
from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.exc import OperationalError

from .settings import get_settings
from .exceptions import DatabaseError,ConfigurationError

# Configure logging
logger = logging.getLogger(__name__)

def init_db() -> sessionmaker:
    """
    Initialize the database engine and session factory.

    Returns:
        sessionmaker: Configured SQLAlchemy session factory.

    Raises:
        ConfigurationError: If settings cannot be loaded.
        DatabaseError: If database engine cannot be created.
    """
    logger.info("Initializing database...")
    try:
        settings = get_settings()
        logger.info("Database settings loaded successfully.")
    except ConfigurationError as e:
        logger.error(f"Failed to load settings: {str(e)}")
        raise

    try:
        # Use keyword arguments to avoid embedding credentials in the URL
        engine = create_engine(
            "oracle+oracledb://",
            connect_args={
                "user": settings.ORCLDB_USER,
                "password": settings.ORCLDB_PWD,
                "host": settings.ORCLDB_HOST,
                "port": settings.ORCLDB_PORT,
                "service_name": settings.ORCLDB_SERVICE,
            },
            echo=False  # Set to True for debugging SQL queries
        )
        logger.info("Database engine created successfully.")
        return sessionmaker(autocommit=False, autoflush=False, bind=engine)
    except Exception as e:
        logger.error(f"Failed to create database engine: {str(e)}")
        raise DatabaseError(f"Database initialization failed: {str(e)}")


# Lazy initialization of SessionLocal
try:
    SessionLocal = init_db()
except (ConfigurationError, DatabaseError) as e:
    logger.critical(f"Application startup failed: {str(e)}")
    raise


def get_db() -> Generator[Session, None, None]:
    """
    Provide a database session for FastAPI dependency injection.

    Yields:
        Session: SQLAlchemy session object.

    Raises:
        DatabaseError: If session creation or usage fails.
    """
    db = SessionLocal()
    try:
        yield db
    except OperationalError as e:
        logger.error(f"Database operation failed: {str(e)}")
        raise DatabaseError(f"Database connection error: {str(e)}")
    finally:
        db.close()
        logger.debug("Database session closed.")

