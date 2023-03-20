library(ggplot2)
library(Metrics)
library(reshape2)
library(patchwork)
library(cowplot)
library(ggtext)

ori_g <- read.csv('../../data/original.csv', row.names = 1)
ori_p <- read.csv('../../data/original_path.csv', row.names = 1)
mcar_10 <- read.csv('../../data/MCAR/mcar10/mcar_10.csv', row.names = 1)
mcar_25 <- read.csv('../../data/MCAR/mcar25/mcar_25.csv', row.names = 1)
mcar_40 <- read.csv('../../data/MCAR/mcar40/mcar_40.csv', row.names = 1)
mnar_30 <- read.csv('../../data/MNAR/mnar30/mnar_30.csv', row.names = 1)
mnar_50 <- read.csv('../../data/MNAR/mnar50/mnar_50.csv', row.names = 1)
mcar_path <- read.csv('../../data/path/mcar_40/path_mcar_40.csv', row.names = 1)
mnar_path <- read.csv('../../data/path/mnar_50/path_mnar_50.csv', row.names = 1)

mcar_10i <- read.csv('../../data/MCAR/mcar10/mean_mcar_10.csv', row.names = 1)
mcar_25i <- read.csv('../../data/MCAR/mcar25/mean_mcar_25.csv', row.names = 1)
mcar_40i <- read.csv('../../data/MCAR/mcar40/mean_mcar_40.csv', row.names = 1)
mnar_30i <- read.csv('../../data/MNAR/mnar30/mean_mnar_30.csv', row.names = 1)
mnar_50i <- read.csv('../../data/MNAR/mnar50/mean_mnar_50.csv', row.names = 1)
mcar_pathi <- read.csv('../../data/path/mcar_40/mean_path_mcar.csv', row.names = 1)
mnar_pathi <- read.csv('../../data/path/mnar_50/mean_path_mnar.csv', row.names = 1)

missing_list <- list(mcar_10 = mcar_10, mcar_25 = mcar_25, mcar_40 = mcar_40,
                     mnar_30 = mnar_30, mnar_50 = mnar_50,
                     mcar_path = mcar_path, mnar_path = mnar_path
                     )
imputed_list <- list(mcar_10 = mcar_10i, mcar_25 = mcar_25i, mcar_40 = mcar_40i,
                     mnar_30 = mnar_30i, mnar_50 = mnar_50i,
                     mcar_path = mcar_pathi, mnar_path = mnar_pathi
                     )

original_list <- list(mcar_10 = ori_g, mcar_25 = ori_g, mcar_40 = ori_g,
                      mnar_30 = ori_g, mnar_50 = ori_g,
                      mcar_path = ori_p, mnar_path = ori_p
                     )

results_df <- data.frame(RMSE = numeric(), correlation = numeric(),
                         row.names = character())

scatter_table <- list()

# Loop through the list of data frames
for (i in seq_along(imputed_list)) {
  # Get the name of the current data frame
  df_name <- names(imputed_list)[i]
  imputed <- imputed_list[[i]]
  missing <- missing_list[[i]]
  original <- original_list[[i]]
  # Index the missing values and find corresponding values in original and impute
  results <- data.frame(
    original = as.numeric(original[is.na(missing)]),
    imputed = as.numeric(imputed[is.na(missing)])
  )
  # Save the results to use in the plots
  scatter_table[[df_name]] <- results
  # Calculate the RMSE and correlation for the current data frame
  rmse <- round(rmse(results$original, results$imputed),3)
  correlation <- round(cor(results$original, results$imputed),3)
  
  # Add the results to the results data frame
  results_df[df_name, "RMSE"] <- rmse
  results_df[df_name, "correlation"] <- correlation
}

write.csv(results_df, '../../outputs/mean/rmse_cor.csv')

### Scatter Plot

scatter <- function(data){
  name <- data
  data <- imputed_list[[data]]
  rmse <- results_df[name,1]
  correlation <- results_df[name,2]
  scatter_results <- scatter_table[[name]]
  # Plot the Scatter Plot
  ggplot(scatter_results, aes(original, imputed)) +
    geom_point(color = 'skyblue') +
    geom_abline(slope = 1, intercept = 0, color = 'red') +
    labs(title = name) + xlim(0,15)+
    annotate(geom= "text", x = 4, y = 10,
             label = paste('RMSE = ', rmse, "\nCorr = ", correlation)) +
    theme_bw() +
    tune::coord_obs_pred()
}


scatter_list <- lapply(names(imputed_list), scatter)
combined_plot <- plot_grid(plotlist = scatter_list, nrow = 2)
title_theme <- ggdraw() +
  draw_label("Column Mean Imputation", 
             fontface = "bold", x = 0.05, hjust = 0)
scatter_plot <- plot_grid(title_theme, combined_plot,
                          ncol = 1, rel_heights = c(0.2, 1))

ggsave('../../outputs/mean/scatter.png', scatter_plot,
       width = 10, height = 7)

### Group Imputed Plot for Most Differentially Expressed Gene
# calculate Kruskal-Wallis test p-values for each gene
pvals <- apply(ori_g[, 1:199], 2,
               function(x) kruskal.test(x ~ ori_g$group)$p.value)
most_de_gene <- names(pvals)[which.min(pvals)]
low_gene <- names(which.min(colMeans(ori_g[,1:199])))
gene_list <- c(mcar_10 = most_de_gene, mcar_25 = most_de_gene,
               mcar_40 = most_de_gene, mnar_30 = low_gene, mnar_50 = low_gene)


group_plot <- function(data){
  name <- data
  most_gene <- gene_list[data]
  missing <- missing_list[[data]]
  data <- imputed_list[[data]]
  miss_long <- melt(missing)
  impute_long <- melt(data)
  impute_long$imputed <- ifelse(is.na(miss_long$value), 'imputed', 'non-missing')
  impute_long <- impute_long[which(impute_long$variable == most_gene),]
  
  ggplot(impute_long) +
    geom_boxplot(aes(x = group, y = value))+
    geom_jitter(aes(x = group, y = value, color = imputed), width = 0.2) +
    labs(title = name, x = 'Cell Group', y = 'log counts') +
    theme_bw()
}
  
group_list <- lapply(names(imputed_list)[1:5], group_plot)
combined_grouped_plot <- plot_grid(plotlist = group_list, nrow = 2)
title_theme <- ggdraw() +
  draw_label("Column Mean Imputation", 
             fontface = "bold", x = 0.05, hjust = 0)
group_plots <- plot_grid(title_theme, combined_grouped_plot,
                          ncol = 1, rel_heights = c(0.2, 1))

ggsave('../../outputs/mean/group_plots.png', group_plots,
       width = 15, height = 7)  
  