# CHAOCEAN PROJECT

![alt tag](files/amoc_26n.png)

The goal of this project is to disentangle the low-frequency oceanic variability in the subtropcial North Atlantic as locally generated through intrinsic ocean processes, locally driven by the atmosphere or controlled by remote processes. 

In depth details of the simulations performed for this project are available at [files/chaocean_project_report.pdf](files/chaocean_project_report.pdf).
 


## Configuration

For this project, we set up an eddy-resolving (1/12) ocean regional configuration of the North Atlantic [20S, 55N] with the MITgcm, coupled the atmospheric boundary layer model CheapAML. We have run 4 different experiments of this configuration, which differ from one another by their surface forcing and open boundary conditions; their are either fully varying (realistic) or yearly repeating. All of these experiments have been integrated over 50 years (1963-2012) with a 12-member ensemble strategy; within an ensemble, all members are exposed to the same forcing (surface and open boundaries), but differ by their initial conditions at Janury, 1st 1963. 

The 4 ensembles are referred to as:

|                       | Fully varying atm  | Yearly repeating atm  |
|-----------------------|--------------------|-----------------------|
| Fully varying OBCS    |       ORAR         |        ORAC           |
| Yearly repeating OBCS |       OCAR         |        OCAC           |


- (27/09/2019) The ensemble ORAR has been extend to 24 members (see ... for details on new ICs).

## Initial conditions, open boundaries and atmospheric forcing

Scripts used to build the inputs (forcing and initial conditions), along with their description, can be found in ```./mk_config/```.

- Initial conditions: The configuration is first spun-up for 5 years (1958-1963) from the ORCA12.L46-MJM88 initial conditions. Then, all ensembles are integrated forward in time for 50 years (1963-2012) with a 12-member ensemble strategy. The 12 initial conditions are common to all ensembles, and are meant to reflect the spread induced by the growth of small, dynamically consistent perturbations decorrelated at seasonal time scales (further details in [mk_config/](mk_config/).

- Open boundaries: Oceanic velocities (U, V) and tracers (T, S) are restored with a 6 hours relaxation time scale toward oceanic state derived from the 55-year long 1/12 horizontal resolution ocean-only global configuration ORCA12.L46-MJM88. Open boundary conditions are applied every 5 days and linearly interpolated in between. 

- Atmospheric forcing: At the surface, the ocean model is coupled to the atmospheric boundary layer model CheapAML. Atmospheric surface temperature and relative humidity respond to ocean surface structures by exchanges computed according to the COARE3 flux formula, but are strongly restored toward prescribed values over land. Other variables (downward longwave and solar shortwave radiation, precipitations) are prescribed everywhere. Atmospheric reanalysis products used in CheapAML originate from the Drakkar forcing set (DFS4.4, Brodeau et al, 2010; Dussin et al, 2016). Pricipitations are from DFS5.2 due to better time resolution.


## Configuration files for MITgcm

All files needed to set up and run this configuration are provided in [./MITgcm/](./MITgcm/). Piece of code specific to this configuration are in ```./code/```, and associated namelists in ```./input/```. The namelists ```data``` and ```data.cheapaml``` are specific to each ensemble and thus placed in their associated directories. We also provide bash scripts in ```./bin/``` to help replication. Further informations and details are also provided there.


## Simulations

Model ouptuts are available at [http://ocean.fsu.edu/~qjamet/share/data/forced_amoc_2019/](http://ocean.fsu.edu/~qjamet/share/data/forced_amoc_2019/).
