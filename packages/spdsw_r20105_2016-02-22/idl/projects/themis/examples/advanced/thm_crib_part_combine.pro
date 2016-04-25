
;+
;Name:
;  thm_crib_part_combine
; 
;Purpose:
;  Crib demonstrating basic usage of combined ESA/SST particle code.
;
;See also:
;  thm_crib_part_products
;  thm_crib_part_slice2d
;  thm_crib_sst_load_calibrate
;
;Notes:
;  If you see any useful examples missing from these cribs, please let us know.
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-14 14:38:31 -0700 (Thu, 14 May 2015) $
;$LastChangedRevision: 17616 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_combine.pro $
;-

compile_opt idl2



print, ' ', ' Load times may be as long as 60+ seconds when producing combined data sets. ', ' '

stop


;expand left margin to better accomodate labels
tplot_options, 'xmargin', [15,9]


;--------------------------------------------------------------------------------------
;Load Combined Data
;--------------------------------------------------------------------------------------

;set probe and day
;time intervals longer than 1-2 hours may be memory and times intensive
probe = 'd'
trange = '2011-07-29/' + ['13:00','14:00']

;specify which datatype to use from each instrument
;only full and burst data are valid for sst_datatype
esa_datatype = 'peif'
sst_datatype = 'psif'

;This will automatically load the required particle data and interpolate 
;between the two instruments to produce the combined product.
;The original ESA and SST data will be passed out via the last two keywords. 
combined = thm_part_combine(probe=probe, trange=trange, $
                            esa_datatype=esa_datatype, sst_datatype=sst_datatype, $
                            orig_esa=esa, orig_sst=sst) 


print, ' ','The "combined" variable now contains pointers to the combined particle distribution.'
print, 'This can be passed to other routines to produce combined data products.', ' '

stop

;--------------------------------------------------------------------------------------
;Produce energy spectrogram
;--------------------------------------------------------------------------------------

;Pass the combined data into processing routines the same way you
;would use output from thm_part_dist_array.
thm_part_products, dist_array=combined, outputs='energy'

window, ysize=800

;naming is slightly different than normal particles variables.
;p=particles
;t=total
;i=ions
;f=full distribution esa
;f=full distribution sst
tplot, 'thd_ptiff_eflux_energy'

print, ' ','Pass the combined data to thm_part_products to produce spectrograms.'
print, 'This is an example of a combined energy spectrogram.'
print, 'Continue to the next example to see a before & after comparison.',' '

stop

;--------------------------------------------------------------------------------------
;Compare with original data
;--------------------------------------------------------------------------------------

;Generate spectrograms from original ESA/SST data
thm_part_products, dist_array=esa, outputs='energy'
thm_part_products, dist_array=sst, outputs='energy'

window, 0, ysize=800
window, 1, ysize=800

;set all plots to the same scale
options, ['thd_ptiff_eflux_energy','thd_psif_eflux_energy','thd_peif_eflux_energy'], $
          zrange = [1e3,1e7]

tplot, ['thd_psif_eflux_energy','thd_peif_eflux_energy'], window=1
tplot, 'thd_ptiff_eflux_energy', window=0

print, ' ','This compares the combined energy spectrogram to plots made from the original data.', ' '

stop

;--------------------------------------------------------------------------------------
;Produce moments
;--------------------------------------------------------------------------------------

;moments will be produced for this run
;see thm_crib_part_products for more usage options
thm_part_products, dist_array=combined, outputs='moments'

;moments to plot
mom_names = 'thd_ptiff_'+['density','velocity','eflux']

tplot, mom_names

print, ' ','Pass the combined data to thm_part_products (or thm_part_moments) to produce combined moments.'
print, 'Continue to the next example to see a comparison with on board moments.',' '

stop

;--------------------------------------------------------------------------------------
;Compare with on board moments
;--------------------------------------------------------------------------------------

;get combined on board moments
thm_load_mom, probe=probe, trange=trange, datatype='ptim'

;density
mom_names = 'thd_'+['ptim','ptiff']+'_density'

options, mom_names, yrange=[1e-2,1e2], ylog=1

tplot, mom_names

print, ' ','Density comparison (on board vs. ground).', ' '

stop

;velocity
mom_names = 'thd_'+['ptim','ptiff']+'_velocity'

options, mom_names, yrange=[-200,200] 

tplot, mom_names

print, ' ','Velocity comparison (on board vs. ground).', ' '

stop

;eflux
mom_names = 'thd_'+['ptim','ptiff']+'_eflux'

options, mom_names, yrange=[-1e11,1e11]

tplot, mom_names

print, ' ','Flux comparison (on board vs. ground).', ' '

stop

;pressure tensor
mom_names = 'thd_'+['ptim','ptiff']+'_ptens'

options, mom_names, yrange=[-1e3,8e3]

tplot, mom_names

print, ' ','Pressure tensor comparison (on board vs. ground).', ' '

stop

;--------------------------------------------------------------------------------------
;Produce velocity slice
;--------------------------------------------------------------------------------------

;load support data for field aligned slice
;  -bulk velocity vector must be specified for combined distributions
;   when using BV, BE, xvel, and perp rotations (no automatic calculation)
thm_load_mom, probe=probe, trange=trange, datatype='ptim'
thm_load_fgm, probe=probe, trange=trange, datatype='fgl', level=2, coord='dsl'

;get velocity slice
thm_part_slice2d, combined, slice_time=trange[0], timewin=30, part_slice=comb_slice, $
   rotation='BV', mag_data='thd_fgl_dsl', vel_data='thd_ptim_velocity', /three_d_interp

thm_part_slice2d_plot, comb_slice

print, ' ','Pass the combined data to thm_part_slice2d to produce combined velocity slices.'
print, 'Continue to the next example to see a comparison with esa-only and sst-only slices.',' '

stop

;--------------------------------------------------------------------------------------
;Compare with plot produced from separate distributions
;--------------------------------------------------------------------------------------

;-use default method to show bin boundaries
;-use gsm coordinates for sst
;-limit energy range to exclude top SST energies
; (tenuous data at high energies/makes it easier to see instrument energy gap)
thm_part_slice2d, combined, slice_time=trange[0], timewin=30, part_slice=comb_slice, $
                  erange=[0,8e5], coord='gsm'
thm_part_slice2d, esa, sst, slice_time=trange[0], timewin=30, part_slice=sep_slice, $
                  erange=[0,8e5], coord='gsm'

zrange = sep_slice.zrange ;range of pre-interpolated data

thm_part_slice2d_plot, comb_slice, zrange=zrange, window=0
thm_part_slice2d_plot, sep_slice, zrange=zrange, window=1


print, ' ','This comparison shows a slice of the combined data compared to an '
print, 'un-interpolated esa + sst slice.',' '

stop

;----------------------------------------------------------------------------------------
;Generate data with SST & interpolated bins only.  
;(This Backwards compatibility mode, generates the output from thm_sst_load_calibrate.)
;----------------------------------------------------------------------------------------
combined = thm_part_combine(probe=probe, trange=trange, $
  esa_datatype=esa_datatype, sst_datatype=sst_datatype, $
  orig_esa=esa, orig_sst=sst,/only_sst)
  

;Pass the combined data into processing routines the same way you
;would use output from thm_part_dist_array.
thm_part_products, dist_array=combined, outputs='energy'

tplot,'thd_psif_eflux_energy'

print,'SST data & interpolated bins used to generate particle products.'

stop

;----------------------------------------------------------------------------------------
;Generate data with SST energy bins below the limit removed before filling the ESA/SST gap
;For later mission dates those bins may be unreliable due to instrument degration
;----------------------------------------------------------------------------------------
combined = thm_part_combine(probe=probe, trange=trange, $
  esa_datatype=esa_datatype, sst_datatype=sst_datatype, $
  orig_esa=esa, orig_sst=sst,sst_min_energy=50000.)


;Pass the combined data into processing routines the same way you
;would use output from thm_part_dist_array.
thm_part_products, dist_array=combined, outputs='energy'

tplot,'thd_psif_eflux_energy'

print,'SST data & interpolated bins used to generate particle products.'

stop
;--------------------------------------------------------------------------------------
;End
;--------------------------------------------------------------------------------------

print, 'End of crib.'

end