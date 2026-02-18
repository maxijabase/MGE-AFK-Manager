# MGE AFK Manager

An extension plugin for [TF2 AFK Manager](https://github.com/maxijabase/TF2-AFK-Manager) that removes AFK players from [MGEMod](https://github.com/maxijabase/MGEMod) arenas.

## What It Does

- Monitors players who are in an MGE arena and go AFK.
- Sends periodic chat warnings telling them how long until they're removed.
- Removes them from the arena once the configured time is reached.
- Respects the core AFK Manager's admin immunity system.
- Optionally adds its own flag-based removal immunity, for cases where you want arena-specific overrides separate from the core.

## ConVars

| ConVar | Default | Description |
|---|---|---|
| `sm_mge_afk_remove_time` | `60` | Seconds of AFK time before a player is removed from their arena. |
| `sm_mge_afk_warn_interval` | `10` | Seconds between AFK warnings to arena players. |
| `sm_mge_afk_immunity_flag` | `""` | Admin flag(s) that grant immunity to MGE AFK removal. Blank = disabled (falls back to core immunity). |

## Requirements

- SourceMod 1.12
- [TF2 AFK Manager](https://github.com/maxijabase/TF2-AFK-Manager)
- [MGEMod](https://github.com/maxijabase/MGEMod)
