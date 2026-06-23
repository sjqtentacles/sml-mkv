# sml-mkv

[![CI](https://github.com/sjqtentacles/sml-mkv/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-mkv/actions/workflows/ci.yml)

Matroska / WebM (EBML) **magic-number recognition** for Standard ML. Detects
whether a byte sequence begins with the EBML header id that starts every
Matroska/WebM file.

## API

```sml
Mkv.ebmlMagic                (* [0x1A, 0x45, 0xDF, 0xA3] *)
Mkv.parseHeader bytes        (* SOME () if the EBML magic is present, else NONE *)
```

```sml
Mkv.parseHeader Mkv.ebmlMagic            (* SOME () *)
Mkv.parseHeader [0x00, 0x45, 0xDF, 0xA3] (* NONE *)
```

## Scope and limitations

- **Magic detection only.** This recognizes the 4-byte EBML header id; it does
  **not** parse EBML element ids, variable-length integers, the Segment, tracks,
  clusters, or any Matroska structure. `parseHeader` returns `unit option`.
- For anything beyond "is this plausibly a Matroska/WebM file?", a full EBML
  parser would be required.

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
  mkv.sml      EBML magic recognition
  mkv.mlb
test/
  test.sml     valid magic, trailing bytes, rejection + short input
```

## License

MIT. See [LICENSE](LICENSE).
