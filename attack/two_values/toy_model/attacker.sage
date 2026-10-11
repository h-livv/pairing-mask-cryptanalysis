# Recover secrets using only the published values v1, v2, ... .
# No elliptic-curve point, share, coefficient, or secret is used here.

from pathlib import Path
import sys

# Sage keeps the original script path in sys.argv[0] when preparsing.
public_values_path = Path(sys.argv[0]).resolve().with_name("public_values.txt")

# =================================================================
# PUBLIC FIELD PARAMETERS
# =================================================================
# These are the same public field parameters used by the dealer.
# The attacker needs the extension-field definition to interpret the
# published coefficients in public_values.txt. This is a public encoding
# convention, not a secret: see attack/README.md for the paper's polynomial issue.
# Section 3.1: keys are in the prime field; Section 5: p=47, ell=37.
# =================================================================

F47 = GF(47)
F47x = PolynomialRing(F47, "X")
X = F47x.gen()
Fqk = F47.extension(X**3 + 3*X + 42, "alpha")
alpha = Fqk.gen()
q = 47
ell = 37


# =================================================================
# READ THE PUBLIC VALUES
# =================================================================
def decode_field_element(coefficients):
    """Rebuild an extension-field element from its power-basis coefficients."""
    value = Fqk(0)
    for i, coefficient in enumerate(coefficients):
        value += Fqk(coefficient) * alpha**i
    return value


def read_coefficients(line):
    """Read comma-separated coefficients from one line of the public file."""
    coefficients = [ZZ(c.strip()) for c in line.strip().split(",")]
    if not 1 <= len(coefficients) <= 3 or any(c < 0 or c >= q for c in coefficients):
        raise ValueError("Expected 1 to 3 public coefficients in [0, 46].")
    return coefficients

with public_values_path.open("r") as public_file:
    public_values = [decode_field_element(read_coefficients(line)) for line in public_file]
if len(public_values) < 2:
    raise ValueError("This attack needs published v1 and v2 (indices 1 and 2).")

v1, v2 = public_values[:2]

print("------ATTACKER: PUBLIC INPUTS------")
print("v1 =", v1)
print("v2 =", v2)


# =================================================================
# RECOVER THE COMMON MASK z
# =================================================================
# The secrets K1 and K2 lie in F_47, so K_i^47 = K_i.
# From v1 = z + K1 and v2 = z^2 + K2, compute
#
#     A = v1^q - v1 = z^q - z
#     B = v2^q - v2 = z^(2q) - z^2.
#
# Since z^q = z + A,
#
#     B = (z + A)^2 - z^2 = 2Az + A^2.
#
# Therefore z = (B - A^2) / (2A), provided A != 0.
# =================================================================

A = v1**q - v1
B = v2**q - v2

if A == 0:
    # z lies in both F_47^* (order 46) and mu_37. Their intersection
    # is {1}, since gcd(46, 37)=1. No private information is needed.
    if gcd(q - 1, ell) != 1:
        raise ValueError("Base-field mask is ambiguous for these public parameters.")
    z_recovered = Fqk(1)
else:
    z_recovered = (B - A**2) / (2 * A)

if z_recovered**ell != 1:
    raise ValueError("Public values do not satisfy the claimed pairing subgroup.")

print("\nRecovered common mask z =", z_recovered)


# =================================================================
# RECOVER THE SECRETS
# =================================================================
# Rearrange v1 = z + K1 and v2 = z^2 + K2.
# =================================================================

recovered_keys = [v - z_recovered**i for i, v in enumerate(public_values, start=1)]
K1_recovered, K2_recovered = recovered_keys[:2]

for i, key in enumerate(recovered_keys, start=1):
    if key**q != key:
        raise ValueError("Recovered value is outside the paper's prime-field key space.")
    print("Recovered K{} = {}".format(i, key))

print("\nAll recovered values lie in F_47.")
