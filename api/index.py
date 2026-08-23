import sys
import os
import traceback
from pathlib import Path

# Ensure project root is in sys.path
root_dir = Path(__file__).resolve().parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

try:
    from backend.app.main import app
except Exception as err:
    from fastapi import FastAPI
    from fastapi.responses import JSONResponse
    
    app = FastAPI(title="Serverless Startup Error")
    error_str = str(err)
    tb_str = traceback.format_exc()
    
    @app.get("/{full_path:path}")
    def error_handler(full_path: str):
        return JSONResponse(
            status_code=500,
            content={
                "error": "Failed to initialize backend application",
                "detail": error_str,
                "traceback": tb_str
            }
        )
