library("biomaRt")
mart <- biomaRt::useMart(biomart = "plants_mart", dataset = "athaliana_eg_gene", host = 'plants.ensembl.org')
GTOGO <- biomaRt::getBM(attributes = c( "ensembl_gene_id", "go_id"), mart = mart)
head(GTOGO)
GTOGO <- GTOGO[GTOGO$go_id != '',]
geneID2GO <- by(GTOGO$go_id, GTOGO$ensembl_gene_id, function(x) as.character(x))

all.genes <- sort(unique(as.character(GTOGO$ensembl_gene_id)))
int.genes <- sample(x = all.genes, size = 200) # some random genes 
int.genes <- factor(as.integer(all.genes %in% int.genes))
names(int.genes) = all.genes

go.obj <- new("topGOdata", ontology='BP'
              , allGenes = int.genes
              , annot = annFUN.gene2GO
              , gene2GO = geneID2GO
)

results <- runTest(go.obj, algorithm = "elim", statistic = "fisher")

results.tab <- GenTable(object = go.obj, elimFisher = results)
