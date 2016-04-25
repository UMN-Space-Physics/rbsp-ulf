;;-Abstract
;;
;;   This "cookbook" program demonstrates the use of SPICE SPK ephemeris
;;   files and software.
;;
;;   Although this program lacks sophistication, it can serve
;;   as a starting point from which you could build your own program.
;;
;;   The Icy subroutine cspice_furnsh (Furnish a program with SPICE
;;   kernels) "loads" kernel files into the SPICE system. The calling
;;   program indicates which files to load by passing their names to
;;   cspice_furnsh.  It is also possible to supply cspice_furnsh with the
;;   name of a "metakernel" containing a list of files to load; see
;;   the header of cspice_furnsh for an example.
;;
;;   cspice_spkezr (S/P Kernel, easier reader) computes states by by
;;   accessing the data loaded with cspice_furnsh (cspice_spkezr does
;;   not require the name of an SPK file as input).
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
;;   The user is prompted for the following input:
;;
;;      - The name of a NAIF leapseconds kernel file.
;;      - The name of one binary NAIF SPK ephemeris file.
;;      - The name for the first target body.
;;      - The name for the second target body.
;;      - The name for the observing body.
;;      - A UTC time interval at which to determine states.
;;
;;   Output
;;
;;   The program calculates the angular separation of the two
;;   target bodies as seen from the observing body.
;;
;;-Particulars
;;
;;   The user enters the names for two target bodies and an
;;   observer (these may be any objects in the solar system for
;;   which the user has data) and the UTC time of interest.
;;
;;   For the sake of brevity, this program NO error checking
;;   on its inputs. Mistakes will cause the program to crash.
;;
;;-Required Reading
;;
;;   See the cookbook routine states.pro.
;;
;;-Version
;;
;;   -ICY Version 1.0.1, 19-FEB-2008   (EDW)
;;
;;      Update and reformat of header. Minor code edits.
;;
;;   -ICY Version 1.0.0, 11-JUNE-2003   (EDW) 
;;
;;-Index_Entries
;;
;;   None.
;;
;;-&

PRO simple

   ;;
   ;; Inizialize variables or set type. All variables used in a PROMPT
   ;; construct must be initialized as strings.
   ;;
   MAXPTS    = 10
   leap      = ''
   spk       = ''
   obs       = ''
   targ1     = ''
   targ2     = ''
   utcbeg    = ''
   utcend    = ''
   answer    = ''
   SPICETRUE = 1B
   SPICEFALSE= 0B

   x = dblarr( MAXPTS)
   y = dblarr( MAXPTS)
   
   print
   print
   print, '                    Welcome to SIMPLE'
   print
   print, 'This program calculates the angular separation of two'
   print, 'target bodies as seen from an observing body.'
   print
   print, 'The angular separations are calculated for each of 10'
   print, 'equally spaced times in a given time interval. A table'
   print, 'of the results is presented.'
   print

   ;;
   ;; Set the time output format, the precision of that output
   ;; and the reference frame.  Note:  The angular separation has the
   ;; same value in all reference frames.  Let's use our favorite, J2000.
   ;; We need an aberration correction.  "LT+S", light time plus stellar
   ;; aberration, satisfies the requirements for this program.
   ;;
   ref  = 'J2000'
   corr = 'LT+S'


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

   ;;
   ;; Load the binary SPK file containing the ephemeris data
   ;; that we need.
   ;;
   cspice_furnsh, spk

   cont = SPICETRUE

   ;;
   ;; Loop till the user quits.
   ;;
   while cont do begin

      ;;
      ;; Get the names for the two target bodies and the observing
      ;; body.
      ;;
      print
      read, obs  , PROMPT = "Enter the name of the observing body: "

      print
      read, targ1, PROMPT = "Enter the name of the first target body: "

      print
      read, targ2, PROMPT = "Enter the name of the second target body: "

      ;;
      ;; Get the beginning and ending UTC times for the time interval
      ;; of interest.
      ;;
      print
      read, utcbeg, PROMPT = "Enter the beginning UTC time: "

      print
      read, utcend, PROMPT = "Enter the ending UTC time: "

      print
      print, "Working ... Please wait."
      print

      ;;
      ;; Convert the UTC times to ephemeris seconds past J2000 (ET),
      ;; since that is what the SPICELIB readers are expecting.
      ;;
      cspice_str2et, utcbeg, etbeg
      cspice_str2et, utcend, etend
      cspice_et2utc, etbeg, "C", 0, utcbeg
      cspice_et2utc, etend, "C", 0, utcend

      ;;
      ;; Calculate the difference between evaluation times.
      ;;
      delta  = ( etend - etbeg ) / ( DOUBLE(MAXPTS)  - 1.d);

      ;;
      ;; For each time, get the apparent states of the two target
      ;; bodies as seen from the observer.
      ;;
      et = etbeg;

      for i=0, (MAXPTS-1) do begin

         ;;
         ;; Compute the state of targ1 and targ2 from obs at et then
         ;; calculate the angular separation between targ1 and targ2 
         ;; as seen from obs. Convert that angular value from radians 
         ;; to degrees.
         ;;
         cspice_spkezr, targ1, et, ref, corr, obs, state1, lt1
         cspice_spkezr, targ2, et, ref, corr, obs, state2, lt2
 
         ;;
         ;; Save the time and the separation between the target bodies
         ;; (in degrees), as seen from the observer, for output to the
         ;; screen.
         ;;
         x[i] = et
         y[i] = cspice_vsep ( state1[0:2], state2[0:2]) * cspice_dpr()
         et   = et + delta

       endfor

      ;;
      ;; Display the time and angular separation of the desired
      ;; target bodies for the requested observer for each of the
      ;; equally spaced evaluation times in the given time interval.
      ;;
      ;; If you have a graphics package, you may wish to write the
      ;; time and angular separation data to a file, and then plot
      ;; them for added effect.
      ;;
      print
      print, FORMAT =                                                      $
             '( "The angular separation between bodies ", A, " and ", A )',$
                                                                targ1, targ2
      print, FORMAT = '( "as seen from body ", A, "." )', obs
 
      print
      print, FORMAT= '("From: ", A)', utcbeg
      print, FORMAT= '("To  : ", A)', utcend

      print
      print, "       UTC Time                 Separation"
      print, "----------------------------------------------"

      for i= 0, (MAXPTS-1) do begin

         cspice_et2utc, x[i], "C", 0, utctim
         print, FORMAT= '(2X,A20,5X,F15.8," deg")', utctim, y[i]

      endfor
 
      print
      read, answer, PROMPT = "Continue? (Enter Y or N): "
      print
      print

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

