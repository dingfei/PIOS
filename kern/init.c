/*
 * Kernel initialization.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/cdefs.h>
#include <inc/elf.h>
#include <inc/vm.h>

#include <kern/init.h>
#include <kern/cons.h>
#include <kern/debug.h>
#include <kern/mem.h>
#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/spinlock.h>
#include <kern/mp.h>
#include <kern/proc.h>

#include <dev/pic.h>
#include <dev/lapic.h>
#include <dev/ioapic.h>


// User-mode stack for user(), below, to run on.
static char gcc_aligned(16) user_stack[PAGESIZE];

void elf_binary_loader(char* elf, pde_t* pdir);


// Lab 3: ELF executable containing root process, linked into the kernel
#ifndef ROOTEXE_START
#define ROOTEXE_START _binary_obj_user_testvm_start
#endif
extern char ROOTEXE_START[];


// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
	
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
		memset(edata, 0, end - edata);
	//cprintf("1\n");

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	//cprintf("1\n");
	cpu_init();
	//cprintf("1\n");
	trap_init();

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
		spinlock_check();

	// Initialize the paged virtual memory system.
	pmap_init();

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
	pic_init();		// setup the legacy PIC (mainly to disable it)
	ioapic_init();		// prepare to handle external device interrupts
	lapic_init();		// setup this CPU's local APIC
		// Initialize the process management code.
	proc_init();
	cpu_bootothers();	// Get other processors started
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
		cpu_onboot() ? "BP" : "AP");


	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.

	//cprintf("before tt\n");

	/*trapframe tt = {
		cs: CPU_GDT_UCODE | 3,
		eip: (uint32_t)(user),
		eflags: FL_IOPL_3,
		gs: CPU_GDT_UDATA | 3,
		fs: CPU_GDT_UDATA | 3,
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
	};
	
	trap_return(&tt);
	*/

	/*
	if(cpu_onboot()){
		proc_root = proc_alloc(&proc_null, 0);
		proc_root->sv.tf.eip = (uint32_t)(user);
		proc_root->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
		//proc_root->sv.tf.eflags = FL_IOPL_3;
		proc_root->sv.tf.eflags = FL_IF;
		proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
		proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;

		proc_ready(proc_root);	
	}
	*/

	
	if(cpu_onboot()){
		proc_root = proc_alloc(&proc_null, 0);
		elf_binary_loader(ROOTEXE_START, proc_root->pdir);
		memset(mem_ptr(VM_USERHI - PAGESIZE), 0, PAGESIZE);
		proc_root->sv.tf.eip = (uint32_t)(0x40000100);
		proc_root->sv.tf.esp = (uint32_t)(VM_USERHI -1);
		proc_root->sv.tf.eflags = FL_IOPL_3;
		proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
		proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;

		pte_t* pte = pmap_walk(proc_root->pdir, 0x40000100, 0);
		cprintf("0x40000100's pte is %x @ %p\n", *pte, pte);

		proc_ready(proc_root);	
	}

	
	proc_sched();

	//user();
}


void
elf_binary_loader(char* elf, pde_t* pdir)
{
	cprintf("======================elf load begin!\n");

	elfhdr* eh = (elfhdr*)elf;
	
	sechdr* sh_start = (sechdr*)(elf + eh->e_shoff);
	uint16_t shnum = eh->e_shnum;
	uint16_t i = 0;
	sechdr* sh = sh_start;

	lcr3(mem_phys(pdir));

	// first, alloc pages for each sections according to the section header
	//cprintf("tag1=======================\n", i);

	for(; i < shnum; i++, sh++){
		//cprintf("i = %d =======================\n", i);
			if ((sh->sh_type != ELF_SHT_PROGBITS) &&
					(sh->sh_type != ELF_SHT_NOBITS)) {
						continue;
			}
			
			if (sh->sh_addr == 0x0) {
				continue;
			}

		uint32_t va_start_page = sh->sh_addr & ~0xfff;
		uint32_t va_end_page = (sh->sh_addr + sh->sh_size) & ~0xfff;
		uint32_t va = va_start_page;

		cprintf("va_start_page = %x, va_end_page = %x\n", va_start_page, va_end_page);

		for(; va <= va_end_page; va += PAGESIZE){
			cprintf("va = %x\n", va);
			if(!pmap_insert(pdir, mem_alloc(), va, PTE_W | PTE_U))
				panic("in elf loader: pmap_insert failed!\n");
		}
	}

	//then, write data into pages according to the context of the sections
	//cprintf("tag2=======================\n", i);

	sh = sh_start;
	i = 0;
	for(; i < shnum; i++, sh++){
		if ((sh->sh_type != ELF_SHT_PROGBITS) &&
				(sh->sh_type != ELF_SHT_NOBITS)) {
					continue;
		}
			
		if (sh->sh_addr == 0x0) {
			continue;
		}
		
		uint32_t sec_start = (uint32_t)elf + sh->sh_offset;
		uint32_t sec_size = sh->sh_size;
		uint32_t va_start = sh->sh_addr;
		
		if(sh->sh_type == ELF_SHT_PROGBITS)
			memcpy((char*)va_start, (char*)sec_start, sec_size);
		else 
			memset((char*)va_start, 0, sec_size);
	}

	//last, set flags correctly to each page
	//cprintf("tag3=======================\n", i);

	sh = sh_start;
	i = 0;
	for(; i < shnum; i++, sh++){
		//cprintf("in tag3 i = %d\n", i);
		if ((sh->sh_type != ELF_SHT_PROGBITS) &&
				(sh->sh_type != ELF_SHT_NOBITS)) {
					continue;
		}
			
		if (sh->sh_addr == 0x0) {
			continue;
		}


		// if this section is Read-Only
		if(!(sh->sh_flags & ELF_SHF_WRITE)){
			uint32_t va_start_page = sh->sh_addr & ~0xfff;
			uint32_t va_end_page = (sh->sh_addr + sh->sh_size) & ~0xfff;
			uint32_t va = va_start_page;
			
			pte_t* pte;

			for(; va <= va_end_page; va += PAGESIZE){
				pte = pmap_walk(pdir, va, 0);

				if(!pte)
					panic("in elf loader: pmap_walk failed!\n");

				*pte &= ~PTE_W;
			}
		}
	}

	//cprintf("tag4=======================\n", i);
	if(!pmap_insert(pdir, mem_alloc(), VM_USERHI - PAGESIZE, PTE_W | PTE_U | PTE_P))
		panic("in elf loader: STACK alloc failed!\n");

	

	cprintf("==================elf load done!\n");

	return;

}

// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
	cprintf("in user()\n");
	assert(read_esp() > (uint32_t) &user_stack[0]);
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);


	done();
}

// This is a function that we call when the kernel is "done" -
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
	while (1)
		;	// just spin
}

