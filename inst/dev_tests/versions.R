Rscript.old <- Sys.getenv('RSCRIPT_OLD_VERSION')
Rscript.new <- Sys.getenv('RSCRIPT_NEW_VERSION')
pkg <- Sys.getenv('PACKAGE_TGZ')

if (!(
	nzchar(Rscript.old) && nzchar(Rscript.new) &&
	file.exists(pkg)
)) {
	message(
		'In order to run this developer test, please set the ',
		'following environment variables:\n',
		' - paths to Rscript for 2 different versions of R ',
			'in RSCRIPT_{OLD,NEW}_VERSION (currently ',
			deparse(c(Rscript.old, Rscript.new)), ')\n',
		' - path to the package tarball in PACKAGE_TGZ; ',
			'file.exists(', deparse(pkg), ') = ', file.exists(pkg)
	)
	stop()
}

# R cluster protocol works on the serialization format. Old versions of
# R don't speak workspace format version 3, but new versions don't mind
# the older, non-default version.
trace(serialize, quote(version <- 2), at = 1, print = FALSE)

library(parallel)
# prevent child processes from running the test suite again
Sys.unsetenv('R_TESTS')
# allow re-running the script manually
if (exists('cl')) { stopCluster(cl); rm(cl) }
cl <- structure(c(
	makePSOCKcluster(1, rscript = Rscript.old),
	# NB: old R can't run new R as a cluster worker
	makePSOCKcluster(1, rscript = Rscript.new)
), class = c('SOCKcluster', 'cluster'))

# check that R versions differ and are in the correct order
Rversions <- clusterEvalQ(cl, getRversion())
message('R versions in use: ', Rversions[[1]], ', ', Rversions[[2]])
stopifnot(Rversions[[1]] < Rversions[[2]])

hash.all <- function(x, v, skip = NULL)
	sapply(setNames(nm = setdiff(names(x), skip)), function(n)
		depcache:::hash(depcache:::fixup(x[[n]]), v)
	)
clusterExport(cl, c('pkg', 'hash.all'))
clusterEvalQ(cl, {
	# avoid altering the libraries, wherever they are
	lib <- tempfile()
	dir.create(lib)
	.libPaths(lib)
	install.packages(pkg)

	library(depcache)

	# prepare objects for later check
	recursive_env = new.env()
	recursive_env$e <- recursive_env
	lat1str <- `Encoding<-`('\xC5\xD8', 'latin1')
})

fail <- FALSE
hashcmp <- function(res) {
	mask <- res[[1]] != res[[2]]
	if (!any(mask)) return()
	message('Found differences in hash values:')
	print(cbind(old = res[[1]][mask], new = res[[2]][mask]))
	fail <<- TRUE
}

# test that the "same" objects result in the same hash for different
# versions of R
for (v in if (Rversions[[1]] >= '3.5.0') 2:3 else 2) {
	message('Using serialization version ', v)
	clusterExport(cl, 'v')
	hashcmp(clusterEvalQ(cl, hash.all(
		loadNamespace('depcache'), v,
		c(
			'C_hash', # $dll$path is different
			'.__NAMESPACE__.' # $DLLs, $path contain paths
		)
	)))
	hashcmp(clusterEvalQ(cl, hash.all(list(
		NULL = NULL,
		symbol = as.symbol('hello'),
		pairlist = pairlist(a = NULL, 1),
		closure = function() c(NA, NULL, 0),
		environment = recursive_env,
		language = quote(a + b),
		special = substitute,
		builtin = `+`,
		expression = expression(haha),
		list = alist(NULL, a=),
		S4_character = setClass(
			'BarClass', contains = 'character', prototype = lat1str
		)(),
		S4_function = setClass(
			'BazClass', contains = 'function', prototype = function(y)
				alist(a=, NA, NULL, 0)
		)()
	), v)))
}

# full clean up if running under R CMD check
if (file.exists(file.path('..', '00_pkg_src', 'depcache'))) stopCluster(cl)

if (fail) stop('Found hash differences between R versions')
