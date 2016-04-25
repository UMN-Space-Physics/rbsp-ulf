Pro spec_crib
mms_init
;tplot_restore,f='/Applications/itt/idl/idl80/data/dis_des_0815_130347_130400.tplot'
sat=3
sat_str=string(sat,format='(I1)')
specie='e' ;'i' or 'e'

t_string = '2015-09-19/09:10'
timespan,t_string, 2, /min


;timespan,'2015-08-15/13:03:47',13,/s ;set up time
;timespan,'2015-09-19/09:10:00',2,/min ;set up time

;load magnetic field and Skymap data

reload3d=1
reloadpa=1 
;for the first time of using fpi_en_spec_crib or fpi_pa_spec_crib
;after loading Skymap and setting up the time interval, reload3d and
;reloadpa should be set as 1

;To create energy spectrogram for [0,12] pitch angle (minimum pa range
;required is 6 degrees)
pa_range=[0,12]
units_name='EFLUX' ;units: 'DF','EFLUX' or 'DIFF FLUX'
fpi_en_spec_crib,sat=sat,specie=specie,units_name=units_name,pa_range=pa_range,$
                 reload3d=reload3d,reloadpa=reloadpa

;To create energy spectrogram for [168,180] pitch angle
pa_range=[168,180]
units_name='EFLUX' ;units: 'DF','EFLUX' or 'DIFF FLUX'
fpi_en_spec_crib,sat=sat,specie=specie,units_name=units_name,pa_range=pa_range

;plot
outpath='/Users/jburch/'
file_mkdir,outpath
filename='para_antipara_d'+specie+'s_eflux_0815_130347_130400'
mydevice=!D.name
myfont=!P.font
mycharsize=!P.charsize
if  StrUpCase(!version.os_family) eq 'WINDOWS' then begin
   set_plot,'win'
endif else begin
   set_plot,'x'
endelse
device,decomposed=0,retain=2
!P.color=0
!P.background=255
!P.font=1
device,set_font='Helvetica Bold',/TT_FONT,set_character_size=[6,7]
!P.charsize=2.0

window,0
tplot,'mms'+sat_str+'_'+strupcase(units_name)+'_d'+specie+'s_pa_'+$
      ['0_12','168_180']
write_png,outpath+filename+'.png',tvrd(/true)
print,'output to file: ',outpath+filename+'.png'

set_plot,mydevice
!P.color=0
!P.background=255
!P.charsize=mycharsize
!P.font=myfont

END
