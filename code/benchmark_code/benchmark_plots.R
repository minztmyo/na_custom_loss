library(ggplot2)
library(Metrics)
library(reshape2)

original <- read.csv('../../data/original.csv')
missing <- read.csv('../../data/MCAR/mcar10/mcar_10.csv')
imputed <- read.csv('../../data/MCAR/mcar10/mean_mcar_10.csv')

## Index the missing values and find corresponding values in original and impute
results <- data.frame(
  original = as.numeric(original[is.na(missing)]),
  imputed = as.numeric(imputed[is.na(missing)])
)

## Calculate RMSE and Corr
rmse <- rmse(results$original, results$imputed)
correlation <- cor(results$original, results$imputed)

## Actual vs Imputed Scatter Plot
ggplot(results, aes(orignal, imputed)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0) +
  ggtitle('Actual vs Imputed Scatter Plot') +
  theme_bw()



## Group Imputed Plot
miss_long <- melt(missing)
impute_long <- melt(imputed)
impute_long$imputed <- ifelse(is.na(miss_long$value), 'imputed', 'non-missing')

ggplot(impute_long, aes(x = variable, y = value, color = imputed)) +
  geom_jitter(width = 0.5) +
  labs(title = 'Scatter Plot by Group', x = 'Cell Group', y = 'log counts') +
  theme_bw()
