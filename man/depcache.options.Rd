\name{depcache.options}
\alias{depcache.options}
\title{Caching options}
\description{
  Control how the dependencies are gathered and hashed to locate the
  determine the file name to load the cached object from.
}
\usage{
depcache.options(
  defaults = getOption("depcache.version", '0.1'),
  skip = getOption("depcache.skip", NULL),
  dir, compress, local.only, format.version
)
}
\arguments{
  \item{defaults}{
    A string containing the version of \pkg{depcache} to get other
    defaults from. If not set, takes the value from the
    \verb{depcache.version} option (see \code{\link{options}}), falling
    back to the current version of the package.

    To make the caching more reproducible against package updates, call
    \code{\link{options}(depcache.version = \var{something})} once at the
    top of your scripts.

    Currently, only version \verb{0.1} is accepted. When a new version
    of the package changes the defaults or adds new settings, the range
    of the accepted values will expand.
  }
  \item{skip}{
    A character vector of variables to omit from automatically-gathered
    dependencies. Variables carrying unintended or unimportant state,
    which would otherwise interfere with obtaining a reproducible hash,
    should be listed here. This may be useful when a symbol encountered
    in the expression doesn't signify a variable in the evaluation frame
    (e.g. non-standard evaluation when plotting with \pkg{lattice}), or
    when the variable is being assigned to as part of the expression.

    Defaults to the \verb{depcache.skip} option, or \code{NULL} if unset.
  }
  \item{dir}{
    The directory to store the cache files inside. Defaults to the
    \verb{depcache.dir} option, or \file{.depcache} in \pkg{depcache}
    version 0.1.
  }
  \item{compress}{
    Passed as the \code{compress} option to \code{\link{saveRDS}} when
    saving the cached objects. Defaults to the \verb{depcache.compress}
    option, or \code{TRUE} in \pkg{depcache} version 0.1.
  }
  \item{local.only}{
    If \code{TRUE}, only variables available in the same environment
    where the caching function has been called from are considered as
    dependencies; parent environments are ignored. Typically, this means
    taking local variables as parts of the hash that determines the file
    name, but not loaded packages or \code{\link{attach}}ed datasets.
    Setting this to \code{FALSE} may invalidate the cache next time a
    package or \R itself is updated.

    Defaults to the \verb{depcache.local.only} option, or \code{TRUE} in
    \pkg{depcache} version 0.1.
  }
  \item{format.version}{
    Passed as the \code{version} argument to \code{\link{saveRDS}} and
    also used when serialising any objects to hash them. Only versions
    \verb{2} and \verb{3} are supported. Defaults to the
    \verb{depcache.format.version} option, or \verb{2} in \pkg{depcache}
    version 0.1.
  }
}
\details{
  In all cases, explicitly passed arguments override settings from the
  \code{\link{options}()}, which override the defaults. Depending on the
  \code{defaults} argument or the \verb{depcache.version} option, the
  defaults may change; setting it explicitly will help your scripts stay
  forward-compatible.

  This function shouldn't be normally called by the user (except,
  perhaps, to verify the parameters about to be passed to the caching
  functions), but it is automatically invoked on every call to
  \code{\link{cache}}, \code{\link{setCached}}, or the use of
  cache-tracking assignment operators \code{\link{\%<-\%}} and
  \code{\link{\%->\%}}. Any additional options passed to the functions
  as \code{\dots} are handled here, and so are the global
  \code{\link{options}}.
}
\value{
  A list containing the settings to be used by the caching system.
  \item{dir}{The directory used for storage of the cache files.}
  \item{compress}{Passed to \code{\link{saveRDS}}.}
  \item{skip}{
    Variables to skip when hashing the dependencies of the
    expressions.
  }
  \item{local.only}{Whether to ignore non-local dependencies.}
  \item{format.version}{
    Passed to \code{\link{saveRDS}} as the \code{version} argument. Also
    determines the format version when serialising the variables to hash
    them.
  }
}

\seealso{\code{\link{cache}}, \code{\link{setCached}}}
\examples{
  \dontshow{
    .depcache.dir <- file.path(tempdir(), 'depcache-example')
    .op <- options(depcache.dir = .depcache.dir)
  }
  # The output is affected by the user's use of options(...) and the
  # current version of the package
  options(depcache.local.only = FALSE)
  print(depcache.options(format.version = 3))
  options(depcache.local.only = TRUE)
  print(depcache.options())

  # "skip" makes it possible to avoid mistaking arguments evaluated in a
  # non-standard way for local variables
  speed <- 1
  options(depcache.skip = 'speed')
  x \%<-\% { message('fitting the model'); lm(dist ~ speed, cars) }
  speed <- 0
  # not fitted again despite change in local variable "speed"
  summary(x)
  \dontshow{
    unlink(.depcache.dir, recursive = TRUE)
    options(.op)
  }
}
\keyword{utilities}
