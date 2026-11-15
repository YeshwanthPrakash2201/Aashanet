"""
Create an administrator account, or promote an existing user to admin.

Run from the `backend` folder with the virtual environment's Python:

    .\\.venv\\Scripts\\python.exe -m scripts.create_admin
    .\\.venv\\Scripts\\python.exe -m scripts.create_admin --promote USERNAME

The password is typed into the terminal (it is not shown on screen)
and is stored only as a hash. It is never printed or logged.
"""

import argparse
import getpass
import sys

from psycopg.errors import UniqueViolation

from app.infrastructure.database import get_connection
from app.main import ADMIN_ROLE
from app.modules.auth.application.user_service import UserService
from app.modules.auth.infrastructure.user_repository import UserRepository

MIN_PASSWORD_LENGTH = 10


def ask(prompt: str, default: str | None = None) -> str:
    suffix = f" [{default}]" if default else ""
    value = input(f"{prompt}{suffix}: ").strip()
    return value or (default or "")


def ask_password() -> str:
    while True:
        password = getpass.getpass(
            f"Password (at least {MIN_PASSWORD_LENGTH} characters, hidden): "
        )

        if len(password) < MIN_PASSWORD_LENGTH:
            print(f"  Too short. Use at least {MIN_PASSWORD_LENGTH} characters.")
            continue

        if password != getpass.getpass("Repeat password: "):
            print("  Passwords do not match. Try again.")
            continue

        return password


def create_admin(service: UserService) -> int:
    username = ask("Admin username", "admin")
    full_name = ask("Full name", "System Administrator")

    if not username:
        print("Username cannot be empty.")
        return 1

    if service.get_user_by_username(username):
        print(f"User '{username}' already exists. "
              f"Use --promote {username} to make it an admin.")
        return 1

    password = ask_password()

    try:
        service.create_user(
            username=username,
            password=password,
            role=ADMIN_ROLE,
            full_name=full_name,
        )
    except UniqueViolation:
        print(f"User '{username}' already exists.")
        return 1

    print(f"Created admin user '{username}'.")
    return 0


def promote(db, service: UserService, username: str) -> int:
    user = service.get_user_by_username(username)

    if not user:
        print(f"No user named '{username}'.")
        return 1

    if user[3] == ADMIN_ROLE:
        print(f"'{username}' is already an admin.")
        return 0

    with db.cursor() as cursor:
        cursor.execute(
            "UPDATE users SET role = %s, updated_at = CURRENT_TIMESTAMP "
            "WHERE username = %s",
            (ADMIN_ROLE, username),
        )

    db.commit()
    print(f"Promoted '{username}' from '{user[3]}' to '{ADMIN_ROLE}'. "
          "Log in again to get a token with the new role.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--promote",
        metavar="USERNAME",
        help="make an existing user an admin instead of creating a new one",
    )
    args = parser.parse_args()

    db = get_connection()

    try:
        service = UserService(UserRepository(db))

        if args.promote:
            return promote(db, service, args.promote)

        return create_admin(service)

    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())
