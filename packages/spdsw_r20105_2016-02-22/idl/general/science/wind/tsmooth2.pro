
;
;+
;PROCEDURE: tsmooth2, name, width, newname=newname
;PURPOSE:
;  Smooths the tplot data. 
;INPUTS: 
;  name:	The tplot handle.
;	 width:	Integer array, same dimension as the data. Default is 10.[NB: the IDL routine used to smooth the data will
;	   automatically add 1 if the width is even]
;	 newname: name to assign to the output tplot variable. Default is name+'_sm'
;	 preserve_nans: (Added 20 dec 2011 lphilpott) set this keyword to not smooth over nans in the data. 
;  edge_truncate: If set, this keyword is passed to the smooth routine
;
;
;Documentation not complete.... 	
;
;
;CREATED BY:     REE 10/11/95
;Modified by:  D Larson.
;LAST MODIFICATION:	%M%
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $

;-

pro tsmooth2, name_, width, esteps=esteps, newname=newname, preserve_nans=preserve_nans,edge_truncate=edge_truncate, display_object=display_object
; 
; Check that width is supplied.
if n_elements(width) eq 0 then begin
  message,/info, 'Smoothing width defaulting to 10.'
  width=10
endif

names = tnames(name_,cnt)
for n=0,cnt-1 do begin
name = names[n]
if cnt gt 1 then newname = name+'_sm'
; Retrieve the data and check.
get_data,name,data=data,alim=alim
if size(data, /type) ne 8 then dprint,'Bad data.'

w = width
d = dimen2(data.y)
if d ne dimen1(w) then w = replicate(width[0],d)

;time check, this program can have issues with highly irregular time
;intervals; check for really badly off time intervals, say more than width * the
;median dt
ntimes = n_elements(data.x)
if(ntimes Lt width) then begin
    dprint, dlevel=1, 'WARNING: Fewer data points than smoothing width for: '+tnames(name), display_object=display_object
endif else begin
    dt = data.x[1:*]-data.x
    dt_test = width*median(dt)
    big_gap = where(dt gt dt_test, nbig_gap)
    if(nbig_gap Gt 0) then begin
        nbstr = strcompress(string(nbig_gap), /remove_all)
        dprint, dlevel=1, display_object=display_object, 'WARNING: Variable: '+tnames(name)+' has '+$
          nbstr+' data gaps larger than the smoothing width*median dt'
    endif
endelse
; Start main loop for smoothing.

for i = 0,d-1 do begin
  if w[i] gt 2 then begin
    ; find any NANS
    nan_data=where(finite(data.y[*,i],/nan),nancount)
    nonnan_data=where(~finite(data.y[*,i],/nan),nonnan_count)
    ; deal with 'bad data'
    if nonnan_count gt 0 then begin
      ; this is to avoid a floating operand error when checking for bad data
      temp_ind=where(data.y[nonnan_data,i] gt 1.9e20,count)
      if count gt 0 then begin
          bad_data=nonnan_data[temp_ind]
          data.y[bad_data,i]=( data.y[bad_data-1,i] + data.y[bad_data+1,i] ) /2.0
      endif
      data.y[*,i] = smooth(data.y[*,i],w[i],/nan,edge_truncate=edge_truncate) ; this still produces floating operand errors if there are nans for some reason
      if count gt 0 then $
          data.y[bad_data,i]=2.0e20
      if keyword_set(preserve_nans) then begin 
        if nancount gt 0 then data.y[nan_data,i]=!values.f_nan ;should this be double or float?
      endif
    endif
  endif
endfor

; Store the data.
printdat,out=outs,width,'width',/val
str_element,/add,alim,'comment',outs[0]
if not keyword_set(newname) then newname = name+'_sm'
store_data,newname,data=data,dlim=alim

endfor
return

end
