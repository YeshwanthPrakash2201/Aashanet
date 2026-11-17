"""
Create an account, list accounts, reset a forgotten password, or promote a user to admin.

Run from the `backend` folder with the virtual environment's Python:

    .\\.venv\\Scripts\\python.exe -m scripts.create_admin --role asha_worker
    .\\.venv\\Scripts\\python.exe -m scripts.create_admin --role admin
    .\\.venv\\Scripts\\python.exe -m scripts.create_admin --promote USERNAME
    .\\.venv\\Scripts\\python.exe -m scripts.create_admin --list
    .\\.venv\\Scripts\\python.exe -m scripts.create_admin --reset-password USERNAME
    .\\.venv\\Scripts\\python.exe -m scripts.create_admin --deactivate USERNAME
    .\\.venv\\Scripts\\python.exe -m scripts.create_admin --activate USERNAME
    .\\.venv\\Scripts\\python.exe -m scripts.create_admin --change-name USERNAME

Full guide (users and PostgreSQL): docs/users-and-database.md

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

# Role names in use. `asha_worker` is the one most existing accounts use.
ROLES = [ADMIN_ROLE, "asha_worker"]

DEFAULTS = {
    ADMIN_ROLE: ("admin", "System Administrator"),
    "asha_worker": ("", ""),
}


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


def create_account(service: UserService, role: str) -> int:
    default_username, default_full_name = DEFAULTS[role]
    username = ask(f"Username for the new {role} account", default_username or None)
    full_name = ask("Full name", default_full_name or None)

    if not username or not full_name:
        print("Username and full name cannot be empty.")
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
            role=role,
            full_name=full_name,
        )
    except UniqueViolation:
        print(f"User '{username}' already exists.")
        return 1

    print(f"Created {role} user '{username}'.")
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


def list_users(db) -> int:
    """Prints every account. Passwords cannot be shown: only their
    hashes are stored."""
    with db.cursor() as cursor:
        cursor.execute(
            "SELECT username, full_name, role, is_active FROM users "
            "ORDER BY created_at"
        )
        rows = cursor.fetchall()

    if not rows:
        print("No users yet. Create one with --role asha_worker.")
        return 0

    print(f"{'USERNAME':<20} {'FULL NAME':<24} {'ROLE':<14} ACTIVE")
    for username, full_name, role, is_active in rows:
        print(f"{username:<20} {full_name:<24} {role:<14} "
              f"{'yes' if is_active else 'no'}")
    return 0


def reset_password(db, service: UserService, username: str) -> int:
    """Sets a new password for an existing user. The old password cannot
    be recovered, because only its hash is stored."""
    if not service.get_user_by_username(username):
        print(f"No user named '{username}'. See all users with --list.")
        return 1

    password = ask_password()

    with db.cursor() as cursor:
        cursor.execute(
            "UPDATE users SET password_hash = %s, "
            "updated_at = CURRENT_TIMESTAMP WHERE username = %s",
            (service.prepare_password(password), username),
        )

    db.commit()
    print(f"Password changed for '{username}'. Log in with the new password.")
    return 0


def set_active(db, service: UserService, username: str, active: bool) -> int:
    """Switches an account on or off. A switched-off account cannot log
    in, but it and its health records are kept (nothing is deleted)."""
    if not service.get_user_by_username(username):
        print(f"No user named '{username}'. See all users with --list.")
        return 1

    with db.cursor() as cursor:
        cursor.execute(
            "UPDATE users SET is_active = %s, "
            "updated_at = CURRENT_TIMESTAMP WHERE username = %s",
            (active, username),
        )

    db.commit()
    state = "activated - can log in" if active else "deactivated - cannot log in"
    print(f"'{username}' {state}.")
    return 0


def change_name(db, service: UserService, username: str) -> int:
    """Changes the full name shown in the app (the username stays)."""
    user = service.get_user_by_username(username)

    if not user:
        print(f"No user named '{username}'. See all users with --list.")
        return 1

    full_name = ask("New full name", user[4])

    if not full_name:
        print("Full name cannot be empty.")
        return 1

    with db.cursor() as cursor:
        cursor.execute(
            "UPDATE users SET full_name = %s, "
            "updated_at = CURRENT_TIMESTAMP WHERE username = %s",
            (full_name, username),
        )

    db.commit()
    print(f"Full name of '{username}' is now '{full_name}'. "
          "It shows in the app after the next login.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument(
        "--promote",
        metavar="USERNAME",
        help="make an existing user an admin instead of creating a new one",
    )
    parser.add_argument(
        "--reset-password",
        metavar="USERNAME",
        help="set a new password for an existing user",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="show all usernames, full names and roles",
    )
    parser.add_argument(
        "--deactivate",
        metavar="USERNAME",
        help="stop a user from logging in (their records are kept)",
    )
    parser.add_argument(
        "--activate",
        metavar="USERNAME",
        help="allow a deactivated user to log in again",
    )
    parser.add_argument(
        "--change-name",
        metavar="USERNAME",
        help="change the full name shown in the app",
    )
    parser.add_argument(
        "--role",
        choices=ROLES,
        help="role for the new account (required unless --promote is used)",
    )
    args = parser.parse_args()

    # No default role on purpose: silently creating an admin when a
    # worker account was intended is an easy and risky mistake.
    if not (args.promote or args.reset_password or args.list or args.role
            or args.deactivate or args.activate or args.change_name):
        parser.error(
            "choose a role: --role asha_worker (phone users) "
            "or --role admin (account managers)"
        )

    db = get_connection()

    try:
        service = UserService(UserRepository(db))

        if args.list:
            return list_users(db)

        if args.reset_password:
            return reset_password(db, service, args.reset_password)

        if args.promote:
            return promote(db, service, args.promote)

        if args.deactivate:
            return set_active(db, service, args.deactivate, False)

        if args.activate:
            return set_active(db, service, args.activate, True)

        if args.change_name:
            return change_name(db, service, args.change_name)

        return create_account(service, args.role)

    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())
