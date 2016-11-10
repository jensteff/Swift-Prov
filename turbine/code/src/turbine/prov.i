%module prov
 %{
 /* Includes the header in the wrapper code */
 #include "prov.h"

 %}
 
 /* Parse the header file to generate wrappers */
 %include "prov.h"
