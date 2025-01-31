% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SCSRDataModel-class.R
\name{cellClustering}
\alias{cellClustering}
\alias{cellClustering,SCSRDataModel-method}
\title{Clustering}
\usage{
\S4method{cellClustering}{SCSRDataModel}(
  obj,
  n.cluster = 0,
  n = 10,
  most.variables = TRUE,
  projection.method = "tsne",
  method = c("simlr", "kmeans"),
  classification = c("none", "by cluster", "singler"),
  markers = markers_default,
  verbose = TRUE,
  plot = TRUE,
  pdf = FALSE,
  write = FALSE
)
}
\arguments{
\item{obj}{an object of class SCSRDataModel}

\item{n.cluster}{a number, an estimation of the ideal number of 
clusters is computed if equal to 0}

\item{n}{a number, the maximum to consider for an automatic 
determination of the ideal number of clusters}

\item{most.variables}{a logical}

\item{projection.method}{'tsne'}

\item{method}{'kmeans' or 'simlr'}

\item{classification}{the method to use for annotation 
(by cluster or a library), 'none' to not do annotation}

\item{markers}{a data frame of cell type signature genes}

\item{verbose}{a logical}

\item{plot}{a logical}

\item{pdf}{a logical}

\item{write}{a logical}
}
\value{
A SCSRDataModel with cluster definition
}
\description{
Identifies the cell clusters, i.e. the cell subpopulations.
}
\details{
If the user knows the number of clusters present in her data set,
then `n.cluster` can be set and the estimation of the number of clusters is
skipped. `n` is the maximum number of clusters that the automatic estimation
of the number of clusters will consider.

It is ignored if `n.cluster` is provided. `method` must be 
'simlr' or 'kmeans' exclusively. If set to 'simlr', then the function uses
the **SIMLR()** function (**SIMLR** package) to perform clustering.

If set to 'kmeans' the function will perform a
dimensionality reduction by principal component analysis (PCA) followed by
K-means clustering and 2-dimensional projection by t-distributed stochastic
neighbor embedding (t-SNE). Regardless of the value of `method` ('simlr' or
'kmeans'), in case `n.cluster` is not provided, then the function relies on
the **SIMLR_Estimate_Number_of_Clusters()** function to determine the number
of clusters, between 2 and `n`.

If `plot` is TRUE, then the function displays
the t-SNE map with each cell colored according to the cluster it belongs to.

If `method` argument is 'simlr', then it further displays a heatmap
of thesimilarity matrix calculated by the **SIMLR()** function.

If `pdf` is TRUE, then the function exports
the t-SNE plot in a pdf file in the *images* folder. The file is named
't-SNE_map-X.pdf', where X is the `method` argument.

If `write` is TRUE, then the function writes two text files in the
*data* folder. The first one is called 'cluster-Y-X.txt', containing the
cluster vector assigning each cell of `data` to a cluster. The second one is
called 'tsne-Y-X.txt', containing the coordinates of each cell in the 2D
t-SNE projection. 'X' is the `method` argument anf 'Y' is the retained 
number of clusters.

If `most.variables` is TRUE, then the function uses the most 
variable genes matrix counts if it exists in the object.

If the user want to do cluster annotation the classification method
and celltype marker table must be provided.

The ` markers` argument must be a table with cell type gene 
signatures, one cell type in each column. The column names are the names 
of the cell types.

The *markers.default* table provides an example of this format.

The`classification` argument must be one of 'by cluster', or 
'library'. 'by cluster' will assign each cluster to a celltype by comparing 
the overall expression with markers given in ` markers`
'library' will use the package *insert package name* to perform the 
labelling.

If `write` is TRUE and classification is not equal to 'none', 
then the function writes in a second text file a table containing 
probabilities of assignments of each cluster to a cell type for each cell
cluster. This cell type calling is performed as for the individual cells 
without thresholding but based on the cluster average transcriptome.
}
\examples{
message('cellClustering')
message('--dataPrepare')
data <- matrix(runif(1000,0,1),nrow=50,ncol=20)
rownames(data) <- paste('gene',seq_len(50))
obj <- dataPrepare(data)
message('--cell Clustering')
obj <- cellClustering(obj)
}
