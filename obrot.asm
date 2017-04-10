	.data	
text1: 	.asciiz "Enter the file path \n"
text2:  .asciiz "Enter the number of turns \n"
#fname:	.space 100
fname: 	.asciiz "image1.bmp"
rfname: .asciiz "result.bmp"

buf:	.space	2097152
		#10240		# 10kB
		#2097152	# 2MB

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

	.text
	.globl main

#t0 - File descriptor
#t1 - 
#s0 - The number of turns
#s1 - The size of the BMP file in bytes
#s2 - The offset of image data (pixel array)
#s3 - Address of allocated memory
#s4 - The bitmap width in pixels
#s5 - The bitmap height in pixels
#s6 - The bitmap width in bytes
#s7 - The bitmap height in bytes



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
	move	$t0, $v0	# file descriptor
	#print "File is opened"
	jal	openFile
	
#read file
	#bitmap file header
	#read "BM"
	li	$v0, 14
	move	$a0, $t0	# pass file descriptor
	la	$a1, buf	# pass address of input buffer
	li	$a2, 2		# pass maximum number of characters to read
	syscall
	beq	$v0, 0, errorfr	# reading file did not succeed
	#read the size of the BMP file in bytes
	li	$v0, 14
	move	$a0, $t0	# pass file descriptor
	la	$a1, buf	# pass address of input buffer
	li	$a2, 4		# pass maximum number of characters to read
	syscall
	beq	$v0, 0, errorfr	# reading file did not succeed
	lw	$s1, buf
	#print bits number - ok
	jal	bitesNumber
	#read 4 reserved bytes = 0
	li	$v0, 14
	move	$a0, $t0	# pass file descriptor
	la	$a1, buf	# pass address of input buffer
	li	$a2, 4		# pass maximum number of characters to read
	#read the offset of image data (pixel array)
	li	$v0, 14
	move	$a0, $t0	# pass file descriptor
	la	$a1, buf	# pass address of input buffer
	li	$a2, 4		# pass maximum number of characters to read
	syscall
	lw 	$s2, buf
	
	#allocate heap memory
	li	$v0, 9
	move	$a0, $s1	#number of bits
	syscall
	move	$s3, $v0	#save the address of allocated memory
	
	#read rest of file to allocated memory (14)
	li	$v0, 14
	move	$a0, $t0	# pass file descriptor
	move	$a1, $s3	# allocated memory
	move	$a2, $s1	# pass maximum number of characters to read
	syscall
	
#close file
	li	$v0, 16
	move	$a0, $t0	# file descriptor to close
	syscall
	#print aboute close
	jal	closeFile
	
#save size from allocated memory
	#the bitmap width in pixels
	lw	$s4, 8($s3)
	jal	printWidth
	#the bitmap height in pixels
	lw	$s5, 12($s3)
	jal	printHeight

#Calculate size in bytes
	#the bitmap width in bytes
	li	$t1, 0
	addi	$t1, $s4, 31
	srl	$t1, $t1, 5
	sll	$t1, $t1, 2
	move	$s6, $t1
	jal	printWidthBytes
	#the bitmap height in bytes
	li	$t1, 0
	addiu	$t1, $s5, 31
	srl	$t1, $t1, 5
	sll	$t1, $t1, 2
	move	$s7, $t1
	jal	printHeightBytes
	
	
	j	end	
#write:
openf2:	
	li	$v0, 13
	la	$a0, rfname
	li	$a1, 1		# open (flags are 0: read, 1: write)
	li	$a2, 0		# mode is ignored
	syscall
	move	$t0, $v0	# file descriptor
	blt	$t0, 0, errorfo	# opening file did not succeed
	li 	$v0, 4
	la 	$a0, fOpenInfo
	syscall			# print string
write:# write bitmap from memory
	li	$v0, 15
	move	$a0, $t0	# pass fd
	la	$a1, buf	# pass address of output buffer
	move	$a2, $s1	# pass number of characters to write
	syscall
	# check ...
	j	closef
	
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
	move	$a0, $t0	# file descriptor to close
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
	move	$a0, $s1
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
	move	$a0, $s4
	syscall
	j 	printEnter
printHeight:
	li 	$v0, 4
	la 	$a0, height
	syscall
	li	$v0, 1
	move	$a0, $s5
	syscall
	j 	printEnter
printWidthBytes:
	li 	$v0, 4
	la 	$a0, widthBytes
	syscall
	li	$v0, 1
	move	$a0, $s6
	syscall
	j 	printEnter
printHeightBytes:
	li 	$v0, 4
	la 	$a0, heightBytes
	syscall
	li	$v0, 1
	move	$a0, $s7
	syscall
	j 	printEnter
	

printEnter:
	li	$v0, 4
	la 	$a0, enter
	syscall
	jr	$ra