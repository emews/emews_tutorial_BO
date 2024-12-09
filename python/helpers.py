import numpy as np
from matplotlib import pyplot as plt
import seaborn as sns
from scipy.stats import multivariate_normal as mvn
from hetgpy import homGP, hetGP
import pandas as pd
import yaml
from typing import Dict
import json


def to_native(x, lb=np.array([0.1, 1]), ub=np.array([1, 3])):
    x_native = np.empty_like(x)
    for i in range(x.shape[1]): 
        x_native[:, i] = lb[i] + x[:, i] * (ub[i] - lb[i])
    return x_native



def generate_inputs(Xgrid, ids, id_counter, seeds, lb=np.array([0.1, 1]), ub=np.array([1, 3])):
    Xgrid_native = to_native(Xgrid, lb=lb, ub=ub)
    Xs = []
    for ix, cnt in ids.items():
        start = id_counter[ix]
        end = id_counter[ix] + cnt
        id_counter[ix] += cnt #update counter
        for s in seeds[start:end]:
            Xs.append(np.append(Xgrid[ix], s))
    X = np.vstack(Xs)
    Xnative = np.hstack([to_native(X[:, :2]), X[:, -1:]])
    return X[:, :2], Xnative


def scale_y(Y):
    Y_scaled = (Y - Y.mean())/Y.std()
    return Y_scaled, (Y.mean(), Y.std())

def initial_samples(n=5, grid_size=30, init_id=[]):
    xx = np.linspace(0, 1, grid_size)
    Xgrid = np.array(np.meshgrid(xx, xx)).T.reshape(-1, 2)
    if len(init_id)==0:
        N = Xgrid.shape[0]
        init_id = np.random.choice(N, n, replace=False)
        
    return (Xgrid[init_id], Xgrid)

def to_01(X):
    min_vals = X.min(axis=0)
    max_vals = X.max(axis=0)
    scale = max_vals - min_vals
    X_scaled = (X - min_vals) / scale
    return X_scaled




def TS_npoints(model, npoints, Xgrid):
        
    #' Batch Bayesian optimization using Thompson sampling
    #'
    #' @param model an object of class `hetGP`; e.g., as returned by `mleHetGP`
    #' @param npoints an integer representing the desired number of samples
    #' @param Xgrid a matrix of locations at which the samples are drawn
    #'
    #' @return a matrix containing the `npoints` best locations where next batch of simulations should be run

    preds = model.predict(x=Xgrid, xprime=Xgrid)
    pred_mean, pred_cov = preds['mean'], preds['cov']
    #pred_mean, pred_cov = model.predict(Xgrid, full_cov=True)
    cov_mtx = 0.5 * (pred_cov + pred_cov.T)
    tTS = mvn.rvs(mean=pred_mean.reshape(-1), cov=cov_mtx, size=npoints)
    #best_ids = list(set(np.argmax(tTS, axis=1)))[:npoints]
    return list(np.argmax(tTS, axis=1))
    #return Xgrid[best_ids]


def TS_npoints_replicates(model, npoints, Xgrid):
    preds = model.predict(x=Xgrid, xprime=Xgrid)
    pred_mean, pred_cov = preds['mean'], preds['cov']
    #pred_mean, pred_cov = model.predict(Xgrid, full_cov=True)
    cov_mtx = 0.5 * (pred_cov + pred_cov.T)
    # ensure PSD
    eigval, eigvec = np.linalg.eigh(pred_cov)
    if (eigval<0).any():
        print('correcting psd')
        eigval[eigval < 0] = 0
        cov_mtx = eigvec @ np.diag(eigval) @ eigvec.T

    tTS = mvn.rvs(mean=pred_mean.reshape(-1), cov=cov_mtx, size=npoints)
    best_ids = list(np.argmax(tTS, axis=1))
    return best_ids


def plot_gp_mean(gp, Xgrid, X, ymean=0, ystd=1,
                 logged=True, title=None):
    fig, ax = plt.subplots(1,1, figsize = (4, 3))
    Xgrid_native = to_native(Xgrid)
    X_native = to_native(X)
    df = pd.DataFrame(Xgrid_native, columns=['zombie_step_size', 'human_step_size'])
    #df[['zombie_step_size', 'human_step_size']] = df[['zombie_step_size', 'human_step_size']].round(2)
    #pred_mean, pred_var = gp.predict(Xgrid)
    preds = gp.predict(Xgrid)
    pred_mean = preds['mean']
    # rescale to original units for plotting
    pred_mean = pred_mean*ystd + ymean
    if logged:
        df['surface'] = np.exp(pred_mean)
            
    # Create the heatmaps
    surface_pivot = df.pivot(index='human_step_size', columns='zombie_step_size', values='surface').sort_index(ascending=False)
    
    surface_pivot.index = surface_pivot.index.round(3)
    surface_pivot.columns = surface_pivot.columns.round(3)
    X_native = X_native.round(3)
    
    # Transform scatter point coordinates to match heatmap's grid
    # Mapping the real 'human_step_size' and 'zombie_step_size' to the heatmap's row and column indices
    human_indices = pd.Series(X_native[:, 1]).map({value: idx for idx, value in enumerate(surface_pivot.index)})
    zombie_indices = pd.Series(X_native[:, 0]).map({value: idx for idx, value in enumerate(surface_pivot.columns)})
    
    surface_pivot.index = surface_pivot.index.round(1)
    surface_pivot.columns = surface_pivot.columns.round(1)
    
    sns.heatmap(surface_pivot, ax=ax, cmap='Blues', alpha=.5, vmin=450, vmax=1000)
        # Set limits with a small margin
    # add smaller buffer
    margin_size = .5  # Adjust margin size as needed
    xlim = ax.get_xlim()
    ylim = ax.get_ylim()
    ax.set_xlim([xlim[0] - margin_size, xlim[1] + margin_size])
    ax.set_ylim([ylim[0] + margin_size, ylim[1] - margin_size])
    
    xlabels = [label if i % 2 == 0 else '' for i, label in enumerate(ax.get_xticklabels())]
    ax.set_xticklabels(xlabels)
    
    # For y-axis
    ylabels = [label if i % 2 == 0 else '' for i, label in enumerate(ax.get_yticklabels())]
    ax.set_yticklabels(ylabels)
    
    ax.set_xlabel('Zombie Step Size')
    ax.set_ylabel('Human Step Size')
    if title is not None:
        plt.title(title)
    
    # Plot scatter points with adjusted coordinates
    #ax.scatter(zombie_indices+.5, human_indices+.5, edgecolors='black', c=np.exp(Y), cmap='Blues', alpha=.25, vmin=100, vmax=3900)
    ax.scatter(zombie_indices+.5, human_indices+.5, edgecolors='black', facecolors='none', alpha=.1)
    plt.show()