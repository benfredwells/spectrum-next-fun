from pngparser import PngParser, chunktypes
import sys

if __name__ == "__main__":
  print(f"Dumping info for {sys.argv[1]}")
  png = PngParser(sys.argv[1])
  header = png.get_header()
  print(header)
  print(header.use_palette())
