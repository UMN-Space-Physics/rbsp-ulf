;;-Abstract
;;
;;   This "cookbook" program demonstrates the use of the CSPICE
;;   Toolkit by computing the apparent sub-observer point on a target
;;   body. It uses light time and stellar aberration corrections in
;;   order to do this.
;;
;;-Disclaimer
;;
;;   THIS SOFTWARE AND ANY RELATED MATERIALS WERE CREATED BY THE
;;   CALIFORNIA INSTITUTE OF TECHNOLOGY (CALTECH) UNDER A U.S.
;;   GOVERNMENT CONTRACT WITH THE NATIONAL AERONAUTICS AND SPACE
;;   ADMINISTRATION (NASA). THE SOFTWARE IS TECHNOLOGY AND SOFTWARE
;;   PUBLICLY AVAILABLE UNDER U.S. EXPORT LAWS AND IS PROVIDED "AS-IS"
;;   TO THE RECIPIENT WITHOUT WARRANTY OF ANY KIND, INCLUDING ANY
;;   WARRANTIES OF PERFORMANCE OR MERCHANTABILITY OR FITNESS FOR A
;;   PARTICULAR USE OR PURPOSE (AS SET FORTH IN UNITED STATES UCC
;;   SECTIONS 2312-2313) OR FOR ANY PURPOSE WHATSOEVER, FOR THE
;;   SOFTWARE AND RELATED MATERIALS, HOWEVER USED.
;;
;;   IN NO EVENT SHALL CALTECH, ITS JET PROPULSION LABORATORY, OR NASA
;;   BE LIABLE FOR ANY DAMAGES AND/OR COSTS, INCLUDING, BUT NOT
;;   LIMITED TO, INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND,
;;   INCLUDING ECONOMIC DAMAGE OR INJURY TO PROPERTY AND LOST PROFITS,
;;   REGARDLESS OF WHETHER CALTECH, JPL, OR NASA BE ADVISED, HAVE
;;   REASON TO KNOW, OR, IN FACT, SHALL KNOW OF THE POSSIBILITY.
;;
;;   RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF
;;   THE SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY
;;   CALTECH AND NASA FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE
;;   ACTIONS OF RECIPIENT IN THE USE OF THE SOFTWARE.
;;
;;-I/O
;;
;;   The user is prompted for the following:
;;
;;      - The name of a leapseconds kernel file.
;;      - The name of a Planetary constants (PCK) kernel file.
;;      - The name of a NAIF SPK Ephemeris file.
;;      - The name of the observing body.
;;      - The name of the target body.
;;      - The name of the body-fixed reference frame
;;        associated with the target body (for example, IAU_MARS).
;;      - Number of evaluations to perform
;;      - A UTC time interval of interest.
;;
;;   Output
;;
;;   The program calculates the planetocentric latitude and longitude
;;   of the nearest point on the target body to the observing body
;;   for a UTC epoch (see Input above). The program outputs
;;
;;      - The epoch of interest as supplied by the user.
;;      - The planetocentric longitude of the nearest point on
;;        the target body to the observing body.
;;      - The planetocentric latitude of the nearest point on
;;        the target body to the observing body.
;;
;;-Particulars
;;
;;   The SPK file must contain data for both the observing body and
;;   the target body during the specified time interval.
;;
;;   The "apparent sub-observer point" is defined in this program to
;;   be the point on the target body that appears to be closest to the
;;   observer. The apparent sub-observer point may also be defined as
;;   the intercept on the target's surface of the ray emanating from
;;   the observer and passing through the apparent target body's
;;   center, but we don't demonstrate use of that definition here. See
;;   the header of cspice_subpnt for details.
;;
;;   In order to compute the apparent location of the sub-observer
;;   point, we correct the position of the sub-observer point for both
;;   light time and stellar aberration, and we correct the orientation
;;   of the target body for light time. We consider "light time" to be
;;   the time it takes a photon to travel from the sub-observer point
;;   to the observer. If the light time is given the name LT, then the
;;   apparent position of the sub-observer point relative to the
;;   observer is defined by the vector from the sub-observer point's
;;   location (relative to the solar system barycenter) at ET-LT,
;;   minus the observer's location (again, relative to the solar
;;   system barycenter) at ET, where this difference vector is
;;   corrected for stellar aberration.
;;
;;   See the header of the Icy routine cspice_spkezr for more
;;   information on light time and stellar aberration corrections; see
;;   the header of the Icy routine cspice_subpnt for an explanation of
;;   how it applies aberration corrections.
;;
;;   Planetocentric coordinates are defined by a distance from a
;;   central reference point, an angle from a reference meridian,
;;   and an angle above the equator of a sphere centered at the
;;   central reference point. These are the radius, longitude,
;;   and latitude, respectively.
;;
;;   The program makes use of the following fundamental CSPICE
;;   interface routines:
;;
;;      cspice_furnsh --- makes kernel information available to
;;                        the user's program.
;;
;;      cspice_str2et --- converts strings representing time to counts
;;                        of seconds past the J2000 epoch.
;;
;;      cspice_et2utc --- converts an ephemeris time J200 to
;;                        a formatted UTC string.
;;
;;      cspice_subpnt --- calculate the position of the sub-observer point
;;                        of one body with respect to another
;;
;;   For the sake of brevity, this program does NO error checking
;;   on its inputs. Mistakes will cause the program to return control
;;   to the IDL interpreter.
;;
;;-Required Reading
;;
;;      KERNEL        The CSPICE Kernel Pool
;;      ROTATIONS     Rotations
;;      SPK           S- and P- Kernel (SPK) Specification
;;      TIME          Time routines in CSPICE
;;
;;   For questions about a particular subroutine, refer to its
;;   header.
;;
;;-Version
;;
;;   -Icy Version 2.0.0, 08-FEB-2008 (NJB)(EDW)
;; 
;;         References to deprecated routine cspice_subpt have been
;;         replaced with references to cspice_subpnt.
;; 
;;         The program now uses both stellar aberration and
;;         light time corrections. Previously only light
;;         time corrections were performed.
;; 
;;         The program now prompts for the name of the target
;;         body-fixed reference frame.
;; 
;;         The discussion in Particulars has been updated.
;; 
;;         Various header typos were corrected.
;;
;;   -Icy Version 1.0.0, 12-JUN-2003   (EDW)
;;
;;-Index_Entries
;;
;;   None.
;;
;;-&

PRO SUBPT

   ;;
   ;; Inizialize variables or set type. All variables used in a PROMPT
   ;; construct must be initialized as strings.
   ;;
   leap   = ''
   pck    = ''
   spk    = ''
   obs    = ''
   targ   = ''
   fixfrm = ''
   line   = ''
   utcbeg = ''
   utcend = ''
   answer = ''
   abcorr = 'LT'
   npts   = 0
   SPICETRUE = 1B
   SPICEFALSE= 0B

   ;;
   ;; An intro banner.
   ;;
   print
   print, '             Welcome to SUBPT'
   print
   print, 'This program demonstrates the use of CSPICE in computing'
   print, 'the apparent sub-observer point on a target body. The'
   print, 'computations use light time and stellar aberration '
   print, 'corrections.'
   print 


   ;;
   ;; Start out by prompting for the names of kernel files.
   ;; Load each kernel as the name is supplied.
   ;;
   ;; Get and load the leapsecond kernel.
   ;;
   read, leap, PROMPT = 'Enter the name of leapseconds kernel file: '
   
   cspice_furnsh, leap
   print


   ;;
   ;; Get and load the physical constants kernel.
   ;;
   read, pck, PROMPT = 'Enter the name of a planetary constants kernel: '

   cspice_furnsh, pck
   print


   ;;
   ;; Get and load the spk kernel.
   ;;
   read, spk, PROMPT = 'Enter the name of a binary SPK file: '
   
   cspice_furnsh, spk

   print
   print, 'Working ... Please wait.'

   ;;
   ;; Set-up for the user response loop
   ;;
   cont = SPICETRUE

   ;;
   ;; Loop till the user quits.
   ;;
   while cont do begin

      ;;
      ;; Get the names/IDs for the two target bodies and the observing
      ;; body.
      ;;
      print
      read, obs  , PROMPT = 'Enter the name of the observing body: '

      print
      read, targ, PROMPT = 'Enter the name for a target body: '

      print
      read, fixfrm, PROMPT = 'Enter the name of the target body-fixed frame: '

      print      
      read, line, PROMPT = 'Enter the number of points to calculate: '
      
      cspice_prsint, line, maxpts
      print

      if maxpts LT 1 then maxpts = 1;

      ;;
      ;; Input strings for the UTC time interval, or single UTC
      ;; time for a single evaluation.
      ;; 
      ;; Convert the UTC time interval to ET. ET stands for Ephemeris
      ;; Time and is in units of ephemeris seconds past Julian year
      ;; 2000. ET is the time system that is used internally in SPK
      ;; ephemeris files and reader subroutines.
      ;;
      ;; DELTA is the increment between consecutive times, if
      ;; needed.
      ;;
      if maxpts EQ 1 then begin 

         ;;
         ;; Request for a single evaluation. No steps - no delta.
         ;;
         read, utcbeg, PROMPT = 'Enter the UTC time: '
         print

         cspice_str2et, utcbeg, etbeg
         delta = 0.d

      endif else begin

         ;;
         ;; Request for a time interval with maxpts evaluations.
         ;;
         read, utcbeg, PROMPT = 'Enter the beginning UTC time: '
         print

         read, utcend, PROMPT = 'Enter the ending UTC time: '
         print

         cspice_str2et, utcbeg, etbeg
         cspice_str2et, utcend, etend

         delta  = ( etend - etbeg ) / ( double(maxpts) - 1.d )

       endelse

      ;;
      ;; Write the headings for the table of values.
      ;;

      print, 'Planetocentric coordinates for the nearest point'
      print, 'on the target body to the observing body (deg).'
 
      print, FORMAT = '("Target body: ",A,"          Observing body: ",A)',$ 
                                                                   targ, obs
      print
      print, '       UTC Time            Lat         Lon'
      print, '----------------------------------------------'
 
      ;;
      ;; Now, everything is set up for output
      ;;
      epoch  = etbeg
      npts   = 1

      ;;
      ;; Evaluate for maxpts, quit when the user inputs an N.
      ;;
      while npts LE maxpts do begin

         ;;
         ;; Note: cspice_subpnt can also calculate a "sub-observer point" via
         ;; the intercept of the observer-target vector with the target
         ;; body's surface. The computation "method" argument value for
         ;; that calculation is
         ;; 
         ;;    "Intercept: ellipsoid"
         ;; 
         ;; The output sub-observer point `spoint' is expressed in the
         ;; body-fixed reference frame `fixfrm' specified by the user,
         ;; where the orientation of the frame is evaluated at the time
         ;; `trgepc'. `trgepc' is expressed in seconds past J2000 TDB, and
         ;; is equal to et-lt, where `lt' is the light time from the
         ;; sub-observer point to the observer. The output `srfvec' is
         ;; the apparent position of the sub-observer point relative to
         ;; the observer. `srfvec' is also expressed in the reference
         ;; frame `fixfrm'.
         ;; 
         ;; Please see the cspice_subpnt header for further
         ;; information.
         ;;
         cspice_subpnt, 'Near point: ellipsoid', targ, epoch,  fixfrm, $
                        abcorr, obs,  spoint, trgepc, srfvec 
         
         cspice_reclat, spoint, radius, lon, lat

 
         ;; 
         ;; Multiply lat and lon by the number of degrees per radian.
         ;;
         lon = lon * cspice_dpr()
         lat = lat * cspice_dpr()

 
         ;;
         ;; Convert the current EPOCH to UTC time for display.
         ;;
         cspice_et2utc, epoch, 'C', 3, utcout


         ;;
         ;; Display results in a table format:
         ;;
         print, FORMAT = '("  ",A20,"  ",D10.5,"    ",D10.5)', utcout, lat, lon

         epoch = epoch + delta
         npts  = npts + 1

      endwhile


      ;;
      ;; Continue?
      ;;
      print
      read, answer, PROMPT = 'Continue? (Enter Y or N): '

      ;;
      ;; Did the user input an 'n'? If not continue.
      ;;
      if ( cspice_eqstr( answer, 'N' ) ) then cont = SPICEFALSE


   endwhile

   ;;
   ;; Finished. Unload the kernel files and empty the kenrel pool.
   ;;
   cspice_kclear

END