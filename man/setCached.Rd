\name{setCached}
\alias{\%->\%}
\alias{\%<-\%}
\alias{setCached}
\title{Cache-tracking assignment}
\description{
  Cache expression values and automatically recalculate them when their
  dependencies change
}
\usage{
  symbol \%<-\% expr
  expr \%->\% symbol
  setCached(symbol, expr, extra = NULL, \dots)
}
\arguments{
  \item{symbol}{
    A variable name to associate with the expression, unquoted.
  }
  \item{expr}{
    The expression to cache, taking dependencies into account.
  }
  \item{extra}{
    An unquoted expression to be considered an extra part of the state,
    in addition to the automatically determined dependencies. Will be
    evaluated every time the variable is accessed to determine whether
    it should be recalculated.
  }
  \item{\dots}{
    Additional settings, see \code{\link{depcache.options}}.
  }
}
\details{
  Sets up the variable \var{symbol} to automatically recalculate the
  value of \code{expr} any time its dependencies change, using
  \code{\link{makeActiveBinding}} and the same mechanisms that power
  \code{\link{cache}}.

  Initially, \code{expr} is loaded from \code{\link{cache}} or
  evaluated, and the hash is remembered. When the variable named by
  \var{symbol} is accessed, its dependencies are hashed together with
  \code{expr} (this may be done recursively if the dependencies are
  themselves active bindings set up the same way). If the hash changes,
  the value of \code{expr} is again loaded from \code{\link{cache}} (if
  available) or evaluated anew.

  To prevent infinite loops during dependency calculation, \var{symbol}
  is automatically skipped, but a self-dependent \code{expr} is probably
  a bad idea anyway.
}
\value{
  Returns the value of \code{expr}, invisibly. Called for the side
  effect of creating an active binding with a name specified by
  \code{symbol}.
}

\seealso{\code{\link{cache}}, \code{\link{makeActiveBinding}}}
\examples{
  \dontshow{
    .depcache.dir <- file.path(tempdir(), 'depcache-example')
    .op <- options(depcache.dir = .depcache.dir)
  }
  a <- 1
  # will evaluate the expression first
  x \%<-\% { message('evaluating expression "x"'); a + 1 }
  x # 2
  # will reuse cached value
  {
    message('evaluating expression "y"')
    a + 1
    # even if written a bit differently
  } \%->\% y
  y # 2
  a <- -1
  # will evaluate the expression again
  x # 0
  # will load the new cached value
  y # 0
  setCached(z, x + y)
  a <- 0
  z # recalculates all three
  \dontshow{
    unlink(.depcache.dir, recursive = TRUE)
    options(.op)
  }
}
\keyword{utilities}
