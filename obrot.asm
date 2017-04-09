#Memory segments (text, data, stack, kernel text, kernel data) are limited to 4MB each starting at their respective base addresses
	.data
	
text1: 	.asciiz "Enter the file path\n"
#fname:	.space 100
fname: 	.asciiz "image1.bmp"	#delete this
rfname: .asciiz "result.bmp"

text2:  .asciiz "\nEnter the number of turns\n"

buf:	.space	2097152
		#10240		# 10kB
		#2097152	# 2MB	
		# change also in readf !!!

enter:		.asciiz "\n"
fOpenInfo: 	.asciiz "\nFile is opened"
fOpenErrorInfo: .asciiz "\nError with opening file"
fReadErrorInfo: .asciiz "\nError with reading file"
closeFInfo: 	.asciiz "\nFile is closed"
numberOfChars:	.asciiz "\nNumber of characters read:\n"

	.text
	.globl main

#t0 - 
#t1 - 
#s0 - The number of turns
#s1 - File descriptor
#s2 - Number of characters read


main:

readfp:	
	li 	$v0, 4
	la 	$a0, text1
	syscall			# print string 1
	#li 	$v0, 8
	#la 	$a0, fname
	#li 	$a1, 100
	#syscall		# read string to path
	#delete this
	li 	$v0, 4
	la 	$a0, fname
	syscall			# print string
	
readn:	
	li 	$v0, 4
	la 	$a0, text2
	syscall			# print string 2
	#li 	$v0, 5
	#syscall 		# read integer
	li	$v0, 1		# set the number of turns
	move	$s0, $v0
	#delete this
	li 	$v0, 1
	move 	$a0, $s0
	syscall			# print integer	
	
openf:	
	li	$v0, 13
	la	$a0, fname
	li	$a1, 0		# open (flags are 0: read, 1: write)
	li	$a2, 0		# mode is ignored
	syscall
	blt	$v0, 0, errorfo	# opening file did not succeed	
	move	$s1, $v0	# file descriptor
	li 	$v0, 4
	la 	$a0, fOpenInfo
	syscall			# print string

readf:	
	li	$v0, 14
	move	$a0, $s1	# pass file descriptor
	la	$a1, buf	# pass address of input buffer
	li	$a2, 2097152	# pass maximum number of characters to read
	syscall
	beq	$v0, 0, errorfr	# reading file did not succeed
	move	$s2, $v0	# number of characters read
	li	$v0, 4
	la	$a0, numberOfChars
	syscall
	li	$v0, 1
	move	$a0, $s2
	syscall
	
	
	
closef1:	
	li	$v0, 16
	move	$a0, $s1	# file descriptor to close
	syscall
	li 	$v0, 4
	la 	$a0, closeFInfo
	syscall			# print string
	
#write:
openf2:	
	li	$v0, 13
	la	$a0, rfname
	li	$a1, 1		# open (flags are 0: read, 1: write)
	li	$a2, 0		# mode is ignored
	syscall
	move	$s1, $v0	# file descriptor
	blt	$s1, 0, errorfo	# opening file did not succeed
	li 	$v0, 4
	la 	$a0, fOpenInfo
	syscall			# print string
write:# write bitmap from memory
	li	$v0, 15
	move	$a0, $s1	# pass fd
	la	$a1, buf	# pass address of output buffer
	move	$a2, $s2	# pass number of characters to write
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
	move	$a0, $s1	# file descriptor to close
	syscall
	li 	$v0, 4
	la 	$a0, closeFInfo
	syscall			# print string
	#j	end
	
end:
	li, 	$v0, 10
	syscall