
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

00100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		start,_start
start: _start:
	movw	$0x1234,0x472			# warm boot BIOS flag
  100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
  100006:	00 00                	add    %al,(%eax)
  100008:	fb                   	sti    
  100009:	4f                   	dec    %edi
  10000a:	52                   	push   %edx
  10000b:	e4 66                	in     $0x66,%al

0010000c <_start>:
  10000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
  100013:	34 12 

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
  100015:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(cpu_boot+4096),%esp
  10001a:	bc 00 90 10 00       	mov    $0x109000,%esp

	# now to C code
	call	init
  10001f:	e8 6d 00 00 00       	call   100091 <init>

00100024 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
  100024:	eb fe                	jmp    100024 <spin>

00100026 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100026:	55                   	push   %ebp
  100027:	89 e5                	mov    %esp,%ebp
  100029:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10002c:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10002f:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100032:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100035:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100038:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10003d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100040:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100043:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100049:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10004e:	74 24                	je     100074 <cpu_cur+0x4e>
  100050:	c7 44 24 0c e0 54 10 	movl   $0x1054e0,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 f6 54 10 	movl   $0x1054f6,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 0b 55 10 00 	movl   $0x10550b,(%esp)
  10006f:	e8 fb 03 00 00       	call   10046f <debug_panic>
	return c;
  100074:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100077:	c9                   	leave  
  100078:	c3                   	ret    

00100079 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100079:	55                   	push   %ebp
  10007a:	89 e5                	mov    %esp,%ebp
  10007c:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10007f:	e8 a2 ff ff ff       	call   100026 <cpu_cur>
  100084:	3d 00 80 10 00       	cmp    $0x108000,%eax
  100089:	0f 94 c0             	sete   %al
  10008c:	0f b6 c0             	movzbl %al,%eax
}
  10008f:	c9                   	leave  
  100090:	c3                   	ret    

00100091 <init>:
// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
  100091:	55                   	push   %ebp
  100092:	89 e5                	mov    %esp,%ebp
  100094:	83 ec 18             	sub    $0x18,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  100097:	e8 dd ff ff ff       	call   100079 <cpu_onboot>
  10009c:	85 c0                	test   %eax,%eax
  10009e:	74 28                	je     1000c8 <init+0x37>
		memset(edata, 0, end - edata);
  1000a0:	ba f0 fa 30 00       	mov    $0x30faf0,%edx
  1000a5:	b8 9c 96 10 00       	mov    $0x10969c,%eax
  1000aa:	89 d1                	mov    %edx,%ecx
  1000ac:	29 c1                	sub    %eax,%ecx
  1000ae:	89 c8                	mov    %ecx,%eax
  1000b0:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bb:	00 
  1000bc:	c7 04 24 9c 96 10 00 	movl   $0x10969c,(%esp)
  1000c3:	e8 93 4f 00 00       	call   10505b <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000c8:	e8 b5 02 00 00       	call   100382 <cons_init>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000cd:	e8 20 10 00 00       	call   1010f2 <cpu_init>
	trap_init();
  1000d2:	e8 e8 14 00 00       	call   1015bf <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000d7:	e8 4d 08 00 00       	call   100929 <mem_init>

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  1000dc:	e8 98 ff ff ff       	call   100079 <cpu_onboot>
  1000e1:	85 c0                	test   %eax,%eax
  1000e3:	74 05                	je     1000ea <init+0x59>
		spinlock_check();
  1000e5:	e8 84 22 00 00       	call   10236e <spinlock_check>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000ea:	e8 10 1f 00 00       	call   101fff <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000ef:	e8 6f 3e 00 00       	call   103f63 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000f4:	e8 9d 44 00 00       	call   104596 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000f9:	e8 48 41 00 00       	call   104246 <lapic_init>
	cpu_bootothers();	// Get other processors started
  1000fe:	e8 be 11 00 00       	call   1012c1 <cpu_bootothers>
//	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
//		cpu_onboot() ? "BP" : "AP");

	// Initialize the process management code.
	proc_init();
  100103:	e8 34 28 00 00       	call   10293c <proc_init>

	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.

	cprintf("before tt\n");
  100108:	c7 04 24 18 55 10 00 	movl   $0x105518,(%esp)
  10010f:	e8 62 4d 00 00       	call   104e76 <cprintf>
	};
	
	trap_return(&tt);
	*/

	cprintf("before alloc proc_root\n");
  100114:	c7 04 24 23 55 10 00 	movl   $0x105523,(%esp)
  10011b:	e8 56 4d 00 00       	call   104e76 <cprintf>
	proc_root = proc_alloc(&proc_null, 1);
  100120:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  100127:	00 
  100128:	c7 04 24 00 f4 30 00 	movl   $0x30f400,(%esp)
  10012f:	e8 56 28 00 00       	call   10298a <proc_alloc>
  100134:	a3 e4 fa 30 00       	mov    %eax,0x30fae4
	proc_root->sv.tf.eip = (uint32_t)(user);
  100139:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  10013e:	ba ae 01 10 00       	mov    $0x1001ae,%edx
  100143:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
	proc_root->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
  100149:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  10014e:	ba a0 a6 10 00       	mov    $0x10a6a0,%edx
  100153:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
	proc_root->sv.tf.eflags = FL_IOPL_3;
  100159:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  10015e:	c7 80 90 04 00 00 00 	movl   $0x3000,0x490(%eax)
  100165:	30 00 00 
	proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
  100168:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  10016d:	66 c7 80 70 04 00 00 	movw   $0x23,0x470(%eax)
  100174:	23 00 
	proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;
  100176:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  10017b:	66 c7 80 74 04 00 00 	movw   $0x23,0x474(%eax)
  100182:	23 00 

	cprintf("before proc_ready\n");
  100184:	c7 04 24 3b 55 10 00 	movl   $0x10553b,(%esp)
  10018b:	e8 e6 4c 00 00       	call   104e76 <cprintf>
	proc_ready(proc_root);
  100190:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  100195:	89 04 24             	mov    %eax,(%esp)
  100198:	e8 6d 29 00 00       	call   102b0a <proc_ready>
	
	cprintf("before proc_sched\n");
  10019d:	c7 04 24 4e 55 10 00 	movl   $0x10554e,(%esp)
  1001a4:	e8 cd 4c 00 00       	call   104e76 <cprintf>
	proc_sched();
  1001a9:	e8 13 2b 00 00       	call   102cc1 <proc_sched>

001001ae <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1001ae:	55                   	push   %ebp
  1001af:	89 e5                	mov    %esp,%ebp
  1001b1:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  1001b4:	c7 04 24 61 55 10 00 	movl   $0x105561,(%esp)
  1001bb:	e8 b6 4c 00 00       	call   104e76 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001c0:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  1001c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  1001c6:	89 c2                	mov    %eax,%edx
  1001c8:	b8 a0 96 10 00       	mov    $0x1096a0,%eax
  1001cd:	39 c2                	cmp    %eax,%edx
  1001cf:	77 24                	ja     1001f5 <user+0x47>
  1001d1:	c7 44 24 0c 6c 55 10 	movl   $0x10556c,0xc(%esp)
  1001d8:	00 
  1001d9:	c7 44 24 08 f6 54 10 	movl   $0x1054f6,0x8(%esp)
  1001e0:	00 
  1001e1:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  1001e8:	00 
  1001e9:	c7 04 24 93 55 10 00 	movl   $0x105593,(%esp)
  1001f0:	e8 7a 02 00 00       	call   10046f <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001f5:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1001f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  1001fb:	89 c2                	mov    %eax,%edx
  1001fd:	b8 a0 a6 10 00       	mov    $0x10a6a0,%eax
  100202:	39 c2                	cmp    %eax,%edx
  100204:	72 24                	jb     10022a <user+0x7c>
  100206:	c7 44 24 0c a0 55 10 	movl   $0x1055a0,0xc(%esp)
  10020d:	00 
  10020e:	c7 44 24 08 f6 54 10 	movl   $0x1054f6,0x8(%esp)
  100215:	00 
  100216:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
  10021d:	00 
  10021e:	c7 04 24 93 55 10 00 	movl   $0x105593,(%esp)
  100225:	e8 45 02 00 00       	call   10046f <debug_panic>

	// Check the system call and process scheduling code.
	proc_check();
  10022a:	e8 80 2c 00 00       	call   102eaf <proc_check>

	done();
  10022f:	e8 00 00 00 00       	call   100234 <done>

00100234 <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  100234:	55                   	push   %ebp
  100235:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  100237:	eb fe                	jmp    100237 <done+0x3>

00100239 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100239:	55                   	push   %ebp
  10023a:	89 e5                	mov    %esp,%ebp
  10023c:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10023f:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100242:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100245:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100248:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10024b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100250:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100253:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100256:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10025c:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100261:	74 24                	je     100287 <cpu_cur+0x4e>
  100263:	c7 44 24 0c d8 55 10 	movl   $0x1055d8,0xc(%esp)
  10026a:	00 
  10026b:	c7 44 24 08 ee 55 10 	movl   $0x1055ee,0x8(%esp)
  100272:	00 
  100273:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10027a:	00 
  10027b:	c7 04 24 03 56 10 00 	movl   $0x105603,(%esp)
  100282:	e8 e8 01 00 00       	call   10046f <debug_panic>
	return c;
  100287:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10028a:	c9                   	leave  
  10028b:	c3                   	ret    

0010028c <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10028c:	55                   	push   %ebp
  10028d:	89 e5                	mov    %esp,%ebp
  10028f:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100292:	e8 a2 ff ff ff       	call   100239 <cpu_cur>
  100297:	3d 00 80 10 00       	cmp    $0x108000,%eax
  10029c:	0f 94 c0             	sete   %al
  10029f:	0f b6 c0             	movzbl %al,%eax
}
  1002a2:	c9                   	leave  
  1002a3:	c3                   	ret    

001002a4 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  1002a4:	55                   	push   %ebp
  1002a5:	89 e5                	mov    %esp,%ebp
  1002a7:	83 ec 28             	sub    $0x28,%esp
	int c;

	spinlock_acquire(&cons_lock);
  1002aa:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  1002b1:	e8 75 1f 00 00       	call   10222b <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  1002b6:	eb 35                	jmp    1002ed <cons_intr+0x49>
		if (c == 0)
  1002b8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1002bc:	74 2e                	je     1002ec <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  1002be:	a1 a4 a8 10 00       	mov    0x10a8a4,%eax
  1002c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1002c6:	88 90 a0 a6 10 00    	mov    %dl,0x10a6a0(%eax)
  1002cc:	83 c0 01             	add    $0x1,%eax
  1002cf:	a3 a4 a8 10 00       	mov    %eax,0x10a8a4
		if (cons.wpos == CONSBUFSIZE)
  1002d4:	a1 a4 a8 10 00       	mov    0x10a8a4,%eax
  1002d9:	3d 00 02 00 00       	cmp    $0x200,%eax
  1002de:	75 0d                	jne    1002ed <cons_intr+0x49>
			cons.wpos = 0;
  1002e0:	c7 05 a4 a8 10 00 00 	movl   $0x0,0x10a8a4
  1002e7:	00 00 00 
  1002ea:	eb 01                	jmp    1002ed <cons_intr+0x49>
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  1002ec:	90                   	nop
cons_intr(int (*proc)(void))
{
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
  1002ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1002f0:	ff d0                	call   *%eax
  1002f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1002f5:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  1002f9:	75 bd                	jne    1002b8 <cons_intr+0x14>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
	spinlock_release(&cons_lock);
  1002fb:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  100302:	e8 a0 1f 00 00       	call   1022a7 <spinlock_release>

}
  100307:	c9                   	leave  
  100308:	c3                   	ret    

00100309 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  100309:	55                   	push   %ebp
  10030a:	89 e5                	mov    %esp,%ebp
  10030c:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  10030f:	e8 ff 3a 00 00       	call   103e13 <serial_intr>
	kbd_intr();
  100314:	e8 55 3a 00 00       	call   103d6e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  100319:	8b 15 a0 a8 10 00    	mov    0x10a8a0,%edx
  10031f:	a1 a4 a8 10 00       	mov    0x10a8a4,%eax
  100324:	39 c2                	cmp    %eax,%edx
  100326:	74 35                	je     10035d <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  100328:	a1 a0 a8 10 00       	mov    0x10a8a0,%eax
  10032d:	0f b6 90 a0 a6 10 00 	movzbl 0x10a6a0(%eax),%edx
  100334:	0f b6 d2             	movzbl %dl,%edx
  100337:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10033a:	83 c0 01             	add    $0x1,%eax
  10033d:	a3 a0 a8 10 00       	mov    %eax,0x10a8a0
		if (cons.rpos == CONSBUFSIZE)
  100342:	a1 a0 a8 10 00       	mov    0x10a8a0,%eax
  100347:	3d 00 02 00 00       	cmp    $0x200,%eax
  10034c:	75 0a                	jne    100358 <cons_getc+0x4f>
			cons.rpos = 0;
  10034e:	c7 05 a0 a8 10 00 00 	movl   $0x0,0x10a8a0
  100355:	00 00 00 
		return c;
  100358:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10035b:	eb 05                	jmp    100362 <cons_getc+0x59>
	}
	return 0;
  10035d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100362:	c9                   	leave  
  100363:	c3                   	ret    

00100364 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  100364:	55                   	push   %ebp
  100365:	89 e5                	mov    %esp,%ebp
  100367:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  10036a:	8b 45 08             	mov    0x8(%ebp),%eax
  10036d:	89 04 24             	mov    %eax,(%esp)
  100370:	e8 bb 3a 00 00       	call   103e30 <serial_putc>
	video_putc(c);
  100375:	8b 45 08             	mov    0x8(%ebp),%eax
  100378:	89 04 24             	mov    %eax,(%esp)
  10037b:	e8 4d 36 00 00       	call   1039cd <video_putc>
}
  100380:	c9                   	leave  
  100381:	c3                   	ret    

00100382 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100382:	55                   	push   %ebp
  100383:	89 e5                	mov    %esp,%ebp
  100385:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100388:	e8 ff fe ff ff       	call   10028c <cpu_onboot>
  10038d:	85 c0                	test   %eax,%eax
  10038f:	74 52                	je     1003e3 <cons_init+0x61>
		return;

	spinlock_init(&cons_lock);
  100391:	c7 44 24 08 6a 00 00 	movl   $0x6a,0x8(%esp)
  100398:	00 
  100399:	c7 44 24 04 10 56 10 	movl   $0x105610,0x4(%esp)
  1003a0:	00 
  1003a1:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  1003a8:	e8 4a 1e 00 00       	call   1021f7 <spinlock_init_>
	video_init();
  1003ad:	e8 4f 35 00 00       	call   103901 <video_init>
	kbd_init();
  1003b2:	e8 cb 39 00 00       	call   103d82 <kbd_init>
	serial_init();
  1003b7:	e8 d9 3a 00 00       	call   103e95 <serial_init>

	if (!serial_exists)
  1003bc:	a1 e8 fa 30 00       	mov    0x30fae8,%eax
  1003c1:	85 c0                	test   %eax,%eax
  1003c3:	75 1f                	jne    1003e4 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  1003c5:	c7 44 24 08 1c 56 10 	movl   $0x10561c,0x8(%esp)
  1003cc:	00 
  1003cd:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  1003d4:	00 
  1003d5:	c7 04 24 10 56 10 00 	movl   $0x105610,(%esp)
  1003dc:	e8 4d 01 00 00       	call   10052e <debug_warn>
  1003e1:	eb 01                	jmp    1003e4 <cons_init+0x62>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  1003e3:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  1003e4:	c9                   	leave  
  1003e5:	c3                   	ret    

001003e6 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  1003e6:	55                   	push   %ebp
  1003e7:	89 e5                	mov    %esp,%ebp
  1003e9:	53                   	push   %ebx
  1003ea:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1003ed:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  1003f0:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	if (read_cs() & 3)
  1003f4:	0f b7 c0             	movzwl %ax,%eax
  1003f7:	83 e0 03             	and    $0x3,%eax
  1003fa:	85 c0                	test   %eax,%eax
  1003fc:	74 14                	je     100412 <cputs+0x2c>
  1003fe:	8b 45 08             	mov    0x8(%ebp),%eax
  100401:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  100404:	b8 00 00 00 00       	mov    $0x0,%eax
  100409:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10040c:	89 d3                	mov    %edx,%ebx
  10040e:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  100410:	eb 57                	jmp    100469 <cputs+0x83>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  100412:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  100419:	e8 e3 1e 00 00       	call   102301 <spinlock_holding>
  10041e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!already)
  100421:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100425:	75 25                	jne    10044c <cputs+0x66>
		spinlock_acquire(&cons_lock);
  100427:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  10042e:	e8 f8 1d 00 00       	call   10222b <spinlock_acquire>

	char ch;
	while (*str)
  100433:	eb 18                	jmp    10044d <cputs+0x67>
		cons_putc(*str++);
  100435:	8b 45 08             	mov    0x8(%ebp),%eax
  100438:	0f b6 00             	movzbl (%eax),%eax
  10043b:	0f be c0             	movsbl %al,%eax
  10043e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100442:	89 04 24             	mov    %eax,(%esp)
  100445:	e8 1a ff ff ff       	call   100364 <cons_putc>
  10044a:	eb 01                	jmp    10044d <cputs+0x67>
	bool already = spinlock_holding(&cons_lock);
	if (!already)
		spinlock_acquire(&cons_lock);

	char ch;
	while (*str)
  10044c:	90                   	nop
  10044d:	8b 45 08             	mov    0x8(%ebp),%eax
  100450:	0f b6 00             	movzbl (%eax),%eax
  100453:	84 c0                	test   %al,%al
  100455:	75 de                	jne    100435 <cputs+0x4f>
		cons_putc(*str++);

	if (!already)
  100457:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10045b:	75 0c                	jne    100469 <cputs+0x83>
		spinlock_release(&cons_lock);
  10045d:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  100464:	e8 3e 1e 00 00       	call   1022a7 <spinlock_release>
}
  100469:	83 c4 24             	add    $0x24,%esp
  10046c:	5b                   	pop    %ebx
  10046d:	5d                   	pop    %ebp
  10046e:	c3                   	ret    

0010046f <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  10046f:	55                   	push   %ebp
  100470:	89 e5                	mov    %esp,%ebp
  100472:	83 ec 58             	sub    $0x58,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  100475:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  100478:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  10047c:	0f b7 c0             	movzwl %ax,%eax
  10047f:	83 e0 03             	and    $0x3,%eax
  100482:	85 c0                	test   %eax,%eax
  100484:	75 15                	jne    10049b <debug_panic+0x2c>
		if (panicstr)
  100486:	a1 a8 a8 10 00       	mov    0x10a8a8,%eax
  10048b:	85 c0                	test   %eax,%eax
  10048d:	0f 85 95 00 00 00    	jne    100528 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  100493:	8b 45 10             	mov    0x10(%ebp),%eax
  100496:	a3 a8 a8 10 00       	mov    %eax,0x10a8a8
	}

	// First print the requested message
	va_start(ap, fmt);
  10049b:	8d 45 10             	lea    0x10(%ebp),%eax
  10049e:	83 c0 04             	add    $0x4,%eax
  1004a1:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  1004a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004a7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1004ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1004ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004b2:	c7 04 24 39 56 10 00 	movl   $0x105639,(%esp)
  1004b9:	e8 b8 49 00 00       	call   104e76 <cprintf>
	vcprintf(fmt, ap);
  1004be:	8b 45 10             	mov    0x10(%ebp),%eax
  1004c1:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1004c4:	89 54 24 04          	mov    %edx,0x4(%esp)
  1004c8:	89 04 24             	mov    %eax,(%esp)
  1004cb:	e8 3d 49 00 00       	call   104e0d <vcprintf>
	cprintf("\n");
  1004d0:	c7 04 24 51 56 10 00 	movl   $0x105651,(%esp)
  1004d7:	e8 9a 49 00 00       	call   104e76 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1004dc:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  1004df:	8b 45 f4             	mov    -0xc(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1004e2:	8d 55 c0             	lea    -0x40(%ebp),%edx
  1004e5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1004e9:	89 04 24             	mov    %eax,(%esp)
  1004ec:	e8 86 00 00 00       	call   100577 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1004f1:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1004f8:	eb 1b                	jmp    100515 <debug_panic+0xa6>
		cprintf("  from %08x\n", eips[i]);
  1004fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1004fd:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  100501:	89 44 24 04          	mov    %eax,0x4(%esp)
  100505:	c7 04 24 53 56 10 00 	movl   $0x105653,(%esp)
  10050c:	e8 65 49 00 00       	call   104e76 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  100511:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100515:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  100519:	7f 0e                	jg     100529 <debug_panic+0xba>
  10051b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10051e:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  100522:	85 c0                	test   %eax,%eax
  100524:	75 d4                	jne    1004fa <debug_panic+0x8b>
  100526:	eb 01                	jmp    100529 <debug_panic+0xba>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  100528:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  100529:	e8 06 fd ff ff       	call   100234 <done>

0010052e <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  10052e:	55                   	push   %ebp
  10052f:	89 e5                	mov    %esp,%ebp
  100531:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  100534:	8d 45 10             	lea    0x10(%ebp),%eax
  100537:	83 c0 04             	add    $0x4,%eax
  10053a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  10053d:	8b 45 0c             	mov    0xc(%ebp),%eax
  100540:	89 44 24 08          	mov    %eax,0x8(%esp)
  100544:	8b 45 08             	mov    0x8(%ebp),%eax
  100547:	89 44 24 04          	mov    %eax,0x4(%esp)
  10054b:	c7 04 24 60 56 10 00 	movl   $0x105660,(%esp)
  100552:	e8 1f 49 00 00       	call   104e76 <cprintf>
	vcprintf(fmt, ap);
  100557:	8b 45 10             	mov    0x10(%ebp),%eax
  10055a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10055d:	89 54 24 04          	mov    %edx,0x4(%esp)
  100561:	89 04 24             	mov    %eax,(%esp)
  100564:	e8 a4 48 00 00       	call   104e0d <vcprintf>
	cprintf("\n");
  100569:	c7 04 24 51 56 10 00 	movl   $0x105651,(%esp)
  100570:	e8 01 49 00 00       	call   104e76 <cprintf>
	va_end(ap);
}
  100575:	c9                   	leave  
  100576:	c3                   	ret    

00100577 <debug_trace>:

// Riecord the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100577:	55                   	push   %ebp
  100578:	89 e5                	mov    %esp,%ebp
  10057a:	83 ec 10             	sub    $0x10,%esp

	return;*/
	//panic("debug_trace not implemented");

	int i ,j;
	uint32_t *cur_epb = (uint32_t *)ebp;
  10057d:	8b 45 08             	mov    0x8(%ebp),%eax
  100580:	89 45 fc             	mov    %eax,-0x4(%ebp)
	//cprintf("Stack backtrace:\n");
	for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  100583:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10058a:	eb 32                	jmp    1005be <debug_trace+0x47>
		//cprintf("  ebp %08x eip %08x args",cur_epb[0],cur_epb[1]);
		eips[i] = cur_epb[1];
  10058c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10058f:	c1 e0 02             	shl    $0x2,%eax
  100592:	03 45 0c             	add    0xc(%ebp),%eax
  100595:	8b 55 fc             	mov    -0x4(%ebp),%edx
  100598:	83 c2 04             	add    $0x4,%edx
  10059b:	8b 12                	mov    (%edx),%edx
  10059d:	89 10                	mov    %edx,(%eax)
		for(j = 0; j < 5; j++) {
  10059f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1005a6:	eb 04                	jmp    1005ac <debug_trace+0x35>
  1005a8:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1005ac:	83 7d f8 04          	cmpl   $0x4,-0x8(%ebp)
  1005b0:	7e f6                	jle    1005a8 <debug_trace+0x31>
			//makecprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");make
		cur_epb = (uint32_t *)(*cur_epb);
  1005b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1005b5:	8b 00                	mov    (%eax),%eax
  1005b7:	89 45 fc             	mov    %eax,-0x4(%ebp)
	//panic("debug_trace not implemented");

	int i ,j;
	uint32_t *cur_epb = (uint32_t *)ebp;
	//cprintf("Stack backtrace:\n");
	for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  1005ba:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1005be:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1005c2:	7f 1b                	jg     1005df <debug_trace+0x68>
  1005c4:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  1005c8:	75 c2                	jne    10058c <debug_trace+0x15>
			//makecprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");make
		cur_epb = (uint32_t *)(*cur_epb);
	}
	for(; i < DEBUG_TRACEFRAMES ; i++) {
  1005ca:	eb 13                	jmp    1005df <debug_trace+0x68>
		eips[i] = 0;
  1005cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1005cf:	c1 e0 02             	shl    $0x2,%eax
  1005d2:	03 45 0c             	add    0xc(%ebp),%eax
  1005d5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			//makecprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");make
		cur_epb = (uint32_t *)(*cur_epb);
	}
	for(; i < DEBUG_TRACEFRAMES ; i++) {
  1005db:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1005df:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1005e3:	7e e7                	jle    1005cc <debug_trace+0x55>
		eips[i] = 0;
	}
	/*
	for(i = 0; i < DEBUG_TRACEFRAMES ; i++) {
		cprintf("eip %x\n",eips[i]);			}*/
}
  1005e5:	c9                   	leave  
  1005e6:	c3                   	ret    

001005e7 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  1005e7:	55                   	push   %ebp
  1005e8:	89 e5                	mov    %esp,%ebp
  1005ea:	83 ec 18             	sub    $0x18,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1005ed:	89 6d fc             	mov    %ebp,-0x4(%ebp)
        return ebp;
  1005f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1005f3:	8b 55 0c             	mov    0xc(%ebp),%edx
  1005f6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1005fa:	89 04 24             	mov    %eax,(%esp)
  1005fd:	e8 75 ff ff ff       	call   100577 <debug_trace>
  100602:	c9                   	leave  
  100603:	c3                   	ret    

00100604 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100604:	55                   	push   %ebp
  100605:	89 e5                	mov    %esp,%ebp
  100607:	83 ec 08             	sub    $0x8,%esp
  10060a:	8b 45 08             	mov    0x8(%ebp),%eax
  10060d:	83 e0 02             	and    $0x2,%eax
  100610:	85 c0                	test   %eax,%eax
  100612:	74 14                	je     100628 <f2+0x24>
  100614:	8b 45 0c             	mov    0xc(%ebp),%eax
  100617:	89 44 24 04          	mov    %eax,0x4(%esp)
  10061b:	8b 45 08             	mov    0x8(%ebp),%eax
  10061e:	89 04 24             	mov    %eax,(%esp)
  100621:	e8 c1 ff ff ff       	call   1005e7 <f3>
  100626:	eb 12                	jmp    10063a <f2+0x36>
  100628:	8b 45 0c             	mov    0xc(%ebp),%eax
  10062b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10062f:	8b 45 08             	mov    0x8(%ebp),%eax
  100632:	89 04 24             	mov    %eax,(%esp)
  100635:	e8 ad ff ff ff       	call   1005e7 <f3>
  10063a:	c9                   	leave  
  10063b:	c3                   	ret    

0010063c <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  10063c:	55                   	push   %ebp
  10063d:	89 e5                	mov    %esp,%ebp
  10063f:	83 ec 08             	sub    $0x8,%esp
  100642:	8b 45 08             	mov    0x8(%ebp),%eax
  100645:	83 e0 01             	and    $0x1,%eax
  100648:	84 c0                	test   %al,%al
  10064a:	74 14                	je     100660 <f1+0x24>
  10064c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10064f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100653:	8b 45 08             	mov    0x8(%ebp),%eax
  100656:	89 04 24             	mov    %eax,(%esp)
  100659:	e8 a6 ff ff ff       	call   100604 <f2>
  10065e:	eb 12                	jmp    100672 <f1+0x36>
  100660:	8b 45 0c             	mov    0xc(%ebp),%eax
  100663:	89 44 24 04          	mov    %eax,0x4(%esp)
  100667:	8b 45 08             	mov    0x8(%ebp),%eax
  10066a:	89 04 24             	mov    %eax,(%esp)
  10066d:	e8 92 ff ff ff       	call   100604 <f2>
  100672:	c9                   	leave  
  100673:	c3                   	ret    

00100674 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100674:	55                   	push   %ebp
  100675:	89 e5                	mov    %esp,%ebp
  100677:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  10067d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100684:	eb 29                	jmp    1006af <debug_check+0x3b>
		f1(i, eips[i]);
  100686:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  10068c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10068f:	89 d0                	mov    %edx,%eax
  100691:	c1 e0 02             	shl    $0x2,%eax
  100694:	01 d0                	add    %edx,%eax
  100696:	c1 e0 03             	shl    $0x3,%eax
  100699:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  10069c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1006a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006a3:	89 04 24             	mov    %eax,(%esp)
  1006a6:	e8 91 ff ff ff       	call   10063c <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1006ab:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1006af:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  1006b3:	7e d1                	jle    100686 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1006b5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1006bc:	e9 bc 00 00 00       	jmp    10077d <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1006c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1006c8:	e9 a2 00 00 00       	jmp    10076f <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  1006cd:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1006d0:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  1006d3:	89 d0                	mov    %edx,%eax
  1006d5:	c1 e0 02             	shl    $0x2,%eax
  1006d8:	01 d0                	add    %edx,%eax
  1006da:	01 c0                	add    %eax,%eax
  1006dc:	01 c8                	add    %ecx,%eax
  1006de:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  1006e5:	85 c0                	test   %eax,%eax
  1006e7:	0f 95 c2             	setne  %dl
  1006ea:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  1006ee:	0f 9e c0             	setle  %al
  1006f1:	31 d0                	xor    %edx,%eax
  1006f3:	84 c0                	test   %al,%al
  1006f5:	74 24                	je     10071b <debug_check+0xa7>
  1006f7:	c7 44 24 0c 7a 56 10 	movl   $0x10567a,0xc(%esp)
  1006fe:	00 
  1006ff:	c7 44 24 08 97 56 10 	movl   $0x105697,0x8(%esp)
  100706:	00 
  100707:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  10070e:	00 
  10070f:	c7 04 24 ac 56 10 00 	movl   $0x1056ac,(%esp)
  100716:	e8 54 fd ff ff       	call   10046f <debug_panic>
			if (i >= 2)
  10071b:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  10071f:	7e 4a                	jle    10076b <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  100721:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100724:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100727:	89 d0                	mov    %edx,%eax
  100729:	c1 e0 02             	shl    $0x2,%eax
  10072c:	01 d0                	add    %edx,%eax
  10072e:	01 c0                	add    %eax,%eax
  100730:	01 c8                	add    %ecx,%eax
  100732:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  100739:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10073c:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100743:	39 c2                	cmp    %eax,%edx
  100745:	74 24                	je     10076b <debug_check+0xf7>
  100747:	c7 44 24 0c b9 56 10 	movl   $0x1056b9,0xc(%esp)
  10074e:	00 
  10074f:	c7 44 24 08 97 56 10 	movl   $0x105697,0x8(%esp)
  100756:	00 
  100757:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  10075e:	00 
  10075f:	c7 04 24 ac 56 10 00 	movl   $0x1056ac,(%esp)
  100766:	e8 04 fd ff ff       	call   10046f <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  10076b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10076f:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100773:	0f 8e 54 ff ff ff    	jle    1006cd <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100779:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10077d:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  100781:	0f 8e 3a ff ff ff    	jle    1006c1 <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  100787:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  10078d:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  100793:	39 c2                	cmp    %eax,%edx
  100795:	74 24                	je     1007bb <debug_check+0x147>
  100797:	c7 44 24 0c d2 56 10 	movl   $0x1056d2,0xc(%esp)
  10079e:	00 
  10079f:	c7 44 24 08 97 56 10 	movl   $0x105697,0x8(%esp)
  1007a6:	00 
  1007a7:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  1007ae:	00 
  1007af:	c7 04 24 ac 56 10 00 	movl   $0x1056ac,(%esp)
  1007b6:	e8 b4 fc ff ff       	call   10046f <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1007bb:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1007be:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1007c1:	39 c2                	cmp    %eax,%edx
  1007c3:	74 24                	je     1007e9 <debug_check+0x175>
  1007c5:	c7 44 24 0c eb 56 10 	movl   $0x1056eb,0xc(%esp)
  1007cc:	00 
  1007cd:	c7 44 24 08 97 56 10 	movl   $0x105697,0x8(%esp)
  1007d4:	00 
  1007d5:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  1007dc:	00 
  1007dd:	c7 04 24 ac 56 10 00 	movl   $0x1056ac,(%esp)
  1007e4:	e8 86 fc ff ff       	call   10046f <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  1007e9:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  1007ef:	8b 45 a0             	mov    -0x60(%ebp),%eax
  1007f2:	39 c2                	cmp    %eax,%edx
  1007f4:	75 24                	jne    10081a <debug_check+0x1a6>
  1007f6:	c7 44 24 0c 04 57 10 	movl   $0x105704,0xc(%esp)
  1007fd:	00 
  1007fe:	c7 44 24 08 97 56 10 	movl   $0x105697,0x8(%esp)
  100805:	00 
  100806:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  10080d:	00 
  10080e:	c7 04 24 ac 56 10 00 	movl   $0x1056ac,(%esp)
  100815:	e8 55 fc ff ff       	call   10046f <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10081a:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100820:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100823:	39 c2                	cmp    %eax,%edx
  100825:	74 24                	je     10084b <debug_check+0x1d7>
  100827:	c7 44 24 0c 1d 57 10 	movl   $0x10571d,0xc(%esp)
  10082e:	00 
  10082f:	c7 44 24 08 97 56 10 	movl   $0x105697,0x8(%esp)
  100836:	00 
  100837:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  10083e:	00 
  10083f:	c7 04 24 ac 56 10 00 	movl   $0x1056ac,(%esp)
  100846:	e8 24 fc ff ff       	call   10046f <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10084b:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100851:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100854:	39 c2                	cmp    %eax,%edx
  100856:	74 24                	je     10087c <debug_check+0x208>
  100858:	c7 44 24 0c 36 57 10 	movl   $0x105736,0xc(%esp)
  10085f:	00 
  100860:	c7 44 24 08 97 56 10 	movl   $0x105697,0x8(%esp)
  100867:	00 
  100868:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  10086f:	00 
  100870:	c7 04 24 ac 56 10 00 	movl   $0x1056ac,(%esp)
  100877:	e8 f3 fb ff ff       	call   10046f <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10087c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100882:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  100888:	39 c2                	cmp    %eax,%edx
  10088a:	75 24                	jne    1008b0 <debug_check+0x23c>
  10088c:	c7 44 24 0c 4f 57 10 	movl   $0x10574f,0xc(%esp)
  100893:	00 
  100894:	c7 44 24 08 97 56 10 	movl   $0x105697,0x8(%esp)
  10089b:	00 
  10089c:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  1008a3:	00 
  1008a4:	c7 04 24 ac 56 10 00 	movl   $0x1056ac,(%esp)
  1008ab:	e8 bf fb ff ff       	call   10046f <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1008b0:	c7 04 24 68 57 10 00 	movl   $0x105768,(%esp)
  1008b7:	e8 ba 45 00 00       	call   104e76 <cprintf>
}
  1008bc:	c9                   	leave  
  1008bd:	c3                   	ret    

001008be <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1008be:	55                   	push   %ebp
  1008bf:	89 e5                	mov    %esp,%ebp
  1008c1:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1008c4:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1008c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1008ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1008cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1008d0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1008d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1008db:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1008e1:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1008e6:	74 24                	je     10090c <cpu_cur+0x4e>
  1008e8:	c7 44 24 0c 84 57 10 	movl   $0x105784,0xc(%esp)
  1008ef:	00 
  1008f0:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  1008f7:	00 
  1008f8:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1008ff:	00 
  100900:	c7 04 24 af 57 10 00 	movl   $0x1057af,(%esp)
  100907:	e8 63 fb ff ff       	call   10046f <debug_panic>
	return c;
  10090c:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10090f:	c9                   	leave  
  100910:	c3                   	ret    

00100911 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100911:	55                   	push   %ebp
  100912:	89 e5                	mov    %esp,%ebp
  100914:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100917:	e8 a2 ff ff ff       	call   1008be <cpu_cur>
  10091c:	3d 00 80 10 00       	cmp    $0x108000,%eax
  100921:	0f 94 c0             	sete   %al
  100924:	0f b6 c0             	movzbl %al,%eax
}
  100927:	c9                   	leave  
  100928:	c3                   	ret    

00100929 <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  100929:	55                   	push   %ebp
  10092a:	89 e5                	mov    %esp,%ebp
  10092c:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10092f:	e8 dd ff ff ff       	call   100911 <cpu_onboot>
  100934:	85 c0                	test   %eax,%eax
  100936:	0f 84 bc 01 00 00    	je     100af8 <mem_init+0x1cf>
		return;

	
	spinlock_init(&mem_spinlock);
  10093c:	c7 44 24 08 2d 00 00 	movl   $0x2d,0x8(%esp)
  100943:	00 
  100944:	c7 44 24 04 bc 57 10 	movl   $0x1057bc,0x4(%esp)
  10094b:	00 
  10094c:	c7 04 24 a0 f3 30 00 	movl   $0x30f3a0,(%esp)
  100953:	e8 9f 18 00 00       	call   1021f7 <spinlock_init_>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100958:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  10095f:	e8 08 38 00 00       	call   10416c <nvram_read16>
  100964:	c1 e0 0a             	shl    $0xa,%eax
  100967:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10096a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10096d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100972:	89 45 dc             	mov    %eax,-0x24(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100975:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  10097c:	e8 eb 37 00 00       	call   10416c <nvram_read16>
  100981:	c1 e0 0a             	shl    $0xa,%eax
  100984:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100987:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10098a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10098f:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  100992:	c7 44 24 08 c8 57 10 	movl   $0x1057c8,0x8(%esp)
  100999:	00 
  10099a:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
  1009a1:	00 
  1009a2:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  1009a9:	e8 80 fb ff ff       	call   10052e <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1009ae:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1009b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009b8:	05 00 00 10 00       	add    $0x100000,%eax
  1009bd:	a3 88 f3 10 00       	mov    %eax,0x10f388

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1009c2:	a1 88 f3 10 00       	mov    0x10f388,%eax
  1009c7:	c1 e8 0c             	shr    $0xc,%eax
  1009ca:	a3 84 f3 10 00       	mov    %eax,0x10f384

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  1009cf:	a1 88 f3 10 00       	mov    0x10f388,%eax
  1009d4:	c1 e8 0a             	shr    $0xa,%eax
  1009d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009db:	c7 04 24 e8 57 10 00 	movl   $0x1057e8,(%esp)
  1009e2:	e8 8f 44 00 00       	call   104e76 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  1009e7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009ea:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  1009ed:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  1009ef:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1009f2:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  1009f5:	89 54 24 08          	mov    %edx,0x8(%esp)
  1009f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009fd:	c7 04 24 09 58 10 00 	movl   $0x105809,(%esp)
  100a04:	e8 6d 44 00 00       	call   104e76 <cprintf>


	extern char start[], end[];
	uint32_t page_start;
	
	pageinfo **freetail = &mem_freelist;
  100a09:	c7 45 e8 80 f3 10 00 	movl   $0x10f380,-0x18(%ebp)
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100a10:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100a17:	00 
  100a18:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100a1f:	00 
  100a20:	c7 04 24 a0 f3 10 00 	movl   $0x10f3a0,(%esp)
  100a27:	e8 2f 46 00 00       	call   10505b <memset>
	mem_pageinfo = spc_for_pi;
  100a2c:	c7 05 d8 f3 30 00 a0 	movl   $0x10f3a0,0x30f3d8
  100a33:	f3 10 00 
	int i;
	for (i = 0; i < mem_npage; i++) {
  100a36:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100a3d:	e9 96 00 00 00       	jmp    100ad8 <mem_init+0x1af>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100a42:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  100a47:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a4a:	c1 e2 03             	shl    $0x3,%edx
  100a4d:	01 d0                	add    %edx,%eax
  100a4f:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		if(i == 0 || i == 1)
  100a56:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100a5a:	74 6e                	je     100aca <mem_init+0x1a1>
  100a5c:	83 7d ec 01          	cmpl   $0x1,-0x14(%ebp)
  100a60:	74 6b                	je     100acd <mem_init+0x1a4>
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);
  100a62:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100a65:	c1 e0 03             	shl    $0x3,%eax
  100a68:	c1 f8 03             	sar    $0x3,%eax
  100a6b:	c1 e0 0c             	shl    $0xc,%eax
  100a6e:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100a71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100a74:	05 00 10 00 00       	add    $0x1000,%eax
  100a79:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  100a7e:	76 09                	jbe    100a89 <mem_init+0x160>
  100a80:	81 7d e4 ff ff 0f 00 	cmpl   $0xfffff,-0x1c(%ebp)
  100a87:	76 47                	jbe    100ad0 <mem_init+0x1a7>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  100a89:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100a8c:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
  100a92:	b8 0c 00 10 00       	mov    $0x10000c,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100a97:	39 c2                	cmp    %eax,%edx
  100a99:	72 0a                	jb     100aa5 <mem_init+0x17c>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  100a9b:	b8 f0 fa 30 00       	mov    $0x30faf0,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100aa0:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  100aa3:	72 2e                	jb     100ad3 <mem_init+0x1aa>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;


		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100aa5:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  100aaa:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100aad:	c1 e2 03             	shl    $0x3,%edx
  100ab0:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100ab3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ab6:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100ab8:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  100abd:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100ac0:	c1 e2 03             	shl    $0x3,%edx
  100ac3:	01 d0                	add    %edx,%eax
  100ac5:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100ac8:	eb 0a                	jmp    100ad4 <mem_init+0x1ab>
	for (i = 0; i < mem_npage; i++) {
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;

		if(i == 0 || i == 1)
			continue;
  100aca:	90                   	nop
  100acb:	eb 07                	jmp    100ad4 <mem_init+0x1ab>
  100acd:	90                   	nop
  100ace:	eb 04                	jmp    100ad4 <mem_init+0x1ab>

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;
  100ad0:	90                   	nop
  100ad1:	eb 01                	jmp    100ad4 <mem_init+0x1ab>
  100ad3:	90                   	nop
	
	pageinfo **freetail = &mem_freelist;
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
	mem_pageinfo = spc_for_pi;
	int i;
	for (i = 0; i < mem_npage; i++) {
  100ad4:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100ad8:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100adb:	a1 84 f3 10 00       	mov    0x10f384,%eax
  100ae0:	39 c2                	cmp    %eax,%edx
  100ae2:	0f 82 5a ff ff ff    	jb     100a42 <mem_init+0x119>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100ae8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100aeb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100af1:	e8 a1 00 00 00       	call   100b97 <mem_check>
  100af6:	eb 01                	jmp    100af9 <mem_init+0x1d0>

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100af8:	90                   	nop
	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100af9:	c9                   	leave  
  100afa:	c3                   	ret    

00100afb <mem_alloc>:



pageinfo *
mem_alloc(void)
{
  100afb:	55                   	push   %ebp
  100afc:	89 e5                	mov    %esp,%ebp
  100afe:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	// Fill this function in.
	//panic("mem_alloc not implemented.");

	if(mem_freelist == NULL)
  100b01:	a1 80 f3 10 00       	mov    0x10f380,%eax
  100b06:	85 c0                	test   %eax,%eax
  100b08:	75 07                	jne    100b11 <mem_alloc+0x16>
		return NULL;
  100b0a:	b8 00 00 00 00       	mov    $0x0,%eax
  100b0f:	eb 2f                	jmp    100b40 <mem_alloc+0x45>

	spinlock_acquire(&mem_spinlock);
  100b11:	c7 04 24 a0 f3 30 00 	movl   $0x30f3a0,(%esp)
  100b18:	e8 0e 17 00 00       	call   10222b <spinlock_acquire>
	pageinfo* r = mem_freelist;
  100b1d:	a1 80 f3 10 00       	mov    0x10f380,%eax
  100b22:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = mem_freelist->free_next;
  100b25:	a1 80 f3 10 00       	mov    0x10f380,%eax
  100b2a:	8b 00                	mov    (%eax),%eax
  100b2c:	a3 80 f3 10 00       	mov    %eax,0x10f380
	spinlock_release(&mem_spinlock);
  100b31:	c7 04 24 a0 f3 30 00 	movl   $0x30f3a0,(%esp)
  100b38:	e8 6a 17 00 00       	call   1022a7 <spinlock_release>
	return r;
  100b3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100b40:	c9                   	leave  
  100b41:	c3                   	ret    

00100b42 <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100b42:	55                   	push   %ebp
  100b43:	89 e5                	mov    %esp,%ebp
  100b45:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");

	if(pi == NULL)
  100b48:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100b4c:	75 1c                	jne    100b6a <mem_free+0x28>
		panic("null for page which to be freed!"); 
  100b4e:	c7 44 24 08 28 58 10 	movl   $0x105828,0x8(%esp)
  100b55:	00 
  100b56:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  100b5d:	00 
  100b5e:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100b65:	e8 05 f9 ff ff       	call   10046f <debug_panic>

	spinlock_acquire(&mem_spinlock);
  100b6a:	c7 04 24 a0 f3 30 00 	movl   $0x30f3a0,(%esp)
  100b71:	e8 b5 16 00 00       	call   10222b <spinlock_acquire>
	pi->free_next = mem_freelist;
  100b76:	8b 15 80 f3 10 00    	mov    0x10f380,%edx
  100b7c:	8b 45 08             	mov    0x8(%ebp),%eax
  100b7f:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100b81:	8b 45 08             	mov    0x8(%ebp),%eax
  100b84:	a3 80 f3 10 00       	mov    %eax,0x10f380
	spinlock_release(&mem_spinlock);
  100b89:	c7 04 24 a0 f3 30 00 	movl   $0x30f3a0,(%esp)
  100b90:	e8 12 17 00 00       	call   1022a7 <spinlock_release>
	
}
  100b95:	c9                   	leave  
  100b96:	c3                   	ret    

00100b97 <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100b97:	55                   	push   %ebp
  100b98:	89 e5                	mov    %esp,%ebp
  100b9a:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100b9d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100ba4:	a1 80 f3 10 00       	mov    0x10f380,%eax
  100ba9:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100bac:	eb 38                	jmp    100be6 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100bae:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100bb1:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  100bb6:	89 d1                	mov    %edx,%ecx
  100bb8:	29 c1                	sub    %eax,%ecx
  100bba:	89 c8                	mov    %ecx,%eax
  100bbc:	c1 f8 03             	sar    $0x3,%eax
  100bbf:	c1 e0 0c             	shl    $0xc,%eax
  100bc2:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100bc9:	00 
  100bca:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100bd1:	00 
  100bd2:	89 04 24             	mov    %eax,(%esp)
  100bd5:	e8 81 44 00 00       	call   10505b <memset>
		freepages++;
  100bda:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100bde:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100be1:	8b 00                	mov    (%eax),%eax
  100be3:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100be6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  100bea:	75 c2                	jne    100bae <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100bec:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100bef:	89 44 24 04          	mov    %eax,0x4(%esp)
  100bf3:	c7 04 24 49 58 10 00 	movl   $0x105849,(%esp)
  100bfa:	e8 77 42 00 00       	call   104e76 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100bff:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c02:	a1 84 f3 10 00       	mov    0x10f384,%eax
  100c07:	39 c2                	cmp    %eax,%edx
  100c09:	72 24                	jb     100c2f <mem_check+0x98>
  100c0b:	c7 44 24 0c 63 58 10 	movl   $0x105863,0xc(%esp)
  100c12:	00 
  100c13:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100c1a:	00 
  100c1b:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  100c22:	00 
  100c23:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100c2a:	e8 40 f8 ff ff       	call   10046f <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100c2f:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100c36:	7f 24                	jg     100c5c <mem_check+0xc5>
  100c38:	c7 44 24 0c 79 58 10 	movl   $0x105879,0xc(%esp)
  100c3f:	00 
  100c40:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100c47:	00 
  100c48:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100c4f:	00 
  100c50:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100c57:	e8 13 f8 ff ff       	call   10046f <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100c5c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100c63:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100c66:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100c69:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100c6c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100c6f:	e8 87 fe ff ff       	call   100afb <mem_alloc>
  100c74:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100c77:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100c7b:	75 24                	jne    100ca1 <mem_check+0x10a>
  100c7d:	c7 44 24 0c 8b 58 10 	movl   $0x10588b,0xc(%esp)
  100c84:	00 
  100c85:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100c8c:	00 
  100c8d:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  100c94:	00 
  100c95:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100c9c:	e8 ce f7 ff ff       	call   10046f <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100ca1:	e8 55 fe ff ff       	call   100afb <mem_alloc>
  100ca6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100ca9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100cad:	75 24                	jne    100cd3 <mem_check+0x13c>
  100caf:	c7 44 24 0c 94 58 10 	movl   $0x105894,0xc(%esp)
  100cb6:	00 
  100cb7:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100cbe:	00 
  100cbf:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100cc6:	00 
  100cc7:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100cce:	e8 9c f7 ff ff       	call   10046f <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100cd3:	e8 23 fe ff ff       	call   100afb <mem_alloc>
  100cd8:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100cdb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100cdf:	75 24                	jne    100d05 <mem_check+0x16e>
  100ce1:	c7 44 24 0c 9d 58 10 	movl   $0x10589d,0xc(%esp)
  100ce8:	00 
  100ce9:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100cf0:	00 
  100cf1:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100cf8:	00 
  100cf9:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100d00:	e8 6a f7 ff ff       	call   10046f <debug_panic>

	assert(pp0);
  100d05:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100d09:	75 24                	jne    100d2f <mem_check+0x198>
  100d0b:	c7 44 24 0c a6 58 10 	movl   $0x1058a6,0xc(%esp)
  100d12:	00 
  100d13:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100d1a:	00 
  100d1b:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  100d22:	00 
  100d23:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100d2a:	e8 40 f7 ff ff       	call   10046f <debug_panic>
	assert(pp1 && pp1 != pp0);
  100d2f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d33:	74 08                	je     100d3d <mem_check+0x1a6>
  100d35:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d38:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d3b:	75 24                	jne    100d61 <mem_check+0x1ca>
  100d3d:	c7 44 24 0c aa 58 10 	movl   $0x1058aa,0xc(%esp)
  100d44:	00 
  100d45:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100d4c:	00 
  100d4d:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100d54:	00 
  100d55:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100d5c:	e8 0e f7 ff ff       	call   10046f <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100d61:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d65:	74 10                	je     100d77 <mem_check+0x1e0>
  100d67:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d6a:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100d6d:	74 08                	je     100d77 <mem_check+0x1e0>
  100d6f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d72:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d75:	75 24                	jne    100d9b <mem_check+0x204>
  100d77:	c7 44 24 0c bc 58 10 	movl   $0x1058bc,0xc(%esp)
  100d7e:	00 
  100d7f:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100d86:	00 
  100d87:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100d8e:	00 
  100d8f:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100d96:	e8 d4 f6 ff ff       	call   10046f <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100d9b:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100d9e:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  100da3:	89 d1                	mov    %edx,%ecx
  100da5:	29 c1                	sub    %eax,%ecx
  100da7:	89 c8                	mov    %ecx,%eax
  100da9:	c1 f8 03             	sar    $0x3,%eax
  100dac:	c1 e0 0c             	shl    $0xc,%eax
  100daf:	8b 15 84 f3 10 00    	mov    0x10f384,%edx
  100db5:	c1 e2 0c             	shl    $0xc,%edx
  100db8:	39 d0                	cmp    %edx,%eax
  100dba:	72 24                	jb     100de0 <mem_check+0x249>
  100dbc:	c7 44 24 0c dc 58 10 	movl   $0x1058dc,0xc(%esp)
  100dc3:	00 
  100dc4:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100dcb:	00 
  100dcc:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  100dd3:	00 
  100dd4:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100ddb:	e8 8f f6 ff ff       	call   10046f <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100de0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100de3:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  100de8:	89 d1                	mov    %edx,%ecx
  100dea:	29 c1                	sub    %eax,%ecx
  100dec:	89 c8                	mov    %ecx,%eax
  100dee:	c1 f8 03             	sar    $0x3,%eax
  100df1:	c1 e0 0c             	shl    $0xc,%eax
  100df4:	8b 15 84 f3 10 00    	mov    0x10f384,%edx
  100dfa:	c1 e2 0c             	shl    $0xc,%edx
  100dfd:	39 d0                	cmp    %edx,%eax
  100dff:	72 24                	jb     100e25 <mem_check+0x28e>
  100e01:	c7 44 24 0c 04 59 10 	movl   $0x105904,0xc(%esp)
  100e08:	00 
  100e09:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100e10:	00 
  100e11:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  100e18:	00 
  100e19:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100e20:	e8 4a f6 ff ff       	call   10046f <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100e25:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100e28:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  100e2d:	89 d1                	mov    %edx,%ecx
  100e2f:	29 c1                	sub    %eax,%ecx
  100e31:	89 c8                	mov    %ecx,%eax
  100e33:	c1 f8 03             	sar    $0x3,%eax
  100e36:	c1 e0 0c             	shl    $0xc,%eax
  100e39:	8b 15 84 f3 10 00    	mov    0x10f384,%edx
  100e3f:	c1 e2 0c             	shl    $0xc,%edx
  100e42:	39 d0                	cmp    %edx,%eax
  100e44:	72 24                	jb     100e6a <mem_check+0x2d3>
  100e46:	c7 44 24 0c 2c 59 10 	movl   $0x10592c,0xc(%esp)
  100e4d:	00 
  100e4e:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100e55:	00 
  100e56:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  100e5d:	00 
  100e5e:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100e65:	e8 05 f6 ff ff       	call   10046f <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100e6a:	a1 80 f3 10 00       	mov    0x10f380,%eax
  100e6f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100e72:	c7 05 80 f3 10 00 00 	movl   $0x0,0x10f380
  100e79:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100e7c:	e8 7a fc ff ff       	call   100afb <mem_alloc>
  100e81:	85 c0                	test   %eax,%eax
  100e83:	74 24                	je     100ea9 <mem_check+0x312>
  100e85:	c7 44 24 0c 52 59 10 	movl   $0x105952,0xc(%esp)
  100e8c:	00 
  100e8d:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100e94:	00 
  100e95:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  100e9c:	00 
  100e9d:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100ea4:	e8 c6 f5 ff ff       	call   10046f <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100ea9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100eac:	89 04 24             	mov    %eax,(%esp)
  100eaf:	e8 8e fc ff ff       	call   100b42 <mem_free>
        mem_free(pp1);
  100eb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100eb7:	89 04 24             	mov    %eax,(%esp)
  100eba:	e8 83 fc ff ff       	call   100b42 <mem_free>
        mem_free(pp2);
  100ebf:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ec2:	89 04 24             	mov    %eax,(%esp)
  100ec5:	e8 78 fc ff ff       	call   100b42 <mem_free>
	pp0 = pp1 = pp2 = 0;
  100eca:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100ed1:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ed4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100ed7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100eda:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100edd:	e8 19 fc ff ff       	call   100afb <mem_alloc>
  100ee2:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100ee5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100ee9:	75 24                	jne    100f0f <mem_check+0x378>
  100eeb:	c7 44 24 0c 8b 58 10 	movl   $0x10588b,0xc(%esp)
  100ef2:	00 
  100ef3:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100efa:	00 
  100efb:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  100f02:	00 
  100f03:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100f0a:	e8 60 f5 ff ff       	call   10046f <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100f0f:	e8 e7 fb ff ff       	call   100afb <mem_alloc>
  100f14:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100f17:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100f1b:	75 24                	jne    100f41 <mem_check+0x3aa>
  100f1d:	c7 44 24 0c 94 58 10 	movl   $0x105894,0xc(%esp)
  100f24:	00 
  100f25:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100f2c:	00 
  100f2d:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  100f34:	00 
  100f35:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100f3c:	e8 2e f5 ff ff       	call   10046f <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100f41:	e8 b5 fb ff ff       	call   100afb <mem_alloc>
  100f46:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100f49:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f4d:	75 24                	jne    100f73 <mem_check+0x3dc>
  100f4f:	c7 44 24 0c 9d 58 10 	movl   $0x10589d,0xc(%esp)
  100f56:	00 
  100f57:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100f5e:	00 
  100f5f:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  100f66:	00 
  100f67:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100f6e:	e8 fc f4 ff ff       	call   10046f <debug_panic>
	assert(pp0);
  100f73:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100f77:	75 24                	jne    100f9d <mem_check+0x406>
  100f79:	c7 44 24 0c a6 58 10 	movl   $0x1058a6,0xc(%esp)
  100f80:	00 
  100f81:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100f88:	00 
  100f89:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  100f90:	00 
  100f91:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100f98:	e8 d2 f4 ff ff       	call   10046f <debug_panic>
	assert(pp1 && pp1 != pp0);
  100f9d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100fa1:	74 08                	je     100fab <mem_check+0x414>
  100fa3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100fa6:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100fa9:	75 24                	jne    100fcf <mem_check+0x438>
  100fab:	c7 44 24 0c aa 58 10 	movl   $0x1058aa,0xc(%esp)
  100fb2:	00 
  100fb3:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100fba:	00 
  100fbb:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  100fc2:	00 
  100fc3:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  100fca:	e8 a0 f4 ff ff       	call   10046f <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100fcf:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100fd3:	74 10                	je     100fe5 <mem_check+0x44e>
  100fd5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100fd8:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100fdb:	74 08                	je     100fe5 <mem_check+0x44e>
  100fdd:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100fe0:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100fe3:	75 24                	jne    101009 <mem_check+0x472>
  100fe5:	c7 44 24 0c bc 58 10 	movl   $0x1058bc,0xc(%esp)
  100fec:	00 
  100fed:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  100ff4:	00 
  100ff5:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  100ffc:	00 
  100ffd:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  101004:	e8 66 f4 ff ff       	call   10046f <debug_panic>
	assert(mem_alloc() == 0);
  101009:	e8 ed fa ff ff       	call   100afb <mem_alloc>
  10100e:	85 c0                	test   %eax,%eax
  101010:	74 24                	je     101036 <mem_check+0x49f>
  101012:	c7 44 24 0c 52 59 10 	movl   $0x105952,0xc(%esp)
  101019:	00 
  10101a:	c7 44 24 08 9a 57 10 	movl   $0x10579a,0x8(%esp)
  101021:	00 
  101022:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  101029:	00 
  10102a:	c7 04 24 bc 57 10 00 	movl   $0x1057bc,(%esp)
  101031:	e8 39 f4 ff ff       	call   10046f <debug_panic>

	// give free list back
	mem_freelist = fl;
  101036:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101039:	a3 80 f3 10 00       	mov    %eax,0x10f380

	// free the pages we took
	mem_free(pp0);
  10103e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101041:	89 04 24             	mov    %eax,(%esp)
  101044:	e8 f9 fa ff ff       	call   100b42 <mem_free>
	mem_free(pp1);
  101049:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10104c:	89 04 24             	mov    %eax,(%esp)
  10104f:	e8 ee fa ff ff       	call   100b42 <mem_free>
	mem_free(pp2);
  101054:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101057:	89 04 24             	mov    %eax,(%esp)
  10105a:	e8 e3 fa ff ff       	call   100b42 <mem_free>

	cprintf("mem_check() succeeded!\n");
  10105f:	c7 04 24 63 59 10 00 	movl   $0x105963,(%esp)
  101066:	e8 0b 3e 00 00       	call   104e76 <cprintf>
}
  10106b:	c9                   	leave  
  10106c:	c3                   	ret    

0010106d <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10106d:	55                   	push   %ebp
  10106e:	89 e5                	mov    %esp,%ebp
  101070:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101073:	8b 55 08             	mov    0x8(%ebp),%edx
  101076:	8b 45 0c             	mov    0xc(%ebp),%eax
  101079:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10107c:	f0 87 02             	lock xchg %eax,(%edx)
  10107f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  101082:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101085:	c9                   	leave  
  101086:	c3                   	ret    

00101087 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101087:	55                   	push   %ebp
  101088:	89 e5                	mov    %esp,%ebp
  10108a:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10108d:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101090:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101093:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101096:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101099:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10109e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1010a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1010a4:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1010aa:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1010af:	74 24                	je     1010d5 <cpu_cur+0x4e>
  1010b1:	c7 44 24 0c 7b 59 10 	movl   $0x10597b,0xc(%esp)
  1010b8:	00 
  1010b9:	c7 44 24 08 91 59 10 	movl   $0x105991,0x8(%esp)
  1010c0:	00 
  1010c1:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1010c8:	00 
  1010c9:	c7 04 24 a6 59 10 00 	movl   $0x1059a6,(%esp)
  1010d0:	e8 9a f3 ff ff       	call   10046f <debug_panic>
	return c;
  1010d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1010d8:	c9                   	leave  
  1010d9:	c3                   	ret    

001010da <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1010da:	55                   	push   %ebp
  1010db:	89 e5                	mov    %esp,%ebp
  1010dd:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1010e0:	e8 a2 ff ff ff       	call   101087 <cpu_cur>
  1010e5:	3d 00 80 10 00       	cmp    $0x108000,%eax
  1010ea:	0f 94 c0             	sete   %al
  1010ed:	0f b6 c0             	movzbl %al,%eax
}
  1010f0:	c9                   	leave  
  1010f1:	c3                   	ret    

001010f2 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  1010f2:	55                   	push   %ebp
  1010f3:	89 e5                	mov    %esp,%ebp
  1010f5:	53                   	push   %ebx
  1010f6:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  1010f9:	e8 89 ff ff ff       	call   101087 <cpu_cur>
  1010fe:	89 45 f0             	mov    %eax,-0x10(%ebp)

	c->tss.ts_ss0 = CPU_GDT_KDATA;
  101101:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101104:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)
	c->tss.ts_esp0 = (uintptr_t)c->kstackhi; 
  10110a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10110d:	05 00 10 00 00       	add    $0x1000,%eax
  101112:	89 c2                	mov    %eax,%edx
  101114:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101117:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->gdt[CPU_GDT_TSS>>3] = SEGDESC16(0, STS_T32A, (uintptr_t)(&c->tss), sizeof(c->tss) - 1, 0);
  10111a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10111d:	83 c0 38             	add    $0x38,%eax
  101120:	89 c3                	mov    %eax,%ebx
  101122:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101125:	83 c0 38             	add    $0x38,%eax
  101128:	c1 e8 10             	shr    $0x10,%eax
  10112b:	89 c1                	mov    %eax,%ecx
  10112d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101130:	83 c0 38             	add    $0x38,%eax
  101133:	c1 e8 18             	shr    $0x18,%eax
  101136:	89 c2                	mov    %eax,%edx
  101138:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10113b:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  101141:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101144:	66 89 58 32          	mov    %bx,0x32(%eax)
  101148:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10114b:	88 48 34             	mov    %cl,0x34(%eax)
  10114e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101151:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101155:	83 e1 f0             	and    $0xfffffff0,%ecx
  101158:	83 c9 09             	or     $0x9,%ecx
  10115b:	88 48 35             	mov    %cl,0x35(%eax)
  10115e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101161:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101165:	83 e1 ef             	and    $0xffffffef,%ecx
  101168:	88 48 35             	mov    %cl,0x35(%eax)
  10116b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10116e:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101172:	83 e1 9f             	and    $0xffffff9f,%ecx
  101175:	88 48 35             	mov    %cl,0x35(%eax)
  101178:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10117b:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  10117f:	83 c9 80             	or     $0xffffff80,%ecx
  101182:	88 48 35             	mov    %cl,0x35(%eax)
  101185:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101188:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10118c:	83 e1 f0             	and    $0xfffffff0,%ecx
  10118f:	88 48 36             	mov    %cl,0x36(%eax)
  101192:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101195:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101199:	83 e1 ef             	and    $0xffffffef,%ecx
  10119c:	88 48 36             	mov    %cl,0x36(%eax)
  10119f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011a2:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1011a6:	83 e1 df             	and    $0xffffffdf,%ecx
  1011a9:	88 48 36             	mov    %cl,0x36(%eax)
  1011ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011af:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1011b3:	83 c9 40             	or     $0x40,%ecx
  1011b6:	88 48 36             	mov    %cl,0x36(%eax)
  1011b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011bc:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1011c0:	83 e1 7f             	and    $0x7f,%ecx
  1011c3:	88 48 36             	mov    %cl,0x36(%eax)
  1011c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011c9:	88 50 37             	mov    %dl,0x37(%eax)


	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  1011cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011cf:	66 c7 45 ea 37 00    	movw   $0x37,-0x16(%ebp)
  1011d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  1011d8:	0f 01 55 ea          	lgdtl  -0x16(%ebp)
  1011dc:	66 c7 45 f6 30 00    	movw   $0x30,-0xa(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1011e2:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  1011e6:	0f 00 d8             	ltr    %ax
	ltr(CPU_GDT_TSS);
	
	// Reload all segment registers.
	//asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
	//asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1011e9:	b8 10 00 00 00       	mov    $0x10,%eax
  1011ee:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  1011f0:	b8 10 00 00 00       	mov    $0x10,%eax
  1011f5:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1011f7:	b8 10 00 00 00       	mov    $0x10,%eax
  1011fc:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  1011fe:	ea 05 12 10 00 08 00 	ljmp   $0x8,$0x101205

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  101205:	b8 00 00 00 00       	mov    $0x0,%eax
  10120a:	0f 00 d0             	lldt   %ax
}
  10120d:	83 c4 14             	add    $0x14,%esp
  101210:	5b                   	pop    %ebx
  101211:	5d                   	pop    %ebp
  101212:	c3                   	ret    

00101213 <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  101213:	55                   	push   %ebp
  101214:	89 e5                	mov    %esp,%ebp
  101216:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  101219:	e8 dd f8 ff ff       	call   100afb <mem_alloc>
  10121e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  101221:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101225:	75 24                	jne    10124b <cpu_alloc+0x38>
  101227:	c7 44 24 0c b3 59 10 	movl   $0x1059b3,0xc(%esp)
  10122e:	00 
  10122f:	c7 44 24 08 91 59 10 	movl   $0x105991,0x8(%esp)
  101236:	00 
  101237:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  10123e:	00 
  10123f:	c7 04 24 bb 59 10 00 	movl   $0x1059bb,(%esp)
  101246:	e8 24 f2 ff ff       	call   10046f <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  10124b:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10124e:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  101253:	89 d1                	mov    %edx,%ecx
  101255:	29 c1                	sub    %eax,%ecx
  101257:	89 c8                	mov    %ecx,%eax
  101259:	c1 f8 03             	sar    $0x3,%eax
  10125c:	c1 e0 0c             	shl    $0xc,%eax
  10125f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  101262:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  101269:	00 
  10126a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101271:	00 
  101272:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101275:	89 04 24             	mov    %eax,(%esp)
  101278:	e8 de 3d 00 00       	call   10505b <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  10127d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101280:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101287:	00 
  101288:	c7 44 24 04 00 80 10 	movl   $0x108000,0x4(%esp)
  10128f:	00 
  101290:	89 04 24             	mov    %eax,(%esp)
  101293:	e8 37 3e 00 00       	call   1050cf <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  101298:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10129b:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  1012a2:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  1012a5:	a1 00 90 10 00       	mov    0x109000,%eax
  1012aa:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1012ad:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  1012af:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012b2:	05 a8 00 00 00       	add    $0xa8,%eax
  1012b7:	a3 00 90 10 00       	mov    %eax,0x109000

	return c;
  1012bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1012bf:	c9                   	leave  
  1012c0:	c3                   	ret    

001012c1 <cpu_bootothers>:

void
cpu_bootothers(void)
{
  1012c1:	55                   	push   %ebp
  1012c2:	89 e5                	mov    %esp,%ebp
  1012c4:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  1012c7:	e8 0e fe ff ff       	call   1010da <cpu_onboot>
  1012cc:	85 c0                	test   %eax,%eax
  1012ce:	75 1f                	jne    1012ef <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  1012d0:	e8 b2 fd ff ff       	call   101087 <cpu_cur>
  1012d5:	05 b0 00 00 00       	add    $0xb0,%eax
  1012da:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1012e1:	00 
  1012e2:	89 04 24             	mov    %eax,(%esp)
  1012e5:	e8 83 fd ff ff       	call   10106d <xchg>
		return;
  1012ea:	e9 91 00 00 00       	jmp    101380 <cpu_bootothers+0xbf>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  1012ef:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  1012f6:	b8 6a 00 00 00       	mov    $0x6a,%eax
  1012fb:	89 44 24 08          	mov    %eax,0x8(%esp)
  1012ff:	c7 44 24 04 32 96 10 	movl   $0x109632,0x4(%esp)
  101306:	00 
  101307:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10130a:	89 04 24             	mov    %eax,(%esp)
  10130d:	e8 bd 3d 00 00       	call   1050cf <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  101312:	c7 45 f4 00 80 10 00 	movl   $0x108000,-0xc(%ebp)
  101319:	eb 5f                	jmp    10137a <cpu_bootothers+0xb9>
		if(c == cpu_cur())  // We''ve started already.
  10131b:	e8 67 fd ff ff       	call   101087 <cpu_cur>
  101320:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  101323:	74 48                	je     10136d <cpu_bootothers+0xac>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  101325:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101328:	83 e8 04             	sub    $0x4,%eax
  10132b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10132e:	81 c2 00 10 00 00    	add    $0x1000,%edx
  101334:	89 10                	mov    %edx,(%eax)
		*(void**)(code-8) = init;
  101336:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101339:	83 e8 08             	sub    $0x8,%eax
  10133c:	c7 00 91 00 10 00    	movl   $0x100091,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  101342:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101345:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101348:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10134f:	0f b6 c0             	movzbl %al,%eax
  101352:	89 54 24 04          	mov    %edx,0x4(%esp)
  101356:	89 04 24             	mov    %eax,(%esp)
  101359:	e8 0f 31 00 00       	call   10446d <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  10135e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101361:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  101367:	85 c0                	test   %eax,%eax
  101369:	74 f3                	je     10135e <cpu_bootothers+0x9d>
  10136b:	eb 01                	jmp    10136e <cpu_bootothers+0xad>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
		if(c == cpu_cur())  // We''ve started already.
			continue;
  10136d:	90                   	nop
	uint8_t *code = (uint8_t*)0x1000;
	memmove(code, _binary_obj_boot_bootother_start,
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  10136e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101371:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101377:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10137a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10137e:	75 9b                	jne    10131b <cpu_bootothers+0x5a>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
			;
	}
}
  101380:	c9                   	leave  
  101381:	c3                   	ret    

00101382 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101382:	55                   	push   %ebp
  101383:	89 e5                	mov    %esp,%ebp
  101385:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101388:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10138b:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10138e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101391:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101394:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101399:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10139c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10139f:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1013a5:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1013aa:	74 24                	je     1013d0 <cpu_cur+0x4e>
  1013ac:	c7 44 24 0c e0 59 10 	movl   $0x1059e0,0xc(%esp)
  1013b3:	00 
  1013b4:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  1013bb:	00 
  1013bc:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1013c3:	00 
  1013c4:	c7 04 24 0b 5a 10 00 	movl   $0x105a0b,(%esp)
  1013cb:	e8 9f f0 ff ff       	call   10046f <debug_panic>
	return c;
  1013d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1013d3:	c9                   	leave  
  1013d4:	c3                   	ret    

001013d5 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1013d5:	55                   	push   %ebp
  1013d6:	89 e5                	mov    %esp,%ebp
  1013d8:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1013db:	e8 a2 ff ff ff       	call   101382 <cpu_cur>
  1013e0:	3d 00 80 10 00       	cmp    $0x108000,%eax
  1013e5:	0f 94 c0             	sete   %al
  1013e8:	0f b6 c0             	movzbl %al,%eax
}
  1013eb:	c9                   	leave  
  1013ec:	c3                   	ret    

001013ed <trap_init_idt>:

extern uint32_t vectors[];

static void
trap_init_idt(void)
{
  1013ed:	55                   	push   %ebp
  1013ee:	89 e5                	mov    %esp,%ebp
  1013f0:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  1013f3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1013fa:	e9 bc 00 00 00       	jmp    1014bb <trap_init_idt+0xce>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
  1013ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101402:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101405:	8b 14 95 10 90 10 00 	mov    0x109010(,%edx,4),%edx
  10140c:	66 89 14 c5 c0 a8 10 	mov    %dx,0x10a8c0(,%eax,8)
  101413:	00 
  101414:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101417:	66 c7 04 c5 c2 a8 10 	movw   $0x8,0x10a8c2(,%eax,8)
  10141e:	00 08 00 
  101421:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101424:	0f b6 14 c5 c4 a8 10 	movzbl 0x10a8c4(,%eax,8),%edx
  10142b:	00 
  10142c:	83 e2 e0             	and    $0xffffffe0,%edx
  10142f:	88 14 c5 c4 a8 10 00 	mov    %dl,0x10a8c4(,%eax,8)
  101436:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101439:	0f b6 14 c5 c4 a8 10 	movzbl 0x10a8c4(,%eax,8),%edx
  101440:	00 
  101441:	83 e2 1f             	and    $0x1f,%edx
  101444:	88 14 c5 c4 a8 10 00 	mov    %dl,0x10a8c4(,%eax,8)
  10144b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10144e:	0f b6 14 c5 c5 a8 10 	movzbl 0x10a8c5(,%eax,8),%edx
  101455:	00 
  101456:	83 ca 0f             	or     $0xf,%edx
  101459:	88 14 c5 c5 a8 10 00 	mov    %dl,0x10a8c5(,%eax,8)
  101460:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101463:	0f b6 14 c5 c5 a8 10 	movzbl 0x10a8c5(,%eax,8),%edx
  10146a:	00 
  10146b:	83 e2 ef             	and    $0xffffffef,%edx
  10146e:	88 14 c5 c5 a8 10 00 	mov    %dl,0x10a8c5(,%eax,8)
  101475:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101478:	0f b6 14 c5 c5 a8 10 	movzbl 0x10a8c5(,%eax,8),%edx
  10147f:	00 
  101480:	83 ca 60             	or     $0x60,%edx
  101483:	88 14 c5 c5 a8 10 00 	mov    %dl,0x10a8c5(,%eax,8)
  10148a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10148d:	0f b6 14 c5 c5 a8 10 	movzbl 0x10a8c5(,%eax,8),%edx
  101494:	00 
  101495:	83 ca 80             	or     $0xffffff80,%edx
  101498:	88 14 c5 c5 a8 10 00 	mov    %dl,0x10a8c5(,%eax,8)
  10149f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1014a2:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1014a5:	8b 14 95 10 90 10 00 	mov    0x109010(,%edx,4),%edx
  1014ac:	c1 ea 10             	shr    $0x10,%edx
  1014af:	66 89 14 c5 c6 a8 10 	mov    %dx,0x10a8c6(,%eax,8)
  1014b6:	00 
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  1014b7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1014bb:	83 7d fc 13          	cmpl   $0x13,-0x4(%ebp)
  1014bf:	0f 8e 3a ff ff ff    	jle    1013ff <trap_init_idt+0x12>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
	}
	SETGATE(idt[30], 1, CPU_GDT_KCODE, vectors[30], 3);
  1014c5:	a1 88 90 10 00       	mov    0x109088,%eax
  1014ca:	66 a3 b0 a9 10 00    	mov    %ax,0x10a9b0
  1014d0:	66 c7 05 b2 a9 10 00 	movw   $0x8,0x10a9b2
  1014d7:	08 00 
  1014d9:	0f b6 05 b4 a9 10 00 	movzbl 0x10a9b4,%eax
  1014e0:	83 e0 e0             	and    $0xffffffe0,%eax
  1014e3:	a2 b4 a9 10 00       	mov    %al,0x10a9b4
  1014e8:	0f b6 05 b4 a9 10 00 	movzbl 0x10a9b4,%eax
  1014ef:	83 e0 1f             	and    $0x1f,%eax
  1014f2:	a2 b4 a9 10 00       	mov    %al,0x10a9b4
  1014f7:	0f b6 05 b5 a9 10 00 	movzbl 0x10a9b5,%eax
  1014fe:	83 c8 0f             	or     $0xf,%eax
  101501:	a2 b5 a9 10 00       	mov    %al,0x10a9b5
  101506:	0f b6 05 b5 a9 10 00 	movzbl 0x10a9b5,%eax
  10150d:	83 e0 ef             	and    $0xffffffef,%eax
  101510:	a2 b5 a9 10 00       	mov    %al,0x10a9b5
  101515:	0f b6 05 b5 a9 10 00 	movzbl 0x10a9b5,%eax
  10151c:	83 c8 60             	or     $0x60,%eax
  10151f:	a2 b5 a9 10 00       	mov    %al,0x10a9b5
  101524:	0f b6 05 b5 a9 10 00 	movzbl 0x10a9b5,%eax
  10152b:	83 c8 80             	or     $0xffffff80,%eax
  10152e:	a2 b5 a9 10 00       	mov    %al,0x10a9b5
  101533:	a1 88 90 10 00       	mov    0x109088,%eax
  101538:	c1 e8 10             	shr    $0x10,%eax
  10153b:	66 a3 b6 a9 10 00    	mov    %ax,0x10a9b6
	SETGATE(idt[T_SYSCALL], 1, CPU_GDT_KCODE, vectors[T_SYSCALL], 3);
  101541:	a1 d0 90 10 00       	mov    0x1090d0,%eax
  101546:	66 a3 40 aa 10 00    	mov    %ax,0x10aa40
  10154c:	66 c7 05 42 aa 10 00 	movw   $0x8,0x10aa42
  101553:	08 00 
  101555:	0f b6 05 44 aa 10 00 	movzbl 0x10aa44,%eax
  10155c:	83 e0 e0             	and    $0xffffffe0,%eax
  10155f:	a2 44 aa 10 00       	mov    %al,0x10aa44
  101564:	0f b6 05 44 aa 10 00 	movzbl 0x10aa44,%eax
  10156b:	83 e0 1f             	and    $0x1f,%eax
  10156e:	a2 44 aa 10 00       	mov    %al,0x10aa44
  101573:	0f b6 05 45 aa 10 00 	movzbl 0x10aa45,%eax
  10157a:	83 c8 0f             	or     $0xf,%eax
  10157d:	a2 45 aa 10 00       	mov    %al,0x10aa45
  101582:	0f b6 05 45 aa 10 00 	movzbl 0x10aa45,%eax
  101589:	83 e0 ef             	and    $0xffffffef,%eax
  10158c:	a2 45 aa 10 00       	mov    %al,0x10aa45
  101591:	0f b6 05 45 aa 10 00 	movzbl 0x10aa45,%eax
  101598:	83 c8 60             	or     $0x60,%eax
  10159b:	a2 45 aa 10 00       	mov    %al,0x10aa45
  1015a0:	0f b6 05 45 aa 10 00 	movzbl 0x10aa45,%eax
  1015a7:	83 c8 80             	or     $0xffffff80,%eax
  1015aa:	a2 45 aa 10 00       	mov    %al,0x10aa45
  1015af:	a1 d0 90 10 00       	mov    0x1090d0,%eax
  1015b4:	c1 e8 10             	shr    $0x10,%eax
  1015b7:	66 a3 46 aa 10 00    	mov    %ax,0x10aa46
}
  1015bd:	c9                   	leave  
  1015be:	c3                   	ret    

001015bf <trap_init>:

void
trap_init(void)
{
  1015bf:	55                   	push   %ebp
  1015c0:	89 e5                	mov    %esp,%ebp
  1015c2:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  1015c5:	e8 0b fe ff ff       	call   1013d5 <cpu_onboot>
  1015ca:	85 c0                	test   %eax,%eax
  1015cc:	74 05                	je     1015d3 <trap_init+0x14>
		trap_init_idt();
  1015ce:	e8 1a fe ff ff       	call   1013ed <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  1015d3:	0f 01 1d 04 90 10 00 	lidtl  0x109004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  1015da:	e8 f6 fd ff ff       	call   1013d5 <cpu_onboot>
  1015df:	85 c0                	test   %eax,%eax
  1015e1:	74 05                	je     1015e8 <trap_init+0x29>
		trap_check_kernel();
  1015e3:	e8 b4 02 00 00       	call   10189c <trap_check_kernel>
}
  1015e8:	c9                   	leave  
  1015e9:	c3                   	ret    

001015ea <trap_name>:

const char *trap_name(int trapno)
{
  1015ea:	55                   	push   %ebp
  1015eb:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  1015ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1015f0:	83 f8 13             	cmp    $0x13,%eax
  1015f3:	77 0c                	ja     101601 <trap_name+0x17>
		return excnames[trapno];
  1015f5:	8b 45 08             	mov    0x8(%ebp),%eax
  1015f8:	8b 04 85 e0 5d 10 00 	mov    0x105de0(,%eax,4),%eax
  1015ff:	eb 25                	jmp    101626 <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  101601:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  101605:	75 07                	jne    10160e <trap_name+0x24>
		return "System call";
  101607:	b8 18 5a 10 00       	mov    $0x105a18,%eax
  10160c:	eb 18                	jmp    101626 <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  10160e:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  101612:	7e 0d                	jle    101621 <trap_name+0x37>
  101614:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  101618:	7f 07                	jg     101621 <trap_name+0x37>
		return "Hardware Interrupt";
  10161a:	b8 24 5a 10 00       	mov    $0x105a24,%eax
  10161f:	eb 05                	jmp    101626 <trap_name+0x3c>
	return "(unknown trap)";
  101621:	b8 37 5a 10 00       	mov    $0x105a37,%eax
}
  101626:	5d                   	pop    %ebp
  101627:	c3                   	ret    

00101628 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101628:	55                   	push   %ebp
  101629:	89 e5                	mov    %esp,%ebp
  10162b:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  10162e:	8b 45 08             	mov    0x8(%ebp),%eax
  101631:	8b 00                	mov    (%eax),%eax
  101633:	89 44 24 04          	mov    %eax,0x4(%esp)
  101637:	c7 04 24 46 5a 10 00 	movl   $0x105a46,(%esp)
  10163e:	e8 33 38 00 00       	call   104e76 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  101643:	8b 45 08             	mov    0x8(%ebp),%eax
  101646:	8b 40 04             	mov    0x4(%eax),%eax
  101649:	89 44 24 04          	mov    %eax,0x4(%esp)
  10164d:	c7 04 24 55 5a 10 00 	movl   $0x105a55,(%esp)
  101654:	e8 1d 38 00 00       	call   104e76 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101659:	8b 45 08             	mov    0x8(%ebp),%eax
  10165c:	8b 40 08             	mov    0x8(%eax),%eax
  10165f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101663:	c7 04 24 64 5a 10 00 	movl   $0x105a64,(%esp)
  10166a:	e8 07 38 00 00       	call   104e76 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  10166f:	8b 45 08             	mov    0x8(%ebp),%eax
  101672:	8b 40 10             	mov    0x10(%eax),%eax
  101675:	89 44 24 04          	mov    %eax,0x4(%esp)
  101679:	c7 04 24 73 5a 10 00 	movl   $0x105a73,(%esp)
  101680:	e8 f1 37 00 00       	call   104e76 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101685:	8b 45 08             	mov    0x8(%ebp),%eax
  101688:	8b 40 14             	mov    0x14(%eax),%eax
  10168b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10168f:	c7 04 24 82 5a 10 00 	movl   $0x105a82,(%esp)
  101696:	e8 db 37 00 00       	call   104e76 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  10169b:	8b 45 08             	mov    0x8(%ebp),%eax
  10169e:	8b 40 18             	mov    0x18(%eax),%eax
  1016a1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016a5:	c7 04 24 91 5a 10 00 	movl   $0x105a91,(%esp)
  1016ac:	e8 c5 37 00 00       	call   104e76 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1016b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1016b4:	8b 40 1c             	mov    0x1c(%eax),%eax
  1016b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016bb:	c7 04 24 a0 5a 10 00 	movl   $0x105aa0,(%esp)
  1016c2:	e8 af 37 00 00       	call   104e76 <cprintf>
}
  1016c7:	c9                   	leave  
  1016c8:	c3                   	ret    

001016c9 <trap_print>:

void
trap_print(trapframe *tf)
{
  1016c9:	55                   	push   %ebp
  1016ca:	89 e5                	mov    %esp,%ebp
  1016cc:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  1016cf:	8b 45 08             	mov    0x8(%ebp),%eax
  1016d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016d6:	c7 04 24 af 5a 10 00 	movl   $0x105aaf,(%esp)
  1016dd:	e8 94 37 00 00       	call   104e76 <cprintf>
	trap_print_regs(&tf->regs);
  1016e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1016e5:	89 04 24             	mov    %eax,(%esp)
  1016e8:	e8 3b ff ff ff       	call   101628 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  1016ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1016f0:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  1016f4:	0f b7 c0             	movzwl %ax,%eax
  1016f7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016fb:	c7 04 24 c1 5a 10 00 	movl   $0x105ac1,(%esp)
  101702:	e8 6f 37 00 00       	call   104e76 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101707:	8b 45 08             	mov    0x8(%ebp),%eax
  10170a:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10170e:	0f b7 c0             	movzwl %ax,%eax
  101711:	89 44 24 04          	mov    %eax,0x4(%esp)
  101715:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  10171c:	e8 55 37 00 00       	call   104e76 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101721:	8b 45 08             	mov    0x8(%ebp),%eax
  101724:	8b 40 30             	mov    0x30(%eax),%eax
  101727:	89 04 24             	mov    %eax,(%esp)
  10172a:	e8 bb fe ff ff       	call   1015ea <trap_name>
  10172f:	8b 55 08             	mov    0x8(%ebp),%edx
  101732:	8b 52 30             	mov    0x30(%edx),%edx
  101735:	89 44 24 08          	mov    %eax,0x8(%esp)
  101739:	89 54 24 04          	mov    %edx,0x4(%esp)
  10173d:	c7 04 24 e7 5a 10 00 	movl   $0x105ae7,(%esp)
  101744:	e8 2d 37 00 00       	call   104e76 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101749:	8b 45 08             	mov    0x8(%ebp),%eax
  10174c:	8b 40 34             	mov    0x34(%eax),%eax
  10174f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101753:	c7 04 24 f9 5a 10 00 	movl   $0x105af9,(%esp)
  10175a:	e8 17 37 00 00       	call   104e76 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  10175f:	8b 45 08             	mov    0x8(%ebp),%eax
  101762:	8b 40 38             	mov    0x38(%eax),%eax
  101765:	89 44 24 04          	mov    %eax,0x4(%esp)
  101769:	c7 04 24 08 5b 10 00 	movl   $0x105b08,(%esp)
  101770:	e8 01 37 00 00       	call   104e76 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101775:	8b 45 08             	mov    0x8(%ebp),%eax
  101778:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10177c:	0f b7 c0             	movzwl %ax,%eax
  10177f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101783:	c7 04 24 17 5b 10 00 	movl   $0x105b17,(%esp)
  10178a:	e8 e7 36 00 00       	call   104e76 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  10178f:	8b 45 08             	mov    0x8(%ebp),%eax
  101792:	8b 40 40             	mov    0x40(%eax),%eax
  101795:	89 44 24 04          	mov    %eax,0x4(%esp)
  101799:	c7 04 24 2a 5b 10 00 	movl   $0x105b2a,(%esp)
  1017a0:	e8 d1 36 00 00       	call   104e76 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1017a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1017a8:	8b 40 44             	mov    0x44(%eax),%eax
  1017ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017af:	c7 04 24 39 5b 10 00 	movl   $0x105b39,(%esp)
  1017b6:	e8 bb 36 00 00       	call   104e76 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1017bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1017be:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1017c2:	0f b7 c0             	movzwl %ax,%eax
  1017c5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017c9:	c7 04 24 48 5b 10 00 	movl   $0x105b48,(%esp)
  1017d0:	e8 a1 36 00 00       	call   104e76 <cprintf>
}
  1017d5:	c9                   	leave  
  1017d6:	c3                   	ret    

001017d7 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  1017d7:	55                   	push   %ebp
  1017d8:	89 e5                	mov    %esp,%ebp
  1017da:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  1017dd:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  1017de:	e8 9f fb ff ff       	call   101382 <cpu_cur>
  1017e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  1017e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1017e9:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1017ef:	85 c0                	test   %eax,%eax
  1017f1:	74 1e                	je     101811 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  1017f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1017f6:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  1017fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1017ff:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  101805:	89 44 24 04          	mov    %eax,0x4(%esp)
  101809:	8b 45 08             	mov    0x8(%ebp),%eax
  10180c:	89 04 24             	mov    %eax,(%esp)
  10180f:	ff d2                	call   *%edx

	// Lab 2: your trap handling code here!
	if(tf->trapno == T_SYSCALL){
  101811:	8b 45 08             	mov    0x8(%ebp),%eax
  101814:	8b 40 30             	mov    0x30(%eax),%eax
  101817:	83 f8 30             	cmp    $0x30,%eax
  10181a:	75 0b                	jne    101827 <trap+0x50>
		syscall(tf);
  10181c:	8b 45 08             	mov    0x8(%ebp),%eax
  10181f:	89 04 24             	mov    %eax,(%esp)
  101822:	e8 5e 20 00 00       	call   103885 <syscall>
		//panic("unhandler system call\n");
	}
	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
  101827:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  10182e:	e8 ce 0a 00 00       	call   102301 <spinlock_holding>
  101833:	85 c0                	test   %eax,%eax
  101835:	74 0c                	je     101843 <trap+0x6c>
		spinlock_release(&cons_lock);
  101837:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  10183e:	e8 64 0a 00 00       	call   1022a7 <spinlock_release>
	trap_print(tf);
  101843:	8b 45 08             	mov    0x8(%ebp),%eax
  101846:	89 04 24             	mov    %eax,(%esp)
  101849:	e8 7b fe ff ff       	call   1016c9 <trap_print>
	panic("unhandled trap");
  10184e:	c7 44 24 08 5b 5b 10 	movl   $0x105b5b,0x8(%esp)
  101855:	00 
  101856:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  10185d:	00 
  10185e:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  101865:	e8 05 ec ff ff       	call   10046f <debug_panic>

0010186a <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  10186a:	55                   	push   %ebp
  10186b:	89 e5                	mov    %esp,%ebp
  10186d:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101870:	8b 45 0c             	mov    0xc(%ebp),%eax
  101873:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101876:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101879:	8b 00                	mov    (%eax),%eax
  10187b:	89 c2                	mov    %eax,%edx
  10187d:	8b 45 08             	mov    0x8(%ebp),%eax
  101880:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  101883:	8b 45 08             	mov    0x8(%ebp),%eax
  101886:	8b 40 30             	mov    0x30(%eax),%eax
  101889:	89 c2                	mov    %eax,%edx
  10188b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10188e:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  101891:	8b 45 08             	mov    0x8(%ebp),%eax
  101894:	89 04 24             	mov    %eax,(%esp)
  101897:	e8 54 78 00 00       	call   1090f0 <trap_return>

0010189c <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  10189c:	55                   	push   %ebp
  10189d:	89 e5                	mov    %esp,%ebp
  10189f:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1018a2:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  1018a5:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  1018a9:	0f b7 c0             	movzwl %ax,%eax
  1018ac:	83 e0 03             	and    $0x3,%eax
  1018af:	85 c0                	test   %eax,%eax
  1018b1:	74 24                	je     1018d7 <trap_check_kernel+0x3b>
  1018b3:	c7 44 24 0c 76 5b 10 	movl   $0x105b76,0xc(%esp)
  1018ba:	00 
  1018bb:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  1018c2:	00 
  1018c3:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  1018ca:	00 
  1018cb:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  1018d2:	e8 98 eb ff ff       	call   10046f <debug_panic>

	cpu *c = cpu_cur();
  1018d7:	e8 a6 fa ff ff       	call   101382 <cpu_cur>
  1018dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  1018df:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1018e2:	c7 80 a0 00 00 00 6a 	movl   $0x10186a,0xa0(%eax)
  1018e9:	18 10 00 
	trap_check(&c->recoverdata);
  1018ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1018ef:	05 a4 00 00 00       	add    $0xa4,%eax
  1018f4:	89 04 24             	mov    %eax,(%esp)
  1018f7:	e8 96 00 00 00       	call   101992 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1018fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1018ff:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101906:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  101909:	c7 04 24 8c 5b 10 00 	movl   $0x105b8c,(%esp)
  101910:	e8 61 35 00 00       	call   104e76 <cprintf>
}
  101915:	c9                   	leave  
  101916:	c3                   	ret    

00101917 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101917:	55                   	push   %ebp
  101918:	89 e5                	mov    %esp,%ebp
  10191a:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10191d:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  101920:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101924:	0f b7 c0             	movzwl %ax,%eax
  101927:	83 e0 03             	and    $0x3,%eax
  10192a:	83 f8 03             	cmp    $0x3,%eax
  10192d:	74 24                	je     101953 <trap_check_user+0x3c>
  10192f:	c7 44 24 0c ac 5b 10 	movl   $0x105bac,0xc(%esp)
  101936:	00 
  101937:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  10193e:	00 
  10193f:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
  101946:	00 
  101947:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  10194e:	e8 1c eb ff ff       	call   10046f <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101953:	c7 45 f0 00 80 10 00 	movl   $0x108000,-0x10(%ebp)
	c->recover = trap_check_recover;
  10195a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10195d:	c7 80 a0 00 00 00 6a 	movl   $0x10186a,0xa0(%eax)
  101964:	18 10 00 
	trap_check(&c->recoverdata);
  101967:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10196a:	05 a4 00 00 00       	add    $0xa4,%eax
  10196f:	89 04 24             	mov    %eax,(%esp)
  101972:	e8 1b 00 00 00       	call   101992 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101977:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10197a:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101981:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101984:	c7 04 24 c1 5b 10 00 	movl   $0x105bc1,(%esp)
  10198b:	e8 e6 34 00 00       	call   104e76 <cprintf>
}
  101990:	c9                   	leave  
  101991:	c3                   	ret    

00101992 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  101992:	55                   	push   %ebp
  101993:	89 e5                	mov    %esp,%ebp
  101995:	57                   	push   %edi
  101996:	56                   	push   %esi
  101997:	53                   	push   %ebx
  101998:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  10199b:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  1019a2:	8b 45 08             	mov    0x8(%ebp),%eax
  1019a5:	8d 55 d8             	lea    -0x28(%ebp),%edx
  1019a8:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  1019aa:	c7 45 d8 b8 19 10 00 	movl   $0x1019b8,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1019b1:	b8 00 00 00 00       	mov    $0x0,%eax
  1019b6:	f7 f0                	div    %eax

001019b8 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1019b8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1019bb:	85 c0                	test   %eax,%eax
  1019bd:	74 24                	je     1019e3 <after_div0+0x2b>
  1019bf:	c7 44 24 0c df 5b 10 	movl   $0x105bdf,0xc(%esp)
  1019c6:	00 
  1019c7:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  1019ce:	00 
  1019cf:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  1019d6:	00 
  1019d7:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  1019de:	e8 8c ea ff ff       	call   10046f <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1019e3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1019e6:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1019eb:	74 24                	je     101a11 <after_div0+0x59>
  1019ed:	c7 44 24 0c f7 5b 10 	movl   $0x105bf7,0xc(%esp)
  1019f4:	00 
  1019f5:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  1019fc:	00 
  1019fd:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  101a04:	00 
  101a05:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  101a0c:	e8 5e ea ff ff       	call   10046f <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101a11:	c7 45 d8 19 1a 10 00 	movl   $0x101a19,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  101a18:	cc                   	int3   

00101a19 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101a19:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101a1c:	83 f8 03             	cmp    $0x3,%eax
  101a1f:	74 24                	je     101a45 <after_breakpoint+0x2c>
  101a21:	c7 44 24 0c 0c 5c 10 	movl   $0x105c0c,0xc(%esp)
  101a28:	00 
  101a29:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  101a30:	00 
  101a31:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  101a38:	00 
  101a39:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  101a40:	e8 2a ea ff ff       	call   10046f <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101a45:	c7 45 d8 54 1a 10 00 	movl   $0x101a54,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101a4c:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101a51:	01 c0                	add    %eax,%eax
  101a53:	ce                   	into   

00101a54 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101a54:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101a57:	83 f8 04             	cmp    $0x4,%eax
  101a5a:	74 24                	je     101a80 <after_overflow+0x2c>
  101a5c:	c7 44 24 0c 23 5c 10 	movl   $0x105c23,0xc(%esp)
  101a63:	00 
  101a64:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  101a6b:	00 
  101a6c:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
  101a73:	00 
  101a74:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  101a7b:	e8 ef e9 ff ff       	call   10046f <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101a80:	c7 45 d8 9d 1a 10 00 	movl   $0x101a9d,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  101a87:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101a8e:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  101a95:	b8 00 00 00 00       	mov    $0x0,%eax
  101a9a:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101a9d <after_bound>:
	assert(args.trapno == T_BOUND);
  101a9d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101aa0:	83 f8 05             	cmp    $0x5,%eax
  101aa3:	74 24                	je     101ac9 <after_bound+0x2c>
  101aa5:	c7 44 24 0c 3a 5c 10 	movl   $0x105c3a,0xc(%esp)
  101aac:	00 
  101aad:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  101ab4:	00 
  101ab5:	c7 44 24 04 f4 00 00 	movl   $0xf4,0x4(%esp)
  101abc:	00 
  101abd:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  101ac4:	e8 a6 e9 ff ff       	call   10046f <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  101ac9:	c7 45 d8 d2 1a 10 00 	movl   $0x101ad2,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101ad0:	0f 0b                	ud2    

00101ad2 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101ad2:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101ad5:	83 f8 06             	cmp    $0x6,%eax
  101ad8:	74 24                	je     101afe <after_illegal+0x2c>
  101ada:	c7 44 24 0c 51 5c 10 	movl   $0x105c51,0xc(%esp)
  101ae1:	00 
  101ae2:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  101ae9:	00 
  101aea:	c7 44 24 04 f9 00 00 	movl   $0xf9,0x4(%esp)
  101af1:	00 
  101af2:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  101af9:	e8 71 e9 ff ff       	call   10046f <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101afe:	c7 45 d8 0c 1b 10 00 	movl   $0x101b0c,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101b05:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101b0a:	8e e0                	mov    %eax,%fs

00101b0c <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101b0c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101b0f:	83 f8 0d             	cmp    $0xd,%eax
  101b12:	74 24                	je     101b38 <after_gpfault+0x2c>
  101b14:	c7 44 24 0c 68 5c 10 	movl   $0x105c68,0xc(%esp)
  101b1b:	00 
  101b1c:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  101b23:	00 
  101b24:	c7 44 24 04 fe 00 00 	movl   $0xfe,0x4(%esp)
  101b2b:	00 
  101b2c:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  101b33:	e8 37 e9 ff ff       	call   10046f <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101b38:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  101b3b:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101b3f:	0f b7 c0             	movzwl %ax,%eax
  101b42:	83 e0 03             	and    $0x3,%eax
  101b45:	85 c0                	test   %eax,%eax
  101b47:	74 3a                	je     101b83 <after_priv+0x2c>
		args.reip = after_priv;
  101b49:	c7 45 d8 57 1b 10 00 	movl   $0x101b57,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101b50:	0f 01 1d 04 90 10 00 	lidtl  0x109004

00101b57 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101b57:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101b5a:	83 f8 0d             	cmp    $0xd,%eax
  101b5d:	74 24                	je     101b83 <after_priv+0x2c>
  101b5f:	c7 44 24 0c 68 5c 10 	movl   $0x105c68,0xc(%esp)
  101b66:	00 
  101b67:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  101b6e:	00 
  101b6f:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
  101b76:	00 
  101b77:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  101b7e:	e8 ec e8 ff ff       	call   10046f <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101b83:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101b86:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101b8b:	74 24                	je     101bb1 <after_priv+0x5a>
  101b8d:	c7 44 24 0c f7 5b 10 	movl   $0x105bf7,0xc(%esp)
  101b94:	00 
  101b95:	c7 44 24 08 f6 59 10 	movl   $0x1059f6,0x8(%esp)
  101b9c:	00 
  101b9d:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
  101ba4:	00 
  101ba5:	c7 04 24 6a 5b 10 00 	movl   $0x105b6a,(%esp)
  101bac:	e8 be e8 ff ff       	call   10046f <debug_panic>
	//cprintf("sfsfsfsfsfsfsfsfsf\n");
	*argsp = NULL;	// recovery mechanism not needed anymore
  101bb1:	8b 45 08             	mov    0x8(%ebp),%eax
  101bb4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101bba:	83 c4 3c             	add    $0x3c,%esp
  101bbd:	5b                   	pop    %ebx
  101bbe:	5e                   	pop    %esi
  101bbf:	5f                   	pop    %edi
  101bc0:	5d                   	pop    %ebp
  101bc1:	c3                   	ret    

00101bc2 <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  101bc2:	6a 00                	push   $0x0
  101bc4:	6a 00                	push   $0x0
  101bc6:	e9 09 75 00 00       	jmp    1090d4 <_alltraps>
  101bcb:	90                   	nop

00101bcc <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  101bcc:	6a 00                	push   $0x0
  101bce:	6a 01                	push   $0x1
  101bd0:	e9 ff 74 00 00       	jmp    1090d4 <_alltraps>
  101bd5:	90                   	nop

00101bd6 <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  101bd6:	6a 00                	push   $0x0
  101bd8:	6a 02                	push   $0x2
  101bda:	e9 f5 74 00 00       	jmp    1090d4 <_alltraps>
  101bdf:	90                   	nop

00101be0 <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  101be0:	6a 00                	push   $0x0
  101be2:	6a 03                	push   $0x3
  101be4:	e9 eb 74 00 00       	jmp    1090d4 <_alltraps>
  101be9:	90                   	nop

00101bea <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  101bea:	6a 00                	push   $0x0
  101bec:	6a 04                	push   $0x4
  101bee:	e9 e1 74 00 00       	jmp    1090d4 <_alltraps>
  101bf3:	90                   	nop

00101bf4 <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  101bf4:	6a 00                	push   $0x0
  101bf6:	6a 05                	push   $0x5
  101bf8:	e9 d7 74 00 00       	jmp    1090d4 <_alltraps>
  101bfd:	90                   	nop

00101bfe <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  101bfe:	6a 00                	push   $0x0
  101c00:	6a 06                	push   $0x6
  101c02:	e9 cd 74 00 00       	jmp    1090d4 <_alltraps>
  101c07:	90                   	nop

00101c08 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  101c08:	6a 00                	push   $0x0
  101c0a:	6a 07                	push   $0x7
  101c0c:	e9 c3 74 00 00       	jmp    1090d4 <_alltraps>
  101c11:	90                   	nop

00101c12 <vector8>:
TRAPHANDLER(vector8, 8)
  101c12:	6a 08                	push   $0x8
  101c14:	e9 bb 74 00 00       	jmp    1090d4 <_alltraps>
  101c19:	90                   	nop

00101c1a <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  101c1a:	6a 00                	push   $0x0
  101c1c:	6a 09                	push   $0x9
  101c1e:	e9 b1 74 00 00       	jmp    1090d4 <_alltraps>
  101c23:	90                   	nop

00101c24 <vector10>:
TRAPHANDLER(vector10, 10)
  101c24:	6a 0a                	push   $0xa
  101c26:	e9 a9 74 00 00       	jmp    1090d4 <_alltraps>
  101c2b:	90                   	nop

00101c2c <vector11>:
TRAPHANDLER(vector11, 11)
  101c2c:	6a 0b                	push   $0xb
  101c2e:	e9 a1 74 00 00       	jmp    1090d4 <_alltraps>
  101c33:	90                   	nop

00101c34 <vector12>:
TRAPHANDLER(vector12, 12)
  101c34:	6a 0c                	push   $0xc
  101c36:	e9 99 74 00 00       	jmp    1090d4 <_alltraps>
  101c3b:	90                   	nop

00101c3c <vector13>:
TRAPHANDLER(vector13, 13)
  101c3c:	6a 0d                	push   $0xd
  101c3e:	e9 91 74 00 00       	jmp    1090d4 <_alltraps>
  101c43:	90                   	nop

00101c44 <vector14>:
TRAPHANDLER(vector14, 14)
  101c44:	6a 0e                	push   $0xe
  101c46:	e9 89 74 00 00       	jmp    1090d4 <_alltraps>
  101c4b:	90                   	nop

00101c4c <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101c4c:	6a 00                	push   $0x0
  101c4e:	6a 0f                	push   $0xf
  101c50:	e9 7f 74 00 00       	jmp    1090d4 <_alltraps>
  101c55:	90                   	nop

00101c56 <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  101c56:	6a 00                	push   $0x0
  101c58:	6a 10                	push   $0x10
  101c5a:	e9 75 74 00 00       	jmp    1090d4 <_alltraps>
  101c5f:	90                   	nop

00101c60 <vector17>:
TRAPHANDLER(vector17, 17)
  101c60:	6a 11                	push   $0x11
  101c62:	e9 6d 74 00 00       	jmp    1090d4 <_alltraps>
  101c67:	90                   	nop

00101c68 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  101c68:	6a 00                	push   $0x0
  101c6a:	6a 12                	push   $0x12
  101c6c:	e9 63 74 00 00       	jmp    1090d4 <_alltraps>
  101c71:	90                   	nop

00101c72 <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  101c72:	6a 00                	push   $0x0
  101c74:	6a 13                	push   $0x13
  101c76:	e9 59 74 00 00       	jmp    1090d4 <_alltraps>
  101c7b:	90                   	nop

00101c7c <vector20>:
TRAPHANDLER_NOEC(vector20, 20)
  101c7c:	6a 00                	push   $0x0
  101c7e:	6a 14                	push   $0x14
  101c80:	e9 4f 74 00 00       	jmp    1090d4 <_alltraps>
  101c85:	90                   	nop

00101c86 <vector21>:
TRAPHANDLER_NOEC(vector21, 21)
  101c86:	6a 00                	push   $0x0
  101c88:	6a 15                	push   $0x15
  101c8a:	e9 45 74 00 00       	jmp    1090d4 <_alltraps>
  101c8f:	90                   	nop

00101c90 <vector22>:
TRAPHANDLER_NOEC(vector22, 22)
  101c90:	6a 00                	push   $0x0
  101c92:	6a 16                	push   $0x16
  101c94:	e9 3b 74 00 00       	jmp    1090d4 <_alltraps>
  101c99:	90                   	nop

00101c9a <vector23>:
TRAPHANDLER_NOEC(vector23, 23)
  101c9a:	6a 00                	push   $0x0
  101c9c:	6a 17                	push   $0x17
  101c9e:	e9 31 74 00 00       	jmp    1090d4 <_alltraps>
  101ca3:	90                   	nop

00101ca4 <vector24>:
TRAPHANDLER_NOEC(vector24, 24)
  101ca4:	6a 00                	push   $0x0
  101ca6:	6a 18                	push   $0x18
  101ca8:	e9 27 74 00 00       	jmp    1090d4 <_alltraps>
  101cad:	90                   	nop

00101cae <vector25>:
TRAPHANDLER_NOEC(vector25, 25)
  101cae:	6a 00                	push   $0x0
  101cb0:	6a 19                	push   $0x19
  101cb2:	e9 1d 74 00 00       	jmp    1090d4 <_alltraps>
  101cb7:	90                   	nop

00101cb8 <vector26>:
TRAPHANDLER_NOEC(vector26, 26)
  101cb8:	6a 00                	push   $0x0
  101cba:	6a 1a                	push   $0x1a
  101cbc:	e9 13 74 00 00       	jmp    1090d4 <_alltraps>
  101cc1:	90                   	nop

00101cc2 <vector27>:
TRAPHANDLER_NOEC(vector27, 27)
  101cc2:	6a 00                	push   $0x0
  101cc4:	6a 1b                	push   $0x1b
  101cc6:	e9 09 74 00 00       	jmp    1090d4 <_alltraps>
  101ccb:	90                   	nop

00101ccc <vector28>:
TRAPHANDLER_NOEC(vector28, 28)
  101ccc:	6a 00                	push   $0x0
  101cce:	6a 1c                	push   $0x1c
  101cd0:	e9 ff 73 00 00       	jmp    1090d4 <_alltraps>
  101cd5:	90                   	nop

00101cd6 <vector29>:
TRAPHANDLER_NOEC(vector29, 29)
  101cd6:	6a 00                	push   $0x0
  101cd8:	6a 1d                	push   $0x1d
  101cda:	e9 f5 73 00 00       	jmp    1090d4 <_alltraps>
  101cdf:	90                   	nop

00101ce0 <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101ce0:	6a 00                	push   $0x0
  101ce2:	6a 1e                	push   $0x1e
  101ce4:	e9 eb 73 00 00       	jmp    1090d4 <_alltraps>
  101ce9:	90                   	nop

00101cea <vector31>:
TRAPHANDLER_NOEC(vector31, 31)
  101cea:	6a 00                	push   $0x0
  101cec:	6a 1f                	push   $0x1f
  101cee:	e9 e1 73 00 00       	jmp    1090d4 <_alltraps>
  101cf3:	90                   	nop

00101cf4 <vector32>:
TRAPHANDLER_NOEC(vector32, 32)
  101cf4:	6a 00                	push   $0x0
  101cf6:	6a 20                	push   $0x20
  101cf8:	e9 d7 73 00 00       	jmp    1090d4 <_alltraps>
  101cfd:	90                   	nop

00101cfe <vector33>:
TRAPHANDLER_NOEC(vector33, 33)
  101cfe:	6a 00                	push   $0x0
  101d00:	6a 21                	push   $0x21
  101d02:	e9 cd 73 00 00       	jmp    1090d4 <_alltraps>
  101d07:	90                   	nop

00101d08 <vector34>:
TRAPHANDLER_NOEC(vector34, 34)
  101d08:	6a 00                	push   $0x0
  101d0a:	6a 22                	push   $0x22
  101d0c:	e9 c3 73 00 00       	jmp    1090d4 <_alltraps>
  101d11:	90                   	nop

00101d12 <vector35>:
TRAPHANDLER_NOEC(vector35, 35)
  101d12:	6a 00                	push   $0x0
  101d14:	6a 23                	push   $0x23
  101d16:	e9 b9 73 00 00       	jmp    1090d4 <_alltraps>
  101d1b:	90                   	nop

00101d1c <vector36>:
TRAPHANDLER_NOEC(vector36, 36)
  101d1c:	6a 00                	push   $0x0
  101d1e:	6a 24                	push   $0x24
  101d20:	e9 af 73 00 00       	jmp    1090d4 <_alltraps>
  101d25:	90                   	nop

00101d26 <vector37>:
TRAPHANDLER_NOEC(vector37, 37)
  101d26:	6a 00                	push   $0x0
  101d28:	6a 25                	push   $0x25
  101d2a:	e9 a5 73 00 00       	jmp    1090d4 <_alltraps>
  101d2f:	90                   	nop

00101d30 <vector38>:
TRAPHANDLER_NOEC(vector38, 38)
  101d30:	6a 00                	push   $0x0
  101d32:	6a 26                	push   $0x26
  101d34:	e9 9b 73 00 00       	jmp    1090d4 <_alltraps>
  101d39:	90                   	nop

00101d3a <vector39>:
TRAPHANDLER_NOEC(vector39, 39)
  101d3a:	6a 00                	push   $0x0
  101d3c:	6a 27                	push   $0x27
  101d3e:	e9 91 73 00 00       	jmp    1090d4 <_alltraps>
  101d43:	90                   	nop

00101d44 <vector40>:
TRAPHANDLER_NOEC(vector40, 40)
  101d44:	6a 00                	push   $0x0
  101d46:	6a 28                	push   $0x28
  101d48:	e9 87 73 00 00       	jmp    1090d4 <_alltraps>
  101d4d:	90                   	nop

00101d4e <vector41>:
TRAPHANDLER_NOEC(vector41, 41)
  101d4e:	6a 00                	push   $0x0
  101d50:	6a 29                	push   $0x29
  101d52:	e9 7d 73 00 00       	jmp    1090d4 <_alltraps>
  101d57:	90                   	nop

00101d58 <vector42>:
TRAPHANDLER_NOEC(vector42, 42)
  101d58:	6a 00                	push   $0x0
  101d5a:	6a 2a                	push   $0x2a
  101d5c:	e9 73 73 00 00       	jmp    1090d4 <_alltraps>
  101d61:	90                   	nop

00101d62 <vector43>:
TRAPHANDLER_NOEC(vector43, 43)
  101d62:	6a 00                	push   $0x0
  101d64:	6a 2b                	push   $0x2b
  101d66:	e9 69 73 00 00       	jmp    1090d4 <_alltraps>
  101d6b:	90                   	nop

00101d6c <vector44>:
TRAPHANDLER_NOEC(vector44, 44)
  101d6c:	6a 00                	push   $0x0
  101d6e:	6a 2c                	push   $0x2c
  101d70:	e9 5f 73 00 00       	jmp    1090d4 <_alltraps>
  101d75:	90                   	nop

00101d76 <vector45>:
TRAPHANDLER_NOEC(vector45, 45)
  101d76:	6a 00                	push   $0x0
  101d78:	6a 2d                	push   $0x2d
  101d7a:	e9 55 73 00 00       	jmp    1090d4 <_alltraps>
  101d7f:	90                   	nop

00101d80 <vector46>:
TRAPHANDLER_NOEC(vector46, 46)
  101d80:	6a 00                	push   $0x0
  101d82:	6a 2e                	push   $0x2e
  101d84:	e9 4b 73 00 00       	jmp    1090d4 <_alltraps>
  101d89:	90                   	nop

00101d8a <vector47>:
TRAPHANDLER_NOEC(vector47, 47)
  101d8a:	6a 00                	push   $0x0
  101d8c:	6a 2f                	push   $0x2f
  101d8e:	e9 41 73 00 00       	jmp    1090d4 <_alltraps>
  101d93:	90                   	nop

00101d94 <vector48>:
TRAPHANDLER_NOEC(vector48, 48)
  101d94:	6a 00                	push   $0x0
  101d96:	6a 30                	push   $0x30
  101d98:	e9 37 73 00 00       	jmp    1090d4 <_alltraps>

00101d9d <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101d9d:	55                   	push   %ebp
  101d9e:	89 e5                	mov    %esp,%ebp
  101da0:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101da3:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101da6:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101da9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101dac:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101daf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101db4:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101db7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101dba:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101dc0:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101dc5:	74 24                	je     101deb <cpu_cur+0x4e>
  101dc7:	c7 44 24 0c 30 5e 10 	movl   $0x105e30,0xc(%esp)
  101dce:	00 
  101dcf:	c7 44 24 08 46 5e 10 	movl   $0x105e46,0x8(%esp)
  101dd6:	00 
  101dd7:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101dde:	00 
  101ddf:	c7 04 24 5b 5e 10 00 	movl   $0x105e5b,(%esp)
  101de6:	e8 84 e6 ff ff       	call   10046f <debug_panic>
	return c;
  101deb:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101dee:	c9                   	leave  
  101def:	c3                   	ret    

00101df0 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101df0:	55                   	push   %ebp
  101df1:	89 e5                	mov    %esp,%ebp
  101df3:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101df6:	e8 a2 ff ff ff       	call   101d9d <cpu_cur>
  101dfb:	3d 00 80 10 00       	cmp    $0x108000,%eax
  101e00:	0f 94 c0             	sete   %al
  101e03:	0f b6 c0             	movzbl %al,%eax
}
  101e06:	c9                   	leave  
  101e07:	c3                   	ret    

00101e08 <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  101e08:	55                   	push   %ebp
  101e09:	89 e5                	mov    %esp,%ebp
  101e0b:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  101e0e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	for (i = 0; i < len; i++)
  101e15:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  101e1c:	eb 13                	jmp    101e31 <sum+0x29>
		sum += addr[i];
  101e1e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101e21:	03 45 08             	add    0x8(%ebp),%eax
  101e24:	0f b6 00             	movzbl (%eax),%eax
  101e27:	0f b6 c0             	movzbl %al,%eax
  101e2a:	01 45 fc             	add    %eax,-0x4(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  101e2d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  101e31:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101e34:	3b 45 0c             	cmp    0xc(%ebp),%eax
  101e37:	7c e5                	jl     101e1e <sum+0x16>
		sum += addr[i];
	return sum;
  101e39:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101e3c:	c9                   	leave  
  101e3d:	c3                   	ret    

00101e3e <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  101e3e:	55                   	push   %ebp
  101e3f:	89 e5                	mov    %esp,%ebp
  101e41:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  101e44:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e47:	03 45 08             	add    0x8(%ebp),%eax
  101e4a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  101e4d:	8b 45 08             	mov    0x8(%ebp),%eax
  101e50:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101e53:	eb 3f                	jmp    101e94 <mpsearch1+0x56>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  101e55:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  101e5c:	00 
  101e5d:	c7 44 24 04 68 5e 10 	movl   $0x105e68,0x4(%esp)
  101e64:	00 
  101e65:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101e68:	89 04 24             	mov    %eax,(%esp)
  101e6b:	e8 5b 33 00 00       	call   1051cb <memcmp>
  101e70:	85 c0                	test   %eax,%eax
  101e72:	75 1c                	jne    101e90 <mpsearch1+0x52>
  101e74:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  101e7b:	00 
  101e7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101e7f:	89 04 24             	mov    %eax,(%esp)
  101e82:	e8 81 ff ff ff       	call   101e08 <sum>
  101e87:	84 c0                	test   %al,%al
  101e89:	75 05                	jne    101e90 <mpsearch1+0x52>
			return (struct mp *) p;
  101e8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101e8e:	eb 11                	jmp    101ea1 <mpsearch1+0x63>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  101e90:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  101e94:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101e97:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  101e9a:	72 b9                	jb     101e55 <mpsearch1+0x17>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  101e9c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  101ea1:	c9                   	leave  
  101ea2:	c3                   	ret    

00101ea3 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  101ea3:	55                   	push   %ebp
  101ea4:	89 e5                	mov    %esp,%ebp
  101ea6:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  101ea9:	c7 45 ec 00 04 00 00 	movl   $0x400,-0x14(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  101eb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101eb3:	83 c0 0f             	add    $0xf,%eax
  101eb6:	0f b6 00             	movzbl (%eax),%eax
  101eb9:	0f b6 c0             	movzbl %al,%eax
  101ebc:	89 c2                	mov    %eax,%edx
  101ebe:	c1 e2 08             	shl    $0x8,%edx
  101ec1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101ec4:	83 c0 0e             	add    $0xe,%eax
  101ec7:	0f b6 00             	movzbl (%eax),%eax
  101eca:	0f b6 c0             	movzbl %al,%eax
  101ecd:	09 d0                	or     %edx,%eax
  101ecf:	c1 e0 04             	shl    $0x4,%eax
  101ed2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101ed5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101ed9:	74 21                	je     101efc <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  101edb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101ede:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  101ee5:	00 
  101ee6:	89 04 24             	mov    %eax,(%esp)
  101ee9:	e8 50 ff ff ff       	call   101e3e <mpsearch1>
  101eee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101ef1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101ef5:	74 50                	je     101f47 <mpsearch+0xa4>
			return mp;
  101ef7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101efa:	eb 5f                	jmp    101f5b <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  101efc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101eff:	83 c0 14             	add    $0x14,%eax
  101f02:	0f b6 00             	movzbl (%eax),%eax
  101f05:	0f b6 c0             	movzbl %al,%eax
  101f08:	89 c2                	mov    %eax,%edx
  101f0a:	c1 e2 08             	shl    $0x8,%edx
  101f0d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101f10:	83 c0 13             	add    $0x13,%eax
  101f13:	0f b6 00             	movzbl (%eax),%eax
  101f16:	0f b6 c0             	movzbl %al,%eax
  101f19:	09 d0                	or     %edx,%eax
  101f1b:	c1 e0 0a             	shl    $0xa,%eax
  101f1e:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  101f21:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f24:	2d 00 04 00 00       	sub    $0x400,%eax
  101f29:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  101f30:	00 
  101f31:	89 04 24             	mov    %eax,(%esp)
  101f34:	e8 05 ff ff ff       	call   101e3e <mpsearch1>
  101f39:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101f3c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101f40:	74 05                	je     101f47 <mpsearch+0xa4>
			return mp;
  101f42:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f45:	eb 14                	jmp    101f5b <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  101f47:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  101f4e:	00 
  101f4f:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  101f56:	e8 e3 fe ff ff       	call   101e3e <mpsearch1>
}
  101f5b:	c9                   	leave  
  101f5c:	c3                   	ret    

00101f5d <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  101f5d:	55                   	push   %ebp
  101f5e:	89 e5                	mov    %esp,%ebp
  101f60:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  101f63:	e8 3b ff ff ff       	call   101ea3 <mpsearch>
  101f68:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101f6b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101f6f:	74 0a                	je     101f7b <mpconfig+0x1e>
  101f71:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f74:	8b 40 04             	mov    0x4(%eax),%eax
  101f77:	85 c0                	test   %eax,%eax
  101f79:	75 07                	jne    101f82 <mpconfig+0x25>
		return 0;
  101f7b:	b8 00 00 00 00       	mov    $0x0,%eax
  101f80:	eb 7b                	jmp    101ffd <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  101f82:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f85:	8b 40 04             	mov    0x4(%eax),%eax
  101f88:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  101f8b:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  101f92:	00 
  101f93:	c7 44 24 04 6d 5e 10 	movl   $0x105e6d,0x4(%esp)
  101f9a:	00 
  101f9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f9e:	89 04 24             	mov    %eax,(%esp)
  101fa1:	e8 25 32 00 00       	call   1051cb <memcmp>
  101fa6:	85 c0                	test   %eax,%eax
  101fa8:	74 07                	je     101fb1 <mpconfig+0x54>
		return 0;
  101faa:	b8 00 00 00 00       	mov    $0x0,%eax
  101faf:	eb 4c                	jmp    101ffd <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  101fb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fb4:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  101fb8:	3c 01                	cmp    $0x1,%al
  101fba:	74 12                	je     101fce <mpconfig+0x71>
  101fbc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fbf:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  101fc3:	3c 04                	cmp    $0x4,%al
  101fc5:	74 07                	je     101fce <mpconfig+0x71>
		return 0;
  101fc7:	b8 00 00 00 00       	mov    $0x0,%eax
  101fcc:	eb 2f                	jmp    101ffd <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  101fce:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fd1:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  101fd5:	0f b7 d0             	movzwl %ax,%edx
  101fd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fdb:	89 54 24 04          	mov    %edx,0x4(%esp)
  101fdf:	89 04 24             	mov    %eax,(%esp)
  101fe2:	e8 21 fe ff ff       	call   101e08 <sum>
  101fe7:	84 c0                	test   %al,%al
  101fe9:	74 07                	je     101ff2 <mpconfig+0x95>
		return 0;
  101feb:	b8 00 00 00 00       	mov    $0x0,%eax
  101ff0:	eb 0b                	jmp    101ffd <mpconfig+0xa0>
       *pmp = mp;
  101ff2:	8b 45 08             	mov    0x8(%ebp),%eax
  101ff5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101ff8:	89 10                	mov    %edx,(%eax)
	return conf;
  101ffa:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  101ffd:	c9                   	leave  
  101ffe:	c3                   	ret    

00101fff <mp_init>:

void
mp_init(void)
{
  101fff:	55                   	push   %ebp
  102000:	89 e5                	mov    %esp,%ebp
  102002:	83 ec 48             	sub    $0x48,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  102005:	e8 e6 fd ff ff       	call   101df0 <cpu_onboot>
  10200a:	85 c0                	test   %eax,%eax
  10200c:	0f 84 72 01 00 00    	je     102184 <mp_init+0x185>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  102012:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102015:	89 04 24             	mov    %eax,(%esp)
  102018:	e8 40 ff ff ff       	call   101f5d <mpconfig>
  10201d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  102020:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  102024:	0f 84 5d 01 00 00    	je     102187 <mp_init+0x188>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  10202a:	c7 05 e4 f3 30 00 01 	movl   $0x1,0x30f3e4
  102031:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  102034:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102037:	8b 40 24             	mov    0x24(%eax),%eax
  10203a:	a3 ec fa 30 00       	mov    %eax,0x30faec
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  10203f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102042:	83 c0 2c             	add    $0x2c,%eax
  102045:	89 45 cc             	mov    %eax,-0x34(%ebp)
  102048:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10204b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10204e:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  102052:	0f b7 c0             	movzwl %ax,%eax
  102055:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102058:	89 45 d0             	mov    %eax,-0x30(%ebp)
  10205b:	e9 cc 00 00 00       	jmp    10212c <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  102060:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102063:	0f b6 00             	movzbl (%eax),%eax
  102066:	0f b6 c0             	movzbl %al,%eax
  102069:	83 f8 04             	cmp    $0x4,%eax
  10206c:	0f 87 90 00 00 00    	ja     102102 <mp_init+0x103>
  102072:	8b 04 85 a0 5e 10 00 	mov    0x105ea0(,%eax,4),%eax
  102079:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  10207b:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10207e:	89 45 d8             	mov    %eax,-0x28(%ebp)
			p += sizeof(struct mpproc);
  102081:	83 45 cc 14          	addl   $0x14,-0x34(%ebp)
			if (!(proc->flags & MPENAB))
  102085:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102088:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  10208c:	0f b6 c0             	movzbl %al,%eax
  10208f:	83 e0 01             	and    $0x1,%eax
  102092:	85 c0                	test   %eax,%eax
  102094:	0f 84 91 00 00 00    	je     10212b <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  10209a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10209d:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  1020a1:	0f b6 c0             	movzbl %al,%eax
  1020a4:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  1020a7:	85 c0                	test   %eax,%eax
  1020a9:	75 07                	jne    1020b2 <mp_init+0xb3>
  1020ab:	e8 63 f1 ff ff       	call   101213 <cpu_alloc>
  1020b0:	eb 05                	jmp    1020b7 <mp_init+0xb8>
  1020b2:	b8 00 80 10 00       	mov    $0x108000,%eax
  1020b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
			c->id = proc->apicid;
  1020ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1020bd:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  1020c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1020c4:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  1020ca:	a1 e8 f3 30 00       	mov    0x30f3e8,%eax
  1020cf:	83 c0 01             	add    $0x1,%eax
  1020d2:	a3 e8 f3 30 00       	mov    %eax,0x30f3e8
			continue;
  1020d7:	eb 53                	jmp    10212c <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  1020d9:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1020dc:	89 45 dc             	mov    %eax,-0x24(%ebp)
			p += sizeof(struct mpioapic);
  1020df:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			ioapicid = mpio->apicno;
  1020e3:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1020e6:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  1020ea:	a2 dc f3 30 00       	mov    %al,0x30f3dc
			ioapic = (struct ioapic *) mpio->addr;
  1020ef:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1020f2:	8b 40 04             	mov    0x4(%eax),%eax
  1020f5:	a3 e0 f3 30 00       	mov    %eax,0x30f3e0
			continue;
  1020fa:	eb 30                	jmp    10212c <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  1020fc:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			continue;
  102100:	eb 2a                	jmp    10212c <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  102102:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102105:	0f b6 00             	movzbl (%eax),%eax
  102108:	0f b6 c0             	movzbl %al,%eax
  10210b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10210f:	c7 44 24 08 74 5e 10 	movl   $0x105e74,0x8(%esp)
  102116:	00 
  102117:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  10211e:	00 
  10211f:	c7 04 24 94 5e 10 00 	movl   $0x105e94,(%esp)
  102126:	e8 44 e3 ff ff       	call   10046f <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  10212b:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  10212c:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10212f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102132:	0f 82 28 ff ff ff    	jb     102060 <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  102138:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10213b:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  10213f:	84 c0                	test   %al,%al
  102141:	74 45                	je     102188 <mp_init+0x189>
  102143:	c7 45 e8 22 00 00 00 	movl   $0x22,-0x18(%ebp)
  10214a:	c6 45 e7 70          	movb   $0x70,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10214e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  102152:	8b 55 e8             	mov    -0x18(%ebp),%edx
  102155:	ee                   	out    %al,(%dx)
  102156:	c7 45 ec 23 00 00 00 	movl   $0x23,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10215d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102160:	89 c2                	mov    %eax,%edx
  102162:	ec                   	in     (%dx),%al
  102163:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  102166:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  10216a:	83 c8 01             	or     $0x1,%eax
  10216d:	0f b6 c0             	movzbl %al,%eax
  102170:	c7 45 f4 23 00 00 00 	movl   $0x23,-0xc(%ebp)
  102177:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10217a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10217e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102181:	ee                   	out    %al,(%dx)
  102182:	eb 04                	jmp    102188 <mp_init+0x189>
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  102184:	90                   	nop
  102185:	eb 01                	jmp    102188 <mp_init+0x189>

	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.
  102187:	90                   	nop
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
	}
}
  102188:	c9                   	leave  
  102189:	c3                   	ret    

0010218a <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10218a:	55                   	push   %ebp
  10218b:	89 e5                	mov    %esp,%ebp
  10218d:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102190:	8b 55 08             	mov    0x8(%ebp),%edx
  102193:	8b 45 0c             	mov    0xc(%ebp),%eax
  102196:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102199:	f0 87 02             	lock xchg %eax,(%edx)
  10219c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  10219f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1021a2:	c9                   	leave  
  1021a3:	c3                   	ret    

001021a4 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1021a4:	55                   	push   %ebp
  1021a5:	89 e5                	mov    %esp,%ebp
  1021a7:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1021aa:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1021ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1021b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1021b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1021b6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1021bb:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1021be:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1021c1:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1021c7:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1021cc:	74 24                	je     1021f2 <cpu_cur+0x4e>
  1021ce:	c7 44 24 0c b4 5e 10 	movl   $0x105eb4,0xc(%esp)
  1021d5:	00 
  1021d6:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  1021dd:	00 
  1021de:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1021e5:	00 
  1021e6:	c7 04 24 df 5e 10 00 	movl   $0x105edf,(%esp)
  1021ed:	e8 7d e2 ff ff       	call   10046f <debug_panic>
	return c;
  1021f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1021f5:	c9                   	leave  
  1021f6:	c3                   	ret    

001021f7 <spinlock_init_>:
#include <kern/cons.h>


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  1021f7:	55                   	push   %ebp
  1021f8:	89 e5                	mov    %esp,%ebp
	lk->locked = 0;
  1021fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1021fd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->file = file;
  102203:	8b 45 08             	mov    0x8(%ebp),%eax
  102206:	8b 55 0c             	mov    0xc(%ebp),%edx
  102209:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  10220c:	8b 45 08             	mov    0x8(%ebp),%eax
  10220f:	8b 55 10             	mov    0x10(%ebp),%edx
  102212:	89 50 08             	mov    %edx,0x8(%eax)
	lk->cpu = NULL;
  102215:	8b 45 08             	mov    0x8(%ebp),%eax
  102218:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	lk->eips[0] = 0;
  10221f:	8b 45 08             	mov    0x8(%ebp),%eax
  102222:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
}
  102229:	5d                   	pop    %ebp
  10222a:	c3                   	ret    

0010222b <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  10222b:	55                   	push   %ebp
  10222c:	89 e5                	mov    %esp,%ebp
  10222e:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in sa\n");

	if(spinlock_holding(lk))
  102231:	8b 45 08             	mov    0x8(%ebp),%eax
  102234:	89 04 24             	mov    %eax,(%esp)
  102237:	e8 c5 00 00 00       	call   102301 <spinlock_holding>
  10223c:	85 c0                	test   %eax,%eax
  10223e:	74 2a                	je     10226a <spinlock_acquire+0x3f>
		panic("acquire");
  102240:	c7 44 24 08 ec 5e 10 	movl   $0x105eec,0x8(%esp)
  102247:	00 
  102248:	c7 44 24 04 27 00 00 	movl   $0x27,0x4(%esp)
  10224f:	00 
  102250:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  102257:	e8 13 e2 ff ff       	call   10046f <debug_panic>

	while(xchg(&lk->locked, 1) !=0)
		{cprintf("in xchg\n")
  10225c:	c7 04 24 04 5f 10 00 	movl   $0x105f04,(%esp)
  102263:	e8 0e 2c 00 00       	call   104e76 <cprintf>
  102268:	eb 01                	jmp    10226b <spinlock_acquire+0x40>
	//cprintf("in sa\n");

	if(spinlock_holding(lk))
		panic("acquire");

	while(xchg(&lk->locked, 1) !=0)
  10226a:	90                   	nop
  10226b:	8b 45 08             	mov    0x8(%ebp),%eax
  10226e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102275:	00 
  102276:	89 04 24             	mov    %eax,(%esp)
  102279:	e8 0c ff ff ff       	call   10218a <xchg>
  10227e:	85 c0                	test   %eax,%eax
  102280:	75 da                	jne    10225c <spinlock_acquire+0x31>
		{cprintf("in xchg\n")
		;}

	lk->cpu = cpu_cur();
  102282:	e8 1d ff ff ff       	call   1021a4 <cpu_cur>
  102287:	8b 55 08             	mov    0x8(%ebp),%edx
  10228a:	89 42 0c             	mov    %eax,0xc(%edx)

	//cprintf("before dt\n");
	debug_trace(read_ebp(), lk->eips);
  10228d:	8b 45 08             	mov    0x8(%ebp),%eax
  102290:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  102293:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  102296:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102299:	89 54 24 04          	mov    %edx,0x4(%esp)
  10229d:	89 04 24             	mov    %eax,(%esp)
  1022a0:	e8 d2 e2 ff ff       	call   100577 <debug_trace>
	//cprintf("after dt\n");

	//cprintf("after sa\n");
}
  1022a5:	c9                   	leave  
  1022a6:	c3                   	ret    

001022a7 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  1022a7:	55                   	push   %ebp
  1022a8:	89 e5                	mov    %esp,%ebp
  1022aa:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk))
  1022ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1022b0:	89 04 24             	mov    %eax,(%esp)
  1022b3:	e8 49 00 00 00       	call   102301 <spinlock_holding>
  1022b8:	85 c0                	test   %eax,%eax
  1022ba:	75 1c                	jne    1022d8 <spinlock_release+0x31>
		panic("release");
  1022bc:	c7 44 24 08 0d 5f 10 	movl   $0x105f0d,0x8(%esp)
  1022c3:	00 
  1022c4:	c7 44 24 04 3b 00 00 	movl   $0x3b,0x4(%esp)
  1022cb:	00 
  1022cc:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  1022d3:	e8 97 e1 ff ff       	call   10046f <debug_panic>

	lk->cpu = NULL;
  1022d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1022db:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	xchg(&lk->locked, 0);
  1022e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1022e5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1022ec:	00 
  1022ed:	89 04 24             	mov    %eax,(%esp)
  1022f0:	e8 95 fe ff ff       	call   10218a <xchg>

	lk->eips[0] = 0;
  1022f5:	8b 45 08             	mov    0x8(%ebp),%eax
  1022f8:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
}
  1022ff:	c9                   	leave  
  102300:	c3                   	ret    

00102301 <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  102301:	55                   	push   %ebp
  102302:	89 e5                	mov    %esp,%ebp
  102304:	53                   	push   %ebx
  102305:	83 ec 04             	sub    $0x4,%esp
	return (lock->cpu == cpu_cur()) && (lock->locked);
  102308:	8b 45 08             	mov    0x8(%ebp),%eax
  10230b:	8b 58 0c             	mov    0xc(%eax),%ebx
  10230e:	e8 91 fe ff ff       	call   1021a4 <cpu_cur>
  102313:	39 c3                	cmp    %eax,%ebx
  102315:	75 10                	jne    102327 <spinlock_holding+0x26>
  102317:	8b 45 08             	mov    0x8(%ebp),%eax
  10231a:	8b 00                	mov    (%eax),%eax
  10231c:	85 c0                	test   %eax,%eax
  10231e:	74 07                	je     102327 <spinlock_holding+0x26>
  102320:	b8 01 00 00 00       	mov    $0x1,%eax
  102325:	eb 05                	jmp    10232c <spinlock_holding+0x2b>
  102327:	b8 00 00 00 00       	mov    $0x0,%eax
	//panic("spinlock_holding() not implemented");
}
  10232c:	83 c4 04             	add    $0x4,%esp
  10232f:	5b                   	pop    %ebx
  102330:	5d                   	pop    %ebp
  102331:	c3                   	ret    

00102332 <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  102332:	55                   	push   %ebp
  102333:	89 e5                	mov    %esp,%ebp
  102335:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  102338:	8b 45 08             	mov    0x8(%ebp),%eax
  10233b:	85 c0                	test   %eax,%eax
  10233d:	75 12                	jne    102351 <spinlock_godeep+0x1f>
  10233f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102342:	89 04 24             	mov    %eax,(%esp)
  102345:	e8 e1 fe ff ff       	call   10222b <spinlock_acquire>
  10234a:	b8 01 00 00 00       	mov    $0x1,%eax
  10234f:	eb 1b                	jmp    10236c <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  102351:	8b 45 08             	mov    0x8(%ebp),%eax
  102354:	8d 50 ff             	lea    -0x1(%eax),%edx
  102357:	8b 45 0c             	mov    0xc(%ebp),%eax
  10235a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10235e:	89 14 24             	mov    %edx,(%esp)
  102361:	e8 cc ff ff ff       	call   102332 <spinlock_godeep>
  102366:	8b 55 08             	mov    0x8(%ebp),%edx
  102369:	0f af c2             	imul   %edx,%eax
}
  10236c:	c9                   	leave  
  10236d:	c3                   	ret    

0010236e <spinlock_check>:



void spinlock_check()
{
  10236e:	55                   	push   %ebp
  10236f:	89 e5                	mov    %esp,%ebp
  102371:	57                   	push   %edi
  102372:	56                   	push   %esi
  102373:	53                   	push   %ebx
  102374:	83 ec 5c             	sub    $0x5c,%esp
  102377:	89 e0                	mov    %esp,%eax
  102379:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	const int NUMLOCKS=10;
  10237c:	c7 45 d0 0a 00 00 00 	movl   $0xa,-0x30(%ebp)
	const int NUMRUNS=5;
  102383:	c7 45 d4 05 00 00 00 	movl   $0x5,-0x2c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  10238a:	c7 45 e4 15 5f 10 00 	movl   $0x105f15,-0x1c(%ebp)
	spinlock locks[NUMLOCKS];
  102391:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102394:	83 e8 01             	sub    $0x1,%eax
  102397:	89 45 c8             	mov    %eax,-0x38(%ebp)
  10239a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10239d:	ba 00 00 00 00       	mov    $0x0,%edx
  1023a2:	89 c1                	mov    %eax,%ecx
  1023a4:	80 e5 ff             	and    $0xff,%ch
  1023a7:	89 d3                	mov    %edx,%ebx
  1023a9:	83 e3 0f             	and    $0xf,%ebx
  1023ac:	89 c8                	mov    %ecx,%eax
  1023ae:	89 da                	mov    %ebx,%edx
  1023b0:	69 da c0 01 00 00    	imul   $0x1c0,%edx,%ebx
  1023b6:	6b c8 00             	imul   $0x0,%eax,%ecx
  1023b9:	01 cb                	add    %ecx,%ebx
  1023bb:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  1023c0:	f7 e1                	mul    %ecx
  1023c2:	01 d3                	add    %edx,%ebx
  1023c4:	89 da                	mov    %ebx,%edx
  1023c6:	89 c6                	mov    %eax,%esi
  1023c8:	83 e6 ff             	and    $0xffffffff,%esi
  1023cb:	89 d7                	mov    %edx,%edi
  1023cd:	83 e7 0f             	and    $0xf,%edi
  1023d0:	89 f0                	mov    %esi,%eax
  1023d2:	89 fa                	mov    %edi,%edx
  1023d4:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1023d7:	c1 e0 03             	shl    $0x3,%eax
  1023da:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1023dd:	ba 00 00 00 00       	mov    $0x0,%edx
  1023e2:	89 c1                	mov    %eax,%ecx
  1023e4:	80 e5 ff             	and    $0xff,%ch
  1023e7:	89 4d b8             	mov    %ecx,-0x48(%ebp)
  1023ea:	89 d3                	mov    %edx,%ebx
  1023ec:	83 e3 0f             	and    $0xf,%ebx
  1023ef:	89 5d bc             	mov    %ebx,-0x44(%ebp)
  1023f2:	8b 45 b8             	mov    -0x48(%ebp),%eax
  1023f5:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1023f8:	69 ca c0 01 00 00    	imul   $0x1c0,%edx,%ecx
  1023fe:	6b d8 00             	imul   $0x0,%eax,%ebx
  102401:	01 d9                	add    %ebx,%ecx
  102403:	bb c0 01 00 00       	mov    $0x1c0,%ebx
  102408:	f7 e3                	mul    %ebx
  10240a:	01 d1                	add    %edx,%ecx
  10240c:	89 ca                	mov    %ecx,%edx
  10240e:	89 c1                	mov    %eax,%ecx
  102410:	80 e5 ff             	and    $0xff,%ch
  102413:	89 4d b0             	mov    %ecx,-0x50(%ebp)
  102416:	89 d3                	mov    %edx,%ebx
  102418:	83 e3 0f             	and    $0xf,%ebx
  10241b:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
  10241e:	8b 45 b0             	mov    -0x50(%ebp),%eax
  102421:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102424:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102427:	c1 e0 03             	shl    $0x3,%eax
  10242a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102431:	89 d1                	mov    %edx,%ecx
  102433:	29 c1                	sub    %eax,%ecx
  102435:	89 c8                	mov    %ecx,%eax
  102437:	83 c0 0f             	add    $0xf,%eax
  10243a:	83 c0 0f             	add    $0xf,%eax
  10243d:	c1 e8 04             	shr    $0x4,%eax
  102440:	c1 e0 04             	shl    $0x4,%eax
  102443:	29 c4                	sub    %eax,%esp
  102445:	8d 44 24 10          	lea    0x10(%esp),%eax
  102449:	83 c0 0f             	add    $0xf,%eax
  10244c:	c1 e8 04             	shr    $0x4,%eax
  10244f:	c1 e0 04             	shl    $0x4,%eax
  102452:	89 45 cc             	mov    %eax,-0x34(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  102455:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10245c:	eb 33                	jmp    102491 <spinlock_check+0x123>
  10245e:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102461:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102464:	c1 e0 03             	shl    $0x3,%eax
  102467:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  10246e:	89 cb                	mov    %ecx,%ebx
  102470:	29 c3                	sub    %eax,%ebx
  102472:	89 d8                	mov    %ebx,%eax
  102474:	01 c2                	add    %eax,%edx
  102476:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10247d:	00 
  10247e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102481:	89 44 24 04          	mov    %eax,0x4(%esp)
  102485:	89 14 24             	mov    %edx,(%esp)
  102488:	e8 6a fd ff ff       	call   1021f7 <spinlock_init_>
  10248d:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102491:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102494:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102497:	7c c5                	jl     10245e <spinlock_check+0xf0>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  102499:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1024a0:	eb 46                	jmp    1024e8 <spinlock_check+0x17a>
  1024a2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1024a5:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1024a8:	c1 e0 03             	shl    $0x3,%eax
  1024ab:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1024b2:	29 c2                	sub    %eax,%edx
  1024b4:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1024b7:	83 c0 0c             	add    $0xc,%eax
  1024ba:	8b 00                	mov    (%eax),%eax
  1024bc:	85 c0                	test   %eax,%eax
  1024be:	74 24                	je     1024e4 <spinlock_check+0x176>
  1024c0:	c7 44 24 0c 24 5f 10 	movl   $0x105f24,0xc(%esp)
  1024c7:	00 
  1024c8:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  1024cf:	00 
  1024d0:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  1024d7:	00 
  1024d8:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  1024df:	e8 8b df ff ff       	call   10046f <debug_panic>
  1024e4:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1024e8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1024eb:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1024ee:	7c b2                	jl     1024a2 <spinlock_check+0x134>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  1024f0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1024f7:	eb 47                	jmp    102540 <spinlock_check+0x1d2>
  1024f9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1024fc:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1024ff:	c1 e0 03             	shl    $0x3,%eax
  102502:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102509:	29 c2                	sub    %eax,%edx
  10250b:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  10250e:	83 c0 04             	add    $0x4,%eax
  102511:	8b 00                	mov    (%eax),%eax
  102513:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  102516:	74 24                	je     10253c <spinlock_check+0x1ce>
  102518:	c7 44 24 0c 37 5f 10 	movl   $0x105f37,0xc(%esp)
  10251f:	00 
  102520:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  102527:	00 
  102528:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  10252f:	00 
  102530:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  102537:	e8 33 df ff ff       	call   10046f <debug_panic>
  10253c:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102540:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102543:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102546:	7c b1                	jl     1024f9 <spinlock_check+0x18b>

	for (run=0;run<NUMRUNS;run++) 
  102548:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  10254f:	e9 25 03 00 00       	jmp    102879 <spinlock_check+0x50b>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  102554:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10255b:	eb 3f                	jmp    10259c <spinlock_check+0x22e>
		{
			cprintf("%d\n", i);
  10255d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102560:	89 44 24 04          	mov    %eax,0x4(%esp)
  102564:	c7 04 24 4b 5f 10 00 	movl   $0x105f4b,(%esp)
  10256b:	e8 06 29 00 00       	call   104e76 <cprintf>
			spinlock_godeep(i, &locks[i]);
  102570:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102573:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102576:	c1 e0 03             	shl    $0x3,%eax
  102579:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102580:	89 cb                	mov    %ecx,%ebx
  102582:	29 c3                	sub    %eax,%ebx
  102584:	89 d8                	mov    %ebx,%eax
  102586:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102589:	89 44 24 04          	mov    %eax,0x4(%esp)
  10258d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102590:	89 04 24             	mov    %eax,(%esp)
  102593:	e8 9a fd ff ff       	call   102332 <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  102598:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10259c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10259f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1025a2:	7c b9                	jl     10255d <spinlock_check+0x1ef>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  1025a4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1025ab:	eb 4b                	jmp    1025f8 <spinlock_check+0x28a>
			assert(locks[i].cpu == cpu_cur());
  1025ad:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025b0:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1025b3:	c1 e0 03             	shl    $0x3,%eax
  1025b6:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1025bd:	29 c2                	sub    %eax,%edx
  1025bf:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1025c2:	83 c0 0c             	add    $0xc,%eax
  1025c5:	8b 18                	mov    (%eax),%ebx
  1025c7:	e8 d8 fb ff ff       	call   1021a4 <cpu_cur>
  1025cc:	39 c3                	cmp    %eax,%ebx
  1025ce:	74 24                	je     1025f4 <spinlock_check+0x286>
  1025d0:	c7 44 24 0c 4f 5f 10 	movl   $0x105f4f,0xc(%esp)
  1025d7:	00 
  1025d8:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  1025df:	00 
  1025e0:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  1025e7:	00 
  1025e8:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  1025ef:	e8 7b de ff ff       	call   10046f <debug_panic>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  1025f4:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1025f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025fb:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1025fe:	7c ad                	jl     1025ad <spinlock_check+0x23f>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102600:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102607:	eb 4d                	jmp    102656 <spinlock_check+0x2e8>
			assert(spinlock_holding(&locks[i]) != 0);
  102609:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10260c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10260f:	c1 e0 03             	shl    $0x3,%eax
  102612:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102619:	89 cb                	mov    %ecx,%ebx
  10261b:	29 c3                	sub    %eax,%ebx
  10261d:	89 d8                	mov    %ebx,%eax
  10261f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102622:	89 04 24             	mov    %eax,(%esp)
  102625:	e8 d7 fc ff ff       	call   102301 <spinlock_holding>
  10262a:	85 c0                	test   %eax,%eax
  10262c:	75 24                	jne    102652 <spinlock_check+0x2e4>
  10262e:	c7 44 24 0c 6c 5f 10 	movl   $0x105f6c,0xc(%esp)
  102635:	00 
  102636:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  10263d:	00 
  10263e:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  102645:	00 
  102646:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  10264d:	e8 1d de ff ff       	call   10046f <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102652:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102656:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102659:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10265c:	7c ab                	jl     102609 <spinlock_check+0x29b>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  10265e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102665:	e9 bd 00 00 00       	jmp    102727 <spinlock_check+0x3b9>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  10266a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102671:	e9 9b 00 00 00       	jmp    102711 <spinlock_check+0x3a3>
			{
				assert(locks[i].eips[j] >=
  102676:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102679:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  10267c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10267f:	01 c0                	add    %eax,%eax
  102681:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102688:	29 c2                	sub    %eax,%edx
  10268a:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  10268d:	83 c0 04             	add    $0x4,%eax
  102690:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  102693:	b8 32 23 10 00       	mov    $0x102332,%eax
  102698:	39 c2                	cmp    %eax,%edx
  10269a:	73 24                	jae    1026c0 <spinlock_check+0x352>
  10269c:	c7 44 24 0c 90 5f 10 	movl   $0x105f90,0xc(%esp)
  1026a3:	00 
  1026a4:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  1026ab:	00 
  1026ac:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  1026b3:	00 
  1026b4:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  1026bb:	e8 af dd ff ff       	call   10046f <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  1026c0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1026c3:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  1026c6:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1026c9:	01 c0                	add    %eax,%eax
  1026cb:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1026d2:	29 c2                	sub    %eax,%edx
  1026d4:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  1026d7:	83 c0 04             	add    $0x4,%eax
  1026da:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  1026dd:	ba 32 23 10 00       	mov    $0x102332,%edx
  1026e2:	83 c2 64             	add    $0x64,%edx
  1026e5:	39 d0                	cmp    %edx,%eax
  1026e7:	72 24                	jb     10270d <spinlock_check+0x39f>
  1026e9:	c7 44 24 0c c0 5f 10 	movl   $0x105fc0,0xc(%esp)
  1026f0:	00 
  1026f1:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  1026f8:	00 
  1026f9:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  102700:	00 
  102701:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  102708:	e8 62 dd ff ff       	call   10046f <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  10270d:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  102711:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102714:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  102717:	7f 0a                	jg     102723 <spinlock_check+0x3b5>
  102719:	83 7d dc 09          	cmpl   $0x9,-0x24(%ebp)
  10271d:	0f 8e 53 ff ff ff    	jle    102676 <spinlock_check+0x308>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  102723:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102727:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10272a:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10272d:	0f 8c 37 ff ff ff    	jl     10266a <spinlock_check+0x2fc>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  102733:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10273a:	eb 25                	jmp    102761 <spinlock_check+0x3f3>
  10273c:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10273f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102742:	c1 e0 03             	shl    $0x3,%eax
  102745:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  10274c:	89 cb                	mov    %ecx,%ebx
  10274e:	29 c3                	sub    %eax,%ebx
  102750:	89 d8                	mov    %ebx,%eax
  102752:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102755:	89 04 24             	mov    %eax,(%esp)
  102758:	e8 4a fb ff ff       	call   1022a7 <spinlock_release>
  10275d:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102761:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102764:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102767:	7c d3                	jl     10273c <spinlock_check+0x3ce>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  102769:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102770:	eb 46                	jmp    1027b8 <spinlock_check+0x44a>
  102772:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102775:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102778:	c1 e0 03             	shl    $0x3,%eax
  10277b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102782:	29 c2                	sub    %eax,%edx
  102784:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  102787:	83 c0 0c             	add    $0xc,%eax
  10278a:	8b 00                	mov    (%eax),%eax
  10278c:	85 c0                	test   %eax,%eax
  10278e:	74 24                	je     1027b4 <spinlock_check+0x446>
  102790:	c7 44 24 0c f1 5f 10 	movl   $0x105ff1,0xc(%esp)
  102797:	00 
  102798:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  10279f:	00 
  1027a0:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  1027a7:	00 
  1027a8:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  1027af:	e8 bb dc ff ff       	call   10046f <debug_panic>
  1027b4:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1027b8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1027bb:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1027be:	7c b2                	jl     102772 <spinlock_check+0x404>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  1027c0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1027c7:	eb 46                	jmp    10280f <spinlock_check+0x4a1>
  1027c9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1027cc:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1027cf:	c1 e0 03             	shl    $0x3,%eax
  1027d2:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1027d9:	29 c2                	sub    %eax,%edx
  1027db:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1027de:	83 c0 10             	add    $0x10,%eax
  1027e1:	8b 00                	mov    (%eax),%eax
  1027e3:	85 c0                	test   %eax,%eax
  1027e5:	74 24                	je     10280b <spinlock_check+0x49d>
  1027e7:	c7 44 24 0c 06 60 10 	movl   $0x106006,0xc(%esp)
  1027ee:	00 
  1027ef:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  1027f6:	00 
  1027f7:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
  1027fe:	00 
  1027ff:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  102806:	e8 64 dc ff ff       	call   10046f <debug_panic>
  10280b:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10280f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102812:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102815:	7c b2                	jl     1027c9 <spinlock_check+0x45b>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  102817:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10281e:	eb 4d                	jmp    10286d <spinlock_check+0x4ff>
  102820:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102823:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102826:	c1 e0 03             	shl    $0x3,%eax
  102829:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102830:	89 cb                	mov    %ecx,%ebx
  102832:	29 c3                	sub    %eax,%ebx
  102834:	89 d8                	mov    %ebx,%eax
  102836:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102839:	89 04 24             	mov    %eax,(%esp)
  10283c:	e8 c0 fa ff ff       	call   102301 <spinlock_holding>
  102841:	85 c0                	test   %eax,%eax
  102843:	74 24                	je     102869 <spinlock_check+0x4fb>
  102845:	c7 44 24 0c 1c 60 10 	movl   $0x10601c,0xc(%esp)
  10284c:	00 
  10284d:	c7 44 24 08 ca 5e 10 	movl   $0x105eca,0x8(%esp)
  102854:	00 
  102855:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  10285c:	00 
  10285d:	c7 04 24 f4 5e 10 00 	movl   $0x105ef4,(%esp)
  102864:	e8 06 dc ff ff       	call   10046f <debug_panic>
  102869:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10286d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102870:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102873:	7c ab                	jl     102820 <spinlock_check+0x4b2>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  102875:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  102879:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10287c:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  10287f:	0f 8c cf fc ff ff    	jl     102554 <spinlock_check+0x1e6>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  102885:	c7 04 24 3d 60 10 00 	movl   $0x10603d,(%esp)
  10288c:	e8 e5 25 00 00       	call   104e76 <cprintf>
  102891:	8b 65 c4             	mov    -0x3c(%ebp),%esp
}
  102894:	8d 65 f4             	lea    -0xc(%ebp),%esp
  102897:	83 c4 00             	add    $0x0,%esp
  10289a:	5b                   	pop    %ebx
  10289b:	5e                   	pop    %esi
  10289c:	5f                   	pop    %edi
  10289d:	5d                   	pop    %ebp
  10289e:	c3                   	ret    

0010289f <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10289f:	55                   	push   %ebp
  1028a0:	89 e5                	mov    %esp,%ebp
  1028a2:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1028a5:	8b 55 08             	mov    0x8(%ebp),%edx
  1028a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1028ae:	f0 87 02             	lock xchg %eax,(%edx)
  1028b1:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  1028b4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1028b7:	c9                   	leave  
  1028b8:	c3                   	ret    

001028b9 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  1028b9:	55                   	push   %ebp
  1028ba:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  1028bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1028bf:	8b 55 0c             	mov    0xc(%ebp),%edx
  1028c2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1028c5:	f0 01 10             	lock add %edx,(%eax)
}
  1028c8:	5d                   	pop    %ebp
  1028c9:	c3                   	ret    

001028ca <pause>:
	return result;
}

static inline void
pause(void)
{
  1028ca:	55                   	push   %ebp
  1028cb:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  1028cd:	f3 90                	pause  
}
  1028cf:	5d                   	pop    %ebp
  1028d0:	c3                   	ret    

001028d1 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1028d1:	55                   	push   %ebp
  1028d2:	89 e5                	mov    %esp,%ebp
  1028d4:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1028d7:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1028da:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1028dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1028e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028e3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1028e8:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1028eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1028ee:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1028f4:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1028f9:	74 24                	je     10291f <cpu_cur+0x4e>
  1028fb:	c7 44 24 0c 5c 60 10 	movl   $0x10605c,0xc(%esp)
  102902:	00 
  102903:	c7 44 24 08 72 60 10 	movl   $0x106072,0x8(%esp)
  10290a:	00 
  10290b:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102912:	00 
  102913:	c7 04 24 87 60 10 00 	movl   $0x106087,(%esp)
  10291a:	e8 50 db ff ff       	call   10046f <debug_panic>
	return c;
  10291f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  102922:	c9                   	leave  
  102923:	c3                   	ret    

00102924 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102924:	55                   	push   %ebp
  102925:	89 e5                	mov    %esp,%ebp
  102927:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10292a:	e8 a2 ff ff ff       	call   1028d1 <cpu_cur>
  10292f:	3d 00 80 10 00       	cmp    $0x108000,%eax
  102934:	0f 94 c0             	sete   %al
  102937:	0f b6 c0             	movzbl %al,%eax
}
  10293a:	c9                   	leave  
  10293b:	c3                   	ret    

0010293c <proc_init>:

ready_queue queue;

void
proc_init(void)
{
  10293c:	55                   	push   %ebp
  10293d:	89 e5                	mov    %esp,%ebp
  10293f:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  102942:	e8 dd ff ff ff       	call   102924 <cpu_onboot>
  102947:	85 c0                	test   %eax,%eax
  102949:	74 3c                	je     102987 <proc_init+0x4b>
		return;

	spinlock_init(&queue.lock);
  10294b:	c7 44 24 08 23 00 00 	movl   $0x23,0x8(%esp)
  102952:	00 
  102953:	c7 44 24 04 94 60 10 	movl   $0x106094,0x4(%esp)
  10295a:	00 
  10295b:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102962:	e8 90 f8 ff ff       	call   1021f7 <spinlock_init_>

	//spinlock_acquire(&queue->lock);
	queue.count= 0;
  102967:	c7 05 d8 fa 30 00 00 	movl   $0x0,0x30fad8
  10296e:	00 00 00 
	queue.head = NULL;
  102971:	c7 05 dc fa 30 00 00 	movl   $0x0,0x30fadc
  102978:	00 00 00 
	queue.tail= NULL;
  10297b:	c7 05 e0 fa 30 00 00 	movl   $0x0,0x30fae0
  102982:	00 00 00 
  102985:	eb 01                	jmp    102988 <proc_init+0x4c>

void
proc_init(void)
{
	if (!cpu_onboot())
		return;
  102987:	90                   	nop
	queue.head = NULL;
	queue.tail= NULL;
	//spinlock_release(&queue->lock);

	// your module initialization code here
}
  102988:	c9                   	leave  
  102989:	c3                   	ret    

0010298a <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  10298a:	55                   	push   %ebp
  10298b:	89 e5                	mov    %esp,%ebp
  10298d:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  102990:	e8 66 e1 ff ff       	call   100afb <mem_alloc>
  102995:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!pi)
  102998:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10299c:	75 0a                	jne    1029a8 <proc_alloc+0x1e>
		return NULL;
  10299e:	b8 00 00 00 00       	mov    $0x0,%eax
  1029a3:	e9 60 01 00 00       	jmp    102b08 <proc_alloc+0x17e>
  1029a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1029ab:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1029ae:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  1029b3:	83 c0 08             	add    $0x8,%eax
  1029b6:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1029b9:	76 15                	jbe    1029d0 <proc_alloc+0x46>
  1029bb:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  1029c0:	8b 15 84 f3 10 00    	mov    0x10f384,%edx
  1029c6:	c1 e2 03             	shl    $0x3,%edx
  1029c9:	01 d0                	add    %edx,%eax
  1029cb:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1029ce:	72 24                	jb     1029f4 <proc_alloc+0x6a>
  1029d0:	c7 44 24 0c a0 60 10 	movl   $0x1060a0,0xc(%esp)
  1029d7:	00 
  1029d8:	c7 44 24 08 72 60 10 	movl   $0x106072,0x8(%esp)
  1029df:	00 
  1029e0:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
  1029e7:	00 
  1029e8:	c7 04 24 d7 60 10 00 	movl   $0x1060d7,(%esp)
  1029ef:	e8 7b da ff ff       	call   10046f <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1029f4:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  1029f9:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  1029fe:	c1 ea 0c             	shr    $0xc,%edx
  102a01:	c1 e2 03             	shl    $0x3,%edx
  102a04:	01 d0                	add    %edx,%eax
  102a06:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102a09:	72 3b                	jb     102a46 <proc_alloc+0xbc>
  102a0b:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  102a10:	ba ef fa 30 00       	mov    $0x30faef,%edx
  102a15:	c1 ea 0c             	shr    $0xc,%edx
  102a18:	c1 e2 03             	shl    $0x3,%edx
  102a1b:	01 d0                	add    %edx,%eax
  102a1d:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102a20:	77 24                	ja     102a46 <proc_alloc+0xbc>
  102a22:	c7 44 24 0c e4 60 10 	movl   $0x1060e4,0xc(%esp)
  102a29:	00 
  102a2a:	c7 44 24 08 72 60 10 	movl   $0x106072,0x8(%esp)
  102a31:	00 
  102a32:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102a39:	00 
  102a3a:	c7 04 24 d7 60 10 00 	movl   $0x1060d7,(%esp)
  102a41:	e8 29 da ff ff       	call   10046f <debug_panic>

	lockadd(&pi->refcount, 1);
  102a46:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102a49:	83 c0 04             	add    $0x4,%eax
  102a4c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102a53:	00 
  102a54:	89 04 24             	mov    %eax,(%esp)
  102a57:	e8 5d fe ff ff       	call   1028b9 <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  102a5c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102a5f:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  102a64:	89 d1                	mov    %edx,%ecx
  102a66:	29 c1                	sub    %eax,%ecx
  102a68:	89 c8                	mov    %ecx,%eax
  102a6a:	c1 f8 03             	sar    $0x3,%eax
  102a6d:	c1 e0 0c             	shl    $0xc,%eax
  102a70:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  102a73:	c7 44 24 08 a0 06 00 	movl   $0x6a0,0x8(%esp)
  102a7a:	00 
  102a7b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102a82:	00 
  102a83:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a86:	89 04 24             	mov    %eax,(%esp)
  102a89:	e8 cd 25 00 00       	call   10505b <memset>
	spinlock_init(&cp->lock);
  102a8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a91:	c7 44 24 08 3a 00 00 	movl   $0x3a,0x8(%esp)
  102a98:	00 
  102a99:	c7 44 24 04 94 60 10 	movl   $0x106094,0x4(%esp)
  102aa0:	00 
  102aa1:	89 04 24             	mov    %eax,(%esp)
  102aa4:	e8 4e f7 ff ff       	call   1021f7 <spinlock_init_>
	cp->parent = p;
  102aa9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102aac:	8b 55 08             	mov    0x8(%ebp),%edx
  102aaf:	89 50 38             	mov    %edx,0x38(%eax)
	cp->state = PROC_STOP;
  102ab2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ab5:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  102abc:	00 00 00 

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  102abf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ac2:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  102ac9:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  102acb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ace:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  102ad5:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  102ad7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ada:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  102ae1:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  102ae3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ae6:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  102aed:	23 00 


	if (p)
  102aef:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102af3:	74 10                	je     102b05 <proc_alloc+0x17b>
		p->child[cn] = cp;
  102af5:	8b 55 0c             	mov    0xc(%ebp),%edx
  102af8:	8b 45 08             	mov    0x8(%ebp),%eax
  102afb:	8d 4a 0c             	lea    0xc(%edx),%ecx
  102afe:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102b01:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
	return cp;
  102b05:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102b08:	c9                   	leave  
  102b09:	c3                   	ret    

00102b0a <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  102b0a:	55                   	push   %ebp
  102b0b:	89 e5                	mov    %esp,%ebp
  102b0d:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_ready not implemented");
	if(p == NULL)
  102b10:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102b14:	75 1c                	jne    102b32 <proc_ready+0x28>
		panic("proc_ready's p is null!");
  102b16:	c7 44 24 08 15 61 10 	movl   $0x106115,0x8(%esp)
  102b1d:	00 
  102b1e:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  102b25:	00 
  102b26:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  102b2d:	e8 3d d9 ff ff       	call   10046f <debug_panic>

	spinlock_acquire(&p->lock);
  102b32:	8b 45 08             	mov    0x8(%ebp),%eax
  102b35:	89 04 24             	mov    %eax,(%esp)
  102b38:	e8 ee f6 ff ff       	call   10222b <spinlock_acquire>
	p->state = PROC_READY;
  102b3d:	8b 45 08             	mov    0x8(%ebp),%eax
  102b40:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  102b47:	00 00 00 

	spinlock_acquire(&queue.lock);
  102b4a:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102b51:	e8 d5 f6 ff ff       	call   10222b <spinlock_acquire>
	// if there is no proc in queue now
	if(queue.count == 0){
  102b56:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102b5b:	85 c0                	test   %eax,%eax
  102b5d:	75 33                	jne    102b92 <proc_ready+0x88>
		queue.count = 1;
  102b5f:	c7 05 d8 fa 30 00 01 	movl   $0x1,0x30fad8
  102b66:	00 00 00 
		queue.head = p;
  102b69:	8b 45 08             	mov    0x8(%ebp),%eax
  102b6c:	a3 dc fa 30 00       	mov    %eax,0x30fadc
		queue.tail = p;
  102b71:	8b 45 08             	mov    0x8(%ebp),%eax
  102b74:	a3 e0 fa 30 00       	mov    %eax,0x30fae0
		spinlock_release(&queue.lock);
  102b79:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102b80:	e8 22 f7 ff ff       	call   1022a7 <spinlock_release>
		spinlock_release(&p->lock);	
  102b85:	8b 45 08             	mov    0x8(%ebp),%eax
  102b88:	89 04 24             	mov    %eax,(%esp)
  102b8b:	e8 17 f7 ff ff       	call   1022a7 <spinlock_release>
		return;
  102b90:	eb 3c                	jmp    102bce <proc_ready+0xc4>
	}

	// insert it to the head of the queue
	p->readynext = queue.head;
  102b92:	8b 15 dc fa 30 00    	mov    0x30fadc,%edx
  102b98:	8b 45 08             	mov    0x8(%ebp),%eax
  102b9b:	89 90 40 04 00 00    	mov    %edx,0x440(%eax)
	queue.head = p;
  102ba1:	8b 45 08             	mov    0x8(%ebp),%eax
  102ba4:	a3 dc fa 30 00       	mov    %eax,0x30fadc
	queue.count++;
  102ba9:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102bae:	83 c0 01             	add    $0x1,%eax
  102bb1:	a3 d8 fa 30 00       	mov    %eax,0x30fad8

	spinlock_release(&queue.lock);
  102bb6:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102bbd:	e8 e5 f6 ff ff       	call   1022a7 <spinlock_release>
	spinlock_release(&p->lock);
  102bc2:	8b 45 08             	mov    0x8(%ebp),%eax
  102bc5:	89 04 24             	mov    %eax,(%esp)
  102bc8:	e8 da f6 ff ff       	call   1022a7 <spinlock_release>
	return;
  102bcd:	90                   	nop
	
}
  102bce:	c9                   	leave  
  102bcf:	c3                   	ret    

00102bd0 <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  102bd0:	55                   	push   %ebp
  102bd1:	89 e5                	mov    %esp,%ebp
  102bd3:	83 ec 18             	sub    $0x18,%esp
	spinlock_acquire(&p->lock);
  102bd6:	8b 45 08             	mov    0x8(%ebp),%eax
  102bd9:	89 04 24             	mov    %eax,(%esp)
  102bdc:	e8 4a f6 ff ff       	call   10222b <spinlock_acquire>
	memcpy(&p->sv.tf, &tf, sizeof(struct trapframe));
  102be1:	8b 45 08             	mov    0x8(%ebp),%eax
  102be4:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102bea:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102bf1:	00 
  102bf2:	8d 45 0c             	lea    0xc(%ebp),%eax
  102bf5:	89 44 24 04          	mov    %eax,0x4(%esp)
  102bf9:	89 14 24             	mov    %edx,(%esp)
  102bfc:	e8 a9 25 00 00       	call   1051aa <memcpy>
	spinlock_release(&p->lock);
  102c01:	8b 45 08             	mov    0x8(%ebp),%eax
  102c04:	89 04 24             	mov    %eax,(%esp)
  102c07:	e8 9b f6 ff ff       	call   1022a7 <spinlock_release>
}
  102c0c:	c9                   	leave  
  102c0d:	c3                   	ret    

00102c0e <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  102c0e:	55                   	push   %ebp
  102c0f:	89 e5                	mov    %esp,%ebp
  102c11:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");

	if(p == NULL || p->state != PROC_RUN)
  102c14:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102c18:	74 0e                	je     102c28 <proc_wait+0x1a>
  102c1a:	8b 45 08             	mov    0x8(%ebp),%eax
  102c1d:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  102c23:	83 f8 02             	cmp    $0x2,%eax
  102c26:	74 1c                	je     102c44 <proc_wait+0x36>
		panic("parent proc is not running!");
  102c28:	c7 44 24 08 2d 61 10 	movl   $0x10612d,0x8(%esp)
  102c2f:	00 
  102c30:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  102c37:	00 
  102c38:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  102c3f:	e8 2b d8 ff ff       	call   10046f <debug_panic>
	if(cp == NULL)
  102c44:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102c48:	75 1c                	jne    102c66 <proc_wait+0x58>
		panic("no child proc!");
  102c4a:	c7 44 24 08 49 61 10 	movl   $0x106149,0x8(%esp)
  102c51:	00 
  102c52:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  102c59:	00 
  102c5a:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  102c61:	e8 09 d8 ff ff       	call   10046f <debug_panic>
	
	spinlock_acquire(&p->lock);
  102c66:	8b 45 08             	mov    0x8(%ebp),%eax
  102c69:	89 04 24             	mov    %eax,(%esp)
  102c6c:	e8 ba f5 ff ff       	call   10222b <spinlock_acquire>
	p->state = PROC_WAIT;
  102c71:	8b 45 08             	mov    0x8(%ebp),%eax
  102c74:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  102c7b:	00 00 00 
	p->waitchild = cp;
  102c7e:	8b 45 08             	mov    0x8(%ebp),%eax
  102c81:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c84:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)
	spinlock_release(&p->lock);
  102c8a:	8b 45 08             	mov    0x8(%ebp),%eax
  102c8d:	89 04 24             	mov    %eax,(%esp)
  102c90:	e8 12 f6 ff ff       	call   1022a7 <spinlock_release>

	proc_save(p, tf, 0);
  102c95:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102c9c:	00 
  102c9d:	8b 45 10             	mov    0x10(%ebp),%eax
  102ca0:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ca4:	8b 45 08             	mov    0x8(%ebp),%eax
  102ca7:	89 04 24             	mov    %eax,(%esp)
  102caa:	e8 21 ff ff ff       	call   102bd0 <proc_save>
	
	while(cp->state != PROC_STOP)
  102caf:	8b 45 0c             	mov    0xc(%ebp),%eax
  102cb2:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  102cb8:	85 c0                	test   %eax,%eax
  102cba:	75 f3                	jne    102caf <proc_wait+0xa1>
		;
	proc_sched();
  102cbc:	e8 00 00 00 00       	call   102cc1 <proc_sched>

00102cc1 <proc_sched>:
	
}

void gcc_noreturn
proc_sched(void)
{
  102cc1:	55                   	push   %ebp
  102cc2:	89 e5                	mov    %esp,%ebp
  102cc4:	83 ec 28             	sub    $0x28,%esp
		//proc* before = cpu_cur()->proc;
			
		// if there is no ready process in queue
		// just wait

		spinlock_acquire(&queue.lock);
  102cc7:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102cce:	e8 58 f5 ff ff       	call   10222b <spinlock_acquire>
		
		while(queue.count == 0){
  102cd3:	eb 05                	jmp    102cda <proc_sched+0x19>
			pause();
  102cd5:	e8 f0 fb ff ff       	call   1028ca <pause>
		// if there is no ready process in queue
		// just wait

		spinlock_acquire(&queue.lock);
		
		while(queue.count == 0){
  102cda:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102cdf:	85 c0                	test   %eax,%eax
  102ce1:	74 f2                	je     102cd5 <proc_sched+0x14>
			pause();
		}	
	
		// if there is just one ready process
		if(queue.count == 1){
  102ce3:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102ce8:	83 f8 01             	cmp    $0x1,%eax
  102ceb:	75 28                	jne    102d15 <proc_sched+0x54>
			run = queue.head;
  102ced:	a1 dc fa 30 00       	mov    0x30fadc,%eax
  102cf2:	89 45 f0             	mov    %eax,-0x10(%ebp)
			queue.head = queue.tail = NULL;
  102cf5:	c7 05 e0 fa 30 00 00 	movl   $0x0,0x30fae0
  102cfc:	00 00 00 
  102cff:	a1 e0 fa 30 00       	mov    0x30fae0,%eax
  102d04:	a3 dc fa 30 00       	mov    %eax,0x30fadc
			queue.count = 0;
  102d09:	c7 05 d8 fa 30 00 00 	movl   $0x0,0x30fad8
  102d10:	00 00 00 
  102d13:	eb 45                	jmp    102d5a <proc_sched+0x99>
		}
		
		// if there is more than one ready processes
		else{
			proc* before_tail = queue.head;
  102d15:	a1 dc fa 30 00       	mov    0x30fadc,%eax
  102d1a:	89 45 f4             	mov    %eax,-0xc(%ebp)
			while(before_tail->readynext != queue.tail){
  102d1d:	eb 0c                	jmp    102d2b <proc_sched+0x6a>
				before_tail = before_tail->readynext;
  102d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d22:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102d28:	89 45 f4             	mov    %eax,-0xc(%ebp)
		}
		
		// if there is more than one ready processes
		else{
			proc* before_tail = queue.head;
			while(before_tail->readynext != queue.tail){
  102d2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d2e:	8b 90 40 04 00 00    	mov    0x440(%eax),%edx
  102d34:	a1 e0 fa 30 00       	mov    0x30fae0,%eax
  102d39:	39 c2                	cmp    %eax,%edx
  102d3b:	75 e2                	jne    102d1f <proc_sched+0x5e>
				before_tail = before_tail->readynext;
			}	
			run = queue.tail;
  102d3d:	a1 e0 fa 30 00       	mov    0x30fae0,%eax
  102d42:	89 45 f0             	mov    %eax,-0x10(%ebp)
			queue.tail = before_tail;
  102d45:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d48:	a3 e0 fa 30 00       	mov    %eax,0x30fae0
			queue.count--;
  102d4d:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102d52:	83 e8 01             	sub    $0x1,%eax
  102d55:	a3 d8 fa 30 00       	mov    %eax,0x30fad8
		}
		
		spinlock_release(&queue.lock);
  102d5a:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102d61:	e8 41 f5 ff ff       	call   1022a7 <spinlock_release>
	
		proc_run(run);
  102d66:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102d69:	89 04 24             	mov    %eax,(%esp)
  102d6c:	e8 00 00 00 00       	call   102d71 <proc_run>

00102d71 <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  102d71:	55                   	push   %ebp
  102d72:	89 e5                	mov    %esp,%ebp
  102d74:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");

	if(p == NULL)
  102d77:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102d7b:	75 1c                	jne    102d99 <proc_run+0x28>
		panic("proc_run's p is null!");
  102d7d:	c7 44 24 08 58 61 10 	movl   $0x106158,0x8(%esp)
  102d84:	00 
  102d85:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  102d8c:	00 
  102d8d:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  102d94:	e8 d6 d6 ff ff       	call   10046f <debug_panic>

	spinlock_acquire(&p->lock);
  102d99:	8b 45 08             	mov    0x8(%ebp),%eax
  102d9c:	89 04 24             	mov    %eax,(%esp)
  102d9f:	e8 87 f4 ff ff       	call   10222b <spinlock_acquire>

	cpu* c = cpu_cur();
  102da4:	e8 28 fb ff ff       	call   1028d1 <cpu_cur>
  102da9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->proc = p;
  102dac:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102daf:	8b 55 08             	mov    0x8(%ebp),%edx
  102db2:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	p->state = PROC_RUN;
  102db8:	8b 45 08             	mov    0x8(%ebp),%eax
  102dbb:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  102dc2:	00 00 00 
	p->runcpu = c;
  102dc5:	8b 45 08             	mov    0x8(%ebp),%eax
  102dc8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102dcb:	89 90 44 04 00 00    	mov    %edx,0x444(%eax)

	spinlock_release(&p->lock);
  102dd1:	8b 45 08             	mov    0x8(%ebp),%eax
  102dd4:	89 04 24             	mov    %eax,(%esp)
  102dd7:	e8 cb f4 ff ff       	call   1022a7 <spinlock_release>
	
	trap_return(&p->sv.tf);
  102ddc:	8b 45 08             	mov    0x8(%ebp),%eax
  102ddf:	05 50 04 00 00       	add    $0x450,%eax
  102de4:	89 04 24             	mov    %eax,(%esp)
  102de7:	e8 04 63 00 00       	call   1090f0 <trap_return>

00102dec <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  102dec:	55                   	push   %ebp
  102ded:	89 e5                	mov    %esp,%ebp
  102def:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_yield not implemented");

	proc* cur_proc = cpu_cur()->proc;
  102df2:	e8 da fa ff ff       	call   1028d1 <cpu_cur>
  102df7:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  102dfd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	proc_save(cur_proc, tf, 0);
  102e00:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102e07:	00 
  102e08:	8b 45 08             	mov    0x8(%ebp),%eax
  102e0b:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e12:	89 04 24             	mov    %eax,(%esp)
  102e15:	e8 b6 fd ff ff       	call   102bd0 <proc_save>
	proc_ready(cur_proc);
  102e1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e1d:	89 04 24             	mov    %eax,(%esp)
  102e20:	e8 e5 fc ff ff       	call   102b0a <proc_ready>
	proc_sched();
  102e25:	e8 97 fe ff ff       	call   102cc1 <proc_sched>

00102e2a <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  102e2a:	55                   	push   %ebp
  102e2b:	89 e5                	mov    %esp,%ebp
  102e2d:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_ret not implemented");

	proc* proc_child = proc_cur();
  102e30:	e8 9c fa ff ff       	call   1028d1 <cpu_cur>
  102e35:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  102e3b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_parent = proc_child->parent;
  102e3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e41:	8b 40 38             	mov    0x38(%eax),%eax
  102e44:	89 45 f4             	mov    %eax,-0xc(%ebp)

	spinlock_acquire(&proc_child->lock);
  102e47:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e4a:	89 04 24             	mov    %eax,(%esp)
  102e4d:	e8 d9 f3 ff ff       	call   10222b <spinlock_acquire>
	proc_child->state = PROC_STOP;
  102e52:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e55:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  102e5c:	00 00 00 
	spinlock_release(&proc_child->lock);
  102e5f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e62:	89 04 24             	mov    %eax,(%esp)
  102e65:	e8 3d f4 ff ff       	call   1022a7 <spinlock_release>

	proc_save(proc_child, tf, entry);
  102e6a:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e6d:	89 44 24 08          	mov    %eax,0x8(%esp)
  102e71:	8b 45 08             	mov    0x8(%ebp),%eax
  102e74:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e78:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e7b:	89 04 24             	mov    %eax,(%esp)
  102e7e:	e8 4d fd ff ff       	call   102bd0 <proc_save>

	if((proc_parent->state == PROC_WAIT) && (proc_parent->waitchild == proc_child) )
  102e83:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e86:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  102e8c:	83 f8 03             	cmp    $0x3,%eax
  102e8f:	75 19                	jne    102eaa <proc_ret+0x80>
  102e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e94:	8b 80 48 04 00 00    	mov    0x448(%eax),%eax
  102e9a:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102e9d:	75 0b                	jne    102eaa <proc_ret+0x80>
		proc_ready(proc_parent);
  102e9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ea2:	89 04 24             	mov    %eax,(%esp)
  102ea5:	e8 60 fc ff ff       	call   102b0a <proc_ready>

	proc_sched();
  102eaa:	e8 12 fe ff ff       	call   102cc1 <proc_sched>

00102eaf <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  102eaf:	55                   	push   %ebp
  102eb0:	89 e5                	mov    %esp,%ebp
  102eb2:	57                   	push   %edi
  102eb3:	56                   	push   %esi
  102eb4:	53                   	push   %ebx
  102eb5:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  102ebb:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  102ec2:	00 00 00 
  102ec5:	e9 f0 00 00 00       	jmp    102fba <proc_check+0x10b>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  102eca:	b8 10 b3 10 00       	mov    $0x10b310,%eax
  102ecf:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  102ed5:	83 c2 01             	add    $0x1,%edx
  102ed8:	c1 e2 0c             	shl    $0xc,%edx
  102edb:	01 d0                	add    %edx,%eax
  102edd:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		*--esp = i;	// push argument to child() function
  102ee3:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  102eea:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  102ef0:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  102ef6:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  102ef8:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  102eff:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  102f05:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  102f0b:	b8 8f 33 10 00       	mov    $0x10338f,%eax
  102f10:	a3 f8 b0 10 00       	mov    %eax,0x10b0f8
		child_state.tf.esp = (uint32_t) esp;
  102f15:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  102f1b:	a3 04 b1 10 00       	mov    %eax,0x10b104

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  102f20:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102f26:	89 44 24 04          	mov    %eax,0x4(%esp)
  102f2a:	c7 04 24 6e 61 10 00 	movl   $0x10616e,(%esp)
  102f31:	e8 40 1f 00 00       	call   104e76 <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  102f36:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102f3c:	0f b7 d0             	movzwl %ax,%edx
  102f3f:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  102f46:	7f 07                	jg     102f4f <proc_check+0xa0>
  102f48:	b8 10 10 00 00       	mov    $0x1010,%eax
  102f4d:	eb 05                	jmp    102f54 <proc_check+0xa5>
  102f4f:	b8 00 10 00 00       	mov    $0x1000,%eax
  102f54:	89 85 54 ff ff ff    	mov    %eax,-0xac(%ebp)
  102f5a:	66 89 95 52 ff ff ff 	mov    %dx,-0xae(%ebp)
  102f61:	c7 85 4c ff ff ff c0 	movl   $0x10b0c0,-0xb4(%ebp)
  102f68:	b0 10 00 
  102f6b:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
  102f72:	00 00 00 
  102f75:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
  102f7c:	00 00 00 
  102f7f:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
  102f86:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  102f89:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
  102f8f:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  102f92:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
  102f98:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
  102f9f:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
  102fa5:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
  102fab:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
  102fb1:	cd 30                	int    $0x30
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  102fb3:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  102fba:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  102fc1:	0f 8e 03 ff ff ff    	jle    102eca <proc_check+0x1b>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  102fc7:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  102fce:	00 00 00 
  102fd1:	e9 89 00 00 00       	jmp    10305f <proc_check+0x1b0>
		cprintf("waiting for child %d\n", i);
  102fd6:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102fdc:	89 44 24 04          	mov    %eax,0x4(%esp)
  102fe0:	c7 04 24 81 61 10 00 	movl   $0x106181,(%esp)
  102fe7:	e8 8a 1e 00 00       	call   104e76 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  102fec:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102ff2:	0f b7 c0             	movzwl %ax,%eax
  102ff5:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
  102ffc:	10 00 00 
  102fff:	66 89 85 6a ff ff ff 	mov    %ax,-0x96(%ebp)
  103006:	c7 85 64 ff ff ff c0 	movl   $0x10b0c0,-0x9c(%ebp)
  10300d:	b0 10 00 
  103010:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
  103017:	00 00 00 
  10301a:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
  103021:	00 00 00 
  103024:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
  10302b:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10302e:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
  103034:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103037:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
  10303d:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
  103044:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
  10304a:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
  103050:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
  103056:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  103058:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  10305f:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  103066:	0f 8e 6a ff ff ff    	jle    102fd6 <proc_check+0x127>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  10306c:	c7 04 24 98 61 10 00 	movl   $0x106198,(%esp)
  103073:	e8 fe 1d 00 00       	call   104e76 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  103078:	c7 04 24 c0 61 10 00 	movl   $0x1061c0,(%esp)
  10307f:	e8 f2 1d 00 00       	call   104e76 <cprintf>
	for (i = 0; i < 4; i++) {
  103084:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10308b:	00 00 00 
  10308e:	eb 7d                	jmp    10310d <proc_check+0x25e>
		cprintf("spawning child %d\n", i);
  103090:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103096:	89 44 24 04          	mov    %eax,0x4(%esp)
  10309a:	c7 04 24 6e 61 10 00 	movl   $0x10616e,(%esp)
  1030a1:	e8 d0 1d 00 00       	call   104e76 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  1030a6:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1030ac:	0f b7 c0             	movzwl %ax,%eax
  1030af:	c7 45 84 10 00 00 00 	movl   $0x10,-0x7c(%ebp)
  1030b6:	66 89 45 82          	mov    %ax,-0x7e(%ebp)
  1030ba:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  1030c1:	00 00 00 
  1030c4:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
  1030cb:	00 00 00 
  1030ce:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
  1030d5:	00 00 00 
  1030d8:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
  1030df:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1030e2:	8b 45 84             	mov    -0x7c(%ebp),%eax
  1030e5:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1030e8:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
  1030ee:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
  1030f2:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
  1030f8:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
  1030fe:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
  103104:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  103106:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  10310d:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103114:	0f 8e 76 ff ff ff    	jle    103090 <proc_check+0x1e1>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  10311a:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103121:	00 00 00 
  103124:	eb 4f                	jmp    103175 <proc_check+0x2c6>
		sys_get(0, i, NULL, NULL, NULL, 0);
  103126:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10312c:	0f b7 c0             	movzwl %ax,%eax
  10312f:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  103136:	66 89 45 9a          	mov    %ax,-0x66(%ebp)
  10313a:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
  103141:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  103148:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
  10314f:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103156:	8b 45 9c             	mov    -0x64(%ebp),%eax
  103159:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10315c:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
  10315f:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
  103163:	8b 75 90             	mov    -0x70(%ebp),%esi
  103166:	8b 7d 8c             	mov    -0x74(%ebp),%edi
  103169:	8b 4d 88             	mov    -0x78(%ebp),%ecx
  10316c:	cd 30                	int    $0x30
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  10316e:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103175:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  10317c:	7e a8                	jle    103126 <proc_check+0x277>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  10317e:	c7 04 24 e4 61 10 00 	movl   $0x1061e4,(%esp)
  103185:	e8 ec 1c 00 00       	call   104e76 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  10318a:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103191:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103194:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10319a:	0f b7 c0             	movzwl %ax,%eax
  10319d:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
  1031a4:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
  1031a8:	c7 45 ac c0 b0 10 00 	movl   $0x10b0c0,-0x54(%ebp)
  1031af:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  1031b6:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  1031bd:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1031c4:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  1031c7:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1031ca:	8b 5d ac             	mov    -0x54(%ebp),%ebx
  1031cd:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
  1031d1:	8b 75 a8             	mov    -0x58(%ebp),%esi
  1031d4:	8b 7d a4             	mov    -0x5c(%ebp),%edi
  1031d7:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  1031da:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  1031dc:	a1 14 f3 10 00       	mov    0x10f314,%eax
  1031e1:	85 c0                	test   %eax,%eax
  1031e3:	74 24                	je     103209 <proc_check+0x35a>
  1031e5:	c7 44 24 0c 09 62 10 	movl   $0x106209,0xc(%esp)
  1031ec:	00 
  1031ed:	c7 44 24 08 72 60 10 	movl   $0x106072,0x8(%esp)
  1031f4:	00 
  1031f5:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
  1031fc:	00 
  1031fd:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  103204:	e8 66 d2 ff ff       	call   10046f <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  103209:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10320f:	0f b7 c0             	movzwl %ax,%eax
  103212:	c7 45 cc 10 10 00 00 	movl   $0x1010,-0x34(%ebp)
  103219:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
  10321d:	c7 45 c4 c0 b0 10 00 	movl   $0x10b0c0,-0x3c(%ebp)
  103224:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
  10322b:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  103232:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103239:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10323c:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10323f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
  103242:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  103246:	8b 75 c0             	mov    -0x40(%ebp),%esi
  103249:	8b 7d bc             	mov    -0x44(%ebp),%edi
  10324c:	8b 4d b8             	mov    -0x48(%ebp),%ecx
  10324f:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103251:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103257:	0f b7 c0             	movzwl %ax,%eax
  10325a:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  103261:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
  103265:	c7 45 dc c0 b0 10 00 	movl   $0x10b0c0,-0x24(%ebp)
  10326c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103273:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  10327a:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103281:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103284:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103287:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  10328a:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  10328e:	8b 75 d8             	mov    -0x28(%ebp),%esi
  103291:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  103294:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  103297:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  103299:	a1 14 f3 10 00       	mov    0x10f314,%eax
  10329e:	85 c0                	test   %eax,%eax
  1032a0:	74 3f                	je     1032e1 <proc_check+0x432>
			trap_check_args *args = recovargs;
  1032a2:	a1 14 f3 10 00       	mov    0x10f314,%eax
  1032a7:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)
			cprintf("recover from trap %d\n",
  1032ad:	a1 f0 b0 10 00       	mov    0x10b0f0,%eax
  1032b2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1032b6:	c7 04 24 1b 62 10 00 	movl   $0x10621b,(%esp)
  1032bd:	e8 b4 1b 00 00       	call   104e76 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  1032c2:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  1032c8:	8b 00                	mov    (%eax),%eax
  1032ca:	a3 f8 b0 10 00       	mov    %eax,0x10b0f8
			args->trapno = child_state.tf.trapno;
  1032cf:	a1 f0 b0 10 00       	mov    0x10b0f0,%eax
  1032d4:	89 c2                	mov    %eax,%edx
  1032d6:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  1032dc:	89 50 04             	mov    %edx,0x4(%eax)
  1032df:	eb 2e                	jmp    10330f <proc_check+0x460>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  1032e1:	a1 f0 b0 10 00       	mov    0x10b0f0,%eax
  1032e6:	83 f8 30             	cmp    $0x30,%eax
  1032e9:	74 24                	je     10330f <proc_check+0x460>
  1032eb:	c7 44 24 0c 34 62 10 	movl   $0x106234,0xc(%esp)
  1032f2:	00 
  1032f3:	c7 44 24 08 72 60 10 	movl   $0x106072,0x8(%esp)
  1032fa:	00 
  1032fb:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
  103302:	00 
  103303:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  10330a:	e8 60 d1 ff ff       	call   10046f <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  10330f:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103315:	8d 50 01             	lea    0x1(%eax),%edx
  103318:	89 d0                	mov    %edx,%eax
  10331a:	c1 f8 1f             	sar    $0x1f,%eax
  10331d:	c1 e8 1e             	shr    $0x1e,%eax
  103320:	01 c2                	add    %eax,%edx
  103322:	83 e2 03             	and    $0x3,%edx
  103325:	89 d1                	mov    %edx,%ecx
  103327:	29 c1                	sub    %eax,%ecx
  103329:	89 c8                	mov    %ecx,%eax
  10332b:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  103331:	a1 f0 b0 10 00       	mov    0x10b0f0,%eax
  103336:	83 f8 30             	cmp    $0x30,%eax
  103339:	0f 85 ca fe ff ff    	jne    103209 <proc_check+0x35a>
	assert(recovargs == NULL);
  10333f:	a1 14 f3 10 00       	mov    0x10f314,%eax
  103344:	85 c0                	test   %eax,%eax
  103346:	74 24                	je     10336c <proc_check+0x4bd>
  103348:	c7 44 24 0c 09 62 10 	movl   $0x106209,0xc(%esp)
  10334f:	00 
  103350:	c7 44 24 08 72 60 10 	movl   $0x106072,0x8(%esp)
  103357:	00 
  103358:	c7 44 24 04 44 01 00 	movl   $0x144,0x4(%esp)
  10335f:	00 
  103360:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  103367:	e8 03 d1 ff ff       	call   10046f <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  10336c:	c7 04 24 58 62 10 00 	movl   $0x106258,(%esp)
  103373:	e8 fe 1a 00 00       	call   104e76 <cprintf>

	cprintf("proc_check() succeeded!\n");
  103378:	c7 04 24 85 62 10 00 	movl   $0x106285,(%esp)
  10337f:	e8 f2 1a 00 00       	call   104e76 <cprintf>
}
  103384:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  10338a:	5b                   	pop    %ebx
  10338b:	5e                   	pop    %esi
  10338c:	5f                   	pop    %edi
  10338d:	5d                   	pop    %ebp
  10338e:	c3                   	ret    

0010338f <child>:

static void child(int n)
{
  10338f:	55                   	push   %ebp
  103390:	89 e5                	mov    %esp,%ebp
  103392:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  103395:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  103399:	7f 64                	jg     1033ff <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  10339b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1033a2:	eb 4e                	jmp    1033f2 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  1033a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1033a7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1033ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1033ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033b2:	c7 04 24 9e 62 10 00 	movl   $0x10629e,(%esp)
  1033b9:	e8 b8 1a 00 00       	call   104e76 <cprintf>
			while (pingpong != n)
  1033be:	eb 05                	jmp    1033c5 <child+0x36>
				pause();
  1033c0:	e8 05 f5 ff ff       	call   1028ca <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n)
  1033c5:	8b 55 08             	mov    0x8(%ebp),%edx
  1033c8:	a1 10 f3 10 00       	mov    0x10f310,%eax
  1033cd:	39 c2                	cmp    %eax,%edx
  1033cf:	75 ef                	jne    1033c0 <child+0x31>
				pause();
			xchg(&pingpong, !pingpong);
  1033d1:	a1 10 f3 10 00       	mov    0x10f310,%eax
  1033d6:	85 c0                	test   %eax,%eax
  1033d8:	0f 94 c0             	sete   %al
  1033db:	0f b6 c0             	movzbl %al,%eax
  1033de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033e2:	c7 04 24 10 f3 10 00 	movl   $0x10f310,(%esp)
  1033e9:	e8 b1 f4 ff ff       	call   10289f <xchg>
static void child(int n)
{
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  1033ee:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1033f2:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1033f6:	7e ac                	jle    1033a4 <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  1033f8:	b8 03 00 00 00       	mov    $0x3,%eax
  1033fd:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  1033ff:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103406:	eb 4c                	jmp    103454 <child+0xc5>
		cprintf("in child %d count %d\n", n, i);
  103408:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10340b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10340f:	8b 45 08             	mov    0x8(%ebp),%eax
  103412:	89 44 24 04          	mov    %eax,0x4(%esp)
  103416:	c7 04 24 9e 62 10 00 	movl   $0x10629e,(%esp)
  10341d:	e8 54 1a 00 00       	call   104e76 <cprintf>
		while (pingpong != n)
  103422:	eb 05                	jmp    103429 <child+0x9a>
			pause();
  103424:	e8 a1 f4 ff ff       	call   1028ca <pause>

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		cprintf("in child %d count %d\n", n, i);
		while (pingpong != n)
  103429:	8b 55 08             	mov    0x8(%ebp),%edx
  10342c:	a1 10 f3 10 00       	mov    0x10f310,%eax
  103431:	39 c2                	cmp    %eax,%edx
  103433:	75 ef                	jne    103424 <child+0x95>
			pause();
		xchg(&pingpong, (pingpong + 1) % 4);
  103435:	a1 10 f3 10 00       	mov    0x10f310,%eax
  10343a:	83 c0 01             	add    $0x1,%eax
  10343d:	83 e0 03             	and    $0x3,%eax
  103440:	89 44 24 04          	mov    %eax,0x4(%esp)
  103444:	c7 04 24 10 f3 10 00 	movl   $0x10f310,(%esp)
  10344b:	e8 4f f4 ff ff       	call   10289f <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103450:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103454:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  103458:	7e ae                	jle    103408 <child+0x79>
  10345a:	b8 03 00 00 00       	mov    $0x3,%eax
  10345f:	cd 30                	int    $0x30
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  103461:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103465:	75 6d                	jne    1034d4 <child+0x145>
		assert(recovargs == NULL);
  103467:	a1 14 f3 10 00       	mov    0x10f314,%eax
  10346c:	85 c0                	test   %eax,%eax
  10346e:	74 24                	je     103494 <child+0x105>
  103470:	c7 44 24 0c 09 62 10 	movl   $0x106209,0xc(%esp)
  103477:	00 
  103478:	c7 44 24 08 72 60 10 	movl   $0x106072,0x8(%esp)
  10347f:	00 
  103480:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
  103487:	00 
  103488:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  10348f:	e8 db cf ff ff       	call   10046f <debug_panic>
		trap_check(&recovargs);
  103494:	c7 04 24 14 f3 10 00 	movl   $0x10f314,(%esp)
  10349b:	e8 f2 e4 ff ff       	call   101992 <trap_check>
		assert(recovargs == NULL);
  1034a0:	a1 14 f3 10 00       	mov    0x10f314,%eax
  1034a5:	85 c0                	test   %eax,%eax
  1034a7:	74 24                	je     1034cd <child+0x13e>
  1034a9:	c7 44 24 0c 09 62 10 	movl   $0x106209,0xc(%esp)
  1034b0:	00 
  1034b1:	c7 44 24 08 72 60 10 	movl   $0x106072,0x8(%esp)
  1034b8:	00 
  1034b9:	c7 44 24 04 67 01 00 	movl   $0x167,0x4(%esp)
  1034c0:	00 
  1034c1:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  1034c8:	e8 a2 cf ff ff       	call   10046f <debug_panic>
  1034cd:	b8 03 00 00 00       	mov    $0x3,%eax
  1034d2:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  1034d4:	c7 44 24 08 b4 62 10 	movl   $0x1062b4,0x8(%esp)
  1034db:	00 
  1034dc:	c7 44 24 04 6b 01 00 	movl   $0x16b,0x4(%esp)
  1034e3:	00 
  1034e4:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  1034eb:	e8 7f cf ff ff       	call   10046f <debug_panic>

001034f0 <grandchild>:
}

static void grandchild(int n)
{
  1034f0:	55                   	push   %ebp
  1034f1:	89 e5                	mov    %esp,%ebp
  1034f3:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  1034f6:	c7 44 24 08 d8 62 10 	movl   $0x1062d8,0x8(%esp)
  1034fd:	00 
  1034fe:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
  103505:	00 
  103506:	c7 04 24 94 60 10 00 	movl   $0x106094,(%esp)
  10350d:	e8 5d cf ff ff       	call   10046f <debug_panic>

00103512 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103512:	55                   	push   %ebp
  103513:	89 e5                	mov    %esp,%ebp
  103515:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103518:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10351b:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10351e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103521:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103524:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103529:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10352c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10352f:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103535:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10353a:	74 24                	je     103560 <cpu_cur+0x4e>
  10353c:	c7 44 24 0c 04 63 10 	movl   $0x106304,0xc(%esp)
  103543:	00 
  103544:	c7 44 24 08 1a 63 10 	movl   $0x10631a,0x8(%esp)
  10354b:	00 
  10354c:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103553:	00 
  103554:	c7 04 24 2f 63 10 00 	movl   $0x10632f,(%esp)
  10355b:	e8 0f cf ff ff       	call   10046f <debug_panic>
	return c;
  103560:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103563:	c9                   	leave  
  103564:	c3                   	ret    

00103565 <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  103565:	55                   	push   %ebp
  103566:	89 e5                	mov    %esp,%ebp
  103568:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  10356b:	c7 44 24 08 3c 63 10 	movl   $0x10633c,0x8(%esp)
  103572:	00 
  103573:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  10357a:	00 
  10357b:	c7 04 24 57 63 10 00 	movl   $0x106357,(%esp)
  103582:	e8 e8 ce ff ff       	call   10046f <debug_panic>

00103587 <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  103587:	55                   	push   %ebp
  103588:	89 e5                	mov    %esp,%ebp
  10358a:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  10358d:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  103594:	00 
  103595:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  10359c:	00 
  10359d:	c7 04 24 57 63 10 00 	movl   $0x106357,(%esp)
  1035a4:	e8 c6 ce ff ff       	call   10046f <debug_panic>

001035a9 <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  1035a9:	55                   	push   %ebp
  1035aa:	89 e5                	mov    %esp,%ebp
  1035ac:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  1035af:	c7 44 24 08 84 63 10 	movl   $0x106384,0x8(%esp)
  1035b6:	00 
  1035b7:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  1035be:	00 
  1035bf:	c7 04 24 57 63 10 00 	movl   $0x106357,(%esp)
  1035c6:	e8 a4 ce ff ff       	call   10046f <debug_panic>

001035cb <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  1035cb:	55                   	push   %ebp
  1035cc:	89 e5                	mov    %esp,%ebp
  1035ce:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  1035d1:	8b 45 18             	mov    0x18(%ebp),%eax
  1035d4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1035d8:	8b 45 14             	mov    0x14(%ebp),%eax
  1035db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035df:	8b 45 08             	mov    0x8(%ebp),%eax
  1035e2:	89 04 24             	mov    %eax,(%esp)
  1035e5:	e8 bf ff ff ff       	call   1035a9 <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  1035ea:	c7 44 24 08 a0 63 10 	movl   $0x1063a0,0x8(%esp)
  1035f1:	00 
  1035f2:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  1035f9:	00 
  1035fa:	c7 04 24 57 63 10 00 	movl   $0x106357,(%esp)
  103601:	e8 69 ce ff ff       	call   10046f <debug_panic>

00103606 <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  103606:	55                   	push   %ebp
  103607:	89 e5                	mov    %esp,%ebp
  103609:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  10360c:	8b 45 08             	mov    0x8(%ebp),%eax
  10360f:	8b 40 10             	mov    0x10(%eax),%eax
  103612:	89 44 24 04          	mov    %eax,0x4(%esp)
  103616:	c7 04 24 c4 63 10 00 	movl   $0x1063c4,(%esp)
  10361d:	e8 54 18 00 00       	call   104e76 <cprintf>

	trap_return(tf);	// syscall completed
  103622:	8b 45 08             	mov    0x8(%ebp),%eax
  103625:	89 04 24             	mov    %eax,(%esp)
  103628:	e8 c3 5a 00 00       	call   1090f0 <trap_return>

0010362d <do_put>:
}


static void
do_put(trapframe *tf, uint32_t cmd)
{	
  10362d:	55                   	push   %ebp
  10362e:	89 e5                	mov    %esp,%ebp
  103630:	83 ec 28             	sub    $0x28,%esp
	procstate* ps = (procstate*)tf->regs.ebx;
  103633:	8b 45 08             	mov    0x8(%ebp),%eax
  103636:	8b 40 10             	mov    0x10(%eax),%eax
  103639:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint16_t child_num = tf->regs.edx;
  10363c:	8b 45 08             	mov    0x8(%ebp),%eax
  10363f:	8b 40 14             	mov    0x14(%eax),%eax
  103642:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
	proc* proc_parent = proc_cur();
  103646:	e8 c7 fe ff ff       	call   103512 <cpu_cur>
  10364b:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103651:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103654:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  103658:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10365b:	83 c2 0c             	add    $0xc,%edx
  10365e:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
  103662:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(proc_child == NULL){
  103665:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103669:	75 38                	jne    1036a3 <do_put+0x76>
		proc_child = proc_alloc(proc_parent, child_num);
  10366b:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
  10366f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103673:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103676:	89 04 24             	mov    %eax,(%esp)
  103679:	e8 0c f3 ff ff       	call   10298a <proc_alloc>
  10367e:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if(proc_child == NULL)
  103681:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103685:	75 1c                	jne    1036a3 <do_put+0x76>
			panic("no child proc!");
  103687:	c7 44 24 08 c7 63 10 	movl   $0x1063c7,0x8(%esp)
  10368e:	00 
  10368f:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  103696:	00 
  103697:	c7 04 24 57 63 10 00 	movl   $0x106357,(%esp)
  10369e:	e8 cc cd ff ff       	call   10046f <debug_panic>
	}

	if(proc_child->state != PROC_STOP){
  1036a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1036a6:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1036ac:	85 c0                	test   %eax,%eax
  1036ae:	74 3d                	je     1036ed <do_put+0xc0>
		spinlock_acquire(&(proc_parent->lock));
  1036b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1036b3:	89 04 24             	mov    %eax,(%esp)
  1036b6:	e8 70 eb ff ff       	call   10222b <spinlock_acquire>
		proc_parent->state = PROC_WAIT;
  1036bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1036be:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  1036c5:	00 00 00 
		spinlock_release(&(proc_parent->lock));
  1036c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1036cb:	89 04 24             	mov    %eax,(%esp)
  1036ce:	e8 d4 eb ff ff       	call   1022a7 <spinlock_release>
		proc_save(proc_parent, tf, 0);
  1036d3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1036da:	00 
  1036db:	8b 45 08             	mov    0x8(%ebp),%eax
  1036de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1036e5:	89 04 24             	mov    %eax,(%esp)
  1036e8:	e8 e3 f4 ff ff       	call   102bd0 <proc_save>
	}

	//cprintf("1");

	if(tf->regs.eax & SYS_REGS){	
  1036ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1036f0:	8b 40 1c             	mov    0x1c(%eax),%eax
  1036f3:	25 00 10 00 00       	and    $0x1000,%eax
  1036f8:	85 c0                	test   %eax,%eax
  1036fa:	0f 84 ba 00 00 00    	je     1037ba <do_put+0x18d>
		//cprintf("2");
		if(((proc_child->sv.tf.eflags ^ ps->tf.eflags) | FL_USER) != FL_USER)
  103700:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103703:	8b 90 90 04 00 00    	mov    0x490(%eax),%edx
  103709:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10370c:	8b 40 40             	mov    0x40(%eax),%eax
  10370f:	31 d0                	xor    %edx,%eax
  103711:	0d d5 0c 00 00       	or     $0xcd5,%eax
  103716:	3d d5 0c 00 00       	cmp    $0xcd5,%eax
  10371b:	74 1c                	je     103739 <do_put+0x10c>
			panic("illegal modification of eflags!");
  10371d:	c7 44 24 08 d8 63 10 	movl   $0x1063d8,0x8(%esp)
  103724:	00 
  103725:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  10372c:	00 
  10372d:	c7 04 24 57 63 10 00 	movl   $0x106357,(%esp)
  103734:	e8 36 cd ff ff       	call   10046f <debug_panic>

		spinlock_acquire(&proc_child->lock);
  103739:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10373c:	89 04 24             	mov    %eax,(%esp)
  10373f:	e8 e7 ea ff ff       	call   10222b <spinlock_acquire>
		proc_child->sv.tf.eflags = ps->tf.eflags;
  103744:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103747:	8b 50 40             	mov    0x40(%eax),%edx
  10374a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10374d:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
		spinlock_release(&proc_child->lock);
  103753:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103756:	89 04 24             	mov    %eax,(%esp)
  103759:	e8 49 eb ff ff       	call   1022a7 <spinlock_release>

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
  10375e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103761:	0f b7 80 8c 04 00 00 	movzwl 0x48c(%eax),%eax

		spinlock_acquire(&proc_child->lock);
		proc_child->sv.tf.eflags = ps->tf.eflags;
		spinlock_release(&proc_child->lock);

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103768:	66 83 f8 1b          	cmp    $0x1b,%ax
  10376c:	75 30                	jne    10379e <do_put+0x171>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
  10376e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103771:	0f b7 80 7c 04 00 00 	movzwl 0x47c(%eax),%eax

		spinlock_acquire(&proc_child->lock);
		proc_child->sv.tf.eflags = ps->tf.eflags;
		spinlock_release(&proc_child->lock);

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103778:	66 83 f8 23          	cmp    $0x23,%ax
  10377c:	75 20                	jne    10379e <do_put+0x171>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  10377e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103781:	0f b7 80 78 04 00 00 	movzwl 0x478(%eax),%eax

		spinlock_acquire(&proc_child->lock);
		proc_child->sv.tf.eflags = ps->tf.eflags;
		spinlock_release(&proc_child->lock);

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103788:	66 83 f8 23          	cmp    $0x23,%ax
  10378c:	75 10                	jne    10379e <do_put+0x171>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  10378e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103791:	0f b7 80 98 04 00 00 	movzwl 0x498(%eax),%eax

		spinlock_acquire(&proc_child->lock);
		proc_child->sv.tf.eflags = ps->tf.eflags;
		spinlock_release(&proc_child->lock);

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103798:	66 83 f8 23          	cmp    $0x23,%ax
  10379c:	74 5a                	je     1037f8 <do_put+0x1cb>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
			panic("wrong segment regs values!");
  10379e:	c7 44 24 08 f8 63 10 	movl   $0x1063f8,0x8(%esp)
  1037a5:	00 
  1037a6:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
  1037ad:	00 
  1037ae:	c7 04 24 57 63 10 00 	movl   $0x106357,(%esp)
  1037b5:	e8 b5 cc ff ff       	call   10046f <debug_panic>
	}
	else if(tf->regs.eax & SYS_START){
  1037ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1037bd:	8b 40 1c             	mov    0x1c(%eax),%eax
  1037c0:	83 e0 10             	and    $0x10,%eax
  1037c3:	85 c0                	test   %eax,%eax
  1037c5:	74 31                	je     1037f8 <do_put+0x1cb>
		if(proc_child->state != PROC_STOP){
  1037c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1037ca:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1037d0:	85 c0                	test   %eax,%eax
  1037d2:	74 19                	je     1037ed <do_put+0x1c0>
			proc_wait(proc_parent, proc_child, tf);
  1037d4:	8b 45 08             	mov    0x8(%ebp),%eax
  1037d7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1037db:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1037de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1037e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1037e5:	89 04 24             	mov    %eax,(%esp)
  1037e8:	e8 21 f4 ff ff       	call   102c0e <proc_wait>
		}
		proc_ready(proc_child);
  1037ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1037f0:	89 04 24             	mov    %eax,(%esp)
  1037f3:	e8 12 f3 ff ff       	call   102b0a <proc_ready>
	}
	
	trap_return(tf);
  1037f8:	8b 45 08             	mov    0x8(%ebp),%eax
  1037fb:	89 04 24             	mov    %eax,(%esp)
  1037fe:	e8 ed 58 00 00       	call   1090f0 <trap_return>

00103803 <do_get>:
}

static void
do_get(trapframe *tf, uint32_t cmd)
{	
  103803:	55                   	push   %ebp
  103804:	89 e5                	mov    %esp,%ebp
  103806:	83 ec 28             	sub    $0x28,%esp
	procstate* ps = (procstate*)tf->regs.ebx;
  103809:	8b 45 08             	mov    0x8(%ebp),%eax
  10380c:	8b 40 10             	mov    0x10(%eax),%eax
  10380f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint16_t child_num = tf->regs.edx;
  103812:	8b 45 08             	mov    0x8(%ebp),%eax
  103815:	8b 40 14             	mov    0x14(%eax),%eax
  103818:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
	proc* proc_parent = proc_cur();
  10381c:	e8 f1 fc ff ff       	call   103512 <cpu_cur>
  103821:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103827:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  10382a:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  10382e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103831:	83 c2 0c             	add    $0xc,%edx
  103834:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
  103838:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(proc_child->state != PROC_STOP)
  10383b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10383e:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  103844:	85 c0                	test   %eax,%eax
  103846:	74 19                	je     103861 <do_get+0x5e>
		proc_wait(proc_parent, proc_child, tf);
  103848:	8b 45 08             	mov    0x8(%ebp),%eax
  10384b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10384f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103852:	89 44 24 04          	mov    %eax,0x4(%esp)
  103856:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103859:	89 04 24             	mov    %eax,(%esp)
  10385c:	e8 ad f3 ff ff       	call   102c0e <proc_wait>

	if((cmd & SYS_TYPE) == SYS_REGS){
		memcpy(&ps->tf, &(proc_child->sv.tf), sizeof(struct trapframe));
	}

	trap_return(tf);
  103861:	8b 45 08             	mov    0x8(%ebp),%eax
  103864:	89 04 24             	mov    %eax,(%esp)
  103867:	e8 84 58 00 00       	call   1090f0 <trap_return>

0010386c <do_ret>:
}

static void
do_ret(trapframe *tf, uint32_t cmd)
{	
  10386c:	55                   	push   %ebp
  10386d:	89 e5                	mov    %esp,%ebp
  10386f:	83 ec 18             	sub    $0x18,%esp
	proc_ret(tf, 1);
  103872:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103879:	00 
  10387a:	8b 45 08             	mov    0x8(%ebp),%eax
  10387d:	89 04 24             	mov    %eax,(%esp)
  103880:	e8 a5 f5 ff ff       	call   102e2a <proc_ret>

00103885 <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  103885:	55                   	push   %ebp
  103886:	89 e5                	mov    %esp,%ebp
  103888:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  10388b:	8b 45 08             	mov    0x8(%ebp),%eax
  10388e:	8b 40 1c             	mov    0x1c(%eax),%eax
  103891:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  103894:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103897:	83 e0 0f             	and    $0xf,%eax
  10389a:	83 f8 01             	cmp    $0x1,%eax
  10389d:	74 25                	je     1038c4 <syscall+0x3f>
  10389f:	83 f8 01             	cmp    $0x1,%eax
  1038a2:	72 0c                	jb     1038b0 <syscall+0x2b>
  1038a4:	83 f8 02             	cmp    $0x2,%eax
  1038a7:	74 2f                	je     1038d8 <syscall+0x53>
  1038a9:	83 f8 03             	cmp    $0x3,%eax
  1038ac:	74 3e                	je     1038ec <syscall+0x67>
	case SYS_PUT:	 do_put(tf, cmd); break;
	case SYS_GET:	 do_get(tf, cmd); break;
	case SYS_RET:	 do_ret(tf, cmd); break;
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
  1038ae:	eb 4f                	jmp    1038ff <syscall+0x7a>
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:	 do_cputs(tf, cmd); break;
  1038b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1038b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1038b7:	8b 45 08             	mov    0x8(%ebp),%eax
  1038ba:	89 04 24             	mov    %eax,(%esp)
  1038bd:	e8 44 fd ff ff       	call   103606 <do_cputs>
  1038c2:	eb 3b                	jmp    1038ff <syscall+0x7a>
	case SYS_PUT:	 do_put(tf, cmd); break;
  1038c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1038c7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1038cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1038ce:	89 04 24             	mov    %eax,(%esp)
  1038d1:	e8 57 fd ff ff       	call   10362d <do_put>
  1038d6:	eb 27                	jmp    1038ff <syscall+0x7a>
	case SYS_GET:	 do_get(tf, cmd); break;
  1038d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1038db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1038df:	8b 45 08             	mov    0x8(%ebp),%eax
  1038e2:	89 04 24             	mov    %eax,(%esp)
  1038e5:	e8 19 ff ff ff       	call   103803 <do_get>
  1038ea:	eb 13                	jmp    1038ff <syscall+0x7a>
	case SYS_RET:	 do_ret(tf, cmd); break;
  1038ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1038ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1038f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1038f6:	89 04 24             	mov    %eax,(%esp)
  1038f9:	e8 6e ff ff ff       	call   10386c <do_ret>
  1038fe:	90                   	nop
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
	}
}
  1038ff:	c9                   	leave  
  103900:	c3                   	ret    

00103901 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  103901:	55                   	push   %ebp
  103902:	89 e5                	mov    %esp,%ebp
  103904:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  103907:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  10390e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103911:	0f b7 00             	movzwl (%eax),%eax
  103914:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  103918:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10391b:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  103920:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103923:	0f b7 00             	movzwl (%eax),%eax
  103926:	66 3d 5a a5          	cmp    $0xa55a,%ax
  10392a:	74 13                	je     10393f <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  10392c:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  103933:	c7 05 18 f3 10 00 b4 	movl   $0x3b4,0x10f318
  10393a:	03 00 00 
  10393d:	eb 14                	jmp    103953 <video_init+0x52>
	} else {
		*cp = was;
  10393f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103942:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  103946:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  103949:	c7 05 18 f3 10 00 d4 	movl   $0x3d4,0x10f318
  103950:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  103953:	a1 18 f3 10 00       	mov    0x10f318,%eax
  103958:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10395b:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10395f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  103963:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103966:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  103967:	a1 18 f3 10 00       	mov    0x10f318,%eax
  10396c:	83 c0 01             	add    $0x1,%eax
  10396f:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103972:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103975:	89 c2                	mov    %eax,%edx
  103977:	ec                   	in     (%dx),%al
  103978:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10397b:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  10397f:	0f b6 c0             	movzbl %al,%eax
  103982:	c1 e0 08             	shl    $0x8,%eax
  103985:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  103988:	a1 18 f3 10 00       	mov    0x10f318,%eax
  10398d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  103990:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103994:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103998:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10399b:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  10399c:	a1 18 f3 10 00       	mov    0x10f318,%eax
  1039a1:	83 c0 01             	add    $0x1,%eax
  1039a4:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1039a7:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1039aa:	89 c2                	mov    %eax,%edx
  1039ac:	ec                   	in     (%dx),%al
  1039ad:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  1039b0:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  1039b4:	0f b6 c0             	movzbl %al,%eax
  1039b7:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  1039ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1039bd:	a3 1c f3 10 00       	mov    %eax,0x10f31c
	crt_pos = pos;
  1039c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1039c5:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
}
  1039cb:	c9                   	leave  
  1039cc:	c3                   	ret    

001039cd <video_putc>:



void
video_putc(int c)
{
  1039cd:	55                   	push   %ebp
  1039ce:	89 e5                	mov    %esp,%ebp
  1039d0:	53                   	push   %ebx
  1039d1:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  1039d4:	8b 45 08             	mov    0x8(%ebp),%eax
  1039d7:	b0 00                	mov    $0x0,%al
  1039d9:	85 c0                	test   %eax,%eax
  1039db:	75 07                	jne    1039e4 <video_putc+0x17>
		c |= 0x0700;
  1039dd:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  1039e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1039e7:	25 ff 00 00 00       	and    $0xff,%eax
  1039ec:	83 f8 09             	cmp    $0x9,%eax
  1039ef:	0f 84 ae 00 00 00    	je     103aa3 <video_putc+0xd6>
  1039f5:	83 f8 09             	cmp    $0x9,%eax
  1039f8:	7f 0a                	jg     103a04 <video_putc+0x37>
  1039fa:	83 f8 08             	cmp    $0x8,%eax
  1039fd:	74 14                	je     103a13 <video_putc+0x46>
  1039ff:	e9 dd 00 00 00       	jmp    103ae1 <video_putc+0x114>
  103a04:	83 f8 0a             	cmp    $0xa,%eax
  103a07:	74 4e                	je     103a57 <video_putc+0x8a>
  103a09:	83 f8 0d             	cmp    $0xd,%eax
  103a0c:	74 59                	je     103a67 <video_putc+0x9a>
  103a0e:	e9 ce 00 00 00       	jmp    103ae1 <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  103a13:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103a1a:	66 85 c0             	test   %ax,%ax
  103a1d:	0f 84 e4 00 00 00    	je     103b07 <video_putc+0x13a>
			crt_pos--;
  103a23:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103a2a:	83 e8 01             	sub    $0x1,%eax
  103a2d:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  103a33:	a1 1c f3 10 00       	mov    0x10f31c,%eax
  103a38:	0f b7 15 20 f3 10 00 	movzwl 0x10f320,%edx
  103a3f:	0f b7 d2             	movzwl %dx,%edx
  103a42:	01 d2                	add    %edx,%edx
  103a44:	8d 14 10             	lea    (%eax,%edx,1),%edx
  103a47:	8b 45 08             	mov    0x8(%ebp),%eax
  103a4a:	b0 00                	mov    $0x0,%al
  103a4c:	83 c8 20             	or     $0x20,%eax
  103a4f:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  103a52:	e9 b1 00 00 00       	jmp    103b08 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  103a57:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103a5e:	83 c0 50             	add    $0x50,%eax
  103a61:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  103a67:	0f b7 1d 20 f3 10 00 	movzwl 0x10f320,%ebx
  103a6e:	0f b7 0d 20 f3 10 00 	movzwl 0x10f320,%ecx
  103a75:	0f b7 c1             	movzwl %cx,%eax
  103a78:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  103a7e:	c1 e8 10             	shr    $0x10,%eax
  103a81:	89 c2                	mov    %eax,%edx
  103a83:	66 c1 ea 06          	shr    $0x6,%dx
  103a87:	89 d0                	mov    %edx,%eax
  103a89:	c1 e0 02             	shl    $0x2,%eax
  103a8c:	01 d0                	add    %edx,%eax
  103a8e:	c1 e0 04             	shl    $0x4,%eax
  103a91:	89 ca                	mov    %ecx,%edx
  103a93:	66 29 c2             	sub    %ax,%dx
  103a96:	89 d8                	mov    %ebx,%eax
  103a98:	66 29 d0             	sub    %dx,%ax
  103a9b:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
		break;
  103aa1:	eb 65                	jmp    103b08 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  103aa3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103aaa:	e8 1e ff ff ff       	call   1039cd <video_putc>
		video_putc(' ');
  103aaf:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103ab6:	e8 12 ff ff ff       	call   1039cd <video_putc>
		video_putc(' ');
  103abb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103ac2:	e8 06 ff ff ff       	call   1039cd <video_putc>
		video_putc(' ');
  103ac7:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103ace:	e8 fa fe ff ff       	call   1039cd <video_putc>
		video_putc(' ');
  103ad3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103ada:	e8 ee fe ff ff       	call   1039cd <video_putc>
		break;
  103adf:	eb 27                	jmp    103b08 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  103ae1:	8b 15 1c f3 10 00    	mov    0x10f31c,%edx
  103ae7:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103aee:	0f b7 c8             	movzwl %ax,%ecx
  103af1:	01 c9                	add    %ecx,%ecx
  103af3:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  103af6:	8b 55 08             	mov    0x8(%ebp),%edx
  103af9:	66 89 11             	mov    %dx,(%ecx)
  103afc:	83 c0 01             	add    $0x1,%eax
  103aff:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
  103b05:	eb 01                	jmp    103b08 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  103b07:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  103b08:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103b0f:	66 3d cf 07          	cmp    $0x7cf,%ax
  103b13:	76 5b                	jbe    103b70 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  103b15:	a1 1c f3 10 00       	mov    0x10f31c,%eax
  103b1a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  103b20:	a1 1c f3 10 00       	mov    0x10f31c,%eax
  103b25:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  103b2c:	00 
  103b2d:	89 54 24 04          	mov    %edx,0x4(%esp)
  103b31:	89 04 24             	mov    %eax,(%esp)
  103b34:	e8 96 15 00 00       	call   1050cf <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103b39:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  103b40:	eb 15                	jmp    103b57 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  103b42:	a1 1c f3 10 00       	mov    0x10f31c,%eax
  103b47:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103b4a:	01 d2                	add    %edx,%edx
  103b4c:	01 d0                	add    %edx,%eax
  103b4e:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103b53:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  103b57:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  103b5e:	7e e2                	jle    103b42 <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  103b60:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103b67:	83 e8 50             	sub    $0x50,%eax
  103b6a:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  103b70:	a1 18 f3 10 00       	mov    0x10f318,%eax
  103b75:	89 45 dc             	mov    %eax,-0x24(%ebp)
  103b78:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103b7c:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103b80:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103b83:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  103b84:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103b8b:	66 c1 e8 08          	shr    $0x8,%ax
  103b8f:	0f b6 c0             	movzbl %al,%eax
  103b92:	8b 15 18 f3 10 00    	mov    0x10f318,%edx
  103b98:	83 c2 01             	add    $0x1,%edx
  103b9b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  103b9e:	88 45 e3             	mov    %al,-0x1d(%ebp)
  103ba1:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103ba5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103ba8:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  103ba9:	a1 18 f3 10 00       	mov    0x10f318,%eax
  103bae:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103bb1:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  103bb5:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  103bb9:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103bbc:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  103bbd:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103bc4:	0f b6 c0             	movzbl %al,%eax
  103bc7:	8b 15 18 f3 10 00    	mov    0x10f318,%edx
  103bcd:	83 c2 01             	add    $0x1,%edx
  103bd0:	89 55 f4             	mov    %edx,-0xc(%ebp)
  103bd3:	88 45 f3             	mov    %al,-0xd(%ebp)
  103bd6:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103bda:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103bdd:	ee                   	out    %al,(%dx)
}
  103bde:	83 c4 44             	add    $0x44,%esp
  103be1:	5b                   	pop    %ebx
  103be2:	5d                   	pop    %ebp
  103be3:	c3                   	ret    

00103be4 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  103be4:	55                   	push   %ebp
  103be5:	89 e5                	mov    %esp,%ebp
  103be7:	83 ec 38             	sub    $0x38,%esp
  103bea:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103bf1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103bf4:	89 c2                	mov    %eax,%edx
  103bf6:	ec                   	in     (%dx),%al
  103bf7:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  103bfa:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  103bfe:	0f b6 c0             	movzbl %al,%eax
  103c01:	83 e0 01             	and    $0x1,%eax
  103c04:	85 c0                	test   %eax,%eax
  103c06:	75 0a                	jne    103c12 <kbd_proc_data+0x2e>
		return -1;
  103c08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  103c0d:	e9 5a 01 00 00       	jmp    103d6c <kbd_proc_data+0x188>
  103c12:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103c19:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103c1c:	89 c2                	mov    %eax,%edx
  103c1e:	ec                   	in     (%dx),%al
  103c1f:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  103c22:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  103c26:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  103c29:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  103c2d:	75 17                	jne    103c46 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  103c2f:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103c34:	83 c8 40             	or     $0x40,%eax
  103c37:	a3 24 f3 10 00       	mov    %eax,0x10f324
		return 0;
  103c3c:	b8 00 00 00 00       	mov    $0x0,%eax
  103c41:	e9 26 01 00 00       	jmp    103d6c <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  103c46:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103c4a:	84 c0                	test   %al,%al
  103c4c:	79 47                	jns    103c95 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  103c4e:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103c53:	83 e0 40             	and    $0x40,%eax
  103c56:	85 c0                	test   %eax,%eax
  103c58:	75 09                	jne    103c63 <kbd_proc_data+0x7f>
  103c5a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103c5e:	83 e0 7f             	and    $0x7f,%eax
  103c61:	eb 04                	jmp    103c67 <kbd_proc_data+0x83>
  103c63:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103c67:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  103c6a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103c6e:	0f b6 80 20 91 10 00 	movzbl 0x109120(%eax),%eax
  103c75:	83 c8 40             	or     $0x40,%eax
  103c78:	0f b6 c0             	movzbl %al,%eax
  103c7b:	f7 d0                	not    %eax
  103c7d:	89 c2                	mov    %eax,%edx
  103c7f:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103c84:	21 d0                	and    %edx,%eax
  103c86:	a3 24 f3 10 00       	mov    %eax,0x10f324
		return 0;
  103c8b:	b8 00 00 00 00       	mov    $0x0,%eax
  103c90:	e9 d7 00 00 00       	jmp    103d6c <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  103c95:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103c9a:	83 e0 40             	and    $0x40,%eax
  103c9d:	85 c0                	test   %eax,%eax
  103c9f:	74 11                	je     103cb2 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  103ca1:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  103ca5:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103caa:	83 e0 bf             	and    $0xffffffbf,%eax
  103cad:	a3 24 f3 10 00       	mov    %eax,0x10f324
	}

	shift |= shiftcode[data];
  103cb2:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103cb6:	0f b6 80 20 91 10 00 	movzbl 0x109120(%eax),%eax
  103cbd:	0f b6 d0             	movzbl %al,%edx
  103cc0:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103cc5:	09 d0                	or     %edx,%eax
  103cc7:	a3 24 f3 10 00       	mov    %eax,0x10f324
	shift ^= togglecode[data];
  103ccc:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103cd0:	0f b6 80 20 92 10 00 	movzbl 0x109220(%eax),%eax
  103cd7:	0f b6 d0             	movzbl %al,%edx
  103cda:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103cdf:	31 d0                	xor    %edx,%eax
  103ce1:	a3 24 f3 10 00       	mov    %eax,0x10f324

	c = charcode[shift & (CTL | SHIFT)][data];
  103ce6:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103ceb:	83 e0 03             	and    $0x3,%eax
  103cee:	8b 14 85 20 96 10 00 	mov    0x109620(,%eax,4),%edx
  103cf5:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103cf9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  103cfc:	0f b6 00             	movzbl (%eax),%eax
  103cff:	0f b6 c0             	movzbl %al,%eax
  103d02:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  103d05:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103d0a:	83 e0 08             	and    $0x8,%eax
  103d0d:	85 c0                	test   %eax,%eax
  103d0f:	74 22                	je     103d33 <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  103d11:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  103d15:	7e 0c                	jle    103d23 <kbd_proc_data+0x13f>
  103d17:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  103d1b:	7f 06                	jg     103d23 <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  103d1d:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  103d21:	eb 10                	jmp    103d33 <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  103d23:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  103d27:	7e 0a                	jle    103d33 <kbd_proc_data+0x14f>
  103d29:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  103d2d:	7f 04                	jg     103d33 <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  103d2f:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  103d33:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103d38:	f7 d0                	not    %eax
  103d3a:	83 e0 06             	and    $0x6,%eax
  103d3d:	85 c0                	test   %eax,%eax
  103d3f:	75 28                	jne    103d69 <kbd_proc_data+0x185>
  103d41:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  103d48:	75 1f                	jne    103d69 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  103d4a:	c7 04 24 13 64 10 00 	movl   $0x106413,(%esp)
  103d51:	e8 20 11 00 00       	call   104e76 <cprintf>
  103d56:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  103d5d:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103d61:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103d65:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103d68:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  103d69:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  103d6c:	c9                   	leave  
  103d6d:	c3                   	ret    

00103d6e <kbd_intr>:

void
kbd_intr(void)
{
  103d6e:	55                   	push   %ebp
  103d6f:	89 e5                	mov    %esp,%ebp
  103d71:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  103d74:	c7 04 24 e4 3b 10 00 	movl   $0x103be4,(%esp)
  103d7b:	e8 24 c5 ff ff       	call   1002a4 <cons_intr>
}
  103d80:	c9                   	leave  
  103d81:	c3                   	ret    

00103d82 <kbd_init>:

void
kbd_init(void)
{
  103d82:	55                   	push   %ebp
  103d83:	89 e5                	mov    %esp,%ebp
}
  103d85:	5d                   	pop    %ebp
  103d86:	c3                   	ret    

00103d87 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  103d87:	55                   	push   %ebp
  103d88:	89 e5                	mov    %esp,%ebp
  103d8a:	83 ec 20             	sub    $0x20,%esp
  103d8d:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103d94:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103d97:	89 c2                	mov    %eax,%edx
  103d99:	ec                   	in     (%dx),%al
  103d9a:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  103d9d:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103da4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103da7:	89 c2                	mov    %eax,%edx
  103da9:	ec                   	in     (%dx),%al
  103daa:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  103dad:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103db4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103db7:	89 c2                	mov    %eax,%edx
  103db9:	ec                   	in     (%dx),%al
  103dba:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  103dbd:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103dc4:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103dc7:	89 c2                	mov    %eax,%edx
  103dc9:	ec                   	in     (%dx),%al
  103dca:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  103dcd:	c9                   	leave  
  103dce:	c3                   	ret    

00103dcf <serial_proc_data>:

static int
serial_proc_data(void)
{
  103dcf:	55                   	push   %ebp
  103dd0:	89 e5                	mov    %esp,%ebp
  103dd2:	83 ec 10             	sub    $0x10,%esp
  103dd5:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  103ddc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103ddf:	89 c2                	mov    %eax,%edx
  103de1:	ec                   	in     (%dx),%al
  103de2:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  103de5:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  103de9:	0f b6 c0             	movzbl %al,%eax
  103dec:	83 e0 01             	and    $0x1,%eax
  103def:	85 c0                	test   %eax,%eax
  103df1:	75 07                	jne    103dfa <serial_proc_data+0x2b>
		return -1;
  103df3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  103df8:	eb 17                	jmp    103e11 <serial_proc_data+0x42>
  103dfa:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103e01:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103e04:	89 c2                	mov    %eax,%edx
  103e06:	ec                   	in     (%dx),%al
  103e07:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  103e0a:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  103e0e:	0f b6 c0             	movzbl %al,%eax
}
  103e11:	c9                   	leave  
  103e12:	c3                   	ret    

00103e13 <serial_intr>:

void
serial_intr(void)
{
  103e13:	55                   	push   %ebp
  103e14:	89 e5                	mov    %esp,%ebp
  103e16:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  103e19:	a1 e8 fa 30 00       	mov    0x30fae8,%eax
  103e1e:	85 c0                	test   %eax,%eax
  103e20:	74 0c                	je     103e2e <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  103e22:	c7 04 24 cf 3d 10 00 	movl   $0x103dcf,(%esp)
  103e29:	e8 76 c4 ff ff       	call   1002a4 <cons_intr>
}
  103e2e:	c9                   	leave  
  103e2f:	c3                   	ret    

00103e30 <serial_putc>:

void
serial_putc(int c)
{
  103e30:	55                   	push   %ebp
  103e31:	89 e5                	mov    %esp,%ebp
  103e33:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  103e36:	a1 e8 fa 30 00       	mov    0x30fae8,%eax
  103e3b:	85 c0                	test   %eax,%eax
  103e3d:	74 53                	je     103e92 <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  103e3f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103e46:	eb 09                	jmp    103e51 <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  103e48:	e8 3a ff ff ff       	call   103d87 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  103e4d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103e51:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103e58:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e5b:	89 c2                	mov    %eax,%edx
  103e5d:	ec                   	in     (%dx),%al
  103e5e:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  103e61:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  103e65:	0f b6 c0             	movzbl %al,%eax
  103e68:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  103e6b:	85 c0                	test   %eax,%eax
  103e6d:	75 09                	jne    103e78 <serial_putc+0x48>
  103e6f:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  103e76:	7e d0                	jle    103e48 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  103e78:	8b 45 08             	mov    0x8(%ebp),%eax
  103e7b:	0f b6 c0             	movzbl %al,%eax
  103e7e:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  103e85:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103e88:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  103e8c:	8b 55 fc             	mov    -0x4(%ebp),%edx
  103e8f:	ee                   	out    %al,(%dx)
  103e90:	eb 01                	jmp    103e93 <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  103e92:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  103e93:	c9                   	leave  
  103e94:	c3                   	ret    

00103e95 <serial_init>:

void
serial_init(void)
{
  103e95:	55                   	push   %ebp
  103e96:	89 e5                	mov    %esp,%ebp
  103e98:	83 ec 50             	sub    $0x50,%esp
  103e9b:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  103ea2:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  103ea6:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  103eaa:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  103ead:	ee                   	out    %al,(%dx)
  103eae:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  103eb5:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  103eb9:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  103ebd:	8b 55 bc             	mov    -0x44(%ebp),%edx
  103ec0:	ee                   	out    %al,(%dx)
  103ec1:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  103ec8:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  103ecc:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  103ed0:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  103ed3:	ee                   	out    %al,(%dx)
  103ed4:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  103edb:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  103edf:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  103ee3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  103ee6:	ee                   	out    %al,(%dx)
  103ee7:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  103eee:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  103ef2:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  103ef6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103ef9:	ee                   	out    %al,(%dx)
  103efa:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  103f01:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  103f05:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103f09:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103f0c:	ee                   	out    %al,(%dx)
  103f0d:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  103f14:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  103f18:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103f1c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103f1f:	ee                   	out    %al,(%dx)
  103f20:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103f27:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103f2a:	89 c2                	mov    %eax,%edx
  103f2c:	ec                   	in     (%dx),%al
  103f2d:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  103f30:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  103f34:	3c ff                	cmp    $0xff,%al
  103f36:	0f 95 c0             	setne  %al
  103f39:	0f b6 c0             	movzbl %al,%eax
  103f3c:	a3 e8 fa 30 00       	mov    %eax,0x30fae8
  103f41:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103f48:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103f4b:	89 c2                	mov    %eax,%edx
  103f4d:	ec                   	in     (%dx),%al
  103f4e:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  103f51:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103f58:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103f5b:	89 c2                	mov    %eax,%edx
  103f5d:	ec                   	in     (%dx),%al
  103f5e:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  103f61:	c9                   	leave  
  103f62:	c3                   	ret    

00103f63 <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  103f63:	55                   	push   %ebp
  103f64:	89 e5                	mov    %esp,%ebp
  103f66:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  103f6c:	a1 28 f3 10 00       	mov    0x10f328,%eax
  103f71:	85 c0                	test   %eax,%eax
  103f73:	0f 85 35 01 00 00    	jne    1040ae <pic_init+0x14b>
		return;
	didinit = 1;
  103f79:	c7 05 28 f3 10 00 01 	movl   $0x1,0x10f328
  103f80:	00 00 00 
  103f83:	c7 45 8c 21 00 00 00 	movl   $0x21,-0x74(%ebp)
  103f8a:	c6 45 8b ff          	movb   $0xff,-0x75(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103f8e:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  103f92:	8b 55 8c             	mov    -0x74(%ebp),%edx
  103f95:	ee                   	out    %al,(%dx)
  103f96:	c7 45 94 a1 00 00 00 	movl   $0xa1,-0x6c(%ebp)
  103f9d:	c6 45 93 ff          	movb   $0xff,-0x6d(%ebp)
  103fa1:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  103fa5:	8b 55 94             	mov    -0x6c(%ebp),%edx
  103fa8:	ee                   	out    %al,(%dx)
  103fa9:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  103fb0:	c6 45 9b 11          	movb   $0x11,-0x65(%ebp)
  103fb4:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  103fb8:	8b 55 9c             	mov    -0x64(%ebp),%edx
  103fbb:	ee                   	out    %al,(%dx)
  103fbc:	c7 45 a4 21 00 00 00 	movl   $0x21,-0x5c(%ebp)
  103fc3:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
  103fc7:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  103fcb:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  103fce:	ee                   	out    %al,(%dx)
  103fcf:	c7 45 ac 21 00 00 00 	movl   $0x21,-0x54(%ebp)
  103fd6:	c6 45 ab 04          	movb   $0x4,-0x55(%ebp)
  103fda:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  103fde:	8b 55 ac             	mov    -0x54(%ebp),%edx
  103fe1:	ee                   	out    %al,(%dx)
  103fe2:	c7 45 b4 21 00 00 00 	movl   $0x21,-0x4c(%ebp)
  103fe9:	c6 45 b3 03          	movb   $0x3,-0x4d(%ebp)
  103fed:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  103ff1:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  103ff4:	ee                   	out    %al,(%dx)
  103ff5:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
  103ffc:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
  104000:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  104004:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104007:	ee                   	out    %al,(%dx)
  104008:	c7 45 c4 a1 00 00 00 	movl   $0xa1,-0x3c(%ebp)
  10400f:	c6 45 c3 28          	movb   $0x28,-0x3d(%ebp)
  104013:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  104017:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  10401a:	ee                   	out    %al,(%dx)
  10401b:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
  104022:	c6 45 cb 02          	movb   $0x2,-0x35(%ebp)
  104026:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  10402a:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10402d:	ee                   	out    %al,(%dx)
  10402e:	c7 45 d4 a1 00 00 00 	movl   $0xa1,-0x2c(%ebp)
  104035:	c6 45 d3 01          	movb   $0x1,-0x2d(%ebp)
  104039:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  10403d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104040:	ee                   	out    %al,(%dx)
  104041:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
  104048:	c6 45 db 68          	movb   $0x68,-0x25(%ebp)
  10404c:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  104050:	8b 55 dc             	mov    -0x24(%ebp),%edx
  104053:	ee                   	out    %al,(%dx)
  104054:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  10405b:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  10405f:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  104063:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  104066:	ee                   	out    %al,(%dx)
  104067:	c7 45 ec a0 00 00 00 	movl   $0xa0,-0x14(%ebp)
  10406e:	c6 45 eb 68          	movb   $0x68,-0x15(%ebp)
  104072:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  104076:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104079:	ee                   	out    %al,(%dx)
  10407a:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
  104081:	c6 45 f3 0a          	movb   $0xa,-0xd(%ebp)
  104085:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104089:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10408c:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  10408d:	0f b7 05 30 96 10 00 	movzwl 0x109630,%eax
  104094:	66 83 f8 ff          	cmp    $0xffff,%ax
  104098:	74 15                	je     1040af <pic_init+0x14c>
		pic_setmask(irqmask);
  10409a:	0f b7 05 30 96 10 00 	movzwl 0x109630,%eax
  1040a1:	0f b7 c0             	movzwl %ax,%eax
  1040a4:	89 04 24             	mov    %eax,(%esp)
  1040a7:	e8 05 00 00 00       	call   1040b1 <pic_setmask>
  1040ac:	eb 01                	jmp    1040af <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  1040ae:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  1040af:	c9                   	leave  
  1040b0:	c3                   	ret    

001040b1 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  1040b1:	55                   	push   %ebp
  1040b2:	89 e5                	mov    %esp,%ebp
  1040b4:	83 ec 14             	sub    $0x14,%esp
  1040b7:	8b 45 08             	mov    0x8(%ebp),%eax
  1040ba:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  1040be:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1040c2:	66 a3 30 96 10 00    	mov    %ax,0x109630
	outb(IO_PIC1+1, (char)mask);
  1040c8:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1040cc:	0f b6 c0             	movzbl %al,%eax
  1040cf:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  1040d6:	88 45 f3             	mov    %al,-0xd(%ebp)
  1040d9:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1040dd:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1040e0:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  1040e1:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1040e5:	66 c1 e8 08          	shr    $0x8,%ax
  1040e9:	0f b6 c0             	movzbl %al,%eax
  1040ec:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
  1040f3:	88 45 fb             	mov    %al,-0x5(%ebp)
  1040f6:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1040fa:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1040fd:	ee                   	out    %al,(%dx)
}
  1040fe:	c9                   	leave  
  1040ff:	c3                   	ret    

00104100 <pic_enable>:

void
pic_enable(int irq)
{
  104100:	55                   	push   %ebp
  104101:	89 e5                	mov    %esp,%ebp
  104103:	53                   	push   %ebx
  104104:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  104107:	8b 45 08             	mov    0x8(%ebp),%eax
  10410a:	ba 01 00 00 00       	mov    $0x1,%edx
  10410f:	89 d3                	mov    %edx,%ebx
  104111:	89 c1                	mov    %eax,%ecx
  104113:	d3 e3                	shl    %cl,%ebx
  104115:	89 d8                	mov    %ebx,%eax
  104117:	89 c2                	mov    %eax,%edx
  104119:	f7 d2                	not    %edx
  10411b:	0f b7 05 30 96 10 00 	movzwl 0x109630,%eax
  104122:	21 d0                	and    %edx,%eax
  104124:	0f b7 c0             	movzwl %ax,%eax
  104127:	89 04 24             	mov    %eax,(%esp)
  10412a:	e8 82 ff ff ff       	call   1040b1 <pic_setmask>
}
  10412f:	83 c4 04             	add    $0x4,%esp
  104132:	5b                   	pop    %ebx
  104133:	5d                   	pop    %ebp
  104134:	c3                   	ret    

00104135 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  104135:	55                   	push   %ebp
  104136:	89 e5                	mov    %esp,%ebp
  104138:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10413b:	8b 45 08             	mov    0x8(%ebp),%eax
  10413e:	0f b6 c0             	movzbl %al,%eax
  104141:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  104148:	88 45 f3             	mov    %al,-0xd(%ebp)
  10414b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10414f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104152:	ee                   	out    %al,(%dx)
  104153:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10415a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10415d:	89 c2                	mov    %eax,%edx
  10415f:	ec                   	in     (%dx),%al
  104160:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  104163:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  104167:	0f b6 c0             	movzbl %al,%eax
}
  10416a:	c9                   	leave  
  10416b:	c3                   	ret    

0010416c <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  10416c:	55                   	push   %ebp
  10416d:	89 e5                	mov    %esp,%ebp
  10416f:	53                   	push   %ebx
  104170:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  104173:	8b 45 08             	mov    0x8(%ebp),%eax
  104176:	89 04 24             	mov    %eax,(%esp)
  104179:	e8 b7 ff ff ff       	call   104135 <nvram_read>
  10417e:	89 c3                	mov    %eax,%ebx
  104180:	8b 45 08             	mov    0x8(%ebp),%eax
  104183:	83 c0 01             	add    $0x1,%eax
  104186:	89 04 24             	mov    %eax,(%esp)
  104189:	e8 a7 ff ff ff       	call   104135 <nvram_read>
  10418e:	c1 e0 08             	shl    $0x8,%eax
  104191:	09 d8                	or     %ebx,%eax
}
  104193:	83 c4 04             	add    $0x4,%esp
  104196:	5b                   	pop    %ebx
  104197:	5d                   	pop    %ebp
  104198:	c3                   	ret    

00104199 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  104199:	55                   	push   %ebp
  10419a:	89 e5                	mov    %esp,%ebp
  10419c:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10419f:	8b 45 08             	mov    0x8(%ebp),%eax
  1041a2:	0f b6 c0             	movzbl %al,%eax
  1041a5:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1041ac:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1041af:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1041b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1041b6:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  1041b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1041ba:	0f b6 c0             	movzbl %al,%eax
  1041bd:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  1041c4:	88 45 fb             	mov    %al,-0x5(%ebp)
  1041c7:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1041cb:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1041ce:	ee                   	out    %al,(%dx)
}
  1041cf:	c9                   	leave  
  1041d0:	c3                   	ret    

001041d1 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1041d1:	55                   	push   %ebp
  1041d2:	89 e5                	mov    %esp,%ebp
  1041d4:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1041d7:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1041da:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1041dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1041e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1041e3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1041e8:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1041eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1041ee:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1041f4:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1041f9:	74 24                	je     10421f <cpu_cur+0x4e>
  1041fb:	c7 44 24 0c 1f 64 10 	movl   $0x10641f,0xc(%esp)
  104202:	00 
  104203:	c7 44 24 08 35 64 10 	movl   $0x106435,0x8(%esp)
  10420a:	00 
  10420b:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  104212:	00 
  104213:	c7 04 24 4a 64 10 00 	movl   $0x10644a,(%esp)
  10421a:	e8 50 c2 ff ff       	call   10046f <debug_panic>
	return c;
  10421f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  104222:	c9                   	leave  
  104223:	c3                   	ret    

00104224 <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  104224:	55                   	push   %ebp
  104225:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  104227:	a1 ec fa 30 00       	mov    0x30faec,%eax
  10422c:	8b 55 08             	mov    0x8(%ebp),%edx
  10422f:	c1 e2 02             	shl    $0x2,%edx
  104232:	8d 14 10             	lea    (%eax,%edx,1),%edx
  104235:	8b 45 0c             	mov    0xc(%ebp),%eax
  104238:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  10423a:	a1 ec fa 30 00       	mov    0x30faec,%eax
  10423f:	83 c0 20             	add    $0x20,%eax
  104242:	8b 00                	mov    (%eax),%eax
}
  104244:	5d                   	pop    %ebp
  104245:	c3                   	ret    

00104246 <lapic_init>:

void
lapic_init()
{
  104246:	55                   	push   %ebp
  104247:	89 e5                	mov    %esp,%ebp
  104249:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  10424c:	a1 ec fa 30 00       	mov    0x30faec,%eax
  104251:	85 c0                	test   %eax,%eax
  104253:	0f 84 82 01 00 00    	je     1043db <lapic_init+0x195>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  104259:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  104260:	00 
  104261:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  104268:	e8 b7 ff ff ff       	call   104224 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  10426d:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  104274:	00 
  104275:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  10427c:	e8 a3 ff ff ff       	call   104224 <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  104281:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  104288:	00 
  104289:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  104290:	e8 8f ff ff ff       	call   104224 <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  104295:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  10429c:	00 
  10429d:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  1042a4:	e8 7b ff ff ff       	call   104224 <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  1042a9:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1042b0:	00 
  1042b1:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  1042b8:	e8 67 ff ff ff       	call   104224 <lapicw>
	lapicw(LINT1, MASKED);
  1042bd:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1042c4:	00 
  1042c5:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  1042cc:	e8 53 ff ff ff       	call   104224 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  1042d1:	a1 ec fa 30 00       	mov    0x30faec,%eax
  1042d6:	83 c0 30             	add    $0x30,%eax
  1042d9:	8b 00                	mov    (%eax),%eax
  1042db:	c1 e8 10             	shr    $0x10,%eax
  1042de:	25 ff 00 00 00       	and    $0xff,%eax
  1042e3:	83 f8 03             	cmp    $0x3,%eax
  1042e6:	76 14                	jbe    1042fc <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  1042e8:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1042ef:	00 
  1042f0:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  1042f7:	e8 28 ff ff ff       	call   104224 <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  1042fc:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  104303:	00 
  104304:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  10430b:	e8 14 ff ff ff       	call   104224 <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  104310:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  104317:	ff 
  104318:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  10431f:	e8 00 ff ff ff       	call   104224 <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  104324:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  10432b:	f0 
  10432c:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  104333:	e8 ec fe ff ff       	call   104224 <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  104338:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10433f:	00 
  104340:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  104347:	e8 d8 fe ff ff       	call   104224 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  10434c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104353:	00 
  104354:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10435b:	e8 c4 fe ff ff       	call   104224 <lapicw>
	lapicw(ESR, 0);
  104360:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104367:	00 
  104368:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10436f:	e8 b0 fe ff ff       	call   104224 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  104374:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10437b:	00 
  10437c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  104383:	e8 9c fe ff ff       	call   104224 <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  104388:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10438f:	00 
  104390:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  104397:	e8 88 fe ff ff       	call   104224 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  10439c:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  1043a3:	00 
  1043a4:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1043ab:	e8 74 fe ff ff       	call   104224 <lapicw>
	while(lapic[ICRLO] & DELIVS)
  1043b0:	a1 ec fa 30 00       	mov    0x30faec,%eax
  1043b5:	05 00 03 00 00       	add    $0x300,%eax
  1043ba:	8b 00                	mov    (%eax),%eax
  1043bc:	25 00 10 00 00       	and    $0x1000,%eax
  1043c1:	85 c0                	test   %eax,%eax
  1043c3:	75 eb                	jne    1043b0 <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  1043c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1043cc:	00 
  1043cd:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1043d4:	e8 4b fe ff ff       	call   104224 <lapicw>
  1043d9:	eb 01                	jmp    1043dc <lapic_init+0x196>

void
lapic_init()
{
	if (!lapic) 
		return;
  1043db:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  1043dc:	c9                   	leave  
  1043dd:	c3                   	ret    

001043de <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  1043de:	55                   	push   %ebp
  1043df:	89 e5                	mov    %esp,%ebp
  1043e1:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  1043e4:	a1 ec fa 30 00       	mov    0x30faec,%eax
  1043e9:	85 c0                	test   %eax,%eax
  1043eb:	74 14                	je     104401 <lapic_eoi+0x23>
		lapicw(EOI, 0);
  1043ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1043f4:	00 
  1043f5:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  1043fc:	e8 23 fe ff ff       	call   104224 <lapicw>
}
  104401:	c9                   	leave  
  104402:	c3                   	ret    

00104403 <lapic_errintr>:

void lapic_errintr(void)
{
  104403:	55                   	push   %ebp
  104404:	89 e5                	mov    %esp,%ebp
  104406:	53                   	push   %ebx
  104407:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  10440a:	e8 cf ff ff ff       	call   1043de <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  10440f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104416:	00 
  104417:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10441e:	e8 01 fe ff ff       	call   104224 <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  104423:	a1 ec fa 30 00       	mov    0x30faec,%eax
  104428:	05 80 02 00 00       	add    $0x280,%eax
  10442d:	8b 18                	mov    (%eax),%ebx
  10442f:	e8 9d fd ff ff       	call   1041d1 <cpu_cur>
  104434:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10443b:	0f b6 c0             	movzbl %al,%eax
  10443e:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  104442:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104446:	c7 44 24 08 57 64 10 	movl   $0x106457,0x8(%esp)
  10444d:	00 
  10444e:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  104455:	00 
  104456:	c7 04 24 71 64 10 00 	movl   $0x106471,(%esp)
  10445d:	e8 cc c0 ff ff       	call   10052e <debug_warn>
}
  104462:	83 c4 24             	add    $0x24,%esp
  104465:	5b                   	pop    %ebx
  104466:	5d                   	pop    %ebp
  104467:	c3                   	ret    

00104468 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  104468:	55                   	push   %ebp
  104469:	89 e5                	mov    %esp,%ebp
}
  10446b:	5d                   	pop    %ebp
  10446c:	c3                   	ret    

0010446d <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  10446d:	55                   	push   %ebp
  10446e:	89 e5                	mov    %esp,%ebp
  104470:	83 ec 2c             	sub    $0x2c,%esp
  104473:	8b 45 08             	mov    0x8(%ebp),%eax
  104476:	88 45 dc             	mov    %al,-0x24(%ebp)
  104479:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  104480:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  104484:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104488:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10448b:	ee                   	out    %al,(%dx)
  10448c:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  104493:	c6 45 fb 0a          	movb   $0xa,-0x5(%ebp)
  104497:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  10449b:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10449e:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  10449f:	c7 45 ec 67 04 00 00 	movl   $0x467,-0x14(%ebp)
	wrv[0] = 0;
  1044a6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1044a9:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  1044ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1044b1:	8d 50 02             	lea    0x2(%eax),%edx
  1044b4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044b7:	c1 e8 04             	shr    $0x4,%eax
  1044ba:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  1044bd:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  1044c1:	c1 e0 18             	shl    $0x18,%eax
  1044c4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044c8:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1044cf:	e8 50 fd ff ff       	call   104224 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  1044d4:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  1044db:	00 
  1044dc:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1044e3:	e8 3c fd ff ff       	call   104224 <lapicw>
	microdelay(200);
  1044e8:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1044ef:	e8 74 ff ff ff       	call   104468 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  1044f4:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  1044fb:	00 
  1044fc:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104503:	e8 1c fd ff ff       	call   104224 <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  104508:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  10450f:	e8 54 ff ff ff       	call   104468 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  104514:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  10451b:	eb 40                	jmp    10455d <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  10451d:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  104521:	c1 e0 18             	shl    $0x18,%eax
  104524:	89 44 24 04          	mov    %eax,0x4(%esp)
  104528:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10452f:	e8 f0 fc ff ff       	call   104224 <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  104534:	8b 45 0c             	mov    0xc(%ebp),%eax
  104537:	c1 e8 0c             	shr    $0xc,%eax
  10453a:	80 cc 06             	or     $0x6,%ah
  10453d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104541:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104548:	e8 d7 fc ff ff       	call   104224 <lapicw>
		microdelay(200);
  10454d:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  104554:	e8 0f ff ff ff       	call   104468 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  104559:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  10455d:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
  104561:	7e ba                	jle    10451d <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  104563:	c9                   	leave  
  104564:	c3                   	ret    

00104565 <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  104565:	55                   	push   %ebp
  104566:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  104568:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  10456d:	8b 55 08             	mov    0x8(%ebp),%edx
  104570:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  104572:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  104577:	8b 40 10             	mov    0x10(%eax),%eax
}
  10457a:	5d                   	pop    %ebp
  10457b:	c3                   	ret    

0010457c <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  10457c:	55                   	push   %ebp
  10457d:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10457f:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  104584:	8b 55 08             	mov    0x8(%ebp),%edx
  104587:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  104589:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  10458e:	8b 55 0c             	mov    0xc(%ebp),%edx
  104591:	89 50 10             	mov    %edx,0x10(%eax)
}
  104594:	5d                   	pop    %ebp
  104595:	c3                   	ret    

00104596 <ioapic_init>:

void
ioapic_init(void)
{
  104596:	55                   	push   %ebp
  104597:	89 e5                	mov    %esp,%ebp
  104599:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  10459c:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  1045a1:	85 c0                	test   %eax,%eax
  1045a3:	0f 84 fd 00 00 00    	je     1046a6 <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  1045a9:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  1045ae:	85 c0                	test   %eax,%eax
  1045b0:	75 0a                	jne    1045bc <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  1045b2:	c7 05 e0 f3 30 00 00 	movl   $0xfec00000,0x30f3e0
  1045b9:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  1045bc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1045c3:	e8 9d ff ff ff       	call   104565 <ioapic_read>
  1045c8:	c1 e8 10             	shr    $0x10,%eax
  1045cb:	25 ff 00 00 00       	and    $0xff,%eax
  1045d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  1045d3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1045da:	e8 86 ff ff ff       	call   104565 <ioapic_read>
  1045df:	c1 e8 18             	shr    $0x18,%eax
  1045e2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  1045e5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1045e9:	75 2a                	jne    104615 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  1045eb:	0f b6 05 dc f3 30 00 	movzbl 0x30f3dc,%eax
  1045f2:	0f b6 c0             	movzbl %al,%eax
  1045f5:	c1 e0 18             	shl    $0x18,%eax
  1045f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1045fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104603:	e8 74 ff ff ff       	call   10457c <ioapic_write>
		id = ioapicid;
  104608:	0f b6 05 dc f3 30 00 	movzbl 0x30f3dc,%eax
  10460f:	0f b6 c0             	movzbl %al,%eax
  104612:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  104615:	0f b6 05 dc f3 30 00 	movzbl 0x30f3dc,%eax
  10461c:	0f b6 c0             	movzbl %al,%eax
  10461f:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104622:	74 31                	je     104655 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  104624:	0f b6 05 dc f3 30 00 	movzbl 0x30f3dc,%eax
  10462b:	0f b6 c0             	movzbl %al,%eax
  10462e:	89 44 24 10          	mov    %eax,0x10(%esp)
  104632:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104635:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104639:	c7 44 24 08 80 64 10 	movl   $0x106480,0x8(%esp)
  104640:	00 
  104641:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  104648:	00 
  104649:	c7 04 24 a1 64 10 00 	movl   $0x1064a1,(%esp)
  104650:	e8 d9 be ff ff       	call   10052e <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  104655:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  10465c:	eb 3e                	jmp    10469c <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  10465e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104661:	83 c0 20             	add    $0x20,%eax
  104664:	0d 00 00 01 00       	or     $0x10000,%eax
  104669:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10466c:	83 c2 08             	add    $0x8,%edx
  10466f:	01 d2                	add    %edx,%edx
  104671:	89 44 24 04          	mov    %eax,0x4(%esp)
  104675:	89 14 24             	mov    %edx,(%esp)
  104678:	e8 ff fe ff ff       	call   10457c <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  10467d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104680:	83 c0 08             	add    $0x8,%eax
  104683:	01 c0                	add    %eax,%eax
  104685:	83 c0 01             	add    $0x1,%eax
  104688:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10468f:	00 
  104690:	89 04 24             	mov    %eax,(%esp)
  104693:	e8 e4 fe ff ff       	call   10457c <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  104698:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  10469c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10469f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1046a2:	7e ba                	jle    10465e <ioapic_init+0xc8>
  1046a4:	eb 01                	jmp    1046a7 <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  1046a6:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  1046a7:	c9                   	leave  
  1046a8:	c3                   	ret    

001046a9 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  1046a9:	55                   	push   %ebp
  1046aa:	89 e5                	mov    %esp,%ebp
  1046ac:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  1046af:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  1046b4:	85 c0                	test   %eax,%eax
  1046b6:	74 3a                	je     1046f2 <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  1046b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1046bb:	83 c0 20             	add    $0x20,%eax
  1046be:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  1046c1:	8b 55 08             	mov    0x8(%ebp),%edx
  1046c4:	83 c2 08             	add    $0x8,%edx
  1046c7:	01 d2                	add    %edx,%edx
  1046c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1046cd:	89 14 24             	mov    %edx,(%esp)
  1046d0:	e8 a7 fe ff ff       	call   10457c <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  1046d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1046d8:	83 c0 08             	add    $0x8,%eax
  1046db:	01 c0                	add    %eax,%eax
  1046dd:	83 c0 01             	add    $0x1,%eax
  1046e0:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  1046e7:	ff 
  1046e8:	89 04 24             	mov    %eax,(%esp)
  1046eb:	e8 8c fe ff ff       	call   10457c <ioapic_write>
  1046f0:	eb 01                	jmp    1046f3 <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  1046f2:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  1046f3:	c9                   	leave  
  1046f4:	c3                   	ret    

001046f5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  1046f5:	55                   	push   %ebp
  1046f6:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  1046f8:	8b 45 08             	mov    0x8(%ebp),%eax
  1046fb:	8b 40 18             	mov    0x18(%eax),%eax
  1046fe:	83 e0 02             	and    $0x2,%eax
  104701:	85 c0                	test   %eax,%eax
  104703:	74 1c                	je     104721 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  104705:	8b 45 0c             	mov    0xc(%ebp),%eax
  104708:	8b 00                	mov    (%eax),%eax
  10470a:	8d 50 08             	lea    0x8(%eax),%edx
  10470d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104710:	89 10                	mov    %edx,(%eax)
  104712:	8b 45 0c             	mov    0xc(%ebp),%eax
  104715:	8b 00                	mov    (%eax),%eax
  104717:	83 e8 08             	sub    $0x8,%eax
  10471a:	8b 50 04             	mov    0x4(%eax),%edx
  10471d:	8b 00                	mov    (%eax),%eax
  10471f:	eb 47                	jmp    104768 <getuint+0x73>
	else if (st->flags & F_L)
  104721:	8b 45 08             	mov    0x8(%ebp),%eax
  104724:	8b 40 18             	mov    0x18(%eax),%eax
  104727:	83 e0 01             	and    $0x1,%eax
  10472a:	84 c0                	test   %al,%al
  10472c:	74 1e                	je     10474c <getuint+0x57>
		return va_arg(*ap, unsigned long);
  10472e:	8b 45 0c             	mov    0xc(%ebp),%eax
  104731:	8b 00                	mov    (%eax),%eax
  104733:	8d 50 04             	lea    0x4(%eax),%edx
  104736:	8b 45 0c             	mov    0xc(%ebp),%eax
  104739:	89 10                	mov    %edx,(%eax)
  10473b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10473e:	8b 00                	mov    (%eax),%eax
  104740:	83 e8 04             	sub    $0x4,%eax
  104743:	8b 00                	mov    (%eax),%eax
  104745:	ba 00 00 00 00       	mov    $0x0,%edx
  10474a:	eb 1c                	jmp    104768 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  10474c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10474f:	8b 00                	mov    (%eax),%eax
  104751:	8d 50 04             	lea    0x4(%eax),%edx
  104754:	8b 45 0c             	mov    0xc(%ebp),%eax
  104757:	89 10                	mov    %edx,(%eax)
  104759:	8b 45 0c             	mov    0xc(%ebp),%eax
  10475c:	8b 00                	mov    (%eax),%eax
  10475e:	83 e8 04             	sub    $0x4,%eax
  104761:	8b 00                	mov    (%eax),%eax
  104763:	ba 00 00 00 00       	mov    $0x0,%edx
}
  104768:	5d                   	pop    %ebp
  104769:	c3                   	ret    

0010476a <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  10476a:	55                   	push   %ebp
  10476b:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  10476d:	8b 45 08             	mov    0x8(%ebp),%eax
  104770:	8b 40 18             	mov    0x18(%eax),%eax
  104773:	83 e0 02             	and    $0x2,%eax
  104776:	85 c0                	test   %eax,%eax
  104778:	74 1c                	je     104796 <getint+0x2c>
		return va_arg(*ap, long long);
  10477a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10477d:	8b 00                	mov    (%eax),%eax
  10477f:	8d 50 08             	lea    0x8(%eax),%edx
  104782:	8b 45 0c             	mov    0xc(%ebp),%eax
  104785:	89 10                	mov    %edx,(%eax)
  104787:	8b 45 0c             	mov    0xc(%ebp),%eax
  10478a:	8b 00                	mov    (%eax),%eax
  10478c:	83 e8 08             	sub    $0x8,%eax
  10478f:	8b 50 04             	mov    0x4(%eax),%edx
  104792:	8b 00                	mov    (%eax),%eax
  104794:	eb 47                	jmp    1047dd <getint+0x73>
	else if (st->flags & F_L)
  104796:	8b 45 08             	mov    0x8(%ebp),%eax
  104799:	8b 40 18             	mov    0x18(%eax),%eax
  10479c:	83 e0 01             	and    $0x1,%eax
  10479f:	84 c0                	test   %al,%al
  1047a1:	74 1e                	je     1047c1 <getint+0x57>
		return va_arg(*ap, long);
  1047a3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047a6:	8b 00                	mov    (%eax),%eax
  1047a8:	8d 50 04             	lea    0x4(%eax),%edx
  1047ab:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047ae:	89 10                	mov    %edx,(%eax)
  1047b0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047b3:	8b 00                	mov    (%eax),%eax
  1047b5:	83 e8 04             	sub    $0x4,%eax
  1047b8:	8b 00                	mov    (%eax),%eax
  1047ba:	89 c2                	mov    %eax,%edx
  1047bc:	c1 fa 1f             	sar    $0x1f,%edx
  1047bf:	eb 1c                	jmp    1047dd <getint+0x73>
	else
		return va_arg(*ap, int);
  1047c1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047c4:	8b 00                	mov    (%eax),%eax
  1047c6:	8d 50 04             	lea    0x4(%eax),%edx
  1047c9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047cc:	89 10                	mov    %edx,(%eax)
  1047ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047d1:	8b 00                	mov    (%eax),%eax
  1047d3:	83 e8 04             	sub    $0x4,%eax
  1047d6:	8b 00                	mov    (%eax),%eax
  1047d8:	89 c2                	mov    %eax,%edx
  1047da:	c1 fa 1f             	sar    $0x1f,%edx
}
  1047dd:	5d                   	pop    %ebp
  1047de:	c3                   	ret    

001047df <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  1047df:	55                   	push   %ebp
  1047e0:	89 e5                	mov    %esp,%ebp
  1047e2:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  1047e5:	eb 1a                	jmp    104801 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  1047e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1047ea:	8b 08                	mov    (%eax),%ecx
  1047ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1047ef:	8b 50 04             	mov    0x4(%eax),%edx
  1047f2:	8b 45 08             	mov    0x8(%ebp),%eax
  1047f5:	8b 40 08             	mov    0x8(%eax),%eax
  1047f8:	89 54 24 04          	mov    %edx,0x4(%esp)
  1047fc:	89 04 24             	mov    %eax,(%esp)
  1047ff:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  104801:	8b 45 08             	mov    0x8(%ebp),%eax
  104804:	8b 40 0c             	mov    0xc(%eax),%eax
  104807:	8d 50 ff             	lea    -0x1(%eax),%edx
  10480a:	8b 45 08             	mov    0x8(%ebp),%eax
  10480d:	89 50 0c             	mov    %edx,0xc(%eax)
  104810:	8b 45 08             	mov    0x8(%ebp),%eax
  104813:	8b 40 0c             	mov    0xc(%eax),%eax
  104816:	85 c0                	test   %eax,%eax
  104818:	79 cd                	jns    1047e7 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  10481a:	c9                   	leave  
  10481b:	c3                   	ret    

0010481c <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  10481c:	55                   	push   %ebp
  10481d:	89 e5                	mov    %esp,%ebp
  10481f:	53                   	push   %ebx
  104820:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  104823:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104827:	79 18                	jns    104841 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  104829:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104830:	00 
  104831:	8b 45 0c             	mov    0xc(%ebp),%eax
  104834:	89 04 24             	mov    %eax,(%esp)
  104837:	e8 e7 07 00 00       	call   105023 <strchr>
  10483c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10483f:	eb 2c                	jmp    10486d <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  104841:	8b 45 10             	mov    0x10(%ebp),%eax
  104844:	89 44 24 08          	mov    %eax,0x8(%esp)
  104848:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10484f:	00 
  104850:	8b 45 0c             	mov    0xc(%ebp),%eax
  104853:	89 04 24             	mov    %eax,(%esp)
  104856:	e8 cc 09 00 00       	call   105227 <memchr>
  10485b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10485e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104862:	75 09                	jne    10486d <putstr+0x51>
		lim = str + maxlen;
  104864:	8b 45 10             	mov    0x10(%ebp),%eax
  104867:	03 45 0c             	add    0xc(%ebp),%eax
  10486a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  10486d:	8b 45 08             	mov    0x8(%ebp),%eax
  104870:	8b 40 0c             	mov    0xc(%eax),%eax
  104873:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  104876:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104879:	89 cb                	mov    %ecx,%ebx
  10487b:	29 d3                	sub    %edx,%ebx
  10487d:	89 da                	mov    %ebx,%edx
  10487f:	8d 14 10             	lea    (%eax,%edx,1),%edx
  104882:	8b 45 08             	mov    0x8(%ebp),%eax
  104885:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  104888:	8b 45 08             	mov    0x8(%ebp),%eax
  10488b:	8b 40 18             	mov    0x18(%eax),%eax
  10488e:	83 e0 10             	and    $0x10,%eax
  104891:	85 c0                	test   %eax,%eax
  104893:	75 32                	jne    1048c7 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  104895:	8b 45 08             	mov    0x8(%ebp),%eax
  104898:	89 04 24             	mov    %eax,(%esp)
  10489b:	e8 3f ff ff ff       	call   1047df <putpad>
	while (str < lim) {
  1048a0:	eb 25                	jmp    1048c7 <putstr+0xab>
		char ch = *str++;
  1048a2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048a5:	0f b6 00             	movzbl (%eax),%eax
  1048a8:	88 45 f7             	mov    %al,-0x9(%ebp)
  1048ab:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  1048af:	8b 45 08             	mov    0x8(%ebp),%eax
  1048b2:	8b 08                	mov    (%eax),%ecx
  1048b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1048b7:	8b 50 04             	mov    0x4(%eax),%edx
  1048ba:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  1048be:	89 54 24 04          	mov    %edx,0x4(%esp)
  1048c2:	89 04 24             	mov    %eax,(%esp)
  1048c5:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  1048c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048ca:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1048cd:	72 d3                	jb     1048a2 <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  1048cf:	8b 45 08             	mov    0x8(%ebp),%eax
  1048d2:	89 04 24             	mov    %eax,(%esp)
  1048d5:	e8 05 ff ff ff       	call   1047df <putpad>
}
  1048da:	83 c4 24             	add    $0x24,%esp
  1048dd:	5b                   	pop    %ebx
  1048de:	5d                   	pop    %ebp
  1048df:	c3                   	ret    

001048e0 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  1048e0:	55                   	push   %ebp
  1048e1:	89 e5                	mov    %esp,%ebp
  1048e3:	53                   	push   %ebx
  1048e4:	83 ec 24             	sub    $0x24,%esp
  1048e7:	8b 45 10             	mov    0x10(%ebp),%eax
  1048ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1048ed:	8b 45 14             	mov    0x14(%ebp),%eax
  1048f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  1048f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1048f6:	8b 40 1c             	mov    0x1c(%eax),%eax
  1048f9:	89 c2                	mov    %eax,%edx
  1048fb:	c1 fa 1f             	sar    $0x1f,%edx
  1048fe:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104901:	77 4e                	ja     104951 <genint+0x71>
  104903:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104906:	72 05                	jb     10490d <genint+0x2d>
  104908:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10490b:	77 44                	ja     104951 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  10490d:	8b 45 08             	mov    0x8(%ebp),%eax
  104910:	8b 40 1c             	mov    0x1c(%eax),%eax
  104913:	89 c2                	mov    %eax,%edx
  104915:	c1 fa 1f             	sar    $0x1f,%edx
  104918:	89 44 24 08          	mov    %eax,0x8(%esp)
  10491c:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104920:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104923:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104926:	89 04 24             	mov    %eax,(%esp)
  104929:	89 54 24 04          	mov    %edx,0x4(%esp)
  10492d:	e8 2e 09 00 00       	call   105260 <__udivdi3>
  104932:	89 44 24 08          	mov    %eax,0x8(%esp)
  104936:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10493a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10493d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104941:	8b 45 08             	mov    0x8(%ebp),%eax
  104944:	89 04 24             	mov    %eax,(%esp)
  104947:	e8 94 ff ff ff       	call   1048e0 <genint>
  10494c:	89 45 0c             	mov    %eax,0xc(%ebp)
  10494f:	eb 1b                	jmp    10496c <genint+0x8c>
	else if (st->signc >= 0)
  104951:	8b 45 08             	mov    0x8(%ebp),%eax
  104954:	8b 40 14             	mov    0x14(%eax),%eax
  104957:	85 c0                	test   %eax,%eax
  104959:	78 11                	js     10496c <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  10495b:	8b 45 08             	mov    0x8(%ebp),%eax
  10495e:	8b 40 14             	mov    0x14(%eax),%eax
  104961:	89 c2                	mov    %eax,%edx
  104963:	8b 45 0c             	mov    0xc(%ebp),%eax
  104966:	88 10                	mov    %dl,(%eax)
  104968:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  10496c:	8b 45 08             	mov    0x8(%ebp),%eax
  10496f:	8b 40 1c             	mov    0x1c(%eax),%eax
  104972:	89 c1                	mov    %eax,%ecx
  104974:	89 c3                	mov    %eax,%ebx
  104976:	c1 fb 1f             	sar    $0x1f,%ebx
  104979:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10497c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10497f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  104983:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  104987:	89 04 24             	mov    %eax,(%esp)
  10498a:	89 54 24 04          	mov    %edx,0x4(%esp)
  10498e:	e8 fd 09 00 00       	call   105390 <__umoddi3>
  104993:	05 b0 64 10 00       	add    $0x1064b0,%eax
  104998:	0f b6 10             	movzbl (%eax),%edx
  10499b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10499e:	88 10                	mov    %dl,(%eax)
  1049a0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  1049a4:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  1049a7:	83 c4 24             	add    $0x24,%esp
  1049aa:	5b                   	pop    %ebx
  1049ab:	5d                   	pop    %ebp
  1049ac:	c3                   	ret    

001049ad <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  1049ad:	55                   	push   %ebp
  1049ae:	89 e5                	mov    %esp,%ebp
  1049b0:	83 ec 58             	sub    $0x58,%esp
  1049b3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049b6:	89 45 c0             	mov    %eax,-0x40(%ebp)
  1049b9:	8b 45 10             	mov    0x10(%ebp),%eax
  1049bc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  1049bf:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1049c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  1049c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1049c8:	8b 55 14             	mov    0x14(%ebp),%edx
  1049cb:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  1049ce:	8b 45 c0             	mov    -0x40(%ebp),%eax
  1049d1:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  1049d4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1049d8:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1049dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1049df:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1049e6:	89 04 24             	mov    %eax,(%esp)
  1049e9:	e8 f2 fe ff ff       	call   1048e0 <genint>
  1049ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  1049f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1049f4:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1049f7:	89 d1                	mov    %edx,%ecx
  1049f9:	29 c1                	sub    %eax,%ecx
  1049fb:	89 c8                	mov    %ecx,%eax
  1049fd:	89 44 24 08          	mov    %eax,0x8(%esp)
  104a01:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104a04:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a08:	8b 45 08             	mov    0x8(%ebp),%eax
  104a0b:	89 04 24             	mov    %eax,(%esp)
  104a0e:	e8 09 fe ff ff       	call   10481c <putstr>
}
  104a13:	c9                   	leave  
  104a14:	c3                   	ret    

00104a15 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  104a15:	55                   	push   %ebp
  104a16:	89 e5                	mov    %esp,%ebp
  104a18:	53                   	push   %ebx
  104a19:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  104a1c:	8d 55 c8             	lea    -0x38(%ebp),%edx
  104a1f:	b9 00 00 00 00       	mov    $0x0,%ecx
  104a24:	b8 20 00 00 00       	mov    $0x20,%eax
  104a29:	89 c3                	mov    %eax,%ebx
  104a2b:	83 e3 fc             	and    $0xfffffffc,%ebx
  104a2e:	b8 00 00 00 00       	mov    $0x0,%eax
  104a33:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  104a36:	83 c0 04             	add    $0x4,%eax
  104a39:	39 d8                	cmp    %ebx,%eax
  104a3b:	72 f6                	jb     104a33 <vprintfmt+0x1e>
  104a3d:	01 c2                	add    %eax,%edx
  104a3f:	8b 45 08             	mov    0x8(%ebp),%eax
  104a42:	89 45 c8             	mov    %eax,-0x38(%ebp)
  104a45:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a48:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104a4b:	eb 17                	jmp    104a64 <vprintfmt+0x4f>
			if (ch == '\0')
  104a4d:	85 db                	test   %ebx,%ebx
  104a4f:	0f 84 52 03 00 00    	je     104da7 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  104a55:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a58:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a5c:	89 1c 24             	mov    %ebx,(%esp)
  104a5f:	8b 45 08             	mov    0x8(%ebp),%eax
  104a62:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104a64:	8b 45 10             	mov    0x10(%ebp),%eax
  104a67:	0f b6 00             	movzbl (%eax),%eax
  104a6a:	0f b6 d8             	movzbl %al,%ebx
  104a6d:	83 fb 25             	cmp    $0x25,%ebx
  104a70:	0f 95 c0             	setne  %al
  104a73:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104a77:	84 c0                	test   %al,%al
  104a79:	75 d2                	jne    104a4d <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  104a7b:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  104a82:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  104a89:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  104a90:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  104a97:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  104a9e:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  104aa5:	eb 04                	jmp    104aab <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  104aa7:	90                   	nop
  104aa8:	eb 01                	jmp    104aab <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  104aaa:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  104aab:	8b 45 10             	mov    0x10(%ebp),%eax
  104aae:	0f b6 00             	movzbl (%eax),%eax
  104ab1:	0f b6 d8             	movzbl %al,%ebx
  104ab4:	89 d8                	mov    %ebx,%eax
  104ab6:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104aba:	83 e8 20             	sub    $0x20,%eax
  104abd:	83 f8 58             	cmp    $0x58,%eax
  104ac0:	0f 87 b1 02 00 00    	ja     104d77 <vprintfmt+0x362>
  104ac6:	8b 04 85 c8 64 10 00 	mov    0x1064c8(,%eax,4),%eax
  104acd:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  104acf:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104ad2:	83 c8 10             	or     $0x10,%eax
  104ad5:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104ad8:	eb d1                	jmp    104aab <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  104ada:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  104ae1:	eb c8                	jmp    104aab <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  104ae3:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104ae6:	85 c0                	test   %eax,%eax
  104ae8:	79 bd                	jns    104aa7 <vprintfmt+0x92>
				st.signc = ' ';
  104aea:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  104af1:	eb b8                	jmp    104aab <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  104af3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104af6:	83 e0 08             	and    $0x8,%eax
  104af9:	85 c0                	test   %eax,%eax
  104afb:	75 07                	jne    104b04 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  104afd:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104b04:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  104b0b:	8b 55 d8             	mov    -0x28(%ebp),%edx
  104b0e:	89 d0                	mov    %edx,%eax
  104b10:	c1 e0 02             	shl    $0x2,%eax
  104b13:	01 d0                	add    %edx,%eax
  104b15:	01 c0                	add    %eax,%eax
  104b17:	01 d8                	add    %ebx,%eax
  104b19:	83 e8 30             	sub    $0x30,%eax
  104b1c:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  104b1f:	8b 45 10             	mov    0x10(%ebp),%eax
  104b22:	0f b6 00             	movzbl (%eax),%eax
  104b25:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  104b28:	83 fb 2f             	cmp    $0x2f,%ebx
  104b2b:	7e 21                	jle    104b4e <vprintfmt+0x139>
  104b2d:	83 fb 39             	cmp    $0x39,%ebx
  104b30:	7f 1f                	jg     104b51 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104b32:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  104b36:	eb d3                	jmp    104b0b <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  104b38:	8b 45 14             	mov    0x14(%ebp),%eax
  104b3b:	83 c0 04             	add    $0x4,%eax
  104b3e:	89 45 14             	mov    %eax,0x14(%ebp)
  104b41:	8b 45 14             	mov    0x14(%ebp),%eax
  104b44:	83 e8 04             	sub    $0x4,%eax
  104b47:	8b 00                	mov    (%eax),%eax
  104b49:	89 45 d8             	mov    %eax,-0x28(%ebp)
  104b4c:	eb 04                	jmp    104b52 <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  104b4e:	90                   	nop
  104b4f:	eb 01                	jmp    104b52 <vprintfmt+0x13d>
  104b51:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  104b52:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104b55:	83 e0 08             	and    $0x8,%eax
  104b58:	85 c0                	test   %eax,%eax
  104b5a:	0f 85 4a ff ff ff    	jne    104aaa <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  104b60:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104b63:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  104b66:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  104b6d:	e9 39 ff ff ff       	jmp    104aab <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  104b72:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104b75:	83 c8 08             	or     $0x8,%eax
  104b78:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104b7b:	e9 2b ff ff ff       	jmp    104aab <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  104b80:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104b83:	83 c8 04             	or     $0x4,%eax
  104b86:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104b89:	e9 1d ff ff ff       	jmp    104aab <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  104b8e:	8b 55 e0             	mov    -0x20(%ebp),%edx
  104b91:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104b94:	83 e0 01             	and    $0x1,%eax
  104b97:	84 c0                	test   %al,%al
  104b99:	74 07                	je     104ba2 <vprintfmt+0x18d>
  104b9b:	b8 02 00 00 00       	mov    $0x2,%eax
  104ba0:	eb 05                	jmp    104ba7 <vprintfmt+0x192>
  104ba2:	b8 01 00 00 00       	mov    $0x1,%eax
  104ba7:	09 d0                	or     %edx,%eax
  104ba9:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104bac:	e9 fa fe ff ff       	jmp    104aab <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  104bb1:	8b 45 14             	mov    0x14(%ebp),%eax
  104bb4:	83 c0 04             	add    $0x4,%eax
  104bb7:	89 45 14             	mov    %eax,0x14(%ebp)
  104bba:	8b 45 14             	mov    0x14(%ebp),%eax
  104bbd:	83 e8 04             	sub    $0x4,%eax
  104bc0:	8b 00                	mov    (%eax),%eax
  104bc2:	8b 55 0c             	mov    0xc(%ebp),%edx
  104bc5:	89 54 24 04          	mov    %edx,0x4(%esp)
  104bc9:	89 04 24             	mov    %eax,(%esp)
  104bcc:	8b 45 08             	mov    0x8(%ebp),%eax
  104bcf:	ff d0                	call   *%eax
			break;
  104bd1:	e9 cb 01 00 00       	jmp    104da1 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  104bd6:	8b 45 14             	mov    0x14(%ebp),%eax
  104bd9:	83 c0 04             	add    $0x4,%eax
  104bdc:	89 45 14             	mov    %eax,0x14(%ebp)
  104bdf:	8b 45 14             	mov    0x14(%ebp),%eax
  104be2:	83 e8 04             	sub    $0x4,%eax
  104be5:	8b 00                	mov    (%eax),%eax
  104be7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104bea:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104bee:	75 07                	jne    104bf7 <vprintfmt+0x1e2>
				s = "(null)";
  104bf0:	c7 45 f4 c1 64 10 00 	movl   $0x1064c1,-0xc(%ebp)
			putstr(&st, s, st.prec);
  104bf7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104bfa:	89 44 24 08          	mov    %eax,0x8(%esp)
  104bfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104c01:	89 44 24 04          	mov    %eax,0x4(%esp)
  104c05:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104c08:	89 04 24             	mov    %eax,(%esp)
  104c0b:	e8 0c fc ff ff       	call   10481c <putstr>
			break;
  104c10:	e9 8c 01 00 00       	jmp    104da1 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  104c15:	8d 45 14             	lea    0x14(%ebp),%eax
  104c18:	89 44 24 04          	mov    %eax,0x4(%esp)
  104c1c:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104c1f:	89 04 24             	mov    %eax,(%esp)
  104c22:	e8 43 fb ff ff       	call   10476a <getint>
  104c27:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104c2a:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  104c2d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104c30:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104c33:	85 d2                	test   %edx,%edx
  104c35:	79 1a                	jns    104c51 <vprintfmt+0x23c>
				num = -(intmax_t) num;
  104c37:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104c3a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104c3d:	f7 d8                	neg    %eax
  104c3f:	83 d2 00             	adc    $0x0,%edx
  104c42:	f7 da                	neg    %edx
  104c44:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104c47:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  104c4a:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  104c51:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104c58:	00 
  104c59:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104c5c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104c5f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104c63:	89 54 24 08          	mov    %edx,0x8(%esp)
  104c67:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104c6a:	89 04 24             	mov    %eax,(%esp)
  104c6d:	e8 3b fd ff ff       	call   1049ad <putint>
			break;
  104c72:	e9 2a 01 00 00       	jmp    104da1 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  104c77:	8d 45 14             	lea    0x14(%ebp),%eax
  104c7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  104c7e:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104c81:	89 04 24             	mov    %eax,(%esp)
  104c84:	e8 6c fa ff ff       	call   1046f5 <getuint>
  104c89:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104c90:	00 
  104c91:	89 44 24 04          	mov    %eax,0x4(%esp)
  104c95:	89 54 24 08          	mov    %edx,0x8(%esp)
  104c99:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104c9c:	89 04 24             	mov    %eax,(%esp)
  104c9f:	e8 09 fd ff ff       	call   1049ad <putint>
			break;
  104ca4:	e9 f8 00 00 00       	jmp    104da1 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  104ca9:	8d 45 14             	lea    0x14(%ebp),%eax
  104cac:	89 44 24 04          	mov    %eax,0x4(%esp)
  104cb0:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104cb3:	89 04 24             	mov    %eax,(%esp)
  104cb6:	e8 3a fa ff ff       	call   1046f5 <getuint>
  104cbb:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  104cc2:	00 
  104cc3:	89 44 24 04          	mov    %eax,0x4(%esp)
  104cc7:	89 54 24 08          	mov    %edx,0x8(%esp)
  104ccb:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104cce:	89 04 24             	mov    %eax,(%esp)
  104cd1:	e8 d7 fc ff ff       	call   1049ad <putint>
			break;
  104cd6:	e9 c6 00 00 00       	jmp    104da1 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  104cdb:	8d 45 14             	lea    0x14(%ebp),%eax
  104cde:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ce2:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104ce5:	89 04 24             	mov    %eax,(%esp)
  104ce8:	e8 08 fa ff ff       	call   1046f5 <getuint>
  104ced:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  104cf4:	00 
  104cf5:	89 44 24 04          	mov    %eax,0x4(%esp)
  104cf9:	89 54 24 08          	mov    %edx,0x8(%esp)
  104cfd:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104d00:	89 04 24             	mov    %eax,(%esp)
  104d03:	e8 a5 fc ff ff       	call   1049ad <putint>
			break;
  104d08:	e9 94 00 00 00       	jmp    104da1 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  104d0d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d10:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d14:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  104d1b:	8b 45 08             	mov    0x8(%ebp),%eax
  104d1e:	ff d0                	call   *%eax
			putch('x', putdat);
  104d20:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d23:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d27:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  104d2e:	8b 45 08             	mov    0x8(%ebp),%eax
  104d31:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  104d33:	8b 45 14             	mov    0x14(%ebp),%eax
  104d36:	83 c0 04             	add    $0x4,%eax
  104d39:	89 45 14             	mov    %eax,0x14(%ebp)
  104d3c:	8b 45 14             	mov    0x14(%ebp),%eax
  104d3f:	83 e8 04             	sub    $0x4,%eax
  104d42:	8b 00                	mov    (%eax),%eax
  104d44:	ba 00 00 00 00       	mov    $0x0,%edx
  104d49:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  104d50:	00 
  104d51:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d55:	89 54 24 08          	mov    %edx,0x8(%esp)
  104d59:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104d5c:	89 04 24             	mov    %eax,(%esp)
  104d5f:	e8 49 fc ff ff       	call   1049ad <putint>
			break;
  104d64:	eb 3b                	jmp    104da1 <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  104d66:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d69:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d6d:	89 1c 24             	mov    %ebx,(%esp)
  104d70:	8b 45 08             	mov    0x8(%ebp),%eax
  104d73:	ff d0                	call   *%eax
			break;
  104d75:	eb 2a                	jmp    104da1 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  104d77:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d7e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  104d85:	8b 45 08             	mov    0x8(%ebp),%eax
  104d88:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  104d8a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104d8e:	eb 04                	jmp    104d94 <vprintfmt+0x37f>
  104d90:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104d94:	8b 45 10             	mov    0x10(%ebp),%eax
  104d97:	83 e8 01             	sub    $0x1,%eax
  104d9a:	0f b6 00             	movzbl (%eax),%eax
  104d9d:	3c 25                	cmp    $0x25,%al
  104d9f:	75 ef                	jne    104d90 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  104da1:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104da2:	e9 bd fc ff ff       	jmp    104a64 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  104da7:	83 c4 44             	add    $0x44,%esp
  104daa:	5b                   	pop    %ebx
  104dab:	5d                   	pop    %ebp
  104dac:	c3                   	ret    

00104dad <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  104dad:	55                   	push   %ebp
  104dae:	89 e5                	mov    %esp,%ebp
  104db0:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  104db3:	8b 45 0c             	mov    0xc(%ebp),%eax
  104db6:	8b 00                	mov    (%eax),%eax
  104db8:	8b 55 08             	mov    0x8(%ebp),%edx
  104dbb:	89 d1                	mov    %edx,%ecx
  104dbd:	8b 55 0c             	mov    0xc(%ebp),%edx
  104dc0:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  104dc4:	8d 50 01             	lea    0x1(%eax),%edx
  104dc7:	8b 45 0c             	mov    0xc(%ebp),%eax
  104dca:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  104dcc:	8b 45 0c             	mov    0xc(%ebp),%eax
  104dcf:	8b 00                	mov    (%eax),%eax
  104dd1:	3d ff 00 00 00       	cmp    $0xff,%eax
  104dd6:	75 24                	jne    104dfc <putch+0x4f>
		b->buf[b->idx] = 0;
  104dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ddb:	8b 00                	mov    (%eax),%eax
  104ddd:	8b 55 0c             	mov    0xc(%ebp),%edx
  104de0:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  104de5:	8b 45 0c             	mov    0xc(%ebp),%eax
  104de8:	83 c0 08             	add    $0x8,%eax
  104deb:	89 04 24             	mov    %eax,(%esp)
  104dee:	e8 f3 b5 ff ff       	call   1003e6 <cputs>
		b->idx = 0;
  104df3:	8b 45 0c             	mov    0xc(%ebp),%eax
  104df6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  104dfc:	8b 45 0c             	mov    0xc(%ebp),%eax
  104dff:	8b 40 04             	mov    0x4(%eax),%eax
  104e02:	8d 50 01             	lea    0x1(%eax),%edx
  104e05:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e08:	89 50 04             	mov    %edx,0x4(%eax)
}
  104e0b:	c9                   	leave  
  104e0c:	c3                   	ret    

00104e0d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  104e0d:	55                   	push   %ebp
  104e0e:	89 e5                	mov    %esp,%ebp
  104e10:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  104e16:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  104e1d:	00 00 00 
	b.cnt = 0;
  104e20:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  104e27:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  104e2a:	b8 ad 4d 10 00       	mov    $0x104dad,%eax
  104e2f:	8b 55 0c             	mov    0xc(%ebp),%edx
  104e32:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104e36:	8b 55 08             	mov    0x8(%ebp),%edx
  104e39:	89 54 24 08          	mov    %edx,0x8(%esp)
  104e3d:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  104e43:	89 54 24 04          	mov    %edx,0x4(%esp)
  104e47:	89 04 24             	mov    %eax,(%esp)
  104e4a:	e8 c6 fb ff ff       	call   104a15 <vprintfmt>

	b.buf[b.idx] = 0;
  104e4f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  104e55:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  104e5c:	00 
	cputs(b.buf);
  104e5d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  104e63:	83 c0 08             	add    $0x8,%eax
  104e66:	89 04 24             	mov    %eax,(%esp)
  104e69:	e8 78 b5 ff ff       	call   1003e6 <cputs>

	return b.cnt;
  104e6e:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  104e74:	c9                   	leave  
  104e75:	c3                   	ret    

00104e76 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  104e76:	55                   	push   %ebp
  104e77:	89 e5                	mov    %esp,%ebp
  104e79:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  104e7c:	8d 45 08             	lea    0x8(%ebp),%eax
  104e7f:	83 c0 04             	add    $0x4,%eax
  104e82:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  104e85:	8b 45 08             	mov    0x8(%ebp),%eax
  104e88:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104e8b:	89 54 24 04          	mov    %edx,0x4(%esp)
  104e8f:	89 04 24             	mov    %eax,(%esp)
  104e92:	e8 76 ff ff ff       	call   104e0d <vcprintf>
  104e97:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  104e9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  104e9d:	c9                   	leave  
  104e9e:	c3                   	ret    

00104e9f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  104e9f:	55                   	push   %ebp
  104ea0:	89 e5                	mov    %esp,%ebp
  104ea2:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  104ea5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  104eac:	eb 08                	jmp    104eb6 <strlen+0x17>
		n++;
  104eae:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  104eb2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104eb6:	8b 45 08             	mov    0x8(%ebp),%eax
  104eb9:	0f b6 00             	movzbl (%eax),%eax
  104ebc:	84 c0                	test   %al,%al
  104ebe:	75 ee                	jne    104eae <strlen+0xf>
		n++;
	return n;
  104ec0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104ec3:	c9                   	leave  
  104ec4:	c3                   	ret    

00104ec5 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  104ec5:	55                   	push   %ebp
  104ec6:	89 e5                	mov    %esp,%ebp
  104ec8:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  104ecb:	8b 45 08             	mov    0x8(%ebp),%eax
  104ece:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  104ed1:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ed4:	0f b6 10             	movzbl (%eax),%edx
  104ed7:	8b 45 08             	mov    0x8(%ebp),%eax
  104eda:	88 10                	mov    %dl,(%eax)
  104edc:	8b 45 08             	mov    0x8(%ebp),%eax
  104edf:	0f b6 00             	movzbl (%eax),%eax
  104ee2:	84 c0                	test   %al,%al
  104ee4:	0f 95 c0             	setne  %al
  104ee7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104eeb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  104eef:	84 c0                	test   %al,%al
  104ef1:	75 de                	jne    104ed1 <strcpy+0xc>
		/* do nothing */;
	return ret;
  104ef3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104ef6:	c9                   	leave  
  104ef7:	c3                   	ret    

00104ef8 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  104ef8:	55                   	push   %ebp
  104ef9:	89 e5                	mov    %esp,%ebp
  104efb:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  104efe:	8b 45 08             	mov    0x8(%ebp),%eax
  104f01:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  104f04:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  104f0b:	eb 21                	jmp    104f2e <strncpy+0x36>
		*dst++ = *src;
  104f0d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104f10:	0f b6 10             	movzbl (%eax),%edx
  104f13:	8b 45 08             	mov    0x8(%ebp),%eax
  104f16:	88 10                	mov    %dl,(%eax)
  104f18:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  104f1c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104f1f:	0f b6 00             	movzbl (%eax),%eax
  104f22:	84 c0                	test   %al,%al
  104f24:	74 04                	je     104f2a <strncpy+0x32>
			src++;
  104f26:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  104f2a:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  104f2e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104f31:	3b 45 10             	cmp    0x10(%ebp),%eax
  104f34:	72 d7                	jb     104f0d <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  104f36:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104f39:	c9                   	leave  
  104f3a:	c3                   	ret    

00104f3b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  104f3b:	55                   	push   %ebp
  104f3c:	89 e5                	mov    %esp,%ebp
  104f3e:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  104f41:	8b 45 08             	mov    0x8(%ebp),%eax
  104f44:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  104f47:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104f4b:	74 2f                	je     104f7c <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  104f4d:	eb 13                	jmp    104f62 <strlcpy+0x27>
			*dst++ = *src++;
  104f4f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104f52:	0f b6 10             	movzbl (%eax),%edx
  104f55:	8b 45 08             	mov    0x8(%ebp),%eax
  104f58:	88 10                	mov    %dl,(%eax)
  104f5a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104f5e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  104f62:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104f66:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104f6a:	74 0a                	je     104f76 <strlcpy+0x3b>
  104f6c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104f6f:	0f b6 00             	movzbl (%eax),%eax
  104f72:	84 c0                	test   %al,%al
  104f74:	75 d9                	jne    104f4f <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  104f76:	8b 45 08             	mov    0x8(%ebp),%eax
  104f79:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  104f7c:	8b 55 08             	mov    0x8(%ebp),%edx
  104f7f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104f82:	89 d1                	mov    %edx,%ecx
  104f84:	29 c1                	sub    %eax,%ecx
  104f86:	89 c8                	mov    %ecx,%eax
}
  104f88:	c9                   	leave  
  104f89:	c3                   	ret    

00104f8a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  104f8a:	55                   	push   %ebp
  104f8b:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  104f8d:	eb 08                	jmp    104f97 <strcmp+0xd>
		p++, q++;
  104f8f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104f93:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  104f97:	8b 45 08             	mov    0x8(%ebp),%eax
  104f9a:	0f b6 00             	movzbl (%eax),%eax
  104f9d:	84 c0                	test   %al,%al
  104f9f:	74 10                	je     104fb1 <strcmp+0x27>
  104fa1:	8b 45 08             	mov    0x8(%ebp),%eax
  104fa4:	0f b6 10             	movzbl (%eax),%edx
  104fa7:	8b 45 0c             	mov    0xc(%ebp),%eax
  104faa:	0f b6 00             	movzbl (%eax),%eax
  104fad:	38 c2                	cmp    %al,%dl
  104faf:	74 de                	je     104f8f <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  104fb1:	8b 45 08             	mov    0x8(%ebp),%eax
  104fb4:	0f b6 00             	movzbl (%eax),%eax
  104fb7:	0f b6 d0             	movzbl %al,%edx
  104fba:	8b 45 0c             	mov    0xc(%ebp),%eax
  104fbd:	0f b6 00             	movzbl (%eax),%eax
  104fc0:	0f b6 c0             	movzbl %al,%eax
  104fc3:	89 d1                	mov    %edx,%ecx
  104fc5:	29 c1                	sub    %eax,%ecx
  104fc7:	89 c8                	mov    %ecx,%eax
}
  104fc9:	5d                   	pop    %ebp
  104fca:	c3                   	ret    

00104fcb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  104fcb:	55                   	push   %ebp
  104fcc:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  104fce:	eb 0c                	jmp    104fdc <strncmp+0x11>
		n--, p++, q++;
  104fd0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104fd4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104fd8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  104fdc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104fe0:	74 1a                	je     104ffc <strncmp+0x31>
  104fe2:	8b 45 08             	mov    0x8(%ebp),%eax
  104fe5:	0f b6 00             	movzbl (%eax),%eax
  104fe8:	84 c0                	test   %al,%al
  104fea:	74 10                	je     104ffc <strncmp+0x31>
  104fec:	8b 45 08             	mov    0x8(%ebp),%eax
  104fef:	0f b6 10             	movzbl (%eax),%edx
  104ff2:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ff5:	0f b6 00             	movzbl (%eax),%eax
  104ff8:	38 c2                	cmp    %al,%dl
  104ffa:	74 d4                	je     104fd0 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  104ffc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105000:	75 07                	jne    105009 <strncmp+0x3e>
		return 0;
  105002:	b8 00 00 00 00       	mov    $0x0,%eax
  105007:	eb 18                	jmp    105021 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  105009:	8b 45 08             	mov    0x8(%ebp),%eax
  10500c:	0f b6 00             	movzbl (%eax),%eax
  10500f:	0f b6 d0             	movzbl %al,%edx
  105012:	8b 45 0c             	mov    0xc(%ebp),%eax
  105015:	0f b6 00             	movzbl (%eax),%eax
  105018:	0f b6 c0             	movzbl %al,%eax
  10501b:	89 d1                	mov    %edx,%ecx
  10501d:	29 c1                	sub    %eax,%ecx
  10501f:	89 c8                	mov    %ecx,%eax
}
  105021:	5d                   	pop    %ebp
  105022:	c3                   	ret    

00105023 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  105023:	55                   	push   %ebp
  105024:	89 e5                	mov    %esp,%ebp
  105026:	83 ec 04             	sub    $0x4,%esp
  105029:	8b 45 0c             	mov    0xc(%ebp),%eax
  10502c:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  10502f:	eb 1a                	jmp    10504b <strchr+0x28>
		if (*s++ == 0)
  105031:	8b 45 08             	mov    0x8(%ebp),%eax
  105034:	0f b6 00             	movzbl (%eax),%eax
  105037:	84 c0                	test   %al,%al
  105039:	0f 94 c0             	sete   %al
  10503c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105040:	84 c0                	test   %al,%al
  105042:	74 07                	je     10504b <strchr+0x28>
			return NULL;
  105044:	b8 00 00 00 00       	mov    $0x0,%eax
  105049:	eb 0e                	jmp    105059 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  10504b:	8b 45 08             	mov    0x8(%ebp),%eax
  10504e:	0f b6 00             	movzbl (%eax),%eax
  105051:	3a 45 fc             	cmp    -0x4(%ebp),%al
  105054:	75 db                	jne    105031 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  105056:	8b 45 08             	mov    0x8(%ebp),%eax
}
  105059:	c9                   	leave  
  10505a:	c3                   	ret    

0010505b <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  10505b:	55                   	push   %ebp
  10505c:	89 e5                	mov    %esp,%ebp
  10505e:	57                   	push   %edi
  10505f:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  105062:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105066:	75 05                	jne    10506d <memset+0x12>
		return v;
  105068:	8b 45 08             	mov    0x8(%ebp),%eax
  10506b:	eb 5c                	jmp    1050c9 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  10506d:	8b 45 08             	mov    0x8(%ebp),%eax
  105070:	83 e0 03             	and    $0x3,%eax
  105073:	85 c0                	test   %eax,%eax
  105075:	75 41                	jne    1050b8 <memset+0x5d>
  105077:	8b 45 10             	mov    0x10(%ebp),%eax
  10507a:	83 e0 03             	and    $0x3,%eax
  10507d:	85 c0                	test   %eax,%eax
  10507f:	75 37                	jne    1050b8 <memset+0x5d>
		c &= 0xFF;
  105081:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  105088:	8b 45 0c             	mov    0xc(%ebp),%eax
  10508b:	89 c2                	mov    %eax,%edx
  10508d:	c1 e2 18             	shl    $0x18,%edx
  105090:	8b 45 0c             	mov    0xc(%ebp),%eax
  105093:	c1 e0 10             	shl    $0x10,%eax
  105096:	09 c2                	or     %eax,%edx
  105098:	8b 45 0c             	mov    0xc(%ebp),%eax
  10509b:	c1 e0 08             	shl    $0x8,%eax
  10509e:	09 d0                	or     %edx,%eax
  1050a0:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  1050a3:	8b 45 10             	mov    0x10(%ebp),%eax
  1050a6:	89 c1                	mov    %eax,%ecx
  1050a8:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  1050ab:	8b 55 08             	mov    0x8(%ebp),%edx
  1050ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050b1:	89 d7                	mov    %edx,%edi
  1050b3:	fc                   	cld    
  1050b4:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  1050b6:	eb 0e                	jmp    1050c6 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  1050b8:	8b 55 08             	mov    0x8(%ebp),%edx
  1050bb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050be:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1050c1:	89 d7                	mov    %edx,%edi
  1050c3:	fc                   	cld    
  1050c4:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  1050c6:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1050c9:	83 c4 10             	add    $0x10,%esp
  1050cc:	5f                   	pop    %edi
  1050cd:	5d                   	pop    %ebp
  1050ce:	c3                   	ret    

001050cf <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  1050cf:	55                   	push   %ebp
  1050d0:	89 e5                	mov    %esp,%ebp
  1050d2:	57                   	push   %edi
  1050d3:	56                   	push   %esi
  1050d4:	53                   	push   %ebx
  1050d5:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  1050d8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050db:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  1050de:	8b 45 08             	mov    0x8(%ebp),%eax
  1050e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  1050e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1050e7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1050ea:	73 6e                	jae    10515a <memmove+0x8b>
  1050ec:	8b 45 10             	mov    0x10(%ebp),%eax
  1050ef:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1050f2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1050f5:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1050f8:	76 60                	jbe    10515a <memmove+0x8b>
		s += n;
  1050fa:	8b 45 10             	mov    0x10(%ebp),%eax
  1050fd:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  105100:	8b 45 10             	mov    0x10(%ebp),%eax
  105103:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  105106:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105109:	83 e0 03             	and    $0x3,%eax
  10510c:	85 c0                	test   %eax,%eax
  10510e:	75 2f                	jne    10513f <memmove+0x70>
  105110:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105113:	83 e0 03             	and    $0x3,%eax
  105116:	85 c0                	test   %eax,%eax
  105118:	75 25                	jne    10513f <memmove+0x70>
  10511a:	8b 45 10             	mov    0x10(%ebp),%eax
  10511d:	83 e0 03             	and    $0x3,%eax
  105120:	85 c0                	test   %eax,%eax
  105122:	75 1b                	jne    10513f <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  105124:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105127:	83 e8 04             	sub    $0x4,%eax
  10512a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10512d:	83 ea 04             	sub    $0x4,%edx
  105130:	8b 4d 10             	mov    0x10(%ebp),%ecx
  105133:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  105136:	89 c7                	mov    %eax,%edi
  105138:	89 d6                	mov    %edx,%esi
  10513a:	fd                   	std    
  10513b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10513d:	eb 18                	jmp    105157 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  10513f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105142:	8d 50 ff             	lea    -0x1(%eax),%edx
  105145:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105148:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  10514b:	8b 45 10             	mov    0x10(%ebp),%eax
  10514e:	89 d7                	mov    %edx,%edi
  105150:	89 de                	mov    %ebx,%esi
  105152:	89 c1                	mov    %eax,%ecx
  105154:	fd                   	std    
  105155:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  105157:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  105158:	eb 45                	jmp    10519f <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10515a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10515d:	83 e0 03             	and    $0x3,%eax
  105160:	85 c0                	test   %eax,%eax
  105162:	75 2b                	jne    10518f <memmove+0xc0>
  105164:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105167:	83 e0 03             	and    $0x3,%eax
  10516a:	85 c0                	test   %eax,%eax
  10516c:	75 21                	jne    10518f <memmove+0xc0>
  10516e:	8b 45 10             	mov    0x10(%ebp),%eax
  105171:	83 e0 03             	and    $0x3,%eax
  105174:	85 c0                	test   %eax,%eax
  105176:	75 17                	jne    10518f <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  105178:	8b 45 10             	mov    0x10(%ebp),%eax
  10517b:	89 c1                	mov    %eax,%ecx
  10517d:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  105180:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105183:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105186:	89 c7                	mov    %eax,%edi
  105188:	89 d6                	mov    %edx,%esi
  10518a:	fc                   	cld    
  10518b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10518d:	eb 10                	jmp    10519f <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  10518f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105192:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105195:	8b 4d 10             	mov    0x10(%ebp),%ecx
  105198:	89 c7                	mov    %eax,%edi
  10519a:	89 d6                	mov    %edx,%esi
  10519c:	fc                   	cld    
  10519d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  10519f:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1051a2:	83 c4 10             	add    $0x10,%esp
  1051a5:	5b                   	pop    %ebx
  1051a6:	5e                   	pop    %esi
  1051a7:	5f                   	pop    %edi
  1051a8:	5d                   	pop    %ebp
  1051a9:	c3                   	ret    

001051aa <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  1051aa:	55                   	push   %ebp
  1051ab:	89 e5                	mov    %esp,%ebp
  1051ad:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  1051b0:	8b 45 10             	mov    0x10(%ebp),%eax
  1051b3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1051b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1051ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  1051be:	8b 45 08             	mov    0x8(%ebp),%eax
  1051c1:	89 04 24             	mov    %eax,(%esp)
  1051c4:	e8 06 ff ff ff       	call   1050cf <memmove>
}
  1051c9:	c9                   	leave  
  1051ca:	c3                   	ret    

001051cb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  1051cb:	55                   	push   %ebp
  1051cc:	89 e5                	mov    %esp,%ebp
  1051ce:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  1051d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1051d4:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  1051d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1051da:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  1051dd:	eb 32                	jmp    105211 <memcmp+0x46>
		if (*s1 != *s2)
  1051df:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1051e2:	0f b6 10             	movzbl (%eax),%edx
  1051e5:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1051e8:	0f b6 00             	movzbl (%eax),%eax
  1051eb:	38 c2                	cmp    %al,%dl
  1051ed:	74 1a                	je     105209 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  1051ef:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1051f2:	0f b6 00             	movzbl (%eax),%eax
  1051f5:	0f b6 d0             	movzbl %al,%edx
  1051f8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1051fb:	0f b6 00             	movzbl (%eax),%eax
  1051fe:	0f b6 c0             	movzbl %al,%eax
  105201:	89 d1                	mov    %edx,%ecx
  105203:	29 c1                	sub    %eax,%ecx
  105205:	89 c8                	mov    %ecx,%eax
  105207:	eb 1c                	jmp    105225 <memcmp+0x5a>
		s1++, s2++;
  105209:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  10520d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  105211:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105215:	0f 95 c0             	setne  %al
  105218:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10521c:	84 c0                	test   %al,%al
  10521e:	75 bf                	jne    1051df <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  105220:	b8 00 00 00 00       	mov    $0x0,%eax
}
  105225:	c9                   	leave  
  105226:	c3                   	ret    

00105227 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  105227:	55                   	push   %ebp
  105228:	89 e5                	mov    %esp,%ebp
  10522a:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  10522d:	8b 45 10             	mov    0x10(%ebp),%eax
  105230:	8b 55 08             	mov    0x8(%ebp),%edx
  105233:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105236:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  105239:	eb 16                	jmp    105251 <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  10523b:	8b 45 08             	mov    0x8(%ebp),%eax
  10523e:	0f b6 10             	movzbl (%eax),%edx
  105241:	8b 45 0c             	mov    0xc(%ebp),%eax
  105244:	38 c2                	cmp    %al,%dl
  105246:	75 05                	jne    10524d <memchr+0x26>
			return (void *) s;
  105248:	8b 45 08             	mov    0x8(%ebp),%eax
  10524b:	eb 11                	jmp    10525e <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  10524d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105251:	8b 45 08             	mov    0x8(%ebp),%eax
  105254:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  105257:	72 e2                	jb     10523b <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  105259:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10525e:	c9                   	leave  
  10525f:	c3                   	ret    

00105260 <__udivdi3>:
  105260:	55                   	push   %ebp
  105261:	89 e5                	mov    %esp,%ebp
  105263:	57                   	push   %edi
  105264:	56                   	push   %esi
  105265:	83 ec 10             	sub    $0x10,%esp
  105268:	8b 45 14             	mov    0x14(%ebp),%eax
  10526b:	8b 55 08             	mov    0x8(%ebp),%edx
  10526e:	8b 75 10             	mov    0x10(%ebp),%esi
  105271:	8b 7d 0c             	mov    0xc(%ebp),%edi
  105274:	85 c0                	test   %eax,%eax
  105276:	89 55 f0             	mov    %edx,-0x10(%ebp)
  105279:	75 35                	jne    1052b0 <__udivdi3+0x50>
  10527b:	39 fe                	cmp    %edi,%esi
  10527d:	77 61                	ja     1052e0 <__udivdi3+0x80>
  10527f:	85 f6                	test   %esi,%esi
  105281:	75 0b                	jne    10528e <__udivdi3+0x2e>
  105283:	b8 01 00 00 00       	mov    $0x1,%eax
  105288:	31 d2                	xor    %edx,%edx
  10528a:	f7 f6                	div    %esi
  10528c:	89 c6                	mov    %eax,%esi
  10528e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  105291:	31 d2                	xor    %edx,%edx
  105293:	89 f8                	mov    %edi,%eax
  105295:	f7 f6                	div    %esi
  105297:	89 c7                	mov    %eax,%edi
  105299:	89 c8                	mov    %ecx,%eax
  10529b:	f7 f6                	div    %esi
  10529d:	89 c1                	mov    %eax,%ecx
  10529f:	89 fa                	mov    %edi,%edx
  1052a1:	89 c8                	mov    %ecx,%eax
  1052a3:	83 c4 10             	add    $0x10,%esp
  1052a6:	5e                   	pop    %esi
  1052a7:	5f                   	pop    %edi
  1052a8:	5d                   	pop    %ebp
  1052a9:	c3                   	ret    
  1052aa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1052b0:	39 f8                	cmp    %edi,%eax
  1052b2:	77 1c                	ja     1052d0 <__udivdi3+0x70>
  1052b4:	0f bd d0             	bsr    %eax,%edx
  1052b7:	83 f2 1f             	xor    $0x1f,%edx
  1052ba:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1052bd:	75 39                	jne    1052f8 <__udivdi3+0x98>
  1052bf:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  1052c2:	0f 86 a0 00 00 00    	jbe    105368 <__udivdi3+0x108>
  1052c8:	39 f8                	cmp    %edi,%eax
  1052ca:	0f 82 98 00 00 00    	jb     105368 <__udivdi3+0x108>
  1052d0:	31 ff                	xor    %edi,%edi
  1052d2:	31 c9                	xor    %ecx,%ecx
  1052d4:	89 c8                	mov    %ecx,%eax
  1052d6:	89 fa                	mov    %edi,%edx
  1052d8:	83 c4 10             	add    $0x10,%esp
  1052db:	5e                   	pop    %esi
  1052dc:	5f                   	pop    %edi
  1052dd:	5d                   	pop    %ebp
  1052de:	c3                   	ret    
  1052df:	90                   	nop
  1052e0:	89 d1                	mov    %edx,%ecx
  1052e2:	89 fa                	mov    %edi,%edx
  1052e4:	89 c8                	mov    %ecx,%eax
  1052e6:	31 ff                	xor    %edi,%edi
  1052e8:	f7 f6                	div    %esi
  1052ea:	89 c1                	mov    %eax,%ecx
  1052ec:	89 fa                	mov    %edi,%edx
  1052ee:	89 c8                	mov    %ecx,%eax
  1052f0:	83 c4 10             	add    $0x10,%esp
  1052f3:	5e                   	pop    %esi
  1052f4:	5f                   	pop    %edi
  1052f5:	5d                   	pop    %ebp
  1052f6:	c3                   	ret    
  1052f7:	90                   	nop
  1052f8:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  1052fc:	89 f2                	mov    %esi,%edx
  1052fe:	d3 e0                	shl    %cl,%eax
  105300:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105303:	b8 20 00 00 00       	mov    $0x20,%eax
  105308:	2b 45 f4             	sub    -0xc(%ebp),%eax
  10530b:	89 c1                	mov    %eax,%ecx
  10530d:	d3 ea                	shr    %cl,%edx
  10530f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  105313:	0b 55 ec             	or     -0x14(%ebp),%edx
  105316:	d3 e6                	shl    %cl,%esi
  105318:	89 c1                	mov    %eax,%ecx
  10531a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  10531d:	89 fe                	mov    %edi,%esi
  10531f:	d3 ee                	shr    %cl,%esi
  105321:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  105325:	89 55 ec             	mov    %edx,-0x14(%ebp)
  105328:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10532b:	d3 e7                	shl    %cl,%edi
  10532d:	89 c1                	mov    %eax,%ecx
  10532f:	d3 ea                	shr    %cl,%edx
  105331:	09 d7                	or     %edx,%edi
  105333:	89 f2                	mov    %esi,%edx
  105335:	89 f8                	mov    %edi,%eax
  105337:	f7 75 ec             	divl   -0x14(%ebp)
  10533a:	89 d6                	mov    %edx,%esi
  10533c:	89 c7                	mov    %eax,%edi
  10533e:	f7 65 e8             	mull   -0x18(%ebp)
  105341:	39 d6                	cmp    %edx,%esi
  105343:	89 55 ec             	mov    %edx,-0x14(%ebp)
  105346:	72 30                	jb     105378 <__udivdi3+0x118>
  105348:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10534b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10534f:	d3 e2                	shl    %cl,%edx
  105351:	39 c2                	cmp    %eax,%edx
  105353:	73 05                	jae    10535a <__udivdi3+0xfa>
  105355:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  105358:	74 1e                	je     105378 <__udivdi3+0x118>
  10535a:	89 f9                	mov    %edi,%ecx
  10535c:	31 ff                	xor    %edi,%edi
  10535e:	e9 71 ff ff ff       	jmp    1052d4 <__udivdi3+0x74>
  105363:	90                   	nop
  105364:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105368:	31 ff                	xor    %edi,%edi
  10536a:	b9 01 00 00 00       	mov    $0x1,%ecx
  10536f:	e9 60 ff ff ff       	jmp    1052d4 <__udivdi3+0x74>
  105374:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105378:	8d 4f ff             	lea    -0x1(%edi),%ecx
  10537b:	31 ff                	xor    %edi,%edi
  10537d:	89 c8                	mov    %ecx,%eax
  10537f:	89 fa                	mov    %edi,%edx
  105381:	83 c4 10             	add    $0x10,%esp
  105384:	5e                   	pop    %esi
  105385:	5f                   	pop    %edi
  105386:	5d                   	pop    %ebp
  105387:	c3                   	ret    
  105388:	66 90                	xchg   %ax,%ax
  10538a:	66 90                	xchg   %ax,%ax
  10538c:	66 90                	xchg   %ax,%ax
  10538e:	66 90                	xchg   %ax,%ax

00105390 <__umoddi3>:
  105390:	55                   	push   %ebp
  105391:	89 e5                	mov    %esp,%ebp
  105393:	57                   	push   %edi
  105394:	56                   	push   %esi
  105395:	83 ec 20             	sub    $0x20,%esp
  105398:	8b 55 14             	mov    0x14(%ebp),%edx
  10539b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10539e:	8b 7d 10             	mov    0x10(%ebp),%edi
  1053a1:	8b 75 0c             	mov    0xc(%ebp),%esi
  1053a4:	85 d2                	test   %edx,%edx
  1053a6:	89 c8                	mov    %ecx,%eax
  1053a8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  1053ab:	75 13                	jne    1053c0 <__umoddi3+0x30>
  1053ad:	39 f7                	cmp    %esi,%edi
  1053af:	76 3f                	jbe    1053f0 <__umoddi3+0x60>
  1053b1:	89 f2                	mov    %esi,%edx
  1053b3:	f7 f7                	div    %edi
  1053b5:	89 d0                	mov    %edx,%eax
  1053b7:	31 d2                	xor    %edx,%edx
  1053b9:	83 c4 20             	add    $0x20,%esp
  1053bc:	5e                   	pop    %esi
  1053bd:	5f                   	pop    %edi
  1053be:	5d                   	pop    %ebp
  1053bf:	c3                   	ret    
  1053c0:	39 f2                	cmp    %esi,%edx
  1053c2:	77 4c                	ja     105410 <__umoddi3+0x80>
  1053c4:	0f bd ca             	bsr    %edx,%ecx
  1053c7:	83 f1 1f             	xor    $0x1f,%ecx
  1053ca:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  1053cd:	75 51                	jne    105420 <__umoddi3+0x90>
  1053cf:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  1053d2:	0f 87 e0 00 00 00    	ja     1054b8 <__umoddi3+0x128>
  1053d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1053db:	29 f8                	sub    %edi,%eax
  1053dd:	19 d6                	sbb    %edx,%esi
  1053df:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1053e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1053e5:	89 f2                	mov    %esi,%edx
  1053e7:	83 c4 20             	add    $0x20,%esp
  1053ea:	5e                   	pop    %esi
  1053eb:	5f                   	pop    %edi
  1053ec:	5d                   	pop    %ebp
  1053ed:	c3                   	ret    
  1053ee:	66 90                	xchg   %ax,%ax
  1053f0:	85 ff                	test   %edi,%edi
  1053f2:	75 0b                	jne    1053ff <__umoddi3+0x6f>
  1053f4:	b8 01 00 00 00       	mov    $0x1,%eax
  1053f9:	31 d2                	xor    %edx,%edx
  1053fb:	f7 f7                	div    %edi
  1053fd:	89 c7                	mov    %eax,%edi
  1053ff:	89 f0                	mov    %esi,%eax
  105401:	31 d2                	xor    %edx,%edx
  105403:	f7 f7                	div    %edi
  105405:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105408:	f7 f7                	div    %edi
  10540a:	eb a9                	jmp    1053b5 <__umoddi3+0x25>
  10540c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105410:	89 c8                	mov    %ecx,%eax
  105412:	89 f2                	mov    %esi,%edx
  105414:	83 c4 20             	add    $0x20,%esp
  105417:	5e                   	pop    %esi
  105418:	5f                   	pop    %edi
  105419:	5d                   	pop    %ebp
  10541a:	c3                   	ret    
  10541b:	90                   	nop
  10541c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105420:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  105424:	d3 e2                	shl    %cl,%edx
  105426:	89 55 f4             	mov    %edx,-0xc(%ebp)
  105429:	ba 20 00 00 00       	mov    $0x20,%edx
  10542e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  105431:	89 55 ec             	mov    %edx,-0x14(%ebp)
  105434:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  105438:	89 fa                	mov    %edi,%edx
  10543a:	d3 ea                	shr    %cl,%edx
  10543c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  105440:	0b 55 f4             	or     -0xc(%ebp),%edx
  105443:	d3 e7                	shl    %cl,%edi
  105445:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  105449:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10544c:	89 f2                	mov    %esi,%edx
  10544e:	89 7d e8             	mov    %edi,-0x18(%ebp)
  105451:	89 c7                	mov    %eax,%edi
  105453:	d3 ea                	shr    %cl,%edx
  105455:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  105459:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10545c:	89 c2                	mov    %eax,%edx
  10545e:	d3 e6                	shl    %cl,%esi
  105460:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  105464:	d3 ea                	shr    %cl,%edx
  105466:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10546a:	09 d6                	or     %edx,%esi
  10546c:	89 f0                	mov    %esi,%eax
  10546e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  105471:	d3 e7                	shl    %cl,%edi
  105473:	89 f2                	mov    %esi,%edx
  105475:	f7 75 f4             	divl   -0xc(%ebp)
  105478:	89 d6                	mov    %edx,%esi
  10547a:	f7 65 e8             	mull   -0x18(%ebp)
  10547d:	39 d6                	cmp    %edx,%esi
  10547f:	72 2b                	jb     1054ac <__umoddi3+0x11c>
  105481:	39 c7                	cmp    %eax,%edi
  105483:	72 23                	jb     1054a8 <__umoddi3+0x118>
  105485:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  105489:	29 c7                	sub    %eax,%edi
  10548b:	19 d6                	sbb    %edx,%esi
  10548d:	89 f0                	mov    %esi,%eax
  10548f:	89 f2                	mov    %esi,%edx
  105491:	d3 ef                	shr    %cl,%edi
  105493:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  105497:	d3 e0                	shl    %cl,%eax
  105499:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10549d:	09 f8                	or     %edi,%eax
  10549f:	d3 ea                	shr    %cl,%edx
  1054a1:	83 c4 20             	add    $0x20,%esp
  1054a4:	5e                   	pop    %esi
  1054a5:	5f                   	pop    %edi
  1054a6:	5d                   	pop    %ebp
  1054a7:	c3                   	ret    
  1054a8:	39 d6                	cmp    %edx,%esi
  1054aa:	75 d9                	jne    105485 <__umoddi3+0xf5>
  1054ac:	2b 45 e8             	sub    -0x18(%ebp),%eax
  1054af:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  1054b2:	eb d1                	jmp    105485 <__umoddi3+0xf5>
  1054b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1054b8:	39 f2                	cmp    %esi,%edx
  1054ba:	0f 82 18 ff ff ff    	jb     1053d8 <__umoddi3+0x48>
  1054c0:	e9 1d ff ff ff       	jmp    1053e2 <__umoddi3+0x52>
