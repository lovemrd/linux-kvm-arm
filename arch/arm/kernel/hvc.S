/*
 * Copyright (C) 2012 - Virtual Open Systems and Columbia University
 * Author: Christoffer Dall <c.dall@virtualopensystems.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <linux/linkage.h>
#include <linux/const.h>
#include <asm/assembler.h>
#include <asm/virt.h>
#include <asm/opcodes-virt.h>

.text

/*
 * int hvc_call(unsigned num, void *arg0, void *arg1,
 * 		void *arg2, void *arg3, void *arg4)
 *
 * @num:  hypercall number passed in r12
 * @arg0: The first argument
 * @arg1: The second argument
 * @arg2: The third argument
 * @arg3: The fourth argument
 * @arg4: The fifth argument
 *
 * Perform an HVC (hyper call) according to the following procedure call
 * starndard:
 *
 * The arguments are passed in r0-r4
 * The hypercall number is passed in r12 (if applicable)
 * The return value is in r0 (if applicable)
 */
#define HVC_CALL(iss)						\
	stmdb	sp!, {r4, lr};					\
	mov	r12, r0;					\
	mov	r0, r1;						\
	mov	r1, r2;						\
	mov	r2, r3;						\
	ldr	r3, [sp, #12];					\
	ldr	r4, [sp, #8];					\
	__HVC(iss);						\
	ldmia	sp!, {r4, lr};					\
	bx	lr

/*
 * Perform a generic HVC call with hvc #0
 */
ENTRY(hvc_call)
	HVC_CALL(0)
ENDPROC(hvc_call)
