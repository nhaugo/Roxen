// $Id: roxen.h,v 1.16 2000/07/17 14:13:42 lange Exp $
// -*- Pike -*-

#ifndef _ROXEN_H_

#define _ROXEN_H_
#include <config.h>
#define HOST_TO_IP 'H'
#define IP_TO_HOST 'I'

#define perror	roxen_perror

// Localization support

#ifndef __LOCALEMODULE
#if constant(Locale.translate)
#define __LOCALEMODULE Locale
#else /* !constant(Locale.translate) */
#define __LOCALEMODULE RoxenLocale
#endif /* constant(Locale.translate) */
#endif /* !__LOCALEMODULE */

#ifndef __LOCALEOBJECT
#ifdef IN_ROXEN
#define __LOCALEOBJECT locale
#else /* !IN_ROXEN */
#define __LOCALEOBJECT roxen.locale
#endif /* IN_ROXEN */
#endif /* !__LOCALEOBJECT */

#ifndef _STR_LOCALE
#define _STR_LOCALE(Z, X, Y)	\
    (__LOCALEMODULE.translate(X, __LOCALEOBJECT->get(), X, Y))
#endif /* !_STR_LOCALE */

#ifndef _DEF_LOCALE
#define _DEF_LOCALE(Z, X, Y)	\
    ([string](mixed)__LOCALEMODULE.DeferredLocale(Z, GETLOCLANG, X, Y))
#endif /* !_DEF_LOCALE */

#ifndef USE_DEFERRED_LOCALE
#define USE_DEFERRED_LOCALE	\
    static local inline string GETLOCLANG() { \
      return __LOCALEOBJECT->get(); \
    }
#endif /* !USE_DEFERRED_LOCALE */

#ifndef _LOCALE_FUN
#define _LOCALE_FUN(X, Y, Z)	\
    (__LOCALEMODULE.call(X, __LOCALEOBJECT->get(), Y, Z))
#endif /* !_LOCALE_FUN */


#endif  /* !_ROXEN_H_ */
