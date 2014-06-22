
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
  10001a:	bc b4 bf 10 00       	mov    $0x10bfb4,%esp

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
  100050:	c7 44 24 0c c0 81 10 	movl   $0x1081c0,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 d6 81 10 	movl   $0x1081d6,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 eb 81 10 00 	movl   $0x1081eb,(%esp)
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
  100084:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
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
  1000a1:	ba 08 20 32 00       	mov    $0x322008,%edx
  1000a6:	b8 34 85 11 00       	mov    $0x118534,%eax
  1000ab:	89 d1                	mov    %edx,%ecx
  1000ad:	29 c1                	sub    %eax,%ecx
  1000af:	89 c8                	mov    %ecx,%eax
  1000b1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bc:	00 
  1000bd:	c7 04 24 34 85 11 00 	movl   $0x118534,(%esp)
  1000c4:	e8 7b 7c 00 00       	call   107d44 <memset>
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
  1000eb:	e8 79 3c 00 00       	call   103d69 <pmap_init>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000f0:	e8 ec 1f 00 00       	call   1020e1 <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000f5:	e8 52 6b 00 00       	call   106c4c <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000fa:	e8 80 71 00 00       	call   10727f <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000ff:	e8 2b 6e 00 00       	call   106f2f <lapic_init>
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
  100117:	bb f8 81 10 00       	mov    $0x1081f8,%ebx
  10011c:	eb 05                	jmp    100123 <init+0x92>
  10011e:	bb fb 81 10 00       	mov    $0x1081fb,%ebx
  100123:	e8 fe fe ff ff       	call   100026 <cpu_cur>
  100128:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10012f:	0f b6 c0             	movzbl %al,%eax
  100132:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  100136:	89 44 24 04          	mov    %eax,0x4(%esp)
  10013a:	c7 04 24 fe 81 10 00 	movl   $0x1081fe,(%esp)
  100141:	e8 19 7a 00 00       	call   107b5f <cprintf>
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
  100157:	c7 04 24 80 ed 31 00 	movl   $0x31ed80,(%esp)
  10015e:	e8 77 29 00 00       	call   102ada <proc_alloc>
  100163:	a3 84 f4 31 00       	mov    %eax,0x31f484
		proc_root->sv.tf.eip = (uint32_t)(user);
  100168:	a1 84 f4 31 00       	mov    0x31f484,%eax
  10016d:	ba c5 01 10 00       	mov    $0x1001c5,%edx
  100172:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_root->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
  100178:	a1 84 f4 31 00       	mov    0x31f484,%eax
  10017d:	ba 00 a0 11 00       	mov    $0x11a000,%edx
  100182:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		//proc_root->sv.tf.eflags = FL_IOPL_3;
		proc_root->sv.tf.eflags = FL_IF;
  100188:	a1 84 f4 31 00       	mov    0x31f484,%eax
  10018d:	c7 80 90 04 00 00 00 	movl   $0x200,0x490(%eax)
  100194:	02 00 00 
		proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
  100197:	a1 84 f4 31 00       	mov    0x31f484,%eax
  10019c:	66 c7 80 70 04 00 00 	movw   $0x23,0x470(%eax)
  1001a3:	23 00 
		proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;
  1001a5:	a1 84 f4 31 00       	mov    0x31f484,%eax
  1001aa:	66 c7 80 74 04 00 00 	movw   $0x23,0x474(%eax)
  1001b1:	23 00 

		proc_ready(proc_root);	
  1001b3:	a1 84 f4 31 00       	mov    0x31f484,%eax
  1001b8:	89 04 24             	mov    %eax,(%esp)
  1001bb:	e8 10 2b 00 00       	call   102cd0 <proc_ready>
	}

	
	proc_sched();
  1001c0:	e8 63 2d 00 00       	call   102f28 <proc_sched>

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
  1001cb:	c7 04 24 16 82 10 00 	movl   $0x108216,(%esp)
  1001d2:	e8 88 79 00 00       	call   107b5f <cprintf>

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
  1001df:	b8 00 90 11 00       	mov    $0x119000,%eax
  1001e4:	39 c2                	cmp    %eax,%edx
  1001e6:	77 24                	ja     10020c <user+0x47>
  1001e8:	c7 44 24 0c 24 82 10 	movl   $0x108224,0xc(%esp)
  1001ef:	00 
  1001f0:	c7 44 24 08 d6 81 10 	movl   $0x1081d6,0x8(%esp)
  1001f7:	00 
  1001f8:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  1001ff:	00 
  100200:	c7 04 24 4b 82 10 00 	movl   $0x10824b,(%esp)
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
  100214:	b8 00 a0 11 00       	mov    $0x11a000,%eax
  100219:	39 c2                	cmp    %eax,%edx
  10021b:	72 24                	jb     100241 <user+0x7c>
  10021d:	c7 44 24 0c 58 82 10 	movl   $0x108258,0xc(%esp)
  100224:	00 
  100225:	c7 44 24 08 d6 81 10 	movl   $0x1081d6,0x8(%esp)
  10022c:	00 
  10022d:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  100234:	00 
  100235:	c7 04 24 4b 82 10 00 	movl   $0x10824b,(%esp)
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
  100275:	c7 44 24 0c 90 82 10 	movl   $0x108290,0xc(%esp)
  10027c:	00 
  10027d:	c7 44 24 08 a6 82 10 	movl   $0x1082a6,0x8(%esp)
  100284:	00 
  100285:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10028c:	00 
  10028d:	c7 04 24 bb 82 10 00 	movl   $0x1082bb,(%esp)
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
  1002a9:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
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
  1002bc:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  1002c3:	e8 45 20 00 00       	call   10230d <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  1002c8:	eb 35                	jmp    1002ff <cons_intr+0x49>
		if (c == 0)
  1002ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1002ce:	74 2e                	je     1002fe <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  1002d0:	a1 04 a2 11 00       	mov    0x11a204,%eax
  1002d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1002d8:	88 90 00 a0 11 00    	mov    %dl,0x11a000(%eax)
  1002de:	83 c0 01             	add    $0x1,%eax
  1002e1:	a3 04 a2 11 00       	mov    %eax,0x11a204
		if (cons.wpos == CONSBUFSIZE)
  1002e6:	a1 04 a2 11 00       	mov    0x11a204,%eax
  1002eb:	3d 00 02 00 00       	cmp    $0x200,%eax
  1002f0:	75 0d                	jne    1002ff <cons_intr+0x49>
			cons.wpos = 0;
  1002f2:	c7 05 04 a2 11 00 00 	movl   $0x0,0x11a204
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
  10030d:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
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
  100321:	e8 d6 67 00 00       	call   106afc <serial_intr>
	kbd_intr();
  100326:	e8 2c 67 00 00       	call   106a57 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  10032b:	8b 15 00 a2 11 00    	mov    0x11a200,%edx
  100331:	a1 04 a2 11 00       	mov    0x11a204,%eax
  100336:	39 c2                	cmp    %eax,%edx
  100338:	74 35                	je     10036f <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  10033a:	a1 00 a2 11 00       	mov    0x11a200,%eax
  10033f:	0f b6 90 00 a0 11 00 	movzbl 0x11a000(%eax),%edx
  100346:	0f b6 d2             	movzbl %dl,%edx
  100349:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10034c:	83 c0 01             	add    $0x1,%eax
  10034f:	a3 00 a2 11 00       	mov    %eax,0x11a200
		if (cons.rpos == CONSBUFSIZE)
  100354:	a1 00 a2 11 00       	mov    0x11a200,%eax
  100359:	3d 00 02 00 00       	cmp    $0x200,%eax
  10035e:	75 0a                	jne    10036a <cons_getc+0x4f>
			cons.rpos = 0;
  100360:	c7 05 00 a2 11 00 00 	movl   $0x0,0x11a200
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
  100382:	e8 92 67 00 00       	call   106b19 <serial_putc>
	video_putc(c);
  100387:	8b 45 08             	mov    0x8(%ebp),%eax
  10038a:	89 04 24             	mov    %eax,(%esp)
  10038d:	e8 24 63 00 00       	call   1066b6 <video_putc>
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
  1003ab:	c7 44 24 04 c8 82 10 	movl   $0x1082c8,0x4(%esp)
  1003b2:	00 
  1003b3:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  1003ba:	e8 1a 1f 00 00       	call   1022d9 <spinlock_init_>
	video_init();
  1003bf:	e8 26 62 00 00       	call   1065ea <video_init>
	kbd_init();
  1003c4:	e8 a2 66 00 00       	call   106a6b <kbd_init>
	serial_init();
  1003c9:	e8 b0 67 00 00       	call   106b7e <serial_init>

	if (!serial_exists)
  1003ce:	a1 00 20 32 00       	mov    0x322000,%eax
  1003d3:	85 c0                	test   %eax,%eax
  1003d5:	75 1f                	jne    1003f6 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  1003d7:	c7 44 24 08 d4 82 10 	movl   $0x1082d4,0x8(%esp)
  1003de:	00 
  1003df:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  1003e6:	00 
  1003e7:	c7 04 24 c8 82 10 00 	movl   $0x1082c8,(%esp)
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
  100424:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  10042b:	e8 a4 1f 00 00       	call   1023d4 <spinlock_holding>
  100430:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!already)
  100433:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100437:	75 25                	jne    10045e <cputs+0x66>
		spinlock_acquire(&cons_lock);
  100439:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
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
  10046f:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
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
  100498:	a1 08 a2 11 00       	mov    0x11a208,%eax
  10049d:	85 c0                	test   %eax,%eax
  10049f:	0f 85 95 00 00 00    	jne    10053a <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  1004a5:	8b 45 10             	mov    0x10(%ebp),%eax
  1004a8:	a3 08 a2 11 00       	mov    %eax,0x11a208
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
  1004c4:	c7 04 24 f1 82 10 00 	movl   $0x1082f1,(%esp)
  1004cb:	e8 8f 76 00 00       	call   107b5f <cprintf>
	vcprintf(fmt, ap);
  1004d0:	8b 45 10             	mov    0x10(%ebp),%eax
  1004d3:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1004d6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1004da:	89 04 24             	mov    %eax,(%esp)
  1004dd:	e8 14 76 00 00       	call   107af6 <vcprintf>
	cprintf("\n");
  1004e2:	c7 04 24 09 83 10 00 	movl   $0x108309,(%esp)
  1004e9:	e8 71 76 00 00       	call   107b5f <cprintf>

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
  100517:	c7 04 24 0b 83 10 00 	movl   $0x10830b,(%esp)
  10051e:	e8 3c 76 00 00       	call   107b5f <cprintf>
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
  10055d:	c7 04 24 18 83 10 00 	movl   $0x108318,(%esp)
  100564:	e8 f6 75 00 00       	call   107b5f <cprintf>
	vcprintf(fmt, ap);
  100569:	8b 45 10             	mov    0x10(%ebp),%eax
  10056c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10056f:	89 54 24 04          	mov    %edx,0x4(%esp)
  100573:	89 04 24             	mov    %eax,(%esp)
  100576:	e8 7b 75 00 00       	call   107af6 <vcprintf>
	cprintf("\n");
  10057b:	c7 04 24 09 83 10 00 	movl   $0x108309,(%esp)
  100582:	e8 d8 75 00 00       	call   107b5f <cprintf>
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
  100709:	c7 44 24 0c 32 83 10 	movl   $0x108332,0xc(%esp)
  100710:	00 
  100711:	c7 44 24 08 4f 83 10 	movl   $0x10834f,0x8(%esp)
  100718:	00 
  100719:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100720:	00 
  100721:	c7 04 24 64 83 10 00 	movl   $0x108364,(%esp)
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
  100759:	c7 44 24 0c 71 83 10 	movl   $0x108371,0xc(%esp)
  100760:	00 
  100761:	c7 44 24 08 4f 83 10 	movl   $0x10834f,0x8(%esp)
  100768:	00 
  100769:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  100770:	00 
  100771:	c7 04 24 64 83 10 00 	movl   $0x108364,(%esp)
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
  1007a9:	c7 44 24 0c 8a 83 10 	movl   $0x10838a,0xc(%esp)
  1007b0:	00 
  1007b1:	c7 44 24 08 4f 83 10 	movl   $0x10834f,0x8(%esp)
  1007b8:	00 
  1007b9:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  1007c0:	00 
  1007c1:	c7 04 24 64 83 10 00 	movl   $0x108364,(%esp)
  1007c8:	e8 b4 fc ff ff       	call   100481 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1007cd:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1007d0:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1007d3:	39 c2                	cmp    %eax,%edx
  1007d5:	74 24                	je     1007fb <debug_check+0x175>
  1007d7:	c7 44 24 0c a3 83 10 	movl   $0x1083a3,0xc(%esp)
  1007de:	00 
  1007df:	c7 44 24 08 4f 83 10 	movl   $0x10834f,0x8(%esp)
  1007e6:	00 
  1007e7:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  1007ee:	00 
  1007ef:	c7 04 24 64 83 10 00 	movl   $0x108364,(%esp)
  1007f6:	e8 86 fc ff ff       	call   100481 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  1007fb:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100801:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100804:	39 c2                	cmp    %eax,%edx
  100806:	75 24                	jne    10082c <debug_check+0x1a6>
  100808:	c7 44 24 0c bc 83 10 	movl   $0x1083bc,0xc(%esp)
  10080f:	00 
  100810:	c7 44 24 08 4f 83 10 	movl   $0x10834f,0x8(%esp)
  100817:	00 
  100818:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  10081f:	00 
  100820:	c7 04 24 64 83 10 00 	movl   $0x108364,(%esp)
  100827:	e8 55 fc ff ff       	call   100481 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10082c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100832:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100835:	39 c2                	cmp    %eax,%edx
  100837:	74 24                	je     10085d <debug_check+0x1d7>
  100839:	c7 44 24 0c d5 83 10 	movl   $0x1083d5,0xc(%esp)
  100840:	00 
  100841:	c7 44 24 08 4f 83 10 	movl   $0x10834f,0x8(%esp)
  100848:	00 
  100849:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100850:	00 
  100851:	c7 04 24 64 83 10 00 	movl   $0x108364,(%esp)
  100858:	e8 24 fc ff ff       	call   100481 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10085d:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100863:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100866:	39 c2                	cmp    %eax,%edx
  100868:	74 24                	je     10088e <debug_check+0x208>
  10086a:	c7 44 24 0c ee 83 10 	movl   $0x1083ee,0xc(%esp)
  100871:	00 
  100872:	c7 44 24 08 4f 83 10 	movl   $0x10834f,0x8(%esp)
  100879:	00 
  10087a:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100881:	00 
  100882:	c7 04 24 64 83 10 00 	movl   $0x108364,(%esp)
  100889:	e8 f3 fb ff ff       	call   100481 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10088e:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100894:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  10089a:	39 c2                	cmp    %eax,%edx
  10089c:	75 24                	jne    1008c2 <debug_check+0x23c>
  10089e:	c7 44 24 0c 07 84 10 	movl   $0x108407,0xc(%esp)
  1008a5:	00 
  1008a6:	c7 44 24 08 4f 83 10 	movl   $0x10834f,0x8(%esp)
  1008ad:	00 
  1008ae:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  1008b5:	00 
  1008b6:	c7 04 24 64 83 10 00 	movl   $0x108364,(%esp)
  1008bd:	e8 bf fb ff ff       	call   100481 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1008c2:	c7 04 24 20 84 10 00 	movl   $0x108420,(%esp)
  1008c9:	e8 91 72 00 00       	call   107b5f <cprintf>
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
  1008fa:	c7 44 24 0c 3c 84 10 	movl   $0x10843c,0xc(%esp)
  100901:	00 
  100902:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100909:	00 
  10090a:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100911:	00 
  100912:	c7 04 24 67 84 10 00 	movl   $0x108467,(%esp)
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
  10092e:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
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
  100956:	c7 44 24 04 74 84 10 	movl   $0x108474,0x4(%esp)
  10095d:	00 
  10095e:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
  100965:	e8 6f 19 00 00       	call   1022d9 <spinlock_init_>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  10096a:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100971:	e8 df 64 00 00       	call   106e55 <nvram_read16>
  100976:	c1 e0 0a             	shl    $0xa,%eax
  100979:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10097c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10097f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100984:	89 45 dc             	mov    %eax,-0x24(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100987:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  10098e:	e8 c2 64 00 00       	call   106e55 <nvram_read16>
  100993:	c1 e0 0a             	shl    $0xa,%eax
  100996:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100999:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10099c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1009a1:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  1009a4:	c7 44 24 08 80 84 10 	movl   $0x108480,0x8(%esp)
  1009ab:	00 
  1009ac:	c7 44 24 04 39 00 00 	movl   $0x39,0x4(%esp)
  1009b3:	00 
  1009b4:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  1009bb:	e8 80 fb ff ff       	call   100540 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1009c0:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1009c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009ca:	05 00 00 10 00       	add    $0x100000,%eax
  1009cf:	a3 08 ed 11 00       	mov    %eax,0x11ed08

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1009d4:	a1 08 ed 11 00       	mov    0x11ed08,%eax
  1009d9:	c1 e8 0c             	shr    $0xc,%eax
  1009dc:	a3 04 ed 11 00       	mov    %eax,0x11ed04

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  1009e1:	a1 08 ed 11 00       	mov    0x11ed08,%eax
  1009e6:	c1 e8 0a             	shr    $0xa,%eax
  1009e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009ed:	c7 04 24 a0 84 10 00 	movl   $0x1084a0,(%esp)
  1009f4:	e8 66 71 00 00       	call   107b5f <cprintf>
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
  100a0f:	c7 04 24 c1 84 10 00 	movl   $0x1084c1,(%esp)
  100a16:	e8 44 71 00 00       	call   107b5f <cprintf>


	extern char start[], end[];
	uint32_t page_start;
	
	pageinfo **freetail = &mem_freelist;
  100a1b:	c7 45 e8 00 ed 11 00 	movl   $0x11ed00,-0x18(%ebp)
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100a22:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100a29:	00 
  100a2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100a31:	00 
  100a32:	c7 04 24 20 ed 11 00 	movl   $0x11ed20,(%esp)
  100a39:	e8 06 73 00 00       	call   107d44 <memset>
	mem_pageinfo = spc_for_pi;
  100a3e:	c7 05 58 ed 31 00 20 	movl   $0x11ed20,0x31ed58
  100a45:	ed 11 00 
	int i;
	for (i = 0; i < mem_npage; i++) {
  100a48:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100a4f:	e9 96 00 00 00       	jmp    100aea <mem_init+0x1af>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100a54:	a1 58 ed 31 00       	mov    0x31ed58,%eax
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
  100aad:	b8 08 20 32 00       	mov    $0x322008,%eax
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
  100ab7:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  100abc:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100abf:	c1 e2 03             	shl    $0x3,%edx
  100ac2:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100ac5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ac8:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100aca:	a1 58 ed 31 00       	mov    0x31ed58,%eax
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
  100aed:	a1 04 ed 11 00       	mov    0x11ed04,%eax
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
  100b13:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  100b18:	85 c0                	test   %eax,%eax
  100b1a:	75 07                	jne    100b23 <mem_alloc+0x16>
		return NULL;
  100b1c:	b8 00 00 00 00       	mov    $0x0,%eax
  100b21:	eb 2f                	jmp    100b52 <mem_alloc+0x45>

	spinlock_acquire(&mem_spinlock);
  100b23:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
  100b2a:	e8 de 17 00 00       	call   10230d <spinlock_acquire>
	pageinfo* r = mem_freelist;
  100b2f:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  100b34:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = mem_freelist->free_next;
  100b37:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  100b3c:	8b 00                	mov    (%eax),%eax
  100b3e:	a3 00 ed 11 00       	mov    %eax,0x11ed00
	spinlock_release(&mem_spinlock);
  100b43:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
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
  100b60:	c7 44 24 08 e0 84 10 	movl   $0x1084e0,0x8(%esp)
  100b67:	00 
  100b68:	c7 44 24 04 ab 00 00 	movl   $0xab,0x4(%esp)
  100b6f:	00 
  100b70:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100b77:	e8 05 f9 ff ff       	call   100481 <debug_panic>

	spinlock_acquire(&mem_spinlock);
  100b7c:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
  100b83:	e8 85 17 00 00       	call   10230d <spinlock_acquire>
	pi->free_next = mem_freelist;
  100b88:	8b 15 00 ed 11 00    	mov    0x11ed00,%edx
  100b8e:	8b 45 08             	mov    0x8(%ebp),%eax
  100b91:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100b93:	8b 45 08             	mov    0x8(%ebp),%eax
  100b96:	a3 00 ed 11 00       	mov    %eax,0x11ed00
	spinlock_release(&mem_spinlock);
  100b9b:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
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
  100bb6:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  100bbb:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100bbe:	eb 38                	jmp    100bf8 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100bc0:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100bc3:	a1 58 ed 31 00       	mov    0x31ed58,%eax
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
  100be7:	e8 58 71 00 00       	call   107d44 <memset>
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
  100c05:	c7 04 24 01 85 10 00 	movl   $0x108501,(%esp)
  100c0c:	e8 4e 6f 00 00       	call   107b5f <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100c11:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c14:	a1 04 ed 11 00       	mov    0x11ed04,%eax
  100c19:	39 c2                	cmp    %eax,%edx
  100c1b:	72 24                	jb     100c41 <mem_check+0x98>
  100c1d:	c7 44 24 0c 1b 85 10 	movl   $0x10851b,0xc(%esp)
  100c24:	00 
  100c25:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100c2c:	00 
  100c2d:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100c34:	00 
  100c35:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100c3c:	e8 40 f8 ff ff       	call   100481 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100c41:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100c48:	7f 24                	jg     100c6e <mem_check+0xc5>
  100c4a:	c7 44 24 0c 31 85 10 	movl   $0x108531,0xc(%esp)
  100c51:	00 
  100c52:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100c59:	00 
  100c5a:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  100c61:	00 
  100c62:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
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
  100c8f:	c7 44 24 0c 43 85 10 	movl   $0x108543,0xc(%esp)
  100c96:	00 
  100c97:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100c9e:	00 
  100c9f:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100ca6:	00 
  100ca7:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100cae:	e8 ce f7 ff ff       	call   100481 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100cb3:	e8 55 fe ff ff       	call   100b0d <mem_alloc>
  100cb8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100cbb:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100cbf:	75 24                	jne    100ce5 <mem_check+0x13c>
  100cc1:	c7 44 24 0c 4c 85 10 	movl   $0x10854c,0xc(%esp)
  100cc8:	00 
  100cc9:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100cd0:	00 
  100cd1:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100cd8:	00 
  100cd9:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100ce0:	e8 9c f7 ff ff       	call   100481 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100ce5:	e8 23 fe ff ff       	call   100b0d <mem_alloc>
  100cea:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100ced:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100cf1:	75 24                	jne    100d17 <mem_check+0x16e>
  100cf3:	c7 44 24 0c 55 85 10 	movl   $0x108555,0xc(%esp)
  100cfa:	00 
  100cfb:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100d02:	00 
  100d03:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  100d0a:	00 
  100d0b:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100d12:	e8 6a f7 ff ff       	call   100481 <debug_panic>

	assert(pp0);
  100d17:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100d1b:	75 24                	jne    100d41 <mem_check+0x198>
  100d1d:	c7 44 24 0c 5e 85 10 	movl   $0x10855e,0xc(%esp)
  100d24:	00 
  100d25:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100d2c:	00 
  100d2d:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100d34:	00 
  100d35:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100d3c:	e8 40 f7 ff ff       	call   100481 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100d41:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d45:	74 08                	je     100d4f <mem_check+0x1a6>
  100d47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d4a:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d4d:	75 24                	jne    100d73 <mem_check+0x1ca>
  100d4f:	c7 44 24 0c 62 85 10 	movl   $0x108562,0xc(%esp)
  100d56:	00 
  100d57:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100d5e:	00 
  100d5f:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100d66:	00 
  100d67:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
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
  100d89:	c7 44 24 0c 74 85 10 	movl   $0x108574,0xc(%esp)
  100d90:	00 
  100d91:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100d98:	00 
  100d99:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  100da0:	00 
  100da1:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100da8:	e8 d4 f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100dad:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100db0:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  100db5:	89 d1                	mov    %edx,%ecx
  100db7:	29 c1                	sub    %eax,%ecx
  100db9:	89 c8                	mov    %ecx,%eax
  100dbb:	c1 f8 03             	sar    $0x3,%eax
  100dbe:	c1 e0 0c             	shl    $0xc,%eax
  100dc1:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  100dc7:	c1 e2 0c             	shl    $0xc,%edx
  100dca:	39 d0                	cmp    %edx,%eax
  100dcc:	72 24                	jb     100df2 <mem_check+0x249>
  100dce:	c7 44 24 0c 94 85 10 	movl   $0x108594,0xc(%esp)
  100dd5:	00 
  100dd6:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100ddd:	00 
  100dde:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  100de5:	00 
  100de6:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100ded:	e8 8f f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100df2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100df5:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  100dfa:	89 d1                	mov    %edx,%ecx
  100dfc:	29 c1                	sub    %eax,%ecx
  100dfe:	89 c8                	mov    %ecx,%eax
  100e00:	c1 f8 03             	sar    $0x3,%eax
  100e03:	c1 e0 0c             	shl    $0xc,%eax
  100e06:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  100e0c:	c1 e2 0c             	shl    $0xc,%edx
  100e0f:	39 d0                	cmp    %edx,%eax
  100e11:	72 24                	jb     100e37 <mem_check+0x28e>
  100e13:	c7 44 24 0c bc 85 10 	movl   $0x1085bc,0xc(%esp)
  100e1a:	00 
  100e1b:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100e22:	00 
  100e23:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  100e2a:	00 
  100e2b:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100e32:	e8 4a f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100e37:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100e3a:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  100e3f:	89 d1                	mov    %edx,%ecx
  100e41:	29 c1                	sub    %eax,%ecx
  100e43:	89 c8                	mov    %ecx,%eax
  100e45:	c1 f8 03             	sar    $0x3,%eax
  100e48:	c1 e0 0c             	shl    $0xc,%eax
  100e4b:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  100e51:	c1 e2 0c             	shl    $0xc,%edx
  100e54:	39 d0                	cmp    %edx,%eax
  100e56:	72 24                	jb     100e7c <mem_check+0x2d3>
  100e58:	c7 44 24 0c e4 85 10 	movl   $0x1085e4,0xc(%esp)
  100e5f:	00 
  100e60:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100e67:	00 
  100e68:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  100e6f:	00 
  100e70:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100e77:	e8 05 f6 ff ff       	call   100481 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100e7c:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  100e81:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100e84:	c7 05 00 ed 11 00 00 	movl   $0x0,0x11ed00
  100e8b:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100e8e:	e8 7a fc ff ff       	call   100b0d <mem_alloc>
  100e93:	85 c0                	test   %eax,%eax
  100e95:	74 24                	je     100ebb <mem_check+0x312>
  100e97:	c7 44 24 0c 0a 86 10 	movl   $0x10860a,0xc(%esp)
  100e9e:	00 
  100e9f:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100ea6:	00 
  100ea7:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  100eae:	00 
  100eaf:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
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
  100efd:	c7 44 24 0c 43 85 10 	movl   $0x108543,0xc(%esp)
  100f04:	00 
  100f05:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100f0c:	00 
  100f0d:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  100f14:	00 
  100f15:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100f1c:	e8 60 f5 ff ff       	call   100481 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100f21:	e8 e7 fb ff ff       	call   100b0d <mem_alloc>
  100f26:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100f29:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100f2d:	75 24                	jne    100f53 <mem_check+0x3aa>
  100f2f:	c7 44 24 0c 4c 85 10 	movl   $0x10854c,0xc(%esp)
  100f36:	00 
  100f37:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100f3e:	00 
  100f3f:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  100f46:	00 
  100f47:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100f4e:	e8 2e f5 ff ff       	call   100481 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100f53:	e8 b5 fb ff ff       	call   100b0d <mem_alloc>
  100f58:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100f5b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f5f:	75 24                	jne    100f85 <mem_check+0x3dc>
  100f61:	c7 44 24 0c 55 85 10 	movl   $0x108555,0xc(%esp)
  100f68:	00 
  100f69:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100f70:	00 
  100f71:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  100f78:	00 
  100f79:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100f80:	e8 fc f4 ff ff       	call   100481 <debug_panic>
	assert(pp0);
  100f85:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100f89:	75 24                	jne    100faf <mem_check+0x406>
  100f8b:	c7 44 24 0c 5e 85 10 	movl   $0x10855e,0xc(%esp)
  100f92:	00 
  100f93:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100f9a:	00 
  100f9b:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  100fa2:	00 
  100fa3:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  100faa:	e8 d2 f4 ff ff       	call   100481 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100faf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100fb3:	74 08                	je     100fbd <mem_check+0x414>
  100fb5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100fb8:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100fbb:	75 24                	jne    100fe1 <mem_check+0x438>
  100fbd:	c7 44 24 0c 62 85 10 	movl   $0x108562,0xc(%esp)
  100fc4:	00 
  100fc5:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  100fcc:	00 
  100fcd:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  100fd4:	00 
  100fd5:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
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
  100ff7:	c7 44 24 0c 74 85 10 	movl   $0x108574,0xc(%esp)
  100ffe:	00 
  100fff:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  101006:	00 
  101007:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  10100e:	00 
  10100f:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  101016:	e8 66 f4 ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == 0);
  10101b:	e8 ed fa ff ff       	call   100b0d <mem_alloc>
  101020:	85 c0                	test   %eax,%eax
  101022:	74 24                	je     101048 <mem_check+0x49f>
  101024:	c7 44 24 0c 0a 86 10 	movl   $0x10860a,0xc(%esp)
  10102b:	00 
  10102c:	c7 44 24 08 52 84 10 	movl   $0x108452,0x8(%esp)
  101033:	00 
  101034:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  10103b:	00 
  10103c:	c7 04 24 74 84 10 00 	movl   $0x108474,(%esp)
  101043:	e8 39 f4 ff ff       	call   100481 <debug_panic>

	// give free list back
	mem_freelist = fl;
  101048:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10104b:	a3 00 ed 11 00       	mov    %eax,0x11ed00

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
  101071:	c7 04 24 1b 86 10 00 	movl   $0x10861b,(%esp)
  101078:	e8 e2 6a 00 00       	call   107b5f <cprintf>
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
  1010c3:	c7 44 24 0c 33 86 10 	movl   $0x108633,0xc(%esp)
  1010ca:	00 
  1010cb:	c7 44 24 08 49 86 10 	movl   $0x108649,0x8(%esp)
  1010d2:	00 
  1010d3:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1010da:	00 
  1010db:	c7 04 24 5e 86 10 00 	movl   $0x10865e,(%esp)
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
  1010f7:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
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
  101239:	c7 44 24 0c 6b 86 10 	movl   $0x10866b,0xc(%esp)
  101240:	00 
  101241:	c7 44 24 08 49 86 10 	movl   $0x108649,0x8(%esp)
  101248:	00 
  101249:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  101250:	00 
  101251:	c7 04 24 73 86 10 00 	movl   $0x108673,(%esp)
  101258:	e8 24 f2 ff ff       	call   100481 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  10125d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101260:	a1 58 ed 31 00       	mov    0x31ed58,%eax
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
  10128a:	e8 b5 6a 00 00       	call   107d44 <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  10128f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101292:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101299:	00 
  10129a:	c7 44 24 04 00 b0 10 	movl   $0x10b000,0x4(%esp)
  1012a1:	00 
  1012a2:	89 04 24             	mov    %eax,(%esp)
  1012a5:	e8 0e 6b 00 00       	call   107db8 <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  1012aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012ad:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  1012b4:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  1012b7:	a1 00 c0 10 00       	mov    0x10c000,%eax
  1012bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1012bf:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  1012c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012c4:	05 a8 00 00 00       	add    $0xa8,%eax
  1012c9:	a3 00 c0 10 00       	mov    %eax,0x10c000

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
  101311:	c7 44 24 04 ca 84 11 	movl   $0x1184ca,0x4(%esp)
  101318:	00 
  101319:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10131c:	89 04 24             	mov    %eax,(%esp)
  10131f:	e8 94 6a 00 00       	call   107db8 <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  101324:	c7 45 f4 00 b0 10 00 	movl   $0x10b000,-0xc(%ebp)
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
  10136b:	e8 e6 5d 00 00       	call   107156 <lapic_startcpu>

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
  1013be:	c7 44 24 0c 80 86 10 	movl   $0x108680,0xc(%esp)
  1013c5:	00 
  1013c6:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  1013cd:	00 
  1013ce:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1013d5:	00 
  1013d6:	c7 04 24 ab 86 10 00 	movl   $0x1086ab,(%esp)
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
  1013f2:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
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
  101417:	8b 14 95 10 c0 10 00 	mov    0x10c010(,%edx,4),%edx
  10141e:	66 89 14 c5 20 a2 11 	mov    %dx,0x11a220(,%eax,8)
  101425:	00 
  101426:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101429:	66 c7 04 c5 22 a2 11 	movw   $0x8,0x11a222(,%eax,8)
  101430:	00 08 00 
  101433:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101436:	0f b6 14 c5 24 a2 11 	movzbl 0x11a224(,%eax,8),%edx
  10143d:	00 
  10143e:	83 e2 e0             	and    $0xffffffe0,%edx
  101441:	88 14 c5 24 a2 11 00 	mov    %dl,0x11a224(,%eax,8)
  101448:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10144b:	0f b6 14 c5 24 a2 11 	movzbl 0x11a224(,%eax,8),%edx
  101452:	00 
  101453:	83 e2 1f             	and    $0x1f,%edx
  101456:	88 14 c5 24 a2 11 00 	mov    %dl,0x11a224(,%eax,8)
  10145d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101460:	0f b6 14 c5 25 a2 11 	movzbl 0x11a225(,%eax,8),%edx
  101467:	00 
  101468:	83 ca 0f             	or     $0xf,%edx
  10146b:	88 14 c5 25 a2 11 00 	mov    %dl,0x11a225(,%eax,8)
  101472:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101475:	0f b6 14 c5 25 a2 11 	movzbl 0x11a225(,%eax,8),%edx
  10147c:	00 
  10147d:	83 e2 ef             	and    $0xffffffef,%edx
  101480:	88 14 c5 25 a2 11 00 	mov    %dl,0x11a225(,%eax,8)
  101487:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10148a:	0f b6 14 c5 25 a2 11 	movzbl 0x11a225(,%eax,8),%edx
  101491:	00 
  101492:	83 ca 60             	or     $0x60,%edx
  101495:	88 14 c5 25 a2 11 00 	mov    %dl,0x11a225(,%eax,8)
  10149c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10149f:	0f b6 14 c5 25 a2 11 	movzbl 0x11a225(,%eax,8),%edx
  1014a6:	00 
  1014a7:	83 ca 80             	or     $0xffffff80,%edx
  1014aa:	88 14 c5 25 a2 11 00 	mov    %dl,0x11a225(,%eax,8)
  1014b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1014b4:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1014b7:	8b 14 95 10 c0 10 00 	mov    0x10c010(,%edx,4),%edx
  1014be:	c1 ea 10             	shr    $0x10,%edx
  1014c1:	66 89 14 c5 26 a2 11 	mov    %dx,0x11a226(,%eax,8)
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
  1014d7:	a1 88 c0 10 00       	mov    0x10c088,%eax
  1014dc:	66 a3 10 a3 11 00    	mov    %ax,0x11a310
  1014e2:	66 c7 05 12 a3 11 00 	movw   $0x8,0x11a312
  1014e9:	08 00 
  1014eb:	0f b6 05 14 a3 11 00 	movzbl 0x11a314,%eax
  1014f2:	83 e0 e0             	and    $0xffffffe0,%eax
  1014f5:	a2 14 a3 11 00       	mov    %al,0x11a314
  1014fa:	0f b6 05 14 a3 11 00 	movzbl 0x11a314,%eax
  101501:	83 e0 1f             	and    $0x1f,%eax
  101504:	a2 14 a3 11 00       	mov    %al,0x11a314
  101509:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  101510:	83 c8 0f             	or     $0xf,%eax
  101513:	a2 15 a3 11 00       	mov    %al,0x11a315
  101518:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  10151f:	83 e0 ef             	and    $0xffffffef,%eax
  101522:	a2 15 a3 11 00       	mov    %al,0x11a315
  101527:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  10152e:	83 c8 60             	or     $0x60,%eax
  101531:	a2 15 a3 11 00       	mov    %al,0x11a315
  101536:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  10153d:	83 c8 80             	or     $0xffffff80,%eax
  101540:	a2 15 a3 11 00       	mov    %al,0x11a315
  101545:	a1 88 c0 10 00       	mov    0x10c088,%eax
  10154a:	c1 e8 10             	shr    $0x10,%eax
  10154d:	66 a3 16 a3 11 00    	mov    %ax,0x11a316
	SETGATE(idt[T_SYSCALL], 1, CPU_GDT_KCODE, vectors[T_SYSCALL], 3);
  101553:	a1 d0 c0 10 00       	mov    0x10c0d0,%eax
  101558:	66 a3 a0 a3 11 00    	mov    %ax,0x11a3a0
  10155e:	66 c7 05 a2 a3 11 00 	movw   $0x8,0x11a3a2
  101565:	08 00 
  101567:	0f b6 05 a4 a3 11 00 	movzbl 0x11a3a4,%eax
  10156e:	83 e0 e0             	and    $0xffffffe0,%eax
  101571:	a2 a4 a3 11 00       	mov    %al,0x11a3a4
  101576:	0f b6 05 a4 a3 11 00 	movzbl 0x11a3a4,%eax
  10157d:	83 e0 1f             	and    $0x1f,%eax
  101580:	a2 a4 a3 11 00       	mov    %al,0x11a3a4
  101585:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  10158c:	83 c8 0f             	or     $0xf,%eax
  10158f:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  101594:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  10159b:	83 e0 ef             	and    $0xffffffef,%eax
  10159e:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  1015a3:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  1015aa:	83 c8 60             	or     $0x60,%eax
  1015ad:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  1015b2:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  1015b9:	83 c8 80             	or     $0xffffff80,%eax
  1015bc:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  1015c1:	a1 d0 c0 10 00       	mov    0x10c0d0,%eax
  1015c6:	c1 e8 10             	shr    $0x10,%eax
  1015c9:	66 a3 a6 a3 11 00    	mov    %ax,0x11a3a6
	SETGATE(idt[T_LTIMER], 1, CPU_GDT_KCODE, vectors[T_LTIMER], 3);
  1015cf:	a1 d4 c0 10 00       	mov    0x10c0d4,%eax
  1015d4:	66 a3 a8 a3 11 00    	mov    %ax,0x11a3a8
  1015da:	66 c7 05 aa a3 11 00 	movw   $0x8,0x11a3aa
  1015e1:	08 00 
  1015e3:	0f b6 05 ac a3 11 00 	movzbl 0x11a3ac,%eax
  1015ea:	83 e0 e0             	and    $0xffffffe0,%eax
  1015ed:	a2 ac a3 11 00       	mov    %al,0x11a3ac
  1015f2:	0f b6 05 ac a3 11 00 	movzbl 0x11a3ac,%eax
  1015f9:	83 e0 1f             	and    $0x1f,%eax
  1015fc:	a2 ac a3 11 00       	mov    %al,0x11a3ac
  101601:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  101608:	83 c8 0f             	or     $0xf,%eax
  10160b:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  101610:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  101617:	83 e0 ef             	and    $0xffffffef,%eax
  10161a:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  10161f:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  101626:	83 c8 60             	or     $0x60,%eax
  101629:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  10162e:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  101635:	83 c8 80             	or     $0xffffff80,%eax
  101638:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  10163d:	a1 d4 c0 10 00       	mov    0x10c0d4,%eax
  101642:	c1 e8 10             	shr    $0x10,%eax
  101645:	66 a3 ae a3 11 00    	mov    %ax,0x11a3ae
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
  101661:	0f 01 1d 04 c0 10 00 	lidtl  0x10c004

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
  101686:	8b 04 85 c0 8a 10 00 	mov    0x108ac0(,%eax,4),%eax
  10168d:	eb 25                	jmp    1016b4 <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  10168f:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  101693:	75 07                	jne    10169c <trap_name+0x24>
		return "System call";
  101695:	b8 b8 86 10 00       	mov    $0x1086b8,%eax
  10169a:	eb 18                	jmp    1016b4 <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  10169c:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  1016a0:	7e 0d                	jle    1016af <trap_name+0x37>
  1016a2:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  1016a6:	7f 07                	jg     1016af <trap_name+0x37>
		return "Hardware Interrupt";
  1016a8:	b8 c4 86 10 00       	mov    $0x1086c4,%eax
  1016ad:	eb 05                	jmp    1016b4 <trap_name+0x3c>
	return "(unknown trap)";
  1016af:	b8 d7 86 10 00       	mov    $0x1086d7,%eax
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
  1016c5:	c7 04 24 e6 86 10 00 	movl   $0x1086e6,(%esp)
  1016cc:	e8 8e 64 00 00       	call   107b5f <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  1016d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1016d4:	8b 40 04             	mov    0x4(%eax),%eax
  1016d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016db:	c7 04 24 f5 86 10 00 	movl   $0x1086f5,(%esp)
  1016e2:	e8 78 64 00 00       	call   107b5f <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  1016e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1016ea:	8b 40 08             	mov    0x8(%eax),%eax
  1016ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016f1:	c7 04 24 04 87 10 00 	movl   $0x108704,(%esp)
  1016f8:	e8 62 64 00 00       	call   107b5f <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  1016fd:	8b 45 08             	mov    0x8(%ebp),%eax
  101700:	8b 40 10             	mov    0x10(%eax),%eax
  101703:	89 44 24 04          	mov    %eax,0x4(%esp)
  101707:	c7 04 24 13 87 10 00 	movl   $0x108713,(%esp)
  10170e:	e8 4c 64 00 00       	call   107b5f <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101713:	8b 45 08             	mov    0x8(%ebp),%eax
  101716:	8b 40 14             	mov    0x14(%eax),%eax
  101719:	89 44 24 04          	mov    %eax,0x4(%esp)
  10171d:	c7 04 24 22 87 10 00 	movl   $0x108722,(%esp)
  101724:	e8 36 64 00 00       	call   107b5f <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101729:	8b 45 08             	mov    0x8(%ebp),%eax
  10172c:	8b 40 18             	mov    0x18(%eax),%eax
  10172f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101733:	c7 04 24 31 87 10 00 	movl   $0x108731,(%esp)
  10173a:	e8 20 64 00 00       	call   107b5f <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  10173f:	8b 45 08             	mov    0x8(%ebp),%eax
  101742:	8b 40 1c             	mov    0x1c(%eax),%eax
  101745:	89 44 24 04          	mov    %eax,0x4(%esp)
  101749:	c7 04 24 40 87 10 00 	movl   $0x108740,(%esp)
  101750:	e8 0a 64 00 00       	call   107b5f <cprintf>
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
  101764:	c7 04 24 4f 87 10 00 	movl   $0x10874f,(%esp)
  10176b:	e8 ef 63 00 00       	call   107b5f <cprintf>
	trap_print_regs(&tf->regs);
  101770:	8b 45 08             	mov    0x8(%ebp),%eax
  101773:	89 04 24             	mov    %eax,(%esp)
  101776:	e8 3b ff ff ff       	call   1016b6 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  10177b:	8b 45 08             	mov    0x8(%ebp),%eax
  10177e:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101782:	0f b7 c0             	movzwl %ax,%eax
  101785:	89 44 24 04          	mov    %eax,0x4(%esp)
  101789:	c7 04 24 61 87 10 00 	movl   $0x108761,(%esp)
  101790:	e8 ca 63 00 00       	call   107b5f <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101795:	8b 45 08             	mov    0x8(%ebp),%eax
  101798:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10179c:	0f b7 c0             	movzwl %ax,%eax
  10179f:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017a3:	c7 04 24 74 87 10 00 	movl   $0x108774,(%esp)
  1017aa:	e8 b0 63 00 00       	call   107b5f <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  1017af:	8b 45 08             	mov    0x8(%ebp),%eax
  1017b2:	8b 40 30             	mov    0x30(%eax),%eax
  1017b5:	89 04 24             	mov    %eax,(%esp)
  1017b8:	e8 bb fe ff ff       	call   101678 <trap_name>
  1017bd:	8b 55 08             	mov    0x8(%ebp),%edx
  1017c0:	8b 52 30             	mov    0x30(%edx),%edx
  1017c3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1017c7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1017cb:	c7 04 24 87 87 10 00 	movl   $0x108787,(%esp)
  1017d2:	e8 88 63 00 00       	call   107b5f <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  1017d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1017da:	8b 40 34             	mov    0x34(%eax),%eax
  1017dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017e1:	c7 04 24 99 87 10 00 	movl   $0x108799,(%esp)
  1017e8:	e8 72 63 00 00       	call   107b5f <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1017ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1017f0:	8b 40 38             	mov    0x38(%eax),%eax
  1017f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017f7:	c7 04 24 a8 87 10 00 	movl   $0x1087a8,(%esp)
  1017fe:	e8 5c 63 00 00       	call   107b5f <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101803:	8b 45 08             	mov    0x8(%ebp),%eax
  101806:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10180a:	0f b7 c0             	movzwl %ax,%eax
  10180d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101811:	c7 04 24 b7 87 10 00 	movl   $0x1087b7,(%esp)
  101818:	e8 42 63 00 00       	call   107b5f <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  10181d:	8b 45 08             	mov    0x8(%ebp),%eax
  101820:	8b 40 40             	mov    0x40(%eax),%eax
  101823:	89 44 24 04          	mov    %eax,0x4(%esp)
  101827:	c7 04 24 ca 87 10 00 	movl   $0x1087ca,(%esp)
  10182e:	e8 2c 63 00 00       	call   107b5f <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  101833:	8b 45 08             	mov    0x8(%ebp),%eax
  101836:	8b 40 44             	mov    0x44(%eax),%eax
  101839:	89 44 24 04          	mov    %eax,0x4(%esp)
  10183d:	c7 04 24 d9 87 10 00 	movl   $0x1087d9,(%esp)
  101844:	e8 16 63 00 00       	call   107b5f <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  101849:	8b 45 08             	mov    0x8(%ebp),%eax
  10184c:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101850:	0f b7 c0             	movzwl %ax,%eax
  101853:	89 44 24 04          	mov    %eax,0x4(%esp)
  101857:	c7 04 24 e8 87 10 00 	movl   $0x1087e8,(%esp)
  10185e:	e8 fc 62 00 00       	call   107b5f <cprintf>
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
  1018b1:	e8 9f 23 00 00       	call   103c55 <syscall>
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
  1018c6:	e8 fc 57 00 00       	call   1070c7 <lapic_eoi>
			proc_yield(tf);
  1018cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1018ce:	89 04 24             	mov    %eax,(%esp)
  1018d1:	e8 c2 17 00 00       	call   103098 <proc_yield>
			break;
		case T_IRQ0 + IRQ_SPURIOUS:
			panic(" IRQ_SPURIOUS ");
  1018d6:	c7 44 24 08 fb 87 10 	movl   $0x1087fb,0x8(%esp)
  1018dd:	00 
  1018de:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  1018e5:	00 
  1018e6:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
  1018ed:	e8 8f eb ff ff       	call   100481 <debug_panic>

		default:
			proc_ret(tf, -1);
  1018f2:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1018f9:	ff 
  1018fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1018fd:	89 04 24             	mov    %eax,(%esp)
  101900:	e8 d1 17 00 00       	call   1030d6 <proc_ret>

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
  101932:	e8 b9 a7 00 00       	call   10c0f0 <trap_return>

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
  10194e:	c7 44 24 0c 16 88 10 	movl   $0x108816,0xc(%esp)
  101955:	00 
  101956:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  10195d:	00 
  10195e:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  101965:	00 
  101966:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
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
  1019a4:	c7 04 24 2c 88 10 00 	movl   $0x10882c,(%esp)
  1019ab:	e8 af 61 00 00       	call   107b5f <cprintf>
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
  1019ca:	c7 44 24 0c 4c 88 10 	movl   $0x10884c,0xc(%esp)
  1019d1:	00 
  1019d2:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  1019d9:	00 
  1019da:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  1019e1:	00 
  1019e2:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
  1019e9:	e8 93 ea ff ff       	call   100481 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  1019ee:	c7 45 f0 00 b0 10 00 	movl   $0x10b000,-0x10(%ebp)
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
  101a1f:	c7 04 24 61 88 10 00 	movl   $0x108861,(%esp)
  101a26:	e8 34 61 00 00       	call   107b5f <cprintf>
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
  101a53:	c7 04 24 7f 88 10 00 	movl   $0x10887f,(%esp)
  101a5a:	e8 00 61 00 00       	call   107b5f <cprintf>

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
  101a69:	c7 04 24 98 88 10 00 	movl   $0x108898,(%esp)
  101a70:	e8 ea 60 00 00       	call   107b5f <cprintf>
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101a75:	b8 00 00 00 00       	mov    $0x0,%eax
  101a7a:	f7 f0                	div    %eax

00101a7c <after_div0>:
	cprintf("2. &args.trapno == %x\n", &args);
  101a7c:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  101a7f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a83:	c7 04 24 be 88 10 00 	movl   $0x1088be,(%esp)
  101a8a:	e8 d0 60 00 00       	call   107b5f <cprintf>
	assert(args.trapno == T_DIVIDE);
  101a8f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101a92:	85 c0                	test   %eax,%eax
  101a94:	74 24                	je     101aba <after_div0+0x3e>
  101a96:	c7 44 24 0c d5 88 10 	movl   $0x1088d5,0xc(%esp)
  101a9d:	00 
  101a9e:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  101aa5:	00 
  101aa6:	c7 44 24 04 f9 00 00 	movl   $0xf9,0x4(%esp)
  101aad:	00 
  101aae:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
  101ab5:	e8 c7 e9 ff ff       	call   100481 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101aba:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101abd:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101ac2:	74 24                	je     101ae8 <after_div0+0x6c>
  101ac4:	c7 44 24 0c ed 88 10 	movl   $0x1088ed,0xc(%esp)
  101acb:	00 
  101acc:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  101ad3:	00 
  101ad4:	c7 44 24 04 fe 00 00 	movl   $0xfe,0x4(%esp)
  101adb:	00 
  101adc:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
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
  101af8:	c7 44 24 0c 02 89 10 	movl   $0x108902,0xc(%esp)
  101aff:	00 
  101b00:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  101b07:	00 
  101b08:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  101b0f:	00 
  101b10:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
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
  101b33:	c7 44 24 0c 19 89 10 	movl   $0x108919,0xc(%esp)
  101b3a:	00 
  101b3b:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  101b42:	00 
  101b43:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
  101b4a:	00 
  101b4b:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
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
  101b7c:	c7 44 24 0c 30 89 10 	movl   $0x108930,0xc(%esp)
  101b83:	00 
  101b84:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  101b8b:	00 
  101b8c:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
  101b93:	00 
  101b94:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
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
  101bb1:	c7 44 24 0c 47 89 10 	movl   $0x108947,0xc(%esp)
  101bb8:	00 
  101bb9:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  101bc0:	00 
  101bc1:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
  101bc8:	00 
  101bc9:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
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
  101beb:	c7 44 24 0c 5e 89 10 	movl   $0x10895e,0xc(%esp)
  101bf2:	00 
  101bf3:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  101bfa:	00 
  101bfb:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  101c02:	00 
  101c03:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
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
  101c27:	0f 01 1d 04 c0 10 00 	lidtl  0x10c004

00101c2e <after_priv>:
		assert(args.trapno == T_GPFLT);
  101c2e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101c31:	83 f8 0d             	cmp    $0xd,%eax
  101c34:	74 24                	je     101c5a <after_priv+0x2c>
  101c36:	c7 44 24 0c 5e 89 10 	movl   $0x10895e,0xc(%esp)
  101c3d:	00 
  101c3e:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  101c45:	00 
  101c46:	c7 44 24 04 1e 01 00 	movl   $0x11e,0x4(%esp)
  101c4d:	00 
  101c4e:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
  101c55:	e8 27 e8 ff ff       	call   100481 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101c5a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101c5d:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101c62:	74 24                	je     101c88 <after_priv+0x5a>
  101c64:	c7 44 24 0c ed 88 10 	movl   $0x1088ed,0xc(%esp)
  101c6b:	00 
  101c6c:	c7 44 24 08 96 86 10 	movl   $0x108696,0x8(%esp)
  101c73:	00 
  101c74:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
  101c7b:	00 
  101c7c:	c7 04 24 0a 88 10 00 	movl   $0x10880a,(%esp)
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
  101c9e:	e9 35 a4 00 00       	jmp    10c0d8 <_alltraps>
  101ca3:	90                   	nop

00101ca4 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  101ca4:	6a 00                	push   $0x0
  101ca6:	6a 01                	push   $0x1
  101ca8:	e9 2b a4 00 00       	jmp    10c0d8 <_alltraps>
  101cad:	90                   	nop

00101cae <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  101cae:	6a 00                	push   $0x0
  101cb0:	6a 02                	push   $0x2
  101cb2:	e9 21 a4 00 00       	jmp    10c0d8 <_alltraps>
  101cb7:	90                   	nop

00101cb8 <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  101cb8:	6a 00                	push   $0x0
  101cba:	6a 03                	push   $0x3
  101cbc:	e9 17 a4 00 00       	jmp    10c0d8 <_alltraps>
  101cc1:	90                   	nop

00101cc2 <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  101cc2:	6a 00                	push   $0x0
  101cc4:	6a 04                	push   $0x4
  101cc6:	e9 0d a4 00 00       	jmp    10c0d8 <_alltraps>
  101ccb:	90                   	nop

00101ccc <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  101ccc:	6a 00                	push   $0x0
  101cce:	6a 05                	push   $0x5
  101cd0:	e9 03 a4 00 00       	jmp    10c0d8 <_alltraps>
  101cd5:	90                   	nop

00101cd6 <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  101cd6:	6a 00                	push   $0x0
  101cd8:	6a 06                	push   $0x6
  101cda:	e9 f9 a3 00 00       	jmp    10c0d8 <_alltraps>
  101cdf:	90                   	nop

00101ce0 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  101ce0:	6a 00                	push   $0x0
  101ce2:	6a 07                	push   $0x7
  101ce4:	e9 ef a3 00 00       	jmp    10c0d8 <_alltraps>
  101ce9:	90                   	nop

00101cea <vector8>:
TRAPHANDLER(vector8, 8)
  101cea:	6a 08                	push   $0x8
  101cec:	e9 e7 a3 00 00       	jmp    10c0d8 <_alltraps>
  101cf1:	90                   	nop

00101cf2 <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  101cf2:	6a 00                	push   $0x0
  101cf4:	6a 09                	push   $0x9
  101cf6:	e9 dd a3 00 00       	jmp    10c0d8 <_alltraps>
  101cfb:	90                   	nop

00101cfc <vector10>:
TRAPHANDLER(vector10, 10)
  101cfc:	6a 0a                	push   $0xa
  101cfe:	e9 d5 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d03:	90                   	nop

00101d04 <vector11>:
TRAPHANDLER(vector11, 11)
  101d04:	6a 0b                	push   $0xb
  101d06:	e9 cd a3 00 00       	jmp    10c0d8 <_alltraps>
  101d0b:	90                   	nop

00101d0c <vector12>:
TRAPHANDLER(vector12, 12)
  101d0c:	6a 0c                	push   $0xc
  101d0e:	e9 c5 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d13:	90                   	nop

00101d14 <vector13>:
TRAPHANDLER(vector13, 13)
  101d14:	6a 0d                	push   $0xd
  101d16:	e9 bd a3 00 00       	jmp    10c0d8 <_alltraps>
  101d1b:	90                   	nop

00101d1c <vector14>:
TRAPHANDLER(vector14, 14)
  101d1c:	6a 0e                	push   $0xe
  101d1e:	e9 b5 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d23:	90                   	nop

00101d24 <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101d24:	6a 00                	push   $0x0
  101d26:	6a 0f                	push   $0xf
  101d28:	e9 ab a3 00 00       	jmp    10c0d8 <_alltraps>
  101d2d:	90                   	nop

00101d2e <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  101d2e:	6a 00                	push   $0x0
  101d30:	6a 10                	push   $0x10
  101d32:	e9 a1 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d37:	90                   	nop

00101d38 <vector17>:
TRAPHANDLER(vector17, 17)
  101d38:	6a 11                	push   $0x11
  101d3a:	e9 99 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d3f:	90                   	nop

00101d40 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  101d40:	6a 00                	push   $0x0
  101d42:	6a 12                	push   $0x12
  101d44:	e9 8f a3 00 00       	jmp    10c0d8 <_alltraps>
  101d49:	90                   	nop

00101d4a <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  101d4a:	6a 00                	push   $0x0
  101d4c:	6a 13                	push   $0x13
  101d4e:	e9 85 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d53:	90                   	nop

00101d54 <vector20>:
TRAPHANDLER_NOEC(vector20, 20)
  101d54:	6a 00                	push   $0x0
  101d56:	6a 14                	push   $0x14
  101d58:	e9 7b a3 00 00       	jmp    10c0d8 <_alltraps>
  101d5d:	90                   	nop

00101d5e <vector21>:
TRAPHANDLER_NOEC(vector21, 21)
  101d5e:	6a 00                	push   $0x0
  101d60:	6a 15                	push   $0x15
  101d62:	e9 71 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d67:	90                   	nop

00101d68 <vector22>:
TRAPHANDLER_NOEC(vector22, 22)
  101d68:	6a 00                	push   $0x0
  101d6a:	6a 16                	push   $0x16
  101d6c:	e9 67 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d71:	90                   	nop

00101d72 <vector23>:
TRAPHANDLER_NOEC(vector23, 23)
  101d72:	6a 00                	push   $0x0
  101d74:	6a 17                	push   $0x17
  101d76:	e9 5d a3 00 00       	jmp    10c0d8 <_alltraps>
  101d7b:	90                   	nop

00101d7c <vector24>:
TRAPHANDLER_NOEC(vector24, 24)
  101d7c:	6a 00                	push   $0x0
  101d7e:	6a 18                	push   $0x18
  101d80:	e9 53 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d85:	90                   	nop

00101d86 <vector25>:
TRAPHANDLER_NOEC(vector25, 25)
  101d86:	6a 00                	push   $0x0
  101d88:	6a 19                	push   $0x19
  101d8a:	e9 49 a3 00 00       	jmp    10c0d8 <_alltraps>
  101d8f:	90                   	nop

00101d90 <vector26>:
TRAPHANDLER_NOEC(vector26, 26)
  101d90:	6a 00                	push   $0x0
  101d92:	6a 1a                	push   $0x1a
  101d94:	e9 3f a3 00 00       	jmp    10c0d8 <_alltraps>
  101d99:	90                   	nop

00101d9a <vector27>:
TRAPHANDLER_NOEC(vector27, 27)
  101d9a:	6a 00                	push   $0x0
  101d9c:	6a 1b                	push   $0x1b
  101d9e:	e9 35 a3 00 00       	jmp    10c0d8 <_alltraps>
  101da3:	90                   	nop

00101da4 <vector28>:
TRAPHANDLER_NOEC(vector28, 28)
  101da4:	6a 00                	push   $0x0
  101da6:	6a 1c                	push   $0x1c
  101da8:	e9 2b a3 00 00       	jmp    10c0d8 <_alltraps>
  101dad:	90                   	nop

00101dae <vector29>:
TRAPHANDLER_NOEC(vector29, 29)
  101dae:	6a 00                	push   $0x0
  101db0:	6a 1d                	push   $0x1d
  101db2:	e9 21 a3 00 00       	jmp    10c0d8 <_alltraps>
  101db7:	90                   	nop

00101db8 <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101db8:	6a 00                	push   $0x0
  101dba:	6a 1e                	push   $0x1e
  101dbc:	e9 17 a3 00 00       	jmp    10c0d8 <_alltraps>
  101dc1:	90                   	nop

00101dc2 <vector31>:
TRAPHANDLER_NOEC(vector31, 31)
  101dc2:	6a 00                	push   $0x0
  101dc4:	6a 1f                	push   $0x1f
  101dc6:	e9 0d a3 00 00       	jmp    10c0d8 <_alltraps>
  101dcb:	90                   	nop

00101dcc <vector32>:
TRAPHANDLER_NOEC(vector32, 32)
  101dcc:	6a 00                	push   $0x0
  101dce:	6a 20                	push   $0x20
  101dd0:	e9 03 a3 00 00       	jmp    10c0d8 <_alltraps>
  101dd5:	90                   	nop

00101dd6 <vector33>:
TRAPHANDLER_NOEC(vector33, 33)
  101dd6:	6a 00                	push   $0x0
  101dd8:	6a 21                	push   $0x21
  101dda:	e9 f9 a2 00 00       	jmp    10c0d8 <_alltraps>
  101ddf:	90                   	nop

00101de0 <vector34>:
TRAPHANDLER_NOEC(vector34, 34)
  101de0:	6a 00                	push   $0x0
  101de2:	6a 22                	push   $0x22
  101de4:	e9 ef a2 00 00       	jmp    10c0d8 <_alltraps>
  101de9:	90                   	nop

00101dea <vector35>:
TRAPHANDLER_NOEC(vector35, 35)
  101dea:	6a 00                	push   $0x0
  101dec:	6a 23                	push   $0x23
  101dee:	e9 e5 a2 00 00       	jmp    10c0d8 <_alltraps>
  101df3:	90                   	nop

00101df4 <vector36>:
TRAPHANDLER_NOEC(vector36, 36)
  101df4:	6a 00                	push   $0x0
  101df6:	6a 24                	push   $0x24
  101df8:	e9 db a2 00 00       	jmp    10c0d8 <_alltraps>
  101dfd:	90                   	nop

00101dfe <vector37>:
TRAPHANDLER_NOEC(vector37, 37)
  101dfe:	6a 00                	push   $0x0
  101e00:	6a 25                	push   $0x25
  101e02:	e9 d1 a2 00 00       	jmp    10c0d8 <_alltraps>
  101e07:	90                   	nop

00101e08 <vector38>:
TRAPHANDLER_NOEC(vector38, 38)
  101e08:	6a 00                	push   $0x0
  101e0a:	6a 26                	push   $0x26
  101e0c:	e9 c7 a2 00 00       	jmp    10c0d8 <_alltraps>
  101e11:	90                   	nop

00101e12 <vector39>:
TRAPHANDLER_NOEC(vector39, 39)
  101e12:	6a 00                	push   $0x0
  101e14:	6a 27                	push   $0x27
  101e16:	e9 bd a2 00 00       	jmp    10c0d8 <_alltraps>
  101e1b:	90                   	nop

00101e1c <vector40>:
TRAPHANDLER_NOEC(vector40, 40)
  101e1c:	6a 00                	push   $0x0
  101e1e:	6a 28                	push   $0x28
  101e20:	e9 b3 a2 00 00       	jmp    10c0d8 <_alltraps>
  101e25:	90                   	nop

00101e26 <vector41>:
TRAPHANDLER_NOEC(vector41, 41)
  101e26:	6a 00                	push   $0x0
  101e28:	6a 29                	push   $0x29
  101e2a:	e9 a9 a2 00 00       	jmp    10c0d8 <_alltraps>
  101e2f:	90                   	nop

00101e30 <vector42>:
TRAPHANDLER_NOEC(vector42, 42)
  101e30:	6a 00                	push   $0x0
  101e32:	6a 2a                	push   $0x2a
  101e34:	e9 9f a2 00 00       	jmp    10c0d8 <_alltraps>
  101e39:	90                   	nop

00101e3a <vector43>:
TRAPHANDLER_NOEC(vector43, 43)
  101e3a:	6a 00                	push   $0x0
  101e3c:	6a 2b                	push   $0x2b
  101e3e:	e9 95 a2 00 00       	jmp    10c0d8 <_alltraps>
  101e43:	90                   	nop

00101e44 <vector44>:
TRAPHANDLER_NOEC(vector44, 44)
  101e44:	6a 00                	push   $0x0
  101e46:	6a 2c                	push   $0x2c
  101e48:	e9 8b a2 00 00       	jmp    10c0d8 <_alltraps>
  101e4d:	90                   	nop

00101e4e <vector45>:
TRAPHANDLER_NOEC(vector45, 45)
  101e4e:	6a 00                	push   $0x0
  101e50:	6a 2d                	push   $0x2d
  101e52:	e9 81 a2 00 00       	jmp    10c0d8 <_alltraps>
  101e57:	90                   	nop

00101e58 <vector46>:
TRAPHANDLER_NOEC(vector46, 46)
  101e58:	6a 00                	push   $0x0
  101e5a:	6a 2e                	push   $0x2e
  101e5c:	e9 77 a2 00 00       	jmp    10c0d8 <_alltraps>
  101e61:	90                   	nop

00101e62 <vector47>:
TRAPHANDLER_NOEC(vector47, 47)
  101e62:	6a 00                	push   $0x0
  101e64:	6a 2f                	push   $0x2f
  101e66:	e9 6d a2 00 00       	jmp    10c0d8 <_alltraps>
  101e6b:	90                   	nop

00101e6c <vector48>:
TRAPHANDLER_NOEC(vector48, 48)
  101e6c:	6a 00                	push   $0x0
  101e6e:	6a 30                	push   $0x30
  101e70:	e9 63 a2 00 00       	jmp    10c0d8 <_alltraps>
  101e75:	90                   	nop

00101e76 <vector49>:
TRAPHANDLER_NOEC(vector49, 49)
  101e76:	6a 00                	push   $0x0
  101e78:	6a 31                	push   $0x31
  101e7a:	e9 59 a2 00 00       	jmp    10c0d8 <_alltraps>

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
  101ea9:	c7 44 24 0c 10 8b 10 	movl   $0x108b10,0xc(%esp)
  101eb0:	00 
  101eb1:	c7 44 24 08 26 8b 10 	movl   $0x108b26,0x8(%esp)
  101eb8:	00 
  101eb9:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101ec0:	00 
  101ec1:	c7 04 24 3b 8b 10 00 	movl   $0x108b3b,(%esp)
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
  101edd:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
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
  101f3f:	c7 44 24 04 48 8b 10 	movl   $0x108b48,0x4(%esp)
  101f46:	00 
  101f47:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f4a:	89 04 24             	mov    %eax,(%esp)
  101f4d:	e8 62 5f 00 00       	call   107eb4 <memcmp>
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
  102075:	c7 44 24 04 4d 8b 10 	movl   $0x108b4d,0x4(%esp)
  10207c:	00 
  10207d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102080:	89 04 24             	mov    %eax,(%esp)
  102083:	e8 2c 5e 00 00       	call   107eb4 <memcmp>
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
  10210c:	c7 05 64 ed 31 00 01 	movl   $0x1,0x31ed64
  102113:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  102116:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102119:	8b 40 24             	mov    0x24(%eax),%eax
  10211c:	a3 04 20 32 00       	mov    %eax,0x322004
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
  102154:	8b 04 85 80 8b 10 00 	mov    0x108b80(,%eax,4),%eax
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
  102194:	b8 00 b0 10 00       	mov    $0x10b000,%eax
  102199:	89 45 e0             	mov    %eax,-0x20(%ebp)
			c->id = proc->apicid;
  10219c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10219f:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  1021a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1021a6:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  1021ac:	a1 68 ed 31 00       	mov    0x31ed68,%eax
  1021b1:	83 c0 01             	add    $0x1,%eax
  1021b4:	a3 68 ed 31 00       	mov    %eax,0x31ed68
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
  1021cc:	a2 5c ed 31 00       	mov    %al,0x31ed5c
			ioapic = (struct ioapic *) mpio->addr;
  1021d1:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1021d4:	8b 40 04             	mov    0x4(%eax),%eax
  1021d7:	a3 60 ed 31 00       	mov    %eax,0x31ed60
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
  1021f1:	c7 44 24 08 54 8b 10 	movl   $0x108b54,0x8(%esp)
  1021f8:	00 
  1021f9:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  102200:	00 
  102201:	c7 04 24 74 8b 10 00 	movl   $0x108b74,(%esp)
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
  1022b0:	c7 44 24 0c 94 8b 10 	movl   $0x108b94,0xc(%esp)
  1022b7:	00 
  1022b8:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  1022bf:	00 
  1022c0:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1022c7:	00 
  1022c8:	c7 04 24 bf 8b 10 00 	movl   $0x108bbf,(%esp)
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
  102322:	c7 44 24 08 cc 8b 10 	movl   $0x108bcc,0x8(%esp)
  102329:	00 
  10232a:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
  102331:	00 
  102332:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  10238f:	c7 44 24 08 e4 8b 10 	movl   $0x108be4,0x8(%esp)
  102396:	00 
  102397:	c7 44 24 04 40 00 00 	movl   $0x40,0x4(%esp)
  10239e:	00 
  10239f:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  10245d:	c7 45 e4 ec 8b 10 00 	movl   $0x108bec,-0x1c(%ebp)
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
  102593:	c7 44 24 0c fb 8b 10 	movl   $0x108bfb,0xc(%esp)
  10259a:	00 
  10259b:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  1025a2:	00 
  1025a3:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1025aa:	00 
  1025ab:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  1025eb:	c7 44 24 0c 0e 8c 10 	movl   $0x108c0e,0xc(%esp)
  1025f2:	00 
  1025f3:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  1025fa:	00 
  1025fb:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  102602:	00 
  102603:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  102637:	c7 04 24 22 8c 10 00 	movl   $0x108c22,(%esp)
  10263e:	e8 1c 55 00 00       	call   107b5f <cprintf>
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
  1026a3:	c7 44 24 0c 26 8c 10 	movl   $0x108c26,0xc(%esp)
  1026aa:	00 
  1026ab:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  1026b2:	00 
  1026b3:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  1026ba:	00 
  1026bb:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  102701:	c7 44 24 0c 40 8c 10 	movl   $0x108c40,0xc(%esp)
  102708:	00 
  102709:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  102710:	00 
  102711:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  102718:	00 
  102719:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  10276f:	c7 44 24 0c 64 8c 10 	movl   $0x108c64,0xc(%esp)
  102776:	00 
  102777:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  10277e:	00 
  10277f:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  102786:	00 
  102787:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  1027bc:	c7 44 24 0c 94 8c 10 	movl   $0x108c94,0xc(%esp)
  1027c3:	00 
  1027c4:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  1027cb:	00 
  1027cc:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  1027d3:	00 
  1027d4:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  102863:	c7 44 24 0c c5 8c 10 	movl   $0x108cc5,0xc(%esp)
  10286a:	00 
  10286b:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  102872:	00 
  102873:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  10287a:	00 
  10287b:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  1028ba:	c7 44 24 0c da 8c 10 	movl   $0x108cda,0xc(%esp)
  1028c1:	00 
  1028c2:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  1028c9:	00 
  1028ca:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  1028d1:	00 
  1028d2:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  102918:	c7 44 24 0c f0 8c 10 	movl   $0x108cf0,0xc(%esp)
  10291f:	00 
  102920:	c7 44 24 08 aa 8b 10 	movl   $0x108baa,0x8(%esp)
  102927:	00 
  102928:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  10292f:	00 
  102930:	c7 04 24 d4 8b 10 00 	movl   $0x108bd4,(%esp)
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
  102958:	c7 04 24 11 8d 10 00 	movl   $0x108d11,(%esp)
  10295f:	e8 fb 51 00 00       	call   107b5f <cprintf>
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
  1029ce:	c7 44 24 0c 30 8d 10 	movl   $0x108d30,0xc(%esp)
  1029d5:	00 
  1029d6:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  1029dd:	00 
  1029de:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1029e5:	00 
  1029e6:	c7 04 24 5b 8d 10 00 	movl   $0x108d5b,(%esp)
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
  102a02:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
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
  102a1c:	c7 04 24 68 8d 10 00 	movl   $0x108d68,(%esp)
  102a23:	e8 37 51 00 00       	call   107b5f <cprintf>
  102a28:	eb 0c                	jmp    102a36 <proc_print+0x27>
	else
		cprintf("release lock ");
  102a2a:	c7 04 24 76 8d 10 00 	movl   $0x108d76,(%esp)
  102a31:	e8 29 51 00 00       	call   107b5f <cprintf>
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
  102a59:	c7 04 24 84 8d 10 00 	movl   $0x108d84,(%esp)
  102a60:	e8 fa 50 00 00       	call   107b5f <cprintf>
  102a65:	eb 1f                	jmp    102a86 <proc_print+0x77>
	else
		cprintf("on cpu %d\n", cpu_cur()->id);
  102a67:	e8 38 ff ff ff       	call   1029a4 <cpu_cur>
  102a6c:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  102a73:	0f b6 c0             	movzbl %al,%eax
  102a76:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a7a:	c7 04 24 9b 8d 10 00 	movl   $0x108d9b,(%esp)
  102a81:	e8 d9 50 00 00       	call   107b5f <cprintf>
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
  102aa3:	c7 44 24 04 a6 8d 10 	movl   $0x108da6,0x4(%esp)
  102aaa:	00 
  102aab:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  102ab2:	e8 22 f8 ff ff       	call   1022d9 <spinlock_init_>

	queue.count= 0;
  102ab7:	c7 05 78 f4 31 00 00 	movl   $0x0,0x31f478
  102abe:	00 00 00 
	queue.head = NULL;
  102ac1:	c7 05 7c f4 31 00 00 	movl   $0x0,0x31f47c
  102ac8:	00 00 00 
	queue.tail= NULL;
  102acb:	c7 05 80 f4 31 00 00 	movl   $0x0,0x31f480
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
  102af3:	e9 d6 01 00 00       	jmp    102cce <proc_alloc+0x1f4>
  102af8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102afb:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  102afe:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102b03:	83 c0 08             	add    $0x8,%eax
  102b06:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b09:	76 15                	jbe    102b20 <proc_alloc+0x46>
  102b0b:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102b10:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  102b16:	c1 e2 03             	shl    $0x3,%edx
  102b19:	01 d0                	add    %edx,%eax
  102b1b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b1e:	72 24                	jb     102b44 <proc_alloc+0x6a>
  102b20:	c7 44 24 0c b4 8d 10 	movl   $0x108db4,0xc(%esp)
  102b27:	00 
  102b28:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  102b2f:	00 
  102b30:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102b37:	00 
  102b38:	c7 04 24 eb 8d 10 00 	movl   $0x108deb,(%esp)
  102b3f:	e8 3d d9 ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  102b44:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102b49:	ba 00 10 32 00       	mov    $0x321000,%edx
  102b4e:	c1 ea 0c             	shr    $0xc,%edx
  102b51:	c1 e2 03             	shl    $0x3,%edx
  102b54:	01 d0                	add    %edx,%eax
  102b56:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b59:	75 24                	jne    102b7f <proc_alloc+0xa5>
  102b5b:	c7 44 24 0c f8 8d 10 	movl   $0x108df8,0xc(%esp)
  102b62:	00 
  102b63:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  102b6a:	00 
  102b6b:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  102b72:	00 
  102b73:	c7 04 24 eb 8d 10 00 	movl   $0x108deb,(%esp)
  102b7a:	e8 02 d9 ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  102b7f:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102b84:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  102b89:	c1 ea 0c             	shr    $0xc,%edx
  102b8c:	c1 e2 03             	shl    $0x3,%edx
  102b8f:	01 d0                	add    %edx,%eax
  102b91:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b94:	72 3b                	jb     102bd1 <proc_alloc+0xf7>
  102b96:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102b9b:	ba 07 20 32 00       	mov    $0x322007,%edx
  102ba0:	c1 ea 0c             	shr    $0xc,%edx
  102ba3:	c1 e2 03             	shl    $0x3,%edx
  102ba6:	01 d0                	add    %edx,%eax
  102ba8:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102bab:	77 24                	ja     102bd1 <proc_alloc+0xf7>
  102bad:	c7 44 24 0c 14 8e 10 	movl   $0x108e14,0xc(%esp)
  102bb4:	00 
  102bb5:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  102bbc:	00 
  102bbd:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  102bc4:	00 
  102bc5:	c7 04 24 eb 8d 10 00 	movl   $0x108deb,(%esp)
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
  102bea:	a1 58 ed 31 00       	mov    0x31ed58,%eax
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
  102c14:	e8 2b 51 00 00       	call   107d44 <memset>

	spinlock_init(&cp->lock);
  102c19:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c1c:	c7 44 24 08 52 00 00 	movl   $0x52,0x8(%esp)
  102c23:	00 
  102c24:	c7 44 24 04 a6 8d 10 	movl   $0x108da6,0x4(%esp)
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
  102c4a:	a1 20 aa 11 00       	mov    0x11aa20,%eax
  102c4f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102c52:	89 42 38             	mov    %eax,0x38(%edx)
  102c55:	83 c0 01             	add    $0x1,%eax
  102c58:	a3 20 aa 11 00       	mov    %eax,0x11aa20

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

	cp->pdir = pmap_newpdir();
  102caf:	e8 96 11 00 00       	call   103e4a <pmap_newpdir>
  102cb4:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102cb7:	89 82 a0 06 00 00    	mov    %eax,0x6a0(%edx)
	cp->rpdir = pmap_newpdir();
  102cbd:	e8 88 11 00 00       	call   103e4a <pmap_newpdir>
  102cc2:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102cc5:	89 82 a4 06 00 00    	mov    %eax,0x6a4(%edx)
	
	return cp;
  102ccb:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102cce:	c9                   	leave  
  102ccf:	c3                   	ret    

00102cd0 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  102cd0:	55                   	push   %ebp
  102cd1:	89 e5                	mov    %esp,%ebp
  102cd3:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_ready not implemented");

 	//cprintf("in ready, child num:%d\n", queue.count);
	if(p == NULL)
  102cd6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102cda:	75 1c                	jne    102cf8 <proc_ready+0x28>
		panic("proc_ready's p is null!");
  102cdc:	c7 44 24 08 45 8e 10 	movl   $0x108e45,0x8(%esp)
  102ce3:	00 
  102ce4:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  102ceb:	00 
  102cec:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  102cf3:	e8 89 d7 ff ff       	call   100481 <debug_panic>
	
	assert(p->state != PROC_READY);
  102cf8:	8b 45 08             	mov    0x8(%ebp),%eax
  102cfb:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102d01:	83 f8 01             	cmp    $0x1,%eax
  102d04:	75 24                	jne    102d2a <proc_ready+0x5a>
  102d06:	c7 44 24 0c 5d 8e 10 	movl   $0x108e5d,0xc(%esp)
  102d0d:	00 
  102d0e:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  102d15:	00 
  102d16:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  102d1d:	00 
  102d1e:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  102d25:	e8 57 d7 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102d2a:	8b 45 08             	mov    0x8(%ebp),%eax
  102d2d:	89 04 24             	mov    %eax,(%esp)
  102d30:	e8 d8 f5 ff ff       	call   10230d <spinlock_acquire>
	p->state = PROC_READY;
  102d35:	8b 45 08             	mov    0x8(%ebp),%eax
  102d38:	c7 80 40 04 00 00 01 	movl   $0x1,0x440(%eax)
  102d3f:	00 00 00 
	spinlock_acquire(&queue.lock);
  102d42:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  102d49:	e8 bf f5 ff ff       	call   10230d <spinlock_acquire>
	// if there is no proc in queue now
	if(queue.count == 0){
  102d4e:	a1 78 f4 31 00       	mov    0x31f478,%eax
  102d53:	85 c0                	test   %eax,%eax
  102d55:	75 1f                	jne    102d76 <proc_ready+0xa6>
		//cprintf("in ready = 0\n");
		queue.count++;
  102d57:	a1 78 f4 31 00       	mov    0x31f478,%eax
  102d5c:	83 c0 01             	add    $0x1,%eax
  102d5f:	a3 78 f4 31 00       	mov    %eax,0x31f478
		queue.head = p;
  102d64:	8b 45 08             	mov    0x8(%ebp),%eax
  102d67:	a3 7c f4 31 00       	mov    %eax,0x31f47c
		queue.tail = p;
  102d6c:	8b 45 08             	mov    0x8(%ebp),%eax
  102d6f:	a3 80 f4 31 00       	mov    %eax,0x31f480
  102d74:	eb 24                	jmp    102d9a <proc_ready+0xca>
	}

	// insert it to the head of the queue
	else{
		//cprintf("in ready != 0\n");
		p->readynext = queue.head;
  102d76:	8b 15 7c f4 31 00    	mov    0x31f47c,%edx
  102d7c:	8b 45 08             	mov    0x8(%ebp),%eax
  102d7f:	89 90 44 04 00 00    	mov    %edx,0x444(%eax)
		queue.head = p;
  102d85:	8b 45 08             	mov    0x8(%ebp),%eax
  102d88:	a3 7c f4 31 00       	mov    %eax,0x31f47c
		queue.count += 1;
  102d8d:	a1 78 f4 31 00       	mov    0x31f478,%eax
  102d92:	83 c0 01             	add    $0x1,%eax
  102d95:	a3 78 f4 31 00       	mov    %eax,0x31f478
		//spinlock_release(&queue.lock);
		//proc_print(RELEASE, p);
		//spinlock_release(&p->lock);
	}

	spinlock_release(&p->lock);
  102d9a:	8b 45 08             	mov    0x8(%ebp),%eax
  102d9d:	89 04 24             	mov    %eax,(%esp)
  102da0:	e8 d5 f5 ff ff       	call   10237a <spinlock_release>
	spinlock_release(&queue.lock);
  102da5:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  102dac:	e8 c9 f5 ff ff       	call   10237a <spinlock_release>
	return;
	
}
  102db1:	c9                   	leave  
  102db2:	c3                   	ret    

00102db3 <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  102db3:	55                   	push   %ebp
  102db4:	89 e5                	mov    %esp,%ebp
  102db6:	83 ec 18             	sub    $0x18,%esp
	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102db9:	8b 45 08             	mov    0x8(%ebp),%eax
  102dbc:	89 04 24             	mov    %eax,(%esp)
  102dbf:	e8 49 f5 ff ff       	call   10230d <spinlock_acquire>

	switch(entry){
  102dc4:	8b 45 10             	mov    0x10(%ebp),%eax
  102dc7:	85 c0                	test   %eax,%eax
  102dc9:	74 2c                	je     102df7 <proc_save+0x44>
  102dcb:	83 f8 01             	cmp    $0x1,%eax
  102dce:	74 36                	je     102e06 <proc_save+0x53>
  102dd0:	83 f8 ff             	cmp    $0xffffffff,%eax
  102dd3:	75 53                	jne    102e28 <proc_save+0x75>
		case -1:		
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  102dd5:	8b 45 08             	mov    0x8(%ebp),%eax
  102dd8:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102dde:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102de5:	00 
  102de6:	8b 45 0c             	mov    0xc(%ebp),%eax
  102de9:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ded:	89 14 24             	mov    %edx,(%esp)
  102df0:	e8 c3 4f 00 00       	call   107db8 <memmove>
			break;
  102df5:	eb 4d                	jmp    102e44 <proc_save+0x91>
		case 0:
			tf->eip = (uintptr_t)((char*)tf->eip - 2);
  102df7:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dfa:	8b 40 38             	mov    0x38(%eax),%eax
  102dfd:	8d 50 fe             	lea    -0x2(%eax),%edx
  102e00:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e03:	89 50 38             	mov    %edx,0x38(%eax)
		case 1:
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  102e06:	8b 45 08             	mov    0x8(%ebp),%eax
  102e09:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102e0f:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102e16:	00 
  102e17:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e1a:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e1e:	89 14 24             	mov    %edx,(%esp)
  102e21:	e8 92 4f 00 00       	call   107db8 <memmove>
			break;
  102e26:	eb 1c                	jmp    102e44 <proc_save+0x91>
		default:
			panic("wrong entry!\n");
  102e28:	c7 44 24 08 74 8e 10 	movl   $0x108e74,0x8(%esp)
  102e2f:	00 
  102e30:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
  102e37:	00 
  102e38:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  102e3f:	e8 3d d6 ff ff       	call   100481 <debug_panic>
	}

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  102e44:	8b 45 08             	mov    0x8(%ebp),%eax
  102e47:	89 04 24             	mov    %eax,(%esp)
  102e4a:	e8 2b f5 ff ff       	call   10237a <spinlock_release>
}
  102e4f:	c9                   	leave  
  102e50:	c3                   	ret    

00102e51 <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  102e51:	55                   	push   %ebp
  102e52:	89 e5                	mov    %esp,%ebp
  102e54:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");

	if(p == NULL || p->state != PROC_RUN)
  102e57:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102e5b:	74 0e                	je     102e6b <proc_wait+0x1a>
  102e5d:	8b 45 08             	mov    0x8(%ebp),%eax
  102e60:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102e66:	83 f8 02             	cmp    $0x2,%eax
  102e69:	74 1c                	je     102e87 <proc_wait+0x36>
		panic("parent proc is not running!");
  102e6b:	c7 44 24 08 82 8e 10 	movl   $0x108e82,0x8(%esp)
  102e72:	00 
  102e73:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
  102e7a:	00 
  102e7b:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  102e82:	e8 fa d5 ff ff       	call   100481 <debug_panic>
	if(cp == NULL)
  102e87:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102e8b:	75 1c                	jne    102ea9 <proc_wait+0x58>
		panic("no child proc!");
  102e8d:	c7 44 24 08 9e 8e 10 	movl   $0x108e9e,0x8(%esp)
  102e94:	00 
  102e95:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
  102e9c:	00 
  102e9d:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  102ea4:	e8 d8 d5 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102ea9:	8b 45 08             	mov    0x8(%ebp),%eax
  102eac:	89 04 24             	mov    %eax,(%esp)
  102eaf:	e8 59 f4 ff ff       	call   10230d <spinlock_acquire>
	p->state = PROC_WAIT;
  102eb4:	8b 45 08             	mov    0x8(%ebp),%eax
  102eb7:	c7 80 40 04 00 00 03 	movl   $0x3,0x440(%eax)
  102ebe:	00 00 00 
	p->waitchild = cp;
  102ec1:	8b 45 08             	mov    0x8(%ebp),%eax
  102ec4:	8b 55 0c             	mov    0xc(%ebp),%edx
  102ec7:	89 90 4c 04 00 00    	mov    %edx,0x44c(%eax)
	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  102ecd:	8b 45 08             	mov    0x8(%ebp),%eax
  102ed0:	89 04 24             	mov    %eax,(%esp)
  102ed3:	e8 a2 f4 ff ff       	call   10237a <spinlock_release>
	
	proc_save(p, tf, 0);
  102ed8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102edf:	00 
  102ee0:	8b 45 10             	mov    0x10(%ebp),%eax
  102ee3:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ee7:	8b 45 08             	mov    0x8(%ebp),%eax
  102eea:	89 04 24             	mov    %eax,(%esp)
  102eed:	e8 c1 fe ff ff       	call   102db3 <proc_save>

	assert(cp->state != PROC_STOP);
  102ef2:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ef5:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102efb:	85 c0                	test   %eax,%eax
  102efd:	75 24                	jne    102f23 <proc_wait+0xd2>
  102eff:	c7 44 24 0c ad 8e 10 	movl   $0x108ead,0xc(%esp)
  102f06:	00 
  102f07:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  102f0e:	00 
  102f0f:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  102f16:	00 
  102f17:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  102f1e:	e8 5e d5 ff ff       	call   100481 <debug_panic>
	
	proc_sched();
  102f23:	e8 00 00 00 00       	call   102f28 <proc_sched>

00102f28 <proc_sched>:
	
}

void gcc_noreturn
proc_sched(void)
{
  102f28:	55                   	push   %ebp
  102f29:	89 e5                	mov    %esp,%ebp
  102f2b:	83 ec 28             	sub    $0x28,%esp
			
		// if there is no ready process in queue
		// just wait

		//proc_print(ACQUIRE, NULL);
		spinlock_acquire(&queue.lock);
  102f2e:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  102f35:	e8 d3 f3 ff ff       	call   10230d <spinlock_acquire>

		if(queue.count != 0){
  102f3a:	a1 78 f4 31 00       	mov    0x31f478,%eax
  102f3f:	85 c0                	test   %eax,%eax
  102f41:	0f 84 8e 00 00 00    	je     102fd5 <proc_sched+0xad>
			// if there is just one ready process
			if(queue.count == 1){
  102f47:	a1 78 f4 31 00       	mov    0x31f478,%eax
  102f4c:	83 f8 01             	cmp    $0x1,%eax
  102f4f:	75 28                	jne    102f79 <proc_sched+0x51>
				//cprintf("in sched queue.count == 1\n");
				run = queue.head;
  102f51:	a1 7c f4 31 00       	mov    0x31f47c,%eax
  102f56:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.head = queue.tail = NULL;
  102f59:	c7 05 80 f4 31 00 00 	movl   $0x0,0x31f480
  102f60:	00 00 00 
  102f63:	a1 80 f4 31 00       	mov    0x31f480,%eax
  102f68:	a3 7c f4 31 00       	mov    %eax,0x31f47c
				queue.count = 0;	
  102f6d:	c7 05 78 f4 31 00 00 	movl   $0x0,0x31f478
  102f74:	00 00 00 
  102f77:	eb 45                	jmp    102fbe <proc_sched+0x96>
			
			
			// if there is more than one ready processes
			else{
				//cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
  102f79:	a1 7c f4 31 00       	mov    0x31f47c,%eax
  102f7e:	89 45 f4             	mov    %eax,-0xc(%ebp)
				while(before_tail->readynext != queue.tail){
  102f81:	eb 0c                	jmp    102f8f <proc_sched+0x67>
					before_tail = before_tail->readynext;
  102f83:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f86:	8b 80 44 04 00 00    	mov    0x444(%eax),%eax
  102f8c:	89 45 f4             	mov    %eax,-0xc(%ebp)
			
			// if there is more than one ready processes
			else{
				//cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
				while(before_tail->readynext != queue.tail){
  102f8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f92:	8b 90 44 04 00 00    	mov    0x444(%eax),%edx
  102f98:	a1 80 f4 31 00       	mov    0x31f480,%eax
  102f9d:	39 c2                	cmp    %eax,%edx
  102f9f:	75 e2                	jne    102f83 <proc_sched+0x5b>
					before_tail = before_tail->readynext;
				}	
				run = queue.tail;
  102fa1:	a1 80 f4 31 00       	mov    0x31f480,%eax
  102fa6:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.tail = before_tail;
  102fa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102fac:	a3 80 f4 31 00       	mov    %eax,0x31f480
				queue.count--;				
  102fb1:	a1 78 f4 31 00       	mov    0x31f478,%eax
  102fb6:	83 e8 01             	sub    $0x1,%eax
  102fb9:	a3 78 f4 31 00       	mov    %eax,0x31f478
				queue.count--;
			}
			*/
			
	
			spinlock_release(&queue.lock);
  102fbe:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  102fc5:	e8 b0 f3 ff ff       	call   10237a <spinlock_release>
			proc_run(run);
  102fca:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102fcd:	89 04 24             	mov    %eax,(%esp)
  102fd0:	e8 16 00 00 00       	call   102feb <proc_run>
		}
		spinlock_release(&queue.lock);
  102fd5:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  102fdc:	e8 99 f3 ff ff       	call   10237a <spinlock_release>
		pause();
  102fe1:	e8 b7 f9 ff ff       	call   10299d <pause>
	}
  102fe6:	e9 43 ff ff ff       	jmp    102f2e <proc_sched+0x6>

00102feb <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  102feb:	55                   	push   %ebp
  102fec:	89 e5                	mov    %esp,%ebp
  102fee:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");

	//cprintf("proc %x is running on cpu:%d\n", p, cpu_cur()->id);
	
	if(p == NULL)
  102ff1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102ff5:	75 1c                	jne    103013 <proc_run+0x28>
		panic("proc_run's p is null!");
  102ff7:	c7 44 24 08 c4 8e 10 	movl   $0x108ec4,0x8(%esp)
  102ffe:	00 
  102fff:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
  103006:	00 
  103007:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  10300e:	e8 6e d4 ff ff       	call   100481 <debug_panic>

	assert(p->state == PROC_READY);
  103013:	8b 45 08             	mov    0x8(%ebp),%eax
  103016:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  10301c:	83 f8 01             	cmp    $0x1,%eax
  10301f:	74 24                	je     103045 <proc_run+0x5a>
  103021:	c7 44 24 0c da 8e 10 	movl   $0x108eda,0xc(%esp)
  103028:	00 
  103029:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  103030:	00 
  103031:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  103038:	00 
  103039:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  103040:	e8 3c d4 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  103045:	8b 45 08             	mov    0x8(%ebp),%eax
  103048:	89 04 24             	mov    %eax,(%esp)
  10304b:	e8 bd f2 ff ff       	call   10230d <spinlock_acquire>

	cpu* c = cpu_cur();
  103050:	e8 4f f9 ff ff       	call   1029a4 <cpu_cur>
  103055:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->proc = p;
  103058:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10305b:	8b 55 08             	mov    0x8(%ebp),%edx
  10305e:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	p->state = PROC_RUN;
  103064:	8b 45 08             	mov    0x8(%ebp),%eax
  103067:	c7 80 40 04 00 00 02 	movl   $0x2,0x440(%eax)
  10306e:	00 00 00 
	p->runcpu = c;
  103071:	8b 45 08             	mov    0x8(%ebp),%eax
  103074:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103077:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  10307d:	8b 45 08             	mov    0x8(%ebp),%eax
  103080:	89 04 24             	mov    %eax,(%esp)
  103083:	e8 f2 f2 ff ff       	call   10237a <spinlock_release>

	//cprintf("eip = %d\n", p->sv.tf.eip);
	
	trap_return(&p->sv.tf);
  103088:	8b 45 08             	mov    0x8(%ebp),%eax
  10308b:	05 50 04 00 00       	add    $0x450,%eax
  103090:	89 04 24             	mov    %eax,(%esp)
  103093:	e8 58 90 00 00       	call   10c0f0 <trap_return>

00103098 <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  103098:	55                   	push   %ebp
  103099:	89 e5                	mov    %esp,%ebp
  10309b:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_yield not implemented");

 	//cprintf("in yield\n");
	proc* cur_proc = cpu_cur()->proc;
  10309e:	e8 01 f9 ff ff       	call   1029a4 <cpu_cur>
  1030a3:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030a9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	proc_save(cur_proc, tf, 1);
  1030ac:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1030b3:	00 
  1030b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1030b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1030bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030be:	89 04 24             	mov    %eax,(%esp)
  1030c1:	e8 ed fc ff ff       	call   102db3 <proc_save>
	proc_ready(cur_proc);
  1030c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1030c9:	89 04 24             	mov    %eax,(%esp)
  1030cc:	e8 ff fb ff ff       	call   102cd0 <proc_ready>
	proc_sched();
  1030d1:	e8 52 fe ff ff       	call   102f28 <proc_sched>

001030d6 <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  1030d6:	55                   	push   %ebp
  1030d7:	89 e5                	mov    %esp,%ebp
  1030d9:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_ret not implemented");

	proc* proc_child = proc_cur();
  1030dc:	e8 c3 f8 ff ff       	call   1029a4 <cpu_cur>
  1030e1:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_parent = proc_child->parent;
  1030ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030ed:	8b 40 3c             	mov    0x3c(%eax),%eax
  1030f0:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child->state != PROC_STOP);
  1030f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030f6:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  1030fc:	85 c0                	test   %eax,%eax
  1030fe:	75 24                	jne    103124 <proc_ret+0x4e>
  103100:	c7 44 24 0c f4 8e 10 	movl   $0x108ef4,0xc(%esp)
  103107:	00 
  103108:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  10310f:	00 
  103110:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
  103117:	00 
  103118:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  10311f:	e8 5d d3 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  103124:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103127:	89 04 24             	mov    %eax,(%esp)
  10312a:	e8 de f1 ff ff       	call   10230d <spinlock_acquire>
	proc_child->state = PROC_STOP;
  10312f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103132:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  103139:	00 00 00 
	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  10313c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10313f:	89 04 24             	mov    %eax,(%esp)
  103142:	e8 33 f2 ff ff       	call   10237a <spinlock_release>

	proc_save(proc_child, tf, entry);
  103147:	8b 45 0c             	mov    0xc(%ebp),%eax
  10314a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10314e:	8b 45 08             	mov    0x8(%ebp),%eax
  103151:	89 44 24 04          	mov    %eax,0x4(%esp)
  103155:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103158:	89 04 24             	mov    %eax,(%esp)
  10315b:	e8 53 fc ff ff       	call   102db3 <proc_save>

	if((proc_parent->state == PROC_WAIT) && (proc_parent->waitchild == proc_child) )
  103160:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103163:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103169:	83 f8 03             	cmp    $0x3,%eax
  10316c:	75 19                	jne    103187 <proc_ret+0xb1>
  10316e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103171:	8b 80 4c 04 00 00    	mov    0x44c(%eax),%eax
  103177:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10317a:	75 0b                	jne    103187 <proc_ret+0xb1>
		proc_ready(proc_parent);
  10317c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10317f:	89 04 24             	mov    %eax,(%esp)
  103182:	e8 49 fb ff ff       	call   102cd0 <proc_ready>

	proc_sched();
  103187:	e8 9c fd ff ff       	call   102f28 <proc_sched>

0010318c <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  10318c:	55                   	push   %ebp
  10318d:	89 e5                	mov    %esp,%ebp
  10318f:	57                   	push   %edi
  103190:	56                   	push   %esi
  103191:	53                   	push   %ebx
  103192:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  103198:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10319f:	00 00 00 
  1031a2:	e9 06 01 00 00       	jmp    1032ad <proc_check+0x121>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  1031a7:	b8 90 ac 11 00       	mov    $0x11ac90,%eax
  1031ac:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  1031b2:	83 c2 01             	add    $0x1,%edx
  1031b5:	c1 e2 0c             	shl    $0xc,%edx
  1031b8:	01 d0                	add    %edx,%eax
  1031ba:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		*--esp = i;	// push argument to child() function
  1031c0:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  1031c7:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  1031cd:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  1031d3:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  1031d5:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  1031dc:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  1031e2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  1031e8:	b8 c5 36 10 00       	mov    $0x1036c5,%eax
  1031ed:	a3 78 aa 11 00       	mov    %eax,0x11aa78
		child_state.tf.esp = (uint32_t) esp;
  1031f2:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  1031f8:	a3 84 aa 11 00       	mov    %eax,0x11aa84

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  1031fd:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103203:	89 44 24 04          	mov    %eax,0x4(%esp)
  103207:	c7 04 24 13 8f 10 00 	movl   $0x108f13,(%esp)
  10320e:	e8 4c 49 00 00       	call   107b5f <cprintf>

		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  103213:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103219:	0f b7 d0             	movzwl %ax,%edx
  10321c:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  103223:	7f 07                	jg     10322c <proc_check+0xa0>
  103225:	b8 10 10 00 00       	mov    $0x1010,%eax
  10322a:	eb 05                	jmp    103231 <proc_check+0xa5>
  10322c:	b8 00 10 00 00       	mov    $0x1000,%eax
  103231:	89 85 54 ff ff ff    	mov    %eax,-0xac(%ebp)
  103237:	66 89 95 52 ff ff ff 	mov    %dx,-0xae(%ebp)
  10323e:	c7 85 4c ff ff ff 40 	movl   $0x11aa40,-0xb4(%ebp)
  103245:	aa 11 00 
  103248:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
  10324f:	00 00 00 
  103252:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
  103259:	00 00 00 
  10325c:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
  103263:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103266:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
  10326c:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10326f:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
  103275:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
  10327c:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
  103282:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
  103288:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
  10328e:	cd 30                	int    $0x30
			NULL, NULL, 0);
		
		cprintf("i == %d complete!\n", i);
  103290:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103296:	89 44 24 04          	mov    %eax,0x4(%esp)
  10329a:	c7 04 24 26 8f 10 00 	movl   $0x108f26,(%esp)
  1032a1:	e8 b9 48 00 00       	call   107b5f <cprintf>
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  1032a6:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  1032ad:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  1032b4:	0f 8e ed fe ff ff    	jle    1031a7 <proc_check+0x1b>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  1032ba:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  1032c1:	00 00 00 
  1032c4:	e9 89 00 00 00       	jmp    103352 <proc_check+0x1c6>
		cprintf("waiting for child %d\n", i);
  1032c9:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1032cf:	89 44 24 04          	mov    %eax,0x4(%esp)
  1032d3:	c7 04 24 39 8f 10 00 	movl   $0x108f39,(%esp)
  1032da:	e8 80 48 00 00       	call   107b5f <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  1032df:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1032e5:	0f b7 c0             	movzwl %ax,%eax
  1032e8:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
  1032ef:	10 00 00 
  1032f2:	66 89 85 6a ff ff ff 	mov    %ax,-0x96(%ebp)
  1032f9:	c7 85 64 ff ff ff 40 	movl   $0x11aa40,-0x9c(%ebp)
  103300:	aa 11 00 
  103303:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
  10330a:	00 00 00 
  10330d:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
  103314:	00 00 00 
  103317:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
  10331e:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103321:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
  103327:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10332a:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
  103330:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
  103337:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
  10333d:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
  103343:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
  103349:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  10334b:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103352:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  103359:	0f 8e 6a ff ff ff    	jle    1032c9 <proc_check+0x13d>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  10335f:	c7 04 24 50 8f 10 00 	movl   $0x108f50,(%esp)
  103366:	e8 f4 47 00 00       	call   107b5f <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  10336b:	c7 04 24 78 8f 10 00 	movl   $0x108f78,(%esp)
  103372:	e8 e8 47 00 00       	call   107b5f <cprintf>
	for (i = 0; i < 4; i++) {
  103377:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10337e:	00 00 00 
  103381:	eb 7d                	jmp    103400 <proc_check+0x274>
		cprintf("spawning child %d\n", i);
  103383:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103389:	89 44 24 04          	mov    %eax,0x4(%esp)
  10338d:	c7 04 24 13 8f 10 00 	movl   $0x108f13,(%esp)
  103394:	e8 c6 47 00 00       	call   107b5f <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  103399:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10339f:	0f b7 c0             	movzwl %ax,%eax
  1033a2:	c7 45 84 10 00 00 00 	movl   $0x10,-0x7c(%ebp)
  1033a9:	66 89 45 82          	mov    %ax,-0x7e(%ebp)
  1033ad:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  1033b4:	00 00 00 
  1033b7:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
  1033be:	00 00 00 
  1033c1:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
  1033c8:	00 00 00 
  1033cb:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
  1033d2:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1033d5:	8b 45 84             	mov    -0x7c(%ebp),%eax
  1033d8:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1033db:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
  1033e1:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
  1033e5:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
  1033eb:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
  1033f1:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
  1033f7:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  1033f9:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103400:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103407:	0f 8e 76 ff ff ff    	jle    103383 <proc_check+0x1f7>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
  10340d:	c7 04 24 9c 8f 10 00 	movl   $0x108f9c,(%esp)
  103414:	e8 46 47 00 00       	call   107b5f <cprintf>
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103419:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103420:	00 00 00 
  103423:	eb 4f                	jmp    103474 <proc_check+0x2e8>
		sys_get(0, i, NULL, NULL, NULL, 0);
  103425:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10342b:	0f b7 c0             	movzwl %ax,%eax
  10342e:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  103435:	66 89 45 9a          	mov    %ax,-0x66(%ebp)
  103439:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
  103440:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  103447:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
  10344e:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103455:	8b 45 9c             	mov    -0x64(%ebp),%eax
  103458:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10345b:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
  10345e:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
  103462:	8b 75 90             	mov    -0x70(%ebp),%esi
  103465:	8b 7d 8c             	mov    -0x74(%ebp),%edi
  103468:	8b 4d 88             	mov    -0x78(%ebp),%ecx
  10346b:	cd 30                	int    $0x30
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  10346d:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103474:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  10347b:	7e a8                	jle    103425 <proc_check+0x299>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  10347d:	c7 04 24 c4 8f 10 00 	movl   $0x108fc4,(%esp)
  103484:	e8 d6 46 00 00       	call   107b5f <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  103489:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103490:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103493:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103499:	0f b7 c0             	movzwl %ax,%eax
  10349c:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
  1034a3:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
  1034a7:	c7 45 ac 40 aa 11 00 	movl   $0x11aa40,-0x54(%ebp)
  1034ae:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  1034b5:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  1034bc:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1034c3:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  1034c6:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1034c9:	8b 5d ac             	mov    -0x54(%ebp),%ebx
  1034cc:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
  1034d0:	8b 75 a8             	mov    -0x58(%ebp),%esi
  1034d3:	8b 7d a4             	mov    -0x5c(%ebp),%edi
  1034d6:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  1034d9:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  1034db:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  1034e0:	85 c0                	test   %eax,%eax
  1034e2:	74 24                	je     103508 <proc_check+0x37c>
  1034e4:	c7 44 24 0c e9 8f 10 	movl   $0x108fe9,0xc(%esp)
  1034eb:	00 
  1034ec:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  1034f3:	00 
  1034f4:	c7 44 24 04 96 01 00 	movl   $0x196,0x4(%esp)
  1034fb:	00 
  1034fc:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  103503:	e8 79 cf ff ff       	call   100481 <debug_panic>
	cprintf("============== tag 1 \n");
  103508:	c7 04 24 fb 8f 10 00 	movl   $0x108ffb,(%esp)
  10350f:	e8 4b 46 00 00       	call   107b5f <cprintf>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  103514:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10351a:	0f b7 c0             	movzwl %ax,%eax
  10351d:	c7 45 cc 10 10 00 00 	movl   $0x1010,-0x34(%ebp)
  103524:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
  103528:	c7 45 c4 40 aa 11 00 	movl   $0x11aa40,-0x3c(%ebp)
  10352f:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
  103536:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  10353d:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103544:	8b 45 cc             	mov    -0x34(%ebp),%eax
  103547:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10354a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
  10354d:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  103551:	8b 75 c0             	mov    -0x40(%ebp),%esi
  103554:	8b 7d bc             	mov    -0x44(%ebp),%edi
  103557:	8b 4d b8             	mov    -0x48(%ebp),%ecx
  10355a:	cd 30                	int    $0x30
		//cprintf("(1). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10355c:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103562:	0f b7 c0             	movzwl %ax,%eax
  103565:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  10356c:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
  103570:	c7 45 dc 40 aa 11 00 	movl   $0x11aa40,-0x24(%ebp)
  103577:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10357e:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  103585:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10358c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10358f:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103592:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  103595:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  103599:	8b 75 d8             	mov    -0x28(%ebp),%esi
  10359c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  10359f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  1035a2:	cd 30                	int    $0x30
		//cprintf("(2). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		cprintf("recovargs 0x%x\n",recovargs);
  1035a4:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  1035a9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035ad:	c7 04 24 12 90 10 00 	movl   $0x109012,(%esp)
  1035b4:	e8 a6 45 00 00       	call   107b5f <cprintf>
		
		if (recovargs) {	// trap recovery needed
  1035b9:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  1035be:	85 c0                	test   %eax,%eax
  1035c0:	74 55                	je     103617 <proc_check+0x48b>
			cprintf("i = %d\n", i);
  1035c2:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1035c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035cc:	c7 04 24 22 90 10 00 	movl   $0x109022,(%esp)
  1035d3:	e8 87 45 00 00       	call   107b5f <cprintf>
			trap_check_args *argss = recovargs;
  1035d8:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  1035dd:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)
			cprintf("recover from trap %d\n",
  1035e3:	a1 70 aa 11 00       	mov    0x11aa70,%eax
  1035e8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035ec:	c7 04 24 2a 90 10 00 	movl   $0x10902a,(%esp)
  1035f3:	e8 67 45 00 00       	call   107b5f <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) argss->reip;
  1035f8:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  1035fe:	8b 00                	mov    (%eax),%eax
  103600:	a3 78 aa 11 00       	mov    %eax,0x11aa78
			argss->trapno = child_state.tf.trapno;
  103605:	a1 70 aa 11 00       	mov    0x11aa70,%eax
  10360a:	89 c2                	mov    %eax,%edx
  10360c:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  103612:	89 50 04             	mov    %edx,0x4(%eax)
  103615:	eb 2e                	jmp    103645 <proc_check+0x4b9>
			//cprintf(">>>>>args->trapno = %d, child_state.tf.trapno = %d\n", 
			//	args->trapno, child_state.tf.trapno);
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  103617:	a1 70 aa 11 00       	mov    0x11aa70,%eax
  10361c:	83 f8 30             	cmp    $0x30,%eax
  10361f:	74 24                	je     103645 <proc_check+0x4b9>
  103621:	c7 44 24 0c 40 90 10 	movl   $0x109040,0xc(%esp)
  103628:	00 
  103629:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  103630:	00 
  103631:	c7 44 24 04 a9 01 00 	movl   $0x1a9,0x4(%esp)
  103638:	00 
  103639:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  103640:	e8 3c ce ff ff       	call   100481 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  103645:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10364b:	8d 50 01             	lea    0x1(%eax),%edx
  10364e:	89 d0                	mov    %edx,%eax
  103650:	c1 f8 1f             	sar    $0x1f,%eax
  103653:	c1 e8 1e             	shr    $0x1e,%eax
  103656:	01 c2                	add    %eax,%edx
  103658:	83 e2 03             	and    $0x3,%edx
  10365b:	89 d1                	mov    %edx,%ecx
  10365d:	29 c1                	sub    %eax,%ecx
  10365f:	89 c8                	mov    %ecx,%eax
  103661:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  103667:	a1 70 aa 11 00       	mov    0x11aa70,%eax
  10366c:	83 f8 30             	cmp    $0x30,%eax
  10366f:	0f 85 9f fe ff ff    	jne    103514 <proc_check+0x388>
	assert(recovargs == NULL);
  103675:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  10367a:	85 c0                	test   %eax,%eax
  10367c:	74 24                	je     1036a2 <proc_check+0x516>
  10367e:	c7 44 24 0c e9 8f 10 	movl   $0x108fe9,0xc(%esp)
  103685:	00 
  103686:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  10368d:	00 
  10368e:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
  103695:	00 
  103696:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  10369d:	e8 df cd ff ff       	call   100481 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  1036a2:	c7 04 24 64 90 10 00 	movl   $0x109064,(%esp)
  1036a9:	e8 b1 44 00 00       	call   107b5f <cprintf>

	cprintf("proc_check() succeeded!\n");
  1036ae:	c7 04 24 91 90 10 00 	movl   $0x109091,(%esp)
  1036b5:	e8 a5 44 00 00       	call   107b5f <cprintf>
}
  1036ba:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  1036c0:	5b                   	pop    %ebx
  1036c1:	5e                   	pop    %esi
  1036c2:	5f                   	pop    %edi
  1036c3:	5d                   	pop    %ebp
  1036c4:	c3                   	ret    

001036c5 <child>:

static void child(int n)
{
  1036c5:	55                   	push   %ebp
  1036c6:	89 e5                	mov    %esp,%ebp
  1036c8:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  1036cb:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  1036cf:	7f 64                	jg     103735 <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  1036d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1036d8:	eb 4e                	jmp    103728 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  1036da:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1036dd:	89 44 24 08          	mov    %eax,0x8(%esp)
  1036e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1036e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036e8:	c7 04 24 aa 90 10 00 	movl   $0x1090aa,(%esp)
  1036ef:	e8 6b 44 00 00       	call   107b5f <cprintf>
			while (pingpong != n){
  1036f4:	eb 05                	jmp    1036fb <child+0x36>
				//cprintf("in pingpong = %d\n", pingpong);
				pause();
  1036f6:	e8 a2 f2 ff ff       	call   10299d <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n){
  1036fb:	8b 55 08             	mov    0x8(%ebp),%edx
  1036fe:	a1 90 ec 11 00       	mov    0x11ec90,%eax
  103703:	39 c2                	cmp    %eax,%edx
  103705:	75 ef                	jne    1036f6 <child+0x31>
				//cprintf("in pingpong = %d\n", pingpong);
				pause();
			}
			xchg(&pingpong, !pingpong);
  103707:	a1 90 ec 11 00       	mov    0x11ec90,%eax
  10370c:	85 c0                	test   %eax,%eax
  10370e:	0f 94 c0             	sete   %al
  103711:	0f b6 c0             	movzbl %al,%eax
  103714:	89 44 24 04          	mov    %eax,0x4(%esp)
  103718:	c7 04 24 90 ec 11 00 	movl   $0x11ec90,(%esp)
  10371f:	e8 4e f2 ff ff       	call   102972 <xchg>
{
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  103724:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  103728:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  10372c:	7e ac                	jle    1036da <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  10372e:	b8 03 00 00 00       	mov    $0x3,%eax
  103733:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103735:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  10373c:	eb 47                	jmp    103785 <child+0xc0>
		//cprintf("in child %d count %d\n", n, i);
		cprintf("child num:%d\n", queue.count);
  10373e:	a1 78 f4 31 00       	mov    0x31f478,%eax
  103743:	89 44 24 04          	mov    %eax,0x4(%esp)
  103747:	c7 04 24 c0 90 10 00 	movl   $0x1090c0,(%esp)
  10374e:	e8 0c 44 00 00       	call   107b5f <cprintf>
		
		while (pingpong != n){
  103753:	eb 05                	jmp    10375a <child+0x95>
			//cprintf("in pingpong = %d\n", pingpong);
			pause();
  103755:	e8 43 f2 ff ff       	call   10299d <pause>
	int i;
	for (i = 0; i < 10; i++) {
		//cprintf("in child %d count %d\n", n, i);
		cprintf("child num:%d\n", queue.count);
		
		while (pingpong != n){
  10375a:	8b 55 08             	mov    0x8(%ebp),%edx
  10375d:	a1 90 ec 11 00       	mov    0x11ec90,%eax
  103762:	39 c2                	cmp    %eax,%edx
  103764:	75 ef                	jne    103755 <child+0x90>
			//cprintf("in pingpong = %d\n", pingpong);
			pause();
		}
		xchg(&pingpong, (pingpong + 1) % 4);
  103766:	a1 90 ec 11 00       	mov    0x11ec90,%eax
  10376b:	83 c0 01             	add    $0x1,%eax
  10376e:	83 e0 03             	and    $0x3,%eax
  103771:	89 44 24 04          	mov    %eax,0x4(%esp)
  103775:	c7 04 24 90 ec 11 00 	movl   $0x11ec90,(%esp)
  10377c:	e8 f1 f1 ff ff       	call   102972 <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103781:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103785:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  103789:	7e b3                	jle    10373e <child+0x79>
  10378b:	b8 03 00 00 00       	mov    $0x3,%eax
  103790:	cd 30                	int    $0x30
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...

	cprintf("child get last test\n");
  103792:	c7 04 24 ce 90 10 00 	movl   $0x1090ce,(%esp)
  103799:	e8 c1 43 00 00       	call   107b5f <cprintf>
	if (n == 0) {
  10379e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1037a2:	75 6d                	jne    103811 <child+0x14c>
		assert(recovargs == NULL);
  1037a4:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  1037a9:	85 c0                	test   %eax,%eax
  1037ab:	74 24                	je     1037d1 <child+0x10c>
  1037ad:	c7 44 24 0c e9 8f 10 	movl   $0x108fe9,0xc(%esp)
  1037b4:	00 
  1037b5:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  1037bc:	00 
  1037bd:	c7 44 24 04 d9 01 00 	movl   $0x1d9,0x4(%esp)
  1037c4:	00 
  1037c5:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  1037cc:	e8 b0 cc ff ff       	call   100481 <debug_panic>
		trap_check(&recovargs);
  1037d1:	c7 04 24 94 ec 11 00 	movl   $0x11ec94,(%esp)
  1037d8:	e8 50 e2 ff ff       	call   101a2d <trap_check>
		assert(recovargs == NULL);
  1037dd:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  1037e2:	85 c0                	test   %eax,%eax
  1037e4:	74 24                	je     10380a <child+0x145>
  1037e6:	c7 44 24 0c e9 8f 10 	movl   $0x108fe9,0xc(%esp)
  1037ed:	00 
  1037ee:	c7 44 24 08 46 8d 10 	movl   $0x108d46,0x8(%esp)
  1037f5:	00 
  1037f6:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
  1037fd:	00 
  1037fe:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  103805:	e8 77 cc ff ff       	call   100481 <debug_panic>
  10380a:	b8 03 00 00 00       	mov    $0x3,%eax
  10380f:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  103811:	c7 44 24 08 e4 90 10 	movl   $0x1090e4,0x8(%esp)
  103818:	00 
  103819:	c7 44 24 04 df 01 00 	movl   $0x1df,0x4(%esp)
  103820:	00 
  103821:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  103828:	e8 54 cc ff ff       	call   100481 <debug_panic>

0010382d <grandchild>:
}

static void grandchild(int n)
{
  10382d:	55                   	push   %ebp
  10382e:	89 e5                	mov    %esp,%ebp
  103830:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  103833:	c7 44 24 08 08 91 10 	movl   $0x109108,0x8(%esp)
  10383a:	00 
  10383b:	c7 44 24 04 e4 01 00 	movl   $0x1e4,0x4(%esp)
  103842:	00 
  103843:	c7 04 24 a6 8d 10 00 	movl   $0x108da6,(%esp)
  10384a:	e8 32 cc ff ff       	call   100481 <debug_panic>

0010384f <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10384f:	55                   	push   %ebp
  103850:	89 e5                	mov    %esp,%ebp
  103852:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103855:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  103858:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10385b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10385e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103861:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103866:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  103869:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10386c:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103872:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103877:	74 24                	je     10389d <cpu_cur+0x4e>
  103879:	c7 44 24 0c 34 91 10 	movl   $0x109134,0xc(%esp)
  103880:	00 
  103881:	c7 44 24 08 4a 91 10 	movl   $0x10914a,0x8(%esp)
  103888:	00 
  103889:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103890:	00 
  103891:	c7 04 24 5f 91 10 00 	movl   $0x10915f,(%esp)
  103898:	e8 e4 cb ff ff       	call   100481 <debug_panic>
	return c;
  10389d:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1038a0:	c9                   	leave  
  1038a1:	c3                   	ret    

001038a2 <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  1038a2:	55                   	push   %ebp
  1038a3:	89 e5                	mov    %esp,%ebp
  1038a5:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  1038a8:	c7 44 24 08 6c 91 10 	movl   $0x10916c,0x8(%esp)
  1038af:	00 
  1038b0:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  1038b7:	00 
  1038b8:	c7 04 24 87 91 10 00 	movl   $0x109187,(%esp)
  1038bf:	e8 bd cb ff ff       	call   100481 <debug_panic>

001038c4 <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  1038c4:	55                   	push   %ebp
  1038c5:	89 e5                	mov    %esp,%ebp
  1038c7:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  1038ca:	c7 44 24 08 96 91 10 	movl   $0x109196,0x8(%esp)
  1038d1:	00 
  1038d2:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  1038d9:	00 
  1038da:	c7 04 24 87 91 10 00 	movl   $0x109187,(%esp)
  1038e1:	e8 9b cb ff ff       	call   100481 <debug_panic>

001038e6 <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  1038e6:	55                   	push   %ebp
  1038e7:	89 e5                	mov    %esp,%ebp
  1038e9:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  1038ec:	c7 44 24 08 b4 91 10 	movl   $0x1091b4,0x8(%esp)
  1038f3:	00 
  1038f4:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  1038fb:	00 
  1038fc:	c7 04 24 87 91 10 00 	movl   $0x109187,(%esp)
  103903:	e8 79 cb ff ff       	call   100481 <debug_panic>

00103908 <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  103908:	55                   	push   %ebp
  103909:	89 e5                	mov    %esp,%ebp
  10390b:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  10390e:	8b 45 18             	mov    0x18(%ebp),%eax
  103911:	89 44 24 08          	mov    %eax,0x8(%esp)
  103915:	8b 45 14             	mov    0x14(%ebp),%eax
  103918:	89 44 24 04          	mov    %eax,0x4(%esp)
  10391c:	8b 45 08             	mov    0x8(%ebp),%eax
  10391f:	89 04 24             	mov    %eax,(%esp)
  103922:	e8 bf ff ff ff       	call   1038e6 <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  103927:	c7 44 24 08 d0 91 10 	movl   $0x1091d0,0x8(%esp)
  10392e:	00 
  10392f:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  103936:	00 
  103937:	c7 04 24 87 91 10 00 	movl   $0x109187,(%esp)
  10393e:	e8 3e cb ff ff       	call   100481 <debug_panic>

00103943 <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  103943:	55                   	push   %ebp
  103944:	89 e5                	mov    %esp,%ebp
  103946:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  103949:	8b 45 08             	mov    0x8(%ebp),%eax
  10394c:	8b 40 10             	mov    0x10(%eax),%eax
  10394f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103953:	c7 04 24 f4 91 10 00 	movl   $0x1091f4,(%esp)
  10395a:	e8 00 42 00 00       	call   107b5f <cprintf>

	trap_return(tf);	// syscall completed
  10395f:	8b 45 08             	mov    0x8(%ebp),%eax
  103962:	89 04 24             	mov    %eax,(%esp)
  103965:	e8 86 87 00 00       	call   10c0f0 <trap_return>

0010396a <do_put>:
}


static void
do_put(trapframe *tf, uint32_t cmd)
{	
  10396a:	55                   	push   %ebp
  10396b:	89 e5                	mov    %esp,%ebp
  10396d:	83 ec 28             	sub    $0x28,%esp
	cprintf("process %p is in do_put()\n", proc_cur());
  103970:	e8 da fe ff ff       	call   10384f <cpu_cur>
  103975:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10397b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10397f:	c7 04 24 f7 91 10 00 	movl   $0x1091f7,(%esp)
  103986:	e8 d4 41 00 00       	call   107b5f <cprintf>
	
	procstate* ps = (procstate*)tf->regs.ebx;
  10398b:	8b 45 08             	mov    0x8(%ebp),%eax
  10398e:	8b 40 10             	mov    0x10(%eax),%eax
  103991:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint16_t child_num = tf->regs.edx;
  103994:	8b 45 08             	mov    0x8(%ebp),%eax
  103997:	8b 40 14             	mov    0x14(%eax),%eax
  10399a:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
	proc* proc_parent = proc_cur();
  10399e:	e8 ac fe ff ff       	call   10384f <cpu_cur>
  1039a3:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1039a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  1039ac:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  1039b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039b3:	83 c2 10             	add    $0x10,%edx
  1039b6:	8b 04 90             	mov    (%eax,%edx,4),%eax
  1039b9:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(proc_child == NULL){
  1039bc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1039c0:	75 38                	jne    1039fa <do_put+0x90>
		proc_child = proc_alloc(proc_parent, child_num);
  1039c2:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
  1039c6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1039ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039cd:	89 04 24             	mov    %eax,(%esp)
  1039d0:	e8 05 f1 ff ff       	call   102ada <proc_alloc>
  1039d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if(proc_child == NULL)
  1039d8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1039dc:	75 1c                	jne    1039fa <do_put+0x90>
			panic("no child proc!");
  1039de:	c7 44 24 08 12 92 10 	movl   $0x109212,0x8(%esp)
  1039e5:	00 
  1039e6:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
  1039ed:	00 
  1039ee:	c7 04 24 87 91 10 00 	movl   $0x109187,(%esp)
  1039f5:	e8 87 ca ff ff       	call   100481 <debug_panic>
	}
	
	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  1039fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039fd:	89 04 24             	mov    %eax,(%esp)
  103a00:	e8 08 e9 ff ff       	call   10230d <spinlock_acquire>
	if(proc_child->state != PROC_STOP){
  103a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a08:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103a0e:	85 c0                	test   %eax,%eax
  103a10:	74 24                	je     103a36 <do_put+0xcc>
		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  103a12:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a15:	89 04 24             	mov    %eax,(%esp)
  103a18:	e8 5d e9 ff ff       	call   10237a <spinlock_release>
		proc_wait(proc_parent, proc_child, tf);
  103a1d:	8b 45 08             	mov    0x8(%ebp),%eax
  103a20:	89 44 24 08          	mov    %eax,0x8(%esp)
  103a24:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a27:	89 44 24 04          	mov    %eax,0x4(%esp)
  103a2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103a2e:	89 04 24             	mov    %eax,(%esp)
  103a31:	e8 1b f4 ff ff       	call   102e51 <proc_wait>
	}

	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  103a36:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a39:	89 04 24             	mov    %eax,(%esp)
  103a3c:	e8 39 e9 ff ff       	call   10237a <spinlock_release>

	if(tf->regs.eax & SYS_REGS){	
  103a41:	8b 45 08             	mov    0x8(%ebp),%eax
  103a44:	8b 40 1c             	mov    0x1c(%eax),%eax
  103a47:	25 00 10 00 00       	and    $0x1000,%eax
  103a4c:	85 c0                	test   %eax,%eax
  103a4e:	0f 84 c4 00 00 00    	je     103b18 <do_put+0x1ae>
		//proc_print(ACQUIRE, proc_child);
		spinlock_acquire(&proc_child->lock);
  103a54:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a57:	89 04 24             	mov    %eax,(%esp)
  103a5a:	e8 ae e8 ff ff       	call   10230d <spinlock_acquire>
		/*
		if(((proc_child->sv.tf.eflags ^ ps->tf.eflags) | FL_USER) != FL_USER)
			panic("illegal modification of eflags!");
		*/
		
		proc_child->sv.tf.eip = ps->tf.eip;
  103a5f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a62:	8b 50 38             	mov    0x38(%eax),%edx
  103a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a68:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_child->sv.tf.esp = ps->tf.esp;
  103a6e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a71:	8b 50 44             	mov    0x44(%eax),%edx
  103a74:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a77:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
  103a7d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a80:	8b 50 08             	mov    0x8(%eax),%edx
  103a83:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a86:	89 90 58 04 00 00    	mov    %edx,0x458(%eax)
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
  103a8c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a8f:	8b 40 44             	mov    0x44(%eax),%eax
  103a92:	89 44 24 04          	mov    %eax,0x4(%esp)
  103a96:	c7 04 24 24 92 10 00 	movl   $0x109224,(%esp)
  103a9d:	e8 bd 40 00 00       	call   107b5f <cprintf>
		proc_child->sv.tf.trapno = ps->tf.trapno;
  103aa2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103aa5:	8b 50 30             	mov    0x30(%eax),%edx
  103aa8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103aab:	89 90 80 04 00 00    	mov    %edx,0x480(%eax)

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
  103ab1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ab4:	0f b7 80 8c 04 00 00 	movzwl 0x48c(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103abb:	66 83 f8 1b          	cmp    $0x1b,%ax
  103abf:	75 30                	jne    103af1 <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
  103ac1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ac4:	0f b7 80 7c 04 00 00 	movzwl 0x47c(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103acb:	66 83 f8 23          	cmp    $0x23,%ax
  103acf:	75 20                	jne    103af1 <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ad4:	0f b7 80 78 04 00 00 	movzwl 0x478(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103adb:	66 83 f8 23          	cmp    $0x23,%ax
  103adf:	75 10                	jne    103af1 <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103ae1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ae4:	0f b7 80 98 04 00 00 	movzwl 0x498(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103aeb:	66 83 f8 23          	cmp    $0x23,%ax
  103aef:	74 1c                	je     103b0d <do_put+0x1a3>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
			panic("wrong segment regs values!");
  103af1:	c7 44 24 08 46 92 10 	movl   $0x109246,0x8(%esp)
  103af8:	00 
  103af9:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  103b00:	00 
  103b01:	c7 04 24 87 91 10 00 	movl   $0x109187,(%esp)
  103b08:	e8 74 c9 ff ff       	call   100481 <debug_panic>

		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  103b0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b10:	89 04 24             	mov    %eax,(%esp)
  103b13:	e8 62 e8 ff ff       	call   10237a <spinlock_release>
	}
    if(tf->regs.eax & SYS_START){
  103b18:	8b 45 08             	mov    0x8(%ebp),%eax
  103b1b:	8b 40 1c             	mov    0x1c(%eax),%eax
  103b1e:	83 e0 10             	and    $0x10,%eax
  103b21:	85 c0                	test   %eax,%eax
  103b23:	74 0b                	je     103b30 <do_put+0x1c6>
		//cprintf("in SYS_START\n");
		proc_ready(proc_child);
  103b25:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b28:	89 04 24             	mov    %eax,(%esp)
  103b2b:	e8 a0 f1 ff ff       	call   102cd0 <proc_ready>
	}
	
	trap_return(tf);
  103b30:	8b 45 08             	mov    0x8(%ebp),%eax
  103b33:	89 04 24             	mov    %eax,(%esp)
  103b36:	e8 b5 85 00 00       	call   10c0f0 <trap_return>

00103b3b <do_get>:
}

static void
do_get(trapframe *tf, uint32_t cmd)
{	
  103b3b:	55                   	push   %ebp
  103b3c:	89 e5                	mov    %esp,%ebp
  103b3e:	83 ec 28             	sub    $0x28,%esp
	cprintf("process %p is in do_get()\n", proc_cur());
  103b41:	e8 09 fd ff ff       	call   10384f <cpu_cur>
  103b46:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103b4c:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b50:	c7 04 24 61 92 10 00 	movl   $0x109261,(%esp)
  103b57:	e8 03 40 00 00       	call   107b5f <cprintf>
	
	procstate* ps = (procstate*)tf->regs.ebx;
  103b5c:	8b 45 08             	mov    0x8(%ebp),%eax
  103b5f:	8b 40 10             	mov    0x10(%eax),%eax
  103b62:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int child_num = (int)tf->regs.edx;
  103b65:	8b 45 08             	mov    0x8(%ebp),%eax
  103b68:	8b 40 14             	mov    0x14(%eax),%eax
  103b6b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	proc* proc_parent = proc_cur();
  103b6e:	e8 dc fc ff ff       	call   10384f <cpu_cur>
  103b73:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103b79:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103b7c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103b7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b82:	83 c2 10             	add    $0x10,%edx
  103b85:	8b 04 90             	mov    (%eax,%edx,4),%eax
  103b88:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child != NULL);
  103b8b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103b8f:	75 24                	jne    103bb5 <do_get+0x7a>
  103b91:	c7 44 24 0c 7c 92 10 	movl   $0x10927c,0xc(%esp)
  103b98:	00 
  103b99:	c7 44 24 08 4a 91 10 	movl   $0x10914a,0x8(%esp)
  103ba0:	00 
  103ba1:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  103ba8:	00 
  103ba9:	c7 04 24 87 91 10 00 	movl   $0x109187,(%esp)
  103bb0:	e8 cc c8 ff ff       	call   100481 <debug_panic>

	if(proc_child->state != PROC_STOP){
  103bb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103bb8:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103bbe:	85 c0                	test   %eax,%eax
  103bc0:	74 25                	je     103be7 <do_get+0xac>
		cprintf("into proc_wait\n");
  103bc2:	c7 04 24 8f 92 10 00 	movl   $0x10928f,(%esp)
  103bc9:	e8 91 3f 00 00       	call   107b5f <cprintf>
		proc_wait(proc_parent, proc_child, tf);}
  103bce:	8b 45 08             	mov    0x8(%ebp),%eax
  103bd1:	89 44 24 08          	mov    %eax,0x8(%esp)
  103bd5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103bd8:	89 44 24 04          	mov    %eax,0x4(%esp)
  103bdc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103bdf:	89 04 24             	mov    %eax,(%esp)
  103be2:	e8 6a f2 ff ff       	call   102e51 <proc_wait>

	if(tf->regs.eax & SYS_REGS){
  103be7:	8b 45 08             	mov    0x8(%ebp),%eax
  103bea:	8b 40 1c             	mov    0x1c(%eax),%eax
  103bed:	25 00 10 00 00       	and    $0x1000,%eax
  103bf2:	85 c0                	test   %eax,%eax
  103bf4:	74 20                	je     103c16 <do_get+0xdb>
		memmove(&(ps->tf), &(proc_child->sv.tf), sizeof(trapframe));
  103bf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103bf9:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  103bff:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103c02:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  103c09:	00 
  103c0a:	89 54 24 04          	mov    %edx,0x4(%esp)
  103c0e:	89 04 24             	mov    %eax,(%esp)
  103c11:	e8 a2 41 00 00       	call   107db8 <memmove>
	}
	
	trap_return(tf);
  103c16:	8b 45 08             	mov    0x8(%ebp),%eax
  103c19:	89 04 24             	mov    %eax,(%esp)
  103c1c:	e8 cf 84 00 00       	call   10c0f0 <trap_return>

00103c21 <do_ret>:
}

static void
do_ret(trapframe *tf, uint32_t cmd)
{	
  103c21:	55                   	push   %ebp
  103c22:	89 e5                	mov    %esp,%ebp
  103c24:	83 ec 18             	sub    $0x18,%esp
	cprintf("process %p is in do_ret()\n", proc_cur());
  103c27:	e8 23 fc ff ff       	call   10384f <cpu_cur>
  103c2c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103c32:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c36:	c7 04 24 9f 92 10 00 	movl   $0x10929f,(%esp)
  103c3d:	e8 1d 3f 00 00       	call   107b5f <cprintf>
	proc_ret(tf, 1);
  103c42:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103c49:	00 
  103c4a:	8b 45 08             	mov    0x8(%ebp),%eax
  103c4d:	89 04 24             	mov    %eax,(%esp)
  103c50:	e8 81 f4 ff ff       	call   1030d6 <proc_ret>

00103c55 <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  103c55:	55                   	push   %ebp
  103c56:	89 e5                	mov    %esp,%ebp
  103c58:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  103c5b:	8b 45 08             	mov    0x8(%ebp),%eax
  103c5e:	8b 40 1c             	mov    0x1c(%eax),%eax
  103c61:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  103c64:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c67:	83 e0 0f             	and    $0xf,%eax
  103c6a:	83 f8 01             	cmp    $0x1,%eax
  103c6d:	74 25                	je     103c94 <syscall+0x3f>
  103c6f:	83 f8 01             	cmp    $0x1,%eax
  103c72:	72 0c                	jb     103c80 <syscall+0x2b>
  103c74:	83 f8 02             	cmp    $0x2,%eax
  103c77:	74 2f                	je     103ca8 <syscall+0x53>
  103c79:	83 f8 03             	cmp    $0x3,%eax
  103c7c:	74 3e                	je     103cbc <syscall+0x67>
	case SYS_PUT:	 do_put(tf, cmd); break;
	case SYS_GET:	 do_get(tf, cmd); break;
	case SYS_RET:	 do_ret(tf, cmd); break;
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
  103c7e:	eb 4f                	jmp    103ccf <syscall+0x7a>
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:	 do_cputs(tf, cmd); break;
  103c80:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c83:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c87:	8b 45 08             	mov    0x8(%ebp),%eax
  103c8a:	89 04 24             	mov    %eax,(%esp)
  103c8d:	e8 b1 fc ff ff       	call   103943 <do_cputs>
  103c92:	eb 3b                	jmp    103ccf <syscall+0x7a>
	case SYS_PUT:	 do_put(tf, cmd); break;
  103c94:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c97:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c9b:	8b 45 08             	mov    0x8(%ebp),%eax
  103c9e:	89 04 24             	mov    %eax,(%esp)
  103ca1:	e8 c4 fc ff ff       	call   10396a <do_put>
  103ca6:	eb 27                	jmp    103ccf <syscall+0x7a>
	case SYS_GET:	 do_get(tf, cmd); break;
  103ca8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103cab:	89 44 24 04          	mov    %eax,0x4(%esp)
  103caf:	8b 45 08             	mov    0x8(%ebp),%eax
  103cb2:	89 04 24             	mov    %eax,(%esp)
  103cb5:	e8 81 fe ff ff       	call   103b3b <do_get>
  103cba:	eb 13                	jmp    103ccf <syscall+0x7a>
	case SYS_RET:	 do_ret(tf, cmd); break;
  103cbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103cbf:	89 44 24 04          	mov    %eax,0x4(%esp)
  103cc3:	8b 45 08             	mov    0x8(%ebp),%eax
  103cc6:	89 04 24             	mov    %eax,(%esp)
  103cc9:	e8 53 ff ff ff       	call   103c21 <do_ret>
  103cce:	90                   	nop
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
	}
}
  103ccf:	c9                   	leave  
  103cd0:	c3                   	ret    

00103cd1 <lockadd>:
}

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  103cd1:	55                   	push   %ebp
  103cd2:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  103cd4:	8b 45 08             	mov    0x8(%ebp),%eax
  103cd7:	8b 55 0c             	mov    0xc(%ebp),%edx
  103cda:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103cdd:	f0 01 10             	lock add %edx,(%eax)
}
  103ce0:	5d                   	pop    %ebp
  103ce1:	c3                   	ret    

00103ce2 <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  103ce2:	55                   	push   %ebp
  103ce3:	89 e5                	mov    %esp,%ebp
  103ce5:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  103ce8:	8b 45 08             	mov    0x8(%ebp),%eax
  103ceb:	8b 55 0c             	mov    0xc(%ebp),%edx
  103cee:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103cf1:	f0 01 10             	lock add %edx,(%eax)
  103cf4:	0f 94 45 ff          	sete   -0x1(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  103cf8:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
  103cfc:	c9                   	leave  
  103cfd:	c3                   	ret    

00103cfe <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103cfe:	55                   	push   %ebp
  103cff:	89 e5                	mov    %esp,%ebp
  103d01:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103d04:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  103d07:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103d0a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103d0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103d10:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103d15:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  103d18:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103d1b:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103d21:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103d26:	74 24                	je     103d4c <cpu_cur+0x4e>
  103d28:	c7 44 24 0c bc 92 10 	movl   $0x1092bc,0xc(%esp)
  103d2f:	00 
  103d30:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  103d37:	00 
  103d38:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103d3f:	00 
  103d40:	c7 04 24 e7 92 10 00 	movl   $0x1092e7,(%esp)
  103d47:	e8 35 c7 ff ff       	call   100481 <debug_panic>
	return c;
  103d4c:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103d4f:	c9                   	leave  
  103d50:	c3                   	ret    

00103d51 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  103d51:	55                   	push   %ebp
  103d52:	89 e5                	mov    %esp,%ebp
  103d54:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  103d57:	e8 a2 ff ff ff       	call   103cfe <cpu_cur>
  103d5c:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  103d61:	0f 94 c0             	sete   %al
  103d64:	0f b6 c0             	movzbl %al,%eax
}
  103d67:	c9                   	leave  
  103d68:	c3                   	ret    

00103d69 <pmap_init>:
// (addresses outside of the range between VM_USERLO and VM_USERHI).
// The user part of the address space remains all PTE_ZERO until later.
//
void
pmap_init(void)
{
  103d69:	55                   	push   %ebp
  103d6a:	89 e5                	mov    %esp,%ebp
  103d6c:	83 ec 48             	sub    $0x48,%esp
	if (cpu_onboot()) {
  103d6f:	e8 dd ff ff ff       	call   103d51 <cpu_onboot>
  103d74:	85 c0                	test   %eax,%eax
  103d76:	74 5a                	je     103dd2 <pmap_init+0x69>

		
		uint32_t va;
		int i;

		for(i = 0, va = 0; i < 1024; i++, va += PTSIZE){
  103d78:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  103d7f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  103d86:	eb 41                	jmp    103dc9 <pmap_init+0x60>
			if(va >= VM_USERLO && va < VM_USERHI){
  103d88:	81 7d dc ff ff ff 3f 	cmpl   $0x3fffffff,-0x24(%ebp)
  103d8f:	76 1a                	jbe    103dab <pmap_init+0x42>
  103d91:	81 7d dc ff ff ff ef 	cmpl   $0xefffffff,-0x24(%ebp)
  103d98:	77 11                	ja     103dab <pmap_init+0x42>
				pmap_bootpdir[i] = PTE_ZERO;
  103d9a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103d9d:	ba 00 10 32 00       	mov    $0x321000,%edx
  103da2:	89 14 85 00 00 32 00 	mov    %edx,0x320000(,%eax,4)
		
		uint32_t va;
		int i;

		for(i = 0, va = 0; i < 1024; i++, va += PTSIZE){
			if(va >= VM_USERLO && va < VM_USERHI){
  103da9:	eb 13                	jmp    103dbe <pmap_init+0x55>
				pmap_bootpdir[i] = PTE_ZERO;
				//cprintf("pmap_bootpdir[%d] = %x\n", i, pmap_bootpdir[i]);
			}
			else{
				pmap_bootpdir[i] = va | PTE_P | PTE_W | PTE_PS | PTE_G;
  103dab:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103dae:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103db1:	81 ca 83 01 00 00    	or     $0x183,%edx
  103db7:	89 14 85 00 00 32 00 	mov    %edx,0x320000(,%eax,4)

		
		uint32_t va;
		int i;

		for(i = 0, va = 0; i < 1024; i++, va += PTSIZE){
  103dbe:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  103dc2:	81 45 dc 00 00 40 00 	addl   $0x400000,-0x24(%ebp)
  103dc9:	81 7d e0 ff 03 00 00 	cmpl   $0x3ff,-0x20(%ebp)
  103dd0:	7e b6                	jle    103d88 <pmap_init+0x1f>

static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
  103dd2:	0f 20 e0             	mov    %cr4,%eax
  103dd5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	return cr4;
  103dd8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
	// where LA == PA according to the page mapping structures.
	// In PIOS this is always the case for the kernel's address space,
	// so we don't have to play any special tricks as in other kernels.

	// Enable 4MB pages and global pages.
	uint32_t cr4 = rcr4();
  103ddb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	cr4 |= CR4_PSE | CR4_PGE;
  103dde:	81 4d d4 90 00 00 00 	orl    $0x90,-0x2c(%ebp)
  103de5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  103de8:	89 45 e8             	mov    %eax,-0x18(%ebp)
}

static gcc_inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
  103deb:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103dee:	0f 22 e0             	mov    %eax,%cr4
	lcr4(cr4);

	// Install the bootstrap page directory into the PDBR.
	lcr3(mem_phys(pmap_bootpdir));
  103df1:	b8 00 00 32 00       	mov    $0x320000,%eax
  103df6:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  103df9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103dfc:	0f 22 d8             	mov    %eax,%cr3

static gcc_inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
  103dff:	0f 20 c0             	mov    %cr0,%eax
  103e02:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return val;
  103e05:	8b 45 f0             	mov    -0x10(%ebp),%eax

	// Turn on paging.
	uint32_t cr0 = rcr0();
  103e08:	89 45 d8             	mov    %eax,-0x28(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_MP|CR0_TS;
  103e0b:	81 4d d8 2b 00 05 80 	orl    $0x8005002b,-0x28(%ebp)
	cr0 &= ~(CR0_EM);
  103e12:	83 65 d8 fb          	andl   $0xfffffffb,-0x28(%ebp)

	cprintf("before lcr0\n");
  103e16:	c7 04 24 f4 92 10 00 	movl   $0x1092f4,(%esp)
  103e1d:	e8 3d 3d 00 00       	call   107b5f <cprintf>
  103e22:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103e25:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
  103e28:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e2b:	0f 22 c0             	mov    %eax,%cr0
	lcr0(cr0);
	cprintf("after lcr0\n");
  103e2e:	c7 04 24 01 93 10 00 	movl   $0x109301,(%esp)
  103e35:	e8 25 3d 00 00       	call   107b5f <cprintf>

	// If we survived the lcr0, we're running with paging enabled.
	// Now check the page table management functions below.
	if (cpu_onboot())
  103e3a:	e8 12 ff ff ff       	call   103d51 <cpu_onboot>
  103e3f:	85 c0                	test   %eax,%eax
  103e41:	74 05                	je     103e48 <pmap_init+0xdf>
		pmap_check();
  103e43:	e8 3a 10 00 00       	call   104e82 <pmap_check>
}
  103e48:	c9                   	leave  
  103e49:	c3                   	ret    

00103e4a <pmap_newpdir>:
// Allocate a new page directory, initialized from the bootstrap pdir.
// Returns the new pdir with a reference count of 1.
//
pte_t *
pmap_newpdir(void)
{
  103e4a:	55                   	push   %ebp
  103e4b:	89 e5                	mov    %esp,%ebp
  103e4d:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  103e50:	e8 b8 cc ff ff       	call   100b0d <mem_alloc>
  103e55:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (pi == NULL)
  103e58:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  103e5c:	75 0a                	jne    103e68 <pmap_newpdir+0x1e>
		return NULL;
  103e5e:	b8 00 00 00 00       	mov    $0x0,%eax
  103e63:	e9 24 01 00 00       	jmp    103f8c <pmap_newpdir+0x142>
  103e68:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103e6b:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  103e6e:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  103e73:	83 c0 08             	add    $0x8,%eax
  103e76:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103e79:	76 15                	jbe    103e90 <pmap_newpdir+0x46>
  103e7b:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  103e80:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  103e86:	c1 e2 03             	shl    $0x3,%edx
  103e89:	01 d0                	add    %edx,%eax
  103e8b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103e8e:	72 24                	jb     103eb4 <pmap_newpdir+0x6a>
  103e90:	c7 44 24 0c 10 93 10 	movl   $0x109310,0xc(%esp)
  103e97:	00 
  103e98:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  103e9f:	00 
  103ea0:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  103ea7:	00 
  103ea8:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  103eaf:	e8 cd c5 ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  103eb4:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  103eb9:	ba 00 10 32 00       	mov    $0x321000,%edx
  103ebe:	c1 ea 0c             	shr    $0xc,%edx
  103ec1:	c1 e2 03             	shl    $0x3,%edx
  103ec4:	01 d0                	add    %edx,%eax
  103ec6:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103ec9:	75 24                	jne    103eef <pmap_newpdir+0xa5>
  103ecb:	c7 44 24 0c 54 93 10 	movl   $0x109354,0xc(%esp)
  103ed2:	00 
  103ed3:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  103eda:	00 
  103edb:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  103ee2:	00 
  103ee3:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  103eea:	e8 92 c5 ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  103eef:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  103ef4:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  103ef9:	c1 ea 0c             	shr    $0xc,%edx
  103efc:	c1 e2 03             	shl    $0x3,%edx
  103eff:	01 d0                	add    %edx,%eax
  103f01:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103f04:	72 3b                	jb     103f41 <pmap_newpdir+0xf7>
  103f06:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  103f0b:	ba 07 20 32 00       	mov    $0x322007,%edx
  103f10:	c1 ea 0c             	shr    $0xc,%edx
  103f13:	c1 e2 03             	shl    $0x3,%edx
  103f16:	01 d0                	add    %edx,%eax
  103f18:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103f1b:	77 24                	ja     103f41 <pmap_newpdir+0xf7>
  103f1d:	c7 44 24 0c 70 93 10 	movl   $0x109370,0xc(%esp)
  103f24:	00 
  103f25:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  103f2c:	00 
  103f2d:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  103f34:	00 
  103f35:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  103f3c:	e8 40 c5 ff ff       	call   100481 <debug_panic>

	lockadd(&pi->refcount, 1);
  103f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f44:	83 c0 04             	add    $0x4,%eax
  103f47:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103f4e:	00 
  103f4f:	89 04 24             	mov    %eax,(%esp)
  103f52:	e8 7a fd ff ff       	call   103cd1 <lockadd>
	mem_incref(pi);
	pte_t *pdir = mem_pi2ptr(pi);
  103f57:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103f5a:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  103f5f:	89 d1                	mov    %edx,%ecx
  103f61:	29 c1                	sub    %eax,%ecx
  103f63:	89 c8                	mov    %ecx,%eax
  103f65:	c1 f8 03             	sar    $0x3,%eax
  103f68:	c1 e0 0c             	shl    $0xc,%eax
  103f6b:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Initialize it from the bootstrap page directory
	assert(sizeof(pmap_bootpdir) == PAGESIZE);
	memmove(pdir, pmap_bootpdir, PAGESIZE);
  103f6e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  103f75:	00 
  103f76:	c7 44 24 04 00 00 32 	movl   $0x320000,0x4(%esp)
  103f7d:	00 
  103f7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103f81:	89 04 24             	mov    %eax,(%esp)
  103f84:	e8 2f 3e 00 00       	call   107db8 <memmove>

	return pdir;
  103f89:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  103f8c:	c9                   	leave  
  103f8d:	c3                   	ret    

00103f8e <pmap_freepdir>:

// Free a page directory, and all page tables and mappings it may contain.
void
pmap_freepdir(pageinfo *pdirpi)
{
  103f8e:	55                   	push   %ebp
  103f8f:	89 e5                	mov    %esp,%ebp
  103f91:	83 ec 18             	sub    $0x18,%esp
	pmap_remove(mem_pi2ptr(pdirpi), VM_USERLO, VM_USERHI-VM_USERLO);
  103f94:	8b 55 08             	mov    0x8(%ebp),%edx
  103f97:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  103f9c:	89 d1                	mov    %edx,%ecx
  103f9e:	29 c1                	sub    %eax,%ecx
  103fa0:	89 c8                	mov    %ecx,%eax
  103fa2:	c1 f8 03             	sar    $0x3,%eax
  103fa5:	c1 e0 0c             	shl    $0xc,%eax
  103fa8:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  103faf:	b0 
  103fb0:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  103fb7:	40 
  103fb8:	89 04 24             	mov    %eax,(%esp)
  103fbb:	e8 75 05 00 00       	call   104535 <pmap_remove>
	mem_free(pdirpi);
  103fc0:	8b 45 08             	mov    0x8(%ebp),%eax
  103fc3:	89 04 24             	mov    %eax,(%esp)
  103fc6:	e8 89 cb ff ff       	call   100b54 <mem_free>
}
  103fcb:	c9                   	leave  
  103fcc:	c3                   	ret    

00103fcd <pmap_freeptab>:

// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
  103fcd:	55                   	push   %ebp
  103fce:	89 e5                	mov    %esp,%ebp
  103fd0:	83 ec 38             	sub    $0x38,%esp
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
  103fd3:	8b 55 08             	mov    0x8(%ebp),%edx
  103fd6:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  103fdb:	89 d1                	mov    %edx,%ecx
  103fdd:	29 c1                	sub    %eax,%ecx
  103fdf:	89 c8                	mov    %ecx,%eax
  103fe1:	c1 f8 03             	sar    $0x3,%eax
  103fe4:	c1 e0 0c             	shl    $0xc,%eax
  103fe7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  103fea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103fed:	05 00 10 00 00       	add    $0x1000,%eax
  103ff2:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (; pte < ptelim; pte++) {
  103ff5:	e9 5f 01 00 00       	jmp    104159 <pmap_freeptab+0x18c>
		uint32_t pgaddr = PGADDR(*pte);
  103ffa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103ffd:	8b 00                	mov    (%eax),%eax
  103fff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104004:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (pgaddr != PTE_ZERO)
  104007:	b8 00 10 32 00       	mov    $0x321000,%eax
  10400c:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  10400f:	0f 84 40 01 00 00    	je     104155 <pmap_freeptab+0x188>
			mem_decref(mem_phys2pi(pgaddr), mem_free);
  104015:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10401a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10401d:	c1 ea 0c             	shr    $0xc,%edx
  104020:	c1 e2 03             	shl    $0x3,%edx
  104023:	01 d0                	add    %edx,%eax
  104025:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104028:	c7 45 f0 54 0b 10 00 	movl   $0x100b54,-0x10(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10402f:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104034:	83 c0 08             	add    $0x8,%eax
  104037:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10403a:	76 15                	jbe    104051 <pmap_freeptab+0x84>
  10403c:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104041:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  104047:	c1 e2 03             	shl    $0x3,%edx
  10404a:	01 d0                	add    %edx,%eax
  10404c:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10404f:	72 24                	jb     104075 <pmap_freeptab+0xa8>
  104051:	c7 44 24 0c 10 93 10 	movl   $0x109310,0xc(%esp)
  104058:	00 
  104059:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104060:	00 
  104061:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  104068:	00 
  104069:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104070:	e8 0c c4 ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  104075:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10407a:	ba 00 10 32 00       	mov    $0x321000,%edx
  10407f:	c1 ea 0c             	shr    $0xc,%edx
  104082:	c1 e2 03             	shl    $0x3,%edx
  104085:	01 d0                	add    %edx,%eax
  104087:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10408a:	75 24                	jne    1040b0 <pmap_freeptab+0xe3>
  10408c:	c7 44 24 0c 54 93 10 	movl   $0x109354,0xc(%esp)
  104093:	00 
  104094:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10409b:	00 
  10409c:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1040a3:	00 
  1040a4:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  1040ab:	e8 d1 c3 ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1040b0:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1040b5:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  1040ba:	c1 ea 0c             	shr    $0xc,%edx
  1040bd:	c1 e2 03             	shl    $0x3,%edx
  1040c0:	01 d0                	add    %edx,%eax
  1040c2:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1040c5:	72 3b                	jb     104102 <pmap_freeptab+0x135>
  1040c7:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1040cc:	ba 07 20 32 00       	mov    $0x322007,%edx
  1040d1:	c1 ea 0c             	shr    $0xc,%edx
  1040d4:	c1 e2 03             	shl    $0x3,%edx
  1040d7:	01 d0                	add    %edx,%eax
  1040d9:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1040dc:	77 24                	ja     104102 <pmap_freeptab+0x135>
  1040de:	c7 44 24 0c 70 93 10 	movl   $0x109370,0xc(%esp)
  1040e5:	00 
  1040e6:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1040ed:	00 
  1040ee:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  1040f5:	00 
  1040f6:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  1040fd:	e8 7f c3 ff ff       	call   100481 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  104102:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104105:	83 c0 04             	add    $0x4,%eax
  104108:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  10410f:	ff 
  104110:	89 04 24             	mov    %eax,(%esp)
  104113:	e8 ca fb ff ff       	call   103ce2 <lockaddz>
  104118:	84 c0                	test   %al,%al
  10411a:	74 0b                	je     104127 <pmap_freeptab+0x15a>
			freefun(pi);
  10411c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10411f:	89 04 24             	mov    %eax,(%esp)
  104122:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104125:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  104127:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10412a:	8b 40 04             	mov    0x4(%eax),%eax
  10412d:	85 c0                	test   %eax,%eax
  10412f:	79 24                	jns    104155 <pmap_freeptab+0x188>
  104131:	c7 44 24 0c a1 93 10 	movl   $0x1093a1,0xc(%esp)
  104138:	00 
  104139:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104140:	00 
  104141:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  104148:	00 
  104149:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104150:	e8 2c c3 ff ff       	call   100481 <debug_panic>
// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
	for (; pte < ptelim; pte++) {
  104155:	83 45 e4 04          	addl   $0x4,-0x1c(%ebp)
  104159:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10415c:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  10415f:	0f 82 95 fe ff ff    	jb     103ffa <pmap_freeptab+0x2d>
		uint32_t pgaddr = PGADDR(*pte);
		if (pgaddr != PTE_ZERO)
			mem_decref(mem_phys2pi(pgaddr), mem_free);
	}
	mem_free(ptabpi);
  104165:	8b 45 08             	mov    0x8(%ebp),%eax
  104168:	89 04 24             	mov    %eax,(%esp)
  10416b:	e8 e4 c9 ff ff       	call   100b54 <mem_free>
}
  104170:	c9                   	leave  
  104171:	c3                   	ret    

00104172 <pmap_walk>:
// Hint 2: the x86 MMU checks permission bits in both the page directory
// and the page table, so it's safe to leave some page permissions
// more permissive than strictly necessary.
pte_t *
pmap_walk(pde_t *pdir, uint32_t va, bool writing)
{
  104172:	55                   	push   %ebp
  104173:	89 e5                	mov    %esp,%ebp
  104175:	83 ec 38             	sub    $0x38,%esp
	assert(va >= VM_USERLO && va < VM_USERHI);
  104178:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  10417f:	76 09                	jbe    10418a <pmap_walk+0x18>
  104181:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  104188:	76 24                	jbe    1041ae <pmap_walk+0x3c>
  10418a:	c7 44 24 0c b4 93 10 	movl   $0x1093b4,0xc(%esp)
  104191:	00 
  104192:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104199:	00 
  10419a:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
  1041a1:	00 
  1041a2:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1041a9:	e8 d3 c2 ff ff       	call   100481 <debug_panic>
	// Fill in this function

	pde_t* pde;
	pte_t* pte;

	pde = &pdir[PDX(va)];
  1041ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  1041b1:	c1 e8 16             	shr    $0x16,%eax
  1041b4:	c1 e0 02             	shl    $0x2,%eax
  1041b7:	03 45 08             	add    0x8(%ebp),%eax
  1041ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	if(*pde == PTE_ZERO){
  1041bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1041c0:	8b 10                	mov    (%eax),%edx
  1041c2:	b8 00 10 32 00       	mov    $0x321000,%eax
  1041c7:	39 c2                	cmp    %eax,%edx
  1041c9:	0f 85 7e 01 00 00    	jne    10434d <pmap_walk+0x1db>
		if(writing == 0)
  1041cf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1041d3:	75 0a                	jne    1041df <pmap_walk+0x6d>
			return NULL;
  1041d5:	b8 00 00 00 00       	mov    $0x0,%eax
  1041da:	e9 8c 01 00 00       	jmp    10436b <pmap_walk+0x1f9>
		else{
			pageinfo* pi = mem_alloc();
  1041df:	e8 29 c9 ff ff       	call   100b0d <mem_alloc>
  1041e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
			
			if(pi== NULL){
  1041e7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1041eb:	75 0a                	jne    1041f7 <pmap_walk+0x85>
				return NULL;}
  1041ed:	b8 00 00 00 00       	mov    $0x0,%eax
  1041f2:	e9 74 01 00 00       	jmp    10436b <pmap_walk+0x1f9>
			
			memset(pi, 0 ,sizeof(PAGESIZE));
  1041f7:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  1041fe:	00 
  1041ff:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104206:	00 
  104207:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10420a:	89 04 24             	mov    %eax,(%esp)
  10420d:	e8 32 3b 00 00       	call   107d44 <memset>
  104212:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104215:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104218:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10421d:	83 c0 08             	add    $0x8,%eax
  104220:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104223:	76 15                	jbe    10423a <pmap_walk+0xc8>
  104225:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10422a:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  104230:	c1 e2 03             	shl    $0x3,%edx
  104233:	01 d0                	add    %edx,%eax
  104235:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104238:	72 24                	jb     10425e <pmap_walk+0xec>
  10423a:	c7 44 24 0c 10 93 10 	movl   $0x109310,0xc(%esp)
  104241:	00 
  104242:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104249:	00 
  10424a:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  104251:	00 
  104252:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104259:	e8 23 c2 ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10425e:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104263:	ba 00 10 32 00       	mov    $0x321000,%edx
  104268:	c1 ea 0c             	shr    $0xc,%edx
  10426b:	c1 e2 03             	shl    $0x3,%edx
  10426e:	01 d0                	add    %edx,%eax
  104270:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104273:	75 24                	jne    104299 <pmap_walk+0x127>
  104275:	c7 44 24 0c 54 93 10 	movl   $0x109354,0xc(%esp)
  10427c:	00 
  10427d:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104284:	00 
  104285:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  10428c:	00 
  10428d:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104294:	e8 e8 c1 ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104299:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10429e:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  1042a3:	c1 ea 0c             	shr    $0xc,%edx
  1042a6:	c1 e2 03             	shl    $0x3,%edx
  1042a9:	01 d0                	add    %edx,%eax
  1042ab:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1042ae:	72 3b                	jb     1042eb <pmap_walk+0x179>
  1042b0:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1042b5:	ba 07 20 32 00       	mov    $0x322007,%edx
  1042ba:	c1 ea 0c             	shr    $0xc,%edx
  1042bd:	c1 e2 03             	shl    $0x3,%edx
  1042c0:	01 d0                	add    %edx,%eax
  1042c2:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1042c5:	77 24                	ja     1042eb <pmap_walk+0x179>
  1042c7:	c7 44 24 0c 70 93 10 	movl   $0x109370,0xc(%esp)
  1042ce:	00 
  1042cf:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1042d6:	00 
  1042d7:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1042de:	00 
  1042df:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  1042e6:	e8 96 c1 ff ff       	call   100481 <debug_panic>

	lockadd(&pi->refcount, 1);
  1042eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1042ee:	83 c0 04             	add    $0x4,%eax
  1042f1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1042f8:	00 
  1042f9:	89 04 24             	mov    %eax,(%esp)
  1042fc:	e8 d0 f9 ff ff       	call   103cd1 <lockadd>
			mem_incref(pi);
			pte = (pte_t*)(mem_pi2ptr(pi));
  104301:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104304:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104309:	89 d1                	mov    %edx,%ecx
  10430b:	29 c1                	sub    %eax,%ecx
  10430d:	89 c8                	mov    %ecx,%eax
  10430f:	c1 f8 03             	sar    $0x3,%eax
  104312:	c1 e0 0c             	shl    $0xc,%eax
  104315:	89 45 e8             	mov    %eax,-0x18(%ebp)
			int i = 0;
  104318:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

			
			for(; i < NPTENTRIES; i++){
  10431f:	eb 14                	jmp    104335 <pmap_walk+0x1c3>
				pte[i] = PTE_ZERO;
  104321:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104324:	c1 e0 02             	shl    $0x2,%eax
  104327:	03 45 e8             	add    -0x18(%ebp),%eax
  10432a:	ba 00 10 32 00       	mov    $0x321000,%edx
  10432f:	89 10                	mov    %edx,(%eax)
			mem_incref(pi);
			pte = (pte_t*)(mem_pi2ptr(pi));
			int i = 0;

			
			for(; i < NPTENTRIES; i++){
  104331:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  104335:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
  10433c:	7e e3                	jle    104321 <pmap_walk+0x1af>
				pte[i] = PTE_ZERO;
			}


			*pde = mem_phys(pte) | PTE_P | PTE_W | PTE_U; 
  10433e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104341:	89 c2                	mov    %eax,%edx
  104343:	83 ca 07             	or     $0x7,%edx
  104346:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104349:	89 10                	mov    %edx,(%eax)
  10434b:	eb 0d                	jmp    10435a <pmap_walk+0x1e8>
			memcpy(page_table, pgtab, sizeof(PAGESIZE));
			*pde |= PTE_W;
			*/
		}
		
		pte = (pte_t*)PGADDR(*pde);
  10434d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104350:	8b 00                	mov    (%eax),%eax
  104352:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104357:	89 45 e8             	mov    %eax,-0x18(%ebp)
		
		//pte[PTX(va)] |= PTE_U;
	}


	return &pte[PTX(va)];
  10435a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10435d:	c1 e8 0c             	shr    $0xc,%eax
  104360:	25 ff 03 00 00       	and    $0x3ff,%eax
  104365:	c1 e0 02             	shl    $0x2,%eax
  104368:	03 45 e8             	add    -0x18(%ebp),%eax
}
  10436b:	c9                   	leave  
  10436c:	c3                   	ret    

0010436d <pmap_insert>:
//
// Hint: The reference solution uses pmap_walk, pmap_remove, and mem_pi2phys.
//
pte_t *
pmap_insert(pde_t *pdir, pageinfo *pi, uint32_t va, int perm)
{
  10436d:	55                   	push   %ebp
  10436e:	89 e5                	mov    %esp,%ebp
  104370:	53                   	push   %ebx
  104371:	83 ec 24             	sub    $0x24,%esp

	// get pte from pdir
	
	//cprintf("in insert pi: %p, pi->refcount = %d\n", pi, pi->refcount);

	pte_t* pte = pmap_walk(pdir, va, 1);
  104374:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10437b:	00 
  10437c:	8b 45 10             	mov    0x10(%ebp),%eax
  10437f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104383:	8b 45 08             	mov    0x8(%ebp),%eax
  104386:	89 04 24             	mov    %eax,(%esp)
  104389:	e8 e4 fd ff ff       	call   104172 <pmap_walk>
  10438e:	89 45 ec             	mov    %eax,-0x14(%ebp)


	if(pte == NULL)
  104391:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  104395:	75 0a                	jne    1043a1 <pmap_insert+0x34>
		return NULL;
  104397:	b8 00 00 00 00       	mov    $0x0,%eax
  10439c:	e9 8e 01 00 00       	jmp    10452f <pmap_insert+0x1c2>


	// if pte has been mapped
	if(*pte != PTE_ZERO){
  1043a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1043a4:	8b 10                	mov    (%eax),%edx
  1043a6:	b8 00 10 32 00       	mov    $0x321000,%eax
  1043ab:	39 c2                	cmp    %eax,%edx
  1043ad:	74 6d                	je     10441c <pmap_insert+0xaf>
		// if va has mapped to another pi, remove that pi 
		if(PGADDR(*pte) != mem_pi2phys(pi)){
  1043af:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1043b2:	8b 00                	mov    (%eax),%eax
  1043b4:	89 c1                	mov    %eax,%ecx
  1043b6:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1043bc:	8b 55 0c             	mov    0xc(%ebp),%edx
  1043bf:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1043c4:	89 d3                	mov    %edx,%ebx
  1043c6:	29 c3                	sub    %eax,%ebx
  1043c8:	89 d8                	mov    %ebx,%eax
  1043ca:	c1 f8 03             	sar    $0x3,%eax
  1043cd:	c1 e0 0c             	shl    $0xc,%eax
  1043d0:	39 c1                	cmp    %eax,%ecx
  1043d2:	74 31                	je     104405 <pmap_insert+0x98>
			cprintf("in remove\n");
  1043d4:	c7 04 24 e2 93 10 00 	movl   $0x1093e2,(%esp)
  1043db:	e8 7f 37 00 00       	call   107b5f <cprintf>
			uint32_t vap = va & ~PAGESHIFT;
  1043e0:	8b 45 10             	mov    0x10(%ebp),%eax
  1043e3:	83 e0 f3             	and    $0xfffffff3,%eax
  1043e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
			pmap_remove(pdir, vap, PAGESIZE);
  1043e9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1043f0:	00 
  1043f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1043f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1043f8:	8b 45 08             	mov    0x8(%ebp),%eax
  1043fb:	89 04 24             	mov    %eax,(%esp)
  1043fe:	e8 32 01 00 00       	call   104535 <pmap_remove>
  104403:	eb 17                	jmp    10441c <pmap_insert+0xaf>
		}
		// if va has mapped to the pi that we want to map
		else{
			//mem_incref(pi);
			//cprintf("---------------\n");
			*pte |= perm;
  104405:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104408:	8b 10                	mov    (%eax),%edx
  10440a:	8b 45 14             	mov    0x14(%ebp),%eax
  10440d:	09 c2                	or     %eax,%edx
  10440f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104412:	89 10                	mov    %edx,(%eax)
			return pte;
  104414:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104417:	e9 13 01 00 00       	jmp    10452f <pmap_insert+0x1c2>
		}
	}

	// if pte is null, map it
	
	*pte = mem_pi2phys(pi) | perm | PTE_P;
  10441c:	8b 55 0c             	mov    0xc(%ebp),%edx
  10441f:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104424:	89 d1                	mov    %edx,%ecx
  104426:	29 c1                	sub    %eax,%ecx
  104428:	89 c8                	mov    %ecx,%eax
  10442a:	c1 f8 03             	sar    $0x3,%eax
  10442d:	c1 e0 0c             	shl    $0xc,%eax
  104430:	0b 45 14             	or     0x14(%ebp),%eax
  104433:	83 c8 01             	or     $0x1,%eax
  104436:	89 c2                	mov    %eax,%edx
  104438:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10443b:	89 10                	mov    %edx,(%eax)
  10443d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104440:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104443:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104448:	83 c0 08             	add    $0x8,%eax
  10444b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10444e:	76 15                	jbe    104465 <pmap_insert+0xf8>
  104450:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104455:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  10445b:	c1 e2 03             	shl    $0x3,%edx
  10445e:	01 d0                	add    %edx,%eax
  104460:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104463:	72 24                	jb     104489 <pmap_insert+0x11c>
  104465:	c7 44 24 0c 10 93 10 	movl   $0x109310,0xc(%esp)
  10446c:	00 
  10446d:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104474:	00 
  104475:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  10447c:	00 
  10447d:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104484:	e8 f8 bf ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  104489:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10448e:	ba 00 10 32 00       	mov    $0x321000,%edx
  104493:	c1 ea 0c             	shr    $0xc,%edx
  104496:	c1 e2 03             	shl    $0x3,%edx
  104499:	01 d0                	add    %edx,%eax
  10449b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10449e:	75 24                	jne    1044c4 <pmap_insert+0x157>
  1044a0:	c7 44 24 0c 54 93 10 	movl   $0x109354,0xc(%esp)
  1044a7:	00 
  1044a8:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1044af:	00 
  1044b0:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  1044b7:	00 
  1044b8:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  1044bf:	e8 bd bf ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1044c4:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1044c9:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  1044ce:	c1 ea 0c             	shr    $0xc,%edx
  1044d1:	c1 e2 03             	shl    $0x3,%edx
  1044d4:	01 d0                	add    %edx,%eax
  1044d6:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1044d9:	72 3b                	jb     104516 <pmap_insert+0x1a9>
  1044db:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1044e0:	ba 07 20 32 00       	mov    $0x322007,%edx
  1044e5:	c1 ea 0c             	shr    $0xc,%edx
  1044e8:	c1 e2 03             	shl    $0x3,%edx
  1044eb:	01 d0                	add    %edx,%eax
  1044ed:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1044f0:	77 24                	ja     104516 <pmap_insert+0x1a9>
  1044f2:	c7 44 24 0c 70 93 10 	movl   $0x109370,0xc(%esp)
  1044f9:	00 
  1044fa:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104501:	00 
  104502:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  104509:	00 
  10450a:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104511:	e8 6b bf ff ff       	call   100481 <debug_panic>

	lockadd(&pi->refcount, 1);
  104516:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104519:	83 c0 04             	add    $0x4,%eax
  10451c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104523:	00 
  104524:	89 04 24             	mov    %eax,(%esp)
  104527:	e8 a5 f7 ff ff       	call   103cd1 <lockadd>
	mem_incref(pi);


	//cprintf("out insert pi: %p, pi->refcount = %d\n", pi, pi->refcount);
	
	return pte;
  10452c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	
}
  10452f:	83 c4 24             	add    $0x24,%esp
  104532:	5b                   	pop    %ebx
  104533:	5d                   	pop    %ebp
  104534:	c3                   	ret    

00104535 <pmap_remove>:
// Hint: The TA solution is implemented using pmap_lookup,
// 	pmap_inval, and mem_decref.
//
void
pmap_remove(pde_t *pdir, uint32_t va, size_t size)
{
  104535:	55                   	push   %ebp
  104536:	89 e5                	mov    %esp,%ebp
  104538:	83 ec 48             	sub    $0x48,%esp
	assert(PGOFF(size) == 0);	// must be page-aligned
  10453b:	8b 45 10             	mov    0x10(%ebp),%eax
  10453e:	25 ff 0f 00 00       	and    $0xfff,%eax
  104543:	85 c0                	test   %eax,%eax
  104545:	74 24                	je     10456b <pmap_remove+0x36>
  104547:	c7 44 24 0c ed 93 10 	movl   $0x1093ed,0xc(%esp)
  10454e:	00 
  10454f:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104556:	00 
  104557:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
  10455e:	00 
  10455f:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104566:	e8 16 bf ff ff       	call   100481 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  10456b:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104572:	76 09                	jbe    10457d <pmap_remove+0x48>
  104574:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  10457b:	76 24                	jbe    1045a1 <pmap_remove+0x6c>
  10457d:	c7 44 24 0c b4 93 10 	movl   $0x1093b4,0xc(%esp)
  104584:	00 
  104585:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10458c:	00 
  10458d:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
  104594:	00 
  104595:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10459c:	e8 e0 be ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - va);
  1045a1:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1045a6:	2b 45 0c             	sub    0xc(%ebp),%eax
  1045a9:	3b 45 10             	cmp    0x10(%ebp),%eax
  1045ac:	73 24                	jae    1045d2 <pmap_remove+0x9d>
  1045ae:	c7 44 24 0c fe 93 10 	movl   $0x1093fe,0xc(%esp)
  1045b5:	00 
  1045b6:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1045bd:	00 
  1045be:	c7 44 24 04 49 01 00 	movl   $0x149,0x4(%esp)
  1045c5:	00 
  1045c6:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1045cd:	e8 af be ff ff       	call   100481 <debug_panic>
	// Fill in this function

	pte_t* pte;
	pageinfo* pi;

	uint32_t count = size/PAGESIZE;
  1045d2:	8b 45 10             	mov    0x10(%ebp),%eax
  1045d5:	c1 e8 0c             	shr    $0xc,%eax
  1045d8:	89 45 d0             	mov    %eax,-0x30(%ebp)


	uint32_t i = 0;
  1045db:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
	uint32_t start = va;
  1045e2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045e5:	89 45 d8             	mov    %eax,-0x28(%ebp)

	bool flag_4M = false;
  1045e8:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)

	for(; i < count; i++, start += PAGESIZE){ 
  1045ef:	e9 79 03 00 00       	jmp    10496d <pmap_remove+0x438>
		//cprintf("start = %x\n", start);

		if(PTOFF(start) == 0x0){
  1045f4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1045f7:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1045fc:	85 c0                	test   %eax,%eax
  1045fe:	75 1a                	jne    10461a <pmap_remove+0xe5>
			cprintf("va start at n * 4M, va = %x\n", start);
  104600:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104603:	89 44 24 04          	mov    %eax,0x4(%esp)
  104607:	c7 04 24 15 94 10 00 	movl   $0x109415,(%esp)
  10460e:	e8 4c 35 00 00       	call   107b5f <cprintf>
			flag_4M = true;
  104613:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
		}
		
		pte = pmap_walk(pdir, start, 0);
  10461a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104621:	00 
  104622:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104625:	89 44 24 04          	mov    %eax,0x4(%esp)
  104629:	8b 45 08             	mov    0x8(%ebp),%eax
  10462c:	89 04 24             	mov    %eax,(%esp)
  10462f:	e8 3e fb ff ff       	call   104172 <pmap_walk>
  104634:	89 45 c8             	mov    %eax,-0x38(%ebp)
		
		if((*pte != PTE_ZERO) && (pte != NULL)){
  104637:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10463a:	8b 10                	mov    (%eax),%edx
  10463c:	b8 00 10 32 00       	mov    $0x321000,%eax
  104641:	39 c2                	cmp    %eax,%edx
  104643:	0f 84 6f 01 00 00    	je     1047b8 <pmap_remove+0x283>
  104649:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
  10464d:	0f 84 65 01 00 00    	je     1047b8 <pmap_remove+0x283>
			cprintf("act delete\n");	
  104653:	c7 04 24 32 94 10 00 	movl   $0x109432,(%esp)
  10465a:	e8 00 35 00 00       	call   107b5f <cprintf>
			pi = mem_phys2pi(PGADDR(*pte));
  10465f:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  104665:	8b 45 c8             	mov    -0x38(%ebp),%eax
  104668:	8b 00                	mov    (%eax),%eax
  10466a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10466f:	c1 e8 0c             	shr    $0xc,%eax
  104672:	c1 e0 03             	shl    $0x3,%eax
  104675:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104678:	89 45 cc             	mov    %eax,-0x34(%ebp)
  10467b:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10467e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104681:	c7 45 e8 54 0b 10 00 	movl   $0x100b54,-0x18(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104688:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10468d:	83 c0 08             	add    $0x8,%eax
  104690:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104693:	76 15                	jbe    1046aa <pmap_remove+0x175>
  104695:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10469a:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  1046a0:	c1 e2 03             	shl    $0x3,%edx
  1046a3:	01 d0                	add    %edx,%eax
  1046a5:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  1046a8:	72 24                	jb     1046ce <pmap_remove+0x199>
  1046aa:	c7 44 24 0c 10 93 10 	movl   $0x109310,0xc(%esp)
  1046b1:	00 
  1046b2:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1046b9:	00 
  1046ba:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1046c1:	00 
  1046c2:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  1046c9:	e8 b3 bd ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1046ce:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1046d3:	ba 00 10 32 00       	mov    $0x321000,%edx
  1046d8:	c1 ea 0c             	shr    $0xc,%edx
  1046db:	c1 e2 03             	shl    $0x3,%edx
  1046de:	01 d0                	add    %edx,%eax
  1046e0:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  1046e3:	75 24                	jne    104709 <pmap_remove+0x1d4>
  1046e5:	c7 44 24 0c 54 93 10 	movl   $0x109354,0xc(%esp)
  1046ec:	00 
  1046ed:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1046f4:	00 
  1046f5:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1046fc:	00 
  1046fd:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104704:	e8 78 bd ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104709:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10470e:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104713:	c1 ea 0c             	shr    $0xc,%edx
  104716:	c1 e2 03             	shl    $0x3,%edx
  104719:	01 d0                	add    %edx,%eax
  10471b:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  10471e:	72 3b                	jb     10475b <pmap_remove+0x226>
  104720:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104725:	ba 07 20 32 00       	mov    $0x322007,%edx
  10472a:	c1 ea 0c             	shr    $0xc,%edx
  10472d:	c1 e2 03             	shl    $0x3,%edx
  104730:	01 d0                	add    %edx,%eax
  104732:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104735:	77 24                	ja     10475b <pmap_remove+0x226>
  104737:	c7 44 24 0c 70 93 10 	movl   $0x109370,0xc(%esp)
  10473e:	00 
  10473f:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104746:	00 
  104747:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  10474e:	00 
  10474f:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104756:	e8 26 bd ff ff       	call   100481 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10475b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10475e:	83 c0 04             	add    $0x4,%eax
  104761:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  104768:	ff 
  104769:	89 04 24             	mov    %eax,(%esp)
  10476c:	e8 71 f5 ff ff       	call   103ce2 <lockaddz>
  104771:	84 c0                	test   %al,%al
  104773:	74 0b                	je     104780 <pmap_remove+0x24b>
			freefun(pi);
  104775:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104778:	89 04 24             	mov    %eax,(%esp)
  10477b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10477e:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  104780:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104783:	8b 40 04             	mov    0x4(%eax),%eax
  104786:	85 c0                	test   %eax,%eax
  104788:	79 24                	jns    1047ae <pmap_remove+0x279>
  10478a:	c7 44 24 0c a1 93 10 	movl   $0x1093a1,0xc(%esp)
  104791:	00 
  104792:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104799:	00 
  10479a:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1047a1:	00 
  1047a2:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  1047a9:	e8 d3 bc ff ff       	call   100481 <debug_panic>
			mem_decref(pi, mem_free);
			*pte = PTE_ZERO;
  1047ae:	ba 00 10 32 00       	mov    $0x321000,%edx
  1047b3:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1047b6:	89 10                	mov    %edx,(%eax)
		}

		//cprintf("flag_4M = %d, va = %x\n", flag_4M, start);

		if((PTOFF(start) == 0x3ff000) && flag_4M){
  1047b8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1047bb:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1047c0:	3d 00 f0 3f 00       	cmp    $0x3ff000,%eax
  1047c5:	0f 85 97 01 00 00    	jne    104962 <pmap_remove+0x42d>
  1047cb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  1047cf:	0f 84 8d 01 00 00    	je     104962 <pmap_remove+0x42d>
			cprintf("=======delete PDE\n");
  1047d5:	c7 04 24 3e 94 10 00 	movl   $0x10943e,(%esp)
  1047dc:	e8 7e 33 00 00       	call   107b5f <cprintf>
			flag_4M = false;
  1047e1:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
			pde_t* pde = &pdir[PDX(start)];
  1047e8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1047eb:	c1 e8 16             	shr    $0x16,%eax
  1047ee:	c1 e0 02             	shl    $0x2,%eax
  1047f1:	03 45 08             	add    0x8(%ebp),%eax
  1047f4:	89 45 e0             	mov    %eax,-0x20(%ebp)
			if(*pde != PTE_ZERO){
  1047f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1047fa:	8b 10                	mov    (%eax),%edx
  1047fc:	b8 00 10 32 00       	mov    $0x321000,%eax
  104801:	39 c2                	cmp    %eax,%edx
  104803:	0f 84 59 01 00 00    	je     104962 <pmap_remove+0x42d>
				pageinfo* pi = mem_phys2pi(PGADDR(*pde));
  104809:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  10480f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104812:	8b 00                	mov    (%eax),%eax
  104814:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104819:	c1 e8 0c             	shr    $0xc,%eax
  10481c:	c1 e0 03             	shl    $0x3,%eax
  10481f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104822:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  104825:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104828:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10482b:	c7 45 f0 54 0b 10 00 	movl   $0x100b54,-0x10(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104832:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104837:	83 c0 08             	add    $0x8,%eax
  10483a:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10483d:	76 15                	jbe    104854 <pmap_remove+0x31f>
  10483f:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104844:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  10484a:	c1 e2 03             	shl    $0x3,%edx
  10484d:	01 d0                	add    %edx,%eax
  10484f:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104852:	72 24                	jb     104878 <pmap_remove+0x343>
  104854:	c7 44 24 0c 10 93 10 	movl   $0x109310,0xc(%esp)
  10485b:	00 
  10485c:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104863:	00 
  104864:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  10486b:	00 
  10486c:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104873:	e8 09 bc ff ff       	call   100481 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  104878:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10487d:	ba 00 10 32 00       	mov    $0x321000,%edx
  104882:	c1 ea 0c             	shr    $0xc,%edx
  104885:	c1 e2 03             	shl    $0x3,%edx
  104888:	01 d0                	add    %edx,%eax
  10488a:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10488d:	75 24                	jne    1048b3 <pmap_remove+0x37e>
  10488f:	c7 44 24 0c 54 93 10 	movl   $0x109354,0xc(%esp)
  104896:	00 
  104897:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10489e:	00 
  10489f:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1048a6:	00 
  1048a7:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  1048ae:	e8 ce bb ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1048b3:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1048b8:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  1048bd:	c1 ea 0c             	shr    $0xc,%edx
  1048c0:	c1 e2 03             	shl    $0x3,%edx
  1048c3:	01 d0                	add    %edx,%eax
  1048c5:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1048c8:	72 3b                	jb     104905 <pmap_remove+0x3d0>
  1048ca:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1048cf:	ba 07 20 32 00       	mov    $0x322007,%edx
  1048d4:	c1 ea 0c             	shr    $0xc,%edx
  1048d7:	c1 e2 03             	shl    $0x3,%edx
  1048da:	01 d0                	add    %edx,%eax
  1048dc:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1048df:	77 24                	ja     104905 <pmap_remove+0x3d0>
  1048e1:	c7 44 24 0c 70 93 10 	movl   $0x109370,0xc(%esp)
  1048e8:	00 
  1048e9:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1048f0:	00 
  1048f1:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  1048f8:	00 
  1048f9:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104900:	e8 7c bb ff ff       	call   100481 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  104905:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104908:	83 c0 04             	add    $0x4,%eax
  10490b:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  104912:	ff 
  104913:	89 04 24             	mov    %eax,(%esp)
  104916:	e8 c7 f3 ff ff       	call   103ce2 <lockaddz>
  10491b:	84 c0                	test   %al,%al
  10491d:	74 0b                	je     10492a <pmap_remove+0x3f5>
			freefun(pi);
  10491f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104922:	89 04 24             	mov    %eax,(%esp)
  104925:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104928:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  10492a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10492d:	8b 40 04             	mov    0x4(%eax),%eax
  104930:	85 c0                	test   %eax,%eax
  104932:	79 24                	jns    104958 <pmap_remove+0x423>
  104934:	c7 44 24 0c a1 93 10 	movl   $0x1093a1,0xc(%esp)
  10493b:	00 
  10493c:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104943:	00 
  104944:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  10494b:	00 
  10494c:	c7 04 24 47 93 10 00 	movl   $0x109347,(%esp)
  104953:	e8 29 bb ff ff       	call   100481 <debug_panic>
				mem_decref(pi, mem_free);
				*pde = PTE_ZERO;
  104958:	ba 00 10 32 00       	mov    $0x321000,%edx
  10495d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104960:	89 10                	mov    %edx,(%eax)
	uint32_t i = 0;
	uint32_t start = va;

	bool flag_4M = false;

	for(; i < count; i++, start += PAGESIZE){ 
  104962:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  104966:	81 45 d8 00 10 00 00 	addl   $0x1000,-0x28(%ebp)
  10496d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104970:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  104973:	0f 82 7b fc ff ff    	jb     1045f4 <pmap_remove+0xbf>

	}

	
	
}
  104979:	c9                   	leave  
  10497a:	c3                   	ret    

0010497b <pmap_inval>:
// but only if the page tables being edited are the ones
// currently in use by the processor.
//
void
pmap_inval(pde_t *pdir, uint32_t va, size_t size)
{
  10497b:	55                   	push   %ebp
  10497c:	89 e5                	mov    %esp,%ebp
  10497e:	83 ec 18             	sub    $0x18,%esp
	// Flush the entry only if we're modifying the current address space.
	proc *p = proc_cur();
  104981:	e8 78 f3 ff ff       	call   103cfe <cpu_cur>
  104986:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10498c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (p == NULL || p->pdir == pdir) {
  10498f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  104993:	74 0e                	je     1049a3 <pmap_inval+0x28>
  104995:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104998:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  10499e:	3b 45 08             	cmp    0x8(%ebp),%eax
  1049a1:	75 23                	jne    1049c6 <pmap_inval+0x4b>
		if (size == PAGESIZE)
  1049a3:	81 7d 10 00 10 00 00 	cmpl   $0x1000,0x10(%ebp)
  1049aa:	75 0e                	jne    1049ba <pmap_inval+0x3f>
			invlpg(mem_ptr(va));	// invalidate one page
  1049ac:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049af:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static gcc_inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
  1049b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1049b5:	0f 01 38             	invlpg (%eax)
  1049b8:	eb 0c                	jmp    1049c6 <pmap_inval+0x4b>
		else
			lcr3(mem_phys(pdir));	// invalidate everything
  1049ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1049bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  1049c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1049c3:	0f 22 d8             	mov    %eax,%cr3
	}
}
  1049c6:	c9                   	leave  
  1049c7:	c3                   	ret    

001049c8 <pmap_copy>:
// Returns true if successfull, false if not enough memory for copy.
//
int
pmap_copy(pde_t *spdir, uint32_t sva, pde_t *dpdir, uint32_t dva,
		size_t size)
{
  1049c8:	55                   	push   %ebp
  1049c9:	89 e5                	mov    %esp,%ebp
  1049cb:	83 ec 18             	sub    $0x18,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  1049ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049d1:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1049d6:	85 c0                	test   %eax,%eax
  1049d8:	74 24                	je     1049fe <pmap_copy+0x36>
  1049da:	c7 44 24 0c 51 94 10 	movl   $0x109451,0xc(%esp)
  1049e1:	00 
  1049e2:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1049e9:	00 
  1049ea:	c7 44 24 04 98 01 00 	movl   $0x198,0x4(%esp)
  1049f1:	00 
  1049f2:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1049f9:	e8 83 ba ff ff       	call   100481 <debug_panic>
	assert(PTOFF(dva) == 0);
  1049fe:	8b 45 14             	mov    0x14(%ebp),%eax
  104a01:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104a06:	85 c0                	test   %eax,%eax
  104a08:	74 24                	je     104a2e <pmap_copy+0x66>
  104a0a:	c7 44 24 0c 61 94 10 	movl   $0x109461,0xc(%esp)
  104a11:	00 
  104a12:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104a19:	00 
  104a1a:	c7 44 24 04 99 01 00 	movl   $0x199,0x4(%esp)
  104a21:	00 
  104a22:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104a29:	e8 53 ba ff ff       	call   100481 <debug_panic>
	assert(PTOFF(size) == 0);
  104a2e:	8b 45 18             	mov    0x18(%ebp),%eax
  104a31:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104a36:	85 c0                	test   %eax,%eax
  104a38:	74 24                	je     104a5e <pmap_copy+0x96>
  104a3a:	c7 44 24 0c 71 94 10 	movl   $0x109471,0xc(%esp)
  104a41:	00 
  104a42:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104a49:	00 
  104a4a:	c7 44 24 04 9a 01 00 	movl   $0x19a,0x4(%esp)
  104a51:	00 
  104a52:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104a59:	e8 23 ba ff ff       	call   100481 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  104a5e:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104a65:	76 09                	jbe    104a70 <pmap_copy+0xa8>
  104a67:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  104a6e:	76 24                	jbe    104a94 <pmap_copy+0xcc>
  104a70:	c7 44 24 0c 84 94 10 	movl   $0x109484,0xc(%esp)
  104a77:	00 
  104a78:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104a7f:	00 
  104a80:	c7 44 24 04 9b 01 00 	movl   $0x19b,0x4(%esp)
  104a87:	00 
  104a88:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104a8f:	e8 ed b9 ff ff       	call   100481 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  104a94:	81 7d 14 ff ff ff 3f 	cmpl   $0x3fffffff,0x14(%ebp)
  104a9b:	76 09                	jbe    104aa6 <pmap_copy+0xde>
  104a9d:	81 7d 14 ff ff ff ef 	cmpl   $0xefffffff,0x14(%ebp)
  104aa4:	76 24                	jbe    104aca <pmap_copy+0x102>
  104aa6:	c7 44 24 0c a8 94 10 	movl   $0x1094a8,0xc(%esp)
  104aad:	00 
  104aae:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104ab5:	00 
  104ab6:	c7 44 24 04 9c 01 00 	movl   $0x19c,0x4(%esp)
  104abd:	00 
  104abe:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104ac5:	e8 b7 b9 ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - sva);
  104aca:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104acf:	2b 45 0c             	sub    0xc(%ebp),%eax
  104ad2:	3b 45 18             	cmp    0x18(%ebp),%eax
  104ad5:	73 24                	jae    104afb <pmap_copy+0x133>
  104ad7:	c7 44 24 0c cc 94 10 	movl   $0x1094cc,0xc(%esp)
  104ade:	00 
  104adf:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104ae6:	00 
  104ae7:	c7 44 24 04 9d 01 00 	movl   $0x19d,0x4(%esp)
  104aee:	00 
  104aef:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104af6:	e8 86 b9 ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - dva);
  104afb:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104b00:	2b 45 14             	sub    0x14(%ebp),%eax
  104b03:	3b 45 18             	cmp    0x18(%ebp),%eax
  104b06:	73 24                	jae    104b2c <pmap_copy+0x164>
  104b08:	c7 44 24 0c e4 94 10 	movl   $0x1094e4,0xc(%esp)
  104b0f:	00 
  104b10:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104b17:	00 
  104b18:	c7 44 24 04 9e 01 00 	movl   $0x19e,0x4(%esp)
  104b1f:	00 
  104b20:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104b27:	e8 55 b9 ff ff       	call   100481 <debug_panic>

	panic("pmap_copy() not implemented");
  104b2c:	c7 44 24 08 fc 94 10 	movl   $0x1094fc,0x8(%esp)
  104b33:	00 
  104b34:	c7 44 24 04 a0 01 00 	movl   $0x1a0,0x4(%esp)
  104b3b:	00 
  104b3c:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104b43:	e8 39 b9 ff ff       	call   100481 <debug_panic>

00104b48 <pmap_pagefault>:
// If the fault wasn't due to the kernel's copy on write optimization,
// however, this function just returns so the trap gets blamed on the user.
//
void
pmap_pagefault(trapframe *tf)
{
  104b48:	55                   	push   %ebp
  104b49:	89 e5                	mov    %esp,%ebp
  104b4b:	83 ec 10             	sub    $0x10,%esp

static gcc_inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
  104b4e:	0f 20 d0             	mov    %cr2,%eax
  104b51:	89 45 fc             	mov    %eax,-0x4(%ebp)
	return val;
  104b54:	8b 45 fc             	mov    -0x4(%ebp),%eax
	// Read processor's CR2 register to find the faulting linear address.
	uint32_t fva = rcr2();
  104b57:	89 45 f8             	mov    %eax,-0x8(%ebp)
	//cprintf("pmap_pagefault fva %x eip %x\n", fva, tf->eip);

	// Fill in the rest of this code.
}
  104b5a:	c9                   	leave  
  104b5b:	c3                   	ret    

00104b5c <pmap_mergepage>:
// print a warning to the console and remove the page from the destination.
// If the destination page is read-shared, be sure to copy it before modifying!
//
void
pmap_mergepage(pte_t *rpte, pte_t *spte, pte_t *dpte, uint32_t dva)
{
  104b5c:	55                   	push   %ebp
  104b5d:	89 e5                	mov    %esp,%ebp
  104b5f:	83 ec 18             	sub    $0x18,%esp
	panic("pmap_mergepage() not implemented");
  104b62:	c7 44 24 08 18 95 10 	movl   $0x109518,0x8(%esp)
  104b69:	00 
  104b6a:	c7 44 24 04 be 01 00 	movl   $0x1be,0x4(%esp)
  104b71:	00 
  104b72:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104b79:	e8 03 b9 ff ff       	call   100481 <debug_panic>

00104b7e <pmap_merge>:
// and a source address space spdir into a destination address space dpdir.
//
int
pmap_merge(pde_t *rpdir, pde_t *spdir, uint32_t sva,
		pde_t *dpdir, uint32_t dva, size_t size)
{
  104b7e:	55                   	push   %ebp
  104b7f:	89 e5                	mov    %esp,%ebp
  104b81:	83 ec 18             	sub    $0x18,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  104b84:	8b 45 10             	mov    0x10(%ebp),%eax
  104b87:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104b8c:	85 c0                	test   %eax,%eax
  104b8e:	74 24                	je     104bb4 <pmap_merge+0x36>
  104b90:	c7 44 24 0c 51 94 10 	movl   $0x109451,0xc(%esp)
  104b97:	00 
  104b98:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104b9f:	00 
  104ba0:	c7 44 24 04 c9 01 00 	movl   $0x1c9,0x4(%esp)
  104ba7:	00 
  104ba8:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104baf:	e8 cd b8 ff ff       	call   100481 <debug_panic>
	assert(PTOFF(dva) == 0);
  104bb4:	8b 45 18             	mov    0x18(%ebp),%eax
  104bb7:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104bbc:	85 c0                	test   %eax,%eax
  104bbe:	74 24                	je     104be4 <pmap_merge+0x66>
  104bc0:	c7 44 24 0c 61 94 10 	movl   $0x109461,0xc(%esp)
  104bc7:	00 
  104bc8:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104bcf:	00 
  104bd0:	c7 44 24 04 ca 01 00 	movl   $0x1ca,0x4(%esp)
  104bd7:	00 
  104bd8:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104bdf:	e8 9d b8 ff ff       	call   100481 <debug_panic>
	assert(PTOFF(size) == 0);
  104be4:	8b 45 1c             	mov    0x1c(%ebp),%eax
  104be7:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104bec:	85 c0                	test   %eax,%eax
  104bee:	74 24                	je     104c14 <pmap_merge+0x96>
  104bf0:	c7 44 24 0c 71 94 10 	movl   $0x109471,0xc(%esp)
  104bf7:	00 
  104bf8:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104bff:	00 
  104c00:	c7 44 24 04 cb 01 00 	movl   $0x1cb,0x4(%esp)
  104c07:	00 
  104c08:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104c0f:	e8 6d b8 ff ff       	call   100481 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  104c14:	81 7d 10 ff ff ff 3f 	cmpl   $0x3fffffff,0x10(%ebp)
  104c1b:	76 09                	jbe    104c26 <pmap_merge+0xa8>
  104c1d:	81 7d 10 ff ff ff ef 	cmpl   $0xefffffff,0x10(%ebp)
  104c24:	76 24                	jbe    104c4a <pmap_merge+0xcc>
  104c26:	c7 44 24 0c 84 94 10 	movl   $0x109484,0xc(%esp)
  104c2d:	00 
  104c2e:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104c35:	00 
  104c36:	c7 44 24 04 cc 01 00 	movl   $0x1cc,0x4(%esp)
  104c3d:	00 
  104c3e:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104c45:	e8 37 b8 ff ff       	call   100481 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  104c4a:	81 7d 18 ff ff ff 3f 	cmpl   $0x3fffffff,0x18(%ebp)
  104c51:	76 09                	jbe    104c5c <pmap_merge+0xde>
  104c53:	81 7d 18 ff ff ff ef 	cmpl   $0xefffffff,0x18(%ebp)
  104c5a:	76 24                	jbe    104c80 <pmap_merge+0x102>
  104c5c:	c7 44 24 0c a8 94 10 	movl   $0x1094a8,0xc(%esp)
  104c63:	00 
  104c64:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104c6b:	00 
  104c6c:	c7 44 24 04 cd 01 00 	movl   $0x1cd,0x4(%esp)
  104c73:	00 
  104c74:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104c7b:	e8 01 b8 ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - sva);
  104c80:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104c85:	2b 45 10             	sub    0x10(%ebp),%eax
  104c88:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  104c8b:	73 24                	jae    104cb1 <pmap_merge+0x133>
  104c8d:	c7 44 24 0c cc 94 10 	movl   $0x1094cc,0xc(%esp)
  104c94:	00 
  104c95:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104c9c:	00 
  104c9d:	c7 44 24 04 ce 01 00 	movl   $0x1ce,0x4(%esp)
  104ca4:	00 
  104ca5:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104cac:	e8 d0 b7 ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - dva);
  104cb1:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104cb6:	2b 45 18             	sub    0x18(%ebp),%eax
  104cb9:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  104cbc:	73 24                	jae    104ce2 <pmap_merge+0x164>
  104cbe:	c7 44 24 0c e4 94 10 	movl   $0x1094e4,0xc(%esp)
  104cc5:	00 
  104cc6:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104ccd:	00 
  104cce:	c7 44 24 04 cf 01 00 	movl   $0x1cf,0x4(%esp)
  104cd5:	00 
  104cd6:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104cdd:	e8 9f b7 ff ff       	call   100481 <debug_panic>

	panic("pmap_merge() not implemented");
  104ce2:	c7 44 24 08 39 95 10 	movl   $0x109539,0x8(%esp)
  104ce9:	00 
  104cea:	c7 44 24 04 d1 01 00 	movl   $0x1d1,0x4(%esp)
  104cf1:	00 
  104cf2:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104cf9:	e8 83 b7 ff ff       	call   100481 <debug_panic>

00104cfe <pmap_setperm>:
// If the user gives SYS_WRITE permission to a PTE_ZERO mapping,
// the page fault handler copies the zero page when the first write occurs.
//
int
pmap_setperm(pde_t *pdir, uint32_t va, uint32_t size, int perm)
{
  104cfe:	55                   	push   %ebp
  104cff:	89 e5                	mov    %esp,%ebp
  104d01:	83 ec 18             	sub    $0x18,%esp
	assert(PGOFF(va) == 0);
  104d04:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d07:	25 ff 0f 00 00       	and    $0xfff,%eax
  104d0c:	85 c0                	test   %eax,%eax
  104d0e:	74 24                	je     104d34 <pmap_setperm+0x36>
  104d10:	c7 44 24 0c 56 95 10 	movl   $0x109556,0xc(%esp)
  104d17:	00 
  104d18:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104d1f:	00 
  104d20:	c7 44 24 04 df 01 00 	movl   $0x1df,0x4(%esp)
  104d27:	00 
  104d28:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104d2f:	e8 4d b7 ff ff       	call   100481 <debug_panic>
	assert(PGOFF(size) == 0);
  104d34:	8b 45 10             	mov    0x10(%ebp),%eax
  104d37:	25 ff 0f 00 00       	and    $0xfff,%eax
  104d3c:	85 c0                	test   %eax,%eax
  104d3e:	74 24                	je     104d64 <pmap_setperm+0x66>
  104d40:	c7 44 24 0c ed 93 10 	movl   $0x1093ed,0xc(%esp)
  104d47:	00 
  104d48:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104d4f:	00 
  104d50:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
  104d57:	00 
  104d58:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104d5f:	e8 1d b7 ff ff       	call   100481 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  104d64:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104d6b:	76 09                	jbe    104d76 <pmap_setperm+0x78>
  104d6d:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  104d74:	76 24                	jbe    104d9a <pmap_setperm+0x9c>
  104d76:	c7 44 24 0c b4 93 10 	movl   $0x1093b4,0xc(%esp)
  104d7d:	00 
  104d7e:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104d85:	00 
  104d86:	c7 44 24 04 e1 01 00 	movl   $0x1e1,0x4(%esp)
  104d8d:	00 
  104d8e:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104d95:	e8 e7 b6 ff ff       	call   100481 <debug_panic>
	assert(size <= VM_USERHI - va);
  104d9a:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104d9f:	2b 45 0c             	sub    0xc(%ebp),%eax
  104da2:	3b 45 10             	cmp    0x10(%ebp),%eax
  104da5:	73 24                	jae    104dcb <pmap_setperm+0xcd>
  104da7:	c7 44 24 0c fe 93 10 	movl   $0x1093fe,0xc(%esp)
  104dae:	00 
  104daf:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104db6:	00 
  104db7:	c7 44 24 04 e2 01 00 	movl   $0x1e2,0x4(%esp)
  104dbe:	00 
  104dbf:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104dc6:	e8 b6 b6 ff ff       	call   100481 <debug_panic>
	assert((perm & ~(SYS_RW)) == 0);
  104dcb:	8b 45 14             	mov    0x14(%ebp),%eax
  104dce:	80 e4 f9             	and    $0xf9,%ah
  104dd1:	85 c0                	test   %eax,%eax
  104dd3:	74 24                	je     104df9 <pmap_setperm+0xfb>
  104dd5:	c7 44 24 0c 65 95 10 	movl   $0x109565,0xc(%esp)
  104ddc:	00 
  104ddd:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104de4:	00 
  104de5:	c7 44 24 04 e3 01 00 	movl   $0x1e3,0x4(%esp)
  104dec:	00 
  104ded:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104df4:	e8 88 b6 ff ff       	call   100481 <debug_panic>

	panic("pmap_merge() not implemented");
  104df9:	c7 44 24 08 39 95 10 	movl   $0x109539,0x8(%esp)
  104e00:	00 
  104e01:	c7 44 24 04 e5 01 00 	movl   $0x1e5,0x4(%esp)
  104e08:	00 
  104e09:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104e10:	e8 6c b6 ff ff       	call   100481 <debug_panic>

00104e15 <va2pa>:
// this functionality for us!  We define our own version to help check
// the pmap_check() function; it shouldn't be used elsewhere.
//
static uint32_t
va2pa(pde_t *pdir, uintptr_t va)
{
  104e15:	55                   	push   %ebp
  104e16:	89 e5                	mov    %esp,%ebp
  104e18:	83 ec 10             	sub    $0x10,%esp
	pdir = &pdir[PDX(va)];
  104e1b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e1e:	c1 e8 16             	shr    $0x16,%eax
  104e21:	c1 e0 02             	shl    $0x2,%eax
  104e24:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pdir & PTE_P))
  104e27:	8b 45 08             	mov    0x8(%ebp),%eax
  104e2a:	8b 00                	mov    (%eax),%eax
  104e2c:	83 e0 01             	and    $0x1,%eax
  104e2f:	85 c0                	test   %eax,%eax
  104e31:	75 07                	jne    104e3a <va2pa+0x25>
		return ~0;
  104e33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104e38:	eb 46                	jmp    104e80 <va2pa+0x6b>
	pte_t *ptab = mem_ptr(PGADDR(*pdir));
  104e3a:	8b 45 08             	mov    0x8(%ebp),%eax
  104e3d:	8b 00                	mov    (%eax),%eax
  104e3f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104e44:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (!(ptab[PTX(va)] & PTE_P))
  104e47:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e4a:	c1 e8 0c             	shr    $0xc,%eax
  104e4d:	25 ff 03 00 00       	and    $0x3ff,%eax
  104e52:	c1 e0 02             	shl    $0x2,%eax
  104e55:	03 45 fc             	add    -0x4(%ebp),%eax
  104e58:	8b 00                	mov    (%eax),%eax
  104e5a:	83 e0 01             	and    $0x1,%eax
  104e5d:	85 c0                	test   %eax,%eax
  104e5f:	75 07                	jne    104e68 <va2pa+0x53>
		return ~0;
  104e61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104e66:	eb 18                	jmp    104e80 <va2pa+0x6b>
	return PGADDR(ptab[PTX(va)]);
  104e68:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e6b:	c1 e8 0c             	shr    $0xc,%eax
  104e6e:	25 ff 03 00 00       	and    $0x3ff,%eax
  104e73:	c1 e0 02             	shl    $0x2,%eax
  104e76:	03 45 fc             	add    -0x4(%ebp),%eax
  104e79:	8b 00                	mov    (%eax),%eax
  104e7b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
  104e80:	c9                   	leave  
  104e81:	c3                   	ret    

00104e82 <pmap_check>:

// check pmap_insert, pmap_remove, &c
void
pmap_check(void)
{
  104e82:	55                   	push   %ebp
  104e83:	89 e5                	mov    %esp,%ebp
  104e85:	53                   	push   %ebx
  104e86:	83 ec 44             	sub    $0x44,%esp

	cprintf("into pmap_check()\n");
  104e89:	c7 04 24 7d 95 10 00 	movl   $0x10957d,(%esp)
  104e90:	e8 ca 2c 00 00       	call   107b5f <cprintf>
	pageinfo *fl;
	pte_t *ptep, *ptep1;
	int i;

	// should be able to allocate three pages
	pi0 = pi1 = pi2 = 0;
  104e95:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  104e9c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104e9f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  104ea2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104ea5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	pi0 = mem_alloc();
  104ea8:	e8 60 bc ff ff       	call   100b0d <mem_alloc>
  104ead:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	pi1 = mem_alloc();
  104eb0:	e8 58 bc ff ff       	call   100b0d <mem_alloc>
  104eb5:	89 45 d8             	mov    %eax,-0x28(%ebp)
	pi2 = mem_alloc();
  104eb8:	e8 50 bc ff ff       	call   100b0d <mem_alloc>
  104ebd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	pi3 = mem_alloc();
  104ec0:	e8 48 bc ff ff       	call   100b0d <mem_alloc>
  104ec5:	89 45 e0             	mov    %eax,-0x20(%ebp)

	assert(pi0);
  104ec8:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  104ecc:	75 24                	jne    104ef2 <pmap_check+0x70>
  104ece:	c7 44 24 0c 90 95 10 	movl   $0x109590,0xc(%esp)
  104ed5:	00 
  104ed6:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104edd:	00 
  104ede:	c7 44 24 04 0e 02 00 	movl   $0x20e,0x4(%esp)
  104ee5:	00 
  104ee6:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104eed:	e8 8f b5 ff ff       	call   100481 <debug_panic>
	assert(pi1 && pi1 != pi0);
  104ef2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  104ef6:	74 08                	je     104f00 <pmap_check+0x7e>
  104ef8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104efb:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  104efe:	75 24                	jne    104f24 <pmap_check+0xa2>
  104f00:	c7 44 24 0c 94 95 10 	movl   $0x109594,0xc(%esp)
  104f07:	00 
  104f08:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104f0f:	00 
  104f10:	c7 44 24 04 0f 02 00 	movl   $0x20f,0x4(%esp)
  104f17:	00 
  104f18:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104f1f:	e8 5d b5 ff ff       	call   100481 <debug_panic>
	assert(pi2 && pi2 != pi1 && pi2 != pi0);
  104f24:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  104f28:	74 10                	je     104f3a <pmap_check+0xb8>
  104f2a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104f2d:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  104f30:	74 08                	je     104f3a <pmap_check+0xb8>
  104f32:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104f35:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  104f38:	75 24                	jne    104f5e <pmap_check+0xdc>
  104f3a:	c7 44 24 0c a8 95 10 	movl   $0x1095a8,0xc(%esp)
  104f41:	00 
  104f42:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104f49:	00 
  104f4a:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
  104f51:	00 
  104f52:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104f59:	e8 23 b5 ff ff       	call   100481 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  104f5e:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  104f63:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	mem_freelist = NULL;
  104f66:	c7 05 00 ed 11 00 00 	movl   $0x0,0x11ed00
  104f6d:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == NULL);
  104f70:	e8 98 bb ff ff       	call   100b0d <mem_alloc>
  104f75:	85 c0                	test   %eax,%eax
  104f77:	74 24                	je     104f9d <pmap_check+0x11b>
  104f79:	c7 44 24 0c c8 95 10 	movl   $0x1095c8,0xc(%esp)
  104f80:	00 
  104f81:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104f88:	00 
  104f89:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
  104f90:	00 
  104f91:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104f98:	e8 e4 b4 ff ff       	call   100481 <debug_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) == NULL);
  104f9d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104fa4:	00 
  104fa5:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  104fac:	40 
  104fad:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104fb0:	89 44 24 04          	mov    %eax,0x4(%esp)
  104fb4:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  104fbb:	e8 ad f3 ff ff       	call   10436d <pmap_insert>
  104fc0:	85 c0                	test   %eax,%eax
  104fc2:	74 24                	je     104fe8 <pmap_check+0x166>
  104fc4:	c7 44 24 0c dc 95 10 	movl   $0x1095dc,0xc(%esp)
  104fcb:	00 
  104fcc:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  104fd3:	00 
  104fd4:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
  104fdb:	00 
  104fdc:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  104fe3:	e8 99 b4 ff ff       	call   100481 <debug_panic>

	// free pi0 and try again: pi0 should be used for page table
	mem_free(pi0);
  104fe8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104feb:	89 04 24             	mov    %eax,(%esp)
  104fee:	e8 61 bb ff ff       	call   100b54 <mem_free>

	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) != NULL);
  104ff3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  104ffa:	00 
  104ffb:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  105002:	40 
  105003:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105006:	89 44 24 04          	mov    %eax,0x4(%esp)
  10500a:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105011:	e8 57 f3 ff ff       	call   10436d <pmap_insert>
  105016:	85 c0                	test   %eax,%eax
  105018:	75 24                	jne    10503e <pmap_check+0x1bc>
  10501a:	c7 44 24 0c 14 96 10 	movl   $0x109614,0xc(%esp)
  105021:	00 
  105022:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105029:	00 
  10502a:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
  105031:	00 
  105032:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105039:	e8 43 b4 ff ff       	call   100481 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi0));
  10503e:	a1 00 04 32 00       	mov    0x320400,%eax
  105043:	89 c1                	mov    %eax,%ecx
  105045:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  10504b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10504e:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  105053:	89 d3                	mov    %edx,%ebx
  105055:	29 c3                	sub    %eax,%ebx
  105057:	89 d8                	mov    %ebx,%eax
  105059:	c1 f8 03             	sar    $0x3,%eax
  10505c:	c1 e0 0c             	shl    $0xc,%eax
  10505f:	39 c1                	cmp    %eax,%ecx
  105061:	74 24                	je     105087 <pmap_check+0x205>
  105063:	c7 44 24 0c 4c 96 10 	movl   $0x10964c,0xc(%esp)
  10506a:	00 
  10506b:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105072:	00 
  105073:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
  10507a:	00 
  10507b:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105082:	e8 fa b3 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO) == mem_pi2phys(pi1));
  105087:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  10508e:	40 
  10508f:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105096:	e8 7a fd ff ff       	call   104e15 <va2pa>
  10509b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  10509e:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  1050a4:	89 cb                	mov    %ecx,%ebx
  1050a6:	29 d3                	sub    %edx,%ebx
  1050a8:	89 da                	mov    %ebx,%edx
  1050aa:	c1 fa 03             	sar    $0x3,%edx
  1050ad:	c1 e2 0c             	shl    $0xc,%edx
  1050b0:	39 d0                	cmp    %edx,%eax
  1050b2:	74 24                	je     1050d8 <pmap_check+0x256>
  1050b4:	c7 44 24 0c 88 96 10 	movl   $0x109688,0xc(%esp)
  1050bb:	00 
  1050bc:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1050c3:	00 
  1050c4:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
  1050cb:	00 
  1050cc:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1050d3:	e8 a9 b3 ff ff       	call   100481 <debug_panic>


	assert(pi1->refcount == 1);
  1050d8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1050db:	8b 40 04             	mov    0x4(%eax),%eax
  1050de:	83 f8 01             	cmp    $0x1,%eax
  1050e1:	74 24                	je     105107 <pmap_check+0x285>
  1050e3:	c7 44 24 0c bc 96 10 	movl   $0x1096bc,0xc(%esp)
  1050ea:	00 
  1050eb:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1050f2:	00 
  1050f3:	c7 44 24 04 24 02 00 	movl   $0x224,0x4(%esp)
  1050fa:	00 
  1050fb:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105102:	e8 7a b3 ff ff       	call   100481 <debug_panic>
	assert(pi0->refcount == 1);
  105107:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10510a:	8b 40 04             	mov    0x4(%eax),%eax
  10510d:	83 f8 01             	cmp    $0x1,%eax
  105110:	74 24                	je     105136 <pmap_check+0x2b4>
  105112:	c7 44 24 0c cf 96 10 	movl   $0x1096cf,0xc(%esp)
  105119:	00 
  10511a:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105121:	00 
  105122:	c7 44 24 04 25 02 00 	movl   $0x225,0x4(%esp)
  105129:	00 
  10512a:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105131:	e8 4b b3 ff ff       	call   100481 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because pi0 is already allocated for page table

	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  105136:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10513d:	00 
  10513e:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  105145:	40 
  105146:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105149:	89 44 24 04          	mov    %eax,0x4(%esp)
  10514d:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105154:	e8 14 f2 ff ff       	call   10436d <pmap_insert>
  105159:	85 c0                	test   %eax,%eax
  10515b:	75 24                	jne    105181 <pmap_check+0x2ff>
  10515d:	c7 44 24 0c e4 96 10 	movl   $0x1096e4,0xc(%esp)
  105164:	00 
  105165:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10516c:	00 
  10516d:	c7 44 24 04 2a 02 00 	movl   $0x22a,0x4(%esp)
  105174:	00 
  105175:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10517c:	e8 00 b3 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  105181:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105188:	40 
  105189:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105190:	e8 80 fc ff ff       	call   104e15 <va2pa>
  105195:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  105198:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  10519e:	89 cb                	mov    %ecx,%ebx
  1051a0:	29 d3                	sub    %edx,%ebx
  1051a2:	89 da                	mov    %ebx,%edx
  1051a4:	c1 fa 03             	sar    $0x3,%edx
  1051a7:	c1 e2 0c             	shl    $0xc,%edx
  1051aa:	39 d0                	cmp    %edx,%eax
  1051ac:	74 24                	je     1051d2 <pmap_check+0x350>
  1051ae:	c7 44 24 0c 1c 97 10 	movl   $0x10971c,0xc(%esp)
  1051b5:	00 
  1051b6:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1051bd:	00 
  1051be:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
  1051c5:	00 
  1051c6:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1051cd:	e8 af b2 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  1051d2:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1051d5:	8b 40 04             	mov    0x4(%eax),%eax
  1051d8:	83 f8 01             	cmp    $0x1,%eax
  1051db:	74 24                	je     105201 <pmap_check+0x37f>
  1051dd:	c7 44 24 0c 59 97 10 	movl   $0x109759,0xc(%esp)
  1051e4:	00 
  1051e5:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1051ec:	00 
  1051ed:	c7 44 24 04 2c 02 00 	movl   $0x22c,0x4(%esp)
  1051f4:	00 
  1051f5:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1051fc:	e8 80 b2 ff ff       	call   100481 <debug_panic>

	// should be no free memory
	assert(mem_alloc() == NULL);
  105201:	e8 07 b9 ff ff       	call   100b0d <mem_alloc>
  105206:	85 c0                	test   %eax,%eax
  105208:	74 24                	je     10522e <pmap_check+0x3ac>
  10520a:	c7 44 24 0c c8 95 10 	movl   $0x1095c8,0xc(%esp)
  105211:	00 
  105212:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105219:	00 
  10521a:	c7 44 24 04 2f 02 00 	movl   $0x22f,0x4(%esp)
  105221:	00 
  105222:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105229:	e8 53 b2 ff ff       	call   100481 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because it's already there
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  10522e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105235:	00 
  105236:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  10523d:	40 
  10523e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105241:	89 44 24 04          	mov    %eax,0x4(%esp)
  105245:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10524c:	e8 1c f1 ff ff       	call   10436d <pmap_insert>
  105251:	85 c0                	test   %eax,%eax
  105253:	75 24                	jne    105279 <pmap_check+0x3f7>
  105255:	c7 44 24 0c e4 96 10 	movl   $0x1096e4,0xc(%esp)
  10525c:	00 
  10525d:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105264:	00 
  105265:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
  10526c:	00 
  10526d:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105274:	e8 08 b2 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  105279:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105280:	40 
  105281:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105288:	e8 88 fb ff ff       	call   104e15 <va2pa>
  10528d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  105290:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  105296:	89 cb                	mov    %ecx,%ebx
  105298:	29 d3                	sub    %edx,%ebx
  10529a:	89 da                	mov    %ebx,%edx
  10529c:	c1 fa 03             	sar    $0x3,%edx
  10529f:	c1 e2 0c             	shl    $0xc,%edx
  1052a2:	39 d0                	cmp    %edx,%eax
  1052a4:	74 24                	je     1052ca <pmap_check+0x448>
  1052a6:	c7 44 24 0c 1c 97 10 	movl   $0x10971c,0xc(%esp)
  1052ad:	00 
  1052ae:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1052b5:	00 
  1052b6:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
  1052bd:	00 
  1052be:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1052c5:	e8 b7 b1 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  1052ca:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1052cd:	8b 40 04             	mov    0x4(%eax),%eax
  1052d0:	83 f8 01             	cmp    $0x1,%eax
  1052d3:	74 24                	je     1052f9 <pmap_check+0x477>
  1052d5:	c7 44 24 0c 59 97 10 	movl   $0x109759,0xc(%esp)
  1052dc:	00 
  1052dd:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1052e4:	00 
  1052e5:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
  1052ec:	00 
  1052ed:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1052f4:	e8 88 b1 ff ff       	call   100481 <debug_panic>

	// pi2 should NOT be on the free list
	// could hapien in ref counts are handled slopiily in pmap_insert
	assert(mem_alloc() == NULL);
  1052f9:	e8 0f b8 ff ff       	call   100b0d <mem_alloc>
  1052fe:	85 c0                	test   %eax,%eax
  105300:	74 24                	je     105326 <pmap_check+0x4a4>
  105302:	c7 44 24 0c c8 95 10 	movl   $0x1095c8,0xc(%esp)
  105309:	00 
  10530a:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105311:	00 
  105312:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
  105319:	00 
  10531a:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105321:	e8 5b b1 ff ff       	call   100481 <debug_panic>

	// check that pmap_walk returns a pointer to the pte
	ptep = mem_ptr(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PAGESIZE)]));
  105326:	a1 00 04 32 00       	mov    0x320400,%eax
  10532b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105330:	89 45 e8             	mov    %eax,-0x18(%ebp)
	assert(pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0)
  105333:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10533a:	00 
  10533b:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105342:	40 
  105343:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10534a:	e8 23 ee ff ff       	call   104172 <pmap_walk>
  10534f:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105352:	83 c2 04             	add    $0x4,%edx
  105355:	39 d0                	cmp    %edx,%eax
  105357:	74 24                	je     10537d <pmap_check+0x4fb>
  105359:	c7 44 24 0c 6c 97 10 	movl   $0x10976c,0xc(%esp)
  105360:	00 
  105361:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105368:	00 
  105369:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
  105370:	00 
  105371:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105378:	e8 04 b1 ff ff       	call   100481 <debug_panic>
		== ptep+PTX(VM_USERLO+PAGESIZE));

	// should be able to change permissions too.
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, PTE_U));
  10537d:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  105384:	00 
  105385:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  10538c:	40 
  10538d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105390:	89 44 24 04          	mov    %eax,0x4(%esp)
  105394:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10539b:	e8 cd ef ff ff       	call   10436d <pmap_insert>
  1053a0:	85 c0                	test   %eax,%eax
  1053a2:	75 24                	jne    1053c8 <pmap_check+0x546>
  1053a4:	c7 44 24 0c bc 97 10 	movl   $0x1097bc,0xc(%esp)
  1053ab:	00 
  1053ac:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1053b3:	00 
  1053b4:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
  1053bb:	00 
  1053bc:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1053c3:	e8 b9 b0 ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  1053c8:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1053cf:	40 
  1053d0:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1053d7:	e8 39 fa ff ff       	call   104e15 <va2pa>
  1053dc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1053df:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  1053e5:	89 cb                	mov    %ecx,%ebx
  1053e7:	29 d3                	sub    %edx,%ebx
  1053e9:	89 da                	mov    %ebx,%edx
  1053eb:	c1 fa 03             	sar    $0x3,%edx
  1053ee:	c1 e2 0c             	shl    $0xc,%edx
  1053f1:	39 d0                	cmp    %edx,%eax
  1053f3:	74 24                	je     105419 <pmap_check+0x597>
  1053f5:	c7 44 24 0c 1c 97 10 	movl   $0x10971c,0xc(%esp)
  1053fc:	00 
  1053fd:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105404:	00 
  105405:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
  10540c:	00 
  10540d:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105414:	e8 68 b0 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  105419:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10541c:	8b 40 04             	mov    0x4(%eax),%eax
  10541f:	83 f8 01             	cmp    $0x1,%eax
  105422:	74 24                	je     105448 <pmap_check+0x5c6>
  105424:	c7 44 24 0c 59 97 10 	movl   $0x109759,0xc(%esp)
  10542b:	00 
  10542c:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105433:	00 
  105434:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
  10543b:	00 
  10543c:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105443:	e8 39 b0 ff ff       	call   100481 <debug_panic>
	assert(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U);
  105448:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10544f:	00 
  105450:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105457:	40 
  105458:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10545f:	e8 0e ed ff ff       	call   104172 <pmap_walk>
  105464:	8b 00                	mov    (%eax),%eax
  105466:	83 e0 04             	and    $0x4,%eax
  105469:	85 c0                	test   %eax,%eax
  10546b:	75 24                	jne    105491 <pmap_check+0x60f>
  10546d:	c7 44 24 0c f8 97 10 	movl   $0x1097f8,0xc(%esp)
  105474:	00 
  105475:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10547c:	00 
  10547d:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
  105484:	00 
  105485:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10548c:	e8 f0 af ff ff       	call   100481 <debug_panic>
	assert(pmap_bootpdir[PDX(VM_USERLO)] & PTE_U);
  105491:	a1 00 04 32 00       	mov    0x320400,%eax
  105496:	83 e0 04             	and    $0x4,%eax
  105499:	85 c0                	test   %eax,%eax
  10549b:	75 24                	jne    1054c1 <pmap_check+0x63f>
  10549d:	c7 44 24 0c 34 98 10 	movl   $0x109834,0xc(%esp)
  1054a4:	00 
  1054a5:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1054ac:	00 
  1054ad:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
  1054b4:	00 
  1054b5:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1054bc:	e8 c0 af ff ff       	call   100481 <debug_panic>
	
	// should not be able to map at VM_USERLO+PTSIZE
	// because we need a free page for a page table
	assert(pmap_insert(pmap_bootpdir, pi0, VM_USERLO+PTSIZE, 0) == NULL);
  1054c1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1054c8:	00 
  1054c9:	c7 44 24 08 00 00 40 	movl   $0x40400000,0x8(%esp)
  1054d0:	40 
  1054d1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1054d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1054d8:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1054df:	e8 89 ee ff ff       	call   10436d <pmap_insert>
  1054e4:	85 c0                	test   %eax,%eax
  1054e6:	74 24                	je     10550c <pmap_check+0x68a>
  1054e8:	c7 44 24 0c 5c 98 10 	movl   $0x10985c,0xc(%esp)
  1054ef:	00 
  1054f0:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1054f7:	00 
  1054f8:	c7 44 24 04 49 02 00 	movl   $0x249,0x4(%esp)
  1054ff:	00 
  105500:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105507:	e8 75 af ff ff       	call   100481 <debug_panic>

	// insert pi1 at VM_USERLO+PAGESIZE (replacing pi2)
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO+PAGESIZE, 0));
  10550c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105513:	00 
  105514:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  10551b:	40 
  10551c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10551f:	89 44 24 04          	mov    %eax,0x4(%esp)
  105523:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10552a:	e8 3e ee ff ff       	call   10436d <pmap_insert>
  10552f:	85 c0                	test   %eax,%eax
  105531:	75 24                	jne    105557 <pmap_check+0x6d5>
  105533:	c7 44 24 0c 9c 98 10 	movl   $0x10989c,0xc(%esp)
  10553a:	00 
  10553b:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105542:	00 
  105543:	c7 44 24 04 4c 02 00 	movl   $0x24c,0x4(%esp)
  10554a:	00 
  10554b:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105552:	e8 2a af ff ff       	call   100481 <debug_panic>
	assert(!(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U));
  105557:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10555e:	00 
  10555f:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105566:	40 
  105567:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10556e:	e8 ff eb ff ff       	call   104172 <pmap_walk>
  105573:	8b 00                	mov    (%eax),%eax
  105575:	83 e0 04             	and    $0x4,%eax
  105578:	85 c0                	test   %eax,%eax
  10557a:	74 24                	je     1055a0 <pmap_check+0x71e>
  10557c:	c7 44 24 0c d4 98 10 	movl   $0x1098d4,0xc(%esp)
  105583:	00 
  105584:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10558b:	00 
  10558c:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
  105593:	00 
  105594:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10559b:	e8 e1 ae ff ff       	call   100481 <debug_panic>

	// should have pi1 at both +0 and +PAGESIZE, pi2 nowhere, ...
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == mem_pi2phys(pi1));
  1055a0:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1055a7:	40 
  1055a8:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1055af:	e8 61 f8 ff ff       	call   104e15 <va2pa>
  1055b4:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1055b7:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  1055bd:	89 cb                	mov    %ecx,%ebx
  1055bf:	29 d3                	sub    %edx,%ebx
  1055c1:	89 da                	mov    %ebx,%edx
  1055c3:	c1 fa 03             	sar    $0x3,%edx
  1055c6:	c1 e2 0c             	shl    $0xc,%edx
  1055c9:	39 d0                	cmp    %edx,%eax
  1055cb:	74 24                	je     1055f1 <pmap_check+0x76f>
  1055cd:	c7 44 24 0c 10 99 10 	movl   $0x109910,0xc(%esp)
  1055d4:	00 
  1055d5:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1055dc:	00 
  1055dd:	c7 44 24 04 50 02 00 	movl   $0x250,0x4(%esp)
  1055e4:	00 
  1055e5:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1055ec:	e8 90 ae ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  1055f1:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1055f8:	40 
  1055f9:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105600:	e8 10 f8 ff ff       	call   104e15 <va2pa>
  105605:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  105608:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  10560e:	89 cb                	mov    %ecx,%ebx
  105610:	29 d3                	sub    %edx,%ebx
  105612:	89 da                	mov    %ebx,%edx
  105614:	c1 fa 03             	sar    $0x3,%edx
  105617:	c1 e2 0c             	shl    $0xc,%edx
  10561a:	39 d0                	cmp    %edx,%eax
  10561c:	74 24                	je     105642 <pmap_check+0x7c0>
  10561e:	c7 44 24 0c 48 99 10 	movl   $0x109948,0xc(%esp)
  105625:	00 
  105626:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10562d:	00 
  10562e:	c7 44 24 04 51 02 00 	movl   $0x251,0x4(%esp)
  105635:	00 
  105636:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10563d:	e8 3f ae ff ff       	call   100481 <debug_panic>
	// ... and ref counts should reflect this
	assert(pi1->refcount == 2);
  105642:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105645:	8b 40 04             	mov    0x4(%eax),%eax
  105648:	83 f8 02             	cmp    $0x2,%eax
  10564b:	74 24                	je     105671 <pmap_check+0x7ef>
  10564d:	c7 44 24 0c 85 99 10 	movl   $0x109985,0xc(%esp)
  105654:	00 
  105655:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10565c:	00 
  10565d:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
  105664:	00 
  105665:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10566c:	e8 10 ae ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 0);
  105671:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105674:	8b 40 04             	mov    0x4(%eax),%eax
  105677:	85 c0                	test   %eax,%eax
  105679:	74 24                	je     10569f <pmap_check+0x81d>
  10567b:	c7 44 24 0c 98 99 10 	movl   $0x109998,0xc(%esp)
  105682:	00 
  105683:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10568a:	00 
  10568b:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
  105692:	00 
  105693:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10569a:	e8 e2 ad ff ff       	call   100481 <debug_panic>

	// pi2 should be returned by mem_alloc
	assert(mem_alloc() == pi2);
  10569f:	e8 69 b4 ff ff       	call   100b0d <mem_alloc>
  1056a4:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  1056a7:	74 24                	je     1056cd <pmap_check+0x84b>
  1056a9:	c7 44 24 0c ab 99 10 	movl   $0x1099ab,0xc(%esp)
  1056b0:	00 
  1056b1:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1056b8:	00 
  1056b9:	c7 44 24 04 57 02 00 	movl   $0x257,0x4(%esp)
  1056c0:	00 
  1056c1:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1056c8:	e8 b4 ad ff ff       	call   100481 <debug_panic>

	// unmapping pi1 at VM_USERLO+0 should keep pi1 at +PAGESIZE
	pmap_remove(pmap_bootpdir, VM_USERLO+0, PAGESIZE);
  1056cd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1056d4:	00 
  1056d5:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1056dc:	40 
  1056dd:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1056e4:	e8 4c ee ff ff       	call   104535 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  1056e9:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1056f0:	40 
  1056f1:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1056f8:	e8 18 f7 ff ff       	call   104e15 <va2pa>
  1056fd:	83 f8 ff             	cmp    $0xffffffff,%eax
  105700:	74 24                	je     105726 <pmap_check+0x8a4>
  105702:	c7 44 24 0c c0 99 10 	movl   $0x1099c0,0xc(%esp)
  105709:	00 
  10570a:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105711:	00 
  105712:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
  105719:	00 
  10571a:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105721:	e8 5b ad ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  105726:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10572d:	40 
  10572e:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105735:	e8 db f6 ff ff       	call   104e15 <va2pa>
  10573a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  10573d:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  105743:	89 cb                	mov    %ecx,%ebx
  105745:	29 d3                	sub    %edx,%ebx
  105747:	89 da                	mov    %ebx,%edx
  105749:	c1 fa 03             	sar    $0x3,%edx
  10574c:	c1 e2 0c             	shl    $0xc,%edx
  10574f:	39 d0                	cmp    %edx,%eax
  105751:	74 24                	je     105777 <pmap_check+0x8f5>
  105753:	c7 44 24 0c 48 99 10 	movl   $0x109948,0xc(%esp)
  10575a:	00 
  10575b:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105762:	00 
  105763:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
  10576a:	00 
  10576b:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105772:	e8 0a ad ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 1);
  105777:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10577a:	8b 40 04             	mov    0x4(%eax),%eax
  10577d:	83 f8 01             	cmp    $0x1,%eax
  105780:	74 24                	je     1057a6 <pmap_check+0x924>
  105782:	c7 44 24 0c bc 96 10 	movl   $0x1096bc,0xc(%esp)
  105789:	00 
  10578a:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105791:	00 
  105792:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
  105799:	00 
  10579a:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1057a1:	e8 db ac ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 0);
  1057a6:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1057a9:	8b 40 04             	mov    0x4(%eax),%eax
  1057ac:	85 c0                	test   %eax,%eax
  1057ae:	74 24                	je     1057d4 <pmap_check+0x952>
  1057b0:	c7 44 24 0c 98 99 10 	movl   $0x109998,0xc(%esp)
  1057b7:	00 
  1057b8:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1057bf:	00 
  1057c0:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
  1057c7:	00 
  1057c8:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1057cf:	e8 ad ac ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == NULL);	// still should have no pages free
  1057d4:	e8 34 b3 ff ff       	call   100b0d <mem_alloc>
  1057d9:	85 c0                	test   %eax,%eax
  1057db:	74 24                	je     105801 <pmap_check+0x97f>
  1057dd:	c7 44 24 0c c8 95 10 	movl   $0x1095c8,0xc(%esp)
  1057e4:	00 
  1057e5:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1057ec:	00 
  1057ed:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
  1057f4:	00 
  1057f5:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1057fc:	e8 80 ac ff ff       	call   100481 <debug_panic>

	// unmapping pi1 at VM_USERLO+PAGESIZE should free it
	pmap_remove(pmap_bootpdir, VM_USERLO+PAGESIZE, PAGESIZE);
  105801:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105808:	00 
  105809:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105810:	40 
  105811:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105818:	e8 18 ed ff ff       	call   104535 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  10581d:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105824:	40 
  105825:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10582c:	e8 e4 f5 ff ff       	call   104e15 <va2pa>
  105831:	83 f8 ff             	cmp    $0xffffffff,%eax
  105834:	74 24                	je     10585a <pmap_check+0x9d8>
  105836:	c7 44 24 0c c0 99 10 	movl   $0x1099c0,0xc(%esp)
  10583d:	00 
  10583e:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105845:	00 
  105846:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
  10584d:	00 
  10584e:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105855:	e8 27 ac ff ff       	call   100481 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == ~0);
  10585a:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105861:	40 
  105862:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105869:	e8 a7 f5 ff ff       	call   104e15 <va2pa>
  10586e:	83 f8 ff             	cmp    $0xffffffff,%eax
  105871:	74 24                	je     105897 <pmap_check+0xa15>
  105873:	c7 44 24 0c e8 99 10 	movl   $0x1099e8,0xc(%esp)
  10587a:	00 
  10587b:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105882:	00 
  105883:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
  10588a:	00 
  10588b:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105892:	e8 ea ab ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 0);
  105897:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10589a:	8b 40 04             	mov    0x4(%eax),%eax
  10589d:	85 c0                	test   %eax,%eax
  10589f:	74 24                	je     1058c5 <pmap_check+0xa43>
  1058a1:	c7 44 24 0c 17 9a 10 	movl   $0x109a17,0xc(%esp)
  1058a8:	00 
  1058a9:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1058b0:	00 
  1058b1:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
  1058b8:	00 
  1058b9:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1058c0:	e8 bc ab ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 0);
  1058c5:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1058c8:	8b 40 04             	mov    0x4(%eax),%eax
  1058cb:	85 c0                	test   %eax,%eax
  1058cd:	74 24                	je     1058f3 <pmap_check+0xa71>
  1058cf:	c7 44 24 0c 98 99 10 	movl   $0x109998,0xc(%esp)
  1058d6:	00 
  1058d7:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1058de:	00 
  1058df:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
  1058e6:	00 
  1058e7:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1058ee:	e8 8e ab ff ff       	call   100481 <debug_panic>

	// so it should be returned by page_alloc
	assert(mem_alloc() == pi1);
  1058f3:	e8 15 b2 ff ff       	call   100b0d <mem_alloc>
  1058f8:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  1058fb:	74 24                	je     105921 <pmap_check+0xa9f>
  1058fd:	c7 44 24 0c 2a 9a 10 	movl   $0x109a2a,0xc(%esp)
  105904:	00 
  105905:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10590c:	00 
  10590d:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
  105914:	00 
  105915:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10591c:	e8 60 ab ff ff       	call   100481 <debug_panic>

	// should once again have no free memory
	assert(mem_alloc() == NULL);
  105921:	e8 e7 b1 ff ff       	call   100b0d <mem_alloc>
  105926:	85 c0                	test   %eax,%eax
  105928:	74 24                	je     10594e <pmap_check+0xacc>
  10592a:	c7 44 24 0c c8 95 10 	movl   $0x1095c8,0xc(%esp)
  105931:	00 
  105932:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105939:	00 
  10593a:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
  105941:	00 
  105942:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105949:	e8 33 ab ff ff       	call   100481 <debug_panic>

	// should be able to pmap_insert to change a page
	// and see the new data immediately.
	memset(mem_pi2ptr(pi1), 1, PAGESIZE);
  10594e:	8b 55 d8             	mov    -0x28(%ebp),%edx
  105951:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  105956:	89 d1                	mov    %edx,%ecx
  105958:	29 c1                	sub    %eax,%ecx
  10595a:	89 c8                	mov    %ecx,%eax
  10595c:	c1 f8 03             	sar    $0x3,%eax
  10595f:	c1 e0 0c             	shl    $0xc,%eax
  105962:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105969:	00 
  10596a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105971:	00 
  105972:	89 04 24             	mov    %eax,(%esp)
  105975:	e8 ca 23 00 00       	call   107d44 <memset>
	memset(mem_pi2ptr(pi2), 2, PAGESIZE);
  10597a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10597d:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  105982:	89 d3                	mov    %edx,%ebx
  105984:	29 c3                	sub    %eax,%ebx
  105986:	89 d8                	mov    %ebx,%eax
  105988:	c1 f8 03             	sar    $0x3,%eax
  10598b:	c1 e0 0c             	shl    $0xc,%eax
  10598e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105995:	00 
  105996:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  10599d:	00 
  10599e:	89 04 24             	mov    %eax,(%esp)
  1059a1:	e8 9e 23 00 00       	call   107d44 <memset>
	pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0);
  1059a6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1059ad:	00 
  1059ae:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  1059b5:	40 
  1059b6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1059b9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059bd:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1059c4:	e8 a4 e9 ff ff       	call   10436d <pmap_insert>
	assert(pi1->refcount == 1);
  1059c9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1059cc:	8b 40 04             	mov    0x4(%eax),%eax
  1059cf:	83 f8 01             	cmp    $0x1,%eax
  1059d2:	74 24                	je     1059f8 <pmap_check+0xb76>
  1059d4:	c7 44 24 0c bc 96 10 	movl   $0x1096bc,0xc(%esp)
  1059db:	00 
  1059dc:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1059e3:	00 
  1059e4:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
  1059eb:	00 
  1059ec:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1059f3:	e8 89 aa ff ff       	call   100481 <debug_panic>
	assert(*(int*)VM_USERLO == 0x01010101);
  1059f8:	b8 00 00 00 40       	mov    $0x40000000,%eax
  1059fd:	8b 00                	mov    (%eax),%eax
  1059ff:	3d 01 01 01 01       	cmp    $0x1010101,%eax
  105a04:	74 24                	je     105a2a <pmap_check+0xba8>
  105a06:	c7 44 24 0c 40 9a 10 	movl   $0x109a40,0xc(%esp)
  105a0d:	00 
  105a0e:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105a15:	00 
  105a16:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
  105a1d:	00 
  105a1e:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105a25:	e8 57 aa ff ff       	call   100481 <debug_panic>
	pmap_insert(pmap_bootpdir, pi2, VM_USERLO, 0);
  105a2a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105a31:	00 
  105a32:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  105a39:	40 
  105a3a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105a3d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a41:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105a48:	e8 20 e9 ff ff       	call   10436d <pmap_insert>
	assert(*(int*)VM_USERLO == 0x02020202);
  105a4d:	b8 00 00 00 40       	mov    $0x40000000,%eax
  105a52:	8b 00                	mov    (%eax),%eax
  105a54:	3d 02 02 02 02       	cmp    $0x2020202,%eax
  105a59:	74 24                	je     105a7f <pmap_check+0xbfd>
  105a5b:	c7 44 24 0c 60 9a 10 	movl   $0x109a60,0xc(%esp)
  105a62:	00 
  105a63:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105a6a:	00 
  105a6b:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
  105a72:	00 
  105a73:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105a7a:	e8 02 aa ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  105a7f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105a82:	8b 40 04             	mov    0x4(%eax),%eax
  105a85:	83 f8 01             	cmp    $0x1,%eax
  105a88:	74 24                	je     105aae <pmap_check+0xc2c>
  105a8a:	c7 44 24 0c 59 97 10 	movl   $0x109759,0xc(%esp)
  105a91:	00 
  105a92:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105a99:	00 
  105a9a:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
  105aa1:	00 
  105aa2:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105aa9:	e8 d3 a9 ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 0);
  105aae:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105ab1:	8b 40 04             	mov    0x4(%eax),%eax
  105ab4:	85 c0                	test   %eax,%eax
  105ab6:	74 24                	je     105adc <pmap_check+0xc5a>
  105ab8:	c7 44 24 0c 17 9a 10 	movl   $0x109a17,0xc(%esp)
  105abf:	00 
  105ac0:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105ac7:	00 
  105ac8:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
  105acf:	00 
  105ad0:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105ad7:	e8 a5 a9 ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == pi1);
  105adc:	e8 2c b0 ff ff       	call   100b0d <mem_alloc>
  105ae1:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  105ae4:	74 24                	je     105b0a <pmap_check+0xc88>
  105ae6:	c7 44 24 0c 2a 9a 10 	movl   $0x109a2a,0xc(%esp)
  105aed:	00 
  105aee:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105af5:	00 
  105af6:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
  105afd:	00 
  105afe:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105b05:	e8 77 a9 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, VM_USERLO, PAGESIZE);
  105b0a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105b11:	00 
  105b12:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105b19:	40 
  105b1a:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105b21:	e8 0f ea ff ff       	call   104535 <pmap_remove>
	assert(pi2->refcount == 0);
  105b26:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105b29:	8b 40 04             	mov    0x4(%eax),%eax
  105b2c:	85 c0                	test   %eax,%eax
  105b2e:	74 24                	je     105b54 <pmap_check+0xcd2>
  105b30:	c7 44 24 0c 98 99 10 	movl   $0x109998,0xc(%esp)
  105b37:	00 
  105b38:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105b3f:	00 
  105b40:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
  105b47:	00 
  105b48:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105b4f:	e8 2d a9 ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == pi2);
  105b54:	e8 b4 af ff ff       	call   100b0d <mem_alloc>
  105b59:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  105b5c:	74 24                	je     105b82 <pmap_check+0xd00>
  105b5e:	c7 44 24 0c ab 99 10 	movl   $0x1099ab,0xc(%esp)
  105b65:	00 
  105b66:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105b6d:	00 
  105b6e:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
  105b75:	00 
  105b76:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105b7d:	e8 ff a8 ff ff       	call   100481 <debug_panic>

	// now use a pmap_remove on a large region to take pi0 back
	cprintf("===================wrong here:\n");
  105b82:	c7 04 24 80 9a 10 00 	movl   $0x109a80,(%esp)
  105b89:	e8 d1 1f 00 00       	call   107b5f <cprintf>
	pmap_remove(pmap_bootpdir, VM_USERLO, VM_USERHI-VM_USERLO);
  105b8e:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  105b95:	b0 
  105b96:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105b9d:	40 
  105b9e:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105ba5:	e8 8b e9 ff ff       	call   104535 <pmap_remove>
	assert(pmap_bootpdir[PDX(VM_USERLO)] == PTE_ZERO);
  105baa:	8b 15 00 04 32 00    	mov    0x320400,%edx
  105bb0:	b8 00 10 32 00       	mov    $0x321000,%eax
  105bb5:	39 c2                	cmp    %eax,%edx
  105bb7:	74 24                	je     105bdd <pmap_check+0xd5b>
  105bb9:	c7 44 24 0c a0 9a 10 	movl   $0x109aa0,0xc(%esp)
  105bc0:	00 
  105bc1:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105bc8:	00 
  105bc9:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
  105bd0:	00 
  105bd1:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105bd8:	e8 a4 a8 ff ff       	call   100481 <debug_panic>
	assert(pi0->refcount == 0);
  105bdd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105be0:	8b 40 04             	mov    0x4(%eax),%eax
  105be3:	85 c0                	test   %eax,%eax
  105be5:	74 24                	je     105c0b <pmap_check+0xd89>
  105be7:	c7 44 24 0c ca 9a 10 	movl   $0x109aca,0xc(%esp)
  105bee:	00 
  105bef:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105bf6:	00 
  105bf7:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
  105bfe:	00 
  105bff:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105c06:	e8 76 a8 ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == pi0);
  105c0b:	e8 fd ae ff ff       	call   100b0d <mem_alloc>
  105c10:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  105c13:	74 24                	je     105c39 <pmap_check+0xdb7>
  105c15:	c7 44 24 0c dd 9a 10 	movl   $0x109add,0xc(%esp)
  105c1c:	00 
  105c1d:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105c24:	00 
  105c25:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
  105c2c:	00 
  105c2d:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105c34:	e8 48 a8 ff ff       	call   100481 <debug_panic>
	assert(mem_freelist == NULL);
  105c39:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  105c3e:	85 c0                	test   %eax,%eax
  105c40:	74 24                	je     105c66 <pmap_check+0xde4>
  105c42:	c7 44 24 0c f0 9a 10 	movl   $0x109af0,0xc(%esp)
  105c49:	00 
  105c4a:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105c51:	00 
  105c52:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
  105c59:	00 
  105c5a:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105c61:	e8 1b a8 ff ff       	call   100481 <debug_panic>

	// test pmap_remove with large, non-ptable-aligned regions
	mem_free(pi1);
  105c66:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105c69:	89 04 24             	mov    %eax,(%esp)
  105c6c:	e8 e3 ae ff ff       	call   100b54 <mem_free>
	uintptr_t va = VM_USERLO;
  105c71:	c7 45 f4 00 00 00 40 	movl   $0x40000000,-0xc(%ebp)
	assert(pmap_insert(pmap_bootpdir, pi0, va, 0));
  105c78:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105c7f:	00 
  105c80:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105c83:	89 44 24 08          	mov    %eax,0x8(%esp)
  105c87:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105c8a:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c8e:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105c95:	e8 d3 e6 ff ff       	call   10436d <pmap_insert>
  105c9a:	85 c0                	test   %eax,%eax
  105c9c:	75 24                	jne    105cc2 <pmap_check+0xe40>
  105c9e:	c7 44 24 0c 08 9b 10 	movl   $0x109b08,0xc(%esp)
  105ca5:	00 
  105ca6:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105cad:	00 
  105cae:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
  105cb5:	00 
  105cb6:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105cbd:	e8 bf a7 ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PAGESIZE, 0));
  105cc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105cc5:	05 00 10 00 00       	add    $0x1000,%eax
  105cca:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105cd1:	00 
  105cd2:	89 44 24 08          	mov    %eax,0x8(%esp)
  105cd6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105cd9:	89 44 24 04          	mov    %eax,0x4(%esp)
  105cdd:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105ce4:	e8 84 e6 ff ff       	call   10436d <pmap_insert>
  105ce9:	85 c0                	test   %eax,%eax
  105ceb:	75 24                	jne    105d11 <pmap_check+0xe8f>
  105ced:	c7 44 24 0c 30 9b 10 	movl   $0x109b30,0xc(%esp)
  105cf4:	00 
  105cf5:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105cfc:	00 
  105cfd:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
  105d04:	00 
  105d05:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105d0c:	e8 70 a7 ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE-PAGESIZE, 0));
  105d11:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105d14:	05 00 f0 3f 00       	add    $0x3ff000,%eax
  105d19:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105d20:	00 
  105d21:	89 44 24 08          	mov    %eax,0x8(%esp)
  105d25:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105d28:	89 44 24 04          	mov    %eax,0x4(%esp)
  105d2c:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105d33:	e8 35 e6 ff ff       	call   10436d <pmap_insert>
  105d38:	85 c0                	test   %eax,%eax
  105d3a:	75 24                	jne    105d60 <pmap_check+0xede>
  105d3c:	c7 44 24 0c 60 9b 10 	movl   $0x109b60,0xc(%esp)
  105d43:	00 
  105d44:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105d4b:	00 
  105d4c:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
  105d53:	00 
  105d54:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105d5b:	e8 21 a7 ff ff       	call   100481 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi1));
  105d60:	a1 00 04 32 00       	mov    0x320400,%eax
  105d65:	89 c1                	mov    %eax,%ecx
  105d67:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  105d6d:	8b 55 d8             	mov    -0x28(%ebp),%edx
  105d70:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  105d75:	89 d3                	mov    %edx,%ebx
  105d77:	29 c3                	sub    %eax,%ebx
  105d79:	89 d8                	mov    %ebx,%eax
  105d7b:	c1 f8 03             	sar    $0x3,%eax
  105d7e:	c1 e0 0c             	shl    $0xc,%eax
  105d81:	39 c1                	cmp    %eax,%ecx
  105d83:	74 24                	je     105da9 <pmap_check+0xf27>
  105d85:	c7 44 24 0c 98 9b 10 	movl   $0x109b98,0xc(%esp)
  105d8c:	00 
  105d8d:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105d94:	00 
  105d95:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
  105d9c:	00 
  105d9d:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105da4:	e8 d8 a6 ff ff       	call   100481 <debug_panic>
	assert(mem_freelist == NULL);
  105da9:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  105dae:	85 c0                	test   %eax,%eax
  105db0:	74 24                	je     105dd6 <pmap_check+0xf54>
  105db2:	c7 44 24 0c f0 9a 10 	movl   $0x109af0,0xc(%esp)
  105db9:	00 
  105dba:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105dc1:	00 
  105dc2:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
  105dc9:	00 
  105dca:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105dd1:	e8 ab a6 ff ff       	call   100481 <debug_panic>
	mem_free(pi2);
  105dd6:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105dd9:	89 04 24             	mov    %eax,(%esp)
  105ddc:	e8 73 ad ff ff       	call   100b54 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE, 0));
  105de1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105de4:	05 00 00 40 00       	add    $0x400000,%eax
  105de9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105df0:	00 
  105df1:	89 44 24 08          	mov    %eax,0x8(%esp)
  105df5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105df8:	89 44 24 04          	mov    %eax,0x4(%esp)
  105dfc:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105e03:	e8 65 e5 ff ff       	call   10436d <pmap_insert>
  105e08:	85 c0                	test   %eax,%eax
  105e0a:	75 24                	jne    105e30 <pmap_check+0xfae>
  105e0c:	c7 44 24 0c d4 9b 10 	movl   $0x109bd4,0xc(%esp)
  105e13:	00 
  105e14:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105e1b:	00 
  105e1c:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
  105e23:	00 
  105e24:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105e2b:	e8 51 a6 ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE+PAGESIZE, 0));
  105e30:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105e33:	05 00 10 40 00       	add    $0x401000,%eax
  105e38:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105e3f:	00 
  105e40:	89 44 24 08          	mov    %eax,0x8(%esp)
  105e44:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105e47:	89 44 24 04          	mov    %eax,0x4(%esp)
  105e4b:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105e52:	e8 16 e5 ff ff       	call   10436d <pmap_insert>
  105e57:	85 c0                	test   %eax,%eax
  105e59:	75 24                	jne    105e7f <pmap_check+0xffd>
  105e5b:	c7 44 24 0c 04 9c 10 	movl   $0x109c04,0xc(%esp)
  105e62:	00 
  105e63:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105e6a:	00 
  105e6b:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
  105e72:	00 
  105e73:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105e7a:	e8 02 a6 ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2-PAGESIZE, 0));
  105e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105e82:	05 00 f0 7f 00       	add    $0x7ff000,%eax
  105e87:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105e8e:	00 
  105e8f:	89 44 24 08          	mov    %eax,0x8(%esp)
  105e93:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105e96:	89 44 24 04          	mov    %eax,0x4(%esp)
  105e9a:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105ea1:	e8 c7 e4 ff ff       	call   10436d <pmap_insert>
  105ea6:	85 c0                	test   %eax,%eax
  105ea8:	75 24                	jne    105ece <pmap_check+0x104c>
  105eaa:	c7 44 24 0c 3c 9c 10 	movl   $0x109c3c,0xc(%esp)
  105eb1:	00 
  105eb2:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105eb9:	00 
  105eba:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
  105ec1:	00 
  105ec2:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105ec9:	e8 b3 a5 ff ff       	call   100481 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE)])
  105ece:	a1 04 04 32 00       	mov    0x320404,%eax
  105ed3:	89 c1                	mov    %eax,%ecx
  105ed5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  105edb:	8b 55 dc             	mov    -0x24(%ebp),%edx
  105ede:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  105ee3:	89 d3                	mov    %edx,%ebx
  105ee5:	29 c3                	sub    %eax,%ebx
  105ee7:	89 d8                	mov    %ebx,%eax
  105ee9:	c1 f8 03             	sar    $0x3,%eax
  105eec:	c1 e0 0c             	shl    $0xc,%eax
  105eef:	39 c1                	cmp    %eax,%ecx
  105ef1:	74 24                	je     105f17 <pmap_check+0x1095>
  105ef3:	c7 44 24 0c 78 9c 10 	movl   $0x109c78,0xc(%esp)
  105efa:	00 
  105efb:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105f02:	00 
  105f03:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
  105f0a:	00 
  105f0b:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105f12:	e8 6a a5 ff ff       	call   100481 <debug_panic>
		== mem_pi2phys(pi2));
	assert(mem_freelist == NULL);
  105f17:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  105f1c:	85 c0                	test   %eax,%eax
  105f1e:	74 24                	je     105f44 <pmap_check+0x10c2>
  105f20:	c7 44 24 0c f0 9a 10 	movl   $0x109af0,0xc(%esp)
  105f27:	00 
  105f28:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105f2f:	00 
  105f30:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
  105f37:	00 
  105f38:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105f3f:	e8 3d a5 ff ff       	call   100481 <debug_panic>
	mem_free(pi3);
  105f44:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105f47:	89 04 24             	mov    %eax,(%esp)
  105f4a:	e8 05 ac ff ff       	call   100b54 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2, 0));
  105f4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105f52:	05 00 00 80 00       	add    $0x800000,%eax
  105f57:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105f5e:	00 
  105f5f:	89 44 24 08          	mov    %eax,0x8(%esp)
  105f63:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105f66:	89 44 24 04          	mov    %eax,0x4(%esp)
  105f6a:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105f71:	e8 f7 e3 ff ff       	call   10436d <pmap_insert>
  105f76:	85 c0                	test   %eax,%eax
  105f78:	75 24                	jne    105f9e <pmap_check+0x111c>
  105f7a:	c7 44 24 0c bc 9c 10 	movl   $0x109cbc,0xc(%esp)
  105f81:	00 
  105f82:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105f89:	00 
  105f8a:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
  105f91:	00 
  105f92:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105f99:	e8 e3 a4 ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2+PAGESIZE, 0));
  105f9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105fa1:	05 00 10 80 00       	add    $0x801000,%eax
  105fa6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105fad:	00 
  105fae:	89 44 24 08          	mov    %eax,0x8(%esp)
  105fb2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105fb5:	89 44 24 04          	mov    %eax,0x4(%esp)
  105fb9:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105fc0:	e8 a8 e3 ff ff       	call   10436d <pmap_insert>
  105fc5:	85 c0                	test   %eax,%eax
  105fc7:	75 24                	jne    105fed <pmap_check+0x116b>
  105fc9:	c7 44 24 0c ec 9c 10 	movl   $0x109cec,0xc(%esp)
  105fd0:	00 
  105fd1:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  105fd8:	00 
  105fd9:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
  105fe0:	00 
  105fe1:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  105fe8:	e8 94 a4 ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE*2, 0));
  105fed:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105ff0:	05 00 e0 bf 00       	add    $0xbfe000,%eax
  105ff5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105ffc:	00 
  105ffd:	89 44 24 08          	mov    %eax,0x8(%esp)
  106001:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106004:	89 44 24 04          	mov    %eax,0x4(%esp)
  106008:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10600f:	e8 59 e3 ff ff       	call   10436d <pmap_insert>
  106014:	85 c0                	test   %eax,%eax
  106016:	75 24                	jne    10603c <pmap_check+0x11ba>
  106018:	c7 44 24 0c 28 9d 10 	movl   $0x109d28,0xc(%esp)
  10601f:	00 
  106020:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  106027:	00 
  106028:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
  10602f:	00 
  106030:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106037:	e8 45 a4 ff ff       	call   100481 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE, 0));
  10603c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10603f:	05 00 f0 bf 00       	add    $0xbff000,%eax
  106044:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10604b:	00 
  10604c:	89 44 24 08          	mov    %eax,0x8(%esp)
  106050:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106053:	89 44 24 04          	mov    %eax,0x4(%esp)
  106057:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10605e:	e8 0a e3 ff ff       	call   10436d <pmap_insert>
  106063:	85 c0                	test   %eax,%eax
  106065:	75 24                	jne    10608b <pmap_check+0x1209>
  106067:	c7 44 24 0c 64 9d 10 	movl   $0x109d64,0xc(%esp)
  10606e:	00 
  10606f:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  106076:	00 
  106077:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
  10607e:	00 
  10607f:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106086:	e8 f6 a3 ff ff       	call   100481 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE*2)])
  10608b:	a1 08 04 32 00       	mov    0x320408,%eax
  106090:	89 c1                	mov    %eax,%ecx
  106092:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  106098:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10609b:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1060a0:	89 d3                	mov    %edx,%ebx
  1060a2:	29 c3                	sub    %eax,%ebx
  1060a4:	89 d8                	mov    %ebx,%eax
  1060a6:	c1 f8 03             	sar    $0x3,%eax
  1060a9:	c1 e0 0c             	shl    $0xc,%eax
  1060ac:	39 c1                	cmp    %eax,%ecx
  1060ae:	74 24                	je     1060d4 <pmap_check+0x1252>
  1060b0:	c7 44 24 0c a0 9d 10 	movl   $0x109da0,0xc(%esp)
  1060b7:	00 
  1060b8:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1060bf:	00 
  1060c0:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
  1060c7:	00 
  1060c8:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1060cf:	e8 ad a3 ff ff       	call   100481 <debug_panic>
		== mem_pi2phys(pi3));
	assert(mem_freelist == NULL);
  1060d4:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  1060d9:	85 c0                	test   %eax,%eax
  1060db:	74 24                	je     106101 <pmap_check+0x127f>
  1060dd:	c7 44 24 0c f0 9a 10 	movl   $0x109af0,0xc(%esp)
  1060e4:	00 
  1060e5:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1060ec:	00 
  1060ed:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
  1060f4:	00 
  1060f5:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1060fc:	e8 80 a3 ff ff       	call   100481 <debug_panic>
	assert(pi0->refcount == 10);
  106101:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106104:	8b 40 04             	mov    0x4(%eax),%eax
  106107:	83 f8 0a             	cmp    $0xa,%eax
  10610a:	74 24                	je     106130 <pmap_check+0x12ae>
  10610c:	c7 44 24 0c e3 9d 10 	movl   $0x109de3,0xc(%esp)
  106113:	00 
  106114:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10611b:	00 
  10611c:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
  106123:	00 
  106124:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10612b:	e8 51 a3 ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 1);
  106130:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106133:	8b 40 04             	mov    0x4(%eax),%eax
  106136:	83 f8 01             	cmp    $0x1,%eax
  106139:	74 24                	je     10615f <pmap_check+0x12dd>
  10613b:	c7 44 24 0c bc 96 10 	movl   $0x1096bc,0xc(%esp)
  106142:	00 
  106143:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10614a:	00 
  10614b:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
  106152:	00 
  106153:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10615a:	e8 22 a3 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 1);
  10615f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  106162:	8b 40 04             	mov    0x4(%eax),%eax
  106165:	83 f8 01             	cmp    $0x1,%eax
  106168:	74 24                	je     10618e <pmap_check+0x130c>
  10616a:	c7 44 24 0c 59 97 10 	movl   $0x109759,0xc(%esp)
  106171:	00 
  106172:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  106179:	00 
  10617a:	c7 44 24 04 9f 02 00 	movl   $0x29f,0x4(%esp)
  106181:	00 
  106182:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106189:	e8 f3 a2 ff ff       	call   100481 <debug_panic>
	assert(pi3->refcount == 1);
  10618e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106191:	8b 40 04             	mov    0x4(%eax),%eax
  106194:	83 f8 01             	cmp    $0x1,%eax
  106197:	74 24                	je     1061bd <pmap_check+0x133b>
  106199:	c7 44 24 0c f7 9d 10 	movl   $0x109df7,0xc(%esp)
  1061a0:	00 
  1061a1:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1061a8:	00 
  1061a9:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
  1061b0:	00 
  1061b1:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1061b8:	e8 c4 a2 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3-PAGESIZE*2);
  1061bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1061c0:	05 00 10 00 00       	add    $0x1000,%eax
  1061c5:	c7 44 24 08 00 e0 bf 	movl   $0xbfe000,0x8(%esp)
  1061cc:	00 
  1061cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1061d1:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1061d8:	e8 58 e3 ff ff       	call   104535 <pmap_remove>
	assert(pi0->refcount == 2);
  1061dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1061e0:	8b 40 04             	mov    0x4(%eax),%eax
  1061e3:	83 f8 02             	cmp    $0x2,%eax
  1061e6:	74 24                	je     10620c <pmap_check+0x138a>
  1061e8:	c7 44 24 0c 0a 9e 10 	movl   $0x109e0a,0xc(%esp)
  1061ef:	00 
  1061f0:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1061f7:	00 
  1061f8:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
  1061ff:	00 
  106200:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106207:	e8 75 a2 ff ff       	call   100481 <debug_panic>
	assert(pi2->refcount == 0); assert(mem_alloc() == pi2);
  10620c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10620f:	8b 40 04             	mov    0x4(%eax),%eax
  106212:	85 c0                	test   %eax,%eax
  106214:	74 24                	je     10623a <pmap_check+0x13b8>
  106216:	c7 44 24 0c 98 99 10 	movl   $0x109998,0xc(%esp)
  10621d:	00 
  10621e:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  106225:	00 
  106226:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
  10622d:	00 
  10622e:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106235:	e8 47 a2 ff ff       	call   100481 <debug_panic>
  10623a:	e8 ce a8 ff ff       	call   100b0d <mem_alloc>
  10623f:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  106242:	74 24                	je     106268 <pmap_check+0x13e6>
  106244:	c7 44 24 0c ab 99 10 	movl   $0x1099ab,0xc(%esp)
  10624b:	00 
  10624c:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  106253:	00 
  106254:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
  10625b:	00 
  10625c:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106263:	e8 19 a2 ff ff       	call   100481 <debug_panic>
	assert(mem_freelist == NULL);
  106268:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  10626d:	85 c0                	test   %eax,%eax
  10626f:	74 24                	je     106295 <pmap_check+0x1413>
  106271:	c7 44 24 0c f0 9a 10 	movl   $0x109af0,0xc(%esp)
  106278:	00 
  106279:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  106280:	00 
  106281:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
  106288:	00 
  106289:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106290:	e8 ec a1 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, va, PTSIZE*3-PAGESIZE);
  106295:	c7 44 24 08 00 f0 bf 	movl   $0xbff000,0x8(%esp)
  10629c:	00 
  10629d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1062a0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1062a4:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1062ab:	e8 85 e2 ff ff       	call   104535 <pmap_remove>
	assert(pi0->refcount == 1);
  1062b0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1062b3:	8b 40 04             	mov    0x4(%eax),%eax
  1062b6:	83 f8 01             	cmp    $0x1,%eax
  1062b9:	74 24                	je     1062df <pmap_check+0x145d>
  1062bb:	c7 44 24 0c cf 96 10 	movl   $0x1096cf,0xc(%esp)
  1062c2:	00 
  1062c3:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1062ca:	00 
  1062cb:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
  1062d2:	00 
  1062d3:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1062da:	e8 a2 a1 ff ff       	call   100481 <debug_panic>
	assert(pi1->refcount == 0); assert(mem_alloc() == pi1);
  1062df:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1062e2:	8b 40 04             	mov    0x4(%eax),%eax
  1062e5:	85 c0                	test   %eax,%eax
  1062e7:	74 24                	je     10630d <pmap_check+0x148b>
  1062e9:	c7 44 24 0c 17 9a 10 	movl   $0x109a17,0xc(%esp)
  1062f0:	00 
  1062f1:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1062f8:	00 
  1062f9:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
  106300:	00 
  106301:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106308:	e8 74 a1 ff ff       	call   100481 <debug_panic>
  10630d:	e8 fb a7 ff ff       	call   100b0d <mem_alloc>
  106312:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  106315:	74 24                	je     10633b <pmap_check+0x14b9>
  106317:	c7 44 24 0c 2a 9a 10 	movl   $0x109a2a,0xc(%esp)
  10631e:	00 
  10631f:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  106326:	00 
  106327:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
  10632e:	00 
  10632f:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106336:	e8 46 a1 ff ff       	call   100481 <debug_panic>
	assert(mem_freelist == NULL);
  10633b:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  106340:	85 c0                	test   %eax,%eax
  106342:	74 24                	je     106368 <pmap_check+0x14e6>
  106344:	c7 44 24 0c f0 9a 10 	movl   $0x109af0,0xc(%esp)
  10634b:	00 
  10634c:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  106353:	00 
  106354:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
  10635b:	00 
  10635c:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106363:	e8 19 a1 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PTSIZE*3-PAGESIZE, PAGESIZE);
  106368:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10636b:	05 00 f0 bf 00       	add    $0xbff000,%eax
  106370:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  106377:	00 
  106378:	89 44 24 04          	mov    %eax,0x4(%esp)
  10637c:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106383:	e8 ad e1 ff ff       	call   104535 <pmap_remove>
	assert(pi0->refcount == 0);	// pi3 might or might not also be freed
  106388:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10638b:	8b 40 04             	mov    0x4(%eax),%eax
  10638e:	85 c0                	test   %eax,%eax
  106390:	74 24                	je     1063b6 <pmap_check+0x1534>
  106392:	c7 44 24 0c ca 9a 10 	movl   $0x109aca,0xc(%esp)
  106399:	00 
  10639a:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1063a1:	00 
  1063a2:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
  1063a9:	00 
  1063aa:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1063b1:	e8 cb a0 ff ff       	call   100481 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3);
  1063b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1063b9:	05 00 10 00 00       	add    $0x1000,%eax
  1063be:	c7 44 24 08 00 00 c0 	movl   $0xc00000,0x8(%esp)
  1063c5:	00 
  1063c6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1063ca:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1063d1:	e8 5f e1 ff ff       	call   104535 <pmap_remove>
	assert(pi3->refcount == 0);
  1063d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1063d9:	8b 40 04             	mov    0x4(%eax),%eax
  1063dc:	85 c0                	test   %eax,%eax
  1063de:	74 24                	je     106404 <pmap_check+0x1582>
  1063e0:	c7 44 24 0c 1d 9e 10 	movl   $0x109e1d,0xc(%esp)
  1063e7:	00 
  1063e8:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1063ef:	00 
  1063f0:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
  1063f7:	00 
  1063f8:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1063ff:	e8 7d a0 ff ff       	call   100481 <debug_panic>
	mem_alloc(); mem_alloc();	// collect pi0 and pi3
  106404:	e8 04 a7 ff ff       	call   100b0d <mem_alloc>
  106409:	e8 ff a6 ff ff       	call   100b0d <mem_alloc>
	assert(mem_freelist == NULL);
  10640e:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  106413:	85 c0                	test   %eax,%eax
  106415:	74 24                	je     10643b <pmap_check+0x15b9>
  106417:	c7 44 24 0c f0 9a 10 	movl   $0x109af0,0xc(%esp)
  10641e:	00 
  10641f:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  106426:	00 
  106427:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
  10642e:	00 
  10642f:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  106436:	e8 46 a0 ff ff       	call   100481 <debug_panic>

	// check pointer arithmetic in pmap_walk
	mem_free(pi0);
  10643b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10643e:	89 04 24             	mov    %eax,(%esp)
  106441:	e8 0e a7 ff ff       	call   100b54 <mem_free>
	va = VM_USERLO + PAGESIZE*NPTENTRIES + PAGESIZE;
  106446:	c7 45 f4 00 10 40 40 	movl   $0x40401000,-0xc(%ebp)
	ptep = pmap_walk(pmap_bootpdir, va, 1);
  10644d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106454:	00 
  106455:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106458:	89 44 24 04          	mov    %eax,0x4(%esp)
  10645c:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106463:	e8 0a dd ff ff       	call   104172 <pmap_walk>
  106468:	89 45 e8             	mov    %eax,-0x18(%ebp)
	ptep1 = mem_ptr(PGADDR(pmap_bootpdir[PDX(va)]));
  10646b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10646e:	c1 e8 16             	shr    $0x16,%eax
  106471:	8b 04 85 00 00 32 00 	mov    0x320000(,%eax,4),%eax
  106478:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10647d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(ptep == ptep1 + PTX(va));
  106480:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106483:	c1 e8 0c             	shr    $0xc,%eax
  106486:	25 ff 03 00 00       	and    $0x3ff,%eax
  10648b:	c1 e0 02             	shl    $0x2,%eax
  10648e:	03 45 ec             	add    -0x14(%ebp),%eax
  106491:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  106494:	74 24                	je     1064ba <pmap_check+0x1638>
  106496:	c7 44 24 0c 30 9e 10 	movl   $0x109e30,0xc(%esp)
  10649d:	00 
  10649e:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  1064a5:	00 
  1064a6:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
  1064ad:	00 
  1064ae:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  1064b5:	e8 c7 9f ff ff       	call   100481 <debug_panic>
	pmap_bootpdir[PDX(va)] = PTE_ZERO;
  1064ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1064bd:	89 c2                	mov    %eax,%edx
  1064bf:	c1 ea 16             	shr    $0x16,%edx
  1064c2:	b8 00 10 32 00       	mov    $0x321000,%eax
  1064c7:	89 04 95 00 00 32 00 	mov    %eax,0x320000(,%edx,4)
	pi0->refcount = 0;
  1064ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1064d1:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
  1064d8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1064db:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1064e0:	89 d1                	mov    %edx,%ecx
  1064e2:	29 c1                	sub    %eax,%ecx
  1064e4:	89 c8                	mov    %ecx,%eax
  1064e6:	c1 f8 03             	sar    $0x3,%eax
  1064e9:	c1 e0 0c             	shl    $0xc,%eax
  1064ec:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1064f3:	00 
  1064f4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  1064fb:	00 
  1064fc:	89 04 24             	mov    %eax,(%esp)
  1064ff:	e8 40 18 00 00       	call   107d44 <memset>
	mem_free(pi0);
  106504:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106507:	89 04 24             	mov    %eax,(%esp)
  10650a:	e8 45 a6 ff ff       	call   100b54 <mem_free>
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
  10650f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106516:	00 
  106517:	c7 44 24 04 00 f0 ff 	movl   $0xeffff000,0x4(%esp)
  10651e:	ef 
  10651f:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106526:	e8 47 dc ff ff       	call   104172 <pmap_walk>
	ptep = mem_pi2ptr(pi0);
  10652b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10652e:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  106533:	89 d3                	mov    %edx,%ebx
  106535:	29 c3                	sub    %eax,%ebx
  106537:	89 d8                	mov    %ebx,%eax
  106539:	c1 f8 03             	sar    $0x3,%eax
  10653c:	c1 e0 0c             	shl    $0xc,%eax
  10653f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for(i=0; i<NPTENTRIES; i++)
  106542:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  106549:	eb 3c                	jmp    106587 <pmap_check+0x1705>
		assert(ptep[i] == PTE_ZERO);
  10654b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10654e:	c1 e0 02             	shl    $0x2,%eax
  106551:	03 45 e8             	add    -0x18(%ebp),%eax
  106554:	8b 10                	mov    (%eax),%edx
  106556:	b8 00 10 32 00       	mov    $0x321000,%eax
  10655b:	39 c2                	cmp    %eax,%edx
  10655d:	74 24                	je     106583 <pmap_check+0x1701>
  10655f:	c7 44 24 0c 48 9e 10 	movl   $0x109e48,0xc(%esp)
  106566:	00 
  106567:	c7 44 24 08 d2 92 10 	movl   $0x1092d2,0x8(%esp)
  10656e:	00 
  10656f:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
  106576:	00 
  106577:	c7 04 24 d6 93 10 00 	movl   $0x1093d6,(%esp)
  10657e:	e8 fe 9e ff ff       	call   100481 <debug_panic>
	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
	mem_free(pi0);
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
	ptep = mem_pi2ptr(pi0);
	for(i=0; i<NPTENTRIES; i++)
  106583:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  106587:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
  10658e:	7e bb                	jle    10654b <pmap_check+0x16c9>
		assert(ptep[i] == PTE_ZERO);
	pmap_bootpdir[PDX(VM_USERHI-PAGESIZE)] = PTE_ZERO;
  106590:	b8 00 10 32 00       	mov    $0x321000,%eax
  106595:	a3 fc 0e 32 00       	mov    %eax,0x320efc
	pi0->refcount = 0;
  10659a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10659d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// give free list back
	mem_freelist = fl;
  1065a4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1065a7:	a3 00 ed 11 00       	mov    %eax,0x11ed00

	// free the pages we filched
	mem_free(pi0);
  1065ac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1065af:	89 04 24             	mov    %eax,(%esp)
  1065b2:	e8 9d a5 ff ff       	call   100b54 <mem_free>
	mem_free(pi1);
  1065b7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1065ba:	89 04 24             	mov    %eax,(%esp)
  1065bd:	e8 92 a5 ff ff       	call   100b54 <mem_free>
	mem_free(pi2);
  1065c2:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1065c5:	89 04 24             	mov    %eax,(%esp)
  1065c8:	e8 87 a5 ff ff       	call   100b54 <mem_free>
	mem_free(pi3);
  1065cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1065d0:	89 04 24             	mov    %eax,(%esp)
  1065d3:	e8 7c a5 ff ff       	call   100b54 <mem_free>

	cprintf("pmap_check() succeeded!\n");
  1065d8:	c7 04 24 5c 9e 10 00 	movl   $0x109e5c,(%esp)
  1065df:	e8 7b 15 00 00       	call   107b5f <cprintf>
}
  1065e4:	83 c4 44             	add    $0x44,%esp
  1065e7:	5b                   	pop    %ebx
  1065e8:	5d                   	pop    %ebp
  1065e9:	c3                   	ret    

001065ea <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  1065ea:	55                   	push   %ebp
  1065eb:	89 e5                	mov    %esp,%ebp
  1065ed:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  1065f0:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  1065f7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1065fa:	0f b7 00             	movzwl (%eax),%eax
  1065fd:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  106601:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106604:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  106609:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10660c:	0f b7 00             	movzwl (%eax),%eax
  10660f:	66 3d 5a a5          	cmp    $0xa55a,%ax
  106613:	74 13                	je     106628 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  106615:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  10661c:	c7 05 98 ec 11 00 b4 	movl   $0x3b4,0x11ec98
  106623:	03 00 00 
  106626:	eb 14                	jmp    10663c <video_init+0x52>
	} else {
		*cp = was;
  106628:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10662b:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  10662f:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  106632:	c7 05 98 ec 11 00 d4 	movl   $0x3d4,0x11ec98
  106639:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  10663c:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106641:	89 45 e8             	mov    %eax,-0x18(%ebp)
  106644:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106648:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  10664c:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10664f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  106650:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106655:	83 c0 01             	add    $0x1,%eax
  106658:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10665b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10665e:	89 c2                	mov    %eax,%edx
  106660:	ec                   	in     (%dx),%al
  106661:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  106664:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  106668:	0f b6 c0             	movzbl %al,%eax
  10666b:	c1 e0 08             	shl    $0x8,%eax
  10666e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  106671:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106676:	89 45 f4             	mov    %eax,-0xc(%ebp)
  106679:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10667d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106681:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106684:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  106685:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  10668a:	83 c0 01             	add    $0x1,%eax
  10668d:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106690:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106693:	89 c2                	mov    %eax,%edx
  106695:	ec                   	in     (%dx),%al
  106696:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  106699:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  10669d:	0f b6 c0             	movzbl %al,%eax
  1066a0:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  1066a3:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1066a6:	a3 9c ec 11 00       	mov    %eax,0x11ec9c
	crt_pos = pos;
  1066ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1066ae:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
}
  1066b4:	c9                   	leave  
  1066b5:	c3                   	ret    

001066b6 <video_putc>:



void
video_putc(int c)
{
  1066b6:	55                   	push   %ebp
  1066b7:	89 e5                	mov    %esp,%ebp
  1066b9:	53                   	push   %ebx
  1066ba:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  1066bd:	8b 45 08             	mov    0x8(%ebp),%eax
  1066c0:	b0 00                	mov    $0x0,%al
  1066c2:	85 c0                	test   %eax,%eax
  1066c4:	75 07                	jne    1066cd <video_putc+0x17>
		c |= 0x0700;
  1066c6:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  1066cd:	8b 45 08             	mov    0x8(%ebp),%eax
  1066d0:	25 ff 00 00 00       	and    $0xff,%eax
  1066d5:	83 f8 09             	cmp    $0x9,%eax
  1066d8:	0f 84 ae 00 00 00    	je     10678c <video_putc+0xd6>
  1066de:	83 f8 09             	cmp    $0x9,%eax
  1066e1:	7f 0a                	jg     1066ed <video_putc+0x37>
  1066e3:	83 f8 08             	cmp    $0x8,%eax
  1066e6:	74 14                	je     1066fc <video_putc+0x46>
  1066e8:	e9 dd 00 00 00       	jmp    1067ca <video_putc+0x114>
  1066ed:	83 f8 0a             	cmp    $0xa,%eax
  1066f0:	74 4e                	je     106740 <video_putc+0x8a>
  1066f2:	83 f8 0d             	cmp    $0xd,%eax
  1066f5:	74 59                	je     106750 <video_putc+0x9a>
  1066f7:	e9 ce 00 00 00       	jmp    1067ca <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  1066fc:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106703:	66 85 c0             	test   %ax,%ax
  106706:	0f 84 e4 00 00 00    	je     1067f0 <video_putc+0x13a>
			crt_pos--;
  10670c:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106713:	83 e8 01             	sub    $0x1,%eax
  106716:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  10671c:	a1 9c ec 11 00       	mov    0x11ec9c,%eax
  106721:	0f b7 15 a0 ec 11 00 	movzwl 0x11eca0,%edx
  106728:	0f b7 d2             	movzwl %dx,%edx
  10672b:	01 d2                	add    %edx,%edx
  10672d:	8d 14 10             	lea    (%eax,%edx,1),%edx
  106730:	8b 45 08             	mov    0x8(%ebp),%eax
  106733:	b0 00                	mov    $0x0,%al
  106735:	83 c8 20             	or     $0x20,%eax
  106738:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  10673b:	e9 b1 00 00 00       	jmp    1067f1 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  106740:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106747:	83 c0 50             	add    $0x50,%eax
  10674a:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  106750:	0f b7 1d a0 ec 11 00 	movzwl 0x11eca0,%ebx
  106757:	0f b7 0d a0 ec 11 00 	movzwl 0x11eca0,%ecx
  10675e:	0f b7 c1             	movzwl %cx,%eax
  106761:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  106767:	c1 e8 10             	shr    $0x10,%eax
  10676a:	89 c2                	mov    %eax,%edx
  10676c:	66 c1 ea 06          	shr    $0x6,%dx
  106770:	89 d0                	mov    %edx,%eax
  106772:	c1 e0 02             	shl    $0x2,%eax
  106775:	01 d0                	add    %edx,%eax
  106777:	c1 e0 04             	shl    $0x4,%eax
  10677a:	89 ca                	mov    %ecx,%edx
  10677c:	66 29 c2             	sub    %ax,%dx
  10677f:	89 d8                	mov    %ebx,%eax
  106781:	66 29 d0             	sub    %dx,%ax
  106784:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
		break;
  10678a:	eb 65                	jmp    1067f1 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  10678c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  106793:	e8 1e ff ff ff       	call   1066b6 <video_putc>
		video_putc(' ');
  106798:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10679f:	e8 12 ff ff ff       	call   1066b6 <video_putc>
		video_putc(' ');
  1067a4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1067ab:	e8 06 ff ff ff       	call   1066b6 <video_putc>
		video_putc(' ');
  1067b0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1067b7:	e8 fa fe ff ff       	call   1066b6 <video_putc>
		video_putc(' ');
  1067bc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1067c3:	e8 ee fe ff ff       	call   1066b6 <video_putc>
		break;
  1067c8:	eb 27                	jmp    1067f1 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  1067ca:	8b 15 9c ec 11 00    	mov    0x11ec9c,%edx
  1067d0:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  1067d7:	0f b7 c8             	movzwl %ax,%ecx
  1067da:	01 c9                	add    %ecx,%ecx
  1067dc:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  1067df:	8b 55 08             	mov    0x8(%ebp),%edx
  1067e2:	66 89 11             	mov    %dx,(%ecx)
  1067e5:	83 c0 01             	add    $0x1,%eax
  1067e8:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
  1067ee:	eb 01                	jmp    1067f1 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  1067f0:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  1067f1:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  1067f8:	66 3d cf 07          	cmp    $0x7cf,%ax
  1067fc:	76 5b                	jbe    106859 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  1067fe:	a1 9c ec 11 00       	mov    0x11ec9c,%eax
  106803:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  106809:	a1 9c ec 11 00       	mov    0x11ec9c,%eax
  10680e:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  106815:	00 
  106816:	89 54 24 04          	mov    %edx,0x4(%esp)
  10681a:	89 04 24             	mov    %eax,(%esp)
  10681d:	e8 96 15 00 00       	call   107db8 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  106822:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  106829:	eb 15                	jmp    106840 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  10682b:	a1 9c ec 11 00       	mov    0x11ec9c,%eax
  106830:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106833:	01 d2                	add    %edx,%edx
  106835:	01 d0                	add    %edx,%eax
  106837:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  10683c:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  106840:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  106847:	7e e2                	jle    10682b <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  106849:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106850:	83 e8 50             	sub    $0x50,%eax
  106853:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  106859:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  10685e:	89 45 dc             	mov    %eax,-0x24(%ebp)
  106861:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106865:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  106869:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10686c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  10686d:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106874:	66 c1 e8 08          	shr    $0x8,%ax
  106878:	0f b6 c0             	movzbl %al,%eax
  10687b:	8b 15 98 ec 11 00    	mov    0x11ec98,%edx
  106881:	83 c2 01             	add    $0x1,%edx
  106884:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  106887:	88 45 e3             	mov    %al,-0x1d(%ebp)
  10688a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10688e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  106891:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  106892:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106897:	89 45 ec             	mov    %eax,-0x14(%ebp)
  10689a:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  10689e:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1068a2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1068a5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  1068a6:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  1068ad:	0f b6 c0             	movzbl %al,%eax
  1068b0:	8b 15 98 ec 11 00    	mov    0x11ec98,%edx
  1068b6:	83 c2 01             	add    $0x1,%edx
  1068b9:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1068bc:	88 45 f3             	mov    %al,-0xd(%ebp)
  1068bf:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1068c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1068c6:	ee                   	out    %al,(%dx)
}
  1068c7:	83 c4 44             	add    $0x44,%esp
  1068ca:	5b                   	pop    %ebx
  1068cb:	5d                   	pop    %ebp
  1068cc:	c3                   	ret    

001068cd <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  1068cd:	55                   	push   %ebp
  1068ce:	89 e5                	mov    %esp,%ebp
  1068d0:	83 ec 38             	sub    $0x38,%esp
  1068d3:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1068da:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1068dd:	89 c2                	mov    %eax,%edx
  1068df:	ec                   	in     (%dx),%al
  1068e0:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  1068e3:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  1068e7:	0f b6 c0             	movzbl %al,%eax
  1068ea:	83 e0 01             	and    $0x1,%eax
  1068ed:	85 c0                	test   %eax,%eax
  1068ef:	75 0a                	jne    1068fb <kbd_proc_data+0x2e>
		return -1;
  1068f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1068f6:	e9 5a 01 00 00       	jmp    106a55 <kbd_proc_data+0x188>
  1068fb:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106902:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106905:	89 c2                	mov    %eax,%edx
  106907:	ec                   	in     (%dx),%al
  106908:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10690b:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  10690f:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  106912:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  106916:	75 17                	jne    10692f <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  106918:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  10691d:	83 c8 40             	or     $0x40,%eax
  106920:	a3 a4 ec 11 00       	mov    %eax,0x11eca4
		return 0;
  106925:	b8 00 00 00 00       	mov    $0x0,%eax
  10692a:	e9 26 01 00 00       	jmp    106a55 <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  10692f:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106933:	84 c0                	test   %al,%al
  106935:	79 47                	jns    10697e <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  106937:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  10693c:	83 e0 40             	and    $0x40,%eax
  10693f:	85 c0                	test   %eax,%eax
  106941:	75 09                	jne    10694c <kbd_proc_data+0x7f>
  106943:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106947:	83 e0 7f             	and    $0x7f,%eax
  10694a:	eb 04                	jmp    106950 <kbd_proc_data+0x83>
  10694c:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106950:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  106953:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106957:	0f b6 80 20 c1 10 00 	movzbl 0x10c120(%eax),%eax
  10695e:	83 c8 40             	or     $0x40,%eax
  106961:	0f b6 c0             	movzbl %al,%eax
  106964:	f7 d0                	not    %eax
  106966:	89 c2                	mov    %eax,%edx
  106968:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  10696d:	21 d0                	and    %edx,%eax
  10696f:	a3 a4 ec 11 00       	mov    %eax,0x11eca4
		return 0;
  106974:	b8 00 00 00 00       	mov    $0x0,%eax
  106979:	e9 d7 00 00 00       	jmp    106a55 <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  10697e:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106983:	83 e0 40             	and    $0x40,%eax
  106986:	85 c0                	test   %eax,%eax
  106988:	74 11                	je     10699b <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  10698a:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  10698e:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106993:	83 e0 bf             	and    $0xffffffbf,%eax
  106996:	a3 a4 ec 11 00       	mov    %eax,0x11eca4
	}

	shift |= shiftcode[data];
  10699b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10699f:	0f b6 80 20 c1 10 00 	movzbl 0x10c120(%eax),%eax
  1069a6:	0f b6 d0             	movzbl %al,%edx
  1069a9:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  1069ae:	09 d0                	or     %edx,%eax
  1069b0:	a3 a4 ec 11 00       	mov    %eax,0x11eca4
	shift ^= togglecode[data];
  1069b5:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1069b9:	0f b6 80 20 c2 10 00 	movzbl 0x10c220(%eax),%eax
  1069c0:	0f b6 d0             	movzbl %al,%edx
  1069c3:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  1069c8:	31 d0                	xor    %edx,%eax
  1069ca:	a3 a4 ec 11 00       	mov    %eax,0x11eca4

	c = charcode[shift & (CTL | SHIFT)][data];
  1069cf:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  1069d4:	83 e0 03             	and    $0x3,%eax
  1069d7:	8b 14 85 20 c6 10 00 	mov    0x10c620(,%eax,4),%edx
  1069de:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1069e2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1069e5:	0f b6 00             	movzbl (%eax),%eax
  1069e8:	0f b6 c0             	movzbl %al,%eax
  1069eb:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  1069ee:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  1069f3:	83 e0 08             	and    $0x8,%eax
  1069f6:	85 c0                	test   %eax,%eax
  1069f8:	74 22                	je     106a1c <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  1069fa:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  1069fe:	7e 0c                	jle    106a0c <kbd_proc_data+0x13f>
  106a00:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  106a04:	7f 06                	jg     106a0c <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  106a06:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  106a0a:	eb 10                	jmp    106a1c <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  106a0c:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  106a10:	7e 0a                	jle    106a1c <kbd_proc_data+0x14f>
  106a12:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  106a16:	7f 04                	jg     106a1c <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  106a18:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  106a1c:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106a21:	f7 d0                	not    %eax
  106a23:	83 e0 06             	and    $0x6,%eax
  106a26:	85 c0                	test   %eax,%eax
  106a28:	75 28                	jne    106a52 <kbd_proc_data+0x185>
  106a2a:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  106a31:	75 1f                	jne    106a52 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  106a33:	c7 04 24 75 9e 10 00 	movl   $0x109e75,(%esp)
  106a3a:	e8 20 11 00 00       	call   107b5f <cprintf>
  106a3f:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  106a46:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106a4a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106a4e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106a51:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  106a52:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  106a55:	c9                   	leave  
  106a56:	c3                   	ret    

00106a57 <kbd_intr>:

void
kbd_intr(void)
{
  106a57:	55                   	push   %ebp
  106a58:	89 e5                	mov    %esp,%ebp
  106a5a:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  106a5d:	c7 04 24 cd 68 10 00 	movl   $0x1068cd,(%esp)
  106a64:	e8 4d 98 ff ff       	call   1002b6 <cons_intr>
}
  106a69:	c9                   	leave  
  106a6a:	c3                   	ret    

00106a6b <kbd_init>:

void
kbd_init(void)
{
  106a6b:	55                   	push   %ebp
  106a6c:	89 e5                	mov    %esp,%ebp
}
  106a6e:	5d                   	pop    %ebp
  106a6f:	c3                   	ret    

00106a70 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  106a70:	55                   	push   %ebp
  106a71:	89 e5                	mov    %esp,%ebp
  106a73:	83 ec 20             	sub    $0x20,%esp
  106a76:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106a7d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106a80:	89 c2                	mov    %eax,%edx
  106a82:	ec                   	in     (%dx),%al
  106a83:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  106a86:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106a8d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106a90:	89 c2                	mov    %eax,%edx
  106a92:	ec                   	in     (%dx),%al
  106a93:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  106a96:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106a9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106aa0:	89 c2                	mov    %eax,%edx
  106aa2:	ec                   	in     (%dx),%al
  106aa3:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  106aa6:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106aad:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106ab0:	89 c2                	mov    %eax,%edx
  106ab2:	ec                   	in     (%dx),%al
  106ab3:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  106ab6:	c9                   	leave  
  106ab7:	c3                   	ret    

00106ab8 <serial_proc_data>:

static int
serial_proc_data(void)
{
  106ab8:	55                   	push   %ebp
  106ab9:	89 e5                	mov    %esp,%ebp
  106abb:	83 ec 10             	sub    $0x10,%esp
  106abe:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  106ac5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106ac8:	89 c2                	mov    %eax,%edx
  106aca:	ec                   	in     (%dx),%al
  106acb:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  106ace:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  106ad2:	0f b6 c0             	movzbl %al,%eax
  106ad5:	83 e0 01             	and    $0x1,%eax
  106ad8:	85 c0                	test   %eax,%eax
  106ada:	75 07                	jne    106ae3 <serial_proc_data+0x2b>
		return -1;
  106adc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  106ae1:	eb 17                	jmp    106afa <serial_proc_data+0x42>
  106ae3:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106aea:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106aed:	89 c2                	mov    %eax,%edx
  106aef:	ec                   	in     (%dx),%al
  106af0:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  106af3:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  106af7:	0f b6 c0             	movzbl %al,%eax
}
  106afa:	c9                   	leave  
  106afb:	c3                   	ret    

00106afc <serial_intr>:

void
serial_intr(void)
{
  106afc:	55                   	push   %ebp
  106afd:	89 e5                	mov    %esp,%ebp
  106aff:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  106b02:	a1 00 20 32 00       	mov    0x322000,%eax
  106b07:	85 c0                	test   %eax,%eax
  106b09:	74 0c                	je     106b17 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  106b0b:	c7 04 24 b8 6a 10 00 	movl   $0x106ab8,(%esp)
  106b12:	e8 9f 97 ff ff       	call   1002b6 <cons_intr>
}
  106b17:	c9                   	leave  
  106b18:	c3                   	ret    

00106b19 <serial_putc>:

void
serial_putc(int c)
{
  106b19:	55                   	push   %ebp
  106b1a:	89 e5                	mov    %esp,%ebp
  106b1c:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  106b1f:	a1 00 20 32 00       	mov    0x322000,%eax
  106b24:	85 c0                	test   %eax,%eax
  106b26:	74 53                	je     106b7b <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  106b28:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  106b2f:	eb 09                	jmp    106b3a <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  106b31:	e8 3a ff ff ff       	call   106a70 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  106b36:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  106b3a:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106b41:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106b44:	89 c2                	mov    %eax,%edx
  106b46:	ec                   	in     (%dx),%al
  106b47:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  106b4a:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  106b4e:	0f b6 c0             	movzbl %al,%eax
  106b51:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  106b54:	85 c0                	test   %eax,%eax
  106b56:	75 09                	jne    106b61 <serial_putc+0x48>
  106b58:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  106b5f:	7e d0                	jle    106b31 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  106b61:	8b 45 08             	mov    0x8(%ebp),%eax
  106b64:	0f b6 c0             	movzbl %al,%eax
  106b67:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  106b6e:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106b71:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106b75:	8b 55 fc             	mov    -0x4(%ebp),%edx
  106b78:	ee                   	out    %al,(%dx)
  106b79:	eb 01                	jmp    106b7c <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  106b7b:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  106b7c:	c9                   	leave  
  106b7d:	c3                   	ret    

00106b7e <serial_init>:

void
serial_init(void)
{
  106b7e:	55                   	push   %ebp
  106b7f:	89 e5                	mov    %esp,%ebp
  106b81:	83 ec 50             	sub    $0x50,%esp
  106b84:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  106b8b:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  106b8f:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  106b93:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  106b96:	ee                   	out    %al,(%dx)
  106b97:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  106b9e:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  106ba2:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  106ba6:	8b 55 bc             	mov    -0x44(%ebp),%edx
  106ba9:	ee                   	out    %al,(%dx)
  106baa:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  106bb1:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  106bb5:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  106bb9:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  106bbc:	ee                   	out    %al,(%dx)
  106bbd:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  106bc4:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  106bc8:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  106bcc:	8b 55 cc             	mov    -0x34(%ebp),%edx
  106bcf:	ee                   	out    %al,(%dx)
  106bd0:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  106bd7:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  106bdb:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  106bdf:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106be2:	ee                   	out    %al,(%dx)
  106be3:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  106bea:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  106bee:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  106bf2:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106bf5:	ee                   	out    %al,(%dx)
  106bf6:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  106bfd:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  106c01:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106c05:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  106c08:	ee                   	out    %al,(%dx)
  106c09:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106c10:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106c13:	89 c2                	mov    %eax,%edx
  106c15:	ec                   	in     (%dx),%al
  106c16:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  106c19:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  106c1d:	3c ff                	cmp    $0xff,%al
  106c1f:	0f 95 c0             	setne  %al
  106c22:	0f b6 c0             	movzbl %al,%eax
  106c25:	a3 00 20 32 00       	mov    %eax,0x322000
  106c2a:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106c31:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106c34:	89 c2                	mov    %eax,%edx
  106c36:	ec                   	in     (%dx),%al
  106c37:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  106c3a:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106c41:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106c44:	89 c2                	mov    %eax,%edx
  106c46:	ec                   	in     (%dx),%al
  106c47:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  106c4a:	c9                   	leave  
  106c4b:	c3                   	ret    

00106c4c <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  106c4c:	55                   	push   %ebp
  106c4d:	89 e5                	mov    %esp,%ebp
  106c4f:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  106c55:	a1 a8 ec 11 00       	mov    0x11eca8,%eax
  106c5a:	85 c0                	test   %eax,%eax
  106c5c:	0f 85 35 01 00 00    	jne    106d97 <pic_init+0x14b>
		return;
	didinit = 1;
  106c62:	c7 05 a8 ec 11 00 01 	movl   $0x1,0x11eca8
  106c69:	00 00 00 
  106c6c:	c7 45 8c 21 00 00 00 	movl   $0x21,-0x74(%ebp)
  106c73:	c6 45 8b ff          	movb   $0xff,-0x75(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106c77:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  106c7b:	8b 55 8c             	mov    -0x74(%ebp),%edx
  106c7e:	ee                   	out    %al,(%dx)
  106c7f:	c7 45 94 a1 00 00 00 	movl   $0xa1,-0x6c(%ebp)
  106c86:	c6 45 93 ff          	movb   $0xff,-0x6d(%ebp)
  106c8a:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  106c8e:	8b 55 94             	mov    -0x6c(%ebp),%edx
  106c91:	ee                   	out    %al,(%dx)
  106c92:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  106c99:	c6 45 9b 11          	movb   $0x11,-0x65(%ebp)
  106c9d:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  106ca1:	8b 55 9c             	mov    -0x64(%ebp),%edx
  106ca4:	ee                   	out    %al,(%dx)
  106ca5:	c7 45 a4 21 00 00 00 	movl   $0x21,-0x5c(%ebp)
  106cac:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
  106cb0:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  106cb4:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  106cb7:	ee                   	out    %al,(%dx)
  106cb8:	c7 45 ac 21 00 00 00 	movl   $0x21,-0x54(%ebp)
  106cbf:	c6 45 ab 04          	movb   $0x4,-0x55(%ebp)
  106cc3:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  106cc7:	8b 55 ac             	mov    -0x54(%ebp),%edx
  106cca:	ee                   	out    %al,(%dx)
  106ccb:	c7 45 b4 21 00 00 00 	movl   $0x21,-0x4c(%ebp)
  106cd2:	c6 45 b3 03          	movb   $0x3,-0x4d(%ebp)
  106cd6:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  106cda:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  106cdd:	ee                   	out    %al,(%dx)
  106cde:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
  106ce5:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
  106ce9:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  106ced:	8b 55 bc             	mov    -0x44(%ebp),%edx
  106cf0:	ee                   	out    %al,(%dx)
  106cf1:	c7 45 c4 a1 00 00 00 	movl   $0xa1,-0x3c(%ebp)
  106cf8:	c6 45 c3 28          	movb   $0x28,-0x3d(%ebp)
  106cfc:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  106d00:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  106d03:	ee                   	out    %al,(%dx)
  106d04:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
  106d0b:	c6 45 cb 02          	movb   $0x2,-0x35(%ebp)
  106d0f:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  106d13:	8b 55 cc             	mov    -0x34(%ebp),%edx
  106d16:	ee                   	out    %al,(%dx)
  106d17:	c7 45 d4 a1 00 00 00 	movl   $0xa1,-0x2c(%ebp)
  106d1e:	c6 45 d3 01          	movb   $0x1,-0x2d(%ebp)
  106d22:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  106d26:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106d29:	ee                   	out    %al,(%dx)
  106d2a:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
  106d31:	c6 45 db 68          	movb   $0x68,-0x25(%ebp)
  106d35:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  106d39:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106d3c:	ee                   	out    %al,(%dx)
  106d3d:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  106d44:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  106d48:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106d4c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  106d4f:	ee                   	out    %al,(%dx)
  106d50:	c7 45 ec a0 00 00 00 	movl   $0xa0,-0x14(%ebp)
  106d57:	c6 45 eb 68          	movb   $0x68,-0x15(%ebp)
  106d5b:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  106d5f:	8b 55 ec             	mov    -0x14(%ebp),%edx
  106d62:	ee                   	out    %al,(%dx)
  106d63:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
  106d6a:	c6 45 f3 0a          	movb   $0xa,-0xd(%ebp)
  106d6e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106d72:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106d75:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  106d76:	0f b7 05 30 c6 10 00 	movzwl 0x10c630,%eax
  106d7d:	66 83 f8 ff          	cmp    $0xffff,%ax
  106d81:	74 15                	je     106d98 <pic_init+0x14c>
		pic_setmask(irqmask);
  106d83:	0f b7 05 30 c6 10 00 	movzwl 0x10c630,%eax
  106d8a:	0f b7 c0             	movzwl %ax,%eax
  106d8d:	89 04 24             	mov    %eax,(%esp)
  106d90:	e8 05 00 00 00       	call   106d9a <pic_setmask>
  106d95:	eb 01                	jmp    106d98 <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  106d97:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  106d98:	c9                   	leave  
  106d99:	c3                   	ret    

00106d9a <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  106d9a:	55                   	push   %ebp
  106d9b:	89 e5                	mov    %esp,%ebp
  106d9d:	83 ec 14             	sub    $0x14,%esp
  106da0:	8b 45 08             	mov    0x8(%ebp),%eax
  106da3:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  106da7:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  106dab:	66 a3 30 c6 10 00    	mov    %ax,0x10c630
	outb(IO_PIC1+1, (char)mask);
  106db1:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  106db5:	0f b6 c0             	movzbl %al,%eax
  106db8:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  106dbf:	88 45 f3             	mov    %al,-0xd(%ebp)
  106dc2:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106dc6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106dc9:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  106dca:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  106dce:	66 c1 e8 08          	shr    $0x8,%ax
  106dd2:	0f b6 c0             	movzbl %al,%eax
  106dd5:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
  106ddc:	88 45 fb             	mov    %al,-0x5(%ebp)
  106ddf:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106de3:	8b 55 fc             	mov    -0x4(%ebp),%edx
  106de6:	ee                   	out    %al,(%dx)
}
  106de7:	c9                   	leave  
  106de8:	c3                   	ret    

00106de9 <pic_enable>:

void
pic_enable(int irq)
{
  106de9:	55                   	push   %ebp
  106dea:	89 e5                	mov    %esp,%ebp
  106dec:	53                   	push   %ebx
  106ded:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  106df0:	8b 45 08             	mov    0x8(%ebp),%eax
  106df3:	ba 01 00 00 00       	mov    $0x1,%edx
  106df8:	89 d3                	mov    %edx,%ebx
  106dfa:	89 c1                	mov    %eax,%ecx
  106dfc:	d3 e3                	shl    %cl,%ebx
  106dfe:	89 d8                	mov    %ebx,%eax
  106e00:	89 c2                	mov    %eax,%edx
  106e02:	f7 d2                	not    %edx
  106e04:	0f b7 05 30 c6 10 00 	movzwl 0x10c630,%eax
  106e0b:	21 d0                	and    %edx,%eax
  106e0d:	0f b7 c0             	movzwl %ax,%eax
  106e10:	89 04 24             	mov    %eax,(%esp)
  106e13:	e8 82 ff ff ff       	call   106d9a <pic_setmask>
}
  106e18:	83 c4 04             	add    $0x4,%esp
  106e1b:	5b                   	pop    %ebx
  106e1c:	5d                   	pop    %ebp
  106e1d:	c3                   	ret    

00106e1e <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  106e1e:	55                   	push   %ebp
  106e1f:	89 e5                	mov    %esp,%ebp
  106e21:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  106e24:	8b 45 08             	mov    0x8(%ebp),%eax
  106e27:	0f b6 c0             	movzbl %al,%eax
  106e2a:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  106e31:	88 45 f3             	mov    %al,-0xd(%ebp)
  106e34:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106e38:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106e3b:	ee                   	out    %al,(%dx)
  106e3c:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106e43:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106e46:	89 c2                	mov    %eax,%edx
  106e48:	ec                   	in     (%dx),%al
  106e49:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  106e4c:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  106e50:	0f b6 c0             	movzbl %al,%eax
}
  106e53:	c9                   	leave  
  106e54:	c3                   	ret    

00106e55 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  106e55:	55                   	push   %ebp
  106e56:	89 e5                	mov    %esp,%ebp
  106e58:	53                   	push   %ebx
  106e59:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  106e5c:	8b 45 08             	mov    0x8(%ebp),%eax
  106e5f:	89 04 24             	mov    %eax,(%esp)
  106e62:	e8 b7 ff ff ff       	call   106e1e <nvram_read>
  106e67:	89 c3                	mov    %eax,%ebx
  106e69:	8b 45 08             	mov    0x8(%ebp),%eax
  106e6c:	83 c0 01             	add    $0x1,%eax
  106e6f:	89 04 24             	mov    %eax,(%esp)
  106e72:	e8 a7 ff ff ff       	call   106e1e <nvram_read>
  106e77:	c1 e0 08             	shl    $0x8,%eax
  106e7a:	09 d8                	or     %ebx,%eax
}
  106e7c:	83 c4 04             	add    $0x4,%esp
  106e7f:	5b                   	pop    %ebx
  106e80:	5d                   	pop    %ebp
  106e81:	c3                   	ret    

00106e82 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  106e82:	55                   	push   %ebp
  106e83:	89 e5                	mov    %esp,%ebp
  106e85:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  106e88:	8b 45 08             	mov    0x8(%ebp),%eax
  106e8b:	0f b6 c0             	movzbl %al,%eax
  106e8e:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  106e95:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106e98:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106e9c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106e9f:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  106ea0:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ea3:	0f b6 c0             	movzbl %al,%eax
  106ea6:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  106ead:	88 45 fb             	mov    %al,-0x5(%ebp)
  106eb0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106eb4:	8b 55 fc             	mov    -0x4(%ebp),%edx
  106eb7:	ee                   	out    %al,(%dx)
}
  106eb8:	c9                   	leave  
  106eb9:	c3                   	ret    

00106eba <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  106eba:	55                   	push   %ebp
  106ebb:	89 e5                	mov    %esp,%ebp
  106ebd:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  106ec0:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  106ec3:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  106ec6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106ec9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106ecc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106ed1:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  106ed4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106ed7:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  106edd:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  106ee2:	74 24                	je     106f08 <cpu_cur+0x4e>
  106ee4:	c7 44 24 0c 81 9e 10 	movl   $0x109e81,0xc(%esp)
  106eeb:	00 
  106eec:	c7 44 24 08 97 9e 10 	movl   $0x109e97,0x8(%esp)
  106ef3:	00 
  106ef4:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  106efb:	00 
  106efc:	c7 04 24 ac 9e 10 00 	movl   $0x109eac,(%esp)
  106f03:	e8 79 95 ff ff       	call   100481 <debug_panic>
	return c;
  106f08:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  106f0b:	c9                   	leave  
  106f0c:	c3                   	ret    

00106f0d <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  106f0d:	55                   	push   %ebp
  106f0e:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  106f10:	a1 04 20 32 00       	mov    0x322004,%eax
  106f15:	8b 55 08             	mov    0x8(%ebp),%edx
  106f18:	c1 e2 02             	shl    $0x2,%edx
  106f1b:	8d 14 10             	lea    (%eax,%edx,1),%edx
  106f1e:	8b 45 0c             	mov    0xc(%ebp),%eax
  106f21:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  106f23:	a1 04 20 32 00       	mov    0x322004,%eax
  106f28:	83 c0 20             	add    $0x20,%eax
  106f2b:	8b 00                	mov    (%eax),%eax
}
  106f2d:	5d                   	pop    %ebp
  106f2e:	c3                   	ret    

00106f2f <lapic_init>:

void
lapic_init()
{
  106f2f:	55                   	push   %ebp
  106f30:	89 e5                	mov    %esp,%ebp
  106f32:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  106f35:	a1 04 20 32 00       	mov    0x322004,%eax
  106f3a:	85 c0                	test   %eax,%eax
  106f3c:	0f 84 82 01 00 00    	je     1070c4 <lapic_init+0x195>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  106f42:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  106f49:	00 
  106f4a:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  106f51:	e8 b7 ff ff ff       	call   106f0d <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  106f56:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  106f5d:	00 
  106f5e:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  106f65:	e8 a3 ff ff ff       	call   106f0d <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  106f6a:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  106f71:	00 
  106f72:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  106f79:	e8 8f ff ff ff       	call   106f0d <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  106f7e:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  106f85:	00 
  106f86:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  106f8d:	e8 7b ff ff ff       	call   106f0d <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  106f92:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  106f99:	00 
  106f9a:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  106fa1:	e8 67 ff ff ff       	call   106f0d <lapicw>
	lapicw(LINT1, MASKED);
  106fa6:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  106fad:	00 
  106fae:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  106fb5:	e8 53 ff ff ff       	call   106f0d <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  106fba:	a1 04 20 32 00       	mov    0x322004,%eax
  106fbf:	83 c0 30             	add    $0x30,%eax
  106fc2:	8b 00                	mov    (%eax),%eax
  106fc4:	c1 e8 10             	shr    $0x10,%eax
  106fc7:	25 ff 00 00 00       	and    $0xff,%eax
  106fcc:	83 f8 03             	cmp    $0x3,%eax
  106fcf:	76 14                	jbe    106fe5 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  106fd1:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  106fd8:	00 
  106fd9:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  106fe0:	e8 28 ff ff ff       	call   106f0d <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  106fe5:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  106fec:	00 
  106fed:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  106ff4:	e8 14 ff ff ff       	call   106f0d <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  106ff9:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  107000:	ff 
  107001:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  107008:	e8 00 ff ff ff       	call   106f0d <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  10700d:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  107014:	f0 
  107015:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  10701c:	e8 ec fe ff ff       	call   106f0d <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  107021:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107028:	00 
  107029:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  107030:	e8 d8 fe ff ff       	call   106f0d <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  107035:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10703c:	00 
  10703d:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  107044:	e8 c4 fe ff ff       	call   106f0d <lapicw>
	lapicw(ESR, 0);
  107049:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107050:	00 
  107051:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  107058:	e8 b0 fe ff ff       	call   106f0d <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  10705d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107064:	00 
  107065:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10706c:	e8 9c fe ff ff       	call   106f0d <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  107071:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107078:	00 
  107079:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  107080:	e8 88 fe ff ff       	call   106f0d <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  107085:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  10708c:	00 
  10708d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  107094:	e8 74 fe ff ff       	call   106f0d <lapicw>
	while(lapic[ICRLO] & DELIVS)
  107099:	a1 04 20 32 00       	mov    0x322004,%eax
  10709e:	05 00 03 00 00       	add    $0x300,%eax
  1070a3:	8b 00                	mov    (%eax),%eax
  1070a5:	25 00 10 00 00       	and    $0x1000,%eax
  1070aa:	85 c0                	test   %eax,%eax
  1070ac:	75 eb                	jne    107099 <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  1070ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1070b5:	00 
  1070b6:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1070bd:	e8 4b fe ff ff       	call   106f0d <lapicw>
  1070c2:	eb 01                	jmp    1070c5 <lapic_init+0x196>

void
lapic_init()
{
	if (!lapic) 
		return;
  1070c4:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  1070c5:	c9                   	leave  
  1070c6:	c3                   	ret    

001070c7 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  1070c7:	55                   	push   %ebp
  1070c8:	89 e5                	mov    %esp,%ebp
  1070ca:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  1070cd:	a1 04 20 32 00       	mov    0x322004,%eax
  1070d2:	85 c0                	test   %eax,%eax
  1070d4:	74 14                	je     1070ea <lapic_eoi+0x23>
		lapicw(EOI, 0);
  1070d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1070dd:	00 
  1070de:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  1070e5:	e8 23 fe ff ff       	call   106f0d <lapicw>
}
  1070ea:	c9                   	leave  
  1070eb:	c3                   	ret    

001070ec <lapic_errintr>:

void lapic_errintr(void)
{
  1070ec:	55                   	push   %ebp
  1070ed:	89 e5                	mov    %esp,%ebp
  1070ef:	53                   	push   %ebx
  1070f0:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  1070f3:	e8 cf ff ff ff       	call   1070c7 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  1070f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1070ff:	00 
  107100:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  107107:	e8 01 fe ff ff       	call   106f0d <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  10710c:	a1 04 20 32 00       	mov    0x322004,%eax
  107111:	05 80 02 00 00       	add    $0x280,%eax
  107116:	8b 18                	mov    (%eax),%ebx
  107118:	e8 9d fd ff ff       	call   106eba <cpu_cur>
  10711d:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  107124:	0f b6 c0             	movzbl %al,%eax
  107127:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  10712b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10712f:	c7 44 24 08 b9 9e 10 	movl   $0x109eb9,0x8(%esp)
  107136:	00 
  107137:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  10713e:	00 
  10713f:	c7 04 24 d3 9e 10 00 	movl   $0x109ed3,(%esp)
  107146:	e8 f5 93 ff ff       	call   100540 <debug_warn>
}
  10714b:	83 c4 24             	add    $0x24,%esp
  10714e:	5b                   	pop    %ebx
  10714f:	5d                   	pop    %ebp
  107150:	c3                   	ret    

00107151 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  107151:	55                   	push   %ebp
  107152:	89 e5                	mov    %esp,%ebp
}
  107154:	5d                   	pop    %ebp
  107155:	c3                   	ret    

00107156 <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  107156:	55                   	push   %ebp
  107157:	89 e5                	mov    %esp,%ebp
  107159:	83 ec 2c             	sub    $0x2c,%esp
  10715c:	8b 45 08             	mov    0x8(%ebp),%eax
  10715f:	88 45 dc             	mov    %al,-0x24(%ebp)
  107162:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  107169:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10716d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  107171:	8b 55 f4             	mov    -0xc(%ebp),%edx
  107174:	ee                   	out    %al,(%dx)
  107175:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  10717c:	c6 45 fb 0a          	movb   $0xa,-0x5(%ebp)
  107180:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  107184:	8b 55 fc             	mov    -0x4(%ebp),%edx
  107187:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  107188:	c7 45 ec 67 04 00 00 	movl   $0x467,-0x14(%ebp)
	wrv[0] = 0;
  10718f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107192:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  107197:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10719a:	8d 50 02             	lea    0x2(%eax),%edx
  10719d:	8b 45 0c             	mov    0xc(%ebp),%eax
  1071a0:	c1 e8 04             	shr    $0x4,%eax
  1071a3:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  1071a6:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  1071aa:	c1 e0 18             	shl    $0x18,%eax
  1071ad:	89 44 24 04          	mov    %eax,0x4(%esp)
  1071b1:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1071b8:	e8 50 fd ff ff       	call   106f0d <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  1071bd:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  1071c4:	00 
  1071c5:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1071cc:	e8 3c fd ff ff       	call   106f0d <lapicw>
	microdelay(200);
  1071d1:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1071d8:	e8 74 ff ff ff       	call   107151 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  1071dd:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  1071e4:	00 
  1071e5:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1071ec:	e8 1c fd ff ff       	call   106f0d <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  1071f1:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  1071f8:	e8 54 ff ff ff       	call   107151 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  1071fd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  107204:	eb 40                	jmp    107246 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  107206:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  10720a:	c1 e0 18             	shl    $0x18,%eax
  10720d:	89 44 24 04          	mov    %eax,0x4(%esp)
  107211:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  107218:	e8 f0 fc ff ff       	call   106f0d <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  10721d:	8b 45 0c             	mov    0xc(%ebp),%eax
  107220:	c1 e8 0c             	shr    $0xc,%eax
  107223:	80 cc 06             	or     $0x6,%ah
  107226:	89 44 24 04          	mov    %eax,0x4(%esp)
  10722a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  107231:	e8 d7 fc ff ff       	call   106f0d <lapicw>
		microdelay(200);
  107236:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10723d:	e8 0f ff ff ff       	call   107151 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  107242:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  107246:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
  10724a:	7e ba                	jle    107206 <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  10724c:	c9                   	leave  
  10724d:	c3                   	ret    

0010724e <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  10724e:	55                   	push   %ebp
  10724f:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  107251:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  107256:	8b 55 08             	mov    0x8(%ebp),%edx
  107259:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  10725b:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  107260:	8b 40 10             	mov    0x10(%eax),%eax
}
  107263:	5d                   	pop    %ebp
  107264:	c3                   	ret    

00107265 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  107265:	55                   	push   %ebp
  107266:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  107268:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  10726d:	8b 55 08             	mov    0x8(%ebp),%edx
  107270:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  107272:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  107277:	8b 55 0c             	mov    0xc(%ebp),%edx
  10727a:	89 50 10             	mov    %edx,0x10(%eax)
}
  10727d:	5d                   	pop    %ebp
  10727e:	c3                   	ret    

0010727f <ioapic_init>:

void
ioapic_init(void)
{
  10727f:	55                   	push   %ebp
  107280:	89 e5                	mov    %esp,%ebp
  107282:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  107285:	a1 64 ed 31 00       	mov    0x31ed64,%eax
  10728a:	85 c0                	test   %eax,%eax
  10728c:	0f 84 fd 00 00 00    	je     10738f <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  107292:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  107297:	85 c0                	test   %eax,%eax
  107299:	75 0a                	jne    1072a5 <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  10729b:	c7 05 60 ed 31 00 00 	movl   $0xfec00000,0x31ed60
  1072a2:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  1072a5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1072ac:	e8 9d ff ff ff       	call   10724e <ioapic_read>
  1072b1:	c1 e8 10             	shr    $0x10,%eax
  1072b4:	25 ff 00 00 00       	and    $0xff,%eax
  1072b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  1072bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1072c3:	e8 86 ff ff ff       	call   10724e <ioapic_read>
  1072c8:	c1 e8 18             	shr    $0x18,%eax
  1072cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  1072ce:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1072d2:	75 2a                	jne    1072fe <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  1072d4:	0f b6 05 5c ed 31 00 	movzbl 0x31ed5c,%eax
  1072db:	0f b6 c0             	movzbl %al,%eax
  1072de:	c1 e0 18             	shl    $0x18,%eax
  1072e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1072e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1072ec:	e8 74 ff ff ff       	call   107265 <ioapic_write>
		id = ioapicid;
  1072f1:	0f b6 05 5c ed 31 00 	movzbl 0x31ed5c,%eax
  1072f8:	0f b6 c0             	movzbl %al,%eax
  1072fb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  1072fe:	0f b6 05 5c ed 31 00 	movzbl 0x31ed5c,%eax
  107305:	0f b6 c0             	movzbl %al,%eax
  107308:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10730b:	74 31                	je     10733e <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  10730d:	0f b6 05 5c ed 31 00 	movzbl 0x31ed5c,%eax
  107314:	0f b6 c0             	movzbl %al,%eax
  107317:	89 44 24 10          	mov    %eax,0x10(%esp)
  10731b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10731e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  107322:	c7 44 24 08 e0 9e 10 	movl   $0x109ee0,0x8(%esp)
  107329:	00 
  10732a:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  107331:	00 
  107332:	c7 04 24 01 9f 10 00 	movl   $0x109f01,(%esp)
  107339:	e8 02 92 ff ff       	call   100540 <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  10733e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  107345:	eb 3e                	jmp    107385 <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  107347:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10734a:	83 c0 20             	add    $0x20,%eax
  10734d:	0d 00 00 01 00       	or     $0x10000,%eax
  107352:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107355:	83 c2 08             	add    $0x8,%edx
  107358:	01 d2                	add    %edx,%edx
  10735a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10735e:	89 14 24             	mov    %edx,(%esp)
  107361:	e8 ff fe ff ff       	call   107265 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  107366:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107369:	83 c0 08             	add    $0x8,%eax
  10736c:	01 c0                	add    %eax,%eax
  10736e:	83 c0 01             	add    $0x1,%eax
  107371:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107378:	00 
  107379:	89 04 24             	mov    %eax,(%esp)
  10737c:	e8 e4 fe ff ff       	call   107265 <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  107381:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  107385:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107388:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  10738b:	7e ba                	jle    107347 <ioapic_init+0xc8>
  10738d:	eb 01                	jmp    107390 <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  10738f:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  107390:	c9                   	leave  
  107391:	c3                   	ret    

00107392 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  107392:	55                   	push   %ebp
  107393:	89 e5                	mov    %esp,%ebp
  107395:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  107398:	a1 64 ed 31 00       	mov    0x31ed64,%eax
  10739d:	85 c0                	test   %eax,%eax
  10739f:	74 3a                	je     1073db <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  1073a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1073a4:	83 c0 20             	add    $0x20,%eax
  1073a7:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  1073aa:	8b 55 08             	mov    0x8(%ebp),%edx
  1073ad:	83 c2 08             	add    $0x8,%edx
  1073b0:	01 d2                	add    %edx,%edx
  1073b2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1073b6:	89 14 24             	mov    %edx,(%esp)
  1073b9:	e8 a7 fe ff ff       	call   107265 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  1073be:	8b 45 08             	mov    0x8(%ebp),%eax
  1073c1:	83 c0 08             	add    $0x8,%eax
  1073c4:	01 c0                	add    %eax,%eax
  1073c6:	83 c0 01             	add    $0x1,%eax
  1073c9:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  1073d0:	ff 
  1073d1:	89 04 24             	mov    %eax,(%esp)
  1073d4:	e8 8c fe ff ff       	call   107265 <ioapic_write>
  1073d9:	eb 01                	jmp    1073dc <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  1073db:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  1073dc:	c9                   	leave  
  1073dd:	c3                   	ret    

001073de <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  1073de:	55                   	push   %ebp
  1073df:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  1073e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1073e4:	8b 40 18             	mov    0x18(%eax),%eax
  1073e7:	83 e0 02             	and    $0x2,%eax
  1073ea:	85 c0                	test   %eax,%eax
  1073ec:	74 1c                	je     10740a <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  1073ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1073f1:	8b 00                	mov    (%eax),%eax
  1073f3:	8d 50 08             	lea    0x8(%eax),%edx
  1073f6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1073f9:	89 10                	mov    %edx,(%eax)
  1073fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1073fe:	8b 00                	mov    (%eax),%eax
  107400:	83 e8 08             	sub    $0x8,%eax
  107403:	8b 50 04             	mov    0x4(%eax),%edx
  107406:	8b 00                	mov    (%eax),%eax
  107408:	eb 47                	jmp    107451 <getuint+0x73>
	else if (st->flags & F_L)
  10740a:	8b 45 08             	mov    0x8(%ebp),%eax
  10740d:	8b 40 18             	mov    0x18(%eax),%eax
  107410:	83 e0 01             	and    $0x1,%eax
  107413:	84 c0                	test   %al,%al
  107415:	74 1e                	je     107435 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  107417:	8b 45 0c             	mov    0xc(%ebp),%eax
  10741a:	8b 00                	mov    (%eax),%eax
  10741c:	8d 50 04             	lea    0x4(%eax),%edx
  10741f:	8b 45 0c             	mov    0xc(%ebp),%eax
  107422:	89 10                	mov    %edx,(%eax)
  107424:	8b 45 0c             	mov    0xc(%ebp),%eax
  107427:	8b 00                	mov    (%eax),%eax
  107429:	83 e8 04             	sub    $0x4,%eax
  10742c:	8b 00                	mov    (%eax),%eax
  10742e:	ba 00 00 00 00       	mov    $0x0,%edx
  107433:	eb 1c                	jmp    107451 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  107435:	8b 45 0c             	mov    0xc(%ebp),%eax
  107438:	8b 00                	mov    (%eax),%eax
  10743a:	8d 50 04             	lea    0x4(%eax),%edx
  10743d:	8b 45 0c             	mov    0xc(%ebp),%eax
  107440:	89 10                	mov    %edx,(%eax)
  107442:	8b 45 0c             	mov    0xc(%ebp),%eax
  107445:	8b 00                	mov    (%eax),%eax
  107447:	83 e8 04             	sub    $0x4,%eax
  10744a:	8b 00                	mov    (%eax),%eax
  10744c:	ba 00 00 00 00       	mov    $0x0,%edx
}
  107451:	5d                   	pop    %ebp
  107452:	c3                   	ret    

00107453 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  107453:	55                   	push   %ebp
  107454:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  107456:	8b 45 08             	mov    0x8(%ebp),%eax
  107459:	8b 40 18             	mov    0x18(%eax),%eax
  10745c:	83 e0 02             	and    $0x2,%eax
  10745f:	85 c0                	test   %eax,%eax
  107461:	74 1c                	je     10747f <getint+0x2c>
		return va_arg(*ap, long long);
  107463:	8b 45 0c             	mov    0xc(%ebp),%eax
  107466:	8b 00                	mov    (%eax),%eax
  107468:	8d 50 08             	lea    0x8(%eax),%edx
  10746b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10746e:	89 10                	mov    %edx,(%eax)
  107470:	8b 45 0c             	mov    0xc(%ebp),%eax
  107473:	8b 00                	mov    (%eax),%eax
  107475:	83 e8 08             	sub    $0x8,%eax
  107478:	8b 50 04             	mov    0x4(%eax),%edx
  10747b:	8b 00                	mov    (%eax),%eax
  10747d:	eb 47                	jmp    1074c6 <getint+0x73>
	else if (st->flags & F_L)
  10747f:	8b 45 08             	mov    0x8(%ebp),%eax
  107482:	8b 40 18             	mov    0x18(%eax),%eax
  107485:	83 e0 01             	and    $0x1,%eax
  107488:	84 c0                	test   %al,%al
  10748a:	74 1e                	je     1074aa <getint+0x57>
		return va_arg(*ap, long);
  10748c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10748f:	8b 00                	mov    (%eax),%eax
  107491:	8d 50 04             	lea    0x4(%eax),%edx
  107494:	8b 45 0c             	mov    0xc(%ebp),%eax
  107497:	89 10                	mov    %edx,(%eax)
  107499:	8b 45 0c             	mov    0xc(%ebp),%eax
  10749c:	8b 00                	mov    (%eax),%eax
  10749e:	83 e8 04             	sub    $0x4,%eax
  1074a1:	8b 00                	mov    (%eax),%eax
  1074a3:	89 c2                	mov    %eax,%edx
  1074a5:	c1 fa 1f             	sar    $0x1f,%edx
  1074a8:	eb 1c                	jmp    1074c6 <getint+0x73>
	else
		return va_arg(*ap, int);
  1074aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1074ad:	8b 00                	mov    (%eax),%eax
  1074af:	8d 50 04             	lea    0x4(%eax),%edx
  1074b2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1074b5:	89 10                	mov    %edx,(%eax)
  1074b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1074ba:	8b 00                	mov    (%eax),%eax
  1074bc:	83 e8 04             	sub    $0x4,%eax
  1074bf:	8b 00                	mov    (%eax),%eax
  1074c1:	89 c2                	mov    %eax,%edx
  1074c3:	c1 fa 1f             	sar    $0x1f,%edx
}
  1074c6:	5d                   	pop    %ebp
  1074c7:	c3                   	ret    

001074c8 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  1074c8:	55                   	push   %ebp
  1074c9:	89 e5                	mov    %esp,%ebp
  1074cb:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  1074ce:	eb 1a                	jmp    1074ea <putpad+0x22>
		st->putch(st->padc, st->putdat);
  1074d0:	8b 45 08             	mov    0x8(%ebp),%eax
  1074d3:	8b 08                	mov    (%eax),%ecx
  1074d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1074d8:	8b 50 04             	mov    0x4(%eax),%edx
  1074db:	8b 45 08             	mov    0x8(%ebp),%eax
  1074de:	8b 40 08             	mov    0x8(%eax),%eax
  1074e1:	89 54 24 04          	mov    %edx,0x4(%esp)
  1074e5:	89 04 24             	mov    %eax,(%esp)
  1074e8:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  1074ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1074ed:	8b 40 0c             	mov    0xc(%eax),%eax
  1074f0:	8d 50 ff             	lea    -0x1(%eax),%edx
  1074f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1074f6:	89 50 0c             	mov    %edx,0xc(%eax)
  1074f9:	8b 45 08             	mov    0x8(%ebp),%eax
  1074fc:	8b 40 0c             	mov    0xc(%eax),%eax
  1074ff:	85 c0                	test   %eax,%eax
  107501:	79 cd                	jns    1074d0 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  107503:	c9                   	leave  
  107504:	c3                   	ret    

00107505 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  107505:	55                   	push   %ebp
  107506:	89 e5                	mov    %esp,%ebp
  107508:	53                   	push   %ebx
  107509:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  10750c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107510:	79 18                	jns    10752a <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  107512:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107519:	00 
  10751a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10751d:	89 04 24             	mov    %eax,(%esp)
  107520:	e8 e7 07 00 00       	call   107d0c <strchr>
  107525:	89 45 f0             	mov    %eax,-0x10(%ebp)
  107528:	eb 2c                	jmp    107556 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  10752a:	8b 45 10             	mov    0x10(%ebp),%eax
  10752d:	89 44 24 08          	mov    %eax,0x8(%esp)
  107531:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107538:	00 
  107539:	8b 45 0c             	mov    0xc(%ebp),%eax
  10753c:	89 04 24             	mov    %eax,(%esp)
  10753f:	e8 cc 09 00 00       	call   107f10 <memchr>
  107544:	89 45 f0             	mov    %eax,-0x10(%ebp)
  107547:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  10754b:	75 09                	jne    107556 <putstr+0x51>
		lim = str + maxlen;
  10754d:	8b 45 10             	mov    0x10(%ebp),%eax
  107550:	03 45 0c             	add    0xc(%ebp),%eax
  107553:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  107556:	8b 45 08             	mov    0x8(%ebp),%eax
  107559:	8b 40 0c             	mov    0xc(%eax),%eax
  10755c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  10755f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  107562:	89 cb                	mov    %ecx,%ebx
  107564:	29 d3                	sub    %edx,%ebx
  107566:	89 da                	mov    %ebx,%edx
  107568:	8d 14 10             	lea    (%eax,%edx,1),%edx
  10756b:	8b 45 08             	mov    0x8(%ebp),%eax
  10756e:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  107571:	8b 45 08             	mov    0x8(%ebp),%eax
  107574:	8b 40 18             	mov    0x18(%eax),%eax
  107577:	83 e0 10             	and    $0x10,%eax
  10757a:	85 c0                	test   %eax,%eax
  10757c:	75 32                	jne    1075b0 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  10757e:	8b 45 08             	mov    0x8(%ebp),%eax
  107581:	89 04 24             	mov    %eax,(%esp)
  107584:	e8 3f ff ff ff       	call   1074c8 <putpad>
	while (str < lim) {
  107589:	eb 25                	jmp    1075b0 <putstr+0xab>
		char ch = *str++;
  10758b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10758e:	0f b6 00             	movzbl (%eax),%eax
  107591:	88 45 f7             	mov    %al,-0x9(%ebp)
  107594:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  107598:	8b 45 08             	mov    0x8(%ebp),%eax
  10759b:	8b 08                	mov    (%eax),%ecx
  10759d:	8b 45 08             	mov    0x8(%ebp),%eax
  1075a0:	8b 50 04             	mov    0x4(%eax),%edx
  1075a3:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  1075a7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1075ab:	89 04 24             	mov    %eax,(%esp)
  1075ae:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  1075b0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075b3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1075b6:	72 d3                	jb     10758b <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  1075b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1075bb:	89 04 24             	mov    %eax,(%esp)
  1075be:	e8 05 ff ff ff       	call   1074c8 <putpad>
}
  1075c3:	83 c4 24             	add    $0x24,%esp
  1075c6:	5b                   	pop    %ebx
  1075c7:	5d                   	pop    %ebp
  1075c8:	c3                   	ret    

001075c9 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  1075c9:	55                   	push   %ebp
  1075ca:	89 e5                	mov    %esp,%ebp
  1075cc:	53                   	push   %ebx
  1075cd:	83 ec 24             	sub    $0x24,%esp
  1075d0:	8b 45 10             	mov    0x10(%ebp),%eax
  1075d3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1075d6:	8b 45 14             	mov    0x14(%ebp),%eax
  1075d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  1075dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1075df:	8b 40 1c             	mov    0x1c(%eax),%eax
  1075e2:	89 c2                	mov    %eax,%edx
  1075e4:	c1 fa 1f             	sar    $0x1f,%edx
  1075e7:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  1075ea:	77 4e                	ja     10763a <genint+0x71>
  1075ec:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  1075ef:	72 05                	jb     1075f6 <genint+0x2d>
  1075f1:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1075f4:	77 44                	ja     10763a <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  1075f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1075f9:	8b 40 1c             	mov    0x1c(%eax),%eax
  1075fc:	89 c2                	mov    %eax,%edx
  1075fe:	c1 fa 1f             	sar    $0x1f,%edx
  107601:	89 44 24 08          	mov    %eax,0x8(%esp)
  107605:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107609:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10760c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10760f:	89 04 24             	mov    %eax,(%esp)
  107612:	89 54 24 04          	mov    %edx,0x4(%esp)
  107616:	e8 35 09 00 00       	call   107f50 <__udivdi3>
  10761b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10761f:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107623:	8b 45 0c             	mov    0xc(%ebp),%eax
  107626:	89 44 24 04          	mov    %eax,0x4(%esp)
  10762a:	8b 45 08             	mov    0x8(%ebp),%eax
  10762d:	89 04 24             	mov    %eax,(%esp)
  107630:	e8 94 ff ff ff       	call   1075c9 <genint>
  107635:	89 45 0c             	mov    %eax,0xc(%ebp)
  107638:	eb 1b                	jmp    107655 <genint+0x8c>
	else if (st->signc >= 0)
  10763a:	8b 45 08             	mov    0x8(%ebp),%eax
  10763d:	8b 40 14             	mov    0x14(%eax),%eax
  107640:	85 c0                	test   %eax,%eax
  107642:	78 11                	js     107655 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  107644:	8b 45 08             	mov    0x8(%ebp),%eax
  107647:	8b 40 14             	mov    0x14(%eax),%eax
  10764a:	89 c2                	mov    %eax,%edx
  10764c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10764f:	88 10                	mov    %dl,(%eax)
  107651:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  107655:	8b 45 08             	mov    0x8(%ebp),%eax
  107658:	8b 40 1c             	mov    0x1c(%eax),%eax
  10765b:	89 c1                	mov    %eax,%ecx
  10765d:	89 c3                	mov    %eax,%ebx
  10765f:	c1 fb 1f             	sar    $0x1f,%ebx
  107662:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107665:	8b 55 f4             	mov    -0xc(%ebp),%edx
  107668:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10766c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  107670:	89 04 24             	mov    %eax,(%esp)
  107673:	89 54 24 04          	mov    %edx,0x4(%esp)
  107677:	e8 04 0a 00 00       	call   108080 <__umoddi3>
  10767c:	05 10 9f 10 00       	add    $0x109f10,%eax
  107681:	0f b6 10             	movzbl (%eax),%edx
  107684:	8b 45 0c             	mov    0xc(%ebp),%eax
  107687:	88 10                	mov    %dl,(%eax)
  107689:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  10768d:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  107690:	83 c4 24             	add    $0x24,%esp
  107693:	5b                   	pop    %ebx
  107694:	5d                   	pop    %ebp
  107695:	c3                   	ret    

00107696 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  107696:	55                   	push   %ebp
  107697:	89 e5                	mov    %esp,%ebp
  107699:	83 ec 58             	sub    $0x58,%esp
  10769c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10769f:	89 45 c0             	mov    %eax,-0x40(%ebp)
  1076a2:	8b 45 10             	mov    0x10(%ebp),%eax
  1076a5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  1076a8:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1076ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  1076ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1076b1:	8b 55 14             	mov    0x14(%ebp),%edx
  1076b4:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  1076b7:	8b 45 c0             	mov    -0x40(%ebp),%eax
  1076ba:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  1076bd:	89 44 24 08          	mov    %eax,0x8(%esp)
  1076c1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1076c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1076c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1076cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1076cf:	89 04 24             	mov    %eax,(%esp)
  1076d2:	e8 f2 fe ff ff       	call   1075c9 <genint>
  1076d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  1076da:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1076dd:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1076e0:	89 d1                	mov    %edx,%ecx
  1076e2:	29 c1                	sub    %eax,%ecx
  1076e4:	89 c8                	mov    %ecx,%eax
  1076e6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1076ea:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1076ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  1076f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1076f4:	89 04 24             	mov    %eax,(%esp)
  1076f7:	e8 09 fe ff ff       	call   107505 <putstr>
}
  1076fc:	c9                   	leave  
  1076fd:	c3                   	ret    

001076fe <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  1076fe:	55                   	push   %ebp
  1076ff:	89 e5                	mov    %esp,%ebp
  107701:	53                   	push   %ebx
  107702:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  107705:	8d 55 c8             	lea    -0x38(%ebp),%edx
  107708:	b9 00 00 00 00       	mov    $0x0,%ecx
  10770d:	b8 20 00 00 00       	mov    $0x20,%eax
  107712:	89 c3                	mov    %eax,%ebx
  107714:	83 e3 fc             	and    $0xfffffffc,%ebx
  107717:	b8 00 00 00 00       	mov    $0x0,%eax
  10771c:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  10771f:	83 c0 04             	add    $0x4,%eax
  107722:	39 d8                	cmp    %ebx,%eax
  107724:	72 f6                	jb     10771c <vprintfmt+0x1e>
  107726:	01 c2                	add    %eax,%edx
  107728:	8b 45 08             	mov    0x8(%ebp),%eax
  10772b:	89 45 c8             	mov    %eax,-0x38(%ebp)
  10772e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107731:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  107734:	eb 17                	jmp    10774d <vprintfmt+0x4f>
			if (ch == '\0')
  107736:	85 db                	test   %ebx,%ebx
  107738:	0f 84 52 03 00 00    	je     107a90 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  10773e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107741:	89 44 24 04          	mov    %eax,0x4(%esp)
  107745:	89 1c 24             	mov    %ebx,(%esp)
  107748:	8b 45 08             	mov    0x8(%ebp),%eax
  10774b:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10774d:	8b 45 10             	mov    0x10(%ebp),%eax
  107750:	0f b6 00             	movzbl (%eax),%eax
  107753:	0f b6 d8             	movzbl %al,%ebx
  107756:	83 fb 25             	cmp    $0x25,%ebx
  107759:	0f 95 c0             	setne  %al
  10775c:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  107760:	84 c0                	test   %al,%al
  107762:	75 d2                	jne    107736 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  107764:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  10776b:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  107772:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  107779:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  107780:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  107787:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  10778e:	eb 04                	jmp    107794 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  107790:	90                   	nop
  107791:	eb 01                	jmp    107794 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  107793:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  107794:	8b 45 10             	mov    0x10(%ebp),%eax
  107797:	0f b6 00             	movzbl (%eax),%eax
  10779a:	0f b6 d8             	movzbl %al,%ebx
  10779d:	89 d8                	mov    %ebx,%eax
  10779f:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1077a3:	83 e8 20             	sub    $0x20,%eax
  1077a6:	83 f8 58             	cmp    $0x58,%eax
  1077a9:	0f 87 b1 02 00 00    	ja     107a60 <vprintfmt+0x362>
  1077af:	8b 04 85 28 9f 10 00 	mov    0x109f28(,%eax,4),%eax
  1077b6:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  1077b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1077bb:	83 c8 10             	or     $0x10,%eax
  1077be:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1077c1:	eb d1                	jmp    107794 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  1077c3:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  1077ca:	eb c8                	jmp    107794 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  1077cc:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1077cf:	85 c0                	test   %eax,%eax
  1077d1:	79 bd                	jns    107790 <vprintfmt+0x92>
				st.signc = ' ';
  1077d3:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  1077da:	eb b8                	jmp    107794 <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  1077dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1077df:	83 e0 08             	and    $0x8,%eax
  1077e2:	85 c0                	test   %eax,%eax
  1077e4:	75 07                	jne    1077ed <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  1077e6:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1077ed:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  1077f4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1077f7:	89 d0                	mov    %edx,%eax
  1077f9:	c1 e0 02             	shl    $0x2,%eax
  1077fc:	01 d0                	add    %edx,%eax
  1077fe:	01 c0                	add    %eax,%eax
  107800:	01 d8                	add    %ebx,%eax
  107802:	83 e8 30             	sub    $0x30,%eax
  107805:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  107808:	8b 45 10             	mov    0x10(%ebp),%eax
  10780b:	0f b6 00             	movzbl (%eax),%eax
  10780e:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  107811:	83 fb 2f             	cmp    $0x2f,%ebx
  107814:	7e 21                	jle    107837 <vprintfmt+0x139>
  107816:	83 fb 39             	cmp    $0x39,%ebx
  107819:	7f 1f                	jg     10783a <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10781b:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  10781f:	eb d3                	jmp    1077f4 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  107821:	8b 45 14             	mov    0x14(%ebp),%eax
  107824:	83 c0 04             	add    $0x4,%eax
  107827:	89 45 14             	mov    %eax,0x14(%ebp)
  10782a:	8b 45 14             	mov    0x14(%ebp),%eax
  10782d:	83 e8 04             	sub    $0x4,%eax
  107830:	8b 00                	mov    (%eax),%eax
  107832:	89 45 d8             	mov    %eax,-0x28(%ebp)
  107835:	eb 04                	jmp    10783b <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  107837:	90                   	nop
  107838:	eb 01                	jmp    10783b <vprintfmt+0x13d>
  10783a:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  10783b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10783e:	83 e0 08             	and    $0x8,%eax
  107841:	85 c0                	test   %eax,%eax
  107843:	0f 85 4a ff ff ff    	jne    107793 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  107849:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10784c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  10784f:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  107856:	e9 39 ff ff ff       	jmp    107794 <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  10785b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10785e:	83 c8 08             	or     $0x8,%eax
  107861:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107864:	e9 2b ff ff ff       	jmp    107794 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  107869:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10786c:	83 c8 04             	or     $0x4,%eax
  10786f:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107872:	e9 1d ff ff ff       	jmp    107794 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  107877:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10787a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10787d:	83 e0 01             	and    $0x1,%eax
  107880:	84 c0                	test   %al,%al
  107882:	74 07                	je     10788b <vprintfmt+0x18d>
  107884:	b8 02 00 00 00       	mov    $0x2,%eax
  107889:	eb 05                	jmp    107890 <vprintfmt+0x192>
  10788b:	b8 01 00 00 00       	mov    $0x1,%eax
  107890:	09 d0                	or     %edx,%eax
  107892:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107895:	e9 fa fe ff ff       	jmp    107794 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  10789a:	8b 45 14             	mov    0x14(%ebp),%eax
  10789d:	83 c0 04             	add    $0x4,%eax
  1078a0:	89 45 14             	mov    %eax,0x14(%ebp)
  1078a3:	8b 45 14             	mov    0x14(%ebp),%eax
  1078a6:	83 e8 04             	sub    $0x4,%eax
  1078a9:	8b 00                	mov    (%eax),%eax
  1078ab:	8b 55 0c             	mov    0xc(%ebp),%edx
  1078ae:	89 54 24 04          	mov    %edx,0x4(%esp)
  1078b2:	89 04 24             	mov    %eax,(%esp)
  1078b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1078b8:	ff d0                	call   *%eax
			break;
  1078ba:	e9 cb 01 00 00       	jmp    107a8a <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  1078bf:	8b 45 14             	mov    0x14(%ebp),%eax
  1078c2:	83 c0 04             	add    $0x4,%eax
  1078c5:	89 45 14             	mov    %eax,0x14(%ebp)
  1078c8:	8b 45 14             	mov    0x14(%ebp),%eax
  1078cb:	83 e8 04             	sub    $0x4,%eax
  1078ce:	8b 00                	mov    (%eax),%eax
  1078d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1078d3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1078d7:	75 07                	jne    1078e0 <vprintfmt+0x1e2>
				s = "(null)";
  1078d9:	c7 45 f4 21 9f 10 00 	movl   $0x109f21,-0xc(%ebp)
			putstr(&st, s, st.prec);
  1078e0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1078e3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1078e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1078ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  1078ee:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1078f1:	89 04 24             	mov    %eax,(%esp)
  1078f4:	e8 0c fc ff ff       	call   107505 <putstr>
			break;
  1078f9:	e9 8c 01 00 00       	jmp    107a8a <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  1078fe:	8d 45 14             	lea    0x14(%ebp),%eax
  107901:	89 44 24 04          	mov    %eax,0x4(%esp)
  107905:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107908:	89 04 24             	mov    %eax,(%esp)
  10790b:	e8 43 fb ff ff       	call   107453 <getint>
  107910:	89 45 e8             	mov    %eax,-0x18(%ebp)
  107913:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  107916:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107919:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10791c:	85 d2                	test   %edx,%edx
  10791e:	79 1a                	jns    10793a <vprintfmt+0x23c>
				num = -(intmax_t) num;
  107920:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107923:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107926:	f7 d8                	neg    %eax
  107928:	83 d2 00             	adc    $0x0,%edx
  10792b:	f7 da                	neg    %edx
  10792d:	89 45 e8             	mov    %eax,-0x18(%ebp)
  107930:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  107933:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  10793a:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  107941:	00 
  107942:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107945:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107948:	89 44 24 04          	mov    %eax,0x4(%esp)
  10794c:	89 54 24 08          	mov    %edx,0x8(%esp)
  107950:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107953:	89 04 24             	mov    %eax,(%esp)
  107956:	e8 3b fd ff ff       	call   107696 <putint>
			break;
  10795b:	e9 2a 01 00 00       	jmp    107a8a <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  107960:	8d 45 14             	lea    0x14(%ebp),%eax
  107963:	89 44 24 04          	mov    %eax,0x4(%esp)
  107967:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10796a:	89 04 24             	mov    %eax,(%esp)
  10796d:	e8 6c fa ff ff       	call   1073de <getuint>
  107972:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  107979:	00 
  10797a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10797e:	89 54 24 08          	mov    %edx,0x8(%esp)
  107982:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107985:	89 04 24             	mov    %eax,(%esp)
  107988:	e8 09 fd ff ff       	call   107696 <putint>
			break;
  10798d:	e9 f8 00 00 00       	jmp    107a8a <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  107992:	8d 45 14             	lea    0x14(%ebp),%eax
  107995:	89 44 24 04          	mov    %eax,0x4(%esp)
  107999:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10799c:	89 04 24             	mov    %eax,(%esp)
  10799f:	e8 3a fa ff ff       	call   1073de <getuint>
  1079a4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  1079ab:	00 
  1079ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1079b0:	89 54 24 08          	mov    %edx,0x8(%esp)
  1079b4:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1079b7:	89 04 24             	mov    %eax,(%esp)
  1079ba:	e8 d7 fc ff ff       	call   107696 <putint>
			break;
  1079bf:	e9 c6 00 00 00       	jmp    107a8a <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  1079c4:	8d 45 14             	lea    0x14(%ebp),%eax
  1079c7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1079cb:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1079ce:	89 04 24             	mov    %eax,(%esp)
  1079d1:	e8 08 fa ff ff       	call   1073de <getuint>
  1079d6:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1079dd:	00 
  1079de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1079e2:	89 54 24 08          	mov    %edx,0x8(%esp)
  1079e6:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1079e9:	89 04 24             	mov    %eax,(%esp)
  1079ec:	e8 a5 fc ff ff       	call   107696 <putint>
			break;
  1079f1:	e9 94 00 00 00       	jmp    107a8a <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  1079f6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1079f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1079fd:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  107a04:	8b 45 08             	mov    0x8(%ebp),%eax
  107a07:	ff d0                	call   *%eax
			putch('x', putdat);
  107a09:	8b 45 0c             	mov    0xc(%ebp),%eax
  107a0c:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a10:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  107a17:	8b 45 08             	mov    0x8(%ebp),%eax
  107a1a:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  107a1c:	8b 45 14             	mov    0x14(%ebp),%eax
  107a1f:	83 c0 04             	add    $0x4,%eax
  107a22:	89 45 14             	mov    %eax,0x14(%ebp)
  107a25:	8b 45 14             	mov    0x14(%ebp),%eax
  107a28:	83 e8 04             	sub    $0x4,%eax
  107a2b:	8b 00                	mov    (%eax),%eax
  107a2d:	ba 00 00 00 00       	mov    $0x0,%edx
  107a32:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  107a39:	00 
  107a3a:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a3e:	89 54 24 08          	mov    %edx,0x8(%esp)
  107a42:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107a45:	89 04 24             	mov    %eax,(%esp)
  107a48:	e8 49 fc ff ff       	call   107696 <putint>
			break;
  107a4d:	eb 3b                	jmp    107a8a <vprintfmt+0x38c>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
  107a4f:	8b 45 0c             	mov    0xc(%ebp),%eax
  107a52:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a56:	89 1c 24             	mov    %ebx,(%esp)
  107a59:	8b 45 08             	mov    0x8(%ebp),%eax
  107a5c:	ff d0                	call   *%eax
			break;
  107a5e:	eb 2a                	jmp    107a8a <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  107a60:	8b 45 0c             	mov    0xc(%ebp),%eax
  107a63:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a67:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  107a6e:	8b 45 08             	mov    0x8(%ebp),%eax
  107a71:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  107a73:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107a77:	eb 04                	jmp    107a7d <vprintfmt+0x37f>
  107a79:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107a7d:	8b 45 10             	mov    0x10(%ebp),%eax
  107a80:	83 e8 01             	sub    $0x1,%eax
  107a83:	0f b6 00             	movzbl (%eax),%eax
  107a86:	3c 25                	cmp    $0x25,%al
  107a88:	75 ef                	jne    107a79 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  107a8a:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  107a8b:	e9 bd fc ff ff       	jmp    10774d <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  107a90:	83 c4 44             	add    $0x44,%esp
  107a93:	5b                   	pop    %ebx
  107a94:	5d                   	pop    %ebp
  107a95:	c3                   	ret    

00107a96 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  107a96:	55                   	push   %ebp
  107a97:	89 e5                	mov    %esp,%ebp
  107a99:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  107a9c:	8b 45 0c             	mov    0xc(%ebp),%eax
  107a9f:	8b 00                	mov    (%eax),%eax
  107aa1:	8b 55 08             	mov    0x8(%ebp),%edx
  107aa4:	89 d1                	mov    %edx,%ecx
  107aa6:	8b 55 0c             	mov    0xc(%ebp),%edx
  107aa9:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  107aad:	8d 50 01             	lea    0x1(%eax),%edx
  107ab0:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ab3:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  107ab5:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ab8:	8b 00                	mov    (%eax),%eax
  107aba:	3d ff 00 00 00       	cmp    $0xff,%eax
  107abf:	75 24                	jne    107ae5 <putch+0x4f>
		b->buf[b->idx] = 0;
  107ac1:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ac4:	8b 00                	mov    (%eax),%eax
  107ac6:	8b 55 0c             	mov    0xc(%ebp),%edx
  107ac9:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  107ace:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ad1:	83 c0 08             	add    $0x8,%eax
  107ad4:	89 04 24             	mov    %eax,(%esp)
  107ad7:	e8 1c 89 ff ff       	call   1003f8 <cputs>
		b->idx = 0;
  107adc:	8b 45 0c             	mov    0xc(%ebp),%eax
  107adf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  107ae5:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ae8:	8b 40 04             	mov    0x4(%eax),%eax
  107aeb:	8d 50 01             	lea    0x1(%eax),%edx
  107aee:	8b 45 0c             	mov    0xc(%ebp),%eax
  107af1:	89 50 04             	mov    %edx,0x4(%eax)
}
  107af4:	c9                   	leave  
  107af5:	c3                   	ret    

00107af6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  107af6:	55                   	push   %ebp
  107af7:	89 e5                	mov    %esp,%ebp
  107af9:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  107aff:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  107b06:	00 00 00 
	b.cnt = 0;
  107b09:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  107b10:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  107b13:	b8 96 7a 10 00       	mov    $0x107a96,%eax
  107b18:	8b 55 0c             	mov    0xc(%ebp),%edx
  107b1b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107b1f:	8b 55 08             	mov    0x8(%ebp),%edx
  107b22:	89 54 24 08          	mov    %edx,0x8(%esp)
  107b26:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  107b2c:	89 54 24 04          	mov    %edx,0x4(%esp)
  107b30:	89 04 24             	mov    %eax,(%esp)
  107b33:	e8 c6 fb ff ff       	call   1076fe <vprintfmt>

	b.buf[b.idx] = 0;
  107b38:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  107b3e:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  107b45:	00 
	cputs(b.buf);
  107b46:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  107b4c:	83 c0 08             	add    $0x8,%eax
  107b4f:	89 04 24             	mov    %eax,(%esp)
  107b52:	e8 a1 88 ff ff       	call   1003f8 <cputs>

	return b.cnt;
  107b57:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  107b5d:	c9                   	leave  
  107b5e:	c3                   	ret    

00107b5f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  107b5f:	55                   	push   %ebp
  107b60:	89 e5                	mov    %esp,%ebp
  107b62:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  107b65:	8d 45 08             	lea    0x8(%ebp),%eax
  107b68:	83 c0 04             	add    $0x4,%eax
  107b6b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  107b6e:	8b 45 08             	mov    0x8(%ebp),%eax
  107b71:	8b 55 f0             	mov    -0x10(%ebp),%edx
  107b74:	89 54 24 04          	mov    %edx,0x4(%esp)
  107b78:	89 04 24             	mov    %eax,(%esp)
  107b7b:	e8 76 ff ff ff       	call   107af6 <vcprintf>
  107b80:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  107b83:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  107b86:	c9                   	leave  
  107b87:	c3                   	ret    

00107b88 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  107b88:	55                   	push   %ebp
  107b89:	89 e5                	mov    %esp,%ebp
  107b8b:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  107b8e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  107b95:	eb 08                	jmp    107b9f <strlen+0x17>
		n++;
  107b97:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  107b9b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107b9f:	8b 45 08             	mov    0x8(%ebp),%eax
  107ba2:	0f b6 00             	movzbl (%eax),%eax
  107ba5:	84 c0                	test   %al,%al
  107ba7:	75 ee                	jne    107b97 <strlen+0xf>
		n++;
	return n;
  107ba9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  107bac:	c9                   	leave  
  107bad:	c3                   	ret    

00107bae <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  107bae:	55                   	push   %ebp
  107baf:	89 e5                	mov    %esp,%ebp
  107bb1:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  107bb4:	8b 45 08             	mov    0x8(%ebp),%eax
  107bb7:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  107bba:	8b 45 0c             	mov    0xc(%ebp),%eax
  107bbd:	0f b6 10             	movzbl (%eax),%edx
  107bc0:	8b 45 08             	mov    0x8(%ebp),%eax
  107bc3:	88 10                	mov    %dl,(%eax)
  107bc5:	8b 45 08             	mov    0x8(%ebp),%eax
  107bc8:	0f b6 00             	movzbl (%eax),%eax
  107bcb:	84 c0                	test   %al,%al
  107bcd:	0f 95 c0             	setne  %al
  107bd0:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107bd4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  107bd8:	84 c0                	test   %al,%al
  107bda:	75 de                	jne    107bba <strcpy+0xc>
		/* do nothing */;
	return ret;
  107bdc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  107bdf:	c9                   	leave  
  107be0:	c3                   	ret    

00107be1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  107be1:	55                   	push   %ebp
  107be2:	89 e5                	mov    %esp,%ebp
  107be4:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  107be7:	8b 45 08             	mov    0x8(%ebp),%eax
  107bea:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  107bed:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  107bf4:	eb 21                	jmp    107c17 <strncpy+0x36>
		*dst++ = *src;
  107bf6:	8b 45 0c             	mov    0xc(%ebp),%eax
  107bf9:	0f b6 10             	movzbl (%eax),%edx
  107bfc:	8b 45 08             	mov    0x8(%ebp),%eax
  107bff:	88 10                	mov    %dl,(%eax)
  107c01:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  107c05:	8b 45 0c             	mov    0xc(%ebp),%eax
  107c08:	0f b6 00             	movzbl (%eax),%eax
  107c0b:	84 c0                	test   %al,%al
  107c0d:	74 04                	je     107c13 <strncpy+0x32>
			src++;
  107c0f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  107c13:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  107c17:	8b 45 f8             	mov    -0x8(%ebp),%eax
  107c1a:	3b 45 10             	cmp    0x10(%ebp),%eax
  107c1d:	72 d7                	jb     107bf6 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  107c1f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  107c22:	c9                   	leave  
  107c23:	c3                   	ret    

00107c24 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  107c24:	55                   	push   %ebp
  107c25:	89 e5                	mov    %esp,%ebp
  107c27:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  107c2a:	8b 45 08             	mov    0x8(%ebp),%eax
  107c2d:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  107c30:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107c34:	74 2f                	je     107c65 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  107c36:	eb 13                	jmp    107c4b <strlcpy+0x27>
			*dst++ = *src++;
  107c38:	8b 45 0c             	mov    0xc(%ebp),%eax
  107c3b:	0f b6 10             	movzbl (%eax),%edx
  107c3e:	8b 45 08             	mov    0x8(%ebp),%eax
  107c41:	88 10                	mov    %dl,(%eax)
  107c43:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107c47:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  107c4b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107c4f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107c53:	74 0a                	je     107c5f <strlcpy+0x3b>
  107c55:	8b 45 0c             	mov    0xc(%ebp),%eax
  107c58:	0f b6 00             	movzbl (%eax),%eax
  107c5b:	84 c0                	test   %al,%al
  107c5d:	75 d9                	jne    107c38 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  107c5f:	8b 45 08             	mov    0x8(%ebp),%eax
  107c62:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  107c65:	8b 55 08             	mov    0x8(%ebp),%edx
  107c68:	8b 45 fc             	mov    -0x4(%ebp),%eax
  107c6b:	89 d1                	mov    %edx,%ecx
  107c6d:	29 c1                	sub    %eax,%ecx
  107c6f:	89 c8                	mov    %ecx,%eax
}
  107c71:	c9                   	leave  
  107c72:	c3                   	ret    

00107c73 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  107c73:	55                   	push   %ebp
  107c74:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  107c76:	eb 08                	jmp    107c80 <strcmp+0xd>
		p++, q++;
  107c78:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107c7c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  107c80:	8b 45 08             	mov    0x8(%ebp),%eax
  107c83:	0f b6 00             	movzbl (%eax),%eax
  107c86:	84 c0                	test   %al,%al
  107c88:	74 10                	je     107c9a <strcmp+0x27>
  107c8a:	8b 45 08             	mov    0x8(%ebp),%eax
  107c8d:	0f b6 10             	movzbl (%eax),%edx
  107c90:	8b 45 0c             	mov    0xc(%ebp),%eax
  107c93:	0f b6 00             	movzbl (%eax),%eax
  107c96:	38 c2                	cmp    %al,%dl
  107c98:	74 de                	je     107c78 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  107c9a:	8b 45 08             	mov    0x8(%ebp),%eax
  107c9d:	0f b6 00             	movzbl (%eax),%eax
  107ca0:	0f b6 d0             	movzbl %al,%edx
  107ca3:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ca6:	0f b6 00             	movzbl (%eax),%eax
  107ca9:	0f b6 c0             	movzbl %al,%eax
  107cac:	89 d1                	mov    %edx,%ecx
  107cae:	29 c1                	sub    %eax,%ecx
  107cb0:	89 c8                	mov    %ecx,%eax
}
  107cb2:	5d                   	pop    %ebp
  107cb3:	c3                   	ret    

00107cb4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  107cb4:	55                   	push   %ebp
  107cb5:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  107cb7:	eb 0c                	jmp    107cc5 <strncmp+0x11>
		n--, p++, q++;
  107cb9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107cbd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107cc1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  107cc5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107cc9:	74 1a                	je     107ce5 <strncmp+0x31>
  107ccb:	8b 45 08             	mov    0x8(%ebp),%eax
  107cce:	0f b6 00             	movzbl (%eax),%eax
  107cd1:	84 c0                	test   %al,%al
  107cd3:	74 10                	je     107ce5 <strncmp+0x31>
  107cd5:	8b 45 08             	mov    0x8(%ebp),%eax
  107cd8:	0f b6 10             	movzbl (%eax),%edx
  107cdb:	8b 45 0c             	mov    0xc(%ebp),%eax
  107cde:	0f b6 00             	movzbl (%eax),%eax
  107ce1:	38 c2                	cmp    %al,%dl
  107ce3:	74 d4                	je     107cb9 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  107ce5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107ce9:	75 07                	jne    107cf2 <strncmp+0x3e>
		return 0;
  107ceb:	b8 00 00 00 00       	mov    $0x0,%eax
  107cf0:	eb 18                	jmp    107d0a <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  107cf2:	8b 45 08             	mov    0x8(%ebp),%eax
  107cf5:	0f b6 00             	movzbl (%eax),%eax
  107cf8:	0f b6 d0             	movzbl %al,%edx
  107cfb:	8b 45 0c             	mov    0xc(%ebp),%eax
  107cfe:	0f b6 00             	movzbl (%eax),%eax
  107d01:	0f b6 c0             	movzbl %al,%eax
  107d04:	89 d1                	mov    %edx,%ecx
  107d06:	29 c1                	sub    %eax,%ecx
  107d08:	89 c8                	mov    %ecx,%eax
}
  107d0a:	5d                   	pop    %ebp
  107d0b:	c3                   	ret    

00107d0c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  107d0c:	55                   	push   %ebp
  107d0d:	89 e5                	mov    %esp,%ebp
  107d0f:	83 ec 04             	sub    $0x4,%esp
  107d12:	8b 45 0c             	mov    0xc(%ebp),%eax
  107d15:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  107d18:	eb 1a                	jmp    107d34 <strchr+0x28>
		if (*s++ == 0)
  107d1a:	8b 45 08             	mov    0x8(%ebp),%eax
  107d1d:	0f b6 00             	movzbl (%eax),%eax
  107d20:	84 c0                	test   %al,%al
  107d22:	0f 94 c0             	sete   %al
  107d25:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107d29:	84 c0                	test   %al,%al
  107d2b:	74 07                	je     107d34 <strchr+0x28>
			return NULL;
  107d2d:	b8 00 00 00 00       	mov    $0x0,%eax
  107d32:	eb 0e                	jmp    107d42 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  107d34:	8b 45 08             	mov    0x8(%ebp),%eax
  107d37:	0f b6 00             	movzbl (%eax),%eax
  107d3a:	3a 45 fc             	cmp    -0x4(%ebp),%al
  107d3d:	75 db                	jne    107d1a <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  107d3f:	8b 45 08             	mov    0x8(%ebp),%eax
}
  107d42:	c9                   	leave  
  107d43:	c3                   	ret    

00107d44 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  107d44:	55                   	push   %ebp
  107d45:	89 e5                	mov    %esp,%ebp
  107d47:	57                   	push   %edi
  107d48:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  107d4b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107d4f:	75 05                	jne    107d56 <memset+0x12>
		return v;
  107d51:	8b 45 08             	mov    0x8(%ebp),%eax
  107d54:	eb 5c                	jmp    107db2 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  107d56:	8b 45 08             	mov    0x8(%ebp),%eax
  107d59:	83 e0 03             	and    $0x3,%eax
  107d5c:	85 c0                	test   %eax,%eax
  107d5e:	75 41                	jne    107da1 <memset+0x5d>
  107d60:	8b 45 10             	mov    0x10(%ebp),%eax
  107d63:	83 e0 03             	and    $0x3,%eax
  107d66:	85 c0                	test   %eax,%eax
  107d68:	75 37                	jne    107da1 <memset+0x5d>
		c &= 0xFF;
  107d6a:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  107d71:	8b 45 0c             	mov    0xc(%ebp),%eax
  107d74:	89 c2                	mov    %eax,%edx
  107d76:	c1 e2 18             	shl    $0x18,%edx
  107d79:	8b 45 0c             	mov    0xc(%ebp),%eax
  107d7c:	c1 e0 10             	shl    $0x10,%eax
  107d7f:	09 c2                	or     %eax,%edx
  107d81:	8b 45 0c             	mov    0xc(%ebp),%eax
  107d84:	c1 e0 08             	shl    $0x8,%eax
  107d87:	09 d0                	or     %edx,%eax
  107d89:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  107d8c:	8b 45 10             	mov    0x10(%ebp),%eax
  107d8f:	89 c1                	mov    %eax,%ecx
  107d91:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  107d94:	8b 55 08             	mov    0x8(%ebp),%edx
  107d97:	8b 45 0c             	mov    0xc(%ebp),%eax
  107d9a:	89 d7                	mov    %edx,%edi
  107d9c:	fc                   	cld    
  107d9d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  107d9f:	eb 0e                	jmp    107daf <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  107da1:	8b 55 08             	mov    0x8(%ebp),%edx
  107da4:	8b 45 0c             	mov    0xc(%ebp),%eax
  107da7:	8b 4d 10             	mov    0x10(%ebp),%ecx
  107daa:	89 d7                	mov    %edx,%edi
  107dac:	fc                   	cld    
  107dad:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  107daf:	8b 45 08             	mov    0x8(%ebp),%eax
}
  107db2:	83 c4 10             	add    $0x10,%esp
  107db5:	5f                   	pop    %edi
  107db6:	5d                   	pop    %ebp
  107db7:	c3                   	ret    

00107db8 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  107db8:	55                   	push   %ebp
  107db9:	89 e5                	mov    %esp,%ebp
  107dbb:	57                   	push   %edi
  107dbc:	56                   	push   %esi
  107dbd:	53                   	push   %ebx
  107dbe:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  107dc1:	8b 45 0c             	mov    0xc(%ebp),%eax
  107dc4:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  107dc7:	8b 45 08             	mov    0x8(%ebp),%eax
  107dca:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  107dcd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107dd0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  107dd3:	73 6e                	jae    107e43 <memmove+0x8b>
  107dd5:	8b 45 10             	mov    0x10(%ebp),%eax
  107dd8:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107ddb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107dde:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  107de1:	76 60                	jbe    107e43 <memmove+0x8b>
		s += n;
  107de3:	8b 45 10             	mov    0x10(%ebp),%eax
  107de6:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  107de9:	8b 45 10             	mov    0x10(%ebp),%eax
  107dec:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107def:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107df2:	83 e0 03             	and    $0x3,%eax
  107df5:	85 c0                	test   %eax,%eax
  107df7:	75 2f                	jne    107e28 <memmove+0x70>
  107df9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107dfc:	83 e0 03             	and    $0x3,%eax
  107dff:	85 c0                	test   %eax,%eax
  107e01:	75 25                	jne    107e28 <memmove+0x70>
  107e03:	8b 45 10             	mov    0x10(%ebp),%eax
  107e06:	83 e0 03             	and    $0x3,%eax
  107e09:	85 c0                	test   %eax,%eax
  107e0b:	75 1b                	jne    107e28 <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  107e0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107e10:	83 e8 04             	sub    $0x4,%eax
  107e13:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107e16:	83 ea 04             	sub    $0x4,%edx
  107e19:	8b 4d 10             	mov    0x10(%ebp),%ecx
  107e1c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  107e1f:	89 c7                	mov    %eax,%edi
  107e21:	89 d6                	mov    %edx,%esi
  107e23:	fd                   	std    
  107e24:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107e26:	eb 18                	jmp    107e40 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  107e28:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107e2b:	8d 50 ff             	lea    -0x1(%eax),%edx
  107e2e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107e31:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  107e34:	8b 45 10             	mov    0x10(%ebp),%eax
  107e37:	89 d7                	mov    %edx,%edi
  107e39:	89 de                	mov    %ebx,%esi
  107e3b:	89 c1                	mov    %eax,%ecx
  107e3d:	fd                   	std    
  107e3e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  107e40:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  107e41:	eb 45                	jmp    107e88 <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107e43:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107e46:	83 e0 03             	and    $0x3,%eax
  107e49:	85 c0                	test   %eax,%eax
  107e4b:	75 2b                	jne    107e78 <memmove+0xc0>
  107e4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107e50:	83 e0 03             	and    $0x3,%eax
  107e53:	85 c0                	test   %eax,%eax
  107e55:	75 21                	jne    107e78 <memmove+0xc0>
  107e57:	8b 45 10             	mov    0x10(%ebp),%eax
  107e5a:	83 e0 03             	and    $0x3,%eax
  107e5d:	85 c0                	test   %eax,%eax
  107e5f:	75 17                	jne    107e78 <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  107e61:	8b 45 10             	mov    0x10(%ebp),%eax
  107e64:	89 c1                	mov    %eax,%ecx
  107e66:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  107e69:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107e6c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107e6f:	89 c7                	mov    %eax,%edi
  107e71:	89 d6                	mov    %edx,%esi
  107e73:	fc                   	cld    
  107e74:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107e76:	eb 10                	jmp    107e88 <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  107e78:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107e7b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107e7e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  107e81:	89 c7                	mov    %eax,%edi
  107e83:	89 d6                	mov    %edx,%esi
  107e85:	fc                   	cld    
  107e86:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  107e88:	8b 45 08             	mov    0x8(%ebp),%eax
}
  107e8b:	83 c4 10             	add    $0x10,%esp
  107e8e:	5b                   	pop    %ebx
  107e8f:	5e                   	pop    %esi
  107e90:	5f                   	pop    %edi
  107e91:	5d                   	pop    %ebp
  107e92:	c3                   	ret    

00107e93 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  107e93:	55                   	push   %ebp
  107e94:	89 e5                	mov    %esp,%ebp
  107e96:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  107e99:	8b 45 10             	mov    0x10(%ebp),%eax
  107e9c:	89 44 24 08          	mov    %eax,0x8(%esp)
  107ea0:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ea3:	89 44 24 04          	mov    %eax,0x4(%esp)
  107ea7:	8b 45 08             	mov    0x8(%ebp),%eax
  107eaa:	89 04 24             	mov    %eax,(%esp)
  107ead:	e8 06 ff ff ff       	call   107db8 <memmove>
}
  107eb2:	c9                   	leave  
  107eb3:	c3                   	ret    

00107eb4 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  107eb4:	55                   	push   %ebp
  107eb5:	89 e5                	mov    %esp,%ebp
  107eb7:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  107eba:	8b 45 08             	mov    0x8(%ebp),%eax
  107ebd:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  107ec0:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ec3:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  107ec6:	eb 32                	jmp    107efa <memcmp+0x46>
		if (*s1 != *s2)
  107ec8:	8b 45 f8             	mov    -0x8(%ebp),%eax
  107ecb:	0f b6 10             	movzbl (%eax),%edx
  107ece:	8b 45 fc             	mov    -0x4(%ebp),%eax
  107ed1:	0f b6 00             	movzbl (%eax),%eax
  107ed4:	38 c2                	cmp    %al,%dl
  107ed6:	74 1a                	je     107ef2 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  107ed8:	8b 45 f8             	mov    -0x8(%ebp),%eax
  107edb:	0f b6 00             	movzbl (%eax),%eax
  107ede:	0f b6 d0             	movzbl %al,%edx
  107ee1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  107ee4:	0f b6 00             	movzbl (%eax),%eax
  107ee7:	0f b6 c0             	movzbl %al,%eax
  107eea:	89 d1                	mov    %edx,%ecx
  107eec:	29 c1                	sub    %eax,%ecx
  107eee:	89 c8                	mov    %ecx,%eax
  107ef0:	eb 1c                	jmp    107f0e <memcmp+0x5a>
		s1++, s2++;
  107ef2:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  107ef6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  107efa:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107efe:	0f 95 c0             	setne  %al
  107f01:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107f05:	84 c0                	test   %al,%al
  107f07:	75 bf                	jne    107ec8 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  107f09:	b8 00 00 00 00       	mov    $0x0,%eax
}
  107f0e:	c9                   	leave  
  107f0f:	c3                   	ret    

00107f10 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  107f10:	55                   	push   %ebp
  107f11:	89 e5                	mov    %esp,%ebp
  107f13:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  107f16:	8b 45 10             	mov    0x10(%ebp),%eax
  107f19:	8b 55 08             	mov    0x8(%ebp),%edx
  107f1c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107f1f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  107f22:	eb 16                	jmp    107f3a <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  107f24:	8b 45 08             	mov    0x8(%ebp),%eax
  107f27:	0f b6 10             	movzbl (%eax),%edx
  107f2a:	8b 45 0c             	mov    0xc(%ebp),%eax
  107f2d:	38 c2                	cmp    %al,%dl
  107f2f:	75 05                	jne    107f36 <memchr+0x26>
			return (void *) s;
  107f31:	8b 45 08             	mov    0x8(%ebp),%eax
  107f34:	eb 11                	jmp    107f47 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  107f36:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107f3a:	8b 45 08             	mov    0x8(%ebp),%eax
  107f3d:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  107f40:	72 e2                	jb     107f24 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  107f42:	b8 00 00 00 00       	mov    $0x0,%eax
}
  107f47:	c9                   	leave  
  107f48:	c3                   	ret    
  107f49:	66 90                	xchg   %ax,%ax
  107f4b:	66 90                	xchg   %ax,%ax
  107f4d:	66 90                	xchg   %ax,%ax
  107f4f:	90                   	nop

00107f50 <__udivdi3>:
  107f50:	55                   	push   %ebp
  107f51:	89 e5                	mov    %esp,%ebp
  107f53:	57                   	push   %edi
  107f54:	56                   	push   %esi
  107f55:	83 ec 10             	sub    $0x10,%esp
  107f58:	8b 45 14             	mov    0x14(%ebp),%eax
  107f5b:	8b 55 08             	mov    0x8(%ebp),%edx
  107f5e:	8b 75 10             	mov    0x10(%ebp),%esi
  107f61:	8b 7d 0c             	mov    0xc(%ebp),%edi
  107f64:	85 c0                	test   %eax,%eax
  107f66:	89 55 f0             	mov    %edx,-0x10(%ebp)
  107f69:	75 35                	jne    107fa0 <__udivdi3+0x50>
  107f6b:	39 fe                	cmp    %edi,%esi
  107f6d:	77 61                	ja     107fd0 <__udivdi3+0x80>
  107f6f:	85 f6                	test   %esi,%esi
  107f71:	75 0b                	jne    107f7e <__udivdi3+0x2e>
  107f73:	b8 01 00 00 00       	mov    $0x1,%eax
  107f78:	31 d2                	xor    %edx,%edx
  107f7a:	f7 f6                	div    %esi
  107f7c:	89 c6                	mov    %eax,%esi
  107f7e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  107f81:	31 d2                	xor    %edx,%edx
  107f83:	89 f8                	mov    %edi,%eax
  107f85:	f7 f6                	div    %esi
  107f87:	89 c7                	mov    %eax,%edi
  107f89:	89 c8                	mov    %ecx,%eax
  107f8b:	f7 f6                	div    %esi
  107f8d:	89 c1                	mov    %eax,%ecx
  107f8f:	89 fa                	mov    %edi,%edx
  107f91:	89 c8                	mov    %ecx,%eax
  107f93:	83 c4 10             	add    $0x10,%esp
  107f96:	5e                   	pop    %esi
  107f97:	5f                   	pop    %edi
  107f98:	5d                   	pop    %ebp
  107f99:	c3                   	ret    
  107f9a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  107fa0:	39 f8                	cmp    %edi,%eax
  107fa2:	77 1c                	ja     107fc0 <__udivdi3+0x70>
  107fa4:	0f bd d0             	bsr    %eax,%edx
  107fa7:	83 f2 1f             	xor    $0x1f,%edx
  107faa:	89 55 f4             	mov    %edx,-0xc(%ebp)
  107fad:	75 39                	jne    107fe8 <__udivdi3+0x98>
  107faf:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  107fb2:	0f 86 a0 00 00 00    	jbe    108058 <__udivdi3+0x108>
  107fb8:	39 f8                	cmp    %edi,%eax
  107fba:	0f 82 98 00 00 00    	jb     108058 <__udivdi3+0x108>
  107fc0:	31 ff                	xor    %edi,%edi
  107fc2:	31 c9                	xor    %ecx,%ecx
  107fc4:	89 c8                	mov    %ecx,%eax
  107fc6:	89 fa                	mov    %edi,%edx
  107fc8:	83 c4 10             	add    $0x10,%esp
  107fcb:	5e                   	pop    %esi
  107fcc:	5f                   	pop    %edi
  107fcd:	5d                   	pop    %ebp
  107fce:	c3                   	ret    
  107fcf:	90                   	nop
  107fd0:	89 d1                	mov    %edx,%ecx
  107fd2:	89 fa                	mov    %edi,%edx
  107fd4:	89 c8                	mov    %ecx,%eax
  107fd6:	31 ff                	xor    %edi,%edi
  107fd8:	f7 f6                	div    %esi
  107fda:	89 c1                	mov    %eax,%ecx
  107fdc:	89 fa                	mov    %edi,%edx
  107fde:	89 c8                	mov    %ecx,%eax
  107fe0:	83 c4 10             	add    $0x10,%esp
  107fe3:	5e                   	pop    %esi
  107fe4:	5f                   	pop    %edi
  107fe5:	5d                   	pop    %ebp
  107fe6:	c3                   	ret    
  107fe7:	90                   	nop
  107fe8:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  107fec:	89 f2                	mov    %esi,%edx
  107fee:	d3 e0                	shl    %cl,%eax
  107ff0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  107ff3:	b8 20 00 00 00       	mov    $0x20,%eax
  107ff8:	2b 45 f4             	sub    -0xc(%ebp),%eax
  107ffb:	89 c1                	mov    %eax,%ecx
  107ffd:	d3 ea                	shr    %cl,%edx
  107fff:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  108003:	0b 55 ec             	or     -0x14(%ebp),%edx
  108006:	d3 e6                	shl    %cl,%esi
  108008:	89 c1                	mov    %eax,%ecx
  10800a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  10800d:	89 fe                	mov    %edi,%esi
  10800f:	d3 ee                	shr    %cl,%esi
  108011:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  108015:	89 55 ec             	mov    %edx,-0x14(%ebp)
  108018:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10801b:	d3 e7                	shl    %cl,%edi
  10801d:	89 c1                	mov    %eax,%ecx
  10801f:	d3 ea                	shr    %cl,%edx
  108021:	09 d7                	or     %edx,%edi
  108023:	89 f2                	mov    %esi,%edx
  108025:	89 f8                	mov    %edi,%eax
  108027:	f7 75 ec             	divl   -0x14(%ebp)
  10802a:	89 d6                	mov    %edx,%esi
  10802c:	89 c7                	mov    %eax,%edi
  10802e:	f7 65 e8             	mull   -0x18(%ebp)
  108031:	39 d6                	cmp    %edx,%esi
  108033:	89 55 ec             	mov    %edx,-0x14(%ebp)
  108036:	72 30                	jb     108068 <__udivdi3+0x118>
  108038:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10803b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10803f:	d3 e2                	shl    %cl,%edx
  108041:	39 c2                	cmp    %eax,%edx
  108043:	73 05                	jae    10804a <__udivdi3+0xfa>
  108045:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  108048:	74 1e                	je     108068 <__udivdi3+0x118>
  10804a:	89 f9                	mov    %edi,%ecx
  10804c:	31 ff                	xor    %edi,%edi
  10804e:	e9 71 ff ff ff       	jmp    107fc4 <__udivdi3+0x74>
  108053:	90                   	nop
  108054:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108058:	31 ff                	xor    %edi,%edi
  10805a:	b9 01 00 00 00       	mov    $0x1,%ecx
  10805f:	e9 60 ff ff ff       	jmp    107fc4 <__udivdi3+0x74>
  108064:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108068:	8d 4f ff             	lea    -0x1(%edi),%ecx
  10806b:	31 ff                	xor    %edi,%edi
  10806d:	89 c8                	mov    %ecx,%eax
  10806f:	89 fa                	mov    %edi,%edx
  108071:	83 c4 10             	add    $0x10,%esp
  108074:	5e                   	pop    %esi
  108075:	5f                   	pop    %edi
  108076:	5d                   	pop    %ebp
  108077:	c3                   	ret    
  108078:	66 90                	xchg   %ax,%ax
  10807a:	66 90                	xchg   %ax,%ax
  10807c:	66 90                	xchg   %ax,%ax
  10807e:	66 90                	xchg   %ax,%ax

00108080 <__umoddi3>:
  108080:	55                   	push   %ebp
  108081:	89 e5                	mov    %esp,%ebp
  108083:	57                   	push   %edi
  108084:	56                   	push   %esi
  108085:	83 ec 20             	sub    $0x20,%esp
  108088:	8b 55 14             	mov    0x14(%ebp),%edx
  10808b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10808e:	8b 7d 10             	mov    0x10(%ebp),%edi
  108091:	8b 75 0c             	mov    0xc(%ebp),%esi
  108094:	85 d2                	test   %edx,%edx
  108096:	89 c8                	mov    %ecx,%eax
  108098:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  10809b:	75 13                	jne    1080b0 <__umoddi3+0x30>
  10809d:	39 f7                	cmp    %esi,%edi
  10809f:	76 3f                	jbe    1080e0 <__umoddi3+0x60>
  1080a1:	89 f2                	mov    %esi,%edx
  1080a3:	f7 f7                	div    %edi
  1080a5:	89 d0                	mov    %edx,%eax
  1080a7:	31 d2                	xor    %edx,%edx
  1080a9:	83 c4 20             	add    $0x20,%esp
  1080ac:	5e                   	pop    %esi
  1080ad:	5f                   	pop    %edi
  1080ae:	5d                   	pop    %ebp
  1080af:	c3                   	ret    
  1080b0:	39 f2                	cmp    %esi,%edx
  1080b2:	77 4c                	ja     108100 <__umoddi3+0x80>
  1080b4:	0f bd ca             	bsr    %edx,%ecx
  1080b7:	83 f1 1f             	xor    $0x1f,%ecx
  1080ba:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  1080bd:	75 51                	jne    108110 <__umoddi3+0x90>
  1080bf:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  1080c2:	0f 87 e0 00 00 00    	ja     1081a8 <__umoddi3+0x128>
  1080c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1080cb:	29 f8                	sub    %edi,%eax
  1080cd:	19 d6                	sbb    %edx,%esi
  1080cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1080d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1080d5:	89 f2                	mov    %esi,%edx
  1080d7:	83 c4 20             	add    $0x20,%esp
  1080da:	5e                   	pop    %esi
  1080db:	5f                   	pop    %edi
  1080dc:	5d                   	pop    %ebp
  1080dd:	c3                   	ret    
  1080de:	66 90                	xchg   %ax,%ax
  1080e0:	85 ff                	test   %edi,%edi
  1080e2:	75 0b                	jne    1080ef <__umoddi3+0x6f>
  1080e4:	b8 01 00 00 00       	mov    $0x1,%eax
  1080e9:	31 d2                	xor    %edx,%edx
  1080eb:	f7 f7                	div    %edi
  1080ed:	89 c7                	mov    %eax,%edi
  1080ef:	89 f0                	mov    %esi,%eax
  1080f1:	31 d2                	xor    %edx,%edx
  1080f3:	f7 f7                	div    %edi
  1080f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1080f8:	f7 f7                	div    %edi
  1080fa:	eb a9                	jmp    1080a5 <__umoddi3+0x25>
  1080fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108100:	89 c8                	mov    %ecx,%eax
  108102:	89 f2                	mov    %esi,%edx
  108104:	83 c4 20             	add    $0x20,%esp
  108107:	5e                   	pop    %esi
  108108:	5f                   	pop    %edi
  108109:	5d                   	pop    %ebp
  10810a:	c3                   	ret    
  10810b:	90                   	nop
  10810c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108110:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108114:	d3 e2                	shl    %cl,%edx
  108116:	89 55 f4             	mov    %edx,-0xc(%ebp)
  108119:	ba 20 00 00 00       	mov    $0x20,%edx
  10811e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  108121:	89 55 ec             	mov    %edx,-0x14(%ebp)
  108124:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108128:	89 fa                	mov    %edi,%edx
  10812a:	d3 ea                	shr    %cl,%edx
  10812c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108130:	0b 55 f4             	or     -0xc(%ebp),%edx
  108133:	d3 e7                	shl    %cl,%edi
  108135:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108139:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10813c:	89 f2                	mov    %esi,%edx
  10813e:	89 7d e8             	mov    %edi,-0x18(%ebp)
  108141:	89 c7                	mov    %eax,%edi
  108143:	d3 ea                	shr    %cl,%edx
  108145:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108149:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10814c:	89 c2                	mov    %eax,%edx
  10814e:	d3 e6                	shl    %cl,%esi
  108150:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108154:	d3 ea                	shr    %cl,%edx
  108156:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10815a:	09 d6                	or     %edx,%esi
  10815c:	89 f0                	mov    %esi,%eax
  10815e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  108161:	d3 e7                	shl    %cl,%edi
  108163:	89 f2                	mov    %esi,%edx
  108165:	f7 75 f4             	divl   -0xc(%ebp)
  108168:	89 d6                	mov    %edx,%esi
  10816a:	f7 65 e8             	mull   -0x18(%ebp)
  10816d:	39 d6                	cmp    %edx,%esi
  10816f:	72 2b                	jb     10819c <__umoddi3+0x11c>
  108171:	39 c7                	cmp    %eax,%edi
  108173:	72 23                	jb     108198 <__umoddi3+0x118>
  108175:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108179:	29 c7                	sub    %eax,%edi
  10817b:	19 d6                	sbb    %edx,%esi
  10817d:	89 f0                	mov    %esi,%eax
  10817f:	89 f2                	mov    %esi,%edx
  108181:	d3 ef                	shr    %cl,%edi
  108183:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108187:	d3 e0                	shl    %cl,%eax
  108189:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10818d:	09 f8                	or     %edi,%eax
  10818f:	d3 ea                	shr    %cl,%edx
  108191:	83 c4 20             	add    $0x20,%esp
  108194:	5e                   	pop    %esi
  108195:	5f                   	pop    %edi
  108196:	5d                   	pop    %ebp
  108197:	c3                   	ret    
  108198:	39 d6                	cmp    %edx,%esi
  10819a:	75 d9                	jne    108175 <__umoddi3+0xf5>
  10819c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  10819f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  1081a2:	eb d1                	jmp    108175 <__umoddi3+0xf5>
  1081a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1081a8:	39 f2                	cmp    %esi,%edx
  1081aa:	0f 82 18 ff ff ff    	jb     1080c8 <__umoddi3+0x48>
  1081b0:	e9 1d ff ff ff       	jmp    1080d2 <__umoddi3+0x52>
