# Use the official Python image as the base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy the application code to the container
COPY app.py /app/

# Install dependencies
RUN pip install flask flask-cors

# Expose the port the app runs on
EXPOSE 80

# Define the command to run the application
CMD ["python", "app.py"]