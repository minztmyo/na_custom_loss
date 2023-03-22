# Load R libs ####
library(glmnet)
library(data.table)
library(ggplot2)
library(reticulate)

# Load Depmap data ####
load("/Users/lukas/OneDrive/Documents/GitHub/depmap_app/data/global.RData")

# Source python code ####
my_module <- source_python("/Users/lukas/Downloads/ae_op.py")

highly_expressed <- tail(names(sort(apply(rnaseq, 2, mean))), 5000)
rna <- t(rnaseq[, highly_expressed])

total_entries <- nrow(rna)*ncol(rna)

missing <- sample(total_entries, round(total_entries*0.05))
tmp <- t(data.frame(rna))

scale <- function(matr) t(apply(matr, 1, function(x)
  (x -mean(x))/sd(x)))
scale2 <- function(matr) t(apply(matr, 1, function(x)
  (x - min(x, na.rm = T))/(max(x, na.rm = T) - min(x, na.rm = T))))

#tmp <- scale2(tmp)

tmp[missing] <- NA
tmp <- scale2(tmp)

rna_imputed <- t(na_op_autoencoder(tmp))

aframe <- data.frame(imputed = rna_imputed[missing],
                     original = scale2(rna)[missing])
ggplot(aframe, aes(imputed, original)) +
  labs(title = "DepMap RNA",
       subtitle = "Scaled input") +
  geom_hex(bins = 100) +
  viridis::scale_fill_viridis(trans = "log10") +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_abline(slope = 1, intercept = 0, color = "red") +
  theme_classic()

# Filter protein data ####
cell_na <- apply(protein, 1, function(x) mean(is.na(x)))
gene_na <- apply(protein, 2, function(x) mean(is.na(x)))
to_be_imputed <- names(which(gene_na > 0 & gene_na < 0.25))

tmp <- protein[, gene_na  < 0.25]
protein_imputed <- na_op_autoencoder(tmp)
colnames(protein_imputed) <- colnames(tmp)
rownames(protein_imputed) <- rownames(tmp)

pca <- prcomp(protein_imputed[, match(to_be_imputed, colnames(tmp))])

uData <- umap::umap(pca$x[,1:20])
aframe <- data.frame(sample_info[match(rownames(tmp), sample_info$DepMap_ID), ],
                     uData$layout)
ggplot(aframe, aes(X1, X2, color = lineage)) +
  geom_point() +
  theme_classic()

expr <- t(protein_imputed[, match(to_be_imputed, colnames(tmp))])
ok <- names(which(gene_na > 0.2 & gene_na < 0.25))

gene <- "CLDN3"
aframe <- data.frame(sample_info[match(rownames(tmp), sample_info$DepMap_ID), ],
                     gene = protein_imputed[, match(gene, colnames(tmp))])
aframe$imputed <- "no"
nas <- names(which(is.na(protein[, gene])))
aframe$imputed[match(nas, aframe$DepMap_ID)] <- "yes"

good_tissues <- names(which(table(aframe$lineage) > 20))

ggplot(aframe[aframe$lineage %in% good_tissues, ],
       aes(imputed, gene,
           color = imputed, group = imputed)) +
  facet_wrap(~ lineage, nrow = 1) +
  labs(title = gene) +
  geom_boxplot() + geom_jitter(height = 0.1) +
  theme_classic()


res <- t(apply(protein_imputed[, match(ok, colnames(protein_imputed))], 2, function(x){
  aframe <- data.frame(sample_info[match(rownames(tmp), sample_info$DepMap_ID), ],
                       gene = x)
  aframe <- aframe[aframe$lineage %in% c("skin", "blood"), ]
  coefficients(summary(lm(gene ~ lineage, data = aframe)))[2, c(1, 4)]
}))
res <- data.frame(res)
colnames(res) <- c("coef", "pval")
res <- res[sort.list(res$pval), ]

sig <- rownames(res)[1:20]
row_ord <- order(res[sig, 1])

aframe <- data.frame(sample_info[match(rownames(tmp), sample_info$DepMap_ID), ])

col_ord <- c(which(aframe$lineage == "skin"),
             which(aframe$lineage == "blood"))

anno_col <- aframe
rownames(anno_col) <- aframe$DepMap_ID

expr <- t(protein_imputed[, match(sig, colnames(protein_imputed))])

pheatmap(expr[row_ord, col_ord],
         scale = "row", breaks = seq(-2, 2, length = 100),
         cluster_rows = F, 
         cluster_cols = F, 
         main = "Imputed",
         show_rownames = T, show_colnames = F)

expr <- t(protein[, match(sig, colnames(protein))])

pheatmap(expr[row_ord, col_ord],
         scale = "row", breaks = seq(-2, 2, length = 100),
         cluster_rows = F, 
         cluster_cols = F, main = "Original",
         show_rownames = T, show_colnames = F)
