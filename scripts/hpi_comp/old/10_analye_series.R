
series_ <- list(med = readRDS(file.path(getwd(), 'data', 'exp_10', 'med_series.RDS')),
                 psf = readRDS(file.path(getwd(), 'data', 'exp_10', 'psf_series.RDS')),
                 hem = readRDS(file.path(getwd(), 'data', 'exp_10', 'hem_series.RDS')),
                 rtm = readRDS(file.path(getwd(), 'data', 'exp_10', 'rtm_series.RDS')),
                 nn = readRDS(file.path(getwd(), 'data', 'exp_10', 'nn_series.RDS')),
                 hei = readRDS(file.path(getwd(), 'data', 'exp_10', 'hei_series.RDS')),
                 rfi = readRDS(file.path(getwd(), 'data', 'exp_10', 'rfi_series.RDS')))

approach <- names(series_)

rev_df <- purrr::map2(.x = series_,
                      .y = approach,
                      .f = function(x, y){
                        data.frame(approach = y,
                                   median = x$revision$median,
                                   mean = x$revision$mean,
                                   abs_median = x$revision$abs_median,
                                   abs_mean = x$revision$abs_mean)
                      }) %>% 
  dplyr::bind_rows()

pred_accr_df <- purrr::map2(.x = series_,
                            .y = approach,
                            .f = function(x, y){
                              x$pr_accuracy %>%
                                dplyr::mutate(approach = y)}) %>%
  dplyr::bind_rows()

rel_accr_df <- purrr::map2(.x = series_,
                            .y = approach,
                            .f = function(x, y){
                              x$rel_accuracy %>%
                                dplyr::mutate(approach = y)}) %>%
  dplyr::bind_rows()


rev_df

pred_accr_df %>%
  dplyr::group_by(approach) %>%
  dplyr::summarize(mdpe = median(log_error),
                   mpe = mean(log_error),
                   mdape = median(abs(log_error)),
                   mape = mean(abs(log_error)))

rel_accr_df %>%
  dplyr::group_by(approach, type) %>%
  dplyr::summarize(mdpe = median(error),
                   mpe = mean(error),
                   mdape = median(abs(error)),
                   mape = mean(abs(error)))





                            })


