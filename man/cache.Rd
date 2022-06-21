\name{cache}
\alias{cache}
\title{Evaluate an expression and cache its results}
\description{
  This function extracts all dependencies of an R expression, hashes
  them together with the expression itself and either loads the
  already-existing file, or evaluates the expression and stores the
  result in that file.
}
\usage{
  cache(expr, extra = NULL, \dots)
}
\arguments{
  \item{expr}{
    An expression to evaluate or load from cache, unquoted.
  }
  \item{extra}{
    Any R value that should be considered part of the state deciding
    whether the expression should be re-computed. For example, if
    \code{expr} reads a file, consider using \code{\link{file.mtime}} or
    \code{\link{md5sum}} to check for changes in it.
  }
  \item{\dots}{
    Additional options, see \code{\link{depcache.options}}.
  }
}
\details{
  Currently, the hash is obtained by means of serialisation. In order to
  make semantically same values have same hashes on a wide range of R
  versions, the following steps were taken: \itemize{
    \item When computing the hash of the serialized data (only the XDR
    format version 2 or 3 is supported), the first 14 bytes containing
    the header (including the version of R that serialized the data) are
    ignored.

    \item Every function is \dQuote{rebuilt} from its body before
    hashing, forcing R to discard the bytecode and the source references
    from the copy of the function before it's hashed.

    \item Strings are converted to UTF-8 before hashing.

    \item All this is done recursively.
  }

  The exact algorithm used and the way hash is obtained are
  implementation details and may eventually change, though not without a
  good reason.

  Other aspects of R data structures are currently not handled:
  \itemize{
    \item Nothing is done about environments. Due to them being
    reference objects, any fix-up must re-create them from scratch,
    taking potentially recursive dependencies into account, which is
    likely expensive.

    \item Some S4 classes (like reference class implementations) just
    have different representations in different versions of \R and
    third-party packages. They may mean the same thing, but they
    serialize to different byte sequences.
  }
}
\value{
  The result of evaluating \code{expr}, either directly, or loaded from
  cache.
}

\seealso{\code{\link{setCached}}}
\examples{
  \dontshow{
    .depcache.dir <- file.path(tempdir(), 'depcache-example')
    .op <- options(depcache.dir = .depcache.dir)
  }
  a <- 1
  # will evaluate the expression the first time
  cache({ message('evaluating expression'); a + 1 }) # 2
  # saved value of the expression will be used
  cache({
    message('evaluating expression')
    # even if written a bit differently
    a + 1
  }) # 2
  a <- -1
  # expression evaluated again because dependencies changed
  cache({ message('evaluating expression'); a + 1 }) # 0
  \dontshow{
    unlink(.depcache.dir, recursive = TRUE)
    options(.op)
  }
}
\keyword{utilities}
