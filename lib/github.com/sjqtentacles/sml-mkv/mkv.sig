signature MKV =
sig
  (* The 4-byte EBML header element id that begins every Matroska/WebM file. *)
  val ebmlMagic : int list

  (* An EBML element: its id (with the length-descriptor marker bit kept, as is
     conventional for ids) and the decoded size of its data payload. *)
  datatype element = Element of { id : int, size : int }

  (* `vintLength b` is the total byte length (1-8) of a VINT whose first byte is
     `b`, determined by the position of the most-significant set bit. Raises
     `Vint` if `b = 0` (no marker bit in the first byte). *)
  exception Vint of string
  val vintLength : int -> int

  (* `readId bytes` decodes a leading element id (the marker bit is retained in
     the returned integer) and returns it with the remaining bytes. NONE if the
     input is empty or truncated. *)
  val readId : int list -> (int * int list) option

  (* `readSize bytes` decodes a leading data-size VINT (the marker bit is
     stripped, so the value is the actual length) and returns it with the
     remaining bytes. NONE if empty or truncated. *)
  val readSize : int list -> (int * int list) option

  (* `scan bytes` walks the top-level element list, reading each element's id and
     size and skipping over its `size` data bytes. Stops at the end of input or
     the first truncated/invalid element. *)
  val scan : int list -> element list

  (* A parsed EBML header: the leading element id (should equal the EBML magic
     interpreted as a vint id) and its declared body size. *)
  type header = { id : int, size : int }

  (* `parseHeader bytes` succeeds when `bytes` begins with the EBML magic; it
     returns the header id/size read as VINTs. NONE otherwise. *)
  val parseHeader : int list -> header option
end
