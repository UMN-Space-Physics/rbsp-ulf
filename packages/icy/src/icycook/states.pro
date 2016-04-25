;;-Abstract
;;
;;   This "cookbook" program demonstrates the use of NAIF S- and P-
;;   Kernel (SPK) files and subroutines to calculate the state
;;   (position and velocity) of one solar system body relative to
;;   another solar system body.
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
;;   The program prompts the user for the following input:
;;
;;      - The name of a NAIF leapseconds kernel file.
;;      - The name of a NAIF binary SPK ephemeris file.
;;      - The name for the observing body.
;;      - The name for the target body.
;;      - Number of states to calculate.
;;      - A time interval of interest.
;;
;;   Output
;;
;;      - The light time and stellar aberration corrected state of
;;        the target body relative to the observing body plus
;;        the magnitude to the position and velocity vectors.
;;
;;-Particulars
;;
;;   The user supplies a NAIF leapseconds kernel file, a NAIF binary
;;   SPK ephemeris file, valid names for both the target and
;;   observing bodies, and the time to calculate the body's state.
;;
;;   The program makes use of the following fundamental Icy
;;   interface routines:
;;
;;      cspice_furnsh --- makes kernel information available to
;;                        the user's program.
;;
;;      cspice_str2et --- converts strings representing time to counts
;;                        of seconds past the J2000 epoch.
;;
;;      cspice_spkezr --- computes states of one object relative to
;;                         another at a user specified epoch.
;;
;;      cspice_et2utc --- converts an ephemeris time J200 to
;;                         a formatted UTC string.
;;
;;      cspice_prsint --- parse a string representation of an integer
;;                         to an integer
;;
;;      cspice_vnorm --- calculate the magnitude (norm) or a 3-vector.
;;
;;   For the sake of brevity, this program performs few error checks
;;   on its inputs. Mistakes will cause the program to crash.
;;
;;-Required Reading
;;
;;   For additional information, see NAIF IDS Required Reading, and the
;;   headers of the Icy subroutines cspice_furnsh, cspice_spkezr,
;;   cspice_et2utc and cspice_str2et.
;;
;;-Version
;;
;;   -ICY Version 1.0.1, 19-FEB-2008   (EDW)
;;
;;      Update and reformat of header.
;;
;;   -Icy Version 1.0.0, 12-JUN-2003   (EDW)
;;
;;-Index_Entries
;;
;;   None.
;;
;;-&


PRO STATES

   ;;
   ;; Inizialize variables or set type. All variables used in a PROMPT
   ;; construct must be initialized as strings.
   ;;
   leap       = ''
   spk        = ''
   obs        = ''
   targ       = ''
   line       = ''
   frame      = ''
   abcorr     = ''
   answer     = ''
   utcbeg     = ''
   utcend     = ''
   format     = 'C'
   prec       = 0
   maxpts     = 0
   SPICETRUE  = 1B
   SPICEFALSE = 0B

   ;;
   ;; Get the various inputs using interactive prompts:
   ;;
   print
   read, leap, PROMPT = "Enter the name of a leapseconds kernel file: "
   print

   ;;
   ;; First load the leapseconds file into the kernel pool, so
   ;; we can convert the UTC time strings to ephemeris seconds
   ;; past J2000.
   ;;
   cspice_furnsh, leap

   read, spk, PROMPT = "Enter the name of a binary SPK ephemeris file: "
   print

   ;;
   ;; Load the binary SPK file containing the ephemeris data
   ;; that we need.
   ;;
   cspice_furnsh, spk


   read, obs, PROMPT = "Enter the name of the observing body: "
   
   print
   read, targ, PROMPT = "Enter the name of a target body: "
   print


   ;;
   ;; Query for the number of state outputs, then loop.
   ;;
   while maxpts LE 0 do begin

      read, line, PROMPT = "Enter the number of states to be calculated: "

      cspice_prsint, line, maxpts
      print

      ;;
      ;; Check for a nonsensical input for the number of
      ;; look ups to perform. 
      ;;
      if maxpts LT 0 then begin
         print, "The number of states must be greater than 0."
         print
      endif
 
   endwhile

   ;;
   ;; Query for the time interval.
   ;;
   if maxpts EQ 1 then begin

      read, utcbeg, PROMPT = "Enter the UTC time: "
      print

   endif else begin

      read, utcbeg, PROMPT = "Enter the beginning UTC time: "
      print

      read, utcend, PROMPT = "Enter the ending UTC time: "
      print
      
   endelse

   read, frame, PROMPT = "Enter the inertial reference frame (e.g.:J2000): "
   print

   ;;
   ;; Output a banner for the aberration correction prompt.
   ;;
   print, "Type of correction                              Type of state" 
   print, "-------------------------------------------------------------"
   print, "'LT+S'    Light-time and stellar aberration    Apparent state"
   print, "'LT'      Light-time only                      True state"
   print, "'NONE'    No correction                        Geometric state"

   print
   read, abcorr, PROMPT = "Enter LT+S, LT, or NONE: "

   print
   print, "Working ... Please wait"
   print

   ;;
   ;; Convert the UTC time strings into DOUBLE PRECISION ETs.
   ;;
   if maxpts EQ 1 then begin

      cspice_str2et,utcbeg, etbeg

   endif else  begin

      cspice_str2et, utcbeg, etbeg
      cspice_str2et, utcend, etend

   endelse

   ;; 
   ;; At each time, compute and print the state of the target body
   ;; as seen by the observer.  The output time will be in calendar
   ;; format, rounded to the nearest seconds.
   ;; 
   ;; delta is the increment between consecutive times.
   ;; 
   ;; Make sure that the number of points is >= 1, to avoid a
   ;; division by zero error.
   ;;
   if maxpts GT 1 then begin

      delta  = ( etend - etbeg ) / ( double(maxpts) - 1.d)

   endif else begin

      delta = 0.d0

   endelse

   ;;
   ;; Initialize control variables for the cspice_spkezr loop.
   ;;
   et   = etbeg
   cont = SPICETRUE
   i    = 1

   ;;
   ;; Perform the state look ups for the number of requested 
   ;; intervals. The loop continues so long as the expression:
   ;;
   ;;       i <= maxpts  &&  cont == SPICETRUE
   ;;
   ;; evaluates to true.
   ;;
   while ( (i LE maxpts) AND cont ) do begin
      
      ;;
      ;; Compute the state of 'targ' from 'obs' at 'et' in the 'frame'
      ;; reference frame and aberration correction 'abcorr'.
      ;;
      cspice_spkezr, targ, et, frame, abcorr, obs, state, ltime

      ;;
      ;; Convert the ET (ephemeris time) into a UTC time string
      ;; for displaying on the screen.
      ;;
      cspice_et2utc, et, format, prec, utc

      ;; 
      ;; Display the results of the state calculation.
      ;;
      print, FORMAT ='("For time ",I3," of ",I3," the state of: ")', i, maxpts

      print, FORMAT = '("Body            : ", A)', targ
      print, FORMAT = '("Relative to body: ", A)', obs
      print, FORMAT = '("In Frame        : ", A)', frame
      print, FORMAT = '("At UTC time     : ", A)', utc

      print
      print, "                 Position (km)              Velocity (km/s)"
      print, "            -----------------------     -----------------------"
      print, FORMAT='("          X: ",E23.16,"     ",E23.16)',state[0],state[3]
      print, FORMAT='("          Y: ",E23.16,"     ",E23.16)',state[1],state[4]
      print, FORMAT='("          Z: ",E23.16,"     ",E23.16)',state[2],state[5]

      print, FORMAT = '("  MAGNITUDE: ",E23.16,"     ",E23.16)', $
                                       cspice_vnorm(state[0:2]), $
                                       cspice_vnorm(state[3:5])

      ;;
      ;; One output cycle finished. Continue?
      ;;
      print
      read, answer, PROMPT = "Continue? (Enter Y or N): "

      ;;
      ;; Did the user input an 'n'? If not continue.
      ;;
      if ( cspice_eqstr( answer, 'N' ) ) then cont = SPICEFALSE

      ;;
      ;; Increment the current et by delta and increment the loop
      ;; counter to mark the next cycle.
      ;;
      et = et + delta
      i  = i + 1
      
   endwhile

   ;;
   ;; Finished. Unload the kernel files and empty the kenrel pool.
   ;;
   cspice_kclear

END
