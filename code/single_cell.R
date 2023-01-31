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
params <- setParam(params, "de.prob", 0.25)
params <- setParam(params, "group.prob", c(1/4, 1/4, 1/4, 1/4)) #groups
sim <- splatSimulate(params, method="groups", verbose=FALSE)
sim <- logNormCounts(sim)
geneinfo_rna <- rowData(sim)
meta_rna <- colData(sim)
counts_rna <- assays(sim)[["logcounts"]]
counts_rna <- counts_rna[apply(counts_rna, 1, var) > 0, ]


# We add MCAR missing values on 15% of the data
amputed <- delete_MCAR(t(counts_rna), 0.15)
amputed <- data.frame(amputed)
amputed$group <- meta_rna$Group
#write.csv(x = amputed, file = "../data/singe_cell.csv")

original <- data.frame(t(counts_rna))
original$group <- meta_rna$Group
#write.csv(x = original, file = "../data/original.csv")

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




