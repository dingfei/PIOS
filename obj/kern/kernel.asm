
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
  10001a:	bc 00 70 10 00       	mov    $0x107000,%esp

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
  100050:	c7 44 24 0c e0 4c 10 	movl   $0x104ce0,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 f6 4c 10 	movl   $0x104cf6,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 0b 4d 10 00 	movl   $0x104d0b,(%esp)
  10006f:	e8 bc 03 00 00       	call   100430 <debug_panic>
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
  100084:	3d 00 60 10 00       	cmp    $0x106000,%eax
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
  100094:	57                   	push   %edi
  100095:	53                   	push   %ebx
  100096:	83 ec 60             	sub    $0x60,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  100099:	e8 db ff ff ff       	call   100079 <cpu_onboot>
  10009e:	85 c0                	test   %eax,%eax
  1000a0:	74 28                	je     1000ca <init+0x39>
		memset(edata, 0, end - edata);
  1000a2:	ba 2c da 30 00       	mov    $0x30da2c,%edx
  1000a7:	b8 1c 76 10 00       	mov    $0x10761c,%eax
  1000ac:	89 d1                	mov    %edx,%ecx
  1000ae:	29 c1                	sub    %eax,%ecx
  1000b0:	89 c8                	mov    %ecx,%eax
  1000b2:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bd:	00 
  1000be:	c7 04 24 1c 76 10 00 	movl   $0x10761c,(%esp)
  1000c5:	e8 a1 47 00 00       	call   10486b <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000ca:	e8 74 02 00 00       	call   100343 <cons_init>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000cf:	e8 df 0f 00 00       	call   1010b3 <cpu_init>
	trap_init();
  1000d4:	e8 2b 14 00 00       	call   101504 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000d9:	e8 0c 08 00 00       	call   1008ea <mem_init>

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  1000de:	e8 96 ff ff ff       	call   100079 <cpu_onboot>
  1000e3:	85 c0                	test   %eax,%eax
  1000e5:	74 05                	je     1000ec <init+0x5b>
		spinlock_check();
  1000e7:	e8 9a 20 00 00       	call   102186 <spinlock_check>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000ec:	e8 26 1d 00 00       	call   101e17 <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000f1:	e8 7d 36 00 00       	call   103773 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000f6:	e8 ab 3c 00 00       	call   103da6 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000fb:	e8 56 39 00 00       	call   103a56 <lapic_init>
	cpu_bootothers();	// Get other processors started
  100100:	e8 7d 11 00 00       	call   101282 <cpu_bootothers>
//	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
//		cpu_onboot() ? "BP" : "AP");

	// Initialize the process management code.
	proc_init();
  100105:	e8 4a 26 00 00       	call   102754 <proc_init>

	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.

	cprintf("before tt\n");
  10010a:	c7 04 24 18 4d 10 00 	movl   $0x104d18,(%esp)
  100111:	e8 70 45 00 00       	call   104686 <cprintf>
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
	};
  100116:	8d 5d ac             	lea    -0x54(%ebp),%ebx
  100119:	b8 00 00 00 00       	mov    $0x0,%eax
  10011e:	ba 13 00 00 00       	mov    $0x13,%edx
  100123:	89 df                	mov    %ebx,%edi
  100125:	89 d1                	mov    %edx,%ecx
  100127:	f3 ab                	rep stos %eax,%es:(%edi)
  100129:	66 c7 45 cc 23 00    	movw   $0x23,-0x34(%ebp)
  10012f:	66 c7 45 d0 23 00    	movw   $0x23,-0x30(%ebp)
  100135:	66 c7 45 d4 23 00    	movw   $0x23,-0x2c(%ebp)
  10013b:	66 c7 45 d8 23 00    	movw   $0x23,-0x28(%ebp)

	cprintf("before tt\n");

	trapframe tt = {
		cs: CPU_GDT_UCODE | 3,
		eip: (uint32_t)(user),
  100141:	b8 6f 01 10 00       	mov    $0x10016f,%eax
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
	};
  100146:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100149:	66 c7 45 e8 1b 00    	movw   $0x1b,-0x18(%ebp)
  10014f:	c7 45 ec 00 30 00 00 	movl   $0x3000,-0x14(%ebp)
		fs: CPU_GDT_UDATA | 3,
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
  100156:	b8 20 86 10 00       	mov    $0x108620,%eax
	};
  10015b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10015e:	66 c7 45 f4 23 00    	movw   $0x23,-0xc(%ebp)
	
	trap_return(&tt);
  100164:	8d 45 ac             	lea    -0x54(%ebp),%eax
  100167:	89 04 24             	mov    %eax,(%esp)
  10016a:	e8 11 6f 00 00       	call   107080 <trap_return>

0010016f <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  10016f:	55                   	push   %ebp
  100170:	89 e5                	mov    %esp,%ebp
  100172:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  100175:	c7 04 24 23 4d 10 00 	movl   $0x104d23,(%esp)
  10017c:	e8 05 45 00 00       	call   104686 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100181:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  100184:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  100187:	89 c2                	mov    %eax,%edx
  100189:	b8 20 76 10 00       	mov    $0x107620,%eax
  10018e:	39 c2                	cmp    %eax,%edx
  100190:	77 24                	ja     1001b6 <user+0x47>
  100192:	c7 44 24 0c 30 4d 10 	movl   $0x104d30,0xc(%esp)
  100199:	00 
  10019a:	c7 44 24 08 f6 4c 10 	movl   $0x104cf6,0x8(%esp)
  1001a1:	00 
  1001a2:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  1001a9:	00 
  1001aa:	c7 04 24 57 4d 10 00 	movl   $0x104d57,(%esp)
  1001b1:	e8 7a 02 00 00       	call   100430 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001b6:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1001b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  1001bc:	89 c2                	mov    %eax,%edx
  1001be:	b8 20 86 10 00       	mov    $0x108620,%eax
  1001c3:	39 c2                	cmp    %eax,%edx
  1001c5:	72 24                	jb     1001eb <user+0x7c>
  1001c7:	c7 44 24 0c 64 4d 10 	movl   $0x104d64,0xc(%esp)
  1001ce:	00 
  1001cf:	c7 44 24 08 f6 4c 10 	movl   $0x104cf6,0x8(%esp)
  1001d6:	00 
  1001d7:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  1001de:	00 
  1001df:	c7 04 24 57 4d 10 00 	movl   $0x104d57,(%esp)
  1001e6:	e8 45 02 00 00       	call   100430 <debug_panic>

	// Check the system call and process scheduling code.
	proc_check();
  1001eb:	e8 c5 27 00 00       	call   1029b5 <proc_check>

	done();
  1001f0:	e8 00 00 00 00       	call   1001f5 <done>

001001f5 <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  1001f5:	55                   	push   %ebp
  1001f6:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  1001f8:	eb fe                	jmp    1001f8 <done+0x3>

001001fa <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1001fa:	55                   	push   %ebp
  1001fb:	89 e5                	mov    %esp,%ebp
  1001fd:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100200:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100203:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100206:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100209:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10020c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100211:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100214:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100217:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10021d:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100222:	74 24                	je     100248 <cpu_cur+0x4e>
  100224:	c7 44 24 0c 9c 4d 10 	movl   $0x104d9c,0xc(%esp)
  10022b:	00 
  10022c:	c7 44 24 08 b2 4d 10 	movl   $0x104db2,0x8(%esp)
  100233:	00 
  100234:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10023b:	00 
  10023c:	c7 04 24 c7 4d 10 00 	movl   $0x104dc7,(%esp)
  100243:	e8 e8 01 00 00       	call   100430 <debug_panic>
	return c;
  100248:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10024b:	c9                   	leave  
  10024c:	c3                   	ret    

0010024d <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10024d:	55                   	push   %ebp
  10024e:	89 e5                	mov    %esp,%ebp
  100250:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100253:	e8 a2 ff ff ff       	call   1001fa <cpu_cur>
  100258:	3d 00 60 10 00       	cmp    $0x106000,%eax
  10025d:	0f 94 c0             	sete   %al
  100260:	0f b6 c0             	movzbl %al,%eax
}
  100263:	c9                   	leave  
  100264:	c3                   	ret    

00100265 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  100265:	55                   	push   %ebp
  100266:	89 e5                	mov    %esp,%ebp
  100268:	83 ec 28             	sub    $0x28,%esp
	int c;

	spinlock_acquire(&cons_lock);
  10026b:	c7 04 24 c0 d2 10 00 	movl   $0x10d2c0,(%esp)
  100272:	e8 cc 1d 00 00       	call   102043 <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  100277:	eb 35                	jmp    1002ae <cons_intr+0x49>
		if (c == 0)
  100279:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10027d:	74 2e                	je     1002ad <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  10027f:	a1 24 88 10 00       	mov    0x108824,%eax
  100284:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100287:	88 90 20 86 10 00    	mov    %dl,0x108620(%eax)
  10028d:	83 c0 01             	add    $0x1,%eax
  100290:	a3 24 88 10 00       	mov    %eax,0x108824
		if (cons.wpos == CONSBUFSIZE)
  100295:	a1 24 88 10 00       	mov    0x108824,%eax
  10029a:	3d 00 02 00 00       	cmp    $0x200,%eax
  10029f:	75 0d                	jne    1002ae <cons_intr+0x49>
			cons.wpos = 0;
  1002a1:	c7 05 24 88 10 00 00 	movl   $0x0,0x108824
  1002a8:	00 00 00 
  1002ab:	eb 01                	jmp    1002ae <cons_intr+0x49>
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  1002ad:	90                   	nop
cons_intr(int (*proc)(void))
{
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
  1002ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1002b1:	ff d0                	call   *%eax
  1002b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1002b6:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  1002ba:	75 bd                	jne    100279 <cons_intr+0x14>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
	spinlock_release(&cons_lock);
  1002bc:	c7 04 24 c0 d2 10 00 	movl   $0x10d2c0,(%esp)
  1002c3:	e8 f7 1d 00 00       	call   1020bf <spinlock_release>

}
  1002c8:	c9                   	leave  
  1002c9:	c3                   	ret    

001002ca <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  1002ca:	55                   	push   %ebp
  1002cb:	89 e5                	mov    %esp,%ebp
  1002cd:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  1002d0:	e8 4e 33 00 00       	call   103623 <serial_intr>
	kbd_intr();
  1002d5:	e8 a4 32 00 00       	call   10357e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  1002da:	8b 15 20 88 10 00    	mov    0x108820,%edx
  1002e0:	a1 24 88 10 00       	mov    0x108824,%eax
  1002e5:	39 c2                	cmp    %eax,%edx
  1002e7:	74 35                	je     10031e <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  1002e9:	a1 20 88 10 00       	mov    0x108820,%eax
  1002ee:	0f b6 90 20 86 10 00 	movzbl 0x108620(%eax),%edx
  1002f5:	0f b6 d2             	movzbl %dl,%edx
  1002f8:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1002fb:	83 c0 01             	add    $0x1,%eax
  1002fe:	a3 20 88 10 00       	mov    %eax,0x108820
		if (cons.rpos == CONSBUFSIZE)
  100303:	a1 20 88 10 00       	mov    0x108820,%eax
  100308:	3d 00 02 00 00       	cmp    $0x200,%eax
  10030d:	75 0a                	jne    100319 <cons_getc+0x4f>
			cons.rpos = 0;
  10030f:	c7 05 20 88 10 00 00 	movl   $0x0,0x108820
  100316:	00 00 00 
		return c;
  100319:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10031c:	eb 05                	jmp    100323 <cons_getc+0x59>
	}
	return 0;
  10031e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100323:	c9                   	leave  
  100324:	c3                   	ret    

00100325 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  100325:	55                   	push   %ebp
  100326:	89 e5                	mov    %esp,%ebp
  100328:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  10032b:	8b 45 08             	mov    0x8(%ebp),%eax
  10032e:	89 04 24             	mov    %eax,(%esp)
  100331:	e8 0a 33 00 00       	call   103640 <serial_putc>
	video_putc(c);
  100336:	8b 45 08             	mov    0x8(%ebp),%eax
  100339:	89 04 24             	mov    %eax,(%esp)
  10033c:	e8 9c 2e 00 00       	call   1031dd <video_putc>
}
  100341:	c9                   	leave  
  100342:	c3                   	ret    

00100343 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100343:	55                   	push   %ebp
  100344:	89 e5                	mov    %esp,%ebp
  100346:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100349:	e8 ff fe ff ff       	call   10024d <cpu_onboot>
  10034e:	85 c0                	test   %eax,%eax
  100350:	74 52                	je     1003a4 <cons_init+0x61>
		return;

	spinlock_init(&cons_lock);
  100352:	c7 44 24 08 6a 00 00 	movl   $0x6a,0x8(%esp)
  100359:	00 
  10035a:	c7 44 24 04 d4 4d 10 	movl   $0x104dd4,0x4(%esp)
  100361:	00 
  100362:	c7 04 24 c0 d2 10 00 	movl   $0x10d2c0,(%esp)
  100369:	e8 a1 1c 00 00       	call   10200f <spinlock_init_>
	video_init();
  10036e:	e8 9e 2d 00 00       	call   103111 <video_init>
	kbd_init();
  100373:	e8 1a 32 00 00       	call   103592 <kbd_init>
	serial_init();
  100378:	e8 28 33 00 00       	call   1036a5 <serial_init>

	if (!serial_exists)
  10037d:	a1 24 da 30 00       	mov    0x30da24,%eax
  100382:	85 c0                	test   %eax,%eax
  100384:	75 1f                	jne    1003a5 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  100386:	c7 44 24 08 e0 4d 10 	movl   $0x104de0,0x8(%esp)
  10038d:	00 
  10038e:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  100395:	00 
  100396:	c7 04 24 d4 4d 10 00 	movl   $0x104dd4,(%esp)
  10039d:	e8 4d 01 00 00       	call   1004ef <debug_warn>
  1003a2:	eb 01                	jmp    1003a5 <cons_init+0x62>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  1003a4:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  1003a5:	c9                   	leave  
  1003a6:	c3                   	ret    

001003a7 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  1003a7:	55                   	push   %ebp
  1003a8:	89 e5                	mov    %esp,%ebp
  1003aa:	53                   	push   %ebx
  1003ab:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1003ae:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  1003b1:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	if (read_cs() & 3)
  1003b5:	0f b7 c0             	movzwl %ax,%eax
  1003b8:	83 e0 03             	and    $0x3,%eax
  1003bb:	85 c0                	test   %eax,%eax
  1003bd:	74 14                	je     1003d3 <cputs+0x2c>
  1003bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1003c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  1003c5:	b8 00 00 00 00       	mov    $0x0,%eax
  1003ca:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1003cd:	89 d3                	mov    %edx,%ebx
  1003cf:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  1003d1:	eb 57                	jmp    10042a <cputs+0x83>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  1003d3:	c7 04 24 c0 d2 10 00 	movl   $0x10d2c0,(%esp)
  1003da:	e8 3a 1d 00 00       	call   102119 <spinlock_holding>
  1003df:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!already)
  1003e2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1003e6:	75 25                	jne    10040d <cputs+0x66>
		spinlock_acquire(&cons_lock);
  1003e8:	c7 04 24 c0 d2 10 00 	movl   $0x10d2c0,(%esp)
  1003ef:	e8 4f 1c 00 00       	call   102043 <spinlock_acquire>

	char ch;
	while (*str)
  1003f4:	eb 18                	jmp    10040e <cputs+0x67>
		cons_putc(*str++);
  1003f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1003f9:	0f b6 00             	movzbl (%eax),%eax
  1003fc:	0f be c0             	movsbl %al,%eax
  1003ff:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100403:	89 04 24             	mov    %eax,(%esp)
  100406:	e8 1a ff ff ff       	call   100325 <cons_putc>
  10040b:	eb 01                	jmp    10040e <cputs+0x67>
	bool already = spinlock_holding(&cons_lock);
	if (!already)
		spinlock_acquire(&cons_lock);

	char ch;
	while (*str)
  10040d:	90                   	nop
  10040e:	8b 45 08             	mov    0x8(%ebp),%eax
  100411:	0f b6 00             	movzbl (%eax),%eax
  100414:	84 c0                	test   %al,%al
  100416:	75 de                	jne    1003f6 <cputs+0x4f>
		cons_putc(*str++);

	if (!already)
  100418:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10041c:	75 0c                	jne    10042a <cputs+0x83>
		spinlock_release(&cons_lock);
  10041e:	c7 04 24 c0 d2 10 00 	movl   $0x10d2c0,(%esp)
  100425:	e8 95 1c 00 00       	call   1020bf <spinlock_release>
}
  10042a:	83 c4 24             	add    $0x24,%esp
  10042d:	5b                   	pop    %ebx
  10042e:	5d                   	pop    %ebp
  10042f:	c3                   	ret    

00100430 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100430:	55                   	push   %ebp
  100431:	89 e5                	mov    %esp,%ebp
  100433:	83 ec 58             	sub    $0x58,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  100436:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  100439:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  10043d:	0f b7 c0             	movzwl %ax,%eax
  100440:	83 e0 03             	and    $0x3,%eax
  100443:	85 c0                	test   %eax,%eax
  100445:	75 15                	jne    10045c <debug_panic+0x2c>
		if (panicstr)
  100447:	a1 28 88 10 00       	mov    0x108828,%eax
  10044c:	85 c0                	test   %eax,%eax
  10044e:	0f 85 95 00 00 00    	jne    1004e9 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  100454:	8b 45 10             	mov    0x10(%ebp),%eax
  100457:	a3 28 88 10 00       	mov    %eax,0x108828
	}

	// First print the requested message
	va_start(ap, fmt);
  10045c:	8d 45 10             	lea    0x10(%ebp),%eax
  10045f:	83 c0 04             	add    $0x4,%eax
  100462:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  100465:	8b 45 0c             	mov    0xc(%ebp),%eax
  100468:	89 44 24 08          	mov    %eax,0x8(%esp)
  10046c:	8b 45 08             	mov    0x8(%ebp),%eax
  10046f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100473:	c7 04 24 fd 4d 10 00 	movl   $0x104dfd,(%esp)
  10047a:	e8 07 42 00 00       	call   104686 <cprintf>
	vcprintf(fmt, ap);
  10047f:	8b 45 10             	mov    0x10(%ebp),%eax
  100482:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100485:	89 54 24 04          	mov    %edx,0x4(%esp)
  100489:	89 04 24             	mov    %eax,(%esp)
  10048c:	e8 8c 41 00 00       	call   10461d <vcprintf>
	cprintf("\n");
  100491:	c7 04 24 15 4e 10 00 	movl   $0x104e15,(%esp)
  100498:	e8 e9 41 00 00       	call   104686 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10049d:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  1004a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1004a3:	8d 55 c0             	lea    -0x40(%ebp),%edx
  1004a6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1004aa:	89 04 24             	mov    %eax,(%esp)
  1004ad:	e8 86 00 00 00       	call   100538 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1004b2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1004b9:	eb 1b                	jmp    1004d6 <debug_panic+0xa6>
		cprintf("  from %08x\n", eips[i]);
  1004bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1004be:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1004c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004c6:	c7 04 24 17 4e 10 00 	movl   $0x104e17,(%esp)
  1004cd:	e8 b4 41 00 00       	call   104686 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1004d2:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1004d6:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  1004da:	7f 0e                	jg     1004ea <debug_panic+0xba>
  1004dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1004df:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1004e3:	85 c0                	test   %eax,%eax
  1004e5:	75 d4                	jne    1004bb <debug_panic+0x8b>
  1004e7:	eb 01                	jmp    1004ea <debug_panic+0xba>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  1004e9:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  1004ea:	e8 06 fd ff ff       	call   1001f5 <done>

001004ef <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  1004ef:	55                   	push   %ebp
  1004f0:	89 e5                	mov    %esp,%ebp
  1004f2:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  1004f5:	8d 45 10             	lea    0x10(%ebp),%eax
  1004f8:	83 c0 04             	add    $0x4,%eax
  1004fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  1004fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  100501:	89 44 24 08          	mov    %eax,0x8(%esp)
  100505:	8b 45 08             	mov    0x8(%ebp),%eax
  100508:	89 44 24 04          	mov    %eax,0x4(%esp)
  10050c:	c7 04 24 24 4e 10 00 	movl   $0x104e24,(%esp)
  100513:	e8 6e 41 00 00       	call   104686 <cprintf>
	vcprintf(fmt, ap);
  100518:	8b 45 10             	mov    0x10(%ebp),%eax
  10051b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10051e:	89 54 24 04          	mov    %edx,0x4(%esp)
  100522:	89 04 24             	mov    %eax,(%esp)
  100525:	e8 f3 40 00 00       	call   10461d <vcprintf>
	cprintf("\n");
  10052a:	c7 04 24 15 4e 10 00 	movl   $0x104e15,(%esp)
  100531:	e8 50 41 00 00       	call   104686 <cprintf>
	va_end(ap);
}
  100536:	c9                   	leave  
  100537:	c3                   	ret    

00100538 <debug_trace>:

// Riecord the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100538:	55                   	push   %ebp
  100539:	89 e5                	mov    %esp,%ebp
  10053b:	83 ec 10             	sub    $0x10,%esp

	return;*/
	//panic("debug_trace not implemented");

	int i ,j;
		uint32_t *cur_epb = (uint32_t *)ebp;
  10053e:	8b 45 08             	mov    0x8(%ebp),%eax
  100541:	89 45 fc             	mov    %eax,-0x4(%ebp)
		//cprintf("Stack backtrace:\n");
		for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  100544:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10054b:	eb 32                	jmp    10057f <debug_trace+0x47>
			//cprintf("  ebp %08x eip %08x args",cur_epb[0],cur_epb[1]);
			eips[i] = cur_epb[1];
  10054d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100550:	c1 e0 02             	shl    $0x2,%eax
  100553:	03 45 0c             	add    0xc(%ebp),%eax
  100556:	8b 55 fc             	mov    -0x4(%ebp),%edx
  100559:	83 c2 04             	add    $0x4,%edx
  10055c:	8b 12                	mov    (%edx),%edx
  10055e:	89 10                	mov    %edx,(%eax)
			for(j = 0; j < 5; j++) {
  100560:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  100567:	eb 04                	jmp    10056d <debug_trace+0x35>
  100569:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  10056d:	83 7d f8 04          	cmpl   $0x4,-0x8(%ebp)
  100571:	7e f6                	jle    100569 <debug_trace+0x31>
				//makecprintf(" %08x",cur_epb[2 + j]);
			}
			//cprintf("\n");make
			cur_epb = (uint32_t *)(*cur_epb);
  100573:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100576:	8b 00                	mov    (%eax),%eax
  100578:	89 45 fc             	mov    %eax,-0x4(%ebp)
	//panic("debug_trace not implemented");

	int i ,j;
		uint32_t *cur_epb = (uint32_t *)ebp;
		//cprintf("Stack backtrace:\n");
		for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  10057b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10057f:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100583:	7f 1b                	jg     1005a0 <debug_trace+0x68>
  100585:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  100589:	75 c2                	jne    10054d <debug_trace+0x15>
				//makecprintf(" %08x",cur_epb[2 + j]);
			}
			//cprintf("\n");make
			cur_epb = (uint32_t *)(*cur_epb);
		}
		for(; i < DEBUG_TRACEFRAMES ; i++) {
  10058b:	eb 13                	jmp    1005a0 <debug_trace+0x68>
			eips[i] = 0;
  10058d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100590:	c1 e0 02             	shl    $0x2,%eax
  100593:	03 45 0c             	add    0xc(%ebp),%eax
  100596:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
				//makecprintf(" %08x",cur_epb[2 + j]);
			}
			//cprintf("\n");make
			cur_epb = (uint32_t *)(*cur_epb);
		}
		for(; i < DEBUG_TRACEFRAMES ; i++) {
  10059c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1005a0:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1005a4:	7e e7                	jle    10058d <debug_trace+0x55>
			eips[i] = 0;
		}
		/*
		for(i = 0; i < DEBUG_TRACEFRAMES ; i++) {
			cprintf("eip %x\n",eips[i]);			}*/
}
  1005a6:	c9                   	leave  
  1005a7:	c3                   	ret    

001005a8 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  1005a8:	55                   	push   %ebp
  1005a9:	89 e5                	mov    %esp,%ebp
  1005ab:	83 ec 18             	sub    $0x18,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1005ae:	89 6d fc             	mov    %ebp,-0x4(%ebp)
        return ebp;
  1005b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1005b4:	8b 55 0c             	mov    0xc(%ebp),%edx
  1005b7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1005bb:	89 04 24             	mov    %eax,(%esp)
  1005be:	e8 75 ff ff ff       	call   100538 <debug_trace>
  1005c3:	c9                   	leave  
  1005c4:	c3                   	ret    

001005c5 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  1005c5:	55                   	push   %ebp
  1005c6:	89 e5                	mov    %esp,%ebp
  1005c8:	83 ec 08             	sub    $0x8,%esp
  1005cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1005ce:	83 e0 02             	and    $0x2,%eax
  1005d1:	85 c0                	test   %eax,%eax
  1005d3:	74 14                	je     1005e9 <f2+0x24>
  1005d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1005df:	89 04 24             	mov    %eax,(%esp)
  1005e2:	e8 c1 ff ff ff       	call   1005a8 <f3>
  1005e7:	eb 12                	jmp    1005fb <f2+0x36>
  1005e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1005f3:	89 04 24             	mov    %eax,(%esp)
  1005f6:	e8 ad ff ff ff       	call   1005a8 <f3>
  1005fb:	c9                   	leave  
  1005fc:	c3                   	ret    

001005fd <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  1005fd:	55                   	push   %ebp
  1005fe:	89 e5                	mov    %esp,%ebp
  100600:	83 ec 08             	sub    $0x8,%esp
  100603:	8b 45 08             	mov    0x8(%ebp),%eax
  100606:	83 e0 01             	and    $0x1,%eax
  100609:	84 c0                	test   %al,%al
  10060b:	74 14                	je     100621 <f1+0x24>
  10060d:	8b 45 0c             	mov    0xc(%ebp),%eax
  100610:	89 44 24 04          	mov    %eax,0x4(%esp)
  100614:	8b 45 08             	mov    0x8(%ebp),%eax
  100617:	89 04 24             	mov    %eax,(%esp)
  10061a:	e8 a6 ff ff ff       	call   1005c5 <f2>
  10061f:	eb 12                	jmp    100633 <f1+0x36>
  100621:	8b 45 0c             	mov    0xc(%ebp),%eax
  100624:	89 44 24 04          	mov    %eax,0x4(%esp)
  100628:	8b 45 08             	mov    0x8(%ebp),%eax
  10062b:	89 04 24             	mov    %eax,(%esp)
  10062e:	e8 92 ff ff ff       	call   1005c5 <f2>
  100633:	c9                   	leave  
  100634:	c3                   	ret    

00100635 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100635:	55                   	push   %ebp
  100636:	89 e5                	mov    %esp,%ebp
  100638:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  10063e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100645:	eb 29                	jmp    100670 <debug_check+0x3b>
		f1(i, eips[i]);
  100647:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  10064d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100650:	89 d0                	mov    %edx,%eax
  100652:	c1 e0 02             	shl    $0x2,%eax
  100655:	01 d0                	add    %edx,%eax
  100657:	c1 e0 03             	shl    $0x3,%eax
  10065a:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  10065d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100661:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100664:	89 04 24             	mov    %eax,(%esp)
  100667:	e8 91 ff ff ff       	call   1005fd <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  10066c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100670:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  100674:	7e d1                	jle    100647 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100676:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  10067d:	e9 bc 00 00 00       	jmp    10073e <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100682:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100689:	e9 a2 00 00 00       	jmp    100730 <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  10068e:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100691:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100694:	89 d0                	mov    %edx,%eax
  100696:	c1 e0 02             	shl    $0x2,%eax
  100699:	01 d0                	add    %edx,%eax
  10069b:	01 c0                	add    %eax,%eax
  10069d:	01 c8                	add    %ecx,%eax
  10069f:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  1006a6:	85 c0                	test   %eax,%eax
  1006a8:	0f 95 c2             	setne  %dl
  1006ab:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  1006af:	0f 9e c0             	setle  %al
  1006b2:	31 d0                	xor    %edx,%eax
  1006b4:	84 c0                	test   %al,%al
  1006b6:	74 24                	je     1006dc <debug_check+0xa7>
  1006b8:	c7 44 24 0c 3e 4e 10 	movl   $0x104e3e,0xc(%esp)
  1006bf:	00 
  1006c0:	c7 44 24 08 5b 4e 10 	movl   $0x104e5b,0x8(%esp)
  1006c7:	00 
  1006c8:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  1006cf:	00 
  1006d0:	c7 04 24 70 4e 10 00 	movl   $0x104e70,(%esp)
  1006d7:	e8 54 fd ff ff       	call   100430 <debug_panic>
			if (i >= 2)
  1006dc:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  1006e0:	7e 4a                	jle    10072c <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  1006e2:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1006e5:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  1006e8:	89 d0                	mov    %edx,%eax
  1006ea:	c1 e0 02             	shl    $0x2,%eax
  1006ed:	01 d0                	add    %edx,%eax
  1006ef:	01 c0                	add    %eax,%eax
  1006f1:	01 c8                	add    %ecx,%eax
  1006f3:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  1006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006fd:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100704:	39 c2                	cmp    %eax,%edx
  100706:	74 24                	je     10072c <debug_check+0xf7>
  100708:	c7 44 24 0c 7d 4e 10 	movl   $0x104e7d,0xc(%esp)
  10070f:	00 
  100710:	c7 44 24 08 5b 4e 10 	movl   $0x104e5b,0x8(%esp)
  100717:	00 
  100718:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  10071f:	00 
  100720:	c7 04 24 70 4e 10 00 	movl   $0x104e70,(%esp)
  100727:	e8 04 fd ff ff       	call   100430 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  10072c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100730:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100734:	0f 8e 54 ff ff ff    	jle    10068e <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  10073a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10073e:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  100742:	0f 8e 3a ff ff ff    	jle    100682 <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  100748:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  10074e:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  100754:	39 c2                	cmp    %eax,%edx
  100756:	74 24                	je     10077c <debug_check+0x147>
  100758:	c7 44 24 0c 96 4e 10 	movl   $0x104e96,0xc(%esp)
  10075f:	00 
  100760:	c7 44 24 08 5b 4e 10 	movl   $0x104e5b,0x8(%esp)
  100767:	00 
  100768:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  10076f:	00 
  100770:	c7 04 24 70 4e 10 00 	movl   $0x104e70,(%esp)
  100777:	e8 b4 fc ff ff       	call   100430 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  10077c:	8b 55 a0             	mov    -0x60(%ebp),%edx
  10077f:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100782:	39 c2                	cmp    %eax,%edx
  100784:	74 24                	je     1007aa <debug_check+0x175>
  100786:	c7 44 24 0c af 4e 10 	movl   $0x104eaf,0xc(%esp)
  10078d:	00 
  10078e:	c7 44 24 08 5b 4e 10 	movl   $0x104e5b,0x8(%esp)
  100795:	00 
  100796:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  10079d:	00 
  10079e:	c7 04 24 70 4e 10 00 	movl   $0x104e70,(%esp)
  1007a5:	e8 86 fc ff ff       	call   100430 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  1007aa:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  1007b0:	8b 45 a0             	mov    -0x60(%ebp),%eax
  1007b3:	39 c2                	cmp    %eax,%edx
  1007b5:	75 24                	jne    1007db <debug_check+0x1a6>
  1007b7:	c7 44 24 0c c8 4e 10 	movl   $0x104ec8,0xc(%esp)
  1007be:	00 
  1007bf:	c7 44 24 08 5b 4e 10 	movl   $0x104e5b,0x8(%esp)
  1007c6:	00 
  1007c7:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  1007ce:	00 
  1007cf:	c7 04 24 70 4e 10 00 	movl   $0x104e70,(%esp)
  1007d6:	e8 55 fc ff ff       	call   100430 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  1007db:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1007e1:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1007e4:	39 c2                	cmp    %eax,%edx
  1007e6:	74 24                	je     10080c <debug_check+0x1d7>
  1007e8:	c7 44 24 0c e1 4e 10 	movl   $0x104ee1,0xc(%esp)
  1007ef:	00 
  1007f0:	c7 44 24 08 5b 4e 10 	movl   $0x104e5b,0x8(%esp)
  1007f7:	00 
  1007f8:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  1007ff:	00 
  100800:	c7 04 24 70 4e 10 00 	movl   $0x104e70,(%esp)
  100807:	e8 24 fc ff ff       	call   100430 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10080c:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100812:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100815:	39 c2                	cmp    %eax,%edx
  100817:	74 24                	je     10083d <debug_check+0x208>
  100819:	c7 44 24 0c fa 4e 10 	movl   $0x104efa,0xc(%esp)
  100820:	00 
  100821:	c7 44 24 08 5b 4e 10 	movl   $0x104e5b,0x8(%esp)
  100828:	00 
  100829:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100830:	00 
  100831:	c7 04 24 70 4e 10 00 	movl   $0x104e70,(%esp)
  100838:	e8 f3 fb ff ff       	call   100430 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10083d:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100843:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  100849:	39 c2                	cmp    %eax,%edx
  10084b:	75 24                	jne    100871 <debug_check+0x23c>
  10084d:	c7 44 24 0c 13 4f 10 	movl   $0x104f13,0xc(%esp)
  100854:	00 
  100855:	c7 44 24 08 5b 4e 10 	movl   $0x104e5b,0x8(%esp)
  10085c:	00 
  10085d:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  100864:	00 
  100865:	c7 04 24 70 4e 10 00 	movl   $0x104e70,(%esp)
  10086c:	e8 bf fb ff ff       	call   100430 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100871:	c7 04 24 2c 4f 10 00 	movl   $0x104f2c,(%esp)
  100878:	e8 09 3e 00 00       	call   104686 <cprintf>
}
  10087d:	c9                   	leave  
  10087e:	c3                   	ret    

0010087f <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10087f:	55                   	push   %ebp
  100880:	89 e5                	mov    %esp,%ebp
  100882:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100885:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100888:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10088b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10088e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100891:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100896:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100899:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10089c:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1008a2:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1008a7:	74 24                	je     1008cd <cpu_cur+0x4e>
  1008a9:	c7 44 24 0c 48 4f 10 	movl   $0x104f48,0xc(%esp)
  1008b0:	00 
  1008b1:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  1008b8:	00 
  1008b9:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1008c0:	00 
  1008c1:	c7 04 24 73 4f 10 00 	movl   $0x104f73,(%esp)
  1008c8:	e8 63 fb ff ff       	call   100430 <debug_panic>
	return c;
  1008cd:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1008d0:	c9                   	leave  
  1008d1:	c3                   	ret    

001008d2 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1008d2:	55                   	push   %ebp
  1008d3:	89 e5                	mov    %esp,%ebp
  1008d5:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1008d8:	e8 a2 ff ff ff       	call   10087f <cpu_cur>
  1008dd:	3d 00 60 10 00       	cmp    $0x106000,%eax
  1008e2:	0f 94 c0             	sete   %al
  1008e5:	0f b6 c0             	movzbl %al,%eax
}
  1008e8:	c9                   	leave  
  1008e9:	c3                   	ret    

001008ea <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  1008ea:	55                   	push   %ebp
  1008eb:	89 e5                	mov    %esp,%ebp
  1008ed:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1008f0:	e8 dd ff ff ff       	call   1008d2 <cpu_onboot>
  1008f5:	85 c0                	test   %eax,%eax
  1008f7:	0f 84 bc 01 00 00    	je     100ab9 <mem_init+0x1cf>
		return;

	
	spinlock_init(&mem_spinlock);
  1008fd:	c7 44 24 08 2d 00 00 	movl   $0x2d,0x8(%esp)
  100904:	00 
  100905:	c7 44 24 04 80 4f 10 	movl   $0x104f80,0x4(%esp)
  10090c:	00 
  10090d:	c7 04 24 20 d3 30 00 	movl   $0x30d320,(%esp)
  100914:	e8 f6 16 00 00       	call   10200f <spinlock_init_>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100919:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100920:	e8 57 30 00 00       	call   10397c <nvram_read16>
  100925:	c1 e0 0a             	shl    $0xa,%eax
  100928:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10092b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10092e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100933:	89 45 dc             	mov    %eax,-0x24(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100936:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  10093d:	e8 3a 30 00 00       	call   10397c <nvram_read16>
  100942:	c1 e0 0a             	shl    $0xa,%eax
  100945:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100948:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10094b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100950:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  100953:	c7 44 24 08 8c 4f 10 	movl   $0x104f8c,0x8(%esp)
  10095a:	00 
  10095b:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
  100962:	00 
  100963:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  10096a:	e8 80 fb ff ff       	call   1004ef <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  10096f:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100976:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100979:	05 00 00 10 00       	add    $0x100000,%eax
  10097e:	a3 08 d3 10 00       	mov    %eax,0x10d308

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100983:	a1 08 d3 10 00       	mov    0x10d308,%eax
  100988:	c1 e8 0c             	shr    $0xc,%eax
  10098b:	a3 04 d3 10 00       	mov    %eax,0x10d304

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100990:	a1 08 d3 10 00       	mov    0x10d308,%eax
  100995:	c1 e8 0a             	shr    $0xa,%eax
  100998:	89 44 24 04          	mov    %eax,0x4(%esp)
  10099c:	c7 04 24 ac 4f 10 00 	movl   $0x104fac,(%esp)
  1009a3:	e8 de 3c 00 00       	call   104686 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  1009a8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009ab:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  1009ae:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  1009b0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1009b3:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  1009b6:	89 54 24 08          	mov    %edx,0x8(%esp)
  1009ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009be:	c7 04 24 cd 4f 10 00 	movl   $0x104fcd,(%esp)
  1009c5:	e8 bc 3c 00 00       	call   104686 <cprintf>


	extern char start[], end[];
	uint32_t page_start;
	
	pageinfo **freetail = &mem_freelist;
  1009ca:	c7 45 e8 00 d3 10 00 	movl   $0x10d300,-0x18(%ebp)
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  1009d1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1009d8:	00 
  1009d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1009e0:	00 
  1009e1:	c7 04 24 20 d3 10 00 	movl   $0x10d320,(%esp)
  1009e8:	e8 7e 3e 00 00       	call   10486b <memset>
	mem_pageinfo = spc_for_pi;
  1009ed:	c7 05 58 d3 30 00 20 	movl   $0x10d320,0x30d358
  1009f4:	d3 10 00 
	int i;
	for (i = 0; i < mem_npage; i++) {
  1009f7:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1009fe:	e9 96 00 00 00       	jmp    100a99 <mem_init+0x1af>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100a03:	a1 58 d3 30 00       	mov    0x30d358,%eax
  100a08:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a0b:	c1 e2 03             	shl    $0x3,%edx
  100a0e:	01 d0                	add    %edx,%eax
  100a10:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		if(i == 0 || i == 1)
  100a17:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100a1b:	74 6e                	je     100a8b <mem_init+0x1a1>
  100a1d:	83 7d ec 01          	cmpl   $0x1,-0x14(%ebp)
  100a21:	74 6b                	je     100a8e <mem_init+0x1a4>
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);
  100a23:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100a26:	c1 e0 03             	shl    $0x3,%eax
  100a29:	c1 f8 03             	sar    $0x3,%eax
  100a2c:	c1 e0 0c             	shl    $0xc,%eax
  100a2f:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100a32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100a35:	05 00 10 00 00       	add    $0x1000,%eax
  100a3a:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  100a3f:	76 09                	jbe    100a4a <mem_init+0x160>
  100a41:	81 7d e4 ff ff 0f 00 	cmpl   $0xfffff,-0x1c(%ebp)
  100a48:	76 47                	jbe    100a91 <mem_init+0x1a7>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  100a4a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100a4d:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
  100a53:	b8 0c 00 10 00       	mov    $0x10000c,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100a58:	39 c2                	cmp    %eax,%edx
  100a5a:	72 0a                	jb     100a66 <mem_init+0x17c>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  100a5c:	b8 2c da 30 00       	mov    $0x30da2c,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100a61:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  100a64:	72 2e                	jb     100a94 <mem_init+0x1aa>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;


		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100a66:	a1 58 d3 30 00       	mov    0x30d358,%eax
  100a6b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a6e:	c1 e2 03             	shl    $0x3,%edx
  100a71:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100a74:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a77:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100a79:	a1 58 d3 30 00       	mov    0x30d358,%eax
  100a7e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a81:	c1 e2 03             	shl    $0x3,%edx
  100a84:	01 d0                	add    %edx,%eax
  100a86:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100a89:	eb 0a                	jmp    100a95 <mem_init+0x1ab>
	for (i = 0; i < mem_npage; i++) {
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;

		if(i == 0 || i == 1)
			continue;
  100a8b:	90                   	nop
  100a8c:	eb 07                	jmp    100a95 <mem_init+0x1ab>
  100a8e:	90                   	nop
  100a8f:	eb 04                	jmp    100a95 <mem_init+0x1ab>

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;
  100a91:	90                   	nop
  100a92:	eb 01                	jmp    100a95 <mem_init+0x1ab>
  100a94:	90                   	nop
	
	pageinfo **freetail = &mem_freelist;
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
	mem_pageinfo = spc_for_pi;
	int i;
	for (i = 0; i < mem_npage; i++) {
  100a95:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100a99:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a9c:	a1 04 d3 10 00       	mov    0x10d304,%eax
  100aa1:	39 c2                	cmp    %eax,%edx
  100aa3:	0f 82 5a ff ff ff    	jb     100a03 <mem_init+0x119>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100aa9:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100aac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100ab2:	e8 a1 00 00 00       	call   100b58 <mem_check>
  100ab7:	eb 01                	jmp    100aba <mem_init+0x1d0>

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100ab9:	90                   	nop
	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100aba:	c9                   	leave  
  100abb:	c3                   	ret    

00100abc <mem_alloc>:



pageinfo *
mem_alloc(void)
{
  100abc:	55                   	push   %ebp
  100abd:	89 e5                	mov    %esp,%ebp
  100abf:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	// Fill this function in.
	//panic("mem_alloc not implemented.");

	if(mem_freelist == NULL)
  100ac2:	a1 00 d3 10 00       	mov    0x10d300,%eax
  100ac7:	85 c0                	test   %eax,%eax
  100ac9:	75 07                	jne    100ad2 <mem_alloc+0x16>
		return NULL;
  100acb:	b8 00 00 00 00       	mov    $0x0,%eax
  100ad0:	eb 2f                	jmp    100b01 <mem_alloc+0x45>

	spinlock_acquire(&mem_spinlock);
  100ad2:	c7 04 24 20 d3 30 00 	movl   $0x30d320,(%esp)
  100ad9:	e8 65 15 00 00       	call   102043 <spinlock_acquire>
	pageinfo* r = mem_freelist;
  100ade:	a1 00 d3 10 00       	mov    0x10d300,%eax
  100ae3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = mem_freelist->free_next;
  100ae6:	a1 00 d3 10 00       	mov    0x10d300,%eax
  100aeb:	8b 00                	mov    (%eax),%eax
  100aed:	a3 00 d3 10 00       	mov    %eax,0x10d300
	spinlock_release(&mem_spinlock);
  100af2:	c7 04 24 20 d3 30 00 	movl   $0x30d320,(%esp)
  100af9:	e8 c1 15 00 00       	call   1020bf <spinlock_release>
	return r;
  100afe:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100b01:	c9                   	leave  
  100b02:	c3                   	ret    

00100b03 <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100b03:	55                   	push   %ebp
  100b04:	89 e5                	mov    %esp,%ebp
  100b06:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");

	if(pi == NULL)
  100b09:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100b0d:	75 1c                	jne    100b2b <mem_free+0x28>
		panic("null for page which to be freed!"); 
  100b0f:	c7 44 24 08 ec 4f 10 	movl   $0x104fec,0x8(%esp)
  100b16:	00 
  100b17:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  100b1e:	00 
  100b1f:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100b26:	e8 05 f9 ff ff       	call   100430 <debug_panic>

	spinlock_acquire(&mem_spinlock);
  100b2b:	c7 04 24 20 d3 30 00 	movl   $0x30d320,(%esp)
  100b32:	e8 0c 15 00 00       	call   102043 <spinlock_acquire>
	pi->free_next = mem_freelist;
  100b37:	8b 15 00 d3 10 00    	mov    0x10d300,%edx
  100b3d:	8b 45 08             	mov    0x8(%ebp),%eax
  100b40:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100b42:	8b 45 08             	mov    0x8(%ebp),%eax
  100b45:	a3 00 d3 10 00       	mov    %eax,0x10d300
	spinlock_release(&mem_spinlock);
  100b4a:	c7 04 24 20 d3 30 00 	movl   $0x30d320,(%esp)
  100b51:	e8 69 15 00 00       	call   1020bf <spinlock_release>
	
}
  100b56:	c9                   	leave  
  100b57:	c3                   	ret    

00100b58 <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100b58:	55                   	push   %ebp
  100b59:	89 e5                	mov    %esp,%ebp
  100b5b:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100b5e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100b65:	a1 00 d3 10 00       	mov    0x10d300,%eax
  100b6a:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100b6d:	eb 38                	jmp    100ba7 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100b6f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100b72:	a1 58 d3 30 00       	mov    0x30d358,%eax
  100b77:	89 d1                	mov    %edx,%ecx
  100b79:	29 c1                	sub    %eax,%ecx
  100b7b:	89 c8                	mov    %ecx,%eax
  100b7d:	c1 f8 03             	sar    $0x3,%eax
  100b80:	c1 e0 0c             	shl    $0xc,%eax
  100b83:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100b8a:	00 
  100b8b:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100b92:	00 
  100b93:	89 04 24             	mov    %eax,(%esp)
  100b96:	e8 d0 3c 00 00       	call   10486b <memset>
		freepages++;
  100b9b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100b9f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100ba2:	8b 00                	mov    (%eax),%eax
  100ba4:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100ba7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  100bab:	75 c2                	jne    100b6f <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100bad:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100bb0:	89 44 24 04          	mov    %eax,0x4(%esp)
  100bb4:	c7 04 24 0d 50 10 00 	movl   $0x10500d,(%esp)
  100bbb:	e8 c6 3a 00 00       	call   104686 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100bc0:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100bc3:	a1 04 d3 10 00       	mov    0x10d304,%eax
  100bc8:	39 c2                	cmp    %eax,%edx
  100bca:	72 24                	jb     100bf0 <mem_check+0x98>
  100bcc:	c7 44 24 0c 27 50 10 	movl   $0x105027,0xc(%esp)
  100bd3:	00 
  100bd4:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100bdb:	00 
  100bdc:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  100be3:	00 
  100be4:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100beb:	e8 40 f8 ff ff       	call   100430 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100bf0:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100bf7:	7f 24                	jg     100c1d <mem_check+0xc5>
  100bf9:	c7 44 24 0c 3d 50 10 	movl   $0x10503d,0xc(%esp)
  100c00:	00 
  100c01:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100c08:	00 
  100c09:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100c10:	00 
  100c11:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100c18:	e8 13 f8 ff ff       	call   100430 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100c1d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100c24:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100c27:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100c2a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100c2d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100c30:	e8 87 fe ff ff       	call   100abc <mem_alloc>
  100c35:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100c38:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100c3c:	75 24                	jne    100c62 <mem_check+0x10a>
  100c3e:	c7 44 24 0c 4f 50 10 	movl   $0x10504f,0xc(%esp)
  100c45:	00 
  100c46:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100c4d:	00 
  100c4e:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  100c55:	00 
  100c56:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100c5d:	e8 ce f7 ff ff       	call   100430 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100c62:	e8 55 fe ff ff       	call   100abc <mem_alloc>
  100c67:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100c6a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100c6e:	75 24                	jne    100c94 <mem_check+0x13c>
  100c70:	c7 44 24 0c 58 50 10 	movl   $0x105058,0xc(%esp)
  100c77:	00 
  100c78:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100c7f:	00 
  100c80:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100c87:	00 
  100c88:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100c8f:	e8 9c f7 ff ff       	call   100430 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100c94:	e8 23 fe ff ff       	call   100abc <mem_alloc>
  100c99:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100c9c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100ca0:	75 24                	jne    100cc6 <mem_check+0x16e>
  100ca2:	c7 44 24 0c 61 50 10 	movl   $0x105061,0xc(%esp)
  100ca9:	00 
  100caa:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100cb1:	00 
  100cb2:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100cb9:	00 
  100cba:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100cc1:	e8 6a f7 ff ff       	call   100430 <debug_panic>

	assert(pp0);
  100cc6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100cca:	75 24                	jne    100cf0 <mem_check+0x198>
  100ccc:	c7 44 24 0c 6a 50 10 	movl   $0x10506a,0xc(%esp)
  100cd3:	00 
  100cd4:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100cdb:	00 
  100cdc:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  100ce3:	00 
  100ce4:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100ceb:	e8 40 f7 ff ff       	call   100430 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100cf0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100cf4:	74 08                	je     100cfe <mem_check+0x1a6>
  100cf6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100cf9:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100cfc:	75 24                	jne    100d22 <mem_check+0x1ca>
  100cfe:	c7 44 24 0c 6e 50 10 	movl   $0x10506e,0xc(%esp)
  100d05:	00 
  100d06:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100d0d:	00 
  100d0e:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100d15:	00 
  100d16:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100d1d:	e8 0e f7 ff ff       	call   100430 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100d22:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d26:	74 10                	je     100d38 <mem_check+0x1e0>
  100d28:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d2b:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100d2e:	74 08                	je     100d38 <mem_check+0x1e0>
  100d30:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d33:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d36:	75 24                	jne    100d5c <mem_check+0x204>
  100d38:	c7 44 24 0c 80 50 10 	movl   $0x105080,0xc(%esp)
  100d3f:	00 
  100d40:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100d47:	00 
  100d48:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100d4f:	00 
  100d50:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100d57:	e8 d4 f6 ff ff       	call   100430 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100d5c:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100d5f:	a1 58 d3 30 00       	mov    0x30d358,%eax
  100d64:	89 d1                	mov    %edx,%ecx
  100d66:	29 c1                	sub    %eax,%ecx
  100d68:	89 c8                	mov    %ecx,%eax
  100d6a:	c1 f8 03             	sar    $0x3,%eax
  100d6d:	c1 e0 0c             	shl    $0xc,%eax
  100d70:	8b 15 04 d3 10 00    	mov    0x10d304,%edx
  100d76:	c1 e2 0c             	shl    $0xc,%edx
  100d79:	39 d0                	cmp    %edx,%eax
  100d7b:	72 24                	jb     100da1 <mem_check+0x249>
  100d7d:	c7 44 24 0c a0 50 10 	movl   $0x1050a0,0xc(%esp)
  100d84:	00 
  100d85:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100d8c:	00 
  100d8d:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  100d94:	00 
  100d95:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100d9c:	e8 8f f6 ff ff       	call   100430 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100da1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100da4:	a1 58 d3 30 00       	mov    0x30d358,%eax
  100da9:	89 d1                	mov    %edx,%ecx
  100dab:	29 c1                	sub    %eax,%ecx
  100dad:	89 c8                	mov    %ecx,%eax
  100daf:	c1 f8 03             	sar    $0x3,%eax
  100db2:	c1 e0 0c             	shl    $0xc,%eax
  100db5:	8b 15 04 d3 10 00    	mov    0x10d304,%edx
  100dbb:	c1 e2 0c             	shl    $0xc,%edx
  100dbe:	39 d0                	cmp    %edx,%eax
  100dc0:	72 24                	jb     100de6 <mem_check+0x28e>
  100dc2:	c7 44 24 0c c8 50 10 	movl   $0x1050c8,0xc(%esp)
  100dc9:	00 
  100dca:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100dd1:	00 
  100dd2:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  100dd9:	00 
  100dda:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100de1:	e8 4a f6 ff ff       	call   100430 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100de6:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100de9:	a1 58 d3 30 00       	mov    0x30d358,%eax
  100dee:	89 d1                	mov    %edx,%ecx
  100df0:	29 c1                	sub    %eax,%ecx
  100df2:	89 c8                	mov    %ecx,%eax
  100df4:	c1 f8 03             	sar    $0x3,%eax
  100df7:	c1 e0 0c             	shl    $0xc,%eax
  100dfa:	8b 15 04 d3 10 00    	mov    0x10d304,%edx
  100e00:	c1 e2 0c             	shl    $0xc,%edx
  100e03:	39 d0                	cmp    %edx,%eax
  100e05:	72 24                	jb     100e2b <mem_check+0x2d3>
  100e07:	c7 44 24 0c f0 50 10 	movl   $0x1050f0,0xc(%esp)
  100e0e:	00 
  100e0f:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100e16:	00 
  100e17:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  100e1e:	00 
  100e1f:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100e26:	e8 05 f6 ff ff       	call   100430 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100e2b:	a1 00 d3 10 00       	mov    0x10d300,%eax
  100e30:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100e33:	c7 05 00 d3 10 00 00 	movl   $0x0,0x10d300
  100e3a:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100e3d:	e8 7a fc ff ff       	call   100abc <mem_alloc>
  100e42:	85 c0                	test   %eax,%eax
  100e44:	74 24                	je     100e6a <mem_check+0x312>
  100e46:	c7 44 24 0c 16 51 10 	movl   $0x105116,0xc(%esp)
  100e4d:	00 
  100e4e:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100e55:	00 
  100e56:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  100e5d:	00 
  100e5e:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100e65:	e8 c6 f5 ff ff       	call   100430 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100e6a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100e6d:	89 04 24             	mov    %eax,(%esp)
  100e70:	e8 8e fc ff ff       	call   100b03 <mem_free>
        mem_free(pp1);
  100e75:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100e78:	89 04 24             	mov    %eax,(%esp)
  100e7b:	e8 83 fc ff ff       	call   100b03 <mem_free>
        mem_free(pp2);
  100e80:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e83:	89 04 24             	mov    %eax,(%esp)
  100e86:	e8 78 fc ff ff       	call   100b03 <mem_free>
	pp0 = pp1 = pp2 = 0;
  100e8b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100e92:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e95:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100e98:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100e9b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100e9e:	e8 19 fc ff ff       	call   100abc <mem_alloc>
  100ea3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100ea6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100eaa:	75 24                	jne    100ed0 <mem_check+0x378>
  100eac:	c7 44 24 0c 4f 50 10 	movl   $0x10504f,0xc(%esp)
  100eb3:	00 
  100eb4:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100ebb:	00 
  100ebc:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  100ec3:	00 
  100ec4:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100ecb:	e8 60 f5 ff ff       	call   100430 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100ed0:	e8 e7 fb ff ff       	call   100abc <mem_alloc>
  100ed5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100ed8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100edc:	75 24                	jne    100f02 <mem_check+0x3aa>
  100ede:	c7 44 24 0c 58 50 10 	movl   $0x105058,0xc(%esp)
  100ee5:	00 
  100ee6:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100eed:	00 
  100eee:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  100ef5:	00 
  100ef6:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100efd:	e8 2e f5 ff ff       	call   100430 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100f02:	e8 b5 fb ff ff       	call   100abc <mem_alloc>
  100f07:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100f0a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f0e:	75 24                	jne    100f34 <mem_check+0x3dc>
  100f10:	c7 44 24 0c 61 50 10 	movl   $0x105061,0xc(%esp)
  100f17:	00 
  100f18:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100f1f:	00 
  100f20:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  100f27:	00 
  100f28:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100f2f:	e8 fc f4 ff ff       	call   100430 <debug_panic>
	assert(pp0);
  100f34:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100f38:	75 24                	jne    100f5e <mem_check+0x406>
  100f3a:	c7 44 24 0c 6a 50 10 	movl   $0x10506a,0xc(%esp)
  100f41:	00 
  100f42:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100f49:	00 
  100f4a:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  100f51:	00 
  100f52:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100f59:	e8 d2 f4 ff ff       	call   100430 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100f5e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100f62:	74 08                	je     100f6c <mem_check+0x414>
  100f64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100f67:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100f6a:	75 24                	jne    100f90 <mem_check+0x438>
  100f6c:	c7 44 24 0c 6e 50 10 	movl   $0x10506e,0xc(%esp)
  100f73:	00 
  100f74:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100f7b:	00 
  100f7c:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  100f83:	00 
  100f84:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100f8b:	e8 a0 f4 ff ff       	call   100430 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100f90:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f94:	74 10                	je     100fa6 <mem_check+0x44e>
  100f96:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100f99:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100f9c:	74 08                	je     100fa6 <mem_check+0x44e>
  100f9e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100fa1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100fa4:	75 24                	jne    100fca <mem_check+0x472>
  100fa6:	c7 44 24 0c 80 50 10 	movl   $0x105080,0xc(%esp)
  100fad:	00 
  100fae:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100fb5:	00 
  100fb6:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  100fbd:	00 
  100fbe:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100fc5:	e8 66 f4 ff ff       	call   100430 <debug_panic>
	assert(mem_alloc() == 0);
  100fca:	e8 ed fa ff ff       	call   100abc <mem_alloc>
  100fcf:	85 c0                	test   %eax,%eax
  100fd1:	74 24                	je     100ff7 <mem_check+0x49f>
  100fd3:	c7 44 24 0c 16 51 10 	movl   $0x105116,0xc(%esp)
  100fda:	00 
  100fdb:	c7 44 24 08 5e 4f 10 	movl   $0x104f5e,0x8(%esp)
  100fe2:	00 
  100fe3:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  100fea:	00 
  100feb:	c7 04 24 80 4f 10 00 	movl   $0x104f80,(%esp)
  100ff2:	e8 39 f4 ff ff       	call   100430 <debug_panic>

	// give free list back
	mem_freelist = fl;
  100ff7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100ffa:	a3 00 d3 10 00       	mov    %eax,0x10d300

	// free the pages we took
	mem_free(pp0);
  100fff:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101002:	89 04 24             	mov    %eax,(%esp)
  101005:	e8 f9 fa ff ff       	call   100b03 <mem_free>
	mem_free(pp1);
  10100a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10100d:	89 04 24             	mov    %eax,(%esp)
  101010:	e8 ee fa ff ff       	call   100b03 <mem_free>
	mem_free(pp2);
  101015:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101018:	89 04 24             	mov    %eax,(%esp)
  10101b:	e8 e3 fa ff ff       	call   100b03 <mem_free>

	cprintf("mem_check() succeeded!\n");
  101020:	c7 04 24 27 51 10 00 	movl   $0x105127,(%esp)
  101027:	e8 5a 36 00 00       	call   104686 <cprintf>
}
  10102c:	c9                   	leave  
  10102d:	c3                   	ret    

0010102e <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10102e:	55                   	push   %ebp
  10102f:	89 e5                	mov    %esp,%ebp
  101031:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101034:	8b 55 08             	mov    0x8(%ebp),%edx
  101037:	8b 45 0c             	mov    0xc(%ebp),%eax
  10103a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10103d:	f0 87 02             	lock xchg %eax,(%edx)
  101040:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  101043:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101046:	c9                   	leave  
  101047:	c3                   	ret    

00101048 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101048:	55                   	push   %ebp
  101049:	89 e5                	mov    %esp,%ebp
  10104b:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10104e:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101051:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101054:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101057:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10105a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10105f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101062:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101065:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10106b:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101070:	74 24                	je     101096 <cpu_cur+0x4e>
  101072:	c7 44 24 0c 3f 51 10 	movl   $0x10513f,0xc(%esp)
  101079:	00 
  10107a:	c7 44 24 08 55 51 10 	movl   $0x105155,0x8(%esp)
  101081:	00 
  101082:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101089:	00 
  10108a:	c7 04 24 6a 51 10 00 	movl   $0x10516a,(%esp)
  101091:	e8 9a f3 ff ff       	call   100430 <debug_panic>
	return c;
  101096:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101099:	c9                   	leave  
  10109a:	c3                   	ret    

0010109b <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10109b:	55                   	push   %ebp
  10109c:	89 e5                	mov    %esp,%ebp
  10109e:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1010a1:	e8 a2 ff ff ff       	call   101048 <cpu_cur>
  1010a6:	3d 00 60 10 00       	cmp    $0x106000,%eax
  1010ab:	0f 94 c0             	sete   %al
  1010ae:	0f b6 c0             	movzbl %al,%eax
}
  1010b1:	c9                   	leave  
  1010b2:	c3                   	ret    

001010b3 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  1010b3:	55                   	push   %ebp
  1010b4:	89 e5                	mov    %esp,%ebp
  1010b6:	53                   	push   %ebx
  1010b7:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  1010ba:	e8 89 ff ff ff       	call   101048 <cpu_cur>
  1010bf:	89 45 f0             	mov    %eax,-0x10(%ebp)

	c->tss.ts_ss0 = CPU_GDT_KDATA;
  1010c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010c5:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)
	c->tss.ts_esp0 = (uintptr_t)c->kstackhi; 
  1010cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010ce:	05 00 10 00 00       	add    $0x1000,%eax
  1010d3:	89 c2                	mov    %eax,%edx
  1010d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010d8:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->gdt[CPU_GDT_TSS>>3] = SEGDESC16(0, STS_T32A, (uintptr_t)(&c->tss), sizeof(c->tss) - 1, 0);
  1010db:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010de:	83 c0 38             	add    $0x38,%eax
  1010e1:	89 c3                	mov    %eax,%ebx
  1010e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010e6:	83 c0 38             	add    $0x38,%eax
  1010e9:	c1 e8 10             	shr    $0x10,%eax
  1010ec:	89 c1                	mov    %eax,%ecx
  1010ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010f1:	83 c0 38             	add    $0x38,%eax
  1010f4:	c1 e8 18             	shr    $0x18,%eax
  1010f7:	89 c2                	mov    %eax,%edx
  1010f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010fc:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  101102:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101105:	66 89 58 32          	mov    %bx,0x32(%eax)
  101109:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10110c:	88 48 34             	mov    %cl,0x34(%eax)
  10110f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101112:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101116:	83 e1 f0             	and    $0xfffffff0,%ecx
  101119:	83 c9 09             	or     $0x9,%ecx
  10111c:	88 48 35             	mov    %cl,0x35(%eax)
  10111f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101122:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101126:	83 e1 ef             	and    $0xffffffef,%ecx
  101129:	88 48 35             	mov    %cl,0x35(%eax)
  10112c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10112f:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101133:	83 e1 9f             	and    $0xffffff9f,%ecx
  101136:	88 48 35             	mov    %cl,0x35(%eax)
  101139:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10113c:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101140:	83 c9 80             	or     $0xffffff80,%ecx
  101143:	88 48 35             	mov    %cl,0x35(%eax)
  101146:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101149:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10114d:	83 e1 f0             	and    $0xfffffff0,%ecx
  101150:	88 48 36             	mov    %cl,0x36(%eax)
  101153:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101156:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10115a:	83 e1 ef             	and    $0xffffffef,%ecx
  10115d:	88 48 36             	mov    %cl,0x36(%eax)
  101160:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101163:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101167:	83 e1 df             	and    $0xffffffdf,%ecx
  10116a:	88 48 36             	mov    %cl,0x36(%eax)
  10116d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101170:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101174:	83 c9 40             	or     $0x40,%ecx
  101177:	88 48 36             	mov    %cl,0x36(%eax)
  10117a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10117d:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101181:	83 e1 7f             	and    $0x7f,%ecx
  101184:	88 48 36             	mov    %cl,0x36(%eax)
  101187:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10118a:	88 50 37             	mov    %dl,0x37(%eax)


	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  10118d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101190:	66 c7 45 ea 37 00    	movw   $0x37,-0x16(%ebp)
  101196:	89 45 ec             	mov    %eax,-0x14(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  101199:	0f 01 55 ea          	lgdtl  -0x16(%ebp)
  10119d:	66 c7 45 f6 30 00    	movw   $0x30,-0xa(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1011a3:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  1011a7:	0f 00 d8             	ltr    %ax
	ltr(CPU_GDT_TSS);
	
	// Reload all segment registers.
	//asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
	//asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1011aa:	b8 10 00 00 00       	mov    $0x10,%eax
  1011af:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  1011b1:	b8 10 00 00 00       	mov    $0x10,%eax
  1011b6:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1011b8:	b8 10 00 00 00       	mov    $0x10,%eax
  1011bd:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  1011bf:	ea c6 11 10 00 08 00 	ljmp   $0x8,$0x1011c6

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  1011c6:	b8 00 00 00 00       	mov    $0x0,%eax
  1011cb:	0f 00 d0             	lldt   %ax
}
  1011ce:	83 c4 14             	add    $0x14,%esp
  1011d1:	5b                   	pop    %ebx
  1011d2:	5d                   	pop    %ebp
  1011d3:	c3                   	ret    

001011d4 <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  1011d4:	55                   	push   %ebp
  1011d5:	89 e5                	mov    %esp,%ebp
  1011d7:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  1011da:	e8 dd f8 ff ff       	call   100abc <mem_alloc>
  1011df:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  1011e2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1011e6:	75 24                	jne    10120c <cpu_alloc+0x38>
  1011e8:	c7 44 24 0c 77 51 10 	movl   $0x105177,0xc(%esp)
  1011ef:	00 
  1011f0:	c7 44 24 08 55 51 10 	movl   $0x105155,0x8(%esp)
  1011f7:	00 
  1011f8:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  1011ff:	00 
  101200:	c7 04 24 7f 51 10 00 	movl   $0x10517f,(%esp)
  101207:	e8 24 f2 ff ff       	call   100430 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  10120c:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10120f:	a1 58 d3 30 00       	mov    0x30d358,%eax
  101214:	89 d1                	mov    %edx,%ecx
  101216:	29 c1                	sub    %eax,%ecx
  101218:	89 c8                	mov    %ecx,%eax
  10121a:	c1 f8 03             	sar    $0x3,%eax
  10121d:	c1 e0 0c             	shl    $0xc,%eax
  101220:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  101223:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10122a:	00 
  10122b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101232:	00 
  101233:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101236:	89 04 24             	mov    %eax,(%esp)
  101239:	e8 2d 36 00 00       	call   10486b <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  10123e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101241:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101248:	00 
  101249:	c7 44 24 04 00 60 10 	movl   $0x106000,0x4(%esp)
  101250:	00 
  101251:	89 04 24             	mov    %eax,(%esp)
  101254:	e8 86 36 00 00       	call   1048df <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  101259:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10125c:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  101263:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  101266:	a1 00 70 10 00       	mov    0x107000,%eax
  10126b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10126e:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  101270:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101273:	05 a8 00 00 00       	add    $0xa8,%eax
  101278:	a3 00 70 10 00       	mov    %eax,0x107000

	return c;
  10127d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  101280:	c9                   	leave  
  101281:	c3                   	ret    

00101282 <cpu_bootothers>:

void
cpu_bootothers(void)
{
  101282:	55                   	push   %ebp
  101283:	89 e5                	mov    %esp,%ebp
  101285:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  101288:	e8 0e fe ff ff       	call   10109b <cpu_onboot>
  10128d:	85 c0                	test   %eax,%eax
  10128f:	75 1f                	jne    1012b0 <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  101291:	e8 b2 fd ff ff       	call   101048 <cpu_cur>
  101296:	05 b0 00 00 00       	add    $0xb0,%eax
  10129b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1012a2:	00 
  1012a3:	89 04 24             	mov    %eax,(%esp)
  1012a6:	e8 83 fd ff ff       	call   10102e <xchg>
		return;
  1012ab:	e9 91 00 00 00       	jmp    101341 <cpu_bootothers+0xbf>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  1012b0:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  1012b7:	b8 6a 00 00 00       	mov    $0x6a,%eax
  1012bc:	89 44 24 08          	mov    %eax,0x8(%esp)
  1012c0:	c7 44 24 04 b2 75 10 	movl   $0x1075b2,0x4(%esp)
  1012c7:	00 
  1012c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012cb:	89 04 24             	mov    %eax,(%esp)
  1012ce:	e8 0c 36 00 00       	call   1048df <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  1012d3:	c7 45 f4 00 60 10 00 	movl   $0x106000,-0xc(%ebp)
  1012da:	eb 5f                	jmp    10133b <cpu_bootothers+0xb9>
		if(c == cpu_cur())  // We''ve started already.
  1012dc:	e8 67 fd ff ff       	call   101048 <cpu_cur>
  1012e1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1012e4:	74 48                	je     10132e <cpu_bootothers+0xac>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  1012e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012e9:	83 e8 04             	sub    $0x4,%eax
  1012ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1012ef:	81 c2 00 10 00 00    	add    $0x1000,%edx
  1012f5:	89 10                	mov    %edx,(%eax)
		*(void**)(code-8) = init;
  1012f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012fa:	83 e8 08             	sub    $0x8,%eax
  1012fd:	c7 00 91 00 10 00    	movl   $0x100091,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  101303:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101306:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101309:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  101310:	0f b6 c0             	movzbl %al,%eax
  101313:	89 54 24 04          	mov    %edx,0x4(%esp)
  101317:	89 04 24             	mov    %eax,(%esp)
  10131a:	e8 5e 29 00 00       	call   103c7d <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  10131f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101322:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  101328:	85 c0                	test   %eax,%eax
  10132a:	74 f3                	je     10131f <cpu_bootothers+0x9d>
  10132c:	eb 01                	jmp    10132f <cpu_bootothers+0xad>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
		if(c == cpu_cur())  // We''ve started already.
			continue;
  10132e:	90                   	nop
	uint8_t *code = (uint8_t*)0x1000;
	memmove(code, _binary_obj_boot_bootother_start,
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  10132f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101332:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101338:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10133b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10133f:	75 9b                	jne    1012dc <cpu_bootothers+0x5a>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
			;
	}
}
  101341:	c9                   	leave  
  101342:	c3                   	ret    

00101343 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101343:	55                   	push   %ebp
  101344:	89 e5                	mov    %esp,%ebp
  101346:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101349:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10134c:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10134f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101352:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101355:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10135a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10135d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101360:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101366:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10136b:	74 24                	je     101391 <cpu_cur+0x4e>
  10136d:	c7 44 24 0c a0 51 10 	movl   $0x1051a0,0xc(%esp)
  101374:	00 
  101375:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  10137c:	00 
  10137d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101384:	00 
  101385:	c7 04 24 cb 51 10 00 	movl   $0x1051cb,(%esp)
  10138c:	e8 9f f0 ff ff       	call   100430 <debug_panic>
	return c;
  101391:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101394:	c9                   	leave  
  101395:	c3                   	ret    

00101396 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101396:	55                   	push   %ebp
  101397:	89 e5                	mov    %esp,%ebp
  101399:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10139c:	e8 a2 ff ff ff       	call   101343 <cpu_cur>
  1013a1:	3d 00 60 10 00       	cmp    $0x106000,%eax
  1013a6:	0f 94 c0             	sete   %al
  1013a9:	0f b6 c0             	movzbl %al,%eax
}
  1013ac:	c9                   	leave  
  1013ad:	c3                   	ret    

001013ae <trap_init_idt>:

extern uint32_t vectors[];

static void
trap_init_idt(void)
{
  1013ae:	55                   	push   %ebp
  1013af:	89 e5                	mov    %esp,%ebp
  1013b1:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  1013b4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1013bb:	e9 bc 00 00 00       	jmp    10147c <trap_init_idt+0xce>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
  1013c0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1013c3:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1013c6:	8b 14 95 10 70 10 00 	mov    0x107010(,%edx,4),%edx
  1013cd:	66 89 14 c5 40 88 10 	mov    %dx,0x108840(,%eax,8)
  1013d4:	00 
  1013d5:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1013d8:	66 c7 04 c5 42 88 10 	movw   $0x8,0x108842(,%eax,8)
  1013df:	00 08 00 
  1013e2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1013e5:	0f b6 14 c5 44 88 10 	movzbl 0x108844(,%eax,8),%edx
  1013ec:	00 
  1013ed:	83 e2 e0             	and    $0xffffffe0,%edx
  1013f0:	88 14 c5 44 88 10 00 	mov    %dl,0x108844(,%eax,8)
  1013f7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1013fa:	0f b6 14 c5 44 88 10 	movzbl 0x108844(,%eax,8),%edx
  101401:	00 
  101402:	83 e2 1f             	and    $0x1f,%edx
  101405:	88 14 c5 44 88 10 00 	mov    %dl,0x108844(,%eax,8)
  10140c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10140f:	0f b6 14 c5 45 88 10 	movzbl 0x108845(,%eax,8),%edx
  101416:	00 
  101417:	83 ca 0f             	or     $0xf,%edx
  10141a:	88 14 c5 45 88 10 00 	mov    %dl,0x108845(,%eax,8)
  101421:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101424:	0f b6 14 c5 45 88 10 	movzbl 0x108845(,%eax,8),%edx
  10142b:	00 
  10142c:	83 e2 ef             	and    $0xffffffef,%edx
  10142f:	88 14 c5 45 88 10 00 	mov    %dl,0x108845(,%eax,8)
  101436:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101439:	0f b6 14 c5 45 88 10 	movzbl 0x108845(,%eax,8),%edx
  101440:	00 
  101441:	83 ca 60             	or     $0x60,%edx
  101444:	88 14 c5 45 88 10 00 	mov    %dl,0x108845(,%eax,8)
  10144b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10144e:	0f b6 14 c5 45 88 10 	movzbl 0x108845(,%eax,8),%edx
  101455:	00 
  101456:	83 ca 80             	or     $0xffffff80,%edx
  101459:	88 14 c5 45 88 10 00 	mov    %dl,0x108845(,%eax,8)
  101460:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101463:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101466:	8b 14 95 10 70 10 00 	mov    0x107010(,%edx,4),%edx
  10146d:	c1 ea 10             	shr    $0x10,%edx
  101470:	66 89 14 c5 46 88 10 	mov    %dx,0x108846(,%eax,8)
  101477:	00 
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  101478:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  10147c:	83 7d fc 13          	cmpl   $0x13,-0x4(%ebp)
  101480:	0f 8e 3a ff ff ff    	jle    1013c0 <trap_init_idt+0x12>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
	}
	SETGATE(idt[30], 1, CPU_GDT_KCODE, vectors[30], 3);
  101486:	a1 88 70 10 00       	mov    0x107088,%eax
  10148b:	66 a3 30 89 10 00    	mov    %ax,0x108930
  101491:	66 c7 05 32 89 10 00 	movw   $0x8,0x108932
  101498:	08 00 
  10149a:	0f b6 05 34 89 10 00 	movzbl 0x108934,%eax
  1014a1:	83 e0 e0             	and    $0xffffffe0,%eax
  1014a4:	a2 34 89 10 00       	mov    %al,0x108934
  1014a9:	0f b6 05 34 89 10 00 	movzbl 0x108934,%eax
  1014b0:	83 e0 1f             	and    $0x1f,%eax
  1014b3:	a2 34 89 10 00       	mov    %al,0x108934
  1014b8:	0f b6 05 35 89 10 00 	movzbl 0x108935,%eax
  1014bf:	83 c8 0f             	or     $0xf,%eax
  1014c2:	a2 35 89 10 00       	mov    %al,0x108935
  1014c7:	0f b6 05 35 89 10 00 	movzbl 0x108935,%eax
  1014ce:	83 e0 ef             	and    $0xffffffef,%eax
  1014d1:	a2 35 89 10 00       	mov    %al,0x108935
  1014d6:	0f b6 05 35 89 10 00 	movzbl 0x108935,%eax
  1014dd:	83 c8 60             	or     $0x60,%eax
  1014e0:	a2 35 89 10 00       	mov    %al,0x108935
  1014e5:	0f b6 05 35 89 10 00 	movzbl 0x108935,%eax
  1014ec:	83 c8 80             	or     $0xffffff80,%eax
  1014ef:	a2 35 89 10 00       	mov    %al,0x108935
  1014f4:	a1 88 70 10 00       	mov    0x107088,%eax
  1014f9:	c1 e8 10             	shr    $0x10,%eax
  1014fc:	66 a3 36 89 10 00    	mov    %ax,0x108936
}
  101502:	c9                   	leave  
  101503:	c3                   	ret    

00101504 <trap_init>:

void
trap_init(void)
{
  101504:	55                   	push   %ebp
  101505:	89 e5                	mov    %esp,%ebp
  101507:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  10150a:	e8 87 fe ff ff       	call   101396 <cpu_onboot>
  10150f:	85 c0                	test   %eax,%eax
  101511:	74 05                	je     101518 <trap_init+0x14>
		trap_init_idt();
  101513:	e8 96 fe ff ff       	call   1013ae <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  101518:	0f 01 1d 04 70 10 00 	lidtl  0x107004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  10151f:	e8 72 fe ff ff       	call   101396 <cpu_onboot>
  101524:	85 c0                	test   %eax,%eax
  101526:	74 05                	je     10152d <trap_init+0x29>
		trap_check_kernel();
  101528:	e8 9e 02 00 00       	call   1017cb <trap_check_kernel>
}
  10152d:	c9                   	leave  
  10152e:	c3                   	ret    

0010152f <trap_name>:

const char *trap_name(int trapno)
{
  10152f:	55                   	push   %ebp
  101530:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101532:	8b 45 08             	mov    0x8(%ebp),%eax
  101535:	83 f8 13             	cmp    $0x13,%eax
  101538:	77 0c                	ja     101546 <trap_name+0x17>
		return excnames[trapno];
  10153a:	8b 45 08             	mov    0x8(%ebp),%eax
  10153d:	8b 04 85 a0 55 10 00 	mov    0x1055a0(,%eax,4),%eax
  101544:	eb 25                	jmp    10156b <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  101546:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  10154a:	75 07                	jne    101553 <trap_name+0x24>
		return "System call";
  10154c:	b8 d8 51 10 00       	mov    $0x1051d8,%eax
  101551:	eb 18                	jmp    10156b <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  101553:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  101557:	7e 0d                	jle    101566 <trap_name+0x37>
  101559:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  10155d:	7f 07                	jg     101566 <trap_name+0x37>
		return "Hardware Interrupt";
  10155f:	b8 e4 51 10 00       	mov    $0x1051e4,%eax
  101564:	eb 05                	jmp    10156b <trap_name+0x3c>
	return "(unknown trap)";
  101566:	b8 f7 51 10 00       	mov    $0x1051f7,%eax
}
  10156b:	5d                   	pop    %ebp
  10156c:	c3                   	ret    

0010156d <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  10156d:	55                   	push   %ebp
  10156e:	89 e5                	mov    %esp,%ebp
  101570:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  101573:	8b 45 08             	mov    0x8(%ebp),%eax
  101576:	8b 00                	mov    (%eax),%eax
  101578:	89 44 24 04          	mov    %eax,0x4(%esp)
  10157c:	c7 04 24 06 52 10 00 	movl   $0x105206,(%esp)
  101583:	e8 fe 30 00 00       	call   104686 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  101588:	8b 45 08             	mov    0x8(%ebp),%eax
  10158b:	8b 40 04             	mov    0x4(%eax),%eax
  10158e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101592:	c7 04 24 15 52 10 00 	movl   $0x105215,(%esp)
  101599:	e8 e8 30 00 00       	call   104686 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  10159e:	8b 45 08             	mov    0x8(%ebp),%eax
  1015a1:	8b 40 08             	mov    0x8(%eax),%eax
  1015a4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1015a8:	c7 04 24 24 52 10 00 	movl   $0x105224,(%esp)
  1015af:	e8 d2 30 00 00       	call   104686 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  1015b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1015b7:	8b 40 10             	mov    0x10(%eax),%eax
  1015ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  1015be:	c7 04 24 33 52 10 00 	movl   $0x105233,(%esp)
  1015c5:	e8 bc 30 00 00       	call   104686 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  1015ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1015cd:	8b 40 14             	mov    0x14(%eax),%eax
  1015d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1015d4:	c7 04 24 42 52 10 00 	movl   $0x105242,(%esp)
  1015db:	e8 a6 30 00 00       	call   104686 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  1015e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1015e3:	8b 40 18             	mov    0x18(%eax),%eax
  1015e6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1015ea:	c7 04 24 51 52 10 00 	movl   $0x105251,(%esp)
  1015f1:	e8 90 30 00 00       	call   104686 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1015f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1015f9:	8b 40 1c             	mov    0x1c(%eax),%eax
  1015fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  101600:	c7 04 24 60 52 10 00 	movl   $0x105260,(%esp)
  101607:	e8 7a 30 00 00       	call   104686 <cprintf>
}
  10160c:	c9                   	leave  
  10160d:	c3                   	ret    

0010160e <trap_print>:

void
trap_print(trapframe *tf)
{
  10160e:	55                   	push   %ebp
  10160f:	89 e5                	mov    %esp,%ebp
  101611:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  101614:	8b 45 08             	mov    0x8(%ebp),%eax
  101617:	89 44 24 04          	mov    %eax,0x4(%esp)
  10161b:	c7 04 24 6f 52 10 00 	movl   $0x10526f,(%esp)
  101622:	e8 5f 30 00 00       	call   104686 <cprintf>
	trap_print_regs(&tf->regs);
  101627:	8b 45 08             	mov    0x8(%ebp),%eax
  10162a:	89 04 24             	mov    %eax,(%esp)
  10162d:	e8 3b ff ff ff       	call   10156d <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  101632:	8b 45 08             	mov    0x8(%ebp),%eax
  101635:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101639:	0f b7 c0             	movzwl %ax,%eax
  10163c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101640:	c7 04 24 81 52 10 00 	movl   $0x105281,(%esp)
  101647:	e8 3a 30 00 00       	call   104686 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  10164c:	8b 45 08             	mov    0x8(%ebp),%eax
  10164f:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101653:	0f b7 c0             	movzwl %ax,%eax
  101656:	89 44 24 04          	mov    %eax,0x4(%esp)
  10165a:	c7 04 24 94 52 10 00 	movl   $0x105294,(%esp)
  101661:	e8 20 30 00 00       	call   104686 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101666:	8b 45 08             	mov    0x8(%ebp),%eax
  101669:	8b 40 30             	mov    0x30(%eax),%eax
  10166c:	89 04 24             	mov    %eax,(%esp)
  10166f:	e8 bb fe ff ff       	call   10152f <trap_name>
  101674:	8b 55 08             	mov    0x8(%ebp),%edx
  101677:	8b 52 30             	mov    0x30(%edx),%edx
  10167a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10167e:	89 54 24 04          	mov    %edx,0x4(%esp)
  101682:	c7 04 24 a7 52 10 00 	movl   $0x1052a7,(%esp)
  101689:	e8 f8 2f 00 00       	call   104686 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  10168e:	8b 45 08             	mov    0x8(%ebp),%eax
  101691:	8b 40 34             	mov    0x34(%eax),%eax
  101694:	89 44 24 04          	mov    %eax,0x4(%esp)
  101698:	c7 04 24 b9 52 10 00 	movl   $0x1052b9,(%esp)
  10169f:	e8 e2 2f 00 00       	call   104686 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1016a4:	8b 45 08             	mov    0x8(%ebp),%eax
  1016a7:	8b 40 38             	mov    0x38(%eax),%eax
  1016aa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016ae:	c7 04 24 c8 52 10 00 	movl   $0x1052c8,(%esp)
  1016b5:	e8 cc 2f 00 00       	call   104686 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  1016ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1016bd:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1016c1:	0f b7 c0             	movzwl %ax,%eax
  1016c4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016c8:	c7 04 24 d7 52 10 00 	movl   $0x1052d7,(%esp)
  1016cf:	e8 b2 2f 00 00       	call   104686 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  1016d4:	8b 45 08             	mov    0x8(%ebp),%eax
  1016d7:	8b 40 40             	mov    0x40(%eax),%eax
  1016da:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016de:	c7 04 24 ea 52 10 00 	movl   $0x1052ea,(%esp)
  1016e5:	e8 9c 2f 00 00       	call   104686 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1016ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1016ed:	8b 40 44             	mov    0x44(%eax),%eax
  1016f0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016f4:	c7 04 24 f9 52 10 00 	movl   $0x1052f9,(%esp)
  1016fb:	e8 86 2f 00 00       	call   104686 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  101700:	8b 45 08             	mov    0x8(%ebp),%eax
  101703:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101707:	0f b7 c0             	movzwl %ax,%eax
  10170a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10170e:	c7 04 24 08 53 10 00 	movl   $0x105308,(%esp)
  101715:	e8 6c 2f 00 00       	call   104686 <cprintf>
}
  10171a:	c9                   	leave  
  10171b:	c3                   	ret    

0010171c <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  10171c:	55                   	push   %ebp
  10171d:	89 e5                	mov    %esp,%ebp
  10171f:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  101722:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  101723:	e8 1b fc ff ff       	call   101343 <cpu_cur>
  101728:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  10172b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10172e:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101734:	85 c0                	test   %eax,%eax
  101736:	74 1e                	je     101756 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  101738:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10173b:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  101741:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101744:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  10174a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10174e:	8b 45 08             	mov    0x8(%ebp),%eax
  101751:	89 04 24             	mov    %eax,(%esp)
  101754:	ff d2                	call   *%edx

	// Lab 2: your trap handling code here!

	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
  101756:	c7 04 24 c0 d2 10 00 	movl   $0x10d2c0,(%esp)
  10175d:	e8 b7 09 00 00       	call   102119 <spinlock_holding>
  101762:	85 c0                	test   %eax,%eax
  101764:	74 0c                	je     101772 <trap+0x56>
		spinlock_release(&cons_lock);
  101766:	c7 04 24 c0 d2 10 00 	movl   $0x10d2c0,(%esp)
  10176d:	e8 4d 09 00 00       	call   1020bf <spinlock_release>
	trap_print(tf);
  101772:	8b 45 08             	mov    0x8(%ebp),%eax
  101775:	89 04 24             	mov    %eax,(%esp)
  101778:	e8 91 fe ff ff       	call   10160e <trap_print>
	panic("unhandled trap");
  10177d:	c7 44 24 08 1b 53 10 	movl   $0x10531b,0x8(%esp)
  101784:	00 
  101785:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
  10178c:	00 
  10178d:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  101794:	e8 97 ec ff ff       	call   100430 <debug_panic>

00101799 <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101799:	55                   	push   %ebp
  10179a:	89 e5                	mov    %esp,%ebp
  10179c:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  10179f:	8b 45 0c             	mov    0xc(%ebp),%eax
  1017a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  1017a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1017a8:	8b 00                	mov    (%eax),%eax
  1017aa:	89 c2                	mov    %eax,%edx
  1017ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1017af:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  1017b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1017b5:	8b 40 30             	mov    0x30(%eax),%eax
  1017b8:	89 c2                	mov    %eax,%edx
  1017ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1017bd:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  1017c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1017c3:	89 04 24             	mov    %eax,(%esp)
  1017c6:	e8 b5 58 00 00       	call   107080 <trap_return>

001017cb <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  1017cb:	55                   	push   %ebp
  1017cc:	89 e5                	mov    %esp,%ebp
  1017ce:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1017d1:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  1017d4:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  1017d8:	0f b7 c0             	movzwl %ax,%eax
  1017db:	83 e0 03             	and    $0x3,%eax
  1017de:	85 c0                	test   %eax,%eax
  1017e0:	74 24                	je     101806 <trap_check_kernel+0x3b>
  1017e2:	c7 44 24 0c 36 53 10 	movl   $0x105336,0xc(%esp)
  1017e9:	00 
  1017ea:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  1017f1:	00 
  1017f2:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  1017f9:	00 
  1017fa:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  101801:	e8 2a ec ff ff       	call   100430 <debug_panic>

	cpu *c = cpu_cur();
  101806:	e8 38 fb ff ff       	call   101343 <cpu_cur>
  10180b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  10180e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101811:	c7 80 a0 00 00 00 99 	movl   $0x101799,0xa0(%eax)
  101818:	17 10 00 
	trap_check(&c->recoverdata);
  10181b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10181e:	05 a4 00 00 00       	add    $0xa4,%eax
  101823:	89 04 24             	mov    %eax,(%esp)
  101826:	e8 96 00 00 00       	call   1018c1 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  10182b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10182e:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101835:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  101838:	c7 04 24 4c 53 10 00 	movl   $0x10534c,(%esp)
  10183f:	e8 42 2e 00 00       	call   104686 <cprintf>
}
  101844:	c9                   	leave  
  101845:	c3                   	ret    

00101846 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101846:	55                   	push   %ebp
  101847:	89 e5                	mov    %esp,%ebp
  101849:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10184c:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  10184f:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101853:	0f b7 c0             	movzwl %ax,%eax
  101856:	83 e0 03             	and    $0x3,%eax
  101859:	83 f8 03             	cmp    $0x3,%eax
  10185c:	74 24                	je     101882 <trap_check_user+0x3c>
  10185e:	c7 44 24 0c 6c 53 10 	movl   $0x10536c,0xc(%esp)
  101865:	00 
  101866:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  10186d:	00 
  10186e:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
  101875:	00 
  101876:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  10187d:	e8 ae eb ff ff       	call   100430 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101882:	c7 45 f0 00 60 10 00 	movl   $0x106000,-0x10(%ebp)
	c->recover = trap_check_recover;
  101889:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10188c:	c7 80 a0 00 00 00 99 	movl   $0x101799,0xa0(%eax)
  101893:	17 10 00 
	trap_check(&c->recoverdata);
  101896:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101899:	05 a4 00 00 00       	add    $0xa4,%eax
  10189e:	89 04 24             	mov    %eax,(%esp)
  1018a1:	e8 1b 00 00 00       	call   1018c1 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1018a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1018a9:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1018b0:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  1018b3:	c7 04 24 81 53 10 00 	movl   $0x105381,(%esp)
  1018ba:	e8 c7 2d 00 00       	call   104686 <cprintf>
}
  1018bf:	c9                   	leave  
  1018c0:	c3                   	ret    

001018c1 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  1018c1:	55                   	push   %ebp
  1018c2:	89 e5                	mov    %esp,%ebp
  1018c4:	57                   	push   %edi
  1018c5:	56                   	push   %esi
  1018c6:	53                   	push   %ebx
  1018c7:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  1018ca:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  1018d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1018d4:	8d 55 d8             	lea    -0x28(%ebp),%edx
  1018d7:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  1018d9:	c7 45 d8 e7 18 10 00 	movl   $0x1018e7,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1018e0:	b8 00 00 00 00       	mov    $0x0,%eax
  1018e5:	f7 f0                	div    %eax

001018e7 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1018e7:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1018ea:	85 c0                	test   %eax,%eax
  1018ec:	74 24                	je     101912 <after_div0+0x2b>
  1018ee:	c7 44 24 0c 9f 53 10 	movl   $0x10539f,0xc(%esp)
  1018f5:	00 
  1018f6:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  1018fd:	00 
  1018fe:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
  101905:	00 
  101906:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  10190d:	e8 1e eb ff ff       	call   100430 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101912:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101915:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  10191a:	74 24                	je     101940 <after_div0+0x59>
  10191c:	c7 44 24 0c b7 53 10 	movl   $0x1053b7,0xc(%esp)
  101923:	00 
  101924:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  10192b:	00 
  10192c:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  101933:	00 
  101934:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  10193b:	e8 f0 ea ff ff       	call   100430 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101940:	c7 45 d8 48 19 10 00 	movl   $0x101948,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  101947:	cc                   	int3   

00101948 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101948:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10194b:	83 f8 03             	cmp    $0x3,%eax
  10194e:	74 24                	je     101974 <after_breakpoint+0x2c>
  101950:	c7 44 24 0c cc 53 10 	movl   $0x1053cc,0xc(%esp)
  101957:	00 
  101958:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  10195f:	00 
  101960:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  101967:	00 
  101968:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  10196f:	e8 bc ea ff ff       	call   100430 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101974:	c7 45 d8 83 19 10 00 	movl   $0x101983,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  10197b:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101980:	01 c0                	add    %eax,%eax
  101982:	ce                   	into   

00101983 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101983:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101986:	83 f8 04             	cmp    $0x4,%eax
  101989:	74 24                	je     1019af <after_overflow+0x2c>
  10198b:	c7 44 24 0c e3 53 10 	movl   $0x1053e3,0xc(%esp)
  101992:	00 
  101993:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  10199a:	00 
  10199b:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  1019a2:	00 
  1019a3:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  1019aa:	e8 81 ea ff ff       	call   100430 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  1019af:	c7 45 d8 cc 19 10 00 	movl   $0x1019cc,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  1019b6:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  1019bd:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  1019c4:	b8 00 00 00 00       	mov    $0x0,%eax
  1019c9:	62 45 d0             	bound  %eax,-0x30(%ebp)

001019cc <after_bound>:
	assert(args.trapno == T_BOUND);
  1019cc:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1019cf:	83 f8 05             	cmp    $0x5,%eax
  1019d2:	74 24                	je     1019f8 <after_bound+0x2c>
  1019d4:	c7 44 24 0c fa 53 10 	movl   $0x1053fa,0xc(%esp)
  1019db:	00 
  1019dc:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  1019e3:	00 
  1019e4:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
  1019eb:	00 
  1019ec:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  1019f3:	e8 38 ea ff ff       	call   100430 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  1019f8:	c7 45 d8 01 1a 10 00 	movl   $0x101a01,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  1019ff:	0f 0b                	ud2    

00101a01 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101a01:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101a04:	83 f8 06             	cmp    $0x6,%eax
  101a07:	74 24                	je     101a2d <after_illegal+0x2c>
  101a09:	c7 44 24 0c 11 54 10 	movl   $0x105411,0xc(%esp)
  101a10:	00 
  101a11:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  101a18:	00 
  101a19:	c7 44 24 04 f5 00 00 	movl   $0xf5,0x4(%esp)
  101a20:	00 
  101a21:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  101a28:	e8 03 ea ff ff       	call   100430 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101a2d:	c7 45 d8 3b 1a 10 00 	movl   $0x101a3b,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101a34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101a39:	8e e0                	mov    %eax,%fs

00101a3b <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101a3b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101a3e:	83 f8 0d             	cmp    $0xd,%eax
  101a41:	74 24                	je     101a67 <after_gpfault+0x2c>
  101a43:	c7 44 24 0c 28 54 10 	movl   $0x105428,0xc(%esp)
  101a4a:	00 
  101a4b:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  101a52:	00 
  101a53:	c7 44 24 04 fa 00 00 	movl   $0xfa,0x4(%esp)
  101a5a:	00 
  101a5b:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  101a62:	e8 c9 e9 ff ff       	call   100430 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101a67:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  101a6a:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101a6e:	0f b7 c0             	movzwl %ax,%eax
  101a71:	83 e0 03             	and    $0x3,%eax
  101a74:	85 c0                	test   %eax,%eax
  101a76:	74 3a                	je     101ab2 <after_priv+0x2c>
		args.reip = after_priv;
  101a78:	c7 45 d8 86 1a 10 00 	movl   $0x101a86,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101a7f:	0f 01 1d 04 70 10 00 	lidtl  0x107004

00101a86 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101a86:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101a89:	83 f8 0d             	cmp    $0xd,%eax
  101a8c:	74 24                	je     101ab2 <after_priv+0x2c>
  101a8e:	c7 44 24 0c 28 54 10 	movl   $0x105428,0xc(%esp)
  101a95:	00 
  101a96:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  101a9d:	00 
  101a9e:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
  101aa5:	00 
  101aa6:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  101aad:	e8 7e e9 ff ff       	call   100430 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101ab2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101ab5:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101aba:	74 24                	je     101ae0 <after_priv+0x5a>
  101abc:	c7 44 24 0c b7 53 10 	movl   $0x1053b7,0xc(%esp)
  101ac3:	00 
  101ac4:	c7 44 24 08 b6 51 10 	movl   $0x1051b6,0x8(%esp)
  101acb:	00 
  101acc:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
  101ad3:	00 
  101ad4:	c7 04 24 2a 53 10 00 	movl   $0x10532a,(%esp)
  101adb:	e8 50 e9 ff ff       	call   100430 <debug_panic>
	//cprintf("sfsfsfsfsfsfsfsfsf\n");
	*argsp = NULL;	// recovery mechanism not needed anymore
  101ae0:	8b 45 08             	mov    0x8(%ebp),%eax
  101ae3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101ae9:	83 c4 3c             	add    $0x3c,%esp
  101aec:	5b                   	pop    %ebx
  101aed:	5e                   	pop    %esi
  101aee:	5f                   	pop    %edi
  101aef:	5d                   	pop    %ebp
  101af0:	c3                   	ret    
  101af1:	90                   	nop

00101af2 <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  101af2:	6a 00                	push   $0x0
  101af4:	6a 00                	push   $0x0
  101af6:	e9 69 55 00 00       	jmp    107064 <_alltraps>
  101afb:	90                   	nop

00101afc <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  101afc:	6a 00                	push   $0x0
  101afe:	6a 01                	push   $0x1
  101b00:	e9 5f 55 00 00       	jmp    107064 <_alltraps>
  101b05:	90                   	nop

00101b06 <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  101b06:	6a 00                	push   $0x0
  101b08:	6a 02                	push   $0x2
  101b0a:	e9 55 55 00 00       	jmp    107064 <_alltraps>
  101b0f:	90                   	nop

00101b10 <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  101b10:	6a 00                	push   $0x0
  101b12:	6a 03                	push   $0x3
  101b14:	e9 4b 55 00 00       	jmp    107064 <_alltraps>
  101b19:	90                   	nop

00101b1a <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  101b1a:	6a 00                	push   $0x0
  101b1c:	6a 04                	push   $0x4
  101b1e:	e9 41 55 00 00       	jmp    107064 <_alltraps>
  101b23:	90                   	nop

00101b24 <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  101b24:	6a 00                	push   $0x0
  101b26:	6a 05                	push   $0x5
  101b28:	e9 37 55 00 00       	jmp    107064 <_alltraps>
  101b2d:	90                   	nop

00101b2e <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  101b2e:	6a 00                	push   $0x0
  101b30:	6a 06                	push   $0x6
  101b32:	e9 2d 55 00 00       	jmp    107064 <_alltraps>
  101b37:	90                   	nop

00101b38 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  101b38:	6a 00                	push   $0x0
  101b3a:	6a 07                	push   $0x7
  101b3c:	e9 23 55 00 00       	jmp    107064 <_alltraps>
  101b41:	90                   	nop

00101b42 <vector8>:
TRAPHANDLER(vector8, 8)
  101b42:	6a 08                	push   $0x8
  101b44:	e9 1b 55 00 00       	jmp    107064 <_alltraps>
  101b49:	90                   	nop

00101b4a <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  101b4a:	6a 00                	push   $0x0
  101b4c:	6a 09                	push   $0x9
  101b4e:	e9 11 55 00 00       	jmp    107064 <_alltraps>
  101b53:	90                   	nop

00101b54 <vector10>:
TRAPHANDLER(vector10, 10)
  101b54:	6a 0a                	push   $0xa
  101b56:	e9 09 55 00 00       	jmp    107064 <_alltraps>
  101b5b:	90                   	nop

00101b5c <vector11>:
TRAPHANDLER(vector11, 11)
  101b5c:	6a 0b                	push   $0xb
  101b5e:	e9 01 55 00 00       	jmp    107064 <_alltraps>
  101b63:	90                   	nop

00101b64 <vector12>:
TRAPHANDLER(vector12, 12)
  101b64:	6a 0c                	push   $0xc
  101b66:	e9 f9 54 00 00       	jmp    107064 <_alltraps>
  101b6b:	90                   	nop

00101b6c <vector13>:
TRAPHANDLER(vector13, 13)
  101b6c:	6a 0d                	push   $0xd
  101b6e:	e9 f1 54 00 00       	jmp    107064 <_alltraps>
  101b73:	90                   	nop

00101b74 <vector14>:
TRAPHANDLER(vector14, 14)
  101b74:	6a 0e                	push   $0xe
  101b76:	e9 e9 54 00 00       	jmp    107064 <_alltraps>
  101b7b:	90                   	nop

00101b7c <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101b7c:	6a 00                	push   $0x0
  101b7e:	6a 0f                	push   $0xf
  101b80:	e9 df 54 00 00       	jmp    107064 <_alltraps>
  101b85:	90                   	nop

00101b86 <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  101b86:	6a 00                	push   $0x0
  101b88:	6a 10                	push   $0x10
  101b8a:	e9 d5 54 00 00       	jmp    107064 <_alltraps>
  101b8f:	90                   	nop

00101b90 <vector17>:
TRAPHANDLER(vector17, 17)
  101b90:	6a 11                	push   $0x11
  101b92:	e9 cd 54 00 00       	jmp    107064 <_alltraps>
  101b97:	90                   	nop

00101b98 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  101b98:	6a 00                	push   $0x0
  101b9a:	6a 12                	push   $0x12
  101b9c:	e9 c3 54 00 00       	jmp    107064 <_alltraps>
  101ba1:	90                   	nop

00101ba2 <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  101ba2:	6a 00                	push   $0x0
  101ba4:	6a 13                	push   $0x13
  101ba6:	e9 b9 54 00 00       	jmp    107064 <_alltraps>
  101bab:	90                   	nop

00101bac <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101bac:	6a 00                	push   $0x0
  101bae:	6a 1e                	push   $0x1e
  101bb0:	e9 af 54 00 00       	jmp    107064 <_alltraps>

00101bb5 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101bb5:	55                   	push   %ebp
  101bb6:	89 e5                	mov    %esp,%ebp
  101bb8:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101bbb:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101bbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101bc1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101bc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101bc7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101bcc:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101bcf:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101bd2:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101bd8:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101bdd:	74 24                	je     101c03 <cpu_cur+0x4e>
  101bdf:	c7 44 24 0c f0 55 10 	movl   $0x1055f0,0xc(%esp)
  101be6:	00 
  101be7:	c7 44 24 08 06 56 10 	movl   $0x105606,0x8(%esp)
  101bee:	00 
  101bef:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101bf6:	00 
  101bf7:	c7 04 24 1b 56 10 00 	movl   $0x10561b,(%esp)
  101bfe:	e8 2d e8 ff ff       	call   100430 <debug_panic>
	return c;
  101c03:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101c06:	c9                   	leave  
  101c07:	c3                   	ret    

00101c08 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101c08:	55                   	push   %ebp
  101c09:	89 e5                	mov    %esp,%ebp
  101c0b:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101c0e:	e8 a2 ff ff ff       	call   101bb5 <cpu_cur>
  101c13:	3d 00 60 10 00       	cmp    $0x106000,%eax
  101c18:	0f 94 c0             	sete   %al
  101c1b:	0f b6 c0             	movzbl %al,%eax
}
  101c1e:	c9                   	leave  
  101c1f:	c3                   	ret    

00101c20 <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  101c20:	55                   	push   %ebp
  101c21:	89 e5                	mov    %esp,%ebp
  101c23:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  101c26:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	for (i = 0; i < len; i++)
  101c2d:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  101c34:	eb 13                	jmp    101c49 <sum+0x29>
		sum += addr[i];
  101c36:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101c39:	03 45 08             	add    0x8(%ebp),%eax
  101c3c:	0f b6 00             	movzbl (%eax),%eax
  101c3f:	0f b6 c0             	movzbl %al,%eax
  101c42:	01 45 fc             	add    %eax,-0x4(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  101c45:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  101c49:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101c4c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  101c4f:	7c e5                	jl     101c36 <sum+0x16>
		sum += addr[i];
	return sum;
  101c51:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101c54:	c9                   	leave  
  101c55:	c3                   	ret    

00101c56 <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  101c56:	55                   	push   %ebp
  101c57:	89 e5                	mov    %esp,%ebp
  101c59:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  101c5c:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c5f:	03 45 08             	add    0x8(%ebp),%eax
  101c62:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  101c65:	8b 45 08             	mov    0x8(%ebp),%eax
  101c68:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101c6b:	eb 3f                	jmp    101cac <mpsearch1+0x56>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  101c6d:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  101c74:	00 
  101c75:	c7 44 24 04 28 56 10 	movl   $0x105628,0x4(%esp)
  101c7c:	00 
  101c7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c80:	89 04 24             	mov    %eax,(%esp)
  101c83:	e8 53 2d 00 00       	call   1049db <memcmp>
  101c88:	85 c0                	test   %eax,%eax
  101c8a:	75 1c                	jne    101ca8 <mpsearch1+0x52>
  101c8c:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  101c93:	00 
  101c94:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c97:	89 04 24             	mov    %eax,(%esp)
  101c9a:	e8 81 ff ff ff       	call   101c20 <sum>
  101c9f:	84 c0                	test   %al,%al
  101ca1:	75 05                	jne    101ca8 <mpsearch1+0x52>
			return (struct mp *) p;
  101ca3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ca6:	eb 11                	jmp    101cb9 <mpsearch1+0x63>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  101ca8:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  101cac:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101caf:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  101cb2:	72 b9                	jb     101c6d <mpsearch1+0x17>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  101cb4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  101cb9:	c9                   	leave  
  101cba:	c3                   	ret    

00101cbb <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  101cbb:	55                   	push   %ebp
  101cbc:	89 e5                	mov    %esp,%ebp
  101cbe:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  101cc1:	c7 45 ec 00 04 00 00 	movl   $0x400,-0x14(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  101cc8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101ccb:	83 c0 0f             	add    $0xf,%eax
  101cce:	0f b6 00             	movzbl (%eax),%eax
  101cd1:	0f b6 c0             	movzbl %al,%eax
  101cd4:	89 c2                	mov    %eax,%edx
  101cd6:	c1 e2 08             	shl    $0x8,%edx
  101cd9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101cdc:	83 c0 0e             	add    $0xe,%eax
  101cdf:	0f b6 00             	movzbl (%eax),%eax
  101ce2:	0f b6 c0             	movzbl %al,%eax
  101ce5:	09 d0                	or     %edx,%eax
  101ce7:	c1 e0 04             	shl    $0x4,%eax
  101cea:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101ced:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101cf1:	74 21                	je     101d14 <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  101cf3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101cf6:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  101cfd:	00 
  101cfe:	89 04 24             	mov    %eax,(%esp)
  101d01:	e8 50 ff ff ff       	call   101c56 <mpsearch1>
  101d06:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101d09:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101d0d:	74 50                	je     101d5f <mpsearch+0xa4>
			return mp;
  101d0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101d12:	eb 5f                	jmp    101d73 <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  101d14:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101d17:	83 c0 14             	add    $0x14,%eax
  101d1a:	0f b6 00             	movzbl (%eax),%eax
  101d1d:	0f b6 c0             	movzbl %al,%eax
  101d20:	89 c2                	mov    %eax,%edx
  101d22:	c1 e2 08             	shl    $0x8,%edx
  101d25:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101d28:	83 c0 13             	add    $0x13,%eax
  101d2b:	0f b6 00             	movzbl (%eax),%eax
  101d2e:	0f b6 c0             	movzbl %al,%eax
  101d31:	09 d0                	or     %edx,%eax
  101d33:	c1 e0 0a             	shl    $0xa,%eax
  101d36:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  101d39:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101d3c:	2d 00 04 00 00       	sub    $0x400,%eax
  101d41:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  101d48:	00 
  101d49:	89 04 24             	mov    %eax,(%esp)
  101d4c:	e8 05 ff ff ff       	call   101c56 <mpsearch1>
  101d51:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101d54:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101d58:	74 05                	je     101d5f <mpsearch+0xa4>
			return mp;
  101d5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101d5d:	eb 14                	jmp    101d73 <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  101d5f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  101d66:	00 
  101d67:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  101d6e:	e8 e3 fe ff ff       	call   101c56 <mpsearch1>
}
  101d73:	c9                   	leave  
  101d74:	c3                   	ret    

00101d75 <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  101d75:	55                   	push   %ebp
  101d76:	89 e5                	mov    %esp,%ebp
  101d78:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  101d7b:	e8 3b ff ff ff       	call   101cbb <mpsearch>
  101d80:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101d83:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101d87:	74 0a                	je     101d93 <mpconfig+0x1e>
  101d89:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101d8c:	8b 40 04             	mov    0x4(%eax),%eax
  101d8f:	85 c0                	test   %eax,%eax
  101d91:	75 07                	jne    101d9a <mpconfig+0x25>
		return 0;
  101d93:	b8 00 00 00 00       	mov    $0x0,%eax
  101d98:	eb 7b                	jmp    101e15 <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  101d9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101d9d:	8b 40 04             	mov    0x4(%eax),%eax
  101da0:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  101da3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  101daa:	00 
  101dab:	c7 44 24 04 2d 56 10 	movl   $0x10562d,0x4(%esp)
  101db2:	00 
  101db3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101db6:	89 04 24             	mov    %eax,(%esp)
  101db9:	e8 1d 2c 00 00       	call   1049db <memcmp>
  101dbe:	85 c0                	test   %eax,%eax
  101dc0:	74 07                	je     101dc9 <mpconfig+0x54>
		return 0;
  101dc2:	b8 00 00 00 00       	mov    $0x0,%eax
  101dc7:	eb 4c                	jmp    101e15 <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  101dc9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101dcc:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  101dd0:	3c 01                	cmp    $0x1,%al
  101dd2:	74 12                	je     101de6 <mpconfig+0x71>
  101dd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101dd7:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  101ddb:	3c 04                	cmp    $0x4,%al
  101ddd:	74 07                	je     101de6 <mpconfig+0x71>
		return 0;
  101ddf:	b8 00 00 00 00       	mov    $0x0,%eax
  101de4:	eb 2f                	jmp    101e15 <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  101de6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101de9:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  101ded:	0f b7 d0             	movzwl %ax,%edx
  101df0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101df3:	89 54 24 04          	mov    %edx,0x4(%esp)
  101df7:	89 04 24             	mov    %eax,(%esp)
  101dfa:	e8 21 fe ff ff       	call   101c20 <sum>
  101dff:	84 c0                	test   %al,%al
  101e01:	74 07                	je     101e0a <mpconfig+0x95>
		return 0;
  101e03:	b8 00 00 00 00       	mov    $0x0,%eax
  101e08:	eb 0b                	jmp    101e15 <mpconfig+0xa0>
       *pmp = mp;
  101e0a:	8b 45 08             	mov    0x8(%ebp),%eax
  101e0d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101e10:	89 10                	mov    %edx,(%eax)
	return conf;
  101e12:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  101e15:	c9                   	leave  
  101e16:	c3                   	ret    

00101e17 <mp_init>:

void
mp_init(void)
{
  101e17:	55                   	push   %ebp
  101e18:	89 e5                	mov    %esp,%ebp
  101e1a:	83 ec 48             	sub    $0x48,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  101e1d:	e8 e6 fd ff ff       	call   101c08 <cpu_onboot>
  101e22:	85 c0                	test   %eax,%eax
  101e24:	0f 84 72 01 00 00    	je     101f9c <mp_init+0x185>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  101e2a:	8d 45 c8             	lea    -0x38(%ebp),%eax
  101e2d:	89 04 24             	mov    %eax,(%esp)
  101e30:	e8 40 ff ff ff       	call   101d75 <mpconfig>
  101e35:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  101e38:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  101e3c:	0f 84 5d 01 00 00    	je     101f9f <mp_init+0x188>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  101e42:	c7 05 64 d3 30 00 01 	movl   $0x1,0x30d364
  101e49:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  101e4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  101e4f:	8b 40 24             	mov    0x24(%eax),%eax
  101e52:	a3 28 da 30 00       	mov    %eax,0x30da28
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  101e57:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  101e5a:	83 c0 2c             	add    $0x2c,%eax
  101e5d:	89 45 cc             	mov    %eax,-0x34(%ebp)
  101e60:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101e63:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  101e66:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  101e6a:	0f b7 c0             	movzwl %ax,%eax
  101e6d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  101e70:	89 45 d0             	mov    %eax,-0x30(%ebp)
  101e73:	e9 cc 00 00 00       	jmp    101f44 <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  101e78:	8b 45 cc             	mov    -0x34(%ebp),%eax
  101e7b:	0f b6 00             	movzbl (%eax),%eax
  101e7e:	0f b6 c0             	movzbl %al,%eax
  101e81:	83 f8 04             	cmp    $0x4,%eax
  101e84:	0f 87 90 00 00 00    	ja     101f1a <mp_init+0x103>
  101e8a:	8b 04 85 60 56 10 00 	mov    0x105660(,%eax,4),%eax
  101e91:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  101e93:	8b 45 cc             	mov    -0x34(%ebp),%eax
  101e96:	89 45 d8             	mov    %eax,-0x28(%ebp)
			p += sizeof(struct mpproc);
  101e99:	83 45 cc 14          	addl   $0x14,-0x34(%ebp)
			if (!(proc->flags & MPENAB))
  101e9d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101ea0:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  101ea4:	0f b6 c0             	movzbl %al,%eax
  101ea7:	83 e0 01             	and    $0x1,%eax
  101eaa:	85 c0                	test   %eax,%eax
  101eac:	0f 84 91 00 00 00    	je     101f43 <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  101eb2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101eb5:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  101eb9:	0f b6 c0             	movzbl %al,%eax
  101ebc:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  101ebf:	85 c0                	test   %eax,%eax
  101ec1:	75 07                	jne    101eca <mp_init+0xb3>
  101ec3:	e8 0c f3 ff ff       	call   1011d4 <cpu_alloc>
  101ec8:	eb 05                	jmp    101ecf <mp_init+0xb8>
  101eca:	b8 00 60 10 00       	mov    $0x106000,%eax
  101ecf:	89 45 e0             	mov    %eax,-0x20(%ebp)
			c->id = proc->apicid;
  101ed2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101ed5:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  101ed9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101edc:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  101ee2:	a1 68 d3 30 00       	mov    0x30d368,%eax
  101ee7:	83 c0 01             	add    $0x1,%eax
  101eea:	a3 68 d3 30 00       	mov    %eax,0x30d368
			continue;
  101eef:	eb 53                	jmp    101f44 <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  101ef1:	8b 45 cc             	mov    -0x34(%ebp),%eax
  101ef4:	89 45 dc             	mov    %eax,-0x24(%ebp)
			p += sizeof(struct mpioapic);
  101ef7:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			ioapicid = mpio->apicno;
  101efb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101efe:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  101f02:	a2 5c d3 30 00       	mov    %al,0x30d35c
			ioapic = (struct ioapic *) mpio->addr;
  101f07:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101f0a:	8b 40 04             	mov    0x4(%eax),%eax
  101f0d:	a3 60 d3 30 00       	mov    %eax,0x30d360
			continue;
  101f12:	eb 30                	jmp    101f44 <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  101f14:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			continue;
  101f18:	eb 2a                	jmp    101f44 <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  101f1a:	8b 45 cc             	mov    -0x34(%ebp),%eax
  101f1d:	0f b6 00             	movzbl (%eax),%eax
  101f20:	0f b6 c0             	movzbl %al,%eax
  101f23:	89 44 24 0c          	mov    %eax,0xc(%esp)
  101f27:	c7 44 24 08 34 56 10 	movl   $0x105634,0x8(%esp)
  101f2e:	00 
  101f2f:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  101f36:	00 
  101f37:	c7 04 24 54 56 10 00 	movl   $0x105654,(%esp)
  101f3e:	e8 ed e4 ff ff       	call   100430 <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  101f43:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  101f44:	8b 45 cc             	mov    -0x34(%ebp),%eax
  101f47:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  101f4a:	0f 82 28 ff ff ff    	jb     101e78 <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  101f50:	8b 45 c8             	mov    -0x38(%ebp),%eax
  101f53:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  101f57:	84 c0                	test   %al,%al
  101f59:	74 45                	je     101fa0 <mp_init+0x189>
  101f5b:	c7 45 e8 22 00 00 00 	movl   $0x22,-0x18(%ebp)
  101f62:	c6 45 e7 70          	movb   $0x70,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101f66:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  101f6a:	8b 55 e8             	mov    -0x18(%ebp),%edx
  101f6d:	ee                   	out    %al,(%dx)
  101f6e:	c7 45 ec 23 00 00 00 	movl   $0x23,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101f75:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101f78:	89 c2                	mov    %eax,%edx
  101f7a:	ec                   	in     (%dx),%al
  101f7b:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  101f7e:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  101f82:	83 c8 01             	or     $0x1,%eax
  101f85:	0f b6 c0             	movzbl %al,%eax
  101f88:	c7 45 f4 23 00 00 00 	movl   $0x23,-0xc(%ebp)
  101f8f:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101f92:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101f96:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101f99:	ee                   	out    %al,(%dx)
  101f9a:	eb 04                	jmp    101fa0 <mp_init+0x189>
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  101f9c:	90                   	nop
  101f9d:	eb 01                	jmp    101fa0 <mp_init+0x189>

	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.
  101f9f:	90                   	nop
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
	}
}
  101fa0:	c9                   	leave  
  101fa1:	c3                   	ret    

00101fa2 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  101fa2:	55                   	push   %ebp
  101fa3:	89 e5                	mov    %esp,%ebp
  101fa5:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101fa8:	8b 55 08             	mov    0x8(%ebp),%edx
  101fab:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fae:	8b 4d 08             	mov    0x8(%ebp),%ecx
  101fb1:	f0 87 02             	lock xchg %eax,(%edx)
  101fb4:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  101fb7:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101fba:	c9                   	leave  
  101fbb:	c3                   	ret    

00101fbc <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101fbc:	55                   	push   %ebp
  101fbd:	89 e5                	mov    %esp,%ebp
  101fbf:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101fc2:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101fc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101fc8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101fcb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fce:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101fd3:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101fd6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101fd9:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101fdf:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101fe4:	74 24                	je     10200a <cpu_cur+0x4e>
  101fe6:	c7 44 24 0c 74 56 10 	movl   $0x105674,0xc(%esp)
  101fed:	00 
  101fee:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  101ff5:	00 
  101ff6:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101ffd:	00 
  101ffe:	c7 04 24 9f 56 10 00 	movl   $0x10569f,(%esp)
  102005:	e8 26 e4 ff ff       	call   100430 <debug_panic>
	return c;
  10200a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10200d:	c9                   	leave  
  10200e:	c3                   	ret    

0010200f <spinlock_init_>:
#include <kern/cons.h>


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  10200f:	55                   	push   %ebp
  102010:	89 e5                	mov    %esp,%ebp
	lk->locked = 0;
  102012:	8b 45 08             	mov    0x8(%ebp),%eax
  102015:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->file = file;
  10201b:	8b 45 08             	mov    0x8(%ebp),%eax
  10201e:	8b 55 0c             	mov    0xc(%ebp),%edx
  102021:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  102024:	8b 45 08             	mov    0x8(%ebp),%eax
  102027:	8b 55 10             	mov    0x10(%ebp),%edx
  10202a:	89 50 08             	mov    %edx,0x8(%eax)
	lk->cpu = NULL;
  10202d:	8b 45 08             	mov    0x8(%ebp),%eax
  102030:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	lk->eips[0] = 0;
  102037:	8b 45 08             	mov    0x8(%ebp),%eax
  10203a:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
}
  102041:	5d                   	pop    %ebp
  102042:	c3                   	ret    

00102043 <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  102043:	55                   	push   %ebp
  102044:	89 e5                	mov    %esp,%ebp
  102046:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in sa\n");

	if(spinlock_holding(lk))
  102049:	8b 45 08             	mov    0x8(%ebp),%eax
  10204c:	89 04 24             	mov    %eax,(%esp)
  10204f:	e8 c5 00 00 00       	call   102119 <spinlock_holding>
  102054:	85 c0                	test   %eax,%eax
  102056:	74 2a                	je     102082 <spinlock_acquire+0x3f>
		panic("acquire");
  102058:	c7 44 24 08 ac 56 10 	movl   $0x1056ac,0x8(%esp)
  10205f:	00 
  102060:	c7 44 24 04 27 00 00 	movl   $0x27,0x4(%esp)
  102067:	00 
  102068:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  10206f:	e8 bc e3 ff ff       	call   100430 <debug_panic>

	while(xchg(&lk->locked, 1) !=0)
		{cprintf("in xchg\n")
  102074:	c7 04 24 c4 56 10 00 	movl   $0x1056c4,(%esp)
  10207b:	e8 06 26 00 00       	call   104686 <cprintf>
  102080:	eb 01                	jmp    102083 <spinlock_acquire+0x40>
	//cprintf("in sa\n");

	if(spinlock_holding(lk))
		panic("acquire");

	while(xchg(&lk->locked, 1) !=0)
  102082:	90                   	nop
  102083:	8b 45 08             	mov    0x8(%ebp),%eax
  102086:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10208d:	00 
  10208e:	89 04 24             	mov    %eax,(%esp)
  102091:	e8 0c ff ff ff       	call   101fa2 <xchg>
  102096:	85 c0                	test   %eax,%eax
  102098:	75 da                	jne    102074 <spinlock_acquire+0x31>
		{cprintf("in xchg\n")
		;}

	lk->cpu = cpu_cur();
  10209a:	e8 1d ff ff ff       	call   101fbc <cpu_cur>
  10209f:	8b 55 08             	mov    0x8(%ebp),%edx
  1020a2:	89 42 0c             	mov    %eax,0xc(%edx)

	//cprintf("before dt\n");
	debug_trace(read_ebp(), lk->eips);
  1020a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1020a8:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1020ab:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  1020ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1020b1:	89 54 24 04          	mov    %edx,0x4(%esp)
  1020b5:	89 04 24             	mov    %eax,(%esp)
  1020b8:	e8 7b e4 ff ff       	call   100538 <debug_trace>
	//cprintf("after dt\n");

	//cprintf("after sa\n");
}
  1020bd:	c9                   	leave  
  1020be:	c3                   	ret    

001020bf <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  1020bf:	55                   	push   %ebp
  1020c0:	89 e5                	mov    %esp,%ebp
  1020c2:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk))
  1020c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1020c8:	89 04 24             	mov    %eax,(%esp)
  1020cb:	e8 49 00 00 00       	call   102119 <spinlock_holding>
  1020d0:	85 c0                	test   %eax,%eax
  1020d2:	75 1c                	jne    1020f0 <spinlock_release+0x31>
		panic("release");
  1020d4:	c7 44 24 08 cd 56 10 	movl   $0x1056cd,0x8(%esp)
  1020db:	00 
  1020dc:	c7 44 24 04 3b 00 00 	movl   $0x3b,0x4(%esp)
  1020e3:	00 
  1020e4:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  1020eb:	e8 40 e3 ff ff       	call   100430 <debug_panic>

	lk->cpu = NULL;
  1020f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1020f3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	xchg(&lk->locked, 0);
  1020fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1020fd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102104:	00 
  102105:	89 04 24             	mov    %eax,(%esp)
  102108:	e8 95 fe ff ff       	call   101fa2 <xchg>

	lk->eips[0] = 0;
  10210d:	8b 45 08             	mov    0x8(%ebp),%eax
  102110:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
}
  102117:	c9                   	leave  
  102118:	c3                   	ret    

00102119 <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  102119:	55                   	push   %ebp
  10211a:	89 e5                	mov    %esp,%ebp
  10211c:	53                   	push   %ebx
  10211d:	83 ec 04             	sub    $0x4,%esp
	return (lock->cpu == cpu_cur()) && (lock->locked);
  102120:	8b 45 08             	mov    0x8(%ebp),%eax
  102123:	8b 58 0c             	mov    0xc(%eax),%ebx
  102126:	e8 91 fe ff ff       	call   101fbc <cpu_cur>
  10212b:	39 c3                	cmp    %eax,%ebx
  10212d:	75 10                	jne    10213f <spinlock_holding+0x26>
  10212f:	8b 45 08             	mov    0x8(%ebp),%eax
  102132:	8b 00                	mov    (%eax),%eax
  102134:	85 c0                	test   %eax,%eax
  102136:	74 07                	je     10213f <spinlock_holding+0x26>
  102138:	b8 01 00 00 00       	mov    $0x1,%eax
  10213d:	eb 05                	jmp    102144 <spinlock_holding+0x2b>
  10213f:	b8 00 00 00 00       	mov    $0x0,%eax
	//panic("spinlock_holding() not implemented");
}
  102144:	83 c4 04             	add    $0x4,%esp
  102147:	5b                   	pop    %ebx
  102148:	5d                   	pop    %ebp
  102149:	c3                   	ret    

0010214a <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  10214a:	55                   	push   %ebp
  10214b:	89 e5                	mov    %esp,%ebp
  10214d:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  102150:	8b 45 08             	mov    0x8(%ebp),%eax
  102153:	85 c0                	test   %eax,%eax
  102155:	75 12                	jne    102169 <spinlock_godeep+0x1f>
  102157:	8b 45 0c             	mov    0xc(%ebp),%eax
  10215a:	89 04 24             	mov    %eax,(%esp)
  10215d:	e8 e1 fe ff ff       	call   102043 <spinlock_acquire>
  102162:	b8 01 00 00 00       	mov    $0x1,%eax
  102167:	eb 1b                	jmp    102184 <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  102169:	8b 45 08             	mov    0x8(%ebp),%eax
  10216c:	8d 50 ff             	lea    -0x1(%eax),%edx
  10216f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102172:	89 44 24 04          	mov    %eax,0x4(%esp)
  102176:	89 14 24             	mov    %edx,(%esp)
  102179:	e8 cc ff ff ff       	call   10214a <spinlock_godeep>
  10217e:	8b 55 08             	mov    0x8(%ebp),%edx
  102181:	0f af c2             	imul   %edx,%eax
}
  102184:	c9                   	leave  
  102185:	c3                   	ret    

00102186 <spinlock_check>:



void spinlock_check()
{
  102186:	55                   	push   %ebp
  102187:	89 e5                	mov    %esp,%ebp
  102189:	57                   	push   %edi
  10218a:	56                   	push   %esi
  10218b:	53                   	push   %ebx
  10218c:	83 ec 5c             	sub    $0x5c,%esp
  10218f:	89 e0                	mov    %esp,%eax
  102191:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	const int NUMLOCKS=10;
  102194:	c7 45 d0 0a 00 00 00 	movl   $0xa,-0x30(%ebp)
	const int NUMRUNS=5;
  10219b:	c7 45 d4 05 00 00 00 	movl   $0x5,-0x2c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  1021a2:	c7 45 e4 d5 56 10 00 	movl   $0x1056d5,-0x1c(%ebp)
	spinlock locks[NUMLOCKS];
  1021a9:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1021ac:	83 e8 01             	sub    $0x1,%eax
  1021af:	89 45 c8             	mov    %eax,-0x38(%ebp)
  1021b2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1021b5:	ba 00 00 00 00       	mov    $0x0,%edx
  1021ba:	89 c1                	mov    %eax,%ecx
  1021bc:	80 e5 ff             	and    $0xff,%ch
  1021bf:	89 d3                	mov    %edx,%ebx
  1021c1:	83 e3 0f             	and    $0xf,%ebx
  1021c4:	89 c8                	mov    %ecx,%eax
  1021c6:	89 da                	mov    %ebx,%edx
  1021c8:	69 da c0 01 00 00    	imul   $0x1c0,%edx,%ebx
  1021ce:	6b c8 00             	imul   $0x0,%eax,%ecx
  1021d1:	01 cb                	add    %ecx,%ebx
  1021d3:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  1021d8:	f7 e1                	mul    %ecx
  1021da:	01 d3                	add    %edx,%ebx
  1021dc:	89 da                	mov    %ebx,%edx
  1021de:	89 c6                	mov    %eax,%esi
  1021e0:	83 e6 ff             	and    $0xffffffff,%esi
  1021e3:	89 d7                	mov    %edx,%edi
  1021e5:	83 e7 0f             	and    $0xf,%edi
  1021e8:	89 f0                	mov    %esi,%eax
  1021ea:	89 fa                	mov    %edi,%edx
  1021ec:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1021ef:	c1 e0 03             	shl    $0x3,%eax
  1021f2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1021f5:	ba 00 00 00 00       	mov    $0x0,%edx
  1021fa:	89 c1                	mov    %eax,%ecx
  1021fc:	80 e5 ff             	and    $0xff,%ch
  1021ff:	89 4d b8             	mov    %ecx,-0x48(%ebp)
  102202:	89 d3                	mov    %edx,%ebx
  102204:	83 e3 0f             	and    $0xf,%ebx
  102207:	89 5d bc             	mov    %ebx,-0x44(%ebp)
  10220a:	8b 45 b8             	mov    -0x48(%ebp),%eax
  10220d:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102210:	69 ca c0 01 00 00    	imul   $0x1c0,%edx,%ecx
  102216:	6b d8 00             	imul   $0x0,%eax,%ebx
  102219:	01 d9                	add    %ebx,%ecx
  10221b:	bb c0 01 00 00       	mov    $0x1c0,%ebx
  102220:	f7 e3                	mul    %ebx
  102222:	01 d1                	add    %edx,%ecx
  102224:	89 ca                	mov    %ecx,%edx
  102226:	89 c1                	mov    %eax,%ecx
  102228:	80 e5 ff             	and    $0xff,%ch
  10222b:	89 4d b0             	mov    %ecx,-0x50(%ebp)
  10222e:	89 d3                	mov    %edx,%ebx
  102230:	83 e3 0f             	and    $0xf,%ebx
  102233:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
  102236:	8b 45 b0             	mov    -0x50(%ebp),%eax
  102239:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  10223c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10223f:	c1 e0 03             	shl    $0x3,%eax
  102242:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102249:	89 d1                	mov    %edx,%ecx
  10224b:	29 c1                	sub    %eax,%ecx
  10224d:	89 c8                	mov    %ecx,%eax
  10224f:	83 c0 0f             	add    $0xf,%eax
  102252:	83 c0 0f             	add    $0xf,%eax
  102255:	c1 e8 04             	shr    $0x4,%eax
  102258:	c1 e0 04             	shl    $0x4,%eax
  10225b:	29 c4                	sub    %eax,%esp
  10225d:	8d 44 24 10          	lea    0x10(%esp),%eax
  102261:	83 c0 0f             	add    $0xf,%eax
  102264:	c1 e8 04             	shr    $0x4,%eax
  102267:	c1 e0 04             	shl    $0x4,%eax
  10226a:	89 45 cc             	mov    %eax,-0x34(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  10226d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102274:	eb 33                	jmp    1022a9 <spinlock_check+0x123>
  102276:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102279:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10227c:	c1 e0 03             	shl    $0x3,%eax
  10227f:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102286:	89 cb                	mov    %ecx,%ebx
  102288:	29 c3                	sub    %eax,%ebx
  10228a:	89 d8                	mov    %ebx,%eax
  10228c:	01 c2                	add    %eax,%edx
  10228e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102295:	00 
  102296:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102299:	89 44 24 04          	mov    %eax,0x4(%esp)
  10229d:	89 14 24             	mov    %edx,(%esp)
  1022a0:	e8 6a fd ff ff       	call   10200f <spinlock_init_>
  1022a5:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1022a9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1022ac:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1022af:	7c c5                	jl     102276 <spinlock_check+0xf0>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  1022b1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1022b8:	eb 46                	jmp    102300 <spinlock_check+0x17a>
  1022ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1022bd:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1022c0:	c1 e0 03             	shl    $0x3,%eax
  1022c3:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1022ca:	29 c2                	sub    %eax,%edx
  1022cc:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1022cf:	83 c0 0c             	add    $0xc,%eax
  1022d2:	8b 00                	mov    (%eax),%eax
  1022d4:	85 c0                	test   %eax,%eax
  1022d6:	74 24                	je     1022fc <spinlock_check+0x176>
  1022d8:	c7 44 24 0c e4 56 10 	movl   $0x1056e4,0xc(%esp)
  1022df:	00 
  1022e0:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  1022e7:	00 
  1022e8:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  1022ef:	00 
  1022f0:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  1022f7:	e8 34 e1 ff ff       	call   100430 <debug_panic>
  1022fc:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102300:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102303:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102306:	7c b2                	jl     1022ba <spinlock_check+0x134>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  102308:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10230f:	eb 47                	jmp    102358 <spinlock_check+0x1d2>
  102311:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102314:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102317:	c1 e0 03             	shl    $0x3,%eax
  10231a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102321:	29 c2                	sub    %eax,%edx
  102323:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  102326:	83 c0 04             	add    $0x4,%eax
  102329:	8b 00                	mov    (%eax),%eax
  10232b:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  10232e:	74 24                	je     102354 <spinlock_check+0x1ce>
  102330:	c7 44 24 0c f7 56 10 	movl   $0x1056f7,0xc(%esp)
  102337:	00 
  102338:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  10233f:	00 
  102340:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  102347:	00 
  102348:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  10234f:	e8 dc e0 ff ff       	call   100430 <debug_panic>
  102354:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102358:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10235b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10235e:	7c b1                	jl     102311 <spinlock_check+0x18b>

	for (run=0;run<NUMRUNS;run++) 
  102360:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  102367:	e9 25 03 00 00       	jmp    102691 <spinlock_check+0x50b>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  10236c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102373:	eb 3f                	jmp    1023b4 <spinlock_check+0x22e>
		{
			cprintf("%d\n", i);
  102375:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102378:	89 44 24 04          	mov    %eax,0x4(%esp)
  10237c:	c7 04 24 0b 57 10 00 	movl   $0x10570b,(%esp)
  102383:	e8 fe 22 00 00       	call   104686 <cprintf>
			spinlock_godeep(i, &locks[i]);
  102388:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10238b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10238e:	c1 e0 03             	shl    $0x3,%eax
  102391:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102398:	89 cb                	mov    %ecx,%ebx
  10239a:	29 c3                	sub    %eax,%ebx
  10239c:	89 d8                	mov    %ebx,%eax
  10239e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1023a1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023a5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1023a8:	89 04 24             	mov    %eax,(%esp)
  1023ab:	e8 9a fd ff ff       	call   10214a <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  1023b0:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1023b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1023b7:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1023ba:	7c b9                	jl     102375 <spinlock_check+0x1ef>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  1023bc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1023c3:	eb 4b                	jmp    102410 <spinlock_check+0x28a>
			assert(locks[i].cpu == cpu_cur());
  1023c5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1023c8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1023cb:	c1 e0 03             	shl    $0x3,%eax
  1023ce:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1023d5:	29 c2                	sub    %eax,%edx
  1023d7:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1023da:	83 c0 0c             	add    $0xc,%eax
  1023dd:	8b 18                	mov    (%eax),%ebx
  1023df:	e8 d8 fb ff ff       	call   101fbc <cpu_cur>
  1023e4:	39 c3                	cmp    %eax,%ebx
  1023e6:	74 24                	je     10240c <spinlock_check+0x286>
  1023e8:	c7 44 24 0c 0f 57 10 	movl   $0x10570f,0xc(%esp)
  1023ef:	00 
  1023f0:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  1023f7:	00 
  1023f8:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  1023ff:	00 
  102400:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  102407:	e8 24 e0 ff ff       	call   100430 <debug_panic>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  10240c:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102410:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102413:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102416:	7c ad                	jl     1023c5 <spinlock_check+0x23f>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102418:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10241f:	eb 4d                	jmp    10246e <spinlock_check+0x2e8>
			assert(spinlock_holding(&locks[i]) != 0);
  102421:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102424:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102427:	c1 e0 03             	shl    $0x3,%eax
  10242a:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102431:	89 cb                	mov    %ecx,%ebx
  102433:	29 c3                	sub    %eax,%ebx
  102435:	89 d8                	mov    %ebx,%eax
  102437:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10243a:	89 04 24             	mov    %eax,(%esp)
  10243d:	e8 d7 fc ff ff       	call   102119 <spinlock_holding>
  102442:	85 c0                	test   %eax,%eax
  102444:	75 24                	jne    10246a <spinlock_check+0x2e4>
  102446:	c7 44 24 0c 2c 57 10 	movl   $0x10572c,0xc(%esp)
  10244d:	00 
  10244e:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  102455:	00 
  102456:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  10245d:	00 
  10245e:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  102465:	e8 c6 df ff ff       	call   100430 <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  10246a:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10246e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102471:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102474:	7c ab                	jl     102421 <spinlock_check+0x29b>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  102476:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10247d:	e9 bd 00 00 00       	jmp    10253f <spinlock_check+0x3b9>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102482:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102489:	e9 9b 00 00 00       	jmp    102529 <spinlock_check+0x3a3>
			{
				assert(locks[i].eips[j] >=
  10248e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102491:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  102494:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102497:	01 c0                	add    %eax,%eax
  102499:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1024a0:	29 c2                	sub    %eax,%edx
  1024a2:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  1024a5:	83 c0 04             	add    $0x4,%eax
  1024a8:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  1024ab:	b8 4a 21 10 00       	mov    $0x10214a,%eax
  1024b0:	39 c2                	cmp    %eax,%edx
  1024b2:	73 24                	jae    1024d8 <spinlock_check+0x352>
  1024b4:	c7 44 24 0c 50 57 10 	movl   $0x105750,0xc(%esp)
  1024bb:	00 
  1024bc:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  1024c3:	00 
  1024c4:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  1024cb:	00 
  1024cc:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  1024d3:	e8 58 df ff ff       	call   100430 <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  1024d8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1024db:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  1024de:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1024e1:	01 c0                	add    %eax,%eax
  1024e3:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1024ea:	29 c2                	sub    %eax,%edx
  1024ec:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  1024ef:	83 c0 04             	add    $0x4,%eax
  1024f2:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  1024f5:	ba 4a 21 10 00       	mov    $0x10214a,%edx
  1024fa:	83 c2 64             	add    $0x64,%edx
  1024fd:	39 d0                	cmp    %edx,%eax
  1024ff:	72 24                	jb     102525 <spinlock_check+0x39f>
  102501:	c7 44 24 0c 80 57 10 	movl   $0x105780,0xc(%esp)
  102508:	00 
  102509:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  102510:	00 
  102511:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  102518:	00 
  102519:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  102520:	e8 0b df ff ff       	call   100430 <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102525:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  102529:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10252c:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  10252f:	7f 0a                	jg     10253b <spinlock_check+0x3b5>
  102531:	83 7d dc 09          	cmpl   $0x9,-0x24(%ebp)
  102535:	0f 8e 53 ff ff ff    	jle    10248e <spinlock_check+0x308>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  10253b:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10253f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102542:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102545:	0f 8c 37 ff ff ff    	jl     102482 <spinlock_check+0x2fc>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  10254b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102552:	eb 25                	jmp    102579 <spinlock_check+0x3f3>
  102554:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102557:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10255a:	c1 e0 03             	shl    $0x3,%eax
  10255d:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102564:	89 cb                	mov    %ecx,%ebx
  102566:	29 c3                	sub    %eax,%ebx
  102568:	89 d8                	mov    %ebx,%eax
  10256a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10256d:	89 04 24             	mov    %eax,(%esp)
  102570:	e8 4a fb ff ff       	call   1020bf <spinlock_release>
  102575:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102579:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10257c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10257f:	7c d3                	jl     102554 <spinlock_check+0x3ce>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  102581:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102588:	eb 46                	jmp    1025d0 <spinlock_check+0x44a>
  10258a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10258d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102590:	c1 e0 03             	shl    $0x3,%eax
  102593:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10259a:	29 c2                	sub    %eax,%edx
  10259c:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  10259f:	83 c0 0c             	add    $0xc,%eax
  1025a2:	8b 00                	mov    (%eax),%eax
  1025a4:	85 c0                	test   %eax,%eax
  1025a6:	74 24                	je     1025cc <spinlock_check+0x446>
  1025a8:	c7 44 24 0c b1 57 10 	movl   $0x1057b1,0xc(%esp)
  1025af:	00 
  1025b0:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  1025b7:	00 
  1025b8:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  1025bf:	00 
  1025c0:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  1025c7:	e8 64 de ff ff       	call   100430 <debug_panic>
  1025cc:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1025d0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025d3:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1025d6:	7c b2                	jl     10258a <spinlock_check+0x404>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  1025d8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1025df:	eb 46                	jmp    102627 <spinlock_check+0x4a1>
  1025e1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025e4:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1025e7:	c1 e0 03             	shl    $0x3,%eax
  1025ea:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1025f1:	29 c2                	sub    %eax,%edx
  1025f3:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1025f6:	83 c0 10             	add    $0x10,%eax
  1025f9:	8b 00                	mov    (%eax),%eax
  1025fb:	85 c0                	test   %eax,%eax
  1025fd:	74 24                	je     102623 <spinlock_check+0x49d>
  1025ff:	c7 44 24 0c c6 57 10 	movl   $0x1057c6,0xc(%esp)
  102606:	00 
  102607:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  10260e:	00 
  10260f:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
  102616:	00 
  102617:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  10261e:	e8 0d de ff ff       	call   100430 <debug_panic>
  102623:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102627:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10262a:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10262d:	7c b2                	jl     1025e1 <spinlock_check+0x45b>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  10262f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102636:	eb 4d                	jmp    102685 <spinlock_check+0x4ff>
  102638:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10263b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10263e:	c1 e0 03             	shl    $0x3,%eax
  102641:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102648:	89 cb                	mov    %ecx,%ebx
  10264a:	29 c3                	sub    %eax,%ebx
  10264c:	89 d8                	mov    %ebx,%eax
  10264e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102651:	89 04 24             	mov    %eax,(%esp)
  102654:	e8 c0 fa ff ff       	call   102119 <spinlock_holding>
  102659:	85 c0                	test   %eax,%eax
  10265b:	74 24                	je     102681 <spinlock_check+0x4fb>
  10265d:	c7 44 24 0c dc 57 10 	movl   $0x1057dc,0xc(%esp)
  102664:	00 
  102665:	c7 44 24 08 8a 56 10 	movl   $0x10568a,0x8(%esp)
  10266c:	00 
  10266d:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  102674:	00 
  102675:	c7 04 24 b4 56 10 00 	movl   $0x1056b4,(%esp)
  10267c:	e8 af dd ff ff       	call   100430 <debug_panic>
  102681:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102685:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102688:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10268b:	7c ab                	jl     102638 <spinlock_check+0x4b2>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  10268d:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  102691:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102694:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  102697:	0f 8c cf fc ff ff    	jl     10236c <spinlock_check+0x1e6>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  10269d:	c7 04 24 fd 57 10 00 	movl   $0x1057fd,(%esp)
  1026a4:	e8 dd 1f 00 00       	call   104686 <cprintf>
  1026a9:	8b 65 c4             	mov    -0x3c(%ebp),%esp
}
  1026ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
  1026af:	83 c4 00             	add    $0x0,%esp
  1026b2:	5b                   	pop    %ebx
  1026b3:	5e                   	pop    %esi
  1026b4:	5f                   	pop    %edi
  1026b5:	5d                   	pop    %ebp
  1026b6:	c3                   	ret    

001026b7 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  1026b7:	55                   	push   %ebp
  1026b8:	89 e5                	mov    %esp,%ebp
  1026ba:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1026bd:	8b 55 08             	mov    0x8(%ebp),%edx
  1026c0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026c3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1026c6:	f0 87 02             	lock xchg %eax,(%edx)
  1026c9:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  1026cc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1026cf:	c9                   	leave  
  1026d0:	c3                   	ret    

001026d1 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  1026d1:	55                   	push   %ebp
  1026d2:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  1026d4:	8b 45 08             	mov    0x8(%ebp),%eax
  1026d7:	8b 55 0c             	mov    0xc(%ebp),%edx
  1026da:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1026dd:	f0 01 10             	lock add %edx,(%eax)
}
  1026e0:	5d                   	pop    %ebp
  1026e1:	c3                   	ret    

001026e2 <pause>:
	return result;
}

static inline void
pause(void)
{
  1026e2:	55                   	push   %ebp
  1026e3:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  1026e5:	f3 90                	pause  
}
  1026e7:	5d                   	pop    %ebp
  1026e8:	c3                   	ret    

001026e9 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1026e9:	55                   	push   %ebp
  1026ea:	89 e5                	mov    %esp,%ebp
  1026ec:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1026ef:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1026f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1026f5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1026f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1026fb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102700:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  102703:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102706:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10270c:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102711:	74 24                	je     102737 <cpu_cur+0x4e>
  102713:	c7 44 24 0c 1c 58 10 	movl   $0x10581c,0xc(%esp)
  10271a:	00 
  10271b:	c7 44 24 08 32 58 10 	movl   $0x105832,0x8(%esp)
  102722:	00 
  102723:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10272a:	00 
  10272b:	c7 04 24 47 58 10 00 	movl   $0x105847,(%esp)
  102732:	e8 f9 dc ff ff       	call   100430 <debug_panic>
	return c;
  102737:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10273a:	c9                   	leave  
  10273b:	c3                   	ret    

0010273c <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10273c:	55                   	push   %ebp
  10273d:	89 e5                	mov    %esp,%ebp
  10273f:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102742:	e8 a2 ff ff ff       	call   1026e9 <cpu_cur>
  102747:	3d 00 60 10 00       	cmp    $0x106000,%eax
  10274c:	0f 94 c0             	sete   %al
  10274f:	0f b6 c0             	movzbl %al,%eax
}
  102752:	c9                   	leave  
  102753:	c3                   	ret    

00102754 <proc_init>:
// LAB 2: insert your scheduling data structure declarations here.


void
proc_init(void)
{
  102754:	55                   	push   %ebp
  102755:	89 e5                	mov    %esp,%ebp
  102757:	83 ec 08             	sub    $0x8,%esp
	if (!cpu_onboot())
  10275a:	e8 dd ff ff ff       	call   10273c <cpu_onboot>
  10275f:	85 c0                	test   %eax,%eax
		return;
  102761:	90                   	nop

	// your module initialization code here
}
  102762:	c9                   	leave  
  102763:	c3                   	ret    

00102764 <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  102764:	55                   	push   %ebp
  102765:	89 e5                	mov    %esp,%ebp
  102767:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  10276a:	e8 4d e3 ff ff       	call   100abc <mem_alloc>
  10276f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!pi)
  102772:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  102776:	75 0a                	jne    102782 <proc_alloc+0x1e>
		return NULL;
  102778:	b8 00 00 00 00       	mov    $0x0,%eax
  10277d:	e9 60 01 00 00       	jmp    1028e2 <proc_alloc+0x17e>
  102782:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102785:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  102788:	a1 58 d3 30 00       	mov    0x30d358,%eax
  10278d:	83 c0 08             	add    $0x8,%eax
  102790:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102793:	76 15                	jbe    1027aa <proc_alloc+0x46>
  102795:	a1 58 d3 30 00       	mov    0x30d358,%eax
  10279a:	8b 15 04 d3 10 00    	mov    0x10d304,%edx
  1027a0:	c1 e2 03             	shl    $0x3,%edx
  1027a3:	01 d0                	add    %edx,%eax
  1027a5:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1027a8:	72 24                	jb     1027ce <proc_alloc+0x6a>
  1027aa:	c7 44 24 0c 54 58 10 	movl   $0x105854,0xc(%esp)
  1027b1:	00 
  1027b2:	c7 44 24 08 32 58 10 	movl   $0x105832,0x8(%esp)
  1027b9:	00 
  1027ba:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
  1027c1:	00 
  1027c2:	c7 04 24 8b 58 10 00 	movl   $0x10588b,(%esp)
  1027c9:	e8 62 dc ff ff       	call   100430 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1027ce:	a1 58 d3 30 00       	mov    0x30d358,%eax
  1027d3:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  1027d8:	c1 ea 0c             	shr    $0xc,%edx
  1027db:	c1 e2 03             	shl    $0x3,%edx
  1027de:	01 d0                	add    %edx,%eax
  1027e0:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1027e3:	72 3b                	jb     102820 <proc_alloc+0xbc>
  1027e5:	a1 58 d3 30 00       	mov    0x30d358,%eax
  1027ea:	ba 2b da 30 00       	mov    $0x30da2b,%edx
  1027ef:	c1 ea 0c             	shr    $0xc,%edx
  1027f2:	c1 e2 03             	shl    $0x3,%edx
  1027f5:	01 d0                	add    %edx,%eax
  1027f7:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1027fa:	77 24                	ja     102820 <proc_alloc+0xbc>
  1027fc:	c7 44 24 0c 98 58 10 	movl   $0x105898,0xc(%esp)
  102803:	00 
  102804:	c7 44 24 08 32 58 10 	movl   $0x105832,0x8(%esp)
  10280b:	00 
  10280c:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102813:	00 
  102814:	c7 04 24 8b 58 10 00 	movl   $0x10588b,(%esp)
  10281b:	e8 10 dc ff ff       	call   100430 <debug_panic>

	lockadd(&pi->refcount, 1);
  102820:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102823:	83 c0 04             	add    $0x4,%eax
  102826:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10282d:	00 
  10282e:	89 04 24             	mov    %eax,(%esp)
  102831:	e8 9b fe ff ff       	call   1026d1 <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  102836:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102839:	a1 58 d3 30 00       	mov    0x30d358,%eax
  10283e:	89 d1                	mov    %edx,%ecx
  102840:	29 c1                	sub    %eax,%ecx
  102842:	89 c8                	mov    %ecx,%eax
  102844:	c1 f8 03             	sar    $0x3,%eax
  102847:	c1 e0 0c             	shl    $0xc,%eax
  10284a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  10284d:	c7 44 24 08 a0 06 00 	movl   $0x6a0,0x8(%esp)
  102854:	00 
  102855:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10285c:	00 
  10285d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102860:	89 04 24             	mov    %eax,(%esp)
  102863:	e8 03 20 00 00       	call   10486b <memset>
	spinlock_init(&cp->lock);
  102868:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10286b:	c7 44 24 08 31 00 00 	movl   $0x31,0x8(%esp)
  102872:	00 
  102873:	c7 44 24 04 c9 58 10 	movl   $0x1058c9,0x4(%esp)
  10287a:	00 
  10287b:	89 04 24             	mov    %eax,(%esp)
  10287e:	e8 8c f7 ff ff       	call   10200f <spinlock_init_>
	cp->parent = p;
  102883:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102886:	8b 55 08             	mov    0x8(%ebp),%edx
  102889:	89 50 38             	mov    %edx,0x38(%eax)
	cp->state = PROC_STOP;
  10288c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10288f:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  102896:	00 00 00 

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  102899:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10289c:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  1028a3:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  1028a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028a8:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  1028af:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  1028b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028b4:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  1028bb:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  1028bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028c0:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  1028c7:	23 00 


	if (p)
  1028c9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1028cd:	74 10                	je     1028df <proc_alloc+0x17b>
		p->child[cn] = cp;
  1028cf:	8b 55 0c             	mov    0xc(%ebp),%edx
  1028d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1028d5:	8d 4a 0c             	lea    0xc(%edx),%ecx
  1028d8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1028db:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
	return cp;
  1028df:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1028e2:	c9                   	leave  
  1028e3:	c3                   	ret    

001028e4 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  1028e4:	55                   	push   %ebp
  1028e5:	89 e5                	mov    %esp,%ebp
  1028e7:	83 ec 18             	sub    $0x18,%esp
	panic("proc_ready not implemented");
  1028ea:	c7 44 24 08 d5 58 10 	movl   $0x1058d5,0x8(%esp)
  1028f1:	00 
  1028f2:	c7 44 24 04 45 00 00 	movl   $0x45,0x4(%esp)
  1028f9:	00 
  1028fa:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  102901:	e8 2a db ff ff       	call   100430 <debug_panic>

00102906 <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  102906:	55                   	push   %ebp
  102907:	89 e5                	mov    %esp,%ebp
}
  102909:	5d                   	pop    %ebp
  10290a:	c3                   	ret    

0010290b <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  10290b:	55                   	push   %ebp
  10290c:	89 e5                	mov    %esp,%ebp
  10290e:	83 ec 18             	sub    $0x18,%esp
	panic("proc_wait not implemented");
  102911:	c7 44 24 08 f0 58 10 	movl   $0x1058f0,0x8(%esp)
  102918:	00 
  102919:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  102920:	00 
  102921:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  102928:	e8 03 db ff ff       	call   100430 <debug_panic>

0010292d <proc_sched>:
}

void gcc_noreturn
proc_sched(void)
{
  10292d:	55                   	push   %ebp
  10292e:	89 e5                	mov    %esp,%ebp
  102930:	83 ec 18             	sub    $0x18,%esp
	panic("proc_sched not implemented");
  102933:	c7 44 24 08 0a 59 10 	movl   $0x10590a,0x8(%esp)
  10293a:	00 
  10293b:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  102942:	00 
  102943:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  10294a:	e8 e1 da ff ff       	call   100430 <debug_panic>

0010294f <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  10294f:	55                   	push   %ebp
  102950:	89 e5                	mov    %esp,%ebp
  102952:	83 ec 18             	sub    $0x18,%esp
	panic("proc_run not implemented");
  102955:	c7 44 24 08 25 59 10 	movl   $0x105925,0x8(%esp)
  10295c:	00 
  10295d:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
  102964:	00 
  102965:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  10296c:	e8 bf da ff ff       	call   100430 <debug_panic>

00102971 <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  102971:	55                   	push   %ebp
  102972:	89 e5                	mov    %esp,%ebp
  102974:	83 ec 18             	sub    $0x18,%esp
	panic("proc_yield not implemented");
  102977:	c7 44 24 08 3e 59 10 	movl   $0x10593e,0x8(%esp)
  10297e:	00 
  10297f:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
  102986:	00 
  102987:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  10298e:	e8 9d da ff ff       	call   100430 <debug_panic>

00102993 <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  102993:	55                   	push   %ebp
  102994:	89 e5                	mov    %esp,%ebp
  102996:	83 ec 18             	sub    $0x18,%esp
	panic("proc_ret not implemented");
  102999:	c7 44 24 08 59 59 10 	movl   $0x105959,0x8(%esp)
  1029a0:	00 
  1029a1:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  1029a8:	00 
  1029a9:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  1029b0:	e8 7b da ff ff       	call   100430 <debug_panic>

001029b5 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  1029b5:	55                   	push   %ebp
  1029b6:	89 e5                	mov    %esp,%ebp
  1029b8:	57                   	push   %edi
  1029b9:	56                   	push   %esi
  1029ba:	53                   	push   %ebx
  1029bb:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  1029c1:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  1029c8:	00 00 00 
  1029cb:	e9 f0 00 00 00       	jmp    102ac0 <proc_check+0x10b>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  1029d0:	b8 90 92 10 00       	mov    $0x109290,%eax
  1029d5:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  1029db:	83 c2 01             	add    $0x1,%edx
  1029de:	c1 e2 0c             	shl    $0xc,%edx
  1029e1:	01 d0                	add    %edx,%eax
  1029e3:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		*--esp = i;	// push argument to child() function
  1029e9:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  1029f0:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  1029f6:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  1029fc:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  1029fe:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  102a05:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  102a0b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  102a11:	b8 95 2e 10 00       	mov    $0x102e95,%eax
  102a16:	a3 78 90 10 00       	mov    %eax,0x109078
		child_state.tf.esp = (uint32_t) esp;
  102a1b:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  102a21:	a3 84 90 10 00       	mov    %eax,0x109084

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  102a26:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102a2c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a30:	c7 04 24 72 59 10 00 	movl   $0x105972,(%esp)
  102a37:	e8 4a 1c 00 00       	call   104686 <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  102a3c:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102a42:	0f b7 d0             	movzwl %ax,%edx
  102a45:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  102a4c:	7f 07                	jg     102a55 <proc_check+0xa0>
  102a4e:	b8 10 10 00 00       	mov    $0x1010,%eax
  102a53:	eb 05                	jmp    102a5a <proc_check+0xa5>
  102a55:	b8 00 10 00 00       	mov    $0x1000,%eax
  102a5a:	89 85 54 ff ff ff    	mov    %eax,-0xac(%ebp)
  102a60:	66 89 95 52 ff ff ff 	mov    %dx,-0xae(%ebp)
  102a67:	c7 85 4c ff ff ff 40 	movl   $0x109040,-0xb4(%ebp)
  102a6e:	90 10 00 
  102a71:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
  102a78:	00 00 00 
  102a7b:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
  102a82:	00 00 00 
  102a85:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
  102a8c:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  102a8f:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
  102a95:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  102a98:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
  102a9e:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
  102aa5:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
  102aab:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
  102ab1:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
  102ab7:	cd 30                	int    $0x30
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  102ab9:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  102ac0:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  102ac7:	0f 8e 03 ff ff ff    	jle    1029d0 <proc_check+0x1b>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  102acd:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  102ad4:	00 00 00 
  102ad7:	e9 89 00 00 00       	jmp    102b65 <proc_check+0x1b0>
		cprintf("waiting for child %d\n", i);
  102adc:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102ae2:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ae6:	c7 04 24 85 59 10 00 	movl   $0x105985,(%esp)
  102aed:	e8 94 1b 00 00       	call   104686 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  102af2:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102af8:	0f b7 c0             	movzwl %ax,%eax
  102afb:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
  102b02:	10 00 00 
  102b05:	66 89 85 6a ff ff ff 	mov    %ax,-0x96(%ebp)
  102b0c:	c7 85 64 ff ff ff 40 	movl   $0x109040,-0x9c(%ebp)
  102b13:	90 10 00 
  102b16:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
  102b1d:	00 00 00 
  102b20:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
  102b27:	00 00 00 
  102b2a:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
  102b31:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  102b34:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
  102b3a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  102b3d:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
  102b43:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
  102b4a:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
  102b50:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
  102b56:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
  102b5c:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  102b5e:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  102b65:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  102b6c:	0f 8e 6a ff ff ff    	jle    102adc <proc_check+0x127>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  102b72:	c7 04 24 9c 59 10 00 	movl   $0x10599c,(%esp)
  102b79:	e8 08 1b 00 00       	call   104686 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  102b7e:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
  102b85:	e8 fc 1a 00 00       	call   104686 <cprintf>
	for (i = 0; i < 4; i++) {
  102b8a:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  102b91:	00 00 00 
  102b94:	eb 7d                	jmp    102c13 <proc_check+0x25e>
		cprintf("spawning child %d\n", i);
  102b96:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102b9c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ba0:	c7 04 24 72 59 10 00 	movl   $0x105972,(%esp)
  102ba7:	e8 da 1a 00 00       	call   104686 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  102bac:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102bb2:	0f b7 c0             	movzwl %ax,%eax
  102bb5:	c7 45 84 10 00 00 00 	movl   $0x10,-0x7c(%ebp)
  102bbc:	66 89 45 82          	mov    %ax,-0x7e(%ebp)
  102bc0:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  102bc7:	00 00 00 
  102bca:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
  102bd1:	00 00 00 
  102bd4:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
  102bdb:	00 00 00 
  102bde:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
  102be5:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  102be8:	8b 45 84             	mov    -0x7c(%ebp),%eax
  102beb:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  102bee:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
  102bf4:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
  102bf8:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
  102bfe:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
  102c04:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
  102c0a:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  102c0c:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  102c13:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  102c1a:	0f 8e 76 ff ff ff    	jle    102b96 <proc_check+0x1e1>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  102c20:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  102c27:	00 00 00 
  102c2a:	eb 4f                	jmp    102c7b <proc_check+0x2c6>
		sys_get(0, i, NULL, NULL, NULL, 0);
  102c2c:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102c32:	0f b7 c0             	movzwl %ax,%eax
  102c35:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  102c3c:	66 89 45 9a          	mov    %ax,-0x66(%ebp)
  102c40:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
  102c47:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  102c4e:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
  102c55:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  102c5c:	8b 45 9c             	mov    -0x64(%ebp),%eax
  102c5f:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  102c62:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
  102c65:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
  102c69:	8b 75 90             	mov    -0x70(%ebp),%esi
  102c6c:	8b 7d 8c             	mov    -0x74(%ebp),%edi
  102c6f:	8b 4d 88             	mov    -0x78(%ebp),%ecx
  102c72:	cd 30                	int    $0x30
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  102c74:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  102c7b:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  102c82:	7e a8                	jle    102c2c <proc_check+0x277>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  102c84:	c7 04 24 e8 59 10 00 	movl   $0x1059e8,(%esp)
  102c8b:	e8 f6 19 00 00       	call   104686 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  102c90:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  102c97:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  102c9a:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102ca0:	0f b7 c0             	movzwl %ax,%eax
  102ca3:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
  102caa:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
  102cae:	c7 45 ac 40 90 10 00 	movl   $0x109040,-0x54(%ebp)
  102cb5:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  102cbc:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  102cc3:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  102cca:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  102ccd:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  102cd0:	8b 5d ac             	mov    -0x54(%ebp),%ebx
  102cd3:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
  102cd7:	8b 75 a8             	mov    -0x58(%ebp),%esi
  102cda:	8b 7d a4             	mov    -0x5c(%ebp),%edi
  102cdd:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  102ce0:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  102ce2:	a1 94 d2 10 00       	mov    0x10d294,%eax
  102ce7:	85 c0                	test   %eax,%eax
  102ce9:	74 24                	je     102d0f <proc_check+0x35a>
  102ceb:	c7 44 24 0c 0d 5a 10 	movl   $0x105a0d,0xc(%esp)
  102cf2:	00 
  102cf3:	c7 44 24 08 32 58 10 	movl   $0x105832,0x8(%esp)
  102cfa:	00 
  102cfb:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  102d02:	00 
  102d03:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  102d0a:	e8 21 d7 ff ff       	call   100430 <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  102d0f:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102d15:	0f b7 c0             	movzwl %ax,%eax
  102d18:	c7 45 cc 10 10 00 00 	movl   $0x1010,-0x34(%ebp)
  102d1f:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
  102d23:	c7 45 c4 40 90 10 00 	movl   $0x109040,-0x3c(%ebp)
  102d2a:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
  102d31:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  102d38:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  102d3f:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102d42:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  102d45:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
  102d48:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  102d4c:	8b 75 c0             	mov    -0x40(%ebp),%esi
  102d4f:	8b 7d bc             	mov    -0x44(%ebp),%edi
  102d52:	8b 4d b8             	mov    -0x48(%ebp),%ecx
  102d55:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  102d57:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102d5d:	0f b7 c0             	movzwl %ax,%eax
  102d60:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  102d67:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
  102d6b:	c7 45 dc 40 90 10 00 	movl   $0x109040,-0x24(%ebp)
  102d72:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102d79:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  102d80:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  102d87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102d8a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  102d8d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  102d90:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  102d94:	8b 75 d8             	mov    -0x28(%ebp),%esi
  102d97:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  102d9a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  102d9d:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  102d9f:	a1 94 d2 10 00       	mov    0x10d294,%eax
  102da4:	85 c0                	test   %eax,%eax
  102da6:	74 3f                	je     102de7 <proc_check+0x432>
			trap_check_args *args = recovargs;
  102da8:	a1 94 d2 10 00       	mov    0x10d294,%eax
  102dad:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)
			cprintf("recover from trap %d\n",
  102db3:	a1 70 90 10 00       	mov    0x109070,%eax
  102db8:	89 44 24 04          	mov    %eax,0x4(%esp)
  102dbc:	c7 04 24 1f 5a 10 00 	movl   $0x105a1f,(%esp)
  102dc3:	e8 be 18 00 00       	call   104686 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  102dc8:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  102dce:	8b 00                	mov    (%eax),%eax
  102dd0:	a3 78 90 10 00       	mov    %eax,0x109078
			args->trapno = child_state.tf.trapno;
  102dd5:	a1 70 90 10 00       	mov    0x109070,%eax
  102dda:	89 c2                	mov    %eax,%edx
  102ddc:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  102de2:	89 50 04             	mov    %edx,0x4(%eax)
  102de5:	eb 2e                	jmp    102e15 <proc_check+0x460>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  102de7:	a1 70 90 10 00       	mov    0x109070,%eax
  102dec:	83 f8 30             	cmp    $0x30,%eax
  102def:	74 24                	je     102e15 <proc_check+0x460>
  102df1:	c7 44 24 0c 38 5a 10 	movl   $0x105a38,0xc(%esp)
  102df8:	00 
  102df9:	c7 44 24 08 32 58 10 	movl   $0x105832,0x8(%esp)
  102e00:	00 
  102e01:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
  102e08:	00 
  102e09:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  102e10:	e8 1b d6 ff ff       	call   100430 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  102e15:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  102e1b:	8d 50 01             	lea    0x1(%eax),%edx
  102e1e:	89 d0                	mov    %edx,%eax
  102e20:	c1 f8 1f             	sar    $0x1f,%eax
  102e23:	c1 e8 1e             	shr    $0x1e,%eax
  102e26:	01 c2                	add    %eax,%edx
  102e28:	83 e2 03             	and    $0x3,%edx
  102e2b:	89 d1                	mov    %edx,%ecx
  102e2d:	29 c1                	sub    %eax,%ecx
  102e2f:	89 c8                	mov    %ecx,%eax
  102e31:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  102e37:	a1 70 90 10 00       	mov    0x109070,%eax
  102e3c:	83 f8 30             	cmp    $0x30,%eax
  102e3f:	0f 85 ca fe ff ff    	jne    102d0f <proc_check+0x35a>
	assert(recovargs == NULL);
  102e45:	a1 94 d2 10 00       	mov    0x10d294,%eax
  102e4a:	85 c0                	test   %eax,%eax
  102e4c:	74 24                	je     102e72 <proc_check+0x4bd>
  102e4e:	c7 44 24 0c 0d 5a 10 	movl   $0x105a0d,0xc(%esp)
  102e55:	00 
  102e56:	c7 44 24 08 32 58 10 	movl   $0x105832,0x8(%esp)
  102e5d:	00 
  102e5e:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  102e65:	00 
  102e66:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  102e6d:	e8 be d5 ff ff       	call   100430 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  102e72:	c7 04 24 5c 5a 10 00 	movl   $0x105a5c,(%esp)
  102e79:	e8 08 18 00 00       	call   104686 <cprintf>

	cprintf("proc_check() succeeded!\n");
  102e7e:	c7 04 24 89 5a 10 00 	movl   $0x105a89,(%esp)
  102e85:	e8 fc 17 00 00       	call   104686 <cprintf>
}
  102e8a:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  102e90:	5b                   	pop    %ebx
  102e91:	5e                   	pop    %esi
  102e92:	5f                   	pop    %edi
  102e93:	5d                   	pop    %ebp
  102e94:	c3                   	ret    

00102e95 <child>:

static void child(int n)
{
  102e95:	55                   	push   %ebp
  102e96:	89 e5                	mov    %esp,%ebp
  102e98:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  102e9b:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  102e9f:	7f 64                	jg     102f05 <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  102ea1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102ea8:	eb 4e                	jmp    102ef8 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  102eaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ead:	89 44 24 08          	mov    %eax,0x8(%esp)
  102eb1:	8b 45 08             	mov    0x8(%ebp),%eax
  102eb4:	89 44 24 04          	mov    %eax,0x4(%esp)
  102eb8:	c7 04 24 a2 5a 10 00 	movl   $0x105aa2,(%esp)
  102ebf:	e8 c2 17 00 00       	call   104686 <cprintf>
			while (pingpong != n)
  102ec4:	eb 05                	jmp    102ecb <child+0x36>
				pause();
  102ec6:	e8 17 f8 ff ff       	call   1026e2 <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n)
  102ecb:	8b 55 08             	mov    0x8(%ebp),%edx
  102ece:	a1 90 d2 10 00       	mov    0x10d290,%eax
  102ed3:	39 c2                	cmp    %eax,%edx
  102ed5:	75 ef                	jne    102ec6 <child+0x31>
				pause();
			xchg(&pingpong, !pingpong);
  102ed7:	a1 90 d2 10 00       	mov    0x10d290,%eax
  102edc:	85 c0                	test   %eax,%eax
  102ede:	0f 94 c0             	sete   %al
  102ee1:	0f b6 c0             	movzbl %al,%eax
  102ee4:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ee8:	c7 04 24 90 d2 10 00 	movl   $0x10d290,(%esp)
  102eef:	e8 c3 f7 ff ff       	call   1026b7 <xchg>
static void child(int n)
{
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  102ef4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102ef8:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  102efc:	7e ac                	jle    102eaa <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  102efe:	b8 03 00 00 00       	mov    $0x3,%eax
  102f03:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  102f05:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  102f0c:	eb 4c                	jmp    102f5a <child+0xc5>
		cprintf("in child %d count %d\n", n, i);
  102f0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102f11:	89 44 24 08          	mov    %eax,0x8(%esp)
  102f15:	8b 45 08             	mov    0x8(%ebp),%eax
  102f18:	89 44 24 04          	mov    %eax,0x4(%esp)
  102f1c:	c7 04 24 a2 5a 10 00 	movl   $0x105aa2,(%esp)
  102f23:	e8 5e 17 00 00       	call   104686 <cprintf>
		while (pingpong != n)
  102f28:	eb 05                	jmp    102f2f <child+0x9a>
			pause();
  102f2a:	e8 b3 f7 ff ff       	call   1026e2 <pause>

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		cprintf("in child %d count %d\n", n, i);
		while (pingpong != n)
  102f2f:	8b 55 08             	mov    0x8(%ebp),%edx
  102f32:	a1 90 d2 10 00       	mov    0x10d290,%eax
  102f37:	39 c2                	cmp    %eax,%edx
  102f39:	75 ef                	jne    102f2a <child+0x95>
			pause();
		xchg(&pingpong, (pingpong + 1) % 4);
  102f3b:	a1 90 d2 10 00       	mov    0x10d290,%eax
  102f40:	83 c0 01             	add    $0x1,%eax
  102f43:	83 e0 03             	and    $0x3,%eax
  102f46:	89 44 24 04          	mov    %eax,0x4(%esp)
  102f4a:	c7 04 24 90 d2 10 00 	movl   $0x10d290,(%esp)
  102f51:	e8 61 f7 ff ff       	call   1026b7 <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  102f56:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  102f5a:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  102f5e:	7e ae                	jle    102f0e <child+0x79>
  102f60:	b8 03 00 00 00       	mov    $0x3,%eax
  102f65:	cd 30                	int    $0x30
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  102f67:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102f6b:	75 6d                	jne    102fda <child+0x145>
		assert(recovargs == NULL);
  102f6d:	a1 94 d2 10 00       	mov    0x10d294,%eax
  102f72:	85 c0                	test   %eax,%eax
  102f74:	74 24                	je     102f9a <child+0x105>
  102f76:	c7 44 24 0c 0d 5a 10 	movl   $0x105a0d,0xc(%esp)
  102f7d:	00 
  102f7e:	c7 44 24 08 32 58 10 	movl   $0x105832,0x8(%esp)
  102f85:	00 
  102f86:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  102f8d:	00 
  102f8e:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  102f95:	e8 96 d4 ff ff       	call   100430 <debug_panic>
		trap_check(&recovargs);
  102f9a:	c7 04 24 94 d2 10 00 	movl   $0x10d294,(%esp)
  102fa1:	e8 1b e9 ff ff       	call   1018c1 <trap_check>
		assert(recovargs == NULL);
  102fa6:	a1 94 d2 10 00       	mov    0x10d294,%eax
  102fab:	85 c0                	test   %eax,%eax
  102fad:	74 24                	je     102fd3 <child+0x13e>
  102faf:	c7 44 24 0c 0d 5a 10 	movl   $0x105a0d,0xc(%esp)
  102fb6:	00 
  102fb7:	c7 44 24 08 32 58 10 	movl   $0x105832,0x8(%esp)
  102fbe:	00 
  102fbf:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  102fc6:	00 
  102fc7:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  102fce:	e8 5d d4 ff ff       	call   100430 <debug_panic>
  102fd3:	b8 03 00 00 00       	mov    $0x3,%eax
  102fd8:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  102fda:	c7 44 24 08 b8 5a 10 	movl   $0x105ab8,0x8(%esp)
  102fe1:	00 
  102fe2:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
  102fe9:	00 
  102fea:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  102ff1:	e8 3a d4 ff ff       	call   100430 <debug_panic>

00102ff6 <grandchild>:
}

static void grandchild(int n)
{
  102ff6:	55                   	push   %ebp
  102ff7:	89 e5                	mov    %esp,%ebp
  102ff9:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  102ffc:	c7 44 24 08 dc 5a 10 	movl   $0x105adc,0x8(%esp)
  103003:	00 
  103004:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
  10300b:	00 
  10300c:	c7 04 24 c9 58 10 00 	movl   $0x1058c9,(%esp)
  103013:	e8 18 d4 ff ff       	call   100430 <debug_panic>

00103018 <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  103018:	55                   	push   %ebp
  103019:	89 e5                	mov    %esp,%ebp
  10301b:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  10301e:	c7 44 24 08 08 5b 10 	movl   $0x105b08,0x8(%esp)
  103025:	00 
  103026:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  10302d:	00 
  10302e:	c7 04 24 23 5b 10 00 	movl   $0x105b23,(%esp)
  103035:	e8 f6 d3 ff ff       	call   100430 <debug_panic>

0010303a <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  10303a:	55                   	push   %ebp
  10303b:	89 e5                	mov    %esp,%ebp
  10303d:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  103040:	c7 44 24 08 32 5b 10 	movl   $0x105b32,0x8(%esp)
  103047:	00 
  103048:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  10304f:	00 
  103050:	c7 04 24 23 5b 10 00 	movl   $0x105b23,(%esp)
  103057:	e8 d4 d3 ff ff       	call   100430 <debug_panic>

0010305c <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  10305c:	55                   	push   %ebp
  10305d:	89 e5                	mov    %esp,%ebp
  10305f:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  103062:	c7 44 24 08 50 5b 10 	movl   $0x105b50,0x8(%esp)
  103069:	00 
  10306a:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  103071:	00 
  103072:	c7 04 24 23 5b 10 00 	movl   $0x105b23,(%esp)
  103079:	e8 b2 d3 ff ff       	call   100430 <debug_panic>

0010307e <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  10307e:	55                   	push   %ebp
  10307f:	89 e5                	mov    %esp,%ebp
  103081:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  103084:	8b 45 18             	mov    0x18(%ebp),%eax
  103087:	89 44 24 08          	mov    %eax,0x8(%esp)
  10308b:	8b 45 14             	mov    0x14(%ebp),%eax
  10308e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103092:	8b 45 08             	mov    0x8(%ebp),%eax
  103095:	89 04 24             	mov    %eax,(%esp)
  103098:	e8 bf ff ff ff       	call   10305c <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  10309d:	c7 44 24 08 6c 5b 10 	movl   $0x105b6c,0x8(%esp)
  1030a4:	00 
  1030a5:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  1030ac:	00 
  1030ad:	c7 04 24 23 5b 10 00 	movl   $0x105b23,(%esp)
  1030b4:	e8 77 d3 ff ff       	call   100430 <debug_panic>

001030b9 <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  1030b9:	55                   	push   %ebp
  1030ba:	89 e5                	mov    %esp,%ebp
  1030bc:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  1030bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1030c2:	8b 40 10             	mov    0x10(%eax),%eax
  1030c5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1030c9:	c7 04 24 90 5b 10 00 	movl   $0x105b90,(%esp)
  1030d0:	e8 b1 15 00 00       	call   104686 <cprintf>

	trap_return(tf);	// syscall completed
  1030d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1030d8:	89 04 24             	mov    %eax,(%esp)
  1030db:	e8 a0 3f 00 00       	call   107080 <trap_return>

001030e0 <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  1030e0:	55                   	push   %ebp
  1030e1:	89 e5                	mov    %esp,%ebp
  1030e3:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  1030e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1030e9:	8b 40 1c             	mov    0x1c(%eax),%eax
  1030ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  1030ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030f2:	83 e0 0f             	and    $0xf,%eax
  1030f5:	85 c0                	test   %eax,%eax
  1030f7:	75 15                	jne    10310e <syscall+0x2e>
	case SYS_CPUTS:	return do_cputs(tf, cmd);
  1030f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  103100:	8b 45 08             	mov    0x8(%ebp),%eax
  103103:	89 04 24             	mov    %eax,(%esp)
  103106:	e8 ae ff ff ff       	call   1030b9 <do_cputs>
  10310b:	90                   	nop
  10310c:	eb 01                	jmp    10310f <syscall+0x2f>
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
  10310e:	90                   	nop
	}
}
  10310f:	c9                   	leave  
  103110:	c3                   	ret    

00103111 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  103111:	55                   	push   %ebp
  103112:	89 e5                	mov    %esp,%ebp
  103114:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  103117:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  10311e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103121:	0f b7 00             	movzwl (%eax),%eax
  103124:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  103128:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10312b:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  103130:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103133:	0f b7 00             	movzwl (%eax),%eax
  103136:	66 3d 5a a5          	cmp    $0xa55a,%ax
  10313a:	74 13                	je     10314f <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  10313c:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  103143:	c7 05 98 d2 10 00 b4 	movl   $0x3b4,0x10d298
  10314a:	03 00 00 
  10314d:	eb 14                	jmp    103163 <video_init+0x52>
	} else {
		*cp = was;
  10314f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103152:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  103156:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  103159:	c7 05 98 d2 10 00 d4 	movl   $0x3d4,0x10d298
  103160:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  103163:	a1 98 d2 10 00       	mov    0x10d298,%eax
  103168:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10316b:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10316f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  103173:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103176:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  103177:	a1 98 d2 10 00       	mov    0x10d298,%eax
  10317c:	83 c0 01             	add    $0x1,%eax
  10317f:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103182:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103185:	89 c2                	mov    %eax,%edx
  103187:	ec                   	in     (%dx),%al
  103188:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10318b:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  10318f:	0f b6 c0             	movzbl %al,%eax
  103192:	c1 e0 08             	shl    $0x8,%eax
  103195:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  103198:	a1 98 d2 10 00       	mov    0x10d298,%eax
  10319d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1031a0:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1031a4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1031a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1031ab:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  1031ac:	a1 98 d2 10 00       	mov    0x10d298,%eax
  1031b1:	83 c0 01             	add    $0x1,%eax
  1031b4:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1031b7:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1031ba:	89 c2                	mov    %eax,%edx
  1031bc:	ec                   	in     (%dx),%al
  1031bd:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  1031c0:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  1031c4:	0f b6 c0             	movzbl %al,%eax
  1031c7:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  1031ca:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1031cd:	a3 9c d2 10 00       	mov    %eax,0x10d29c
	crt_pos = pos;
  1031d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1031d5:	66 a3 a0 d2 10 00    	mov    %ax,0x10d2a0
}
  1031db:	c9                   	leave  
  1031dc:	c3                   	ret    

001031dd <video_putc>:



void
video_putc(int c)
{
  1031dd:	55                   	push   %ebp
  1031de:	89 e5                	mov    %esp,%ebp
  1031e0:	53                   	push   %ebx
  1031e1:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  1031e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1031e7:	b0 00                	mov    $0x0,%al
  1031e9:	85 c0                	test   %eax,%eax
  1031eb:	75 07                	jne    1031f4 <video_putc+0x17>
		c |= 0x0700;
  1031ed:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  1031f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1031f7:	25 ff 00 00 00       	and    $0xff,%eax
  1031fc:	83 f8 09             	cmp    $0x9,%eax
  1031ff:	0f 84 ae 00 00 00    	je     1032b3 <video_putc+0xd6>
  103205:	83 f8 09             	cmp    $0x9,%eax
  103208:	7f 0a                	jg     103214 <video_putc+0x37>
  10320a:	83 f8 08             	cmp    $0x8,%eax
  10320d:	74 14                	je     103223 <video_putc+0x46>
  10320f:	e9 dd 00 00 00       	jmp    1032f1 <video_putc+0x114>
  103214:	83 f8 0a             	cmp    $0xa,%eax
  103217:	74 4e                	je     103267 <video_putc+0x8a>
  103219:	83 f8 0d             	cmp    $0xd,%eax
  10321c:	74 59                	je     103277 <video_putc+0x9a>
  10321e:	e9 ce 00 00 00       	jmp    1032f1 <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  103223:	0f b7 05 a0 d2 10 00 	movzwl 0x10d2a0,%eax
  10322a:	66 85 c0             	test   %ax,%ax
  10322d:	0f 84 e4 00 00 00    	je     103317 <video_putc+0x13a>
			crt_pos--;
  103233:	0f b7 05 a0 d2 10 00 	movzwl 0x10d2a0,%eax
  10323a:	83 e8 01             	sub    $0x1,%eax
  10323d:	66 a3 a0 d2 10 00    	mov    %ax,0x10d2a0
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  103243:	a1 9c d2 10 00       	mov    0x10d29c,%eax
  103248:	0f b7 15 a0 d2 10 00 	movzwl 0x10d2a0,%edx
  10324f:	0f b7 d2             	movzwl %dx,%edx
  103252:	01 d2                	add    %edx,%edx
  103254:	8d 14 10             	lea    (%eax,%edx,1),%edx
  103257:	8b 45 08             	mov    0x8(%ebp),%eax
  10325a:	b0 00                	mov    $0x0,%al
  10325c:	83 c8 20             	or     $0x20,%eax
  10325f:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  103262:	e9 b1 00 00 00       	jmp    103318 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  103267:	0f b7 05 a0 d2 10 00 	movzwl 0x10d2a0,%eax
  10326e:	83 c0 50             	add    $0x50,%eax
  103271:	66 a3 a0 d2 10 00    	mov    %ax,0x10d2a0
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  103277:	0f b7 1d a0 d2 10 00 	movzwl 0x10d2a0,%ebx
  10327e:	0f b7 0d a0 d2 10 00 	movzwl 0x10d2a0,%ecx
  103285:	0f b7 c1             	movzwl %cx,%eax
  103288:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  10328e:	c1 e8 10             	shr    $0x10,%eax
  103291:	89 c2                	mov    %eax,%edx
  103293:	66 c1 ea 06          	shr    $0x6,%dx
  103297:	89 d0                	mov    %edx,%eax
  103299:	c1 e0 02             	shl    $0x2,%eax
  10329c:	01 d0                	add    %edx,%eax
  10329e:	c1 e0 04             	shl    $0x4,%eax
  1032a1:	89 ca                	mov    %ecx,%edx
  1032a3:	66 29 c2             	sub    %ax,%dx
  1032a6:	89 d8                	mov    %ebx,%eax
  1032a8:	66 29 d0             	sub    %dx,%ax
  1032ab:	66 a3 a0 d2 10 00    	mov    %ax,0x10d2a0
		break;
  1032b1:	eb 65                	jmp    103318 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  1032b3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1032ba:	e8 1e ff ff ff       	call   1031dd <video_putc>
		video_putc(' ');
  1032bf:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1032c6:	e8 12 ff ff ff       	call   1031dd <video_putc>
		video_putc(' ');
  1032cb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1032d2:	e8 06 ff ff ff       	call   1031dd <video_putc>
		video_putc(' ');
  1032d7:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1032de:	e8 fa fe ff ff       	call   1031dd <video_putc>
		video_putc(' ');
  1032e3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1032ea:	e8 ee fe ff ff       	call   1031dd <video_putc>
		break;
  1032ef:	eb 27                	jmp    103318 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  1032f1:	8b 15 9c d2 10 00    	mov    0x10d29c,%edx
  1032f7:	0f b7 05 a0 d2 10 00 	movzwl 0x10d2a0,%eax
  1032fe:	0f b7 c8             	movzwl %ax,%ecx
  103301:	01 c9                	add    %ecx,%ecx
  103303:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  103306:	8b 55 08             	mov    0x8(%ebp),%edx
  103309:	66 89 11             	mov    %dx,(%ecx)
  10330c:	83 c0 01             	add    $0x1,%eax
  10330f:	66 a3 a0 d2 10 00    	mov    %ax,0x10d2a0
  103315:	eb 01                	jmp    103318 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  103317:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  103318:	0f b7 05 a0 d2 10 00 	movzwl 0x10d2a0,%eax
  10331f:	66 3d cf 07          	cmp    $0x7cf,%ax
  103323:	76 5b                	jbe    103380 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  103325:	a1 9c d2 10 00       	mov    0x10d29c,%eax
  10332a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  103330:	a1 9c d2 10 00       	mov    0x10d29c,%eax
  103335:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  10333c:	00 
  10333d:	89 54 24 04          	mov    %edx,0x4(%esp)
  103341:	89 04 24             	mov    %eax,(%esp)
  103344:	e8 96 15 00 00       	call   1048df <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103349:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  103350:	eb 15                	jmp    103367 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  103352:	a1 9c d2 10 00       	mov    0x10d29c,%eax
  103357:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10335a:	01 d2                	add    %edx,%edx
  10335c:	01 d0                	add    %edx,%eax
  10335e:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103363:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  103367:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  10336e:	7e e2                	jle    103352 <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  103370:	0f b7 05 a0 d2 10 00 	movzwl 0x10d2a0,%eax
  103377:	83 e8 50             	sub    $0x50,%eax
  10337a:	66 a3 a0 d2 10 00    	mov    %ax,0x10d2a0
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  103380:	a1 98 d2 10 00       	mov    0x10d298,%eax
  103385:	89 45 dc             	mov    %eax,-0x24(%ebp)
  103388:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10338c:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103390:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103393:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  103394:	0f b7 05 a0 d2 10 00 	movzwl 0x10d2a0,%eax
  10339b:	66 c1 e8 08          	shr    $0x8,%ax
  10339f:	0f b6 c0             	movzbl %al,%eax
  1033a2:	8b 15 98 d2 10 00    	mov    0x10d298,%edx
  1033a8:	83 c2 01             	add    $0x1,%edx
  1033ab:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1033ae:	88 45 e3             	mov    %al,-0x1d(%ebp)
  1033b1:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1033b5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1033b8:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  1033b9:	a1 98 d2 10 00       	mov    0x10d298,%eax
  1033be:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1033c1:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  1033c5:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1033c9:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1033cc:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  1033cd:	0f b7 05 a0 d2 10 00 	movzwl 0x10d2a0,%eax
  1033d4:	0f b6 c0             	movzbl %al,%eax
  1033d7:	8b 15 98 d2 10 00    	mov    0x10d298,%edx
  1033dd:	83 c2 01             	add    $0x1,%edx
  1033e0:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1033e3:	88 45 f3             	mov    %al,-0xd(%ebp)
  1033e6:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1033ea:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1033ed:	ee                   	out    %al,(%dx)
}
  1033ee:	83 c4 44             	add    $0x44,%esp
  1033f1:	5b                   	pop    %ebx
  1033f2:	5d                   	pop    %ebp
  1033f3:	c3                   	ret    

001033f4 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  1033f4:	55                   	push   %ebp
  1033f5:	89 e5                	mov    %esp,%ebp
  1033f7:	83 ec 38             	sub    $0x38,%esp
  1033fa:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103401:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103404:	89 c2                	mov    %eax,%edx
  103406:	ec                   	in     (%dx),%al
  103407:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  10340a:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  10340e:	0f b6 c0             	movzbl %al,%eax
  103411:	83 e0 01             	and    $0x1,%eax
  103414:	85 c0                	test   %eax,%eax
  103416:	75 0a                	jne    103422 <kbd_proc_data+0x2e>
		return -1;
  103418:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10341d:	e9 5a 01 00 00       	jmp    10357c <kbd_proc_data+0x188>
  103422:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103429:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10342c:	89 c2                	mov    %eax,%edx
  10342e:	ec                   	in     (%dx),%al
  10342f:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  103432:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  103436:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  103439:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  10343d:	75 17                	jne    103456 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  10343f:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  103444:	83 c8 40             	or     $0x40,%eax
  103447:	a3 a4 d2 10 00       	mov    %eax,0x10d2a4
		return 0;
  10344c:	b8 00 00 00 00       	mov    $0x0,%eax
  103451:	e9 26 01 00 00       	jmp    10357c <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  103456:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10345a:	84 c0                	test   %al,%al
  10345c:	79 47                	jns    1034a5 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  10345e:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  103463:	83 e0 40             	and    $0x40,%eax
  103466:	85 c0                	test   %eax,%eax
  103468:	75 09                	jne    103473 <kbd_proc_data+0x7f>
  10346a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10346e:	83 e0 7f             	and    $0x7f,%eax
  103471:	eb 04                	jmp    103477 <kbd_proc_data+0x83>
  103473:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103477:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  10347a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10347e:	0f b6 80 a0 70 10 00 	movzbl 0x1070a0(%eax),%eax
  103485:	83 c8 40             	or     $0x40,%eax
  103488:	0f b6 c0             	movzbl %al,%eax
  10348b:	f7 d0                	not    %eax
  10348d:	89 c2                	mov    %eax,%edx
  10348f:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  103494:	21 d0                	and    %edx,%eax
  103496:	a3 a4 d2 10 00       	mov    %eax,0x10d2a4
		return 0;
  10349b:	b8 00 00 00 00       	mov    $0x0,%eax
  1034a0:	e9 d7 00 00 00       	jmp    10357c <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  1034a5:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  1034aa:	83 e0 40             	and    $0x40,%eax
  1034ad:	85 c0                	test   %eax,%eax
  1034af:	74 11                	je     1034c2 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  1034b1:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  1034b5:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  1034ba:	83 e0 bf             	and    $0xffffffbf,%eax
  1034bd:	a3 a4 d2 10 00       	mov    %eax,0x10d2a4
	}

	shift |= shiftcode[data];
  1034c2:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1034c6:	0f b6 80 a0 70 10 00 	movzbl 0x1070a0(%eax),%eax
  1034cd:	0f b6 d0             	movzbl %al,%edx
  1034d0:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  1034d5:	09 d0                	or     %edx,%eax
  1034d7:	a3 a4 d2 10 00       	mov    %eax,0x10d2a4
	shift ^= togglecode[data];
  1034dc:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1034e0:	0f b6 80 a0 71 10 00 	movzbl 0x1071a0(%eax),%eax
  1034e7:	0f b6 d0             	movzbl %al,%edx
  1034ea:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  1034ef:	31 d0                	xor    %edx,%eax
  1034f1:	a3 a4 d2 10 00       	mov    %eax,0x10d2a4

	c = charcode[shift & (CTL | SHIFT)][data];
  1034f6:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  1034fb:	83 e0 03             	and    $0x3,%eax
  1034fe:	8b 14 85 a0 75 10 00 	mov    0x1075a0(,%eax,4),%edx
  103505:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103509:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10350c:	0f b6 00             	movzbl (%eax),%eax
  10350f:	0f b6 c0             	movzbl %al,%eax
  103512:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  103515:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  10351a:	83 e0 08             	and    $0x8,%eax
  10351d:	85 c0                	test   %eax,%eax
  10351f:	74 22                	je     103543 <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  103521:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  103525:	7e 0c                	jle    103533 <kbd_proc_data+0x13f>
  103527:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  10352b:	7f 06                	jg     103533 <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  10352d:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  103531:	eb 10                	jmp    103543 <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  103533:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  103537:	7e 0a                	jle    103543 <kbd_proc_data+0x14f>
  103539:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  10353d:	7f 04                	jg     103543 <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  10353f:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  103543:	a1 a4 d2 10 00       	mov    0x10d2a4,%eax
  103548:	f7 d0                	not    %eax
  10354a:	83 e0 06             	and    $0x6,%eax
  10354d:	85 c0                	test   %eax,%eax
  10354f:	75 28                	jne    103579 <kbd_proc_data+0x185>
  103551:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  103558:	75 1f                	jne    103579 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  10355a:	c7 04 24 93 5b 10 00 	movl   $0x105b93,(%esp)
  103561:	e8 20 11 00 00       	call   104686 <cprintf>
  103566:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  10356d:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103571:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103575:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103578:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  103579:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  10357c:	c9                   	leave  
  10357d:	c3                   	ret    

0010357e <kbd_intr>:

void
kbd_intr(void)
{
  10357e:	55                   	push   %ebp
  10357f:	89 e5                	mov    %esp,%ebp
  103581:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  103584:	c7 04 24 f4 33 10 00 	movl   $0x1033f4,(%esp)
  10358b:	e8 d5 cc ff ff       	call   100265 <cons_intr>
}
  103590:	c9                   	leave  
  103591:	c3                   	ret    

00103592 <kbd_init>:

void
kbd_init(void)
{
  103592:	55                   	push   %ebp
  103593:	89 e5                	mov    %esp,%ebp
}
  103595:	5d                   	pop    %ebp
  103596:	c3                   	ret    

00103597 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  103597:	55                   	push   %ebp
  103598:	89 e5                	mov    %esp,%ebp
  10359a:	83 ec 20             	sub    $0x20,%esp
  10359d:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1035a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1035a7:	89 c2                	mov    %eax,%edx
  1035a9:	ec                   	in     (%dx),%al
  1035aa:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  1035ad:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1035b4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1035b7:	89 c2                	mov    %eax,%edx
  1035b9:	ec                   	in     (%dx),%al
  1035ba:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  1035bd:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1035c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1035c7:	89 c2                	mov    %eax,%edx
  1035c9:	ec                   	in     (%dx),%al
  1035ca:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  1035cd:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1035d4:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1035d7:	89 c2                	mov    %eax,%edx
  1035d9:	ec                   	in     (%dx),%al
  1035da:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  1035dd:	c9                   	leave  
  1035de:	c3                   	ret    

001035df <serial_proc_data>:

static int
serial_proc_data(void)
{
  1035df:	55                   	push   %ebp
  1035e0:	89 e5                	mov    %esp,%ebp
  1035e2:	83 ec 10             	sub    $0x10,%esp
  1035e5:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  1035ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1035ef:	89 c2                	mov    %eax,%edx
  1035f1:	ec                   	in     (%dx),%al
  1035f2:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  1035f5:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  1035f9:	0f b6 c0             	movzbl %al,%eax
  1035fc:	83 e0 01             	and    $0x1,%eax
  1035ff:	85 c0                	test   %eax,%eax
  103601:	75 07                	jne    10360a <serial_proc_data+0x2b>
		return -1;
  103603:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  103608:	eb 17                	jmp    103621 <serial_proc_data+0x42>
  10360a:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103611:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103614:	89 c2                	mov    %eax,%edx
  103616:	ec                   	in     (%dx),%al
  103617:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  10361a:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  10361e:	0f b6 c0             	movzbl %al,%eax
}
  103621:	c9                   	leave  
  103622:	c3                   	ret    

00103623 <serial_intr>:

void
serial_intr(void)
{
  103623:	55                   	push   %ebp
  103624:	89 e5                	mov    %esp,%ebp
  103626:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  103629:	a1 24 da 30 00       	mov    0x30da24,%eax
  10362e:	85 c0                	test   %eax,%eax
  103630:	74 0c                	je     10363e <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  103632:	c7 04 24 df 35 10 00 	movl   $0x1035df,(%esp)
  103639:	e8 27 cc ff ff       	call   100265 <cons_intr>
}
  10363e:	c9                   	leave  
  10363f:	c3                   	ret    

00103640 <serial_putc>:

void
serial_putc(int c)
{
  103640:	55                   	push   %ebp
  103641:	89 e5                	mov    %esp,%ebp
  103643:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  103646:	a1 24 da 30 00       	mov    0x30da24,%eax
  10364b:	85 c0                	test   %eax,%eax
  10364d:	74 53                	je     1036a2 <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  10364f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103656:	eb 09                	jmp    103661 <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  103658:	e8 3a ff ff ff       	call   103597 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  10365d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103661:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103668:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10366b:	89 c2                	mov    %eax,%edx
  10366d:	ec                   	in     (%dx),%al
  10366e:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  103671:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  103675:	0f b6 c0             	movzbl %al,%eax
  103678:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  10367b:	85 c0                	test   %eax,%eax
  10367d:	75 09                	jne    103688 <serial_putc+0x48>
  10367f:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  103686:	7e d0                	jle    103658 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  103688:	8b 45 08             	mov    0x8(%ebp),%eax
  10368b:	0f b6 c0             	movzbl %al,%eax
  10368e:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  103695:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103698:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  10369c:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10369f:	ee                   	out    %al,(%dx)
  1036a0:	eb 01                	jmp    1036a3 <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  1036a2:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  1036a3:	c9                   	leave  
  1036a4:	c3                   	ret    

001036a5 <serial_init>:

void
serial_init(void)
{
  1036a5:	55                   	push   %ebp
  1036a6:	89 e5                	mov    %esp,%ebp
  1036a8:	83 ec 50             	sub    $0x50,%esp
  1036ab:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  1036b2:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  1036b6:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  1036ba:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  1036bd:	ee                   	out    %al,(%dx)
  1036be:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  1036c5:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  1036c9:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  1036cd:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1036d0:	ee                   	out    %al,(%dx)
  1036d1:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  1036d8:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  1036dc:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  1036e0:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  1036e3:	ee                   	out    %al,(%dx)
  1036e4:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  1036eb:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  1036ef:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  1036f3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1036f6:	ee                   	out    %al,(%dx)
  1036f7:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  1036fe:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  103702:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  103706:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103709:	ee                   	out    %al,(%dx)
  10370a:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  103711:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  103715:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103719:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10371c:	ee                   	out    %al,(%dx)
  10371d:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  103724:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  103728:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10372c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10372f:	ee                   	out    %al,(%dx)
  103730:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103737:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10373a:	89 c2                	mov    %eax,%edx
  10373c:	ec                   	in     (%dx),%al
  10373d:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  103740:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  103744:	3c ff                	cmp    $0xff,%al
  103746:	0f 95 c0             	setne  %al
  103749:	0f b6 c0             	movzbl %al,%eax
  10374c:	a3 24 da 30 00       	mov    %eax,0x30da24
  103751:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103758:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10375b:	89 c2                	mov    %eax,%edx
  10375d:	ec                   	in     (%dx),%al
  10375e:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  103761:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103768:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10376b:	89 c2                	mov    %eax,%edx
  10376d:	ec                   	in     (%dx),%al
  10376e:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  103771:	c9                   	leave  
  103772:	c3                   	ret    

00103773 <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  103773:	55                   	push   %ebp
  103774:	89 e5                	mov    %esp,%ebp
  103776:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  10377c:	a1 a8 d2 10 00       	mov    0x10d2a8,%eax
  103781:	85 c0                	test   %eax,%eax
  103783:	0f 85 35 01 00 00    	jne    1038be <pic_init+0x14b>
		return;
	didinit = 1;
  103789:	c7 05 a8 d2 10 00 01 	movl   $0x1,0x10d2a8
  103790:	00 00 00 
  103793:	c7 45 8c 21 00 00 00 	movl   $0x21,-0x74(%ebp)
  10379a:	c6 45 8b ff          	movb   $0xff,-0x75(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10379e:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  1037a2:	8b 55 8c             	mov    -0x74(%ebp),%edx
  1037a5:	ee                   	out    %al,(%dx)
  1037a6:	c7 45 94 a1 00 00 00 	movl   $0xa1,-0x6c(%ebp)
  1037ad:	c6 45 93 ff          	movb   $0xff,-0x6d(%ebp)
  1037b1:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  1037b5:	8b 55 94             	mov    -0x6c(%ebp),%edx
  1037b8:	ee                   	out    %al,(%dx)
  1037b9:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  1037c0:	c6 45 9b 11          	movb   $0x11,-0x65(%ebp)
  1037c4:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  1037c8:	8b 55 9c             	mov    -0x64(%ebp),%edx
  1037cb:	ee                   	out    %al,(%dx)
  1037cc:	c7 45 a4 21 00 00 00 	movl   $0x21,-0x5c(%ebp)
  1037d3:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
  1037d7:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  1037db:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  1037de:	ee                   	out    %al,(%dx)
  1037df:	c7 45 ac 21 00 00 00 	movl   $0x21,-0x54(%ebp)
  1037e6:	c6 45 ab 04          	movb   $0x4,-0x55(%ebp)
  1037ea:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  1037ee:	8b 55 ac             	mov    -0x54(%ebp),%edx
  1037f1:	ee                   	out    %al,(%dx)
  1037f2:	c7 45 b4 21 00 00 00 	movl   $0x21,-0x4c(%ebp)
  1037f9:	c6 45 b3 03          	movb   $0x3,-0x4d(%ebp)
  1037fd:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  103801:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  103804:	ee                   	out    %al,(%dx)
  103805:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
  10380c:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
  103810:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  103814:	8b 55 bc             	mov    -0x44(%ebp),%edx
  103817:	ee                   	out    %al,(%dx)
  103818:	c7 45 c4 a1 00 00 00 	movl   $0xa1,-0x3c(%ebp)
  10381f:	c6 45 c3 28          	movb   $0x28,-0x3d(%ebp)
  103823:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  103827:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  10382a:	ee                   	out    %al,(%dx)
  10382b:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
  103832:	c6 45 cb 02          	movb   $0x2,-0x35(%ebp)
  103836:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  10383a:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10383d:	ee                   	out    %al,(%dx)
  10383e:	c7 45 d4 a1 00 00 00 	movl   $0xa1,-0x2c(%ebp)
  103845:	c6 45 d3 01          	movb   $0x1,-0x2d(%ebp)
  103849:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  10384d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103850:	ee                   	out    %al,(%dx)
  103851:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
  103858:	c6 45 db 68          	movb   $0x68,-0x25(%ebp)
  10385c:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103860:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103863:	ee                   	out    %al,(%dx)
  103864:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  10386b:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  10386f:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103873:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103876:	ee                   	out    %al,(%dx)
  103877:	c7 45 ec a0 00 00 00 	movl   $0xa0,-0x14(%ebp)
  10387e:	c6 45 eb 68          	movb   $0x68,-0x15(%ebp)
  103882:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  103886:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103889:	ee                   	out    %al,(%dx)
  10388a:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
  103891:	c6 45 f3 0a          	movb   $0xa,-0xd(%ebp)
  103895:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103899:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10389c:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  10389d:	0f b7 05 b0 75 10 00 	movzwl 0x1075b0,%eax
  1038a4:	66 83 f8 ff          	cmp    $0xffff,%ax
  1038a8:	74 15                	je     1038bf <pic_init+0x14c>
		pic_setmask(irqmask);
  1038aa:	0f b7 05 b0 75 10 00 	movzwl 0x1075b0,%eax
  1038b1:	0f b7 c0             	movzwl %ax,%eax
  1038b4:	89 04 24             	mov    %eax,(%esp)
  1038b7:	e8 05 00 00 00       	call   1038c1 <pic_setmask>
  1038bc:	eb 01                	jmp    1038bf <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  1038be:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  1038bf:	c9                   	leave  
  1038c0:	c3                   	ret    

001038c1 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  1038c1:	55                   	push   %ebp
  1038c2:	89 e5                	mov    %esp,%ebp
  1038c4:	83 ec 14             	sub    $0x14,%esp
  1038c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1038ca:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  1038ce:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1038d2:	66 a3 b0 75 10 00    	mov    %ax,0x1075b0
	outb(IO_PIC1+1, (char)mask);
  1038d8:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1038dc:	0f b6 c0             	movzbl %al,%eax
  1038df:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  1038e6:	88 45 f3             	mov    %al,-0xd(%ebp)
  1038e9:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1038ed:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1038f0:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  1038f1:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1038f5:	66 c1 e8 08          	shr    $0x8,%ax
  1038f9:	0f b6 c0             	movzbl %al,%eax
  1038fc:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
  103903:	88 45 fb             	mov    %al,-0x5(%ebp)
  103906:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  10390a:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10390d:	ee                   	out    %al,(%dx)
}
  10390e:	c9                   	leave  
  10390f:	c3                   	ret    

00103910 <pic_enable>:

void
pic_enable(int irq)
{
  103910:	55                   	push   %ebp
  103911:	89 e5                	mov    %esp,%ebp
  103913:	53                   	push   %ebx
  103914:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  103917:	8b 45 08             	mov    0x8(%ebp),%eax
  10391a:	ba 01 00 00 00       	mov    $0x1,%edx
  10391f:	89 d3                	mov    %edx,%ebx
  103921:	89 c1                	mov    %eax,%ecx
  103923:	d3 e3                	shl    %cl,%ebx
  103925:	89 d8                	mov    %ebx,%eax
  103927:	89 c2                	mov    %eax,%edx
  103929:	f7 d2                	not    %edx
  10392b:	0f b7 05 b0 75 10 00 	movzwl 0x1075b0,%eax
  103932:	21 d0                	and    %edx,%eax
  103934:	0f b7 c0             	movzwl %ax,%eax
  103937:	89 04 24             	mov    %eax,(%esp)
  10393a:	e8 82 ff ff ff       	call   1038c1 <pic_setmask>
}
  10393f:	83 c4 04             	add    $0x4,%esp
  103942:	5b                   	pop    %ebx
  103943:	5d                   	pop    %ebp
  103944:	c3                   	ret    

00103945 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  103945:	55                   	push   %ebp
  103946:	89 e5                	mov    %esp,%ebp
  103948:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10394b:	8b 45 08             	mov    0x8(%ebp),%eax
  10394e:	0f b6 c0             	movzbl %al,%eax
  103951:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  103958:	88 45 f3             	mov    %al,-0xd(%ebp)
  10395b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10395f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103962:	ee                   	out    %al,(%dx)
  103963:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10396a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10396d:	89 c2                	mov    %eax,%edx
  10396f:	ec                   	in     (%dx),%al
  103970:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  103973:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  103977:	0f b6 c0             	movzbl %al,%eax
}
  10397a:	c9                   	leave  
  10397b:	c3                   	ret    

0010397c <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  10397c:	55                   	push   %ebp
  10397d:	89 e5                	mov    %esp,%ebp
  10397f:	53                   	push   %ebx
  103980:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  103983:	8b 45 08             	mov    0x8(%ebp),%eax
  103986:	89 04 24             	mov    %eax,(%esp)
  103989:	e8 b7 ff ff ff       	call   103945 <nvram_read>
  10398e:	89 c3                	mov    %eax,%ebx
  103990:	8b 45 08             	mov    0x8(%ebp),%eax
  103993:	83 c0 01             	add    $0x1,%eax
  103996:	89 04 24             	mov    %eax,(%esp)
  103999:	e8 a7 ff ff ff       	call   103945 <nvram_read>
  10399e:	c1 e0 08             	shl    $0x8,%eax
  1039a1:	09 d8                	or     %ebx,%eax
}
  1039a3:	83 c4 04             	add    $0x4,%esp
  1039a6:	5b                   	pop    %ebx
  1039a7:	5d                   	pop    %ebp
  1039a8:	c3                   	ret    

001039a9 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  1039a9:	55                   	push   %ebp
  1039aa:	89 e5                	mov    %esp,%ebp
  1039ac:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  1039af:	8b 45 08             	mov    0x8(%ebp),%eax
  1039b2:	0f b6 c0             	movzbl %al,%eax
  1039b5:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1039bc:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1039bf:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1039c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1039c6:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  1039c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1039ca:	0f b6 c0             	movzbl %al,%eax
  1039cd:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  1039d4:	88 45 fb             	mov    %al,-0x5(%ebp)
  1039d7:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1039db:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1039de:	ee                   	out    %al,(%dx)
}
  1039df:	c9                   	leave  
  1039e0:	c3                   	ret    

001039e1 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1039e1:	55                   	push   %ebp
  1039e2:	89 e5                	mov    %esp,%ebp
  1039e4:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1039e7:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1039ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1039ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1039f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039f3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1039f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1039fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1039fe:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103a04:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103a09:	74 24                	je     103a2f <cpu_cur+0x4e>
  103a0b:	c7 44 24 0c 9f 5b 10 	movl   $0x105b9f,0xc(%esp)
  103a12:	00 
  103a13:	c7 44 24 08 b5 5b 10 	movl   $0x105bb5,0x8(%esp)
  103a1a:	00 
  103a1b:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103a22:	00 
  103a23:	c7 04 24 ca 5b 10 00 	movl   $0x105bca,(%esp)
  103a2a:	e8 01 ca ff ff       	call   100430 <debug_panic>
	return c;
  103a2f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103a32:	c9                   	leave  
  103a33:	c3                   	ret    

00103a34 <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  103a34:	55                   	push   %ebp
  103a35:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  103a37:	a1 28 da 30 00       	mov    0x30da28,%eax
  103a3c:	8b 55 08             	mov    0x8(%ebp),%edx
  103a3f:	c1 e2 02             	shl    $0x2,%edx
  103a42:	8d 14 10             	lea    (%eax,%edx,1),%edx
  103a45:	8b 45 0c             	mov    0xc(%ebp),%eax
  103a48:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  103a4a:	a1 28 da 30 00       	mov    0x30da28,%eax
  103a4f:	83 c0 20             	add    $0x20,%eax
  103a52:	8b 00                	mov    (%eax),%eax
}
  103a54:	5d                   	pop    %ebp
  103a55:	c3                   	ret    

00103a56 <lapic_init>:

void
lapic_init()
{
  103a56:	55                   	push   %ebp
  103a57:	89 e5                	mov    %esp,%ebp
  103a59:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  103a5c:	a1 28 da 30 00       	mov    0x30da28,%eax
  103a61:	85 c0                	test   %eax,%eax
  103a63:	0f 84 82 01 00 00    	je     103beb <lapic_init+0x195>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  103a69:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  103a70:	00 
  103a71:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  103a78:	e8 b7 ff ff ff       	call   103a34 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  103a7d:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  103a84:	00 
  103a85:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  103a8c:	e8 a3 ff ff ff       	call   103a34 <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  103a91:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  103a98:	00 
  103a99:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  103aa0:	e8 8f ff ff ff       	call   103a34 <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  103aa5:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  103aac:	00 
  103aad:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  103ab4:	e8 7b ff ff ff       	call   103a34 <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  103ab9:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  103ac0:	00 
  103ac1:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  103ac8:	e8 67 ff ff ff       	call   103a34 <lapicw>
	lapicw(LINT1, MASKED);
  103acd:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  103ad4:	00 
  103ad5:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  103adc:	e8 53 ff ff ff       	call   103a34 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  103ae1:	a1 28 da 30 00       	mov    0x30da28,%eax
  103ae6:	83 c0 30             	add    $0x30,%eax
  103ae9:	8b 00                	mov    (%eax),%eax
  103aeb:	c1 e8 10             	shr    $0x10,%eax
  103aee:	25 ff 00 00 00       	and    $0xff,%eax
  103af3:	83 f8 03             	cmp    $0x3,%eax
  103af6:	76 14                	jbe    103b0c <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  103af8:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  103aff:	00 
  103b00:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  103b07:	e8 28 ff ff ff       	call   103a34 <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  103b0c:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  103b13:	00 
  103b14:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  103b1b:	e8 14 ff ff ff       	call   103a34 <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  103b20:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  103b27:	ff 
  103b28:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  103b2f:	e8 00 ff ff ff       	call   103a34 <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  103b34:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  103b3b:	f0 
  103b3c:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  103b43:	e8 ec fe ff ff       	call   103a34 <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  103b48:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103b4f:	00 
  103b50:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103b57:	e8 d8 fe ff ff       	call   103a34 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  103b5c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103b63:	00 
  103b64:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  103b6b:	e8 c4 fe ff ff       	call   103a34 <lapicw>
	lapicw(ESR, 0);
  103b70:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103b77:	00 
  103b78:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  103b7f:	e8 b0 fe ff ff       	call   103a34 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  103b84:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103b8b:	00 
  103b8c:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  103b93:	e8 9c fe ff ff       	call   103a34 <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  103b98:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103b9f:	00 
  103ba0:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  103ba7:	e8 88 fe ff ff       	call   103a34 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  103bac:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  103bb3:	00 
  103bb4:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  103bbb:	e8 74 fe ff ff       	call   103a34 <lapicw>
	while(lapic[ICRLO] & DELIVS)
  103bc0:	a1 28 da 30 00       	mov    0x30da28,%eax
  103bc5:	05 00 03 00 00       	add    $0x300,%eax
  103bca:	8b 00                	mov    (%eax),%eax
  103bcc:	25 00 10 00 00       	and    $0x1000,%eax
  103bd1:	85 c0                	test   %eax,%eax
  103bd3:	75 eb                	jne    103bc0 <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  103bd5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103bdc:	00 
  103bdd:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103be4:	e8 4b fe ff ff       	call   103a34 <lapicw>
  103be9:	eb 01                	jmp    103bec <lapic_init+0x196>

void
lapic_init()
{
	if (!lapic) 
		return;
  103beb:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  103bec:	c9                   	leave  
  103bed:	c3                   	ret    

00103bee <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  103bee:	55                   	push   %ebp
  103bef:	89 e5                	mov    %esp,%ebp
  103bf1:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  103bf4:	a1 28 da 30 00       	mov    0x30da28,%eax
  103bf9:	85 c0                	test   %eax,%eax
  103bfb:	74 14                	je     103c11 <lapic_eoi+0x23>
		lapicw(EOI, 0);
  103bfd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103c04:	00 
  103c05:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  103c0c:	e8 23 fe ff ff       	call   103a34 <lapicw>
}
  103c11:	c9                   	leave  
  103c12:	c3                   	ret    

00103c13 <lapic_errintr>:

void lapic_errintr(void)
{
  103c13:	55                   	push   %ebp
  103c14:	89 e5                	mov    %esp,%ebp
  103c16:	53                   	push   %ebx
  103c17:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  103c1a:	e8 cf ff ff ff       	call   103bee <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  103c1f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103c26:	00 
  103c27:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  103c2e:	e8 01 fe ff ff       	call   103a34 <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  103c33:	a1 28 da 30 00       	mov    0x30da28,%eax
  103c38:	05 80 02 00 00       	add    $0x280,%eax
  103c3d:	8b 18                	mov    (%eax),%ebx
  103c3f:	e8 9d fd ff ff       	call   1039e1 <cpu_cur>
  103c44:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  103c4b:	0f b6 c0             	movzbl %al,%eax
  103c4e:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  103c52:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103c56:	c7 44 24 08 d7 5b 10 	movl   $0x105bd7,0x8(%esp)
  103c5d:	00 
  103c5e:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  103c65:	00 
  103c66:	c7 04 24 f1 5b 10 00 	movl   $0x105bf1,(%esp)
  103c6d:	e8 7d c8 ff ff       	call   1004ef <debug_warn>
}
  103c72:	83 c4 24             	add    $0x24,%esp
  103c75:	5b                   	pop    %ebx
  103c76:	5d                   	pop    %ebp
  103c77:	c3                   	ret    

00103c78 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  103c78:	55                   	push   %ebp
  103c79:	89 e5                	mov    %esp,%ebp
}
  103c7b:	5d                   	pop    %ebp
  103c7c:	c3                   	ret    

00103c7d <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  103c7d:	55                   	push   %ebp
  103c7e:	89 e5                	mov    %esp,%ebp
  103c80:	83 ec 2c             	sub    $0x2c,%esp
  103c83:	8b 45 08             	mov    0x8(%ebp),%eax
  103c86:	88 45 dc             	mov    %al,-0x24(%ebp)
  103c89:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  103c90:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103c94:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103c98:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103c9b:	ee                   	out    %al,(%dx)
  103c9c:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  103ca3:	c6 45 fb 0a          	movb   $0xa,-0x5(%ebp)
  103ca7:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  103cab:	8b 55 fc             	mov    -0x4(%ebp),%edx
  103cae:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  103caf:	c7 45 ec 67 04 00 00 	movl   $0x467,-0x14(%ebp)
	wrv[0] = 0;
  103cb6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103cb9:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  103cbe:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103cc1:	8d 50 02             	lea    0x2(%eax),%edx
  103cc4:	8b 45 0c             	mov    0xc(%ebp),%eax
  103cc7:	c1 e8 04             	shr    $0x4,%eax
  103cca:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  103ccd:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  103cd1:	c1 e0 18             	shl    $0x18,%eax
  103cd4:	89 44 24 04          	mov    %eax,0x4(%esp)
  103cd8:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  103cdf:	e8 50 fd ff ff       	call   103a34 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  103ce4:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  103ceb:	00 
  103cec:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  103cf3:	e8 3c fd ff ff       	call   103a34 <lapicw>
	microdelay(200);
  103cf8:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  103cff:	e8 74 ff ff ff       	call   103c78 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  103d04:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  103d0b:	00 
  103d0c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  103d13:	e8 1c fd ff ff       	call   103a34 <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  103d18:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  103d1f:	e8 54 ff ff ff       	call   103c78 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  103d24:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  103d2b:	eb 40                	jmp    103d6d <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  103d2d:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  103d31:	c1 e0 18             	shl    $0x18,%eax
  103d34:	89 44 24 04          	mov    %eax,0x4(%esp)
  103d38:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  103d3f:	e8 f0 fc ff ff       	call   103a34 <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  103d44:	8b 45 0c             	mov    0xc(%ebp),%eax
  103d47:	c1 e8 0c             	shr    $0xc,%eax
  103d4a:	80 cc 06             	or     $0x6,%ah
  103d4d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103d51:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  103d58:	e8 d7 fc ff ff       	call   103a34 <lapicw>
		microdelay(200);
  103d5d:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  103d64:	e8 0f ff ff ff       	call   103c78 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  103d69:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  103d6d:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
  103d71:	7e ba                	jle    103d2d <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  103d73:	c9                   	leave  
  103d74:	c3                   	ret    

00103d75 <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  103d75:	55                   	push   %ebp
  103d76:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  103d78:	a1 60 d3 30 00       	mov    0x30d360,%eax
  103d7d:	8b 55 08             	mov    0x8(%ebp),%edx
  103d80:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  103d82:	a1 60 d3 30 00       	mov    0x30d360,%eax
  103d87:	8b 40 10             	mov    0x10(%eax),%eax
}
  103d8a:	5d                   	pop    %ebp
  103d8b:	c3                   	ret    

00103d8c <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  103d8c:	55                   	push   %ebp
  103d8d:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  103d8f:	a1 60 d3 30 00       	mov    0x30d360,%eax
  103d94:	8b 55 08             	mov    0x8(%ebp),%edx
  103d97:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  103d99:	a1 60 d3 30 00       	mov    0x30d360,%eax
  103d9e:	8b 55 0c             	mov    0xc(%ebp),%edx
  103da1:	89 50 10             	mov    %edx,0x10(%eax)
}
  103da4:	5d                   	pop    %ebp
  103da5:	c3                   	ret    

00103da6 <ioapic_init>:

void
ioapic_init(void)
{
  103da6:	55                   	push   %ebp
  103da7:	89 e5                	mov    %esp,%ebp
  103da9:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  103dac:	a1 64 d3 30 00       	mov    0x30d364,%eax
  103db1:	85 c0                	test   %eax,%eax
  103db3:	0f 84 fd 00 00 00    	je     103eb6 <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  103db9:	a1 60 d3 30 00       	mov    0x30d360,%eax
  103dbe:	85 c0                	test   %eax,%eax
  103dc0:	75 0a                	jne    103dcc <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  103dc2:	c7 05 60 d3 30 00 00 	movl   $0xfec00000,0x30d360
  103dc9:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  103dcc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  103dd3:	e8 9d ff ff ff       	call   103d75 <ioapic_read>
  103dd8:	c1 e8 10             	shr    $0x10,%eax
  103ddb:	25 ff 00 00 00       	and    $0xff,%eax
  103de0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  103de3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  103dea:	e8 86 ff ff ff       	call   103d75 <ioapic_read>
  103def:	c1 e8 18             	shr    $0x18,%eax
  103df2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  103df5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  103df9:	75 2a                	jne    103e25 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  103dfb:	0f b6 05 5c d3 30 00 	movzbl 0x30d35c,%eax
  103e02:	0f b6 c0             	movzbl %al,%eax
  103e05:	c1 e0 18             	shl    $0x18,%eax
  103e08:	89 44 24 04          	mov    %eax,0x4(%esp)
  103e0c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  103e13:	e8 74 ff ff ff       	call   103d8c <ioapic_write>
		id = ioapicid;
  103e18:	0f b6 05 5c d3 30 00 	movzbl 0x30d35c,%eax
  103e1f:	0f b6 c0             	movzbl %al,%eax
  103e22:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  103e25:	0f b6 05 5c d3 30 00 	movzbl 0x30d35c,%eax
  103e2c:	0f b6 c0             	movzbl %al,%eax
  103e2f:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  103e32:	74 31                	je     103e65 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  103e34:	0f b6 05 5c d3 30 00 	movzbl 0x30d35c,%eax
  103e3b:	0f b6 c0             	movzbl %al,%eax
  103e3e:	89 44 24 10          	mov    %eax,0x10(%esp)
  103e42:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103e45:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103e49:	c7 44 24 08 00 5c 10 	movl   $0x105c00,0x8(%esp)
  103e50:	00 
  103e51:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  103e58:	00 
  103e59:	c7 04 24 21 5c 10 00 	movl   $0x105c21,(%esp)
  103e60:	e8 8a c6 ff ff       	call   1004ef <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  103e65:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  103e6c:	eb 3e                	jmp    103eac <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  103e6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103e71:	83 c0 20             	add    $0x20,%eax
  103e74:	0d 00 00 01 00       	or     $0x10000,%eax
  103e79:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103e7c:	83 c2 08             	add    $0x8,%edx
  103e7f:	01 d2                	add    %edx,%edx
  103e81:	89 44 24 04          	mov    %eax,0x4(%esp)
  103e85:	89 14 24             	mov    %edx,(%esp)
  103e88:	e8 ff fe ff ff       	call   103d8c <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  103e8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103e90:	83 c0 08             	add    $0x8,%eax
  103e93:	01 c0                	add    %eax,%eax
  103e95:	83 c0 01             	add    $0x1,%eax
  103e98:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103e9f:	00 
  103ea0:	89 04 24             	mov    %eax,(%esp)
  103ea3:	e8 e4 fe ff ff       	call   103d8c <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  103ea8:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  103eac:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103eaf:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  103eb2:	7e ba                	jle    103e6e <ioapic_init+0xc8>
  103eb4:	eb 01                	jmp    103eb7 <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  103eb6:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  103eb7:	c9                   	leave  
  103eb8:	c3                   	ret    

00103eb9 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  103eb9:	55                   	push   %ebp
  103eba:	89 e5                	mov    %esp,%ebp
  103ebc:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  103ebf:	a1 64 d3 30 00       	mov    0x30d364,%eax
  103ec4:	85 c0                	test   %eax,%eax
  103ec6:	74 3a                	je     103f02 <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  103ec8:	8b 45 08             	mov    0x8(%ebp),%eax
  103ecb:	83 c0 20             	add    $0x20,%eax
  103ece:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  103ed1:	8b 55 08             	mov    0x8(%ebp),%edx
  103ed4:	83 c2 08             	add    $0x8,%edx
  103ed7:	01 d2                	add    %edx,%edx
  103ed9:	89 44 24 04          	mov    %eax,0x4(%esp)
  103edd:	89 14 24             	mov    %edx,(%esp)
  103ee0:	e8 a7 fe ff ff       	call   103d8c <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  103ee5:	8b 45 08             	mov    0x8(%ebp),%eax
  103ee8:	83 c0 08             	add    $0x8,%eax
  103eeb:	01 c0                	add    %eax,%eax
  103eed:	83 c0 01             	add    $0x1,%eax
  103ef0:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  103ef7:	ff 
  103ef8:	89 04 24             	mov    %eax,(%esp)
  103efb:	e8 8c fe ff ff       	call   103d8c <ioapic_write>
  103f00:	eb 01                	jmp    103f03 <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  103f02:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  103f03:	c9                   	leave  
  103f04:	c3                   	ret    

00103f05 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  103f05:	55                   	push   %ebp
  103f06:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  103f08:	8b 45 08             	mov    0x8(%ebp),%eax
  103f0b:	8b 40 18             	mov    0x18(%eax),%eax
  103f0e:	83 e0 02             	and    $0x2,%eax
  103f11:	85 c0                	test   %eax,%eax
  103f13:	74 1c                	je     103f31 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  103f15:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f18:	8b 00                	mov    (%eax),%eax
  103f1a:	8d 50 08             	lea    0x8(%eax),%edx
  103f1d:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f20:	89 10                	mov    %edx,(%eax)
  103f22:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f25:	8b 00                	mov    (%eax),%eax
  103f27:	83 e8 08             	sub    $0x8,%eax
  103f2a:	8b 50 04             	mov    0x4(%eax),%edx
  103f2d:	8b 00                	mov    (%eax),%eax
  103f2f:	eb 47                	jmp    103f78 <getuint+0x73>
	else if (st->flags & F_L)
  103f31:	8b 45 08             	mov    0x8(%ebp),%eax
  103f34:	8b 40 18             	mov    0x18(%eax),%eax
  103f37:	83 e0 01             	and    $0x1,%eax
  103f3a:	84 c0                	test   %al,%al
  103f3c:	74 1e                	je     103f5c <getuint+0x57>
		return va_arg(*ap, unsigned long);
  103f3e:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f41:	8b 00                	mov    (%eax),%eax
  103f43:	8d 50 04             	lea    0x4(%eax),%edx
  103f46:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f49:	89 10                	mov    %edx,(%eax)
  103f4b:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f4e:	8b 00                	mov    (%eax),%eax
  103f50:	83 e8 04             	sub    $0x4,%eax
  103f53:	8b 00                	mov    (%eax),%eax
  103f55:	ba 00 00 00 00       	mov    $0x0,%edx
  103f5a:	eb 1c                	jmp    103f78 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  103f5c:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f5f:	8b 00                	mov    (%eax),%eax
  103f61:	8d 50 04             	lea    0x4(%eax),%edx
  103f64:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f67:	89 10                	mov    %edx,(%eax)
  103f69:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f6c:	8b 00                	mov    (%eax),%eax
  103f6e:	83 e8 04             	sub    $0x4,%eax
  103f71:	8b 00                	mov    (%eax),%eax
  103f73:	ba 00 00 00 00       	mov    $0x0,%edx
}
  103f78:	5d                   	pop    %ebp
  103f79:	c3                   	ret    

00103f7a <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  103f7a:	55                   	push   %ebp
  103f7b:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  103f7d:	8b 45 08             	mov    0x8(%ebp),%eax
  103f80:	8b 40 18             	mov    0x18(%eax),%eax
  103f83:	83 e0 02             	and    $0x2,%eax
  103f86:	85 c0                	test   %eax,%eax
  103f88:	74 1c                	je     103fa6 <getint+0x2c>
		return va_arg(*ap, long long);
  103f8a:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f8d:	8b 00                	mov    (%eax),%eax
  103f8f:	8d 50 08             	lea    0x8(%eax),%edx
  103f92:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f95:	89 10                	mov    %edx,(%eax)
  103f97:	8b 45 0c             	mov    0xc(%ebp),%eax
  103f9a:	8b 00                	mov    (%eax),%eax
  103f9c:	83 e8 08             	sub    $0x8,%eax
  103f9f:	8b 50 04             	mov    0x4(%eax),%edx
  103fa2:	8b 00                	mov    (%eax),%eax
  103fa4:	eb 47                	jmp    103fed <getint+0x73>
	else if (st->flags & F_L)
  103fa6:	8b 45 08             	mov    0x8(%ebp),%eax
  103fa9:	8b 40 18             	mov    0x18(%eax),%eax
  103fac:	83 e0 01             	and    $0x1,%eax
  103faf:	84 c0                	test   %al,%al
  103fb1:	74 1e                	je     103fd1 <getint+0x57>
		return va_arg(*ap, long);
  103fb3:	8b 45 0c             	mov    0xc(%ebp),%eax
  103fb6:	8b 00                	mov    (%eax),%eax
  103fb8:	8d 50 04             	lea    0x4(%eax),%edx
  103fbb:	8b 45 0c             	mov    0xc(%ebp),%eax
  103fbe:	89 10                	mov    %edx,(%eax)
  103fc0:	8b 45 0c             	mov    0xc(%ebp),%eax
  103fc3:	8b 00                	mov    (%eax),%eax
  103fc5:	83 e8 04             	sub    $0x4,%eax
  103fc8:	8b 00                	mov    (%eax),%eax
  103fca:	89 c2                	mov    %eax,%edx
  103fcc:	c1 fa 1f             	sar    $0x1f,%edx
  103fcf:	eb 1c                	jmp    103fed <getint+0x73>
	else
		return va_arg(*ap, int);
  103fd1:	8b 45 0c             	mov    0xc(%ebp),%eax
  103fd4:	8b 00                	mov    (%eax),%eax
  103fd6:	8d 50 04             	lea    0x4(%eax),%edx
  103fd9:	8b 45 0c             	mov    0xc(%ebp),%eax
  103fdc:	89 10                	mov    %edx,(%eax)
  103fde:	8b 45 0c             	mov    0xc(%ebp),%eax
  103fe1:	8b 00                	mov    (%eax),%eax
  103fe3:	83 e8 04             	sub    $0x4,%eax
  103fe6:	8b 00                	mov    (%eax),%eax
  103fe8:	89 c2                	mov    %eax,%edx
  103fea:	c1 fa 1f             	sar    $0x1f,%edx
}
  103fed:	5d                   	pop    %ebp
  103fee:	c3                   	ret    

00103fef <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  103fef:	55                   	push   %ebp
  103ff0:	89 e5                	mov    %esp,%ebp
  103ff2:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  103ff5:	eb 1a                	jmp    104011 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  103ff7:	8b 45 08             	mov    0x8(%ebp),%eax
  103ffa:	8b 08                	mov    (%eax),%ecx
  103ffc:	8b 45 08             	mov    0x8(%ebp),%eax
  103fff:	8b 50 04             	mov    0x4(%eax),%edx
  104002:	8b 45 08             	mov    0x8(%ebp),%eax
  104005:	8b 40 08             	mov    0x8(%eax),%eax
  104008:	89 54 24 04          	mov    %edx,0x4(%esp)
  10400c:	89 04 24             	mov    %eax,(%esp)
  10400f:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  104011:	8b 45 08             	mov    0x8(%ebp),%eax
  104014:	8b 40 0c             	mov    0xc(%eax),%eax
  104017:	8d 50 ff             	lea    -0x1(%eax),%edx
  10401a:	8b 45 08             	mov    0x8(%ebp),%eax
  10401d:	89 50 0c             	mov    %edx,0xc(%eax)
  104020:	8b 45 08             	mov    0x8(%ebp),%eax
  104023:	8b 40 0c             	mov    0xc(%eax),%eax
  104026:	85 c0                	test   %eax,%eax
  104028:	79 cd                	jns    103ff7 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  10402a:	c9                   	leave  
  10402b:	c3                   	ret    

0010402c <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  10402c:	55                   	push   %ebp
  10402d:	89 e5                	mov    %esp,%ebp
  10402f:	53                   	push   %ebx
  104030:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  104033:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104037:	79 18                	jns    104051 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  104039:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104040:	00 
  104041:	8b 45 0c             	mov    0xc(%ebp),%eax
  104044:	89 04 24             	mov    %eax,(%esp)
  104047:	e8 e7 07 00 00       	call   104833 <strchr>
  10404c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10404f:	eb 2c                	jmp    10407d <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  104051:	8b 45 10             	mov    0x10(%ebp),%eax
  104054:	89 44 24 08          	mov    %eax,0x8(%esp)
  104058:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10405f:	00 
  104060:	8b 45 0c             	mov    0xc(%ebp),%eax
  104063:	89 04 24             	mov    %eax,(%esp)
  104066:	e8 cc 09 00 00       	call   104a37 <memchr>
  10406b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10406e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104072:	75 09                	jne    10407d <putstr+0x51>
		lim = str + maxlen;
  104074:	8b 45 10             	mov    0x10(%ebp),%eax
  104077:	03 45 0c             	add    0xc(%ebp),%eax
  10407a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  10407d:	8b 45 08             	mov    0x8(%ebp),%eax
  104080:	8b 40 0c             	mov    0xc(%eax),%eax
  104083:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  104086:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104089:	89 cb                	mov    %ecx,%ebx
  10408b:	29 d3                	sub    %edx,%ebx
  10408d:	89 da                	mov    %ebx,%edx
  10408f:	8d 14 10             	lea    (%eax,%edx,1),%edx
  104092:	8b 45 08             	mov    0x8(%ebp),%eax
  104095:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  104098:	8b 45 08             	mov    0x8(%ebp),%eax
  10409b:	8b 40 18             	mov    0x18(%eax),%eax
  10409e:	83 e0 10             	and    $0x10,%eax
  1040a1:	85 c0                	test   %eax,%eax
  1040a3:	75 32                	jne    1040d7 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  1040a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1040a8:	89 04 24             	mov    %eax,(%esp)
  1040ab:	e8 3f ff ff ff       	call   103fef <putpad>
	while (str < lim) {
  1040b0:	eb 25                	jmp    1040d7 <putstr+0xab>
		char ch = *str++;
  1040b2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1040b5:	0f b6 00             	movzbl (%eax),%eax
  1040b8:	88 45 f7             	mov    %al,-0x9(%ebp)
  1040bb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  1040bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1040c2:	8b 08                	mov    (%eax),%ecx
  1040c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1040c7:	8b 50 04             	mov    0x4(%eax),%edx
  1040ca:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  1040ce:	89 54 24 04          	mov    %edx,0x4(%esp)
  1040d2:	89 04 24             	mov    %eax,(%esp)
  1040d5:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  1040d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1040da:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1040dd:	72 d3                	jb     1040b2 <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  1040df:	8b 45 08             	mov    0x8(%ebp),%eax
  1040e2:	89 04 24             	mov    %eax,(%esp)
  1040e5:	e8 05 ff ff ff       	call   103fef <putpad>
}
  1040ea:	83 c4 24             	add    $0x24,%esp
  1040ed:	5b                   	pop    %ebx
  1040ee:	5d                   	pop    %ebp
  1040ef:	c3                   	ret    

001040f0 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  1040f0:	55                   	push   %ebp
  1040f1:	89 e5                	mov    %esp,%ebp
  1040f3:	53                   	push   %ebx
  1040f4:	83 ec 24             	sub    $0x24,%esp
  1040f7:	8b 45 10             	mov    0x10(%ebp),%eax
  1040fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1040fd:	8b 45 14             	mov    0x14(%ebp),%eax
  104100:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  104103:	8b 45 08             	mov    0x8(%ebp),%eax
  104106:	8b 40 1c             	mov    0x1c(%eax),%eax
  104109:	89 c2                	mov    %eax,%edx
  10410b:	c1 fa 1f             	sar    $0x1f,%edx
  10410e:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104111:	77 4e                	ja     104161 <genint+0x71>
  104113:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104116:	72 05                	jb     10411d <genint+0x2d>
  104118:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10411b:	77 44                	ja     104161 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  10411d:	8b 45 08             	mov    0x8(%ebp),%eax
  104120:	8b 40 1c             	mov    0x1c(%eax),%eax
  104123:	89 c2                	mov    %eax,%edx
  104125:	c1 fa 1f             	sar    $0x1f,%edx
  104128:	89 44 24 08          	mov    %eax,0x8(%esp)
  10412c:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104130:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104133:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104136:	89 04 24             	mov    %eax,(%esp)
  104139:	89 54 24 04          	mov    %edx,0x4(%esp)
  10413d:	e8 2e 09 00 00       	call   104a70 <__udivdi3>
  104142:	89 44 24 08          	mov    %eax,0x8(%esp)
  104146:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10414a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10414d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104151:	8b 45 08             	mov    0x8(%ebp),%eax
  104154:	89 04 24             	mov    %eax,(%esp)
  104157:	e8 94 ff ff ff       	call   1040f0 <genint>
  10415c:	89 45 0c             	mov    %eax,0xc(%ebp)
  10415f:	eb 1b                	jmp    10417c <genint+0x8c>
	else if (st->signc >= 0)
  104161:	8b 45 08             	mov    0x8(%ebp),%eax
  104164:	8b 40 14             	mov    0x14(%eax),%eax
  104167:	85 c0                	test   %eax,%eax
  104169:	78 11                	js     10417c <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  10416b:	8b 45 08             	mov    0x8(%ebp),%eax
  10416e:	8b 40 14             	mov    0x14(%eax),%eax
  104171:	89 c2                	mov    %eax,%edx
  104173:	8b 45 0c             	mov    0xc(%ebp),%eax
  104176:	88 10                	mov    %dl,(%eax)
  104178:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  10417c:	8b 45 08             	mov    0x8(%ebp),%eax
  10417f:	8b 40 1c             	mov    0x1c(%eax),%eax
  104182:	89 c1                	mov    %eax,%ecx
  104184:	89 c3                	mov    %eax,%ebx
  104186:	c1 fb 1f             	sar    $0x1f,%ebx
  104189:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10418c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10418f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  104193:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  104197:	89 04 24             	mov    %eax,(%esp)
  10419a:	89 54 24 04          	mov    %edx,0x4(%esp)
  10419e:	e8 fd 09 00 00       	call   104ba0 <__umoddi3>
  1041a3:	05 30 5c 10 00       	add    $0x105c30,%eax
  1041a8:	0f b6 10             	movzbl (%eax),%edx
  1041ab:	8b 45 0c             	mov    0xc(%ebp),%eax
  1041ae:	88 10                	mov    %dl,(%eax)
  1041b0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  1041b4:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  1041b7:	83 c4 24             	add    $0x24,%esp
  1041ba:	5b                   	pop    %ebx
  1041bb:	5d                   	pop    %ebp
  1041bc:	c3                   	ret    

001041bd <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  1041bd:	55                   	push   %ebp
  1041be:	89 e5                	mov    %esp,%ebp
  1041c0:	83 ec 58             	sub    $0x58,%esp
  1041c3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1041c6:	89 45 c0             	mov    %eax,-0x40(%ebp)
  1041c9:	8b 45 10             	mov    0x10(%ebp),%eax
  1041cc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  1041cf:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1041d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  1041d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1041d8:	8b 55 14             	mov    0x14(%ebp),%edx
  1041db:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  1041de:	8b 45 c0             	mov    -0x40(%ebp),%eax
  1041e1:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  1041e4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1041e8:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1041ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1041ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1041f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1041f6:	89 04 24             	mov    %eax,(%esp)
  1041f9:	e8 f2 fe ff ff       	call   1040f0 <genint>
  1041fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  104201:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104204:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104207:	89 d1                	mov    %edx,%ecx
  104209:	29 c1                	sub    %eax,%ecx
  10420b:	89 c8                	mov    %ecx,%eax
  10420d:	89 44 24 08          	mov    %eax,0x8(%esp)
  104211:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104214:	89 44 24 04          	mov    %eax,0x4(%esp)
  104218:	8b 45 08             	mov    0x8(%ebp),%eax
  10421b:	89 04 24             	mov    %eax,(%esp)
  10421e:	e8 09 fe ff ff       	call   10402c <putstr>
}
  104223:	c9                   	leave  
  104224:	c3                   	ret    

00104225 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  104225:	55                   	push   %ebp
  104226:	89 e5                	mov    %esp,%ebp
  104228:	53                   	push   %ebx
  104229:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  10422c:	8d 55 c8             	lea    -0x38(%ebp),%edx
  10422f:	b9 00 00 00 00       	mov    $0x0,%ecx
  104234:	b8 20 00 00 00       	mov    $0x20,%eax
  104239:	89 c3                	mov    %eax,%ebx
  10423b:	83 e3 fc             	and    $0xfffffffc,%ebx
  10423e:	b8 00 00 00 00       	mov    $0x0,%eax
  104243:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  104246:	83 c0 04             	add    $0x4,%eax
  104249:	39 d8                	cmp    %ebx,%eax
  10424b:	72 f6                	jb     104243 <vprintfmt+0x1e>
  10424d:	01 c2                	add    %eax,%edx
  10424f:	8b 45 08             	mov    0x8(%ebp),%eax
  104252:	89 45 c8             	mov    %eax,-0x38(%ebp)
  104255:	8b 45 0c             	mov    0xc(%ebp),%eax
  104258:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10425b:	eb 17                	jmp    104274 <vprintfmt+0x4f>
			if (ch == '\0')
  10425d:	85 db                	test   %ebx,%ebx
  10425f:	0f 84 52 03 00 00    	je     1045b7 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  104265:	8b 45 0c             	mov    0xc(%ebp),%eax
  104268:	89 44 24 04          	mov    %eax,0x4(%esp)
  10426c:	89 1c 24             	mov    %ebx,(%esp)
  10426f:	8b 45 08             	mov    0x8(%ebp),%eax
  104272:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104274:	8b 45 10             	mov    0x10(%ebp),%eax
  104277:	0f b6 00             	movzbl (%eax),%eax
  10427a:	0f b6 d8             	movzbl %al,%ebx
  10427d:	83 fb 25             	cmp    $0x25,%ebx
  104280:	0f 95 c0             	setne  %al
  104283:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104287:	84 c0                	test   %al,%al
  104289:	75 d2                	jne    10425d <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  10428b:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  104292:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  104299:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  1042a0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  1042a7:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  1042ae:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  1042b5:	eb 04                	jmp    1042bb <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  1042b7:	90                   	nop
  1042b8:	eb 01                	jmp    1042bb <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  1042ba:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  1042bb:	8b 45 10             	mov    0x10(%ebp),%eax
  1042be:	0f b6 00             	movzbl (%eax),%eax
  1042c1:	0f b6 d8             	movzbl %al,%ebx
  1042c4:	89 d8                	mov    %ebx,%eax
  1042c6:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1042ca:	83 e8 20             	sub    $0x20,%eax
  1042cd:	83 f8 58             	cmp    $0x58,%eax
  1042d0:	0f 87 b1 02 00 00    	ja     104587 <vprintfmt+0x362>
  1042d6:	8b 04 85 48 5c 10 00 	mov    0x105c48(,%eax,4),%eax
  1042dd:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  1042df:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1042e2:	83 c8 10             	or     $0x10,%eax
  1042e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1042e8:	eb d1                	jmp    1042bb <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  1042ea:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  1042f1:	eb c8                	jmp    1042bb <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  1042f3:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1042f6:	85 c0                	test   %eax,%eax
  1042f8:	79 bd                	jns    1042b7 <vprintfmt+0x92>
				st.signc = ' ';
  1042fa:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  104301:	eb b8                	jmp    1042bb <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  104303:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104306:	83 e0 08             	and    $0x8,%eax
  104309:	85 c0                	test   %eax,%eax
  10430b:	75 07                	jne    104314 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  10430d:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104314:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  10431b:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10431e:	89 d0                	mov    %edx,%eax
  104320:	c1 e0 02             	shl    $0x2,%eax
  104323:	01 d0                	add    %edx,%eax
  104325:	01 c0                	add    %eax,%eax
  104327:	01 d8                	add    %ebx,%eax
  104329:	83 e8 30             	sub    $0x30,%eax
  10432c:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  10432f:	8b 45 10             	mov    0x10(%ebp),%eax
  104332:	0f b6 00             	movzbl (%eax),%eax
  104335:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  104338:	83 fb 2f             	cmp    $0x2f,%ebx
  10433b:	7e 21                	jle    10435e <vprintfmt+0x139>
  10433d:	83 fb 39             	cmp    $0x39,%ebx
  104340:	7f 1f                	jg     104361 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104342:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  104346:	eb d3                	jmp    10431b <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  104348:	8b 45 14             	mov    0x14(%ebp),%eax
  10434b:	83 c0 04             	add    $0x4,%eax
  10434e:	89 45 14             	mov    %eax,0x14(%ebp)
  104351:	8b 45 14             	mov    0x14(%ebp),%eax
  104354:	83 e8 04             	sub    $0x4,%eax
  104357:	8b 00                	mov    (%eax),%eax
  104359:	89 45 d8             	mov    %eax,-0x28(%ebp)
  10435c:	eb 04                	jmp    104362 <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  10435e:	90                   	nop
  10435f:	eb 01                	jmp    104362 <vprintfmt+0x13d>
  104361:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  104362:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104365:	83 e0 08             	and    $0x8,%eax
  104368:	85 c0                	test   %eax,%eax
  10436a:	0f 85 4a ff ff ff    	jne    1042ba <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  104370:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104373:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  104376:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  10437d:	e9 39 ff ff ff       	jmp    1042bb <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  104382:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104385:	83 c8 08             	or     $0x8,%eax
  104388:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10438b:	e9 2b ff ff ff       	jmp    1042bb <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  104390:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104393:	83 c8 04             	or     $0x4,%eax
  104396:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104399:	e9 1d ff ff ff       	jmp    1042bb <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  10439e:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1043a1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1043a4:	83 e0 01             	and    $0x1,%eax
  1043a7:	84 c0                	test   %al,%al
  1043a9:	74 07                	je     1043b2 <vprintfmt+0x18d>
  1043ab:	b8 02 00 00 00       	mov    $0x2,%eax
  1043b0:	eb 05                	jmp    1043b7 <vprintfmt+0x192>
  1043b2:	b8 01 00 00 00       	mov    $0x1,%eax
  1043b7:	09 d0                	or     %edx,%eax
  1043b9:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1043bc:	e9 fa fe ff ff       	jmp    1042bb <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  1043c1:	8b 45 14             	mov    0x14(%ebp),%eax
  1043c4:	83 c0 04             	add    $0x4,%eax
  1043c7:	89 45 14             	mov    %eax,0x14(%ebp)
  1043ca:	8b 45 14             	mov    0x14(%ebp),%eax
  1043cd:	83 e8 04             	sub    $0x4,%eax
  1043d0:	8b 00                	mov    (%eax),%eax
  1043d2:	8b 55 0c             	mov    0xc(%ebp),%edx
  1043d5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1043d9:	89 04 24             	mov    %eax,(%esp)
  1043dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1043df:	ff d0                	call   *%eax
			break;
  1043e1:	e9 cb 01 00 00       	jmp    1045b1 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  1043e6:	8b 45 14             	mov    0x14(%ebp),%eax
  1043e9:	83 c0 04             	add    $0x4,%eax
  1043ec:	89 45 14             	mov    %eax,0x14(%ebp)
  1043ef:	8b 45 14             	mov    0x14(%ebp),%eax
  1043f2:	83 e8 04             	sub    $0x4,%eax
  1043f5:	8b 00                	mov    (%eax),%eax
  1043f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1043fa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1043fe:	75 07                	jne    104407 <vprintfmt+0x1e2>
				s = "(null)";
  104400:	c7 45 f4 41 5c 10 00 	movl   $0x105c41,-0xc(%ebp)
			putstr(&st, s, st.prec);
  104407:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10440a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10440e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104411:	89 44 24 04          	mov    %eax,0x4(%esp)
  104415:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104418:	89 04 24             	mov    %eax,(%esp)
  10441b:	e8 0c fc ff ff       	call   10402c <putstr>
			break;
  104420:	e9 8c 01 00 00       	jmp    1045b1 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  104425:	8d 45 14             	lea    0x14(%ebp),%eax
  104428:	89 44 24 04          	mov    %eax,0x4(%esp)
  10442c:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10442f:	89 04 24             	mov    %eax,(%esp)
  104432:	e8 43 fb ff ff       	call   103f7a <getint>
  104437:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10443a:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  10443d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104440:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104443:	85 d2                	test   %edx,%edx
  104445:	79 1a                	jns    104461 <vprintfmt+0x23c>
				num = -(intmax_t) num;
  104447:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10444a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10444d:	f7 d8                	neg    %eax
  10444f:	83 d2 00             	adc    $0x0,%edx
  104452:	f7 da                	neg    %edx
  104454:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104457:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  10445a:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  104461:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104468:	00 
  104469:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10446c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10446f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104473:	89 54 24 08          	mov    %edx,0x8(%esp)
  104477:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10447a:	89 04 24             	mov    %eax,(%esp)
  10447d:	e8 3b fd ff ff       	call   1041bd <putint>
			break;
  104482:	e9 2a 01 00 00       	jmp    1045b1 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  104487:	8d 45 14             	lea    0x14(%ebp),%eax
  10448a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10448e:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104491:	89 04 24             	mov    %eax,(%esp)
  104494:	e8 6c fa ff ff       	call   103f05 <getuint>
  104499:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1044a0:	00 
  1044a1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044a5:	89 54 24 08          	mov    %edx,0x8(%esp)
  1044a9:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1044ac:	89 04 24             	mov    %eax,(%esp)
  1044af:	e8 09 fd ff ff       	call   1041bd <putint>
			break;
  1044b4:	e9 f8 00 00 00       	jmp    1045b1 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  1044b9:	8d 45 14             	lea    0x14(%ebp),%eax
  1044bc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044c0:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1044c3:	89 04 24             	mov    %eax,(%esp)
  1044c6:	e8 3a fa ff ff       	call   103f05 <getuint>
  1044cb:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  1044d2:	00 
  1044d3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044d7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1044db:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1044de:	89 04 24             	mov    %eax,(%esp)
  1044e1:	e8 d7 fc ff ff       	call   1041bd <putint>
			break;
  1044e6:	e9 c6 00 00 00       	jmp    1045b1 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  1044eb:	8d 45 14             	lea    0x14(%ebp),%eax
  1044ee:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044f2:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1044f5:	89 04 24             	mov    %eax,(%esp)
  1044f8:	e8 08 fa ff ff       	call   103f05 <getuint>
  1044fd:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  104504:	00 
  104505:	89 44 24 04          	mov    %eax,0x4(%esp)
  104509:	89 54 24 08          	mov    %edx,0x8(%esp)
  10450d:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104510:	89 04 24             	mov    %eax,(%esp)
  104513:	e8 a5 fc ff ff       	call   1041bd <putint>
			break;
  104518:	e9 94 00 00 00       	jmp    1045b1 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  10451d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104520:	89 44 24 04          	mov    %eax,0x4(%esp)
  104524:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10452b:	8b 45 08             	mov    0x8(%ebp),%eax
  10452e:	ff d0                	call   *%eax
			putch('x', putdat);
  104530:	8b 45 0c             	mov    0xc(%ebp),%eax
  104533:	89 44 24 04          	mov    %eax,0x4(%esp)
  104537:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  10453e:	8b 45 08             	mov    0x8(%ebp),%eax
  104541:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  104543:	8b 45 14             	mov    0x14(%ebp),%eax
  104546:	83 c0 04             	add    $0x4,%eax
  104549:	89 45 14             	mov    %eax,0x14(%ebp)
  10454c:	8b 45 14             	mov    0x14(%ebp),%eax
  10454f:	83 e8 04             	sub    $0x4,%eax
  104552:	8b 00                	mov    (%eax),%eax
  104554:	ba 00 00 00 00       	mov    $0x0,%edx
  104559:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  104560:	00 
  104561:	89 44 24 04          	mov    %eax,0x4(%esp)
  104565:	89 54 24 08          	mov    %edx,0x8(%esp)
  104569:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10456c:	89 04 24             	mov    %eax,(%esp)
  10456f:	e8 49 fc ff ff       	call   1041bd <putint>
			break;
  104574:	eb 3b                	jmp    1045b1 <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  104576:	8b 45 0c             	mov    0xc(%ebp),%eax
  104579:	89 44 24 04          	mov    %eax,0x4(%esp)
  10457d:	89 1c 24             	mov    %ebx,(%esp)
  104580:	8b 45 08             	mov    0x8(%ebp),%eax
  104583:	ff d0                	call   *%eax
			break;
  104585:	eb 2a                	jmp    1045b1 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  104587:	8b 45 0c             	mov    0xc(%ebp),%eax
  10458a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10458e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  104595:	8b 45 08             	mov    0x8(%ebp),%eax
  104598:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  10459a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10459e:	eb 04                	jmp    1045a4 <vprintfmt+0x37f>
  1045a0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1045a4:	8b 45 10             	mov    0x10(%ebp),%eax
  1045a7:	83 e8 01             	sub    $0x1,%eax
  1045aa:	0f b6 00             	movzbl (%eax),%eax
  1045ad:	3c 25                	cmp    $0x25,%al
  1045af:	75 ef                	jne    1045a0 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  1045b1:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1045b2:	e9 bd fc ff ff       	jmp    104274 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  1045b7:	83 c4 44             	add    $0x44,%esp
  1045ba:	5b                   	pop    %ebx
  1045bb:	5d                   	pop    %ebp
  1045bc:	c3                   	ret    

001045bd <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  1045bd:	55                   	push   %ebp
  1045be:	89 e5                	mov    %esp,%ebp
  1045c0:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  1045c3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045c6:	8b 00                	mov    (%eax),%eax
  1045c8:	8b 55 08             	mov    0x8(%ebp),%edx
  1045cb:	89 d1                	mov    %edx,%ecx
  1045cd:	8b 55 0c             	mov    0xc(%ebp),%edx
  1045d0:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  1045d4:	8d 50 01             	lea    0x1(%eax),%edx
  1045d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045da:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  1045dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045df:	8b 00                	mov    (%eax),%eax
  1045e1:	3d ff 00 00 00       	cmp    $0xff,%eax
  1045e6:	75 24                	jne    10460c <putch+0x4f>
		b->buf[b->idx] = 0;
  1045e8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045eb:	8b 00                	mov    (%eax),%eax
  1045ed:	8b 55 0c             	mov    0xc(%ebp),%edx
  1045f0:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  1045f5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045f8:	83 c0 08             	add    $0x8,%eax
  1045fb:	89 04 24             	mov    %eax,(%esp)
  1045fe:	e8 a4 bd ff ff       	call   1003a7 <cputs>
		b->idx = 0;
  104603:	8b 45 0c             	mov    0xc(%ebp),%eax
  104606:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  10460c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10460f:	8b 40 04             	mov    0x4(%eax),%eax
  104612:	8d 50 01             	lea    0x1(%eax),%edx
  104615:	8b 45 0c             	mov    0xc(%ebp),%eax
  104618:	89 50 04             	mov    %edx,0x4(%eax)
}
  10461b:	c9                   	leave  
  10461c:	c3                   	ret    

0010461d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  10461d:	55                   	push   %ebp
  10461e:	89 e5                	mov    %esp,%ebp
  104620:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  104626:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  10462d:	00 00 00 
	b.cnt = 0;
  104630:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  104637:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  10463a:	b8 bd 45 10 00       	mov    $0x1045bd,%eax
  10463f:	8b 55 0c             	mov    0xc(%ebp),%edx
  104642:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104646:	8b 55 08             	mov    0x8(%ebp),%edx
  104649:	89 54 24 08          	mov    %edx,0x8(%esp)
  10464d:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  104653:	89 54 24 04          	mov    %edx,0x4(%esp)
  104657:	89 04 24             	mov    %eax,(%esp)
  10465a:	e8 c6 fb ff ff       	call   104225 <vprintfmt>

	b.buf[b.idx] = 0;
  10465f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  104665:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  10466c:	00 
	cputs(b.buf);
  10466d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  104673:	83 c0 08             	add    $0x8,%eax
  104676:	89 04 24             	mov    %eax,(%esp)
  104679:	e8 29 bd ff ff       	call   1003a7 <cputs>

	return b.cnt;
  10467e:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  104684:	c9                   	leave  
  104685:	c3                   	ret    

00104686 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  104686:	55                   	push   %ebp
  104687:	89 e5                	mov    %esp,%ebp
  104689:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  10468c:	8d 45 08             	lea    0x8(%ebp),%eax
  10468f:	83 c0 04             	add    $0x4,%eax
  104692:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  104695:	8b 45 08             	mov    0x8(%ebp),%eax
  104698:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10469b:	89 54 24 04          	mov    %edx,0x4(%esp)
  10469f:	89 04 24             	mov    %eax,(%esp)
  1046a2:	e8 76 ff ff ff       	call   10461d <vcprintf>
  1046a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  1046aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1046ad:	c9                   	leave  
  1046ae:	c3                   	ret    

001046af <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  1046af:	55                   	push   %ebp
  1046b0:	89 e5                	mov    %esp,%ebp
  1046b2:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  1046b5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1046bc:	eb 08                	jmp    1046c6 <strlen+0x17>
		n++;
  1046be:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  1046c2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1046c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1046c9:	0f b6 00             	movzbl (%eax),%eax
  1046cc:	84 c0                	test   %al,%al
  1046ce:	75 ee                	jne    1046be <strlen+0xf>
		n++;
	return n;
  1046d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1046d3:	c9                   	leave  
  1046d4:	c3                   	ret    

001046d5 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  1046d5:	55                   	push   %ebp
  1046d6:	89 e5                	mov    %esp,%ebp
  1046d8:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  1046db:	8b 45 08             	mov    0x8(%ebp),%eax
  1046de:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  1046e1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1046e4:	0f b6 10             	movzbl (%eax),%edx
  1046e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1046ea:	88 10                	mov    %dl,(%eax)
  1046ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1046ef:	0f b6 00             	movzbl (%eax),%eax
  1046f2:	84 c0                	test   %al,%al
  1046f4:	0f 95 c0             	setne  %al
  1046f7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1046fb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  1046ff:	84 c0                	test   %al,%al
  104701:	75 de                	jne    1046e1 <strcpy+0xc>
		/* do nothing */;
	return ret;
  104703:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104706:	c9                   	leave  
  104707:	c3                   	ret    

00104708 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  104708:	55                   	push   %ebp
  104709:	89 e5                	mov    %esp,%ebp
  10470b:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  10470e:	8b 45 08             	mov    0x8(%ebp),%eax
  104711:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  104714:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  10471b:	eb 21                	jmp    10473e <strncpy+0x36>
		*dst++ = *src;
  10471d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104720:	0f b6 10             	movzbl (%eax),%edx
  104723:	8b 45 08             	mov    0x8(%ebp),%eax
  104726:	88 10                	mov    %dl,(%eax)
  104728:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  10472c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10472f:	0f b6 00             	movzbl (%eax),%eax
  104732:	84 c0                	test   %al,%al
  104734:	74 04                	je     10473a <strncpy+0x32>
			src++;
  104736:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  10473a:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  10473e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104741:	3b 45 10             	cmp    0x10(%ebp),%eax
  104744:	72 d7                	jb     10471d <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  104746:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  104749:	c9                   	leave  
  10474a:	c3                   	ret    

0010474b <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  10474b:	55                   	push   %ebp
  10474c:	89 e5                	mov    %esp,%ebp
  10474e:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  104751:	8b 45 08             	mov    0x8(%ebp),%eax
  104754:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  104757:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10475b:	74 2f                	je     10478c <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  10475d:	eb 13                	jmp    104772 <strlcpy+0x27>
			*dst++ = *src++;
  10475f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104762:	0f b6 10             	movzbl (%eax),%edx
  104765:	8b 45 08             	mov    0x8(%ebp),%eax
  104768:	88 10                	mov    %dl,(%eax)
  10476a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10476e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  104772:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104776:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10477a:	74 0a                	je     104786 <strlcpy+0x3b>
  10477c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10477f:	0f b6 00             	movzbl (%eax),%eax
  104782:	84 c0                	test   %al,%al
  104784:	75 d9                	jne    10475f <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  104786:	8b 45 08             	mov    0x8(%ebp),%eax
  104789:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  10478c:	8b 55 08             	mov    0x8(%ebp),%edx
  10478f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104792:	89 d1                	mov    %edx,%ecx
  104794:	29 c1                	sub    %eax,%ecx
  104796:	89 c8                	mov    %ecx,%eax
}
  104798:	c9                   	leave  
  104799:	c3                   	ret    

0010479a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  10479a:	55                   	push   %ebp
  10479b:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  10479d:	eb 08                	jmp    1047a7 <strcmp+0xd>
		p++, q++;
  10479f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1047a3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  1047a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1047aa:	0f b6 00             	movzbl (%eax),%eax
  1047ad:	84 c0                	test   %al,%al
  1047af:	74 10                	je     1047c1 <strcmp+0x27>
  1047b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1047b4:	0f b6 10             	movzbl (%eax),%edx
  1047b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047ba:	0f b6 00             	movzbl (%eax),%eax
  1047bd:	38 c2                	cmp    %al,%dl
  1047bf:	74 de                	je     10479f <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  1047c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1047c4:	0f b6 00             	movzbl (%eax),%eax
  1047c7:	0f b6 d0             	movzbl %al,%edx
  1047ca:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047cd:	0f b6 00             	movzbl (%eax),%eax
  1047d0:	0f b6 c0             	movzbl %al,%eax
  1047d3:	89 d1                	mov    %edx,%ecx
  1047d5:	29 c1                	sub    %eax,%ecx
  1047d7:	89 c8                	mov    %ecx,%eax
}
  1047d9:	5d                   	pop    %ebp
  1047da:	c3                   	ret    

001047db <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  1047db:	55                   	push   %ebp
  1047dc:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  1047de:	eb 0c                	jmp    1047ec <strncmp+0x11>
		n--, p++, q++;
  1047e0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1047e4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1047e8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  1047ec:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1047f0:	74 1a                	je     10480c <strncmp+0x31>
  1047f2:	8b 45 08             	mov    0x8(%ebp),%eax
  1047f5:	0f b6 00             	movzbl (%eax),%eax
  1047f8:	84 c0                	test   %al,%al
  1047fa:	74 10                	je     10480c <strncmp+0x31>
  1047fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1047ff:	0f b6 10             	movzbl (%eax),%edx
  104802:	8b 45 0c             	mov    0xc(%ebp),%eax
  104805:	0f b6 00             	movzbl (%eax),%eax
  104808:	38 c2                	cmp    %al,%dl
  10480a:	74 d4                	je     1047e0 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  10480c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104810:	75 07                	jne    104819 <strncmp+0x3e>
		return 0;
  104812:	b8 00 00 00 00       	mov    $0x0,%eax
  104817:	eb 18                	jmp    104831 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  104819:	8b 45 08             	mov    0x8(%ebp),%eax
  10481c:	0f b6 00             	movzbl (%eax),%eax
  10481f:	0f b6 d0             	movzbl %al,%edx
  104822:	8b 45 0c             	mov    0xc(%ebp),%eax
  104825:	0f b6 00             	movzbl (%eax),%eax
  104828:	0f b6 c0             	movzbl %al,%eax
  10482b:	89 d1                	mov    %edx,%ecx
  10482d:	29 c1                	sub    %eax,%ecx
  10482f:	89 c8                	mov    %ecx,%eax
}
  104831:	5d                   	pop    %ebp
  104832:	c3                   	ret    

00104833 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  104833:	55                   	push   %ebp
  104834:	89 e5                	mov    %esp,%ebp
  104836:	83 ec 04             	sub    $0x4,%esp
  104839:	8b 45 0c             	mov    0xc(%ebp),%eax
  10483c:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  10483f:	eb 1a                	jmp    10485b <strchr+0x28>
		if (*s++ == 0)
  104841:	8b 45 08             	mov    0x8(%ebp),%eax
  104844:	0f b6 00             	movzbl (%eax),%eax
  104847:	84 c0                	test   %al,%al
  104849:	0f 94 c0             	sete   %al
  10484c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104850:	84 c0                	test   %al,%al
  104852:	74 07                	je     10485b <strchr+0x28>
			return NULL;
  104854:	b8 00 00 00 00       	mov    $0x0,%eax
  104859:	eb 0e                	jmp    104869 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  10485b:	8b 45 08             	mov    0x8(%ebp),%eax
  10485e:	0f b6 00             	movzbl (%eax),%eax
  104861:	3a 45 fc             	cmp    -0x4(%ebp),%al
  104864:	75 db                	jne    104841 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  104866:	8b 45 08             	mov    0x8(%ebp),%eax
}
  104869:	c9                   	leave  
  10486a:	c3                   	ret    

0010486b <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  10486b:	55                   	push   %ebp
  10486c:	89 e5                	mov    %esp,%ebp
  10486e:	57                   	push   %edi
  10486f:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  104872:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104876:	75 05                	jne    10487d <memset+0x12>
		return v;
  104878:	8b 45 08             	mov    0x8(%ebp),%eax
  10487b:	eb 5c                	jmp    1048d9 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  10487d:	8b 45 08             	mov    0x8(%ebp),%eax
  104880:	83 e0 03             	and    $0x3,%eax
  104883:	85 c0                	test   %eax,%eax
  104885:	75 41                	jne    1048c8 <memset+0x5d>
  104887:	8b 45 10             	mov    0x10(%ebp),%eax
  10488a:	83 e0 03             	and    $0x3,%eax
  10488d:	85 c0                	test   %eax,%eax
  10488f:	75 37                	jne    1048c8 <memset+0x5d>
		c &= 0xFF;
  104891:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  104898:	8b 45 0c             	mov    0xc(%ebp),%eax
  10489b:	89 c2                	mov    %eax,%edx
  10489d:	c1 e2 18             	shl    $0x18,%edx
  1048a0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048a3:	c1 e0 10             	shl    $0x10,%eax
  1048a6:	09 c2                	or     %eax,%edx
  1048a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048ab:	c1 e0 08             	shl    $0x8,%eax
  1048ae:	09 d0                	or     %edx,%eax
  1048b0:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  1048b3:	8b 45 10             	mov    0x10(%ebp),%eax
  1048b6:	89 c1                	mov    %eax,%ecx
  1048b8:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  1048bb:	8b 55 08             	mov    0x8(%ebp),%edx
  1048be:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048c1:	89 d7                	mov    %edx,%edi
  1048c3:	fc                   	cld    
  1048c4:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  1048c6:	eb 0e                	jmp    1048d6 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  1048c8:	8b 55 08             	mov    0x8(%ebp),%edx
  1048cb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048ce:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1048d1:	89 d7                	mov    %edx,%edi
  1048d3:	fc                   	cld    
  1048d4:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  1048d6:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1048d9:	83 c4 10             	add    $0x10,%esp
  1048dc:	5f                   	pop    %edi
  1048dd:	5d                   	pop    %ebp
  1048de:	c3                   	ret    

001048df <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  1048df:	55                   	push   %ebp
  1048e0:	89 e5                	mov    %esp,%ebp
  1048e2:	57                   	push   %edi
  1048e3:	56                   	push   %esi
  1048e4:	53                   	push   %ebx
  1048e5:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  1048e8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048eb:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  1048ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1048f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  1048f4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1048f7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1048fa:	73 6e                	jae    10496a <memmove+0x8b>
  1048fc:	8b 45 10             	mov    0x10(%ebp),%eax
  1048ff:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104902:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104905:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104908:	76 60                	jbe    10496a <memmove+0x8b>
		s += n;
  10490a:	8b 45 10             	mov    0x10(%ebp),%eax
  10490d:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  104910:	8b 45 10             	mov    0x10(%ebp),%eax
  104913:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  104916:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104919:	83 e0 03             	and    $0x3,%eax
  10491c:	85 c0                	test   %eax,%eax
  10491e:	75 2f                	jne    10494f <memmove+0x70>
  104920:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104923:	83 e0 03             	and    $0x3,%eax
  104926:	85 c0                	test   %eax,%eax
  104928:	75 25                	jne    10494f <memmove+0x70>
  10492a:	8b 45 10             	mov    0x10(%ebp),%eax
  10492d:	83 e0 03             	and    $0x3,%eax
  104930:	85 c0                	test   %eax,%eax
  104932:	75 1b                	jne    10494f <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  104934:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104937:	83 e8 04             	sub    $0x4,%eax
  10493a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10493d:	83 ea 04             	sub    $0x4,%edx
  104940:	8b 4d 10             	mov    0x10(%ebp),%ecx
  104943:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  104946:	89 c7                	mov    %eax,%edi
  104948:	89 d6                	mov    %edx,%esi
  10494a:	fd                   	std    
  10494b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10494d:	eb 18                	jmp    104967 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  10494f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104952:	8d 50 ff             	lea    -0x1(%eax),%edx
  104955:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104958:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  10495b:	8b 45 10             	mov    0x10(%ebp),%eax
  10495e:	89 d7                	mov    %edx,%edi
  104960:	89 de                	mov    %ebx,%esi
  104962:	89 c1                	mov    %eax,%ecx
  104964:	fd                   	std    
  104965:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  104967:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  104968:	eb 45                	jmp    1049af <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10496a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10496d:	83 e0 03             	and    $0x3,%eax
  104970:	85 c0                	test   %eax,%eax
  104972:	75 2b                	jne    10499f <memmove+0xc0>
  104974:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104977:	83 e0 03             	and    $0x3,%eax
  10497a:	85 c0                	test   %eax,%eax
  10497c:	75 21                	jne    10499f <memmove+0xc0>
  10497e:	8b 45 10             	mov    0x10(%ebp),%eax
  104981:	83 e0 03             	and    $0x3,%eax
  104984:	85 c0                	test   %eax,%eax
  104986:	75 17                	jne    10499f <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  104988:	8b 45 10             	mov    0x10(%ebp),%eax
  10498b:	89 c1                	mov    %eax,%ecx
  10498d:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  104990:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104993:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104996:	89 c7                	mov    %eax,%edi
  104998:	89 d6                	mov    %edx,%esi
  10499a:	fc                   	cld    
  10499b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10499d:	eb 10                	jmp    1049af <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  10499f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1049a2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1049a5:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1049a8:	89 c7                	mov    %eax,%edi
  1049aa:	89 d6                	mov    %edx,%esi
  1049ac:	fc                   	cld    
  1049ad:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  1049af:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1049b2:	83 c4 10             	add    $0x10,%esp
  1049b5:	5b                   	pop    %ebx
  1049b6:	5e                   	pop    %esi
  1049b7:	5f                   	pop    %edi
  1049b8:	5d                   	pop    %ebp
  1049b9:	c3                   	ret    

001049ba <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  1049ba:	55                   	push   %ebp
  1049bb:	89 e5                	mov    %esp,%ebp
  1049bd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  1049c0:	8b 45 10             	mov    0x10(%ebp),%eax
  1049c3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1049c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1049d1:	89 04 24             	mov    %eax,(%esp)
  1049d4:	e8 06 ff ff ff       	call   1048df <memmove>
}
  1049d9:	c9                   	leave  
  1049da:	c3                   	ret    

001049db <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  1049db:	55                   	push   %ebp
  1049dc:	89 e5                	mov    %esp,%ebp
  1049de:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  1049e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1049e4:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  1049e7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049ea:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  1049ed:	eb 32                	jmp    104a21 <memcmp+0x46>
		if (*s1 != *s2)
  1049ef:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1049f2:	0f b6 10             	movzbl (%eax),%edx
  1049f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1049f8:	0f b6 00             	movzbl (%eax),%eax
  1049fb:	38 c2                	cmp    %al,%dl
  1049fd:	74 1a                	je     104a19 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  1049ff:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104a02:	0f b6 00             	movzbl (%eax),%eax
  104a05:	0f b6 d0             	movzbl %al,%edx
  104a08:	8b 45 fc             	mov    -0x4(%ebp),%eax
  104a0b:	0f b6 00             	movzbl (%eax),%eax
  104a0e:	0f b6 c0             	movzbl %al,%eax
  104a11:	89 d1                	mov    %edx,%ecx
  104a13:	29 c1                	sub    %eax,%ecx
  104a15:	89 c8                	mov    %ecx,%eax
  104a17:	eb 1c                	jmp    104a35 <memcmp+0x5a>
		s1++, s2++;
  104a19:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  104a1d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  104a21:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104a25:	0f 95 c0             	setne  %al
  104a28:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  104a2c:	84 c0                	test   %al,%al
  104a2e:	75 bf                	jne    1049ef <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  104a30:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104a35:	c9                   	leave  
  104a36:	c3                   	ret    

00104a37 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  104a37:	55                   	push   %ebp
  104a38:	89 e5                	mov    %esp,%ebp
  104a3a:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  104a3d:	8b 45 10             	mov    0x10(%ebp),%eax
  104a40:	8b 55 08             	mov    0x8(%ebp),%edx
  104a43:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104a46:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  104a49:	eb 16                	jmp    104a61 <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  104a4b:	8b 45 08             	mov    0x8(%ebp),%eax
  104a4e:	0f b6 10             	movzbl (%eax),%edx
  104a51:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a54:	38 c2                	cmp    %al,%dl
  104a56:	75 05                	jne    104a5d <memchr+0x26>
			return (void *) s;
  104a58:	8b 45 08             	mov    0x8(%ebp),%eax
  104a5b:	eb 11                	jmp    104a6e <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  104a5d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  104a61:	8b 45 08             	mov    0x8(%ebp),%eax
  104a64:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  104a67:	72 e2                	jb     104a4b <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  104a69:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104a6e:	c9                   	leave  
  104a6f:	c3                   	ret    

00104a70 <__udivdi3>:
  104a70:	55                   	push   %ebp
  104a71:	89 e5                	mov    %esp,%ebp
  104a73:	57                   	push   %edi
  104a74:	56                   	push   %esi
  104a75:	83 ec 10             	sub    $0x10,%esp
  104a78:	8b 45 14             	mov    0x14(%ebp),%eax
  104a7b:	8b 55 08             	mov    0x8(%ebp),%edx
  104a7e:	8b 75 10             	mov    0x10(%ebp),%esi
  104a81:	8b 7d 0c             	mov    0xc(%ebp),%edi
  104a84:	85 c0                	test   %eax,%eax
  104a86:	89 55 f0             	mov    %edx,-0x10(%ebp)
  104a89:	75 35                	jne    104ac0 <__udivdi3+0x50>
  104a8b:	39 fe                	cmp    %edi,%esi
  104a8d:	77 61                	ja     104af0 <__udivdi3+0x80>
  104a8f:	85 f6                	test   %esi,%esi
  104a91:	75 0b                	jne    104a9e <__udivdi3+0x2e>
  104a93:	b8 01 00 00 00       	mov    $0x1,%eax
  104a98:	31 d2                	xor    %edx,%edx
  104a9a:	f7 f6                	div    %esi
  104a9c:	89 c6                	mov    %eax,%esi
  104a9e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  104aa1:	31 d2                	xor    %edx,%edx
  104aa3:	89 f8                	mov    %edi,%eax
  104aa5:	f7 f6                	div    %esi
  104aa7:	89 c7                	mov    %eax,%edi
  104aa9:	89 c8                	mov    %ecx,%eax
  104aab:	f7 f6                	div    %esi
  104aad:	89 c1                	mov    %eax,%ecx
  104aaf:	89 fa                	mov    %edi,%edx
  104ab1:	89 c8                	mov    %ecx,%eax
  104ab3:	83 c4 10             	add    $0x10,%esp
  104ab6:	5e                   	pop    %esi
  104ab7:	5f                   	pop    %edi
  104ab8:	5d                   	pop    %ebp
  104ab9:	c3                   	ret    
  104aba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  104ac0:	39 f8                	cmp    %edi,%eax
  104ac2:	77 1c                	ja     104ae0 <__udivdi3+0x70>
  104ac4:	0f bd d0             	bsr    %eax,%edx
  104ac7:	83 f2 1f             	xor    $0x1f,%edx
  104aca:	89 55 f4             	mov    %edx,-0xc(%ebp)
  104acd:	75 39                	jne    104b08 <__udivdi3+0x98>
  104acf:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  104ad2:	0f 86 a0 00 00 00    	jbe    104b78 <__udivdi3+0x108>
  104ad8:	39 f8                	cmp    %edi,%eax
  104ada:	0f 82 98 00 00 00    	jb     104b78 <__udivdi3+0x108>
  104ae0:	31 ff                	xor    %edi,%edi
  104ae2:	31 c9                	xor    %ecx,%ecx
  104ae4:	89 c8                	mov    %ecx,%eax
  104ae6:	89 fa                	mov    %edi,%edx
  104ae8:	83 c4 10             	add    $0x10,%esp
  104aeb:	5e                   	pop    %esi
  104aec:	5f                   	pop    %edi
  104aed:	5d                   	pop    %ebp
  104aee:	c3                   	ret    
  104aef:	90                   	nop
  104af0:	89 d1                	mov    %edx,%ecx
  104af2:	89 fa                	mov    %edi,%edx
  104af4:	89 c8                	mov    %ecx,%eax
  104af6:	31 ff                	xor    %edi,%edi
  104af8:	f7 f6                	div    %esi
  104afa:	89 c1                	mov    %eax,%ecx
  104afc:	89 fa                	mov    %edi,%edx
  104afe:	89 c8                	mov    %ecx,%eax
  104b00:	83 c4 10             	add    $0x10,%esp
  104b03:	5e                   	pop    %esi
  104b04:	5f                   	pop    %edi
  104b05:	5d                   	pop    %ebp
  104b06:	c3                   	ret    
  104b07:	90                   	nop
  104b08:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  104b0c:	89 f2                	mov    %esi,%edx
  104b0e:	d3 e0                	shl    %cl,%eax
  104b10:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104b13:	b8 20 00 00 00       	mov    $0x20,%eax
  104b18:	2b 45 f4             	sub    -0xc(%ebp),%eax
  104b1b:	89 c1                	mov    %eax,%ecx
  104b1d:	d3 ea                	shr    %cl,%edx
  104b1f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  104b23:	0b 55 ec             	or     -0x14(%ebp),%edx
  104b26:	d3 e6                	shl    %cl,%esi
  104b28:	89 c1                	mov    %eax,%ecx
  104b2a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  104b2d:	89 fe                	mov    %edi,%esi
  104b2f:	d3 ee                	shr    %cl,%esi
  104b31:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  104b35:	89 55 ec             	mov    %edx,-0x14(%ebp)
  104b38:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104b3b:	d3 e7                	shl    %cl,%edi
  104b3d:	89 c1                	mov    %eax,%ecx
  104b3f:	d3 ea                	shr    %cl,%edx
  104b41:	09 d7                	or     %edx,%edi
  104b43:	89 f2                	mov    %esi,%edx
  104b45:	89 f8                	mov    %edi,%eax
  104b47:	f7 75 ec             	divl   -0x14(%ebp)
  104b4a:	89 d6                	mov    %edx,%esi
  104b4c:	89 c7                	mov    %eax,%edi
  104b4e:	f7 65 e8             	mull   -0x18(%ebp)
  104b51:	39 d6                	cmp    %edx,%esi
  104b53:	89 55 ec             	mov    %edx,-0x14(%ebp)
  104b56:	72 30                	jb     104b88 <__udivdi3+0x118>
  104b58:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104b5b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  104b5f:	d3 e2                	shl    %cl,%edx
  104b61:	39 c2                	cmp    %eax,%edx
  104b63:	73 05                	jae    104b6a <__udivdi3+0xfa>
  104b65:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  104b68:	74 1e                	je     104b88 <__udivdi3+0x118>
  104b6a:	89 f9                	mov    %edi,%ecx
  104b6c:	31 ff                	xor    %edi,%edi
  104b6e:	e9 71 ff ff ff       	jmp    104ae4 <__udivdi3+0x74>
  104b73:	90                   	nop
  104b74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  104b78:	31 ff                	xor    %edi,%edi
  104b7a:	b9 01 00 00 00       	mov    $0x1,%ecx
  104b7f:	e9 60 ff ff ff       	jmp    104ae4 <__udivdi3+0x74>
  104b84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  104b88:	8d 4f ff             	lea    -0x1(%edi),%ecx
  104b8b:	31 ff                	xor    %edi,%edi
  104b8d:	89 c8                	mov    %ecx,%eax
  104b8f:	89 fa                	mov    %edi,%edx
  104b91:	83 c4 10             	add    $0x10,%esp
  104b94:	5e                   	pop    %esi
  104b95:	5f                   	pop    %edi
  104b96:	5d                   	pop    %ebp
  104b97:	c3                   	ret    
  104b98:	66 90                	xchg   %ax,%ax
  104b9a:	66 90                	xchg   %ax,%ax
  104b9c:	66 90                	xchg   %ax,%ax
  104b9e:	66 90                	xchg   %ax,%ax

00104ba0 <__umoddi3>:
  104ba0:	55                   	push   %ebp
  104ba1:	89 e5                	mov    %esp,%ebp
  104ba3:	57                   	push   %edi
  104ba4:	56                   	push   %esi
  104ba5:	83 ec 20             	sub    $0x20,%esp
  104ba8:	8b 55 14             	mov    0x14(%ebp),%edx
  104bab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  104bae:	8b 7d 10             	mov    0x10(%ebp),%edi
  104bb1:	8b 75 0c             	mov    0xc(%ebp),%esi
  104bb4:	85 d2                	test   %edx,%edx
  104bb6:	89 c8                	mov    %ecx,%eax
  104bb8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  104bbb:	75 13                	jne    104bd0 <__umoddi3+0x30>
  104bbd:	39 f7                	cmp    %esi,%edi
  104bbf:	76 3f                	jbe    104c00 <__umoddi3+0x60>
  104bc1:	89 f2                	mov    %esi,%edx
  104bc3:	f7 f7                	div    %edi
  104bc5:	89 d0                	mov    %edx,%eax
  104bc7:	31 d2                	xor    %edx,%edx
  104bc9:	83 c4 20             	add    $0x20,%esp
  104bcc:	5e                   	pop    %esi
  104bcd:	5f                   	pop    %edi
  104bce:	5d                   	pop    %ebp
  104bcf:	c3                   	ret    
  104bd0:	39 f2                	cmp    %esi,%edx
  104bd2:	77 4c                	ja     104c20 <__umoddi3+0x80>
  104bd4:	0f bd ca             	bsr    %edx,%ecx
  104bd7:	83 f1 1f             	xor    $0x1f,%ecx
  104bda:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  104bdd:	75 51                	jne    104c30 <__umoddi3+0x90>
  104bdf:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  104be2:	0f 87 e0 00 00 00    	ja     104cc8 <__umoddi3+0x128>
  104be8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104beb:	29 f8                	sub    %edi,%eax
  104bed:	19 d6                	sbb    %edx,%esi
  104bef:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104bf2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104bf5:	89 f2                	mov    %esi,%edx
  104bf7:	83 c4 20             	add    $0x20,%esp
  104bfa:	5e                   	pop    %esi
  104bfb:	5f                   	pop    %edi
  104bfc:	5d                   	pop    %ebp
  104bfd:	c3                   	ret    
  104bfe:	66 90                	xchg   %ax,%ax
  104c00:	85 ff                	test   %edi,%edi
  104c02:	75 0b                	jne    104c0f <__umoddi3+0x6f>
  104c04:	b8 01 00 00 00       	mov    $0x1,%eax
  104c09:	31 d2                	xor    %edx,%edx
  104c0b:	f7 f7                	div    %edi
  104c0d:	89 c7                	mov    %eax,%edi
  104c0f:	89 f0                	mov    %esi,%eax
  104c11:	31 d2                	xor    %edx,%edx
  104c13:	f7 f7                	div    %edi
  104c15:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104c18:	f7 f7                	div    %edi
  104c1a:	eb a9                	jmp    104bc5 <__umoddi3+0x25>
  104c1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  104c20:	89 c8                	mov    %ecx,%eax
  104c22:	89 f2                	mov    %esi,%edx
  104c24:	83 c4 20             	add    $0x20,%esp
  104c27:	5e                   	pop    %esi
  104c28:	5f                   	pop    %edi
  104c29:	5d                   	pop    %ebp
  104c2a:	c3                   	ret    
  104c2b:	90                   	nop
  104c2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  104c30:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  104c34:	d3 e2                	shl    %cl,%edx
  104c36:	89 55 f4             	mov    %edx,-0xc(%ebp)
  104c39:	ba 20 00 00 00       	mov    $0x20,%edx
  104c3e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  104c41:	89 55 ec             	mov    %edx,-0x14(%ebp)
  104c44:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  104c48:	89 fa                	mov    %edi,%edx
  104c4a:	d3 ea                	shr    %cl,%edx
  104c4c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  104c50:	0b 55 f4             	or     -0xc(%ebp),%edx
  104c53:	d3 e7                	shl    %cl,%edi
  104c55:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  104c59:	89 55 f4             	mov    %edx,-0xc(%ebp)
  104c5c:	89 f2                	mov    %esi,%edx
  104c5e:	89 7d e8             	mov    %edi,-0x18(%ebp)
  104c61:	89 c7                	mov    %eax,%edi
  104c63:	d3 ea                	shr    %cl,%edx
  104c65:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  104c69:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  104c6c:	89 c2                	mov    %eax,%edx
  104c6e:	d3 e6                	shl    %cl,%esi
  104c70:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  104c74:	d3 ea                	shr    %cl,%edx
  104c76:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  104c7a:	09 d6                	or     %edx,%esi
  104c7c:	89 f0                	mov    %esi,%eax
  104c7e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  104c81:	d3 e7                	shl    %cl,%edi
  104c83:	89 f2                	mov    %esi,%edx
  104c85:	f7 75 f4             	divl   -0xc(%ebp)
  104c88:	89 d6                	mov    %edx,%esi
  104c8a:	f7 65 e8             	mull   -0x18(%ebp)
  104c8d:	39 d6                	cmp    %edx,%esi
  104c8f:	72 2b                	jb     104cbc <__umoddi3+0x11c>
  104c91:	39 c7                	cmp    %eax,%edi
  104c93:	72 23                	jb     104cb8 <__umoddi3+0x118>
  104c95:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  104c99:	29 c7                	sub    %eax,%edi
  104c9b:	19 d6                	sbb    %edx,%esi
  104c9d:	89 f0                	mov    %esi,%eax
  104c9f:	89 f2                	mov    %esi,%edx
  104ca1:	d3 ef                	shr    %cl,%edi
  104ca3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  104ca7:	d3 e0                	shl    %cl,%eax
  104ca9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  104cad:	09 f8                	or     %edi,%eax
  104caf:	d3 ea                	shr    %cl,%edx
  104cb1:	83 c4 20             	add    $0x20,%esp
  104cb4:	5e                   	pop    %esi
  104cb5:	5f                   	pop    %edi
  104cb6:	5d                   	pop    %ebp
  104cb7:	c3                   	ret    
  104cb8:	39 d6                	cmp    %edx,%esi
  104cba:	75 d9                	jne    104c95 <__umoddi3+0xf5>
  104cbc:	2b 45 e8             	sub    -0x18(%ebp),%eax
  104cbf:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  104cc2:	eb d1                	jmp    104c95 <__umoddi3+0xf5>
  104cc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  104cc8:	39 f2                	cmp    %esi,%edx
  104cca:	0f 82 18 ff ff ff    	jb     104be8 <__umoddi3+0x48>
  104cd0:	e9 1d ff ff ff       	jmp    104bf2 <__umoddi3+0x52>
