# CHAOCEAN PROJECT

![alt tag](files/amoc_26n.png)

The goal of this project is to disentangle the low-frequency oceanic variability in the subtropcial North Atlantic as locally generated through intrinsic ocean processes, locally driven by the atmosphere or controlled by remote processes. 

In depth details of the simulations performed for this project are available in the [files/chaocean_project_report.pdf](chaocean project report).
 


## Configuration

For this project, we developped an eddy-resolving (1/12) ocean regional configuration of the North Atlantic [20S, 55N] with the MITgcm, coupled the atmospheric boundary layer model CheapAML. 12 realizations under 4 different forcing scenario have been completed, providing a set of 4 ensembles with 12 members each. Each ensemble is exposed to its own forcing, which is a permutation of the atmospheric forcing and the open boundary conditions as fully varying (realistic) or yearly repeating. The 4 ensembles are referred to as:

|                       | Fully varying atm  | Yearly repeating atm  |
|-----------------------|--------------------|-----------------------|
| Fully varying OBCS    |       ORAR         |        ORAC           |
| Yearly repeating OBCS |       OCAR         |        OCAC           |

Within each ensemble, the 12 realizations are initialized with 12 different perturbed ocean state, provinding a estimate of the sensibility of the system to initial conditions, i.e. the intrinsic oceanic variability.

- (27/09/2019) The ensemble ORAR has been extend to 24 members (see ... for details on new ICs).

## Initial conditions, open boundaries and atmospheric forcing

Scripts used to build the inputs (forcing and initial conditions), along with their description, can be found in ```./mk_config/```. 

- Initial conditions: Derived from a perturbed ocean state at the end of the 5-years spin-up (more details below).

- Open boundaries: Derived from the 55-yr long, 1/12 global ocean configuration ORCA12.L46-MJM88; Applied every 5 days. 

- Atmospheric forcing: Derived from DFS4.4 and DFS5.2 data set; Applied every 6 hours.


## Configuration files for MITgcm

All these files are in the MITgcm directory. The sub-directories are for namelists (```input_*```) and associated code (```code_*```) (usual MITgcm configurations files). 

## Simulations

Model ouptuts are available at [http://ocean.fsu.edu/~qjamet/share/data/forced_amoc_2019/](http://ocean.fsu.edu/~qjamet/share/data/forced_amoc_2019/).
