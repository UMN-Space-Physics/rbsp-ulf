#! /bin/csh
#
#   Linux gcc version, shared object lib script.
#
#   This script is a more or less generic library/executable
#   builder for CSPICE products.  It assumes that it is executed
#   from one of the "product" directories in a tree that looks like
#   the one displayed below:
#
#                      package
#                         |
#                         |
#       +------+------+------+------+------+
#       |      |      |      |      |      |
#     data    doc    etc    exe    lib    src
#                                          |
#                                          |
#                         +----------+----------+------- ... ------+
#                         |          |          |                  |
#                     product_1  product_2  product_3    ...   product_n
#
#   Here's the basic strategy:
#
#     1)  Compile all of the .c files in the current directory
#
#     2)  If there are no .pgm files in the current directory this
#         is assumed to be a library source directory.  The name
#         of the library is the same as the name of the product.
#         The library is placed in the "lib" directory in the tree
#         above.  The script is then done.
#
#         If there are .pgm files and there were some .c
#         files compiled the objects are gathered together in the
#         current directory into a library called locallib.a.
#
#     3)  If any *.pgm files exist in the current directory, compile
#         them and add their objects to locallib.a.  Create a C main
#         program file from the uniform CSPICE main program main.x.
#         Compile this main program and link its object with locallib.a,
#         ../../cspice.a and ../../csupport.a. The output
#         executables have an empty extension.  The executables are
#         placed in the "exe" directory in the tree above.
#
#   The environment variable SOCOMPILEOPTIONS containing compile options
#   is optionally set. If it is set prior to executing this script,
#   those options are used. It it is not set, it is set within this
#   script as a local variable.
#
#   References:
#   ===========
#
#   "Unix Power Tools", page 11.02
#      Use the "\" character to unalias a command temporarily.
#
#   "A Practical Guide to the Unix System"
#
#   "The Unix C Shell Field Guide"
#
#   Change History:
#   ===============
#
#   Version 1.0.0  Jan. 1, 2002  Ed Wright
#
#


#
#  Choose your compiler.
#
if ( $?TKCOMPILER ) then
    echo " "
    echo "      Using compiler: "
    echo "      $TKCOMPILER"
else
    set TKCOMPILER  =  "gcc"
    echo " "
    echo "      Setting default compiler:"
    echo $TKCOMPILER
endif


#
#  What compile options do we want to use? If they were
#  set somewhere else, use those values.  The same goes
#  for link options.
#
if ( $?SOCOMPILEOPTIONS ) then
    echo " "
    echo "      Using compile options: "
    echo "      $SOCOMPILEOPTIONS"
else

   #
   #  Compile options:
   #
   set SOOPTIONS        = "-fPIC "
   set INCLUDESOPTIONS  = "-I/usr/local/itt/idl/idl/external -I../../include"
   set WARNINGS1        = "-ansi -Wall -Wundef"
   set WARNINGS2        = " -Wpointer-arith -Wcast-align -Wsign-compare"
   set COMPILEOPTIONS   = "-c -m64"
   set SOCOMPILEOPTIONS =  "$SOOPTIONS $INCLUDESOPTIONS $WARNINGS1 $WARNINGS2 $COMPILEOPTIONS"

   echo " "
   echo "      Setting default compile options:"
   echo "      $SOCOMPILEOPTIONS"
endif


if ( $?TKLINKOPTIONS ) then
    echo " "
    echo "      Using link options: "
    echo "      $TKLINKOPTIONS"
else

    set TKLINKOPTIONS = "-shared -m64 -o"
    set LINKLIB       = "../../lib/cspice.a -lm"
    echo " "
    echo "      Setting default link options:"
    echo "      $TKLINKOPTIONS"
endif

echo " "

#
#   Determine a provisional LIBRARY name.
#
foreach item ( `pwd` )
    set LOCALLIB = $item:t".so"
    set LIBRARY  = "../../lib/"$LOCALLIB
end

#
#  Compile the .c files.
#
foreach SRCFILE ( *.c )
   echo "      Compiling: "   $SRCFILE
   $TKCOMPILER $SOCOMPILEOPTIONS $SRCFILE
end

echo " "

#
#  Link
#
set OBJS = " "

foreach OBFILE ( *.o )
   echo "      Linking: "   $OBFILE
   set OBJS = "$OBJS "$OBFILE
end

$TKCOMPILER $TKLINKOPTIONS $LOCALLIB $OBJS $LINKLIB

\rm *.o
\mv $LOCALLIB $LIBRARY
\cp $item:t".dlm" ../../lib/.

exit 0
