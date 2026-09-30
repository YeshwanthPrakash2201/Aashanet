from app.modules.auth.infrastructure.user_repository import UserRepository
from app.core.security import hash_password, verify_password


class UserService:

    def __init__(self, repository: UserRepository):
        self.repository = repository

    def get_user_count(self) -> int:
        return self.repository.count_users()

    def prepare_password(self, password: str) -> str:
        return hash_password(password)

    def create_user(
        self,
        username: str,
        password: str,
        role: str,
        full_name: str
    ):
        hashed_password = self.prepare_password(password)

        return self.repository.create_user(
            username=username,
            password_hash=hashed_password,
            role=role,
            full_name=full_name
        )

    def get_user_by_username(self, username: str):
        return self.repository.get_user_by_username(username)

    def verify_user_password(
        self,
        password: str,
        password_hash: str
    ) -> bool:
        return verify_password(password, password_hash)