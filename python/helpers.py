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
    """
    Transform a matrix to be within specified bounds
    """
    x_native = np.empty_like(x)
    for i in range(x.shape[1]): 
        x_native[:, i] = lb[i] + x[:, i] * (ub[i] - lb[i])
    return x_native


def generate_inputs(Xgrid, ids, id_counter, seeds, lb=np.array([0.1, 1]), ub=np.array([1, 3])):
    """
    Generate inputs in required format for EMEWS DB
    """
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


def TS_npoints_replicates(model, npoints, Xgrid):
    preds = model.predict(x=Xgrid, xprime=Xgrid)
    pred_mean, pred_cov = preds['mean'], preds['cov']
    #pred_mean, pred_cov = model.predict(Xgrid, full_cov=True)
    cov_mtx = 0.5 * (pred_cov + pred_cov.T)
    # ensure PSD
    eigval, eigvec = np.linalg.eigh(cov_mtx)
    if (eigval<0).any():
        print('Covariance matrix is not positive semidefinite. Clipping negative eigenvalues.')
        eigval[eigval < 0] = 0
        cov_mtx = eigvec @ np.diag(eigval) @ eigvec.T

    tTS = mvn.rvs(mean=pred_mean.reshape(-1), cov=cov_mtx, size=npoints)
    best_ids = list(np.argmax(tTS, axis=1))
    return best_ids

def plot_gp(gp, Xgrid, X, ymean=0, ystd=1,
                 logged=True, title=''):
    fig, axs = plt.subplots(1,2, figsize = (8, 4))
    Xgrid_native = to_native(Xgrid)
    X_native = to_native(X)
    df = pd.DataFrame(Xgrid_native, columns=['zombie_step_size', 'human_step_size'])
    #df[['zombie_step_size', 'human_step_size']] = df[['zombie_step_size', 'human_step_size']].round(2)
    #pred_mean, pred_var = gp.predict(Xgrid)
    preds = gp.predict(x=Xgrid, xprime=Xgrid)
    pred_mean, pred_cov = preds['mean'], preds['cov']
    # rescale to original units for plotting
    pred_mean = pred_mean*ystd + ymean
    if logged:
        df['surface'] = np.exp(pred_mean)
    df['surface_sd'] = np.sqrt(preds['sd2'])
            
    # Create the heatmaps
    for i, col in enumerate(['surface', 'surface_sd']):
        ax = axs[i]
        surface_pivot = df.pivot(index='human_step_size', columns='zombie_step_size', values=col).sort_index(ascending=False)
        
        surface_pivot.index = surface_pivot.index.round(3)
        surface_pivot.columns = surface_pivot.columns.round(3)
        X_native = X_native.round(3)
        
        # Transform scatter point coordinates to match heatmap's grid
        # Mapping the real 'human_step_size' and 'zombie_step_size' to the heatmap's row and column indices
        human_indices = pd.Series(X_native[:, 1]).map({value: idx for idx, value in enumerate(surface_pivot.index)})
        zombie_indices = pd.Series(X_native[:, 0]).map({value: idx for idx, value in enumerate(surface_pivot.columns)})
        
        surface_pivot.index = surface_pivot.index.round(1)
        surface_pivot.columns = surface_pivot.columns.round(1)
        
        if col == 'surface':
            sns.heatmap(surface_pivot, ax=ax, cmap='Blues', alpha=.5, vmin=450, vmax=1000)
        elif col == 'surface_sd':
            sns.heatmap(surface_pivot, ax=ax, cmap='Greens', alpha=.5)
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
        if col == 'surface':
            ax.set_title('Mean Surface')
            ax.collections[0].colorbar.set_label("Surviving Humans", labelpad=-52)
            #cbar = ax.collections[0].colorbar
            #cbar.ax.text(1,1,"Surviving \nHumans",rotation=0)

        elif col == 'surface_sd':
            ax.set_title('Variance')
    # Plot scatter points with adjusted coordinates
    #ax.scatter(zombie_indices+.5, human_indices+.5, edgecolors='black', c=np.exp(Y), cmap='Blues', alpha=.25, vmin=100, vmax=3900)
        ax.scatter(zombie_indices+.5, human_indices+.5, edgecolors='black', facecolors='none', alpha=.1)
    fig.suptitle(title, fontsize=16)
    # Add a subtitle slightly below the suptitle
    fig.tight_layout(rect=[0, 0, 1, 1])
    plt.show()
