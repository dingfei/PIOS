
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
  100050:	c7 44 24 0c 20 58 10 	movl   $0x105820,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 4b 58 10 00 	movl   $0x10584b,(%esp)
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
  1000a1:	ba 10 fb 30 00       	mov    $0x30fb10,%edx
  1000a6:	b8 9c 96 10 00       	mov    $0x10969c,%eax
  1000ab:	89 d1                	mov    %edx,%ecx
  1000ad:	29 c1                	sub    %eax,%ecx
  1000af:	89 c8                	mov    %ecx,%eax
  1000b1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bc:	00 
  1000bd:	c7 04 24 9c 96 10 00 	movl   $0x10969c,(%esp)
  1000c4:	e8 d5 52 00 00       	call   10539e <memset>
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
  1000e6:	e8 1a 23 00 00       	call   102405 <spinlock_check>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000eb:	e8 b5 1f 00 00       	call   1020a5 <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000f0:	e8 b1 41 00 00       	call   1042a6 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000f5:	e8 df 47 00 00       	call   1048d9 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000fa:	e8 8a 44 00 00       	call   104589 <lapic_init>
		// Initialize the process management code.
	proc_init();
  1000ff:	e8 4c 29 00 00       	call   102a50 <proc_init>
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
  100112:	bb 58 58 10 00       	mov    $0x105858,%ebx
  100117:	eb 05                	jmp    10011e <init+0x8d>
  100119:	bb 5b 58 10 00       	mov    $0x10585b,%ebx
  10011e:	e8 03 ff ff ff       	call   100026 <cpu_cur>
  100123:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10012a:	0f b6 c0             	movzbl %al,%eax
  10012d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  100131:	89 44 24 04          	mov    %eax,0x4(%esp)
  100135:	c7 04 24 5e 58 10 00 	movl   $0x10585e,(%esp)
  10013c:	e8 78 50 00 00       	call   1051b9 <cprintf>
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
  100152:	c7 04 24 20 f4 30 00 	movl   $0x30f420,(%esp)
  100159:	e8 40 29 00 00       	call   102a9e <proc_alloc>
  10015e:	a3 04 fb 30 00       	mov    %eax,0x30fb04
		proc_root->sv.tf.eip = (uint32_t)(user);
  100163:	a1 04 fb 30 00       	mov    0x30fb04,%eax
  100168:	ba c0 01 10 00       	mov    $0x1001c0,%edx
  10016d:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_root->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
  100173:	a1 04 fb 30 00       	mov    0x30fb04,%eax
  100178:	ba a0 a6 10 00       	mov    $0x10a6a0,%edx
  10017d:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		proc_root->sv.tf.eflags = FL_IF;
  100183:	a1 04 fb 30 00       	mov    0x30fb04,%eax
  100188:	c7 80 90 04 00 00 00 	movl   $0x200,0x490(%eax)
  10018f:	02 00 00 
		proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
  100192:	a1 04 fb 30 00       	mov    0x30fb04,%eax
  100197:	66 c7 80 70 04 00 00 	movw   $0x23,0x470(%eax)
  10019e:	23 00 
		proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;
  1001a0:	a1 04 fb 30 00       	mov    0x30fb04,%eax
  1001a5:	66 c7 80 74 04 00 00 	movw   $0x23,0x474(%eax)
  1001ac:	23 00 

		proc_ready(proc_root);	
  1001ae:	a1 04 fb 30 00       	mov    0x30fb04,%eax
  1001b3:	89 04 24             	mov    %eax,(%esp)
  1001b6:	e8 75 2a 00 00       	call   102c30 <proc_ready>
	}

	
	proc_sched();
  1001bb:	e8 c8 2c 00 00       	call   102e88 <proc_sched>

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
  1001c6:	c7 04 24 76 58 10 00 	movl   $0x105876,(%esp)
  1001cd:	e8 e7 4f 00 00       	call   1051b9 <cprintf>

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
  1001da:	b8 a0 96 10 00       	mov    $0x1096a0,%eax
  1001df:	39 c2                	cmp    %eax,%edx
  1001e1:	77 24                	ja     100207 <user+0x47>
  1001e3:	c7 44 24 0c 84 58 10 	movl   $0x105884,0xc(%esp)
  1001ea:	00 
  1001eb:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  1001f2:	00 
  1001f3:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
  1001fa:	00 
  1001fb:	c7 04 24 ab 58 10 00 	movl   $0x1058ab,(%esp)
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
  10020f:	b8 a0 a6 10 00       	mov    $0x10a6a0,%eax
  100214:	39 c2                	cmp    %eax,%edx
  100216:	72 24                	jb     10023c <user+0x7c>
  100218:	c7 44 24 0c b8 58 10 	movl   $0x1058b8,0xc(%esp)
  10021f:	00 
  100220:	c7 44 24 08 36 58 10 	movl   $0x105836,0x8(%esp)
  100227:	00 
  100228:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  10022f:	00 
  100230:	c7 04 24 ab 58 10 00 	movl   $0x1058ab,(%esp)
  100237:	e8 45 02 00 00       	call   100481 <debug_panic>

	// Check the system call and process scheduling code.
	proc_check();
  10023c:	e8 06 2f 00 00       	call   103147 <proc_check>

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
  100275:	c7 44 24 0c f0 58 10 	movl   $0x1058f0,0xc(%esp)
  10027c:	00 
  10027d:	c7 44 24 08 06 59 10 	movl   $0x105906,0x8(%esp)
  100284:	00 
  100285:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10028c:	00 
  10028d:	c7 04 24 1b 59 10 00 	movl   $0x10591b,(%esp)
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
  1002a9:	3d 00 80 10 00       	cmp    $0x108000,%eax
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
  1002bc:	c7 04 24 60 f3 10 00 	movl   $0x10f360,(%esp)
  1002c3:	e8 09 20 00 00       	call   1022d1 <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  1002c8:	eb 35                	jmp    1002ff <cons_intr+0x49>
		if (c == 0)
  1002ca:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1002ce:	74 2e                	je     1002fe <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  1002d0:	a1 a4 a8 10 00       	mov    0x10a8a4,%eax
  1002d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1002d8:	88 90 a0 a6 10 00    	mov    %dl,0x10a6a0(%eax)
  1002de:	83 c0 01             	add    $0x1,%eax
  1002e1:	a3 a4 a8 10 00       	mov    %eax,0x10a8a4
		if (cons.wpos == CONSBUFSIZE)
  1002e6:	a1 a4 a8 10 00       	mov    0x10a8a4,%eax
  1002eb:	3d 00 02 00 00       	cmp    $0x200,%eax
  1002f0:	75 0d                	jne    1002ff <cons_intr+0x49>
			cons.wpos = 0;
  1002f2:	c7 05 a4 a8 10 00 00 	movl   $0x0,0x10a8a4
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
  10030d:	c7 04 24 60 f3 10 00 	movl   $0x10f360,(%esp)
  100314:	e8 25 20 00 00       	call   10233e <spinlock_release>

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
  100321:	e8 30 3e 00 00       	call   104156 <serial_intr>
	kbd_intr();
  100326:	e8 86 3d 00 00       	call   1040b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  10032b:	8b 15 a0 a8 10 00    	mov    0x10a8a0,%edx
  100331:	a1 a4 a8 10 00       	mov    0x10a8a4,%eax
  100336:	39 c2                	cmp    %eax,%edx
  100338:	74 35                	je     10036f <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  10033a:	a1 a0 a8 10 00       	mov    0x10a8a0,%eax
  10033f:	0f b6 90 a0 a6 10 00 	movzbl 0x10a6a0(%eax),%edx
  100346:	0f b6 d2             	movzbl %dl,%edx
  100349:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10034c:	83 c0 01             	add    $0x1,%eax
  10034f:	a3 a0 a8 10 00       	mov    %eax,0x10a8a0
		if (cons.rpos == CONSBUFSIZE)
  100354:	a1 a0 a8 10 00       	mov    0x10a8a0,%eax
  100359:	3d 00 02 00 00       	cmp    $0x200,%eax
  10035e:	75 0a                	jne    10036a <cons_getc+0x4f>
			cons.rpos = 0;
  100360:	c7 05 a0 a8 10 00 00 	movl   $0x0,0x10a8a0
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
  100382:	e8 ec 3d 00 00       	call   104173 <serial_putc>
	video_putc(c);
  100387:	8b 45 08             	mov    0x8(%ebp),%eax
  10038a:	89 04 24             	mov    %eax,(%esp)
  10038d:	e8 7e 39 00 00       	call   103d10 <video_putc>
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
  1003ab:	c7 44 24 04 28 59 10 	movl   $0x105928,0x4(%esp)
  1003b2:	00 
  1003b3:	c7 04 24 60 f3 10 00 	movl   $0x10f360,(%esp)
  1003ba:	e8 de 1e 00 00       	call   10229d <spinlock_init_>
	video_init();
  1003bf:	e8 80 38 00 00       	call   103c44 <video_init>
	kbd_init();
  1003c4:	e8 fc 3c 00 00       	call   1040c5 <kbd_init>
	serial_init();
  1003c9:	e8 0a 3e 00 00       	call   1041d8 <serial_init>

	if (!serial_exists)
  1003ce:	a1 08 fb 30 00       	mov    0x30fb08,%eax
  1003d3:	85 c0                	test   %eax,%eax
  1003d5:	75 1f                	jne    1003f6 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  1003d7:	c7 44 24 08 34 59 10 	movl   $0x105934,0x8(%esp)
  1003de:	00 
  1003df:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  1003e6:	00 
  1003e7:	c7 04 24 28 59 10 00 	movl   $0x105928,(%esp)
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
  100424:	c7 04 24 60 f3 10 00 	movl   $0x10f360,(%esp)
  10042b:	e8 68 1f 00 00       	call   102398 <spinlock_holding>
  100430:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!already)
  100433:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100437:	75 25                	jne    10045e <cputs+0x66>
		spinlock_acquire(&cons_lock);
  100439:	c7 04 24 60 f3 10 00 	movl   $0x10f360,(%esp)
  100440:	e8 8c 1e 00 00       	call   1022d1 <spinlock_acquire>

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
  10046f:	c7 04 24 60 f3 10 00 	movl   $0x10f360,(%esp)
  100476:	e8 c3 1e 00 00       	call   10233e <spinlock_release>
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
  100498:	a1 a8 a8 10 00       	mov    0x10a8a8,%eax
  10049d:	85 c0                	test   %eax,%eax
  10049f:	0f 85 95 00 00 00    	jne    10053a <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  1004a5:	8b 45 10             	mov    0x10(%ebp),%eax
  1004a8:	a3 a8 a8 10 00       	mov    %eax,0x10a8a8
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
  1004c4:	c7 04 24 51 59 10 00 	movl   $0x105951,(%esp)
  1004cb:	e8 e9 4c 00 00       	call   1051b9 <cprintf>
	vcprintf(fmt, ap);
  1004d0:	8b 45 10             	mov    0x10(%ebp),%eax
  1004d3:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1004d6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1004da:	89 04 24             	mov    %eax,(%esp)
  1004dd:	e8 6e 4c 00 00       	call   105150 <vcprintf>
	cprintf("\n");
  1004e2:	c7 04 24 69 59 10 00 	movl   $0x105969,(%esp)
  1004e9:	e8 cb 4c 00 00       	call   1051b9 <cprintf>

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
  100517:	c7 04 24 6b 59 10 00 	movl   $0x10596b,(%esp)
  10051e:	e8 96 4c 00 00       	call   1051b9 <cprintf>
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
  10055d:	c7 04 24 78 59 10 00 	movl   $0x105978,(%esp)
  100564:	e8 50 4c 00 00       	call   1051b9 <cprintf>
	vcprintf(fmt, ap);
  100569:	8b 45 10             	mov    0x10(%ebp),%eax
  10056c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10056f:	89 54 24 04          	mov    %edx,0x4(%esp)
  100573:	89 04 24             	mov    %eax,(%esp)
  100576:	e8 d5 4b 00 00       	call   105150 <vcprintf>
	cprintf("\n");
  10057b:	c7 04 24 69 59 10 00 	movl   $0x105969,(%esp)
  100582:	e8 32 4c 00 00       	call   1051b9 <cprintf>
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
  100709:	c7 44 24 0c 92 59 10 	movl   $0x105992,0xc(%esp)
  100710:	00 
  100711:	c7 44 24 08 af 59 10 	movl   $0x1059af,0x8(%esp)
  100718:	00 
  100719:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100720:	00 
  100721:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
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
  100759:	c7 44 24 0c d1 59 10 	movl   $0x1059d1,0xc(%esp)
  100760:	00 
  100761:	c7 44 24 08 af 59 10 	movl   $0x1059af,0x8(%esp)
  100768:	00 
  100769:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  100770:	00 
  100771:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
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
  1007a9:	c7 44 24 0c ea 59 10 	movl   $0x1059ea,0xc(%esp)
  1007b0:	00 
  1007b1:	c7 44 24 08 af 59 10 	movl   $0x1059af,0x8(%esp)
  1007b8:	00 
  1007b9:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  1007c0:	00 
  1007c1:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
  1007c8:	e8 b4 fc ff ff       	call   100481 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1007cd:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1007d0:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1007d3:	39 c2                	cmp    %eax,%edx
  1007d5:	74 24                	je     1007fb <debug_check+0x175>
  1007d7:	c7 44 24 0c 03 5a 10 	movl   $0x105a03,0xc(%esp)
  1007de:	00 
  1007df:	c7 44 24 08 af 59 10 	movl   $0x1059af,0x8(%esp)
  1007e6:	00 
  1007e7:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  1007ee:	00 
  1007ef:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
  1007f6:	e8 86 fc ff ff       	call   100481 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  1007fb:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100801:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100804:	39 c2                	cmp    %eax,%edx
  100806:	75 24                	jne    10082c <debug_check+0x1a6>
  100808:	c7 44 24 0c 1c 5a 10 	movl   $0x105a1c,0xc(%esp)
  10080f:	00 
  100810:	c7 44 24 08 af 59 10 	movl   $0x1059af,0x8(%esp)
  100817:	00 
  100818:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  10081f:	00 
  100820:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
  100827:	e8 55 fc ff ff       	call   100481 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10082c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100832:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100835:	39 c2                	cmp    %eax,%edx
  100837:	74 24                	je     10085d <debug_check+0x1d7>
  100839:	c7 44 24 0c 35 5a 10 	movl   $0x105a35,0xc(%esp)
  100840:	00 
  100841:	c7 44 24 08 af 59 10 	movl   $0x1059af,0x8(%esp)
  100848:	00 
  100849:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100850:	00 
  100851:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
  100858:	e8 24 fc ff ff       	call   100481 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10085d:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100863:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100866:	39 c2                	cmp    %eax,%edx
  100868:	74 24                	je     10088e <debug_check+0x208>
  10086a:	c7 44 24 0c 4e 5a 10 	movl   $0x105a4e,0xc(%esp)
  100871:	00 
  100872:	c7 44 24 08 af 59 10 	movl   $0x1059af,0x8(%esp)
  100879:	00 
  10087a:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100881:	00 
  100882:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
  100889:	e8 f3 fb ff ff       	call   100481 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10088e:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100894:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  10089a:	39 c2                	cmp    %eax,%edx
  10089c:	75 24                	jne    1008c2 <debug_check+0x23c>
  10089e:	c7 44 24 0c 67 5a 10 	movl   $0x105a67,0xc(%esp)
  1008a5:	00 
  1008a6:	c7 44 24 08 af 59 10 	movl   $0x1059af,0x8(%esp)
  1008ad:	00 
  1008ae:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  1008b5:	00 
  1008b6:	c7 04 24 c4 59 10 00 	movl   $0x1059c4,(%esp)
  1008bd:	e8 bf fb ff ff       	call   100481 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1008c2:	c7 04 24 80 5a 10 00 	movl   $0x105a80,(%esp)
  1008c9:	e8 eb 48 00 00       	call   1051b9 <cprintf>
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
  1008fa:	c7 44 24 0c 9c 5a 10 	movl   $0x105a9c,0xc(%esp)
  100901:	00 
  100902:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100909:	00 
  10090a:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100911:	00 
  100912:	c7 04 24 c7 5a 10 00 	movl   $0x105ac7,(%esp)
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
  10092e:	3d 00 80 10 00       	cmp    $0x108000,%eax
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
  100956:	c7 44 24 04 d4 5a 10 	movl   $0x105ad4,0x4(%esp)
  10095d:	00 
  10095e:	c7 04 24 c0 f3 30 00 	movl   $0x30f3c0,(%esp)
  100965:	e8 33 19 00 00       	call   10229d <spinlock_init_>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  10096a:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100971:	e8 39 3b 00 00       	call   1044af <nvram_read16>
  100976:	c1 e0 0a             	shl    $0xa,%eax
  100979:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10097c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10097f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100984:	89 45 dc             	mov    %eax,-0x24(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100987:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  10098e:	e8 1c 3b 00 00       	call   1044af <nvram_read16>
  100993:	c1 e0 0a             	shl    $0xa,%eax
  100996:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100999:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10099c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1009a1:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  1009a4:	c7 44 24 08 e0 5a 10 	movl   $0x105ae0,0x8(%esp)
  1009ab:	00 
  1009ac:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
  1009b3:	00 
  1009b4:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  1009bb:	e8 80 fb ff ff       	call   100540 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1009c0:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1009c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1009ca:	05 00 00 10 00       	add    $0x100000,%eax
  1009cf:	a3 a8 f3 10 00       	mov    %eax,0x10f3a8

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1009d4:	a1 a8 f3 10 00       	mov    0x10f3a8,%eax
  1009d9:	c1 e8 0c             	shr    $0xc,%eax
  1009dc:	a3 a4 f3 10 00       	mov    %eax,0x10f3a4

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  1009e1:	a1 a8 f3 10 00       	mov    0x10f3a8,%eax
  1009e6:	c1 e8 0a             	shr    $0xa,%eax
  1009e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009ed:	c7 04 24 00 5b 10 00 	movl   $0x105b00,(%esp)
  1009f4:	e8 c0 47 00 00       	call   1051b9 <cprintf>
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
  100a0f:	c7 04 24 21 5b 10 00 	movl   $0x105b21,(%esp)
  100a16:	e8 9e 47 00 00       	call   1051b9 <cprintf>


	extern char start[], end[];
	uint32_t page_start;
	
	pageinfo **freetail = &mem_freelist;
  100a1b:	c7 45 e8 a0 f3 10 00 	movl   $0x10f3a0,-0x18(%ebp)
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100a22:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100a29:	00 
  100a2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100a31:	00 
  100a32:	c7 04 24 c0 f3 10 00 	movl   $0x10f3c0,(%esp)
  100a39:	e8 60 49 00 00       	call   10539e <memset>
	mem_pageinfo = spc_for_pi;
  100a3e:	c7 05 f8 f3 30 00 c0 	movl   $0x10f3c0,0x30f3f8
  100a45:	f3 10 00 
	int i;
	for (i = 0; i < mem_npage; i++) {
  100a48:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100a4f:	e9 96 00 00 00       	jmp    100aea <mem_init+0x1af>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100a54:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
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
  100aad:	b8 10 fb 30 00       	mov    $0x30fb10,%eax
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
  100ab7:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
  100abc:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100abf:	c1 e2 03             	shl    $0x3,%edx
  100ac2:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100ac5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ac8:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100aca:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
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
  100aed:	a1 a4 f3 10 00       	mov    0x10f3a4,%eax
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
  100b13:	a1 a0 f3 10 00       	mov    0x10f3a0,%eax
  100b18:	85 c0                	test   %eax,%eax
  100b1a:	75 07                	jne    100b23 <mem_alloc+0x16>
		return NULL;
  100b1c:	b8 00 00 00 00       	mov    $0x0,%eax
  100b21:	eb 2f                	jmp    100b52 <mem_alloc+0x45>

	spinlock_acquire(&mem_spinlock);
  100b23:	c7 04 24 c0 f3 30 00 	movl   $0x30f3c0,(%esp)
  100b2a:	e8 a2 17 00 00       	call   1022d1 <spinlock_acquire>
	pageinfo* r = mem_freelist;
  100b2f:	a1 a0 f3 10 00       	mov    0x10f3a0,%eax
  100b34:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = mem_freelist->free_next;
  100b37:	a1 a0 f3 10 00       	mov    0x10f3a0,%eax
  100b3c:	8b 00                	mov    (%eax),%eax
  100b3e:	a3 a0 f3 10 00       	mov    %eax,0x10f3a0
	spinlock_release(&mem_spinlock);
  100b43:	c7 04 24 c0 f3 30 00 	movl   $0x30f3c0,(%esp)
  100b4a:	e8 ef 17 00 00       	call   10233e <spinlock_release>
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
  100b60:	c7 44 24 08 40 5b 10 	movl   $0x105b40,0x8(%esp)
  100b67:	00 
  100b68:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  100b6f:	00 
  100b70:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100b77:	e8 05 f9 ff ff       	call   100481 <debug_panic>

	spinlock_acquire(&mem_spinlock);
  100b7c:	c7 04 24 c0 f3 30 00 	movl   $0x30f3c0,(%esp)
  100b83:	e8 49 17 00 00       	call   1022d1 <spinlock_acquire>
	pi->free_next = mem_freelist;
  100b88:	8b 15 a0 f3 10 00    	mov    0x10f3a0,%edx
  100b8e:	8b 45 08             	mov    0x8(%ebp),%eax
  100b91:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100b93:	8b 45 08             	mov    0x8(%ebp),%eax
  100b96:	a3 a0 f3 10 00       	mov    %eax,0x10f3a0
	spinlock_release(&mem_spinlock);
  100b9b:	c7 04 24 c0 f3 30 00 	movl   $0x30f3c0,(%esp)
  100ba2:	e8 97 17 00 00       	call   10233e <spinlock_release>
	
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
  100bb6:	a1 a0 f3 10 00       	mov    0x10f3a0,%eax
  100bbb:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100bbe:	eb 38                	jmp    100bf8 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100bc0:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100bc3:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
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
  100be7:	e8 b2 47 00 00       	call   10539e <memset>
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
  100c05:	c7 04 24 61 5b 10 00 	movl   $0x105b61,(%esp)
  100c0c:	e8 a8 45 00 00       	call   1051b9 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100c11:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c14:	a1 a4 f3 10 00       	mov    0x10f3a4,%eax
  100c19:	39 c2                	cmp    %eax,%edx
  100c1b:	72 24                	jb     100c41 <mem_check+0x98>
  100c1d:	c7 44 24 0c 7b 5b 10 	movl   $0x105b7b,0xc(%esp)
  100c24:	00 
  100c25:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100c2c:	00 
  100c2d:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  100c34:	00 
  100c35:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100c3c:	e8 40 f8 ff ff       	call   100481 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100c41:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100c48:	7f 24                	jg     100c6e <mem_check+0xc5>
  100c4a:	c7 44 24 0c 91 5b 10 	movl   $0x105b91,0xc(%esp)
  100c51:	00 
  100c52:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100c59:	00 
  100c5a:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100c61:	00 
  100c62:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
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
  100c8f:	c7 44 24 0c a3 5b 10 	movl   $0x105ba3,0xc(%esp)
  100c96:	00 
  100c97:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100c9e:	00 
  100c9f:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  100ca6:	00 
  100ca7:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100cae:	e8 ce f7 ff ff       	call   100481 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100cb3:	e8 55 fe ff ff       	call   100b0d <mem_alloc>
  100cb8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100cbb:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100cbf:	75 24                	jne    100ce5 <mem_check+0x13c>
  100cc1:	c7 44 24 0c ac 5b 10 	movl   $0x105bac,0xc(%esp)
  100cc8:	00 
  100cc9:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100cd0:	00 
  100cd1:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100cd8:	00 
  100cd9:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100ce0:	e8 9c f7 ff ff       	call   100481 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100ce5:	e8 23 fe ff ff       	call   100b0d <mem_alloc>
  100cea:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100ced:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100cf1:	75 24                	jne    100d17 <mem_check+0x16e>
  100cf3:	c7 44 24 0c b5 5b 10 	movl   $0x105bb5,0xc(%esp)
  100cfa:	00 
  100cfb:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100d02:	00 
  100d03:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100d0a:	00 
  100d0b:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100d12:	e8 6a f7 ff ff       	call   100481 <debug_panic>

	assert(pp0);
  100d17:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100d1b:	75 24                	jne    100d41 <mem_check+0x198>
  100d1d:	c7 44 24 0c be 5b 10 	movl   $0x105bbe,0xc(%esp)
  100d24:	00 
  100d25:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100d2c:	00 
  100d2d:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  100d34:	00 
  100d35:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100d3c:	e8 40 f7 ff ff       	call   100481 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100d41:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d45:	74 08                	je     100d4f <mem_check+0x1a6>
  100d47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d4a:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d4d:	75 24                	jne    100d73 <mem_check+0x1ca>
  100d4f:	c7 44 24 0c c2 5b 10 	movl   $0x105bc2,0xc(%esp)
  100d56:	00 
  100d57:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100d5e:	00 
  100d5f:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100d66:	00 
  100d67:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
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
  100d89:	c7 44 24 0c d4 5b 10 	movl   $0x105bd4,0xc(%esp)
  100d90:	00 
  100d91:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100d98:	00 
  100d99:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100da0:	00 
  100da1:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100da8:	e8 d4 f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100dad:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100db0:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
  100db5:	89 d1                	mov    %edx,%ecx
  100db7:	29 c1                	sub    %eax,%ecx
  100db9:	89 c8                	mov    %ecx,%eax
  100dbb:	c1 f8 03             	sar    $0x3,%eax
  100dbe:	c1 e0 0c             	shl    $0xc,%eax
  100dc1:	8b 15 a4 f3 10 00    	mov    0x10f3a4,%edx
  100dc7:	c1 e2 0c             	shl    $0xc,%edx
  100dca:	39 d0                	cmp    %edx,%eax
  100dcc:	72 24                	jb     100df2 <mem_check+0x249>
  100dce:	c7 44 24 0c f4 5b 10 	movl   $0x105bf4,0xc(%esp)
  100dd5:	00 
  100dd6:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100ddd:	00 
  100dde:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  100de5:	00 
  100de6:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100ded:	e8 8f f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100df2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100df5:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
  100dfa:	89 d1                	mov    %edx,%ecx
  100dfc:	29 c1                	sub    %eax,%ecx
  100dfe:	89 c8                	mov    %ecx,%eax
  100e00:	c1 f8 03             	sar    $0x3,%eax
  100e03:	c1 e0 0c             	shl    $0xc,%eax
  100e06:	8b 15 a4 f3 10 00    	mov    0x10f3a4,%edx
  100e0c:	c1 e2 0c             	shl    $0xc,%edx
  100e0f:	39 d0                	cmp    %edx,%eax
  100e11:	72 24                	jb     100e37 <mem_check+0x28e>
  100e13:	c7 44 24 0c 1c 5c 10 	movl   $0x105c1c,0xc(%esp)
  100e1a:	00 
  100e1b:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100e22:	00 
  100e23:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  100e2a:	00 
  100e2b:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100e32:	e8 4a f6 ff ff       	call   100481 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100e37:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100e3a:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
  100e3f:	89 d1                	mov    %edx,%ecx
  100e41:	29 c1                	sub    %eax,%ecx
  100e43:	89 c8                	mov    %ecx,%eax
  100e45:	c1 f8 03             	sar    $0x3,%eax
  100e48:	c1 e0 0c             	shl    $0xc,%eax
  100e4b:	8b 15 a4 f3 10 00    	mov    0x10f3a4,%edx
  100e51:	c1 e2 0c             	shl    $0xc,%edx
  100e54:	39 d0                	cmp    %edx,%eax
  100e56:	72 24                	jb     100e7c <mem_check+0x2d3>
  100e58:	c7 44 24 0c 44 5c 10 	movl   $0x105c44,0xc(%esp)
  100e5f:	00 
  100e60:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100e67:	00 
  100e68:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  100e6f:	00 
  100e70:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100e77:	e8 05 f6 ff ff       	call   100481 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100e7c:	a1 a0 f3 10 00       	mov    0x10f3a0,%eax
  100e81:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100e84:	c7 05 a0 f3 10 00 00 	movl   $0x0,0x10f3a0
  100e8b:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100e8e:	e8 7a fc ff ff       	call   100b0d <mem_alloc>
  100e93:	85 c0                	test   %eax,%eax
  100e95:	74 24                	je     100ebb <mem_check+0x312>
  100e97:	c7 44 24 0c 6a 5c 10 	movl   $0x105c6a,0xc(%esp)
  100e9e:	00 
  100e9f:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100ea6:	00 
  100ea7:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  100eae:	00 
  100eaf:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
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
  100efd:	c7 44 24 0c a3 5b 10 	movl   $0x105ba3,0xc(%esp)
  100f04:	00 
  100f05:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100f0c:	00 
  100f0d:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  100f14:	00 
  100f15:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100f1c:	e8 60 f5 ff ff       	call   100481 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100f21:	e8 e7 fb ff ff       	call   100b0d <mem_alloc>
  100f26:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100f29:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100f2d:	75 24                	jne    100f53 <mem_check+0x3aa>
  100f2f:	c7 44 24 0c ac 5b 10 	movl   $0x105bac,0xc(%esp)
  100f36:	00 
  100f37:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100f3e:	00 
  100f3f:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  100f46:	00 
  100f47:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100f4e:	e8 2e f5 ff ff       	call   100481 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100f53:	e8 b5 fb ff ff       	call   100b0d <mem_alloc>
  100f58:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100f5b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f5f:	75 24                	jne    100f85 <mem_check+0x3dc>
  100f61:	c7 44 24 0c b5 5b 10 	movl   $0x105bb5,0xc(%esp)
  100f68:	00 
  100f69:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100f70:	00 
  100f71:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  100f78:	00 
  100f79:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100f80:	e8 fc f4 ff ff       	call   100481 <debug_panic>
	assert(pp0);
  100f85:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100f89:	75 24                	jne    100faf <mem_check+0x406>
  100f8b:	c7 44 24 0c be 5b 10 	movl   $0x105bbe,0xc(%esp)
  100f92:	00 
  100f93:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100f9a:	00 
  100f9b:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  100fa2:	00 
  100fa3:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  100faa:	e8 d2 f4 ff ff       	call   100481 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100faf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100fb3:	74 08                	je     100fbd <mem_check+0x414>
  100fb5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100fb8:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100fbb:	75 24                	jne    100fe1 <mem_check+0x438>
  100fbd:	c7 44 24 0c c2 5b 10 	movl   $0x105bc2,0xc(%esp)
  100fc4:	00 
  100fc5:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  100fcc:	00 
  100fcd:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  100fd4:	00 
  100fd5:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
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
  100ff7:	c7 44 24 0c d4 5b 10 	movl   $0x105bd4,0xc(%esp)
  100ffe:	00 
  100fff:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  101006:	00 
  101007:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  10100e:	00 
  10100f:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  101016:	e8 66 f4 ff ff       	call   100481 <debug_panic>
	assert(mem_alloc() == 0);
  10101b:	e8 ed fa ff ff       	call   100b0d <mem_alloc>
  101020:	85 c0                	test   %eax,%eax
  101022:	74 24                	je     101048 <mem_check+0x49f>
  101024:	c7 44 24 0c 6a 5c 10 	movl   $0x105c6a,0xc(%esp)
  10102b:	00 
  10102c:	c7 44 24 08 b2 5a 10 	movl   $0x105ab2,0x8(%esp)
  101033:	00 
  101034:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  10103b:	00 
  10103c:	c7 04 24 d4 5a 10 00 	movl   $0x105ad4,(%esp)
  101043:	e8 39 f4 ff ff       	call   100481 <debug_panic>

	// give free list back
	mem_freelist = fl;
  101048:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10104b:	a3 a0 f3 10 00       	mov    %eax,0x10f3a0

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
  101071:	c7 04 24 7b 5c 10 00 	movl   $0x105c7b,(%esp)
  101078:	e8 3c 41 00 00       	call   1051b9 <cprintf>
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
  1010c3:	c7 44 24 0c 93 5c 10 	movl   $0x105c93,0xc(%esp)
  1010ca:	00 
  1010cb:	c7 44 24 08 a9 5c 10 	movl   $0x105ca9,0x8(%esp)
  1010d2:	00 
  1010d3:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1010da:	00 
  1010db:	c7 04 24 be 5c 10 00 	movl   $0x105cbe,(%esp)
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
  1010f7:	3d 00 80 10 00       	cmp    $0x108000,%eax
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
  101239:	c7 44 24 0c cb 5c 10 	movl   $0x105ccb,0xc(%esp)
  101240:	00 
  101241:	c7 44 24 08 a9 5c 10 	movl   $0x105ca9,0x8(%esp)
  101248:	00 
  101249:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  101250:	00 
  101251:	c7 04 24 d3 5c 10 00 	movl   $0x105cd3,(%esp)
  101258:	e8 24 f2 ff ff       	call   100481 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  10125d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101260:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
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
  10128a:	e8 0f 41 00 00       	call   10539e <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  10128f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101292:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101299:	00 
  10129a:	c7 44 24 04 00 80 10 	movl   $0x108000,0x4(%esp)
  1012a1:	00 
  1012a2:	89 04 24             	mov    %eax,(%esp)
  1012a5:	e8 68 41 00 00       	call   105412 <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  1012aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012ad:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  1012b4:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  1012b7:	a1 00 90 10 00       	mov    0x109000,%eax
  1012bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1012bf:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  1012c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1012c4:	05 a8 00 00 00       	add    $0xa8,%eax
  1012c9:	a3 00 90 10 00       	mov    %eax,0x109000

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
  101311:	c7 44 24 04 32 96 10 	movl   $0x109632,0x4(%esp)
  101318:	00 
  101319:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10131c:	89 04 24             	mov    %eax,(%esp)
  10131f:	e8 ee 40 00 00       	call   105412 <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  101324:	c7 45 f4 00 80 10 00 	movl   $0x108000,-0xc(%ebp)
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
  10136b:	e8 40 34 00 00       	call   1047b0 <lapic_startcpu>

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
  1013be:	c7 44 24 0c e0 5c 10 	movl   $0x105ce0,0xc(%esp)
  1013c5:	00 
  1013c6:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  1013cd:	00 
  1013ce:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1013d5:	00 
  1013d6:	c7 04 24 0b 5d 10 00 	movl   $0x105d0b,(%esp)
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
  1013f2:	3d 00 80 10 00       	cmp    $0x108000,%eax
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
  101417:	8b 14 95 10 90 10 00 	mov    0x109010(,%edx,4),%edx
  10141e:	66 89 14 c5 c0 a8 10 	mov    %dx,0x10a8c0(,%eax,8)
  101425:	00 
  101426:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101429:	66 c7 04 c5 c2 a8 10 	movw   $0x8,0x10a8c2(,%eax,8)
  101430:	00 08 00 
  101433:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101436:	0f b6 14 c5 c4 a8 10 	movzbl 0x10a8c4(,%eax,8),%edx
  10143d:	00 
  10143e:	83 e2 e0             	and    $0xffffffe0,%edx
  101441:	88 14 c5 c4 a8 10 00 	mov    %dl,0x10a8c4(,%eax,8)
  101448:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10144b:	0f b6 14 c5 c4 a8 10 	movzbl 0x10a8c4(,%eax,8),%edx
  101452:	00 
  101453:	83 e2 1f             	and    $0x1f,%edx
  101456:	88 14 c5 c4 a8 10 00 	mov    %dl,0x10a8c4(,%eax,8)
  10145d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101460:	0f b6 14 c5 c5 a8 10 	movzbl 0x10a8c5(,%eax,8),%edx
  101467:	00 
  101468:	83 ca 0f             	or     $0xf,%edx
  10146b:	88 14 c5 c5 a8 10 00 	mov    %dl,0x10a8c5(,%eax,8)
  101472:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101475:	0f b6 14 c5 c5 a8 10 	movzbl 0x10a8c5(,%eax,8),%edx
  10147c:	00 
  10147d:	83 e2 ef             	and    $0xffffffef,%edx
  101480:	88 14 c5 c5 a8 10 00 	mov    %dl,0x10a8c5(,%eax,8)
  101487:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10148a:	0f b6 14 c5 c5 a8 10 	movzbl 0x10a8c5(,%eax,8),%edx
  101491:	00 
  101492:	83 ca 60             	or     $0x60,%edx
  101495:	88 14 c5 c5 a8 10 00 	mov    %dl,0x10a8c5(,%eax,8)
  10149c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10149f:	0f b6 14 c5 c5 a8 10 	movzbl 0x10a8c5(,%eax,8),%edx
  1014a6:	00 
  1014a7:	83 ca 80             	or     $0xffffff80,%edx
  1014aa:	88 14 c5 c5 a8 10 00 	mov    %dl,0x10a8c5(,%eax,8)
  1014b1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1014b4:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1014b7:	8b 14 95 10 90 10 00 	mov    0x109010(,%edx,4),%edx
  1014be:	c1 ea 10             	shr    $0x10,%edx
  1014c1:	66 89 14 c5 c6 a8 10 	mov    %dx,0x10a8c6(,%eax,8)
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
  1014d7:	a1 88 90 10 00       	mov    0x109088,%eax
  1014dc:	66 a3 b0 a9 10 00    	mov    %ax,0x10a9b0
  1014e2:	66 c7 05 b2 a9 10 00 	movw   $0x8,0x10a9b2
  1014e9:	08 00 
  1014eb:	0f b6 05 b4 a9 10 00 	movzbl 0x10a9b4,%eax
  1014f2:	83 e0 e0             	and    $0xffffffe0,%eax
  1014f5:	a2 b4 a9 10 00       	mov    %al,0x10a9b4
  1014fa:	0f b6 05 b4 a9 10 00 	movzbl 0x10a9b4,%eax
  101501:	83 e0 1f             	and    $0x1f,%eax
  101504:	a2 b4 a9 10 00       	mov    %al,0x10a9b4
  101509:	0f b6 05 b5 a9 10 00 	movzbl 0x10a9b5,%eax
  101510:	83 c8 0f             	or     $0xf,%eax
  101513:	a2 b5 a9 10 00       	mov    %al,0x10a9b5
  101518:	0f b6 05 b5 a9 10 00 	movzbl 0x10a9b5,%eax
  10151f:	83 e0 ef             	and    $0xffffffef,%eax
  101522:	a2 b5 a9 10 00       	mov    %al,0x10a9b5
  101527:	0f b6 05 b5 a9 10 00 	movzbl 0x10a9b5,%eax
  10152e:	83 c8 60             	or     $0x60,%eax
  101531:	a2 b5 a9 10 00       	mov    %al,0x10a9b5
  101536:	0f b6 05 b5 a9 10 00 	movzbl 0x10a9b5,%eax
  10153d:	83 c8 80             	or     $0xffffff80,%eax
  101540:	a2 b5 a9 10 00       	mov    %al,0x10a9b5
  101545:	a1 88 90 10 00       	mov    0x109088,%eax
  10154a:	c1 e8 10             	shr    $0x10,%eax
  10154d:	66 a3 b6 a9 10 00    	mov    %ax,0x10a9b6
	SETGATE(idt[T_SYSCALL], 1, CPU_GDT_KCODE, vectors[T_SYSCALL], 3);
  101553:	a1 d0 90 10 00       	mov    0x1090d0,%eax
  101558:	66 a3 40 aa 10 00    	mov    %ax,0x10aa40
  10155e:	66 c7 05 42 aa 10 00 	movw   $0x8,0x10aa42
  101565:	08 00 
  101567:	0f b6 05 44 aa 10 00 	movzbl 0x10aa44,%eax
  10156e:	83 e0 e0             	and    $0xffffffe0,%eax
  101571:	a2 44 aa 10 00       	mov    %al,0x10aa44
  101576:	0f b6 05 44 aa 10 00 	movzbl 0x10aa44,%eax
  10157d:	83 e0 1f             	and    $0x1f,%eax
  101580:	a2 44 aa 10 00       	mov    %al,0x10aa44
  101585:	0f b6 05 45 aa 10 00 	movzbl 0x10aa45,%eax
  10158c:	83 c8 0f             	or     $0xf,%eax
  10158f:	a2 45 aa 10 00       	mov    %al,0x10aa45
  101594:	0f b6 05 45 aa 10 00 	movzbl 0x10aa45,%eax
  10159b:	83 e0 ef             	and    $0xffffffef,%eax
  10159e:	a2 45 aa 10 00       	mov    %al,0x10aa45
  1015a3:	0f b6 05 45 aa 10 00 	movzbl 0x10aa45,%eax
  1015aa:	83 c8 60             	or     $0x60,%eax
  1015ad:	a2 45 aa 10 00       	mov    %al,0x10aa45
  1015b2:	0f b6 05 45 aa 10 00 	movzbl 0x10aa45,%eax
  1015b9:	83 c8 80             	or     $0xffffff80,%eax
  1015bc:	a2 45 aa 10 00       	mov    %al,0x10aa45
  1015c1:	a1 d0 90 10 00       	mov    0x1090d0,%eax
  1015c6:	c1 e8 10             	shr    $0x10,%eax
  1015c9:	66 a3 46 aa 10 00    	mov    %ax,0x10aa46
	SETGATE(idt[T_LTIMER], 1, CPU_GDT_KCODE, vectors[T_LTIMER], 3);
  1015cf:	a1 d4 90 10 00       	mov    0x1090d4,%eax
  1015d4:	66 a3 48 aa 10 00    	mov    %ax,0x10aa48
  1015da:	66 c7 05 4a aa 10 00 	movw   $0x8,0x10aa4a
  1015e1:	08 00 
  1015e3:	0f b6 05 4c aa 10 00 	movzbl 0x10aa4c,%eax
  1015ea:	83 e0 e0             	and    $0xffffffe0,%eax
  1015ed:	a2 4c aa 10 00       	mov    %al,0x10aa4c
  1015f2:	0f b6 05 4c aa 10 00 	movzbl 0x10aa4c,%eax
  1015f9:	83 e0 1f             	and    $0x1f,%eax
  1015fc:	a2 4c aa 10 00       	mov    %al,0x10aa4c
  101601:	0f b6 05 4d aa 10 00 	movzbl 0x10aa4d,%eax
  101608:	83 c8 0f             	or     $0xf,%eax
  10160b:	a2 4d aa 10 00       	mov    %al,0x10aa4d
  101610:	0f b6 05 4d aa 10 00 	movzbl 0x10aa4d,%eax
  101617:	83 e0 ef             	and    $0xffffffef,%eax
  10161a:	a2 4d aa 10 00       	mov    %al,0x10aa4d
  10161f:	0f b6 05 4d aa 10 00 	movzbl 0x10aa4d,%eax
  101626:	83 c8 60             	or     $0x60,%eax
  101629:	a2 4d aa 10 00       	mov    %al,0x10aa4d
  10162e:	0f b6 05 4d aa 10 00 	movzbl 0x10aa4d,%eax
  101635:	83 c8 80             	or     $0xffffff80,%eax
  101638:	a2 4d aa 10 00       	mov    %al,0x10aa4d
  10163d:	a1 d4 90 10 00       	mov    0x1090d4,%eax
  101642:	c1 e8 10             	shr    $0x10,%eax
  101645:	66 a3 4e aa 10 00    	mov    %ax,0x10aa4e
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
  101661:	0f 01 1d 04 90 10 00 	lidtl  0x109004

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
  101686:	8b 04 85 e0 60 10 00 	mov    0x1060e0(,%eax,4),%eax
  10168d:	eb 25                	jmp    1016b4 <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  10168f:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  101693:	75 07                	jne    10169c <trap_name+0x24>
		return "System call";
  101695:	b8 18 5d 10 00       	mov    $0x105d18,%eax
  10169a:	eb 18                	jmp    1016b4 <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  10169c:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  1016a0:	7e 0d                	jle    1016af <trap_name+0x37>
  1016a2:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  1016a6:	7f 07                	jg     1016af <trap_name+0x37>
		return "Hardware Interrupt";
  1016a8:	b8 24 5d 10 00       	mov    $0x105d24,%eax
  1016ad:	eb 05                	jmp    1016b4 <trap_name+0x3c>
	return "(unknown trap)";
  1016af:	b8 37 5d 10 00       	mov    $0x105d37,%eax
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
  1016c5:	c7 04 24 46 5d 10 00 	movl   $0x105d46,(%esp)
  1016cc:	e8 e8 3a 00 00       	call   1051b9 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  1016d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1016d4:	8b 40 04             	mov    0x4(%eax),%eax
  1016d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016db:	c7 04 24 55 5d 10 00 	movl   $0x105d55,(%esp)
  1016e2:	e8 d2 3a 00 00       	call   1051b9 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  1016e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1016ea:	8b 40 08             	mov    0x8(%eax),%eax
  1016ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  1016f1:	c7 04 24 64 5d 10 00 	movl   $0x105d64,(%esp)
  1016f8:	e8 bc 3a 00 00       	call   1051b9 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  1016fd:	8b 45 08             	mov    0x8(%ebp),%eax
  101700:	8b 40 10             	mov    0x10(%eax),%eax
  101703:	89 44 24 04          	mov    %eax,0x4(%esp)
  101707:	c7 04 24 73 5d 10 00 	movl   $0x105d73,(%esp)
  10170e:	e8 a6 3a 00 00       	call   1051b9 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101713:	8b 45 08             	mov    0x8(%ebp),%eax
  101716:	8b 40 14             	mov    0x14(%eax),%eax
  101719:	89 44 24 04          	mov    %eax,0x4(%esp)
  10171d:	c7 04 24 82 5d 10 00 	movl   $0x105d82,(%esp)
  101724:	e8 90 3a 00 00       	call   1051b9 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101729:	8b 45 08             	mov    0x8(%ebp),%eax
  10172c:	8b 40 18             	mov    0x18(%eax),%eax
  10172f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101733:	c7 04 24 91 5d 10 00 	movl   $0x105d91,(%esp)
  10173a:	e8 7a 3a 00 00       	call   1051b9 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  10173f:	8b 45 08             	mov    0x8(%ebp),%eax
  101742:	8b 40 1c             	mov    0x1c(%eax),%eax
  101745:	89 44 24 04          	mov    %eax,0x4(%esp)
  101749:	c7 04 24 a0 5d 10 00 	movl   $0x105da0,(%esp)
  101750:	e8 64 3a 00 00       	call   1051b9 <cprintf>
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
  101764:	c7 04 24 af 5d 10 00 	movl   $0x105daf,(%esp)
  10176b:	e8 49 3a 00 00       	call   1051b9 <cprintf>
	trap_print_regs(&tf->regs);
  101770:	8b 45 08             	mov    0x8(%ebp),%eax
  101773:	89 04 24             	mov    %eax,(%esp)
  101776:	e8 3b ff ff ff       	call   1016b6 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  10177b:	8b 45 08             	mov    0x8(%ebp),%eax
  10177e:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101782:	0f b7 c0             	movzwl %ax,%eax
  101785:	89 44 24 04          	mov    %eax,0x4(%esp)
  101789:	c7 04 24 c1 5d 10 00 	movl   $0x105dc1,(%esp)
  101790:	e8 24 3a 00 00       	call   1051b9 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101795:	8b 45 08             	mov    0x8(%ebp),%eax
  101798:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10179c:	0f b7 c0             	movzwl %ax,%eax
  10179f:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017a3:	c7 04 24 d4 5d 10 00 	movl   $0x105dd4,(%esp)
  1017aa:	e8 0a 3a 00 00       	call   1051b9 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  1017af:	8b 45 08             	mov    0x8(%ebp),%eax
  1017b2:	8b 40 30             	mov    0x30(%eax),%eax
  1017b5:	89 04 24             	mov    %eax,(%esp)
  1017b8:	e8 bb fe ff ff       	call   101678 <trap_name>
  1017bd:	8b 55 08             	mov    0x8(%ebp),%edx
  1017c0:	8b 52 30             	mov    0x30(%edx),%edx
  1017c3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1017c7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1017cb:	c7 04 24 e7 5d 10 00 	movl   $0x105de7,(%esp)
  1017d2:	e8 e2 39 00 00       	call   1051b9 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  1017d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1017da:	8b 40 34             	mov    0x34(%eax),%eax
  1017dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017e1:	c7 04 24 f9 5d 10 00 	movl   $0x105df9,(%esp)
  1017e8:	e8 cc 39 00 00       	call   1051b9 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1017ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1017f0:	8b 40 38             	mov    0x38(%eax),%eax
  1017f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017f7:	c7 04 24 08 5e 10 00 	movl   $0x105e08,(%esp)
  1017fe:	e8 b6 39 00 00       	call   1051b9 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101803:	8b 45 08             	mov    0x8(%ebp),%eax
  101806:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10180a:	0f b7 c0             	movzwl %ax,%eax
  10180d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101811:	c7 04 24 17 5e 10 00 	movl   $0x105e17,(%esp)
  101818:	e8 9c 39 00 00       	call   1051b9 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  10181d:	8b 45 08             	mov    0x8(%ebp),%eax
  101820:	8b 40 40             	mov    0x40(%eax),%eax
  101823:	89 44 24 04          	mov    %eax,0x4(%esp)
  101827:	c7 04 24 2a 5e 10 00 	movl   $0x105e2a,(%esp)
  10182e:	e8 86 39 00 00       	call   1051b9 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  101833:	8b 45 08             	mov    0x8(%ebp),%eax
  101836:	8b 40 44             	mov    0x44(%eax),%eax
  101839:	89 44 24 04          	mov    %eax,0x4(%esp)
  10183d:	c7 04 24 39 5e 10 00 	movl   $0x105e39,(%esp)
  101844:	e8 70 39 00 00       	call   1051b9 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  101849:	8b 45 08             	mov    0x8(%ebp),%eax
  10184c:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101850:	0f b7 c0             	movzwl %ax,%eax
  101853:	89 44 24 04          	mov    %eax,0x4(%esp)
  101857:	c7 04 24 48 5e 10 00 	movl   $0x105e48,(%esp)
  10185e:	e8 56 39 00 00       	call   1051b9 <cprintf>
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

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  10186d:	e8 22 fb ff ff       	call   101394 <cpu_cur>
  101872:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  101875:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101878:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10187e:	85 c0                	test   %eax,%eax
  101880:	74 1e                	je     1018a0 <trap+0x3b>
		c->recover(tf, c->recoverdata);
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
  1018b1:	e8 12 23 00 00       	call   103bc8 <syscall>
		//panic("unhandler system call\n");
	}

    
	switch(tf->trapno){
  1018b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1018b9:	8b 40 30             	mov    0x30(%eax),%eax
  1018bc:	83 f8 27             	cmp    $0x27,%eax
  1018bf:	74 15                	je     1018d6 <trap+0x71>
  1018c1:	83 f8 31             	cmp    $0x31,%eax
  1018c4:	75 2c                	jne    1018f2 <trap+0x8d>
		//cprintf("in switch\n");
		case T_LTIMER:
			//cprintf("in T_LTIMER\n");
			lapic_eoi();
  1018c6:	e8 56 2e 00 00       	call   104721 <lapic_eoi>
			//cprintf("before yield\n");
			proc_yield(tf);
  1018cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1018ce:	89 04 24             	mov    %eax,(%esp)
  1018d1:	e8 71 17 00 00       	call   103047 <proc_yield>
			break;
		case T_IRQ0 + IRQ_SPURIOUS:
			panic(" IRQ_SPURIOUS ");
  1018d6:	c7 44 24 08 5b 5e 10 	movl   $0x105e5b,0x8(%esp)
  1018dd:	00 
  1018de:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  1018e5:	00 
  1018e6:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  1018ed:	e8 8f eb ff ff       	call   100481 <debug_panic>

		default:
			proc_ret(tf, -1);
  1018f2:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1018f9:	ff 
  1018fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1018fd:	89 04 24             	mov    %eax,(%esp)
  101900:	e8 8c 17 00 00       	call   103091 <proc_ret>

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
  101932:	e8 b9 77 00 00       	call   1090f0 <trap_return>

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
  10194e:	c7 44 24 0c 76 5e 10 	movl   $0x105e76,0xc(%esp)
  101955:	00 
  101956:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  10195d:	00 
  10195e:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
  101965:	00 
  101966:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
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
  1019a4:	c7 04 24 8c 5e 10 00 	movl   $0x105e8c,(%esp)
  1019ab:	e8 09 38 00 00       	call   1051b9 <cprintf>
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
  1019ca:	c7 44 24 0c ac 5e 10 	movl   $0x105eac,0xc(%esp)
  1019d1:	00 
  1019d2:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  1019d9:	00 
  1019da:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  1019e1:	00 
  1019e2:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  1019e9:	e8 93 ea ff ff       	call   100481 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  1019ee:	c7 45 f0 00 80 10 00 	movl   $0x108000,-0x10(%ebp)
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
  101a1f:	c7 04 24 c1 5e 10 00 	movl   $0x105ec1,(%esp)
  101a26:	e8 8e 37 00 00       	call   1051b9 <cprintf>
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
  101a36:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101a3d:	8b 45 08             	mov    0x8(%ebp),%eax
  101a40:	8d 55 d8             	lea    -0x28(%ebp),%edx
  101a43:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  101a45:	c7 45 d8 53 1a 10 00 	movl   $0x101a53,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101a4c:	b8 00 00 00 00       	mov    $0x0,%eax
  101a51:	f7 f0                	div    %eax

00101a53 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  101a53:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101a56:	85 c0                	test   %eax,%eax
  101a58:	74 24                	je     101a7e <after_div0+0x2b>
  101a5a:	c7 44 24 0c df 5e 10 	movl   $0x105edf,0xc(%esp)
  101a61:	00 
  101a62:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  101a69:	00 
  101a6a:	c7 44 24 04 f4 00 00 	movl   $0xf4,0x4(%esp)
  101a71:	00 
  101a72:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  101a79:	e8 03 ea ff ff       	call   100481 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101a7e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101a81:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101a86:	74 24                	je     101aac <after_div0+0x59>
  101a88:	c7 44 24 0c f7 5e 10 	movl   $0x105ef7,0xc(%esp)
  101a8f:	00 
  101a90:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  101a97:	00 
  101a98:	c7 44 24 04 f9 00 00 	movl   $0xf9,0x4(%esp)
  101a9f:	00 
  101aa0:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  101aa7:	e8 d5 e9 ff ff       	call   100481 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101aac:	c7 45 d8 b4 1a 10 00 	movl   $0x101ab4,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  101ab3:	cc                   	int3   

00101ab4 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101ab4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101ab7:	83 f8 03             	cmp    $0x3,%eax
  101aba:	74 24                	je     101ae0 <after_breakpoint+0x2c>
  101abc:	c7 44 24 0c 0c 5f 10 	movl   $0x105f0c,0xc(%esp)
  101ac3:	00 
  101ac4:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  101acb:	00 
  101acc:	c7 44 24 04 fe 00 00 	movl   $0xfe,0x4(%esp)
  101ad3:	00 
  101ad4:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  101adb:	e8 a1 e9 ff ff       	call   100481 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101ae0:	c7 45 d8 ef 1a 10 00 	movl   $0x101aef,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101ae7:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101aec:	01 c0                	add    %eax,%eax
  101aee:	ce                   	into   

00101aef <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101aef:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101af2:	83 f8 04             	cmp    $0x4,%eax
  101af5:	74 24                	je     101b1b <after_overflow+0x2c>
  101af7:	c7 44 24 0c 23 5f 10 	movl   $0x105f23,0xc(%esp)
  101afe:	00 
  101aff:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  101b06:	00 
  101b07:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  101b0e:	00 
  101b0f:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  101b16:	e8 66 e9 ff ff       	call   100481 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101b1b:	c7 45 d8 38 1b 10 00 	movl   $0x101b38,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  101b22:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101b29:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  101b30:	b8 00 00 00 00       	mov    $0x0,%eax
  101b35:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101b38 <after_bound>:
	assert(args.trapno == T_BOUND);
  101b38:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101b3b:	83 f8 05             	cmp    $0x5,%eax
  101b3e:	74 24                	je     101b64 <after_bound+0x2c>
  101b40:	c7 44 24 0c 3a 5f 10 	movl   $0x105f3a,0xc(%esp)
  101b47:	00 
  101b48:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  101b4f:	00 
  101b50:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
  101b57:	00 
  101b58:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  101b5f:	e8 1d e9 ff ff       	call   100481 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  101b64:	c7 45 d8 6d 1b 10 00 	movl   $0x101b6d,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101b6b:	0f 0b                	ud2    

00101b6d <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101b6d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101b70:	83 f8 06             	cmp    $0x6,%eax
  101b73:	74 24                	je     101b99 <after_illegal+0x2c>
  101b75:	c7 44 24 0c 51 5f 10 	movl   $0x105f51,0xc(%esp)
  101b7c:	00 
  101b7d:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  101b84:	00 
  101b85:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
  101b8c:	00 
  101b8d:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  101b94:	e8 e8 e8 ff ff       	call   100481 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101b99:	c7 45 d8 a7 1b 10 00 	movl   $0x101ba7,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101ba0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101ba5:	8e e0                	mov    %eax,%fs

00101ba7 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101ba7:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101baa:	83 f8 0d             	cmp    $0xd,%eax
  101bad:	74 24                	je     101bd3 <after_gpfault+0x2c>
  101baf:	c7 44 24 0c 68 5f 10 	movl   $0x105f68,0xc(%esp)
  101bb6:	00 
  101bb7:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  101bbe:	00 
  101bbf:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
  101bc6:	00 
  101bc7:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  101bce:	e8 ae e8 ff ff       	call   100481 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101bd3:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  101bd6:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101bda:	0f b7 c0             	movzwl %ax,%eax
  101bdd:	83 e0 03             	and    $0x3,%eax
  101be0:	85 c0                	test   %eax,%eax
  101be2:	74 3a                	je     101c1e <after_priv+0x2c>
		args.reip = after_priv;
  101be4:	c7 45 d8 f2 1b 10 00 	movl   $0x101bf2,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101beb:	0f 01 1d 04 90 10 00 	lidtl  0x109004

00101bf2 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101bf2:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101bf5:	83 f8 0d             	cmp    $0xd,%eax
  101bf8:	74 24                	je     101c1e <after_priv+0x2c>
  101bfa:	c7 44 24 0c 68 5f 10 	movl   $0x105f68,0xc(%esp)
  101c01:	00 
  101c02:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  101c09:	00 
  101c0a:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
  101c11:	00 
  101c12:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  101c19:	e8 63 e8 ff ff       	call   100481 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101c1e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101c21:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101c26:	74 24                	je     101c4c <after_priv+0x5a>
  101c28:	c7 44 24 0c f7 5e 10 	movl   $0x105ef7,0xc(%esp)
  101c2f:	00 
  101c30:	c7 44 24 08 f6 5c 10 	movl   $0x105cf6,0x8(%esp)
  101c37:	00 
  101c38:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
  101c3f:	00 
  101c40:	c7 04 24 6a 5e 10 00 	movl   $0x105e6a,(%esp)
  101c47:	e8 35 e8 ff ff       	call   100481 <debug_panic>
	//cprintf("sfsfsfsfsfsfsfsfsf\n");
	*argsp = NULL;	// recovery mechanism not needed anymore
  101c4c:	8b 45 08             	mov    0x8(%ebp),%eax
  101c4f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101c55:	83 c4 3c             	add    $0x3c,%esp
  101c58:	5b                   	pop    %ebx
  101c59:	5e                   	pop    %esi
  101c5a:	5f                   	pop    %edi
  101c5b:	5d                   	pop    %ebp
  101c5c:	c3                   	ret    
  101c5d:	90                   	nop

00101c5e <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  101c5e:	6a 00                	push   $0x0
  101c60:	6a 00                	push   $0x0
  101c62:	e9 71 74 00 00       	jmp    1090d8 <_alltraps>
  101c67:	90                   	nop

00101c68 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  101c68:	6a 00                	push   $0x0
  101c6a:	6a 01                	push   $0x1
  101c6c:	e9 67 74 00 00       	jmp    1090d8 <_alltraps>
  101c71:	90                   	nop

00101c72 <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  101c72:	6a 00                	push   $0x0
  101c74:	6a 02                	push   $0x2
  101c76:	e9 5d 74 00 00       	jmp    1090d8 <_alltraps>
  101c7b:	90                   	nop

00101c7c <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  101c7c:	6a 00                	push   $0x0
  101c7e:	6a 03                	push   $0x3
  101c80:	e9 53 74 00 00       	jmp    1090d8 <_alltraps>
  101c85:	90                   	nop

00101c86 <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  101c86:	6a 00                	push   $0x0
  101c88:	6a 04                	push   $0x4
  101c8a:	e9 49 74 00 00       	jmp    1090d8 <_alltraps>
  101c8f:	90                   	nop

00101c90 <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  101c90:	6a 00                	push   $0x0
  101c92:	6a 05                	push   $0x5
  101c94:	e9 3f 74 00 00       	jmp    1090d8 <_alltraps>
  101c99:	90                   	nop

00101c9a <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  101c9a:	6a 00                	push   $0x0
  101c9c:	6a 06                	push   $0x6
  101c9e:	e9 35 74 00 00       	jmp    1090d8 <_alltraps>
  101ca3:	90                   	nop

00101ca4 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  101ca4:	6a 00                	push   $0x0
  101ca6:	6a 07                	push   $0x7
  101ca8:	e9 2b 74 00 00       	jmp    1090d8 <_alltraps>
  101cad:	90                   	nop

00101cae <vector8>:
TRAPHANDLER(vector8, 8)
  101cae:	6a 08                	push   $0x8
  101cb0:	e9 23 74 00 00       	jmp    1090d8 <_alltraps>
  101cb5:	90                   	nop

00101cb6 <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  101cb6:	6a 00                	push   $0x0
  101cb8:	6a 09                	push   $0x9
  101cba:	e9 19 74 00 00       	jmp    1090d8 <_alltraps>
  101cbf:	90                   	nop

00101cc0 <vector10>:
TRAPHANDLER(vector10, 10)
  101cc0:	6a 0a                	push   $0xa
  101cc2:	e9 11 74 00 00       	jmp    1090d8 <_alltraps>
  101cc7:	90                   	nop

00101cc8 <vector11>:
TRAPHANDLER(vector11, 11)
  101cc8:	6a 0b                	push   $0xb
  101cca:	e9 09 74 00 00       	jmp    1090d8 <_alltraps>
  101ccf:	90                   	nop

00101cd0 <vector12>:
TRAPHANDLER(vector12, 12)
  101cd0:	6a 0c                	push   $0xc
  101cd2:	e9 01 74 00 00       	jmp    1090d8 <_alltraps>
  101cd7:	90                   	nop

00101cd8 <vector13>:
TRAPHANDLER(vector13, 13)
  101cd8:	6a 0d                	push   $0xd
  101cda:	e9 f9 73 00 00       	jmp    1090d8 <_alltraps>
  101cdf:	90                   	nop

00101ce0 <vector14>:
TRAPHANDLER(vector14, 14)
  101ce0:	6a 0e                	push   $0xe
  101ce2:	e9 f1 73 00 00       	jmp    1090d8 <_alltraps>
  101ce7:	90                   	nop

00101ce8 <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101ce8:	6a 00                	push   $0x0
  101cea:	6a 0f                	push   $0xf
  101cec:	e9 e7 73 00 00       	jmp    1090d8 <_alltraps>
  101cf1:	90                   	nop

00101cf2 <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  101cf2:	6a 00                	push   $0x0
  101cf4:	6a 10                	push   $0x10
  101cf6:	e9 dd 73 00 00       	jmp    1090d8 <_alltraps>
  101cfb:	90                   	nop

00101cfc <vector17>:
TRAPHANDLER(vector17, 17)
  101cfc:	6a 11                	push   $0x11
  101cfe:	e9 d5 73 00 00       	jmp    1090d8 <_alltraps>
  101d03:	90                   	nop

00101d04 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  101d04:	6a 00                	push   $0x0
  101d06:	6a 12                	push   $0x12
  101d08:	e9 cb 73 00 00       	jmp    1090d8 <_alltraps>
  101d0d:	90                   	nop

00101d0e <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  101d0e:	6a 00                	push   $0x0
  101d10:	6a 13                	push   $0x13
  101d12:	e9 c1 73 00 00       	jmp    1090d8 <_alltraps>
  101d17:	90                   	nop

00101d18 <vector20>:
TRAPHANDLER_NOEC(vector20, 20)
  101d18:	6a 00                	push   $0x0
  101d1a:	6a 14                	push   $0x14
  101d1c:	e9 b7 73 00 00       	jmp    1090d8 <_alltraps>
  101d21:	90                   	nop

00101d22 <vector21>:
TRAPHANDLER_NOEC(vector21, 21)
  101d22:	6a 00                	push   $0x0
  101d24:	6a 15                	push   $0x15
  101d26:	e9 ad 73 00 00       	jmp    1090d8 <_alltraps>
  101d2b:	90                   	nop

00101d2c <vector22>:
TRAPHANDLER_NOEC(vector22, 22)
  101d2c:	6a 00                	push   $0x0
  101d2e:	6a 16                	push   $0x16
  101d30:	e9 a3 73 00 00       	jmp    1090d8 <_alltraps>
  101d35:	90                   	nop

00101d36 <vector23>:
TRAPHANDLER_NOEC(vector23, 23)
  101d36:	6a 00                	push   $0x0
  101d38:	6a 17                	push   $0x17
  101d3a:	e9 99 73 00 00       	jmp    1090d8 <_alltraps>
  101d3f:	90                   	nop

00101d40 <vector24>:
TRAPHANDLER_NOEC(vector24, 24)
  101d40:	6a 00                	push   $0x0
  101d42:	6a 18                	push   $0x18
  101d44:	e9 8f 73 00 00       	jmp    1090d8 <_alltraps>
  101d49:	90                   	nop

00101d4a <vector25>:
TRAPHANDLER_NOEC(vector25, 25)
  101d4a:	6a 00                	push   $0x0
  101d4c:	6a 19                	push   $0x19
  101d4e:	e9 85 73 00 00       	jmp    1090d8 <_alltraps>
  101d53:	90                   	nop

00101d54 <vector26>:
TRAPHANDLER_NOEC(vector26, 26)
  101d54:	6a 00                	push   $0x0
  101d56:	6a 1a                	push   $0x1a
  101d58:	e9 7b 73 00 00       	jmp    1090d8 <_alltraps>
  101d5d:	90                   	nop

00101d5e <vector27>:
TRAPHANDLER_NOEC(vector27, 27)
  101d5e:	6a 00                	push   $0x0
  101d60:	6a 1b                	push   $0x1b
  101d62:	e9 71 73 00 00       	jmp    1090d8 <_alltraps>
  101d67:	90                   	nop

00101d68 <vector28>:
TRAPHANDLER_NOEC(vector28, 28)
  101d68:	6a 00                	push   $0x0
  101d6a:	6a 1c                	push   $0x1c
  101d6c:	e9 67 73 00 00       	jmp    1090d8 <_alltraps>
  101d71:	90                   	nop

00101d72 <vector29>:
TRAPHANDLER_NOEC(vector29, 29)
  101d72:	6a 00                	push   $0x0
  101d74:	6a 1d                	push   $0x1d
  101d76:	e9 5d 73 00 00       	jmp    1090d8 <_alltraps>
  101d7b:	90                   	nop

00101d7c <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101d7c:	6a 00                	push   $0x0
  101d7e:	6a 1e                	push   $0x1e
  101d80:	e9 53 73 00 00       	jmp    1090d8 <_alltraps>
  101d85:	90                   	nop

00101d86 <vector31>:
TRAPHANDLER_NOEC(vector31, 31)
  101d86:	6a 00                	push   $0x0
  101d88:	6a 1f                	push   $0x1f
  101d8a:	e9 49 73 00 00       	jmp    1090d8 <_alltraps>
  101d8f:	90                   	nop

00101d90 <vector32>:
TRAPHANDLER_NOEC(vector32, 32)
  101d90:	6a 00                	push   $0x0
  101d92:	6a 20                	push   $0x20
  101d94:	e9 3f 73 00 00       	jmp    1090d8 <_alltraps>
  101d99:	90                   	nop

00101d9a <vector33>:
TRAPHANDLER_NOEC(vector33, 33)
  101d9a:	6a 00                	push   $0x0
  101d9c:	6a 21                	push   $0x21
  101d9e:	e9 35 73 00 00       	jmp    1090d8 <_alltraps>
  101da3:	90                   	nop

00101da4 <vector34>:
TRAPHANDLER_NOEC(vector34, 34)
  101da4:	6a 00                	push   $0x0
  101da6:	6a 22                	push   $0x22
  101da8:	e9 2b 73 00 00       	jmp    1090d8 <_alltraps>
  101dad:	90                   	nop

00101dae <vector35>:
TRAPHANDLER_NOEC(vector35, 35)
  101dae:	6a 00                	push   $0x0
  101db0:	6a 23                	push   $0x23
  101db2:	e9 21 73 00 00       	jmp    1090d8 <_alltraps>
  101db7:	90                   	nop

00101db8 <vector36>:
TRAPHANDLER_NOEC(vector36, 36)
  101db8:	6a 00                	push   $0x0
  101dba:	6a 24                	push   $0x24
  101dbc:	e9 17 73 00 00       	jmp    1090d8 <_alltraps>
  101dc1:	90                   	nop

00101dc2 <vector37>:
TRAPHANDLER_NOEC(vector37, 37)
  101dc2:	6a 00                	push   $0x0
  101dc4:	6a 25                	push   $0x25
  101dc6:	e9 0d 73 00 00       	jmp    1090d8 <_alltraps>
  101dcb:	90                   	nop

00101dcc <vector38>:
TRAPHANDLER_NOEC(vector38, 38)
  101dcc:	6a 00                	push   $0x0
  101dce:	6a 26                	push   $0x26
  101dd0:	e9 03 73 00 00       	jmp    1090d8 <_alltraps>
  101dd5:	90                   	nop

00101dd6 <vector39>:
TRAPHANDLER_NOEC(vector39, 39)
  101dd6:	6a 00                	push   $0x0
  101dd8:	6a 27                	push   $0x27
  101dda:	e9 f9 72 00 00       	jmp    1090d8 <_alltraps>
  101ddf:	90                   	nop

00101de0 <vector40>:
TRAPHANDLER_NOEC(vector40, 40)
  101de0:	6a 00                	push   $0x0
  101de2:	6a 28                	push   $0x28
  101de4:	e9 ef 72 00 00       	jmp    1090d8 <_alltraps>
  101de9:	90                   	nop

00101dea <vector41>:
TRAPHANDLER_NOEC(vector41, 41)
  101dea:	6a 00                	push   $0x0
  101dec:	6a 29                	push   $0x29
  101dee:	e9 e5 72 00 00       	jmp    1090d8 <_alltraps>
  101df3:	90                   	nop

00101df4 <vector42>:
TRAPHANDLER_NOEC(vector42, 42)
  101df4:	6a 00                	push   $0x0
  101df6:	6a 2a                	push   $0x2a
  101df8:	e9 db 72 00 00       	jmp    1090d8 <_alltraps>
  101dfd:	90                   	nop

00101dfe <vector43>:
TRAPHANDLER_NOEC(vector43, 43)
  101dfe:	6a 00                	push   $0x0
  101e00:	6a 2b                	push   $0x2b
  101e02:	e9 d1 72 00 00       	jmp    1090d8 <_alltraps>
  101e07:	90                   	nop

00101e08 <vector44>:
TRAPHANDLER_NOEC(vector44, 44)
  101e08:	6a 00                	push   $0x0
  101e0a:	6a 2c                	push   $0x2c
  101e0c:	e9 c7 72 00 00       	jmp    1090d8 <_alltraps>
  101e11:	90                   	nop

00101e12 <vector45>:
TRAPHANDLER_NOEC(vector45, 45)
  101e12:	6a 00                	push   $0x0
  101e14:	6a 2d                	push   $0x2d
  101e16:	e9 bd 72 00 00       	jmp    1090d8 <_alltraps>
  101e1b:	90                   	nop

00101e1c <vector46>:
TRAPHANDLER_NOEC(vector46, 46)
  101e1c:	6a 00                	push   $0x0
  101e1e:	6a 2e                	push   $0x2e
  101e20:	e9 b3 72 00 00       	jmp    1090d8 <_alltraps>
  101e25:	90                   	nop

00101e26 <vector47>:
TRAPHANDLER_NOEC(vector47, 47)
  101e26:	6a 00                	push   $0x0
  101e28:	6a 2f                	push   $0x2f
  101e2a:	e9 a9 72 00 00       	jmp    1090d8 <_alltraps>
  101e2f:	90                   	nop

00101e30 <vector48>:
TRAPHANDLER_NOEC(vector48, 48)
  101e30:	6a 00                	push   $0x0
  101e32:	6a 30                	push   $0x30
  101e34:	e9 9f 72 00 00       	jmp    1090d8 <_alltraps>
  101e39:	90                   	nop

00101e3a <vector49>:
TRAPHANDLER_NOEC(vector49, 49)
  101e3a:	6a 00                	push   $0x0
  101e3c:	6a 31                	push   $0x31
  101e3e:	e9 95 72 00 00       	jmp    1090d8 <_alltraps>

00101e43 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101e43:	55                   	push   %ebp
  101e44:	89 e5                	mov    %esp,%ebp
  101e46:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101e49:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101e4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101e4f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101e52:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e55:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101e5a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101e5d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101e60:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101e66:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101e6b:	74 24                	je     101e91 <cpu_cur+0x4e>
  101e6d:	c7 44 24 0c 30 61 10 	movl   $0x106130,0xc(%esp)
  101e74:	00 
  101e75:	c7 44 24 08 46 61 10 	movl   $0x106146,0x8(%esp)
  101e7c:	00 
  101e7d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101e84:	00 
  101e85:	c7 04 24 5b 61 10 00 	movl   $0x10615b,(%esp)
  101e8c:	e8 f0 e5 ff ff       	call   100481 <debug_panic>
	return c;
  101e91:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101e94:	c9                   	leave  
  101e95:	c3                   	ret    

00101e96 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101e96:	55                   	push   %ebp
  101e97:	89 e5                	mov    %esp,%ebp
  101e99:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101e9c:	e8 a2 ff ff ff       	call   101e43 <cpu_cur>
  101ea1:	3d 00 80 10 00       	cmp    $0x108000,%eax
  101ea6:	0f 94 c0             	sete   %al
  101ea9:	0f b6 c0             	movzbl %al,%eax
}
  101eac:	c9                   	leave  
  101ead:	c3                   	ret    

00101eae <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  101eae:	55                   	push   %ebp
  101eaf:	89 e5                	mov    %esp,%ebp
  101eb1:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  101eb4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	for (i = 0; i < len; i++)
  101ebb:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  101ec2:	eb 13                	jmp    101ed7 <sum+0x29>
		sum += addr[i];
  101ec4:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101ec7:	03 45 08             	add    0x8(%ebp),%eax
  101eca:	0f b6 00             	movzbl (%eax),%eax
  101ecd:	0f b6 c0             	movzbl %al,%eax
  101ed0:	01 45 fc             	add    %eax,-0x4(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  101ed3:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  101ed7:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101eda:	3b 45 0c             	cmp    0xc(%ebp),%eax
  101edd:	7c e5                	jl     101ec4 <sum+0x16>
		sum += addr[i];
	return sum;
  101edf:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101ee2:	c9                   	leave  
  101ee3:	c3                   	ret    

00101ee4 <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  101ee4:	55                   	push   %ebp
  101ee5:	89 e5                	mov    %esp,%ebp
  101ee7:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  101eea:	8b 45 0c             	mov    0xc(%ebp),%eax
  101eed:	03 45 08             	add    0x8(%ebp),%eax
  101ef0:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  101ef3:	8b 45 08             	mov    0x8(%ebp),%eax
  101ef6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101ef9:	eb 3f                	jmp    101f3a <mpsearch1+0x56>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  101efb:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  101f02:	00 
  101f03:	c7 44 24 04 68 61 10 	movl   $0x106168,0x4(%esp)
  101f0a:	00 
  101f0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f0e:	89 04 24             	mov    %eax,(%esp)
  101f11:	e8 f8 35 00 00       	call   10550e <memcmp>
  101f16:	85 c0                	test   %eax,%eax
  101f18:	75 1c                	jne    101f36 <mpsearch1+0x52>
  101f1a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  101f21:	00 
  101f22:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f25:	89 04 24             	mov    %eax,(%esp)
  101f28:	e8 81 ff ff ff       	call   101eae <sum>
  101f2d:	84 c0                	test   %al,%al
  101f2f:	75 05                	jne    101f36 <mpsearch1+0x52>
			return (struct mp *) p;
  101f31:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f34:	eb 11                	jmp    101f47 <mpsearch1+0x63>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  101f36:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  101f3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f3d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  101f40:	72 b9                	jb     101efb <mpsearch1+0x17>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  101f42:	b8 00 00 00 00       	mov    $0x0,%eax
}
  101f47:	c9                   	leave  
  101f48:	c3                   	ret    

00101f49 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  101f49:	55                   	push   %ebp
  101f4a:	89 e5                	mov    %esp,%ebp
  101f4c:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  101f4f:	c7 45 ec 00 04 00 00 	movl   $0x400,-0x14(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  101f56:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101f59:	83 c0 0f             	add    $0xf,%eax
  101f5c:	0f b6 00             	movzbl (%eax),%eax
  101f5f:	0f b6 c0             	movzbl %al,%eax
  101f62:	89 c2                	mov    %eax,%edx
  101f64:	c1 e2 08             	shl    $0x8,%edx
  101f67:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101f6a:	83 c0 0e             	add    $0xe,%eax
  101f6d:	0f b6 00             	movzbl (%eax),%eax
  101f70:	0f b6 c0             	movzbl %al,%eax
  101f73:	09 d0                	or     %edx,%eax
  101f75:	c1 e0 04             	shl    $0x4,%eax
  101f78:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101f7b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101f7f:	74 21                	je     101fa2 <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  101f81:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f84:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  101f8b:	00 
  101f8c:	89 04 24             	mov    %eax,(%esp)
  101f8f:	e8 50 ff ff ff       	call   101ee4 <mpsearch1>
  101f94:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101f97:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101f9b:	74 50                	je     101fed <mpsearch+0xa4>
			return mp;
  101f9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101fa0:	eb 5f                	jmp    102001 <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  101fa2:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101fa5:	83 c0 14             	add    $0x14,%eax
  101fa8:	0f b6 00             	movzbl (%eax),%eax
  101fab:	0f b6 c0             	movzbl %al,%eax
  101fae:	89 c2                	mov    %eax,%edx
  101fb0:	c1 e2 08             	shl    $0x8,%edx
  101fb3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101fb6:	83 c0 13             	add    $0x13,%eax
  101fb9:	0f b6 00             	movzbl (%eax),%eax
  101fbc:	0f b6 c0             	movzbl %al,%eax
  101fbf:	09 d0                	or     %edx,%eax
  101fc1:	c1 e0 0a             	shl    $0xa,%eax
  101fc4:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  101fc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101fca:	2d 00 04 00 00       	sub    $0x400,%eax
  101fcf:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  101fd6:	00 
  101fd7:	89 04 24             	mov    %eax,(%esp)
  101fda:	e8 05 ff ff ff       	call   101ee4 <mpsearch1>
  101fdf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101fe2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101fe6:	74 05                	je     101fed <mpsearch+0xa4>
			return mp;
  101fe8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101feb:	eb 14                	jmp    102001 <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  101fed:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  101ff4:	00 
  101ff5:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  101ffc:	e8 e3 fe ff ff       	call   101ee4 <mpsearch1>
}
  102001:	c9                   	leave  
  102002:	c3                   	ret    

00102003 <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  102003:	55                   	push   %ebp
  102004:	89 e5                	mov    %esp,%ebp
  102006:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  102009:	e8 3b ff ff ff       	call   101f49 <mpsearch>
  10200e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102011:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102015:	74 0a                	je     102021 <mpconfig+0x1e>
  102017:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10201a:	8b 40 04             	mov    0x4(%eax),%eax
  10201d:	85 c0                	test   %eax,%eax
  10201f:	75 07                	jne    102028 <mpconfig+0x25>
		return 0;
  102021:	b8 00 00 00 00       	mov    $0x0,%eax
  102026:	eb 7b                	jmp    1020a3 <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  102028:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10202b:	8b 40 04             	mov    0x4(%eax),%eax
  10202e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  102031:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  102038:	00 
  102039:	c7 44 24 04 6d 61 10 	movl   $0x10616d,0x4(%esp)
  102040:	00 
  102041:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102044:	89 04 24             	mov    %eax,(%esp)
  102047:	e8 c2 34 00 00       	call   10550e <memcmp>
  10204c:	85 c0                	test   %eax,%eax
  10204e:	74 07                	je     102057 <mpconfig+0x54>
		return 0;
  102050:	b8 00 00 00 00       	mov    $0x0,%eax
  102055:	eb 4c                	jmp    1020a3 <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  102057:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10205a:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  10205e:	3c 01                	cmp    $0x1,%al
  102060:	74 12                	je     102074 <mpconfig+0x71>
  102062:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102065:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102069:	3c 04                	cmp    $0x4,%al
  10206b:	74 07                	je     102074 <mpconfig+0x71>
		return 0;
  10206d:	b8 00 00 00 00       	mov    $0x0,%eax
  102072:	eb 2f                	jmp    1020a3 <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  102074:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102077:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  10207b:	0f b7 d0             	movzwl %ax,%edx
  10207e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102081:	89 54 24 04          	mov    %edx,0x4(%esp)
  102085:	89 04 24             	mov    %eax,(%esp)
  102088:	e8 21 fe ff ff       	call   101eae <sum>
  10208d:	84 c0                	test   %al,%al
  10208f:	74 07                	je     102098 <mpconfig+0x95>
		return 0;
  102091:	b8 00 00 00 00       	mov    $0x0,%eax
  102096:	eb 0b                	jmp    1020a3 <mpconfig+0xa0>
       *pmp = mp;
  102098:	8b 45 08             	mov    0x8(%ebp),%eax
  10209b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10209e:	89 10                	mov    %edx,(%eax)
	return conf;
  1020a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1020a3:	c9                   	leave  
  1020a4:	c3                   	ret    

001020a5 <mp_init>:

void
mp_init(void)
{
  1020a5:	55                   	push   %ebp
  1020a6:	89 e5                	mov    %esp,%ebp
  1020a8:	83 ec 48             	sub    $0x48,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  1020ab:	e8 e6 fd ff ff       	call   101e96 <cpu_onboot>
  1020b0:	85 c0                	test   %eax,%eax
  1020b2:	0f 84 72 01 00 00    	je     10222a <mp_init+0x185>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  1020b8:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1020bb:	89 04 24             	mov    %eax,(%esp)
  1020be:	e8 40 ff ff ff       	call   102003 <mpconfig>
  1020c3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  1020c6:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  1020ca:	0f 84 5d 01 00 00    	je     10222d <mp_init+0x188>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  1020d0:	c7 05 04 f4 30 00 01 	movl   $0x1,0x30f404
  1020d7:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  1020da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1020dd:	8b 40 24             	mov    0x24(%eax),%eax
  1020e0:	a3 0c fb 30 00       	mov    %eax,0x30fb0c
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  1020e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1020e8:	83 c0 2c             	add    $0x2c,%eax
  1020eb:	89 45 cc             	mov    %eax,-0x34(%ebp)
  1020ee:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1020f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1020f4:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  1020f8:	0f b7 c0             	movzwl %ax,%eax
  1020fb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1020fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102101:	e9 cc 00 00 00       	jmp    1021d2 <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  102106:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102109:	0f b6 00             	movzbl (%eax),%eax
  10210c:	0f b6 c0             	movzbl %al,%eax
  10210f:	83 f8 04             	cmp    $0x4,%eax
  102112:	0f 87 90 00 00 00    	ja     1021a8 <mp_init+0x103>
  102118:	8b 04 85 a0 61 10 00 	mov    0x1061a0(,%eax,4),%eax
  10211f:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  102121:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102124:	89 45 d8             	mov    %eax,-0x28(%ebp)
			p += sizeof(struct mpproc);
  102127:	83 45 cc 14          	addl   $0x14,-0x34(%ebp)
			if (!(proc->flags & MPENAB))
  10212b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10212e:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102132:	0f b6 c0             	movzbl %al,%eax
  102135:	83 e0 01             	and    $0x1,%eax
  102138:	85 c0                	test   %eax,%eax
  10213a:	0f 84 91 00 00 00    	je     1021d1 <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  102140:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102143:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102147:	0f b6 c0             	movzbl %al,%eax
  10214a:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  10214d:	85 c0                	test   %eax,%eax
  10214f:	75 07                	jne    102158 <mp_init+0xb3>
  102151:	e8 cf f0 ff ff       	call   101225 <cpu_alloc>
  102156:	eb 05                	jmp    10215d <mp_init+0xb8>
  102158:	b8 00 80 10 00       	mov    $0x108000,%eax
  10215d:	89 45 e0             	mov    %eax,-0x20(%ebp)
			c->id = proc->apicid;
  102160:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102163:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  102167:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10216a:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  102170:	a1 08 f4 30 00       	mov    0x30f408,%eax
  102175:	83 c0 01             	add    $0x1,%eax
  102178:	a3 08 f4 30 00       	mov    %eax,0x30f408
			continue;
  10217d:	eb 53                	jmp    1021d2 <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  10217f:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102182:	89 45 dc             	mov    %eax,-0x24(%ebp)
			p += sizeof(struct mpioapic);
  102185:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			ioapicid = mpio->apicno;
  102189:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10218c:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  102190:	a2 fc f3 30 00       	mov    %al,0x30f3fc
			ioapic = (struct ioapic *) mpio->addr;
  102195:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102198:	8b 40 04             	mov    0x4(%eax),%eax
  10219b:	a3 00 f4 30 00       	mov    %eax,0x30f400
			continue;
  1021a0:	eb 30                	jmp    1021d2 <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  1021a2:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			continue;
  1021a6:	eb 2a                	jmp    1021d2 <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  1021a8:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1021ab:	0f b6 00             	movzbl (%eax),%eax
  1021ae:	0f b6 c0             	movzbl %al,%eax
  1021b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1021b5:	c7 44 24 08 74 61 10 	movl   $0x106174,0x8(%esp)
  1021bc:	00 
  1021bd:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  1021c4:	00 
  1021c5:	c7 04 24 94 61 10 00 	movl   $0x106194,(%esp)
  1021cc:	e8 b0 e2 ff ff       	call   100481 <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  1021d1:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  1021d2:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1021d5:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1021d8:	0f 82 28 ff ff ff    	jb     102106 <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  1021de:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1021e1:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  1021e5:	84 c0                	test   %al,%al
  1021e7:	74 45                	je     10222e <mp_init+0x189>
  1021e9:	c7 45 e8 22 00 00 00 	movl   $0x22,-0x18(%ebp)
  1021f0:	c6 45 e7 70          	movb   $0x70,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1021f4:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1021f8:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1021fb:	ee                   	out    %al,(%dx)
  1021fc:	c7 45 ec 23 00 00 00 	movl   $0x23,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102203:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102206:	89 c2                	mov    %eax,%edx
  102208:	ec                   	in     (%dx),%al
  102209:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10220c:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  102210:	83 c8 01             	or     $0x1,%eax
  102213:	0f b6 c0             	movzbl %al,%eax
  102216:	c7 45 f4 23 00 00 00 	movl   $0x23,-0xc(%ebp)
  10221d:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102220:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  102224:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102227:	ee                   	out    %al,(%dx)
  102228:	eb 04                	jmp    10222e <mp_init+0x189>
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  10222a:	90                   	nop
  10222b:	eb 01                	jmp    10222e <mp_init+0x189>

	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.
  10222d:	90                   	nop
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
	}
}
  10222e:	c9                   	leave  
  10222f:	c3                   	ret    

00102230 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  102230:	55                   	push   %ebp
  102231:	89 e5                	mov    %esp,%ebp
  102233:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102236:	8b 55 08             	mov    0x8(%ebp),%edx
  102239:	8b 45 0c             	mov    0xc(%ebp),%eax
  10223c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10223f:	f0 87 02             	lock xchg %eax,(%edx)
  102242:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102245:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102248:	c9                   	leave  
  102249:	c3                   	ret    

0010224a <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10224a:	55                   	push   %ebp
  10224b:	89 e5                	mov    %esp,%ebp
  10224d:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102250:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  102253:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102256:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102259:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10225c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102261:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  102264:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102267:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10226d:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102272:	74 24                	je     102298 <cpu_cur+0x4e>
  102274:	c7 44 24 0c b4 61 10 	movl   $0x1061b4,0xc(%esp)
  10227b:	00 
  10227c:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  102283:	00 
  102284:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10228b:	00 
  10228c:	c7 04 24 df 61 10 00 	movl   $0x1061df,(%esp)
  102293:	e8 e9 e1 ff ff       	call   100481 <debug_panic>
	return c;
  102298:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10229b:	c9                   	leave  
  10229c:	c3                   	ret    

0010229d <spinlock_init_>:
#include <kern/cons.h>


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  10229d:	55                   	push   %ebp
  10229e:	89 e5                	mov    %esp,%ebp
	lk->locked = 0;
  1022a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1022a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->file = file;
  1022a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1022ac:	8b 55 0c             	mov    0xc(%ebp),%edx
  1022af:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  1022b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1022b5:	8b 55 10             	mov    0x10(%ebp),%edx
  1022b8:	89 50 08             	mov    %edx,0x8(%eax)
	lk->cpu = NULL;
  1022bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1022be:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	lk->eips[0] = 0;
  1022c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1022c8:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
}
  1022cf:	5d                   	pop    %ebp
  1022d0:	c3                   	ret    

001022d1 <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  1022d1:	55                   	push   %ebp
  1022d2:	89 e5                	mov    %esp,%ebp
  1022d4:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in sa\n");

	if(spinlock_holding(lk)){
  1022d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1022da:	89 04 24             	mov    %eax,(%esp)
  1022dd:	e8 b6 00 00 00       	call   102398 <spinlock_holding>
  1022e2:	85 c0                	test   %eax,%eax
  1022e4:	74 1c                	je     102302 <spinlock_acquire+0x31>
		//cprintf("acquire\n");
		//cprintf("file = %s, line = %d, cpu = %d\n", lk->file, lk->line, lk->cpu->id);
		panic("acquire");
  1022e6:	c7 44 24 08 ec 61 10 	movl   $0x1061ec,0x8(%esp)
  1022ed:	00 
  1022ee:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
  1022f5:	00 
  1022f6:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  1022fd:	e8 7f e1 ff ff       	call   100481 <debug_panic>
	}

	while(xchg(&lk->locked, 1) !=0)
  102302:	8b 45 08             	mov    0x8(%ebp),%eax
  102305:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10230c:	00 
  10230d:	89 04 24             	mov    %eax,(%esp)
  102310:	e8 1b ff ff ff       	call   102230 <xchg>
  102315:	85 c0                	test   %eax,%eax
  102317:	75 e9                	jne    102302 <spinlock_acquire+0x31>
		{//cprintf("in xchg\n")
		;}

	lk->cpu = cpu_cur();
  102319:	e8 2c ff ff ff       	call   10224a <cpu_cur>
  10231e:	8b 55 08             	mov    0x8(%ebp),%edx
  102321:	89 42 0c             	mov    %eax,0xc(%edx)

	//cprintf("before dt\n");
	debug_trace(read_ebp(), lk->eips);
  102324:	8b 45 08             	mov    0x8(%ebp),%eax
  102327:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10232a:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  10232d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102330:	89 54 24 04          	mov    %edx,0x4(%esp)
  102334:	89 04 24             	mov    %eax,(%esp)
  102337:	e8 4d e2 ff ff       	call   100589 <debug_trace>
	//cprintf("after dt\n");

	//cprintf("after sa\n");

	//cprintf("acquire lock num: %d on cpu: %d\n", lk->number, lk->cpu->id);
}
  10233c:	c9                   	leave  
  10233d:	c3                   	ret    

0010233e <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  10233e:	55                   	push   %ebp
  10233f:	89 e5                	mov    %esp,%ebp
  102341:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk))
  102344:	8b 45 08             	mov    0x8(%ebp),%eax
  102347:	89 04 24             	mov    %eax,(%esp)
  10234a:	e8 49 00 00 00       	call   102398 <spinlock_holding>
  10234f:	85 c0                	test   %eax,%eax
  102351:	75 1c                	jne    10236f <spinlock_release+0x31>
		panic("release");
  102353:	c7 44 24 08 04 62 10 	movl   $0x106204,0x8(%esp)
  10235a:	00 
  10235b:	c7 44 24 04 40 00 00 	movl   $0x40,0x4(%esp)
  102362:	00 
  102363:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  10236a:	e8 12 e1 ff ff       	call   100481 <debug_panic>

	lk->cpu = NULL;
  10236f:	8b 45 08             	mov    0x8(%ebp),%eax
  102372:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	xchg(&lk->locked, 0);
  102379:	8b 45 08             	mov    0x8(%ebp),%eax
  10237c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102383:	00 
  102384:	89 04 24             	mov    %eax,(%esp)
  102387:	e8 a4 fe ff ff       	call   102230 <xchg>

	lk->eips[0] = 0;
  10238c:	8b 45 08             	mov    0x8(%ebp),%eax
  10238f:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)

	//cprintf("release lock num: %d on cpu: %d\n", lk->number, lk->cpu->id);
}
  102396:	c9                   	leave  
  102397:	c3                   	ret    

00102398 <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  102398:	55                   	push   %ebp
  102399:	89 e5                	mov    %esp,%ebp
  10239b:	53                   	push   %ebx
  10239c:	83 ec 04             	sub    $0x4,%esp
	return (lock->cpu == cpu_cur()) && (lock->locked);
  10239f:	8b 45 08             	mov    0x8(%ebp),%eax
  1023a2:	8b 58 0c             	mov    0xc(%eax),%ebx
  1023a5:	e8 a0 fe ff ff       	call   10224a <cpu_cur>
  1023aa:	39 c3                	cmp    %eax,%ebx
  1023ac:	75 10                	jne    1023be <spinlock_holding+0x26>
  1023ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1023b1:	8b 00                	mov    (%eax),%eax
  1023b3:	85 c0                	test   %eax,%eax
  1023b5:	74 07                	je     1023be <spinlock_holding+0x26>
  1023b7:	b8 01 00 00 00       	mov    $0x1,%eax
  1023bc:	eb 05                	jmp    1023c3 <spinlock_holding+0x2b>
  1023be:	b8 00 00 00 00       	mov    $0x0,%eax
	//panic("spinlock_holding() not implemented");
}
  1023c3:	83 c4 04             	add    $0x4,%esp
  1023c6:	5b                   	pop    %ebx
  1023c7:	5d                   	pop    %ebp
  1023c8:	c3                   	ret    

001023c9 <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  1023c9:	55                   	push   %ebp
  1023ca:	89 e5                	mov    %esp,%ebp
  1023cc:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  1023cf:	8b 45 08             	mov    0x8(%ebp),%eax
  1023d2:	85 c0                	test   %eax,%eax
  1023d4:	75 12                	jne    1023e8 <spinlock_godeep+0x1f>
  1023d6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023d9:	89 04 24             	mov    %eax,(%esp)
  1023dc:	e8 f0 fe ff ff       	call   1022d1 <spinlock_acquire>
  1023e1:	b8 01 00 00 00       	mov    $0x1,%eax
  1023e6:	eb 1b                	jmp    102403 <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  1023e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1023eb:	8d 50 ff             	lea    -0x1(%eax),%edx
  1023ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023f1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023f5:	89 14 24             	mov    %edx,(%esp)
  1023f8:	e8 cc ff ff ff       	call   1023c9 <spinlock_godeep>
  1023fd:	8b 55 08             	mov    0x8(%ebp),%edx
  102400:	0f af c2             	imul   %edx,%eax
}
  102403:	c9                   	leave  
  102404:	c3                   	ret    

00102405 <spinlock_check>:



void spinlock_check()
{
  102405:	55                   	push   %ebp
  102406:	89 e5                	mov    %esp,%ebp
  102408:	57                   	push   %edi
  102409:	56                   	push   %esi
  10240a:	53                   	push   %ebx
  10240b:	83 ec 5c             	sub    $0x5c,%esp
  10240e:	89 e0                	mov    %esp,%eax
  102410:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	const int NUMLOCKS=10;
  102413:	c7 45 d0 0a 00 00 00 	movl   $0xa,-0x30(%ebp)
	const int NUMRUNS=5;
  10241a:	c7 45 d4 05 00 00 00 	movl   $0x5,-0x2c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  102421:	c7 45 e4 0c 62 10 00 	movl   $0x10620c,-0x1c(%ebp)
	spinlock locks[NUMLOCKS];
  102428:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10242b:	83 e8 01             	sub    $0x1,%eax
  10242e:	89 45 c8             	mov    %eax,-0x38(%ebp)
  102431:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102434:	ba 00 00 00 00       	mov    $0x0,%edx
  102439:	89 c1                	mov    %eax,%ecx
  10243b:	80 e5 ff             	and    $0xff,%ch
  10243e:	89 d3                	mov    %edx,%ebx
  102440:	83 e3 0f             	and    $0xf,%ebx
  102443:	89 c8                	mov    %ecx,%eax
  102445:	89 da                	mov    %ebx,%edx
  102447:	69 da c0 01 00 00    	imul   $0x1c0,%edx,%ebx
  10244d:	6b c8 00             	imul   $0x0,%eax,%ecx
  102450:	01 cb                	add    %ecx,%ebx
  102452:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102457:	f7 e1                	mul    %ecx
  102459:	01 d3                	add    %edx,%ebx
  10245b:	89 da                	mov    %ebx,%edx
  10245d:	89 c6                	mov    %eax,%esi
  10245f:	83 e6 ff             	and    $0xffffffff,%esi
  102462:	89 d7                	mov    %edx,%edi
  102464:	83 e7 0f             	and    $0xf,%edi
  102467:	89 f0                	mov    %esi,%eax
  102469:	89 fa                	mov    %edi,%edx
  10246b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10246e:	c1 e0 03             	shl    $0x3,%eax
  102471:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102474:	ba 00 00 00 00       	mov    $0x0,%edx
  102479:	89 c1                	mov    %eax,%ecx
  10247b:	80 e5 ff             	and    $0xff,%ch
  10247e:	89 4d b8             	mov    %ecx,-0x48(%ebp)
  102481:	89 d3                	mov    %edx,%ebx
  102483:	83 e3 0f             	and    $0xf,%ebx
  102486:	89 5d bc             	mov    %ebx,-0x44(%ebp)
  102489:	8b 45 b8             	mov    -0x48(%ebp),%eax
  10248c:	8b 55 bc             	mov    -0x44(%ebp),%edx
  10248f:	69 ca c0 01 00 00    	imul   $0x1c0,%edx,%ecx
  102495:	6b d8 00             	imul   $0x0,%eax,%ebx
  102498:	01 d9                	add    %ebx,%ecx
  10249a:	bb c0 01 00 00       	mov    $0x1c0,%ebx
  10249f:	f7 e3                	mul    %ebx
  1024a1:	01 d1                	add    %edx,%ecx
  1024a3:	89 ca                	mov    %ecx,%edx
  1024a5:	89 c1                	mov    %eax,%ecx
  1024a7:	80 e5 ff             	and    $0xff,%ch
  1024aa:	89 4d b0             	mov    %ecx,-0x50(%ebp)
  1024ad:	89 d3                	mov    %edx,%ebx
  1024af:	83 e3 0f             	and    $0xf,%ebx
  1024b2:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
  1024b5:	8b 45 b0             	mov    -0x50(%ebp),%eax
  1024b8:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  1024bb:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1024be:	c1 e0 03             	shl    $0x3,%eax
  1024c1:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1024c8:	89 d1                	mov    %edx,%ecx
  1024ca:	29 c1                	sub    %eax,%ecx
  1024cc:	89 c8                	mov    %ecx,%eax
  1024ce:	83 c0 0f             	add    $0xf,%eax
  1024d1:	83 c0 0f             	add    $0xf,%eax
  1024d4:	c1 e8 04             	shr    $0x4,%eax
  1024d7:	c1 e0 04             	shl    $0x4,%eax
  1024da:	29 c4                	sub    %eax,%esp
  1024dc:	8d 44 24 10          	lea    0x10(%esp),%eax
  1024e0:	83 c0 0f             	add    $0xf,%eax
  1024e3:	c1 e8 04             	shr    $0x4,%eax
  1024e6:	c1 e0 04             	shl    $0x4,%eax
  1024e9:	89 45 cc             	mov    %eax,-0x34(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  1024ec:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1024f3:	eb 33                	jmp    102528 <spinlock_check+0x123>
  1024f5:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1024f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1024fb:	c1 e0 03             	shl    $0x3,%eax
  1024fe:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102505:	89 cb                	mov    %ecx,%ebx
  102507:	29 c3                	sub    %eax,%ebx
  102509:	89 d8                	mov    %ebx,%eax
  10250b:	01 c2                	add    %eax,%edx
  10250d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102514:	00 
  102515:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102518:	89 44 24 04          	mov    %eax,0x4(%esp)
  10251c:	89 14 24             	mov    %edx,(%esp)
  10251f:	e8 79 fd ff ff       	call   10229d <spinlock_init_>
  102524:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102528:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10252b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10252e:	7c c5                	jl     1024f5 <spinlock_check+0xf0>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  102530:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102537:	eb 46                	jmp    10257f <spinlock_check+0x17a>
  102539:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10253c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10253f:	c1 e0 03             	shl    $0x3,%eax
  102542:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102549:	29 c2                	sub    %eax,%edx
  10254b:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  10254e:	83 c0 0c             	add    $0xc,%eax
  102551:	8b 00                	mov    (%eax),%eax
  102553:	85 c0                	test   %eax,%eax
  102555:	74 24                	je     10257b <spinlock_check+0x176>
  102557:	c7 44 24 0c 1b 62 10 	movl   $0x10621b,0xc(%esp)
  10255e:	00 
  10255f:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  102566:	00 
  102567:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  10256e:	00 
  10256f:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  102576:	e8 06 df ff ff       	call   100481 <debug_panic>
  10257b:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10257f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102582:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102585:	7c b2                	jl     102539 <spinlock_check+0x134>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  102587:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10258e:	eb 47                	jmp    1025d7 <spinlock_check+0x1d2>
  102590:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102593:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102596:	c1 e0 03             	shl    $0x3,%eax
  102599:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1025a0:	29 c2                	sub    %eax,%edx
  1025a2:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1025a5:	83 c0 04             	add    $0x4,%eax
  1025a8:	8b 00                	mov    (%eax),%eax
  1025aa:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  1025ad:	74 24                	je     1025d3 <spinlock_check+0x1ce>
  1025af:	c7 44 24 0c 2e 62 10 	movl   $0x10622e,0xc(%esp)
  1025b6:	00 
  1025b7:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  1025be:	00 
  1025bf:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  1025c6:	00 
  1025c7:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  1025ce:	e8 ae de ff ff       	call   100481 <debug_panic>
  1025d3:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1025d7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025da:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1025dd:	7c b1                	jl     102590 <spinlock_check+0x18b>

	for (run=0;run<NUMRUNS;run++) 
  1025df:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  1025e6:	e9 25 03 00 00       	jmp    102910 <spinlock_check+0x50b>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  1025eb:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1025f2:	eb 3f                	jmp    102633 <spinlock_check+0x22e>
		{
			cprintf("%d\n", i);
  1025f4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1025f7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025fb:	c7 04 24 42 62 10 00 	movl   $0x106242,(%esp)
  102602:	e8 b2 2b 00 00       	call   1051b9 <cprintf>
			spinlock_godeep(i, &locks[i]);
  102607:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10260a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10260d:	c1 e0 03             	shl    $0x3,%eax
  102610:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102617:	89 cb                	mov    %ecx,%ebx
  102619:	29 c3                	sub    %eax,%ebx
  10261b:	89 d8                	mov    %ebx,%eax
  10261d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102620:	89 44 24 04          	mov    %eax,0x4(%esp)
  102624:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102627:	89 04 24             	mov    %eax,(%esp)
  10262a:	e8 9a fd ff ff       	call   1023c9 <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  10262f:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102633:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102636:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102639:	7c b9                	jl     1025f4 <spinlock_check+0x1ef>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  10263b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102642:	eb 4b                	jmp    10268f <spinlock_check+0x28a>
			assert(locks[i].cpu == cpu_cur());
  102644:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102647:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10264a:	c1 e0 03             	shl    $0x3,%eax
  10264d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102654:	29 c2                	sub    %eax,%edx
  102656:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  102659:	83 c0 0c             	add    $0xc,%eax
  10265c:	8b 18                	mov    (%eax),%ebx
  10265e:	e8 e7 fb ff ff       	call   10224a <cpu_cur>
  102663:	39 c3                	cmp    %eax,%ebx
  102665:	74 24                	je     10268b <spinlock_check+0x286>
  102667:	c7 44 24 0c 46 62 10 	movl   $0x106246,0xc(%esp)
  10266e:	00 
  10266f:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  102676:	00 
  102677:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  10267e:	00 
  10267f:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  102686:	e8 f6 dd ff ff       	call   100481 <debug_panic>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  10268b:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10268f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102692:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102695:	7c ad                	jl     102644 <spinlock_check+0x23f>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102697:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10269e:	eb 4d                	jmp    1026ed <spinlock_check+0x2e8>
			assert(spinlock_holding(&locks[i]) != 0);
  1026a0:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1026a3:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1026a6:	c1 e0 03             	shl    $0x3,%eax
  1026a9:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  1026b0:	89 cb                	mov    %ecx,%ebx
  1026b2:	29 c3                	sub    %eax,%ebx
  1026b4:	89 d8                	mov    %ebx,%eax
  1026b6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1026b9:	89 04 24             	mov    %eax,(%esp)
  1026bc:	e8 d7 fc ff ff       	call   102398 <spinlock_holding>
  1026c1:	85 c0                	test   %eax,%eax
  1026c3:	75 24                	jne    1026e9 <spinlock_check+0x2e4>
  1026c5:	c7 44 24 0c 60 62 10 	movl   $0x106260,0xc(%esp)
  1026cc:	00 
  1026cd:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  1026d4:	00 
  1026d5:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  1026dc:	00 
  1026dd:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  1026e4:	e8 98 dd ff ff       	call   100481 <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  1026e9:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1026ed:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1026f0:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1026f3:	7c ab                	jl     1026a0 <spinlock_check+0x29b>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  1026f5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1026fc:	e9 bd 00 00 00       	jmp    1027be <spinlock_check+0x3b9>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102701:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102708:	e9 9b 00 00 00       	jmp    1027a8 <spinlock_check+0x3a3>
			{
				assert(locks[i].eips[j] >=
  10270d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102710:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  102713:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102716:	01 c0                	add    %eax,%eax
  102718:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10271f:	29 c2                	sub    %eax,%edx
  102721:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  102724:	83 c0 04             	add    $0x4,%eax
  102727:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  10272a:	b8 c9 23 10 00       	mov    $0x1023c9,%eax
  10272f:	39 c2                	cmp    %eax,%edx
  102731:	73 24                	jae    102757 <spinlock_check+0x352>
  102733:	c7 44 24 0c 84 62 10 	movl   $0x106284,0xc(%esp)
  10273a:	00 
  10273b:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  102742:	00 
  102743:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  10274a:	00 
  10274b:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  102752:	e8 2a dd ff ff       	call   100481 <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  102757:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10275a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  10275d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102760:	01 c0                	add    %eax,%eax
  102762:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102769:	29 c2                	sub    %eax,%edx
  10276b:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  10276e:	83 c0 04             	add    $0x4,%eax
  102771:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  102774:	ba c9 23 10 00       	mov    $0x1023c9,%edx
  102779:	83 c2 64             	add    $0x64,%edx
  10277c:	39 d0                	cmp    %edx,%eax
  10277e:	72 24                	jb     1027a4 <spinlock_check+0x39f>
  102780:	c7 44 24 0c b4 62 10 	movl   $0x1062b4,0xc(%esp)
  102787:	00 
  102788:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  10278f:	00 
  102790:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  102797:	00 
  102798:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  10279f:	e8 dd dc ff ff       	call   100481 <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  1027a4:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  1027a8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1027ab:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  1027ae:	7f 0a                	jg     1027ba <spinlock_check+0x3b5>
  1027b0:	83 7d dc 09          	cmpl   $0x9,-0x24(%ebp)
  1027b4:	0f 8e 53 ff ff ff    	jle    10270d <spinlock_check+0x308>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  1027ba:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1027be:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1027c1:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1027c4:	0f 8c 37 ff ff ff    	jl     102701 <spinlock_check+0x2fc>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  1027ca:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1027d1:	eb 25                	jmp    1027f8 <spinlock_check+0x3f3>
  1027d3:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1027d6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1027d9:	c1 e0 03             	shl    $0x3,%eax
  1027dc:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  1027e3:	89 cb                	mov    %ecx,%ebx
  1027e5:	29 c3                	sub    %eax,%ebx
  1027e7:	89 d8                	mov    %ebx,%eax
  1027e9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1027ec:	89 04 24             	mov    %eax,(%esp)
  1027ef:	e8 4a fb ff ff       	call   10233e <spinlock_release>
  1027f4:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1027f8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1027fb:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1027fe:	7c d3                	jl     1027d3 <spinlock_check+0x3ce>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  102800:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102807:	eb 46                	jmp    10284f <spinlock_check+0x44a>
  102809:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10280c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10280f:	c1 e0 03             	shl    $0x3,%eax
  102812:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102819:	29 c2                	sub    %eax,%edx
  10281b:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  10281e:	83 c0 0c             	add    $0xc,%eax
  102821:	8b 00                	mov    (%eax),%eax
  102823:	85 c0                	test   %eax,%eax
  102825:	74 24                	je     10284b <spinlock_check+0x446>
  102827:	c7 44 24 0c e5 62 10 	movl   $0x1062e5,0xc(%esp)
  10282e:	00 
  10282f:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  102836:	00 
  102837:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  10283e:	00 
  10283f:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  102846:	e8 36 dc ff ff       	call   100481 <debug_panic>
  10284b:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10284f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102852:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102855:	7c b2                	jl     102809 <spinlock_check+0x404>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  102857:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10285e:	eb 46                	jmp    1028a6 <spinlock_check+0x4a1>
  102860:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102863:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102866:	c1 e0 03             	shl    $0x3,%eax
  102869:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102870:	29 c2                	sub    %eax,%edx
  102872:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  102875:	83 c0 10             	add    $0x10,%eax
  102878:	8b 00                	mov    (%eax),%eax
  10287a:	85 c0                	test   %eax,%eax
  10287c:	74 24                	je     1028a2 <spinlock_check+0x49d>
  10287e:	c7 44 24 0c fa 62 10 	movl   $0x1062fa,0xc(%esp)
  102885:	00 
  102886:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  10288d:	00 
  10288e:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  102895:	00 
  102896:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  10289d:	e8 df db ff ff       	call   100481 <debug_panic>
  1028a2:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1028a6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1028a9:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1028ac:	7c b2                	jl     102860 <spinlock_check+0x45b>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  1028ae:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1028b5:	eb 4d                	jmp    102904 <spinlock_check+0x4ff>
  1028b7:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1028ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1028bd:	c1 e0 03             	shl    $0x3,%eax
  1028c0:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  1028c7:	89 cb                	mov    %ecx,%ebx
  1028c9:	29 c3                	sub    %eax,%ebx
  1028cb:	89 d8                	mov    %ebx,%eax
  1028cd:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1028d0:	89 04 24             	mov    %eax,(%esp)
  1028d3:	e8 c0 fa ff ff       	call   102398 <spinlock_holding>
  1028d8:	85 c0                	test   %eax,%eax
  1028da:	74 24                	je     102900 <spinlock_check+0x4fb>
  1028dc:	c7 44 24 0c 10 63 10 	movl   $0x106310,0xc(%esp)
  1028e3:	00 
  1028e4:	c7 44 24 08 ca 61 10 	movl   $0x1061ca,0x8(%esp)
  1028eb:	00 
  1028ec:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  1028f3:	00 
  1028f4:	c7 04 24 f4 61 10 00 	movl   $0x1061f4,(%esp)
  1028fb:	e8 81 db ff ff       	call   100481 <debug_panic>
  102900:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102904:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102907:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10290a:	7c ab                	jl     1028b7 <spinlock_check+0x4b2>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  10290c:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  102910:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102913:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  102916:	0f 8c cf fc ff ff    	jl     1025eb <spinlock_check+0x1e6>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  10291c:	c7 04 24 31 63 10 00 	movl   $0x106331,(%esp)
  102923:	e8 91 28 00 00       	call   1051b9 <cprintf>
  102928:	8b 65 c4             	mov    -0x3c(%ebp),%esp
}
  10292b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  10292e:	83 c4 00             	add    $0x0,%esp
  102931:	5b                   	pop    %ebx
  102932:	5e                   	pop    %esi
  102933:	5f                   	pop    %edi
  102934:	5d                   	pop    %ebp
  102935:	c3                   	ret    

00102936 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  102936:	55                   	push   %ebp
  102937:	89 e5                	mov    %esp,%ebp
  102939:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  10293c:	8b 55 08             	mov    0x8(%ebp),%edx
  10293f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102942:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102945:	f0 87 02             	lock xchg %eax,(%edx)
  102948:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  10294b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10294e:	c9                   	leave  
  10294f:	c3                   	ret    

00102950 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  102950:	55                   	push   %ebp
  102951:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  102953:	8b 45 08             	mov    0x8(%ebp),%eax
  102956:	8b 55 0c             	mov    0xc(%ebp),%edx
  102959:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10295c:	f0 01 10             	lock add %edx,(%eax)
}
  10295f:	5d                   	pop    %ebp
  102960:	c3                   	ret    

00102961 <pause>:
	return result;
}

static inline void
pause(void)
{
  102961:	55                   	push   %ebp
  102962:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  102964:	f3 90                	pause  
}
  102966:	5d                   	pop    %ebp
  102967:	c3                   	ret    

00102968 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102968:	55                   	push   %ebp
  102969:	89 e5                	mov    %esp,%ebp
  10296b:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10296e:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  102971:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102974:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102977:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10297a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10297f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  102982:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102985:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10298b:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102990:	74 24                	je     1029b6 <cpu_cur+0x4e>
  102992:	c7 44 24 0c 50 63 10 	movl   $0x106350,0xc(%esp)
  102999:	00 
  10299a:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  1029a1:	00 
  1029a2:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1029a9:	00 
  1029aa:	c7 04 24 7b 63 10 00 	movl   $0x10637b,(%esp)
  1029b1:	e8 cb da ff ff       	call   100481 <debug_panic>
	return c;
  1029b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1029b9:	c9                   	leave  
  1029ba:	c3                   	ret    

001029bb <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1029bb:	55                   	push   %ebp
  1029bc:	89 e5                	mov    %esp,%ebp
  1029be:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1029c1:	e8 a2 ff ff ff       	call   102968 <cpu_cur>
  1029c6:	3d 00 80 10 00       	cmp    $0x108000,%eax
  1029cb:	0f 94 c0             	sete   %al
  1029ce:	0f b6 c0             	movzbl %al,%eax
}
  1029d1:	c9                   	leave  
  1029d2:	c3                   	ret    

001029d3 <proc_print>:



void
proc_print(TYPE ty, proc* p)
{
  1029d3:	55                   	push   %ebp
  1029d4:	89 e5                	mov    %esp,%ebp
  1029d6:	53                   	push   %ebx
  1029d7:	83 ec 14             	sub    $0x14,%esp
	if(ty == ACQUIRE)
  1029da:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1029de:	75 0e                	jne    1029ee <proc_print+0x1b>
		cprintf("acquire lock ");
  1029e0:	c7 04 24 88 63 10 00 	movl   $0x106388,(%esp)
  1029e7:	e8 cd 27 00 00       	call   1051b9 <cprintf>
  1029ec:	eb 0c                	jmp    1029fa <proc_print+0x27>
	else
		cprintf("release lock ");
  1029ee:	c7 04 24 96 63 10 00 	movl   $0x106396,(%esp)
  1029f5:	e8 bf 27 00 00       	call   1051b9 <cprintf>
	if(p != NULL)
  1029fa:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1029fe:	74 2b                	je     102a2b <proc_print+0x58>
		cprintf("on cpu %d, process %d\n", cpu_cur()->id, p->num);
  102a00:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a03:	8b 58 38             	mov    0x38(%eax),%ebx
  102a06:	e8 5d ff ff ff       	call   102968 <cpu_cur>
  102a0b:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  102a12:	0f b6 c0             	movzbl %al,%eax
  102a15:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  102a19:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a1d:	c7 04 24 a4 63 10 00 	movl   $0x1063a4,(%esp)
  102a24:	e8 90 27 00 00       	call   1051b9 <cprintf>
  102a29:	eb 1f                	jmp    102a4a <proc_print+0x77>
	else
		cprintf("on cpu %d\n", cpu_cur()->id);
  102a2b:	e8 38 ff ff ff       	call   102968 <cpu_cur>
  102a30:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  102a37:	0f b6 c0             	movzbl %al,%eax
  102a3a:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a3e:	c7 04 24 bb 63 10 00 	movl   $0x1063bb,(%esp)
  102a45:	e8 6f 27 00 00       	call   1051b9 <cprintf>
}
  102a4a:	83 c4 14             	add    $0x14,%esp
  102a4d:	5b                   	pop    %ebx
  102a4e:	5d                   	pop    %ebp
  102a4f:	c3                   	ret    

00102a50 <proc_init>:



void
proc_init(void)
{
  102a50:	55                   	push   %ebp
  102a51:	89 e5                	mov    %esp,%ebp
  102a53:	83 ec 18             	sub    $0x18,%esp
	
	if (!cpu_onboot())
  102a56:	e8 60 ff ff ff       	call   1029bb <cpu_onboot>
  102a5b:	85 c0                	test   %eax,%eax
  102a5d:	74 3c                	je     102a9b <proc_init+0x4b>
		return;
	
	//cprintf("in proc_init, current cpu:%d\n", cpu_cur()->id);

	spinlock_init(&queue.lock);
  102a5f:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  102a66:	00 
  102a67:	c7 44 24 04 c6 63 10 	movl   $0x1063c6,0x4(%esp)
  102a6e:	00 
  102a6f:	c7 04 24 c0 fa 30 00 	movl   $0x30fac0,(%esp)
  102a76:	e8 22 f8 ff ff       	call   10229d <spinlock_init_>

	queue.count= 0;
  102a7b:	c7 05 f8 fa 30 00 00 	movl   $0x0,0x30faf8
  102a82:	00 00 00 
	queue.head = NULL;
  102a85:	c7 05 fc fa 30 00 00 	movl   $0x0,0x30fafc
  102a8c:	00 00 00 
	queue.tail= NULL;
  102a8f:	c7 05 00 fb 30 00 00 	movl   $0x0,0x30fb00
  102a96:	00 00 00 
  102a99:	eb 01                	jmp    102a9c <proc_init+0x4c>
void
proc_init(void)
{
	
	if (!cpu_onboot())
		return;
  102a9b:	90                   	nop
	queue.head = NULL;
	queue.tail= NULL;
	
	
	// your module initialization code here
}
  102a9c:	c9                   	leave  
  102a9d:	c3                   	ret    

00102a9e <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  102a9e:	55                   	push   %ebp
  102a9f:	89 e5                	mov    %esp,%ebp
  102aa1:	83 ec 28             	sub    $0x28,%esp

	//cprintf("in proc_alloc\n");
	
	pageinfo *pi = mem_alloc();
  102aa4:	e8 64 e0 ff ff       	call   100b0d <mem_alloc>
  102aa9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!pi)
  102aac:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  102ab0:	75 0a                	jne    102abc <proc_alloc+0x1e>
		return NULL;
  102ab2:	b8 00 00 00 00       	mov    $0x0,%eax
  102ab7:	e9 72 01 00 00       	jmp    102c2e <proc_alloc+0x190>
  102abc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102abf:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  102ac2:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
  102ac7:	83 c0 08             	add    $0x8,%eax
  102aca:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102acd:	76 15                	jbe    102ae4 <proc_alloc+0x46>
  102acf:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
  102ad4:	8b 15 a4 f3 10 00    	mov    0x10f3a4,%edx
  102ada:	c1 e2 03             	shl    $0x3,%edx
  102add:	01 d0                	add    %edx,%eax
  102adf:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102ae2:	72 24                	jb     102b08 <proc_alloc+0x6a>
  102ae4:	c7 44 24 0c d4 63 10 	movl   $0x1063d4,0xc(%esp)
  102aeb:	00 
  102aec:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  102af3:	00 
  102af4:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
  102afb:	00 
  102afc:	c7 04 24 0b 64 10 00 	movl   $0x10640b,(%esp)
  102b03:	e8 79 d9 ff ff       	call   100481 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  102b08:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
  102b0d:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  102b12:	c1 ea 0c             	shr    $0xc,%edx
  102b15:	c1 e2 03             	shl    $0x3,%edx
  102b18:	01 d0                	add    %edx,%eax
  102b1a:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b1d:	72 3b                	jb     102b5a <proc_alloc+0xbc>
  102b1f:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
  102b24:	ba 0f fb 30 00       	mov    $0x30fb0f,%edx
  102b29:	c1 ea 0c             	shr    $0xc,%edx
  102b2c:	c1 e2 03             	shl    $0x3,%edx
  102b2f:	01 d0                	add    %edx,%eax
  102b31:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102b34:	77 24                	ja     102b5a <proc_alloc+0xbc>
  102b36:	c7 44 24 0c 18 64 10 	movl   $0x106418,0xc(%esp)
  102b3d:	00 
  102b3e:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  102b45:	00 
  102b46:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102b4d:	00 
  102b4e:	c7 04 24 0b 64 10 00 	movl   $0x10640b,(%esp)
  102b55:	e8 27 d9 ff ff       	call   100481 <debug_panic>

	lockadd(&pi->refcount, 1);
  102b5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b5d:	83 c0 04             	add    $0x4,%eax
  102b60:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102b67:	00 
  102b68:	89 04 24             	mov    %eax,(%esp)
  102b6b:	e8 e0 fd ff ff       	call   102950 <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  102b70:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102b73:	a1 f8 f3 30 00       	mov    0x30f3f8,%eax
  102b78:	89 d1                	mov    %edx,%ecx
  102b7a:	29 c1                	sub    %eax,%ecx
  102b7c:	89 c8                	mov    %ecx,%eax
  102b7e:	c1 f8 03             	sar    $0x3,%eax
  102b81:	c1 e0 0c             	shl    $0xc,%eax
  102b84:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  102b87:	c7 44 24 08 a0 06 00 	movl   $0x6a0,0x8(%esp)
  102b8e:	00 
  102b8f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102b96:	00 
  102b97:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102b9a:	89 04 24             	mov    %eax,(%esp)
  102b9d:	e8 fc 27 00 00       	call   10539e <memset>

	spinlock_init(&cp->lock);
  102ba2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ba5:	c7 44 24 08 52 00 00 	movl   $0x52,0x8(%esp)
  102bac:	00 
  102bad:	c7 44 24 04 c6 63 10 	movl   $0x1063c6,0x4(%esp)
  102bb4:	00 
  102bb5:	89 04 24             	mov    %eax,(%esp)
  102bb8:	e8 e0 f6 ff ff       	call   10229d <spinlock_init_>
	cp->parent = p;
  102bbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bc0:	8b 55 08             	mov    0x8(%ebp),%edx
  102bc3:	89 50 3c             	mov    %edx,0x3c(%eax)
	cp->state = PROC_STOP;
  102bc6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bc9:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  102bd0:	00 00 00 

	cp->num = count++;
  102bd3:	a1 c0 b0 10 00       	mov    0x10b0c0,%eax
  102bd8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102bdb:	89 42 38             	mov    %eax,0x38(%edx)
  102bde:	83 c0 01             	add    $0x1,%eax
  102be1:	a3 c0 b0 10 00       	mov    %eax,0x10b0c0

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  102be6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102be9:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  102bf0:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  102bf2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102bf5:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  102bfc:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  102bfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c01:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  102c08:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  102c0a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102c0d:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  102c14:	23 00 

	//cp->sv.tf.eflags = FL_IF;

	if (p)
  102c16:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102c1a:	74 0f                	je     102c2b <proc_alloc+0x18d>
		p->child[cn] = cp;
  102c1c:	8b 55 0c             	mov    0xc(%ebp),%edx
  102c1f:	8b 45 08             	mov    0x8(%ebp),%eax
  102c22:	8d 4a 10             	lea    0x10(%edx),%ecx
  102c25:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102c28:	89 14 88             	mov    %edx,(%eax,%ecx,4)
	return cp;
  102c2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102c2e:	c9                   	leave  
  102c2f:	c3                   	ret    

00102c30 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  102c30:	55                   	push   %ebp
  102c31:	89 e5                	mov    %esp,%ebp
  102c33:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_ready not implemented");

	if(p == NULL)
  102c36:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102c3a:	75 1c                	jne    102c58 <proc_ready+0x28>
		panic("proc_ready's p is null!");
  102c3c:	c7 44 24 08 49 64 10 	movl   $0x106449,0x8(%esp)
  102c43:	00 
  102c44:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  102c4b:	00 
  102c4c:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  102c53:	e8 29 d8 ff ff       	call   100481 <debug_panic>
	
	assert(p->state != PROC_READY);
  102c58:	8b 45 08             	mov    0x8(%ebp),%eax
  102c5b:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102c61:	83 f8 01             	cmp    $0x1,%eax
  102c64:	75 24                	jne    102c8a <proc_ready+0x5a>
  102c66:	c7 44 24 0c 61 64 10 	movl   $0x106461,0xc(%esp)
  102c6d:	00 
  102c6e:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  102c75:	00 
  102c76:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
  102c7d:	00 
  102c7e:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  102c85:	e8 f7 d7 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102c8a:	8b 45 08             	mov    0x8(%ebp),%eax
  102c8d:	89 04 24             	mov    %eax,(%esp)
  102c90:	e8 3c f6 ff ff       	call   1022d1 <spinlock_acquire>
	p->state = PROC_READY;
  102c95:	8b 45 08             	mov    0x8(%ebp),%eax
  102c98:	c7 80 40 04 00 00 01 	movl   $0x1,0x440(%eax)
  102c9f:	00 00 00 

	spinlock_acquire(&queue.lock);
  102ca2:	c7 04 24 c0 fa 30 00 	movl   $0x30fac0,(%esp)
  102ca9:	e8 23 f6 ff ff       	call   1022d1 <spinlock_acquire>
	// if there is no proc in queue now
	if(queue.count == 0){
  102cae:	a1 f8 fa 30 00       	mov    0x30faf8,%eax
  102cb3:	85 c0                	test   %eax,%eax
  102cb5:	75 1f                	jne    102cd6 <proc_ready+0xa6>
		//cprintf("in ready = 0\n");
		queue.count++;
  102cb7:	a1 f8 fa 30 00       	mov    0x30faf8,%eax
  102cbc:	83 c0 01             	add    $0x1,%eax
  102cbf:	a3 f8 fa 30 00       	mov    %eax,0x30faf8
		queue.head = p;
  102cc4:	8b 45 08             	mov    0x8(%ebp),%eax
  102cc7:	a3 fc fa 30 00       	mov    %eax,0x30fafc
		queue.tail = p;
  102ccc:	8b 45 08             	mov    0x8(%ebp),%eax
  102ccf:	a3 00 fb 30 00       	mov    %eax,0x30fb00
  102cd4:	eb 24                	jmp    102cfa <proc_ready+0xca>
	}

	// insert it to the head of the queue
	else{
		//cprintf("in ready != 0\n");
		p->readynext = queue.head;
  102cd6:	8b 15 fc fa 30 00    	mov    0x30fafc,%edx
  102cdc:	8b 45 08             	mov    0x8(%ebp),%eax
  102cdf:	89 90 44 04 00 00    	mov    %edx,0x444(%eax)
		queue.head = p;
  102ce5:	8b 45 08             	mov    0x8(%ebp),%eax
  102ce8:	a3 fc fa 30 00       	mov    %eax,0x30fafc
		queue.count += 1;
  102ced:	a1 f8 fa 30 00       	mov    0x30faf8,%eax
  102cf2:	83 c0 01             	add    $0x1,%eax
  102cf5:	a3 f8 fa 30 00       	mov    %eax,0x30faf8
		//spinlock_release(&queue.lock);
		//proc_print(RELEASE, p);
		//spinlock_release(&p->lock);
	}

	spinlock_release(&p->lock);
  102cfa:	8b 45 08             	mov    0x8(%ebp),%eax
  102cfd:	89 04 24             	mov    %eax,(%esp)
  102d00:	e8 39 f6 ff ff       	call   10233e <spinlock_release>
	spinlock_release(&queue.lock);
  102d05:	c7 04 24 c0 fa 30 00 	movl   $0x30fac0,(%esp)
  102d0c:	e8 2d f6 ff ff       	call   10233e <spinlock_release>
	return;
	
}
  102d11:	c9                   	leave  
  102d12:	c3                   	ret    

00102d13 <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  102d13:	55                   	push   %ebp
  102d14:	89 e5                	mov    %esp,%ebp
  102d16:	83 ec 18             	sub    $0x18,%esp
	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102d19:	8b 45 08             	mov    0x8(%ebp),%eax
  102d1c:	89 04 24             	mov    %eax,(%esp)
  102d1f:	e8 ad f5 ff ff       	call   1022d1 <spinlock_acquire>

	switch(entry){
  102d24:	8b 45 10             	mov    0x10(%ebp),%eax
  102d27:	85 c0                	test   %eax,%eax
  102d29:	74 2c                	je     102d57 <proc_save+0x44>
  102d2b:	83 f8 01             	cmp    $0x1,%eax
  102d2e:	74 36                	je     102d66 <proc_save+0x53>
  102d30:	83 f8 ff             	cmp    $0xffffffff,%eax
  102d33:	75 53                	jne    102d88 <proc_save+0x75>
		case -1:		
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  102d35:	8b 45 08             	mov    0x8(%ebp),%eax
  102d38:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102d3e:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102d45:	00 
  102d46:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d49:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d4d:	89 14 24             	mov    %edx,(%esp)
  102d50:	e8 bd 26 00 00       	call   105412 <memmove>
			break;
  102d55:	eb 4d                	jmp    102da4 <proc_save+0x91>
		case 0:
			tf->eip = (uintptr_t)((char*)tf->eip - 2);
  102d57:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d5a:	8b 40 38             	mov    0x38(%eax),%eax
  102d5d:	8d 50 fe             	lea    -0x2(%eax),%edx
  102d60:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d63:	89 50 38             	mov    %edx,0x38(%eax)
		case 1:
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  102d66:	8b 45 08             	mov    0x8(%ebp),%eax
  102d69:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  102d6f:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  102d76:	00 
  102d77:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d7e:	89 14 24             	mov    %edx,(%esp)
  102d81:	e8 8c 26 00 00       	call   105412 <memmove>
			break;
  102d86:	eb 1c                	jmp    102da4 <proc_save+0x91>
		default:
			panic("wrong entry!\n");
  102d88:	c7 44 24 08 78 64 10 	movl   $0x106478,0x8(%esp)
  102d8f:	00 
  102d90:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
  102d97:	00 
  102d98:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  102d9f:	e8 dd d6 ff ff       	call   100481 <debug_panic>
	}

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  102da4:	8b 45 08             	mov    0x8(%ebp),%eax
  102da7:	89 04 24             	mov    %eax,(%esp)
  102daa:	e8 8f f5 ff ff       	call   10233e <spinlock_release>
}
  102daf:	c9                   	leave  
  102db0:	c3                   	ret    

00102db1 <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  102db1:	55                   	push   %ebp
  102db2:	89 e5                	mov    %esp,%ebp
  102db4:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");

	if(p == NULL || p->state != PROC_RUN)
  102db7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102dbb:	74 0e                	je     102dcb <proc_wait+0x1a>
  102dbd:	8b 45 08             	mov    0x8(%ebp),%eax
  102dc0:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102dc6:	83 f8 02             	cmp    $0x2,%eax
  102dc9:	74 1c                	je     102de7 <proc_wait+0x36>
		panic("parent proc is not running!");
  102dcb:	c7 44 24 08 86 64 10 	movl   $0x106486,0x8(%esp)
  102dd2:	00 
  102dd3:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  102dda:	00 
  102ddb:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  102de2:	e8 9a d6 ff ff       	call   100481 <debug_panic>
	if(cp == NULL)
  102de7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102deb:	75 1c                	jne    102e09 <proc_wait+0x58>
		panic("no child proc!");
  102ded:	c7 44 24 08 a2 64 10 	movl   $0x1064a2,0x8(%esp)
  102df4:	00 
  102df5:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
  102dfc:	00 
  102dfd:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  102e04:	e8 78 d6 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102e09:	8b 45 08             	mov    0x8(%ebp),%eax
  102e0c:	89 04 24             	mov    %eax,(%esp)
  102e0f:	e8 bd f4 ff ff       	call   1022d1 <spinlock_acquire>
	p->state = PROC_WAIT;
  102e14:	8b 45 08             	mov    0x8(%ebp),%eax
  102e17:	c7 80 40 04 00 00 03 	movl   $0x3,0x440(%eax)
  102e1e:	00 00 00 
	p->waitchild = cp;
  102e21:	8b 45 08             	mov    0x8(%ebp),%eax
  102e24:	8b 55 0c             	mov    0xc(%ebp),%edx
  102e27:	89 90 4c 04 00 00    	mov    %edx,0x44c(%eax)
	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  102e2d:	8b 45 08             	mov    0x8(%ebp),%eax
  102e30:	89 04 24             	mov    %eax,(%esp)
  102e33:	e8 06 f5 ff ff       	call   10233e <spinlock_release>
	
	proc_save(p, tf, 0);
  102e38:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102e3f:	00 
  102e40:	8b 45 10             	mov    0x10(%ebp),%eax
  102e43:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e47:	8b 45 08             	mov    0x8(%ebp),%eax
  102e4a:	89 04 24             	mov    %eax,(%esp)
  102e4d:	e8 c1 fe ff ff       	call   102d13 <proc_save>

	assert(cp->state != PROC_STOP);
  102e52:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e55:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102e5b:	85 c0                	test   %eax,%eax
  102e5d:	75 24                	jne    102e83 <proc_wait+0xd2>
  102e5f:	c7 44 24 0c b1 64 10 	movl   $0x1064b1,0xc(%esp)
  102e66:	00 
  102e67:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  102e6e:	00 
  102e6f:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  102e76:	00 
  102e77:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  102e7e:	e8 fe d5 ff ff       	call   100481 <debug_panic>
	
	proc_sched();
  102e83:	e8 00 00 00 00       	call   102e88 <proc_sched>

00102e88 <proc_sched>:
	
}

void gcc_noreturn
proc_sched(void)
{
  102e88:	55                   	push   %ebp
  102e89:	89 e5                	mov    %esp,%ebp
  102e8b:	53                   	push   %ebx
  102e8c:	83 ec 24             	sub    $0x24,%esp
	//panic("proc_sched not implemented");

	cprintf("cpu: %d, queue has %d elements\n", cpu_cur()->id, queue.count);
  102e8f:	8b 1d f8 fa 30 00    	mov    0x30faf8,%ebx
  102e95:	e8 ce fa ff ff       	call   102968 <cpu_cur>
  102e9a:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  102ea1:	0f b6 c0             	movzbl %al,%eax
  102ea4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  102ea8:	89 44 24 04          	mov    %eax,0x4(%esp)
  102eac:	c7 04 24 c8 64 10 00 	movl   $0x1064c8,(%esp)
  102eb3:	e8 01 23 00 00       	call   1051b9 <cprintf>
			
		// if there is no ready process in queue
		// just wait

		//proc_print(ACQUIRE, NULL);
		spinlock_acquire(&queue.lock);
  102eb8:	c7 04 24 c0 fa 30 00 	movl   $0x30fac0,(%esp)
  102ebf:	e8 0d f4 ff ff       	call   1022d1 <spinlock_acquire>

		if(queue.count != 0){
  102ec4:	a1 f8 fa 30 00       	mov    0x30faf8,%eax
  102ec9:	85 c0                	test   %eax,%eax
  102ecb:	0f 84 9a 00 00 00    	je     102f6b <proc_sched+0xe3>
			// if there is just one ready process
			if(queue.count == 1){
  102ed1:	a1 f8 fa 30 00       	mov    0x30faf8,%eax
  102ed6:	83 f8 01             	cmp    $0x1,%eax
  102ed9:	75 28                	jne    102f03 <proc_sched+0x7b>
				//cprintf("in sched queue.count == 1\n");
				run = queue.head;
  102edb:	a1 fc fa 30 00       	mov    0x30fafc,%eax
  102ee0:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.head = queue.tail = NULL;
  102ee3:	c7 05 00 fb 30 00 00 	movl   $0x0,0x30fb00
  102eea:	00 00 00 
  102eed:	a1 00 fb 30 00       	mov    0x30fb00,%eax
  102ef2:	a3 fc fa 30 00       	mov    %eax,0x30fafc
				queue.count = 0;	
  102ef7:	c7 05 f8 fa 30 00 00 	movl   $0x0,0x30faf8
  102efe:	00 00 00 
  102f01:	eb 51                	jmp    102f54 <proc_sched+0xcc>
			}
			
			// if there is more than one ready processes
			else{
				cprintf("in sched queue.count > 1\n");
  102f03:	c7 04 24 e8 64 10 00 	movl   $0x1064e8,(%esp)
  102f0a:	e8 aa 22 00 00       	call   1051b9 <cprintf>
				proc* before_tail = queue.head;
  102f0f:	a1 fc fa 30 00       	mov    0x30fafc,%eax
  102f14:	89 45 f4             	mov    %eax,-0xc(%ebp)
				while(before_tail->readynext != queue.tail){
  102f17:	eb 0c                	jmp    102f25 <proc_sched+0x9d>
					before_tail = before_tail->readynext;
  102f19:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f1c:	8b 80 44 04 00 00    	mov    0x444(%eax),%eax
  102f22:	89 45 f4             	mov    %eax,-0xc(%ebp)
			
			// if there is more than one ready processes
			else{
				cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
				while(before_tail->readynext != queue.tail){
  102f25:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f28:	8b 90 44 04 00 00    	mov    0x444(%eax),%edx
  102f2e:	a1 00 fb 30 00       	mov    0x30fb00,%eax
  102f33:	39 c2                	cmp    %eax,%edx
  102f35:	75 e2                	jne    102f19 <proc_sched+0x91>
					before_tail = before_tail->readynext;
				}	
				run = queue.tail;
  102f37:	a1 00 fb 30 00       	mov    0x30fb00,%eax
  102f3c:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.tail = before_tail;
  102f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f42:	a3 00 fb 30 00       	mov    %eax,0x30fb00
				queue.count--;				
  102f47:	a1 f8 fa 30 00       	mov    0x30faf8,%eax
  102f4c:	83 e8 01             	sub    $0x1,%eax
  102f4f:	a3 f8 fa 30 00       	mov    %eax,0x30faf8
				run = queue.head;
				queue.head = queue.head->readynext;
				queue.count--;
			}*/
			
			spinlock_release(&queue.lock);
  102f54:	c7 04 24 c0 fa 30 00 	movl   $0x30fac0,(%esp)
  102f5b:	e8 de f3 ff ff       	call   10233e <spinlock_release>
			proc_run(run);
  102f60:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102f63:	89 04 24             	mov    %eax,(%esp)
  102f66:	e8 16 00 00 00       	call   102f81 <proc_run>
		}
		else{
			//cprintf("proc_sched queue.count = 0 on cpu %d\n", cpu_cur()->id);
			pause();
  102f6b:	e8 f1 f9 ff ff       	call   102961 <pause>
		}

		//proc_print(RELEASE, NULL);
		spinlock_release(&queue.lock);
  102f70:	c7 04 24 c0 fa 30 00 	movl   $0x30fac0,(%esp)
  102f77:	e8 c2 f3 ff ff       	call   10233e <spinlock_release>
	}
  102f7c:	e9 37 ff ff ff       	jmp    102eb8 <proc_sched+0x30>

00102f81 <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  102f81:	55                   	push   %ebp
  102f82:	89 e5                	mov    %esp,%ebp
  102f84:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");

	//cprintf("proc %d is running on cpu:%d\n", p->num, cpu_cur()->id);
	
	if(p == NULL)
  102f87:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102f8b:	75 1c                	jne    102fa9 <proc_run+0x28>
		panic("proc_run's p is null!");
  102f8d:	c7 44 24 08 02 65 10 	movl   $0x106502,0x8(%esp)
  102f94:	00 
  102f95:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
  102f9c:	00 
  102f9d:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  102fa4:	e8 d8 d4 ff ff       	call   100481 <debug_panic>

	assert(p->state == PROC_READY);
  102fa9:	8b 45 08             	mov    0x8(%ebp),%eax
  102fac:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  102fb2:	83 f8 01             	cmp    $0x1,%eax
  102fb5:	74 24                	je     102fdb <proc_run+0x5a>
  102fb7:	c7 44 24 0c 18 65 10 	movl   $0x106518,0xc(%esp)
  102fbe:	00 
  102fbf:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  102fc6:	00 
  102fc7:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
  102fce:	00 
  102fcf:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  102fd6:	e8 a6 d4 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  102fdb:	8b 45 08             	mov    0x8(%ebp),%eax
  102fde:	89 04 24             	mov    %eax,(%esp)
  102fe1:	e8 eb f2 ff ff       	call   1022d1 <spinlock_acquire>

	cpu* c = cpu_cur();
  102fe6:	e8 7d f9 ff ff       	call   102968 <cpu_cur>
  102feb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->proc = p;
  102fee:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ff1:	8b 55 08             	mov    0x8(%ebp),%edx
  102ff4:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	p->state = PROC_RUN;
  102ffa:	8b 45 08             	mov    0x8(%ebp),%eax
  102ffd:	c7 80 40 04 00 00 02 	movl   $0x2,0x440(%eax)
  103004:	00 00 00 
	p->runcpu = c;
  103007:	8b 45 08             	mov    0x8(%ebp),%eax
  10300a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10300d:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  103013:	8b 45 08             	mov    0x8(%ebp),%eax
  103016:	89 04 24             	mov    %eax,(%esp)
  103019:	e8 20 f3 ff ff       	call   10233e <spinlock_release>

	cprintf("eip = %d\n", p->sv.tf.eip);
  10301e:	8b 45 08             	mov    0x8(%ebp),%eax
  103021:	8b 80 88 04 00 00    	mov    0x488(%eax),%eax
  103027:	89 44 24 04          	mov    %eax,0x4(%esp)
  10302b:	c7 04 24 2f 65 10 00 	movl   $0x10652f,(%esp)
  103032:	e8 82 21 00 00       	call   1051b9 <cprintf>
	
	trap_return(&p->sv.tf);
  103037:	8b 45 08             	mov    0x8(%ebp),%eax
  10303a:	05 50 04 00 00       	add    $0x450,%eax
  10303f:	89 04 24             	mov    %eax,(%esp)
  103042:	e8 a9 60 00 00       	call   1090f0 <trap_return>

00103047 <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  103047:	55                   	push   %ebp
  103048:	89 e5                	mov    %esp,%ebp
  10304a:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_yield not implemented");

 	cprintf("in yield\n");
  10304d:	c7 04 24 39 65 10 00 	movl   $0x106539,(%esp)
  103054:	e8 60 21 00 00       	call   1051b9 <cprintf>
	proc* cur_proc = cpu_cur()->proc;
  103059:	e8 0a f9 ff ff       	call   102968 <cpu_cur>
  10305e:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103064:	89 45 f4             	mov    %eax,-0xc(%ebp)
	proc_save(cur_proc, tf, 1);
  103067:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10306e:	00 
  10306f:	8b 45 08             	mov    0x8(%ebp),%eax
  103072:	89 44 24 04          	mov    %eax,0x4(%esp)
  103076:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103079:	89 04 24             	mov    %eax,(%esp)
  10307c:	e8 92 fc ff ff       	call   102d13 <proc_save>
	proc_ready(cur_proc);
  103081:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103084:	89 04 24             	mov    %eax,(%esp)
  103087:	e8 a4 fb ff ff       	call   102c30 <proc_ready>
	proc_sched();
  10308c:	e8 f7 fd ff ff       	call   102e88 <proc_sched>

00103091 <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  103091:	55                   	push   %ebp
  103092:	89 e5                	mov    %esp,%ebp
  103094:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_ret not implemented");

	proc* proc_child = proc_cur();
  103097:	e8 cc f8 ff ff       	call   102968 <cpu_cur>
  10309c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_parent = proc_child->parent;
  1030a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030a8:	8b 40 3c             	mov    0x3c(%eax),%eax
  1030ab:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child->state != PROC_STOP);
  1030ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030b1:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  1030b7:	85 c0                	test   %eax,%eax
  1030b9:	75 24                	jne    1030df <proc_ret+0x4e>
  1030bb:	c7 44 24 0c 44 65 10 	movl   $0x106544,0xc(%esp)
  1030c2:	00 
  1030c3:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  1030ca:	00 
  1030cb:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
  1030d2:	00 
  1030d3:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  1030da:	e8 a2 d3 ff ff       	call   100481 <debug_panic>

	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  1030df:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030e2:	89 04 24             	mov    %eax,(%esp)
  1030e5:	e8 e7 f1 ff ff       	call   1022d1 <spinlock_acquire>
	proc_child->state = PROC_STOP;
  1030ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030ed:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  1030f4:	00 00 00 
	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  1030f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1030fa:	89 04 24             	mov    %eax,(%esp)
  1030fd:	e8 3c f2 ff ff       	call   10233e <spinlock_release>

	proc_save(proc_child, tf, entry);
  103102:	8b 45 0c             	mov    0xc(%ebp),%eax
  103105:	89 44 24 08          	mov    %eax,0x8(%esp)
  103109:	8b 45 08             	mov    0x8(%ebp),%eax
  10310c:	89 44 24 04          	mov    %eax,0x4(%esp)
  103110:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103113:	89 04 24             	mov    %eax,(%esp)
  103116:	e8 f8 fb ff ff       	call   102d13 <proc_save>

	if((proc_parent->state == PROC_WAIT) && (proc_parent->waitchild == proc_child) )
  10311b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10311e:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103124:	83 f8 03             	cmp    $0x3,%eax
  103127:	75 19                	jne    103142 <proc_ret+0xb1>
  103129:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10312c:	8b 80 4c 04 00 00    	mov    0x44c(%eax),%eax
  103132:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  103135:	75 0b                	jne    103142 <proc_ret+0xb1>
		proc_ready(proc_parent);
  103137:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10313a:	89 04 24             	mov    %eax,(%esp)
  10313d:	e8 ee fa ff ff       	call   102c30 <proc_ready>

	proc_sched();
  103142:	e8 41 fd ff ff       	call   102e88 <proc_sched>

00103147 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  103147:	55                   	push   %ebp
  103148:	89 e5                	mov    %esp,%ebp
  10314a:	57                   	push   %edi
  10314b:	56                   	push   %esi
  10314c:	53                   	push   %ebx
  10314d:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  103153:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10315a:	00 00 00 
  10315d:	e9 06 01 00 00       	jmp    103268 <proc_check+0x121>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  103162:	b8 30 b3 10 00       	mov    $0x10b330,%eax
  103167:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  10316d:	83 c2 01             	add    $0x1,%edx
  103170:	c1 e2 0c             	shl    $0xc,%edx
  103173:	01 d0                	add    %edx,%eax
  103175:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		*--esp = i;	// push argument to child() function
  10317b:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  103182:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  103188:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  10318e:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  103190:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  103197:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  10319d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  1031a3:	b8 49 36 10 00       	mov    $0x103649,%eax
  1031a8:	a3 18 b1 10 00       	mov    %eax,0x10b118
		child_state.tf.esp = (uint32_t) esp;
  1031ad:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  1031b3:	a3 24 b1 10 00       	mov    %eax,0x10b124

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  1031b8:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1031be:	89 44 24 04          	mov    %eax,0x4(%esp)
  1031c2:	c7 04 24 63 65 10 00 	movl   $0x106563,(%esp)
  1031c9:	e8 eb 1f 00 00       	call   1051b9 <cprintf>

		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  1031ce:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1031d4:	0f b7 d0             	movzwl %ax,%edx
  1031d7:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  1031de:	7f 07                	jg     1031e7 <proc_check+0xa0>
  1031e0:	b8 10 10 00 00       	mov    $0x1010,%eax
  1031e5:	eb 05                	jmp    1031ec <proc_check+0xa5>
  1031e7:	b8 00 10 00 00       	mov    $0x1000,%eax
  1031ec:	89 85 54 ff ff ff    	mov    %eax,-0xac(%ebp)
  1031f2:	66 89 95 52 ff ff ff 	mov    %dx,-0xae(%ebp)
  1031f9:	c7 85 4c ff ff ff e0 	movl   $0x10b0e0,-0xb4(%ebp)
  103200:	b0 10 00 
  103203:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
  10320a:	00 00 00 
  10320d:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
  103214:	00 00 00 
  103217:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
  10321e:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103221:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
  103227:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10322a:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
  103230:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
  103237:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
  10323d:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
  103243:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
  103249:	cd 30                	int    $0x30
			NULL, NULL, 0);
		
		cprintf("i == %d complete!\n", i);
  10324b:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103251:	89 44 24 04          	mov    %eax,0x4(%esp)
  103255:	c7 04 24 76 65 10 00 	movl   $0x106576,(%esp)
  10325c:	e8 58 1f 00 00       	call   1051b9 <cprintf>
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  103261:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103268:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  10326f:	0f 8e ed fe ff ff    	jle    103162 <proc_check+0x1b>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  103275:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10327c:	00 00 00 
  10327f:	e9 89 00 00 00       	jmp    10330d <proc_check+0x1c6>
		cprintf("waiting for child %d\n", i);
  103284:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10328a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10328e:	c7 04 24 89 65 10 00 	movl   $0x106589,(%esp)
  103295:	e8 1f 1f 00 00       	call   1051b9 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10329a:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1032a0:	0f b7 c0             	movzwl %ax,%eax
  1032a3:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
  1032aa:	10 00 00 
  1032ad:	66 89 85 6a ff ff ff 	mov    %ax,-0x96(%ebp)
  1032b4:	c7 85 64 ff ff ff e0 	movl   $0x10b0e0,-0x9c(%ebp)
  1032bb:	b0 10 00 
  1032be:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
  1032c5:	00 00 00 
  1032c8:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
  1032cf:	00 00 00 
  1032d2:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
  1032d9:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1032dc:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
  1032e2:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1032e5:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
  1032eb:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
  1032f2:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
  1032f8:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
  1032fe:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
  103304:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  103306:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  10330d:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  103314:	0f 8e 6a ff ff ff    	jle    103284 <proc_check+0x13d>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  10331a:	c7 04 24 a0 65 10 00 	movl   $0x1065a0,(%esp)
  103321:	e8 93 1e 00 00       	call   1051b9 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  103326:	c7 04 24 c8 65 10 00 	movl   $0x1065c8,(%esp)
  10332d:	e8 87 1e 00 00       	call   1051b9 <cprintf>
	for (i = 0; i < 4; i++) {
  103332:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103339:	00 00 00 
  10333c:	eb 7d                	jmp    1033bb <proc_check+0x274>
		cprintf("spawning child %d\n", i);
  10333e:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103344:	89 44 24 04          	mov    %eax,0x4(%esp)
  103348:	c7 04 24 63 65 10 00 	movl   $0x106563,(%esp)
  10334f:	e8 65 1e 00 00       	call   1051b9 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  103354:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10335a:	0f b7 c0             	movzwl %ax,%eax
  10335d:	c7 45 84 10 00 00 00 	movl   $0x10,-0x7c(%ebp)
  103364:	66 89 45 82          	mov    %ax,-0x7e(%ebp)
  103368:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  10336f:	00 00 00 
  103372:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
  103379:	00 00 00 
  10337c:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
  103383:	00 00 00 
  103386:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
  10338d:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103390:	8b 45 84             	mov    -0x7c(%ebp),%eax
  103393:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103396:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
  10339c:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
  1033a0:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
  1033a6:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
  1033ac:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
  1033b2:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  1033b4:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  1033bb:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  1033c2:	0f 8e 76 ff ff ff    	jle    10333e <proc_check+0x1f7>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
  1033c8:	c7 04 24 ec 65 10 00 	movl   $0x1065ec,(%esp)
  1033cf:	e8 e5 1d 00 00       	call   1051b9 <cprintf>
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  1033d4:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  1033db:	00 00 00 
  1033de:	eb 4f                	jmp    10342f <proc_check+0x2e8>
		sys_get(0, i, NULL, NULL, NULL, 0);
  1033e0:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1033e6:	0f b7 c0             	movzwl %ax,%eax
  1033e9:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  1033f0:	66 89 45 9a          	mov    %ax,-0x66(%ebp)
  1033f4:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
  1033fb:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  103402:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
  103409:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103410:	8b 45 9c             	mov    -0x64(%ebp),%eax
  103413:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103416:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
  103419:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
  10341d:	8b 75 90             	mov    -0x70(%ebp),%esi
  103420:	8b 7d 8c             	mov    -0x74(%ebp),%edi
  103423:	8b 4d 88             	mov    -0x78(%ebp),%ecx
  103426:	cd 30                	int    $0x30
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103428:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  10342f:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103436:	7e a8                	jle    1033e0 <proc_check+0x299>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  103438:	c7 04 24 14 66 10 00 	movl   $0x106614,(%esp)
  10343f:	e8 75 1d 00 00       	call   1051b9 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  103444:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10344b:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10344e:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103454:	0f b7 c0             	movzwl %ax,%eax
  103457:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
  10345e:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
  103462:	c7 45 ac e0 b0 10 00 	movl   $0x10b0e0,-0x54(%ebp)
  103469:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  103470:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  103477:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10347e:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  103481:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103484:	8b 5d ac             	mov    -0x54(%ebp),%ebx
  103487:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
  10348b:	8b 75 a8             	mov    -0x58(%ebp),%esi
  10348e:	8b 7d a4             	mov    -0x5c(%ebp),%edi
  103491:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  103494:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  103496:	a1 34 f3 10 00       	mov    0x10f334,%eax
  10349b:	85 c0                	test   %eax,%eax
  10349d:	74 24                	je     1034c3 <proc_check+0x37c>
  10349f:	c7 44 24 0c 39 66 10 	movl   $0x106639,0xc(%esp)
  1034a6:	00 
  1034a7:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  1034ae:	00 
  1034af:	c7 44 24 04 93 01 00 	movl   $0x193,0x4(%esp)
  1034b6:	00 
  1034b7:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  1034be:	e8 be cf ff ff       	call   100481 <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  1034c3:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1034c9:	0f b7 c0             	movzwl %ax,%eax
  1034cc:	c7 45 cc 10 10 00 00 	movl   $0x1010,-0x34(%ebp)
  1034d3:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
  1034d7:	c7 45 c4 e0 b0 10 00 	movl   $0x10b0e0,-0x3c(%ebp)
  1034de:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
  1034e5:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  1034ec:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1034f3:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1034f6:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1034f9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
  1034fc:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  103500:	8b 75 c0             	mov    -0x40(%ebp),%esi
  103503:	8b 7d bc             	mov    -0x44(%ebp),%edi
  103506:	8b 4d b8             	mov    -0x48(%ebp),%ecx
  103509:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10350b:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103511:	0f b7 c0             	movzwl %ax,%eax
  103514:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  10351b:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
  10351f:	c7 45 dc e0 b0 10 00 	movl   $0x10b0e0,-0x24(%ebp)
  103526:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10352d:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  103534:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10353b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10353e:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103541:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  103544:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  103548:	8b 75 d8             	mov    -0x28(%ebp),%esi
  10354b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  10354e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  103551:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  103553:	a1 34 f3 10 00       	mov    0x10f334,%eax
  103558:	85 c0                	test   %eax,%eax
  10355a:	74 3f                	je     10359b <proc_check+0x454>
			trap_check_args *args = recovargs;
  10355c:	a1 34 f3 10 00       	mov    0x10f334,%eax
  103561:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)
			cprintf("recover from trap %d\n",
  103567:	a1 10 b1 10 00       	mov    0x10b110,%eax
  10356c:	89 44 24 04          	mov    %eax,0x4(%esp)
  103570:	c7 04 24 4b 66 10 00 	movl   $0x10664b,(%esp)
  103577:	e8 3d 1c 00 00       	call   1051b9 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  10357c:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  103582:	8b 00                	mov    (%eax),%eax
  103584:	a3 18 b1 10 00       	mov    %eax,0x10b118
			args->trapno = child_state.tf.trapno;
  103589:	a1 10 b1 10 00       	mov    0x10b110,%eax
  10358e:	89 c2                	mov    %eax,%edx
  103590:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  103596:	89 50 04             	mov    %edx,0x4(%eax)
  103599:	eb 2e                	jmp    1035c9 <proc_check+0x482>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  10359b:	a1 10 b1 10 00       	mov    0x10b110,%eax
  1035a0:	83 f8 30             	cmp    $0x30,%eax
  1035a3:	74 24                	je     1035c9 <proc_check+0x482>
  1035a5:	c7 44 24 0c 64 66 10 	movl   $0x106664,0xc(%esp)
  1035ac:	00 
  1035ad:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  1035b4:	00 
  1035b5:	c7 44 24 04 9e 01 00 	movl   $0x19e,0x4(%esp)
  1035bc:	00 
  1035bd:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  1035c4:	e8 b8 ce ff ff       	call   100481 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  1035c9:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1035cf:	8d 50 01             	lea    0x1(%eax),%edx
  1035d2:	89 d0                	mov    %edx,%eax
  1035d4:	c1 f8 1f             	sar    $0x1f,%eax
  1035d7:	c1 e8 1e             	shr    $0x1e,%eax
  1035da:	01 c2                	add    %eax,%edx
  1035dc:	83 e2 03             	and    $0x3,%edx
  1035df:	89 d1                	mov    %edx,%ecx
  1035e1:	29 c1                	sub    %eax,%ecx
  1035e3:	89 c8                	mov    %ecx,%eax
  1035e5:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  1035eb:	a1 10 b1 10 00       	mov    0x10b110,%eax
  1035f0:	83 f8 30             	cmp    $0x30,%eax
  1035f3:	0f 85 ca fe ff ff    	jne    1034c3 <proc_check+0x37c>
	assert(recovargs == NULL);
  1035f9:	a1 34 f3 10 00       	mov    0x10f334,%eax
  1035fe:	85 c0                	test   %eax,%eax
  103600:	74 24                	je     103626 <proc_check+0x4df>
  103602:	c7 44 24 0c 39 66 10 	movl   $0x106639,0xc(%esp)
  103609:	00 
  10360a:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  103611:	00 
  103612:	c7 44 24 04 a1 01 00 	movl   $0x1a1,0x4(%esp)
  103619:	00 
  10361a:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  103621:	e8 5b ce ff ff       	call   100481 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  103626:	c7 04 24 88 66 10 00 	movl   $0x106688,(%esp)
  10362d:	e8 87 1b 00 00       	call   1051b9 <cprintf>

	cprintf("proc_check() succeeded!\n");
  103632:	c7 04 24 b5 66 10 00 	movl   $0x1066b5,(%esp)
  103639:	e8 7b 1b 00 00       	call   1051b9 <cprintf>
}
  10363e:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  103644:	5b                   	pop    %ebx
  103645:	5e                   	pop    %esi
  103646:	5f                   	pop    %edi
  103647:	5d                   	pop    %ebp
  103648:	c3                   	ret    

00103649 <child>:

static void child(int n)
{
  103649:	55                   	push   %ebp
  10364a:	89 e5                	mov    %esp,%ebp
  10364c:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  10364f:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  103653:	7f 79                	jg     1036ce <child+0x85>
		int i;
		for (i = 0; i < 10; i++) {
  103655:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  10365c:	eb 63                	jmp    1036c1 <child+0x78>
			cprintf("in child %d count %d\n", n, i);
  10365e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103661:	89 44 24 08          	mov    %eax,0x8(%esp)
  103665:	8b 45 08             	mov    0x8(%ebp),%eax
  103668:	89 44 24 04          	mov    %eax,0x4(%esp)
  10366c:	c7 04 24 ce 66 10 00 	movl   $0x1066ce,(%esp)
  103673:	e8 41 1b 00 00       	call   1051b9 <cprintf>
			while (pingpong != n){
  103678:	eb 1a                	jmp    103694 <child+0x4b>
				cprintf("in pingpong = %d\n", pingpong);
  10367a:	a1 30 f3 10 00       	mov    0x10f330,%eax
  10367f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103683:	c7 04 24 e4 66 10 00 	movl   $0x1066e4,(%esp)
  10368a:	e8 2a 1b 00 00       	call   1051b9 <cprintf>
				pause();
  10368f:	e8 cd f2 ff ff       	call   102961 <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n){
  103694:	8b 55 08             	mov    0x8(%ebp),%edx
  103697:	a1 30 f3 10 00       	mov    0x10f330,%eax
  10369c:	39 c2                	cmp    %eax,%edx
  10369e:	75 da                	jne    10367a <child+0x31>
				cprintf("in pingpong = %d\n", pingpong);
				pause();
			}
			xchg(&pingpong, !pingpong);
  1036a0:	a1 30 f3 10 00       	mov    0x10f330,%eax
  1036a5:	85 c0                	test   %eax,%eax
  1036a7:	0f 94 c0             	sete   %al
  1036aa:	0f b6 c0             	movzbl %al,%eax
  1036ad:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036b1:	c7 04 24 30 f3 10 00 	movl   $0x10f330,(%esp)
  1036b8:	e8 79 f2 ff ff       	call   102936 <xchg>
{
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  1036bd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1036c1:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1036c5:	7e 97                	jle    10365e <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  1036c7:	b8 03 00 00 00       	mov    $0x3,%eax
  1036cc:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  1036ce:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1036d5:	eb 61                	jmp    103738 <child+0xef>
		cprintf("in child %d count %d\n", n, i);
  1036d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1036da:	89 44 24 08          	mov    %eax,0x8(%esp)
  1036de:	8b 45 08             	mov    0x8(%ebp),%eax
  1036e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036e5:	c7 04 24 ce 66 10 00 	movl   $0x1066ce,(%esp)
  1036ec:	e8 c8 1a 00 00       	call   1051b9 <cprintf>
		while (pingpong != n){
  1036f1:	eb 1a                	jmp    10370d <child+0xc4>
			cprintf("in pingpong = %d\n", pingpong);
  1036f3:	a1 30 f3 10 00       	mov    0x10f330,%eax
  1036f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036fc:	c7 04 24 e4 66 10 00 	movl   $0x1066e4,(%esp)
  103703:	e8 b1 1a 00 00       	call   1051b9 <cprintf>
			pause();
  103708:	e8 54 f2 ff ff       	call   102961 <pause>

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		cprintf("in child %d count %d\n", n, i);
		while (pingpong != n){
  10370d:	8b 55 08             	mov    0x8(%ebp),%edx
  103710:	a1 30 f3 10 00       	mov    0x10f330,%eax
  103715:	39 c2                	cmp    %eax,%edx
  103717:	75 da                	jne    1036f3 <child+0xaa>
			cprintf("in pingpong = %d\n", pingpong);
			pause();
		}
		xchg(&pingpong, (pingpong + 1) % 4);
  103719:	a1 30 f3 10 00       	mov    0x10f330,%eax
  10371e:	83 c0 01             	add    $0x1,%eax
  103721:	83 e0 03             	and    $0x3,%eax
  103724:	89 44 24 04          	mov    %eax,0x4(%esp)
  103728:	c7 04 24 30 f3 10 00 	movl   $0x10f330,(%esp)
  10372f:	e8 02 f2 ff ff       	call   102936 <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103734:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103738:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  10373c:	7e 99                	jle    1036d7 <child+0x8e>
  10373e:	b8 03 00 00 00       	mov    $0x3,%eax
  103743:	cd 30                	int    $0x30
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  103745:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103749:	75 6d                	jne    1037b8 <child+0x16f>
		assert(recovargs == NULL);
  10374b:	a1 34 f3 10 00       	mov    0x10f334,%eax
  103750:	85 c0                	test   %eax,%eax
  103752:	74 24                	je     103778 <child+0x12f>
  103754:	c7 44 24 0c 39 66 10 	movl   $0x106639,0xc(%esp)
  10375b:	00 
  10375c:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  103763:	00 
  103764:	c7 44 24 04 ca 01 00 	movl   $0x1ca,0x4(%esp)
  10376b:	00 
  10376c:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  103773:	e8 09 cd ff ff       	call   100481 <debug_panic>
		trap_check(&recovargs);
  103778:	c7 04 24 34 f3 10 00 	movl   $0x10f334,(%esp)
  10377f:	e8 a9 e2 ff ff       	call   101a2d <trap_check>
		assert(recovargs == NULL);
  103784:	a1 34 f3 10 00       	mov    0x10f334,%eax
  103789:	85 c0                	test   %eax,%eax
  10378b:	74 24                	je     1037b1 <child+0x168>
  10378d:	c7 44 24 0c 39 66 10 	movl   $0x106639,0xc(%esp)
  103794:	00 
  103795:	c7 44 24 08 66 63 10 	movl   $0x106366,0x8(%esp)
  10379c:	00 
  10379d:	c7 44 24 04 cc 01 00 	movl   $0x1cc,0x4(%esp)
  1037a4:	00 
  1037a5:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  1037ac:	e8 d0 cc ff ff       	call   100481 <debug_panic>
  1037b1:	b8 03 00 00 00       	mov    $0x3,%eax
  1037b6:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  1037b8:	c7 44 24 08 f8 66 10 	movl   $0x1066f8,0x8(%esp)
  1037bf:	00 
  1037c0:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
  1037c7:	00 
  1037c8:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  1037cf:	e8 ad cc ff ff       	call   100481 <debug_panic>

001037d4 <grandchild>:
}

static void grandchild(int n)
{
  1037d4:	55                   	push   %ebp
  1037d5:	89 e5                	mov    %esp,%ebp
  1037d7:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  1037da:	c7 44 24 08 1c 67 10 	movl   $0x10671c,0x8(%esp)
  1037e1:	00 
  1037e2:	c7 44 24 04 d5 01 00 	movl   $0x1d5,0x4(%esp)
  1037e9:	00 
  1037ea:	c7 04 24 c6 63 10 00 	movl   $0x1063c6,(%esp)
  1037f1:	e8 8b cc ff ff       	call   100481 <debug_panic>

001037f6 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1037f6:	55                   	push   %ebp
  1037f7:	89 e5                	mov    %esp,%ebp
  1037f9:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1037fc:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1037ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103802:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103805:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103808:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10380d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  103810:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103813:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103819:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10381e:	74 24                	je     103844 <cpu_cur+0x4e>
  103820:	c7 44 24 0c 48 67 10 	movl   $0x106748,0xc(%esp)
  103827:	00 
  103828:	c7 44 24 08 5e 67 10 	movl   $0x10675e,0x8(%esp)
  10382f:	00 
  103830:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103837:	00 
  103838:	c7 04 24 73 67 10 00 	movl   $0x106773,(%esp)
  10383f:	e8 3d cc ff ff       	call   100481 <debug_panic>
	return c;
  103844:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103847:	c9                   	leave  
  103848:	c3                   	ret    

00103849 <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  103849:	55                   	push   %ebp
  10384a:	89 e5                	mov    %esp,%ebp
  10384c:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  10384f:	c7 44 24 08 80 67 10 	movl   $0x106780,0x8(%esp)
  103856:	00 
  103857:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  10385e:	00 
  10385f:	c7 04 24 9b 67 10 00 	movl   $0x10679b,(%esp)
  103866:	e8 16 cc ff ff       	call   100481 <debug_panic>

0010386b <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  10386b:	55                   	push   %ebp
  10386c:	89 e5                	mov    %esp,%ebp
  10386e:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  103871:	c7 44 24 08 aa 67 10 	movl   $0x1067aa,0x8(%esp)
  103878:	00 
  103879:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  103880:	00 
  103881:	c7 04 24 9b 67 10 00 	movl   $0x10679b,(%esp)
  103888:	e8 f4 cb ff ff       	call   100481 <debug_panic>

0010388d <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  10388d:	55                   	push   %ebp
  10388e:	89 e5                	mov    %esp,%ebp
  103890:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  103893:	c7 44 24 08 c8 67 10 	movl   $0x1067c8,0x8(%esp)
  10389a:	00 
  10389b:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  1038a2:	00 
  1038a3:	c7 04 24 9b 67 10 00 	movl   $0x10679b,(%esp)
  1038aa:	e8 d2 cb ff ff       	call   100481 <debug_panic>

001038af <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  1038af:	55                   	push   %ebp
  1038b0:	89 e5                	mov    %esp,%ebp
  1038b2:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  1038b5:	8b 45 18             	mov    0x18(%ebp),%eax
  1038b8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1038bc:	8b 45 14             	mov    0x14(%ebp),%eax
  1038bf:	89 44 24 04          	mov    %eax,0x4(%esp)
  1038c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1038c6:	89 04 24             	mov    %eax,(%esp)
  1038c9:	e8 bf ff ff ff       	call   10388d <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  1038ce:	c7 44 24 08 e4 67 10 	movl   $0x1067e4,0x8(%esp)
  1038d5:	00 
  1038d6:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  1038dd:	00 
  1038de:	c7 04 24 9b 67 10 00 	movl   $0x10679b,(%esp)
  1038e5:	e8 97 cb ff ff       	call   100481 <debug_panic>

001038ea <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  1038ea:	55                   	push   %ebp
  1038eb:	89 e5                	mov    %esp,%ebp
  1038ed:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  1038f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1038f3:	8b 40 10             	mov    0x10(%eax),%eax
  1038f6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1038fa:	c7 04 24 08 68 10 00 	movl   $0x106808,(%esp)
  103901:	e8 b3 18 00 00       	call   1051b9 <cprintf>

	trap_return(tf);	// syscall completed
  103906:	8b 45 08             	mov    0x8(%ebp),%eax
  103909:	89 04 24             	mov    %eax,(%esp)
  10390c:	e8 df 57 00 00       	call   1090f0 <trap_return>

00103911 <do_put>:
}


static void
do_put(trapframe *tf, uint32_t cmd)
{	
  103911:	55                   	push   %ebp
  103912:	89 e5                	mov    %esp,%ebp
  103914:	83 ec 28             	sub    $0x28,%esp
	procstate* ps = (procstate*)tf->regs.ebx;
  103917:	8b 45 08             	mov    0x8(%ebp),%eax
  10391a:	8b 40 10             	mov    0x10(%eax),%eax
  10391d:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint16_t child_num = tf->regs.edx;
  103920:	8b 45 08             	mov    0x8(%ebp),%eax
  103923:	8b 40 14             	mov    0x14(%eax),%eax
  103926:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
	proc* proc_parent = proc_cur();
  10392a:	e8 c7 fe ff ff       	call   1037f6 <cpu_cur>
  10392f:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103935:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103938:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  10393c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10393f:	83 c2 10             	add    $0x10,%edx
  103942:	8b 04 90             	mov    (%eax,%edx,4),%eax
  103945:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(proc_child == NULL){
  103948:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10394c:	75 38                	jne    103986 <do_put+0x75>
		proc_child = proc_alloc(proc_parent, child_num);
  10394e:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
  103952:	89 44 24 04          	mov    %eax,0x4(%esp)
  103956:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103959:	89 04 24             	mov    %eax,(%esp)
  10395c:	e8 3d f1 ff ff       	call   102a9e <proc_alloc>
  103961:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if(proc_child == NULL)
  103964:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103968:	75 1c                	jne    103986 <do_put+0x75>
			panic("no child proc!");
  10396a:	c7 44 24 08 0b 68 10 	movl   $0x10680b,0x8(%esp)
  103971:	00 
  103972:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  103979:	00 
  10397a:	c7 04 24 9b 67 10 00 	movl   $0x10679b,(%esp)
  103981:	e8 fb ca ff ff       	call   100481 <debug_panic>
	}
	
	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  103986:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103989:	89 04 24             	mov    %eax,(%esp)
  10398c:	e8 40 e9 ff ff       	call   1022d1 <spinlock_acquire>
	if(proc_child->state != PROC_STOP){
  103991:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103994:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  10399a:	85 c0                	test   %eax,%eax
  10399c:	74 24                	je     1039c2 <do_put+0xb1>
		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  10399e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039a1:	89 04 24             	mov    %eax,(%esp)
  1039a4:	e8 95 e9 ff ff       	call   10233e <spinlock_release>
		proc_wait(proc_parent, proc_child, tf);
  1039a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1039ac:	89 44 24 08          	mov    %eax,0x8(%esp)
  1039b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1039b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039ba:	89 04 24             	mov    %eax,(%esp)
  1039bd:	e8 ef f3 ff ff       	call   102db1 <proc_wait>
	}

	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  1039c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039c5:	89 04 24             	mov    %eax,(%esp)
  1039c8:	e8 71 e9 ff ff       	call   10233e <spinlock_release>

	if(tf->regs.eax & SYS_REGS){	
  1039cd:	8b 45 08             	mov    0x8(%ebp),%eax
  1039d0:	8b 40 1c             	mov    0x1c(%eax),%eax
  1039d3:	25 00 10 00 00       	and    $0x1000,%eax
  1039d8:	85 c0                	test   %eax,%eax
  1039da:	0f 84 c9 00 00 00    	je     103aa9 <do_put+0x198>
		//proc_print(ACQUIRE, proc_child);
		spinlock_acquire(&proc_child->lock);
  1039e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039e3:	89 04 24             	mov    %eax,(%esp)
  1039e6:	e8 e6 e8 ff ff       	call   1022d1 <spinlock_acquire>
		
		if(((proc_child->sv.tf.eflags ^ ps->tf.eflags) | FL_USER) != FL_USER)
  1039eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039ee:	8b 90 90 04 00 00    	mov    0x490(%eax),%edx
  1039f4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1039f7:	8b 40 40             	mov    0x40(%eax),%eax
  1039fa:	31 d0                	xor    %edx,%eax
  1039fc:	0d d5 0c 00 00       	or     $0xcd5,%eax
  103a01:	3d d5 0c 00 00       	cmp    $0xcd5,%eax
  103a06:	74 1c                	je     103a24 <do_put+0x113>
			panic("illegal modification of eflags!");
  103a08:	c7 44 24 08 1c 68 10 	movl   $0x10681c,0x8(%esp)
  103a0f:	00 
  103a10:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  103a17:	00 
  103a18:	c7 04 24 9b 67 10 00 	movl   $0x10679b,(%esp)
  103a1f:	e8 5d ca ff ff       	call   100481 <debug_panic>

		
		proc_child->sv.tf.eip = ps->tf.eip;
  103a24:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a27:	8b 50 38             	mov    0x38(%eax),%edx
  103a2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a2d:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_child->sv.tf.esp = ps->tf.esp;
  103a33:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103a36:	8b 50 44             	mov    0x44(%eax),%edx
  103a39:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a3c:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
  103a42:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a45:	0f b7 80 8c 04 00 00 	movzwl 0x48c(%eax),%eax
		
		proc_child->sv.tf.eip = ps->tf.eip;
		proc_child->sv.tf.esp = ps->tf.esp;
		

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103a4c:	66 83 f8 1b          	cmp    $0x1b,%ax
  103a50:	75 30                	jne    103a82 <do_put+0x171>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
  103a52:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a55:	0f b7 80 7c 04 00 00 	movzwl 0x47c(%eax),%eax
		
		proc_child->sv.tf.eip = ps->tf.eip;
		proc_child->sv.tf.esp = ps->tf.esp;
		

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103a5c:	66 83 f8 23          	cmp    $0x23,%ax
  103a60:	75 20                	jne    103a82 <do_put+0x171>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103a62:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a65:	0f b7 80 78 04 00 00 	movzwl 0x478(%eax),%eax
		
		proc_child->sv.tf.eip = ps->tf.eip;
		proc_child->sv.tf.esp = ps->tf.esp;
		

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103a6c:	66 83 f8 23          	cmp    $0x23,%ax
  103a70:	75 10                	jne    103a82 <do_put+0x171>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103a72:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a75:	0f b7 80 98 04 00 00 	movzwl 0x498(%eax),%eax
		
		proc_child->sv.tf.eip = ps->tf.eip;
		proc_child->sv.tf.esp = ps->tf.esp;
		

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103a7c:	66 83 f8 23          	cmp    $0x23,%ax
  103a80:	74 1c                	je     103a9e <do_put+0x18d>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
			panic("wrong segment regs values!");
  103a82:	c7 44 24 08 3c 68 10 	movl   $0x10683c,0x8(%esp)
  103a89:	00 
  103a8a:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
  103a91:	00 
  103a92:	c7 04 24 9b 67 10 00 	movl   $0x10679b,(%esp)
  103a99:	e8 e3 c9 ff ff       	call   100481 <debug_panic>

		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  103a9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103aa1:	89 04 24             	mov    %eax,(%esp)
  103aa4:	e8 95 e8 ff ff       	call   10233e <spinlock_release>
	}
    if(tf->regs.eax & SYS_START){
  103aa9:	8b 45 08             	mov    0x8(%ebp),%eax
  103aac:	8b 40 1c             	mov    0x1c(%eax),%eax
  103aaf:	83 e0 10             	and    $0x10,%eax
  103ab2:	85 c0                	test   %eax,%eax
  103ab4:	74 17                	je     103acd <do_put+0x1bc>
		cprintf("in SYS_START\n");
  103ab6:	c7 04 24 57 68 10 00 	movl   $0x106857,(%esp)
  103abd:	e8 f7 16 00 00       	call   1051b9 <cprintf>
		proc_ready(proc_child);
  103ac2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ac5:	89 04 24             	mov    %eax,(%esp)
  103ac8:	e8 63 f1 ff ff       	call   102c30 <proc_ready>
	}
	
	trap_return(tf);
  103acd:	8b 45 08             	mov    0x8(%ebp),%eax
  103ad0:	89 04 24             	mov    %eax,(%esp)
  103ad3:	e8 18 56 00 00       	call   1090f0 <trap_return>

00103ad8 <do_get>:
}

static void
do_get(trapframe *tf, uint32_t cmd)
{	
  103ad8:	55                   	push   %ebp
  103ad9:	89 e5                	mov    %esp,%ebp
  103adb:	83 ec 28             	sub    $0x28,%esp
	cprintf("in do_get()\n");
  103ade:	c7 04 24 65 68 10 00 	movl   $0x106865,(%esp)
  103ae5:	e8 cf 16 00 00       	call   1051b9 <cprintf>
	procstate* ps = (procstate*)tf->regs.ebx;
  103aea:	8b 45 08             	mov    0x8(%ebp),%eax
  103aed:	8b 40 10             	mov    0x10(%eax),%eax
  103af0:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int child_num = (int)tf->regs.edx;
  103af3:	8b 45 08             	mov    0x8(%ebp),%eax
  103af6:	8b 40 14             	mov    0x14(%eax),%eax
  103af9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	proc* proc_parent = proc_cur();
  103afc:	e8 f5 fc ff ff       	call   1037f6 <cpu_cur>
  103b01:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103b07:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103b0a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103b0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b10:	83 c2 10             	add    $0x10,%edx
  103b13:	8b 04 90             	mov    (%eax,%edx,4),%eax
  103b16:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child != NULL);
  103b19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103b1d:	75 24                	jne    103b43 <do_get+0x6b>
  103b1f:	c7 44 24 0c 72 68 10 	movl   $0x106872,0xc(%esp)
  103b26:	00 
  103b27:	c7 44 24 08 5e 67 10 	movl   $0x10675e,0x8(%esp)
  103b2e:	00 
  103b2f:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  103b36:	00 
  103b37:	c7 04 24 9b 67 10 00 	movl   $0x10679b,(%esp)
  103b3e:	e8 3e c9 ff ff       	call   100481 <debug_panic>

	if(proc_child->state != PROC_STOP){
  103b43:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b46:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103b4c:	85 c0                	test   %eax,%eax
  103b4e:	74 25                	je     103b75 <do_get+0x9d>
		cprintf("into proc_wait\n");
  103b50:	c7 04 24 85 68 10 00 	movl   $0x106885,(%esp)
  103b57:	e8 5d 16 00 00       	call   1051b9 <cprintf>
		proc_wait(proc_parent, proc_child, tf);}
  103b5c:	8b 45 08             	mov    0x8(%ebp),%eax
  103b5f:	89 44 24 08          	mov    %eax,0x8(%esp)
  103b63:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b66:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103b6d:	89 04 24             	mov    %eax,(%esp)
  103b70:	e8 3c f2 ff ff       	call   102db1 <proc_wait>

	if(tf->regs.eax & SYS_REGS){
  103b75:	8b 45 08             	mov    0x8(%ebp),%eax
  103b78:	8b 40 1c             	mov    0x1c(%eax),%eax
  103b7b:	25 00 10 00 00       	and    $0x1000,%eax
  103b80:	85 c0                	test   %eax,%eax
  103b82:	74 20                	je     103ba4 <do_get+0xcc>
		memmove(&(ps->tf), &(proc_child->sv.tf), sizeof(trapframe));
  103b84:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b87:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  103b8d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103b90:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  103b97:	00 
  103b98:	89 54 24 04          	mov    %edx,0x4(%esp)
  103b9c:	89 04 24             	mov    %eax,(%esp)
  103b9f:	e8 6e 18 00 00       	call   105412 <memmove>
	}
	
	trap_return(tf);
  103ba4:	8b 45 08             	mov    0x8(%ebp),%eax
  103ba7:	89 04 24             	mov    %eax,(%esp)
  103baa:	e8 41 55 00 00       	call   1090f0 <trap_return>

00103baf <do_ret>:
}

static void
do_ret(trapframe *tf, uint32_t cmd)
{	
  103baf:	55                   	push   %ebp
  103bb0:	89 e5                	mov    %esp,%ebp
  103bb2:	83 ec 18             	sub    $0x18,%esp
	proc_ret(tf, 1);
  103bb5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103bbc:	00 
  103bbd:	8b 45 08             	mov    0x8(%ebp),%eax
  103bc0:	89 04 24             	mov    %eax,(%esp)
  103bc3:	e8 c9 f4 ff ff       	call   103091 <proc_ret>

00103bc8 <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  103bc8:	55                   	push   %ebp
  103bc9:	89 e5                	mov    %esp,%ebp
  103bcb:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  103bce:	8b 45 08             	mov    0x8(%ebp),%eax
  103bd1:	8b 40 1c             	mov    0x1c(%eax),%eax
  103bd4:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  103bd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103bda:	83 e0 0f             	and    $0xf,%eax
  103bdd:	83 f8 01             	cmp    $0x1,%eax
  103be0:	74 25                	je     103c07 <syscall+0x3f>
  103be2:	83 f8 01             	cmp    $0x1,%eax
  103be5:	72 0c                	jb     103bf3 <syscall+0x2b>
  103be7:	83 f8 02             	cmp    $0x2,%eax
  103bea:	74 2f                	je     103c1b <syscall+0x53>
  103bec:	83 f8 03             	cmp    $0x3,%eax
  103bef:	74 3e                	je     103c2f <syscall+0x67>
	case SYS_PUT:	 do_put(tf, cmd); break;
	case SYS_GET:	 do_get(tf, cmd); break;
	case SYS_RET:	 do_ret(tf, cmd); break;
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
  103bf1:	eb 4f                	jmp    103c42 <syscall+0x7a>
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:	 do_cputs(tf, cmd); break;
  103bf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103bf6:	89 44 24 04          	mov    %eax,0x4(%esp)
  103bfa:	8b 45 08             	mov    0x8(%ebp),%eax
  103bfd:	89 04 24             	mov    %eax,(%esp)
  103c00:	e8 e5 fc ff ff       	call   1038ea <do_cputs>
  103c05:	eb 3b                	jmp    103c42 <syscall+0x7a>
	case SYS_PUT:	 do_put(tf, cmd); break;
  103c07:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c0e:	8b 45 08             	mov    0x8(%ebp),%eax
  103c11:	89 04 24             	mov    %eax,(%esp)
  103c14:	e8 f8 fc ff ff       	call   103911 <do_put>
  103c19:	eb 27                	jmp    103c42 <syscall+0x7a>
	case SYS_GET:	 do_get(tf, cmd); break;
  103c1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c1e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c22:	8b 45 08             	mov    0x8(%ebp),%eax
  103c25:	89 04 24             	mov    %eax,(%esp)
  103c28:	e8 ab fe ff ff       	call   103ad8 <do_get>
  103c2d:	eb 13                	jmp    103c42 <syscall+0x7a>
	case SYS_RET:	 do_ret(tf, cmd); break;
  103c2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c32:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c36:	8b 45 08             	mov    0x8(%ebp),%eax
  103c39:	89 04 24             	mov    %eax,(%esp)
  103c3c:	e8 6e ff ff ff       	call   103baf <do_ret>
  103c41:	90                   	nop
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
	}
}
  103c42:	c9                   	leave  
  103c43:	c3                   	ret    

00103c44 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  103c44:	55                   	push   %ebp
  103c45:	89 e5                	mov    %esp,%ebp
  103c47:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  103c4a:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  103c51:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103c54:	0f b7 00             	movzwl (%eax),%eax
  103c57:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  103c5b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103c5e:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  103c63:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103c66:	0f b7 00             	movzwl (%eax),%eax
  103c69:	66 3d 5a a5          	cmp    $0xa55a,%ax
  103c6d:	74 13                	je     103c82 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  103c6f:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  103c76:	c7 05 38 f3 10 00 b4 	movl   $0x3b4,0x10f338
  103c7d:	03 00 00 
  103c80:	eb 14                	jmp    103c96 <video_init+0x52>
	} else {
		*cp = was;
  103c82:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103c85:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  103c89:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  103c8c:	c7 05 38 f3 10 00 d4 	movl   $0x3d4,0x10f338
  103c93:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  103c96:	a1 38 f3 10 00       	mov    0x10f338,%eax
  103c9b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  103c9e:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103ca2:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  103ca6:	8b 55 e8             	mov    -0x18(%ebp),%edx
  103ca9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  103caa:	a1 38 f3 10 00       	mov    0x10f338,%eax
  103caf:	83 c0 01             	add    $0x1,%eax
  103cb2:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103cb5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103cb8:	89 c2                	mov    %eax,%edx
  103cba:	ec                   	in     (%dx),%al
  103cbb:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  103cbe:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  103cc2:	0f b6 c0             	movzbl %al,%eax
  103cc5:	c1 e0 08             	shl    $0x8,%eax
  103cc8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  103ccb:	a1 38 f3 10 00       	mov    0x10f338,%eax
  103cd0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  103cd3:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103cd7:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103cdb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103cde:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  103cdf:	a1 38 f3 10 00       	mov    0x10f338,%eax
  103ce4:	83 c0 01             	add    $0x1,%eax
  103ce7:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103cea:	8b 45 f8             	mov    -0x8(%ebp),%eax
  103ced:	89 c2                	mov    %eax,%edx
  103cef:	ec                   	in     (%dx),%al
  103cf0:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  103cf3:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  103cf7:	0f b6 c0             	movzbl %al,%eax
  103cfa:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  103cfd:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103d00:	a3 3c f3 10 00       	mov    %eax,0x10f33c
	crt_pos = pos;
  103d05:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103d08:	66 a3 40 f3 10 00    	mov    %ax,0x10f340
}
  103d0e:	c9                   	leave  
  103d0f:	c3                   	ret    

00103d10 <video_putc>:



void
video_putc(int c)
{
  103d10:	55                   	push   %ebp
  103d11:	89 e5                	mov    %esp,%ebp
  103d13:	53                   	push   %ebx
  103d14:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  103d17:	8b 45 08             	mov    0x8(%ebp),%eax
  103d1a:	b0 00                	mov    $0x0,%al
  103d1c:	85 c0                	test   %eax,%eax
  103d1e:	75 07                	jne    103d27 <video_putc+0x17>
		c |= 0x0700;
  103d20:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  103d27:	8b 45 08             	mov    0x8(%ebp),%eax
  103d2a:	25 ff 00 00 00       	and    $0xff,%eax
  103d2f:	83 f8 09             	cmp    $0x9,%eax
  103d32:	0f 84 ae 00 00 00    	je     103de6 <video_putc+0xd6>
  103d38:	83 f8 09             	cmp    $0x9,%eax
  103d3b:	7f 0a                	jg     103d47 <video_putc+0x37>
  103d3d:	83 f8 08             	cmp    $0x8,%eax
  103d40:	74 14                	je     103d56 <video_putc+0x46>
  103d42:	e9 dd 00 00 00       	jmp    103e24 <video_putc+0x114>
  103d47:	83 f8 0a             	cmp    $0xa,%eax
  103d4a:	74 4e                	je     103d9a <video_putc+0x8a>
  103d4c:	83 f8 0d             	cmp    $0xd,%eax
  103d4f:	74 59                	je     103daa <video_putc+0x9a>
  103d51:	e9 ce 00 00 00       	jmp    103e24 <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  103d56:	0f b7 05 40 f3 10 00 	movzwl 0x10f340,%eax
  103d5d:	66 85 c0             	test   %ax,%ax
  103d60:	0f 84 e4 00 00 00    	je     103e4a <video_putc+0x13a>
			crt_pos--;
  103d66:	0f b7 05 40 f3 10 00 	movzwl 0x10f340,%eax
  103d6d:	83 e8 01             	sub    $0x1,%eax
  103d70:	66 a3 40 f3 10 00    	mov    %ax,0x10f340
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  103d76:	a1 3c f3 10 00       	mov    0x10f33c,%eax
  103d7b:	0f b7 15 40 f3 10 00 	movzwl 0x10f340,%edx
  103d82:	0f b7 d2             	movzwl %dx,%edx
  103d85:	01 d2                	add    %edx,%edx
  103d87:	8d 14 10             	lea    (%eax,%edx,1),%edx
  103d8a:	8b 45 08             	mov    0x8(%ebp),%eax
  103d8d:	b0 00                	mov    $0x0,%al
  103d8f:	83 c8 20             	or     $0x20,%eax
  103d92:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  103d95:	e9 b1 00 00 00       	jmp    103e4b <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  103d9a:	0f b7 05 40 f3 10 00 	movzwl 0x10f340,%eax
  103da1:	83 c0 50             	add    $0x50,%eax
  103da4:	66 a3 40 f3 10 00    	mov    %ax,0x10f340
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  103daa:	0f b7 1d 40 f3 10 00 	movzwl 0x10f340,%ebx
  103db1:	0f b7 0d 40 f3 10 00 	movzwl 0x10f340,%ecx
  103db8:	0f b7 c1             	movzwl %cx,%eax
  103dbb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  103dc1:	c1 e8 10             	shr    $0x10,%eax
  103dc4:	89 c2                	mov    %eax,%edx
  103dc6:	66 c1 ea 06          	shr    $0x6,%dx
  103dca:	89 d0                	mov    %edx,%eax
  103dcc:	c1 e0 02             	shl    $0x2,%eax
  103dcf:	01 d0                	add    %edx,%eax
  103dd1:	c1 e0 04             	shl    $0x4,%eax
  103dd4:	89 ca                	mov    %ecx,%edx
  103dd6:	66 29 c2             	sub    %ax,%dx
  103dd9:	89 d8                	mov    %ebx,%eax
  103ddb:	66 29 d0             	sub    %dx,%ax
  103dde:	66 a3 40 f3 10 00    	mov    %ax,0x10f340
		break;
  103de4:	eb 65                	jmp    103e4b <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  103de6:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103ded:	e8 1e ff ff ff       	call   103d10 <video_putc>
		video_putc(' ');
  103df2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103df9:	e8 12 ff ff ff       	call   103d10 <video_putc>
		video_putc(' ');
  103dfe:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103e05:	e8 06 ff ff ff       	call   103d10 <video_putc>
		video_putc(' ');
  103e0a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103e11:	e8 fa fe ff ff       	call   103d10 <video_putc>
		video_putc(' ');
  103e16:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  103e1d:	e8 ee fe ff ff       	call   103d10 <video_putc>
		break;
  103e22:	eb 27                	jmp    103e4b <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  103e24:	8b 15 3c f3 10 00    	mov    0x10f33c,%edx
  103e2a:	0f b7 05 40 f3 10 00 	movzwl 0x10f340,%eax
  103e31:	0f b7 c8             	movzwl %ax,%ecx
  103e34:	01 c9                	add    %ecx,%ecx
  103e36:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  103e39:	8b 55 08             	mov    0x8(%ebp),%edx
  103e3c:	66 89 11             	mov    %dx,(%ecx)
  103e3f:	83 c0 01             	add    $0x1,%eax
  103e42:	66 a3 40 f3 10 00    	mov    %ax,0x10f340
  103e48:	eb 01                	jmp    103e4b <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  103e4a:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  103e4b:	0f b7 05 40 f3 10 00 	movzwl 0x10f340,%eax
  103e52:	66 3d cf 07          	cmp    $0x7cf,%ax
  103e56:	76 5b                	jbe    103eb3 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  103e58:	a1 3c f3 10 00       	mov    0x10f33c,%eax
  103e5d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  103e63:	a1 3c f3 10 00       	mov    0x10f33c,%eax
  103e68:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  103e6f:	00 
  103e70:	89 54 24 04          	mov    %edx,0x4(%esp)
  103e74:	89 04 24             	mov    %eax,(%esp)
  103e77:	e8 96 15 00 00       	call   105412 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103e7c:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  103e83:	eb 15                	jmp    103e9a <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  103e85:	a1 3c f3 10 00       	mov    0x10f33c,%eax
  103e8a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  103e8d:	01 d2                	add    %edx,%edx
  103e8f:	01 d0                	add    %edx,%eax
  103e91:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  103e96:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  103e9a:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  103ea1:	7e e2                	jle    103e85 <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  103ea3:	0f b7 05 40 f3 10 00 	movzwl 0x10f340,%eax
  103eaa:	83 e8 50             	sub    $0x50,%eax
  103ead:	66 a3 40 f3 10 00    	mov    %ax,0x10f340
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  103eb3:	a1 38 f3 10 00       	mov    0x10f338,%eax
  103eb8:	89 45 dc             	mov    %eax,-0x24(%ebp)
  103ebb:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103ebf:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  103ec3:	8b 55 dc             	mov    -0x24(%ebp),%edx
  103ec6:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  103ec7:	0f b7 05 40 f3 10 00 	movzwl 0x10f340,%eax
  103ece:	66 c1 e8 08          	shr    $0x8,%ax
  103ed2:	0f b6 c0             	movzbl %al,%eax
  103ed5:	8b 15 38 f3 10 00    	mov    0x10f338,%edx
  103edb:	83 c2 01             	add    $0x1,%edx
  103ede:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  103ee1:	88 45 e3             	mov    %al,-0x1d(%ebp)
  103ee4:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103ee8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103eeb:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  103eec:	a1 38 f3 10 00       	mov    0x10f338,%eax
  103ef1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  103ef4:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  103ef8:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  103efc:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103eff:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  103f00:	0f b7 05 40 f3 10 00 	movzwl 0x10f340,%eax
  103f07:	0f b6 c0             	movzbl %al,%eax
  103f0a:	8b 15 38 f3 10 00    	mov    0x10f338,%edx
  103f10:	83 c2 01             	add    $0x1,%edx
  103f13:	89 55 f4             	mov    %edx,-0xc(%ebp)
  103f16:	88 45 f3             	mov    %al,-0xd(%ebp)
  103f19:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  103f1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103f20:	ee                   	out    %al,(%dx)
}
  103f21:	83 c4 44             	add    $0x44,%esp
  103f24:	5b                   	pop    %ebx
  103f25:	5d                   	pop    %ebp
  103f26:	c3                   	ret    

00103f27 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  103f27:	55                   	push   %ebp
  103f28:	89 e5                	mov    %esp,%ebp
  103f2a:	83 ec 38             	sub    $0x38,%esp
  103f2d:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103f34:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103f37:	89 c2                	mov    %eax,%edx
  103f39:	ec                   	in     (%dx),%al
  103f3a:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  103f3d:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  103f41:	0f b6 c0             	movzbl %al,%eax
  103f44:	83 e0 01             	and    $0x1,%eax
  103f47:	85 c0                	test   %eax,%eax
  103f49:	75 0a                	jne    103f55 <kbd_proc_data+0x2e>
		return -1;
  103f4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  103f50:	e9 5a 01 00 00       	jmp    1040af <kbd_proc_data+0x188>
  103f55:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  103f5c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103f5f:	89 c2                	mov    %eax,%edx
  103f61:	ec                   	in     (%dx),%al
  103f62:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  103f65:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  103f69:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  103f6c:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  103f70:	75 17                	jne    103f89 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  103f72:	a1 44 f3 10 00       	mov    0x10f344,%eax
  103f77:	83 c8 40             	or     $0x40,%eax
  103f7a:	a3 44 f3 10 00       	mov    %eax,0x10f344
		return 0;
  103f7f:	b8 00 00 00 00       	mov    $0x0,%eax
  103f84:	e9 26 01 00 00       	jmp    1040af <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  103f89:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103f8d:	84 c0                	test   %al,%al
  103f8f:	79 47                	jns    103fd8 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  103f91:	a1 44 f3 10 00       	mov    0x10f344,%eax
  103f96:	83 e0 40             	and    $0x40,%eax
  103f99:	85 c0                	test   %eax,%eax
  103f9b:	75 09                	jne    103fa6 <kbd_proc_data+0x7f>
  103f9d:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103fa1:	83 e0 7f             	and    $0x7f,%eax
  103fa4:	eb 04                	jmp    103faa <kbd_proc_data+0x83>
  103fa6:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103faa:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  103fad:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103fb1:	0f b6 80 20 91 10 00 	movzbl 0x109120(%eax),%eax
  103fb8:	83 c8 40             	or     $0x40,%eax
  103fbb:	0f b6 c0             	movzbl %al,%eax
  103fbe:	f7 d0                	not    %eax
  103fc0:	89 c2                	mov    %eax,%edx
  103fc2:	a1 44 f3 10 00       	mov    0x10f344,%eax
  103fc7:	21 d0                	and    %edx,%eax
  103fc9:	a3 44 f3 10 00       	mov    %eax,0x10f344
		return 0;
  103fce:	b8 00 00 00 00       	mov    $0x0,%eax
  103fd3:	e9 d7 00 00 00       	jmp    1040af <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  103fd8:	a1 44 f3 10 00       	mov    0x10f344,%eax
  103fdd:	83 e0 40             	and    $0x40,%eax
  103fe0:	85 c0                	test   %eax,%eax
  103fe2:	74 11                	je     103ff5 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  103fe4:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  103fe8:	a1 44 f3 10 00       	mov    0x10f344,%eax
  103fed:	83 e0 bf             	and    $0xffffffbf,%eax
  103ff0:	a3 44 f3 10 00       	mov    %eax,0x10f344
	}

	shift |= shiftcode[data];
  103ff5:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  103ff9:	0f b6 80 20 91 10 00 	movzbl 0x109120(%eax),%eax
  104000:	0f b6 d0             	movzbl %al,%edx
  104003:	a1 44 f3 10 00       	mov    0x10f344,%eax
  104008:	09 d0                	or     %edx,%eax
  10400a:	a3 44 f3 10 00       	mov    %eax,0x10f344
	shift ^= togglecode[data];
  10400f:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  104013:	0f b6 80 20 92 10 00 	movzbl 0x109220(%eax),%eax
  10401a:	0f b6 d0             	movzbl %al,%edx
  10401d:	a1 44 f3 10 00       	mov    0x10f344,%eax
  104022:	31 d0                	xor    %edx,%eax
  104024:	a3 44 f3 10 00       	mov    %eax,0x10f344

	c = charcode[shift & (CTL | SHIFT)][data];
  104029:	a1 44 f3 10 00       	mov    0x10f344,%eax
  10402e:	83 e0 03             	and    $0x3,%eax
  104031:	8b 14 85 20 96 10 00 	mov    0x109620(,%eax,4),%edx
  104038:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10403c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10403f:	0f b6 00             	movzbl (%eax),%eax
  104042:	0f b6 c0             	movzbl %al,%eax
  104045:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  104048:	a1 44 f3 10 00       	mov    0x10f344,%eax
  10404d:	83 e0 08             	and    $0x8,%eax
  104050:	85 c0                	test   %eax,%eax
  104052:	74 22                	je     104076 <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  104054:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  104058:	7e 0c                	jle    104066 <kbd_proc_data+0x13f>
  10405a:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  10405e:	7f 06                	jg     104066 <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  104060:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  104064:	eb 10                	jmp    104076 <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  104066:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  10406a:	7e 0a                	jle    104076 <kbd_proc_data+0x14f>
  10406c:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  104070:	7f 04                	jg     104076 <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  104072:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  104076:	a1 44 f3 10 00       	mov    0x10f344,%eax
  10407b:	f7 d0                	not    %eax
  10407d:	83 e0 06             	and    $0x6,%eax
  104080:	85 c0                	test   %eax,%eax
  104082:	75 28                	jne    1040ac <kbd_proc_data+0x185>
  104084:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  10408b:	75 1f                	jne    1040ac <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  10408d:	c7 04 24 95 68 10 00 	movl   $0x106895,(%esp)
  104094:	e8 20 11 00 00       	call   1051b9 <cprintf>
  104099:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  1040a0:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1040a4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1040a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1040ab:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  1040ac:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  1040af:	c9                   	leave  
  1040b0:	c3                   	ret    

001040b1 <kbd_intr>:

void
kbd_intr(void)
{
  1040b1:	55                   	push   %ebp
  1040b2:	89 e5                	mov    %esp,%ebp
  1040b4:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  1040b7:	c7 04 24 27 3f 10 00 	movl   $0x103f27,(%esp)
  1040be:	e8 f3 c1 ff ff       	call   1002b6 <cons_intr>
}
  1040c3:	c9                   	leave  
  1040c4:	c3                   	ret    

001040c5 <kbd_init>:

void
kbd_init(void)
{
  1040c5:	55                   	push   %ebp
  1040c6:	89 e5                	mov    %esp,%ebp
}
  1040c8:	5d                   	pop    %ebp
  1040c9:	c3                   	ret    

001040ca <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  1040ca:	55                   	push   %ebp
  1040cb:	89 e5                	mov    %esp,%ebp
  1040cd:	83 ec 20             	sub    $0x20,%esp
  1040d0:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1040d7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1040da:	89 c2                	mov    %eax,%edx
  1040dc:	ec                   	in     (%dx),%al
  1040dd:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  1040e0:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1040e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1040ea:	89 c2                	mov    %eax,%edx
  1040ec:	ec                   	in     (%dx),%al
  1040ed:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  1040f0:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1040f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1040fa:	89 c2                	mov    %eax,%edx
  1040fc:	ec                   	in     (%dx),%al
  1040fd:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  104100:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  104107:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10410a:	89 c2                	mov    %eax,%edx
  10410c:	ec                   	in     (%dx),%al
  10410d:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  104110:	c9                   	leave  
  104111:	c3                   	ret    

00104112 <serial_proc_data>:

static int
serial_proc_data(void)
{
  104112:	55                   	push   %ebp
  104113:	89 e5                	mov    %esp,%ebp
  104115:	83 ec 10             	sub    $0x10,%esp
  104118:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  10411f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104122:	89 c2                	mov    %eax,%edx
  104124:	ec                   	in     (%dx),%al
  104125:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  104128:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  10412c:	0f b6 c0             	movzbl %al,%eax
  10412f:	83 e0 01             	and    $0x1,%eax
  104132:	85 c0                	test   %eax,%eax
  104134:	75 07                	jne    10413d <serial_proc_data+0x2b>
		return -1;
  104136:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10413b:	eb 17                	jmp    104154 <serial_proc_data+0x42>
  10413d:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  104144:	8b 45 f8             	mov    -0x8(%ebp),%eax
  104147:	89 c2                	mov    %eax,%edx
  104149:	ec                   	in     (%dx),%al
  10414a:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  10414d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  104151:	0f b6 c0             	movzbl %al,%eax
}
  104154:	c9                   	leave  
  104155:	c3                   	ret    

00104156 <serial_intr>:

void
serial_intr(void)
{
  104156:	55                   	push   %ebp
  104157:	89 e5                	mov    %esp,%ebp
  104159:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  10415c:	a1 08 fb 30 00       	mov    0x30fb08,%eax
  104161:	85 c0                	test   %eax,%eax
  104163:	74 0c                	je     104171 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  104165:	c7 04 24 12 41 10 00 	movl   $0x104112,(%esp)
  10416c:	e8 45 c1 ff ff       	call   1002b6 <cons_intr>
}
  104171:	c9                   	leave  
  104172:	c3                   	ret    

00104173 <serial_putc>:

void
serial_putc(int c)
{
  104173:	55                   	push   %ebp
  104174:	89 e5                	mov    %esp,%ebp
  104176:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  104179:	a1 08 fb 30 00       	mov    0x30fb08,%eax
  10417e:	85 c0                	test   %eax,%eax
  104180:	74 53                	je     1041d5 <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  104182:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  104189:	eb 09                	jmp    104194 <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  10418b:	e8 3a ff ff ff       	call   1040ca <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  104190:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  104194:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10419b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10419e:	89 c2                	mov    %eax,%edx
  1041a0:	ec                   	in     (%dx),%al
  1041a1:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  1041a4:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  1041a8:	0f b6 c0             	movzbl %al,%eax
  1041ab:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  1041ae:	85 c0                	test   %eax,%eax
  1041b0:	75 09                	jne    1041bb <serial_putc+0x48>
  1041b2:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  1041b9:	7e d0                	jle    10418b <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  1041bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1041be:	0f b6 c0             	movzbl %al,%eax
  1041c1:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  1041c8:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1041cb:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1041cf:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1041d2:	ee                   	out    %al,(%dx)
  1041d3:	eb 01                	jmp    1041d6 <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  1041d5:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  1041d6:	c9                   	leave  
  1041d7:	c3                   	ret    

001041d8 <serial_init>:

void
serial_init(void)
{
  1041d8:	55                   	push   %ebp
  1041d9:	89 e5                	mov    %esp,%ebp
  1041db:	83 ec 50             	sub    $0x50,%esp
  1041de:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  1041e5:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  1041e9:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  1041ed:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  1041f0:	ee                   	out    %al,(%dx)
  1041f1:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  1041f8:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  1041fc:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  104200:	8b 55 bc             	mov    -0x44(%ebp),%edx
  104203:	ee                   	out    %al,(%dx)
  104204:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  10420b:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  10420f:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  104213:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104216:	ee                   	out    %al,(%dx)
  104217:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  10421e:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  104222:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  104226:	8b 55 cc             	mov    -0x34(%ebp),%edx
  104229:	ee                   	out    %al,(%dx)
  10422a:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  104231:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  104235:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  104239:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10423c:	ee                   	out    %al,(%dx)
  10423d:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  104244:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  104248:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  10424c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10424f:	ee                   	out    %al,(%dx)
  104250:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  104257:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  10425b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10425f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  104262:	ee                   	out    %al,(%dx)
  104263:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10426a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10426d:	89 c2                	mov    %eax,%edx
  10426f:	ec                   	in     (%dx),%al
  104270:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  104273:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  104277:	3c ff                	cmp    $0xff,%al
  104279:	0f 95 c0             	setne  %al
  10427c:	0f b6 c0             	movzbl %al,%eax
  10427f:	a3 08 fb 30 00       	mov    %eax,0x30fb08
  104284:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10428b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10428e:	89 c2                	mov    %eax,%edx
  104290:	ec                   	in     (%dx),%al
  104291:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  104294:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10429b:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10429e:	89 c2                	mov    %eax,%edx
  1042a0:	ec                   	in     (%dx),%al
  1042a1:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  1042a4:	c9                   	leave  
  1042a5:	c3                   	ret    

001042a6 <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  1042a6:	55                   	push   %ebp
  1042a7:	89 e5                	mov    %esp,%ebp
  1042a9:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  1042af:	a1 48 f3 10 00       	mov    0x10f348,%eax
  1042b4:	85 c0                	test   %eax,%eax
  1042b6:	0f 85 35 01 00 00    	jne    1043f1 <pic_init+0x14b>
		return;
	didinit = 1;
  1042bc:	c7 05 48 f3 10 00 01 	movl   $0x1,0x10f348
  1042c3:	00 00 00 
  1042c6:	c7 45 8c 21 00 00 00 	movl   $0x21,-0x74(%ebp)
  1042cd:	c6 45 8b ff          	movb   $0xff,-0x75(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1042d1:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  1042d5:	8b 55 8c             	mov    -0x74(%ebp),%edx
  1042d8:	ee                   	out    %al,(%dx)
  1042d9:	c7 45 94 a1 00 00 00 	movl   $0xa1,-0x6c(%ebp)
  1042e0:	c6 45 93 ff          	movb   $0xff,-0x6d(%ebp)
  1042e4:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  1042e8:	8b 55 94             	mov    -0x6c(%ebp),%edx
  1042eb:	ee                   	out    %al,(%dx)
  1042ec:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  1042f3:	c6 45 9b 11          	movb   $0x11,-0x65(%ebp)
  1042f7:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  1042fb:	8b 55 9c             	mov    -0x64(%ebp),%edx
  1042fe:	ee                   	out    %al,(%dx)
  1042ff:	c7 45 a4 21 00 00 00 	movl   $0x21,-0x5c(%ebp)
  104306:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
  10430a:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  10430e:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  104311:	ee                   	out    %al,(%dx)
  104312:	c7 45 ac 21 00 00 00 	movl   $0x21,-0x54(%ebp)
  104319:	c6 45 ab 04          	movb   $0x4,-0x55(%ebp)
  10431d:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  104321:	8b 55 ac             	mov    -0x54(%ebp),%edx
  104324:	ee                   	out    %al,(%dx)
  104325:	c7 45 b4 21 00 00 00 	movl   $0x21,-0x4c(%ebp)
  10432c:	c6 45 b3 03          	movb   $0x3,-0x4d(%ebp)
  104330:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  104334:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  104337:	ee                   	out    %al,(%dx)
  104338:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
  10433f:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
  104343:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  104347:	8b 55 bc             	mov    -0x44(%ebp),%edx
  10434a:	ee                   	out    %al,(%dx)
  10434b:	c7 45 c4 a1 00 00 00 	movl   $0xa1,-0x3c(%ebp)
  104352:	c6 45 c3 28          	movb   $0x28,-0x3d(%ebp)
  104356:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  10435a:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  10435d:	ee                   	out    %al,(%dx)
  10435e:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
  104365:	c6 45 cb 02          	movb   $0x2,-0x35(%ebp)
  104369:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  10436d:	8b 55 cc             	mov    -0x34(%ebp),%edx
  104370:	ee                   	out    %al,(%dx)
  104371:	c7 45 d4 a1 00 00 00 	movl   $0xa1,-0x2c(%ebp)
  104378:	c6 45 d3 01          	movb   $0x1,-0x2d(%ebp)
  10437c:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  104380:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  104383:	ee                   	out    %al,(%dx)
  104384:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
  10438b:	c6 45 db 68          	movb   $0x68,-0x25(%ebp)
  10438f:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  104393:	8b 55 dc             	mov    -0x24(%ebp),%edx
  104396:	ee                   	out    %al,(%dx)
  104397:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  10439e:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  1043a2:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1043a6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1043a9:	ee                   	out    %al,(%dx)
  1043aa:	c7 45 ec a0 00 00 00 	movl   $0xa0,-0x14(%ebp)
  1043b1:	c6 45 eb 68          	movb   $0x68,-0x15(%ebp)
  1043b5:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1043b9:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1043bc:	ee                   	out    %al,(%dx)
  1043bd:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
  1043c4:	c6 45 f3 0a          	movb   $0xa,-0xd(%ebp)
  1043c8:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1043cc:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1043cf:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  1043d0:	0f b7 05 30 96 10 00 	movzwl 0x109630,%eax
  1043d7:	66 83 f8 ff          	cmp    $0xffff,%ax
  1043db:	74 15                	je     1043f2 <pic_init+0x14c>
		pic_setmask(irqmask);
  1043dd:	0f b7 05 30 96 10 00 	movzwl 0x109630,%eax
  1043e4:	0f b7 c0             	movzwl %ax,%eax
  1043e7:	89 04 24             	mov    %eax,(%esp)
  1043ea:	e8 05 00 00 00       	call   1043f4 <pic_setmask>
  1043ef:	eb 01                	jmp    1043f2 <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  1043f1:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  1043f2:	c9                   	leave  
  1043f3:	c3                   	ret    

001043f4 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  1043f4:	55                   	push   %ebp
  1043f5:	89 e5                	mov    %esp,%ebp
  1043f7:	83 ec 14             	sub    $0x14,%esp
  1043fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1043fd:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  104401:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  104405:	66 a3 30 96 10 00    	mov    %ax,0x109630
	outb(IO_PIC1+1, (char)mask);
  10440b:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  10440f:	0f b6 c0             	movzbl %al,%eax
  104412:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  104419:	88 45 f3             	mov    %al,-0xd(%ebp)
  10441c:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104420:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104423:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  104424:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  104428:	66 c1 e8 08          	shr    $0x8,%ax
  10442c:	0f b6 c0             	movzbl %al,%eax
  10442f:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
  104436:	88 45 fb             	mov    %al,-0x5(%ebp)
  104439:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  10443d:	8b 55 fc             	mov    -0x4(%ebp),%edx
  104440:	ee                   	out    %al,(%dx)
}
  104441:	c9                   	leave  
  104442:	c3                   	ret    

00104443 <pic_enable>:

void
pic_enable(int irq)
{
  104443:	55                   	push   %ebp
  104444:	89 e5                	mov    %esp,%ebp
  104446:	53                   	push   %ebx
  104447:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  10444a:	8b 45 08             	mov    0x8(%ebp),%eax
  10444d:	ba 01 00 00 00       	mov    $0x1,%edx
  104452:	89 d3                	mov    %edx,%ebx
  104454:	89 c1                	mov    %eax,%ecx
  104456:	d3 e3                	shl    %cl,%ebx
  104458:	89 d8                	mov    %ebx,%eax
  10445a:	89 c2                	mov    %eax,%edx
  10445c:	f7 d2                	not    %edx
  10445e:	0f b7 05 30 96 10 00 	movzwl 0x109630,%eax
  104465:	21 d0                	and    %edx,%eax
  104467:	0f b7 c0             	movzwl %ax,%eax
  10446a:	89 04 24             	mov    %eax,(%esp)
  10446d:	e8 82 ff ff ff       	call   1043f4 <pic_setmask>
}
  104472:	83 c4 04             	add    $0x4,%esp
  104475:	5b                   	pop    %ebx
  104476:	5d                   	pop    %ebp
  104477:	c3                   	ret    

00104478 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  104478:	55                   	push   %ebp
  104479:	89 e5                	mov    %esp,%ebp
  10447b:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10447e:	8b 45 08             	mov    0x8(%ebp),%eax
  104481:	0f b6 c0             	movzbl %al,%eax
  104484:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  10448b:	88 45 f3             	mov    %al,-0xd(%ebp)
  10448e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  104492:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104495:	ee                   	out    %al,(%dx)
  104496:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10449d:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1044a0:	89 c2                	mov    %eax,%edx
  1044a2:	ec                   	in     (%dx),%al
  1044a3:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  1044a6:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  1044aa:	0f b6 c0             	movzbl %al,%eax
}
  1044ad:	c9                   	leave  
  1044ae:	c3                   	ret    

001044af <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  1044af:	55                   	push   %ebp
  1044b0:	89 e5                	mov    %esp,%ebp
  1044b2:	53                   	push   %ebx
  1044b3:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  1044b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1044b9:	89 04 24             	mov    %eax,(%esp)
  1044bc:	e8 b7 ff ff ff       	call   104478 <nvram_read>
  1044c1:	89 c3                	mov    %eax,%ebx
  1044c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1044c6:	83 c0 01             	add    $0x1,%eax
  1044c9:	89 04 24             	mov    %eax,(%esp)
  1044cc:	e8 a7 ff ff ff       	call   104478 <nvram_read>
  1044d1:	c1 e0 08             	shl    $0x8,%eax
  1044d4:	09 d8                	or     %ebx,%eax
}
  1044d6:	83 c4 04             	add    $0x4,%esp
  1044d9:	5b                   	pop    %ebx
  1044da:	5d                   	pop    %ebp
  1044db:	c3                   	ret    

001044dc <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  1044dc:	55                   	push   %ebp
  1044dd:	89 e5                	mov    %esp,%ebp
  1044df:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  1044e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1044e5:	0f b6 c0             	movzbl %al,%eax
  1044e8:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1044ef:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1044f2:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1044f6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1044f9:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  1044fa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1044fd:	0f b6 c0             	movzbl %al,%eax
  104500:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  104507:	88 45 fb             	mov    %al,-0x5(%ebp)
  10450a:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  10450e:	8b 55 fc             	mov    -0x4(%ebp),%edx
  104511:	ee                   	out    %al,(%dx)
}
  104512:	c9                   	leave  
  104513:	c3                   	ret    

00104514 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  104514:	55                   	push   %ebp
  104515:	89 e5                	mov    %esp,%ebp
  104517:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10451a:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10451d:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  104520:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104523:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104526:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10452b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10452e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104531:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  104537:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10453c:	74 24                	je     104562 <cpu_cur+0x4e>
  10453e:	c7 44 24 0c a1 68 10 	movl   $0x1068a1,0xc(%esp)
  104545:	00 
  104546:	c7 44 24 08 b7 68 10 	movl   $0x1068b7,0x8(%esp)
  10454d:	00 
  10454e:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  104555:	00 
  104556:	c7 04 24 cc 68 10 00 	movl   $0x1068cc,(%esp)
  10455d:	e8 1f bf ff ff       	call   100481 <debug_panic>
	return c;
  104562:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  104565:	c9                   	leave  
  104566:	c3                   	ret    

00104567 <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  104567:	55                   	push   %ebp
  104568:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  10456a:	a1 0c fb 30 00       	mov    0x30fb0c,%eax
  10456f:	8b 55 08             	mov    0x8(%ebp),%edx
  104572:	c1 e2 02             	shl    $0x2,%edx
  104575:	8d 14 10             	lea    (%eax,%edx,1),%edx
  104578:	8b 45 0c             	mov    0xc(%ebp),%eax
  10457b:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  10457d:	a1 0c fb 30 00       	mov    0x30fb0c,%eax
  104582:	83 c0 20             	add    $0x20,%eax
  104585:	8b 00                	mov    (%eax),%eax
}
  104587:	5d                   	pop    %ebp
  104588:	c3                   	ret    

00104589 <lapic_init>:

void
lapic_init()
{
  104589:	55                   	push   %ebp
  10458a:	89 e5                	mov    %esp,%ebp
  10458c:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  10458f:	a1 0c fb 30 00       	mov    0x30fb0c,%eax
  104594:	85 c0                	test   %eax,%eax
  104596:	0f 84 82 01 00 00    	je     10471e <lapic_init+0x195>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  10459c:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  1045a3:	00 
  1045a4:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  1045ab:	e8 b7 ff ff ff       	call   104567 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  1045b0:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  1045b7:	00 
  1045b8:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  1045bf:	e8 a3 ff ff ff       	call   104567 <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  1045c4:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  1045cb:	00 
  1045cc:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1045d3:	e8 8f ff ff ff       	call   104567 <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  1045d8:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  1045df:	00 
  1045e0:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  1045e7:	e8 7b ff ff ff       	call   104567 <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  1045ec:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1045f3:	00 
  1045f4:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  1045fb:	e8 67 ff ff ff       	call   104567 <lapicw>
	lapicw(LINT1, MASKED);
  104600:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  104607:	00 
  104608:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  10460f:	e8 53 ff ff ff       	call   104567 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  104614:	a1 0c fb 30 00       	mov    0x30fb0c,%eax
  104619:	83 c0 30             	add    $0x30,%eax
  10461c:	8b 00                	mov    (%eax),%eax
  10461e:	c1 e8 10             	shr    $0x10,%eax
  104621:	25 ff 00 00 00       	and    $0xff,%eax
  104626:	83 f8 03             	cmp    $0x3,%eax
  104629:	76 14                	jbe    10463f <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  10462b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  104632:	00 
  104633:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  10463a:	e8 28 ff ff ff       	call   104567 <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  10463f:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  104646:	00 
  104647:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  10464e:	e8 14 ff ff ff       	call   104567 <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  104653:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  10465a:	ff 
  10465b:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  104662:	e8 00 ff ff ff       	call   104567 <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  104667:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  10466e:	f0 
  10466f:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  104676:	e8 ec fe ff ff       	call   104567 <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  10467b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104682:	00 
  104683:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10468a:	e8 d8 fe ff ff       	call   104567 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  10468f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104696:	00 
  104697:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10469e:	e8 c4 fe ff ff       	call   104567 <lapicw>
	lapicw(ESR, 0);
  1046a3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046aa:	00 
  1046ab:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1046b2:	e8 b0 fe ff ff       	call   104567 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  1046b7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046be:	00 
  1046bf:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  1046c6:	e8 9c fe ff ff       	call   104567 <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  1046cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1046d2:	00 
  1046d3:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1046da:	e8 88 fe ff ff       	call   104567 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  1046df:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  1046e6:	00 
  1046e7:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1046ee:	e8 74 fe ff ff       	call   104567 <lapicw>
	while(lapic[ICRLO] & DELIVS)
  1046f3:	a1 0c fb 30 00       	mov    0x30fb0c,%eax
  1046f8:	05 00 03 00 00       	add    $0x300,%eax
  1046fd:	8b 00                	mov    (%eax),%eax
  1046ff:	25 00 10 00 00       	and    $0x1000,%eax
  104704:	85 c0                	test   %eax,%eax
  104706:	75 eb                	jne    1046f3 <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  104708:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10470f:	00 
  104710:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  104717:	e8 4b fe ff ff       	call   104567 <lapicw>
  10471c:	eb 01                	jmp    10471f <lapic_init+0x196>

void
lapic_init()
{
	if (!lapic) 
		return;
  10471e:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  10471f:	c9                   	leave  
  104720:	c3                   	ret    

00104721 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  104721:	55                   	push   %ebp
  104722:	89 e5                	mov    %esp,%ebp
  104724:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  104727:	a1 0c fb 30 00       	mov    0x30fb0c,%eax
  10472c:	85 c0                	test   %eax,%eax
  10472e:	74 14                	je     104744 <lapic_eoi+0x23>
		lapicw(EOI, 0);
  104730:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104737:	00 
  104738:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10473f:	e8 23 fe ff ff       	call   104567 <lapicw>
}
  104744:	c9                   	leave  
  104745:	c3                   	ret    

00104746 <lapic_errintr>:

void lapic_errintr(void)
{
  104746:	55                   	push   %ebp
  104747:	89 e5                	mov    %esp,%ebp
  104749:	53                   	push   %ebx
  10474a:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  10474d:	e8 cf ff ff ff       	call   104721 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  104752:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104759:	00 
  10475a:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  104761:	e8 01 fe ff ff       	call   104567 <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  104766:	a1 0c fb 30 00       	mov    0x30fb0c,%eax
  10476b:	05 80 02 00 00       	add    $0x280,%eax
  104770:	8b 18                	mov    (%eax),%ebx
  104772:	e8 9d fd ff ff       	call   104514 <cpu_cur>
  104777:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10477e:	0f b6 c0             	movzbl %al,%eax
  104781:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  104785:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104789:	c7 44 24 08 d9 68 10 	movl   $0x1068d9,0x8(%esp)
  104790:	00 
  104791:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  104798:	00 
  104799:	c7 04 24 f3 68 10 00 	movl   $0x1068f3,(%esp)
  1047a0:	e8 9b bd ff ff       	call   100540 <debug_warn>
}
  1047a5:	83 c4 24             	add    $0x24,%esp
  1047a8:	5b                   	pop    %ebx
  1047a9:	5d                   	pop    %ebp
  1047aa:	c3                   	ret    

001047ab <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  1047ab:	55                   	push   %ebp
  1047ac:	89 e5                	mov    %esp,%ebp
}
  1047ae:	5d                   	pop    %ebp
  1047af:	c3                   	ret    

001047b0 <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  1047b0:	55                   	push   %ebp
  1047b1:	89 e5                	mov    %esp,%ebp
  1047b3:	83 ec 2c             	sub    $0x2c,%esp
  1047b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1047b9:	88 45 dc             	mov    %al,-0x24(%ebp)
  1047bc:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1047c3:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1047c7:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1047cb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1047ce:	ee                   	out    %al,(%dx)
  1047cf:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  1047d6:	c6 45 fb 0a          	movb   $0xa,-0x5(%ebp)
  1047da:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1047de:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1047e1:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  1047e2:	c7 45 ec 67 04 00 00 	movl   $0x467,-0x14(%ebp)
	wrv[0] = 0;
  1047e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1047ec:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  1047f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1047f4:	8d 50 02             	lea    0x2(%eax),%edx
  1047f7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047fa:	c1 e8 04             	shr    $0x4,%eax
  1047fd:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  104800:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  104804:	c1 e0 18             	shl    $0x18,%eax
  104807:	89 44 24 04          	mov    %eax,0x4(%esp)
  10480b:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  104812:	e8 50 fd ff ff       	call   104567 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  104817:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  10481e:	00 
  10481f:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104826:	e8 3c fd ff ff       	call   104567 <lapicw>
	microdelay(200);
  10482b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  104832:	e8 74 ff ff ff       	call   1047ab <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  104837:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  10483e:	00 
  10483f:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  104846:	e8 1c fd ff ff       	call   104567 <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  10484b:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  104852:	e8 54 ff ff ff       	call   1047ab <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  104857:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  10485e:	eb 40                	jmp    1048a0 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  104860:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  104864:	c1 e0 18             	shl    $0x18,%eax
  104867:	89 44 24 04          	mov    %eax,0x4(%esp)
  10486b:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  104872:	e8 f0 fc ff ff       	call   104567 <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  104877:	8b 45 0c             	mov    0xc(%ebp),%eax
  10487a:	c1 e8 0c             	shr    $0xc,%eax
  10487d:	80 cc 06             	or     $0x6,%ah
  104880:	89 44 24 04          	mov    %eax,0x4(%esp)
  104884:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10488b:	e8 d7 fc ff ff       	call   104567 <lapicw>
		microdelay(200);
  104890:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  104897:	e8 0f ff ff ff       	call   1047ab <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  10489c:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  1048a0:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
  1048a4:	7e ba                	jle    104860 <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  1048a6:	c9                   	leave  
  1048a7:	c3                   	ret    

001048a8 <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  1048a8:	55                   	push   %ebp
  1048a9:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  1048ab:	a1 00 f4 30 00       	mov    0x30f400,%eax
  1048b0:	8b 55 08             	mov    0x8(%ebp),%edx
  1048b3:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  1048b5:	a1 00 f4 30 00       	mov    0x30f400,%eax
  1048ba:	8b 40 10             	mov    0x10(%eax),%eax
}
  1048bd:	5d                   	pop    %ebp
  1048be:	c3                   	ret    

001048bf <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  1048bf:	55                   	push   %ebp
  1048c0:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  1048c2:	a1 00 f4 30 00       	mov    0x30f400,%eax
  1048c7:	8b 55 08             	mov    0x8(%ebp),%edx
  1048ca:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  1048cc:	a1 00 f4 30 00       	mov    0x30f400,%eax
  1048d1:	8b 55 0c             	mov    0xc(%ebp),%edx
  1048d4:	89 50 10             	mov    %edx,0x10(%eax)
}
  1048d7:	5d                   	pop    %ebp
  1048d8:	c3                   	ret    

001048d9 <ioapic_init>:

void
ioapic_init(void)
{
  1048d9:	55                   	push   %ebp
  1048da:	89 e5                	mov    %esp,%ebp
  1048dc:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  1048df:	a1 04 f4 30 00       	mov    0x30f404,%eax
  1048e4:	85 c0                	test   %eax,%eax
  1048e6:	0f 84 fd 00 00 00    	je     1049e9 <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  1048ec:	a1 00 f4 30 00       	mov    0x30f400,%eax
  1048f1:	85 c0                	test   %eax,%eax
  1048f3:	75 0a                	jne    1048ff <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  1048f5:	c7 05 00 f4 30 00 00 	movl   $0xfec00000,0x30f400
  1048fc:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  1048ff:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  104906:	e8 9d ff ff ff       	call   1048a8 <ioapic_read>
  10490b:	c1 e8 10             	shr    $0x10,%eax
  10490e:	25 ff 00 00 00       	and    $0xff,%eax
  104913:	89 45 f4             	mov    %eax,-0xc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  104916:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10491d:	e8 86 ff ff ff       	call   1048a8 <ioapic_read>
  104922:	c1 e8 18             	shr    $0x18,%eax
  104925:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  104928:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  10492c:	75 2a                	jne    104958 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  10492e:	0f b6 05 fc f3 30 00 	movzbl 0x30f3fc,%eax
  104935:	0f b6 c0             	movzbl %al,%eax
  104938:	c1 e0 18             	shl    $0x18,%eax
  10493b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10493f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  104946:	e8 74 ff ff ff       	call   1048bf <ioapic_write>
		id = ioapicid;
  10494b:	0f b6 05 fc f3 30 00 	movzbl 0x30f3fc,%eax
  104952:	0f b6 c0             	movzbl %al,%eax
  104955:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  104958:	0f b6 05 fc f3 30 00 	movzbl 0x30f3fc,%eax
  10495f:	0f b6 c0             	movzbl %al,%eax
  104962:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104965:	74 31                	je     104998 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  104967:	0f b6 05 fc f3 30 00 	movzbl 0x30f3fc,%eax
  10496e:	0f b6 c0             	movzbl %al,%eax
  104971:	89 44 24 10          	mov    %eax,0x10(%esp)
  104975:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104978:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10497c:	c7 44 24 08 00 69 10 	movl   $0x106900,0x8(%esp)
  104983:	00 
  104984:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  10498b:	00 
  10498c:	c7 04 24 21 69 10 00 	movl   $0x106921,(%esp)
  104993:	e8 a8 bb ff ff       	call   100540 <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  104998:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  10499f:	eb 3e                	jmp    1049df <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  1049a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1049a4:	83 c0 20             	add    $0x20,%eax
  1049a7:	0d 00 00 01 00       	or     $0x10000,%eax
  1049ac:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1049af:	83 c2 08             	add    $0x8,%edx
  1049b2:	01 d2                	add    %edx,%edx
  1049b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049b8:	89 14 24             	mov    %edx,(%esp)
  1049bb:	e8 ff fe ff ff       	call   1048bf <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  1049c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1049c3:	83 c0 08             	add    $0x8,%eax
  1049c6:	01 c0                	add    %eax,%eax
  1049c8:	83 c0 01             	add    $0x1,%eax
  1049cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1049d2:	00 
  1049d3:	89 04 24             	mov    %eax,(%esp)
  1049d6:	e8 e4 fe ff ff       	call   1048bf <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  1049db:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1049df:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1049e2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1049e5:	7e ba                	jle    1049a1 <ioapic_init+0xc8>
  1049e7:	eb 01                	jmp    1049ea <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  1049e9:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  1049ea:	c9                   	leave  
  1049eb:	c3                   	ret    

001049ec <ioapic_enable>:

void
ioapic_enable(int irq)
{
  1049ec:	55                   	push   %ebp
  1049ed:	89 e5                	mov    %esp,%ebp
  1049ef:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  1049f2:	a1 04 f4 30 00       	mov    0x30f404,%eax
  1049f7:	85 c0                	test   %eax,%eax
  1049f9:	74 3a                	je     104a35 <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  1049fb:	8b 45 08             	mov    0x8(%ebp),%eax
  1049fe:	83 c0 20             	add    $0x20,%eax
  104a01:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  104a04:	8b 55 08             	mov    0x8(%ebp),%edx
  104a07:	83 c2 08             	add    $0x8,%edx
  104a0a:	01 d2                	add    %edx,%edx
  104a0c:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a10:	89 14 24             	mov    %edx,(%esp)
  104a13:	e8 a7 fe ff ff       	call   1048bf <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  104a18:	8b 45 08             	mov    0x8(%ebp),%eax
  104a1b:	83 c0 08             	add    $0x8,%eax
  104a1e:	01 c0                	add    %eax,%eax
  104a20:	83 c0 01             	add    $0x1,%eax
  104a23:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  104a2a:	ff 
  104a2b:	89 04 24             	mov    %eax,(%esp)
  104a2e:	e8 8c fe ff ff       	call   1048bf <ioapic_write>
  104a33:	eb 01                	jmp    104a36 <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  104a35:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  104a36:	c9                   	leave  
  104a37:	c3                   	ret    

00104a38 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  104a38:	55                   	push   %ebp
  104a39:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  104a3b:	8b 45 08             	mov    0x8(%ebp),%eax
  104a3e:	8b 40 18             	mov    0x18(%eax),%eax
  104a41:	83 e0 02             	and    $0x2,%eax
  104a44:	85 c0                	test   %eax,%eax
  104a46:	74 1c                	je     104a64 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  104a48:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a4b:	8b 00                	mov    (%eax),%eax
  104a4d:	8d 50 08             	lea    0x8(%eax),%edx
  104a50:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a53:	89 10                	mov    %edx,(%eax)
  104a55:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a58:	8b 00                	mov    (%eax),%eax
  104a5a:	83 e8 08             	sub    $0x8,%eax
  104a5d:	8b 50 04             	mov    0x4(%eax),%edx
  104a60:	8b 00                	mov    (%eax),%eax
  104a62:	eb 47                	jmp    104aab <getuint+0x73>
	else if (st->flags & F_L)
  104a64:	8b 45 08             	mov    0x8(%ebp),%eax
  104a67:	8b 40 18             	mov    0x18(%eax),%eax
  104a6a:	83 e0 01             	and    $0x1,%eax
  104a6d:	84 c0                	test   %al,%al
  104a6f:	74 1e                	je     104a8f <getuint+0x57>
		return va_arg(*ap, unsigned long);
  104a71:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a74:	8b 00                	mov    (%eax),%eax
  104a76:	8d 50 04             	lea    0x4(%eax),%edx
  104a79:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a7c:	89 10                	mov    %edx,(%eax)
  104a7e:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a81:	8b 00                	mov    (%eax),%eax
  104a83:	83 e8 04             	sub    $0x4,%eax
  104a86:	8b 00                	mov    (%eax),%eax
  104a88:	ba 00 00 00 00       	mov    $0x0,%edx
  104a8d:	eb 1c                	jmp    104aab <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  104a8f:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a92:	8b 00                	mov    (%eax),%eax
  104a94:	8d 50 04             	lea    0x4(%eax),%edx
  104a97:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a9a:	89 10                	mov    %edx,(%eax)
  104a9c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a9f:	8b 00                	mov    (%eax),%eax
  104aa1:	83 e8 04             	sub    $0x4,%eax
  104aa4:	8b 00                	mov    (%eax),%eax
  104aa6:	ba 00 00 00 00       	mov    $0x0,%edx
}
  104aab:	5d                   	pop    %ebp
  104aac:	c3                   	ret    

00104aad <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  104aad:	55                   	push   %ebp
  104aae:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  104ab0:	8b 45 08             	mov    0x8(%ebp),%eax
  104ab3:	8b 40 18             	mov    0x18(%eax),%eax
  104ab6:	83 e0 02             	and    $0x2,%eax
  104ab9:	85 c0                	test   %eax,%eax
  104abb:	74 1c                	je     104ad9 <getint+0x2c>
		return va_arg(*ap, long long);
  104abd:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ac0:	8b 00                	mov    (%eax),%eax
  104ac2:	8d 50 08             	lea    0x8(%eax),%edx
  104ac5:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ac8:	89 10                	mov    %edx,(%eax)
  104aca:	8b 45 0c             	mov    0xc(%ebp),%eax
  104acd:	8b 00                	mov    (%eax),%eax
  104acf:	83 e8 08             	sub    $0x8,%eax
  104ad2:	8b 50 04             	mov    0x4(%eax),%edx
  104ad5:	8b 00                	mov    (%eax),%eax
  104ad7:	eb 47                	jmp    104b20 <getint+0x73>
	else if (st->flags & F_L)
  104ad9:	8b 45 08             	mov    0x8(%ebp),%eax
  104adc:	8b 40 18             	mov    0x18(%eax),%eax
  104adf:	83 e0 01             	and    $0x1,%eax
  104ae2:	84 c0                	test   %al,%al
  104ae4:	74 1e                	je     104b04 <getint+0x57>
		return va_arg(*ap, long);
  104ae6:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ae9:	8b 00                	mov    (%eax),%eax
  104aeb:	8d 50 04             	lea    0x4(%eax),%edx
  104aee:	8b 45 0c             	mov    0xc(%ebp),%eax
  104af1:	89 10                	mov    %edx,(%eax)
  104af3:	8b 45 0c             	mov    0xc(%ebp),%eax
  104af6:	8b 00                	mov    (%eax),%eax
  104af8:	83 e8 04             	sub    $0x4,%eax
  104afb:	8b 00                	mov    (%eax),%eax
  104afd:	89 c2                	mov    %eax,%edx
  104aff:	c1 fa 1f             	sar    $0x1f,%edx
  104b02:	eb 1c                	jmp    104b20 <getint+0x73>
	else
		return va_arg(*ap, int);
  104b04:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b07:	8b 00                	mov    (%eax),%eax
  104b09:	8d 50 04             	lea    0x4(%eax),%edx
  104b0c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b0f:	89 10                	mov    %edx,(%eax)
  104b11:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b14:	8b 00                	mov    (%eax),%eax
  104b16:	83 e8 04             	sub    $0x4,%eax
  104b19:	8b 00                	mov    (%eax),%eax
  104b1b:	89 c2                	mov    %eax,%edx
  104b1d:	c1 fa 1f             	sar    $0x1f,%edx
}
  104b20:	5d                   	pop    %ebp
  104b21:	c3                   	ret    

00104b22 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  104b22:	55                   	push   %ebp
  104b23:	89 e5                	mov    %esp,%ebp
  104b25:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  104b28:	eb 1a                	jmp    104b44 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  104b2a:	8b 45 08             	mov    0x8(%ebp),%eax
  104b2d:	8b 08                	mov    (%eax),%ecx
  104b2f:	8b 45 08             	mov    0x8(%ebp),%eax
  104b32:	8b 50 04             	mov    0x4(%eax),%edx
  104b35:	8b 45 08             	mov    0x8(%ebp),%eax
  104b38:	8b 40 08             	mov    0x8(%eax),%eax
  104b3b:	89 54 24 04          	mov    %edx,0x4(%esp)
  104b3f:	89 04 24             	mov    %eax,(%esp)
  104b42:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  104b44:	8b 45 08             	mov    0x8(%ebp),%eax
  104b47:	8b 40 0c             	mov    0xc(%eax),%eax
  104b4a:	8d 50 ff             	lea    -0x1(%eax),%edx
  104b4d:	8b 45 08             	mov    0x8(%ebp),%eax
  104b50:	89 50 0c             	mov    %edx,0xc(%eax)
  104b53:	8b 45 08             	mov    0x8(%ebp),%eax
  104b56:	8b 40 0c             	mov    0xc(%eax),%eax
  104b59:	85 c0                	test   %eax,%eax
  104b5b:	79 cd                	jns    104b2a <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  104b5d:	c9                   	leave  
  104b5e:	c3                   	ret    

00104b5f <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  104b5f:	55                   	push   %ebp
  104b60:	89 e5                	mov    %esp,%ebp
  104b62:	53                   	push   %ebx
  104b63:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  104b66:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104b6a:	79 18                	jns    104b84 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  104b6c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104b73:	00 
  104b74:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b77:	89 04 24             	mov    %eax,(%esp)
  104b7a:	e8 e7 07 00 00       	call   105366 <strchr>
  104b7f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104b82:	eb 2c                	jmp    104bb0 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  104b84:	8b 45 10             	mov    0x10(%ebp),%eax
  104b87:	89 44 24 08          	mov    %eax,0x8(%esp)
  104b8b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104b92:	00 
  104b93:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b96:	89 04 24             	mov    %eax,(%esp)
  104b99:	e8 cc 09 00 00       	call   10556a <memchr>
  104b9e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104ba1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104ba5:	75 09                	jne    104bb0 <putstr+0x51>
		lim = str + maxlen;
  104ba7:	8b 45 10             	mov    0x10(%ebp),%eax
  104baa:	03 45 0c             	add    0xc(%ebp),%eax
  104bad:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  104bb0:	8b 45 08             	mov    0x8(%ebp),%eax
  104bb3:	8b 40 0c             	mov    0xc(%eax),%eax
  104bb6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  104bb9:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104bbc:	89 cb                	mov    %ecx,%ebx
  104bbe:	29 d3                	sub    %edx,%ebx
  104bc0:	89 da                	mov    %ebx,%edx
  104bc2:	8d 14 10             	lea    (%eax,%edx,1),%edx
  104bc5:	8b 45 08             	mov    0x8(%ebp),%eax
  104bc8:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  104bcb:	8b 45 08             	mov    0x8(%ebp),%eax
  104bce:	8b 40 18             	mov    0x18(%eax),%eax
  104bd1:	83 e0 10             	and    $0x10,%eax
  104bd4:	85 c0                	test   %eax,%eax
  104bd6:	75 32                	jne    104c0a <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  104bd8:	8b 45 08             	mov    0x8(%ebp),%eax
  104bdb:	89 04 24             	mov    %eax,(%esp)
  104bde:	e8 3f ff ff ff       	call   104b22 <putpad>
	while (str < lim) {
  104be3:	eb 25                	jmp    104c0a <putstr+0xab>
		char ch = *str++;
  104be5:	8b 45 0c             	mov    0xc(%ebp),%eax
  104be8:	0f b6 00             	movzbl (%eax),%eax
  104beb:	88 45 f7             	mov    %al,-0x9(%ebp)
  104bee:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  104bf2:	8b 45 08             	mov    0x8(%ebp),%eax
  104bf5:	8b 08                	mov    (%eax),%ecx
  104bf7:	8b 45 08             	mov    0x8(%ebp),%eax
  104bfa:	8b 50 04             	mov    0x4(%eax),%edx
  104bfd:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  104c01:	89 54 24 04          	mov    %edx,0x4(%esp)
  104c05:	89 04 24             	mov    %eax,(%esp)
  104c08:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  104c0a:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c0d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104c10:	72 d3                	jb     104be5 <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  104c12:	8b 45 08             	mov    0x8(%ebp),%eax
  104c15:	89 04 24             	mov    %eax,(%esp)
  104c18:	e8 05 ff ff ff       	call   104b22 <putpad>
}
  104c1d:	83 c4 24             	add    $0x24,%esp
  104c20:	5b                   	pop    %ebx
  104c21:	5d                   	pop    %ebp
  104c22:	c3                   	ret    

00104c23 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  104c23:	55                   	push   %ebp
  104c24:	89 e5                	mov    %esp,%ebp
  104c26:	53                   	push   %ebx
  104c27:	83 ec 24             	sub    $0x24,%esp
  104c2a:	8b 45 10             	mov    0x10(%ebp),%eax
  104c2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104c30:	8b 45 14             	mov    0x14(%ebp),%eax
  104c33:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  104c36:	8b 45 08             	mov    0x8(%ebp),%eax
  104c39:	8b 40 1c             	mov    0x1c(%eax),%eax
  104c3c:	89 c2                	mov    %eax,%edx
  104c3e:	c1 fa 1f             	sar    $0x1f,%edx
  104c41:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104c44:	77 4e                	ja     104c94 <genint+0x71>
  104c46:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  104c49:	72 05                	jb     104c50 <genint+0x2d>
  104c4b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104c4e:	77 44                	ja     104c94 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  104c50:	8b 45 08             	mov    0x8(%ebp),%eax
  104c53:	8b 40 1c             	mov    0x1c(%eax),%eax
  104c56:	89 c2                	mov    %eax,%edx
  104c58:	c1 fa 1f             	sar    $0x1f,%edx
  104c5b:	89 44 24 08          	mov    %eax,0x8(%esp)
  104c5f:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104c63:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104c66:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104c69:	89 04 24             	mov    %eax,(%esp)
  104c6c:	89 54 24 04          	mov    %edx,0x4(%esp)
  104c70:	e8 3b 09 00 00       	call   1055b0 <__udivdi3>
  104c75:	89 44 24 08          	mov    %eax,0x8(%esp)
  104c79:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104c7d:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c80:	89 44 24 04          	mov    %eax,0x4(%esp)
  104c84:	8b 45 08             	mov    0x8(%ebp),%eax
  104c87:	89 04 24             	mov    %eax,(%esp)
  104c8a:	e8 94 ff ff ff       	call   104c23 <genint>
  104c8f:	89 45 0c             	mov    %eax,0xc(%ebp)
  104c92:	eb 1b                	jmp    104caf <genint+0x8c>
	else if (st->signc >= 0)
  104c94:	8b 45 08             	mov    0x8(%ebp),%eax
  104c97:	8b 40 14             	mov    0x14(%eax),%eax
  104c9a:	85 c0                	test   %eax,%eax
  104c9c:	78 11                	js     104caf <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  104c9e:	8b 45 08             	mov    0x8(%ebp),%eax
  104ca1:	8b 40 14             	mov    0x14(%eax),%eax
  104ca4:	89 c2                	mov    %eax,%edx
  104ca6:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ca9:	88 10                	mov    %dl,(%eax)
  104cab:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  104caf:	8b 45 08             	mov    0x8(%ebp),%eax
  104cb2:	8b 40 1c             	mov    0x1c(%eax),%eax
  104cb5:	89 c1                	mov    %eax,%ecx
  104cb7:	89 c3                	mov    %eax,%ebx
  104cb9:	c1 fb 1f             	sar    $0x1f,%ebx
  104cbc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104cbf:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104cc2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  104cc6:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  104cca:	89 04 24             	mov    %eax,(%esp)
  104ccd:	89 54 24 04          	mov    %edx,0x4(%esp)
  104cd1:	e8 0a 0a 00 00       	call   1056e0 <__umoddi3>
  104cd6:	05 30 69 10 00       	add    $0x106930,%eax
  104cdb:	0f b6 10             	movzbl (%eax),%edx
  104cde:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ce1:	88 10                	mov    %dl,(%eax)
  104ce3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  104ce7:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  104cea:	83 c4 24             	add    $0x24,%esp
  104ced:	5b                   	pop    %ebx
  104cee:	5d                   	pop    %ebp
  104cef:	c3                   	ret    

00104cf0 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  104cf0:	55                   	push   %ebp
  104cf1:	89 e5                	mov    %esp,%ebp
  104cf3:	83 ec 58             	sub    $0x58,%esp
  104cf6:	8b 45 0c             	mov    0xc(%ebp),%eax
  104cf9:	89 45 c0             	mov    %eax,-0x40(%ebp)
  104cfc:	8b 45 10             	mov    0x10(%ebp),%eax
  104cff:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  104d02:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104d05:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  104d08:	8b 45 08             	mov    0x8(%ebp),%eax
  104d0b:	8b 55 14             	mov    0x14(%ebp),%edx
  104d0e:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  104d11:	8b 45 c0             	mov    -0x40(%ebp),%eax
  104d14:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  104d17:	89 44 24 08          	mov    %eax,0x8(%esp)
  104d1b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104d22:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d26:	8b 45 08             	mov    0x8(%ebp),%eax
  104d29:	89 04 24             	mov    %eax,(%esp)
  104d2c:	e8 f2 fe ff ff       	call   104c23 <genint>
  104d31:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  104d34:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104d37:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104d3a:	89 d1                	mov    %edx,%ecx
  104d3c:	29 c1                	sub    %eax,%ecx
  104d3e:	89 c8                	mov    %ecx,%eax
  104d40:	89 44 24 08          	mov    %eax,0x8(%esp)
  104d44:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  104d47:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d4b:	8b 45 08             	mov    0x8(%ebp),%eax
  104d4e:	89 04 24             	mov    %eax,(%esp)
  104d51:	e8 09 fe ff ff       	call   104b5f <putstr>
}
  104d56:	c9                   	leave  
  104d57:	c3                   	ret    

00104d58 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  104d58:	55                   	push   %ebp
  104d59:	89 e5                	mov    %esp,%ebp
  104d5b:	53                   	push   %ebx
  104d5c:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  104d5f:	8d 55 c8             	lea    -0x38(%ebp),%edx
  104d62:	b9 00 00 00 00       	mov    $0x0,%ecx
  104d67:	b8 20 00 00 00       	mov    $0x20,%eax
  104d6c:	89 c3                	mov    %eax,%ebx
  104d6e:	83 e3 fc             	and    $0xfffffffc,%ebx
  104d71:	b8 00 00 00 00       	mov    $0x0,%eax
  104d76:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  104d79:	83 c0 04             	add    $0x4,%eax
  104d7c:	39 d8                	cmp    %ebx,%eax
  104d7e:	72 f6                	jb     104d76 <vprintfmt+0x1e>
  104d80:	01 c2                	add    %eax,%edx
  104d82:	8b 45 08             	mov    0x8(%ebp),%eax
  104d85:	89 45 c8             	mov    %eax,-0x38(%ebp)
  104d88:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d8b:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104d8e:	eb 17                	jmp    104da7 <vprintfmt+0x4f>
			if (ch == '\0')
  104d90:	85 db                	test   %ebx,%ebx
  104d92:	0f 84 52 03 00 00    	je     1050ea <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  104d98:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d9b:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d9f:	89 1c 24             	mov    %ebx,(%esp)
  104da2:	8b 45 08             	mov    0x8(%ebp),%eax
  104da5:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  104da7:	8b 45 10             	mov    0x10(%ebp),%eax
  104daa:	0f b6 00             	movzbl (%eax),%eax
  104dad:	0f b6 d8             	movzbl %al,%ebx
  104db0:	83 fb 25             	cmp    $0x25,%ebx
  104db3:	0f 95 c0             	setne  %al
  104db6:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104dba:	84 c0                	test   %al,%al
  104dbc:	75 d2                	jne    104d90 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  104dbe:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  104dc5:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  104dcc:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  104dd3:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  104dda:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  104de1:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  104de8:	eb 04                	jmp    104dee <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  104dea:	90                   	nop
  104deb:	eb 01                	jmp    104dee <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  104ded:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  104dee:	8b 45 10             	mov    0x10(%ebp),%eax
  104df1:	0f b6 00             	movzbl (%eax),%eax
  104df4:	0f b6 d8             	movzbl %al,%ebx
  104df7:	89 d8                	mov    %ebx,%eax
  104df9:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  104dfd:	83 e8 20             	sub    $0x20,%eax
  104e00:	83 f8 58             	cmp    $0x58,%eax
  104e03:	0f 87 b1 02 00 00    	ja     1050ba <vprintfmt+0x362>
  104e09:	8b 04 85 48 69 10 00 	mov    0x106948(,%eax,4),%eax
  104e10:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  104e12:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104e15:	83 c8 10             	or     $0x10,%eax
  104e18:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104e1b:	eb d1                	jmp    104dee <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  104e1d:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  104e24:	eb c8                	jmp    104dee <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  104e26:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104e29:	85 c0                	test   %eax,%eax
  104e2b:	79 bd                	jns    104dea <vprintfmt+0x92>
				st.signc = ' ';
  104e2d:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  104e34:	eb b8                	jmp    104dee <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  104e36:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104e39:	83 e0 08             	and    $0x8,%eax
  104e3c:	85 c0                	test   %eax,%eax
  104e3e:	75 07                	jne    104e47 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  104e40:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104e47:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  104e4e:	8b 55 d8             	mov    -0x28(%ebp),%edx
  104e51:	89 d0                	mov    %edx,%eax
  104e53:	c1 e0 02             	shl    $0x2,%eax
  104e56:	01 d0                	add    %edx,%eax
  104e58:	01 c0                	add    %eax,%eax
  104e5a:	01 d8                	add    %ebx,%eax
  104e5c:	83 e8 30             	sub    $0x30,%eax
  104e5f:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  104e62:	8b 45 10             	mov    0x10(%ebp),%eax
  104e65:	0f b6 00             	movzbl (%eax),%eax
  104e68:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  104e6b:	83 fb 2f             	cmp    $0x2f,%ebx
  104e6e:	7e 21                	jle    104e91 <vprintfmt+0x139>
  104e70:	83 fb 39             	cmp    $0x39,%ebx
  104e73:	7f 1f                	jg     104e94 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  104e75:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  104e79:	eb d3                	jmp    104e4e <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  104e7b:	8b 45 14             	mov    0x14(%ebp),%eax
  104e7e:	83 c0 04             	add    $0x4,%eax
  104e81:	89 45 14             	mov    %eax,0x14(%ebp)
  104e84:	8b 45 14             	mov    0x14(%ebp),%eax
  104e87:	83 e8 04             	sub    $0x4,%eax
  104e8a:	8b 00                	mov    (%eax),%eax
  104e8c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  104e8f:	eb 04                	jmp    104e95 <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  104e91:	90                   	nop
  104e92:	eb 01                	jmp    104e95 <vprintfmt+0x13d>
  104e94:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  104e95:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104e98:	83 e0 08             	and    $0x8,%eax
  104e9b:	85 c0                	test   %eax,%eax
  104e9d:	0f 85 4a ff ff ff    	jne    104ded <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  104ea3:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104ea6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  104ea9:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  104eb0:	e9 39 ff ff ff       	jmp    104dee <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  104eb5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104eb8:	83 c8 08             	or     $0x8,%eax
  104ebb:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104ebe:	e9 2b ff ff ff       	jmp    104dee <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  104ec3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104ec6:	83 c8 04             	or     $0x4,%eax
  104ec9:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104ecc:	e9 1d ff ff ff       	jmp    104dee <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  104ed1:	8b 55 e0             	mov    -0x20(%ebp),%edx
  104ed4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104ed7:	83 e0 01             	and    $0x1,%eax
  104eda:	84 c0                	test   %al,%al
  104edc:	74 07                	je     104ee5 <vprintfmt+0x18d>
  104ede:	b8 02 00 00 00       	mov    $0x2,%eax
  104ee3:	eb 05                	jmp    104eea <vprintfmt+0x192>
  104ee5:	b8 01 00 00 00       	mov    $0x1,%eax
  104eea:	09 d0                	or     %edx,%eax
  104eec:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  104eef:	e9 fa fe ff ff       	jmp    104dee <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  104ef4:	8b 45 14             	mov    0x14(%ebp),%eax
  104ef7:	83 c0 04             	add    $0x4,%eax
  104efa:	89 45 14             	mov    %eax,0x14(%ebp)
  104efd:	8b 45 14             	mov    0x14(%ebp),%eax
  104f00:	83 e8 04             	sub    $0x4,%eax
  104f03:	8b 00                	mov    (%eax),%eax
  104f05:	8b 55 0c             	mov    0xc(%ebp),%edx
  104f08:	89 54 24 04          	mov    %edx,0x4(%esp)
  104f0c:	89 04 24             	mov    %eax,(%esp)
  104f0f:	8b 45 08             	mov    0x8(%ebp),%eax
  104f12:	ff d0                	call   *%eax
			break;
  104f14:	e9 cb 01 00 00       	jmp    1050e4 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  104f19:	8b 45 14             	mov    0x14(%ebp),%eax
  104f1c:	83 c0 04             	add    $0x4,%eax
  104f1f:	89 45 14             	mov    %eax,0x14(%ebp)
  104f22:	8b 45 14             	mov    0x14(%ebp),%eax
  104f25:	83 e8 04             	sub    $0x4,%eax
  104f28:	8b 00                	mov    (%eax),%eax
  104f2a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104f2d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104f31:	75 07                	jne    104f3a <vprintfmt+0x1e2>
				s = "(null)";
  104f33:	c7 45 f4 41 69 10 00 	movl   $0x106941,-0xc(%ebp)
			putstr(&st, s, st.prec);
  104f3a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104f3d:	89 44 24 08          	mov    %eax,0x8(%esp)
  104f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104f44:	89 44 24 04          	mov    %eax,0x4(%esp)
  104f48:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104f4b:	89 04 24             	mov    %eax,(%esp)
  104f4e:	e8 0c fc ff ff       	call   104b5f <putstr>
			break;
  104f53:	e9 8c 01 00 00       	jmp    1050e4 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  104f58:	8d 45 14             	lea    0x14(%ebp),%eax
  104f5b:	89 44 24 04          	mov    %eax,0x4(%esp)
  104f5f:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104f62:	89 04 24             	mov    %eax,(%esp)
  104f65:	e8 43 fb ff ff       	call   104aad <getint>
  104f6a:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104f6d:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  104f70:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104f73:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104f76:	85 d2                	test   %edx,%edx
  104f78:	79 1a                	jns    104f94 <vprintfmt+0x23c>
				num = -(intmax_t) num;
  104f7a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104f7d:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104f80:	f7 d8                	neg    %eax
  104f82:	83 d2 00             	adc    $0x0,%edx
  104f85:	f7 da                	neg    %edx
  104f87:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104f8a:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  104f8d:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  104f94:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104f9b:	00 
  104f9c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104f9f:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104fa2:	89 44 24 04          	mov    %eax,0x4(%esp)
  104fa6:	89 54 24 08          	mov    %edx,0x8(%esp)
  104faa:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104fad:	89 04 24             	mov    %eax,(%esp)
  104fb0:	e8 3b fd ff ff       	call   104cf0 <putint>
			break;
  104fb5:	e9 2a 01 00 00       	jmp    1050e4 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  104fba:	8d 45 14             	lea    0x14(%ebp),%eax
  104fbd:	89 44 24 04          	mov    %eax,0x4(%esp)
  104fc1:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104fc4:	89 04 24             	mov    %eax,(%esp)
  104fc7:	e8 6c fa ff ff       	call   104a38 <getuint>
  104fcc:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  104fd3:	00 
  104fd4:	89 44 24 04          	mov    %eax,0x4(%esp)
  104fd8:	89 54 24 08          	mov    %edx,0x8(%esp)
  104fdc:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104fdf:	89 04 24             	mov    %eax,(%esp)
  104fe2:	e8 09 fd ff ff       	call   104cf0 <putint>
			break;
  104fe7:	e9 f8 00 00 00       	jmp    1050e4 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  104fec:	8d 45 14             	lea    0x14(%ebp),%eax
  104fef:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ff3:	8d 45 c8             	lea    -0x38(%ebp),%eax
  104ff6:	89 04 24             	mov    %eax,(%esp)
  104ff9:	e8 3a fa ff ff       	call   104a38 <getuint>
  104ffe:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  105005:	00 
  105006:	89 44 24 04          	mov    %eax,0x4(%esp)
  10500a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10500e:	8d 45 c8             	lea    -0x38(%ebp),%eax
  105011:	89 04 24             	mov    %eax,(%esp)
  105014:	e8 d7 fc ff ff       	call   104cf0 <putint>
			break;
  105019:	e9 c6 00 00 00       	jmp    1050e4 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10501e:	8d 45 14             	lea    0x14(%ebp),%eax
  105021:	89 44 24 04          	mov    %eax,0x4(%esp)
  105025:	8d 45 c8             	lea    -0x38(%ebp),%eax
  105028:	89 04 24             	mov    %eax,(%esp)
  10502b:	e8 08 fa ff ff       	call   104a38 <getuint>
  105030:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  105037:	00 
  105038:	89 44 24 04          	mov    %eax,0x4(%esp)
  10503c:	89 54 24 08          	mov    %edx,0x8(%esp)
  105040:	8d 45 c8             	lea    -0x38(%ebp),%eax
  105043:	89 04 24             	mov    %eax,(%esp)
  105046:	e8 a5 fc ff ff       	call   104cf0 <putint>
			break;
  10504b:	e9 94 00 00 00       	jmp    1050e4 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  105050:	8b 45 0c             	mov    0xc(%ebp),%eax
  105053:	89 44 24 04          	mov    %eax,0x4(%esp)
  105057:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10505e:	8b 45 08             	mov    0x8(%ebp),%eax
  105061:	ff d0                	call   *%eax
			putch('x', putdat);
  105063:	8b 45 0c             	mov    0xc(%ebp),%eax
  105066:	89 44 24 04          	mov    %eax,0x4(%esp)
  10506a:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  105071:	8b 45 08             	mov    0x8(%ebp),%eax
  105074:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  105076:	8b 45 14             	mov    0x14(%ebp),%eax
  105079:	83 c0 04             	add    $0x4,%eax
  10507c:	89 45 14             	mov    %eax,0x14(%ebp)
  10507f:	8b 45 14             	mov    0x14(%ebp),%eax
  105082:	83 e8 04             	sub    $0x4,%eax
  105085:	8b 00                	mov    (%eax),%eax
  105087:	ba 00 00 00 00       	mov    $0x0,%edx
  10508c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  105093:	00 
  105094:	89 44 24 04          	mov    %eax,0x4(%esp)
  105098:	89 54 24 08          	mov    %edx,0x8(%esp)
  10509c:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10509f:	89 04 24             	mov    %eax,(%esp)
  1050a2:	e8 49 fc ff ff       	call   104cf0 <putint>
			break;
  1050a7:	eb 3b                	jmp    1050e4 <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  1050a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050b0:	89 1c 24             	mov    %ebx,(%esp)
  1050b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1050b6:	ff d0                	call   *%eax
			break;
  1050b8:	eb 2a                	jmp    1050e4 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1050ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050c1:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  1050c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1050cb:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  1050cd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1050d1:	eb 04                	jmp    1050d7 <vprintfmt+0x37f>
  1050d3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1050d7:	8b 45 10             	mov    0x10(%ebp),%eax
  1050da:	83 e8 01             	sub    $0x1,%eax
  1050dd:	0f b6 00             	movzbl (%eax),%eax
  1050e0:	3c 25                	cmp    $0x25,%al
  1050e2:	75 ef                	jne    1050d3 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  1050e4:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1050e5:	e9 bd fc ff ff       	jmp    104da7 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  1050ea:	83 c4 44             	add    $0x44,%esp
  1050ed:	5b                   	pop    %ebx
  1050ee:	5d                   	pop    %ebp
  1050ef:	c3                   	ret    

001050f0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  1050f0:	55                   	push   %ebp
  1050f1:	89 e5                	mov    %esp,%ebp
  1050f3:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  1050f6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1050f9:	8b 00                	mov    (%eax),%eax
  1050fb:	8b 55 08             	mov    0x8(%ebp),%edx
  1050fe:	89 d1                	mov    %edx,%ecx
  105100:	8b 55 0c             	mov    0xc(%ebp),%edx
  105103:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  105107:	8d 50 01             	lea    0x1(%eax),%edx
  10510a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10510d:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  10510f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105112:	8b 00                	mov    (%eax),%eax
  105114:	3d ff 00 00 00       	cmp    $0xff,%eax
  105119:	75 24                	jne    10513f <putch+0x4f>
		b->buf[b->idx] = 0;
  10511b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10511e:	8b 00                	mov    (%eax),%eax
  105120:	8b 55 0c             	mov    0xc(%ebp),%edx
  105123:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  105128:	8b 45 0c             	mov    0xc(%ebp),%eax
  10512b:	83 c0 08             	add    $0x8,%eax
  10512e:	89 04 24             	mov    %eax,(%esp)
  105131:	e8 c2 b2 ff ff       	call   1003f8 <cputs>
		b->idx = 0;
  105136:	8b 45 0c             	mov    0xc(%ebp),%eax
  105139:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  10513f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105142:	8b 40 04             	mov    0x4(%eax),%eax
  105145:	8d 50 01             	lea    0x1(%eax),%edx
  105148:	8b 45 0c             	mov    0xc(%ebp),%eax
  10514b:	89 50 04             	mov    %edx,0x4(%eax)
}
  10514e:	c9                   	leave  
  10514f:	c3                   	ret    

00105150 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  105150:	55                   	push   %ebp
  105151:	89 e5                	mov    %esp,%ebp
  105153:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  105159:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  105160:	00 00 00 
	b.cnt = 0;
  105163:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  10516a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  10516d:	b8 f0 50 10 00       	mov    $0x1050f0,%eax
  105172:	8b 55 0c             	mov    0xc(%ebp),%edx
  105175:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105179:	8b 55 08             	mov    0x8(%ebp),%edx
  10517c:	89 54 24 08          	mov    %edx,0x8(%esp)
  105180:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  105186:	89 54 24 04          	mov    %edx,0x4(%esp)
  10518a:	89 04 24             	mov    %eax,(%esp)
  10518d:	e8 c6 fb ff ff       	call   104d58 <vprintfmt>

	b.buf[b.idx] = 0;
  105192:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  105198:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  10519f:	00 
	cputs(b.buf);
  1051a0:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1051a6:	83 c0 08             	add    $0x8,%eax
  1051a9:	89 04 24             	mov    %eax,(%esp)
  1051ac:	e8 47 b2 ff ff       	call   1003f8 <cputs>

	return b.cnt;
  1051b1:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  1051b7:	c9                   	leave  
  1051b8:	c3                   	ret    

001051b9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1051b9:	55                   	push   %ebp
  1051ba:	89 e5                	mov    %esp,%ebp
  1051bc:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  1051bf:	8d 45 08             	lea    0x8(%ebp),%eax
  1051c2:	83 c0 04             	add    $0x4,%eax
  1051c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  1051c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1051cb:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1051ce:	89 54 24 04          	mov    %edx,0x4(%esp)
  1051d2:	89 04 24             	mov    %eax,(%esp)
  1051d5:	e8 76 ff ff ff       	call   105150 <vcprintf>
  1051da:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  1051dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1051e0:	c9                   	leave  
  1051e1:	c3                   	ret    

001051e2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  1051e2:	55                   	push   %ebp
  1051e3:	89 e5                	mov    %esp,%ebp
  1051e5:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  1051e8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1051ef:	eb 08                	jmp    1051f9 <strlen+0x17>
		n++;
  1051f1:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  1051f5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1051f9:	8b 45 08             	mov    0x8(%ebp),%eax
  1051fc:	0f b6 00             	movzbl (%eax),%eax
  1051ff:	84 c0                	test   %al,%al
  105201:	75 ee                	jne    1051f1 <strlen+0xf>
		n++;
	return n;
  105203:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  105206:	c9                   	leave  
  105207:	c3                   	ret    

00105208 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  105208:	55                   	push   %ebp
  105209:	89 e5                	mov    %esp,%ebp
  10520b:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  10520e:	8b 45 08             	mov    0x8(%ebp),%eax
  105211:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  105214:	8b 45 0c             	mov    0xc(%ebp),%eax
  105217:	0f b6 10             	movzbl (%eax),%edx
  10521a:	8b 45 08             	mov    0x8(%ebp),%eax
  10521d:	88 10                	mov    %dl,(%eax)
  10521f:	8b 45 08             	mov    0x8(%ebp),%eax
  105222:	0f b6 00             	movzbl (%eax),%eax
  105225:	84 c0                	test   %al,%al
  105227:	0f 95 c0             	setne  %al
  10522a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10522e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  105232:	84 c0                	test   %al,%al
  105234:	75 de                	jne    105214 <strcpy+0xc>
		/* do nothing */;
	return ret;
  105236:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  105239:	c9                   	leave  
  10523a:	c3                   	ret    

0010523b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  10523b:	55                   	push   %ebp
  10523c:	89 e5                	mov    %esp,%ebp
  10523e:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  105241:	8b 45 08             	mov    0x8(%ebp),%eax
  105244:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  105247:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  10524e:	eb 21                	jmp    105271 <strncpy+0x36>
		*dst++ = *src;
  105250:	8b 45 0c             	mov    0xc(%ebp),%eax
  105253:	0f b6 10             	movzbl (%eax),%edx
  105256:	8b 45 08             	mov    0x8(%ebp),%eax
  105259:	88 10                	mov    %dl,(%eax)
  10525b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  10525f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105262:	0f b6 00             	movzbl (%eax),%eax
  105265:	84 c0                	test   %al,%al
  105267:	74 04                	je     10526d <strncpy+0x32>
			src++;
  105269:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  10526d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  105271:	8b 45 f8             	mov    -0x8(%ebp),%eax
  105274:	3b 45 10             	cmp    0x10(%ebp),%eax
  105277:	72 d7                	jb     105250 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  105279:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10527c:	c9                   	leave  
  10527d:	c3                   	ret    

0010527e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  10527e:	55                   	push   %ebp
  10527f:	89 e5                	mov    %esp,%ebp
  105281:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  105284:	8b 45 08             	mov    0x8(%ebp),%eax
  105287:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  10528a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10528e:	74 2f                	je     1052bf <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  105290:	eb 13                	jmp    1052a5 <strlcpy+0x27>
			*dst++ = *src++;
  105292:	8b 45 0c             	mov    0xc(%ebp),%eax
  105295:	0f b6 10             	movzbl (%eax),%edx
  105298:	8b 45 08             	mov    0x8(%ebp),%eax
  10529b:	88 10                	mov    %dl,(%eax)
  10529d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1052a1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  1052a5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1052a9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1052ad:	74 0a                	je     1052b9 <strlcpy+0x3b>
  1052af:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052b2:	0f b6 00             	movzbl (%eax),%eax
  1052b5:	84 c0                	test   %al,%al
  1052b7:	75 d9                	jne    105292 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  1052b9:	8b 45 08             	mov    0x8(%ebp),%eax
  1052bc:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  1052bf:	8b 55 08             	mov    0x8(%ebp),%edx
  1052c2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1052c5:	89 d1                	mov    %edx,%ecx
  1052c7:	29 c1                	sub    %eax,%ecx
  1052c9:	89 c8                	mov    %ecx,%eax
}
  1052cb:	c9                   	leave  
  1052cc:	c3                   	ret    

001052cd <strcmp>:

int
strcmp(const char *p, const char *q)
{
  1052cd:	55                   	push   %ebp
  1052ce:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  1052d0:	eb 08                	jmp    1052da <strcmp+0xd>
		p++, q++;
  1052d2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1052d6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  1052da:	8b 45 08             	mov    0x8(%ebp),%eax
  1052dd:	0f b6 00             	movzbl (%eax),%eax
  1052e0:	84 c0                	test   %al,%al
  1052e2:	74 10                	je     1052f4 <strcmp+0x27>
  1052e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1052e7:	0f b6 10             	movzbl (%eax),%edx
  1052ea:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052ed:	0f b6 00             	movzbl (%eax),%eax
  1052f0:	38 c2                	cmp    %al,%dl
  1052f2:	74 de                	je     1052d2 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  1052f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1052f7:	0f b6 00             	movzbl (%eax),%eax
  1052fa:	0f b6 d0             	movzbl %al,%edx
  1052fd:	8b 45 0c             	mov    0xc(%ebp),%eax
  105300:	0f b6 00             	movzbl (%eax),%eax
  105303:	0f b6 c0             	movzbl %al,%eax
  105306:	89 d1                	mov    %edx,%ecx
  105308:	29 c1                	sub    %eax,%ecx
  10530a:	89 c8                	mov    %ecx,%eax
}
  10530c:	5d                   	pop    %ebp
  10530d:	c3                   	ret    

0010530e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  10530e:	55                   	push   %ebp
  10530f:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  105311:	eb 0c                	jmp    10531f <strncmp+0x11>
		n--, p++, q++;
  105313:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  105317:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10531b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  10531f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105323:	74 1a                	je     10533f <strncmp+0x31>
  105325:	8b 45 08             	mov    0x8(%ebp),%eax
  105328:	0f b6 00             	movzbl (%eax),%eax
  10532b:	84 c0                	test   %al,%al
  10532d:	74 10                	je     10533f <strncmp+0x31>
  10532f:	8b 45 08             	mov    0x8(%ebp),%eax
  105332:	0f b6 10             	movzbl (%eax),%edx
  105335:	8b 45 0c             	mov    0xc(%ebp),%eax
  105338:	0f b6 00             	movzbl (%eax),%eax
  10533b:	38 c2                	cmp    %al,%dl
  10533d:	74 d4                	je     105313 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  10533f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105343:	75 07                	jne    10534c <strncmp+0x3e>
		return 0;
  105345:	b8 00 00 00 00       	mov    $0x0,%eax
  10534a:	eb 18                	jmp    105364 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  10534c:	8b 45 08             	mov    0x8(%ebp),%eax
  10534f:	0f b6 00             	movzbl (%eax),%eax
  105352:	0f b6 d0             	movzbl %al,%edx
  105355:	8b 45 0c             	mov    0xc(%ebp),%eax
  105358:	0f b6 00             	movzbl (%eax),%eax
  10535b:	0f b6 c0             	movzbl %al,%eax
  10535e:	89 d1                	mov    %edx,%ecx
  105360:	29 c1                	sub    %eax,%ecx
  105362:	89 c8                	mov    %ecx,%eax
}
  105364:	5d                   	pop    %ebp
  105365:	c3                   	ret    

00105366 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  105366:	55                   	push   %ebp
  105367:	89 e5                	mov    %esp,%ebp
  105369:	83 ec 04             	sub    $0x4,%esp
  10536c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10536f:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  105372:	eb 1a                	jmp    10538e <strchr+0x28>
		if (*s++ == 0)
  105374:	8b 45 08             	mov    0x8(%ebp),%eax
  105377:	0f b6 00             	movzbl (%eax),%eax
  10537a:	84 c0                	test   %al,%al
  10537c:	0f 94 c0             	sete   %al
  10537f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105383:	84 c0                	test   %al,%al
  105385:	74 07                	je     10538e <strchr+0x28>
			return NULL;
  105387:	b8 00 00 00 00       	mov    $0x0,%eax
  10538c:	eb 0e                	jmp    10539c <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  10538e:	8b 45 08             	mov    0x8(%ebp),%eax
  105391:	0f b6 00             	movzbl (%eax),%eax
  105394:	3a 45 fc             	cmp    -0x4(%ebp),%al
  105397:	75 db                	jne    105374 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  105399:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10539c:	c9                   	leave  
  10539d:	c3                   	ret    

0010539e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  10539e:	55                   	push   %ebp
  10539f:	89 e5                	mov    %esp,%ebp
  1053a1:	57                   	push   %edi
  1053a2:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  1053a5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1053a9:	75 05                	jne    1053b0 <memset+0x12>
		return v;
  1053ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1053ae:	eb 5c                	jmp    10540c <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  1053b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1053b3:	83 e0 03             	and    $0x3,%eax
  1053b6:	85 c0                	test   %eax,%eax
  1053b8:	75 41                	jne    1053fb <memset+0x5d>
  1053ba:	8b 45 10             	mov    0x10(%ebp),%eax
  1053bd:	83 e0 03             	and    $0x3,%eax
  1053c0:	85 c0                	test   %eax,%eax
  1053c2:	75 37                	jne    1053fb <memset+0x5d>
		c &= 0xFF;
  1053c4:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  1053cb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1053ce:	89 c2                	mov    %eax,%edx
  1053d0:	c1 e2 18             	shl    $0x18,%edx
  1053d3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1053d6:	c1 e0 10             	shl    $0x10,%eax
  1053d9:	09 c2                	or     %eax,%edx
  1053db:	8b 45 0c             	mov    0xc(%ebp),%eax
  1053de:	c1 e0 08             	shl    $0x8,%eax
  1053e1:	09 d0                	or     %edx,%eax
  1053e3:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  1053e6:	8b 45 10             	mov    0x10(%ebp),%eax
  1053e9:	89 c1                	mov    %eax,%ecx
  1053eb:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  1053ee:	8b 55 08             	mov    0x8(%ebp),%edx
  1053f1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1053f4:	89 d7                	mov    %edx,%edi
  1053f6:	fc                   	cld    
  1053f7:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  1053f9:	eb 0e                	jmp    105409 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  1053fb:	8b 55 08             	mov    0x8(%ebp),%edx
  1053fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  105401:	8b 4d 10             	mov    0x10(%ebp),%ecx
  105404:	89 d7                	mov    %edx,%edi
  105406:	fc                   	cld    
  105407:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  105409:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10540c:	83 c4 10             	add    $0x10,%esp
  10540f:	5f                   	pop    %edi
  105410:	5d                   	pop    %ebp
  105411:	c3                   	ret    

00105412 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  105412:	55                   	push   %ebp
  105413:	89 e5                	mov    %esp,%ebp
  105415:	57                   	push   %edi
  105416:	56                   	push   %esi
  105417:	53                   	push   %ebx
  105418:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  10541b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10541e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  105421:	8b 45 08             	mov    0x8(%ebp),%eax
  105424:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  105427:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10542a:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10542d:	73 6e                	jae    10549d <memmove+0x8b>
  10542f:	8b 45 10             	mov    0x10(%ebp),%eax
  105432:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105435:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105438:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10543b:	76 60                	jbe    10549d <memmove+0x8b>
		s += n;
  10543d:	8b 45 10             	mov    0x10(%ebp),%eax
  105440:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  105443:	8b 45 10             	mov    0x10(%ebp),%eax
  105446:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  105449:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10544c:	83 e0 03             	and    $0x3,%eax
  10544f:	85 c0                	test   %eax,%eax
  105451:	75 2f                	jne    105482 <memmove+0x70>
  105453:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105456:	83 e0 03             	and    $0x3,%eax
  105459:	85 c0                	test   %eax,%eax
  10545b:	75 25                	jne    105482 <memmove+0x70>
  10545d:	8b 45 10             	mov    0x10(%ebp),%eax
  105460:	83 e0 03             	and    $0x3,%eax
  105463:	85 c0                	test   %eax,%eax
  105465:	75 1b                	jne    105482 <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  105467:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10546a:	83 e8 04             	sub    $0x4,%eax
  10546d:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105470:	83 ea 04             	sub    $0x4,%edx
  105473:	8b 4d 10             	mov    0x10(%ebp),%ecx
  105476:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  105479:	89 c7                	mov    %eax,%edi
  10547b:	89 d6                	mov    %edx,%esi
  10547d:	fd                   	std    
  10547e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  105480:	eb 18                	jmp    10549a <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  105482:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105485:	8d 50 ff             	lea    -0x1(%eax),%edx
  105488:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10548b:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  10548e:	8b 45 10             	mov    0x10(%ebp),%eax
  105491:	89 d7                	mov    %edx,%edi
  105493:	89 de                	mov    %ebx,%esi
  105495:	89 c1                	mov    %eax,%ecx
  105497:	fd                   	std    
  105498:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  10549a:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  10549b:	eb 45                	jmp    1054e2 <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10549d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1054a0:	83 e0 03             	and    $0x3,%eax
  1054a3:	85 c0                	test   %eax,%eax
  1054a5:	75 2b                	jne    1054d2 <memmove+0xc0>
  1054a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054aa:	83 e0 03             	and    $0x3,%eax
  1054ad:	85 c0                	test   %eax,%eax
  1054af:	75 21                	jne    1054d2 <memmove+0xc0>
  1054b1:	8b 45 10             	mov    0x10(%ebp),%eax
  1054b4:	83 e0 03             	and    $0x3,%eax
  1054b7:	85 c0                	test   %eax,%eax
  1054b9:	75 17                	jne    1054d2 <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  1054bb:	8b 45 10             	mov    0x10(%ebp),%eax
  1054be:	89 c1                	mov    %eax,%ecx
  1054c0:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  1054c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054c6:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1054c9:	89 c7                	mov    %eax,%edi
  1054cb:	89 d6                	mov    %edx,%esi
  1054cd:	fc                   	cld    
  1054ce:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1054d0:	eb 10                	jmp    1054e2 <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  1054d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054d5:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1054d8:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1054db:	89 c7                	mov    %eax,%edi
  1054dd:	89 d6                	mov    %edx,%esi
  1054df:	fc                   	cld    
  1054e0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  1054e2:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1054e5:	83 c4 10             	add    $0x10,%esp
  1054e8:	5b                   	pop    %ebx
  1054e9:	5e                   	pop    %esi
  1054ea:	5f                   	pop    %edi
  1054eb:	5d                   	pop    %ebp
  1054ec:	c3                   	ret    

001054ed <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  1054ed:	55                   	push   %ebp
  1054ee:	89 e5                	mov    %esp,%ebp
  1054f0:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  1054f3:	8b 45 10             	mov    0x10(%ebp),%eax
  1054f6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1054fa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1054fd:	89 44 24 04          	mov    %eax,0x4(%esp)
  105501:	8b 45 08             	mov    0x8(%ebp),%eax
  105504:	89 04 24             	mov    %eax,(%esp)
  105507:	e8 06 ff ff ff       	call   105412 <memmove>
}
  10550c:	c9                   	leave  
  10550d:	c3                   	ret    

0010550e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  10550e:	55                   	push   %ebp
  10550f:	89 e5                	mov    %esp,%ebp
  105511:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  105514:	8b 45 08             	mov    0x8(%ebp),%eax
  105517:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  10551a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10551d:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  105520:	eb 32                	jmp    105554 <memcmp+0x46>
		if (*s1 != *s2)
  105522:	8b 45 f8             	mov    -0x8(%ebp),%eax
  105525:	0f b6 10             	movzbl (%eax),%edx
  105528:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10552b:	0f b6 00             	movzbl (%eax),%eax
  10552e:	38 c2                	cmp    %al,%dl
  105530:	74 1a                	je     10554c <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  105532:	8b 45 f8             	mov    -0x8(%ebp),%eax
  105535:	0f b6 00             	movzbl (%eax),%eax
  105538:	0f b6 d0             	movzbl %al,%edx
  10553b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10553e:	0f b6 00             	movzbl (%eax),%eax
  105541:	0f b6 c0             	movzbl %al,%eax
  105544:	89 d1                	mov    %edx,%ecx
  105546:	29 c1                	sub    %eax,%ecx
  105548:	89 c8                	mov    %ecx,%eax
  10554a:	eb 1c                	jmp    105568 <memcmp+0x5a>
		s1++, s2++;
  10554c:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  105550:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  105554:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105558:	0f 95 c0             	setne  %al
  10555b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10555f:	84 c0                	test   %al,%al
  105561:	75 bf                	jne    105522 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  105563:	b8 00 00 00 00       	mov    $0x0,%eax
}
  105568:	c9                   	leave  
  105569:	c3                   	ret    

0010556a <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  10556a:	55                   	push   %ebp
  10556b:	89 e5                	mov    %esp,%ebp
  10556d:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  105570:	8b 45 10             	mov    0x10(%ebp),%eax
  105573:	8b 55 08             	mov    0x8(%ebp),%edx
  105576:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105579:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  10557c:	eb 16                	jmp    105594 <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  10557e:	8b 45 08             	mov    0x8(%ebp),%eax
  105581:	0f b6 10             	movzbl (%eax),%edx
  105584:	8b 45 0c             	mov    0xc(%ebp),%eax
  105587:	38 c2                	cmp    %al,%dl
  105589:	75 05                	jne    105590 <memchr+0x26>
			return (void *) s;
  10558b:	8b 45 08             	mov    0x8(%ebp),%eax
  10558e:	eb 11                	jmp    1055a1 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  105590:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  105594:	8b 45 08             	mov    0x8(%ebp),%eax
  105597:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  10559a:	72 e2                	jb     10557e <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  10559c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1055a1:	c9                   	leave  
  1055a2:	c3                   	ret    
  1055a3:	66 90                	xchg   %ax,%ax
  1055a5:	66 90                	xchg   %ax,%ax
  1055a7:	66 90                	xchg   %ax,%ax
  1055a9:	66 90                	xchg   %ax,%ax
  1055ab:	66 90                	xchg   %ax,%ax
  1055ad:	66 90                	xchg   %ax,%ax
  1055af:	90                   	nop

001055b0 <__udivdi3>:
  1055b0:	55                   	push   %ebp
  1055b1:	89 e5                	mov    %esp,%ebp
  1055b3:	57                   	push   %edi
  1055b4:	56                   	push   %esi
  1055b5:	83 ec 10             	sub    $0x10,%esp
  1055b8:	8b 45 14             	mov    0x14(%ebp),%eax
  1055bb:	8b 55 08             	mov    0x8(%ebp),%edx
  1055be:	8b 75 10             	mov    0x10(%ebp),%esi
  1055c1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  1055c4:	85 c0                	test   %eax,%eax
  1055c6:	89 55 f0             	mov    %edx,-0x10(%ebp)
  1055c9:	75 35                	jne    105600 <__udivdi3+0x50>
  1055cb:	39 fe                	cmp    %edi,%esi
  1055cd:	77 61                	ja     105630 <__udivdi3+0x80>
  1055cf:	85 f6                	test   %esi,%esi
  1055d1:	75 0b                	jne    1055de <__udivdi3+0x2e>
  1055d3:	b8 01 00 00 00       	mov    $0x1,%eax
  1055d8:	31 d2                	xor    %edx,%edx
  1055da:	f7 f6                	div    %esi
  1055dc:	89 c6                	mov    %eax,%esi
  1055de:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1055e1:	31 d2                	xor    %edx,%edx
  1055e3:	89 f8                	mov    %edi,%eax
  1055e5:	f7 f6                	div    %esi
  1055e7:	89 c7                	mov    %eax,%edi
  1055e9:	89 c8                	mov    %ecx,%eax
  1055eb:	f7 f6                	div    %esi
  1055ed:	89 c1                	mov    %eax,%ecx
  1055ef:	89 fa                	mov    %edi,%edx
  1055f1:	89 c8                	mov    %ecx,%eax
  1055f3:	83 c4 10             	add    $0x10,%esp
  1055f6:	5e                   	pop    %esi
  1055f7:	5f                   	pop    %edi
  1055f8:	5d                   	pop    %ebp
  1055f9:	c3                   	ret    
  1055fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  105600:	39 f8                	cmp    %edi,%eax
  105602:	77 1c                	ja     105620 <__udivdi3+0x70>
  105604:	0f bd d0             	bsr    %eax,%edx
  105607:	83 f2 1f             	xor    $0x1f,%edx
  10560a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10560d:	75 39                	jne    105648 <__udivdi3+0x98>
  10560f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  105612:	0f 86 a0 00 00 00    	jbe    1056b8 <__udivdi3+0x108>
  105618:	39 f8                	cmp    %edi,%eax
  10561a:	0f 82 98 00 00 00    	jb     1056b8 <__udivdi3+0x108>
  105620:	31 ff                	xor    %edi,%edi
  105622:	31 c9                	xor    %ecx,%ecx
  105624:	89 c8                	mov    %ecx,%eax
  105626:	89 fa                	mov    %edi,%edx
  105628:	83 c4 10             	add    $0x10,%esp
  10562b:	5e                   	pop    %esi
  10562c:	5f                   	pop    %edi
  10562d:	5d                   	pop    %ebp
  10562e:	c3                   	ret    
  10562f:	90                   	nop
  105630:	89 d1                	mov    %edx,%ecx
  105632:	89 fa                	mov    %edi,%edx
  105634:	89 c8                	mov    %ecx,%eax
  105636:	31 ff                	xor    %edi,%edi
  105638:	f7 f6                	div    %esi
  10563a:	89 c1                	mov    %eax,%ecx
  10563c:	89 fa                	mov    %edi,%edx
  10563e:	89 c8                	mov    %ecx,%eax
  105640:	83 c4 10             	add    $0x10,%esp
  105643:	5e                   	pop    %esi
  105644:	5f                   	pop    %edi
  105645:	5d                   	pop    %ebp
  105646:	c3                   	ret    
  105647:	90                   	nop
  105648:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10564c:	89 f2                	mov    %esi,%edx
  10564e:	d3 e0                	shl    %cl,%eax
  105650:	89 45 ec             	mov    %eax,-0x14(%ebp)
  105653:	b8 20 00 00 00       	mov    $0x20,%eax
  105658:	2b 45 f4             	sub    -0xc(%ebp),%eax
  10565b:	89 c1                	mov    %eax,%ecx
  10565d:	d3 ea                	shr    %cl,%edx
  10565f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  105663:	0b 55 ec             	or     -0x14(%ebp),%edx
  105666:	d3 e6                	shl    %cl,%esi
  105668:	89 c1                	mov    %eax,%ecx
  10566a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  10566d:	89 fe                	mov    %edi,%esi
  10566f:	d3 ee                	shr    %cl,%esi
  105671:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  105675:	89 55 ec             	mov    %edx,-0x14(%ebp)
  105678:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10567b:	d3 e7                	shl    %cl,%edi
  10567d:	89 c1                	mov    %eax,%ecx
  10567f:	d3 ea                	shr    %cl,%edx
  105681:	09 d7                	or     %edx,%edi
  105683:	89 f2                	mov    %esi,%edx
  105685:	89 f8                	mov    %edi,%eax
  105687:	f7 75 ec             	divl   -0x14(%ebp)
  10568a:	89 d6                	mov    %edx,%esi
  10568c:	89 c7                	mov    %eax,%edi
  10568e:	f7 65 e8             	mull   -0x18(%ebp)
  105691:	39 d6                	cmp    %edx,%esi
  105693:	89 55 ec             	mov    %edx,-0x14(%ebp)
  105696:	72 30                	jb     1056c8 <__udivdi3+0x118>
  105698:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10569b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10569f:	d3 e2                	shl    %cl,%edx
  1056a1:	39 c2                	cmp    %eax,%edx
  1056a3:	73 05                	jae    1056aa <__udivdi3+0xfa>
  1056a5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  1056a8:	74 1e                	je     1056c8 <__udivdi3+0x118>
  1056aa:	89 f9                	mov    %edi,%ecx
  1056ac:	31 ff                	xor    %edi,%edi
  1056ae:	e9 71 ff ff ff       	jmp    105624 <__udivdi3+0x74>
  1056b3:	90                   	nop
  1056b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1056b8:	31 ff                	xor    %edi,%edi
  1056ba:	b9 01 00 00 00       	mov    $0x1,%ecx
  1056bf:	e9 60 ff ff ff       	jmp    105624 <__udivdi3+0x74>
  1056c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1056c8:	8d 4f ff             	lea    -0x1(%edi),%ecx
  1056cb:	31 ff                	xor    %edi,%edi
  1056cd:	89 c8                	mov    %ecx,%eax
  1056cf:	89 fa                	mov    %edi,%edx
  1056d1:	83 c4 10             	add    $0x10,%esp
  1056d4:	5e                   	pop    %esi
  1056d5:	5f                   	pop    %edi
  1056d6:	5d                   	pop    %ebp
  1056d7:	c3                   	ret    
  1056d8:	66 90                	xchg   %ax,%ax
  1056da:	66 90                	xchg   %ax,%ax
  1056dc:	66 90                	xchg   %ax,%ax
  1056de:	66 90                	xchg   %ax,%ax

001056e0 <__umoddi3>:
  1056e0:	55                   	push   %ebp
  1056e1:	89 e5                	mov    %esp,%ebp
  1056e3:	57                   	push   %edi
  1056e4:	56                   	push   %esi
  1056e5:	83 ec 20             	sub    $0x20,%esp
  1056e8:	8b 55 14             	mov    0x14(%ebp),%edx
  1056eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1056ee:	8b 7d 10             	mov    0x10(%ebp),%edi
  1056f1:	8b 75 0c             	mov    0xc(%ebp),%esi
  1056f4:	85 d2                	test   %edx,%edx
  1056f6:	89 c8                	mov    %ecx,%eax
  1056f8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  1056fb:	75 13                	jne    105710 <__umoddi3+0x30>
  1056fd:	39 f7                	cmp    %esi,%edi
  1056ff:	76 3f                	jbe    105740 <__umoddi3+0x60>
  105701:	89 f2                	mov    %esi,%edx
  105703:	f7 f7                	div    %edi
  105705:	89 d0                	mov    %edx,%eax
  105707:	31 d2                	xor    %edx,%edx
  105709:	83 c4 20             	add    $0x20,%esp
  10570c:	5e                   	pop    %esi
  10570d:	5f                   	pop    %edi
  10570e:	5d                   	pop    %ebp
  10570f:	c3                   	ret    
  105710:	39 f2                	cmp    %esi,%edx
  105712:	77 4c                	ja     105760 <__umoddi3+0x80>
  105714:	0f bd ca             	bsr    %edx,%ecx
  105717:	83 f1 1f             	xor    $0x1f,%ecx
  10571a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  10571d:	75 51                	jne    105770 <__umoddi3+0x90>
  10571f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  105722:	0f 87 e0 00 00 00    	ja     105808 <__umoddi3+0x128>
  105728:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10572b:	29 f8                	sub    %edi,%eax
  10572d:	19 d6                	sbb    %edx,%esi
  10572f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  105732:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105735:	89 f2                	mov    %esi,%edx
  105737:	83 c4 20             	add    $0x20,%esp
  10573a:	5e                   	pop    %esi
  10573b:	5f                   	pop    %edi
  10573c:	5d                   	pop    %ebp
  10573d:	c3                   	ret    
  10573e:	66 90                	xchg   %ax,%ax
  105740:	85 ff                	test   %edi,%edi
  105742:	75 0b                	jne    10574f <__umoddi3+0x6f>
  105744:	b8 01 00 00 00       	mov    $0x1,%eax
  105749:	31 d2                	xor    %edx,%edx
  10574b:	f7 f7                	div    %edi
  10574d:	89 c7                	mov    %eax,%edi
  10574f:	89 f0                	mov    %esi,%eax
  105751:	31 d2                	xor    %edx,%edx
  105753:	f7 f7                	div    %edi
  105755:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105758:	f7 f7                	div    %edi
  10575a:	eb a9                	jmp    105705 <__umoddi3+0x25>
  10575c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105760:	89 c8                	mov    %ecx,%eax
  105762:	89 f2                	mov    %esi,%edx
  105764:	83 c4 20             	add    $0x20,%esp
  105767:	5e                   	pop    %esi
  105768:	5f                   	pop    %edi
  105769:	5d                   	pop    %ebp
  10576a:	c3                   	ret    
  10576b:	90                   	nop
  10576c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105770:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  105774:	d3 e2                	shl    %cl,%edx
  105776:	89 55 f4             	mov    %edx,-0xc(%ebp)
  105779:	ba 20 00 00 00       	mov    $0x20,%edx
  10577e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  105781:	89 55 ec             	mov    %edx,-0x14(%ebp)
  105784:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  105788:	89 fa                	mov    %edi,%edx
  10578a:	d3 ea                	shr    %cl,%edx
  10578c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  105790:	0b 55 f4             	or     -0xc(%ebp),%edx
  105793:	d3 e7                	shl    %cl,%edi
  105795:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  105799:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10579c:	89 f2                	mov    %esi,%edx
  10579e:	89 7d e8             	mov    %edi,-0x18(%ebp)
  1057a1:	89 c7                	mov    %eax,%edi
  1057a3:	d3 ea                	shr    %cl,%edx
  1057a5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1057a9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1057ac:	89 c2                	mov    %eax,%edx
  1057ae:	d3 e6                	shl    %cl,%esi
  1057b0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1057b4:	d3 ea                	shr    %cl,%edx
  1057b6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1057ba:	09 d6                	or     %edx,%esi
  1057bc:	89 f0                	mov    %esi,%eax
  1057be:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  1057c1:	d3 e7                	shl    %cl,%edi
  1057c3:	89 f2                	mov    %esi,%edx
  1057c5:	f7 75 f4             	divl   -0xc(%ebp)
  1057c8:	89 d6                	mov    %edx,%esi
  1057ca:	f7 65 e8             	mull   -0x18(%ebp)
  1057cd:	39 d6                	cmp    %edx,%esi
  1057cf:	72 2b                	jb     1057fc <__umoddi3+0x11c>
  1057d1:	39 c7                	cmp    %eax,%edi
  1057d3:	72 23                	jb     1057f8 <__umoddi3+0x118>
  1057d5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1057d9:	29 c7                	sub    %eax,%edi
  1057db:	19 d6                	sbb    %edx,%esi
  1057dd:	89 f0                	mov    %esi,%eax
  1057df:	89 f2                	mov    %esi,%edx
  1057e1:	d3 ef                	shr    %cl,%edi
  1057e3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1057e7:	d3 e0                	shl    %cl,%eax
  1057e9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1057ed:	09 f8                	or     %edi,%eax
  1057ef:	d3 ea                	shr    %cl,%edx
  1057f1:	83 c4 20             	add    $0x20,%esp
  1057f4:	5e                   	pop    %esi
  1057f5:	5f                   	pop    %edi
  1057f6:	5d                   	pop    %ebp
  1057f7:	c3                   	ret    
  1057f8:	39 d6                	cmp    %edx,%esi
  1057fa:	75 d9                	jne    1057d5 <__umoddi3+0xf5>
  1057fc:	2b 45 e8             	sub    -0x18(%ebp),%eax
  1057ff:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  105802:	eb d1                	jmp    1057d5 <__umoddi3+0xf5>
  105804:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  105808:	39 f2                	cmp    %esi,%edx
  10580a:	0f 82 18 ff ff ff    	jb     105728 <__umoddi3+0x48>
  105810:	e9 1d ff ff ff       	jmp    105732 <__umoddi3+0x52>
