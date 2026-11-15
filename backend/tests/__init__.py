import os

# app.config refuses to import without these. Tests never touch a real
# database or Gemini, so dummy values are enough.
os.environ.setdefault("DATABASE_URL", "postgresql://test:test@localhost/test")
os.environ.setdefault("JWT_SECRET_KEY", "unit-test-secret-key-not-for-production-use")
os.environ.setdefault("GEMINI_API_KEY", "unit-test-fake-key")
