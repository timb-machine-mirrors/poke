# Copyright (C) 2020 Jose E. Marchesi
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

COMMON = term-if.h

check_PROGRAMS = values
values_SOURCES = $(COMMON) values.c

values_CPPFLAGS = -I$(top_builddir)/gl -I$(top_srcdir)/gl \
                  -I$(top_srcdir)/common \
                  -I$(top_srcdir)/libpoke -I$(top_builddir)/libpoke

values_LDADD = $(top_builddir)/gl/libgnu.la \
               $(top_builddir)/libpoke/libpoke.la