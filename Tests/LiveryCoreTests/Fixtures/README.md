# Theme file fixtures

Each file is a built-in theme as its app exports it (`JSONEncoder` with
`.prettyPrinted` and `.sortedKeys`, from the app's `AppearancePreset`):

| File | App | Built-in theme |
|---|---|---|
| `zap-zx-night.json` | Zap | ZX Night |
| `jetty-vapor.json` | Jetty | Vapor |
| `invoque-summon.json` | Invoque | Summon |

`ThemeSnapshotTests` checks that `ThemeSnapshot` reads each one. When an app
renames, adds or drops an exported field, update its fixture here and the
"Theme files" table in the package README.
