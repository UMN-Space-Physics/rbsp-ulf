;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10,
;         2.69E-06,  -2.33E-02, 9.33E+01]

function spp_spc_met_to_unixtime,met
  
  ;; long(time_double('2000-1-1/12:00'))  ;Early SWEM definition
  epoch =  946771200d - 12L*3600
  ;; long(time_double('2010-1-1/0:00')) ; Correct SWEM use
  epoch =  1262304000
  unixtime =  met +  epoch
  return,unixtime

end