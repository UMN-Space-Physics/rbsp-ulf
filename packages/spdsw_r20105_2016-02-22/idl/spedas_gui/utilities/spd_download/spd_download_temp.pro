
;+
;Function:
;  spd_download_temp
;
;Purpose:
;  Create a random numeric filename suffix for temporary files.
;
;Calling Sequence:
;  suffix = spd_download_temp()
;
;Output:
;  Returns 12 digit numeric string preceded by a period
;
;    e.g. ".555350461348"
;
;Notes:
;  
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-02-23 15:13:04 -0800 (Mon, 23 Feb 2015) $
;$LastChangedRevision: 17025 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_download/spd_download_temp.pro $
;
;-

function spd_download_temp

    compile_opt idl2, hidden

  
  ;use milliseconds on clock as seed for random #
  t = systime(/sec) * 1e3

  ;pull digits directly to ensure # of characters
  s = string( randomu(t,/double), format='(F14.12)' )

  ;trim leading zero and use rest as temporary file suffix
  s = strmid(s,1)

  return, s

end