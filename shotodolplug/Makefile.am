include $(top_srcdir)/Makefile.common

NULL =

AM_CPPFLAGS = \
	$(COVERAGE_CFLAGS) \
	-I$(top_srcdir)/gee \
	$(GLIB_CFLAGS) \
	$(GMODULE_CFLAGS) \
	-DPACKAGE_DATADIR=\"$(pkgdatadir)\" \
	$(NULL)

BUILT_SOURCES = shotodolplug.vala.stamp

noinst_LTLIBRARIES = \
	libshotodolplug.la \
	$(NULL)

libshotodolplug_la_VALASOURCES = \
	module.vala \
	extension.vala \
	compositeextension.vala \
	plugin.vala \
	$(NULL)

libshotodolplug_la_SOURCES = \
	shotodolplug.vala.stamp \
	$(libshotodolplug_la_VALASOURCES:.vala=.c) \
	$(NULL)

valaincludedir = $(includedir)/vala@PACKAGE_SUFFIX@

valainclude_HEADERS = \
	shotodolplug.h \
	$(NULL)

shotodolplug.vapi shotodolplug.vala.stamp: $(libshotodolplug_la_VALASOURCES)
	$(VALA_V)$(VALAC) \
		$(COVERAGE_VALAFLAGS) \
		$(VALAFLAGS) \
		-C \
		--vapidir $(top_srcdir)/vapi --pkg gmodule-2.0 --pkg gobject-2.0 \
		--vapidir $(top_srcdir)/gee --pkg gee \
		--pkg config \
		-H shotodolplug.h \
		--library shotodolplug \
		$^
	@touch $@

libshotodolplug_la_LIBADD = \
	$(COVERAGE_LIBS) \
	$(GLIB_LIBS) \
	$(GMODULE_LIBS) \
	$(top_builddir)/gee/libgee.la \
	$(NULL)

EXTRA_DIST = $(libshotodolplug_la_VALASOURCES) shotodolplug.vapi shotodolplug.vala.stamp

MAINTAINERCLEANFILES = \
	shotodolplug.vapi \
	shotodolplug.h \
	$(libshotodolplug_la_VALASOURCES:.vala=.c) \
	$(NULL)
