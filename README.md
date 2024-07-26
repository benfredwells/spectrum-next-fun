# spectrum-next-fun
My explorations of the ZX Spectrum Next. These instructions are for Windows, Linux instructions to come.

## Project contents

### fullPalleteView (WIP)
A Spectrum Next program that let's you scroll through the entire colour palette of the Spectrum Next - i.e. all 512 colours from the 9 bit palette. This is intended to be a Spectrum Next 'port' of https://9bit-colour.pages.dev/ and evolve along with it.

### loadPng
This Spectrum Next program loads a PNG image onto the Spectrum Next using Layer2. To prepare the image, use src\tools\pngDump.py.

### tools\pngDump.py
This tool takes supported PNG images and generates palette and image data binary files, formatted in a way that is relatively easy to load onto the Spectrum Next (see program loadPng). Only 320x256 palatted images are supported.

## Setup / build / run instructions

### Python tools

#### Setup
- Python3 installed on the machine
- go to the `.\src\tools` folder and run `pip install -r requirements.txt`

#### Running
- from `.\src\tools\` folder run `python .\pngDump.py --help` to see usage instructions

### Spectrum programs

#### Pre-setup
An sd card image is required in the checkout. This is used for the emulator. These instructions taken from the CSpect readme:

- The sd card image should be in `.\next-sd-card`
  - when finished, there should be these files in the folder: `diskimage.img`, `enNextNZ.rom` and `enNxtmmc.rom`
- You can get a pre-made image here: http://www.zxspectrumnext.online/cspect/ unzip this file - and the contained ROM files - into the image folder
- Or you can make an image yourself
  - Get a Spectrum Next SD card, either by using your existing card or
    - Download the latest SD card from https://www.specnext.com/category/downloads/ or
    - Copy onto an SD card
  - Copy the files `enNextZX.rom` and `enNxtmmc.rom` from the SD Card into the image folder (on my card these are in `\machines\next`)
  - Use an imager (e.g. Win32DiskImager https://sourceforge.net/projects/win32diskimager/) to make an .img file of the SD card and put it in the image folder. This file should be called `diskimage.img`
  - Note that taking an image of an SD card >= 16GB seems to cause issues so I use the pre-made image

#### Setup
To setup, these tools all need to be installed into the `.\SpectrumToolchain` folder:
- sjasmplus (assembler), which can be found here: https://github.com/z00m128/sjasmplus
  - note there is a zipped install that can be downloaded, no need to build
  - put the install in `.\SpectrumToolchain\sjasmplus`
- hdfmonkey (tool to work with FAT disk images)
  - can be found here: https://github.com/gasman/hdfmonkey
  - I can't remember how I built this and all links to download an exe seem to be dead, so there is one in the `prebuilt` folder.
  - put `hdfmonkey.exe` in `.\SpectrumToolchain`
- CSpect (emulator), which can be found here: https://mdf200.itch.io/cspect
  - unzip the install contents into `.\SpectrumToolchain\CSpect`

Other useful tools:
- Z80 Macro Assembler VS Code extension: https://marketplace.visualstudio.com/items?itemName=mborik.z80-macroasm

#### Build
- Make sure there is a `.\build` folder
- Open any file in the folder containing the main.asm file to be built (e.g. `.\src\loadPng\foo.bar`)
- Run the Build command in vs code (ctrl+shift+B > Build)
- This will create `.\build\test.nex`

#### Install
- This will add `.\build\test.nex` to the disk image in `.\next-sd-card`
- Run the Copy task (ctrl+shift_P > Type task > Run task > select Copy)

#### Emulate
- This will run the emulator using the disk image in `.\next-sd-card`
- Run the Launch CSpect task (ctrl+shift+P > Type task > Run task > select Launch CSpect)
- CSpect is a little hard to use, read the `.\SpectrumToolchain\CSpect\ReadMe.txt` for instructions
  - The emulator starts paused, to run press F1
  - From there you can use the Spectrum Next browser to find the test.nex file and run it
  - To pause, hit F1 again which will drop you in the emulator view

#### Run
- Copy the `test.nex` file from `.\build` to your (real) Spectrum Next SD card
