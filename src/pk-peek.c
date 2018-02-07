/* pk-peek.c - `peek' command.  */

/* Copyright (C) 2018 Jose E. Marchesi */

/* This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <config.h>
#include <assert.h>
#include <stdio.h> /* For stdout */
#include <gettext.h>
#define _(str) dgettext (PACKAGE, str)

#include "pk-cmd.h"
#include "pk-io.h"

static int
pk_cmd_peek (int argc, struct pk_cmd_arg argv[], uint64_t uflags)
{
  /* peek [ADDR]  */

  pvm_program prog;
  pk_io_off address;
  int c;
  pvm_val val;
  int pvm_ret;

  assert (argc == 1);

  if (PK_CMD_ARG_TYPE (argv[0]) == PK_CMD_ARG_NULL)
    {
      address = pk_io_tell (pk_io_cur ());
    }
  else
    {
      assert (PK_CMD_ARG_TYPE (argv[0]) == PK_CMD_ARG_EXP);
      prog = PK_CMD_ARG_EXP (argv[0]);

      pvm_ret = pvm_run (prog, &val);
      if (pvm_ret != PVM_EXIT_OK)
        goto rterror;

      if (!PVM_IS_NUMBER (val) || PVM_VAL_NUMBER (val) < 0)
        {
          printf (_("Bad ADDRESS.\n"));
          return 0;
        }

      address = PVM_VAL_NUMBER (val);
    }
  
  /* XXX: endianness, and what not.  */
  pk_io_seek (pk_io_cur (), address, PK_SEEK_SET);
  c = pk_io_getc ();
  if (c == PK_EOF)
    printf ("EOF\n");
  else
    printf ("0x%08jx 0x%x\n", address, c);

  return 1;

 rterror:
  printf (_("run-time error: %s\n"), pvm_error (pvm_ret));
  return 0;
}

static int
pk_cmd_help_peek (int argc, struct pk_cmd_arg argv[], uint64_t uflags)
{
  /* help peek  */

  assert (argc == 0);

  puts (_("The peek command fetches a value from the current IO"));
  puts ("stream.");
  
  return 1;
}

struct pk_cmd peek_cmd =
  {"peek", "?e", "", PK_CMD_F_REQ_IO, NULL, pk_cmd_peek, "peek [ADDRESS]"};

struct pk_cmd help_peek_cmd =
  {"peek", "", "", 0, NULL, pk_cmd_help_peek, "help peek"};
