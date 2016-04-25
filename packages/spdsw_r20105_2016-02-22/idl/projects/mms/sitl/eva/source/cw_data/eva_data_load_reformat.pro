FUNCTION eva_data_load_reformat, paramlist, probelist, FOURTH=fourth
  compile_opt idl2
  
  imax = n_elements(paramlist)
  spcidloc = 2
  if keyword_set(fourth) then spcidloc = 3
  
  for i=0,imax-1 do begin; for each parameter
    slen = strlen(paramlist[i])
    paramlist0 = paramlist[i]
    
    third = strlowcase(strmid(paramlist0,spcidloc,1))

    ; check suffix
    lencmb = 0
;    pos = strpos(paramlist[i],'cmb')  & if pos eq slen-3 then lencmb = 3
;    pos = strpos(paramlist[i],'comb') & if pos eq slen-4 then lencmb = 4
    sdif = slen-lencmb-2
    match  = (strpos(paramlist[i],'_m') eq sdif)
    match += (strpos(paramlist[i],'_x') ge sdif)
    match += (strpos(paramlist[i],'_y') ge sdif)
    match += (strpos(paramlist[i],'_z') ge sdif)
    match += (strpos(paramlist[i],'_p') ge sdif)
    match += (strpos(paramlist[i],'_t') ge sdif)

    if match then begin
      paramlist0 = strmid(paramlist[i],0,slen-lencmb-2); paramlist[i] without suffix

      ; expand probelist
      if strmatch(third,'*') or strmatch(third,'w') then begin ; "*" or "w" --> expand probes
        plist = probelist
      endif else begin
        plist = strarr(1)
        plist[0] = strmid(paramlist0,0,spcidloc+1)
      endelse
      qmax = n_elements(plist)
      
      ; extract a component from each probe
      sfx = ''
      for q=0,qmax-1 do begin; for each probe
        tn = plist[q] + strmid(paramlist0,spcidloc+1,100)
        tname = tnames(tn,c)
        if c eq 0 then begin
          print, 'EVA: ERROR: '+tn+' is not loaded (eva_data_load_reformat)'
          return, 'No'
        endif
        get_data, tname, data=DD, lim=lim, dl=dl
        tgn = tag_names(lim)
        idx = where(tgn eq 'lim',ct)
        newlabel = ''
        ysubtitle = ''
        if size(DD.y,/n_dim) eq 2 then begin
          if strpos(paramlist[i],'_m') ge 0 then begin
            sfx = '_m'
            pcolor = 0
            ysubtitle = '(magnitude)'
            Dnew = sqrt(DD.y[*,0]^2+DD.y[*,1]^2+DD.y[*,2]^2)
            newlabel = ' '
          endif
          if strpos(paramlist[i],'_x') ge 0 then begin
            sfx = '_x'
            pcolor = 2
            Dnew = DD.y[*,0]
            newlabel = lim.labels[0]
          endif
          if strpos(paramlist[i],'_y') ge 0 then begin
            sfx = '_y'
            pcolor = 4
            Dnew = DD.y[*,1]
            newlabel = lim.labels[1]
          endif
          if strpos(paramlist[i],'_z') ge 0 then begin
            sfx = '_z'
            pcolor = 6
            Dnew = DD.y[*,2]
            newlabel = lim.labels[2]
          endif
          ;if ct eq 1 then begin
            if strlen(newlabel) gt 0 then str_element,lim,'labels',newlabel,/add
            str_element,lim,'colors',[pcolor],/add
            if strlen(ysubtitle) gt 0 then str_element,lim,'ysubtitle',ysubtitle,/add
            ;str_element,lim,'labels',/delete
          ;endif
          store_data, tname+sfx, data={x:DD.x,y:Dnew},lim=lim,dl=dl
        endif; if size(DD.y
      endfor; for each probe
    endif ; if match (i.e. sfx found)

    ; combine the same component data from all probes
    if strmatch(third,'w') then begin
      sfx = match ? sfx : ''
      colors = intarr(qmax)
      labels = strarr(qmax)
      for q=0,qmax-1 do begin; for each probe
        case strmid(plist[q],spcidloc,1) of
          'a': pcolor = 1; purple
          'b': pcolor = 6; red
          'c': pcolor = 4; green
          'd': pcolor = 3; light-blue
          'e': pcolor = 2; blue
          '1': pcolor = 0; black
          '2': pcolor = 2; blue
          '3': pcolor = 4; green
          '4': pcolor = 6; red
          else: pcolor = 0
        endcase
        colors[q] = pcolor
        labels[q] = plist[q]
      endfor
      dl = {colors:colors, labels:labels, labflag:1}

      store_data, paramlist0+sfx, data=plist+strmid(paramlist0,spcidloc+1,100)+sfx,dl=dl
    endif
  endfor; for each parameter
  return, 'Yes'
END
