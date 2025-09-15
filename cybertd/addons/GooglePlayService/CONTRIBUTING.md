# Contributing to the Godot Play Games Services plugin

Thanks for contributing to the plugin! You can do so by [opening an issue](https://github.com/godot-sdk-integrations/godot-play-game-services/issues/new/choose) asking for a new feature or bug fixing, or just by [opening a Pull Request](https://github.com/godot-sdk-integrations/godot-play-game-services/compare) implementing the change yourself.

I haven't set any code style guidelines (yet?), just check how the already existing code is done and try to follow the patterns. We can discuss it further in the Pull Requests. Same applies for other changes not involving new features or bug fixing, like refactoring or deep changes in the way the plugin works. I'm open to discussion.

Note that this repository includes several code sources:

* The Kotlin code integrating the Google SDK itself. It's under the `plugin/src` directory.
* The Godot Plugin code written in GDScript, under the `plugin/export_scripts_template` directory.
* The demo project also written in GDScript, under the `plugin/demo` directory.

You can contribute to the demo project also if you want, but that's intended as a dummy Godot App to showcase some features of the plugin. The main source codes of the plugin are the Kotlin and the Godot Plugin ones.