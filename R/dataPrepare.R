#' @title Data Prepare
#' @description Prepares the data for further analysis
#'
#' @details `file` is either the path to the file containing the read or UMI 
#' count matrix the user wants to analyze or directly the count matrix.
#' @details
#' `most.variables` can be set to N to select the Nth most variables genes. 
#' This option allows the user to use a reduced matrix (N x number of cells) to
#' perform the clustering step faster.
#' @details
#' `lower` and `upper` are used to remove the genes whose average counts are 
#' outliers. The values of these arguments are fractions of the total number of 
#' genes and hence must be between 0 and 1. Namely, if `lower = 0.05`, then the 
#' function removes the 5% less expressed genes and if `upper = 0.05`, then the 
#' function removes the 5% most expressed genes.
#' @details
#' If `write` is TRUE, then the function writes two text files. One for the
#' normalized and gene thresholded read counts table and another one for the
#' genes that passed the lower and upper threshold. Note that the length of the
#' genes vector written in the *genes.txt* file is equal to the number of rows
#' of the table of read counts written in the *data.txt* file.
#'
#' @param file either a string for the scRNAseq data file or a count matrix
#' @param species the species to which the data corresponds
#' @param most.variables a number of most variable genes to keep
#' @param formating quantile, library (not functionnal yet) or none
#' @param lower a number in [0,1], low quantile threshold
#' @param upper a number in [0,1], high quantile threshold
#' @param method.ortho    3 choices are available ('gprofiler','homologene',
#' 'babelgene') gprofiler is set by  default.
#' @param write a logical
#' @param verbose a logical
#' @param plot a logical
#' 
#' @return The function returns an object of type SCSRDataModel.
#'
#' @export
#'
#' @import data.table
#'
#' @examples
#' message('dataPrepare')
#' data <- matrix(runif(1000,0,1),nrow=50,ncol=20)
#' rownames(data) <- paste('gene',seq_len(50))
#' obj <- dataPrepare(data)

dataPrepare <- function(file, species = "hsapiens", most.variables = 0,
    formating = c("quantile", "library", "none"), lower = 0,
    upper = 0, method.ortho = c("gprofiler", "homologene", "babelgene"),
    write = FALSE, verbose = TRUE, plot = FALSE) {


    if (dir.exists("data") == FALSE & write == TRUE) {
        dir.create("data")
    }

    if (is.matrix(file) | is.data.frame(file)) {
        data <- file
    } else if (file.exists(file)) {
        data <- fread(file, data.table = FALSE)
    } else {
        stop(file, " doesn't exist.")
    }
    spec <- NULL
    # If genes are written in a column, pass it as rownames
    # and remove column
    for (i in seq_len(ncol(data))) {
        if (!is.character(data[, i])) {
            p <- i - 1
            break
        }
    }
    if (p != 0) {
        colCheck <- data[, p]
        data <- data[, -c(seq_len(p))]
        genes <- colCheck
        rownames(data) <- genes
    } else {
        colCheck <- rownames(data)
    }

    data <- subset(data, !duplicated(colCheck))
    genes <- rownames(data)


    formating <- match.arg(formating)

    # Apply chosen normalization method
    if (formating == "quantile") {
        data <- data[rowSums(data) > 0, ]
        data <- data.frame(data[, apply(data, 2, function(x) quantile(x,
            0.99)) > 0])

        message("Log-Normalization")
        q <- apply(data, 2, quantile, 0.99)
        data <- log(1 + sweep(data, 2, q/median(q), "/"))

        data <- data[rowSums(data) > 0, ]
        data <- data[rowSums(data) <= quantile(rowSums(data),
            1 - upper) & rowSums(data) >= quantile(rowSums(data),
            lower), ]
        spec <- list(Lower = lower, Upper = upper)
    } else if (formating == "library") {
        # Add library that does normalization
    }

    homolog.genes <- NULL
    homolog.genes.mv <- NULL

    # Convert genes to human in the counts matrix and store
    # original gene names
    if (species != "hsapiens") {
        method.ortho <- match.arg(method.ortho)
        message("Converting data to human data:")
        conversion.dict <- .findOrthoGenes(from_organism = species,
            from_values = rownames(data), method = method.ortho)

        dataGene <- .convertToHuman(data, conversion.dict)
        dataGene <- dataGene[c("Gene.name", setdiff(names(dataGene),
            "Gene.name"))]
        homolog.genes <- as.character(dataGene$Gene.name)
        data <- dataGene[, -1]
    }

    if (verbose == TRUE) {
        message(dim(data)[1], " genes")
        message(dim(data)[2], " cells")
        message("Zero rate = ", round(sum(data == 0) * 
            1000/prod(dim(data)))/10, "%")
    }
    if (write == TRUE) {
        fwrite(data.frame(data), "./data/data.txt", sep = "\t")
        fwrite(data.frame(rownames(data)), "./data/genes.txt",
            sep = "\t")
    }

    # Select most variable genes
    if (most.variables != 0 & most.variables >= 1) {
        m <- apply(data, 1, mean)
        cv <- apply(data, 1, sd)/m
        names(cv) <- rownames(data)

        cvGenes <- cv
        if (species != "hsapiens")
            names(cvGenes) <- dataGene$Gene.name

        cv <- cv[m > quantile(m, 0.5)]
        if (species != "hsapiens")
            cvGenes <- cvGenes[m > quantile(m, 0.5)]

        if (length(cv) < most.variables) {
            mv.genes <- names(cv)
            if (species != "hsapiens")
                homolog.genes.mv <- names(cvGenes)
        } else {
            mv.genes <- names(sort(cv, 
                decreasing = TRUE))[seq_len(most.variables)]
            if (species != "hsapiens")
                homolog.genes.mv <- names(sort(cvGenes, 
                    decreasing = TRUE))[seq_len(most.variables)]
        }
        mv.genes <- names(sort(cv, decreasing = TRUE))[seq_len(most.variables)]
        if (species != "hsapiens")
            homolog.genes.mv <- names(sort(cvGenes, 
                decreasing = TRUE))[seq_len(most.variables)]

        res <- list(data, data[mv.genes, ])
        names(res) <- c("complete.dataset", "most.var.dataset")
        mat <- as.matrix(res[[1]])
        mat.mv <- as.matrix(res[[2]])
        genes.mv <- rownames(as.matrix(res[[2]]))

        if (verbose == TRUE) {
            message("Most variable counts matrix:\n")
            message(dim(mat.mv)[1], " genes")
            message(dim(mat.mv)[2], " cells")
            message("Zero rate = ", round(sum(mat.mv == 0) *
                1000/prod(dim(mat.mv)))/10, "%")
        }
    } else {
        if (most.variables != 0) {
            most.variables <- 0
            message("Most variables should be an integer (number of genes
            to keep as regard to their variation). No most variable count
            matrix will be computed.")
        }
        res <- data
        mat <- as.matrix(res)
        mat.mv <- NULL
    }

    new("SCSRDataModel", initial.organism = species, 
        ncounts = list(matrix = mat,
        matrix.mv = mat.mv, initial.orthologs = homolog.genes,
        initial.orthologs.mv = homolog.genes.mv, 
        param = list(formating = formating,
            specific = spec, most.variables = most.variables)))
}

#' @title Orthologs Gene Names 
#'
#' @description By default, SingleSignalR is designed to work with Homo 
#' Sapiens. In order to work with other species, gene names need to be first 
#' converted to Human following an orthology mapping process.
#' @param from_organism    An organism as defined in Ensembl : 
#' drerio, mmusculus, celegans, dmelanogaster...This is the source organism 
#' from which you want to convert the gene names to Homo Sapiens.
#' @param from_values    A vector of gene names from the current species 
#' studied.
#' @param method    3 choices are available ('gprofiler','homologene',
#' 'babelgene') gprofiler is set by  default.
#' @keywords internal
#' 
#' @importFrom orthogene convert_orthologs
#'
#' @return Return a datraframe with 2 columns containing the gene names
#' for two species.  
#' First column is the gene name from the source organism 
#' and the second column corresponds to the  homologous gene name
#' in  Homo Sapiens.
#' This function uses orthogene package to query databases
#' for homologous genes annotation
#'
#' @examples
#' print('findOrthoGenes')
.findOrthoGenes <- function(from_organism, from_values, method) {

    data(LRdb)

    if (!method %in% c("gprofiler", "homologene", "babelgene"))
        stop("Method selected should be gprofiler,homologene or babelgene")

    orthologs_dictionnary <- orthogene::convert_orthologs(
        gene_df = from_values, gene_input = "rownames", 
        gene_output = "rownames", input_species = from_organism,
        output_species = "human", non121_strategy = "drop_both_species",
        method = method, verbose = FALSE)

    orthologs_dictionnary$index <- NULL
    names(orthologs_dictionnary)[1] <- paste("Gene.name")

    message(paste0(capture.output(head(orthologs_dictionnary,
        10)), collapse = "\n"))
    message("Dictionnary Size: ", dim(orthologs_dictionnary)[1],
        " genes")

    nL <- length(intersect(LRdb$ligand, rownames(orthologs_dictionnary)))
    message("-> ", nL, " : Ligands")

    nR <- length(intersect(LRdb$receptor, rownames(orthologs_dictionnary)))
    message("-> ", nR, " : Receptors")

    orthologs_dictionnary
}  #findOrthoGenes 


#' @title Transpose To Human Gene Names
#' @description By default, SingleSignalR is designed to work with Homo Sapiens
#' In order to work with other species, gene names need to be first converted
#' to Human following an orthology mapping process.
#' @param counts     A table or matrix of read counts.
#' @param dictionnary   A dataframe where first column belong to 
#' organism of study & rownames are the human gene names.
#' @keywords internal
#'
#' @return Return a counts matrix transposed for Human containing a column of 
#' original gene names
#'
#' @examples
#' print('transposeToHuman')
.convertToHuman <- function(counts, dictionnary = data.frame(Gene.name = "A",
    row.names = "B")) {

    # Should test counts have rownames.
    if (all(row.names(counts) == seq_len(nrow(counts))))
        stop("Rownames should be set as human gene names for counts.",
            call. = FALSE)
    if (all(row.names(dictionnary) == seq_len(nrow(dictionnary))))
        stop("Rownames should be set ashuman gene names dictionnary.",
            call. = FALSE)
    if (dim(dictionnary)[2] != 1)
        stop("Unique column must be set for dictionnary.", call. = FALSE)
    if (!all(apply(counts, 2, function(x) is.numeric(x))))
        stop("Some variables are not defined as numerics.", call. = FALSE)

    # Transform Matrice using orthologs_dictionnary
    counts$Gene.name <- rownames(counts)
    dictionnary$human.gn <- rownames(dictionnary)
    counts$index <- seq(1, nrow(counts), 1)

    counts.transposed <- merge(counts, dictionnary, by = "Gene.name",
        all.x = TRUE, sort = FALSE)
    counts.transposed <- counts.transposed[!is.na(counts.transposed$human.gn),
        ]
    counts.transposed <- counts.transposed[order(counts.transposed$index,
        decreasing = FALSE), ]
    counts.transposed$index <- NULL

    # counts.transposed$Gene.name <- NULL
    counts.transposed <- counts.transposed[c("human.gn", 
        setdiff(names(counts.transposed), "human.gn"))]

    rownames(counts.transposed) <- counts.transposed[, 1]
    counts.transposed <- counts.transposed[, -1]

    counts.transposed
}
