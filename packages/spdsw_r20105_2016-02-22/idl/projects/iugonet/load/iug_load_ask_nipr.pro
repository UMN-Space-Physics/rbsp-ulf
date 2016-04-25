;+
;PROCEDURE: IUG_LOAD_ASK_NIPR,
;  iug_load_ask_nipr, site = site, trange = trange, 
;                     verbose = verbose, downloadonly = downloadonly
;
;PURPOSE:
;  Loads keogram data obtained with AWI by NIPR.
;
;KEYWORDS:
;  site  = Observatory name.  For example, iug_load_ask_nipr, site = 'tro'.
;          Available sites: 'tro', 'lyr'
;          The default is 'all', i.e., load all available stations.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /verbose, if set, then output some useful info
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
;EXAMPLE:
;  iug_load_ask_nipr, site = 'tro'
;
; Written by: Y.-M. Tanaka, Feb. 20, 2012 (ytanaka at nipr.ac.jp)
;-


PRO read_ask_ascii_nipr, filename, tvec, keodata

;--- Read ascii data ---;
ndata=86400L
keodata=dblarr(ndata, 60)
tvec=dblarr(ndata)
tstr = {time_structr,year:0,month:0,date:0,hour:0,min:0,sec:0, $
        fsec:0, daynum:0l,doy:0,dow:0,sod:!values.d_nan, $
        dst:0,tzone:0,tdiff:0}
dumm=' '
yyyymmdd=0L
hhmmss=0L
keo=fltarr(60)

openr, lun, filename, /get_lun

;--- Skip the first 2 lines ---;
readf, lun, dumm
readf, lun, dumm

i=0L
while(not EOF(lun)) do begin
   readf, lun, yyyymmdd, hhmmss, keo
;   readf, lun, hhmmss
;   readf, lun, keo

   tstr.year=fix(yyyymmdd/10000.)
   tstr.month=fix((yyyymmdd-tstr.year*10000L)/100.)
   tstr.date=fix(yyyymmdd-tstr.year*10000L-tstr.month*100L)
   tstr.hour=fix(hhmmss/10000.)
   tstr.min=fix((hhmmss-tstr.hour*10000L)/100.)
   tstr.sec=fix(hhmmss-tstr.hour*10000L-tstr.min*100L)

;   print, tstr.year, tstr.month, tstr.date, tstr.hour, tstr.min, tstr.sec

   tvec[i]=time_double(tstr)
   keodata[i, *]=double(keo)

   i++
endwhile

free_lun, lun

tvec=tvec[0:i-1]
keodata=reverse(keodata[0:i-1, *], 2)

END


;************************************************************
;***** Load procedure for keogram data obtained by NIPR *****
;************************************************************
pro iug_load_ask_nipr, site = site, downloadonly=downloadonly

; keyword
if ~keyword_set(verbose) then verbose=0

; list of sites
vsnames = 'tro lyr'
vsnames_all = strsplit(vsnames, ' ', /extract)

; validate sites
if(keyword_set(site)) then site_in = site else site_in = 'all'
sites = ssl_check_valid_name(site_in, vsnames_all, $
                             /ignore_case, /include_all)
if sites[0] eq '' then return

; number of valid sites
nsites = n_elements(sites)

; acknowlegment string (use for creating tplot vars)
acknowledgstring = 'The optical data are the intellectual property of National '$
  + 'Institute of Polar Research, JAPAN. They may be freely used for the purpose '$
  + 'of illustration for teaching and for non-commercial scientific research, '$
  + 'provided that the source is acknowledged. Substantial use of the data should '$
  + 'be discussed at an early stage with the PI of each instrument. NIPR receachers '$
  + 'are hoping collaborative studies and fluitful scientific outputs using these '$
  + 'data. The distribution of the optical data from NIPR has been partly '$
  + 'supported by the IUGONET (Inter-university Upper atmosphere Global Observation '$
  + 'NETwork) project (http://www.iugonet.org/) funded by the Ministry of Education, '$
  + 'Culture, Sports, Science and Technology (MEXT), Japan.'

instr='ask'

;=================================
;=== Loop on downloading files ===
;=================================
for i=0, nsites-1 do begin
  ; define file names
  pathformat= sites[i] + '/awi/ascii/YYYYMM/' + $
              sites[i] + '_awi_YYYYMMDD_hh.txt'
  relpathnames = file_dailynames(file_format=pathformat, trange=trange, /hour_res)

  ; define remote and local path information
  source = file_retrieve(/struct)
  source.verbose = verbose
  source.local_data_dir = root_data_dir() + 'iugonet/nipr/'+instr+'/'
  source.remote_data_dir = 'http://pc115.seg20.nipr.ac.jp/www/optical/watec/'

  ; download data
  local_files = file_retrieve(relpathnames, _extra=source)

  ; if downloadonly set, go to the top of this loop
  if keyword_set(downloadonly) then continue

  ;===================================
  ;=== Loop on reading data files ===
  ;===================================
  for j=0,n_elements(local_files)-1 do begin
    file = local_files[j]

    if file_test(/regular,file) then begin
      dprint,'Loading data file: ', file
      fexist = 1
    endif else begin
      dprint,'Data file ',file,' not found. Skipping'
      continue
    endelse

    ; read ascii file
    read_ask_ascii_nipr, file, tvec, keodata
;    keodata=transpose(keodata)
    
    ; append data and time index
    append_array, databuf, keodata
    append_array, timebuf, tvec
  endfor
 
  ;=======================================
  ;=== Loop on creating tplot variable ===
  ;=======================================
  if size(databuf,/type) eq 5 then begin
    print_str_maxlet, acknowledgstring

    ; tplot variable name
    tplot_name = 'iug_ask_' + strlowcase(sites[i])
  
    ; for bad data
    wbad = where(finite(databuf) eq -99, nbad)
    if nbad gt 0 then databuf[wbad] = !values.f_nan

    ; default limit structure
    dlimit=create_struct('data_att',create_struct('acknowledgment', acknowledgstring))

    ; store data to tplot variable
    case sites[i] of
      'tro' : begin
	vdata=-70.+findgen(60)*2.4
      end
      'lyr' : begin
        vdata=-65.+findgen(60)*2.4
      end
    endcase
 
    store_data, tplot_name, data={x:timebuf, y:databuf, v:vdata}, dlimit=dlimit

    ; add options
    options, tplot_name, ytitle = sites[i]+'!CN-S Keogram', ysubtitle='[deg]', $
	spec=1, ztitle = '[Counts]'
    case sites[i] of 
      'tro' : begin
        ylim, tplot_name, -90, 90, 0
      end 
      'lyr' : begin
        ylim, tplot_name, -90, 90, 0
      end
    endcase

  endif

  ; clear data and time buffer
  databuf = 0
  timebuf = 0

; go to next site
endfor

end
