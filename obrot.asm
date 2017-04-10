#t0 - File descriptor
#t1 - 
#s0 - The number of turns
#s1 - Address of allocated memory
#s2 - Address of pixels data 1
#s3 - Address of pixels data 2
#s4 - The bitmap width in bytes
#s5 - The bitmap height in bytes
#s6 - The bitmap height * width
#s7 - The number of bytes per pixel
	
.eqv 	deskryptor 	$t0
.eqv 	adr_mem 	$s1
.eqv 	adr_pb1 	$s2
.eqv 	adr_pb2 	$s3
.eqv 	width_B 	$s4
.eqv 	height_B	$s5
.eqv 	size_pixel_area $s6
.eqv 	bytes_per_pixel	$s7

		
	.data	
text1: 	.asciiz "Enter the file path \n"
text2:  .asciiz "Enter the number of turns \n"
#fname:	.space 100
fname: 	.asciiz "image2.bmp"
rfname: .asciiz "result.bmp"

buf:	.space	2097152
		#10240		# 10kB
		#2097152	# 2MB
BM:	.asciiz  "BM"

enter:		.asciiz "\n"
fOpenInfo: 	.asciiz "File is opened \n"
fOpenErrorInfo: .asciiz "Error with opening file \n"
fReadErrorInfo: .asciiz "Error with reading file \n"
closeFInfo: 	.asciiz "File is closed \n"
numberOfChars:	.asciiz "The size of the BMP file in bytes: \n"
width:		.asciiz "width in pixels: \n"
height:		.asciiz "height in pixels: \n"
widthBytes:	.asciiz "width in bytes: \n"
heightBytes:	.asciiz "height in bytes: \n"
bytesPixel:	.asciiz "Bytes per pixel: \n"

	.text
	.globl main

main:

#read file path	
	li 	$v0, 4
	la 	$a0, text1
	syscall			# print string 1
	#li 	$v0, 8
	#la 	$a0, fname
	#li 	$a1, 100
	#syscall		# read string to path
	#print path
	jal	pathFile
	
#read number of turns	
	li 	$v0, 4
	la 	$a0, text2
	syscall			# print string 2
	#li 	$v0, 5
	#syscall 		# read integer
	li	$v0, 1		# set the number of turns
	move	$s0, $v0
	#print number of turn
	jal	turnNumber
	
#open file
	li	$v0, 13
	la	$a0, fname	# file path
	li	$a1, 0		# open (flags are 0: read, 1: write)
	li	$a2, 0		# mode is ignored
	syscall
	blt	$v0, 0, errorfo	# opening file did not succeed	
	move	deskryptor, $v0	# file descriptor
	#print "File is opened"
	jal	openFile
	
#read file
	#bitmap file header
	#read "BM"
	li	$v0, 14
	move	$a0, deskryptor	# pass file descriptor
	la	$a1, buf	# pass address of input buffer
	li	$a2, 2		# pass maximum number of characters to read
	syscall
	beq	$v0, 0, errorfr	# reading file did not succeed
	#read the size of the BMP file in bytes
	li	$v0, 14
	move	$a0, deskryptor	# pass file descriptor
	la	$a1, buf	# pass address of input buffer
	li	$a2, 4		# pass maximum number of characters to read
	syscall
	beq	$v0, 0, errorfr	# reading file did not succeed
	lw	$t9, buf
	#print bits number - ok
	jal	bitesNumber
	
	#allocate heap memory
	li	$v0, 9
	move	$a0, $t9	#number of bits
	syscall
	move	adr_mem, $v0	#save the address of allocated memory
	
	#save the size of the BMP file
	sw	$t9, (adr_mem)
	
	#read rest of file to allocated memory (14)
	li	$v0, 14
	move	$a0, deskryptor	# pass file descriptor
	#move	$a1, adr_mem	# allocated memory
	addiu	$a1, adr_mem, 4	# We need to shift allocated memory by 4 bytes
	lw	$a2, (adr_mem)	# pass maximum number of characters to read
	syscall
	
#close file
	li	$v0, 16
	move	$a0, deskryptor	# file descriptor to close
	syscall
	#print aboute close
	jal	closeFile
	
	
#size from allocated memory
	#the bitmap width in pixels
	jal	printWidth
	#the bitmap height in pixels
	jal	printHeight

#Calculate size in bytes (with padding)
	#the bitmap width in bytes
	lw	$t1, 16(adr_mem)	#image width
	lh	$t2, 26(adr_mem)	#bits per pixel
	mul	$t1, $t1, $t2
	addiu	$t1, $t1, 31
	srl	$t1, $t1, 5
	sll	$t1, $t1, 2
	move	width_B, $t1
	jal	printWidthBytes
	#the bitmap height in bytes
	lw	$t1, 20(adr_mem)	#image width
	lh	$t2, 26(adr_mem)	#bits per pixel
	mul	$t1, $t1, $t2
	addiu	$t1, $t1, 31
	srl	$t1, $t1, 5
	sll	$t1, $t1, 2
	move	height_B, $t1
	jal	printHeightBytes
	
#set the number of bytes per pixel
	lh 	bytes_per_pixel, 26(adr_mem)
	div	bytes_per_pixel, bytes_per_pixel, 8
	#print bytes per pixel
	jal	printBytesPerPixel
	
	#load and chang offset of image data
	lw	$t9, 8(adr_mem)
	sub 	$t9, $t9, 2
	#change pointer of first allocated memory to image data		 	#note !!!!!
	add	adr_pb1, adr_mem, $t9
	
#create new allocated memory
	#width * height
	mul	size_pixel_area, height_B, width_B
	#allocate heap memory
	li	$v0, 9
	move	$a0, size_pixel_area	#number of bits
	syscall
	move	adr_pb2, $v0	#save the address of allocated memory
	
	
#rotate!!!
	#(i,j) - position in pixels data 1
	#(k,m) - position in pixels data 2
	#(i,j) = i*bytes_per_pixel + j*width_B
	#(k,m) = k*bytes_per_pixel + m*height_B
	#
	#for(j=0, k=height-1;	j<height;	++j, --k)
	#	for(i=0, m=0;	j<width;	++i, ++m)
	#		(k,m) = (i,j)	- rewrite bytes_per_pixel times
	#
	#$t1 - i
	#$t2 - j
	#$t3 - k
	#$t4 - m
	#$t5 - width
	#$t6 - height
	#$t7 - (i,j)
	#$t8 - (k,m)
	#$t9 - for help
	lw	$t5, 16(adr_mem)	#width
	lw	$t6, 20(adr_mem)	#height
	li	$t2, 0
	sub	$t3, $t6, 1
rotateLoop1:
	li	$t1, 0
	li	$t4, 0
rotateLoop2:
	#copy pixel
	#$t7 = i*bytes_per_pixel + j*width_B
	mul	$t7, $t1, bytes_per_pixel
	mul	$t9, $t2, width_B
	add	$t7, $t7, $t9
	add	$t7, $t7, adr_pb1
	#$t8 = k*bytes_per_pixel + m*height_B
	mul	$t8, $t3, bytes_per_pixel
	mul	$t9, $t4, height_B
	add	$t8, $t8, $t9
	add	$t8, $t8, adr_pb2
	#copy bytes
	lb	$t9, 0($t7)
	sb	$t9, 0($t8)
	lb	$t9, 1($t7)
	sb	$t9, 1($t8)
	lb	$t9, 2($t7)
	sb	$t9, 2($t8)
	
	add	$t1, $t1, 1
	add	$t4, $t4, 1
	blt	$t1, $t5, rotateLoop2
	#end of rotateLoop2
	add	$t2, $t2, 1
	sub	$t3, $t3, 1
	blt	$t2, $t6, rotateLoop1
	#end of rotateLoop1
	

#copy pixels data 2 to pixels data 1
	#move 	$t1, size_pixel_area
	#move	$t2, adr_pb1
	#move	$t3, adr_pb2
copyLoop:
	#subiu	$t1, $t1, 1
	#lb 	$t4, ($t3)
	#sb	$t4, ($t2)
	#addiu	$t2, $t2, 1
	#addiu	$t3, $t3, 1
	#bnez	$t1, copyLoop

#swap width and height
	lw	$t1, 16(adr_mem)
	lw	$t2, 20(adr_mem)
	sw	$t1, 20(adr_mem)
	sw	$t2, 16(adr_mem)

#open file
	li	$v0, 13
	la	$a0, rfname	# file path
	li	$a1, 1		# open (flags are 0: read, 1: write)
	li	$a2, 0		# mode is ignored
	syscall
	blt	$v0, 0, errorfo	# opening file did not succeed	
	move	deskryptor, $v0	# file descriptor
	#print "File is opened"
	jal	openFile
	
#write to file
	#write "BM"
	li	$v0, 15
	move	$a0, deskryptor	# pass file descriptor
	la	$a1, BM		# pass address of input buffer
	li	$a2, 2		# pass maximum number of characters to read
	syscall
	#write rest of file
	li	$v0, 15
	move	$a0, deskryptor	# pass file descriptor
	move	$a1, adr_mem	# pass address of input buffer
	lw	$a2, 8(adr_mem)	# pass maximum number of characters to read
	sub	$a2, $a2, 2	# -2B <-> BM
	syscall
	#write rest of file
	li	$v0, 15
	move	$a0, deskryptor	# pass file descriptor
	move	$a1, adr_pb2	# pass address of input buffer
	move	$a2, size_pixel_area	# pass maximum number of characters to read
	syscall

#close file
	li	$v0, 16
	move	$a0, deskryptor	# file descriptor to close
	syscall
	#print aboute close
	jal	closeFile
	
	
	j	end
errorfo:
	li 	$v0, 4
	la 	$a0, fOpenErrorInfo
	syscall			# print string
	j	end

errorfr:
	li 	$v0, 4
	la 	$a0, fReadErrorInfo
	syscall			# print string
	j	closef

closef:	
	li	$v0, 16
	move	$a0, deskryptor	# file descriptor to close
	syscall
	li 	$v0, 4
	la 	$a0, closeFInfo
	syscall			# print string
	#j	end
	
end:
	li, 	$v0, 10
	syscall

#jal... $ra
pathFile:
	li 	$v0, 4
	la 	$a0, fname
	syscall 
	j	printEnter
turnNumber:
	li 	$v0, 1
	move 	$a0, $s0
	syscall
	j	printEnter
openFile:
	li 	$v0, 4
	la 	$a0, fOpenInfo
	syscall
	jr	$ra
bitesNumber:
	li	$v0, 4
	la	$a0, numberOfChars
	syscall
	li	$v0, 1
	move	$a0, $t9
	syscall
	j	printEnter
closeFile:
	li 	$v0, 4
	la 	$a0, closeFInfo
	syscall
	jr	$ra
printWidth:
	li 	$v0, 4
	la 	$a0, width
	syscall
	li	$v0, 1
	lw	$a0, 16(adr_mem)
	syscall
	j 	printEnter
printHeight:
	li 	$v0, 4
	la 	$a0, height
	syscall
	li	$v0, 1
	lw	$a0, 20(adr_mem)
	syscall
	j 	printEnter
printWidthBytes:
	li 	$v0, 4
	la 	$a0, widthBytes
	syscall
	li	$v0, 1
	move	$a0, width_B
	syscall
	j 	printEnter
printHeightBytes:
	li 	$v0, 4
	la 	$a0, heightBytes
	syscall
	li	$v0, 1
	move	$a0, height_B
	syscall
	j 	printEnter
printBytesPerPixel:
	li 	$v0, 4
	la 	$a0, bytesPixel
	syscall
	li	$v0, 1
	move	$a0, bytes_per_pixel
	syscall
	j	printEnter
	

printEnter:
	li	$v0, 4
	la 	$a0, enter
	syscall
	jr	$ra
