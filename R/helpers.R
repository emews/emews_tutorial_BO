library(ggplot2)
library(dplyr)
library(reshape2)
library(MASS) # for mvrnorm
library(yaml)
library(jsonlite)

to_native <- function(x, lb = c(0.1, 1), ub = c(1, 3)) {
  x_native <- matrix(NA, nrow = nrow(x), ncol = ncol(x))
  for (i in seq_len(ncol(x))) {
    x_native[, i] <- lb[i] + x[, i] * (ub[i] - lb[i])
  }
  return(x_native)
}

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

# Define `run_reps`
run_reps <- function(ids, seeds) {
  X <- list()
  Y <- list()
  
  for (s in seeds) {
    X <- append(X, list(Xgrid[ids, ]))
    Y <- append(Y, list(Ygrid[ids, s]))
  }
  
  X <- do.call(rbind, X)
  Y <- unlist(Y)
  return(list(X = X, Y = Y))
}


scale_y <- function(Y) {
  Y_scaled <- (Y - mean(Y)) / sd(Y)
  return(list(Y_scaled = Y_scaled, stats = c(mean = mean(Y), sd = sd(Y))))
}

initial_samples <- function(n = 5, grid_size = 30, init_id = NULL) {
  xx <- seq(0, 1, length.out = grid_size)
  Xgrid <- expand.grid(xx, xx)
  
  if (is.null(init_id)) {
    N <- nrow(Xgrid)
    init_id <- sample(1:N, n, replace = FALSE)
  }
  
  return(list(Xinit = Xgrid[init_id, ], Xgrid = Xgrid))
}

to_01 <- function(X) {
  min_vals <- apply(X, 2, min)
  max_vals <- apply(X, 2, max)
  scale <- max_vals - min_vals
  X_scaled <- sweep(sweep(X, 2, min_vals, "-"), 2, scale, "/")
  return(X_scaled)
}


TS_npoints <- function(model, npoints, Xgrid) {
  preds <- predict(model, Xgrid, xprime=Xgrid)
  pred_mean <- preds$mean
  pred_cov <- preds$cov
  
  cov_mtx <- 0.5 * (pred_cov + t(pred_cov))
  tTS <- mvrnorm(n = npoints, mu = as.vector(pred_mean), Sigma = cov_mtx)
  return(apply(tTS, 1, which.max))
}


plot_gp_mean <- function(model, Xgrid, X, ymean = 0, ystd = 1, logged = TRUE, title = NULL) {
  Xgrid_native <- to_native(Xgrid)
  X_native <- to_native(X)
  
  df <- as.data.frame(Xgrid_native)
  colnames(df) <- c("zombie_step_size", "human_step_size")
  
  preds <- predict(model, Xgrid, xprime=Xgrid)
  pred_mean <- preds$mean * ystd + ymean
  
  if (logged) {
    df$surface <- exp(pred_mean)
  }
  
  p <- ggplot() +
    geom_tile(data = df, aes(x = zombie_step_size, y = human_step_size, fill = surface)) +
    geom_point(data = as.data.frame(X_native), aes(x = V1, y = V2), color = "black", alpha=.1, shape=1, size=3) +
    scale_fill_gradient(low = "lightblue", high = "cornflowerblue") +
    labs(title = title, x = "Zombie Step Size", y = "Human Step Size") +
    theme_minimal()
  
  return(p)
}