# Finite-field attack experiment on the secret-masking step.
# The dealer creates four masked secrets using the local two-level Q.
# Secret indices are independent of hierarchy levels (paper Section 3.1).
# This is a masking-layer experiment, not a full share-distribution run.

from pathlib import Path
import sys

# Sage keeps the original script path in sys.argv[0] when preparsing.
public_values_path = Path(sys.argv[0]).resolve().with_name("public_values.txt")

# =================================================================
# SETUP: BASE FIELD, EXTENSION FIELD, AND ELLIPTIC CURVE
# =================================================================

# Base field F_47.
F47 = GF(47)

# Elliptic curve y^2 = x^3 + 4x + 15 over F_47.
E47 = EllipticCurve(F47, [4, 15])

# Construct the extension field F_(47^3) using the corrected polynomial
# described in references/references.md. This public encoding corrects the paper's
# inconsistent suggested polynomial; see attack/README.md.
F47x = PolynomialRing(F47, "X")
X = F47x.gen()
Fqk = F47.extension(X**3 + 3*X + 42, "alpha")
alpha = Fqk.gen()

# The elliptic curve and point P, now defined over F_(47^3).
E = E47.base_extend(Fqk)
P = E(24*alpha + 1, 22*alpha**2 + 10*alpha + 23)


# =================================================================
# CONSTRUCTION: THE DEALER'S MASK
# =================================================================
# The local fixture uses the first coefficients
#
#     a11 = 11,  a21 = 33.
#
# The paper constructs Q from these coefficients:
#
#     Q = a11 P + a21 P.
#
# The share-matrix calculations are omitted here because the attack
# targets the public secret-masking values, not the share construction.
# =================================================================

a11 = 11
a21 = 33
Q_dealer = (a11 + a21) * P


# =================================================================
# PAIRING
# =================================================================
def pairing(A, B):
    """Compute the modified Tate pairing e(A, B)."""
    return A.tate_pairing(B, 37, 3)


# =================================================================
# PUBLIC VALUES: v_i = e(P, iQ) + K_i
# =================================================================
# All keys are secrets in the base field F_47, embedded in F_(47^3).
# The attacker will not receive these values directly.
#
# Let z = e(P, Q). By bilinearity, e(P, 2Q) = z^2, so
#
#     v1 = z   + K1
#     v2 = z^2 + K2.
# =================================================================

# These four demonstration keys come from the paper's Section 5.
# Add further integers in [0, 46] here to publish more secrets.
secret_values = [8, 15, 22, 11]
if any(key < 0 or key >= 47 for key in secret_values):
    raise ValueError("The paper requires every secret to be in [0, p-1].")
keys = [Fqk(key) for key in secret_values]

z_dealer = pairing(P, Q_dealer)
public_values = [pairing(P, i * Q_dealer) + key
                 for i, key in enumerate(keys, start=1)]

# Check the bilinear relation used by the experiment.
assert all(value - key == z_dealer**i
           for i, (value, key) in enumerate(zip(public_values, keys), start=1))

print("------DEALER: PUBLIC VALUES------")
for i, value in enumerate(public_values, start=1):
    print("v{} = {}".format(i, value))


# =================================================================
# EXPORT ONLY THE PUBLIC VALUES
# =================================================================
# Store each extension-field element as its coefficients in the basis
# 1, alpha, alpha^2. Line i contains v_i.
# The attacker needs this file, not the dealer script.
# =================================================================

def encode_field_element(value):
    """Return the base-field coefficients of an extension-field value."""
    coefficients = value.polynomial().list() or [0]
    return ",".join(str(ZZ(c)) for c in coefficients)

with public_values_path.open("w") as public_file:
    for value in public_values:
        public_file.write(encode_field_element(value) + "\n")

print("\nPublic values written to", public_values_path)
