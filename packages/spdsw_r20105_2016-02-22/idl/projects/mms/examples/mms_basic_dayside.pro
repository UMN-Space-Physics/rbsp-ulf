;+
; script for basic dayside science (from EVA, first plot)
; 
; Plots on the figure include:
;   1: DFG, srvy, GSM
;   2. DFG magnitude
;   3. FPI ion spectra
;   4. FPI electron spectra
;   5. FPI Ni (ion density)
;   6. EDP, -log(scpot)
;   7. FPI Vi (ion velocity, 3 components)
;   8. (ExB)z, vperp(z)
;   9. HPCA H+
;   10. HPCA O+
;   11. EDP fast
;   12. EDP srvy, EPSD spectra (x) mms*_edp_srvy_EPSD_x
;   13. DSP, fast, bpsd omni
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-15 07:40:55 -0800 (Fri, 15 Jan 2016) $
; $LastChangedRevision: 19741 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_basic_dayside.pro $
;-
start_time = systime(/sec)

date = '2015-09-01/00:00:00
timespan, date, 1, /day
probe = '1'
; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows
send_plots_to = 'win'
plot_directory = ''
postscript = send_plots_to eq 'ps' ? 1 : 0

; set the following bit to avoid the SDC username/password prompt; this is useful
; if you want to avoid the SDC, or only use local CDFs
LOCAL_FILES_ONLY = 0

; load the data
mms_load_fgm, instrument='dfg', probe=probe, data_rate='srvy', level='l2pre', no_update = LOCAL_FILES_ONLY
mms_load_fpi, probe=probe, data_rate='fast', level='sitl', no_update = LOCAL_FILES_ONLY
mms_load_edp, probe=probe, datatype='scpot', level='l2', no_update = LOCAL_FILES_ONLY
mms_load_edp, probe=probe, data_rate='fast', level='ql', datatype='dce', no_update = LOCAL_FILES_ONLY
mms_load_edp, probe=probe, data_rate='srvy', level='l1b', datatype=['dce', 'hfesp'], no_update = LOCAL_FILES_ONLY
mms_load_dsp, probe=probe, data_rate='fast', level='l2', datatype='bpsd', no_update = LOCAL_FILES_ONLY
mms_load_hpca, probe=probe, data_rate='srvy', level='sitl', no_update = LOCAL_FILES_ONLY

; sum the HPCA spectra over the full field of view
mms_hpca_calc_anodes, fov=[0, 360], probe=probe

; For the s/c potential, we plot -ln(scpot), to match the plot in EVA
calc, '"mms'+probe+'_edp_fast_scpot_ln" = -ln("mms'+probe+'_edp_fast_scpot")'
; update the Y-axis title
options, 'mms'+probe+'_edp_fast_scpot_ln', ytitle='EDP!CFAST!C-ln(scpot)'

; join the velocity data into a single variable
join_vec, 'mms'+probe+['_fpi_iBulkV_X_DSC', '_fpi_iBulkV_Y_DSC', '_fpi_iBulkV_Z_DSC'], 'mms'+probe+'_fpi_iBulkV'

;;;;; The following ExB calculations were taken from EVA, 12/10/2015
; ExB
;------------
sc = 'mms'+strcompress(string(probe), /rem)
vthres = 500.
get_data,sc+'_dfg_srvy_l2pre_dmpa',data=B
get_data,sc+'_edp_fast_dce_dsl',data=E,dl=dl,lim=lim
tnB = tnames(sc+'_dfg_srvy_l2pre_dmpa',ctB)
tnE = tnames(sc+'_edp_fast_dce_dsl',ctE)
if ctB eq 1 and ctE eq 1 then begin
  ; E has a higher time resolution than B
  ; Here, we interpolate B so that its timestamps will match with those of E.
  Bip = fltarr(n_elements(E.x),3)
  wBx = interpol(B.y[*,0], B.x, E.x,/spline)
  wBy = interpol(B.y[*,1], B.x, E.x,/spline)
  wBz = interpol(B.y[*,2], B.x, E.x,/spline)
  iwB2 = 1000./(wBx^2 + wBy^2 + wBz^2)
  EXB = fltarr(n_elements(E.x),3)
  EXB[*,0] = ((E.y[*,1]*wBz - E.y[*,2]*wBy)*iwB2 > (-1)*vthres) < vthres
  EXB[*,1] = ((E.y[*,2]*wBx - E.y[*,0]*wBz)*iwB2 > (-1)*vthres) < vthres
  EXB[*,2] = ((E.y[*,0]*wBy - E.y[*,1]*wBx)*iwB2 > (-1)*vthres) < vthres
  str_element,/delete,'lim','yrange'
  store_data,sc+'_exb_dsl',data={x:E.x,y:EXB},dl=dl
  options,sc+'_exb_dsl',labels=['(ExB)x','(ExB)y','(ExB)z'],labflag=-1,colors=[2,4,6],$
    ytitle=sc+'!CExB',ysubtitle='[km/s]',constant=0,ystyle=1

  ; extract ExB to be compared with FPI
  comp = ['x','y','z']
  clrs = [2,4,6]
  cmax = n_elements(comp)
  for c=0,cmax-1 do begin
    store_data,sc+'_exb_dsl_'+comp[c],data={x:E.x,y:EXB[*,c]}
    options,sc+'_exb_dsl_'+comp[c],labels='(ExB)'+comp[c],labflag=-1,colors=clrs[c],$
      ytitle=sc+'!C(ExB)'+comp[c],ysubtitle='[km/s]',constant=0,ystyle=1
  endfor
endif

; Compare with FPI
;-------------------------

; extract Vperp
tn = tnames(sc+'_fpi_iBulkV',ct)
if ct eq 1 then begin
  comp = ['x','y','z']
  clrs = [2,4,6]
  cmax = n_elements(comp)
  ; V has a much lower time resolution than B
  ; Here, we keep the lower time resolution by interpolating B.
  get_data,sc+'_fpi_iBulkV',data=F
  wBx = interpol(B.y[*,0], B.x, F.x)
  wBy = interpol(B.y[*,1], B.x, F.x)
  wBz = interpol(B.y[*,2], B.x, F.x)
  iwB2 = 1./(wBx^2 + wBy^2 + wBz^2)
  BdotV = iwB2*(wBx*F.y[*,0]+wBy*F.y[*,1]+wBz*F.y[*,2])
  Vperp = fltarr(n_elements(F.x),3)
  Vperp[*,0] = F.y[*,0] - BdotV*wBx
  Vperp[*,1] = F.y[*,1] - BdotV*wBy
  Vperp[*,2] = F.y[*,2] - BdotV*wBz
  for c=0,cmax-1 do begin
    store_data,sc+'_fpi_iBulkVperp_'+comp[c],data={x:F.x,y:Vperp[*,c]}
    options,sc+'_fpi_iBulkVperp_'+comp[c],labels='Vperp,'+comp[c],labflag=-1,colors=clrs[c],$
      ytitle=sc+'!CFPI!CVperp,'+comp[c],ysubtitle='[km/s]',constant=0,ystyle=1
  endfor

  ; combine
  for c=0,cmax-1 do begin
    store_data,sc+'_exb_vperp_'+comp[c],data=sc+['_exb_dsl_','_fpi_iBulkVperp_']+comp[c]
    options,sc+'_exb_vperp_'+comp[c],colors=[clrs[c],0],labflag=-1,$
      labels=['(ExB)'+comp[c],'Vperp,'+comp[c]]
  endfor

endif

; let's put the ephemeris data at the bottom
eph_variable = 'mms'+strcompress(string(probe), /rem)+'_pos_gsm'
b_variable = '_dfg_srvy_l2pre_gsm'
suffix_kludge = ['0', '1', '2'] ; because the suffix is different depending on the level...

; eph_variable = 'mms'+strcompress(string(i), /rem)+'_dfg_srvy_gsm_dmpa'
calc,'"'+eph_variable+'_re" = "'+eph_variable+'"/6371.2'

; split the position into its components
split_vec, eph_variable+'_re'

; set the label to show along the bottom of the tplot
options, eph_variable+'_re_'+suffix_kludge[0],ytitle='X-GSM (Re)'
options, eph_variable+'_re_'+suffix_kludge[1],ytitle='Y-GSM (Re)'
options, eph_variable+'_re_'+suffix_kludge[2],ytitle='Z-GSM (Re)'
;position_vars = [eph_variable+'_re_'+suffix_kludge[0], eph_variable+'_re_'+suffix_kludge[1], eph_variable+'_re_'+suffix_kludge[2]]
position_vars = [eph_variable+'_re_'+suffix_kludge[2], eph_variable+'_re_'+suffix_kludge[1], eph_variable+'_re_'+suffix_kludge[0]]


; set some plot options
ylim, 'mms'+probe+'_dsp_bpsd_omni', 0, 0, 1
zlim, 'mms'+probe+'_dsp_bpsd_omni', 0, 0, 1
ylim, 'mms'+probe+'_edp_srvy_EPSD_x', 0, 0, 1
zlim, 'mms'+probe+'_edp_srvy_EPSD_x', 0, 0, 1
options, 'mms'+probe+'_fpi_iBulkV', colors=[2, 4, 6]
options, 'mms'+probe+'_fpi_iBulkV', labels=['Vx', 'Vy', 'Vz']
options, 'mms'+probe+'_fpi_iBulkV', labflag=-1
options, 'mms'+probe+'_edp_fast_dce_dsl', colors=[2, 4, 6]
options, 'mms'+probe+'_edp_fast_dce_dsl', labels=['Ex', 'Ey', 'Ez']
options, 'mms'+probe+'_edp_fast_dce_dsl', labflag=-1
options,'mms'+probe+'_fpi_DISnumberDensity', ytitle='FPI!CDIS!CDensity'

; clip the field data, so the data at perigee doesn't dominate the figure
split_vec, 'mms'+probe+b_variable+'_bvec'
tclip, 'mms'+probe+b_variable+'_bvec_?', -50, 50, /overwrite
tclip, 'mms'+probe+b_variable+'_btot', -50, 50, /overwrite
store_data, 'mms'+probe+'_dfg_gsm_srvy', data='mms'+probe+b_variable+'_bvec'+['_x', '_y', '_z']
options, 'mms'+probe+'_dfg_gsm_srvy', labflag=-1
options, 'mms'+probe+'_dfg_gsm_srvy', labels=['Bx', 'By', 'Bz']
options, 'mms'+probe+'_dfg_gsm_srvy', colors=[2, 4, 6]
options, 'mms'+probe+b_variable+'_btot', labels='Bmag'
options, 'mms'+probe+b_variable+'_btot', ytitle='mms'+probe+'!CFGM'
options, 'mms'+probe+'_dfg_gsm_srvy', ytitle='mms'+probe+'!CFGM!CGSM'

; degap the FPI spectra
tdegap, 'mms'+probe+'_fpi_iEnergySpectr_omni_sum', /overwrite
tdegap, 'mms'+probe+'_fpi_eEnergySpectr_omni_sum', /overwrite
; degap the BPSD
tdegap, 'mms'+probe+'_dsp_bpsd_omni', /overwrite

window, ysize=800
; plot the data
tplot, 'mms'+probe+['_dfg_gsm_srvy', $
                    '_dfg_srvy_l2pre_gsm_btot', $
                    '_fpi_iEnergySpectr_omni_sum', $
                    '_fpi_eEnergySpectr_omni_sum', $
                    '_fpi_DISnumberDensity', $
                    '_edp_fast_scpot_ln', $
                    '_fpi_iBulkV', $
                    '_exb_vperp_z', $
                    '_hpca_hplus_RF_corrected_elev_0-360', $
                    '_hpca_oplus_RF_corrected_elev_0-360', $
                    '_edp_fast_dce_dsl', $
                    '_edp_srvy_EPSD_x', $
                    '_dsp_bpsd_omni' $
                    ], var_label=position_vars
                    
if postscript then tprint, plot_directory + 'mms'+probe + '_basic_dayside'
if send_plots_to eq 'png' then begin
  makepng, plot_directory + 'mms'+probe + '_basic_dayside_'+ $
    time_string(date, tformat='YYYYMMDD_hhmmss.fff'), $
    /mkdir
endif
            
print, 'took ' + string(systime(/sec)-start_time) + ' seconds to run'

end