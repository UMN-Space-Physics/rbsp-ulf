function units_string_fpi,units,reduce=reduce,onlyunit=onlyunit

if ~keyword_set(onlyunit) then begin
case strlowcase(units) of

'counts' : ustr = 'Counts'
'rate'   : ustr = 'Rate (Counts/sec)'
'eflux'  : ustr = 'Energy Flux (eV/s/cm!U2!N /str/eV)'
'flux'   :  ustr = 'Flux (#/s/cm!U2!N/str/ eV)'
'df'     :  begin
  if keyword_set(reduce) then begin
    ustr = 'f (s!U2!N/cm!U5!N)'
  endif else begin
      ustr = 'f (s!U3!N/cm!U6!N)'
  endelse
  end
'psd'     :  ustr = 'f (s!U3!N/cm!U6!N)'
'e2flux' : ustr = 'Energy^2 Flux (eV^2 / sec / cm^2 / ster /ev)'
'e3flux' : ustr = 'Energy^3 Flux (eV^3 / sec / cm^2 / ster /ev)'
else:     ustr = 'Unknown'
endcase
endif else begin
case strlowcase(units) of

'counts' : ustr = 'Counts'
'rate'   : ustr = 'Counts/sec'
'eflux'  : ustr = 'eV/s/cm!U2!N/str/eV'
'flux'   :  ustr = '#/s/cm!U2!N/str/eV'
'df'     :  begin
  if keyword_set(reduce) then begin
    ustr = 's!U2!N/cm!U5!N'
  endif else begin
      ustr = 's!U3!N/cm!U6!N'
  endelse
  end
'psd'     :  ustr = 's!U3!N/cm!U6!N'
'e2flux' : ustr = 'Energy^2 Flux (eV^2 / sec / cm^2 / ster /ev)'
'e3flux' : ustr = 'Energy^3 Flux (eV^3 / sec / cm^2 / ster /ev)'
else:     ustr = 'Unknown'
endcase
endelse


return,ustr
end
