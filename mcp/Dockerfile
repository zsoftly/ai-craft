# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the pyproject.toml file and install dependencies
COPY pyproject.toml .
COPY ./mcp_registry ./mcp_registry
RUN pip install --no-cache-dir .

# Expose the port the app runs on
EXPOSE 80

# Run the application
CMD ["uvicorn", "mcp_registry.main:app", "--host", "0.0.0.0", "--port", "80"]
