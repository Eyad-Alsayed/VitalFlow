FROM python:3.11-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend/ ./backend/

# Make start script executable
RUN chmod +x ./backend/start.sh

# Expose port
EXPOSE 8000

# Change to backend directory
WORKDIR /app/backend

# Start command - use bash script
CMD ["bash", "start.sh"]
