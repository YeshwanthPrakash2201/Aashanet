from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from psycopg import Connection
from psycopg.errors import UniqueViolation

from app.core.auth import get_current_user
from app.core.security import create_access_token, decode_access_token

from app.infrastructure.db_dependency import get_db
from app.modules.records.api.health_records import router as health_records_router
from app.modules.auth.infrastructure.user_repository import UserRepository
from app.modules.auth.application.user_service import UserService

from app.schemas.user import (
    UserCreate,
    LoginRequest,
    LoginResponse
)


ADMIN_ROLE = "admin"

# auto_error=False so the very first (bootstrap) user can be created
# without a token; every later request must carry an admin token.
optional_bearer = HTTPBearer(auto_error=False)


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
# Admin JWT required. The only exception is bootstrapping: when the
# users table is empty, the first user may be created without a token
# and must be an admin.
# ============================================================

@app.post("/users", status_code=status.HTTP_201_CREATED)
def create_user(
    user: UserCreate,
    db: Connection = Depends(get_db),
    credentials: HTTPAuthorizationCredentials | None = Depends(optional_bearer)
):
    repository = UserRepository(db)
    service = UserService(repository)

    if credentials is not None:
        current_user = decode_access_token(credentials)

        if current_user.get("role") != ADMIN_ROLE:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only administrators can create users"
            )

    elif service.get_user_count() == 0:
        if user.role != ADMIN_ROLE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="The first user must be an admin"
            )

    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )

    try:
        created_user = service.create_user(
            username=user.username,
            password=user.password,
            role=user.role,
            full_name=user.full_name
        )
    except UniqueViolation:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already exists"
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
    # STEP 4b: Deactivated accounts cannot log in
    # --------------------------------------------------------

    if not existing_user[5]:
        raise HTTPException(
            status_code=403,
            detail="Account is disabled"
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