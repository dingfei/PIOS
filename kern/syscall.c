/*
 * System call handling.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the xv6 instructional operating system from MIT.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/x86.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/trap.h>
#include <inc/syscall.h>

#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/proc.h>
#include <kern/syscall.h>





// This bit mask defines the eflags bits user code is allowed to set.
#define FL_USER		(FL_CF|FL_PF|FL_AF|FL_ZF|FL_SF|FL_DF|FL_OF)


// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
	panic("systrap() not implemented.");
}

// Recover from a trap that occurs during a copyin or copyout,
// by aborting the system call and reflecting the trap to the parent process,
// behaving as if the user program's INT instruction had caused the trap.
// This uses the 'recover' pointer in the current cpu struct,
// and invokes systrap() above to blame the trap on the user process.
//
// Notes:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
	panic("sysrecover() not implemented.");
}

// Check a user virtual address block for validity:
// i.e., make sure the complete area specified lies in
// the user address space between VM_USERLO and VM_USERHI.
// If not, abort the syscall by sending a T_GPFLT to the parent,
// again as if the user program's INT instruction was to blame.
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
	panic("checkva() not implemented.");
}

// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
	checkva(utf, uva, size);

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);

	trap_return(tf);	// syscall completed
}


static void
do_put(trapframe *tf, uint32_t cmd)
{	
	cprintf("process %p is in do_put()\n", proc_cur());
	
	procstate* ps = (procstate*)tf->regs.ebx;
	uint16_t child_num = tf->regs.edx;
	proc* proc_parent = proc_cur();
	proc* proc_child = proc_parent->child[child_num];

	if(proc_child == NULL){
		proc_child = proc_alloc(proc_parent, child_num);
		if(proc_child == NULL)
			panic("no child proc!");
	}
	
	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
	if(proc_child->state != PROC_STOP){
		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
		proc_wait(proc_parent, proc_child, tf);
	}

	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);

	if(tf->regs.eax & SYS_REGS){	
		//proc_print(ACQUIRE, proc_child);
		spinlock_acquire(&proc_child->lock);

		/*
		if(((proc_child->sv.tf.eflags ^ ps->tf.eflags) | FL_USER) != FL_USER)
			panic("illegal modification of eflags!");
		*/
		
		proc_child->sv.tf.eip = ps->tf.eip;
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
			panic("wrong segment regs values!");

		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
	}
    if(tf->regs.eax & SYS_START){
		//cprintf("in SYS_START\n");
		proc_ready(proc_child);
	}
	
	trap_return(tf);
}

static void
do_get(trapframe *tf, uint32_t cmd)
{	
	cprintf("process %p is in do_get()\n", proc_cur());
	
	procstate* ps = (procstate*)tf->regs.ebx;
	int child_num = (int)tf->regs.edx;
	proc* proc_parent = proc_cur();
	proc* proc_child = proc_parent->child[child_num];

	assert(proc_child != NULL);

	if(proc_child->state != PROC_STOP){
		cprintf("into proc_wait\n");
		proc_wait(proc_parent, proc_child, tf);}

	if(tf->regs.eax & SYS_REGS){
		memmove(&(ps->tf), &(proc_child->sv.tf), sizeof(trapframe));
	}
	
	trap_return(tf);
}

static void
do_ret(trapframe *tf, uint32_t cmd)
{	
	cprintf("process %p is in do_ret()\n", proc_cur());
	proc_ret(tf, 1);
}



// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:	 do_cputs(tf, cmd); break;
	case SYS_PUT:	 do_put(tf, cmd); break;
	case SYS_GET:	 do_get(tf, cmd); break;
	case SYS_RET:	 do_ret(tf, cmd); break;
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
	}
}

