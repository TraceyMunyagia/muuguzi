import json
import os
from typing import List, Dict, Any

from flask import current_app





def get_caregiver_file_path() -> str:
    """
    Returns path to the caregivers JSON file, configured in Config.CAREGIVER_FILE.
    """
    return current_app.config["CAREGIVER_FILE"]


def load_caregivers() -> List[Dict[str, Any]]:
    """
    Load caregivers from the JSON file. Returns an empty list if file missing/invalid.
    """
    path = get_caregiver_file_path()
    if not os.path.exists(path):
        return []
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, list):
            return data
        return []
    except (json.JSONDecodeError, OSError):
        return []


def save_caregivers(caregivers: List[Dict[str, Any]]) -> None:
    """
    Save caregivers list back to the JSON file.
    """
    path = get_caregiver_file_path()
    with open(path, "w", encoding="utf-8") as f:
        json.dump(caregivers, f, indent=2, ensure_ascii=False)




def _safe_float(value, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def predict_survival_level(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Lightweight, rule-based survival scoring function.

    Updated to use:
        - mmse_score (0-30)          # Mini-Mental State Examination
        - fast_stage (1-7)           # FAST functional decline scale

    The backend still tolerates legacy keys ("severity", "functional_decline")
    but the preferred keys from the Flutter app are:

        mmse_score       -> slider 0-30
        fast_stage       -> slider 1-7

    Other fields:
        - age
        - sex
        - dementia_type  (alzheimers, vascular, other)
        - comorbidities  (count or list)
        - neurological_symptoms (1-3 or list)
        - respiratory_issues    (1-3 or list)

    It returns:
        {
          "survival_level": "high chance" | "medium chance" | "low chance",
          "score": 0-100,
          "recommendations": { ... }
        }
    """

    age = _safe_float(payload.get("age", 0))
    sex = str(payload.get("sex", "")).lower()
    dementia_type = str(payload.get("dementia_type", "")).lower()

   
    mmse = _safe_float(payload.get("mmse_score", payload.get("severity", 24)))  
    fast_stage = _safe_float(
        payload.get("fast_stage", payload.get("functional_decline", 1))
    )  # 1-7

    comorbidities_raw = payload.get("comorbidities", 0)
    neurological_raw = payload.get("neurological_symptoms", 1)
    respiratory_raw = payload.get("respiratory_issues", 1)

    if isinstance(comorbidities_raw, list):
        comorbidities = len(comorbidities_raw)
    else:
        comorbidities = int(_safe_float(comorbidities_raw, 0))

    if isinstance(neurological_raw, list):
        neurological = min(3.0, 1.0 + len(neurological_raw) * 0.5)
    else:
        neurological = _safe_float(neurological_raw, 1.0)

    if isinstance(respiratory_raw, list):
        respiratory = min(3.0, 1.0 + len(respiratory_raw) * 0.5)
    else:
        respiratory = _safe_float(respiratory_raw, 1.0)

    score = 85.0

    if age > 80:
        score -= (age - 80) * 0.8
    elif age > 65:
        score -= (age - 65) * 0.4

    if dementia_type == "alzheimers":
        score -= 10
    elif dementia_type == "vascular":
        score -= 15
    elif dementia_type:
        score -= 12

    
    if mmse >= 24:
        mmse_penalty = 0.0
    elif mmse >= 20:
        mmse_penalty = 5.0
    elif mmse >= 13:
        mmse_penalty = 12.0
    else:
        mmse_penalty = 18.0
    score -= mmse_penalty

    fast_penalty = max(0.0, min(20.0, (fast_stage - 1.0) * 3.5))
    score -= fast_penalty

    score -= comorbidities * 3.0

    score -= (neurological - 1.0) * 7.0
    score -= (respiratory - 1.0) * 9.0

    score = max(0.0, min(100.0, score))

    if score >= 70:
        level = "high chance"
    elif score >= 40:
        level = "medium chance"
    else:
        level = "low chance"

    recommendations = {
        "Regular Medical Check-ups": (
            "Maintain regular follow-up visits with healthcare providers "
            "to monitor dementia progression, adjust medications, and "
            "screen for other conditions such as hypertension, diabetes, "
            "cardiovascular disease, and infections."
        ),
        "Healthy Diet and Hydration": (
            "Encourage a balanced diet rich in fruits, vegetables, whole grains, "
            "and adequate fluids. Monitor weight, appetite, and swallowing "
            "difficulties to reduce the risk of malnutrition and aspiration."
        ),
        "Exercise": (
            "Support safe physical activity such as walking, stretching, or "
            "simple chair exercises to maintain mobility, muscle strength, "
            "and cardiovascular health, while reducing fall risk."
        ),
        "Social Engagement": (
            "Promote meaningful activities, conversations, and time with family "
            "or caregivers to support mood, orientation, and quality of life."
        ),
        "Routine": (
            "Keep a consistent daily routine for meals, medications, sleep, "
            "and personal care. Stable routines reduce confusion, agitation, "
            "and caregiver stress."
        ),
    }

    return {
        "survival_level": level,
        "score": round(score, 1),
        "recommendations": recommendations,
    }




def match_caregivers(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Simple rule-based caregiver matching:

    - More points if caregiver's location matches patient's location.
    - More points if caregiver's gender matches patient preference (if any).
    - More points if caregiver has 'dementia' or specific dementia type in focus_conditions.
    - 'Preferred availability' (daytime/night) is matched using a simple flag.

    The function returns a dict:
    {
        "matches": [ {caregiver...}, ... ],
        "total_available": <int>
    }
    """

    medical_needs = str(payload.get("medical_needs", "")).lower()
    location = str(payload.get("location", "")).lower().strip()
    gender_pref = str(payload.get("gender_preference", "")).lower().strip()
    preferred_availability = str(payload.get("preferred_availability", "")).lower().strip()

    caregivers = load_caregivers()
    scored: List[Any] = []

    for cg in caregivers:
        score = 0.0

        cg_location = str(cg.get("location", "")).lower()
        cg_gender = str(cg.get("gender", "")).lower()
        cg_focus = [str(x).lower() for x in cg.get("focus_conditions", [])]
        cg_availability = [str(x).lower() for x in cg.get("availability", [])] if isinstance(
            cg.get("availability", []), list
        ) else [str(cg.get("availability", "")).lower()]

        if location and location in cg_location:
            score += 30.0

        if gender_pref and cg_gender == gender_pref:
            score += 15.0

        if "dementia" in cg_focus:
            score += 25.0

        if "alzheimer" in medical_needs and "alzheimers" in cg_focus:
            score += 10.0
        if "vascular" in medical_needs and "vascular" in cg_focus:
            score += 10.0

   
        if preferred_availability:
            if preferred_availability in cg_availability:
                score += 20.0

        if cg.get("is_available", True):
            score += 10.0

        scored.append((score, cg))

    # Sort by score descending
    scored.sort(key=lambda x: x[0], reverse=True)
    top_matches = [cg for s, cg in scored if s > 0][:5]

    return {
        "matches": top_matches,
        "total_available": len(caregivers),
    }


_ml_model = None


def _get_ml_model():
    """Lazy-load the trained scikit-learn model if available.

    The model is trained by train_model.py and saved as 'survival_model.pkl'
    in the project root (next to app.py).
    """
    global _ml_model
    if _ml_model is not None:
        return _ml_model

    import joblib  

    root = current_app.root_path
    model_path = os.path.join(root, "..", "survival_model.pkl")
    model_path = os.path.abspath(model_path)

    if not os.path.exists(model_path):
        return None

    _ml_model = joblib.load(model_path)
    return _ml_model


def predict_survival_level_ml(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Predict survival using a trained ML model if available.

    If the trained model file cannot be found, this falls back to the
    existing rule-based `predict_survival_level` function.
    """
    model = _get_ml_model()
    if model is None:
        return predict_survival_level(payload)

    import pandas as pd 

    age = _safe_float(payload.get("age", 0))
    sex = str(payload.get("sex", "")).lower() or "unknown"
    dementia_type = str(payload.get("dementia_type", "")).lower() or "other"

    mmse = _safe_float(payload.get("mmse_score", payload.get("severity", 24)))
    fast_stage = _safe_float(
        payload.get("fast_stage", payload.get("functional_decline", 1))
    )

    comorbidities_raw = payload.get("comorbidities", 0)
    neurological_raw = payload.get("neurological_symptoms", 1)
    respiratory_raw = payload.get("respiratory_issues", 1)

    if isinstance(comorbidities_raw, list):
        comorbidities = len(comorbidities_raw)
    else:
        comorbidities = int(_safe_float(comorbidities_raw, 0))

    if isinstance(neurological_raw, list):
        neurological = min(3.0, 1.0 + len(neurological_raw) * 0.5)
    else:
        neurological = _safe_float(neurological_raw, 1.0)

    if isinstance(respiratory_raw, list):
        respiratory = min(3.0, 1.0 + len(respiratory_raw) * 0.5)
    else:
        respiratory = _safe_float(respiratory_raw, 1.0)

    row = pd.DataFrame(
        [
            {
                "age": age,
                "sex": sex,
                "dementia_type": dementia_type,
                "mmse_score": mmse,
                "fast_stage": fast_stage,
                "comorbidities": comorbidities,
                "neurological": neurological,
                "respiratory": respiratory,
            }
        ]
    )

    score = float(model.predict(row)[0])

    score = max(0.0, min(100.0, score))

    if score >= 70:
        level = "high chance"
    elif score >= 40:
        level = "medium chance"
    else:
        level = "low chance"

    recommendations = {
        "Regular Medical Check-ups": (
            "Ensure regular follow-up with healthcare providers for "
            "medication review, monitoring of dementia progression, and "
            "early detection of complications."
        ),
        "Healthy Diet and Hydration": (
            "Provide a balanced diet rich in fruits, vegetables, whole grains, "
            "and adequate fluids to support overall brain and physical health."
        ),
        "Exercise": (
            "Support safe physical activity such as walking, stretching, or "
            "simple chair exercises to maintain mobility, muscle strength, "
            "and cardiovascular health, while reducing fall risk."
        ),
        "Social Engagement": (
            "Promote meaningful activities, conversations, and time with family "
            "or caregivers to support mood, orientation, and quality of life."
        ),
        "Routine": (
            "Keep a consistent daily routine for meals, medications, sleep, "
            "and personal care. Stable routines reduce confusion, agitation, "
            "and caregiver stress."
        ),
    }

    return {
        "survival_level": level,
        "score": score,
        "recommendations": recommendations,
    }
