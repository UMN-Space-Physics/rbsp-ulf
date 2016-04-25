;+
; PROCEDURE:
;         mms_fpi_angles
;
; PURPOSE:
;         Returns the hard coded angles for the SITL FS FPI pitch angle distributions
;
; NOTE:
;         Expect this routine to be made obsolete after adding the angles to the CDF
; 
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:14:24 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19585 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_angles.pro $
;-
function mms_fpi_angles
    return, [0,6,12,18, $
        24,30,36,42,48,54,60,66,72,78,84,90,96,102, $
        108,114,120,126,132,138,144,150,156,162,168,174] + 3
end