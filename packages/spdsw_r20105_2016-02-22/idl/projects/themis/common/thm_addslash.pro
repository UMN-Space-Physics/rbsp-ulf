;+
;NAME:
; thm_addslash
;PURPOSE:
; Adds a trailing slash to a string, (usually a directory name) if it
; does not already have one. This is used to insure that local and
; remote directory names passed into load programs have the trailing
; slash. Note that even for windows, a '/' works, no need to use '\'
;CALLING SEQUENCE:
; dirslash = thm_addslash(dir)
;INPUT:
; dir = A string, usually a directory name.
;OUTPUT:
; dirslash = dir+'/', if there is no slash, otherwise dir is unchanged
;HISTORY:
; 2012-08-15, jmm, jimm@ssl.berkeley.edu
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2012-08-24 09:57:09 -0700 (Fri, 24 Aug 2012) $
; $LastChangedRevision: 10856 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_addslash.pro $
;-
Function thm_addslash, dir, _extra = _extra

;First check for a slash
n = n_elements(dir)
If(n Eq 0) Then dirslash = '/' Else Begin
    dirslash = dir
    For j = 0, n-1 Do Begin
        temp_string = strtrim(dir[j], 2)
        ll = strmid(temp_string, strlen(temp_string)-1, 1)
        If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
        dirslash[j] = temporary(temp_string)
    Endfor
Endelse

Return, dirslash
End
