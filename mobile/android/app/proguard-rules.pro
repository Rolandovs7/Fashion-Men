# ============================================================
# Reglas ProGuard para flutter_stripe 11.x
# Resuelve: R8 Missing class com.stripe.android.pushProvisioning.*
# ============================================================

# Mantener todas las clases de Stripe
-keep class com.stripe.** { *; }

# Ignorar advertencias de pushProvisioning
-dontwarn com.stripe.**
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# Mantener clases específicas
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }
