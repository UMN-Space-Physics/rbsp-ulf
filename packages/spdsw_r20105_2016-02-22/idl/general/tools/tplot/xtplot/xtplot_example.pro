; This is an example program to be called from 
; the "Auto Command" feature (in the "Options" menu)
;
PRO xtplot_example
@xtplot_com
  pA = xtplot_pcsrA
  pB = xtplot_pcsrB
  
  print, xtplot_pcsrA, xtplot_pcsrB
  print, xtplot_vnameA
  print, xtplot_vnameB
  if strmatch(xtplot_vnameA, xtplot_vnameB) then begin
    get_data, xtplot_vnameA, data=D
    sum = total(D.y[pA:pB])
    print, '***************************************'
    print, 'sum of the data between the two cursors are: ', sum
    print, '***************************************'
  endif
END
