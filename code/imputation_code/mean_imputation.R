missing <- read.csv('../../data/MCAR/mcar10/mcar_10.csv')

## Column Mean Imputation

mean_impute <- function(missing){
  imputed <- missing[,1:200]
  for(i in 1:ncol(imputed)) {
    imputed[ , i][is.na(imputed[ , i])] <- mean(imputed[ , i], na.rm = TRUE)
  }
  row.names(imputed) <- imputed$X
  imputed <- imputed[,-1]
  imputed$group <- missing[,201]
  return(imputed)
}

mean_imputed <- mean_impute(missing)
write.csv(mean_imputed, '../../data/MCAR/mcar10/mean_mcar_10.csv')

