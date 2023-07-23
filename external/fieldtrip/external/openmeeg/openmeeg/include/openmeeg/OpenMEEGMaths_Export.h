
#ifndef OPENMEEGMATHS_EXPORT_H
#define OPENMEEGMATHS_EXPORT_H

#ifdef OpenMEEGMaths_BUILT_AS_STATIC
#  define OPENMEEGMATHS_EXPORT
#  define OPENMEEGMATHS_NO_EXPORT
#else
#  ifndef OPENMEEGMATHS_EXPORT
#    ifdef OpenMEEGMaths_EXPORTS
        /* We are building this library */
#      define OPENMEEGMATHS_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define OPENMEEGMATHS_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef OPENMEEGMATHS_NO_EXPORT
#    define OPENMEEGMATHS_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef OPENMEEGMATHS_DEPRECATED
#  define OPENMEEGMATHS_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef OPENMEEGMATHS_DEPRECATED_EXPORT
#  define OPENMEEGMATHS_DEPRECATED_EXPORT OPENMEEGMATHS_EXPORT OPENMEEGMATHS_DEPRECATED
#endif

#ifndef OPENMEEGMATHS_DEPRECATED_NO_EXPORT
#  define OPENMEEGMATHS_DEPRECATED_NO_EXPORT OPENMEEGMATHS_NO_EXPORT OPENMEEGMATHS_DEPRECATED
#endif

#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef OPENMEEGMATHS_NO_DEPRECATED
#    define OPENMEEGMATHS_NO_DEPRECATED
#  endif
#endif

#endif
