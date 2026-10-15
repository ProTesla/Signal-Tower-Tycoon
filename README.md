# Signal Tower Tycoon

A small isometric tycoon game built in **Godot 4.7**. You manage a budget and place telecom signal towers on a tile grid. This is an early build (increment 1): the building loop works, and the economy comes next.

## Gameplay

- Start with **1000 credits**.
- Each tower costs **250 credits**, so you can build 4 before you run out.
- Click a free tile to build a tower. It rises out of the ground with a short animation.
- Occupied tiles and an empty budget are rejected, with a message on screen.
- Turn **Build mode** off to stop clicks from building.

## Controls

| Action | Input |
|---|---|
| Build a tower | Left-click a tile (Build mode ON) |
| Pan the camera | `W` `A` `S` `D` or arrow keys |
| Zoom | Mouse wheel |
| Toggle build mode | Button in the top-left corner |

The tile under your cursor is highlighted green if you can build there and red if it is occupied.

## Running the project

1. Install [Godot 4.7](https://godotengine.org/download) (the Forward Plus renderer is used).
2. Clone this repo.
3. In the Godot Project Manager, click **Import** and select `project.godot`.
4. Press **F5** to run. The main scene is `scenes/main.tscn`.

## Project structure

```
project.godot
icon.svg
smoke_test.gd          headless test of the build/budget rules
scenes/
  main.tscn            root scene: camera, light, grid, towers, UI
  tower.tscn           tower scene (visuals are built in code)
scripts/
  GameManager.gd       game state and rules (budget, placing towers)
  Grid.gd              tile grid, mouse picking, hover highlight
  Tower.gd             tower stats and primitive-mesh visuals
  CameraController.gd  isometric orthographic camera, pan and zoom
  UI.gd                credits label, build-mode toggle, status text
shaders/
  grid.gdshader        draws grid lines on the ground plane
```

### How the pieces fit together

The scripts communicate through Godot signals, so no node reaches into another's internals:

```
Grid.tile_clicked --> GameManager --> budget_changed --> UI credits label
                                  \-> build_failed   --> UI status text
```

`Grid` only reports which tile was clicked. `GameManager` decides whether the build is allowed. `UI` just displays the results.

## Tests

A headless smoke test drives the real main scene through building, rejected builds, running out of credits, and build mode off:

```bash
godot --headless --script res://smoke_test.gd
```

It prints `SMOKE TEST: ALL PASS` and exits with code 0 on success.

## Roadmap

Already declared in `Tower.gd` and planned for the next increment:

- Monthly tick, with upkeep per tower
- Revenue and coverage percentage
- Tower capacity and frequency bands
- Interference between towers
- Selecting and inspecting towers when build mode is off

## Notes

- All visuals are primitive meshes and a shader, with no imported art assets.
- The `.godot/` folder (Godot's local cache) is intentionally not committed. Godot regenerates it when you open the project.

## License

Released under the [MIT License](LICENSE). Copyright (c) 2026 Ebenezer Ajijola.
