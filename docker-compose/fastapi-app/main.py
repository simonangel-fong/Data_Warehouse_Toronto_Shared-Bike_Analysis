import logging
from typing import List
from fastapi import FastAPI, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

# from .config.logging_file import configure_logging_from_env
from config.database import get_db
from config.exceptions import DatabaseError
from models.MVUserSegmentation import MVUserSegmentation, UserSegmentationResponse

# Configure logging at startup
# configure_logging_from_env()

app = FastAPI(title="Toronto_Shared_Bike")

logger = logging.getLogger(__name__)

logger.info("Application starting up...")


@app.get(
    "/user-segmentation/",
    response_model=List[UserSegmentationResponse],
    tags=["User Segmentation"],
    summary="Retrieve user segmentation data",
)
def get_user_segmentation(
    db: Session = Depends(get_db),
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(100, ge=1, le=1000,
                       description="Maximum number of records to return"),
) -> List[UserSegmentationResponse]:
    """
    Fetch user segmentation data from the materialized view.

    Args:
        db: SQLAlchemy session provided by dependency injection.
        skip: Number of records to skip for pagination (default: 0).
        limit: Maximum number of records to return (default: 100, max: 1000).

    Returns:
        List of user segmentation records.

    Raises:
        HTTPException: If a database error occurs (status code 503).
    """
    logger.info(
        f"Fetching user segmentation data with skip={skip}, limit={limit}")
    try:
        query = db.query(MVUserSegmentation)
        result = query.offset(skip).limit(limit).all()
        logger.debug(
            f"Retrieved {len(result)} records from MV_USER_SEGMENTATION")
        return result
    # if db error
    except (SQLAlchemyError, DatabaseError) as e:
        logger.error(f"Database error in get_user_segmentation: {str(e)}")
        raise HTTPException(
            status_code=503,
            detail="Service unavailable due to a database error. Please try again later."
        )
    # if other error
    except Exception as e:
        logger.error(f"Unexpected error in get_user_segmentation: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="An unexpected error occurred."
        )
