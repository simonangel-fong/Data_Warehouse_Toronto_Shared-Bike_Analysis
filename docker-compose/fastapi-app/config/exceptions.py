class ApplicationError(Exception):
    """Base exception class for all custom application errors."""

    def __init__(self, message: str, status_code: int = 500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class ConfigurationError(ApplicationError):
    """Raised when configuration loading fails."""

    def __init__(self, message: str):
        super().__init__(message=message, status_code=500)


class DatabaseError(ApplicationError):
    """Raised when database operations fail."""

    def __init__(self, message: str):
        super().__init__(message=message, status_code=503)
