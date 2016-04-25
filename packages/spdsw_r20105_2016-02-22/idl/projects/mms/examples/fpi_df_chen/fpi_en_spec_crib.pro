;sat: 1,2,3,4 sc number
;specie: 'i' or 'e'
;data_rate: data time resolution, default: brst
;units_name: 'df','EFLUX','DIFF FLUX' (unit from data files or
;existing tplot variables), default 'df'
;reload3d: if set, store [time, angular bin, energy] structures for
;requested time.
;reloadb: not applicable to official spedas codes, magnetic field data
;need to be loaded in advance
;datab: tplot variable name for the magnetic field, default: srvy
;l2pre (if not existing, use srvy ql)
;reloadpa: if set, calculate pa distributions for all energies and
;angular bins
;pa_range: if set, create fluxes for given pa_range, default [0,180]
;(omni spectra)
;eachpa: if set, create fluxes for each pa (30 in total, with a pa bin
;size of 6 degrees)
;out_unit: output units (if different from existing tplot variables of
;pa distributions), 'df', 'EFLUX', 'DIFF FLUX', default: same
;with units_name (whose default  is 'df')

;after loading fpi Skymap and magnetic field data, for the first time
;to call this crib, reload3d and reloadpa needs to be set

;Example:
;timespan,'2015-08-15/13:03',2,/min  ;set up time
;;;;;load fpi dist data and magnetic field data
;fpi_en_spec_crib,sat=3,specie='e',/reload3d,/reloadpa,units_name='EFLUX',pa_range=[0,180]
;Then no need to set reload3d and reloadpa again
;fpi_en_spec_crib,sat=3,specie='e',units_name='EFLUX',pa_range=[0,12]
;--Shan Wang
Pro fpi_en_spec_crib,sat=sat,$
                     specie=specie,$
                     data_rate=data_rate,$
                     units_name=units_name,$
                     reload3d=reload3d,$
                     reloadb=reloadb,$
                     reloadpa=reloadpa,$
                     pa_range=pa_range,$
                     eachpa = eachpa,$
                     out_unit=out_unit,$
                     datab = datab
                     
sat_str=string(sat,format='(I1)')
if ~keyword_set(specie) then specie='e'
if ~keyword_set(data_rate) then data_rate='brst'
if ~keyword_set(units_name) then units_name='df'
if ~keyword_set(out_unit) then out_unit=units_name

if keyword_set(reloadpa) then begin
  fpi_pa_spec_crib,sat,specie,/all,reload3d=reload3d,reloadb=reloadb,$
    units_name=units_name,resolution=data_rate,datab=datab
endif

get_data,'PASPEC_mms'+sat_str+'_UN'+strupcase(units_name)+'_FPI'+specie,data=d
pa = reform(d.v[0,*])
npa = n_elements(pa)
energy=d.e
onet=fltarr(n_elements(d.x))+1
vv = onet#energy
if keyword_set(eachpa) then begin
  for i=0,npa-1 do begin
    pa_str=strtrim(ceil(pa[i]),2)
    yy = transpose(reform(d.y[*,*,i]))
    if out_unit ne units_name then begin
      if units_name eq 'df' then yy = yy*1.e30 ;/cm^6 to /km^6
      convert_flux_unit,specie=specie,energy=vv,flux=yy,$
        from_unit=units_name,to_unit=out_unit,new_flux=yy
    endif
    name='mms'+sat_str+'_'+strupcase(out_unit)+'_d'+specie+'s_pa_'+pa_str
    store_data,name,$
      data={x:d.x,y:yy,v:d.e},$
      lim={spec:1,ytitle:'mms'+sat_str+'!Cd'+specie+'s!CPA '+strjoin(strsplit(pa_str,'_',/extract),'-'),$
           no_interp:1,ztitle:units_string_fpi(out_unit,/onlyunit)}
    ylim,name,10,30000,1
    zlim,name,0,0,1
  endfor
endif else begin
  if ~keyword_set(pa_range) then pa_range=[0,180]
  ind = where(pa ge pa_range[0] and pa le pa_range[1],cc)
  if cc eq 0 then begin
    print,'no pitch angle in the given range'
    return
  endif
  pa_str = strtrim(ceil(pa_range[0]),2)+'_'+strtrim(ceil(pa_range[1]),2)
  name='mms'+sat_str+'_'+strupcase(out_unit)+'_d'+specie+'s_pa_'+pa_str
  if cc eq 1 then begin
     yy = reform(d.y[*,*,ind])
  endif else begin
     yy = mean(d.y[*,*,ind],dimension=3,/nan)
  endelse
  yy = transpose(yy)
  if out_unit ne units_name then begin
      if units_name eq 'df' then yy = yy*1.e30 ;/cm^6 to /km^6
      convert_flux_unit,specie=specie,energy=vv,flux=yy,$
        from_unit=units_name,to_unit=out_unit,new_flux=yy
  endif
  store_data,name,$
    data={x:d.x,y:yy,v:d.e},$
      lim={spec:1,ytitle:'mms'+sat_str+'!Cd'+specie+'s!CPA '+strjoin(strsplit(pa_str,'_',/extract),'-'),$
           no_interp:1,ztitle:units_string_fpi(out_unit,/onlyunit)}
    ylim,name,10,30000,1
    zlim,name,0,0,1
endelse

END
