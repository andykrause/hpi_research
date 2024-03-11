idx <- ls()[grepl('_series', ls())]
series_ <- list()
series_names <- lapply(idx, function(x) {strsplit(x, '_')[1]}) %>%
  unlist()
series_names <- series_names[series_names != 'series']

for (i in 1:length(idx)){
  series_[[i]] <- get(idx[i])
  #rm(get(idx[i]))
}
names(series_) <- series_names

pr_accr <- list()
for(j in 1:length(series_names)){
  pr_accr[[j]] <- series_[[j]]$pr_accuracy %>%
    dplyr::mutate(model = series_names[j])
}

praccr_df <- pr_accr %>% dplyr::bind_rows()
praccr_df %>%
  dplyr::group_by(model) %>%
  dplyr::summarize(mdpe = median(log_error),
                   mdape = median(abs(log_error)))


rel_accr <- list()
for(j in 1:length(series_names)){
  rel_accr[[j]] <- series_[[j]]$rel_accuracy %>%
    dplyr::mutate(model = series_names[j])
}

relaccr_df <- rel_accr %>% dplyr::bind_rows()
relaccr_df %>%
  dplyr::group_by(type, model) %>%
  dplyr::summarize(mdpe = median(error),
                   mdape = median(abs(error)))


rev_ <- list()
for(j in 1:length(series_names)){
  rev_[[j]] <- data.frame(median = series_[[j]]$revision$median,
                          mean = series_[[j]]$revision$mean,
                          abs_median = series_[[j]]$revision$abs_median,
                          abs_mean = series_[[j]]$revision$abs_mean,
                          model = series_names[j])
}
rev_ %>% dplyr::bind_rows()




