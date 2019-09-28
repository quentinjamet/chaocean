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

- Initial conditions: Derived from a perturbed ocean state at the end of the 5-years spin-up (more details below).

- Open boundaries: Derived from the 55-yr long, 1/12 global ocean configuration ORCA12.L46-MJM88; Applied every 5 days. 

- Atmospheric forcing: Derived from DFS4.4 and DFS5.2 data set; Applied every 6 hours.


## Configuration files for MITgcm

All these files are in the MITgcm directory. The sub-directories are for namelists (```input_*```) and associated code (```code_*```) (usual MITgcm configurations files). 

## Simulations

Model ouptuts are available at [http://ocean.fsu.edu/~qjamet/share/data/forced_amoc_2019/](http://ocean.fsu.edu/~qjamet/share/data/forced_amoc_2019/).
