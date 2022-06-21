do.cachetrack <- function(symbol, expr, frame, extra, opts) {
	if (!is.symbol(symbol)) stop(
		'Cache-tracking assignment only works on plain variable names'
	)
	symbol <- as.character(symbol)
	opts$skip <- c(opts$skip, symbol)

	path <- get.filename(expr, frame, extra, opts)
	val <- do.cache(expr, frame, extra, opts)

	fun <- function(assignment) {
		if (missing(assignment)) {
			new.path <- get.filename(expr, frame, extra, opts)
			if (new.path != path) {
				val <<- do.cache(expr, frame, extra, opts)
				path <<- new.path
			}
			val
		} else {
			warning(
				'Overwriting a cache-tracked object (', symbol, ') ',
				'with an untracked value', call. = FALSE
			)
			rm(list = symbol, envir = frame)
			assign(symbol, assignment, envir = frame)
		}
	}

	# makeActiveBinding stops if the variable already exists
	if (exists(symbol, frame, inherits = FALSE))
		rm(list = symbol, envir = frame)
	makeActiveBinding(symbol, fun, frame)
	invisible(fun())
}

`%<-%` <- function(symbol, expr) do.cachetrack(
	substitute(symbol), substitute(expr), parent.frame(),
	quote(NULL), depcache.options()
)

`%->%` <- function(expr, symbol) do.cachetrack(
	substitute(symbol), substitute(expr), parent.frame(),
	quote(NULL), depcache.options()
)

setCached <- function(symbol, expr, extra = NULL, ...)
	do.cachetrack(
		substitute(symbol), substitute(expr), parent.frame(),
		substitute(extra), depcache.options(...)
	)
