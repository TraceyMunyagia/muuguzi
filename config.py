import os

BASE_DIR = os.path.abspath(os.path.dirname(__file__))


class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-key")
    JSON_SORT_KEYS = False

    CAREGIVER_FILE = os.path.join(BASE_DIR, "caregivers.json")
