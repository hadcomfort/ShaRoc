module TestSha256 exposes [main]

imports [
    roc/Test exposing [describe, test, expectEq],
    ../src/Sha256 exposing [Sha256],
    ../src/Sha256/Internal exposing [bytesToHex, padMessage, u32sToBytes], # Added u32sToBytes
    roc/Str,
    roc/List,
    roc/Num, # Added Num
    roc/Bitwise # Added Bitwise
]

# Helper function to generate the expected 8-byte length suffix
expectedLenBytes = \originalLenBits ->
    [
        Num.toU8 (Bitwise.shiftRightBy originalLenBits 56),
        Num.toU8 (Bitwise.shiftRightBy originalLenBits 48),
        Num.toU8 (Bitwise.shiftRightBy originalLenBits 40),
        Num.toU8 (Bitwise.shiftRightBy originalLenBits 32),
        Num.toU8 (Bitwise.shiftRightBy originalLenBits 24),
        Num.toU8 (Bitwise.shiftRightBy originalLenBits 16),
        Num.toU8 (Bitwise.shiftRightBy originalLenBits 8),
        Num.toU8 originalLenBits,
    ]

# Helper function to verify padding properties
verifyPadding = \originalMsg, paddedMsg, testNamePrefix ->
    originalLenBytes = List.len originalMsg
    originalLenBits = Num.toU64 originalLenBytes * 8

    # Verification a: Total length is a multiple of 64
    expectEq (Num.remBy (List.len paddedMsg) 64) 0 "$(testNamePrefix): Padded length multiple of 64"

    # Verification b: 0x80 byte
    when List.get paddedMsg originalLenBytes is
        Ok val -> expectEq val 0x80 "$(testNamePrefix): Padding starts with 0x80"
        Err _ -> Test.fail "$(testNamePrefix): Failed to get 0x80 byte at index $(Num.toStr originalLenBytes)"

    # Verification c: Number of zero bytes
    # Padded data part = msg + 0x80 + zeros. Length of this should be 56 mod 64.
    # Total length = len(msg) + 1 (for 0x80) + numZeroBytes + 8 (for length field)
    # numZeroBytes = Total length - len(msg) - 1 - 8
    numZeroBytesCalculated = (List.len paddedMsg) - originalLenBytes - 1 - 8

    # Check each zero byte individually
    # Start index of zero bytes is originalLenBytes + 1
    # End index (exclusive) of zero bytes is originalLenBytes + 1 + numZeroBytesCalculated
    if numZeroBytesCalculated > 0 then
        List.walk (List.range (originalLenBytes + 1) (originalLenBytes + 1 + numZeroBytesCalculated)) (Ok {}) <| \acc, index ->
            when acc is
                Ok {} ->
                    when List.get paddedMsg index is
                        Ok 0x00 -> Ok {}
                        Ok other -> Err "$(testNamePrefix): Expected 0x00 at zero padding index $(Num.toStr index), got $(Num.toHex other)"
                        Err _ -> Err "$(testNamePrefix): Failed to get byte at zero padding index $(Num.toStr index)"
                Err err -> Err err
        |> Result.mapError Test.fail
        |> ignore # Discard the Ok {} result if successful
    else if numZeroBytesCalculated < 0 then
        Test.fail "$(testNamePrefix): Calculated negative number of zero bytes: $(Num.toStr numZeroBytesCalculated)"
    # If numZeroBytesCalculated is 0, no zero bytes to check, which is fine.

    # Verification d: Last 8 bytes are original length in bits (big-endian)
    expectedLenSuffix = expectedLenBytes originalLenBits
    actualLenSuffix = List.slice paddedMsg (List.len paddedMsg - 8) (List.len paddedMsg)
    expectEq actualLenSuffix expectedLenSuffix "$(testNamePrefix): Length bytes correct"

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

        describe "padMessage Tests" [
            test "empty message" <| \{} ->
                originalMsg = []
                padded = padMessage originalMsg # Using direct padMessage from import
                verifyPadding originalMsg padded "Empty message",

            test "short message \"abc\"" <| \{} ->
                originalMsg = Str.toUtf8 "abc" # [0x61, 0x62, 0x63]
                padded = padMessage originalMsg
                verifyPadding originalMsg padded "\"abc\"",

            test "55-byte message" <| \{} ->
                originalMsg = List.repeat 0x41 55 # 55 'A's
                padded = padMessage originalMsg
                verifyPadding originalMsg padded "55-byte message",

            test "56-byte message" <| \{} ->
                originalMsg = List.repeat 0x41 56 # 56 'A's
                padded = padMessage originalMsg
                verifyPadding originalMsg padded "56-byte message",

            test "63-byte message" <| \{} ->
                originalMsg = List.repeat 0x41 63 # 63 'A's
                padded = padMessage originalMsg
                verifyPadding originalMsg padded "63-byte message",

            test "64-byte message" <| \{} ->
                originalMsg = List.repeat 0x41 64 # 64 'A's
                padded = padMessage originalMsg
                verifyPadding originalMsg padded "64-byte message",

            test "70-byte message" <| \{} ->
                originalMsg = List.repeat 0x41 70 # 70 'A's
                padded = padMessage originalMsg
                verifyPadding originalMsg padded "70-byte message"
        ],

        describe "hashStr NIST Vector Tests" [
            test "empty string" <| \{} ->
                expectEq (Sha256.hashStrToHex "") "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",

            test "\"abc\"" <| \{} ->
                expectEq (Sha256.hashStrToHex "abc") "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",

            test "55-byte string (padding test)" <| \{} ->
                expectEq (Sha256.hashStrToHex "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcde") "cf001c901192831856092573125f78092106111609845343c037a8c46d6a889c",

            test "56-byte string (RFC 6234 TEST2_1)" <| \{} ->
                expectEq (Sha256.hashStrToHex "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",

            test "63-byte string (padding test)" <| \{} ->
                expectEq (Sha256.hashStrToHex "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghi") "070f2a16846193990853e02a572a3c48d669e253781e0b848c97542de4e4e997",

            test "64-byte string (padding test)" <| \{} ->
                expectEq (Sha256.hashStrToHex "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij") "f01c900c85153d4e5982365d03361031000fd5cca3c6624695012f1d6f2beb96"
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
        ],

        u32sToBytesTests # Add the new test suite here
    ]

u32sToBytesTests =
    describe "u32sToBytes Tests" [
        test "empty list" <| \{} ->
            expectEq (u32sToBytes []) ([] : List U8) "Empty list converts to empty list",

        test "one U32" <| \{} ->
            expectEq (u32sToBytes [0x01020304]) ([0x01, 0x02, 0x03, 0x04] : List U8) "Single U32",

        test "multiple U32s" <| \{} ->
            expectEq
                (u32sToBytes [0x01020304, 0x05060708])
                ([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08] : List U8)
                "Multiple U32s",

        test "U32 with leading zeros in bytes" <| \{} ->
            expectEq (u32sToBytes [0x00112233]) ([0x00, 0x11, 0x22, 0x33] : List U8) "Leading zero bytes",

        test "U32 with 0xFF bytes" <| \{} ->
            expectEq (u32sToBytes [0xFFEEDDCC]) ([0xFF, 0xEE, 0xDD, 0xCC] : List U8) "0xFF bytes",

        test "list of all zeros U32" <| \{} ->
            expectEq
                (u32sToBytes [0x00000000, 0x00000000])
                ([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] : List U8)
                "All zeros U32s",

        test "list of all 0xFFFFFFFF U32" <| \{} ->
            expectEq (u32sToBytes [0xFFFFFFFF]) ([0xFF, 0xFF, 0xFF, 0xFF] : List U8) "All 0xFFFFFFFF U32"
    ]
