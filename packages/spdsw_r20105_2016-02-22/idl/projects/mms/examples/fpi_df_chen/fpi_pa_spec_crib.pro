;Pro fpi_pa_spec_crib
;Purpose: To generate pa distributions for the given energy range
 ;------------------ INPUT PARAMETERS ----------------------------------
;sat:        Satellite number
;            An array of integers (1, 2, 3 or 4) indicating the 4 s/c
;
;specie:     'i' or 'e'
;
;
;units_name: Units for pitch angle spectra
;            'Counts', 'NCOUNTS', 'RATE', 'NRATE',
;            'DF' (or 'PSD'),'DIFF FLUX', 'EFLUX'
;
;energy:   Energy range (maximum range 10-30000), if set, the PA
;distribution averaged over this energy range will be created
;all: to generate PA distribution for all energies (to be used by
;other codes, not a variable to be plotted)
;eachen:To plotcreate  PAD for each energy
;realoadb: To reload the magnetic field data (personal usage, not
;applicable to official spedas codes, and magnetic field data need to
;be loaded in advance)
;reload3d: if set, it will call fpi_3dflux_2dbin to create necessary
;3D data structure
;datab: magnetic field data, default: srvy l2pre (if not existing, use
;srvy ql). If B data resolution is higher than fpi resolution, an
;average B between t[i] and t[i+1] of fpi data is used for the i_th
;point; otherwise, B is interpolated to (t[i]+t[i+1])/2

;example:
;fpi_pa_spec_crib,1,'e',energy=[500,1000],units_name='EFLUX',/reload3d

;--Shan Wang
;----------------------------------------------------------------------
Pro fpi_pa_spec_crib,sat,specie,energy=energy,all=all,$
                     eachen= eachen,$
                     units_name=units_name,$
                     reloadb = reloadb,$
                     reload3d = reload3d,$
                     resolution=resolution,$
                     datab = datab

sat_str=string(sat,format='(I1)')
if not keyword_set(units_name) then $
units_name='counts'        ; 'Counts', 'NCOUNTS', 'RATE', 'NRATE',
                              ; 'DIFF FLUX', 'EFLUX', 'DF'('PSD')
if strupcase(units_name) eq 'PSD' then units_name='DF'

eff_table=0 ; 0: GROUND, 1: ONBOARD --meaningless right now

if keyword_set(reloadb)then begin
  load_dfg,probe=sat,data_rate='brst',/dirname,/onlycdf
endif
;datab = 'mms'+sat_str+'_d'+specie+'s_bentPipeB_DSC_rmsunpulse'
if ~keyword_set(datab) then begin
   datab = 'mms'+sat_str+'_dfg_srvy_l2pre_dmpa_xyz'
   tplot_names,datab,names=nn
   if ~keyword_set(nn) then datab='mms'+sat_str+'_dfg_srvy_dmpa_xyz'
endif
;To generate PA distributions for all energies and all pas
if keyword_set(all) then begin
energy = [0,3e4]
plot_pa_spec_from_crib,sat,specie,units_name,$
                       energy,eff_table,$
                       datab = datab,$
                       /all_energy_bins,$
                       reload3d = reload3d,$
                       resolution=resolution
endif
;----------------------------------------------------------------------

if ~keyword_set(all) and ~keyword_set(eachen) then begin
plot_pa_spec_from_crib, sat, specie, units_name, $
                        energy, eff_table, $
                        PaBin=0,$
                        datab = datab,$
                        reload3d = reload3d,$
                        resolution=resolution
endif


;stop
;----------------------------------------------------------------------

;----------------------------------------------------------------------

if keyword_set(eachen) then begin
  allspec= 'PASPEC_mms'+sat_str+'_UN'+strupcase(units_name)+'_FPI'+specie
   tplot_names,allspec,names=allspec
   if ~keyword_set(allspec) then begin
    energy = [0,3e4]
    plot_pa_spec_from_crib,sat,specie,units_name,$
                       energy,eff_table,$
                       datab = datab,$
                       /all_energy_bins,$
                       reload3d = reload3d,$
                       resolution=resolution
   endif
     allspec= 'PASPEC_mms'+sat_str+'_UN'+strupcase(units_name)+'_FPI'+specie
   tplot_names,allspec,names=allspec
   get_data,allspec,data=d1
   v=reform(d1.e)
   pa = reform(d1.v[0,*])


   for i=0,n_elements(v)-1 do begin
      en_str=strtrim(ceil(v[i]),2)
      name = 'PASPEC_mms'+sat_str+'_EN'+en_str+'_UN'+strupcase(units_name)+'_FPI'+specie
      yy = reform(d1.y[i,*,*])
      store_data,name,data={x:d1.x,y:yy,v:pa},$
        lim={spec:1,ytitle:'mms'+sat_str+'!C'+specie+' '+en_str+' eV',no_interp:1}
      ylim,name,0,180,0
      zlim,name,0,0,1
      options,name,'ztitle',units_string_fpi(units_name,/onlyunit)
   endfor
endif

;stop


END
