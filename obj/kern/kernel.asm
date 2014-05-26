
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
  10001a:	bc 00 50 10 00       	mov    $0x105000,%esp

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
  100043:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100049:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10004e:	74 24                	je     100074 <cpu_cur+0x4e>
  100050:	c7 44 24 0c 40 2e 10 	movl   $0x102e40,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 56 2e 10 	movl   $0x102e56,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 6b 2e 10 00 	movl   $0x102e6b,(%esp)
  10006f:	e8 15 03 00 00       	call   100389 <debug_panic>
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
  100084:	3d 00 40 10 00       	cmp    $0x104000,%eax
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
  1000a2:	ba 28 70 30 00       	mov    $0x307028,%edx
  1000a7:	b8 b0 55 10 00       	mov    $0x1055b0,%eax
  1000ac:	89 d1                	mov    %edx,%ecx
  1000ae:	29 c1                	sub    %eax,%ecx
  1000b0:	89 c8                	mov    %ecx,%eax
  1000b2:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bd:	00 
  1000be:	c7 04 24 b0 55 10 00 	movl   $0x1055b0,(%esp)
  1000c5:	e8 e5 28 00 00       	call   1029af <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000ca:	e8 49 02 00 00       	call   100318 <cons_init>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  1000cf:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  1000d6:	00 
  1000d7:	c7 04 24 78 2e 10 00 	movl   $0x102e78,(%esp)
  1000de:	e8 e7 26 00 00       	call   1027ca <cprintf>
	debug_check();
  1000e3:	e8 0c 05 00 00       	call   1005f4 <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000e8:	e8 07 0f 00 00       	call   100ff4 <cpu_init>
	trap_init();
  1000ed:	e8 e4 11 00 00       	call   1012d6 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000f2:	e8 b2 07 00 00       	call   1008a9 <mem_init>

	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.

	cprintf("before tt\n");
  1000f7:	c7 04 24 93 2e 10 00 	movl   $0x102e93,(%esp)
  1000fe:	e8 c7 26 00 00       	call   1027ca <cprintf>
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
	};
  100103:	8d 5d ac             	lea    -0x54(%ebp),%ebx
  100106:	b8 00 00 00 00       	mov    $0x0,%eax
  10010b:	ba 13 00 00 00       	mov    $0x13,%edx
  100110:	89 df                	mov    %ebx,%edi
  100112:	89 d1                	mov    %edx,%ecx
  100114:	f3 ab                	rep stos %eax,%es:(%edi)
  100116:	66 c7 45 cc 23 00    	movw   $0x23,-0x34(%ebp)
  10011c:	66 c7 45 d0 23 00    	movw   $0x23,-0x30(%ebp)
  100122:	66 c7 45 d4 23 00    	movw   $0x23,-0x2c(%ebp)
  100128:	66 c7 45 d8 23 00    	movw   $0x23,-0x28(%ebp)

	cprintf("before tt\n");

	trapframe tt = {
		cs: CPU_GDT_UCODE | 3,
		eip: (uint32_t)(user),
  10012e:	b8 5c 01 10 00       	mov    $0x10015c,%eax
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
	};
  100133:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100136:	66 c7 45 e8 1b 00    	movw   $0x1b,-0x18(%ebp)
  10013c:	c7 45 ec 00 30 00 00 	movl   $0x3000,-0x14(%ebp)
		fs: CPU_GDT_UDATA | 3,
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
  100143:	b8 c0 65 10 00       	mov    $0x1065c0,%eax
	};
  100148:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10014b:	66 c7 45 f4 23 00    	movw   $0x23,-0xc(%ebp)
	
	trap_return(&tt);
  100151:	8d 45 ac             	lea    -0x54(%ebp),%eax
  100154:	89 04 24             	mov    %eax,(%esp)
  100157:	e8 24 4f 00 00       	call   105080 <trap_return>

0010015c <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  10015c:	55                   	push   %ebp
  10015d:	89 e5                	mov    %esp,%ebp
  10015f:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  100162:	c7 04 24 9e 2e 10 00 	movl   $0x102e9e,(%esp)
  100169:	e8 5c 26 00 00       	call   1027ca <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10016e:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  100171:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  100174:	89 c2                	mov    %eax,%edx
  100176:	b8 c0 55 10 00       	mov    $0x1055c0,%eax
  10017b:	39 c2                	cmp    %eax,%edx
  10017d:	77 24                	ja     1001a3 <user+0x47>
  10017f:	c7 44 24 0c ac 2e 10 	movl   $0x102eac,0xc(%esp)
  100186:	00 
  100187:	c7 44 24 08 56 2e 10 	movl   $0x102e56,0x8(%esp)
  10018e:	00 
  10018f:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  100196:	00 
  100197:	c7 04 24 d3 2e 10 00 	movl   $0x102ed3,(%esp)
  10019e:	e8 e6 01 00 00       	call   100389 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001a3:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1001a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  1001a9:	89 c2                	mov    %eax,%edx
  1001ab:	b8 c0 65 10 00       	mov    $0x1065c0,%eax
  1001b0:	39 c2                	cmp    %eax,%edx
  1001b2:	72 24                	jb     1001d8 <user+0x7c>
  1001b4:	c7 44 24 0c e0 2e 10 	movl   $0x102ee0,0xc(%esp)
  1001bb:	00 
  1001bc:	c7 44 24 08 56 2e 10 	movl   $0x102e56,0x8(%esp)
  1001c3:	00 
  1001c4:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1001cb:	00 
  1001cc:	c7 04 24 d3 2e 10 00 	movl   $0x102ed3,(%esp)
  1001d3:	e8 b1 01 00 00       	call   100389 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  1001d8:	e8 ff 13 00 00       	call   1015dc <trap_check_user>

	done();
  1001dd:	e8 00 00 00 00       	call   1001e2 <done>

001001e2 <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  1001e2:	55                   	push   %ebp
  1001e3:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  1001e5:	eb fe                	jmp    1001e5 <done+0x3>

001001e7 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1001e7:	55                   	push   %ebp
  1001e8:	89 e5                	mov    %esp,%ebp
  1001ea:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001ed:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1001f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1001f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1001f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1001f9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1001fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100201:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100204:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  10020a:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10020f:	74 24                	je     100235 <cpu_cur+0x4e>
  100211:	c7 44 24 0c 18 2f 10 	movl   $0x102f18,0xc(%esp)
  100218:	00 
  100219:	c7 44 24 08 2e 2f 10 	movl   $0x102f2e,0x8(%esp)
  100220:	00 
  100221:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100228:	00 
  100229:	c7 04 24 43 2f 10 00 	movl   $0x102f43,(%esp)
  100230:	e8 54 01 00 00       	call   100389 <debug_panic>
	return c;
  100235:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100238:	c9                   	leave  
  100239:	c3                   	ret    

0010023a <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10023a:	55                   	push   %ebp
  10023b:	89 e5                	mov    %esp,%ebp
  10023d:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100240:	e8 a2 ff ff ff       	call   1001e7 <cpu_cur>
  100245:	3d 00 40 10 00       	cmp    $0x104000,%eax
  10024a:	0f 94 c0             	sete   %al
  10024d:	0f b6 c0             	movzbl %al,%eax
}
  100250:	c9                   	leave  
  100251:	c3                   	ret    

00100252 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  100252:	55                   	push   %ebp
  100253:	89 e5                	mov    %esp,%ebp
  100255:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
  100258:	eb 35                	jmp    10028f <cons_intr+0x3d>
		if (c == 0)
  10025a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10025e:	74 2e                	je     10028e <cons_intr+0x3c>
			continue;
		cons.buf[cons.wpos++] = c;
  100260:	a1 c4 67 10 00       	mov    0x1067c4,%eax
  100265:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100268:	88 90 c0 65 10 00    	mov    %dl,0x1065c0(%eax)
  10026e:	83 c0 01             	add    $0x1,%eax
  100271:	a3 c4 67 10 00       	mov    %eax,0x1067c4
		if (cons.wpos == CONSBUFSIZE)
  100276:	a1 c4 67 10 00       	mov    0x1067c4,%eax
  10027b:	3d 00 02 00 00       	cmp    $0x200,%eax
  100280:	75 0d                	jne    10028f <cons_intr+0x3d>
			cons.wpos = 0;
  100282:	c7 05 c4 67 10 00 00 	movl   $0x0,0x1067c4
  100289:	00 00 00 
  10028c:	eb 01                	jmp    10028f <cons_intr+0x3d>
{
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  10028e:	90                   	nop
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
  10028f:	8b 45 08             	mov    0x8(%ebp),%eax
  100292:	ff d0                	call   *%eax
  100294:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100297:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  10029b:	75 bd                	jne    10025a <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
  10029d:	c9                   	leave  
  10029e:	c3                   	ret    

0010029f <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  10029f:	55                   	push   %ebp
  1002a0:	89 e5                	mov    %esp,%ebp
  1002a2:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  1002a5:	e8 b3 1b 00 00       	call   101e5d <serial_intr>
	kbd_intr();
  1002aa:	e8 09 1b 00 00       	call   101db8 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  1002af:	8b 15 c0 67 10 00    	mov    0x1067c0,%edx
  1002b5:	a1 c4 67 10 00       	mov    0x1067c4,%eax
  1002ba:	39 c2                	cmp    %eax,%edx
  1002bc:	74 35                	je     1002f3 <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  1002be:	a1 c0 67 10 00       	mov    0x1067c0,%eax
  1002c3:	0f b6 90 c0 65 10 00 	movzbl 0x1065c0(%eax),%edx
  1002ca:	0f b6 d2             	movzbl %dl,%edx
  1002cd:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1002d0:	83 c0 01             	add    $0x1,%eax
  1002d3:	a3 c0 67 10 00       	mov    %eax,0x1067c0
		if (cons.rpos == CONSBUFSIZE)
  1002d8:	a1 c0 67 10 00       	mov    0x1067c0,%eax
  1002dd:	3d 00 02 00 00       	cmp    $0x200,%eax
  1002e2:	75 0a                	jne    1002ee <cons_getc+0x4f>
			cons.rpos = 0;
  1002e4:	c7 05 c0 67 10 00 00 	movl   $0x0,0x1067c0
  1002eb:	00 00 00 
		return c;
  1002ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1002f1:	eb 05                	jmp    1002f8 <cons_getc+0x59>
	}
	return 0;
  1002f3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1002f8:	c9                   	leave  
  1002f9:	c3                   	ret    

001002fa <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  1002fa:	55                   	push   %ebp
  1002fb:	89 e5                	mov    %esp,%ebp
  1002fd:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  100300:	8b 45 08             	mov    0x8(%ebp),%eax
  100303:	89 04 24             	mov    %eax,(%esp)
  100306:	e8 6f 1b 00 00       	call   101e7a <serial_putc>
	video_putc(c);
  10030b:	8b 45 08             	mov    0x8(%ebp),%eax
  10030e:	89 04 24             	mov    %eax,(%esp)
  100311:	e8 01 17 00 00       	call   101a17 <video_putc>
}
  100316:	c9                   	leave  
  100317:	c3                   	ret    

00100318 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100318:	55                   	push   %ebp
  100319:	89 e5                	mov    %esp,%ebp
  10031b:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10031e:	e8 17 ff ff ff       	call   10023a <cpu_onboot>
  100323:	85 c0                	test   %eax,%eax
  100325:	74 36                	je     10035d <cons_init+0x45>
		return;

	video_init();
  100327:	e8 1f 16 00 00       	call   10194b <video_init>
	kbd_init();
  10032c:	e8 9b 1a 00 00       	call   101dcc <kbd_init>
	serial_init();
  100331:	e8 a9 1b 00 00       	call   101edf <serial_init>

	if (!serial_exists)
  100336:	a1 24 70 30 00       	mov    0x307024,%eax
  10033b:	85 c0                	test   %eax,%eax
  10033d:	75 1f                	jne    10035e <cons_init+0x46>
		warn("Serial port does not exist!\n");
  10033f:	c7 44 24 08 50 2f 10 	movl   $0x102f50,0x8(%esp)
  100346:	00 
  100347:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  10034e:	00 
  10034f:	c7 04 24 6d 2f 10 00 	movl   $0x102f6d,(%esp)
  100356:	e8 ed 00 00 00       	call   100448 <debug_warn>
  10035b:	eb 01                	jmp    10035e <cons_init+0x46>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  10035d:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  10035e:	c9                   	leave  
  10035f:	c3                   	ret    

00100360 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  100360:	55                   	push   %ebp
  100361:	89 e5                	mov    %esp,%ebp
  100363:	83 ec 28             	sub    $0x28,%esp
	char ch;
	while (*str)
  100366:	eb 15                	jmp    10037d <cputs+0x1d>
		cons_putc(*str++);
  100368:	8b 45 08             	mov    0x8(%ebp),%eax
  10036b:	0f b6 00             	movzbl (%eax),%eax
  10036e:	0f be c0             	movsbl %al,%eax
  100371:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100375:	89 04 24             	mov    %eax,(%esp)
  100378:	e8 7d ff ff ff       	call   1002fa <cons_putc>
// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
	char ch;
	while (*str)
  10037d:	8b 45 08             	mov    0x8(%ebp),%eax
  100380:	0f b6 00             	movzbl (%eax),%eax
  100383:	84 c0                	test   %al,%al
  100385:	75 e1                	jne    100368 <cputs+0x8>
		cons_putc(*str++);
}
  100387:	c9                   	leave  
  100388:	c3                   	ret    

00100389 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100389:	55                   	push   %ebp
  10038a:	89 e5                	mov    %esp,%ebp
  10038c:	83 ec 58             	sub    $0x58,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10038f:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  100392:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  100396:	0f b7 c0             	movzwl %ax,%eax
  100399:	83 e0 03             	and    $0x3,%eax
  10039c:	85 c0                	test   %eax,%eax
  10039e:	75 15                	jne    1003b5 <debug_panic+0x2c>
		if (panicstr)
  1003a0:	a1 c8 67 10 00       	mov    0x1067c8,%eax
  1003a5:	85 c0                	test   %eax,%eax
  1003a7:	0f 85 95 00 00 00    	jne    100442 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  1003ad:	8b 45 10             	mov    0x10(%ebp),%eax
  1003b0:	a3 c8 67 10 00       	mov    %eax,0x1067c8
	}

	// First print the requested message
	va_start(ap, fmt);
  1003b5:	8d 45 10             	lea    0x10(%ebp),%eax
  1003b8:	83 c0 04             	add    $0x4,%eax
  1003bb:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  1003be:	8b 45 0c             	mov    0xc(%ebp),%eax
  1003c1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1003c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1003c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003cc:	c7 04 24 79 2f 10 00 	movl   $0x102f79,(%esp)
  1003d3:	e8 f2 23 00 00       	call   1027ca <cprintf>
	vcprintf(fmt, ap);
  1003d8:	8b 45 10             	mov    0x10(%ebp),%eax
  1003db:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1003de:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003e2:	89 04 24             	mov    %eax,(%esp)
  1003e5:	e8 77 23 00 00       	call   102761 <vcprintf>
	cprintf("\n");
  1003ea:	c7 04 24 91 2f 10 00 	movl   $0x102f91,(%esp)
  1003f1:	e8 d4 23 00 00       	call   1027ca <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1003f6:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  1003f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1003fc:	8d 55 c0             	lea    -0x40(%ebp),%edx
  1003ff:	89 54 24 04          	mov    %edx,0x4(%esp)
  100403:	89 04 24             	mov    %eax,(%esp)
  100406:	e8 86 00 00 00       	call   100491 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  10040b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100412:	eb 1b                	jmp    10042f <debug_panic+0xa6>
		cprintf("  from %08x\n", eips[i]);
  100414:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100417:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  10041b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10041f:	c7 04 24 93 2f 10 00 	movl   $0x102f93,(%esp)
  100426:	e8 9f 23 00 00       	call   1027ca <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  10042b:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  10042f:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  100433:	7f 0e                	jg     100443 <debug_panic+0xba>
  100435:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100438:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  10043c:	85 c0                	test   %eax,%eax
  10043e:	75 d4                	jne    100414 <debug_panic+0x8b>
  100440:	eb 01                	jmp    100443 <debug_panic+0xba>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  100442:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  100443:	e8 9a fd ff ff       	call   1001e2 <done>

00100448 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  100448:	55                   	push   %ebp
  100449:	89 e5                	mov    %esp,%ebp
  10044b:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  10044e:	8d 45 10             	lea    0x10(%ebp),%eax
  100451:	83 c0 04             	add    $0x4,%eax
  100454:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100457:	8b 45 0c             	mov    0xc(%ebp),%eax
  10045a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10045e:	8b 45 08             	mov    0x8(%ebp),%eax
  100461:	89 44 24 04          	mov    %eax,0x4(%esp)
  100465:	c7 04 24 a0 2f 10 00 	movl   $0x102fa0,(%esp)
  10046c:	e8 59 23 00 00       	call   1027ca <cprintf>
	vcprintf(fmt, ap);
  100471:	8b 45 10             	mov    0x10(%ebp),%eax
  100474:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100477:	89 54 24 04          	mov    %edx,0x4(%esp)
  10047b:	89 04 24             	mov    %eax,(%esp)
  10047e:	e8 de 22 00 00       	call   102761 <vcprintf>
	cprintf("\n");
  100483:	c7 04 24 91 2f 10 00 	movl   $0x102f91,(%esp)
  10048a:	e8 3b 23 00 00       	call   1027ca <cprintf>
	va_end(ap);
}
  10048f:	c9                   	leave  
  100490:	c3                   	ret    

00100491 <debug_trace>:

// Riecord the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100491:	55                   	push   %ebp
  100492:	89 e5                	mov    %esp,%ebp
  100494:	83 ec 28             	sub    $0x28,%esp
	uint32_t* ebp_addr;
	uint32_t eip;

	ebp_addr = (uint32_t*) ebp;
  100497:	8b 45 08             	mov    0x8(%ebp),%eax
  10049a:	89 45 e8             	mov    %eax,-0x18(%ebp)

	int x = 0;
  10049d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	cprintf("Stack backtrace:\n");
  1004a4:	c7 04 24 ba 2f 10 00 	movl   $0x102fba,(%esp)
  1004ab:	e8 1a 23 00 00       	call   1027ca <cprintf>

	while(*ebp_addr >= 0)
	{

		eip = ebp_addr[1];
  1004b0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1004b3:	83 c0 04             	add    $0x4,%eax
  1004b6:	8b 00                	mov    (%eax),%eax
  1004b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
		eips[x++] = eip;
  1004bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004be:	c1 e0 02             	shl    $0x2,%eax
  1004c1:	03 45 0c             	add    0xc(%ebp),%eax
  1004c4:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1004c7:	89 10                	mov    %edx,(%eax)
  1004c9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)

		cprintf("ebp 0x%08x eip 0x%08x", *ebp_addr, eip);
  1004cd:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1004d0:	8b 00                	mov    (%eax),%eax
  1004d2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1004d5:	89 54 24 08          	mov    %edx,0x8(%esp)
  1004d9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004dd:	c7 04 24 cc 2f 10 00 	movl   $0x102fcc,(%esp)
  1004e4:	e8 e1 22 00 00       	call   1027ca <cprintf>

		int y = 0;
  1004e9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

		cprintf(" args");
  1004f0:	c7 04 24 e2 2f 10 00 	movl   $0x102fe2,(%esp)
  1004f7:	e8 ce 22 00 00       	call   1027ca <cprintf>

		for(; y < 5; y++)
  1004fc:	eb 22                	jmp    100520 <debug_trace+0x8f>
		{
			cprintf(" %08x", ebp_addr[2 + y]);
  1004fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100501:	83 c0 02             	add    $0x2,%eax
  100504:	c1 e0 02             	shl    $0x2,%eax
  100507:	03 45 e8             	add    -0x18(%ebp),%eax
  10050a:	8b 00                	mov    (%eax),%eax
  10050c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100510:	c7 04 24 e8 2f 10 00 	movl   $0x102fe8,(%esp)
  100517:	e8 ae 22 00 00       	call   1027ca <cprintf>

		int y = 0;

		cprintf(" args");

		for(; y < 5; y++)
  10051c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100520:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  100524:	7e d8                	jle    1004fe <debug_trace+0x6d>
		{
			cprintf(" %08x", ebp_addr[2 + y]);
		}

		cprintf("\n");
  100526:	c7 04 24 91 2f 10 00 	movl   $0x102f91,(%esp)
  10052d:	e8 98 22 00 00       	call   1027ca <cprintf>

		if(*ebp_addr == 0)
  100532:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100535:	8b 00                	mov    (%eax),%eax
  100537:	85 c0                	test   %eax,%eax
  100539:	75 1d                	jne    100558 <debug_trace+0xc7>
		{
			for(; x < 10; x++)
  10053b:	eb 13                	jmp    100550 <debug_trace+0xbf>
				eips[x] = 0;
  10053d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100540:	c1 e0 02             	shl    $0x2,%eax
  100543:	03 45 0c             	add    0xc(%ebp),%eax
  100546:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

		cprintf("\n");

		if(*ebp_addr == 0)
		{
			for(; x < 10; x++)
  10054c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100550:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  100554:	7e e7                	jle    10053d <debug_trace+0xac>
  100556:	eb 0d                	jmp    100565 <debug_trace+0xd4>
				eips[x] = 0;
			break;
		}

		ebp_addr = (uint32_t*) (*ebp_addr);
  100558:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10055b:	8b 00                	mov    (%eax),%eax
  10055d:	89 45 e8             	mov    %eax,-0x18(%ebp)
	}
  100560:	e9 4b ff ff ff       	jmp    1004b0 <debug_trace+0x1f>

	return;
	//panic("debug_trace not implemented");
}
  100565:	c9                   	leave  
  100566:	c3                   	ret    

00100567 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100567:	55                   	push   %ebp
  100568:	89 e5                	mov    %esp,%ebp
  10056a:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10056d:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  100570:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100573:	8b 55 0c             	mov    0xc(%ebp),%edx
  100576:	89 54 24 04          	mov    %edx,0x4(%esp)
  10057a:	89 04 24             	mov    %eax,(%esp)
  10057d:	e8 0f ff ff ff       	call   100491 <debug_trace>
  100582:	c9                   	leave  
  100583:	c3                   	ret    

00100584 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100584:	55                   	push   %ebp
  100585:	89 e5                	mov    %esp,%ebp
  100587:	83 ec 18             	sub    $0x18,%esp
  10058a:	8b 45 08             	mov    0x8(%ebp),%eax
  10058d:	83 e0 02             	and    $0x2,%eax
  100590:	85 c0                	test   %eax,%eax
  100592:	74 14                	je     1005a8 <f2+0x24>
  100594:	8b 45 0c             	mov    0xc(%ebp),%eax
  100597:	89 44 24 04          	mov    %eax,0x4(%esp)
  10059b:	8b 45 08             	mov    0x8(%ebp),%eax
  10059e:	89 04 24             	mov    %eax,(%esp)
  1005a1:	e8 c1 ff ff ff       	call   100567 <f3>
  1005a6:	eb 12                	jmp    1005ba <f2+0x36>
  1005a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005af:	8b 45 08             	mov    0x8(%ebp),%eax
  1005b2:	89 04 24             	mov    %eax,(%esp)
  1005b5:	e8 ad ff ff ff       	call   100567 <f3>
  1005ba:	c9                   	leave  
  1005bb:	c3                   	ret    

001005bc <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  1005bc:	55                   	push   %ebp
  1005bd:	89 e5                	mov    %esp,%ebp
  1005bf:	83 ec 18             	sub    $0x18,%esp
  1005c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1005c5:	83 e0 01             	and    $0x1,%eax
  1005c8:	84 c0                	test   %al,%al
  1005ca:	74 14                	je     1005e0 <f1+0x24>
  1005cc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005cf:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005d3:	8b 45 08             	mov    0x8(%ebp),%eax
  1005d6:	89 04 24             	mov    %eax,(%esp)
  1005d9:	e8 a6 ff ff ff       	call   100584 <f2>
  1005de:	eb 12                	jmp    1005f2 <f1+0x36>
  1005e0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005e3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1005ea:	89 04 24             	mov    %eax,(%esp)
  1005ed:	e8 92 ff ff ff       	call   100584 <f2>
  1005f2:	c9                   	leave  
  1005f3:	c3                   	ret    

001005f4 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  1005f4:	55                   	push   %ebp
  1005f5:	89 e5                	mov    %esp,%ebp
  1005f7:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1005fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100604:	eb 29                	jmp    10062f <debug_check+0x3b>
		f1(i, eips[i]);
  100606:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  10060c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10060f:	89 d0                	mov    %edx,%eax
  100611:	c1 e0 02             	shl    $0x2,%eax
  100614:	01 d0                	add    %edx,%eax
  100616:	c1 e0 03             	shl    $0x3,%eax
  100619:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  10061c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100620:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100623:	89 04 24             	mov    %eax,(%esp)
  100626:	e8 91 ff ff ff       	call   1005bc <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  10062b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10062f:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  100633:	7e d1                	jle    100606 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100635:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  10063c:	e9 bc 00 00 00       	jmp    1006fd <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100641:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100648:	e9 a2 00 00 00       	jmp    1006ef <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  10064d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100650:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100653:	89 d0                	mov    %edx,%eax
  100655:	c1 e0 02             	shl    $0x2,%eax
  100658:	01 d0                	add    %edx,%eax
  10065a:	01 c0                	add    %eax,%eax
  10065c:	01 c8                	add    %ecx,%eax
  10065e:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100665:	85 c0                	test   %eax,%eax
  100667:	0f 95 c2             	setne  %dl
  10066a:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  10066e:	0f 9e c0             	setle  %al
  100671:	31 d0                	xor    %edx,%eax
  100673:	84 c0                	test   %al,%al
  100675:	74 24                	je     10069b <debug_check+0xa7>
  100677:	c7 44 24 0c ee 2f 10 	movl   $0x102fee,0xc(%esp)
  10067e:	00 
  10067f:	c7 44 24 08 0b 30 10 	movl   $0x10300b,0x8(%esp)
  100686:	00 
  100687:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
  10068e:	00 
  10068f:	c7 04 24 20 30 10 00 	movl   $0x103020,(%esp)
  100696:	e8 ee fc ff ff       	call   100389 <debug_panic>
			if (i >= 2)
  10069b:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  10069f:	7e 4a                	jle    1006eb <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  1006a1:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1006a4:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  1006a7:	89 d0                	mov    %edx,%eax
  1006a9:	c1 e0 02             	shl    $0x2,%eax
  1006ac:	01 d0                	add    %edx,%eax
  1006ae:	01 c0                	add    %eax,%eax
  1006b0:	01 c8                	add    %ecx,%eax
  1006b2:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  1006b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006bc:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  1006c3:	39 c2                	cmp    %eax,%edx
  1006c5:	74 24                	je     1006eb <debug_check+0xf7>
  1006c7:	c7 44 24 0c 2d 30 10 	movl   $0x10302d,0xc(%esp)
  1006ce:	00 
  1006cf:	c7 44 24 08 0b 30 10 	movl   $0x10300b,0x8(%esp)
  1006d6:	00 
  1006d7:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  1006de:	00 
  1006df:	c7 04 24 20 30 10 00 	movl   $0x103020,(%esp)
  1006e6:	e8 9e fc ff ff       	call   100389 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1006eb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1006ef:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1006f3:	0f 8e 54 ff ff ff    	jle    10064d <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1006f9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1006fd:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  100701:	0f 8e 3a ff ff ff    	jle    100641 <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  100707:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  10070d:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  100713:	39 c2                	cmp    %eax,%edx
  100715:	74 24                	je     10073b <debug_check+0x147>
  100717:	c7 44 24 0c 46 30 10 	movl   $0x103046,0xc(%esp)
  10071e:	00 
  10071f:	c7 44 24 08 0b 30 10 	movl   $0x10300b,0x8(%esp)
  100726:	00 
  100727:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
  10072e:	00 
  10072f:	c7 04 24 20 30 10 00 	movl   $0x103020,(%esp)
  100736:	e8 4e fc ff ff       	call   100389 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  10073b:	8b 55 a0             	mov    -0x60(%ebp),%edx
  10073e:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100741:	39 c2                	cmp    %eax,%edx
  100743:	74 24                	je     100769 <debug_check+0x175>
  100745:	c7 44 24 0c 5f 30 10 	movl   $0x10305f,0xc(%esp)
  10074c:	00 
  10074d:	c7 44 24 08 0b 30 10 	movl   $0x10300b,0x8(%esp)
  100754:	00 
  100755:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  10075c:	00 
  10075d:	c7 04 24 20 30 10 00 	movl   $0x103020,(%esp)
  100764:	e8 20 fc ff ff       	call   100389 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100769:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  10076f:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100772:	39 c2                	cmp    %eax,%edx
  100774:	75 24                	jne    10079a <debug_check+0x1a6>
  100776:	c7 44 24 0c 78 30 10 	movl   $0x103078,0xc(%esp)
  10077d:	00 
  10077e:	c7 44 24 08 0b 30 10 	movl   $0x10300b,0x8(%esp)
  100785:	00 
  100786:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  10078d:	00 
  10078e:	c7 04 24 20 30 10 00 	movl   $0x103020,(%esp)
  100795:	e8 ef fb ff ff       	call   100389 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10079a:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1007a0:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  1007a3:	39 c2                	cmp    %eax,%edx
  1007a5:	74 24                	je     1007cb <debug_check+0x1d7>
  1007a7:	c7 44 24 0c 91 30 10 	movl   $0x103091,0xc(%esp)
  1007ae:	00 
  1007af:	c7 44 24 08 0b 30 10 	movl   $0x10300b,0x8(%esp)
  1007b6:	00 
  1007b7:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  1007be:	00 
  1007bf:	c7 04 24 20 30 10 00 	movl   $0x103020,(%esp)
  1007c6:	e8 be fb ff ff       	call   100389 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  1007cb:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  1007d1:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1007d4:	39 c2                	cmp    %eax,%edx
  1007d6:	74 24                	je     1007fc <debug_check+0x208>
  1007d8:	c7 44 24 0c aa 30 10 	movl   $0x1030aa,0xc(%esp)
  1007df:	00 
  1007e0:	c7 44 24 08 0b 30 10 	movl   $0x10300b,0x8(%esp)
  1007e7:	00 
  1007e8:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  1007ef:	00 
  1007f0:	c7 04 24 20 30 10 00 	movl   $0x103020,(%esp)
  1007f7:	e8 8d fb ff ff       	call   100389 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  1007fc:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100802:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  100808:	39 c2                	cmp    %eax,%edx
  10080a:	75 24                	jne    100830 <debug_check+0x23c>
  10080c:	c7 44 24 0c c3 30 10 	movl   $0x1030c3,0xc(%esp)
  100813:	00 
  100814:	c7 44 24 08 0b 30 10 	movl   $0x10300b,0x8(%esp)
  10081b:	00 
  10081c:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  100823:	00 
  100824:	c7 04 24 20 30 10 00 	movl   $0x103020,(%esp)
  10082b:	e8 59 fb ff ff       	call   100389 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100830:	c7 04 24 dc 30 10 00 	movl   $0x1030dc,(%esp)
  100837:	e8 8e 1f 00 00       	call   1027ca <cprintf>
}
  10083c:	c9                   	leave  
  10083d:	c3                   	ret    

0010083e <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10083e:	55                   	push   %ebp
  10083f:	89 e5                	mov    %esp,%ebp
  100841:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100844:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100847:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10084a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10084d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100850:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100855:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100858:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10085b:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100861:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100866:	74 24                	je     10088c <cpu_cur+0x4e>
  100868:	c7 44 24 0c f8 30 10 	movl   $0x1030f8,0xc(%esp)
  10086f:	00 
  100870:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100877:	00 
  100878:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10087f:	00 
  100880:	c7 04 24 23 31 10 00 	movl   $0x103123,(%esp)
  100887:	e8 fd fa ff ff       	call   100389 <debug_panic>
	return c;
  10088c:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10088f:	c9                   	leave  
  100890:	c3                   	ret    

00100891 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100891:	55                   	push   %ebp
  100892:	89 e5                	mov    %esp,%ebp
  100894:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100897:	e8 a2 ff ff ff       	call   10083e <cpu_cur>
  10089c:	3d 00 40 10 00       	cmp    $0x104000,%eax
  1008a1:	0f 94 c0             	sete   %al
  1008a4:	0f b6 c0             	movzbl %al,%eax
}
  1008a7:	c9                   	leave  
  1008a8:	c3                   	ret    

001008a9 <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  1008a9:	55                   	push   %ebp
  1008aa:	89 e5                	mov    %esp,%ebp
  1008ac:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1008af:	e8 dd ff ff ff       	call   100891 <cpu_onboot>
  1008b4:	85 c0                	test   %eax,%eax
  1008b6:	0f 84 a0 01 00 00    	je     100a5c <mem_init+0x1b3>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  1008bc:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  1008c3:	e8 1c 17 00 00       	call   101fe4 <nvram_read16>
  1008c8:	c1 e0 0a             	shl    $0xa,%eax
  1008cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1008ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1008d1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008d6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  1008d9:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  1008e0:	e8 ff 16 00 00       	call   101fe4 <nvram_read16>
  1008e5:	c1 e0 0a             	shl    $0xa,%eax
  1008e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1008eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1008ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008f3:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  1008f6:	c7 44 24 08 30 31 10 	movl   $0x103130,0x8(%esp)
  1008fd:	00 
  1008fe:	c7 44 24 04 31 00 00 	movl   $0x31,0x4(%esp)
  100905:	00 
  100906:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  10090d:	e8 36 fb ff ff       	call   100448 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100912:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100919:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10091c:	05 00 00 10 00       	add    $0x100000,%eax
  100921:	a3 08 70 10 00       	mov    %eax,0x107008

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100926:	a1 08 70 10 00       	mov    0x107008,%eax
  10092b:	c1 e8 0c             	shr    $0xc,%eax
  10092e:	a3 04 70 10 00       	mov    %eax,0x107004

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100933:	a1 08 70 10 00       	mov    0x107008,%eax
  100938:	c1 e8 0a             	shr    $0xa,%eax
  10093b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10093f:	c7 04 24 5c 31 10 00 	movl   $0x10315c,(%esp)
  100946:	e8 7f 1e 00 00       	call   1027ca <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  10094b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10094e:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100951:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  100953:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100956:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100959:	89 54 24 08          	mov    %edx,0x8(%esp)
  10095d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100961:	c7 04 24 7d 31 10 00 	movl   $0x10317d,(%esp)
  100968:	e8 5d 1e 00 00       	call   1027ca <cprintf>


	extern char start[], end[];
	uint32_t page_start;
	
	pageinfo **freetail = &mem_freelist;
  10096d:	c7 45 e8 00 70 10 00 	movl   $0x107000,-0x18(%ebp)
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100974:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10097b:	00 
  10097c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100983:	00 
  100984:	c7 04 24 20 70 10 00 	movl   $0x107020,(%esp)
  10098b:	e8 1f 20 00 00       	call   1029af <memset>
	mem_pageinfo = spc_for_pi;
  100990:	c7 05 20 70 30 00 20 	movl   $0x107020,0x307020
  100997:	70 10 00 
	int i;
	for (i = 0; i < mem_npage; i++) {
  10099a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1009a1:	e9 96 00 00 00       	jmp    100a3c <mem_init+0x193>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  1009a6:	a1 20 70 30 00       	mov    0x307020,%eax
  1009ab:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1009ae:	c1 e2 03             	shl    $0x3,%edx
  1009b1:	01 d0                	add    %edx,%eax
  1009b3:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		if(i == 0 || i == 1)
  1009ba:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1009be:	74 6e                	je     100a2e <mem_init+0x185>
  1009c0:	83 7d ec 01          	cmpl   $0x1,-0x14(%ebp)
  1009c4:	74 6b                	je     100a31 <mem_init+0x188>
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);
  1009c6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1009c9:	c1 e0 03             	shl    $0x3,%eax
  1009cc:	c1 f8 03             	sar    $0x3,%eax
  1009cf:	c1 e0 0c             	shl    $0xc,%eax
  1009d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  1009d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1009d8:	05 00 10 00 00       	add    $0x1000,%eax
  1009dd:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  1009e2:	76 09                	jbe    1009ed <mem_init+0x144>
  1009e4:	81 7d e4 ff ff 0f 00 	cmpl   $0xfffff,-0x1c(%ebp)
  1009eb:	76 47                	jbe    100a34 <mem_init+0x18b>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  1009ed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1009f0:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
  1009f6:	b8 0c 00 10 00       	mov    $0x10000c,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  1009fb:	39 c2                	cmp    %eax,%edx
  1009fd:	72 0a                	jb     100a09 <mem_init+0x160>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  1009ff:	b8 28 70 30 00       	mov    $0x307028,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100a04:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  100a07:	72 2e                	jb     100a37 <mem_init+0x18e>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;


		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100a09:	a1 20 70 30 00       	mov    0x307020,%eax
  100a0e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a11:	c1 e2 03             	shl    $0x3,%edx
  100a14:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100a17:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a1a:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100a1c:	a1 20 70 30 00       	mov    0x307020,%eax
  100a21:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a24:	c1 e2 03             	shl    $0x3,%edx
  100a27:	01 d0                	add    %edx,%eax
  100a29:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100a2c:	eb 0a                	jmp    100a38 <mem_init+0x18f>
	for (i = 0; i < mem_npage; i++) {
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;

		if(i == 0 || i == 1)
			continue;
  100a2e:	90                   	nop
  100a2f:	eb 07                	jmp    100a38 <mem_init+0x18f>
  100a31:	90                   	nop
  100a32:	eb 04                	jmp    100a38 <mem_init+0x18f>

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;
  100a34:	90                   	nop
  100a35:	eb 01                	jmp    100a38 <mem_init+0x18f>
  100a37:	90                   	nop
	
	pageinfo **freetail = &mem_freelist;
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
	mem_pageinfo = spc_for_pi;
	int i;
	for (i = 0; i < mem_npage; i++) {
  100a38:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100a3c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100a3f:	a1 04 70 10 00       	mov    0x107004,%eax
  100a44:	39 c2                	cmp    %eax,%edx
  100a46:	0f 82 5a ff ff ff    	jb     1009a6 <mem_init+0xfd>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100a4c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a4f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100a55:	e8 71 00 00 00       	call   100acb <mem_check>
  100a5a:	eb 01                	jmp    100a5d <mem_init+0x1b4>

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100a5c:	90                   	nop
	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100a5d:	c9                   	leave  
  100a5e:	c3                   	ret    

00100a5f <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  100a5f:	55                   	push   %ebp
  100a60:	89 e5                	mov    %esp,%ebp
  100a62:	83 ec 10             	sub    $0x10,%esp
	// Fill this function in
	// Fill this function in.
	//panic("mem_alloc not implemented.");

	if(mem_freelist == NULL)
  100a65:	a1 00 70 10 00       	mov    0x107000,%eax
  100a6a:	85 c0                	test   %eax,%eax
  100a6c:	75 07                	jne    100a75 <mem_alloc+0x16>
		return NULL;
  100a6e:	b8 00 00 00 00       	mov    $0x0,%eax
  100a73:	eb 17                	jmp    100a8c <mem_alloc+0x2d>
	pageinfo* r = mem_freelist;
  100a75:	a1 00 70 10 00       	mov    0x107000,%eax
  100a7a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	mem_freelist = mem_freelist->free_next;
  100a7d:	a1 00 70 10 00       	mov    0x107000,%eax
  100a82:	8b 00                	mov    (%eax),%eax
  100a84:	a3 00 70 10 00       	mov    %eax,0x107000
	return r;
  100a89:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  100a8c:	c9                   	leave  
  100a8d:	c3                   	ret    

00100a8e <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100a8e:	55                   	push   %ebp
  100a8f:	89 e5                	mov    %esp,%ebp
  100a91:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");

	if(pi == NULL)
  100a94:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100a98:	75 1c                	jne    100ab6 <mem_free+0x28>
		panic("null for page which to be freed!"); 
  100a9a:	c7 44 24 08 9c 31 10 	movl   $0x10319c,0x8(%esp)
  100aa1:	00 
  100aa2:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  100aa9:	00 
  100aaa:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100ab1:	e8 d3 f8 ff ff       	call   100389 <debug_panic>

	pi->free_next = mem_freelist;
  100ab6:	8b 15 00 70 10 00    	mov    0x107000,%edx
  100abc:	8b 45 08             	mov    0x8(%ebp),%eax
  100abf:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100ac1:	8b 45 08             	mov    0x8(%ebp),%eax
  100ac4:	a3 00 70 10 00       	mov    %eax,0x107000
	
}
  100ac9:	c9                   	leave  
  100aca:	c3                   	ret    

00100acb <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100acb:	55                   	push   %ebp
  100acc:	89 e5                	mov    %esp,%ebp
  100ace:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100ad1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100ad8:	a1 00 70 10 00       	mov    0x107000,%eax
  100add:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100ae0:	eb 38                	jmp    100b1a <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100ae2:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100ae5:	a1 20 70 30 00       	mov    0x307020,%eax
  100aea:	89 d1                	mov    %edx,%ecx
  100aec:	29 c1                	sub    %eax,%ecx
  100aee:	89 c8                	mov    %ecx,%eax
  100af0:	c1 f8 03             	sar    $0x3,%eax
  100af3:	c1 e0 0c             	shl    $0xc,%eax
  100af6:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100afd:	00 
  100afe:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100b05:	00 
  100b06:	89 04 24             	mov    %eax,(%esp)
  100b09:	e8 a1 1e 00 00       	call   1029af <memset>
		freepages++;
  100b0e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100b12:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100b15:	8b 00                	mov    (%eax),%eax
  100b17:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100b1a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  100b1e:	75 c2                	jne    100ae2 <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100b23:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b27:	c7 04 24 bd 31 10 00 	movl   $0x1031bd,(%esp)
  100b2e:	e8 97 1c 00 00       	call   1027ca <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100b33:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100b36:	a1 04 70 10 00       	mov    0x107004,%eax
  100b3b:	39 c2                	cmp    %eax,%edx
  100b3d:	72 24                	jb     100b63 <mem_check+0x98>
  100b3f:	c7 44 24 0c d7 31 10 	movl   $0x1031d7,0xc(%esp)
  100b46:	00 
  100b47:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100b4e:	00 
  100b4f:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  100b56:	00 
  100b57:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100b5e:	e8 26 f8 ff ff       	call   100389 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100b63:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100b6a:	7f 24                	jg     100b90 <mem_check+0xc5>
  100b6c:	c7 44 24 0c ed 31 10 	movl   $0x1031ed,0xc(%esp)
  100b73:	00 
  100b74:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100b7b:	00 
  100b7c:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  100b83:	00 
  100b84:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100b8b:	e8 f9 f7 ff ff       	call   100389 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100b90:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100b97:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100b9a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100b9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100ba0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100ba3:	e8 b7 fe ff ff       	call   100a5f <mem_alloc>
  100ba8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100bab:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100baf:	75 24                	jne    100bd5 <mem_check+0x10a>
  100bb1:	c7 44 24 0c ff 31 10 	movl   $0x1031ff,0xc(%esp)
  100bb8:	00 
  100bb9:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100bc0:	00 
  100bc1:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
  100bc8:	00 
  100bc9:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100bd0:	e8 b4 f7 ff ff       	call   100389 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100bd5:	e8 85 fe ff ff       	call   100a5f <mem_alloc>
  100bda:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100bdd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100be1:	75 24                	jne    100c07 <mem_check+0x13c>
  100be3:	c7 44 24 0c 08 32 10 	movl   $0x103208,0xc(%esp)
  100bea:	00 
  100beb:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100bf2:	00 
  100bf3:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
  100bfa:	00 
  100bfb:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100c02:	e8 82 f7 ff ff       	call   100389 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100c07:	e8 53 fe ff ff       	call   100a5f <mem_alloc>
  100c0c:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100c0f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100c13:	75 24                	jne    100c39 <mem_check+0x16e>
  100c15:	c7 44 24 0c 11 32 10 	movl   $0x103211,0xc(%esp)
  100c1c:	00 
  100c1d:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100c24:	00 
  100c25:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
  100c2c:	00 
  100c2d:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100c34:	e8 50 f7 ff ff       	call   100389 <debug_panic>

	assert(pp0);
  100c39:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100c3d:	75 24                	jne    100c63 <mem_check+0x198>
  100c3f:	c7 44 24 0c 1a 32 10 	movl   $0x10321a,0xc(%esp)
  100c46:	00 
  100c47:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100c4e:	00 
  100c4f:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
  100c56:	00 
  100c57:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100c5e:	e8 26 f7 ff ff       	call   100389 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100c63:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100c67:	74 08                	je     100c71 <mem_check+0x1a6>
  100c69:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100c6c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100c6f:	75 24                	jne    100c95 <mem_check+0x1ca>
  100c71:	c7 44 24 0c 1e 32 10 	movl   $0x10321e,0xc(%esp)
  100c78:	00 
  100c79:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100c80:	00 
  100c81:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
  100c88:	00 
  100c89:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100c90:	e8 f4 f6 ff ff       	call   100389 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100c95:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100c99:	74 10                	je     100cab <mem_check+0x1e0>
  100c9b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100c9e:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100ca1:	74 08                	je     100cab <mem_check+0x1e0>
  100ca3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ca6:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100ca9:	75 24                	jne    100ccf <mem_check+0x204>
  100cab:	c7 44 24 0c 30 32 10 	movl   $0x103230,0xc(%esp)
  100cb2:	00 
  100cb3:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100cba:	00 
  100cbb:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
  100cc2:	00 
  100cc3:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100cca:	e8 ba f6 ff ff       	call   100389 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100ccf:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100cd2:	a1 20 70 30 00       	mov    0x307020,%eax
  100cd7:	89 d1                	mov    %edx,%ecx
  100cd9:	29 c1                	sub    %eax,%ecx
  100cdb:	89 c8                	mov    %ecx,%eax
  100cdd:	c1 f8 03             	sar    $0x3,%eax
  100ce0:	c1 e0 0c             	shl    $0xc,%eax
  100ce3:	8b 15 04 70 10 00    	mov    0x107004,%edx
  100ce9:	c1 e2 0c             	shl    $0xc,%edx
  100cec:	39 d0                	cmp    %edx,%eax
  100cee:	72 24                	jb     100d14 <mem_check+0x249>
  100cf0:	c7 44 24 0c 50 32 10 	movl   $0x103250,0xc(%esp)
  100cf7:	00 
  100cf8:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100cff:	00 
  100d00:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
  100d07:	00 
  100d08:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100d0f:	e8 75 f6 ff ff       	call   100389 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100d14:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100d17:	a1 20 70 30 00       	mov    0x307020,%eax
  100d1c:	89 d1                	mov    %edx,%ecx
  100d1e:	29 c1                	sub    %eax,%ecx
  100d20:	89 c8                	mov    %ecx,%eax
  100d22:	c1 f8 03             	sar    $0x3,%eax
  100d25:	c1 e0 0c             	shl    $0xc,%eax
  100d28:	8b 15 04 70 10 00    	mov    0x107004,%edx
  100d2e:	c1 e2 0c             	shl    $0xc,%edx
  100d31:	39 d0                	cmp    %edx,%eax
  100d33:	72 24                	jb     100d59 <mem_check+0x28e>
  100d35:	c7 44 24 0c 78 32 10 	movl   $0x103278,0xc(%esp)
  100d3c:	00 
  100d3d:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100d44:	00 
  100d45:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
  100d4c:	00 
  100d4d:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100d54:	e8 30 f6 ff ff       	call   100389 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100d59:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100d5c:	a1 20 70 30 00       	mov    0x307020,%eax
  100d61:	89 d1                	mov    %edx,%ecx
  100d63:	29 c1                	sub    %eax,%ecx
  100d65:	89 c8                	mov    %ecx,%eax
  100d67:	c1 f8 03             	sar    $0x3,%eax
  100d6a:	c1 e0 0c             	shl    $0xc,%eax
  100d6d:	8b 15 04 70 10 00    	mov    0x107004,%edx
  100d73:	c1 e2 0c             	shl    $0xc,%edx
  100d76:	39 d0                	cmp    %edx,%eax
  100d78:	72 24                	jb     100d9e <mem_check+0x2d3>
  100d7a:	c7 44 24 0c a0 32 10 	movl   $0x1032a0,0xc(%esp)
  100d81:	00 
  100d82:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100d89:	00 
  100d8a:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  100d91:	00 
  100d92:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100d99:	e8 eb f5 ff ff       	call   100389 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100d9e:	a1 00 70 10 00       	mov    0x107000,%eax
  100da3:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100da6:	c7 05 00 70 10 00 00 	movl   $0x0,0x107000
  100dad:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100db0:	e8 aa fc ff ff       	call   100a5f <mem_alloc>
  100db5:	85 c0                	test   %eax,%eax
  100db7:	74 24                	je     100ddd <mem_check+0x312>
  100db9:	c7 44 24 0c c6 32 10 	movl   $0x1032c6,0xc(%esp)
  100dc0:	00 
  100dc1:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100dc8:	00 
  100dc9:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  100dd0:	00 
  100dd1:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100dd8:	e8 ac f5 ff ff       	call   100389 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100ddd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100de0:	89 04 24             	mov    %eax,(%esp)
  100de3:	e8 a6 fc ff ff       	call   100a8e <mem_free>
        mem_free(pp1);
  100de8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100deb:	89 04 24             	mov    %eax,(%esp)
  100dee:	e8 9b fc ff ff       	call   100a8e <mem_free>
        mem_free(pp2);
  100df3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100df6:	89 04 24             	mov    %eax,(%esp)
  100df9:	e8 90 fc ff ff       	call   100a8e <mem_free>
	pp0 = pp1 = pp2 = 0;
  100dfe:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100e05:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e08:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100e0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100e0e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100e11:	e8 49 fc ff ff       	call   100a5f <mem_alloc>
  100e16:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100e19:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100e1d:	75 24                	jne    100e43 <mem_check+0x378>
  100e1f:	c7 44 24 0c ff 31 10 	movl   $0x1031ff,0xc(%esp)
  100e26:	00 
  100e27:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100e2e:	00 
  100e2f:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  100e36:	00 
  100e37:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100e3e:	e8 46 f5 ff ff       	call   100389 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100e43:	e8 17 fc ff ff       	call   100a5f <mem_alloc>
  100e48:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100e4b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100e4f:	75 24                	jne    100e75 <mem_check+0x3aa>
  100e51:	c7 44 24 0c 08 32 10 	movl   $0x103208,0xc(%esp)
  100e58:	00 
  100e59:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100e60:	00 
  100e61:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  100e68:	00 
  100e69:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100e70:	e8 14 f5 ff ff       	call   100389 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100e75:	e8 e5 fb ff ff       	call   100a5f <mem_alloc>
  100e7a:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100e7d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100e81:	75 24                	jne    100ea7 <mem_check+0x3dc>
  100e83:	c7 44 24 0c 11 32 10 	movl   $0x103211,0xc(%esp)
  100e8a:	00 
  100e8b:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100e92:	00 
  100e93:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  100e9a:	00 
  100e9b:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100ea2:	e8 e2 f4 ff ff       	call   100389 <debug_panic>
	assert(pp0);
  100ea7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100eab:	75 24                	jne    100ed1 <mem_check+0x406>
  100ead:	c7 44 24 0c 1a 32 10 	movl   $0x10321a,0xc(%esp)
  100eb4:	00 
  100eb5:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100ebc:	00 
  100ebd:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  100ec4:	00 
  100ec5:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100ecc:	e8 b8 f4 ff ff       	call   100389 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100ed1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100ed5:	74 08                	je     100edf <mem_check+0x414>
  100ed7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100eda:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100edd:	75 24                	jne    100f03 <mem_check+0x438>
  100edf:	c7 44 24 0c 1e 32 10 	movl   $0x10321e,0xc(%esp)
  100ee6:	00 
  100ee7:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100eee:	00 
  100eef:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  100ef6:	00 
  100ef7:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100efe:	e8 86 f4 ff ff       	call   100389 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100f03:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100f07:	74 10                	je     100f19 <mem_check+0x44e>
  100f09:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100f0c:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100f0f:	74 08                	je     100f19 <mem_check+0x44e>
  100f11:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100f14:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100f17:	75 24                	jne    100f3d <mem_check+0x472>
  100f19:	c7 44 24 0c 30 32 10 	movl   $0x103230,0xc(%esp)
  100f20:	00 
  100f21:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100f28:	00 
  100f29:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
  100f30:	00 
  100f31:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100f38:	e8 4c f4 ff ff       	call   100389 <debug_panic>
	assert(mem_alloc() == 0);
  100f3d:	e8 1d fb ff ff       	call   100a5f <mem_alloc>
  100f42:	85 c0                	test   %eax,%eax
  100f44:	74 24                	je     100f6a <mem_check+0x49f>
  100f46:	c7 44 24 0c c6 32 10 	movl   $0x1032c6,0xc(%esp)
  100f4d:	00 
  100f4e:	c7 44 24 08 0e 31 10 	movl   $0x10310e,0x8(%esp)
  100f55:	00 
  100f56:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
  100f5d:	00 
  100f5e:	c7 04 24 50 31 10 00 	movl   $0x103150,(%esp)
  100f65:	e8 1f f4 ff ff       	call   100389 <debug_panic>

	// give free list back
	mem_freelist = fl;
  100f6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100f6d:	a3 00 70 10 00       	mov    %eax,0x107000

	// free the pages we took
	mem_free(pp0);
  100f72:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100f75:	89 04 24             	mov    %eax,(%esp)
  100f78:	e8 11 fb ff ff       	call   100a8e <mem_free>
	mem_free(pp1);
  100f7d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100f80:	89 04 24             	mov    %eax,(%esp)
  100f83:	e8 06 fb ff ff       	call   100a8e <mem_free>
	mem_free(pp2);
  100f88:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100f8b:	89 04 24             	mov    %eax,(%esp)
  100f8e:	e8 fb fa ff ff       	call   100a8e <mem_free>

	cprintf("mem_check() succeeded!\n");
  100f93:	c7 04 24 d7 32 10 00 	movl   $0x1032d7,(%esp)
  100f9a:	e8 2b 18 00 00       	call   1027ca <cprintf>
}
  100f9f:	c9                   	leave  
  100fa0:	c3                   	ret    

00100fa1 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100fa1:	55                   	push   %ebp
  100fa2:	89 e5                	mov    %esp,%ebp
  100fa4:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100fa7:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100faa:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100fad:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100fb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fb3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100fb8:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100fbb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100fbe:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100fc4:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100fc9:	74 24                	je     100fef <cpu_cur+0x4e>
  100fcb:	c7 44 24 0c ef 32 10 	movl   $0x1032ef,0xc(%esp)
  100fd2:	00 
  100fd3:	c7 44 24 08 05 33 10 	movl   $0x103305,0x8(%esp)
  100fda:	00 
  100fdb:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100fe2:	00 
  100fe3:	c7 04 24 1a 33 10 00 	movl   $0x10331a,(%esp)
  100fea:	e8 9a f3 ff ff       	call   100389 <debug_panic>
	return c;
  100fef:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100ff2:	c9                   	leave  
  100ff3:	c3                   	ret    

00100ff4 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  100ff4:	55                   	push   %ebp
  100ff5:	89 e5                	mov    %esp,%ebp
  100ff7:	53                   	push   %ebx
  100ff8:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  100ffb:	e8 a1 ff ff ff       	call   100fa1 <cpu_cur>
  101000:	89 45 f0             	mov    %eax,-0x10(%ebp)

	c->tss.ts_ss0 = CPU_GDT_KDATA;
  101003:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101006:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)
	c->tss.ts_esp0 = (uintptr_t)c->kstackhi; 
  10100c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10100f:	05 00 10 00 00       	add    $0x1000,%eax
  101014:	89 c2                	mov    %eax,%edx
  101016:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101019:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->gdt[CPU_GDT_TSS>>3] = SEGDESC16(0, STS_T32A, (uintptr_t)(&c->tss), sizeof(c->tss) - 1, 0);
  10101c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10101f:	83 c0 38             	add    $0x38,%eax
  101022:	89 c3                	mov    %eax,%ebx
  101024:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101027:	83 c0 38             	add    $0x38,%eax
  10102a:	c1 e8 10             	shr    $0x10,%eax
  10102d:	89 c1                	mov    %eax,%ecx
  10102f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101032:	83 c0 38             	add    $0x38,%eax
  101035:	c1 e8 18             	shr    $0x18,%eax
  101038:	89 c2                	mov    %eax,%edx
  10103a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10103d:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  101043:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101046:	66 89 58 32          	mov    %bx,0x32(%eax)
  10104a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10104d:	88 48 34             	mov    %cl,0x34(%eax)
  101050:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101053:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101057:	83 e1 f0             	and    $0xfffffff0,%ecx
  10105a:	83 c9 09             	or     $0x9,%ecx
  10105d:	88 48 35             	mov    %cl,0x35(%eax)
  101060:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101063:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101067:	83 e1 ef             	and    $0xffffffef,%ecx
  10106a:	88 48 35             	mov    %cl,0x35(%eax)
  10106d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101070:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101074:	83 e1 9f             	and    $0xffffff9f,%ecx
  101077:	88 48 35             	mov    %cl,0x35(%eax)
  10107a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10107d:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101081:	83 c9 80             	or     $0xffffff80,%ecx
  101084:	88 48 35             	mov    %cl,0x35(%eax)
  101087:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10108a:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10108e:	83 e1 f0             	and    $0xfffffff0,%ecx
  101091:	88 48 36             	mov    %cl,0x36(%eax)
  101094:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101097:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10109b:	83 e1 ef             	and    $0xffffffef,%ecx
  10109e:	88 48 36             	mov    %cl,0x36(%eax)
  1010a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010a4:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1010a8:	83 e1 df             	and    $0xffffffdf,%ecx
  1010ab:	88 48 36             	mov    %cl,0x36(%eax)
  1010ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010b1:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1010b5:	83 c9 40             	or     $0x40,%ecx
  1010b8:	88 48 36             	mov    %cl,0x36(%eax)
  1010bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010be:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1010c2:	83 e1 7f             	and    $0x7f,%ecx
  1010c5:	88 48 36             	mov    %cl,0x36(%eax)
  1010c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010cb:	88 50 37             	mov    %dl,0x37(%eax)


	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  1010ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010d1:	66 c7 45 ea 37 00    	movw   $0x37,-0x16(%ebp)
  1010d7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  1010da:	0f 01 55 ea          	lgdtl  -0x16(%ebp)
  1010de:	66 c7 45 f6 30 00    	movw   $0x30,-0xa(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1010e4:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  1010e8:	0f 00 d8             	ltr    %ax
	ltr(CPU_GDT_TSS);
	
	// Reload all segment registers.
	//asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
	//asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1010eb:	b8 10 00 00 00       	mov    $0x10,%eax
  1010f0:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  1010f2:	b8 10 00 00 00       	mov    $0x10,%eax
  1010f7:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1010f9:	b8 10 00 00 00       	mov    $0x10,%eax
  1010fe:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  101100:	ea 07 11 10 00 08 00 	ljmp   $0x8,$0x101107

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  101107:	b8 00 00 00 00       	mov    $0x0,%eax
  10110c:	0f 00 d0             	lldt   %ax
}
  10110f:	83 c4 14             	add    $0x14,%esp
  101112:	5b                   	pop    %ebx
  101113:	5d                   	pop    %ebp
  101114:	c3                   	ret    

00101115 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101115:	55                   	push   %ebp
  101116:	89 e5                	mov    %esp,%ebp
  101118:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10111b:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10111e:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101121:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101124:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101127:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10112c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10112f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101132:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101138:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10113d:	74 24                	je     101163 <cpu_cur+0x4e>
  10113f:	c7 44 24 0c 40 33 10 	movl   $0x103340,0xc(%esp)
  101146:	00 
  101147:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  10114e:	00 
  10114f:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  101156:	00 
  101157:	c7 04 24 6b 33 10 00 	movl   $0x10336b,(%esp)
  10115e:	e8 26 f2 ff ff       	call   100389 <debug_panic>
	return c;
  101163:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101166:	c9                   	leave  
  101167:	c3                   	ret    

00101168 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101168:	55                   	push   %ebp
  101169:	89 e5                	mov    %esp,%ebp
  10116b:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10116e:	e8 a2 ff ff ff       	call   101115 <cpu_cur>
  101173:	3d 00 40 10 00       	cmp    $0x104000,%eax
  101178:	0f 94 c0             	sete   %al
  10117b:	0f b6 c0             	movzbl %al,%eax
}
  10117e:	c9                   	leave  
  10117f:	c3                   	ret    

00101180 <trap_init_idt>:

extern uint32_t vectors[];

static void
trap_init_idt(void)
{
  101180:	55                   	push   %ebp
  101181:	89 e5                	mov    %esp,%ebp
  101183:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  101186:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  10118d:	e9 bc 00 00 00       	jmp    10124e <trap_init_idt+0xce>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
  101192:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101195:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101198:	8b 14 95 10 50 10 00 	mov    0x105010(,%edx,4),%edx
  10119f:	66 89 14 c5 e0 67 10 	mov    %dx,0x1067e0(,%eax,8)
  1011a6:	00 
  1011a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1011aa:	66 c7 04 c5 e2 67 10 	movw   $0x8,0x1067e2(,%eax,8)
  1011b1:	00 08 00 
  1011b4:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1011b7:	0f b6 14 c5 e4 67 10 	movzbl 0x1067e4(,%eax,8),%edx
  1011be:	00 
  1011bf:	83 e2 e0             	and    $0xffffffe0,%edx
  1011c2:	88 14 c5 e4 67 10 00 	mov    %dl,0x1067e4(,%eax,8)
  1011c9:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1011cc:	0f b6 14 c5 e4 67 10 	movzbl 0x1067e4(,%eax,8),%edx
  1011d3:	00 
  1011d4:	83 e2 1f             	and    $0x1f,%edx
  1011d7:	88 14 c5 e4 67 10 00 	mov    %dl,0x1067e4(,%eax,8)
  1011de:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1011e1:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  1011e8:	00 
  1011e9:	83 ca 0f             	or     $0xf,%edx
  1011ec:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  1011f3:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1011f6:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  1011fd:	00 
  1011fe:	83 e2 ef             	and    $0xffffffef,%edx
  101201:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  101208:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10120b:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  101212:	00 
  101213:	83 ca 60             	or     $0x60,%edx
  101216:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  10121d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101220:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  101227:	00 
  101228:	83 ca 80             	or     $0xffffff80,%edx
  10122b:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  101232:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101235:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101238:	8b 14 95 10 50 10 00 	mov    0x105010(,%edx,4),%edx
  10123f:	c1 ea 10             	shr    $0x10,%edx
  101242:	66 89 14 c5 e6 67 10 	mov    %dx,0x1067e6(,%eax,8)
  101249:	00 
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  10124a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  10124e:	83 7d fc 13          	cmpl   $0x13,-0x4(%ebp)
  101252:	0f 8e 3a ff ff ff    	jle    101192 <trap_init_idt+0x12>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
	}
	SETGATE(idt[30], 1, CPU_GDT_KCODE, vectors[30], 3);
  101258:	a1 88 50 10 00       	mov    0x105088,%eax
  10125d:	66 a3 d0 68 10 00    	mov    %ax,0x1068d0
  101263:	66 c7 05 d2 68 10 00 	movw   $0x8,0x1068d2
  10126a:	08 00 
  10126c:	0f b6 05 d4 68 10 00 	movzbl 0x1068d4,%eax
  101273:	83 e0 e0             	and    $0xffffffe0,%eax
  101276:	a2 d4 68 10 00       	mov    %al,0x1068d4
  10127b:	0f b6 05 d4 68 10 00 	movzbl 0x1068d4,%eax
  101282:	83 e0 1f             	and    $0x1f,%eax
  101285:	a2 d4 68 10 00       	mov    %al,0x1068d4
  10128a:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  101291:	83 c8 0f             	or     $0xf,%eax
  101294:	a2 d5 68 10 00       	mov    %al,0x1068d5
  101299:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1012a0:	83 e0 ef             	and    $0xffffffef,%eax
  1012a3:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1012a8:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1012af:	83 c8 60             	or     $0x60,%eax
  1012b2:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1012b7:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1012be:	83 c8 80             	or     $0xffffff80,%eax
  1012c1:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1012c6:	a1 88 50 10 00       	mov    0x105088,%eax
  1012cb:	c1 e8 10             	shr    $0x10,%eax
  1012ce:	66 a3 d6 68 10 00    	mov    %ax,0x1068d6
}
  1012d4:	c9                   	leave  
  1012d5:	c3                   	ret    

001012d6 <trap_init>:

void
trap_init(void)
{
  1012d6:	55                   	push   %ebp
  1012d7:	89 e5                	mov    %esp,%ebp
  1012d9:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  1012dc:	e8 87 fe ff ff       	call   101168 <cpu_onboot>
  1012e1:	85 c0                	test   %eax,%eax
  1012e3:	74 05                	je     1012ea <trap_init+0x14>
		trap_init_idt();
  1012e5:	e8 96 fe ff ff       	call   101180 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  1012ea:	0f 01 1d 00 50 10 00 	lidtl  0x105000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  1012f1:	e8 72 fe ff ff       	call   101168 <cpu_onboot>
  1012f6:	85 c0                	test   %eax,%eax
  1012f8:	74 05                	je     1012ff <trap_init+0x29>
		trap_check_kernel();
  1012fa:	e8 62 02 00 00       	call   101561 <trap_check_kernel>
}
  1012ff:	c9                   	leave  
  101300:	c3                   	ret    

00101301 <trap_name>:

const char *trap_name(int trapno)
{
  101301:	55                   	push   %ebp
  101302:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101304:	8b 45 08             	mov    0x8(%ebp),%eax
  101307:	83 f8 13             	cmp    $0x13,%eax
  10130a:	77 0c                	ja     101318 <trap_name+0x17>
		return excnames[trapno];
  10130c:	8b 45 08             	mov    0x8(%ebp),%eax
  10130f:	8b 04 85 20 37 10 00 	mov    0x103720(,%eax,4),%eax
  101316:	eb 05                	jmp    10131d <trap_name+0x1c>
	return "(unknown trap)";
  101318:	b8 78 33 10 00       	mov    $0x103378,%eax
}
  10131d:	5d                   	pop    %ebp
  10131e:	c3                   	ret    

0010131f <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  10131f:	55                   	push   %ebp
  101320:	89 e5                	mov    %esp,%ebp
  101322:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  101325:	8b 45 08             	mov    0x8(%ebp),%eax
  101328:	8b 00                	mov    (%eax),%eax
  10132a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10132e:	c7 04 24 87 33 10 00 	movl   $0x103387,(%esp)
  101335:	e8 90 14 00 00       	call   1027ca <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  10133a:	8b 45 08             	mov    0x8(%ebp),%eax
  10133d:	8b 40 04             	mov    0x4(%eax),%eax
  101340:	89 44 24 04          	mov    %eax,0x4(%esp)
  101344:	c7 04 24 96 33 10 00 	movl   $0x103396,(%esp)
  10134b:	e8 7a 14 00 00       	call   1027ca <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101350:	8b 45 08             	mov    0x8(%ebp),%eax
  101353:	8b 40 08             	mov    0x8(%eax),%eax
  101356:	89 44 24 04          	mov    %eax,0x4(%esp)
  10135a:	c7 04 24 a5 33 10 00 	movl   $0x1033a5,(%esp)
  101361:	e8 64 14 00 00       	call   1027ca <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  101366:	8b 45 08             	mov    0x8(%ebp),%eax
  101369:	8b 40 10             	mov    0x10(%eax),%eax
  10136c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101370:	c7 04 24 b4 33 10 00 	movl   $0x1033b4,(%esp)
  101377:	e8 4e 14 00 00       	call   1027ca <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  10137c:	8b 45 08             	mov    0x8(%ebp),%eax
  10137f:	8b 40 14             	mov    0x14(%eax),%eax
  101382:	89 44 24 04          	mov    %eax,0x4(%esp)
  101386:	c7 04 24 c3 33 10 00 	movl   $0x1033c3,(%esp)
  10138d:	e8 38 14 00 00       	call   1027ca <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101392:	8b 45 08             	mov    0x8(%ebp),%eax
  101395:	8b 40 18             	mov    0x18(%eax),%eax
  101398:	89 44 24 04          	mov    %eax,0x4(%esp)
  10139c:	c7 04 24 d2 33 10 00 	movl   $0x1033d2,(%esp)
  1013a3:	e8 22 14 00 00       	call   1027ca <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1013a8:	8b 45 08             	mov    0x8(%ebp),%eax
  1013ab:	8b 40 1c             	mov    0x1c(%eax),%eax
  1013ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013b2:	c7 04 24 e1 33 10 00 	movl   $0x1033e1,(%esp)
  1013b9:	e8 0c 14 00 00       	call   1027ca <cprintf>
}
  1013be:	c9                   	leave  
  1013bf:	c3                   	ret    

001013c0 <trap_print>:

void
trap_print(trapframe *tf)
{
  1013c0:	55                   	push   %ebp
  1013c1:	89 e5                	mov    %esp,%ebp
  1013c3:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  1013c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1013c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013cd:	c7 04 24 f0 33 10 00 	movl   $0x1033f0,(%esp)
  1013d4:	e8 f1 13 00 00       	call   1027ca <cprintf>
	trap_print_regs(&tf->regs);
  1013d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1013dc:	89 04 24             	mov    %eax,(%esp)
  1013df:	e8 3b ff ff ff       	call   10131f <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  1013e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1013e7:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  1013eb:	0f b7 c0             	movzwl %ax,%eax
  1013ee:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013f2:	c7 04 24 02 34 10 00 	movl   $0x103402,(%esp)
  1013f9:	e8 cc 13 00 00       	call   1027ca <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  1013fe:	8b 45 08             	mov    0x8(%ebp),%eax
  101401:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101405:	0f b7 c0             	movzwl %ax,%eax
  101408:	89 44 24 04          	mov    %eax,0x4(%esp)
  10140c:	c7 04 24 15 34 10 00 	movl   $0x103415,(%esp)
  101413:	e8 b2 13 00 00       	call   1027ca <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101418:	8b 45 08             	mov    0x8(%ebp),%eax
  10141b:	8b 40 30             	mov    0x30(%eax),%eax
  10141e:	89 04 24             	mov    %eax,(%esp)
  101421:	e8 db fe ff ff       	call   101301 <trap_name>
  101426:	8b 55 08             	mov    0x8(%ebp),%edx
  101429:	8b 52 30             	mov    0x30(%edx),%edx
  10142c:	89 44 24 08          	mov    %eax,0x8(%esp)
  101430:	89 54 24 04          	mov    %edx,0x4(%esp)
  101434:	c7 04 24 28 34 10 00 	movl   $0x103428,(%esp)
  10143b:	e8 8a 13 00 00       	call   1027ca <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101440:	8b 45 08             	mov    0x8(%ebp),%eax
  101443:	8b 40 34             	mov    0x34(%eax),%eax
  101446:	89 44 24 04          	mov    %eax,0x4(%esp)
  10144a:	c7 04 24 3a 34 10 00 	movl   $0x10343a,(%esp)
  101451:	e8 74 13 00 00       	call   1027ca <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  101456:	8b 45 08             	mov    0x8(%ebp),%eax
  101459:	8b 40 38             	mov    0x38(%eax),%eax
  10145c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101460:	c7 04 24 49 34 10 00 	movl   $0x103449,(%esp)
  101467:	e8 5e 13 00 00       	call   1027ca <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  10146c:	8b 45 08             	mov    0x8(%ebp),%eax
  10146f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101473:	0f b7 c0             	movzwl %ax,%eax
  101476:	89 44 24 04          	mov    %eax,0x4(%esp)
  10147a:	c7 04 24 58 34 10 00 	movl   $0x103458,(%esp)
  101481:	e8 44 13 00 00       	call   1027ca <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  101486:	8b 45 08             	mov    0x8(%ebp),%eax
  101489:	8b 40 40             	mov    0x40(%eax),%eax
  10148c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101490:	c7 04 24 6b 34 10 00 	movl   $0x10346b,(%esp)
  101497:	e8 2e 13 00 00       	call   1027ca <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  10149c:	8b 45 08             	mov    0x8(%ebp),%eax
  10149f:	8b 40 44             	mov    0x44(%eax),%eax
  1014a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1014a6:	c7 04 24 7a 34 10 00 	movl   $0x10347a,(%esp)
  1014ad:	e8 18 13 00 00       	call   1027ca <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1014b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1014b5:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1014b9:	0f b7 c0             	movzwl %ax,%eax
  1014bc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1014c0:	c7 04 24 89 34 10 00 	movl   $0x103489,(%esp)
  1014c7:	e8 fe 12 00 00       	call   1027ca <cprintf>
}
  1014cc:	c9                   	leave  
  1014cd:	c3                   	ret    

001014ce <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  1014ce:	55                   	push   %ebp
  1014cf:	89 e5                	mov    %esp,%ebp
  1014d1:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  1014d4:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  1014d5:	e8 3b fc ff ff       	call   101115 <cpu_cur>
  1014da:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  1014dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1014e0:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1014e6:	85 c0                	test   %eax,%eax
  1014e8:	74 1e                	je     101508 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  1014ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1014ed:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  1014f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1014f6:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  1014fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  101500:	8b 45 08             	mov    0x8(%ebp),%eax
  101503:	89 04 24             	mov    %eax,(%esp)
  101506:	ff d2                	call   *%edx

	trap_print(tf);
  101508:	8b 45 08             	mov    0x8(%ebp),%eax
  10150b:	89 04 24             	mov    %eax,(%esp)
  10150e:	e8 ad fe ff ff       	call   1013c0 <trap_print>
	panic("unhandled trap");
  101513:	c7 44 24 08 9c 34 10 	movl   $0x10349c,0x8(%esp)
  10151a:	00 
  10151b:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  101522:	00 
  101523:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  10152a:	e8 5a ee ff ff       	call   100389 <debug_panic>

0010152f <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  10152f:	55                   	push   %ebp
  101530:	89 e5                	mov    %esp,%ebp
  101532:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101535:	8b 45 0c             	mov    0xc(%ebp),%eax
  101538:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  10153b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10153e:	8b 00                	mov    (%eax),%eax
  101540:	89 c2                	mov    %eax,%edx
  101542:	8b 45 08             	mov    0x8(%ebp),%eax
  101545:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  101548:	8b 45 08             	mov    0x8(%ebp),%eax
  10154b:	8b 40 30             	mov    0x30(%eax),%eax
  10154e:	89 c2                	mov    %eax,%edx
  101550:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101553:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  101556:	8b 45 08             	mov    0x8(%ebp),%eax
  101559:	89 04 24             	mov    %eax,(%esp)
  10155c:	e8 1f 3b 00 00       	call   105080 <trap_return>

00101561 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101561:	55                   	push   %ebp
  101562:	89 e5                	mov    %esp,%ebp
  101564:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101567:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  10156a:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  10156e:	0f b7 c0             	movzwl %ax,%eax
  101571:	83 e0 03             	and    $0x3,%eax
  101574:	85 c0                	test   %eax,%eax
  101576:	74 24                	je     10159c <trap_check_kernel+0x3b>
  101578:	c7 44 24 0c b7 34 10 	movl   $0x1034b7,0xc(%esp)
  10157f:	00 
  101580:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  101587:	00 
  101588:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  10158f:	00 
  101590:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  101597:	e8 ed ed ff ff       	call   100389 <debug_panic>

	cpu *c = cpu_cur();
  10159c:	e8 74 fb ff ff       	call   101115 <cpu_cur>
  1015a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  1015a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1015a7:	c7 80 a0 00 00 00 2f 	movl   $0x10152f,0xa0(%eax)
  1015ae:	15 10 00 
	trap_check(&c->recoverdata);
  1015b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1015b4:	05 a4 00 00 00       	add    $0xa4,%eax
  1015b9:	89 04 24             	mov    %eax,(%esp)
  1015bc:	e8 96 00 00 00       	call   101657 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1015c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1015c4:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1015cb:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  1015ce:	c7 04 24 cc 34 10 00 	movl   $0x1034cc,(%esp)
  1015d5:	e8 f0 11 00 00       	call   1027ca <cprintf>
}
  1015da:	c9                   	leave  
  1015db:	c3                   	ret    

001015dc <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  1015dc:	55                   	push   %ebp
  1015dd:	89 e5                	mov    %esp,%ebp
  1015df:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1015e2:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  1015e5:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  1015e9:	0f b7 c0             	movzwl %ax,%eax
  1015ec:	83 e0 03             	and    $0x3,%eax
  1015ef:	83 f8 03             	cmp    $0x3,%eax
  1015f2:	74 24                	je     101618 <trap_check_user+0x3c>
  1015f4:	c7 44 24 0c ec 34 10 	movl   $0x1034ec,0xc(%esp)
  1015fb:	00 
  1015fc:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  101603:	00 
  101604:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
  10160b:	00 
  10160c:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  101613:	e8 71 ed ff ff       	call   100389 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101618:	c7 45 f0 00 40 10 00 	movl   $0x104000,-0x10(%ebp)
	c->recover = trap_check_recover;
  10161f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101622:	c7 80 a0 00 00 00 2f 	movl   $0x10152f,0xa0(%eax)
  101629:	15 10 00 
	trap_check(&c->recoverdata);
  10162c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10162f:	05 a4 00 00 00       	add    $0xa4,%eax
  101634:	89 04 24             	mov    %eax,(%esp)
  101637:	e8 1b 00 00 00       	call   101657 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  10163c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10163f:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101646:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101649:	c7 04 24 01 35 10 00 	movl   $0x103501,(%esp)
  101650:	e8 75 11 00 00       	call   1027ca <cprintf>
}
  101655:	c9                   	leave  
  101656:	c3                   	ret    

00101657 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  101657:	55                   	push   %ebp
  101658:	89 e5                	mov    %esp,%ebp
  10165a:	57                   	push   %edi
  10165b:	56                   	push   %esi
  10165c:	53                   	push   %ebx
  10165d:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101660:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101667:	8b 45 08             	mov    0x8(%ebp),%eax
  10166a:	8d 55 d8             	lea    -0x28(%ebp),%edx
  10166d:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  10166f:	c7 45 d8 7d 16 10 00 	movl   $0x10167d,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101676:	b8 00 00 00 00       	mov    $0x0,%eax
  10167b:	f7 f0                	div    %eax

0010167d <after_div0>:
	assert(args.trapno == T_DIVIDE);
  10167d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101680:	85 c0                	test   %eax,%eax
  101682:	74 24                	je     1016a8 <after_div0+0x2b>
  101684:	c7 44 24 0c 1f 35 10 	movl   $0x10351f,0xc(%esp)
  10168b:	00 
  10168c:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  101693:	00 
  101694:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  10169b:	00 
  10169c:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  1016a3:	e8 e1 ec ff ff       	call   100389 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1016a8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1016ab:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1016b0:	74 24                	je     1016d6 <after_div0+0x59>
  1016b2:	c7 44 24 0c 37 35 10 	movl   $0x103537,0xc(%esp)
  1016b9:	00 
  1016ba:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  1016c1:	00 
  1016c2:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  1016c9:	00 
  1016ca:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  1016d1:	e8 b3 ec ff ff       	call   100389 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  1016d6:	c7 45 d8 de 16 10 00 	movl   $0x1016de,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  1016dd:	cc                   	int3   

001016de <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  1016de:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1016e1:	83 f8 03             	cmp    $0x3,%eax
  1016e4:	74 24                	je     10170a <after_breakpoint+0x2c>
  1016e6:	c7 44 24 0c 4c 35 10 	movl   $0x10354c,0xc(%esp)
  1016ed:	00 
  1016ee:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  1016f5:	00 
  1016f6:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  1016fd:	00 
  1016fe:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  101705:	e8 7f ec ff ff       	call   100389 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  10170a:	c7 45 d8 19 17 10 00 	movl   $0x101719,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101711:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101716:	01 c0                	add    %eax,%eax
  101718:	ce                   	into   

00101719 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101719:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10171c:	83 f8 04             	cmp    $0x4,%eax
  10171f:	74 24                	je     101745 <after_overflow+0x2c>
  101721:	c7 44 24 0c 63 35 10 	movl   $0x103563,0xc(%esp)
  101728:	00 
  101729:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  101730:	00 
  101731:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  101738:	00 
  101739:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  101740:	e8 44 ec ff ff       	call   100389 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101745:	c7 45 d8 62 17 10 00 	movl   $0x101762,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  10174c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101753:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  10175a:	b8 00 00 00 00       	mov    $0x0,%eax
  10175f:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101762 <after_bound>:
	assert(args.trapno == T_BOUND);
  101762:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101765:	83 f8 05             	cmp    $0x5,%eax
  101768:	74 24                	je     10178e <after_bound+0x2c>
  10176a:	c7 44 24 0c 7a 35 10 	movl   $0x10357a,0xc(%esp)
  101771:	00 
  101772:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  101779:	00 
  10177a:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  101781:	00 
  101782:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  101789:	e8 fb eb ff ff       	call   100389 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  10178e:	c7 45 d8 97 17 10 00 	movl   $0x101797,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101795:	0f 0b                	ud2    

00101797 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101797:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10179a:	83 f8 06             	cmp    $0x6,%eax
  10179d:	74 24                	je     1017c3 <after_illegal+0x2c>
  10179f:	c7 44 24 0c 91 35 10 	movl   $0x103591,0xc(%esp)
  1017a6:	00 
  1017a7:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  1017ae:	00 
  1017af:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  1017b6:	00 
  1017b7:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  1017be:	e8 c6 eb ff ff       	call   100389 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  1017c3:	c7 45 d8 d1 17 10 00 	movl   $0x1017d1,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  1017ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1017cf:	8e e0                	mov    %eax,%fs

001017d1 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  1017d1:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1017d4:	83 f8 0d             	cmp    $0xd,%eax
  1017d7:	74 24                	je     1017fd <after_gpfault+0x2c>
  1017d9:	c7 44 24 0c a8 35 10 	movl   $0x1035a8,0xc(%esp)
  1017e0:	00 
  1017e1:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  1017e8:	00 
  1017e9:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
  1017f0:	00 
  1017f1:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  1017f8:	e8 8c eb ff ff       	call   100389 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1017fd:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  101800:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101804:	0f b7 c0             	movzwl %ax,%eax
  101807:	83 e0 03             	and    $0x3,%eax
  10180a:	85 c0                	test   %eax,%eax
  10180c:	74 3a                	je     101848 <after_priv+0x2c>
		args.reip = after_priv;
  10180e:	c7 45 d8 1c 18 10 00 	movl   $0x10181c,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101815:	0f 01 1d 00 50 10 00 	lidtl  0x105000

0010181c <after_priv>:
		assert(args.trapno == T_GPFLT);
  10181c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10181f:	83 f8 0d             	cmp    $0xd,%eax
  101822:	74 24                	je     101848 <after_priv+0x2c>
  101824:	c7 44 24 0c a8 35 10 	movl   $0x1035a8,0xc(%esp)
  10182b:	00 
  10182c:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  101833:	00 
  101834:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
  10183b:	00 
  10183c:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  101843:	e8 41 eb ff ff       	call   100389 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101848:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10184b:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101850:	74 24                	je     101876 <after_priv+0x5a>
  101852:	c7 44 24 0c 37 35 10 	movl   $0x103537,0xc(%esp)
  101859:	00 
  10185a:	c7 44 24 08 56 33 10 	movl   $0x103356,0x8(%esp)
  101861:	00 
  101862:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
  101869:	00 
  10186a:	c7 04 24 ab 34 10 00 	movl   $0x1034ab,(%esp)
  101871:	e8 13 eb ff ff       	call   100389 <debug_panic>
	//cprintf("sfsfsfsfsfsfsfsfsf\n");
	*argsp = NULL;	// recovery mechanism not needed anymore
  101876:	8b 45 08             	mov    0x8(%ebp),%eax
  101879:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  10187f:	83 c4 3c             	add    $0x3c,%esp
  101882:	5b                   	pop    %ebx
  101883:	5e                   	pop    %esi
  101884:	5f                   	pop    %edi
  101885:	5d                   	pop    %ebp
  101886:	c3                   	ret    
  101887:	90                   	nop

00101888 <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  101888:	6a 00                	push   $0x0
  10188a:	6a 00                	push   $0x0
  10188c:	e9 d3 37 00 00       	jmp    105064 <_alltraps>
  101891:	90                   	nop

00101892 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  101892:	6a 00                	push   $0x0
  101894:	6a 01                	push   $0x1
  101896:	e9 c9 37 00 00       	jmp    105064 <_alltraps>
  10189b:	90                   	nop

0010189c <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  10189c:	6a 00                	push   $0x0
  10189e:	6a 02                	push   $0x2
  1018a0:	e9 bf 37 00 00       	jmp    105064 <_alltraps>
  1018a5:	90                   	nop

001018a6 <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  1018a6:	6a 00                	push   $0x0
  1018a8:	6a 03                	push   $0x3
  1018aa:	e9 b5 37 00 00       	jmp    105064 <_alltraps>
  1018af:	90                   	nop

001018b0 <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  1018b0:	6a 00                	push   $0x0
  1018b2:	6a 04                	push   $0x4
  1018b4:	e9 ab 37 00 00       	jmp    105064 <_alltraps>
  1018b9:	90                   	nop

001018ba <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  1018ba:	6a 00                	push   $0x0
  1018bc:	6a 05                	push   $0x5
  1018be:	e9 a1 37 00 00       	jmp    105064 <_alltraps>
  1018c3:	90                   	nop

001018c4 <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  1018c4:	6a 00                	push   $0x0
  1018c6:	6a 06                	push   $0x6
  1018c8:	e9 97 37 00 00       	jmp    105064 <_alltraps>
  1018cd:	90                   	nop

001018ce <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  1018ce:	6a 00                	push   $0x0
  1018d0:	6a 07                	push   $0x7
  1018d2:	e9 8d 37 00 00       	jmp    105064 <_alltraps>
  1018d7:	90                   	nop

001018d8 <vector8>:
TRAPHANDLER(vector8, 8)
  1018d8:	6a 08                	push   $0x8
  1018da:	e9 85 37 00 00       	jmp    105064 <_alltraps>
  1018df:	90                   	nop

001018e0 <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  1018e0:	6a 00                	push   $0x0
  1018e2:	6a 09                	push   $0x9
  1018e4:	e9 7b 37 00 00       	jmp    105064 <_alltraps>
  1018e9:	90                   	nop

001018ea <vector10>:
TRAPHANDLER(vector10, 10)
  1018ea:	6a 0a                	push   $0xa
  1018ec:	e9 73 37 00 00       	jmp    105064 <_alltraps>
  1018f1:	90                   	nop

001018f2 <vector11>:
TRAPHANDLER(vector11, 11)
  1018f2:	6a 0b                	push   $0xb
  1018f4:	e9 6b 37 00 00       	jmp    105064 <_alltraps>
  1018f9:	90                   	nop

001018fa <vector12>:
TRAPHANDLER(vector12, 12)
  1018fa:	6a 0c                	push   $0xc
  1018fc:	e9 63 37 00 00       	jmp    105064 <_alltraps>
  101901:	90                   	nop

00101902 <vector13>:
TRAPHANDLER(vector13, 13)
  101902:	6a 0d                	push   $0xd
  101904:	e9 5b 37 00 00       	jmp    105064 <_alltraps>
  101909:	90                   	nop

0010190a <vector14>:
TRAPHANDLER(vector14, 14)
  10190a:	6a 0e                	push   $0xe
  10190c:	e9 53 37 00 00       	jmp    105064 <_alltraps>
  101911:	90                   	nop

00101912 <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101912:	6a 00                	push   $0x0
  101914:	6a 0f                	push   $0xf
  101916:	e9 49 37 00 00       	jmp    105064 <_alltraps>
  10191b:	90                   	nop

0010191c <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  10191c:	6a 00                	push   $0x0
  10191e:	6a 10                	push   $0x10
  101920:	e9 3f 37 00 00       	jmp    105064 <_alltraps>
  101925:	90                   	nop

00101926 <vector17>:
TRAPHANDLER(vector17, 17)
  101926:	6a 11                	push   $0x11
  101928:	e9 37 37 00 00       	jmp    105064 <_alltraps>
  10192d:	90                   	nop

0010192e <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  10192e:	6a 00                	push   $0x0
  101930:	6a 12                	push   $0x12
  101932:	e9 2d 37 00 00       	jmp    105064 <_alltraps>
  101937:	90                   	nop

00101938 <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  101938:	6a 00                	push   $0x0
  10193a:	6a 13                	push   $0x13
  10193c:	e9 23 37 00 00       	jmp    105064 <_alltraps>
  101941:	90                   	nop

00101942 <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101942:	6a 00                	push   $0x0
  101944:	6a 1e                	push   $0x1e
  101946:	e9 19 37 00 00       	jmp    105064 <_alltraps>

0010194b <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  10194b:	55                   	push   %ebp
  10194c:	89 e5                	mov    %esp,%ebp
  10194e:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  101951:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  101958:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10195b:	0f b7 00             	movzwl (%eax),%eax
  10195e:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  101962:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101965:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  10196a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10196d:	0f b7 00             	movzwl (%eax),%eax
  101970:	66 3d 5a a5          	cmp    $0xa55a,%ax
  101974:	74 13                	je     101989 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  101976:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  10197d:	c7 05 e0 6f 10 00 b4 	movl   $0x3b4,0x106fe0
  101984:	03 00 00 
  101987:	eb 14                	jmp    10199d <video_init+0x52>
	} else {
		*cp = was;
  101989:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10198c:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  101990:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  101993:	c7 05 e0 6f 10 00 d4 	movl   $0x3d4,0x106fe0
  10199a:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  10199d:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1019a2:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1019a5:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1019a9:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1019ad:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1019b0:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  1019b1:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1019b6:	83 c0 01             	add    $0x1,%eax
  1019b9:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1019bc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1019bf:	89 c2                	mov    %eax,%edx
  1019c1:	ec                   	in     (%dx),%al
  1019c2:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  1019c5:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  1019c9:	0f b6 c0             	movzbl %al,%eax
  1019cc:	c1 e0 08             	shl    $0x8,%eax
  1019cf:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  1019d2:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1019d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1019da:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1019de:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1019e2:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1019e5:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  1019e6:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1019eb:	83 c0 01             	add    $0x1,%eax
  1019ee:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1019f1:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1019f4:	89 c2                	mov    %eax,%edx
  1019f6:	ec                   	in     (%dx),%al
  1019f7:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  1019fa:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  1019fe:	0f b6 c0             	movzbl %al,%eax
  101a01:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  101a04:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101a07:	a3 e4 6f 10 00       	mov    %eax,0x106fe4
	crt_pos = pos;
  101a0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101a0f:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
}
  101a15:	c9                   	leave  
  101a16:	c3                   	ret    

00101a17 <video_putc>:



void
video_putc(int c)
{
  101a17:	55                   	push   %ebp
  101a18:	89 e5                	mov    %esp,%ebp
  101a1a:	53                   	push   %ebx
  101a1b:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  101a1e:	8b 45 08             	mov    0x8(%ebp),%eax
  101a21:	b0 00                	mov    $0x0,%al
  101a23:	85 c0                	test   %eax,%eax
  101a25:	75 07                	jne    101a2e <video_putc+0x17>
		c |= 0x0700;
  101a27:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  101a2e:	8b 45 08             	mov    0x8(%ebp),%eax
  101a31:	25 ff 00 00 00       	and    $0xff,%eax
  101a36:	83 f8 09             	cmp    $0x9,%eax
  101a39:	0f 84 ae 00 00 00    	je     101aed <video_putc+0xd6>
  101a3f:	83 f8 09             	cmp    $0x9,%eax
  101a42:	7f 0a                	jg     101a4e <video_putc+0x37>
  101a44:	83 f8 08             	cmp    $0x8,%eax
  101a47:	74 14                	je     101a5d <video_putc+0x46>
  101a49:	e9 dd 00 00 00       	jmp    101b2b <video_putc+0x114>
  101a4e:	83 f8 0a             	cmp    $0xa,%eax
  101a51:	74 4e                	je     101aa1 <video_putc+0x8a>
  101a53:	83 f8 0d             	cmp    $0xd,%eax
  101a56:	74 59                	je     101ab1 <video_putc+0x9a>
  101a58:	e9 ce 00 00 00       	jmp    101b2b <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  101a5d:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101a64:	66 85 c0             	test   %ax,%ax
  101a67:	0f 84 e4 00 00 00    	je     101b51 <video_putc+0x13a>
			crt_pos--;
  101a6d:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101a74:	83 e8 01             	sub    $0x1,%eax
  101a77:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  101a7d:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101a82:	0f b7 15 e8 6f 10 00 	movzwl 0x106fe8,%edx
  101a89:	0f b7 d2             	movzwl %dx,%edx
  101a8c:	01 d2                	add    %edx,%edx
  101a8e:	8d 14 10             	lea    (%eax,%edx,1),%edx
  101a91:	8b 45 08             	mov    0x8(%ebp),%eax
  101a94:	b0 00                	mov    $0x0,%al
  101a96:	83 c8 20             	or     $0x20,%eax
  101a99:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  101a9c:	e9 b1 00 00 00       	jmp    101b52 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  101aa1:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101aa8:	83 c0 50             	add    $0x50,%eax
  101aab:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  101ab1:	0f b7 1d e8 6f 10 00 	movzwl 0x106fe8,%ebx
  101ab8:	0f b7 0d e8 6f 10 00 	movzwl 0x106fe8,%ecx
  101abf:	0f b7 c1             	movzwl %cx,%eax
  101ac2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  101ac8:	c1 e8 10             	shr    $0x10,%eax
  101acb:	89 c2                	mov    %eax,%edx
  101acd:	66 c1 ea 06          	shr    $0x6,%dx
  101ad1:	89 d0                	mov    %edx,%eax
  101ad3:	c1 e0 02             	shl    $0x2,%eax
  101ad6:	01 d0                	add    %edx,%eax
  101ad8:	c1 e0 04             	shl    $0x4,%eax
  101adb:	89 ca                	mov    %ecx,%edx
  101add:	66 29 c2             	sub    %ax,%dx
  101ae0:	89 d8                	mov    %ebx,%eax
  101ae2:	66 29 d0             	sub    %dx,%ax
  101ae5:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
		break;
  101aeb:	eb 65                	jmp    101b52 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  101aed:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101af4:	e8 1e ff ff ff       	call   101a17 <video_putc>
		video_putc(' ');
  101af9:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101b00:	e8 12 ff ff ff       	call   101a17 <video_putc>
		video_putc(' ');
  101b05:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101b0c:	e8 06 ff ff ff       	call   101a17 <video_putc>
		video_putc(' ');
  101b11:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101b18:	e8 fa fe ff ff       	call   101a17 <video_putc>
		video_putc(' ');
  101b1d:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101b24:	e8 ee fe ff ff       	call   101a17 <video_putc>
		break;
  101b29:	eb 27                	jmp    101b52 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  101b2b:	8b 15 e4 6f 10 00    	mov    0x106fe4,%edx
  101b31:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101b38:	0f b7 c8             	movzwl %ax,%ecx
  101b3b:	01 c9                	add    %ecx,%ecx
  101b3d:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  101b40:	8b 55 08             	mov    0x8(%ebp),%edx
  101b43:	66 89 11             	mov    %dx,(%ecx)
  101b46:	83 c0 01             	add    $0x1,%eax
  101b49:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
  101b4f:	eb 01                	jmp    101b52 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  101b51:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  101b52:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101b59:	66 3d cf 07          	cmp    $0x7cf,%ax
  101b5d:	76 5b                	jbe    101bba <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  101b5f:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101b64:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  101b6a:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101b6f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  101b76:	00 
  101b77:	89 54 24 04          	mov    %edx,0x4(%esp)
  101b7b:	89 04 24             	mov    %eax,(%esp)
  101b7e:	e8 a0 0e 00 00       	call   102a23 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101b83:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  101b8a:	eb 15                	jmp    101ba1 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  101b8c:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101b91:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101b94:	01 d2                	add    %edx,%edx
  101b96:	01 d0                	add    %edx,%eax
  101b98:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101b9d:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  101ba1:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  101ba8:	7e e2                	jle    101b8c <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  101baa:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101bb1:	83 e8 50             	sub    $0x50,%eax
  101bb4:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  101bba:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101bbf:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101bc2:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101bc6:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101bca:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101bcd:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101bce:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101bd5:	66 c1 e8 08          	shr    $0x8,%ax
  101bd9:	0f b6 c0             	movzbl %al,%eax
  101bdc:	8b 15 e0 6f 10 00    	mov    0x106fe0,%edx
  101be2:	83 c2 01             	add    $0x1,%edx
  101be5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  101be8:	88 45 e3             	mov    %al,-0x1d(%ebp)
  101beb:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101bef:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101bf2:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  101bf3:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101bf8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101bfb:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  101bff:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  101c03:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101c06:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  101c07:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101c0e:	0f b6 c0             	movzbl %al,%eax
  101c11:	8b 15 e0 6f 10 00    	mov    0x106fe0,%edx
  101c17:	83 c2 01             	add    $0x1,%edx
  101c1a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  101c1d:	88 45 f3             	mov    %al,-0xd(%ebp)
  101c20:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101c24:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101c27:	ee                   	out    %al,(%dx)
}
  101c28:	83 c4 44             	add    $0x44,%esp
  101c2b:	5b                   	pop    %ebx
  101c2c:	5d                   	pop    %ebp
  101c2d:	c3                   	ret    

00101c2e <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  101c2e:	55                   	push   %ebp
  101c2f:	89 e5                	mov    %esp,%ebp
  101c31:	83 ec 38             	sub    $0x38,%esp
  101c34:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101c3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101c3e:	89 c2                	mov    %eax,%edx
  101c40:	ec                   	in     (%dx),%al
  101c41:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  101c44:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  101c48:	0f b6 c0             	movzbl %al,%eax
  101c4b:	83 e0 01             	and    $0x1,%eax
  101c4e:	85 c0                	test   %eax,%eax
  101c50:	75 0a                	jne    101c5c <kbd_proc_data+0x2e>
		return -1;
  101c52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101c57:	e9 5a 01 00 00       	jmp    101db6 <kbd_proc_data+0x188>
  101c5c:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101c63:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101c66:	89 c2                	mov    %eax,%edx
  101c68:	ec                   	in     (%dx),%al
  101c69:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  101c6c:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  101c70:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  101c73:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  101c77:	75 17                	jne    101c90 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  101c79:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c7e:	83 c8 40             	or     $0x40,%eax
  101c81:	a3 ec 6f 10 00       	mov    %eax,0x106fec
		return 0;
  101c86:	b8 00 00 00 00       	mov    $0x0,%eax
  101c8b:	e9 26 01 00 00       	jmp    101db6 <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  101c90:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101c94:	84 c0                	test   %al,%al
  101c96:	79 47                	jns    101cdf <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  101c98:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c9d:	83 e0 40             	and    $0x40,%eax
  101ca0:	85 c0                	test   %eax,%eax
  101ca2:	75 09                	jne    101cad <kbd_proc_data+0x7f>
  101ca4:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101ca8:	83 e0 7f             	and    $0x7f,%eax
  101cab:	eb 04                	jmp    101cb1 <kbd_proc_data+0x83>
  101cad:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101cb1:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  101cb4:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101cb8:	0f b6 80 a0 50 10 00 	movzbl 0x1050a0(%eax),%eax
  101cbf:	83 c8 40             	or     $0x40,%eax
  101cc2:	0f b6 c0             	movzbl %al,%eax
  101cc5:	f7 d0                	not    %eax
  101cc7:	89 c2                	mov    %eax,%edx
  101cc9:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101cce:	21 d0                	and    %edx,%eax
  101cd0:	a3 ec 6f 10 00       	mov    %eax,0x106fec
		return 0;
  101cd5:	b8 00 00 00 00       	mov    $0x0,%eax
  101cda:	e9 d7 00 00 00       	jmp    101db6 <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  101cdf:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101ce4:	83 e0 40             	and    $0x40,%eax
  101ce7:	85 c0                	test   %eax,%eax
  101ce9:	74 11                	je     101cfc <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  101ceb:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  101cef:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101cf4:	83 e0 bf             	and    $0xffffffbf,%eax
  101cf7:	a3 ec 6f 10 00       	mov    %eax,0x106fec
	}

	shift |= shiftcode[data];
  101cfc:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101d00:	0f b6 80 a0 50 10 00 	movzbl 0x1050a0(%eax),%eax
  101d07:	0f b6 d0             	movzbl %al,%edx
  101d0a:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101d0f:	09 d0                	or     %edx,%eax
  101d11:	a3 ec 6f 10 00       	mov    %eax,0x106fec
	shift ^= togglecode[data];
  101d16:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101d1a:	0f b6 80 a0 51 10 00 	movzbl 0x1051a0(%eax),%eax
  101d21:	0f b6 d0             	movzbl %al,%edx
  101d24:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101d29:	31 d0                	xor    %edx,%eax
  101d2b:	a3 ec 6f 10 00       	mov    %eax,0x106fec

	c = charcode[shift & (CTL | SHIFT)][data];
  101d30:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101d35:	83 e0 03             	and    $0x3,%eax
  101d38:	8b 14 85 a0 55 10 00 	mov    0x1055a0(,%eax,4),%edx
  101d3f:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101d43:	8d 04 02             	lea    (%edx,%eax,1),%eax
  101d46:	0f b6 00             	movzbl (%eax),%eax
  101d49:	0f b6 c0             	movzbl %al,%eax
  101d4c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  101d4f:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101d54:	83 e0 08             	and    $0x8,%eax
  101d57:	85 c0                	test   %eax,%eax
  101d59:	74 22                	je     101d7d <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  101d5b:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  101d5f:	7e 0c                	jle    101d6d <kbd_proc_data+0x13f>
  101d61:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  101d65:	7f 06                	jg     101d6d <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  101d67:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  101d6b:	eb 10                	jmp    101d7d <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  101d6d:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  101d71:	7e 0a                	jle    101d7d <kbd_proc_data+0x14f>
  101d73:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  101d77:	7f 04                	jg     101d7d <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  101d79:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  101d7d:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101d82:	f7 d0                	not    %eax
  101d84:	83 e0 06             	and    $0x6,%eax
  101d87:	85 c0                	test   %eax,%eax
  101d89:	75 28                	jne    101db3 <kbd_proc_data+0x185>
  101d8b:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  101d92:	75 1f                	jne    101db3 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  101d94:	c7 04 24 70 37 10 00 	movl   $0x103770,(%esp)
  101d9b:	e8 2a 0a 00 00       	call   1027ca <cprintf>
  101da0:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  101da7:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101dab:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101daf:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101db2:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  101db3:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  101db6:	c9                   	leave  
  101db7:	c3                   	ret    

00101db8 <kbd_intr>:

void
kbd_intr(void)
{
  101db8:	55                   	push   %ebp
  101db9:	89 e5                	mov    %esp,%ebp
  101dbb:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  101dbe:	c7 04 24 2e 1c 10 00 	movl   $0x101c2e,(%esp)
  101dc5:	e8 88 e4 ff ff       	call   100252 <cons_intr>
}
  101dca:	c9                   	leave  
  101dcb:	c3                   	ret    

00101dcc <kbd_init>:

void
kbd_init(void)
{
  101dcc:	55                   	push   %ebp
  101dcd:	89 e5                	mov    %esp,%ebp
}
  101dcf:	5d                   	pop    %ebp
  101dd0:	c3                   	ret    

00101dd1 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  101dd1:	55                   	push   %ebp
  101dd2:	89 e5                	mov    %esp,%ebp
  101dd4:	83 ec 20             	sub    $0x20,%esp
  101dd7:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101dde:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101de1:	89 c2                	mov    %eax,%edx
  101de3:	ec                   	in     (%dx),%al
  101de4:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  101de7:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101dee:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101df1:	89 c2                	mov    %eax,%edx
  101df3:	ec                   	in     (%dx),%al
  101df4:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101df7:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101dfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e01:	89 c2                	mov    %eax,%edx
  101e03:	ec                   	in     (%dx),%al
  101e04:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101e07:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101e0e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101e11:	89 c2                	mov    %eax,%edx
  101e13:	ec                   	in     (%dx),%al
  101e14:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  101e17:	c9                   	leave  
  101e18:	c3                   	ret    

00101e19 <serial_proc_data>:

static int
serial_proc_data(void)
{
  101e19:	55                   	push   %ebp
  101e1a:	89 e5                	mov    %esp,%ebp
  101e1c:	83 ec 10             	sub    $0x10,%esp
  101e1f:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  101e26:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e29:	89 c2                	mov    %eax,%edx
  101e2b:	ec                   	in     (%dx),%al
  101e2c:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101e2f:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  101e33:	0f b6 c0             	movzbl %al,%eax
  101e36:	83 e0 01             	and    $0x1,%eax
  101e39:	85 c0                	test   %eax,%eax
  101e3b:	75 07                	jne    101e44 <serial_proc_data+0x2b>
		return -1;
  101e3d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101e42:	eb 17                	jmp    101e5b <serial_proc_data+0x42>
  101e44:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101e4b:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101e4e:	89 c2                	mov    %eax,%edx
  101e50:	ec                   	in     (%dx),%al
  101e51:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101e54:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  101e58:	0f b6 c0             	movzbl %al,%eax
}
  101e5b:	c9                   	leave  
  101e5c:	c3                   	ret    

00101e5d <serial_intr>:

void
serial_intr(void)
{
  101e5d:	55                   	push   %ebp
  101e5e:	89 e5                	mov    %esp,%ebp
  101e60:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  101e63:	a1 24 70 30 00       	mov    0x307024,%eax
  101e68:	85 c0                	test   %eax,%eax
  101e6a:	74 0c                	je     101e78 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  101e6c:	c7 04 24 19 1e 10 00 	movl   $0x101e19,(%esp)
  101e73:	e8 da e3 ff ff       	call   100252 <cons_intr>
}
  101e78:	c9                   	leave  
  101e79:	c3                   	ret    

00101e7a <serial_putc>:

void
serial_putc(int c)
{
  101e7a:	55                   	push   %ebp
  101e7b:	89 e5                	mov    %esp,%ebp
  101e7d:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  101e80:	a1 24 70 30 00       	mov    0x307024,%eax
  101e85:	85 c0                	test   %eax,%eax
  101e87:	74 53                	je     101edc <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  101e89:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  101e90:	eb 09                	jmp    101e9b <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  101e92:	e8 3a ff ff ff       	call   101dd1 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  101e97:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  101e9b:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ea2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ea5:	89 c2                	mov    %eax,%edx
  101ea7:	ec                   	in     (%dx),%al
  101ea8:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  101eab:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101eaf:	0f b6 c0             	movzbl %al,%eax
  101eb2:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  101eb5:	85 c0                	test   %eax,%eax
  101eb7:	75 09                	jne    101ec2 <serial_putc+0x48>
  101eb9:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  101ec0:	7e d0                	jle    101e92 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  101ec2:	8b 45 08             	mov    0x8(%ebp),%eax
  101ec5:	0f b6 c0             	movzbl %al,%eax
  101ec8:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  101ecf:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101ed2:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101ed6:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101ed9:	ee                   	out    %al,(%dx)
  101eda:	eb 01                	jmp    101edd <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  101edc:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  101edd:	c9                   	leave  
  101ede:	c3                   	ret    

00101edf <serial_init>:

void
serial_init(void)
{
  101edf:	55                   	push   %ebp
  101ee0:	89 e5                	mov    %esp,%ebp
  101ee2:	83 ec 50             	sub    $0x50,%esp
  101ee5:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  101eec:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  101ef0:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  101ef4:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  101ef7:	ee                   	out    %al,(%dx)
  101ef8:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  101eff:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  101f03:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  101f07:	8b 55 bc             	mov    -0x44(%ebp),%edx
  101f0a:	ee                   	out    %al,(%dx)
  101f0b:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  101f12:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  101f16:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  101f1a:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  101f1d:	ee                   	out    %al,(%dx)
  101f1e:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  101f25:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  101f29:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  101f2d:	8b 55 cc             	mov    -0x34(%ebp),%edx
  101f30:	ee                   	out    %al,(%dx)
  101f31:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  101f38:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  101f3c:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  101f40:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101f43:	ee                   	out    %al,(%dx)
  101f44:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  101f4b:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  101f4f:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101f53:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101f56:	ee                   	out    %al,(%dx)
  101f57:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  101f5e:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  101f62:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101f66:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101f69:	ee                   	out    %al,(%dx)
  101f6a:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101f71:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101f74:	89 c2                	mov    %eax,%edx
  101f76:	ec                   	in     (%dx),%al
  101f77:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101f7a:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  101f7e:	3c ff                	cmp    $0xff,%al
  101f80:	0f 95 c0             	setne  %al
  101f83:	0f b6 c0             	movzbl %al,%eax
  101f86:	a3 24 70 30 00       	mov    %eax,0x307024
  101f8b:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101f92:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f95:	89 c2                	mov    %eax,%edx
  101f97:	ec                   	in     (%dx),%al
  101f98:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101f9b:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101fa2:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101fa5:	89 c2                	mov    %eax,%edx
  101fa7:	ec                   	in     (%dx),%al
  101fa8:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  101fab:	c9                   	leave  
  101fac:	c3                   	ret    

00101fad <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  101fad:	55                   	push   %ebp
  101fae:	89 e5                	mov    %esp,%ebp
  101fb0:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101fb3:	8b 45 08             	mov    0x8(%ebp),%eax
  101fb6:	0f b6 c0             	movzbl %al,%eax
  101fb9:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101fc0:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101fc3:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101fc7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101fca:	ee                   	out    %al,(%dx)
  101fcb:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101fd2:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101fd5:	89 c2                	mov    %eax,%edx
  101fd7:	ec                   	in     (%dx),%al
  101fd8:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101fdb:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  101fdf:	0f b6 c0             	movzbl %al,%eax
}
  101fe2:	c9                   	leave  
  101fe3:	c3                   	ret    

00101fe4 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  101fe4:	55                   	push   %ebp
  101fe5:	89 e5                	mov    %esp,%ebp
  101fe7:	53                   	push   %ebx
  101fe8:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  101feb:	8b 45 08             	mov    0x8(%ebp),%eax
  101fee:	89 04 24             	mov    %eax,(%esp)
  101ff1:	e8 b7 ff ff ff       	call   101fad <nvram_read>
  101ff6:	89 c3                	mov    %eax,%ebx
  101ff8:	8b 45 08             	mov    0x8(%ebp),%eax
  101ffb:	83 c0 01             	add    $0x1,%eax
  101ffe:	89 04 24             	mov    %eax,(%esp)
  102001:	e8 a7 ff ff ff       	call   101fad <nvram_read>
  102006:	c1 e0 08             	shl    $0x8,%eax
  102009:	09 d8                	or     %ebx,%eax
}
  10200b:	83 c4 04             	add    $0x4,%esp
  10200e:	5b                   	pop    %ebx
  10200f:	5d                   	pop    %ebp
  102010:	c3                   	ret    

00102011 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  102011:	55                   	push   %ebp
  102012:	89 e5                	mov    %esp,%ebp
  102014:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  102017:	8b 45 08             	mov    0x8(%ebp),%eax
  10201a:	0f b6 c0             	movzbl %al,%eax
  10201d:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  102024:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102027:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10202b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10202e:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  10202f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102032:	0f b6 c0             	movzbl %al,%eax
  102035:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  10203c:	88 45 fb             	mov    %al,-0x5(%ebp)
  10203f:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  102043:	8b 55 fc             	mov    -0x4(%ebp),%edx
  102046:	ee                   	out    %al,(%dx)
}
  102047:	c9                   	leave  
  102048:	c3                   	ret    

00102049 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  102049:	55                   	push   %ebp
  10204a:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  10204c:	8b 45 08             	mov    0x8(%ebp),%eax
  10204f:	8b 40 18             	mov    0x18(%eax),%eax
  102052:	83 e0 02             	and    $0x2,%eax
  102055:	85 c0                	test   %eax,%eax
  102057:	74 1c                	je     102075 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  102059:	8b 45 0c             	mov    0xc(%ebp),%eax
  10205c:	8b 00                	mov    (%eax),%eax
  10205e:	8d 50 08             	lea    0x8(%eax),%edx
  102061:	8b 45 0c             	mov    0xc(%ebp),%eax
  102064:	89 10                	mov    %edx,(%eax)
  102066:	8b 45 0c             	mov    0xc(%ebp),%eax
  102069:	8b 00                	mov    (%eax),%eax
  10206b:	83 e8 08             	sub    $0x8,%eax
  10206e:	8b 50 04             	mov    0x4(%eax),%edx
  102071:	8b 00                	mov    (%eax),%eax
  102073:	eb 47                	jmp    1020bc <getuint+0x73>
	else if (st->flags & F_L)
  102075:	8b 45 08             	mov    0x8(%ebp),%eax
  102078:	8b 40 18             	mov    0x18(%eax),%eax
  10207b:	83 e0 01             	and    $0x1,%eax
  10207e:	84 c0                	test   %al,%al
  102080:	74 1e                	je     1020a0 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  102082:	8b 45 0c             	mov    0xc(%ebp),%eax
  102085:	8b 00                	mov    (%eax),%eax
  102087:	8d 50 04             	lea    0x4(%eax),%edx
  10208a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10208d:	89 10                	mov    %edx,(%eax)
  10208f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102092:	8b 00                	mov    (%eax),%eax
  102094:	83 e8 04             	sub    $0x4,%eax
  102097:	8b 00                	mov    (%eax),%eax
  102099:	ba 00 00 00 00       	mov    $0x0,%edx
  10209e:	eb 1c                	jmp    1020bc <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  1020a0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020a3:	8b 00                	mov    (%eax),%eax
  1020a5:	8d 50 04             	lea    0x4(%eax),%edx
  1020a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020ab:	89 10                	mov    %edx,(%eax)
  1020ad:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020b0:	8b 00                	mov    (%eax),%eax
  1020b2:	83 e8 04             	sub    $0x4,%eax
  1020b5:	8b 00                	mov    (%eax),%eax
  1020b7:	ba 00 00 00 00       	mov    $0x0,%edx
}
  1020bc:	5d                   	pop    %ebp
  1020bd:	c3                   	ret    

001020be <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  1020be:	55                   	push   %ebp
  1020bf:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  1020c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1020c4:	8b 40 18             	mov    0x18(%eax),%eax
  1020c7:	83 e0 02             	and    $0x2,%eax
  1020ca:	85 c0                	test   %eax,%eax
  1020cc:	74 1c                	je     1020ea <getint+0x2c>
		return va_arg(*ap, long long);
  1020ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020d1:	8b 00                	mov    (%eax),%eax
  1020d3:	8d 50 08             	lea    0x8(%eax),%edx
  1020d6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020d9:	89 10                	mov    %edx,(%eax)
  1020db:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020de:	8b 00                	mov    (%eax),%eax
  1020e0:	83 e8 08             	sub    $0x8,%eax
  1020e3:	8b 50 04             	mov    0x4(%eax),%edx
  1020e6:	8b 00                	mov    (%eax),%eax
  1020e8:	eb 47                	jmp    102131 <getint+0x73>
	else if (st->flags & F_L)
  1020ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1020ed:	8b 40 18             	mov    0x18(%eax),%eax
  1020f0:	83 e0 01             	and    $0x1,%eax
  1020f3:	84 c0                	test   %al,%al
  1020f5:	74 1e                	je     102115 <getint+0x57>
		return va_arg(*ap, long);
  1020f7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020fa:	8b 00                	mov    (%eax),%eax
  1020fc:	8d 50 04             	lea    0x4(%eax),%edx
  1020ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  102102:	89 10                	mov    %edx,(%eax)
  102104:	8b 45 0c             	mov    0xc(%ebp),%eax
  102107:	8b 00                	mov    (%eax),%eax
  102109:	83 e8 04             	sub    $0x4,%eax
  10210c:	8b 00                	mov    (%eax),%eax
  10210e:	89 c2                	mov    %eax,%edx
  102110:	c1 fa 1f             	sar    $0x1f,%edx
  102113:	eb 1c                	jmp    102131 <getint+0x73>
	else
		return va_arg(*ap, int);
  102115:	8b 45 0c             	mov    0xc(%ebp),%eax
  102118:	8b 00                	mov    (%eax),%eax
  10211a:	8d 50 04             	lea    0x4(%eax),%edx
  10211d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102120:	89 10                	mov    %edx,(%eax)
  102122:	8b 45 0c             	mov    0xc(%ebp),%eax
  102125:	8b 00                	mov    (%eax),%eax
  102127:	83 e8 04             	sub    $0x4,%eax
  10212a:	8b 00                	mov    (%eax),%eax
  10212c:	89 c2                	mov    %eax,%edx
  10212e:	c1 fa 1f             	sar    $0x1f,%edx
}
  102131:	5d                   	pop    %ebp
  102132:	c3                   	ret    

00102133 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  102133:	55                   	push   %ebp
  102134:	89 e5                	mov    %esp,%ebp
  102136:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  102139:	eb 1a                	jmp    102155 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  10213b:	8b 45 08             	mov    0x8(%ebp),%eax
  10213e:	8b 08                	mov    (%eax),%ecx
  102140:	8b 45 08             	mov    0x8(%ebp),%eax
  102143:	8b 50 04             	mov    0x4(%eax),%edx
  102146:	8b 45 08             	mov    0x8(%ebp),%eax
  102149:	8b 40 08             	mov    0x8(%eax),%eax
  10214c:	89 54 24 04          	mov    %edx,0x4(%esp)
  102150:	89 04 24             	mov    %eax,(%esp)
  102153:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  102155:	8b 45 08             	mov    0x8(%ebp),%eax
  102158:	8b 40 0c             	mov    0xc(%eax),%eax
  10215b:	8d 50 ff             	lea    -0x1(%eax),%edx
  10215e:	8b 45 08             	mov    0x8(%ebp),%eax
  102161:	89 50 0c             	mov    %edx,0xc(%eax)
  102164:	8b 45 08             	mov    0x8(%ebp),%eax
  102167:	8b 40 0c             	mov    0xc(%eax),%eax
  10216a:	85 c0                	test   %eax,%eax
  10216c:	79 cd                	jns    10213b <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  10216e:	c9                   	leave  
  10216f:	c3                   	ret    

00102170 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  102170:	55                   	push   %ebp
  102171:	89 e5                	mov    %esp,%ebp
  102173:	53                   	push   %ebx
  102174:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  102177:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10217b:	79 18                	jns    102195 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  10217d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102184:	00 
  102185:	8b 45 0c             	mov    0xc(%ebp),%eax
  102188:	89 04 24             	mov    %eax,(%esp)
  10218b:	e8 e7 07 00 00       	call   102977 <strchr>
  102190:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102193:	eb 2c                	jmp    1021c1 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  102195:	8b 45 10             	mov    0x10(%ebp),%eax
  102198:	89 44 24 08          	mov    %eax,0x8(%esp)
  10219c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1021a3:	00 
  1021a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021a7:	89 04 24             	mov    %eax,(%esp)
  1021aa:	e8 cc 09 00 00       	call   102b7b <memchr>
  1021af:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1021b2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1021b6:	75 09                	jne    1021c1 <putstr+0x51>
		lim = str + maxlen;
  1021b8:	8b 45 10             	mov    0x10(%ebp),%eax
  1021bb:	03 45 0c             	add    0xc(%ebp),%eax
  1021be:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  1021c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1021c4:	8b 40 0c             	mov    0xc(%eax),%eax
  1021c7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  1021ca:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1021cd:	89 cb                	mov    %ecx,%ebx
  1021cf:	29 d3                	sub    %edx,%ebx
  1021d1:	89 da                	mov    %ebx,%edx
  1021d3:	8d 14 10             	lea    (%eax,%edx,1),%edx
  1021d6:	8b 45 08             	mov    0x8(%ebp),%eax
  1021d9:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  1021dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1021df:	8b 40 18             	mov    0x18(%eax),%eax
  1021e2:	83 e0 10             	and    $0x10,%eax
  1021e5:	85 c0                	test   %eax,%eax
  1021e7:	75 32                	jne    10221b <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  1021e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1021ec:	89 04 24             	mov    %eax,(%esp)
  1021ef:	e8 3f ff ff ff       	call   102133 <putpad>
	while (str < lim) {
  1021f4:	eb 25                	jmp    10221b <putstr+0xab>
		char ch = *str++;
  1021f6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021f9:	0f b6 00             	movzbl (%eax),%eax
  1021fc:	88 45 f7             	mov    %al,-0x9(%ebp)
  1021ff:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  102203:	8b 45 08             	mov    0x8(%ebp),%eax
  102206:	8b 08                	mov    (%eax),%ecx
  102208:	8b 45 08             	mov    0x8(%ebp),%eax
  10220b:	8b 50 04             	mov    0x4(%eax),%edx
  10220e:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  102212:	89 54 24 04          	mov    %edx,0x4(%esp)
  102216:	89 04 24             	mov    %eax,(%esp)
  102219:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  10221b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10221e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102221:	72 d3                	jb     1021f6 <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  102223:	8b 45 08             	mov    0x8(%ebp),%eax
  102226:	89 04 24             	mov    %eax,(%esp)
  102229:	e8 05 ff ff ff       	call   102133 <putpad>
}
  10222e:	83 c4 24             	add    $0x24,%esp
  102231:	5b                   	pop    %ebx
  102232:	5d                   	pop    %ebp
  102233:	c3                   	ret    

00102234 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  102234:	55                   	push   %ebp
  102235:	89 e5                	mov    %esp,%ebp
  102237:	53                   	push   %ebx
  102238:	83 ec 24             	sub    $0x24,%esp
  10223b:	8b 45 10             	mov    0x10(%ebp),%eax
  10223e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102241:	8b 45 14             	mov    0x14(%ebp),%eax
  102244:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  102247:	8b 45 08             	mov    0x8(%ebp),%eax
  10224a:	8b 40 1c             	mov    0x1c(%eax),%eax
  10224d:	89 c2                	mov    %eax,%edx
  10224f:	c1 fa 1f             	sar    $0x1f,%edx
  102252:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  102255:	77 4e                	ja     1022a5 <genint+0x71>
  102257:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  10225a:	72 05                	jb     102261 <genint+0x2d>
  10225c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10225f:	77 44                	ja     1022a5 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  102261:	8b 45 08             	mov    0x8(%ebp),%eax
  102264:	8b 40 1c             	mov    0x1c(%eax),%eax
  102267:	89 c2                	mov    %eax,%edx
  102269:	c1 fa 1f             	sar    $0x1f,%edx
  10226c:	89 44 24 08          	mov    %eax,0x8(%esp)
  102270:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102274:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102277:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10227a:	89 04 24             	mov    %eax,(%esp)
  10227d:	89 54 24 04          	mov    %edx,0x4(%esp)
  102281:	e8 3a 09 00 00       	call   102bc0 <__udivdi3>
  102286:	89 44 24 08          	mov    %eax,0x8(%esp)
  10228a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10228e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102291:	89 44 24 04          	mov    %eax,0x4(%esp)
  102295:	8b 45 08             	mov    0x8(%ebp),%eax
  102298:	89 04 24             	mov    %eax,(%esp)
  10229b:	e8 94 ff ff ff       	call   102234 <genint>
  1022a0:	89 45 0c             	mov    %eax,0xc(%ebp)
  1022a3:	eb 1b                	jmp    1022c0 <genint+0x8c>
	else if (st->signc >= 0)
  1022a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1022a8:	8b 40 14             	mov    0x14(%eax),%eax
  1022ab:	85 c0                	test   %eax,%eax
  1022ad:	78 11                	js     1022c0 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  1022af:	8b 45 08             	mov    0x8(%ebp),%eax
  1022b2:	8b 40 14             	mov    0x14(%eax),%eax
  1022b5:	89 c2                	mov    %eax,%edx
  1022b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022ba:	88 10                	mov    %dl,(%eax)
  1022bc:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  1022c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1022c3:	8b 40 1c             	mov    0x1c(%eax),%eax
  1022c6:	89 c1                	mov    %eax,%ecx
  1022c8:	89 c3                	mov    %eax,%ebx
  1022ca:	c1 fb 1f             	sar    $0x1f,%ebx
  1022cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1022d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1022d3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1022d7:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  1022db:	89 04 24             	mov    %eax,(%esp)
  1022de:	89 54 24 04          	mov    %edx,0x4(%esp)
  1022e2:	e8 09 0a 00 00       	call   102cf0 <__umoddi3>
  1022e7:	05 7c 37 10 00       	add    $0x10377c,%eax
  1022ec:	0f b6 10             	movzbl (%eax),%edx
  1022ef:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022f2:	88 10                	mov    %dl,(%eax)
  1022f4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  1022f8:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  1022fb:	83 c4 24             	add    $0x24,%esp
  1022fe:	5b                   	pop    %ebx
  1022ff:	5d                   	pop    %ebp
  102300:	c3                   	ret    

00102301 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  102301:	55                   	push   %ebp
  102302:	89 e5                	mov    %esp,%ebp
  102304:	83 ec 58             	sub    $0x58,%esp
  102307:	8b 45 0c             	mov    0xc(%ebp),%eax
  10230a:	89 45 c0             	mov    %eax,-0x40(%ebp)
  10230d:	8b 45 10             	mov    0x10(%ebp),%eax
  102310:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  102313:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  102316:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  102319:	8b 45 08             	mov    0x8(%ebp),%eax
  10231c:	8b 55 14             	mov    0x14(%ebp),%edx
  10231f:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  102322:	8b 45 c0             	mov    -0x40(%ebp),%eax
  102325:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  102328:	89 44 24 08          	mov    %eax,0x8(%esp)
  10232c:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102330:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102333:	89 44 24 04          	mov    %eax,0x4(%esp)
  102337:	8b 45 08             	mov    0x8(%ebp),%eax
  10233a:	89 04 24             	mov    %eax,(%esp)
  10233d:	e8 f2 fe ff ff       	call   102234 <genint>
  102342:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  102345:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102348:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  10234b:	89 d1                	mov    %edx,%ecx
  10234d:	29 c1                	sub    %eax,%ecx
  10234f:	89 c8                	mov    %ecx,%eax
  102351:	89 44 24 08          	mov    %eax,0x8(%esp)
  102355:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  102358:	89 44 24 04          	mov    %eax,0x4(%esp)
  10235c:	8b 45 08             	mov    0x8(%ebp),%eax
  10235f:	89 04 24             	mov    %eax,(%esp)
  102362:	e8 09 fe ff ff       	call   102170 <putstr>
}
  102367:	c9                   	leave  
  102368:	c3                   	ret    

00102369 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  102369:	55                   	push   %ebp
  10236a:	89 e5                	mov    %esp,%ebp
  10236c:	53                   	push   %ebx
  10236d:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  102370:	8d 55 c8             	lea    -0x38(%ebp),%edx
  102373:	b9 00 00 00 00       	mov    $0x0,%ecx
  102378:	b8 20 00 00 00       	mov    $0x20,%eax
  10237d:	89 c3                	mov    %eax,%ebx
  10237f:	83 e3 fc             	and    $0xfffffffc,%ebx
  102382:	b8 00 00 00 00       	mov    $0x0,%eax
  102387:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  10238a:	83 c0 04             	add    $0x4,%eax
  10238d:	39 d8                	cmp    %ebx,%eax
  10238f:	72 f6                	jb     102387 <vprintfmt+0x1e>
  102391:	01 c2                	add    %eax,%edx
  102393:	8b 45 08             	mov    0x8(%ebp),%eax
  102396:	89 45 c8             	mov    %eax,-0x38(%ebp)
  102399:	8b 45 0c             	mov    0xc(%ebp),%eax
  10239c:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10239f:	eb 17                	jmp    1023b8 <vprintfmt+0x4f>
			if (ch == '\0')
  1023a1:	85 db                	test   %ebx,%ebx
  1023a3:	0f 84 52 03 00 00    	je     1026fb <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  1023a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023b0:	89 1c 24             	mov    %ebx,(%esp)
  1023b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1023b6:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1023b8:	8b 45 10             	mov    0x10(%ebp),%eax
  1023bb:	0f b6 00             	movzbl (%eax),%eax
  1023be:	0f b6 d8             	movzbl %al,%ebx
  1023c1:	83 fb 25             	cmp    $0x25,%ebx
  1023c4:	0f 95 c0             	setne  %al
  1023c7:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1023cb:	84 c0                	test   %al,%al
  1023cd:	75 d2                	jne    1023a1 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  1023cf:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  1023d6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  1023dd:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  1023e4:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  1023eb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  1023f2:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  1023f9:	eb 04                	jmp    1023ff <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  1023fb:	90                   	nop
  1023fc:	eb 01                	jmp    1023ff <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  1023fe:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  1023ff:	8b 45 10             	mov    0x10(%ebp),%eax
  102402:	0f b6 00             	movzbl (%eax),%eax
  102405:	0f b6 d8             	movzbl %al,%ebx
  102408:	89 d8                	mov    %ebx,%eax
  10240a:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10240e:	83 e8 20             	sub    $0x20,%eax
  102411:	83 f8 58             	cmp    $0x58,%eax
  102414:	0f 87 b1 02 00 00    	ja     1026cb <vprintfmt+0x362>
  10241a:	8b 04 85 94 37 10 00 	mov    0x103794(,%eax,4),%eax
  102421:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  102423:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102426:	83 c8 10             	or     $0x10,%eax
  102429:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10242c:	eb d1                	jmp    1023ff <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  10242e:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  102435:	eb c8                	jmp    1023ff <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  102437:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10243a:	85 c0                	test   %eax,%eax
  10243c:	79 bd                	jns    1023fb <vprintfmt+0x92>
				st.signc = ' ';
  10243e:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  102445:	eb b8                	jmp    1023ff <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  102447:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10244a:	83 e0 08             	and    $0x8,%eax
  10244d:	85 c0                	test   %eax,%eax
  10244f:	75 07                	jne    102458 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  102451:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  102458:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  10245f:	8b 55 d8             	mov    -0x28(%ebp),%edx
  102462:	89 d0                	mov    %edx,%eax
  102464:	c1 e0 02             	shl    $0x2,%eax
  102467:	01 d0                	add    %edx,%eax
  102469:	01 c0                	add    %eax,%eax
  10246b:	01 d8                	add    %ebx,%eax
  10246d:	83 e8 30             	sub    $0x30,%eax
  102470:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  102473:	8b 45 10             	mov    0x10(%ebp),%eax
  102476:	0f b6 00             	movzbl (%eax),%eax
  102479:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  10247c:	83 fb 2f             	cmp    $0x2f,%ebx
  10247f:	7e 21                	jle    1024a2 <vprintfmt+0x139>
  102481:	83 fb 39             	cmp    $0x39,%ebx
  102484:	7f 1f                	jg     1024a5 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  102486:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  10248a:	eb d3                	jmp    10245f <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  10248c:	8b 45 14             	mov    0x14(%ebp),%eax
  10248f:	83 c0 04             	add    $0x4,%eax
  102492:	89 45 14             	mov    %eax,0x14(%ebp)
  102495:	8b 45 14             	mov    0x14(%ebp),%eax
  102498:	83 e8 04             	sub    $0x4,%eax
  10249b:	8b 00                	mov    (%eax),%eax
  10249d:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1024a0:	eb 04                	jmp    1024a6 <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  1024a2:	90                   	nop
  1024a3:	eb 01                	jmp    1024a6 <vprintfmt+0x13d>
  1024a5:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  1024a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1024a9:	83 e0 08             	and    $0x8,%eax
  1024ac:	85 c0                	test   %eax,%eax
  1024ae:	0f 85 4a ff ff ff    	jne    1023fe <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  1024b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1024b7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  1024ba:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  1024c1:	e9 39 ff ff ff       	jmp    1023ff <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  1024c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1024c9:	83 c8 08             	or     $0x8,%eax
  1024cc:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1024cf:	e9 2b ff ff ff       	jmp    1023ff <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  1024d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1024d7:	83 c8 04             	or     $0x4,%eax
  1024da:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1024dd:	e9 1d ff ff ff       	jmp    1023ff <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  1024e2:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1024e5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1024e8:	83 e0 01             	and    $0x1,%eax
  1024eb:	84 c0                	test   %al,%al
  1024ed:	74 07                	je     1024f6 <vprintfmt+0x18d>
  1024ef:	b8 02 00 00 00       	mov    $0x2,%eax
  1024f4:	eb 05                	jmp    1024fb <vprintfmt+0x192>
  1024f6:	b8 01 00 00 00       	mov    $0x1,%eax
  1024fb:	09 d0                	or     %edx,%eax
  1024fd:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102500:	e9 fa fe ff ff       	jmp    1023ff <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  102505:	8b 45 14             	mov    0x14(%ebp),%eax
  102508:	83 c0 04             	add    $0x4,%eax
  10250b:	89 45 14             	mov    %eax,0x14(%ebp)
  10250e:	8b 45 14             	mov    0x14(%ebp),%eax
  102511:	83 e8 04             	sub    $0x4,%eax
  102514:	8b 00                	mov    (%eax),%eax
  102516:	8b 55 0c             	mov    0xc(%ebp),%edx
  102519:	89 54 24 04          	mov    %edx,0x4(%esp)
  10251d:	89 04 24             	mov    %eax,(%esp)
  102520:	8b 45 08             	mov    0x8(%ebp),%eax
  102523:	ff d0                	call   *%eax
			break;
  102525:	e9 cb 01 00 00       	jmp    1026f5 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  10252a:	8b 45 14             	mov    0x14(%ebp),%eax
  10252d:	83 c0 04             	add    $0x4,%eax
  102530:	89 45 14             	mov    %eax,0x14(%ebp)
  102533:	8b 45 14             	mov    0x14(%ebp),%eax
  102536:	83 e8 04             	sub    $0x4,%eax
  102539:	8b 00                	mov    (%eax),%eax
  10253b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10253e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102542:	75 07                	jne    10254b <vprintfmt+0x1e2>
				s = "(null)";
  102544:	c7 45 f4 8d 37 10 00 	movl   $0x10378d,-0xc(%ebp)
			putstr(&st, s, st.prec);
  10254b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10254e:	89 44 24 08          	mov    %eax,0x8(%esp)
  102552:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102555:	89 44 24 04          	mov    %eax,0x4(%esp)
  102559:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10255c:	89 04 24             	mov    %eax,(%esp)
  10255f:	e8 0c fc ff ff       	call   102170 <putstr>
			break;
  102564:	e9 8c 01 00 00       	jmp    1026f5 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  102569:	8d 45 14             	lea    0x14(%ebp),%eax
  10256c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102570:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102573:	89 04 24             	mov    %eax,(%esp)
  102576:	e8 43 fb ff ff       	call   1020be <getint>
  10257b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10257e:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  102581:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102584:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102587:	85 d2                	test   %edx,%edx
  102589:	79 1a                	jns    1025a5 <vprintfmt+0x23c>
				num = -(intmax_t) num;
  10258b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10258e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102591:	f7 d8                	neg    %eax
  102593:	83 d2 00             	adc    $0x0,%edx
  102596:	f7 da                	neg    %edx
  102598:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10259b:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  10259e:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  1025a5:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1025ac:	00 
  1025ad:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1025b0:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1025b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025b7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1025bb:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1025be:	89 04 24             	mov    %eax,(%esp)
  1025c1:	e8 3b fd ff ff       	call   102301 <putint>
			break;
  1025c6:	e9 2a 01 00 00       	jmp    1026f5 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  1025cb:	8d 45 14             	lea    0x14(%ebp),%eax
  1025ce:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025d2:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1025d5:	89 04 24             	mov    %eax,(%esp)
  1025d8:	e8 6c fa ff ff       	call   102049 <getuint>
  1025dd:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1025e4:	00 
  1025e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025e9:	89 54 24 08          	mov    %edx,0x8(%esp)
  1025ed:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1025f0:	89 04 24             	mov    %eax,(%esp)
  1025f3:	e8 09 fd ff ff       	call   102301 <putint>
			break;
  1025f8:	e9 f8 00 00 00       	jmp    1026f5 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  1025fd:	8d 45 14             	lea    0x14(%ebp),%eax
  102600:	89 44 24 04          	mov    %eax,0x4(%esp)
  102604:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102607:	89 04 24             	mov    %eax,(%esp)
  10260a:	e8 3a fa ff ff       	call   102049 <getuint>
  10260f:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  102616:	00 
  102617:	89 44 24 04          	mov    %eax,0x4(%esp)
  10261b:	89 54 24 08          	mov    %edx,0x8(%esp)
  10261f:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102622:	89 04 24             	mov    %eax,(%esp)
  102625:	e8 d7 fc ff ff       	call   102301 <putint>
			break;
  10262a:	e9 c6 00 00 00       	jmp    1026f5 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10262f:	8d 45 14             	lea    0x14(%ebp),%eax
  102632:	89 44 24 04          	mov    %eax,0x4(%esp)
  102636:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102639:	89 04 24             	mov    %eax,(%esp)
  10263c:	e8 08 fa ff ff       	call   102049 <getuint>
  102641:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  102648:	00 
  102649:	89 44 24 04          	mov    %eax,0x4(%esp)
  10264d:	89 54 24 08          	mov    %edx,0x8(%esp)
  102651:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102654:	89 04 24             	mov    %eax,(%esp)
  102657:	e8 a5 fc ff ff       	call   102301 <putint>
			break;
  10265c:	e9 94 00 00 00       	jmp    1026f5 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  102661:	8b 45 0c             	mov    0xc(%ebp),%eax
  102664:	89 44 24 04          	mov    %eax,0x4(%esp)
  102668:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10266f:	8b 45 08             	mov    0x8(%ebp),%eax
  102672:	ff d0                	call   *%eax
			putch('x', putdat);
  102674:	8b 45 0c             	mov    0xc(%ebp),%eax
  102677:	89 44 24 04          	mov    %eax,0x4(%esp)
  10267b:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  102682:	8b 45 08             	mov    0x8(%ebp),%eax
  102685:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  102687:	8b 45 14             	mov    0x14(%ebp),%eax
  10268a:	83 c0 04             	add    $0x4,%eax
  10268d:	89 45 14             	mov    %eax,0x14(%ebp)
  102690:	8b 45 14             	mov    0x14(%ebp),%eax
  102693:	83 e8 04             	sub    $0x4,%eax
  102696:	8b 00                	mov    (%eax),%eax
  102698:	ba 00 00 00 00       	mov    $0x0,%edx
  10269d:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1026a4:	00 
  1026a5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1026a9:	89 54 24 08          	mov    %edx,0x8(%esp)
  1026ad:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1026b0:	89 04 24             	mov    %eax,(%esp)
  1026b3:	e8 49 fc ff ff       	call   102301 <putint>
			break;
  1026b8:	eb 3b                	jmp    1026f5 <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  1026ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1026c1:	89 1c 24             	mov    %ebx,(%esp)
  1026c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1026c7:	ff d0                	call   *%eax
			break;
  1026c9:	eb 2a                	jmp    1026f5 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1026cb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026ce:	89 44 24 04          	mov    %eax,0x4(%esp)
  1026d2:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  1026d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1026dc:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  1026de:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1026e2:	eb 04                	jmp    1026e8 <vprintfmt+0x37f>
  1026e4:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1026e8:	8b 45 10             	mov    0x10(%ebp),%eax
  1026eb:	83 e8 01             	sub    $0x1,%eax
  1026ee:	0f b6 00             	movzbl (%eax),%eax
  1026f1:	3c 25                	cmp    $0x25,%al
  1026f3:	75 ef                	jne    1026e4 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  1026f5:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1026f6:	e9 bd fc ff ff       	jmp    1023b8 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  1026fb:	83 c4 44             	add    $0x44,%esp
  1026fe:	5b                   	pop    %ebx
  1026ff:	5d                   	pop    %ebp
  102700:	c3                   	ret    

00102701 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  102701:	55                   	push   %ebp
  102702:	89 e5                	mov    %esp,%ebp
  102704:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  102707:	8b 45 0c             	mov    0xc(%ebp),%eax
  10270a:	8b 00                	mov    (%eax),%eax
  10270c:	8b 55 08             	mov    0x8(%ebp),%edx
  10270f:	89 d1                	mov    %edx,%ecx
  102711:	8b 55 0c             	mov    0xc(%ebp),%edx
  102714:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  102718:	8d 50 01             	lea    0x1(%eax),%edx
  10271b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10271e:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  102720:	8b 45 0c             	mov    0xc(%ebp),%eax
  102723:	8b 00                	mov    (%eax),%eax
  102725:	3d ff 00 00 00       	cmp    $0xff,%eax
  10272a:	75 24                	jne    102750 <putch+0x4f>
		b->buf[b->idx] = 0;
  10272c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10272f:	8b 00                	mov    (%eax),%eax
  102731:	8b 55 0c             	mov    0xc(%ebp),%edx
  102734:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  102739:	8b 45 0c             	mov    0xc(%ebp),%eax
  10273c:	83 c0 08             	add    $0x8,%eax
  10273f:	89 04 24             	mov    %eax,(%esp)
  102742:	e8 19 dc ff ff       	call   100360 <cputs>
		b->idx = 0;
  102747:	8b 45 0c             	mov    0xc(%ebp),%eax
  10274a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  102750:	8b 45 0c             	mov    0xc(%ebp),%eax
  102753:	8b 40 04             	mov    0x4(%eax),%eax
  102756:	8d 50 01             	lea    0x1(%eax),%edx
  102759:	8b 45 0c             	mov    0xc(%ebp),%eax
  10275c:	89 50 04             	mov    %edx,0x4(%eax)
}
  10275f:	c9                   	leave  
  102760:	c3                   	ret    

00102761 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  102761:	55                   	push   %ebp
  102762:	89 e5                	mov    %esp,%ebp
  102764:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  10276a:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  102771:	00 00 00 
	b.cnt = 0;
  102774:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  10277b:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  10277e:	b8 01 27 10 00       	mov    $0x102701,%eax
  102783:	8b 55 0c             	mov    0xc(%ebp),%edx
  102786:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10278a:	8b 55 08             	mov    0x8(%ebp),%edx
  10278d:	89 54 24 08          	mov    %edx,0x8(%esp)
  102791:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  102797:	89 54 24 04          	mov    %edx,0x4(%esp)
  10279b:	89 04 24             	mov    %eax,(%esp)
  10279e:	e8 c6 fb ff ff       	call   102369 <vprintfmt>

	b.buf[b.idx] = 0;
  1027a3:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  1027a9:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  1027b0:	00 
	cputs(b.buf);
  1027b1:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1027b7:	83 c0 08             	add    $0x8,%eax
  1027ba:	89 04 24             	mov    %eax,(%esp)
  1027bd:	e8 9e db ff ff       	call   100360 <cputs>

	return b.cnt;
  1027c2:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  1027c8:	c9                   	leave  
  1027c9:	c3                   	ret    

001027ca <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1027ca:	55                   	push   %ebp
  1027cb:	89 e5                	mov    %esp,%ebp
  1027cd:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  1027d0:	8d 45 08             	lea    0x8(%ebp),%eax
  1027d3:	83 c0 04             	add    $0x4,%eax
  1027d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  1027d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1027dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1027df:	89 54 24 04          	mov    %edx,0x4(%esp)
  1027e3:	89 04 24             	mov    %eax,(%esp)
  1027e6:	e8 76 ff ff ff       	call   102761 <vcprintf>
  1027eb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  1027ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1027f1:	c9                   	leave  
  1027f2:	c3                   	ret    

001027f3 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  1027f3:	55                   	push   %ebp
  1027f4:	89 e5                	mov    %esp,%ebp
  1027f6:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  1027f9:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  102800:	eb 08                	jmp    10280a <strlen+0x17>
		n++;
  102802:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  102806:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10280a:	8b 45 08             	mov    0x8(%ebp),%eax
  10280d:	0f b6 00             	movzbl (%eax),%eax
  102810:	84 c0                	test   %al,%al
  102812:	75 ee                	jne    102802 <strlen+0xf>
		n++;
	return n;
  102814:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102817:	c9                   	leave  
  102818:	c3                   	ret    

00102819 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  102819:	55                   	push   %ebp
  10281a:	89 e5                	mov    %esp,%ebp
  10281c:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  10281f:	8b 45 08             	mov    0x8(%ebp),%eax
  102822:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  102825:	8b 45 0c             	mov    0xc(%ebp),%eax
  102828:	0f b6 10             	movzbl (%eax),%edx
  10282b:	8b 45 08             	mov    0x8(%ebp),%eax
  10282e:	88 10                	mov    %dl,(%eax)
  102830:	8b 45 08             	mov    0x8(%ebp),%eax
  102833:	0f b6 00             	movzbl (%eax),%eax
  102836:	84 c0                	test   %al,%al
  102838:	0f 95 c0             	setne  %al
  10283b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10283f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  102843:	84 c0                	test   %al,%al
  102845:	75 de                	jne    102825 <strcpy+0xc>
		/* do nothing */;
	return ret;
  102847:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10284a:	c9                   	leave  
  10284b:	c3                   	ret    

0010284c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  10284c:	55                   	push   %ebp
  10284d:	89 e5                	mov    %esp,%ebp
  10284f:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  102852:	8b 45 08             	mov    0x8(%ebp),%eax
  102855:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  102858:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  10285f:	eb 21                	jmp    102882 <strncpy+0x36>
		*dst++ = *src;
  102861:	8b 45 0c             	mov    0xc(%ebp),%eax
  102864:	0f b6 10             	movzbl (%eax),%edx
  102867:	8b 45 08             	mov    0x8(%ebp),%eax
  10286a:	88 10                	mov    %dl,(%eax)
  10286c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  102870:	8b 45 0c             	mov    0xc(%ebp),%eax
  102873:	0f b6 00             	movzbl (%eax),%eax
  102876:	84 c0                	test   %al,%al
  102878:	74 04                	je     10287e <strncpy+0x32>
			src++;
  10287a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  10287e:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  102882:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102885:	3b 45 10             	cmp    0x10(%ebp),%eax
  102888:	72 d7                	jb     102861 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  10288a:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10288d:	c9                   	leave  
  10288e:	c3                   	ret    

0010288f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  10288f:	55                   	push   %ebp
  102890:	89 e5                	mov    %esp,%ebp
  102892:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  102895:	8b 45 08             	mov    0x8(%ebp),%eax
  102898:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  10289b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10289f:	74 2f                	je     1028d0 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  1028a1:	eb 13                	jmp    1028b6 <strlcpy+0x27>
			*dst++ = *src++;
  1028a3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028a6:	0f b6 10             	movzbl (%eax),%edx
  1028a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1028ac:	88 10                	mov    %dl,(%eax)
  1028ae:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1028b2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  1028b6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1028ba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1028be:	74 0a                	je     1028ca <strlcpy+0x3b>
  1028c0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028c3:	0f b6 00             	movzbl (%eax),%eax
  1028c6:	84 c0                	test   %al,%al
  1028c8:	75 d9                	jne    1028a3 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  1028ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1028cd:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  1028d0:	8b 55 08             	mov    0x8(%ebp),%edx
  1028d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1028d6:	89 d1                	mov    %edx,%ecx
  1028d8:	29 c1                	sub    %eax,%ecx
  1028da:	89 c8                	mov    %ecx,%eax
}
  1028dc:	c9                   	leave  
  1028dd:	c3                   	ret    

001028de <strcmp>:

int
strcmp(const char *p, const char *q)
{
  1028de:	55                   	push   %ebp
  1028df:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  1028e1:	eb 08                	jmp    1028eb <strcmp+0xd>
		p++, q++;
  1028e3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1028e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  1028eb:	8b 45 08             	mov    0x8(%ebp),%eax
  1028ee:	0f b6 00             	movzbl (%eax),%eax
  1028f1:	84 c0                	test   %al,%al
  1028f3:	74 10                	je     102905 <strcmp+0x27>
  1028f5:	8b 45 08             	mov    0x8(%ebp),%eax
  1028f8:	0f b6 10             	movzbl (%eax),%edx
  1028fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028fe:	0f b6 00             	movzbl (%eax),%eax
  102901:	38 c2                	cmp    %al,%dl
  102903:	74 de                	je     1028e3 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  102905:	8b 45 08             	mov    0x8(%ebp),%eax
  102908:	0f b6 00             	movzbl (%eax),%eax
  10290b:	0f b6 d0             	movzbl %al,%edx
  10290e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102911:	0f b6 00             	movzbl (%eax),%eax
  102914:	0f b6 c0             	movzbl %al,%eax
  102917:	89 d1                	mov    %edx,%ecx
  102919:	29 c1                	sub    %eax,%ecx
  10291b:	89 c8                	mov    %ecx,%eax
}
  10291d:	5d                   	pop    %ebp
  10291e:	c3                   	ret    

0010291f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  10291f:	55                   	push   %ebp
  102920:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  102922:	eb 0c                	jmp    102930 <strncmp+0x11>
		n--, p++, q++;
  102924:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102928:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10292c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  102930:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102934:	74 1a                	je     102950 <strncmp+0x31>
  102936:	8b 45 08             	mov    0x8(%ebp),%eax
  102939:	0f b6 00             	movzbl (%eax),%eax
  10293c:	84 c0                	test   %al,%al
  10293e:	74 10                	je     102950 <strncmp+0x31>
  102940:	8b 45 08             	mov    0x8(%ebp),%eax
  102943:	0f b6 10             	movzbl (%eax),%edx
  102946:	8b 45 0c             	mov    0xc(%ebp),%eax
  102949:	0f b6 00             	movzbl (%eax),%eax
  10294c:	38 c2                	cmp    %al,%dl
  10294e:	74 d4                	je     102924 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  102950:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102954:	75 07                	jne    10295d <strncmp+0x3e>
		return 0;
  102956:	b8 00 00 00 00       	mov    $0x0,%eax
  10295b:	eb 18                	jmp    102975 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  10295d:	8b 45 08             	mov    0x8(%ebp),%eax
  102960:	0f b6 00             	movzbl (%eax),%eax
  102963:	0f b6 d0             	movzbl %al,%edx
  102966:	8b 45 0c             	mov    0xc(%ebp),%eax
  102969:	0f b6 00             	movzbl (%eax),%eax
  10296c:	0f b6 c0             	movzbl %al,%eax
  10296f:	89 d1                	mov    %edx,%ecx
  102971:	29 c1                	sub    %eax,%ecx
  102973:	89 c8                	mov    %ecx,%eax
}
  102975:	5d                   	pop    %ebp
  102976:	c3                   	ret    

00102977 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  102977:	55                   	push   %ebp
  102978:	89 e5                	mov    %esp,%ebp
  10297a:	83 ec 04             	sub    $0x4,%esp
  10297d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102980:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  102983:	eb 1a                	jmp    10299f <strchr+0x28>
		if (*s++ == 0)
  102985:	8b 45 08             	mov    0x8(%ebp),%eax
  102988:	0f b6 00             	movzbl (%eax),%eax
  10298b:	84 c0                	test   %al,%al
  10298d:	0f 94 c0             	sete   %al
  102990:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102994:	84 c0                	test   %al,%al
  102996:	74 07                	je     10299f <strchr+0x28>
			return NULL;
  102998:	b8 00 00 00 00       	mov    $0x0,%eax
  10299d:	eb 0e                	jmp    1029ad <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  10299f:	8b 45 08             	mov    0x8(%ebp),%eax
  1029a2:	0f b6 00             	movzbl (%eax),%eax
  1029a5:	3a 45 fc             	cmp    -0x4(%ebp),%al
  1029a8:	75 db                	jne    102985 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  1029aa:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1029ad:	c9                   	leave  
  1029ae:	c3                   	ret    

001029af <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  1029af:	55                   	push   %ebp
  1029b0:	89 e5                	mov    %esp,%ebp
  1029b2:	57                   	push   %edi
  1029b3:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  1029b6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1029ba:	75 05                	jne    1029c1 <memset+0x12>
		return v;
  1029bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1029bf:	eb 5c                	jmp    102a1d <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  1029c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1029c4:	83 e0 03             	and    $0x3,%eax
  1029c7:	85 c0                	test   %eax,%eax
  1029c9:	75 41                	jne    102a0c <memset+0x5d>
  1029cb:	8b 45 10             	mov    0x10(%ebp),%eax
  1029ce:	83 e0 03             	and    $0x3,%eax
  1029d1:	85 c0                	test   %eax,%eax
  1029d3:	75 37                	jne    102a0c <memset+0x5d>
		c &= 0xFF;
  1029d5:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  1029dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029df:	89 c2                	mov    %eax,%edx
  1029e1:	c1 e2 18             	shl    $0x18,%edx
  1029e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029e7:	c1 e0 10             	shl    $0x10,%eax
  1029ea:	09 c2                	or     %eax,%edx
  1029ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029ef:	c1 e0 08             	shl    $0x8,%eax
  1029f2:	09 d0                	or     %edx,%eax
  1029f4:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  1029f7:	8b 45 10             	mov    0x10(%ebp),%eax
  1029fa:	89 c1                	mov    %eax,%ecx
  1029fc:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  1029ff:	8b 55 08             	mov    0x8(%ebp),%edx
  102a02:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a05:	89 d7                	mov    %edx,%edi
  102a07:	fc                   	cld    
  102a08:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  102a0a:	eb 0e                	jmp    102a1a <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  102a0c:	8b 55 08             	mov    0x8(%ebp),%edx
  102a0f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a12:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102a15:	89 d7                	mov    %edx,%edi
  102a17:	fc                   	cld    
  102a18:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  102a1a:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102a1d:	83 c4 10             	add    $0x10,%esp
  102a20:	5f                   	pop    %edi
  102a21:	5d                   	pop    %ebp
  102a22:	c3                   	ret    

00102a23 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  102a23:	55                   	push   %ebp
  102a24:	89 e5                	mov    %esp,%ebp
  102a26:	57                   	push   %edi
  102a27:	56                   	push   %esi
  102a28:	53                   	push   %ebx
  102a29:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  102a2c:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a2f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  102a32:	8b 45 08             	mov    0x8(%ebp),%eax
  102a35:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  102a38:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102a3b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102a3e:	73 6e                	jae    102aae <memmove+0x8b>
  102a40:	8b 45 10             	mov    0x10(%ebp),%eax
  102a43:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102a46:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102a49:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102a4c:	76 60                	jbe    102aae <memmove+0x8b>
		s += n;
  102a4e:	8b 45 10             	mov    0x10(%ebp),%eax
  102a51:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  102a54:	8b 45 10             	mov    0x10(%ebp),%eax
  102a57:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102a5a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102a5d:	83 e0 03             	and    $0x3,%eax
  102a60:	85 c0                	test   %eax,%eax
  102a62:	75 2f                	jne    102a93 <memmove+0x70>
  102a64:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a67:	83 e0 03             	and    $0x3,%eax
  102a6a:	85 c0                	test   %eax,%eax
  102a6c:	75 25                	jne    102a93 <memmove+0x70>
  102a6e:	8b 45 10             	mov    0x10(%ebp),%eax
  102a71:	83 e0 03             	and    $0x3,%eax
  102a74:	85 c0                	test   %eax,%eax
  102a76:	75 1b                	jne    102a93 <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  102a78:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a7b:	83 e8 04             	sub    $0x4,%eax
  102a7e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102a81:	83 ea 04             	sub    $0x4,%edx
  102a84:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102a87:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  102a8a:	89 c7                	mov    %eax,%edi
  102a8c:	89 d6                	mov    %edx,%esi
  102a8e:	fd                   	std    
  102a8f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102a91:	eb 18                	jmp    102aab <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  102a93:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a96:	8d 50 ff             	lea    -0x1(%eax),%edx
  102a99:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102a9c:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  102a9f:	8b 45 10             	mov    0x10(%ebp),%eax
  102aa2:	89 d7                	mov    %edx,%edi
  102aa4:	89 de                	mov    %ebx,%esi
  102aa6:	89 c1                	mov    %eax,%ecx
  102aa8:	fd                   	std    
  102aa9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  102aab:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  102aac:	eb 45                	jmp    102af3 <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102aae:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102ab1:	83 e0 03             	and    $0x3,%eax
  102ab4:	85 c0                	test   %eax,%eax
  102ab6:	75 2b                	jne    102ae3 <memmove+0xc0>
  102ab8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102abb:	83 e0 03             	and    $0x3,%eax
  102abe:	85 c0                	test   %eax,%eax
  102ac0:	75 21                	jne    102ae3 <memmove+0xc0>
  102ac2:	8b 45 10             	mov    0x10(%ebp),%eax
  102ac5:	83 e0 03             	and    $0x3,%eax
  102ac8:	85 c0                	test   %eax,%eax
  102aca:	75 17                	jne    102ae3 <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  102acc:	8b 45 10             	mov    0x10(%ebp),%eax
  102acf:	89 c1                	mov    %eax,%ecx
  102ad1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  102ad4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ad7:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102ada:	89 c7                	mov    %eax,%edi
  102adc:	89 d6                	mov    %edx,%esi
  102ade:	fc                   	cld    
  102adf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102ae1:	eb 10                	jmp    102af3 <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  102ae3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ae6:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102ae9:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102aec:	89 c7                	mov    %eax,%edi
  102aee:	89 d6                	mov    %edx,%esi
  102af0:	fc                   	cld    
  102af1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  102af3:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102af6:	83 c4 10             	add    $0x10,%esp
  102af9:	5b                   	pop    %ebx
  102afa:	5e                   	pop    %esi
  102afb:	5f                   	pop    %edi
  102afc:	5d                   	pop    %ebp
  102afd:	c3                   	ret    

00102afe <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  102afe:	55                   	push   %ebp
  102aff:	89 e5                	mov    %esp,%ebp
  102b01:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  102b04:	8b 45 10             	mov    0x10(%ebp),%eax
  102b07:	89 44 24 08          	mov    %eax,0x8(%esp)
  102b0b:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b0e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102b12:	8b 45 08             	mov    0x8(%ebp),%eax
  102b15:	89 04 24             	mov    %eax,(%esp)
  102b18:	e8 06 ff ff ff       	call   102a23 <memmove>
}
  102b1d:	c9                   	leave  
  102b1e:	c3                   	ret    

00102b1f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  102b1f:	55                   	push   %ebp
  102b20:	89 e5                	mov    %esp,%ebp
  102b22:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  102b25:	8b 45 08             	mov    0x8(%ebp),%eax
  102b28:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  102b2b:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b2e:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  102b31:	eb 32                	jmp    102b65 <memcmp+0x46>
		if (*s1 != *s2)
  102b33:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102b36:	0f b6 10             	movzbl (%eax),%edx
  102b39:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102b3c:	0f b6 00             	movzbl (%eax),%eax
  102b3f:	38 c2                	cmp    %al,%dl
  102b41:	74 1a                	je     102b5d <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  102b43:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102b46:	0f b6 00             	movzbl (%eax),%eax
  102b49:	0f b6 d0             	movzbl %al,%edx
  102b4c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102b4f:	0f b6 00             	movzbl (%eax),%eax
  102b52:	0f b6 c0             	movzbl %al,%eax
  102b55:	89 d1                	mov    %edx,%ecx
  102b57:	29 c1                	sub    %eax,%ecx
  102b59:	89 c8                	mov    %ecx,%eax
  102b5b:	eb 1c                	jmp    102b79 <memcmp+0x5a>
		s1++, s2++;
  102b5d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  102b61:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  102b65:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102b69:	0f 95 c0             	setne  %al
  102b6c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102b70:	84 c0                	test   %al,%al
  102b72:	75 bf                	jne    102b33 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  102b74:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102b79:	c9                   	leave  
  102b7a:	c3                   	ret    

00102b7b <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  102b7b:	55                   	push   %ebp
  102b7c:	89 e5                	mov    %esp,%ebp
  102b7e:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  102b81:	8b 45 10             	mov    0x10(%ebp),%eax
  102b84:	8b 55 08             	mov    0x8(%ebp),%edx
  102b87:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102b8a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  102b8d:	eb 16                	jmp    102ba5 <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  102b8f:	8b 45 08             	mov    0x8(%ebp),%eax
  102b92:	0f b6 10             	movzbl (%eax),%edx
  102b95:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b98:	38 c2                	cmp    %al,%dl
  102b9a:	75 05                	jne    102ba1 <memchr+0x26>
			return (void *) s;
  102b9c:	8b 45 08             	mov    0x8(%ebp),%eax
  102b9f:	eb 11                	jmp    102bb2 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  102ba1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102ba5:	8b 45 08             	mov    0x8(%ebp),%eax
  102ba8:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  102bab:	72 e2                	jb     102b8f <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  102bad:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102bb2:	c9                   	leave  
  102bb3:	c3                   	ret    
  102bb4:	66 90                	xchg   %ax,%ax
  102bb6:	66 90                	xchg   %ax,%ax
  102bb8:	66 90                	xchg   %ax,%ax
  102bba:	66 90                	xchg   %ax,%ax
  102bbc:	66 90                	xchg   %ax,%ax
  102bbe:	66 90                	xchg   %ax,%ax

00102bc0 <__udivdi3>:
  102bc0:	55                   	push   %ebp
  102bc1:	89 e5                	mov    %esp,%ebp
  102bc3:	57                   	push   %edi
  102bc4:	56                   	push   %esi
  102bc5:	83 ec 10             	sub    $0x10,%esp
  102bc8:	8b 45 14             	mov    0x14(%ebp),%eax
  102bcb:	8b 55 08             	mov    0x8(%ebp),%edx
  102bce:	8b 75 10             	mov    0x10(%ebp),%esi
  102bd1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  102bd4:	85 c0                	test   %eax,%eax
  102bd6:	89 55 f0             	mov    %edx,-0x10(%ebp)
  102bd9:	75 35                	jne    102c10 <__udivdi3+0x50>
  102bdb:	39 fe                	cmp    %edi,%esi
  102bdd:	77 61                	ja     102c40 <__udivdi3+0x80>
  102bdf:	85 f6                	test   %esi,%esi
  102be1:	75 0b                	jne    102bee <__udivdi3+0x2e>
  102be3:	b8 01 00 00 00       	mov    $0x1,%eax
  102be8:	31 d2                	xor    %edx,%edx
  102bea:	f7 f6                	div    %esi
  102bec:	89 c6                	mov    %eax,%esi
  102bee:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  102bf1:	31 d2                	xor    %edx,%edx
  102bf3:	89 f8                	mov    %edi,%eax
  102bf5:	f7 f6                	div    %esi
  102bf7:	89 c7                	mov    %eax,%edi
  102bf9:	89 c8                	mov    %ecx,%eax
  102bfb:	f7 f6                	div    %esi
  102bfd:	89 c1                	mov    %eax,%ecx
  102bff:	89 fa                	mov    %edi,%edx
  102c01:	89 c8                	mov    %ecx,%eax
  102c03:	83 c4 10             	add    $0x10,%esp
  102c06:	5e                   	pop    %esi
  102c07:	5f                   	pop    %edi
  102c08:	5d                   	pop    %ebp
  102c09:	c3                   	ret    
  102c0a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102c10:	39 f8                	cmp    %edi,%eax
  102c12:	77 1c                	ja     102c30 <__udivdi3+0x70>
  102c14:	0f bd d0             	bsr    %eax,%edx
  102c17:	83 f2 1f             	xor    $0x1f,%edx
  102c1a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102c1d:	75 39                	jne    102c58 <__udivdi3+0x98>
  102c1f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  102c22:	0f 86 a0 00 00 00    	jbe    102cc8 <__udivdi3+0x108>
  102c28:	39 f8                	cmp    %edi,%eax
  102c2a:	0f 82 98 00 00 00    	jb     102cc8 <__udivdi3+0x108>
  102c30:	31 ff                	xor    %edi,%edi
  102c32:	31 c9                	xor    %ecx,%ecx
  102c34:	89 c8                	mov    %ecx,%eax
  102c36:	89 fa                	mov    %edi,%edx
  102c38:	83 c4 10             	add    $0x10,%esp
  102c3b:	5e                   	pop    %esi
  102c3c:	5f                   	pop    %edi
  102c3d:	5d                   	pop    %ebp
  102c3e:	c3                   	ret    
  102c3f:	90                   	nop
  102c40:	89 d1                	mov    %edx,%ecx
  102c42:	89 fa                	mov    %edi,%edx
  102c44:	89 c8                	mov    %ecx,%eax
  102c46:	31 ff                	xor    %edi,%edi
  102c48:	f7 f6                	div    %esi
  102c4a:	89 c1                	mov    %eax,%ecx
  102c4c:	89 fa                	mov    %edi,%edx
  102c4e:	89 c8                	mov    %ecx,%eax
  102c50:	83 c4 10             	add    $0x10,%esp
  102c53:	5e                   	pop    %esi
  102c54:	5f                   	pop    %edi
  102c55:	5d                   	pop    %ebp
  102c56:	c3                   	ret    
  102c57:	90                   	nop
  102c58:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102c5c:	89 f2                	mov    %esi,%edx
  102c5e:	d3 e0                	shl    %cl,%eax
  102c60:	89 45 ec             	mov    %eax,-0x14(%ebp)
  102c63:	b8 20 00 00 00       	mov    $0x20,%eax
  102c68:	2b 45 f4             	sub    -0xc(%ebp),%eax
  102c6b:	89 c1                	mov    %eax,%ecx
  102c6d:	d3 ea                	shr    %cl,%edx
  102c6f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102c73:	0b 55 ec             	or     -0x14(%ebp),%edx
  102c76:	d3 e6                	shl    %cl,%esi
  102c78:	89 c1                	mov    %eax,%ecx
  102c7a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  102c7d:	89 fe                	mov    %edi,%esi
  102c7f:	d3 ee                	shr    %cl,%esi
  102c81:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102c85:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102c88:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102c8b:	d3 e7                	shl    %cl,%edi
  102c8d:	89 c1                	mov    %eax,%ecx
  102c8f:	d3 ea                	shr    %cl,%edx
  102c91:	09 d7                	or     %edx,%edi
  102c93:	89 f2                	mov    %esi,%edx
  102c95:	89 f8                	mov    %edi,%eax
  102c97:	f7 75 ec             	divl   -0x14(%ebp)
  102c9a:	89 d6                	mov    %edx,%esi
  102c9c:	89 c7                	mov    %eax,%edi
  102c9e:	f7 65 e8             	mull   -0x18(%ebp)
  102ca1:	39 d6                	cmp    %edx,%esi
  102ca3:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102ca6:	72 30                	jb     102cd8 <__udivdi3+0x118>
  102ca8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102cab:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102caf:	d3 e2                	shl    %cl,%edx
  102cb1:	39 c2                	cmp    %eax,%edx
  102cb3:	73 05                	jae    102cba <__udivdi3+0xfa>
  102cb5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  102cb8:	74 1e                	je     102cd8 <__udivdi3+0x118>
  102cba:	89 f9                	mov    %edi,%ecx
  102cbc:	31 ff                	xor    %edi,%edi
  102cbe:	e9 71 ff ff ff       	jmp    102c34 <__udivdi3+0x74>
  102cc3:	90                   	nop
  102cc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102cc8:	31 ff                	xor    %edi,%edi
  102cca:	b9 01 00 00 00       	mov    $0x1,%ecx
  102ccf:	e9 60 ff ff ff       	jmp    102c34 <__udivdi3+0x74>
  102cd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102cd8:	8d 4f ff             	lea    -0x1(%edi),%ecx
  102cdb:	31 ff                	xor    %edi,%edi
  102cdd:	89 c8                	mov    %ecx,%eax
  102cdf:	89 fa                	mov    %edi,%edx
  102ce1:	83 c4 10             	add    $0x10,%esp
  102ce4:	5e                   	pop    %esi
  102ce5:	5f                   	pop    %edi
  102ce6:	5d                   	pop    %ebp
  102ce7:	c3                   	ret    
  102ce8:	66 90                	xchg   %ax,%ax
  102cea:	66 90                	xchg   %ax,%ax
  102cec:	66 90                	xchg   %ax,%ax
  102cee:	66 90                	xchg   %ax,%ax

00102cf0 <__umoddi3>:
  102cf0:	55                   	push   %ebp
  102cf1:	89 e5                	mov    %esp,%ebp
  102cf3:	57                   	push   %edi
  102cf4:	56                   	push   %esi
  102cf5:	83 ec 20             	sub    $0x20,%esp
  102cf8:	8b 55 14             	mov    0x14(%ebp),%edx
  102cfb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102cfe:	8b 7d 10             	mov    0x10(%ebp),%edi
  102d01:	8b 75 0c             	mov    0xc(%ebp),%esi
  102d04:	85 d2                	test   %edx,%edx
  102d06:	89 c8                	mov    %ecx,%eax
  102d08:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  102d0b:	75 13                	jne    102d20 <__umoddi3+0x30>
  102d0d:	39 f7                	cmp    %esi,%edi
  102d0f:	76 3f                	jbe    102d50 <__umoddi3+0x60>
  102d11:	89 f2                	mov    %esi,%edx
  102d13:	f7 f7                	div    %edi
  102d15:	89 d0                	mov    %edx,%eax
  102d17:	31 d2                	xor    %edx,%edx
  102d19:	83 c4 20             	add    $0x20,%esp
  102d1c:	5e                   	pop    %esi
  102d1d:	5f                   	pop    %edi
  102d1e:	5d                   	pop    %ebp
  102d1f:	c3                   	ret    
  102d20:	39 f2                	cmp    %esi,%edx
  102d22:	77 4c                	ja     102d70 <__umoddi3+0x80>
  102d24:	0f bd ca             	bsr    %edx,%ecx
  102d27:	83 f1 1f             	xor    $0x1f,%ecx
  102d2a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  102d2d:	75 51                	jne    102d80 <__umoddi3+0x90>
  102d2f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  102d32:	0f 87 e0 00 00 00    	ja     102e18 <__umoddi3+0x128>
  102d38:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d3b:	29 f8                	sub    %edi,%eax
  102d3d:	19 d6                	sbb    %edx,%esi
  102d3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102d42:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d45:	89 f2                	mov    %esi,%edx
  102d47:	83 c4 20             	add    $0x20,%esp
  102d4a:	5e                   	pop    %esi
  102d4b:	5f                   	pop    %edi
  102d4c:	5d                   	pop    %ebp
  102d4d:	c3                   	ret    
  102d4e:	66 90                	xchg   %ax,%ax
  102d50:	85 ff                	test   %edi,%edi
  102d52:	75 0b                	jne    102d5f <__umoddi3+0x6f>
  102d54:	b8 01 00 00 00       	mov    $0x1,%eax
  102d59:	31 d2                	xor    %edx,%edx
  102d5b:	f7 f7                	div    %edi
  102d5d:	89 c7                	mov    %eax,%edi
  102d5f:	89 f0                	mov    %esi,%eax
  102d61:	31 d2                	xor    %edx,%edx
  102d63:	f7 f7                	div    %edi
  102d65:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d68:	f7 f7                	div    %edi
  102d6a:	eb a9                	jmp    102d15 <__umoddi3+0x25>
  102d6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102d70:	89 c8                	mov    %ecx,%eax
  102d72:	89 f2                	mov    %esi,%edx
  102d74:	83 c4 20             	add    $0x20,%esp
  102d77:	5e                   	pop    %esi
  102d78:	5f                   	pop    %edi
  102d79:	5d                   	pop    %ebp
  102d7a:	c3                   	ret    
  102d7b:	90                   	nop
  102d7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102d80:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102d84:	d3 e2                	shl    %cl,%edx
  102d86:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102d89:	ba 20 00 00 00       	mov    $0x20,%edx
  102d8e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  102d91:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102d94:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102d98:	89 fa                	mov    %edi,%edx
  102d9a:	d3 ea                	shr    %cl,%edx
  102d9c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102da0:	0b 55 f4             	or     -0xc(%ebp),%edx
  102da3:	d3 e7                	shl    %cl,%edi
  102da5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102da9:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102dac:	89 f2                	mov    %esi,%edx
  102dae:	89 7d e8             	mov    %edi,-0x18(%ebp)
  102db1:	89 c7                	mov    %eax,%edi
  102db3:	d3 ea                	shr    %cl,%edx
  102db5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102db9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  102dbc:	89 c2                	mov    %eax,%edx
  102dbe:	d3 e6                	shl    %cl,%esi
  102dc0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102dc4:	d3 ea                	shr    %cl,%edx
  102dc6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102dca:	09 d6                	or     %edx,%esi
  102dcc:	89 f0                	mov    %esi,%eax
  102dce:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  102dd1:	d3 e7                	shl    %cl,%edi
  102dd3:	89 f2                	mov    %esi,%edx
  102dd5:	f7 75 f4             	divl   -0xc(%ebp)
  102dd8:	89 d6                	mov    %edx,%esi
  102dda:	f7 65 e8             	mull   -0x18(%ebp)
  102ddd:	39 d6                	cmp    %edx,%esi
  102ddf:	72 2b                	jb     102e0c <__umoddi3+0x11c>
  102de1:	39 c7                	cmp    %eax,%edi
  102de3:	72 23                	jb     102e08 <__umoddi3+0x118>
  102de5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102de9:	29 c7                	sub    %eax,%edi
  102deb:	19 d6                	sbb    %edx,%esi
  102ded:	89 f0                	mov    %esi,%eax
  102def:	89 f2                	mov    %esi,%edx
  102df1:	d3 ef                	shr    %cl,%edi
  102df3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102df7:	d3 e0                	shl    %cl,%eax
  102df9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102dfd:	09 f8                	or     %edi,%eax
  102dff:	d3 ea                	shr    %cl,%edx
  102e01:	83 c4 20             	add    $0x20,%esp
  102e04:	5e                   	pop    %esi
  102e05:	5f                   	pop    %edi
  102e06:	5d                   	pop    %ebp
  102e07:	c3                   	ret    
  102e08:	39 d6                	cmp    %edx,%esi
  102e0a:	75 d9                	jne    102de5 <__umoddi3+0xf5>
  102e0c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  102e0f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  102e12:	eb d1                	jmp    102de5 <__umoddi3+0xf5>
  102e14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102e18:	39 f2                	cmp    %esi,%edx
  102e1a:	0f 82 18 ff ff ff    	jb     102d38 <__umoddi3+0x48>
  102e20:	e9 1d ff ff ff       	jmp    102d42 <__umoddi3+0x52>
