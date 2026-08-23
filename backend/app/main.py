import logging
from fastapi import FastAPI, Request
from fastapi.responses import RedirectResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from backend.app.core.config import settings
from backend.app.core.logging_config import setup_logging
from backend.app.database.session import engine
from backend.app.models import Base
from backend.app.api.v1.router import api_router

setup_logging()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Automatically initialize PostgreSQL database schema on startup
    try:
        Base.metadata.create_all(bind=engine)
        logging.info("Cloud Database tables checked/created successfully on app startup.")
        
        # Seed master data if database is fresh (0 accounts)
        from backend.app.database.session import SessionLocal
        db = SessionLocal()
        try:
            from backend.app.models.accounts import Account
            if db.query(Account).count() == 0:
                from backend.seed.seed_july_2026 import seed_master_data
                seed_master_data(db)
                db.commit()
                logging.info("Master accounts, products, and tanks seeded successfully on boot.")
        except Exception as seed_err:
            logging.error(f"Auto-seed warning: {seed_err}")
            db.rollback()
        finally:
            db.close()
    except Exception as e:
        logging.error(f"Error during startup database creation: {e}")
    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Automated Accounting, Stock Inventory, & Reporting REST API for PSO Lucky Filling Station",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configure CORS Middleware for local frontend development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import traceback
    error_trace = traceback.format_exc()
    print("GLOBAL EXCEPTION HANDLER:", error_trace)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal Server Error", "error": str(exc), "traceback": error_trace}
    )

@app.get("/", include_in_schema=False)
def root():
    """Redirect root path to interactive Swagger documentation."""
    return RedirectResponse(url="/docs")

@app.get("/health", tags=["Health"])
def health_check():
    """Health check endpoint to verify system status."""
    return {
        "status": "healthy",
        "project": settings.PROJECT_NAME,
        "version": "1.0.0",
        "docs_url": "http://127.0.0.1:8000/docs"
    }

# Register API v1 Routers
app.include_router(api_router)
