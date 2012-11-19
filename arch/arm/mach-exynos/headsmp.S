/*
 *  linux/arch/arm/mach-exynos4/headsmp.S
 *
 *  Cloned from linux/arch/arm/mach-realview/headsmp.S
 *
 *  Copyright (c) 2003 ARM Limited
 *  All Rights Reserved
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */
#include <linux/linkage.h>
#include <linux/init.h>

	.syntax	unified
	.arch_extension sec
	.arch_extension virt
	.text

	__CPUINIT

.align 5

/* We use the same vector table for Hyp and Monitor mode, since
 * we will only use each once and they don't overlap.
 */
mon_vectors:
	.word 0	/* reset */
	.word 0	/* undef */
	b	2f /* smc */
	.word 0 /* pabt */
	.word 0 /* dabt */
	b	1f
	.word 0 /* irq */
	.word 0 /* fiq */

/* Return directly back to the caller without leaving Hyp mode: */
1:	mrs	lr, elr_hyp
	mov	pc, lr

/* In monitor mode, set up HVBAR and SCR then return to caller in NS-SVC. */
2:
	mrc	p15, 0, r10, c1, c1, 0		@ SCR
	/*
	 * Set SCR.NS=1 (needed for setting HVBAR and also returning to NS state)
	 *        .IRQ,FIQ,EA=0 (don't take aborts/exceptions to Monitor mode)
	 *        .FW,AW=1 (CPSR.A,F modifiable in NS state)
	 *        .nET=0 (early termination OK)
	 *        .SCD=0 (SMC in NS mode OK, so we can call secure firmware)
	 *        .HCE=1 (HVC does Hyp call)
	 */
	bic	r10, r10, #0x07f
	ldr	r11, =0x131
	orr	r10, r10, r11
	mcr	p15, 0, r11, c1, c1, 0		@ SCR
	isb
	ldr	r11, =mon_vectors
	mcr	p15, 4, r11, c12, c0, 0		@ set HVBAR
	/* ...and return to calling code in NS state */
	movs	pc, lr

/*
 * exynos4 specific entry point for secondary CPUs.  This provides
 * a "holding pen" into which all secondary cores are held until we're
 * ready for them to initialise.
 */
ENTRY(exynos4_secondary_startup)
	mrc	p15, 0, r0, c0, c0, 5
	and	r0, r0, #15
	adr	r4, 1f
	ldmia	r4, {r5, r6}
	sub	r4, r4, r5
	add	r6, r6, r4
pen:	ldr	r7, [r6]
	cmp	r7, r0
	bne	pen

	/* Let's switch to Hyp mode */
	ldr	ip, =mon_vectors
	mcr	p15, 0, ip, c12, c0, 1		@ Monitor vector base address
	smc	#0
	hvc	#0

	/*
	 * we've been released from the holding pen: secondary_stack
	 * should now contain the SVC stack for this core
	 */
	b	secondary_startup
ENDPROC(exynos4_secondary_startup)

	.align 2
1:	.long	.
	.long	pen_release
