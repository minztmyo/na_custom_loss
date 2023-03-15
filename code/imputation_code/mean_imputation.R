missing <- read.csv('../../data/MCAR/mcar10/mcar_10.csv', row.names = 1)

## Column Mean Imputation

mean_impute <- function(missing){
  imputed <- missing[,1:199]
  for(i in 1:ncol(imputed)) {
    imputed[ , i][is.na(imputed[ , i])] <- mean(imputed[ , i], na.rm = TRUE)
  }
  imputed$group <- missing[,200]
  return(imputed)
}

mean_imputed <- mean_impute(missing)
write.csv(mean_imputed, '../../data/MCAR/mcar10/mean_mcar_10.csv')

