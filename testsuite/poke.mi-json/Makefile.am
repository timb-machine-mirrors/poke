# Copyright (C) 2020, 2021 Jose E. Marchesi
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

AUTOMAKE_OPTIONS = subdir-objects

EXTRA_DIST = \
  mi-json.exp

if POKE_MI

if HAVE_DEJAGNU
check_PROGRAMS = mi-json
endif

mi_json_SOURCES = mi-json.c \
                  $(top_srcdir)/poke/pk-mi-msg.c \
                  $(top_srcdir)/poke/pk-mi-json.c

mi_json_CPPFLAGS = -I$(top_builddir)/gl -I$(top_srcdir)/gl \
                   -I$(top_srcdir)/poke -I$(top_builddir)/poke \
                   -DTESTDIR=\"$(abs_srcdir)\" \
                   -DPKGDATADIR=\"$(pkgdatadir)\" \
                   -I$(top_srcdir)/libpoke -I$(top_builddir)/libpoke

# Old DejaGnu versions need a specific old interpretation of 'inline'.
mi_json_CFLAGS = -fgnu89-inline $(JSON_C_CFLAGS)

mi_json_LDADD = $(JSON_C_LIBS) $(top_builddir)/gl/libgnu.la \
                $(top_builddir)/libpoke/libpoke.la

endif
