library(ggplot2)
library(Metrics)
library(reshape2)

original <- read.csv('../../data/original.csv', row.names = 1)
missing <- read.csv('../../data/MCAR/mcar10/mcar_10.csv', row.names = 1)
imputed <- read.csv('../../data/MCAR/mcar10/mean_mcar_10.csv', row.names = 1)

## Index the missing values and find corresponding values in original and impute
results <- data.frame(
  original = as.numeric(original[is.na(missing)]),
  imputed = as.numeric(imputed[is.na(missing)])
)

## Calculate RMSE and Corr
rmse <- round(rmse(results$original, results$imputed),3)
correlation <- round(cor(results$original, results$imputed),3)

## Actual vs Imputed Scatter Plot
scatter <- ggplot(results, aes(original, imputed)) +
  geom_point(color = 'skyblue') +
  geom_abline(slope = 1, intercept = 0, color = 'red') +
  ggtitle('Actual vs Imputed Scatter Plot') +
  annotate(geom= "text", x = 2, y = 10,
           label = paste('RMSE = ', rmse, "\nCorr = ", correlation)) +
  theme_bw() +
  tune::coord_obs_pred()

ggsave('../../data/MCAR/mcar10/mean_scatter.png', scatter, width = 5, height = 5)

## Group Imputed Plot for Most Differentially Expressed Gene
# calculate Kruskal-Wallis test p-values for each gene
pvals <- apply(original[, 1:199], 2, function(x) kruskal.test(x ~ original$group)$p.value)
most_de_gene <- names(pvals)[which.min(pvals)]

miss_long <- melt(missing)
impute_long <- melt(imputed)
impute_long$imputed <- ifelse(is.na(miss_long$value), 'imputed', 'non-missing')
impute_long <- impute_long[which(impute_long$variable == most_de_gene),]

group_plot <- ggplot(impute_long) +
  geom_boxplot(aes(x = group, y = value))+
  geom_jitter(aes(x = group, y = value, color = imputed), width = 0.2) +
  labs(title = 'Scatter Plot by Group', x = 'Cell Group', y = 'log counts') +
  theme_bw()

ggsave('../../data/MCAR/mcar10/mean_group_plot.png', group_plot, width = 6, height = 4.5)
