from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Change SECRET_KEY in production (put it in a .env file).
    secret_key: str = "change-me-ews-dev-secret"
    algorithm: str = "HS256"
    access_token_minutes: int = 60 * 12

    database_url: str = "sqlite:///./ews.db"
    upload_dir: str = "uploads"

    class Config:
        env_file = ".env"


settings = Settings()
