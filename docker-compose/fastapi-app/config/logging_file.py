import os
import logging
from typing import Optional


def setup_logging(log_level: str = "INFO", log_file: Optional[str] = None) -> None:
    """
    Configure application-wide logging.

    Args:
        log_level: Logging level (e.g., "INFO", "DEBUG"). Defaults to "INFO".
        log_file: Optional file path to log to in addition to console.
    """
    # Convert string level to logging constant
    level = getattr(logging, log_level.upper(), logging.INFO)

    # Define handlers
    handlers = [logging.StreamHandler()]  # Console output
    if log_file:
        handlers.append(logging.FileHandler(log_file))

    # Configure logging
    logging.basicConfig(
        level=level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers=handlers,
    )

    # Ensure this runs only once
    if not logging.getLogger(__name__).hasHandlers():
        logging.getLogger(__name__).info("Logging configured successfully.")


def configure_logging_from_env() -> None:
    log_level = os.getenv("LOG_LEVEL", "INFO")
    log_file = os.getenv("LOG_FILE", None)
    setup_logging(log_level=log_level, log_file=log_file)
