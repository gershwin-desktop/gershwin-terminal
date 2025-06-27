# copyright 2002, 2003 Alexander Malmberg <alexander@malmberg.org>
#
# This file is a part of Terminal.app. Terminal.app is free software; you
# can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation; version 2
# of the License. See COPYING or main.m for more information.


GNUSTEP_INSTALLATION_DOMAIN = LOCAL
include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Terminal
PACKAGE_NAME = Terminal
VERSION = 0.98
Terminal_APPLICATION_ICON = Terminal.tiff
Terminal_MAIN_MODEL_FILE = Terminal.gorm

SUBPROJECTS = Preferences

Terminal_OBJC_FILES = \
	main.m \
	Controller.m \
	\
	Defaults.m\
	\
	SetTitlePanel.m\
	\
	TerminalServices.m \
	TerminalServicesPanel.m \
	\
	TerminalWindow.m \
	TerminalView.m \
	TerminalParser_Linux.m \
	\
	InfoPanel.m\
	\
	TerminalFinder.m \
	TerminalIcon.m \

Terminal_LANGUAGES = English
Terminal_LOCALIZED_RESOURCE_FILES = \
	Localizable.strings \
	Terminal.gorm \
	SetTitlePanel.gorm \
	TerminalServices.gorm \
	SaveAsAccessory.gorm \
	AddArguments.gorm \
	Info.gorm \
	Find.gorm

Terminal_RESOURCE_FILES = \
	Preferences/Preferences.bundle \
	Resources/ExampleServices.svcs \
	Resources/Terminal.tiff \
	Resources/ScrollingMach.tiff \
	Resources/ScrollingOutput.tiff

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
