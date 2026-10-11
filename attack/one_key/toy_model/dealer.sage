from pathlib import Path
import sys

PUBLIC_FILE = Path(sys.argv[0]).resolve().with_name("public_values.txt")

# Finite-field attack experiment on the secret-masking step.
# The dealer creates two public values for Levels 1 and 2.

# =================================================================
# SETUP: BASE FIELD, EXTENSION FIELD, AND ELLIPTIC CURVE
# =================================================================

# Base field F_47.
F47 = GF(47)

# Elliptic curve y^2 = x^3 + 4x + 15 over F_47.
E47 = EllipticCurve(F47, [4, 15])

# Construct the extension field F_(47^3) using the same polynomial
# as in chmss_two_level_demo.sage.
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
# In chmss_two_level_demo.sage, the first coefficients are
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
# K1 and K2 are secrets in the base field F_47, embedded in F_(47^3).
# The attacker will not receive these values directly.
#
# Let z = e(P, Q). By bilinearity, e(P, 2Q) = z^2, so
#
#     v1 = z   + K1
#     v2 = z^2 + K2.
# =================================================================

K1 = Fqk(8)
K2 = Fqk(15)

z_dealer = pairing(P, Q_dealer)
v1 = z_dealer + K1
v2 = pairing(P, 2 * Q_dealer) + K2

# Check the bilinear relation used by the experiment.
assert pairing(P, 2 * Q_dealer) == z_dealer**2

print("------DEALER: PUBLIC VALUES------")
print("v1 =", v1)
print("v2 =", v2)


# =================================================================
# EXPORT ONLY THE PUBLIC VALUES
# =================================================================
# Store each extension-field element as its coefficients in the basis
# 1, alpha, alpha^2. The first line is v1; the second line is v2.
# The attacker needs this file, not the dealer script.
# =================================================================

def encode_field_element(value):
    """Return the base-field coefficients of an extension-field value."""
    coefficients = value.polynomial().list()
    return ",".join(str(ZZ(c)) for c in coefficients)

with PUBLIC_FILE.open("w") as public_file:
    public_file.write(encode_field_element(v1) + "\n")
    public_file.write(encode_field_element(v2) + "\n")

print("\nPublic values written to", PUBLIC_FILE)
