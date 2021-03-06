# This tests the correctness of the getBestTest function.

suppressWarnings(suppressPackageStartupMessages(require(csaw)))
comp <- function(alpha=1, beta=2, nids=10, max.weight=10) {
	n <- 10000L
    ids<-round(runif(n, 1, nids))
	tab <- data.frame(logFC=rnorm(n), logCPM=rnorm(n), PValue=rbeta(n, alpha, beta))
	best<-getBestTest(ids, tab)

	ref <- aggregate(tab$PValue ~ ids, FUN=function(x) { min(1, x*length(x)) }, data=NULL)	
	xref <- aggregate(1:n ~ ids, FUN=function(x) { x[which.min(tab$PValue[x])] }, data=NULL)	
	if (any(abs(best$PValue - ref[,2]) > 1e-6 * (ref[,2] + best$PValue)) ||
			!identical(best$best, xref[,2]) ) {
		stop("best p-value doesn't match reference") 
	}

	# With window weighting.
	w<-round(runif(n, 1, max.weight))
	best<-getBestTest(ids, tab, weight=w)
	ref <- aggregate(1:n ~ ids, FUN=function(x) { min(1, tab$PValue[x]/w[x]*sum(w[x])) }, data=NULL)	
	xref <- aggregate(1:n ~ ids, FUN=function(x) { x[which.min(tab$PValue[x]/w[x])] }, data=NULL)	
	if (any(abs(best$PValue - ref[,2]) > 1e-6 * (ref[,2] + best$PValue)) ||
			!identical(best$best, xref[,2]) ) {
		stop("best p-value doesn't match reference after weighting") 
	}

    # After shuffling things around.
    re.o <- n:1
    out2 <- getBestTest(ids[re.o], tab[re.o,], weight=w[re.o])
    if (any(abs(best$PValue - out2$PValue) > 1e-6 * (best$PValue)) 
        || !identical(n - best$best + 1L, out2$best) # because the ordering of 'tab' changes.
        || !identical(rownames(best), rownames(out2))) { 
        stop("values not preserved after shuffling") 
    }

    # Testing what happens with a character vector as input.
    out3 <- getBestTest(as.character(ids), tab, weight=w)
    out3 <- out3[rownames(best),]
    if (!identical(best, out3)) { stop("values not preserved with character vector input") }

    # Checking what happens if the first id becomes NA.
    na.ids <- ids 
    na.ids[1] <- NA_integer_
    out.na <- getBestTest(na.ids, tab, weight=w)
    out.ref <- getBestTest(na.ids[-1], tab[-1,], weight=w[-1])
    if (any(abs(out.na$PValue - out.ref$PValue) > 1e-6 * (out.na$PValue)) 
        || !identical(out.na$best, out.ref$best + 1L)  # because of the missing first row.
        || !identical(rownames(out.na), rownames(out.ref))) {
        stop("values not preserved after adding an NA") 
    }

	# Now, searching for the max log-CPM.
	almostbest <- getBestTest(ids, tab, by.pval=FALSE)
    ref <- aggregate(1:n ~ ids, FUN=function(x) { x[which.max(tab$logCPM[x])] }, data=NULL)
	if (!identical(ref[,2], almostbest$best)) { stop("tests with the highest log-CPMs don't match reference") }
	
	return(head(best))	
}

set.seed(3479102)
options(width=120)

comp()
comp(1,1)
comp(1,3)
comp(1,5)
comp(2,1)
comp(2,3)
comp(2,5)

comp(nids=1000)
comp(1,1, nids=100)
comp(1,3, nids=1000)
comp(1,5, nids=5000)
comp(2,1, nids=50)
comp(2,3, nids=100)
comp(2,5, nids=500)

comp(1,1, nids=1000, max.weight=2)
comp(1,3, nids=1000, max.weight=5)
comp(1,5, nids=5000, max.weight=10)
comp(2,1, nids=20, max.weight=20)
comp(2,3, nids=30, max.weight=50)
comp(2,5, nids=50, max.weight=100)

##################################################################
# Checking for sane behaviour when no IDs are supplied.

getBestTest(integer(0), data.frame(PValue=numeric(0), logCPM=numeric(0), logFC=numeric(0)), weight=numeric(0))

##################################################################
# End.

