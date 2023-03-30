library(ggplot2)
library(patchwork)

dir_path <- "../../outputs"
subfolders <- list.dirs(dir_path, recursive=TRUE)[-1]
desired_word <- "rmse"

df <- list()
for (j in seq_along(subfolders)) {
  files <- list.files(subfolders[j], pattern = desired_word,
                      full.names = TRUE)
  data <- read.csv(files)
  data$imputation <- basename(subfolders[j])
  df[[j]] <- data
}

df <- do.call(rbind, df)
df$RMSE <- ifelse(df$RMSE > 10, NA, df$RMSE)
df$correlation <- ifelse(df$correlation < 0.3, NA, df$correlation)

rmse <- ggplot(df, aes(x = imputation, y = RMSE, color = imputation)) +
  geom_boxplot() +
  facet_grid(~X) + theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

correlation <- ggplot(df, aes(x = imputation, y = correlation,
                              color = imputation)) +
  geom_boxplot() +
  facet_grid(~X) + theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

(rmse/correlation) + plot_annotation('NA Imputation Benchmark Results')

