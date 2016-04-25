;+
;
;  Name: SPD_UI_SAVE_TEMPLATE
;  
;  Purpose: SAVES a spedas template
;  
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_save_template.pro $
;-
pro spd_ui_save_template,info

  compile_opt idl2
  
  if info.marking ne 0 || info.rubberbanding ne 0 then begin
    return
  endif
  
  info.ctrl = 0
    
  filename=info.template_filename  

  IF NOT Is_String(filename) then filename=''
  IF filename EQ '' THEN BEGIN 
    xt = Time_String(systime(/sec))
    timeString = Strmid(xt, 0, 4)+Strmid(xt, 5, 2)+Strmid(xt, 8, 2)+$
      '_'+Strmid(xt,11,2)+Strmid(xt,14,2)+Strmid(xt,17,2)
    fileString = 'spedas_template_'+timeString+'.tgt'
    ;filename = dialog_pickfile(Title='Save SPEDAS Template:', $
    ;   Filter='*.tgt', File = fileString, /Write, Dialog_Parent=info.master)
    filename = spd_ui_dialog_pickfile_save_wrapper(Title='Save SPEDAS Template:', $
       Filter='*.tgt', File = fileString, /Write, Dialog_Parent=info.master)
  ENDIF 
  IF(Is_String(filename)) THEN BEGIN
    save_spedas_template,template=info.template_object,filename=filename,$
       statusmsg=statusmsg,statuscode=statuscode
    IF (statuscode LT 0) THEN BEGIN
      ; statuscode -6 is "operation cancelled by user", no need
      ; to pop up another dialog for that case
      IF (statuscode NE -6) THEN dummy=dialog_message(statusmsg,/ERROR,/CENTER)
    ENDIF ELSE BEGIN
      info.template_filename=filename
    ENDELSE
      info.statusBar->Update, statusmsg
      info.historywin->Update,statusmsg
  ENDIF ELSE BEGIN
    info.statusBar->Update, 'Operation Cancelled'
  ENDELSE
  
end
