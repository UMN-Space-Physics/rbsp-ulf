pro istp_fa_k0_load,types,trange=trange,verbose=verbose

istp_init
source = !istp
;local_dir = root_data_dir() + 'fast/' ; '/data/fast/
;remote_dir = 'http://cdaweb.gsfc.nasa.gov/data/fast/'

mstr_source = source
;mstr_source.remote_data_dir +=  'OLD_MASTERS/'
;mstr_source.local_data_dir  +=   'OLD_MASTERS/'
addmaster = 0

if not keyword_set(types) then types = ['ees','ies']

for i=0,n_elements(types)-1 do begin
     type = types[i]
;     relpath = 'fast/'+type+'/'
;     prefix = 'fa_k0_'+type+'_'
;     ending = '_v0?.cdf'
;     relpathnames = file_dailynames(relpath,prefix,ending,/YEARDIR,trange=trange)
     version = 'v0?'
     
     ;URLs changed due to SPDF reorg
     ;file_format = 'fast/'+type+'/YYYY/fa_k0_'+type+'_YYYYMMDD_'+version+'.cdf'
     ;New URL 2012/10 pcruce@igpp
      file_format = 'fast/'+type+'/'+type+'_k0/YYYY/fa_k0_'+type+'_YYYYMMDD_'+version+'.cdf'
     relpathnames = file_dailynames(file_format=file_format,trange=trange)

     ;No longer can load master files from SPDF after reorg
     ;mfile = file_retrieve(_extra = mstr_source, 'fa_k0_'+type+'_00000000_v01.cdf' )
     files = file_retrieve(relpathnames,_extra=source)
     if keyword_set(downloadonly) then continue
     cdf2tplot,file=[files],all=all,verbose=verbose ,prefix = 'istp_fa_'    ; load data into tplot variables
endfor


end
