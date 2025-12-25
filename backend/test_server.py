from fastapi import FastAPI
import uvicorn

# Simple test server
app = FastAPI(title="Test API", version="1.0.0")

@app.get("/")
def root():
    return {"message": "API is working!", "status": "success"}

@app.get("/test")  
def test():
    return {"test": "endpoint working"}

if __name__ == "__main__":
    print("Starting simple test server...")
    uvicorn.run(app, host="0.0.0.0", port=8000)