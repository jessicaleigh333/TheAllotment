"""Validation for future authoring profiles; no simulation or publication writes."""
import json
from pathlib import Path

from .foundation import IntegrityError, canonical


def validate_profile(profile, known_plant_ids):
    from jsonschema import Draft202012Validator

    canonical(profile)  # Reject NaN/Infinity before schema number comparisons.
    schema=json.loads(Path(__file__).with_name("profile.schema.json").read_text())
    Draft202012Validator(schema).validate(profile)
    if profile["plant_id"] not in known_plant_ids:
        raise IntegrityError("Unknown profile botanical ID")
    evidence=[value["evidence_id"] for value in profile["evidence"]]
    if len(set(evidence))!=len(evidence):
        raise IntegrityError("Duplicate profile evidence ID")
    if "size_growth" in profile["capabilities"] and (
        len(profile["size_knots"])<2 or not profile["calibration_basis"] or not profile["propagation_method"]
    ):
        raise IntegrityError("Size growth requires knots, propagation context and calibration provenance")
    previous=-1
    for knot in profile["size_knots"]:
        if knot["age_days"]<=previous:
            raise IntegrityError("Profile age knots must strictly increase")
        previous=knot["age_days"]
        if not set(knot["evidence_ids"]).issubset(evidence):
            raise IntegrityError("Unknown size-knot evidence ID")
    for rule in profile["seasonal_rules"]:
        if not set(rule["evidence_ids"]).issubset(evidence):
            raise IntegrityError("Unknown seasonal-rule evidence ID")
    return True
