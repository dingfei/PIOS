
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
  100050:	c7 44 24 0c 80 51 10 	movl   $0x105180,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 96 51 10 	movl   $0x105196,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 ab 51 10 00 	movl   $0x1051ab,(%esp)
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
  1000c3:	e8 42 4c 00 00       	call   104d0a <memset>

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
  1000e5:	e8 a0 22 00 00       	call   10238a <spinlock_check>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000ea:	e8 2c 1f 00 00       	call   10201b <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000ef:	e8 1e 3b 00 00       	call   103c12 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000f4:	e8 4c 41 00 00       	call   104245 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000f9:	e8 f7 3d 00 00       	call   103ef5 <lapic_init>
	cpu_bootothers();	// Get other processors started
  1000fe:	e8 be 11 00 00       	call   1012c1 <cpu_bootothers>
//	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
//		cpu_onboot() ? "BP" : "AP");

	// Initialize the process management code.
	proc_init();
  100103:	e8 50 28 00 00       	call   102958 <proc_init>

	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.

	cprintf("before tt\n");
  100108:	c7 04 24 b8 51 10 00 	movl   $0x1051b8,(%esp)
  10010f:	e8 11 4a 00 00       	call   104b25 <cprintf>
	};
	
	trap_return(&tt);
	*/

	cprintf("before alloc proc_root\n");
  100114:	c7 04 24 c3 51 10 00 	movl   $0x1051c3,(%esp)
  10011b:	e8 05 4a 00 00       	call   104b25 <cprintf>
	proc_root = proc_alloc(&proc_null, 1);
  100120:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  100127:	00 
  100128:	c7 04 24 00 f4 30 00 	movl   $0x30f400,(%esp)
  10012f:	e8 72 28 00 00       	call   1029a6 <proc_alloc>
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
  100184:	c7 04 24 db 51 10 00 	movl   $0x1051db,(%esp)
  10018b:	e8 95 49 00 00       	call   104b25 <cprintf>
	proc_ready(proc_root);
  100190:	a1 e4 fa 30 00       	mov    0x30fae4,%eax
  100195:	89 04 24             	mov    %eax,(%esp)
  100198:	e8 89 29 00 00       	call   102b26 <proc_ready>
	
	cprintf("before proc_sched\n");
  10019d:	c7 04 24 ee 51 10 00 	movl   $0x1051ee,(%esp)
  1001a4:	e8 7c 49 00 00       	call   104b25 <cprintf>
	proc_sched();
  1001a9:	e8 1b 2b 00 00       	call   102cc9 <proc_sched>

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
  1001b4:	c7 04 24 01 52 10 00 	movl   $0x105201,(%esp)
  1001bb:	e8 65 49 00 00       	call   104b25 <cprintf>

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
  1001d1:	c7 44 24 0c 0c 52 10 	movl   $0x10520c,0xc(%esp)
  1001d8:	00 
  1001d9:	c7 44 24 08 96 51 10 	movl   $0x105196,0x8(%esp)
  1001e0:	00 
  1001e1:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  1001e8:	00 
  1001e9:	c7 04 24 33 52 10 00 	movl   $0x105233,(%esp)
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
  100206:	c7 44 24 0c 40 52 10 	movl   $0x105240,0xc(%esp)
  10020d:	00 
  10020e:	c7 44 24 08 96 51 10 	movl   $0x105196,0x8(%esp)
  100215:	00 
  100216:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
  10021d:	00 
  10021e:	c7 04 24 33 52 10 00 	movl   $0x105233,(%esp)
  100225:	e8 45 02 00 00       	call   10046f <debug_panic>

	// Check the system call and process scheduling code.
	proc_check();
  10022a:	e8 25 2c 00 00       	call   102e54 <proc_check>

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
  100263:	c7 44 24 0c 78 52 10 	movl   $0x105278,0xc(%esp)
  10026a:	00 
  10026b:	c7 44 24 08 8e 52 10 	movl   $0x10528e,0x8(%esp)
  100272:	00 
  100273:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10027a:	00 
  10027b:	c7 04 24 a3 52 10 00 	movl   $0x1052a3,(%esp)
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
  1002b1:	e8 91 1f 00 00       	call   102247 <spinlock_acquire>
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
  100302:	e8 bc 1f 00 00       	call   1022c3 <spinlock_release>

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
  10030f:	e8 ae 37 00 00       	call   103ac2 <serial_intr>
	kbd_intr();
  100314:	e8 04 37 00 00       	call   103a1d <kbd_intr>

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
  100370:	e8 6a 37 00 00       	call   103adf <serial_putc>
	video_putc(c);
  100375:	8b 45 08             	mov    0x8(%ebp),%eax
  100378:	89 04 24             	mov    %eax,(%esp)
  10037b:	e8 fc 32 00 00       	call   10367c <video_putc>
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
  100399:	c7 44 24 04 b0 52 10 	movl   $0x1052b0,0x4(%esp)
  1003a0:	00 
  1003a1:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  1003a8:	e8 66 1e 00 00       	call   102213 <spinlock_init_>
	video_init();
  1003ad:	e8 fe 31 00 00       	call   1035b0 <video_init>
	kbd_init();
  1003b2:	e8 7a 36 00 00       	call   103a31 <kbd_init>
	serial_init();
  1003b7:	e8 88 37 00 00       	call   103b44 <serial_init>

	if (!serial_exists)
  1003bc:	a1 e8 fa 30 00       	mov    0x30fae8,%eax
  1003c1:	85 c0                	test   %eax,%eax
  1003c3:	75 1f                	jne    1003e4 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  1003c5:	c7 44 24 08 bc 52 10 	movl   $0x1052bc,0x8(%esp)
  1003cc:	00 
  1003cd:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  1003d4:	00 
  1003d5:	c7 04 24 b0 52 10 00 	movl   $0x1052b0,(%esp)
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
  100419:	e8 ff 1e 00 00       	call   10231d <spinlock_holding>
  10041e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!already)
  100421:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100425:	75 25                	jne    10044c <cputs+0x66>
		spinlock_acquire(&cons_lock);
  100427:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  10042e:	e8 14 1e 00 00       	call   102247 <spinlock_acquire>

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
  100464:	e8 5a 1e 00 00       	call   1022c3 <spinlock_release>
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
  1004b2:	c7 04 24 d9 52 10 00 	movl   $0x1052d9,(%esp)
  1004b9:	e8 67 46 00 00       	call   104b25 <cprintf>
	vcprintf(fmt, ap);
  1004be:	8b 45 10             	mov    0x10(%ebp),%eax
  1004c1:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1004c4:	89 54 24 04          	mov    %edx,0x4(%esp)
  1004c8:	89 04 24             	mov    %eax,(%esp)
  1004cb:	e8 ec 45 00 00       	call   104abc <vcprintf>
	cprintf("\n");
  1004d0:	c7 04 24 f1 52 10 00 	movl   $0x1052f1,(%esp)
  1004d7:	e8 49 46 00 00       	call   104b25 <cprintf>

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
  100505:	c7 04 24 f3 52 10 00 	movl   $0x1052f3,(%esp)
  10050c:	e8 14 46 00 00       	call   104b25 <cprintf>
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
  10054b:	c7 04 24 00 53 10 00 	movl   $0x105300,(%esp)
  100552:	e8 ce 45 00 00       	call   104b25 <cprintf>
	vcprintf(fmt, ap);
  100557:	8b 45 10             	mov    0x10(%ebp),%eax
  10055a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10055d:	89 54 24 04          	mov    %edx,0x4(%esp)
  100561:	89 04 24             	mov    %eax,(%esp)
  100564:	e8 53 45 00 00       	call   104abc <vcprintf>
	cprintf("\n");
  100569:	c7 04 24 f1 52 10 00 	movl   $0x1052f1,(%esp)
  100570:	e8 b0 45 00 00       	call   104b25 <cprintf>
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
  1006f7:	c7 44 24 0c 1a 53 10 	movl   $0x10531a,0xc(%esp)
  1006fe:	00 
  1006ff:	c7 44 24 08 37 53 10 	movl   $0x105337,0x8(%esp)
  100706:	00 
  100707:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  10070e:	00 
  10070f:	c7 04 24 4c 53 10 00 	movl   $0x10534c,(%esp)
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
  100747:	c7 44 24 0c 59 53 10 	movl   $0x105359,0xc(%esp)
  10074e:	00 
  10074f:	c7 44 24 08 37 53 10 	movl   $0x105337,0x8(%esp)
  100756:	00 
  100757:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  10075e:	00 
  10075f:	c7 04 24 4c 53 10 00 	movl   $0x10534c,(%esp)
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
  100797:	c7 44 24 0c 72 53 10 	movl   $0x105372,0xc(%esp)
  10079e:	00 
  10079f:	c7 44 24 08 37 53 10 	movl   $0x105337,0x8(%esp)
  1007a6:	00 
  1007a7:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  1007ae:	00 
  1007af:	c7 04 24 4c 53 10 00 	movl   $0x10534c,(%esp)
  1007b6:	e8 b4 fc ff ff       	call   10046f <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1007bb:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1007be:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1007c1:	39 c2                	cmp    %eax,%edx
  1007c3:	74 24                	je     1007e9 <debug_check+0x175>
  1007c5:	c7 44 24 0c 8b 53 10 	movl   $0x10538b,0xc(%esp)
  1007cc:	00 
  1007cd:	c7 44 24 08 37 53 10 	movl   $0x105337,0x8(%esp)
  1007d4:	00 
  1007d5:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  1007dc:	00 
  1007dd:	c7 04 24 4c 53 10 00 	movl   $0x10534c,(%esp)
  1007e4:	e8 86 fc ff ff       	call   10046f <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  1007e9:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  1007ef:	8b 45 a0             	mov    -0x60(%ebp),%eax
  1007f2:	39 c2                	cmp    %eax,%edx
  1007f4:	75 24                	jne    10081a <debug_check+0x1a6>
  1007f6:	c7 44 24 0c a4 53 10 	movl   $0x1053a4,0xc(%esp)
  1007fd:	00 
  1007fe:	c7 44 24 08 37 53 10 	movl   $0x105337,0x8(%esp)
  100805:	00 
  100806:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  10080d:	00 
  10080e:	c7 04 24 4c 53 10 00 	movl   $0x10534c,(%esp)
  100815:	e8 55 fc ff ff       	call   10046f <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10081a:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100820:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100823:	39 c2                	cmp    %eax,%edx
  100825:	74 24                	je     10084b <debug_check+0x1d7>
  100827:	c7 44 24 0c bd 53 10 	movl   $0x1053bd,0xc(%esp)
  10082e:	00 
  10082f:	c7 44 24 08 37 53 10 	movl   $0x105337,0x8(%esp)
  100836:	00 
  100837:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  10083e:	00 
  10083f:	c7 04 24 4c 53 10 00 	movl   $0x10534c,(%esp)
  100846:	e8 24 fc ff ff       	call   10046f <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10084b:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100851:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100854:	39 c2                	cmp    %eax,%edx
  100856:	74 24                	je     10087c <debug_check+0x208>
  100858:	c7 44 24 0c d6 53 10 	movl   $0x1053d6,0xc(%esp)
  10085f:	00 
  100860:	c7 44 24 08 37 53 10 	movl   $0x105337,0x8(%esp)
  100867:	00 
  100868:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  10086f:	00 
  100870:	c7 04 24 4c 53 10 00 	movl   $0x10534c,(%esp)
  100877:	e8 f3 fb ff ff       	call   10046f <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10087c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100882:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  100888:	39 c2                	cmp    %eax,%edx
  10088a:	75 24                	jne    1008b0 <debug_check+0x23c>
  10088c:	c7 44 24 0c ef 53 10 	movl   $0x1053ef,0xc(%esp)
  100893:	00 
  100894:	c7 44 24 08 37 53 10 	movl   $0x105337,0x8(%esp)
  10089b:	00 
  10089c:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  1008a3:	00 
  1008a4:	c7 04 24 4c 53 10 00 	movl   $0x10534c,(%esp)
  1008ab:	e8 bf fb ff ff       	call   10046f <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1008b0:	c7 04 24 08 54 10 00 	movl   $0x105408,(%esp)
  1008b7:	e8 69 42 00 00       	call   104b25 <cprintf>
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
  1008e8:	c7 44 24 0c 24 54 10 	movl   $0x105424,0xc(%esp)
  1008ef:	00 
  1008f0:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  1008f7:	00 
  1008f8:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1008ff:	00 
  100900:	c7 04 24 4f 54 10 00 	movl   $0x10544f,(%esp)
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
  100944:	c7 44 24 04 5c 54 10 	movl   $0x10545c,0x4(%esp)
  10094b:	00 
  10094c:	c7 04 24 a0 f3 30 00 	movl   $0x30f3a0,(%esp)
  100953:	e8 bb 18 00 00       	call   102213 <spinlock_init_>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100958:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  10095f:	e8 b7 34 00 00       	call   103e1b <nvram_read16>
  100964:	c1 e0 0a             	shl    $0xa,%eax
  100967:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10096a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10096d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100972:	89 45 dc             	mov    %eax,-0x24(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100975:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  10097c:	e8 9a 34 00 00       	call   103e1b <nvram_read16>
  100981:	c1 e0 0a             	shl    $0xa,%eax
  100984:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100987:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10098a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10098f:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  100992:	c7 44 24 08 68 54 10 	movl   $0x105468,0x8(%esp)
  100999:	00 
  10099a:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
  1009a1:	00 
  1009a2:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  1009db:	c7 04 24 88 54 10 00 	movl   $0x105488,(%esp)
  1009e2:	e8 3e 41 00 00       	call   104b25 <cprintf>
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
  1009fd:	c7 04 24 a9 54 10 00 	movl   $0x1054a9,(%esp)
  100a04:	e8 1c 41 00 00       	call   104b25 <cprintf>


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
  100a27:	e8 de 42 00 00       	call   104d0a <memset>
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
  100b18:	e8 2a 17 00 00       	call   102247 <spinlock_acquire>
	pageinfo* r = mem_freelist;
  100b1d:	a1 80 f3 10 00       	mov    0x10f380,%eax
  100b22:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = mem_freelist->free_next;
  100b25:	a1 80 f3 10 00       	mov    0x10f380,%eax
  100b2a:	8b 00                	mov    (%eax),%eax
  100b2c:	a3 80 f3 10 00       	mov    %eax,0x10f380
	spinlock_release(&mem_spinlock);
  100b31:	c7 04 24 a0 f3 30 00 	movl   $0x30f3a0,(%esp)
  100b38:	e8 86 17 00 00       	call   1022c3 <spinlock_release>
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
  100b4e:	c7 44 24 08 c8 54 10 	movl   $0x1054c8,0x8(%esp)
  100b55:	00 
  100b56:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  100b5d:	00 
  100b5e:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100b65:	e8 05 f9 ff ff       	call   10046f <debug_panic>

	spinlock_acquire(&mem_spinlock);
  100b6a:	c7 04 24 a0 f3 30 00 	movl   $0x30f3a0,(%esp)
  100b71:	e8 d1 16 00 00       	call   102247 <spinlock_acquire>
	pi->free_next = mem_freelist;
  100b76:	8b 15 80 f3 10 00    	mov    0x10f380,%edx
  100b7c:	8b 45 08             	mov    0x8(%ebp),%eax
  100b7f:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100b81:	8b 45 08             	mov    0x8(%ebp),%eax
  100b84:	a3 80 f3 10 00       	mov    %eax,0x10f380
	spinlock_release(&mem_spinlock);
  100b89:	c7 04 24 a0 f3 30 00 	movl   $0x30f3a0,(%esp)
  100b90:	e8 2e 17 00 00       	call   1022c3 <spinlock_release>
	
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
  100bd5:	e8 30 41 00 00       	call   104d0a <memset>
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
  100bf3:	c7 04 24 e9 54 10 00 	movl   $0x1054e9,(%esp)
  100bfa:	e8 26 3f 00 00       	call   104b25 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100bff:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c02:	a1 84 f3 10 00       	mov    0x10f384,%eax
  100c07:	39 c2                	cmp    %eax,%edx
  100c09:	72 24                	jb     100c2f <mem_check+0x98>
  100c0b:	c7 44 24 0c 03 55 10 	movl   $0x105503,0xc(%esp)
  100c12:	00 
  100c13:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100c1a:	00 
  100c1b:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  100c22:	00 
  100c23:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100c2a:	e8 40 f8 ff ff       	call   10046f <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100c2f:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100c36:	7f 24                	jg     100c5c <mem_check+0xc5>
  100c38:	c7 44 24 0c 19 55 10 	movl   $0x105519,0xc(%esp)
  100c3f:	00 
  100c40:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100c47:	00 
  100c48:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100c4f:	00 
  100c50:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  100c7d:	c7 44 24 0c 2b 55 10 	movl   $0x10552b,0xc(%esp)
  100c84:	00 
  100c85:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100c8c:	00 
  100c8d:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  100c94:	00 
  100c95:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100c9c:	e8 ce f7 ff ff       	call   10046f <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100ca1:	e8 55 fe ff ff       	call   100afb <mem_alloc>
  100ca6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100ca9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100cad:	75 24                	jne    100cd3 <mem_check+0x13c>
  100caf:	c7 44 24 0c 34 55 10 	movl   $0x105534,0xc(%esp)
  100cb6:	00 
  100cb7:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100cbe:	00 
  100cbf:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100cc6:	00 
  100cc7:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100cce:	e8 9c f7 ff ff       	call   10046f <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100cd3:	e8 23 fe ff ff       	call   100afb <mem_alloc>
  100cd8:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100cdb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100cdf:	75 24                	jne    100d05 <mem_check+0x16e>
  100ce1:	c7 44 24 0c 3d 55 10 	movl   $0x10553d,0xc(%esp)
  100ce8:	00 
  100ce9:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100cf0:	00 
  100cf1:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100cf8:	00 
  100cf9:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100d00:	e8 6a f7 ff ff       	call   10046f <debug_panic>

	assert(pp0);
  100d05:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100d09:	75 24                	jne    100d2f <mem_check+0x198>
  100d0b:	c7 44 24 0c 46 55 10 	movl   $0x105546,0xc(%esp)
  100d12:	00 
  100d13:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100d1a:	00 
  100d1b:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  100d22:	00 
  100d23:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100d2a:	e8 40 f7 ff ff       	call   10046f <debug_panic>
	assert(pp1 && pp1 != pp0);
  100d2f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d33:	74 08                	je     100d3d <mem_check+0x1a6>
  100d35:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d38:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d3b:	75 24                	jne    100d61 <mem_check+0x1ca>
  100d3d:	c7 44 24 0c 4a 55 10 	movl   $0x10554a,0xc(%esp)
  100d44:	00 
  100d45:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100d4c:	00 
  100d4d:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100d54:	00 
  100d55:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  100d77:	c7 44 24 0c 5c 55 10 	movl   $0x10555c,0xc(%esp)
  100d7e:	00 
  100d7f:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100d86:	00 
  100d87:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100d8e:	00 
  100d8f:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  100dbc:	c7 44 24 0c 7c 55 10 	movl   $0x10557c,0xc(%esp)
  100dc3:	00 
  100dc4:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100dcb:	00 
  100dcc:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  100dd3:	00 
  100dd4:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  100e01:	c7 44 24 0c a4 55 10 	movl   $0x1055a4,0xc(%esp)
  100e08:	00 
  100e09:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100e10:	00 
  100e11:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  100e18:	00 
  100e19:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  100e46:	c7 44 24 0c cc 55 10 	movl   $0x1055cc,0xc(%esp)
  100e4d:	00 
  100e4e:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100e55:	00 
  100e56:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  100e5d:	00 
  100e5e:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  100e85:	c7 44 24 0c f2 55 10 	movl   $0x1055f2,0xc(%esp)
  100e8c:	00 
  100e8d:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100e94:	00 
  100e95:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  100e9c:	00 
  100e9d:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  100eeb:	c7 44 24 0c 2b 55 10 	movl   $0x10552b,0xc(%esp)
  100ef2:	00 
  100ef3:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100efa:	00 
  100efb:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  100f02:	00 
  100f03:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100f0a:	e8 60 f5 ff ff       	call   10046f <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100f0f:	e8 e7 fb ff ff       	call   100afb <mem_alloc>
  100f14:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100f17:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100f1b:	75 24                	jne    100f41 <mem_check+0x3aa>
  100f1d:	c7 44 24 0c 34 55 10 	movl   $0x105534,0xc(%esp)
  100f24:	00 
  100f25:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100f2c:	00 
  100f2d:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  100f34:	00 
  100f35:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100f3c:	e8 2e f5 ff ff       	call   10046f <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100f41:	e8 b5 fb ff ff       	call   100afb <mem_alloc>
  100f46:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100f49:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f4d:	75 24                	jne    100f73 <mem_check+0x3dc>
  100f4f:	c7 44 24 0c 3d 55 10 	movl   $0x10553d,0xc(%esp)
  100f56:	00 
  100f57:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100f5e:	00 
  100f5f:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  100f66:	00 
  100f67:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100f6e:	e8 fc f4 ff ff       	call   10046f <debug_panic>
	assert(pp0);
  100f73:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100f77:	75 24                	jne    100f9d <mem_check+0x406>
  100f79:	c7 44 24 0c 46 55 10 	movl   $0x105546,0xc(%esp)
  100f80:	00 
  100f81:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100f88:	00 
  100f89:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  100f90:	00 
  100f91:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  100f98:	e8 d2 f4 ff ff       	call   10046f <debug_panic>
	assert(pp1 && pp1 != pp0);
  100f9d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100fa1:	74 08                	je     100fab <mem_check+0x414>
  100fa3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100fa6:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100fa9:	75 24                	jne    100fcf <mem_check+0x438>
  100fab:	c7 44 24 0c 4a 55 10 	movl   $0x10554a,0xc(%esp)
  100fb2:	00 
  100fb3:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100fba:	00 
  100fbb:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  100fc2:	00 
  100fc3:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  100fe5:	c7 44 24 0c 5c 55 10 	movl   $0x10555c,0xc(%esp)
  100fec:	00 
  100fed:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  100ff4:	00 
  100ff5:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  100ffc:	00 
  100ffd:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
  101004:	e8 66 f4 ff ff       	call   10046f <debug_panic>
	assert(mem_alloc() == 0);
  101009:	e8 ed fa ff ff       	call   100afb <mem_alloc>
  10100e:	85 c0                	test   %eax,%eax
  101010:	74 24                	je     101036 <mem_check+0x49f>
  101012:	c7 44 24 0c f2 55 10 	movl   $0x1055f2,0xc(%esp)
  101019:	00 
  10101a:	c7 44 24 08 3a 54 10 	movl   $0x10543a,0x8(%esp)
  101021:	00 
  101022:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  101029:	00 
  10102a:	c7 04 24 5c 54 10 00 	movl   $0x10545c,(%esp)
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
  10105f:	c7 04 24 03 56 10 00 	movl   $0x105603,(%esp)
  101066:	e8 ba 3a 00 00       	call   104b25 <cprintf>
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
  1010b1:	c7 44 24 0c 1b 56 10 	movl   $0x10561b,0xc(%esp)
  1010b8:	00 
  1010b9:	c7 44 24 08 31 56 10 	movl   $0x105631,0x8(%esp)
  1010c0:	00 
  1010c1:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1010c8:	00 
  1010c9:	c7 04 24 46 56 10 00 	movl   $0x105646,(%esp)
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
  101227:	c7 44 24 0c 53 56 10 	movl   $0x105653,0xc(%esp)
  10122e:	00 
  10122f:	c7 44 24 08 31 56 10 	movl   $0x105631,0x8(%esp)
  101236:	00 
  101237:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  10123e:	00 
  10123f:	c7 04 24 5b 56 10 00 	movl   $0x10565b,(%esp)
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
  101278:	e8 8d 3a 00 00       	call   104d0a <memset>
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
  101293:	e8 e6 3a 00 00       	call   104d7e <memmove>

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
  10130d:	e8 6c 3a 00 00       	call   104d7e <memmove>
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
  101359:	e8 be 2d 00 00       	call   10411c <lapic_startcpu>

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
  1013ac:	c7 44 24 0c 80 56 10 	movl   $0x105680,0xc(%esp)
  1013b3:	00 
  1013b4:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  1013bb:	00 
  1013bc:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1013c3:	00 
  1013c4:	c7 04 24 ab 56 10 00 	movl   $0x1056ab,(%esp)
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
  1015e3:	e8 d0 02 00 00       	call   1018b8 <trap_check_kernel>
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
  1015f8:	8b 04 85 80 5a 10 00 	mov    0x105a80(,%eax,4),%eax
  1015ff:	eb 25                	jmp    101626 <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  101601:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  101605:	75 07                	jne    10160e <trap_name+0x24>
		return "System call";
  101607:	b8 b8 56 10 00       	mov    $0x1056b8,%eax
  10160c:	eb 18                	jmp    101626 <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  10160e:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  101612:	7e 0d                	jle    101621 <trap_name+0x37>
  101614:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  101618:	7f 07                	jg     101621 <trap_name+0x37>
		return "Hardware Interrupt";
  10161a:	b8 c4 56 10 00       	mov    $0x1056c4,%eax
  10161f:	eb 05                	jmp    101626 <trap_name+0x3c>
	return "(unknown trap)";
  101621:	b8 d7 56 10 00       	mov    $0x1056d7,%eax
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
  101637:	c7 04 24 e6 56 10 00 	movl   $0x1056e6,(%esp)
  10163e:	e8 e2 34 00 00       	call   104b25 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  101643:	8b 45 08             	mov    0x8(%ebp),%eax
  101646:	8b 40 04             	mov    0x4(%eax),%eax
  101649:	89 44 24 04          	mov    %eax,0x4(%esp)
  10164d:	c7 04 24 f5 56 10 00 	movl   $0x1056f5,(%esp)
  101654:	e8 cc 34 00 00       	call   104b25 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101659:	8b 45 08             	mov    0x8(%ebp),%eax
  10165c:	8b 40 08             	mov    0x8(%eax),%eax
  10165f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101663:	c7 04 24 04 57 10 00 	movl   $0x105704,(%esp)
  10166a:	e8 b6 34 00 00       	call   104b25 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  10166f:	8b 45 08             	mov    0x8(%ebp),%eax
  101672:	8b 40 10             	mov    0x10(%eax),%eax
  101675:	89 44 24 04          	mov    %eax,0x4(%esp)
  101679:	c7 04 24 13 57 10 00 	movl   $0x105713,(%esp)
  101680:	e8 a0 34 00 00       	call   104b25 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101685:	8b 45 08             	mov    0x8(%ebp),%eax
  101688:	8b 40 14             	mov    0x14(%eax),%eax
  10168b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10168f:	c7 04 24 22 57 10 00 	movl   $0x105722,(%esp)
  101696:	e8 8a 34 00 00       	call   104b25 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  10169b:	8b 45 08             	mov    0x8(%ebp),%eax
  10169e:	8b 40 18             	mov    0x18(%eax),%eax
  1016a1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016a5:	c7 04 24 31 57 10 00 	movl   $0x105731,(%esp)
  1016ac:	e8 74 34 00 00       	call   104b25 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1016b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1016b4:	8b 40 1c             	mov    0x1c(%eax),%eax
  1016b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016bb:	c7 04 24 40 57 10 00 	movl   $0x105740,(%esp)
  1016c2:	e8 5e 34 00 00       	call   104b25 <cprintf>
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
  1016d6:	c7 04 24 4f 57 10 00 	movl   $0x10574f,(%esp)
  1016dd:	e8 43 34 00 00       	call   104b25 <cprintf>
	trap_print_regs(&tf->regs);
  1016e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1016e5:	89 04 24             	mov    %eax,(%esp)
  1016e8:	e8 3b ff ff ff       	call   101628 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  1016ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1016f0:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  1016f4:	0f b7 c0             	movzwl %ax,%eax
  1016f7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016fb:	c7 04 24 61 57 10 00 	movl   $0x105761,(%esp)
  101702:	e8 1e 34 00 00       	call   104b25 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101707:	8b 45 08             	mov    0x8(%ebp),%eax
  10170a:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10170e:	0f b7 c0             	movzwl %ax,%eax
  101711:	89 44 24 04          	mov    %eax,0x4(%esp)
  101715:	c7 04 24 74 57 10 00 	movl   $0x105774,(%esp)
  10171c:	e8 04 34 00 00       	call   104b25 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101721:	8b 45 08             	mov    0x8(%ebp),%eax
  101724:	8b 40 30             	mov    0x30(%eax),%eax
  101727:	89 04 24             	mov    %eax,(%esp)
  10172a:	e8 bb fe ff ff       	call   1015ea <trap_name>
  10172f:	8b 55 08             	mov    0x8(%ebp),%edx
  101732:	8b 52 30             	mov    0x30(%edx),%edx
  101735:	89 44 24 08          	mov    %eax,0x8(%esp)
  101739:	89 54 24 04          	mov    %edx,0x4(%esp)
  10173d:	c7 04 24 87 57 10 00 	movl   $0x105787,(%esp)
  101744:	e8 dc 33 00 00       	call   104b25 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101749:	8b 45 08             	mov    0x8(%ebp),%eax
  10174c:	8b 40 34             	mov    0x34(%eax),%eax
  10174f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101753:	c7 04 24 99 57 10 00 	movl   $0x105799,(%esp)
  10175a:	e8 c6 33 00 00       	call   104b25 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  10175f:	8b 45 08             	mov    0x8(%ebp),%eax
  101762:	8b 40 38             	mov    0x38(%eax),%eax
  101765:	89 44 24 04          	mov    %eax,0x4(%esp)
  101769:	c7 04 24 a8 57 10 00 	movl   $0x1057a8,(%esp)
  101770:	e8 b0 33 00 00       	call   104b25 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101775:	8b 45 08             	mov    0x8(%ebp),%eax
  101778:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10177c:	0f b7 c0             	movzwl %ax,%eax
  10177f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101783:	c7 04 24 b7 57 10 00 	movl   $0x1057b7,(%esp)
  10178a:	e8 96 33 00 00       	call   104b25 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  10178f:	8b 45 08             	mov    0x8(%ebp),%eax
  101792:	8b 40 40             	mov    0x40(%eax),%eax
  101795:	89 44 24 04          	mov    %eax,0x4(%esp)
  101799:	c7 04 24 ca 57 10 00 	movl   $0x1057ca,(%esp)
  1017a0:	e8 80 33 00 00       	call   104b25 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1017a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1017a8:	8b 40 44             	mov    0x44(%eax),%eax
  1017ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017af:	c7 04 24 d9 57 10 00 	movl   $0x1057d9,(%esp)
  1017b6:	e8 6a 33 00 00       	call   104b25 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1017bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1017be:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1017c2:	0f b7 c0             	movzwl %ax,%eax
  1017c5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017c9:	c7 04 24 e8 57 10 00 	movl   $0x1057e8,(%esp)
  1017d0:	e8 50 33 00 00       	call   104b25 <cprintf>
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
  10181a:	75 27                	jne    101843 <trap+0x6c>
		syscall(tf);
  10181c:	8b 45 08             	mov    0x8(%ebp),%eax
  10181f:	89 04 24             	mov    %eax,(%esp)
  101822:	e8 58 1d 00 00       	call   10357f <syscall>
		panic("unhandler system call\n");
  101827:	c7 44 24 08 fb 57 10 	movl   $0x1057fb,0x8(%esp)
  10182e:	00 
  10182f:	c7 44 24 04 93 00 00 	movl   $0x93,0x4(%esp)
  101836:	00 
  101837:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  10183e:	e8 2c ec ff ff       	call   10046f <debug_panic>
	}
	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
  101843:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  10184a:	e8 ce 0a 00 00       	call   10231d <spinlock_holding>
  10184f:	85 c0                	test   %eax,%eax
  101851:	74 0c                	je     10185f <trap+0x88>
		spinlock_release(&cons_lock);
  101853:	c7 04 24 40 f3 10 00 	movl   $0x10f340,(%esp)
  10185a:	e8 64 0a 00 00       	call   1022c3 <spinlock_release>
	trap_print(tf);
  10185f:	8b 45 08             	mov    0x8(%ebp),%eax
  101862:	89 04 24             	mov    %eax,(%esp)
  101865:	e8 5f fe ff ff       	call   1016c9 <trap_print>
	panic("unhandled trap");
  10186a:	c7 44 24 08 1e 58 10 	movl   $0x10581e,0x8(%esp)
  101871:	00 
  101872:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  101879:	00 
  10187a:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  101881:	e8 e9 eb ff ff       	call   10046f <debug_panic>

00101886 <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101886:	55                   	push   %ebp
  101887:	89 e5                	mov    %esp,%ebp
  101889:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  10188c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10188f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101892:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101895:	8b 00                	mov    (%eax),%eax
  101897:	89 c2                	mov    %eax,%edx
  101899:	8b 45 08             	mov    0x8(%ebp),%eax
  10189c:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  10189f:	8b 45 08             	mov    0x8(%ebp),%eax
  1018a2:	8b 40 30             	mov    0x30(%eax),%eax
  1018a5:	89 c2                	mov    %eax,%edx
  1018a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1018aa:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  1018ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1018b0:	89 04 24             	mov    %eax,(%esp)
  1018b3:	e8 38 78 00 00       	call   1090f0 <trap_return>

001018b8 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  1018b8:	55                   	push   %ebp
  1018b9:	89 e5                	mov    %esp,%ebp
  1018bb:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1018be:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  1018c1:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  1018c5:	0f b7 c0             	movzwl %ax,%eax
  1018c8:	83 e0 03             	and    $0x3,%eax
  1018cb:	85 c0                	test   %eax,%eax
  1018cd:	74 24                	je     1018f3 <trap_check_kernel+0x3b>
  1018cf:	c7 44 24 0c 2d 58 10 	movl   $0x10582d,0xc(%esp)
  1018d6:	00 
  1018d7:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  1018de:	00 
  1018df:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  1018e6:	00 
  1018e7:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  1018ee:	e8 7c eb ff ff       	call   10046f <debug_panic>

	cpu *c = cpu_cur();
  1018f3:	e8 8a fa ff ff       	call   101382 <cpu_cur>
  1018f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  1018fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1018fe:	c7 80 a0 00 00 00 86 	movl   $0x101886,0xa0(%eax)
  101905:	18 10 00 
	trap_check(&c->recoverdata);
  101908:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10190b:	05 a4 00 00 00       	add    $0xa4,%eax
  101910:	89 04 24             	mov    %eax,(%esp)
  101913:	e8 96 00 00 00       	call   1019ae <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101918:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10191b:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101922:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  101925:	c7 04 24 44 58 10 00 	movl   $0x105844,(%esp)
  10192c:	e8 f4 31 00 00       	call   104b25 <cprintf>
}
  101931:	c9                   	leave  
  101932:	c3                   	ret    

00101933 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101933:	55                   	push   %ebp
  101934:	89 e5                	mov    %esp,%ebp
  101936:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101939:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  10193c:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101940:	0f b7 c0             	movzwl %ax,%eax
  101943:	83 e0 03             	and    $0x3,%eax
  101946:	83 f8 03             	cmp    $0x3,%eax
  101949:	74 24                	je     10196f <trap_check_user+0x3c>
  10194b:	c7 44 24 0c 64 58 10 	movl   $0x105864,0xc(%esp)
  101952:	00 
  101953:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  10195a:	00 
  10195b:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
  101962:	00 
  101963:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  10196a:	e8 00 eb ff ff       	call   10046f <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  10196f:	c7 45 f0 00 80 10 00 	movl   $0x108000,-0x10(%ebp)
	c->recover = trap_check_recover;
  101976:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101979:	c7 80 a0 00 00 00 86 	movl   $0x101886,0xa0(%eax)
  101980:	18 10 00 
	trap_check(&c->recoverdata);
  101983:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101986:	05 a4 00 00 00       	add    $0xa4,%eax
  10198b:	89 04 24             	mov    %eax,(%esp)
  10198e:	e8 1b 00 00 00       	call   1019ae <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101993:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101996:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  10199d:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  1019a0:	c7 04 24 79 58 10 00 	movl   $0x105879,(%esp)
  1019a7:	e8 79 31 00 00       	call   104b25 <cprintf>
}
  1019ac:	c9                   	leave  
  1019ad:	c3                   	ret    

001019ae <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  1019ae:	55                   	push   %ebp
  1019af:	89 e5                	mov    %esp,%ebp
  1019b1:	57                   	push   %edi
  1019b2:	56                   	push   %esi
  1019b3:	53                   	push   %ebx
  1019b4:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  1019b7:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  1019be:	8b 45 08             	mov    0x8(%ebp),%eax
  1019c1:	8d 55 d8             	lea    -0x28(%ebp),%edx
  1019c4:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  1019c6:	c7 45 d8 d4 19 10 00 	movl   $0x1019d4,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1019cd:	b8 00 00 00 00       	mov    $0x0,%eax
  1019d2:	f7 f0                	div    %eax

001019d4 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1019d4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1019d7:	85 c0                	test   %eax,%eax
  1019d9:	74 24                	je     1019ff <after_div0+0x2b>
  1019db:	c7 44 24 0c 97 58 10 	movl   $0x105897,0xc(%esp)
  1019e2:	00 
  1019e3:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  1019ea:	00 
  1019eb:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  1019f2:	00 
  1019f3:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  1019fa:	e8 70 ea ff ff       	call   10046f <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1019ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101a02:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101a07:	74 24                	je     101a2d <after_div0+0x59>
  101a09:	c7 44 24 0c af 58 10 	movl   $0x1058af,0xc(%esp)
  101a10:	00 
  101a11:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  101a18:	00 
  101a19:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  101a20:	00 
  101a21:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  101a28:	e8 42 ea ff ff       	call   10046f <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101a2d:	c7 45 d8 35 1a 10 00 	movl   $0x101a35,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  101a34:	cc                   	int3   

00101a35 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101a35:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101a38:	83 f8 03             	cmp    $0x3,%eax
  101a3b:	74 24                	je     101a61 <after_breakpoint+0x2c>
  101a3d:	c7 44 24 0c c4 58 10 	movl   $0x1058c4,0xc(%esp)
  101a44:	00 
  101a45:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  101a4c:	00 
  101a4d:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  101a54:	00 
  101a55:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  101a5c:	e8 0e ea ff ff       	call   10046f <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101a61:	c7 45 d8 70 1a 10 00 	movl   $0x101a70,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101a68:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101a6d:	01 c0                	add    %eax,%eax
  101a6f:	ce                   	into   

00101a70 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101a70:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101a73:	83 f8 04             	cmp    $0x4,%eax
  101a76:	74 24                	je     101a9c <after_overflow+0x2c>
  101a78:	c7 44 24 0c db 58 10 	movl   $0x1058db,0xc(%esp)
  101a7f:	00 
  101a80:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  101a87:	00 
  101a88:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
  101a8f:	00 
  101a90:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  101a97:	e8 d3 e9 ff ff       	call   10046f <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101a9c:	c7 45 d8 b9 1a 10 00 	movl   $0x101ab9,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  101aa3:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101aaa:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  101ab1:	b8 00 00 00 00       	mov    $0x0,%eax
  101ab6:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101ab9 <after_bound>:
	assert(args.trapno == T_BOUND);
  101ab9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101abc:	83 f8 05             	cmp    $0x5,%eax
  101abf:	74 24                	je     101ae5 <after_bound+0x2c>
  101ac1:	c7 44 24 0c f2 58 10 	movl   $0x1058f2,0xc(%esp)
  101ac8:	00 
  101ac9:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  101ad0:	00 
  101ad1:	c7 44 24 04 f4 00 00 	movl   $0xf4,0x4(%esp)
  101ad8:	00 
  101ad9:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  101ae0:	e8 8a e9 ff ff       	call   10046f <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  101ae5:	c7 45 d8 ee 1a 10 00 	movl   $0x101aee,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101aec:	0f 0b                	ud2    

00101aee <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101aee:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101af1:	83 f8 06             	cmp    $0x6,%eax
  101af4:	74 24                	je     101b1a <after_illegal+0x2c>
  101af6:	c7 44 24 0c 09 59 10 	movl   $0x105909,0xc(%esp)
  101afd:	00 
  101afe:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  101b05:	00 
  101b06:	c7 44 24 04 f9 00 00 	movl   $0xf9,0x4(%esp)
  101b0d:	00 
  101b0e:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  101b15:	e8 55 e9 ff ff       	call   10046f <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101b1a:	c7 45 d8 28 1b 10 00 	movl   $0x101b28,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101b21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101b26:	8e e0                	mov    %eax,%fs

00101b28 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101b28:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101b2b:	83 f8 0d             	cmp    $0xd,%eax
  101b2e:	74 24                	je     101b54 <after_gpfault+0x2c>
  101b30:	c7 44 24 0c 20 59 10 	movl   $0x105920,0xc(%esp)
  101b37:	00 
  101b38:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  101b3f:	00 
  101b40:	c7 44 24 04 fe 00 00 	movl   $0xfe,0x4(%esp)
  101b47:	00 
  101b48:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  101b4f:	e8 1b e9 ff ff       	call   10046f <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101b54:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  101b57:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101b5b:	0f b7 c0             	movzwl %ax,%eax
  101b5e:	83 e0 03             	and    $0x3,%eax
  101b61:	85 c0                	test   %eax,%eax
  101b63:	74 3a                	je     101b9f <after_priv+0x2c>
		args.reip = after_priv;
  101b65:	c7 45 d8 73 1b 10 00 	movl   $0x101b73,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101b6c:	0f 01 1d 04 90 10 00 	lidtl  0x109004

00101b73 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101b73:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101b76:	83 f8 0d             	cmp    $0xd,%eax
  101b79:	74 24                	je     101b9f <after_priv+0x2c>
  101b7b:	c7 44 24 0c 20 59 10 	movl   $0x105920,0xc(%esp)
  101b82:	00 
  101b83:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  101b8a:	00 
  101b8b:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
  101b92:	00 
  101b93:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  101b9a:	e8 d0 e8 ff ff       	call   10046f <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101b9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101ba2:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101ba7:	74 24                	je     101bcd <after_priv+0x5a>
  101ba9:	c7 44 24 0c af 58 10 	movl   $0x1058af,0xc(%esp)
  101bb0:	00 
  101bb1:	c7 44 24 08 96 56 10 	movl   $0x105696,0x8(%esp)
  101bb8:	00 
  101bb9:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
  101bc0:	00 
  101bc1:	c7 04 24 12 58 10 00 	movl   $0x105812,(%esp)
  101bc8:	e8 a2 e8 ff ff       	call   10046f <debug_panic>
	//cprintf("sfsfsfsfsfsfsfsfsf\n");
	*argsp = NULL;	// recovery mechanism not needed anymore
  101bcd:	8b 45 08             	mov    0x8(%ebp),%eax
  101bd0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101bd6:	83 c4 3c             	add    $0x3c,%esp
  101bd9:	5b                   	pop    %ebx
  101bda:	5e                   	pop    %esi
  101bdb:	5f                   	pop    %edi
  101bdc:	5d                   	pop    %ebp
  101bdd:	c3                   	ret    

00101bde <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  101bde:	6a 00                	push   $0x0
  101be0:	6a 00                	push   $0x0
  101be2:	e9 ed 74 00 00       	jmp    1090d4 <_alltraps>
  101be7:	90                   	nop

00101be8 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  101be8:	6a 00                	push   $0x0
  101bea:	6a 01                	push   $0x1
  101bec:	e9 e3 74 00 00       	jmp    1090d4 <_alltraps>
  101bf1:	90                   	nop

00101bf2 <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  101bf2:	6a 00                	push   $0x0
  101bf4:	6a 02                	push   $0x2
  101bf6:	e9 d9 74 00 00       	jmp    1090d4 <_alltraps>
  101bfb:	90                   	nop

00101bfc <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  101bfc:	6a 00                	push   $0x0
  101bfe:	6a 03                	push   $0x3
  101c00:	e9 cf 74 00 00       	jmp    1090d4 <_alltraps>
  101c05:	90                   	nop

00101c06 <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  101c06:	6a 00                	push   $0x0
  101c08:	6a 04                	push   $0x4
  101c0a:	e9 c5 74 00 00       	jmp    1090d4 <_alltraps>
  101c0f:	90                   	nop

00101c10 <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  101c10:	6a 00                	push   $0x0
  101c12:	6a 05                	push   $0x5
  101c14:	e9 bb 74 00 00       	jmp    1090d4 <_alltraps>
  101c19:	90                   	nop

00101c1a <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  101c1a:	6a 00                	push   $0x0
  101c1c:	6a 06                	push   $0x6
  101c1e:	e9 b1 74 00 00       	jmp    1090d4 <_alltraps>
  101c23:	90                   	nop

00101c24 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  101c24:	6a 00                	push   $0x0
  101c26:	6a 07                	push   $0x7
  101c28:	e9 a7 74 00 00       	jmp    1090d4 <_alltraps>
  101c2d:	90                   	nop

00101c2e <vector8>:
TRAPHANDLER(vector8, 8)
  101c2e:	6a 08                	push   $0x8
  101c30:	e9 9f 74 00 00       	jmp    1090d4 <_alltraps>
  101c35:	90                   	nop

00101c36 <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  101c36:	6a 00                	push   $0x0
  101c38:	6a 09                	push   $0x9
  101c3a:	e9 95 74 00 00       	jmp    1090d4 <_alltraps>
  101c3f:	90                   	nop

00101c40 <vector10>:
TRAPHANDLER(vector10, 10)
  101c40:	6a 0a                	push   $0xa
  101c42:	e9 8d 74 00 00       	jmp    1090d4 <_alltraps>
  101c47:	90                   	nop

00101c48 <vector11>:
TRAPHANDLER(vector11, 11)
  101c48:	6a 0b                	push   $0xb
  101c4a:	e9 85 74 00 00       	jmp    1090d4 <_alltraps>
  101c4f:	90                   	nop

00101c50 <vector12>:
TRAPHANDLER(vector12, 12)
  101c50:	6a 0c                	push   $0xc
  101c52:	e9 7d 74 00 00       	jmp    1090d4 <_alltraps>
  101c57:	90                   	nop

00101c58 <vector13>:
TRAPHANDLER(vector13, 13)
  101c58:	6a 0d                	push   $0xd
  101c5a:	e9 75 74 00 00       	jmp    1090d4 <_alltraps>
  101c5f:	90                   	nop

00101c60 <vector14>:
TRAPHANDLER(vector14, 14)
  101c60:	6a 0e                	push   $0xe
  101c62:	e9 6d 74 00 00       	jmp    1090d4 <_alltraps>
  101c67:	90                   	nop

00101c68 <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101c68:	6a 00                	push   $0x0
  101c6a:	6a 0f                	push   $0xf
  101c6c:	e9 63 74 00 00       	jmp    1090d4 <_alltraps>
  101c71:	90                   	nop

00101c72 <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  101c72:	6a 00                	push   $0x0
  101c74:	6a 10                	push   $0x10
  101c76:	e9 59 74 00 00       	jmp    1090d4 <_alltraps>
  101c7b:	90                   	nop

00101c7c <vector17>:
TRAPHANDLER(vector17, 17)
  101c7c:	6a 11                	push   $0x11
  101c7e:	e9 51 74 00 00       	jmp    1090d4 <_alltraps>
  101c83:	90                   	nop

00101c84 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  101c84:	6a 00                	push   $0x0
  101c86:	6a 12                	push   $0x12
  101c88:	e9 47 74 00 00       	jmp    1090d4 <_alltraps>
  101c8d:	90                   	nop

00101c8e <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  101c8e:	6a 00                	push   $0x0
  101c90:	6a 13                	push   $0x13
  101c92:	e9 3d 74 00 00       	jmp    1090d4 <_alltraps>
  101c97:	90                   	nop

00101c98 <vector20>:
TRAPHANDLER_NOEC(vector20, 20)
  101c98:	6a 00                	push   $0x0
  101c9a:	6a 14                	push   $0x14
  101c9c:	e9 33 74 00 00       	jmp    1090d4 <_alltraps>
  101ca1:	90                   	nop

00101ca2 <vector21>:
TRAPHANDLER_NOEC(vector21, 21)
  101ca2:	6a 00                	push   $0x0
  101ca4:	6a 15                	push   $0x15
  101ca6:	e9 29 74 00 00       	jmp    1090d4 <_alltraps>
  101cab:	90                   	nop

00101cac <vector22>:
TRAPHANDLER_NOEC(vector22, 22)
  101cac:	6a 00                	push   $0x0
  101cae:	6a 16                	push   $0x16
  101cb0:	e9 1f 74 00 00       	jmp    1090d4 <_alltraps>
  101cb5:	90                   	nop

00101cb6 <vector23>:
TRAPHANDLER_NOEC(vector23, 23)
  101cb6:	6a 00                	push   $0x0
  101cb8:	6a 17                	push   $0x17
  101cba:	e9 15 74 00 00       	jmp    1090d4 <_alltraps>
  101cbf:	90                   	nop

00101cc0 <vector24>:
TRAPHANDLER_NOEC(vector24, 24)
  101cc0:	6a 00                	push   $0x0
  101cc2:	6a 18                	push   $0x18
  101cc4:	e9 0b 74 00 00       	jmp    1090d4 <_alltraps>
  101cc9:	90                   	nop

00101cca <vector25>:
TRAPHANDLER_NOEC(vector25, 25)
  101cca:	6a 00                	push   $0x0
  101ccc:	6a 19                	push   $0x19
  101cce:	e9 01 74 00 00       	jmp    1090d4 <_alltraps>
  101cd3:	90                   	nop

00101cd4 <vector26>:
TRAPHANDLER_NOEC(vector26, 26)
  101cd4:	6a 00                	push   $0x0
  101cd6:	6a 1a                	push   $0x1a
  101cd8:	e9 f7 73 00 00       	jmp    1090d4 <_alltraps>
  101cdd:	90                   	nop

00101cde <vector27>:
TRAPHANDLER_NOEC(vector27, 27)
  101cde:	6a 00                	push   $0x0
  101ce0:	6a 1b                	push   $0x1b
  101ce2:	e9 ed 73 00 00       	jmp    1090d4 <_alltraps>
  101ce7:	90                   	nop

00101ce8 <vector28>:
TRAPHANDLER_NOEC(vector28, 28)
  101ce8:	6a 00                	push   $0x0
  101cea:	6a 1c                	push   $0x1c
  101cec:	e9 e3 73 00 00       	jmp    1090d4 <_alltraps>
  101cf1:	90                   	nop

00101cf2 <vector29>:
TRAPHANDLER_NOEC(vector29, 29)
  101cf2:	6a 00                	push   $0x0
  101cf4:	6a 1d                	push   $0x1d
  101cf6:	e9 d9 73 00 00       	jmp    1090d4 <_alltraps>
  101cfb:	90                   	nop

00101cfc <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101cfc:	6a 00                	push   $0x0
  101cfe:	6a 1e                	push   $0x1e
  101d00:	e9 cf 73 00 00       	jmp    1090d4 <_alltraps>
  101d05:	90                   	nop

00101d06 <vector31>:
TRAPHANDLER_NOEC(vector31, 31)
  101d06:	6a 00                	push   $0x0
  101d08:	6a 1f                	push   $0x1f
  101d0a:	e9 c5 73 00 00       	jmp    1090d4 <_alltraps>
  101d0f:	90                   	nop

00101d10 <vector32>:
TRAPHANDLER_NOEC(vector32, 32)
  101d10:	6a 00                	push   $0x0
  101d12:	6a 20                	push   $0x20
  101d14:	e9 bb 73 00 00       	jmp    1090d4 <_alltraps>
  101d19:	90                   	nop

00101d1a <vector33>:
TRAPHANDLER_NOEC(vector33, 33)
  101d1a:	6a 00                	push   $0x0
  101d1c:	6a 21                	push   $0x21
  101d1e:	e9 b1 73 00 00       	jmp    1090d4 <_alltraps>
  101d23:	90                   	nop

00101d24 <vector34>:
TRAPHANDLER_NOEC(vector34, 34)
  101d24:	6a 00                	push   $0x0
  101d26:	6a 22                	push   $0x22
  101d28:	e9 a7 73 00 00       	jmp    1090d4 <_alltraps>
  101d2d:	90                   	nop

00101d2e <vector35>:
TRAPHANDLER_NOEC(vector35, 35)
  101d2e:	6a 00                	push   $0x0
  101d30:	6a 23                	push   $0x23
  101d32:	e9 9d 73 00 00       	jmp    1090d4 <_alltraps>
  101d37:	90                   	nop

00101d38 <vector36>:
TRAPHANDLER_NOEC(vector36, 36)
  101d38:	6a 00                	push   $0x0
  101d3a:	6a 24                	push   $0x24
  101d3c:	e9 93 73 00 00       	jmp    1090d4 <_alltraps>
  101d41:	90                   	nop

00101d42 <vector37>:
TRAPHANDLER_NOEC(vector37, 37)
  101d42:	6a 00                	push   $0x0
  101d44:	6a 25                	push   $0x25
  101d46:	e9 89 73 00 00       	jmp    1090d4 <_alltraps>
  101d4b:	90                   	nop

00101d4c <vector38>:
TRAPHANDLER_NOEC(vector38, 38)
  101d4c:	6a 00                	push   $0x0
  101d4e:	6a 26                	push   $0x26
  101d50:	e9 7f 73 00 00       	jmp    1090d4 <_alltraps>
  101d55:	90                   	nop

00101d56 <vector39>:
TRAPHANDLER_NOEC(vector39, 39)
  101d56:	6a 00                	push   $0x0
  101d58:	6a 27                	push   $0x27
  101d5a:	e9 75 73 00 00       	jmp    1090d4 <_alltraps>
  101d5f:	90                   	nop

00101d60 <vector40>:
TRAPHANDLER_NOEC(vector40, 40)
  101d60:	6a 00                	push   $0x0
  101d62:	6a 28                	push   $0x28
  101d64:	e9 6b 73 00 00       	jmp    1090d4 <_alltraps>
  101d69:	90                   	nop

00101d6a <vector41>:
TRAPHANDLER_NOEC(vector41, 41)
  101d6a:	6a 00                	push   $0x0
  101d6c:	6a 29                	push   $0x29
  101d6e:	e9 61 73 00 00       	jmp    1090d4 <_alltraps>
  101d73:	90                   	nop

00101d74 <vector42>:
TRAPHANDLER_NOEC(vector42, 42)
  101d74:	6a 00                	push   $0x0
  101d76:	6a 2a                	push   $0x2a
  101d78:	e9 57 73 00 00       	jmp    1090d4 <_alltraps>
  101d7d:	90                   	nop

00101d7e <vector43>:
TRAPHANDLER_NOEC(vector43, 43)
  101d7e:	6a 00                	push   $0x0
  101d80:	6a 2b                	push   $0x2b
  101d82:	e9 4d 73 00 00       	jmp    1090d4 <_alltraps>
  101d87:	90                   	nop

00101d88 <vector44>:
TRAPHANDLER_NOEC(vector44, 44)
  101d88:	6a 00                	push   $0x0
  101d8a:	6a 2c                	push   $0x2c
  101d8c:	e9 43 73 00 00       	jmp    1090d4 <_alltraps>
  101d91:	90                   	nop

00101d92 <vector45>:
TRAPHANDLER_NOEC(vector45, 45)
  101d92:	6a 00                	push   $0x0
  101d94:	6a 2d                	push   $0x2d
  101d96:	e9 39 73 00 00       	jmp    1090d4 <_alltraps>
  101d9b:	90                   	nop

00101d9c <vector46>:
TRAPHANDLER_NOEC(vector46, 46)
  101d9c:	6a 00                	push   $0x0
  101d9e:	6a 2e                	push   $0x2e
  101da0:	e9 2f 73 00 00       	jmp    1090d4 <_alltraps>
  101da5:	90                   	nop

00101da6 <vector47>:
TRAPHANDLER_NOEC(vector47, 47)
  101da6:	6a 00                	push   $0x0
  101da8:	6a 2f                	push   $0x2f
  101daa:	e9 25 73 00 00       	jmp    1090d4 <_alltraps>
  101daf:	90                   	nop

00101db0 <vector48>:
TRAPHANDLER_NOEC(vector48, 48)
  101db0:	6a 00                	push   $0x0
  101db2:	6a 30                	push   $0x30
  101db4:	e9 1b 73 00 00       	jmp    1090d4 <_alltraps>

00101db9 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101db9:	55                   	push   %ebp
  101dba:	89 e5                	mov    %esp,%ebp
  101dbc:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101dbf:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101dc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101dc5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101dc8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101dcb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101dd0:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101dd3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101dd6:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101ddc:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101de1:	74 24                	je     101e07 <cpu_cur+0x4e>
  101de3:	c7 44 24 0c d0 5a 10 	movl   $0x105ad0,0xc(%esp)
  101dea:	00 
  101deb:	c7 44 24 08 e6 5a 10 	movl   $0x105ae6,0x8(%esp)
  101df2:	00 
  101df3:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101dfa:	00 
  101dfb:	c7 04 24 fb 5a 10 00 	movl   $0x105afb,(%esp)
  101e02:	e8 68 e6 ff ff       	call   10046f <debug_panic>
	return c;
  101e07:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101e0a:	c9                   	leave  
  101e0b:	c3                   	ret    

00101e0c <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101e0c:	55                   	push   %ebp
  101e0d:	89 e5                	mov    %esp,%ebp
  101e0f:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101e12:	e8 a2 ff ff ff       	call   101db9 <cpu_cur>
  101e17:	3d 00 80 10 00       	cmp    $0x108000,%eax
  101e1c:	0f 94 c0             	sete   %al
  101e1f:	0f b6 c0             	movzbl %al,%eax
}
  101e22:	c9                   	leave  
  101e23:	c3                   	ret    

00101e24 <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  101e24:	55                   	push   %ebp
  101e25:	89 e5                	mov    %esp,%ebp
  101e27:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  101e2a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	for (i = 0; i < len; i++)
  101e31:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  101e38:	eb 13                	jmp    101e4d <sum+0x29>
		sum += addr[i];
  101e3a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101e3d:	03 45 08             	add    0x8(%ebp),%eax
  101e40:	0f b6 00             	movzbl (%eax),%eax
  101e43:	0f b6 c0             	movzbl %al,%eax
  101e46:	01 45 fc             	add    %eax,-0x4(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  101e49:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  101e4d:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101e50:	3b 45 0c             	cmp    0xc(%ebp),%eax
  101e53:	7c e5                	jl     101e3a <sum+0x16>
		sum += addr[i];
	return sum;
  101e55:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101e58:	c9                   	leave  
  101e59:	c3                   	ret    

00101e5a <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  101e5a:	55                   	push   %ebp
  101e5b:	89 e5                	mov    %esp,%ebp
  101e5d:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  101e60:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e63:	03 45 08             	add    0x8(%ebp),%eax
  101e66:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  101e69:	8b 45 08             	mov    0x8(%ebp),%eax
  101e6c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101e6f:	eb 3f                	jmp    101eb0 <mpsearch1+0x56>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  101e71:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  101e78:	00 
  101e79:	c7 44 24 04 08 5b 10 	movl   $0x105b08,0x4(%esp)
  101e80:	00 
  101e81:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101e84:	89 04 24             	mov    %eax,(%esp)
  101e87:	e8 ee 2f 00 00       	call   104e7a <memcmp>
  101e8c:	85 c0                	test   %eax,%eax
  101e8e:	75 1c                	jne    101eac <mpsearch1+0x52>
  101e90:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  101e97:	00 
  101e98:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101e9b:	89 04 24             	mov    %eax,(%esp)
  101e9e:	e8 81 ff ff ff       	call   101e24 <sum>
  101ea3:	84 c0                	test   %al,%al
  101ea5:	75 05                	jne    101eac <mpsearch1+0x52>
			return (struct mp *) p;
  101ea7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101eaa:	eb 11                	jmp    101ebd <mpsearch1+0x63>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  101eac:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  101eb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101eb3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  101eb6:	72 b9                	jb     101e71 <mpsearch1+0x17>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  101eb8:	b8 00 00 00 00       	mov    $0x0,%eax
}
  101ebd:	c9                   	leave  
  101ebe:	c3                   	ret    

00101ebf <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  101ebf:	55                   	push   %ebp
  101ec0:	89 e5                	mov    %esp,%ebp
  101ec2:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  101ec5:	c7 45 ec 00 04 00 00 	movl   $0x400,-0x14(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  101ecc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101ecf:	83 c0 0f             	add    $0xf,%eax
  101ed2:	0f b6 00             	movzbl (%eax),%eax
  101ed5:	0f b6 c0             	movzbl %al,%eax
  101ed8:	89 c2                	mov    %eax,%edx
  101eda:	c1 e2 08             	shl    $0x8,%edx
  101edd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101ee0:	83 c0 0e             	add    $0xe,%eax
  101ee3:	0f b6 00             	movzbl (%eax),%eax
  101ee6:	0f b6 c0             	movzbl %al,%eax
  101ee9:	09 d0                	or     %edx,%eax
  101eeb:	c1 e0 04             	shl    $0x4,%eax
  101eee:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101ef1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101ef5:	74 21                	je     101f18 <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  101ef7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101efa:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  101f01:	00 
  101f02:	89 04 24             	mov    %eax,(%esp)
  101f05:	e8 50 ff ff ff       	call   101e5a <mpsearch1>
  101f0a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101f0d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101f11:	74 50                	je     101f63 <mpsearch+0xa4>
			return mp;
  101f13:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f16:	eb 5f                	jmp    101f77 <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  101f18:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101f1b:	83 c0 14             	add    $0x14,%eax
  101f1e:	0f b6 00             	movzbl (%eax),%eax
  101f21:	0f b6 c0             	movzbl %al,%eax
  101f24:	89 c2                	mov    %eax,%edx
  101f26:	c1 e2 08             	shl    $0x8,%edx
  101f29:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101f2c:	83 c0 13             	add    $0x13,%eax
  101f2f:	0f b6 00             	movzbl (%eax),%eax
  101f32:	0f b6 c0             	movzbl %al,%eax
  101f35:	09 d0                	or     %edx,%eax
  101f37:	c1 e0 0a             	shl    $0xa,%eax
  101f3a:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  101f3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f40:	2d 00 04 00 00       	sub    $0x400,%eax
  101f45:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  101f4c:	00 
  101f4d:	89 04 24             	mov    %eax,(%esp)
  101f50:	e8 05 ff ff ff       	call   101e5a <mpsearch1>
  101f55:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101f58:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101f5c:	74 05                	je     101f63 <mpsearch+0xa4>
			return mp;
  101f5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f61:	eb 14                	jmp    101f77 <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  101f63:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  101f6a:	00 
  101f6b:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  101f72:	e8 e3 fe ff ff       	call   101e5a <mpsearch1>
}
  101f77:	c9                   	leave  
  101f78:	c3                   	ret    

00101f79 <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  101f79:	55                   	push   %ebp
  101f7a:	89 e5                	mov    %esp,%ebp
  101f7c:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  101f7f:	e8 3b ff ff ff       	call   101ebf <mpsearch>
  101f84:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101f87:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101f8b:	74 0a                	je     101f97 <mpconfig+0x1e>
  101f8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f90:	8b 40 04             	mov    0x4(%eax),%eax
  101f93:	85 c0                	test   %eax,%eax
  101f95:	75 07                	jne    101f9e <mpconfig+0x25>
		return 0;
  101f97:	b8 00 00 00 00       	mov    $0x0,%eax
  101f9c:	eb 7b                	jmp    102019 <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  101f9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101fa1:	8b 40 04             	mov    0x4(%eax),%eax
  101fa4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  101fa7:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  101fae:	00 
  101faf:	c7 44 24 04 0d 5b 10 	movl   $0x105b0d,0x4(%esp)
  101fb6:	00 
  101fb7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fba:	89 04 24             	mov    %eax,(%esp)
  101fbd:	e8 b8 2e 00 00       	call   104e7a <memcmp>
  101fc2:	85 c0                	test   %eax,%eax
  101fc4:	74 07                	je     101fcd <mpconfig+0x54>
		return 0;
  101fc6:	b8 00 00 00 00       	mov    $0x0,%eax
  101fcb:	eb 4c                	jmp    102019 <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  101fcd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fd0:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  101fd4:	3c 01                	cmp    $0x1,%al
  101fd6:	74 12                	je     101fea <mpconfig+0x71>
  101fd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fdb:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  101fdf:	3c 04                	cmp    $0x4,%al
  101fe1:	74 07                	je     101fea <mpconfig+0x71>
		return 0;
  101fe3:	b8 00 00 00 00       	mov    $0x0,%eax
  101fe8:	eb 2f                	jmp    102019 <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  101fea:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fed:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  101ff1:	0f b7 d0             	movzwl %ax,%edx
  101ff4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101ff7:	89 54 24 04          	mov    %edx,0x4(%esp)
  101ffb:	89 04 24             	mov    %eax,(%esp)
  101ffe:	e8 21 fe ff ff       	call   101e24 <sum>
  102003:	84 c0                	test   %al,%al
  102005:	74 07                	je     10200e <mpconfig+0x95>
		return 0;
  102007:	b8 00 00 00 00       	mov    $0x0,%eax
  10200c:	eb 0b                	jmp    102019 <mpconfig+0xa0>
       *pmp = mp;
  10200e:	8b 45 08             	mov    0x8(%ebp),%eax
  102011:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102014:	89 10                	mov    %edx,(%eax)
	return conf;
  102016:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102019:	c9                   	leave  
  10201a:	c3                   	ret    

0010201b <mp_init>:

void
mp_init(void)
{
  10201b:	55                   	push   %ebp
  10201c:	89 e5                	mov    %esp,%ebp
  10201e:	83 ec 48             	sub    $0x48,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  102021:	e8 e6 fd ff ff       	call   101e0c <cpu_onboot>
  102026:	85 c0                	test   %eax,%eax
  102028:	0f 84 72 01 00 00    	je     1021a0 <mp_init+0x185>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  10202e:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102031:	89 04 24             	mov    %eax,(%esp)
  102034:	e8 40 ff ff ff       	call   101f79 <mpconfig>
  102039:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  10203c:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  102040:	0f 84 5d 01 00 00    	je     1021a3 <mp_init+0x188>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  102046:	c7 05 e4 f3 30 00 01 	movl   $0x1,0x30f3e4
  10204d:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  102050:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102053:	8b 40 24             	mov    0x24(%eax),%eax
  102056:	a3 ec fa 30 00       	mov    %eax,0x30faec
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  10205b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10205e:	83 c0 2c             	add    $0x2c,%eax
  102061:	89 45 cc             	mov    %eax,-0x34(%ebp)
  102064:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102067:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10206a:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  10206e:	0f b7 c0             	movzwl %ax,%eax
  102071:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102074:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102077:	e9 cc 00 00 00       	jmp    102148 <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  10207c:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10207f:	0f b6 00             	movzbl (%eax),%eax
  102082:	0f b6 c0             	movzbl %al,%eax
  102085:	83 f8 04             	cmp    $0x4,%eax
  102088:	0f 87 90 00 00 00    	ja     10211e <mp_init+0x103>
  10208e:	8b 04 85 40 5b 10 00 	mov    0x105b40(,%eax,4),%eax
  102095:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  102097:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10209a:	89 45 d8             	mov    %eax,-0x28(%ebp)
			p += sizeof(struct mpproc);
  10209d:	83 45 cc 14          	addl   $0x14,-0x34(%ebp)
			if (!(proc->flags & MPENAB))
  1020a1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1020a4:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  1020a8:	0f b6 c0             	movzbl %al,%eax
  1020ab:	83 e0 01             	and    $0x1,%eax
  1020ae:	85 c0                	test   %eax,%eax
  1020b0:	0f 84 91 00 00 00    	je     102147 <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  1020b6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1020b9:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  1020bd:	0f b6 c0             	movzbl %al,%eax
  1020c0:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  1020c3:	85 c0                	test   %eax,%eax
  1020c5:	75 07                	jne    1020ce <mp_init+0xb3>
  1020c7:	e8 47 f1 ff ff       	call   101213 <cpu_alloc>
  1020cc:	eb 05                	jmp    1020d3 <mp_init+0xb8>
  1020ce:	b8 00 80 10 00       	mov    $0x108000,%eax
  1020d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
			c->id = proc->apicid;
  1020d6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1020d9:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  1020dd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1020e0:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  1020e6:	a1 e8 f3 30 00       	mov    0x30f3e8,%eax
  1020eb:	83 c0 01             	add    $0x1,%eax
  1020ee:	a3 e8 f3 30 00       	mov    %eax,0x30f3e8
			continue;
  1020f3:	eb 53                	jmp    102148 <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  1020f5:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1020f8:	89 45 dc             	mov    %eax,-0x24(%ebp)
			p += sizeof(struct mpioapic);
  1020fb:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			ioapicid = mpio->apicno;
  1020ff:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102102:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  102106:	a2 dc f3 30 00       	mov    %al,0x30f3dc
			ioapic = (struct ioapic *) mpio->addr;
  10210b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10210e:	8b 40 04             	mov    0x4(%eax),%eax
  102111:	a3 e0 f3 30 00       	mov    %eax,0x30f3e0
			continue;
  102116:	eb 30                	jmp    102148 <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  102118:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			continue;
  10211c:	eb 2a                	jmp    102148 <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  10211e:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102121:	0f b6 00             	movzbl (%eax),%eax
  102124:	0f b6 c0             	movzbl %al,%eax
  102127:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10212b:	c7 44 24 08 14 5b 10 	movl   $0x105b14,0x8(%esp)
  102132:	00 
  102133:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  10213a:	00 
  10213b:	c7 04 24 34 5b 10 00 	movl   $0x105b34,(%esp)
  102142:	e8 28 e3 ff ff       	call   10046f <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  102147:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  102148:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10214b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10214e:	0f 82 28 ff ff ff    	jb     10207c <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  102154:	8b 45 c8             	mov    -0x38(%ebp),%eax
  102157:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  10215b:	84 c0                	test   %al,%al
  10215d:	74 45                	je     1021a4 <mp_init+0x189>
  10215f:	c7 45 e8 22 00 00 00 	movl   $0x22,-0x18(%ebp)
  102166:	c6 45 e7 70          	movb   $0x70,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10216a:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  10216e:	8b 55 e8             	mov    -0x18(%ebp),%edx
  102171:	ee                   	out    %al,(%dx)
  102172:	c7 45 ec 23 00 00 00 	movl   $0x23,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102179:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10217c:	89 c2                	mov    %eax,%edx
  10217e:	ec                   	in     (%dx),%al
  10217f:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  102182:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  102186:	83 c8 01             	or     $0x1,%eax
  102189:	0f b6 c0             	movzbl %al,%eax
  10218c:	c7 45 f4 23 00 00 00 	movl   $0x23,-0xc(%ebp)
  102193:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102196:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10219a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10219d:	ee                   	out    %al,(%dx)
  10219e:	eb 04                	jmp    1021a4 <mp_init+0x189>
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  1021a0:	90                   	nop
  1021a1:	eb 01                	jmp    1021a4 <mp_init+0x189>

	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.
  1021a3:	90                   	nop
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
	}
}
  1021a4:	c9                   	leave  
  1021a5:	c3                   	ret    

001021a6 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  1021a6:	55                   	push   %ebp
  1021a7:	89 e5                	mov    %esp,%ebp
  1021a9:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1021ac:	8b 55 08             	mov    0x8(%ebp),%edx
  1021af:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021b2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1021b5:	f0 87 02             	lock xchg %eax,(%edx)
  1021b8:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  1021bb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1021be:	c9                   	leave  
  1021bf:	c3                   	ret    

001021c0 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1021c0:	55                   	push   %ebp
  1021c1:	89 e5                	mov    %esp,%ebp
  1021c3:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1021c6:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1021c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1021cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1021cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1021d2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1021d7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1021da:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1021dd:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1021e3:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1021e8:	74 24                	je     10220e <cpu_cur+0x4e>
  1021ea:	c7 44 24 0c 54 5b 10 	movl   $0x105b54,0xc(%esp)
  1021f1:	00 
  1021f2:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  1021f9:	00 
  1021fa:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102201:	00 
  102202:	c7 04 24 7f 5b 10 00 	movl   $0x105b7f,(%esp)
  102209:	e8 61 e2 ff ff       	call   10046f <debug_panic>
	return c;
  10220e:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  102211:	c9                   	leave  
  102212:	c3                   	ret    

00102213 <spinlock_init_>:
#include <kern/cons.h>


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  102213:	55                   	push   %ebp
  102214:	89 e5                	mov    %esp,%ebp
	lk->locked = 0;
  102216:	8b 45 08             	mov    0x8(%ebp),%eax
  102219:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->file = file;
  10221f:	8b 45 08             	mov    0x8(%ebp),%eax
  102222:	8b 55 0c             	mov    0xc(%ebp),%edx
  102225:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  102228:	8b 45 08             	mov    0x8(%ebp),%eax
  10222b:	8b 55 10             	mov    0x10(%ebp),%edx
  10222e:	89 50 08             	mov    %edx,0x8(%eax)
	lk->cpu = NULL;
  102231:	8b 45 08             	mov    0x8(%ebp),%eax
  102234:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	lk->eips[0] = 0;
  10223b:	8b 45 08             	mov    0x8(%ebp),%eax
  10223e:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
}
  102245:	5d                   	pop    %ebp
  102246:	c3                   	ret    

00102247 <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  102247:	55                   	push   %ebp
  102248:	89 e5                	mov    %esp,%ebp
  10224a:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in sa\n");

	if(spinlock_holding(lk))
  10224d:	8b 45 08             	mov    0x8(%ebp),%eax
  102250:	89 04 24             	mov    %eax,(%esp)
  102253:	e8 c5 00 00 00       	call   10231d <spinlock_holding>
  102258:	85 c0                	test   %eax,%eax
  10225a:	74 2a                	je     102286 <spinlock_acquire+0x3f>
		panic("acquire");
  10225c:	c7 44 24 08 8c 5b 10 	movl   $0x105b8c,0x8(%esp)
  102263:	00 
  102264:	c7 44 24 04 27 00 00 	movl   $0x27,0x4(%esp)
  10226b:	00 
  10226c:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  102273:	e8 f7 e1 ff ff       	call   10046f <debug_panic>

	while(xchg(&lk->locked, 1) !=0)
		{cprintf("in xchg\n")
  102278:	c7 04 24 a4 5b 10 00 	movl   $0x105ba4,(%esp)
  10227f:	e8 a1 28 00 00       	call   104b25 <cprintf>
  102284:	eb 01                	jmp    102287 <spinlock_acquire+0x40>
	//cprintf("in sa\n");

	if(spinlock_holding(lk))
		panic("acquire");

	while(xchg(&lk->locked, 1) !=0)
  102286:	90                   	nop
  102287:	8b 45 08             	mov    0x8(%ebp),%eax
  10228a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102291:	00 
  102292:	89 04 24             	mov    %eax,(%esp)
  102295:	e8 0c ff ff ff       	call   1021a6 <xchg>
  10229a:	85 c0                	test   %eax,%eax
  10229c:	75 da                	jne    102278 <spinlock_acquire+0x31>
		{cprintf("in xchg\n")
		;}

	lk->cpu = cpu_cur();
  10229e:	e8 1d ff ff ff       	call   1021c0 <cpu_cur>
  1022a3:	8b 55 08             	mov    0x8(%ebp),%edx
  1022a6:	89 42 0c             	mov    %eax,0xc(%edx)

	//cprintf("before dt\n");
	debug_trace(read_ebp(), lk->eips);
  1022a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1022ac:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1022af:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  1022b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1022b5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1022b9:	89 04 24             	mov    %eax,(%esp)
  1022bc:	e8 b6 e2 ff ff       	call   100577 <debug_trace>
	//cprintf("after dt\n");

	//cprintf("after sa\n");
}
  1022c1:	c9                   	leave  
  1022c2:	c3                   	ret    

001022c3 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  1022c3:	55                   	push   %ebp
  1022c4:	89 e5                	mov    %esp,%ebp
  1022c6:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk))
  1022c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1022cc:	89 04 24             	mov    %eax,(%esp)
  1022cf:	e8 49 00 00 00       	call   10231d <spinlock_holding>
  1022d4:	85 c0                	test   %eax,%eax
  1022d6:	75 1c                	jne    1022f4 <spinlock_release+0x31>
		panic("release");
  1022d8:	c7 44 24 08 ad 5b 10 	movl   $0x105bad,0x8(%esp)
  1022df:	00 
  1022e0:	c7 44 24 04 3b 00 00 	movl   $0x3b,0x4(%esp)
  1022e7:	00 
  1022e8:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  1022ef:	e8 7b e1 ff ff       	call   10046f <debug_panic>

	lk->cpu = NULL;
  1022f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1022f7:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	xchg(&lk->locked, 0);
  1022fe:	8b 45 08             	mov    0x8(%ebp),%eax
  102301:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102308:	00 
  102309:	89 04 24             	mov    %eax,(%esp)
  10230c:	e8 95 fe ff ff       	call   1021a6 <xchg>

	lk->eips[0] = 0;
  102311:	8b 45 08             	mov    0x8(%ebp),%eax
  102314:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
}
  10231b:	c9                   	leave  
  10231c:	c3                   	ret    

0010231d <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  10231d:	55                   	push   %ebp
  10231e:	89 e5                	mov    %esp,%ebp
  102320:	53                   	push   %ebx
  102321:	83 ec 04             	sub    $0x4,%esp
	return (lock->cpu == cpu_cur()) && (lock->locked);
  102324:	8b 45 08             	mov    0x8(%ebp),%eax
  102327:	8b 58 0c             	mov    0xc(%eax),%ebx
  10232a:	e8 91 fe ff ff       	call   1021c0 <cpu_cur>
  10232f:	39 c3                	cmp    %eax,%ebx
  102331:	75 10                	jne    102343 <spinlock_holding+0x26>
  102333:	8b 45 08             	mov    0x8(%ebp),%eax
  102336:	8b 00                	mov    (%eax),%eax
  102338:	85 c0                	test   %eax,%eax
  10233a:	74 07                	je     102343 <spinlock_holding+0x26>
  10233c:	b8 01 00 00 00       	mov    $0x1,%eax
  102341:	eb 05                	jmp    102348 <spinlock_holding+0x2b>
  102343:	b8 00 00 00 00       	mov    $0x0,%eax
	//panic("spinlock_holding() not implemented");
}
  102348:	83 c4 04             	add    $0x4,%esp
  10234b:	5b                   	pop    %ebx
  10234c:	5d                   	pop    %ebp
  10234d:	c3                   	ret    

0010234e <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  10234e:	55                   	push   %ebp
  10234f:	89 e5                	mov    %esp,%ebp
  102351:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  102354:	8b 45 08             	mov    0x8(%ebp),%eax
  102357:	85 c0                	test   %eax,%eax
  102359:	75 12                	jne    10236d <spinlock_godeep+0x1f>
  10235b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10235e:	89 04 24             	mov    %eax,(%esp)
  102361:	e8 e1 fe ff ff       	call   102247 <spinlock_acquire>
  102366:	b8 01 00 00 00       	mov    $0x1,%eax
  10236b:	eb 1b                	jmp    102388 <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  10236d:	8b 45 08             	mov    0x8(%ebp),%eax
  102370:	8d 50 ff             	lea    -0x1(%eax),%edx
  102373:	8b 45 0c             	mov    0xc(%ebp),%eax
  102376:	89 44 24 04          	mov    %eax,0x4(%esp)
  10237a:	89 14 24             	mov    %edx,(%esp)
  10237d:	e8 cc ff ff ff       	call   10234e <spinlock_godeep>
  102382:	8b 55 08             	mov    0x8(%ebp),%edx
  102385:	0f af c2             	imul   %edx,%eax
}
  102388:	c9                   	leave  
  102389:	c3                   	ret    

0010238a <spinlock_check>:



void spinlock_check()
{
  10238a:	55                   	push   %ebp
  10238b:	89 e5                	mov    %esp,%ebp
  10238d:	57                   	push   %edi
  10238e:	56                   	push   %esi
  10238f:	53                   	push   %ebx
  102390:	83 ec 5c             	sub    $0x5c,%esp
  102393:	89 e0                	mov    %esp,%eax
  102395:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	const int NUMLOCKS=10;
  102398:	c7 45 d0 0a 00 00 00 	movl   $0xa,-0x30(%ebp)
	const int NUMRUNS=5;
  10239f:	c7 45 d4 05 00 00 00 	movl   $0x5,-0x2c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  1023a6:	c7 45 e4 b5 5b 10 00 	movl   $0x105bb5,-0x1c(%ebp)
	spinlock locks[NUMLOCKS];
  1023ad:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1023b0:	83 e8 01             	sub    $0x1,%eax
  1023b3:	89 45 c8             	mov    %eax,-0x38(%ebp)
  1023b6:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1023b9:	ba 00 00 00 00       	mov    $0x0,%edx
  1023be:	89 c1                	mov    %eax,%ecx
  1023c0:	80 e5 ff             	and    $0xff,%ch
  1023c3:	89 d3                	mov    %edx,%ebx
  1023c5:	83 e3 0f             	and    $0xf,%ebx
  1023c8:	89 c8                	mov    %ecx,%eax
  1023ca:	89 da                	mov    %ebx,%edx
  1023cc:	69 da c0 01 00 00    	imul   $0x1c0,%edx,%ebx
  1023d2:	6b c8 00             	imul   $0x0,%eax,%ecx
  1023d5:	01 cb                	add    %ecx,%ebx
  1023d7:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  1023dc:	f7 e1                	mul    %ecx
  1023de:	01 d3                	add    %edx,%ebx
  1023e0:	89 da                	mov    %ebx,%edx
  1023e2:	89 c6                	mov    %eax,%esi
  1023e4:	83 e6 ff             	and    $0xffffffff,%esi
  1023e7:	89 d7                	mov    %edx,%edi
  1023e9:	83 e7 0f             	and    $0xf,%edi
  1023ec:	89 f0                	mov    %esi,%eax
  1023ee:	89 fa                	mov    %edi,%edx
  1023f0:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1023f3:	c1 e0 03             	shl    $0x3,%eax
  1023f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1023f9:	ba 00 00 00 00       	mov    $0x0,%edx
  1023fe:	89 c1                	mov    %eax,%ecx
  102400:	80 e5 ff             	and    $0xff,%ch
  102403:	89 4d b8             	mov    %ecx,-0x48(%ebp)
  102406:	89 d3                	mov    %edx,%ebx
  102408:	83 e3 0f             	and    $0xf,%ebx
  10240b:	89 5d bc             	mov    %ebx,-0x44(%ebp)
  10240e:	8b 45 b8             	mov    -0x48(%ebp),%eax
  102411:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102414:	69 ca c0 01 00 00    	imul   $0x1c0,%edx,%ecx
  10241a:	6b d8 00             	imul   $0x0,%eax,%ebx
  10241d:	01 d9                	add    %ebx,%ecx
  10241f:	bb c0 01 00 00       	mov    $0x1c0,%ebx
  102424:	f7 e3                	mul    %ebx
  102426:	01 d1                	add    %edx,%ecx
  102428:	89 ca                	mov    %ecx,%edx
  10242a:	89 c1                	mov    %eax,%ecx
  10242c:	80 e5 ff             	and    $0xff,%ch
  10242f:	89 4d b0             	mov    %ecx,-0x50(%ebp)
  102432:	89 d3                	mov    %edx,%ebx
  102434:	83 e3 0f             	and    $0xf,%ebx
  102437:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
  10243a:	8b 45 b0             	mov    -0x50(%ebp),%eax
  10243d:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102440:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102443:	c1 e0 03             	shl    $0x3,%eax
  102446:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10244d:	89 d1                	mov    %edx,%ecx
  10244f:	29 c1                	sub    %eax,%ecx
  102451:	89 c8                	mov    %ecx,%eax
  102453:	83 c0 0f             	add    $0xf,%eax
  102456:	83 c0 0f             	add    $0xf,%eax
  102459:	c1 e8 04             	shr    $0x4,%eax
  10245c:	c1 e0 04             	shl    $0x4,%eax
  10245f:	29 c4                	sub    %eax,%esp
  102461:	8d 44 24 10          	lea    0x10(%esp),%eax
  102465:	83 c0 0f             	add    $0xf,%eax
  102468:	c1 e8 04             	shr    $0x4,%eax
  10246b:	c1 e0 04             	shl    $0x4,%eax
  10246e:	89 45 cc             	mov    %eax,-0x34(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  102471:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102478:	eb 33                	jmp    1024ad <spinlock_check+0x123>
  10247a:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10247d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102480:	c1 e0 03             	shl    $0x3,%eax
  102483:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  10248a:	89 cb                	mov    %ecx,%ebx
  10248c:	29 c3                	sub    %eax,%ebx
  10248e:	89 d8                	mov    %ebx,%eax
  102490:	01 c2                	add    %eax,%edx
  102492:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102499:	00 
  10249a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10249d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024a1:	89 14 24             	mov    %edx,(%esp)
  1024a4:	e8 6a fd ff ff       	call   102213 <spinlock_init_>
  1024a9:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1024ad:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1024b0:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1024b3:	7c c5                	jl     10247a <spinlock_check+0xf0>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  1024b5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1024bc:	eb 46                	jmp    102504 <spinlock_check+0x17a>
  1024be:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1024c1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1024c4:	c1 e0 03             	shl    $0x3,%eax
  1024c7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1024ce:	29 c2                	sub    %eax,%edx
  1024d0:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1024d3:	83 c0 0c             	add    $0xc,%eax
  1024d6:	8b 00                	mov    (%eax),%eax
  1024d8:	85 c0                	test   %eax,%eax
  1024da:	74 24                	je     102500 <spinlock_check+0x176>
  1024dc:	c7 44 24 0c c4 5b 10 	movl   $0x105bc4,0xc(%esp)
  1024e3:	00 
  1024e4:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  1024eb:	00 
  1024ec:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  1024f3:	00 
  1024f4:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  1024fb:	e8 6f df ff ff       	call   10046f <debug_panic>
  102500:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102504:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102507:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10250a:	7c b2                	jl     1024be <spinlock_check+0x134>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  10250c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102513:	eb 47                	jmp    10255c <spinlock_check+0x1d2>
  102515:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102518:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10251b:	c1 e0 03             	shl    $0x3,%eax
  10251e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102525:	29 c2                	sub    %eax,%edx
  102527:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  10252a:	83 c0 04             	add    $0x4,%eax
  10252d:	8b 00                	mov    (%eax),%eax
  10252f:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  102532:	74 24                	je     102558 <spinlock_check+0x1ce>
  102534:	c7 44 24 0c d7 5b 10 	movl   $0x105bd7,0xc(%esp)
  10253b:	00 
  10253c:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  102543:	00 
  102544:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  10254b:	00 
  10254c:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  102553:	e8 17 df ff ff       	call   10046f <debug_panic>
  102558:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10255c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10255f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102562:	7c b1                	jl     102515 <spinlock_check+0x18b>

	for (run=0;run<NUMRUNS;run++) 
  102564:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  10256b:	e9 25 03 00 00       	jmp    102895 <spinlock_check+0x50b>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  102570:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102577:	eb 3f                	jmp    1025b8 <spinlock_check+0x22e>
		{
			cprintf("%d\n", i);
  102579:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10257c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102580:	c7 04 24 eb 5b 10 00 	movl   $0x105beb,(%esp)
  102587:	e8 99 25 00 00       	call   104b25 <cprintf>
			spinlock_godeep(i, &locks[i]);
  10258c:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10258f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102592:	c1 e0 03             	shl    $0x3,%eax
  102595:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  10259c:	89 cb                	mov    %ecx,%ebx
  10259e:	29 c3                	sub    %eax,%ebx
  1025a0:	89 d8                	mov    %ebx,%eax
  1025a2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1025a5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025a9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025ac:	89 04 24             	mov    %eax,(%esp)
  1025af:	e8 9a fd ff ff       	call   10234e <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  1025b4:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1025b8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025bb:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1025be:	7c b9                	jl     102579 <spinlock_check+0x1ef>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  1025c0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1025c7:	eb 4b                	jmp    102614 <spinlock_check+0x28a>
			assert(locks[i].cpu == cpu_cur());
  1025c9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025cc:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1025cf:	c1 e0 03             	shl    $0x3,%eax
  1025d2:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1025d9:	29 c2                	sub    %eax,%edx
  1025db:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1025de:	83 c0 0c             	add    $0xc,%eax
  1025e1:	8b 18                	mov    (%eax),%ebx
  1025e3:	e8 d8 fb ff ff       	call   1021c0 <cpu_cur>
  1025e8:	39 c3                	cmp    %eax,%ebx
  1025ea:	74 24                	je     102610 <spinlock_check+0x286>
  1025ec:	c7 44 24 0c ef 5b 10 	movl   $0x105bef,0xc(%esp)
  1025f3:	00 
  1025f4:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  1025fb:	00 
  1025fc:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  102603:	00 
  102604:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  10260b:	e8 5f de ff ff       	call   10046f <debug_panic>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  102610:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102614:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102617:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10261a:	7c ad                	jl     1025c9 <spinlock_check+0x23f>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  10261c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102623:	eb 4d                	jmp    102672 <spinlock_check+0x2e8>
			assert(spinlock_holding(&locks[i]) != 0);
  102625:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102628:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10262b:	c1 e0 03             	shl    $0x3,%eax
  10262e:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102635:	89 cb                	mov    %ecx,%ebx
  102637:	29 c3                	sub    %eax,%ebx
  102639:	89 d8                	mov    %ebx,%eax
  10263b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10263e:	89 04 24             	mov    %eax,(%esp)
  102641:	e8 d7 fc ff ff       	call   10231d <spinlock_holding>
  102646:	85 c0                	test   %eax,%eax
  102648:	75 24                	jne    10266e <spinlock_check+0x2e4>
  10264a:	c7 44 24 0c 0c 5c 10 	movl   $0x105c0c,0xc(%esp)
  102651:	00 
  102652:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  102659:	00 
  10265a:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  102661:	00 
  102662:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  102669:	e8 01 de ff ff       	call   10046f <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  10266e:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102672:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102675:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102678:	7c ab                	jl     102625 <spinlock_check+0x29b>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  10267a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102681:	e9 bd 00 00 00       	jmp    102743 <spinlock_check+0x3b9>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102686:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  10268d:	e9 9b 00 00 00       	jmp    10272d <spinlock_check+0x3a3>
			{
				assert(locks[i].eips[j] >=
  102692:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102695:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  102698:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10269b:	01 c0                	add    %eax,%eax
  10269d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1026a4:	29 c2                	sub    %eax,%edx
  1026a6:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  1026a9:	83 c0 04             	add    $0x4,%eax
  1026ac:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  1026af:	b8 4e 23 10 00       	mov    $0x10234e,%eax
  1026b4:	39 c2                	cmp    %eax,%edx
  1026b6:	73 24                	jae    1026dc <spinlock_check+0x352>
  1026b8:	c7 44 24 0c 30 5c 10 	movl   $0x105c30,0xc(%esp)
  1026bf:	00 
  1026c0:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  1026c7:	00 
  1026c8:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  1026cf:	00 
  1026d0:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  1026d7:	e8 93 dd ff ff       	call   10046f <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  1026dc:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1026df:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  1026e2:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1026e5:	01 c0                	add    %eax,%eax
  1026e7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1026ee:	29 c2                	sub    %eax,%edx
  1026f0:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  1026f3:	83 c0 04             	add    $0x4,%eax
  1026f6:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  1026f9:	ba 4e 23 10 00       	mov    $0x10234e,%edx
  1026fe:	83 c2 64             	add    $0x64,%edx
  102701:	39 d0                	cmp    %edx,%eax
  102703:	72 24                	jb     102729 <spinlock_check+0x39f>
  102705:	c7 44 24 0c 60 5c 10 	movl   $0x105c60,0xc(%esp)
  10270c:	00 
  10270d:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  102714:	00 
  102715:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  10271c:	00 
  10271d:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  102724:	e8 46 dd ff ff       	call   10046f <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102729:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  10272d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102730:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  102733:	7f 0a                	jg     10273f <spinlock_check+0x3b5>
  102735:	83 7d dc 09          	cmpl   $0x9,-0x24(%ebp)
  102739:	0f 8e 53 ff ff ff    	jle    102692 <spinlock_check+0x308>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  10273f:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102743:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102746:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102749:	0f 8c 37 ff ff ff    	jl     102686 <spinlock_check+0x2fc>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  10274f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102756:	eb 25                	jmp    10277d <spinlock_check+0x3f3>
  102758:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10275b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10275e:	c1 e0 03             	shl    $0x3,%eax
  102761:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102768:	89 cb                	mov    %ecx,%ebx
  10276a:	29 c3                	sub    %eax,%ebx
  10276c:	89 d8                	mov    %ebx,%eax
  10276e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102771:	89 04 24             	mov    %eax,(%esp)
  102774:	e8 4a fb ff ff       	call   1022c3 <spinlock_release>
  102779:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10277d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102780:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102783:	7c d3                	jl     102758 <spinlock_check+0x3ce>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  102785:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10278c:	eb 46                	jmp    1027d4 <spinlock_check+0x44a>
  10278e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102791:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102794:	c1 e0 03             	shl    $0x3,%eax
  102797:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10279e:	29 c2                	sub    %eax,%edx
  1027a0:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1027a3:	83 c0 0c             	add    $0xc,%eax
  1027a6:	8b 00                	mov    (%eax),%eax
  1027a8:	85 c0                	test   %eax,%eax
  1027aa:	74 24                	je     1027d0 <spinlock_check+0x446>
  1027ac:	c7 44 24 0c 91 5c 10 	movl   $0x105c91,0xc(%esp)
  1027b3:	00 
  1027b4:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  1027bb:	00 
  1027bc:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  1027c3:	00 
  1027c4:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  1027cb:	e8 9f dc ff ff       	call   10046f <debug_panic>
  1027d0:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1027d4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1027d7:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1027da:	7c b2                	jl     10278e <spinlock_check+0x404>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  1027dc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1027e3:	eb 46                	jmp    10282b <spinlock_check+0x4a1>
  1027e5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1027e8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1027eb:	c1 e0 03             	shl    $0x3,%eax
  1027ee:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1027f5:	29 c2                	sub    %eax,%edx
  1027f7:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1027fa:	83 c0 10             	add    $0x10,%eax
  1027fd:	8b 00                	mov    (%eax),%eax
  1027ff:	85 c0                	test   %eax,%eax
  102801:	74 24                	je     102827 <spinlock_check+0x49d>
  102803:	c7 44 24 0c a6 5c 10 	movl   $0x105ca6,0xc(%esp)
  10280a:	00 
  10280b:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  102812:	00 
  102813:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
  10281a:	00 
  10281b:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  102822:	e8 48 dc ff ff       	call   10046f <debug_panic>
  102827:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10282b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10282e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102831:	7c b2                	jl     1027e5 <spinlock_check+0x45b>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  102833:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10283a:	eb 4d                	jmp    102889 <spinlock_check+0x4ff>
  10283c:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10283f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102842:	c1 e0 03             	shl    $0x3,%eax
  102845:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  10284c:	89 cb                	mov    %ecx,%ebx
  10284e:	29 c3                	sub    %eax,%ebx
  102850:	89 d8                	mov    %ebx,%eax
  102852:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102855:	89 04 24             	mov    %eax,(%esp)
  102858:	e8 c0 fa ff ff       	call   10231d <spinlock_holding>
  10285d:	85 c0                	test   %eax,%eax
  10285f:	74 24                	je     102885 <spinlock_check+0x4fb>
  102861:	c7 44 24 0c bc 5c 10 	movl   $0x105cbc,0xc(%esp)
  102868:	00 
  102869:	c7 44 24 08 6a 5b 10 	movl   $0x105b6a,0x8(%esp)
  102870:	00 
  102871:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  102878:	00 
  102879:	c7 04 24 94 5b 10 00 	movl   $0x105b94,(%esp)
  102880:	e8 ea db ff ff       	call   10046f <debug_panic>
  102885:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102889:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10288c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10288f:	7c ab                	jl     10283c <spinlock_check+0x4b2>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  102891:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  102895:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102898:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  10289b:	0f 8c cf fc ff ff    	jl     102570 <spinlock_check+0x1e6>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  1028a1:	c7 04 24 dd 5c 10 00 	movl   $0x105cdd,(%esp)
  1028a8:	e8 78 22 00 00       	call   104b25 <cprintf>
  1028ad:	8b 65 c4             	mov    -0x3c(%ebp),%esp
}
  1028b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
  1028b3:	83 c4 00             	add    $0x0,%esp
  1028b6:	5b                   	pop    %ebx
  1028b7:	5e                   	pop    %esi
  1028b8:	5f                   	pop    %edi
  1028b9:	5d                   	pop    %ebp
  1028ba:	c3                   	ret    

001028bb <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  1028bb:	55                   	push   %ebp
  1028bc:	89 e5                	mov    %esp,%ebp
  1028be:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1028c1:	8b 55 08             	mov    0x8(%ebp),%edx
  1028c4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028c7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1028ca:	f0 87 02             	lock xchg %eax,(%edx)
  1028cd:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  1028d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1028d3:	c9                   	leave  
  1028d4:	c3                   	ret    

001028d5 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  1028d5:	55                   	push   %ebp
  1028d6:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  1028d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1028db:	8b 55 0c             	mov    0xc(%ebp),%edx
  1028de:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1028e1:	f0 01 10             	lock add %edx,(%eax)
}
  1028e4:	5d                   	pop    %ebp
  1028e5:	c3                   	ret    

001028e6 <pause>:
	return result;
}

static inline void
pause(void)
{
  1028e6:	55                   	push   %ebp
  1028e7:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  1028e9:	f3 90                	pause  
}
  1028eb:	5d                   	pop    %ebp
  1028ec:	c3                   	ret    

001028ed <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1028ed:	55                   	push   %ebp
  1028ee:	89 e5                	mov    %esp,%ebp
  1028f0:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1028f3:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1028f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1028f9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1028fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028ff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102904:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  102907:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10290a:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102910:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102915:	74 24                	je     10293b <cpu_cur+0x4e>
  102917:	c7 44 24 0c fc 5c 10 	movl   $0x105cfc,0xc(%esp)
  10291e:	00 
  10291f:	c7 44 24 08 12 5d 10 	movl   $0x105d12,0x8(%esp)
  102926:	00 
  102927:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10292e:	00 
  10292f:	c7 04 24 27 5d 10 00 	movl   $0x105d27,(%esp)
  102936:	e8 34 db ff ff       	call   10046f <debug_panic>
	return c;
  10293b:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10293e:	c9                   	leave  
  10293f:	c3                   	ret    

00102940 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102940:	55                   	push   %ebp
  102941:	89 e5                	mov    %esp,%ebp
  102943:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102946:	e8 a2 ff ff ff       	call   1028ed <cpu_cur>
  10294b:	3d 00 80 10 00       	cmp    $0x108000,%eax
  102950:	0f 94 c0             	sete   %al
  102953:	0f b6 c0             	movzbl %al,%eax
}
  102956:	c9                   	leave  
  102957:	c3                   	ret    

00102958 <proc_init>:

ready_queue queue;

void
proc_init(void)
{
  102958:	55                   	push   %ebp
  102959:	89 e5                	mov    %esp,%ebp
  10295b:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  10295e:	e8 dd ff ff ff       	call   102940 <cpu_onboot>
  102963:	85 c0                	test   %eax,%eax
  102965:	74 3c                	je     1029a3 <proc_init+0x4b>
		return;

	spinlock_init(&queue.lock);
  102967:	c7 44 24 08 23 00 00 	movl   $0x23,0x8(%esp)
  10296e:	00 
  10296f:	c7 44 24 04 34 5d 10 	movl   $0x105d34,0x4(%esp)
  102976:	00 
  102977:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  10297e:	e8 90 f8 ff ff       	call   102213 <spinlock_init_>

	//spinlock_acquire(&queue->lock);
	queue.count= 0;
  102983:	c7 05 d8 fa 30 00 00 	movl   $0x0,0x30fad8
  10298a:	00 00 00 
	queue.head = NULL;
  10298d:	c7 05 dc fa 30 00 00 	movl   $0x0,0x30fadc
  102994:	00 00 00 
	queue.tail= NULL;
  102997:	c7 05 e0 fa 30 00 00 	movl   $0x0,0x30fae0
  10299e:	00 00 00 
  1029a1:	eb 01                	jmp    1029a4 <proc_init+0x4c>

void
proc_init(void)
{
	if (!cpu_onboot())
		return;
  1029a3:	90                   	nop
	queue.head = NULL;
	queue.tail= NULL;
	//spinlock_release(&queue->lock);

	// your module initialization code here
}
  1029a4:	c9                   	leave  
  1029a5:	c3                   	ret    

001029a6 <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  1029a6:	55                   	push   %ebp
  1029a7:	89 e5                	mov    %esp,%ebp
  1029a9:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  1029ac:	e8 4a e1 ff ff       	call   100afb <mem_alloc>
  1029b1:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!pi)
  1029b4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1029b8:	75 0a                	jne    1029c4 <proc_alloc+0x1e>
		return NULL;
  1029ba:	b8 00 00 00 00       	mov    $0x0,%eax
  1029bf:	e9 60 01 00 00       	jmp    102b24 <proc_alloc+0x17e>
  1029c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1029c7:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1029ca:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  1029cf:	83 c0 08             	add    $0x8,%eax
  1029d2:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1029d5:	76 15                	jbe    1029ec <proc_alloc+0x46>
  1029d7:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  1029dc:	8b 15 84 f3 10 00    	mov    0x10f384,%edx
  1029e2:	c1 e2 03             	shl    $0x3,%edx
  1029e5:	01 d0                	add    %edx,%eax
  1029e7:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1029ea:	72 24                	jb     102a10 <proc_alloc+0x6a>
  1029ec:	c7 44 24 0c 40 5d 10 	movl   $0x105d40,0xc(%esp)
  1029f3:	00 
  1029f4:	c7 44 24 08 12 5d 10 	movl   $0x105d12,0x8(%esp)
  1029fb:	00 
  1029fc:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
  102a03:	00 
  102a04:	c7 04 24 77 5d 10 00 	movl   $0x105d77,(%esp)
  102a0b:	e8 5f da ff ff       	call   10046f <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  102a10:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  102a15:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  102a1a:	c1 ea 0c             	shr    $0xc,%edx
  102a1d:	c1 e2 03             	shl    $0x3,%edx
  102a20:	01 d0                	add    %edx,%eax
  102a22:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102a25:	72 3b                	jb     102a62 <proc_alloc+0xbc>
  102a27:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  102a2c:	ba ef fa 30 00       	mov    $0x30faef,%edx
  102a31:	c1 ea 0c             	shr    $0xc,%edx
  102a34:	c1 e2 03             	shl    $0x3,%edx
  102a37:	01 d0                	add    %edx,%eax
  102a39:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102a3c:	77 24                	ja     102a62 <proc_alloc+0xbc>
  102a3e:	c7 44 24 0c 84 5d 10 	movl   $0x105d84,0xc(%esp)
  102a45:	00 
  102a46:	c7 44 24 08 12 5d 10 	movl   $0x105d12,0x8(%esp)
  102a4d:	00 
  102a4e:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102a55:	00 
  102a56:	c7 04 24 77 5d 10 00 	movl   $0x105d77,(%esp)
  102a5d:	e8 0d da ff ff       	call   10046f <debug_panic>

	lockadd(&pi->refcount, 1);
  102a62:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102a65:	83 c0 04             	add    $0x4,%eax
  102a68:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102a6f:	00 
  102a70:	89 04 24             	mov    %eax,(%esp)
  102a73:	e8 5d fe ff ff       	call   1028d5 <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  102a78:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102a7b:	a1 d8 f3 30 00       	mov    0x30f3d8,%eax
  102a80:	89 d1                	mov    %edx,%ecx
  102a82:	29 c1                	sub    %eax,%ecx
  102a84:	89 c8                	mov    %ecx,%eax
  102a86:	c1 f8 03             	sar    $0x3,%eax
  102a89:	c1 e0 0c             	shl    $0xc,%eax
  102a8c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  102a8f:	c7 44 24 08 a0 06 00 	movl   $0x6a0,0x8(%esp)
  102a96:	00 
  102a97:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102a9e:	00 
  102a9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102aa2:	89 04 24             	mov    %eax,(%esp)
  102aa5:	e8 60 22 00 00       	call   104d0a <memset>
	spinlock_init(&cp->lock);
  102aaa:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102aad:	c7 44 24 08 3a 00 00 	movl   $0x3a,0x8(%esp)
  102ab4:	00 
  102ab5:	c7 44 24 04 34 5d 10 	movl   $0x105d34,0x4(%esp)
  102abc:	00 
  102abd:	89 04 24             	mov    %eax,(%esp)
  102ac0:	e8 4e f7 ff ff       	call   102213 <spinlock_init_>
	cp->parent = p;
  102ac5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ac8:	8b 55 08             	mov    0x8(%ebp),%edx
  102acb:	89 50 38             	mov    %edx,0x38(%eax)
	cp->state = PROC_STOP;
  102ace:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ad1:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  102ad8:	00 00 00 

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  102adb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ade:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  102ae5:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  102ae7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102aea:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  102af1:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  102af3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102af6:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  102afd:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  102aff:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102b02:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  102b09:	23 00 


	if (p)
  102b0b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102b0f:	74 10                	je     102b21 <proc_alloc+0x17b>
		p->child[cn] = cp;
  102b11:	8b 55 0c             	mov    0xc(%ebp),%edx
  102b14:	8b 45 08             	mov    0x8(%ebp),%eax
  102b17:	8d 4a 0c             	lea    0xc(%edx),%ecx
  102b1a:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102b1d:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
	return cp;
  102b21:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102b24:	c9                   	leave  
  102b25:	c3                   	ret    

00102b26 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  102b26:	55                   	push   %ebp
  102b27:	89 e5                	mov    %esp,%ebp
  102b29:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_ready not implemented");
	if(p == NULL)
  102b2c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102b30:	75 1c                	jne    102b4e <proc_ready+0x28>
		panic("proc_ready's p is null!");
  102b32:	c7 44 24 08 b5 5d 10 	movl   $0x105db5,0x8(%esp)
  102b39:	00 
  102b3a:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  102b41:	00 
  102b42:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  102b49:	e8 21 d9 ff ff       	call   10046f <debug_panic>

	spinlock_acquire(&p->lock);
  102b4e:	8b 45 08             	mov    0x8(%ebp),%eax
  102b51:	89 04 24             	mov    %eax,(%esp)
  102b54:	e8 ee f6 ff ff       	call   102247 <spinlock_acquire>
	p->state = PROC_READY;
  102b59:	8b 45 08             	mov    0x8(%ebp),%eax
  102b5c:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  102b63:	00 00 00 

	spinlock_acquire(&queue.lock);
  102b66:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102b6d:	e8 d5 f6 ff ff       	call   102247 <spinlock_acquire>
	// if there is no proc in queue now
	if(queue.count == 0){
  102b72:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102b77:	85 c0                	test   %eax,%eax
  102b79:	75 33                	jne    102bae <proc_ready+0x88>
		queue.count = 1;
  102b7b:	c7 05 d8 fa 30 00 01 	movl   $0x1,0x30fad8
  102b82:	00 00 00 
		queue.head = p;
  102b85:	8b 45 08             	mov    0x8(%ebp),%eax
  102b88:	a3 dc fa 30 00       	mov    %eax,0x30fadc
		queue.tail = p;
  102b8d:	8b 45 08             	mov    0x8(%ebp),%eax
  102b90:	a3 e0 fa 30 00       	mov    %eax,0x30fae0
		spinlock_release(&queue.lock);
  102b95:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102b9c:	e8 22 f7 ff ff       	call   1022c3 <spinlock_release>
		spinlock_release(&p->lock);	
  102ba1:	8b 45 08             	mov    0x8(%ebp),%eax
  102ba4:	89 04 24             	mov    %eax,(%esp)
  102ba7:	e8 17 f7 ff ff       	call   1022c3 <spinlock_release>
		return;
  102bac:	eb 3c                	jmp    102bea <proc_ready+0xc4>
	}

	// insert it to the head of the queue
	p->readynext = queue.head;
  102bae:	8b 15 dc fa 30 00    	mov    0x30fadc,%edx
  102bb4:	8b 45 08             	mov    0x8(%ebp),%eax
  102bb7:	89 90 40 04 00 00    	mov    %edx,0x440(%eax)
	queue.head = p;
  102bbd:	8b 45 08             	mov    0x8(%ebp),%eax
  102bc0:	a3 dc fa 30 00       	mov    %eax,0x30fadc
	queue.count++;
  102bc5:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102bca:	83 c0 01             	add    $0x1,%eax
  102bcd:	a3 d8 fa 30 00       	mov    %eax,0x30fad8

	spinlock_release(&queue.lock);
  102bd2:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102bd9:	e8 e5 f6 ff ff       	call   1022c3 <spinlock_release>
	spinlock_release(&p->lock);
  102bde:	8b 45 08             	mov    0x8(%ebp),%eax
  102be1:	89 04 24             	mov    %eax,(%esp)
  102be4:	e8 da f6 ff ff       	call   1022c3 <spinlock_release>
	return;
  102be9:	90                   	nop
	
}
  102bea:	c9                   	leave  
  102beb:	c3                   	ret    

00102bec <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  102bec:	55                   	push   %ebp
  102bed:	89 e5                	mov    %esp,%ebp
  102bef:	83 ec 18             	sub    $0x18,%esp
	spinlock_acquire(&p->lock);
  102bf2:	8b 45 08             	mov    0x8(%ebp),%eax
  102bf5:	89 04 24             	mov    %eax,(%esp)
  102bf8:	e8 4a f6 ff ff       	call   102247 <spinlock_acquire>
	memcpy(&p->sv.tf, &tf, sizeof(struct trapframe));
  102bfd:	8b 45 08             	mov    0x8(%ebp),%eax
  102c00:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102c06:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102c0d:	00 
  102c0e:	8d 45 0c             	lea    0xc(%ebp),%eax
  102c11:	89 44 24 04          	mov    %eax,0x4(%esp)
  102c15:	89 14 24             	mov    %edx,(%esp)
  102c18:	e8 3c 22 00 00       	call   104e59 <memcpy>
	spinlock_release(&p->lock);
  102c1d:	8b 45 08             	mov    0x8(%ebp),%eax
  102c20:	89 04 24             	mov    %eax,(%esp)
  102c23:	e8 9b f6 ff ff       	call   1022c3 <spinlock_release>
}
  102c28:	c9                   	leave  
  102c29:	c3                   	ret    

00102c2a <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  102c2a:	55                   	push   %ebp
  102c2b:	89 e5                	mov    %esp,%ebp
  102c2d:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");

	if(p == NULL || p->state != PROC_RUN)
  102c30:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102c34:	74 0e                	je     102c44 <proc_wait+0x1a>
  102c36:	8b 45 08             	mov    0x8(%ebp),%eax
  102c39:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  102c3f:	83 f8 02             	cmp    $0x2,%eax
  102c42:	74 1c                	je     102c60 <proc_wait+0x36>
		panic("parent proc is not running!");
  102c44:	c7 44 24 08 cd 5d 10 	movl   $0x105dcd,0x8(%esp)
  102c4b:	00 
  102c4c:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  102c53:	00 
  102c54:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  102c5b:	e8 0f d8 ff ff       	call   10046f <debug_panic>
	if(cp == NULL)
  102c60:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102c64:	75 1c                	jne    102c82 <proc_wait+0x58>
		panic("no child proc!");
  102c66:	c7 44 24 08 e9 5d 10 	movl   $0x105de9,0x8(%esp)
  102c6d:	00 
  102c6e:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  102c75:	00 
  102c76:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  102c7d:	e8 ed d7 ff ff       	call   10046f <debug_panic>
	
	p->waitchild = cp;
  102c82:	8b 45 08             	mov    0x8(%ebp),%eax
  102c85:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c88:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)
	cp->parent = p;
  102c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102c91:	8b 55 08             	mov    0x8(%ebp),%edx
  102c94:	89 50 38             	mov    %edx,0x38(%eax)
	p->state = PROC_WAIT;
  102c97:	8b 45 08             	mov    0x8(%ebp),%eax
  102c9a:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  102ca1:	00 00 00 
	proc_save(p, tf, 0);
  102ca4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102cab:	00 
  102cac:	8b 45 10             	mov    0x10(%ebp),%eax
  102caf:	89 44 24 04          	mov    %eax,0x4(%esp)
  102cb3:	8b 45 08             	mov    0x8(%ebp),%eax
  102cb6:	89 04 24             	mov    %eax,(%esp)
  102cb9:	e8 2e ff ff ff       	call   102bec <proc_save>
	proc_run(cp);
  102cbe:	8b 45 0c             	mov    0xc(%ebp),%eax
  102cc1:	89 04 24             	mov    %eax,(%esp)
  102cc4:	e8 b0 00 00 00       	call   102d79 <proc_run>

00102cc9 <proc_sched>:
}

void gcc_noreturn
proc_sched(void)
{
  102cc9:	55                   	push   %ebp
  102cca:	89 e5                	mov    %esp,%ebp
  102ccc:	83 ec 28             	sub    $0x28,%esp
		//proc* before = cpu_cur()->proc;
			
		// if there is no ready process in queue
		// just wait

		spinlock_acquire(&queue.lock);
  102ccf:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102cd6:	e8 6c f5 ff ff       	call   102247 <spinlock_acquire>
		
		while(queue.count == 0){
  102cdb:	eb 05                	jmp    102ce2 <proc_sched+0x19>
			pause();
  102cdd:	e8 04 fc ff ff       	call   1028e6 <pause>
		// if there is no ready process in queue
		// just wait

		spinlock_acquire(&queue.lock);
		
		while(queue.count == 0){
  102ce2:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102ce7:	85 c0                	test   %eax,%eax
  102ce9:	74 f2                	je     102cdd <proc_sched+0x14>
			pause();
		}	
	
		// if there is just one ready process
		if(queue.count == 1){
  102ceb:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102cf0:	83 f8 01             	cmp    $0x1,%eax
  102cf3:	75 28                	jne    102d1d <proc_sched+0x54>
			run = queue.head;
  102cf5:	a1 dc fa 30 00       	mov    0x30fadc,%eax
  102cfa:	89 45 f0             	mov    %eax,-0x10(%ebp)
			queue.head = queue.tail = NULL;
  102cfd:	c7 05 e0 fa 30 00 00 	movl   $0x0,0x30fae0
  102d04:	00 00 00 
  102d07:	a1 e0 fa 30 00       	mov    0x30fae0,%eax
  102d0c:	a3 dc fa 30 00       	mov    %eax,0x30fadc
			queue.count = 0;
  102d11:	c7 05 d8 fa 30 00 00 	movl   $0x0,0x30fad8
  102d18:	00 00 00 
  102d1b:	eb 45                	jmp    102d62 <proc_sched+0x99>
		}
		
		// if there is more than one ready processes
		else{
			proc* before_tail = queue.head;
  102d1d:	a1 dc fa 30 00       	mov    0x30fadc,%eax
  102d22:	89 45 f4             	mov    %eax,-0xc(%ebp)
			while(before_tail->readynext != queue.tail){
  102d25:	eb 0c                	jmp    102d33 <proc_sched+0x6a>
				before_tail = before_tail->readynext;
  102d27:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d2a:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102d30:	89 45 f4             	mov    %eax,-0xc(%ebp)
		}
		
		// if there is more than one ready processes
		else{
			proc* before_tail = queue.head;
			while(before_tail->readynext != queue.tail){
  102d33:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d36:	8b 90 40 04 00 00    	mov    0x440(%eax),%edx
  102d3c:	a1 e0 fa 30 00       	mov    0x30fae0,%eax
  102d41:	39 c2                	cmp    %eax,%edx
  102d43:	75 e2                	jne    102d27 <proc_sched+0x5e>
				before_tail = before_tail->readynext;
			}	
			run = queue.tail;
  102d45:	a1 e0 fa 30 00       	mov    0x30fae0,%eax
  102d4a:	89 45 f0             	mov    %eax,-0x10(%ebp)
			queue.tail = before_tail;
  102d4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d50:	a3 e0 fa 30 00       	mov    %eax,0x30fae0
			queue.count--;
  102d55:	a1 d8 fa 30 00       	mov    0x30fad8,%eax
  102d5a:	83 e8 01             	sub    $0x1,%eax
  102d5d:	a3 d8 fa 30 00       	mov    %eax,0x30fad8
		}
		
		spinlock_release(&queue.lock);
  102d62:	c7 04 24 a0 fa 30 00 	movl   $0x30faa0,(%esp)
  102d69:	e8 55 f5 ff ff       	call   1022c3 <spinlock_release>
	
		proc_run(run);
  102d6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102d71:	89 04 24             	mov    %eax,(%esp)
  102d74:	e8 00 00 00 00       	call   102d79 <proc_run>

00102d79 <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  102d79:	55                   	push   %ebp
  102d7a:	89 e5                	mov    %esp,%ebp
  102d7c:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");

	if(p == NULL)
  102d7f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102d83:	75 1c                	jne    102da1 <proc_run+0x28>
		panic("proc_run's p is null!");
  102d85:	c7 44 24 08 f8 5d 10 	movl   $0x105df8,0x8(%esp)
  102d8c:	00 
  102d8d:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
  102d94:	00 
  102d95:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  102d9c:	e8 ce d6 ff ff       	call   10046f <debug_panic>

	spinlock_acquire(&p->lock);
  102da1:	8b 45 08             	mov    0x8(%ebp),%eax
  102da4:	89 04 24             	mov    %eax,(%esp)
  102da7:	e8 9b f4 ff ff       	call   102247 <spinlock_acquire>

	cpu* c = cpu_cur();
  102dac:	e8 3c fb ff ff       	call   1028ed <cpu_cur>
  102db1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->proc = p;
  102db4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102db7:	8b 55 08             	mov    0x8(%ebp),%edx
  102dba:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	p->state = PROC_RUN;
  102dc0:	8b 45 08             	mov    0x8(%ebp),%eax
  102dc3:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  102dca:	00 00 00 
	p->runcpu = c;
  102dcd:	8b 45 08             	mov    0x8(%ebp),%eax
  102dd0:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102dd3:	89 90 44 04 00 00    	mov    %edx,0x444(%eax)

	spinlock_release(&p->lock);
  102dd9:	8b 45 08             	mov    0x8(%ebp),%eax
  102ddc:	89 04 24             	mov    %eax,(%esp)
  102ddf:	e8 df f4 ff ff       	call   1022c3 <spinlock_release>
	
	trap_return(&p->sv.tf);
  102de4:	8b 45 08             	mov    0x8(%ebp),%eax
  102de7:	05 50 04 00 00       	add    $0x450,%eax
  102dec:	89 04 24             	mov    %eax,(%esp)
  102def:	e8 fc 62 00 00       	call   1090f0 <trap_return>

00102df4 <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  102df4:	55                   	push   %ebp
  102df5:	89 e5                	mov    %esp,%ebp
  102df7:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_yield not implemented");

	proc* cur_proc = cpu_cur()->proc;
  102dfa:	e8 ee fa ff ff       	call   1028ed <cpu_cur>
  102dff:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  102e05:	89 45 f4             	mov    %eax,-0xc(%ebp)
	proc_save(cur_proc, tf, 0);
  102e08:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102e0f:	00 
  102e10:	8b 45 08             	mov    0x8(%ebp),%eax
  102e13:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e17:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e1a:	89 04 24             	mov    %eax,(%esp)
  102e1d:	e8 ca fd ff ff       	call   102bec <proc_save>
	proc_ready(cur_proc);
  102e22:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e25:	89 04 24             	mov    %eax,(%esp)
  102e28:	e8 f9 fc ff ff       	call   102b26 <proc_ready>
	proc_sched();
  102e2d:	e8 97 fe ff ff       	call   102cc9 <proc_sched>

00102e32 <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  102e32:	55                   	push   %ebp
  102e33:	89 e5                	mov    %esp,%ebp
  102e35:	83 ec 18             	sub    $0x18,%esp
	panic("proc_ret not implemented");
  102e38:	c7 44 24 08 0e 5e 10 	movl   $0x105e0e,0x8(%esp)
  102e3f:	00 
  102e40:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  102e47:	00 
  102e48:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  102e4f:	e8 1b d6 ff ff       	call   10046f <debug_panic>

00102e54 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  102e54:	55                   	push   %ebp
  102e55:	89 e5                	mov    %esp,%ebp
  102e57:	57                   	push   %edi
  102e58:	56                   	push   %esi
  102e59:	53                   	push   %ebx
  102e5a:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  102e60:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  102e67:	00 00 00 
  102e6a:	e9 f0 00 00 00       	jmp    102f5f <proc_check+0x10b>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  102e6f:	b8 10 b3 10 00       	mov    $0x10b310,%eax
  102e74:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  102e7a:	83 c2 01             	add    $0x1,%edx
  102e7d:	c1 e2 0c             	shl    $0xc,%edx
  102e80:	01 d0                	add    %edx,%eax
  102e82:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		*--esp = i;	// push argument to child() function
  102e88:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  102e8f:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  102e95:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  102e9b:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  102e9d:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  102ea4:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  102eaa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  102eb0:	b8 34 33 10 00       	mov    $0x103334,%eax
  102eb5:	a3 f8 b0 10 00       	mov    %eax,0x10b0f8
		child_state.tf.esp = (uint32_t) esp;
  102eba:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  102ec0:	a3 04 b1 10 00       	mov    %eax,0x10b104

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  102ec5:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102ecb:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ecf:	c7 04 24 27 5e 10 00 	movl   $0x105e27,(%esp)
  102ed6:	e8 4a 1c 00 00       	call   104b25 <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  102edb:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102ee1:	0f b7 d0             	movzwl %ax,%edx
  102ee4:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  102eeb:	7f 07                	jg     102ef4 <proc_check+0xa0>
  102eed:	b8 10 10 00 00       	mov    $0x1010,%eax
  102ef2:	eb 05                	jmp    102ef9 <proc_check+0xa5>
  102ef4:	b8 00 10 00 00       	mov    $0x1000,%eax
  102ef9:	89 85 54 ff ff ff    	mov    %eax,-0xac(%ebp)
  102eff:	66 89 95 52 ff ff ff 	mov    %dx,-0xae(%ebp)
  102f06:	c7 85 4c ff ff ff c0 	movl   $0x10b0c0,-0xb4(%ebp)
  102f0d:	b0 10 00 
  102f10:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
  102f17:	00 00 00 
  102f1a:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
  102f21:	00 00 00 
  102f24:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
  102f2b:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  102f2e:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
  102f34:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  102f37:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
  102f3d:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
  102f44:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
  102f4a:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
  102f50:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
  102f56:	cd 30                	int    $0x30
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  102f58:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  102f5f:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  102f66:	0f 8e 03 ff ff ff    	jle    102e6f <proc_check+0x1b>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  102f6c:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  102f73:	00 00 00 
  102f76:	e9 89 00 00 00       	jmp    103004 <proc_check+0x1b0>
		cprintf("waiting for child %d\n", i);
  102f7b:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102f81:	89 44 24 04          	mov    %eax,0x4(%esp)
  102f85:	c7 04 24 3a 5e 10 00 	movl   $0x105e3a,(%esp)
  102f8c:	e8 94 1b 00 00       	call   104b25 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  102f91:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102f97:	0f b7 c0             	movzwl %ax,%eax
  102f9a:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
  102fa1:	10 00 00 
  102fa4:	66 89 85 6a ff ff ff 	mov    %ax,-0x96(%ebp)
  102fab:	c7 85 64 ff ff ff c0 	movl   $0x10b0c0,-0x9c(%ebp)
  102fb2:	b0 10 00 
  102fb5:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
  102fbc:	00 00 00 
  102fbf:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
  102fc6:	00 00 00 
  102fc9:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
  102fd0:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  102fd3:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
  102fd9:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  102fdc:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
  102fe2:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
  102fe9:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
  102fef:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
  102ff5:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
  102ffb:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  102ffd:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103004:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  10300b:	0f 8e 6a ff ff ff    	jle    102f7b <proc_check+0x127>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  103011:	c7 04 24 50 5e 10 00 	movl   $0x105e50,(%esp)
  103018:	e8 08 1b 00 00       	call   104b25 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  10301d:	c7 04 24 78 5e 10 00 	movl   $0x105e78,(%esp)
  103024:	e8 fc 1a 00 00       	call   104b25 <cprintf>
	for (i = 0; i < 4; i++) {
  103029:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103030:	00 00 00 
  103033:	eb 7d                	jmp    1030b2 <proc_check+0x25e>
		cprintf("spawning child %d\n", i);
  103035:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10303b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10303f:	c7 04 24 27 5e 10 00 	movl   $0x105e27,(%esp)
  103046:	e8 da 1a 00 00       	call   104b25 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  10304b:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103051:	0f b7 c0             	movzwl %ax,%eax
  103054:	c7 45 84 10 00 00 00 	movl   $0x10,-0x7c(%ebp)
  10305b:	66 89 45 82          	mov    %ax,-0x7e(%ebp)
  10305f:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  103066:	00 00 00 
  103069:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
  103070:	00 00 00 
  103073:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
  10307a:	00 00 00 
  10307d:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
  103084:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103087:	8b 45 84             	mov    -0x7c(%ebp),%eax
  10308a:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10308d:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
  103093:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
  103097:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
  10309d:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
  1030a3:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
  1030a9:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  1030ab:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  1030b2:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  1030b9:	0f 8e 76 ff ff ff    	jle    103035 <proc_check+0x1e1>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  1030bf:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  1030c6:	00 00 00 
  1030c9:	eb 4f                	jmp    10311a <proc_check+0x2c6>
		sys_get(0, i, NULL, NULL, NULL, 0);
  1030cb:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1030d1:	0f b7 c0             	movzwl %ax,%eax
  1030d4:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  1030db:	66 89 45 9a          	mov    %ax,-0x66(%ebp)
  1030df:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
  1030e6:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  1030ed:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
  1030f4:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1030fb:	8b 45 9c             	mov    -0x64(%ebp),%eax
  1030fe:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103101:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
  103104:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
  103108:	8b 75 90             	mov    -0x70(%ebp),%esi
  10310b:	8b 7d 8c             	mov    -0x74(%ebp),%edi
  10310e:	8b 4d 88             	mov    -0x78(%ebp),%ecx
  103111:	cd 30                	int    $0x30
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103113:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  10311a:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103121:	7e a8                	jle    1030cb <proc_check+0x277>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  103123:	c7 04 24 9c 5e 10 00 	movl   $0x105e9c,(%esp)
  10312a:	e8 f6 19 00 00       	call   104b25 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  10312f:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103136:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103139:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10313f:	0f b7 c0             	movzwl %ax,%eax
  103142:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
  103149:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
  10314d:	c7 45 ac c0 b0 10 00 	movl   $0x10b0c0,-0x54(%ebp)
  103154:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  10315b:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  103162:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103169:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  10316c:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10316f:	8b 5d ac             	mov    -0x54(%ebp),%ebx
  103172:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
  103176:	8b 75 a8             	mov    -0x58(%ebp),%esi
  103179:	8b 7d a4             	mov    -0x5c(%ebp),%edi
  10317c:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  10317f:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  103181:	a1 14 f3 10 00       	mov    0x10f314,%eax
  103186:	85 c0                	test   %eax,%eax
  103188:	74 24                	je     1031ae <proc_check+0x35a>
  10318a:	c7 44 24 0c c1 5e 10 	movl   $0x105ec1,0xc(%esp)
  103191:	00 
  103192:	c7 44 24 08 12 5d 10 	movl   $0x105d12,0x8(%esp)
  103199:	00 
  10319a:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
  1031a1:	00 
  1031a2:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  1031a9:	e8 c1 d2 ff ff       	call   10046f <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  1031ae:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1031b4:	0f b7 c0             	movzwl %ax,%eax
  1031b7:	c7 45 cc 10 10 00 00 	movl   $0x1010,-0x34(%ebp)
  1031be:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
  1031c2:	c7 45 c4 c0 b0 10 00 	movl   $0x10b0c0,-0x3c(%ebp)
  1031c9:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
  1031d0:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  1031d7:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1031de:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1031e1:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1031e4:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
  1031e7:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  1031eb:	8b 75 c0             	mov    -0x40(%ebp),%esi
  1031ee:	8b 7d bc             	mov    -0x44(%ebp),%edi
  1031f1:	8b 4d b8             	mov    -0x48(%ebp),%ecx
  1031f4:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  1031f6:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1031fc:	0f b7 c0             	movzwl %ax,%eax
  1031ff:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  103206:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
  10320a:	c7 45 dc c0 b0 10 00 	movl   $0x10b0c0,-0x24(%ebp)
  103211:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103218:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  10321f:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103226:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103229:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10322c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  10322f:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  103233:	8b 75 d8             	mov    -0x28(%ebp),%esi
  103236:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  103239:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  10323c:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  10323e:	a1 14 f3 10 00       	mov    0x10f314,%eax
  103243:	85 c0                	test   %eax,%eax
  103245:	74 3f                	je     103286 <proc_check+0x432>
			trap_check_args *args = recovargs;
  103247:	a1 14 f3 10 00       	mov    0x10f314,%eax
  10324c:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)
			cprintf("recover from trap %d\n",
  103252:	a1 f0 b0 10 00       	mov    0x10b0f0,%eax
  103257:	89 44 24 04          	mov    %eax,0x4(%esp)
  10325b:	c7 04 24 d3 5e 10 00 	movl   $0x105ed3,(%esp)
  103262:	e8 be 18 00 00       	call   104b25 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  103267:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  10326d:	8b 00                	mov    (%eax),%eax
  10326f:	a3 f8 b0 10 00       	mov    %eax,0x10b0f8
			args->trapno = child_state.tf.trapno;
  103274:	a1 f0 b0 10 00       	mov    0x10b0f0,%eax
  103279:	89 c2                	mov    %eax,%edx
  10327b:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  103281:	89 50 04             	mov    %edx,0x4(%eax)
  103284:	eb 2e                	jmp    1032b4 <proc_check+0x460>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  103286:	a1 f0 b0 10 00       	mov    0x10b0f0,%eax
  10328b:	83 f8 30             	cmp    $0x30,%eax
  10328e:	74 24                	je     1032b4 <proc_check+0x460>
  103290:	c7 44 24 0c ec 5e 10 	movl   $0x105eec,0xc(%esp)
  103297:	00 
  103298:	c7 44 24 08 12 5d 10 	movl   $0x105d12,0x8(%esp)
  10329f:	00 
  1032a0:	c7 44 24 04 2f 01 00 	movl   $0x12f,0x4(%esp)
  1032a7:	00 
  1032a8:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  1032af:	e8 bb d1 ff ff       	call   10046f <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  1032b4:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1032ba:	8d 50 01             	lea    0x1(%eax),%edx
  1032bd:	89 d0                	mov    %edx,%eax
  1032bf:	c1 f8 1f             	sar    $0x1f,%eax
  1032c2:	c1 e8 1e             	shr    $0x1e,%eax
  1032c5:	01 c2                	add    %eax,%edx
  1032c7:	83 e2 03             	and    $0x3,%edx
  1032ca:	89 d1                	mov    %edx,%ecx
  1032cc:	29 c1                	sub    %eax,%ecx
  1032ce:	89 c8                	mov    %ecx,%eax
  1032d0:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  1032d6:	a1 f0 b0 10 00       	mov    0x10b0f0,%eax
  1032db:	83 f8 30             	cmp    $0x30,%eax
  1032de:	0f 85 ca fe ff ff    	jne    1031ae <proc_check+0x35a>
	assert(recovargs == NULL);
  1032e4:	a1 14 f3 10 00       	mov    0x10f314,%eax
  1032e9:	85 c0                	test   %eax,%eax
  1032eb:	74 24                	je     103311 <proc_check+0x4bd>
  1032ed:	c7 44 24 0c c1 5e 10 	movl   $0x105ec1,0xc(%esp)
  1032f4:	00 
  1032f5:	c7 44 24 08 12 5d 10 	movl   $0x105d12,0x8(%esp)
  1032fc:	00 
  1032fd:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
  103304:	00 
  103305:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  10330c:	e8 5e d1 ff ff       	call   10046f <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  103311:	c7 04 24 10 5f 10 00 	movl   $0x105f10,(%esp)
  103318:	e8 08 18 00 00       	call   104b25 <cprintf>

	cprintf("proc_check() succeeded!\n");
  10331d:	c7 04 24 3d 5f 10 00 	movl   $0x105f3d,(%esp)
  103324:	e8 fc 17 00 00       	call   104b25 <cprintf>
}
  103329:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  10332f:	5b                   	pop    %ebx
  103330:	5e                   	pop    %esi
  103331:	5f                   	pop    %edi
  103332:	5d                   	pop    %ebp
  103333:	c3                   	ret    

00103334 <child>:

static void child(int n)
{
  103334:	55                   	push   %ebp
  103335:	89 e5                	mov    %esp,%ebp
  103337:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  10333a:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  10333e:	7f 64                	jg     1033a4 <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  103340:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  103347:	eb 4e                	jmp    103397 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  103349:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10334c:	89 44 24 08          	mov    %eax,0x8(%esp)
  103350:	8b 45 08             	mov    0x8(%ebp),%eax
  103353:	89 44 24 04          	mov    %eax,0x4(%esp)
  103357:	c7 04 24 56 5f 10 00 	movl   $0x105f56,(%esp)
  10335e:	e8 c2 17 00 00       	call   104b25 <cprintf>
			while (pingpong != n)
  103363:	eb 05                	jmp    10336a <child+0x36>
				pause();
  103365:	e8 7c f5 ff ff       	call   1028e6 <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n)
  10336a:	8b 55 08             	mov    0x8(%ebp),%edx
  10336d:	a1 10 f3 10 00       	mov    0x10f310,%eax
  103372:	39 c2                	cmp    %eax,%edx
  103374:	75 ef                	jne    103365 <child+0x31>
				pause();
			xchg(&pingpong, !pingpong);
  103376:	a1 10 f3 10 00       	mov    0x10f310,%eax
  10337b:	85 c0                	test   %eax,%eax
  10337d:	0f 94 c0             	sete   %al
  103380:	0f b6 c0             	movzbl %al,%eax
  103383:	89 44 24 04          	mov    %eax,0x4(%esp)
  103387:	c7 04 24 10 f3 10 00 	movl   $0x10f310,(%esp)
  10338e:	e8 28 f5 ff ff       	call   1028bb <xchg>
static void child(int n)
{
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  103393:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  103397:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  10339b:	7e ac                	jle    103349 <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  10339d:	b8 03 00 00 00       	mov    $0x3,%eax
  1033a2:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  1033a4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1033ab:	eb 4c                	jmp    1033f9 <child+0xc5>
		cprintf("in child %d count %d\n", n, i);
  1033ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1033b0:	89 44 24 08          	mov    %eax,0x8(%esp)
  1033b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1033b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033bb:	c7 04 24 56 5f 10 00 	movl   $0x105f56,(%esp)
  1033c2:	e8 5e 17 00 00       	call   104b25 <cprintf>
		while (pingpong != n)
  1033c7:	eb 05                	jmp    1033ce <child+0x9a>
			pause();
  1033c9:	e8 18 f5 ff ff       	call   1028e6 <pause>

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		cprintf("in child %d count %d\n", n, i);
		while (pingpong != n)
  1033ce:	8b 55 08             	mov    0x8(%ebp),%edx
  1033d1:	a1 10 f3 10 00       	mov    0x10f310,%eax
  1033d6:	39 c2                	cmp    %eax,%edx
  1033d8:	75 ef                	jne    1033c9 <child+0x95>
			pause();
		xchg(&pingpong, (pingpong + 1) % 4);
  1033da:	a1 10 f3 10 00       	mov    0x10f310,%eax
  1033df:	83 c0 01             	add    $0x1,%eax
  1033e2:	83 e0 03             	and    $0x3,%eax
  1033e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033e9:	c7 04 24 10 f3 10 00 	movl   $0x10f310,(%esp)
  1033f0:	e8 c6 f4 ff ff       	call   1028bb <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  1033f5:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1033f9:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  1033fd:	7e ae                	jle    1033ad <child+0x79>
  1033ff:	b8 03 00 00 00       	mov    $0x3,%eax
  103404:	cd 30                	int    $0x30
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  103406:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10340a:	75 6d                	jne    103479 <child+0x145>
		assert(recovargs == NULL);
  10340c:	a1 14 f3 10 00       	mov    0x10f314,%eax
  103411:	85 c0                	test   %eax,%eax
  103413:	74 24                	je     103439 <child+0x105>
  103415:	c7 44 24 0c c1 5e 10 	movl   $0x105ec1,0xc(%esp)
  10341c:	00 
  10341d:	c7 44 24 08 12 5d 10 	movl   $0x105d12,0x8(%esp)
  103424:	00 
  103425:	c7 44 24 04 53 01 00 	movl   $0x153,0x4(%esp)
  10342c:	00 
  10342d:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  103434:	e8 36 d0 ff ff       	call   10046f <debug_panic>
		trap_check(&recovargs);
  103439:	c7 04 24 14 f3 10 00 	movl   $0x10f314,(%esp)
  103440:	e8 69 e5 ff ff       	call   1019ae <trap_check>
		assert(recovargs == NULL);
  103445:	a1 14 f3 10 00       	mov    0x10f314,%eax
  10344a:	85 c0                	test   %eax,%eax
  10344c:	74 24                	je     103472 <child+0x13e>
  10344e:	c7 44 24 0c c1 5e 10 	movl   $0x105ec1,0xc(%esp)
  103455:	00 
  103456:	c7 44 24 08 12 5d 10 	movl   $0x105d12,0x8(%esp)
  10345d:	00 
  10345e:	c7 44 24 04 55 01 00 	movl   $0x155,0x4(%esp)
  103465:	00 
  103466:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  10346d:	e8 fd cf ff ff       	call   10046f <debug_panic>
  103472:	b8 03 00 00 00       	mov    $0x3,%eax
  103477:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  103479:	c7 44 24 08 6c 5f 10 	movl   $0x105f6c,0x8(%esp)
  103480:	00 
  103481:	c7 44 24 04 59 01 00 	movl   $0x159,0x4(%esp)
  103488:	00 
  103489:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  103490:	e8 da cf ff ff       	call   10046f <debug_panic>

00103495 <grandchild>:
}

static void grandchild(int n)
{
  103495:	55                   	push   %ebp
  103496:	89 e5                	mov    %esp,%ebp
  103498:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  10349b:	c7 44 24 08 90 5f 10 	movl   $0x105f90,0x8(%esp)
  1034a2:	00 
  1034a3:	c7 44 24 04 5e 01 00 	movl   $0x15e,0x4(%esp)
  1034aa:	00 
  1034ab:	c7 04 24 34 5d 10 00 	movl   $0x105d34,(%esp)
  1034b2:	e8 b8 cf ff ff       	call   10046f <debug_panic>

001034b7 <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  1034b7:	55                   	push   %ebp
  1034b8:	89 e5                	mov    %esp,%ebp
  1034ba:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  1034bd:	c7 44 24 08 bc 5f 10 	movl   $0x105fbc,0x8(%esp)
  1034c4:	00 
  1034c5:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  1034cc:	00 
  1034cd:	c7 04 24 d7 5f 10 00 	movl   $0x105fd7,(%esp)
  1034d4:	e8 96 cf ff ff       	call   10046f <debug_panic>

001034d9 <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  1034d9:	55                   	push   %ebp
  1034da:	89 e5                	mov    %esp,%ebp
  1034dc:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  1034df:	c7 44 24 08 e6 5f 10 	movl   $0x105fe6,0x8(%esp)
  1034e6:	00 
  1034e7:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  1034ee:	00 
  1034ef:	c7 04 24 d7 5f 10 00 	movl   $0x105fd7,(%esp)
  1034f6:	e8 74 cf ff ff       	call   10046f <debug_panic>

001034fb <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  1034fb:	55                   	push   %ebp
  1034fc:	89 e5                	mov    %esp,%ebp
  1034fe:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  103501:	c7 44 24 08 04 60 10 	movl   $0x106004,0x8(%esp)
  103508:	00 
  103509:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  103510:	00 
  103511:	c7 04 24 d7 5f 10 00 	movl   $0x105fd7,(%esp)
  103518:	e8 52 cf ff ff       	call   10046f <debug_panic>

0010351d <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  10351d:	55                   	push   %ebp
  10351e:	89 e5                	mov    %esp,%ebp
  103520:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  103523:	8b 45 18             	mov    0x18(%ebp),%eax
  103526:	89 44 24 08          	mov    %eax,0x8(%esp)
  10352a:	8b 45 14             	mov    0x14(%ebp),%eax
  10352d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103531:	8b 45 08             	mov    0x8(%ebp),%eax
  103534:	89 04 24             	mov    %eax,(%esp)
  103537:	e8 bf ff ff ff       	call   1034fb <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  10353c:	c7 44 24 08 20 60 10 	movl   $0x106020,0x8(%esp)
  103543:	00 
  103544:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  10354b:	00 
  10354c:	c7 04 24 d7 5f 10 00 	movl   $0x105fd7,(%esp)
  103553:	e8 17 cf ff ff       	call   10046f <debug_panic>

00103558 <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  103558:	55                   	push   %ebp
  103559:	89 e5                	mov    %esp,%ebp
  10355b:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  10355e:	8b 45 08             	mov    0x8(%ebp),%eax
  103561:	8b 40 10             	mov    0x10(%eax),%eax
  103564:	89 44 24 04          	mov    %eax,0x4(%esp)
  103568:	c7 04 24 44 60 10 00 	movl   $0x106044,(%esp)
  10356f:	e8 b1 15 00 00       	call   104b25 <cprintf>

	trap_return(tf);	// syscall completed
  103574:	8b 45 08             	mov    0x8(%ebp),%eax
  103577:	89 04 24             	mov    %eax,(%esp)
  10357a:	e8 71 5b 00 00       	call   1090f0 <trap_return>

0010357f <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  10357f:	55                   	push   %ebp
  103580:	89 e5                	mov    %esp,%ebp
  103582:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  103585:	8b 45 08             	mov    0x8(%ebp),%eax
  103588:	8b 40 1c             	mov    0x1c(%eax),%eax
  10358b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  10358e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103591:	83 e0 0f             	and    $0xf,%eax
  103594:	85 c0                	test   %eax,%eax
  103596:	75 15                	jne    1035ad <syscall+0x2e>
	case SYS_CPUTS:	return do_cputs(tf, cmd);
  103598:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10359b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10359f:	8b 45 08             	mov    0x8(%ebp),%eax
  1035a2:	89 04 24             	mov    %eax,(%esp)
  1035a5:	e8 ae ff ff ff       	call   103558 <do_cputs>
  1035aa:	90                   	nop
  1035ab:	eb 01                	jmp    1035ae <syscall+0x2f>
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
  1035ad:	90                   	nop
	}
}
  1035ae:	c9                   	leave  
  1035af:	c3                   	ret    

001035b0 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  1035b0:	55                   	push   %ebp
  1035b1:	89 e5                	mov    %esp,%ebp
  1035b3:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  1035b6:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  1035bd:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1035c0:	0f b7 00             	movzwl (%eax),%eax
  1035c3:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  1035c7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1035ca:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  1035cf:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1035d2:	0f b7 00             	movzwl (%eax),%eax
  1035d5:	66 3d 5a a5          	cmp    $0xa55a,%ax
  1035d9:	74 13                	je     1035ee <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  1035db:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  1035e2:	c7 05 18 f3 10 00 b4 	movl   $0x3b4,0x10f318
  1035e9:	03 00 00 
  1035ec:	eb 14                	jmp    103602 <video_init+0x52>
	} else {
		*cp = was;
  1035ee:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1035f1:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  1035f5:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  1035f8:	c7 05 18 f3 10 00 d4 	movl   $0x3d4,0x10f318
  1035ff:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  103602:	a1 18 f3 10 00       	mov    0x10f318,%eax
  103607:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10360a:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10360e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  103612:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103615:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  103616:	a1 18 f3 10 00       	mov    0x10f318,%eax
  10361b:	83 c0 01             	add    $0x1,%eax
  10361e:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103621:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103624:	89 c2                	mov    %eax,%edx
  103626:	ec                   	in     (%dx),%al
  103627:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10362a:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  10362e:	0f b6 c0             	movzbl %al,%eax
  103631:	c1 e0 08             	shl    $0x8,%eax
  103634:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  103637:	a1 18 f3 10 00       	mov    0x10f318,%eax
  10363c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10363f:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103643:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103647:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10364a:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  10364b:	a1 18 f3 10 00       	mov    0x10f318,%eax
  103650:	83 c0 01             	add    $0x1,%eax
  103653:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103656:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103659:	89 c2                	mov    %eax,%edx
  10365b:	ec                   	in     (%dx),%al
  10365c:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  10365f:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  103663:	0f b6 c0             	movzbl %al,%eax
  103666:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  103669:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10366c:	a3 1c f3 10 00       	mov    %eax,0x10f31c
	crt_pos = pos;
  103671:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103674:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
}
  10367a:	c9                   	leave  
  10367b:	c3                   	ret    

0010367c <video_putc>:



void
video_putc(int c)
{
  10367c:	55                   	push   %ebp
  10367d:	89 e5                	mov    %esp,%ebp
  10367f:	53                   	push   %ebx
  103680:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  103683:	8b 45 08             	mov    0x8(%ebp),%eax
  103686:	b0 00                	mov    $0x0,%al
  103688:	85 c0                	test   %eax,%eax
  10368a:	75 07                	jne    103693 <video_putc+0x17>
		c |= 0x0700;
  10368c:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  103693:	8b 45 08             	mov    0x8(%ebp),%eax
  103696:	25 ff 00 00 00       	and    $0xff,%eax
  10369b:	83 f8 09             	cmp    $0x9,%eax
  10369e:	0f 84 ae 00 00 00    	je     103752 <video_putc+0xd6>
  1036a4:	83 f8 09             	cmp    $0x9,%eax
  1036a7:	7f 0a                	jg     1036b3 <video_putc+0x37>
  1036a9:	83 f8 08             	cmp    $0x8,%eax
  1036ac:	74 14                	je     1036c2 <video_putc+0x46>
  1036ae:	e9 dd 00 00 00       	jmp    103790 <video_putc+0x114>
  1036b3:	83 f8 0a             	cmp    $0xa,%eax
  1036b6:	74 4e                	je     103706 <video_putc+0x8a>
  1036b8:	83 f8 0d             	cmp    $0xd,%eax
  1036bb:	74 59                	je     103716 <video_putc+0x9a>
  1036bd:	e9 ce 00 00 00       	jmp    103790 <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  1036c2:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  1036c9:	66 85 c0             	test   %ax,%ax
  1036cc:	0f 84 e4 00 00 00    	je     1037b6 <video_putc+0x13a>
			crt_pos--;
  1036d2:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  1036d9:	83 e8 01             	sub    $0x1,%eax
  1036dc:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  1036e2:	a1 1c f3 10 00       	mov    0x10f31c,%eax
  1036e7:	0f b7 15 20 f3 10 00 	movzwl 0x10f320,%edx
  1036ee:	0f b7 d2             	movzwl %dx,%edx
  1036f1:	01 d2                	add    %edx,%edx
  1036f3:	8d 14 10             	lea    (%eax,%edx,1),%edx
  1036f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1036f9:	b0 00                	mov    $0x0,%al
  1036fb:	83 c8 20             	or     $0x20,%eax
  1036fe:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  103701:	e9 b1 00 00 00       	jmp    1037b7 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  103706:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  10370d:	83 c0 50             	add    $0x50,%eax
  103710:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  103716:	0f b7 1d 20 f3 10 00 	movzwl 0x10f320,%ebx
  10371d:	0f b7 0d 20 f3 10 00 	movzwl 0x10f320,%ecx
  103724:	0f b7 c1             	movzwl %cx,%eax
  103727:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  10372d:	c1 e8 10             	shr    $0x10,%eax
  103730:	89 c2                	mov    %eax,%edx
  103732:	66 c1 ea 06          	shr    $0x6,%dx
  103736:	89 d0                	mov    %edx,%eax
  103738:	c1 e0 02             	shl    $0x2,%eax
  10373b:	01 d0                	add    %edx,%eax
  10373d:	c1 e0 04             	shl    $0x4,%eax
  103740:	89 ca                	mov    %ecx,%edx
  103742:	66 29 c2             	sub    %ax,%dx
  103745:	89 d8                	mov    %ebx,%eax
  103747:	66 29 d0             	sub    %dx,%ax
  10374a:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
		break;
  103750:	eb 65                	jmp    1037b7 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  103752:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103759:	e8 1e ff ff ff       	call   10367c <video_putc>
		video_putc(' ');
  10375e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103765:	e8 12 ff ff ff       	call   10367c <video_putc>
		video_putc(' ');
  10376a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103771:	e8 06 ff ff ff       	call   10367c <video_putc>
		video_putc(' ');
  103776:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10377d:	e8 fa fe ff ff       	call   10367c <video_putc>
		video_putc(' ');
  103782:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103789:	e8 ee fe ff ff       	call   10367c <video_putc>
		break;
  10378e:	eb 27                	jmp    1037b7 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  103790:	8b 15 1c f3 10 00    	mov    0x10f31c,%edx
  103796:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  10379d:	0f b7 c8             	movzwl %ax,%ecx
  1037a0:	01 c9                	add    %ecx,%ecx
  1037a2:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  1037a5:	8b 55 08             	mov    0x8(%ebp),%edx
  1037a8:	66 89 11             	mov    %dx,(%ecx)
  1037ab:	83 c0 01             	add    $0x1,%eax
  1037ae:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
  1037b4:	eb 01                	jmp    1037b7 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  1037b6:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  1037b7:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  1037be:	66 3d cf 07          	cmp    $0x7cf,%ax
  1037c2:	76 5b                	jbe    10381f <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  1037c4:	a1 1c f3 10 00       	mov    0x10f31c,%eax
  1037c9:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  1037cf:	a1 1c f3 10 00       	mov    0x10f31c,%eax
  1037d4:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  1037db:	00 
  1037dc:	89 54 24 04          	mov    %edx,0x4(%esp)
  1037e0:	89 04 24             	mov    %eax,(%esp)
  1037e3:	e8 96 15 00 00       	call   104d7e <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  1037e8:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  1037ef:	eb 15                	jmp    103806 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  1037f1:	a1 1c f3 10 00       	mov    0x10f31c,%eax
  1037f6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1037f9:	01 d2                	add    %edx,%edx
  1037fb:	01 d0                	add    %edx,%eax
  1037fd:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103802:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  103806:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  10380d:	7e e2                	jle    1037f1 <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  10380f:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103816:	83 e8 50             	sub    $0x50,%eax
  103819:	66 a3 20 f3 10 00    	mov    %ax,0x10f320
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  10381f:	a1 18 f3 10 00       	mov    0x10f318,%eax
  103824:	89 45 dc             	mov    %eax,-0x24(%ebp)
  103827:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10382b:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  10382f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103832:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  103833:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  10383a:	66 c1 e8 08          	shr    $0x8,%ax
  10383e:	0f b6 c0             	movzbl %al,%eax
  103841:	8b 15 18 f3 10 00    	mov    0x10f318,%edx
  103847:	83 c2 01             	add    $0x1,%edx
  10384a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10384d:	88 45 e3             	mov    %al,-0x1d(%ebp)
  103850:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103854:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103857:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  103858:	a1 18 f3 10 00       	mov    0x10f318,%eax
  10385d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103860:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  103864:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  103868:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10386b:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  10386c:	0f b7 05 20 f3 10 00 	movzwl 0x10f320,%eax
  103873:	0f b6 c0             	movzbl %al,%eax
  103876:	8b 15 18 f3 10 00    	mov    0x10f318,%edx
  10387c:	83 c2 01             	add    $0x1,%edx
  10387f:	89 55 f4             	mov    %edx,-0xc(%ebp)
  103882:	88 45 f3             	mov    %al,-0xd(%ebp)
  103885:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103889:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10388c:	ee                   	out    %al,(%dx)
}
  10388d:	83 c4 44             	add    $0x44,%esp
  103890:	5b                   	pop    %ebx
  103891:	5d                   	pop    %ebp
  103892:	c3                   	ret    

00103893 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  103893:	55                   	push   %ebp
  103894:	89 e5                	mov    %esp,%ebp
  103896:	83 ec 38             	sub    $0x38,%esp
  103899:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1038a0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1038a3:	89 c2                	mov    %eax,%edx
  1038a5:	ec                   	in     (%dx),%al
  1038a6:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  1038a9:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  1038ad:	0f b6 c0             	movzbl %al,%eax
  1038b0:	83 e0 01             	and    $0x1,%eax
  1038b3:	85 c0                	test   %eax,%eax
  1038b5:	75 0a                	jne    1038c1 <kbd_proc_data+0x2e>
		return -1;
  1038b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1038bc:	e9 5a 01 00 00       	jmp    103a1b <kbd_proc_data+0x188>
  1038c1:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1038c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1038cb:	89 c2                	mov    %eax,%edx
  1038cd:	ec                   	in     (%dx),%al
  1038ce:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  1038d1:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  1038d5:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  1038d8:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  1038dc:	75 17                	jne    1038f5 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  1038de:	a1 24 f3 10 00       	mov    0x10f324,%eax
  1038e3:	83 c8 40             	or     $0x40,%eax
  1038e6:	a3 24 f3 10 00       	mov    %eax,0x10f324
		return 0;
  1038eb:	b8 00 00 00 00       	mov    $0x0,%eax
  1038f0:	e9 26 01 00 00       	jmp    103a1b <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  1038f5:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1038f9:	84 c0                	test   %al,%al
  1038fb:	79 47                	jns    103944 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  1038fd:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103902:	83 e0 40             	and    $0x40,%eax
  103905:	85 c0                	test   %eax,%eax
  103907:	75 09                	jne    103912 <kbd_proc_data+0x7f>
  103909:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10390d:	83 e0 7f             	and    $0x7f,%eax
  103910:	eb 04                	jmp    103916 <kbd_proc_data+0x83>
  103912:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103916:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  103919:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10391d:	0f b6 80 20 91 10 00 	movzbl 0x109120(%eax),%eax
  103924:	83 c8 40             	or     $0x40,%eax
  103927:	0f b6 c0             	movzbl %al,%eax
  10392a:	f7 d0                	not    %eax
  10392c:	89 c2                	mov    %eax,%edx
  10392e:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103933:	21 d0                	and    %edx,%eax
  103935:	a3 24 f3 10 00       	mov    %eax,0x10f324
		return 0;
  10393a:	b8 00 00 00 00       	mov    $0x0,%eax
  10393f:	e9 d7 00 00 00       	jmp    103a1b <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  103944:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103949:	83 e0 40             	and    $0x40,%eax
  10394c:	85 c0                	test   %eax,%eax
  10394e:	74 11                	je     103961 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  103950:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  103954:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103959:	83 e0 bf             	and    $0xffffffbf,%eax
  10395c:	a3 24 f3 10 00       	mov    %eax,0x10f324
	}

	shift |= shiftcode[data];
  103961:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103965:	0f b6 80 20 91 10 00 	movzbl 0x109120(%eax),%eax
  10396c:	0f b6 d0             	movzbl %al,%edx
  10396f:	a1 24 f3 10 00       	mov    0x10f324,%eax
  103974:	09 d0                	or     %edx,%eax
  103976:	a3 24 f3 10 00       	mov    %eax,0x10f324
	shift ^= togglecode[data];
  10397b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10397f:	0f b6 80 20 92 10 00 	movzbl 0x109220(%eax),%eax
  103986:	0f b6 d0             	movzbl %al,%edx
  103989:	a1 24 f3 10 00       	mov    0x10f324,%eax
  10398e:	31 d0                	xor    %edx,%eax
  103990:	a3 24 f3 10 00       	mov    %eax,0x10f324

	c = charcode[shift & (CTL | SHIFT)][data];
  103995:	a1 24 f3 10 00       	mov    0x10f324,%eax
  10399a:	83 e0 03             	and    $0x3,%eax
  10399d:	8b 14 85 20 96 10 00 	mov    0x109620(,%eax,4),%edx
  1039a4:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1039a8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1039ab:	0f b6 00             	movzbl (%eax),%eax
  1039ae:	0f b6 c0             	movzbl %al,%eax
  1039b1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  1039b4:	a1 24 f3 10 00       	mov    0x10f324,%eax
  1039b9:	83 e0 08             	and    $0x8,%eax
  1039bc:	85 c0                	test   %eax,%eax
  1039be:	74 22                	je     1039e2 <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  1039c0:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  1039c4:	7e 0c                	jle    1039d2 <kbd_proc_data+0x13f>
  1039c6:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  1039ca:	7f 06                	jg     1039d2 <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  1039cc:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  1039d0:	eb 10                	jmp    1039e2 <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  1039d2:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  1039d6:	7e 0a                	jle    1039e2 <kbd_proc_data+0x14f>
  1039d8:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  1039dc:	7f 04                	jg     1039e2 <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  1039de:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  1039e2:	a1 24 f3 10 00       	mov    0x10f324,%eax
  1039e7:	f7 d0                	not    %eax
  1039e9:	83 e0 06             	and    $0x6,%eax
  1039ec:	85 c0                	test   %eax,%eax
  1039ee:	75 28                	jne    103a18 <kbd_proc_data+0x185>
  1039f0:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  1039f7:	75 1f                	jne    103a18 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  1039f9:	c7 04 24 47 60 10 00 	movl   $0x106047,(%esp)
  103a00:	e8 20 11 00 00       	call   104b25 <cprintf>
  103a05:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  103a0c:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103a10:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103a14:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103a17:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  103a18:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  103a1b:	c9                   	leave  
  103a1c:	c3                   	ret    

00103a1d <kbd_intr>:

void
kbd_intr(void)
{
  103a1d:	55                   	push   %ebp
  103a1e:	89 e5                	mov    %esp,%ebp
  103a20:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  103a23:	c7 04 24 93 38 10 00 	movl   $0x103893,(%esp)
  103a2a:	e8 75 c8 ff ff       	call   1002a4 <cons_intr>
}
  103a2f:	c9                   	leave  
  103a30:	c3                   	ret    

00103a31 <kbd_init>:

void
kbd_init(void)
{
  103a31:	55                   	push   %ebp
  103a32:	89 e5                	mov    %esp,%ebp
}
  103a34:	5d                   	pop    %ebp
  103a35:	c3                   	ret    

00103a36 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  103a36:	55                   	push   %ebp
  103a37:	89 e5                	mov    %esp,%ebp
  103a39:	83 ec 20             	sub    $0x20,%esp
  103a3c:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103a43:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103a46:	89 c2                	mov    %eax,%edx
  103a48:	ec                   	in     (%dx),%al
  103a49:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  103a4c:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103a53:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a56:	89 c2                	mov    %eax,%edx
  103a58:	ec                   	in     (%dx),%al
  103a59:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  103a5c:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103a63:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103a66:	89 c2                	mov    %eax,%edx
  103a68:	ec                   	in     (%dx),%al
  103a69:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  103a6c:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103a73:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103a76:	89 c2                	mov    %eax,%edx
  103a78:	ec                   	in     (%dx),%al
  103a79:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  103a7c:	c9                   	leave  
  103a7d:	c3                   	ret    

00103a7e <serial_proc_data>:

static int
serial_proc_data(void)
{
  103a7e:	55                   	push   %ebp
  103a7f:	89 e5                	mov    %esp,%ebp
  103a81:	83 ec 10             	sub    $0x10,%esp
  103a84:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  103a8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103a8e:	89 c2                	mov    %eax,%edx
  103a90:	ec                   	in     (%dx),%al
  103a91:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  103a94:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  103a98:	0f b6 c0             	movzbl %al,%eax
  103a9b:	83 e0 01             	and    $0x1,%eax
  103a9e:	85 c0                	test   %eax,%eax
  103aa0:	75 07                	jne    103aa9 <serial_proc_data+0x2b>
		return -1;
  103aa2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  103aa7:	eb 17                	jmp    103ac0 <serial_proc_data+0x42>
  103aa9:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103ab0:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103ab3:	89 c2                	mov    %eax,%edx
  103ab5:	ec                   	in     (%dx),%al
  103ab6:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  103ab9:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  103abd:	0f b6 c0             	movzbl %al,%eax
}
  103ac0:	c9                   	leave  
  103ac1:	c3                   	ret    

00103ac2 <serial_intr>:

void
serial_intr(void)
{
  103ac2:	55                   	push   %ebp
  103ac3:	89 e5                	mov    %esp,%ebp
  103ac5:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  103ac8:	a1 e8 fa 30 00       	mov    0x30fae8,%eax
  103acd:	85 c0                	test   %eax,%eax
  103acf:	74 0c                	je     103add <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  103ad1:	c7 04 24 7e 3a 10 00 	movl   $0x103a7e,(%esp)
  103ad8:	e8 c7 c7 ff ff       	call   1002a4 <cons_intr>
}
  103add:	c9                   	leave  
  103ade:	c3                   	ret    

00103adf <serial_putc>:

void
serial_putc(int c)
{
  103adf:	55                   	push   %ebp
  103ae0:	89 e5                	mov    %esp,%ebp
  103ae2:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  103ae5:	a1 e8 fa 30 00       	mov    0x30fae8,%eax
  103aea:	85 c0                	test   %eax,%eax
  103aec:	74 53                	je     103b41 <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  103aee:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103af5:	eb 09                	jmp    103b00 <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  103af7:	e8 3a ff ff ff       	call   103a36 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  103afc:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103b00:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103b07:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b0a:	89 c2                	mov    %eax,%edx
  103b0c:	ec                   	in     (%dx),%al
  103b0d:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  103b10:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  103b14:	0f b6 c0             	movzbl %al,%eax
  103b17:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  103b1a:	85 c0                	test   %eax,%eax
  103b1c:	75 09                	jne    103b27 <serial_putc+0x48>
  103b1e:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  103b25:	7e d0                	jle    103af7 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  103b27:	8b 45 08             	mov    0x8(%ebp),%eax
  103b2a:	0f b6 c0             	movzbl %al,%eax
  103b2d:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  103b34:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103b37:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  103b3b:	8b 55 fc             	mov    -0x4(%ebp),%edx
  103b3e:	ee                   	out    %al,(%dx)
  103b3f:	eb 01                	jmp    103b42 <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  103b41:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  103b42:	c9                   	leave  
  103b43:	c3                   	ret    

00103b44 <serial_init>:

void
serial_init(void)
{
  103b44:	55                   	push   %ebp
  103b45:	89 e5                	mov    %esp,%ebp
  103b47:	83 ec 50             	sub    $0x50,%esp
  103b4a:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  103b51:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  103b55:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  103b59:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  103b5c:	ee                   	out    %al,(%dx)
  103b5d:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  103b64:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  103b68:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  103b6c:	8b 55 bc             	mov    -0x44(%ebp),%edx
  103b6f:	ee                   	out    %al,(%dx)
  103b70:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  103b77:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  103b7b:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  103b7f:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  103b82:	ee                   	out    %al,(%dx)
  103b83:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  103b8a:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  103b8e:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  103b92:	8b 55 cc             	mov    -0x34(%ebp),%edx
  103b95:	ee                   	out    %al,(%dx)
  103b96:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  103b9d:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  103ba1:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  103ba5:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103ba8:	ee                   	out    %al,(%dx)
  103ba9:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  103bb0:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  103bb4:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103bb8:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103bbb:	ee                   	out    %al,(%dx)
  103bbc:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  103bc3:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  103bc7:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103bcb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103bce:	ee                   	out    %al,(%dx)
  103bcf:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103bd6:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103bd9:	89 c2                	mov    %eax,%edx
  103bdb:	ec                   	in     (%dx),%al
  103bdc:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  103bdf:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  103be3:	3c ff                	cmp    $0xff,%al
  103be5:	0f 95 c0             	setne  %al
  103be8:	0f b6 c0             	movzbl %al,%eax
  103beb:	a3 e8 fa 30 00       	mov    %eax,0x30fae8
  103bf0:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103bf7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103bfa:	89 c2                	mov    %eax,%edx
  103bfc:	ec                   	in     (%dx),%al
  103bfd:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  103c00:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103c07:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103c0a:	89 c2                	mov    %eax,%edx
  103c0c:	ec                   	in     (%dx),%al
  103c0d:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  103c10:	c9                   	leave  
  103c11:	c3                   	ret    

00103c12 <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  103c12:	55                   	push   %ebp
  103c13:	89 e5                	mov    %esp,%ebp
  103c15:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  103c1b:	a1 28 f3 10 00       	mov    0x10f328,%eax
  103c20:	85 c0                	test   %eax,%eax
  103c22:	0f 85 35 01 00 00    	jne    103d5d <pic_init+0x14b>
		return;
	didinit = 1;
  103c28:	c7 05 28 f3 10 00 01 	movl   $0x1,0x10f328
  103c2f:	00 00 00 
  103c32:	c7 45 8c 21 00 00 00 	movl   $0x21,-0x74(%ebp)
  103c39:	c6 45 8b ff          	movb   $0xff,-0x75(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103c3d:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  103c41:	8b 55 8c             	mov    -0x74(%ebp),%edx
  103c44:	ee                   	out    %al,(%dx)
  103c45:	c7 45 94 a1 00 00 00 	movl   $0xa1,-0x6c(%ebp)
  103c4c:	c6 45 93 ff          	movb   $0xff,-0x6d(%ebp)
  103c50:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  103c54:	8b 55 94             	mov    -0x6c(%ebp),%edx
  103c57:	ee                   	out    %al,(%dx)
  103c58:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  103c5f:	c6 45 9b 11          	movb   $0x11,-0x65(%ebp)
  103c63:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  103c67:	8b 55 9c             	mov    -0x64(%ebp),%edx
  103c6a:	ee                   	out    %al,(%dx)
  103c6b:	c7 45 a4 21 00 00 00 	movl   $0x21,-0x5c(%ebp)
  103c72:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
  103c76:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  103c7a:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  103c7d:	ee                   	out    %al,(%dx)
  103c7e:	c7 45 ac 21 00 00 00 	movl   $0x21,-0x54(%ebp)
  103c85:	c6 45 ab 04          	movb   $0x4,-0x55(%ebp)
  103c89:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  103c8d:	8b 55 ac             	mov    -0x54(%ebp),%edx
  103c90:	ee                   	out    %al,(%dx)
  103c91:	c7 45 b4 21 00 00 00 	movl   $0x21,-0x4c(%ebp)
  103c98:	c6 45 b3 03          	movb   $0x3,-0x4d(%ebp)
  103c9c:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  103ca0:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  103ca3:	ee                   	out    %al,(%dx)
  103ca4:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
  103cab:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
  103caf:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  103cb3:	8b 55 bc             	mov    -0x44(%ebp),%edx
  103cb6:	ee                   	out    %al,(%dx)
  103cb7:	c7 45 c4 a1 00 00 00 	movl   $0xa1,-0x3c(%ebp)
  103cbe:	c6 45 c3 28          	movb   $0x28,-0x3d(%ebp)
  103cc2:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  103cc6:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  103cc9:	ee                   	out    %al,(%dx)
  103cca:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
  103cd1:	c6 45 cb 02          	movb   $0x2,-0x35(%ebp)
  103cd5:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  103cd9:	8b 55 cc             	mov    -0x34(%ebp),%edx
  103cdc:	ee                   	out    %al,(%dx)
  103cdd:	c7 45 d4 a1 00 00 00 	movl   $0xa1,-0x2c(%ebp)
  103ce4:	c6 45 d3 01          	movb   $0x1,-0x2d(%ebp)
  103ce8:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  103cec:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103cef:	ee                   	out    %al,(%dx)
  103cf0:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
  103cf7:	c6 45 db 68          	movb   $0x68,-0x25(%ebp)
  103cfb:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103cff:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103d02:	ee                   	out    %al,(%dx)
  103d03:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  103d0a:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  103d0e:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103d12:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103d15:	ee                   	out    %al,(%dx)
  103d16:	c7 45 ec a0 00 00 00 	movl   $0xa0,-0x14(%ebp)
  103d1d:	c6 45 eb 68          	movb   $0x68,-0x15(%ebp)
  103d21:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  103d25:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103d28:	ee                   	out    %al,(%dx)
  103d29:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
  103d30:	c6 45 f3 0a          	movb   $0xa,-0xd(%ebp)
  103d34:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103d38:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103d3b:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  103d3c:	0f b7 05 30 96 10 00 	movzwl 0x109630,%eax
  103d43:	66 83 f8 ff          	cmp    $0xffff,%ax
  103d47:	74 15                	je     103d5e <pic_init+0x14c>
		pic_setmask(irqmask);
  103d49:	0f b7 05 30 96 10 00 	movzwl 0x109630,%eax
  103d50:	0f b7 c0             	movzwl %ax,%eax
  103d53:	89 04 24             	mov    %eax,(%esp)
  103d56:	e8 05 00 00 00       	call   103d60 <pic_setmask>
  103d5b:	eb 01                	jmp    103d5e <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  103d5d:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  103d5e:	c9                   	leave  
  103d5f:	c3                   	ret    

00103d60 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  103d60:	55                   	push   %ebp
  103d61:	89 e5                	mov    %esp,%ebp
  103d63:	83 ec 14             	sub    $0x14,%esp
  103d66:	8b 45 08             	mov    0x8(%ebp),%eax
  103d69:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  103d6d:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  103d71:	66 a3 30 96 10 00    	mov    %ax,0x109630
	outb(IO_PIC1+1, (char)mask);
  103d77:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  103d7b:	0f b6 c0             	movzbl %al,%eax
  103d7e:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  103d85:	88 45 f3             	mov    %al,-0xd(%ebp)
  103d88:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103d8c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103d8f:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  103d90:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  103d94:	66 c1 e8 08          	shr    $0x8,%ax
  103d98:	0f b6 c0             	movzbl %al,%eax
  103d9b:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
  103da2:	88 45 fb             	mov    %al,-0x5(%ebp)
  103da5:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  103da9:	8b 55 fc             	mov    -0x4(%ebp),%edx
  103dac:	ee                   	out    %al,(%dx)
}
  103dad:	c9                   	leave  
  103dae:	c3                   	ret    

00103daf <pic_enable>:

void
pic_enable(int irq)
{
  103daf:	55                   	push   %ebp
  103db0:	89 e5                	mov    %esp,%ebp
  103db2:	53                   	push   %ebx
  103db3:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  103db6:	8b 45 08             	mov    0x8(%ebp),%eax
  103db9:	ba 01 00 00 00       	mov    $0x1,%edx
  103dbe:	89 d3                	mov    %edx,%ebx
  103dc0:	89 c1                	mov    %eax,%ecx
  103dc2:	d3 e3                	shl    %cl,%ebx
  103dc4:	89 d8                	mov    %ebx,%eax
  103dc6:	89 c2                	mov    %eax,%edx
  103dc8:	f7 d2                	not    %edx
  103dca:	0f b7 05 30 96 10 00 	movzwl 0x109630,%eax
  103dd1:	21 d0                	and    %edx,%eax
  103dd3:	0f b7 c0             	movzwl %ax,%eax
  103dd6:	89 04 24             	mov    %eax,(%esp)
  103dd9:	e8 82 ff ff ff       	call   103d60 <pic_setmask>
}
  103dde:	83 c4 04             	add    $0x4,%esp
  103de1:	5b                   	pop    %ebx
  103de2:	5d                   	pop    %ebp
  103de3:	c3                   	ret    

00103de4 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  103de4:	55                   	push   %ebp
  103de5:	89 e5                	mov    %esp,%ebp
  103de7:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  103dea:	8b 45 08             	mov    0x8(%ebp),%eax
  103ded:	0f b6 c0             	movzbl %al,%eax
  103df0:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  103df7:	88 45 f3             	mov    %al,-0xd(%ebp)
  103dfa:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103dfe:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103e01:	ee                   	out    %al,(%dx)
  103e02:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103e09:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103e0c:	89 c2                	mov    %eax,%edx
  103e0e:	ec                   	in     (%dx),%al
  103e0f:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  103e12:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  103e16:	0f b6 c0             	movzbl %al,%eax
}
  103e19:	c9                   	leave  
  103e1a:	c3                   	ret    

00103e1b <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  103e1b:	55                   	push   %ebp
  103e1c:	89 e5                	mov    %esp,%ebp
  103e1e:	53                   	push   %ebx
  103e1f:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  103e22:	8b 45 08             	mov    0x8(%ebp),%eax
  103e25:	89 04 24             	mov    %eax,(%esp)
  103e28:	e8 b7 ff ff ff       	call   103de4 <nvram_read>
  103e2d:	89 c3                	mov    %eax,%ebx
  103e2f:	8b 45 08             	mov    0x8(%ebp),%eax
  103e32:	83 c0 01             	add    $0x1,%eax
  103e35:	89 04 24             	mov    %eax,(%esp)
  103e38:	e8 a7 ff ff ff       	call   103de4 <nvram_read>
  103e3d:	c1 e0 08             	shl    $0x8,%eax
  103e40:	09 d8                	or     %ebx,%eax
}
  103e42:	83 c4 04             	add    $0x4,%esp
  103e45:	5b                   	pop    %ebx
  103e46:	5d                   	pop    %ebp
  103e47:	c3                   	ret    

00103e48 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  103e48:	55                   	push   %ebp
  103e49:	89 e5                	mov    %esp,%ebp
  103e4b:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  103e4e:	8b 45 08             	mov    0x8(%ebp),%eax
  103e51:	0f b6 c0             	movzbl %al,%eax
  103e54:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  103e5b:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103e5e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103e62:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103e65:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  103e66:	8b 45 0c             	mov    0xc(%ebp),%eax
  103e69:	0f b6 c0             	movzbl %al,%eax
  103e6c:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  103e73:	88 45 fb             	mov    %al,-0x5(%ebp)
  103e76:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  103e7a:	8b 55 fc             	mov    -0x4(%ebp),%edx
  103e7d:	ee                   	out    %al,(%dx)
}
  103e7e:	c9                   	leave  
  103e7f:	c3                   	ret    

00103e80 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103e80:	55                   	push   %ebp
  103e81:	89 e5                	mov    %esp,%ebp
  103e83:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103e86:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  103e89:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103e8c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103e8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103e92:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103e97:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  103e9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103e9d:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103ea3:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103ea8:	74 24                	je     103ece <cpu_cur+0x4e>
  103eaa:	c7 44 24 0c 53 60 10 	movl   $0x106053,0xc(%esp)
  103eb1:	00 
  103eb2:	c7 44 24 08 69 60 10 	movl   $0x106069,0x8(%esp)
  103eb9:	00 
  103eba:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103ec1:	00 
  103ec2:	c7 04 24 7e 60 10 00 	movl   $0x10607e,(%esp)
  103ec9:	e8 a1 c5 ff ff       	call   10046f <debug_panic>
	return c;
  103ece:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103ed1:	c9                   	leave  
  103ed2:	c3                   	ret    

00103ed3 <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  103ed3:	55                   	push   %ebp
  103ed4:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  103ed6:	a1 ec fa 30 00       	mov    0x30faec,%eax
  103edb:	8b 55 08             	mov    0x8(%ebp),%edx
  103ede:	c1 e2 02             	shl    $0x2,%edx
  103ee1:	8d 14 10             	lea    (%eax,%edx,1),%edx
  103ee4:	8b 45 0c             	mov    0xc(%ebp),%eax
  103ee7:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  103ee9:	a1 ec fa 30 00       	mov    0x30faec,%eax
  103eee:	83 c0 20             	add    $0x20,%eax
  103ef1:	8b 00                	mov    (%eax),%eax
}
  103ef3:	5d                   	pop    %ebp
  103ef4:	c3                   	ret    

00103ef5 <lapic_init>:

void
lapic_init()
{
  103ef5:	55                   	push   %ebp
  103ef6:	89 e5                	mov    %esp,%ebp
  103ef8:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  103efb:	a1 ec fa 30 00       	mov    0x30faec,%eax
  103f00:	85 c0                	test   %eax,%eax
  103f02:	0f 84 82 01 00 00    	je     10408a <lapic_init+0x195>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  103f08:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  103f0f:	00 
  103f10:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  103f17:	e8 b7 ff ff ff       	call   103ed3 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  103f1c:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  103f23:	00 
  103f24:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  103f2b:	e8 a3 ff ff ff       	call   103ed3 <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  103f30:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  103f37:	00 
  103f38:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  103f3f:	e8 8f ff ff ff       	call   103ed3 <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  103f44:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  103f4b:	00 
  103f4c:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  103f53:	e8 7b ff ff ff       	call   103ed3 <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  103f58:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  103f5f:	00 
  103f60:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  103f67:	e8 67 ff ff ff       	call   103ed3 <lapicw>
	lapicw(LINT1, MASKED);
  103f6c:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  103f73:	00 
  103f74:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  103f7b:	e8 53 ff ff ff       	call   103ed3 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  103f80:	a1 ec fa 30 00       	mov    0x30faec,%eax
  103f85:	83 c0 30             	add    $0x30,%eax
  103f88:	8b 00                	mov    (%eax),%eax
  103f8a:	c1 e8 10             	shr    $0x10,%eax
  103f8d:	25 ff 00 00 00       	and    $0xff,%eax
  103f92:	83 f8 03             	cmp    $0x3,%eax
  103f95:	76 14                	jbe    103fab <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  103f97:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  103f9e:	00 
  103f9f:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  103fa6:	e8 28 ff ff ff       	call   103ed3 <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  103fab:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  103fb2:	00 
  103fb3:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  103fba:	e8 14 ff ff ff       	call   103ed3 <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  103fbf:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  103fc6:	ff 
  103fc7:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  103fce:	e8 00 ff ff ff       	call   103ed3 <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  103fd3:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  103fda:	f0 
  103fdb:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  103fe2:	e8 ec fe ff ff       	call   103ed3 <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  103fe7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103fee:	00 
  103fef:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103ff6:	e8 d8 fe ff ff       	call   103ed3 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  103ffb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104002:	00 
  104003:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10400a:	e8 c4 fe ff ff       	call   103ed3 <lapicw>
	lapicw(ESR, 0);
  10400f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104016:	00 
  104017:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10401e:	e8 b0 fe ff ff       	call   103ed3 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  104023:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10402a:	00 
  10402b:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  104032:	e8 9c fe ff ff       	call   103ed3 <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  104037:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10403e:	00 
  10403f:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  104046:	e8 88 fe ff ff       	call   103ed3 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  10404b:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  104052:	00 
  104053:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10405a:	e8 74 fe ff ff       	call   103ed3 <lapicw>
	while(lapic[ICRLO] & DELIVS)
  10405f:	a1 ec fa 30 00       	mov    0x30faec,%eax
  104064:	05 00 03 00 00       	add    $0x300,%eax
  104069:	8b 00                	mov    (%eax),%eax
  10406b:	25 00 10 00 00       	and    $0x1000,%eax
  104070:	85 c0                	test   %eax,%eax
  104072:	75 eb                	jne    10405f <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  104074:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10407b:	00 
  10407c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  104083:	e8 4b fe ff ff       	call   103ed3 <lapicw>
  104088:	eb 01                	jmp    10408b <lapic_init+0x196>

void
lapic_init()
{
	if (!lapic) 
		return;
  10408a:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  10408b:	c9                   	leave  
  10408c:	c3                   	ret    

0010408d <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  10408d:	55                   	push   %ebp
  10408e:	89 e5                	mov    %esp,%ebp
  104090:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  104093:	a1 ec fa 30 00       	mov    0x30faec,%eax
  104098:	85 c0                	test   %eax,%eax
  10409a:	74 14                	je     1040b0 <lapic_eoi+0x23>
		lapicw(EOI, 0);
  10409c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1040a3:	00 
  1040a4:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  1040ab:	e8 23 fe ff ff       	call   103ed3 <lapicw>
}
  1040b0:	c9                   	leave  
  1040b1:	c3                   	ret    

001040b2 <lapic_errintr>:

void lapic_errintr(void)
{
  1040b2:	55                   	push   %ebp
  1040b3:	89 e5                	mov    %esp,%ebp
  1040b5:	53                   	push   %ebx
  1040b6:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  1040b9:	e8 cf ff ff ff       	call   10408d <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  1040be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1040c5:	00 
  1040c6:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1040cd:	e8 01 fe ff ff       	call   103ed3 <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  1040d2:	a1 ec fa 30 00       	mov    0x30faec,%eax
  1040d7:	05 80 02 00 00       	add    $0x280,%eax
  1040dc:	8b 18                	mov    (%eax),%ebx
  1040de:	e8 9d fd ff ff       	call   103e80 <cpu_cur>
  1040e3:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1040ea:	0f b6 c0             	movzbl %al,%eax
  1040ed:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  1040f1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1040f5:	c7 44 24 08 8b 60 10 	movl   $0x10608b,0x8(%esp)
  1040fc:	00 
  1040fd:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  104104:	00 
  104105:	c7 04 24 a5 60 10 00 	movl   $0x1060a5,(%esp)
  10410c:	e8 1d c4 ff ff       	call   10052e <debug_warn>
}
  104111:	83 c4 24             	add    $0x24,%esp
  104114:	5b                   	pop    %ebx
  104115:	5d                   	pop    %ebp
  104116:	c3                   	ret    

00104117 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  104117:	55                   	push   %ebp
  104118:	89 e5                	mov    %esp,%ebp
}
  10411a:	5d                   	pop    %ebp
  10411b:	c3                   	ret    

0010411c <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  10411c:	55                   	push   %ebp
  10411d:	89 e5                	mov    %esp,%ebp
  10411f:	83 ec 2c             	sub    $0x2c,%esp
  104122:	8b 45 08             	mov    0x8(%ebp),%eax
  104125:	88 45 dc             	mov    %al,-0x24(%ebp)
  104128:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  10412f:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  104133:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104137:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10413a:	ee                   	out    %al,(%dx)
  10413b:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  104142:	c6 45 fb 0a          	movb   $0xa,-0x5(%ebp)
  104146:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  10414a:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10414d:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  10414e:	c7 45 ec 67 04 00 00 	movl   $0x467,-0x14(%ebp)
	wrv[0] = 0;
  104155:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104158:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  10415d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104160:	8d 50 02             	lea    0x2(%eax),%edx
  104163:	8b 45 0c             	mov    0xc(%ebp),%eax
  104166:	c1 e8 04             	shr    $0x4,%eax
  104169:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  10416c:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  104170:	c1 e0 18             	shl    $0x18,%eax
  104173:	89 44 24 04          	mov    %eax,0x4(%esp)
  104177:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10417e:	e8 50 fd ff ff       	call   103ed3 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  104183:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  10418a:	00 
  10418b:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104192:	e8 3c fd ff ff       	call   103ed3 <lapicw>
	microdelay(200);
  104197:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10419e:	e8 74 ff ff ff       	call   104117 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  1041a3:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  1041aa:	00 
  1041ab:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1041b2:	e8 1c fd ff ff       	call   103ed3 <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  1041b7:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  1041be:	e8 54 ff ff ff       	call   104117 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  1041c3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  1041ca:	eb 40                	jmp    10420c <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  1041cc:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  1041d0:	c1 e0 18             	shl    $0x18,%eax
  1041d3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1041d7:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1041de:	e8 f0 fc ff ff       	call   103ed3 <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  1041e3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1041e6:	c1 e8 0c             	shr    $0xc,%eax
  1041e9:	80 cc 06             	or     $0x6,%ah
  1041ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  1041f0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1041f7:	e8 d7 fc ff ff       	call   103ed3 <lapicw>
		microdelay(200);
  1041fc:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  104203:	e8 0f ff ff ff       	call   104117 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  104208:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  10420c:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
  104210:	7e ba                	jle    1041cc <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  104212:	c9                   	leave  
  104213:	c3                   	ret    

00104214 <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  104214:	55                   	push   %ebp
  104215:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  104217:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  10421c:	8b 55 08             	mov    0x8(%ebp),%edx
  10421f:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  104221:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  104226:	8b 40 10             	mov    0x10(%eax),%eax
}
  104229:	5d                   	pop    %ebp
  10422a:	c3                   	ret    

0010422b <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  10422b:	55                   	push   %ebp
  10422c:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10422e:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  104233:	8b 55 08             	mov    0x8(%ebp),%edx
  104236:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  104238:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  10423d:	8b 55 0c             	mov    0xc(%ebp),%edx
  104240:	89 50 10             	mov    %edx,0x10(%eax)
}
  104243:	5d                   	pop    %ebp
  104244:	c3                   	ret    

00104245 <ioapic_init>:

void
ioapic_init(void)
{
  104245:	55                   	push   %ebp
  104246:	89 e5                	mov    %esp,%ebp
  104248:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  10424b:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  104250:	85 c0                	test   %eax,%eax
  104252:	0f 84 fd 00 00 00    	je     104355 <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  104258:	a1 e0 f3 30 00       	mov    0x30f3e0,%eax
  10425d:	85 c0                	test   %eax,%eax
  10425f:	75 0a                	jne    10426b <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  104261:	c7 05 e0 f3 30 00 00 	movl   $0xfec00000,0x30f3e0
  104268:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  10426b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104272:	e8 9d ff ff ff       	call   104214 <ioapic_read>
  104277:	c1 e8 10             	shr    $0x10,%eax
  10427a:	25 ff 00 00 00       	and    $0xff,%eax
  10427f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  104282:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104289:	e8 86 ff ff ff       	call   104214 <ioapic_read>
  10428e:	c1 e8 18             	shr    $0x18,%eax
  104291:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  104294:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104298:	75 2a                	jne    1042c4 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  10429a:	0f b6 05 dc f3 30 00 	movzbl 0x30f3dc,%eax
  1042a1:	0f b6 c0             	movzbl %al,%eax
  1042a4:	c1 e0 18             	shl    $0x18,%eax
  1042a7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1042ab:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1042b2:	e8 74 ff ff ff       	call   10422b <ioapic_write>
		id = ioapicid;
  1042b7:	0f b6 05 dc f3 30 00 	movzbl 0x30f3dc,%eax
  1042be:	0f b6 c0             	movzbl %al,%eax
  1042c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  1042c4:	0f b6 05 dc f3 30 00 	movzbl 0x30f3dc,%eax
  1042cb:	0f b6 c0             	movzbl %al,%eax
  1042ce:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1042d1:	74 31                	je     104304 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  1042d3:	0f b6 05 dc f3 30 00 	movzbl 0x30f3dc,%eax
  1042da:	0f b6 c0             	movzbl %al,%eax
  1042dd:	89 44 24 10          	mov    %eax,0x10(%esp)
  1042e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042e4:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1042e8:	c7 44 24 08 b4 60 10 	movl   $0x1060b4,0x8(%esp)
  1042ef:	00 
  1042f0:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  1042f7:	00 
  1042f8:	c7 04 24 d5 60 10 00 	movl   $0x1060d5,(%esp)
  1042ff:	e8 2a c2 ff ff       	call   10052e <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  104304:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  10430b:	eb 3e                	jmp    10434b <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  10430d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104310:	83 c0 20             	add    $0x20,%eax
  104313:	0d 00 00 01 00       	or     $0x10000,%eax
  104318:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10431b:	83 c2 08             	add    $0x8,%edx
  10431e:	01 d2                	add    %edx,%edx
  104320:	89 44 24 04          	mov    %eax,0x4(%esp)
  104324:	89 14 24             	mov    %edx,(%esp)
  104327:	e8 ff fe ff ff       	call   10422b <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  10432c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10432f:	83 c0 08             	add    $0x8,%eax
  104332:	01 c0                	add    %eax,%eax
  104334:	83 c0 01             	add    $0x1,%eax
  104337:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10433e:	00 
  10433f:	89 04 24             	mov    %eax,(%esp)
  104342:	e8 e4 fe ff ff       	call   10422b <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  104347:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  10434b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10434e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104351:	7e ba                	jle    10430d <ioapic_init+0xc8>
  104353:	eb 01                	jmp    104356 <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  104355:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  104356:	c9                   	leave  
  104357:	c3                   	ret    

00104358 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  104358:	55                   	push   %ebp
  104359:	89 e5                	mov    %esp,%ebp
  10435b:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  10435e:	a1 e4 f3 30 00       	mov    0x30f3e4,%eax
  104363:	85 c0                	test   %eax,%eax
  104365:	74 3a                	je     1043a1 <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  104367:	8b 45 08             	mov    0x8(%ebp),%eax
  10436a:	83 c0 20             	add    $0x20,%eax
  10436d:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  104370:	8b 55 08             	mov    0x8(%ebp),%edx
  104373:	83 c2 08             	add    $0x8,%edx
  104376:	01 d2                	add    %edx,%edx
  104378:	89 44 24 04          	mov    %eax,0x4(%esp)
  10437c:	89 14 24             	mov    %edx,(%esp)
  10437f:	e8 a7 fe ff ff       	call   10422b <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  104384:	8b 45 08             	mov    0x8(%ebp),%eax
  104387:	83 c0 08             	add    $0x8,%eax
  10438a:	01 c0                	add    %eax,%eax
  10438c:	83 c0 01             	add    $0x1,%eax
  10438f:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  104396:	ff 
  104397:	89 04 24             	mov    %eax,(%esp)
  10439a:	e8 8c fe ff ff       	call   10422b <ioapic_write>
  10439f:	eb 01                	jmp    1043a2 <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  1043a1:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  1043a2:	c9                   	leave  
  1043a3:	c3                   	ret    

001043a4 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  1043a4:	55                   	push   %ebp
  1043a5:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  1043a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1043aa:	8b 40 18             	mov    0x18(%eax),%eax
  1043ad:	83 e0 02             	and    $0x2,%eax
  1043b0:	85 c0                	test   %eax,%eax
  1043b2:	74 1c                	je     1043d0 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  1043b4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1043b7:	8b 00                	mov    (%eax),%eax
  1043b9:	8d 50 08             	lea    0x8(%eax),%edx
  1043bc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1043bf:	89 10                	mov    %edx,(%eax)
  1043c1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1043c4:	8b 00                	mov    (%eax),%eax
  1043c6:	83 e8 08             	sub    $0x8,%eax
  1043c9:	8b 50 04             	mov    0x4(%eax),%edx
  1043cc:	8b 00                	mov    (%eax),%eax
  1043ce:	eb 47                	jmp    104417 <getuint+0x73>
	else if (st->flags & F_L)
  1043d0:	8b 45 08             	mov    0x8(%ebp),%eax
  1043d3:	8b 40 18             	mov    0x18(%eax),%eax
  1043d6:	83 e0 01             	and    $0x1,%eax
  1043d9:	84 c0                	test   %al,%al
  1043db:	74 1e                	je     1043fb <getuint+0x57>
		return va_arg(*ap, unsigned long);
  1043dd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1043e0:	8b 00                	mov    (%eax),%eax
  1043e2:	8d 50 04             	lea    0x4(%eax),%edx
  1043e5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1043e8:	89 10                	mov    %edx,(%eax)
  1043ea:	8b 45 0c             	mov    0xc(%ebp),%eax
  1043ed:	8b 00                	mov    (%eax),%eax
  1043ef:	83 e8 04             	sub    $0x4,%eax
  1043f2:	8b 00                	mov    (%eax),%eax
  1043f4:	ba 00 00 00 00       	mov    $0x0,%edx
  1043f9:	eb 1c                	jmp    104417 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  1043fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1043fe:	8b 00                	mov    (%eax),%eax
  104400:	8d 50 04             	lea    0x4(%eax),%edx
  104403:	8b 45 0c             	mov    0xc(%ebp),%eax
  104406:	89 10                	mov    %edx,(%eax)
  104408:	8b 45 0c             	mov    0xc(%ebp),%eax
  10440b:	8b 00                	mov    (%eax),%eax
  10440d:	83 e8 04             	sub    $0x4,%eax
  104410:	8b 00                	mov    (%eax),%eax
  104412:	ba 00 00 00 00       	mov    $0x0,%edx
}
  104417:	5d                   	pop    %ebp
  104418:	c3                   	ret    

00104419 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  104419:	55                   	push   %ebp
  10441a:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  10441c:	8b 45 08             	mov    0x8(%ebp),%eax
  10441f:	8b 40 18             	mov    0x18(%eax),%eax
  104422:	83 e0 02             	and    $0x2,%eax
  104425:	85 c0                	test   %eax,%eax
  104427:	74 1c                	je     104445 <getint+0x2c>
		return va_arg(*ap, long long);
  104429:	8b 45 0c             	mov    0xc(%ebp),%eax
  10442c:	8b 00                	mov    (%eax),%eax
  10442e:	8d 50 08             	lea    0x8(%eax),%edx
  104431:	8b 45 0c             	mov    0xc(%ebp),%eax
  104434:	89 10                	mov    %edx,(%eax)
  104436:	8b 45 0c             	mov    0xc(%ebp),%eax
  104439:	8b 00                	mov    (%eax),%eax
  10443b:	83 e8 08             	sub    $0x8,%eax
  10443e:	8b 50 04             	mov    0x4(%eax),%edx
  104441:	8b 00                	mov    (%eax),%eax
  104443:	eb 47                	jmp    10448c <getint+0x73>
	else if (st->flags & F_L)
  104445:	8b 45 08             	mov    0x8(%ebp),%eax
  104448:	8b 40 18             	mov    0x18(%eax),%eax
  10444b:	83 e0 01             	and    $0x1,%eax
  10444e:	84 c0                	test   %al,%al
  104450:	74 1e                	je     104470 <getint+0x57>
		return va_arg(*ap, long);
  104452:	8b 45 0c             	mov    0xc(%ebp),%eax
  104455:	8b 00                	mov    (%eax),%eax
  104457:	8d 50 04             	lea    0x4(%eax),%edx
  10445a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10445d:	89 10                	mov    %edx,(%eax)
  10445f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104462:	8b 00                	mov    (%eax),%eax
  104464:	83 e8 04             	sub    $0x4,%eax
  104467:	8b 00                	mov    (%eax),%eax
  104469:	89 c2                	mov    %eax,%edx
  10446b:	c1 fa 1f             	sar    $0x1f,%edx
  10446e:	eb 1c                	jmp    10448c <getint+0x73>
	else
		return va_arg(*ap, int);
  104470:	8b 45 0c             	mov    0xc(%ebp),%eax
  104473:	8b 00                	mov    (%eax),%eax
  104475:	8d 50 04             	lea    0x4(%eax),%edx
  104478:	8b 45 0c             	mov    0xc(%ebp),%eax
  10447b:	89 10                	mov    %edx,(%eax)
  10447d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104480:	8b 00                	mov    (%eax),%eax
  104482:	83 e8 04             	sub    $0x4,%eax
  104485:	8b 00                	mov    (%eax),%eax
  104487:	89 c2                	mov    %eax,%edx
  104489:	c1 fa 1f             	sar    $0x1f,%edx
}
  10448c:	5d                   	pop    %ebp
  10448d:	c3                   	ret    

0010448e <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  10448e:	55                   	push   %ebp
  10448f:	89 e5                	mov    %esp,%ebp
  104491:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  104494:	eb 1a                	jmp    1044b0 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  104496:	8b 45 08             	mov    0x8(%ebp),%eax
  104499:	8b 08                	mov    (%eax),%ecx
  10449b:	8b 45 08             	mov    0x8(%ebp),%eax
  10449e:	8b 50 04             	mov    0x4(%eax),%edx
  1044a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1044a4:	8b 40 08             	mov    0x8(%eax),%eax
  1044a7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1044ab:	89 04 24             	mov    %eax,(%esp)
  1044ae:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  1044b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1044b3:	8b 40 0c             	mov    0xc(%eax),%eax
  1044b6:	8d 50 ff             	lea    -0x1(%eax),%edx
  1044b9:	8b 45 08             	mov    0x8(%ebp),%eax
  1044bc:	89 50 0c             	mov    %edx,0xc(%eax)
  1044bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1044c2:	8b 40 0c             	mov    0xc(%eax),%eax
  1044c5:	85 c0                	test   %eax,%eax
  1044c7:	79 cd                	jns    104496 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  1044c9:	c9                   	leave  
  1044ca:	c3                   	ret    

001044cb <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  1044cb:	55                   	push   %ebp
  1044cc:	89 e5                	mov    %esp,%ebp
  1044ce:	53                   	push   %ebx
  1044cf:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  1044d2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1044d6:	79 18                	jns    1044f0 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  1044d8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1044df:	00 
  1044e0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044e3:	89 04 24             	mov    %eax,(%esp)
  1044e6:	e8 e7 07 00 00       	call   104cd2 <strchr>
  1044eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1044ee:	eb 2c                	jmp    10451c <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  1044f0:	8b 45 10             	mov    0x10(%ebp),%eax
  1044f3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1044f7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1044fe:	00 
  1044ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  104502:	89 04 24             	mov    %eax,(%esp)
  104505:	e8 cc 09 00 00       	call   104ed6 <memchr>
  10450a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10450d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104511:	75 09                	jne    10451c <putstr+0x51>
		lim = str + maxlen;
  104513:	8b 45 10             	mov    0x10(%ebp),%eax
  104516:	03 45 0c             	add    0xc(%ebp),%eax
  104519:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  10451c:	8b 45 08             	mov    0x8(%ebp),%eax
  10451f:	8b 40 0c             	mov    0xc(%eax),%eax
  104522:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  104525:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104528:	89 cb                	mov    %ecx,%ebx
  10452a:	29 d3                	sub    %edx,%ebx
  10452c:	89 da                	mov    %ebx,%edx
  10452e:	8d 14 10             	lea    (%eax,%edx,1),%edx
  104531:	8b 45 08             	mov    0x8(%ebp),%eax
  104534:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  104537:	8b 45 08             	mov    0x8(%ebp),%eax
  10453a:	8b 40 18             	mov    0x18(%eax),%eax
  10453d:	83 e0 10             	and    $0x10,%eax
  104540:	85 c0                	test   %eax,%eax
  104542:	75 32                	jne    104576 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  104544:	8b 45 08             	mov    0x8(%ebp),%eax
  104547:	89 04 24             	mov    %eax,(%esp)
  10454a:	e8 3f ff ff ff       	call   10448e <putpad>
	while (str < lim) {
  10454f:	eb 25                	jmp    104576 <putstr+0xab>
		char ch = *str++;
  104551:	8b 45 0c             	mov    0xc(%ebp),%eax
  104554:	0f b6 00             	movzbl (%eax),%eax
  104557:	88 45 f7             	mov    %al,-0x9(%ebp)
  10455a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  10455e:	8b 45 08             	mov    0x8(%ebp),%eax
  104561:	8b 08                	mov    (%eax),%ecx
  104563:	8b 45 08             	mov    0x8(%ebp),%eax
  104566:	8b 50 04             	mov    0x4(%eax),%edx
  104569:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  10456d:	89 54 24 04          	mov    %edx,0x4(%esp)
  104571:	89 04 24             	mov    %eax,(%esp)
  104574:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  104576:	8b 45 0c             	mov    0xc(%ebp),%eax
  104579:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10457c:	72 d3                	jb     104551 <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  10457e:	8b 45 08             	mov    0x8(%ebp),%eax
  104581:	89 04 24             	mov    %eax,(%esp)
  104584:	e8 05 ff ff ff       	call   10448e <putpad>
}
  104589:	83 c4 24             	add    $0x24,%esp
  10458c:	5b                   	pop    %ebx
  10458d:	5d                   	pop    %ebp
  10458e:	c3                   	ret    

0010458f <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  10458f:	55                   	push   %ebp
  104590:	89 e5                	mov    %esp,%ebp
  104592:	53                   	push   %ebx
  104593:	83 ec 24             	sub    $0x24,%esp
  104596:	8b 45 10             	mov    0x10(%ebp),%eax
  104599:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10459c:	8b 45 14             	mov    0x14(%ebp),%eax
  10459f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  1045a2:	8b 45 08             	mov    0x8(%ebp),%eax
  1045a5:	8b 40 1c             	mov    0x1c(%eax),%eax
  1045a8:	89 c2                	mov    %eax,%edx
  1045aa:	c1 fa 1f             	sar    $0x1f,%edx
  1045ad:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  1045b0:	77 4e                	ja     104600 <genint+0x71>
  1045b2:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  1045b5:	72 05                	jb     1045bc <genint+0x2d>
  1045b7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1045ba:	77 44                	ja     104600 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  1045bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1045bf:	8b 40 1c             	mov    0x1c(%eax),%eax
  1045c2:	89 c2                	mov    %eax,%edx
  1045c4:	c1 fa 1f             	sar    $0x1f,%edx
  1045c7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1045cb:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1045cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1045d2:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1045d5:	89 04 24             	mov    %eax,(%esp)
  1045d8:	89 54 24 04          	mov    %edx,0x4(%esp)
  1045dc:	e8 2f 09 00 00       	call   104f10 <__udivdi3>
  1045e1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1045e5:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1045e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  1045f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1045f3:	89 04 24             	mov    %eax,(%esp)
  1045f6:	e8 94 ff ff ff       	call   10458f <genint>
  1045fb:	89 45 0c             	mov    %eax,0xc(%ebp)
  1045fe:	eb 1b                	jmp    10461b <genint+0x8c>
	else if (st->signc >= 0)
  104600:	8b 45 08             	mov    0x8(%ebp),%eax
  104603:	8b 40 14             	mov    0x14(%eax),%eax
  104606:	85 c0                	test   %eax,%eax
  104608:	78 11                	js     10461b <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  10460a:	8b 45 08             	mov    0x8(%ebp),%eax
  10460d:	8b 40 14             	mov    0x14(%eax),%eax
  104610:	89 c2                	mov    %eax,%edx
  104612:	8b 45 0c             	mov    0xc(%ebp),%eax
  104615:	88 10                	mov    %dl,(%eax)
  104617:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  10461b:	8b 45 08             	mov    0x8(%ebp),%eax
  10461e:	8b 40 1c             	mov    0x1c(%eax),%eax
  104621:	89 c1                	mov    %eax,%ecx
  104623:	89 c3                	mov    %eax,%ebx
  104625:	c1 fb 1f             	sar    $0x1f,%ebx
  104628:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10462b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10462e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  104632:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  104636:	89 04 24             	mov    %eax,(%esp)
  104639:	89 54 24 04          	mov    %edx,0x4(%esp)
  10463d:	e8 fe 09 00 00       	call   105040 <__umoddi3>
  104642:	05 e4 60 10 00       	add    $0x1060e4,%eax
  104647:	0f b6 10             	movzbl (%eax),%edx
  10464a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10464d:	88 10                	mov    %dl,(%eax)
  10464f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  104653:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  104656:	83 c4 24             	add    $0x24,%esp
  104659:	5b                   	pop    %ebx
  10465a:	5d                   	pop    %ebp
  10465b:	c3                   	ret    

0010465c <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  10465c:	55                   	push   %ebp
  10465d:	89 e5                	mov    %esp,%ebp
  10465f:	83 ec 58             	sub    $0x58,%esp
  104662:	8b 45 0c             	mov    0xc(%ebp),%eax
  104665:	89 45 c0             	mov    %eax,-0x40(%ebp)
  104668:	8b 45 10             	mov    0x10(%ebp),%eax
  10466b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  10466e:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104671:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  104674:	8b 45 08             	mov    0x8(%ebp),%eax
  104677:	8b 55 14             	mov    0x14(%ebp),%edx
  10467a:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  10467d:	8b 45 c0             	mov    -0x40(%ebp),%eax
  104680:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104683:	89 44 24 08          	mov    %eax,0x8(%esp)
  104687:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10468b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10468e:	89 44 24 04          	mov    %eax,0x4(%esp)
  104692:	8b 45 08             	mov    0x8(%ebp),%eax
  104695:	89 04 24             	mov    %eax,(%esp)
  104698:	e8 f2 fe ff ff       	call   10458f <genint>
  10469d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  1046a0:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1046a3:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1046a6:	89 d1                	mov    %edx,%ecx
  1046a8:	29 c1                	sub    %eax,%ecx
  1046aa:	89 c8                	mov    %ecx,%eax
  1046ac:	89 44 24 08          	mov    %eax,0x8(%esp)
  1046b0:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1046b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1046b7:	8b 45 08             	mov    0x8(%ebp),%eax
  1046ba:	89 04 24             	mov    %eax,(%esp)
  1046bd:	e8 09 fe ff ff       	call   1044cb <putstr>
}
  1046c2:	c9                   	leave  
  1046c3:	c3                   	ret    

001046c4 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  1046c4:	55                   	push   %ebp
  1046c5:	89 e5                	mov    %esp,%ebp
  1046c7:	53                   	push   %ebx
  1046c8:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  1046cb:	8d 55 c8             	lea    -0x38(%ebp),%edx
  1046ce:	b9 00 00 00 00       	mov    $0x0,%ecx
  1046d3:	b8 20 00 00 00       	mov    $0x20,%eax
  1046d8:	89 c3                	mov    %eax,%ebx
  1046da:	83 e3 fc             	and    $0xfffffffc,%ebx
  1046dd:	b8 00 00 00 00       	mov    $0x0,%eax
  1046e2:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  1046e5:	83 c0 04             	add    $0x4,%eax
  1046e8:	39 d8                	cmp    %ebx,%eax
  1046ea:	72 f6                	jb     1046e2 <vprintfmt+0x1e>
  1046ec:	01 c2                	add    %eax,%edx
  1046ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1046f1:	89 45 c8             	mov    %eax,-0x38(%ebp)
  1046f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1046f7:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1046fa:	eb 17                	jmp    104713 <vprintfmt+0x4f>
			if (ch == '\0')
  1046fc:	85 db                	test   %ebx,%ebx
  1046fe:	0f 84 52 03 00 00    	je     104a56 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  104704:	8b 45 0c             	mov    0xc(%ebp),%eax
  104707:	89 44 24 04          	mov    %eax,0x4(%esp)
  10470b:	89 1c 24             	mov    %ebx,(%esp)
  10470e:	8b 45 08             	mov    0x8(%ebp),%eax
  104711:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104713:	8b 45 10             	mov    0x10(%ebp),%eax
  104716:	0f b6 00             	movzbl (%eax),%eax
  104719:	0f b6 d8             	movzbl %al,%ebx
  10471c:	83 fb 25             	cmp    $0x25,%ebx
  10471f:	0f 95 c0             	setne  %al
  104722:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104726:	84 c0                	test   %al,%al
  104728:	75 d2                	jne    1046fc <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  10472a:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  104731:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  104738:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  10473f:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  104746:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  10474d:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  104754:	eb 04                	jmp    10475a <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  104756:	90                   	nop
  104757:	eb 01                	jmp    10475a <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  104759:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  10475a:	8b 45 10             	mov    0x10(%ebp),%eax
  10475d:	0f b6 00             	movzbl (%eax),%eax
  104760:	0f b6 d8             	movzbl %al,%ebx
  104763:	89 d8                	mov    %ebx,%eax
  104765:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104769:	83 e8 20             	sub    $0x20,%eax
  10476c:	83 f8 58             	cmp    $0x58,%eax
  10476f:	0f 87 b1 02 00 00    	ja     104a26 <vprintfmt+0x362>
  104775:	8b 04 85 fc 60 10 00 	mov    0x1060fc(,%eax,4),%eax
  10477c:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  10477e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104781:	83 c8 10             	or     $0x10,%eax
  104784:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104787:	eb d1                	jmp    10475a <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  104789:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  104790:	eb c8                	jmp    10475a <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  104792:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104795:	85 c0                	test   %eax,%eax
  104797:	79 bd                	jns    104756 <vprintfmt+0x92>
				st.signc = ' ';
  104799:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  1047a0:	eb b8                	jmp    10475a <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  1047a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1047a5:	83 e0 08             	and    $0x8,%eax
  1047a8:	85 c0                	test   %eax,%eax
  1047aa:	75 07                	jne    1047b3 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  1047ac:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1047b3:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  1047ba:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1047bd:	89 d0                	mov    %edx,%eax
  1047bf:	c1 e0 02             	shl    $0x2,%eax
  1047c2:	01 d0                	add    %edx,%eax
  1047c4:	01 c0                	add    %eax,%eax
  1047c6:	01 d8                	add    %ebx,%eax
  1047c8:	83 e8 30             	sub    $0x30,%eax
  1047cb:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  1047ce:	8b 45 10             	mov    0x10(%ebp),%eax
  1047d1:	0f b6 00             	movzbl (%eax),%eax
  1047d4:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  1047d7:	83 fb 2f             	cmp    $0x2f,%ebx
  1047da:	7e 21                	jle    1047fd <vprintfmt+0x139>
  1047dc:	83 fb 39             	cmp    $0x39,%ebx
  1047df:	7f 1f                	jg     104800 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1047e1:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  1047e5:	eb d3                	jmp    1047ba <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  1047e7:	8b 45 14             	mov    0x14(%ebp),%eax
  1047ea:	83 c0 04             	add    $0x4,%eax
  1047ed:	89 45 14             	mov    %eax,0x14(%ebp)
  1047f0:	8b 45 14             	mov    0x14(%ebp),%eax
  1047f3:	83 e8 04             	sub    $0x4,%eax
  1047f6:	8b 00                	mov    (%eax),%eax
  1047f8:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1047fb:	eb 04                	jmp    104801 <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  1047fd:	90                   	nop
  1047fe:	eb 01                	jmp    104801 <vprintfmt+0x13d>
  104800:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  104801:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104804:	83 e0 08             	and    $0x8,%eax
  104807:	85 c0                	test   %eax,%eax
  104809:	0f 85 4a ff ff ff    	jne    104759 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  10480f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104812:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  104815:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  10481c:	e9 39 ff ff ff       	jmp    10475a <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  104821:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104824:	83 c8 08             	or     $0x8,%eax
  104827:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10482a:	e9 2b ff ff ff       	jmp    10475a <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  10482f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104832:	83 c8 04             	or     $0x4,%eax
  104835:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104838:	e9 1d ff ff ff       	jmp    10475a <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  10483d:	8b 55 e0             	mov    -0x20(%ebp),%edx
  104840:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104843:	83 e0 01             	and    $0x1,%eax
  104846:	84 c0                	test   %al,%al
  104848:	74 07                	je     104851 <vprintfmt+0x18d>
  10484a:	b8 02 00 00 00       	mov    $0x2,%eax
  10484f:	eb 05                	jmp    104856 <vprintfmt+0x192>
  104851:	b8 01 00 00 00       	mov    $0x1,%eax
  104856:	09 d0                	or     %edx,%eax
  104858:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10485b:	e9 fa fe ff ff       	jmp    10475a <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  104860:	8b 45 14             	mov    0x14(%ebp),%eax
  104863:	83 c0 04             	add    $0x4,%eax
  104866:	89 45 14             	mov    %eax,0x14(%ebp)
  104869:	8b 45 14             	mov    0x14(%ebp),%eax
  10486c:	83 e8 04             	sub    $0x4,%eax
  10486f:	8b 00                	mov    (%eax),%eax
  104871:	8b 55 0c             	mov    0xc(%ebp),%edx
  104874:	89 54 24 04          	mov    %edx,0x4(%esp)
  104878:	89 04 24             	mov    %eax,(%esp)
  10487b:	8b 45 08             	mov    0x8(%ebp),%eax
  10487e:	ff d0                	call   *%eax
			break;
  104880:	e9 cb 01 00 00       	jmp    104a50 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  104885:	8b 45 14             	mov    0x14(%ebp),%eax
  104888:	83 c0 04             	add    $0x4,%eax
  10488b:	89 45 14             	mov    %eax,0x14(%ebp)
  10488e:	8b 45 14             	mov    0x14(%ebp),%eax
  104891:	83 e8 04             	sub    $0x4,%eax
  104894:	8b 00                	mov    (%eax),%eax
  104896:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104899:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10489d:	75 07                	jne    1048a6 <vprintfmt+0x1e2>
				s = "(null)";
  10489f:	c7 45 f4 f5 60 10 00 	movl   $0x1060f5,-0xc(%ebp)
			putstr(&st, s, st.prec);
  1048a6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1048a9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1048ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1048b0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048b4:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1048b7:	89 04 24             	mov    %eax,(%esp)
  1048ba:	e8 0c fc ff ff       	call   1044cb <putstr>
			break;
  1048bf:	e9 8c 01 00 00       	jmp    104a50 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  1048c4:	8d 45 14             	lea    0x14(%ebp),%eax
  1048c7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048cb:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1048ce:	89 04 24             	mov    %eax,(%esp)
  1048d1:	e8 43 fb ff ff       	call   104419 <getint>
  1048d6:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1048d9:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  1048dc:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1048df:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1048e2:	85 d2                	test   %edx,%edx
  1048e4:	79 1a                	jns    104900 <vprintfmt+0x23c>
				num = -(intmax_t) num;
  1048e6:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1048e9:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1048ec:	f7 d8                	neg    %eax
  1048ee:	83 d2 00             	adc    $0x0,%edx
  1048f1:	f7 da                	neg    %edx
  1048f3:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1048f6:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  1048f9:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  104900:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104907:	00 
  104908:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10490b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10490e:	89 44 24 04          	mov    %eax,0x4(%esp)
  104912:	89 54 24 08          	mov    %edx,0x8(%esp)
  104916:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104919:	89 04 24             	mov    %eax,(%esp)
  10491c:	e8 3b fd ff ff       	call   10465c <putint>
			break;
  104921:	e9 2a 01 00 00       	jmp    104a50 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  104926:	8d 45 14             	lea    0x14(%ebp),%eax
  104929:	89 44 24 04          	mov    %eax,0x4(%esp)
  10492d:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104930:	89 04 24             	mov    %eax,(%esp)
  104933:	e8 6c fa ff ff       	call   1043a4 <getuint>
  104938:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10493f:	00 
  104940:	89 44 24 04          	mov    %eax,0x4(%esp)
  104944:	89 54 24 08          	mov    %edx,0x8(%esp)
  104948:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10494b:	89 04 24             	mov    %eax,(%esp)
  10494e:	e8 09 fd ff ff       	call   10465c <putint>
			break;
  104953:	e9 f8 00 00 00       	jmp    104a50 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  104958:	8d 45 14             	lea    0x14(%ebp),%eax
  10495b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10495f:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104962:	89 04 24             	mov    %eax,(%esp)
  104965:	e8 3a fa ff ff       	call   1043a4 <getuint>
  10496a:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  104971:	00 
  104972:	89 44 24 04          	mov    %eax,0x4(%esp)
  104976:	89 54 24 08          	mov    %edx,0x8(%esp)
  10497a:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10497d:	89 04 24             	mov    %eax,(%esp)
  104980:	e8 d7 fc ff ff       	call   10465c <putint>
			break;
  104985:	e9 c6 00 00 00       	jmp    104a50 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10498a:	8d 45 14             	lea    0x14(%ebp),%eax
  10498d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104991:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104994:	89 04 24             	mov    %eax,(%esp)
  104997:	e8 08 fa ff ff       	call   1043a4 <getuint>
  10499c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1049a3:	00 
  1049a4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049a8:	89 54 24 08          	mov    %edx,0x8(%esp)
  1049ac:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1049af:	89 04 24             	mov    %eax,(%esp)
  1049b2:	e8 a5 fc ff ff       	call   10465c <putint>
			break;
  1049b7:	e9 94 00 00 00       	jmp    104a50 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  1049bc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049bf:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049c3:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  1049ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1049cd:	ff d0                	call   *%eax
			putch('x', putdat);
  1049cf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049d6:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  1049dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1049e0:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  1049e2:	8b 45 14             	mov    0x14(%ebp),%eax
  1049e5:	83 c0 04             	add    $0x4,%eax
  1049e8:	89 45 14             	mov    %eax,0x14(%ebp)
  1049eb:	8b 45 14             	mov    0x14(%ebp),%eax
  1049ee:	83 e8 04             	sub    $0x4,%eax
  1049f1:	8b 00                	mov    (%eax),%eax
  1049f3:	ba 00 00 00 00       	mov    $0x0,%edx
  1049f8:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1049ff:	00 
  104a00:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a04:	89 54 24 08          	mov    %edx,0x8(%esp)
  104a08:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104a0b:	89 04 24             	mov    %eax,(%esp)
  104a0e:	e8 49 fc ff ff       	call   10465c <putint>
			break;
  104a13:	eb 3b                	jmp    104a50 <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  104a15:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a18:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a1c:	89 1c 24             	mov    %ebx,(%esp)
  104a1f:	8b 45 08             	mov    0x8(%ebp),%eax
  104a22:	ff d0                	call   *%eax
			break;
  104a24:	eb 2a                	jmp    104a50 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  104a26:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a29:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a2d:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  104a34:	8b 45 08             	mov    0x8(%ebp),%eax
  104a37:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  104a39:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104a3d:	eb 04                	jmp    104a43 <vprintfmt+0x37f>
  104a3f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104a43:	8b 45 10             	mov    0x10(%ebp),%eax
  104a46:	83 e8 01             	sub    $0x1,%eax
  104a49:	0f b6 00             	movzbl (%eax),%eax
  104a4c:	3c 25                	cmp    $0x25,%al
  104a4e:	75 ef                	jne    104a3f <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  104a50:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104a51:	e9 bd fc ff ff       	jmp    104713 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  104a56:	83 c4 44             	add    $0x44,%esp
  104a59:	5b                   	pop    %ebx
  104a5a:	5d                   	pop    %ebp
  104a5b:	c3                   	ret    

00104a5c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  104a5c:	55                   	push   %ebp
  104a5d:	89 e5                	mov    %esp,%ebp
  104a5f:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  104a62:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a65:	8b 00                	mov    (%eax),%eax
  104a67:	8b 55 08             	mov    0x8(%ebp),%edx
  104a6a:	89 d1                	mov    %edx,%ecx
  104a6c:	8b 55 0c             	mov    0xc(%ebp),%edx
  104a6f:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  104a73:	8d 50 01             	lea    0x1(%eax),%edx
  104a76:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a79:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  104a7b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a7e:	8b 00                	mov    (%eax),%eax
  104a80:	3d ff 00 00 00       	cmp    $0xff,%eax
  104a85:	75 24                	jne    104aab <putch+0x4f>
		b->buf[b->idx] = 0;
  104a87:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a8a:	8b 00                	mov    (%eax),%eax
  104a8c:	8b 55 0c             	mov    0xc(%ebp),%edx
  104a8f:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  104a94:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a97:	83 c0 08             	add    $0x8,%eax
  104a9a:	89 04 24             	mov    %eax,(%esp)
  104a9d:	e8 44 b9 ff ff       	call   1003e6 <cputs>
		b->idx = 0;
  104aa2:	8b 45 0c             	mov    0xc(%ebp),%eax
  104aa5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  104aab:	8b 45 0c             	mov    0xc(%ebp),%eax
  104aae:	8b 40 04             	mov    0x4(%eax),%eax
  104ab1:	8d 50 01             	lea    0x1(%eax),%edx
  104ab4:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ab7:	89 50 04             	mov    %edx,0x4(%eax)
}
  104aba:	c9                   	leave  
  104abb:	c3                   	ret    

00104abc <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  104abc:	55                   	push   %ebp
  104abd:	89 e5                	mov    %esp,%ebp
  104abf:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  104ac5:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  104acc:	00 00 00 
	b.cnt = 0;
  104acf:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  104ad6:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  104ad9:	b8 5c 4a 10 00       	mov    $0x104a5c,%eax
  104ade:	8b 55 0c             	mov    0xc(%ebp),%edx
  104ae1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104ae5:	8b 55 08             	mov    0x8(%ebp),%edx
  104ae8:	89 54 24 08          	mov    %edx,0x8(%esp)
  104aec:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  104af2:	89 54 24 04          	mov    %edx,0x4(%esp)
  104af6:	89 04 24             	mov    %eax,(%esp)
  104af9:	e8 c6 fb ff ff       	call   1046c4 <vprintfmt>

	b.buf[b.idx] = 0;
  104afe:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  104b04:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  104b0b:	00 
	cputs(b.buf);
  104b0c:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  104b12:	83 c0 08             	add    $0x8,%eax
  104b15:	89 04 24             	mov    %eax,(%esp)
  104b18:	e8 c9 b8 ff ff       	call   1003e6 <cputs>

	return b.cnt;
  104b1d:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  104b23:	c9                   	leave  
  104b24:	c3                   	ret    

00104b25 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  104b25:	55                   	push   %ebp
  104b26:	89 e5                	mov    %esp,%ebp
  104b28:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  104b2b:	8d 45 08             	lea    0x8(%ebp),%eax
  104b2e:	83 c0 04             	add    $0x4,%eax
  104b31:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  104b34:	8b 45 08             	mov    0x8(%ebp),%eax
  104b37:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104b3a:	89 54 24 04          	mov    %edx,0x4(%esp)
  104b3e:	89 04 24             	mov    %eax,(%esp)
  104b41:	e8 76 ff ff ff       	call   104abc <vcprintf>
  104b46:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  104b49:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  104b4c:	c9                   	leave  
  104b4d:	c3                   	ret    

00104b4e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  104b4e:	55                   	push   %ebp
  104b4f:	89 e5                	mov    %esp,%ebp
  104b51:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  104b54:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  104b5b:	eb 08                	jmp    104b65 <strlen+0x17>
		n++;
  104b5d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  104b61:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104b65:	8b 45 08             	mov    0x8(%ebp),%eax
  104b68:	0f b6 00             	movzbl (%eax),%eax
  104b6b:	84 c0                	test   %al,%al
  104b6d:	75 ee                	jne    104b5d <strlen+0xf>
		n++;
	return n;
  104b6f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104b72:	c9                   	leave  
  104b73:	c3                   	ret    

00104b74 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  104b74:	55                   	push   %ebp
  104b75:	89 e5                	mov    %esp,%ebp
  104b77:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  104b7a:	8b 45 08             	mov    0x8(%ebp),%eax
  104b7d:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  104b80:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b83:	0f b6 10             	movzbl (%eax),%edx
  104b86:	8b 45 08             	mov    0x8(%ebp),%eax
  104b89:	88 10                	mov    %dl,(%eax)
  104b8b:	8b 45 08             	mov    0x8(%ebp),%eax
  104b8e:	0f b6 00             	movzbl (%eax),%eax
  104b91:	84 c0                	test   %al,%al
  104b93:	0f 95 c0             	setne  %al
  104b96:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104b9a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  104b9e:	84 c0                	test   %al,%al
  104ba0:	75 de                	jne    104b80 <strcpy+0xc>
		/* do nothing */;
	return ret;
  104ba2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104ba5:	c9                   	leave  
  104ba6:	c3                   	ret    

00104ba7 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  104ba7:	55                   	push   %ebp
  104ba8:	89 e5                	mov    %esp,%ebp
  104baa:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  104bad:	8b 45 08             	mov    0x8(%ebp),%eax
  104bb0:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  104bb3:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  104bba:	eb 21                	jmp    104bdd <strncpy+0x36>
		*dst++ = *src;
  104bbc:	8b 45 0c             	mov    0xc(%ebp),%eax
  104bbf:	0f b6 10             	movzbl (%eax),%edx
  104bc2:	8b 45 08             	mov    0x8(%ebp),%eax
  104bc5:	88 10                	mov    %dl,(%eax)
  104bc7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  104bcb:	8b 45 0c             	mov    0xc(%ebp),%eax
  104bce:	0f b6 00             	movzbl (%eax),%eax
  104bd1:	84 c0                	test   %al,%al
  104bd3:	74 04                	je     104bd9 <strncpy+0x32>
			src++;
  104bd5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  104bd9:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  104bdd:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104be0:	3b 45 10             	cmp    0x10(%ebp),%eax
  104be3:	72 d7                	jb     104bbc <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  104be5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104be8:	c9                   	leave  
  104be9:	c3                   	ret    

00104bea <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  104bea:	55                   	push   %ebp
  104beb:	89 e5                	mov    %esp,%ebp
  104bed:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  104bf0:	8b 45 08             	mov    0x8(%ebp),%eax
  104bf3:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  104bf6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104bfa:	74 2f                	je     104c2b <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  104bfc:	eb 13                	jmp    104c11 <strlcpy+0x27>
			*dst++ = *src++;
  104bfe:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c01:	0f b6 10             	movzbl (%eax),%edx
  104c04:	8b 45 08             	mov    0x8(%ebp),%eax
  104c07:	88 10                	mov    %dl,(%eax)
  104c09:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104c0d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  104c11:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104c15:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104c19:	74 0a                	je     104c25 <strlcpy+0x3b>
  104c1b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c1e:	0f b6 00             	movzbl (%eax),%eax
  104c21:	84 c0                	test   %al,%al
  104c23:	75 d9                	jne    104bfe <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  104c25:	8b 45 08             	mov    0x8(%ebp),%eax
  104c28:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  104c2b:	8b 55 08             	mov    0x8(%ebp),%edx
  104c2e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104c31:	89 d1                	mov    %edx,%ecx
  104c33:	29 c1                	sub    %eax,%ecx
  104c35:	89 c8                	mov    %ecx,%eax
}
  104c37:	c9                   	leave  
  104c38:	c3                   	ret    

00104c39 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  104c39:	55                   	push   %ebp
  104c3a:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  104c3c:	eb 08                	jmp    104c46 <strcmp+0xd>
		p++, q++;
  104c3e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104c42:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  104c46:	8b 45 08             	mov    0x8(%ebp),%eax
  104c49:	0f b6 00             	movzbl (%eax),%eax
  104c4c:	84 c0                	test   %al,%al
  104c4e:	74 10                	je     104c60 <strcmp+0x27>
  104c50:	8b 45 08             	mov    0x8(%ebp),%eax
  104c53:	0f b6 10             	movzbl (%eax),%edx
  104c56:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c59:	0f b6 00             	movzbl (%eax),%eax
  104c5c:	38 c2                	cmp    %al,%dl
  104c5e:	74 de                	je     104c3e <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  104c60:	8b 45 08             	mov    0x8(%ebp),%eax
  104c63:	0f b6 00             	movzbl (%eax),%eax
  104c66:	0f b6 d0             	movzbl %al,%edx
  104c69:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c6c:	0f b6 00             	movzbl (%eax),%eax
  104c6f:	0f b6 c0             	movzbl %al,%eax
  104c72:	89 d1                	mov    %edx,%ecx
  104c74:	29 c1                	sub    %eax,%ecx
  104c76:	89 c8                	mov    %ecx,%eax
}
  104c78:	5d                   	pop    %ebp
  104c79:	c3                   	ret    

00104c7a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  104c7a:	55                   	push   %ebp
  104c7b:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  104c7d:	eb 0c                	jmp    104c8b <strncmp+0x11>
		n--, p++, q++;
  104c7f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104c83:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104c87:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  104c8b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104c8f:	74 1a                	je     104cab <strncmp+0x31>
  104c91:	8b 45 08             	mov    0x8(%ebp),%eax
  104c94:	0f b6 00             	movzbl (%eax),%eax
  104c97:	84 c0                	test   %al,%al
  104c99:	74 10                	je     104cab <strncmp+0x31>
  104c9b:	8b 45 08             	mov    0x8(%ebp),%eax
  104c9e:	0f b6 10             	movzbl (%eax),%edx
  104ca1:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ca4:	0f b6 00             	movzbl (%eax),%eax
  104ca7:	38 c2                	cmp    %al,%dl
  104ca9:	74 d4                	je     104c7f <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  104cab:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104caf:	75 07                	jne    104cb8 <strncmp+0x3e>
		return 0;
  104cb1:	b8 00 00 00 00       	mov    $0x0,%eax
  104cb6:	eb 18                	jmp    104cd0 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  104cb8:	8b 45 08             	mov    0x8(%ebp),%eax
  104cbb:	0f b6 00             	movzbl (%eax),%eax
  104cbe:	0f b6 d0             	movzbl %al,%edx
  104cc1:	8b 45 0c             	mov    0xc(%ebp),%eax
  104cc4:	0f b6 00             	movzbl (%eax),%eax
  104cc7:	0f b6 c0             	movzbl %al,%eax
  104cca:	89 d1                	mov    %edx,%ecx
  104ccc:	29 c1                	sub    %eax,%ecx
  104cce:	89 c8                	mov    %ecx,%eax
}
  104cd0:	5d                   	pop    %ebp
  104cd1:	c3                   	ret    

00104cd2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  104cd2:	55                   	push   %ebp
  104cd3:	89 e5                	mov    %esp,%ebp
  104cd5:	83 ec 04             	sub    $0x4,%esp
  104cd8:	8b 45 0c             	mov    0xc(%ebp),%eax
  104cdb:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  104cde:	eb 1a                	jmp    104cfa <strchr+0x28>
		if (*s++ == 0)
  104ce0:	8b 45 08             	mov    0x8(%ebp),%eax
  104ce3:	0f b6 00             	movzbl (%eax),%eax
  104ce6:	84 c0                	test   %al,%al
  104ce8:	0f 94 c0             	sete   %al
  104ceb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104cef:	84 c0                	test   %al,%al
  104cf1:	74 07                	je     104cfa <strchr+0x28>
			return NULL;
  104cf3:	b8 00 00 00 00       	mov    $0x0,%eax
  104cf8:	eb 0e                	jmp    104d08 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  104cfa:	8b 45 08             	mov    0x8(%ebp),%eax
  104cfd:	0f b6 00             	movzbl (%eax),%eax
  104d00:	3a 45 fc             	cmp    -0x4(%ebp),%al
  104d03:	75 db                	jne    104ce0 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  104d05:	8b 45 08             	mov    0x8(%ebp),%eax
}
  104d08:	c9                   	leave  
  104d09:	c3                   	ret    

00104d0a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  104d0a:	55                   	push   %ebp
  104d0b:	89 e5                	mov    %esp,%ebp
  104d0d:	57                   	push   %edi
  104d0e:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  104d11:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104d15:	75 05                	jne    104d1c <memset+0x12>
		return v;
  104d17:	8b 45 08             	mov    0x8(%ebp),%eax
  104d1a:	eb 5c                	jmp    104d78 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  104d1c:	8b 45 08             	mov    0x8(%ebp),%eax
  104d1f:	83 e0 03             	and    $0x3,%eax
  104d22:	85 c0                	test   %eax,%eax
  104d24:	75 41                	jne    104d67 <memset+0x5d>
  104d26:	8b 45 10             	mov    0x10(%ebp),%eax
  104d29:	83 e0 03             	and    $0x3,%eax
  104d2c:	85 c0                	test   %eax,%eax
  104d2e:	75 37                	jne    104d67 <memset+0x5d>
		c &= 0xFF;
  104d30:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  104d37:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d3a:	89 c2                	mov    %eax,%edx
  104d3c:	c1 e2 18             	shl    $0x18,%edx
  104d3f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d42:	c1 e0 10             	shl    $0x10,%eax
  104d45:	09 c2                	or     %eax,%edx
  104d47:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d4a:	c1 e0 08             	shl    $0x8,%eax
  104d4d:	09 d0                	or     %edx,%eax
  104d4f:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  104d52:	8b 45 10             	mov    0x10(%ebp),%eax
  104d55:	89 c1                	mov    %eax,%ecx
  104d57:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  104d5a:	8b 55 08             	mov    0x8(%ebp),%edx
  104d5d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d60:	89 d7                	mov    %edx,%edi
  104d62:	fc                   	cld    
  104d63:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  104d65:	eb 0e                	jmp    104d75 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  104d67:	8b 55 08             	mov    0x8(%ebp),%edx
  104d6a:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d6d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  104d70:	89 d7                	mov    %edx,%edi
  104d72:	fc                   	cld    
  104d73:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  104d75:	8b 45 08             	mov    0x8(%ebp),%eax
}
  104d78:	83 c4 10             	add    $0x10,%esp
  104d7b:	5f                   	pop    %edi
  104d7c:	5d                   	pop    %ebp
  104d7d:	c3                   	ret    

00104d7e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  104d7e:	55                   	push   %ebp
  104d7f:	89 e5                	mov    %esp,%ebp
  104d81:	57                   	push   %edi
  104d82:	56                   	push   %esi
  104d83:	53                   	push   %ebx
  104d84:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  104d87:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d8a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  104d8d:	8b 45 08             	mov    0x8(%ebp),%eax
  104d90:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  104d93:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104d96:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104d99:	73 6e                	jae    104e09 <memmove+0x8b>
  104d9b:	8b 45 10             	mov    0x10(%ebp),%eax
  104d9e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104da1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104da4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104da7:	76 60                	jbe    104e09 <memmove+0x8b>
		s += n;
  104da9:	8b 45 10             	mov    0x10(%ebp),%eax
  104dac:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  104daf:	8b 45 10             	mov    0x10(%ebp),%eax
  104db2:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  104db5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104db8:	83 e0 03             	and    $0x3,%eax
  104dbb:	85 c0                	test   %eax,%eax
  104dbd:	75 2f                	jne    104dee <memmove+0x70>
  104dbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104dc2:	83 e0 03             	and    $0x3,%eax
  104dc5:	85 c0                	test   %eax,%eax
  104dc7:	75 25                	jne    104dee <memmove+0x70>
  104dc9:	8b 45 10             	mov    0x10(%ebp),%eax
  104dcc:	83 e0 03             	and    $0x3,%eax
  104dcf:	85 c0                	test   %eax,%eax
  104dd1:	75 1b                	jne    104dee <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  104dd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104dd6:	83 e8 04             	sub    $0x4,%eax
  104dd9:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104ddc:	83 ea 04             	sub    $0x4,%edx
  104ddf:	8b 4d 10             	mov    0x10(%ebp),%ecx
  104de2:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  104de5:	89 c7                	mov    %eax,%edi
  104de7:	89 d6                	mov    %edx,%esi
  104de9:	fd                   	std    
  104dea:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  104dec:	eb 18                	jmp    104e06 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  104dee:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104df1:	8d 50 ff             	lea    -0x1(%eax),%edx
  104df4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104df7:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  104dfa:	8b 45 10             	mov    0x10(%ebp),%eax
  104dfd:	89 d7                	mov    %edx,%edi
  104dff:	89 de                	mov    %ebx,%esi
  104e01:	89 c1                	mov    %eax,%ecx
  104e03:	fd                   	std    
  104e04:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  104e06:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  104e07:	eb 45                	jmp    104e4e <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  104e09:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104e0c:	83 e0 03             	and    $0x3,%eax
  104e0f:	85 c0                	test   %eax,%eax
  104e11:	75 2b                	jne    104e3e <memmove+0xc0>
  104e13:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104e16:	83 e0 03             	and    $0x3,%eax
  104e19:	85 c0                	test   %eax,%eax
  104e1b:	75 21                	jne    104e3e <memmove+0xc0>
  104e1d:	8b 45 10             	mov    0x10(%ebp),%eax
  104e20:	83 e0 03             	and    $0x3,%eax
  104e23:	85 c0                	test   %eax,%eax
  104e25:	75 17                	jne    104e3e <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  104e27:	8b 45 10             	mov    0x10(%ebp),%eax
  104e2a:	89 c1                	mov    %eax,%ecx
  104e2c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  104e2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104e32:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104e35:	89 c7                	mov    %eax,%edi
  104e37:	89 d6                	mov    %edx,%esi
  104e39:	fc                   	cld    
  104e3a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  104e3c:	eb 10                	jmp    104e4e <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  104e3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104e41:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104e44:	8b 4d 10             	mov    0x10(%ebp),%ecx
  104e47:	89 c7                	mov    %eax,%edi
  104e49:	89 d6                	mov    %edx,%esi
  104e4b:	fc                   	cld    
  104e4c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  104e4e:	8b 45 08             	mov    0x8(%ebp),%eax
}
  104e51:	83 c4 10             	add    $0x10,%esp
  104e54:	5b                   	pop    %ebx
  104e55:	5e                   	pop    %esi
  104e56:	5f                   	pop    %edi
  104e57:	5d                   	pop    %ebp
  104e58:	c3                   	ret    

00104e59 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  104e59:	55                   	push   %ebp
  104e5a:	89 e5                	mov    %esp,%ebp
  104e5c:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  104e5f:	8b 45 10             	mov    0x10(%ebp),%eax
  104e62:	89 44 24 08          	mov    %eax,0x8(%esp)
  104e66:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e69:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e6d:	8b 45 08             	mov    0x8(%ebp),%eax
  104e70:	89 04 24             	mov    %eax,(%esp)
  104e73:	e8 06 ff ff ff       	call   104d7e <memmove>
}
  104e78:	c9                   	leave  
  104e79:	c3                   	ret    

00104e7a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  104e7a:	55                   	push   %ebp
  104e7b:	89 e5                	mov    %esp,%ebp
  104e7d:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  104e80:	8b 45 08             	mov    0x8(%ebp),%eax
  104e83:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  104e86:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e89:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  104e8c:	eb 32                	jmp    104ec0 <memcmp+0x46>
		if (*s1 != *s2)
  104e8e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104e91:	0f b6 10             	movzbl (%eax),%edx
  104e94:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104e97:	0f b6 00             	movzbl (%eax),%eax
  104e9a:	38 c2                	cmp    %al,%dl
  104e9c:	74 1a                	je     104eb8 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  104e9e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104ea1:	0f b6 00             	movzbl (%eax),%eax
  104ea4:	0f b6 d0             	movzbl %al,%edx
  104ea7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104eaa:	0f b6 00             	movzbl (%eax),%eax
  104ead:	0f b6 c0             	movzbl %al,%eax
  104eb0:	89 d1                	mov    %edx,%ecx
  104eb2:	29 c1                	sub    %eax,%ecx
  104eb4:	89 c8                	mov    %ecx,%eax
  104eb6:	eb 1c                	jmp    104ed4 <memcmp+0x5a>
		s1++, s2++;
  104eb8:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  104ebc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  104ec0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104ec4:	0f 95 c0             	setne  %al
  104ec7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104ecb:	84 c0                	test   %al,%al
  104ecd:	75 bf                	jne    104e8e <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  104ecf:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104ed4:	c9                   	leave  
  104ed5:	c3                   	ret    

00104ed6 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  104ed6:	55                   	push   %ebp
  104ed7:	89 e5                	mov    %esp,%ebp
  104ed9:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  104edc:	8b 45 10             	mov    0x10(%ebp),%eax
  104edf:	8b 55 08             	mov    0x8(%ebp),%edx
  104ee2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104ee5:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  104ee8:	eb 16                	jmp    104f00 <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  104eea:	8b 45 08             	mov    0x8(%ebp),%eax
  104eed:	0f b6 10             	movzbl (%eax),%edx
  104ef0:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ef3:	38 c2                	cmp    %al,%dl
  104ef5:	75 05                	jne    104efc <memchr+0x26>
			return (void *) s;
  104ef7:	8b 45 08             	mov    0x8(%ebp),%eax
  104efa:	eb 11                	jmp    104f0d <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  104efc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104f00:	8b 45 08             	mov    0x8(%ebp),%eax
  104f03:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  104f06:	72 e2                	jb     104eea <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  104f08:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104f0d:	c9                   	leave  
  104f0e:	c3                   	ret    
  104f0f:	90                   	nop

00104f10 <__udivdi3>:
  104f10:	55                   	push   %ebp
  104f11:	89 e5                	mov    %esp,%ebp
  104f13:	57                   	push   %edi
  104f14:	56                   	push   %esi
  104f15:	83 ec 10             	sub    $0x10,%esp
  104f18:	8b 45 14             	mov    0x14(%ebp),%eax
  104f1b:	8b 55 08             	mov    0x8(%ebp),%edx
  104f1e:	8b 75 10             	mov    0x10(%ebp),%esi
  104f21:	8b 7d 0c             	mov    0xc(%ebp),%edi
  104f24:	85 c0                	test   %eax,%eax
  104f26:	89 55 f0             	mov    %edx,-0x10(%ebp)
  104f29:	75 35                	jne    104f60 <__udivdi3+0x50>
  104f2b:	39 fe                	cmp    %edi,%esi
  104f2d:	77 61                	ja     104f90 <__udivdi3+0x80>
  104f2f:	85 f6                	test   %esi,%esi
  104f31:	75 0b                	jne    104f3e <__udivdi3+0x2e>
  104f33:	b8 01 00 00 00       	mov    $0x1,%eax
  104f38:	31 d2                	xor    %edx,%edx
  104f3a:	f7 f6                	div    %esi
  104f3c:	89 c6                	mov    %eax,%esi
  104f3e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  104f41:	31 d2                	xor    %edx,%edx
  104f43:	89 f8                	mov    %edi,%eax
  104f45:	f7 f6                	div    %esi
  104f47:	89 c7                	mov    %eax,%edi
  104f49:	89 c8                	mov    %ecx,%eax
  104f4b:	f7 f6                	div    %esi
  104f4d:	89 c1                	mov    %eax,%ecx
  104f4f:	89 fa                	mov    %edi,%edx
  104f51:	89 c8                	mov    %ecx,%eax
  104f53:	83 c4 10             	add    $0x10,%esp
  104f56:	5e                   	pop    %esi
  104f57:	5f                   	pop    %edi
  104f58:	5d                   	pop    %ebp
  104f59:	c3                   	ret    
  104f5a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104f60:	39 f8                	cmp    %edi,%eax
  104f62:	77 1c                	ja     104f80 <__udivdi3+0x70>
  104f64:	0f bd d0             	bsr    %eax,%edx
  104f67:	83 f2 1f             	xor    $0x1f,%edx
  104f6a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  104f6d:	75 39                	jne    104fa8 <__udivdi3+0x98>
  104f6f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  104f72:	0f 86 a0 00 00 00    	jbe    105018 <__udivdi3+0x108>
  104f78:	39 f8                	cmp    %edi,%eax
  104f7a:	0f 82 98 00 00 00    	jb     105018 <__udivdi3+0x108>
  104f80:	31 ff                	xor    %edi,%edi
  104f82:	31 c9                	xor    %ecx,%ecx
  104f84:	89 c8                	mov    %ecx,%eax
  104f86:	89 fa                	mov    %edi,%edx
  104f88:	83 c4 10             	add    $0x10,%esp
  104f8b:	5e                   	pop    %esi
  104f8c:	5f                   	pop    %edi
  104f8d:	5d                   	pop    %ebp
  104f8e:	c3                   	ret    
  104f8f:	90                   	nop
  104f90:	89 d1                	mov    %edx,%ecx
  104f92:	89 fa                	mov    %edi,%edx
  104f94:	89 c8                	mov    %ecx,%eax
  104f96:	31 ff                	xor    %edi,%edi
  104f98:	f7 f6                	div    %esi
  104f9a:	89 c1                	mov    %eax,%ecx
  104f9c:	89 fa                	mov    %edi,%edx
  104f9e:	89 c8                	mov    %ecx,%eax
  104fa0:	83 c4 10             	add    $0x10,%esp
  104fa3:	5e                   	pop    %esi
  104fa4:	5f                   	pop    %edi
  104fa5:	5d                   	pop    %ebp
  104fa6:	c3                   	ret    
  104fa7:	90                   	nop
  104fa8:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  104fac:	89 f2                	mov    %esi,%edx
  104fae:	d3 e0                	shl    %cl,%eax
  104fb0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104fb3:	b8 20 00 00 00       	mov    $0x20,%eax
  104fb8:	2b 45 f4             	sub    -0xc(%ebp),%eax
  104fbb:	89 c1                	mov    %eax,%ecx
  104fbd:	d3 ea                	shr    %cl,%edx
  104fbf:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  104fc3:	0b 55 ec             	or     -0x14(%ebp),%edx
  104fc6:	d3 e6                	shl    %cl,%esi
  104fc8:	89 c1                	mov    %eax,%ecx
  104fca:	89 75 e8             	mov    %esi,-0x18(%ebp)
  104fcd:	89 fe                	mov    %edi,%esi
  104fcf:	d3 ee                	shr    %cl,%esi
  104fd1:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  104fd5:	89 55 ec             	mov    %edx,-0x14(%ebp)
  104fd8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104fdb:	d3 e7                	shl    %cl,%edi
  104fdd:	89 c1                	mov    %eax,%ecx
  104fdf:	d3 ea                	shr    %cl,%edx
  104fe1:	09 d7                	or     %edx,%edi
  104fe3:	89 f2                	mov    %esi,%edx
  104fe5:	89 f8                	mov    %edi,%eax
  104fe7:	f7 75 ec             	divl   -0x14(%ebp)
  104fea:	89 d6                	mov    %edx,%esi
  104fec:	89 c7                	mov    %eax,%edi
  104fee:	f7 65 e8             	mull   -0x18(%ebp)
  104ff1:	39 d6                	cmp    %edx,%esi
  104ff3:	89 55 ec             	mov    %edx,-0x14(%ebp)
  104ff6:	72 30                	jb     105028 <__udivdi3+0x118>
  104ff8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104ffb:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  104fff:	d3 e2                	shl    %cl,%edx
  105001:	39 c2                	cmp    %eax,%edx
  105003:	73 05                	jae    10500a <__udivdi3+0xfa>
  105005:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  105008:	74 1e                	je     105028 <__udivdi3+0x118>
  10500a:	89 f9                	mov    %edi,%ecx
  10500c:	31 ff                	xor    %edi,%edi
  10500e:	e9 71 ff ff ff       	jmp    104f84 <__udivdi3+0x74>
  105013:	90                   	nop
  105014:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105018:	31 ff                	xor    %edi,%edi
  10501a:	b9 01 00 00 00       	mov    $0x1,%ecx
  10501f:	e9 60 ff ff ff       	jmp    104f84 <__udivdi3+0x74>
  105024:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105028:	8d 4f ff             	lea    -0x1(%edi),%ecx
  10502b:	31 ff                	xor    %edi,%edi
  10502d:	89 c8                	mov    %ecx,%eax
  10502f:	89 fa                	mov    %edi,%edx
  105031:	83 c4 10             	add    $0x10,%esp
  105034:	5e                   	pop    %esi
  105035:	5f                   	pop    %edi
  105036:	5d                   	pop    %ebp
  105037:	c3                   	ret    
  105038:	66 90                	xchg   %ax,%ax
  10503a:	66 90                	xchg   %ax,%ax
  10503c:	66 90                	xchg   %ax,%ax
  10503e:	66 90                	xchg   %ax,%ax

00105040 <__umoddi3>:
  105040:	55                   	push   %ebp
  105041:	89 e5                	mov    %esp,%ebp
  105043:	57                   	push   %edi
  105044:	56                   	push   %esi
  105045:	83 ec 20             	sub    $0x20,%esp
  105048:	8b 55 14             	mov    0x14(%ebp),%edx
  10504b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10504e:	8b 7d 10             	mov    0x10(%ebp),%edi
  105051:	8b 75 0c             	mov    0xc(%ebp),%esi
  105054:	85 d2                	test   %edx,%edx
  105056:	89 c8                	mov    %ecx,%eax
  105058:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  10505b:	75 13                	jne    105070 <__umoddi3+0x30>
  10505d:	39 f7                	cmp    %esi,%edi
  10505f:	76 3f                	jbe    1050a0 <__umoddi3+0x60>
  105061:	89 f2                	mov    %esi,%edx
  105063:	f7 f7                	div    %edi
  105065:	89 d0                	mov    %edx,%eax
  105067:	31 d2                	xor    %edx,%edx
  105069:	83 c4 20             	add    $0x20,%esp
  10506c:	5e                   	pop    %esi
  10506d:	5f                   	pop    %edi
  10506e:	5d                   	pop    %ebp
  10506f:	c3                   	ret    
  105070:	39 f2                	cmp    %esi,%edx
  105072:	77 4c                	ja     1050c0 <__umoddi3+0x80>
  105074:	0f bd ca             	bsr    %edx,%ecx
  105077:	83 f1 1f             	xor    $0x1f,%ecx
  10507a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  10507d:	75 51                	jne    1050d0 <__umoddi3+0x90>
  10507f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  105082:	0f 87 e0 00 00 00    	ja     105168 <__umoddi3+0x128>
  105088:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10508b:	29 f8                	sub    %edi,%eax
  10508d:	19 d6                	sbb    %edx,%esi
  10508f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105092:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105095:	89 f2                	mov    %esi,%edx
  105097:	83 c4 20             	add    $0x20,%esp
  10509a:	5e                   	pop    %esi
  10509b:	5f                   	pop    %edi
  10509c:	5d                   	pop    %ebp
  10509d:	c3                   	ret    
  10509e:	66 90                	xchg   %ax,%ax
  1050a0:	85 ff                	test   %edi,%edi
  1050a2:	75 0b                	jne    1050af <__umoddi3+0x6f>
  1050a4:	b8 01 00 00 00       	mov    $0x1,%eax
  1050a9:	31 d2                	xor    %edx,%edx
  1050ab:	f7 f7                	div    %edi
  1050ad:	89 c7                	mov    %eax,%edi
  1050af:	89 f0                	mov    %esi,%eax
  1050b1:	31 d2                	xor    %edx,%edx
  1050b3:	f7 f7                	div    %edi
  1050b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1050b8:	f7 f7                	div    %edi
  1050ba:	eb a9                	jmp    105065 <__umoddi3+0x25>
  1050bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1050c0:	89 c8                	mov    %ecx,%eax
  1050c2:	89 f2                	mov    %esi,%edx
  1050c4:	83 c4 20             	add    $0x20,%esp
  1050c7:	5e                   	pop    %esi
  1050c8:	5f                   	pop    %edi
  1050c9:	5d                   	pop    %ebp
  1050ca:	c3                   	ret    
  1050cb:	90                   	nop
  1050cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1050d0:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1050d4:	d3 e2                	shl    %cl,%edx
  1050d6:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1050d9:	ba 20 00 00 00       	mov    $0x20,%edx
  1050de:	2b 55 f0             	sub    -0x10(%ebp),%edx
  1050e1:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1050e4:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1050e8:	89 fa                	mov    %edi,%edx
  1050ea:	d3 ea                	shr    %cl,%edx
  1050ec:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1050f0:	0b 55 f4             	or     -0xc(%ebp),%edx
  1050f3:	d3 e7                	shl    %cl,%edi
  1050f5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1050f9:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1050fc:	89 f2                	mov    %esi,%edx
  1050fe:	89 7d e8             	mov    %edi,-0x18(%ebp)
  105101:	89 c7                	mov    %eax,%edi
  105103:	d3 ea                	shr    %cl,%edx
  105105:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  105109:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10510c:	89 c2                	mov    %eax,%edx
  10510e:	d3 e6                	shl    %cl,%esi
  105110:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  105114:	d3 ea                	shr    %cl,%edx
  105116:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10511a:	09 d6                	or     %edx,%esi
  10511c:	89 f0                	mov    %esi,%eax
  10511e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  105121:	d3 e7                	shl    %cl,%edi
  105123:	89 f2                	mov    %esi,%edx
  105125:	f7 75 f4             	divl   -0xc(%ebp)
  105128:	89 d6                	mov    %edx,%esi
  10512a:	f7 65 e8             	mull   -0x18(%ebp)
  10512d:	39 d6                	cmp    %edx,%esi
  10512f:	72 2b                	jb     10515c <__umoddi3+0x11c>
  105131:	39 c7                	cmp    %eax,%edi
  105133:	72 23                	jb     105158 <__umoddi3+0x118>
  105135:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  105139:	29 c7                	sub    %eax,%edi
  10513b:	19 d6                	sbb    %edx,%esi
  10513d:	89 f0                	mov    %esi,%eax
  10513f:	89 f2                	mov    %esi,%edx
  105141:	d3 ef                	shr    %cl,%edi
  105143:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  105147:	d3 e0                	shl    %cl,%eax
  105149:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10514d:	09 f8                	or     %edi,%eax
  10514f:	d3 ea                	shr    %cl,%edx
  105151:	83 c4 20             	add    $0x20,%esp
  105154:	5e                   	pop    %esi
  105155:	5f                   	pop    %edi
  105156:	5d                   	pop    %ebp
  105157:	c3                   	ret    
  105158:	39 d6                	cmp    %edx,%esi
  10515a:	75 d9                	jne    105135 <__umoddi3+0xf5>
  10515c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  10515f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  105162:	eb d1                	jmp    105135 <__umoddi3+0xf5>
  105164:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105168:	39 f2                	cmp    %esi,%edx
  10516a:	0f 82 18 ff ff ff    	jb     105088 <__umoddi3+0x48>
  105170:	e9 1d ff ff ff       	jmp    105092 <__umoddi3+0x52>
