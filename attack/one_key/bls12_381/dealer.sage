"""Dealer for the BLS12-381 one-key-leak experiment.

Run: sage attack/one_key/bls12_381/dealer.sage

This writes the public transcript to public_values.txt. The separate
 dealer_truth.json file is only for the verifier; never give it to the attacker.
"""

import json
import secrets
import sys
from pathlib import Path

from sage.all import ZZ

# Sage preserves the original script path in sys.argv[0].
SCRIPT_DIR = Path(sys.argv[0]).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from public_parameters import P, R, make_field, public_document
from curve import generators, pairing

# Keep the experiment settings simple and fixed.
NUMBER_OF_KEYS = 4
KEY_BITS = 256
PUBLIC_FILE = SCRIPT_DIR / "public_values.txt"
PRIVATE_FILE = SCRIPT_DIR / "dealer_truth.json"


# --------------------------------------------------------------------
# 1. Set up the pairing and choose the dealer's private mask.
# --------------------------------------------------------------------

field = make_field()
G1, G2 = generators(field)

# Q is private. The scalar is chosen randomly in the order-r group.
scalar = ZZ(secrets.randbelow(int(R) - 1) + 1)
Q = scalar * G2

# z is the common mask. It is not published.
z = pairing(G1, Q)
if z == 1 or z**R != 1:
    raise ValueError("Expected a non-identity mask of order r.")


# --------------------------------------------------------------------
# 2. Choose keys and publish v_i = z^i + K_i.
# --------------------------------------------------------------------

# Each key is an integer in the base field Fp.
keys = [secrets.randbits(KEY_BITS) for _ in range(NUMBER_OF_KEYS)]
public_values = []

for i, key in enumerate(keys, start=1):
    # The paper's pairing mask is e(G1, iQ). Bilinearity says this is z^i.
    mask = pairing(G1, i * Q)
    if mask != z**i:
        raise ValueError("Pairing bilinearity check failed at index {}.".format(i))

    public_values.append(mask + field(key))

# Everyone can see these masked values. No key or Q is written here.
PUBLIC_FILE.write_text(
    json.dumps(public_document(public_values), indent=2) + "\n"
)

# This extra file exists only so the verifier can check the experiment.
# The verifier moves it away before starting the attacker.
PRIVATE_FILE.write_text(json.dumps({"keys": [str(k) for k in keys]}, indent=2) + "\n")

print("Published {} masked keys to {}.".format(NUMBER_OF_KEYS, PUBLIC_FILE))
print("For the one-key-leak demonstration, K1 is the compromised key:")
print(keys[0])
print("The other keys are kept in dealer_truth.json for verification only.")
