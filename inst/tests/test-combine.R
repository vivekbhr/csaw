# This tests the combining power of the combineTests function.

suppressWarnings(suppressPackageStartupMessages(require(csaw)))

comp <- function(total.n, n.clusters, weights=NULL) {
	merged.ids <- sample(n.clusters, total.n, replace=TRUE)
	tab <- data.frame(logFC=runif(total.n, -1, 1), logCPM=runif(total.n, -2, 1),
		PValue=rbeta(total.n, 1, 10))
	if (is.null(weights)) { weights <- rep(1, length.out=total.n) }
	out <- combineTests(merged.ids, tab, weight=weights)

	# Checking numbers.
	if (!identical(as.integer(table(merged.ids)), out$nWindows)) { stop("total numbers of windows are not identical") }
	reference <- integer(nrow(out))
	test <- table(merged.ids[tab$logFC > 0.5])
	reference[match(names(test), rownames(out))] <- as.integer(test)
	if (!identical(reference, out$logFC.up)) { stop("number of up windows is not identical") }
	reference <- integer(nrow(out))
	test <- table(merged.ids[tab$logFC < -0.5])
	reference[match(names(test), rownames(out))] <- as.integer(test)
	if (!identical(reference, out$logFC.down)) { stop("number of up windows is not identical") }
   	
	# Checking Simes.
	checker <- split(data.frame(PValue=tab$PValue, weight=weights), merged.ids)
	osimes<-sapply(checker, FUN=function(x) {
		o<-order(x$PValue)
		min(x$PValue[o]/cumsum(x$weight[o])) * sum(x$weight)
	})
	almostidentical <- function(x, y, tol=1e-8) { 
		if (length(x)!=length(y)) { return(FALSE) }
		return(all(abs((x-y)/(x+y+1e-6)) < tol))
	}
	if (!almostidentical(osimes, out$PValue)) { stop("combined p-values are not identical") }
	if (!almostidentical(p.adjust(osimes, method="BH"), out$FDR)) { stop("q-values are not identical") }

    # Checking inferred directions.
    going.up <- tab$logFC > 0
    tab.up <- tab
    tab.up$PValue[!going.up] <- 1
    out.up <- combineTests(merged.ids, tab.up, weight=weights)
    tab.down <- tab
    tab.down$PValue[going.up] <- 1
    out.down <- combineTests(merged.ids, tab.down, weight=weights)
    
    direction <- rep("mixed", nrow(out))
    tol <- 1e-6
    up.same <- out.up$PValue/out$PValue - 1 <= tol  # No need to use abs(), up/down cannot be lower.
    down.same <- out.down$PValue/out$PValue - 1 <= tol
    direction[up.same & !down.same] <- "up"
    direction[!up.same & down.same] <- "down"
    stopifnot(identical(direction, out$direction))

	# Checking the rownames.
	if (!identical(rownames(out), as.character(sort(unique(merged.ids))))) { stop("row names are not matched") }

	# Checking if we get the same results after reversing the ids (ensures internal re-ordering is active).
    re.o <- total.n:1
    out2<-combineTests(merged.ids[re.o], tab[re.o,], weight=weights[re.o])
    if (!almostidentical(out$logFC, out2$logFC) || !almostidentical(out$logCPM, out2$logCPM)
        || !almostidentical(out$PValue, out2$PValue) || !identical(rownames(out), rownames(out2))) { 
        stop("values not preserved after shuffling") 
    }

    # Checking we get the same results with a character vector (though ordering might be different).
    out3 <- combineTests(as.character(merged.ids), tab, weight=weights)
    out3 <- out3[rownames(out),]
    if (!identical(out, out3)) { stop("values not preserved with character vector input") }

    # Checking what happens if the first id becomes NA.
    na.ids <- merged.ids
    na.ids[1] <- NA_integer_
    out.na <- combineTests(na.ids, tab, weight=weights)
    out.ref <- combineTests(na.ids[-1], tab[-1,], weight=weights[-1])
    if (!almostidentical(out.na$logFC, out.ref$logFC) || !almostidentical(out.na$logCPM, out.ref$logCPM)
        || !almostidentical(out.na$PValue, out.ref$PValue) || !identical(rownames(out), rownames(out2))) {
        stop("values not preserved after adding an NA") 
    }

	# Adding some tests if there's multiple log-FC's in 'tab'.
	is.fc<-which(colnames(tab)=="logFC")
	colnames(tab)[is.fc]<-"logFC.1"
	tab$logFC.2<--tab$logFC.1
    out<-combineTests(merged.ids, tab, weight=weights)
	if (!identical(out$logFC.1.up, out$logFC.2.down)) { stop("check failed for multiple log-FC columns") }
	if (!identical(out$logFC.1.down, out$logFC.2.up)) { stop("check failed for multiple log-FC columns") }

	return(head(out))
}

###################################################################################################

set.seed(2135045)
suppressWarnings(suppressPackageStartupMessages(require(csaw)))
options(width=100)

comp(20, 5)
comp(20, 10)
comp(20, 20)
comp(20, 5, weights=runif(20))
comp(20, 10, weights=runif(20))
comp(20, 20, weights=runif(20))

comp(100, 50)
comp(100, 100)
comp(100, 200)
comp(100, 50, weights=runif(100))
comp(100, 100, weights=runif(100))
comp(100, 200, weights=runif(100))

comp(1000, 50)
comp(1000, 100)
comp(1000, 200)
comp(1000, 50, weights=runif(1000))
comp(1000, 100, weights=runif(1000))
comp(1000, 200, weights=runif(1000))

###################################################################################################
# Checking for sane behaviour when no IDs are supplied.

combineTests(integer(0), data.frame(PValue=numeric(0), logCPM=numeric(0), logFC=numeric(0)), weight=numeric(0))

###################################################################################################
# End.

