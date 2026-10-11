"""The public BLS12-381 curve generators and reduced Tate pairing.

The large hexadecimal constants are the standard G1 and G2 generators.
They are public parameters, not secrets. The pairing produces the mask z.
"""

import sys
from pathlib import Path

# Sage direct execution uses sage.all globals; imports use this module path.
module_path = sys.argv[0] if __name__ == "sage.all" else __file__
sys.path.insert(0, str(Path(module_path).resolve().parent))

from sage.all import EllipticCurve
from public_parameters import P, R, DEGREE


def generators(field):
    """Return the standard order-r points G1 and G2 on E over Fp^12."""
    w = field.gen()

    # This extension representation makes u = w^6 - 1 satisfy u^2 = -1.
    u = w**6 - 1
    if u**2 != -1:
        raise ValueError("The Fp^12 extension field was constructed incorrectly.")

    curve = EllipticCurve(field, [0, 4])  # y^2 = x^3 + 4

    # Standard BLS12-381 G1 generator, whose coordinates are in Fp.
    G1 = curve(
        0x17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb,
        0x08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1,
    )

    # Standard G2 coordinates are first given on a twist. These expressions
    # map that point onto our curve over Fp^12.
    x = (
        field(0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8)
        + field(0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e) * u
    )
    y = (
        field(0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801)
        + field(0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be) * u
    )
    if y**2 != x**3 + 4 * (u + 1):
        raise ValueError("The standard G2 point is not on its twist.")

    G2 = curve(x / w**2, y / w**3)

    # Confirm both generators have order r.
    if G1.is_zero() or G2.is_zero() or not (R * G1).is_zero() or not (R * G2).is_zero():
        raise ValueError("The curve generators do not have order r.")

    return G1, G2


def pairing(G1, G2):
    """Compute the reduced Tate pairing e(G1, G2) in Fp^12."""
    return G1.tate_pairing(G2, R, DEGREE, q=P)
