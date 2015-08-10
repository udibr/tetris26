Tetris for Atari 2600
=====================

This repo is a slight improvement over the origianl code by [Colin Hughes](./TETRIS26.TXT)

#Build
This repo contains the [latest ROM](./TETRIS26.BIN) but if you want to play with the source code
then you will have to build a new ROM as follows:

* [Download](http://sourceforge.net/projects/dasm-dillon/files/dasm-dillon/2.20.11/dasm-2.20.11.tar.gz/download) dasm
* Compile:

    ~/Downloads/dasm-2.20.11-2014.03.04-binaries/dasm.Darwin.x86 TETRIS26.S -f3 -oTETRIS26.BIN

#Run

    /Applications/Stella.app/Contents/MacOS/Stella TETRIS26.BIN

#More info
* http://www.dwheeler.com/6502/oneelkruns/asm1step.html
* http://www.6502.org/tutorials/6502opcodes.html