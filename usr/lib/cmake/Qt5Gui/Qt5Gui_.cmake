
add_library(Qt5:: MODULE IMPORTED)

_populate_Gui_plugin_properties( RELEASE "platforms/libcustom-wayland.so")

list(APPEND Qt5Gui_PLUGINS Qt5::)
