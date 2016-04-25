;;-Abstract
;;
;;   This `cookbook' example program demonstrates use of the
;;   following two Icy time conversion routines:
;;
;;                  cspice_str2et
;;                  cspice_et2utc
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
;;   The user will be prompted for:
;;
;;      - The name of a leapseconds Kernel file.
;;
;;   Output
;;
;;   This program will output to the terminal, several
;;   examples of valid UTC time strings and their corresponding ET
;;   (ephemeris time) values.
;;
;;-Examples
;;
;;   None.
;;
;;-Particulars
;;
;;   This program uses the Icy routines cspice_str2et and cspice_et2utc.
;;   These routines convert between UTC and ET representations of
;;   time:
;;
;;      UTC    is a character string representation of Universal
;;             Time Coordinated.  which may be in calendar, day
;;             of year, or Julian date format.  UTC time strings
;;             are human-readable and thus suitable as user input.
;;
;;      ET     which stands for Ephemeris Time, is a double precision
;;             number of ephemeris seconds past Julian year 2000,
;;             also called Barycentric Dynamical Time.  ET time is
;;             used internally in CSPICE routines for reading
;;             ephemeris files.
;;
;;   For the sake of brevity, this program does NO error checking
;;   on its inputs. Mistakes will cause the program to return control to
;;   the IDL interpreter.
;;
;;-Required Reading
;;
;;   Refer to Time Required Reading and the cspice_str2et and cspice_et2utc
;;   module headers for additional information.
;;
;;-Version
;;
;;   -ICY Version 1.0.1, 19-FEB-2008   (EDW)
;;
;;      Update and reformat of header. Minor code edit.
;;
;;   -ICY Version 1.0.0, 13-JUN-2003   (EDW)
;;
;;-Index_Entries
;;
;;   None.
;;
;;-&

PRO tictoc

   ;;
   ;;
   ;; Inizialize variables or set type. All variables used in a PROMPT
   ;; construct must be initialized as strings.
   ;;
   ;;
   ;; Set the example time strings and the precision level for output.
   ;;
   SPICETRUE  = 1B
   SPICEFALSE = 0B

   utc = [ '9 JAN 1986 03:12:59.22451', $
           '1/9/86 3:12:59.22451',      $
           '86-365//12:00',             $
           'JD 2451545',                $
           '77 JUL 1',                  $
           '1 JUL ' + "'29" ]
   NCASES = n_elements( utc )
   
   prec   = 3
   leap   = ''
   i      = 0
   cont   = SPICETRUE
   answer = ''

   ;;
   ;; Information for the user.
   ;;
   print, '                 Welcome to TICTOC'
   print 
   print, 'This program demonstrates the use of the Icy  ' 
   print, 'time conversion utility routines: cspice_str2et and cspice_et2utc.'
   print

   ;;
   ;; Get and load the leapsecond kernel.
   ;;
   read, leap, PROMPT = 'Enter the name of a leapseconds kernel file: '
   
   cspice_furnsh, leap

   print
   print, 'Working ... Please wait.'
   print

   while ( (i LT NCASES) AND cont ) do begin

      ;;
      ;; Begin output.
      ;;
      print
      print, '      Example UTC time      : ', utc[i]

      ;;
      ;; Convert the time string to ephemeris time J2000.
      ;;
      cspice_str2et, utc[i], et
      print
      print, FORMAT = '("      Corresponding ET      : ",E18.8)', et
      print

      ;;
      ;; Convert the ephemeris time to a calendar format.
      ;;
      format = 'C';
      cspice_et2utc, et , format, prec, timestr
      print, '      UTC calendar format   :  ', timestr

      ;;
      ;; Convert the ephemeris time to a day-of-year format.
      ;;
      format = 'D';
      cspice_et2utc, et , format, prec, timestr
      print, '      UTC day of year format:  ', timestr


      ;;
      ;; Convert the ephemeris time to a Julian Day format.
      ;;
      format = 'J';
      cspice_et2utc, et , format, prec, timestr
      print, '      UTC Julian date format:  ', timestr

      i = i + 1

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
