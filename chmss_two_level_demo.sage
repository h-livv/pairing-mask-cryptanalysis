# Foundation for Chintamani, Paul, and Sa, Section 5.
# Levels 1 and 2 only, and one secret.

# =================================================================
# SETUP: BASE FIELD, EXTENSION FIELD, AND ELLIPTIC CURVE
# =================================================================
# This section constructs the mathematical objects used throughout
# the scheme: F47, F47^3, the elliptic curve E, and the point P.
# =================================================================

# Galois Field - Constructs the finite field F47.
# Arithmetic is done in the field F47 (mod 47).
# {0, 1, 2,...., 46}
# F47 is an object representing the field.
F47 = GF(47)

# Constructs the elliptic curve y^2 = x^3 + 4x + 15 over the field F47.
# (x, y) is in F47 x F47.
E47 = EllipticCurve(F47, [4, 15])

# All polynomials where every coefficient comes from F47.
# Ex. 50X^2+100X+3 becomes 3X^2+6X+3
F47x = PolynomialRing(F47, "X") 

# Generates the actual variable X that can be used to construct any polynomial in F47x.
X = F47x.gen()

# Irreducible cubic polynomial X^3 + 3X + 42 over F47x.
# .extension extends the field adding a root of the polynomial - alpha.
# Every element can be written a + b*alpha + c*alpha^2 with a, b, c (mod 47).
# (a, b, c) have 47^3 possible choices, hence extending the field.
Fqk = F47.extension(X**3 + 3*X + 42, "alpha")

# Generates alpha, the newly added root.
# Any polynomial written in alpha will be in the extended field.
alpha = Fqk.gen()

# Creates the same elliptic curve equation, but over our larger extended field = E(Fqk)
E = E47.base_extend(Fqk)

# Constructing the point P in E[37] (the 37 torsion points of the elliptic curve E).
# E[37] = {P in E : 37P = O} where O is a point at infinity = identity element of the group.
P = E(24*alpha + 1, 22*alpha**2 + 10*alpha + 23)

# Finite field F37.
F37 = GF(37)

# The picture till now:
# An elliptic curve was selected over F47.
# E(F47) is the set of points on E, and its cardinality turns out to be 37.
# Embedding degree 37 | 47^3 - 1 is found to be 3, hence F47^3 (Fqk) is constructed.
# Point P is created, which is in E[37] which is a subset of E(Fqk).
# A cyclic subgroup is generated with P as the generator.


print("------SETTING UP AND DISTRIBUTION OF THE PARAMETERS OF THE SCHEME------")
print("")

# =================================================================
# CONSTRUCTION: LINEAR SHARES AT LEVELS 1 AND 2
# =================================================================
# The dealer constructs scalar shares using
#
#     b = M a
#
# and then converts those scalar shares into elliptic-curve points
# b_i P, which are distributed to the users.
# =================================================================

# -----------------------------------------------------------------
# CONSTRUCTION: LEVEL 1
#
# t1 = 1
# n1 = 2
# -----------------------------------------------------------------

# Create M1 with elements in F37.
# One row corresponds to one user.
M1 = matrix(F37, [
    [3], 
    [4]
])

# Random integer a11 in F37, this is the hidden coefficient.
# Column matrix.
a11 = vector(F37, [11])

# Generate the shares (b1).
b1 = M1 * a11

# b1's entries are mod-37 field elements. 
# ZZ(x) turns them into a Python integer in {0..36}.
print("level-1 shares =", [ZZ(x) for x in b1])

# -----------------------------------------------------------------
# CONSTRUCTION: LEVEL 2
#
# t2 = 3
# n2 = 3
# -----------------------------------------------------------------

# Encoding matrix.
# Level 2 is selected in such a way that the old b1 and b2 remain unchanged.
M = matrix(F37, [
    [4, 6, 1],   # u11
    [2, 5, 8],   # u12
    [1, 0, 9],   # u21
    [5, 2, 10],  # u22
    [7, 3, 11],  # u23
])

# Hidden coefficients.
a = vector(F37, [33, 32, 5])

# Scalar shares.
b = M * a

print("b = M a =", [ZZ(x) for x in b])

# -----------------------------------------------------------------
# The users are given the points b_i P, not the integers b_i.
# M is public, so the integers b would let a square set of users
# solve b' = M' a for the coefficient vector itself.
# -----------------------------------------------------------------

share_points = [ZZ(x) * P for x in b]

# ---------------------------------------------------------------
# PAIRING: TREATED AS A BLACK BOX
# ---------------------------------------------------------------

def pairing(A, B):
    """
    Black box for the modified Tate pairing e(A, B).
    """
    return A.tate_pairing(B, 37, 3)


# ---------------------------------------------------------------
# SECRET: ONE-SECRET RECOVERY
# ---------------------------------------------------------------
# The paper publishes:
#
#     v = e(P, Q) + K
#
# Here we use K1 = 8 from the numerical example.
# ---------------------------------------------------------------

K = Fqk(8)

Q_dealer = (ZZ(a11[0]) + ZZ(a[0])) * P

v = pairing(P, Q_dealer) + K

print("v =", v)




# =================================================================
# RECONSTRUCTION: SECTION 3.2
# =================================================================
# Authorized users use their point shares to recover the required
# coefficient points, construct Q, and finally recover the secret.
# =================================================================
print("")
print("------RECONSTRUCTION OF THE SECRETS------")
print("")

# ---------------------------------------------------------------
# RECONSTRUCTION: LEVEL 1
# ---------------------------------------------------------------
# Collaborating user:
#
#     u11
#
# From M1 = [3, 4]^T, the corresponding 1 x 1 submatrix is [3].
#
# The paper computes:
#   
#   a11 P = M'^(-1) (b11 P)
#   a11 P = 3^(-1) (b11 P)
#
# We work directly with the elliptic-curve point b11 P.
# The integer a11 itself is never recovered.
# ---------------------------------------------------------------

M1_prime = matrix(F37, [[3]])

a11P = ZZ(M1_prime.inverse()[0, 0]) * share_points[0]

print("a11 P recovered:", a11P)


# ---------------------------------------------------------------
# RECONSTRUCTION: LEVEL 2
# ---------------------------------------------------------------
# Suppose u11, u21, u23 collaborate.
#
# Their shares are:
#
#     u11 -> 33P
#     u21 ->  4P
#     u23 -> 12P
#
# Take the corresponding rows of M2:
#
#     M2' =
#     [4 6  1]
#     [1 0  9]
#     [7 3 11]
#
# Then the paper computes:
#
#     M2'^(-1) (33P, 4P, 12P)^T
#
#     = (a21P, a22P, a23P)^T
#
# Again, the users recover points, not the scalar coefficients.
# ---------------------------------------------------------------

M2_prime = matrix(F37, [
    [4, 6, 1],    # u11
    [1, 0, 9],     # u21
    [7, 3, 11],   # u23
])

M2_inv = M2_prime.inverse()

chosen_shares = [
    share_points[0],   # 33P
    share_points[2],   # 4P
    share_points[4],   # 12P
]


# Apply M2'^(-1) to the vector of elliptic-curve points.
a2P = []

for i in range(3):
    point = E(0)

    for j in range(3):
        point += ZZ(M2_inv[i, j]) * chosen_shares[j]

    a2P.append(point)

a21P = a2P[0]

print("a21 P recovered:", a21P)


# ---------------------------------------------------------------
# RECONSTRUCTION: CONSTRUCT Q
# ---------------------------------------------------------------
# The paper defines:
#
#     Q = sum_j a_{j1} P
#
# With only Levels 1 and 2 implemented:
#
#     Q = a11 P + a21 P
# ---------------------------------------------------------------

Q = a11P + a21P

print("Q =", Q)


# An authorized set reconstructs Q, evaluates the same pairing,
# and obtains:
#
#     K = v - e(P, Q)
# ---------------------------------------------------------------

recovered_K = v - pairing(P, Q)

print("recovered K =", recovered_K)