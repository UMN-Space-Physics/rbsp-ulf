;+
;PROCEDURE:   swe_plot_fhsk
;PURPOSE:
;  Plots SWEA fast housekeeping data (A6).
;
;USAGE:
;  swe_plot_fhsk
;
;INPUTS:
;
;KEYWORDS:
;
;CREATED BY:    David L. Mitchell  07-24-12
;FILE: swe_plot_fhsk.pro
;VERSION:   1.0
;LAST MODIFICATION:   03/23/13
;-
pro swe_plot_fhsk

  @mvn_swe_com
  
  Twin = !d.window
  tplot_options,get=opt
  
  if (size(a6,/type) ne 8) then begin
    print,"No fast housekeeping data."
    return
  endif
  
  npkt = n_elements(a6)
  
  for i=0,(npkt-1) do begin
    window,/free
    
    dt = min(abs(swe_hsk.time - a6[i].time),j)
    chksum = swe_hsk[j].chksum[swe_hsk[j].ssctl]
    tabnum = mvn_swe_tabnum(chksum)
    title = time_string(a6[i].time) + $
            string([tabnum,chksum],format='(4x,"Table Number: ",i1,4x,"Checksum: ",Z2.2)')

    t = a6[i].time + (1.95D/224D)*dindgen(224)
  
    store_data,'a6_analv',data={x:t, y:a6[i].analv}
    store_data,'a6_def1v',data={x:t, y:a6[i].def1v}
    store_data,'a6_def2v',data={x:t, y:a6[i].def2v}
    store_data,'a6_v0v',data={x:t, y:a6[i].v0v}
  
    options,'a6_analv','ytitle','ANALV'
    options,'a6_def1v','ytitle','DEF1V'
    options,'a6_def2v','ytitle','DEF2V'
    options,'a6_v0v','ytitle','V0V'
  
    options,'a6_analv','psym',10
    options,'a6_def1v','psym',10
    options,'a6_def2v','psym',10
    options,'a6_v0v','psym',10
  
    pans = ['a6_analv','a6_def1v','a6_def2v','a6_v0v']
    tplot_options,'title',title
    tplot,pans,trange=[min(t),max(t)]
  endfor
  
  wset, Twin
  tplot_options,opt=opt
  tplot_options,'title',''
  
  return

end
