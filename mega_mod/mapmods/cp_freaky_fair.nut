// Credit to Mr. Burguers for figuring this out and sharing how to do it in the TF2Maps discord.

local root = getroottable();
local prefix = DoUniqueString("mega");
local mega = root[prefix] <- {};

IncludeScript("mega_mod/common/5cp_anti_stalemate.nut");

::MM_CREDITS_RED <- 0;
::MM_CREDITS_BLU <- 0;

::MM_TRIGGERED <- false;

mega.OnGameEvent_teamplay_round_start <- function (event) {
    printl("MEGAMOD: Loading custom cp_freaky_fair logic...");

    ::MegaModRoundStart <- function () {
        if(IsInWaitingForPlayers()) return;

        // For reasons beyond my comprehension, the freaky_fair vscript is attached to an info_target.
        // This means the script only runs *once* when the map loads, meaning that if the line of code
        // below runs more than once, we end up assigning our AwardCreditsToTeam to the base handle as well,
        // creating an infinite loop. https://developer.valvesoftware.com/wiki/Info_target
        if (MM_TRIGGERED == false)
            AwardCreditsToTeamBase <- AwardCreditsToTeam;

        ::MM_TRIGGERED <- true;

        AwardCreditsToTeam <- function (team, amount)
        {
            if (team == Constants.ETFTeam.TF_TEAM_RED) {
                ::MM_CREDITS_RED <- MM_CREDITS_RED + amount;
            } else if (team == Constants.ETFTeam.TF_TEAM_BLUE) {
                ::MM_CREDITS_BLU <- MM_CREDITS_BLU + amount;
            }
            printl("Added " + amount + " credits to team " + team);
            AwardCreditsToTeamBase(team, amount);
        }.bindenv(MM_GetEntByName("scripto").GetScriptScope());

        // Set both team's credit values to the greater of the two.
        ::MM_CREDITS_RED <- MM_CREDITS_RED > MM_CREDITS_BLU ? MM_CREDITS_RED : MM_CREDITS_BLU;
        ::MM_CREDITS_BLU <- MM_CREDITS_RED;

        AwardCreditsToTeamBase(Constants.ETFTeam.TF_TEAM_RED, MM_CREDITS_RED);
        AwardCreditsToTeamBase(Constants.ETFTeam.TF_TEAM_BLUE, MM_CREDITS_BLU);

        MM_5CP_Activate();

    }.bindenv(MM_GetEntByName("scripto").GetScriptScope())

    EntFireByHandle(MM_GetEntByName("scripto"), "RunScriptCode", "MegaModRoundStart()", 0, null, null);
}

mega.ClearGameEventCallbacks <- ::ClearGameEventCallbacks
::ClearGameEventCallbacks <- function () {
    mega.ClearGameEventCallbacks()
    ::__CollectGameEventCallbacks(mega)
}
::__CollectGameEventCallbacks(mega);