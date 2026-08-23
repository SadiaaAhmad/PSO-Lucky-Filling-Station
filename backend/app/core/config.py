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
        if self.DATABASE_URL:
            url = self.DATABASE_URL
        else:
            url = f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        
        # Handle postgres:// vs postgresql:// protocol prefix for cloud DBs (e.g. Render/Supabase)
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql://", 1)
        
        # Replace localhost with 127.0.0.1 to avoid Windows IPv6 (::1) auth issues
        if "@localhost" in url:
            url = url.replace("@localhost", "@127.0.0.1")
        return url

settings = Settings()
