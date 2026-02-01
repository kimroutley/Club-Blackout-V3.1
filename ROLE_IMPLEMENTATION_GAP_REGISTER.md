# Role Implementation Gap Register

Cross-check of `assets/data/roles.json` vs `ScriptBuilder` (script steps), `GameEngine` (execution), and UI completion paths.

Legend: ✅ complete | 🟡 partial/manual | ❌ missing

| Role ID | Name | Status | Script Steps (id:action) | Engine | UI | Notes / Remaining Gaps |
|---|---|:---:|---|---|---|---|
| ally_cat | The Ally Cat | 🟡 | ally_cat_meow:showInfo | passive (extra lives) + host-mediated social | GameScreen step controls (if scripted) | Nine lives implemented. “Meow-only communication” is a real-world rule; the app provides prompts/logging, not speech enforcement. |
| bartender | The Bartender | ✅ | bartender_act:selectTwoPlayers | handleScriptAction | GameScreen step controls (if scripted) |  |
| bouncer | The Bouncer | ✅ | bouncer_act:selectPlayer<br>bouncer_sleep:default | handleScriptAction + resolveBouncerRoofiChallenge | GameScreen step controls (if scripted) + FAB “Confront Roofi” | Challenge mechanic is available via FAB and fully resolves (success steals Roofi power; failure revokes ID checks). |
| clinger | The Clinger | ✅ | clinger_act:selectPlayer<br>clinger_obsession:selectPlayer<br>clinger_reveal:showInfo | handleScriptAction | GameScreen step controls (if scripted) |  |
| club_manager | The Club Manager | ✅ | club_manager_act:selectPlayer | handleScriptAction | GameScreen selection + private reveal modal |  |
| creep | The Creep | ✅ | creep_act:selectPlayer<br>creep_reveal:showInfo | handleScriptAction | GameScreen step controls (if scripted) |  |
| dealer | The Dealer | ✅ | dealer_act:selectPlayer<br>dealer_blocked:showInfo<br>dealer_sleep:default<br>second_wind_conversion_choice:binaryChoice | handleScriptAction | GameScreen step controls (if scripted) | Second Wind conversion choice is injected as a host-only Dealer step when applicable. |
| drama_queen | The Drama Queen | ✅ | drama_queen_act:selectTwoPlayers | handleScriptAction | GameScreen selection + HostOverview pending swap | Swap completed via HostOverview when pending. |
| lightweight | The Lightweight | 🟡 | lightweight_act:selectPlayer | handleScriptAction | GameScreen step controls (if scripted) | App tracks taboo names; enforcement is social/manual (no speech recognition). |
| medic | The Medic | ✅ | medic_protect:selectPlayer<br>medic_setup_choice:toggleOption<br>medic_sleep:default | handleScriptAction | GameScreen step controls (if scripted) |  |
| messy_bitch | The Messy Bitch | ✅ | messy_bitch_act:selectPlayer<br>messy_bitch_special_kill:selectPlayer<br>messy_bitch_special_sleep:default<br>messy_bitch_special_wake:default | handleScriptAction | GameScreen step controls (if scripted) |  |
| minor | The Minor | ✅ | (none) | passive (special death rule) | GameScreen step controls (if scripted) |  |
| party_animal | The Party Animal | ✅ | (none) | passive | GameScreen step controls (if scripted) |  |
| predator | The Predator | ✅ | predator_act:selectPlayer | handleScriptAction | HostOverview pending retaliation | Retaliation is completed via HostOverview using recorded votes/eligible voters. |
| roofi | The Roofi | ✅ | roofi_act:selectPlayer (generated) | handleScriptAction | GameScreen step controls (if scripted) |  |
| seasoned_drinker | The Seasoned Drinker | ✅ | (none) | passive (extra lives) | GameScreen step controls (if scripted) | Lives are set based on dealer count (baseline 1 + one per Dealer). |
| second_wind | The Second Wind | ✅ | (injected) second_wind_conversion_choice:binaryChoice | handleScriptAction | GameScreen step controls (if scripted) | Choice is injected before Dealer kill when a Second Wind is pending conversion that night. |
| silver_fox | The Silver Fox | ✅ | silver_fox_act:selectPlayer | handleScriptAction | GameScreen step controls (if scripted) | Nightly alibi: target becomes vote-immune for the following day (`alibiDay`). |
| sober | The Sober | ✅ | sober_act:selectPlayer | handleScriptAction | GameScreen step controls (if scripted) | Nightly send-home affects who wakes + blocks Dealer kill if Dealer sent home. |
| tea_spiller | The Tea Spiller | ✅ | tea_spiller_act:selectPlayer | handleScriptAction | GameScreen step controls (if scripted) | Engine stores marked target and resolves on death. |
| wallflower | The Wallflower | ✅ | wallflower_act:binaryChoice (integrated)<br>wallflower_act:optional (standalone)<br>wallflower_independent_witness:default | handleScriptAction | GameScreen step controls (if scripted) |  |
| whore | The Whore | ✅ | whore_deflect:selectPlayer | handleScriptAction | GameScreen step controls (if scripted) | Deflection target chosen in script; vote deflection resolves during day vote logic. |

## High-impact remaining gaps
- Lightweight taboo enforcement is manual (by design unless you want speech/name input rules).
- Ally Cat “witness ID checks” + “Meow” comms are social/manual (no digital enforcement).

