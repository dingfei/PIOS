
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

	# Leave a few words on the stack for the user trap frame
	movl	$(cpu_boot+4096-SIZEOF_STRUCT_TRAPFRAME),%esp
  10001a:	bc b4 af 10 00       	mov    $0x10afb4,%esp

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
  100050:	c7 44 24 0c e0 7a 10 	movl   $0x107ae0,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 f6 7a 10 	movl   $0x107af6,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 0b 7b 10 00 	movl   $0x107b0b,(%esp)
  10006f:	e8 0d 04 00 00       	call   100481 <debug_panic>
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
  100084:	3d 00 a0 10 00       	cmp    $0x10a000,%eax
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
  100094:	53                   	push   %ebx
  100095:	83 ec 14             	sub    $0x14,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  100098:	e8 dc ff ff ff       	call   100079 <cpu_onboot>
  10009d:	85 c0                	test   %eax,%eax
  10009f:	74 28                	je     1000c9 <init+0x38>
		memset(edata, 0, end - edata);
  1000a1:	ba 08 10 32 00       	mov    $0x321008,%edx
  1000a6:	b8 34 75 11 00       	mov    $0x117534,%eax
  1000ab:	89 d1                	mov    %edx,%ecx
  1000ad:	29 c1                	sub    %eax,%ecx
  1000af:	89 c8                	mov    %ecx,%eax
  1000b1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bc:	00 
  1000bd:	c7 04 24 34 75 11 00 	movl   $0x117534,(%esp)
  1000c4:	e8 9e 75 00 00       	call   107667 <memset>
	//cprintf("1\n");

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000c9:	e8 c6 02 00 00       	call   100394 <cons_init>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	//cprintf("1\n");
	cpu_init();
  1000ce:	e8 31 10 00 00       	call   101104 <cpu_init>
	//cprintf("1\n");
	trap_init();
  1000d3:	e8 75 15 00 00       	call   10164d <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000d8:	e8 5e 08 00 00       	call   10093b <mem_init>

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  1000dd:	e8 97 ff ff ff       	call   100079 <cpu_onboot>
  1000e2:	85 c0                	test   %eax,%eax
  1000e4:	74 05                	je     1000eb <init+0x5a>
		spinlock_check();
  1000e6:	e8 56 23 00 00       	call   102441 <spinlock_check>

	// Initialize the paged virtual memory system.
	pmap_init();
  1000eb:	e8 5d 3c 00 00       	call   103d4d <pmap_init>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000f0:	e8 ec 1f 00 00       	call   1020e1 <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000f5:	e8 75 64 00 00       	call   10656f <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000fa:	e8 a3 6a 00 00       	call   106ba2 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000ff:	e8 4e 67 00 00       	call   106852 <lapic_init>
		// Initialize the process management code.
	proc_init();
  100104:	e8 83 29 00 00       	call   102a8c <proc_init>
	cpu_bootothers();	// Get other processors started
  100109:	e8 c5 11 00 00       	call   1012d3 <cpu_bootothers>
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
		cpu_onboot() ? "BP" : "AP");
  10010e:	e8 66 ff ff ff       	call   100079 <cpu_onboot>
	ioapic_init();		// prepare to handle external device interrupts
	lapic_init();		// setup this CPU's local APIC
		// Initialize the process management code.
	proc_init();
	cpu_bootothers();	// Get other processors started
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
  100113:	85 c0                	test   %eax,%eax
  100115:	74 07                	je     10011e <init+0x8d>
  100117:	bb 18 7b 10 00       	mov    $0x107b18,%ebx
  10011c:	eb 05                	jmp    100123 <init+0x92>
  10011e:	bb 1b 7b 10 00       	mov    $0x107b1b,%ebx
  100123:	e8 fe fe ff ff       	call   100026 <cpu_cur>
  100128:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10012f:	0f b6 c0             	movzbl %al,%eax
  100132:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  100136:	89 44 24 04          	mov    %eax,0x4(%esp)
  10013a:	c7 04 24 1e 7b 10 00 	movl   $0x107b1e,(%esp)
  100141:	e8 3c 73 00 00       	call   107482 <cprintf>
	};
	
	trap_return(&tt);
	*/

	if(cpu_onboot()){
  100146:	e8 2e ff ff ff       	call   100079 <cpu_onboot>
  10014b:	85 c0                	test   %eax,%eax
  10014d:	74 71                	je     1001c0 <init+0x12f>
		proc_root = proc_alloc(&proc_null, 0);
  10014f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100156:	00 
  100157:	c7 04 24 80 dd 31 00 	movl   $0x31dd80,(%esp)
  10015e:	e8 77 29 00 00       	call   102ada <proc_alloc>
  100163:	a3 84 e4 31 00       	mov    %eax,0x31e484
		proc_root->sv.tf.eip = (uint32_t)(user);
  100168:	a1 84 e4 31 00       	mov    0x31e484,%eax
  10016d:	ba c5 01 10 00       	mov    $0x1001c5,%edx
  100172:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_root->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
  100178:	a1 84 e4 31 00       	mov    0x31e484,%eax
  10017d:	ba 00 90 11 00       	mov    $0x119000,%edx
  100182:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		//proc_root->sv.tf.eflags = FL_IOPL_3;
		proc_root->sv.tf.eflags = FL_IF;
  100188:	a1 84 e4 31 00       	mov    0x31e484,%eax
  10018d:	c7 80 90 04 00 00 00 	movl   $0x200,0x490(%eax)
  100194:	02 00 00 
		proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
  100197:	a1 84 e4 31 00       	mov    0x31e484,%eax
  10019c:	66 c7 80 70 04 00 00 	movw   $0x23,0x470(%eax)
  1001a3:	23 00 
		proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;
  1001a5:	a1 84 e4 31 00       	mov    0x31e484,%eax
  1001aa:	66 c7 80 74 04 00 00 	movw   $0x23,0x474(%eax)
  1001b1:	23 00 

		proc_ready(proc_root);	
  1001b3:	a1 84 e4 31 00       	mov    0x31e484,%eax
  1001b8:	89 04 24             	mov    %eax,(%esp)
  1001bb:	e8 f4 2a 00 00       	call   102cb4 <proc_ready>
	}

	
	proc_sched();
  1001c0:	e8 47 2d 00 00       	call   102f0c <proc_sched>

001001c5 <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1001c5:	55                   	push   %ebp
  1001c6:	89 e5                	mov    %esp,%ebp
  1001c8:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  1001cb:	c7 04 24 36 7b 10 00 	movl   $0x107b36,(%esp)
  1001d2:	e8 ab 72 00 00       	call   107482 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001d7:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  1001da:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  1001dd:	89 c2                	mov    %eax,%edx
  1001df:	b8 00 80 11 00       	mov    $0x118000,%eax
  1001e4:	39 c2                	cmp    %eax,%edx
  1001e6:	77 24                	ja     10020c <user+0x47>
  1001e8:	c7 44 24 0c 44 7b 10 	movl   $0x107b44,0xc(%esp)
  1001ef:	00 
  1001f0:	c7 44 24 08 f6 7a 10 	movl   $0x107af6,0x8(%esp)
  1001f7:	00 
  1001f8:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  1001ff:	00 
  100200:	c7 04 24 6b 7b 10 00 	movl   $0x107b6b,(%esp)
  100207:	e8 75 02 00 00       	call   100481 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10020c:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10020f:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  100212:	89 c2                	mov    %eax,%edx
  100214:	b8 00 90 11 00       	mov    $0x119000,%eax
  100219:	39 c2                	cmp    %eax,%edx
  10021b:	72 24                	jb     100241 <user+0x7c>
  10021d:	c7 44 24 0c 78 7b 10 	movl   $0x107b78,0xc(%esp)
  100224:	00 
  100225:	c7 44 24 08 f6 7a 10 	movl   $0x107af6,0x8(%esp)
  10022c:	00 
  10022d:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  100234:	00 
  100235:	c7 04 24 6b 7b 10 00 	movl   $0x107b6b,(%esp)
  10023c:	e8 40 02 00 00       	call   100481 <debug_panic>


	done();
  100241:	e8 00 00 00 00       	call   100246 <done>

00100246 <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  100246:	55                   	push   %ebp
  100247:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  100249:	eb fe                	jmp    100249 <done+0x3>

0010024b <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10024b:	55                   	push   %ebp
  10024c:	89 e5                	mov    %esp,%ebp
  10024e:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100251:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100254:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100257:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10025a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10025d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100262:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100265:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100268:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10026e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100273:	74 24                	je     100299 <cpu_cur+0x4e>
  100275:	c7 44 24 0c b0 7b 10 	movl   $0x107bb0,0xc(%esp)
  10027c:	00 
  10027d:	c7 44 24 08 c6 7b 10 	movl   $0x107bc6,0x8(%esp)
  100284:	00 
  100285:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10028c:	00 
  10028d:	c7 04 24 db 7b 10 00 	movl   $0x107bdb,(%esp)
  100294:	e8 e8 01 00 00       	call   100481 <debug_panic>
	return c;
  100299:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10029c:	c9                   	leave  
  10029d:	c3                   	ret    

0010029e <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10029e:	55                   	push   %ebp
  10029f:	89 e5                	mov    %esp,%ebp
  1002a1:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1002a4:	e8 a2 ff ff ff       	call   10024b <cpu_cur>
  1002a9:	3d 00 a0 10 00       	cmp    $0x10a000,%eax
  1002ae:	0f 94 c0             	sete   %al
  1002b1:	0f b6 c0             	movzbl %al,%eax
}
  1002b4:	c9                   	leave  
  1002b5:	c3                   	ret    

001002b6 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  1002b6:	55                   	push   %ebp
  1002b7:	89 e5                	mov    %esp,%ebp
  1002b9:	83 ec 28             	sub    $0x28,%esp
	int c;

	spinlock_acquire(&cons_lock);
  1002bc:	c7 04 24 c0 dc 11 00 	movl   $0x11dcc0,(%esp)
  1002c3:	e8 45 20 00 00       	call   10230d <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  1002c8:	eb 35                	jmp    1002ff <cons_intr+0x49>
		if (c == 0)
  1002ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1002ce:	74 2e                	je     1002fe <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  1002d0:	a1 04 92 11 00       	mov    0x119204,%eax
  1002d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1002d8:	88 90 00 90 11 00    	mov    %dl,0x119000(%eax)
  1002de:	83 c0 01             	add    $0x1,%eax
  1002e1:	a3 04 92 11 00       	mov    %eax,0x119204
		if (cons.wpos == CONSBUFSIZE)
  1002e6:	a1 04 92 11 00       	mov    0x119204,%eax
  1002eb:	3d 00 02 00 00       	cmp    $0x200,%eax
  1002f0:	75 0d                	jne    1002ff <cons_intr+0x49>
			cons.wpos = 0;
  1002f2:	c7 05 04 92 11 00 00 	movl   $0x0,0x119204
  1002f9:	00 00 00 
  1002fc:	eb 01                	jmp    1002ff <cons_intr+0x49>
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  1002fe:	90                   	nop
cons_intr(int (*proc)(void))
{
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
  1002ff:	8b 45 08             	mov    0x8(%ebp),%eax
  100302:	ff d0                	call   *%eax
  100304:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100307:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  10030b:	75 bd                	jne    1002ca <cons_intr+0x14>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
	spinlock_release(&cons_lock);
  10030d:	c7 04 24 c0 dc 11 00 	movl   $0x11dcc0,(%esp)
  100314:	e8 61 20 00 00       	call   10237a <spinlock_release>

}
  100319:	c9                   	leave  
  10031a:	c3                   	ret    

0010031b <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  10031b:	55                   	push   %ebp
  10031c:	89 e5                	mov    %esp,%ebp
  10031e:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  100321:	e8 f9 60 00 00       	call   10641f <serial_intr>
	kbd_intr();
  100326:	e8 4f 60 00 00       	call   10637a <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  10032b:	8b 15 00 92 11 00    	mov    0x119200,%edx
  100331:	a1 04 92 11 00       	mov    0x119204,%eax
  100336:	39 c2                	cmp    %eax,%edx
  100338:	74 35                	je     10036f <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  10033a:	a1 00 92 11 00       	mov    0x119200,%eax
  10033f:	0f b6 90 00 90 11 00 	movzbl 0x119000(%eax),%edx
  100346:	0f b6 d2             	movzbl %dl,%edx
  100349:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10034c:	83 c0 01             	add    $0x1,%eax
  10034f:	a3 00 92 11 00       	mov    %eax,0x119200
		if (cons.rpos == CONSBUFSIZE)
  100354:	a1 00 92 11 00       	mov    0x119200,%eax
  100359:	3d 00 02 00 00       	cmp    $0x200,%eax
  10035e:	75 0a                	jne    10036a <cons_getc+0x4f>
			cons.rpos = 0;
  100360:	c7 05 00 92 11 00 00 	movl   $0x0,0x119200
  100367:	00 00 00 
		return c;
  10036a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10036d:	eb 05                	jmp    100374 <cons_getc+0x59>
	}
	return 0;
  10036f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100374:	c9                   	leave  
  100375:	c3                   	ret    

00100376 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  100376:	55                   	push   %ebp
  100377:	89 e5                	mov    %esp,%ebp
  100379:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  10037c:	8b 45 08             	mov    0x8(%ebp),%eax
  10037f:	89 04 24             	mov    %eax,(%esp)
  100382:	e8 b5 60 00 00       	call   10643c <serial_putc>
	video_putc(c);
  100387:	8b 45 08             	mov    0x8(%ebp),%eax
  10038a:	89 04 24             	mov    %eax,(%esp)
  10038d:	e8 47 5c 00 00       	call   105fd9 <video_putc>
}
  100392:	c9                   	leave  
  100393:	c3                   	ret    

00100394 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100394:	55                   	push   %ebp
  100395:	89 e5                	mov    %esp,%ebp
  100397:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10039a:	e8 ff fe ff ff       	call   10029e <cpu_onboot>
  10039f:	85 c0                	test   %eax,%eax
  1003a1:	74 52                	je     1003f5 <cons_init+0x61>
		return;

	spinlock_init(&cons_lock);
  1003a3:	c7 44 24 08 6a 00 00 	movl   $0x6a,0x8(%esp)
  1003aa:	00 
  1003ab:	c7 44 24 04 e8 7b 10 	movl   $0x107be8,0x4(%esp)
  1003b2:	00 
  1003b3:	c7 04 24 c0 dc 11 00 	movl   $0x11dcc0,(%esp)
  1003ba:	e8 1a 1f 00 00       	call   1022d9 <spinlock_init_>
	video_init();
  1003bf:	e8 49 5b 00 00       	call   105f0d <video_init>
	kbd_init();
  1003c4:	e8 c5 5f 00 00       	call   10638e <kbd_init>
	serial_init();
  1003c9:	e8 d3 60 00 00       	call   1064a1 <serial_init>

	if (!serial_exists)
  1003ce:	a1 00 10 32 00       	mov    0x321000,%eax
  1003d3:	85 c0                	test   %eax,%eax
  1003d5:	75 1f                	jne    1003f6 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  1003d7:	c7 44 24 08 f4 7b 10 	movl   $0x107bf4,0x8(%esp)
  1003de:	00 
  1003df:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  1003e6:	00 
  1003e7:	c7 04 24 e8 7b 10 00 	movl   $0x107be8,(%esp)
  1003ee:	e8 4d 01 00 00       	call   100540 <debug_warn>
  1003f3:	eb 01                	jmp    1003f6 <cons_init+0x62>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  1003f5:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  1003f6:	c9                   	leave  
  1003f7:	c3                   	ret    

001003f8 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  1003f8:	55                   	push   %ebp
  1003f9:	89 e5                	mov    %esp,%ebp
  1003fb:	53                   	push   %ebx
  1003fc:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1003ff:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  100402:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	if (read_cs() & 3)
  100406:	0f b7 c0             	movzwl %ax,%eax
  100409:	83 e0 03             	and    $0x3,%eax
  10040c:	85 c0                	test   %eax,%eax
  10040e:	74 14                	je     100424 <cputs+0x2c>
  100410:	8b 45 08             	mov    0x8(%ebp),%eax
  100413:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  100416:	b8 00 00 00 00       	mov    $0x0,%eax
  10041b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10041e:	89 d3                	mov    %edx,%ebx
  100420:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  100422:	eb 57                	jmp    10047b <cputs+0x83>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  100424:	c7 04 24 c0 dc 11 00 	movl   $0x11dcc0,(%esp)
  10042b:	e8 a4 1f 00 00       	call   1023d4 <spinlock_holding>
  100430:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!already)
  100433:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100437:	75 25                	jne    10045e <cputs+0x66>
		spinlock_acquire(&cons_lock);
  100439:	c7 04 24 c0 dc 11 00 	movl   $0x11dcc0,(%esp)
  100440:	e8 c8 1e 00 00       	call   10230d <spinlock_acquire>

	char ch;
	while (*str)
  100445:	eb 18                	jmp    10045f <cputs+0x67>
		cons_putc(*str++);
  100447:	8b 45 08             	mov    0x8(%ebp),%eax
  10044a:	0f b6 00             	movzbl (%eax),%eax
  10044d:	0f be c0             	movsbl %al,%eax
  100450:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100454:	89 04 24             	mov    %eax,(%esp)
  100457:	e8 1a ff ff ff       	call   100376 <cons_putc>
  10045c:	eb 01                	jmp    10045f <cputs+0x67>
	bool already = spinlock_holding(&cons_lock);
	if (!already)
		spinlock_acquire(&cons_lock);

	char ch;
	while (*str)
  10045e:	90                   	nop
  10045f:	8b 45 08             	mov    0x8(%ebp),%eax
  100462:	0f b6 00             	movzbl (%eax),%eax
  100465:	84 c0                	test   %al,%al
  100467:	75 de                	jne    100447 <cputs+0x4f>
		cons_putc(*str++);

	if (!already)
  100469:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10046d:	75 0c                	jne    10047b <cputs+0x83>
		spinlock_release(&cons_lock);
  10046f:	c7 04 24 c0 dc 11 00 	movl   $0x11dcc0,(%esp)
  100476:	e8 ff 1e 00 00       	call   10237a <spinlock_release>
}
  10047b:	83 c4 24             	add    $0x24,%esp
  10047e:	5b                   	pop    %ebx
  10047f:	5d                   	pop    %ebp
  100480:	c3                   	ret    

00100481 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100481:	55                   	push   %ebp
  100482:	89 e5                	mov    %esp,%ebp
  100484:	83 ec 58             	sub    $0x58,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  100487:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  10048a:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  10048e:	0f b7 c0             	movzwl %ax,%eax
  100491:	83 e0 03             	and    $0x3,%eax
  100494:	85 c0                	test   %eax,%eax
  100496:	75 15                	jne    1004ad <debug_panic+0x2c>
		if (panicstr)
  100498:	a1 08 92 11 00       	mov    0x119208,%eax
  10049d:	85 c0                	test   %eax,%eax
  10049f:	0f 85 95 00 00 00    	jne    10053a <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  1004a5:	8b 45 10             	mov    0x10(%ebp),%eax
  1004a8:	a3 08 92 11 00       	mov    %eax,0x119208
	}

	// First print the requested message
	va_start(ap, fmt);
  1004ad:	8d 45 10             	lea    0x10(%ebp),%eax
  1004b0:	83 c0 04             	add    $0x4,%eax
  1004b3:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  1004b6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004b9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1004bd:	8b 45 08             	mov    0x8(%ebp),%eax
  1004c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004c4:	c7 04 24 11 7c 10 00 	movl   $0x107c11,(%esp)
  1004cb:	e8 b2 6f 00 00       	call   107482 <cprintf>
	vcprintf(fmt, ap);
  1004d0:	8b 45 10             	mov    0x10(%ebp),%eax
  1004d3:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1004d6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1004da:	89 04 24             	mov    %eax,(%esp)
  1004dd:	e8 37 6f 00 00       	call   107419 <vcprintf>
	cprintf("\n");
  1004e2:	c7 04 24 29 7c 10 00 	movl   $0x107c29,(%esp)
  1004e9:	e8 94 6f 00 00       	call   107482 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1004ee:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  1004f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1004f4:	8d 55 c0             	lea    -0x40(%ebp),%edx
  1004f7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1004fb:	89 04 24             	mov    %eax,(%esp)
  1004fe:	e8 86 00 00 00       	call   100589 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  100503:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  10050a:	eb 1b                	jmp    100527 <debug_panic+0xa6>
		cprintf("  from %08x\n", eips[i]);
  10050c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10050f:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  100513:	89 44 24 04          	mov    %eax,0x4(%esp)
  100517:	c7 04 24 2b 7c 10 00 	movl   $0x107c2b,(%esp)
  10051e:	e8 5f 6f 00 00       	call   107482 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  100523:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100527:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  10052b:	7f 0e                	jg     10053b <debug_panic+0xba>
  10052d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100530:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  100534:	85 c0                	test   %eax,%eax
  100536:	75 d4                	jne    10050c <debug_panic+0x8b>
  100538:	eb 01                	jmp    10053b <debug_panic+0xba>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  10053a:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  10053b:	e8 06 fd ff ff       	call   100246 <done>

00100540 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  100540:	55                   	push   %ebp
  100541:	89 e5                	mov    %esp,%ebp
  100543:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  100546:	8d 45 10             	lea    0x10(%ebp),%eax
  100549:	83 c0 04             	add    $0x4,%eax
  10054c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  10054f:	8b 45 0c             	mov    0xc(%ebp),%eax
  100552:	89 44 24 08          	mov    %eax,0x8(%esp)
  100556:	8b 45 08             	mov    0x8(%ebp),%eax
  100559:	89 44 24 04          	mov    %eax,0x4(%esp)
  10055d:	c7 04 24 38 7c 10 00 	movl   $0x107c38,(%esp)
  100564:	e8 19 6f 00 00       	call   107482 <cprintf>
	vcprintf(fmt, ap);
  100569:	8b 45 10             	mov    0x10(%ebp),%eax
  10056c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10056f:	89 54 24 04          	mov    %edx,0x4(%esp)
  100573:	89 04 24             	mov    %eax,(%esp)
  100576:	e8 9e 6e 00 00       	call   107419 <vcprintf>
	cprintf("\n");
  10057b:	c7 04 24 29 7c 10 00 	movl   $0x107c29,(%esp)
  100582:	e8 fb 6e 00 00       	call   107482 <cprintf>
	va_end(ap);
}
  100587:	c9                   	leave  
  100588:	c3                   	ret    

00100589 <debug_trace>:

// Riecord the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100589:	55                   	push   %ebp
  10058a:	89 e5                	mov    %esp,%ebp
  10058c:	83 ec 10             	sub    $0x10,%esp

	return;*/
	//panic("debug_trace not implemented");

	int i ,j;
	uint32_t *cur_epb = (uint32_t *)ebp;
  10058f:	8b 45 08             	mov    0x8(%ebp),%eax
  100592:	89 45 fc             	mov    %eax,-0x4(%ebp)
	//cprintf("Stack backtrace:\n");
	for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  100595:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10059c:	eb 32                	jmp    1005d0 <debug_trace+0x47>
		//cprintf("  ebp %08x eip %08x args",cur_epb[0],cur_epb[1]);
		eips[i] = cur_epb[1];
  10059e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1005a1:	c1 e0 02             	shl    $0x2,%eax
  1005a4:	03 45 0c             	add    0xc(%ebp),%eax
  1005a7:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1005aa:	83 c2 04             	add    $0x4,%edx
  1005ad:	8b 12                	mov    (%edx),%edx
  1005af:	89 10                	mov    %edx,(%eax)
		for(j = 0; j < 5; j++) {
  1005b1:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1005b8:	eb 04                	jmp    1005be <debug_trace+0x35>
  1005ba:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1005be:	83 7d f8 04          	cmpl   $0x4,-0x8(%ebp)
  1005c2:	7e f6                	jle    1005ba <debug_trace+0x31>
			//makecprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");make
		cur_epb = (uint32_t *)(*cur_epb);
  1005c4:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1005c7:	8b 00                	mov    (%eax),%eax
  1005c9:	89 45 fc             	mov    %eax,-0x4(%ebp)
	//panic("debug_trace not implemented");

	int i ,j;
	uint32_t *cur_epb = (uint32_t *)ebp;
	//cprintf("Stack backtrace:\n");
	for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  1005cc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1005d0:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1005d4:	7f 1b                	jg     1005f1 <debug_trace+0x68>
  1005d6:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  1005da:	75 c2                	jne    10059e <debug_trace+0x15>
			//makecprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");make
		cur_epb = (uint32_t *)(*cur_epb);
	}
	for(; i < DEBUG_TRACEFRAMES ; i++) {
  1005dc:	eb 13                	jmp    1005f1 <debug_trace+0x68>
		eips[i] = 0;
  1005de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1005e1:	c1 e0 02             	shl    $0x2,%eax
  1005e4:	03 45 0c             	add    0xc(%ebp),%eax
  1005e7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			//makecprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");make
		cur_epb = (uint32_t *)(*cur_epb);
	}
	for(; i < DEBUG_TRACEFRAMES ; i++) {
  1005ed:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1005f1:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1005f5:	7e e7                	jle    1005de <debug_trace+0x55>
		eips[i] = 0;
	}
	/*
	for(i = 0; i < DEBUG_TRACEFRAMES ; i++) {
		cprintf("eip %x\n",eips[i]);			}*/
}
  1005f7:	c9                   	leave  
  1005f8:	c3                   	ret    

001005f9 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  1005f9:	55                   	push   %ebp
  1005fa:	89 e5                	mov    %esp,%ebp
  1005fc:	83 ec 18             	sub    $0x18,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1005ff:	89 6d fc             	mov    %ebp,-0x4(%ebp)
        return ebp;
  100602:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100605:	8b 55 0c             	mov    0xc(%ebp),%edx
  100608:	89 54 24 04          	mov    %edx,0x4(%esp)
  10060c:	89 04 24             	mov    %eax,(%esp)
  10060f:	e8 75 ff ff ff       	call   100589 <debug_trace>
  100614:	c9                   	leave  
  100615:	c3                   	ret    

00100616 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100616:	55                   	push   %ebp
  100617:	89 e5                	mov    %esp,%ebp
  100619:	83 ec 08             	sub    $0x8,%esp
  10061c:	8b 45 08             	mov    0x8(%ebp),%eax
  10061f:	83 e0 02             	and    $0x2,%eax
  100622:	85 c0                	test   %eax,%eax
  100624:	74 14                	je     10063a <f2+0x24>
  100626:	8b 45 0c             	mov    0xc(%ebp),%eax
  100629:	89 44 24 04          	mov    %eax,0x4(%esp)
  10062d:	8b 45 08             	mov    0x8(%ebp),%eax
  100630:	89 04 24             	mov    %eax,(%esp)
  100633:	e8 c1 ff ff ff       	call   1005f9 <f3>
  100638:	eb 12                	jmp    10064c <f2+0x36>
  10063a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10063d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100641:	8b 45 08             	mov    0x8(%ebp),%eax
  100644:	89 04 24             	mov    %eax,(%esp)
  100647:	e8 ad ff ff ff       	call   1005f9 <f3>
  10064c:	c9                   	leave  
  10064d:	c3                   	ret    

0010064e <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  10064e:	55                   	push   %ebp
  10064f:	89 e5                	mov    %esp,%ebp
  100651:	83 ec 08             	sub    $0x8,%esp
  100654:	8b 45 08             	mov    0x8(%ebp),%eax
  100657:	83 e0 01             	and    $0x1,%eax
  10065a:	84 c0                	test   %al,%al
  10065c:	74 14                	je     100672 <f1+0x24>
  10065e:	8b 45 0c             	mov    0xc(%ebp),%eax
  100661:	89 44 24 04          	mov    %eax,0x4(%esp)
  100665:	8b 45 08             	mov    0x8(%ebp),%eax
  100668:	89 04 24             	mov    %eax,(%esp)
  10066b:	e8 a6 ff ff ff       	call   100616 <f2>
  100670:	eb 12                	jmp    100684 <f1+0x36>
  100672:	8b 45 0c             	mov    0xc(%ebp),%eax
  100675:	89 44 24 04          	mov    %eax,0x4(%esp)
  100679:	8b 45 08             	mov    0x8(%ebp),%eax
  10067c:	89 04 24             	mov    %eax,(%esp)
  10067f:	e8 92 ff ff ff       	call   100616 <f2>
  100684:	c9                   	leave  
  100685:	c3                   	ret    

00100686 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100686:	55                   	push   %ebp
  100687:	89 e5                	mov    %esp,%ebp
  100689:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  10068f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100696:	eb 29                	jmp    1006c1 <debug_check+0x3b>
		f1(i, eips[i]);
  100698:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  10069e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1006a1:	89 d0                	mov    %edx,%eax
  1006a3:	c1 e0 02             	shl    $0x2,%eax
  1006a6:	01 d0                	add    %edx,%eax
  1006a8:	c1 e0 03             	shl    $0x3,%eax
  1006ab:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  1006ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  1006b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006b5:	89 04 24             	mov    %eax,(%esp)
  1006b8:	e8 91 ff ff ff       	call   10064e <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1006bd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1006c1:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  1006c5:	7e d1                	jle    100698 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1006c7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1006ce:	e9 bc 00 00 00       	jmp    10078f <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1006d3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1006da:	e9 a2 00 00 00       	jmp    100781 <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  1006df:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1006e2:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  1006e5:	89 d0                	mov    %edx,%eax
  1006e7:	c1 e0 02             	shl    $0x2,%eax
  1006ea:	01 d0                	add    %edx,%eax
  1006ec:	01 c0                	add    %eax,%eax
  1006ee:	01 c8                	add    %ecx,%eax
  1006f0:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  1006f7:	85 c0                	test   %eax,%eax
  1006f9:	0f 95 c2             	setne  %dl
  1006fc:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  100700:	0f 9e c0             	setle  %al
  100703:	31 d0                	xor    %edx,%eax
  100705:	84 c0                	test   %al,%al
  100707:	74 24                	je     10072d <debug_check+0xa7>
  100709:	c7 44 24 0c 52 7c 10 	movl   $0x107c52,0xc(%esp)
  100710:	00 
  100711:	c7 44 24 08 6f 7c 10 	movl   $0x107c6f,0x8(%esp)
  100718:	00 
  100719:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100720:	00 
  100721:	c7 04 24 84 7c 10 00 	movl   $0x107c84,(%esp)
  100728:	e8 54 fd ff ff       	call   100481 <debug_panic>
			if (i >= 2)
  10072d:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  100731:	7e 4a                	jle    10077d <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  100733:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100736:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100739:	89 d0                	mov    %edx,%eax
  10073b:	c1 e0 02             	shl    $0x2,%eax
  10073e:	01 d0                	add    %edx,%eax
  100740:	01 c0                	add    %eax,%eax
  100742:	01 c8                	add    %ecx,%eax
  100744:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  10074b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10074e:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100755:	39 c2                	cmp    %eax,%edx
  100757:	74 24                	je     10077d <debug_check+0xf7>
  100759:	c7 44 24 0c 91 7c 10 	movl   $0x107c91,0xc(%esp)
  100760:	00 
  100761:	c7 44 24 08 6f 7c 10 	movl   $0x107c6f,0x8(%esp)
  100768:	00 
  100769:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  100770:	00 
  100771:	c7 04 24 84 7c 10 00 	movl   $0x107c84,(%esp)
  100778:	e8 04 fd ff ff       	call   100481 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  10077d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100781:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100785:	0f 8e 54 ff ff ff    	jle    1006df <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  10078b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10078f:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  100793:	0f 8e 3a ff ff ff    	jle    1006d3 <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  100799:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  10079f:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  1007a5:	39 c2                	cmp    %eax,%edx
  1007a7:	74 24                	je     1007cd <debug_check+0x147>
  1007a9:	c7 44 24 0c aa 7c 10 	movl   $0x107caa,0xc(%esp)
  1007b0:	00 
  1007b1:	c7 44 24 08 6f 7c 10 	movl   $0x107c6f,0x8(%esp)
  1007b8:	00 
  1007b9:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  1007c0:	00 
  1007c1:	c7 04 24 84 7c 10 00 	movl   $0x107c84,(%esp)
  1007c8:	e8 b4 fc ff ff       	call   100481 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1007cd:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1007d0:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1007d3:	39 c2                	cmp    %eax,%edx
  1007d5:	74 24                	je     1007fb <debug_check+0x175>
  1007d7:	c7 44 24 0c c3 7c 10 	movl   $0x107cc3,0xc(%esp)
  1007de:	00 
  1007df:	c7 44 24 08 6f 7c 10 	movl   $0x107c6f,0x8(%esp)
  1007e6:	00 
  1007e7:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  1007ee:	00 
  1007ef:	c7 04 24 84 7c 10 00 	movl   $0x107c84,(%esp)
  1007f6:	e8 86 fc ff ff       	call   100481 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  1007fb:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100801:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100804:	39 c2                	cmp    %eax,%edx
  100806:	75 24                	jne    10082c <debug_check+0x1a6>
  100808:	c7 44 24 0c dc 7c 10 	movl   $0x107cdc,0xc(%esp)
  10080f:	00 
  100810:	c7 44 24 08 6f 7c 10 	movl   $0x107c6f,0x8(%esp)
  100817:	00 
  100818:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  10081f:	00 
  100820:	c7 04 24 84 7c 10 00 	movl   $0x107c84,(%esp)
  100827:	e8 55 fc ff ff       	call   100481 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10082c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100832:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100835:	39 c2                	cmp    %eax,%edx
  100837:	74 24                	je     10085d <debug_check+0x1d7>
  100839:	c7 44 24 0c f5 7c 10 	movl   $0x107cf5,0xc(%esp)
  100840:	00 
  100841:	c7 44 24 08 6f 7c 10 	movl   $0x107c6f,0x8(%esp)
  100848:	00 
  100849:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100850:	00 
  100851:	c7 04 24 84 7c 10 00 	movl   $0x107c84,(%esp)
  100858:	e8 24 fc ff ff       	call   100481 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10085d:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100863:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100866:	39 c2                	cmp    %eax,%edx
  100868:	74 24                	je     10088e <debug_check+0x208>
  10086a:	c7 44 24 0c 0e 7d 10 	movl   $0x107d0e,0xc(%esp)
  100871:	00 
  100872:	c7 44 24 08 6f 7c 10 	movl   $0x107c6f,0x8(%esp)
  100879:	00 
  10087a:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100881:	00 
  100882:	c7 04 24 84 7c 10 00 	movl   $0x107c84,(%esp)
  100889:	e8 f3 fb ff ff       	call   100481 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10088e:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100894:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  10089a:	39 c2                	cmp    %eax,%edx
  10089c:	75 24                	jne    1008c2 <debug_check+0x23c>
  10089e:	c7 44 24 0c 27 7d 10 	movl   $0x107d27,0xc(%esp)
  1008a5:	00 
  1008a6:	c7 44 24 08 6f 7c 10 	movl   $0x107c6f,0x8(%esp)
  1008ad:	00 
  1008ae:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  1008b5:	00 
  1008b6:	c7 04 24 84 7c 10 00 	movl   $0x107c84,(%esp)
  1008bd:	e8 bf fb ff ff       	call   100481 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1008c2:	c7 04 24 40 7d 10 00 	movl   $0x107d40,(%esp)
  1008c9:	e8 b4 6b 00 00       	call   107482 <cprintf>
}
  1008ce:	c9                   	leave  
  1008cf:	c3                   	ret    

001008d0 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1008d0:	55                   	push   %ebp
  1008d1:	89 e5                	mov    %esp,%ebp
  1008d3:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1008d6:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1008d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1008dc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1008df:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1008e2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008e7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1008ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1008ed:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1008f3:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1008f8:	74 24                	je     10091e <cpu_cur+0x4e>
  1008fa:	c7 44 24 0c 5c 7d 10 	movl   $0x107d5c,0xc(%esp)
  100901:	00 
  100902:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100909:	00 
  10090a:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100911:	00 
  100912:	c7 04 24 87 7d 10 00 	movl   $0x107d87,(%esp)
  100919:	e8 63 fb ff ff       	call   100481 <debug_panic>
	return c;
  10091e:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100921:	c9                   	leave  
  100922:	c3                   	ret    

00100923 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100923:	55                   	push   %ebp
  100924:	89 e5                	mov    %esp,%ebp
  100926:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100929:	e8 a2 ff ff ff       	call   1008d0 <cpu_cur>
  10092e:	3d 00 a0 10 00       	cmp    $0x10a000,%eax
  100933:	0f 94 c0             	sete   %al
  100936:	0f b6 c0             	movzbl %al,%eax
}
  100939:	c9                   	leave  
  10093a:	c3                   	ret    

0010093b <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  10093b:	55                   	push   %ebp
  10093c:	89 e5                	mov    %esp,%ebp
  10093e:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100941:	e8 dd ff ff ff       	call   100923 <cpu_onboot>
  100946:	85 c0                	test   %eax,%eax
  100948:	0f 84 bc 01 00 00    	je     100b0a <mem_init+0x1cf>
		return;

	
	spinlock_init(&mem_spinlock);
  10094e:	c7 44 24 08 2e 00 00 	movl   $0x2e,0x8(%esp)
  100955:	00 
  100956:	c7 44 24 04 94 7d 10 	movl   $0x107d94,0x4(%esp)
  10095d:	00 
  10095e:	c7 04 24 20 dd 31 00 	movl   $0x31dd20,(%esp)
  100965:	e8 6f 19 00 00       	call   1022d9 <spinlock_init_>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  10096a:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100971:	e8 02 5e 00 00       	call   106778 <nvram_read16>
  100976:	c1 e0 0a             	shl    $0xa,%eax
  100979:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10097c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10097f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100984:	89 45 dc             	mov    %eax,-0x24(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100987:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  10098e:	e8 e5 5d 00 00       	call   106778 <nvram_read16>
  100993:	c1 e0 0a             	shl    $0xa,%eax
  100996:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100999:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10099c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1009a1:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  1009a4:	c7 44 24 08 a0 7d 10 	movl   $0x107da0,0x8(%esp)
  1009ab:	00 
  1009ac:	c7 44 24 04 39 00 00 	movl   $0x39,0x4(%esp)
  1009b3:	00 
  1009b4:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  1009bb:	e8 80 fb ff ff       	call   100540 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1009c0:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1009c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009ca:	05 00 00 10 00       	add    $0x100000,%eax
  1009cf:	a3 08 dd 11 00       	mov    %eax,0x11dd08

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1009d4:	a1 08 dd 11 00       	mov    0x11dd08,%eax
  1009d9:	c1 e8 0c             	shr    $0xc,%eax
  1009dc:	a3 04 dd 11 00       	mov    %eax,0x11dd04

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  1009e1:	a1 08 dd 11 00       	mov    0x11dd08,%eax
  1009e6:	c1 e8 0a             	shr    $0xa,%eax
  1009e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009ed:	c7 04 24 c0 7d 10 00 	movl   $0x107dc0,(%esp)
  1009f4:	e8 89 6a 00 00       	call   107482 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  1009f9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009fc:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  1009ff:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  100a01:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100a04:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100a07:	89 54 24 08          	mov    %edx,0x8(%esp)
  100a0b:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a0f:	c7 04 24 e1 7d 10 00 	movl   $0x107de1,(%esp)
  100a16:	e8 67 6a 00 00       	call   107482 <cprintf>


	extern char start[], end[];
	uint32_t page_start;
	
	pageinfo **freetail = &mem_freelist;
  100a1b:	c7 45 e8 00 dd 11 00 	movl   $0x11dd00,-0x18(%ebp)
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100a22:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100a29:	00 
  100a2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100a31:	00 
  100a32:	c7 04 24 20 dd 11 00 	movl   $0x11dd20,(%esp)
  100a39:	e8 29 6c 00 00       	call   107667 <memset>
	mem_pageinfo = spc_for_pi;
  100a3e:	c7 05 58 dd 31 00 20 	movl   $0x11dd20,0x31dd58
  100a45:	dd 11 00 
	int i;
	for (i = 0; i < mem_npage; i++) {
  100a48:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100a4f:	e9 96 00 00 00       	jmp    100aea <mem_init+0x1af>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100a54:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  100a59:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a5c:	c1 e2 03             	shl    $0x3,%edx
  100a5f:	01 d0                	add    %edx,%eax
  100a61:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		if(i == 0 || i == 1)
  100a68:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100a6c:	74 6e                	je     100adc <mem_init+0x1a1>
  100a6e:	83 7d ec 01          	cmpl   $0x1,-0x14(%ebp)
  100a72:	74 6b                	je     100adf <mem_init+0x1a4>
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);
  100a74:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100a77:	c1 e0 03             	shl    $0x3,%eax
  100a7a:	c1 f8 03             	sar    $0x3,%eax
  100a7d:	c1 e0 0c             	shl    $0xc,%eax
  100a80:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100a83:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100a86:	05 00 10 00 00       	add    $0x1000,%eax
  100a8b:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  100a90:	76 09                	jbe    100a9b <mem_init+0x160>
  100a92:	81 7d e4 ff ff 0f 00 	cmpl   $0xfffff,-0x1c(%ebp)
  100a99:	76 47                	jbe    100ae2 <mem_init+0x1a7>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  100a9b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100a9e:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
  100aa4:	b8 0c 00 10 00       	mov    $0x10000c,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100aa9:	39 c2                	cmp    %eax,%edx
  100aab:	72 0a                	jb     100ab7 <mem_init+0x17c>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  100aad:	b8 08 10 32 00       	mov    $0x321008,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100ab2:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  100ab5:	72 2e                	jb     100ae5 <mem_init+0x1aa>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;


		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100ab7:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  100abc:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100abf:	c1 e2 03             	shl    $0x3,%edx
  100ac2:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100ac5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ac8:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100aca:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  100acf:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100ad2:	c1 e2 03             	shl    $0x3,%edx
  100ad5:	01 d0                	add    %edx,%eax
  100ad7:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100ada:	eb 0a                	jmp    100ae6 <mem_init+0x1ab>
	for (i = 0; i < mem_npage; i++) {
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;

		if(i == 0 || i == 1)
			continue;
  100adc:	90                   	nop
  100add:	eb 07                	jmp    100ae6 <mem_init+0x1ab>
  100adf:	90                   	nop
  100ae0:	eb 04                	jmp    100ae6 <mem_init+0x1ab>

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;
  100ae2:	90                   	nop
  100ae3:	eb 01                	jmp    100ae6 <mem_init+0x1ab>
  100ae5:	90                   	nop
	
	pageinfo **freetail = &mem_freelist;
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
	mem_pageinfo = spc_for_pi;
	int i;
	for (i = 0; i < mem_npage; i++) {
  100ae6:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100aea:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100aed:	a1 04 dd 11 00       	mov    0x11dd04,%eax
  100af2:	39 c2                	cmp    %eax,%edx
  100af4:	0f 82 5a ff ff ff    	jb     100a54 <mem_init+0x119>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100afa:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100afd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100b03:	e8 a1 00 00 00       	call   100ba9 <mem_check>
  100b08:	eb 01                	jmp    100b0b <mem_init+0x1d0>

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100b0a:	90                   	nop
	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100b0b:	c9                   	leave  
  100b0c:	c3                   	ret    

00100b0d <mem_alloc>:



pageinfo *
mem_alloc(void)
{
  100b0d:	55                   	push   %ebp
  100b0e:	89 e5                	mov    %esp,%ebp
  100b10:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	// Fill this function in.
	//panic("mem_alloc not implemented.");

	if(mem_freelist == NULL)
  100b13:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  100b18:	85 c0                	test   %eax,%eax
  100b1a:	75 07                	jne    100b23 <mem_alloc+0x16>
		return NULL;
  100b1c:	b8 00 00 00 00       	mov    $0x0,%eax
  100b21:	eb 2f                	jmp    100b52 <mem_alloc+0x45>

	spinlock_acquire(&mem_spinlock);
  100b23:	c7 04 24 20 dd 31 00 	movl   $0x31dd20,(%esp)
  100b2a:	e8 de 17 00 00       	call   10230d <spinlock_acquire>
	pageinfo* r = mem_freelist;
  100b2f:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  100b34:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = mem_freelist->free_next;
  100b37:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  100b3c:	8b 00                	mov    (%eax),%eax
  100b3e:	a3 00 dd 11 00       	mov    %eax,0x11dd00
	spinlock_release(&mem_spinlock);
  100b43:	c7 04 24 20 dd 31 00 	movl   $0x31dd20,(%esp)
  100b4a:	e8 2b 18 00 00       	call   10237a <spinlock_release>
	return r;
  100b4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100b52:	c9                   	leave  
  100b53:	c3                   	ret    

00100b54 <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100b54:	55                   	push   %ebp
  100b55:	89 e5                	mov    %esp,%ebp
  100b57:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");

	if(pi == NULL)
  100b5a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100b5e:	75 1c                	jne    100b7c <mem_free+0x28>
		panic("null for page which to be freed!"); 
  100b60:	c7 44 24 08 00 7e 10 	movl   $0x107e00,0x8(%esp)
  100b67:	00 
  100b68:	c7 44 24 04 ab 00 00 	movl   $0xab,0x4(%esp)
  100b6f:	00 
  100b70:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100b77:	e8 05 f9 ff ff       	call   100481 <debug_panic>

	spinlock_acquire(&mem_spinlock);
  100b7c:	c7 04 24 20 dd 31 00 	movl   $0x31dd20,(%esp)
  100b83:	e8 85 17 00 00       	call   10230d <spinlock_acquire>
	pi->free_next = mem_freelist;
  100b88:	8b 15 00 dd 11 00    	mov    0x11dd00,%edx
  100b8e:	8b 45 08             	mov    0x8(%ebp),%eax
  100b91:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100b93:	8b 45 08             	mov    0x8(%ebp),%eax
  100b96:	a3 00 dd 11 00       	mov    %eax,0x11dd00
	spinlock_release(&mem_spinlock);
  100b9b:	c7 04 24 20 dd 31 00 	movl   $0x31dd20,(%esp)
  100ba2:	e8 d3 17 00 00       	call   10237a <spinlock_release>
	
}
  100ba7:	c9                   	leave  
  100ba8:	c3                   	ret    

00100ba9 <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100ba9:	55                   	push   %ebp
  100baa:	89 e5                	mov    %esp,%ebp
  100bac:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100baf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100bb6:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  100bbb:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100bbe:	eb 38                	jmp    100bf8 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100bc0:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100bc3:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  100bc8:	89 d1                	mov    %edx,%ecx
  100bca:	29 c1                	sub    %eax,%ecx
  100bcc:	89 c8                	mov    %ecx,%eax
  100bce:	c1 f8 03             	sar    $0x3,%eax
  100bd1:	c1 e0 0c             	shl    $0xc,%eax
  100bd4:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100bdb:	00 
  100bdc:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100be3:	00 
  100be4:	89 04 24             	mov    %eax,(%esp)
  100be7:	e8 7b 6a 00 00       	call   107667 <memset>
		freepages++;
  100bec:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100bf0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100bf3:	8b 00                	mov    (%eax),%eax
  100bf5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100bf8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  100bfc:	75 c2                	jne    100bc0 <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100bfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100c01:	89 44 24 04          	mov    %eax,0x4(%esp)
  100c05:	c7 04 24 21 7e 10 00 	movl   $0x107e21,(%esp)
  100c0c:	e8 71 68 00 00       	call   107482 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100c11:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c14:	a1 04 dd 11 00       	mov    0x11dd04,%eax
  100c19:	39 c2                	cmp    %eax,%edx
  100c1b:	72 24                	jb     100c41 <mem_check+0x98>
  100c1d:	c7 44 24 0c 3b 7e 10 	movl   $0x107e3b,0xc(%esp)
  100c24:	00 
  100c25:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100c2c:	00 
  100c2d:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100c34:	00 
  100c35:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100c3c:	e8 40 f8 ff ff       	call   100481 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100c41:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100c48:	7f 24                	jg     100c6e <mem_check+0xc5>
  100c4a:	c7 44 24 0c 51 7e 10 	movl   $0x107e51,0xc(%esp)
  100c51:	00 
  100c52:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100c59:	00 
  100c5a:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  100c61:	00 
  100c62:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100c69:	e8 13 f8 ff ff       	call   100481 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100c6e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100c75:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100c78:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100c7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100c7e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100c81:	e8 87 fe ff ff       	call   100b0d <mem_alloc>
  100c86:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100c89:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100c8d:	75 24                	jne    100cb3 <mem_check+0x10a>
  100c8f:	c7 44 24 0c 63 7e 10 	movl   $0x107e63,0xc(%esp)
  100c96:	00 
  100c97:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100c9e:	00 
  100c9f:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100ca6:	00 
  100ca7:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100cae:	e8 ce f7 ff ff       	call   100481 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100cb3:	e8 55 fe ff ff       	call   100b0d <mem_alloc>
  100cb8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100cbb:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100cbf:	75 24                	jne    100ce5 <mem_check+0x13c>
  100cc1:	c7 44 24 0c 6c 7e 10 	movl   $0x107e6c,0xc(%esp)
  100cc8:	00 
  100cc9:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100cd0:	00 
  100cd1:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100cd8:	00 
  100cd9:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100ce0:	e8 9c f7 ff ff       	call   100481 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100ce5:	e8 23 fe ff ff       	call   100b0d <mem_alloc>
  100cea:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100ced:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100cf1:	75 24                	jne    100d17 <mem_check+0x16e>
  100cf3:	c7 44 24 0c 75 7e 10 	movl   $0x107e75,0xc(%esp)
  100cfa:	00 
  100cfb:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100d02:	00 
  100d03:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  100d0a:	00 
  100d0b:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100d12:	e8 6a f7 ff ff       	call   100481 <debug_panic>

	assert(pp0);
  100d17:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100d1b:	75 24                	jne    100d41 <mem_check+0x198>
  100d1d:	c7 44 24 0c 7e 7e 10 	movl   $0x107e7e,0xc(%esp)
  100d24:	00 
  100d25:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100d2c:	00 
  100d2d:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100d34:	00 
  100d35:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100d3c:	e8 40 f7 ff ff       	call   100481 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100d41:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d45:	74 08                	je     100d4f <mem_check+0x1a6>
  100d47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d4a:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d4d:	75 24                	jne    100d73 <mem_check+0x1ca>
  100d4f:	c7 44 24 0c 82 7e 10 	movl   $0x107e82,0xc(%esp)
  100d56:	00 
  100d57:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100d5e:	00 
  100d5f:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100d66:	00 
  100d67:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100d6e:	e8 0e f7 ff ff       	call   100481 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100d73:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d77:	74 10                	je     100d89 <mem_check+0x1e0>
  100d79:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d7c:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100d7f:	74 08                	je     100d89 <mem_check+0x1e0>
  100d81:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d84:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d87:	75 24                	jne    100dad <mem_check+0x204>
  100d89:	c7 44 24 0c 94 7e 10 	movl   $0x107e94,0xc(%esp)
  100d90:	00 
  100d91:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100d98:	00 
  100d99:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  100da0:	00 
  100da1:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100da8:	e8 d4 f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100dad:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100db0:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  100db5:	89 d1                	mov    %edx,%ecx
  100db7:	29 c1                	sub    %eax,%ecx
  100db9:	89 c8                	mov    %ecx,%eax
  100dbb:	c1 f8 03             	sar    $0x3,%eax
  100dbe:	c1 e0 0c             	shl    $0xc,%eax
  100dc1:	8b 15 04 dd 11 00    	mov    0x11dd04,%edx
  100dc7:	c1 e2 0c             	shl    $0xc,%edx
  100dca:	39 d0                	cmp    %edx,%eax
  100dcc:	72 24                	jb     100df2 <mem_check+0x249>
  100dce:	c7 44 24 0c b4 7e 10 	movl   $0x107eb4,0xc(%esp)
  100dd5:	00 
  100dd6:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100ddd:	00 
  100dde:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  100de5:	00 
  100de6:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100ded:	e8 8f f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100df2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100df5:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  100dfa:	89 d1                	mov    %edx,%ecx
  100dfc:	29 c1                	sub    %eax,%ecx
  100dfe:	89 c8                	mov    %ecx,%eax
  100e00:	c1 f8 03             	sar    $0x3,%eax
  100e03:	c1 e0 0c             	shl    $0xc,%eax
  100e06:	8b 15 04 dd 11 00    	mov    0x11dd04,%edx
  100e0c:	c1 e2 0c             	shl    $0xc,%edx
  100e0f:	39 d0                	cmp    %edx,%eax
  100e11:	72 24                	jb     100e37 <mem_check+0x28e>
  100e13:	c7 44 24 0c dc 7e 10 	movl   $0x107edc,0xc(%esp)
  100e1a:	00 
  100e1b:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100e22:	00 
  100e23:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  100e2a:	00 
  100e2b:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100e32:	e8 4a f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100e37:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100e3a:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  100e3f:	89 d1                	mov    %edx,%ecx
  100e41:	29 c1                	sub    %eax,%ecx
  100e43:	89 c8                	mov    %ecx,%eax
  100e45:	c1 f8 03             	sar    $0x3,%eax
  100e48:	c1 e0 0c             	shl    $0xc,%eax
  100e4b:	8b 15 04 dd 11 00    	mov    0x11dd04,%edx
  100e51:	c1 e2 0c             	shl    $0xc,%edx
  100e54:	39 d0                	cmp    %edx,%eax
  100e56:	72 24                	jb     100e7c <mem_check+0x2d3>
  100e58:	c7 44 24 0c 04 7f 10 	movl   $0x107f04,0xc(%esp)
  100e5f:	00 
  100e60:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100e67:	00 
  100e68:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  100e6f:	00 
  100e70:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100e77:	e8 05 f6 ff ff       	call   100481 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100e7c:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  100e81:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100e84:	c7 05 00 dd 11 00 00 	movl   $0x0,0x11dd00
  100e8b:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100e8e:	e8 7a fc ff ff       	call   100b0d <mem_alloc>
  100e93:	85 c0                	test   %eax,%eax
  100e95:	74 24                	je     100ebb <mem_check+0x312>
  100e97:	c7 44 24 0c 2a 7f 10 	movl   $0x107f2a,0xc(%esp)
  100e9e:	00 
  100e9f:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100ea6:	00 
  100ea7:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  100eae:	00 
  100eaf:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100eb6:	e8 c6 f5 ff ff       	call   100481 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100ebb:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100ebe:	89 04 24             	mov    %eax,(%esp)
  100ec1:	e8 8e fc ff ff       	call   100b54 <mem_free>
        mem_free(pp1);
  100ec6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100ec9:	89 04 24             	mov    %eax,(%esp)
  100ecc:	e8 83 fc ff ff       	call   100b54 <mem_free>
        mem_free(pp2);
  100ed1:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ed4:	89 04 24             	mov    %eax,(%esp)
  100ed7:	e8 78 fc ff ff       	call   100b54 <mem_free>
	pp0 = pp1 = pp2 = 0;
  100edc:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100ee3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ee6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100ee9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100eec:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100eef:	e8 19 fc ff ff       	call   100b0d <mem_alloc>
  100ef4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100ef7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100efb:	75 24                	jne    100f21 <mem_check+0x378>
  100efd:	c7 44 24 0c 63 7e 10 	movl   $0x107e63,0xc(%esp)
  100f04:	00 
  100f05:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100f0c:	00 
  100f0d:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  100f14:	00 
  100f15:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100f1c:	e8 60 f5 ff ff       	call   100481 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100f21:	e8 e7 fb ff ff       	call   100b0d <mem_alloc>
  100f26:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100f29:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100f2d:	75 24                	jne    100f53 <mem_check+0x3aa>
  100f2f:	c7 44 24 0c 6c 7e 10 	movl   $0x107e6c,0xc(%esp)
  100f36:	00 
  100f37:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100f3e:	00 
  100f3f:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  100f46:	00 
  100f47:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100f4e:	e8 2e f5 ff ff       	call   100481 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100f53:	e8 b5 fb ff ff       	call   100b0d <mem_alloc>
  100f58:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100f5b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f5f:	75 24                	jne    100f85 <mem_check+0x3dc>
  100f61:	c7 44 24 0c 75 7e 10 	movl   $0x107e75,0xc(%esp)
  100f68:	00 
  100f69:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100f70:	00 
  100f71:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  100f78:	00 
  100f79:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100f80:	e8 fc f4 ff ff       	call   100481 <debug_panic>
	assert(pp0);
  100f85:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100f89:	75 24                	jne    100faf <mem_check+0x406>
  100f8b:	c7 44 24 0c 7e 7e 10 	movl   $0x107e7e,0xc(%esp)
  100f92:	00 
  100f93:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100f9a:	00 
  100f9b:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  100fa2:	00 
  100fa3:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100faa:	e8 d2 f4 ff ff       	call   100481 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100faf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100fb3:	74 08                	je     100fbd <mem_check+0x414>
  100fb5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100fb8:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100fbb:	75 24                	jne    100fe1 <mem_check+0x438>
  100fbd:	c7 44 24 0c 82 7e 10 	movl   $0x107e82,0xc(%esp)
  100fc4:	00 
  100fc5:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  100fcc:	00 
  100fcd:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  100fd4:	00 
  100fd5:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  100fdc:	e8 a0 f4 ff ff       	call   100481 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100fe1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100fe5:	74 10                	je     100ff7 <mem_check+0x44e>
  100fe7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100fea:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100fed:	74 08                	je     100ff7 <mem_check+0x44e>
  100fef:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ff2:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100ff5:	75 24                	jne    10101b <mem_check+0x472>
  100ff7:	c7 44 24 0c 94 7e 10 	movl   $0x107e94,0xc(%esp)
  100ffe:	00 
  100fff:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  101006:	00 
  101007:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  10100e:	00 
  10100f:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  101016:	e8 66 f4 ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == 0);
  10101b:	e8 ed fa ff ff       	call   100b0d <mem_alloc>
  101020:	85 c0                	test   %eax,%eax
  101022:	74 24                	je     101048 <mem_check+0x49f>
  101024:	c7 44 24 0c 2a 7f 10 	movl   $0x107f2a,0xc(%esp)
  10102b:	00 
  10102c:	c7 44 24 08 72 7d 10 	movl   $0x107d72,0x8(%esp)
  101033:	00 
  101034:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  10103b:	00 
  10103c:	c7 04 24 94 7d 10 00 	movl   $0x107d94,(%esp)
  101043:	e8 39 f4 ff ff       	call   100481 <debug_panic>

	// give free list back
	mem_freelist = fl;
  101048:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10104b:	a3 00 dd 11 00       	mov    %eax,0x11dd00

	// free the pages we took
	mem_free(pp0);
  101050:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101053:	89 04 24             	mov    %eax,(%esp)
  101056:	e8 f9 fa ff ff       	call   100b54 <mem_free>
	mem_free(pp1);
  10105b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10105e:	89 04 24             	mov    %eax,(%esp)
  101061:	e8 ee fa ff ff       	call   100b54 <mem_free>
	mem_free(pp2);
  101066:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101069:	89 04 24             	mov    %eax,(%esp)
  10106c:	e8 e3 fa ff ff       	call   100b54 <mem_free>

	cprintf("mem_check() succeeded!\n");
  101071:	c7 04 24 3b 7f 10 00 	movl   $0x107f3b,(%esp)
  101078:	e8 05 64 00 00       	call   107482 <cprintf>
}
  10107d:	c9                   	leave  
  10107e:	c3                   	ret    

0010107f <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10107f:	55                   	push   %ebp
  101080:	89 e5                	mov    %esp,%ebp
  101082:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101085:	8b 55 08             	mov    0x8(%ebp),%edx
  101088:	8b 45 0c             	mov    0xc(%ebp),%eax
  10108b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10108e:	f0 87 02             	lock xchg %eax,(%edx)
  101091:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  101094:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101097:	c9                   	leave  
  101098:	c3                   	ret    

00101099 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101099:	55                   	push   %ebp
  10109a:	89 e5                	mov    %esp,%ebp
  10109c:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10109f:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1010a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1010a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1010a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010ab:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1010b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1010b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1010b6:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1010bc:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1010c1:	74 24                	je     1010e7 <cpu_cur+0x4e>
  1010c3:	c7 44 24 0c 53 7f 10 	movl   $0x107f53,0xc(%esp)
  1010ca:	00 
  1010cb:	c7 44 24 08 69 7f 10 	movl   $0x107f69,0x8(%esp)
  1010d2:	00 
  1010d3:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1010da:	00 
  1010db:	c7 04 24 7e 7f 10 00 	movl   $0x107f7e,(%esp)
  1010e2:	e8 9a f3 ff ff       	call   100481 <debug_panic>
	return c;
  1010e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1010ea:	c9                   	leave  
  1010eb:	c3                   	ret    

001010ec <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1010ec:	55                   	push   %ebp
  1010ed:	89 e5                	mov    %esp,%ebp
  1010ef:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1010f2:	e8 a2 ff ff ff       	call   101099 <cpu_cur>
  1010f7:	3d 00 a0 10 00       	cmp    $0x10a000,%eax
  1010fc:	0f 94 c0             	sete   %al
  1010ff:	0f b6 c0             	movzbl %al,%eax
}
  101102:	c9                   	leave  
  101103:	c3                   	ret    

00101104 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  101104:	55                   	push   %ebp
  101105:	89 e5                	mov    %esp,%ebp
  101107:	53                   	push   %ebx
  101108:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  10110b:	e8 89 ff ff ff       	call   101099 <cpu_cur>
  101110:	89 45 f0             	mov    %eax,-0x10(%ebp)

	c->tss.ts_ss0 = CPU_GDT_KDATA;
  101113:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101116:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)
	c->tss.ts_esp0 = (uintptr_t)c->kstackhi; 
  10111c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10111f:	05 00 10 00 00       	add    $0x1000,%eax
  101124:	89 c2                	mov    %eax,%edx
  101126:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101129:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->gdt[CPU_GDT_TSS>>3] = SEGDESC16(0, STS_T32A, (uintptr_t)(&c->tss), sizeof(c->tss) - 1, 0);
  10112c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10112f:	83 c0 38             	add    $0x38,%eax
  101132:	89 c3                	mov    %eax,%ebx
  101134:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101137:	83 c0 38             	add    $0x38,%eax
  10113a:	c1 e8 10             	shr    $0x10,%eax
  10113d:	89 c1                	mov    %eax,%ecx
  10113f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101142:	83 c0 38             	add    $0x38,%eax
  101145:	c1 e8 18             	shr    $0x18,%eax
  101148:	89 c2                	mov    %eax,%edx
  10114a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10114d:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  101153:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101156:	66 89 58 32          	mov    %bx,0x32(%eax)
  10115a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10115d:	88 48 34             	mov    %cl,0x34(%eax)
  101160:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101163:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101167:	83 e1 f0             	and    $0xfffffff0,%ecx
  10116a:	83 c9 09             	or     $0x9,%ecx
  10116d:	88 48 35             	mov    %cl,0x35(%eax)
  101170:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101173:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101177:	83 e1 ef             	and    $0xffffffef,%ecx
  10117a:	88 48 35             	mov    %cl,0x35(%eax)
  10117d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101180:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101184:	83 e1 9f             	and    $0xffffff9f,%ecx
  101187:	88 48 35             	mov    %cl,0x35(%eax)
  10118a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10118d:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101191:	83 c9 80             	or     $0xffffff80,%ecx
  101194:	88 48 35             	mov    %cl,0x35(%eax)
  101197:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10119a:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10119e:	83 e1 f0             	and    $0xfffffff0,%ecx
  1011a1:	88 48 36             	mov    %cl,0x36(%eax)
  1011a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011a7:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1011ab:	83 e1 ef             	and    $0xffffffef,%ecx
  1011ae:	88 48 36             	mov    %cl,0x36(%eax)
  1011b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011b4:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1011b8:	83 e1 df             	and    $0xffffffdf,%ecx
  1011bb:	88 48 36             	mov    %cl,0x36(%eax)
  1011be:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011c1:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1011c5:	83 c9 40             	or     $0x40,%ecx
  1011c8:	88 48 36             	mov    %cl,0x36(%eax)
  1011cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011ce:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1011d2:	83 e1 7f             	and    $0x7f,%ecx
  1011d5:	88 48 36             	mov    %cl,0x36(%eax)
  1011d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011db:	88 50 37             	mov    %dl,0x37(%eax)


	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  1011de:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011e1:	66 c7 45 ea 37 00    	movw   $0x37,-0x16(%ebp)
  1011e7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  1011ea:	0f 01 55 ea          	lgdtl  -0x16(%ebp)
  1011ee:	66 c7 45 f6 30 00    	movw   $0x30,-0xa(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1011f4:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  1011f8:	0f 00 d8             	ltr    %ax
	ltr(CPU_GDT_TSS);
	
	// Reload all segment registers.
	//asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
	//asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1011fb:	b8 10 00 00 00       	mov    $0x10,%eax
  101200:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  101202:	b8 10 00 00 00       	mov    $0x10,%eax
  101207:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  101209:	b8 10 00 00 00       	mov    $0x10,%eax
  10120e:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  101210:	ea 17 12 10 00 08 00 	ljmp   $0x8,$0x101217

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  101217:	b8 00 00 00 00       	mov    $0x0,%eax
  10121c:	0f 00 d0             	lldt   %ax
}
  10121f:	83 c4 14             	add    $0x14,%esp
  101222:	5b                   	pop    %ebx
  101223:	5d                   	pop    %ebp
  101224:	c3                   	ret    

00101225 <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  101225:	55                   	push   %ebp
  101226:	89 e5                	mov    %esp,%ebp
  101228:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  10122b:	e8 dd f8 ff ff       	call   100b0d <mem_alloc>
  101230:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  101233:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101237:	75 24                	jne    10125d <cpu_alloc+0x38>
  101239:	c7 44 24 0c 8b 7f 10 	movl   $0x107f8b,0xc(%esp)
  101240:	00 
  101241:	c7 44 24 08 69 7f 10 	movl   $0x107f69,0x8(%esp)
  101248:	00 
  101249:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  101250:	00 
  101251:	c7 04 24 93 7f 10 00 	movl   $0x107f93,(%esp)
  101258:	e8 24 f2 ff ff       	call   100481 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  10125d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101260:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  101265:	89 d1                	mov    %edx,%ecx
  101267:	29 c1                	sub    %eax,%ecx
  101269:	89 c8                	mov    %ecx,%eax
  10126b:	c1 f8 03             	sar    $0x3,%eax
  10126e:	c1 e0 0c             	shl    $0xc,%eax
  101271:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  101274:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10127b:	00 
  10127c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101283:	00 
  101284:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101287:	89 04 24             	mov    %eax,(%esp)
  10128a:	e8 d8 63 00 00       	call   107667 <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  10128f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101292:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101299:	00 
  10129a:	c7 44 24 04 00 a0 10 	movl   $0x10a000,0x4(%esp)
  1012a1:	00 
  1012a2:	89 04 24             	mov    %eax,(%esp)
  1012a5:	e8 31 64 00 00       	call   1076db <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  1012aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012ad:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  1012b4:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  1012b7:	a1 00 b0 10 00       	mov    0x10b000,%eax
  1012bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1012bf:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  1012c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012c4:	05 a8 00 00 00       	add    $0xa8,%eax
  1012c9:	a3 00 b0 10 00       	mov    %eax,0x10b000

	return c;
  1012ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1012d1:	c9                   	leave  
  1012d2:	c3                   	ret    

001012d3 <cpu_bootothers>:

void
cpu_bootothers(void)
{
  1012d3:	55                   	push   %ebp
  1012d4:	89 e5                	mov    %esp,%ebp
  1012d6:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  1012d9:	e8 0e fe ff ff       	call   1010ec <cpu_onboot>
  1012de:	85 c0                	test   %eax,%eax
  1012e0:	75 1f                	jne    101301 <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  1012e2:	e8 b2 fd ff ff       	call   101099 <cpu_cur>
  1012e7:	05 b0 00 00 00       	add    $0xb0,%eax
  1012ec:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1012f3:	00 
  1012f4:	89 04 24             	mov    %eax,(%esp)
  1012f7:	e8 83 fd ff ff       	call   10107f <xchg>
		return;
  1012fc:	e9 91 00 00 00       	jmp    101392 <cpu_bootothers+0xbf>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  101301:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  101308:	b8 6a 00 00 00       	mov    $0x6a,%eax
  10130d:	89 44 24 08          	mov    %eax,0x8(%esp)
  101311:	c7 44 24 04 ca 74 11 	movl   $0x1174ca,0x4(%esp)
  101318:	00 
  101319:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10131c:	89 04 24             	mov    %eax,(%esp)
  10131f:	e8 b7 63 00 00       	call   1076db <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  101324:	c7 45 f4 00 a0 10 00 	movl   $0x10a000,-0xc(%ebp)
  10132b:	eb 5f                	jmp    10138c <cpu_bootothers+0xb9>
		if(c == cpu_cur())  // We''ve started already.
  10132d:	e8 67 fd ff ff       	call   101099 <cpu_cur>
  101332:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  101335:	74 48                	je     10137f <cpu_bootothers+0xac>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  101337:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10133a:	83 e8 04             	sub    $0x4,%eax
  10133d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101340:	81 c2 00 10 00 00    	add    $0x1000,%edx
  101346:	89 10                	mov    %edx,(%eax)
		*(void**)(code-8) = init;
  101348:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10134b:	83 e8 08             	sub    $0x8,%eax
  10134e:	c7 00 91 00 10 00    	movl   $0x100091,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  101354:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101357:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10135a:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  101361:	0f b6 c0             	movzbl %al,%eax
  101364:	89 54 24 04          	mov    %edx,0x4(%esp)
  101368:	89 04 24             	mov    %eax,(%esp)
  10136b:	e8 09 57 00 00       	call   106a79 <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  101370:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101373:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  101379:	85 c0                	test   %eax,%eax
  10137b:	74 f3                	je     101370 <cpu_bootothers+0x9d>
  10137d:	eb 01                	jmp    101380 <cpu_bootothers+0xad>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
		if(c == cpu_cur())  // We''ve started already.
			continue;
  10137f:	90                   	nop
	uint8_t *code = (uint8_t*)0x1000;
	memmove(code, _binary_obj_boot_bootother_start,
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  101380:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101383:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101389:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10138c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101390:	75 9b                	jne    10132d <cpu_bootothers+0x5a>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
			;
	}
}
  101392:	c9                   	leave  
  101393:	c3                   	ret    

00101394 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101394:	55                   	push   %ebp
  101395:	89 e5                	mov    %esp,%ebp
  101397:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10139a:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10139d:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1013a0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1013a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1013a6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1013ab:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1013ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1013b1:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1013b7:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1013bc:	74 24                	je     1013e2 <cpu_cur+0x4e>
  1013be:	c7 44 24 0c a0 7f 10 	movl   $0x107fa0,0xc(%esp)
  1013c5:	00 
  1013c6:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  1013cd:	00 
  1013ce:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1013d5:	00 
  1013d6:	c7 04 24 cb 7f 10 00 	movl   $0x107fcb,(%esp)
  1013dd:	e8 9f f0 ff ff       	call   100481 <debug_panic>
	return c;
  1013e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1013e5:	c9                   	leave  
  1013e6:	c3                   	ret    

001013e7 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1013e7:	55                   	push   %ebp
  1013e8:	89 e5                	mov    %esp,%ebp
  1013ea:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1013ed:	e8 a2 ff ff ff       	call   101394 <cpu_cur>
  1013f2:	3d 00 a0 10 00       	cmp    $0x10a000,%eax
  1013f7:	0f 94 c0             	sete   %al
  1013fa:	0f b6 c0             	movzbl %al,%eax
}
  1013fd:	c9                   	leave  
  1013fe:	c3                   	ret    

001013ff <trap_init_idt>:

extern uint32_t vectors[];

static void
trap_init_idt(void)
{
  1013ff:	55                   	push   %ebp
  101400:	89 e5                	mov    %esp,%ebp
  101402:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  101405:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  10140c:	e9 bc 00 00 00       	jmp    1014cd <trap_init_idt+0xce>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
  101411:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101414:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101417:	8b 14 95 10 b0 10 00 	mov    0x10b010(,%edx,4),%edx
  10141e:	66 89 14 c5 20 92 11 	mov    %dx,0x119220(,%eax,8)
  101425:	00 
  101426:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101429:	66 c7 04 c5 22 92 11 	movw   $0x8,0x119222(,%eax,8)
  101430:	00 08 00 
  101433:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101436:	0f b6 14 c5 24 92 11 	movzbl 0x119224(,%eax,8),%edx
  10143d:	00 
  10143e:	83 e2 e0             	and    $0xffffffe0,%edx
  101441:	88 14 c5 24 92 11 00 	mov    %dl,0x119224(,%eax,8)
  101448:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10144b:	0f b6 14 c5 24 92 11 	movzbl 0x119224(,%eax,8),%edx
  101452:	00 
  101453:	83 e2 1f             	and    $0x1f,%edx
  101456:	88 14 c5 24 92 11 00 	mov    %dl,0x119224(,%eax,8)
  10145d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101460:	0f b6 14 c5 25 92 11 	movzbl 0x119225(,%eax,8),%edx
  101467:	00 
  101468:	83 ca 0f             	or     $0xf,%edx
  10146b:	88 14 c5 25 92 11 00 	mov    %dl,0x119225(,%eax,8)
  101472:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101475:	0f b6 14 c5 25 92 11 	movzbl 0x119225(,%eax,8),%edx
  10147c:	00 
  10147d:	83 e2 ef             	and    $0xffffffef,%edx
  101480:	88 14 c5 25 92 11 00 	mov    %dl,0x119225(,%eax,8)
  101487:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10148a:	0f b6 14 c5 25 92 11 	movzbl 0x119225(,%eax,8),%edx
  101491:	00 
  101492:	83 ca 60             	or     $0x60,%edx
  101495:	88 14 c5 25 92 11 00 	mov    %dl,0x119225(,%eax,8)
  10149c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10149f:	0f b6 14 c5 25 92 11 	movzbl 0x119225(,%eax,8),%edx
  1014a6:	00 
  1014a7:	83 ca 80             	or     $0xffffff80,%edx
  1014aa:	88 14 c5 25 92 11 00 	mov    %dl,0x119225(,%eax,8)
  1014b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1014b4:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1014b7:	8b 14 95 10 b0 10 00 	mov    0x10b010(,%edx,4),%edx
  1014be:	c1 ea 10             	shr    $0x10,%edx
  1014c1:	66 89 14 c5 26 92 11 	mov    %dx,0x119226(,%eax,8)
  1014c8:	00 
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  1014c9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1014cd:	83 7d fc 13          	cmpl   $0x13,-0x4(%ebp)
  1014d1:	0f 8e 3a ff ff ff    	jle    101411 <trap_init_idt+0x12>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
	}
	SETGATE(idt[T_SECEV], 1, CPU_GDT_KCODE, vectors[T_SECEV], 3);
  1014d7:	a1 88 b0 10 00       	mov    0x10b088,%eax
  1014dc:	66 a3 10 93 11 00    	mov    %ax,0x119310
  1014e2:	66 c7 05 12 93 11 00 	movw   $0x8,0x119312
  1014e9:	08 00 
  1014eb:	0f b6 05 14 93 11 00 	movzbl 0x119314,%eax
  1014f2:	83 e0 e0             	and    $0xffffffe0,%eax
  1014f5:	a2 14 93 11 00       	mov    %al,0x119314
  1014fa:	0f b6 05 14 93 11 00 	movzbl 0x119314,%eax
  101501:	83 e0 1f             	and    $0x1f,%eax
  101504:	a2 14 93 11 00       	mov    %al,0x119314
  101509:	0f b6 05 15 93 11 00 	movzbl 0x119315,%eax
  101510:	83 c8 0f             	or     $0xf,%eax
  101513:	a2 15 93 11 00       	mov    %al,0x119315
  101518:	0f b6 05 15 93 11 00 	movzbl 0x119315,%eax
  10151f:	83 e0 ef             	and    $0xffffffef,%eax
  101522:	a2 15 93 11 00       	mov    %al,0x119315
  101527:	0f b6 05 15 93 11 00 	movzbl 0x119315,%eax
  10152e:	83 c8 60             	or     $0x60,%eax
  101531:	a2 15 93 11 00       	mov    %al,0x119315
  101536:	0f b6 05 15 93 11 00 	movzbl 0x119315,%eax
  10153d:	83 c8 80             	or     $0xffffff80,%eax
  101540:	a2 15 93 11 00       	mov    %al,0x119315
  101545:	a1 88 b0 10 00       	mov    0x10b088,%eax
  10154a:	c1 e8 10             	shr    $0x10,%eax
  10154d:	66 a3 16 93 11 00    	mov    %ax,0x119316
	SETGATE(idt[T_SYSCALL], 1, CPU_GDT_KCODE, vectors[T_SYSCALL], 3);
  101553:	a1 d0 b0 10 00       	mov    0x10b0d0,%eax
  101558:	66 a3 a0 93 11 00    	mov    %ax,0x1193a0
  10155e:	66 c7 05 a2 93 11 00 	movw   $0x8,0x1193a2
  101565:	08 00 
  101567:	0f b6 05 a4 93 11 00 	movzbl 0x1193a4,%eax
  10156e:	83 e0 e0             	and    $0xffffffe0,%eax
  101571:	a2 a4 93 11 00       	mov    %al,0x1193a4
  101576:	0f b6 05 a4 93 11 00 	movzbl 0x1193a4,%eax
  10157d:	83 e0 1f             	and    $0x1f,%eax
  101580:	a2 a4 93 11 00       	mov    %al,0x1193a4
  101585:	0f b6 05 a5 93 11 00 	movzbl 0x1193a5,%eax
  10158c:	83 c8 0f             	or     $0xf,%eax
  10158f:	a2 a5 93 11 00       	mov    %al,0x1193a5
  101594:	0f b6 05 a5 93 11 00 	movzbl 0x1193a5,%eax
  10159b:	83 e0 ef             	and    $0xffffffef,%eax
  10159e:	a2 a5 93 11 00       	mov    %al,0x1193a5
  1015a3:	0f b6 05 a5 93 11 00 	movzbl 0x1193a5,%eax
  1015aa:	83 c8 60             	or     $0x60,%eax
  1015ad:	a2 a5 93 11 00       	mov    %al,0x1193a5
  1015b2:	0f b6 05 a5 93 11 00 	movzbl 0x1193a5,%eax
  1015b9:	83 c8 80             	or     $0xffffff80,%eax
  1015bc:	a2 a5 93 11 00       	mov    %al,0x1193a5
  1015c1:	a1 d0 b0 10 00       	mov    0x10b0d0,%eax
  1015c6:	c1 e8 10             	shr    $0x10,%eax
  1015c9:	66 a3 a6 93 11 00    	mov    %ax,0x1193a6
	SETGATE(idt[T_LTIMER], 1, CPU_GDT_KCODE, vectors[T_LTIMER], 3);
  1015cf:	a1 d4 b0 10 00       	mov    0x10b0d4,%eax
  1015d4:	66 a3 a8 93 11 00    	mov    %ax,0x1193a8
  1015da:	66 c7 05 aa 93 11 00 	movw   $0x8,0x1193aa
  1015e1:	08 00 
  1015e3:	0f b6 05 ac 93 11 00 	movzbl 0x1193ac,%eax
  1015ea:	83 e0 e0             	and    $0xffffffe0,%eax
  1015ed:	a2 ac 93 11 00       	mov    %al,0x1193ac
  1015f2:	0f b6 05 ac 93 11 00 	movzbl 0x1193ac,%eax
  1015f9:	83 e0 1f             	and    $0x1f,%eax
  1015fc:	a2 ac 93 11 00       	mov    %al,0x1193ac
  101601:	0f b6 05 ad 93 11 00 	movzbl 0x1193ad,%eax
  101608:	83 c8 0f             	or     $0xf,%eax
  10160b:	a2 ad 93 11 00       	mov    %al,0x1193ad
  101610:	0f b6 05 ad 93 11 00 	movzbl 0x1193ad,%eax
  101617:	83 e0 ef             	and    $0xffffffef,%eax
  10161a:	a2 ad 93 11 00       	mov    %al,0x1193ad
  10161f:	0f b6 05 ad 93 11 00 	movzbl 0x1193ad,%eax
  101626:	83 c8 60             	or     $0x60,%eax
  101629:	a2 ad 93 11 00       	mov    %al,0x1193ad
  10162e:	0f b6 05 ad 93 11 00 	movzbl 0x1193ad,%eax
  101635:	83 c8 80             	or     $0xffffff80,%eax
  101638:	a2 ad 93 11 00       	mov    %al,0x1193ad
  10163d:	a1 d4 b0 10 00       	mov    0x10b0d4,%eax
  101642:	c1 e8 10             	shr    $0x10,%eax
  101645:	66 a3 ae 93 11 00    	mov    %ax,0x1193ae
}
  10164b:	c9                   	leave  
  10164c:	c3                   	ret    

0010164d <trap_init>:

void
trap_init(void)
{
  10164d:	55                   	push   %ebp
  10164e:	89 e5                	mov    %esp,%ebp
  101650:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  101653:	e8 8f fd ff ff       	call   1013e7 <cpu_onboot>
  101658:	85 c0                	test   %eax,%eax
  10165a:	74 05                	je     101661 <trap_init+0x14>
		trap_init_idt();
  10165c:	e8 9e fd ff ff       	call   1013ff <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  101661:	0f 01 1d 04 b0 10 00 	lidtl  0x10b004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  101668:	e8 7a fd ff ff       	call   1013e7 <cpu_onboot>
  10166d:	85 c0                	test   %eax,%eax
  10166f:	74 05                	je     101676 <trap_init+0x29>
		trap_check_kernel();
  101671:	e8 c1 02 00 00       	call   101937 <trap_check_kernel>
}
  101676:	c9                   	leave  
  101677:	c3                   	ret    

00101678 <trap_name>:

const char *trap_name(int trapno)
{
  101678:	55                   	push   %ebp
  101679:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  10167b:	8b 45 08             	mov    0x8(%ebp),%eax
  10167e:	83 f8 13             	cmp    $0x13,%eax
  101681:	77 0c                	ja     10168f <trap_name+0x17>
		return excnames[trapno];
  101683:	8b 45 08             	mov    0x8(%ebp),%eax
  101686:	8b 04 85 e0 83 10 00 	mov    0x1083e0(,%eax,4),%eax
  10168d:	eb 25                	jmp    1016b4 <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  10168f:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  101693:	75 07                	jne    10169c <trap_name+0x24>
		return "System call";
  101695:	b8 d8 7f 10 00       	mov    $0x107fd8,%eax
  10169a:	eb 18                	jmp    1016b4 <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  10169c:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  1016a0:	7e 0d                	jle    1016af <trap_name+0x37>
  1016a2:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  1016a6:	7f 07                	jg     1016af <trap_name+0x37>
		return "Hardware Interrupt";
  1016a8:	b8 e4 7f 10 00       	mov    $0x107fe4,%eax
  1016ad:	eb 05                	jmp    1016b4 <trap_name+0x3c>
	return "(unknown trap)";
  1016af:	b8 f7 7f 10 00       	mov    $0x107ff7,%eax
}
  1016b4:	5d                   	pop    %ebp
  1016b5:	c3                   	ret    

001016b6 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  1016b6:	55                   	push   %ebp
  1016b7:	89 e5                	mov    %esp,%ebp
  1016b9:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  1016bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1016bf:	8b 00                	mov    (%eax),%eax
  1016c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016c5:	c7 04 24 06 80 10 00 	movl   $0x108006,(%esp)
  1016cc:	e8 b1 5d 00 00       	call   107482 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  1016d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1016d4:	8b 40 04             	mov    0x4(%eax),%eax
  1016d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016db:	c7 04 24 15 80 10 00 	movl   $0x108015,(%esp)
  1016e2:	e8 9b 5d 00 00       	call   107482 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  1016e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1016ea:	8b 40 08             	mov    0x8(%eax),%eax
  1016ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016f1:	c7 04 24 24 80 10 00 	movl   $0x108024,(%esp)
  1016f8:	e8 85 5d 00 00       	call   107482 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  1016fd:	8b 45 08             	mov    0x8(%ebp),%eax
  101700:	8b 40 10             	mov    0x10(%eax),%eax
  101703:	89 44 24 04          	mov    %eax,0x4(%esp)
  101707:	c7 04 24 33 80 10 00 	movl   $0x108033,(%esp)
  10170e:	e8 6f 5d 00 00       	call   107482 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101713:	8b 45 08             	mov    0x8(%ebp),%eax
  101716:	8b 40 14             	mov    0x14(%eax),%eax
  101719:	89 44 24 04          	mov    %eax,0x4(%esp)
  10171d:	c7 04 24 42 80 10 00 	movl   $0x108042,(%esp)
  101724:	e8 59 5d 00 00       	call   107482 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101729:	8b 45 08             	mov    0x8(%ebp),%eax
  10172c:	8b 40 18             	mov    0x18(%eax),%eax
  10172f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101733:	c7 04 24 51 80 10 00 	movl   $0x108051,(%esp)
  10173a:	e8 43 5d 00 00       	call   107482 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  10173f:	8b 45 08             	mov    0x8(%ebp),%eax
  101742:	8b 40 1c             	mov    0x1c(%eax),%eax
  101745:	89 44 24 04          	mov    %eax,0x4(%esp)
  101749:	c7 04 24 60 80 10 00 	movl   $0x108060,(%esp)
  101750:	e8 2d 5d 00 00       	call   107482 <cprintf>
}
  101755:	c9                   	leave  
  101756:	c3                   	ret    

00101757 <trap_print>:

void
trap_print(trapframe *tf)
{
  101757:	55                   	push   %ebp
  101758:	89 e5                	mov    %esp,%ebp
  10175a:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  10175d:	8b 45 08             	mov    0x8(%ebp),%eax
  101760:	89 44 24 04          	mov    %eax,0x4(%esp)
  101764:	c7 04 24 6f 80 10 00 	movl   $0x10806f,(%esp)
  10176b:	e8 12 5d 00 00       	call   107482 <cprintf>
	trap_print_regs(&tf->regs);
  101770:	8b 45 08             	mov    0x8(%ebp),%eax
  101773:	89 04 24             	mov    %eax,(%esp)
  101776:	e8 3b ff ff ff       	call   1016b6 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  10177b:	8b 45 08             	mov    0x8(%ebp),%eax
  10177e:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101782:	0f b7 c0             	movzwl %ax,%eax
  101785:	89 44 24 04          	mov    %eax,0x4(%esp)
  101789:	c7 04 24 81 80 10 00 	movl   $0x108081,(%esp)
  101790:	e8 ed 5c 00 00       	call   107482 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101795:	8b 45 08             	mov    0x8(%ebp),%eax
  101798:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10179c:	0f b7 c0             	movzwl %ax,%eax
  10179f:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017a3:	c7 04 24 94 80 10 00 	movl   $0x108094,(%esp)
  1017aa:	e8 d3 5c 00 00       	call   107482 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  1017af:	8b 45 08             	mov    0x8(%ebp),%eax
  1017b2:	8b 40 30             	mov    0x30(%eax),%eax
  1017b5:	89 04 24             	mov    %eax,(%esp)
  1017b8:	e8 bb fe ff ff       	call   101678 <trap_name>
  1017bd:	8b 55 08             	mov    0x8(%ebp),%edx
  1017c0:	8b 52 30             	mov    0x30(%edx),%edx
  1017c3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1017c7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1017cb:	c7 04 24 a7 80 10 00 	movl   $0x1080a7,(%esp)
  1017d2:	e8 ab 5c 00 00       	call   107482 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  1017d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1017da:	8b 40 34             	mov    0x34(%eax),%eax
  1017dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017e1:	c7 04 24 b9 80 10 00 	movl   $0x1080b9,(%esp)
  1017e8:	e8 95 5c 00 00       	call   107482 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1017ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1017f0:	8b 40 38             	mov    0x38(%eax),%eax
  1017f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017f7:	c7 04 24 c8 80 10 00 	movl   $0x1080c8,(%esp)
  1017fe:	e8 7f 5c 00 00       	call   107482 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101803:	8b 45 08             	mov    0x8(%ebp),%eax
  101806:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10180a:	0f b7 c0             	movzwl %ax,%eax
  10180d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101811:	c7 04 24 d7 80 10 00 	movl   $0x1080d7,(%esp)
  101818:	e8 65 5c 00 00       	call   107482 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  10181d:	8b 45 08             	mov    0x8(%ebp),%eax
  101820:	8b 40 40             	mov    0x40(%eax),%eax
  101823:	89 44 24 04          	mov    %eax,0x4(%esp)
  101827:	c7 04 24 ea 80 10 00 	movl   $0x1080ea,(%esp)
  10182e:	e8 4f 5c 00 00       	call   107482 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  101833:	8b 45 08             	mov    0x8(%ebp),%eax
  101836:	8b 40 44             	mov    0x44(%eax),%eax
  101839:	89 44 24 04          	mov    %eax,0x4(%esp)
  10183d:	c7 04 24 f9 80 10 00 	movl   $0x1080f9,(%esp)
  101844:	e8 39 5c 00 00       	call   107482 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  101849:	8b 45 08             	mov    0x8(%ebp),%eax
  10184c:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101850:	0f b7 c0             	movzwl %ax,%eax
  101853:	89 44 24 04          	mov    %eax,0x4(%esp)
  101857:	c7 04 24 08 81 10 00 	movl   $0x108108,(%esp)
  10185e:	e8 1f 5c 00 00       	call   107482 <cprintf>
}
  101863:	c9                   	leave  
  101864:	c3                   	ret    

00101865 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  101865:	55                   	push   %ebp
  101866:	89 e5                	mov    %esp,%ebp
  101868:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  10186b:	fc                   	cld    

// Disable external device interrupts.
static gcc_inline void
cli(void)
{
	asm volatile("cli");
  10186c:	fa                   	cli    
	cli();

	//cprintf("process %p is in trap(), trapno == %d\n", proc_cur(), tf->trapno);

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  10186d:	e8 22 fb ff ff       	call   101394 <cpu_cur>
  101872:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover){
  101875:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101878:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10187e:	85 c0                	test   %eax,%eax
  101880:	74 1e                	je     1018a0 <trap+0x3b>
		//cprintf("before c->recover()\n");
		c->recover(tf, c->recoverdata);}
  101882:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101885:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  10188b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10188e:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  101894:	89 44 24 04          	mov    %eax,0x4(%esp)
  101898:	8b 45 08             	mov    0x8(%ebp),%eax
  10189b:	89 04 24             	mov    %eax,(%esp)
  10189e:	ff d2                	call   *%edx

	// Lab 2: your trap handling code here!
	if(tf->trapno == T_SYSCALL){
  1018a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1018a3:	8b 40 30             	mov    0x30(%eax),%eax
  1018a6:	83 f8 30             	cmp    $0x30,%eax
  1018a9:	75 0b                	jne    1018b6 <trap+0x51>
		syscall(tf);
  1018ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1018ae:	89 04 24             	mov    %eax,(%esp)
  1018b1:	e8 83 23 00 00       	call   103c39 <syscall>
		//panic("unhandler system call\n");
	}

    
	switch(tf->trapno){
  1018b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1018b9:	8b 40 30             	mov    0x30(%eax),%eax
  1018bc:	83 f8 27             	cmp    $0x27,%eax
  1018bf:	74 15                	je     1018d6 <trap+0x71>
  1018c1:	83 f8 31             	cmp    $0x31,%eax
  1018c4:	75 2c                	jne    1018f2 <trap+0x8d>
		case T_LTIMER:
			//cprintf("T_LTIMER proc: 0x%x\n",proc_cur());
			lapic_eoi();
  1018c6:	e8 1f 51 00 00       	call   1069ea <lapic_eoi>
			proc_yield(tf);
  1018cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1018ce:	89 04 24             	mov    %eax,(%esp)
  1018d1:	e8 a6 17 00 00       	call   10307c <proc_yield>
			break;
		case T_IRQ0 + IRQ_SPURIOUS:
			panic(" IRQ_SPURIOUS ");
  1018d6:	c7 44 24 08 1b 81 10 	movl   $0x10811b,0x8(%esp)
  1018dd:	00 
  1018de:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  1018e5:	00 
  1018e6:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  1018ed:	e8 8f eb ff ff       	call   100481 <debug_panic>

		default:
			proc_ret(tf, -1);
  1018f2:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1018f9:	ff 
  1018fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1018fd:	89 04 24             	mov    %eax,(%esp)
  101900:	e8 b5 17 00 00       	call   1030ba <proc_ret>

00101905 <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101905:	55                   	push   %ebp
  101906:	89 e5                	mov    %esp,%ebp
  101908:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  10190b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10190e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101911:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101914:	8b 00                	mov    (%eax),%eax
  101916:	89 c2                	mov    %eax,%edx
  101918:	8b 45 08             	mov    0x8(%ebp),%eax
  10191b:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  10191e:	8b 45 08             	mov    0x8(%ebp),%eax
  101921:	8b 40 30             	mov    0x30(%eax),%eax
  101924:	89 c2                	mov    %eax,%edx
  101926:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101929:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  10192c:	8b 45 08             	mov    0x8(%ebp),%eax
  10192f:	89 04 24             	mov    %eax,(%esp)
  101932:	e8 b9 97 00 00       	call   10b0f0 <trap_return>

00101937 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101937:	55                   	push   %ebp
  101938:	89 e5                	mov    %esp,%ebp
  10193a:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10193d:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  101940:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  101944:	0f b7 c0             	movzwl %ax,%eax
  101947:	83 e0 03             	and    $0x3,%eax
  10194a:	85 c0                	test   %eax,%eax
  10194c:	74 24                	je     101972 <trap_check_kernel+0x3b>
  10194e:	c7 44 24 0c 36 81 10 	movl   $0x108136,0xc(%esp)
  101955:	00 
  101956:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  10195d:	00 
  10195e:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  101965:	00 
  101966:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  10196d:	e8 0f eb ff ff       	call   100481 <debug_panic>

	cpu *c = cpu_cur();
  101972:	e8 1d fa ff ff       	call   101394 <cpu_cur>
  101977:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  10197a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10197d:	c7 80 a0 00 00 00 05 	movl   $0x101905,0xa0(%eax)
  101984:	19 10 00 
	trap_check(&c->recoverdata);
  101987:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10198a:	05 a4 00 00 00       	add    $0xa4,%eax
  10198f:	89 04 24             	mov    %eax,(%esp)
  101992:	e8 96 00 00 00       	call   101a2d <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101997:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10199a:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1019a1:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  1019a4:	c7 04 24 4c 81 10 00 	movl   $0x10814c,(%esp)
  1019ab:	e8 d2 5a 00 00       	call   107482 <cprintf>
}
  1019b0:	c9                   	leave  
  1019b1:	c3                   	ret    

001019b2 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  1019b2:	55                   	push   %ebp
  1019b3:	89 e5                	mov    %esp,%ebp
  1019b5:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1019b8:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  1019bb:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  1019bf:	0f b7 c0             	movzwl %ax,%eax
  1019c2:	83 e0 03             	and    $0x3,%eax
  1019c5:	83 f8 03             	cmp    $0x3,%eax
  1019c8:	74 24                	je     1019ee <trap_check_user+0x3c>
  1019ca:	c7 44 24 0c 6c 81 10 	movl   $0x10816c,0xc(%esp)
  1019d1:	00 
  1019d2:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  1019d9:	00 
  1019da:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  1019e1:	00 
  1019e2:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  1019e9:	e8 93 ea ff ff       	call   100481 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  1019ee:	c7 45 f0 00 a0 10 00 	movl   $0x10a000,-0x10(%ebp)
	c->recover = trap_check_recover;
  1019f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1019f8:	c7 80 a0 00 00 00 05 	movl   $0x101905,0xa0(%eax)
  1019ff:	19 10 00 
	trap_check(&c->recoverdata);
  101a02:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101a05:	05 a4 00 00 00       	add    $0xa4,%eax
  101a0a:	89 04 24             	mov    %eax,(%esp)
  101a0d:	e8 1b 00 00 00       	call   101a2d <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101a12:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101a15:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101a1c:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101a1f:	c7 04 24 81 81 10 00 	movl   $0x108181,(%esp)
  101a26:	e8 57 5a 00 00       	call   107482 <cprintf>
}
  101a2b:	c9                   	leave  
  101a2c:	c3                   	ret    

00101a2d <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  101a2d:	55                   	push   %ebp
  101a2e:	89 e5                	mov    %esp,%ebp
  101a30:	57                   	push   %edi
  101a31:	56                   	push   %esi
  101a32:	53                   	push   %ebx
  101a33:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101a36:	c7 45 dc ce fa ed fe 	movl   $0xfeedface,-0x24(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101a3d:	8b 45 08             	mov    0x8(%ebp),%eax
  101a40:	8d 55 d4             	lea    -0x2c(%ebp),%edx
  101a43:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address or a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  101a45:	c7 45 d4 7c 1a 10 00 	movl   $0x101a7c,-0x2c(%ebp)
	cprintf("1. &args.trapno == %x\n", &args);
  101a4c:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  101a4f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a53:	c7 04 24 9f 81 10 00 	movl   $0x10819f,(%esp)
  101a5a:	e8 23 5a 00 00       	call   107482 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101a5f:	89 65 e0             	mov    %esp,-0x20(%ebp)
        return esp;
  101a62:	8b 45 e0             	mov    -0x20(%ebp),%eax
	cprintf(">>>>>>>>>>in trap_check : esp : 0x%x\n",read_esp());
  101a65:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a69:	c7 04 24 b8 81 10 00 	movl   $0x1081b8,(%esp)
  101a70:	e8 0d 5a 00 00       	call   107482 <cprintf>
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101a75:	b8 00 00 00 00       	mov    $0x0,%eax
  101a7a:	f7 f0                	div    %eax

00101a7c <after_div0>:
	cprintf("2. &args.trapno == %x\n", &args);
  101a7c:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  101a7f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a83:	c7 04 24 de 81 10 00 	movl   $0x1081de,(%esp)
  101a8a:	e8 f3 59 00 00       	call   107482 <cprintf>
	assert(args.trapno == T_DIVIDE);
  101a8f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101a92:	85 c0                	test   %eax,%eax
  101a94:	74 24                	je     101aba <after_div0+0x3e>
  101a96:	c7 44 24 0c f5 81 10 	movl   $0x1081f5,0xc(%esp)
  101a9d:	00 
  101a9e:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  101aa5:	00 
  101aa6:	c7 44 24 04 f9 00 00 	movl   $0xf9,0x4(%esp)
  101aad:	00 
  101aae:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  101ab5:	e8 c7 e9 ff ff       	call   100481 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101aba:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101abd:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101ac2:	74 24                	je     101ae8 <after_div0+0x6c>
  101ac4:	c7 44 24 0c 0d 82 10 	movl   $0x10820d,0xc(%esp)
  101acb:	00 
  101acc:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  101ad3:	00 
  101ad4:	c7 44 24 04 fe 00 00 	movl   $0xfe,0x4(%esp)
  101adb:	00 
  101adc:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  101ae3:	e8 99 e9 ff ff       	call   100481 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101ae8:	c7 45 d4 f0 1a 10 00 	movl   $0x101af0,-0x2c(%ebp)
	asm volatile("int3; after_breakpoint:");
  101aef:	cc                   	int3   

00101af0 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101af0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101af3:	83 f8 03             	cmp    $0x3,%eax
  101af6:	74 24                	je     101b1c <after_breakpoint+0x2c>
  101af8:	c7 44 24 0c 22 82 10 	movl   $0x108222,0xc(%esp)
  101aff:	00 
  101b00:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  101b07:	00 
  101b08:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  101b0f:	00 
  101b10:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  101b17:	e8 65 e9 ff ff       	call   100481 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101b1c:	c7 45 d4 2b 1b 10 00 	movl   $0x101b2b,-0x2c(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101b23:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101b28:	01 c0                	add    %eax,%eax
  101b2a:	ce                   	into   

00101b2b <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101b2b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101b2e:	83 f8 04             	cmp    $0x4,%eax
  101b31:	74 24                	je     101b57 <after_overflow+0x2c>
  101b33:	c7 44 24 0c 39 82 10 	movl   $0x108239,0xc(%esp)
  101b3a:	00 
  101b3b:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  101b42:	00 
  101b43:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
  101b4a:	00 
  101b4b:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  101b52:	e8 2a e9 ff ff       	call   100481 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101b57:	c7 45 d4 74 1b 10 00 	movl   $0x101b74,-0x2c(%ebp)
	int bounds[2] = { 1, 3 };
  101b5e:	c7 45 cc 01 00 00 00 	movl   $0x1,-0x34(%ebp)
  101b65:	c7 45 d0 03 00 00 00 	movl   $0x3,-0x30(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  101b6c:	b8 00 00 00 00       	mov    $0x0,%eax
  101b71:	62 45 cc             	bound  %eax,-0x34(%ebp)

00101b74 <after_bound>:
	assert(args.trapno == T_BOUND);
  101b74:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101b77:	83 f8 05             	cmp    $0x5,%eax
  101b7a:	74 24                	je     101ba0 <after_bound+0x2c>
  101b7c:	c7 44 24 0c 50 82 10 	movl   $0x108250,0xc(%esp)
  101b83:	00 
  101b84:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  101b8b:	00 
  101b8c:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
  101b93:	00 
  101b94:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  101b9b:	e8 e1 e8 ff ff       	call   100481 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  101ba0:	c7 45 d4 a9 1b 10 00 	movl   $0x101ba9,-0x2c(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101ba7:	0f 0b                	ud2    

00101ba9 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101ba9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101bac:	83 f8 06             	cmp    $0x6,%eax
  101baf:	74 24                	je     101bd5 <after_illegal+0x2c>
  101bb1:	c7 44 24 0c 67 82 10 	movl   $0x108267,0xc(%esp)
  101bb8:	00 
  101bb9:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  101bc0:	00 
  101bc1:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
  101bc8:	00 
  101bc9:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  101bd0:	e8 ac e8 ff ff       	call   100481 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101bd5:	c7 45 d4 e3 1b 10 00 	movl   $0x101be3,-0x2c(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101bdc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101be1:	8e e0                	mov    %eax,%fs

00101be3 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101be3:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101be6:	83 f8 0d             	cmp    $0xd,%eax
  101be9:	74 24                	je     101c0f <after_gpfault+0x2c>
  101beb:	c7 44 24 0c 7e 82 10 	movl   $0x10827e,0xc(%esp)
  101bf2:	00 
  101bf3:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  101bfa:	00 
  101bfb:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  101c02:	00 
  101c03:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  101c0a:	e8 72 e8 ff ff       	call   100481 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101c0f:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  101c12:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101c16:	0f b7 c0             	movzwl %ax,%eax
  101c19:	83 e0 03             	and    $0x3,%eax
  101c1c:	85 c0                	test   %eax,%eax
  101c1e:	74 3a                	je     101c5a <after_priv+0x2c>
		args.reip = after_priv;
  101c20:	c7 45 d4 2e 1c 10 00 	movl   $0x101c2e,-0x2c(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101c27:	0f 01 1d 04 b0 10 00 	lidtl  0x10b004

00101c2e <after_priv>:
		assert(args.trapno == T_GPFLT);
  101c2e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101c31:	83 f8 0d             	cmp    $0xd,%eax
  101c34:	74 24                	je     101c5a <after_priv+0x2c>
  101c36:	c7 44 24 0c 7e 82 10 	movl   $0x10827e,0xc(%esp)
  101c3d:	00 
  101c3e:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  101c45:	00 
  101c46:	c7 44 24 04 1e 01 00 	movl   $0x11e,0x4(%esp)
  101c4d:	00 
  101c4e:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  101c55:	e8 27 e8 ff ff       	call   100481 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101c5a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101c5d:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101c62:	74 24                	je     101c88 <after_priv+0x5a>
  101c64:	c7 44 24 0c 0d 82 10 	movl   $0x10820d,0xc(%esp)
  101c6b:	00 
  101c6c:	c7 44 24 08 b6 7f 10 	movl   $0x107fb6,0x8(%esp)
  101c73:	00 
  101c74:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
  101c7b:	00 
  101c7c:	c7 04 24 2a 81 10 00 	movl   $0x10812a,(%esp)
  101c83:	e8 f9 e7 ff ff       	call   100481 <debug_panic>
	//cprintf("sfsfsfsfsfsfsfsfsf\n");
	*argsp = NULL;	// recovery mechanism not needed anymore
  101c88:	8b 45 08             	mov    0x8(%ebp),%eax
  101c8b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101c91:	83 c4 3c             	add    $0x3c,%esp
  101c94:	5b                   	pop    %ebx
  101c95:	5e                   	pop    %esi
  101c96:	5f                   	pop    %edi
  101c97:	5d                   	pop    %ebp
  101c98:	c3                   	ret    
  101c99:	90                   	nop

00101c9a <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  101c9a:	6a 00                	push   $0x0
  101c9c:	6a 00                	push   $0x0
  101c9e:	e9 35 94 00 00       	jmp    10b0d8 <_alltraps>
  101ca3:	90                   	nop

00101ca4 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  101ca4:	6a 00                	push   $0x0
  101ca6:	6a 01                	push   $0x1
  101ca8:	e9 2b 94 00 00       	jmp    10b0d8 <_alltraps>
  101cad:	90                   	nop

00101cae <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  101cae:	6a 00                	push   $0x0
  101cb0:	6a 02                	push   $0x2
  101cb2:	e9 21 94 00 00       	jmp    10b0d8 <_alltraps>
  101cb7:	90                   	nop

00101cb8 <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  101cb8:	6a 00                	push   $0x0
  101cba:	6a 03                	push   $0x3
  101cbc:	e9 17 94 00 00       	jmp    10b0d8 <_alltraps>
  101cc1:	90                   	nop

00101cc2 <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  101cc2:	6a 00                	push   $0x0
  101cc4:	6a 04                	push   $0x4
  101cc6:	e9 0d 94 00 00       	jmp    10b0d8 <_alltraps>
  101ccb:	90                   	nop

00101ccc <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  101ccc:	6a 00                	push   $0x0
  101cce:	6a 05                	push   $0x5
  101cd0:	e9 03 94 00 00       	jmp    10b0d8 <_alltraps>
  101cd5:	90                   	nop

00101cd6 <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  101cd6:	6a 00                	push   $0x0
  101cd8:	6a 06                	push   $0x6
  101cda:	e9 f9 93 00 00       	jmp    10b0d8 <_alltraps>
  101cdf:	90                   	nop

00101ce0 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  101ce0:	6a 00                	push   $0x0
  101ce2:	6a 07                	push   $0x7
  101ce4:	e9 ef 93 00 00       	jmp    10b0d8 <_alltraps>
  101ce9:	90                   	nop

00101cea <vector8>:
TRAPHANDLER(vector8, 8)
  101cea:	6a 08                	push   $0x8
  101cec:	e9 e7 93 00 00       	jmp    10b0d8 <_alltraps>
  101cf1:	90                   	nop

00101cf2 <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  101cf2:	6a 00                	push   $0x0
  101cf4:	6a 09                	push   $0x9
  101cf6:	e9 dd 93 00 00       	jmp    10b0d8 <_alltraps>
  101cfb:	90                   	nop

00101cfc <vector10>:
TRAPHANDLER(vector10, 10)
  101cfc:	6a 0a                	push   $0xa
  101cfe:	e9 d5 93 00 00       	jmp    10b0d8 <_alltraps>
  101d03:	90                   	nop

00101d04 <vector11>:
TRAPHANDLER(vector11, 11)
  101d04:	6a 0b                	push   $0xb
  101d06:	e9 cd 93 00 00       	jmp    10b0d8 <_alltraps>
  101d0b:	90                   	nop

00101d0c <vector12>:
TRAPHANDLER(vector12, 12)
  101d0c:	6a 0c                	push   $0xc
  101d0e:	e9 c5 93 00 00       	jmp    10b0d8 <_alltraps>
  101d13:	90                   	nop

00101d14 <vector13>:
TRAPHANDLER(vector13, 13)
  101d14:	6a 0d                	push   $0xd
  101d16:	e9 bd 93 00 00       	jmp    10b0d8 <_alltraps>
  101d1b:	90                   	nop

00101d1c <vector14>:
TRAPHANDLER(vector14, 14)
  101d1c:	6a 0e                	push   $0xe
  101d1e:	e9 b5 93 00 00       	jmp    10b0d8 <_alltraps>
  101d23:	90                   	nop

00101d24 <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101d24:	6a 00                	push   $0x0
  101d26:	6a 0f                	push   $0xf
  101d28:	e9 ab 93 00 00       	jmp    10b0d8 <_alltraps>
  101d2d:	90                   	nop

00101d2e <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  101d2e:	6a 00                	push   $0x0
  101d30:	6a 10                	push   $0x10
  101d32:	e9 a1 93 00 00       	jmp    10b0d8 <_alltraps>
  101d37:	90                   	nop

00101d38 <vector17>:
TRAPHANDLER(vector17, 17)
  101d38:	6a 11                	push   $0x11
  101d3a:	e9 99 93 00 00       	jmp    10b0d8 <_alltraps>
  101d3f:	90                   	nop

00101d40 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  101d40:	6a 00                	push   $0x0
  101d42:	6a 12                	push   $0x12
  101d44:	e9 8f 93 00 00       	jmp    10b0d8 <_alltraps>
  101d49:	90                   	nop

00101d4a <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  101d4a:	6a 00                	push   $0x0
  101d4c:	6a 13                	push   $0x13
  101d4e:	e9 85 93 00 00       	jmp    10b0d8 <_alltraps>
  101d53:	90                   	nop

00101d54 <vector20>:
TRAPHANDLER_NOEC(vector20, 20)
  101d54:	6a 00                	push   $0x0
  101d56:	6a 14                	push   $0x14
  101d58:	e9 7b 93 00 00       	jmp    10b0d8 <_alltraps>
  101d5d:	90                   	nop

00101d5e <vector21>:
TRAPHANDLER_NOEC(vector21, 21)
  101d5e:	6a 00                	push   $0x0
  101d60:	6a 15                	push   $0x15
  101d62:	e9 71 93 00 00       	jmp    10b0d8 <_alltraps>
  101d67:	90                   	nop

00101d68 <vector22>:
TRAPHANDLER_NOEC(vector22, 22)
  101d68:	6a 00                	push   $0x0
  101d6a:	6a 16                	push   $0x16
  101d6c:	e9 67 93 00 00       	jmp    10b0d8 <_alltraps>
  101d71:	90                   	nop

00101d72 <vector23>:
TRAPHANDLER_NOEC(vector23, 23)
  101d72:	6a 00                	push   $0x0
  101d74:	6a 17                	push   $0x17
  101d76:	e9 5d 93 00 00       	jmp    10b0d8 <_alltraps>
  101d7b:	90                   	nop

00101d7c <vector24>:
TRAPHANDLER_NOEC(vector24, 24)
  101d7c:	6a 00                	push   $0x0
  101d7e:	6a 18                	push   $0x18
  101d80:	e9 53 93 00 00       	jmp    10b0d8 <_alltraps>
  101d85:	90                   	nop

00101d86 <vector25>:
TRAPHANDLER_NOEC(vector25, 25)
  101d86:	6a 00                	push   $0x0
  101d88:	6a 19                	push   $0x19
  101d8a:	e9 49 93 00 00       	jmp    10b0d8 <_alltraps>
  101d8f:	90                   	nop

00101d90 <vector26>:
TRAPHANDLER_NOEC(vector26, 26)
  101d90:	6a 00                	push   $0x0
  101d92:	6a 1a                	push   $0x1a
  101d94:	e9 3f 93 00 00       	jmp    10b0d8 <_alltraps>
  101d99:	90                   	nop

00101d9a <vector27>:
TRAPHANDLER_NOEC(vector27, 27)
  101d9a:	6a 00                	push   $0x0
  101d9c:	6a 1b                	push   $0x1b
  101d9e:	e9 35 93 00 00       	jmp    10b0d8 <_alltraps>
  101da3:	90                   	nop

00101da4 <vector28>:
TRAPHANDLER_NOEC(vector28, 28)
  101da4:	6a 00                	push   $0x0
  101da6:	6a 1c                	push   $0x1c
  101da8:	e9 2b 93 00 00       	jmp    10b0d8 <_alltraps>
  101dad:	90                   	nop

00101dae <vector29>:
TRAPHANDLER_NOEC(vector29, 29)
  101dae:	6a 00                	push   $0x0
  101db0:	6a 1d                	push   $0x1d
  101db2:	e9 21 93 00 00       	jmp    10b0d8 <_alltraps>
  101db7:	90                   	nop

00101db8 <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101db8:	6a 00                	push   $0x0
  101dba:	6a 1e                	push   $0x1e
  101dbc:	e9 17 93 00 00       	jmp    10b0d8 <_alltraps>
  101dc1:	90                   	nop

00101dc2 <vector31>:
TRAPHANDLER_NOEC(vector31, 31)
  101dc2:	6a 00                	push   $0x0
  101dc4:	6a 1f                	push   $0x1f
  101dc6:	e9 0d 93 00 00       	jmp    10b0d8 <_alltraps>
  101dcb:	90                   	nop

00101dcc <vector32>:
TRAPHANDLER_NOEC(vector32, 32)
  101dcc:	6a 00                	push   $0x0
  101dce:	6a 20                	push   $0x20
  101dd0:	e9 03 93 00 00       	jmp    10b0d8 <_alltraps>
  101dd5:	90                   	nop

00101dd6 <vector33>:
TRAPHANDLER_NOEC(vector33, 33)
  101dd6:	6a 00                	push   $0x0
  101dd8:	6a 21                	push   $0x21
  101dda:	e9 f9 92 00 00       	jmp    10b0d8 <_alltraps>
  101ddf:	90                   	nop

00101de0 <vector34>:
TRAPHANDLER_NOEC(vector34, 34)
  101de0:	6a 00                	push   $0x0
  101de2:	6a 22                	push   $0x22
  101de4:	e9 ef 92 00 00       	jmp    10b0d8 <_alltraps>
  101de9:	90                   	nop

00101dea <vector35>:
TRAPHANDLER_NOEC(vector35, 35)
  101dea:	6a 00                	push   $0x0
  101dec:	6a 23                	push   $0x23
  101dee:	e9 e5 92 00 00       	jmp    10b0d8 <_alltraps>
  101df3:	90                   	nop

00101df4 <vector36>:
TRAPHANDLER_NOEC(vector36, 36)
  101df4:	6a 00                	push   $0x0
  101df6:	6a 24                	push   $0x24
  101df8:	e9 db 92 00 00       	jmp    10b0d8 <_alltraps>
  101dfd:	90                   	nop

00101dfe <vector37>:
TRAPHANDLER_NOEC(vector37, 37)
  101dfe:	6a 00                	push   $0x0
  101e00:	6a 25                	push   $0x25
  101e02:	e9 d1 92 00 00       	jmp    10b0d8 <_alltraps>
  101e07:	90                   	nop

00101e08 <vector38>:
TRAPHANDLER_NOEC(vector38, 38)
  101e08:	6a 00                	push   $0x0
  101e0a:	6a 26                	push   $0x26
  101e0c:	e9 c7 92 00 00       	jmp    10b0d8 <_alltraps>
  101e11:	90                   	nop

00101e12 <vector39>:
TRAPHANDLER_NOEC(vector39, 39)
  101e12:	6a 00                	push   $0x0
  101e14:	6a 27                	push   $0x27
  101e16:	e9 bd 92 00 00       	jmp    10b0d8 <_alltraps>
  101e1b:	90                   	nop

00101e1c <vector40>:
TRAPHANDLER_NOEC(vector40, 40)
  101e1c:	6a 00                	push   $0x0
  101e1e:	6a 28                	push   $0x28
  101e20:	e9 b3 92 00 00       	jmp    10b0d8 <_alltraps>
  101e25:	90                   	nop

00101e26 <vector41>:
TRAPHANDLER_NOEC(vector41, 41)
  101e26:	6a 00                	push   $0x0
  101e28:	6a 29                	push   $0x29
  101e2a:	e9 a9 92 00 00       	jmp    10b0d8 <_alltraps>
  101e2f:	90                   	nop

00101e30 <vector42>:
TRAPHANDLER_NOEC(vector42, 42)
  101e30:	6a 00                	push   $0x0
  101e32:	6a 2a                	push   $0x2a
  101e34:	e9 9f 92 00 00       	jmp    10b0d8 <_alltraps>
  101e39:	90                   	nop

00101e3a <vector43>:
TRAPHANDLER_NOEC(vector43, 43)
  101e3a:	6a 00                	push   $0x0
  101e3c:	6a 2b                	push   $0x2b
  101e3e:	e9 95 92 00 00       	jmp    10b0d8 <_alltraps>
  101e43:	90                   	nop

00101e44 <vector44>:
TRAPHANDLER_NOEC(vector44, 44)
  101e44:	6a 00                	push   $0x0
  101e46:	6a 2c                	push   $0x2c
  101e48:	e9 8b 92 00 00       	jmp    10b0d8 <_alltraps>
  101e4d:	90                   	nop

00101e4e <vector45>:
TRAPHANDLER_NOEC(vector45, 45)
  101e4e:	6a 00                	push   $0x0
  101e50:	6a 2d                	push   $0x2d
  101e52:	e9 81 92 00 00       	jmp    10b0d8 <_alltraps>
  101e57:	90                   	nop

00101e58 <vector46>:
TRAPHANDLER_NOEC(vector46, 46)
  101e58:	6a 00                	push   $0x0
  101e5a:	6a 2e                	push   $0x2e
  101e5c:	e9 77 92 00 00       	jmp    10b0d8 <_alltraps>
  101e61:	90                   	nop

00101e62 <vector47>:
TRAPHANDLER_NOEC(vector47, 47)
  101e62:	6a 00                	push   $0x0
  101e64:	6a 2f                	push   $0x2f
  101e66:	e9 6d 92 00 00       	jmp    10b0d8 <_alltraps>
  101e6b:	90                   	nop

00101e6c <vector48>:
TRAPHANDLER_NOEC(vector48, 48)
  101e6c:	6a 00                	push   $0x0
  101e6e:	6a 30                	push   $0x30
  101e70:	e9 63 92 00 00       	jmp    10b0d8 <_alltraps>
  101e75:	90                   	nop

00101e76 <vector49>:
TRAPHANDLER_NOEC(vector49, 49)
  101e76:	6a 00                	push   $0x0
  101e78:	6a 31                	push   $0x31
  101e7a:	e9 59 92 00 00       	jmp    10b0d8 <_alltraps>

00101e7f <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101e7f:	55                   	push   %ebp
  101e80:	89 e5                	mov    %esp,%ebp
  101e82:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101e85:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101e88:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101e8b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101e8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e91:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101e96:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101e99:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101e9c:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101ea2:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101ea7:	74 24                	je     101ecd <cpu_cur+0x4e>
  101ea9:	c7 44 24 0c 30 84 10 	movl   $0x108430,0xc(%esp)
  101eb0:	00 
  101eb1:	c7 44 24 08 46 84 10 	movl   $0x108446,0x8(%esp)
  101eb8:	00 
  101eb9:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101ec0:	00 
  101ec1:	c7 04 24 5b 84 10 00 	movl   $0x10845b,(%esp)
  101ec8:	e8 b4 e5 ff ff       	call   100481 <debug_panic>
	return c;
  101ecd:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101ed0:	c9                   	leave  
  101ed1:	c3                   	ret    

00101ed2 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101ed2:	55                   	push   %ebp
  101ed3:	89 e5                	mov    %esp,%ebp
  101ed5:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101ed8:	e8 a2 ff ff ff       	call   101e7f <cpu_cur>
  101edd:	3d 00 a0 10 00       	cmp    $0x10a000,%eax
  101ee2:	0f 94 c0             	sete   %al
  101ee5:	0f b6 c0             	movzbl %al,%eax
}
  101ee8:	c9                   	leave  
  101ee9:	c3                   	ret    

00101eea <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  101eea:	55                   	push   %ebp
  101eeb:	89 e5                	mov    %esp,%ebp
  101eed:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  101ef0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	for (i = 0; i < len; i++)
  101ef7:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  101efe:	eb 13                	jmp    101f13 <sum+0x29>
		sum += addr[i];
  101f00:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101f03:	03 45 08             	add    0x8(%ebp),%eax
  101f06:	0f b6 00             	movzbl (%eax),%eax
  101f09:	0f b6 c0             	movzbl %al,%eax
  101f0c:	01 45 fc             	add    %eax,-0x4(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  101f0f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  101f13:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101f16:	3b 45 0c             	cmp    0xc(%ebp),%eax
  101f19:	7c e5                	jl     101f00 <sum+0x16>
		sum += addr[i];
	return sum;
  101f1b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101f1e:	c9                   	leave  
  101f1f:	c3                   	ret    

00101f20 <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  101f20:	55                   	push   %ebp
  101f21:	89 e5                	mov    %esp,%ebp
  101f23:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  101f26:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f29:	03 45 08             	add    0x8(%ebp),%eax
  101f2c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  101f2f:	8b 45 08             	mov    0x8(%ebp),%eax
  101f32:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101f35:	eb 3f                	jmp    101f76 <mpsearch1+0x56>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  101f37:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  101f3e:	00 
  101f3f:	c7 44 24 04 68 84 10 	movl   $0x108468,0x4(%esp)
  101f46:	00 
  101f47:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f4a:	89 04 24             	mov    %eax,(%esp)
  101f4d:	e8 85 58 00 00       	call   1077d7 <memcmp>
  101f52:	85 c0                	test   %eax,%eax
  101f54:	75 1c                	jne    101f72 <mpsearch1+0x52>
  101f56:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  101f5d:	00 
  101f5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f61:	89 04 24             	mov    %eax,(%esp)
  101f64:	e8 81 ff ff ff       	call   101eea <sum>
  101f69:	84 c0                	test   %al,%al
  101f6b:	75 05                	jne    101f72 <mpsearch1+0x52>
			return (struct mp *) p;
  101f6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f70:	eb 11                	jmp    101f83 <mpsearch1+0x63>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  101f72:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  101f76:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f79:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  101f7c:	72 b9                	jb     101f37 <mpsearch1+0x17>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  101f7e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  101f83:	c9                   	leave  
  101f84:	c3                   	ret    

00101f85 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  101f85:	55                   	push   %ebp
  101f86:	89 e5                	mov    %esp,%ebp
  101f88:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  101f8b:	c7 45 ec 00 04 00 00 	movl   $0x400,-0x14(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  101f92:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101f95:	83 c0 0f             	add    $0xf,%eax
  101f98:	0f b6 00             	movzbl (%eax),%eax
  101f9b:	0f b6 c0             	movzbl %al,%eax
  101f9e:	89 c2                	mov    %eax,%edx
  101fa0:	c1 e2 08             	shl    $0x8,%edx
  101fa3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101fa6:	83 c0 0e             	add    $0xe,%eax
  101fa9:	0f b6 00             	movzbl (%eax),%eax
  101fac:	0f b6 c0             	movzbl %al,%eax
  101faf:	09 d0                	or     %edx,%eax
  101fb1:	c1 e0 04             	shl    $0x4,%eax
  101fb4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101fb7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101fbb:	74 21                	je     101fde <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  101fbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fc0:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  101fc7:	00 
  101fc8:	89 04 24             	mov    %eax,(%esp)
  101fcb:	e8 50 ff ff ff       	call   101f20 <mpsearch1>
  101fd0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101fd3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101fd7:	74 50                	je     102029 <mpsearch+0xa4>
			return mp;
  101fd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101fdc:	eb 5f                	jmp    10203d <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  101fde:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101fe1:	83 c0 14             	add    $0x14,%eax
  101fe4:	0f b6 00             	movzbl (%eax),%eax
  101fe7:	0f b6 c0             	movzbl %al,%eax
  101fea:	89 c2                	mov    %eax,%edx
  101fec:	c1 e2 08             	shl    $0x8,%edx
  101fef:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101ff2:	83 c0 13             	add    $0x13,%eax
  101ff5:	0f b6 00             	movzbl (%eax),%eax
  101ff8:	0f b6 c0             	movzbl %al,%eax
  101ffb:	09 d0                	or     %edx,%eax
  101ffd:	c1 e0 0a             	shl    $0xa,%eax
  102000:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  102003:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102006:	2d 00 04 00 00       	sub    $0x400,%eax
  10200b:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  102012:	00 
  102013:	89 04 24             	mov    %eax,(%esp)
  102016:	e8 05 ff ff ff       	call   101f20 <mpsearch1>
  10201b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10201e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102022:	74 05                	je     102029 <mpsearch+0xa4>
			return mp;
  102024:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102027:	eb 14                	jmp    10203d <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  102029:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  102030:	00 
  102031:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  102038:	e8 e3 fe ff ff       	call   101f20 <mpsearch1>
}
  10203d:	c9                   	leave  
  10203e:	c3                   	ret    

0010203f <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  10203f:	55                   	push   %ebp
  102040:	89 e5                	mov    %esp,%ebp
  102042:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  102045:	e8 3b ff ff ff       	call   101f85 <mpsearch>
  10204a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10204d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102051:	74 0a                	je     10205d <mpconfig+0x1e>
  102053:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102056:	8b 40 04             	mov    0x4(%eax),%eax
  102059:	85 c0                	test   %eax,%eax
  10205b:	75 07                	jne    102064 <mpconfig+0x25>
		return 0;
  10205d:	b8 00 00 00 00       	mov    $0x0,%eax
  102062:	eb 7b                	jmp    1020df <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  102064:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102067:	8b 40 04             	mov    0x4(%eax),%eax
  10206a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  10206d:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  102074:	00 
  102075:	c7 44 24 04 6d 84 10 	movl   $0x10846d,0x4(%esp)
  10207c:	00 
  10207d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102080:	89 04 24             	mov    %eax,(%esp)
  102083:	e8 4f 57 00 00       	call   1077d7 <memcmp>
  102088:	85 c0                	test   %eax,%eax
  10208a:	74 07                	je     102093 <mpconfig+0x54>
		return 0;
  10208c:	b8 00 00 00 00       	mov    $0x0,%eax
  102091:	eb 4c                	jmp    1020df <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  102093:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102096:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  10209a:	3c 01                	cmp    $0x1,%al
  10209c:	74 12                	je     1020b0 <mpconfig+0x71>
  10209e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1020a1:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  1020a5:	3c 04                	cmp    $0x4,%al
  1020a7:	74 07                	je     1020b0 <mpconfig+0x71>
		return 0;
  1020a9:	b8 00 00 00 00       	mov    $0x0,%eax
  1020ae:	eb 2f                	jmp    1020df <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  1020b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1020b3:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  1020b7:	0f b7 d0             	movzwl %ax,%edx
  1020ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1020bd:	89 54 24 04          	mov    %edx,0x4(%esp)
  1020c1:	89 04 24             	mov    %eax,(%esp)
  1020c4:	e8 21 fe ff ff       	call   101eea <sum>
  1020c9:	84 c0                	test   %al,%al
  1020cb:	74 07                	je     1020d4 <mpconfig+0x95>
		return 0;
  1020cd:	b8 00 00 00 00       	mov    $0x0,%eax
  1020d2:	eb 0b                	jmp    1020df <mpconfig+0xa0>
       *pmp = mp;
  1020d4:	8b 45 08             	mov    0x8(%ebp),%eax
  1020d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1020da:	89 10                	mov    %edx,(%eax)
	return conf;
  1020dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1020df:	c9                   	leave  
  1020e0:	c3                   	ret    

001020e1 <mp_init>:

void
mp_init(void)
{
  1020e1:	55                   	push   %ebp
  1020e2:	89 e5                	mov    %esp,%ebp
  1020e4:	83 ec 48             	sub    $0x48,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  1020e7:	e8 e6 fd ff ff       	call   101ed2 <cpu_onboot>
  1020ec:	85 c0                	test   %eax,%eax
  1020ee:	0f 84 72 01 00 00    	je     102266 <mp_init+0x185>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  1020f4:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1020f7:	89 04 24             	mov    %eax,(%esp)
  1020fa:	e8 40 ff ff ff       	call   10203f <mpconfig>
  1020ff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  102102:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  102106:	0f 84 5d 01 00 00    	je     102269 <mp_init+0x188>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  10210c:	c7 05 64 dd 31 00 01 	movl   $0x1,0x31dd64
  102113:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  102116:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102119:	8b 40 24             	mov    0x24(%eax),%eax
  10211c:	a3 04 10 32 00       	mov    %eax,0x321004
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  102121:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102124:	83 c0 2c             	add    $0x2c,%eax
  102127:	89 45 cc             	mov    %eax,-0x34(%ebp)
  10212a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10212d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102130:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  102134:	0f b7 c0             	movzwl %ax,%eax
  102137:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10213a:	89 45 d0             	mov    %eax,-0x30(%ebp)
  10213d:	e9 cc 00 00 00       	jmp    10220e <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  102142:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102145:	0f b6 00             	movzbl (%eax),%eax
  102148:	0f b6 c0             	movzbl %al,%eax
  10214b:	83 f8 04             	cmp    $0x4,%eax
  10214e:	0f 87 90 00 00 00    	ja     1021e4 <mp_init+0x103>
  102154:	8b 04 85 a0 84 10 00 	mov    0x1084a0(,%eax,4),%eax
  10215b:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  10215d:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102160:	89 45 d8             	mov    %eax,-0x28(%ebp)
			p += sizeof(struct mpproc);
  102163:	83 45 cc 14          	addl   $0x14,-0x34(%ebp)
			if (!(proc->flags & MPENAB))
  102167:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10216a:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  10216e:	0f b6 c0             	movzbl %al,%eax
  102171:	83 e0 01             	and    $0x1,%eax
  102174:	85 c0                	test   %eax,%eax
  102176:	0f 84 91 00 00 00    	je     10220d <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  10217c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10217f:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102183:	0f b6 c0             	movzbl %al,%eax
  102186:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  102189:	85 c0                	test   %eax,%eax
  10218b:	75 07                	jne    102194 <mp_init+0xb3>
  10218d:	e8 93 f0 ff ff       	call   101225 <cpu_alloc>
  102192:	eb 05                	jmp    102199 <mp_init+0xb8>
  102194:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  102199:	89 45 e0             	mov    %eax,-0x20(%ebp)
			c->id = proc->apicid;
  10219c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10219f:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  1021a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1021a6:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  1021ac:	a1 68 dd 31 00       	mov    0x31dd68,%eax
  1021b1:	83 c0 01             	add    $0x1,%eax
  1021b4:	a3 68 dd 31 00       	mov    %eax,0x31dd68
			continue;
  1021b9:	eb 53                	jmp    10220e <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  1021bb:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1021be:	89 45 dc             	mov    %eax,-0x24(%ebp)
			p += sizeof(struct mpioapic);
  1021c1:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			ioapicid = mpio->apicno;
  1021c5:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1021c8:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  1021cc:	a2 5c dd 31 00       	mov    %al,0x31dd5c
			ioapic = (struct ioapic *) mpio->addr;
  1021d1:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1021d4:	8b 40 04             	mov    0x4(%eax),%eax
  1021d7:	a3 60 dd 31 00       	mov    %eax,0x31dd60
			continue;
  1021dc:	eb 30                	jmp    10220e <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  1021de:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			continue;
  1021e2:	eb 2a                	jmp    10220e <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  1021e4:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1021e7:	0f b6 00             	movzbl (%eax),%eax
  1021ea:	0f b6 c0             	movzbl %al,%eax
  1021ed:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1021f1:	c7 44 24 08 74 84 10 	movl   $0x108474,0x8(%esp)
  1021f8:	00 
  1021f9:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  102200:	00 
  102201:	c7 04 24 94 84 10 00 	movl   $0x108494,(%esp)
  102208:	e8 74 e2 ff ff       	call   100481 <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  10220d:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  10220e:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102211:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102214:	0f 82 28 ff ff ff    	jb     102142 <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  10221a:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10221d:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  102221:	84 c0                	test   %al,%al
  102223:	74 45                	je     10226a <mp_init+0x189>
  102225:	c7 45 e8 22 00 00 00 	movl   $0x22,-0x18(%ebp)
  10222c:	c6 45 e7 70          	movb   $0x70,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102230:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  102234:	8b 55 e8             	mov    -0x18(%ebp),%edx
  102237:	ee                   	out    %al,(%dx)
  102238:	c7 45 ec 23 00 00 00 	movl   $0x23,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10223f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102242:	89 c2                	mov    %eax,%edx
  102244:	ec                   	in     (%dx),%al
  102245:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  102248:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  10224c:	83 c8 01             	or     $0x1,%eax
  10224f:	0f b6 c0             	movzbl %al,%eax
  102252:	c7 45 f4 23 00 00 00 	movl   $0x23,-0xc(%ebp)
  102259:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10225c:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  102260:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102263:	ee                   	out    %al,(%dx)
  102264:	eb 04                	jmp    10226a <mp_init+0x189>
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  102266:	90                   	nop
  102267:	eb 01                	jmp    10226a <mp_init+0x189>

	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.
  102269:	90                   	nop
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
	}
}
  10226a:	c9                   	leave  
  10226b:	c3                   	ret    

0010226c <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10226c:	55                   	push   %ebp
  10226d:	89 e5                	mov    %esp,%ebp
  10226f:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102272:	8b 55 08             	mov    0x8(%ebp),%edx
  102275:	8b 45 0c             	mov    0xc(%ebp),%eax
  102278:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10227b:	f0 87 02             	lock xchg %eax,(%edx)
  10227e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102281:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102284:	c9                   	leave  
  102285:	c3                   	ret    

00102286 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102286:	55                   	push   %ebp
  102287:	89 e5                	mov    %esp,%ebp
  102289:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10228c:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10228f:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102292:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102295:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102298:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10229d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1022a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1022a3:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1022a9:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1022ae:	74 24                	je     1022d4 <cpu_cur+0x4e>
  1022b0:	c7 44 24 0c b4 84 10 	movl   $0x1084b4,0xc(%esp)
  1022b7:	00 
  1022b8:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  1022bf:	00 
  1022c0:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1022c7:	00 
  1022c8:	c7 04 24 df 84 10 00 	movl   $0x1084df,(%esp)
  1022cf:	e8 ad e1 ff ff       	call   100481 <debug_panic>
	return c;
  1022d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1022d7:	c9                   	leave  
  1022d8:	c3                   	ret    

001022d9 <spinlock_init_>:
#include <kern/cons.h>


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  1022d9:	55                   	push   %ebp
  1022da:	89 e5                	mov    %esp,%ebp
	lk->locked = 0;
  1022dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1022df:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->file = file;
  1022e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1022e8:	8b 55 0c             	mov    0xc(%ebp),%edx
  1022eb:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  1022ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1022f1:	8b 55 10             	mov    0x10(%ebp),%edx
  1022f4:	89 50 08             	mov    %edx,0x8(%eax)
	lk->cpu = NULL;
  1022f7:	8b 45 08             	mov    0x8(%ebp),%eax
  1022fa:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	lk->eips[0] = 0;
  102301:	8b 45 08             	mov    0x8(%ebp),%eax
  102304:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
}
  10230b:	5d                   	pop    %ebp
  10230c:	c3                   	ret    

0010230d <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  10230d:	55                   	push   %ebp
  10230e:	89 e5                	mov    %esp,%ebp
  102310:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in sa\n");

	if(spinlock_holding(lk)){
  102313:	8b 45 08             	mov    0x8(%ebp),%eax
  102316:	89 04 24             	mov    %eax,(%esp)
  102319:	e8 b6 00 00 00       	call   1023d4 <spinlock_holding>
  10231e:	85 c0                	test   %eax,%eax
  102320:	74 1c                	je     10233e <spinlock_acquire+0x31>
		//cprintf("acquire\n");
		//cprintf("file = %s, line = %d, cpu = %d\n", lk->file, lk->line, lk->cpu->id);
		panic("acquire");
  102322:	c7 44 24 08 ec 84 10 	movl   $0x1084ec,0x8(%esp)
  102329:	00 
  10232a:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
  102331:	00 
  102332:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  102339:	e8 43 e1 ff ff       	call   100481 <debug_panic>
	}

	while(xchg(&lk->locked, 1) !=0)
  10233e:	8b 45 08             	mov    0x8(%ebp),%eax
  102341:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102348:	00 
  102349:	89 04 24             	mov    %eax,(%esp)
  10234c:	e8 1b ff ff ff       	call   10226c <xchg>
  102351:	85 c0                	test   %eax,%eax
  102353:	75 e9                	jne    10233e <spinlock_acquire+0x31>
		{//cprintf("in xchg\n")
		;}

	lk->cpu = cpu_cur();
  102355:	e8 2c ff ff ff       	call   102286 <cpu_cur>
  10235a:	8b 55 08             	mov    0x8(%ebp),%edx
  10235d:	89 42 0c             	mov    %eax,0xc(%edx)

	//cprintf("before dt\n");
	debug_trace(read_ebp(), lk->eips);
  102360:	8b 45 08             	mov    0x8(%ebp),%eax
  102363:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  102366:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  102369:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10236c:	89 54 24 04          	mov    %edx,0x4(%esp)
  102370:	89 04 24             	mov    %eax,(%esp)
  102373:	e8 11 e2 ff ff       	call   100589 <debug_trace>
	//cprintf("after dt\n");

	//cprintf("after sa\n");

	//cprintf("acquire lock num: %d on cpu: %d\n", lk->number, lk->cpu->id);
}
  102378:	c9                   	leave  
  102379:	c3                   	ret    

0010237a <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  10237a:	55                   	push   %ebp
  10237b:	89 e5                	mov    %esp,%ebp
  10237d:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk))
  102380:	8b 45 08             	mov    0x8(%ebp),%eax
  102383:	89 04 24             	mov    %eax,(%esp)
  102386:	e8 49 00 00 00       	call   1023d4 <spinlock_holding>
  10238b:	85 c0                	test   %eax,%eax
  10238d:	75 1c                	jne    1023ab <spinlock_release+0x31>
		panic("release");
  10238f:	c7 44 24 08 04 85 10 	movl   $0x108504,0x8(%esp)
  102396:	00 
  102397:	c7 44 24 04 40 00 00 	movl   $0x40,0x4(%esp)
  10239e:	00 
  10239f:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  1023a6:	e8 d6 e0 ff ff       	call   100481 <debug_panic>

	lk->cpu = NULL;
  1023ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1023ae:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	xchg(&lk->locked, 0);
  1023b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1023b8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1023bf:	00 
  1023c0:	89 04 24             	mov    %eax,(%esp)
  1023c3:	e8 a4 fe ff ff       	call   10226c <xchg>

	lk->eips[0] = 0;
  1023c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1023cb:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)

	//cprintf("release lock num: %d on cpu: %d\n", lk->number, lk->cpu->id);
}
  1023d2:	c9                   	leave  
  1023d3:	c3                   	ret    

001023d4 <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  1023d4:	55                   	push   %ebp
  1023d5:	89 e5                	mov    %esp,%ebp
  1023d7:	53                   	push   %ebx
  1023d8:	83 ec 04             	sub    $0x4,%esp
	return (lock->cpu == cpu_cur()) && (lock->locked);
  1023db:	8b 45 08             	mov    0x8(%ebp),%eax
  1023de:	8b 58 0c             	mov    0xc(%eax),%ebx
  1023e1:	e8 a0 fe ff ff       	call   102286 <cpu_cur>
  1023e6:	39 c3                	cmp    %eax,%ebx
  1023e8:	75 10                	jne    1023fa <spinlock_holding+0x26>
  1023ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1023ed:	8b 00                	mov    (%eax),%eax
  1023ef:	85 c0                	test   %eax,%eax
  1023f1:	74 07                	je     1023fa <spinlock_holding+0x26>
  1023f3:	b8 01 00 00 00       	mov    $0x1,%eax
  1023f8:	eb 05                	jmp    1023ff <spinlock_holding+0x2b>
  1023fa:	b8 00 00 00 00       	mov    $0x0,%eax
	//panic("spinlock_holding() not implemented");
}
  1023ff:	83 c4 04             	add    $0x4,%esp
  102402:	5b                   	pop    %ebx
  102403:	5d                   	pop    %ebp
  102404:	c3                   	ret    

00102405 <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  102405:	55                   	push   %ebp
  102406:	89 e5                	mov    %esp,%ebp
  102408:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  10240b:	8b 45 08             	mov    0x8(%ebp),%eax
  10240e:	85 c0                	test   %eax,%eax
  102410:	75 12                	jne    102424 <spinlock_godeep+0x1f>
  102412:	8b 45 0c             	mov    0xc(%ebp),%eax
  102415:	89 04 24             	mov    %eax,(%esp)
  102418:	e8 f0 fe ff ff       	call   10230d <spinlock_acquire>
  10241d:	b8 01 00 00 00       	mov    $0x1,%eax
  102422:	eb 1b                	jmp    10243f <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  102424:	8b 45 08             	mov    0x8(%ebp),%eax
  102427:	8d 50 ff             	lea    -0x1(%eax),%edx
  10242a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10242d:	89 44 24 04          	mov    %eax,0x4(%esp)
  102431:	89 14 24             	mov    %edx,(%esp)
  102434:	e8 cc ff ff ff       	call   102405 <spinlock_godeep>
  102439:	8b 55 08             	mov    0x8(%ebp),%edx
  10243c:	0f af c2             	imul   %edx,%eax
}
  10243f:	c9                   	leave  
  102440:	c3                   	ret    

00102441 <spinlock_check>:



void spinlock_check()
{
  102441:	55                   	push   %ebp
  102442:	89 e5                	mov    %esp,%ebp
  102444:	57                   	push   %edi
  102445:	56                   	push   %esi
  102446:	53                   	push   %ebx
  102447:	83 ec 5c             	sub    $0x5c,%esp
  10244a:	89 e0                	mov    %esp,%eax
  10244c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	const int NUMLOCKS=10;
  10244f:	c7 45 d0 0a 00 00 00 	movl   $0xa,-0x30(%ebp)
	const int NUMRUNS=5;
  102456:	c7 45 d4 05 00 00 00 	movl   $0x5,-0x2c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  10245d:	c7 45 e4 0c 85 10 00 	movl   $0x10850c,-0x1c(%ebp)
	spinlock locks[NUMLOCKS];
  102464:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102467:	83 e8 01             	sub    $0x1,%eax
  10246a:	89 45 c8             	mov    %eax,-0x38(%ebp)
  10246d:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102470:	ba 00 00 00 00       	mov    $0x0,%edx
  102475:	89 c1                	mov    %eax,%ecx
  102477:	80 e5 ff             	and    $0xff,%ch
  10247a:	89 d3                	mov    %edx,%ebx
  10247c:	83 e3 0f             	and    $0xf,%ebx
  10247f:	89 c8                	mov    %ecx,%eax
  102481:	89 da                	mov    %ebx,%edx
  102483:	69 da c0 01 00 00    	imul   $0x1c0,%edx,%ebx
  102489:	6b c8 00             	imul   $0x0,%eax,%ecx
  10248c:	01 cb                	add    %ecx,%ebx
  10248e:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102493:	f7 e1                	mul    %ecx
  102495:	01 d3                	add    %edx,%ebx
  102497:	89 da                	mov    %ebx,%edx
  102499:	89 c6                	mov    %eax,%esi
  10249b:	83 e6 ff             	and    $0xffffffff,%esi
  10249e:	89 d7                	mov    %edx,%edi
  1024a0:	83 e7 0f             	and    $0xf,%edi
  1024a3:	89 f0                	mov    %esi,%eax
  1024a5:	89 fa                	mov    %edi,%edx
  1024a7:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1024aa:	c1 e0 03             	shl    $0x3,%eax
  1024ad:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1024b0:	ba 00 00 00 00       	mov    $0x0,%edx
  1024b5:	89 c1                	mov    %eax,%ecx
  1024b7:	80 e5 ff             	and    $0xff,%ch
  1024ba:	89 4d b8             	mov    %ecx,-0x48(%ebp)
  1024bd:	89 d3                	mov    %edx,%ebx
  1024bf:	83 e3 0f             	and    $0xf,%ebx
  1024c2:	89 5d bc             	mov    %ebx,-0x44(%ebp)
  1024c5:	8b 45 b8             	mov    -0x48(%ebp),%eax
  1024c8:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1024cb:	69 ca c0 01 00 00    	imul   $0x1c0,%edx,%ecx
  1024d1:	6b d8 00             	imul   $0x0,%eax,%ebx
  1024d4:	01 d9                	add    %ebx,%ecx
  1024d6:	bb c0 01 00 00       	mov    $0x1c0,%ebx
  1024db:	f7 e3                	mul    %ebx
  1024dd:	01 d1                	add    %edx,%ecx
  1024df:	89 ca                	mov    %ecx,%edx
  1024e1:	89 c1                	mov    %eax,%ecx
  1024e3:	80 e5 ff             	and    $0xff,%ch
  1024e6:	89 4d b0             	mov    %ecx,-0x50(%ebp)
  1024e9:	89 d3                	mov    %edx,%ebx
  1024eb:	83 e3 0f             	and    $0xf,%ebx
  1024ee:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
  1024f1:	8b 45 b0             	mov    -0x50(%ebp),%eax
  1024f4:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  1024f7:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1024fa:	c1 e0 03             	shl    $0x3,%eax
  1024fd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102504:	89 d1                	mov    %edx,%ecx
  102506:	29 c1                	sub    %eax,%ecx
  102508:	89 c8                	mov    %ecx,%eax
  10250a:	83 c0 0f             	add    $0xf,%eax
  10250d:	83 c0 0f             	add    $0xf,%eax
  102510:	c1 e8 04             	shr    $0x4,%eax
  102513:	c1 e0 04             	shl    $0x4,%eax
  102516:	29 c4                	sub    %eax,%esp
  102518:	8d 44 24 10          	lea    0x10(%esp),%eax
  10251c:	83 c0 0f             	add    $0xf,%eax
  10251f:	c1 e8 04             	shr    $0x4,%eax
  102522:	c1 e0 04             	shl    $0x4,%eax
  102525:	89 45 cc             	mov    %eax,-0x34(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  102528:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10252f:	eb 33                	jmp    102564 <spinlock_check+0x123>
  102531:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102534:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102537:	c1 e0 03             	shl    $0x3,%eax
  10253a:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102541:	89 cb                	mov    %ecx,%ebx
  102543:	29 c3                	sub    %eax,%ebx
  102545:	89 d8                	mov    %ebx,%eax
  102547:	01 c2                	add    %eax,%edx
  102549:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102550:	00 
  102551:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102554:	89 44 24 04          	mov    %eax,0x4(%esp)
  102558:	89 14 24             	mov    %edx,(%esp)
  10255b:	e8 79 fd ff ff       	call   1022d9 <spinlock_init_>
  102560:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102564:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102567:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10256a:	7c c5                	jl     102531 <spinlock_check+0xf0>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  10256c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102573:	eb 46                	jmp    1025bb <spinlock_check+0x17a>
  102575:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102578:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10257b:	c1 e0 03             	shl    $0x3,%eax
  10257e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102585:	29 c2                	sub    %eax,%edx
  102587:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  10258a:	83 c0 0c             	add    $0xc,%eax
  10258d:	8b 00                	mov    (%eax),%eax
  10258f:	85 c0                	test   %eax,%eax
  102591:	74 24                	je     1025b7 <spinlock_check+0x176>
  102593:	c7 44 24 0c 1b 85 10 	movl   $0x10851b,0xc(%esp)
  10259a:	00 
  10259b:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  1025a2:	00 
  1025a3:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1025aa:	00 
  1025ab:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  1025b2:	e8 ca de ff ff       	call   100481 <debug_panic>
  1025b7:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1025bb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025be:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1025c1:	7c b2                	jl     102575 <spinlock_check+0x134>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  1025c3:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1025ca:	eb 47                	jmp    102613 <spinlock_check+0x1d2>
  1025cc:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025cf:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1025d2:	c1 e0 03             	shl    $0x3,%eax
  1025d5:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1025dc:	29 c2                	sub    %eax,%edx
  1025de:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1025e1:	83 c0 04             	add    $0x4,%eax
  1025e4:	8b 00                	mov    (%eax),%eax
  1025e6:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  1025e9:	74 24                	je     10260f <spinlock_check+0x1ce>
  1025eb:	c7 44 24 0c 2e 85 10 	movl   $0x10852e,0xc(%esp)
  1025f2:	00 
  1025f3:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  1025fa:	00 
  1025fb:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  102602:	00 
  102603:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  10260a:	e8 72 de ff ff       	call   100481 <debug_panic>
  10260f:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102613:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102616:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102619:	7c b1                	jl     1025cc <spinlock_check+0x18b>

	for (run=0;run<NUMRUNS;run++) 
  10261b:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  102622:	e9 25 03 00 00       	jmp    10294c <spinlock_check+0x50b>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  102627:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10262e:	eb 3f                	jmp    10266f <spinlock_check+0x22e>
		{
			cprintf("%d\n", i);
  102630:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102633:	89 44 24 04          	mov    %eax,0x4(%esp)
  102637:	c7 04 24 42 85 10 00 	movl   $0x108542,(%esp)
  10263e:	e8 3f 4e 00 00       	call   107482 <cprintf>
			spinlock_godeep(i, &locks[i]);
  102643:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102646:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102649:	c1 e0 03             	shl    $0x3,%eax
  10264c:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102653:	89 cb                	mov    %ecx,%ebx
  102655:	29 c3                	sub    %eax,%ebx
  102657:	89 d8                	mov    %ebx,%eax
  102659:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10265c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102660:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102663:	89 04 24             	mov    %eax,(%esp)
  102666:	e8 9a fd ff ff       	call   102405 <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  10266b:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10266f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102672:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102675:	7c b9                	jl     102630 <spinlock_check+0x1ef>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  102677:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10267e:	eb 4b                	jmp    1026cb <spinlock_check+0x28a>
			assert(locks[i].cpu == cpu_cur());
  102680:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102683:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102686:	c1 e0 03             	shl    $0x3,%eax
  102689:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102690:	29 c2                	sub    %eax,%edx
  102692:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  102695:	83 c0 0c             	add    $0xc,%eax
  102698:	8b 18                	mov    (%eax),%ebx
  10269a:	e8 e7 fb ff ff       	call   102286 <cpu_cur>
  10269f:	39 c3                	cmp    %eax,%ebx
  1026a1:	74 24                	je     1026c7 <spinlock_check+0x286>
  1026a3:	c7 44 24 0c 46 85 10 	movl   $0x108546,0xc(%esp)
  1026aa:	00 
  1026ab:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  1026b2:	00 
  1026b3:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  1026ba:	00 
  1026bb:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  1026c2:	e8 ba dd ff ff       	call   100481 <debug_panic>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  1026c7:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1026cb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1026ce:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1026d1:	7c ad                	jl     102680 <spinlock_check+0x23f>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  1026d3:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1026da:	eb 4d                	jmp    102729 <spinlock_check+0x2e8>
			assert(spinlock_holding(&locks[i]) != 0);
  1026dc:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1026df:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1026e2:	c1 e0 03             	shl    $0x3,%eax
  1026e5:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  1026ec:	89 cb                	mov    %ecx,%ebx
  1026ee:	29 c3                	sub    %eax,%ebx
  1026f0:	89 d8                	mov    %ebx,%eax
  1026f2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1026f5:	89 04 24             	mov    %eax,(%esp)
  1026f8:	e8 d7 fc ff ff       	call   1023d4 <spinlock_holding>
  1026fd:	85 c0                	test   %eax,%eax
  1026ff:	75 24                	jne    102725 <spinlock_check+0x2e4>
  102701:	c7 44 24 0c 60 85 10 	movl   $0x108560,0xc(%esp)
  102708:	00 
  102709:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  102710:	00 
  102711:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  102718:	00 
  102719:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  102720:	e8 5c dd ff ff       	call   100481 <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102725:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102729:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10272c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10272f:	7c ab                	jl     1026dc <spinlock_check+0x29b>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  102731:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102738:	e9 bd 00 00 00       	jmp    1027fa <spinlock_check+0x3b9>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  10273d:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102744:	e9 9b 00 00 00       	jmp    1027e4 <spinlock_check+0x3a3>
			{
				assert(locks[i].eips[j] >=
  102749:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10274c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  10274f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102752:	01 c0                	add    %eax,%eax
  102754:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10275b:	29 c2                	sub    %eax,%edx
  10275d:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  102760:	83 c0 04             	add    $0x4,%eax
  102763:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  102766:	b8 05 24 10 00       	mov    $0x102405,%eax
  10276b:	39 c2                	cmp    %eax,%edx
  10276d:	73 24                	jae    102793 <spinlock_check+0x352>
  10276f:	c7 44 24 0c 84 85 10 	movl   $0x108584,0xc(%esp)
  102776:	00 
  102777:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  10277e:	00 
  10277f:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  102786:	00 
  102787:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  10278e:	e8 ee dc ff ff       	call   100481 <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  102793:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102796:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  102799:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10279c:	01 c0                	add    %eax,%eax
  10279e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1027a5:	29 c2                	sub    %eax,%edx
  1027a7:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  1027aa:	83 c0 04             	add    $0x4,%eax
  1027ad:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  1027b0:	ba 05 24 10 00       	mov    $0x102405,%edx
  1027b5:	83 c2 64             	add    $0x64,%edx
  1027b8:	39 d0                	cmp    %edx,%eax
  1027ba:	72 24                	jb     1027e0 <spinlock_check+0x39f>
  1027bc:	c7 44 24 0c b4 85 10 	movl   $0x1085b4,0xc(%esp)
  1027c3:	00 
  1027c4:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  1027cb:	00 
  1027cc:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  1027d3:	00 
  1027d4:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  1027db:	e8 a1 dc ff ff       	call   100481 <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  1027e0:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  1027e4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1027e7:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  1027ea:	7f 0a                	jg     1027f6 <spinlock_check+0x3b5>
  1027ec:	83 7d dc 09          	cmpl   $0x9,-0x24(%ebp)
  1027f0:	0f 8e 53 ff ff ff    	jle    102749 <spinlock_check+0x308>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  1027f6:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1027fa:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1027fd:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102800:	0f 8c 37 ff ff ff    	jl     10273d <spinlock_check+0x2fc>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  102806:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10280d:	eb 25                	jmp    102834 <spinlock_check+0x3f3>
  10280f:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102812:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102815:	c1 e0 03             	shl    $0x3,%eax
  102818:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  10281f:	89 cb                	mov    %ecx,%ebx
  102821:	29 c3                	sub    %eax,%ebx
  102823:	89 d8                	mov    %ebx,%eax
  102825:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102828:	89 04 24             	mov    %eax,(%esp)
  10282b:	e8 4a fb ff ff       	call   10237a <spinlock_release>
  102830:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102834:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102837:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10283a:	7c d3                	jl     10280f <spinlock_check+0x3ce>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  10283c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102843:	eb 46                	jmp    10288b <spinlock_check+0x44a>
  102845:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102848:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10284b:	c1 e0 03             	shl    $0x3,%eax
  10284e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102855:	29 c2                	sub    %eax,%edx
  102857:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  10285a:	83 c0 0c             	add    $0xc,%eax
  10285d:	8b 00                	mov    (%eax),%eax
  10285f:	85 c0                	test   %eax,%eax
  102861:	74 24                	je     102887 <spinlock_check+0x446>
  102863:	c7 44 24 0c e5 85 10 	movl   $0x1085e5,0xc(%esp)
  10286a:	00 
  10286b:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  102872:	00 
  102873:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  10287a:	00 
  10287b:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  102882:	e8 fa db ff ff       	call   100481 <debug_panic>
  102887:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10288b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10288e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102891:	7c b2                	jl     102845 <spinlock_check+0x404>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  102893:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10289a:	eb 46                	jmp    1028e2 <spinlock_check+0x4a1>
  10289c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10289f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1028a2:	c1 e0 03             	shl    $0x3,%eax
  1028a5:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1028ac:	29 c2                	sub    %eax,%edx
  1028ae:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1028b1:	83 c0 10             	add    $0x10,%eax
  1028b4:	8b 00                	mov    (%eax),%eax
  1028b6:	85 c0                	test   %eax,%eax
  1028b8:	74 24                	je     1028de <spinlock_check+0x49d>
  1028ba:	c7 44 24 0c fa 85 10 	movl   $0x1085fa,0xc(%esp)
  1028c1:	00 
  1028c2:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  1028c9:	00 
  1028ca:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  1028d1:	00 
  1028d2:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  1028d9:	e8 a3 db ff ff       	call   100481 <debug_panic>
  1028de:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1028e2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1028e5:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1028e8:	7c b2                	jl     10289c <spinlock_check+0x45b>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  1028ea:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1028f1:	eb 4d                	jmp    102940 <spinlock_check+0x4ff>
  1028f3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1028f6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1028f9:	c1 e0 03             	shl    $0x3,%eax
  1028fc:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102903:	89 cb                	mov    %ecx,%ebx
  102905:	29 c3                	sub    %eax,%ebx
  102907:	89 d8                	mov    %ebx,%eax
  102909:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10290c:	89 04 24             	mov    %eax,(%esp)
  10290f:	e8 c0 fa ff ff       	call   1023d4 <spinlock_holding>
  102914:	85 c0                	test   %eax,%eax
  102916:	74 24                	je     10293c <spinlock_check+0x4fb>
  102918:	c7 44 24 0c 10 86 10 	movl   $0x108610,0xc(%esp)
  10291f:	00 
  102920:	c7 44 24 08 ca 84 10 	movl   $0x1084ca,0x8(%esp)
  102927:	00 
  102928:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  10292f:	00 
  102930:	c7 04 24 f4 84 10 00 	movl   $0x1084f4,(%esp)
  102937:	e8 45 db ff ff       	call   100481 <debug_panic>
  10293c:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102940:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102943:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102946:	7c ab                	jl     1028f3 <spinlock_check+0x4b2>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  102948:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  10294c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10294f:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  102952:	0f 8c cf fc ff ff    	jl     102627 <spinlock_check+0x1e6>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  102958:	c7 04 24 31 86 10 00 	movl   $0x108631,(%esp)
  10295f:	e8 1e 4b 00 00       	call   107482 <cprintf>
  102964:	8b 65 c4             	mov    -0x3c(%ebp),%esp
}
  102967:	8d 65 f4             	lea    -0xc(%ebp),%esp
  10296a:	83 c4 00             	add    $0x0,%esp
  10296d:	5b                   	pop    %ebx
  10296e:	5e                   	pop    %esi
  10296f:	5f                   	pop    %edi
  102970:	5d                   	pop    %ebp
  102971:	c3                   	ret    

00102972 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  102972:	55                   	push   %ebp
  102973:	89 e5                	mov    %esp,%ebp
  102975:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102978:	8b 55 08             	mov    0x8(%ebp),%edx
  10297b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10297e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102981:	f0 87 02             	lock xchg %eax,(%edx)
  102984:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102987:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10298a:	c9                   	leave  
  10298b:	c3                   	ret    

0010298c <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  10298c:	55                   	push   %ebp
  10298d:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  10298f:	8b 45 08             	mov    0x8(%ebp),%eax
  102992:	8b 55 0c             	mov    0xc(%ebp),%edx
  102995:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102998:	f0 01 10             	lock add %edx,(%eax)
}
  10299b:	5d                   	pop    %ebp
  10299c:	c3                   	ret    

0010299d <pause>:
	return result;
}

static inline void
pause(void)
{
  10299d:	55                   	push   %ebp
  10299e:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  1029a0:	f3 90                	pause  
}
  1029a2:	5d                   	pop    %ebp
  1029a3:	c3                   	ret    

001029a4 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1029a4:	55                   	push   %ebp
  1029a5:	89 e5                	mov    %esp,%ebp
  1029a7:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1029aa:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1029ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1029b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1029b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1029b6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1029bb:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1029be:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1029c1:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1029c7:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1029cc:	74 24                	je     1029f2 <cpu_cur+0x4e>
  1029ce:	c7 44 24 0c 50 86 10 	movl   $0x108650,0xc(%esp)
  1029d5:	00 
  1029d6:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  1029dd:	00 
  1029de:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1029e5:	00 
  1029e6:	c7 04 24 7b 86 10 00 	movl   $0x10867b,(%esp)
  1029ed:	e8 8f da ff ff       	call   100481 <debug_panic>
	return c;
  1029f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1029f5:	c9                   	leave  
  1029f6:	c3                   	ret    

001029f7 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1029f7:	55                   	push   %ebp
  1029f8:	89 e5                	mov    %esp,%ebp
  1029fa:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1029fd:	e8 a2 ff ff ff       	call   1029a4 <cpu_cur>
  102a02:	3d 00 a0 10 00       	cmp    $0x10a000,%eax
  102a07:	0f 94 c0             	sete   %al
  102a0a:	0f b6 c0             	movzbl %al,%eax
}
  102a0d:	c9                   	leave  
  102a0e:	c3                   	ret    

00102a0f <proc_print>:



void
proc_print(TYPE ty, proc* p)
{
  102a0f:	55                   	push   %ebp
  102a10:	89 e5                	mov    %esp,%ebp
  102a12:	53                   	push   %ebx
  102a13:	83 ec 14             	sub    $0x14,%esp
	if(ty == ACQUIRE)
  102a16:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102a1a:	75 0e                	jne    102a2a <proc_print+0x1b>
		cprintf("acquire lock ");
  102a1c:	c7 04 24 88 86 10 00 	movl   $0x108688,(%esp)
  102a23:	e8 5a 4a 00 00       	call   107482 <cprintf>
  102a28:	eb 0c                	jmp    102a36 <proc_print+0x27>
	else
		cprintf("release lock ");
  102a2a:	c7 04 24 96 86 10 00 	movl   $0x108696,(%esp)
  102a31:	e8 4c 4a 00 00       	call   107482 <cprintf>
	if(p != NULL)
  102a36:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102a3a:	74 2b                	je     102a67 <proc_print+0x58>
		cprintf("on cpu %d, process %d\n", cpu_cur()->id, p->num);
  102a3c:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a3f:	8b 58 38             	mov    0x38(%eax),%ebx
  102a42:	e8 5d ff ff ff       	call   1029a4 <cpu_cur>
  102a47:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  102a4e:	0f b6 c0             	movzbl %al,%eax
  102a51:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  102a55:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a59:	c7 04 24 a4 86 10 00 	movl   $0x1086a4,(%esp)
  102a60:	e8 1d 4a 00 00       	call   107482 <cprintf>
  102a65:	eb 1f                	jmp    102a86 <proc_print+0x77>
	else
		cprintf("on cpu %d\n", cpu_cur()->id);
  102a67:	e8 38 ff ff ff       	call   1029a4 <cpu_cur>
  102a6c:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  102a73:	0f b6 c0             	movzbl %al,%eax
  102a76:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a7a:	c7 04 24 bb 86 10 00 	movl   $0x1086bb,(%esp)
  102a81:	e8 fc 49 00 00       	call   107482 <cprintf>
}
  102a86:	83 c4 14             	add    $0x14,%esp
  102a89:	5b                   	pop    %ebx
  102a8a:	5d                   	pop    %ebp
  102a8b:	c3                   	ret    

00102a8c <proc_init>:



void
proc_init(void)
{
  102a8c:	55                   	push   %ebp
  102a8d:	89 e5                	mov    %esp,%ebp
  102a8f:	83 ec 18             	sub    $0x18,%esp
	
	if (!cpu_onboot())
  102a92:	e8 60 ff ff ff       	call   1029f7 <cpu_onboot>
  102a97:	85 c0                	test   %eax,%eax
  102a99:	74 3c                	je     102ad7 <proc_init+0x4b>
		return;
	
	//cprintf("in proc_init, current cpu:%d\n", cpu_cur()->id);

	spinlock_init(&queue.lock);
  102a9b:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  102aa2:	00 
  102aa3:	c7 44 24 04 c6 86 10 	movl   $0x1086c6,0x4(%esp)
  102aaa:	00 
  102aab:	c7 04 24 40 e4 31 00 	movl   $0x31e440,(%esp)
  102ab2:	e8 22 f8 ff ff       	call   1022d9 <spinlock_init_>

	queue.count= 0;
  102ab7:	c7 05 78 e4 31 00 00 	movl   $0x0,0x31e478
  102abe:	00 00 00 
	queue.head = NULL;
  102ac1:	c7 05 7c e4 31 00 00 	movl   $0x0,0x31e47c
  102ac8:	00 00 00 
	queue.tail= NULL;
  102acb:	c7 05 80 e4 31 00 00 	movl   $0x0,0x31e480
  102ad2:	00 00 00 
  102ad5:	eb 01                	jmp    102ad8 <proc_init+0x4c>
void
proc_init(void)
{
	
	if (!cpu_onboot())
		return;
  102ad7:	90                   	nop
	queue.head = NULL;
	queue.tail= NULL;
	
	
	// your module initialization code here
}
  102ad8:	c9                   	leave  
  102ad9:	c3                   	ret    

00102ada <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  102ada:	55                   	push   %ebp
  102adb:	89 e5                	mov    %esp,%ebp
  102add:	83 ec 28             	sub    $0x28,%esp

	//cprintf("in proc_alloc\n");
	
	pageinfo *pi = mem_alloc();
  102ae0:	e8 28 e0 ff ff       	call   100b0d <mem_alloc>
  102ae5:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!pi)
  102ae8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  102aec:	75 0a                	jne    102af8 <proc_alloc+0x1e>
		return NULL;
  102aee:	b8 00 00 00 00       	mov    $0x0,%eax
  102af3:	e9 ba 01 00 00       	jmp    102cb2 <proc_alloc+0x1d8>
  102af8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102afb:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  102afe:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  102b03:	83 c0 08             	add    $0x8,%eax
  102b06:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b09:	76 15                	jbe    102b20 <proc_alloc+0x46>
  102b0b:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  102b10:	8b 15 04 dd 11 00    	mov    0x11dd04,%edx
  102b16:	c1 e2 03             	shl    $0x3,%edx
  102b19:	01 d0                	add    %edx,%eax
  102b1b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b1e:	72 24                	jb     102b44 <proc_alloc+0x6a>
  102b20:	c7 44 24 0c d4 86 10 	movl   $0x1086d4,0xc(%esp)
  102b27:	00 
  102b28:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  102b2f:	00 
  102b30:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102b37:	00 
  102b38:	c7 04 24 0b 87 10 00 	movl   $0x10870b,(%esp)
  102b3f:	e8 3d d9 ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  102b44:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  102b49:	ba 00 00 32 00       	mov    $0x320000,%edx
  102b4e:	c1 ea 0c             	shr    $0xc,%edx
  102b51:	c1 e2 03             	shl    $0x3,%edx
  102b54:	01 d0                	add    %edx,%eax
  102b56:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b59:	75 24                	jne    102b7f <proc_alloc+0xa5>
  102b5b:	c7 44 24 0c 18 87 10 	movl   $0x108718,0xc(%esp)
  102b62:	00 
  102b63:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  102b6a:	00 
  102b6b:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  102b72:	00 
  102b73:	c7 04 24 0b 87 10 00 	movl   $0x10870b,(%esp)
  102b7a:	e8 02 d9 ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  102b7f:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  102b84:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  102b89:	c1 ea 0c             	shr    $0xc,%edx
  102b8c:	c1 e2 03             	shl    $0x3,%edx
  102b8f:	01 d0                	add    %edx,%eax
  102b91:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b94:	72 3b                	jb     102bd1 <proc_alloc+0xf7>
  102b96:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  102b9b:	ba 07 10 32 00       	mov    $0x321007,%edx
  102ba0:	c1 ea 0c             	shr    $0xc,%edx
  102ba3:	c1 e2 03             	shl    $0x3,%edx
  102ba6:	01 d0                	add    %edx,%eax
  102ba8:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102bab:	77 24                	ja     102bd1 <proc_alloc+0xf7>
  102bad:	c7 44 24 0c 34 87 10 	movl   $0x108734,0xc(%esp)
  102bb4:	00 
  102bb5:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  102bbc:	00 
  102bbd:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  102bc4:	00 
  102bc5:	c7 04 24 0b 87 10 00 	movl   $0x10870b,(%esp)
  102bcc:	e8 b0 d8 ff ff       	call   100481 <debug_panic>

	lockadd(&pi->refcount, 1);
  102bd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102bd4:	83 c0 04             	add    $0x4,%eax
  102bd7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102bde:	00 
  102bdf:	89 04 24             	mov    %eax,(%esp)
  102be2:	e8 a5 fd ff ff       	call   10298c <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  102be7:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102bea:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  102bef:	89 d1                	mov    %edx,%ecx
  102bf1:	29 c1                	sub    %eax,%ecx
  102bf3:	89 c8                	mov    %ecx,%eax
  102bf5:	c1 f8 03             	sar    $0x3,%eax
  102bf8:	c1 e0 0c             	shl    $0xc,%eax
  102bfb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  102bfe:	c7 44 24 08 b0 06 00 	movl   $0x6b0,0x8(%esp)
  102c05:	00 
  102c06:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102c0d:	00 
  102c0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c11:	89 04 24             	mov    %eax,(%esp)
  102c14:	e8 4e 4a 00 00       	call   107667 <memset>

	spinlock_init(&cp->lock);
  102c19:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c1c:	c7 44 24 08 52 00 00 	movl   $0x52,0x8(%esp)
  102c23:	00 
  102c24:	c7 44 24 04 c6 86 10 	movl   $0x1086c6,0x4(%esp)
  102c2b:	00 
  102c2c:	89 04 24             	mov    %eax,(%esp)
  102c2f:	e8 a5 f6 ff ff       	call   1022d9 <spinlock_init_>
	cp->parent = p;
  102c34:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c37:	8b 55 08             	mov    0x8(%ebp),%edx
  102c3a:	89 50 3c             	mov    %edx,0x3c(%eax)
	cp->state = PROC_STOP;
  102c3d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c40:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  102c47:	00 00 00 

	cp->num = count++;
  102c4a:	a1 20 9a 11 00       	mov    0x119a20,%eax
  102c4f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102c52:	89 42 38             	mov    %eax,0x38(%edx)
  102c55:	83 c0 01             	add    $0x1,%eax
  102c58:	a3 20 9a 11 00       	mov    %eax,0x119a20

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  102c5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c60:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  102c67:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  102c69:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c6c:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  102c73:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  102c75:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c78:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  102c7f:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  102c81:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c84:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  102c8b:	23 00 

	cp->sv.tf.eflags = FL_IF;
  102c8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c90:	c7 80 90 04 00 00 00 	movl   $0x200,0x490(%eax)
  102c97:	02 00 00 

	if (p)
  102c9a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102c9e:	74 0f                	je     102caf <proc_alloc+0x1d5>
		p->child[cn] = cp;
  102ca0:	8b 55 0c             	mov    0xc(%ebp),%edx
  102ca3:	8b 45 08             	mov    0x8(%ebp),%eax
  102ca6:	8d 4a 10             	lea    0x10(%edx),%ecx
  102ca9:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102cac:	89 14 88             	mov    %edx,(%eax,%ecx,4)
	return cp;
  102caf:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102cb2:	c9                   	leave  
  102cb3:	c3                   	ret    

00102cb4 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  102cb4:	55                   	push   %ebp
  102cb5:	89 e5                	mov    %esp,%ebp
  102cb7:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_ready not implemented");

 	//cprintf("in ready, child num:%d\n", queue.count);
	if(p == NULL)
  102cba:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102cbe:	75 1c                	jne    102cdc <proc_ready+0x28>
		panic("proc_ready's p is null!");
  102cc0:	c7 44 24 08 65 87 10 	movl   $0x108765,0x8(%esp)
  102cc7:	00 
  102cc8:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
  102ccf:	00 
  102cd0:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  102cd7:	e8 a5 d7 ff ff       	call   100481 <debug_panic>
	
	assert(p->state != PROC_READY);
  102cdc:	8b 45 08             	mov    0x8(%ebp),%eax
  102cdf:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102ce5:	83 f8 01             	cmp    $0x1,%eax
  102ce8:	75 24                	jne    102d0e <proc_ready+0x5a>
  102cea:	c7 44 24 0c 7d 87 10 	movl   $0x10877d,0xc(%esp)
  102cf1:	00 
  102cf2:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  102cf9:	00 
  102cfa:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
  102d01:	00 
  102d02:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  102d09:	e8 73 d7 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102d0e:	8b 45 08             	mov    0x8(%ebp),%eax
  102d11:	89 04 24             	mov    %eax,(%esp)
  102d14:	e8 f4 f5 ff ff       	call   10230d <spinlock_acquire>
	p->state = PROC_READY;
  102d19:	8b 45 08             	mov    0x8(%ebp),%eax
  102d1c:	c7 80 40 04 00 00 01 	movl   $0x1,0x440(%eax)
  102d23:	00 00 00 
	spinlock_acquire(&queue.lock);
  102d26:	c7 04 24 40 e4 31 00 	movl   $0x31e440,(%esp)
  102d2d:	e8 db f5 ff ff       	call   10230d <spinlock_acquire>
	// if there is no proc in queue now
	if(queue.count == 0){
  102d32:	a1 78 e4 31 00       	mov    0x31e478,%eax
  102d37:	85 c0                	test   %eax,%eax
  102d39:	75 1f                	jne    102d5a <proc_ready+0xa6>
		//cprintf("in ready = 0\n");
		queue.count++;
  102d3b:	a1 78 e4 31 00       	mov    0x31e478,%eax
  102d40:	83 c0 01             	add    $0x1,%eax
  102d43:	a3 78 e4 31 00       	mov    %eax,0x31e478
		queue.head = p;
  102d48:	8b 45 08             	mov    0x8(%ebp),%eax
  102d4b:	a3 7c e4 31 00       	mov    %eax,0x31e47c
		queue.tail = p;
  102d50:	8b 45 08             	mov    0x8(%ebp),%eax
  102d53:	a3 80 e4 31 00       	mov    %eax,0x31e480
  102d58:	eb 24                	jmp    102d7e <proc_ready+0xca>
	}

	// insert it to the head of the queue
	else{
		//cprintf("in ready != 0\n");
		p->readynext = queue.head;
  102d5a:	8b 15 7c e4 31 00    	mov    0x31e47c,%edx
  102d60:	8b 45 08             	mov    0x8(%ebp),%eax
  102d63:	89 90 44 04 00 00    	mov    %edx,0x444(%eax)
		queue.head = p;
  102d69:	8b 45 08             	mov    0x8(%ebp),%eax
  102d6c:	a3 7c e4 31 00       	mov    %eax,0x31e47c
		queue.count += 1;
  102d71:	a1 78 e4 31 00       	mov    0x31e478,%eax
  102d76:	83 c0 01             	add    $0x1,%eax
  102d79:	a3 78 e4 31 00       	mov    %eax,0x31e478
		//spinlock_release(&queue.lock);
		//proc_print(RELEASE, p);
		//spinlock_release(&p->lock);
	}

	spinlock_release(&p->lock);
  102d7e:	8b 45 08             	mov    0x8(%ebp),%eax
  102d81:	89 04 24             	mov    %eax,(%esp)
  102d84:	e8 f1 f5 ff ff       	call   10237a <spinlock_release>
	spinlock_release(&queue.lock);
  102d89:	c7 04 24 40 e4 31 00 	movl   $0x31e440,(%esp)
  102d90:	e8 e5 f5 ff ff       	call   10237a <spinlock_release>
	return;
	
}
  102d95:	c9                   	leave  
  102d96:	c3                   	ret    

00102d97 <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  102d97:	55                   	push   %ebp
  102d98:	89 e5                	mov    %esp,%ebp
  102d9a:	83 ec 18             	sub    $0x18,%esp
	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102d9d:	8b 45 08             	mov    0x8(%ebp),%eax
  102da0:	89 04 24             	mov    %eax,(%esp)
  102da3:	e8 65 f5 ff ff       	call   10230d <spinlock_acquire>

	switch(entry){
  102da8:	8b 45 10             	mov    0x10(%ebp),%eax
  102dab:	85 c0                	test   %eax,%eax
  102dad:	74 2c                	je     102ddb <proc_save+0x44>
  102daf:	83 f8 01             	cmp    $0x1,%eax
  102db2:	74 36                	je     102dea <proc_save+0x53>
  102db4:	83 f8 ff             	cmp    $0xffffffff,%eax
  102db7:	75 53                	jne    102e0c <proc_save+0x75>
		case -1:		
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  102db9:	8b 45 08             	mov    0x8(%ebp),%eax
  102dbc:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102dc2:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102dc9:	00 
  102dca:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dcd:	89 44 24 04          	mov    %eax,0x4(%esp)
  102dd1:	89 14 24             	mov    %edx,(%esp)
  102dd4:	e8 02 49 00 00       	call   1076db <memmove>
			break;
  102dd9:	eb 4d                	jmp    102e28 <proc_save+0x91>
		case 0:
			tf->eip = (uintptr_t)((char*)tf->eip - 2);
  102ddb:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dde:	8b 40 38             	mov    0x38(%eax),%eax
  102de1:	8d 50 fe             	lea    -0x2(%eax),%edx
  102de4:	8b 45 0c             	mov    0xc(%ebp),%eax
  102de7:	89 50 38             	mov    %edx,0x38(%eax)
		case 1:
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  102dea:	8b 45 08             	mov    0x8(%ebp),%eax
  102ded:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102df3:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102dfa:	00 
  102dfb:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dfe:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e02:	89 14 24             	mov    %edx,(%esp)
  102e05:	e8 d1 48 00 00       	call   1076db <memmove>
			break;
  102e0a:	eb 1c                	jmp    102e28 <proc_save+0x91>
		default:
			panic("wrong entry!\n");
  102e0c:	c7 44 24 08 94 87 10 	movl   $0x108794,0x8(%esp)
  102e13:	00 
  102e14:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
  102e1b:	00 
  102e1c:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  102e23:	e8 59 d6 ff ff       	call   100481 <debug_panic>
	}

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  102e28:	8b 45 08             	mov    0x8(%ebp),%eax
  102e2b:	89 04 24             	mov    %eax,(%esp)
  102e2e:	e8 47 f5 ff ff       	call   10237a <spinlock_release>
}
  102e33:	c9                   	leave  
  102e34:	c3                   	ret    

00102e35 <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  102e35:	55                   	push   %ebp
  102e36:	89 e5                	mov    %esp,%ebp
  102e38:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");

	if(p == NULL || p->state != PROC_RUN)
  102e3b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102e3f:	74 0e                	je     102e4f <proc_wait+0x1a>
  102e41:	8b 45 08             	mov    0x8(%ebp),%eax
  102e44:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102e4a:	83 f8 02             	cmp    $0x2,%eax
  102e4d:	74 1c                	je     102e6b <proc_wait+0x36>
		panic("parent proc is not running!");
  102e4f:	c7 44 24 08 a2 87 10 	movl   $0x1087a2,0x8(%esp)
  102e56:	00 
  102e57:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  102e5e:	00 
  102e5f:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  102e66:	e8 16 d6 ff ff       	call   100481 <debug_panic>
	if(cp == NULL)
  102e6b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102e6f:	75 1c                	jne    102e8d <proc_wait+0x58>
		panic("no child proc!");
  102e71:	c7 44 24 08 be 87 10 	movl   $0x1087be,0x8(%esp)
  102e78:	00 
  102e79:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
  102e80:	00 
  102e81:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  102e88:	e8 f4 d5 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102e8d:	8b 45 08             	mov    0x8(%ebp),%eax
  102e90:	89 04 24             	mov    %eax,(%esp)
  102e93:	e8 75 f4 ff ff       	call   10230d <spinlock_acquire>
	p->state = PROC_WAIT;
  102e98:	8b 45 08             	mov    0x8(%ebp),%eax
  102e9b:	c7 80 40 04 00 00 03 	movl   $0x3,0x440(%eax)
  102ea2:	00 00 00 
	p->waitchild = cp;
  102ea5:	8b 45 08             	mov    0x8(%ebp),%eax
  102ea8:	8b 55 0c             	mov    0xc(%ebp),%edx
  102eab:	89 90 4c 04 00 00    	mov    %edx,0x44c(%eax)
	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  102eb1:	8b 45 08             	mov    0x8(%ebp),%eax
  102eb4:	89 04 24             	mov    %eax,(%esp)
  102eb7:	e8 be f4 ff ff       	call   10237a <spinlock_release>
	
	proc_save(p, tf, 0);
  102ebc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102ec3:	00 
  102ec4:	8b 45 10             	mov    0x10(%ebp),%eax
  102ec7:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ecb:	8b 45 08             	mov    0x8(%ebp),%eax
  102ece:	89 04 24             	mov    %eax,(%esp)
  102ed1:	e8 c1 fe ff ff       	call   102d97 <proc_save>

	assert(cp->state != PROC_STOP);
  102ed6:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ed9:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102edf:	85 c0                	test   %eax,%eax
  102ee1:	75 24                	jne    102f07 <proc_wait+0xd2>
  102ee3:	c7 44 24 0c cd 87 10 	movl   $0x1087cd,0xc(%esp)
  102eea:	00 
  102eeb:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  102ef2:	00 
  102ef3:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  102efa:	00 
  102efb:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  102f02:	e8 7a d5 ff ff       	call   100481 <debug_panic>
	
	proc_sched();
  102f07:	e8 00 00 00 00       	call   102f0c <proc_sched>

00102f0c <proc_sched>:
	
}

void gcc_noreturn
proc_sched(void)
{
  102f0c:	55                   	push   %ebp
  102f0d:	89 e5                	mov    %esp,%ebp
  102f0f:	83 ec 28             	sub    $0x28,%esp
			
		// if there is no ready process in queue
		// just wait

		//proc_print(ACQUIRE, NULL);
		spinlock_acquire(&queue.lock);
  102f12:	c7 04 24 40 e4 31 00 	movl   $0x31e440,(%esp)
  102f19:	e8 ef f3 ff ff       	call   10230d <spinlock_acquire>

		if(queue.count != 0){
  102f1e:	a1 78 e4 31 00       	mov    0x31e478,%eax
  102f23:	85 c0                	test   %eax,%eax
  102f25:	0f 84 8e 00 00 00    	je     102fb9 <proc_sched+0xad>
			// if there is just one ready process
			if(queue.count == 1){
  102f2b:	a1 78 e4 31 00       	mov    0x31e478,%eax
  102f30:	83 f8 01             	cmp    $0x1,%eax
  102f33:	75 28                	jne    102f5d <proc_sched+0x51>
				//cprintf("in sched queue.count == 1\n");
				run = queue.head;
  102f35:	a1 7c e4 31 00       	mov    0x31e47c,%eax
  102f3a:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.head = queue.tail = NULL;
  102f3d:	c7 05 80 e4 31 00 00 	movl   $0x0,0x31e480
  102f44:	00 00 00 
  102f47:	a1 80 e4 31 00       	mov    0x31e480,%eax
  102f4c:	a3 7c e4 31 00       	mov    %eax,0x31e47c
				queue.count = 0;	
  102f51:	c7 05 78 e4 31 00 00 	movl   $0x0,0x31e478
  102f58:	00 00 00 
  102f5b:	eb 45                	jmp    102fa2 <proc_sched+0x96>
			
			
			// if there is more than one ready processes
			else{
				//cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
  102f5d:	a1 7c e4 31 00       	mov    0x31e47c,%eax
  102f62:	89 45 f4             	mov    %eax,-0xc(%ebp)
				while(before_tail->readynext != queue.tail){
  102f65:	eb 0c                	jmp    102f73 <proc_sched+0x67>
					before_tail = before_tail->readynext;
  102f67:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f6a:	8b 80 44 04 00 00    	mov    0x444(%eax),%eax
  102f70:	89 45 f4             	mov    %eax,-0xc(%ebp)
			
			// if there is more than one ready processes
			else{
				//cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
				while(before_tail->readynext != queue.tail){
  102f73:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f76:	8b 90 44 04 00 00    	mov    0x444(%eax),%edx
  102f7c:	a1 80 e4 31 00       	mov    0x31e480,%eax
  102f81:	39 c2                	cmp    %eax,%edx
  102f83:	75 e2                	jne    102f67 <proc_sched+0x5b>
					before_tail = before_tail->readynext;
				}	
				run = queue.tail;
  102f85:	a1 80 e4 31 00       	mov    0x31e480,%eax
  102f8a:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.tail = before_tail;
  102f8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f90:	a3 80 e4 31 00       	mov    %eax,0x31e480
				queue.count--;				
  102f95:	a1 78 e4 31 00       	mov    0x31e478,%eax
  102f9a:	83 e8 01             	sub    $0x1,%eax
  102f9d:	a3 78 e4 31 00       	mov    %eax,0x31e478
				queue.count--;
			}
			*/
			
	
			spinlock_release(&queue.lock);
  102fa2:	c7 04 24 40 e4 31 00 	movl   $0x31e440,(%esp)
  102fa9:	e8 cc f3 ff ff       	call   10237a <spinlock_release>
			proc_run(run);
  102fae:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102fb1:	89 04 24             	mov    %eax,(%esp)
  102fb4:	e8 16 00 00 00       	call   102fcf <proc_run>
		}
		spinlock_release(&queue.lock);
  102fb9:	c7 04 24 40 e4 31 00 	movl   $0x31e440,(%esp)
  102fc0:	e8 b5 f3 ff ff       	call   10237a <spinlock_release>
		pause();
  102fc5:	e8 d3 f9 ff ff       	call   10299d <pause>
	}
  102fca:	e9 43 ff ff ff       	jmp    102f12 <proc_sched+0x6>

00102fcf <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  102fcf:	55                   	push   %ebp
  102fd0:	89 e5                	mov    %esp,%ebp
  102fd2:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");

	//cprintf("proc %x is running on cpu:%d\n", p, cpu_cur()->id);
	
	if(p == NULL)
  102fd5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102fd9:	75 1c                	jne    102ff7 <proc_run+0x28>
		panic("proc_run's p is null!");
  102fdb:	c7 44 24 08 e4 87 10 	movl   $0x1087e4,0x8(%esp)
  102fe2:	00 
  102fe3:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
  102fea:	00 
  102feb:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  102ff2:	e8 8a d4 ff ff       	call   100481 <debug_panic>

	assert(p->state == PROC_READY);
  102ff7:	8b 45 08             	mov    0x8(%ebp),%eax
  102ffa:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103000:	83 f8 01             	cmp    $0x1,%eax
  103003:	74 24                	je     103029 <proc_run+0x5a>
  103005:	c7 44 24 0c fa 87 10 	movl   $0x1087fa,0xc(%esp)
  10300c:	00 
  10300d:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  103014:	00 
  103015:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
  10301c:	00 
  10301d:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  103024:	e8 58 d4 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  103029:	8b 45 08             	mov    0x8(%ebp),%eax
  10302c:	89 04 24             	mov    %eax,(%esp)
  10302f:	e8 d9 f2 ff ff       	call   10230d <spinlock_acquire>

	cpu* c = cpu_cur();
  103034:	e8 6b f9 ff ff       	call   1029a4 <cpu_cur>
  103039:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->proc = p;
  10303c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10303f:	8b 55 08             	mov    0x8(%ebp),%edx
  103042:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	p->state = PROC_RUN;
  103048:	8b 45 08             	mov    0x8(%ebp),%eax
  10304b:	c7 80 40 04 00 00 02 	movl   $0x2,0x440(%eax)
  103052:	00 00 00 
	p->runcpu = c;
  103055:	8b 45 08             	mov    0x8(%ebp),%eax
  103058:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10305b:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  103061:	8b 45 08             	mov    0x8(%ebp),%eax
  103064:	89 04 24             	mov    %eax,(%esp)
  103067:	e8 0e f3 ff ff       	call   10237a <spinlock_release>

	//cprintf("eip = %d\n", p->sv.tf.eip);
	
	trap_return(&p->sv.tf);
  10306c:	8b 45 08             	mov    0x8(%ebp),%eax
  10306f:	05 50 04 00 00       	add    $0x450,%eax
  103074:	89 04 24             	mov    %eax,(%esp)
  103077:	e8 74 80 00 00       	call   10b0f0 <trap_return>

0010307c <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  10307c:	55                   	push   %ebp
  10307d:	89 e5                	mov    %esp,%ebp
  10307f:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_yield not implemented");

 	//cprintf("in yield\n");
	proc* cur_proc = cpu_cur()->proc;
  103082:	e8 1d f9 ff ff       	call   1029a4 <cpu_cur>
  103087:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10308d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	proc_save(cur_proc, tf, 1);
  103090:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  103097:	00 
  103098:	8b 45 08             	mov    0x8(%ebp),%eax
  10309b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10309f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030a2:	89 04 24             	mov    %eax,(%esp)
  1030a5:	e8 ed fc ff ff       	call   102d97 <proc_save>
	proc_ready(cur_proc);
  1030aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030ad:	89 04 24             	mov    %eax,(%esp)
  1030b0:	e8 ff fb ff ff       	call   102cb4 <proc_ready>
	proc_sched();
  1030b5:	e8 52 fe ff ff       	call   102f0c <proc_sched>

001030ba <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  1030ba:	55                   	push   %ebp
  1030bb:	89 e5                	mov    %esp,%ebp
  1030bd:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_ret not implemented");

	proc* proc_child = proc_cur();
  1030c0:	e8 df f8 ff ff       	call   1029a4 <cpu_cur>
  1030c5:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_parent = proc_child->parent;
  1030ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030d1:	8b 40 3c             	mov    0x3c(%eax),%eax
  1030d4:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child->state != PROC_STOP);
  1030d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030da:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  1030e0:	85 c0                	test   %eax,%eax
  1030e2:	75 24                	jne    103108 <proc_ret+0x4e>
  1030e4:	c7 44 24 0c 14 88 10 	movl   $0x108814,0xc(%esp)
  1030eb:	00 
  1030ec:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  1030f3:	00 
  1030f4:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
  1030fb:	00 
  1030fc:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  103103:	e8 79 d3 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  103108:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10310b:	89 04 24             	mov    %eax,(%esp)
  10310e:	e8 fa f1 ff ff       	call   10230d <spinlock_acquire>
	proc_child->state = PROC_STOP;
  103113:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103116:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  10311d:	00 00 00 
	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  103120:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103123:	89 04 24             	mov    %eax,(%esp)
  103126:	e8 4f f2 ff ff       	call   10237a <spinlock_release>

	proc_save(proc_child, tf, entry);
  10312b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10312e:	89 44 24 08          	mov    %eax,0x8(%esp)
  103132:	8b 45 08             	mov    0x8(%ebp),%eax
  103135:	89 44 24 04          	mov    %eax,0x4(%esp)
  103139:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10313c:	89 04 24             	mov    %eax,(%esp)
  10313f:	e8 53 fc ff ff       	call   102d97 <proc_save>

	if((proc_parent->state == PROC_WAIT) && (proc_parent->waitchild == proc_child) )
  103144:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103147:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  10314d:	83 f8 03             	cmp    $0x3,%eax
  103150:	75 19                	jne    10316b <proc_ret+0xb1>
  103152:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103155:	8b 80 4c 04 00 00    	mov    0x44c(%eax),%eax
  10315b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10315e:	75 0b                	jne    10316b <proc_ret+0xb1>
		proc_ready(proc_parent);
  103160:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103163:	89 04 24             	mov    %eax,(%esp)
  103166:	e8 49 fb ff ff       	call   102cb4 <proc_ready>

	proc_sched();
  10316b:	e8 9c fd ff ff       	call   102f0c <proc_sched>

00103170 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  103170:	55                   	push   %ebp
  103171:	89 e5                	mov    %esp,%ebp
  103173:	57                   	push   %edi
  103174:	56                   	push   %esi
  103175:	53                   	push   %ebx
  103176:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  10317c:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103183:	00 00 00 
  103186:	e9 06 01 00 00       	jmp    103291 <proc_check+0x121>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  10318b:	b8 90 9c 11 00       	mov    $0x119c90,%eax
  103190:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  103196:	83 c2 01             	add    $0x1,%edx
  103199:	c1 e2 0c             	shl    $0xc,%edx
  10319c:	01 d0                	add    %edx,%eax
  10319e:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		*--esp = i;	// push argument to child() function
  1031a4:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  1031ab:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  1031b1:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  1031b7:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  1031b9:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  1031c0:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  1031c6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  1031cc:	b8 a9 36 10 00       	mov    $0x1036a9,%eax
  1031d1:	a3 78 9a 11 00       	mov    %eax,0x119a78
		child_state.tf.esp = (uint32_t) esp;
  1031d6:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  1031dc:	a3 84 9a 11 00       	mov    %eax,0x119a84

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  1031e1:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1031e7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1031eb:	c7 04 24 33 88 10 00 	movl   $0x108833,(%esp)
  1031f2:	e8 8b 42 00 00       	call   107482 <cprintf>

		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  1031f7:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1031fd:	0f b7 d0             	movzwl %ax,%edx
  103200:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  103207:	7f 07                	jg     103210 <proc_check+0xa0>
  103209:	b8 10 10 00 00       	mov    $0x1010,%eax
  10320e:	eb 05                	jmp    103215 <proc_check+0xa5>
  103210:	b8 00 10 00 00       	mov    $0x1000,%eax
  103215:	89 85 54 ff ff ff    	mov    %eax,-0xac(%ebp)
  10321b:	66 89 95 52 ff ff ff 	mov    %dx,-0xae(%ebp)
  103222:	c7 85 4c ff ff ff 40 	movl   $0x119a40,-0xb4(%ebp)
  103229:	9a 11 00 
  10322c:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
  103233:	00 00 00 
  103236:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
  10323d:	00 00 00 
  103240:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
  103247:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  10324a:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
  103250:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103253:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
  103259:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
  103260:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
  103266:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
  10326c:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
  103272:	cd 30                	int    $0x30
			NULL, NULL, 0);
		
		cprintf("i == %d complete!\n", i);
  103274:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10327a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10327e:	c7 04 24 46 88 10 00 	movl   $0x108846,(%esp)
  103285:	e8 f8 41 00 00       	call   107482 <cprintf>
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  10328a:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103291:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103298:	0f 8e ed fe ff ff    	jle    10318b <proc_check+0x1b>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  10329e:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  1032a5:	00 00 00 
  1032a8:	e9 89 00 00 00       	jmp    103336 <proc_check+0x1c6>
		cprintf("waiting for child %d\n", i);
  1032ad:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1032b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1032b7:	c7 04 24 59 88 10 00 	movl   $0x108859,(%esp)
  1032be:	e8 bf 41 00 00       	call   107482 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  1032c3:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1032c9:	0f b7 c0             	movzwl %ax,%eax
  1032cc:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
  1032d3:	10 00 00 
  1032d6:	66 89 85 6a ff ff ff 	mov    %ax,-0x96(%ebp)
  1032dd:	c7 85 64 ff ff ff 40 	movl   $0x119a40,-0x9c(%ebp)
  1032e4:	9a 11 00 
  1032e7:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
  1032ee:	00 00 00 
  1032f1:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
  1032f8:	00 00 00 
  1032fb:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
  103302:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103305:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
  10330b:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10330e:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
  103314:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
  10331b:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
  103321:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
  103327:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
  10332d:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  10332f:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103336:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  10333d:	0f 8e 6a ff ff ff    	jle    1032ad <proc_check+0x13d>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  103343:	c7 04 24 70 88 10 00 	movl   $0x108870,(%esp)
  10334a:	e8 33 41 00 00       	call   107482 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  10334f:	c7 04 24 98 88 10 00 	movl   $0x108898,(%esp)
  103356:	e8 27 41 00 00       	call   107482 <cprintf>
	for (i = 0; i < 4; i++) {
  10335b:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103362:	00 00 00 
  103365:	eb 7d                	jmp    1033e4 <proc_check+0x274>
		cprintf("spawning child %d\n", i);
  103367:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10336d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103371:	c7 04 24 33 88 10 00 	movl   $0x108833,(%esp)
  103378:	e8 05 41 00 00       	call   107482 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  10337d:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103383:	0f b7 c0             	movzwl %ax,%eax
  103386:	c7 45 84 10 00 00 00 	movl   $0x10,-0x7c(%ebp)
  10338d:	66 89 45 82          	mov    %ax,-0x7e(%ebp)
  103391:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  103398:	00 00 00 
  10339b:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
  1033a2:	00 00 00 
  1033a5:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
  1033ac:	00 00 00 
  1033af:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
  1033b6:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1033b9:	8b 45 84             	mov    -0x7c(%ebp),%eax
  1033bc:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1033bf:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
  1033c5:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
  1033c9:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
  1033cf:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
  1033d5:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
  1033db:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  1033dd:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  1033e4:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  1033eb:	0f 8e 76 ff ff ff    	jle    103367 <proc_check+0x1f7>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
  1033f1:	c7 04 24 bc 88 10 00 	movl   $0x1088bc,(%esp)
  1033f8:	e8 85 40 00 00       	call   107482 <cprintf>
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  1033fd:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103404:	00 00 00 
  103407:	eb 4f                	jmp    103458 <proc_check+0x2e8>
		sys_get(0, i, NULL, NULL, NULL, 0);
  103409:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10340f:	0f b7 c0             	movzwl %ax,%eax
  103412:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  103419:	66 89 45 9a          	mov    %ax,-0x66(%ebp)
  10341d:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
  103424:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  10342b:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
  103432:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103439:	8b 45 9c             	mov    -0x64(%ebp),%eax
  10343c:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10343f:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
  103442:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
  103446:	8b 75 90             	mov    -0x70(%ebp),%esi
  103449:	8b 7d 8c             	mov    -0x74(%ebp),%edi
  10344c:	8b 4d 88             	mov    -0x78(%ebp),%ecx
  10344f:	cd 30                	int    $0x30
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103451:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103458:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  10345f:	7e a8                	jle    103409 <proc_check+0x299>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  103461:	c7 04 24 e4 88 10 00 	movl   $0x1088e4,(%esp)
  103468:	e8 15 40 00 00       	call   107482 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  10346d:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103474:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103477:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10347d:	0f b7 c0             	movzwl %ax,%eax
  103480:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
  103487:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
  10348b:	c7 45 ac 40 9a 11 00 	movl   $0x119a40,-0x54(%ebp)
  103492:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  103499:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  1034a0:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1034a7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  1034aa:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1034ad:	8b 5d ac             	mov    -0x54(%ebp),%ebx
  1034b0:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
  1034b4:	8b 75 a8             	mov    -0x58(%ebp),%esi
  1034b7:	8b 7d a4             	mov    -0x5c(%ebp),%edi
  1034ba:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  1034bd:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  1034bf:	a1 94 dc 11 00       	mov    0x11dc94,%eax
  1034c4:	85 c0                	test   %eax,%eax
  1034c6:	74 24                	je     1034ec <proc_check+0x37c>
  1034c8:	c7 44 24 0c 09 89 10 	movl   $0x108909,0xc(%esp)
  1034cf:	00 
  1034d0:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  1034d7:	00 
  1034d8:	c7 44 24 04 92 01 00 	movl   $0x192,0x4(%esp)
  1034df:	00 
  1034e0:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  1034e7:	e8 95 cf ff ff       	call   100481 <debug_panic>
	cprintf("============== tag 1 \n");
  1034ec:	c7 04 24 1b 89 10 00 	movl   $0x10891b,(%esp)
  1034f3:	e8 8a 3f 00 00       	call   107482 <cprintf>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  1034f8:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1034fe:	0f b7 c0             	movzwl %ax,%eax
  103501:	c7 45 cc 10 10 00 00 	movl   $0x1010,-0x34(%ebp)
  103508:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
  10350c:	c7 45 c4 40 9a 11 00 	movl   $0x119a40,-0x3c(%ebp)
  103513:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
  10351a:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  103521:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103528:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10352b:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10352e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
  103531:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  103535:	8b 75 c0             	mov    -0x40(%ebp),%esi
  103538:	8b 7d bc             	mov    -0x44(%ebp),%edi
  10353b:	8b 4d b8             	mov    -0x48(%ebp),%ecx
  10353e:	cd 30                	int    $0x30
		//cprintf("(1). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103540:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103546:	0f b7 c0             	movzwl %ax,%eax
  103549:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  103550:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
  103554:	c7 45 dc 40 9a 11 00 	movl   $0x119a40,-0x24(%ebp)
  10355b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103562:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  103569:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103570:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103573:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103576:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  103579:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  10357d:	8b 75 d8             	mov    -0x28(%ebp),%esi
  103580:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  103583:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  103586:	cd 30                	int    $0x30
		//cprintf("(2). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		cprintf("recovargs 0x%x\n",recovargs);
  103588:	a1 94 dc 11 00       	mov    0x11dc94,%eax
  10358d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103591:	c7 04 24 32 89 10 00 	movl   $0x108932,(%esp)
  103598:	e8 e5 3e 00 00       	call   107482 <cprintf>
		
		if (recovargs) {	// trap recovery needed
  10359d:	a1 94 dc 11 00       	mov    0x11dc94,%eax
  1035a2:	85 c0                	test   %eax,%eax
  1035a4:	74 55                	je     1035fb <proc_check+0x48b>
			cprintf("i = %d\n", i);
  1035a6:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1035ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035b0:	c7 04 24 42 89 10 00 	movl   $0x108942,(%esp)
  1035b7:	e8 c6 3e 00 00       	call   107482 <cprintf>
			trap_check_args *argss = recovargs;
  1035bc:	a1 94 dc 11 00       	mov    0x11dc94,%eax
  1035c1:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)
			cprintf("recover from trap %d\n",
  1035c7:	a1 70 9a 11 00       	mov    0x119a70,%eax
  1035cc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035d0:	c7 04 24 4a 89 10 00 	movl   $0x10894a,(%esp)
  1035d7:	e8 a6 3e 00 00       	call   107482 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) argss->reip;
  1035dc:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  1035e2:	8b 00                	mov    (%eax),%eax
  1035e4:	a3 78 9a 11 00       	mov    %eax,0x119a78
			argss->trapno = child_state.tf.trapno;
  1035e9:	a1 70 9a 11 00       	mov    0x119a70,%eax
  1035ee:	89 c2                	mov    %eax,%edx
  1035f0:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  1035f6:	89 50 04             	mov    %edx,0x4(%eax)
  1035f9:	eb 2e                	jmp    103629 <proc_check+0x4b9>
			//cprintf(">>>>>args->trapno = %d, child_state.tf.trapno = %d\n", 
			//	args->trapno, child_state.tf.trapno);
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  1035fb:	a1 70 9a 11 00       	mov    0x119a70,%eax
  103600:	83 f8 30             	cmp    $0x30,%eax
  103603:	74 24                	je     103629 <proc_check+0x4b9>
  103605:	c7 44 24 0c 60 89 10 	movl   $0x108960,0xc(%esp)
  10360c:	00 
  10360d:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  103614:	00 
  103615:	c7 44 24 04 a5 01 00 	movl   $0x1a5,0x4(%esp)
  10361c:	00 
  10361d:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  103624:	e8 58 ce ff ff       	call   100481 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  103629:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10362f:	8d 50 01             	lea    0x1(%eax),%edx
  103632:	89 d0                	mov    %edx,%eax
  103634:	c1 f8 1f             	sar    $0x1f,%eax
  103637:	c1 e8 1e             	shr    $0x1e,%eax
  10363a:	01 c2                	add    %eax,%edx
  10363c:	83 e2 03             	and    $0x3,%edx
  10363f:	89 d1                	mov    %edx,%ecx
  103641:	29 c1                	sub    %eax,%ecx
  103643:	89 c8                	mov    %ecx,%eax
  103645:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  10364b:	a1 70 9a 11 00       	mov    0x119a70,%eax
  103650:	83 f8 30             	cmp    $0x30,%eax
  103653:	0f 85 9f fe ff ff    	jne    1034f8 <proc_check+0x388>
	assert(recovargs == NULL);
  103659:	a1 94 dc 11 00       	mov    0x11dc94,%eax
  10365e:	85 c0                	test   %eax,%eax
  103660:	74 24                	je     103686 <proc_check+0x516>
  103662:	c7 44 24 0c 09 89 10 	movl   $0x108909,0xc(%esp)
  103669:	00 
  10366a:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  103671:	00 
  103672:	c7 44 24 04 a8 01 00 	movl   $0x1a8,0x4(%esp)
  103679:	00 
  10367a:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  103681:	e8 fb cd ff ff       	call   100481 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  103686:	c7 04 24 84 89 10 00 	movl   $0x108984,(%esp)
  10368d:	e8 f0 3d 00 00       	call   107482 <cprintf>

	cprintf("proc_check() succeeded!\n");
  103692:	c7 04 24 b1 89 10 00 	movl   $0x1089b1,(%esp)
  103699:	e8 e4 3d 00 00       	call   107482 <cprintf>
}
  10369e:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  1036a4:	5b                   	pop    %ebx
  1036a5:	5e                   	pop    %esi
  1036a6:	5f                   	pop    %edi
  1036a7:	5d                   	pop    %ebp
  1036a8:	c3                   	ret    

001036a9 <child>:

static void child(int n)
{
  1036a9:	55                   	push   %ebp
  1036aa:	89 e5                	mov    %esp,%ebp
  1036ac:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  1036af:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  1036b3:	7f 64                	jg     103719 <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  1036b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1036bc:	eb 4e                	jmp    10370c <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  1036be:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1036c1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1036c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1036c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036cc:	c7 04 24 ca 89 10 00 	movl   $0x1089ca,(%esp)
  1036d3:	e8 aa 3d 00 00       	call   107482 <cprintf>
			while (pingpong != n){
  1036d8:	eb 05                	jmp    1036df <child+0x36>
				//cprintf("in pingpong = %d\n", pingpong);
				pause();
  1036da:	e8 be f2 ff ff       	call   10299d <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n){
  1036df:	8b 55 08             	mov    0x8(%ebp),%edx
  1036e2:	a1 90 dc 11 00       	mov    0x11dc90,%eax
  1036e7:	39 c2                	cmp    %eax,%edx
  1036e9:	75 ef                	jne    1036da <child+0x31>
				//cprintf("in pingpong = %d\n", pingpong);
				pause();
			}
			xchg(&pingpong, !pingpong);
  1036eb:	a1 90 dc 11 00       	mov    0x11dc90,%eax
  1036f0:	85 c0                	test   %eax,%eax
  1036f2:	0f 94 c0             	sete   %al
  1036f5:	0f b6 c0             	movzbl %al,%eax
  1036f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036fc:	c7 04 24 90 dc 11 00 	movl   $0x11dc90,(%esp)
  103703:	e8 6a f2 ff ff       	call   102972 <xchg>
{
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  103708:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10370c:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  103710:	7e ac                	jle    1036be <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  103712:	b8 03 00 00 00       	mov    $0x3,%eax
  103717:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103719:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103720:	eb 47                	jmp    103769 <child+0xc0>
		//cprintf("in child %d count %d\n", n, i);
		cprintf("child num:%d\n", queue.count);
  103722:	a1 78 e4 31 00       	mov    0x31e478,%eax
  103727:	89 44 24 04          	mov    %eax,0x4(%esp)
  10372b:	c7 04 24 e0 89 10 00 	movl   $0x1089e0,(%esp)
  103732:	e8 4b 3d 00 00       	call   107482 <cprintf>
		
		while (pingpong != n){
  103737:	eb 05                	jmp    10373e <child+0x95>
			//cprintf("in pingpong = %d\n", pingpong);
			pause();
  103739:	e8 5f f2 ff ff       	call   10299d <pause>
	int i;
	for (i = 0; i < 10; i++) {
		//cprintf("in child %d count %d\n", n, i);
		cprintf("child num:%d\n", queue.count);
		
		while (pingpong != n){
  10373e:	8b 55 08             	mov    0x8(%ebp),%edx
  103741:	a1 90 dc 11 00       	mov    0x11dc90,%eax
  103746:	39 c2                	cmp    %eax,%edx
  103748:	75 ef                	jne    103739 <child+0x90>
			//cprintf("in pingpong = %d\n", pingpong);
			pause();
		}
		xchg(&pingpong, (pingpong + 1) % 4);
  10374a:	a1 90 dc 11 00       	mov    0x11dc90,%eax
  10374f:	83 c0 01             	add    $0x1,%eax
  103752:	83 e0 03             	and    $0x3,%eax
  103755:	89 44 24 04          	mov    %eax,0x4(%esp)
  103759:	c7 04 24 90 dc 11 00 	movl   $0x11dc90,(%esp)
  103760:	e8 0d f2 ff ff       	call   102972 <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103765:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103769:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  10376d:	7e b3                	jle    103722 <child+0x79>
  10376f:	b8 03 00 00 00       	mov    $0x3,%eax
  103774:	cd 30                	int    $0x30
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...

	cprintf("child get last test\n");
  103776:	c7 04 24 ee 89 10 00 	movl   $0x1089ee,(%esp)
  10377d:	e8 00 3d 00 00       	call   107482 <cprintf>
	if (n == 0) {
  103782:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103786:	75 6d                	jne    1037f5 <child+0x14c>
		assert(recovargs == NULL);
  103788:	a1 94 dc 11 00       	mov    0x11dc94,%eax
  10378d:	85 c0                	test   %eax,%eax
  10378f:	74 24                	je     1037b5 <child+0x10c>
  103791:	c7 44 24 0c 09 89 10 	movl   $0x108909,0xc(%esp)
  103798:	00 
  103799:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  1037a0:	00 
  1037a1:	c7 44 24 04 d5 01 00 	movl   $0x1d5,0x4(%esp)
  1037a8:	00 
  1037a9:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  1037b0:	e8 cc cc ff ff       	call   100481 <debug_panic>
		trap_check(&recovargs);
  1037b5:	c7 04 24 94 dc 11 00 	movl   $0x11dc94,(%esp)
  1037bc:	e8 6c e2 ff ff       	call   101a2d <trap_check>
		assert(recovargs == NULL);
  1037c1:	a1 94 dc 11 00       	mov    0x11dc94,%eax
  1037c6:	85 c0                	test   %eax,%eax
  1037c8:	74 24                	je     1037ee <child+0x145>
  1037ca:	c7 44 24 0c 09 89 10 	movl   $0x108909,0xc(%esp)
  1037d1:	00 
  1037d2:	c7 44 24 08 66 86 10 	movl   $0x108666,0x8(%esp)
  1037d9:	00 
  1037da:	c7 44 24 04 d7 01 00 	movl   $0x1d7,0x4(%esp)
  1037e1:	00 
  1037e2:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  1037e9:	e8 93 cc ff ff       	call   100481 <debug_panic>
  1037ee:	b8 03 00 00 00       	mov    $0x3,%eax
  1037f3:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  1037f5:	c7 44 24 08 04 8a 10 	movl   $0x108a04,0x8(%esp)
  1037fc:	00 
  1037fd:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
  103804:	00 
  103805:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  10380c:	e8 70 cc ff ff       	call   100481 <debug_panic>

00103811 <grandchild>:
}

static void grandchild(int n)
{
  103811:	55                   	push   %ebp
  103812:	89 e5                	mov    %esp,%ebp
  103814:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  103817:	c7 44 24 08 28 8a 10 	movl   $0x108a28,0x8(%esp)
  10381e:	00 
  10381f:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
  103826:	00 
  103827:	c7 04 24 c6 86 10 00 	movl   $0x1086c6,(%esp)
  10382e:	e8 4e cc ff ff       	call   100481 <debug_panic>

00103833 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103833:	55                   	push   %ebp
  103834:	89 e5                	mov    %esp,%ebp
  103836:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103839:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10383c:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10383f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103842:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103845:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10384a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10384d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103850:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103856:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10385b:	74 24                	je     103881 <cpu_cur+0x4e>
  10385d:	c7 44 24 0c 54 8a 10 	movl   $0x108a54,0xc(%esp)
  103864:	00 
  103865:	c7 44 24 08 6a 8a 10 	movl   $0x108a6a,0x8(%esp)
  10386c:	00 
  10386d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103874:	00 
  103875:	c7 04 24 7f 8a 10 00 	movl   $0x108a7f,(%esp)
  10387c:	e8 00 cc ff ff       	call   100481 <debug_panic>
	return c;
  103881:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103884:	c9                   	leave  
  103885:	c3                   	ret    

00103886 <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  103886:	55                   	push   %ebp
  103887:	89 e5                	mov    %esp,%ebp
  103889:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  10388c:	c7 44 24 08 8c 8a 10 	movl   $0x108a8c,0x8(%esp)
  103893:	00 
  103894:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  10389b:	00 
  10389c:	c7 04 24 a7 8a 10 00 	movl   $0x108aa7,(%esp)
  1038a3:	e8 d9 cb ff ff       	call   100481 <debug_panic>

001038a8 <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  1038a8:	55                   	push   %ebp
  1038a9:	89 e5                	mov    %esp,%ebp
  1038ab:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  1038ae:	c7 44 24 08 b6 8a 10 	movl   $0x108ab6,0x8(%esp)
  1038b5:	00 
  1038b6:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  1038bd:	00 
  1038be:	c7 04 24 a7 8a 10 00 	movl   $0x108aa7,(%esp)
  1038c5:	e8 b7 cb ff ff       	call   100481 <debug_panic>

001038ca <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  1038ca:	55                   	push   %ebp
  1038cb:	89 e5                	mov    %esp,%ebp
  1038cd:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  1038d0:	c7 44 24 08 d4 8a 10 	movl   $0x108ad4,0x8(%esp)
  1038d7:	00 
  1038d8:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  1038df:	00 
  1038e0:	c7 04 24 a7 8a 10 00 	movl   $0x108aa7,(%esp)
  1038e7:	e8 95 cb ff ff       	call   100481 <debug_panic>

001038ec <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  1038ec:	55                   	push   %ebp
  1038ed:	89 e5                	mov    %esp,%ebp
  1038ef:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  1038f2:	8b 45 18             	mov    0x18(%ebp),%eax
  1038f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  1038f9:	8b 45 14             	mov    0x14(%ebp),%eax
  1038fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  103900:	8b 45 08             	mov    0x8(%ebp),%eax
  103903:	89 04 24             	mov    %eax,(%esp)
  103906:	e8 bf ff ff ff       	call   1038ca <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  10390b:	c7 44 24 08 f0 8a 10 	movl   $0x108af0,0x8(%esp)
  103912:	00 
  103913:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  10391a:	00 
  10391b:	c7 04 24 a7 8a 10 00 	movl   $0x108aa7,(%esp)
  103922:	e8 5a cb ff ff       	call   100481 <debug_panic>

00103927 <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  103927:	55                   	push   %ebp
  103928:	89 e5                	mov    %esp,%ebp
  10392a:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  10392d:	8b 45 08             	mov    0x8(%ebp),%eax
  103930:	8b 40 10             	mov    0x10(%eax),%eax
  103933:	89 44 24 04          	mov    %eax,0x4(%esp)
  103937:	c7 04 24 14 8b 10 00 	movl   $0x108b14,(%esp)
  10393e:	e8 3f 3b 00 00       	call   107482 <cprintf>

	trap_return(tf);	// syscall completed
  103943:	8b 45 08             	mov    0x8(%ebp),%eax
  103946:	89 04 24             	mov    %eax,(%esp)
  103949:	e8 a2 77 00 00       	call   10b0f0 <trap_return>

0010394e <do_put>:
}


static void
do_put(trapframe *tf, uint32_t cmd)
{	
  10394e:	55                   	push   %ebp
  10394f:	89 e5                	mov    %esp,%ebp
  103951:	83 ec 28             	sub    $0x28,%esp
	cprintf("process %p is in do_put()\n", proc_cur());
  103954:	e8 da fe ff ff       	call   103833 <cpu_cur>
  103959:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10395f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103963:	c7 04 24 17 8b 10 00 	movl   $0x108b17,(%esp)
  10396a:	e8 13 3b 00 00       	call   107482 <cprintf>
	
	procstate* ps = (procstate*)tf->regs.ebx;
  10396f:	8b 45 08             	mov    0x8(%ebp),%eax
  103972:	8b 40 10             	mov    0x10(%eax),%eax
  103975:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint16_t child_num = tf->regs.edx;
  103978:	8b 45 08             	mov    0x8(%ebp),%eax
  10397b:	8b 40 14             	mov    0x14(%eax),%eax
  10397e:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
	proc* proc_parent = proc_cur();
  103982:	e8 ac fe ff ff       	call   103833 <cpu_cur>
  103987:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10398d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103990:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  103994:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103997:	83 c2 10             	add    $0x10,%edx
  10399a:	8b 04 90             	mov    (%eax,%edx,4),%eax
  10399d:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(proc_child == NULL){
  1039a0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1039a4:	75 38                	jne    1039de <do_put+0x90>
		proc_child = proc_alloc(proc_parent, child_num);
  1039a6:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
  1039aa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1039ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039b1:	89 04 24             	mov    %eax,(%esp)
  1039b4:	e8 21 f1 ff ff       	call   102ada <proc_alloc>
  1039b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if(proc_child == NULL)
  1039bc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1039c0:	75 1c                	jne    1039de <do_put+0x90>
			panic("no child proc!");
  1039c2:	c7 44 24 08 32 8b 10 	movl   $0x108b32,0x8(%esp)
  1039c9:	00 
  1039ca:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
  1039d1:	00 
  1039d2:	c7 04 24 a7 8a 10 00 	movl   $0x108aa7,(%esp)
  1039d9:	e8 a3 ca ff ff       	call   100481 <debug_panic>
	}
	
	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  1039de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039e1:	89 04 24             	mov    %eax,(%esp)
  1039e4:	e8 24 e9 ff ff       	call   10230d <spinlock_acquire>
	if(proc_child->state != PROC_STOP){
  1039e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039ec:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  1039f2:	85 c0                	test   %eax,%eax
  1039f4:	74 24                	je     103a1a <do_put+0xcc>
		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  1039f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039f9:	89 04 24             	mov    %eax,(%esp)
  1039fc:	e8 79 e9 ff ff       	call   10237a <spinlock_release>
		proc_wait(proc_parent, proc_child, tf);
  103a01:	8b 45 08             	mov    0x8(%ebp),%eax
  103a04:	89 44 24 08          	mov    %eax,0x8(%esp)
  103a08:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a0b:	89 44 24 04          	mov    %eax,0x4(%esp)
  103a0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103a12:	89 04 24             	mov    %eax,(%esp)
  103a15:	e8 1b f4 ff ff       	call   102e35 <proc_wait>
	}

	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  103a1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a1d:	89 04 24             	mov    %eax,(%esp)
  103a20:	e8 55 e9 ff ff       	call   10237a <spinlock_release>

	if(tf->regs.eax & SYS_REGS){	
  103a25:	8b 45 08             	mov    0x8(%ebp),%eax
  103a28:	8b 40 1c             	mov    0x1c(%eax),%eax
  103a2b:	25 00 10 00 00       	and    $0x1000,%eax
  103a30:	85 c0                	test   %eax,%eax
  103a32:	0f 84 c4 00 00 00    	je     103afc <do_put+0x1ae>
		//proc_print(ACQUIRE, proc_child);
		spinlock_acquire(&proc_child->lock);
  103a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a3b:	89 04 24             	mov    %eax,(%esp)
  103a3e:	e8 ca e8 ff ff       	call   10230d <spinlock_acquire>
		/*
		if(((proc_child->sv.tf.eflags ^ ps->tf.eflags) | FL_USER) != FL_USER)
			panic("illegal modification of eflags!");
		*/
		
		proc_child->sv.tf.eip = ps->tf.eip;
  103a43:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a46:	8b 50 38             	mov    0x38(%eax),%edx
  103a49:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a4c:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_child->sv.tf.esp = ps->tf.esp;
  103a52:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a55:	8b 50 44             	mov    0x44(%eax),%edx
  103a58:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a5b:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
  103a61:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a64:	8b 50 08             	mov    0x8(%eax),%edx
  103a67:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a6a:	89 90 58 04 00 00    	mov    %edx,0x458(%eax)
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
  103a70:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a73:	8b 40 44             	mov    0x44(%eax),%eax
  103a76:	89 44 24 04          	mov    %eax,0x4(%esp)
  103a7a:	c7 04 24 44 8b 10 00 	movl   $0x108b44,(%esp)
  103a81:	e8 fc 39 00 00       	call   107482 <cprintf>
		proc_child->sv.tf.trapno = ps->tf.trapno;
  103a86:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a89:	8b 50 30             	mov    0x30(%eax),%edx
  103a8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a8f:	89 90 80 04 00 00    	mov    %edx,0x480(%eax)

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
  103a95:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a98:	0f b7 80 8c 04 00 00 	movzwl 0x48c(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103a9f:	66 83 f8 1b          	cmp    $0x1b,%ax
  103aa3:	75 30                	jne    103ad5 <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
  103aa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103aa8:	0f b7 80 7c 04 00 00 	movzwl 0x47c(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103aaf:	66 83 f8 23          	cmp    $0x23,%ax
  103ab3:	75 20                	jne    103ad5 <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ab8:	0f b7 80 78 04 00 00 	movzwl 0x478(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103abf:	66 83 f8 23          	cmp    $0x23,%ax
  103ac3:	75 10                	jne    103ad5 <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103ac5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ac8:	0f b7 80 98 04 00 00 	movzwl 0x498(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103acf:	66 83 f8 23          	cmp    $0x23,%ax
  103ad3:	74 1c                	je     103af1 <do_put+0x1a3>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
			panic("wrong segment regs values!");
  103ad5:	c7 44 24 08 66 8b 10 	movl   $0x108b66,0x8(%esp)
  103adc:	00 
  103add:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  103ae4:	00 
  103ae5:	c7 04 24 a7 8a 10 00 	movl   $0x108aa7,(%esp)
  103aec:	e8 90 c9 ff ff       	call   100481 <debug_panic>

		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  103af1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103af4:	89 04 24             	mov    %eax,(%esp)
  103af7:	e8 7e e8 ff ff       	call   10237a <spinlock_release>
	}
    if(tf->regs.eax & SYS_START){
  103afc:	8b 45 08             	mov    0x8(%ebp),%eax
  103aff:	8b 40 1c             	mov    0x1c(%eax),%eax
  103b02:	83 e0 10             	and    $0x10,%eax
  103b05:	85 c0                	test   %eax,%eax
  103b07:	74 0b                	je     103b14 <do_put+0x1c6>
		//cprintf("in SYS_START\n");
		proc_ready(proc_child);
  103b09:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b0c:	89 04 24             	mov    %eax,(%esp)
  103b0f:	e8 a0 f1 ff ff       	call   102cb4 <proc_ready>
	}
	
	trap_return(tf);
  103b14:	8b 45 08             	mov    0x8(%ebp),%eax
  103b17:	89 04 24             	mov    %eax,(%esp)
  103b1a:	e8 d1 75 00 00       	call   10b0f0 <trap_return>

00103b1f <do_get>:
}

static void
do_get(trapframe *tf, uint32_t cmd)
{	
  103b1f:	55                   	push   %ebp
  103b20:	89 e5                	mov    %esp,%ebp
  103b22:	83 ec 28             	sub    $0x28,%esp
	cprintf("process %p is in do_get()\n", proc_cur());
  103b25:	e8 09 fd ff ff       	call   103833 <cpu_cur>
  103b2a:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103b30:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b34:	c7 04 24 81 8b 10 00 	movl   $0x108b81,(%esp)
  103b3b:	e8 42 39 00 00       	call   107482 <cprintf>
	
	procstate* ps = (procstate*)tf->regs.ebx;
  103b40:	8b 45 08             	mov    0x8(%ebp),%eax
  103b43:	8b 40 10             	mov    0x10(%eax),%eax
  103b46:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int child_num = (int)tf->regs.edx;
  103b49:	8b 45 08             	mov    0x8(%ebp),%eax
  103b4c:	8b 40 14             	mov    0x14(%eax),%eax
  103b4f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	proc* proc_parent = proc_cur();
  103b52:	e8 dc fc ff ff       	call   103833 <cpu_cur>
  103b57:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103b5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103b60:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103b63:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b66:	83 c2 10             	add    $0x10,%edx
  103b69:	8b 04 90             	mov    (%eax,%edx,4),%eax
  103b6c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child != NULL);
  103b6f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103b73:	75 24                	jne    103b99 <do_get+0x7a>
  103b75:	c7 44 24 0c 9c 8b 10 	movl   $0x108b9c,0xc(%esp)
  103b7c:	00 
  103b7d:	c7 44 24 08 6a 8a 10 	movl   $0x108a6a,0x8(%esp)
  103b84:	00 
  103b85:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  103b8c:	00 
  103b8d:	c7 04 24 a7 8a 10 00 	movl   $0x108aa7,(%esp)
  103b94:	e8 e8 c8 ff ff       	call   100481 <debug_panic>

	if(proc_child->state != PROC_STOP){
  103b99:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b9c:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103ba2:	85 c0                	test   %eax,%eax
  103ba4:	74 25                	je     103bcb <do_get+0xac>
		cprintf("into proc_wait\n");
  103ba6:	c7 04 24 af 8b 10 00 	movl   $0x108baf,(%esp)
  103bad:	e8 d0 38 00 00       	call   107482 <cprintf>
		proc_wait(proc_parent, proc_child, tf);}
  103bb2:	8b 45 08             	mov    0x8(%ebp),%eax
  103bb5:	89 44 24 08          	mov    %eax,0x8(%esp)
  103bb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103bbc:	89 44 24 04          	mov    %eax,0x4(%esp)
  103bc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103bc3:	89 04 24             	mov    %eax,(%esp)
  103bc6:	e8 6a f2 ff ff       	call   102e35 <proc_wait>

	if(tf->regs.eax & SYS_REGS){
  103bcb:	8b 45 08             	mov    0x8(%ebp),%eax
  103bce:	8b 40 1c             	mov    0x1c(%eax),%eax
  103bd1:	25 00 10 00 00       	and    $0x1000,%eax
  103bd6:	85 c0                	test   %eax,%eax
  103bd8:	74 20                	je     103bfa <do_get+0xdb>
		memmove(&(ps->tf), &(proc_child->sv.tf), sizeof(trapframe));
  103bda:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103bdd:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  103be3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103be6:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  103bed:	00 
  103bee:	89 54 24 04          	mov    %edx,0x4(%esp)
  103bf2:	89 04 24             	mov    %eax,(%esp)
  103bf5:	e8 e1 3a 00 00       	call   1076db <memmove>
	}
	
	trap_return(tf);
  103bfa:	8b 45 08             	mov    0x8(%ebp),%eax
  103bfd:	89 04 24             	mov    %eax,(%esp)
  103c00:	e8 eb 74 00 00       	call   10b0f0 <trap_return>

00103c05 <do_ret>:
}

static void
do_ret(trapframe *tf, uint32_t cmd)
{	
  103c05:	55                   	push   %ebp
  103c06:	89 e5                	mov    %esp,%ebp
  103c08:	83 ec 18             	sub    $0x18,%esp
	cprintf("process %p is in do_ret()\n", proc_cur());
  103c0b:	e8 23 fc ff ff       	call   103833 <cpu_cur>
  103c10:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103c16:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c1a:	c7 04 24 bf 8b 10 00 	movl   $0x108bbf,(%esp)
  103c21:	e8 5c 38 00 00       	call   107482 <cprintf>
	proc_ret(tf, 1);
  103c26:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103c2d:	00 
  103c2e:	8b 45 08             	mov    0x8(%ebp),%eax
  103c31:	89 04 24             	mov    %eax,(%esp)
  103c34:	e8 81 f4 ff ff       	call   1030ba <proc_ret>

00103c39 <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  103c39:	55                   	push   %ebp
  103c3a:	89 e5                	mov    %esp,%ebp
  103c3c:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  103c3f:	8b 45 08             	mov    0x8(%ebp),%eax
  103c42:	8b 40 1c             	mov    0x1c(%eax),%eax
  103c45:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  103c48:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c4b:	83 e0 0f             	and    $0xf,%eax
  103c4e:	83 f8 01             	cmp    $0x1,%eax
  103c51:	74 25                	je     103c78 <syscall+0x3f>
  103c53:	83 f8 01             	cmp    $0x1,%eax
  103c56:	72 0c                	jb     103c64 <syscall+0x2b>
  103c58:	83 f8 02             	cmp    $0x2,%eax
  103c5b:	74 2f                	je     103c8c <syscall+0x53>
  103c5d:	83 f8 03             	cmp    $0x3,%eax
  103c60:	74 3e                	je     103ca0 <syscall+0x67>
	case SYS_PUT:	 do_put(tf, cmd); break;
	case SYS_GET:	 do_get(tf, cmd); break;
	case SYS_RET:	 do_ret(tf, cmd); break;
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
  103c62:	eb 4f                	jmp    103cb3 <syscall+0x7a>
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:	 do_cputs(tf, cmd); break;
  103c64:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c67:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c6b:	8b 45 08             	mov    0x8(%ebp),%eax
  103c6e:	89 04 24             	mov    %eax,(%esp)
  103c71:	e8 b1 fc ff ff       	call   103927 <do_cputs>
  103c76:	eb 3b                	jmp    103cb3 <syscall+0x7a>
	case SYS_PUT:	 do_put(tf, cmd); break;
  103c78:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c7b:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c7f:	8b 45 08             	mov    0x8(%ebp),%eax
  103c82:	89 04 24             	mov    %eax,(%esp)
  103c85:	e8 c4 fc ff ff       	call   10394e <do_put>
  103c8a:	eb 27                	jmp    103cb3 <syscall+0x7a>
	case SYS_GET:	 do_get(tf, cmd); break;
  103c8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c8f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c93:	8b 45 08             	mov    0x8(%ebp),%eax
  103c96:	89 04 24             	mov    %eax,(%esp)
  103c99:	e8 81 fe ff ff       	call   103b1f <do_get>
  103c9e:	eb 13                	jmp    103cb3 <syscall+0x7a>
	case SYS_RET:	 do_ret(tf, cmd); break;
  103ca0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ca3:	89 44 24 04          	mov    %eax,0x4(%esp)
  103ca7:	8b 45 08             	mov    0x8(%ebp),%eax
  103caa:	89 04 24             	mov    %eax,(%esp)
  103cad:	e8 53 ff ff ff       	call   103c05 <do_ret>
  103cb2:	90                   	nop
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
	}
}
  103cb3:	c9                   	leave  
  103cb4:	c3                   	ret    

00103cb5 <lockadd>:
}

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  103cb5:	55                   	push   %ebp
  103cb6:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  103cb8:	8b 45 08             	mov    0x8(%ebp),%eax
  103cbb:	8b 55 0c             	mov    0xc(%ebp),%edx
  103cbe:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103cc1:	f0 01 10             	lock add %edx,(%eax)
}
  103cc4:	5d                   	pop    %ebp
  103cc5:	c3                   	ret    

00103cc6 <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  103cc6:	55                   	push   %ebp
  103cc7:	89 e5                	mov    %esp,%ebp
  103cc9:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  103ccc:	8b 45 08             	mov    0x8(%ebp),%eax
  103ccf:	8b 55 0c             	mov    0xc(%ebp),%edx
  103cd2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103cd5:	f0 01 10             	lock add %edx,(%eax)
  103cd8:	0f 94 45 ff          	sete   -0x1(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  103cdc:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
  103ce0:	c9                   	leave  
  103ce1:	c3                   	ret    

00103ce2 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103ce2:	55                   	push   %ebp
  103ce3:	89 e5                	mov    %esp,%ebp
  103ce5:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103ce8:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  103ceb:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103cee:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103cf1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103cf4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103cf9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  103cfc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103cff:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103d05:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103d0a:	74 24                	je     103d30 <cpu_cur+0x4e>
  103d0c:	c7 44 24 0c dc 8b 10 	movl   $0x108bdc,0xc(%esp)
  103d13:	00 
  103d14:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  103d1b:	00 
  103d1c:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103d23:	00 
  103d24:	c7 04 24 07 8c 10 00 	movl   $0x108c07,(%esp)
  103d2b:	e8 51 c7 ff ff       	call   100481 <debug_panic>
	return c;
  103d30:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103d33:	c9                   	leave  
  103d34:	c3                   	ret    

00103d35 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  103d35:	55                   	push   %ebp
  103d36:	89 e5                	mov    %esp,%ebp
  103d38:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  103d3b:	e8 a2 ff ff ff       	call   103ce2 <cpu_cur>
  103d40:	3d 00 a0 10 00       	cmp    $0x10a000,%eax
  103d45:	0f 94 c0             	sete   %al
  103d48:	0f b6 c0             	movzbl %al,%eax
}
  103d4b:	c9                   	leave  
  103d4c:	c3                   	ret    

00103d4d <pmap_init>:
// (addresses outside of the range between VM_USERLO and VM_USERHI).
// The user part of the address space remains all PTE_ZERO until later.
//
void
pmap_init(void)
{
  103d4d:	55                   	push   %ebp
  103d4e:	89 e5                	mov    %esp,%ebp
  103d50:	83 ec 48             	sub    $0x48,%esp
	if (cpu_onboot()) {
  103d53:	e8 dd ff ff ff       	call   103d35 <cpu_onboot>
  103d58:	85 c0                	test   %eax,%eax
  103d5a:	0f 84 be 00 00 00    	je     103e1e <pmap_init+0xd1>
		// we can also mark them global (PTE_G) so the processor
		// doesn't flush these mappings when we reload the PDBR.
		
		// panic("pmap_init() not implemented");

		cprintf("in	 pmap_init\n");
  103d60:	c7 04 24 14 8c 10 00 	movl   $0x108c14,(%esp)
  103d67:	e8 16 37 00 00       	call   107482 <cprintf>
		
		uint32_t va;
		int i;

		for(i = 0, va = 0; i < 1024; i++, va += PTSIZE){
  103d6c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  103d73:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  103d7a:	e9 86 00 00 00       	jmp    103e05 <pmap_init+0xb8>
			if(va >= VM_USERLO && va < VM_USERHI){
  103d7f:	81 7d dc ff ff ff 3f 	cmpl   $0x3fffffff,-0x24(%ebp)
  103d86:	76 3e                	jbe    103dc6 <pmap_init+0x79>
  103d88:	81 7d dc ff ff ff ef 	cmpl   $0xefffffff,-0x24(%ebp)
  103d8f:	77 35                	ja     103dc6 <pmap_init+0x79>
				pmap_bootpdir[i] = PTE_ZERO | PTE_P | PTE_W | PTE_PS;
  103d91:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103d94:	ba 00 00 32 00       	mov    $0x320000,%edx
  103d99:	80 ca 83             	or     $0x83,%dl
  103d9c:	89 14 85 00 f0 31 00 	mov    %edx,0x31f000(,%eax,4)
				cprintf("pmap_bootpdir[%d] = %x\n", i, pmap_bootpdir[i]);
  103da3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103da6:	8b 04 85 00 f0 31 00 	mov    0x31f000(,%eax,4),%eax
  103dad:	89 44 24 08          	mov    %eax,0x8(%esp)
  103db1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103db4:	89 44 24 04          	mov    %eax,0x4(%esp)
  103db8:	c7 04 24 23 8c 10 00 	movl   $0x108c23,(%esp)
  103dbf:	e8 be 36 00 00       	call   107482 <cprintf>
		
		uint32_t va;
		int i;

		for(i = 0, va = 0; i < 1024; i++, va += PTSIZE){
			if(va >= VM_USERLO && va < VM_USERHI){
  103dc4:	eb 34                	jmp    103dfa <pmap_init+0xad>
				pmap_bootpdir[i] = PTE_ZERO | PTE_P | PTE_W | PTE_PS;
				cprintf("pmap_bootpdir[%d] = %x\n", i, pmap_bootpdir[i]);
			}
			else{
				pmap_bootpdir[i] = va | PTE_P | PTE_W | PTE_PS | PTE_G;
  103dc6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103dc9:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103dcc:	81 ca 83 01 00 00    	or     $0x183,%edx
  103dd2:	89 14 85 00 f0 31 00 	mov    %edx,0x31f000(,%eax,4)
				cprintf("pmap_bootpdir[%d] = %x\n", i, pmap_bootpdir[i]);
  103dd9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103ddc:	8b 04 85 00 f0 31 00 	mov    0x31f000(,%eax,4),%eax
  103de3:	89 44 24 08          	mov    %eax,0x8(%esp)
  103de7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103dea:	89 44 24 04          	mov    %eax,0x4(%esp)
  103dee:	c7 04 24 23 8c 10 00 	movl   $0x108c23,(%esp)
  103df5:	e8 88 36 00 00       	call   107482 <cprintf>
		cprintf("in	 pmap_init\n");
		
		uint32_t va;
		int i;

		for(i = 0, va = 0; i < 1024; i++, va += PTSIZE){
  103dfa:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  103dfe:	81 45 dc 00 00 40 00 	addl   $0x400000,-0x24(%ebp)
  103e05:	81 7d e0 ff 03 00 00 	cmpl   $0x3ff,-0x20(%ebp)
  103e0c:	0f 8e 6d ff ff ff    	jle    103d7f <pmap_init+0x32>
				pmap_bootpdir[i] = va | PTE_P | PTE_W | PTE_PS | PTE_G;
				cprintf("pmap_bootpdir[%d] = %x\n", i, pmap_bootpdir[i]);
			}
		}

		cprintf("at last pmap_init\n");
  103e12:	c7 04 24 3b 8c 10 00 	movl   $0x108c3b,(%esp)
  103e19:	e8 64 36 00 00       	call   107482 <cprintf>

static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
  103e1e:	0f 20 e0             	mov    %cr4,%eax
  103e21:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	return cr4;
  103e24:	8b 45 e4             	mov    -0x1c(%ebp),%eax
	// where LA == PA according to the page mapping structures.
	// In PIOS this is always the case for the kernel's address space,
	// so we don't have to play any special tricks as in other kernels.

	// Enable 4MB pages and global pages.
	uint32_t cr4 = rcr4();
  103e27:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	cr4 |= CR4_PSE | CR4_PGE;
  103e2a:	81 4d d4 90 00 00 00 	orl    $0x90,-0x2c(%ebp)
  103e31:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  103e34:	89 45 e8             	mov    %eax,-0x18(%ebp)
}

static gcc_inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
  103e37:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103e3a:	0f 22 e0             	mov    %eax,%cr4
	lcr4(cr4);

	// Install the bootstrap page directory into the PDBR.
	lcr3(mem_phys(pmap_bootpdir));
  103e3d:	b8 00 f0 31 00       	mov    $0x31f000,%eax
  103e42:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  103e45:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103e48:	0f 22 d8             	mov    %eax,%cr3

static gcc_inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
  103e4b:	0f 20 c0             	mov    %cr0,%eax
  103e4e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return val;
  103e51:	8b 45 f0             	mov    -0x10(%ebp),%eax

	// Turn on paging.
	uint32_t cr0 = rcr0();
  103e54:	89 45 d8             	mov    %eax,-0x28(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_MP|CR0_TS;
  103e57:	81 4d d8 2b 00 05 80 	orl    $0x8005002b,-0x28(%ebp)
	cr0 &= ~(CR0_EM);
  103e5e:	83 65 d8 fb          	andl   $0xfffffffb,-0x28(%ebp)

	cprintf("before lcr0\n");
  103e62:	c7 04 24 4e 8c 10 00 	movl   $0x108c4e,(%esp)
  103e69:	e8 14 36 00 00       	call   107482 <cprintf>
  103e6e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103e71:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
  103e74:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e77:	0f 22 c0             	mov    %eax,%cr0
	lcr0(cr0);
	cprintf("after lcr0\n");
  103e7a:	c7 04 24 5b 8c 10 00 	movl   $0x108c5b,(%esp)
  103e81:	e8 fc 35 00 00       	call   107482 <cprintf>

	// If we survived the lcr0, we're running with paging enabled.
	// Now check the page table management functions below.
	if (cpu_onboot())
  103e86:	e8 aa fe ff ff       	call   103d35 <cpu_onboot>
  103e8b:	85 c0                	test   %eax,%eax
  103e8d:	74 05                	je     103e94 <pmap_init+0x147>
		pmap_check();
  103e8f:	e8 1d 09 00 00       	call   1047b1 <pmap_check>
}
  103e94:	c9                   	leave  
  103e95:	c3                   	ret    

00103e96 <pmap_newpdir>:
// Allocate a new page directory, initialized from the bootstrap pdir.
// Returns the new pdir with a reference count of 1.
//
pte_t *
pmap_newpdir(void)
{
  103e96:	55                   	push   %ebp
  103e97:	89 e5                	mov    %esp,%ebp
  103e99:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  103e9c:	e8 6c cc ff ff       	call   100b0d <mem_alloc>
  103ea1:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (pi == NULL)
  103ea4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  103ea8:	75 0a                	jne    103eb4 <pmap_newpdir+0x1e>
		return NULL;
  103eaa:	b8 00 00 00 00       	mov    $0x0,%eax
  103eaf:	e9 24 01 00 00       	jmp    103fd8 <pmap_newpdir+0x142>
  103eb4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103eb7:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  103eba:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  103ebf:	83 c0 08             	add    $0x8,%eax
  103ec2:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103ec5:	76 15                	jbe    103edc <pmap_newpdir+0x46>
  103ec7:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  103ecc:	8b 15 04 dd 11 00    	mov    0x11dd04,%edx
  103ed2:	c1 e2 03             	shl    $0x3,%edx
  103ed5:	01 d0                	add    %edx,%eax
  103ed7:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103eda:	72 24                	jb     103f00 <pmap_newpdir+0x6a>
  103edc:	c7 44 24 0c 68 8c 10 	movl   $0x108c68,0xc(%esp)
  103ee3:	00 
  103ee4:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  103eeb:	00 
  103eec:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  103ef3:	00 
  103ef4:	c7 04 24 9f 8c 10 00 	movl   $0x108c9f,(%esp)
  103efb:	e8 81 c5 ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  103f00:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  103f05:	ba 00 00 32 00       	mov    $0x320000,%edx
  103f0a:	c1 ea 0c             	shr    $0xc,%edx
  103f0d:	c1 e2 03             	shl    $0x3,%edx
  103f10:	01 d0                	add    %edx,%eax
  103f12:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103f15:	75 24                	jne    103f3b <pmap_newpdir+0xa5>
  103f17:	c7 44 24 0c ac 8c 10 	movl   $0x108cac,0xc(%esp)
  103f1e:	00 
  103f1f:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  103f26:	00 
  103f27:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  103f2e:	00 
  103f2f:	c7 04 24 9f 8c 10 00 	movl   $0x108c9f,(%esp)
  103f36:	e8 46 c5 ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  103f3b:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  103f40:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  103f45:	c1 ea 0c             	shr    $0xc,%edx
  103f48:	c1 e2 03             	shl    $0x3,%edx
  103f4b:	01 d0                	add    %edx,%eax
  103f4d:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103f50:	72 3b                	jb     103f8d <pmap_newpdir+0xf7>
  103f52:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  103f57:	ba 07 10 32 00       	mov    $0x321007,%edx
  103f5c:	c1 ea 0c             	shr    $0xc,%edx
  103f5f:	c1 e2 03             	shl    $0x3,%edx
  103f62:	01 d0                	add    %edx,%eax
  103f64:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103f67:	77 24                	ja     103f8d <pmap_newpdir+0xf7>
  103f69:	c7 44 24 0c c8 8c 10 	movl   $0x108cc8,0xc(%esp)
  103f70:	00 
  103f71:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  103f78:	00 
  103f79:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  103f80:	00 
  103f81:	c7 04 24 9f 8c 10 00 	movl   $0x108c9f,(%esp)
  103f88:	e8 f4 c4 ff ff       	call   100481 <debug_panic>

	lockadd(&pi->refcount, 1);
  103f8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f90:	83 c0 04             	add    $0x4,%eax
  103f93:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103f9a:	00 
  103f9b:	89 04 24             	mov    %eax,(%esp)
  103f9e:	e8 12 fd ff ff       	call   103cb5 <lockadd>
	mem_incref(pi);
	pte_t *pdir = mem_pi2ptr(pi);
  103fa3:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103fa6:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  103fab:	89 d1                	mov    %edx,%ecx
  103fad:	29 c1                	sub    %eax,%ecx
  103faf:	89 c8                	mov    %ecx,%eax
  103fb1:	c1 f8 03             	sar    $0x3,%eax
  103fb4:	c1 e0 0c             	shl    $0xc,%eax
  103fb7:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Initialize it from the bootstrap page directory
	assert(sizeof(pmap_bootpdir) == PAGESIZE);
	memmove(pdir, pmap_bootpdir, PAGESIZE);
  103fba:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  103fc1:	00 
  103fc2:	c7 44 24 04 00 f0 31 	movl   $0x31f000,0x4(%esp)
  103fc9:	00 
  103fca:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103fcd:	89 04 24             	mov    %eax,(%esp)
  103fd0:	e8 06 37 00 00       	call   1076db <memmove>

	return pdir;
  103fd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  103fd8:	c9                   	leave  
  103fd9:	c3                   	ret    

00103fda <pmap_freepdir>:

// Free a page directory, and all page tables and mappings it may contain.
void
pmap_freepdir(pageinfo *pdirpi)
{
  103fda:	55                   	push   %ebp
  103fdb:	89 e5                	mov    %esp,%ebp
  103fdd:	83 ec 18             	sub    $0x18,%esp
	pmap_remove(mem_pi2ptr(pdirpi), VM_USERLO, VM_USERHI-VM_USERLO);
  103fe0:	8b 55 08             	mov    0x8(%ebp),%edx
  103fe3:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  103fe8:	89 d1                	mov    %edx,%ecx
  103fea:	29 c1                	sub    %eax,%ecx
  103fec:	89 c8                	mov    %ecx,%eax
  103fee:	c1 f8 03             	sar    $0x3,%eax
  103ff1:	c1 e0 0c             	shl    $0xc,%eax
  103ff4:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  103ffb:	b0 
  103ffc:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  104003:	40 
  104004:	89 04 24             	mov    %eax,(%esp)
  104007:	e8 ff 01 00 00       	call   10420b <pmap_remove>
	mem_free(pdirpi);
  10400c:	8b 45 08             	mov    0x8(%ebp),%eax
  10400f:	89 04 24             	mov    %eax,(%esp)
  104012:	e8 3d cb ff ff       	call   100b54 <mem_free>
}
  104017:	c9                   	leave  
  104018:	c3                   	ret    

00104019 <pmap_freeptab>:

// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
  104019:	55                   	push   %ebp
  10401a:	89 e5                	mov    %esp,%ebp
  10401c:	83 ec 38             	sub    $0x38,%esp
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
  10401f:	8b 55 08             	mov    0x8(%ebp),%edx
  104022:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  104027:	89 d1                	mov    %edx,%ecx
  104029:	29 c1                	sub    %eax,%ecx
  10402b:	89 c8                	mov    %ecx,%eax
  10402d:	c1 f8 03             	sar    $0x3,%eax
  104030:	c1 e0 0c             	shl    $0xc,%eax
  104033:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  104036:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104039:	05 00 10 00 00       	add    $0x1000,%eax
  10403e:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (; pte < ptelim; pte++) {
  104041:	e9 5f 01 00 00       	jmp    1041a5 <pmap_freeptab+0x18c>
		uint32_t pgaddr = PGADDR(*pte);
  104046:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104049:	8b 00                	mov    (%eax),%eax
  10404b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104050:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (pgaddr != PTE_ZERO)
  104053:	b8 00 00 32 00       	mov    $0x320000,%eax
  104058:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  10405b:	0f 84 40 01 00 00    	je     1041a1 <pmap_freeptab+0x188>
			mem_decref(mem_phys2pi(pgaddr), mem_free);
  104061:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  104066:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104069:	c1 ea 0c             	shr    $0xc,%edx
  10406c:	c1 e2 03             	shl    $0x3,%edx
  10406f:	01 d0                	add    %edx,%eax
  104071:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104074:	c7 45 f0 54 0b 10 00 	movl   $0x100b54,-0x10(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10407b:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  104080:	83 c0 08             	add    $0x8,%eax
  104083:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104086:	76 15                	jbe    10409d <pmap_freeptab+0x84>
  104088:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  10408d:	8b 15 04 dd 11 00    	mov    0x11dd04,%edx
  104093:	c1 e2 03             	shl    $0x3,%edx
  104096:	01 d0                	add    %edx,%eax
  104098:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10409b:	72 24                	jb     1040c1 <pmap_freeptab+0xa8>
  10409d:	c7 44 24 0c 68 8c 10 	movl   $0x108c68,0xc(%esp)
  1040a4:	00 
  1040a5:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1040ac:	00 
  1040ad:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1040b4:	00 
  1040b5:	c7 04 24 9f 8c 10 00 	movl   $0x108c9f,(%esp)
  1040bc:	e8 c0 c3 ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1040c1:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  1040c6:	ba 00 00 32 00       	mov    $0x320000,%edx
  1040cb:	c1 ea 0c             	shr    $0xc,%edx
  1040ce:	c1 e2 03             	shl    $0x3,%edx
  1040d1:	01 d0                	add    %edx,%eax
  1040d3:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1040d6:	75 24                	jne    1040fc <pmap_freeptab+0xe3>
  1040d8:	c7 44 24 0c ac 8c 10 	movl   $0x108cac,0xc(%esp)
  1040df:	00 
  1040e0:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1040e7:	00 
  1040e8:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1040ef:	00 
  1040f0:	c7 04 24 9f 8c 10 00 	movl   $0x108c9f,(%esp)
  1040f7:	e8 85 c3 ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1040fc:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  104101:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104106:	c1 ea 0c             	shr    $0xc,%edx
  104109:	c1 e2 03             	shl    $0x3,%edx
  10410c:	01 d0                	add    %edx,%eax
  10410e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104111:	72 3b                	jb     10414e <pmap_freeptab+0x135>
  104113:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  104118:	ba 07 10 32 00       	mov    $0x321007,%edx
  10411d:	c1 ea 0c             	shr    $0xc,%edx
  104120:	c1 e2 03             	shl    $0x3,%edx
  104123:	01 d0                	add    %edx,%eax
  104125:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104128:	77 24                	ja     10414e <pmap_freeptab+0x135>
  10412a:	c7 44 24 0c c8 8c 10 	movl   $0x108cc8,0xc(%esp)
  104131:	00 
  104132:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104139:	00 
  10413a:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  104141:	00 
  104142:	c7 04 24 9f 8c 10 00 	movl   $0x108c9f,(%esp)
  104149:	e8 33 c3 ff ff       	call   100481 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10414e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104151:	83 c0 04             	add    $0x4,%eax
  104154:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  10415b:	ff 
  10415c:	89 04 24             	mov    %eax,(%esp)
  10415f:	e8 62 fb ff ff       	call   103cc6 <lockaddz>
  104164:	84 c0                	test   %al,%al
  104166:	74 0b                	je     104173 <pmap_freeptab+0x15a>
			freefun(pi);
  104168:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10416b:	89 04 24             	mov    %eax,(%esp)
  10416e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104171:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  104173:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104176:	8b 40 04             	mov    0x4(%eax),%eax
  104179:	85 c0                	test   %eax,%eax
  10417b:	79 24                	jns    1041a1 <pmap_freeptab+0x188>
  10417d:	c7 44 24 0c f9 8c 10 	movl   $0x108cf9,0xc(%esp)
  104184:	00 
  104185:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10418c:	00 
  10418d:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  104194:	00 
  104195:	c7 04 24 9f 8c 10 00 	movl   $0x108c9f,(%esp)
  10419c:	e8 e0 c2 ff ff       	call   100481 <debug_panic>
// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
	for (; pte < ptelim; pte++) {
  1041a1:	83 45 e4 04          	addl   $0x4,-0x1c(%ebp)
  1041a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1041a8:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1041ab:	0f 82 95 fe ff ff    	jb     104046 <pmap_freeptab+0x2d>
		uint32_t pgaddr = PGADDR(*pte);
		if (pgaddr != PTE_ZERO)
			mem_decref(mem_phys2pi(pgaddr), mem_free);
	}
	mem_free(ptabpi);
  1041b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1041b4:	89 04 24             	mov    %eax,(%esp)
  1041b7:	e8 98 c9 ff ff       	call   100b54 <mem_free>
}
  1041bc:	c9                   	leave  
  1041bd:	c3                   	ret    

001041be <pmap_walk>:
// Hint 2: the x86 MMU checks permission bits in both the page directory
// and the page table, so it's safe to leave some page permissions
// more permissive than strictly necessary.
pte_t *
pmap_walk(pde_t *pdir, uint32_t va, bool writing)
{
  1041be:	55                   	push   %ebp
  1041bf:	89 e5                	mov    %esp,%ebp
  1041c1:	83 ec 18             	sub    $0x18,%esp
	assert(va >= VM_USERLO && va < VM_USERHI);
  1041c4:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1041cb:	76 09                	jbe    1041d6 <pmap_walk+0x18>
  1041cd:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1041d4:	76 24                	jbe    1041fa <pmap_walk+0x3c>
  1041d6:	c7 44 24 0c 0c 8d 10 	movl   $0x108d0c,0xc(%esp)
  1041dd:	00 
  1041de:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1041e5:	00 
  1041e6:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  1041ed:	00 
  1041ee:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1041f5:	e8 87 c2 ff ff       	call   100481 <debug_panic>

	// Fill in this function
	return NULL;
  1041fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1041ff:	c9                   	leave  
  104200:	c3                   	ret    

00104201 <pmap_insert>:
//
// Hint: The reference solution uses pmap_walk, pmap_remove, and mem_pi2phys.
//
pte_t *
pmap_insert(pde_t *pdir, pageinfo *pi, uint32_t va, int perm)
{
  104201:	55                   	push   %ebp
  104202:	89 e5                	mov    %esp,%ebp
	// Fill in this function
	return NULL;
  104204:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104209:	5d                   	pop    %ebp
  10420a:	c3                   	ret    

0010420b <pmap_remove>:
// Hint: The TA solution is implemented using pmap_lookup,
// 	pmap_inval, and mem_decref.
//
void
pmap_remove(pde_t *pdir, uint32_t va, size_t size)
{
  10420b:	55                   	push   %ebp
  10420c:	89 e5                	mov    %esp,%ebp
  10420e:	83 ec 18             	sub    $0x18,%esp
	assert(PGOFF(size) == 0);	// must be page-aligned
  104211:	8b 45 10             	mov    0x10(%ebp),%eax
  104214:	25 ff 0f 00 00       	and    $0xfff,%eax
  104219:	85 c0                	test   %eax,%eax
  10421b:	74 24                	je     104241 <pmap_remove+0x36>
  10421d:	c7 44 24 0c 3a 8d 10 	movl   $0x108d3a,0xc(%esp)
  104224:	00 
  104225:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10422c:	00 
  10422d:	c7 44 24 04 f1 00 00 	movl   $0xf1,0x4(%esp)
  104234:	00 
  104235:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10423c:	e8 40 c2 ff ff       	call   100481 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  104241:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104248:	76 09                	jbe    104253 <pmap_remove+0x48>
  10424a:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  104251:	76 24                	jbe    104277 <pmap_remove+0x6c>
  104253:	c7 44 24 0c 0c 8d 10 	movl   $0x108d0c,0xc(%esp)
  10425a:	00 
  10425b:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104262:	00 
  104263:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
  10426a:	00 
  10426b:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104272:	e8 0a c2 ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - va);
  104277:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  10427c:	2b 45 0c             	sub    0xc(%ebp),%eax
  10427f:	3b 45 10             	cmp    0x10(%ebp),%eax
  104282:	73 24                	jae    1042a8 <pmap_remove+0x9d>
  104284:	c7 44 24 0c 4b 8d 10 	movl   $0x108d4b,0xc(%esp)
  10428b:	00 
  10428c:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104293:	00 
  104294:	c7 44 24 04 f3 00 00 	movl   $0xf3,0x4(%esp)
  10429b:	00 
  10429c:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1042a3:	e8 d9 c1 ff ff       	call   100481 <debug_panic>

	// Fill in this function
}
  1042a8:	c9                   	leave  
  1042a9:	c3                   	ret    

001042aa <pmap_inval>:
// but only if the page tables being edited are the ones
// currently in use by the processor.
//
void
pmap_inval(pde_t *pdir, uint32_t va, size_t size)
{
  1042aa:	55                   	push   %ebp
  1042ab:	89 e5                	mov    %esp,%ebp
  1042ad:	83 ec 18             	sub    $0x18,%esp
	// Flush the entry only if we're modifying the current address space.
	proc *p = proc_cur();
  1042b0:	e8 2d fa ff ff       	call   103ce2 <cpu_cur>
  1042b5:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1042bb:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (p == NULL || p->pdir == pdir) {
  1042be:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1042c2:	74 0e                	je     1042d2 <pmap_inval+0x28>
  1042c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1042c7:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1042cd:	3b 45 08             	cmp    0x8(%ebp),%eax
  1042d0:	75 23                	jne    1042f5 <pmap_inval+0x4b>
		if (size == PAGESIZE)
  1042d2:	81 7d 10 00 10 00 00 	cmpl   $0x1000,0x10(%ebp)
  1042d9:	75 0e                	jne    1042e9 <pmap_inval+0x3f>
			invlpg(mem_ptr(va));	// invalidate one page
  1042db:	8b 45 0c             	mov    0xc(%ebp),%eax
  1042de:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static gcc_inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
  1042e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042e4:	0f 01 38             	invlpg (%eax)
  1042e7:	eb 0c                	jmp    1042f5 <pmap_inval+0x4b>
		else
			lcr3(mem_phys(pdir));	// invalidate everything
  1042e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1042ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  1042ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1042f2:	0f 22 d8             	mov    %eax,%cr3
	}
}
  1042f5:	c9                   	leave  
  1042f6:	c3                   	ret    

001042f7 <pmap_copy>:
// Returns true if successfull, false if not enough memory for copy.
//
int
pmap_copy(pde_t *spdir, uint32_t sva, pde_t *dpdir, uint32_t dva,
		size_t size)
{
  1042f7:	55                   	push   %ebp
  1042f8:	89 e5                	mov    %esp,%ebp
  1042fa:	83 ec 18             	sub    $0x18,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  1042fd:	8b 45 0c             	mov    0xc(%ebp),%eax
  104300:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104305:	85 c0                	test   %eax,%eax
  104307:	74 24                	je     10432d <pmap_copy+0x36>
  104309:	c7 44 24 0c 62 8d 10 	movl   $0x108d62,0xc(%esp)
  104310:	00 
  104311:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104318:	00 
  104319:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
  104320:	00 
  104321:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104328:	e8 54 c1 ff ff       	call   100481 <debug_panic>
	assert(PTOFF(dva) == 0);
  10432d:	8b 45 14             	mov    0x14(%ebp),%eax
  104330:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104335:	85 c0                	test   %eax,%eax
  104337:	74 24                	je     10435d <pmap_copy+0x66>
  104339:	c7 44 24 0c 72 8d 10 	movl   $0x108d72,0xc(%esp)
  104340:	00 
  104341:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104348:	00 
  104349:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
  104350:	00 
  104351:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104358:	e8 24 c1 ff ff       	call   100481 <debug_panic>
	assert(PTOFF(size) == 0);
  10435d:	8b 45 18             	mov    0x18(%ebp),%eax
  104360:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104365:	85 c0                	test   %eax,%eax
  104367:	74 24                	je     10438d <pmap_copy+0x96>
  104369:	c7 44 24 0c 82 8d 10 	movl   $0x108d82,0xc(%esp)
  104370:	00 
  104371:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104378:	00 
  104379:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
  104380:	00 
  104381:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104388:	e8 f4 c0 ff ff       	call   100481 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  10438d:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104394:	76 09                	jbe    10439f <pmap_copy+0xa8>
  104396:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  10439d:	76 24                	jbe    1043c3 <pmap_copy+0xcc>
  10439f:	c7 44 24 0c 94 8d 10 	movl   $0x108d94,0xc(%esp)
  1043a6:	00 
  1043a7:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1043ae:	00 
  1043af:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
  1043b6:	00 
  1043b7:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1043be:	e8 be c0 ff ff       	call   100481 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  1043c3:	81 7d 14 ff ff ff 3f 	cmpl   $0x3fffffff,0x14(%ebp)
  1043ca:	76 09                	jbe    1043d5 <pmap_copy+0xde>
  1043cc:	81 7d 14 ff ff ff ef 	cmpl   $0xefffffff,0x14(%ebp)
  1043d3:	76 24                	jbe    1043f9 <pmap_copy+0x102>
  1043d5:	c7 44 24 0c b8 8d 10 	movl   $0x108db8,0xc(%esp)
  1043dc:	00 
  1043dd:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1043e4:	00 
  1043e5:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  1043ec:	00 
  1043ed:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1043f4:	e8 88 c0 ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - sva);
  1043f9:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1043fe:	2b 45 0c             	sub    0xc(%ebp),%eax
  104401:	3b 45 18             	cmp    0x18(%ebp),%eax
  104404:	73 24                	jae    10442a <pmap_copy+0x133>
  104406:	c7 44 24 0c dc 8d 10 	movl   $0x108ddc,0xc(%esp)
  10440d:	00 
  10440e:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104415:	00 
  104416:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
  10441d:	00 
  10441e:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104425:	e8 57 c0 ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - dva);
  10442a:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  10442f:	2b 45 14             	sub    0x14(%ebp),%eax
  104432:	3b 45 18             	cmp    0x18(%ebp),%eax
  104435:	73 24                	jae    10445b <pmap_copy+0x164>
  104437:	c7 44 24 0c f4 8d 10 	movl   $0x108df4,0xc(%esp)
  10443e:	00 
  10443f:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104446:	00 
  104447:	c7 44 24 04 1a 01 00 	movl   $0x11a,0x4(%esp)
  10444e:	00 
  10444f:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104456:	e8 26 c0 ff ff       	call   100481 <debug_panic>

	panic("pmap_copy() not implemented");
  10445b:	c7 44 24 08 0c 8e 10 	movl   $0x108e0c,0x8(%esp)
  104462:	00 
  104463:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
  10446a:	00 
  10446b:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104472:	e8 0a c0 ff ff       	call   100481 <debug_panic>

00104477 <pmap_pagefault>:
// If the fault wasn't due to the kernel's copy on write optimization,
// however, this function just returns so the trap gets blamed on the user.
//
void
pmap_pagefault(trapframe *tf)
{
  104477:	55                   	push   %ebp
  104478:	89 e5                	mov    %esp,%ebp
  10447a:	83 ec 10             	sub    $0x10,%esp

static gcc_inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
  10447d:	0f 20 d0             	mov    %cr2,%eax
  104480:	89 45 fc             	mov    %eax,-0x4(%ebp)
	return val;
  104483:	8b 45 fc             	mov    -0x4(%ebp),%eax
	// Read processor's CR2 register to find the faulting linear address.
	uint32_t fva = rcr2();
  104486:	89 45 f8             	mov    %eax,-0x8(%ebp)
	//cprintf("pmap_pagefault fva %x eip %x\n", fva, tf->eip);

	// Fill in the rest of this code.
}
  104489:	c9                   	leave  
  10448a:	c3                   	ret    

0010448b <pmap_mergepage>:
// print a warning to the console and remove the page from the destination.
// If the destination page is read-shared, be sure to copy it before modifying!
//
void
pmap_mergepage(pte_t *rpte, pte_t *spte, pte_t *dpte, uint32_t dva)
{
  10448b:	55                   	push   %ebp
  10448c:	89 e5                	mov    %esp,%ebp
  10448e:	83 ec 18             	sub    $0x18,%esp
	panic("pmap_mergepage() not implemented");
  104491:	c7 44 24 08 28 8e 10 	movl   $0x108e28,0x8(%esp)
  104498:	00 
  104499:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
  1044a0:	00 
  1044a1:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1044a8:	e8 d4 bf ff ff       	call   100481 <debug_panic>

001044ad <pmap_merge>:
// and a source address space spdir into a destination address space dpdir.
//
int
pmap_merge(pde_t *rpdir, pde_t *spdir, uint32_t sva,
		pde_t *dpdir, uint32_t dva, size_t size)
{
  1044ad:	55                   	push   %ebp
  1044ae:	89 e5                	mov    %esp,%ebp
  1044b0:	83 ec 18             	sub    $0x18,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  1044b3:	8b 45 10             	mov    0x10(%ebp),%eax
  1044b6:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1044bb:	85 c0                	test   %eax,%eax
  1044bd:	74 24                	je     1044e3 <pmap_merge+0x36>
  1044bf:	c7 44 24 0c 62 8d 10 	movl   $0x108d62,0xc(%esp)
  1044c6:	00 
  1044c7:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1044ce:	00 
  1044cf:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
  1044d6:	00 
  1044d7:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1044de:	e8 9e bf ff ff       	call   100481 <debug_panic>
	assert(PTOFF(dva) == 0);
  1044e3:	8b 45 18             	mov    0x18(%ebp),%eax
  1044e6:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1044eb:	85 c0                	test   %eax,%eax
  1044ed:	74 24                	je     104513 <pmap_merge+0x66>
  1044ef:	c7 44 24 0c 72 8d 10 	movl   $0x108d72,0xc(%esp)
  1044f6:	00 
  1044f7:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1044fe:	00 
  1044ff:	c7 44 24 04 46 01 00 	movl   $0x146,0x4(%esp)
  104506:	00 
  104507:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10450e:	e8 6e bf ff ff       	call   100481 <debug_panic>
	assert(PTOFF(size) == 0);
  104513:	8b 45 1c             	mov    0x1c(%ebp),%eax
  104516:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10451b:	85 c0                	test   %eax,%eax
  10451d:	74 24                	je     104543 <pmap_merge+0x96>
  10451f:	c7 44 24 0c 82 8d 10 	movl   $0x108d82,0xc(%esp)
  104526:	00 
  104527:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10452e:	00 
  10452f:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
  104536:	00 
  104537:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10453e:	e8 3e bf ff ff       	call   100481 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  104543:	81 7d 10 ff ff ff 3f 	cmpl   $0x3fffffff,0x10(%ebp)
  10454a:	76 09                	jbe    104555 <pmap_merge+0xa8>
  10454c:	81 7d 10 ff ff ff ef 	cmpl   $0xefffffff,0x10(%ebp)
  104553:	76 24                	jbe    104579 <pmap_merge+0xcc>
  104555:	c7 44 24 0c 94 8d 10 	movl   $0x108d94,0xc(%esp)
  10455c:	00 
  10455d:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104564:	00 
  104565:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
  10456c:	00 
  10456d:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104574:	e8 08 bf ff ff       	call   100481 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  104579:	81 7d 18 ff ff ff 3f 	cmpl   $0x3fffffff,0x18(%ebp)
  104580:	76 09                	jbe    10458b <pmap_merge+0xde>
  104582:	81 7d 18 ff ff ff ef 	cmpl   $0xefffffff,0x18(%ebp)
  104589:	76 24                	jbe    1045af <pmap_merge+0x102>
  10458b:	c7 44 24 0c b8 8d 10 	movl   $0x108db8,0xc(%esp)
  104592:	00 
  104593:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10459a:	00 
  10459b:	c7 44 24 04 49 01 00 	movl   $0x149,0x4(%esp)
  1045a2:	00 
  1045a3:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1045aa:	e8 d2 be ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - sva);
  1045af:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1045b4:	2b 45 10             	sub    0x10(%ebp),%eax
  1045b7:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  1045ba:	73 24                	jae    1045e0 <pmap_merge+0x133>
  1045bc:	c7 44 24 0c dc 8d 10 	movl   $0x108ddc,0xc(%esp)
  1045c3:	00 
  1045c4:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1045cb:	00 
  1045cc:	c7 44 24 04 4a 01 00 	movl   $0x14a,0x4(%esp)
  1045d3:	00 
  1045d4:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1045db:	e8 a1 be ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - dva);
  1045e0:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1045e5:	2b 45 18             	sub    0x18(%ebp),%eax
  1045e8:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  1045eb:	73 24                	jae    104611 <pmap_merge+0x164>
  1045ed:	c7 44 24 0c f4 8d 10 	movl   $0x108df4,0xc(%esp)
  1045f4:	00 
  1045f5:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1045fc:	00 
  1045fd:	c7 44 24 04 4b 01 00 	movl   $0x14b,0x4(%esp)
  104604:	00 
  104605:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10460c:	e8 70 be ff ff       	call   100481 <debug_panic>

	panic("pmap_merge() not implemented");
  104611:	c7 44 24 08 49 8e 10 	movl   $0x108e49,0x8(%esp)
  104618:	00 
  104619:	c7 44 24 04 4d 01 00 	movl   $0x14d,0x4(%esp)
  104620:	00 
  104621:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104628:	e8 54 be ff ff       	call   100481 <debug_panic>

0010462d <pmap_setperm>:
// If the user gives SYS_WRITE permission to a PTE_ZERO mapping,
// the page fault handler copies the zero page when the first write occurs.
//
int
pmap_setperm(pde_t *pdir, uint32_t va, uint32_t size, int perm)
{
  10462d:	55                   	push   %ebp
  10462e:	89 e5                	mov    %esp,%ebp
  104630:	83 ec 18             	sub    $0x18,%esp
	assert(PGOFF(va) == 0);
  104633:	8b 45 0c             	mov    0xc(%ebp),%eax
  104636:	25 ff 0f 00 00       	and    $0xfff,%eax
  10463b:	85 c0                	test   %eax,%eax
  10463d:	74 24                	je     104663 <pmap_setperm+0x36>
  10463f:	c7 44 24 0c 66 8e 10 	movl   $0x108e66,0xc(%esp)
  104646:	00 
  104647:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10464e:	00 
  10464f:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
  104656:	00 
  104657:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10465e:	e8 1e be ff ff       	call   100481 <debug_panic>
	assert(PGOFF(size) == 0);
  104663:	8b 45 10             	mov    0x10(%ebp),%eax
  104666:	25 ff 0f 00 00       	and    $0xfff,%eax
  10466b:	85 c0                	test   %eax,%eax
  10466d:	74 24                	je     104693 <pmap_setperm+0x66>
  10466f:	c7 44 24 0c 3a 8d 10 	movl   $0x108d3a,0xc(%esp)
  104676:	00 
  104677:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10467e:	00 
  10467f:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
  104686:	00 
  104687:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10468e:	e8 ee bd ff ff       	call   100481 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  104693:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  10469a:	76 09                	jbe    1046a5 <pmap_setperm+0x78>
  10469c:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1046a3:	76 24                	jbe    1046c9 <pmap_setperm+0x9c>
  1046a5:	c7 44 24 0c 0c 8d 10 	movl   $0x108d0c,0xc(%esp)
  1046ac:	00 
  1046ad:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1046b4:	00 
  1046b5:	c7 44 24 04 5d 01 00 	movl   $0x15d,0x4(%esp)
  1046bc:	00 
  1046bd:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1046c4:	e8 b8 bd ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - va);
  1046c9:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1046ce:	2b 45 0c             	sub    0xc(%ebp),%eax
  1046d1:	3b 45 10             	cmp    0x10(%ebp),%eax
  1046d4:	73 24                	jae    1046fa <pmap_setperm+0xcd>
  1046d6:	c7 44 24 0c 4b 8d 10 	movl   $0x108d4b,0xc(%esp)
  1046dd:	00 
  1046de:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1046e5:	00 
  1046e6:	c7 44 24 04 5e 01 00 	movl   $0x15e,0x4(%esp)
  1046ed:	00 
  1046ee:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1046f5:	e8 87 bd ff ff       	call   100481 <debug_panic>
	assert((perm & ~(SYS_RW)) == 0);
  1046fa:	8b 45 14             	mov    0x14(%ebp),%eax
  1046fd:	80 e4 f9             	and    $0xf9,%ah
  104700:	85 c0                	test   %eax,%eax
  104702:	74 24                	je     104728 <pmap_setperm+0xfb>
  104704:	c7 44 24 0c 75 8e 10 	movl   $0x108e75,0xc(%esp)
  10470b:	00 
  10470c:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104713:	00 
  104714:	c7 44 24 04 5f 01 00 	movl   $0x15f,0x4(%esp)
  10471b:	00 
  10471c:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104723:	e8 59 bd ff ff       	call   100481 <debug_panic>

	panic("pmap_merge() not implemented");
  104728:	c7 44 24 08 49 8e 10 	movl   $0x108e49,0x8(%esp)
  10472f:	00 
  104730:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
  104737:	00 
  104738:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10473f:	e8 3d bd ff ff       	call   100481 <debug_panic>

00104744 <va2pa>:
// this functionality for us!  We define our own version to help check
// the pmap_check() function; it shouldn't be used elsewhere.
//
static uint32_t
va2pa(pde_t *pdir, uintptr_t va)
{
  104744:	55                   	push   %ebp
  104745:	89 e5                	mov    %esp,%ebp
  104747:	83 ec 10             	sub    $0x10,%esp
	pdir = &pdir[PDX(va)];
  10474a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10474d:	c1 e8 16             	shr    $0x16,%eax
  104750:	c1 e0 02             	shl    $0x2,%eax
  104753:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pdir & PTE_P))
  104756:	8b 45 08             	mov    0x8(%ebp),%eax
  104759:	8b 00                	mov    (%eax),%eax
  10475b:	83 e0 01             	and    $0x1,%eax
  10475e:	85 c0                	test   %eax,%eax
  104760:	75 07                	jne    104769 <va2pa+0x25>
		return ~0;
  104762:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104767:	eb 46                	jmp    1047af <va2pa+0x6b>
	pte_t *ptab = mem_ptr(PGADDR(*pdir));
  104769:	8b 45 08             	mov    0x8(%ebp),%eax
  10476c:	8b 00                	mov    (%eax),%eax
  10476e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104773:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (!(ptab[PTX(va)] & PTE_P))
  104776:	8b 45 0c             	mov    0xc(%ebp),%eax
  104779:	c1 e8 0c             	shr    $0xc,%eax
  10477c:	25 ff 03 00 00       	and    $0x3ff,%eax
  104781:	c1 e0 02             	shl    $0x2,%eax
  104784:	03 45 fc             	add    -0x4(%ebp),%eax
  104787:	8b 00                	mov    (%eax),%eax
  104789:	83 e0 01             	and    $0x1,%eax
  10478c:	85 c0                	test   %eax,%eax
  10478e:	75 07                	jne    104797 <va2pa+0x53>
		return ~0;
  104790:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104795:	eb 18                	jmp    1047af <va2pa+0x6b>
	return PGADDR(ptab[PTX(va)]);
  104797:	8b 45 0c             	mov    0xc(%ebp),%eax
  10479a:	c1 e8 0c             	shr    $0xc,%eax
  10479d:	25 ff 03 00 00       	and    $0x3ff,%eax
  1047a2:	c1 e0 02             	shl    $0x2,%eax
  1047a5:	03 45 fc             	add    -0x4(%ebp),%eax
  1047a8:	8b 00                	mov    (%eax),%eax
  1047aa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
  1047af:	c9                   	leave  
  1047b0:	c3                   	ret    

001047b1 <pmap_check>:

// check pmap_insert, pmap_remove, &c
void
pmap_check(void)
{
  1047b1:	55                   	push   %ebp
  1047b2:	89 e5                	mov    %esp,%ebp
  1047b4:	53                   	push   %ebx
  1047b5:	83 ec 44             	sub    $0x44,%esp

	cprintf("into pmap_check()\n");
  1047b8:	c7 04 24 8d 8e 10 00 	movl   $0x108e8d,(%esp)
  1047bf:	e8 be 2c 00 00       	call   107482 <cprintf>
	pageinfo *fl;
	pte_t *ptep, *ptep1;
	int i;

	// should be able to allocate three pages
	pi0 = pi1 = pi2 = 0;
  1047c4:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  1047cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1047ce:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1047d1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1047d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	pi0 = mem_alloc();
  1047d7:	e8 31 c3 ff ff       	call   100b0d <mem_alloc>
  1047dc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	pi1 = mem_alloc();
  1047df:	e8 29 c3 ff ff       	call   100b0d <mem_alloc>
  1047e4:	89 45 d8             	mov    %eax,-0x28(%ebp)
	pi2 = mem_alloc();
  1047e7:	e8 21 c3 ff ff       	call   100b0d <mem_alloc>
  1047ec:	89 45 dc             	mov    %eax,-0x24(%ebp)
	pi3 = mem_alloc();
  1047ef:	e8 19 c3 ff ff       	call   100b0d <mem_alloc>
  1047f4:	89 45 e0             	mov    %eax,-0x20(%ebp)

	assert(pi0);
  1047f7:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  1047fb:	75 24                	jne    104821 <pmap_check+0x70>
  1047fd:	c7 44 24 0c a0 8e 10 	movl   $0x108ea0,0xc(%esp)
  104804:	00 
  104805:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10480c:	00 
  10480d:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
  104814:	00 
  104815:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10481c:	e8 60 bc ff ff       	call   100481 <debug_panic>
	assert(pi1 && pi1 != pi0);
  104821:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  104825:	74 08                	je     10482f <pmap_check+0x7e>
  104827:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10482a:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  10482d:	75 24                	jne    104853 <pmap_check+0xa2>
  10482f:	c7 44 24 0c a4 8e 10 	movl   $0x108ea4,0xc(%esp)
  104836:	00 
  104837:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10483e:	00 
  10483f:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
  104846:	00 
  104847:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10484e:	e8 2e bc ff ff       	call   100481 <debug_panic>
	assert(pi2 && pi2 != pi1 && pi2 != pi0);
  104853:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  104857:	74 10                	je     104869 <pmap_check+0xb8>
  104859:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10485c:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  10485f:	74 08                	je     104869 <pmap_check+0xb8>
  104861:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104864:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  104867:	75 24                	jne    10488d <pmap_check+0xdc>
  104869:	c7 44 24 0c b8 8e 10 	movl   $0x108eb8,0xc(%esp)
  104870:	00 
  104871:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104878:	00 
  104879:	c7 44 24 04 8c 01 00 	movl   $0x18c,0x4(%esp)
  104880:	00 
  104881:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104888:	e8 f4 bb ff ff       	call   100481 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  10488d:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  104892:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	mem_freelist = NULL;
  104895:	c7 05 00 dd 11 00 00 	movl   $0x0,0x11dd00
  10489c:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == NULL);
  10489f:	e8 69 c2 ff ff       	call   100b0d <mem_alloc>
  1048a4:	85 c0                	test   %eax,%eax
  1048a6:	74 24                	je     1048cc <pmap_check+0x11b>
  1048a8:	c7 44 24 0c d8 8e 10 	movl   $0x108ed8,0xc(%esp)
  1048af:	00 
  1048b0:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1048b7:	00 
  1048b8:	c7 44 24 04 93 01 00 	movl   $0x193,0x4(%esp)
  1048bf:	00 
  1048c0:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1048c7:	e8 b5 bb ff ff       	call   100481 <debug_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) == NULL);
  1048cc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1048d3:	00 
  1048d4:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  1048db:	40 
  1048dc:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1048df:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048e3:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  1048ea:	e8 12 f9 ff ff       	call   104201 <pmap_insert>
  1048ef:	85 c0                	test   %eax,%eax
  1048f1:	74 24                	je     104917 <pmap_check+0x166>
  1048f3:	c7 44 24 0c ec 8e 10 	movl   $0x108eec,0xc(%esp)
  1048fa:	00 
  1048fb:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104902:	00 
  104903:	c7 44 24 04 96 01 00 	movl   $0x196,0x4(%esp)
  10490a:	00 
  10490b:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104912:	e8 6a bb ff ff       	call   100481 <debug_panic>

	// free pi0 and try again: pi0 should be used for page table
	mem_free(pi0);
  104917:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10491a:	89 04 24             	mov    %eax,(%esp)
  10491d:	e8 32 c2 ff ff       	call   100b54 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) != NULL);
  104922:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104929:	00 
  10492a:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  104931:	40 
  104932:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104935:	89 44 24 04          	mov    %eax,0x4(%esp)
  104939:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104940:	e8 bc f8 ff ff       	call   104201 <pmap_insert>
  104945:	85 c0                	test   %eax,%eax
  104947:	75 24                	jne    10496d <pmap_check+0x1bc>
  104949:	c7 44 24 0c 24 8f 10 	movl   $0x108f24,0xc(%esp)
  104950:	00 
  104951:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104958:	00 
  104959:	c7 44 24 04 9a 01 00 	movl   $0x19a,0x4(%esp)
  104960:	00 
  104961:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104968:	e8 14 bb ff ff       	call   100481 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi0));
  10496d:	a1 00 f4 31 00       	mov    0x31f400,%eax
  104972:	89 c1                	mov    %eax,%ecx
  104974:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  10497a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10497d:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  104982:	89 d3                	mov    %edx,%ebx
  104984:	29 c3                	sub    %eax,%ebx
  104986:	89 d8                	mov    %ebx,%eax
  104988:	c1 f8 03             	sar    $0x3,%eax
  10498b:	c1 e0 0c             	shl    $0xc,%eax
  10498e:	39 c1                	cmp    %eax,%ecx
  104990:	74 24                	je     1049b6 <pmap_check+0x205>
  104992:	c7 44 24 0c 5c 8f 10 	movl   $0x108f5c,0xc(%esp)
  104999:	00 
  10499a:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1049a1:	00 
  1049a2:	c7 44 24 04 9b 01 00 	movl   $0x19b,0x4(%esp)
  1049a9:	00 
  1049aa:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1049b1:	e8 cb ba ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO) == mem_pi2phys(pi1));
  1049b6:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1049bd:	40 
  1049be:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  1049c5:	e8 7a fd ff ff       	call   104744 <va2pa>
  1049ca:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1049cd:	8b 15 58 dd 31 00    	mov    0x31dd58,%edx
  1049d3:	89 cb                	mov    %ecx,%ebx
  1049d5:	29 d3                	sub    %edx,%ebx
  1049d7:	89 da                	mov    %ebx,%edx
  1049d9:	c1 fa 03             	sar    $0x3,%edx
  1049dc:	c1 e2 0c             	shl    $0xc,%edx
  1049df:	39 d0                	cmp    %edx,%eax
  1049e1:	74 24                	je     104a07 <pmap_check+0x256>
  1049e3:	c7 44 24 0c 98 8f 10 	movl   $0x108f98,0xc(%esp)
  1049ea:	00 
  1049eb:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1049f2:	00 
  1049f3:	c7 44 24 04 9c 01 00 	movl   $0x19c,0x4(%esp)
  1049fa:	00 
  1049fb:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104a02:	e8 7a ba ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 1);
  104a07:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104a0a:	8b 40 04             	mov    0x4(%eax),%eax
  104a0d:	83 f8 01             	cmp    $0x1,%eax
  104a10:	74 24                	je     104a36 <pmap_check+0x285>
  104a12:	c7 44 24 0c cc 8f 10 	movl   $0x108fcc,0xc(%esp)
  104a19:	00 
  104a1a:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104a21:	00 
  104a22:	c7 44 24 04 9d 01 00 	movl   $0x19d,0x4(%esp)
  104a29:	00 
  104a2a:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104a31:	e8 4b ba ff ff       	call   100481 <debug_panic>
	assert(pi0->refcount == 1);
  104a36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104a39:	8b 40 04             	mov    0x4(%eax),%eax
  104a3c:	83 f8 01             	cmp    $0x1,%eax
  104a3f:	74 24                	je     104a65 <pmap_check+0x2b4>
  104a41:	c7 44 24 0c df 8f 10 	movl   $0x108fdf,0xc(%esp)
  104a48:	00 
  104a49:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104a50:	00 
  104a51:	c7 44 24 04 9e 01 00 	movl   $0x19e,0x4(%esp)
  104a58:	00 
  104a59:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104a60:	e8 1c ba ff ff       	call   100481 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because pi0 is already allocated for page table
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  104a65:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104a6c:	00 
  104a6d:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  104a74:	40 
  104a75:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104a78:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a7c:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104a83:	e8 79 f7 ff ff       	call   104201 <pmap_insert>
  104a88:	85 c0                	test   %eax,%eax
  104a8a:	75 24                	jne    104ab0 <pmap_check+0x2ff>
  104a8c:	c7 44 24 0c f4 8f 10 	movl   $0x108ff4,0xc(%esp)
  104a93:	00 
  104a94:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104a9b:	00 
  104a9c:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
  104aa3:	00 
  104aa4:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104aab:	e8 d1 b9 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  104ab0:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  104ab7:	40 
  104ab8:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104abf:	e8 80 fc ff ff       	call   104744 <va2pa>
  104ac4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  104ac7:	8b 15 58 dd 31 00    	mov    0x31dd58,%edx
  104acd:	89 cb                	mov    %ecx,%ebx
  104acf:	29 d3                	sub    %edx,%ebx
  104ad1:	89 da                	mov    %ebx,%edx
  104ad3:	c1 fa 03             	sar    $0x3,%edx
  104ad6:	c1 e2 0c             	shl    $0xc,%edx
  104ad9:	39 d0                	cmp    %edx,%eax
  104adb:	74 24                	je     104b01 <pmap_check+0x350>
  104add:	c7 44 24 0c 2c 90 10 	movl   $0x10902c,0xc(%esp)
  104ae4:	00 
  104ae5:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104aec:	00 
  104aed:	c7 44 24 04 a3 01 00 	movl   $0x1a3,0x4(%esp)
  104af4:	00 
  104af5:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104afc:	e8 80 b9 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  104b01:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104b04:	8b 40 04             	mov    0x4(%eax),%eax
  104b07:	83 f8 01             	cmp    $0x1,%eax
  104b0a:	74 24                	je     104b30 <pmap_check+0x37f>
  104b0c:	c7 44 24 0c 69 90 10 	movl   $0x109069,0xc(%esp)
  104b13:	00 
  104b14:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104b1b:	00 
  104b1c:	c7 44 24 04 a4 01 00 	movl   $0x1a4,0x4(%esp)
  104b23:	00 
  104b24:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104b2b:	e8 51 b9 ff ff       	call   100481 <debug_panic>

	// should be no free memory
	assert(mem_alloc() == NULL);
  104b30:	e8 d8 bf ff ff       	call   100b0d <mem_alloc>
  104b35:	85 c0                	test   %eax,%eax
  104b37:	74 24                	je     104b5d <pmap_check+0x3ac>
  104b39:	c7 44 24 0c d8 8e 10 	movl   $0x108ed8,0xc(%esp)
  104b40:	00 
  104b41:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104b48:	00 
  104b49:	c7 44 24 04 a7 01 00 	movl   $0x1a7,0x4(%esp)
  104b50:	00 
  104b51:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104b58:	e8 24 b9 ff ff       	call   100481 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because it's already there
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  104b5d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104b64:	00 
  104b65:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  104b6c:	40 
  104b6d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104b70:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b74:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104b7b:	e8 81 f6 ff ff       	call   104201 <pmap_insert>
  104b80:	85 c0                	test   %eax,%eax
  104b82:	75 24                	jne    104ba8 <pmap_check+0x3f7>
  104b84:	c7 44 24 0c f4 8f 10 	movl   $0x108ff4,0xc(%esp)
  104b8b:	00 
  104b8c:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104b93:	00 
  104b94:	c7 44 24 04 ab 01 00 	movl   $0x1ab,0x4(%esp)
  104b9b:	00 
  104b9c:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104ba3:	e8 d9 b8 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  104ba8:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  104baf:	40 
  104bb0:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104bb7:	e8 88 fb ff ff       	call   104744 <va2pa>
  104bbc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  104bbf:	8b 15 58 dd 31 00    	mov    0x31dd58,%edx
  104bc5:	89 cb                	mov    %ecx,%ebx
  104bc7:	29 d3                	sub    %edx,%ebx
  104bc9:	89 da                	mov    %ebx,%edx
  104bcb:	c1 fa 03             	sar    $0x3,%edx
  104bce:	c1 e2 0c             	shl    $0xc,%edx
  104bd1:	39 d0                	cmp    %edx,%eax
  104bd3:	74 24                	je     104bf9 <pmap_check+0x448>
  104bd5:	c7 44 24 0c 2c 90 10 	movl   $0x10902c,0xc(%esp)
  104bdc:	00 
  104bdd:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104be4:	00 
  104be5:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
  104bec:	00 
  104bed:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104bf4:	e8 88 b8 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  104bf9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104bfc:	8b 40 04             	mov    0x4(%eax),%eax
  104bff:	83 f8 01             	cmp    $0x1,%eax
  104c02:	74 24                	je     104c28 <pmap_check+0x477>
  104c04:	c7 44 24 0c 69 90 10 	movl   $0x109069,0xc(%esp)
  104c0b:	00 
  104c0c:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104c13:	00 
  104c14:	c7 44 24 04 ad 01 00 	movl   $0x1ad,0x4(%esp)
  104c1b:	00 
  104c1c:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104c23:	e8 59 b8 ff ff       	call   100481 <debug_panic>

	// pi2 should NOT be on the free list
	// could hapien in ref counts are handled slopiily in pmap_insert
	assert(mem_alloc() == NULL);
  104c28:	e8 e0 be ff ff       	call   100b0d <mem_alloc>
  104c2d:	85 c0                	test   %eax,%eax
  104c2f:	74 24                	je     104c55 <pmap_check+0x4a4>
  104c31:	c7 44 24 0c d8 8e 10 	movl   $0x108ed8,0xc(%esp)
  104c38:	00 
  104c39:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104c40:	00 
  104c41:	c7 44 24 04 b1 01 00 	movl   $0x1b1,0x4(%esp)
  104c48:	00 
  104c49:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104c50:	e8 2c b8 ff ff       	call   100481 <debug_panic>

	// check that pmap_walk returns a pointer to the pte
	ptep = mem_ptr(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PAGESIZE)]));
  104c55:	a1 00 f4 31 00       	mov    0x31f400,%eax
  104c5a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104c5f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	assert(pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0)
  104c62:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104c69:	00 
  104c6a:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  104c71:	40 
  104c72:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104c79:	e8 40 f5 ff ff       	call   1041be <pmap_walk>
  104c7e:	8b 55 e8             	mov    -0x18(%ebp),%edx
  104c81:	83 c2 04             	add    $0x4,%edx
  104c84:	39 d0                	cmp    %edx,%eax
  104c86:	74 24                	je     104cac <pmap_check+0x4fb>
  104c88:	c7 44 24 0c 7c 90 10 	movl   $0x10907c,0xc(%esp)
  104c8f:	00 
  104c90:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104c97:	00 
  104c98:	c7 44 24 04 b6 01 00 	movl   $0x1b6,0x4(%esp)
  104c9f:	00 
  104ca0:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104ca7:	e8 d5 b7 ff ff       	call   100481 <debug_panic>
		== ptep+PTX(VM_USERLO+PAGESIZE));

	// should be able to change permissions too.
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, PTE_U));
  104cac:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  104cb3:	00 
  104cb4:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  104cbb:	40 
  104cbc:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104cbf:	89 44 24 04          	mov    %eax,0x4(%esp)
  104cc3:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104cca:	e8 32 f5 ff ff       	call   104201 <pmap_insert>
  104ccf:	85 c0                	test   %eax,%eax
  104cd1:	75 24                	jne    104cf7 <pmap_check+0x546>
  104cd3:	c7 44 24 0c cc 90 10 	movl   $0x1090cc,0xc(%esp)
  104cda:	00 
  104cdb:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104ce2:	00 
  104ce3:	c7 44 24 04 b9 01 00 	movl   $0x1b9,0x4(%esp)
  104cea:	00 
  104ceb:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104cf2:	e8 8a b7 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  104cf7:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  104cfe:	40 
  104cff:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104d06:	e8 39 fa ff ff       	call   104744 <va2pa>
  104d0b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  104d0e:	8b 15 58 dd 31 00    	mov    0x31dd58,%edx
  104d14:	89 cb                	mov    %ecx,%ebx
  104d16:	29 d3                	sub    %edx,%ebx
  104d18:	89 da                	mov    %ebx,%edx
  104d1a:	c1 fa 03             	sar    $0x3,%edx
  104d1d:	c1 e2 0c             	shl    $0xc,%edx
  104d20:	39 d0                	cmp    %edx,%eax
  104d22:	74 24                	je     104d48 <pmap_check+0x597>
  104d24:	c7 44 24 0c 2c 90 10 	movl   $0x10902c,0xc(%esp)
  104d2b:	00 
  104d2c:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104d33:	00 
  104d34:	c7 44 24 04 ba 01 00 	movl   $0x1ba,0x4(%esp)
  104d3b:	00 
  104d3c:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104d43:	e8 39 b7 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  104d48:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104d4b:	8b 40 04             	mov    0x4(%eax),%eax
  104d4e:	83 f8 01             	cmp    $0x1,%eax
  104d51:	74 24                	je     104d77 <pmap_check+0x5c6>
  104d53:	c7 44 24 0c 69 90 10 	movl   $0x109069,0xc(%esp)
  104d5a:	00 
  104d5b:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104d62:	00 
  104d63:	c7 44 24 04 bb 01 00 	movl   $0x1bb,0x4(%esp)
  104d6a:	00 
  104d6b:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104d72:	e8 0a b7 ff ff       	call   100481 <debug_panic>
	assert(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U);
  104d77:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104d7e:	00 
  104d7f:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  104d86:	40 
  104d87:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104d8e:	e8 2b f4 ff ff       	call   1041be <pmap_walk>
  104d93:	8b 00                	mov    (%eax),%eax
  104d95:	83 e0 04             	and    $0x4,%eax
  104d98:	85 c0                	test   %eax,%eax
  104d9a:	75 24                	jne    104dc0 <pmap_check+0x60f>
  104d9c:	c7 44 24 0c 08 91 10 	movl   $0x109108,0xc(%esp)
  104da3:	00 
  104da4:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104dab:	00 
  104dac:	c7 44 24 04 bc 01 00 	movl   $0x1bc,0x4(%esp)
  104db3:	00 
  104db4:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104dbb:	e8 c1 b6 ff ff       	call   100481 <debug_panic>
	assert(pmap_bootpdir[PDX(VM_USERLO)] & PTE_U);
  104dc0:	a1 00 f4 31 00       	mov    0x31f400,%eax
  104dc5:	83 e0 04             	and    $0x4,%eax
  104dc8:	85 c0                	test   %eax,%eax
  104dca:	75 24                	jne    104df0 <pmap_check+0x63f>
  104dcc:	c7 44 24 0c 44 91 10 	movl   $0x109144,0xc(%esp)
  104dd3:	00 
  104dd4:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104ddb:	00 
  104ddc:	c7 44 24 04 bd 01 00 	movl   $0x1bd,0x4(%esp)
  104de3:	00 
  104de4:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104deb:	e8 91 b6 ff ff       	call   100481 <debug_panic>
	
	// should not be able to map at VM_USERLO+PTSIZE
	// because we need a free page for a page table
	assert(pmap_insert(pmap_bootpdir, pi0, VM_USERLO+PTSIZE, 0) == NULL);
  104df0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104df7:	00 
  104df8:	c7 44 24 08 00 00 40 	movl   $0x40400000,0x8(%esp)
  104dff:	40 
  104e00:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104e03:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e07:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104e0e:	e8 ee f3 ff ff       	call   104201 <pmap_insert>
  104e13:	85 c0                	test   %eax,%eax
  104e15:	74 24                	je     104e3b <pmap_check+0x68a>
  104e17:	c7 44 24 0c 6c 91 10 	movl   $0x10916c,0xc(%esp)
  104e1e:	00 
  104e1f:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104e26:	00 
  104e27:	c7 44 24 04 c1 01 00 	movl   $0x1c1,0x4(%esp)
  104e2e:	00 
  104e2f:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104e36:	e8 46 b6 ff ff       	call   100481 <debug_panic>

	// insert pi1 at VM_USERLO+PAGESIZE (replacing pi2)
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO+PAGESIZE, 0));
  104e3b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104e42:	00 
  104e43:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  104e4a:	40 
  104e4b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104e4e:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e52:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104e59:	e8 a3 f3 ff ff       	call   104201 <pmap_insert>
  104e5e:	85 c0                	test   %eax,%eax
  104e60:	75 24                	jne    104e86 <pmap_check+0x6d5>
  104e62:	c7 44 24 0c ac 91 10 	movl   $0x1091ac,0xc(%esp)
  104e69:	00 
  104e6a:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104e71:	00 
  104e72:	c7 44 24 04 c4 01 00 	movl   $0x1c4,0x4(%esp)
  104e79:	00 
  104e7a:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104e81:	e8 fb b5 ff ff       	call   100481 <debug_panic>
	assert(!(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U));
  104e86:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104e8d:	00 
  104e8e:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  104e95:	40 
  104e96:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104e9d:	e8 1c f3 ff ff       	call   1041be <pmap_walk>
  104ea2:	8b 00                	mov    (%eax),%eax
  104ea4:	83 e0 04             	and    $0x4,%eax
  104ea7:	85 c0                	test   %eax,%eax
  104ea9:	74 24                	je     104ecf <pmap_check+0x71e>
  104eab:	c7 44 24 0c e4 91 10 	movl   $0x1091e4,0xc(%esp)
  104eb2:	00 
  104eb3:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104eba:	00 
  104ebb:	c7 44 24 04 c5 01 00 	movl   $0x1c5,0x4(%esp)
  104ec2:	00 
  104ec3:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104eca:	e8 b2 b5 ff ff       	call   100481 <debug_panic>

	// should have pi1 at both +0 and +PAGESIZE, pi2 nowhere, ...
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == mem_pi2phys(pi1));
  104ecf:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  104ed6:	40 
  104ed7:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104ede:	e8 61 f8 ff ff       	call   104744 <va2pa>
  104ee3:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  104ee6:	8b 15 58 dd 31 00    	mov    0x31dd58,%edx
  104eec:	89 cb                	mov    %ecx,%ebx
  104eee:	29 d3                	sub    %edx,%ebx
  104ef0:	89 da                	mov    %ebx,%edx
  104ef2:	c1 fa 03             	sar    $0x3,%edx
  104ef5:	c1 e2 0c             	shl    $0xc,%edx
  104ef8:	39 d0                	cmp    %edx,%eax
  104efa:	74 24                	je     104f20 <pmap_check+0x76f>
  104efc:	c7 44 24 0c 20 92 10 	movl   $0x109220,0xc(%esp)
  104f03:	00 
  104f04:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104f0b:	00 
  104f0c:	c7 44 24 04 c8 01 00 	movl   $0x1c8,0x4(%esp)
  104f13:	00 
  104f14:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104f1b:	e8 61 b5 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  104f20:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  104f27:	40 
  104f28:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  104f2f:	e8 10 f8 ff ff       	call   104744 <va2pa>
  104f34:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  104f37:	8b 15 58 dd 31 00    	mov    0x31dd58,%edx
  104f3d:	89 cb                	mov    %ecx,%ebx
  104f3f:	29 d3                	sub    %edx,%ebx
  104f41:	89 da                	mov    %ebx,%edx
  104f43:	c1 fa 03             	sar    $0x3,%edx
  104f46:	c1 e2 0c             	shl    $0xc,%edx
  104f49:	39 d0                	cmp    %edx,%eax
  104f4b:	74 24                	je     104f71 <pmap_check+0x7c0>
  104f4d:	c7 44 24 0c 58 92 10 	movl   $0x109258,0xc(%esp)
  104f54:	00 
  104f55:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104f5c:	00 
  104f5d:	c7 44 24 04 c9 01 00 	movl   $0x1c9,0x4(%esp)
  104f64:	00 
  104f65:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104f6c:	e8 10 b5 ff ff       	call   100481 <debug_panic>
	// ... and ref counts should reflect this
	assert(pi1->refcount == 2);
  104f71:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104f74:	8b 40 04             	mov    0x4(%eax),%eax
  104f77:	83 f8 02             	cmp    $0x2,%eax
  104f7a:	74 24                	je     104fa0 <pmap_check+0x7ef>
  104f7c:	c7 44 24 0c 95 92 10 	movl   $0x109295,0xc(%esp)
  104f83:	00 
  104f84:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104f8b:	00 
  104f8c:	c7 44 24 04 cb 01 00 	movl   $0x1cb,0x4(%esp)
  104f93:	00 
  104f94:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104f9b:	e8 e1 b4 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 0);
  104fa0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104fa3:	8b 40 04             	mov    0x4(%eax),%eax
  104fa6:	85 c0                	test   %eax,%eax
  104fa8:	74 24                	je     104fce <pmap_check+0x81d>
  104faa:	c7 44 24 0c a8 92 10 	movl   $0x1092a8,0xc(%esp)
  104fb1:	00 
  104fb2:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104fb9:	00 
  104fba:	c7 44 24 04 cc 01 00 	movl   $0x1cc,0x4(%esp)
  104fc1:	00 
  104fc2:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104fc9:	e8 b3 b4 ff ff       	call   100481 <debug_panic>

	// pi2 should be returned by mem_alloc
	assert(mem_alloc() == pi2);
  104fce:	e8 3a bb ff ff       	call   100b0d <mem_alloc>
  104fd3:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  104fd6:	74 24                	je     104ffc <pmap_check+0x84b>
  104fd8:	c7 44 24 0c bb 92 10 	movl   $0x1092bb,0xc(%esp)
  104fdf:	00 
  104fe0:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  104fe7:	00 
  104fe8:	c7 44 24 04 cf 01 00 	movl   $0x1cf,0x4(%esp)
  104fef:	00 
  104ff0:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  104ff7:	e8 85 b4 ff ff       	call   100481 <debug_panic>

	// unmapping pi1 at VM_USERLO+0 should keep pi1 at +PAGESIZE
	pmap_remove(pmap_bootpdir, VM_USERLO+0, PAGESIZE);
  104ffc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105003:	00 
  105004:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  10500b:	40 
  10500c:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105013:	e8 f3 f1 ff ff       	call   10420b <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  105018:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  10501f:	40 
  105020:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105027:	e8 18 f7 ff ff       	call   104744 <va2pa>
  10502c:	83 f8 ff             	cmp    $0xffffffff,%eax
  10502f:	74 24                	je     105055 <pmap_check+0x8a4>
  105031:	c7 44 24 0c d0 92 10 	movl   $0x1092d0,0xc(%esp)
  105038:	00 
  105039:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105040:	00 
  105041:	c7 44 24 04 d3 01 00 	movl   $0x1d3,0x4(%esp)
  105048:	00 
  105049:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105050:	e8 2c b4 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  105055:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10505c:	40 
  10505d:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105064:	e8 db f6 ff ff       	call   104744 <va2pa>
  105069:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  10506c:	8b 15 58 dd 31 00    	mov    0x31dd58,%edx
  105072:	89 cb                	mov    %ecx,%ebx
  105074:	29 d3                	sub    %edx,%ebx
  105076:	89 da                	mov    %ebx,%edx
  105078:	c1 fa 03             	sar    $0x3,%edx
  10507b:	c1 e2 0c             	shl    $0xc,%edx
  10507e:	39 d0                	cmp    %edx,%eax
  105080:	74 24                	je     1050a6 <pmap_check+0x8f5>
  105082:	c7 44 24 0c 58 92 10 	movl   $0x109258,0xc(%esp)
  105089:	00 
  10508a:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105091:	00 
  105092:	c7 44 24 04 d4 01 00 	movl   $0x1d4,0x4(%esp)
  105099:	00 
  10509a:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1050a1:	e8 db b3 ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 1);
  1050a6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1050a9:	8b 40 04             	mov    0x4(%eax),%eax
  1050ac:	83 f8 01             	cmp    $0x1,%eax
  1050af:	74 24                	je     1050d5 <pmap_check+0x924>
  1050b1:	c7 44 24 0c cc 8f 10 	movl   $0x108fcc,0xc(%esp)
  1050b8:	00 
  1050b9:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1050c0:	00 
  1050c1:	c7 44 24 04 d5 01 00 	movl   $0x1d5,0x4(%esp)
  1050c8:	00 
  1050c9:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1050d0:	e8 ac b3 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 0);
  1050d5:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1050d8:	8b 40 04             	mov    0x4(%eax),%eax
  1050db:	85 c0                	test   %eax,%eax
  1050dd:	74 24                	je     105103 <pmap_check+0x952>
  1050df:	c7 44 24 0c a8 92 10 	movl   $0x1092a8,0xc(%esp)
  1050e6:	00 
  1050e7:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1050ee:	00 
  1050ef:	c7 44 24 04 d6 01 00 	movl   $0x1d6,0x4(%esp)
  1050f6:	00 
  1050f7:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1050fe:	e8 7e b3 ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == NULL);	// still should have no pages free
  105103:	e8 05 ba ff ff       	call   100b0d <mem_alloc>
  105108:	85 c0                	test   %eax,%eax
  10510a:	74 24                	je     105130 <pmap_check+0x97f>
  10510c:	c7 44 24 0c d8 8e 10 	movl   $0x108ed8,0xc(%esp)
  105113:	00 
  105114:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10511b:	00 
  10511c:	c7 44 24 04 d7 01 00 	movl   $0x1d7,0x4(%esp)
  105123:	00 
  105124:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10512b:	e8 51 b3 ff ff       	call   100481 <debug_panic>

	// unmapping pi1 at VM_USERLO+PAGESIZE should free it
	pmap_remove(pmap_bootpdir, VM_USERLO+PAGESIZE, PAGESIZE);
  105130:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105137:	00 
  105138:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10513f:	40 
  105140:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105147:	e8 bf f0 ff ff       	call   10420b <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  10514c:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105153:	40 
  105154:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  10515b:	e8 e4 f5 ff ff       	call   104744 <va2pa>
  105160:	83 f8 ff             	cmp    $0xffffffff,%eax
  105163:	74 24                	je     105189 <pmap_check+0x9d8>
  105165:	c7 44 24 0c d0 92 10 	movl   $0x1092d0,0xc(%esp)
  10516c:	00 
  10516d:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105174:	00 
  105175:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
  10517c:	00 
  10517d:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105184:	e8 f8 b2 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == ~0);
  105189:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105190:	40 
  105191:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105198:	e8 a7 f5 ff ff       	call   104744 <va2pa>
  10519d:	83 f8 ff             	cmp    $0xffffffff,%eax
  1051a0:	74 24                	je     1051c6 <pmap_check+0xa15>
  1051a2:	c7 44 24 0c f8 92 10 	movl   $0x1092f8,0xc(%esp)
  1051a9:	00 
  1051aa:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1051b1:	00 
  1051b2:	c7 44 24 04 dc 01 00 	movl   $0x1dc,0x4(%esp)
  1051b9:	00 
  1051ba:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1051c1:	e8 bb b2 ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 0);
  1051c6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1051c9:	8b 40 04             	mov    0x4(%eax),%eax
  1051cc:	85 c0                	test   %eax,%eax
  1051ce:	74 24                	je     1051f4 <pmap_check+0xa43>
  1051d0:	c7 44 24 0c 27 93 10 	movl   $0x109327,0xc(%esp)
  1051d7:	00 
  1051d8:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1051df:	00 
  1051e0:	c7 44 24 04 dd 01 00 	movl   $0x1dd,0x4(%esp)
  1051e7:	00 
  1051e8:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1051ef:	e8 8d b2 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 0);
  1051f4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1051f7:	8b 40 04             	mov    0x4(%eax),%eax
  1051fa:	85 c0                	test   %eax,%eax
  1051fc:	74 24                	je     105222 <pmap_check+0xa71>
  1051fe:	c7 44 24 0c a8 92 10 	movl   $0x1092a8,0xc(%esp)
  105205:	00 
  105206:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10520d:	00 
  10520e:	c7 44 24 04 de 01 00 	movl   $0x1de,0x4(%esp)
  105215:	00 
  105216:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10521d:	e8 5f b2 ff ff       	call   100481 <debug_panic>

	// so it should be returned by page_alloc
	assert(mem_alloc() == pi1);
  105222:	e8 e6 b8 ff ff       	call   100b0d <mem_alloc>
  105227:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  10522a:	74 24                	je     105250 <pmap_check+0xa9f>
  10522c:	c7 44 24 0c 3a 93 10 	movl   $0x10933a,0xc(%esp)
  105233:	00 
  105234:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10523b:	00 
  10523c:	c7 44 24 04 e1 01 00 	movl   $0x1e1,0x4(%esp)
  105243:	00 
  105244:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10524b:	e8 31 b2 ff ff       	call   100481 <debug_panic>

	// should once again have no free memory
	assert(mem_alloc() == NULL);
  105250:	e8 b8 b8 ff ff       	call   100b0d <mem_alloc>
  105255:	85 c0                	test   %eax,%eax
  105257:	74 24                	je     10527d <pmap_check+0xacc>
  105259:	c7 44 24 0c d8 8e 10 	movl   $0x108ed8,0xc(%esp)
  105260:	00 
  105261:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105268:	00 
  105269:	c7 44 24 04 e4 01 00 	movl   $0x1e4,0x4(%esp)
  105270:	00 
  105271:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105278:	e8 04 b2 ff ff       	call   100481 <debug_panic>

	// should be able to pmap_insert to change a page
	// and see the new data immediately.
	memset(mem_pi2ptr(pi1), 1, PAGESIZE);
  10527d:	8b 55 d8             	mov    -0x28(%ebp),%edx
  105280:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  105285:	89 d1                	mov    %edx,%ecx
  105287:	29 c1                	sub    %eax,%ecx
  105289:	89 c8                	mov    %ecx,%eax
  10528b:	c1 f8 03             	sar    $0x3,%eax
  10528e:	c1 e0 0c             	shl    $0xc,%eax
  105291:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105298:	00 
  105299:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1052a0:	00 
  1052a1:	89 04 24             	mov    %eax,(%esp)
  1052a4:	e8 be 23 00 00       	call   107667 <memset>
	memset(mem_pi2ptr(pi2), 2, PAGESIZE);
  1052a9:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1052ac:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  1052b1:	89 d3                	mov    %edx,%ebx
  1052b3:	29 c3                	sub    %eax,%ebx
  1052b5:	89 d8                	mov    %ebx,%eax
  1052b7:	c1 f8 03             	sar    $0x3,%eax
  1052ba:	c1 e0 0c             	shl    $0xc,%eax
  1052bd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1052c4:	00 
  1052c5:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  1052cc:	00 
  1052cd:	89 04 24             	mov    %eax,(%esp)
  1052d0:	e8 92 23 00 00       	call   107667 <memset>
	pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0);
  1052d5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1052dc:	00 
  1052dd:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  1052e4:	40 
  1052e5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1052e8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1052ec:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  1052f3:	e8 09 ef ff ff       	call   104201 <pmap_insert>
	assert(pi1->refcount == 1);
  1052f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1052fb:	8b 40 04             	mov    0x4(%eax),%eax
  1052fe:	83 f8 01             	cmp    $0x1,%eax
  105301:	74 24                	je     105327 <pmap_check+0xb76>
  105303:	c7 44 24 0c cc 8f 10 	movl   $0x108fcc,0xc(%esp)
  10530a:	00 
  10530b:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105312:	00 
  105313:	c7 44 24 04 eb 01 00 	movl   $0x1eb,0x4(%esp)
  10531a:	00 
  10531b:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105322:	e8 5a b1 ff ff       	call   100481 <debug_panic>
	assert(*(int*)VM_USERLO == 0x01010101);
  105327:	b8 00 00 00 40       	mov    $0x40000000,%eax
  10532c:	8b 00                	mov    (%eax),%eax
  10532e:	3d 01 01 01 01       	cmp    $0x1010101,%eax
  105333:	74 24                	je     105359 <pmap_check+0xba8>
  105335:	c7 44 24 0c 50 93 10 	movl   $0x109350,0xc(%esp)
  10533c:	00 
  10533d:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105344:	00 
  105345:	c7 44 24 04 ec 01 00 	movl   $0x1ec,0x4(%esp)
  10534c:	00 
  10534d:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105354:	e8 28 b1 ff ff       	call   100481 <debug_panic>
	pmap_insert(pmap_bootpdir, pi2, VM_USERLO, 0);
  105359:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105360:	00 
  105361:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  105368:	40 
  105369:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10536c:	89 44 24 04          	mov    %eax,0x4(%esp)
  105370:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105377:	e8 85 ee ff ff       	call   104201 <pmap_insert>
	assert(*(int*)VM_USERLO == 0x02020202);
  10537c:	b8 00 00 00 40       	mov    $0x40000000,%eax
  105381:	8b 00                	mov    (%eax),%eax
  105383:	3d 02 02 02 02       	cmp    $0x2020202,%eax
  105388:	74 24                	je     1053ae <pmap_check+0xbfd>
  10538a:	c7 44 24 0c 70 93 10 	movl   $0x109370,0xc(%esp)
  105391:	00 
  105392:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105399:	00 
  10539a:	c7 44 24 04 ee 01 00 	movl   $0x1ee,0x4(%esp)
  1053a1:	00 
  1053a2:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1053a9:	e8 d3 b0 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  1053ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1053b1:	8b 40 04             	mov    0x4(%eax),%eax
  1053b4:	83 f8 01             	cmp    $0x1,%eax
  1053b7:	74 24                	je     1053dd <pmap_check+0xc2c>
  1053b9:	c7 44 24 0c 69 90 10 	movl   $0x109069,0xc(%esp)
  1053c0:	00 
  1053c1:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1053c8:	00 
  1053c9:	c7 44 24 04 ef 01 00 	movl   $0x1ef,0x4(%esp)
  1053d0:	00 
  1053d1:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1053d8:	e8 a4 b0 ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 0);
  1053dd:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1053e0:	8b 40 04             	mov    0x4(%eax),%eax
  1053e3:	85 c0                	test   %eax,%eax
  1053e5:	74 24                	je     10540b <pmap_check+0xc5a>
  1053e7:	c7 44 24 0c 27 93 10 	movl   $0x109327,0xc(%esp)
  1053ee:	00 
  1053ef:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1053f6:	00 
  1053f7:	c7 44 24 04 f0 01 00 	movl   $0x1f0,0x4(%esp)
  1053fe:	00 
  1053ff:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105406:	e8 76 b0 ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == pi1);
  10540b:	e8 fd b6 ff ff       	call   100b0d <mem_alloc>
  105410:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  105413:	74 24                	je     105439 <pmap_check+0xc88>
  105415:	c7 44 24 0c 3a 93 10 	movl   $0x10933a,0xc(%esp)
  10541c:	00 
  10541d:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105424:	00 
  105425:	c7 44 24 04 f1 01 00 	movl   $0x1f1,0x4(%esp)
  10542c:	00 
  10542d:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105434:	e8 48 b0 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, VM_USERLO, PAGESIZE);
  105439:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105440:	00 
  105441:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105448:	40 
  105449:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105450:	e8 b6 ed ff ff       	call   10420b <pmap_remove>
	assert(pi2->refcount == 0);
  105455:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105458:	8b 40 04             	mov    0x4(%eax),%eax
  10545b:	85 c0                	test   %eax,%eax
  10545d:	74 24                	je     105483 <pmap_check+0xcd2>
  10545f:	c7 44 24 0c a8 92 10 	movl   $0x1092a8,0xc(%esp)
  105466:	00 
  105467:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10546e:	00 
  10546f:	c7 44 24 04 f3 01 00 	movl   $0x1f3,0x4(%esp)
  105476:	00 
  105477:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10547e:	e8 fe af ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == pi2);
  105483:	e8 85 b6 ff ff       	call   100b0d <mem_alloc>
  105488:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  10548b:	74 24                	je     1054b1 <pmap_check+0xd00>
  10548d:	c7 44 24 0c bb 92 10 	movl   $0x1092bb,0xc(%esp)
  105494:	00 
  105495:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10549c:	00 
  10549d:	c7 44 24 04 f4 01 00 	movl   $0x1f4,0x4(%esp)
  1054a4:	00 
  1054a5:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1054ac:	e8 d0 af ff ff       	call   100481 <debug_panic>

	// now use a pmap_remove on a large region to take pi0 back
	pmap_remove(pmap_bootpdir, VM_USERLO, VM_USERHI-VM_USERLO);
  1054b1:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  1054b8:	b0 
  1054b9:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1054c0:	40 
  1054c1:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  1054c8:	e8 3e ed ff ff       	call   10420b <pmap_remove>
	assert(pmap_bootpdir[PDX(VM_USERLO)] == PTE_ZERO);
  1054cd:	8b 15 00 f4 31 00    	mov    0x31f400,%edx
  1054d3:	b8 00 00 32 00       	mov    $0x320000,%eax
  1054d8:	39 c2                	cmp    %eax,%edx
  1054da:	74 24                	je     105500 <pmap_check+0xd4f>
  1054dc:	c7 44 24 0c 90 93 10 	movl   $0x109390,0xc(%esp)
  1054e3:	00 
  1054e4:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1054eb:	00 
  1054ec:	c7 44 24 04 f8 01 00 	movl   $0x1f8,0x4(%esp)
  1054f3:	00 
  1054f4:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1054fb:	e8 81 af ff ff       	call   100481 <debug_panic>
	assert(pi0->refcount == 0);
  105500:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105503:	8b 40 04             	mov    0x4(%eax),%eax
  105506:	85 c0                	test   %eax,%eax
  105508:	74 24                	je     10552e <pmap_check+0xd7d>
  10550a:	c7 44 24 0c ba 93 10 	movl   $0x1093ba,0xc(%esp)
  105511:	00 
  105512:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105519:	00 
  10551a:	c7 44 24 04 f9 01 00 	movl   $0x1f9,0x4(%esp)
  105521:	00 
  105522:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105529:	e8 53 af ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == pi0);
  10552e:	e8 da b5 ff ff       	call   100b0d <mem_alloc>
  105533:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  105536:	74 24                	je     10555c <pmap_check+0xdab>
  105538:	c7 44 24 0c cd 93 10 	movl   $0x1093cd,0xc(%esp)
  10553f:	00 
  105540:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105547:	00 
  105548:	c7 44 24 04 fa 01 00 	movl   $0x1fa,0x4(%esp)
  10554f:	00 
  105550:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105557:	e8 25 af ff ff       	call   100481 <debug_panic>
	assert(mem_freelist == NULL);
  10555c:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  105561:	85 c0                	test   %eax,%eax
  105563:	74 24                	je     105589 <pmap_check+0xdd8>
  105565:	c7 44 24 0c e0 93 10 	movl   $0x1093e0,0xc(%esp)
  10556c:	00 
  10556d:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105574:	00 
  105575:	c7 44 24 04 fb 01 00 	movl   $0x1fb,0x4(%esp)
  10557c:	00 
  10557d:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105584:	e8 f8 ae ff ff       	call   100481 <debug_panic>

	// test pmap_remove with large, non-ptable-aligned regions
	mem_free(pi1);
  105589:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10558c:	89 04 24             	mov    %eax,(%esp)
  10558f:	e8 c0 b5 ff ff       	call   100b54 <mem_free>
	uintptr_t va = VM_USERLO;
  105594:	c7 45 f4 00 00 00 40 	movl   $0x40000000,-0xc(%ebp)
	assert(pmap_insert(pmap_bootpdir, pi0, va, 0));
  10559b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1055a2:	00 
  1055a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1055a6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1055aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1055ad:	89 44 24 04          	mov    %eax,0x4(%esp)
  1055b1:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  1055b8:	e8 44 ec ff ff       	call   104201 <pmap_insert>
  1055bd:	85 c0                	test   %eax,%eax
  1055bf:	75 24                	jne    1055e5 <pmap_check+0xe34>
  1055c1:	c7 44 24 0c f8 93 10 	movl   $0x1093f8,0xc(%esp)
  1055c8:	00 
  1055c9:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1055d0:	00 
  1055d1:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
  1055d8:	00 
  1055d9:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1055e0:	e8 9c ae ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PAGESIZE, 0));
  1055e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1055e8:	05 00 10 00 00       	add    $0x1000,%eax
  1055ed:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1055f4:	00 
  1055f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  1055f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1055fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  105600:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105607:	e8 f5 eb ff ff       	call   104201 <pmap_insert>
  10560c:	85 c0                	test   %eax,%eax
  10560e:	75 24                	jne    105634 <pmap_check+0xe83>
  105610:	c7 44 24 0c 20 94 10 	movl   $0x109420,0xc(%esp)
  105617:	00 
  105618:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10561f:	00 
  105620:	c7 44 24 04 01 02 00 	movl   $0x201,0x4(%esp)
  105627:	00 
  105628:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10562f:	e8 4d ae ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE-PAGESIZE, 0));
  105634:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105637:	05 00 f0 3f 00       	add    $0x3ff000,%eax
  10563c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105643:	00 
  105644:	89 44 24 08          	mov    %eax,0x8(%esp)
  105648:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10564b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10564f:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105656:	e8 a6 eb ff ff       	call   104201 <pmap_insert>
  10565b:	85 c0                	test   %eax,%eax
  10565d:	75 24                	jne    105683 <pmap_check+0xed2>
  10565f:	c7 44 24 0c 50 94 10 	movl   $0x109450,0xc(%esp)
  105666:	00 
  105667:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10566e:	00 
  10566f:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
  105676:	00 
  105677:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10567e:	e8 fe ad ff ff       	call   100481 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi1));
  105683:	a1 00 f4 31 00       	mov    0x31f400,%eax
  105688:	89 c1                	mov    %eax,%ecx
  10568a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  105690:	8b 55 d8             	mov    -0x28(%ebp),%edx
  105693:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  105698:	89 d3                	mov    %edx,%ebx
  10569a:	29 c3                	sub    %eax,%ebx
  10569c:	89 d8                	mov    %ebx,%eax
  10569e:	c1 f8 03             	sar    $0x3,%eax
  1056a1:	c1 e0 0c             	shl    $0xc,%eax
  1056a4:	39 c1                	cmp    %eax,%ecx
  1056a6:	74 24                	je     1056cc <pmap_check+0xf1b>
  1056a8:	c7 44 24 0c 88 94 10 	movl   $0x109488,0xc(%esp)
  1056af:	00 
  1056b0:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1056b7:	00 
  1056b8:	c7 44 24 04 03 02 00 	movl   $0x203,0x4(%esp)
  1056bf:	00 
  1056c0:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1056c7:	e8 b5 ad ff ff       	call   100481 <debug_panic>
	assert(mem_freelist == NULL);
  1056cc:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  1056d1:	85 c0                	test   %eax,%eax
  1056d3:	74 24                	je     1056f9 <pmap_check+0xf48>
  1056d5:	c7 44 24 0c e0 93 10 	movl   $0x1093e0,0xc(%esp)
  1056dc:	00 
  1056dd:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1056e4:	00 
  1056e5:	c7 44 24 04 04 02 00 	movl   $0x204,0x4(%esp)
  1056ec:	00 
  1056ed:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1056f4:	e8 88 ad ff ff       	call   100481 <debug_panic>
	mem_free(pi2);
  1056f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1056fc:	89 04 24             	mov    %eax,(%esp)
  1056ff:	e8 50 b4 ff ff       	call   100b54 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE, 0));
  105704:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105707:	05 00 00 40 00       	add    $0x400000,%eax
  10570c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105713:	00 
  105714:	89 44 24 08          	mov    %eax,0x8(%esp)
  105718:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10571b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10571f:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105726:	e8 d6 ea ff ff       	call   104201 <pmap_insert>
  10572b:	85 c0                	test   %eax,%eax
  10572d:	75 24                	jne    105753 <pmap_check+0xfa2>
  10572f:	c7 44 24 0c c4 94 10 	movl   $0x1094c4,0xc(%esp)
  105736:	00 
  105737:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10573e:	00 
  10573f:	c7 44 24 04 06 02 00 	movl   $0x206,0x4(%esp)
  105746:	00 
  105747:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10574e:	e8 2e ad ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE+PAGESIZE, 0));
  105753:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105756:	05 00 10 40 00       	add    $0x401000,%eax
  10575b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105762:	00 
  105763:	89 44 24 08          	mov    %eax,0x8(%esp)
  105767:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10576a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10576e:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105775:	e8 87 ea ff ff       	call   104201 <pmap_insert>
  10577a:	85 c0                	test   %eax,%eax
  10577c:	75 24                	jne    1057a2 <pmap_check+0xff1>
  10577e:	c7 44 24 0c f4 94 10 	movl   $0x1094f4,0xc(%esp)
  105785:	00 
  105786:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10578d:	00 
  10578e:	c7 44 24 04 07 02 00 	movl   $0x207,0x4(%esp)
  105795:	00 
  105796:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10579d:	e8 df ac ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2-PAGESIZE, 0));
  1057a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1057a5:	05 00 f0 7f 00       	add    $0x7ff000,%eax
  1057aa:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1057b1:	00 
  1057b2:	89 44 24 08          	mov    %eax,0x8(%esp)
  1057b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1057b9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1057bd:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  1057c4:	e8 38 ea ff ff       	call   104201 <pmap_insert>
  1057c9:	85 c0                	test   %eax,%eax
  1057cb:	75 24                	jne    1057f1 <pmap_check+0x1040>
  1057cd:	c7 44 24 0c 2c 95 10 	movl   $0x10952c,0xc(%esp)
  1057d4:	00 
  1057d5:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1057dc:	00 
  1057dd:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
  1057e4:	00 
  1057e5:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1057ec:	e8 90 ac ff ff       	call   100481 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE)])
  1057f1:	a1 04 f4 31 00       	mov    0x31f404,%eax
  1057f6:	89 c1                	mov    %eax,%ecx
  1057f8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1057fe:	8b 55 dc             	mov    -0x24(%ebp),%edx
  105801:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  105806:	89 d3                	mov    %edx,%ebx
  105808:	29 c3                	sub    %eax,%ebx
  10580a:	89 d8                	mov    %ebx,%eax
  10580c:	c1 f8 03             	sar    $0x3,%eax
  10580f:	c1 e0 0c             	shl    $0xc,%eax
  105812:	39 c1                	cmp    %eax,%ecx
  105814:	74 24                	je     10583a <pmap_check+0x1089>
  105816:	c7 44 24 0c 68 95 10 	movl   $0x109568,0xc(%esp)
  10581d:	00 
  10581e:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105825:	00 
  105826:	c7 44 24 04 0a 02 00 	movl   $0x20a,0x4(%esp)
  10582d:	00 
  10582e:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105835:	e8 47 ac ff ff       	call   100481 <debug_panic>
		== mem_pi2phys(pi2));
	assert(mem_freelist == NULL);
  10583a:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  10583f:	85 c0                	test   %eax,%eax
  105841:	74 24                	je     105867 <pmap_check+0x10b6>
  105843:	c7 44 24 0c e0 93 10 	movl   $0x1093e0,0xc(%esp)
  10584a:	00 
  10584b:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105852:	00 
  105853:	c7 44 24 04 0b 02 00 	movl   $0x20b,0x4(%esp)
  10585a:	00 
  10585b:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105862:	e8 1a ac ff ff       	call   100481 <debug_panic>
	mem_free(pi3);
  105867:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10586a:	89 04 24             	mov    %eax,(%esp)
  10586d:	e8 e2 b2 ff ff       	call   100b54 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2, 0));
  105872:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105875:	05 00 00 80 00       	add    $0x800000,%eax
  10587a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105881:	00 
  105882:	89 44 24 08          	mov    %eax,0x8(%esp)
  105886:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105889:	89 44 24 04          	mov    %eax,0x4(%esp)
  10588d:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105894:	e8 68 e9 ff ff       	call   104201 <pmap_insert>
  105899:	85 c0                	test   %eax,%eax
  10589b:	75 24                	jne    1058c1 <pmap_check+0x1110>
  10589d:	c7 44 24 0c ac 95 10 	movl   $0x1095ac,0xc(%esp)
  1058a4:	00 
  1058a5:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1058ac:	00 
  1058ad:	c7 44 24 04 0d 02 00 	movl   $0x20d,0x4(%esp)
  1058b4:	00 
  1058b5:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1058bc:	e8 c0 ab ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2+PAGESIZE, 0));
  1058c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1058c4:	05 00 10 80 00       	add    $0x801000,%eax
  1058c9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1058d0:	00 
  1058d1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1058d5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1058d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1058dc:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  1058e3:	e8 19 e9 ff ff       	call   104201 <pmap_insert>
  1058e8:	85 c0                	test   %eax,%eax
  1058ea:	75 24                	jne    105910 <pmap_check+0x115f>
  1058ec:	c7 44 24 0c dc 95 10 	movl   $0x1095dc,0xc(%esp)
  1058f3:	00 
  1058f4:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1058fb:	00 
  1058fc:	c7 44 24 04 0e 02 00 	movl   $0x20e,0x4(%esp)
  105903:	00 
  105904:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10590b:	e8 71 ab ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE*2, 0));
  105910:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105913:	05 00 e0 bf 00       	add    $0xbfe000,%eax
  105918:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10591f:	00 
  105920:	89 44 24 08          	mov    %eax,0x8(%esp)
  105924:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105927:	89 44 24 04          	mov    %eax,0x4(%esp)
  10592b:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105932:	e8 ca e8 ff ff       	call   104201 <pmap_insert>
  105937:	85 c0                	test   %eax,%eax
  105939:	75 24                	jne    10595f <pmap_check+0x11ae>
  10593b:	c7 44 24 0c 18 96 10 	movl   $0x109618,0xc(%esp)
  105942:	00 
  105943:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  10594a:	00 
  10594b:	c7 44 24 04 0f 02 00 	movl   $0x20f,0x4(%esp)
  105952:	00 
  105953:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  10595a:	e8 22 ab ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE, 0));
  10595f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105962:	05 00 f0 bf 00       	add    $0xbff000,%eax
  105967:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10596e:	00 
  10596f:	89 44 24 08          	mov    %eax,0x8(%esp)
  105973:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105976:	89 44 24 04          	mov    %eax,0x4(%esp)
  10597a:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105981:	e8 7b e8 ff ff       	call   104201 <pmap_insert>
  105986:	85 c0                	test   %eax,%eax
  105988:	75 24                	jne    1059ae <pmap_check+0x11fd>
  10598a:	c7 44 24 0c 54 96 10 	movl   $0x109654,0xc(%esp)
  105991:	00 
  105992:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105999:	00 
  10599a:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
  1059a1:	00 
  1059a2:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1059a9:	e8 d3 aa ff ff       	call   100481 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE*2)])
  1059ae:	a1 08 f4 31 00       	mov    0x31f408,%eax
  1059b3:	89 c1                	mov    %eax,%ecx
  1059b5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1059bb:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1059be:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  1059c3:	89 d3                	mov    %edx,%ebx
  1059c5:	29 c3                	sub    %eax,%ebx
  1059c7:	89 d8                	mov    %ebx,%eax
  1059c9:	c1 f8 03             	sar    $0x3,%eax
  1059cc:	c1 e0 0c             	shl    $0xc,%eax
  1059cf:	39 c1                	cmp    %eax,%ecx
  1059d1:	74 24                	je     1059f7 <pmap_check+0x1246>
  1059d3:	c7 44 24 0c 90 96 10 	movl   $0x109690,0xc(%esp)
  1059da:	00 
  1059db:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  1059e2:	00 
  1059e3:	c7 44 24 04 12 02 00 	movl   $0x212,0x4(%esp)
  1059ea:	00 
  1059eb:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  1059f2:	e8 8a aa ff ff       	call   100481 <debug_panic>
		== mem_pi2phys(pi3));
	assert(mem_freelist == NULL);
  1059f7:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  1059fc:	85 c0                	test   %eax,%eax
  1059fe:	74 24                	je     105a24 <pmap_check+0x1273>
  105a00:	c7 44 24 0c e0 93 10 	movl   $0x1093e0,0xc(%esp)
  105a07:	00 
  105a08:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105a0f:	00 
  105a10:	c7 44 24 04 13 02 00 	movl   $0x213,0x4(%esp)
  105a17:	00 
  105a18:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105a1f:	e8 5d aa ff ff       	call   100481 <debug_panic>
	assert(pi0->refcount == 10);
  105a24:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105a27:	8b 40 04             	mov    0x4(%eax),%eax
  105a2a:	83 f8 0a             	cmp    $0xa,%eax
  105a2d:	74 24                	je     105a53 <pmap_check+0x12a2>
  105a2f:	c7 44 24 0c d3 96 10 	movl   $0x1096d3,0xc(%esp)
  105a36:	00 
  105a37:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105a3e:	00 
  105a3f:	c7 44 24 04 14 02 00 	movl   $0x214,0x4(%esp)
  105a46:	00 
  105a47:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105a4e:	e8 2e aa ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 1);
  105a53:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105a56:	8b 40 04             	mov    0x4(%eax),%eax
  105a59:	83 f8 01             	cmp    $0x1,%eax
  105a5c:	74 24                	je     105a82 <pmap_check+0x12d1>
  105a5e:	c7 44 24 0c cc 8f 10 	movl   $0x108fcc,0xc(%esp)
  105a65:	00 
  105a66:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105a6d:	00 
  105a6e:	c7 44 24 04 15 02 00 	movl   $0x215,0x4(%esp)
  105a75:	00 
  105a76:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105a7d:	e8 ff a9 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  105a82:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105a85:	8b 40 04             	mov    0x4(%eax),%eax
  105a88:	83 f8 01             	cmp    $0x1,%eax
  105a8b:	74 24                	je     105ab1 <pmap_check+0x1300>
  105a8d:	c7 44 24 0c 69 90 10 	movl   $0x109069,0xc(%esp)
  105a94:	00 
  105a95:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105a9c:	00 
  105a9d:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
  105aa4:	00 
  105aa5:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105aac:	e8 d0 a9 ff ff       	call   100481 <debug_panic>
	assert(pi3->refcount == 1);
  105ab1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105ab4:	8b 40 04             	mov    0x4(%eax),%eax
  105ab7:	83 f8 01             	cmp    $0x1,%eax
  105aba:	74 24                	je     105ae0 <pmap_check+0x132f>
  105abc:	c7 44 24 0c e7 96 10 	movl   $0x1096e7,0xc(%esp)
  105ac3:	00 
  105ac4:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105acb:	00 
  105acc:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
  105ad3:	00 
  105ad4:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105adb:	e8 a1 a9 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3-PAGESIZE*2);
  105ae0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105ae3:	05 00 10 00 00       	add    $0x1000,%eax
  105ae8:	c7 44 24 08 00 e0 bf 	movl   $0xbfe000,0x8(%esp)
  105aef:	00 
  105af0:	89 44 24 04          	mov    %eax,0x4(%esp)
  105af4:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105afb:	e8 0b e7 ff ff       	call   10420b <pmap_remove>
	assert(pi0->refcount == 2);
  105b00:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105b03:	8b 40 04             	mov    0x4(%eax),%eax
  105b06:	83 f8 02             	cmp    $0x2,%eax
  105b09:	74 24                	je     105b2f <pmap_check+0x137e>
  105b0b:	c7 44 24 0c fa 96 10 	movl   $0x1096fa,0xc(%esp)
  105b12:	00 
  105b13:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105b1a:	00 
  105b1b:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
  105b22:	00 
  105b23:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105b2a:	e8 52 a9 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 0); assert(mem_alloc() == pi2);
  105b2f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105b32:	8b 40 04             	mov    0x4(%eax),%eax
  105b35:	85 c0                	test   %eax,%eax
  105b37:	74 24                	je     105b5d <pmap_check+0x13ac>
  105b39:	c7 44 24 0c a8 92 10 	movl   $0x1092a8,0xc(%esp)
  105b40:	00 
  105b41:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105b48:	00 
  105b49:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
  105b50:	00 
  105b51:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105b58:	e8 24 a9 ff ff       	call   100481 <debug_panic>
  105b5d:	e8 ab af ff ff       	call   100b0d <mem_alloc>
  105b62:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  105b65:	74 24                	je     105b8b <pmap_check+0x13da>
  105b67:	c7 44 24 0c bb 92 10 	movl   $0x1092bb,0xc(%esp)
  105b6e:	00 
  105b6f:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105b76:	00 
  105b77:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
  105b7e:	00 
  105b7f:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105b86:	e8 f6 a8 ff ff       	call   100481 <debug_panic>
	assert(mem_freelist == NULL);
  105b8b:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  105b90:	85 c0                	test   %eax,%eax
  105b92:	74 24                	je     105bb8 <pmap_check+0x1407>
  105b94:	c7 44 24 0c e0 93 10 	movl   $0x1093e0,0xc(%esp)
  105b9b:	00 
  105b9c:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105ba3:	00 
  105ba4:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
  105bab:	00 
  105bac:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105bb3:	e8 c9 a8 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, va, PTSIZE*3-PAGESIZE);
  105bb8:	c7 44 24 08 00 f0 bf 	movl   $0xbff000,0x8(%esp)
  105bbf:	00 
  105bc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105bc3:	89 44 24 04          	mov    %eax,0x4(%esp)
  105bc7:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105bce:	e8 38 e6 ff ff       	call   10420b <pmap_remove>
	assert(pi0->refcount == 1);
  105bd3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105bd6:	8b 40 04             	mov    0x4(%eax),%eax
  105bd9:	83 f8 01             	cmp    $0x1,%eax
  105bdc:	74 24                	je     105c02 <pmap_check+0x1451>
  105bde:	c7 44 24 0c df 8f 10 	movl   $0x108fdf,0xc(%esp)
  105be5:	00 
  105be6:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105bed:	00 
  105bee:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
  105bf5:	00 
  105bf6:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105bfd:	e8 7f a8 ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 0); assert(mem_alloc() == pi1);
  105c02:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105c05:	8b 40 04             	mov    0x4(%eax),%eax
  105c08:	85 c0                	test   %eax,%eax
  105c0a:	74 24                	je     105c30 <pmap_check+0x147f>
  105c0c:	c7 44 24 0c 27 93 10 	movl   $0x109327,0xc(%esp)
  105c13:	00 
  105c14:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105c1b:	00 
  105c1c:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
  105c23:	00 
  105c24:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105c2b:	e8 51 a8 ff ff       	call   100481 <debug_panic>
  105c30:	e8 d8 ae ff ff       	call   100b0d <mem_alloc>
  105c35:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  105c38:	74 24                	je     105c5e <pmap_check+0x14ad>
  105c3a:	c7 44 24 0c 3a 93 10 	movl   $0x10933a,0xc(%esp)
  105c41:	00 
  105c42:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105c49:	00 
  105c4a:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
  105c51:	00 
  105c52:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105c59:	e8 23 a8 ff ff       	call   100481 <debug_panic>
	assert(mem_freelist == NULL);
  105c5e:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  105c63:	85 c0                	test   %eax,%eax
  105c65:	74 24                	je     105c8b <pmap_check+0x14da>
  105c67:	c7 44 24 0c e0 93 10 	movl   $0x1093e0,0xc(%esp)
  105c6e:	00 
  105c6f:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105c76:	00 
  105c77:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
  105c7e:	00 
  105c7f:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105c86:	e8 f6 a7 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PTSIZE*3-PAGESIZE, PAGESIZE);
  105c8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105c8e:	05 00 f0 bf 00       	add    $0xbff000,%eax
  105c93:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105c9a:	00 
  105c9b:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c9f:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105ca6:	e8 60 e5 ff ff       	call   10420b <pmap_remove>
	assert(pi0->refcount == 0);	// pi3 might or might not also be freed
  105cab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105cae:	8b 40 04             	mov    0x4(%eax),%eax
  105cb1:	85 c0                	test   %eax,%eax
  105cb3:	74 24                	je     105cd9 <pmap_check+0x1528>
  105cb5:	c7 44 24 0c ba 93 10 	movl   $0x1093ba,0xc(%esp)
  105cbc:	00 
  105cbd:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105cc4:	00 
  105cc5:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
  105ccc:	00 
  105ccd:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105cd4:	e8 a8 a7 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3);
  105cd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105cdc:	05 00 10 00 00       	add    $0x1000,%eax
  105ce1:	c7 44 24 08 00 00 c0 	movl   $0xc00000,0x8(%esp)
  105ce8:	00 
  105ce9:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ced:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105cf4:	e8 12 e5 ff ff       	call   10420b <pmap_remove>
	assert(pi3->refcount == 0);
  105cf9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105cfc:	8b 40 04             	mov    0x4(%eax),%eax
  105cff:	85 c0                	test   %eax,%eax
  105d01:	74 24                	je     105d27 <pmap_check+0x1576>
  105d03:	c7 44 24 0c 0d 97 10 	movl   $0x10970d,0xc(%esp)
  105d0a:	00 
  105d0b:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105d12:	00 
  105d13:	c7 44 24 04 23 02 00 	movl   $0x223,0x4(%esp)
  105d1a:	00 
  105d1b:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105d22:	e8 5a a7 ff ff       	call   100481 <debug_panic>
	mem_alloc(); mem_alloc();	// collect pi0 and pi3
  105d27:	e8 e1 ad ff ff       	call   100b0d <mem_alloc>
  105d2c:	e8 dc ad ff ff       	call   100b0d <mem_alloc>
	assert(mem_freelist == NULL);
  105d31:	a1 00 dd 11 00       	mov    0x11dd00,%eax
  105d36:	85 c0                	test   %eax,%eax
  105d38:	74 24                	je     105d5e <pmap_check+0x15ad>
  105d3a:	c7 44 24 0c e0 93 10 	movl   $0x1093e0,0xc(%esp)
  105d41:	00 
  105d42:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105d49:	00 
  105d4a:	c7 44 24 04 25 02 00 	movl   $0x225,0x4(%esp)
  105d51:	00 
  105d52:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105d59:	e8 23 a7 ff ff       	call   100481 <debug_panic>

	// check pointer arithmetic in pmap_walk
	mem_free(pi0);
  105d5e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105d61:	89 04 24             	mov    %eax,(%esp)
  105d64:	e8 eb ad ff ff       	call   100b54 <mem_free>
	va = VM_USERLO + PAGESIZE*NPTENTRIES + PAGESIZE;
  105d69:	c7 45 f4 00 10 40 40 	movl   $0x40401000,-0xc(%ebp)
	ptep = pmap_walk(pmap_bootpdir, va, 1);
  105d70:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  105d77:	00 
  105d78:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105d7b:	89 44 24 04          	mov    %eax,0x4(%esp)
  105d7f:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105d86:	e8 33 e4 ff ff       	call   1041be <pmap_walk>
  105d8b:	89 45 e8             	mov    %eax,-0x18(%ebp)
	ptep1 = mem_ptr(PGADDR(pmap_bootpdir[PDX(va)]));
  105d8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105d91:	c1 e8 16             	shr    $0x16,%eax
  105d94:	8b 04 85 00 f0 31 00 	mov    0x31f000(,%eax,4),%eax
  105d9b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105da0:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(ptep == ptep1 + PTX(va));
  105da3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105da6:	c1 e8 0c             	shr    $0xc,%eax
  105da9:	25 ff 03 00 00       	and    $0x3ff,%eax
  105dae:	c1 e0 02             	shl    $0x2,%eax
  105db1:	03 45 ec             	add    -0x14(%ebp),%eax
  105db4:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  105db7:	74 24                	je     105ddd <pmap_check+0x162c>
  105db9:	c7 44 24 0c 20 97 10 	movl   $0x109720,0xc(%esp)
  105dc0:	00 
  105dc1:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105dc8:	00 
  105dc9:	c7 44 24 04 2c 02 00 	movl   $0x22c,0x4(%esp)
  105dd0:	00 
  105dd1:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105dd8:	e8 a4 a6 ff ff       	call   100481 <debug_panic>
	pmap_bootpdir[PDX(va)] = PTE_ZERO;
  105ddd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105de0:	89 c2                	mov    %eax,%edx
  105de2:	c1 ea 16             	shr    $0x16,%edx
  105de5:	b8 00 00 32 00       	mov    $0x320000,%eax
  105dea:	89 04 95 00 f0 31 00 	mov    %eax,0x31f000(,%edx,4)
	pi0->refcount = 0;
  105df1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105df4:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
  105dfb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  105dfe:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  105e03:	89 d1                	mov    %edx,%ecx
  105e05:	29 c1                	sub    %eax,%ecx
  105e07:	89 c8                	mov    %ecx,%eax
  105e09:	c1 f8 03             	sar    $0x3,%eax
  105e0c:	c1 e0 0c             	shl    $0xc,%eax
  105e0f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105e16:	00 
  105e17:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  105e1e:	00 
  105e1f:	89 04 24             	mov    %eax,(%esp)
  105e22:	e8 40 18 00 00       	call   107667 <memset>
	mem_free(pi0);
  105e27:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105e2a:	89 04 24             	mov    %eax,(%esp)
  105e2d:	e8 22 ad ff ff       	call   100b54 <mem_free>
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
  105e32:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  105e39:	00 
  105e3a:	c7 44 24 04 00 f0 ff 	movl   $0xeffff000,0x4(%esp)
  105e41:	ef 
  105e42:	c7 04 24 00 f0 31 00 	movl   $0x31f000,(%esp)
  105e49:	e8 70 e3 ff ff       	call   1041be <pmap_walk>
	ptep = mem_pi2ptr(pi0);
  105e4e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  105e51:	a1 58 dd 31 00       	mov    0x31dd58,%eax
  105e56:	89 d3                	mov    %edx,%ebx
  105e58:	29 c3                	sub    %eax,%ebx
  105e5a:	89 d8                	mov    %ebx,%eax
  105e5c:	c1 f8 03             	sar    $0x3,%eax
  105e5f:	c1 e0 0c             	shl    $0xc,%eax
  105e62:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for(i=0; i<NPTENTRIES; i++)
  105e65:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  105e6c:	eb 3c                	jmp    105eaa <pmap_check+0x16f9>
		assert(ptep[i] == PTE_ZERO);
  105e6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105e71:	c1 e0 02             	shl    $0x2,%eax
  105e74:	03 45 e8             	add    -0x18(%ebp),%eax
  105e77:	8b 10                	mov    (%eax),%edx
  105e79:	b8 00 00 32 00       	mov    $0x320000,%eax
  105e7e:	39 c2                	cmp    %eax,%edx
  105e80:	74 24                	je     105ea6 <pmap_check+0x16f5>
  105e82:	c7 44 24 0c 38 97 10 	movl   $0x109738,0xc(%esp)
  105e89:	00 
  105e8a:	c7 44 24 08 f2 8b 10 	movl   $0x108bf2,0x8(%esp)
  105e91:	00 
  105e92:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
  105e99:	00 
  105e9a:	c7 04 24 2e 8d 10 00 	movl   $0x108d2e,(%esp)
  105ea1:	e8 db a5 ff ff       	call   100481 <debug_panic>
	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
	mem_free(pi0);
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
	ptep = mem_pi2ptr(pi0);
	for(i=0; i<NPTENTRIES; i++)
  105ea6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  105eaa:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
  105eb1:	7e bb                	jle    105e6e <pmap_check+0x16bd>
		assert(ptep[i] == PTE_ZERO);
	pmap_bootpdir[PDX(VM_USERHI-PAGESIZE)] = PTE_ZERO;
  105eb3:	b8 00 00 32 00       	mov    $0x320000,%eax
  105eb8:	a3 fc fe 31 00       	mov    %eax,0x31fefc
	pi0->refcount = 0;
  105ebd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105ec0:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// give free list back
	mem_freelist = fl;
  105ec7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105eca:	a3 00 dd 11 00       	mov    %eax,0x11dd00

	// free the pages we filched
	mem_free(pi0);
  105ecf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105ed2:	89 04 24             	mov    %eax,(%esp)
  105ed5:	e8 7a ac ff ff       	call   100b54 <mem_free>
	mem_free(pi1);
  105eda:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105edd:	89 04 24             	mov    %eax,(%esp)
  105ee0:	e8 6f ac ff ff       	call   100b54 <mem_free>
	mem_free(pi2);
  105ee5:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105ee8:	89 04 24             	mov    %eax,(%esp)
  105eeb:	e8 64 ac ff ff       	call   100b54 <mem_free>
	mem_free(pi3);
  105ef0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105ef3:	89 04 24             	mov    %eax,(%esp)
  105ef6:	e8 59 ac ff ff       	call   100b54 <mem_free>

	cprintf("pmap_check() succeeded!\n");
  105efb:	c7 04 24 4c 97 10 00 	movl   $0x10974c,(%esp)
  105f02:	e8 7b 15 00 00       	call   107482 <cprintf>
}
  105f07:	83 c4 44             	add    $0x44,%esp
  105f0a:	5b                   	pop    %ebx
  105f0b:	5d                   	pop    %ebp
  105f0c:	c3                   	ret    

00105f0d <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  105f0d:	55                   	push   %ebp
  105f0e:	89 e5                	mov    %esp,%ebp
  105f10:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  105f13:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  105f1a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105f1d:	0f b7 00             	movzwl (%eax),%eax
  105f20:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  105f24:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105f27:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  105f2c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105f2f:	0f b7 00             	movzwl (%eax),%eax
  105f32:	66 3d 5a a5          	cmp    $0xa55a,%ax
  105f36:	74 13                	je     105f4b <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  105f38:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  105f3f:	c7 05 98 dc 11 00 b4 	movl   $0x3b4,0x11dc98
  105f46:	03 00 00 
  105f49:	eb 14                	jmp    105f5f <video_init+0x52>
	} else {
		*cp = was;
  105f4b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105f4e:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  105f52:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  105f55:	c7 05 98 dc 11 00 d4 	movl   $0x3d4,0x11dc98
  105f5c:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  105f5f:	a1 98 dc 11 00       	mov    0x11dc98,%eax
  105f64:	89 45 e8             	mov    %eax,-0x18(%ebp)
  105f67:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  105f6b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  105f6f:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105f72:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  105f73:	a1 98 dc 11 00       	mov    0x11dc98,%eax
  105f78:	83 c0 01             	add    $0x1,%eax
  105f7b:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  105f7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105f81:	89 c2                	mov    %eax,%edx
  105f83:	ec                   	in     (%dx),%al
  105f84:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  105f87:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  105f8b:	0f b6 c0             	movzbl %al,%eax
  105f8e:	c1 e0 08             	shl    $0x8,%eax
  105f91:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  105f94:	a1 98 dc 11 00       	mov    0x11dc98,%eax
  105f99:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105f9c:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  105fa0:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  105fa4:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105fa7:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  105fa8:	a1 98 dc 11 00       	mov    0x11dc98,%eax
  105fad:	83 c0 01             	add    $0x1,%eax
  105fb0:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  105fb3:	8b 45 f8             	mov    -0x8(%ebp),%eax
  105fb6:	89 c2                	mov    %eax,%edx
  105fb8:	ec                   	in     (%dx),%al
  105fb9:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  105fbc:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  105fc0:	0f b6 c0             	movzbl %al,%eax
  105fc3:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  105fc6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105fc9:	a3 9c dc 11 00       	mov    %eax,0x11dc9c
	crt_pos = pos;
  105fce:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105fd1:	66 a3 a0 dc 11 00    	mov    %ax,0x11dca0
}
  105fd7:	c9                   	leave  
  105fd8:	c3                   	ret    

00105fd9 <video_putc>:



void
video_putc(int c)
{
  105fd9:	55                   	push   %ebp
  105fda:	89 e5                	mov    %esp,%ebp
  105fdc:	53                   	push   %ebx
  105fdd:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  105fe0:	8b 45 08             	mov    0x8(%ebp),%eax
  105fe3:	b0 00                	mov    $0x0,%al
  105fe5:	85 c0                	test   %eax,%eax
  105fe7:	75 07                	jne    105ff0 <video_putc+0x17>
		c |= 0x0700;
  105fe9:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  105ff0:	8b 45 08             	mov    0x8(%ebp),%eax
  105ff3:	25 ff 00 00 00       	and    $0xff,%eax
  105ff8:	83 f8 09             	cmp    $0x9,%eax
  105ffb:	0f 84 ae 00 00 00    	je     1060af <video_putc+0xd6>
  106001:	83 f8 09             	cmp    $0x9,%eax
  106004:	7f 0a                	jg     106010 <video_putc+0x37>
  106006:	83 f8 08             	cmp    $0x8,%eax
  106009:	74 14                	je     10601f <video_putc+0x46>
  10600b:	e9 dd 00 00 00       	jmp    1060ed <video_putc+0x114>
  106010:	83 f8 0a             	cmp    $0xa,%eax
  106013:	74 4e                	je     106063 <video_putc+0x8a>
  106015:	83 f8 0d             	cmp    $0xd,%eax
  106018:	74 59                	je     106073 <video_putc+0x9a>
  10601a:	e9 ce 00 00 00       	jmp    1060ed <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  10601f:	0f b7 05 a0 dc 11 00 	movzwl 0x11dca0,%eax
  106026:	66 85 c0             	test   %ax,%ax
  106029:	0f 84 e4 00 00 00    	je     106113 <video_putc+0x13a>
			crt_pos--;
  10602f:	0f b7 05 a0 dc 11 00 	movzwl 0x11dca0,%eax
  106036:	83 e8 01             	sub    $0x1,%eax
  106039:	66 a3 a0 dc 11 00    	mov    %ax,0x11dca0
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  10603f:	a1 9c dc 11 00       	mov    0x11dc9c,%eax
  106044:	0f b7 15 a0 dc 11 00 	movzwl 0x11dca0,%edx
  10604b:	0f b7 d2             	movzwl %dx,%edx
  10604e:	01 d2                	add    %edx,%edx
  106050:	8d 14 10             	lea    (%eax,%edx,1),%edx
  106053:	8b 45 08             	mov    0x8(%ebp),%eax
  106056:	b0 00                	mov    $0x0,%al
  106058:	83 c8 20             	or     $0x20,%eax
  10605b:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  10605e:	e9 b1 00 00 00       	jmp    106114 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  106063:	0f b7 05 a0 dc 11 00 	movzwl 0x11dca0,%eax
  10606a:	83 c0 50             	add    $0x50,%eax
  10606d:	66 a3 a0 dc 11 00    	mov    %ax,0x11dca0
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  106073:	0f b7 1d a0 dc 11 00 	movzwl 0x11dca0,%ebx
  10607a:	0f b7 0d a0 dc 11 00 	movzwl 0x11dca0,%ecx
  106081:	0f b7 c1             	movzwl %cx,%eax
  106084:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  10608a:	c1 e8 10             	shr    $0x10,%eax
  10608d:	89 c2                	mov    %eax,%edx
  10608f:	66 c1 ea 06          	shr    $0x6,%dx
  106093:	89 d0                	mov    %edx,%eax
  106095:	c1 e0 02             	shl    $0x2,%eax
  106098:	01 d0                	add    %edx,%eax
  10609a:	c1 e0 04             	shl    $0x4,%eax
  10609d:	89 ca                	mov    %ecx,%edx
  10609f:	66 29 c2             	sub    %ax,%dx
  1060a2:	89 d8                	mov    %ebx,%eax
  1060a4:	66 29 d0             	sub    %dx,%ax
  1060a7:	66 a3 a0 dc 11 00    	mov    %ax,0x11dca0
		break;
  1060ad:	eb 65                	jmp    106114 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  1060af:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1060b6:	e8 1e ff ff ff       	call   105fd9 <video_putc>
		video_putc(' ');
  1060bb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1060c2:	e8 12 ff ff ff       	call   105fd9 <video_putc>
		video_putc(' ');
  1060c7:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1060ce:	e8 06 ff ff ff       	call   105fd9 <video_putc>
		video_putc(' ');
  1060d3:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1060da:	e8 fa fe ff ff       	call   105fd9 <video_putc>
		video_putc(' ');
  1060df:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1060e6:	e8 ee fe ff ff       	call   105fd9 <video_putc>
		break;
  1060eb:	eb 27                	jmp    106114 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  1060ed:	8b 15 9c dc 11 00    	mov    0x11dc9c,%edx
  1060f3:	0f b7 05 a0 dc 11 00 	movzwl 0x11dca0,%eax
  1060fa:	0f b7 c8             	movzwl %ax,%ecx
  1060fd:	01 c9                	add    %ecx,%ecx
  1060ff:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  106102:	8b 55 08             	mov    0x8(%ebp),%edx
  106105:	66 89 11             	mov    %dx,(%ecx)
  106108:	83 c0 01             	add    $0x1,%eax
  10610b:	66 a3 a0 dc 11 00    	mov    %ax,0x11dca0
  106111:	eb 01                	jmp    106114 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  106113:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  106114:	0f b7 05 a0 dc 11 00 	movzwl 0x11dca0,%eax
  10611b:	66 3d cf 07          	cmp    $0x7cf,%ax
  10611f:	76 5b                	jbe    10617c <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  106121:	a1 9c dc 11 00       	mov    0x11dc9c,%eax
  106126:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  10612c:	a1 9c dc 11 00       	mov    0x11dc9c,%eax
  106131:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  106138:	00 
  106139:	89 54 24 04          	mov    %edx,0x4(%esp)
  10613d:	89 04 24             	mov    %eax,(%esp)
  106140:	e8 96 15 00 00       	call   1076db <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  106145:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  10614c:	eb 15                	jmp    106163 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  10614e:	a1 9c dc 11 00       	mov    0x11dc9c,%eax
  106153:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106156:	01 d2                	add    %edx,%edx
  106158:	01 d0                	add    %edx,%eax
  10615a:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  10615f:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  106163:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  10616a:	7e e2                	jle    10614e <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  10616c:	0f b7 05 a0 dc 11 00 	movzwl 0x11dca0,%eax
  106173:	83 e8 50             	sub    $0x50,%eax
  106176:	66 a3 a0 dc 11 00    	mov    %ax,0x11dca0
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  10617c:	a1 98 dc 11 00       	mov    0x11dc98,%eax
  106181:	89 45 dc             	mov    %eax,-0x24(%ebp)
  106184:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106188:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  10618c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10618f:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  106190:	0f b7 05 a0 dc 11 00 	movzwl 0x11dca0,%eax
  106197:	66 c1 e8 08          	shr    $0x8,%ax
  10619b:	0f b6 c0             	movzbl %al,%eax
  10619e:	8b 15 98 dc 11 00    	mov    0x11dc98,%edx
  1061a4:	83 c2 01             	add    $0x1,%edx
  1061a7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1061aa:	88 45 e3             	mov    %al,-0x1d(%ebp)
  1061ad:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1061b1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1061b4:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  1061b5:	a1 98 dc 11 00       	mov    0x11dc98,%eax
  1061ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1061bd:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  1061c1:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1061c5:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1061c8:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  1061c9:	0f b7 05 a0 dc 11 00 	movzwl 0x11dca0,%eax
  1061d0:	0f b6 c0             	movzbl %al,%eax
  1061d3:	8b 15 98 dc 11 00    	mov    0x11dc98,%edx
  1061d9:	83 c2 01             	add    $0x1,%edx
  1061dc:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1061df:	88 45 f3             	mov    %al,-0xd(%ebp)
  1061e2:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1061e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1061e9:	ee                   	out    %al,(%dx)
}
  1061ea:	83 c4 44             	add    $0x44,%esp
  1061ed:	5b                   	pop    %ebx
  1061ee:	5d                   	pop    %ebp
  1061ef:	c3                   	ret    

001061f0 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  1061f0:	55                   	push   %ebp
  1061f1:	89 e5                	mov    %esp,%ebp
  1061f3:	83 ec 38             	sub    $0x38,%esp
  1061f6:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1061fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106200:	89 c2                	mov    %eax,%edx
  106202:	ec                   	in     (%dx),%al
  106203:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  106206:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  10620a:	0f b6 c0             	movzbl %al,%eax
  10620d:	83 e0 01             	and    $0x1,%eax
  106210:	85 c0                	test   %eax,%eax
  106212:	75 0a                	jne    10621e <kbd_proc_data+0x2e>
		return -1;
  106214:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  106219:	e9 5a 01 00 00       	jmp    106378 <kbd_proc_data+0x188>
  10621e:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106225:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106228:	89 c2                	mov    %eax,%edx
  10622a:	ec                   	in     (%dx),%al
  10622b:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10622e:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  106232:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  106235:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  106239:	75 17                	jne    106252 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  10623b:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  106240:	83 c8 40             	or     $0x40,%eax
  106243:	a3 a4 dc 11 00       	mov    %eax,0x11dca4
		return 0;
  106248:	b8 00 00 00 00       	mov    $0x0,%eax
  10624d:	e9 26 01 00 00       	jmp    106378 <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  106252:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106256:	84 c0                	test   %al,%al
  106258:	79 47                	jns    1062a1 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  10625a:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  10625f:	83 e0 40             	and    $0x40,%eax
  106262:	85 c0                	test   %eax,%eax
  106264:	75 09                	jne    10626f <kbd_proc_data+0x7f>
  106266:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10626a:	83 e0 7f             	and    $0x7f,%eax
  10626d:	eb 04                	jmp    106273 <kbd_proc_data+0x83>
  10626f:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106273:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  106276:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10627a:	0f b6 80 20 b1 10 00 	movzbl 0x10b120(%eax),%eax
  106281:	83 c8 40             	or     $0x40,%eax
  106284:	0f b6 c0             	movzbl %al,%eax
  106287:	f7 d0                	not    %eax
  106289:	89 c2                	mov    %eax,%edx
  10628b:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  106290:	21 d0                	and    %edx,%eax
  106292:	a3 a4 dc 11 00       	mov    %eax,0x11dca4
		return 0;
  106297:	b8 00 00 00 00       	mov    $0x0,%eax
  10629c:	e9 d7 00 00 00       	jmp    106378 <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  1062a1:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  1062a6:	83 e0 40             	and    $0x40,%eax
  1062a9:	85 c0                	test   %eax,%eax
  1062ab:	74 11                	je     1062be <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  1062ad:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  1062b1:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  1062b6:	83 e0 bf             	and    $0xffffffbf,%eax
  1062b9:	a3 a4 dc 11 00       	mov    %eax,0x11dca4
	}

	shift |= shiftcode[data];
  1062be:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1062c2:	0f b6 80 20 b1 10 00 	movzbl 0x10b120(%eax),%eax
  1062c9:	0f b6 d0             	movzbl %al,%edx
  1062cc:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  1062d1:	09 d0                	or     %edx,%eax
  1062d3:	a3 a4 dc 11 00       	mov    %eax,0x11dca4
	shift ^= togglecode[data];
  1062d8:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1062dc:	0f b6 80 20 b2 10 00 	movzbl 0x10b220(%eax),%eax
  1062e3:	0f b6 d0             	movzbl %al,%edx
  1062e6:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  1062eb:	31 d0                	xor    %edx,%eax
  1062ed:	a3 a4 dc 11 00       	mov    %eax,0x11dca4

	c = charcode[shift & (CTL | SHIFT)][data];
  1062f2:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  1062f7:	83 e0 03             	and    $0x3,%eax
  1062fa:	8b 14 85 20 b6 10 00 	mov    0x10b620(,%eax,4),%edx
  106301:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106305:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106308:	0f b6 00             	movzbl (%eax),%eax
  10630b:	0f b6 c0             	movzbl %al,%eax
  10630e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  106311:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  106316:	83 e0 08             	and    $0x8,%eax
  106319:	85 c0                	test   %eax,%eax
  10631b:	74 22                	je     10633f <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  10631d:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  106321:	7e 0c                	jle    10632f <kbd_proc_data+0x13f>
  106323:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  106327:	7f 06                	jg     10632f <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  106329:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  10632d:	eb 10                	jmp    10633f <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  10632f:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  106333:	7e 0a                	jle    10633f <kbd_proc_data+0x14f>
  106335:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  106339:	7f 04                	jg     10633f <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  10633b:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  10633f:	a1 a4 dc 11 00       	mov    0x11dca4,%eax
  106344:	f7 d0                	not    %eax
  106346:	83 e0 06             	and    $0x6,%eax
  106349:	85 c0                	test   %eax,%eax
  10634b:	75 28                	jne    106375 <kbd_proc_data+0x185>
  10634d:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  106354:	75 1f                	jne    106375 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  106356:	c7 04 24 65 97 10 00 	movl   $0x109765,(%esp)
  10635d:	e8 20 11 00 00       	call   107482 <cprintf>
  106362:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  106369:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10636d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106371:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106374:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  106375:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  106378:	c9                   	leave  
  106379:	c3                   	ret    

0010637a <kbd_intr>:

void
kbd_intr(void)
{
  10637a:	55                   	push   %ebp
  10637b:	89 e5                	mov    %esp,%ebp
  10637d:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  106380:	c7 04 24 f0 61 10 00 	movl   $0x1061f0,(%esp)
  106387:	e8 2a 9f ff ff       	call   1002b6 <cons_intr>
}
  10638c:	c9                   	leave  
  10638d:	c3                   	ret    

0010638e <kbd_init>:

void
kbd_init(void)
{
  10638e:	55                   	push   %ebp
  10638f:	89 e5                	mov    %esp,%ebp
}
  106391:	5d                   	pop    %ebp
  106392:	c3                   	ret    

00106393 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  106393:	55                   	push   %ebp
  106394:	89 e5                	mov    %esp,%ebp
  106396:	83 ec 20             	sub    $0x20,%esp
  106399:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1063a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1063a3:	89 c2                	mov    %eax,%edx
  1063a5:	ec                   	in     (%dx),%al
  1063a6:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  1063a9:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1063b0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1063b3:	89 c2                	mov    %eax,%edx
  1063b5:	ec                   	in     (%dx),%al
  1063b6:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  1063b9:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1063c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1063c3:	89 c2                	mov    %eax,%edx
  1063c5:	ec                   	in     (%dx),%al
  1063c6:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  1063c9:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1063d0:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1063d3:	89 c2                	mov    %eax,%edx
  1063d5:	ec                   	in     (%dx),%al
  1063d6:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  1063d9:	c9                   	leave  
  1063da:	c3                   	ret    

001063db <serial_proc_data>:

static int
serial_proc_data(void)
{
  1063db:	55                   	push   %ebp
  1063dc:	89 e5                	mov    %esp,%ebp
  1063de:	83 ec 10             	sub    $0x10,%esp
  1063e1:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  1063e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1063eb:	89 c2                	mov    %eax,%edx
  1063ed:	ec                   	in     (%dx),%al
  1063ee:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  1063f1:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  1063f5:	0f b6 c0             	movzbl %al,%eax
  1063f8:	83 e0 01             	and    $0x1,%eax
  1063fb:	85 c0                	test   %eax,%eax
  1063fd:	75 07                	jne    106406 <serial_proc_data+0x2b>
		return -1;
  1063ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  106404:	eb 17                	jmp    10641d <serial_proc_data+0x42>
  106406:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10640d:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106410:	89 c2                	mov    %eax,%edx
  106412:	ec                   	in     (%dx),%al
  106413:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  106416:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  10641a:	0f b6 c0             	movzbl %al,%eax
}
  10641d:	c9                   	leave  
  10641e:	c3                   	ret    

0010641f <serial_intr>:

void
serial_intr(void)
{
  10641f:	55                   	push   %ebp
  106420:	89 e5                	mov    %esp,%ebp
  106422:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  106425:	a1 00 10 32 00       	mov    0x321000,%eax
  10642a:	85 c0                	test   %eax,%eax
  10642c:	74 0c                	je     10643a <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  10642e:	c7 04 24 db 63 10 00 	movl   $0x1063db,(%esp)
  106435:	e8 7c 9e ff ff       	call   1002b6 <cons_intr>
}
  10643a:	c9                   	leave  
  10643b:	c3                   	ret    

0010643c <serial_putc>:

void
serial_putc(int c)
{
  10643c:	55                   	push   %ebp
  10643d:	89 e5                	mov    %esp,%ebp
  10643f:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  106442:	a1 00 10 32 00       	mov    0x321000,%eax
  106447:	85 c0                	test   %eax,%eax
  106449:	74 53                	je     10649e <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  10644b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  106452:	eb 09                	jmp    10645d <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  106454:	e8 3a ff ff ff       	call   106393 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  106459:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10645d:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106464:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106467:	89 c2                	mov    %eax,%edx
  106469:	ec                   	in     (%dx),%al
  10646a:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  10646d:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  106471:	0f b6 c0             	movzbl %al,%eax
  106474:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  106477:	85 c0                	test   %eax,%eax
  106479:	75 09                	jne    106484 <serial_putc+0x48>
  10647b:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  106482:	7e d0                	jle    106454 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  106484:	8b 45 08             	mov    0x8(%ebp),%eax
  106487:	0f b6 c0             	movzbl %al,%eax
  10648a:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  106491:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106494:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106498:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10649b:	ee                   	out    %al,(%dx)
  10649c:	eb 01                	jmp    10649f <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  10649e:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  10649f:	c9                   	leave  
  1064a0:	c3                   	ret    

001064a1 <serial_init>:

void
serial_init(void)
{
  1064a1:	55                   	push   %ebp
  1064a2:	89 e5                	mov    %esp,%ebp
  1064a4:	83 ec 50             	sub    $0x50,%esp
  1064a7:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  1064ae:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  1064b2:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  1064b6:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  1064b9:	ee                   	out    %al,(%dx)
  1064ba:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  1064c1:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  1064c5:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  1064c9:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1064cc:	ee                   	out    %al,(%dx)
  1064cd:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  1064d4:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  1064d8:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  1064dc:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  1064df:	ee                   	out    %al,(%dx)
  1064e0:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  1064e7:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  1064eb:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  1064ef:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1064f2:	ee                   	out    %al,(%dx)
  1064f3:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  1064fa:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  1064fe:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  106502:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106505:	ee                   	out    %al,(%dx)
  106506:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  10650d:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  106511:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  106515:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106518:	ee                   	out    %al,(%dx)
  106519:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  106520:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  106524:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106528:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10652b:	ee                   	out    %al,(%dx)
  10652c:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106533:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106536:	89 c2                	mov    %eax,%edx
  106538:	ec                   	in     (%dx),%al
  106539:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  10653c:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  106540:	3c ff                	cmp    $0xff,%al
  106542:	0f 95 c0             	setne  %al
  106545:	0f b6 c0             	movzbl %al,%eax
  106548:	a3 00 10 32 00       	mov    %eax,0x321000
  10654d:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106554:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106557:	89 c2                	mov    %eax,%edx
  106559:	ec                   	in     (%dx),%al
  10655a:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  10655d:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106564:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106567:	89 c2                	mov    %eax,%edx
  106569:	ec                   	in     (%dx),%al
  10656a:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  10656d:	c9                   	leave  
  10656e:	c3                   	ret    

0010656f <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  10656f:	55                   	push   %ebp
  106570:	89 e5                	mov    %esp,%ebp
  106572:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  106578:	a1 a8 dc 11 00       	mov    0x11dca8,%eax
  10657d:	85 c0                	test   %eax,%eax
  10657f:	0f 85 35 01 00 00    	jne    1066ba <pic_init+0x14b>
		return;
	didinit = 1;
  106585:	c7 05 a8 dc 11 00 01 	movl   $0x1,0x11dca8
  10658c:	00 00 00 
  10658f:	c7 45 8c 21 00 00 00 	movl   $0x21,-0x74(%ebp)
  106596:	c6 45 8b ff          	movb   $0xff,-0x75(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10659a:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  10659e:	8b 55 8c             	mov    -0x74(%ebp),%edx
  1065a1:	ee                   	out    %al,(%dx)
  1065a2:	c7 45 94 a1 00 00 00 	movl   $0xa1,-0x6c(%ebp)
  1065a9:	c6 45 93 ff          	movb   $0xff,-0x6d(%ebp)
  1065ad:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  1065b1:	8b 55 94             	mov    -0x6c(%ebp),%edx
  1065b4:	ee                   	out    %al,(%dx)
  1065b5:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  1065bc:	c6 45 9b 11          	movb   $0x11,-0x65(%ebp)
  1065c0:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  1065c4:	8b 55 9c             	mov    -0x64(%ebp),%edx
  1065c7:	ee                   	out    %al,(%dx)
  1065c8:	c7 45 a4 21 00 00 00 	movl   $0x21,-0x5c(%ebp)
  1065cf:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
  1065d3:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  1065d7:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  1065da:	ee                   	out    %al,(%dx)
  1065db:	c7 45 ac 21 00 00 00 	movl   $0x21,-0x54(%ebp)
  1065e2:	c6 45 ab 04          	movb   $0x4,-0x55(%ebp)
  1065e6:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  1065ea:	8b 55 ac             	mov    -0x54(%ebp),%edx
  1065ed:	ee                   	out    %al,(%dx)
  1065ee:	c7 45 b4 21 00 00 00 	movl   $0x21,-0x4c(%ebp)
  1065f5:	c6 45 b3 03          	movb   $0x3,-0x4d(%ebp)
  1065f9:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  1065fd:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  106600:	ee                   	out    %al,(%dx)
  106601:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
  106608:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
  10660c:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  106610:	8b 55 bc             	mov    -0x44(%ebp),%edx
  106613:	ee                   	out    %al,(%dx)
  106614:	c7 45 c4 a1 00 00 00 	movl   $0xa1,-0x3c(%ebp)
  10661b:	c6 45 c3 28          	movb   $0x28,-0x3d(%ebp)
  10661f:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  106623:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  106626:	ee                   	out    %al,(%dx)
  106627:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
  10662e:	c6 45 cb 02          	movb   $0x2,-0x35(%ebp)
  106632:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  106636:	8b 55 cc             	mov    -0x34(%ebp),%edx
  106639:	ee                   	out    %al,(%dx)
  10663a:	c7 45 d4 a1 00 00 00 	movl   $0xa1,-0x2c(%ebp)
  106641:	c6 45 d3 01          	movb   $0x1,-0x2d(%ebp)
  106645:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  106649:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10664c:	ee                   	out    %al,(%dx)
  10664d:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
  106654:	c6 45 db 68          	movb   $0x68,-0x25(%ebp)
  106658:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  10665c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10665f:	ee                   	out    %al,(%dx)
  106660:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  106667:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  10666b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10666f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  106672:	ee                   	out    %al,(%dx)
  106673:	c7 45 ec a0 00 00 00 	movl   $0xa0,-0x14(%ebp)
  10667a:	c6 45 eb 68          	movb   $0x68,-0x15(%ebp)
  10667e:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  106682:	8b 55 ec             	mov    -0x14(%ebp),%edx
  106685:	ee                   	out    %al,(%dx)
  106686:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
  10668d:	c6 45 f3 0a          	movb   $0xa,-0xd(%ebp)
  106691:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106695:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106698:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  106699:	0f b7 05 30 b6 10 00 	movzwl 0x10b630,%eax
  1066a0:	66 83 f8 ff          	cmp    $0xffff,%ax
  1066a4:	74 15                	je     1066bb <pic_init+0x14c>
		pic_setmask(irqmask);
  1066a6:	0f b7 05 30 b6 10 00 	movzwl 0x10b630,%eax
  1066ad:	0f b7 c0             	movzwl %ax,%eax
  1066b0:	89 04 24             	mov    %eax,(%esp)
  1066b3:	e8 05 00 00 00       	call   1066bd <pic_setmask>
  1066b8:	eb 01                	jmp    1066bb <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  1066ba:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  1066bb:	c9                   	leave  
  1066bc:	c3                   	ret    

001066bd <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  1066bd:	55                   	push   %ebp
  1066be:	89 e5                	mov    %esp,%ebp
  1066c0:	83 ec 14             	sub    $0x14,%esp
  1066c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1066c6:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  1066ca:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1066ce:	66 a3 30 b6 10 00    	mov    %ax,0x10b630
	outb(IO_PIC1+1, (char)mask);
  1066d4:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1066d8:	0f b6 c0             	movzbl %al,%eax
  1066db:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  1066e2:	88 45 f3             	mov    %al,-0xd(%ebp)
  1066e5:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1066e9:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1066ec:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  1066ed:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1066f1:	66 c1 e8 08          	shr    $0x8,%ax
  1066f5:	0f b6 c0             	movzbl %al,%eax
  1066f8:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
  1066ff:	88 45 fb             	mov    %al,-0x5(%ebp)
  106702:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106706:	8b 55 fc             	mov    -0x4(%ebp),%edx
  106709:	ee                   	out    %al,(%dx)
}
  10670a:	c9                   	leave  
  10670b:	c3                   	ret    

0010670c <pic_enable>:

void
pic_enable(int irq)
{
  10670c:	55                   	push   %ebp
  10670d:	89 e5                	mov    %esp,%ebp
  10670f:	53                   	push   %ebx
  106710:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  106713:	8b 45 08             	mov    0x8(%ebp),%eax
  106716:	ba 01 00 00 00       	mov    $0x1,%edx
  10671b:	89 d3                	mov    %edx,%ebx
  10671d:	89 c1                	mov    %eax,%ecx
  10671f:	d3 e3                	shl    %cl,%ebx
  106721:	89 d8                	mov    %ebx,%eax
  106723:	89 c2                	mov    %eax,%edx
  106725:	f7 d2                	not    %edx
  106727:	0f b7 05 30 b6 10 00 	movzwl 0x10b630,%eax
  10672e:	21 d0                	and    %edx,%eax
  106730:	0f b7 c0             	movzwl %ax,%eax
  106733:	89 04 24             	mov    %eax,(%esp)
  106736:	e8 82 ff ff ff       	call   1066bd <pic_setmask>
}
  10673b:	83 c4 04             	add    $0x4,%esp
  10673e:	5b                   	pop    %ebx
  10673f:	5d                   	pop    %ebp
  106740:	c3                   	ret    

00106741 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  106741:	55                   	push   %ebp
  106742:	89 e5                	mov    %esp,%ebp
  106744:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  106747:	8b 45 08             	mov    0x8(%ebp),%eax
  10674a:	0f b6 c0             	movzbl %al,%eax
  10674d:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  106754:	88 45 f3             	mov    %al,-0xd(%ebp)
  106757:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10675b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10675e:	ee                   	out    %al,(%dx)
  10675f:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106766:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106769:	89 c2                	mov    %eax,%edx
  10676b:	ec                   	in     (%dx),%al
  10676c:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  10676f:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  106773:	0f b6 c0             	movzbl %al,%eax
}
  106776:	c9                   	leave  
  106777:	c3                   	ret    

00106778 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  106778:	55                   	push   %ebp
  106779:	89 e5                	mov    %esp,%ebp
  10677b:	53                   	push   %ebx
  10677c:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  10677f:	8b 45 08             	mov    0x8(%ebp),%eax
  106782:	89 04 24             	mov    %eax,(%esp)
  106785:	e8 b7 ff ff ff       	call   106741 <nvram_read>
  10678a:	89 c3                	mov    %eax,%ebx
  10678c:	8b 45 08             	mov    0x8(%ebp),%eax
  10678f:	83 c0 01             	add    $0x1,%eax
  106792:	89 04 24             	mov    %eax,(%esp)
  106795:	e8 a7 ff ff ff       	call   106741 <nvram_read>
  10679a:	c1 e0 08             	shl    $0x8,%eax
  10679d:	09 d8                	or     %ebx,%eax
}
  10679f:	83 c4 04             	add    $0x4,%esp
  1067a2:	5b                   	pop    %ebx
  1067a3:	5d                   	pop    %ebp
  1067a4:	c3                   	ret    

001067a5 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  1067a5:	55                   	push   %ebp
  1067a6:	89 e5                	mov    %esp,%ebp
  1067a8:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  1067ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1067ae:	0f b6 c0             	movzbl %al,%eax
  1067b1:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1067b8:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1067bb:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1067bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1067c2:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  1067c3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1067c6:	0f b6 c0             	movzbl %al,%eax
  1067c9:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  1067d0:	88 45 fb             	mov    %al,-0x5(%ebp)
  1067d3:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1067d7:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1067da:	ee                   	out    %al,(%dx)
}
  1067db:	c9                   	leave  
  1067dc:	c3                   	ret    

001067dd <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1067dd:	55                   	push   %ebp
  1067de:	89 e5                	mov    %esp,%ebp
  1067e0:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1067e3:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1067e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1067e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1067ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1067ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1067f4:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1067f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1067fa:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  106800:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  106805:	74 24                	je     10682b <cpu_cur+0x4e>
  106807:	c7 44 24 0c 71 97 10 	movl   $0x109771,0xc(%esp)
  10680e:	00 
  10680f:	c7 44 24 08 87 97 10 	movl   $0x109787,0x8(%esp)
  106816:	00 
  106817:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10681e:	00 
  10681f:	c7 04 24 9c 97 10 00 	movl   $0x10979c,(%esp)
  106826:	e8 56 9c ff ff       	call   100481 <debug_panic>
	return c;
  10682b:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10682e:	c9                   	leave  
  10682f:	c3                   	ret    

00106830 <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  106830:	55                   	push   %ebp
  106831:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  106833:	a1 04 10 32 00       	mov    0x321004,%eax
  106838:	8b 55 08             	mov    0x8(%ebp),%edx
  10683b:	c1 e2 02             	shl    $0x2,%edx
  10683e:	8d 14 10             	lea    (%eax,%edx,1),%edx
  106841:	8b 45 0c             	mov    0xc(%ebp),%eax
  106844:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  106846:	a1 04 10 32 00       	mov    0x321004,%eax
  10684b:	83 c0 20             	add    $0x20,%eax
  10684e:	8b 00                	mov    (%eax),%eax
}
  106850:	5d                   	pop    %ebp
  106851:	c3                   	ret    

00106852 <lapic_init>:

void
lapic_init()
{
  106852:	55                   	push   %ebp
  106853:	89 e5                	mov    %esp,%ebp
  106855:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  106858:	a1 04 10 32 00       	mov    0x321004,%eax
  10685d:	85 c0                	test   %eax,%eax
  10685f:	0f 84 82 01 00 00    	je     1069e7 <lapic_init+0x195>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  106865:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  10686c:	00 
  10686d:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  106874:	e8 b7 ff ff ff       	call   106830 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  106879:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  106880:	00 
  106881:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  106888:	e8 a3 ff ff ff       	call   106830 <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  10688d:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  106894:	00 
  106895:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10689c:	e8 8f ff ff ff       	call   106830 <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  1068a1:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  1068a8:	00 
  1068a9:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  1068b0:	e8 7b ff ff ff       	call   106830 <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  1068b5:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1068bc:	00 
  1068bd:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  1068c4:	e8 67 ff ff ff       	call   106830 <lapicw>
	lapicw(LINT1, MASKED);
  1068c9:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1068d0:	00 
  1068d1:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  1068d8:	e8 53 ff ff ff       	call   106830 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  1068dd:	a1 04 10 32 00       	mov    0x321004,%eax
  1068e2:	83 c0 30             	add    $0x30,%eax
  1068e5:	8b 00                	mov    (%eax),%eax
  1068e7:	c1 e8 10             	shr    $0x10,%eax
  1068ea:	25 ff 00 00 00       	and    $0xff,%eax
  1068ef:	83 f8 03             	cmp    $0x3,%eax
  1068f2:	76 14                	jbe    106908 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  1068f4:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1068fb:	00 
  1068fc:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  106903:	e8 28 ff ff ff       	call   106830 <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  106908:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  10690f:	00 
  106910:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  106917:	e8 14 ff ff ff       	call   106830 <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  10691c:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  106923:	ff 
  106924:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  10692b:	e8 00 ff ff ff       	call   106830 <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  106930:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  106937:	f0 
  106938:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  10693f:	e8 ec fe ff ff       	call   106830 <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  106944:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10694b:	00 
  10694c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  106953:	e8 d8 fe ff ff       	call   106830 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  106958:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10695f:	00 
  106960:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  106967:	e8 c4 fe ff ff       	call   106830 <lapicw>
	lapicw(ESR, 0);
  10696c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  106973:	00 
  106974:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10697b:	e8 b0 fe ff ff       	call   106830 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  106980:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  106987:	00 
  106988:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10698f:	e8 9c fe ff ff       	call   106830 <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  106994:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10699b:	00 
  10699c:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1069a3:	e8 88 fe ff ff       	call   106830 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  1069a8:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  1069af:	00 
  1069b0:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1069b7:	e8 74 fe ff ff       	call   106830 <lapicw>
	while(lapic[ICRLO] & DELIVS)
  1069bc:	a1 04 10 32 00       	mov    0x321004,%eax
  1069c1:	05 00 03 00 00       	add    $0x300,%eax
  1069c6:	8b 00                	mov    (%eax),%eax
  1069c8:	25 00 10 00 00       	and    $0x1000,%eax
  1069cd:	85 c0                	test   %eax,%eax
  1069cf:	75 eb                	jne    1069bc <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  1069d1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1069d8:	00 
  1069d9:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1069e0:	e8 4b fe ff ff       	call   106830 <lapicw>
  1069e5:	eb 01                	jmp    1069e8 <lapic_init+0x196>

void
lapic_init()
{
	if (!lapic) 
		return;
  1069e7:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  1069e8:	c9                   	leave  
  1069e9:	c3                   	ret    

001069ea <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  1069ea:	55                   	push   %ebp
  1069eb:	89 e5                	mov    %esp,%ebp
  1069ed:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  1069f0:	a1 04 10 32 00       	mov    0x321004,%eax
  1069f5:	85 c0                	test   %eax,%eax
  1069f7:	74 14                	je     106a0d <lapic_eoi+0x23>
		lapicw(EOI, 0);
  1069f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  106a00:	00 
  106a01:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  106a08:	e8 23 fe ff ff       	call   106830 <lapicw>
}
  106a0d:	c9                   	leave  
  106a0e:	c3                   	ret    

00106a0f <lapic_errintr>:

void lapic_errintr(void)
{
  106a0f:	55                   	push   %ebp
  106a10:	89 e5                	mov    %esp,%ebp
  106a12:	53                   	push   %ebx
  106a13:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  106a16:	e8 cf ff ff ff       	call   1069ea <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  106a1b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  106a22:	00 
  106a23:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  106a2a:	e8 01 fe ff ff       	call   106830 <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  106a2f:	a1 04 10 32 00       	mov    0x321004,%eax
  106a34:	05 80 02 00 00       	add    $0x280,%eax
  106a39:	8b 18                	mov    (%eax),%ebx
  106a3b:	e8 9d fd ff ff       	call   1067dd <cpu_cur>
  106a40:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  106a47:	0f b6 c0             	movzbl %al,%eax
  106a4a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  106a4e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  106a52:	c7 44 24 08 a9 97 10 	movl   $0x1097a9,0x8(%esp)
  106a59:	00 
  106a5a:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  106a61:	00 
  106a62:	c7 04 24 c3 97 10 00 	movl   $0x1097c3,(%esp)
  106a69:	e8 d2 9a ff ff       	call   100540 <debug_warn>
}
  106a6e:	83 c4 24             	add    $0x24,%esp
  106a71:	5b                   	pop    %ebx
  106a72:	5d                   	pop    %ebp
  106a73:	c3                   	ret    

00106a74 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  106a74:	55                   	push   %ebp
  106a75:	89 e5                	mov    %esp,%ebp
}
  106a77:	5d                   	pop    %ebp
  106a78:	c3                   	ret    

00106a79 <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  106a79:	55                   	push   %ebp
  106a7a:	89 e5                	mov    %esp,%ebp
  106a7c:	83 ec 2c             	sub    $0x2c,%esp
  106a7f:	8b 45 08             	mov    0x8(%ebp),%eax
  106a82:	88 45 dc             	mov    %al,-0x24(%ebp)
  106a85:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  106a8c:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106a90:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106a94:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106a97:	ee                   	out    %al,(%dx)
  106a98:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  106a9f:	c6 45 fb 0a          	movb   $0xa,-0x5(%ebp)
  106aa3:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106aa7:	8b 55 fc             	mov    -0x4(%ebp),%edx
  106aaa:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  106aab:	c7 45 ec 67 04 00 00 	movl   $0x467,-0x14(%ebp)
	wrv[0] = 0;
  106ab2:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106ab5:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  106aba:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106abd:	8d 50 02             	lea    0x2(%eax),%edx
  106ac0:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ac3:	c1 e8 04             	shr    $0x4,%eax
  106ac6:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  106ac9:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  106acd:	c1 e0 18             	shl    $0x18,%eax
  106ad0:	89 44 24 04          	mov    %eax,0x4(%esp)
  106ad4:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  106adb:	e8 50 fd ff ff       	call   106830 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  106ae0:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  106ae7:	00 
  106ae8:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  106aef:	e8 3c fd ff ff       	call   106830 <lapicw>
	microdelay(200);
  106af4:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  106afb:	e8 74 ff ff ff       	call   106a74 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  106b00:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  106b07:	00 
  106b08:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  106b0f:	e8 1c fd ff ff       	call   106830 <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  106b14:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  106b1b:	e8 54 ff ff ff       	call   106a74 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  106b20:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  106b27:	eb 40                	jmp    106b69 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  106b29:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  106b2d:	c1 e0 18             	shl    $0x18,%eax
  106b30:	89 44 24 04          	mov    %eax,0x4(%esp)
  106b34:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  106b3b:	e8 f0 fc ff ff       	call   106830 <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  106b40:	8b 45 0c             	mov    0xc(%ebp),%eax
  106b43:	c1 e8 0c             	shr    $0xc,%eax
  106b46:	80 cc 06             	or     $0x6,%ah
  106b49:	89 44 24 04          	mov    %eax,0x4(%esp)
  106b4d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  106b54:	e8 d7 fc ff ff       	call   106830 <lapicw>
		microdelay(200);
  106b59:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  106b60:	e8 0f ff ff ff       	call   106a74 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  106b65:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  106b69:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
  106b6d:	7e ba                	jle    106b29 <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  106b6f:	c9                   	leave  
  106b70:	c3                   	ret    

00106b71 <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  106b71:	55                   	push   %ebp
  106b72:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  106b74:	a1 60 dd 31 00       	mov    0x31dd60,%eax
  106b79:	8b 55 08             	mov    0x8(%ebp),%edx
  106b7c:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  106b7e:	a1 60 dd 31 00       	mov    0x31dd60,%eax
  106b83:	8b 40 10             	mov    0x10(%eax),%eax
}
  106b86:	5d                   	pop    %ebp
  106b87:	c3                   	ret    

00106b88 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  106b88:	55                   	push   %ebp
  106b89:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  106b8b:	a1 60 dd 31 00       	mov    0x31dd60,%eax
  106b90:	8b 55 08             	mov    0x8(%ebp),%edx
  106b93:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  106b95:	a1 60 dd 31 00       	mov    0x31dd60,%eax
  106b9a:	8b 55 0c             	mov    0xc(%ebp),%edx
  106b9d:	89 50 10             	mov    %edx,0x10(%eax)
}
  106ba0:	5d                   	pop    %ebp
  106ba1:	c3                   	ret    

00106ba2 <ioapic_init>:

void
ioapic_init(void)
{
  106ba2:	55                   	push   %ebp
  106ba3:	89 e5                	mov    %esp,%ebp
  106ba5:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  106ba8:	a1 64 dd 31 00       	mov    0x31dd64,%eax
  106bad:	85 c0                	test   %eax,%eax
  106baf:	0f 84 fd 00 00 00    	je     106cb2 <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  106bb5:	a1 60 dd 31 00       	mov    0x31dd60,%eax
  106bba:	85 c0                	test   %eax,%eax
  106bbc:	75 0a                	jne    106bc8 <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  106bbe:	c7 05 60 dd 31 00 00 	movl   $0xfec00000,0x31dd60
  106bc5:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  106bc8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  106bcf:	e8 9d ff ff ff       	call   106b71 <ioapic_read>
  106bd4:	c1 e8 10             	shr    $0x10,%eax
  106bd7:	25 ff 00 00 00       	and    $0xff,%eax
  106bdc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  106bdf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  106be6:	e8 86 ff ff ff       	call   106b71 <ioapic_read>
  106beb:	c1 e8 18             	shr    $0x18,%eax
  106bee:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  106bf1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  106bf5:	75 2a                	jne    106c21 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  106bf7:	0f b6 05 5c dd 31 00 	movzbl 0x31dd5c,%eax
  106bfe:	0f b6 c0             	movzbl %al,%eax
  106c01:	c1 e0 18             	shl    $0x18,%eax
  106c04:	89 44 24 04          	mov    %eax,0x4(%esp)
  106c08:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  106c0f:	e8 74 ff ff ff       	call   106b88 <ioapic_write>
		id = ioapicid;
  106c14:	0f b6 05 5c dd 31 00 	movzbl 0x31dd5c,%eax
  106c1b:	0f b6 c0             	movzbl %al,%eax
  106c1e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  106c21:	0f b6 05 5c dd 31 00 	movzbl 0x31dd5c,%eax
  106c28:	0f b6 c0             	movzbl %al,%eax
  106c2b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  106c2e:	74 31                	je     106c61 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  106c30:	0f b6 05 5c dd 31 00 	movzbl 0x31dd5c,%eax
  106c37:	0f b6 c0             	movzbl %al,%eax
  106c3a:	89 44 24 10          	mov    %eax,0x10(%esp)
  106c3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106c41:	89 44 24 0c          	mov    %eax,0xc(%esp)
  106c45:	c7 44 24 08 d0 97 10 	movl   $0x1097d0,0x8(%esp)
  106c4c:	00 
  106c4d:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  106c54:	00 
  106c55:	c7 04 24 f1 97 10 00 	movl   $0x1097f1,(%esp)
  106c5c:	e8 df 98 ff ff       	call   100540 <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  106c61:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  106c68:	eb 3e                	jmp    106ca8 <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  106c6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106c6d:	83 c0 20             	add    $0x20,%eax
  106c70:	0d 00 00 01 00       	or     $0x10000,%eax
  106c75:	8b 55 ec             	mov    -0x14(%ebp),%edx
  106c78:	83 c2 08             	add    $0x8,%edx
  106c7b:	01 d2                	add    %edx,%edx
  106c7d:	89 44 24 04          	mov    %eax,0x4(%esp)
  106c81:	89 14 24             	mov    %edx,(%esp)
  106c84:	e8 ff fe ff ff       	call   106b88 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  106c89:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106c8c:	83 c0 08             	add    $0x8,%eax
  106c8f:	01 c0                	add    %eax,%eax
  106c91:	83 c0 01             	add    $0x1,%eax
  106c94:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  106c9b:	00 
  106c9c:	89 04 24             	mov    %eax,(%esp)
  106c9f:	e8 e4 fe ff ff       	call   106b88 <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  106ca4:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  106ca8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106cab:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  106cae:	7e ba                	jle    106c6a <ioapic_init+0xc8>
  106cb0:	eb 01                	jmp    106cb3 <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  106cb2:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  106cb3:	c9                   	leave  
  106cb4:	c3                   	ret    

00106cb5 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  106cb5:	55                   	push   %ebp
  106cb6:	89 e5                	mov    %esp,%ebp
  106cb8:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  106cbb:	a1 64 dd 31 00       	mov    0x31dd64,%eax
  106cc0:	85 c0                	test   %eax,%eax
  106cc2:	74 3a                	je     106cfe <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  106cc4:	8b 45 08             	mov    0x8(%ebp),%eax
  106cc7:	83 c0 20             	add    $0x20,%eax
  106cca:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  106ccd:	8b 55 08             	mov    0x8(%ebp),%edx
  106cd0:	83 c2 08             	add    $0x8,%edx
  106cd3:	01 d2                	add    %edx,%edx
  106cd5:	89 44 24 04          	mov    %eax,0x4(%esp)
  106cd9:	89 14 24             	mov    %edx,(%esp)
  106cdc:	e8 a7 fe ff ff       	call   106b88 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  106ce1:	8b 45 08             	mov    0x8(%ebp),%eax
  106ce4:	83 c0 08             	add    $0x8,%eax
  106ce7:	01 c0                	add    %eax,%eax
  106ce9:	83 c0 01             	add    $0x1,%eax
  106cec:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  106cf3:	ff 
  106cf4:	89 04 24             	mov    %eax,(%esp)
  106cf7:	e8 8c fe ff ff       	call   106b88 <ioapic_write>
  106cfc:	eb 01                	jmp    106cff <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  106cfe:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  106cff:	c9                   	leave  
  106d00:	c3                   	ret    

00106d01 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  106d01:	55                   	push   %ebp
  106d02:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  106d04:	8b 45 08             	mov    0x8(%ebp),%eax
  106d07:	8b 40 18             	mov    0x18(%eax),%eax
  106d0a:	83 e0 02             	and    $0x2,%eax
  106d0d:	85 c0                	test   %eax,%eax
  106d0f:	74 1c                	je     106d2d <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  106d11:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d14:	8b 00                	mov    (%eax),%eax
  106d16:	8d 50 08             	lea    0x8(%eax),%edx
  106d19:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d1c:	89 10                	mov    %edx,(%eax)
  106d1e:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d21:	8b 00                	mov    (%eax),%eax
  106d23:	83 e8 08             	sub    $0x8,%eax
  106d26:	8b 50 04             	mov    0x4(%eax),%edx
  106d29:	8b 00                	mov    (%eax),%eax
  106d2b:	eb 47                	jmp    106d74 <getuint+0x73>
	else if (st->flags & F_L)
  106d2d:	8b 45 08             	mov    0x8(%ebp),%eax
  106d30:	8b 40 18             	mov    0x18(%eax),%eax
  106d33:	83 e0 01             	and    $0x1,%eax
  106d36:	84 c0                	test   %al,%al
  106d38:	74 1e                	je     106d58 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  106d3a:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d3d:	8b 00                	mov    (%eax),%eax
  106d3f:	8d 50 04             	lea    0x4(%eax),%edx
  106d42:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d45:	89 10                	mov    %edx,(%eax)
  106d47:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d4a:	8b 00                	mov    (%eax),%eax
  106d4c:	83 e8 04             	sub    $0x4,%eax
  106d4f:	8b 00                	mov    (%eax),%eax
  106d51:	ba 00 00 00 00       	mov    $0x0,%edx
  106d56:	eb 1c                	jmp    106d74 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  106d58:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d5b:	8b 00                	mov    (%eax),%eax
  106d5d:	8d 50 04             	lea    0x4(%eax),%edx
  106d60:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d63:	89 10                	mov    %edx,(%eax)
  106d65:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d68:	8b 00                	mov    (%eax),%eax
  106d6a:	83 e8 04             	sub    $0x4,%eax
  106d6d:	8b 00                	mov    (%eax),%eax
  106d6f:	ba 00 00 00 00       	mov    $0x0,%edx
}
  106d74:	5d                   	pop    %ebp
  106d75:	c3                   	ret    

00106d76 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  106d76:	55                   	push   %ebp
  106d77:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  106d79:	8b 45 08             	mov    0x8(%ebp),%eax
  106d7c:	8b 40 18             	mov    0x18(%eax),%eax
  106d7f:	83 e0 02             	and    $0x2,%eax
  106d82:	85 c0                	test   %eax,%eax
  106d84:	74 1c                	je     106da2 <getint+0x2c>
		return va_arg(*ap, long long);
  106d86:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d89:	8b 00                	mov    (%eax),%eax
  106d8b:	8d 50 08             	lea    0x8(%eax),%edx
  106d8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d91:	89 10                	mov    %edx,(%eax)
  106d93:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d96:	8b 00                	mov    (%eax),%eax
  106d98:	83 e8 08             	sub    $0x8,%eax
  106d9b:	8b 50 04             	mov    0x4(%eax),%edx
  106d9e:	8b 00                	mov    (%eax),%eax
  106da0:	eb 47                	jmp    106de9 <getint+0x73>
	else if (st->flags & F_L)
  106da2:	8b 45 08             	mov    0x8(%ebp),%eax
  106da5:	8b 40 18             	mov    0x18(%eax),%eax
  106da8:	83 e0 01             	and    $0x1,%eax
  106dab:	84 c0                	test   %al,%al
  106dad:	74 1e                	je     106dcd <getint+0x57>
		return va_arg(*ap, long);
  106daf:	8b 45 0c             	mov    0xc(%ebp),%eax
  106db2:	8b 00                	mov    (%eax),%eax
  106db4:	8d 50 04             	lea    0x4(%eax),%edx
  106db7:	8b 45 0c             	mov    0xc(%ebp),%eax
  106dba:	89 10                	mov    %edx,(%eax)
  106dbc:	8b 45 0c             	mov    0xc(%ebp),%eax
  106dbf:	8b 00                	mov    (%eax),%eax
  106dc1:	83 e8 04             	sub    $0x4,%eax
  106dc4:	8b 00                	mov    (%eax),%eax
  106dc6:	89 c2                	mov    %eax,%edx
  106dc8:	c1 fa 1f             	sar    $0x1f,%edx
  106dcb:	eb 1c                	jmp    106de9 <getint+0x73>
	else
		return va_arg(*ap, int);
  106dcd:	8b 45 0c             	mov    0xc(%ebp),%eax
  106dd0:	8b 00                	mov    (%eax),%eax
  106dd2:	8d 50 04             	lea    0x4(%eax),%edx
  106dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
  106dd8:	89 10                	mov    %edx,(%eax)
  106dda:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ddd:	8b 00                	mov    (%eax),%eax
  106ddf:	83 e8 04             	sub    $0x4,%eax
  106de2:	8b 00                	mov    (%eax),%eax
  106de4:	89 c2                	mov    %eax,%edx
  106de6:	c1 fa 1f             	sar    $0x1f,%edx
}
  106de9:	5d                   	pop    %ebp
  106dea:	c3                   	ret    

00106deb <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  106deb:	55                   	push   %ebp
  106dec:	89 e5                	mov    %esp,%ebp
  106dee:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  106df1:	eb 1a                	jmp    106e0d <putpad+0x22>
		st->putch(st->padc, st->putdat);
  106df3:	8b 45 08             	mov    0x8(%ebp),%eax
  106df6:	8b 08                	mov    (%eax),%ecx
  106df8:	8b 45 08             	mov    0x8(%ebp),%eax
  106dfb:	8b 50 04             	mov    0x4(%eax),%edx
  106dfe:	8b 45 08             	mov    0x8(%ebp),%eax
  106e01:	8b 40 08             	mov    0x8(%eax),%eax
  106e04:	89 54 24 04          	mov    %edx,0x4(%esp)
  106e08:	89 04 24             	mov    %eax,(%esp)
  106e0b:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  106e0d:	8b 45 08             	mov    0x8(%ebp),%eax
  106e10:	8b 40 0c             	mov    0xc(%eax),%eax
  106e13:	8d 50 ff             	lea    -0x1(%eax),%edx
  106e16:	8b 45 08             	mov    0x8(%ebp),%eax
  106e19:	89 50 0c             	mov    %edx,0xc(%eax)
  106e1c:	8b 45 08             	mov    0x8(%ebp),%eax
  106e1f:	8b 40 0c             	mov    0xc(%eax),%eax
  106e22:	85 c0                	test   %eax,%eax
  106e24:	79 cd                	jns    106df3 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  106e26:	c9                   	leave  
  106e27:	c3                   	ret    

00106e28 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  106e28:	55                   	push   %ebp
  106e29:	89 e5                	mov    %esp,%ebp
  106e2b:	53                   	push   %ebx
  106e2c:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  106e2f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  106e33:	79 18                	jns    106e4d <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  106e35:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  106e3c:	00 
  106e3d:	8b 45 0c             	mov    0xc(%ebp),%eax
  106e40:	89 04 24             	mov    %eax,(%esp)
  106e43:	e8 e7 07 00 00       	call   10762f <strchr>
  106e48:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106e4b:	eb 2c                	jmp    106e79 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  106e4d:	8b 45 10             	mov    0x10(%ebp),%eax
  106e50:	89 44 24 08          	mov    %eax,0x8(%esp)
  106e54:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  106e5b:	00 
  106e5c:	8b 45 0c             	mov    0xc(%ebp),%eax
  106e5f:	89 04 24             	mov    %eax,(%esp)
  106e62:	e8 cc 09 00 00       	call   107833 <memchr>
  106e67:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106e6a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  106e6e:	75 09                	jne    106e79 <putstr+0x51>
		lim = str + maxlen;
  106e70:	8b 45 10             	mov    0x10(%ebp),%eax
  106e73:	03 45 0c             	add    0xc(%ebp),%eax
  106e76:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  106e79:	8b 45 08             	mov    0x8(%ebp),%eax
  106e7c:	8b 40 0c             	mov    0xc(%eax),%eax
  106e7f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  106e82:	8b 55 f0             	mov    -0x10(%ebp),%edx
  106e85:	89 cb                	mov    %ecx,%ebx
  106e87:	29 d3                	sub    %edx,%ebx
  106e89:	89 da                	mov    %ebx,%edx
  106e8b:	8d 14 10             	lea    (%eax,%edx,1),%edx
  106e8e:	8b 45 08             	mov    0x8(%ebp),%eax
  106e91:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  106e94:	8b 45 08             	mov    0x8(%ebp),%eax
  106e97:	8b 40 18             	mov    0x18(%eax),%eax
  106e9a:	83 e0 10             	and    $0x10,%eax
  106e9d:	85 c0                	test   %eax,%eax
  106e9f:	75 32                	jne    106ed3 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  106ea1:	8b 45 08             	mov    0x8(%ebp),%eax
  106ea4:	89 04 24             	mov    %eax,(%esp)
  106ea7:	e8 3f ff ff ff       	call   106deb <putpad>
	while (str < lim) {
  106eac:	eb 25                	jmp    106ed3 <putstr+0xab>
		char ch = *str++;
  106eae:	8b 45 0c             	mov    0xc(%ebp),%eax
  106eb1:	0f b6 00             	movzbl (%eax),%eax
  106eb4:	88 45 f7             	mov    %al,-0x9(%ebp)
  106eb7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  106ebb:	8b 45 08             	mov    0x8(%ebp),%eax
  106ebe:	8b 08                	mov    (%eax),%ecx
  106ec0:	8b 45 08             	mov    0x8(%ebp),%eax
  106ec3:	8b 50 04             	mov    0x4(%eax),%edx
  106ec6:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  106eca:	89 54 24 04          	mov    %edx,0x4(%esp)
  106ece:	89 04 24             	mov    %eax,(%esp)
  106ed1:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  106ed3:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ed6:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  106ed9:	72 d3                	jb     106eae <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  106edb:	8b 45 08             	mov    0x8(%ebp),%eax
  106ede:	89 04 24             	mov    %eax,(%esp)
  106ee1:	e8 05 ff ff ff       	call   106deb <putpad>
}
  106ee6:	83 c4 24             	add    $0x24,%esp
  106ee9:	5b                   	pop    %ebx
  106eea:	5d                   	pop    %ebp
  106eeb:	c3                   	ret    

00106eec <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  106eec:	55                   	push   %ebp
  106eed:	89 e5                	mov    %esp,%ebp
  106eef:	53                   	push   %ebx
  106ef0:	83 ec 24             	sub    $0x24,%esp
  106ef3:	8b 45 10             	mov    0x10(%ebp),%eax
  106ef6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106ef9:	8b 45 14             	mov    0x14(%ebp),%eax
  106efc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  106eff:	8b 45 08             	mov    0x8(%ebp),%eax
  106f02:	8b 40 1c             	mov    0x1c(%eax),%eax
  106f05:	89 c2                	mov    %eax,%edx
  106f07:	c1 fa 1f             	sar    $0x1f,%edx
  106f0a:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  106f0d:	77 4e                	ja     106f5d <genint+0x71>
  106f0f:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  106f12:	72 05                	jb     106f19 <genint+0x2d>
  106f14:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  106f17:	77 44                	ja     106f5d <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  106f19:	8b 45 08             	mov    0x8(%ebp),%eax
  106f1c:	8b 40 1c             	mov    0x1c(%eax),%eax
  106f1f:	89 c2                	mov    %eax,%edx
  106f21:	c1 fa 1f             	sar    $0x1f,%edx
  106f24:	89 44 24 08          	mov    %eax,0x8(%esp)
  106f28:	89 54 24 0c          	mov    %edx,0xc(%esp)
  106f2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106f2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106f32:	89 04 24             	mov    %eax,(%esp)
  106f35:	89 54 24 04          	mov    %edx,0x4(%esp)
  106f39:	e8 32 09 00 00       	call   107870 <__udivdi3>
  106f3e:	89 44 24 08          	mov    %eax,0x8(%esp)
  106f42:	89 54 24 0c          	mov    %edx,0xc(%esp)
  106f46:	8b 45 0c             	mov    0xc(%ebp),%eax
  106f49:	89 44 24 04          	mov    %eax,0x4(%esp)
  106f4d:	8b 45 08             	mov    0x8(%ebp),%eax
  106f50:	89 04 24             	mov    %eax,(%esp)
  106f53:	e8 94 ff ff ff       	call   106eec <genint>
  106f58:	89 45 0c             	mov    %eax,0xc(%ebp)
  106f5b:	eb 1b                	jmp    106f78 <genint+0x8c>
	else if (st->signc >= 0)
  106f5d:	8b 45 08             	mov    0x8(%ebp),%eax
  106f60:	8b 40 14             	mov    0x14(%eax),%eax
  106f63:	85 c0                	test   %eax,%eax
  106f65:	78 11                	js     106f78 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  106f67:	8b 45 08             	mov    0x8(%ebp),%eax
  106f6a:	8b 40 14             	mov    0x14(%eax),%eax
  106f6d:	89 c2                	mov    %eax,%edx
  106f6f:	8b 45 0c             	mov    0xc(%ebp),%eax
  106f72:	88 10                	mov    %dl,(%eax)
  106f74:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  106f78:	8b 45 08             	mov    0x8(%ebp),%eax
  106f7b:	8b 40 1c             	mov    0x1c(%eax),%eax
  106f7e:	89 c1                	mov    %eax,%ecx
  106f80:	89 c3                	mov    %eax,%ebx
  106f82:	c1 fb 1f             	sar    $0x1f,%ebx
  106f85:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106f88:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106f8b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  106f8f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  106f93:	89 04 24             	mov    %eax,(%esp)
  106f96:	89 54 24 04          	mov    %edx,0x4(%esp)
  106f9a:	e8 01 0a 00 00       	call   1079a0 <__umoddi3>
  106f9f:	05 00 98 10 00       	add    $0x109800,%eax
  106fa4:	0f b6 10             	movzbl (%eax),%edx
  106fa7:	8b 45 0c             	mov    0xc(%ebp),%eax
  106faa:	88 10                	mov    %dl,(%eax)
  106fac:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  106fb0:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  106fb3:	83 c4 24             	add    $0x24,%esp
  106fb6:	5b                   	pop    %ebx
  106fb7:	5d                   	pop    %ebp
  106fb8:	c3                   	ret    

00106fb9 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  106fb9:	55                   	push   %ebp
  106fba:	89 e5                	mov    %esp,%ebp
  106fbc:	83 ec 58             	sub    $0x58,%esp
  106fbf:	8b 45 0c             	mov    0xc(%ebp),%eax
  106fc2:	89 45 c0             	mov    %eax,-0x40(%ebp)
  106fc5:	8b 45 10             	mov    0x10(%ebp),%eax
  106fc8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  106fcb:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  106fce:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  106fd1:	8b 45 08             	mov    0x8(%ebp),%eax
  106fd4:	8b 55 14             	mov    0x14(%ebp),%edx
  106fd7:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  106fda:	8b 45 c0             	mov    -0x40(%ebp),%eax
  106fdd:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  106fe0:	89 44 24 08          	mov    %eax,0x8(%esp)
  106fe4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  106fe8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106feb:	89 44 24 04          	mov    %eax,0x4(%esp)
  106fef:	8b 45 08             	mov    0x8(%ebp),%eax
  106ff2:	89 04 24             	mov    %eax,(%esp)
  106ff5:	e8 f2 fe ff ff       	call   106eec <genint>
  106ffa:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  106ffd:	8b 55 f4             	mov    -0xc(%ebp),%edx
  107000:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  107003:	89 d1                	mov    %edx,%ecx
  107005:	29 c1                	sub    %eax,%ecx
  107007:	89 c8                	mov    %ecx,%eax
  107009:	89 44 24 08          	mov    %eax,0x8(%esp)
  10700d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  107010:	89 44 24 04          	mov    %eax,0x4(%esp)
  107014:	8b 45 08             	mov    0x8(%ebp),%eax
  107017:	89 04 24             	mov    %eax,(%esp)
  10701a:	e8 09 fe ff ff       	call   106e28 <putstr>
}
  10701f:	c9                   	leave  
  107020:	c3                   	ret    

00107021 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  107021:	55                   	push   %ebp
  107022:	89 e5                	mov    %esp,%ebp
  107024:	53                   	push   %ebx
  107025:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  107028:	8d 55 c8             	lea    -0x38(%ebp),%edx
  10702b:	b9 00 00 00 00       	mov    $0x0,%ecx
  107030:	b8 20 00 00 00       	mov    $0x20,%eax
  107035:	89 c3                	mov    %eax,%ebx
  107037:	83 e3 fc             	and    $0xfffffffc,%ebx
  10703a:	b8 00 00 00 00       	mov    $0x0,%eax
  10703f:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  107042:	83 c0 04             	add    $0x4,%eax
  107045:	39 d8                	cmp    %ebx,%eax
  107047:	72 f6                	jb     10703f <vprintfmt+0x1e>
  107049:	01 c2                	add    %eax,%edx
  10704b:	8b 45 08             	mov    0x8(%ebp),%eax
  10704e:	89 45 c8             	mov    %eax,-0x38(%ebp)
  107051:	8b 45 0c             	mov    0xc(%ebp),%eax
  107054:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  107057:	eb 17                	jmp    107070 <vprintfmt+0x4f>
			if (ch == '\0')
  107059:	85 db                	test   %ebx,%ebx
  10705b:	0f 84 52 03 00 00    	je     1073b3 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  107061:	8b 45 0c             	mov    0xc(%ebp),%eax
  107064:	89 44 24 04          	mov    %eax,0x4(%esp)
  107068:	89 1c 24             	mov    %ebx,(%esp)
  10706b:	8b 45 08             	mov    0x8(%ebp),%eax
  10706e:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  107070:	8b 45 10             	mov    0x10(%ebp),%eax
  107073:	0f b6 00             	movzbl (%eax),%eax
  107076:	0f b6 d8             	movzbl %al,%ebx
  107079:	83 fb 25             	cmp    $0x25,%ebx
  10707c:	0f 95 c0             	setne  %al
  10707f:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  107083:	84 c0                	test   %al,%al
  107085:	75 d2                	jne    107059 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  107087:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  10708e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  107095:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  10709c:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  1070a3:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  1070aa:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  1070b1:	eb 04                	jmp    1070b7 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  1070b3:	90                   	nop
  1070b4:	eb 01                	jmp    1070b7 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  1070b6:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  1070b7:	8b 45 10             	mov    0x10(%ebp),%eax
  1070ba:	0f b6 00             	movzbl (%eax),%eax
  1070bd:	0f b6 d8             	movzbl %al,%ebx
  1070c0:	89 d8                	mov    %ebx,%eax
  1070c2:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1070c6:	83 e8 20             	sub    $0x20,%eax
  1070c9:	83 f8 58             	cmp    $0x58,%eax
  1070cc:	0f 87 b1 02 00 00    	ja     107383 <vprintfmt+0x362>
  1070d2:	8b 04 85 18 98 10 00 	mov    0x109818(,%eax,4),%eax
  1070d9:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  1070db:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1070de:	83 c8 10             	or     $0x10,%eax
  1070e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1070e4:	eb d1                	jmp    1070b7 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  1070e6:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  1070ed:	eb c8                	jmp    1070b7 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  1070ef:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1070f2:	85 c0                	test   %eax,%eax
  1070f4:	79 bd                	jns    1070b3 <vprintfmt+0x92>
				st.signc = ' ';
  1070f6:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  1070fd:	eb b8                	jmp    1070b7 <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  1070ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107102:	83 e0 08             	and    $0x8,%eax
  107105:	85 c0                	test   %eax,%eax
  107107:	75 07                	jne    107110 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  107109:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  107110:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  107117:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10711a:	89 d0                	mov    %edx,%eax
  10711c:	c1 e0 02             	shl    $0x2,%eax
  10711f:	01 d0                	add    %edx,%eax
  107121:	01 c0                	add    %eax,%eax
  107123:	01 d8                	add    %ebx,%eax
  107125:	83 e8 30             	sub    $0x30,%eax
  107128:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  10712b:	8b 45 10             	mov    0x10(%ebp),%eax
  10712e:	0f b6 00             	movzbl (%eax),%eax
  107131:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  107134:	83 fb 2f             	cmp    $0x2f,%ebx
  107137:	7e 21                	jle    10715a <vprintfmt+0x139>
  107139:	83 fb 39             	cmp    $0x39,%ebx
  10713c:	7f 1f                	jg     10715d <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10713e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  107142:	eb d3                	jmp    107117 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  107144:	8b 45 14             	mov    0x14(%ebp),%eax
  107147:	83 c0 04             	add    $0x4,%eax
  10714a:	89 45 14             	mov    %eax,0x14(%ebp)
  10714d:	8b 45 14             	mov    0x14(%ebp),%eax
  107150:	83 e8 04             	sub    $0x4,%eax
  107153:	8b 00                	mov    (%eax),%eax
  107155:	89 45 d8             	mov    %eax,-0x28(%ebp)
  107158:	eb 04                	jmp    10715e <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  10715a:	90                   	nop
  10715b:	eb 01                	jmp    10715e <vprintfmt+0x13d>
  10715d:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  10715e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107161:	83 e0 08             	and    $0x8,%eax
  107164:	85 c0                	test   %eax,%eax
  107166:	0f 85 4a ff ff ff    	jne    1070b6 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  10716c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10716f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  107172:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  107179:	e9 39 ff ff ff       	jmp    1070b7 <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  10717e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107181:	83 c8 08             	or     $0x8,%eax
  107184:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107187:	e9 2b ff ff ff       	jmp    1070b7 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  10718c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10718f:	83 c8 04             	or     $0x4,%eax
  107192:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107195:	e9 1d ff ff ff       	jmp    1070b7 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  10719a:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10719d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1071a0:	83 e0 01             	and    $0x1,%eax
  1071a3:	84 c0                	test   %al,%al
  1071a5:	74 07                	je     1071ae <vprintfmt+0x18d>
  1071a7:	b8 02 00 00 00       	mov    $0x2,%eax
  1071ac:	eb 05                	jmp    1071b3 <vprintfmt+0x192>
  1071ae:	b8 01 00 00 00       	mov    $0x1,%eax
  1071b3:	09 d0                	or     %edx,%eax
  1071b5:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1071b8:	e9 fa fe ff ff       	jmp    1070b7 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  1071bd:	8b 45 14             	mov    0x14(%ebp),%eax
  1071c0:	83 c0 04             	add    $0x4,%eax
  1071c3:	89 45 14             	mov    %eax,0x14(%ebp)
  1071c6:	8b 45 14             	mov    0x14(%ebp),%eax
  1071c9:	83 e8 04             	sub    $0x4,%eax
  1071cc:	8b 00                	mov    (%eax),%eax
  1071ce:	8b 55 0c             	mov    0xc(%ebp),%edx
  1071d1:	89 54 24 04          	mov    %edx,0x4(%esp)
  1071d5:	89 04 24             	mov    %eax,(%esp)
  1071d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1071db:	ff d0                	call   *%eax
			break;
  1071dd:	e9 cb 01 00 00       	jmp    1073ad <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  1071e2:	8b 45 14             	mov    0x14(%ebp),%eax
  1071e5:	83 c0 04             	add    $0x4,%eax
  1071e8:	89 45 14             	mov    %eax,0x14(%ebp)
  1071eb:	8b 45 14             	mov    0x14(%ebp),%eax
  1071ee:	83 e8 04             	sub    $0x4,%eax
  1071f1:	8b 00                	mov    (%eax),%eax
  1071f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1071f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1071fa:	75 07                	jne    107203 <vprintfmt+0x1e2>
				s = "(null)";
  1071fc:	c7 45 f4 11 98 10 00 	movl   $0x109811,-0xc(%ebp)
			putstr(&st, s, st.prec);
  107203:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107206:	89 44 24 08          	mov    %eax,0x8(%esp)
  10720a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10720d:	89 44 24 04          	mov    %eax,0x4(%esp)
  107211:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107214:	89 04 24             	mov    %eax,(%esp)
  107217:	e8 0c fc ff ff       	call   106e28 <putstr>
			break;
  10721c:	e9 8c 01 00 00       	jmp    1073ad <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  107221:	8d 45 14             	lea    0x14(%ebp),%eax
  107224:	89 44 24 04          	mov    %eax,0x4(%esp)
  107228:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10722b:	89 04 24             	mov    %eax,(%esp)
  10722e:	e8 43 fb ff ff       	call   106d76 <getint>
  107233:	89 45 e8             	mov    %eax,-0x18(%ebp)
  107236:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  107239:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10723c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10723f:	85 d2                	test   %edx,%edx
  107241:	79 1a                	jns    10725d <vprintfmt+0x23c>
				num = -(intmax_t) num;
  107243:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107246:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107249:	f7 d8                	neg    %eax
  10724b:	83 d2 00             	adc    $0x0,%edx
  10724e:	f7 da                	neg    %edx
  107250:	89 45 e8             	mov    %eax,-0x18(%ebp)
  107253:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  107256:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  10725d:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  107264:	00 
  107265:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107268:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10726b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10726f:	89 54 24 08          	mov    %edx,0x8(%esp)
  107273:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107276:	89 04 24             	mov    %eax,(%esp)
  107279:	e8 3b fd ff ff       	call   106fb9 <putint>
			break;
  10727e:	e9 2a 01 00 00       	jmp    1073ad <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  107283:	8d 45 14             	lea    0x14(%ebp),%eax
  107286:	89 44 24 04          	mov    %eax,0x4(%esp)
  10728a:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10728d:	89 04 24             	mov    %eax,(%esp)
  107290:	e8 6c fa ff ff       	call   106d01 <getuint>
  107295:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10729c:	00 
  10729d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1072a1:	89 54 24 08          	mov    %edx,0x8(%esp)
  1072a5:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1072a8:	89 04 24             	mov    %eax,(%esp)
  1072ab:	e8 09 fd ff ff       	call   106fb9 <putint>
			break;
  1072b0:	e9 f8 00 00 00       	jmp    1073ad <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  1072b5:	8d 45 14             	lea    0x14(%ebp),%eax
  1072b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1072bc:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1072bf:	89 04 24             	mov    %eax,(%esp)
  1072c2:	e8 3a fa ff ff       	call   106d01 <getuint>
  1072c7:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  1072ce:	00 
  1072cf:	89 44 24 04          	mov    %eax,0x4(%esp)
  1072d3:	89 54 24 08          	mov    %edx,0x8(%esp)
  1072d7:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1072da:	89 04 24             	mov    %eax,(%esp)
  1072dd:	e8 d7 fc ff ff       	call   106fb9 <putint>
			break;
  1072e2:	e9 c6 00 00 00       	jmp    1073ad <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  1072e7:	8d 45 14             	lea    0x14(%ebp),%eax
  1072ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  1072ee:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1072f1:	89 04 24             	mov    %eax,(%esp)
  1072f4:	e8 08 fa ff ff       	call   106d01 <getuint>
  1072f9:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  107300:	00 
  107301:	89 44 24 04          	mov    %eax,0x4(%esp)
  107305:	89 54 24 08          	mov    %edx,0x8(%esp)
  107309:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10730c:	89 04 24             	mov    %eax,(%esp)
  10730f:	e8 a5 fc ff ff       	call   106fb9 <putint>
			break;
  107314:	e9 94 00 00 00       	jmp    1073ad <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  107319:	8b 45 0c             	mov    0xc(%ebp),%eax
  10731c:	89 44 24 04          	mov    %eax,0x4(%esp)
  107320:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  107327:	8b 45 08             	mov    0x8(%ebp),%eax
  10732a:	ff d0                	call   *%eax
			putch('x', putdat);
  10732c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10732f:	89 44 24 04          	mov    %eax,0x4(%esp)
  107333:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  10733a:	8b 45 08             	mov    0x8(%ebp),%eax
  10733d:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  10733f:	8b 45 14             	mov    0x14(%ebp),%eax
  107342:	83 c0 04             	add    $0x4,%eax
  107345:	89 45 14             	mov    %eax,0x14(%ebp)
  107348:	8b 45 14             	mov    0x14(%ebp),%eax
  10734b:	83 e8 04             	sub    $0x4,%eax
  10734e:	8b 00                	mov    (%eax),%eax
  107350:	ba 00 00 00 00       	mov    $0x0,%edx
  107355:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10735c:	00 
  10735d:	89 44 24 04          	mov    %eax,0x4(%esp)
  107361:	89 54 24 08          	mov    %edx,0x8(%esp)
  107365:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107368:	89 04 24             	mov    %eax,(%esp)
  10736b:	e8 49 fc ff ff       	call   106fb9 <putint>
			break;
  107370:	eb 3b                	jmp    1073ad <vprintfmt+0x38c>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
  107372:	8b 45 0c             	mov    0xc(%ebp),%eax
  107375:	89 44 24 04          	mov    %eax,0x4(%esp)
  107379:	89 1c 24             	mov    %ebx,(%esp)
  10737c:	8b 45 08             	mov    0x8(%ebp),%eax
  10737f:	ff d0                	call   *%eax
			break;
  107381:	eb 2a                	jmp    1073ad <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  107383:	8b 45 0c             	mov    0xc(%ebp),%eax
  107386:	89 44 24 04          	mov    %eax,0x4(%esp)
  10738a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  107391:	8b 45 08             	mov    0x8(%ebp),%eax
  107394:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  107396:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10739a:	eb 04                	jmp    1073a0 <vprintfmt+0x37f>
  10739c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1073a0:	8b 45 10             	mov    0x10(%ebp),%eax
  1073a3:	83 e8 01             	sub    $0x1,%eax
  1073a6:	0f b6 00             	movzbl (%eax),%eax
  1073a9:	3c 25                	cmp    $0x25,%al
  1073ab:	75 ef                	jne    10739c <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  1073ad:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1073ae:	e9 bd fc ff ff       	jmp    107070 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  1073b3:	83 c4 44             	add    $0x44,%esp
  1073b6:	5b                   	pop    %ebx
  1073b7:	5d                   	pop    %ebp
  1073b8:	c3                   	ret    

001073b9 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  1073b9:	55                   	push   %ebp
  1073ba:	89 e5                	mov    %esp,%ebp
  1073bc:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  1073bf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1073c2:	8b 00                	mov    (%eax),%eax
  1073c4:	8b 55 08             	mov    0x8(%ebp),%edx
  1073c7:	89 d1                	mov    %edx,%ecx
  1073c9:	8b 55 0c             	mov    0xc(%ebp),%edx
  1073cc:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  1073d0:	8d 50 01             	lea    0x1(%eax),%edx
  1073d3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1073d6:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  1073d8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1073db:	8b 00                	mov    (%eax),%eax
  1073dd:	3d ff 00 00 00       	cmp    $0xff,%eax
  1073e2:	75 24                	jne    107408 <putch+0x4f>
		b->buf[b->idx] = 0;
  1073e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1073e7:	8b 00                	mov    (%eax),%eax
  1073e9:	8b 55 0c             	mov    0xc(%ebp),%edx
  1073ec:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  1073f1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1073f4:	83 c0 08             	add    $0x8,%eax
  1073f7:	89 04 24             	mov    %eax,(%esp)
  1073fa:	e8 f9 8f ff ff       	call   1003f8 <cputs>
		b->idx = 0;
  1073ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  107402:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  107408:	8b 45 0c             	mov    0xc(%ebp),%eax
  10740b:	8b 40 04             	mov    0x4(%eax),%eax
  10740e:	8d 50 01             	lea    0x1(%eax),%edx
  107411:	8b 45 0c             	mov    0xc(%ebp),%eax
  107414:	89 50 04             	mov    %edx,0x4(%eax)
}
  107417:	c9                   	leave  
  107418:	c3                   	ret    

00107419 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  107419:	55                   	push   %ebp
  10741a:	89 e5                	mov    %esp,%ebp
  10741c:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  107422:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  107429:	00 00 00 
	b.cnt = 0;
  10742c:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  107433:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  107436:	b8 b9 73 10 00       	mov    $0x1073b9,%eax
  10743b:	8b 55 0c             	mov    0xc(%ebp),%edx
  10743e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107442:	8b 55 08             	mov    0x8(%ebp),%edx
  107445:	89 54 24 08          	mov    %edx,0x8(%esp)
  107449:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  10744f:	89 54 24 04          	mov    %edx,0x4(%esp)
  107453:	89 04 24             	mov    %eax,(%esp)
  107456:	e8 c6 fb ff ff       	call   107021 <vprintfmt>

	b.buf[b.idx] = 0;
  10745b:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  107461:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  107468:	00 
	cputs(b.buf);
  107469:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  10746f:	83 c0 08             	add    $0x8,%eax
  107472:	89 04 24             	mov    %eax,(%esp)
  107475:	e8 7e 8f ff ff       	call   1003f8 <cputs>

	return b.cnt;
  10747a:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  107480:	c9                   	leave  
  107481:	c3                   	ret    

00107482 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  107482:	55                   	push   %ebp
  107483:	89 e5                	mov    %esp,%ebp
  107485:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  107488:	8d 45 08             	lea    0x8(%ebp),%eax
  10748b:	83 c0 04             	add    $0x4,%eax
  10748e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  107491:	8b 45 08             	mov    0x8(%ebp),%eax
  107494:	8b 55 f0             	mov    -0x10(%ebp),%edx
  107497:	89 54 24 04          	mov    %edx,0x4(%esp)
  10749b:	89 04 24             	mov    %eax,(%esp)
  10749e:	e8 76 ff ff ff       	call   107419 <vcprintf>
  1074a3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  1074a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1074a9:	c9                   	leave  
  1074aa:	c3                   	ret    

001074ab <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  1074ab:	55                   	push   %ebp
  1074ac:	89 e5                	mov    %esp,%ebp
  1074ae:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  1074b1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1074b8:	eb 08                	jmp    1074c2 <strlen+0x17>
		n++;
  1074ba:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  1074be:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1074c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1074c5:	0f b6 00             	movzbl (%eax),%eax
  1074c8:	84 c0                	test   %al,%al
  1074ca:	75 ee                	jne    1074ba <strlen+0xf>
		n++;
	return n;
  1074cc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1074cf:	c9                   	leave  
  1074d0:	c3                   	ret    

001074d1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  1074d1:	55                   	push   %ebp
  1074d2:	89 e5                	mov    %esp,%ebp
  1074d4:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  1074d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1074da:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  1074dd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1074e0:	0f b6 10             	movzbl (%eax),%edx
  1074e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1074e6:	88 10                	mov    %dl,(%eax)
  1074e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1074eb:	0f b6 00             	movzbl (%eax),%eax
  1074ee:	84 c0                	test   %al,%al
  1074f0:	0f 95 c0             	setne  %al
  1074f3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1074f7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  1074fb:	84 c0                	test   %al,%al
  1074fd:	75 de                	jne    1074dd <strcpy+0xc>
		/* do nothing */;
	return ret;
  1074ff:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  107502:	c9                   	leave  
  107503:	c3                   	ret    

00107504 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  107504:	55                   	push   %ebp
  107505:	89 e5                	mov    %esp,%ebp
  107507:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  10750a:	8b 45 08             	mov    0x8(%ebp),%eax
  10750d:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  107510:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  107517:	eb 21                	jmp    10753a <strncpy+0x36>
		*dst++ = *src;
  107519:	8b 45 0c             	mov    0xc(%ebp),%eax
  10751c:	0f b6 10             	movzbl (%eax),%edx
  10751f:	8b 45 08             	mov    0x8(%ebp),%eax
  107522:	88 10                	mov    %dl,(%eax)
  107524:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  107528:	8b 45 0c             	mov    0xc(%ebp),%eax
  10752b:	0f b6 00             	movzbl (%eax),%eax
  10752e:	84 c0                	test   %al,%al
  107530:	74 04                	je     107536 <strncpy+0x32>
			src++;
  107532:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  107536:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  10753a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10753d:	3b 45 10             	cmp    0x10(%ebp),%eax
  107540:	72 d7                	jb     107519 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  107542:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  107545:	c9                   	leave  
  107546:	c3                   	ret    

00107547 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  107547:	55                   	push   %ebp
  107548:	89 e5                	mov    %esp,%ebp
  10754a:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  10754d:	8b 45 08             	mov    0x8(%ebp),%eax
  107550:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  107553:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107557:	74 2f                	je     107588 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  107559:	eb 13                	jmp    10756e <strlcpy+0x27>
			*dst++ = *src++;
  10755b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10755e:	0f b6 10             	movzbl (%eax),%edx
  107561:	8b 45 08             	mov    0x8(%ebp),%eax
  107564:	88 10                	mov    %dl,(%eax)
  107566:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10756a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  10756e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107572:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107576:	74 0a                	je     107582 <strlcpy+0x3b>
  107578:	8b 45 0c             	mov    0xc(%ebp),%eax
  10757b:	0f b6 00             	movzbl (%eax),%eax
  10757e:	84 c0                	test   %al,%al
  107580:	75 d9                	jne    10755b <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  107582:	8b 45 08             	mov    0x8(%ebp),%eax
  107585:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  107588:	8b 55 08             	mov    0x8(%ebp),%edx
  10758b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10758e:	89 d1                	mov    %edx,%ecx
  107590:	29 c1                	sub    %eax,%ecx
  107592:	89 c8                	mov    %ecx,%eax
}
  107594:	c9                   	leave  
  107595:	c3                   	ret    

00107596 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  107596:	55                   	push   %ebp
  107597:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  107599:	eb 08                	jmp    1075a3 <strcmp+0xd>
		p++, q++;
  10759b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10759f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  1075a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1075a6:	0f b6 00             	movzbl (%eax),%eax
  1075a9:	84 c0                	test   %al,%al
  1075ab:	74 10                	je     1075bd <strcmp+0x27>
  1075ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1075b0:	0f b6 10             	movzbl (%eax),%edx
  1075b3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075b6:	0f b6 00             	movzbl (%eax),%eax
  1075b9:	38 c2                	cmp    %al,%dl
  1075bb:	74 de                	je     10759b <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  1075bd:	8b 45 08             	mov    0x8(%ebp),%eax
  1075c0:	0f b6 00             	movzbl (%eax),%eax
  1075c3:	0f b6 d0             	movzbl %al,%edx
  1075c6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075c9:	0f b6 00             	movzbl (%eax),%eax
  1075cc:	0f b6 c0             	movzbl %al,%eax
  1075cf:	89 d1                	mov    %edx,%ecx
  1075d1:	29 c1                	sub    %eax,%ecx
  1075d3:	89 c8                	mov    %ecx,%eax
}
  1075d5:	5d                   	pop    %ebp
  1075d6:	c3                   	ret    

001075d7 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  1075d7:	55                   	push   %ebp
  1075d8:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  1075da:	eb 0c                	jmp    1075e8 <strncmp+0x11>
		n--, p++, q++;
  1075dc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1075e0:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1075e4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  1075e8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1075ec:	74 1a                	je     107608 <strncmp+0x31>
  1075ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1075f1:	0f b6 00             	movzbl (%eax),%eax
  1075f4:	84 c0                	test   %al,%al
  1075f6:	74 10                	je     107608 <strncmp+0x31>
  1075f8:	8b 45 08             	mov    0x8(%ebp),%eax
  1075fb:	0f b6 10             	movzbl (%eax),%edx
  1075fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  107601:	0f b6 00             	movzbl (%eax),%eax
  107604:	38 c2                	cmp    %al,%dl
  107606:	74 d4                	je     1075dc <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  107608:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10760c:	75 07                	jne    107615 <strncmp+0x3e>
		return 0;
  10760e:	b8 00 00 00 00       	mov    $0x0,%eax
  107613:	eb 18                	jmp    10762d <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  107615:	8b 45 08             	mov    0x8(%ebp),%eax
  107618:	0f b6 00             	movzbl (%eax),%eax
  10761b:	0f b6 d0             	movzbl %al,%edx
  10761e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107621:	0f b6 00             	movzbl (%eax),%eax
  107624:	0f b6 c0             	movzbl %al,%eax
  107627:	89 d1                	mov    %edx,%ecx
  107629:	29 c1                	sub    %eax,%ecx
  10762b:	89 c8                	mov    %ecx,%eax
}
  10762d:	5d                   	pop    %ebp
  10762e:	c3                   	ret    

0010762f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  10762f:	55                   	push   %ebp
  107630:	89 e5                	mov    %esp,%ebp
  107632:	83 ec 04             	sub    $0x4,%esp
  107635:	8b 45 0c             	mov    0xc(%ebp),%eax
  107638:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  10763b:	eb 1a                	jmp    107657 <strchr+0x28>
		if (*s++ == 0)
  10763d:	8b 45 08             	mov    0x8(%ebp),%eax
  107640:	0f b6 00             	movzbl (%eax),%eax
  107643:	84 c0                	test   %al,%al
  107645:	0f 94 c0             	sete   %al
  107648:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10764c:	84 c0                	test   %al,%al
  10764e:	74 07                	je     107657 <strchr+0x28>
			return NULL;
  107650:	b8 00 00 00 00       	mov    $0x0,%eax
  107655:	eb 0e                	jmp    107665 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  107657:	8b 45 08             	mov    0x8(%ebp),%eax
  10765a:	0f b6 00             	movzbl (%eax),%eax
  10765d:	3a 45 fc             	cmp    -0x4(%ebp),%al
  107660:	75 db                	jne    10763d <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  107662:	8b 45 08             	mov    0x8(%ebp),%eax
}
  107665:	c9                   	leave  
  107666:	c3                   	ret    

00107667 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  107667:	55                   	push   %ebp
  107668:	89 e5                	mov    %esp,%ebp
  10766a:	57                   	push   %edi
  10766b:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  10766e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107672:	75 05                	jne    107679 <memset+0x12>
		return v;
  107674:	8b 45 08             	mov    0x8(%ebp),%eax
  107677:	eb 5c                	jmp    1076d5 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  107679:	8b 45 08             	mov    0x8(%ebp),%eax
  10767c:	83 e0 03             	and    $0x3,%eax
  10767f:	85 c0                	test   %eax,%eax
  107681:	75 41                	jne    1076c4 <memset+0x5d>
  107683:	8b 45 10             	mov    0x10(%ebp),%eax
  107686:	83 e0 03             	and    $0x3,%eax
  107689:	85 c0                	test   %eax,%eax
  10768b:	75 37                	jne    1076c4 <memset+0x5d>
		c &= 0xFF;
  10768d:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  107694:	8b 45 0c             	mov    0xc(%ebp),%eax
  107697:	89 c2                	mov    %eax,%edx
  107699:	c1 e2 18             	shl    $0x18,%edx
  10769c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10769f:	c1 e0 10             	shl    $0x10,%eax
  1076a2:	09 c2                	or     %eax,%edx
  1076a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1076a7:	c1 e0 08             	shl    $0x8,%eax
  1076aa:	09 d0                	or     %edx,%eax
  1076ac:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  1076af:	8b 45 10             	mov    0x10(%ebp),%eax
  1076b2:	89 c1                	mov    %eax,%ecx
  1076b4:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  1076b7:	8b 55 08             	mov    0x8(%ebp),%edx
  1076ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  1076bd:	89 d7                	mov    %edx,%edi
  1076bf:	fc                   	cld    
  1076c0:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  1076c2:	eb 0e                	jmp    1076d2 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  1076c4:	8b 55 08             	mov    0x8(%ebp),%edx
  1076c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1076ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1076cd:	89 d7                	mov    %edx,%edi
  1076cf:	fc                   	cld    
  1076d0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  1076d2:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1076d5:	83 c4 10             	add    $0x10,%esp
  1076d8:	5f                   	pop    %edi
  1076d9:	5d                   	pop    %ebp
  1076da:	c3                   	ret    

001076db <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  1076db:	55                   	push   %ebp
  1076dc:	89 e5                	mov    %esp,%ebp
  1076de:	57                   	push   %edi
  1076df:	56                   	push   %esi
  1076e0:	53                   	push   %ebx
  1076e1:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  1076e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1076e7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  1076ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1076ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  1076f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1076f3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1076f6:	73 6e                	jae    107766 <memmove+0x8b>
  1076f8:	8b 45 10             	mov    0x10(%ebp),%eax
  1076fb:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1076fe:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107701:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  107704:	76 60                	jbe    107766 <memmove+0x8b>
		s += n;
  107706:	8b 45 10             	mov    0x10(%ebp),%eax
  107709:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  10770c:	8b 45 10             	mov    0x10(%ebp),%eax
  10770f:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107712:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107715:	83 e0 03             	and    $0x3,%eax
  107718:	85 c0                	test   %eax,%eax
  10771a:	75 2f                	jne    10774b <memmove+0x70>
  10771c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10771f:	83 e0 03             	and    $0x3,%eax
  107722:	85 c0                	test   %eax,%eax
  107724:	75 25                	jne    10774b <memmove+0x70>
  107726:	8b 45 10             	mov    0x10(%ebp),%eax
  107729:	83 e0 03             	and    $0x3,%eax
  10772c:	85 c0                	test   %eax,%eax
  10772e:	75 1b                	jne    10774b <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  107730:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107733:	83 e8 04             	sub    $0x4,%eax
  107736:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107739:	83 ea 04             	sub    $0x4,%edx
  10773c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10773f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  107742:	89 c7                	mov    %eax,%edi
  107744:	89 d6                	mov    %edx,%esi
  107746:	fd                   	std    
  107747:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107749:	eb 18                	jmp    107763 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  10774b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10774e:	8d 50 ff             	lea    -0x1(%eax),%edx
  107751:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107754:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  107757:	8b 45 10             	mov    0x10(%ebp),%eax
  10775a:	89 d7                	mov    %edx,%edi
  10775c:	89 de                	mov    %ebx,%esi
  10775e:	89 c1                	mov    %eax,%ecx
  107760:	fd                   	std    
  107761:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  107763:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  107764:	eb 45                	jmp    1077ab <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107766:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107769:	83 e0 03             	and    $0x3,%eax
  10776c:	85 c0                	test   %eax,%eax
  10776e:	75 2b                	jne    10779b <memmove+0xc0>
  107770:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107773:	83 e0 03             	and    $0x3,%eax
  107776:	85 c0                	test   %eax,%eax
  107778:	75 21                	jne    10779b <memmove+0xc0>
  10777a:	8b 45 10             	mov    0x10(%ebp),%eax
  10777d:	83 e0 03             	and    $0x3,%eax
  107780:	85 c0                	test   %eax,%eax
  107782:	75 17                	jne    10779b <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  107784:	8b 45 10             	mov    0x10(%ebp),%eax
  107787:	89 c1                	mov    %eax,%ecx
  107789:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  10778c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10778f:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107792:	89 c7                	mov    %eax,%edi
  107794:	89 d6                	mov    %edx,%esi
  107796:	fc                   	cld    
  107797:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107799:	eb 10                	jmp    1077ab <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  10779b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10779e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1077a1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1077a4:	89 c7                	mov    %eax,%edi
  1077a6:	89 d6                	mov    %edx,%esi
  1077a8:	fc                   	cld    
  1077a9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  1077ab:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1077ae:	83 c4 10             	add    $0x10,%esp
  1077b1:	5b                   	pop    %ebx
  1077b2:	5e                   	pop    %esi
  1077b3:	5f                   	pop    %edi
  1077b4:	5d                   	pop    %ebp
  1077b5:	c3                   	ret    

001077b6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  1077b6:	55                   	push   %ebp
  1077b7:	89 e5                	mov    %esp,%ebp
  1077b9:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  1077bc:	8b 45 10             	mov    0x10(%ebp),%eax
  1077bf:	89 44 24 08          	mov    %eax,0x8(%esp)
  1077c3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1077c6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1077ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1077cd:	89 04 24             	mov    %eax,(%esp)
  1077d0:	e8 06 ff ff ff       	call   1076db <memmove>
}
  1077d5:	c9                   	leave  
  1077d6:	c3                   	ret    

001077d7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  1077d7:	55                   	push   %ebp
  1077d8:	89 e5                	mov    %esp,%ebp
  1077da:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  1077dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1077e0:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  1077e3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1077e6:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  1077e9:	eb 32                	jmp    10781d <memcmp+0x46>
		if (*s1 != *s2)
  1077eb:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1077ee:	0f b6 10             	movzbl (%eax),%edx
  1077f1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1077f4:	0f b6 00             	movzbl (%eax),%eax
  1077f7:	38 c2                	cmp    %al,%dl
  1077f9:	74 1a                	je     107815 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  1077fb:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1077fe:	0f b6 00             	movzbl (%eax),%eax
  107801:	0f b6 d0             	movzbl %al,%edx
  107804:	8b 45 fc             	mov    -0x4(%ebp),%eax
  107807:	0f b6 00             	movzbl (%eax),%eax
  10780a:	0f b6 c0             	movzbl %al,%eax
  10780d:	89 d1                	mov    %edx,%ecx
  10780f:	29 c1                	sub    %eax,%ecx
  107811:	89 c8                	mov    %ecx,%eax
  107813:	eb 1c                	jmp    107831 <memcmp+0x5a>
		s1++, s2++;
  107815:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  107819:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  10781d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107821:	0f 95 c0             	setne  %al
  107824:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107828:	84 c0                	test   %al,%al
  10782a:	75 bf                	jne    1077eb <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  10782c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  107831:	c9                   	leave  
  107832:	c3                   	ret    

00107833 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  107833:	55                   	push   %ebp
  107834:	89 e5                	mov    %esp,%ebp
  107836:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  107839:	8b 45 10             	mov    0x10(%ebp),%eax
  10783c:	8b 55 08             	mov    0x8(%ebp),%edx
  10783f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107842:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  107845:	eb 16                	jmp    10785d <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  107847:	8b 45 08             	mov    0x8(%ebp),%eax
  10784a:	0f b6 10             	movzbl (%eax),%edx
  10784d:	8b 45 0c             	mov    0xc(%ebp),%eax
  107850:	38 c2                	cmp    %al,%dl
  107852:	75 05                	jne    107859 <memchr+0x26>
			return (void *) s;
  107854:	8b 45 08             	mov    0x8(%ebp),%eax
  107857:	eb 11                	jmp    10786a <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  107859:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10785d:	8b 45 08             	mov    0x8(%ebp),%eax
  107860:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  107863:	72 e2                	jb     107847 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  107865:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10786a:	c9                   	leave  
  10786b:	c3                   	ret    
  10786c:	66 90                	xchg   %ax,%ax
  10786e:	66 90                	xchg   %ax,%ax

00107870 <__udivdi3>:
  107870:	55                   	push   %ebp
  107871:	89 e5                	mov    %esp,%ebp
  107873:	57                   	push   %edi
  107874:	56                   	push   %esi
  107875:	83 ec 10             	sub    $0x10,%esp
  107878:	8b 45 14             	mov    0x14(%ebp),%eax
  10787b:	8b 55 08             	mov    0x8(%ebp),%edx
  10787e:	8b 75 10             	mov    0x10(%ebp),%esi
  107881:	8b 7d 0c             	mov    0xc(%ebp),%edi
  107884:	85 c0                	test   %eax,%eax
  107886:	89 55 f0             	mov    %edx,-0x10(%ebp)
  107889:	75 35                	jne    1078c0 <__udivdi3+0x50>
  10788b:	39 fe                	cmp    %edi,%esi
  10788d:	77 61                	ja     1078f0 <__udivdi3+0x80>
  10788f:	85 f6                	test   %esi,%esi
  107891:	75 0b                	jne    10789e <__udivdi3+0x2e>
  107893:	b8 01 00 00 00       	mov    $0x1,%eax
  107898:	31 d2                	xor    %edx,%edx
  10789a:	f7 f6                	div    %esi
  10789c:	89 c6                	mov    %eax,%esi
  10789e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1078a1:	31 d2                	xor    %edx,%edx
  1078a3:	89 f8                	mov    %edi,%eax
  1078a5:	f7 f6                	div    %esi
  1078a7:	89 c7                	mov    %eax,%edi
  1078a9:	89 c8                	mov    %ecx,%eax
  1078ab:	f7 f6                	div    %esi
  1078ad:	89 c1                	mov    %eax,%ecx
  1078af:	89 fa                	mov    %edi,%edx
  1078b1:	89 c8                	mov    %ecx,%eax
  1078b3:	83 c4 10             	add    $0x10,%esp
  1078b6:	5e                   	pop    %esi
  1078b7:	5f                   	pop    %edi
  1078b8:	5d                   	pop    %ebp
  1078b9:	c3                   	ret    
  1078ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1078c0:	39 f8                	cmp    %edi,%eax
  1078c2:	77 1c                	ja     1078e0 <__udivdi3+0x70>
  1078c4:	0f bd d0             	bsr    %eax,%edx
  1078c7:	83 f2 1f             	xor    $0x1f,%edx
  1078ca:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1078cd:	75 39                	jne    107908 <__udivdi3+0x98>
  1078cf:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  1078d2:	0f 86 a0 00 00 00    	jbe    107978 <__udivdi3+0x108>
  1078d8:	39 f8                	cmp    %edi,%eax
  1078da:	0f 82 98 00 00 00    	jb     107978 <__udivdi3+0x108>
  1078e0:	31 ff                	xor    %edi,%edi
  1078e2:	31 c9                	xor    %ecx,%ecx
  1078e4:	89 c8                	mov    %ecx,%eax
  1078e6:	89 fa                	mov    %edi,%edx
  1078e8:	83 c4 10             	add    $0x10,%esp
  1078eb:	5e                   	pop    %esi
  1078ec:	5f                   	pop    %edi
  1078ed:	5d                   	pop    %ebp
  1078ee:	c3                   	ret    
  1078ef:	90                   	nop
  1078f0:	89 d1                	mov    %edx,%ecx
  1078f2:	89 fa                	mov    %edi,%edx
  1078f4:	89 c8                	mov    %ecx,%eax
  1078f6:	31 ff                	xor    %edi,%edi
  1078f8:	f7 f6                	div    %esi
  1078fa:	89 c1                	mov    %eax,%ecx
  1078fc:	89 fa                	mov    %edi,%edx
  1078fe:	89 c8                	mov    %ecx,%eax
  107900:	83 c4 10             	add    $0x10,%esp
  107903:	5e                   	pop    %esi
  107904:	5f                   	pop    %edi
  107905:	5d                   	pop    %ebp
  107906:	c3                   	ret    
  107907:	90                   	nop
  107908:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10790c:	89 f2                	mov    %esi,%edx
  10790e:	d3 e0                	shl    %cl,%eax
  107910:	89 45 ec             	mov    %eax,-0x14(%ebp)
  107913:	b8 20 00 00 00       	mov    $0x20,%eax
  107918:	2b 45 f4             	sub    -0xc(%ebp),%eax
  10791b:	89 c1                	mov    %eax,%ecx
  10791d:	d3 ea                	shr    %cl,%edx
  10791f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  107923:	0b 55 ec             	or     -0x14(%ebp),%edx
  107926:	d3 e6                	shl    %cl,%esi
  107928:	89 c1                	mov    %eax,%ecx
  10792a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  10792d:	89 fe                	mov    %edi,%esi
  10792f:	d3 ee                	shr    %cl,%esi
  107931:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  107935:	89 55 ec             	mov    %edx,-0x14(%ebp)
  107938:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10793b:	d3 e7                	shl    %cl,%edi
  10793d:	89 c1                	mov    %eax,%ecx
  10793f:	d3 ea                	shr    %cl,%edx
  107941:	09 d7                	or     %edx,%edi
  107943:	89 f2                	mov    %esi,%edx
  107945:	89 f8                	mov    %edi,%eax
  107947:	f7 75 ec             	divl   -0x14(%ebp)
  10794a:	89 d6                	mov    %edx,%esi
  10794c:	89 c7                	mov    %eax,%edi
  10794e:	f7 65 e8             	mull   -0x18(%ebp)
  107951:	39 d6                	cmp    %edx,%esi
  107953:	89 55 ec             	mov    %edx,-0x14(%ebp)
  107956:	72 30                	jb     107988 <__udivdi3+0x118>
  107958:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10795b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10795f:	d3 e2                	shl    %cl,%edx
  107961:	39 c2                	cmp    %eax,%edx
  107963:	73 05                	jae    10796a <__udivdi3+0xfa>
  107965:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  107968:	74 1e                	je     107988 <__udivdi3+0x118>
  10796a:	89 f9                	mov    %edi,%ecx
  10796c:	31 ff                	xor    %edi,%edi
  10796e:	e9 71 ff ff ff       	jmp    1078e4 <__udivdi3+0x74>
  107973:	90                   	nop
  107974:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  107978:	31 ff                	xor    %edi,%edi
  10797a:	b9 01 00 00 00       	mov    $0x1,%ecx
  10797f:	e9 60 ff ff ff       	jmp    1078e4 <__udivdi3+0x74>
  107984:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  107988:	8d 4f ff             	lea    -0x1(%edi),%ecx
  10798b:	31 ff                	xor    %edi,%edi
  10798d:	89 c8                	mov    %ecx,%eax
  10798f:	89 fa                	mov    %edi,%edx
  107991:	83 c4 10             	add    $0x10,%esp
  107994:	5e                   	pop    %esi
  107995:	5f                   	pop    %edi
  107996:	5d                   	pop    %ebp
  107997:	c3                   	ret    
  107998:	66 90                	xchg   %ax,%ax
  10799a:	66 90                	xchg   %ax,%ax
  10799c:	66 90                	xchg   %ax,%ax
  10799e:	66 90                	xchg   %ax,%ax

001079a0 <__umoddi3>:
  1079a0:	55                   	push   %ebp
  1079a1:	89 e5                	mov    %esp,%ebp
  1079a3:	57                   	push   %edi
  1079a4:	56                   	push   %esi
  1079a5:	83 ec 20             	sub    $0x20,%esp
  1079a8:	8b 55 14             	mov    0x14(%ebp),%edx
  1079ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1079ae:	8b 7d 10             	mov    0x10(%ebp),%edi
  1079b1:	8b 75 0c             	mov    0xc(%ebp),%esi
  1079b4:	85 d2                	test   %edx,%edx
  1079b6:	89 c8                	mov    %ecx,%eax
  1079b8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  1079bb:	75 13                	jne    1079d0 <__umoddi3+0x30>
  1079bd:	39 f7                	cmp    %esi,%edi
  1079bf:	76 3f                	jbe    107a00 <__umoddi3+0x60>
  1079c1:	89 f2                	mov    %esi,%edx
  1079c3:	f7 f7                	div    %edi
  1079c5:	89 d0                	mov    %edx,%eax
  1079c7:	31 d2                	xor    %edx,%edx
  1079c9:	83 c4 20             	add    $0x20,%esp
  1079cc:	5e                   	pop    %esi
  1079cd:	5f                   	pop    %edi
  1079ce:	5d                   	pop    %ebp
  1079cf:	c3                   	ret    
  1079d0:	39 f2                	cmp    %esi,%edx
  1079d2:	77 4c                	ja     107a20 <__umoddi3+0x80>
  1079d4:	0f bd ca             	bsr    %edx,%ecx
  1079d7:	83 f1 1f             	xor    $0x1f,%ecx
  1079da:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  1079dd:	75 51                	jne    107a30 <__umoddi3+0x90>
  1079df:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  1079e2:	0f 87 e0 00 00 00    	ja     107ac8 <__umoddi3+0x128>
  1079e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1079eb:	29 f8                	sub    %edi,%eax
  1079ed:	19 d6                	sbb    %edx,%esi
  1079ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1079f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1079f5:	89 f2                	mov    %esi,%edx
  1079f7:	83 c4 20             	add    $0x20,%esp
  1079fa:	5e                   	pop    %esi
  1079fb:	5f                   	pop    %edi
  1079fc:	5d                   	pop    %ebp
  1079fd:	c3                   	ret    
  1079fe:	66 90                	xchg   %ax,%ax
  107a00:	85 ff                	test   %edi,%edi
  107a02:	75 0b                	jne    107a0f <__umoddi3+0x6f>
  107a04:	b8 01 00 00 00       	mov    $0x1,%eax
  107a09:	31 d2                	xor    %edx,%edx
  107a0b:	f7 f7                	div    %edi
  107a0d:	89 c7                	mov    %eax,%edi
  107a0f:	89 f0                	mov    %esi,%eax
  107a11:	31 d2                	xor    %edx,%edx
  107a13:	f7 f7                	div    %edi
  107a15:	8b 45 f4             	mov    -0xc(%ebp),%eax
  107a18:	f7 f7                	div    %edi
  107a1a:	eb a9                	jmp    1079c5 <__umoddi3+0x25>
  107a1c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  107a20:	89 c8                	mov    %ecx,%eax
  107a22:	89 f2                	mov    %esi,%edx
  107a24:	83 c4 20             	add    $0x20,%esp
  107a27:	5e                   	pop    %esi
  107a28:	5f                   	pop    %edi
  107a29:	5d                   	pop    %ebp
  107a2a:	c3                   	ret    
  107a2b:	90                   	nop
  107a2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  107a30:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  107a34:	d3 e2                	shl    %cl,%edx
  107a36:	89 55 f4             	mov    %edx,-0xc(%ebp)
  107a39:	ba 20 00 00 00       	mov    $0x20,%edx
  107a3e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  107a41:	89 55 ec             	mov    %edx,-0x14(%ebp)
  107a44:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  107a48:	89 fa                	mov    %edi,%edx
  107a4a:	d3 ea                	shr    %cl,%edx
  107a4c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  107a50:	0b 55 f4             	or     -0xc(%ebp),%edx
  107a53:	d3 e7                	shl    %cl,%edi
  107a55:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  107a59:	89 55 f4             	mov    %edx,-0xc(%ebp)
  107a5c:	89 f2                	mov    %esi,%edx
  107a5e:	89 7d e8             	mov    %edi,-0x18(%ebp)
  107a61:	89 c7                	mov    %eax,%edi
  107a63:	d3 ea                	shr    %cl,%edx
  107a65:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  107a69:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  107a6c:	89 c2                	mov    %eax,%edx
  107a6e:	d3 e6                	shl    %cl,%esi
  107a70:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  107a74:	d3 ea                	shr    %cl,%edx
  107a76:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  107a7a:	09 d6                	or     %edx,%esi
  107a7c:	89 f0                	mov    %esi,%eax
  107a7e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  107a81:	d3 e7                	shl    %cl,%edi
  107a83:	89 f2                	mov    %esi,%edx
  107a85:	f7 75 f4             	divl   -0xc(%ebp)
  107a88:	89 d6                	mov    %edx,%esi
  107a8a:	f7 65 e8             	mull   -0x18(%ebp)
  107a8d:	39 d6                	cmp    %edx,%esi
  107a8f:	72 2b                	jb     107abc <__umoddi3+0x11c>
  107a91:	39 c7                	cmp    %eax,%edi
  107a93:	72 23                	jb     107ab8 <__umoddi3+0x118>
  107a95:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  107a99:	29 c7                	sub    %eax,%edi
  107a9b:	19 d6                	sbb    %edx,%esi
  107a9d:	89 f0                	mov    %esi,%eax
  107a9f:	89 f2                	mov    %esi,%edx
  107aa1:	d3 ef                	shr    %cl,%edi
  107aa3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  107aa7:	d3 e0                	shl    %cl,%eax
  107aa9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  107aad:	09 f8                	or     %edi,%eax
  107aaf:	d3 ea                	shr    %cl,%edx
  107ab1:	83 c4 20             	add    $0x20,%esp
  107ab4:	5e                   	pop    %esi
  107ab5:	5f                   	pop    %edi
  107ab6:	5d                   	pop    %ebp
  107ab7:	c3                   	ret    
  107ab8:	39 d6                	cmp    %edx,%esi
  107aba:	75 d9                	jne    107a95 <__umoddi3+0xf5>
  107abc:	2b 45 e8             	sub    -0x18(%ebp),%eax
  107abf:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  107ac2:	eb d1                	jmp    107a95 <__umoddi3+0xf5>
  107ac4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  107ac8:	39 f2                	cmp    %esi,%edx
  107aca:	0f 82 18 ff ff ff    	jb     1079e8 <__umoddi3+0x48>
  107ad0:	e9 1d ff ff ff       	jmp    1079f2 <__umoddi3+0x52>
