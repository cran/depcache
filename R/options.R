.defaults <- list(
	'0.1' = list(
		dir = '.depcache',
		compress = TRUE,
		local.only = TRUE,
		format.version = 2
	)
)

depcache.options <- function(
	defaults = getOption('depcache.version', '0.1'),
	skip = getOption('depcache.skip', NULL),
	dir, compress, local.only, format.version
) {
	defaults <- .defaults[[match.arg(defaults, names(.defaults))]]

	.getdefault <- function(var) {
		if (!missing(var)) return(var)
		name <- deparse(substitute(var))
		getOption(paste0('depcache.', name), defaults[[name]])
	}
	dir            <- .getdefault(dir)
	compress       <- .getdefault(compress)
	local.only     <- .getdefault(local.only)
	format.version <- .getdefault(format.version)

	stopifnot(
		is.character(dir), length(dir) == 1L,
		is.character(skip) || is.null(skip),
		length(compress) == 1L && !is.na(compress),
		is.logical(local.only) && length(local.only) == 1L,
		format.version %in% c(2,3)
	)

	list(
		dir = dir, compress = compress, skip = skip,
		local.only = local.only, format.version = format.version
	)
}
