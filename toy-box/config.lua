-------------------------------------------------------------------------------
-- Defaults for settings in settings dialog. Tweak these if you have some 
-- values you like to use all the time for new games.
-------------------------------------------------------------------------------

DEFAULT_CATEGORIZE_ITEMS = true
DEFAULT_GROUP_ITEMS = true
DEFAULT_DONT_GROUP_ALL = true
DEFAULT_TABLE_COLUMNS = 20
DEFAULT_AUTOCLOSE = true
DEFAULT_NO_VEHICLE_AUTOCLOSE = true


-------------------------------------------------------------------------------
-- Less useful stuff is below this line.
-------------------------------------------------------------------------------

-- Checkboxes can display images without stretching them, but the minecraft 
-- look is kinda cool. So it's controllable here, for now.
USE_CHECKBOXES = true

-- Distance player must walk for the GUI to automatically close
GUI_CLOSE_DISTANCE = 0.1 -- actually we'll keep this super small

-- Interval (in ticks) for checking player positions for auto-close. This only 
-- happens while the GUI is open, it's not really a big deal.
POSITION_CHECK_INTERVAL = 6

-- Interval (in ticks) for updating dumpsters and bottomless chests. It's not
-- actually that performance hungry, but it doesn't really *need* to be that
-- often either.
CHEST_UPDATE_INTERVAL = 60
