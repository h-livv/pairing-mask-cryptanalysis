"""Recover every key after just K1 is leaked.

Run: sage attack/one_key/bls12_381/attacker.sage
When prompted, enter the leaked K1 printed by dealer.sage.

The attacker reads public_values.txt and the one leaked key only.
It does not construct the curve or compute a pairing.
"""

import sys
from pathlib import Path

from sage.all import ZZ

# Sage preserves the original script path in sys.argv[0].
SCRIPT_DIR = Path(sys.argv[0]).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from public_parameters import P, R, make_field, read_public

PUBLIC_FILE = SCRIPT_DIR / "public_values.txt"


# --------------------------------------------------------------------
# 1. Read public data and the one compromised key.
# --------------------------------------------------------------------

field = make_field()
public_values = read_public(PUBLIC_FILE, field)

# This is the attack's only secret input: the leaked first key K1.
leaked_K1 = ZZ(input("Enter the leaked K1: ").strip())
if not 0 <= leaked_K1 < P:
    raise ValueError("K1 must be an integer in the base field Fp.")


# --------------------------------------------------------------------
# 2. Recover the common mask z.
# --------------------------------------------------------------------

# Public rule: v1 = z + K1. Since K1 is now known, subtract it.
z = public_values[0] - field(leaked_K1)

# The mask must be a non-identity element of the order-r pairing subgroup.
if z == 1 or z**R != 1:
    raise ValueError("The supplied K1 did not produce a valid mask.")

print("Recovered z = v1 - K1 using only public data and leaked K1.")


# --------------------------------------------------------------------
# 3. Recover each remaining key.
# --------------------------------------------------------------------

for i, value in enumerate(public_values, start=1):
    # Public rule: vi = z^i + Ki, so Ki = vi - z^i.
    key_as_field_element = value - z**i

    # A key belongs to Fp. In the 12-coefficient extension representation,
    # only the constant coefficient may be nonzero.
    coefficients = list(key_as_field_element.polynomial())
    coefficients += [0] * (12 - len(coefficients))
    if any(coefficients[1:]):
        raise ValueError("Recovered K{} is not in the base field Fp.".format(i))

    key = ZZ(coefficients[0])
    if i == 1 and key != leaked_K1:
        raise ValueError("The leaked K1 does not match the public transcript.")

    print("Recovered K{} = {}".format(i, key))
