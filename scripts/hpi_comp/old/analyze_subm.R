
subm_ <- list(med = readRDS(file.path(getwd(), 'data', 'exp_10', 'med_submarket.RDS')),
                psf = readRDS(file.path(getwd(), 'data', 'exp_10', 'psf_submarket.RDS')),
                hem = readRDS(file.path(getwd(), 'data', 'exp_10', 'hem_submarket.RDS')),
                rtm = readRDS(file.path(getwd(), 'data', 'exp_10', 'rtm_submarket.RDS')),
                hei = readRDS(file.path(getwd(), 'data', 'exp_10', 'hei_submarket.RDS')),
                rfi = readRDS(file.path(getwd(), 'data', 'exp_10', 'rfi_submarket.RDS')))


approaches <- names(subm_)


stl_df <- purrr::map2(.x = subm_,
                      .y = approaches,
                      .f = function(x,y){
                        x$stl %>%
                          dplyr::mutate(approach = y)
                      }) %>%
  dplyr::bind_rows()

stl_df %>%
  dplyr::group_by(approach) %>%
  dplyr::summarize(mean_vol = mean(volatility),
                   med_vol = median(volatility))

stl_df %>%
  dplyr::group_by(approach) %>%
  dplyr::summarize(mean_vol = mean(remainder),
                   med_vol = median(remainder),
                   meana_vol = mean(abs(remainder)),
                   meda_vol = median(abs(remainder)))


rev_df <- purrr::map2(.x = subm_,
                       .y = approaches,
                       .f = function(x,y){
                         x$revision %>%
                           dplyr::mutate(approach = y)
                       }) %>%
  dplyr::bind_rows()

rev_df %>%
  dplyr::group_by(approach) %>%
  dplyr::summarize(median = median(median),
                   mean = median(mean),
                   abs_median = median(abs_median),
                   abs_mean = median(abs_mean))



absa_df <- purrr::map2(.x = subm_,
                       .y = approaches,
                       .f = function(x,y){
                         x$absacc %>%
                           dplyr::mutate(approach = y)
                       }) %>%
  dplyr::bind_rows()

absa_df %>%
  dplyr::group_by(approach) %>%
  dplyr::summarize(mdpe = median(error),
                   mdape = median(abs(error)))


rela_df <- purrr::map2(.x = subm_,
                       .y = approaches,
                       .f = function(x,y){
                         x$relacc %>%
                           dplyr::mutate(approach = y)
                       }) %>%
  dplyr::bind_rows()

rela_df %>%
  dplyr::group_by(approach, type) %>%
  dplyr::summarize(count = dplyr::n(),
                   mdpe = median(error),
                   mdape = median(abs(error)))
