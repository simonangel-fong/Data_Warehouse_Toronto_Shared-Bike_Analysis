import logging
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from config.exceptions import ConfigurationError

# retrieve a logger object
logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    """Database connection settings loaded from environment variables."""
    ORCLDB_HOST: str
    ORCLDB_SID: str
    ORCLDB_PORT: str
    ORCLDB_SERVICE: str
    ORCLDB_USER: str
    ORCLDB_PWD: str

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="forbid"  # Prevent unexpected fields
    )


@lru_cache
def get_settings():
    """
    Load and cache application settings from environment variables.
    Returns:
        Settings: Configured settings object.
    Raises:
        ConfigurationError: If settings cannot be loaded due to missing or invalid values.
    """
    try:
        settings = Settings()
        print(settings.ORCLDB_HOST)
        logger.info("Settings loaded successfully.")
        return settings
    except Exception as e:  # Broad exception catch for simplicity; refine as needed
        logger.error(f"Failed to load settings: {str(e)}")
        raise ConfigurationError(f"Unable to load configuration: {str(e)}")
