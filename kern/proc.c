/*
 * PIOS process management.
 *
 * Copyright (C) 2010 Yale University.
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Primary author: Bryan Ford
 */

#include <inc/string.h>
#include <inc/syscall.h>

#include <kern/cpu.h>
#include <kern/mem.h>
#include <kern/trap.h>
#include <kern/proc.h>
#include <kern/init.h>


proc proc_null;		// null process - just leave it initialized to 0

proc *proc_root;	// root process, once it's created in init()

// LAB 2: insert your scheduling data structure declarations here.

ready_queue queue;

static int count;



void
proc_print(TYPE ty, proc* p)
{
	if(ty == ACQUIRE)
		cprintf("acquire lock ");
	else
		cprintf("release lock ");
	if(p != NULL)
		cprintf("on cpu %d, process %d\n", cpu_cur()->id, p->num);
	else
		cprintf("on cpu %d\n", cpu_cur()->id);
}



void
proc_init(void)
{
	
	if (!cpu_onboot())
		return;
	
	//cprintf("in proc_init, current cpu:%d\n", cpu_cur()->id);

	spinlock_init(&queue.lock);

	queue.count= 0;
	queue.head = NULL;
	queue.tail= NULL;
	
	
	// your module initialization code here
}

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{

	//cprintf("in proc_alloc\n");
	
	pageinfo *pi = mem_alloc();
	if (!pi)
		return NULL;
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
	memset(cp, 0, sizeof(proc));

	spinlock_init(&cp->lock);
	cp->parent = p;
	cp->state = PROC_STOP;

	cp->num = count++;

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;

	cp->sv.tf.eflags = FL_IF;

	if (p)
		p->child[cn] = cp;

	cp->pdir = pmap_newpdir();
	cp->rpdir = pmap_newpdir();
	
	return cp;
}

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
	//panic("proc_ready not implemented");

 	//cprintf("in ready, child num:%d\n", queue.count);
	if(p == NULL)
		panic("proc_ready's p is null!");
	
	assert(p->state != PROC_READY);

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
	p->state = PROC_READY;
	spinlock_acquire(&queue.lock);
	// if there is no proc in queue now
	if(queue.count == 0){
		//cprintf("in ready = 0\n");
		queue.count++;
		queue.head = p;
		queue.tail = p;
		//spinlock_release(&queue.lock);
		//proc_print(RELEASE, p);
		//spinlock_release(&p->lock);	
	}

	// insert it to the head of the queue
	else{
		//cprintf("in ready != 0\n");
		p->readynext = queue.head;
		queue.head = p;
		queue.count += 1;

		//spinlock_release(&queue.lock);
		//proc_print(RELEASE, p);
		//spinlock_release(&p->lock);
	}

	spinlock_release(&p->lock);
	spinlock_release(&queue.lock);
	return;
	
}

// Save the current process's state before switching to another process.
// Copies trapframe 'tf' into the proc struct,
// and saves any other relevant state such as FPU state.
// The 'entry' parameter is one of:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);

	switch(entry){
		case -1:		
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
			break;
		case 0:
			tf->eip = (uintptr_t)((char*)tf->eip - 2);
		case 1:
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
			break;
		default:
			panic("wrong entry!\n");
	}

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
}

// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
	//panic("proc_wait not implemented");

	if(p == NULL || p->state != PROC_RUN)
		panic("parent proc is not running!");
	if(cp == NULL)
		panic("no child proc!");

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
	p->state = PROC_WAIT;
	p->waitchild = cp;
	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
	
	proc_save(p, tf, 0);

	assert(cp->state != PROC_STOP);
	
	proc_sched();
	
}

void gcc_noreturn
proc_sched(void)
{
	//panic("proc_sched not implemented");

	//cprintf("cpu: %d, queue has %d elements\n", cpu_cur()->id, queue.count);
	
	for(;;){

		//cprintf("proc_sched on cpu %d\n", cpu_cur()->id);
		
		proc* run;
		//proc* before = cpu_cur()->proc;
			
		// if there is no ready process in queue
		// just wait

		//proc_print(ACQUIRE, NULL);
		spinlock_acquire(&queue.lock);

		if(queue.count != 0){
			// if there is just one ready process
			if(queue.count == 1){
				//cprintf("in sched queue.count == 1\n");
				run = queue.head;
				queue.head = queue.tail = NULL;
				queue.count = 0;	
			}
			
			
			// if there is more than one ready processes
			else{
				//cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
				while(before_tail->readynext != queue.tail){
					before_tail = before_tail->readynext;
				}	
				run = queue.tail;
				queue.tail = before_tail;
				queue.count--;				
			}
			
			/*
			else{
				//cprintf("in sched queue.count > 1\n");
				run = queue.head;
				queue.head = queue.head->readynext;
				queue.count--;
			}
			*/
			
	
			spinlock_release(&queue.lock);
			proc_run(run);
		}
		spinlock_release(&queue.lock);
		pause();
	}
	
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
	//panic("proc_run not implemented");

	//cprintf("proc %x is running on cpu:%d\n", p, cpu_cur()->id);
	
	if(p == NULL)
		panic("proc_run's p is null!");

	assert(p->state == PROC_READY);

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);

	cpu* c = cpu_cur();
	c->proc = p;
	p->state = PROC_RUN;
	p->runcpu = c;

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);

	//cprintf("eip = %d\n", p->sv.tf.eip);
	
	trap_return(&p->sv.tf);
	
}

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
	//panic("proc_yield not implemented");

 	//cprintf("in yield\n");
	proc* cur_proc = cpu_cur()->proc;
	proc_save(cur_proc, tf, 1);
	proc_ready(cur_proc);
	proc_sched();
}

// Put the current process to sleep by "returning" to its parent process.
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
	//panic("proc_ret not implemented");

	proc* proc_child = proc_cur();
	proc* proc_parent = proc_child->parent;

	assert(proc_child->state != PROC_STOP);

	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
	proc_child->state = PROC_STOP;
	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);

	proc_save(proc_child, tf, entry);

	if((proc_parent->state == PROC_WAIT) && (proc_parent->waitchild == proc_child) )
		proc_ready(proc_parent);

	proc_sched();
}

// Helper functions for proc_check()
static void child(int n);
static void grandchild(int n);

static struct procstate child_state;
static char gcc_aligned(16) child_stack[4][PAGESIZE];

static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
		*--esp = i;	// push argument to child() function
		*--esp = 0;	// fake return address
		child_state.tf.eip = (uint32_t) child;
		child_state.tf.esp = (uint32_t) esp;

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);

		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
			NULL, NULL, 0);
		
		cprintf("i == %d complete!\n", i);
		
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
		// get child 0's state
	assert(recovargs == NULL);
	cprintf("============== tag 1 \n");
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
		//cprintf("(1). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
		//cprintf("(2). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		cprintf("recovargs 0x%x\n",recovargs);
		
		if (recovargs) {	// trap recovery needed
			cprintf("i = %d\n", i);
			trap_check_args *argss = recovargs;
			cprintf("recover from trap %d\n",
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) argss->reip;
			argss->trapno = child_state.tf.trapno;
			//cprintf(">>>>>args->trapno = %d, child_state.tf.trapno = %d\n", 
			//	args->trapno, child_state.tf.trapno);
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
		i = (i+1) % 4;	// rotate to next child proc
	} while (child_state.tf.trapno != T_SYSCALL);
	assert(recovargs == NULL);

	cprintf("proc_check() trap reflection test succeeded\n");

	cprintf("proc_check() succeeded!\n");
}

static void child(int n)
{
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n){
				//cprintf("in pingpong = %d\n", pingpong);
				pause();
			}
			xchg(&pingpong, !pingpong);
		}

		//cprintf("before sys_ret!/n");
		//cprintf("in pingpong = %d\n", pingpong);
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		//cprintf("in child %d count %d\n", n, i);
		cprintf("child num:%d\n", queue.count);
		
		while (pingpong != n){
			//cprintf("in pingpong = %d\n", pingpong);
			pause();
		}
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...

	cprintf("child get last test\n");
	if (n == 0) {
		assert(recovargs == NULL);
		trap_check(&recovargs);
		assert(recovargs == NULL);
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
}

static void grandchild(int n)
{
	panic("grandchild(): shouldn't have gotten here");
}

