# Test for an R_MissingArg (as found in formals()), not an actually
# missing argument.
.missing <- function(x) {
	x <- x
	missing(x)
}

# In R < 3.6, removeSource only works with functions, despite language
# objects also have source references to remove.
# In R < 3.5, there's a bug concerning function calls involving NULLs:
# elementwise replacement is done using x[[i]] <- Recall(x[[i]]), so
# when x[[i]] is NULL, the language object ends up being shortened by
# one.
# On the one hand, we're playing with undocumented stuff here. On the
# other hand, there will never be another version of R 3.x, so any
# remaining bugs can be fixed right here.
.removeSource <- function(x)
	if (getRversion() >= '3.6') removeSource(x) else {
		# no attributes for symbols; no source references for primitives
		if (is.name(x) || is.primitive(x)) return(x)
		attr(x, 'srcref') <- NULL
		attr(x, 'wholeSrcref') <- NULL
		attr(x, 'srcfile') <- NULL
		# might contain more source references below
		if (is.function(x)) {
			# functions are recursive language objects, but aren't
			# iterable
			body(x) <- Recall(body(x))
		} else if (is.recursive(x) && is.language(x)) {
			for (i in seq_along(x))
				x[i] <- list(Recall(x[[i]])) # watch out for NULLs
		}
		x
	}

# apply changes to objects in order to make their hashes reproducible
# between R versions and operating systems
fixup <- function(x)
	if (isS4(x)) {
		# Don't even try to "edit" S4 objects using body<- and similar
		# tools; this destroys the S4 part of the object. Instead, use
		# the (pseudo-)slots to edit the object by parts.
		# NB: can't use slotNames because class representations are
		# themselves S4 objects and slotNames would return the names of
		# the slots for the wrong class
		for (n in names(getSlots(class(x))))
			slot(x, n) <- Recall(slot(x, n))
		x
	} else if (is.character(x)) {
		# This changes the representation of the string, but doesn't
		# change its semantics, unless the string isn't representable in
		# UTF-8 (e.g. because it contained invalid byte sequences).
		enc2utf8(x)
	} else if (is.primitive(x) || is.environment(x)) {
		# There's nothing to fix about primitives, and they trip up
		# body<-. Environments have reference semantics and can be
		# recursive, so it's hard to keep track of them properly.
		x
	} else {
		# Out of special cases, must consider intersections for some of
		# the following conditions.

		# Source references can be different for equivalent functions and
		# expressions and so must be removed.
		if (is.language(x)) x <- .removeSource(x)
		if (is.function(x)) {
			# Functions are special in that they are recursive, but can't be
			# directly subsetted: they consist of formals, body and environment,
			# all of which could be subsetted.
			body(x) <- Recall(body(x))
			formals(x) <- Recall(formals(x))
		} else if (is.recursive(x))
			# Recursive objects could contain things to fix downstream.
			for (i in seq_along(x))
				# 1. Inside formals() there can be R_MissingArg, better
				# leave it alone.
				# 2. There's nothing to fix up in a NULL, and inserting a
				# NULL in a list removes the entry.
				if (!.missing(x[[i]]) && !is.null(x[[i]]))
					x[[i]] <- Recall(x[[i]])
		# Finally, done with transformations.
		x
	}
