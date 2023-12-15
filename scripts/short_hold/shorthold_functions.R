#***************************************************************************************************
#
#  Functions for creating steele and goy replication
#
#***************************************************************************************************

steeleGoy <- function(sales_df,
                     control_reno = FALSE,
                     weight_max = 48,
                     aggregation = 'monthly',
                     min_period_dist = 1){

  ## Create Data  
  
  hed_df <- hedCreateTrans(trans_df = sales_df,
                           prop_id = 'pinx',
                           trans_id = 'sale_id',
                           price = 'sale_price',
                           date = 'sale_date',
                           periodicity = aggregation)

  rt_df <- rtCreateTrans(trans_df = sales_df,
                         prop_id = 'pinx',
                         trans_id = 'sale_id',
                         price = 'sale_price',
                         date = 'sale_date',
                         periodicity = aggregation,
                         seq_only = TRUE,
                         min_period_dist = min_period_dist)

  ## Add span and reno data to rt data
  rt_df <- rt_df %>%
    dplyr::mutate(span = period_2 - period_1,
                  yearspan = span / 12)
  rt_df$age1 <- hed_df$eff_age[match(rt_df$trans_id1, hed_df$trans_id)]
  rt_df$age2 <- hed_df$eff_age[match(rt_df$trans_id2, hed_df$trans_id)]
  rt_df$reno <- ifelse(rt_df$age2 < rt_df$yearspan, 1, 0)

  ## Create a list of renovated data
   reno_df <- rt_df %>%
     dplyr::filter(reno == 1)
  rt_df <- rt_df %>% dplyr::filter(reno == 0) 

  ## Add reno data to hedonic data
  hed_df$reno <- 'None'
  hed_df$reno[hed_df$trans_id %in% reno_df$trans_id1] <- 'After'
  hed_df$reno[hed_df$trans_id %in% reno_df$trans_id2] <- 'Before'
  hed_df <- hed_df %>% dplyr::filter(reno == 'None')
  
  # Add time status
  hed_df <- hed_df %>%
    dplyr::mutate(status = ifelse(trans_id %in% rt_df$trans_id1 & 
                                    !trans_id %in% rt_df$trans_id2, 'First',
                                     ifelse(trans_id %in% rt_df$trans_id2 & 
                                              !trans_id %in% rt_df$trans_id1, 'Second',
                                            ifelse(trans_id %in% rt_df$trans_id1 & 
                                                     trans_id %in% rt_df$trans_id2, 'Both', 
                                                   'None'))),
                  status = forcats::fct_relevel(status, 'None', 'Both', 'First', 'Second'))

  hed_df <- hed_df %>%
    dplyr::left_join(., rt_df %>%
                       dplyr::select(trans_id = trans_id2, prev_sale = span),
                     by = 'trans_id') %>%
    dplyr::left_join(., rt_df %>%
                       dplyr::select(trans_id = trans_id1, next_sale = span),
                     by = 'trans_id')

  hed_df$span <- ifelse(hed_df$status == 'First', hed_df$next_sale, 
                        ifelse(hed_df$status == 'Second', -hed_df$prev_sale, NA))

  ## Hedonic Models
  hed_formula <- log(price) ~ as.factor(present_use) + as.factor(area) + log(sqft_lot + 1) + 
    log(sqft + 1) + wfnt + grade + beds + 
    I(bath_full + (.75 * bath_3qtr) + (.5 * bath_half)) + eff_age + 
    as.factor(trans_period)
  
  hed_lm <- lm(hed_formula, data = hed_df)
  
  rtx <- which(hed_df$status %in% c('First', 'Second'))
  pl_df <- data.frame(span = hed_df$span[rtx],
                      error = hed_lm$residuals[rtx]) %>%
    dplyr::mutate(first = ifelse(span >= 0, 1, 0))

  error_lm <- lm(hed_lm$residuals ~ as.factor(hed_df$status))
  
  # hed2_formula <- update(hed_formula, . ~ . + status)
  # hed2_lm <- lm(hed2_formula, data = hed_df)
  gamma <- as.numeric(error_lm$coefficients[grepl('Second', names(error_lm$coefficients))] - 
         error_lm$coefficients[grepl('First', names(error_lm$coefficients))])
  
  # Create the Repeat Sales Model (original)
  rt_df <- structure(rt_df, class = c('rtdata', 'hpidata', 'data.frame'))
  time_matrix <- rtTimeMatrix(rt_df)
  price_diff <- log(rt_df$price_2) - log(rt_df$price_1)
  rt_model <- stats::lm(price_diff ~ time_matrix + 0)

  # Create standard adjustment
  A <- solve(t(time_matrix) %*% time_matrix)
  R <- A %*% t(time_matrix) %*% rep(1, nrow(time_matrix))
  Ry <- gamma * R

  # Weighted Version
  tm_df <- time_matrix
  max_span = max(rt_df$span)
  for(i in 1:nrow(time_matrix)){tm_df[i, ] <- tm_df[i, ] * (1- (rt_df$span[i] / max_span))}
  R <- A %*% t(tm_df) %*% rep(1, nrow(tm_df))
  Rw <- gamma * R

  # Nonlinear weight
  # tm_df <- time_matrix
  # res_sdf <- pl_df %>% 
  #   dplyr::group_by(span) %>% 
  #   dplyr::filter(first == 1) %>% 
  #   dplyr::summarize(m = mean(error))
  # rts <- filter(ts(res_sdf$m, start=1), sides = 2, filter=rep(1/3,3))
  # nl_span <- min(which(rts > 0))
  # 
  # for(i in 1:nrow(time_matrix)){
  #   tm_df[i, ] <- tm_df[i, ] * ifelse(rt_df$span[i] <= nl_span,
  #                                     (1- (rt_df$span[i] / max_span)), 0)
  # }
  # R <- A %*% t(tm_df) %*% rep(1, nrow(tm_df))
  # Rz <- hed_lm$gamma * R
  # 
  # Convert all to Indexes
  rt_index <- 100 * (1 + exp(rt_model$coef) - 1)
  rtb_index <- 100 * (1 + exp(rt_model$coef - Ry) - 1)
  rtw_index <- 100 * (1 + exp(rt_model$coef - Rw) - 1)
  # rtz_index <- 100 * (1 + exp(rt_model$coef - Rz) - 1)
  hed_index <- 100 * (1 + exp(hed_lm$coefficients[grepl('trans_period', 
                                                        names(hed_lm$coefficients))]) - 1)

  # Simplify to plot df
  plot_df <- data.frame(model = c(rep('Standard', length(rt_index) + 1),
                                  rep('SteeleGoy', length(rtb_index) + 1),
                                  rep('WgtBias', length(rtw_index) + 1),
                                  rep('Hedonic', length(rtw_index) + 1)),
                        index = c(c(100, rt_index), c(100, rtb_index), c(100, rtw_index),
                                  c(100, hed_index)),
                        time = rep(1:(length(rt_index) + 1), 4)) %>%
  dplyr::mutate(model = forcats::fct_relevel(model, 'Standard', 'SteeleGoy', 'WgtBias', 
                                             'Hedonic'))
  # Return
  list(indexes = plot_df,
       plot_df = pl_df,
       lm = hed_lm,
       gamma = gamma,
       rt = rt_model,
       hed_df = hed_df,
       rt_df = rt_df)
}

