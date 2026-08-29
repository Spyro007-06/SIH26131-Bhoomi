"""vision/ — classifier and OCR extraction.

OWNER: Suchit. Spec: docs/DESIGN.md §3, contract C1 in §4.

Exposes `classify(image) -> TopK` and `extract_label(image) -> LabelExtract`.
"""

from app.vision.classifier import classify
from app.vision.ocr import extract_label

__all__ = ["classify", "extract_label"]
