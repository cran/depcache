# Hash arbitrary R values by serializing them and calculating a hash
# of the XDR representation. "Version" here is the format version; only
# 2 and 3 are supported.
hash <- function(value, version)
	paste(as.character(.Call(C_hash, value, version)), collapse = '')
