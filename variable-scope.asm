/*zoom modifier ASM by hetoan2*/

.long 0x214EB1F4, 0x0000000C	#fix for wifi bug

.set rambase,0x81656000			#don't mess with unless you know what you're doing!
.set activator,0x80200F0A

#comment the line below (add # to the front) to use WiiMote + Nunchuck
.set ccpro,1
.ifndef ccpro
.set activator,0x80200EE0
.endif

#button values
.set buttonscope,0x2000	#scope button (L)
.set buttoninc,0x0001	#increase zoom button (up)
.set buttondec,0x4000	#decrease zoom button (down)

.int rambase<<7>>7|0x04000008
.float .05				#increment speed variable
.int rambase<<7>>7|0x0400000C
.float 1				#minimum zoom variable
.int rambase<<7>>7|0x04000010
.float 15				#maximum zoom variable

.set codeaddress,0x8074F640
.set length,end1-start1
.set align,(length%8==0)*-0x60000000
.set numlines,(length+4)/8+(length%8==0)*-1
.int codeaddress<<7>>7|0xC2000000
.int numlines

.set fdefy,0x3F969DC1	#sets default y value zoom (may need changing if issues occur)
.set fbase,17

start1:
lis fbase,fdefy@h
ori fbase,fbase,fdefy@l
cmpw fbase,r4			#contains current zoom level
beq skip				#skip if not scoped
lis fbase,rambase@h		#load rambase
ori fbase,fbase,rambase@l
stw r4,0(fbase)			#store current zoom
lfs f20,0(fbase)		#load as float
lwz r18,4(fbase)		#load zoommult
stw r18,0(fbase)		#store zoommult
lfs f21,0(fbase)		#load as float
fmuls f20,f20,f21		#multiply current zoom by zoommult
stfs f20,0(fbase)		#store newfloat to rambase
lwz r4,0(fbase)			#override current
skip:
stw r4,64(r29)			#overridden asm to store
end1:
.int align
.balignl 8,0

#after: stw r0,68(r29)
#part deux
#before: stw r4,80(r29)
.set codeaddress,0x8074F664

.set length,end2-start2
.set align,(length%8==0)*-0x60000000
.set numlines,(length+4)/8+(length%8==0)*-1

.int codeaddress<<7>>7|0xC2000000
.int numlines


start2:
lis r17,0x4005
ori r17,r17,0xE18F
cmpw r17,r0
beq skip2

lis r17,rambase@h
ori r17,r17,rambase@l
stw r0,0(r17)
lfs f20,0(r17)
lwz r18,4(r17)
stw r18,0(r17)
lfs f21,0(r17)
fmuls f20,f20,f21
stfs f20,0(r17)
lwz r0,0(r17)

skip2:
stw r0,84(r29) 

end2:
.int align
.balignl 8,0

#controller start

.set length,end3-start3
.set align,(length%8==0)*-0x60000000
.set numlines,(length+4)/8+(length%8==0)*-1

.int 0XC0000000
.int numlines

start3:

stwu r1,-80(r1)			#allocate room for r14-r31
stmw r14,8(r1)			#load r14-r31 into stackframe

lis r30,activator@h
ori r30,r30,activator@l
lhz r31,0(r30)			#load buttonpressed

cmpwi r31,buttonscope
beq do_glow
cmpwi r31,buttoninc+buttonscope
beq do_glow
cmpwi r31,buttondec+buttonscope
beq do_glow
b skip_glow

.set baseglow,0x8144BF60
.set glowred,0x3F24A4A0
.set glowgreen,0x3D007FED
.set glowblue,0x3C007FED

do_glow:
lis r24,baseglow@h
ori r24,r24,baseglow@l
li r23,0
startglow:
lis r20,glowred@h
ori r20,r20,glowred@l
lis r21,glowgreen@h
ori r21,r21,glowgreen@l
lis r22,glowblue@h
ori r21,r21,glowblue@l
addi r23,r23,1
stw r20,0(r24)
stw r21,0x10(r24)
stw r22,0x20(r24)
addi r24,r24,0x78		#offset to next player
cmpwi r23,9
blt startglow			#loop for all 9 players

skip_glow:
lis r17,rambase@h
ori r17,r17,rambase@l
cmpwi r31,buttoninc+buttonscope
beq up
cmpwi r31,buttondec+buttonscope
bne store
b down

up:
lfs f23,4(r17)
lfs f24,8(r17)
fadd f23,f23,24
b store

down:
lfs f23,4(r17)
lfs f24,8(r17)
fsub f23,f23,24

store:
lfs f24,0x0C(r17)
lfs f25,0x10(r17)
fcmpo cr0,f23,f24
ble forcesetl
fcmpo cr0,f23,f25
bge forceseth
stfs f23,4(r17)
b popstackframe

forcesetl:
stfs f24,4(r17)
b popstackframe

forceseth:
stfs f25,4(r17)

popstackframe:
lmw r14,8(r1)			#read registers r14 to r31 from stack 
addi r1,r1,80			#free stackframe

blr						#necessary for C0 codetype!!!

end3:
.int align
.balignl 8,0

.long 0xE0000000, 0x80008000