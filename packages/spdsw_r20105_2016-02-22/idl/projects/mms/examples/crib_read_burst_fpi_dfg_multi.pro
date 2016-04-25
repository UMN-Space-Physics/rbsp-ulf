mms_init

iread=0

!mms.no_server = 0

;timespan,'2015-08-28/14:53:30',45,/sec

;timespan,'2015-08-28/14:50',5,/min

;timespan,'2015-08-28/14:53:30',45,/sec

;timespan,'2015-09-19/07:40', 6, /min

timespan,'2015-09-19/07:43:20', 20, /sec ; zoom

;timespan,'2015-10-01/06:50', 6, /min

;timespan,'2015-10-03/14:45', 4.4, /min

;timespan,'2015-10-03/14:46:50', 35,/sec

;timespan,'2015-10-16/10:30', 5,/min ; yuri; FPI not available

;timespan,'2015-10-16/13:05', 2.5,/min ; Jonathan

;timespan,'2015-10-16/13:06:30', 1,/min ; Jonathan

;timespan,'2015-09-19/09:04:30', 6.5, /min









probe_id=[1,2,3,4]

level='ql' ;'ql' or 'l2pre' or 'srvy'  (specify DFG data level)

sc_id='mms'+string(probe_id,format='(I1)')

if iread eq 1 then begin

mms_load_data, instrument='fpi',probes=probe_id, datatype='dis-moms', level='l1b', data_rate='brst'

mms_load_data, instrument='fpi',probes=probe_id, datatype='des-moms', level='l1b', data_rate='brst'
mms_load_data, instrument='dfg',probes=probe_id, datatype='',  data_rate='srvy'; 7 samples/s
mms_load_data, instrument='edp',probes=probe_id, level='ql', data_rate='fast', datatype='dce'

if level eq 'l2pre' then begin
	mms_load_dfg, probes=probe_id, level='l2pre', data_rate='brst', /no_attitude_data 
	copy_data,sc_id+'_dfg_brst_l2pre_dmpa_bvec','B'
endif

if level eq 'ql' then begin
	mms_load_dfg, probes=probe_id, level='ql', data_rate='brst', /no_attitude_data

endif

if level eq 'srvy' then begin
	mms_load_dfg, probes=probe_id, data_rate='srvy', /no_attitude_data 
endif

endif; iread

sc=['mms1','mms2','mms3','mms4']

for i=0, n_elements(sc)-1 do begin
get_data,sc(i)+'_dfg_brst_dmpa_bvec',data=d
store_data,sc(i)+'_dfg_brst_dmpa_bx',data={x:d.x,y:d.y(*,0)}
store_data,sc(i)+'_dfg_brst_dmpa_by',data={x:d.x,y:d.y(*,1)}
store_data,sc(i)+'_dfg_brst_dmpa_bz',data={x:d.x,y:d.y(*,2)}

get_data,sc(i)+'_edp_dce_xyz_dsl',data=d
store_data,sc(i)+'_edp_dce_x',data={x:d.x,y:d.y(*,0)}
store_data,sc(i)+'_edp_dce_y',data={x:d.x,y:d.y(*,1)}
store_data,sc(i)+'_edp_dce_z',data={x:d.x,y:d.y(*,2)}
endfor



store_data,'Bx',data=['mms1_dfg_brst_dmpa_bx','mms2_dfg_brst_dmpa_bx','mms3_dfg_brst_dmpa_bx','mms4_dfg_brst_dmpa_bx']
store_data,'By',data=['mms1_dfg_brst_dmpa_by','mms2_dfg_brst_dmpa_by','mms3_dfg_brst_dmpa_by','mms4_dfg_brst_dmpa_by']
store_data,'Bz',data=['mms1_dfg_brst_dmpa_bz','mms2_dfg_brst_dmpa_bz','mms3_dfg_brst_dmpa_bz','mms4_dfg_brst_dmpa_bz']
store_data,'Bt',data=['mms1_dfg_brst_dmpa_btot','mms2_dfg_brst_dmpa_btot','mms3_dfg_brst_dmpa_btot','mms4_dfg_brst_dmpa_btot']

store_data,'Vix',data=['mms1_dis_bulkX','mms2_dis_bulkX','mms3_dis_bulkX','mms4_dis_bulkX']
store_data,'Viy',data=['mms1_dis_bulkY','mms2_dis_bulkY','mms3_dis_bulkY','mms4_dis_bulkY']
store_data,'Viz',data=['mms1_dis_bulkZ','mms2_dis_bulkZ','mms3_dis_bulkZ','mms4_dis_bulkZ']

store_data,'Vex',data=['mms1_des_bulkX','mms2_des_bulkX','mms3_des_bulkX','mms4_des_bulkX']
store_data,'Vey',data=['mms1_des_bulkY','mms2_des_bulkY','mms3_des_bulkY','mms4_des_bulkY']
store_data,'Vez',data=['mms1_des_bulkZ','mms2_des_bulkZ','mms3_des_bulkZ','mms4_des_bulkZ']

store_data,'Ex',data=['mms1_edp_dce_x','mms2_edp_dce_x','mms3_edp_dce_x','mms4_edp_dce_x']
store_data,'Ey',data=['mms1_edp_dce_y','mms2_edp_dce_y','mms3_edp_dce_y','mms4_edp_dce_y']
store_data,'Ez',data=['mms1_edp_dce_z','mms2_edp_dce_z','mms3_edp_dce_z','mms4_edp_dce_z']

store_data,'Ne',data=['mms1_des_numberDensity','mms2_des_numberDensity','mms3_des_numberDensity','mms4_des_numberDensity']

var=['Bt','Bx','By','Bz','Ne','Vix','Viy','Viz','Vex','Vey','Vez','Ex','Ey']

for i=0, n_elements(var)-1 do begin
options,var(i),colors=[0,6,4,2]
options,var(i),thick=1
endfor

tplot_options,'ygap',0.3

tplot,var

stop


stop

end


