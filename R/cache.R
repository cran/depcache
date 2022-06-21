get.filename <- function(expr, frame, extra, opts) {
	deps <- dependencies(expr, frame, opts)
	filename <- hash(
		list(fixup(expr), fixup(deps), eval(extra, frame)),
		opts$format.version
	)
	paste0(file.path(opts$dir, filename), '.rds')
}

do.cache <- function(expr, frame, extra, opts) {
	dir.create(opts$dir, showWarnings = FALSE)
	stopifnot(dir.exists(opts$dir))

	rds <- get.filename(expr, frame, extra, opts)

	tryCatch(
		suppressWarnings(readRDS(rds)),
		error = function(e) {
			val <- eval(expr, frame)
			saveRDS(
				val, rds,
				version = opts$format.version, compress = opts$compress
			)
			val
		}
	)
}

cache <- function(expr, extra = NULL, ...) do.cache(
	substitute(expr), parent.frame(), substitute(extra), depcache.options(...)
)
