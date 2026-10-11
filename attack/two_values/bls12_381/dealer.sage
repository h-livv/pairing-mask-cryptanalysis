"""Create public masked values for the large-prime experiment.

Run this first: sage attack/two_values/bls12_381/dealer.sage
It writes public_values.txt. The file contains no secret keys or mask z.
"""

import secrets
import sys
from pathlib import Path

from sage.all import ZZ

# Sage preserves the original script path in sys.argv[0].
SCRIPT_DIR = Path(sys.argv[0]).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from public_parameters import P, R, make_field, save_public
from curve import generators, pairing

# Experiment settings. Four 256-bit secrets are enough for the demonstration.
NUMBER_OF_SECRETS = 4
KEY_BITS = 256
PUBLIC_FILE = SCRIPT_DIR / "public_values.txt"

# ------------------------------------------------------------------
# 1. Set up the pairing and choose the dealer's private mask.
# ------------------------------------------------------------------
field = make_field()
g1, g2 = generators(field)

# The scalar is private. Q = scalar * G2 represents the dealer's Q.
scalar = ZZ(secrets.randbelow(int(R) - 1) + 1)
Q = scalar * g2
z = pairing(g1, Q)

if z == 1 or z**R != 1:
    raise ValueError("Expected a non-identity mask of order r.")

# ------------------------------------------------------------------
# 2. Choose the secrets and publish v_i = z^i + K_i.
# ------------------------------------------------------------------
keys = [secrets.randbits(KEY_BITS) for _ in range(NUMBER_OF_SECRETS)]
values = []

for i, key in enumerate(keys, start=1):
    # Compute the pairing directly, as in the scheme.
    mask = pairing(g1, i * Q)

    # Bilinearity says e(G1, iQ) = e(G1, Q)^i = z^i.
    if mask != z**i:
        raise ValueError("Pairing bilinearity check failed.")

    values.append(mask + field(key))

# Only v_1, ..., v_n are written to the public transcript.
save_public(PUBLIC_FILE, values)

print("Published {} masked secrets to {}.".format(NUMBER_OF_SECRETS, PUBLIC_FILE))
print("The secret keys, scalar, Q, and z were not written to the public file.")
