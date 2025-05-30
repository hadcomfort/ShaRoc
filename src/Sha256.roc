module Sha256 exposing [Sha256.{ hash }]

imports [
    Sha256.Internal.{ sha256Once }, # sha256Once : List U8 -> List U8
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
