structure Tests = struct open Harness structure M = Mkv

fun idOf (M.Element e) = #id e
fun szOf (M.Element e) = #size e

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

  val () = section "vintLength"
  val () = checkInt "0x82 -> 1" (1, M.vintLength 0x82)
  val () = checkInt "0xFF -> 1" (1, M.vintLength 0xFF)
  val () = checkInt "0x42 -> 2" (2, M.vintLength 0x42)
  val () = checkInt "0x20 -> 3" (3, M.vintLength 0x20)
  val () = checkInt "0x1A -> 4" (4, M.vintLength 0x1A)
  val () = checkInt "0x10 -> 4" (4, M.vintLength 0x10)
  val () = checkInt "0x01 -> 8" (8, M.vintLength 0x01)
  val () = checkRaises "0x00 raises Vint" (fn () => M.vintLength 0x00)

  val () = section "readSize (marker stripped)"
  val () = checkInt "[0x82] -> 2" (2, #1 (Option.valOf (M.readSize [0x82])))
  val () = checkInt "[0x81] -> 1" (1, #1 (Option.valOf (M.readSize [0x81])))
  val () = checkInt "[0x40,0x02] -> 2" (2, #1 (Option.valOf (M.readSize [0x40, 0x02])))
  val () = checkInt "[0x41,0x00] -> 256" (256, #1 (Option.valOf (M.readSize [0x41, 0x00])))
  val () = check "readSize [] -> NONE" (not (Option.isSome (M.readSize [])))
  val () = check "readSize truncated -> NONE" (not (Option.isSome (M.readSize [0x40])))
  val () = checkIntList "readSize returns remainder"
             ([0xAA, 0xBB], #2 (Option.valOf (M.readSize [0x82, 0xAA, 0xBB])))

  val () = section "readId (marker kept)"
  val () = checkInt "[0x82] id -> 0x82" (0x82, #1 (Option.valOf (M.readId [0x82])))
  val () = checkInt "EBML magic id -> 0x1A45DFA3"
             (0x1A45DFA3, #1 (Option.valOf (M.readId M.ebmlMagic)))
  val () = check "readId [] -> NONE" (not (Option.isSome (M.readId [])))

  val () = section "scan top-level elements"
  (* el1: id 0x82, size 0x82 (=2), data AA BB; el2: id 0x83, size 0x81 (=1), data CC *)
  val stream = [0x82, 0x82, 0xAA, 0xBB, 0x83, 0x81, 0xCC]
  val els = M.scan stream
  val () = checkInt "two elements" (2, List.length els)
  val () = checkInt "el1 id" (0x82, idOf (List.nth (els, 0)))
  val () = checkInt "el1 size" (2, szOf (List.nth (els, 0)))
  val () = checkInt "el2 id" (0x83, idOf (List.nth (els, 1)))
  val () = checkInt "el2 size" (1, szOf (List.nth (els, 1)))
  val () = checkInt "scan [] -> 0 elements" (0, List.length (M.scan []))
  val () = checkInt "scan stops on truncated data"
             (0, List.length (M.scan [0x82, 0x82, 0xAA]))  (* el1 wants 2 data bytes, only 1 *)

  val () = section "parseHeader returns id/size"
  val hdr = Option.valOf (M.parseHeader (M.ebmlMagic @ [0x83, 0x01, 0x02, 0x03]))
  val () = checkInt "header id" (0x1A45DFA3, #id hdr)
  val () = checkInt "header size = 3" (3, #size hdr)
in Harness.run () end end
