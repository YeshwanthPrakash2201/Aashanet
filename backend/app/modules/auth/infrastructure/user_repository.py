from psycopg import Connection


class UserRepository:

    def __init__(self, db: Connection):
        self.db = db

    def count_users(self) -> int:
        with self.db.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM users")
            result = cursor.fetchone()

        return result[0]

    def create_user(
        self,
        username: str,
        password_hash: str,
        role: str,
        full_name: str
    ):
        with self.db.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO users (
                    id,
                    username,
                    password_hash,
                    role,
                    full_name
                )
                VALUES (
                    gen_random_uuid(),
                    %s,
                    %s,
                    %s,
                    %s
                )
                RETURNING id, username, role, full_name, is_active
                """,
                (username, password_hash, role, full_name)
            )

            user = cursor.fetchone()

        self.db.commit()

        return user

    def get_user_by_username(self, username: str):
        with self.db.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    id,
                    username,
                    password_hash,
                    role,
                    full_name,
                    is_active
                FROM users
                WHERE username = %s
                """,
                (username,)
            )

            return cursor.fetchone()

    def create_health_record(
        self,
        worker_id,
        raw_input: str,
        input_language: str | None = None
    ):
        with self.db.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO health_records (
                    id,
                    worker_id,
                    raw_input,
                    input_language
                )
                VALUES (
                    gen_random_uuid(),
                    %s,
                    %s,
                    %s
                )
                RETURNING
                    id,
                    worker_id,
                    raw_input,
                    input_language,
                    ai_status,
                    record_status
                """,
                (
                    worker_id,
                    raw_input,
                    input_language
                )
            )

            record = cursor.fetchone()

        self.db.commit()

        return record

   