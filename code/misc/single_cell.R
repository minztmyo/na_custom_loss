# Load R libs ####
library(ggplot2)
library(keras)
library(scater)
library(splatter)
library(missMethods)

# Simulate data ####
# We are simulating Single Cell data with 4 groups of cells
# More info about simulation can be found on:
# https://www.bioconductor.org/packages/devel/bioc/vignettes/splatter/inst/doc/splatter.html
params <- newSplatParams()
params <- setParam(params, "nGenes", 300)
params <- setParam(params, "batchCells", 100)
params <- setParam(params, "dropout.type", 'none')
params <- setParam(params, "de.prob", 0.25)
params <- setParam(params, "group.prob", c(1/4, 1/4, 1/4, 1/4)) #groups
sim <- splatSimulate(params, method="groups", verbose=FALSE)
sim <- logNormCounts(sim)
geneinfo_rna <- rowData(sim)
meta_rna <- colData(sim)
counts_rna <- assays(sim)[["logcounts"]]
# counts_rna <- counts_rna[apply(counts_rna, 1, var) > 0, ]
counts_rna <- data.frame(t(counts_rna))

### Process Gene Data
gene <- data.frame(geneinfo_rna)

gene <- gene %>%
  mutate(param = case_when(
    DEFacGroup1 != 1 & DEFacGroup2 != 1 & DEFacGroup3 != 1 & DEFacGroup4 != 1 ~ 5,
    DEFacGroup1 != 1 ~ 1,
    DEFacGroup2 != 1 ~ 2,
    DEFacGroup3 != 1 ~ 3,
    DEFacGroup4 != 1 ~ 4,
    TRUE ~ 0  # all values are 1
  ))
#gene$param <- paste('DE_', gene$param)

write.csv(x = gene, file = "../../data/gene_info.csv")

# We add MCAR missing values on 10% of the data
amputed_10 <- delete_MCAR(counts_rna, 0.15)
amputed_10 <- data.frame(amputed_10)
amputed_10$group <- meta_rna$Group
write.csv(x = amputed_10, file = "../../data/mcar_10.csv")

# We add MCAR missing values on 25% of the data
amputed_25 <- delete_MCAR(counts_rna, 0.25)
amputed_25 <- data.frame(amputed_25)
amputed_25$group <- meta_rna$Group
write.csv(x = amputed_25, file = "../../data/mcar_25.csv")

# We add MCAR missing values on 40% of the data
amputed_40 <- delete_MCAR(counts_rna, 0.40)
amputed_40 <- data.frame(amputed_40)
amputed_40$group <- meta_rna$Group
write.csv(x = amputed_40, file = "../../data/mcar_40.csv")

counts_rna2 <- assays(sim)[["logcounts"]]
counts_rna2 <- counts_rna2[apply(counts_rna2, 1, var) > 0, ]
col_means <- colMeans(t(counts_rna2))
n <- length(col_means)
indexes <- order(col_means)[1:ceiling(n * 0.2)]
# We add MNAR missing values on 30% of the data
mcar_30 <- delete_MNAR_censoring(counts_rna, p = 0.30, cols_mis = indexes)
mcar_30 <- data.frame(mcar_30)
mcar_30$group <- meta_rna$Group
write.csv(x = mcar_30, file = "../../data/mnar_30.csv")

# We add MNAR missing values on 50% of the data
mnar50 <- delete_MNAR_censoring(counts_rna, p = 0.50, cols_mis = indexes)
mnar50 <- data.frame(mnar50)
mnar50$group <- meta_rna$Group
write.csv(x = mnar50, file = "../../data/mnar_50.csv")


# We simulate Paths

sim.paths <- splatSimulate(nGenes = 300, batchCells = 100,
                           de.prob = 0.1, de.facLoc = 1, dropout.type = "none",
                           mean.rate = 3, mean.shape = 3, out.prob = 0,
                           method = "paths", verbose = FALSE)
sim.paths <- logNormCounts(sim.paths)
geneinfo_rna <- rowData(sim.paths)
meta_rna2 <- colData(sim.paths)
counts_rna2 <- assays(sim.paths)[["logcounts"]]
#counts_rna2 <- counts_rna2[apply(counts_rna2, 1, var) > 0, ]
counts_rna2 <- data.frame(t(counts_rna2))

# We add MCAR missing values on 40% of the path data
path40 <- delete_MCAR(counts_rna2, 0.40)
path40 <- data.frame(path40)
path40$group <- meta_rna2$Group
write.csv(x = path40, file = "../../data/path_mcar_40.csv")

rna <- assays(sim.paths)[["logcounts"]]
rna <- rna[apply(rna, 1, var) > 0, ]
rna <- t(rna)
col_means <- colMeans(rna)
n <- length(col_means)
indexes <- order(col_means)[1:ceiling(n * 0.2)]
# We add MNAR missing values on 50% of the data
path50 <- delete_MNAR_censoring(counts_rna2, p = 0.50, cols_mis = indexes)
path50 <- data.frame(path50)
path50$group <- meta_rna2$Group
write.csv(x = path50, file = "../../data/path_mnar_50.csv")

df <- read.csv('../../data/mcar_10.csv', row.names = 1)
# df <- df[,1:100]
# df_scaled <- base::scale(df)
# write.csv(x = df_scaled, file = "../../data/mcar_scaled.csv")
# ori_scaled <- base::scale(original)

original <- data.frame(counts_rna)
original$group <- meta_rna$Group
write.csv(x = original, file = "../../data/original.csv")

original_path <- data.frame(counts_rna2)
original_path$group <- meta_rna2$Group
write.csv(x = original_path, file = "../../data/original_path.csv")
