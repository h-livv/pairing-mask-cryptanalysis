"""Recover the mask and keys using only public_values.txt.

Run after dealer.sage: sage attack/two_values/bls12_381/attacker.sage
No curve or dealer code is needed for the attack itself.
"""

import sys
from pathlib import Path

# Sage preserves the original script path in sys.argv[0].
SCRIPT_DIR = Path(sys.argv[0]).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from public_parameters import R, P, make_field, load_public

PUBLIC_FILE = SCRIPT_DIR / "public_values.txt"
field = make_field()
values = load_public(PUBLIC_FILE, field)
v1, v2 = values[0], values[1]

# ------------------------------------------------------------------
# 1. Cancel the first two secrets with the p-th power Frobenius map.
# ------------------------------------------------------------------
# Every key K_i is in Fp, so K_i^p = K_i.
# Therefore A = v1^p - v1 = z^p - z.
# Similarly B = v2^p - v2 = z^(2p) - z^2.
A = v1**P - v1
B = v2**P - v2

# The mask has order r. Since gcd(p - 1, r) = 1, a mask in Fp
# would have to be 1. The dealer excludes z = 1, so A must be nonzero.
if A == 0:
    raise ValueError("A is zero; the expected non-identity mask condition failed.")

# From z^p = z + A:
# B = (z^p)^2 - z^2 = (z + A)^2 - z^2 = 2*A*z + A^2.
# Solve this equation for z.
z = (B - A**2) / (2 * A)

# Check that the recovered mask belongs to the public order-r subgroup.
if z**R != 1:
    raise ValueError("Recovered mask is not an r-th root of unity.")

print("Recovered mask z from public values v1 and v2.")

# ------------------------------------------------------------------
# 2. Recover every key: K_i = v_i - z^i.
# ------------------------------------------------------------------
for i, value in enumerate(values, start=1):
    key = value - z**i
    coefficients = list(key.polynomial())
    coefficients += [0] * (12 - len(coefficients))

    # A valid key lies in the base field Fp, so only coefficient 0
    # may be nonzero in its extension-field representation.
    if any(coefficients[1:]):
        raise ValueError("Recovered value K{} is not in Fp.".format(i))

    print("Recovered K{} = {}".format(i, int(coefficients[0])))
