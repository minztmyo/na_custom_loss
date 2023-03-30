library(missForest)

mcar_10 <- read.csv('../../data/MCAR/mcar10/mcar_10.csv', row.names = 1)
mcar_25 <- read.csv('../../data/MCAR/mcar25/mcar_25.csv', row.names=1)
mcar_40 <- read.csv('../../data/MCAR/mcar40/mcar_40.csv', row.names=1)
mnar_30 <- read.csv('../../data/MNAR/mnar30/mnar_30.csv', row.names=1)
mnar_50 <- read.csv('../../data/MNAR/mnar50/mnar_50.csv', row.names=1)
mcar_path <- read.csv('../../data/path/mcar_40/path_mcar_40.csv', row.names=1)
mnar_path <- read.csv('../../data/path/mnar_50/path_mnar_50.csv', row.names=1)

## Column msf Imputation
msf_impute <- function(missing){
  imputed <- missing[,1:199]
  imputed <- missForest(imputed)$ximp
  imputed$group <- missing[,200]
  return(imputed)
}

mcar_10im <- msf_impute(mcar_10)
mcar_25im <- msf_impute(mcar_25)
mcar_40im <- msf_impute(mcar_40)
mnar_30im <- msf_impute(mnar_30)
mnar_50im <- msf_impute(mnar_50)
mcar_pathim <- msf_impute(mcar_path)
mnar_pathim <- msf_impute(mnar_path)

write.csv(mcar_10im, '../../data/MCAR/mcar10/missForest_mcar_10.csv')
write.csv(mcar_25im, '../../data/MCAR/mcar25/missForest_mcar_25.csv')
write.csv(mcar_40im, '../../data/MCAR/mcar40/missForest_mcar_40.csv')
write.csv(mnar_30im, '../../data/MNAR/mnar30/missForest_mnar_30.csv')
write.csv(mnar_50im, '../../data/MNAR/mnar50/missForest_mnar_50.csv')
write.csv(mcar_pathim, '../../data/path/mcar_40/missForest_path_mcar.csv')
write.csv(mnar_pathim, '../../data/path/mnar_50/missForest_path_mnar.csv')
