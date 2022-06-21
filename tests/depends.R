library(depcache)

data(cars) # creates the variable in the namespace
speed <- 1 # overlaps with the NSE variable in the call
expr <- quote(lm(dist ~ speed, cars))
frame <- environment()

getdep <- function(x, envir)
	mget(sort(unique(x)), envir = envir, inherits = TRUE)

stopifnot(
	all.equal(
		depcache:::dependencies(expr, frame, list(skip = NULL, local.only = TRUE)),
		# "speed" exists and so is picked up
		getdep(c('speed', 'cars'), frame)
	),
	all.equal(
		depcache:::dependencies(expr, frame, list(skip = NULL, local.only = FALSE)),
		# "lm" additionally picked up
		# "dist" is a function from stats and so is picked up too
		getdep(c('speed', 'cars', 'lm', 'dist', '~'), frame)
	),
	all.equal(
		depcache:::dependencies(expr, frame, list(skip = c('speed', 'dist'), local.only = FALSE)),
		# explicitly asking to skip the NSE variables
		getdep(c('cars', 'lm', '~'), frame)
	),
	all.equal(
		depcache:::dependencies(expr, frame, list(skip = 'speed', local.only = TRUE)),
		# avoiding both problems
		getdep(c('cars'), frame)
	)
)
