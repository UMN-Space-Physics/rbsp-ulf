# RBSP

Note: this repository is large (so `git status` and `git commit` are slow) due mostly to the SPEDAS and SPICE packages. Really, they don't even need to be in this repository -- no changes are made to them here. 

## Setup

In order to access RBSP data through IDL, the following should be added to `~/.bashrc` and (?) `~/.bash_profile` (replacing the data storage path, the include path, and the root path as appropriate). 

    function spedas {
      module load idl
      export ROOT_DATA_DIR="/export/scratch/users/mceachern/rbsp"
      idl -e "PREF_SET, 'IDL_DLM_PATH', '<IDL_DEFAULT>'+PATH_SEP(/SEARCH_PATH)+'~/Desktop/rbsp/incl', /COMMIT"
      ROOTDIR=~/Desktop/rbsp/packages/
      idl $* -IDL_PATH "+$ROOTDIR:<IDL_DEFAULT>"
    }
    export -f spedas

Creating a symbolic link to the EFW examples is also convenient. In `rbsp/`, type `ln -s packages/spdsw_r20105_2016-02-22/idl/general/missions/rbsp/efw/examples/ examples`. IDL **does** seem to respect symbolic links. 

Bleeding-edge SPEDAS software comes from `http://themis.ssl.berkeley.edu/socware/bleeding_edge/`. 

Geopack library is located at `http://ampere.jhuapl.edu/code/idl_geopack.html`. Note that version 9.3 has dependencies that the physics department machines can't satisfy, but 7.6 seems to work. 

Icy, the IDL SPICE toolkit, comes from `http://naif.jpl.nasa.gov/naif/toolkit_IDL.html`. 

Requirements include NumPy, SciPy, and Matplotlib. The versions on department machines may be too old; try `pip install --user --upgrade scipy` and so on if libraries seem to be missing. This does not require root access, since it performs the upgrade only for the current user. 

## `grabber.py`

This is a Python script which calls IDL under the hood, using `crib.pro`. The routine grabs ULF electric and magnetic field waveforms from both RBSP probes, dumps them as SAV files (IDL data format), then loads them into Python and saves them as pickles (Python data format). 

## `day.py`

This file describes the `day` and `event` data structures. These classes read in the pickles created by `grabber.py`, transform the data into dipole coordinates, and keep track of concurrent Dst, probe position, plasmapause location, etc. 

## `finder.py`

Using the `day` and `event` classes, this routine goes through the data and finds all of the Pc4 (or whatever) events. Event properties (frequency, magnitude, etc) are stored in `events.txt`. The fields and spectra for each event are also plotted. 

This routine also handles `pos.txt` (probe position as a function of time), `dst.txt` (Dst as a function of time), and `lpp.txt` (Scott's estimate of the plasmapause position as a function of time). 

## `plotter.py`

This script assembles plots of individual events and of aggregate event statistics -- frequency distribution of events, event positions normalized to sampling, etc. 

## `plotmod.py`

Both `finder.py` and `plotter.py` depend on `plotmod.py`, the plotting module. This file differs slightly from the version found in the Tuna repo. Another repo, Charlesplotlib, is a work in progress to consolidate all of the under-the-hood plotting routines. 



