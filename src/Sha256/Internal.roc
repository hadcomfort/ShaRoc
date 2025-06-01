##
# The `Sha256.Internal` module contains the core, non-public logic for the
# SHA-256 hashing algorithm.
#
# Purpose:
# This module encapsulates the detailed implementation of the SHA-256 algorithm,
# including helper functions and state management. It is not intended for direct
# external use.
#
# Disclaimer:
# The contents of this module are considered internal implementation details.
# They are subject to change without notice and should not be relied upon
# directly by external code. Use the functions exposed by the `Sha256`
# module instead.
##
module Sha256.Internal exposing [rotr, shr, smallSigma0, smallSigma1, ch, maj, bigSigma0, bigSigma1, bytesToWordsBE, InvalidInput, generateMessageSchedule, processChunk, Sha256State, sha256Once, padMessage, u32sToBytes, bytesToHex]

# Placeholder for padMessage
## padMessage : List U8 -> List U8
##
## Purpose:
##   Implements the SHA-256 padding scheme as defined in FIPS 180-4, Section 5.1.1.
##   The message is padded to ensure its total length is a multiple of 512 bits (64 bytes).
##
## Padding Steps:
##   1. Append a '1' bit to the end of the message.
##   2. Append '0' bits until the message length is 448 bits (56 bytes) modulo 512 bits (64 bytes).
##      This means the padded message (excluding the length) will be 56, 120, 184, ... bytes long.
##   3. Append the original message length as a 64-bit big-endian integer.
##
## Parameters:
##   - `message` : `List U8` - The original message bytes.
##
## Return Value:
##   - `List U8` - The padded message, ready for processing in 512-bit (64-byte) chunks.
##
## Note: This is currently a placeholder and needs the actual padding logic.
padMessage : List U8 -> List U8
padMessage = \message -> message # Actual padding logic will be implemented later

# Placeholder for u32sToBytes
## u32sToBytes : List U32 -> List U8
##
## Purpose:
##   Converts a list of eight U32 hash values (h0-h7) into a 32-byte `List U8`
##   in big-endian order. Each U32 is converted to 4 bytes.
##
## Parameters:
##   - `u32s` : `List U32` - A list containing the eight 32-bit hash values.
##
## Return Value:
##   - `List U8` - A 32-byte list representing the concatenated hash values.
##
## Note: This is currently a placeholder and needs the actual conversion logic.
u32sToBytes : List U32 -> List U8
u32sToBytes = \_u32s -> List.repeat 0 32 # Actual conversion logic will be implemented later (expects 8 U32s, returns 32 U8s)

## bytesToHex : List U8 -> Str
##
## Purpose:
##   Converts a list of bytes (typically a hash result) into its human-readable
##   hexadecimal string representation. Each byte is converted to two hex characters.
##
## Parameters:
##   - `bytes` : `List U8` - The list of bytes to convert.
##
## Return Value:
##   - `Str` - The hexadecimal string representation of the input bytes.
##
## Example:
##   bytesToHex [0xA4, 0xB7, 0x3F] == "a4b73f" (actual output might be uppercase based on Num.toHex)
bytesToHex : List U8 -> Str
bytesToHex = \bytes ->
    bytes
        |> List.walk "" \acc, byte ->
            hexByte = Num.toHex byte
            if Str.countChars hexByte == 1 then
                acc |> Str.concat "0" |> Str.concat hexByte
            else
                acc |> Str.concat hexByte

## Sha256State
##
## Purpose:
## This record holds the eight 32-bit words that represent the intermediate
## and final hash values (h0 through h7) during the SHA-256 computation process.
## These values are updated after processing each message block.
Sha256State : {
    h0 : U32,
    h1 : U32,
    h2 : U32,
    h3 : U32,
    h4 : U32,
    h5 : U32,
    h6 : U32,
    h7 : U32,
}

## bytesToWordsBE : List U8 -> Result (List U32) InvalidInput
##
## Purpose:
##   Converts a 512-bit (64-byte) message chunk into a list of sixteen 32-bit (U32) words.
##   The conversion is done in big-endian format, where the first byte of a 4-byte sequence
##   forms the most significant byte of the U32 word. This is step 1 of the message
##   schedule generation described in FIPS 180-4, Section 6.2.
##
## Parameters:
##   - `messageChunk` : `List U8` - A 64-byte list representing one block of the padded message.
##
## Return Value:
##   - `Result (List U32) InvalidInput` -
##     - `Ok (List U32)`: A list of 16 U32 words if the input chunk is valid (64 bytes).
##     - `Err InvalidInput`: If the input `messageChunk` is not exactly 64 bytes long.
bytesToWordsBE : List U8 -> Result (List U32) InvalidInput
bytesToWordsBE = \messageChunk ->
    if List.len messageChunk == 64 then
        words =
            messageChunk
                |> List.chunksOf 4
                |> List.map \chunk ->
                    b1 = List.get chunk 0 |> Result.withDefault 0 # Default should ideally not be hit with 64-byte check
                    b2 = List.get chunk 1 |> Result.withDefault 0
                    b3 = List.get chunk 2 |> Result.withDefault 0
                    b4 = List.get chunk 3 |> Result.withDefault 0

                    (Bitwise.shiftLeftBy (Num.toU32 b1) 24)
                        |> Bitwise.or (Bitwise.shiftLeftBy (Num.toU32 b2) 16)
                        |> Bitwise.or (Bitwise.shiftLeftBy (Num.toU32 b3) 8)
                        |> Bitwise.or (Num.toU32 b4)

        Ok words
    else
        Err InvalidInput

# Initial Hash Values (H0-H7)
## These are the initial hash values, representing the first 32 bits of the
## fractional parts of the square roots of the first 8 prime numbers (2 through 19).
## As defined in FIPS 180-4, section 5.3.3.
h0 : U32 = 0x6a09e667
h1 : U32 = 0xbb67ae85
h2 : U32 = 0x3c6ef372
h3 : U32 = 0xa54ff53a
h4 : U32 = 0x510e527f
h5 : U32 = 0x9b05688c
h6 : U32 = 0x1f83d9ab
h7 : U32 = 0x5be0cd19

# Round Constants (K)
## These are the round constants used in the SHA-256 compression function.
## They represent the first 32 bits of the fractional parts of the cube roots
## of the first 64 prime numbers (2 through 311).
## As defined in FIPS 180-4, section 4.2.2.
kConstants : List U32 = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

## generateMessageSchedule : List U8 -> Result (List U32) InvalidInput
##
## Purpose:
##   Creates the 64-word (U32) message schedule `W` for a single 512-bit (64-byte) message chunk.
##   This is as per FIPS 180-4, Section 6.2, step 2. The first 16 words (W0-W15) are derived
##   directly from the message chunk (using `bytesToWordsBE`). The remaining 48 words (W16-W63)
##   are calculated using the formula:
##   W_t = σ1(W_{t-2}) + W_{t-7} + σ0(W_{t-15}) + W_{t-16}
##
## Parameters:
##   - `messageChunk` : `List U8` - A 64-byte list representing one block of the padded message.
##
## Return Value:
##   - `Result (List U32) InvalidInput` -
##     - `Ok (List U32)`: A list of 64 U32 words representing the message schedule `W`.
##     - `Err InvalidInput`: If `bytesToWordsBE` fails (e.g., `messageChunk` is not 64 bytes).
generateMessageSchedule : List U8 -> Result (List U32) InvalidInput
generateMessageSchedule = \messageChunk ->
    bytesToWordsBE messageChunk
    |> Result.try \initialWords ->
        # Helper function to recursively build the schedule
        buildSchedule = \currentSchedule, currentIndex ->
            if currentIndex == 64 then
                currentSchedule
            else
                # Indices for w[t-2], w[t-7], w[t-15], w[t-16]
                # Note: Roc list indices match t values directly here (0-based)
                wTMinus2 = List.getUnsafe currentSchedule (currentIndex - 2)
                wTMinus7 = List.getUnsafe currentSchedule (currentIndex - 7)
                wTMinus15 = List.getUnsafe currentSchedule (currentIndex - 15)
                wTMinus16 = List.getUnsafe currentSchedule (currentIndex - 16)

                s1 = smallSigma1 wTMinus2
                s0 = smallSigma0 wTMinus15

                # U32 addition wraps by default in Roc, which is the desired behavior for SHA-256.
                newWord = s1 + wTMinus7 + s0 + wTMinus16

                nextSchedule = List.append currentSchedule newWord
                buildSchedule nextSchedule (currentIndex + 1)

        # Start building from index 16, as W0-W15 are `initialWords`
        finalSchedule = buildSchedule initialWords 16
        Ok finalSchedule

InvalidInput : []

## rotr : U8, U32 -> U32
## Right-rotate a U32 value by n bits.
## Parameters:
##   - n: U8 - Number of bits to rotate by.
##   - val: U32 - The value to rotate.
## Returns: U32 - The rotated value.
rotr : U8, U32 -> U32
rotr = \n, val ->
    (Bitwise.shiftRightBy val n) |> Bitwise.or (Bitwise.shiftLeftBy val (32 - n))

## shr : U8, U32 -> U32
## Right-shift a U32 value by n bits (logical shift).
## Parameters:
##   - n: U8 - Number of bits to shift by.
##   - val: U32 - The value to shift.
## Returns: U32 - The shifted value.
shr : U8, U32 -> U32
shr = \n, val ->
    Bitwise.shiftRightBy val n

## smallSigma0 : U32 -> U32
## SHA-256 internal function sigma0 (small sigma 0), as defined in FIPS 180-4, section 4.1.2.
## σ0(x) = ROTR^7(x) XOR ROTR^18(x) XOR SHR^3(x)
## Parameters:
##   - val: U32 - The input word.
## Returns: U32 - The result of the smallSigma0 operation.
smallSigma0 : U32 -> U32
smallSigma0 = \val ->
    (rotr 7 val)
        |> Bitwise.xor (rotr 18 val)
        |> Bitwise.xor (shr 3 val)

## smallSigma1 : U32 -> U32
## SHA-256 internal function sigma1 (small sigma 1), as defined in FIPS 180-4, section 4.1.2.
## σ1(x) = ROTR^17(x) XOR ROTR^19(x) XOR SHR^10(x)
## Parameters:
##   - val: U32 - The input word.
## Returns: U32 - The result of the smallSigma1 operation.
smallSigma1 : U32 -> U32
smallSigma1 = \val ->
    (rotr 17 val)
        |> Bitwise.xor (rotr 19 val)
        |> Bitwise.xor (shr 10 val)

## ch : U32, U32, U32 -> U32
## SHA-256 internal function Ch (Choose), as defined in FIPS 180-4, section 4.1.2.
## Ch(x, y, z) = (x AND y) XOR ((NOT x) AND z)
## Parameters:
##   - x: U32 - First input word.
##   - y: U32 - Second input word.
##   - z: U32 - Third input word.
## Returns: U32 - The result of the Ch function.
ch : U32, U32, U32 -> U32
ch = \x, y, z ->
    (Bitwise.and x y)
        |> Bitwise.xor (Bitwise.and (Bitwise.not x) z)

## maj : U32, U32, U32 -> U32
## SHA-256 internal function Maj (Majority), as defined in FIPS 180-4, section 4.1.2.
## Maj(x, y, z) = (x AND y) XOR (x AND z) XOR (y AND z)
## Parameters:
##   - x: U32 - First input word.
##   - y: U32 - Second input word.
##   - z: U32 - Third input word.
## Returns: U32 - The result of the Maj function.
maj : U32, U32, U32 -> U32
maj = \x, y, z ->
    (Bitwise.and x y)
        |> Bitwise.xor (Bitwise.and x z)
        |> Bitwise.xor (Bitwise.and y z)

## bigSigma0 : U32 -> U32
## SHA-256 internal function Sigma0 (capital sigma 0), as defined in FIPS 180-4, section 4.1.2.
## Σ0(x) = ROTR^2(x) XOR ROTR^13(x) XOR ROTR^22(x)
## Parameters:
##   - x: U32 - The input word.
## Returns: U32 - The result of the bigSigma0 operation.
bigSigma0 : U32 -> U32
bigSigma0 = \x ->
    (rotr 2 x)
        |> Bitwise.xor (rotr 13 x)
        |> Bitwise.xor (rotr 22 x)

## bigSigma1 : U32 -> U32
## SHA-256 internal function Sigma1 (capital sigma 1), as defined in FIPS 180-4, section 4.1.2.
## Σ1(x) = ROTR^6(x) XOR ROTR^11(x) XOR ROTR^25(x)
## Parameters:
##   - x: U32 - The input word.
## Returns: U32 - The result of the bigSigma1 operation.
bigSigma1 : U32 -> U32
bigSigma1 = \x ->
    (rotr 6 x)
        |> Bitwise.xor (rotr 11 x)
        |> Bitwise.xor (rotr 25 x)

## sha256Once : List U8 -> List U8
##
## Purpose:
##   Orchestrates the entire SHA-256 hashing process for a given message.
##   This involves:
##     1. Initializing the hash state (H0-H7) (FIPS 180-4, Sec 5.3.3).
##     2. Padding the input message (`padMessage`) (FIPS 180-4, Sec 5.1.1).
##     3. Parsing the padded message into 512-bit (64-byte) blocks.
##     4. Iteratively processing each block using `processChunk` (FIPS 180-4, Sec 6.2).
##     5. Producing the final 256-bit (32-byte) hash value.
##
## Parameters:
##   - `message` : `List U8` - The input message to be hashed.
##
## Return Value:
##   - `List U8` - A 32-byte list representing the SHA-256 hash of the input message.
sha256Once : List U8 -> List U8
sha256Once = \message ->
    # 1. Initialize hash values
    initialState : Sha256State = {
        h0: h0, # These refer to the global h0-h7 constants
        h1: h1,
        h2: h2,
        h3: h3,
        h4: h4,
        h5: h5,
        h6: h6,
        h7: h7,
    }

    # 2. Pad the message
    paddedMessage = padMessage message

    # 3. Process message in 512-bit (64-byte) chunks
    finalState =
        paddedMessage
            |> List.chunksOf 64 # Process in 64-byte chunks
            |> List.walk initialState \currentChunkState, chunk ->
                # a. Generate message schedule (W) for the current chunk
                when generateMessageSchedule chunk is
                    Ok scheduleW ->
                        # b. Process the chunk with the current hash state
                        processChunk currentChunkState scheduleW
                    Err InvalidInput ->
                        # This case should ideally not happen with correct padding
                        # For now, crash or return an error state; let's crash.
                        crash "Invalid input to generateMessageSchedule during sha256Once"

    # 4. Convert final hash state (List U32) to List U8
    # The Sha256State record needs to be converted to a list of U32 first.
    finalHashesU32 = [
        finalState.h0,
        finalState.h1,
        finalState.h2,
        finalState.h3,
        finalState.h4,
        finalState.h5,
        finalState.h6,
        finalState.h7,
    ]
    u32sToBytes finalHashesU32

## processChunk : Sha256State, List U32 -> Sha256State
##
## Purpose:
##   Performs the SHA-256 compression function on a single 512-bit (64-byte)
##   message chunk. It takes the current hash state (intermediate hash values H(i-1))
##   and the message schedule (W) for the current chunk, and computes the next
##   intermediate hash state H(i). This is detailed in FIPS 180-4, Section 6.2.
##
## Steps:
##   1. Initialize eight working variables (a, b, c, d, e, f, g, h) with the
##      current intermediate hash values. (Sec 6.2, step 2)
##   2. Perform 64 rounds of computation (t=0 to 63). In each round:
##      - Calculate S1, Ch, Temp1, S0, Maj, Temp2.
##      - Update the working variables a-h. (Sec 6.2, step 3)
##   3. Compute the new intermediate hash values H(i) by adding the final
##      working variables to the previous intermediate hash values H(i-1). (Sec 6.2, step 4)
##
## Parameters:
##   - `currentState` : `Sha256State` - The current set of eight 32-bit intermediate hash values.
##   - `w` : `List U32` - The 64-word message schedule for the current chunk.
##
## Return Value:
##   - `Sha256State` - The updated set of eight 32-bit intermediate hash values after
##     processing the chunk.
processChunk : Sha256State, List U32 -> Sha256State
processChunk = \currentState, w ->
    # Initialize working variables from the current hash state
    workingVars = {
        a: currentState.h0,
        b: currentState.h1,
        c: currentState.h2,
        d: currentState.h3,
        e: currentState.h4,
        f: currentState.h5,
        g: currentState.h6,
        h: currentState.h7,
    }

    # Perform 64 rounds of computation
    finalWorkingVars =
        List.range 0 63 # Generates a list [0, 1, ..., 63]
        |> List.walk workingVars \t, currentIterVars ->
            # s1 = bigSigma1 e
            s1 = bigSigma1 currentIterVars.e

            # chVal = ch e f g
            chVal = ch currentIterVars.e currentIterVars.f currentIterVars.g

            # k_t = List.getUnsafe kConstants t
            k_t = List.getUnsafe kConstants t

            # w_t = List.getUnsafe w t
            w_t = List.getUnsafe w t

            # temp1 = h + s1 + chVal + k_t + w_t
            temp1 = currentIterVars.h + s1 + chVal + k_t + w_t # U32 addition wraps

            # s0 = bigSigma0 a
            s0 = bigSigma0 currentIterVars.a

            # majVal = maj a b c
            majVal = maj currentIterVars.a currentIterVars.b currentIterVars.c

            # temp2 = s0 + majVal
            temp2 = s0 + majVal # U32 addition wraps

            # Update working variables for the next iteration
            {
                a: temp1 + temp2, # a = temp1 + temp2
                b: currentIterVars.a, # b = a
                c: currentIterVars.b, # c = b
                d: currentIterVars.c, # d = c
                e: currentIterVars.d + temp1, # e = d + temp1
                f: currentIterVars.e, # f = e
                g: currentIterVars.f, # g = f
                h: currentIterVars.g, # h = g
            }

    # Compute new intermediate hash values
    {
        h0: currentState.h0 + finalWorkingVars.a,
        h1: currentState.h1 + finalWorkingVars.b,
        h2: currentState.h2 + finalWorkingVars.c,
        h3: currentState.h3 + finalWorkingVars.d,
        h4: currentState.h4 + finalWorkingVars.e,
        h5: currentState.h5 + finalWorkingVars.f,
        h6: currentState.h6 + finalWorkingVars.g,
        h7: currentState.h7 + finalWorkingVars.h,
    }

bytesToWordsBE : List U8 -> Result (List U32) InvalidInput
bytesToWordsBE = \messageChunk ->
    if List.len messageChunk == 64 then
        words =
            messageChunk
                |> List.chunksOf 4
                |> List.map \chunk ->
                    b1 = List.get chunk 0 |> Result.withDefault 0
                    b2 = List.get chunk 1 |> Result.withDefault 0
                    b3 = List.get chunk 2 |> Result.withDefault 0
                    b4 = List.get chunk 3 |> Result.withDefault 0

                    (Bitwise.shiftLeftBy (Num.toU32 b1) 24)
                        |> Bitwise.or (Bitwise.shiftLeftBy (Num.toU32 b2) 16)
                        |> Bitwise.or (Bitwise.shiftLeftBy (Num.toU32 b3) 8)
                        |> Bitwise.or (Num.toU32 b4)

        Ok words
    else
        Err InvalidInput

generateMessageSchedule : List U8 -> Result (List U32) InvalidInput
generateMessageSchedule = \messageChunk ->
    bytesToWordsBE messageChunk
    |> Result.try \initialWords ->
        # Helper function to recursively build the schedule
        buildSchedule = \currentSchedule, currentIndex ->
            if currentIndex == 64 then
                currentSchedule
            else
                # Indices for w[i-2], w[i-7], w[i-15], w[i-16]
                wIMinus2 = List.getUnsafe currentSchedule (currentIndex - 2)
                wIMinus7 = List.getUnsafe currentSchedule (currentIndex - 7)
                wIMinus15 = List.getUnsafe currentSchedule (currentIndex - 15)
                wIMinus16 = List.getUnsafe currentSchedule (currentIndex - 16)

                s1 = smallSigma1 wIMinus2
                s0 = smallSigma0 wIMinus15

                newWord = s1 + wIMinus7 + s0 + wIMinus16

                nextSchedule = List.append currentSchedule newWord
                buildSchedule nextSchedule (currentIndex + 1)

        finalSchedule = buildSchedule initialWords 16
        Ok finalSchedule

#
# Inline Tests
#

expectU32Crash : U32, U32, Str -> {}
expectU32Crash = \actual, expected, description ->
    if actual == expected then
        {}
    else
        crash "Assertion failed: \(description). Expected 0x\(Num.toHex expected), got 0x\(Num.toHex actual)"

expectStrCrash : Str, Str, Str -> {}
expectStrCrash = \actual, expected, description ->
    if actual == expected then
        {}
    else
        crash "Assertion failed: \(description). Expected \"\(expected)\", got \"\(actual)\""

runBitwiseHelperTests : {}
runBitwiseHelperTests =
    # Tests for rotr
    expectU32Crash (rotr 8 0x12345678) 0x78123456 "rotr(8, 0x12345678)"
    expectU32Crash (rotr 0 0x12345678) 0x12345678 "rotr(0, 0x12345678)"
    expectU32Crash (rotr 32 0x12345678) 0x12345678 "rotr(32, 0x12345678)"
    expectU32Crash (rotr 4 0xABCDEF01) 0x1ABCDEF0 "rotr(4, 0xABCDEF01)"

    # Tests for shr
    expectU32Crash (shr 4 0x12345678) 0x01234567 "shr(4, 0x12345678)"
    expectU32Crash (shr 0 0x12345678) 0x12345678 "shr(0, 0x12345678)"
    expectU32Crash (shr 32 0x12345678) 0x00000000 "shr(32, 0x12345678)"
    expectU32Crash (shr 8 0xFF00FF00) 0x00FF00FF "shr(8, 0xFF00FF00)"

    # Tests for smallSigma0
    expectU32Crash (smallSigma0 0x6a09e667) 0x99a279a1 "smallSigma0(0x6a09e667)"

    # Tests for smallSigma1
    expectU32Crash (smallSigma1 0xbb67ae85) 0x0c0518c9 "smallSigma1(0xbb67ae85)"

    # Tests for ch
    expectU32Crash (ch 0x510e527f 0x9b05688c 0x1f83d9ab) 0x1f84198c "ch(H4,H5,H6 initial)"

    # Tests for maj
    expectU32Crash (maj 0x6a09e667 0xbb67ae85 0x3c6ef372) 0x306e0067 "maj(H0,H1,H2 initial)"

    # Tests for bigSigma0
    expectU32Crash (bigSigma0 0x6a09e667) 0x50864d0d "bigSigma0(0x6a09e667)"

    # Tests for bigSigma1
    expectU32Crash (bigSigma1 0x510e527f) 0x79c66d87 "bigSigma1(0x510e527f)"

    {}

runMessageScheduleTests : {}
runMessageScheduleTests =
    scheduleResult = generateMessageSchedule messageChunk_abc_bytes

    when scheduleResult is
        Err InvalidInput ->
            crash "generateMessageSchedule returned InvalidInput for 'abc' chunk"

        Ok actualScheduleWords ->
            if List.len actualScheduleWords != 64 then
                crash "generateMessageSchedule for 'abc' did not return 64 words. Got: \(List.len actualScheduleWords)"
            else
                List.walkWithIndex expected_schedule_abc_prefix {} \index, acc, expectedWord ->
                    actualWord = List.getUnsafe actualScheduleWords index
                    description = "W[\(Num.toStr index)] for 'abc'"
                    expectU32Crash actualWord expectedWord description
                    acc
    {}

runProcessChunkTests : {}
runProcessChunkTests =
    initialState : Sha256State = {
        h0: h0, h1: h1, h2: h2, h3: h3,
        h4: h4, h5: h5, h6: h6, h7: h7,
    }
    scheduleResult = generateMessageSchedule messageChunk_abc_bytes
    when scheduleResult is
        Err InvalidInput ->
            crash "processChunk test: generateMessageSchedule failed for 'abc' chunk"
        Ok schedule_W ->
            newState = processChunk initialState schedule_W
            expectU32Crash newState.h0 0x29019097 "processChunk 'abc' H0'"
            expectU32Crash newState.h1 0xf8355c50 "processChunk 'abc' H1'"
            expectU32Crash newState.h2 0x51092d3c "processChunk 'abc' H2'"
            expectU32Crash newState.h3 0x8a4d6170 "processChunk 'abc' H3'"
            expectU32Crash newState.h4 0x57690f29 "processChunk 'abc' H4'"
            expectU32Crash newState.h5 0x705cec03 "processChunk 'abc' H5'"
            expectU32Crash newState.h6 0x4e9f139d "processChunk 'abc' H6'"
            expectU32Crash newState.h7 0x4009f386 "processChunk 'abc' H7'"
    {}

messageChunk_abc_bytes : List U8
messageChunk_abc_bytes =
    [0x61, 0x62, 0x63, 0x80]
        |> List.concat (List.repeat 0x00 52)
        |> List.concat [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18]

expected_schedule_abc_prefix : List U32
expected_schedule_abc_prefix =
    [
        0x61626380, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000018,
        0x61626380, 0x000F0000,
    ]

# Run tests when module is loaded
_ = runBitwiseHelperTests
_ = runMessageScheduleTests
_ = runProcessChunkTests
