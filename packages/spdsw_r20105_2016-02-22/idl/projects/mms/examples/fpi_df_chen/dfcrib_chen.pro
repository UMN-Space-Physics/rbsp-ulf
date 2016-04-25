;to run simply type: .r dfcrib_chen

;mms_init to set up the environment in spedas
;mms_load_data to load all relevant data from SDC, or tplot_restore to restore the tplot variables stored in the .tplot file
;nloops tp specify the # of time chucks to plot a series of 2D slices of the 3D MMS FPI des and dis distributions.
;species = 'e' for des and 'i' for 'dis'
;t_chunk: time in s to store data from skymap_dist for processing 
;/noload_cdf when des and dis variables are restored from a .tplot file
;/noreload when the B field variables are restored from a .tplot fileb
;endtime: start_time + t_chunk
;angle: specifies the angle for fixed angle slicing. Example: [-20,20] means to slice at an angle 20 degrees above and below the plane to be plotted.
;/noflip: ignores the flipbook keywords
;outputfolder: the directory for the program to create for storing the distribution plots
;vrange: range of the velocity axes. Default is set in flip_dist_crib.pro
;zrange: range of the plotted quantity (PSD or counts). Default is set in flip_dist_crib.pro
;ThirdDirLim: set to 0 if doing fixed-angle slicing;
;             set to [-v3, v3] for slab slicing, where v3 is 1/2 of the velocity height (in the third dimension) of the slab    
;             example: ThirdDirLim=[-5000,5000] slices the 3D distribution by a slab with fixed height 1e4 km/s
;
; prepared by Shan Wang and Li-Jen Chen,  2015-10-06
; updated to load FPI burst data and dfg survey l2pre from SDC, Li-Jen Chen, 2015-10-12


;Pro dfcrib_chen
mms_init
sat=3
;*************
sat_str=string(sat,format='(I1)')
t_string = '2015-09-21/13:52'
timespan,t_string, 2, /min
sc_id='mms'+sat_str
probe_id=sat_str
mms_load_data, instrument='fpi',probes=probe_id, datatype='dis-dist', level='l1b', data_rate='brst'
mms_load_data, instrument='fpi',probes=probe_id, datatype='dis-moms', level='l1b', data_rate='brst'
mms_load_data, instrument='fpi',probes=probe_id, datatype='des-dist', level='l1b', data_rate='brst'
mms_load_data, instrument='fpi',probes=probe_id, datatype='des-moms', level='l1b', data_rate='brst'
mms_load_data, instrument='dfg',probes=probe_id, datatype='', level='l2pre', data_rate='srvy'

get_data,'mms'+sat_str+'_dfg_srvy_l2pre_dmpa',data=d
store_data,'mms'+sat_str+'_dfg_srvy_l2pre_dmpa_xyz',data={x:d.x,y:d.y[*,0:2]}

species='e'
join_vec,'mms'+sat_str+'_d'+species+'s_bulk'+['X','Y','Z'], 'mms'+sat_str+'_d'+species+'s_brst_bulk_DSC'

species='i'
join_vec,'mms'+sat_str+'_d'+species+'s_bulk'+['X','Y','Z'], 'mms'+sat_str+'_d'+species+'s_brst_bulk_DSC'


;*************
start_time=time_double('2015-09-21/13:52:00')

nloops = 1 ; specify the number of nloops * t_chunk (in seconds) to plot. E.g., nloops=2 means 2 seconds if t_chunks=1
species = 'e' ; select species
;species = 'i' ; select species
t_chunk = 1.0 ; 1 second (do not change this)
angle = [-20,20]
;outputfolder='~/MDAS/081515/mms_vdf_code/eVDF_FAC/'
outputfolder='./test_chen_new/'

if species eq 'e' then begin
vrange = [-3.0e4,3.0e4] ;#'s optimized for des for 0815
zrange = [1.0e-31, 1.0e-26] ;#'s optimized for des for 0815
endif

if species eq 'i' then begin
vrange = [-1.0e3,1.0e3] ;dis for 0815
zrange = [5.0e-26, 5.0e-23] ;dis for 0815
endif

ThirdDirLim = 0
for i=0,nloops-1 do begin
   end_time = start_time + t_chunk
   flip_dist_crib,sat=sat,species=species,$ 
		              /noreloadb,$
                  start_time=start_time,end_time=end_time,$
                  angle=angle,$
		/noflip,$
                  outputfolder=outputfolder,$
                  vrange=vrange,$
                  zrange=zrange,$
                  ThirdDirLim=ThirdDirLim ;slice by constant angle 20 degree
   start_time += t_chunk
endfor
END
