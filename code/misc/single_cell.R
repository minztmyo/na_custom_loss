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
set.seed(4367)
params <- newSplatParams()
params <- setParam(params, "nGenes", 200)
params <- setParam(params, "dropout.type", 'none')
params <- setParam(params, "de.prob", 0.25)
params <- setParam(params, "group.prob", c(1/4, 1/4, 1/4, 1/4)) #groups
sim <- splatSimulate(params, method="groups", verbose=FALSE)
sim <- logNormCounts(sim)
geneinfo_rna <- rowData(sim)
meta_rna <- colData(sim)
counts_rna <- assays(sim)[["logcounts"]]
counts_rna <- counts_rna[apply(counts_rna, 1, var) > 0, ]


# We add MCAR missing values on 10% of the data
amputed_10 <- delete_MCAR(t(counts_rna), 0.10)
amputed_10 <- data.frame(amputed_10)
amputed_10$group <- meta_rna$Group
write.csv(x = amputed_10, file = "../../data/mcar_10.csv")

# We add MCAR missing values on 25% of the data
amputed_25 <- delete_MCAR(t(counts_rna), 0.25)
amputed_25 <- data.frame(amputed_25)
amputed_25$group <- meta_rna$Group
write.csv(x = amputed_25, file = "../../data/mcar_25.csv")

# We add MCAR missing values on 40% of the data
amputed_40 <- delete_MCAR(t(counts_rna), 0.40)
amputed_40 <- data.frame(amputed_40)
amputed_40$group <- meta_rna$Group
write.csv(x = amputed_40, file = "../../data/mcar_40.csv")

rna <- t(counts_rna)
col_means <- colMeans(rna)
n <- length(col_means)
indexes <- order(col_means)[1:ceiling(n * 0.2)]
# We add MNAR missing values on 30% of the data
amputed_30 <- delete_MNAR_censoring(rna, p = 0.30, cols_mis = indexes)
amputed_30 <- data.frame(amputed_30)
amputed_30$group <- meta_rna$Group
write.csv(x = amputed_30, file = "../../data/mnar_30.csv")

# We add MNAR missing values on 50% of the data
amputed_30 <- delete_MNAR_censoring(rna, p = 0.50, cols_mis = indexes)
amputed_30 <- data.frame(amputed_30)
amputed_30$group <- meta_rna$Group
write.csv(x = amputed_30, file = "../../data/mnar_50.csv")


# We simulate Paths

sim.paths <- splatSimulate(nGenes = 199, batchCells = 100,
                           de.prob = 0.1, de.facLoc = 1, dropout.type = "none",
                           mean.rate = 3, mean.shape = 3, out.prob = 0,
                           method = "paths", verbose = FALSE)
sim.paths <- logNormCounts(sim.paths)
geneinfo_rna <- rowData(sim.paths)
meta_rna2 <- colData(sim.paths)
counts_rna2 <- assays(sim.paths)[["logcounts"]]
counts_rna2 <- counts_rna2[apply(counts_rna2, 1, var) > 0, ]

# We add MCAR missing values on 40% of the path data
amputed_40 <- delete_MCAR(t(counts_rna2), 0.40)
amputed_40 <- data.frame(amputed_40)
amputed_40$group <- meta_rna$Group
write.csv(x = amputed_40, file = "../../data/path_mcar_40.csv")

rna <- t(counts_rna2)
col_means <- colMeans(rna)
n <- length(col_means)
indexes <- order(col_means)[1:ceiling(n * 0.2)]
# We add MNAR missing values on 50% of the data
amputed_30 <- delete_MNAR_censoring(rna, p = 0.50, cols_mis = indexes)
amputed_30 <- data.frame(amputed_30)
amputed_30$group <- meta_rna$Group
write.csv(x = amputed_30, file = "../../data/path_mnar_50.csv")



original <- data.frame(t(counts_rna))
original$group <- meta_rna$Group
write.csv(x = original, file = "../../data/original.csv")

original_path <- data.frame(t(counts_rna2))
original_path$group <- meta_rna2$Group
write.csv(x = original_path, file = "../../data/original_path.csv")

# Scale the data ####
scale <- function(matr) {
  t(apply(matr, 1, function(x) (x - min(x)) / (max(x) - min(x))))
}
x_train <- t(scale(counts_rna))


## Autoencoder

enc_input = layer_input(shape = ncol(x_train))
enc_output = enc_input %>% 
  layer_dense(units = 128, activation = "relu") %>%
  layer_dense(units = 32, activation = "relu") %>%
  layer_dense(units = 2, activation = "relu")

encoder = keras_model(enc_input, enc_output)

dec_input = layer_input(shape = 2)
dec_output = dec_input %>% 
  layer_dense(units = 32, activation = "relu") %>% 
  layer_dense(units = 128, activation = "relu") %>% 
  layer_dense(units = ncol(x_train), activation = "sigmoid") 

decoder = keras_model(dec_input, dec_output)

aen_output = enc_input %>% 
  encoder() %>% 
  decoder()

aen = keras_model(enc_input, aen_output)
summary(aen)

aen %>% compile(optimizer = "adam", loss = "binary_crossentropy")

aen %>% fit(x_train, x_train, epochs = 200, batch_size = 32,
            validation_split = 0.2)

reddim <- predict(encoder, x_train)
aframe <- data.frame(reddim,
                     condition = meta_rna$Group)

# Plot the embedding
ggplot(aframe, aes(X1, X2, group = condition,
                            color = condition)) +
  geom_point() +
  theme_bw()




