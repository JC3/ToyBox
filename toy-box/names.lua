require "config"

MAIN_BUTTON_STYLE = "toy-box-button-style"
ITEM_BUTTON_BASE_STYLE = "toy-box-item-button-base"
-- in 0.1.1 style name changed to icon2 as workaround for https://forums.factorio.com/viewtopic.php?f=25&t=23968
ITEM_BUTTON_STYLE_PREFIX = (USE_CHECKBOXES and "toy-box-item-icons2-" or "toy-box-item-icons-")

MAIN_BUTTON_NAME = "toy-box-button"
MAIN_FRAME_NAME = "toy-box-frame"
ITEM_TABLE_NAME = "toy-box-item-table"
ITEM_BUTTON_NAME_PREFIX = "toy-box-item-button-"

BUTTON_CLICK_SOUND_NAME = "toy-box-button-sound"
