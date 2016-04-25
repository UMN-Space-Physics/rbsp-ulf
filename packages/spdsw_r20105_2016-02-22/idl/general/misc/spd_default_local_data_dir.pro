;+
;NAME:
; spd_default_local_data_dir
;
;PURPOSE:
; Returns the default data directory for file downloads for varius projects.
; It is used for the GUI configuration settings.
; Simplified replacement for root_data_dir
;
;CALLING SEQUENCE:
; spd_default_local_data_dir
;
;INPUT:
; none
;
;OUTPUT:
; (string) Directory in user's home path
;
;HISTORY:
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;-----------------------------------------------------------------------------------

function spd_default_local_data_dir
  data_dir = file_search('~',/expand_tilde) + path_sep() + 'data' + path_sep()
  return, data_dir
end