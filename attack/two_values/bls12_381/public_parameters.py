"""Public field parameters and simple JSON encoding for BLS12-381.

This file contains no dealer secrets. The extension field is Fp^12, represented
using w^12 - 2*w^6 + 2 = 0.
"""

import json
from sage.all import GF, PolynomialRing, ZZ

# BLS12-381 base-field prime p and subgroup-order prime r.
P = ZZ(0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab)
R = ZZ(0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001)
DEGREE = 12
MODULUS = [2] + [0] * 5 + [-2] + [0] * 5 + [1]
PROFILE = "BLS12-381/reduced-Tate/G1xG2"


def make_field():
    """Construct the target extension field Fp^12."""
    base_field = GF(P)
    polynomials = PolynomialRing(base_field, "X")
    modulus = polynomials(MODULUS)
    return base_field.extension(modulus, "w")


def encode(value):
    """Turn a field element into 12 decimal-string coefficients for JSON."""
    coefficients = list(value.polynomial())
    coefficients += [0] * (DEGREE - len(coefficients))
    return [str(int(c)) for c in coefficients]


def decode(field, coefficients):
    """Rebuild a field element from its 12 power-basis coefficients."""
    if not isinstance(coefficients, list) or len(coefficients) != DEGREE:
        raise ValueError("A field element must have exactly 12 coefficients.")
    return field([ZZ(c) for c in coefficients])


def save_public(path, values):
    """Write the two-value experiment's public coefficient-list transcript."""
    path.write_text(json.dumps([encode(value) for value in values], indent=2) + "\n")


def load_public(path, field):
    """Read the public coefficient lists without loading any dealer state."""
    entries = json.loads(path.read_text())
    if not isinstance(entries, list) or len(entries) < 2:
        raise ValueError("At least two public masked values are required.")
    return [decode(field, coefficients) for coefficients in entries]


def public_document(values):
    """Package the public masked values with the field definition."""
    return {
        "schema": 1,
        "profile": PROFILE,
        "key_space": "Fp",
        "parameters": {"p": str(P), "r": str(R), "degree": DEGREE, "modulus": MODULUS},
        "values": [
            {"index": i, "coefficients": encode(value)}
            for i, value in enumerate(values, start=1)
        ],
    }


def read_public(path, field):
    """Read public values and check that they use this field configuration."""
    document = json.loads(path.read_text())
    if document.get("profile") != PROFILE or document.get("key_space") != "Fp":
        raise ValueError("This is not a BLS12-381 public transcript.")

    expected_parameters = public_document([])["parameters"]
    if document.get("parameters") != expected_parameters:
        raise ValueError("The public transcript uses unexpected field parameters.")

    entries = document.get("values", [])
    if len(entries) < 2:
        raise ValueError("At least two masked values are needed to expose another key.")

    # The first item must be v1, the second v2, and so on.
    for index, entry in enumerate(entries, start=1):
        if entry.get("index") != index:
            raise ValueError("Public values must be indexed consecutively from 1.")

    return [decode(field, entry["coefficients"]) for entry in entries]
