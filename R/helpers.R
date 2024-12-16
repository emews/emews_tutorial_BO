library(ggplot2)
library(dplyr)
library(reshape2)
library(MASS) 
library(yaml)
library(jsonlite)

# Scale matrix within specified bounds
to_native <- function(x, lb = c(0.1, 1), ub = c(1, 3)) {
  x_native <- matrix(NA, nrow = nrow(x), ncol = ncol(x))
  for (i in seq_len(ncol(x))) {
    x_native[, i] <- lb[i] + x[, i] * (ub[i] - lb[i])
  }
  return(x_native)
}

# Generate inputs in required format for EMEWS
generate_inputs <- function(Xgrid, ids, seed_tracker, seeds, lb = c(0.1, 1), ub = c(1, 3)) {
  Xgrid_native <- to_native(Xgrid, lb = lb, ub = ub)
  Xs <- list()
  id_table <- table(ids)
  for (cix in names(id_table)) {
    cnt <- id_table[[cix]]
    ix <- as.numeric(cix)
    start <- seed_tracker[[ix]] + 1
    end <- seed_tracker[[ix]] + cnt
    seed_tracker[[ix]] <- seed_tracker[[ix]] + cnt
    
    for (s in seeds[start:end]) {
      Xs <- append(Xs, list(c(Xgrid[ix, ], s, ix)))
    }
  }
  X <- do.call(rbind, Xs)
  Xnative <- cbind(to_native(X[, 1:2]), X[, 3])
  return(list(X = X[, 1:2], Xnative = Xnative))
}


# Thomspon sample
TS_npoints <- function(model, npoints, Xgrid) {
  preds <- predict(model, Xgrid, xprime=Xgrid)
  pred_mean <- preds$mean
  pred_cov <- preds$cov
  
  cov_mtx <- 0.5 * (pred_cov + t(pred_cov))
  tTS <- mvrnorm(n = npoints, mu = as.vector(pred_mean), Sigma = cov_mtx)
  return(apply(tTS, 1, which.max))
}


# Plot mean surface/variance
plot_gp <- function(model, Xgrid, X, ymean = 0, ystd = 1, title = NULL) {
  Xgrid_native <- to_native(Xgrid)
  X_native <- to_native(X)
  
  df <- as.data.frame(Xgrid_native)
  colnames(df) <- c("zombie_step_size", "human_step_size")
  
  preds <- predict(model, Xgrid, xprime=Xgrid)
  pred_mean <- preds$mean * ystd + ymean
  
  df$Std <- sqrt(preds$sd2)
  df$`Surviving Humans` <- exp(pred_mean)

  p1 <- ggplot() +
    geom_tile(data = df, aes(x = zombie_step_size, y = human_step_size, fill = `Surviving Humans`)) +
    geom_point(data = as.data.frame(X_native), aes(x = V1, y = V2), color = "black", alpha=.2, shape=1, size=3) +
    scale_fill_gradient(low = "lightblue", high = "cornflowerblue") +
    labs(title = 'Mean Surface', x = "Zombie Step Size", y = "Human Step Size", fill=NULL) +
    theme_minimal() + 
    theme(legend.box.spacing = unit(0.1, "lines"),
          legend.margin = margin(0, 0, 0, 0),
          plot.title = element_text(hjust = 0.5))
  
  p2 <- ggplot() +
    geom_tile(data = df, aes(x = zombie_step_size, y = human_step_size, fill = Std)) +
    geom_point(data = as.data.frame(X_native), aes(x = V1, y = V2), color = "black", alpha=.2, shape=1, size=3) +
    scale_fill_gradient(low = "#E0FFE0", high = "seagreen") +
    labs(title = 'Variance', x = "Zombie Step Size", y = "Human Step Size", fill=NULL) +
    theme_minimal() + 
    theme(legend.box.spacing = unit(0.1, "lines"),
          legend.margin = margin(0, 0, 0, 0),
          plot.title = element_text(hjust = 0.5))
  
  plots <- list(mean_surface=p1, pred_var=p2)
  return(plots)
}