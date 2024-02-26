

base_index_df <- readRDS(file = file.path(getwd(), 'data', 'exp_10', 'indexes_df.RDS'))

ggplot()+
  geom_line(data=base_index_df %>% dplyr::select(-class),
            aes(time_period, index, group = approach), color="grey") +
  geom_line(data=base_index_df,
            aes(x=time_period, y=index, color=approach, group = approach))+
  facet_wrap(~class, nrow=3) + 
  theme(legend.position = 'bottom')

ggplot()+
  geom_boxplot(data=base_index_df, aes(x = approach, y = volatility))

  geom_line(data=base_index_df %>% dplyr::select(-class),
            aes(time_period, volatility, group = approach), color="grey") +
  geom_line(data=base_index_df,
            aes(x=time_period, y=volatility, color=approach, group = approach))+
  facet_wrap(~class, nrow=3) + 
  theme(legend.position = 'bottom')
