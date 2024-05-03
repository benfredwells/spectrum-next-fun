from pngparser import PngParser, TYPE_PLTE
import sys
import argparse


def checkPngValidity(png):
    # Must be paletted
    header = png.get_header()
    if not header.use_palette():
        print("Error: Only paletted images are supported")
        return False
    # Resolution must be 320x256
    lines = png.get_image_data().scanlines
    if (len(lines) != 256) or (len(lines[0].data) != 320):
        print("Error: Only 320x256 images supported")
        return False
    return True


def run(args):
    png = None
    try:
        png = PngParser(args.input)
    except Exception as e:
        print(e)
        exit()
    if not checkPngValidity(png):
        exit()
    palette_chunks = png.get_by_type(TYPE_PLTE)
    for chunk in palette_chunks:
        print("Have a chunk")
        print(f"size {len(chunk.data)}")
        for i in range(0, len(chunk.data) // 3):
            base = i * 3
            r = chunk.data[base]
            g = chunk.data[base + 1]
            b = chunk.data[base + 2]
            print(f"color {i:>4} is r:{r:02X} g:{g:02X} b:{b:02X}")

    lines = png.get_image_data().scanlines
    print(f"there are {len(lines)} lines")
    print(f"each line is {len(lines[0].data)} bytes long")


def processArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_file")
    parser.add_argument(
        "-p", "--p_file", default="palette.bin", help="Output palette file name"
    )
    parser.add_argument(
        "-o", "--o-file", default="image.bin", help="Image output file name"
    )
    return parser.parse_args()


if __name__ == "__main__":
    run(processArgs())
