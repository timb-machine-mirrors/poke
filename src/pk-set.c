/* pk-set.c - Commands to show and set properties.  */

/* Copyright (C) 2019 Jose E. Marchesi */

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
#include <gettext.h>
#define _(str) dgettext (PACKAGE, str)
#include <assert.h>
#include <string.h>
#include <arpa/inet.h> /* For htonl */

#include "poke.h"
#include "pk-cmd.h"
#include "ios.h"
#include "pvm.h"

#define STREQ(a, b) (strcmp (a, b) == 0)

static int
pk_cmd_set_obase (int argc, struct pk_cmd_arg argv[], uint64_t uflags)
{
  /* set obase {2,8,10,16} */
  int base = PK_CMD_ARG_INT (argv[0]);

  if (base != 10 && base != 16 && base != 2 && base != 8)
    {
      fputs ("error: obase should be one of 2, 8, 10 or 16.\n", stdout);
      return 0;
    }

  poke_obase = base;
  return 1;
}

static int
pk_cmd_set_endian (int argc, struct pk_cmd_arg argv[], uint64_t uflags)
{
  /* set endian {little,big,host,network}  */

  const char *arg;

  /* Note that it is not possible to distinguish between no argument
     and an empty unique string argument.  Therefore, argc should be
     always 1 here, and we determine when no value was specified by
     checking whether the passed string is empty or not.  */

  if (argc != 1)
    assert (0);

  arg = PK_CMD_ARG_STR (argv[0]);

  if (*arg == '\0')
    {
      enum ios_endian endian = pvm_endian (poke_vm);

      switch (endian)
        {
        case IOS_ENDIAN_LSB: printf ("little\n"); break;
        case IOS_ENDIAN_MSB: printf ("big\n"); break;
        default:
          assert (0);
        }
    }
  else
    {
      enum ios_endian endian;

      if (STREQ (arg, "little"))
        endian = IOS_ENDIAN_LSB;
      else if (STREQ (arg, "big"))
        endian = IOS_ENDIAN_MSB;
      else if (STREQ (arg, "host"))
        {
#ifdef WORDS_BIGENDIAN
          endian = IOS_ENDIAN_MSB;
#else
          endian = IOS_ENDIAN_LSB;
#endif
        }
      else if (STREQ (arg, "network"))
        {
          uint32_t canary = 0x11223344;

          if (canary == htonl (canary))
            {
#ifdef WORDS_BIGENDIAN
              endian = IOS_ENDIAN_MSB;
#else
              endian = IOS_ENDIAN_LSB;
#endif
            }
          else
            {
#ifdef WORDS_BIGENDIAN
              endian = IOS_ENDIAN_LSB;
#else
              endian = IOS_ENDIAN_MSB;
#endif
            }
        }
      else
        {
          fputs ("error: endian should be one of `little', `big', `host' or `network'.\n",
                 stdout);
          return 0;
        }

      pvm_set_endian (poke_vm, endian);
    }

  return 1;
}

static int
pk_cmd_set_nenc (int argc, struct pk_cmd_arg argv[], uint64_t uflags)
{
  /* set nenc {1c,2c}  */

  const char *arg;

  /* Note that it is not possible to distinguish between no argument
     and an empty unique string argument.  Therefore, argc should be
     always 1 here, and we determine when no value was specified by
     checking whether the passed string is empty or not.  */

  if (argc != 1)
    assert (0);

  arg = PK_CMD_ARG_STR (argv[0]);

  if (*arg == '\0')
    {
      enum ios_nenc nenc = pvm_nenc (poke_vm);

      switch (nenc)
        {
        case IOS_NENC_1: printf ("1c\n"); break;
        case IOS_NENC_2: printf ("2c\n"); break;
        default:
          assert (0);
        }
    }
  else
    {
      enum ios_nenc nenc;

      if (STREQ (arg, "1c"))
        nenc = IOS_NENC_1;
      else if (STREQ (arg, "2c"))
        nenc = IOS_NENC_2;
      else
        {
          fputs ("error: nenc should be one of `1c' or `2c'.\n",
                 stdout);
          return 0;
        }

      pvm_set_nenc (poke_vm, nenc);
    }

  return 1;
}

extern struct pk_cmd null_cmd; /* pk-cmd.c  */

struct pk_cmd set_obase_cmd =
  {"obase", "i", "", 0, NULL, pk_cmd_set_obase, "set obase (2|8|10|16)"};

struct pk_cmd set_endian_cmd =
  {"endian", "s?", "", 0, NULL, pk_cmd_set_endian, "set endian (little|big|host)"};

struct pk_cmd set_nenc_cmd =
  {"nenc", "s?", "", 0, NULL, pk_cmd_set_nenc, "set nenc (1c|2c)"};

struct pk_cmd *set_cmds[] =
  {
   &set_obase_cmd,
   &set_endian_cmd,
   &set_nenc_cmd,
   &null_cmd
  };

struct pk_trie *set_trie;

struct pk_cmd set_cmd =
  {"set", "", "", 0, &set_trie, NULL, "set PROPERTY"};
