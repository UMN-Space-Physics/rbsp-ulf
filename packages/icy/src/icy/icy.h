/*

-Abstract

   Definitions for the Icy interface.
   
   Do not edit, touch, or in any way alter the code within this file.

-Particulars

   None.

Version-

   Icy 1.0.7 22-FEB-2012 (EDW)

      Removed unused macro definitions:
      
         S_DBL_RET_ARGV( x )        (SpiceDouble*)  &Argv[x]->value.d
         S_INT_RET_ARGV( x )        (SpiceInt*)     &Argv[x]->value.l
        S_BOOL_RET_ARGV( x )        (SpiceBoolean*) &Argv[x]->value.c

   Icy 1.0.6 09-JUL-2009 (EDW)

      Removed the unused macro A_BOOL_RET_ARGV.

      Renamed the less-than-dignified name "cspice_argbarf_cleanup" to 
      "zzicy_argcleanup".'

   Icy 1.0.5 04-AUG-2008 (EDW)

      Added the ICY_MAXPARAMS definition, set to 30. This parameter
      defines the maximum number of arguments permitted to an Icy 
      call. If the paramter is changed, the corresponding value
      in icy.dlm and ticyutil.dlm must change to match, e.g.:
      
         PROCEDURE   CSPICE_APPNDD     0 30
      
      to
      
         PROCEDURE   CSPICE_APPNDD     0 new_value

   Icy 1.0.4 28-APR-2005 (EDW)
      
      Added macro A_BOOL_RET_ARGV(x) to return arrays of booleans.

      Replaced the conversion macro definitions assigned
      to S_INT_ARGV(x) and S_DBL_ARGV(x) with calls
      IDL_LongScalar(Argv[x]) and IDL_DoubleScalar(Argv[x]).
      
      Removed superfluous code from S_STR_RET_ARGV(arg, buff).

      Added CHECK_CALL_FAILURE_MEM2 macro to ensure deallocation of
      cell character memory.

      Added the ICY_ALLOC_CHECK macro. Similar to the standard
      ALLOC_CHECK macro with the addition of a icy_fail
      call to pass the error information back to the IDL interpreter.

   Icy 1.0.1 26-JUL-2004 (EDW)

      Added the A_BOOL_ARGV(x) macro.

   Icy 1.0.0 20-MAY-2004 (EDW)

*/



/*
Max number of return strings, macros for IDL-esque PROCEDURE and
FUNCTION tags, and the default string length.
*/
#define    FUNCTION                    IDL_VPTR

#define    NUMVALS                     1024

#define    PROCEDURE                   void

#define    RET_ARRAY_LEN               1024

#define    SCALAR                      -1

#define    ICY_MAXPARAMS               30

#define    TAG_SIZE(X)  (int)( sizeof(X)/sizeof(*X) )


/*
Cast assignments for common argv component args. As you will see, much of
the interface's functionality involves casting variables to an from
the appropriate types.

   S     indicates a scalar value 
   A     an array
   INT   a value of type SpiceInt
   DBL   a value of type SpiceDouble
   STR   a string (pointer to SpiceChar)
   LEN   the length (measure) of an array
   RET   identifies a scalar return value
 
*/
#define       S_INT_ARGV( x )        (SpiceInt)       IDL_LongScalar(Argv[x])
#define       A_INT_ARGV( x )        (SpiceInt*)      Argv[x]->value.arr->data
#define       S_DBL_ARGV( x )        (SpiceDouble)    IDL_DoubleScalar(Argv[x])
#define       A_DBL_ARGV( x )        (SpiceDouble*)   Argv[x]->value.arr->data
#define      S_BOOL_ARGV( x )        (SpiceBoolean)   Argv[x]->value.c
#define      A_BOOL_ARGV( x )        (SpiceBoolean*)  Argv[x]->value.arr->data
#define       A_LEN_ARGV( x )        (SpiceInt)       Argv[x]->value.arr->n_elts
#define       S_ELL_ARGV( x )        (SpiceEllipse*)  Argv[x]->value.s.arr->data
#define       S_PLN_ARGV( x )        (SpicePlane*)    Argv[x]->value.s.arr->data
#define       S_CEL_ARGV( x )        (SpiceCell*)     Argv[x]->value.s.arr->data
#define       S_STR_ARGV( x )        IDL_STRING_STR( &Argv[x]->value.str)
#define           RETURN_BOOL        UCHAR



/*
Code to pack a CSPICE string into an Argv element for return to the IDL
environment. Use this macro for all return strings. This is a _COPY_
operation.
*/
#define S_STR_RET_ARGV(arg, buff)  IDL_VarCopy(IDL_StrToSTRING(buff), Argv[arg])

/* 
Define the flags to indicate read-write-read and write. 
*/
#define OREAD                      IDL_EZ_ACCESS_R
#define OWRIT                      IDL_EZ_ACCESS_W
#define RDWRT                      IDL_EZ_ACCESS_RW


/*
These macros checks for the status of failed_c to detect a SPICE error
signal.

If found, the argument cleanup routine executes, freeing/deleting
any temp memory, resetting the error system, the interface then
passes the error message to the user.

Code should call this macro after a call to any subroutine or function
that might signal a SPICE error.

The routine "zzicy_argcleanup" cleans up those temporary variables
allocated for the interface.

The "icy_fail" call builds the traceback string, passing that string
and the error message to IDL, then reset the SPICE error system. 'cnt' 
indicates whether the call occured in a scalar context, 'cnt' equals
SCALAR, or vector, 'cnt' equals vector index.
*/
#define CHECK_CALL_FAILURE( cnt )                                  \
                          if ( failed_c())                         \
                             {                                     \
                             zzicy_argcleanup( Argc,       \
                                                       Argv_orig,  \
                                                       argcheck,   \
                                                       Argv );     \
                             icy_fail(cnt);                        \
                             }



/*
CHECK_CALL_FAILURE_MEM(n,arr) performs the same functions as in
CHECK_CALL_FAILURE but also frees memory blocks allocated by the
alloc_SpiceString_C_array routines.
*/
#define CHECK_CALL_FAILURE_MEM(n,arr)                             \
                          if ( failed_c())                        \
                             {                                    \
                             free_SpiceString_C_array ( n, arr ); \
                                                                  \
                             zzicy_argcleanup( Argc,      \
                                                       Argv_orig, \
                                                       argcheck,  \
                                                       Argv );    \
                             icy_fail(SCALAR);                    \
                             }



/*
CHECK_CALL_FAILURE_MEM1(arr,cnt) performs the same functions as in
CHECK_CALL_FAILURE but frees memory blocks allocated by the
alloc_Spice[Double|Int|String]* routines. 'cnt' indicates whether
the call occured in a scalar context, 'cnt' equals SCALAR, or 
vector, 'cnt' equals vector index.
*/
#define CHECK_CALL_FAILURE_MEM1( arr, cnt )                       \
                          if ( failed_c())                        \
                             {                                    \
                             free_SpiceMemory( arr );             \
                                                                  \
                             zzicy_argcleanup( Argc,      \
                                                       Argv_orig, \
                                                       argcheck,  \
                                                       Argv );    \
                             icy_fail(cnt);                 \
                             }




/*
CHECK_CALL_FAILURE_MEMn macros performs the same functions as in
CHECK_CALL_FAILURE but also frees memory blocks allocated to SPICE_CHR
cells in the base field. 'cnt' indicates whether the call occured in 
a scalar context, 'cnt' equals SCALAR, or vector, 'cnt' equals vector
index.
 */
#define CHECK_CALL_FAILURE_MEM2( cell, cnt )                      \
                          if ( failed_c())                        \
                             {                                    \
                             if ( cell.dtype == SPICE_CHR )       \
                                {                                 \
                                free_SpiceMemory( cell.base );    \
                                }                                 \
                                                                  \
                             zzicy_argcleanup(         Argc,      \
                                                       Argv_orig, \
                                                       argcheck,  \
                                                       Argv );    \
                             icy_fail(cnt);                       \
                             }


#define CHECK_CALL_FAILURE_MEM3( cell1, cell2, cnt )              \
                          if ( failed_c())                        \
                             {                                    \
                             if ( cell1.dtype == SPICE_CHR )      \
                                {                                 \
                                free_SpiceMemory( cell1.base );   \
                                }                                 \
                                                                  \
                             if ( cell2.dtype == SPICE_CHR )      \
                                {                                 \
                                free_SpiceMemory( cell2.base );   \
                                }                                 \
                                                                  \
                             zzicy_argcleanup(         Argc,      \
                                                       Argv_orig, \
                                                       argcheck,  \
                                                       Argv );    \
                             icy_fail(cnt);                       \
                             }


#define CHECK_CALL_FAILURE_MEM4( cell1, cell2, cell3, cnt )       \
                          if ( failed_c())                        \
                             {                                    \
                             if ( cell1.dtype == SPICE_CHR )      \
                                {                                 \
                                free_SpiceMemory( cell1.base );   \
                                }                                 \
                                                                  \
                             if ( cell2.dtype == SPICE_CHR )      \
                                {                                 \
                                free_SpiceMemory( cell2.base );   \
                                }                                 \
                                                                  \
                             if ( cell3.dtype == SPICE_CHR )      \
                                {                                 \
                                free_SpiceMemory( cell3.base );   \
                                }                                 \
                                                                  \
                             zzicy_argcleanup(         Argc,      \
                                                       Argv_orig, \
                                                       argcheck,  \
                                                       Argv );    \
                             icy_fail(cnt);                       \
                             }




/*
Simple macro based on ALLOC_CHECK to ensure a zero value alloc count
at end of routine, if not, pass the error message to the IDL interpreter.
Note, the need to use this macro exists only in those routines
allocating/deallocating memory.
*/
#define ICY_ALLOC_CHECK  if ( alloc_count( "=" ) != 0 )                    \
                {                                                          \
                setmsg_c ( "ICY(BUG): Malloc/Free count not zero at end "  \
                           "of routine. Malloc count = #. Contact NAIF." );\
                errint_c ( "#", alloc_count ( "=" )    );                  \
                sigerr_c ( "SPICE(MALLOCCOUNT)"        );                  \
                icy_fail(SCALAR);                                          \
                }   

