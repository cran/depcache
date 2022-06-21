#include <assert.h>
#include <limits.h>
#include <stdint.h>

#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

/* FNV-1a hash: http://www.isthe.com/chongo/tech/comp/fnv */

static const uint64_t fnv1a64_basis = 14695981039346656037ULL;
static uint64_t do_fnv1a64(uint64_t hash, const unsigned char * buf, size_t sz) {
	for (const unsigned char * end = buf + sz; buf != end; ++buf) {
		hash ^= *buf;
		hash *= 1099511628211ULL; /* FNV_prime */
	}
	return hash;
}

struct hash_state {
	uint64_t val;
	size_t skip;
};

static void hash_update(struct hash_state * st, const void * buf, size_t sz) {
	if (st->skip > 0) {
		/* subtract the lesser of two */
		size_t consume = sz > st->skip ? st->skip : sz;
		st->skip -= consume;
		sz -= consume;
		buf = ((const char*)buf + consume);
	}
	st->val = do_fnv1a64(st->val, buf, sz);
}

static void outchar(R_outpstream_t st, int ch) {
	unsigned char c = ch;
	assert(ch >= 0);
	hash_update(st->data, &c, sizeof c);
}

static void outbytes(R_outpstream_t st, void * buf, int sz) {
	assert(sz >= 0);
	hash_update(st->data, buf, sz);
}

static SEXP hash(SEXP value, SEXP sver) {
	struct R_outpstream_st stream;
	/* R Internals, 1.8 Serialization Formats:
	 *
	 *  Version-2 serialization first writes a header indicating the
	 *  format (normally ‘X\n’ for an XDR format binary save, but ‘A\n’,
	 *  ASCII, and ‘B\n’, native word-order binary, can also occur) and
	 *  then three integers giving the version of the format and two R
	 *  versions (packed by the R_Version macro from Rversion.h).
	 *
	 *  Version-3 serialization extends version-2 by support for custom
	 *  serialization of ALTREP framework objects. It also stores the
	 *  current native encoding at serialization time, so that unflagged
	 *  strings can be converted if unserialized in R running under
	 *  different native encoding.
	 *
	 * Here, we skip over the header containing the R versions, but do
	 * nothing about the native encoding. Yet another reason to default
	 * to version 2.
	 */
	struct hash_state st = { .val = fnv1a64_basis, .skip = 14 };
	int version = asInteger(sver);
	SEXP ret = PROTECT(allocVector(RAWSXP, sizeof(st.val)));
	R_InitOutPStream(
		&stream, &st,
		R_pstream_xdr_format, version,
		outchar, outbytes,
		NULL, NULL
	);
	R_Serialize(value, &stream);
	for (size_t i = 0; i < sizeof(st.val); ++i)
		RAW(ret)[i] = (Rbyte)(st.val >> (CHAR_BIT * (sizeof(st.val) - 1 - i)));
	UNPROTECT(1);
	return ret;
}

static R_CallMethodDef call_methods[] = {
	{"hash", (DL_FUNC)&hash, 2},
	{NULL, NULL, 0}
};

void R_init_depcache(DllInfo *info) {
	R_registerRoutines(info, NULL, call_methods, NULL, NULL);
	R_useDynamicSymbols(info, FALSE);
	R_forceSymbols(info, TRUE);
}
