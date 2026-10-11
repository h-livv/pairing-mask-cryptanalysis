"""Demonstrated one-value recovery for the corrected numerical fixture.

The attacker reads v1 from public_values.txt beside this script. This script does not know K1,
construct Q, construct an elliptic curve, or calculate a pairing.

It first uses a necessary norm condition to find possible secrets, then
checks the exact condition that a valid mask must satisfy: w^37 = 1.
For the corrected fixture it recovers K1=8 using public information only.
Other valid inputs can leave multiple candidates. It reports every
consistent key; unique recovery is not guaranteed for arbitrary inputs.

Run from the repository root: sage attack/one_value/attacker.sage
"""

from pathlib import Path
import sys
from sage.all import GF, PolynomialRing, ZZ

# =====================================================================
# PUBLIC FIELD PARAMETERS
# =====================================================================

p = 47
mask_order = 37

F47 = GF(p)
R = PolynomialRing(F47, "X")
X = R.gen()
Fqk = F47.extension(X**3 + 3*X + 42, "alpha")
alpha = Fqk.gen()

# =====================================================================
# READ THE ONLY PUBLIC MASKING VALUE
# =====================================================================

# The public file contains coefficients in the basis [1, alpha, alpha^2].
# For example, "12 28 37" means 12 + 28*alpha + 37*alpha^2.
path = Path(sys.argv[0]).resolve().with_name("public_values.txt")
if not path.exists():
    raise FileNotFoundError(
        "{} not found. Run sage attack/one_value/dealer.sage first.".format(path)
    )

coefficients = [int(c) for c in path.read_text().split()]
if len(coefficients) != 3 or any(not 0 <= c < p for c in coefficients):
    raise ValueError("public_values.txt must contain three coefficients from 0 to 46.")

v1 = sum(Fqk(c) * alpha**i for i, c in enumerate(coefficients))


def norm_to_base_field(value):
    """Compute N(w) in F_47, represented inside F_(47^3)."""
    return value * value**p * value**(p**2)


def coefficients_of(value):
    """Return [constant, alpha, alpha^2] as ordinary integers."""
    result = [ZZ(c) for c in value.polynomial().list()]
    result += [ZZ(0)] * (3 - len(result))
    return result[:3]

print("=" * 64)
print("ONE-VALUE RECOVERY DEMONSTRATION: CORRECTED NUMERICAL FIXTURE")
print("Unique recovery is fixture-specific; other valid inputs can leave multiple candidates.")
print("=" * 64)
print("Read public v1 coefficients [1, alpha, alpha^2]:", coefficients)
print("The attacker does not receive K1, Q, participant shares, or a pairing result.")

# =====================================================================
# STEP 1: USE A NECESSARY NORM CONDITION TO NARROW THE CANDIDATES
# =====================================================================
# If w is a 37th root of unity, then
#
#   N(w) = w^(1 + 47 + 47^2) = w^2257 = (w^37)^61 = 1.
#
# Since v1 = z + K1, a candidate secret k implies a possible mask
# w = v1 - k.  Therefore any valid k must satisfy N(v1 - k) = 1.
# This condition is necessary, but not sufficient.

candidates = []
for k in F47:
    possible_mask = v1 - Fqk(k)
    if norm_to_base_field(possible_mask) == Fqk(1):
        candidates.append(ZZ(k))

print("\nCandidates surviving N(v1 - k) = 1:")
print(candidates)

# =====================================================================
# STEP 2: CHECK THE DEFINING MASK CONDITION
# =====================================================================
# A valid mask must satisfy w^37 = 1.  Test each remaining candidate.

valid_secrets = []
print("\nChecking (v1 - k)^37 = 1:")
for k in candidates:
    possible_mask = v1 - Fqk(k)
    mask_power = possible_mask**mask_order
    valid = (mask_power == Fqk(1))

    print(f"\n  Candidate K1 = {k}")
    print("  Coefficients of (v1 - K1)^37:", coefficients_of(mask_power))
    print("  Result:", "VALID mask" if valid else "reject candidate")

    if valid:
        valid_secrets.append(k)

print("\n" + "=" * 64)
print("Recovered secret candidate(s):", valid_secrets)
if not valid_secrets:
    raise ValueError("No prime-field secret gives an order-37 subgroup mask.")
elif len(valid_secrets) == 1:
    print("Unique recovery in this numerical example: K1 =", valid_secrets[0])
else:
    print("Ambiguous recovery: the public conditions do not identify a unique secret.")
print("=" * 64)
