# Database Connection Configuration Guide

## Option 1: Update database.py directly
# Replace the DATABASE_URL in backend/database.py with your credentials:

DATABASE_URL = "postgresql://postgres:YOUR_PASSWORD@localhost:5432/medical_services"

# Where:
# - postgres = username (default PostgreSQL user)
# - YOUR_PASSWORD = the password you set during PostgreSQL installation
# - localhost = server address (local machine)
# - 5432 = PostgreSQL port (default)
# - medical_services = database name

## Option 2: Use Environment Variable (Recommended for production)
# Set environment variable instead of hardcoding password:

# Windows (Command Prompt):
set DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/medical_services

# Windows (PowerShell):
$env:DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/medical_services"

# Linux/Mac:
export DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/medical_services"

## Option 3: Create .env file (Most secure)
# Create a .env file in the backend folder with:
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/medical_services

# Then modify database.py to use python-dotenv:
# pip install python-dotenv
# from dotenv import load_dotenv
# load_dotenv()

## Connection String Examples:
# Local PostgreSQL: postgresql://postgres:mypassword@localhost:5432/medical_services
# Remote PostgreSQL: postgresql://user:password@remote-server.com:5432/medical_services
# With SSL: postgresql://user:password@server:5432/dbname?sslmode=require

## Common Issues:
# 1. "password authentication failed" → Check password
# 2. "could not connect to server" → Check if PostgreSQL service is running
# 3. "database does not exist" → Create database first: CREATE DATABASE medical_services;
# 4. "port 5432 failed" → Check if PostgreSQL is running on correct port