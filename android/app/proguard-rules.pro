# Reglas de R8 para la versión de release de ClubReads.
# Las librerías de Flutter y de los plugins traen sus propias reglas; aquí solo
# va lo específico de la app.

# Trazas legibles en Crashlytics (nombres de archivo y números de línea).
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*

# Flutter referencia Play Core para módulos diferidos, que esta app no usa.
-dontwarn com.google.android.play.core.**

# Firebase descubre sus componentes (Crashlytics, Core…) por reflexión a través
# de los «registrars» declarados en el manifiesto. Si R8 los elimina o les
# cambia el nombre, Firebase.initializeApp() falla al arrancar con «component
# is not present» y la app no llega a abrirse.
-keep class * implements com.google.firebase.components.ComponentRegistrar { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrarProcessor { *; }
-keep class com.google.firebase.provider.FirebaseInitProvider { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.components.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }
-dontwarn com.google.firebase.**
