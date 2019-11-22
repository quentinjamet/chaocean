# Making the ensembles

## Scripts used to make the configuration and generate forcing files

The set of DFS data used to generate atmospheric conditions are available at [http://ocean.fsu.edu/~qjamet/share/data/data_in_chao12/atm_data/](http://ocean.fsu.edu/~qjamet/share/data/data_in_chao12/atm_data/), the original ORCA12.L46-MJM88 data used to generate boundary conditions are available at [http://ocean.fsu.edu/~qjamet/share/data/data_in_chao12/atm_data/](http://ocean.fsu.edu/~qjamet/share/data/data_in_chao12/atm_datai/), and the topography data (also from the ORCA12.L46-MJM88) are in [http://ocean.fsu.edu/~qjamet/share/data/data_in_chao12/grid_12/](http://ocean.fsu.edu/~qjamet/share/data/data_in_chao12/grid_12//). The scripts bellow are examples of how to generate forcing files for the configuration from those data sets, and need to be adapted to specific needs. 

- ```mk_grid.m```: Make the grid and bathy files used to initiate the simulation. 

- ```mk_initialConditions.m```: Make the initial conditions for the 5 years (1958-1963) spin-up.

- ```mk_radLW_radSW_precip_6hr.m```: Extrapolate daily long wave and short wave radiations and precipitation from DFS4.4 and DFS5.2 to 6 hourly fields.

- ```mk_atmFlx.m```: Interpolate DFS atmospheric forcing fields on the model grid.

- ```mk_precip.m```: Precipitations are made separatly because from another dataset

- ```mk_obcsFlx.m```: Interpolate ORCA12.L46-MJM88 U, V, T, S on the boundaries (North (55N), South (20S) and at the Strait of Gibraltar) of the domain.

- ```mk_extended_flx.m```: The 50-yr long atmopsheric forcing and boundary conditions are split in 1-yr long files. For the time interpolation to be made properly at run time, two additional time records, corresponding to the last (first) time record of the preceding (following) year are placed at the end of each files. The code as been modified to handle this time interpolation (see [../MITgcm/code/](../MITgcm/code/)).

- ```mk_neutral_year_wind_12.m```: Make the normal year forcing for the 2 ensemble driven by early repeating atmospheric forcing. 

- ```cut_gulf.m```: Used to remap the (x,y) interpolated fields on the reshaped geometry of the simulation. 

- ```my_griddata1.m``` and ```my_griddata2.m```: Modified griddata.m to avoid recomputation of interpolants when used recursively. my_griddata1.m generate the interpolants and my_griddata2.m apply them.



## Generation of Initial conditions

- The 12 ICs common to the 4 ensembles have been constructed as the model state obtained after a 1-year long model integration starting from 12 consecutive, 2-days apart model state in January 1963 and run under realistic forcing (surface and open boundaries). At the end of the 1-year long runs, the model state was saved as a restart file (including tendencies) and used as initial conditions.

- The 12 additional ICs used to extend the realistic ensemble ORAR to 24 members have been constructed in the same way, but with 2-days apart model state taken in Decembre 1962

- The 12 macro ICs used to extend the ensemble OCAC have been constructed as as the 3-year apart model state of memb00 (unperturbed), ensemble ocac, at January 1st of years 1967, 1971, 1975, 1979, 1983, 1987, 1991, 1995, 1999, 2003, 2007 and 2011.



the model state 
