(* demo.sml - decodes a small in-memory EBML/Matroska byte stream: an EBML
   header, a Segment element, and a Void element, built as a literal int
   list (no fixture file). Deterministic: no I/O beyond stdout. *)

structure M = Mkv

fun hex n = "0x" ^ String.map Char.toUpper (Int.fmt StringCvt.HEX n)

val () = print "vintLength (VINT byte length from the marker bit):\n"
val () =
  List.app
    (fn b => print ("  vintLength(" ^ hex b ^ ") = " ^ Int.toString (M.vintLength b) ^ "\n"))
    [0x1A, 0x80, 0xEC, 0x40]

val () = print "\nreadId on the EBML magic bytes:\n"
val () =
  case M.readId M.ebmlMagic of
      NONE => print "  NONE\n"
    | SOME (id, rest) =>
        print ("  id = " ^ hex id ^ ", " ^ Int.toString (List.length rest) ^ " bytes left\n")

val () = print "\nreadSize on a lone 1-byte VINT [0x9F]:\n"
val () =
  case M.readSize [0x9F] of
      NONE => print "  NONE\n"
    | SOME (size, rest) =>
        print ("  size = " ^ Int.toString size ^ ", " ^ Int.toString (List.length rest) ^ " bytes left\n")

(* Build a tiny top-level element stream: EBML header (size=4, 4 dummy body
   bytes), a Segment element (size=10, 10 body bytes), a Void element
   (size=3, 3 body bytes). *)
val ebmlHeader = M.ebmlMagic @ [0x84] @ [0, 0, 0, 0]
val segment    = [0x18, 0x53, 0x80, 0x67] @ [0x40, 0x0A] @ List.tabulate (10, fn i => i)
val void       = [0xEC] @ [0x83] @ [0xFF, 0xFF, 0xFF]
val stream     = ebmlHeader @ segment @ void

val () = print "\nparseHeader on the stream:\n"
val () =
  case M.parseHeader stream of
      NONE => print "  NONE\n"
    | SOME { id, size } => print ("  id = " ^ hex id ^ ", size = " ^ Int.toString size ^ "\n")

val () = print "\nscan over the stream (top-level elements):\n"
val () =
  List.app
    (fn (M.Element { id, size }) =>
        print ("  Element id=" ^ hex id ^ " size=" ^ Int.toString size ^ "\n"))
    (M.scan stream)
