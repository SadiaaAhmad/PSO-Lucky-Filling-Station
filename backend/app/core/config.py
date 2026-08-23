import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

# Locate backend/.env file relative to this file
BASE_DIR = Path(__file__).resolve().parent.parent.parent
ENV_FILE = BASE_DIR / ".env"

class Settings(BaseSettings):
    PROJECT_NAME: str = "Fuel Station Accounting System"
    API_V1_STR: str = "/api/v1"
    
    POSTGRES_SERVER: str = "127.0.0.1"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "pgadmin4"
    POSTGRES_DB: str = "fuel_station_db"
    POSTGRES_PORT: int = 5432
    
    DATABASE_URL: str = ""

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore"
    )

    def get_database_url(self) -> str:
        # Check environment variable first (Vercel/Render env vars)
        db_url = os.getenv("DATABASE_URL") or self.DATABASE_URL
        if db_url and db_url.strip():
            if db_url.startswith("postgres://"):
                db_url = db_url.replace("postgres://", "postgresql://", 1)
            return db_url
        
        # If running on Vercel serverless without DATABASE_URL set, use /tmp SQLite
        if os.getenv("VERCEL"):
            return "sqlite:////tmp/fuel_station.db"
            
        # Fallback to local SQLite file if it exists
        local_sqlite = BASE_DIR / "fuel_station.db"
        if local_sqlite.exists():
            return f"sqlite:///{local_sqlite}"

        url = f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        if "@localhost" in url:
            url = url.replace("@localhost", "@127.0.0.1")
        return url

settings = Settings()
