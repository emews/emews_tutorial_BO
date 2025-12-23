Bayesian Optimization of the Zombies model with EMEWS
-----------------------

This repository contains worked examples of optimizing a simple simulation model using EMEWS with both Python and R. It accompanies the "Distributed Model Exploration with EMEWS" tutorial paper (Collier et al. 2024). The Zombies demonstration model, [which is distributed with Repast4Py](https://repast.github.io/repast4py.site/guide/user_guide.html#_tutorial_3_the_zombies_model) (Collier and Ozik 2022), is an agent-baed model involving two agent types, Zombies and Humans. Zombies pursue Humans, seeking to infect them, and once a Human agent is infected it is transformed into a Zombie after an incubation period lasting a number of time steps. Each time step, each Zombie and Human examines their local Moore neighborhood and moves towards the location with the most Humans or fewest Zombies, respectively. Refer to [Collier and North, 2015](https://repast.github.io/docs/RepastJavaGettingStarted.pdf) and the relevant section [in the EMEWS tutorial](https://emews.org/emews-tutorial/#_jzombie_repast_simulation) for more information on the Zombies model.

For this demonstration, we have introduced a varying movement step size for each of the agent types. The original model had Zombies move in fixed steps of length 0.25 (in units of the model space) and Humans in steps of length 0.5. The present model encapsulates these two values in two float type parameters, `zombie_step_size` and `human_step_size`. 

Using EMEWS and tools from Bayesian optimization (BO), we seek to find the combination of `zombie_step_size` and `human_step_size` that results in the greatest number of surviving human agents at a specified simulation time. The adaptive parameter search algorithm we use is Thompson sampling (TS, Thompson 1933; Thompson 1935) combined with [Gaussian process (GP) surrogates](https://bobby.gramacy.com/surrogates/), which efficiently samples parameters by balancing exploration (trying to options) and exploitation (leveraging current knowledge). To start with, a GP model is trained on an initial batch of
simulations and subsequently updated as the simulation dataset expands during optimization. At each
iteration, samples are drawn from the fitted GP’s predictive surface to identify the next batch of parameter
combinations for conducting new simulations. The parameters we want to explore are submit to an EMEWS DB task queue to run the Zombies simulations with Repast4Py. 


Setup
---- 

After cloning this repository, the following setup is required to run these examples. More information on this setup can be found in the EMEWS tutorial [quickstart instructions](https://jozik.github.io/emews_next_gen_tutorial_tests/#quickstart).

### 1. Install Conda

The EMEWS binary install is a conda environment, and requires a conda installation as a prerequisite. Please install [miniconda](https://docs.anaconda.com/free/miniconda/miniconda-install), [miniforge](https://conda-forge.org/miniforge), or [anaconda](ttps://www.anaconda.com/download), or miniconda if you do not have an existing conda installation. 

### 2. Download the installer files

With conda activated in your terminal, download the installer files as follows:

```
$ curl -L -O https://raw.githubusercontent.com/jozik/emews_next_gen_tutorial_tests/main/code/install/install_emews.sh
$ curl -L -O https://raw.githubusercontent.com/jozik/emews_next_gen_tutorial_tests/main/code/install/install_pkgs.R
$ curl -L -O https://raw.githubusercontent.com/jozik/emews_next_gen_tutorial_tests/main/code/install/install_eq_sql.R
```
### 3. Run the installer

The install script, install_emews.sh, takes two arguments:

```
$ bash install_emews.sh <python-version> <database-directory>
```

You can use Python version of 3.8, 3.9, 3.10, or 3.11.  The EMEWS DB database directory must be a folder that does NOT already exist. For example,

```
$ bash install_emews.sh 3.11 ~/Documents/db/emews_db
```

will install the EMEWS environment with Python 3.11 and create the EMEWS DB database in the ~/Documents/db/emews_db directory.

The install will take a few minutes to download and install the necessary components, reporting its progress as each step completes. A detailed log of the installation can be found in emews_install.log in the same directory where the install script is run. The installer will create a conda environment named emews-pyX.XX where X.XX is the Python version provide on the command line, i.e., bash install_emews.sh install_emews.sh 3.11 ~/Documents/db/emews_db creates a conda environment named emews-py3.11. The environment can found in the envs directory of your conda installation.

### 4. Setup conda environment
Once installed, activate your emews conda environment (e.g., `conda activate emews-pyX.XX`) in your terminal. Within this environment, install the Python packages required to run the analysis:

```pip install -r requirements.txt```

#### 5. Run example in Python or R 
You can now run the BO routine for the Zombies model with both [Python](https://github.com/emews/emews_tutorial_BO/tree/master/python) and [R](https://github.com/emews/emews_tutorial_BO/tree/master/R). Please see respective folders for further intstructions on running the examples.


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

References
-----------
Collier, N. and J. Ozik. 2022. “Distributed Agent-Based Simulation with Repast4Py”. In 2022 Winter Simulation Conference (WSC), 192–206 https://doi.org/10.1109/WSC57314.2022.10015389.

Collier, N., Wozniak, J.M., Fadikar, A., Stevens, A., and J. Ozik. 2024. "Distributed Model Exploration with EMEWS." In 2024 Winter Simulation Conference (WSC) (IEEE), pp. 72–86. https://doi.org/10.1109/WSC63780.2024.10838848.

Thompson, W. R. 1933. “On the Likelihood that One Unknown Probability Exceeds Another in View of the Evidence of Two
Samples”. Biometrika 25(3/4):285 https://doi.org/10.2307/2332286.

Thompson, W. R. 1935. “On the Theory of Apportionment”. American Journal of Mathematics 57(2):450 https://doi.org/10.
2307/2371219.
