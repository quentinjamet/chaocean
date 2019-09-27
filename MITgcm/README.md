# Code, namelist (input) and bash scripts description

Compiled with the Checkpoint 66d of the MITgcm. Some namelists (data, data.cheapaml) are ensembler-dependent and are thus provided with their associated ensemble.

## ```./code/```: 

- Specific code used in the smulations. The ```SIZE.h``` can be changed to spread the computation on fewer/larger number of processors. 

- Important modifications here are made to read 1-year long forcing files as sub-samples of long time records (50 years in our case). This is made through the use of the run time parameter ```useYearlyField``` and ```useYearlyField_cheap```, and modify the get_periodic_interval.F to read in these 2 extra time records.

- See ```[../mk_config/mk_extended_flx.m](../mk_config/mk_extended_flx.m)``` for how to generate the appropriate forcing files.

## ```./orar/```, ```./ocar/```, ```./orac/```, ```./ocac/```

- namelists to run the 4 different ensembles. In each, common namelists to all members are in ```./input/``` and specific ones in ```./memb##/```

## Reproducing an ensemble (ORAR)

Bash scripts provided for the ensemble ```[./orar](./orar/)``` are example to reproduce a simulation. 

- ```run.sh```: script to submit to the supercomputer bash scheduler (PBS for Cheyenne)

- ```pc.vars```: additional namelist for setting up the appropriate path and bash variables

- ```./bin/```: Directory with several other scripts called by ```run.sh``` 
- 
