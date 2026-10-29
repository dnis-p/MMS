#!/usr/bin/env python3
"""Minimal APK Signature Scheme v2 signer.

Used to sign the unsigned APK that Godot exports when the Android SDK's
`apksigner` is not available (e.g. in sandboxed CI). v2 alone is accepted by
Android 7.0+ (API 24), which is Godot 4's minimum SDK.

If you have the Android SDK installed, prefer letting Godot sign with
`apksigner` directly and ignore this script.

Usage:
  sign_apk_v2.py --key key.pem --cert cert.der IN.apk OUT.apk
  sign_apk_v2.py --gen-key key.pem cert.der      # create a debug key pair
"""

import argparse
import datetime
import hashlib
import struct
import sys

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.x509.oid import NameOID

EOCD_MAGIC = 0x06054B50
APK_SIG_BLOCK_MAGIC = b"APK Sig Block 42"
V2_BLOCK_ID = 0x7109871A
SIG_RSA_PKCS1_SHA256 = 0x0103
CHUNK = 1024 * 1024


def lp(data: bytes) -> bytes:
    """uint32 little-endian length prefix."""
    return struct.pack("<I", len(data)) + data


def find_eocd(apk: bytes) -> int:
    # EOCD is 22 bytes + up to 65535 bytes of comment.
    for off in range(len(apk) - 22, max(-1, len(apk) - 22 - 65536), -1):
        if struct.unpack_from("<I", apk, off)[0] == EOCD_MAGIC:
            comment_len = struct.unpack_from("<H", apk, off + 20)[0]
            if off + 22 + comment_len == len(apk):
                return off
    raise ValueError("End of central directory not found")


def chunked_digest(sections) -> bytes:
    chunk_digests = []
    for sec in sections:
        for i in range(0, len(sec), CHUNK):
            chunk = sec[i:i + CHUNK]
            chunk_digests.append(
                hashlib.sha256(b"\xa5" + struct.pack("<I", len(chunk)) + chunk).digest())
    return hashlib.sha256(
        b"\x5a" + struct.pack("<I", len(chunk_digests)) + b"".join(chunk_digests)).digest()


def sign(in_path, out_path, key_path, cert_path):
    apk = open(in_path, "rb").read()
    eocd_off = find_eocd(apk)
    cd_size, cd_off = struct.unpack_from("<II", apk, eocd_off + 12)
    if cd_off + cd_size != eocd_off:
        raise ValueError("Central directory is not immediately followed by EOCD")
    if apk[cd_off - 16:cd_off] == APK_SIG_BLOCK_MAGIC:
        raise ValueError("APK already contains a signing block")

    entries = apk[:cd_off]
    central_dir = apk[cd_off:eocd_off]
    eocd = apk[eocd_off:]
    # The EOCD's CD offset must point at the signing block, which is inserted
    # exactly at cd_off, so the unsigned EOCD is already the value to digest.
    digest = chunked_digest([entries, central_dir, eocd])

    key = serialization.load_pem_private_key(open(key_path, "rb").read(), password=None)
    cert_der = open(cert_path, "rb").read()
    pubkey_der = key.public_key().public_bytes(
        serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)

    digests = lp(lp(struct.pack("<I", SIG_RSA_PKCS1_SHA256) + lp(digest)))
    certs = lp(lp(cert_der))
    signed_data = digests + certs + lp(b"")
    signature = key.sign(signed_data, padding.PKCS1v15(), hashes.SHA256())
    signatures = lp(lp(struct.pack("<I", SIG_RSA_PKCS1_SHA256) + lp(signature)))
    signer = lp(signed_data) + signatures + lp(pubkey_der)
    v2_value = lp(lp(signer))

    pair = struct.pack("<Q", 4 + len(v2_value)) + struct.pack("<I", V2_BLOCK_ID) + v2_value
    block_size = len(pair) + 8 + 16
    block = struct.pack("<Q", block_size) + pair + struct.pack("<Q", block_size) + APK_SIG_BLOCK_MAGIC

    new_eocd = bytearray(eocd)
    struct.pack_into("<I", new_eocd, 16, cd_off + len(block))
    with open(out_path, "wb") as f:
        f.write(entries + block + central_dir + bytes(new_eocd))


def gen_key(key_path, cert_path):
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Android Debug")])
    now = datetime.datetime.now(datetime.timezone.utc)
    cert = (x509.CertificateBuilder()
            .subject_name(name).issuer_name(name)
            .public_key(key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(now - datetime.timedelta(days=1))
            .not_valid_after(now + datetime.timedelta(days=365 * 30))
            .sign(key, hashes.SHA256()))
    with open(key_path, "wb") as f:
        f.write(key.private_bytes(serialization.Encoding.PEM,
                                  serialization.PrivateFormat.PKCS8,
                                  serialization.NoEncryption()))
    with open(cert_path, "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.DER))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--gen-key", nargs=2, metavar=("KEY_PEM", "CERT_DER"))
    p.add_argument("--key")
    p.add_argument("--cert")
    p.add_argument("paths", nargs="*")
    a = p.parse_args()
    if a.gen_key:
        gen_key(*a.gen_key)
        return 0
    if not (a.key and a.cert and len(a.paths) == 2):
        p.error("signing needs --key, --cert, IN.apk and OUT.apk")
    sign(a.paths[0], a.paths[1], a.key, a.cert)
    return 0


if __name__ == "__main__":
    sys.exit(main())
