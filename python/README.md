Zombies BO with Python
----

This folder contains the worked exampled of the EMEWS Zombies BO in a Jupyter notebook.
- `zombiesBO.ipynb` contains the full worked example, which includes launching the EMEWS database, running the Zombies simulation with EMEWS, and performing a simple Bayesian Optimization to find the optimal parameters.
- `helpers.py` includes functions for data processing and plotting and is imported into the notebook.
- `algo_cfg.yaml` sets parameters for EMEWS and Repast4Py and needs to be edited before running.

Setup
----

1. Edit `algo_cfg.yaml` to point to your local installation of EMEWS:
    - Line 2: Set `db_path` to the location of the EMEWS database you installed (e.g., `~/Documents/db/emews_db`)
    - Line 13: Update `pb_bin_path` to point to the Conda environment installed during the EMEWS intallation (e.g., `~/miniconda3/envs/emews-py3.11/bin`)
    - Line 19: Set `python_path` to the location of the Python install within the Conda environmente (e.g., `~/miniconda3/envs/emews-py3.11/bin/python3`)
2. Open `zombiesBO.ipynb` in a Jupyter environment, making sure you select the conda environment we created a your kernel (e.g., emews-py3.11) and work through the example.


