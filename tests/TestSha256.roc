module TestSha256 exposes [main]

imports [
    roc/Test exposing [describe, test, expectEq],
    ../src/Sha256 exposing [Sha256],
    ../src/Sha256/Internal exposing [bytesToHex],
    roc/Str,
    roc/List
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
        ],

        describe "hashToHex NIST Byte Vector Tests" [
            test "empty byte list" <| \{} ->
                expectEq (Sha256.hashToHex []) "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",

            test "byte list for \"abc\"" <| \{} ->
                expectEq (Sha256.hashToHex [0x61, 0x62, 0x63]) "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",

            test "byte list for \"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq\"" <| \{} ->
                expectEq (Sha256.hashToHex [
                    0x61, 0x62, 0x63, 0x64, 0x62, 0x63, 0x64, 0x65, 0x63, 0x64, 0x65, 0x66,
                    0x64, 0x65, 0x66, 0x67, 0x65, 0x66, 0x67, 0x68, 0x66, 0x67, 0x68, 0x69,
                    0x67, 0x68, 0x69, 0x6A, 0x68, 0x69, 0x6A, 0x6B, 0x69, 0x6A, 0x6B, 0x6C,
                    0x6A, 0x6B, 0x6C, 0x6D, 0x6B, 0x6C, 0x6D, 0x6E, 0x6C, 0x6D, 0x6E, 0x6F,
                    0x6D, 0x6E, 0x6F, 0x70, 0x6E, 0x6F, 0x70, 0x71
                ]) "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",

            test "Million 'a's (RFC 6234 TEST3)" <| \{} ->
                # Create a list of 1,000,000 'a' characters (0x61)
                millionAs = List.repeat 0x61 1_000_000
                expectEq (Sha256.hashToHex millionAs) "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0",

            test "Exact block size message (RFC 6234 TEST4) - 64 bytes" <| \{} ->
                # Input: "0123456701234567012345670123456701234567012345670123456701234567"
                # Hex:   3031323334353637303132333435363730313233343536373031323334353637
                #        3031323334353637303132333435363730313233343536373031323334353637
                inputBytes = Str.toUtf8 "0123456701234567012345670123456701234567012345670123456701234567"
                expectEq (Sha256.hashToHex inputBytes) "594847328451bdfa85056225462cc1d867d877fb388df0ce35f25ab5562bfbb5"
        ]
    ]
