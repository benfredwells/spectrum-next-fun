from pngparser import PngParser, TYPE_PLTE
import sys

if __name__ == "__main__":
  print(f'Dumping info for {sys.argv[1]}')
  png = PngParser(sys.argv[1])
  header = png.get_header()
  print(header)
  print(header.use_palette())
  palette_chunks = png.get_by_type(TYPE_PLTE)
  for chunk in palette_chunks:
    print('Have a chunk')
    print(f'size {len(chunk.data)}')
    for i in range(0, len(chunk.data)//3):
      base = i * 3
      r = chunk.data[base]
      g = chunk.data[base+1]
      b = chunk.data[base+2]
      print(f'color {i} is r:{r:2x} g:{g:2x} b:{b:2x}')
