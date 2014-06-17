
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
  10001a:	bc 00 80 10 00       	mov    $0x108000,%esp

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
  100050:	c7 44 24 0c 60 58 10 	movl   $0x105860,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 76 58 10 	movl   $0x105876,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 8b 58 10 00 	movl   $0x10588b,(%esp)
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
  100084:	3d 00 70 10 00       	cmp    $0x107000,%eax
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
  1000a1:	ba 10 eb 30 00       	mov    $0x30eb10,%edx
  1000a6:	b8 9c 86 10 00       	mov    $0x10869c,%eax
  1000ab:	89 d1                	mov    %edx,%ecx
  1000ad:	29 c1                	sub    %eax,%ecx
  1000af:	89 c8                	mov    %ecx,%eax
  1000b1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bc:	00 
  1000bd:	c7 04 24 9c 86 10 00 	movl   $0x10869c,(%esp)
  1000c4:	e8 0b 53 00 00       	call   1053d4 <memset>
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

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000eb:	e8 f1 1f 00 00       	call   1020e1 <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000f0:	e8 e7 41 00 00       	call   1042dc <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000f5:	e8 15 48 00 00       	call   10490f <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000fa:	e8 c0 44 00 00       	call   1045bf <lapic_init>
		// Initialize the process management code.
	proc_init();
  1000ff:	e8 88 29 00 00       	call   102a8c <proc_init>
	cpu_bootothers();	// Get other processors started
  100104:	e8 ca 11 00 00       	call   1012d3 <cpu_bootothers>
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
		cpu_onboot() ? "BP" : "AP");
  100109:	e8 6b ff ff ff       	call   100079 <cpu_onboot>
	ioapic_init();		// prepare to handle external device interrupts
	lapic_init();		// setup this CPU's local APIC
		// Initialize the process management code.
	proc_init();
	cpu_bootothers();	// Get other processors started
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
  10010e:	85 c0                	test   %eax,%eax
  100110:	74 07                	je     100119 <init+0x88>
  100112:	bb 98 58 10 00       	mov    $0x105898,%ebx
  100117:	eb 05                	jmp    10011e <init+0x8d>
  100119:	bb 9b 58 10 00       	mov    $0x10589b,%ebx
  10011e:	e8 03 ff ff ff       	call   100026 <cpu_cur>
  100123:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10012a:	0f b6 c0             	movzbl %al,%eax
  10012d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  100131:	89 44 24 04          	mov    %eax,0x4(%esp)
  100135:	c7 04 24 9e 58 10 00 	movl   $0x10589e,(%esp)
  10013c:	e8 ae 50 00 00       	call   1051ef <cprintf>
	};
	
	trap_return(&tt);
	*/

	if(cpu_onboot()){
  100141:	e8 33 ff ff ff       	call   100079 <cpu_onboot>
  100146:	85 c0                	test   %eax,%eax
  100148:	74 71                	je     1001bb <init+0x12a>
		proc_root = proc_alloc(&proc_null, 0);
  10014a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100151:	00 
  100152:	c7 04 24 20 e4 30 00 	movl   $0x30e420,(%esp)
  100159:	e8 7c 29 00 00       	call   102ada <proc_alloc>
  10015e:	a3 04 eb 30 00       	mov    %eax,0x30eb04
		proc_root->sv.tf.eip = (uint32_t)(user);
  100163:	a1 04 eb 30 00       	mov    0x30eb04,%eax
  100168:	ba c0 01 10 00       	mov    $0x1001c0,%edx
  10016d:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_root->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
  100173:	a1 04 eb 30 00       	mov    0x30eb04,%eax
  100178:	ba a0 96 10 00       	mov    $0x1096a0,%edx
  10017d:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		//proc_root->sv.tf.eflags = FL_IOPL_3;
		proc_root->sv.tf.eflags = FL_IF;
  100183:	a1 04 eb 30 00       	mov    0x30eb04,%eax
  100188:	c7 80 90 04 00 00 00 	movl   $0x200,0x490(%eax)
  10018f:	02 00 00 
		proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
  100192:	a1 04 eb 30 00       	mov    0x30eb04,%eax
  100197:	66 c7 80 70 04 00 00 	movw   $0x23,0x470(%eax)
  10019e:	23 00 
		proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;
  1001a0:	a1 04 eb 30 00       	mov    0x30eb04,%eax
  1001a5:	66 c7 80 74 04 00 00 	movw   $0x23,0x474(%eax)
  1001ac:	23 00 

		proc_ready(proc_root);	
  1001ae:	a1 04 eb 30 00       	mov    0x30eb04,%eax
  1001b3:	89 04 24             	mov    %eax,(%esp)
  1001b6:	e8 be 2a 00 00       	call   102c79 <proc_ready>
	}

	
	proc_sched();
  1001bb:	e8 11 2d 00 00       	call   102ed1 <proc_sched>

001001c0 <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1001c0:	55                   	push   %ebp
  1001c1:	89 e5                	mov    %esp,%ebp
  1001c3:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  1001c6:	c7 04 24 b6 58 10 00 	movl   $0x1058b6,(%esp)
  1001cd:	e8 1d 50 00 00       	call   1051ef <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001d2:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  1001d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  1001d8:	89 c2                	mov    %eax,%edx
  1001da:	b8 a0 86 10 00       	mov    $0x1086a0,%eax
  1001df:	39 c2                	cmp    %eax,%edx
  1001e1:	77 24                	ja     100207 <user+0x47>
  1001e3:	c7 44 24 0c c4 58 10 	movl   $0x1058c4,0xc(%esp)
  1001ea:	00 
  1001eb:	c7 44 24 08 76 58 10 	movl   $0x105876,0x8(%esp)
  1001f2:	00 
  1001f3:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  1001fa:	00 
  1001fb:	c7 04 24 eb 58 10 00 	movl   $0x1058eb,(%esp)
  100202:	e8 7a 02 00 00       	call   100481 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100207:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10020a:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  10020d:	89 c2                	mov    %eax,%edx
  10020f:	b8 a0 96 10 00       	mov    $0x1096a0,%eax
  100214:	39 c2                	cmp    %eax,%edx
  100216:	72 24                	jb     10023c <user+0x7c>
  100218:	c7 44 24 0c f8 58 10 	movl   $0x1058f8,0xc(%esp)
  10021f:	00 
  100220:	c7 44 24 08 76 58 10 	movl   $0x105876,0x8(%esp)
  100227:	00 
  100228:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  10022f:	00 
  100230:	c7 04 24 eb 58 10 00 	movl   $0x1058eb,(%esp)
  100237:	e8 45 02 00 00       	call   100481 <debug_panic>

	// Check the system call and process scheduling code.
	proc_check();
  10023c:	e8 f4 2e 00 00       	call   103135 <proc_check>

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
  100275:	c7 44 24 0c 30 59 10 	movl   $0x105930,0xc(%esp)
  10027c:	00 
  10027d:	c7 44 24 08 46 59 10 	movl   $0x105946,0x8(%esp)
  100284:	00 
  100285:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10028c:	00 
  10028d:	c7 04 24 5b 59 10 00 	movl   $0x10595b,(%esp)
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
  1002a9:	3d 00 70 10 00       	cmp    $0x107000,%eax
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
  1002bc:	c7 04 24 60 e3 10 00 	movl   $0x10e360,(%esp)
  1002c3:	e8 45 20 00 00       	call   10230d <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  1002c8:	eb 35                	jmp    1002ff <cons_intr+0x49>
		if (c == 0)
  1002ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1002ce:	74 2e                	je     1002fe <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  1002d0:	a1 a4 98 10 00       	mov    0x1098a4,%eax
  1002d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1002d8:	88 90 a0 96 10 00    	mov    %dl,0x1096a0(%eax)
  1002de:	83 c0 01             	add    $0x1,%eax
  1002e1:	a3 a4 98 10 00       	mov    %eax,0x1098a4
		if (cons.wpos == CONSBUFSIZE)
  1002e6:	a1 a4 98 10 00       	mov    0x1098a4,%eax
  1002eb:	3d 00 02 00 00       	cmp    $0x200,%eax
  1002f0:	75 0d                	jne    1002ff <cons_intr+0x49>
			cons.wpos = 0;
  1002f2:	c7 05 a4 98 10 00 00 	movl   $0x0,0x1098a4
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
  10030d:	c7 04 24 60 e3 10 00 	movl   $0x10e360,(%esp)
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
  100321:	e8 66 3e 00 00       	call   10418c <serial_intr>
	kbd_intr();
  100326:	e8 bc 3d 00 00       	call   1040e7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  10032b:	8b 15 a0 98 10 00    	mov    0x1098a0,%edx
  100331:	a1 a4 98 10 00       	mov    0x1098a4,%eax
  100336:	39 c2                	cmp    %eax,%edx
  100338:	74 35                	je     10036f <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  10033a:	a1 a0 98 10 00       	mov    0x1098a0,%eax
  10033f:	0f b6 90 a0 96 10 00 	movzbl 0x1096a0(%eax),%edx
  100346:	0f b6 d2             	movzbl %dl,%edx
  100349:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10034c:	83 c0 01             	add    $0x1,%eax
  10034f:	a3 a0 98 10 00       	mov    %eax,0x1098a0
		if (cons.rpos == CONSBUFSIZE)
  100354:	a1 a0 98 10 00       	mov    0x1098a0,%eax
  100359:	3d 00 02 00 00       	cmp    $0x200,%eax
  10035e:	75 0a                	jne    10036a <cons_getc+0x4f>
			cons.rpos = 0;
  100360:	c7 05 a0 98 10 00 00 	movl   $0x0,0x1098a0
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
  100382:	e8 22 3e 00 00       	call   1041a9 <serial_putc>
	video_putc(c);
  100387:	8b 45 08             	mov    0x8(%ebp),%eax
  10038a:	89 04 24             	mov    %eax,(%esp)
  10038d:	e8 b4 39 00 00       	call   103d46 <video_putc>
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
  1003ab:	c7 44 24 04 68 59 10 	movl   $0x105968,0x4(%esp)
  1003b2:	00 
  1003b3:	c7 04 24 60 e3 10 00 	movl   $0x10e360,(%esp)
  1003ba:	e8 1a 1f 00 00       	call   1022d9 <spinlock_init_>
	video_init();
  1003bf:	e8 b6 38 00 00       	call   103c7a <video_init>
	kbd_init();
  1003c4:	e8 32 3d 00 00       	call   1040fb <kbd_init>
	serial_init();
  1003c9:	e8 40 3e 00 00       	call   10420e <serial_init>

	if (!serial_exists)
  1003ce:	a1 08 eb 30 00       	mov    0x30eb08,%eax
  1003d3:	85 c0                	test   %eax,%eax
  1003d5:	75 1f                	jne    1003f6 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  1003d7:	c7 44 24 08 74 59 10 	movl   $0x105974,0x8(%esp)
  1003de:	00 
  1003df:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  1003e6:	00 
  1003e7:	c7 04 24 68 59 10 00 	movl   $0x105968,(%esp)
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
  100424:	c7 04 24 60 e3 10 00 	movl   $0x10e360,(%esp)
  10042b:	e8 a4 1f 00 00       	call   1023d4 <spinlock_holding>
  100430:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!already)
  100433:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100437:	75 25                	jne    10045e <cputs+0x66>
		spinlock_acquire(&cons_lock);
  100439:	c7 04 24 60 e3 10 00 	movl   $0x10e360,(%esp)
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
  10046f:	c7 04 24 60 e3 10 00 	movl   $0x10e360,(%esp)
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
  100498:	a1 a8 98 10 00       	mov    0x1098a8,%eax
  10049d:	85 c0                	test   %eax,%eax
  10049f:	0f 85 95 00 00 00    	jne    10053a <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  1004a5:	8b 45 10             	mov    0x10(%ebp),%eax
  1004a8:	a3 a8 98 10 00       	mov    %eax,0x1098a8
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
  1004c4:	c7 04 24 91 59 10 00 	movl   $0x105991,(%esp)
  1004cb:	e8 1f 4d 00 00       	call   1051ef <cprintf>
	vcprintf(fmt, ap);
  1004d0:	8b 45 10             	mov    0x10(%ebp),%eax
  1004d3:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1004d6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1004da:	89 04 24             	mov    %eax,(%esp)
  1004dd:	e8 a4 4c 00 00       	call   105186 <vcprintf>
	cprintf("\n");
  1004e2:	c7 04 24 a9 59 10 00 	movl   $0x1059a9,(%esp)
  1004e9:	e8 01 4d 00 00       	call   1051ef <cprintf>

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
  100517:	c7 04 24 ab 59 10 00 	movl   $0x1059ab,(%esp)
  10051e:	e8 cc 4c 00 00       	call   1051ef <cprintf>
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
  10055d:	c7 04 24 b8 59 10 00 	movl   $0x1059b8,(%esp)
  100564:	e8 86 4c 00 00       	call   1051ef <cprintf>
	vcprintf(fmt, ap);
  100569:	8b 45 10             	mov    0x10(%ebp),%eax
  10056c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10056f:	89 54 24 04          	mov    %edx,0x4(%esp)
  100573:	89 04 24             	mov    %eax,(%esp)
  100576:	e8 0b 4c 00 00       	call   105186 <vcprintf>
	cprintf("\n");
  10057b:	c7 04 24 a9 59 10 00 	movl   $0x1059a9,(%esp)
  100582:	e8 68 4c 00 00       	call   1051ef <cprintf>
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
  100709:	c7 44 24 0c d2 59 10 	movl   $0x1059d2,0xc(%esp)
  100710:	00 
  100711:	c7 44 24 08 ef 59 10 	movl   $0x1059ef,0x8(%esp)
  100718:	00 
  100719:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100720:	00 
  100721:	c7 04 24 04 5a 10 00 	movl   $0x105a04,(%esp)
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
  100759:	c7 44 24 0c 11 5a 10 	movl   $0x105a11,0xc(%esp)
  100760:	00 
  100761:	c7 44 24 08 ef 59 10 	movl   $0x1059ef,0x8(%esp)
  100768:	00 
  100769:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  100770:	00 
  100771:	c7 04 24 04 5a 10 00 	movl   $0x105a04,(%esp)
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
  1007a9:	c7 44 24 0c 2a 5a 10 	movl   $0x105a2a,0xc(%esp)
  1007b0:	00 
  1007b1:	c7 44 24 08 ef 59 10 	movl   $0x1059ef,0x8(%esp)
  1007b8:	00 
  1007b9:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  1007c0:	00 
  1007c1:	c7 04 24 04 5a 10 00 	movl   $0x105a04,(%esp)
  1007c8:	e8 b4 fc ff ff       	call   100481 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1007cd:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1007d0:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1007d3:	39 c2                	cmp    %eax,%edx
  1007d5:	74 24                	je     1007fb <debug_check+0x175>
  1007d7:	c7 44 24 0c 43 5a 10 	movl   $0x105a43,0xc(%esp)
  1007de:	00 
  1007df:	c7 44 24 08 ef 59 10 	movl   $0x1059ef,0x8(%esp)
  1007e6:	00 
  1007e7:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  1007ee:	00 
  1007ef:	c7 04 24 04 5a 10 00 	movl   $0x105a04,(%esp)
  1007f6:	e8 86 fc ff ff       	call   100481 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  1007fb:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100801:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100804:	39 c2                	cmp    %eax,%edx
  100806:	75 24                	jne    10082c <debug_check+0x1a6>
  100808:	c7 44 24 0c 5c 5a 10 	movl   $0x105a5c,0xc(%esp)
  10080f:	00 
  100810:	c7 44 24 08 ef 59 10 	movl   $0x1059ef,0x8(%esp)
  100817:	00 
  100818:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  10081f:	00 
  100820:	c7 04 24 04 5a 10 00 	movl   $0x105a04,(%esp)
  100827:	e8 55 fc ff ff       	call   100481 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10082c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100832:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100835:	39 c2                	cmp    %eax,%edx
  100837:	74 24                	je     10085d <debug_check+0x1d7>
  100839:	c7 44 24 0c 75 5a 10 	movl   $0x105a75,0xc(%esp)
  100840:	00 
  100841:	c7 44 24 08 ef 59 10 	movl   $0x1059ef,0x8(%esp)
  100848:	00 
  100849:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100850:	00 
  100851:	c7 04 24 04 5a 10 00 	movl   $0x105a04,(%esp)
  100858:	e8 24 fc ff ff       	call   100481 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10085d:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100863:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100866:	39 c2                	cmp    %eax,%edx
  100868:	74 24                	je     10088e <debug_check+0x208>
  10086a:	c7 44 24 0c 8e 5a 10 	movl   $0x105a8e,0xc(%esp)
  100871:	00 
  100872:	c7 44 24 08 ef 59 10 	movl   $0x1059ef,0x8(%esp)
  100879:	00 
  10087a:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100881:	00 
  100882:	c7 04 24 04 5a 10 00 	movl   $0x105a04,(%esp)
  100889:	e8 f3 fb ff ff       	call   100481 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10088e:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100894:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  10089a:	39 c2                	cmp    %eax,%edx
  10089c:	75 24                	jne    1008c2 <debug_check+0x23c>
  10089e:	c7 44 24 0c a7 5a 10 	movl   $0x105aa7,0xc(%esp)
  1008a5:	00 
  1008a6:	c7 44 24 08 ef 59 10 	movl   $0x1059ef,0x8(%esp)
  1008ad:	00 
  1008ae:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  1008b5:	00 
  1008b6:	c7 04 24 04 5a 10 00 	movl   $0x105a04,(%esp)
  1008bd:	e8 bf fb ff ff       	call   100481 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1008c2:	c7 04 24 c0 5a 10 00 	movl   $0x105ac0,(%esp)
  1008c9:	e8 21 49 00 00       	call   1051ef <cprintf>
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
  1008fa:	c7 44 24 0c dc 5a 10 	movl   $0x105adc,0xc(%esp)
  100901:	00 
  100902:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100909:	00 
  10090a:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100911:	00 
  100912:	c7 04 24 07 5b 10 00 	movl   $0x105b07,(%esp)
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
  10092e:	3d 00 70 10 00       	cmp    $0x107000,%eax
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
  10094e:	c7 44 24 08 2d 00 00 	movl   $0x2d,0x8(%esp)
  100955:	00 
  100956:	c7 44 24 04 14 5b 10 	movl   $0x105b14,0x4(%esp)
  10095d:	00 
  10095e:	c7 04 24 c0 e3 30 00 	movl   $0x30e3c0,(%esp)
  100965:	e8 6f 19 00 00       	call   1022d9 <spinlock_init_>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  10096a:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100971:	e8 6f 3b 00 00       	call   1044e5 <nvram_read16>
  100976:	c1 e0 0a             	shl    $0xa,%eax
  100979:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10097c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10097f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100984:	89 45 dc             	mov    %eax,-0x24(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100987:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  10098e:	e8 52 3b 00 00       	call   1044e5 <nvram_read16>
  100993:	c1 e0 0a             	shl    $0xa,%eax
  100996:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100999:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10099c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1009a1:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  1009a4:	c7 44 24 08 20 5b 10 	movl   $0x105b20,0x8(%esp)
  1009ab:	00 
  1009ac:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
  1009b3:	00 
  1009b4:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  1009bb:	e8 80 fb ff ff       	call   100540 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1009c0:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1009c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009ca:	05 00 00 10 00       	add    $0x100000,%eax
  1009cf:	a3 a8 e3 10 00       	mov    %eax,0x10e3a8

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1009d4:	a1 a8 e3 10 00       	mov    0x10e3a8,%eax
  1009d9:	c1 e8 0c             	shr    $0xc,%eax
  1009dc:	a3 a4 e3 10 00       	mov    %eax,0x10e3a4

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  1009e1:	a1 a8 e3 10 00       	mov    0x10e3a8,%eax
  1009e6:	c1 e8 0a             	shr    $0xa,%eax
  1009e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009ed:	c7 04 24 40 5b 10 00 	movl   $0x105b40,(%esp)
  1009f4:	e8 f6 47 00 00       	call   1051ef <cprintf>
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
  100a0f:	c7 04 24 61 5b 10 00 	movl   $0x105b61,(%esp)
  100a16:	e8 d4 47 00 00       	call   1051ef <cprintf>


	extern char start[], end[];
	uint32_t page_start;
	
	pageinfo **freetail = &mem_freelist;
  100a1b:	c7 45 e8 a0 e3 10 00 	movl   $0x10e3a0,-0x18(%ebp)
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100a22:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100a29:	00 
  100a2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100a31:	00 
  100a32:	c7 04 24 c0 e3 10 00 	movl   $0x10e3c0,(%esp)
  100a39:	e8 96 49 00 00       	call   1053d4 <memset>
	mem_pageinfo = spc_for_pi;
  100a3e:	c7 05 f8 e3 30 00 c0 	movl   $0x10e3c0,0x30e3f8
  100a45:	e3 10 00 
	int i;
	for (i = 0; i < mem_npage; i++) {
  100a48:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100a4f:	e9 96 00 00 00       	jmp    100aea <mem_init+0x1af>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100a54:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
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
  100aad:	b8 10 eb 30 00       	mov    $0x30eb10,%eax
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
  100ab7:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
  100abc:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100abf:	c1 e2 03             	shl    $0x3,%edx
  100ac2:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100ac5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ac8:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100aca:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
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
  100aed:	a1 a4 e3 10 00       	mov    0x10e3a4,%eax
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
  100b13:	a1 a0 e3 10 00       	mov    0x10e3a0,%eax
  100b18:	85 c0                	test   %eax,%eax
  100b1a:	75 07                	jne    100b23 <mem_alloc+0x16>
		return NULL;
  100b1c:	b8 00 00 00 00       	mov    $0x0,%eax
  100b21:	eb 2f                	jmp    100b52 <mem_alloc+0x45>

	spinlock_acquire(&mem_spinlock);
  100b23:	c7 04 24 c0 e3 30 00 	movl   $0x30e3c0,(%esp)
  100b2a:	e8 de 17 00 00       	call   10230d <spinlock_acquire>
	pageinfo* r = mem_freelist;
  100b2f:	a1 a0 e3 10 00       	mov    0x10e3a0,%eax
  100b34:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = mem_freelist->free_next;
  100b37:	a1 a0 e3 10 00       	mov    0x10e3a0,%eax
  100b3c:	8b 00                	mov    (%eax),%eax
  100b3e:	a3 a0 e3 10 00       	mov    %eax,0x10e3a0
	spinlock_release(&mem_spinlock);
  100b43:	c7 04 24 c0 e3 30 00 	movl   $0x30e3c0,(%esp)
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
  100b60:	c7 44 24 08 80 5b 10 	movl   $0x105b80,0x8(%esp)
  100b67:	00 
  100b68:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  100b6f:	00 
  100b70:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100b77:	e8 05 f9 ff ff       	call   100481 <debug_panic>

	spinlock_acquire(&mem_spinlock);
  100b7c:	c7 04 24 c0 e3 30 00 	movl   $0x30e3c0,(%esp)
  100b83:	e8 85 17 00 00       	call   10230d <spinlock_acquire>
	pi->free_next = mem_freelist;
  100b88:	8b 15 a0 e3 10 00    	mov    0x10e3a0,%edx
  100b8e:	8b 45 08             	mov    0x8(%ebp),%eax
  100b91:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100b93:	8b 45 08             	mov    0x8(%ebp),%eax
  100b96:	a3 a0 e3 10 00       	mov    %eax,0x10e3a0
	spinlock_release(&mem_spinlock);
  100b9b:	c7 04 24 c0 e3 30 00 	movl   $0x30e3c0,(%esp)
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
  100bb6:	a1 a0 e3 10 00       	mov    0x10e3a0,%eax
  100bbb:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100bbe:	eb 38                	jmp    100bf8 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100bc0:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100bc3:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
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
  100be7:	e8 e8 47 00 00       	call   1053d4 <memset>
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
  100c05:	c7 04 24 a1 5b 10 00 	movl   $0x105ba1,(%esp)
  100c0c:	e8 de 45 00 00       	call   1051ef <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100c11:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c14:	a1 a4 e3 10 00       	mov    0x10e3a4,%eax
  100c19:	39 c2                	cmp    %eax,%edx
  100c1b:	72 24                	jb     100c41 <mem_check+0x98>
  100c1d:	c7 44 24 0c bb 5b 10 	movl   $0x105bbb,0xc(%esp)
  100c24:	00 
  100c25:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100c2c:	00 
  100c2d:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  100c34:	00 
  100c35:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100c3c:	e8 40 f8 ff ff       	call   100481 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100c41:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100c48:	7f 24                	jg     100c6e <mem_check+0xc5>
  100c4a:	c7 44 24 0c d1 5b 10 	movl   $0x105bd1,0xc(%esp)
  100c51:	00 
  100c52:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100c59:	00 
  100c5a:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100c61:	00 
  100c62:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
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
  100c8f:	c7 44 24 0c e3 5b 10 	movl   $0x105be3,0xc(%esp)
  100c96:	00 
  100c97:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100c9e:	00 
  100c9f:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  100ca6:	00 
  100ca7:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100cae:	e8 ce f7 ff ff       	call   100481 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100cb3:	e8 55 fe ff ff       	call   100b0d <mem_alloc>
  100cb8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100cbb:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100cbf:	75 24                	jne    100ce5 <mem_check+0x13c>
  100cc1:	c7 44 24 0c ec 5b 10 	movl   $0x105bec,0xc(%esp)
  100cc8:	00 
  100cc9:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100cd0:	00 
  100cd1:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100cd8:	00 
  100cd9:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100ce0:	e8 9c f7 ff ff       	call   100481 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100ce5:	e8 23 fe ff ff       	call   100b0d <mem_alloc>
  100cea:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100ced:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100cf1:	75 24                	jne    100d17 <mem_check+0x16e>
  100cf3:	c7 44 24 0c f5 5b 10 	movl   $0x105bf5,0xc(%esp)
  100cfa:	00 
  100cfb:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100d02:	00 
  100d03:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100d0a:	00 
  100d0b:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100d12:	e8 6a f7 ff ff       	call   100481 <debug_panic>

	assert(pp0);
  100d17:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100d1b:	75 24                	jne    100d41 <mem_check+0x198>
  100d1d:	c7 44 24 0c fe 5b 10 	movl   $0x105bfe,0xc(%esp)
  100d24:	00 
  100d25:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100d2c:	00 
  100d2d:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  100d34:	00 
  100d35:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100d3c:	e8 40 f7 ff ff       	call   100481 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100d41:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d45:	74 08                	je     100d4f <mem_check+0x1a6>
  100d47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d4a:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d4d:	75 24                	jne    100d73 <mem_check+0x1ca>
  100d4f:	c7 44 24 0c 02 5c 10 	movl   $0x105c02,0xc(%esp)
  100d56:	00 
  100d57:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100d5e:	00 
  100d5f:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100d66:	00 
  100d67:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
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
  100d89:	c7 44 24 0c 14 5c 10 	movl   $0x105c14,0xc(%esp)
  100d90:	00 
  100d91:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100d98:	00 
  100d99:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100da0:	00 
  100da1:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100da8:	e8 d4 f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100dad:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100db0:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
  100db5:	89 d1                	mov    %edx,%ecx
  100db7:	29 c1                	sub    %eax,%ecx
  100db9:	89 c8                	mov    %ecx,%eax
  100dbb:	c1 f8 03             	sar    $0x3,%eax
  100dbe:	c1 e0 0c             	shl    $0xc,%eax
  100dc1:	8b 15 a4 e3 10 00    	mov    0x10e3a4,%edx
  100dc7:	c1 e2 0c             	shl    $0xc,%edx
  100dca:	39 d0                	cmp    %edx,%eax
  100dcc:	72 24                	jb     100df2 <mem_check+0x249>
  100dce:	c7 44 24 0c 34 5c 10 	movl   $0x105c34,0xc(%esp)
  100dd5:	00 
  100dd6:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100ddd:	00 
  100dde:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  100de5:	00 
  100de6:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100ded:	e8 8f f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100df2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100df5:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
  100dfa:	89 d1                	mov    %edx,%ecx
  100dfc:	29 c1                	sub    %eax,%ecx
  100dfe:	89 c8                	mov    %ecx,%eax
  100e00:	c1 f8 03             	sar    $0x3,%eax
  100e03:	c1 e0 0c             	shl    $0xc,%eax
  100e06:	8b 15 a4 e3 10 00    	mov    0x10e3a4,%edx
  100e0c:	c1 e2 0c             	shl    $0xc,%edx
  100e0f:	39 d0                	cmp    %edx,%eax
  100e11:	72 24                	jb     100e37 <mem_check+0x28e>
  100e13:	c7 44 24 0c 5c 5c 10 	movl   $0x105c5c,0xc(%esp)
  100e1a:	00 
  100e1b:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100e22:	00 
  100e23:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  100e2a:	00 
  100e2b:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100e32:	e8 4a f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100e37:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100e3a:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
  100e3f:	89 d1                	mov    %edx,%ecx
  100e41:	29 c1                	sub    %eax,%ecx
  100e43:	89 c8                	mov    %ecx,%eax
  100e45:	c1 f8 03             	sar    $0x3,%eax
  100e48:	c1 e0 0c             	shl    $0xc,%eax
  100e4b:	8b 15 a4 e3 10 00    	mov    0x10e3a4,%edx
  100e51:	c1 e2 0c             	shl    $0xc,%edx
  100e54:	39 d0                	cmp    %edx,%eax
  100e56:	72 24                	jb     100e7c <mem_check+0x2d3>
  100e58:	c7 44 24 0c 84 5c 10 	movl   $0x105c84,0xc(%esp)
  100e5f:	00 
  100e60:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100e67:	00 
  100e68:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  100e6f:	00 
  100e70:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100e77:	e8 05 f6 ff ff       	call   100481 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100e7c:	a1 a0 e3 10 00       	mov    0x10e3a0,%eax
  100e81:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100e84:	c7 05 a0 e3 10 00 00 	movl   $0x0,0x10e3a0
  100e8b:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100e8e:	e8 7a fc ff ff       	call   100b0d <mem_alloc>
  100e93:	85 c0                	test   %eax,%eax
  100e95:	74 24                	je     100ebb <mem_check+0x312>
  100e97:	c7 44 24 0c aa 5c 10 	movl   $0x105caa,0xc(%esp)
  100e9e:	00 
  100e9f:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100ea6:	00 
  100ea7:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  100eae:	00 
  100eaf:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
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
  100efd:	c7 44 24 0c e3 5b 10 	movl   $0x105be3,0xc(%esp)
  100f04:	00 
  100f05:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100f0c:	00 
  100f0d:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  100f14:	00 
  100f15:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100f1c:	e8 60 f5 ff ff       	call   100481 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100f21:	e8 e7 fb ff ff       	call   100b0d <mem_alloc>
  100f26:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100f29:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100f2d:	75 24                	jne    100f53 <mem_check+0x3aa>
  100f2f:	c7 44 24 0c ec 5b 10 	movl   $0x105bec,0xc(%esp)
  100f36:	00 
  100f37:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100f3e:	00 
  100f3f:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  100f46:	00 
  100f47:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100f4e:	e8 2e f5 ff ff       	call   100481 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100f53:	e8 b5 fb ff ff       	call   100b0d <mem_alloc>
  100f58:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100f5b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f5f:	75 24                	jne    100f85 <mem_check+0x3dc>
  100f61:	c7 44 24 0c f5 5b 10 	movl   $0x105bf5,0xc(%esp)
  100f68:	00 
  100f69:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100f70:	00 
  100f71:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  100f78:	00 
  100f79:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100f80:	e8 fc f4 ff ff       	call   100481 <debug_panic>
	assert(pp0);
  100f85:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100f89:	75 24                	jne    100faf <mem_check+0x406>
  100f8b:	c7 44 24 0c fe 5b 10 	movl   $0x105bfe,0xc(%esp)
  100f92:	00 
  100f93:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100f9a:	00 
  100f9b:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  100fa2:	00 
  100fa3:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  100faa:	e8 d2 f4 ff ff       	call   100481 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100faf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100fb3:	74 08                	je     100fbd <mem_check+0x414>
  100fb5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100fb8:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100fbb:	75 24                	jne    100fe1 <mem_check+0x438>
  100fbd:	c7 44 24 0c 02 5c 10 	movl   $0x105c02,0xc(%esp)
  100fc4:	00 
  100fc5:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  100fcc:	00 
  100fcd:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  100fd4:	00 
  100fd5:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
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
  100ff7:	c7 44 24 0c 14 5c 10 	movl   $0x105c14,0xc(%esp)
  100ffe:	00 
  100fff:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  101006:	00 
  101007:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  10100e:	00 
  10100f:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  101016:	e8 66 f4 ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == 0);
  10101b:	e8 ed fa ff ff       	call   100b0d <mem_alloc>
  101020:	85 c0                	test   %eax,%eax
  101022:	74 24                	je     101048 <mem_check+0x49f>
  101024:	c7 44 24 0c aa 5c 10 	movl   $0x105caa,0xc(%esp)
  10102b:	00 
  10102c:	c7 44 24 08 f2 5a 10 	movl   $0x105af2,0x8(%esp)
  101033:	00 
  101034:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  10103b:	00 
  10103c:	c7 04 24 14 5b 10 00 	movl   $0x105b14,(%esp)
  101043:	e8 39 f4 ff ff       	call   100481 <debug_panic>

	// give free list back
	mem_freelist = fl;
  101048:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10104b:	a3 a0 e3 10 00       	mov    %eax,0x10e3a0

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
  101071:	c7 04 24 bb 5c 10 00 	movl   $0x105cbb,(%esp)
  101078:	e8 72 41 00 00       	call   1051ef <cprintf>
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
  1010c3:	c7 44 24 0c d3 5c 10 	movl   $0x105cd3,0xc(%esp)
  1010ca:	00 
  1010cb:	c7 44 24 08 e9 5c 10 	movl   $0x105ce9,0x8(%esp)
  1010d2:	00 
  1010d3:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1010da:	00 
  1010db:	c7 04 24 fe 5c 10 00 	movl   $0x105cfe,(%esp)
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
  1010f7:	3d 00 70 10 00       	cmp    $0x107000,%eax
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
  101239:	c7 44 24 0c 0b 5d 10 	movl   $0x105d0b,0xc(%esp)
  101240:	00 
  101241:	c7 44 24 08 e9 5c 10 	movl   $0x105ce9,0x8(%esp)
  101248:	00 
  101249:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  101250:	00 
  101251:	c7 04 24 13 5d 10 00 	movl   $0x105d13,(%esp)
  101258:	e8 24 f2 ff ff       	call   100481 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  10125d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101260:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
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
  10128a:	e8 45 41 00 00       	call   1053d4 <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  10128f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101292:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101299:	00 
  10129a:	c7 44 24 04 00 70 10 	movl   $0x107000,0x4(%esp)
  1012a1:	00 
  1012a2:	89 04 24             	mov    %eax,(%esp)
  1012a5:	e8 9e 41 00 00       	call   105448 <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  1012aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012ad:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  1012b4:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  1012b7:	a1 00 80 10 00       	mov    0x108000,%eax
  1012bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1012bf:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  1012c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012c4:	05 a8 00 00 00       	add    $0xa8,%eax
  1012c9:	a3 00 80 10 00       	mov    %eax,0x108000

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
  101311:	c7 44 24 04 32 86 10 	movl   $0x108632,0x4(%esp)
  101318:	00 
  101319:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10131c:	89 04 24             	mov    %eax,(%esp)
  10131f:	e8 24 41 00 00       	call   105448 <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  101324:	c7 45 f4 00 70 10 00 	movl   $0x107000,-0xc(%ebp)
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
  10136b:	e8 76 34 00 00       	call   1047e6 <lapic_startcpu>

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
  1013be:	c7 44 24 0c 20 5d 10 	movl   $0x105d20,0xc(%esp)
  1013c5:	00 
  1013c6:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  1013cd:	00 
  1013ce:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1013d5:	00 
  1013d6:	c7 04 24 4b 5d 10 00 	movl   $0x105d4b,(%esp)
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
  1013f2:	3d 00 70 10 00       	cmp    $0x107000,%eax
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
  101417:	8b 14 95 10 80 10 00 	mov    0x108010(,%edx,4),%edx
  10141e:	66 89 14 c5 c0 98 10 	mov    %dx,0x1098c0(,%eax,8)
  101425:	00 
  101426:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101429:	66 c7 04 c5 c2 98 10 	movw   $0x8,0x1098c2(,%eax,8)
  101430:	00 08 00 
  101433:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101436:	0f b6 14 c5 c4 98 10 	movzbl 0x1098c4(,%eax,8),%edx
  10143d:	00 
  10143e:	83 e2 e0             	and    $0xffffffe0,%edx
  101441:	88 14 c5 c4 98 10 00 	mov    %dl,0x1098c4(,%eax,8)
  101448:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10144b:	0f b6 14 c5 c4 98 10 	movzbl 0x1098c4(,%eax,8),%edx
  101452:	00 
  101453:	83 e2 1f             	and    $0x1f,%edx
  101456:	88 14 c5 c4 98 10 00 	mov    %dl,0x1098c4(,%eax,8)
  10145d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101460:	0f b6 14 c5 c5 98 10 	movzbl 0x1098c5(,%eax,8),%edx
  101467:	00 
  101468:	83 ca 0f             	or     $0xf,%edx
  10146b:	88 14 c5 c5 98 10 00 	mov    %dl,0x1098c5(,%eax,8)
  101472:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101475:	0f b6 14 c5 c5 98 10 	movzbl 0x1098c5(,%eax,8),%edx
  10147c:	00 
  10147d:	83 e2 ef             	and    $0xffffffef,%edx
  101480:	88 14 c5 c5 98 10 00 	mov    %dl,0x1098c5(,%eax,8)
  101487:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10148a:	0f b6 14 c5 c5 98 10 	movzbl 0x1098c5(,%eax,8),%edx
  101491:	00 
  101492:	83 ca 60             	or     $0x60,%edx
  101495:	88 14 c5 c5 98 10 00 	mov    %dl,0x1098c5(,%eax,8)
  10149c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10149f:	0f b6 14 c5 c5 98 10 	movzbl 0x1098c5(,%eax,8),%edx
  1014a6:	00 
  1014a7:	83 ca 80             	or     $0xffffff80,%edx
  1014aa:	88 14 c5 c5 98 10 00 	mov    %dl,0x1098c5(,%eax,8)
  1014b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1014b4:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1014b7:	8b 14 95 10 80 10 00 	mov    0x108010(,%edx,4),%edx
  1014be:	c1 ea 10             	shr    $0x10,%edx
  1014c1:	66 89 14 c5 c6 98 10 	mov    %dx,0x1098c6(,%eax,8)
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
  1014d7:	a1 88 80 10 00       	mov    0x108088,%eax
  1014dc:	66 a3 b0 99 10 00    	mov    %ax,0x1099b0
  1014e2:	66 c7 05 b2 99 10 00 	movw   $0x8,0x1099b2
  1014e9:	08 00 
  1014eb:	0f b6 05 b4 99 10 00 	movzbl 0x1099b4,%eax
  1014f2:	83 e0 e0             	and    $0xffffffe0,%eax
  1014f5:	a2 b4 99 10 00       	mov    %al,0x1099b4
  1014fa:	0f b6 05 b4 99 10 00 	movzbl 0x1099b4,%eax
  101501:	83 e0 1f             	and    $0x1f,%eax
  101504:	a2 b4 99 10 00       	mov    %al,0x1099b4
  101509:	0f b6 05 b5 99 10 00 	movzbl 0x1099b5,%eax
  101510:	83 c8 0f             	or     $0xf,%eax
  101513:	a2 b5 99 10 00       	mov    %al,0x1099b5
  101518:	0f b6 05 b5 99 10 00 	movzbl 0x1099b5,%eax
  10151f:	83 e0 ef             	and    $0xffffffef,%eax
  101522:	a2 b5 99 10 00       	mov    %al,0x1099b5
  101527:	0f b6 05 b5 99 10 00 	movzbl 0x1099b5,%eax
  10152e:	83 c8 60             	or     $0x60,%eax
  101531:	a2 b5 99 10 00       	mov    %al,0x1099b5
  101536:	0f b6 05 b5 99 10 00 	movzbl 0x1099b5,%eax
  10153d:	83 c8 80             	or     $0xffffff80,%eax
  101540:	a2 b5 99 10 00       	mov    %al,0x1099b5
  101545:	a1 88 80 10 00       	mov    0x108088,%eax
  10154a:	c1 e8 10             	shr    $0x10,%eax
  10154d:	66 a3 b6 99 10 00    	mov    %ax,0x1099b6
	SETGATE(idt[T_SYSCALL], 1, CPU_GDT_KCODE, vectors[T_SYSCALL], 3);
  101553:	a1 d0 80 10 00       	mov    0x1080d0,%eax
  101558:	66 a3 40 9a 10 00    	mov    %ax,0x109a40
  10155e:	66 c7 05 42 9a 10 00 	movw   $0x8,0x109a42
  101565:	08 00 
  101567:	0f b6 05 44 9a 10 00 	movzbl 0x109a44,%eax
  10156e:	83 e0 e0             	and    $0xffffffe0,%eax
  101571:	a2 44 9a 10 00       	mov    %al,0x109a44
  101576:	0f b6 05 44 9a 10 00 	movzbl 0x109a44,%eax
  10157d:	83 e0 1f             	and    $0x1f,%eax
  101580:	a2 44 9a 10 00       	mov    %al,0x109a44
  101585:	0f b6 05 45 9a 10 00 	movzbl 0x109a45,%eax
  10158c:	83 c8 0f             	or     $0xf,%eax
  10158f:	a2 45 9a 10 00       	mov    %al,0x109a45
  101594:	0f b6 05 45 9a 10 00 	movzbl 0x109a45,%eax
  10159b:	83 e0 ef             	and    $0xffffffef,%eax
  10159e:	a2 45 9a 10 00       	mov    %al,0x109a45
  1015a3:	0f b6 05 45 9a 10 00 	movzbl 0x109a45,%eax
  1015aa:	83 c8 60             	or     $0x60,%eax
  1015ad:	a2 45 9a 10 00       	mov    %al,0x109a45
  1015b2:	0f b6 05 45 9a 10 00 	movzbl 0x109a45,%eax
  1015b9:	83 c8 80             	or     $0xffffff80,%eax
  1015bc:	a2 45 9a 10 00       	mov    %al,0x109a45
  1015c1:	a1 d0 80 10 00       	mov    0x1080d0,%eax
  1015c6:	c1 e8 10             	shr    $0x10,%eax
  1015c9:	66 a3 46 9a 10 00    	mov    %ax,0x109a46
	SETGATE(idt[T_LTIMER], 1, CPU_GDT_KCODE, vectors[T_LTIMER], 3);
  1015cf:	a1 d4 80 10 00       	mov    0x1080d4,%eax
  1015d4:	66 a3 48 9a 10 00    	mov    %ax,0x109a48
  1015da:	66 c7 05 4a 9a 10 00 	movw   $0x8,0x109a4a
  1015e1:	08 00 
  1015e3:	0f b6 05 4c 9a 10 00 	movzbl 0x109a4c,%eax
  1015ea:	83 e0 e0             	and    $0xffffffe0,%eax
  1015ed:	a2 4c 9a 10 00       	mov    %al,0x109a4c
  1015f2:	0f b6 05 4c 9a 10 00 	movzbl 0x109a4c,%eax
  1015f9:	83 e0 1f             	and    $0x1f,%eax
  1015fc:	a2 4c 9a 10 00       	mov    %al,0x109a4c
  101601:	0f b6 05 4d 9a 10 00 	movzbl 0x109a4d,%eax
  101608:	83 c8 0f             	or     $0xf,%eax
  10160b:	a2 4d 9a 10 00       	mov    %al,0x109a4d
  101610:	0f b6 05 4d 9a 10 00 	movzbl 0x109a4d,%eax
  101617:	83 e0 ef             	and    $0xffffffef,%eax
  10161a:	a2 4d 9a 10 00       	mov    %al,0x109a4d
  10161f:	0f b6 05 4d 9a 10 00 	movzbl 0x109a4d,%eax
  101626:	83 c8 60             	or     $0x60,%eax
  101629:	a2 4d 9a 10 00       	mov    %al,0x109a4d
  10162e:	0f b6 05 4d 9a 10 00 	movzbl 0x109a4d,%eax
  101635:	83 c8 80             	or     $0xffffff80,%eax
  101638:	a2 4d 9a 10 00       	mov    %al,0x109a4d
  10163d:	a1 d4 80 10 00       	mov    0x1080d4,%eax
  101642:	c1 e8 10             	shr    $0x10,%eax
  101645:	66 a3 4e 9a 10 00    	mov    %ax,0x109a4e
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
  101661:	0f 01 1d 04 80 10 00 	lidtl  0x108004

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
  101686:	8b 04 85 60 61 10 00 	mov    0x106160(,%eax,4),%eax
  10168d:	eb 25                	jmp    1016b4 <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  10168f:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  101693:	75 07                	jne    10169c <trap_name+0x24>
		return "System call";
  101695:	b8 58 5d 10 00       	mov    $0x105d58,%eax
  10169a:	eb 18                	jmp    1016b4 <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  10169c:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  1016a0:	7e 0d                	jle    1016af <trap_name+0x37>
  1016a2:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  1016a6:	7f 07                	jg     1016af <trap_name+0x37>
		return "Hardware Interrupt";
  1016a8:	b8 64 5d 10 00       	mov    $0x105d64,%eax
  1016ad:	eb 05                	jmp    1016b4 <trap_name+0x3c>
	return "(unknown trap)";
  1016af:	b8 77 5d 10 00       	mov    $0x105d77,%eax
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
  1016c5:	c7 04 24 86 5d 10 00 	movl   $0x105d86,(%esp)
  1016cc:	e8 1e 3b 00 00       	call   1051ef <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  1016d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1016d4:	8b 40 04             	mov    0x4(%eax),%eax
  1016d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016db:	c7 04 24 95 5d 10 00 	movl   $0x105d95,(%esp)
  1016e2:	e8 08 3b 00 00       	call   1051ef <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  1016e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1016ea:	8b 40 08             	mov    0x8(%eax),%eax
  1016ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016f1:	c7 04 24 a4 5d 10 00 	movl   $0x105da4,(%esp)
  1016f8:	e8 f2 3a 00 00       	call   1051ef <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  1016fd:	8b 45 08             	mov    0x8(%ebp),%eax
  101700:	8b 40 10             	mov    0x10(%eax),%eax
  101703:	89 44 24 04          	mov    %eax,0x4(%esp)
  101707:	c7 04 24 b3 5d 10 00 	movl   $0x105db3,(%esp)
  10170e:	e8 dc 3a 00 00       	call   1051ef <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101713:	8b 45 08             	mov    0x8(%ebp),%eax
  101716:	8b 40 14             	mov    0x14(%eax),%eax
  101719:	89 44 24 04          	mov    %eax,0x4(%esp)
  10171d:	c7 04 24 c2 5d 10 00 	movl   $0x105dc2,(%esp)
  101724:	e8 c6 3a 00 00       	call   1051ef <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101729:	8b 45 08             	mov    0x8(%ebp),%eax
  10172c:	8b 40 18             	mov    0x18(%eax),%eax
  10172f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101733:	c7 04 24 d1 5d 10 00 	movl   $0x105dd1,(%esp)
  10173a:	e8 b0 3a 00 00       	call   1051ef <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  10173f:	8b 45 08             	mov    0x8(%ebp),%eax
  101742:	8b 40 1c             	mov    0x1c(%eax),%eax
  101745:	89 44 24 04          	mov    %eax,0x4(%esp)
  101749:	c7 04 24 e0 5d 10 00 	movl   $0x105de0,(%esp)
  101750:	e8 9a 3a 00 00       	call   1051ef <cprintf>
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
  101764:	c7 04 24 ef 5d 10 00 	movl   $0x105def,(%esp)
  10176b:	e8 7f 3a 00 00       	call   1051ef <cprintf>
	trap_print_regs(&tf->regs);
  101770:	8b 45 08             	mov    0x8(%ebp),%eax
  101773:	89 04 24             	mov    %eax,(%esp)
  101776:	e8 3b ff ff ff       	call   1016b6 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  10177b:	8b 45 08             	mov    0x8(%ebp),%eax
  10177e:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101782:	0f b7 c0             	movzwl %ax,%eax
  101785:	89 44 24 04          	mov    %eax,0x4(%esp)
  101789:	c7 04 24 01 5e 10 00 	movl   $0x105e01,(%esp)
  101790:	e8 5a 3a 00 00       	call   1051ef <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101795:	8b 45 08             	mov    0x8(%ebp),%eax
  101798:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10179c:	0f b7 c0             	movzwl %ax,%eax
  10179f:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017a3:	c7 04 24 14 5e 10 00 	movl   $0x105e14,(%esp)
  1017aa:	e8 40 3a 00 00       	call   1051ef <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  1017af:	8b 45 08             	mov    0x8(%ebp),%eax
  1017b2:	8b 40 30             	mov    0x30(%eax),%eax
  1017b5:	89 04 24             	mov    %eax,(%esp)
  1017b8:	e8 bb fe ff ff       	call   101678 <trap_name>
  1017bd:	8b 55 08             	mov    0x8(%ebp),%edx
  1017c0:	8b 52 30             	mov    0x30(%edx),%edx
  1017c3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1017c7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1017cb:	c7 04 24 27 5e 10 00 	movl   $0x105e27,(%esp)
  1017d2:	e8 18 3a 00 00       	call   1051ef <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  1017d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1017da:	8b 40 34             	mov    0x34(%eax),%eax
  1017dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017e1:	c7 04 24 39 5e 10 00 	movl   $0x105e39,(%esp)
  1017e8:	e8 02 3a 00 00       	call   1051ef <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1017ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1017f0:	8b 40 38             	mov    0x38(%eax),%eax
  1017f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017f7:	c7 04 24 48 5e 10 00 	movl   $0x105e48,(%esp)
  1017fe:	e8 ec 39 00 00       	call   1051ef <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101803:	8b 45 08             	mov    0x8(%ebp),%eax
  101806:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10180a:	0f b7 c0             	movzwl %ax,%eax
  10180d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101811:	c7 04 24 57 5e 10 00 	movl   $0x105e57,(%esp)
  101818:	e8 d2 39 00 00       	call   1051ef <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  10181d:	8b 45 08             	mov    0x8(%ebp),%eax
  101820:	8b 40 40             	mov    0x40(%eax),%eax
  101823:	89 44 24 04          	mov    %eax,0x4(%esp)
  101827:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  10182e:	e8 bc 39 00 00       	call   1051ef <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  101833:	8b 45 08             	mov    0x8(%ebp),%eax
  101836:	8b 40 44             	mov    0x44(%eax),%eax
  101839:	89 44 24 04          	mov    %eax,0x4(%esp)
  10183d:	c7 04 24 79 5e 10 00 	movl   $0x105e79,(%esp)
  101844:	e8 a6 39 00 00       	call   1051ef <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  101849:	8b 45 08             	mov    0x8(%ebp),%eax
  10184c:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101850:	0f b7 c0             	movzwl %ax,%eax
  101853:	89 44 24 04          	mov    %eax,0x4(%esp)
  101857:	c7 04 24 88 5e 10 00 	movl   $0x105e88,(%esp)
  10185e:	e8 8c 39 00 00       	call   1051ef <cprintf>
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
  1018b1:	e8 48 23 00 00       	call   103bfe <syscall>
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
  1018c6:	e8 8c 2e 00 00       	call   104757 <lapic_eoi>
			proc_yield(tf);
  1018cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1018ce:	89 04 24             	mov    %eax,(%esp)
  1018d1:	e8 6b 17 00 00       	call   103041 <proc_yield>
			break;
		case T_IRQ0 + IRQ_SPURIOUS:
			panic(" IRQ_SPURIOUS ");
  1018d6:	c7 44 24 08 9b 5e 10 	movl   $0x105e9b,0x8(%esp)
  1018dd:	00 
  1018de:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  1018e5:	00 
  1018e6:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
  1018ed:	e8 8f eb ff ff       	call   100481 <debug_panic>

		default:
			proc_ret(tf, -1);
  1018f2:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1018f9:	ff 
  1018fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1018fd:	89 04 24             	mov    %eax,(%esp)
  101900:	e8 7a 17 00 00       	call   10307f <proc_ret>

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
  101932:	e8 b9 67 00 00       	call   1080f0 <trap_return>

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
  10194e:	c7 44 24 0c b6 5e 10 	movl   $0x105eb6,0xc(%esp)
  101955:	00 
  101956:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  10195d:	00 
  10195e:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
  101965:	00 
  101966:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
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
  1019a4:	c7 04 24 cc 5e 10 00 	movl   $0x105ecc,(%esp)
  1019ab:	e8 3f 38 00 00       	call   1051ef <cprintf>
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
  1019ca:	c7 44 24 0c ec 5e 10 	movl   $0x105eec,0xc(%esp)
  1019d1:	00 
  1019d2:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  1019d9:	00 
  1019da:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  1019e1:	00 
  1019e2:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
  1019e9:	e8 93 ea ff ff       	call   100481 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  1019ee:	c7 45 f0 00 70 10 00 	movl   $0x107000,-0x10(%ebp)
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
  101a1f:	c7 04 24 01 5f 10 00 	movl   $0x105f01,(%esp)
  101a26:	e8 c4 37 00 00       	call   1051ef <cprintf>
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
  101a53:	c7 04 24 1f 5f 10 00 	movl   $0x105f1f,(%esp)
  101a5a:	e8 90 37 00 00       	call   1051ef <cprintf>

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
  101a69:	c7 04 24 38 5f 10 00 	movl   $0x105f38,(%esp)
  101a70:	e8 7a 37 00 00       	call   1051ef <cprintf>
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101a75:	b8 00 00 00 00       	mov    $0x0,%eax
  101a7a:	f7 f0                	div    %eax

00101a7c <after_div0>:
	cprintf("2. &args.trapno == %x\n", &args);
  101a7c:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  101a7f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a83:	c7 04 24 5e 5f 10 00 	movl   $0x105f5e,(%esp)
  101a8a:	e8 60 37 00 00       	call   1051ef <cprintf>
	assert(args.trapno == T_DIVIDE);
  101a8f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101a92:	85 c0                	test   %eax,%eax
  101a94:	74 24                	je     101aba <after_div0+0x3e>
  101a96:	c7 44 24 0c 75 5f 10 	movl   $0x105f75,0xc(%esp)
  101a9d:	00 
  101a9e:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  101aa5:	00 
  101aa6:	c7 44 24 04 f8 00 00 	movl   $0xf8,0x4(%esp)
  101aad:	00 
  101aae:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
  101ab5:	e8 c7 e9 ff ff       	call   100481 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101aba:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101abd:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101ac2:	74 24                	je     101ae8 <after_div0+0x6c>
  101ac4:	c7 44 24 0c 8d 5f 10 	movl   $0x105f8d,0xc(%esp)
  101acb:	00 
  101acc:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  101ad3:	00 
  101ad4:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
  101adb:	00 
  101adc:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
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
  101af8:	c7 44 24 0c a2 5f 10 	movl   $0x105fa2,0xc(%esp)
  101aff:	00 
  101b00:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  101b07:	00 
  101b08:	c7 44 24 04 02 01 00 	movl   $0x102,0x4(%esp)
  101b0f:	00 
  101b10:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
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
  101b33:	c7 44 24 0c b9 5f 10 	movl   $0x105fb9,0xc(%esp)
  101b3a:	00 
  101b3b:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  101b42:	00 
  101b43:	c7 44 24 04 07 01 00 	movl   $0x107,0x4(%esp)
  101b4a:	00 
  101b4b:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
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
  101b7c:	c7 44 24 0c d0 5f 10 	movl   $0x105fd0,0xc(%esp)
  101b83:	00 
  101b84:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  101b8b:	00 
  101b8c:	c7 44 24 04 0d 01 00 	movl   $0x10d,0x4(%esp)
  101b93:	00 
  101b94:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
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
  101bb1:	c7 44 24 0c e7 5f 10 	movl   $0x105fe7,0xc(%esp)
  101bb8:	00 
  101bb9:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  101bc0:	00 
  101bc1:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
  101bc8:	00 
  101bc9:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
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
  101beb:	c7 44 24 0c fe 5f 10 	movl   $0x105ffe,0xc(%esp)
  101bf2:	00 
  101bf3:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  101bfa:	00 
  101bfb:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
  101c02:	00 
  101c03:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
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
  101c27:	0f 01 1d 04 80 10 00 	lidtl  0x108004

00101c2e <after_priv>:
		assert(args.trapno == T_GPFLT);
  101c2e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101c31:	83 f8 0d             	cmp    $0xd,%eax
  101c34:	74 24                	je     101c5a <after_priv+0x2c>
  101c36:	c7 44 24 0c fe 5f 10 	movl   $0x105ffe,0xc(%esp)
  101c3d:	00 
  101c3e:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  101c45:	00 
  101c46:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
  101c4d:	00 
  101c4e:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
  101c55:	e8 27 e8 ff ff       	call   100481 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101c5a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101c5d:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101c62:	74 24                	je     101c88 <after_priv+0x5a>
  101c64:	c7 44 24 0c 8d 5f 10 	movl   $0x105f8d,0xc(%esp)
  101c6b:	00 
  101c6c:	c7 44 24 08 36 5d 10 	movl   $0x105d36,0x8(%esp)
  101c73:	00 
  101c74:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
  101c7b:	00 
  101c7c:	c7 04 24 aa 5e 10 00 	movl   $0x105eaa,(%esp)
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
  101c9e:	e9 35 64 00 00       	jmp    1080d8 <_alltraps>
  101ca3:	90                   	nop

00101ca4 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  101ca4:	6a 00                	push   $0x0
  101ca6:	6a 01                	push   $0x1
  101ca8:	e9 2b 64 00 00       	jmp    1080d8 <_alltraps>
  101cad:	90                   	nop

00101cae <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  101cae:	6a 00                	push   $0x0
  101cb0:	6a 02                	push   $0x2
  101cb2:	e9 21 64 00 00       	jmp    1080d8 <_alltraps>
  101cb7:	90                   	nop

00101cb8 <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  101cb8:	6a 00                	push   $0x0
  101cba:	6a 03                	push   $0x3
  101cbc:	e9 17 64 00 00       	jmp    1080d8 <_alltraps>
  101cc1:	90                   	nop

00101cc2 <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  101cc2:	6a 00                	push   $0x0
  101cc4:	6a 04                	push   $0x4
  101cc6:	e9 0d 64 00 00       	jmp    1080d8 <_alltraps>
  101ccb:	90                   	nop

00101ccc <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  101ccc:	6a 00                	push   $0x0
  101cce:	6a 05                	push   $0x5
  101cd0:	e9 03 64 00 00       	jmp    1080d8 <_alltraps>
  101cd5:	90                   	nop

00101cd6 <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  101cd6:	6a 00                	push   $0x0
  101cd8:	6a 06                	push   $0x6
  101cda:	e9 f9 63 00 00       	jmp    1080d8 <_alltraps>
  101cdf:	90                   	nop

00101ce0 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  101ce0:	6a 00                	push   $0x0
  101ce2:	6a 07                	push   $0x7
  101ce4:	e9 ef 63 00 00       	jmp    1080d8 <_alltraps>
  101ce9:	90                   	nop

00101cea <vector8>:
TRAPHANDLER(vector8, 8)
  101cea:	6a 08                	push   $0x8
  101cec:	e9 e7 63 00 00       	jmp    1080d8 <_alltraps>
  101cf1:	90                   	nop

00101cf2 <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  101cf2:	6a 00                	push   $0x0
  101cf4:	6a 09                	push   $0x9
  101cf6:	e9 dd 63 00 00       	jmp    1080d8 <_alltraps>
  101cfb:	90                   	nop

00101cfc <vector10>:
TRAPHANDLER(vector10, 10)
  101cfc:	6a 0a                	push   $0xa
  101cfe:	e9 d5 63 00 00       	jmp    1080d8 <_alltraps>
  101d03:	90                   	nop

00101d04 <vector11>:
TRAPHANDLER(vector11, 11)
  101d04:	6a 0b                	push   $0xb
  101d06:	e9 cd 63 00 00       	jmp    1080d8 <_alltraps>
  101d0b:	90                   	nop

00101d0c <vector12>:
TRAPHANDLER(vector12, 12)
  101d0c:	6a 0c                	push   $0xc
  101d0e:	e9 c5 63 00 00       	jmp    1080d8 <_alltraps>
  101d13:	90                   	nop

00101d14 <vector13>:
TRAPHANDLER(vector13, 13)
  101d14:	6a 0d                	push   $0xd
  101d16:	e9 bd 63 00 00       	jmp    1080d8 <_alltraps>
  101d1b:	90                   	nop

00101d1c <vector14>:
TRAPHANDLER(vector14, 14)
  101d1c:	6a 0e                	push   $0xe
  101d1e:	e9 b5 63 00 00       	jmp    1080d8 <_alltraps>
  101d23:	90                   	nop

00101d24 <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101d24:	6a 00                	push   $0x0
  101d26:	6a 0f                	push   $0xf
  101d28:	e9 ab 63 00 00       	jmp    1080d8 <_alltraps>
  101d2d:	90                   	nop

00101d2e <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  101d2e:	6a 00                	push   $0x0
  101d30:	6a 10                	push   $0x10
  101d32:	e9 a1 63 00 00       	jmp    1080d8 <_alltraps>
  101d37:	90                   	nop

00101d38 <vector17>:
TRAPHANDLER(vector17, 17)
  101d38:	6a 11                	push   $0x11
  101d3a:	e9 99 63 00 00       	jmp    1080d8 <_alltraps>
  101d3f:	90                   	nop

00101d40 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  101d40:	6a 00                	push   $0x0
  101d42:	6a 12                	push   $0x12
  101d44:	e9 8f 63 00 00       	jmp    1080d8 <_alltraps>
  101d49:	90                   	nop

00101d4a <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  101d4a:	6a 00                	push   $0x0
  101d4c:	6a 13                	push   $0x13
  101d4e:	e9 85 63 00 00       	jmp    1080d8 <_alltraps>
  101d53:	90                   	nop

00101d54 <vector20>:
TRAPHANDLER_NOEC(vector20, 20)
  101d54:	6a 00                	push   $0x0
  101d56:	6a 14                	push   $0x14
  101d58:	e9 7b 63 00 00       	jmp    1080d8 <_alltraps>
  101d5d:	90                   	nop

00101d5e <vector21>:
TRAPHANDLER_NOEC(vector21, 21)
  101d5e:	6a 00                	push   $0x0
  101d60:	6a 15                	push   $0x15
  101d62:	e9 71 63 00 00       	jmp    1080d8 <_alltraps>
  101d67:	90                   	nop

00101d68 <vector22>:
TRAPHANDLER_NOEC(vector22, 22)
  101d68:	6a 00                	push   $0x0
  101d6a:	6a 16                	push   $0x16
  101d6c:	e9 67 63 00 00       	jmp    1080d8 <_alltraps>
  101d71:	90                   	nop

00101d72 <vector23>:
TRAPHANDLER_NOEC(vector23, 23)
  101d72:	6a 00                	push   $0x0
  101d74:	6a 17                	push   $0x17
  101d76:	e9 5d 63 00 00       	jmp    1080d8 <_alltraps>
  101d7b:	90                   	nop

00101d7c <vector24>:
TRAPHANDLER_NOEC(vector24, 24)
  101d7c:	6a 00                	push   $0x0
  101d7e:	6a 18                	push   $0x18
  101d80:	e9 53 63 00 00       	jmp    1080d8 <_alltraps>
  101d85:	90                   	nop

00101d86 <vector25>:
TRAPHANDLER_NOEC(vector25, 25)
  101d86:	6a 00                	push   $0x0
  101d88:	6a 19                	push   $0x19
  101d8a:	e9 49 63 00 00       	jmp    1080d8 <_alltraps>
  101d8f:	90                   	nop

00101d90 <vector26>:
TRAPHANDLER_NOEC(vector26, 26)
  101d90:	6a 00                	push   $0x0
  101d92:	6a 1a                	push   $0x1a
  101d94:	e9 3f 63 00 00       	jmp    1080d8 <_alltraps>
  101d99:	90                   	nop

00101d9a <vector27>:
TRAPHANDLER_NOEC(vector27, 27)
  101d9a:	6a 00                	push   $0x0
  101d9c:	6a 1b                	push   $0x1b
  101d9e:	e9 35 63 00 00       	jmp    1080d8 <_alltraps>
  101da3:	90                   	nop

00101da4 <vector28>:
TRAPHANDLER_NOEC(vector28, 28)
  101da4:	6a 00                	push   $0x0
  101da6:	6a 1c                	push   $0x1c
  101da8:	e9 2b 63 00 00       	jmp    1080d8 <_alltraps>
  101dad:	90                   	nop

00101dae <vector29>:
TRAPHANDLER_NOEC(vector29, 29)
  101dae:	6a 00                	push   $0x0
  101db0:	6a 1d                	push   $0x1d
  101db2:	e9 21 63 00 00       	jmp    1080d8 <_alltraps>
  101db7:	90                   	nop

00101db8 <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101db8:	6a 00                	push   $0x0
  101dba:	6a 1e                	push   $0x1e
  101dbc:	e9 17 63 00 00       	jmp    1080d8 <_alltraps>
  101dc1:	90                   	nop

00101dc2 <vector31>:
TRAPHANDLER_NOEC(vector31, 31)
  101dc2:	6a 00                	push   $0x0
  101dc4:	6a 1f                	push   $0x1f
  101dc6:	e9 0d 63 00 00       	jmp    1080d8 <_alltraps>
  101dcb:	90                   	nop

00101dcc <vector32>:
TRAPHANDLER_NOEC(vector32, 32)
  101dcc:	6a 00                	push   $0x0
  101dce:	6a 20                	push   $0x20
  101dd0:	e9 03 63 00 00       	jmp    1080d8 <_alltraps>
  101dd5:	90                   	nop

00101dd6 <vector33>:
TRAPHANDLER_NOEC(vector33, 33)
  101dd6:	6a 00                	push   $0x0
  101dd8:	6a 21                	push   $0x21
  101dda:	e9 f9 62 00 00       	jmp    1080d8 <_alltraps>
  101ddf:	90                   	nop

00101de0 <vector34>:
TRAPHANDLER_NOEC(vector34, 34)
  101de0:	6a 00                	push   $0x0
  101de2:	6a 22                	push   $0x22
  101de4:	e9 ef 62 00 00       	jmp    1080d8 <_alltraps>
  101de9:	90                   	nop

00101dea <vector35>:
TRAPHANDLER_NOEC(vector35, 35)
  101dea:	6a 00                	push   $0x0
  101dec:	6a 23                	push   $0x23
  101dee:	e9 e5 62 00 00       	jmp    1080d8 <_alltraps>
  101df3:	90                   	nop

00101df4 <vector36>:
TRAPHANDLER_NOEC(vector36, 36)
  101df4:	6a 00                	push   $0x0
  101df6:	6a 24                	push   $0x24
  101df8:	e9 db 62 00 00       	jmp    1080d8 <_alltraps>
  101dfd:	90                   	nop

00101dfe <vector37>:
TRAPHANDLER_NOEC(vector37, 37)
  101dfe:	6a 00                	push   $0x0
  101e00:	6a 25                	push   $0x25
  101e02:	e9 d1 62 00 00       	jmp    1080d8 <_alltraps>
  101e07:	90                   	nop

00101e08 <vector38>:
TRAPHANDLER_NOEC(vector38, 38)
  101e08:	6a 00                	push   $0x0
  101e0a:	6a 26                	push   $0x26
  101e0c:	e9 c7 62 00 00       	jmp    1080d8 <_alltraps>
  101e11:	90                   	nop

00101e12 <vector39>:
TRAPHANDLER_NOEC(vector39, 39)
  101e12:	6a 00                	push   $0x0
  101e14:	6a 27                	push   $0x27
  101e16:	e9 bd 62 00 00       	jmp    1080d8 <_alltraps>
  101e1b:	90                   	nop

00101e1c <vector40>:
TRAPHANDLER_NOEC(vector40, 40)
  101e1c:	6a 00                	push   $0x0
  101e1e:	6a 28                	push   $0x28
  101e20:	e9 b3 62 00 00       	jmp    1080d8 <_alltraps>
  101e25:	90                   	nop

00101e26 <vector41>:
TRAPHANDLER_NOEC(vector41, 41)
  101e26:	6a 00                	push   $0x0
  101e28:	6a 29                	push   $0x29
  101e2a:	e9 a9 62 00 00       	jmp    1080d8 <_alltraps>
  101e2f:	90                   	nop

00101e30 <vector42>:
TRAPHANDLER_NOEC(vector42, 42)
  101e30:	6a 00                	push   $0x0
  101e32:	6a 2a                	push   $0x2a
  101e34:	e9 9f 62 00 00       	jmp    1080d8 <_alltraps>
  101e39:	90                   	nop

00101e3a <vector43>:
TRAPHANDLER_NOEC(vector43, 43)
  101e3a:	6a 00                	push   $0x0
  101e3c:	6a 2b                	push   $0x2b
  101e3e:	e9 95 62 00 00       	jmp    1080d8 <_alltraps>
  101e43:	90                   	nop

00101e44 <vector44>:
TRAPHANDLER_NOEC(vector44, 44)
  101e44:	6a 00                	push   $0x0
  101e46:	6a 2c                	push   $0x2c
  101e48:	e9 8b 62 00 00       	jmp    1080d8 <_alltraps>
  101e4d:	90                   	nop

00101e4e <vector45>:
TRAPHANDLER_NOEC(vector45, 45)
  101e4e:	6a 00                	push   $0x0
  101e50:	6a 2d                	push   $0x2d
  101e52:	e9 81 62 00 00       	jmp    1080d8 <_alltraps>
  101e57:	90                   	nop

00101e58 <vector46>:
TRAPHANDLER_NOEC(vector46, 46)
  101e58:	6a 00                	push   $0x0
  101e5a:	6a 2e                	push   $0x2e
  101e5c:	e9 77 62 00 00       	jmp    1080d8 <_alltraps>
  101e61:	90                   	nop

00101e62 <vector47>:
TRAPHANDLER_NOEC(vector47, 47)
  101e62:	6a 00                	push   $0x0
  101e64:	6a 2f                	push   $0x2f
  101e66:	e9 6d 62 00 00       	jmp    1080d8 <_alltraps>
  101e6b:	90                   	nop

00101e6c <vector48>:
TRAPHANDLER_NOEC(vector48, 48)
  101e6c:	6a 00                	push   $0x0
  101e6e:	6a 30                	push   $0x30
  101e70:	e9 63 62 00 00       	jmp    1080d8 <_alltraps>
  101e75:	90                   	nop

00101e76 <vector49>:
TRAPHANDLER_NOEC(vector49, 49)
  101e76:	6a 00                	push   $0x0
  101e78:	6a 31                	push   $0x31
  101e7a:	e9 59 62 00 00       	jmp    1080d8 <_alltraps>

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
  101ea9:	c7 44 24 0c b0 61 10 	movl   $0x1061b0,0xc(%esp)
  101eb0:	00 
  101eb1:	c7 44 24 08 c6 61 10 	movl   $0x1061c6,0x8(%esp)
  101eb8:	00 
  101eb9:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101ec0:	00 
  101ec1:	c7 04 24 db 61 10 00 	movl   $0x1061db,(%esp)
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
  101edd:	3d 00 70 10 00       	cmp    $0x107000,%eax
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
  101f3f:	c7 44 24 04 e8 61 10 	movl   $0x1061e8,0x4(%esp)
  101f46:	00 
  101f47:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f4a:	89 04 24             	mov    %eax,(%esp)
  101f4d:	e8 f2 35 00 00       	call   105544 <memcmp>
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
  102075:	c7 44 24 04 ed 61 10 	movl   $0x1061ed,0x4(%esp)
  10207c:	00 
  10207d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102080:	89 04 24             	mov    %eax,(%esp)
  102083:	e8 bc 34 00 00       	call   105544 <memcmp>
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
  10210c:	c7 05 04 e4 30 00 01 	movl   $0x1,0x30e404
  102113:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  102116:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102119:	8b 40 24             	mov    0x24(%eax),%eax
  10211c:	a3 0c eb 30 00       	mov    %eax,0x30eb0c
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
  102154:	8b 04 85 20 62 10 00 	mov    0x106220(,%eax,4),%eax
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
  102194:	b8 00 70 10 00       	mov    $0x107000,%eax
  102199:	89 45 e0             	mov    %eax,-0x20(%ebp)
			c->id = proc->apicid;
  10219c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10219f:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  1021a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1021a6:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  1021ac:	a1 08 e4 30 00       	mov    0x30e408,%eax
  1021b1:	83 c0 01             	add    $0x1,%eax
  1021b4:	a3 08 e4 30 00       	mov    %eax,0x30e408
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
  1021cc:	a2 fc e3 30 00       	mov    %al,0x30e3fc
			ioapic = (struct ioapic *) mpio->addr;
  1021d1:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1021d4:	8b 40 04             	mov    0x4(%eax),%eax
  1021d7:	a3 00 e4 30 00       	mov    %eax,0x30e400
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
  1021f1:	c7 44 24 08 f4 61 10 	movl   $0x1061f4,0x8(%esp)
  1021f8:	00 
  1021f9:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  102200:	00 
  102201:	c7 04 24 14 62 10 00 	movl   $0x106214,(%esp)
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
  1022b0:	c7 44 24 0c 34 62 10 	movl   $0x106234,0xc(%esp)
  1022b7:	00 
  1022b8:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  1022bf:	00 
  1022c0:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1022c7:	00 
  1022c8:	c7 04 24 5f 62 10 00 	movl   $0x10625f,(%esp)
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
  102322:	c7 44 24 08 6c 62 10 	movl   $0x10626c,0x8(%esp)
  102329:	00 
  10232a:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
  102331:	00 
  102332:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  10238f:	c7 44 24 08 84 62 10 	movl   $0x106284,0x8(%esp)
  102396:	00 
  102397:	c7 44 24 04 40 00 00 	movl   $0x40,0x4(%esp)
  10239e:	00 
  10239f:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  10245d:	c7 45 e4 8c 62 10 00 	movl   $0x10628c,-0x1c(%ebp)
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
  102593:	c7 44 24 0c 9b 62 10 	movl   $0x10629b,0xc(%esp)
  10259a:	00 
  10259b:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  1025a2:	00 
  1025a3:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1025aa:	00 
  1025ab:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  1025eb:	c7 44 24 0c ae 62 10 	movl   $0x1062ae,0xc(%esp)
  1025f2:	00 
  1025f3:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  1025fa:	00 
  1025fb:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  102602:	00 
  102603:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  102637:	c7 04 24 c2 62 10 00 	movl   $0x1062c2,(%esp)
  10263e:	e8 ac 2b 00 00       	call   1051ef <cprintf>
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
  1026a3:	c7 44 24 0c c6 62 10 	movl   $0x1062c6,0xc(%esp)
  1026aa:	00 
  1026ab:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  1026b2:	00 
  1026b3:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  1026ba:	00 
  1026bb:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  102701:	c7 44 24 0c e0 62 10 	movl   $0x1062e0,0xc(%esp)
  102708:	00 
  102709:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  102710:	00 
  102711:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  102718:	00 
  102719:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  10276f:	c7 44 24 0c 04 63 10 	movl   $0x106304,0xc(%esp)
  102776:	00 
  102777:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  10277e:	00 
  10277f:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  102786:	00 
  102787:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  1027bc:	c7 44 24 0c 34 63 10 	movl   $0x106334,0xc(%esp)
  1027c3:	00 
  1027c4:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  1027cb:	00 
  1027cc:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  1027d3:	00 
  1027d4:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  102863:	c7 44 24 0c 65 63 10 	movl   $0x106365,0xc(%esp)
  10286a:	00 
  10286b:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  102872:	00 
  102873:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  10287a:	00 
  10287b:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  1028ba:	c7 44 24 0c 7a 63 10 	movl   $0x10637a,0xc(%esp)
  1028c1:	00 
  1028c2:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  1028c9:	00 
  1028ca:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  1028d1:	00 
  1028d2:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  102918:	c7 44 24 0c 90 63 10 	movl   $0x106390,0xc(%esp)
  10291f:	00 
  102920:	c7 44 24 08 4a 62 10 	movl   $0x10624a,0x8(%esp)
  102927:	00 
  102928:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  10292f:	00 
  102930:	c7 04 24 74 62 10 00 	movl   $0x106274,(%esp)
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
  102958:	c7 04 24 b1 63 10 00 	movl   $0x1063b1,(%esp)
  10295f:	e8 8b 28 00 00       	call   1051ef <cprintf>
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
  1029ce:	c7 44 24 0c d0 63 10 	movl   $0x1063d0,0xc(%esp)
  1029d5:	00 
  1029d6:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  1029dd:	00 
  1029de:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1029e5:	00 
  1029e6:	c7 04 24 fb 63 10 00 	movl   $0x1063fb,(%esp)
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
  102a02:	3d 00 70 10 00       	cmp    $0x107000,%eax
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
  102a1c:	c7 04 24 08 64 10 00 	movl   $0x106408,(%esp)
  102a23:	e8 c7 27 00 00       	call   1051ef <cprintf>
  102a28:	eb 0c                	jmp    102a36 <proc_print+0x27>
	else
		cprintf("release lock ");
  102a2a:	c7 04 24 16 64 10 00 	movl   $0x106416,(%esp)
  102a31:	e8 b9 27 00 00       	call   1051ef <cprintf>
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
  102a59:	c7 04 24 24 64 10 00 	movl   $0x106424,(%esp)
  102a60:	e8 8a 27 00 00       	call   1051ef <cprintf>
  102a65:	eb 1f                	jmp    102a86 <proc_print+0x77>
	else
		cprintf("on cpu %d\n", cpu_cur()->id);
  102a67:	e8 38 ff ff ff       	call   1029a4 <cpu_cur>
  102a6c:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  102a73:	0f b6 c0             	movzbl %al,%eax
  102a76:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a7a:	c7 04 24 3b 64 10 00 	movl   $0x10643b,(%esp)
  102a81:	e8 69 27 00 00       	call   1051ef <cprintf>
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
  102aa3:	c7 44 24 04 46 64 10 	movl   $0x106446,0x4(%esp)
  102aaa:	00 
  102aab:	c7 04 24 c0 ea 30 00 	movl   $0x30eac0,(%esp)
  102ab2:	e8 22 f8 ff ff       	call   1022d9 <spinlock_init_>

	queue.count= 0;
  102ab7:	c7 05 f8 ea 30 00 00 	movl   $0x0,0x30eaf8
  102abe:	00 00 00 
	queue.head = NULL;
  102ac1:	c7 05 fc ea 30 00 00 	movl   $0x0,0x30eafc
  102ac8:	00 00 00 
	queue.tail= NULL;
  102acb:	c7 05 00 eb 30 00 00 	movl   $0x0,0x30eb00
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
  102af3:	e9 7f 01 00 00       	jmp    102c77 <proc_alloc+0x19d>
  102af8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102afb:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  102afe:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
  102b03:	83 c0 08             	add    $0x8,%eax
  102b06:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b09:	76 15                	jbe    102b20 <proc_alloc+0x46>
  102b0b:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
  102b10:	8b 15 a4 e3 10 00    	mov    0x10e3a4,%edx
  102b16:	c1 e2 03             	shl    $0x3,%edx
  102b19:	01 d0                	add    %edx,%eax
  102b1b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b1e:	72 24                	jb     102b44 <proc_alloc+0x6a>
  102b20:	c7 44 24 0c 54 64 10 	movl   $0x106454,0xc(%esp)
  102b27:	00 
  102b28:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  102b2f:	00 
  102b30:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
  102b37:	00 
  102b38:	c7 04 24 8b 64 10 00 	movl   $0x10648b,(%esp)
  102b3f:	e8 3d d9 ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  102b44:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
  102b49:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  102b4e:	c1 ea 0c             	shr    $0xc,%edx
  102b51:	c1 e2 03             	shl    $0x3,%edx
  102b54:	01 d0                	add    %edx,%eax
  102b56:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b59:	72 3b                	jb     102b96 <proc_alloc+0xbc>
  102b5b:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
  102b60:	ba 0f eb 30 00       	mov    $0x30eb0f,%edx
  102b65:	c1 ea 0c             	shr    $0xc,%edx
  102b68:	c1 e2 03             	shl    $0x3,%edx
  102b6b:	01 d0                	add    %edx,%eax
  102b6d:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b70:	77 24                	ja     102b96 <proc_alloc+0xbc>
  102b72:	c7 44 24 0c 98 64 10 	movl   $0x106498,0xc(%esp)
  102b79:	00 
  102b7a:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  102b81:	00 
  102b82:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102b89:	00 
  102b8a:	c7 04 24 8b 64 10 00 	movl   $0x10648b,(%esp)
  102b91:	e8 eb d8 ff ff       	call   100481 <debug_panic>

	lockadd(&pi->refcount, 1);
  102b96:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b99:	83 c0 04             	add    $0x4,%eax
  102b9c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102ba3:	00 
  102ba4:	89 04 24             	mov    %eax,(%esp)
  102ba7:	e8 e0 fd ff ff       	call   10298c <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  102bac:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102baf:	a1 f8 e3 30 00       	mov    0x30e3f8,%eax
  102bb4:	89 d1                	mov    %edx,%ecx
  102bb6:	29 c1                	sub    %eax,%ecx
  102bb8:	89 c8                	mov    %ecx,%eax
  102bba:	c1 f8 03             	sar    $0x3,%eax
  102bbd:	c1 e0 0c             	shl    $0xc,%eax
  102bc0:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  102bc3:	c7 44 24 08 a0 06 00 	movl   $0x6a0,0x8(%esp)
  102bca:	00 
  102bcb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102bd2:	00 
  102bd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bd6:	89 04 24             	mov    %eax,(%esp)
  102bd9:	e8 f6 27 00 00       	call   1053d4 <memset>

	spinlock_init(&cp->lock);
  102bde:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102be1:	c7 44 24 08 52 00 00 	movl   $0x52,0x8(%esp)
  102be8:	00 
  102be9:	c7 44 24 04 46 64 10 	movl   $0x106446,0x4(%esp)
  102bf0:	00 
  102bf1:	89 04 24             	mov    %eax,(%esp)
  102bf4:	e8 e0 f6 ff ff       	call   1022d9 <spinlock_init_>
	cp->parent = p;
  102bf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bfc:	8b 55 08             	mov    0x8(%ebp),%edx
  102bff:	89 50 3c             	mov    %edx,0x3c(%eax)
	cp->state = PROC_STOP;
  102c02:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c05:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  102c0c:	00 00 00 

	cp->num = count++;
  102c0f:	a1 c0 a0 10 00       	mov    0x10a0c0,%eax
  102c14:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102c17:	89 42 38             	mov    %eax,0x38(%edx)
  102c1a:	83 c0 01             	add    $0x1,%eax
  102c1d:	a3 c0 a0 10 00       	mov    %eax,0x10a0c0

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  102c22:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c25:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  102c2c:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  102c2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c31:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  102c38:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  102c3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c3d:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  102c44:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  102c46:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c49:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  102c50:	23 00 

	cp->sv.tf.eflags = FL_IF;
  102c52:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c55:	c7 80 90 04 00 00 00 	movl   $0x200,0x490(%eax)
  102c5c:	02 00 00 

	if (p)
  102c5f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102c63:	74 0f                	je     102c74 <proc_alloc+0x19a>
		p->child[cn] = cp;
  102c65:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c68:	8b 45 08             	mov    0x8(%ebp),%eax
  102c6b:	8d 4a 10             	lea    0x10(%edx),%ecx
  102c6e:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102c71:	89 14 88             	mov    %edx,(%eax,%ecx,4)
	return cp;
  102c74:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102c77:	c9                   	leave  
  102c78:	c3                   	ret    

00102c79 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  102c79:	55                   	push   %ebp
  102c7a:	89 e5                	mov    %esp,%ebp
  102c7c:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_ready not implemented");

 	//cprintf("in ready, child num:%d\n", queue.count);
	if(p == NULL)
  102c7f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102c83:	75 1c                	jne    102ca1 <proc_ready+0x28>
		panic("proc_ready's p is null!");
  102c85:	c7 44 24 08 c9 64 10 	movl   $0x1064c9,0x8(%esp)
  102c8c:	00 
  102c8d:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
  102c94:	00 
  102c95:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  102c9c:	e8 e0 d7 ff ff       	call   100481 <debug_panic>
	
	assert(p->state != PROC_READY);
  102ca1:	8b 45 08             	mov    0x8(%ebp),%eax
  102ca4:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102caa:	83 f8 01             	cmp    $0x1,%eax
  102cad:	75 24                	jne    102cd3 <proc_ready+0x5a>
  102caf:	c7 44 24 0c e1 64 10 	movl   $0x1064e1,0xc(%esp)
  102cb6:	00 
  102cb7:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  102cbe:	00 
  102cbf:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
  102cc6:	00 
  102cc7:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  102cce:	e8 ae d7 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102cd3:	8b 45 08             	mov    0x8(%ebp),%eax
  102cd6:	89 04 24             	mov    %eax,(%esp)
  102cd9:	e8 2f f6 ff ff       	call   10230d <spinlock_acquire>
	p->state = PROC_READY;
  102cde:	8b 45 08             	mov    0x8(%ebp),%eax
  102ce1:	c7 80 40 04 00 00 01 	movl   $0x1,0x440(%eax)
  102ce8:	00 00 00 
	spinlock_acquire(&queue.lock);
  102ceb:	c7 04 24 c0 ea 30 00 	movl   $0x30eac0,(%esp)
  102cf2:	e8 16 f6 ff ff       	call   10230d <spinlock_acquire>
	// if there is no proc in queue now
	if(queue.count == 0){
  102cf7:	a1 f8 ea 30 00       	mov    0x30eaf8,%eax
  102cfc:	85 c0                	test   %eax,%eax
  102cfe:	75 1f                	jne    102d1f <proc_ready+0xa6>
		//cprintf("in ready = 0\n");
		queue.count++;
  102d00:	a1 f8 ea 30 00       	mov    0x30eaf8,%eax
  102d05:	83 c0 01             	add    $0x1,%eax
  102d08:	a3 f8 ea 30 00       	mov    %eax,0x30eaf8
		queue.head = p;
  102d0d:	8b 45 08             	mov    0x8(%ebp),%eax
  102d10:	a3 fc ea 30 00       	mov    %eax,0x30eafc
		queue.tail = p;
  102d15:	8b 45 08             	mov    0x8(%ebp),%eax
  102d18:	a3 00 eb 30 00       	mov    %eax,0x30eb00
  102d1d:	eb 24                	jmp    102d43 <proc_ready+0xca>
	}

	// insert it to the head of the queue
	else{
		//cprintf("in ready != 0\n");
		p->readynext = queue.head;
  102d1f:	8b 15 fc ea 30 00    	mov    0x30eafc,%edx
  102d25:	8b 45 08             	mov    0x8(%ebp),%eax
  102d28:	89 90 44 04 00 00    	mov    %edx,0x444(%eax)
		queue.head = p;
  102d2e:	8b 45 08             	mov    0x8(%ebp),%eax
  102d31:	a3 fc ea 30 00       	mov    %eax,0x30eafc
		queue.count += 1;
  102d36:	a1 f8 ea 30 00       	mov    0x30eaf8,%eax
  102d3b:	83 c0 01             	add    $0x1,%eax
  102d3e:	a3 f8 ea 30 00       	mov    %eax,0x30eaf8
		//spinlock_release(&queue.lock);
		//proc_print(RELEASE, p);
		//spinlock_release(&p->lock);
	}

	spinlock_release(&p->lock);
  102d43:	8b 45 08             	mov    0x8(%ebp),%eax
  102d46:	89 04 24             	mov    %eax,(%esp)
  102d49:	e8 2c f6 ff ff       	call   10237a <spinlock_release>
	spinlock_release(&queue.lock);
  102d4e:	c7 04 24 c0 ea 30 00 	movl   $0x30eac0,(%esp)
  102d55:	e8 20 f6 ff ff       	call   10237a <spinlock_release>
	return;
	
}
  102d5a:	c9                   	leave  
  102d5b:	c3                   	ret    

00102d5c <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  102d5c:	55                   	push   %ebp
  102d5d:	89 e5                	mov    %esp,%ebp
  102d5f:	83 ec 18             	sub    $0x18,%esp
	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102d62:	8b 45 08             	mov    0x8(%ebp),%eax
  102d65:	89 04 24             	mov    %eax,(%esp)
  102d68:	e8 a0 f5 ff ff       	call   10230d <spinlock_acquire>

	switch(entry){
  102d6d:	8b 45 10             	mov    0x10(%ebp),%eax
  102d70:	85 c0                	test   %eax,%eax
  102d72:	74 2c                	je     102da0 <proc_save+0x44>
  102d74:	83 f8 01             	cmp    $0x1,%eax
  102d77:	74 36                	je     102daf <proc_save+0x53>
  102d79:	83 f8 ff             	cmp    $0xffffffff,%eax
  102d7c:	75 53                	jne    102dd1 <proc_save+0x75>
		case -1:		
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  102d7e:	8b 45 08             	mov    0x8(%ebp),%eax
  102d81:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102d87:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102d8e:	00 
  102d8f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d92:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d96:	89 14 24             	mov    %edx,(%esp)
  102d99:	e8 aa 26 00 00       	call   105448 <memmove>
			break;
  102d9e:	eb 4d                	jmp    102ded <proc_save+0x91>
		case 0:
			tf->eip = (uintptr_t)((char*)tf->eip - 2);
  102da0:	8b 45 0c             	mov    0xc(%ebp),%eax
  102da3:	8b 40 38             	mov    0x38(%eax),%eax
  102da6:	8d 50 fe             	lea    -0x2(%eax),%edx
  102da9:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dac:	89 50 38             	mov    %edx,0x38(%eax)
		case 1:
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  102daf:	8b 45 08             	mov    0x8(%ebp),%eax
  102db2:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102db8:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102dbf:	00 
  102dc0:	8b 45 0c             	mov    0xc(%ebp),%eax
  102dc3:	89 44 24 04          	mov    %eax,0x4(%esp)
  102dc7:	89 14 24             	mov    %edx,(%esp)
  102dca:	e8 79 26 00 00       	call   105448 <memmove>
			break;
  102dcf:	eb 1c                	jmp    102ded <proc_save+0x91>
		default:
			panic("wrong entry!\n");
  102dd1:	c7 44 24 08 f8 64 10 	movl   $0x1064f8,0x8(%esp)
  102dd8:	00 
  102dd9:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
  102de0:	00 
  102de1:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  102de8:	e8 94 d6 ff ff       	call   100481 <debug_panic>
	}

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  102ded:	8b 45 08             	mov    0x8(%ebp),%eax
  102df0:	89 04 24             	mov    %eax,(%esp)
  102df3:	e8 82 f5 ff ff       	call   10237a <spinlock_release>
}
  102df8:	c9                   	leave  
  102df9:	c3                   	ret    

00102dfa <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  102dfa:	55                   	push   %ebp
  102dfb:	89 e5                	mov    %esp,%ebp
  102dfd:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");

	if(p == NULL || p->state != PROC_RUN)
  102e00:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102e04:	74 0e                	je     102e14 <proc_wait+0x1a>
  102e06:	8b 45 08             	mov    0x8(%ebp),%eax
  102e09:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102e0f:	83 f8 02             	cmp    $0x2,%eax
  102e12:	74 1c                	je     102e30 <proc_wait+0x36>
		panic("parent proc is not running!");
  102e14:	c7 44 24 08 06 65 10 	movl   $0x106506,0x8(%esp)
  102e1b:	00 
  102e1c:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  102e23:	00 
  102e24:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  102e2b:	e8 51 d6 ff ff       	call   100481 <debug_panic>
	if(cp == NULL)
  102e30:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102e34:	75 1c                	jne    102e52 <proc_wait+0x58>
		panic("no child proc!");
  102e36:	c7 44 24 08 22 65 10 	movl   $0x106522,0x8(%esp)
  102e3d:	00 
  102e3e:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
  102e45:	00 
  102e46:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  102e4d:	e8 2f d6 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102e52:	8b 45 08             	mov    0x8(%ebp),%eax
  102e55:	89 04 24             	mov    %eax,(%esp)
  102e58:	e8 b0 f4 ff ff       	call   10230d <spinlock_acquire>
	p->state = PROC_WAIT;
  102e5d:	8b 45 08             	mov    0x8(%ebp),%eax
  102e60:	c7 80 40 04 00 00 03 	movl   $0x3,0x440(%eax)
  102e67:	00 00 00 
	p->waitchild = cp;
  102e6a:	8b 45 08             	mov    0x8(%ebp),%eax
  102e6d:	8b 55 0c             	mov    0xc(%ebp),%edx
  102e70:	89 90 4c 04 00 00    	mov    %edx,0x44c(%eax)
	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  102e76:	8b 45 08             	mov    0x8(%ebp),%eax
  102e79:	89 04 24             	mov    %eax,(%esp)
  102e7c:	e8 f9 f4 ff ff       	call   10237a <spinlock_release>
	
	proc_save(p, tf, 0);
  102e81:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102e88:	00 
  102e89:	8b 45 10             	mov    0x10(%ebp),%eax
  102e8c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e90:	8b 45 08             	mov    0x8(%ebp),%eax
  102e93:	89 04 24             	mov    %eax,(%esp)
  102e96:	e8 c1 fe ff ff       	call   102d5c <proc_save>

	assert(cp->state != PROC_STOP);
  102e9b:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e9e:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102ea4:	85 c0                	test   %eax,%eax
  102ea6:	75 24                	jne    102ecc <proc_wait+0xd2>
  102ea8:	c7 44 24 0c 31 65 10 	movl   $0x106531,0xc(%esp)
  102eaf:	00 
  102eb0:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  102eb7:	00 
  102eb8:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  102ebf:	00 
  102ec0:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  102ec7:	e8 b5 d5 ff ff       	call   100481 <debug_panic>
	
	proc_sched();
  102ecc:	e8 00 00 00 00       	call   102ed1 <proc_sched>

00102ed1 <proc_sched>:
	
}

void gcc_noreturn
proc_sched(void)
{
  102ed1:	55                   	push   %ebp
  102ed2:	89 e5                	mov    %esp,%ebp
  102ed4:	83 ec 28             	sub    $0x28,%esp
			
		// if there is no ready process in queue
		// just wait

		//proc_print(ACQUIRE, NULL);
		spinlock_acquire(&queue.lock);
  102ed7:	c7 04 24 c0 ea 30 00 	movl   $0x30eac0,(%esp)
  102ede:	e8 2a f4 ff ff       	call   10230d <spinlock_acquire>

		if(queue.count != 0){
  102ee3:	a1 f8 ea 30 00       	mov    0x30eaf8,%eax
  102ee8:	85 c0                	test   %eax,%eax
  102eea:	0f 84 8e 00 00 00    	je     102f7e <proc_sched+0xad>
			// if there is just one ready process
			if(queue.count == 1){
  102ef0:	a1 f8 ea 30 00       	mov    0x30eaf8,%eax
  102ef5:	83 f8 01             	cmp    $0x1,%eax
  102ef8:	75 28                	jne    102f22 <proc_sched+0x51>
				//cprintf("in sched queue.count == 1\n");
				run = queue.head;
  102efa:	a1 fc ea 30 00       	mov    0x30eafc,%eax
  102eff:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.head = queue.tail = NULL;
  102f02:	c7 05 00 eb 30 00 00 	movl   $0x0,0x30eb00
  102f09:	00 00 00 
  102f0c:	a1 00 eb 30 00       	mov    0x30eb00,%eax
  102f11:	a3 fc ea 30 00       	mov    %eax,0x30eafc
				queue.count = 0;	
  102f16:	c7 05 f8 ea 30 00 00 	movl   $0x0,0x30eaf8
  102f1d:	00 00 00 
  102f20:	eb 45                	jmp    102f67 <proc_sched+0x96>
			
			
			// if there is more than one ready processes
			else{
				//cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
  102f22:	a1 fc ea 30 00       	mov    0x30eafc,%eax
  102f27:	89 45 f4             	mov    %eax,-0xc(%ebp)
				while(before_tail->readynext != queue.tail){
  102f2a:	eb 0c                	jmp    102f38 <proc_sched+0x67>
					before_tail = before_tail->readynext;
  102f2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f2f:	8b 80 44 04 00 00    	mov    0x444(%eax),%eax
  102f35:	89 45 f4             	mov    %eax,-0xc(%ebp)
			
			// if there is more than one ready processes
			else{
				//cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
				while(before_tail->readynext != queue.tail){
  102f38:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f3b:	8b 90 44 04 00 00    	mov    0x444(%eax),%edx
  102f41:	a1 00 eb 30 00       	mov    0x30eb00,%eax
  102f46:	39 c2                	cmp    %eax,%edx
  102f48:	75 e2                	jne    102f2c <proc_sched+0x5b>
					before_tail = before_tail->readynext;
				}	
				run = queue.tail;
  102f4a:	a1 00 eb 30 00       	mov    0x30eb00,%eax
  102f4f:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.tail = before_tail;
  102f52:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f55:	a3 00 eb 30 00       	mov    %eax,0x30eb00
				queue.count--;				
  102f5a:	a1 f8 ea 30 00       	mov    0x30eaf8,%eax
  102f5f:	83 e8 01             	sub    $0x1,%eax
  102f62:	a3 f8 ea 30 00       	mov    %eax,0x30eaf8
				queue.count--;
			}
			*/
			
	
			spinlock_release(&queue.lock);
  102f67:	c7 04 24 c0 ea 30 00 	movl   $0x30eac0,(%esp)
  102f6e:	e8 07 f4 ff ff       	call   10237a <spinlock_release>
			proc_run(run);
  102f73:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102f76:	89 04 24             	mov    %eax,(%esp)
  102f79:	e8 16 00 00 00       	call   102f94 <proc_run>
		}
		spinlock_release(&queue.lock);
  102f7e:	c7 04 24 c0 ea 30 00 	movl   $0x30eac0,(%esp)
  102f85:	e8 f0 f3 ff ff       	call   10237a <spinlock_release>
		pause();
  102f8a:	e8 0e fa ff ff       	call   10299d <pause>
	}
  102f8f:	e9 43 ff ff ff       	jmp    102ed7 <proc_sched+0x6>

00102f94 <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  102f94:	55                   	push   %ebp
  102f95:	89 e5                	mov    %esp,%ebp
  102f97:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");

	//cprintf("proc %x is running on cpu:%d\n", p, cpu_cur()->id);
	
	if(p == NULL)
  102f9a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102f9e:	75 1c                	jne    102fbc <proc_run+0x28>
		panic("proc_run's p is null!");
  102fa0:	c7 44 24 08 48 65 10 	movl   $0x106548,0x8(%esp)
  102fa7:	00 
  102fa8:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
  102faf:	00 
  102fb0:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  102fb7:	e8 c5 d4 ff ff       	call   100481 <debug_panic>

	assert(p->state == PROC_READY);
  102fbc:	8b 45 08             	mov    0x8(%ebp),%eax
  102fbf:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102fc5:	83 f8 01             	cmp    $0x1,%eax
  102fc8:	74 24                	je     102fee <proc_run+0x5a>
  102fca:	c7 44 24 0c 5e 65 10 	movl   $0x10655e,0xc(%esp)
  102fd1:	00 
  102fd2:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  102fd9:	00 
  102fda:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
  102fe1:	00 
  102fe2:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  102fe9:	e8 93 d4 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102fee:	8b 45 08             	mov    0x8(%ebp),%eax
  102ff1:	89 04 24             	mov    %eax,(%esp)
  102ff4:	e8 14 f3 ff ff       	call   10230d <spinlock_acquire>

	cpu* c = cpu_cur();
  102ff9:	e8 a6 f9 ff ff       	call   1029a4 <cpu_cur>
  102ffe:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->proc = p;
  103001:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103004:	8b 55 08             	mov    0x8(%ebp),%edx
  103007:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	p->state = PROC_RUN;
  10300d:	8b 45 08             	mov    0x8(%ebp),%eax
  103010:	c7 80 40 04 00 00 02 	movl   $0x2,0x440(%eax)
  103017:	00 00 00 
	p->runcpu = c;
  10301a:	8b 45 08             	mov    0x8(%ebp),%eax
  10301d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103020:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  103026:	8b 45 08             	mov    0x8(%ebp),%eax
  103029:	89 04 24             	mov    %eax,(%esp)
  10302c:	e8 49 f3 ff ff       	call   10237a <spinlock_release>

	//cprintf("eip = %d\n", p->sv.tf.eip);
	
	trap_return(&p->sv.tf);
  103031:	8b 45 08             	mov    0x8(%ebp),%eax
  103034:	05 50 04 00 00       	add    $0x450,%eax
  103039:	89 04 24             	mov    %eax,(%esp)
  10303c:	e8 af 50 00 00       	call   1080f0 <trap_return>

00103041 <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  103041:	55                   	push   %ebp
  103042:	89 e5                	mov    %esp,%ebp
  103044:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_yield not implemented");

 	//cprintf("in yield\n");
	proc* cur_proc = cpu_cur()->proc;
  103047:	e8 58 f9 ff ff       	call   1029a4 <cpu_cur>
  10304c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103052:	89 45 f4             	mov    %eax,-0xc(%ebp)
	proc_save(cur_proc, tf, 1);
  103055:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10305c:	00 
  10305d:	8b 45 08             	mov    0x8(%ebp),%eax
  103060:	89 44 24 04          	mov    %eax,0x4(%esp)
  103064:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103067:	89 04 24             	mov    %eax,(%esp)
  10306a:	e8 ed fc ff ff       	call   102d5c <proc_save>
	proc_ready(cur_proc);
  10306f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103072:	89 04 24             	mov    %eax,(%esp)
  103075:	e8 ff fb ff ff       	call   102c79 <proc_ready>
	proc_sched();
  10307a:	e8 52 fe ff ff       	call   102ed1 <proc_sched>

0010307f <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  10307f:	55                   	push   %ebp
  103080:	89 e5                	mov    %esp,%ebp
  103082:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_ret not implemented");

	proc* proc_child = proc_cur();
  103085:	e8 1a f9 ff ff       	call   1029a4 <cpu_cur>
  10308a:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103090:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_parent = proc_child->parent;
  103093:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103096:	8b 40 3c             	mov    0x3c(%eax),%eax
  103099:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child->state != PROC_STOP);
  10309c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10309f:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  1030a5:	85 c0                	test   %eax,%eax
  1030a7:	75 24                	jne    1030cd <proc_ret+0x4e>
  1030a9:	c7 44 24 0c 78 65 10 	movl   $0x106578,0xc(%esp)
  1030b0:	00 
  1030b1:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  1030b8:	00 
  1030b9:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
  1030c0:	00 
  1030c1:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  1030c8:	e8 b4 d3 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  1030cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030d0:	89 04 24             	mov    %eax,(%esp)
  1030d3:	e8 35 f2 ff ff       	call   10230d <spinlock_acquire>
	proc_child->state = PROC_STOP;
  1030d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030db:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  1030e2:	00 00 00 
	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  1030e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030e8:	89 04 24             	mov    %eax,(%esp)
  1030eb:	e8 8a f2 ff ff       	call   10237a <spinlock_release>

	proc_save(proc_child, tf, entry);
  1030f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1030f3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1030f7:	8b 45 08             	mov    0x8(%ebp),%eax
  1030fa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1030fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103101:	89 04 24             	mov    %eax,(%esp)
  103104:	e8 53 fc ff ff       	call   102d5c <proc_save>

	if((proc_parent->state == PROC_WAIT) && (proc_parent->waitchild == proc_child) )
  103109:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10310c:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103112:	83 f8 03             	cmp    $0x3,%eax
  103115:	75 19                	jne    103130 <proc_ret+0xb1>
  103117:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10311a:	8b 80 4c 04 00 00    	mov    0x44c(%eax),%eax
  103120:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  103123:	75 0b                	jne    103130 <proc_ret+0xb1>
		proc_ready(proc_parent);
  103125:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103128:	89 04 24             	mov    %eax,(%esp)
  10312b:	e8 49 fb ff ff       	call   102c79 <proc_ready>

	proc_sched();
  103130:	e8 9c fd ff ff       	call   102ed1 <proc_sched>

00103135 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  103135:	55                   	push   %ebp
  103136:	89 e5                	mov    %esp,%ebp
  103138:	57                   	push   %edi
  103139:	56                   	push   %esi
  10313a:	53                   	push   %ebx
  10313b:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  103141:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103148:	00 00 00 
  10314b:	e9 06 01 00 00       	jmp    103256 <proc_check+0x121>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  103150:	b8 30 a3 10 00       	mov    $0x10a330,%eax
  103155:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  10315b:	83 c2 01             	add    $0x1,%edx
  10315e:	c1 e2 0c             	shl    $0xc,%edx
  103161:	01 d0                	add    %edx,%eax
  103163:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		*--esp = i;	// push argument to child() function
  103169:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  103170:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  103176:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  10317c:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  10317e:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  103185:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  10318b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  103191:	b8 6e 36 10 00       	mov    $0x10366e,%eax
  103196:	a3 18 a1 10 00       	mov    %eax,0x10a118
		child_state.tf.esp = (uint32_t) esp;
  10319b:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  1031a1:	a3 24 a1 10 00       	mov    %eax,0x10a124

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  1031a6:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1031ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1031b0:	c7 04 24 97 65 10 00 	movl   $0x106597,(%esp)
  1031b7:	e8 33 20 00 00       	call   1051ef <cprintf>

		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  1031bc:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1031c2:	0f b7 d0             	movzwl %ax,%edx
  1031c5:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  1031cc:	7f 07                	jg     1031d5 <proc_check+0xa0>
  1031ce:	b8 10 10 00 00       	mov    $0x1010,%eax
  1031d3:	eb 05                	jmp    1031da <proc_check+0xa5>
  1031d5:	b8 00 10 00 00       	mov    $0x1000,%eax
  1031da:	89 85 54 ff ff ff    	mov    %eax,-0xac(%ebp)
  1031e0:	66 89 95 52 ff ff ff 	mov    %dx,-0xae(%ebp)
  1031e7:	c7 85 4c ff ff ff e0 	movl   $0x10a0e0,-0xb4(%ebp)
  1031ee:	a0 10 00 
  1031f1:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
  1031f8:	00 00 00 
  1031fb:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
  103202:	00 00 00 
  103205:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
  10320c:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  10320f:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
  103215:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103218:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
  10321e:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
  103225:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
  10322b:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
  103231:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
  103237:	cd 30                	int    $0x30
			NULL, NULL, 0);
		
		cprintf("i == %d complete!\n", i);
  103239:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10323f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103243:	c7 04 24 aa 65 10 00 	movl   $0x1065aa,(%esp)
  10324a:	e8 a0 1f 00 00       	call   1051ef <cprintf>
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  10324f:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103256:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  10325d:	0f 8e ed fe ff ff    	jle    103150 <proc_check+0x1b>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  103263:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10326a:	00 00 00 
  10326d:	e9 89 00 00 00       	jmp    1032fb <proc_check+0x1c6>
		cprintf("waiting for child %d\n", i);
  103272:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103278:	89 44 24 04          	mov    %eax,0x4(%esp)
  10327c:	c7 04 24 bd 65 10 00 	movl   $0x1065bd,(%esp)
  103283:	e8 67 1f 00 00       	call   1051ef <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103288:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10328e:	0f b7 c0             	movzwl %ax,%eax
  103291:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
  103298:	10 00 00 
  10329b:	66 89 85 6a ff ff ff 	mov    %ax,-0x96(%ebp)
  1032a2:	c7 85 64 ff ff ff e0 	movl   $0x10a0e0,-0x9c(%ebp)
  1032a9:	a0 10 00 
  1032ac:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
  1032b3:	00 00 00 
  1032b6:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
  1032bd:	00 00 00 
  1032c0:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
  1032c7:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1032ca:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
  1032d0:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1032d3:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
  1032d9:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
  1032e0:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
  1032e6:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
  1032ec:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
  1032f2:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  1032f4:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  1032fb:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  103302:	0f 8e 6a ff ff ff    	jle    103272 <proc_check+0x13d>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  103308:	c7 04 24 d4 65 10 00 	movl   $0x1065d4,(%esp)
  10330f:	e8 db 1e 00 00       	call   1051ef <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  103314:	c7 04 24 fc 65 10 00 	movl   $0x1065fc,(%esp)
  10331b:	e8 cf 1e 00 00       	call   1051ef <cprintf>
	for (i = 0; i < 4; i++) {
  103320:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103327:	00 00 00 
  10332a:	eb 7d                	jmp    1033a9 <proc_check+0x274>
		cprintf("spawning child %d\n", i);
  10332c:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103332:	89 44 24 04          	mov    %eax,0x4(%esp)
  103336:	c7 04 24 97 65 10 00 	movl   $0x106597,(%esp)
  10333d:	e8 ad 1e 00 00       	call   1051ef <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  103342:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103348:	0f b7 c0             	movzwl %ax,%eax
  10334b:	c7 45 84 10 00 00 00 	movl   $0x10,-0x7c(%ebp)
  103352:	66 89 45 82          	mov    %ax,-0x7e(%ebp)
  103356:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  10335d:	00 00 00 
  103360:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
  103367:	00 00 00 
  10336a:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
  103371:	00 00 00 
  103374:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
  10337b:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  10337e:	8b 45 84             	mov    -0x7c(%ebp),%eax
  103381:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103384:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
  10338a:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
  10338e:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
  103394:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
  10339a:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
  1033a0:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  1033a2:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  1033a9:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  1033b0:	0f 8e 76 ff ff ff    	jle    10332c <proc_check+0x1f7>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
  1033b6:	c7 04 24 20 66 10 00 	movl   $0x106620,(%esp)
  1033bd:	e8 2d 1e 00 00       	call   1051ef <cprintf>
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  1033c2:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  1033c9:	00 00 00 
  1033cc:	eb 4f                	jmp    10341d <proc_check+0x2e8>
		sys_get(0, i, NULL, NULL, NULL, 0);
  1033ce:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1033d4:	0f b7 c0             	movzwl %ax,%eax
  1033d7:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  1033de:	66 89 45 9a          	mov    %ax,-0x66(%ebp)
  1033e2:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
  1033e9:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  1033f0:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
  1033f7:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1033fe:	8b 45 9c             	mov    -0x64(%ebp),%eax
  103401:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103404:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
  103407:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
  10340b:	8b 75 90             	mov    -0x70(%ebp),%esi
  10340e:	8b 7d 8c             	mov    -0x74(%ebp),%edi
  103411:	8b 4d 88             	mov    -0x78(%ebp),%ecx
  103414:	cd 30                	int    $0x30
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103416:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  10341d:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103424:	7e a8                	jle    1033ce <proc_check+0x299>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  103426:	c7 04 24 48 66 10 00 	movl   $0x106648,(%esp)
  10342d:	e8 bd 1d 00 00       	call   1051ef <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  103432:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103439:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10343c:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103442:	0f b7 c0             	movzwl %ax,%eax
  103445:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
  10344c:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
  103450:	c7 45 ac e0 a0 10 00 	movl   $0x10a0e0,-0x54(%ebp)
  103457:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  10345e:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  103465:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10346c:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  10346f:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103472:	8b 5d ac             	mov    -0x54(%ebp),%ebx
  103475:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
  103479:	8b 75 a8             	mov    -0x58(%ebp),%esi
  10347c:	8b 7d a4             	mov    -0x5c(%ebp),%edi
  10347f:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  103482:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  103484:	a1 34 e3 10 00       	mov    0x10e334,%eax
  103489:	85 c0                	test   %eax,%eax
  10348b:	74 24                	je     1034b1 <proc_check+0x37c>
  10348d:	c7 44 24 0c 6d 66 10 	movl   $0x10666d,0xc(%esp)
  103494:	00 
  103495:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  10349c:	00 
  10349d:	c7 44 24 04 92 01 00 	movl   $0x192,0x4(%esp)
  1034a4:	00 
  1034a5:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  1034ac:	e8 d0 cf ff ff       	call   100481 <debug_panic>
	cprintf("============== tag 1 \n");
  1034b1:	c7 04 24 7f 66 10 00 	movl   $0x10667f,(%esp)
  1034b8:	e8 32 1d 00 00       	call   1051ef <cprintf>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  1034bd:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1034c3:	0f b7 c0             	movzwl %ax,%eax
  1034c6:	c7 45 cc 10 10 00 00 	movl   $0x1010,-0x34(%ebp)
  1034cd:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
  1034d1:	c7 45 c4 e0 a0 10 00 	movl   $0x10a0e0,-0x3c(%ebp)
  1034d8:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
  1034df:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  1034e6:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1034ed:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1034f0:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1034f3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
  1034f6:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  1034fa:	8b 75 c0             	mov    -0x40(%ebp),%esi
  1034fd:	8b 7d bc             	mov    -0x44(%ebp),%edi
  103500:	8b 4d b8             	mov    -0x48(%ebp),%ecx
  103503:	cd 30                	int    $0x30
		//cprintf("(1). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103505:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10350b:	0f b7 c0             	movzwl %ax,%eax
  10350e:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  103515:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
  103519:	c7 45 dc e0 a0 10 00 	movl   $0x10a0e0,-0x24(%ebp)
  103520:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103527:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  10352e:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103535:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103538:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10353b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  10353e:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  103542:	8b 75 d8             	mov    -0x28(%ebp),%esi
  103545:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  103548:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  10354b:	cd 30                	int    $0x30
		//cprintf("(2). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		cprintf("recovargs 0x%x\n",recovargs);
  10354d:	a1 34 e3 10 00       	mov    0x10e334,%eax
  103552:	89 44 24 04          	mov    %eax,0x4(%esp)
  103556:	c7 04 24 96 66 10 00 	movl   $0x106696,(%esp)
  10355d:	e8 8d 1c 00 00       	call   1051ef <cprintf>
		
		if (recovargs) {	// trap recovery needed
  103562:	a1 34 e3 10 00       	mov    0x10e334,%eax
  103567:	85 c0                	test   %eax,%eax
  103569:	74 55                	je     1035c0 <proc_check+0x48b>
			cprintf("i = %d\n", i);
  10356b:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103571:	89 44 24 04          	mov    %eax,0x4(%esp)
  103575:	c7 04 24 a6 66 10 00 	movl   $0x1066a6,(%esp)
  10357c:	e8 6e 1c 00 00       	call   1051ef <cprintf>
			trap_check_args *argss = recovargs;
  103581:	a1 34 e3 10 00       	mov    0x10e334,%eax
  103586:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)
			cprintf("recover from trap %d\n",
  10358c:	a1 10 a1 10 00       	mov    0x10a110,%eax
  103591:	89 44 24 04          	mov    %eax,0x4(%esp)
  103595:	c7 04 24 ae 66 10 00 	movl   $0x1066ae,(%esp)
  10359c:	e8 4e 1c 00 00       	call   1051ef <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) argss->reip;
  1035a1:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  1035a7:	8b 00                	mov    (%eax),%eax
  1035a9:	a3 18 a1 10 00       	mov    %eax,0x10a118
			argss->trapno = child_state.tf.trapno;
  1035ae:	a1 10 a1 10 00       	mov    0x10a110,%eax
  1035b3:	89 c2                	mov    %eax,%edx
  1035b5:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  1035bb:	89 50 04             	mov    %edx,0x4(%eax)
  1035be:	eb 2e                	jmp    1035ee <proc_check+0x4b9>
			//cprintf(">>>>>args->trapno = %d, child_state.tf.trapno = %d\n", 
			//	args->trapno, child_state.tf.trapno);
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  1035c0:	a1 10 a1 10 00       	mov    0x10a110,%eax
  1035c5:	83 f8 30             	cmp    $0x30,%eax
  1035c8:	74 24                	je     1035ee <proc_check+0x4b9>
  1035ca:	c7 44 24 0c c4 66 10 	movl   $0x1066c4,0xc(%esp)
  1035d1:	00 
  1035d2:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  1035d9:	00 
  1035da:	c7 44 24 04 a5 01 00 	movl   $0x1a5,0x4(%esp)
  1035e1:	00 
  1035e2:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  1035e9:	e8 93 ce ff ff       	call   100481 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  1035ee:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1035f4:	8d 50 01             	lea    0x1(%eax),%edx
  1035f7:	89 d0                	mov    %edx,%eax
  1035f9:	c1 f8 1f             	sar    $0x1f,%eax
  1035fc:	c1 e8 1e             	shr    $0x1e,%eax
  1035ff:	01 c2                	add    %eax,%edx
  103601:	83 e2 03             	and    $0x3,%edx
  103604:	89 d1                	mov    %edx,%ecx
  103606:	29 c1                	sub    %eax,%ecx
  103608:	89 c8                	mov    %ecx,%eax
  10360a:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  103610:	a1 10 a1 10 00       	mov    0x10a110,%eax
  103615:	83 f8 30             	cmp    $0x30,%eax
  103618:	0f 85 9f fe ff ff    	jne    1034bd <proc_check+0x388>
	assert(recovargs == NULL);
  10361e:	a1 34 e3 10 00       	mov    0x10e334,%eax
  103623:	85 c0                	test   %eax,%eax
  103625:	74 24                	je     10364b <proc_check+0x516>
  103627:	c7 44 24 0c 6d 66 10 	movl   $0x10666d,0xc(%esp)
  10362e:	00 
  10362f:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  103636:	00 
  103637:	c7 44 24 04 a8 01 00 	movl   $0x1a8,0x4(%esp)
  10363e:	00 
  10363f:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  103646:	e8 36 ce ff ff       	call   100481 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  10364b:	c7 04 24 e8 66 10 00 	movl   $0x1066e8,(%esp)
  103652:	e8 98 1b 00 00       	call   1051ef <cprintf>

	cprintf("proc_check() succeeded!\n");
  103657:	c7 04 24 15 67 10 00 	movl   $0x106715,(%esp)
  10365e:	e8 8c 1b 00 00       	call   1051ef <cprintf>
}
  103663:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  103669:	5b                   	pop    %ebx
  10366a:	5e                   	pop    %esi
  10366b:	5f                   	pop    %edi
  10366c:	5d                   	pop    %ebp
  10366d:	c3                   	ret    

0010366e <child>:

static void child(int n)
{
  10366e:	55                   	push   %ebp
  10366f:	89 e5                	mov    %esp,%ebp
  103671:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  103674:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  103678:	7f 64                	jg     1036de <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  10367a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  103681:	eb 4e                	jmp    1036d1 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  103683:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103686:	89 44 24 08          	mov    %eax,0x8(%esp)
  10368a:	8b 45 08             	mov    0x8(%ebp),%eax
  10368d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103691:	c7 04 24 2e 67 10 00 	movl   $0x10672e,(%esp)
  103698:	e8 52 1b 00 00       	call   1051ef <cprintf>
			while (pingpong != n){
  10369d:	eb 05                	jmp    1036a4 <child+0x36>
				//cprintf("in pingpong = %d\n", pingpong);
				pause();
  10369f:	e8 f9 f2 ff ff       	call   10299d <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n){
  1036a4:	8b 55 08             	mov    0x8(%ebp),%edx
  1036a7:	a1 30 e3 10 00       	mov    0x10e330,%eax
  1036ac:	39 c2                	cmp    %eax,%edx
  1036ae:	75 ef                	jne    10369f <child+0x31>
				//cprintf("in pingpong = %d\n", pingpong);
				pause();
			}
			xchg(&pingpong, !pingpong);
  1036b0:	a1 30 e3 10 00       	mov    0x10e330,%eax
  1036b5:	85 c0                	test   %eax,%eax
  1036b7:	0f 94 c0             	sete   %al
  1036ba:	0f b6 c0             	movzbl %al,%eax
  1036bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036c1:	c7 04 24 30 e3 10 00 	movl   $0x10e330,(%esp)
  1036c8:	e8 a5 f2 ff ff       	call   102972 <xchg>
{
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  1036cd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1036d1:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1036d5:	7e ac                	jle    103683 <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  1036d7:	b8 03 00 00 00       	mov    $0x3,%eax
  1036dc:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  1036de:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1036e5:	eb 47                	jmp    10372e <child+0xc0>
		//cprintf("in child %d count %d\n", n, i);
		cprintf("child num:%d\n", queue.count);
  1036e7:	a1 f8 ea 30 00       	mov    0x30eaf8,%eax
  1036ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036f0:	c7 04 24 44 67 10 00 	movl   $0x106744,(%esp)
  1036f7:	e8 f3 1a 00 00       	call   1051ef <cprintf>
		
		while (pingpong != n){
  1036fc:	eb 05                	jmp    103703 <child+0x95>
			//cprintf("in pingpong = %d\n", pingpong);
			pause();
  1036fe:	e8 9a f2 ff ff       	call   10299d <pause>
	int i;
	for (i = 0; i < 10; i++) {
		//cprintf("in child %d count %d\n", n, i);
		cprintf("child num:%d\n", queue.count);
		
		while (pingpong != n){
  103703:	8b 55 08             	mov    0x8(%ebp),%edx
  103706:	a1 30 e3 10 00       	mov    0x10e330,%eax
  10370b:	39 c2                	cmp    %eax,%edx
  10370d:	75 ef                	jne    1036fe <child+0x90>
			//cprintf("in pingpong = %d\n", pingpong);
			pause();
		}
		xchg(&pingpong, (pingpong + 1) % 4);
  10370f:	a1 30 e3 10 00       	mov    0x10e330,%eax
  103714:	83 c0 01             	add    $0x1,%eax
  103717:	83 e0 03             	and    $0x3,%eax
  10371a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10371e:	c7 04 24 30 e3 10 00 	movl   $0x10e330,(%esp)
  103725:	e8 48 f2 ff ff       	call   102972 <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  10372a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10372e:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  103732:	7e b3                	jle    1036e7 <child+0x79>
  103734:	b8 03 00 00 00       	mov    $0x3,%eax
  103739:	cd 30                	int    $0x30
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...

	cprintf("child get last test\n");
  10373b:	c7 04 24 52 67 10 00 	movl   $0x106752,(%esp)
  103742:	e8 a8 1a 00 00       	call   1051ef <cprintf>
	if (n == 0) {
  103747:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10374b:	75 6d                	jne    1037ba <child+0x14c>
		assert(recovargs == NULL);
  10374d:	a1 34 e3 10 00       	mov    0x10e334,%eax
  103752:	85 c0                	test   %eax,%eax
  103754:	74 24                	je     10377a <child+0x10c>
  103756:	c7 44 24 0c 6d 66 10 	movl   $0x10666d,0xc(%esp)
  10375d:	00 
  10375e:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  103765:	00 
  103766:	c7 44 24 04 d5 01 00 	movl   $0x1d5,0x4(%esp)
  10376d:	00 
  10376e:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  103775:	e8 07 cd ff ff       	call   100481 <debug_panic>
		trap_check(&recovargs);
  10377a:	c7 04 24 34 e3 10 00 	movl   $0x10e334,(%esp)
  103781:	e8 a7 e2 ff ff       	call   101a2d <trap_check>
		assert(recovargs == NULL);
  103786:	a1 34 e3 10 00       	mov    0x10e334,%eax
  10378b:	85 c0                	test   %eax,%eax
  10378d:	74 24                	je     1037b3 <child+0x145>
  10378f:	c7 44 24 0c 6d 66 10 	movl   $0x10666d,0xc(%esp)
  103796:	00 
  103797:	c7 44 24 08 e6 63 10 	movl   $0x1063e6,0x8(%esp)
  10379e:	00 
  10379f:	c7 44 24 04 d7 01 00 	movl   $0x1d7,0x4(%esp)
  1037a6:	00 
  1037a7:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  1037ae:	e8 ce cc ff ff       	call   100481 <debug_panic>
  1037b3:	b8 03 00 00 00       	mov    $0x3,%eax
  1037b8:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  1037ba:	c7 44 24 08 68 67 10 	movl   $0x106768,0x8(%esp)
  1037c1:	00 
  1037c2:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
  1037c9:	00 
  1037ca:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  1037d1:	e8 ab cc ff ff       	call   100481 <debug_panic>

001037d6 <grandchild>:
}

static void grandchild(int n)
{
  1037d6:	55                   	push   %ebp
  1037d7:	89 e5                	mov    %esp,%ebp
  1037d9:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  1037dc:	c7 44 24 08 8c 67 10 	movl   $0x10678c,0x8(%esp)
  1037e3:	00 
  1037e4:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
  1037eb:	00 
  1037ec:	c7 04 24 46 64 10 00 	movl   $0x106446,(%esp)
  1037f3:	e8 89 cc ff ff       	call   100481 <debug_panic>

001037f8 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1037f8:	55                   	push   %ebp
  1037f9:	89 e5                	mov    %esp,%ebp
  1037fb:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1037fe:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  103801:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103804:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103807:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10380a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10380f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  103812:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103815:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10381b:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103820:	74 24                	je     103846 <cpu_cur+0x4e>
  103822:	c7 44 24 0c b8 67 10 	movl   $0x1067b8,0xc(%esp)
  103829:	00 
  10382a:	c7 44 24 08 ce 67 10 	movl   $0x1067ce,0x8(%esp)
  103831:	00 
  103832:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103839:	00 
  10383a:	c7 04 24 e3 67 10 00 	movl   $0x1067e3,(%esp)
  103841:	e8 3b cc ff ff       	call   100481 <debug_panic>
	return c;
  103846:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103849:	c9                   	leave  
  10384a:	c3                   	ret    

0010384b <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  10384b:	55                   	push   %ebp
  10384c:	89 e5                	mov    %esp,%ebp
  10384e:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  103851:	c7 44 24 08 f0 67 10 	movl   $0x1067f0,0x8(%esp)
  103858:	00 
  103859:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  103860:	00 
  103861:	c7 04 24 0b 68 10 00 	movl   $0x10680b,(%esp)
  103868:	e8 14 cc ff ff       	call   100481 <debug_panic>

0010386d <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  10386d:	55                   	push   %ebp
  10386e:	89 e5                	mov    %esp,%ebp
  103870:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  103873:	c7 44 24 08 1a 68 10 	movl   $0x10681a,0x8(%esp)
  10387a:	00 
  10387b:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  103882:	00 
  103883:	c7 04 24 0b 68 10 00 	movl   $0x10680b,(%esp)
  10388a:	e8 f2 cb ff ff       	call   100481 <debug_panic>

0010388f <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  10388f:	55                   	push   %ebp
  103890:	89 e5                	mov    %esp,%ebp
  103892:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  103895:	c7 44 24 08 38 68 10 	movl   $0x106838,0x8(%esp)
  10389c:	00 
  10389d:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  1038a4:	00 
  1038a5:	c7 04 24 0b 68 10 00 	movl   $0x10680b,(%esp)
  1038ac:	e8 d0 cb ff ff       	call   100481 <debug_panic>

001038b1 <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  1038b1:	55                   	push   %ebp
  1038b2:	89 e5                	mov    %esp,%ebp
  1038b4:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  1038b7:	8b 45 18             	mov    0x18(%ebp),%eax
  1038ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  1038be:	8b 45 14             	mov    0x14(%ebp),%eax
  1038c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1038c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1038c8:	89 04 24             	mov    %eax,(%esp)
  1038cb:	e8 bf ff ff ff       	call   10388f <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  1038d0:	c7 44 24 08 54 68 10 	movl   $0x106854,0x8(%esp)
  1038d7:	00 
  1038d8:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  1038df:	00 
  1038e0:	c7 04 24 0b 68 10 00 	movl   $0x10680b,(%esp)
  1038e7:	e8 95 cb ff ff       	call   100481 <debug_panic>

001038ec <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  1038ec:	55                   	push   %ebp
  1038ed:	89 e5                	mov    %esp,%ebp
  1038ef:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  1038f2:	8b 45 08             	mov    0x8(%ebp),%eax
  1038f5:	8b 40 10             	mov    0x10(%eax),%eax
  1038f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1038fc:	c7 04 24 78 68 10 00 	movl   $0x106878,(%esp)
  103903:	e8 e7 18 00 00       	call   1051ef <cprintf>

	trap_return(tf);	// syscall completed
  103908:	8b 45 08             	mov    0x8(%ebp),%eax
  10390b:	89 04 24             	mov    %eax,(%esp)
  10390e:	e8 dd 47 00 00       	call   1080f0 <trap_return>

00103913 <do_put>:
}


static void
do_put(trapframe *tf, uint32_t cmd)
{	
  103913:	55                   	push   %ebp
  103914:	89 e5                	mov    %esp,%ebp
  103916:	83 ec 28             	sub    $0x28,%esp
	cprintf("process %p is in do_put()\n", proc_cur());
  103919:	e8 da fe ff ff       	call   1037f8 <cpu_cur>
  10391e:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103924:	89 44 24 04          	mov    %eax,0x4(%esp)
  103928:	c7 04 24 7b 68 10 00 	movl   $0x10687b,(%esp)
  10392f:	e8 bb 18 00 00       	call   1051ef <cprintf>
	
	procstate* ps = (procstate*)tf->regs.ebx;
  103934:	8b 45 08             	mov    0x8(%ebp),%eax
  103937:	8b 40 10             	mov    0x10(%eax),%eax
  10393a:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint16_t child_num = tf->regs.edx;
  10393d:	8b 45 08             	mov    0x8(%ebp),%eax
  103940:	8b 40 14             	mov    0x14(%eax),%eax
  103943:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
	proc* proc_parent = proc_cur();
  103947:	e8 ac fe ff ff       	call   1037f8 <cpu_cur>
  10394c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103952:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103955:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  103959:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10395c:	83 c2 10             	add    $0x10,%edx
  10395f:	8b 04 90             	mov    (%eax,%edx,4),%eax
  103962:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(proc_child == NULL){
  103965:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103969:	75 38                	jne    1039a3 <do_put+0x90>
		proc_child = proc_alloc(proc_parent, child_num);
  10396b:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
  10396f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103973:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103976:	89 04 24             	mov    %eax,(%esp)
  103979:	e8 5c f1 ff ff       	call   102ada <proc_alloc>
  10397e:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if(proc_child == NULL)
  103981:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103985:	75 1c                	jne    1039a3 <do_put+0x90>
			panic("no child proc!");
  103987:	c7 44 24 08 96 68 10 	movl   $0x106896,0x8(%esp)
  10398e:	00 
  10398f:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
  103996:	00 
  103997:	c7 04 24 0b 68 10 00 	movl   $0x10680b,(%esp)
  10399e:	e8 de ca ff ff       	call   100481 <debug_panic>
	}
	
	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  1039a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039a6:	89 04 24             	mov    %eax,(%esp)
  1039a9:	e8 5f e9 ff ff       	call   10230d <spinlock_acquire>
	if(proc_child->state != PROC_STOP){
  1039ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039b1:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  1039b7:	85 c0                	test   %eax,%eax
  1039b9:	74 24                	je     1039df <do_put+0xcc>
		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  1039bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039be:	89 04 24             	mov    %eax,(%esp)
  1039c1:	e8 b4 e9 ff ff       	call   10237a <spinlock_release>
		proc_wait(proc_parent, proc_child, tf);
  1039c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1039c9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1039cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1039d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039d7:	89 04 24             	mov    %eax,(%esp)
  1039da:	e8 1b f4 ff ff       	call   102dfa <proc_wait>
	}

	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  1039df:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039e2:	89 04 24             	mov    %eax,(%esp)
  1039e5:	e8 90 e9 ff ff       	call   10237a <spinlock_release>

	if(tf->regs.eax & SYS_REGS){	
  1039ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1039ed:	8b 40 1c             	mov    0x1c(%eax),%eax
  1039f0:	25 00 10 00 00       	and    $0x1000,%eax
  1039f5:	85 c0                	test   %eax,%eax
  1039f7:	0f 84 c4 00 00 00    	je     103ac1 <do_put+0x1ae>
		//proc_print(ACQUIRE, proc_child);
		spinlock_acquire(&proc_child->lock);
  1039fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a00:	89 04 24             	mov    %eax,(%esp)
  103a03:	e8 05 e9 ff ff       	call   10230d <spinlock_acquire>
		/*
		if(((proc_child->sv.tf.eflags ^ ps->tf.eflags) | FL_USER) != FL_USER)
			panic("illegal modification of eflags!");
		*/
		
		proc_child->sv.tf.eip = ps->tf.eip;
  103a08:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a0b:	8b 50 38             	mov    0x38(%eax),%edx
  103a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a11:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_child->sv.tf.esp = ps->tf.esp;
  103a17:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a1a:	8b 50 44             	mov    0x44(%eax),%edx
  103a1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a20:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
  103a26:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a29:	8b 50 08             	mov    0x8(%eax),%edx
  103a2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a2f:	89 90 58 04 00 00    	mov    %edx,0x458(%eax)
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
  103a35:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a38:	8b 40 44             	mov    0x44(%eax),%eax
  103a3b:	89 44 24 04          	mov    %eax,0x4(%esp)
  103a3f:	c7 04 24 a8 68 10 00 	movl   $0x1068a8,(%esp)
  103a46:	e8 a4 17 00 00       	call   1051ef <cprintf>
		proc_child->sv.tf.trapno = ps->tf.trapno;
  103a4b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a4e:	8b 50 30             	mov    0x30(%eax),%edx
  103a51:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a54:	89 90 80 04 00 00    	mov    %edx,0x480(%eax)

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
  103a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a5d:	0f b7 80 8c 04 00 00 	movzwl 0x48c(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103a64:	66 83 f8 1b          	cmp    $0x1b,%ax
  103a68:	75 30                	jne    103a9a <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
  103a6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a6d:	0f b7 80 7c 04 00 00 	movzwl 0x47c(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103a74:	66 83 f8 23          	cmp    $0x23,%ax
  103a78:	75 20                	jne    103a9a <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103a7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a7d:	0f b7 80 78 04 00 00 	movzwl 0x478(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103a84:	66 83 f8 23          	cmp    $0x23,%ax
  103a88:	75 10                	jne    103a9a <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103a8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a8d:	0f b7 80 98 04 00 00 	movzwl 0x498(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103a94:	66 83 f8 23          	cmp    $0x23,%ax
  103a98:	74 1c                	je     103ab6 <do_put+0x1a3>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
			panic("wrong segment regs values!");
  103a9a:	c7 44 24 08 ca 68 10 	movl   $0x1068ca,0x8(%esp)
  103aa1:	00 
  103aa2:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  103aa9:	00 
  103aaa:	c7 04 24 0b 68 10 00 	movl   $0x10680b,(%esp)
  103ab1:	e8 cb c9 ff ff       	call   100481 <debug_panic>

		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  103ab6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ab9:	89 04 24             	mov    %eax,(%esp)
  103abc:	e8 b9 e8 ff ff       	call   10237a <spinlock_release>
	}
    if(tf->regs.eax & SYS_START){
  103ac1:	8b 45 08             	mov    0x8(%ebp),%eax
  103ac4:	8b 40 1c             	mov    0x1c(%eax),%eax
  103ac7:	83 e0 10             	and    $0x10,%eax
  103aca:	85 c0                	test   %eax,%eax
  103acc:	74 0b                	je     103ad9 <do_put+0x1c6>
		//cprintf("in SYS_START\n");
		proc_ready(proc_child);
  103ace:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ad1:	89 04 24             	mov    %eax,(%esp)
  103ad4:	e8 a0 f1 ff ff       	call   102c79 <proc_ready>
	}
	
	trap_return(tf);
  103ad9:	8b 45 08             	mov    0x8(%ebp),%eax
  103adc:	89 04 24             	mov    %eax,(%esp)
  103adf:	e8 0c 46 00 00       	call   1080f0 <trap_return>

00103ae4 <do_get>:
}

static void
do_get(trapframe *tf, uint32_t cmd)
{	
  103ae4:	55                   	push   %ebp
  103ae5:	89 e5                	mov    %esp,%ebp
  103ae7:	83 ec 28             	sub    $0x28,%esp
	cprintf("process %p is in do_get()\n", proc_cur());
  103aea:	e8 09 fd ff ff       	call   1037f8 <cpu_cur>
  103aef:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103af5:	89 44 24 04          	mov    %eax,0x4(%esp)
  103af9:	c7 04 24 e5 68 10 00 	movl   $0x1068e5,(%esp)
  103b00:	e8 ea 16 00 00       	call   1051ef <cprintf>
	
	procstate* ps = (procstate*)tf->regs.ebx;
  103b05:	8b 45 08             	mov    0x8(%ebp),%eax
  103b08:	8b 40 10             	mov    0x10(%eax),%eax
  103b0b:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int child_num = (int)tf->regs.edx;
  103b0e:	8b 45 08             	mov    0x8(%ebp),%eax
  103b11:	8b 40 14             	mov    0x14(%eax),%eax
  103b14:	89 45 ec             	mov    %eax,-0x14(%ebp)
	proc* proc_parent = proc_cur();
  103b17:	e8 dc fc ff ff       	call   1037f8 <cpu_cur>
  103b1c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103b22:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103b25:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103b28:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b2b:	83 c2 10             	add    $0x10,%edx
  103b2e:	8b 04 90             	mov    (%eax,%edx,4),%eax
  103b31:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child != NULL);
  103b34:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103b38:	75 24                	jne    103b5e <do_get+0x7a>
  103b3a:	c7 44 24 0c 00 69 10 	movl   $0x106900,0xc(%esp)
  103b41:	00 
  103b42:	c7 44 24 08 ce 67 10 	movl   $0x1067ce,0x8(%esp)
  103b49:	00 
  103b4a:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  103b51:	00 
  103b52:	c7 04 24 0b 68 10 00 	movl   $0x10680b,(%esp)
  103b59:	e8 23 c9 ff ff       	call   100481 <debug_panic>

	if(proc_child->state != PROC_STOP){
  103b5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b61:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103b67:	85 c0                	test   %eax,%eax
  103b69:	74 25                	je     103b90 <do_get+0xac>
		cprintf("into proc_wait\n");
  103b6b:	c7 04 24 13 69 10 00 	movl   $0x106913,(%esp)
  103b72:	e8 78 16 00 00       	call   1051ef <cprintf>
		proc_wait(proc_parent, proc_child, tf);}
  103b77:	8b 45 08             	mov    0x8(%ebp),%eax
  103b7a:	89 44 24 08          	mov    %eax,0x8(%esp)
  103b7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b81:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b85:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b88:	89 04 24             	mov    %eax,(%esp)
  103b8b:	e8 6a f2 ff ff       	call   102dfa <proc_wait>

	if(tf->regs.eax & SYS_REGS){
  103b90:	8b 45 08             	mov    0x8(%ebp),%eax
  103b93:	8b 40 1c             	mov    0x1c(%eax),%eax
  103b96:	25 00 10 00 00       	and    $0x1000,%eax
  103b9b:	85 c0                	test   %eax,%eax
  103b9d:	74 20                	je     103bbf <do_get+0xdb>
		memmove(&(ps->tf), &(proc_child->sv.tf), sizeof(trapframe));
  103b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ba2:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  103ba8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103bab:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  103bb2:	00 
  103bb3:	89 54 24 04          	mov    %edx,0x4(%esp)
  103bb7:	89 04 24             	mov    %eax,(%esp)
  103bba:	e8 89 18 00 00       	call   105448 <memmove>
	}
	
	trap_return(tf);
  103bbf:	8b 45 08             	mov    0x8(%ebp),%eax
  103bc2:	89 04 24             	mov    %eax,(%esp)
  103bc5:	e8 26 45 00 00       	call   1080f0 <trap_return>

00103bca <do_ret>:
}

static void
do_ret(trapframe *tf, uint32_t cmd)
{	
  103bca:	55                   	push   %ebp
  103bcb:	89 e5                	mov    %esp,%ebp
  103bcd:	83 ec 18             	sub    $0x18,%esp
	cprintf("process %p is in do_ret()\n", proc_cur());
  103bd0:	e8 23 fc ff ff       	call   1037f8 <cpu_cur>
  103bd5:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103bdb:	89 44 24 04          	mov    %eax,0x4(%esp)
  103bdf:	c7 04 24 23 69 10 00 	movl   $0x106923,(%esp)
  103be6:	e8 04 16 00 00       	call   1051ef <cprintf>
	proc_ret(tf, 1);
  103beb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103bf2:	00 
  103bf3:	8b 45 08             	mov    0x8(%ebp),%eax
  103bf6:	89 04 24             	mov    %eax,(%esp)
  103bf9:	e8 81 f4 ff ff       	call   10307f <proc_ret>

00103bfe <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  103bfe:	55                   	push   %ebp
  103bff:	89 e5                	mov    %esp,%ebp
  103c01:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  103c04:	8b 45 08             	mov    0x8(%ebp),%eax
  103c07:	8b 40 1c             	mov    0x1c(%eax),%eax
  103c0a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  103c0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c10:	83 e0 0f             	and    $0xf,%eax
  103c13:	83 f8 01             	cmp    $0x1,%eax
  103c16:	74 25                	je     103c3d <syscall+0x3f>
  103c18:	83 f8 01             	cmp    $0x1,%eax
  103c1b:	72 0c                	jb     103c29 <syscall+0x2b>
  103c1d:	83 f8 02             	cmp    $0x2,%eax
  103c20:	74 2f                	je     103c51 <syscall+0x53>
  103c22:	83 f8 03             	cmp    $0x3,%eax
  103c25:	74 3e                	je     103c65 <syscall+0x67>
	case SYS_PUT:	 do_put(tf, cmd); break;
	case SYS_GET:	 do_get(tf, cmd); break;
	case SYS_RET:	 do_ret(tf, cmd); break;
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
  103c27:	eb 4f                	jmp    103c78 <syscall+0x7a>
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:	 do_cputs(tf, cmd); break;
  103c29:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c2c:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c30:	8b 45 08             	mov    0x8(%ebp),%eax
  103c33:	89 04 24             	mov    %eax,(%esp)
  103c36:	e8 b1 fc ff ff       	call   1038ec <do_cputs>
  103c3b:	eb 3b                	jmp    103c78 <syscall+0x7a>
	case SYS_PUT:	 do_put(tf, cmd); break;
  103c3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c40:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c44:	8b 45 08             	mov    0x8(%ebp),%eax
  103c47:	89 04 24             	mov    %eax,(%esp)
  103c4a:	e8 c4 fc ff ff       	call   103913 <do_put>
  103c4f:	eb 27                	jmp    103c78 <syscall+0x7a>
	case SYS_GET:	 do_get(tf, cmd); break;
  103c51:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c54:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c58:	8b 45 08             	mov    0x8(%ebp),%eax
  103c5b:	89 04 24             	mov    %eax,(%esp)
  103c5e:	e8 81 fe ff ff       	call   103ae4 <do_get>
  103c63:	eb 13                	jmp    103c78 <syscall+0x7a>
	case SYS_RET:	 do_ret(tf, cmd); break;
  103c65:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c68:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c6c:	8b 45 08             	mov    0x8(%ebp),%eax
  103c6f:	89 04 24             	mov    %eax,(%esp)
  103c72:	e8 53 ff ff ff       	call   103bca <do_ret>
  103c77:	90                   	nop
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
	}
}
  103c78:	c9                   	leave  
  103c79:	c3                   	ret    

00103c7a <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  103c7a:	55                   	push   %ebp
  103c7b:	89 e5                	mov    %esp,%ebp
  103c7d:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  103c80:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  103c87:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103c8a:	0f b7 00             	movzwl (%eax),%eax
  103c8d:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  103c91:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103c94:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  103c99:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103c9c:	0f b7 00             	movzwl (%eax),%eax
  103c9f:	66 3d 5a a5          	cmp    $0xa55a,%ax
  103ca3:	74 13                	je     103cb8 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  103ca5:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  103cac:	c7 05 38 e3 10 00 b4 	movl   $0x3b4,0x10e338
  103cb3:	03 00 00 
  103cb6:	eb 14                	jmp    103ccc <video_init+0x52>
	} else {
		*cp = was;
  103cb8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103cbb:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  103cbf:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  103cc2:	c7 05 38 e3 10 00 d4 	movl   $0x3d4,0x10e338
  103cc9:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  103ccc:	a1 38 e3 10 00       	mov    0x10e338,%eax
  103cd1:	89 45 e8             	mov    %eax,-0x18(%ebp)
  103cd4:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103cd8:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  103cdc:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103cdf:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  103ce0:	a1 38 e3 10 00       	mov    0x10e338,%eax
  103ce5:	83 c0 01             	add    $0x1,%eax
  103ce8:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103ceb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103cee:	89 c2                	mov    %eax,%edx
  103cf0:	ec                   	in     (%dx),%al
  103cf1:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  103cf4:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  103cf8:	0f b6 c0             	movzbl %al,%eax
  103cfb:	c1 e0 08             	shl    $0x8,%eax
  103cfe:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  103d01:	a1 38 e3 10 00       	mov    0x10e338,%eax
  103d06:	89 45 f4             	mov    %eax,-0xc(%ebp)
  103d09:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103d0d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103d11:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103d14:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  103d15:	a1 38 e3 10 00       	mov    0x10e338,%eax
  103d1a:	83 c0 01             	add    $0x1,%eax
  103d1d:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103d20:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103d23:	89 c2                	mov    %eax,%edx
  103d25:	ec                   	in     (%dx),%al
  103d26:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  103d29:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  103d2d:	0f b6 c0             	movzbl %al,%eax
  103d30:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  103d33:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103d36:	a3 3c e3 10 00       	mov    %eax,0x10e33c
	crt_pos = pos;
  103d3b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103d3e:	66 a3 40 e3 10 00    	mov    %ax,0x10e340
}
  103d44:	c9                   	leave  
  103d45:	c3                   	ret    

00103d46 <video_putc>:



void
video_putc(int c)
{
  103d46:	55                   	push   %ebp
  103d47:	89 e5                	mov    %esp,%ebp
  103d49:	53                   	push   %ebx
  103d4a:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  103d4d:	8b 45 08             	mov    0x8(%ebp),%eax
  103d50:	b0 00                	mov    $0x0,%al
  103d52:	85 c0                	test   %eax,%eax
  103d54:	75 07                	jne    103d5d <video_putc+0x17>
		c |= 0x0700;
  103d56:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  103d5d:	8b 45 08             	mov    0x8(%ebp),%eax
  103d60:	25 ff 00 00 00       	and    $0xff,%eax
  103d65:	83 f8 09             	cmp    $0x9,%eax
  103d68:	0f 84 ae 00 00 00    	je     103e1c <video_putc+0xd6>
  103d6e:	83 f8 09             	cmp    $0x9,%eax
  103d71:	7f 0a                	jg     103d7d <video_putc+0x37>
  103d73:	83 f8 08             	cmp    $0x8,%eax
  103d76:	74 14                	je     103d8c <video_putc+0x46>
  103d78:	e9 dd 00 00 00       	jmp    103e5a <video_putc+0x114>
  103d7d:	83 f8 0a             	cmp    $0xa,%eax
  103d80:	74 4e                	je     103dd0 <video_putc+0x8a>
  103d82:	83 f8 0d             	cmp    $0xd,%eax
  103d85:	74 59                	je     103de0 <video_putc+0x9a>
  103d87:	e9 ce 00 00 00       	jmp    103e5a <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  103d8c:	0f b7 05 40 e3 10 00 	movzwl 0x10e340,%eax
  103d93:	66 85 c0             	test   %ax,%ax
  103d96:	0f 84 e4 00 00 00    	je     103e80 <video_putc+0x13a>
			crt_pos--;
  103d9c:	0f b7 05 40 e3 10 00 	movzwl 0x10e340,%eax
  103da3:	83 e8 01             	sub    $0x1,%eax
  103da6:	66 a3 40 e3 10 00    	mov    %ax,0x10e340
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  103dac:	a1 3c e3 10 00       	mov    0x10e33c,%eax
  103db1:	0f b7 15 40 e3 10 00 	movzwl 0x10e340,%edx
  103db8:	0f b7 d2             	movzwl %dx,%edx
  103dbb:	01 d2                	add    %edx,%edx
  103dbd:	8d 14 10             	lea    (%eax,%edx,1),%edx
  103dc0:	8b 45 08             	mov    0x8(%ebp),%eax
  103dc3:	b0 00                	mov    $0x0,%al
  103dc5:	83 c8 20             	or     $0x20,%eax
  103dc8:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  103dcb:	e9 b1 00 00 00       	jmp    103e81 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  103dd0:	0f b7 05 40 e3 10 00 	movzwl 0x10e340,%eax
  103dd7:	83 c0 50             	add    $0x50,%eax
  103dda:	66 a3 40 e3 10 00    	mov    %ax,0x10e340
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  103de0:	0f b7 1d 40 e3 10 00 	movzwl 0x10e340,%ebx
  103de7:	0f b7 0d 40 e3 10 00 	movzwl 0x10e340,%ecx
  103dee:	0f b7 c1             	movzwl %cx,%eax
  103df1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  103df7:	c1 e8 10             	shr    $0x10,%eax
  103dfa:	89 c2                	mov    %eax,%edx
  103dfc:	66 c1 ea 06          	shr    $0x6,%dx
  103e00:	89 d0                	mov    %edx,%eax
  103e02:	c1 e0 02             	shl    $0x2,%eax
  103e05:	01 d0                	add    %edx,%eax
  103e07:	c1 e0 04             	shl    $0x4,%eax
  103e0a:	89 ca                	mov    %ecx,%edx
  103e0c:	66 29 c2             	sub    %ax,%dx
  103e0f:	89 d8                	mov    %ebx,%eax
  103e11:	66 29 d0             	sub    %dx,%ax
  103e14:	66 a3 40 e3 10 00    	mov    %ax,0x10e340
		break;
  103e1a:	eb 65                	jmp    103e81 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  103e1c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103e23:	e8 1e ff ff ff       	call   103d46 <video_putc>
		video_putc(' ');
  103e28:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103e2f:	e8 12 ff ff ff       	call   103d46 <video_putc>
		video_putc(' ');
  103e34:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103e3b:	e8 06 ff ff ff       	call   103d46 <video_putc>
		video_putc(' ');
  103e40:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103e47:	e8 fa fe ff ff       	call   103d46 <video_putc>
		video_putc(' ');
  103e4c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103e53:	e8 ee fe ff ff       	call   103d46 <video_putc>
		break;
  103e58:	eb 27                	jmp    103e81 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  103e5a:	8b 15 3c e3 10 00    	mov    0x10e33c,%edx
  103e60:	0f b7 05 40 e3 10 00 	movzwl 0x10e340,%eax
  103e67:	0f b7 c8             	movzwl %ax,%ecx
  103e6a:	01 c9                	add    %ecx,%ecx
  103e6c:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  103e6f:	8b 55 08             	mov    0x8(%ebp),%edx
  103e72:	66 89 11             	mov    %dx,(%ecx)
  103e75:	83 c0 01             	add    $0x1,%eax
  103e78:	66 a3 40 e3 10 00    	mov    %ax,0x10e340
  103e7e:	eb 01                	jmp    103e81 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  103e80:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  103e81:	0f b7 05 40 e3 10 00 	movzwl 0x10e340,%eax
  103e88:	66 3d cf 07          	cmp    $0x7cf,%ax
  103e8c:	76 5b                	jbe    103ee9 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  103e8e:	a1 3c e3 10 00       	mov    0x10e33c,%eax
  103e93:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  103e99:	a1 3c e3 10 00       	mov    0x10e33c,%eax
  103e9e:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  103ea5:	00 
  103ea6:	89 54 24 04          	mov    %edx,0x4(%esp)
  103eaa:	89 04 24             	mov    %eax,(%esp)
  103ead:	e8 96 15 00 00       	call   105448 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103eb2:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  103eb9:	eb 15                	jmp    103ed0 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  103ebb:	a1 3c e3 10 00       	mov    0x10e33c,%eax
  103ec0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103ec3:	01 d2                	add    %edx,%edx
  103ec5:	01 d0                	add    %edx,%eax
  103ec7:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103ecc:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  103ed0:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  103ed7:	7e e2                	jle    103ebb <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  103ed9:	0f b7 05 40 e3 10 00 	movzwl 0x10e340,%eax
  103ee0:	83 e8 50             	sub    $0x50,%eax
  103ee3:	66 a3 40 e3 10 00    	mov    %ax,0x10e340
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  103ee9:	a1 38 e3 10 00       	mov    0x10e338,%eax
  103eee:	89 45 dc             	mov    %eax,-0x24(%ebp)
  103ef1:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103ef5:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103ef9:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103efc:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  103efd:	0f b7 05 40 e3 10 00 	movzwl 0x10e340,%eax
  103f04:	66 c1 e8 08          	shr    $0x8,%ax
  103f08:	0f b6 c0             	movzbl %al,%eax
  103f0b:	8b 15 38 e3 10 00    	mov    0x10e338,%edx
  103f11:	83 c2 01             	add    $0x1,%edx
  103f14:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  103f17:	88 45 e3             	mov    %al,-0x1d(%ebp)
  103f1a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103f1e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103f21:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  103f22:	a1 38 e3 10 00       	mov    0x10e338,%eax
  103f27:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103f2a:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  103f2e:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  103f32:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103f35:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  103f36:	0f b7 05 40 e3 10 00 	movzwl 0x10e340,%eax
  103f3d:	0f b6 c0             	movzbl %al,%eax
  103f40:	8b 15 38 e3 10 00    	mov    0x10e338,%edx
  103f46:	83 c2 01             	add    $0x1,%edx
  103f49:	89 55 f4             	mov    %edx,-0xc(%ebp)
  103f4c:	88 45 f3             	mov    %al,-0xd(%ebp)
  103f4f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103f53:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103f56:	ee                   	out    %al,(%dx)
}
  103f57:	83 c4 44             	add    $0x44,%esp
  103f5a:	5b                   	pop    %ebx
  103f5b:	5d                   	pop    %ebp
  103f5c:	c3                   	ret    

00103f5d <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  103f5d:	55                   	push   %ebp
  103f5e:	89 e5                	mov    %esp,%ebp
  103f60:	83 ec 38             	sub    $0x38,%esp
  103f63:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103f6a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103f6d:	89 c2                	mov    %eax,%edx
  103f6f:	ec                   	in     (%dx),%al
  103f70:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  103f73:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  103f77:	0f b6 c0             	movzbl %al,%eax
  103f7a:	83 e0 01             	and    $0x1,%eax
  103f7d:	85 c0                	test   %eax,%eax
  103f7f:	75 0a                	jne    103f8b <kbd_proc_data+0x2e>
		return -1;
  103f81:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  103f86:	e9 5a 01 00 00       	jmp    1040e5 <kbd_proc_data+0x188>
  103f8b:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103f92:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103f95:	89 c2                	mov    %eax,%edx
  103f97:	ec                   	in     (%dx),%al
  103f98:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  103f9b:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  103f9f:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  103fa2:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  103fa6:	75 17                	jne    103fbf <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  103fa8:	a1 44 e3 10 00       	mov    0x10e344,%eax
  103fad:	83 c8 40             	or     $0x40,%eax
  103fb0:	a3 44 e3 10 00       	mov    %eax,0x10e344
		return 0;
  103fb5:	b8 00 00 00 00       	mov    $0x0,%eax
  103fba:	e9 26 01 00 00       	jmp    1040e5 <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  103fbf:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103fc3:	84 c0                	test   %al,%al
  103fc5:	79 47                	jns    10400e <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  103fc7:	a1 44 e3 10 00       	mov    0x10e344,%eax
  103fcc:	83 e0 40             	and    $0x40,%eax
  103fcf:	85 c0                	test   %eax,%eax
  103fd1:	75 09                	jne    103fdc <kbd_proc_data+0x7f>
  103fd3:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103fd7:	83 e0 7f             	and    $0x7f,%eax
  103fda:	eb 04                	jmp    103fe0 <kbd_proc_data+0x83>
  103fdc:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103fe0:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  103fe3:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103fe7:	0f b6 80 20 81 10 00 	movzbl 0x108120(%eax),%eax
  103fee:	83 c8 40             	or     $0x40,%eax
  103ff1:	0f b6 c0             	movzbl %al,%eax
  103ff4:	f7 d0                	not    %eax
  103ff6:	89 c2                	mov    %eax,%edx
  103ff8:	a1 44 e3 10 00       	mov    0x10e344,%eax
  103ffd:	21 d0                	and    %edx,%eax
  103fff:	a3 44 e3 10 00       	mov    %eax,0x10e344
		return 0;
  104004:	b8 00 00 00 00       	mov    $0x0,%eax
  104009:	e9 d7 00 00 00       	jmp    1040e5 <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  10400e:	a1 44 e3 10 00       	mov    0x10e344,%eax
  104013:	83 e0 40             	and    $0x40,%eax
  104016:	85 c0                	test   %eax,%eax
  104018:	74 11                	je     10402b <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  10401a:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  10401e:	a1 44 e3 10 00       	mov    0x10e344,%eax
  104023:	83 e0 bf             	and    $0xffffffbf,%eax
  104026:	a3 44 e3 10 00       	mov    %eax,0x10e344
	}

	shift |= shiftcode[data];
  10402b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10402f:	0f b6 80 20 81 10 00 	movzbl 0x108120(%eax),%eax
  104036:	0f b6 d0             	movzbl %al,%edx
  104039:	a1 44 e3 10 00       	mov    0x10e344,%eax
  10403e:	09 d0                	or     %edx,%eax
  104040:	a3 44 e3 10 00       	mov    %eax,0x10e344
	shift ^= togglecode[data];
  104045:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  104049:	0f b6 80 20 82 10 00 	movzbl 0x108220(%eax),%eax
  104050:	0f b6 d0             	movzbl %al,%edx
  104053:	a1 44 e3 10 00       	mov    0x10e344,%eax
  104058:	31 d0                	xor    %edx,%eax
  10405a:	a3 44 e3 10 00       	mov    %eax,0x10e344

	c = charcode[shift & (CTL | SHIFT)][data];
  10405f:	a1 44 e3 10 00       	mov    0x10e344,%eax
  104064:	83 e0 03             	and    $0x3,%eax
  104067:	8b 14 85 20 86 10 00 	mov    0x108620(,%eax,4),%edx
  10406e:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  104072:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104075:	0f b6 00             	movzbl (%eax),%eax
  104078:	0f b6 c0             	movzbl %al,%eax
  10407b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  10407e:	a1 44 e3 10 00       	mov    0x10e344,%eax
  104083:	83 e0 08             	and    $0x8,%eax
  104086:	85 c0                	test   %eax,%eax
  104088:	74 22                	je     1040ac <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  10408a:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  10408e:	7e 0c                	jle    10409c <kbd_proc_data+0x13f>
  104090:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  104094:	7f 06                	jg     10409c <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  104096:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  10409a:	eb 10                	jmp    1040ac <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  10409c:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  1040a0:	7e 0a                	jle    1040ac <kbd_proc_data+0x14f>
  1040a2:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  1040a6:	7f 04                	jg     1040ac <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  1040a8:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  1040ac:	a1 44 e3 10 00       	mov    0x10e344,%eax
  1040b1:	f7 d0                	not    %eax
  1040b3:	83 e0 06             	and    $0x6,%eax
  1040b6:	85 c0                	test   %eax,%eax
  1040b8:	75 28                	jne    1040e2 <kbd_proc_data+0x185>
  1040ba:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  1040c1:	75 1f                	jne    1040e2 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  1040c3:	c7 04 24 3e 69 10 00 	movl   $0x10693e,(%esp)
  1040ca:	e8 20 11 00 00       	call   1051ef <cprintf>
  1040cf:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  1040d6:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1040da:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1040de:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1040e1:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  1040e2:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  1040e5:	c9                   	leave  
  1040e6:	c3                   	ret    

001040e7 <kbd_intr>:

void
kbd_intr(void)
{
  1040e7:	55                   	push   %ebp
  1040e8:	89 e5                	mov    %esp,%ebp
  1040ea:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  1040ed:	c7 04 24 5d 3f 10 00 	movl   $0x103f5d,(%esp)
  1040f4:	e8 bd c1 ff ff       	call   1002b6 <cons_intr>
}
  1040f9:	c9                   	leave  
  1040fa:	c3                   	ret    

001040fb <kbd_init>:

void
kbd_init(void)
{
  1040fb:	55                   	push   %ebp
  1040fc:	89 e5                	mov    %esp,%ebp
}
  1040fe:	5d                   	pop    %ebp
  1040ff:	c3                   	ret    

00104100 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  104100:	55                   	push   %ebp
  104101:	89 e5                	mov    %esp,%ebp
  104103:	83 ec 20             	sub    $0x20,%esp
  104106:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10410d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104110:	89 c2                	mov    %eax,%edx
  104112:	ec                   	in     (%dx),%al
  104113:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  104116:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10411d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104120:	89 c2                	mov    %eax,%edx
  104122:	ec                   	in     (%dx),%al
  104123:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  104126:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10412d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104130:	89 c2                	mov    %eax,%edx
  104132:	ec                   	in     (%dx),%al
  104133:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  104136:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10413d:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104140:	89 c2                	mov    %eax,%edx
  104142:	ec                   	in     (%dx),%al
  104143:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  104146:	c9                   	leave  
  104147:	c3                   	ret    

00104148 <serial_proc_data>:

static int
serial_proc_data(void)
{
  104148:	55                   	push   %ebp
  104149:	89 e5                	mov    %esp,%ebp
  10414b:	83 ec 10             	sub    $0x10,%esp
  10414e:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  104155:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104158:	89 c2                	mov    %eax,%edx
  10415a:	ec                   	in     (%dx),%al
  10415b:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  10415e:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  104162:	0f b6 c0             	movzbl %al,%eax
  104165:	83 e0 01             	and    $0x1,%eax
  104168:	85 c0                	test   %eax,%eax
  10416a:	75 07                	jne    104173 <serial_proc_data+0x2b>
		return -1;
  10416c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104171:	eb 17                	jmp    10418a <serial_proc_data+0x42>
  104173:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10417a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10417d:	89 c2                	mov    %eax,%edx
  10417f:	ec                   	in     (%dx),%al
  104180:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  104183:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  104187:	0f b6 c0             	movzbl %al,%eax
}
  10418a:	c9                   	leave  
  10418b:	c3                   	ret    

0010418c <serial_intr>:

void
serial_intr(void)
{
  10418c:	55                   	push   %ebp
  10418d:	89 e5                	mov    %esp,%ebp
  10418f:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  104192:	a1 08 eb 30 00       	mov    0x30eb08,%eax
  104197:	85 c0                	test   %eax,%eax
  104199:	74 0c                	je     1041a7 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  10419b:	c7 04 24 48 41 10 00 	movl   $0x104148,(%esp)
  1041a2:	e8 0f c1 ff ff       	call   1002b6 <cons_intr>
}
  1041a7:	c9                   	leave  
  1041a8:	c3                   	ret    

001041a9 <serial_putc>:

void
serial_putc(int c)
{
  1041a9:	55                   	push   %ebp
  1041aa:	89 e5                	mov    %esp,%ebp
  1041ac:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  1041af:	a1 08 eb 30 00       	mov    0x30eb08,%eax
  1041b4:	85 c0                	test   %eax,%eax
  1041b6:	74 53                	je     10420b <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  1041b8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1041bf:	eb 09                	jmp    1041ca <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  1041c1:	e8 3a ff ff ff       	call   104100 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  1041c6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1041ca:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1041d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1041d4:	89 c2                	mov    %eax,%edx
  1041d6:	ec                   	in     (%dx),%al
  1041d7:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  1041da:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  1041de:	0f b6 c0             	movzbl %al,%eax
  1041e1:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  1041e4:	85 c0                	test   %eax,%eax
  1041e6:	75 09                	jne    1041f1 <serial_putc+0x48>
  1041e8:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  1041ef:	7e d0                	jle    1041c1 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  1041f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1041f4:	0f b6 c0             	movzbl %al,%eax
  1041f7:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  1041fe:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  104201:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  104205:	8b 55 fc             	mov    -0x4(%ebp),%edx
  104208:	ee                   	out    %al,(%dx)
  104209:	eb 01                	jmp    10420c <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  10420b:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  10420c:	c9                   	leave  
  10420d:	c3                   	ret    

0010420e <serial_init>:

void
serial_init(void)
{
  10420e:	55                   	push   %ebp
  10420f:	89 e5                	mov    %esp,%ebp
  104211:	83 ec 50             	sub    $0x50,%esp
  104214:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  10421b:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  10421f:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  104223:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  104226:	ee                   	out    %al,(%dx)
  104227:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  10422e:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  104232:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  104236:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104239:	ee                   	out    %al,(%dx)
  10423a:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  104241:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  104245:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  104249:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  10424c:	ee                   	out    %al,(%dx)
  10424d:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  104254:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  104258:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  10425c:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10425f:	ee                   	out    %al,(%dx)
  104260:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  104267:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  10426b:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  10426f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104272:	ee                   	out    %al,(%dx)
  104273:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  10427a:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  10427e:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  104282:	8b 55 dc             	mov    -0x24(%ebp),%edx
  104285:	ee                   	out    %al,(%dx)
  104286:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  10428d:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  104291:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  104295:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  104298:	ee                   	out    %al,(%dx)
  104299:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1042a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1042a3:	89 c2                	mov    %eax,%edx
  1042a5:	ec                   	in     (%dx),%al
  1042a6:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  1042a9:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  1042ad:	3c ff                	cmp    $0xff,%al
  1042af:	0f 95 c0             	setne  %al
  1042b2:	0f b6 c0             	movzbl %al,%eax
  1042b5:	a3 08 eb 30 00       	mov    %eax,0x30eb08
  1042ba:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1042c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042c4:	89 c2                	mov    %eax,%edx
  1042c6:	ec                   	in     (%dx),%al
  1042c7:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  1042ca:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1042d1:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1042d4:	89 c2                	mov    %eax,%edx
  1042d6:	ec                   	in     (%dx),%al
  1042d7:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  1042da:	c9                   	leave  
  1042db:	c3                   	ret    

001042dc <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  1042dc:	55                   	push   %ebp
  1042dd:	89 e5                	mov    %esp,%ebp
  1042df:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  1042e5:	a1 48 e3 10 00       	mov    0x10e348,%eax
  1042ea:	85 c0                	test   %eax,%eax
  1042ec:	0f 85 35 01 00 00    	jne    104427 <pic_init+0x14b>
		return;
	didinit = 1;
  1042f2:	c7 05 48 e3 10 00 01 	movl   $0x1,0x10e348
  1042f9:	00 00 00 
  1042fc:	c7 45 8c 21 00 00 00 	movl   $0x21,-0x74(%ebp)
  104303:	c6 45 8b ff          	movb   $0xff,-0x75(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  104307:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  10430b:	8b 55 8c             	mov    -0x74(%ebp),%edx
  10430e:	ee                   	out    %al,(%dx)
  10430f:	c7 45 94 a1 00 00 00 	movl   $0xa1,-0x6c(%ebp)
  104316:	c6 45 93 ff          	movb   $0xff,-0x6d(%ebp)
  10431a:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  10431e:	8b 55 94             	mov    -0x6c(%ebp),%edx
  104321:	ee                   	out    %al,(%dx)
  104322:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  104329:	c6 45 9b 11          	movb   $0x11,-0x65(%ebp)
  10432d:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  104331:	8b 55 9c             	mov    -0x64(%ebp),%edx
  104334:	ee                   	out    %al,(%dx)
  104335:	c7 45 a4 21 00 00 00 	movl   $0x21,-0x5c(%ebp)
  10433c:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
  104340:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  104344:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  104347:	ee                   	out    %al,(%dx)
  104348:	c7 45 ac 21 00 00 00 	movl   $0x21,-0x54(%ebp)
  10434f:	c6 45 ab 04          	movb   $0x4,-0x55(%ebp)
  104353:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  104357:	8b 55 ac             	mov    -0x54(%ebp),%edx
  10435a:	ee                   	out    %al,(%dx)
  10435b:	c7 45 b4 21 00 00 00 	movl   $0x21,-0x4c(%ebp)
  104362:	c6 45 b3 03          	movb   $0x3,-0x4d(%ebp)
  104366:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  10436a:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  10436d:	ee                   	out    %al,(%dx)
  10436e:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
  104375:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
  104379:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  10437d:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104380:	ee                   	out    %al,(%dx)
  104381:	c7 45 c4 a1 00 00 00 	movl   $0xa1,-0x3c(%ebp)
  104388:	c6 45 c3 28          	movb   $0x28,-0x3d(%ebp)
  10438c:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  104390:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104393:	ee                   	out    %al,(%dx)
  104394:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
  10439b:	c6 45 cb 02          	movb   $0x2,-0x35(%ebp)
  10439f:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  1043a3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1043a6:	ee                   	out    %al,(%dx)
  1043a7:	c7 45 d4 a1 00 00 00 	movl   $0xa1,-0x2c(%ebp)
  1043ae:	c6 45 d3 01          	movb   $0x1,-0x2d(%ebp)
  1043b2:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  1043b6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1043b9:	ee                   	out    %al,(%dx)
  1043ba:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
  1043c1:	c6 45 db 68          	movb   $0x68,-0x25(%ebp)
  1043c5:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  1043c9:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1043cc:	ee                   	out    %al,(%dx)
  1043cd:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  1043d4:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  1043d8:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1043dc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1043df:	ee                   	out    %al,(%dx)
  1043e0:	c7 45 ec a0 00 00 00 	movl   $0xa0,-0x14(%ebp)
  1043e7:	c6 45 eb 68          	movb   $0x68,-0x15(%ebp)
  1043eb:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1043ef:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1043f2:	ee                   	out    %al,(%dx)
  1043f3:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
  1043fa:	c6 45 f3 0a          	movb   $0xa,-0xd(%ebp)
  1043fe:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104402:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104405:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  104406:	0f b7 05 30 86 10 00 	movzwl 0x108630,%eax
  10440d:	66 83 f8 ff          	cmp    $0xffff,%ax
  104411:	74 15                	je     104428 <pic_init+0x14c>
		pic_setmask(irqmask);
  104413:	0f b7 05 30 86 10 00 	movzwl 0x108630,%eax
  10441a:	0f b7 c0             	movzwl %ax,%eax
  10441d:	89 04 24             	mov    %eax,(%esp)
  104420:	e8 05 00 00 00       	call   10442a <pic_setmask>
  104425:	eb 01                	jmp    104428 <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  104427:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  104428:	c9                   	leave  
  104429:	c3                   	ret    

0010442a <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  10442a:	55                   	push   %ebp
  10442b:	89 e5                	mov    %esp,%ebp
  10442d:	83 ec 14             	sub    $0x14,%esp
  104430:	8b 45 08             	mov    0x8(%ebp),%eax
  104433:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  104437:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  10443b:	66 a3 30 86 10 00    	mov    %ax,0x108630
	outb(IO_PIC1+1, (char)mask);
  104441:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  104445:	0f b6 c0             	movzbl %al,%eax
  104448:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  10444f:	88 45 f3             	mov    %al,-0xd(%ebp)
  104452:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104456:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104459:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  10445a:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  10445e:	66 c1 e8 08          	shr    $0x8,%ax
  104462:	0f b6 c0             	movzbl %al,%eax
  104465:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
  10446c:	88 45 fb             	mov    %al,-0x5(%ebp)
  10446f:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  104473:	8b 55 fc             	mov    -0x4(%ebp),%edx
  104476:	ee                   	out    %al,(%dx)
}
  104477:	c9                   	leave  
  104478:	c3                   	ret    

00104479 <pic_enable>:

void
pic_enable(int irq)
{
  104479:	55                   	push   %ebp
  10447a:	89 e5                	mov    %esp,%ebp
  10447c:	53                   	push   %ebx
  10447d:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  104480:	8b 45 08             	mov    0x8(%ebp),%eax
  104483:	ba 01 00 00 00       	mov    $0x1,%edx
  104488:	89 d3                	mov    %edx,%ebx
  10448a:	89 c1                	mov    %eax,%ecx
  10448c:	d3 e3                	shl    %cl,%ebx
  10448e:	89 d8                	mov    %ebx,%eax
  104490:	89 c2                	mov    %eax,%edx
  104492:	f7 d2                	not    %edx
  104494:	0f b7 05 30 86 10 00 	movzwl 0x108630,%eax
  10449b:	21 d0                	and    %edx,%eax
  10449d:	0f b7 c0             	movzwl %ax,%eax
  1044a0:	89 04 24             	mov    %eax,(%esp)
  1044a3:	e8 82 ff ff ff       	call   10442a <pic_setmask>
}
  1044a8:	83 c4 04             	add    $0x4,%esp
  1044ab:	5b                   	pop    %ebx
  1044ac:	5d                   	pop    %ebp
  1044ad:	c3                   	ret    

001044ae <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  1044ae:	55                   	push   %ebp
  1044af:	89 e5                	mov    %esp,%ebp
  1044b1:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  1044b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1044b7:	0f b6 c0             	movzbl %al,%eax
  1044ba:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1044c1:	88 45 f3             	mov    %al,-0xd(%ebp)
  1044c4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1044c8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1044cb:	ee                   	out    %al,(%dx)
  1044cc:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1044d3:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1044d6:	89 c2                	mov    %eax,%edx
  1044d8:	ec                   	in     (%dx),%al
  1044d9:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  1044dc:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  1044e0:	0f b6 c0             	movzbl %al,%eax
}
  1044e3:	c9                   	leave  
  1044e4:	c3                   	ret    

001044e5 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  1044e5:	55                   	push   %ebp
  1044e6:	89 e5                	mov    %esp,%ebp
  1044e8:	53                   	push   %ebx
  1044e9:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  1044ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1044ef:	89 04 24             	mov    %eax,(%esp)
  1044f2:	e8 b7 ff ff ff       	call   1044ae <nvram_read>
  1044f7:	89 c3                	mov    %eax,%ebx
  1044f9:	8b 45 08             	mov    0x8(%ebp),%eax
  1044fc:	83 c0 01             	add    $0x1,%eax
  1044ff:	89 04 24             	mov    %eax,(%esp)
  104502:	e8 a7 ff ff ff       	call   1044ae <nvram_read>
  104507:	c1 e0 08             	shl    $0x8,%eax
  10450a:	09 d8                	or     %ebx,%eax
}
  10450c:	83 c4 04             	add    $0x4,%esp
  10450f:	5b                   	pop    %ebx
  104510:	5d                   	pop    %ebp
  104511:	c3                   	ret    

00104512 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  104512:	55                   	push   %ebp
  104513:	89 e5                	mov    %esp,%ebp
  104515:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  104518:	8b 45 08             	mov    0x8(%ebp),%eax
  10451b:	0f b6 c0             	movzbl %al,%eax
  10451e:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  104525:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  104528:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10452c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10452f:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  104530:	8b 45 0c             	mov    0xc(%ebp),%eax
  104533:	0f b6 c0             	movzbl %al,%eax
  104536:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  10453d:	88 45 fb             	mov    %al,-0x5(%ebp)
  104540:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  104544:	8b 55 fc             	mov    -0x4(%ebp),%edx
  104547:	ee                   	out    %al,(%dx)
}
  104548:	c9                   	leave  
  104549:	c3                   	ret    

0010454a <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10454a:	55                   	push   %ebp
  10454b:	89 e5                	mov    %esp,%ebp
  10454d:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  104550:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  104553:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  104556:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104559:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10455c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104561:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  104564:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104567:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10456d:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  104572:	74 24                	je     104598 <cpu_cur+0x4e>
  104574:	c7 44 24 0c 4a 69 10 	movl   $0x10694a,0xc(%esp)
  10457b:	00 
  10457c:	c7 44 24 08 60 69 10 	movl   $0x106960,0x8(%esp)
  104583:	00 
  104584:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10458b:	00 
  10458c:	c7 04 24 75 69 10 00 	movl   $0x106975,(%esp)
  104593:	e8 e9 be ff ff       	call   100481 <debug_panic>
	return c;
  104598:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10459b:	c9                   	leave  
  10459c:	c3                   	ret    

0010459d <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  10459d:	55                   	push   %ebp
  10459e:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  1045a0:	a1 0c eb 30 00       	mov    0x30eb0c,%eax
  1045a5:	8b 55 08             	mov    0x8(%ebp),%edx
  1045a8:	c1 e2 02             	shl    $0x2,%edx
  1045ab:	8d 14 10             	lea    (%eax,%edx,1),%edx
  1045ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045b1:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  1045b3:	a1 0c eb 30 00       	mov    0x30eb0c,%eax
  1045b8:	83 c0 20             	add    $0x20,%eax
  1045bb:	8b 00                	mov    (%eax),%eax
}
  1045bd:	5d                   	pop    %ebp
  1045be:	c3                   	ret    

001045bf <lapic_init>:

void
lapic_init()
{
  1045bf:	55                   	push   %ebp
  1045c0:	89 e5                	mov    %esp,%ebp
  1045c2:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  1045c5:	a1 0c eb 30 00       	mov    0x30eb0c,%eax
  1045ca:	85 c0                	test   %eax,%eax
  1045cc:	0f 84 82 01 00 00    	je     104754 <lapic_init+0x195>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  1045d2:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  1045d9:	00 
  1045da:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  1045e1:	e8 b7 ff ff ff       	call   10459d <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  1045e6:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  1045ed:	00 
  1045ee:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  1045f5:	e8 a3 ff ff ff       	call   10459d <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  1045fa:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  104601:	00 
  104602:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  104609:	e8 8f ff ff ff       	call   10459d <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  10460e:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  104615:	00 
  104616:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  10461d:	e8 7b ff ff ff       	call   10459d <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  104622:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  104629:	00 
  10462a:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  104631:	e8 67 ff ff ff       	call   10459d <lapicw>
	lapicw(LINT1, MASKED);
  104636:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10463d:	00 
  10463e:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  104645:	e8 53 ff ff ff       	call   10459d <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  10464a:	a1 0c eb 30 00       	mov    0x30eb0c,%eax
  10464f:	83 c0 30             	add    $0x30,%eax
  104652:	8b 00                	mov    (%eax),%eax
  104654:	c1 e8 10             	shr    $0x10,%eax
  104657:	25 ff 00 00 00       	and    $0xff,%eax
  10465c:	83 f8 03             	cmp    $0x3,%eax
  10465f:	76 14                	jbe    104675 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  104661:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  104668:	00 
  104669:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  104670:	e8 28 ff ff ff       	call   10459d <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  104675:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  10467c:	00 
  10467d:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  104684:	e8 14 ff ff ff       	call   10459d <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  104689:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  104690:	ff 
  104691:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  104698:	e8 00 ff ff ff       	call   10459d <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  10469d:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  1046a4:	f0 
  1046a5:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  1046ac:	e8 ec fe ff ff       	call   10459d <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  1046b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046b8:	00 
  1046b9:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1046c0:	e8 d8 fe ff ff       	call   10459d <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  1046c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046cc:	00 
  1046cd:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1046d4:	e8 c4 fe ff ff       	call   10459d <lapicw>
	lapicw(ESR, 0);
  1046d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046e0:	00 
  1046e1:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1046e8:	e8 b0 fe ff ff       	call   10459d <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  1046ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046f4:	00 
  1046f5:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  1046fc:	e8 9c fe ff ff       	call   10459d <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  104701:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104708:	00 
  104709:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  104710:	e8 88 fe ff ff       	call   10459d <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  104715:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  10471c:	00 
  10471d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104724:	e8 74 fe ff ff       	call   10459d <lapicw>
	while(lapic[ICRLO] & DELIVS)
  104729:	a1 0c eb 30 00       	mov    0x30eb0c,%eax
  10472e:	05 00 03 00 00       	add    $0x300,%eax
  104733:	8b 00                	mov    (%eax),%eax
  104735:	25 00 10 00 00       	and    $0x1000,%eax
  10473a:	85 c0                	test   %eax,%eax
  10473c:	75 eb                	jne    104729 <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  10473e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104745:	00 
  104746:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10474d:	e8 4b fe ff ff       	call   10459d <lapicw>
  104752:	eb 01                	jmp    104755 <lapic_init+0x196>

void
lapic_init()
{
	if (!lapic) 
		return;
  104754:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  104755:	c9                   	leave  
  104756:	c3                   	ret    

00104757 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  104757:	55                   	push   %ebp
  104758:	89 e5                	mov    %esp,%ebp
  10475a:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  10475d:	a1 0c eb 30 00       	mov    0x30eb0c,%eax
  104762:	85 c0                	test   %eax,%eax
  104764:	74 14                	je     10477a <lapic_eoi+0x23>
		lapicw(EOI, 0);
  104766:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10476d:	00 
  10476e:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  104775:	e8 23 fe ff ff       	call   10459d <lapicw>
}
  10477a:	c9                   	leave  
  10477b:	c3                   	ret    

0010477c <lapic_errintr>:

void lapic_errintr(void)
{
  10477c:	55                   	push   %ebp
  10477d:	89 e5                	mov    %esp,%ebp
  10477f:	53                   	push   %ebx
  104780:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  104783:	e8 cf ff ff ff       	call   104757 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  104788:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10478f:	00 
  104790:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  104797:	e8 01 fe ff ff       	call   10459d <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  10479c:	a1 0c eb 30 00       	mov    0x30eb0c,%eax
  1047a1:	05 80 02 00 00       	add    $0x280,%eax
  1047a6:	8b 18                	mov    (%eax),%ebx
  1047a8:	e8 9d fd ff ff       	call   10454a <cpu_cur>
  1047ad:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1047b4:	0f b6 c0             	movzbl %al,%eax
  1047b7:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  1047bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1047bf:	c7 44 24 08 82 69 10 	movl   $0x106982,0x8(%esp)
  1047c6:	00 
  1047c7:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  1047ce:	00 
  1047cf:	c7 04 24 9c 69 10 00 	movl   $0x10699c,(%esp)
  1047d6:	e8 65 bd ff ff       	call   100540 <debug_warn>
}
  1047db:	83 c4 24             	add    $0x24,%esp
  1047de:	5b                   	pop    %ebx
  1047df:	5d                   	pop    %ebp
  1047e0:	c3                   	ret    

001047e1 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  1047e1:	55                   	push   %ebp
  1047e2:	89 e5                	mov    %esp,%ebp
}
  1047e4:	5d                   	pop    %ebp
  1047e5:	c3                   	ret    

001047e6 <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  1047e6:	55                   	push   %ebp
  1047e7:	89 e5                	mov    %esp,%ebp
  1047e9:	83 ec 2c             	sub    $0x2c,%esp
  1047ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1047ef:	88 45 dc             	mov    %al,-0x24(%ebp)
  1047f2:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1047f9:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1047fd:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104801:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104804:	ee                   	out    %al,(%dx)
  104805:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  10480c:	c6 45 fb 0a          	movb   $0xa,-0x5(%ebp)
  104810:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  104814:	8b 55 fc             	mov    -0x4(%ebp),%edx
  104817:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  104818:	c7 45 ec 67 04 00 00 	movl   $0x467,-0x14(%ebp)
	wrv[0] = 0;
  10481f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104822:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  104827:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10482a:	8d 50 02             	lea    0x2(%eax),%edx
  10482d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104830:	c1 e8 04             	shr    $0x4,%eax
  104833:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  104836:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  10483a:	c1 e0 18             	shl    $0x18,%eax
  10483d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104841:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  104848:	e8 50 fd ff ff       	call   10459d <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  10484d:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  104854:	00 
  104855:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10485c:	e8 3c fd ff ff       	call   10459d <lapicw>
	microdelay(200);
  104861:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  104868:	e8 74 ff ff ff       	call   1047e1 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  10486d:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  104874:	00 
  104875:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10487c:	e8 1c fd ff ff       	call   10459d <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  104881:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  104888:	e8 54 ff ff ff       	call   1047e1 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  10488d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  104894:	eb 40                	jmp    1048d6 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  104896:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  10489a:	c1 e0 18             	shl    $0x18,%eax
  10489d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048a1:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1048a8:	e8 f0 fc ff ff       	call   10459d <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  1048ad:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048b0:	c1 e8 0c             	shr    $0xc,%eax
  1048b3:	80 cc 06             	or     $0x6,%ah
  1048b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048ba:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1048c1:	e8 d7 fc ff ff       	call   10459d <lapicw>
		microdelay(200);
  1048c6:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1048cd:	e8 0f ff ff ff       	call   1047e1 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  1048d2:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  1048d6:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
  1048da:	7e ba                	jle    104896 <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  1048dc:	c9                   	leave  
  1048dd:	c3                   	ret    

001048de <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  1048de:	55                   	push   %ebp
  1048df:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  1048e1:	a1 00 e4 30 00       	mov    0x30e400,%eax
  1048e6:	8b 55 08             	mov    0x8(%ebp),%edx
  1048e9:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  1048eb:	a1 00 e4 30 00       	mov    0x30e400,%eax
  1048f0:	8b 40 10             	mov    0x10(%eax),%eax
}
  1048f3:	5d                   	pop    %ebp
  1048f4:	c3                   	ret    

001048f5 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  1048f5:	55                   	push   %ebp
  1048f6:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  1048f8:	a1 00 e4 30 00       	mov    0x30e400,%eax
  1048fd:	8b 55 08             	mov    0x8(%ebp),%edx
  104900:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  104902:	a1 00 e4 30 00       	mov    0x30e400,%eax
  104907:	8b 55 0c             	mov    0xc(%ebp),%edx
  10490a:	89 50 10             	mov    %edx,0x10(%eax)
}
  10490d:	5d                   	pop    %ebp
  10490e:	c3                   	ret    

0010490f <ioapic_init>:

void
ioapic_init(void)
{
  10490f:	55                   	push   %ebp
  104910:	89 e5                	mov    %esp,%ebp
  104912:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  104915:	a1 04 e4 30 00       	mov    0x30e404,%eax
  10491a:	85 c0                	test   %eax,%eax
  10491c:	0f 84 fd 00 00 00    	je     104a1f <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  104922:	a1 00 e4 30 00       	mov    0x30e400,%eax
  104927:	85 c0                	test   %eax,%eax
  104929:	75 0a                	jne    104935 <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  10492b:	c7 05 00 e4 30 00 00 	movl   $0xfec00000,0x30e400
  104932:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  104935:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10493c:	e8 9d ff ff ff       	call   1048de <ioapic_read>
  104941:	c1 e8 10             	shr    $0x10,%eax
  104944:	25 ff 00 00 00       	and    $0xff,%eax
  104949:	89 45 f4             	mov    %eax,-0xc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  10494c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104953:	e8 86 ff ff ff       	call   1048de <ioapic_read>
  104958:	c1 e8 18             	shr    $0x18,%eax
  10495b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  10495e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104962:	75 2a                	jne    10498e <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  104964:	0f b6 05 fc e3 30 00 	movzbl 0x30e3fc,%eax
  10496b:	0f b6 c0             	movzbl %al,%eax
  10496e:	c1 e0 18             	shl    $0x18,%eax
  104971:	89 44 24 04          	mov    %eax,0x4(%esp)
  104975:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10497c:	e8 74 ff ff ff       	call   1048f5 <ioapic_write>
		id = ioapicid;
  104981:	0f b6 05 fc e3 30 00 	movzbl 0x30e3fc,%eax
  104988:	0f b6 c0             	movzbl %al,%eax
  10498b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  10498e:	0f b6 05 fc e3 30 00 	movzbl 0x30e3fc,%eax
  104995:	0f b6 c0             	movzbl %al,%eax
  104998:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10499b:	74 31                	je     1049ce <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  10499d:	0f b6 05 fc e3 30 00 	movzbl 0x30e3fc,%eax
  1049a4:	0f b6 c0             	movzbl %al,%eax
  1049a7:	89 44 24 10          	mov    %eax,0x10(%esp)
  1049ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1049ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1049b2:	c7 44 24 08 a8 69 10 	movl   $0x1069a8,0x8(%esp)
  1049b9:	00 
  1049ba:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  1049c1:	00 
  1049c2:	c7 04 24 c9 69 10 00 	movl   $0x1069c9,(%esp)
  1049c9:	e8 72 bb ff ff       	call   100540 <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  1049ce:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1049d5:	eb 3e                	jmp    104a15 <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  1049d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1049da:	83 c0 20             	add    $0x20,%eax
  1049dd:	0d 00 00 01 00       	or     $0x10000,%eax
  1049e2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1049e5:	83 c2 08             	add    $0x8,%edx
  1049e8:	01 d2                	add    %edx,%edx
  1049ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049ee:	89 14 24             	mov    %edx,(%esp)
  1049f1:	e8 ff fe ff ff       	call   1048f5 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  1049f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1049f9:	83 c0 08             	add    $0x8,%eax
  1049fc:	01 c0                	add    %eax,%eax
  1049fe:	83 c0 01             	add    $0x1,%eax
  104a01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104a08:	00 
  104a09:	89 04 24             	mov    %eax,(%esp)
  104a0c:	e8 e4 fe ff ff       	call   1048f5 <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  104a11:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  104a15:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104a18:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  104a1b:	7e ba                	jle    1049d7 <ioapic_init+0xc8>
  104a1d:	eb 01                	jmp    104a20 <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  104a1f:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  104a20:	c9                   	leave  
  104a21:	c3                   	ret    

00104a22 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  104a22:	55                   	push   %ebp
  104a23:	89 e5                	mov    %esp,%ebp
  104a25:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  104a28:	a1 04 e4 30 00       	mov    0x30e404,%eax
  104a2d:	85 c0                	test   %eax,%eax
  104a2f:	74 3a                	je     104a6b <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  104a31:	8b 45 08             	mov    0x8(%ebp),%eax
  104a34:	83 c0 20             	add    $0x20,%eax
  104a37:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  104a3a:	8b 55 08             	mov    0x8(%ebp),%edx
  104a3d:	83 c2 08             	add    $0x8,%edx
  104a40:	01 d2                	add    %edx,%edx
  104a42:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a46:	89 14 24             	mov    %edx,(%esp)
  104a49:	e8 a7 fe ff ff       	call   1048f5 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  104a4e:	8b 45 08             	mov    0x8(%ebp),%eax
  104a51:	83 c0 08             	add    $0x8,%eax
  104a54:	01 c0                	add    %eax,%eax
  104a56:	83 c0 01             	add    $0x1,%eax
  104a59:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  104a60:	ff 
  104a61:	89 04 24             	mov    %eax,(%esp)
  104a64:	e8 8c fe ff ff       	call   1048f5 <ioapic_write>
  104a69:	eb 01                	jmp    104a6c <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  104a6b:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  104a6c:	c9                   	leave  
  104a6d:	c3                   	ret    

00104a6e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  104a6e:	55                   	push   %ebp
  104a6f:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  104a71:	8b 45 08             	mov    0x8(%ebp),%eax
  104a74:	8b 40 18             	mov    0x18(%eax),%eax
  104a77:	83 e0 02             	and    $0x2,%eax
  104a7a:	85 c0                	test   %eax,%eax
  104a7c:	74 1c                	je     104a9a <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  104a7e:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a81:	8b 00                	mov    (%eax),%eax
  104a83:	8d 50 08             	lea    0x8(%eax),%edx
  104a86:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a89:	89 10                	mov    %edx,(%eax)
  104a8b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a8e:	8b 00                	mov    (%eax),%eax
  104a90:	83 e8 08             	sub    $0x8,%eax
  104a93:	8b 50 04             	mov    0x4(%eax),%edx
  104a96:	8b 00                	mov    (%eax),%eax
  104a98:	eb 47                	jmp    104ae1 <getuint+0x73>
	else if (st->flags & F_L)
  104a9a:	8b 45 08             	mov    0x8(%ebp),%eax
  104a9d:	8b 40 18             	mov    0x18(%eax),%eax
  104aa0:	83 e0 01             	and    $0x1,%eax
  104aa3:	84 c0                	test   %al,%al
  104aa5:	74 1e                	je     104ac5 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  104aa7:	8b 45 0c             	mov    0xc(%ebp),%eax
  104aaa:	8b 00                	mov    (%eax),%eax
  104aac:	8d 50 04             	lea    0x4(%eax),%edx
  104aaf:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ab2:	89 10                	mov    %edx,(%eax)
  104ab4:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ab7:	8b 00                	mov    (%eax),%eax
  104ab9:	83 e8 04             	sub    $0x4,%eax
  104abc:	8b 00                	mov    (%eax),%eax
  104abe:	ba 00 00 00 00       	mov    $0x0,%edx
  104ac3:	eb 1c                	jmp    104ae1 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  104ac5:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ac8:	8b 00                	mov    (%eax),%eax
  104aca:	8d 50 04             	lea    0x4(%eax),%edx
  104acd:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ad0:	89 10                	mov    %edx,(%eax)
  104ad2:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ad5:	8b 00                	mov    (%eax),%eax
  104ad7:	83 e8 04             	sub    $0x4,%eax
  104ada:	8b 00                	mov    (%eax),%eax
  104adc:	ba 00 00 00 00       	mov    $0x0,%edx
}
  104ae1:	5d                   	pop    %ebp
  104ae2:	c3                   	ret    

00104ae3 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  104ae3:	55                   	push   %ebp
  104ae4:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  104ae6:	8b 45 08             	mov    0x8(%ebp),%eax
  104ae9:	8b 40 18             	mov    0x18(%eax),%eax
  104aec:	83 e0 02             	and    $0x2,%eax
  104aef:	85 c0                	test   %eax,%eax
  104af1:	74 1c                	je     104b0f <getint+0x2c>
		return va_arg(*ap, long long);
  104af3:	8b 45 0c             	mov    0xc(%ebp),%eax
  104af6:	8b 00                	mov    (%eax),%eax
  104af8:	8d 50 08             	lea    0x8(%eax),%edx
  104afb:	8b 45 0c             	mov    0xc(%ebp),%eax
  104afe:	89 10                	mov    %edx,(%eax)
  104b00:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b03:	8b 00                	mov    (%eax),%eax
  104b05:	83 e8 08             	sub    $0x8,%eax
  104b08:	8b 50 04             	mov    0x4(%eax),%edx
  104b0b:	8b 00                	mov    (%eax),%eax
  104b0d:	eb 47                	jmp    104b56 <getint+0x73>
	else if (st->flags & F_L)
  104b0f:	8b 45 08             	mov    0x8(%ebp),%eax
  104b12:	8b 40 18             	mov    0x18(%eax),%eax
  104b15:	83 e0 01             	and    $0x1,%eax
  104b18:	84 c0                	test   %al,%al
  104b1a:	74 1e                	je     104b3a <getint+0x57>
		return va_arg(*ap, long);
  104b1c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b1f:	8b 00                	mov    (%eax),%eax
  104b21:	8d 50 04             	lea    0x4(%eax),%edx
  104b24:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b27:	89 10                	mov    %edx,(%eax)
  104b29:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b2c:	8b 00                	mov    (%eax),%eax
  104b2e:	83 e8 04             	sub    $0x4,%eax
  104b31:	8b 00                	mov    (%eax),%eax
  104b33:	89 c2                	mov    %eax,%edx
  104b35:	c1 fa 1f             	sar    $0x1f,%edx
  104b38:	eb 1c                	jmp    104b56 <getint+0x73>
	else
		return va_arg(*ap, int);
  104b3a:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b3d:	8b 00                	mov    (%eax),%eax
  104b3f:	8d 50 04             	lea    0x4(%eax),%edx
  104b42:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b45:	89 10                	mov    %edx,(%eax)
  104b47:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b4a:	8b 00                	mov    (%eax),%eax
  104b4c:	83 e8 04             	sub    $0x4,%eax
  104b4f:	8b 00                	mov    (%eax),%eax
  104b51:	89 c2                	mov    %eax,%edx
  104b53:	c1 fa 1f             	sar    $0x1f,%edx
}
  104b56:	5d                   	pop    %ebp
  104b57:	c3                   	ret    

00104b58 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  104b58:	55                   	push   %ebp
  104b59:	89 e5                	mov    %esp,%ebp
  104b5b:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  104b5e:	eb 1a                	jmp    104b7a <putpad+0x22>
		st->putch(st->padc, st->putdat);
  104b60:	8b 45 08             	mov    0x8(%ebp),%eax
  104b63:	8b 08                	mov    (%eax),%ecx
  104b65:	8b 45 08             	mov    0x8(%ebp),%eax
  104b68:	8b 50 04             	mov    0x4(%eax),%edx
  104b6b:	8b 45 08             	mov    0x8(%ebp),%eax
  104b6e:	8b 40 08             	mov    0x8(%eax),%eax
  104b71:	89 54 24 04          	mov    %edx,0x4(%esp)
  104b75:	89 04 24             	mov    %eax,(%esp)
  104b78:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  104b7a:	8b 45 08             	mov    0x8(%ebp),%eax
  104b7d:	8b 40 0c             	mov    0xc(%eax),%eax
  104b80:	8d 50 ff             	lea    -0x1(%eax),%edx
  104b83:	8b 45 08             	mov    0x8(%ebp),%eax
  104b86:	89 50 0c             	mov    %edx,0xc(%eax)
  104b89:	8b 45 08             	mov    0x8(%ebp),%eax
  104b8c:	8b 40 0c             	mov    0xc(%eax),%eax
  104b8f:	85 c0                	test   %eax,%eax
  104b91:	79 cd                	jns    104b60 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  104b93:	c9                   	leave  
  104b94:	c3                   	ret    

00104b95 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  104b95:	55                   	push   %ebp
  104b96:	89 e5                	mov    %esp,%ebp
  104b98:	53                   	push   %ebx
  104b99:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  104b9c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104ba0:	79 18                	jns    104bba <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  104ba2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104ba9:	00 
  104baa:	8b 45 0c             	mov    0xc(%ebp),%eax
  104bad:	89 04 24             	mov    %eax,(%esp)
  104bb0:	e8 e7 07 00 00       	call   10539c <strchr>
  104bb5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104bb8:	eb 2c                	jmp    104be6 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  104bba:	8b 45 10             	mov    0x10(%ebp),%eax
  104bbd:	89 44 24 08          	mov    %eax,0x8(%esp)
  104bc1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104bc8:	00 
  104bc9:	8b 45 0c             	mov    0xc(%ebp),%eax
  104bcc:	89 04 24             	mov    %eax,(%esp)
  104bcf:	e8 cc 09 00 00       	call   1055a0 <memchr>
  104bd4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104bd7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104bdb:	75 09                	jne    104be6 <putstr+0x51>
		lim = str + maxlen;
  104bdd:	8b 45 10             	mov    0x10(%ebp),%eax
  104be0:	03 45 0c             	add    0xc(%ebp),%eax
  104be3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  104be6:	8b 45 08             	mov    0x8(%ebp),%eax
  104be9:	8b 40 0c             	mov    0xc(%eax),%eax
  104bec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  104bef:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104bf2:	89 cb                	mov    %ecx,%ebx
  104bf4:	29 d3                	sub    %edx,%ebx
  104bf6:	89 da                	mov    %ebx,%edx
  104bf8:	8d 14 10             	lea    (%eax,%edx,1),%edx
  104bfb:	8b 45 08             	mov    0x8(%ebp),%eax
  104bfe:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  104c01:	8b 45 08             	mov    0x8(%ebp),%eax
  104c04:	8b 40 18             	mov    0x18(%eax),%eax
  104c07:	83 e0 10             	and    $0x10,%eax
  104c0a:	85 c0                	test   %eax,%eax
  104c0c:	75 32                	jne    104c40 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  104c0e:	8b 45 08             	mov    0x8(%ebp),%eax
  104c11:	89 04 24             	mov    %eax,(%esp)
  104c14:	e8 3f ff ff ff       	call   104b58 <putpad>
	while (str < lim) {
  104c19:	eb 25                	jmp    104c40 <putstr+0xab>
		char ch = *str++;
  104c1b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c1e:	0f b6 00             	movzbl (%eax),%eax
  104c21:	88 45 f7             	mov    %al,-0x9(%ebp)
  104c24:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  104c28:	8b 45 08             	mov    0x8(%ebp),%eax
  104c2b:	8b 08                	mov    (%eax),%ecx
  104c2d:	8b 45 08             	mov    0x8(%ebp),%eax
  104c30:	8b 50 04             	mov    0x4(%eax),%edx
  104c33:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  104c37:	89 54 24 04          	mov    %edx,0x4(%esp)
  104c3b:	89 04 24             	mov    %eax,(%esp)
  104c3e:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  104c40:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c43:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104c46:	72 d3                	jb     104c1b <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  104c48:	8b 45 08             	mov    0x8(%ebp),%eax
  104c4b:	89 04 24             	mov    %eax,(%esp)
  104c4e:	e8 05 ff ff ff       	call   104b58 <putpad>
}
  104c53:	83 c4 24             	add    $0x24,%esp
  104c56:	5b                   	pop    %ebx
  104c57:	5d                   	pop    %ebp
  104c58:	c3                   	ret    

00104c59 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  104c59:	55                   	push   %ebp
  104c5a:	89 e5                	mov    %esp,%ebp
  104c5c:	53                   	push   %ebx
  104c5d:	83 ec 24             	sub    $0x24,%esp
  104c60:	8b 45 10             	mov    0x10(%ebp),%eax
  104c63:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104c66:	8b 45 14             	mov    0x14(%ebp),%eax
  104c69:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  104c6c:	8b 45 08             	mov    0x8(%ebp),%eax
  104c6f:	8b 40 1c             	mov    0x1c(%eax),%eax
  104c72:	89 c2                	mov    %eax,%edx
  104c74:	c1 fa 1f             	sar    $0x1f,%edx
  104c77:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104c7a:	77 4e                	ja     104cca <genint+0x71>
  104c7c:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104c7f:	72 05                	jb     104c86 <genint+0x2d>
  104c81:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104c84:	77 44                	ja     104cca <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  104c86:	8b 45 08             	mov    0x8(%ebp),%eax
  104c89:	8b 40 1c             	mov    0x1c(%eax),%eax
  104c8c:	89 c2                	mov    %eax,%edx
  104c8e:	c1 fa 1f             	sar    $0x1f,%edx
  104c91:	89 44 24 08          	mov    %eax,0x8(%esp)
  104c95:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104c99:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104c9c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104c9f:	89 04 24             	mov    %eax,(%esp)
  104ca2:	89 54 24 04          	mov    %edx,0x4(%esp)
  104ca6:	e8 35 09 00 00       	call   1055e0 <__udivdi3>
  104cab:	89 44 24 08          	mov    %eax,0x8(%esp)
  104caf:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104cb3:	8b 45 0c             	mov    0xc(%ebp),%eax
  104cb6:	89 44 24 04          	mov    %eax,0x4(%esp)
  104cba:	8b 45 08             	mov    0x8(%ebp),%eax
  104cbd:	89 04 24             	mov    %eax,(%esp)
  104cc0:	e8 94 ff ff ff       	call   104c59 <genint>
  104cc5:	89 45 0c             	mov    %eax,0xc(%ebp)
  104cc8:	eb 1b                	jmp    104ce5 <genint+0x8c>
	else if (st->signc >= 0)
  104cca:	8b 45 08             	mov    0x8(%ebp),%eax
  104ccd:	8b 40 14             	mov    0x14(%eax),%eax
  104cd0:	85 c0                	test   %eax,%eax
  104cd2:	78 11                	js     104ce5 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  104cd4:	8b 45 08             	mov    0x8(%ebp),%eax
  104cd7:	8b 40 14             	mov    0x14(%eax),%eax
  104cda:	89 c2                	mov    %eax,%edx
  104cdc:	8b 45 0c             	mov    0xc(%ebp),%eax
  104cdf:	88 10                	mov    %dl,(%eax)
  104ce1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  104ce5:	8b 45 08             	mov    0x8(%ebp),%eax
  104ce8:	8b 40 1c             	mov    0x1c(%eax),%eax
  104ceb:	89 c1                	mov    %eax,%ecx
  104ced:	89 c3                	mov    %eax,%ebx
  104cef:	c1 fb 1f             	sar    $0x1f,%ebx
  104cf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104cf5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104cf8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  104cfc:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  104d00:	89 04 24             	mov    %eax,(%esp)
  104d03:	89 54 24 04          	mov    %edx,0x4(%esp)
  104d07:	e8 04 0a 00 00       	call   105710 <__umoddi3>
  104d0c:	05 d8 69 10 00       	add    $0x1069d8,%eax
  104d11:	0f b6 10             	movzbl (%eax),%edx
  104d14:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d17:	88 10                	mov    %dl,(%eax)
  104d19:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  104d1d:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  104d20:	83 c4 24             	add    $0x24,%esp
  104d23:	5b                   	pop    %ebx
  104d24:	5d                   	pop    %ebp
  104d25:	c3                   	ret    

00104d26 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  104d26:	55                   	push   %ebp
  104d27:	89 e5                	mov    %esp,%ebp
  104d29:	83 ec 58             	sub    $0x58,%esp
  104d2c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d2f:	89 45 c0             	mov    %eax,-0x40(%ebp)
  104d32:	8b 45 10             	mov    0x10(%ebp),%eax
  104d35:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  104d38:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104d3b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  104d3e:	8b 45 08             	mov    0x8(%ebp),%eax
  104d41:	8b 55 14             	mov    0x14(%ebp),%edx
  104d44:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  104d47:	8b 45 c0             	mov    -0x40(%ebp),%eax
  104d4a:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104d4d:	89 44 24 08          	mov    %eax,0x8(%esp)
  104d51:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104d55:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104d58:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d5c:	8b 45 08             	mov    0x8(%ebp),%eax
  104d5f:	89 04 24             	mov    %eax,(%esp)
  104d62:	e8 f2 fe ff ff       	call   104c59 <genint>
  104d67:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  104d6a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104d6d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104d70:	89 d1                	mov    %edx,%ecx
  104d72:	29 c1                	sub    %eax,%ecx
  104d74:	89 c8                	mov    %ecx,%eax
  104d76:	89 44 24 08          	mov    %eax,0x8(%esp)
  104d7a:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d81:	8b 45 08             	mov    0x8(%ebp),%eax
  104d84:	89 04 24             	mov    %eax,(%esp)
  104d87:	e8 09 fe ff ff       	call   104b95 <putstr>
}
  104d8c:	c9                   	leave  
  104d8d:	c3                   	ret    

00104d8e <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  104d8e:	55                   	push   %ebp
  104d8f:	89 e5                	mov    %esp,%ebp
  104d91:	53                   	push   %ebx
  104d92:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  104d95:	8d 55 c8             	lea    -0x38(%ebp),%edx
  104d98:	b9 00 00 00 00       	mov    $0x0,%ecx
  104d9d:	b8 20 00 00 00       	mov    $0x20,%eax
  104da2:	89 c3                	mov    %eax,%ebx
  104da4:	83 e3 fc             	and    $0xfffffffc,%ebx
  104da7:	b8 00 00 00 00       	mov    $0x0,%eax
  104dac:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  104daf:	83 c0 04             	add    $0x4,%eax
  104db2:	39 d8                	cmp    %ebx,%eax
  104db4:	72 f6                	jb     104dac <vprintfmt+0x1e>
  104db6:	01 c2                	add    %eax,%edx
  104db8:	8b 45 08             	mov    0x8(%ebp),%eax
  104dbb:	89 45 c8             	mov    %eax,-0x38(%ebp)
  104dbe:	8b 45 0c             	mov    0xc(%ebp),%eax
  104dc1:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104dc4:	eb 17                	jmp    104ddd <vprintfmt+0x4f>
			if (ch == '\0')
  104dc6:	85 db                	test   %ebx,%ebx
  104dc8:	0f 84 52 03 00 00    	je     105120 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  104dce:	8b 45 0c             	mov    0xc(%ebp),%eax
  104dd1:	89 44 24 04          	mov    %eax,0x4(%esp)
  104dd5:	89 1c 24             	mov    %ebx,(%esp)
  104dd8:	8b 45 08             	mov    0x8(%ebp),%eax
  104ddb:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104ddd:	8b 45 10             	mov    0x10(%ebp),%eax
  104de0:	0f b6 00             	movzbl (%eax),%eax
  104de3:	0f b6 d8             	movzbl %al,%ebx
  104de6:	83 fb 25             	cmp    $0x25,%ebx
  104de9:	0f 95 c0             	setne  %al
  104dec:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104df0:	84 c0                	test   %al,%al
  104df2:	75 d2                	jne    104dc6 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  104df4:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  104dfb:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  104e02:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  104e09:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  104e10:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  104e17:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  104e1e:	eb 04                	jmp    104e24 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  104e20:	90                   	nop
  104e21:	eb 01                	jmp    104e24 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  104e23:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  104e24:	8b 45 10             	mov    0x10(%ebp),%eax
  104e27:	0f b6 00             	movzbl (%eax),%eax
  104e2a:	0f b6 d8             	movzbl %al,%ebx
  104e2d:	89 d8                	mov    %ebx,%eax
  104e2f:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104e33:	83 e8 20             	sub    $0x20,%eax
  104e36:	83 f8 58             	cmp    $0x58,%eax
  104e39:	0f 87 b1 02 00 00    	ja     1050f0 <vprintfmt+0x362>
  104e3f:	8b 04 85 f0 69 10 00 	mov    0x1069f0(,%eax,4),%eax
  104e46:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  104e48:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104e4b:	83 c8 10             	or     $0x10,%eax
  104e4e:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104e51:	eb d1                	jmp    104e24 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  104e53:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  104e5a:	eb c8                	jmp    104e24 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  104e5c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104e5f:	85 c0                	test   %eax,%eax
  104e61:	79 bd                	jns    104e20 <vprintfmt+0x92>
				st.signc = ' ';
  104e63:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  104e6a:	eb b8                	jmp    104e24 <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  104e6c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104e6f:	83 e0 08             	and    $0x8,%eax
  104e72:	85 c0                	test   %eax,%eax
  104e74:	75 07                	jne    104e7d <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  104e76:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104e7d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  104e84:	8b 55 d8             	mov    -0x28(%ebp),%edx
  104e87:	89 d0                	mov    %edx,%eax
  104e89:	c1 e0 02             	shl    $0x2,%eax
  104e8c:	01 d0                	add    %edx,%eax
  104e8e:	01 c0                	add    %eax,%eax
  104e90:	01 d8                	add    %ebx,%eax
  104e92:	83 e8 30             	sub    $0x30,%eax
  104e95:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  104e98:	8b 45 10             	mov    0x10(%ebp),%eax
  104e9b:	0f b6 00             	movzbl (%eax),%eax
  104e9e:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  104ea1:	83 fb 2f             	cmp    $0x2f,%ebx
  104ea4:	7e 21                	jle    104ec7 <vprintfmt+0x139>
  104ea6:	83 fb 39             	cmp    $0x39,%ebx
  104ea9:	7f 1f                	jg     104eca <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104eab:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  104eaf:	eb d3                	jmp    104e84 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  104eb1:	8b 45 14             	mov    0x14(%ebp),%eax
  104eb4:	83 c0 04             	add    $0x4,%eax
  104eb7:	89 45 14             	mov    %eax,0x14(%ebp)
  104eba:	8b 45 14             	mov    0x14(%ebp),%eax
  104ebd:	83 e8 04             	sub    $0x4,%eax
  104ec0:	8b 00                	mov    (%eax),%eax
  104ec2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  104ec5:	eb 04                	jmp    104ecb <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  104ec7:	90                   	nop
  104ec8:	eb 01                	jmp    104ecb <vprintfmt+0x13d>
  104eca:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  104ecb:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104ece:	83 e0 08             	and    $0x8,%eax
  104ed1:	85 c0                	test   %eax,%eax
  104ed3:	0f 85 4a ff ff ff    	jne    104e23 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  104ed9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104edc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  104edf:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  104ee6:	e9 39 ff ff ff       	jmp    104e24 <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  104eeb:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104eee:	83 c8 08             	or     $0x8,%eax
  104ef1:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104ef4:	e9 2b ff ff ff       	jmp    104e24 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  104ef9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104efc:	83 c8 04             	or     $0x4,%eax
  104eff:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104f02:	e9 1d ff ff ff       	jmp    104e24 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  104f07:	8b 55 e0             	mov    -0x20(%ebp),%edx
  104f0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104f0d:	83 e0 01             	and    $0x1,%eax
  104f10:	84 c0                	test   %al,%al
  104f12:	74 07                	je     104f1b <vprintfmt+0x18d>
  104f14:	b8 02 00 00 00       	mov    $0x2,%eax
  104f19:	eb 05                	jmp    104f20 <vprintfmt+0x192>
  104f1b:	b8 01 00 00 00       	mov    $0x1,%eax
  104f20:	09 d0                	or     %edx,%eax
  104f22:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104f25:	e9 fa fe ff ff       	jmp    104e24 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  104f2a:	8b 45 14             	mov    0x14(%ebp),%eax
  104f2d:	83 c0 04             	add    $0x4,%eax
  104f30:	89 45 14             	mov    %eax,0x14(%ebp)
  104f33:	8b 45 14             	mov    0x14(%ebp),%eax
  104f36:	83 e8 04             	sub    $0x4,%eax
  104f39:	8b 00                	mov    (%eax),%eax
  104f3b:	8b 55 0c             	mov    0xc(%ebp),%edx
  104f3e:	89 54 24 04          	mov    %edx,0x4(%esp)
  104f42:	89 04 24             	mov    %eax,(%esp)
  104f45:	8b 45 08             	mov    0x8(%ebp),%eax
  104f48:	ff d0                	call   *%eax
			break;
  104f4a:	e9 cb 01 00 00       	jmp    10511a <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  104f4f:	8b 45 14             	mov    0x14(%ebp),%eax
  104f52:	83 c0 04             	add    $0x4,%eax
  104f55:	89 45 14             	mov    %eax,0x14(%ebp)
  104f58:	8b 45 14             	mov    0x14(%ebp),%eax
  104f5b:	83 e8 04             	sub    $0x4,%eax
  104f5e:	8b 00                	mov    (%eax),%eax
  104f60:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104f63:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104f67:	75 07                	jne    104f70 <vprintfmt+0x1e2>
				s = "(null)";
  104f69:	c7 45 f4 e9 69 10 00 	movl   $0x1069e9,-0xc(%ebp)
			putstr(&st, s, st.prec);
  104f70:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104f73:	89 44 24 08          	mov    %eax,0x8(%esp)
  104f77:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104f7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  104f7e:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104f81:	89 04 24             	mov    %eax,(%esp)
  104f84:	e8 0c fc ff ff       	call   104b95 <putstr>
			break;
  104f89:	e9 8c 01 00 00       	jmp    10511a <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  104f8e:	8d 45 14             	lea    0x14(%ebp),%eax
  104f91:	89 44 24 04          	mov    %eax,0x4(%esp)
  104f95:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104f98:	89 04 24             	mov    %eax,(%esp)
  104f9b:	e8 43 fb ff ff       	call   104ae3 <getint>
  104fa0:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104fa3:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  104fa6:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104fa9:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104fac:	85 d2                	test   %edx,%edx
  104fae:	79 1a                	jns    104fca <vprintfmt+0x23c>
				num = -(intmax_t) num;
  104fb0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104fb3:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104fb6:	f7 d8                	neg    %eax
  104fb8:	83 d2 00             	adc    $0x0,%edx
  104fbb:	f7 da                	neg    %edx
  104fbd:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104fc0:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  104fc3:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  104fca:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104fd1:	00 
  104fd2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104fd5:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104fd8:	89 44 24 04          	mov    %eax,0x4(%esp)
  104fdc:	89 54 24 08          	mov    %edx,0x8(%esp)
  104fe0:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104fe3:	89 04 24             	mov    %eax,(%esp)
  104fe6:	e8 3b fd ff ff       	call   104d26 <putint>
			break;
  104feb:	e9 2a 01 00 00       	jmp    10511a <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  104ff0:	8d 45 14             	lea    0x14(%ebp),%eax
  104ff3:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ff7:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104ffa:	89 04 24             	mov    %eax,(%esp)
  104ffd:	e8 6c fa ff ff       	call   104a6e <getuint>
  105002:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  105009:	00 
  10500a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10500e:	89 54 24 08          	mov    %edx,0x8(%esp)
  105012:	8d 45 c8             	lea    -0x38(%ebp),%eax
  105015:	89 04 24             	mov    %eax,(%esp)
  105018:	e8 09 fd ff ff       	call   104d26 <putint>
			break;
  10501d:	e9 f8 00 00 00       	jmp    10511a <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  105022:	8d 45 14             	lea    0x14(%ebp),%eax
  105025:	89 44 24 04          	mov    %eax,0x4(%esp)
  105029:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10502c:	89 04 24             	mov    %eax,(%esp)
  10502f:	e8 3a fa ff ff       	call   104a6e <getuint>
  105034:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  10503b:	00 
  10503c:	89 44 24 04          	mov    %eax,0x4(%esp)
  105040:	89 54 24 08          	mov    %edx,0x8(%esp)
  105044:	8d 45 c8             	lea    -0x38(%ebp),%eax
  105047:	89 04 24             	mov    %eax,(%esp)
  10504a:	e8 d7 fc ff ff       	call   104d26 <putint>
			break;
  10504f:	e9 c6 00 00 00       	jmp    10511a <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  105054:	8d 45 14             	lea    0x14(%ebp),%eax
  105057:	89 44 24 04          	mov    %eax,0x4(%esp)
  10505b:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10505e:	89 04 24             	mov    %eax,(%esp)
  105061:	e8 08 fa ff ff       	call   104a6e <getuint>
  105066:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10506d:	00 
  10506e:	89 44 24 04          	mov    %eax,0x4(%esp)
  105072:	89 54 24 08          	mov    %edx,0x8(%esp)
  105076:	8d 45 c8             	lea    -0x38(%ebp),%eax
  105079:	89 04 24             	mov    %eax,(%esp)
  10507c:	e8 a5 fc ff ff       	call   104d26 <putint>
			break;
  105081:	e9 94 00 00 00       	jmp    10511a <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  105086:	8b 45 0c             	mov    0xc(%ebp),%eax
  105089:	89 44 24 04          	mov    %eax,0x4(%esp)
  10508d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  105094:	8b 45 08             	mov    0x8(%ebp),%eax
  105097:	ff d0                	call   *%eax
			putch('x', putdat);
  105099:	8b 45 0c             	mov    0xc(%ebp),%eax
  10509c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050a0:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  1050a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1050aa:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  1050ac:	8b 45 14             	mov    0x14(%ebp),%eax
  1050af:	83 c0 04             	add    $0x4,%eax
  1050b2:	89 45 14             	mov    %eax,0x14(%ebp)
  1050b5:	8b 45 14             	mov    0x14(%ebp),%eax
  1050b8:	83 e8 04             	sub    $0x4,%eax
  1050bb:	8b 00                	mov    (%eax),%eax
  1050bd:	ba 00 00 00 00       	mov    $0x0,%edx
  1050c2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1050c9:	00 
  1050ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050ce:	89 54 24 08          	mov    %edx,0x8(%esp)
  1050d2:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1050d5:	89 04 24             	mov    %eax,(%esp)
  1050d8:	e8 49 fc ff ff       	call   104d26 <putint>
			break;
  1050dd:	eb 3b                	jmp    10511a <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  1050df:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050e2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050e6:	89 1c 24             	mov    %ebx,(%esp)
  1050e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1050ec:	ff d0                	call   *%eax
			break;
  1050ee:	eb 2a                	jmp    10511a <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1050f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050f7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  1050fe:	8b 45 08             	mov    0x8(%ebp),%eax
  105101:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  105103:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  105107:	eb 04                	jmp    10510d <vprintfmt+0x37f>
  105109:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10510d:	8b 45 10             	mov    0x10(%ebp),%eax
  105110:	83 e8 01             	sub    $0x1,%eax
  105113:	0f b6 00             	movzbl (%eax),%eax
  105116:	3c 25                	cmp    $0x25,%al
  105118:	75 ef                	jne    105109 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  10511a:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10511b:	e9 bd fc ff ff       	jmp    104ddd <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  105120:	83 c4 44             	add    $0x44,%esp
  105123:	5b                   	pop    %ebx
  105124:	5d                   	pop    %ebp
  105125:	c3                   	ret    

00105126 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  105126:	55                   	push   %ebp
  105127:	89 e5                	mov    %esp,%ebp
  105129:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  10512c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10512f:	8b 00                	mov    (%eax),%eax
  105131:	8b 55 08             	mov    0x8(%ebp),%edx
  105134:	89 d1                	mov    %edx,%ecx
  105136:	8b 55 0c             	mov    0xc(%ebp),%edx
  105139:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  10513d:	8d 50 01             	lea    0x1(%eax),%edx
  105140:	8b 45 0c             	mov    0xc(%ebp),%eax
  105143:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  105145:	8b 45 0c             	mov    0xc(%ebp),%eax
  105148:	8b 00                	mov    (%eax),%eax
  10514a:	3d ff 00 00 00       	cmp    $0xff,%eax
  10514f:	75 24                	jne    105175 <putch+0x4f>
		b->buf[b->idx] = 0;
  105151:	8b 45 0c             	mov    0xc(%ebp),%eax
  105154:	8b 00                	mov    (%eax),%eax
  105156:	8b 55 0c             	mov    0xc(%ebp),%edx
  105159:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  10515e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105161:	83 c0 08             	add    $0x8,%eax
  105164:	89 04 24             	mov    %eax,(%esp)
  105167:	e8 8c b2 ff ff       	call   1003f8 <cputs>
		b->idx = 0;
  10516c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10516f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  105175:	8b 45 0c             	mov    0xc(%ebp),%eax
  105178:	8b 40 04             	mov    0x4(%eax),%eax
  10517b:	8d 50 01             	lea    0x1(%eax),%edx
  10517e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105181:	89 50 04             	mov    %edx,0x4(%eax)
}
  105184:	c9                   	leave  
  105185:	c3                   	ret    

00105186 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  105186:	55                   	push   %ebp
  105187:	89 e5                	mov    %esp,%ebp
  105189:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  10518f:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  105196:	00 00 00 
	b.cnt = 0;
  105199:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  1051a0:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  1051a3:	b8 26 51 10 00       	mov    $0x105126,%eax
  1051a8:	8b 55 0c             	mov    0xc(%ebp),%edx
  1051ab:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1051af:	8b 55 08             	mov    0x8(%ebp),%edx
  1051b2:	89 54 24 08          	mov    %edx,0x8(%esp)
  1051b6:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  1051bc:	89 54 24 04          	mov    %edx,0x4(%esp)
  1051c0:	89 04 24             	mov    %eax,(%esp)
  1051c3:	e8 c6 fb ff ff       	call   104d8e <vprintfmt>

	b.buf[b.idx] = 0;
  1051c8:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  1051ce:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  1051d5:	00 
	cputs(b.buf);
  1051d6:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1051dc:	83 c0 08             	add    $0x8,%eax
  1051df:	89 04 24             	mov    %eax,(%esp)
  1051e2:	e8 11 b2 ff ff       	call   1003f8 <cputs>

	return b.cnt;
  1051e7:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  1051ed:	c9                   	leave  
  1051ee:	c3                   	ret    

001051ef <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1051ef:	55                   	push   %ebp
  1051f0:	89 e5                	mov    %esp,%ebp
  1051f2:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  1051f5:	8d 45 08             	lea    0x8(%ebp),%eax
  1051f8:	83 c0 04             	add    $0x4,%eax
  1051fb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  1051fe:	8b 45 08             	mov    0x8(%ebp),%eax
  105201:	8b 55 f0             	mov    -0x10(%ebp),%edx
  105204:	89 54 24 04          	mov    %edx,0x4(%esp)
  105208:	89 04 24             	mov    %eax,(%esp)
  10520b:	e8 76 ff ff ff       	call   105186 <vcprintf>
  105210:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  105213:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  105216:	c9                   	leave  
  105217:	c3                   	ret    

00105218 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  105218:	55                   	push   %ebp
  105219:	89 e5                	mov    %esp,%ebp
  10521b:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  10521e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  105225:	eb 08                	jmp    10522f <strlen+0x17>
		n++;
  105227:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  10522b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10522f:	8b 45 08             	mov    0x8(%ebp),%eax
  105232:	0f b6 00             	movzbl (%eax),%eax
  105235:	84 c0                	test   %al,%al
  105237:	75 ee                	jne    105227 <strlen+0xf>
		n++;
	return n;
  105239:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10523c:	c9                   	leave  
  10523d:	c3                   	ret    

0010523e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  10523e:	55                   	push   %ebp
  10523f:	89 e5                	mov    %esp,%ebp
  105241:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  105244:	8b 45 08             	mov    0x8(%ebp),%eax
  105247:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  10524a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10524d:	0f b6 10             	movzbl (%eax),%edx
  105250:	8b 45 08             	mov    0x8(%ebp),%eax
  105253:	88 10                	mov    %dl,(%eax)
  105255:	8b 45 08             	mov    0x8(%ebp),%eax
  105258:	0f b6 00             	movzbl (%eax),%eax
  10525b:	84 c0                	test   %al,%al
  10525d:	0f 95 c0             	setne  %al
  105260:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105264:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  105268:	84 c0                	test   %al,%al
  10526a:	75 de                	jne    10524a <strcpy+0xc>
		/* do nothing */;
	return ret;
  10526c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10526f:	c9                   	leave  
  105270:	c3                   	ret    

00105271 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  105271:	55                   	push   %ebp
  105272:	89 e5                	mov    %esp,%ebp
  105274:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  105277:	8b 45 08             	mov    0x8(%ebp),%eax
  10527a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  10527d:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  105284:	eb 21                	jmp    1052a7 <strncpy+0x36>
		*dst++ = *src;
  105286:	8b 45 0c             	mov    0xc(%ebp),%eax
  105289:	0f b6 10             	movzbl (%eax),%edx
  10528c:	8b 45 08             	mov    0x8(%ebp),%eax
  10528f:	88 10                	mov    %dl,(%eax)
  105291:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  105295:	8b 45 0c             	mov    0xc(%ebp),%eax
  105298:	0f b6 00             	movzbl (%eax),%eax
  10529b:	84 c0                	test   %al,%al
  10529d:	74 04                	je     1052a3 <strncpy+0x32>
			src++;
  10529f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  1052a3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1052a7:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1052aa:	3b 45 10             	cmp    0x10(%ebp),%eax
  1052ad:	72 d7                	jb     105286 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  1052af:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1052b2:	c9                   	leave  
  1052b3:	c3                   	ret    

001052b4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  1052b4:	55                   	push   %ebp
  1052b5:	89 e5                	mov    %esp,%ebp
  1052b7:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  1052ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1052bd:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  1052c0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1052c4:	74 2f                	je     1052f5 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  1052c6:	eb 13                	jmp    1052db <strlcpy+0x27>
			*dst++ = *src++;
  1052c8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052cb:	0f b6 10             	movzbl (%eax),%edx
  1052ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1052d1:	88 10                	mov    %dl,(%eax)
  1052d3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1052d7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  1052db:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1052df:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1052e3:	74 0a                	je     1052ef <strlcpy+0x3b>
  1052e5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052e8:	0f b6 00             	movzbl (%eax),%eax
  1052eb:	84 c0                	test   %al,%al
  1052ed:	75 d9                	jne    1052c8 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  1052ef:	8b 45 08             	mov    0x8(%ebp),%eax
  1052f2:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  1052f5:	8b 55 08             	mov    0x8(%ebp),%edx
  1052f8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1052fb:	89 d1                	mov    %edx,%ecx
  1052fd:	29 c1                	sub    %eax,%ecx
  1052ff:	89 c8                	mov    %ecx,%eax
}
  105301:	c9                   	leave  
  105302:	c3                   	ret    

00105303 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  105303:	55                   	push   %ebp
  105304:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  105306:	eb 08                	jmp    105310 <strcmp+0xd>
		p++, q++;
  105308:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10530c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  105310:	8b 45 08             	mov    0x8(%ebp),%eax
  105313:	0f b6 00             	movzbl (%eax),%eax
  105316:	84 c0                	test   %al,%al
  105318:	74 10                	je     10532a <strcmp+0x27>
  10531a:	8b 45 08             	mov    0x8(%ebp),%eax
  10531d:	0f b6 10             	movzbl (%eax),%edx
  105320:	8b 45 0c             	mov    0xc(%ebp),%eax
  105323:	0f b6 00             	movzbl (%eax),%eax
  105326:	38 c2                	cmp    %al,%dl
  105328:	74 de                	je     105308 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  10532a:	8b 45 08             	mov    0x8(%ebp),%eax
  10532d:	0f b6 00             	movzbl (%eax),%eax
  105330:	0f b6 d0             	movzbl %al,%edx
  105333:	8b 45 0c             	mov    0xc(%ebp),%eax
  105336:	0f b6 00             	movzbl (%eax),%eax
  105339:	0f b6 c0             	movzbl %al,%eax
  10533c:	89 d1                	mov    %edx,%ecx
  10533e:	29 c1                	sub    %eax,%ecx
  105340:	89 c8                	mov    %ecx,%eax
}
  105342:	5d                   	pop    %ebp
  105343:	c3                   	ret    

00105344 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  105344:	55                   	push   %ebp
  105345:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  105347:	eb 0c                	jmp    105355 <strncmp+0x11>
		n--, p++, q++;
  105349:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10534d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105351:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  105355:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105359:	74 1a                	je     105375 <strncmp+0x31>
  10535b:	8b 45 08             	mov    0x8(%ebp),%eax
  10535e:	0f b6 00             	movzbl (%eax),%eax
  105361:	84 c0                	test   %al,%al
  105363:	74 10                	je     105375 <strncmp+0x31>
  105365:	8b 45 08             	mov    0x8(%ebp),%eax
  105368:	0f b6 10             	movzbl (%eax),%edx
  10536b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10536e:	0f b6 00             	movzbl (%eax),%eax
  105371:	38 c2                	cmp    %al,%dl
  105373:	74 d4                	je     105349 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  105375:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105379:	75 07                	jne    105382 <strncmp+0x3e>
		return 0;
  10537b:	b8 00 00 00 00       	mov    $0x0,%eax
  105380:	eb 18                	jmp    10539a <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  105382:	8b 45 08             	mov    0x8(%ebp),%eax
  105385:	0f b6 00             	movzbl (%eax),%eax
  105388:	0f b6 d0             	movzbl %al,%edx
  10538b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10538e:	0f b6 00             	movzbl (%eax),%eax
  105391:	0f b6 c0             	movzbl %al,%eax
  105394:	89 d1                	mov    %edx,%ecx
  105396:	29 c1                	sub    %eax,%ecx
  105398:	89 c8                	mov    %ecx,%eax
}
  10539a:	5d                   	pop    %ebp
  10539b:	c3                   	ret    

0010539c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  10539c:	55                   	push   %ebp
  10539d:	89 e5                	mov    %esp,%ebp
  10539f:	83 ec 04             	sub    $0x4,%esp
  1053a2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1053a5:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  1053a8:	eb 1a                	jmp    1053c4 <strchr+0x28>
		if (*s++ == 0)
  1053aa:	8b 45 08             	mov    0x8(%ebp),%eax
  1053ad:	0f b6 00             	movzbl (%eax),%eax
  1053b0:	84 c0                	test   %al,%al
  1053b2:	0f 94 c0             	sete   %al
  1053b5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1053b9:	84 c0                	test   %al,%al
  1053bb:	74 07                	je     1053c4 <strchr+0x28>
			return NULL;
  1053bd:	b8 00 00 00 00       	mov    $0x0,%eax
  1053c2:	eb 0e                	jmp    1053d2 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  1053c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1053c7:	0f b6 00             	movzbl (%eax),%eax
  1053ca:	3a 45 fc             	cmp    -0x4(%ebp),%al
  1053cd:	75 db                	jne    1053aa <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  1053cf:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1053d2:	c9                   	leave  
  1053d3:	c3                   	ret    

001053d4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  1053d4:	55                   	push   %ebp
  1053d5:	89 e5                	mov    %esp,%ebp
  1053d7:	57                   	push   %edi
  1053d8:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  1053db:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1053df:	75 05                	jne    1053e6 <memset+0x12>
		return v;
  1053e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1053e4:	eb 5c                	jmp    105442 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  1053e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1053e9:	83 e0 03             	and    $0x3,%eax
  1053ec:	85 c0                	test   %eax,%eax
  1053ee:	75 41                	jne    105431 <memset+0x5d>
  1053f0:	8b 45 10             	mov    0x10(%ebp),%eax
  1053f3:	83 e0 03             	and    $0x3,%eax
  1053f6:	85 c0                	test   %eax,%eax
  1053f8:	75 37                	jne    105431 <memset+0x5d>
		c &= 0xFF;
  1053fa:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  105401:	8b 45 0c             	mov    0xc(%ebp),%eax
  105404:	89 c2                	mov    %eax,%edx
  105406:	c1 e2 18             	shl    $0x18,%edx
  105409:	8b 45 0c             	mov    0xc(%ebp),%eax
  10540c:	c1 e0 10             	shl    $0x10,%eax
  10540f:	09 c2                	or     %eax,%edx
  105411:	8b 45 0c             	mov    0xc(%ebp),%eax
  105414:	c1 e0 08             	shl    $0x8,%eax
  105417:	09 d0                	or     %edx,%eax
  105419:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  10541c:	8b 45 10             	mov    0x10(%ebp),%eax
  10541f:	89 c1                	mov    %eax,%ecx
  105421:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  105424:	8b 55 08             	mov    0x8(%ebp),%edx
  105427:	8b 45 0c             	mov    0xc(%ebp),%eax
  10542a:	89 d7                	mov    %edx,%edi
  10542c:	fc                   	cld    
  10542d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  10542f:	eb 0e                	jmp    10543f <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  105431:	8b 55 08             	mov    0x8(%ebp),%edx
  105434:	8b 45 0c             	mov    0xc(%ebp),%eax
  105437:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10543a:	89 d7                	mov    %edx,%edi
  10543c:	fc                   	cld    
  10543d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  10543f:	8b 45 08             	mov    0x8(%ebp),%eax
}
  105442:	83 c4 10             	add    $0x10,%esp
  105445:	5f                   	pop    %edi
  105446:	5d                   	pop    %ebp
  105447:	c3                   	ret    

00105448 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  105448:	55                   	push   %ebp
  105449:	89 e5                	mov    %esp,%ebp
  10544b:	57                   	push   %edi
  10544c:	56                   	push   %esi
  10544d:	53                   	push   %ebx
  10544e:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  105451:	8b 45 0c             	mov    0xc(%ebp),%eax
  105454:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  105457:	8b 45 08             	mov    0x8(%ebp),%eax
  10545a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  10545d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105460:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  105463:	73 6e                	jae    1054d3 <memmove+0x8b>
  105465:	8b 45 10             	mov    0x10(%ebp),%eax
  105468:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10546b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10546e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  105471:	76 60                	jbe    1054d3 <memmove+0x8b>
		s += n;
  105473:	8b 45 10             	mov    0x10(%ebp),%eax
  105476:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  105479:	8b 45 10             	mov    0x10(%ebp),%eax
  10547c:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10547f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105482:	83 e0 03             	and    $0x3,%eax
  105485:	85 c0                	test   %eax,%eax
  105487:	75 2f                	jne    1054b8 <memmove+0x70>
  105489:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10548c:	83 e0 03             	and    $0x3,%eax
  10548f:	85 c0                	test   %eax,%eax
  105491:	75 25                	jne    1054b8 <memmove+0x70>
  105493:	8b 45 10             	mov    0x10(%ebp),%eax
  105496:	83 e0 03             	and    $0x3,%eax
  105499:	85 c0                	test   %eax,%eax
  10549b:	75 1b                	jne    1054b8 <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  10549d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054a0:	83 e8 04             	sub    $0x4,%eax
  1054a3:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1054a6:	83 ea 04             	sub    $0x4,%edx
  1054a9:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1054ac:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  1054af:	89 c7                	mov    %eax,%edi
  1054b1:	89 d6                	mov    %edx,%esi
  1054b3:	fd                   	std    
  1054b4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1054b6:	eb 18                	jmp    1054d0 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  1054b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054bb:	8d 50 ff             	lea    -0x1(%eax),%edx
  1054be:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1054c1:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  1054c4:	8b 45 10             	mov    0x10(%ebp),%eax
  1054c7:	89 d7                	mov    %edx,%edi
  1054c9:	89 de                	mov    %ebx,%esi
  1054cb:	89 c1                	mov    %eax,%ecx
  1054cd:	fd                   	std    
  1054ce:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  1054d0:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  1054d1:	eb 45                	jmp    105518 <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1054d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1054d6:	83 e0 03             	and    $0x3,%eax
  1054d9:	85 c0                	test   %eax,%eax
  1054db:	75 2b                	jne    105508 <memmove+0xc0>
  1054dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054e0:	83 e0 03             	and    $0x3,%eax
  1054e3:	85 c0                	test   %eax,%eax
  1054e5:	75 21                	jne    105508 <memmove+0xc0>
  1054e7:	8b 45 10             	mov    0x10(%ebp),%eax
  1054ea:	83 e0 03             	and    $0x3,%eax
  1054ed:	85 c0                	test   %eax,%eax
  1054ef:	75 17                	jne    105508 <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  1054f1:	8b 45 10             	mov    0x10(%ebp),%eax
  1054f4:	89 c1                	mov    %eax,%ecx
  1054f6:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  1054f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054fc:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1054ff:	89 c7                	mov    %eax,%edi
  105501:	89 d6                	mov    %edx,%esi
  105503:	fc                   	cld    
  105504:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  105506:	eb 10                	jmp    105518 <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  105508:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10550b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10550e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  105511:	89 c7                	mov    %eax,%edi
  105513:	89 d6                	mov    %edx,%esi
  105515:	fc                   	cld    
  105516:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  105518:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10551b:	83 c4 10             	add    $0x10,%esp
  10551e:	5b                   	pop    %ebx
  10551f:	5e                   	pop    %esi
  105520:	5f                   	pop    %edi
  105521:	5d                   	pop    %ebp
  105522:	c3                   	ret    

00105523 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  105523:	55                   	push   %ebp
  105524:	89 e5                	mov    %esp,%ebp
  105526:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  105529:	8b 45 10             	mov    0x10(%ebp),%eax
  10552c:	89 44 24 08          	mov    %eax,0x8(%esp)
  105530:	8b 45 0c             	mov    0xc(%ebp),%eax
  105533:	89 44 24 04          	mov    %eax,0x4(%esp)
  105537:	8b 45 08             	mov    0x8(%ebp),%eax
  10553a:	89 04 24             	mov    %eax,(%esp)
  10553d:	e8 06 ff ff ff       	call   105448 <memmove>
}
  105542:	c9                   	leave  
  105543:	c3                   	ret    

00105544 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  105544:	55                   	push   %ebp
  105545:	89 e5                	mov    %esp,%ebp
  105547:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  10554a:	8b 45 08             	mov    0x8(%ebp),%eax
  10554d:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  105550:	8b 45 0c             	mov    0xc(%ebp),%eax
  105553:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  105556:	eb 32                	jmp    10558a <memcmp+0x46>
		if (*s1 != *s2)
  105558:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10555b:	0f b6 10             	movzbl (%eax),%edx
  10555e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105561:	0f b6 00             	movzbl (%eax),%eax
  105564:	38 c2                	cmp    %al,%dl
  105566:	74 1a                	je     105582 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  105568:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10556b:	0f b6 00             	movzbl (%eax),%eax
  10556e:	0f b6 d0             	movzbl %al,%edx
  105571:	8b 45 fc             	mov    -0x4(%ebp),%eax
  105574:	0f b6 00             	movzbl (%eax),%eax
  105577:	0f b6 c0             	movzbl %al,%eax
  10557a:	89 d1                	mov    %edx,%ecx
  10557c:	29 c1                	sub    %eax,%ecx
  10557e:	89 c8                	mov    %ecx,%eax
  105580:	eb 1c                	jmp    10559e <memcmp+0x5a>
		s1++, s2++;
  105582:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  105586:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  10558a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10558e:	0f 95 c0             	setne  %al
  105591:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  105595:	84 c0                	test   %al,%al
  105597:	75 bf                	jne    105558 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  105599:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10559e:	c9                   	leave  
  10559f:	c3                   	ret    

001055a0 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  1055a0:	55                   	push   %ebp
  1055a1:	89 e5                	mov    %esp,%ebp
  1055a3:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  1055a6:	8b 45 10             	mov    0x10(%ebp),%eax
  1055a9:	8b 55 08             	mov    0x8(%ebp),%edx
  1055ac:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1055af:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  1055b2:	eb 16                	jmp    1055ca <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  1055b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1055b7:	0f b6 10             	movzbl (%eax),%edx
  1055ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  1055bd:	38 c2                	cmp    %al,%dl
  1055bf:	75 05                	jne    1055c6 <memchr+0x26>
			return (void *) s;
  1055c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1055c4:	eb 11                	jmp    1055d7 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  1055c6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1055ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1055cd:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  1055d0:	72 e2                	jb     1055b4 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  1055d2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1055d7:	c9                   	leave  
  1055d8:	c3                   	ret    
  1055d9:	66 90                	xchg   %ax,%ax
  1055db:	66 90                	xchg   %ax,%ax
  1055dd:	66 90                	xchg   %ax,%ax
  1055df:	90                   	nop

001055e0 <__udivdi3>:
  1055e0:	55                   	push   %ebp
  1055e1:	89 e5                	mov    %esp,%ebp
  1055e3:	57                   	push   %edi
  1055e4:	56                   	push   %esi
  1055e5:	83 ec 10             	sub    $0x10,%esp
  1055e8:	8b 45 14             	mov    0x14(%ebp),%eax
  1055eb:	8b 55 08             	mov    0x8(%ebp),%edx
  1055ee:	8b 75 10             	mov    0x10(%ebp),%esi
  1055f1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  1055f4:	85 c0                	test   %eax,%eax
  1055f6:	89 55 f0             	mov    %edx,-0x10(%ebp)
  1055f9:	75 35                	jne    105630 <__udivdi3+0x50>
  1055fb:	39 fe                	cmp    %edi,%esi
  1055fd:	77 61                	ja     105660 <__udivdi3+0x80>
  1055ff:	85 f6                	test   %esi,%esi
  105601:	75 0b                	jne    10560e <__udivdi3+0x2e>
  105603:	b8 01 00 00 00       	mov    $0x1,%eax
  105608:	31 d2                	xor    %edx,%edx
  10560a:	f7 f6                	div    %esi
  10560c:	89 c6                	mov    %eax,%esi
  10560e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  105611:	31 d2                	xor    %edx,%edx
  105613:	89 f8                	mov    %edi,%eax
  105615:	f7 f6                	div    %esi
  105617:	89 c7                	mov    %eax,%edi
  105619:	89 c8                	mov    %ecx,%eax
  10561b:	f7 f6                	div    %esi
  10561d:	89 c1                	mov    %eax,%ecx
  10561f:	89 fa                	mov    %edi,%edx
  105621:	89 c8                	mov    %ecx,%eax
  105623:	83 c4 10             	add    $0x10,%esp
  105626:	5e                   	pop    %esi
  105627:	5f                   	pop    %edi
  105628:	5d                   	pop    %ebp
  105629:	c3                   	ret    
  10562a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  105630:	39 f8                	cmp    %edi,%eax
  105632:	77 1c                	ja     105650 <__udivdi3+0x70>
  105634:	0f bd d0             	bsr    %eax,%edx
  105637:	83 f2 1f             	xor    $0x1f,%edx
  10563a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10563d:	75 39                	jne    105678 <__udivdi3+0x98>
  10563f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  105642:	0f 86 a0 00 00 00    	jbe    1056e8 <__udivdi3+0x108>
  105648:	39 f8                	cmp    %edi,%eax
  10564a:	0f 82 98 00 00 00    	jb     1056e8 <__udivdi3+0x108>
  105650:	31 ff                	xor    %edi,%edi
  105652:	31 c9                	xor    %ecx,%ecx
  105654:	89 c8                	mov    %ecx,%eax
  105656:	89 fa                	mov    %edi,%edx
  105658:	83 c4 10             	add    $0x10,%esp
  10565b:	5e                   	pop    %esi
  10565c:	5f                   	pop    %edi
  10565d:	5d                   	pop    %ebp
  10565e:	c3                   	ret    
  10565f:	90                   	nop
  105660:	89 d1                	mov    %edx,%ecx
  105662:	89 fa                	mov    %edi,%edx
  105664:	89 c8                	mov    %ecx,%eax
  105666:	31 ff                	xor    %edi,%edi
  105668:	f7 f6                	div    %esi
  10566a:	89 c1                	mov    %eax,%ecx
  10566c:	89 fa                	mov    %edi,%edx
  10566e:	89 c8                	mov    %ecx,%eax
  105670:	83 c4 10             	add    $0x10,%esp
  105673:	5e                   	pop    %esi
  105674:	5f                   	pop    %edi
  105675:	5d                   	pop    %ebp
  105676:	c3                   	ret    
  105677:	90                   	nop
  105678:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10567c:	89 f2                	mov    %esi,%edx
  10567e:	d3 e0                	shl    %cl,%eax
  105680:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105683:	b8 20 00 00 00       	mov    $0x20,%eax
  105688:	2b 45 f4             	sub    -0xc(%ebp),%eax
  10568b:	89 c1                	mov    %eax,%ecx
  10568d:	d3 ea                	shr    %cl,%edx
  10568f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  105693:	0b 55 ec             	or     -0x14(%ebp),%edx
  105696:	d3 e6                	shl    %cl,%esi
  105698:	89 c1                	mov    %eax,%ecx
  10569a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  10569d:	89 fe                	mov    %edi,%esi
  10569f:	d3 ee                	shr    %cl,%esi
  1056a1:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  1056a5:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1056a8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1056ab:	d3 e7                	shl    %cl,%edi
  1056ad:	89 c1                	mov    %eax,%ecx
  1056af:	d3 ea                	shr    %cl,%edx
  1056b1:	09 d7                	or     %edx,%edi
  1056b3:	89 f2                	mov    %esi,%edx
  1056b5:	89 f8                	mov    %edi,%eax
  1056b7:	f7 75 ec             	divl   -0x14(%ebp)
  1056ba:	89 d6                	mov    %edx,%esi
  1056bc:	89 c7                	mov    %eax,%edi
  1056be:	f7 65 e8             	mull   -0x18(%ebp)
  1056c1:	39 d6                	cmp    %edx,%esi
  1056c3:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1056c6:	72 30                	jb     1056f8 <__udivdi3+0x118>
  1056c8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1056cb:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  1056cf:	d3 e2                	shl    %cl,%edx
  1056d1:	39 c2                	cmp    %eax,%edx
  1056d3:	73 05                	jae    1056da <__udivdi3+0xfa>
  1056d5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  1056d8:	74 1e                	je     1056f8 <__udivdi3+0x118>
  1056da:	89 f9                	mov    %edi,%ecx
  1056dc:	31 ff                	xor    %edi,%edi
  1056de:	e9 71 ff ff ff       	jmp    105654 <__udivdi3+0x74>
  1056e3:	90                   	nop
  1056e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1056e8:	31 ff                	xor    %edi,%edi
  1056ea:	b9 01 00 00 00       	mov    $0x1,%ecx
  1056ef:	e9 60 ff ff ff       	jmp    105654 <__udivdi3+0x74>
  1056f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1056f8:	8d 4f ff             	lea    -0x1(%edi),%ecx
  1056fb:	31 ff                	xor    %edi,%edi
  1056fd:	89 c8                	mov    %ecx,%eax
  1056ff:	89 fa                	mov    %edi,%edx
  105701:	83 c4 10             	add    $0x10,%esp
  105704:	5e                   	pop    %esi
  105705:	5f                   	pop    %edi
  105706:	5d                   	pop    %ebp
  105707:	c3                   	ret    
  105708:	66 90                	xchg   %ax,%ax
  10570a:	66 90                	xchg   %ax,%ax
  10570c:	66 90                	xchg   %ax,%ax
  10570e:	66 90                	xchg   %ax,%ax

00105710 <__umoddi3>:
  105710:	55                   	push   %ebp
  105711:	89 e5                	mov    %esp,%ebp
  105713:	57                   	push   %edi
  105714:	56                   	push   %esi
  105715:	83 ec 20             	sub    $0x20,%esp
  105718:	8b 55 14             	mov    0x14(%ebp),%edx
  10571b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10571e:	8b 7d 10             	mov    0x10(%ebp),%edi
  105721:	8b 75 0c             	mov    0xc(%ebp),%esi
  105724:	85 d2                	test   %edx,%edx
  105726:	89 c8                	mov    %ecx,%eax
  105728:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  10572b:	75 13                	jne    105740 <__umoddi3+0x30>
  10572d:	39 f7                	cmp    %esi,%edi
  10572f:	76 3f                	jbe    105770 <__umoddi3+0x60>
  105731:	89 f2                	mov    %esi,%edx
  105733:	f7 f7                	div    %edi
  105735:	89 d0                	mov    %edx,%eax
  105737:	31 d2                	xor    %edx,%edx
  105739:	83 c4 20             	add    $0x20,%esp
  10573c:	5e                   	pop    %esi
  10573d:	5f                   	pop    %edi
  10573e:	5d                   	pop    %ebp
  10573f:	c3                   	ret    
  105740:	39 f2                	cmp    %esi,%edx
  105742:	77 4c                	ja     105790 <__umoddi3+0x80>
  105744:	0f bd ca             	bsr    %edx,%ecx
  105747:	83 f1 1f             	xor    $0x1f,%ecx
  10574a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  10574d:	75 51                	jne    1057a0 <__umoddi3+0x90>
  10574f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  105752:	0f 87 e0 00 00 00    	ja     105838 <__umoddi3+0x128>
  105758:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10575b:	29 f8                	sub    %edi,%eax
  10575d:	19 d6                	sbb    %edx,%esi
  10575f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105762:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105765:	89 f2                	mov    %esi,%edx
  105767:	83 c4 20             	add    $0x20,%esp
  10576a:	5e                   	pop    %esi
  10576b:	5f                   	pop    %edi
  10576c:	5d                   	pop    %ebp
  10576d:	c3                   	ret    
  10576e:	66 90                	xchg   %ax,%ax
  105770:	85 ff                	test   %edi,%edi
  105772:	75 0b                	jne    10577f <__umoddi3+0x6f>
  105774:	b8 01 00 00 00       	mov    $0x1,%eax
  105779:	31 d2                	xor    %edx,%edx
  10577b:	f7 f7                	div    %edi
  10577d:	89 c7                	mov    %eax,%edi
  10577f:	89 f0                	mov    %esi,%eax
  105781:	31 d2                	xor    %edx,%edx
  105783:	f7 f7                	div    %edi
  105785:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105788:	f7 f7                	div    %edi
  10578a:	eb a9                	jmp    105735 <__umoddi3+0x25>
  10578c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105790:	89 c8                	mov    %ecx,%eax
  105792:	89 f2                	mov    %esi,%edx
  105794:	83 c4 20             	add    $0x20,%esp
  105797:	5e                   	pop    %esi
  105798:	5f                   	pop    %edi
  105799:	5d                   	pop    %ebp
  10579a:	c3                   	ret    
  10579b:	90                   	nop
  10579c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1057a0:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1057a4:	d3 e2                	shl    %cl,%edx
  1057a6:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1057a9:	ba 20 00 00 00       	mov    $0x20,%edx
  1057ae:	2b 55 f0             	sub    -0x10(%ebp),%edx
  1057b1:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1057b4:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1057b8:	89 fa                	mov    %edi,%edx
  1057ba:	d3 ea                	shr    %cl,%edx
  1057bc:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1057c0:	0b 55 f4             	or     -0xc(%ebp),%edx
  1057c3:	d3 e7                	shl    %cl,%edi
  1057c5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1057c9:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1057cc:	89 f2                	mov    %esi,%edx
  1057ce:	89 7d e8             	mov    %edi,-0x18(%ebp)
  1057d1:	89 c7                	mov    %eax,%edi
  1057d3:	d3 ea                	shr    %cl,%edx
  1057d5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1057d9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1057dc:	89 c2                	mov    %eax,%edx
  1057de:	d3 e6                	shl    %cl,%esi
  1057e0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1057e4:	d3 ea                	shr    %cl,%edx
  1057e6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1057ea:	09 d6                	or     %edx,%esi
  1057ec:	89 f0                	mov    %esi,%eax
  1057ee:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  1057f1:	d3 e7                	shl    %cl,%edi
  1057f3:	89 f2                	mov    %esi,%edx
  1057f5:	f7 75 f4             	divl   -0xc(%ebp)
  1057f8:	89 d6                	mov    %edx,%esi
  1057fa:	f7 65 e8             	mull   -0x18(%ebp)
  1057fd:	39 d6                	cmp    %edx,%esi
  1057ff:	72 2b                	jb     10582c <__umoddi3+0x11c>
  105801:	39 c7                	cmp    %eax,%edi
  105803:	72 23                	jb     105828 <__umoddi3+0x118>
  105805:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  105809:	29 c7                	sub    %eax,%edi
  10580b:	19 d6                	sbb    %edx,%esi
  10580d:	89 f0                	mov    %esi,%eax
  10580f:	89 f2                	mov    %esi,%edx
  105811:	d3 ef                	shr    %cl,%edi
  105813:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  105817:	d3 e0                	shl    %cl,%eax
  105819:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10581d:	09 f8                	or     %edi,%eax
  10581f:	d3 ea                	shr    %cl,%edx
  105821:	83 c4 20             	add    $0x20,%esp
  105824:	5e                   	pop    %esi
  105825:	5f                   	pop    %edi
  105826:	5d                   	pop    %ebp
  105827:	c3                   	ret    
  105828:	39 d6                	cmp    %edx,%esi
  10582a:	75 d9                	jne    105805 <__umoddi3+0xf5>
  10582c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  10582f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  105832:	eb d1                	jmp    105805 <__umoddi3+0xf5>
  105834:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105838:	39 f2                	cmp    %esi,%edx
  10583a:	0f 82 18 ff ff ff    	jb     105758 <__umoddi3+0x48>
  105840:	e9 1d ff ff ff       	jmp    105762 <__umoddi3+0x52>
