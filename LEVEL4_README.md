# Level 4 – Operation Iron Rail

Built on commit fb8d1d0.

## Install
1. Close Godot.
2. Unzip into the project folder (the one with `project.godot`). Say yes to overwriting files.
3. Open the project. Godot imports the new scenes on its own, which takes a few seconds.
4. Level 4 is already in Main's **Levels** list. Press Play and use the dev menu's **LEVEL 4** button. Tick **Start at boss** to jump straight to the fortress and trains.

## Changed files
- `autoload/game.gd`: adds `shake_camera()` and `flash_screen()`.
- `levels/level_data.gd`: adds `rail_enemies`, `stage_lengths` and `stage_ups`.
- `scenes/chunks/spawn_point.gd`: adds the **Track** checkbox.
- `scenes/main/chunk_spawner.gd`: trains go on Track points. The new **Build Ahead** and **Keep Below** settings stop long trains popping in and out.
- `scenes/main/main.gd`: uses the per-boss stage lengths and stage ups.
- `scenes/main/main.tscn`: adds level 4 to the Levels list.
- `scenes/title/dev_menu.gd`: starts level 4 at the right difficulty.
- `scenes/enemies/boss.gd`: adds the **Fade Out** checkbox (the trains roll away instead of fading).

## New files
- `levels/level_04.tres`: the level (briefing, map, enemies, bosses, radio lines).
- `scenes/chunks/train/`:
  - `chunk_yard_01` to `chunk_yard_13`: the rail yard, played once in order.
  - `chunk_tracks`: open track, used before and after the yard.
- `scenes/enemies/train/`:
  - Trains: `small_train_*` and their cars (`engine`, `gun_car`, `boxcar_*`, `tanker*`, `short_car`).
  - Vehicles: `big_tank`, `truck`.
  - Fortress boss: `fortress.tscn` / `fortress.gd`.
  - Armoured trains: `armored_train_a` / `armored_train_b`, script `train_boss.gd`.

## Things you might want to tweak in the Inspector
- **Mission name:** `level_04.tres` > Title. "OPERATION IRON RAIL" is a placeholder.
- **Spawn points:** open any `chunk_yard_XX.tscn` and move the markers under SpawnPoints.
  - Ticking Track spawns a train. Rotate the marker 180° to make the train drive away.
  - Ticking Parked makes the vehicle stand still.
- **Train fights** (`armored_train_a/b.tscn`, root node):
  - Track X: which pair of tracks the train runs on.
  - Car Stop Y: where each wagon stops.
  - Travel Speed: how fast it slides between stops.
- **Gun placement:** move a turret under the train's `Turrets` node onto a different wagon and it becomes part of that wagon's fight.
- **Ending:** on `armored_train_b.tscn`, the Big Finish group sets the flash, shake and blast timings.
- **Stage timing:** `level_04.tres` > Stage Lengths is set to 145 s, 40 s and 15 s.
  - 145 s lets the whole yard scroll past before the fortress arrives. If you change the scroll speed or cut yard chunks, change this too.
