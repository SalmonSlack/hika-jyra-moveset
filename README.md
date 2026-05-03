# Hikaseru / Jyra Moveset
Custom SM64 Coop DX moveset for Hikaseru / Jyra

## 🎮 Move List
* Adds `Air Jumps` which can be performed by pressing `A` while descending. Up to 5 `Air Jumps` can be performed by default
* Adds `Grab` mechanic which applies to both players and a list of typically non-grabbable objects such as Goombas
  * `Punch` an object or player to put them into the `Held` state
  * Press `B` to throw a held object or player
  * Press `Z` to `Eat` a held object or player
* Adds `Eat` mechanic which allows the player to store other players or objects and `Spit` them out later
  * `Punch` or `Air Kick` to `Spit` a player or object out
  * Only one object or player can be eaten at a time
* Replaces `Dive` with `Belly Flop`
  * Hold `A` when making contact with the ground to bounce back into the air. Can chain these bounces infinitely
  * Press `A` while towards the peak of the bounce to cancel into an `Air Jump`
* Replaces `Slide Kick` with `Roll`
  * Can jump and `Belly Flop` out of a `Roll`
  * Press `B` to cancel the `Roll` into a `Belly Flop`
  * `Roll` can also be performed by holding `Z` and pressing `B` while landing from a `Ground Pound`
* Replaces `Long Jump` with `Belly Thrust`
  * Hold `A` when making contact with a wall during a `Belly Thrust` to cling to the wall
  * Release `A` while holding away from the wall to perform another `Belly Thrust` in that direction
  * `Belly Thrust` can be chained infinitely when combined with wall clings
* Replaces `Backflip` with `Belly Trampoline`
  * Other players can jump off a player in the `Belly Trampoline` state for increased height
 
## ⚙️ Modifying the Moveset / Applying to Other Models
The moveset is customizable and you can opt in / out of elements of the moveset you like!

### Editing Values
To edit individual values like speeds, gravity, number of air jumps, etc, you can modify the labelled constants in `main.lua` to your liking!

### Editing Audio
To edit audio files, place the files you'd like to use in the `sound` folder, and create new variables under the `Audio` section of `main.lua` and add them to the appropriate lists in `SOUNDS_TABLE`!

### Using a Different Model
To use a different model, add your `*_geo` file to the `actors` folder, and add your icon files to the `textures` folder. Then, modify the `Adding Hikaseru to Character Select` section in `main.lua` with the new information! Just make sure to update `HIKA_HITBOX_RADIUS` and `HIKA_HITBOX_HEIGHT` in `main.lua` to better suit your character's proportions! 

If you are finding the `Eat` and `Spit` actions aren't lining up with your character's model, you can replace the `*.marioObj.hitboxHeight - 40` found in `actions.lua`, `behaviors.lua`, and `hooks.lua` with a number that looks better!

### Removing Features
If there are parts of the moveset you don't want on your character, open `main.lua` and search for `_G.hikaMoveset.character_set_hika_flags(E_MODEL_HIKASERU, _G.hikaMoveset.FLAG_ALL)` and replace FLAG_ALL with a pipe delimited list of the flags for the moves you would like to include.

An example list could be `_G.hikaMoveset.FLAG_CAN_BELLY_FLOP | _G.hikaMoveset.FLAG_CAN_ROLL | _G.hikaMoveset.FLAG_CAN_GRAB_ENTITIES`. Refer to the `_G.hikaMoveset` table for a full list of flags!
