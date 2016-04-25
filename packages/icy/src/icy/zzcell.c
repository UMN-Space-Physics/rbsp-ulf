/*
-Procedure zzcell (Icy cell routines)

-Abstract

    Routines to create, pack and unpack Icy implementations of
    CSPICE cells.
    
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

   CELLS.REQ 
   ICY.REQ

-Keywords

   None

-Brief_I/O

   None.

-Detailed_Input

   None.

-Detailed_Output

   None.

-Parameters
   
   Define the 'tag_offset' indexes for each cell field.

*/

#define   DTYPE     0
#define   LENGTH    1
#define   SIZE      2
#define   CARD      3
#define   ISSET     4
#define   ADJUST    5
#define   INIT      6
#define   BASE      7
#define   DATA      8


/*
 
-Exceptions

   None.

-Files

   None.

-Particulars

   The 'tag_offset' array is the first cell structure field and so has
   zero offset from the start of the structure's data array. This offset 
   array lists the integer offsets for all other structure fields. The offset
   indexes listed above correspond to the index of 'tag_offset' for the 
   named fields.

-Examples

   Example 1: return a cell from Icy to IDL. Argv index 6 contains
   the cell structure.

   /. 
   Pack the IDL cell structure to a CSPICE cell. 
   ./
   tag_offset = (SpiceInt*) (Argv[6]->value.s.arr->data);
   pack_cell ( 6, tag_offset, Argv, &cover );

   ckcov_c( ck, idcode, needav, level, tol, timsys, &cover );

   /.
   Test for a SPICE error signal, if found, display an error message to the
   user then return to the IDL application.
   ./
   CHECK_CALL_FAILURE( SCALAR );

   /.
   Unpack the data from 'cover' to 'Argv'.
   ./
   unpack_cell ( 6, tag_offset, &cover, Argv );

   Use this procedure regardless of whether the cell serves as input,
   output, or both.

-Restrictions

   Use only with the Icy interface.

-Literature_References

   None.

-Author_and_Institution

   E. D. Wright  (JPL)

-Version

   Icy 1.2.3 14-NOV-2013, EDW (JPL)

      File spell check.
      
   Icy 1.2.2 08-JUL-2009 (EDW)

      Renamed the less-than-dignified name "cspice_argbarf" to 
      "zzicy_argerr".

   Icy 1.2.1 07-FEB-2008 (EDW)

      Implemented properly structured headers for all routines.

      Unnecessary declaration removed as the 'size_SpiceChar' evaluates
      to 1 on currently supported platforms,

         static int     size_SpiceChar = (int) sizeof(SpiceChar);

   Icy 1.2.0 07-FEB-2005 (EDW)

      Added capability to process SPICE_CHR cells.

   Icy 1.1.0 01-AUG-2004 (EDW)

-Index_Entries

   None.

-&
*/

#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <ctype.h>
#include "export.h"
#include "SpiceUsr.h"
#include "SpiceZfc.h"
#include "SpiceZst.h"
#include "SpiceZmc.h"
#include "SpiceCel.h"
#include "icy.h"
#include "zzicy.h"
#include "zzalloc.h"

/*
-Procedure pack_cell (Pack an Icy cell)

-Abstract
 
    This routine packs a CSPICE cell structure with the data from an
    IDL/Icy cell structure.
 
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
 
   CELLS.REQ 
   ICY.REQ
 
-Keywords

   None.

-Brief_I/O

   VARIABLE  I/O  DESCRIPTION 
   --------  ---  -------------------------------------------------- 
   cell       I   Temporary CSPICE cell
   x          I   Index of the 'Argv' array containing the cell
                  structure. 
   tag_offset I   List of offsets to each structure field. 
   Argv       I   Array of input arguments passed from the IDL interpreter. 

-Detailed_Input

   cell           a temporary CSPICE cell to which pack_cell copies 
                  the data in an input IDL cell. This 'cell' then passes
                  to a CSPICE routine.

   x              integer index of the element in Argv pointing to the
                  IDL structure used as a cell.

   tag_offset     the integer list of offsets for each data field from
                  the start of the structure.

   Argv            the argument list passed from IDL; element 'x' holds a
                   pointer to the IDL structure containing the data 
                   and fields to copy to the CSPICE cell.

-Detailed_Output
 
   The function returns a CSPICE Cell containing the same data as 
   the input Icy Cell.

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

   None.

-Index_Entries

   None.

-&
 */
void pack_cell ( SpiceCell * cell, int x, SpiceInt * tag_offset, 
                 IDL_VPTR * Argv )
   {

   SpiceDouble          * base_dp;
   SpiceDouble          * data_dp;
   SpiceInt             * base_int;
   SpiceInt             * data_int;
   IDL_STRING           * stuct_chr;
   SpiceInt               data_shift;
   SpiceInt               byte_shift;
   SpiceInt               base_shift;
   void                 * base_chr;

   int                    i;
   
   chkin_c( "pack_cell" );

   /* 
   Unpack the IDL cell structure to the CSPICE cell. 
   */

   cell->dtype  = *(SpiceCellDataType*)
                    (Argv[x]->value.s.arr->data + *(tag_offset+DTYPE ));
   
   cell->length = *(SpiceInt*)
                    (Argv[x]->value.s.arr->data + *(tag_offset+LENGTH));
   
   cell->size   = *(SpiceInt*)
                    (Argv[x]->value.s.arr->data + *(tag_offset+SIZE  ));
   
   cell->card   = *(SpiceInt*)
                    (Argv[x]->value.s.arr->data + *(tag_offset+CARD  ));

   /*
   Boolean values. 
   */
   cell->isSet  = (SpiceBoolean)      
                  *(Argv[x]->value.s.arr->data + *(tag_offset+ISSET ));
   
   cell->adjust = (SpiceBoolean)
                  *(Argv[x]->value.s.arr->data + *(tag_offset+ADJUST));
   
   cell->init   = (SpiceBoolean)
                  *(Argv[x]->value.s.arr->data + *(tag_offset+INIT  ));

   /* 
   The array data. 'base' points to the allocated array, 'data_shift' 
   is the offset from the first element of the 'base' array
   to the cell dp data.
   */
   data_shift    =*(SpiceInt*)
                   (Argv[x]->value.s.arr->data + *(tag_offset+DATA  ));
   

   /*
   Extract the 'base' and 'data' pointers. Cast the pointers to 
   the appropriate type as defined by 'cell->type'.
   */
   switch ( cell->dtype )
      {
      
      /*
      The cell contains what type of data? 
      */

      case SPICE_DP:

         /* Double Precision */
         
         /* 
         Retrieve the pointer to the dp array and the data offset value. 
         */
         base_dp     = (SpiceDouble*)
                       (Argv[x]->value.s.arr->data + *(tag_offset+BASE  ));

         /*
         Calculate the pointer address for the cell data.
         */
         data_dp     = base_dp + data_shift;
         
         cell->base = (void*) base_dp;
         cell->data = (void*) data_dp;
         break;
         
      case SPICE_INT:

         /* Integer */
         
         /* 
         Retrieve the pointer to the dp array and the data offset value. 
         */
         base_int   = (SpiceInt*)
                      (Argv[x]->value.s.arr->data + *(tag_offset+BASE  ));
         
         /*
         Calculate the pointer address for the cell data.
         */
         data_int   = base_int + data_shift;

         cell->base = (void*) base_int;
         cell->data = (void*) data_int;
         break;

      case SPICE_CHR:

         /*
         Cast the point to an IDL_STRING pointer. Consider 'stuct_chr'
         a pointer to an array of IDL_STRINGs.
         */
         stuct_chr  = (IDL_STRING*)
                      (Argv[x]->value.s.arr->data + tag_offset[BASE]  );
         
         /*
         Allocate the needed memory for the call 'base':

            no_memory_blocks = ( data_shift + size )*length

            total_memory     = no_memory_blocks * sizeof(SpiceChar)
          
         where data_shift equals the size of the cell control block.
         */
         byte_shift = data_shift                 *cell->length;
         base_shift = (data_shift + cell->size)*(cell->length);
         base_chr   = alloc_SpiceMemory( base_shift );

         if ( base_chr == NULL ) 
            {
            
            /*
            The pointer to the memory returned as NULL. Signal an error then
            return to the interpreter.
            */
            setmsg_c( "Malloc failed to allocate memory for #1 bytes.");
            errint_c( "#1", (SpiceInt) base_shift);
            sigerr_c( "SPICE(MALLOCFAILED)"     );
            chkout_c( "pack_cell" );
            icy_fail(SCALAR);
            }

         /*
         Store the pointer to 'base'.
         */
         cell->base = base_chr;
         
         /*
         The data region starts 'byte_shift from the beginning of the 
         allocated memory.
         */
         cell->data = (SpiceChar*)base_chr + byte_shift;

         for (i=0; i < cell->size; i++)
            {
            
            /*
            The offset to data IN THE 'stuct_chr' ARRAY is data_shift.
            Copy the strings from the IDL cell to the CSPICE cell. 
            */
            strcpy( (char*)cell->data + i*cell->length, 
                    IDL_STRING_STR( &(stuct_chr[i+data_shift]) ) );
            
            /* 
            The cell has a declared value, but direct assignment of string 
            from the IDL interpreter may exceed the declared length. Null
            terminate at end of 'length'.
            */
            strcpy( (char*)cell->data 
                    + ( (i+1)*cell->length - 1), 
                    "\0");
            }


         break;

      default:
         zzicy_argerr( 0, "type", NULL, 
                         "Unacceptable cell type passed to pack_cell.");
         break;
      }


   /*
   In the case of a CHAR cell, 'cell' contains pointers to a memory
   space allocated in this routine. Deallocate the memory in unpack_cell
   or explicitly in the Icy interface call.
   */

   /*
   Initialize the cell if necessary. 
   */
   CELLINIT( cell );
   
   chkout_c( "pack_cell" );
   
   }




/*
-Procedure unpack_call ( Unpack an Icy cell)

-Abstract
 
   This routine unpacks a CSPICE cell structure data, copying the data
   to an IDL/Icy cell structure.
 
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
 
   CELLS.REQ 
   ICY.REQ
 
-Keywords

   None.

-Brief_I/O
 
   VARIABLE  I/O  DESCRIPTION 
   --------  ---  -------------------------------------------------- 
   x          I   Index of the 'Argv' array containing the cell
                  structure. 
   tag_offset I   List of offsets to each structure field.
   cell       I   CSPICE cell to copy to an Icy cell.
   Argv       O   Array of input arguments passed from the IDL interpreter. 
 
-Detailed_Input
 
   x              integer index of the element in Argv pointing to the
                  IDL structure used as a cell.
 
   tag_offset     the integer list of offsets for each data field from
                  the start of the structure.
 
   cell         the CSPICE cell to copy to an Icy cell.
 
-Detailed_Output
 
   Argv            the argument list passed from IDL; element 'x' holds a
                   pointer to the IDL structure containing the same data 
                   and fields as  the input CSPICE Cell.

-Parameters
 
   None.
 
-Exceptions
 
   None.
 
-Files
 
   None.
 
-Particulars
 
   This routine functions in tandem with pack_cell to copy data between
   CSPICE cells and corresponding Icy cells. An unpack_cell call occurs
   after a CSPICE call to return a cell variable to the IDL interpreter.

   An Icy cell is an IDL structure laid out in a format similar to a 
   CSPICE cell.

-Examples

   None.

-Restrictions

   None.

-Literature_References

   None.

-Author_and_Institution

   None.

-Version

   None.

-Index_Entries

   None.

-&
*/
void unpack_cell ( int x           , SpiceInt  * tag_offset, 
                   SpiceCell * cell, IDL_VPTR  * Argv      )
   {

   SpiceInt               data_shift;
   IDL_STRING           * stuct_chr;
   void                 * data_chr;
   int                    i;

   chkin_c( "unpack_cell" );

   data_shift =*(SpiceInt*)(Argv[x]->value.s.arr->data + tag_offset[DATA]);

   /* 
   Unpack a CSPICE cell structure - pack the IDL cell structure using 
   same strategy used at initialization. No need to process the BASE field 
   (pointer), DATA (does not change) or DTYPE (does not change).
   */

   *(SpiceInt*) (Argv[x]->value.s.arr->data + tag_offset[LENGTH]) = 
                                                           cell->length;

   *(SpiceInt*) (Argv[x]->value.s.arr->data + tag_offset[SIZE]  ) =
                                                           cell->size;

   *(SpiceInt*) (Argv[x]->value.s.arr->data + tag_offset[CARD]  ) = 
                                                           cell->card;

   /*
   Booleans, directly set the value pointed at by the struct pointer,
   'adjust', 'isSet', 'init'.
   */
   *(UCHAR*) (Argv[x]->value.s.arr->data + tag_offset[ADJUST]) =
                                                       (UCHAR) cell->adjust;

   *(UCHAR*) (Argv[x]->value.s.arr->data + tag_offset[ISSET]) =
                                                        (UCHAR) cell->isSet;

   *(UCHAR*) (Argv[x]->value.s.arr->data + tag_offset[INIT])  = 
                                                         (UCHAR) cell->init;

   /*
   Copy the character data back to the IDL structure, then release the memory.
   Undo the SPICE_CHR operations in pack_cell.
   */
   if ( cell->dtype == SPICE_CHR )
      {

      stuct_chr = (IDL_STRING*)(Argv[x]->value.s.arr->data 
                  + tag_offset[BASE]  );
      data_chr  = cell->data;

      /*
      Copy the data portion of the data block - offset by
      'data_shift'. This operation does not copy control area. 
      */
      for (i=0; i < cell->size; i++)
         {
         
         /*
         Delete the existing string and allocated memory before copying the
         new string. Failure to do this causes a large memory leak.
         */
         IDL_StrDelete( &(stuct_chr[i+data_shift]), (IDL_MEMINT) 1 ); 
         IDL_StrStore(  &(stuct_chr[i+data_shift]), 
                        (char*)(data_chr) + i*cell->length ); 
         }

      /* 
      Free the memory allocated to the character cell. 
      */
      free_SpiceMemory(cell->base );
      }
      
   chkout_c( "unpack_cell" );

   }



/*
-Procedure icy_cell (Create an Icy cell)

-Abstract

   Dynamically create a Icy cell corresponding to a CSPICE cell.
 
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
 
   CELLS.REQ 
   ICY.REQ
 
-Keywords

   None.

-Brief_I/O
 
   VARIABLE  I/O  DESCRIPTION 
   --------  ---  -------------------------------------------------- 
   type       I   ID of the type of cell data
   size       I   Number of elements in the cell data array
   length     I   For character data cells, the maximum string length

-Detailed_Input

   type       the SpiceCellDataType ID defining the data type for the
              cell data: double precision, integer, or character.

   size       the number of elements to allocate for cell data.

   length     when 'type' defines a character cell, 'length' defines
              the maximum length of the data strings.

-Detailed_Output

   The function returns an IDL structure corresponding to a CSPICE
   cell.
 
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

   None.

-Index_Entries

   None.

-&
*/
IDL_VPTR icy_cell( SpiceCellDataType type, SpiceInt size, SpiceInt length)
   {

   static IDL_STRUCT_TAG_DEF * struct_tags;

   void               * cell;
   IDL_VPTR             return_val = NULL;
   IDL_MEMINT           offset;

   /* Initially, set the base array as a 1-vector. */
   static IDL_MEMINT    dims  [] = { 1, 1};
   
   /* Set the dimension of the offset field to 9. */
   static IDL_MEMINT    dims_9[] = { 1, 9};
   
   /* The structure field names. */
   static SpiceChar   * tags[] = { "OFFSET", 
                                   "DTYPE" , 
                                   "LENGTH", 
                                   "SIZE"  , 
                                   "CARD"  , 
                                   "ISSET" , 
                                   "ADJUST", 
                                   "INIT"  , 
                                   "BASE"  , 
                                   "DATA" };

   SpiceInt           * dsize;
   SpiceInt           * dlength;
   SpiceInt           * data;
   SpiceInt           * dtype;
   SpiceInt           * tag_offset;

   int                  i;
   
   /*
   Create enough memory for the data array and the SPICE_CELL_CTRLSZ
   control region.
   */
   dims[1] = (IDL_MEMINT) size + (IDL_MEMINT) SPICE_CELL_CTRLSZ;

   /* 
   Allocate memory from IDL for the array of structure tags. Perform
   a LONGJUMP if error.
   */
   struct_tags = IDL_MemAlloc( (TAG_SIZE(tags) + 1)*sizeof(*struct_tags),
                               NULL,
                               IDL_MSG_LONGJMP );
   
   /* 
   Create the structure definition. You _MUST_ null out
   the flags field to destroy any random data. Failure to
   do this can cause memory corruption and intense aggravation.
   */
   for (i=0; i<TAG_SIZE(tags); i++ )
      {
      struct_tags[i].name  = tags[i];
      struct_tags[i].dims  = NULL;
      struct_tags[i].type  = (void*) IDL_TYP_LONG;
      struct_tags[i].flags = 0;
      }
   
   /* 
   Overwrite the default definition for the data array.
   
   This changes the "type" fields for indices:

      0  -> OFFSET
      5  -> ISSET
      6  -> ADJUST
      7  -> INIT
   */
   struct_tags[0].dims = dims_9;
   struct_tags[0].type = (void*) IDL_TYP_MEMINT;
   struct_tags[5].type = (void*) IDL_TYP_BYTE;
   struct_tags[6].type = (void*) IDL_TYP_BYTE;
   struct_tags[7].type = (void*) IDL_TYP_BYTE;
   
   /*
   Set the type of structure dependent on the value of input
   'type'. DP, INT or CHAR.
   
   This changes the "type" fields for index:

      8  -> BASE
   */
   struct_tags[8].dims = dims;

   switch ( type )
      {
      case SPICE_DP:
         struct_tags[8].type = (void*) IDL_TYP_DOUBLE;
         break;
         
      case SPICE_INT:
         struct_tags[8].type = (void*) IDL_TYP_LONG;
         break;

      case SPICE_CHR:
         struct_tags[8].type = (void*) IDL_TYP_STRING;
         break;

      default:
         IDL_MemFree( struct_tags, NULL, IDL_MSG_LONGJMP );
         zzicy_argerr( 0, "type", NULL, 
                            "Unknown cell type passed to icy_cell.");
         break;
      }
   
   /* Null terminate the structure. */
   struct_tags[TAG_SIZE(tags)].name = NULL;
   
   /* 
   Create the new ANONYMOUS structure. We __MUST__ use an anonymous
   structure since CSPICE cells have variable size; a named structure
   maintains the size declared when first created.
    */
   cell = IDL_MakeStruct( 0, struct_tags );
   
   /* Free the memory needed by the structure tags. */
   IDL_MemFree( struct_tags, NULL, IDL_MSG_LONGJMP );

   /*
   Create the return value 'return_value' for the 'cell' structure
   of dimension '1'; zero out all fields (IDL_TRUE).
   */
   IDL_MakeTempStructVector( cell, (IDL_MEMINT) 1, &return_val, IDL_TRUE );
   
   /* 
   Fill the data fields, retrieve the offsets to the fields.
   Store the offsets in the 'offset' field.
   */

   /* Offset list */
   offset     = IDL_StructTagInfoByIndex( cell, 0, IDL_MSG_LONGJMP, NULL);
   tag_offset = (SpiceInt*)(return_val->value.s.arr->data + offset);

   /*
   Fill the tag_offset array with values.
   */
   for( i=0; i<9; i++ )
      {
      
      /*
      On success, the function returns the data offset of the tag.
      */
      tag_offset[i] = IDL_StructTagInfoByIndex( cell,
                                                i+1,
                                                IDL_MSG_LONGJMP,
                                                NULL);        
      }

   /* 
   Field index 1, the cell data type as passed from the calling routine. 
   */
   dtype  = (SpiceInt*) (return_val->value.s.arr->data + tag_offset[0]);
   *dtype = (SpiceInt) type;
   
   /* 
   Field index 2, length, initially zero.
   */
   dlength  = (SpiceInt*) (return_val->value.s.arr->data + tag_offset[1]);
   *dlength = (SpiceInt) length;

   /* 
   Field index 3, size of the data array. 
   */
   dsize  = (SpiceInt*) (return_val->value.s.arr->data + tag_offset[2]);
   *dsize = (SpiceInt) size;

   /* 
   The field index 4, cardinality, initially has value zero.
   */
   
   /* 
   Set the boolean values. Booleans return as IDL type BYTE;
   identical to UCHAR.
   */
   
   /* 
   First isSet, field 5... 
   */
   *(UCHAR*) (return_val->value.s.arr->data + tag_offset[4]) = 
                                                          (UCHAR) SPICETRUE;
   
   /* 
   ...now adjust, field index 6... 
   */
   *(UCHAR*) (return_val->value.s.arr->data + tag_offset[5]) = 
                                                          (UCHAR) SPICEFALSE;
   
   /* 
   ...and init, field index 7. 
   */
   *(UCHAR*) (return_val->value.s.arr->data + tag_offset[6]) = 
                                                          (UCHAR) SPICEFALSE;
   
   /* 
   Field index 8, the array of values. 
   */
   
   /* 
   Field index 9, the length of the control segment for cell data.
   Set the value.
   */
   data  = (SpiceInt*) (return_val->value.s.arr->data + tag_offset[8]);
   *data = SPICE_CELL_CTRLSZ;   
   
   return return_val;
   }

