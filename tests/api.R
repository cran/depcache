library(depcache)

cache.dir <- file.path(tempdir(), 'cache')
options(depcache.dir = cache.dir)

# depends() previously crashed on expressions with no symbols
x <- cache(1)

# must remember and not re-run cached chunks of code
o1 <- capture.output(
	x <- cache({cat('performing side-effects'); 'ok'})
)
stopifnot(all.equal(x, 'ok'), all.equal(o1, 'performing side-effects'))
o2 <- capture.output(
	x <- cache({cat('performing side-effects'); 'ok'})
)
stopifnot(all.equal(x, 'ok'), all.equal(o2, character()))

# dependencies in cache-tracking assignment
a <- 1

o <- capture.output(
	x %<-% { cat('side-effects'); a + 1 }
)
stopifnot(all.equal(x, 2), all.equal(o, 'side-effects'))
# must not re-run if nothing changed
o <- capture.output(invisible(force(x)))
stopifnot(all.equal(o, character()))

# must re-run if dependencies change
a <- -1
o <- capture.output(invisible(force(x)))
stopifnot(all.equal(x, 0), all.equal(o, 'side-effects'))

# must not re-run for a different form of the same call
o <- capture.output(
	{ cat('side-effects'); a + 1 } %->% y
)
stopifnot(all.equal(o, character()))

tools::assertWarning(x <- 1)

# must not crash on missing values in the parse tree
cache( volcano[,1] )

unlink(cache.dir, recursive = TRUE)
