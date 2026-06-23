structure Mkv :> MKV =
struct
  type header = unit
  val ebmlMagic = [0x1A, 0x45, 0xDF, 0xA3]
  fun parseHeader bytes =
    if List.length bytes >= 4
       andalso List.all (fn (i,n) => List.nth (bytes,i) = n) (List.tabulate (4, fn i => (i, List.nth (ebmlMagic, i))))
    then SOME () else NONE
end
