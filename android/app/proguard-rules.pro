# Reglas de R8 para la versión de release de ClubReads.
# Las librerías de Flutter y de los plugins traen sus propias reglas; aquí solo
# va lo específico de la app.

# Trazas legibles en Crashlytics (nombres de archivo y números de línea).
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*

# Flutter referencia Play Core para módulos diferidos, que esta app no usa.
-dontwarn com.google.android.play.core.**
