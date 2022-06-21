dependencies <- function(expr, frame, opts) {
	# any symbol in the expression can be a dependency
	symbols <- unname(unlist(walkCode(
		expr, makeCodeWalker(
			# handle generic calls and recurse
			call = function(call, w) lapply(call, walkCode, w = w),
			# handle leafs of the AST
			leaf = function(l, w)
				if (is.symbol(l) && l != '') as.character(l)
		)
	)))

	# except the ones we're explicitly told not to hash
	# also get them in a defined order
	symbols <- sort(unique(setdiff(symbols, opts$skip)))

	# Reliable test for objects that don't exist. A value identical to a
	# freshly created environment won't be found in the environment of
	# a user expression that doesn't have access to here.
	notfound <- new.env(parent = emptyenv(), size = 0L)

	values <- mget(
		# if there's no symbols, cast NULL to character to satisfy mget
		as.character(symbols), frame, ifnotfound = list(notfound),
		inherits = !opts$local.only
	)
	# we pretend missing values don't exist (some NSE likely going on)
	ret <- Filter(function(v) !identical(v, notfound), values)

	ret
}
