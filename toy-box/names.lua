require "config"

-- STYLES

BASE_SOUND_BUTTON_STYLE = "toy-box-base-button-style"
MAIN_BUTTON_STYLE = "toy-box-button-style"
ITEM_BUTTON_BASE_STYLE = "toy-box-item-button-base"
-- in 0.1.1 style name changed to icon2 as workaround for https://forums.factorio.com/viewtopic.php?f=25&t=23968
ITEM_BUTTON_STYLE_PREFIX = (USE_CHECKBOXES and "toy-box-item-icons2-" or "toy-box-item-icons-")
ITEM_TABLE_STYLE = "toy-box-item-table-style"
SETTINGS_BUTTON_STYLE = "toy-box-settings-button-style"
MISC_BUTTON_STYLE = "toy-box-misc-button-style"
ACTION_BUTTON_STYLE = "toy-box-action-button-style"
DESCRIPTION_LABEL_STYLE = "toy-box-description-label-style"
DIALOG_PADDING_LABEL_STYLE = "toy-box-left-padding-label-style"
CATEGORY_BUTTON_STYLE = "toy-box-category-button-style"
FUNCTION_BUTTON_STYLE = "toy-box-function-button-style"

-- GUI ELEMENTS

MAIN_BUTTON_NAME = "toy-box-button"
MAIN_FRAME_NAME = "toy-box-frame"
ITEM_TABLE_NAME = "toy-box-item-table"
ITEM_TABLE_FRAME_NAME = "toy-box-item-table-frame"
ITEM_BUTTON_NAME_PREFIX = "toy-box-item-button-"
CATEGORY_BUTTON_NAME_PREFIX = "toy-box-category-button-"
SETTINGS_BUTTON_NAME = "toy-box-settings-button"
SETTINGS_FRAME_NAME = "toy-box-settings-frame"
SETTINGS_OK_BUTTON_NAME = "toy-box-settings-ok-button"
SETTINGS_CANCEL_BUTTON_NAME = "toy-box-settings-cancel-button"

-- GUI ELEMENTS ON SETTINGS DIALOG

SETTING_AUTOCLOSE_ELEMENT_NAME = "toy-box-setting-autoclose"
SETTING_NVAUTOCLOSE_ELEMENT_NAME = "toy-box-setting-no-vehicle-autoclose"
SETTING_COLUMNS_ELEMENT_NAME = "toy-box-setting-table-columns"
SETTING_CATEGORIZE_ELEMENT_NAME = "toy-box-setting-categorize-items"
SETTING_GROUP_ELEMENT_NAME = "toy-box-setting-group-items"
SETTING_NGROUPALL_ELEMENT_NAME = "toy-box-setting-no-group-all"

-- SETTINGS KEYS IN global.player_data[].settings

SETTING_AUTOCLOSE = "autoclose"
SETTING_NVAUTOCLOSE = "no_vehicle_autoclose"
SETTING_COLUMNS = "table_columns"
SETTING_CATEGORIZE = "categorize_items"
SETTING_GROUP = "group_items"
SETTING_NGROUPALL = "dont_group_all"

-- MISC.

BUTTON_CLICK_SOUND_NAME = "toy-box-button-sound"
CATEGORY_FONT_NAME = "toy-box-category-font"