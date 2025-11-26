
import os
import random

import joblib
import numpy as np
import pandas as pd

from app.utils import predict_survival_level


RANDOM_SEED = 42
N_SAMPLES = 2000


def generate_synthetic_dataset(n_samples: int) -> pd.DataFrame:
    rng = random.Random(RANDOM_SEED)
    rows = []

    sexes = ["male", "female"]
    dementia_types = ["alzheimers", "vascular", "other"]

    for _ in range(n_samples):
        age = rng.randint(55, 95)
        sex = rng.choice(sexes)
        dementia_type = rng.choice(dementia_types)
        mmse_score = rng.randint(0, 30)        
        fast_stage = rng.randint(1, 7)         
        comorbidities = rng.randint(0, 4)      
        neurological = rng.randint(1, 3)       
        respiratory = rng.randint(1, 3)        

        payload = {
            "age": age,
            "sex": sex,
            "dementia_type": dementia_type,
            "mmse_score": mmse_score,
            "fast_stage": fast_stage,
            "comorbidities": comorbidities,
            "neurological_symptoms": neurological,
            "respiratory_issues": respiratory,
        }

        teacher_out = predict_survival_level(payload)
        score = teacher_out.get("score", 50.0)

        rows.append(
            {
                "age": age,
                "sex": sex,
                "dementia_type": dementia_type,
                "mmse_score": mmse_score,
                "fast_stage": fast_stage,
                "comorbidities": comorbidities,
                "neurological": neurological,
                "respiratory": respiratory,
                "score": score,
            }
        )

    return pd.DataFrame(rows)


def train_and_save_model(df: pd.DataFrame, output_path: str) -> None:
    from sklearn.compose import ColumnTransformer
    from sklearn.ensemble import RandomForestRegressor
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import OneHotEncoder

    feature_cols = [
        "age",
        "sex",
        "dementia_type",
        "mmse_score",
        "fast_stage",
        "comorbidities",
        "neurological",
        "respiratory",
    ]
    target_col = "score"

    X = df[feature_cols]
    y = df[target_col]

    categorical = ["sex", "dementia_type"]
    numeric = [
        "age",
        "mmse_score",
        "fast_stage",
        "comorbidities",
        "neurological",
        "respiratory",
    ]

    preprocessor = ColumnTransformer(
        transformers=[
            ("cat", OneHotEncoder(handle_unknown="ignore"), categorical),
            ("num", "passthrough", numeric),
        ]
    )

    model = RandomForestRegressor(
        n_estimators=200,
        max_depth=8,
        random_state=RANDOM_SEED,
    )

    pipe = Pipeline(
        steps=[
            ("pre", preprocessor),
            ("model", model),
        ]
    )

    pipe.fit(X, y)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    joblib.dump(pipe, output_path)
    print(f"Saved trained model to {output_path}")


def main():
    print("Generating synthetic training data...")
    df = generate_synthetic_dataset(N_SAMPLES)
    print(df.head())

    out_path = os.path.join(os.path.dirname(__file__), "survival_model.pkl")
    print("Training model...")
    train_and_save_model(df, out_path)


if __name__ == "__main__":
    main()
