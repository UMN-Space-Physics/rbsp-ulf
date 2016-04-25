/*
 
-Abstract

   Header for auxiliary / utility routines used by 
   the CSPICE DLM package; struct & proto definitions.

   Do not edit, touch, or in any way alter the code within this file.

-Particulars

   Structure definitions for our special argument checking code. The struct 
   possesses 6 members:

      access          - indicates the state of the argument, read, write,
                        or read-write
      name            - the name of the argument, i.e. the name of the variable
      type            - the type (kind) or argument, double, int, character 
                        string, etc.
      min_dims        - how many dimensions for the argument. A scalar has a 
                        value 0, a vector 1, a matrix 2.
      dims            - the array of sizes for each dimension. This variable 
                        defines 'min_dims' sizes for the argument.
      is_vectorizable - boolean flagging whether the argument is vectorizable

-Example

   Each interface has its own assignments (e.g. spkezr):

   struct argcheck argcheck[] = 
      {
      { OREAD, "target",   (void*)IDL_TYP_STRING,  0, { 0 }, 0},
      { OREAD, "epoch",    (void*)IDL_TYP_DOUBLE,  0, { 0 }, 0},
      { OREAD, "frame",    (void*)IDL_TYP_STRING,  0, { 0 }, 0},
      { OREAD, "abcorr",   (void*)IDL_TYP_STRING,  0, { 0 }, 0},
      { OREAD, "observer", (void*)IDL_TYP_STRING,  0, { 0 }, 0},
      { OWRIT, "state",    (void*)IDL_TYP_DOUBLE,  1, { 6 }, 0},
      { OWRIT, "lt",       (void*)IDL_TYP_DOUBLE,  0, { 0 }, 0},
      };

   where OREAD is an alias for IDL_EZ_ACCESS_R, OWRIT for IDL_EZ_ACCESS_W, 
   and RDWRT for IDL_EZ_ACCESS_RW

   The 'state' variable has min_dims=1, dims=6 to indicate a 6-vector.
   A 3x3 matrix has min_dims=2, dims={3,3}.

-Version

   Icy 1.0.1 16-JUL-2009 (EDW)

      Added a ticy specific set of defines to rename routines
      defined in zzicy.c. ticy failed due to a duplicate message 
      block error on an OS X machine after an OS upgrade to 10.5.
      This error occurred because both the ticyutil and Icy shared 
      libraries contained the zzicy.c symbol names.

      Renamed the less-than-dignified name "cspice_argbarf" to 
      "zzicy_argerr".

      Renamed the less-than-dignified name "cspice_argbarf_cleanup" to 
      "zzicy_argcleanup".

      Renamed the name "cspice_checkargs" to "zzicy_argcheck".

   Icy 1.0.0 19-DEC-2003 (EDW)

*/

#ifdef ICYTEST

#define  define_message_block        TUTILSdefine_message_block 
#define  icy_fail                    TUTILSicy_fail 
#define  zzicy_argerr                TUTILSzzicy_argerr 
#define  zzicy_argcheck              TUTILSzzicy_argcheck 
#define  zzicy_argcleanup            TUTILSzzicy_argcleanup 

#endif


#ifndef ZZICY_H
#define ZZICY_H

   struct argcheck
      {
      char              access;
      char            * name;
      void            * type;
      UCHAR             min_dims;
      IDL_ARRAY_DIM     dims;
      UCHAR             is_vectorizable;
      };

   /* 
   Structure to record the number of extra dimensions for "vectorized" 
   functions. The struct contains 4 members:

   ndims         - number of "vectorized" dimensions, i.e. the number of
                   data elements input to an argument nominally expecting
                   to receive a single input. Non-vectorized argument have 
                   ndims = 0 (scalar, vectors, matrices ).

   dims          - the vectorized dimensions

   nelts         - the product ndims*dims

   */

   struct               extra_dims 
                           {
                           UCHAR          ndims;
                           IDL_ARRAY_DIM  dims;
                           IDL_LONG       n_elts;
                           };


   /*

   zzicy.c function prototypes.

   */

   void                 define_message_block ( SpiceChar * block_name );

   void                 icy_fail        ( long cnt );
 
   void                 zzicy_argerr    ( int   argnum,
                                          char *argname,
                                          char *varname,
                                          char *fmt,
                                          ... );

   struct extra_dims  * zzicy_argcheck  ( int               Argc,
                                          IDL_VPTR         *Argv,
                                          struct argcheck  *argcheck,
                                          IDL_VPTR        **Argv_ret);

   void                 zzicy_argcleanup ( int                Argc,
                                           IDL_VPTR          *Argv_orig, 
                                           struct argcheck   *argcheck,
                                           IDL_VPTR          *Argv_tmp );

#endif

