module Sha256 exposing [Sha256.{ hash, hashToHex, hashStrToHex, hashStrToBytes }]

imports [
    Sha256.Internal.{ sha256Once }, # sha256Once : List U8 -> List U8
    Sha256.Internal.{ bytesToHex }, # bytesToHex : List U8 -> Str
    Roc.Utf8.{ toBytes }, # toBytes : Str -> List U8
]

# hash : List U8 -> List U8
#
# This is the core public hashing function. It takes a list of bytes (List U8)
# as input and returns a 32-byte list (List U8) representing the
# SHA-256 hash of the input.
hash : List U8 -> List U8
hash = \inputBytes ->
    # Call the internal sha256Once function which performs the SHA-256 algorithm
    sha256Once inputBytes

# hashToHex : List U8 -> Str
#
# This function takes a list of bytes (List U8) as input,
# computes its SHA-256 hash, and then converts the resulting
# hash bytes into a hexadecimal string representation.
hashToHex : List U8 -> Str
hashToHex = \inputBytes ->
    hashedBytes = hash inputBytes
    bytesToHex hashedBytes

# hashStrToHex : Str -> Str
#
# This function takes a string as input, converts it to a list of UTF-8 bytes,
# computes its SHA-256 hash, and then converts the resulting hash bytes
# into a hexadecimal string representation.
hashStrToHex : Str -> Str
hashStrToHex = \inputStr ->
    inputBytes = Roc.Utf8.toBytes inputStr
    hashToHex inputBytes

# hashStrToBytes : Str -> List U8
#
# This function takes a string as input, converts it to a list of UTF-8 bytes,
# and then computes and returns its SHA-256 hash as a list of bytes.
hashStrToBytes : Str -> List U8
hashStrToBytes = \inputStr ->
    inputBytes = Roc.Utf8.toBytes inputStr
    hash inputBytes
