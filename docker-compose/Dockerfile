# Base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Create non-root user
RUN useradd -m -r appuser && chown appuser:appuser /app

# Copy only requirements and install packages
COPY ./app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire app directory
COPY ./app .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Run with optimized settings
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]