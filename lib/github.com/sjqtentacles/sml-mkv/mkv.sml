structure Mkv :> MKV =
struct
  val ebmlMagic = [0x1A, 0x45, 0xDF, 0xA3]

  datatype element = Element of { id : int, size : int }

  exception Vint of string

  (* Number of leading zero bits before the first set bit determines the VINT
     length: 0x80 -> 1, 0x40 -> 2, ... 0x01 -> 8. A zero first byte is invalid. *)
  fun vintLength b =
    if b < 0 orelse b > 0xFF then raise Vint "byte out of range"
    else if b = 0 then raise Vint "no length marker in first byte"
    else
      let fun go (mask, len) =
            if Int.> (Word.toInt (Word.andb (Word.fromInt b, Word.fromInt mask)), 0)
            then len
            else go (Word.toInt (Word.>> (Word.fromInt mask, 0w1)), len + 1)
      in go (0x80, 1) end

  (* Read a `len`-byte big-endian integer from `bytes`, masking the first byte
     with `firstMask` (0xFF keeps the marker, a narrower mask strips it). *)
  fun readN (bytes, firstMask) =
    case bytes of
        [] => NONE
      | first :: _ =>
          let val len = vintLength first
          in if List.length bytes < len then NONE
             else
               let val taken = List.take (bytes, len)
                   val rest = List.drop (bytes, len)
                   fun fold ([], _, acc) = acc
                     | fold (b :: bs, i, acc) =
                         let val mask = if i = 0 then firstMask else 0xFF
                             val v = Word.toInt (Word.andb (Word.fromInt b, Word.fromInt mask))
                         in fold (bs, i + 1, acc * 256 + v) end
               in SOME (fold (taken, 0, 0), rest) end
          end handle Vint _ => NONE

  fun readId bytes = readN (bytes, 0xFF)

  fun readSize bytes =
    case bytes of
        [] => NONE
      | first :: _ =>
          let val len = vintLength first
              (* strip the marker bit: keep the low (8 - len) bits of byte 0 *)
              val firstMask = Word.toInt (Word.<< (0w1, Word.fromInt (8 - len))) - 1
          in readN (bytes, firstMask) end
          handle Vint _ => NONE

  fun scan bytes =
    let fun loop (bs, acc) =
          case readId bs of
              NONE => List.rev acc
            | SOME (id, afterId) =>
                case readSize afterId of
                    NONE => List.rev acc
                  | SOME (size, afterSize) =>
                      if List.length afterSize < size then List.rev acc
                      else loop (List.drop (afterSize, size),
                                 Element { id = id, size = size } :: acc)
    in loop (bytes, []) end

  type header = { id : int, size : int }

  fun startsWithMagic bytes =
    List.length bytes >= 4
    andalso List.all (fn (i,n) => List.nth (bytes,i) = n)
                     (List.tabulate (4, fn i => (i, List.nth (ebmlMagic, i))))

  fun parseHeader bytes =
    if not (startsWithMagic bytes) then NONE
    else
      case readId bytes of
          NONE => NONE
        | SOME (id, afterId) =>
            case readSize afterId of
                NONE => SOME { id = id, size = 0 }
              | SOME (size, _) => SOME { id = id, size = size }
end
