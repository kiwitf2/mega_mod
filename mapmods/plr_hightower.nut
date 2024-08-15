ClearGameEventCallbacks();
IncludeScript("mega_mod/common/plr_overtime.nut");

function OnGameEvent_teamplay_round_start(params) {

    ::PLR_TIMER_NAME <- "plr_timer";
    ::PLR_TIMER = MM_GetEntByName(PLR_TIMER_NAME);

    ::RED_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_red_cartsparks");
    ::BLU_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_blu_cartsparks");

    ::RED_FLASHINGLIGHT <- MM_GetEntByName("plr_red_flashinglight");
    ::BLU_FLASHINGLIGHT <- MM_GetEntByName("plr_blu_flashinglight");

    ::RED_PUSHZONE <- MM_GetEntByName("plr_red_pushzone");
    ::BLU_PUSHZONE <- MM_GetEntByName("plr_blu_pushzone");

    ::RED_ROLLBACK_BRANCH <- MM_GetEntByName("plr_red_rollback");
    ::BLU_ROLLBACK_BRANCH <- MM_GetEntByName("plr_blu_rollback");

    ::RED_TRAIN <- MM_GetEntByName("plr_red_train");
    ::BLU_TRAIN <- MM_GetEntByName("plr_blu_train");

    // When a cart changes player count, call respective update function
    AddCaptureOutputsToEntity(MM_GetEntByName("plr_red_pushingcase"), "Red");
    AddCaptureOutputsToEntity(MM_GetEntByName("plr_blu_pushingcase"), "Blu")

    // Ensure overtime works on the crossover.
    EntityOutputs.AddOutput(MM_GetEntByName("plr_red_crossover1_branch"), "OnTrue", "!self", "RunScriptCode", "SetRedCrossing(1)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_red_crossover1_relay"), "OnTrigger", "!self", "RunScriptCode", "SetRedCrossing(-1)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_blu_crossover1_branch"), "OnTrue", "!self", "RunScriptCode", "SetBluCrossing(1)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("plr_blu_crossover1_relay"), "OnTrigger", "!self", "RunScriptCode", "SetBluCrossing(-1)", 0, -1);

    // Cart onboarding for elevator
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_red_positioncart_relay_begin"), "OnTrigger", "!self", "RunScriptCode", "BlockRedCart(true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_blu_positioncart_relay_begin"), "OnTrigger", "!self", "RunScriptCode", "BlockBluCart(true)", 0, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_red_positioncart_relay_end"), "OnTrigger", "!self", "RunScriptCode", "SwitchToElevatorRed()", 0.95, -1);
    EntityOutputs.AddOutput(MM_GetEntByName("clamp_blu_positioncart_relay_end"), "OnTrigger", "!self", "RunScriptCode", "SwitchToElevatorBlu()", 0.95, -1);

    // Clear out elevator logic
    MM_GetEntByName("clamp_logic_case_red").Kill();
    MM_GetEntByName("clamp_logic_case").Kill();

    EntityOutputs.RemoveOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "Disable", "");
    EntityOutputs.AddOutput(PLR_TIMER, "OnSetupFinished", PLR_TIMER_NAME, "SetTime", "600", 0, -1);
    EntityOutputs.AddOutput(PLR_TIMER, "OnFinished", "!self", "RunScriptCode", "StartOvertime()", 0, -1);
}

::StartOvertimeBase <- StartOvertime;

function StartOvertime() {
    local redRollbackRelay = MM_GetEntByName("plr_red_rollback_relay");
    local bluRollbackRelay = MM_GetEntByName("plr_blu_rollback_relay");

    // Prevent other calls to overtime logic
    EntFireByHandle(redRollbackRelay, "Disable", "", 0, null, null);
    EntFireByHandle(bluRollbackRelay, "Disable", "", 0, null, null);

    StartOvertimeBase();
}

::AdvanceRedBase <- AdvanceRed;
::StopRedBase <- StopRed;
::AdvanceBluBase <- AdvanceBlu;
::StopBluBase <- StopBlu;

function AdvanceRed() {
    AdvanceRedBase();
    if(RED_ELV) {
        EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(RED_ELV, "SetSpeedDirAccel", "0.22", 0.1, null, null);
    }
}

function StopRed() {
    StopRedBase();
    if(RED_ELV) {
        EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(RED_ELV, "SetSpeedDirAccel", "0.0", 0.1, null, null);
    }
}

function AdvanceBlu() {
    AdvanceBluBase();
    if(BLU_ELV) {
        EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(BLU_ELV, "SetSpeedDirAccel", "0.22", 0.1, null, null);
    }
}

function StopBlu() {
    StopBluBase();
    if(BLU_ELV) {
        EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
        EntFireByHandle(BLU_ELV, "SetSpeedDirAccel", "0.0", 0.1, null, null);
    }
}

// When the cart goes on the elevator, trigger necessary logic.
// Also disables rollback, otherwise it becomes impossible to maintain sync
// between the two func_tracktrains.
function SwitchToElevatorRed() {
    ::RED_ELV <- MM_GetEntByName("clamp_red");
    ::RED_PUSHZONE <- MM_GetEntByName("plr_red_pushzone_elv");
    ::RED_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_red_elevatorsparks");

    DisableRollback();

    local redPushingCaseElv = MM_GetEntByName("plr_red_pushingcase_elv");
    AddCaptureOutputsToEntity(redPushingCaseElv, "Red");
    EntityOutputs.AddOutput(redPushingCaseElv, "OnCase01", "clamp_red", "SetSpeedDirAccel", "0.0", 0, -1);
    EntityOutputs.AddOutput(redPushingCaseElv, "OnDefault", "clamp_red", "SetSpeedDirAccel", "0.77", 0, -1);

    EntityOutputs.AddOutput(RED_ROLLBACK_BRANCH, "OnTrue", "clamp_red", "SetSpeedDirAccel", "-1.0", 0, -1);
    EntityOutputs.AddOutput(RED_ROLLBACK_BRANCH, "OnFalse", "clamp_red", "SetSpeedDirAccel", "0.0", 0, -1);

    EntFireByHandle(RED_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
    EntFireByHandle(RED_TRAIN, "TeleportToPathTrack", "plr_red_pathC_hillA3", 0, null, null);

    BlockRedCart(false);
}

function SwitchToElevatorBlu() {
    ::BLU_ELV <- MM_GetEntByName("clamp_blue");
    ::BLU_PUSHZONE <- MM_GetEntByName("plr_blu_pushzone_elv");
    ::BLU_CARTSPARKS_ARRAY <- MM_GetEntArrayByName("plr_blu_elevatorsparks");

    DisableRollback();

    local bluPushingCaseElv = MM_GetEntByName("plr_blu_pushingcase_elv");
    AddCaptureOutputsToEntity(bluPushingCaseElv, "Blu");
    EntityOutputs.AddOutput(bluPushingCaseElv, "OnCase01", "clamp_blue", "SetSpeedDirAccel", "0.0", 0, -1);
    EntityOutputs.AddOutput(bluPushingCaseElv, "OnDefault", "clamp_blue", "SetSpeedDirAccel", "0.77", 0, -1);

    EntityOutputs.AddOutput(BLU_ROLLBACK_BRANCH, "OnTrue", "clamp_blue", "SetSpeedDirAccel", "-1.0", 0, -1);
    EntityOutputs.AddOutput(BLU_ROLLBACK_BRANCH, "OnFalse", "clamp_blue", "SetSpeedDirAccel", "0.0", 0, -1);

    EntFireByHandle(BLU_ELV, "SetSpeedForwardModifier", "0.25", 0, null, null);
    EntFireByHandle(BLU_TRAIN, "TeleportToPathTrack", "plr_blu_pathC_hillA3", 0, null, null);

    BlockBluCart(false);
}

__CollectGameEventCallbacks(this);