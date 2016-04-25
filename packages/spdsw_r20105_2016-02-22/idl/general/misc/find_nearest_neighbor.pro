;+ 
; Name:
;     find_nearest_neighbor
;     
; Purpose:
;     Uses binary search on a time series to find the array element closest to the target time
;     
; Input:
;     time_series: monotonically increasing time series array (stored as doubles)
;     target_time: time to search for in the time series (double)
;     
; Keywords:
;     quiet: suppress output of errors
;     sort: sort the input array prior to searching
;     
; Output:
;     Returns the value in time_series nearest to the target_time (as a double) 
;     Returns -1 if there's an error
; 
; Examples:
;     >> print, find_nearest_neighbor([1,2,3,4,5,6,7,8,9], 4.6)
;           5
;           
;     >> print, find_nearest_neighbor([5,4,3,7,8,2,4,6,7], 7.6, /sort)
;           8
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-02-06 12:09:24 -0800 (Thu, 06 Feb 2014) $
; $LastChangedRevision: 14176 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/find_nearest_neighbor.pro $
;-
function find_nearest_neighbor, time_series, target_time, quiet = quiet, sort = sort
    if ~undefined(sort) then time_series = time_series[bsort(time_series)]

    ; check the first and last elements to make sure we're inside the range
    ; using the fact that the times are monotonic 
    if (target_time lt time_series[0] || target_time gt time_series[n_elements(time_series)-1]) then begin
        if undefined(quiet) then dprint, dlevel=1, 'The element we''re searching for is outside the array'
        return, -1
    end
    
    if n_elements(time_series) le 1 then begin
        if undefined(quiet) then dprint, dlevel=1, 'time_series has <= 1 element'
        return, -1
    endif else if n_elements(time_series) eq 2 then begin
        ; down to the last 2 elements in the time series, find out which is closer to the target time
        if abs(time_series[0]-target_time) le abs(time_series[1]-target_time) then begin
            return, time_series[0]
        endif else begin
            return, time_series[1]
        endelse 
    endif else begin ; more than 2 elements in the array
        ; split the time series in half
        times_left = time_series[0:n_elements(time_series)/2]
        times_right = time_series[n_elements(time_series)/2:n_elements(time_series)-1]

        ; again, using the fact that the time series is monotonic in the array
        ; if the time of interest is <= the last element on the left array, 
        ; we know the nearest neighbor must be somewhere in that array
        if target_time le times_left[n_elements(times_left)-1] then begin
            fnn = find_nearest_neighbor(times_left, target_time, quiet = quiet)
        endif
        if target_time ge times_right[0] then begin
            fnn = find_nearest_neighbor(times_right, target_time, quiet = quiet)
        endif 
    endelse

    return, fnn

end