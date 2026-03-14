# Dynamic Acoustics Raycast System (Godot)

This script implements a **dynamic spatial audio filtering system** for **Godot** that simulates sound occlusion between an audio source and the player.

This implementation is **a variation of the technique demonstrated in the following video:**

**Spatial audio with Dynamic Acoustics in Godot | Tutorial**
https://youtu.be/mHokBQyB_08

The main difference is that **this version uses physics raycast queries instead of RayCast nodes**.
Using queries allows the system to:

* Avoid adding extra nodes to the scene
* Perform raycasts directly through `PhysicsDirectSpaceState`
* Scale better when many audio sources exist
* Be easier to run from scripts without scene setup

---

## Overview

The goal of the system is to simulate how **walls and obstacles affect sound**.

When a wall is between the **audio source** and the **player**, the system:

* Detects the obstruction using a physics raycast
* Calculates how much of the sound path is blocked
* Dynamically applies a **low-pass filter** to muffle the audio

This creates a more immersive audio experience where sounds become **duller and more muffled when heard through walls**.

---

## How It Works

1. A ray is cast from the **audio source** toward the **player**.
2. If the ray hits an obstacle before reaching the player, the sound is considered **occluded**.
3. The distance to the wall is compared to the total distance to the player.
4. A **ratio** is calculated describing how much of the sound path is blocked.
5. That ratio determines the **cutoff frequency** of a low-pass filter.

Example logic:

```
ray_distance = distance(source → wall)
distance_to_player = distance(source → player)

wall_to_player_ratio = ray_distance / distance_to_player
```

The lower the ratio, the **more muffled the sound becomes**.

---

## Why Use Physics Raycast Queries?

The tutorial implementation uses **RayCast nodes**, which work well but have some limitations when scaling.

Using **physics raycast queries** provides several advantages:

* No need to attach a `RayCast3D` node to every audio source
* Fewer nodes in large scenes
* Faster dynamic checks when many sounds exist
* Easier to run logic inside update loops

This approach uses:

```
PhysicsDirectSpaceState3D
intersect_ray()
```

to perform the raycast directly from code.

---

## Example Snippet

Below is a simplified example of the occlusion calculation:

```gdscript
if res and res.collider != _player:
    
    var ray_distance = global_position.distance_to(res.position)
    var distance_to_player = global_position.distance_to(_player.global_position)

    var wall_to_player_ratio = ray_distance / max(distance_to_player, 0.001)

    _target_lowpass = 1500 * wall_to_player_ratio
```

This value can then be applied to an **AudioEffectLowPassFilter** to dynamically adjust the sound.

---

## Features

* Dynamic sound occlusion
* Works with **3D spatial audio**
* No RayCast nodes required
* Lightweight physics queries
* Smooth audio filtering based on obstruction

---

## Requirements

* Godot 4.x
* 3D physics enabled
* An audio bus with a **LowPassFilter** effect

---

## Possible Improvements

Some ideas for extending the system:

* **Change player position from camera to actual character** Currently, if you attach your camera under a subviewport, this system won't work, so changing this to your player character's position instead should fix it. 
* **Material-based absorption** (different walls muffle sound differently)
* **Reverb zones** when sound passes through openings
* **Caching ray results** for performance when many audio sources exist

---

## Credits

Original concept inspired by:

**Spatial audio with Dynamic Acoustics in Godot | Tutorial**
https://youtu.be/mHokBQyB_08

This implementation modifies the technique by replacing **RayCast nodes** with **physics raycast queries** for a more flexible and scalable approach.
