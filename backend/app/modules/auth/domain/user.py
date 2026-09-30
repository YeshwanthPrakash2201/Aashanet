from dataclasses import dataclass
from uuid import UUID
from datetime import datetime


@dataclass
class User:
    id: UUID
    username: str
    password_hash: str
    role: str
    full_name: str
    is_active: bool
    created_at: datetime
    updated_at: datetime