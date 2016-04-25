Pro flip_dist_crib,sat=sat,time_str=time_str,$
                   species=species,$
                   v0 = v0,$
                   v1 = v1,$
                   v2 = v2,$
                   v3 = v3,$
                   start_time=start_time,$
                   end_time=end_time,$
                   angle=angle,$
                   zcut=zcut,$
                   noreload_3d=noreload_3d,$
                   noreloadb=noreloadb,$
                   noflip = noflip,$
                   zrange=zrange,$
                   vrange=vrange,$
                   outputfolder=outputfolder,$
                   ThirdDirLim=ThirdDirLim,$
                   trange_bve=trange_bve,$
                   datab = datab,$
                   reduce = reduce

if ~keyword_set(sat) then sat = 3
sat_str=string(sat,format='(I1)')
if ~keyword_set(time_str) then time_str='074653' ; for LMN
filetype='png'  ; 'png' or 'ps' or 'x'
if ~keyword_set(species) then species ='e'  ; 'e' or 'i'
if ~keyword_set(v0) then v0 = 'mms'+sat_str+'_dis_numberDensity'
if ~keyword_set(v1) then v1 = 'mms'+sat_str+'_B_brst_LMN_'+time_str
if ~keyword_set(v2) then v2 = 'mms'+sat_str+'_V'+species+'_brst_LMN_'+time_str
if ~keyword_set(v3) then v3 = 'mms'+sat_str+'_edp_dce_brstinterp_LMN_'+time_str

coord_str='FAC'
if ~keyword_set(angle) and ~keyword_set(ThirdDirLim) then angle=[-20,20]
;Choose start and end times
if ~keyword_set(start_time) then start_time='2015-08-15/13:00:00.000'
if ~keyword_set(end_time) then _time = '2015-08-15/13:04:15.000'
if ~keyword_set(trange_bve) then trange_bve = [start_time,end_time]
;trange_bve = '2015-10-03/'+['15:35:40','15:36:40']

if n_elements(zcut) eq 0 then zcut='bulk';'bulk'

units='df'
resolution='brst'
noreload_3d=noreload_3d
noreloadb=noreloadb

if keyword_set(reduce) then begin
   if species eq 'i' then begin
      ThirdDirLim=[-2400,2400]
   endif
   if species eq 'e' then begin
      ThirdDirLim=[-10300,10300]
   endif
   zcut = 0
endif


;ThirdDirLim=[-200,200]
;ThirdDirLim=1
if keyword_set(angle) then begin
if max(angle) lt 90 then begin
   reduce_str='ang'+strtrim(ceil(angle[1]),2)
   method_reduce = 'ave'
endif else begin
   method_reduce = 'ave';'sum' or 'ave'
   zcut = 0
   reduce_str='reduce_'+method_reduce
endelse
endif

if keyword_set(ThirdDirLim) then begin
   method_reduce='ave'
   reduce_str='third'+strtrim(ceil(thirddirlim[1]),2)
endif
;method_reduce='ave'
;method_reduce='sum'
;reduce_str='slice_sum'

if ~keyword_set(zrange) then begin
if units eq 'counts' then begin
   if species eq 'e' then zrange=[0.1,5000] else zrange=[0.01,500]
endif else begin
   if species eq 'e' then begin
      if method_reduce eq 'ave' then zrange=[5.E-30,5.e-26] else zrange=[1e-31,1e-26]
   endif else begin
      if method_reduce eq 'ave' then zrange=[1.0e-25,1.0e-21] else zrange=[1e-26,1e-23]
   endelse
endelse
endif

if ~keyword_set(vrange) then begin
if species eq 'e' then vrange=[-5e4,5e4] else vrange=[-2400,2400]
endif
;xrange=[-1000,1000]


start_time=time_double(start_time)
end_time = time_double(end_time)

date_str=strmid(time_string(start_time,format=2),0,8)


;********************!!! Set Output Folder
;!!!*****************************************
;mat_gse2dsl=0
coord=strlowcase(coord_str)
case coord_str of
'LMN':rotations=['xy','xz','yz']
'DSC':rotations=['xy','xz','yz']
'GSE':rotations=['xy','xz','yz']
'GSM':rotations=['xy','xz','yz']
'FAC':rotations=['BV','BE','perp']
endcase
; Input the increment in seconds
if coord_str eq 'LMN' then coord_str=coord_str+time_str
case resolution of
'fast':increment = 5.0
'brst':if species eq 'e' then increment = 0.03 else increment=0.15
endcase
;increment = 0.06
; Input the time interval for each plot (in seconds)
timeinterval = 0
if data_type(zcut) eq 7 then zcut_title='_zbulk' else zcut_title='_z0'

if ~keyword_set(outputfolder) then begin
Case StrUpCase(!version.os_family) of
    'WINDOWS' : outputfolder='G:\data\PLOTS\MMS\'+date_str+'\mms'+sat_str+'_'+species+'flip_VDF_'+coord_str+'_'+resolution+zcut_title+'_'+reduce_str+'\'
    Else : outputfolder='/home/wang/mms/fig/'+date_str+'/mms'+sat_str+'_'+species+'flip_VDF_'+coord_str+'_'+resolution+zcut_title+'_'+reduce_str+'/'
 Endcase
endif
if filetype ne 'x' then  file_mkdir,outputfolder

;if ~keyword_set(noreloadb) then begin
;   plot_vector_inverse,'mms'+sat_str+'_d'+species+'s_bentPipeB_'+['X','Y','Z']+'_DSC',$
;                    name='mms'+sat_str+'_d'+species+'s_bentPipeB_DSC'
;   tplot_rotate,var='mms'+sat_str+'_d'+species+'s_bentPipeB_DSC',axis=2,angle=-76,$
;                name='mms'+sat_str+'_d'+species+'s_bentPipeB_DSC_rmsunpulse'
;   get_timespan,trange
;   time_clip,'mms'+sat_stxr+'_d'+species+'s_bentPipeB_DSC_rmsunpulse',trange[0],trange[1],/replace
;endif
if ~keyword_set(noreloadb) then begin
   load_dfg,probe=sat,/onlycdf
endif

timespan, start_time, time_double(end_time)-time_double(start_time),/s


if ~keyword_set(noreload_3d) then begin
   ;datab = 'mms'+sat_str+'_dfg_srvy_dmpa_xyz'
   fpi_3dflux_2dbin,sat,species,resolution=resolution,units_name=units,$
                   thebdata=datab
endif



column=3

if keyword_set(noflip) then begin
row=1
arrange_plots,x0,y0,x1,y1,nx=column,ny=row,ygap=0.08,x1margin=0.05,$
              x0margin=0.1,y1margin=-0.04,xgap=0.1,y0margin=0.25
fig_dim=[1200,400]
endif else begin
row=2
arrange_plots,x0,y0,x1,y1,nx=column,ny=row,ygap=0.1,x1margin=0.08,$
              x0margin=0.1,y1margin=-0.04,xgap=0.1,y0margin=0.12
x0=x0[3:5]
x1=x1[3:5]
y0=y0[3:5]
y1=y1[3:5]
 fig_dim=[1000,600]
endelse

              

  ;tplot,[bfield,vi,efield]
;tplot,'ntmp'
;tplot_options,'noerase',1
if ~keyword_set(noflip) then $
tplot,[v0,v1,v2,v3]
;tplot_options,'noerase',0
;stop
mydevice=!D.name
 

;  loadct,34
;  tvlct,r,g,b,/get
;  r[0]=0 & g[0]=0 & b[0]=0
;  r[255]=255 & g[255]=255 & b[255]=255
;  tvlct,r,g,b


current_time = start_time

; ROTATION: SUGGESTING THE X AND Y AXIS IN THE OUTPUT FILE, WHICH CAN BE SELECTED AS THE FOLLOWINGS:
; 'BV': the x axis would be V_para (to the magnetic field) and the bulk velocity would be in the x-y plane. (DEFAULT)
; 'BE': the x axis would be V_para (to the magnetic field) and the VxB direction would be in the x-y plane.
; 'xy': the x axis would be V_x and the y axis would be V_y.
; 'xz': the x axis would be V_x and the y axis would be V_z.
; 'yz': the x axis would be V_y and the y axis would be V_z.
; 'perp': the x-y plane is perpendicular to the magnetic field, while the x axis would be the velocity projection on the plane.
; 'perp_xy': the x-y plane is perpendicular to the magnetic field, while the x axis representing the x projection on the plane.
; 'perp_xz': the x-y plane is perpendicular to the magnetic field, while the x axis representing the x projection on the plane.
; 'perp_yz': the x-y plane is perpendicular to the magnetic field, while the x axis representing the y projection on the plane.


   case coord of
      'lmn': begin
         tplot_path=getenv('TPLOT_PATH')+date_str+'/'
         restore,f=file_search(tplot_path+'*'+time_str+'*.sav')
         lmn_evec= fltarr(1,3,3)
         lmn_evec[0,*,*] = transpose(evec)
                                ;originally evec complies: evec[*,0]
                                ;is L, for lmn_evec: lmn_evec[0,0,*]
                                ;is L
         tplot_names,'mms'+sat_str+'_defatt_spinras',names=ndef
         if ~keyword_set(ndef) then begin
            get_timespan,trange
            mms_load_state,trange=trange,probes=sat_str,level = 'def', $
                           datatypes=['spinras', 'spindec'],/no_download 
         endif
         inv_rot='mms'+sat_str+'_dsl_mva_mat_t'
         store_data,'mat_gsm_lmn_t',$
                    data={x:time_double(current_time),y:lmn_evec}
         mms_cotrans_mat,in_name='mat_gsm_lmn_t',out_name=inv_rot,$
                     in_coord='gsm',out_coord='dsl',probe=sat
      end
;      'gse': begin
;         cotrans_mat,'dsl',coord,probe=sat_str,time=current_time,/noload
;         inv_rot='mat_dsl_gse_t'
;      end
      'gsm': begin
         tplot_names,'mms'+sat_str+'_defatt_spinras',names=ndef
         if ~keyword_set(ndef) then begin
            get_timespan,trange
            mms_load_state,trange=trange,probes=sat_str,level = 'def', $
                           datatypes=['spinras', 'spindec'],/no_download 
         endif
         inv_rot='mat_dsl_gsm_t'
         mms_cotrans_mat,out_name=inv_rot,probe=sat,$
                         in_coord='dsl',out_coord='gsm',/identity,$
                         time=current_time
      end
      'dsc': inv_rot=0
      'fac': inv_rot=0
      'gse': inv_rot=0
   endcase


while current_time lt end_time do begin

     if resolution eq 'brst' then precision=3
  clock_time = time_string(format=2,current_time,precision=precision)
  clock_time = strjoin(strsplit(clock_time,'.',/extract),'_')

    if species eq 'i' then begin
      outputfile = outputfolder+'mms'+sat_str+'_'+coord_str+'_'+units+'_'+resolution+'_'+clock_time+'_fpii'+zcut_title+'_'+reduce_str
   endif else begin
       outputfile = outputfolder+'mms'+sat_str+'_'+coord_str+'_'+units+'_'+resolution+'_'+clock_time+'_fpie'+zcut_title+'_'+reduce_str
    endelse     

   if filetype eq 'ps' then begin
    SET_PLOT, 'PS'
    popen,outputfile,/encap,land=(fig_dim[0] gt fig_dim[1])
    !P.charsize=1.2
    ;loadct,39
    ;DEVICE, FILENAME=outputfile+'.ps',/color,bits_per_pixel=8,/Times
 endif
if filetype eq 'png' then begin
   set_plot,'Z'
   device,decomposed=0,set_pixel_depth=24,set_resolution=fig_dim
   ;loadct,39
   !P.background=255
   !P.color=0
   !P.font=1
   !P.charsize=2.5
   device,set_font='Helvetica Bold',/TT_FONT,set_character_size=[6,6]
   erase
endif
if filetype eq 'x' then begin
   set_plot,'x'
   device,decomposed=0
   ;loadct,39
   !P.background=255
   !P.color=0
   window,0,xsize=fig_dim[0],ysize=fig_dim[1]
   !P.font=1
   !P.charsize=2.0
   device,set_font='Helvetica Bold',/TT_FONT,set_character_size=[6,6]
endif
if filetype eq 'win' then begin
   set_plot,'win'
   device,decomposed=0
   ;loadct,39
   !P.background=255
   !P.color=0
   window,1,xsize=fig_dim[0],ysize=fig_dim[1]
   !P.charsize=1.2
   !P.font=-1
endif


if coord ne 'fac' then nob=0 else nob=1
if ~keyword_set(noflip) then begin
  !P.region=[0,0.45,1.0,1.0]
  tlimit,trange_bve
  yline,[v0,v1,v2,v3],linestyle=2
  ;timespan,trange_bve[0],time_double(trange_bve[1])-time_double(trange_bve[0]),/s
 ; evcompare,sat=sat,efield=v0,bfield=v1,ivelocity=v2,evelocity=v3,$
     ;      /fac_vcom,/noinit
  timebar,current_time+0.5*timeinterval
  !P.region=[0,0,0,0]
endif

   for i=0,2 do begin
      noerase=1
      if i eq 2 then begin
         nocolbar=0
         closefile=1 
      endif else begin
         nocolbar=1
         closefile=0
      endelse
      if i eq 1 then notitle=0 else notitle=1
      mms_fpi_slice2d_regbin,sat,current_time,timeinterval,$
                             ;theedata='mms'+sat_str+'_edp_brst_dce2d_xyz_dsl',$
                                ;thebdata='mms'+sat_str+'_dfg_srvy_dmpa_xyz',$
                             vel = 'mms'+sat_str+'_d'+species+'s_brst_bulk_DSC',$
                          species=species,$
                           zrange=zrange,$
                          rotation=rotations[i],$
                          angle=angle,$
                          ThirdDirLim=ThirdDirLim,$
                          filetype=filetype,$
                          outputfile=outputfile,$
                          nosmooth=1,$
                          units=units,$
                          coord=coord,$
                          inv_rot=inv_rot,$
                          vrange=vrange,$
                          noerase=noerase,$
                          closefile=closefile,$
                          position=[x0[i],y0[i],x1[i],y1[i]],$
                          nosun=1,$
                          nob=nob,$
                          zcut=zcut,$
                          novelline = 0,$
                          data_resolution=resolution,$
                          method_reduce=method_reduce,$
                           nocolbar=nocolbar,$
                           notitle=notitle,$
                             numolines = 15
       endfor

   current_time+=increment
;stop
;print, clock_time
print,outputfile
;stop
endwhile

set_plot,mydevice
;loadct2, 41, file='papco.tbl'
!P.background=255
!P.color=0

end
