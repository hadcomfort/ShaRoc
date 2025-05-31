module TestSha256 exposes [main]

imports [
    roc/Test exposing [describe, test, expectEq],
    ../src/Sha256 exposing [Sha256],
    ../src/Sha256/Internal exposing [bytesToHex]
]

main =
    describe "Sha256 Library Tests" [
        describe "bytesToHex Tests" [
            test "empty list" <| \{} ->
                expectEq (bytesToHex []) "",

            test "single zero byte" <| \{} ->
                expectEq (bytesToHex [0x00]) "00",

            test "single byte with leading hex zero" <| \{} ->
                expectEq (bytesToHex [0x0A]) "0a",

            test "single byte max value" <| \{} ->
                expectEq (bytesToHex [0xFF]) "ff",

            test "four bytes 'deadbeef'" <| \{} ->
                expectEq (bytesToHex [0xDE, 0xAD, 0xBE, 0xEF]) "deadbeef",

            test "multiple bytes with leading hex zeros" <| \{} ->
                expectEq (bytesToHex [0x01, 0x02, 0x03]) "010203",

            test "eight bytes common sequence" <| \{} ->
                expectEq (bytesToHex [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]) "0123456789abcdef",

            test "list of all zeros (4 bytes)" <| \{} ->
                expectEq (bytesToHex [0x00, 0x00, 0x00, 0x00]) "00000000",

            test "list of all 0xFF (4 bytes)" <| \{} ->
                expectEq (bytesToHex [0xFF, 0xFF, 0xFF, 0xFF]) "ffffffff"
        ],

        describe "hashStr NIST Vector Tests" [
            test "empty string" <| \{} ->
                expectEq (Sha256.hashStr "") "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",

            test "\"abc\"" <| \{} ->
                expectEq (Sha256.hashStr "abc") "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",

            test "55-byte string (padding test)" <| \{} ->
                expectEq (Sha256.hashStr "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcde") "cf001c901192831856092573125f78092106111609845343c037a8c46d6a889c",

            test "56-byte string (RFC 6234 TEST2_1)" <| \{} ->
                expectEq (Sha256.hashStr "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",

            test "63-byte string (padding test)" <| \{} ->
                expectEq (Sha256.hashStr "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghi") "070f2a16846193990853e02a572a3c48d669e253781e0b848c97542de4e4e997",

            test "64-byte string (padding test)" <| \{} ->
                expectEq (Sha256.hashStr "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij") "f01c900c85153d4e5982365d03361031000fd5cca3c6624695012f1d6f2beb96"
        ]
    ]
