--[[
    DayPhaseConfig.lua  (STAGING — merge to src/shared after approval)
    Server-local day rhythm for Palm Springs Paradise core loop.

    Phases map to README loop:
      Morning   → garden + shop
      Afternoon → home + outfits
      Evening   → fashion + community events (+ optional night)
]]

export type DayPhase = "Morning" | "Afternoon" | "Evening"

local DayPhaseConfig = {}

DayPhaseConfig.Phases = { "Morning", "Afternoon", "Evening" } :: { DayPhase }

-- Server clock boundaries (hour, 0–23). Uses os.date("*t").hour on server.
DayPhaseConfig.Boundaries = {
    Morning = { startHour = 6, endHour = 11 },
    Afternoon = { startHour = 11, endHour = 17 },
    Evening = { startHour = 17, endHour = 22 },
}

-- Outside 22–6 rolls to Morning (desert "early light" — keeps garden loop alive)
DayPhaseConfig.DefaultPhase = "Morning" :: DayPhase

---------------------------------------------------------------------------
-- Player-facing hints (HUD + notifications)
---------------------------------------------------------------------------
DayPhaseConfig.Hints = {
    Morning = {
        title = "Morning in the Desert",
        body = "Tend the community garden and stock your El Paseo boutique.",
        actions = { "garden", "shop" },
    },
    Afternoon = {
        title = "Afternoon Glow",
        body = "Decorate your MCM home and curate poolside outfits.",
        actions = { "plot", "fashion_prep" },
    },
    Evening = {
        title = "Evening Soirée",
        body = "Join the runway, trade on the boulevard, catch the festival.",
        actions = { "fashion", "shop", "events" },
    },
}

---------------------------------------------------------------------------
-- Gameplay modifiers (applied by CoreLoopService)
---------------------------------------------------------------------------
DayPhaseConfig.Modifiers = {
    Morning = {
        gardenGrowthMultiplier = 1.25,
        fashionEventsAllowed = false,
        nightToggleAllowed = false,
        shopRestockReminder = true,
    },
    Afternoon = {
        gardenGrowthMultiplier = 1.0,
        fashionEventsAllowed = false, -- prep only; FashionService timer still runs
        nightToggleAllowed = false,
        shopRestockReminder = false,
    },
    Evening = {
        gardenGrowthMultiplier = 1.0,
        fashionEventsAllowed = true,
        nightToggleAllowed = true,
        shopRestockReminder = false,
    },
}

---------------------------------------------------------------------------
-- Resolve phase from server hour
---------------------------------------------------------------------------
function DayPhaseConfig.getPhaseFromHour(hour: number): DayPhase
    if
        hour >= DayPhaseConfig.Boundaries.Morning.startHour
        and hour < DayPhaseConfig.Boundaries.Morning.endHour
    then
        return "Morning"
    elseif
        hour >= DayPhaseConfig.Boundaries.Afternoon.startHour
        and hour < DayPhaseConfig.Boundaries.Afternoon.endHour
    then
        return "Afternoon"
    elseif
        hour >= DayPhaseConfig.Boundaries.Evening.startHour
        and hour < DayPhaseConfig.Boundaries.Evening.endHour
    then
        return "Evening"
    end
    return DayPhaseConfig.DefaultPhase
end

function DayPhaseConfig.getCurrentPhase(): DayPhase
    return DayPhaseConfig.getPhaseFromHour(os.date("*t").hour)
end

function DayPhaseConfig.getHint(phase: DayPhase)
    return DayPhaseConfig.Hints[phase]
end

function DayPhaseConfig.getModifiers(phase: DayPhase)
    return DayPhaseConfig.Modifiers[phase]
end

return DayPhaseConfig
