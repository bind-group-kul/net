
#ifndef OPENMEEG_EXPORT_H
#define OPENMEEG_EXPORT_H

#ifdef OpenMEEG_BUILT_AS_STATIC
#  define OPENMEEG_EXPORT
#  define OPENMEEG_NO_EXPORT
#else
#  ifndef OPENMEEG_EXPORT
#    ifdef OpenMEEG_EXPORTS
        /* We are building this library */
#      define OPENMEEG_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define OPENMEEG_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef OPENMEEG_NO_EXPORT
#    define OPENMEEG_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef OPENMEEG_DEPRECATED
#  define OPENMEEG_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef OPENMEEG_DEPRECATED_EXPORT
#  define OPENMEEG_DEPRECATED_EXPORT OPENMEEG_EXPORT OPENMEEG_DEPRECATED
#endif

#ifndef OPENMEEG_DEPRECATED_NO_EXPORT
#  define OPENMEEG_DEPRECATED_NO_EXPORT OPENMEEG_NO_EXPORT OPENMEEG_DEPRECATED
#endif

#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef OPENMEEG_NO_DEPRECATED
#    define OPENMEEG_NO_DEPRECATED
#  endif
#endif

#endif
