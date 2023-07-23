#pragma once

// Here is where system computed values get stored these values should only
// change when the target compile platform changes 
 
#define USE_VTK
/* #undef USE_GIFTI */
/* #undef USE_CGAL */

#define HAVE_BLAS
#define HAVE_LAPACK

/* #undef USE_ATLAS */
/* #undef USE_MKL */
/* #undef USE_OPENBLAS */
/* #undef USE_LAPACK */
#define USE_VECLIB
#define BLASLAPACK_IMPLEMENTATION

/* Define to 1 if your processor stores words with the most significant byte
   first (like Motorola and SPARC, unlike Intel and VAX). */

/* #undef WORDS_BIGENDIAN */

#define HAVE_ISNORMAL_IN_NAMESPACE_STD
/* #undef HAVE_ISNORMAL_IN_MATH_H */

static const char version[] = "2.3.99";

#ifdef USE_OMP
    #define STATIC_OMP
    #if defined _OPENMP
        #if _OPENMP>=200805
            #define OPENMP_3_0
        #endif
    #endif
#else
    #define STATIC_OMP static
#endif
