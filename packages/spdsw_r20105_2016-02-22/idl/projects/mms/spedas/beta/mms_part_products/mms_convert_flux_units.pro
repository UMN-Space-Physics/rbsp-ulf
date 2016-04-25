;+
;PROCEDURE: mms_convert_flux_unit
;PURPOSE:
;  Converts between eflux, differential flux, power spectral density and df units for particle routines
;
; Based on mms/examples/fpi_df_chen/convert_flux_unit.pro
; Modified to be more convenient for particle products routines
; Only tested with fpi data
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-01-15 11:37:57 -0800 (Fri, 15 Jan 2016) $
;$LastChangedRevision: 19748 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_part_products/mms_convert_flux_units.pro $
;-
pro mms_convert_flux_units,dist,units=units,output=out

;print,'******Unit requirements:********'
;print,'energy: eV'
;print,'EFLUX eV/cm^2/s/sr/eV or keV/cm^2/s/sr/keV'
;print,'DIFF FLUX #/cm^2/s/sr/keV'
;print,'PSD or DF s^3/km^6'
;print,'**********************************'

out = dist

m = 1.67e-27
species_lc = strlowcase(dist.species)

from_units = strlowcase(dist.units_name)

if undefined(units) then begin
  units = 'eflux'
endif

units_lc = strlowcase(units)


if from_units eq 'df_cm' then begin
  out.data *= 1e30
  from_units = 'df'
endif else if from_units eq 'df_km' then begin
  from_units = 'df'
endif

df_div = 1
if units_lc eq 'df_km' then begin
  units_lc = 'df'
endif else if units_lc eq 'df_cm' then begin
  units_lc = 'df'
  df_div = 1e30
endif

case species_lc of
   'i': A=1;H+
   'hplus': A=1;H+
   'heplus': A=4;He+
   'heplusplus': A=4;He++
   'oplus': A=16;O+
   'oplusplus': A=16;O++
   'e': A=1./1836;e-
endcase

eflux_to_psd = A^2*0.5447*1.e6
if from_units eq 'eflux' then begin
   case units_lc of
     'diff_flux': out.data = out.data/out.energy*1e3
     'psd': out.data = eflux_to_psd*out.data/out.energy^2
     'df': out.data = eflux_to_psd*out.data/out.energy^2
  endcase
endif
if from_units eq 'diff_flux' then begin
   eflux = out.data*out.energy*1.e-3
   case units_lc of
      'eflux': out.data = eflux
      'psd': out.data = eflux_to_psd*eflux/out.energy^2
      'df': out.data = eflux_to_psd*eflux/out.energy^2
   endcase
endif
if from_units eq 'psd' or from_units eq 'df' then begin
   case units_lc of
      'eflux': out.data = out.data/eflux_to_psd*out.energy^2
      'diff_flux': out.data= out.data/eflux_to_psd*out.energy*1.e3
      'df':
   endcase
endif

 out.data /= df_div
 out.units_name = units_lc 

END
