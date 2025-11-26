import math
from dataclasses import dataclass
from typing import Dict, Iterable, List, Tuple


@dataclass
class Model:
    """Simple, rule-based classifier."""

    def predict(self, sample: Dict[str, float]) -> Tuple[int, float]:
        """Return (pred_label, probability) using a deterministic rule."""
        fast_stage = sample.get("fast_stage", 0)
        mmse_score = sample.get("mmse_score", 30)

  
        is_high_risk = fast_stage >= 4 or mmse_score <= 18
        pred = 1 if is_high_risk else 0
        prob = 0.9 if pred == 1 else 0.1
        return pred, prob


MODEL = Model()



DATASET: List[Dict[str, float]] = [
    {"age": 78, "mmse_score": 12, "fast_stage": 6, "comorbidity_count": 3, "label": 1},
    {"age": 70, "mmse_score": 24, "fast_stage": 3, "comorbidity_count": 1, "label": 0},
    {"age": 65, "mmse_score": 28, "fast_stage": 2, "comorbidity_count": 0, "label": 0},
    {"age": 82, "mmse_score": 10, "fast_stage": 7, "comorbidity_count": 4, "label": 1},
    {"age": 75, "mmse_score": 18, "fast_stage": 4, "comorbidity_count": 2, "label": 1},
    {"age": 72, "mmse_score": 22, "fast_stage": 3, "comorbidity_count": 1, "label": 0},
    {"age": 68, "mmse_score": 26, "fast_stage": 2, "comorbidity_count": 1, "label": 0},
    {"age": 80, "mmse_score": 14, "fast_stage": 5, "comorbidity_count": 2, "label": 1},
    {"age": 77, "mmse_score": 20, "fast_stage": 4, "comorbidity_count": 2, "label": 1},
    {"age": 73, "mmse_score": 25, "fast_stage": 3, "comorbidity_count": 0, "label": 0},
    {"age": 74, "mmse_score": 22, "fast_stage": 3, "comorbidity_count": 1, "label": 0},
    {"age": 79, "mmse_score": 15, "fast_stage": 5, "comorbidity_count": 3, "label": 1},
    {"age": 67, "mmse_score": 27, "fast_stage": 2, "comorbidity_count": 0, "label": 0},
    {"age": 81, "mmse_score": 16, "fast_stage": 5, "comorbidity_count": 3, "label": 1},
    {"age": 76, "mmse_score": 19, "fast_stage": 4, "comorbidity_count": 2, "label": 1},
    {"age": 69, "mmse_score": 23, "fast_stage": 3, "comorbidity_count": 1, "label": 0},
    {"age": 71, "mmse_score": 21, "fast_stage": 2, "comorbidity_count": 1, "label": 0},
    {"age": 83, "mmse_score": 13, "fast_stage": 6, "comorbidity_count": 4, "label": 1},
    {"age": 66, "mmse_score": 29, "fast_stage": 2, "comorbidity_count": 1, "label": 0},
    {"age": 78, "mmse_score": 17, "fast_stage": 4, "comorbidity_count": 2, "label": 1},
    {"age": 72, "mmse_score": 24, "fast_stage": 3, "comorbidity_count": 2, "label": 0},
    {"age": 75, "mmse_score": 18, "fast_stage": 3, "comorbidity_count": 2, "label": 1},
    {"age": 70, "mmse_score": 26, "fast_stage": 5, "comorbidity_count": 1, "label": 0},  
    {"age": 64, "mmse_score": 27, "fast_stage": 2, "comorbidity_count": 0, "label": 1},  
    {"age": 79, "mmse_score": 14, "fast_stage": 5, "comorbidity_count": 2, "label": 1},
]


def evaluate(model: Model, dataset: Iterable[Dict[str, float]]) -> None:
    total = 0
    correct = 0
    tp = fp = tn = fn = 0
    for row in dataset:
        total += 1
        label = int(row["label"])
        pred, prob = model.predict(row)
        correct += int(pred == label)

        if pred == 1 and label == 1:
            tp += 1
        elif pred == 1 and label == 0:
            fp += 1
        elif pred == 0 and label == 0:
            tn += 1
        elif pred == 0 and label == 1:
            fn += 1

    accuracy = correct / total if total else 0.0
    print("=== Model Evaluation ===")
    print(f"Samples      : {total}")
    print(f"Accuracy     : {accuracy:.3f}")
    print()
    print("Confusion matrix (rows=true, cols=pred):")
    print(f"  TP: {tp:2d}  FP: {fp:2d}")
    print(f"  FN: {fn:2d}  TN: {tn:2d}")


if __name__ == "__main__":
    evaluate(MODEL, DATASET)
