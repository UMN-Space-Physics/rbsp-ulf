;compile_opt idl2


function spp_swp_spani_thermaltest1_files
src = spp_file_source()
pathnames = 'spp/sweap/prelaunch/gsedata/EM/spanai/201502??_*/PTP_data.dat'
printdat,src
files=file_retrieve(pathnames,_extra=src)
return,files
end




pro poisson_plot,s,index=index
if not keyword_set(s) then s = tsample()
nd = size(/dimen,s)
;avg = average(s,1)
;tot = total(s,1)
par = poisson()

if n_elements(index) eq 0  then index = 2
i=index
s_i = s[*,i]
cs_i = spp_sweap_log_decomp( s_i,/comp)
h = histbins(cs_i,xb,binsize=1)

par.avg = average(s_i)
par.h   = nd[0]
printdat,par
xv=dindgen(10000)
pc =  poisson(xv,param=par) 
printdat,pc
cxv = spp_sweap_log_decomp( xv,/comp)

cpc = average_hist(pc,cxv,xbins=ccxv,binsize=1,/ret_total)

plot,xb,h, psym=4,xrange=minmax([ccxv,cxv,xb]),yrange=minmax([pc,h,cpc])
oplot,xb,h,psym=10


;oplot,xv,pc,color=6,psym=10
oplot,ccxv,cpc,color=6,psym=10
end



pro print_rates,t
if ~keyword_set(t) then ctime,t,npoint=2,/silent

valids=tsample('spp_spanai_rates_VALID_CNTS',t,/average)
multis=tsample('spp_spanai_rates_MULTI_CNTS',t,/average)
ostarts=tsample('spp_spanai_rates_START_CNTS',t,/average)
ostops =tsample('spp_spanai_rates_STOP_CNTS',t,/average)

print,findgen(16)
print
print,valids
print,multis
print,ostarts
print,ostops

starts = ostarts+valids
stops = ostops+valids
print
print,valids/starts
print,valids/stops
end




pro spp_tof_histogram,trange=trange,xrange=xrange,ylog=ylog,binsize=binsize,noerase=noerase,channels=channels,xlog=xlog
if ~keyword_set(trange) then ctime,trange,npoints=2

csize = 2
spp_apid_data,'3B9'x,apdata=ap
;print_struct,ap
events = *ap.dataptr
if not keyword_set(tragne) then ctime,trange

if keyword_set(trange) then begin
  w = where(events.time ge trange[0] and events.time le trange[1],nw)
  if nw ne 0 then events = events[w] else dprint,'No points selected - using all'
endif

col = bytescale(indgen(16))
nc = n_elements(col)
;if ~keyword_set(xrange) then xrange=[450,600]
if ~keyword_set(binsize) then binsize = 1
h = histbins(events.tof,xb,binsize=binsize,shift=0,/extend_range)

if keyword_set(ylog) then begin
  mx = max(h)
  yrange = [mx/10^(ylog+3),mx]
  yrange  = [.5,mx*2]
endif

if keyword_set(xlog) then begin
  xrange = minmax(/pos,xb) > 10
endif


plot,/nodata,xb,h * 1.1,xrange=xrange,charsize=csize,yrange=yrange,ylog=ylog,ystyle=3,noerase=noerase,xtitle='Time of Flight channel',ytitle='Counts',xlog=xlog
mxt = max(h)

if ~keyword_set(channels) then channels = reverse(indgen(16))

for i=0,n_elements(channels)-1 do begin
  ch = channels[i]
  c=col[ch mod nc]
  w = where(events.channel eq ch, nw)
  if nw eq 0 then continue
  h = histbins(events[w].tof,xb,binsize=binsize,shift=0)
  oplot,xb,h,color=c,psym=10
  oplot,xb,h,color=c,psym=1
  mx = max(h,b)
  xyouts,xb[b],h[b]+mxt*.03,strtrim(ch,2),color=c,align=.5,charsize=2
  if keyword_set(dt)  then begin
     
 ;   dt = findgen(44)+7

    pks = find_peaks( [replicate(0,round(xb[0])),h],roiw=5 )    
    
    plot,dt,pks.x0,/psym,yrange=[-100,500],xrange=[0,55],/ystyle,/xstyle,xtitle='Delay (ns)',ytitle='TOF value',title='Fit to response'
    par = polycurve()
    fit,dt[1:*],pks[1:*].x0,param=par,names='a0 a1'
    oplot,dt,(pks.x0-func(dt,param=pc)) * 10,psym=4,color=6
    oplot,xv,func(xv,param=pc)
    xv=dgen()
    oplot,xv,func(xv,param=pc)
    oplot,[0,60],[0,0],color=5,linestyle=2
    oplot,[0,60],[0,0],color=2,linestyle=2

    
  endif
endfor


end


pro spp_set_tplot_options,spec=spec

clog = keyword_set(spec)
crange = [.9,5000.]
  if keyword_set(spec) then begin
    ylim,'*rate*CNTS',-1,16,0
    options,'*rates*CNTS',spec=1,ystyle=3,symsize=.5,zrange=crange
;    options,'*rates*CNTS_t',labels='CH'+strtrim(indgen(16),2),labflag=-1,yrange=[.01,100],/ylog,ystyle=3,psym=-1,symsize=.5
  endif else begin
 ;   ylim,'*rate*CNTS',1,1,1
    options,'*rates*CNTS',spec=0,yrange=crange,ylog=1,ystyle=3,psym=-1,symsize=.5
;    options,'*rates*CNTS_t',labels='CH'+strtrim(indgen(16),2),labflag=-1,yrange=[.01,100],/ylog,ystyle=3,psym=-1,symsize=.5
    
  endelse
  options,'*events*',psym=3,ystyle=3
  store_data,'log_MSG',dlimit=struct(tplot_routine='strplot')
  options,'*MON*',/ynozero
  tplot_options,'local_time',1
  tplot_options,'xtitle','Pacific Time'
  store_data,'STOP_SPEC',data='spp_spanai_rates_STOP_CNTS',dlimit=struct(spec=1,yrange=[-1,16],zrange=[.5,500],/zlog,ylog=0,/no_interp)
  store_data,'START_SPEC',data='spp_spanai_rates_START_CNTS',dlimit=struct(spec=1,yrange=[-1,16],zrange=[.5,500],/zlog,ylog=0,/no_interp)

 ; tplot,' *CMD_REC *rate*CNTS *ACC *MCP *events* log_MSG'
  
  if 0 then begin
    options,'spp_spane_spec_CNTS',spec=0,yrange=[1,1000],ylog=1,colors='mbcgdr'
  endif else begin
    options,'spp_spane_spec_CNTS',spec=1,yrange=[0,17],ylog=0,zrange=[1,500.],zlog=1
  endelse
  
  


end


pro spp_init_realtime,filename=filename,base=base
common spp_crib_com2, recorder_base,exec_base
exec,exec_base,exec_text = 'tplot,verbose=0,trange=systime(1)+[-1,.05]*300'

host = 'localhost'
host = '128.32.98.101'
host = 'ABIAD-SW'
recorder,recorder_base,title='GSEOS PTP',port=2024,host=host,exec_proc='spp_ptp_stream_read',destination='spp_raw_YYYYMMDD_hhmmss.ptp';,/set_proc,/set_connect,get_filename=filename
printdat,recorder_base,filename,exec_base,/value

spp_swp_apid_data_init,save=1
spp_apid_data,'3b9'x,name='SWEAP SPAN-I Events',rt_tags='*'
spp_apid_data,'3bb'x,name='SWEAP SPAN-I Rates',rt_tags='*CNTS'
spp_apid_data,'3be'x,name='SWEAP SPAN-I HKP',rt_tags='*'
spp_apid_data, rt_flag = 1
spp_swp_manip_init

wait,1

spp_set_tplot_options

spp_apid_data,apdata=ap
print_struct,ap

if 0 then begin
  f1= file_search('spp*.ptp')
  spp_apid_data,rt_flag=0
  spp_ptp_file_read,f1[-1]
  spp_apid_data,rt_flag=1
endif
base = recorder_base
end


pro spp_message_to_value

  spp_apid_data,'7C0'x,apdata=ap
  print_struct,ap
  dat = *ap.dataptr
  w = where( strmid(dat.msg,0,4) eq 'set ')
 


end



pro spp_swp_reduce,tof_range=tof_range,tof_name=tof_name

res =5.

if 0 then begin
  reduce_timeres_data,'spp_spanai_rates_*CNTS',res ;,trange=tr
  get_data,'spp_spanai_rates_VALID_CNTS_t',data=d1
  get_data,'spp_spanai_rates_START_CNTS_t',data=d3
  get_data,'spp_spanai_rates_STOP_CNTS_t',data=d4
  dr =d1
  dr.y = d1.y/(d1.y+d3.y)
  store_data,'valid_start',data=dr
  dr.y = d1.y/(d1.y+d4.y)
  store_data,'valid_stop',data=dr
  dr.y = (d1.y+d3.y)/(d1.y+d4.y)
  store_data,'start_stop',data=dr
  dr.y = (d1.y+d4.y)/(d1.y+d3.y)
  store_data,'stop_start',data=dr
endif

if 1 then begin
  spp_apid_data,'3b9'x,apdata=ap
  a = *ap.dataptr
  for ch = 0 ,15 do begin   
    test = a.channel eq ch
    if n_elements(tof_range) eq 2 then test = test and (a.tof le tof_range[1] and a.tof ge tof_range[0])
    w = where(test,nw)
    colors = bytescale(findgen(16))
    ;dl = {psym:3, colors=0}
    name =string(ch,format='("spanai_ch",i02,"_")')
    if keyword_set(tof_name) then name += tof_name+'_'
    if nw ne 0 then store_data,name,data=a[w],tagnames='*',dlim={TOF:{psym:3,symsize:.4,colors:colors[ch] }}
    h=histbins(a[w].time,tb,binsize=double(res))
    store_data,name+'TOT',tb,h,dlim={colors:colors[ch]}
  endfor
  store_data,'spanai_all_TOT',data='spanai_ch??_TOT'

endif


end




if 0 then begin

  if 0 then begin
    src = file_retrieve(/str)
    src.remote_data_dir='http://sprg.ssl.berkeley.edu/data/
    url_index = 'http://sprg.ssl.berkeley.edu/data/spp/sweap/prelaunch/gsedata/EM/spanai/'
    pathindex = strmid(url_index,strlen(src.remote_data_dir))
    indexfile = file_retrieve(_extra=src,pathindex)+'/.remote-index.html'
 ;   links = file_extract_html_links(indexfile,count,verbose=verbose,no_parent=url_index)  ; Links with '*' or '?' or leading '/' are removed.
    fileformat = 'spp/sweap/prelaunch/gsedata/EM/spanai/'+links[-1]+'PTP_data.dat'
  endif

  src = file_retrieve(/str)
  src.remote_data_dir='http://sprg.ssl.berkeley.edu/data/
  fileformat = 'spp/sweap/prelaunch/gsedata/EM/spanai/2015*/PTP_data.dat'
  files = file_retrieve(_extra=src,fileformat,last_version=1)
  spp_ptp_file_read,files

  
  
  spp_init_realtime,filename=rtfile
  spp_ptp_file_read,rtfile
  

  spp_ptp_file_read,file[-1]
  spp_apid_data,rt_flag=1
  
;  del_data,'*'
;  f= file_search('~/Downloads/PTP*.dat')
;  f1= file_search('spp*.ptp')
;  f2=file_search('/disks/data/spp/sweap/','*PTP*')
;  files = [F2[-1],f1[-1]]
;  files = [file,f1[-1]]
  
  store_data,'*',/clear

  spp_ptp_file_read,files

  spp_apid_data,rt_flag=1,/finish


  spp_apid_data,apdata=ap
  print_struct,ap  
  
spp_tof_histogram,/ylog  ;,trange,xrange=xrange

spp_swp_reduce

gunvoltage =[0,10.3,50.3,100.4,500.3,1000.3,2000.1,3000.1,4000.1]
gunsupplycurrent = [.0013,.0015,.0024,.0033,.0115,.0216,.0418,.0619,.0820]
plot,gunvoltage,gunsupplycurrent

endif


end


