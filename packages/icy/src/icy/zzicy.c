/*

-Procedure zzicy (Auxiliary Icy routines )

-Abstract

   Support routines for the Icy interface.
   
   Do not edit, touch, or in any way alter the code within this file.

-Disclaimer

   THIS SOFTWARE AND ANY RELATED MATERIALS WERE CREATED BY THE
   CALIFORNIA INSTITUTE OF TECHNOLOGY (CALTECH) UNDER A U.S.
   GOVERNMENT CONTRACT WITH THE NATIONAL AERONAUTICS AND SPACE
   ADMINISTRATION (NASA). THE SOFTWARE IS TECHNOLOGY AND SOFTWARE
   PUBLICLY AVAILABLE UNDER U.S. EXPORT LAWS AND IS PROVIDED "AS-IS"
   TO THE RECIPIENT WITHOUT WARRANTY OF ANY KIND, INCLUDING ANY
   WARRANTIES OF PERFORMANCE OR MERCHANTABILITY OR FITNESS FOR A
   PARTICULAR USE OR PURPOSE (AS SET FORTH IN UNITED STATES UCC
   SECTIONS 2312-2313) OR FOR ANY PURPOSE WHATSOEVER, FOR THE
   SOFTWARE AND RELATED MATERIALS, HOWEVER USED.

   IN NO EVENT SHALL CALTECH, ITS JET PROPULSION LABORATORY, OR NASA
   BE LIABLE FOR ANY DAMAGES AND/OR COSTS, INCLUDING, BUT NOT
   LIMITED TO, INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND,
   INCLUDING ECONOMIC DAMAGE OR INJURY TO PROPERTY AND LOST PROFITS,
   REGARDLESS OF WHETHER CALTECH, JPL, OR NASA BE ADVISED, HAVE
   REASON TO KNOW, OR, IN FACT, SHALL KNOW OF THE POSSIBILITY.

   RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF
   THE SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY
   CALTECH AND NASA FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE
   ACTIONS OF RECIPIENT IN THE USE OF THE SOFTWARE.

-Required_Reading

   None

-Keywords

   None

-Brief_I/O

   None

-Detailed_Input

   None

-Detailed_Output

   None

-Parameters

   None

-Exceptions

   None

-Files

   None

-Particulars

   Icy passes error messages to the IDL application via the IDL native
   routines IDL_Message and IDL_MessageFromBlock.

-Examples

   None

-Restrictions

   None

-Literature_References

   None

-Author_and_Institution
   
   E. D. Wright    (JPL)

-Version

   Icy 2.0.1 14-NOV-2013, EDW (JPL)

      File spell check.

   Icy 2.0.0 25-MAY-2010, EDW (JPL)

      Added a ticy specific set of defines to rename routines
      defined in "zzicy.c." ticy failed on an OS X machine after 
      an OS upgrade to 10.5 due to a duplicate message block
      error. This error occurred because both the ticyutil and
      Icy shared libraries contained the "zzicy.c" symbol names.

      The instructions:

      IDL> et[0] = 0d
      IDL> spoint = dblarr[3,200]
      IDL> CSPICE_ILLUM, name_target_gt, et[0], 'LT', name_observer_gt, $
                         spoint, phase, solar, emissn

      caused a bus error from IDL due to a boundary case failure in 
      the argument check routine 'cspice_checkargs'. This error
      occurred due to a similar logic error as noted in the Icy 1.1.4
      comment.

      Renamed the less-than-dignified name 'cspice_argbarf' to 
      'zzicy_argerr'.

      Renamed the less-than-dignified name 'cspice_argbarf_cleanup' to 
      'zzicy_argcleanup'.

      Renamed the name 'cspice_checkargs' to 'zzicy_argcheck'.

      Extensive rewrite of the argument checking logic in 'zzicy_argcheck'.
      The new logic separates checks on type, vectorization, and 
      dimension.

   Icy 1.1.5 24-NOV-2008, EDW (JPL)

      Eliminated use of temp variables in 'icy_fail' call.

   Icy 1.1.4 14-JUN-2008, EDW (JPL)

      Added additional error check to confirm proper vectorization
      measures for vectorizable scalar arguments.

      The instruction:

         CSPICE_PGRREC, 'earth', [2d], 3d, 0d, 1d, 0d, v

      caused an Icy crash due to failure of the argument check code
      to properly process the mix of vectorized and unvectorized 
      input arguments.

   Icy 1.1.3 07-FEB-2008, EDW (JPL)

      Implemented properly structured headers for all routines.

   Icy 1.1.2 11-MAY-2005, EDW (JPL)

      Renamed "spice_dlm_barf" call with a more dignified name, "icy_fail."

      Removed use of 'reuse_if_possible'. This ensures all variables not
      set by the CSPICE routine corresponding to an interface return
      initialized to zero.

      Added call to 'zzerror', replacing parallel code in 'icy_fail'.

   Icy 1.1.0 01-AUG-2004, EDW (JPL)

      Added logic to 'icy_fail' allowing error messages during
      vectorized operations to report the IDL vector 
      index value at error.
   
   Icy 1.0.0 01-FEB-2004, EDW (JPL)

-Index_Entries

   None

-&
*/

#ifdef ICYTEST

#define  define_message_block      TUTILSdefine_message_block 
#define  icy_fail                  TUTILSicy_fail 
#define  zzicy_argerr              TUTILSzzicy_argerr 
#define  zzicy_argcheck            TUTILSzzicy_argcheck 
#define  zzicy_argcleanup          TUTILSzzicy_argcleanup 

#endif


/* 
   Includes: standard, IDL, and cspice. 
*/
#include <ctype.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#include "export.h"
#include "SpiceUsr.h"
#include "SpiceZfc.h"
#include "icy.h"
#include "zzicy.h"
#include "zzerror.h"

#define INDEX_BASE                   0

/*
Define the IDL error response codes and a corresponding message block.
*/
static IDL_MSG_BLOCK * spice_msg_block;

#define ICY_M_SPICE_ERROR            0
#define ICY_M_BAD_IDL_ARGS          -1

static IDL_MSG_DEF    msg_arr[] = 
   {
   { "ICY_M_SPICE_ERROR" , "%N%s" },
   { "ICY_M_BAD_IDL_ARGS", "%N%s" }
   };


/*

-Procedure define_message_block (Define an IDL message block)

-Abstract

   Define the SPICE_MBLK message block with msg_arr.

-Disclaimer

   THIS SOFTWARE AND ANY RELATED MATERIALS WERE CREATED BY THE
   CALIFORNIA INSTITUTE OF TECHNOLOGY (CALTECH) UNDER A U.S.
   GOVERNMENT CONTRACT WITH THE NATIONAL AERONAUTICS AND SPACE
   ADMINISTRATION (NASA). THE SOFTWARE IS TECHNOLOGY AND SOFTWARE
   PUBLICLY AVAILABLE UNDER U.S. EXPORT LAWS AND IS PROVIDED "AS-IS"
   TO THE RECIPIENT WITHOUT WARRANTY OF ANY KIND, INCLUDING ANY
   WARRANTIES OF PERFORMANCE OR MERCHANTABILITY OR FITNESS FOR A
   PARTICULAR USE OR PURPOSE (AS SET FORTH IN UNITED STATES UCC
   SECTIONS 2312-2313) OR FOR ANY PURPOSE WHATSOEVER, FOR THE
   SOFTWARE AND RELATED MATERIALS, HOWEVER USED.

   IN NO EVENT SHALL CALTECH, ITS JET PROPULSION LABORATORY, OR NASA
   BE LIABLE FOR ANY DAMAGES AND/OR COSTS, INCLUDING, BUT NOT
   LIMITED TO, INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND,
   INCLUDING ECONOMIC DAMAGE OR INJURY TO PROPERTY AND LOST PROFITS,
   REGARDLESS OF WHETHER CALTECH, JPL, OR NASA BE ADVISED, HAVE
   REASON TO KNOW, OR, IN FACT, SHALL KNOW OF THE POSSIBILITY.

   RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF
   THE SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY
   CALTECH AND NASA FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE
   ACTIONS OF RECIPIENT IN THE USE OF THE SOFTWARE.

-Required_Reading

   None

-Keywords

   None

-Brief_I/O

   None

-Detailed_Input

   None

-Detailed_Output

   None

-Parameters

   None

-Exceptions

   None

-Files

   None

-Particulars

   None

-Examples

   None

-Restrictions

   None

-Literature_References

   None

-Author_and_Institution

   None

-Version

   Icy 1.0.0 01-FEB-2004, EDW (JPL)

-Index_Entries

   None

-&
*/
void define_message_block( SpiceChar * block_name )
   {

   /*
   This defines the message block used in icy_fail().
   */

   spice_msg_block = IDL_MessageDefineBlock( block_name,
                                             IDL_CARRAY_ELTS(msg_arr),
                                             msg_arr);

   }


/*

-Procedure icy_fail ( Report SPICE errors to IDL)

-Abstract

   Respond to SPICE errors by building the traceback string, passing that string
   and the error message to IDL, then reset the SPICE error system. 
   the zzerror() call performs all error subsystem calls.

-Disclaimer

   THIS SOFTWARE AND ANY RELATED MATERIALS WERE CREATED BY THE
   CALIFORNIA INSTITUTE OF TECHNOLOGY (CALTECH) UNDER A U.S.
   GOVERNMENT CONTRACT WITH THE NATIONAL AERONAUTICS AND SPACE
   ADMINISTRATION (NASA). THE SOFTWARE IS TECHNOLOGY AND SOFTWARE
   PUBLICLY AVAILABLE UNDER U.S. EXPORT LAWS AND IS PROVIDED "AS-IS"
   TO THE RECIPIENT WITHOUT WARRANTY OF ANY KIND, INCLUDING ANY
   WARRANTIES OF PERFORMANCE OR MERCHANTABILITY OR FITNESS FOR A
   PARTICULAR USE OR PURPOSE (AS SET FORTH IN UNITED STATES UCC
   SECTIONS 2312-2313) OR FOR ANY PURPOSE WHATSOEVER, FOR THE
   SOFTWARE AND RELATED MATERIALS, HOWEVER USED.

   IN NO EVENT SHALL CALTECH, ITS JET PROPULSION LABORATORY, OR NASA
   BE LIABLE FOR ANY DAMAGES AND/OR COSTS, INCLUDING, BUT NOT
   LIMITED TO, INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND,
   INCLUDING ECONOMIC DAMAGE OR INJURY TO PROPERTY AND LOST PROFITS,
   REGARDLESS OF WHETHER CALTECH, JPL, OR NASA BE ADVISED, HAVE
   REASON TO KNOW, OR, IN FACT, SHALL KNOW OF THE POSSIBILITY.

   RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF
   THE SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY
   CALTECH AND NASA FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE
   ACTIONS OF RECIPIENT IN THE USE OF THE SOFTWARE.

-Required_Reading

   None

-Keywords

   None

-Brief_I/O

   None

-Detailed_Input

   None

-Detailed_Output

   None

-Parameters

   None

-Exceptions

   None

-Files

   None

-Particulars

   None

-Examples

   None

-Restrictions

   None

-Literature_References

   None

-Author_and_Institution

   None

-Version

   Icy 1.0.0 01-FEB-2004, EDW (JPL)

-Index_Entries

   None

-&
*/
void icy_fail( long cnt )
   {

   /*
   Send the error message to the interpreter.
   */
   IDL_MessageFromBlock(spice_msg_block, 
                        ICY_M_SPICE_ERROR, 
                        IDL_MSG_LONGJMP, 
                        zzerror( cnt ) ); 
   }



/*

-Procedure zzicy_argerr (Emit an error message if invalid input arguments )

-Abstract

   Return an error signal and a usage string if the user passes an improper
   argument list.
   
-Disclaimer

   THIS SOFTWARE AND ANY RELATED MATERIALS WERE CREATED BY THE
   CALIFORNIA INSTITUTE OF TECHNOLOGY (CALTECH) UNDER A U.S.
   GOVERNMENT CONTRACT WITH THE NATIONAL AERONAUTICS AND SPACE
   ADMINISTRATION (NASA). THE SOFTWARE IS TECHNOLOGY AND SOFTWARE
   PUBLICLY AVAILABLE UNDER U.S. EXPORT LAWS AND IS PROVIDED "AS-IS"
   TO THE RECIPIENT WITHOUT WARRANTY OF ANY KIND, INCLUDING ANY
   WARRANTIES OF PERFORMANCE OR MERCHANTABILITY OR FITNESS FOR A
   PARTICULAR USE OR PURPOSE (AS SET FORTH IN UNITED STATES UCC
   SECTIONS 2312-2313) OR FOR ANY PURPOSE WHATSOEVER, FOR THE
   SOFTWARE AND RELATED MATERIALS, HOWEVER USED.

   IN NO EVENT SHALL CALTECH, ITS JET PROPULSION LABORATORY, OR NASA
   BE LIABLE FOR ANY DAMAGES AND/OR COSTS, INCLUDING, BUT NOT
   LIMITED TO, INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND,
   INCLUDING ECONOMIC DAMAGE OR INJURY TO PROPERTY AND LOST PROFITS,
   REGARDLESS OF WHETHER CALTECH, JPL, OR NASA BE ADVISED, HAVE
   REASON TO KNOW, OR, IN FACT, SHALL KNOW OF THE POSSIBILITY.

   RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF
   THE SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY
   CALTECH AND NASA FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE
   ACTIONS OF RECIPIENT IN THE USE OF THE SOFTWARE.

-Required_Reading

   None

-Keywords

   None

-Brief_I/O

   None

-Detailed_Input

   None

-Detailed_Output

   None

-Parameters

   None

-Exceptions

   None

-Files

   None

-Particulars

   None

-Examples

   None

-Restrictions

   None

-Literature_References

   None

-Author_and_Institution

   None

-Version

   Icy 1.0.1 08-JUL-2009, EDW (JPL)

      Altered form of output string to include the argument name
      as defined in the argcheck structure, the variable name (or
      description) passed from IDL, and the ICY(BADARG) tag.

   Icy 1.0.0 01-FEB-2004, EDW (JPL)

-Index_Entries

   None

-&
*/

void zzicy_argerr( int argnum, char *argname, char *varname, char *fmt, ... )
   {
   va_list   args;
   
   char      fmt_buf[1024];
   char      err_buf[1024];

   /* 
   "fmt" is probably a simple string... but it _could_ have "%<etc>" fmt. 
   */
   va_start(args, fmt);
   vsprintf(fmt_buf, fmt, args);

   sprintf(err_buf, "ICY(BADARG): Argument %d (`%s` = %s) ", 
                                argnum+1, argname, varname);

   strcat(err_buf, fmt_buf);

   /*
   Pass the error message to IDL.
   */
   IDL_MessageFromBlock( spice_msg_block,
                         ICY_M_BAD_IDL_ARGS,
                         IDL_MSG_LONGJMP,
                         err_buf );
   }


/*

-Procedure zzicy_newvar (Return a variable of type with allocated memory)

-Abstract

   None.

-Disclaimer

   THIS SOFTWARE AND ANY RELATED MATERIALS WERE CREATED BY THE
   CALIFORNIA INSTITUTE OF TECHNOLOGY (CALTECH) UNDER A U.S.
   GOVERNMENT CONTRACT WITH THE NATIONAL AERONAUTICS AND SPACE
   ADMINISTRATION (NASA). THE SOFTWARE IS TECHNOLOGY AND SOFTWARE
   PUBLICLY AVAILABLE UNDER U.S. EXPORT LAWS AND IS PROVIDED "AS-IS"
   TO THE RECIPIENT WITHOUT WARRANTY OF ANY KIND, INCLUDING ANY
   WARRANTIES OF PERFORMANCE OR MERCHANTABILITY OR FITNESS FOR A
   PARTICULAR USE OR PURPOSE (AS SET FORTH IN UNITED STATES UCC
   SECTIONS 2312-2313) OR FOR ANY PURPOSE WHATSOEVER, FOR THE
   SOFTWARE AND RELATED MATERIALS, HOWEVER USED.

   IN NO EVENT SHALL CALTECH, ITS JET PROPULSION LABORATORY, OR NASA
   BE LIABLE FOR ANY DAMAGES AND/OR COSTS, INCLUDING, BUT NOT
   LIMITED TO, INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND,
   INCLUDING ECONOMIC DAMAGE OR INJURY TO PROPERTY AND LOST PROFITS,
   REGARDLESS OF WHETHER CALTECH, JPL, OR NASA BE ADVISED, HAVE
   REASON TO KNOW, OR, IN FACT, SHALL KNOW OF THE POSSIBILITY.

   RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF
   THE SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY
   CALTECH AND NASA FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE
   ACTIONS OF RECIPIENT IN THE USE OF THE SOFTWARE.

-Required_Reading

   None.

-Keywords

   None.

-Brief_I/O

   None.

-Detailed_Input

   None.

-Detailed_Output

   None.

-Parameters

   None.

-Exceptions

   None.

-Files

   None.

-Particulars

   None.

-Examples

   None.

-Restrictions

   None.

-Literature_References

   None.

-Author_and_Institution

   None.

-Version

   Icy 1.0.0 01-FEB-2004, EDW (JPL)

-Index_Entries

   None.

-&
*/

static IDL_VPTR zzicy_newvar( struct argcheck *argcheck )
   {
   
   /* Type the return variable. */
   IDL_VPTR    zzicy_newvar;
   
   /* Set the variable 'dimension'. */
   int         n_dim  = argcheck->min_dims;
   
   /* 
   Needed if we create an array (vector or matrix). The dimensionality
   of the array must not exceed IDL_MAX_ARRAY_DIM. 
   */
   IDL_MEMINT  dims[IDL_MAX_ARRAY_DIM];

   /* Determine the kind of variable to create. */

   /*
   One of the define structures.
   */
   if ( (long)argcheck->type > IDL_MAX_TYPE) 
      {

      if (n_dim == 0) 
         {
         
         /* 
         The usual case: "0" means "scalar"
         */
         n_dim   = 1;
         dims[0] = 1;
         } 
      else 
         {
         int i;

         for (i=0; i < n_dim; i++)
            {
            dims[i] = argcheck->dims[i];
            }
         }
       
      /* 
      Allocate memory for a new structure. 
      */
      (void)IDL_MakeTempStruct(argcheck->type, n_dim, dims, &zzicy_newvar, 0);
      
      /* Return the new struct to the caller. */
      return zzicy_newvar;
      }

   /*
   Simple scalar or array 
   */
   if ( (long)argcheck->type & IDL_TYP_B_SIMPLE) 
      {

      /*
      Do we need a scalar? 
      */
      if (n_dim == 0) 
         {

         /*
         Yes. Create a scalar of the required type. 
         */
         zzicy_newvar       = IDL_Gettmp();
         zzicy_newvar->type = (long)argcheck->type;

         /* 
         Initialize the new variable to null string, or zero, as appropriate 
         */
         if (zzicy_newvar->type == IDL_TYP_STRING)
            {
            IDL_StrStore(&zzicy_newvar->value.str, "");
            }
         else
            {

            /* 
            DP zero clears all other types 
            */
            zzicy_newvar->value.d = 0.0;
            }

         /* 
         Return the new variable to the caller. 
         */
         return zzicy_newvar;

         } 
      else 
         {

         /* We need to create an array. */
         int i;

         for (i=0; i < n_dim; i++)
            {

            /* 
            Check for an array dimension of zero. A zero value dimension 
            indicates the caller will dynamically allocate memory for 
            the return argument. 
            */
            if ((dims[i]=argcheck->dims[i]) == 0)
               {

               /* Caller creates VPTR so return a NULL. */
               return NULL;
               }

            }

         /* 
         Create the IDL array; return the pointer to the caller.
         IDL_BARR_INI_ZERO causes the array to zero out.
         */
         (void)IDL_MakeTempArray( (long)argcheck->type, 
                                  n_dim, 
                                  dims, 
                                  IDL_BARR_INI_ZERO, 
                                  &zzicy_newvar);

         /* 
         Return the new array to the caller. 
         */
         return zzicy_newvar;
         }
         
      }

   /* 
   This code should never execute, but we require the return to satisfy
   the requirements of the compiler.
   */
   IDL_Message( IDL_M_NAMED_GENERIC, 
                IDL_MSG_LONGJMP, 
                "ICY(BUG): [zzicy] Failsafe internal error. This code "
                "should not execute. Please contact NAIF.");
   return 0;
   }




/*

-Procedure zzicy_argcheck ( Check arguments for type and size)

-Abstract

   Confirm the correctness of arguments passed to an interface
   function. This is sort of our IDL_EzCall replacement.

-Disclaimer

   THIS SOFTWARE AND ANY RELATED MATERIALS WERE CREATED BY THE
   CALIFORNIA INSTITUTE OF TECHNOLOGY (CALTECH) UNDER A U.S.
   GOVERNMENT CONTRACT WITH THE NATIONAL AERONAUTICS AND SPACE
   ADMINISTRATION (NASA). THE SOFTWARE IS TECHNOLOGY AND SOFTWARE
   PUBLICLY AVAILABLE UNDER U.S. EXPORT LAWS AND IS PROVIDED "AS-IS"
   TO THE RECIPIENT WITHOUT WARRANTY OF ANY KIND, INCLUDING ANY
   WARRANTIES OF PERFORMANCE OR MERCHANTABILITY OR FITNESS FOR A
   PARTICULAR USE OR PURPOSE (AS SET FORTH IN UNITED STATES UCC
   SECTIONS 2312-2313) OR FOR ANY PURPOSE WHATSOEVER, FOR THE
   SOFTWARE AND RELATED MATERIALS, HOWEVER USED.

   IN NO EVENT SHALL CALTECH, ITS JET PROPULSION LABORATORY, OR NASA
   BE LIABLE FOR ANY DAMAGES AND/OR COSTS, INCLUDING, BUT NOT
   LIMITED TO, INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND,
   INCLUDING ECONOMIC DAMAGE OR INJURY TO PROPERTY AND LOST PROFITS,
   REGARDLESS OF WHETHER CALTECH, JPL, OR NASA BE ADVISED, HAVE
   REASON TO KNOW, OR, IN FACT, SHALL KNOW OF THE POSSIBILITY.

   RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF
   THE SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY
   CALTECH AND NASA FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE
   ACTIONS OF RECIPIENT IN THE USE OF THE SOFTWARE.

-Required_Reading

   None.

-Keywords

   None.

-Brief_I/O

   None.

-Detailed_Input

   None.

-Detailed_Output

   None.

-Parameters

   None.

-Exceptions

   None.

-Files

   None.

-Particulars

   None.

-Examples

   None.

-Restrictions

   None.

-Literature_References

   None.

-Author_and_Institution

   None.

-Version

   Icy 2.0.0 24-SEP-2009, EDW (JPL)

      Corrected error in handling of input arrays of logicals.
      The conversion to an array of SpiceBoolean did not function.

      The instructions:

      IDL> et[0] = 0d
      IDL> spoint = dblarr[3,200]
      IDL> CSPICE_ILLUM, name_target_gt, et[0], 'LT', name_observer_gt, $
                         spoint, phase, solar, emissn
      
      caused a bus error from IDL due to a boundary case failure in 
      the argument check routine 'cspice_checkargs'.

      Renamed the less-than-dignified name 'cspice_argbarf' to 
      'zzicy_argerr'.

      Renamed the name 'cspice_checkargs' to 'zzicy_argcheck'.

      Extensive rewrite of the argument checking logic in zzicy_argcheck.
      The new logic separates checks on type, vectorization, and 
      dimension.
      
   Icy 1.1.0 12-JUL-2008, EDW (JPL)

      Added additional error check to confirm proper vectorization
      measures for vectorizable scalar arguments.
      
      The instruction:
      
         CSPICE_PGRREC, 'earth', [2d], 3d, 0d, 1d, 0d, v
      
      caused an Icy crash due to failure of the argument check code
      to properly process the mix of vectorized and unvectorized 
      input arguments.

      Defined 'retval' size as ICY_MAXPARAMS, replacing the hardcoded
      value 16. Added an appropriate error check for Argc > ICY_MAXPARAMS.
      ICY_MAXPARAMS value (30, as of this version) set in "icy.h" 

   Icy 1.0.0 01-FEB-2004, EDW (JPL)

-Index_Entries

   None.

-&
*/
struct extra_dims * zzicy_argcheck( int               Argc,
                                    IDL_VPTR         *Argv,
                                    struct argcheck  *argcheck,
                                    IDL_VPTR        **Argv_ret)
   {

   static IDL_VPTR    retval[ICY_MAXPARAMS];

   SpiceInt           i;
   SpiceInt           min_dims;
   SpiceInt           n_dim;
   SpiceInt           vectorized_measure = 0;
   SpiceInt           measure;
   SpiceInt           first_i  = -1;

   SpiceBoolean       first_vectorizable = SPICETRUE;
   SpiceBoolean       is_vectorized      = SPICEFALSE;
   SpiceBoolean       is_array;
   SpiceBoolean       is_struct;
   SpiceBoolean       vectorized_arg     = SPICEFALSE;
   SpiceBoolean       has_zerodim        = SPICEFALSE;
   SpiceBoolean       is_valid           = SPICEFALSE;

   
   /* 
   For vectorizable functions 
   */
   static struct extra_dims extra;

   /* The message buffer to write an error message */
   char msg[1024];

   /* 
   Initialize 
   */
   extra.ndims = 0;
   *Argv_ret   = &retval[0];

   /*
   Ensure we don't loop beyond the size of 'retval'.
   */
   if ( Argc > ICY_MAXPARAMS )
      {
      IDL_MessageFromBlock( spice_msg_block   ,
                            ICY_M_BAD_IDL_ARGS,
                            IDL_MSG_LONGJMP   ,
         "ICY(BUG): [zzicy]  Failsafe internal error. Argc greater than "
         "ICY_MAXPARAMS. This error should not occur. Please contact NAIF." );
       }                     


   /* 
   Loop over the number of arguments. 
   */
   for (i=0; i < Argc; i++) 
      {
      
      /*
      Retrieve the IDL variable name for argument "i."
      */
      char *varname = IDL_VarName(Argv[i]);

      retval[i]     = Argv[i];


      /*
      Check INPUT arguments. Define an input as non exclusive write.
      This passes for read and readwrite args.
      */
      if (argcheck[i].access != IDL_EZ_ACCESS_W)
         {

         /* 
         First, make sure the argument is defined. 
         */
         IDL_EXCLUDE_UNDEF( Argv[i] );

         /*
         Determine if the argument is an array. Any vectorized argument
         is an array.
         */
         is_array = (Argv[i]->flags & IDL_V_ARR);

         /*
         Determine if the argument is a structure. A structure
         is an array in all cases.
         */
         is_struct = (Argv[i]->type == IDL_TYP_STRUCT );


   /* Begin argument tests. */


         /* 
         ---Begin block, argument check, type
         */
         if ( (long)argcheck[i].type > IDL_MAX_TYPE) 
            { 
   
            /* 
            The argument must be a struct. The argcheck[i].type
            value will exceed IDL_MAX_TYPE for Icy structures.
            */
            if ( !is_struct ) 
               {
               zzicy_argerr(i, argcheck[i].name, varname, 
                               "must be a STRUCT {TYPE}" );
               }


            if (argcheck[i].is_vectorizable)
               {
               IDL_Message( IDL_M_NAMED_GENERIC, IDL_MSG_LONGJMP,
                            "ICY(BUG): [zzicy] Failsafe internal error. "
                            "A STRUCT argument defined as vectorizable. "
                            "Please contact NAIF.");
               }

            /* 
            Icy does not use vectors of structs. Confirm the structure
            argument consists of a single structure, not a vector of
            structures.
            */
            if (Argv[i]->value.s.arr->n_elts != 1)
               {
               zzicy_argerr(i, argcheck[i].name, varname, 
                                "can only have one element {TYPE}");
               }

            }
         else if ((long)argcheck[i].type == IDL_TYP_STRING) 
            {

            /* 
            Argument type must be a STRING type. 
            */
            if (Argv[i]->type != IDL_TYP_STRING)
               {
               zzicy_argerr(i, argcheck[i].name, varname, 
                               "must be a STRING {TYPE}");
               }

            }
         else if ((long)argcheck[i].type == IDL_TYP_LONG) 
            {

            /* 
            Argument type expected as a LONG. Accept BYTE and INT.
            */ 
            if ( (Argv[i]->type != IDL_TYP_LONG ) &&
                 (Argv[i]->type != IDL_TYP_INT  ) &&
                 (Argv[i]->type != IDL_TYP_BYTE  )    )
               {
               zzicy_argerr(i, argcheck[i].name, varname, 
                               "must be a LONG {TYPE}");
               }

            }
         else if ((long)argcheck[i].type == IDL_TYP_DOUBLE) 
            {

            /* 
            Argument type expected as a DOUBLE. Accept FLOAT, LONG and INT.
            */ 
            if ( (Argv[i]->type != IDL_TYP_LONG   ) &&
                 (Argv[i]->type != IDL_TYP_INT    ) &&
                 (Argv[i]->type != IDL_TYP_FLOAT  ) &&
                 (Argv[i]->type != IDL_TYP_DOUBLE  )    )
               {
               zzicy_argerr(i, argcheck[i].name, varname, 
                            "must be a DOUBLE or losslessly "
                            "convertible to a DOUBLE {TYPE}");
               }
               
            }
         else if ((long)argcheck[i].type == IDL_TYP_BYTE) 
            {

            /* 
            Argument type expected as a BYTE (logical). Accept LONG and INT.
            */
            if ( (Argv[i]->type != IDL_TYP_BYTE   ) &&
                 (Argv[i]->type != IDL_TYP_LONG   ) &&
                 (Argv[i]->type != IDL_TYP_INT    ) )
               {
               zzicy_argerr(i, argcheck[i].name, varname, 
                            "must represent a logical, INT, LONG, "
                            "or BYTE {TYPE}");
               }

            }
         else 
            {

            IDL_Message( IDL_M_NAMED_GENERIC, IDL_MSG_LONGJMP,
                            "ICY(BUG): [zzicy] Failsafe internal error. "
                            "Type check description error. "
                            "Please contact NAIF.");
            }
         /*
         ---End block, argument check, type
         */


   /* Passed type check, now begin vectorization tests. */


         /*
         ---Begin block, argument check, vectorization
         */

         if( argcheck[i].is_vectorizable )
            {

            /*
            Key off the first vectorizable argument. If the argument
            is vectorized, then all subsequent vectorizable arguments must
            have the same measure of vectorization as the first; error if
            otherwise. If the first vectorizable argument is not vectorized,
            error if any of the subsequent vectorizable arguments are 
            vectorized.
            */
            if( first_vectorizable )
               {

               first_vectorizable = SPICEFALSE;
               first_i            = i;
               is_vectorized      = SPICEFALSE;
               vectorized_measure = 0;
                  
               if ( is_array )
                  {
                  min_dims = argcheck[i].min_dims;
                  n_dim    = Argv[i]->value.arr->n_dim;

                  /*
                  A vectorized argument has the property:
                  
                     n_dim = min_dims +1

                  */
                  vectorized_arg = (min_dims +1 == n_dim );
                  is_vectorized  = vectorized_arg;
                  
                  if ( is_vectorized )
                     {
                     vectorized_measure = Argv[i]->value.arr->dim[ n_dim - 1 ];
                     }

                  }

               }
             else
               {
               
               /*
               Condition, a vectorizable argument not the first vectorizable
               argument.
 
               Vectorization measure for argument index "i" unknown. Assume 
               zero until determined otherwise.
               */
               measure = 0;

               if ( is_array )
                  {

                  min_dims = argcheck[i].min_dims;
                  n_dim    = Argv[i]->value.arr->n_dim;

                  /*
                  A vectorized argument has the property:

                     n_dim = min_dims +1
                  */
                  vectorized_arg = (min_dims +1 == n_dim );                  

                  if ( vectorized_arg )
                     {
                     measure = Argv[i]->value.arr->dim[ n_dim - 1 ];
                     }

                  }

               /*
               Test the vectorization measure of the "i" argument against
               the required measure determine from the first vectorizable
               argument.
               */
               if( measure != vectorized_measure )
                  {
                  sprintf( msg, "must have the same measure of "
                                "vectorization as `%s'. Required "
                                "measure %ld, argument has measure %ld. {VEC}",
                                 argcheck[first_i].name,
                                 (long)vectorized_measure,
                                 (long)measure);

                  zzicy_argerr(i, argcheck[i].name, varname, msg);
                  }

               }

            }
         /*
         ---End block, argument check, vectorization
         */


   /* Passed vectorization state check, now begin dimension tests. */

                                    
         /*
         ---Begin block, argument check, dimensions
         */
         if ( is_array && !is_struct )
            {
            
            /*
            Confirm validity of array arguments that are not structures.
            */

            min_dims = argcheck[i].min_dims;
            n_dim    = Argv[i]->value.arr->n_dim;

            switch( n_dim - min_dims )
               {
               case 0:
               
                  /*
                  Continue.
                  */
               
                  break;
                  
               case 1:

                  if ( !argcheck[i].is_vectorizable )
                     {
                     sprintf( msg, 
                              "incorrect array dimensions. Argument should "
                              "have %ld dimension(s), found to have %ld. "
                              "{DIM}", 
                              (long)min_dims, 
                              (long)n_dim );
                     zzicy_argerr(i, argcheck[i].name, varname, msg);
                     }

                  break;
                  
               default:
               
                  sprintf( msg, "incorrect array dimensions. Argument should "
                                " have %ld dimension(s), found to have %ld. "
                                "{DIM}", 
                                (long)min_dims, 
                                (long)n_dim );
                  zzicy_argerr(i, argcheck[i].name, varname, msg);

                  break;
               }

            }


         /*
         Argument shape checks, begin.
         */
         switch( argcheck[i].min_dims )
            {
            
            case 0: 
            
               /*
               Check if the argument is an array and not a structure.
               The argument cannot be a vector unless marked as vectorizable.
               */
               if ( is_array && !is_struct  )
                  {

                  if ( !argcheck[i].is_vectorizable ) 
                     {

                     /* 
                     An argument defined as a non-vectorizable scalar, but found
                     to be an array. Signal an error.
                     */
                     zzicy_argerr(i, argcheck[i].name, varname, 
                                    "must be a scalar {DIM}");

                     }
                  else 
                     {
                     extra.ndims = 1;
                     extra.dims[0] = vectorized_measure;
                     }


                  }

               break;

            case 1:

               switch( argcheck[i].dims[0] )
                  {

                  case 0:
                  
                     /*
                     The case where the argument is expected as an N array,
                     with N an arbitrary value. Do not allow a scalar. Any other
                     error checks will occur in the interface code.
                     */

                    if ( !is_array )
                        {

                        /* 
                        An argument defined as a non-vectorizable N-array, but 
                        found to be a scalar. Signal an error.
                        */
                        zzicy_argerr(i, argcheck[i].name, varname, 
                                      "must be an N-array. The argument "
                                      "cannot be a scalar. {DIM}");
                        }

                     break;

                  default:

                    if ( !is_array )
                        {

                        /* 
                        An argument defined as a non-vectorizable N-array, but 
                        found to be a scalar. Signal an error.
                        */
                       sprintf( msg, "must be an %ld-array. The argument "
                                     "cannot be a scalar. {DIM}", 
                                     (long)argcheck[i].dims[0]);
                                    
                        zzicy_argerr(i, argcheck[i].name, varname, msg);
                        }

                     /*
                     The argument must either have dimension [N] or [N,S] with 
                     N defined in the interface argcheck structure and S the 
                     measure of vectorization.
                     */
                     is_valid = (Argv[i]->value.arr->dim[0] 
                                 == 
                                 argcheck[i].dims[0]);

                     if (  !is_vectorized ) 
                        {

                        if ( !is_valid )
                           {
                           sprintf( msg, 
                                    "incorrect array size. The array argument "
                                    "should have  dimension [%ld], found to "
                                    "have dimension [%ld]. {DIM}",

                                     (long)argcheck[i].dims[0],
                                     (long)Argv[i]->value.arr->dim[0]);

                           zzicy_argerr(i, argcheck[i].name, varname, msg);

                           }

                        }
                     else
                        {

                        if ( !is_valid )
                           {
                           sprintf( msg, 
                                    "incorrect array size. The array argument "
                                    "should have dimension [%ld,%ld], found to "
                                    "have dimension [%ld,%ld]. {DIM}", 
                                          
                                    (long)argcheck[i].dims[0], 
                                    (long)vectorized_measure,
                                          
                                    (long)Argv[i]->value.arr->dim[0],
                                    (long)vectorized_measure );
   
                           zzicy_argerr(i, argcheck[i].name, varname, msg);

                           }

                        extra.ndims = 1;
                        extra.dims[0] = vectorized_measure;
                        }
                  
                     break;   
                  }
            
               break;

            case 2:

               /*
               Determine if the stated dimension has value zero, defined in the 
               argcheck structure.
               */
               has_zerodim = ( argcheck[i].dims[0]==0 ) 
                              || 
                             ( argcheck[i].dims[1] == 0);
               
               if( has_zerodim )
                  {

                  /* Error check, argument cannot have a scalar form. */
                  if ( !is_array )
                     {
                     zzicy_argerr(i, argcheck[i].name, varname, 
                                     "must be an [N,M]-array. The argument "
                                     "cannot be a scalar. {DIM}");
                      }
                      
                  if ( argcheck[i].dims[0]==0 )
                     {
                     is_valid = (Argv[i]->value.arr->dim[1] 
                                 == 
                                 argcheck[i].dims[1]);

                     if ( !is_valid )
                        {
                        sprintf( msg, 
                                 "incorrect array size. The array argument "
                                 "should have dimension [N,%ld], found to "
                                 "have dimension [N,%ld]. {DIM}", 
                                          
                                  (long)argcheck[i].dims[1], 
                                  
                                  (long)Argv[i]->value.arr->dim[1]
                               );
                         zzicy_argerr(i, argcheck[i].name, varname, msg);
                        }

                     }
                  
                  if ( argcheck[i].dims[1]==0 )
                     {
                     is_valid = (Argv[i]->value.arr->dim[0] 
                                 == 
                                 argcheck[i].dims[0]);

                     if ( !is_valid )
                        {
                        sprintf( msg, 
                                 "incorrect array size. The array argument "
                                 "should have dimension [%ld,N], found to "
                                 "have dimension [%ld,N]. {DIM}", 
                                          
                                  (long)argcheck[i].dims[0], 
                                  
                                  (long)Argv[i]->value.arr->dim[0]
                                );
                        zzicy_argerr(i, argcheck[i].name, varname, msg);
                        }

                     }


                  }
               else
                  {

                  /* Error check, argument cannot have a scalar form. */
                  if ( !is_array )
                     {
                     sprintf( msg, "must be an [%ld,%ld]-array. The argument "
                                   "cannot be a scalar. {DIM}",
                                     (long)argcheck[i].dims[0], 
                                     (long)argcheck[i].dims[1]
                            );
                      zzicy_argerr(i, argcheck[i].name, varname, msg );
                      }

                  /*
                  The argument must either has dimension [M,N] or [M,N,S] with 
                  M,N defined in the interface argcheck structure and S the 
                  measure of vectorization.
                  */
                  is_valid =  (Argv[i]->value.arr->dim[0] 
                              == 
                              argcheck[i].dims[0]) 
                           &&
                              (Argv[i]->value.arr->dim[1] 
                              == 
                              argcheck[i].dims[1]);


                     if ( !is_vectorized ) 
                        {

                        /*
                        Condition: min_dims =2, non-vectorized argument.
                        */

                        if ( !is_valid )
                           {
                           sprintf( msg, 
                                    "incorrect array size. The array argument "
                                    "should have dimension [%ld,%ld], found to "
                                    "have dimension [%ld,%ld]. {DIM}", 
                                          
                                     (long)argcheck[i].dims[0], 
                                     (long)argcheck[i].dims[1], 
                                          
                                     (long)Argv[i]->value.arr->dim[0],
                                     (long)Argv[i]->value.arr->dim[1]
                                  );
   
                           zzicy_argerr(i, argcheck[i].name, varname, msg);

                           }

                        }
                     else
                        {
                       
                        /*
                        Condition: min_dims =2, vectorized argument.
                        */

                        if ( !is_valid )
                           {
                           sprintf( msg,
                                    "incorrect array size. The array argument "
                                    "should have dimension [%ld,%ld,%ld], "
                                    "found to have dimension [%ld,%ld,%ld]. "
                                    "{DIM}",

                                     (long)argcheck[i].dims[0], 
                                     (long)argcheck[i].dims[1],
                                     (long)vectorized_measure,

                                     (long)Argv[i]->value.arr->dim[0],
                                     (long)Argv[i]->value.arr->dim[1],
                                     (long)vectorized_measure
                                  );
   
                           zzicy_argerr(i, argcheck[i].name, varname, msg);
                           }

                        extra.ndims = 1;
                        extra.dims[0] = vectorized_measure;

                        }
                     }

               break;

            default:
   
               /* 
               This should never happen. 'min_dims' not a member of {0, 1, 2}.
               An error exists in the argcheck structure description. Feel free
               to slap the developer.
               */
               IDL_Message( IDL_M_NAMED_GENERIC, IDL_MSG_LONGJMP,
                            "ICY(BUG): [zzicy] Failsafe internal error. "
                            "Parameter min_dims not an element of {0, 1, 2}. "
                            "Please contact NAIF.");

               break;
            }
         /*
         Argument shape checks, end.
         */

            
         /*
         ---End block, argument check, dimensions
         */


         /* 
         Convert argument type if required, but only for non-struct arguments. 
         */
         if ( (Argv[i]->type != (long)argcheck[i].type) && !is_struct)
            {
            retval[i] = IDL_BasicTypeConversion( 1,
                                                 &Argv[i],
                                                 (long)argcheck[i].type );
            }

         }


      /* 
      Check RETURN arguments. Define a return argument as an
      exclusive write. Use of read/write args requires declaration
      of size - like a read.

      Note that output arguments are either all vectorized or all not 
      vectorized.
      */
      if (argcheck[i].access == IDL_EZ_ACCESS_W) 
         {

         if (Argv[i]->flags & (IDL_V_CONST|IDL_V_TEMP))
            {
            zzicy_argerr(i, argcheck[i].name, varname, 
                         "must be a named variable");
            }

         /*
         If a vectorized argument list, adjust the dimensionality and size of 
         the output argument (declared in the 'argcheck' struct) to have one 
         extra dimension of size 'vectorized_measure'.
         */
         if( is_vectorized)
            {
            argcheck[i].dims[ argcheck[i].min_dims] =  vectorized_measure;
            argcheck[i].min_dims                   += 1;
            }

         /*
         Create an output argument of the correct size, shape, and type.
         */
         retval[i] = zzicy_newvar(&argcheck[i]);
         }

      }


   /* 
   Set the "n_elts" field to describe vectorization. 
   */
   
   extra.n_elts = 1;
   
   if( is_vectorized)
      {
      extra.n_elts = vectorized_measure;
      }
      
   return &extra;
   }



/*

-Procedure zzicy_argcleanup ( Eliminate unneeded variables )

-Abstract

   Delete those temporary variables and associated memory allocated for 
   arguments.

-Disclaimer

   THIS SOFTWARE AND ANY RELATED MATERIALS WERE CREATED BY THE
   CALIFORNIA INSTITUTE OF TECHNOLOGY (CALTECH) UNDER A U.S.
   GOVERNMENT CONTRACT WITH THE NATIONAL AERONAUTICS AND SPACE
   ADMINISTRATION (NASA). THE SOFTWARE IS TECHNOLOGY AND SOFTWARE
   PUBLICLY AVAILABLE UNDER U.S. EXPORT LAWS AND IS PROVIDED "AS-IS"
   TO THE RECIPIENT WITHOUT WARRANTY OF ANY KIND, INCLUDING ANY
   WARRANTIES OF PERFORMANCE OR MERCHANTABILITY OR FITNESS FOR A
   PARTICULAR USE OR PURPOSE (AS SET FORTH IN UNITED STATES UCC
   SECTIONS 2312-2313) OR FOR ANY PURPOSE WHATSOEVER, FOR THE
   SOFTWARE AND RELATED MATERIALS, HOWEVER USED.

   IN NO EVENT SHALL CALTECH, ITS JET PROPULSION LABORATORY, OR NASA
   BE LIABLE FOR ANY DAMAGES AND/OR COSTS, INCLUDING, BUT NOT
   LIMITED TO, INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND,
   INCLUDING ECONOMIC DAMAGE OR INJURY TO PROPERTY AND LOST PROFITS,
   REGARDLESS OF WHETHER CALTECH, JPL, OR NASA BE ADVISED, HAVE
   REASON TO KNOW, OR, IN FACT, SHALL KNOW OF THE POSSIBILITY.

   RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF
   THE SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY
   CALTECH AND NASA FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE
   ACTIONS OF RECIPIENT IN THE USE OF THE SOFTWARE.

-Required_Reading

   None.

-Keywords

   None.

-Brief_I/O

   None.

-Detailed_Input

   None.

-Detailed_Output

   None.

-Parameters

   None.

-Exceptions

   None.

-Files

   None.

-Particulars

   None.

-Examples

   None.

-Restrictions

   None.

-Literature_References

   None.

-Author_and_Institution

   None.

-Version

   Icy 1.0.0 01-FEB-2004, EDW (JPL)

-Index_Entries

   None.

-&
*/
void zzicy_argcleanup( int                 Argc,
                       IDL_VPTR          * Argv_orig, 
                       struct argcheck   * argcheck,
                       IDL_VPTR          * Argv_tmp )
   {
   int i;

   /* 
   Loop over the number of arguments in Argc.
   */
   for (i=0; i < Argc; i++) 
      {

      /* 
      Clean up converted input arguments; delete the allocated
      resources. 
      
      Define an input as an exclusive read. This exempts
      write and read/write arguments.

      Does the original argument pointer equal the temporary (work)
      pointer?

      */
      if ( (argcheck[i].access == IDL_EZ_ACCESS_R) &&
           (Argv_tmp[i]        != Argv_orig[i]   )   )
         {

         /* 
         If the original Argv pointer does not match the temporary
         pointer value, delete the temp variable. This deletes unneeded
         memory, but preserves original arguments.
         */
         IDL_Deltmp(Argv_tmp[i]);

         }
      else if ( argcheck[i].access != IDL_EZ_ACCESS_R) 
         {

         /* 
         Copy output arguments to the real Argv for return to IDL. Define
         an output as a not exclusive read. This allows a return of 
         both write and read/write args.

         No need to copy a NULL.
         */
         if (Argv_tmp[i] != NULL)
            {
            IDL_VarCopy(Argv_tmp[i], Argv_orig[i]);
            }

         }

      }

   }

