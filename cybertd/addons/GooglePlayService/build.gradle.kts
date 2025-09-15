import org.jetbrains.dokka.base.DokkaBase
import org.jetbrains.dokka.base.DokkaBaseConfiguration

// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    id("com.android.library") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "1.8.0" apply false
    id("org.jetbrains.dokka") version "1.9.10"
}

buildscript {
    val agp_version by extra("8.7.3")
    dependencies {
        classpath("org.jetbrains.dokka:dokka-base:1.9.10")
    }
}

subprojects {
    apply(plugin = "org.jetbrains.dokka")
}

tasks.dokkaHtmlMultiModule {
    moduleName.set("Godot Play Game Services")
    outputDirectory.set(rootDir.resolve("docs/dokka/$name"))

    pluginConfiguration<DokkaBase, DokkaBaseConfiguration> {
        footerMessage = "©2023 Jacob Ibáñez Sánchez"
        customAssets = listOf(file("docs/images/logo-icon.svg"))
    }
}