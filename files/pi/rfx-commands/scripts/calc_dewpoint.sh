#!/bin/bash
# dewpoint
# Berechnung des Taupunkts
# aus Temperatur und Relativer Feuchte
#
# parameter:
# arg1 = Temperatur in Grad Celsius
# arg2 = Relative Luftfeuchtigkeit in %

# bc wird zum Rechnen gebraucht
BCPROG="/usr/bin/bc"
BCOPTS="-lq"
BC="$BCPROG $BCOPTS"

# mal sehen, ob das bc Programm gefunden wird
if ! which $BCPROG >/dev/null 2>&1 ; then
	echo "ERROR: 'dewpoint' needs bc"
	exit 1
fi

# prüfe, ob zwei Argumente übergeben wurden
if test -z "$1" -o -z "$2" ; then
	echo "ERROR: 'dewpoint' needs arguments <temperature> <rel_humidity>"
	exit 1
fi

# Die relative Luftfeuchte muss im Bereich 0% ... 100% liegen
BOOL=$(echo "($2 >= 0) && ($2 <= 100)" | $BC)
if ! test $BOOL == 1 ; then
	echo "ERROR: dewpoint out of limits"
	exit 1
fi

# Formeln:
# r   = relative Luftfeuchte
# T   = Temperatur in °C
# TD  = Taupunkttemperatur in °C
# DD  = Dampfdruck in hPa
# SDD = Sättigungsdampfdruck in hPa
#
# Parameter:
# a = 7.5, b = 237.3 für T >= 0
# a = 7.6, b = 240.7 für T <  0
#
# SDD(T)  = 6.1078 * 10^((a*T)/(b+T))
# DD(r,T) = r/100 * SDD(T)
# r(T,TD) = 100 * SDD(TD) / SDD(T)
# TD(r,T) = b*v/(a-v)
# mit:
# v(r,T)  = log10(DD(r,T)/6.1078)
#
# Da bc nur ganzzahlige Exponenten akzeptiert, muss mit
# Logarithmen gerechnet werden. Es gilt:
#   ln(a^b) = b * ln(a)
#   also: a^b = e^(b * ln(a))
#
echo "define pa (n) {
         if (n >= 0.0) {
            return (7.5);
         } else {
            return (7.6);
         }
      }

      define pb (n) {
         if (n >= 0.0) {
            return (237.3);
         } else {
            return (240.7);
         }
      }

      define sdd (t) {
         return (6.1078 * e( l(10) * ((pa(t) * t) / (pb(t) + t)) ) );
      }

      define dd (r,t) {
         return (r / 100.0 * sdd(t));
      }

      /* factor 2.302585093 converts ln() to log() */
      v  = l(dd($2,$1) / 6.1078) / 2.302585093;
      tp = ((pb($1) * v) / (pa($1) - v));

      if ( tp >= 0.0 ) {
         tp = (tp + 0.05);
      } else {
         tp = (tp - 0.05);
      }

      scale = 1;
      (tp / 1.0);" | $BC

exit 0
