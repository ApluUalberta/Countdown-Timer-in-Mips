
# Unix ID:              Aplu
# Lecture Section:      B2
# Instructor:           Karim Ali
# Lab Section:          H10 (Thursday 1700 - 1930)
# Teaching Assistant:   Ahmed Elbashir
#---------------------------------------------------------------
#---------------------------------------------------------------
# 
# This program is a countdown timer that parses user input in the form of seconds (eg. 5999 seconds). The user input cna only be between 0 (inclusive) to 5999.
# The program displays the seconds in the form of mm:ss (where m denotes minutes and s denotes seconds). For every second, the clock decrements seconds.
# When seconds drops below 00, the least significant minute decrements and seconds resets to 59.
# This program only works for <= 5999 seconds (99:59).
# When the timer reaches 0, 00:00 is displayed and the program quits
# If the user inputs q at any time during the coundown, the program quits


# DISCLAIMER: an attricute of spim decides to quit this program at around 25 minutes... Likely unfixable with the program.

# Register Usage:
#   $t0: In exception handler, t0 is used as a mask of 1 to check if certain bits of the coprocessor register (often 13) is equal to 0
#           > stores and pushes the contents it masks into coprocessor registers, contains dividers, upper limit for input, buffer address, NUL, q
#   $t1: Contains 60 to split up seconds and minutes, address of display control register, address of data display register
#   $t2: Contains both minute digits, and *(0xffff0008) or the display control register to check if ready
#   $t3: Contains both seconds to be split up individually, then used as &buffer to load 88888mm:ss0 in memory
#   $t4: Acts as an 8 mask to store into buffer memory
#   $t5: Contains the most significant minute
#   $t6: Contains the less significant minute
#   $t7: Contains the most significant second
#   $t8: Contains the less significant second
#   $s2: Contains the user input that is to be decremented as each second goes by
#   $v0: Contains the command to print "seconds = ", user input, and ending the program
#   $k0: Contains the cause register whose bits are to be checked and the address of the keyboard data register
#   $k1: Contains the cause register whose bits are to be checked and also an updated, shifted verison of the cause register
#   $9: Contains the Timer register to be compared to 100 in order to decrement the time every second (timer works in milliseconds)
#   $11: Contains the value that the timer register compares itself to, once the time equals this register, the interrupt (timer type) occurs.
#   $12: Status register that enables interrupts in general, and the type of interrupt that has occurred.
#   $13: Contains the type of interupt that has occurred, (15th bit or 11th bit). 11th bit for quit, 15th for timer type.
#---------------------------------------------------------------
# CMPUT 229 Student Submission License (Version 1.1)

# Copyright 2018 Allen Lu

# Unauthorized redistribution is forbidden in all circumstances. Use of this software without explicit authorization from the author or CMPUT 229 Teaching Staff is prohibited.

# This software was produced as a solution for an assignment in the course CMPUT 229 (Computer Organization and Architecture I) at the University of Alberta, Canada. This solution is confidential and remains confidential after it is submitted for grading. The course staff has the right to run plagiarism-detection tools on any code developed under this license, even beyond the duration of the course.

# Copying any part of this solution without including this copyright notice is illegal.

# If any portion of this software is included in a solution submitted for grading at an educational institution, the submitter will be subject to the sanctions for plagiarism at that institution.

# This software cannot be publicly posted under any circumstances, whether by the original student or by a third party. If this software is found in any public website or public repository, the person finding it is kindly requested to immediately report, including the URL or other repository locating information, to the following email address: cmput229@ualberta.ca.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


.kdata
s0: .word 0
s1: .word 0
s2: .word 0
.ktext 0x80000180

    # store the input register and any used registers other than k0 and k1 into saved values in the register
    .set noat
    sw $at, s2
    .set at
    
    sw $t0, s1                  # s1 <- $t0
    # store the temp registers used

    # read the cause register for quit
    mfc0 $k1, $13                # k1 <- cause register
    # sll $k1, $k0, 4            # if the user interrupts (if 11th bit of register 13 is 1), then jump to check if q
    srl $k1, $k1, 11             # isolate the first bit of the cause register
    andi $k1, 1                  #   > andi with 1

    bne $k1, $0, quitcheck       # if the first bit is not 0, jump to the branch that quits the program

    # check if there is a timer interrupt, or if $9 == $11. this is signified by bit 15 of register 15 being equal to 1
    # this is causing the problem
    li $t0, 1                    # t0 <- 1
    mfc0 $k0, $13                # k0 <- cause register
    srl $k1, $k0, 15             # k1 <- cause register shifted by 15 (isolating the 15th bit)
    andi $k1, $k1, 1             # k1 <- 1 or 0
    beq $0, $k1, return          # if k1 == 0, then return

    # timer section
    mtc0 $0, $9                  # 0 -> timer register
    lw  $t0, change              # t0 <- change
    li  $t0, 1                   # t0 = 1
    sw  $t0, change              # change = 1
    # this is causing he problem

    j return                     # skip he quit code and go to restore and return from exception handling

quitcheck:

    #check if q was the input
    addi $t0, $0, 113               # $t0 <- q (ascii representation)

    lw $k0, 0xffff0004              # k0 <- address of keyboard data register
    bne $t0, $k0, return            # if the keyboard interrupt input = q, execute the code below

    li $v0, 10                      # end the program
    syscall

    return:
        # clear register 13
        mtc0 $0, $13                # 0 -> cause register (clearing method)
        # re-enable the interrupts (register 12)
        mfc0 $t0, $12
        ori $t0, 0x8801             # put 1's in the 15th bit, the 11th bit, and the first bit
        mtc0 $t0, $12               # t0 -> status register
        # restore the saved values
                                    
        lw $t0, s1                  # restore t0
        .set noat
        lw $at, s2
        .set at

        eret                        # return

.data

change: .word 0
seconds: .asciiz "seconds = "
colon: .asciiz " : "

.align 2
buffer: .space 44                   # allocate space for the entire buffer (int)
.text

.globl __start
__start:

    # initialize check if there is a keyboard interrupt
    li $t0, 0                       # timer register <- 0
    mtc0 $t0, $9

    li $t0, 100                     # compare register <- 100
    mtc0 $t0, $11                   # every 100 milliseconds (1 second), a timer interrupt occurs

    mfc0 $t0, $12                   # t0 <- status register
    ori $t0, 0x8801                 # t0 <- change the 15th, 11th, and 1st register
    mtc0 $t0, $12                   # updated register -> status register

    # initialize check if there is a keyboard interrupt
    lui $t0, 0xffff                 # t0 <- 0xffff
    ori $t0, $t0, 0x02              # t0 <- 0xffff0002
    sw $t0, 0xffff0000              # *0xffff0000 = 0xffff0002

    # print the seconds label

    li $v0, 4                   # print string command
    la $a0, seconds             # print "seconds ="
    syscall

    #parse user input
    li $v0, 5                   # parse user input command
    syscall

    # assume input is between 0 - 99:59 (check?)
    addi $s2, $v0, 0            # s2 <- v0 (just in case we need inital v0 later)

    # checks if input is correct

    blez $s2, done              # if input < 0, jump to end the program
    li $t0, 6000                # t0 <- 6000 (upper limit)
    bge $s2, $t0, done          # if input >= 6000, jump to the end of a program
    jal bufferprint             # jump to the loading of the buffer
    j		printalg		    # jump to target
    

                                 # store the time from coprocessor register into s0

bufferprint:

    li $t1, 60                  # t1 <- 60
    div $s2, $t1                # input / 60
    mflo $t2                    # t2 <- quotient  (minutes)
    mfhi $t3                    # t3 <- remainder (seconds)

    li $t0, 10                  # t0 <- 10
    div $t2, $t0                # minutes / 10
    mflo $t5                    # t5 <- quotient (the most significant minute)
    mfhi $t6                    # t6 <- remainder (the less significant minute)

    #isolate seconds into registers
    div $t3, $t0                # seconds / 10
    mflo $t7                    # t7 <- quotient (most significant second)
    mfhi $t8                    # t8 <- remainder (least significant second)

    addi $t5, $t5, 48           # t5 <- ascii value for the most significant minute
    addi $t6, $t6, 48           # t6 <- ascii value for less significant minute
    addi $t7, $t7, 48           # t7 <- ascii value for the most significant second
    addi $t8, $t8, 48           # t8 <- ascii value for the least significant second

    # load buffer
    la $t3, buffer              # t3 <- &buffer
    li $t4, 8                   # t4 <- 8
    sw $t4, 0($t3)              # 8 -> *t3
    sw $t4, 4($t3)              # 8 -> *(t3 + 1)
    sw $t4, 8($t3)              # 8 -> *(t3 + 2)
    sw $t4, 12($t3)             # 8 -> *(t3 + 3)
    sw $t4, 16($t3)             # 8 -> *(t3 + 4)

    sw $t5, 20($t3)             # most significant minute -> *(t3 + 5)
    sw $t6, 24($t3)             # less significant minute -> *(t3 + 6)

    li $t0, 58                  # t0 <- :
    sw $t0, 28($t3)             # : -> *(t3 + 7)

    sw $t7, 32($t3)             # most significant second -> *(t3 + 8)
    sw $t8, 36($t3)             # least significant second -> *(t3 + 9)
    
    li $t0, 0                   # t0 <- 0
    sw $t0, 40($t3)             # NULL -> *(t3 + 10)
    jr		$ra					# jump to $ra
    

printalg:

    #change = 0
    la $t0, buffer              # q <- address of the first clock character
NEXT1:
    #display_string(q)
poll:
    lui $t1, 0xffff
    ori $t1, $t1, 0x0008        # $t1 <- 0xffff0008
    lw $t2, 0($t1)              # read the display control register
    beq $t2, $0, poll           # if not ready, or if the contents of the display control register = 0

    # write *q to data display register
    lui $t1, 0xffff
    ori $t1, $t1, 0x000c        # $t1 <- 0xffff000c
    lw $t3, 0($t0)              # t3 <- address of the first clock character
    sw $t3, 0($t1)              # *0xffff000c = *q

    addi $t0, $t0, 4            # q++
    lw $t3, 0($t0)              # t3 <- first character in the buffer

    
    bne $t3, $0, NEXT1          # if *q != NULL jump back to NEXT1

FOREVER:
    lw $t0, change              # t0 <- change
    beq $t0, $0, FOREVER        # if change == 0, jump back (exception handling indicator)

 
    addi $s2, $s2, -1           # input = input - 1

    jal bufferprint             # jump back to pinting the buffer
    sw $0, change               # change = 0

    la $t0, buffer              # t0 <- &buffer

NEXT2:

poll1:
    lui $t1, 0xffff             # t1 <- 0xffff0000
    ori $t1, $t1, 0x0008        # t1 <- 0xffff0008
    lw $t2, 0($t1)              # t2 <- *(t1)
    beq $t2, $0, poll1          # if *t1 == 0, jump back to poll1 and repeat

    lui $t1, 0xffff             # t1 <- 0xffff0000
    ori $t1, $t1, 0x000c        # t1 <- 0xffff000c
    lw $t3, 0($t0)              # t3 <- *(buffer)
    sw $t3, 0($t1)              # *buffer -> *(0xffff000c)



    addi $t0, $t0, 4            # t0 <- t0 + 1 (increment pointer)
    lw $t3, 0($t0)              # t3 <- *t0
    bne $t3, $0, NEXT2          # if *t0 == 0. jump back to NEXT2 and repeat

    beq $s2, $0, done           # if input == 0, end the program

    j FOREVER                   # jump back to forever loop


done:

    li $v0, 10              # end the program
    syscall
