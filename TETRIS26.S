	processor 6502

	include vcs.h

;
; Tetris 2600
;
;	My attempt to provide the classic in only 2K....
;
;	Also to program something on the 2600, as the closest I got before
;	was coding a game for Atari called 'Chronicles of Omega' that was
;	on the ST ( with STe hardware support ) Amiga and 7800 ( Cool machine )
;	The 7800 version was canned before release, which was a pity as it
;	was probally the version I had highest hopes for.
;
;
;Version 0.01	June 3rd 1997
;
;	Just got the Emulator and the assembler, and dug out old manuals for
;	2600/7800... This should be a welcome change from PSX coding
;
;
;	June 4th 1997
;
;	Programming via the emulator is great, a lot quicker than Yaroze ( but
;	I guess I am only coding 2K max )
;	I've got the main screen display working, with the Tetris tiles visible
;	and a title on the right side. I've put the code in to drop the tiles
;	and stop when they land on other tiles.
;	At the moment all code and graphics take up around 600 bytes, but I
;	haven't put in sound or joystick handling yet (or scores)
;
;	.....
;
;	Gameplay is complete, just need to add score code and game over code
;	I think I may change the display loop slightly, so that the BK colour
;	is grey behind the tetris box rather than the credits text - It will
;	look a lot better, but I'll have to muck about with the timings.
;	( I haven't really counted cycles seriously yet, I just try something
;	and if the position is wrong I go back and move some instructions
;	around - Trial by error.. )
;
;	June 5th 1997
;
;	I added the full line removal so this is now a full game of Tetris,
;	although there are no scores and the block stuff isn't random ( I'll
;	make a random block table when I have time ) I just need to see how
;	it runs on a normal VCS now...
;
;Version 0.02	June 9th 1997
;
;	I've added a new display routine to give 13 characters on a screen
;	line, to provide the title routine. I've also placed a score on the
;	right, with flash messages for when you clear lines.. also I switch
;	the playfield colours each line to get a more colourful display



;Ram variables.....

		SEG.U	variables

		org	$80

left		ds 22			;pf1 part of display (22 lines)
right		ds 22			;pf2 part of display (22 lines)
gfxpf1		ds 22			;pf1 score and message area (22 lines)
gfxpf2		ds 22			;pf1 score and message area (22 lines)

;Variables only used during screen build

blockcnt	ds 1			;Counter for block inner loop
outercnt	ds 1			;Counter for block outer loop
blockcol	ds 1			;Colour of each block

scorecount	ds 1			;Line counter for score

;Variables only used outside screen build

offb4		ds 4			;Line offsets for 4 block pixels
pf1b4		ds 4			;PF1 masks for 4 block pixels
pf2b4		ds 4			;PF2 masks for 4 block pixels
temp		ds 1			;Temp save for Y


;Game logic variables...

blkoff		ds 1			;Offset of block
blkx		ds 1			;Block X start
blkid		ds 1			;Block type (include rotation)
save		ds 1			;Saved copy for use in move not allowed
save1		ds 1
nextblock	ds 1			;Next type of block
counter		ds 1			;State counter 
gamespeed	ds 1			;Reload value ( Always multiple of 4)
score		ds 2			;Game score ( 4 digit BCD )
message		ds 1			;Flash message ( Also used for game over )
digptr0		ds 2			;Indirect ptrs for score
digptr1		ds 2
nib0		ds 1			;Mask for nibble score
nib1		ds 1

eov			ds 0				;End of variables

;Leave rest for stack...


;
;
;Title line routines are macros, it's easier that way
;

	MAC	line

	sta	WSYNC			;0

	ldy	#2				;2
.wait
	dey
	bne	.wait
	nop


	lda	#{1}
	sta	GRP0
	sta	RESP0

	lda	#{2}
	sta	GRP0
	sta	RESP0

	lda	#{3}
	sta	GRP0
	sta	RESP0
	
	lda	#{4}
	sta	GRP0
	sta	RESP0

	lda	#{5}
	sta	GRP0
	sta	RESP0+$100		;Get extra delay

	lda	#{6}
	sta	GRP0
	sta	RESP0+$100

	lda	#{7}
	sta	GRP0
	sta	RESP0

	
	ENDM

	MAC	line2

	sta	WSYNC			;0

	ldy	#2				;2
.wait
	dey
	bne	.wait
	nop
	nop
	nop

	lda	#{1}
	sta	GRP0
	sta	RESP0

	lda	#{2}
	sta	GRP0
	sta	RESP0

	lda	#{3}
	sta	GRP0
	sta	RESP0
	
	lda	#{4}
	sta	GRP0
	sta	RESP0

	lda	#{5}
	sta	GRP0
	sta	RESP0+$100

	lda	#{6}
	sta	GRP0
	sta	RESP0+$100

	
	ENDM





	SEG code

	org	$f800				

start

;Set Stack and all up..

	sei
	cld
	ldx	#$ff
	txs

;Clear all memory except $ff/$1ff - Stack end

	lda	#0
clear
	sta	$ff,x
	dex
	bne	clear

;
;Set Joypad to input
;

	stx	SWACNT

;Make test tetris screen...

	lda	#6
	sta	blkx
	lda	#21
	sta	blkoff

	lda	#16
	sta	gamespeed
	sta	counter

;
;
; My Display... Version 1.
;
;


frame
	lda	#2
	sta	WSYNC
	sta	VSYNC  		;VSync
	sta	WSYNC  		;1 line
    sta WSYNC       ;2 lines
	sta	WSYNC  		;3 lines
	lda #0
	sta VSYNC
	lda	#44
	sta	TIM64T		;Timer for 37 lines blanking

;Set score up here...

	lda	#>revdigits	;Units & tens...
	sta	digptr0+1
	sta	digptr1+1
	lda #<revdigits
	sta digptr0
	sta digptr1
	lda	#$f0
	sta nib0
	lda #15
	sta nib1
	lda	score
	ldx	#gfxpf2+4
	jsr	scoredigits

	lda #>digits		;hundreds & thousands
	sta	digptr0+1
	sta digptr1+1
	lda #<digits
	sta	digptr0
	sta digptr1
	lda #15
	sta nib0
	lda #$f0
	sta nib1
	lda score+1
	ldx #gfxpf1+4
	jsr scoredigits


;
;Handle flash message removal..
;

	lda	message
	bmi	none
	beq	none

	dec	message
	bne	none

	ldx	#4
	lda	#0
remove
	sta	gfxpf1+12,x
	sta	gfxpf2+12,x
	dex
	bpl	remove
	
none




	lda	#-1
	sta	scorecount

vb
	lda INTIM			;37 lines VBLANK ended?
	bne	vb
	sta	VBLANK    

;
;	Title display goes here up to 24 lines
;

;
;Title line is interlaced, so two routines are called
;

;Initialise p0&p1

	lda	#$c4
	sta	COLUBK
	lda	#$ce
	sta	COLUP0
	lda	#0
	sta	NUSIZ0
	sta	GRP0
	sta	GRP1

	sta	WSYNC
	lda	counter
	and	#1
	beq	display1
	jmp display2

display1

	line %11111111,%11111111,%11111111,%11111110,%11000000,%01111111,%11000011
	line2 %10000001,%01000011,%10000001,%10000001,%10000001,%00000010
	line %00011000,%00011000,%00011000,%00000001,%10000000,%10000000,%10000001
	line2 %11111000,%01111111,%11111111,%11111111,%11111111,%00000010
	line %00011000,%00011000,%00011000,%10000000,%11000011,%10000000,%10000001
	line2 %10000001,%01001100,%10000001,%10000001,%00011000,%10000010
	line %00111100,%00111100,%11111111,%11111111,%11111110,%01111111,%11000011

	jmp	rest

display2

	line2 %11111111,%11111111,%01111111,%11111111,%11000011,%00000111
	line %10011001,%10011001,%10011001,%10000001,%10000000,%10000001,%10000001
	line2 %10001000,%01000011,%10000000,%10000000,%10000001,%00000010
	line %00011000,%00011000,%00011000,%11111111,%11111110,%10000000,%11111111
	line2 %10001000,%01110000,%00000001,%10000001,%00011000,%00000010
	line %00011000,%00011000,%10011001,%10000001,%11000011,%10000001,%10000001
	line2 %11111111,%11000011,%11111110,%11111111,%00111100,%11111110

rest
	sta	WSYNC
	lda	#0
	sta	GRP0
	sta	GRP1
	sta	WSYNC
	sta	COLUBK

;
;Blank out for 13 lines..

	ldy	#13
gap
	sta	WSYNC
	dey
	bne	gap

;
;Set Tetris background colour for blocks...
;

    lda	#$1e            ;Gold blocks
	sta	blockcol

	lda	#4				;Use P0&P1 as masks 
	sta COLUP0
	lda	#4
	sta COLUP1

	lda	#3
	sta	NUSIZ0
	lda	#1
	sta NUSIZ1


;Position P0 and P1

	sta WSYNC
	ldx	#5
wp
	dex
	bne	wp
	
	sta	RESP0
	sta RESP1

	ldy	#4			;Wait before setting graphics, so they cant be seen
w1
	dey
	bne	w1
	lda	#$11
	sta	GRP0
	lda	#$22
	sta	GRP1


;
;	Basic Tetris display
;	Each block is 8 scanlines x 4 pixels ( using PF1 & PF2 )
;	giving 22 lines of blocks...
;	Score appears on right side for first few lines...


;	First section of display also has score..

	lda	#22
	sta	outercnt
disploop

;First scanline of each block is blank..Might as well fetch stuff here

	lda	#0
	sta WSYNC
	sta	COLUBK
	sta	PF1
	sta	PF2

	lda	blockcol			;Quick hack for block colours
	clc
	adc	#$10
	sta	blockcol+$100


	ldx	scorecount
	inx

	ldy	#4
	sty	COLUBK				;This provides the gray backdrop for the tiles

	lda	gfxpf1,x
	ldy	gfxpf2,x
	ldx	#0
	stx	COLUBK+$100


	sta	PF1
	sty	PF2
	inc	scorecount





;Inner loop for block display
;
; Tetris uses 10 blocks; 8bits PF1 + 2 bits PF2
; I use P0 & P1 as masks to give a more 'blocky' look
;
; I also reuse PF1/2 to show the score and spot graphics

	lda	#7
	sta	blockcnt
inner
	ldy	#4
	sta	WSYNC
	lda	blockcol
	sta	COLUPF
	ldx	outercnt
	lda	left-1,x
	sta	PF1
	lda	right-1,x
	sta	PF2

	ldx	scorecount
	sty	COLUBK+$100

	lda	gfxpf1,x
	ldy	gfxpf2,x
	ldx	#0
	stx	COLUBK+$100

	ldx	#$1e
	stx	COLUPF
	sta	PF1
	sty	PF2


	dec blockcnt
	bne inner
	dec	outercnt
	bne disploop


;Over scan routine... Use timer...


	lda	#2	   		;First line turns on VBLANK 
	sta	WSYNC
	sta	VBLANK

	lda	#36			;Timer for 30 scanlines
	sta	TIM64T


	lda	message		;Check game over state
	bpl	playing


	dec	counter		;Need to update this for text display
	jmp timewait

playing
	dec	counter		;Game state machine and speed
	bne	noreload

	lda	gamespeed
	sta	counter

blockdown

;Counter reached zero, move block down and check

	jsr	drawblock		;Erase old copy of sprite

	lda	blkoff			;Keep old just in case
	sta	save

;Try to move down

	dec	blkoff


	jsr	buildblock
	bcs	stopped
	jsr	testblock
	bcs	stopped
	jmp	okmove

;Block stopped, need new block....

stopped
	lda	save
	sta	blkoff

	jsr	buildblock		;Old pos must be valid
	jsr	drawblock

;Use new block next time

	ldx	nextblock
	lda	blocks,x
	sta	blkid
	inx
	txa
	and	#$3f
	sta	nextblock

	lda	#6
	sta	blkx
	lda	#21
	sta	blkoff

;Now is a good time to check for game over..

	jsr	buildblock
	jsr	testblock
	bcs	endgame


	ldx	#4				;Leave image on screen
	lda	#0
clearimage
	sta	offb4-1,x
	sta	pf1b4-1,x
	sta	pf2b4-1,x
	dex
	bne	clearimage

	beq	timewait

;Copy game over message...
endgame
	ldx	#10
copyend
	lda	endpf1,x
	sta	gfxpf1+9,x
	lda endpf2,x
	sta	gfxpf2+9,x
	dex
	bpl copyend
	stx	message
	bmi timewait


noreload

	lda	counter
	and	#3
	cmp	#2
	bne	checks

	
	lda	SWCHA		;If down pressed, drop block anyway
	and	#$20
	beq	blockdown



;
;Joystick control movement
;

	jsr	drawblock		;Erase old copy of sprite

	lda	blkid			;Keep old just in case
	sta	save
	lda	blkx
	sta	save1

;Move if needed

	bit	SWCHA
	bpl	okright
	bvs	notleft
	dec blkx
	bpl	notleft
okright
	inc blkx
notleft

;Check for Rotation

	bit	INPT4
	bmi	norotate

	lda	blkid
	and	#$f0
	sta	blkid
	lda	save
	clc
	adc	#4
	and	#15
	ora	blkid
	sta	blkid

norotate


	jsr	buildblock
	bcs	cantmove
	jsr	testblock
	bcc	okmove

cantmove
	lda	save
	sta	blkid
	lda	save1
	sta	blkx

	jsr	buildblock		;Redraw at old pos...

okmove
	jsr	drawblock		;Draw block in new 

timewait
	ldy	INTIM
	bne	timewait
	

;Check for reset here....

	lda SWCHB
	and	#1
	beq	resetgame

	jmp	frame

resetgame
	lda	SWCHB
	and	#1
	beq	resetgame
	jmp start

;Check and remove lines....

checks
	jsr	drawblock		;Remove sprite

	ldx	#0
	ldy	#0
checkline:
	lda	left,x
	cmp	#$3f
	bne	notfull
	lda	right,x
	cmp	#$f
	bne	notfull

;Found a complete line here..adjust pointers so it is written over..

	inx
	bne	nextcheck

notfull
	lda	left,x
	sta	left,y
	lda	right,x
	sta	right,y

	iny
	inx
nextcheck
	cpx	#22
	bne	checkline

;Now fill rest with blanks..

	lda	#0
	tax
blankfill
	cpy	#22
	beq	doneblank
	sta	left,y
	sta	right,y
	iny
	inx
	bne	blankfill

doneblank

;Update score and show message...

	txa
	beq noscore
	cmp	#4			;Tetris score 10 points
	bne	normscore
	lda	#$10		;BCD..
normscore
	sed
	clc
	adc	score
	sta	score
	lda	score+1
	adc	#0
	sta	score+1
	cld

	txa
	sta	temp
	asl
	asl
	adc	temp
	tay
	ldx	#4
flashit
	lda	messpf1-1,y
	sta	gfxpf1+12,x
	lda	messpf2-1,y
	sta	gfxpf2+12,x
	dey
	dex
	bpl flashit

	lda	#30
	sta	message

noscore
	jsr	drawblock			;Redraw sprite

	jmp	timewait			;(drawblock returns with Z set)




;
;Game logic subroutines
;

buildblock

	ldx	#4

	ldy	blkid
pixel
	lda	blktab,y			;Combined block table
	ora	#$f0
	sec
	adc	blkoff
	bmi	error

	sta	offb4-1,x

	lda	blktab,y
	and	#$f0
	lsr
	lsr
	lsr
	lsr
	adc	blkx
	sty	temp
	tay
	lda	mask1,y
	bmi	error
	sta	pf1b4-1,x
	lda	mask2,y
	bmi	error
	sta	pf2b4-1,x

	ldy	temp
	iny
	dex
	bne	pixel

	clc
	rts

error
	sec
	rts

;
;Test block ( checks whether block can be drawn )
;

testblock
	ldy	#4
testpixel
	ldx	offb4-1,y
	lda	pf1b4-1,y
	and	left,x
	bne	error
	lda	pf2b4-1,y
	and	right,x
	bne	error
	dey
	bne	testpixel

	clc
	rts

;
;Draw block ( use EOR drawing so same code for erase )
;

drawblock
	ldy	#4
drawpixel
	ldx	offb4-1,y
	lda	pf1b4-1,y
	eor	left,x
	sta	left,x
	lda	pf2b4-1,y
	eor	right,x
	sta	right,x
	dey
	bne	drawpixel
	rts

;
;Draw 2 digits of score
;

scoredigits
	
	tay				
	and	#15
	sta	temp
	asl
	asl
	adc	temp
	adc digptr0
	sta	digptr0

	tya
	and	#$f0
	lsr
	lsr
	sta	temp
	lsr
	lsr
	adc	temp
	adc digptr1
	sta digptr1

	ldy	#4
scoreline
	lda (digptr0),y
	and	nib0
	sta	temp
	lda	(digptr1),y
	and	nib1
	ora temp
	sta 0,x
	dex
	dey
	bpl scoreline	
	rts




;
;Random block list ( I know it is wasteful, but I've go memory to spare
;even on a 2k Cart
;-Spoke too soon, I've had to prune this from 256 to 64 bytes....

bx	= 0
rs	= $10
rs1 = $14
ls	= $20
ls1 = $24
tp	= $30
tp1	= $34
tp2 = $38
tp3 = $3c
ll	= $40
ll1	= $44
ll2	= $48
ll3	= $4c
rl	= $50
rl1	= $54
rl2	= $58
rl3	= $5c
ln	= $60
ln1	= $64

	org	$fe40

;
;Tables and graphics...
;


;Bit mask table for graphics... 0-2 and 13-15 are invalid

mask1
	dc	-1,-1,-1				
	dc	$20,$10,$8,$4,$2,$1		
	dc	0,0,0,0					
mask2
	dc	-1,-1,-1				
	dc	0,0,0,0,0,0
	dc	1,2,4,8
	dc	-1,-1,-1


;Tetris blocks
;4 rotations per block, 7 blocks, 2 bytes code

;Blocks are	stored as four single pixels with line offset and
;X offset for each pixel in relevant table

;Byte encoded as XY, X is X offset, Y is 15-yoffset
;Four rotations in clockwise order

blktab

;## 
;##

	dc	$0f,$1f,$0e,$1e
	dc	$0f,$1f,$0e,$1e
	dc	$0f,$1f,$0e,$1e
	dc	$0f,$1f,$0e,$1e

;.##   .#.
;##.   .##
;...   ..#

	dc	$1f,$2f,$0e,$1e
	dc	$1f,$1e,$2e,$2d
	dc	$1f,$2f,$0e,$1e
	dc	$1f,$1e,$2e,$2d

;##.   ..#
;.##   .##
;...   .#.

	dc	$0f,$1f,$1e,$2e
	dc	$2f,$1e,$2e,$1d
	dc	$0f,$1f,$1e,$2e
	dc	$2f,$1e,$2e,$1d

;.#.  .#.	...	.#.
;###  .##	###	##.
;...  .#.	.#.	.#.

	dc	$1f,$0e,$1e,$2e
	dc	$1f,$1e,$2e,$1d
	dc	$0e,$1e,$2e,$1d
	dc	$1f,$0e,$1e,$1d

;...  .#. 	#..	.##
;###  .#.   ###	.#.
;..#  ##.	...	.#.

	dc	$0e,$1e,$2e,$2d
	dc	$1f,$1e,$0d,$1d
	dc	$0f,$0e,$1e,$2e
	dc	$1f,$2f,$1e,$1d

;...  ##.	..#	 .#.
;###  .#.   ###	 .#.
;#..  .#.	...	 .##

	dc	$0e,$1e,$2e,$0d
	dc	$0f,$1f,$1e,$1d
	dc	$2f,$0e,$1e,$2e
	dc	$1f,$1e,$1d,$2d

;....  .#..
;####  .#..
;....  .#..
;....  .#..

	dc	$0e,$1e,$2e,$3e
	dc	$1f,$1e,$1d,$1c
	dc	$0e,$1e,$2e,$3e
	dc	$1f,$1e,$1d,$1c

;Block waves ( not very random at moment,, sorry )

blocks
	repeat 4
	dc	bx,rs,rs1,ls,ls1,tp,tp1,tp2,tp3,ll,ll1,rl,rl1,ln,ln1,bx
	repend


;Score messages

messpf1
	dc %11101110
	dc %10101010
	dc %10101010
	dc %10101010
	dc %11101010

	dc %11101001
	dc %01001001
	dc %01001101
	dc %01001101
	dc %01001111

	dc %11000001
	dc %10000001
	dc %10110101
	dc %10100101
	dc %10100101

	dc %11011011
	dc %10010010
	dc %10011010
	dc %10010010
	dc %10011010

messpf2
	dc %00000111
	dc %00000001
	dc %00000111
	dc %00000001
	dc %00000111

	dc %00001110
	dc %00000010
	dc %00001110
	dc %00000010
	dc %00001110

	dc %01101011
	dc %00101010
	dc %01101011
	dc %00101000
	dc %01101000

	dc %11000000	
	dc %01000000
	dc %11010110
	dc %10010010
	dc %11010010


endpf1

	dc %11101110
	dc %10001010
	dc %10101110
	dc %10101010
	dc %11101010
	dc 0
	dc %11101010
	dc %10101010
	dc %10101010
	dc %10101010
	dc %11101110
endpf2

	dc %11101111
	dc %00101011
	dc %11101011
	dc %00101001
	dc %11101001
	dc 0
	dc %01110111
	dc %01010001
	dc %01110111
	dc %00110001
	dc %01010111


;Score digits and game highlight graphics...

digits

	dc	%11101110
	dc	%10101010
	dc	%10101010
	dc	%10101010
	dc	%11101110

	dc	%01000100
	dc	%11001100
	dc	%01000100
	dc	%01000100
	dc	%11101110

	dc	%11101110
	dc	%00100010
	dc	%11101110
	dc	%10001000
	dc	%11101110

	dc	%11101110
	dc	%00100010
	dc	%01100110
	dc	%00100010
	dc	%11101110

	dc	%10101010
	dc	%10101010
	dc	%11101110
	dc	%00100010
	dc	%00100010

	dc	%11101110
	dc	%10001000
	dc	%11101110
	dc	%00100010
	dc	%11101110

	dc	%11101110
	dc	%10001000
	dc	%11101110
	dc	%10101010
	dc	%11101110

	dc	%11101110
	dc	%00100010
	dc	%00100010
	dc	%00100010
	dc	%00100010

	dc	%11101110
	dc	%10101010
	dc	%11101110
	dc	%10101010
	dc	%11101110

	dc	%11101110
	dc	%10101010
	dc	%11101110
	dc	%00100010
	dc	%11101110

revdigits

	dc	%01110111
	dc	%01010101
	dc	%01010101
	dc	%01010101
	dc	%01110111

	dc	%00100010
	dc	%00110011
	dc	%00100010
	dc	%00100010
	dc	%01110111

	dc	%01110111
	dc	%01000100
	dc	%01110111
	dc	%00010001
	dc	%01110111

	dc	%01110111
	dc	%01000100
	dc	%01100110
	dc	%01000100
	dc	%01110111

	dc	%01010101
	dc	%01010101
	dc	%01110111
	dc	%01000100
	dc	%01000100

	dc	%01110111
	dc	%00010001
	dc	%01110111
	dc	%01000100
	dc	%01110111

	dc	%01110111
	dc	%00010001
	dc	%01110111
	dc	%01010101
	dc	%01110111

	dc	%01110111
	dc	%01000100
	dc	%01000100
	dc	%01000100
	dc	%01000100

	dc	%01110111
	dc	%01010101
	dc	%01110111
	dc	%01010101
	dc	%01110111

	dc	%01110111
	dc	%01010101
	dc	%01110111
	dc	%01000100
	dc	%01110111




;Boot up points....


	org	$fffc
	dc.w	start                    ; Reset vector
    dc.w	start                    ; IRQ vector
