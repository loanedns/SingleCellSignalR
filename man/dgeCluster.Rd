% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SCSRDataModel-class.R
\name{dgeCluster}
\alias{dgeCluster}
\alias{dgeCluster,SCSRDataModel-method}
\title{Differential Gene Expression}
\usage{
\S4method{dgeCluster}{SCSRDataModel}(
  obj,
  s.pval = 10^-2,
  most.variables = TRUE,
  write = FALSE,
  verbose = TRUE,
  plot = TRUE
)
}
\arguments{
\item{obj}{A SCSRDataModel object}

\item{s.pval}{A pvalue threshold}

\item{most.variables}{a logical}

\item{write}{A logical}

\item{verbose}{A logical}

\item{plot}{A logical}
}
\value{
A SCSRDataModel with cluster definition
}
\description{
Analysis of the differentially expressed genes in the clusters
}
\details{
Computes the diferential gene expression
between the clusters using **edgeR**)

If `most.variables` is TRUE, then the function uses the 
most variable genes matrix counts if it exists in the object.

If `write` is TRUE, then the
function writes a text file named 'table_dge_X.txt', where X is the 
cluster name, that contains the list of differentially expressed genes.
}
\examples{
message('dgeCluster')
message('--dataPrepare')
data <- matrix(runif(1000,0,1),nrow=50,ncol=20)
rownames(data) <- paste('gene',seq_len(50))
obj <- dataPrepare(data)
message('--add Clustering')
obj <- addClustering(obj,cluster.id = sample(1:5,size = 20,replace = TRUE))
if (FALSE) obj <- dgeCluster(obj)
}
