\name{depcache-package}
\alias{depcache-package}
\alias{depcache}
\docType{package}
\title{\packageTitle{depcache}}
\description{
  \packageDescription{depcache}
}
\details{
  The functions in this package take an expression, walk its code to
  find its dependencies and calculate a hash of them. If a corresponding
  file already exists, it is loaded; otherwise, the expression is
  evaluated and its value is saved in the file. Optionally, this check
  may be performed every time a variable is accessed.

  By default, a subdirectory of the current directory is used to store
  the cache files.

  \packageIndices{depcache}
}
\author{Ivan Krylov}
\keyword{package}
\references{
  FNV-1a hash: \url{http://www.isthe.com/chongo/tech/comp/fnv/}
}
\seealso{\code{\link{cache}}, \code{\link{\%<-\%}}}
\examples{
  \dontshow{
    .depcache.dir <- file.path(tempdir(), 'depcache-example')
    .op <- options(depcache.dir = .depcache.dir)
  }
  a <- 1
  # will evaluate expression
  cache({ message('evaluating expression'); a + 1 }) # 2
  # will reuse cached value
  x \%<-\% { message('evaluating expression'); a + 1 } # 2
  x
  a <- 2
  # will recalculate the value
  x # 3
  \dontshow{
    unlink(.depcache.dir, recursive = TRUE)
    options(.op)
  }
}
