mcar_10 <- read.csv('../../data/MCAR/mcar10/mcar_10.csv', row.names = 1)
mcar_25 <- read.csv('../../data/MCAR/mcar25/mcar_25.csv', row.names = 1)
mcar_40 <- read.csv('../../data/MCAR/mcar40/mcar_40.csv', row.names = 1)
mnar_30 <- read.csv('../../data/MNAR/mnar30/mnar_30.csv', row.names = 1)
mnar_50 <- read.csv('../../data/MNAR/mnar50/mnar_50.csv', row.names = 1)
mcar_path <- read.csv('../../data/path/mcar_40/path_mcar_40.csv', row.names = 1)
mnar_path <- read.csv('../../data/path/mnar_50/path_mnar_50.csv', row.names = 1)

## Column Mean Imputation
mean_impute <- function(missing){
  imputed <- missing[,1:(ncol(missing)-1)]
  imputed <- t(imputed)
  for(i in 1:ncol(imputed)) {
    imputed[ , i][is.na(imputed[ , i])] <- mean(imputed[ , i], na.rm = TRUE)
  }
  imputed <- data.frame(t(imputed))
  imputed$group <- missing[,ncol(missing)]
  return(imputed)
}

mcar_10i <- mean_impute(mcar_10)
mcar_25i <- mean_impute(mcar_25)
mcar_40i <- mean_impute(mcar_40)
mnar_30i <- mean_impute(mnar_30)
mnar_50i <- mean_impute(mnar_50)
mcar_pathi <- mean_impute(mcar_path)
mnar_pathi <- mean_impute(mnar_path)

write.csv(mcar_10i, '../../data/MCAR/mcar10/mean_mcar_10.csv')
write.csv(mcar_25i, '../../data/MCAR/mcar25/mean_mcar_25.csv')
write.csv(mcar_40i, '../../data/MCAR/mcar40/mean_mcar_40.csv')
write.csv(mnar_30i, '../../data/MNAR/mnar30/mean_mnar_30.csv')
write.csv(mnar_50i, '../../data/MNAR/mnar50/mean_mnar_50.csv')
write.csv(mcar_pathi, '../../data/path/mcar_40/mean_path_mcar.csv')
write.csv(mnar_pathi, '../../data/path/mnar_50/mean_path_mnar.csv')
