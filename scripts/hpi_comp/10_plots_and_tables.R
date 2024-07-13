#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Create Tables and Plots
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 ## Load libraries

  library(tidyverse)

 ## Read in results data 
  
  index_df <- readRDS(file = file.path(getwd(), 'data', 'exp_10', 'results_index.RDS'))
  series <- readRDS(file = file.path(getwd(), 'data', 'exp_10', 'results_series.RDS'))
  subm <- readRDS(file = file.path(getwd(), 'data', 'exp_10', 'results_submarket.RDS'))

### Set parameters ---------------------------------------------------------------------------------  

  ## Set Colors
  color_df <- data.frame(method = c('med', 'psf', 'hem', 'rtm', 'nnm', 'hei', 'rfi'),
                         colorx = c('darkorange2', 'orange', 'blue4', 'dodgerblue', 'skyblue', 
                                    'purple', 'orchid'))

  ## Set other parameters
  
  model_names <-  c('Agg: Med', 'Agg: PSF', 'TME: Rep', 'TME: OLS',
                    'TME: NN', 'Imp: OLS', 'Imp: RF')
  model_relevel <- c('med', 'psf', 'rtm', 'hem', 'nnm', 'hei', 'rfi')
  method_df <- 
    data.frame(method = model_relevel,
               method_name = model_names)
  
  month_labs <- paste0('Dec-', 2013:2023)
  plotwidth <- 1960
  plotheight <- 860
  bg_col <- 'gray80'
  line_size <- 1.8
  text_size <- 24

### Set Plot Templates --------------------------  
  
  method_base_plot <- 
    ggplot() + 
    theme_minimal() + 
    theme(text=element_text(size = text_size),
          legend.position = 'bottom') +
    scale_x_discrete(labels = model_names) + 
    xlab('\n Index Method') 
  
### Index Comparison -------------------------------------------------------------------------------

  ## Re-order levels
  
  # County
  index_df <- index_df %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) 
  
  # Submarket
  indexS_df <- subm$index_df %>%
    dplyr::left_join(., subm$stl_df %>%
                       dplyr::rename(time_period = period), 
                     by = c('time_period', 'approach', 'subm')) %>%
    dplyr::rename(method = approach) %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) %>%
    dplyr::left_join(., method_df, by = 'method')
  
 #### Set Base Plot -------------------  

  index_base_plot <- 
    ggplot() + 
    theme_minimal() + 
    theme(text=element_text(size = 24),
          legend.position = 'bottom') +
    coord_cartesian(ylim = c(95, 270)) + 
    scale_x_continuous(breaks = seq(0, 120, by = 12),
                       labels = month_labs) + 
    xlab('') + 
    ylab('Index\n') 
    
 #### Median Index ------------

  ## Select data
  med_idf <- index_df %>%
    dplyr::filter(method == 'med')
  cidx <- 1
  
  ## Build plot
  medindex_plot <- 
   index_base_plot + 
   geom_line(data = med_idf,
             aes(x = time_period, y = index, color = method),
             size = line_size) + 
   scale_color_manual(name = 'Index Method',
                      values = color_df$colorx[cidx],
                      labels = model_names[cidx]) + 
   ggtitle('Median Sales Price Index', subtitle = "King County, WA")
  
  ## Plot and Save
  medindex_plot
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'med_index.png'), 
                                width = plotwidth, height = plotheight) 
  dev.off()
 
 #### PSF Index ------------

   ## Select Data
   psf_idf <- index_df %>%
     dplyr::filter(method == 'psf')
   base_idf <- index_df %>%
     dplyr::filter(method == 'med') 
   cidx <- 2
 
   ## Built Plot
   psfindex_plot <- 
     index_base_plot +
     geom_line(data = base_idf, 
               aes(x = time_period, y = index), 
               color = bg_col,
               size = line_size) + 
     geom_line(data = psf_idf,
               aes(x = time_period, y = index, color = method),
               size = line_size) + 
     scale_color_manual(name = 'Index Method',
                      values = color_df$colorx[cidx],
                      labels = model_names[cidx]) + 
     ggtitle('Median Sales Price per SqFt ($/SF) Index', subtitle = "King County, WA")
  
   ## Plot and Save
   psfindex_plot
   dev.copy(device = png, 
            filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'psf_indexes.png'), 
            width = plotwidth, height = plotheight) 
   dev.off()

 #### TME Indexes ------------
  
  ## Select Data
  tme_idf <- index_df %>%
    dplyr::filter(method %in% c('rtm', 'hem', 'nnm'))
  base_idf <- index_df %>%
    dplyr::filter(method %in% c('med', 'psf')) 
  cidx <- 3:5
  
  ## Built Plot
  tmeindex_plot <- 
    index_base_plot +
    geom_line(data = base_idf, 
              aes(x = time_period, y = index, group = method), 
              color = bg_col,
              size = line_size) + 
    geom_line(data = tme_idf,
              aes(x = time_period, y = index, color = method),
              size = line_size) + 
    scale_color_manual(name = 'Index Method',
                       values = color_df$colorx[cidx],
                       labels = model_names[cidx]) + 
    ggtitle('Trained Model Extraction Indexes', subtitle = "King County, WA")
  
  ## Plot and Save
  tmeindex_plot
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'tme_indexes.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
  
 #### Imputation Indexes ------------   
 
  ## Select Data
  imp_idf <- index_df %>%
    dplyr::filter(method %in% c('hei', 'rfi'))
  base_idf <- index_df %>%
    dplyr::filter(!method %in% c('hei', 'rfi')) 
  cidx <- 6:7

  ## Built Plot
  impindex_plot <- 
    index_base_plot +
    geom_line(data = base_idf, 
              aes(x = time_period, y = index, group = method), 
              color = bg_col,
              size = line_size) + 
    geom_line(data = imp_idf,
              aes(x = time_period, y = index, color = method),
              size = line_size) + 
    scale_color_manual(name = 'Index Method',
                       values = color_df$colorx[cidx],
                       labels = model_names[cidx]) + 
    ggtitle('Imputation Indexes', subtitle = "King County, WA")
  
  ## Plot and Save
  impindex_plot
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'imp_indexes.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
  
 #### All Index (County) -----------------------
  
  ## Built Plot
   allindex_plot <- 
    index_base_plot +
    geom_line(data = index_df, 
              aes(x = time_period, y = index, color = method, group = method), 
              size = line_size) + 
    scale_color_manual(name = 'Index Method',
                       values = color_df$colorx,
                       labels = model_names) #+ 
    #ggtitle('All Indexes', subtitle = "King County, WA")
  
  ## Plot and Save
  allindex_plot
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'all_indexes.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
  
 #### All Index Zoomed (County) -----------------------
  
  ## Built Plot
  allindexzoom_plot <- 
    index_base_plot +
    geom_line(data = index_df, 
              aes(x = time_period, y = index, color = method, group = method), 
              size = line_size) + 
    scale_color_manual(name = 'Index Method',
                       values = color_df$colorx,
                       labels = model_names) + 
    coord_cartesian(xlim = c(84, 120),
                    ylim = c(150, 260)) #+ 
    #ggtitle('All Indexes (Zoomed)', subtitle = "King County, WA")
  
  ## Plot and Save
  allindexzoom_plot
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'all_indexeszoom.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
  
 #### Submarket Indexes ------------------------
  sub_index_plot <- 
    index_base_plot + 
    coord_cartesian(ylim = c(75, 350)) + 
    geom_line(data = indexS_df,
              aes(x = time_period, y = index, color = method, group = subm),
              size = .4,
              alpha = .5,
              show.legend = FALSE) + 
    facet_wrap(~method_name, ncol = 4) + 
    scale_color_manual(name = 'Index Method',
                       values = color_df$colorx[c(6,4,1,5,2, 7,3)],
                       labels = model_names) + 
    scale_x_continuous(breaks = seq(12, 108, by = 48),
                       labels = paste0('Dec-', c(2014, 2018, 2022))) + 
    geom_line(data = index_df %>%
                dplyr::left_join(., method_df, by = 'method'),
              aes(x = time_period, y = index, group = method), color = 'black') #+ 
   # ggtitle('All Indexes', subtitle = "18 Submarkets in King County, WA")
  
  sub_index_plot 
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'subm_indexes.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()

### Volatility --------------------------------------------------------------------------- 
 
 #### Trend Plot -----------------------------

  trend_plot <-   
  ggplot() + 
    theme_minimal() + 
    theme(text=element_text(size = text_size),
          legend.position = 'bottom') +
    coord_cartesian(ylim = c(95, 270)) + 
    scale_x_continuous(breaks = seq(0, 120, by = 12),
                       labels = month_labs) + 
    geom_line(data = index_df,
              aes(x = time_period, y = trend, color = method),
              size = line_size)  + 
    scale_color_manual(values = color_df$colorx,
                       labels = model_names,
                       name = 'Index Approach') +
    ylab('Trend \n (w/o Seasonality and Noise)')  +
    xlab('') + 
   # ggtitle('Index Trend Comparisons') + 
    theme(legend.position = 'bottom')  
  
  trend_plot
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'trend_comparison.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
  
 #### Seasonality --------------
  
  ## Prep Data
  seas_df <- index_df %>%
    dplyr::mutate(geo = 'all') %>%
    dplyr::left_join(., method_df, by = 'method') %>%
    dplyr::bind_rows(., indexS_df %>%
                       dplyr::mutate(geo = 'subm'))
  season_plot <- 
    method_base_plot + 
    geom_hline(yintercept = 0, linetype = 3, color = 'black') +
    geom_line(data = seas_df, 
                 aes(x = geo, y = seasonal, color = method, alpha = geo),
                 size = 14,
                 show.legend = FALSE) +  
    facet_wrap(~method_name, nrow=1) + 
    scale_x_discrete(labels = c('All', 'Subm')) + 
    scale_alpha_manual(values = c(1,.4)) + 
    #scale_color_manual(values = c('black', 'gray60')) + 
    scale_color_manual(values = color_df$colorx[c(6,4,1,5,2, 7,3)]) +
    ylab('Seasonality Range\n Index Points\n') + 
    xlab('') + 
   # ggtitle('Seasonality Range', subtitle = 'All County vs Submarkets') + 
    theme(legend.position = 'none')
  
  season_plot
  
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'season_comparison.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
  
 #### Volatility Plot ----------
  
  vol_plot <- 
    method_base_plot + 
    geom_hline(yintercept = 0, linetype = 3, color = 'black') +
    geom_boxplot(data = seas_df, 
              aes(x = geo, y = remainder, color = geo, fill=method, alpha = geo),
              size = 1,
              show.legend = FALSE) +  
    facet_wrap(~method_name, nrow=1) + 
    scale_x_discrete(labels = c('All', 'Subm')) + 
    scale_alpha_manual(values = c(1,.4)) + 
    scale_color_manual(values = c('black', 'gray60')) + 
    scale_fill_manual(values = color_df$colorx[c(6,4,1,5,2, 7,3)]) +
    ylab('Volatility Range\n Index Points\n') + 
    xlab('') + 
    coord_cartesian(ylim = c(-15, 15)) + 
    #ggtitle('Volatility Range', subtitle = 'All County vs Submarkets') + 
    theme(legend.position = 'none')
  
  vol_plot
  
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'vol_comparison.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
  
 #### Directional Volatility Plot ----------
  
  dvol_plot <- 
    method_base_plot + 
    geom_boxplot(data = index_df, 
                 aes(x = method, y = remainder, fill = method),
                 show.legend = FALSE,
                 color = 'black') + 
    scale_fill_manual(values = color_df$colorx,
                      labels = model_names,
                      name = '') +
    ylab('Volatility \n (Remainder)') + 
    coord_cartesian(ylim = c(-6, 6)) + 
    ggtitle('Directional Index Volatility', 
            subtitle = 'Remainder of Seasonal/Trend Decomposition')
  
  dvol_plot
  
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'dirvol_comparison.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()

### Revision ---------------------------------------------------------------------------------------  
  
  rev_df <- series$rev_df %>%
   dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) 
  
  revS_df <- subm$rev_df %>%
    dplyr::group_by(method, class) %>%
    dplyr::summarize(median = mean(median),
                     abs_median = mean(abs_median),
                     mean = mean(mean),
                     abs_mean = mean(abs_mean)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) 
  
  rev_sdf <- rev_df %>%
    dplyr::mutate(geo = 'all') %>%
    dplyr::bind_rows(., revS_df %>%
                       dplyr::mutate(geo = 'subm')) %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel))
  
  rev_plot <-
    method_base_plot + 
    geom_bar(data = rev_df, 
             aes(x = method, y = abs_mean, fill=method),
             stat = 'identity',
             show.legend = FALSE) + 
    scale_fill_manual(values = color_df$colorx,
                     labels = model_names) +
    geom_bar(data = revS_df, 
             aes(x = method, y = abs_mean, fill=method),
             stat = 'identity',
             alpha = .4,
             show.legend = FALSE) + 
    scale_fill_manual(values = color_df$colorx,
                      labels = model_names) +
    ylab('Mean Absolute Revision Level\n') +
    theme(legend.position = 'none')
  rev_plot
  
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'rev_comparison.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
    
### Prediction errors ------------------------------------------------------------------------------
  
  ## Prep Data
  
  # County
  pred_df <- series$abs_df %>%
    as.data.frame()
  
  pred_sdf <- pred_df %>%
    dplyr::group_by(method) %>%
    dplyr::summarize(count = dplyr::n(), 
                     mdpe = median(error),
                     mpe = mean(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error))) %>%
    dplyr::mutate(method = as.factor(method)) %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) 
  
  # Submarkets
  predS_df <- subm$abs_df %>%
    as.data.frame()
  
  predS_sdf <- predS_df %>%
    dplyr::group_by(method) %>%
    dplyr::summarize(count = dplyr::n(),
                     mdpe = median(error),
                     mpe = mean(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error))) %>%
    dplyr::mutate(method = as.factor(method)) %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) 
  
  # Make Plot
  pred_plot <- 
    method_base_plot + 
    geom_bar(data = pred_sdf,
             aes(x = method, y = mape, color = method, fill = method),
             alpha = .15,
             show.legend = FALSE,
             stat = 'identity') + 
    geom_bar(data = predS_sdf,
             aes(x = method, y = mape, color = method, fill = method),
             #alpha = .15,
             stat = 'identity',
             show.legend = FALSE) + 
    coord_cartesian(ylim = c(.09, .12)) + 
    scale_fill_manual(values = color_df$colorx)+
    scale_color_manual(values = color_df$colorx) + 
    ylab('Mean Absolute Predictive Error\n') + 
    annotate('text', x = 5, y = .119, color = 'red', size = 12,
             label = "Opaque = Submarket\nTransparent = Full County")# + 
   # ggtitle('Predictive Error', 
   #         subtitle = 'Prediction On Resale')
  
  pred_plot

  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'predacc_comparison.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
  
### Assistive Accuracy -----------------------------------------------------------------------------
  
  ast_df <- series$rel_df %>%
    dplyr::filter(type != 'base') %>%
    as.data.frame()
  
  ast_sdf <- ast_df %>%
  dplyr::group_by(method) %>%
    dplyr::summarize(mdpe = median(error),
                     mpe = mean(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error)),
                     count = dplyr::n()) %>%
    dplyr::mutate(method = as.factor(method)) %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) 

  astS_df <- subm$rel_df %>%
    as.data.frame() %>%
    dplyr::filter(type != 'base')
  
  astS_sdf <- astS_df %>%
    dplyr::group_by(method) %>%
    dplyr::summarize(count = dplyr::n(),
                     mdpe = median(error),
                     mpe = mean(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error)))
  astS_sdf <- astS_sdf %>%
    dplyr::mutate(method = as.factor(method)) %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) 
  
  astS_plot <- 
    method_base_plot + 
    geom_bar(data = astS_sdf,
             aes(x = method, y = mape, color = method, fill = method),
             stat = 'identity',
             show.legend = FALSE) + 
    geom_bar(data = ast_sdf,
             aes(x = method, y = mape, color = method, fill = method),
             alpha = .15,
             show.legend = FALSE,
             stat = 'identity') + 
    geom_bar(data = ast_sdf %>%
               dplyr::filter(method == 'rtm'),
             aes(x = method, y = mape),
             color = 'white',
             fill = 'white',
             alpha = .35,
             show.legend = FALSE,
             stat = 'identity') + 
    coord_cartesian(ylim = c(.115, .135)) + 
    scale_fill_manual(values = color_df$colorx) +
    scale_color_manual(values = color_df$colorx) + 
    ylab('Mean Absolute Assistive Error\n') + 
    annotate('text', x = 5, y = .1325, color = 'red', size = 12,
             label = "Opaque = Submarket\nTransparent = Full County") #+ 
    #ggtitle('Assistive Error', subtitle = 'AVM Error Using Index')
  
  astS_plot
  
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'asterror_comparison.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()

### All Errors --------------------------
  
  alle_sdf <- ast_sdf %>%
    dplyr::select(method, ast_mape = mape) %>%
    dplyr::left_join(., pred_sdf %>%
                       dplyr::select(method, pred_mape = mape),
                     by = 'method') %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) %>%
    dplyr::arrange(method) %>%
    dplyr::mutate(ast_imp = 1-ast_mape/ast_mape[1],
                  pred_imp = 1-pred_mape/pred_mape[1],
                  geo = 'county')
  alle_sdf

  alleS_sdf <- astS_sdf %>%
    dplyr::select(method, ast_mape = mape) %>%
    dplyr::left_join(., predS_sdf %>%
                       dplyr::select(method, pred_mape = mape),
                     by = 'method') %>%
    dplyr::mutate(method = forcats::fct_relevel(method, model_relevel)) %>%
    dplyr::arrange(method) %>%
    dplyr::mutate(ast_imp = 1-ast_mape/ast_mape[1],
                  pred_imp = 1-pred_mape/pred_mape[1],
                  geo = 'subm')
  alleS_sdf
  
  allex_sdf <- alleS_sdf %>%
    dplyr::bind_rows(alle_sdf)
    
  errcomp_plot <- 
    ggplot() + 
    theme_minimal() + 
    theme(text=element_text(size = text_size+12),
          legend.position = 'bottom') +
    geom_point(data = allex_sdf %>% 
                 dplyr::filter(method != 'med'),
             aes(x = pred_imp, y = ast_imp, color = method, shape = geo),
             size = 16) + 
    scale_shape_manual(values = c(15,17),
                       name = '',
                       labels = c('All County', 'Submarkets')) + 
    scale_color_manual(name = '',
                       values = color_df$colorx[2:7],
                       labels = model_names[2:7]) + 
    #scale_alpha_manual(values = c(1, .4)) + 
    #coord_cartesian(xlim = c(0.035, 0.082),
    #                ylim = c(0.035, .06)) + 
    scale_x_continuous(breaks = seq(0.04, 0.1, by =.01),
                     labels = paste0(4:10, "%")) + 
    scale_y_continuous(breaks = seq(-0.04, 0.1, by =.01),
                       labels = paste0(-4:10, "%")) + 
    geom_hline(yintercept = 0, linetype = 'dashed') + 
    ylab('Assistive Error % Improvement \nover Median Index\n') + 
    xlab('\nPredictive Error % Improvement \nover Median Index')
    
  errcomp_plot  
  
  dev.copy(device = png, 
           filename = file.path(getwd(), 'papers', 'hpi_comp', 'figures', 'error_comparison.png'), 
           width = plotwidth, height = plotheight) 
  dev.off()
  
 