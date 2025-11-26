import time
from flask import Blueprint, request, jsonify

from app.utils import (
    load_caregivers,
    save_caregivers,
    predict_survival_level_ml as predict_survival_level,
    match_caregivers,
)

bp = Blueprint("main", __name__)
RESPONSE_DELAY_SECONDS = 10  # keep artificial processing time capped at 10s


@bp.route("/api/predict_survival", methods=["POST"])
def api_predict_survival():
    """
    Endpoint used by the Flutter PredictionPage.

    Expects JSON body with fields such as:
    {
      "age": 76,
      "sex": "female",
      "dementia_type": "alzheimers",
      "severity": 2,
      "functional_decline": 2,
      "comorbidities": 1 or ["hypertension", "diabetes"],
      "neurological_symptoms": 2 or ["memory loss", "confusion"],
      "respiratory_issues": 1 or ["pneumonia"]
    }

    Returns:
    {
      "survival_level": "high chance" | "medium chance" | "low chance",
      "score": 0-100,
      "recommendations": { ... }
    }
    """

    payload = request.get_json(force=True) or {}

    time.sleep(RESPONSE_DELAY_SECONDS)

    result = predict_survival_level(payload)
    return jsonify(result), 200


@bp.route("/api/match_caregivers", methods=["POST"])
def api_match_caregivers():
    """
    Endpoint used by the Flutter CaregiverPage for matching.

    Expected payload:
    {
      "medical_needs": "Alzheimer's, wandering, medication help",
      "location": "Nairobi",
      "gender_preference": "female",
      "preferred_availability": "daytime" | "night"
    }

    Returns:
    {
      "matches": [ {caregiver...}, ... ],
      "total_available": <int>
    }
    """

    payload = request.get_json(force=True) or {}

    time.sleep(RESPONSE_DELAY_SECONDS)

    result = match_caregivers(payload)
    return jsonify(result), 200


@bp.route("/api/caregivers", methods=["GET"])
def api_get_caregivers():
    """
    Public endpoint to list caregivers (e.g. for admin views).
    """
    caregivers = load_caregivers()
    return jsonify(caregivers), 200


@bp.route("/api/admin/caregivers", methods=["POST"])
def api_add_caregiver():
    """
    Admin endpoint to create a new caregiver profile.
    This is used by the nursing home / admin side of the Flutter app.

    Expected JSON body:
    {
      "name": "...",
      "qualifications": ["..."],
      "focus_conditions": ["dementia", "alzheimers"],
      "location": "Nairobi",
      "gender": "female",
      "availability": ["daytime", "night"],
      "is_available": true
    }
    """
    data = request.get_json(force=True) or {}

    caregivers = load_caregivers()
    new_id = (max([cg.get("id", 0) for cg in caregivers]) + 1) if caregivers else 1

    new_cg = {
        "id": new_id,
        "name": data.get("name", ""),
        "qualifications": data.get("qualifications", []),
        "focus_conditions": data.get("focus_conditions", ["dementia"]),
        "location": data.get("location", ""),
        "gender": data.get("gender", ""),
        "availability": data.get("availability", []),
        "is_available": bool(data.get("is_available", True)),
    }

    caregivers.append(new_cg)
    save_caregivers(caregivers)
    return jsonify(new_cg), 201


@bp.route("/")
def index():
    return jsonify({"status": "Muuguzi Flask backend running"})
