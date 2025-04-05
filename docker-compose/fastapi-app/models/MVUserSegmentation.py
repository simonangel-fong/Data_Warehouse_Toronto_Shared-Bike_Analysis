from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, Float
from sqlalchemy.ext.declarative import declarative_base

# SQLAlchemy Base
Base = declarative_base()


class MVUserSegmentation(Base):
    __tablename__ = "mv_user_segmentation"
    __table_args__ = {"schema": "dw_schema"}

    # Using as primary key with year
    user_type_id = Column(Integer, primary_key=True)
    user_type_name = Column(String)
    # Using as composite primary key with user_type_id
    dim_year = Column(Integer, primary_key=True)
    trip_count = Column(Integer)
    avg_trip_duration = Column(Float)


class UserSegmentationResponse(BaseModel):
    user_type_id: int
    user_type_name: str
    dim_year: int
    trip_count: int
    avg_trip_duration: float

    class Config:
        orm_mode = True  # Enables compatibility with SQLAlchemy ORM objects
