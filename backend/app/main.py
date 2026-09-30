from fastapi import FastAPI, Depends, HTTPException
from psycopg import Connection

from app.core.auth import get_current_user
from app.core.security import create_access_token

from app.infrastructure.db_dependency import get_db
from app.modules.records.api.health_records import router as health_records_router
from app.modules.auth.infrastructure.user_repository import UserRepository
from app.modules.auth.application.user_service import UserService

from app.schemas.user import (
    UserCreate,
    LoginRequest,
    LoginResponse
)


app = FastAPI(title="AASHANet AI API")
app.include_router(health_records_router)


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():
    return {
        "message": "AASHANet AI backend is running"
    }


# ============================================================
# DATABASE HEALTH CHECK
# ============================================================

@app.get("/health/database")
def database_health(
    db: Connection = Depends(get_db)
):
    with db.cursor() as cursor:
        cursor.execute("SELECT 1")
        result = cursor.fetchone()

    return {
        "database": "connected",
        "test_result": result[0]
    }


# ============================================================
# USERS COUNT
# Protected endpoint - JWT required
# ============================================================

@app.get("/users/count")
def users_count(
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    repository = UserRepository(db)
    service = UserService(repository)

    count = service.get_user_count()

    return {
        "user_count": count
    }


# ============================================================
# CREATE USER
# ============================================================

@app.post("/users")
def create_user(
    user: UserCreate,
    db: Connection = Depends(get_db)
):
    repository = UserRepository(db)
    service = UserService(repository)

    created_user = service.create_user(
        username=user.username,
        password=user.password,
        role=user.role,
        full_name=user.full_name
    )

    return {
        "id": str(created_user[0]),
        "username": created_user[1],
        "role": created_user[2],
        "full_name": created_user[3],
        "is_active": created_user[4]
    }


# ============================================================
# LOGIN
# ============================================================

@app.post("/auth/login", response_model=LoginResponse)
def login(
    user: LoginRequest,
    db: Connection = Depends(get_db)
):
    repository = UserRepository(db)
    service = UserService(repository)

    # --------------------------------------------------------
    # STEP 1: Find user by username
    # --------------------------------------------------------

    existing_user = service.get_user_by_username(
        user.username
    )

    # --------------------------------------------------------
    # STEP 2: User does not exist
    # --------------------------------------------------------

    if not existing_user:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password"
        )

    # --------------------------------------------------------
    # STEP 3: Verify password
    # --------------------------------------------------------

    password_is_valid = service.verify_user_password(
        user.password,
        existing_user[2]
    )

    # --------------------------------------------------------
    # STEP 4: Password is incorrect
    # --------------------------------------------------------

    if not password_is_valid:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password"
        )

    # --------------------------------------------------------
    # STEP 5: Create JWT access token
    # --------------------------------------------------------

    access_token = create_access_token(
        username=existing_user[1],
        role=existing_user[3]
    )

    # --------------------------------------------------------
    # STEP 6: Return successful login response
    # --------------------------------------------------------

    return {
        "message": "Login successful",
        "access_token": access_token,
        "token_type": "bearer",
        "username": existing_user[1],
        "role": existing_user[3],
        "full_name": existing_user[4]
    }

# CURRENT USER PROFILE
# Protected endpoint - JWT required

@app.get("/auth/me")
def get_my_profile(
    current_user: dict = Depends(get_current_user)
):
    return {
        "username": current_user["sub"],
        "role": current_user["role"]
    }