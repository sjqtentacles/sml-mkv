# sml-mkv

[![CI](https://github.com/sjqtentacles/sml-mkv/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-mkv/actions/workflows/ci.yml)

Matroska / WebM (EBML) parsing primitives for Standard ML: EBML
variable-length-integer (VINT) decoding, element id/size reading, a top-level
element scanner, and EBML header recognition.

## API

```sml
Mkv.ebmlMagic                (* [0x1A, 0x45, 0xDF, 0xA3] *)

datatype element = Element of { id : int, size : int }
type header = { id : int, size : int }

exception Vint of string
val vintLength  : int -> int                       (* first byte -> 1..8       *)
val readId      : int list -> (int * int list) option   (* marker bit kept     *)
val readSize    : int list -> (int * int list) option   (* marker bit stripped *)
val scan        : int list -> element list
val parseHeader : int list -> header option
```

### VINT decoding

The first byte's most-significant set bit gives the VINT length (`0x80` -> 1
byte, `0x40` -> 2, ... `0x01` -> 8). Element **ids** retain the marker bit;
data **sizes** strip it.

```sml
Mkv.vintLength 0x82            (* 1 *)
Mkv.vintLength 0x1A            (* 4 *)
Mkv.readSize [0x82]            (* SOME (2, [])        — marker stripped *)
Mkv.readSize [0x40, 0x02]      (* SOME (2, [])                          *)
Mkv.readId   Mkv.ebmlMagic     (* SOME (0x1A45DFA3, []) — marker kept   *)
```

### Scanning top-level elements

`scan` walks `(id, size)` pairs, skipping each element's `size` data bytes, and
stops at end-of-input or the first truncated element.

```sml
(* id 0x82, size 2, data AA BB; then id 0x83, size 1, data CC *)
Mkv.scan [0x82, 0x82, 0xAA, 0xBB, 0x83, 0x81, 0xCC]
(* [Element {id=0x82, size=2}, Element {id=0x83, size=1}] *)
```

### Header recognition

```sml
Mkv.parseHeader Mkv.ebmlMagic            (* SOME {id=0x1A45DFA3, size=...} *)
Mkv.parseHeader [0x00, 0x45, 0xDF, 0xA3] (* NONE *)
```

## Scope and limitations

- Operates on `int list` byte streams and decodes the EBML framing layer
  (VINTs, element ids, sizes, top-level scan). It does **not** interpret
  specific Matroska element semantics (Segment, Tracks, Clusters, codecs,
  timestamps) nor build a typed element tree beyond the flat top-level `scan`.
- Sizes are decoded as plain integers; the "unknown size" all-ones VINT is not
  given special treatment.

## Example

`make example` builds and runs [`examples/demo.sml`](examples/demo.sml), which
decodes a hand-built EBML/Matroska byte stream (an EBML header, a Segment
element, and a Void element) with `vintLength`, `readId`, `readSize`,
`parseHeader`, and `scan` (output is byte-identical under MLton and
Poly/ML):

```
vintLength (VINT byte length from the marker bit):
  vintLength(0x1A) = 4
  vintLength(0x80) = 1
  vintLength(0xEC) = 1
  vintLength(0x40) = 2

readId on the EBML magic bytes:
  id = 0x1A45DFA3, 0 bytes left

readSize on a lone 1-byte VINT [0x9F]:
  size = 31, 0 bytes left

parseHeader on the stream:
  id = 0x1A45DFA3, size = 4

scan over the stream (top-level elements):
  Element id=0x1A45DFA3 size=4
  Element id=0x18538067 size=10
  Element id=0xEC size=3
```

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-mkv
smlpkg sync
```

Reference from your `.mlb`:

```
lib/github.com/sjqtentacles/sml-mkv/mkv.mlb
```

## Building and testing

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make clean
```

## Project layout

```
sml.pkg
Makefile
lib/github.com/sjqtentacles/sml-mkv/
  mkv.sig
  mkv.sml      EBML VINT decoding, id/size reading, top-level scan
  mkv.mlb
test/
  test.sml     vintLength, readId/readSize, scan, header parsing
```

## License

MIT. See [LICENSE](LICENSE).
