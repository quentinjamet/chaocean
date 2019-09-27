# CHAOCEAN

![alt tag](files/amoc_26n.png)

The goal of this project is to disentangle the low-frequency oceanic variability in the subtropcial North Atlantic as locally generated through intrinsic ocean processes, locally driven by the atmosphere or controlled by remote signals. 

We run for this 4 ensembles with permutation in the atmospheric forcing and opend boundary conditions as fully varying (realistic) or yearly repeating. The 4 ensembles are referred to as: 

|                       | Fully varying atm  | Yearly repeating atm  |
|-----------------------|--------------------|-----------------------|
| Fully varying OBCS    |       ORAR         |        ORAC           |
|-----------------------|--------------------|-----------------------|
| Yearly repeating OBCS |       OCAR         |        OCAC           |

For in depth details, see the project report [files/chaocean_project_report.pdf](files/chaocean_project_report.pdf) on these simulations are given in the following.


## Initial conditions, open boundaries and atmospheric forcing


- Open boundaries: Derived from the 55-yr long, 1/12 global ocean configuration ORCA12.L46-MJM88; Applied every 5 days. 

- Atmospheric forcing: Derived from DFS4.4 and DFS5.2 data set; Applied every 6 hours.

- Initial conditions: Derived from a perturbed ocean state at the end of the 5-years spin-up (more details below).

All the scripts needed to build the input (forcing and initial conditions) can be found in ```./mk_config/```. 

- 



- ```./mk_extended_flx.m```: The 50-yr long atmopsheric forcing and boundary conditions are split in 1-yr long files. For the time interpolation to be made properly at run time, two additional time records, corresponding to the last (first) time record of the preceding (following) year are placed at the end of each files. The code as been modified to properly handle this time interpolation (see below).

## Configuration files for MITgcm

All these files are in the MITgcm directory. The sub-directories are for namelists (```input_*```) and associated code (```code_*```) (usual MITgcm configurations files). 

![alt tag](scripts/topo_tiles.png)

## Runs


