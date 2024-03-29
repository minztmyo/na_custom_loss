library(reticulate)
my_module <- source_python("../imputation_code/ae_op.py")

mcar_10 <- read.csv('../../data/MCAR/mcar10/mcar_10.csv', row.names = 1)
mcar_25 <- read.csv('../../data/MCAR/mcar25/mcar_25.csv', row.names = 1)
mcar_40 <- read.csv('../../data/MCAR/mcar40/mcar_40.csv', row.names = 1)
mnar_30 <- read.csv('../../data/MNAR/mnar30/mnar_30.csv', row.names = 1)
mnar_50 <- read.csv('../../data/MNAR/mnar50/mnar_50.csv', row.names = 1)
mcar_path <- read.csv('../../data/path/mcar_40/path_mcar_40.csv', row.names = 1)
mnar_path <- read.csv('../../data/path/mnar_50/path_mnar_50.csv', row.names = 1)

# mcar_10 <- data.frame(scale(mcar_10[,1:199]), group = mcar_10[,200])
# mcar_25 <- data.frame(scale(mcar_25[,1:199]), group = mcar_25[,200])
# mcar_40 <- data.frame(scale(mcar_40[,1:199]), group = mcar_40[,200])
# mnar_30 <- data.frame(scale(mnar_30[,1:199]), group = mnar_30[,200])
# mnar_50 <- data.frame(scale(mnar_50[,1:199]), group = mnar_50[,200])
# mcar_path <- data.frame(scale(mcar_path[,1:199]), group = mcar_path[,200])
# mnar_path <- data.frame(scale(mnar_path[,1:199]), group = mnar_path[,200])

mcar_10i <- na_op_autoencoder(mcar_10)
mcar_25i <- na_op_autoencoder(mcar_25)
mcar_40i <- na_op_autoencoder(mcar_40)
mnar_30i <- na_op_autoencoder(mnar_30)
mnar_50i <- na_op_autoencoder(mnar_50)
mcar_pathi <- na_op_autoencoder(mcar_path)
mnar_pathi <- na_op_autoencoder(mnar_path)

write.csv(mcar_10i, '../../data/MCAR/mcar10/aeop_mcar_10.csv')
write.csv(mcar_25i, '../../data/MCAR/mcar25/aeop_mcar_25.csv')
write.csv(mcar_40i, '../../data/MCAR/mcar40/aeop_mcar_40.csv')
write.csv(mnar_30i, '../../data/MNAR/mnar30/aeop_mnar_30.csv')
write.csv(mnar_50i, '../../data/MNAR/mnar50/aeop_mnar_50.csv')
write.csv(mcar_pathi, '../../data/path/mcar_40/aeop_path_mcar.csv')
write.csv(mnar_pathi, '../../data/path/mnar_50/aeop_path_mnar.csv')
