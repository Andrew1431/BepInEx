# BepInEx pack for Moon Sweepers

An unofficial build of BepInEx 6 IL2CPP for Moon Sweepers (Unity 6000.6, IL2CPP metadata v108), which stock BepInEx
can't load yet. It's meant as the shared dependency for Moon Sweepers mods until official BepInEx builds support the
game, and it isn't made by or supported by the BepInEx team.

Install it, then launch the game once. The first launch generates the interop assemblies, which takes a few minutes.
Close any other mod loader first, and remove ModEngine if you have it installed.

## Status

Test build. It has been tested in single player on Windows. Multiplayer, Linux and other Unity games are untested.

## Source

- BepInEx: <https://github.com/Andrew1431/BepInEx/tree/moonsweepers-pack> (LGPL-2.1)
- Il2CppInterop: <https://github.com/Andrew1431/Il2CppInterop/tree/v108> (LGPL-3.0)

Licence texts are in the `licenses` folder. To rebuild the pack from source, run `build-moonsweepers-pack.ps1` from the
BepInEx branch.
