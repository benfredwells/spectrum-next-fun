from pngparser import PngParser, TYPE_PLTE
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


def truncateColour(colour):
    # Use top three bits, however if this means a non-zero colour becomes zero,
    # use the minimum non-zero colour
    truncated = (colour & 0xE0) >> 5
    if truncated == 0 and colour != 0:
        truncated = 0x01
    return truncated


def dumpPalette(path, png):
    try:
        # just handle 9 bit palettes for now
        palette_chunks = png.get_by_type(TYPE_PLTE)
        output_bytes = bytes()
        for chunk in palette_chunks:
            for i in range(0, len(chunk.data) // 3):
                base = i * 3
                r = truncateColour(chunk.data[base])
                g = truncateColour(chunk.data[base + 1])
                b = truncateColour(chunk.data[base + 2])
                byte_1 = r << 5 | g << 2 | b >> 1
                byte_2 = b & 0x01
                output_bytes += byte_1
                output_bytes += byte_2
        f = open(path, mode="wb")
        f.write(output_bytes)
        f.close()
    except Exception as e:
        print("Could not write palette", e)

def run(args):
    png = None
    try:
        png = PngParser(args.input_file)
        if not checkPngValidity(png):
            return
        dumpPalette(args.p_file, png)
    except Exception as e:
        print(e)
        return


def processArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_file")
    parser.add_argument(
        "-p", "--p_file", default="palette.bin", help="Output palette file name"
    )
    parser.add_argument(
        "-o", "--o_file", default="image.bin", help="Image output file name"
    )
    return parser.parse_args()


if __name__ == "__main__":
    run(processArgs())
