structure Tests = struct open Harness structure M = Mkv
fun run () = let
  val () = section "EBML magic recognition"
  val () = checkInt "magic is 4 bytes" (4, List.length M.ebmlMagic)
  val () = check "accepts valid EBML magic" (Option.isSome (M.parseHeader M.ebmlMagic))
  val () = check "accepts magic with trailing bytes"
             (Option.isSome (M.parseHeader (M.ebmlMagic @ [0x01, 0x02, 0x03])))

  val () = section "rejects non-EBML input"
  val () = check "wrong first byte -> NONE"
             (not (Option.isSome (M.parseHeader [0x00, 0x45, 0xDF, 0xA3])))
  val () = check "wrong last byte -> NONE"
             (not (Option.isSome (M.parseHeader [0x1A, 0x45, 0xDF, 0x00])))
  val () = check "too short -> NONE"
             (not (Option.isSome (M.parseHeader [0x1A, 0x45])))
  val () = check "empty -> NONE"
             (not (Option.isSome (M.parseHeader [])))
in Harness.run () end end
