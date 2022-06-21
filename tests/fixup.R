library(depcache)

# This is supposed to handle different "unknown" (native) encodings, but
# we're testing with latin1, which is the only encoding other than UTF-8
# that works the same regardless of native encoding.
x <- '\xC5\xD8'
Encoding(x) <- 'latin1'
stopifnot(
	identical(x, y <- depcache:::fixup(x)), # must be semantically equal
	!identical(charToRaw(x), charToRaw(y)) # despite representation
)

check.all.equal <- function(x) for (n in names(x))
	if (!isTRUE(ret <- all.equal(x[[n]], ff <- depcache:::fixup(x[[n]]))))
		stop(
			sQuote(n), ' semantically changes after fixup\n',
			'all.equal() says: ', ret, '\n',
			'deparse(', n, '): ', paste(deparse(x[[n]]), collapse = '\n'), '\n',
			'deparse(fixup(', n, ')): ', paste(deparse(ff), collapse = '\n'), '\n'
		)

# This is a bit lazy, but does check a lot. Most of our fixes are for
# language objects (which we have plenty of here) and recursive objects
# (which functions consist of).
check.all.equal(loadNamespace('depcache'))

recursive_env = new.env()
recursive_env$e <- recursive_env

# Try to cover most kinds of objects, except atomic vectors (we only
# touch character vectors, covered above) and stuff we're unlikely to
# ever meet in R code.
check.all.equal(list(
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
	S4_refclass = setRefClass( # reference classes are S4 objects
		'FooClass', fields = c('string'), methods = list(
			initialize = function() {
				string <<- `Encoding<-`('\xC5\xD8', 'latin1')
			}
		)
	),
	S4_character = setClass(
		'BarClass', contains = 'character', prototype = x
	)(),
	S4_function = setClass(
		'BazClass', contains = 'function', prototype = function(y)
			alist(a=, NA, NULL, 0)
	)()
))
