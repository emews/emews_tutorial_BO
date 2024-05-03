import numpy as np
from matplotlib import pyplot as plt
import seaborn as sns
import GPy
from scipy.stats import multivariate_normal as mvn
import pandas as pd
import yaml
from typing import Dict
import json
import random

from pandarallel import pandarallel

pandarallel.initialize(progress_bar=True)

import sys, os
sys.path.append('../zombies/')

import zombies

def to_native(x, lb, ub):
    x_native = np.empty_like(x)
    for i in range(x.shape[1]): 
        x_native[:, i] = lb[i] + x[:, i] * (ub[i] - lb[i])
    return x_native


def make_params(human_step_size, zombie_step_size, counts_file, random_seed):
    params  = {
        'random.seed': random_seed,
         'stop.at': 50.0,
         'human.count': 4000,
         'zombie.count': 200,
         'world.width': 200,
         'world.height': 200,
         'run.number': 1,
         'counts_file': counts_file,
         'zombie_step_size': zombie_step_size,
         'human_step_size': human_step_size
    }
    return params

def zombies_sim(human_step_size, zombie_step_size, random_seed):
    counts_file = f'tmp/cnts_{human_step_size}_{zombie_step_size}_{random_seed}.txt'
    if os.path.exists(counts_file):
        os.remove(counts_file)
    params = make_params(human_step_size, zombie_step_size, counts_file, random_seed)
    zombies.run(params)
    with open(counts_file) as fin:
        lines = fin.readlines()
    os.remove(counts_file)
    line = lines[-1]
    vals = line.split(",")
    h_count = int(vals[1])
    return h_count
    
def get_zombies_results(human_step_size, zombie_step_size, n_trials=5):
    h_counts = []
    for i in range(n_trials):
        h_count = zombies_sim(human_step_size, zombie_step_size, i)
        h_counts.append(h_count)
    return np.mean(h_counts)

grid_size = 30
lb = np.array([0.1, 0])
ub = np.array([1, 3])

xx = np.linspace(0, 1, grid_size)
Xgrid = np.array(np.meshgrid(xx, xx)).T.reshape(-1, 2)
Xgrid_native = to_native(Xgrid, lb=lb, ub=ub)

df = pd.DataFrame(Xgrid_native, columns=['zombie_step', 'human_step'])

for i in np.arange(0):
    print('random seed', i)
    random.seed(int(i))
    #np.random.seed(i)
    df['surviving_humans'] = df.parallel_apply(lambda x: zombies_sim(x.human_step, x.zombie_step, int(i)), axis=1)
    df.to_csv(f'zombie_full_grid/human_survival_seed{i}.csv', index=False)