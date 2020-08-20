# Multirotor Sizing Methodology
By Nathan Toombs. Based on the repository for the article "Multirotor Sizing Methodology with Flight Time Estimation", with credit to M. Biczyski, R. Sehab, G.Krebs, J.F. Whidborne, P. Luk

Files created and validated using Matlab 2018a

## Instructions
The `main.m` file defines the flight parameters and runs the optimization. Choose the parameters, actual and estimated, then choose the optimization method. `singleRun` uses the defined payload mass and battery capacity to determine the best system for those parameters. `iterateBattery` uses a given min, step, and max battery capacities to run the optimization for each and creates a plot of the flight time performance for each capacity. `iteratePayloadAndBattery` repeats the `iterateBattery` method for different payloads with a min, step, and max mass, and will produce a plot for each payload mass. The `data` variable holds information on the chosen combination at each payload mass and battery capacity.

## Combination List
In the `Lists` directory is the `ComboList&Data.xlsx` file. On the first sheet is the list of each provided motor and propeller combination, and then brands have their own tabs. At the moment, only KDE, T-Motor, and CR Flight products are implemented.

### Adding Combinations
The optimization uses motor/propeller combinations because they match the data provided. To add more combinations, enter the correct sheet and follow the format of previous examples. The data for each combination must take up exactly 8 lines; make sure to have a row at 0% thrust, rpm, power, etc, and one at 100%; this will allow the algorithm to interpolate anywhere from 0% to 100%. Make sure to add a line to the List sheet for the corresponding combination.

### Selecting Specific Combinations
To use only certain combinations, set the `Use Data` column to 0 for every combination to be ignored and 1 for the ones to use in the algorithm. This can be used to check the performance of a single combination over a wide range of conditions.
