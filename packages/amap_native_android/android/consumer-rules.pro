# AMap ships its SDK as a JAR without consumer ProGuard rules.
-keep class com.amap.api.** { *; }
-keep class com.autonavi.** { *; }
-keep class com.amap.ams.** { *; }
-keep class com.loc.** { *; }
-keep class net.jafama.** { *; }
-dontwarn com.amap.api.**
-dontwarn com.autonavi.**
-dontwarn com.amap.ams.**
-dontwarn net.jafama.**
