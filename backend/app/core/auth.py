from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials

from app.core.security import (
    security,
    decode_access_token
)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    payload = decode_access_token(credentials)

    return payload