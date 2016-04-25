/*

-Abstract

   The cell manipulation prototypes for use in Icy.

-Particulars

    pack_cell and unpack_cell invert the other's function, copying
    data between an Icy cell to a CSPICE cell.
 
    icy_cell creates Icy cells within the interface for use in IDL.

Version-

   Icy 1.1.0 17-NOV-2004 (EDW)

*/


void      pack_cell   ( SpiceCell * window, 
                        int         x, 
                        SpiceInt  * tag_offset, 
                        IDL_VPTR  * Argv );


void      unpack_cell ( int         x, 
                        SpiceInt  * tag_offset, 
                        SpiceCell * cell, 
                        IDL_VPTR  * Argv );


IDL_VPTR  icy_cell    ( SpiceCellDataType type, 
                        SpiceInt          size, 
                        SpiceInt          length);
