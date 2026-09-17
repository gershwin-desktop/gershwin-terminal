
include $(GNUSTEP_MAKEFILES)/common.make
GNUSTEP_INSTALLATION_DOMAIN = SYSTEM

BUNDLE_NAME=Preferences
BUNDLE_EXTENSION=.bundle
$(BUNDLE_NAME)_PRINCIPAL_CLASS=Preferences

###$(BUNDLE_NAME)_RESOURCE_FILES=$(wildcard Images/*) $(wildcard Resources/*)

$(BUNDLE_NAME)_OBJC_FILES=$(wildcard *.m)
$(BUNDLE_NAME)_LOCALIZED_RESOURCE_FILES=$(notdir $(wildcard English.lproj/*))
$(BUNDLE_NAME)_LANGUAGES=$(basename $(wildcard *.lproj))
$(BUNDLE_NAME)_STANDARD_INSTALL=no

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble

