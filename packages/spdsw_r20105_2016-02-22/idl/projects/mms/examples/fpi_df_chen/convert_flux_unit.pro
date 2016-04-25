Pro convert_flux_unit,specie=specie,energy=energy,flux=flux,$
                      from_unit=from_unit,to_unit=to_unit,$
                      new_flux = new_flux

;print,'******Unit requirements:********'
;print,'energy: eV'
;print,'EFLUX eV/cm^2/s/sr/eV or keV/cm^2/s/sr/keV'
;print,'DIFF FLUX #/cm^2/s/sr/keV'
;print,'PSD or DF s^3/km^6'
;print,'**********************************'

m = 1.67e-27
case specie of
   'i': A=1;H+
   'H': A=1;H+
   'He': A=4;He+
   'He2': A=4;He++
   'O': A=16;O+
   'e': A=1./1836;e-
endcase

eflux_to_psd = A^2*0.5447*1.e6
if strupcase(from_unit) eq 'EFLUX' then begin
   case strupcase(to_unit) of
     'DIFF FLUX': new_flux = flux/energy*1e3
     'PSD': new_flux = eflux_to_psd*flux/energy^2
     'DF': new_flux = eflux_to_psd*flux/energy^2
  endcase
endif
if strupcase(from_unit) eq 'DIFF FLUX' then begin
   eflux = flux*energy*1.e-3
   case strupcase(to_unit) of
      'EFLUX': new_flux = eflux
      'PSD': new_flux = eflux_to_psd*eflux/energy^2
      'DF': new_flux = eflux_to_psd*eflux/energy^2
   endcase
endif
if strupcase(from_unit) eq 'PSD' or strupcase(from_unit) eq 'DF' then begin
   case strupcase(to_unit) of
      'EFLUX': new_flux = flux/eflux_to_psd*energy^2
      'DIFF FLUX': new_flux= flux/eflux_to_psd*energy*1.e3
   endcase
endif

END
