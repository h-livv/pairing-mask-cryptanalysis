"""Dealer for the corrected numerical fixture's one-value recovery demonstration.

The dealer computes one public value v1 = e(P, Q) + K1 and writes
only that value to public_values.txt beside this script. The secret K1 and the mask z=e(P,Q)
are not written to the public file.

This reproduces the first masked value of the paper's numerical example,
using the corrected field encoding X^3 + 3*X + 42 and Q = 13P.
It does not implement the hierarchical share construction.
Unique one-value recovery is demonstrated for this fixture, not guaranteed
for arbitrary valid transcripts.

Run from the repository root: sage attack/one_value/dealer.sage
"""

from pathlib import Path
import sys
from sage.all import GF, PolynomialRing, EllipticCurve, ZZ

PUBLIC_FILE = Path(sys.argv[0]).resolve().with_name("public_values.txt")

# =====================================================================
# PUBLIC PARAMETERS: F_47^3 AND THE ELLIPTIC CURVE
# =====================================================================

p = 47
mask_order = 37

F47 = GF(p)
R = PolynomialRing(F47, "X")
X = R.gen()
Fqk = F47.extension(X**3 + 3*X + 42, "alpha")
alpha = Fqk.gen()

# E: y^2 = x^3 + 4x + 15, defined over the extension field.
E47 = EllipticCurve(F47, [4, 15])
E = E47.base_extend(Fqk)

# Public generator used by the paper's numerical example.
P = E(24*alpha + 1, 22*alpha**2 + 10*alpha + 23)
if P.is_zero() or P.order() != mask_order:
    raise ValueError("The public point must have order 37.")

# =====================================================================
# DEALER-ONLY VALUES
# =====================================================================

# In the paper's full numerical example, Q = 13P and K1 = 8.
# Q and K1 are used here only to generate the public value.
Q = 13 * P
K1 = 8

# The modified Tate pairing used in the paper's example.
def pairing(A, B):
    """Compute the modified Tate pairing e(A, B) in F_(47^3)."""
    return A.tate_pairing(B, mask_order, 3)

z = pairing(P, Q)
if z == 1 or z**mask_order != 1:
    raise ValueError("Expected a non-identity order-37 mask for this fixture.")
v1 = z + Fqk(K1)

# Encode v1 in the public basis [1, alpha, alpha^2].
# Only these three public coefficients are written to disk.
coefficients = [ZZ(c) for c in v1.polynomial().list()]
coefficients += [ZZ(0)] * (3 - len(coefficients))
coefficients = coefficients[:3]

# Sanity check against the published numerical example.
expected = [12, 28, 37]  # v1 = 12 + 28*alpha + 37*alpha^2
if coefficients != expected:
    raise ValueError(
        "Computed public coefficients {} do not match the printed fixture {}.".format(
            coefficients, expected
        )
    )

PUBLIC_FILE.write_text(" ".join(map(str, coefficients)) + "\n")

print("Dealer generated one public value.")
print("Public v1 coefficients [1, alpha, alpha^2]:", coefficients)
print("Saved to", PUBLIC_FILE)
print("The secret K1 and the mask z were not written to the public file.")
