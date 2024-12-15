Bayesion Optimization of the Zombies model with EMEWS
-----------------------

This repository contains worked examples of optimizing a simple simulation model using EMEWS with both Python and R. The Zombies demonstration model, [which is distributed with Repast4Py](https://repast.github.io/repast4py.site/guide/user_guide.html#_tutorial_3_the_zombies_model) (Collier and Ozik 2022), is an agent-baed model involving two agent types, Zombies and Humans. Zombies pursue Humans, seeking to infect them, and once a Human agent is infected it is transformed into a Zombie after an incubation period lasting a number of time steps. Each time step, each Zombie and Human examines their local Moore neighborhood and moves towards the location with the most Humans or fewest Zombies, respectively. Refer to [Collier and North, 2015](https://jozik.github.io/emews_next_gen_tutorial_tests/#_jzombie_repast_simulation) for more information on the Zombies model.

For this demonstration, we have introduced a varying movement step size for each of the agent types. The original model had Zombies move in fixed steps of length 0.25 (in units of the model space) and Humans in steps of length 0.5. The present model encapsulates these two values in two float type parameters, `zombie_step_size` and `human_step_size`. 

Using EMEWS and tools from Bayesian optimization (BO), we seek to find the combination of `zombie_step_size` and `human_step_size` that results in the greatest number of surviving human agents at a specified simulation time. The adaptive parameter search algorithm we use is Thompson sampling (TS, Thompson 1933; Thompson 1935) combined with [Gaussian process (GP) surrogates](https://bobby.gramacy.com/surrogates/), which efficiently samples parameters by balancing exploration (trying to options) and exploitation (leveraging current knowledge). To start with, a GP model is trained on an initial batch of
simulations and subsequently updated as the simulation dataset expands during optimization. At each
iteration, samples are drawn from the fitted GP’s predictive surface to identify the next batch of parameter
combinations for conducting new simulations. The parameters we want to explore are submit to an EMEWS DB task queue to run the Zombies simulations with Repast4Py. 


Setup
---- 

After cloning this repository, the following setup is required to run these examples:

1. Install EMEWS on your machine following the [quickstart instructions](https://jozik.github.io/emews_next_gen_tutorial_tests/#quickstart).
2. Point line 19 of `scripts/run_zombies.sh` to the location of the Python environment. 

2. Install [Repast4Py](https://repast.github.io/repast4py.site/index.html) in a local Python environment (virutal or otherwise) and point line 19 of `scripts/run_zombies.sh` to this environment.
3. Activate the 











References
-----------
Collier, N. and J. Ozik. 2022. “Distributed Agent-Based Simulation with Repast4Py”. In 2022 Winter Simulation Conference (WSC), 192–206 https://doi.org/10.1109/WSC57314.2022.10015389.

Thompson, W. R. 1933. “On the Likelihood that One Unknown Probability Exceeds Another in View of the Evidence of Two
Samples”. Biometrika 25(3/4):285 https://doi.org/10.2307/2332286.

Thompson, W. R. 1935. “On the Theory of Apportionment”. American Journal of Mathematics 57(2):450 https://doi.org/10.
2307/2371219.
Ushey, K., J. Allaire, an

EMEWS project template
-----------------------

This project is compatible with swift-t v. 1.3+. Earlier
versions will NOT work.

The project consists of the following directories:

```
./
  data/
  ext/
  etc/
  python/
    test/
  R/
    test/
  scripts/
  swift/
  README.md
```
The directories are intended to contain the following:

 * `data` - model input etc. data
 * `etc` - additional code used by EMEWS
 * `ext` - swift-t extensions such as eqpy, eqr
 * `python` - python code (e.g. model exploration algorithms written in python)
 * `python/test` - tests of the python code
 * `R` - R code (e.g. model exploration algorithms written R)
 * `R/test` - tests of the R code
 * `scripts` - any necessary scripts (e.g. scripts to launch a model), excluding
    scripts used to run the workflow.
 * `swift` - swift code
