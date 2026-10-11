"""BLS12-381 generators and a simple reduced Tate pairing wrapper."""

import sys
from pathlib import Path

# Sage direct execution uses sage.all globals; imports use this module path.
module_path = sys.argv[0] if __name__ == "sage.all" else __file__
sys.path.insert(0, str(Path(module_path).resolve().parent))

from sage.all import EllipticCurve
from public_parameters import R, DEGREE, P


def generators(field):
    """Build the standard G1 and G2 generators over Fp^12."""
    w = field.gen()
    u = w**6 - 1
    if u**2 != -1:
        raise ValueError("The extension field was constructed incorrectly.")

    # The curve is y^2 = x^3 + 4.
    curve = EllipticCurve(field, [0, 4])

    # Standard G1 generator. Its coordinates lie in the base field Fp.
    g1 = curve(
        0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb,
        0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1,
    )

    # Standard G2 generator, first represented on the twist.
    x = (field(0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8)
         + field(0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e) * u)
    y = (field(0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801)
         + field(0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be) * u)

    # Map the twist point onto the curve over the full extension field.
    if y**2 != x**3 + 4 * (u + 1):
        raise ValueError("The G2 twist point is invalid.")
    g2 = curve(x / w**2, y / w**3)

    # Both generators must have order r.
    if g1.is_zero() or g2.is_zero() or not (R * g1).is_zero() or not (R * g2).is_zero():
        raise ValueError("A generator does not have order r.")
    return g1, g2


def pairing(g1, g2):
    """Compute the reduced Tate pairing e(g1, g2) in Fp^12."""
    return g1.tate_pairing(g2, R, DEGREE, q=P)
