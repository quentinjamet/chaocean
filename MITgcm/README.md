# Numerical description of the configuration and re-run

We provide here all the necessary informations to compile and run the simulation used in the project. The piece of code for the MITgcm, associated namelists and bash scripts to help reproducing the run, as well as location of where to retrieve forcing files, are all provided here. In case of problem, you can always contact me (<quentin.jamet@univ-grenoble-alpes.fr>).



Compiled with the Checkpoint 66d of the MITgcm. Some namelists (data, data.cheapaml) are ensembler-dependent and are thus provided with their associated ensemble.

## MITgcm code: 

The configuration has been made with the Checkpoint 66d of the MITgcm. Issued are likely to emerge with latter version due to model updates (particularly the cheapaml package). Following MITgcm 'Getting Started with MITgcm' instructions on the code manual ([https://doi.org/10.5281/zenodo.1409237](https://doi.org/10.5281/zenodo.1409237)), we provide the specific piece of code for this configuration in the ```./code/``` directory. For example, the ```package.conf``` file defines the different packages to be complied for this configuration:

```
   gfd
   obcs
   kpp
   gmredi (compiled but not used at run time (useGMRedi=.FALSE. in data.pkg))
   cheapaml
   diagnostics
```

Most important modifications of the original code concern the way input files are read. To avoid 50-year long forcing files (which would have represent about 60GB of data for each atmospheric fields), we split this long time series into 50, 1-yr long time series, one for each year. We thus leveraged the ```periodicExternalForcing``` (```periodicExternalForcing_cheap``` for CheapAML), and modified the time interpolation made at the begin and at the end of the 1-year long simulation. Changes appear in ```external_fields_load.F```, such that 2 additional time records in the forcing files are considered, corresponding to the last (first) time record of the preceding (following) year. (See ../mk_config/mk_extended_flx.m for how to generate those forcing files). To let the model know about these 2 additional time records, we added the run time flag ```useYearlyField``` (and ```useYearlyField_cheap``` for CheapAML) in the associated namelists.


## Namelists:

Namelists common to all ensembles are provided in the ```./input/``` directory. This are run time parameters used for the simulations, where prescription of open boundary conditions (```data.obcs```) and model outputs (```data.diagnostics```) are for instance made. 

Namelists ```data``` and CheapAML ```data.cheapaml``` are ensemble-dependent, and thus placed in the appropriate directory. Three points here:

- In the ensembles exposed to realistic open boundary conditions (ORAR and ORAC), ```useYearlyField``` is set to ```.TRUE.``` in the ```data``` namelist (```=.FALSE``` for the 2 other ensembles). Same, In ensembles exposed to realistic surface forcing (ORAR and OCAR), ```useYearlyField_cheap``` is set tot ```.TRUE.``` in the ```data.cheapaml``` namelist (```=.FALSE.``` for the two other ensembles). 

- The repeat cycle is set to 1 year in all cases (```externForcingCycle=31536000``` and ```externForcingCycle_cheap=31536000```), and the repeat period to 5 days (6 hours) for the obcs (cheapaml), i.e. ```externForcingPeriod=432000``` in ```data``` (```externForcingPeriod_cheap=21600``` in ```data.cheapaml```).

- There is 2 versions of CheapAML namelist because a issue on the periodic boundary conditions was present in the original code and has contaminated the 10 first years of simulation. ```data.cheapaml_bug``` is thus used before 1973, and ```data.cheapaml``` afterwards. This issue has been reproduced in all ensembles to avoid inconsistency in comparisons.

## Getting the forcing files

The forcing files (both surface and open boundary conditions) used to generate our ensemble are accessible at [http://ocean.fsu.edu/~qjamet/share/data_in/](http://ocean.fsu.edu/~qjamet/share/data_in/). It contains both realisitc forcing for each year (with the 2 extra time records discussed above), as well as the yearly repeating forcing (1963-2012 climatology for obcs and August 2003 - July 2004 normal year for the atmospheric fields).


## Reproducing the configuration 

This lines are guidelines for recompiling the configuration used in this project, and run a test for 1 year of 1 of the members of the ORAR ensemble.

- To start, get all about the chaocean project, i.e. clone the git repository where you will compile the code, and download the 66c MITgcm chekpoint in the chaocean directory (you can remove the verification directory which)

```
git clone https://github.com/quentinjamet/chaocean.git
cd ./chaocean/MITgcm/
wget https://github.com/MITgcm/MITgcm/archive/checkpoint66d.zip
unzip MITgcm
rm -rf MITgcm-checkpoint66d/verification/
```
- Compile the code. Update the ```Compile``` bash script with appropriate root directory and option file. The provided example is made to run on Cheyenne under a testing directory.
```
cd ./bin/
./Compile
cd ../
```
At this stage, the configuration should have compiled, and a ```mitgcmuv``` executable should be present in the ```./chaocean/MITgcm/build/``` directory. If this is not the case, I am affraied something went wrong ...

- Retrieve initial conditions, grid and forcing files for memb00 and the year 1963 as an eample. These data set is potentially heavy and should be placed on a dedicated disk space. The bash script ```mk_input```  is an example of how to proceed.
