/* pvm.h - Poke Virtual Machine.  Definitions.   */

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

#ifndef PVM_H
#define PVM_H

#include <config.h>

#include "ios.h"

#include "pvm-val.h"
#include "pvm-env.h"

/* The following enumeration contains every possible exit code
   resulting from the execution of a program in the PVM.  */

enum pvm_exit_code
  {
    PVM_EXIT_OK,
    PVM_EXIT_ERROR,
    PVM_EXIT_EDIVZ
  };

/* Note that the jitter-generated header should be included this late
   in the file because it uses some stuff defined above.  */
#include "pvm-vm.h"

typedef struct pvm *pvm;

/* A PVM program can be executed in the virtual machine at any time.
   The struct pvm_program is provided by Jitter, but we provide here
   an opaque type to be used by the PVM users.  */

typedef struct pvm_program *pvm_program;

/* Initialize a new Poke Virtual Machine and return it.  */

pvm pvm_init (void);

/* Finalize a Poke Virtual Machine, freeing all used resources.  */

void pvm_shutdown (pvm pvm);

/* Get the current run-time environment of PVM.  */

pvm_env pvm_get_env (pvm pvm);

/* Run a PVM program in a given Poke Virtual Machine.  Put the
   resulting value in RES, if any, and return an exit code.  */

enum pvm_exit_code pvm_run (pvm pvm,
                            pvm_program prog,
                            pvm_val *res);

/* Set the current endianness and negative encoding for PVM.  */

void pvm_set_endian (pvm pvm, enum ios_endian endian);
void pvm_set_nenc (pvm pvm, enum ios_nenc nenc);

/* Set the current negative encoding for PVM.  NENC should be one of
 * the IOS_NENC_* values defined in ios.h */

/* Get a string with a description of a PVM exit code as returned by
   `pvm_run'.  */

const char *pvm_error (enum pvm_exit_code code);

/* The following function is to be used in pvm.jitter, because the
   system `assert' may expand to a macro and is therefore
   non-wrappeable.  */

void pvm_assert (int expression);

#endif /* ! PVM_H */
