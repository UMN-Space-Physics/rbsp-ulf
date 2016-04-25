#designed to be run as an muser cronjob
#!/bin/csh

source /usr/local/setup/setup_idl8.3		# IDL
setenv BASE_DATA_DIR /disks/data/
setenv ROOT_DATA_DIR /disks/data/
#IDL SETUP for MAVEN
if !( $?IDL_BASE_DIR ) then
    setenv IDL_BASE_DIR ~/export_socware/idl_socware
endif

if !( $?IDL_PATH ) then
   setenv IDL_PATH '<IDL_DEFAULT>'
endif

setenv IDL_PATH $IDL_PATH':'+$IDL_BASE_DIR

#check for lock file here
if (! -e /tmp/PFPL2PLOTlock.txt) then
    cd /mydisks/home/maven
    rm -f run_pfpl2plot.bm
    rm -f /tmp/run_pfpl2plot.txt

    set line="run_pfpl2plot"
    echo $line > run_pfpl2plot.bm
    echo exit >> run_pfpl2plot.bm

    idl run_pfpl2plot.bm > /tmp/run_pfpl2plot.txt &
#else close quietly
endif 


