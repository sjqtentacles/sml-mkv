signature MKV =
sig
  type header
  val parseHeader : int list -> header option
  val ebmlMagic : int list
end
