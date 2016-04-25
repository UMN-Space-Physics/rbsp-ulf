;+
;Procedure: WI_3DP_LOAD
;
;Purpose:  Loads WIND 3DP data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   VERBOSE : To change verbosity
;Examples:
;   wi_3dp_load,'k0'
;   wi_3dp_load,'pm'
;   wi_3dp_load,'elpd'
;   wi_3dp_load,'elm2'
;   wi_3dp_load,'sfpd'
;   wi_3dp_load,'sfsp'
;   wi_3dp_load,'phsp'
;   wi_3dp_load,'sosp'
;   wi_3dp_load,'sopd'
;
;Notes:
; Author: Davin Larson
;
; $LastChangedBy: davin-win $
; $LastChangedDate: 2011-02-11 16:01:27 -0800 (Fri, 11 Feb 2011) $
; $LastChangedRevision: 8201 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/wi_3dp_load.pro $
;-
pro wi_3dp_load,type,files=files,trange=trange,verbose=verbose,downloadonly=downloadonly, $
      varformat=varformat,datatype=datatype, $
      version=version, $
      addmaster=addmaster,tplotnames=tn,source=source

if keyword_set(type) then datatype=type
if not keyword_set(datatype) then datatype = 'k0'

wind_init
if not keyword_set(source) then source = !wind
    masterfile=''

case datatype of
  'k0':  begin
    pathformat = 'wind/3dp/k0/YYYY/wi_k0_3dp_YYYYMMDD_v??.cdf'
    if not keyword_set(varformat) then  varformat = 'ion_density ion_vel ion_temp'
    if not keyword_set(prefix) then prefix = 'wi_3dp_k0_'
  end

  'pm': begin
    pathformat = 'wind/3dp/pm/YYYY/wi_pm_3dp_YYYYMMDD_v03.cdf'
    if not keyword_set(varformat) then varformat = '?_* TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_pm_'
  end

  'elpd_old': begin
    pathformat = 'wind/3dp/elpd/YYYY/wi_elpd_3dp_YYYYMMDD_v0?.cdf'
    if not keyword_set(varformat) then varformat = 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_elpd_'
    addmaster=1
  end

  'elpd': begin
    if not keyword_set(version) then version ='v06'
    pathformat = 'wind/3dp/elpd2/YYYY/wi_3dp_elpd_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_elpd_'
    fix_elpd_flux = 1
;    addmaster=1
  end

  'elsp': begin
    if not keyword_set(version) then version ='v01'
    pathformat = 'wind/3dp/elsp/YYYY/wi_elsp_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_elsp_'
;    fix_elpd_flux = 1
;    addmaster=1
  end

  'elm2': begin
    if not keyword_set(version) then version ='v02'
    pathformat = 'wind/3dp/elm2/YYYY/wi_elm2_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_elm2_'
;    fix_elpd_flux = 1
;    addmaster=1
  end

  'sfpd': begin
    pathformat = 'wind/3dp/sfpd/YYYY/wi_sfpd_3dp_YYYYMMDD_v0?.cdf'
    if not keyword_set(varformat) then varformat = '*'  ; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sfpd_'
;    addmaster=0
  end

  'sfsp': begin
    pathformat = 'wind/3dp/sfsp/YYYY/wi_sfsp_3dp_YYYYMMDD_v0?.cdf'
    if not keyword_set(varformat) then varformat = '*'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sfsp_'
;    addmaster=0
  end

  'plsp': begin
    pathformat = 'wind/3dp/plsp/YYYY/wi_plsp_3dp_YYYYMMDD_v02.cdf'
    if not keyword_set(varformat) then varformat = '*'
    if not keyword_set(prefix) then prefix = 'wi_3dp_plsp_'
    fix_sosp_flux =1
  addmaster=0
  end

  'phsp': begin
    pathformat = 'wind/3dp/phsp/YYYY/wi_phsp_3dp_YYYYMMDD_v01.cdf'
    if not keyword_set(varformat) then varformat = '*'
    if not keyword_set(prefix) then prefix = 'wi_3dp_phsp_'
   ; fix_sosp_flux =1
  addmaster=0
  end

  'sosp': begin
    pathformat = 'wind/3dp/sosp/YYYY/wi_sosp_3dp_YYYYMMDD_v01.cdf'
    if not keyword_set(varformat) then varformat = '*'  ; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sosp_'
    fix_sosp_flux =1
  addmaster=0
  end

  'sosp2': begin
    pathformat = 'wind/3dp/sosp/YYYY/wi_3dp_sosp_YYYYMMDD_v02.cdf'
    if not keyword_set(varformat) then varformat = '*'  ; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sosp2_'
    fix_sosp_flux =1
;    addmaster=0
  end

  'sopd': begin
    pathformat = 'wind/3dp/sopd/YYYY/wi_sopd_3dp_YYYYMMDD_v02.cdf'
    if not keyword_set(varformat) then varformat = '*'  ; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sopd_'
    fix_sopd_flux =1
;    addmaster=0
  end

endcase

relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)

files = file_retrieve(relpathnames, _extra=source,/last_version)
if keyword_set(masterfile) then files= [masterfile,files]

if keyword_set(downloadonly) then return

cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn    ; load data into tplot variables

; Set options for specific variables

if keyword_set(fix_elpd_flux) or keyword_set(fix_sopd_flux) then begin   ;  perform cluge because CDF file attributes are not set for these files
   get_data,prefix+'FLUX',ptr=p_flux
   get_data,prefix+'PANGLE',ptr=p_pangles
   get_data,prefix+'ENERGY',ptr=p_energy
   str_element,/add,p_flux,'V1',p_energy.y
   str_element,/add,p_flux,'V2',p_pangles.y
   store_data,prefix+'FLUX',data = p_flux
endif


if keyword_set(fix_sosp_flux) then begin
  ;  printdat,tn
   get_data,prefix+'FLUX',ptr=p_flux
   get_data,prefix+'ENERGY',ptr=p_energy
   str_element,/add,p_flux,'V',p_energy.y
   store_data,prefix+'FLUX',data = p_flux

endif



if datatype eq 'elpd' then begin
   reduce_pads,'wi_3dp_elpd_FLUX',1,4,4
   reduce_pads,'wi_3dp_elpd_FLUX',2,0,0
   reduce_pads,'wi_3dp_elpd_FLUX',2,12,12
endif

options,/def,strfilter(tn,'wi_3dp_ion_vel',delim=' ') , colors='bgr', labels=['Vx','Vy','Vz']   ; set colors for the vector quantities
;options,/def,strfilter(tn,'wi_mfi_BGSEc') , ytitle = 'WIND!CB (nT)'

dprint,dlevel=3,'tplotnames: ',tn


end
