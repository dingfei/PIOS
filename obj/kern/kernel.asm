
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
  10001a:	bc 00 60 10 00       	mov    $0x106000,%esp

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
  100050:	c7 44 24 0c c0 29 10 	movl   $0x1029c0,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 d6 29 10 	movl   $0x1029d6,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 eb 29 10 00 	movl   $0x1029eb,(%esp)
  10006f:	e8 b5 02 00 00       	call   100329 <debug_panic>
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
  100084:	3d 00 50 10 00       	cmp    $0x105000,%eax
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
  1000a0:	ba 84 7f 10 00       	mov    $0x107f84,%edx
  1000a5:	b8 30 65 10 00       	mov    $0x106530,%eax
  1000aa:	89 d1                	mov    %edx,%ecx
  1000ac:	29 c1                	sub    %eax,%ecx
  1000ae:	89 c8                	mov    %ecx,%eax
  1000b0:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bb:	00 
  1000bc:	c7 04 24 30 65 10 00 	movl   $0x106530,(%esp)
  1000c3:	e8 7e 24 00 00       	call   102546 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000c8:	e8 eb 01 00 00       	call   1002b8 <cons_init>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  1000cd:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  1000d4:	00 
  1000d5:	c7 04 24 f8 29 10 00 	movl   $0x1029f8,(%esp)
  1000dc:	e8 80 22 00 00       	call   102361 <cprintf>
	debug_check();
  1000e1:	e8 fa 03 00 00       	call   1004e0 <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000e6:	e8 59 0d 00 00       	call   100e44 <cpu_init>
	trap_init();
  1000eb:	e8 33 0e 00 00       	call   100f23 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000f0:	e8 a0 06 00 00       	call   100795 <mem_init>


	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.
	user();
  1000f5:	e8 02 00 00 00       	call   1000fc <user>
}
  1000fa:	c9                   	leave  
  1000fb:	c3                   	ret    

001000fc <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1000fc:	55                   	push   %ebp
  1000fd:	89 e5                	mov    %esp,%ebp
  1000ff:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  100102:	c7 04 24 13 2a 10 00 	movl   $0x102a13,(%esp)
  100109:	e8 53 22 00 00       	call   102361 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10010e:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  100111:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  100114:	89 c2                	mov    %eax,%edx
  100116:	b8 40 65 10 00       	mov    $0x106540,%eax
  10011b:	39 c2                	cmp    %eax,%edx
  10011d:	77 24                	ja     100143 <user+0x47>
  10011f:	c7 44 24 0c 20 2a 10 	movl   $0x102a20,0xc(%esp)
  100126:	00 
  100127:	c7 44 24 08 d6 29 10 	movl   $0x1029d6,0x8(%esp)
  10012e:	00 
  10012f:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100136:	00 
  100137:	c7 04 24 47 2a 10 00 	movl   $0x102a47,(%esp)
  10013e:	e8 e6 01 00 00       	call   100329 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100143:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100146:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  100149:	89 c2                	mov    %eax,%edx
  10014b:	b8 40 75 10 00       	mov    $0x107540,%eax
  100150:	39 c2                	cmp    %eax,%edx
  100152:	72 24                	jb     100178 <user+0x7c>
  100154:	c7 44 24 0c 54 2a 10 	movl   $0x102a54,0xc(%esp)
  10015b:	00 
  10015c:	c7 44 24 08 d6 29 10 	movl   $0x1029d6,0x8(%esp)
  100163:	00 
  100164:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  10016b:	00 
  10016c:	c7 04 24 47 2a 10 00 	movl   $0x102a47,(%esp)
  100173:	e8 b1 01 00 00       	call   100329 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  100178:	e8 ac 10 00 00       	call   101229 <trap_check_user>

	done();
  10017d:	e8 00 00 00 00       	call   100182 <done>

00100182 <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  100182:	55                   	push   %ebp
  100183:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  100185:	eb fe                	jmp    100185 <done+0x3>

00100187 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100187:	55                   	push   %ebp
  100188:	89 e5                	mov    %esp,%ebp
  10018a:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10018d:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100190:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100193:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100196:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100199:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10019e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1001a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1001a4:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1001aa:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1001af:	74 24                	je     1001d5 <cpu_cur+0x4e>
  1001b1:	c7 44 24 0c 8c 2a 10 	movl   $0x102a8c,0xc(%esp)
  1001b8:	00 
  1001b9:	c7 44 24 08 a2 2a 10 	movl   $0x102aa2,0x8(%esp)
  1001c0:	00 
  1001c1:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1001c8:	00 
  1001c9:	c7 04 24 b7 2a 10 00 	movl   $0x102ab7,(%esp)
  1001d0:	e8 54 01 00 00       	call   100329 <debug_panic>
	return c;
  1001d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1001d8:	c9                   	leave  
  1001d9:	c3                   	ret    

001001da <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1001da:	55                   	push   %ebp
  1001db:	89 e5                	mov    %esp,%ebp
  1001dd:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1001e0:	e8 a2 ff ff ff       	call   100187 <cpu_cur>
  1001e5:	3d 00 50 10 00       	cmp    $0x105000,%eax
  1001ea:	0f 94 c0             	sete   %al
  1001ed:	0f b6 c0             	movzbl %al,%eax
}
  1001f0:	c9                   	leave  
  1001f1:	c3                   	ret    

001001f2 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  1001f2:	55                   	push   %ebp
  1001f3:	89 e5                	mov    %esp,%ebp
  1001f5:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
  1001f8:	eb 35                	jmp    10022f <cons_intr+0x3d>
		if (c == 0)
  1001fa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1001fe:	74 2e                	je     10022e <cons_intr+0x3c>
			continue;
		cons.buf[cons.wpos++] = c;
  100200:	a1 44 77 10 00       	mov    0x107744,%eax
  100205:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100208:	88 90 40 75 10 00    	mov    %dl,0x107540(%eax)
  10020e:	83 c0 01             	add    $0x1,%eax
  100211:	a3 44 77 10 00       	mov    %eax,0x107744
		if (cons.wpos == CONSBUFSIZE)
  100216:	a1 44 77 10 00       	mov    0x107744,%eax
  10021b:	3d 00 02 00 00       	cmp    $0x200,%eax
  100220:	75 0d                	jne    10022f <cons_intr+0x3d>
			cons.wpos = 0;
  100222:	c7 05 44 77 10 00 00 	movl   $0x0,0x107744
  100229:	00 00 00 
  10022c:	eb 01                	jmp    10022f <cons_intr+0x3d>
{
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  10022e:	90                   	nop
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
  10022f:	8b 45 08             	mov    0x8(%ebp),%eax
  100232:	ff d0                	call   *%eax
  100234:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100237:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  10023b:	75 bd                	jne    1001fa <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
  10023d:	c9                   	leave  
  10023e:	c3                   	ret    

0010023f <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  10023f:	55                   	push   %ebp
  100240:	89 e5                	mov    %esp,%ebp
  100242:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  100245:	e8 aa 17 00 00       	call   1019f4 <serial_intr>
	kbd_intr();
  10024a:	e8 00 17 00 00       	call   10194f <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  10024f:	8b 15 40 77 10 00    	mov    0x107740,%edx
  100255:	a1 44 77 10 00       	mov    0x107744,%eax
  10025a:	39 c2                	cmp    %eax,%edx
  10025c:	74 35                	je     100293 <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  10025e:	a1 40 77 10 00       	mov    0x107740,%eax
  100263:	0f b6 90 40 75 10 00 	movzbl 0x107540(%eax),%edx
  10026a:	0f b6 d2             	movzbl %dl,%edx
  10026d:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100270:	83 c0 01             	add    $0x1,%eax
  100273:	a3 40 77 10 00       	mov    %eax,0x107740
		if (cons.rpos == CONSBUFSIZE)
  100278:	a1 40 77 10 00       	mov    0x107740,%eax
  10027d:	3d 00 02 00 00       	cmp    $0x200,%eax
  100282:	75 0a                	jne    10028e <cons_getc+0x4f>
			cons.rpos = 0;
  100284:	c7 05 40 77 10 00 00 	movl   $0x0,0x107740
  10028b:	00 00 00 
		return c;
  10028e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100291:	eb 05                	jmp    100298 <cons_getc+0x59>
	}
	return 0;
  100293:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100298:	c9                   	leave  
  100299:	c3                   	ret    

0010029a <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  10029a:	55                   	push   %ebp
  10029b:	89 e5                	mov    %esp,%ebp
  10029d:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  1002a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1002a3:	89 04 24             	mov    %eax,(%esp)
  1002a6:	e8 66 17 00 00       	call   101a11 <serial_putc>
	video_putc(c);
  1002ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1002ae:	89 04 24             	mov    %eax,(%esp)
  1002b1:	e8 f8 12 00 00       	call   1015ae <video_putc>
}
  1002b6:	c9                   	leave  
  1002b7:	c3                   	ret    

001002b8 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  1002b8:	55                   	push   %ebp
  1002b9:	89 e5                	mov    %esp,%ebp
  1002bb:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1002be:	e8 17 ff ff ff       	call   1001da <cpu_onboot>
  1002c3:	85 c0                	test   %eax,%eax
  1002c5:	74 36                	je     1002fd <cons_init+0x45>
		return;

	video_init();
  1002c7:	e8 16 12 00 00       	call   1014e2 <video_init>
	kbd_init();
  1002cc:	e8 92 16 00 00       	call   101963 <kbd_init>
	serial_init();
  1002d1:	e8 a0 17 00 00       	call   101a76 <serial_init>

	if (!serial_exists)
  1002d6:	a1 80 7f 10 00       	mov    0x107f80,%eax
  1002db:	85 c0                	test   %eax,%eax
  1002dd:	75 1f                	jne    1002fe <cons_init+0x46>
		warn("Serial port does not exist!\n");
  1002df:	c7 44 24 08 c4 2a 10 	movl   $0x102ac4,0x8(%esp)
  1002e6:	00 
  1002e7:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  1002ee:	00 
  1002ef:	c7 04 24 e1 2a 10 00 	movl   $0x102ae1,(%esp)
  1002f6:	e8 ed 00 00 00       	call   1003e8 <debug_warn>
  1002fb:	eb 01                	jmp    1002fe <cons_init+0x46>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  1002fd:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  1002fe:	c9                   	leave  
  1002ff:	c3                   	ret    

00100300 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  100300:	55                   	push   %ebp
  100301:	89 e5                	mov    %esp,%ebp
  100303:	83 ec 28             	sub    $0x28,%esp
	char ch;
	while (*str)
  100306:	eb 15                	jmp    10031d <cputs+0x1d>
		cons_putc(*str++);
  100308:	8b 45 08             	mov    0x8(%ebp),%eax
  10030b:	0f b6 00             	movzbl (%eax),%eax
  10030e:	0f be c0             	movsbl %al,%eax
  100311:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100315:	89 04 24             	mov    %eax,(%esp)
  100318:	e8 7d ff ff ff       	call   10029a <cons_putc>
// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
	char ch;
	while (*str)
  10031d:	8b 45 08             	mov    0x8(%ebp),%eax
  100320:	0f b6 00             	movzbl (%eax),%eax
  100323:	84 c0                	test   %al,%al
  100325:	75 e1                	jne    100308 <cputs+0x8>
		cons_putc(*str++);
}
  100327:	c9                   	leave  
  100328:	c3                   	ret    

00100329 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100329:	55                   	push   %ebp
  10032a:	89 e5                	mov    %esp,%ebp
  10032c:	83 ec 58             	sub    $0x58,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10032f:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  100332:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  100336:	0f b7 c0             	movzwl %ax,%eax
  100339:	83 e0 03             	and    $0x3,%eax
  10033c:	85 c0                	test   %eax,%eax
  10033e:	75 15                	jne    100355 <debug_panic+0x2c>
		if (panicstr)
  100340:	a1 48 77 10 00       	mov    0x107748,%eax
  100345:	85 c0                	test   %eax,%eax
  100347:	0f 85 95 00 00 00    	jne    1003e2 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  10034d:	8b 45 10             	mov    0x10(%ebp),%eax
  100350:	a3 48 77 10 00       	mov    %eax,0x107748
	}

	// First print the requested message
	va_start(ap, fmt);
  100355:	8d 45 10             	lea    0x10(%ebp),%eax
  100358:	83 c0 04             	add    $0x4,%eax
  10035b:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  10035e:	8b 45 0c             	mov    0xc(%ebp),%eax
  100361:	89 44 24 08          	mov    %eax,0x8(%esp)
  100365:	8b 45 08             	mov    0x8(%ebp),%eax
  100368:	89 44 24 04          	mov    %eax,0x4(%esp)
  10036c:	c7 04 24 ed 2a 10 00 	movl   $0x102aed,(%esp)
  100373:	e8 e9 1f 00 00       	call   102361 <cprintf>
	vcprintf(fmt, ap);
  100378:	8b 45 10             	mov    0x10(%ebp),%eax
  10037b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10037e:	89 54 24 04          	mov    %edx,0x4(%esp)
  100382:	89 04 24             	mov    %eax,(%esp)
  100385:	e8 6e 1f 00 00       	call   1022f8 <vcprintf>
	cprintf("\n");
  10038a:	c7 04 24 05 2b 10 00 	movl   $0x102b05,(%esp)
  100391:	e8 cb 1f 00 00       	call   102361 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100396:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  100399:	8b 45 f4             	mov    -0xc(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  10039c:	8d 55 c0             	lea    -0x40(%ebp),%edx
  10039f:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003a3:	89 04 24             	mov    %eax,(%esp)
  1003a6:	e8 86 00 00 00       	call   100431 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1003ab:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1003b2:	eb 1b                	jmp    1003cf <debug_panic+0xa6>
		cprintf("  from %08x\n", eips[i]);
  1003b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1003b7:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1003bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003bf:	c7 04 24 07 2b 10 00 	movl   $0x102b07,(%esp)
  1003c6:	e8 96 1f 00 00       	call   102361 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1003cb:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1003cf:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  1003d3:	7f 0e                	jg     1003e3 <debug_panic+0xba>
  1003d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1003d8:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1003dc:	85 c0                	test   %eax,%eax
  1003de:	75 d4                	jne    1003b4 <debug_panic+0x8b>
  1003e0:	eb 01                	jmp    1003e3 <debug_panic+0xba>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  1003e2:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  1003e3:	e8 9a fd ff ff       	call   100182 <done>

001003e8 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  1003e8:	55                   	push   %ebp
  1003e9:	89 e5                	mov    %esp,%ebp
  1003eb:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  1003ee:	8d 45 10             	lea    0x10(%ebp),%eax
  1003f1:	83 c0 04             	add    $0x4,%eax
  1003f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  1003f7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1003fa:	89 44 24 08          	mov    %eax,0x8(%esp)
  1003fe:	8b 45 08             	mov    0x8(%ebp),%eax
  100401:	89 44 24 04          	mov    %eax,0x4(%esp)
  100405:	c7 04 24 14 2b 10 00 	movl   $0x102b14,(%esp)
  10040c:	e8 50 1f 00 00       	call   102361 <cprintf>
	vcprintf(fmt, ap);
  100411:	8b 45 10             	mov    0x10(%ebp),%eax
  100414:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100417:	89 54 24 04          	mov    %edx,0x4(%esp)
  10041b:	89 04 24             	mov    %eax,(%esp)
  10041e:	e8 d5 1e 00 00       	call   1022f8 <vcprintf>
	cprintf("\n");
  100423:	c7 04 24 05 2b 10 00 	movl   $0x102b05,(%esp)
  10042a:	e8 32 1f 00 00       	call   102361 <cprintf>
	va_end(ap);
}
  10042f:	c9                   	leave  
  100430:	c3                   	ret    

00100431 <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100431:	55                   	push   %ebp
  100432:	89 e5                	mov    %esp,%ebp
  100434:	83 ec 18             	sub    $0x18,%esp
	panic("debug_trace not implemented");
  100437:	c7 44 24 08 2e 2b 10 	movl   $0x102b2e,0x8(%esp)
  10043e:	00 
  10043f:	c7 44 24 04 4a 00 00 	movl   $0x4a,0x4(%esp)
  100446:	00 
  100447:	c7 04 24 4a 2b 10 00 	movl   $0x102b4a,(%esp)
  10044e:	e8 d6 fe ff ff       	call   100329 <debug_panic>

00100453 <f3>:
}


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100453:	55                   	push   %ebp
  100454:	89 e5                	mov    %esp,%ebp
  100456:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100459:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  10045c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10045f:	8b 55 0c             	mov    0xc(%ebp),%edx
  100462:	89 54 24 04          	mov    %edx,0x4(%esp)
  100466:	89 04 24             	mov    %eax,(%esp)
  100469:	e8 c3 ff ff ff       	call   100431 <debug_trace>
  10046e:	c9                   	leave  
  10046f:	c3                   	ret    

00100470 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100470:	55                   	push   %ebp
  100471:	89 e5                	mov    %esp,%ebp
  100473:	83 ec 18             	sub    $0x18,%esp
  100476:	8b 45 08             	mov    0x8(%ebp),%eax
  100479:	83 e0 02             	and    $0x2,%eax
  10047c:	85 c0                	test   %eax,%eax
  10047e:	74 14                	je     100494 <f2+0x24>
  100480:	8b 45 0c             	mov    0xc(%ebp),%eax
  100483:	89 44 24 04          	mov    %eax,0x4(%esp)
  100487:	8b 45 08             	mov    0x8(%ebp),%eax
  10048a:	89 04 24             	mov    %eax,(%esp)
  10048d:	e8 c1 ff ff ff       	call   100453 <f3>
  100492:	eb 12                	jmp    1004a6 <f2+0x36>
  100494:	8b 45 0c             	mov    0xc(%ebp),%eax
  100497:	89 44 24 04          	mov    %eax,0x4(%esp)
  10049b:	8b 45 08             	mov    0x8(%ebp),%eax
  10049e:	89 04 24             	mov    %eax,(%esp)
  1004a1:	e8 ad ff ff ff       	call   100453 <f3>
  1004a6:	c9                   	leave  
  1004a7:	c3                   	ret    

001004a8 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  1004a8:	55                   	push   %ebp
  1004a9:	89 e5                	mov    %esp,%ebp
  1004ab:	83 ec 18             	sub    $0x18,%esp
  1004ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1004b1:	83 e0 01             	and    $0x1,%eax
  1004b4:	84 c0                	test   %al,%al
  1004b6:	74 14                	je     1004cc <f1+0x24>
  1004b8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1004c2:	89 04 24             	mov    %eax,(%esp)
  1004c5:	e8 a6 ff ff ff       	call   100470 <f2>
  1004ca:	eb 12                	jmp    1004de <f1+0x36>
  1004cc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004cf:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004d3:	8b 45 08             	mov    0x8(%ebp),%eax
  1004d6:	89 04 24             	mov    %eax,(%esp)
  1004d9:	e8 92 ff ff ff       	call   100470 <f2>
  1004de:	c9                   	leave  
  1004df:	c3                   	ret    

001004e0 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  1004e0:	55                   	push   %ebp
  1004e1:	89 e5                	mov    %esp,%ebp
  1004e3:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1004e9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1004f0:	eb 29                	jmp    10051b <debug_check+0x3b>
		f1(i, eips[i]);
  1004f2:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  1004f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1004fb:	89 d0                	mov    %edx,%eax
  1004fd:	c1 e0 02             	shl    $0x2,%eax
  100500:	01 d0                	add    %edx,%eax
  100502:	c1 e0 03             	shl    $0x3,%eax
  100505:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  100508:	89 44 24 04          	mov    %eax,0x4(%esp)
  10050c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10050f:	89 04 24             	mov    %eax,(%esp)
  100512:	e8 91 ff ff ff       	call   1004a8 <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100517:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10051b:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  10051f:	7e d1                	jle    1004f2 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100521:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100528:	e9 bc 00 00 00       	jmp    1005e9 <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  10052d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100534:	e9 a2 00 00 00       	jmp    1005db <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  100539:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10053c:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  10053f:	89 d0                	mov    %edx,%eax
  100541:	c1 e0 02             	shl    $0x2,%eax
  100544:	01 d0                	add    %edx,%eax
  100546:	01 c0                	add    %eax,%eax
  100548:	01 c8                	add    %ecx,%eax
  10054a:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100551:	85 c0                	test   %eax,%eax
  100553:	0f 95 c2             	setne  %dl
  100556:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  10055a:	0f 9e c0             	setle  %al
  10055d:	31 d0                	xor    %edx,%eax
  10055f:	84 c0                	test   %al,%al
  100561:	74 24                	je     100587 <debug_check+0xa7>
  100563:	c7 44 24 0c 57 2b 10 	movl   $0x102b57,0xc(%esp)
  10056a:	00 
  10056b:	c7 44 24 08 74 2b 10 	movl   $0x102b74,0x8(%esp)
  100572:	00 
  100573:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  10057a:	00 
  10057b:	c7 04 24 4a 2b 10 00 	movl   $0x102b4a,(%esp)
  100582:	e8 a2 fd ff ff       	call   100329 <debug_panic>
			if (i >= 2)
  100587:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  10058b:	7e 4a                	jle    1005d7 <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  10058d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100590:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100593:	89 d0                	mov    %edx,%eax
  100595:	c1 e0 02             	shl    $0x2,%eax
  100598:	01 d0                	add    %edx,%eax
  10059a:	01 c0                	add    %eax,%eax
  10059c:	01 c8                	add    %ecx,%eax
  10059e:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  1005a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1005a8:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  1005af:	39 c2                	cmp    %eax,%edx
  1005b1:	74 24                	je     1005d7 <debug_check+0xf7>
  1005b3:	c7 44 24 0c 89 2b 10 	movl   $0x102b89,0xc(%esp)
  1005ba:	00 
  1005bb:	c7 44 24 08 74 2b 10 	movl   $0x102b74,0x8(%esp)
  1005c2:	00 
  1005c3:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
  1005ca:	00 
  1005cb:	c7 04 24 4a 2b 10 00 	movl   $0x102b4a,(%esp)
  1005d2:	e8 52 fd ff ff       	call   100329 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1005d7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1005db:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1005df:	0f 8e 54 ff ff ff    	jle    100539 <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1005e5:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1005e9:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  1005ed:	0f 8e 3a ff ff ff    	jle    10052d <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  1005f3:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  1005f9:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  1005ff:	39 c2                	cmp    %eax,%edx
  100601:	74 24                	je     100627 <debug_check+0x147>
  100603:	c7 44 24 0c a2 2b 10 	movl   $0x102ba2,0xc(%esp)
  10060a:	00 
  10060b:	c7 44 24 08 74 2b 10 	movl   $0x102b74,0x8(%esp)
  100612:	00 
  100613:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  10061a:	00 
  10061b:	c7 04 24 4a 2b 10 00 	movl   $0x102b4a,(%esp)
  100622:	e8 02 fd ff ff       	call   100329 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100627:	8b 55 a0             	mov    -0x60(%ebp),%edx
  10062a:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10062d:	39 c2                	cmp    %eax,%edx
  10062f:	74 24                	je     100655 <debug_check+0x175>
  100631:	c7 44 24 0c bb 2b 10 	movl   $0x102bbb,0xc(%esp)
  100638:	00 
  100639:	c7 44 24 08 74 2b 10 	movl   $0x102b74,0x8(%esp)
  100640:	00 
  100641:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  100648:	00 
  100649:	c7 04 24 4a 2b 10 00 	movl   $0x102b4a,(%esp)
  100650:	e8 d4 fc ff ff       	call   100329 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100655:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  10065b:	8b 45 a0             	mov    -0x60(%ebp),%eax
  10065e:	39 c2                	cmp    %eax,%edx
  100660:	75 24                	jne    100686 <debug_check+0x1a6>
  100662:	c7 44 24 0c d4 2b 10 	movl   $0x102bd4,0xc(%esp)
  100669:	00 
  10066a:	c7 44 24 08 74 2b 10 	movl   $0x102b74,0x8(%esp)
  100671:	00 
  100672:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  100679:	00 
  10067a:	c7 04 24 4a 2b 10 00 	movl   $0x102b4a,(%esp)
  100681:	e8 a3 fc ff ff       	call   100329 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100686:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  10068c:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  10068f:	39 c2                	cmp    %eax,%edx
  100691:	74 24                	je     1006b7 <debug_check+0x1d7>
  100693:	c7 44 24 0c ed 2b 10 	movl   $0x102bed,0xc(%esp)
  10069a:	00 
  10069b:	c7 44 24 08 74 2b 10 	movl   $0x102b74,0x8(%esp)
  1006a2:	00 
  1006a3:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
  1006aa:	00 
  1006ab:	c7 04 24 4a 2b 10 00 	movl   $0x102b4a,(%esp)
  1006b2:	e8 72 fc ff ff       	call   100329 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  1006b7:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  1006bd:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1006c0:	39 c2                	cmp    %eax,%edx
  1006c2:	74 24                	je     1006e8 <debug_check+0x208>
  1006c4:	c7 44 24 0c 06 2c 10 	movl   $0x102c06,0xc(%esp)
  1006cb:	00 
  1006cc:	c7 44 24 08 74 2b 10 	movl   $0x102b74,0x8(%esp)
  1006d3:	00 
  1006d4:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
  1006db:	00 
  1006dc:	c7 04 24 4a 2b 10 00 	movl   $0x102b4a,(%esp)
  1006e3:	e8 41 fc ff ff       	call   100329 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  1006e8:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1006ee:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1006f4:	39 c2                	cmp    %eax,%edx
  1006f6:	75 24                	jne    10071c <debug_check+0x23c>
  1006f8:	c7 44 24 0c 1f 2c 10 	movl   $0x102c1f,0xc(%esp)
  1006ff:	00 
  100700:	c7 44 24 08 74 2b 10 	movl   $0x102b74,0x8(%esp)
  100707:	00 
  100708:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  10070f:	00 
  100710:	c7 04 24 4a 2b 10 00 	movl   $0x102b4a,(%esp)
  100717:	e8 0d fc ff ff       	call   100329 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  10071c:	c7 04 24 38 2c 10 00 	movl   $0x102c38,(%esp)
  100723:	e8 39 1c 00 00       	call   102361 <cprintf>
}
  100728:	c9                   	leave  
  100729:	c3                   	ret    

0010072a <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10072a:	55                   	push   %ebp
  10072b:	89 e5                	mov    %esp,%ebp
  10072d:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100730:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100733:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100736:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100739:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10073c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100741:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100744:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100747:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  10074d:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100752:	74 24                	je     100778 <cpu_cur+0x4e>
  100754:	c7 44 24 0c 54 2c 10 	movl   $0x102c54,0xc(%esp)
  10075b:	00 
  10075c:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100763:	00 
  100764:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10076b:	00 
  10076c:	c7 04 24 7f 2c 10 00 	movl   $0x102c7f,(%esp)
  100773:	e8 b1 fb ff ff       	call   100329 <debug_panic>
	return c;
  100778:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10077b:	c9                   	leave  
  10077c:	c3                   	ret    

0010077d <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10077d:	55                   	push   %ebp
  10077e:	89 e5                	mov    %esp,%ebp
  100780:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100783:	e8 a2 ff ff ff       	call   10072a <cpu_cur>
  100788:	3d 00 50 10 00       	cmp    $0x105000,%eax
  10078d:	0f 94 c0             	sete   %al
  100790:	0f b6 c0             	movzbl %al,%eax
}
  100793:	c9                   	leave  
  100794:	c3                   	ret    

00100795 <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  100795:	55                   	push   %ebp
  100796:	89 e5                	mov    %esp,%ebp
  100798:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10079b:	e8 dd ff ff ff       	call   10077d <cpu_onboot>
  1007a0:	85 c0                	test   %eax,%eax
  1007a2:	0f 84 2d 01 00 00    	je     1008d5 <mem_init+0x140>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  1007a8:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  1007af:	e8 c7 13 00 00       	call   101b7b <nvram_read16>
  1007b4:	c1 e0 0a             	shl    $0xa,%eax
  1007b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1007ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1007bd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1007c2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  1007c5:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  1007cc:	e8 aa 13 00 00       	call   101b7b <nvram_read16>
  1007d1:	c1 e0 0a             	shl    $0xa,%eax
  1007d4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1007d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1007da:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1007df:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	warn("Assuming we have 1GB of memory!");
  1007e2:	c7 44 24 08 8c 2c 10 	movl   $0x102c8c,0x8(%esp)
  1007e9:	00 
  1007ea:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  1007f1:	00 
  1007f2:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  1007f9:	e8 ea fb ff ff       	call   1003e8 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1007fe:	c7 45 e4 00 00 f0 3f 	movl   $0x3ff00000,-0x1c(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100805:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100808:	05 00 00 10 00       	add    $0x100000,%eax
  10080d:	a3 78 7f 10 00       	mov    %eax,0x107f78

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100812:	a1 78 7f 10 00       	mov    0x107f78,%eax
  100817:	c1 e8 0c             	shr    $0xc,%eax
  10081a:	a3 74 7f 10 00       	mov    %eax,0x107f74

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  10081f:	a1 78 7f 10 00       	mov    0x107f78,%eax
  100824:	c1 e8 0a             	shr    $0xa,%eax
  100827:	89 44 24 04          	mov    %eax,0x4(%esp)
  10082b:	c7 04 24 b8 2c 10 00 	movl   $0x102cb8,(%esp)
  100832:	e8 2a 1b 00 00       	call   102361 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  100837:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10083a:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  10083d:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  10083f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100842:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100845:	89 54 24 08          	mov    %edx,0x8(%esp)
  100849:	89 44 24 04          	mov    %eax,0x4(%esp)
  10084d:	c7 04 24 d9 2c 10 00 	movl   $0x102cd9,(%esp)
  100854:	e8 08 1b 00 00       	call   102361 <cprintf>
	//     Some of it is in use, some is free.
	//     Which pages hold the kernel and the pageinfo array?
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
  100859:	c7 45 e8 70 7f 10 00 	movl   $0x107f70,-0x18(%ebp)
	int i;
	for (i = 0; i < mem_npage; i++) {
  100860:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100867:	eb 3b                	jmp    1008a4 <mem_init+0x10f>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100869:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  10086e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100871:	c1 e2 03             	shl    $0x3,%edx
  100874:	01 d0                	add    %edx,%eax
  100876:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  10087d:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100882:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100885:	c1 e2 03             	shl    $0x3,%edx
  100888:	8d 14 10             	lea    (%eax,%edx,1),%edx
  10088b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10088e:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100890:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100895:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100898:	c1 e2 03             	shl    $0x3,%edx
  10089b:	01 d0                	add    %edx,%eax
  10089d:	89 45 e8             	mov    %eax,-0x18(%ebp)
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
	int i;
	for (i = 0; i < mem_npage; i++) {
  1008a0:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1008a4:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1008a7:	a1 74 7f 10 00       	mov    0x107f74,%eax
  1008ac:	39 c2                	cmp    %eax,%edx
  1008ae:	72 b9                	jb     100869 <mem_init+0xd4>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  1008b0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1008b3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	panic("mem_init() not implemented");
  1008b9:	c7 44 24 08 f5 2c 10 	movl   $0x102cf5,0x8(%esp)
  1008c0:	00 
  1008c1:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  1008c8:	00 
  1008c9:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  1008d0:	e8 54 fa ff ff       	call   100329 <debug_panic>

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  1008d5:	c9                   	leave  
  1008d6:	c3                   	ret    

001008d7 <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  1008d7:	55                   	push   %ebp
  1008d8:	89 e5                	mov    %esp,%ebp
  1008da:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	// Fill this function in.
	panic("mem_alloc not implemented.");
  1008dd:	c7 44 24 08 10 2d 10 	movl   $0x102d10,0x8(%esp)
  1008e4:	00 
  1008e5:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  1008ec:	00 
  1008ed:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  1008f4:	e8 30 fa ff ff       	call   100329 <debug_panic>

001008f9 <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  1008f9:	55                   	push   %ebp
  1008fa:	89 e5                	mov    %esp,%ebp
  1008fc:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	panic("mem_free not implemented.");
  1008ff:	c7 44 24 08 2b 2d 10 	movl   $0x102d2b,0x8(%esp)
  100906:	00 
  100907:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  10090e:	00 
  10090f:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100916:	e8 0e fa ff ff       	call   100329 <debug_panic>

0010091b <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  10091b:	55                   	push   %ebp
  10091c:	89 e5                	mov    %esp,%ebp
  10091e:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100921:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100928:	a1 70 7f 10 00       	mov    0x107f70,%eax
  10092d:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100930:	eb 38                	jmp    10096a <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100932:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100935:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  10093a:	89 d1                	mov    %edx,%ecx
  10093c:	29 c1                	sub    %eax,%ecx
  10093e:	89 c8                	mov    %ecx,%eax
  100940:	c1 f8 03             	sar    $0x3,%eax
  100943:	c1 e0 0c             	shl    $0xc,%eax
  100946:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  10094d:	00 
  10094e:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100955:	00 
  100956:	89 04 24             	mov    %eax,(%esp)
  100959:	e8 e8 1b 00 00       	call   102546 <memset>
		freepages++;
  10095e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100962:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100965:	8b 00                	mov    (%eax),%eax
  100967:	89 45 dc             	mov    %eax,-0x24(%ebp)
  10096a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  10096e:	75 c2                	jne    100932 <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100970:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100973:	89 44 24 04          	mov    %eax,0x4(%esp)
  100977:	c7 04 24 45 2d 10 00 	movl   $0x102d45,(%esp)
  10097e:	e8 de 19 00 00       	call   102361 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100983:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100986:	a1 74 7f 10 00       	mov    0x107f74,%eax
  10098b:	39 c2                	cmp    %eax,%edx
  10098d:	72 24                	jb     1009b3 <mem_check+0x98>
  10098f:	c7 44 24 0c 5f 2d 10 	movl   $0x102d5f,0xc(%esp)
  100996:	00 
  100997:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  10099e:	00 
  10099f:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  1009a6:	00 
  1009a7:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  1009ae:	e8 76 f9 ff ff       	call   100329 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  1009b3:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  1009ba:	7f 24                	jg     1009e0 <mem_check+0xc5>
  1009bc:	c7 44 24 0c 75 2d 10 	movl   $0x102d75,0xc(%esp)
  1009c3:	00 
  1009c4:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  1009cb:	00 
  1009cc:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
  1009d3:	00 
  1009d4:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  1009db:	e8 49 f9 ff ff       	call   100329 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  1009e0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  1009e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1009ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1009ed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1009f0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  1009f3:	e8 df fe ff ff       	call   1008d7 <mem_alloc>
  1009f8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1009fb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  1009ff:	75 24                	jne    100a25 <mem_check+0x10a>
  100a01:	c7 44 24 0c 87 2d 10 	movl   $0x102d87,0xc(%esp)
  100a08:	00 
  100a09:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100a10:	00 
  100a11:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  100a18:	00 
  100a19:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100a20:	e8 04 f9 ff ff       	call   100329 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100a25:	e8 ad fe ff ff       	call   1008d7 <mem_alloc>
  100a2a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100a2d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100a31:	75 24                	jne    100a57 <mem_check+0x13c>
  100a33:	c7 44 24 0c 90 2d 10 	movl   $0x102d90,0xc(%esp)
  100a3a:	00 
  100a3b:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100a42:	00 
  100a43:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100a4a:	00 
  100a4b:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100a52:	e8 d2 f8 ff ff       	call   100329 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100a57:	e8 7b fe ff ff       	call   1008d7 <mem_alloc>
  100a5c:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100a5f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100a63:	75 24                	jne    100a89 <mem_check+0x16e>
  100a65:	c7 44 24 0c 99 2d 10 	movl   $0x102d99,0xc(%esp)
  100a6c:	00 
  100a6d:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100a74:	00 
  100a75:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  100a7c:	00 
  100a7d:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100a84:	e8 a0 f8 ff ff       	call   100329 <debug_panic>

	assert(pp0);
  100a89:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100a8d:	75 24                	jne    100ab3 <mem_check+0x198>
  100a8f:	c7 44 24 0c a2 2d 10 	movl   $0x102da2,0xc(%esp)
  100a96:	00 
  100a97:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100a9e:	00 
  100a9f:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  100aa6:	00 
  100aa7:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100aae:	e8 76 f8 ff ff       	call   100329 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100ab3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100ab7:	74 08                	je     100ac1 <mem_check+0x1a6>
  100ab9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100abc:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100abf:	75 24                	jne    100ae5 <mem_check+0x1ca>
  100ac1:	c7 44 24 0c a6 2d 10 	movl   $0x102da6,0xc(%esp)
  100ac8:	00 
  100ac9:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100ad0:	00 
  100ad1:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100ad8:	00 
  100ad9:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100ae0:	e8 44 f8 ff ff       	call   100329 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100ae5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100ae9:	74 10                	je     100afb <mem_check+0x1e0>
  100aeb:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100aee:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100af1:	74 08                	je     100afb <mem_check+0x1e0>
  100af3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100af6:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100af9:	75 24                	jne    100b1f <mem_check+0x204>
  100afb:	c7 44 24 0c b8 2d 10 	movl   $0x102db8,0xc(%esp)
  100b02:	00 
  100b03:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100b0a:	00 
  100b0b:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  100b12:	00 
  100b13:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100b1a:	e8 0a f8 ff ff       	call   100329 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100b1f:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100b22:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100b27:	89 d1                	mov    %edx,%ecx
  100b29:	29 c1                	sub    %eax,%ecx
  100b2b:	89 c8                	mov    %ecx,%eax
  100b2d:	c1 f8 03             	sar    $0x3,%eax
  100b30:	c1 e0 0c             	shl    $0xc,%eax
  100b33:	8b 15 74 7f 10 00    	mov    0x107f74,%edx
  100b39:	c1 e2 0c             	shl    $0xc,%edx
  100b3c:	39 d0                	cmp    %edx,%eax
  100b3e:	72 24                	jb     100b64 <mem_check+0x249>
  100b40:	c7 44 24 0c d8 2d 10 	movl   $0x102dd8,0xc(%esp)
  100b47:	00 
  100b48:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100b4f:	00 
  100b50:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100b57:	00 
  100b58:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100b5f:	e8 c5 f7 ff ff       	call   100329 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100b64:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100b67:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100b6c:	89 d1                	mov    %edx,%ecx
  100b6e:	29 c1                	sub    %eax,%ecx
  100b70:	89 c8                	mov    %ecx,%eax
  100b72:	c1 f8 03             	sar    $0x3,%eax
  100b75:	c1 e0 0c             	shl    $0xc,%eax
  100b78:	8b 15 74 7f 10 00    	mov    0x107f74,%edx
  100b7e:	c1 e2 0c             	shl    $0xc,%edx
  100b81:	39 d0                	cmp    %edx,%eax
  100b83:	72 24                	jb     100ba9 <mem_check+0x28e>
  100b85:	c7 44 24 0c 00 2e 10 	movl   $0x102e00,0xc(%esp)
  100b8c:	00 
  100b8d:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100b94:	00 
  100b95:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100b9c:	00 
  100b9d:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100ba4:	e8 80 f7 ff ff       	call   100329 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100ba9:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100bac:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100bb1:	89 d1                	mov    %edx,%ecx
  100bb3:	29 c1                	sub    %eax,%ecx
  100bb5:	89 c8                	mov    %ecx,%eax
  100bb7:	c1 f8 03             	sar    $0x3,%eax
  100bba:	c1 e0 0c             	shl    $0xc,%eax
  100bbd:	8b 15 74 7f 10 00    	mov    0x107f74,%edx
  100bc3:	c1 e2 0c             	shl    $0xc,%edx
  100bc6:	39 d0                	cmp    %edx,%eax
  100bc8:	72 24                	jb     100bee <mem_check+0x2d3>
  100bca:	c7 44 24 0c 28 2e 10 	movl   $0x102e28,0xc(%esp)
  100bd1:	00 
  100bd2:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100bd9:	00 
  100bda:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100be1:	00 
  100be2:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100be9:	e8 3b f7 ff ff       	call   100329 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100bee:	a1 70 7f 10 00       	mov    0x107f70,%eax
  100bf3:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100bf6:	c7 05 70 7f 10 00 00 	movl   $0x0,0x107f70
  100bfd:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100c00:	e8 d2 fc ff ff       	call   1008d7 <mem_alloc>
  100c05:	85 c0                	test   %eax,%eax
  100c07:	74 24                	je     100c2d <mem_check+0x312>
  100c09:	c7 44 24 0c 4e 2e 10 	movl   $0x102e4e,0xc(%esp)
  100c10:	00 
  100c11:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100c18:	00 
  100c19:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  100c20:	00 
  100c21:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100c28:	e8 fc f6 ff ff       	call   100329 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100c2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100c30:	89 04 24             	mov    %eax,(%esp)
  100c33:	e8 c1 fc ff ff       	call   1008f9 <mem_free>
        mem_free(pp1);
  100c38:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100c3b:	89 04 24             	mov    %eax,(%esp)
  100c3e:	e8 b6 fc ff ff       	call   1008f9 <mem_free>
        mem_free(pp2);
  100c43:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100c46:	89 04 24             	mov    %eax,(%esp)
  100c49:	e8 ab fc ff ff       	call   1008f9 <mem_free>
	pp0 = pp1 = pp2 = 0;
  100c4e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100c55:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100c58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100c5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100c5e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100c61:	e8 71 fc ff ff       	call   1008d7 <mem_alloc>
  100c66:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100c69:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100c6d:	75 24                	jne    100c93 <mem_check+0x378>
  100c6f:	c7 44 24 0c 87 2d 10 	movl   $0x102d87,0xc(%esp)
  100c76:	00 
  100c77:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100c7e:	00 
  100c7f:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  100c86:	00 
  100c87:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100c8e:	e8 96 f6 ff ff       	call   100329 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100c93:	e8 3f fc ff ff       	call   1008d7 <mem_alloc>
  100c98:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100c9b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100c9f:	75 24                	jne    100cc5 <mem_check+0x3aa>
  100ca1:	c7 44 24 0c 90 2d 10 	movl   $0x102d90,0xc(%esp)
  100ca8:	00 
  100ca9:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100cb0:	00 
  100cb1:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  100cb8:	00 
  100cb9:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100cc0:	e8 64 f6 ff ff       	call   100329 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100cc5:	e8 0d fc ff ff       	call   1008d7 <mem_alloc>
  100cca:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100ccd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100cd1:	75 24                	jne    100cf7 <mem_check+0x3dc>
  100cd3:	c7 44 24 0c 99 2d 10 	movl   $0x102d99,0xc(%esp)
  100cda:	00 
  100cdb:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100ce2:	00 
  100ce3:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  100cea:	00 
  100ceb:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100cf2:	e8 32 f6 ff ff       	call   100329 <debug_panic>
	assert(pp0);
  100cf7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100cfb:	75 24                	jne    100d21 <mem_check+0x406>
  100cfd:	c7 44 24 0c a2 2d 10 	movl   $0x102da2,0xc(%esp)
  100d04:	00 
  100d05:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100d0c:	00 
  100d0d:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
  100d14:	00 
  100d15:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100d1c:	e8 08 f6 ff ff       	call   100329 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100d21:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d25:	74 08                	je     100d2f <mem_check+0x414>
  100d27:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d2a:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d2d:	75 24                	jne    100d53 <mem_check+0x438>
  100d2f:	c7 44 24 0c a6 2d 10 	movl   $0x102da6,0xc(%esp)
  100d36:	00 
  100d37:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100d3e:	00 
  100d3f:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  100d46:	00 
  100d47:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100d4e:	e8 d6 f5 ff ff       	call   100329 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100d53:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d57:	74 10                	je     100d69 <mem_check+0x44e>
  100d59:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d5c:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100d5f:	74 08                	je     100d69 <mem_check+0x44e>
  100d61:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d64:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100d67:	75 24                	jne    100d8d <mem_check+0x472>
  100d69:	c7 44 24 0c b8 2d 10 	movl   $0x102db8,0xc(%esp)
  100d70:	00 
  100d71:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100d78:	00 
  100d79:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  100d80:	00 
  100d81:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100d88:	e8 9c f5 ff ff       	call   100329 <debug_panic>
	assert(mem_alloc() == 0);
  100d8d:	e8 45 fb ff ff       	call   1008d7 <mem_alloc>
  100d92:	85 c0                	test   %eax,%eax
  100d94:	74 24                	je     100dba <mem_check+0x49f>
  100d96:	c7 44 24 0c 4e 2e 10 	movl   $0x102e4e,0xc(%esp)
  100d9d:	00 
  100d9e:	c7 44 24 08 6a 2c 10 	movl   $0x102c6a,0x8(%esp)
  100da5:	00 
  100da6:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  100dad:	00 
  100dae:	c7 04 24 ac 2c 10 00 	movl   $0x102cac,(%esp)
  100db5:	e8 6f f5 ff ff       	call   100329 <debug_panic>

	// give free list back
	mem_freelist = fl;
  100dba:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100dbd:	a3 70 7f 10 00       	mov    %eax,0x107f70

	// free the pages we took
	mem_free(pp0);
  100dc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100dc5:	89 04 24             	mov    %eax,(%esp)
  100dc8:	e8 2c fb ff ff       	call   1008f9 <mem_free>
	mem_free(pp1);
  100dcd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100dd0:	89 04 24             	mov    %eax,(%esp)
  100dd3:	e8 21 fb ff ff       	call   1008f9 <mem_free>
	mem_free(pp2);
  100dd8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ddb:	89 04 24             	mov    %eax,(%esp)
  100dde:	e8 16 fb ff ff       	call   1008f9 <mem_free>

	cprintf("mem_check() succeeded!\n");
  100de3:	c7 04 24 5f 2e 10 00 	movl   $0x102e5f,(%esp)
  100dea:	e8 72 15 00 00       	call   102361 <cprintf>
}
  100def:	c9                   	leave  
  100df0:	c3                   	ret    

00100df1 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100df1:	55                   	push   %ebp
  100df2:	89 e5                	mov    %esp,%ebp
  100df4:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100df7:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100dfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100dfd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100e00:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100e03:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100e08:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100e0b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e0e:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100e14:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100e19:	74 24                	je     100e3f <cpu_cur+0x4e>
  100e1b:	c7 44 24 0c 77 2e 10 	movl   $0x102e77,0xc(%esp)
  100e22:	00 
  100e23:	c7 44 24 08 8d 2e 10 	movl   $0x102e8d,0x8(%esp)
  100e2a:	00 
  100e2b:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100e32:	00 
  100e33:	c7 04 24 a2 2e 10 00 	movl   $0x102ea2,(%esp)
  100e3a:	e8 ea f4 ff ff       	call   100329 <debug_panic>
	return c;
  100e3f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100e42:	c9                   	leave  
  100e43:	c3                   	ret    

00100e44 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  100e44:	55                   	push   %ebp
  100e45:	89 e5                	mov    %esp,%ebp
  100e47:	83 ec 18             	sub    $0x18,%esp
	cpu *c = cpu_cur();
  100e4a:	e8 a2 ff ff ff       	call   100df1 <cpu_cur>
  100e4f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  100e52:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100e55:	66 c7 45 ee 37 00    	movw   $0x37,-0x12(%ebp)
  100e5b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  100e5e:	0f 01 55 ee          	lgdtl  -0x12(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  100e62:	b8 23 00 00 00       	mov    $0x23,%eax
  100e67:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  100e69:	b8 23 00 00 00       	mov    $0x23,%eax
  100e6e:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  100e70:	b8 10 00 00 00       	mov    $0x10,%eax
  100e75:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  100e77:	b8 10 00 00 00       	mov    $0x10,%eax
  100e7c:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  100e7e:	b8 10 00 00 00       	mov    $0x10,%eax
  100e83:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  100e85:	ea 8c 0e 10 00 08 00 	ljmp   $0x8,$0x100e8c

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  100e8c:	b8 00 00 00 00       	mov    $0x0,%eax
  100e91:	0f 00 d0             	lldt   %ax
}
  100e94:	c9                   	leave  
  100e95:	c3                   	ret    

00100e96 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100e96:	55                   	push   %ebp
  100e97:	89 e5                	mov    %esp,%ebp
  100e99:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100e9c:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100e9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100ea2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100ea5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100ea8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100ead:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100eb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100eb3:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100eb9:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100ebe:	74 24                	je     100ee4 <cpu_cur+0x4e>
  100ec0:	c7 44 24 0c c0 2e 10 	movl   $0x102ec0,0xc(%esp)
  100ec7:	00 
  100ec8:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  100ecf:	00 
  100ed0:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100ed7:	00 
  100ed8:	c7 04 24 eb 2e 10 00 	movl   $0x102eeb,(%esp)
  100edf:	e8 45 f4 ff ff       	call   100329 <debug_panic>
	return c;
  100ee4:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100ee7:	c9                   	leave  
  100ee8:	c3                   	ret    

00100ee9 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100ee9:	55                   	push   %ebp
  100eea:	89 e5                	mov    %esp,%ebp
  100eec:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100eef:	e8 a2 ff ff ff       	call   100e96 <cpu_cur>
  100ef4:	3d 00 50 10 00       	cmp    $0x105000,%eax
  100ef9:	0f 94 c0             	sete   %al
  100efc:	0f b6 c0             	movzbl %al,%eax
}
  100eff:	c9                   	leave  
  100f00:	c3                   	ret    

00100f01 <trap_init_idt>:
};


static void
trap_init_idt(void)
{
  100f01:	55                   	push   %ebp
  100f02:	89 e5                	mov    %esp,%ebp
  100f04:	83 ec 18             	sub    $0x18,%esp
	extern segdesc gdt[];
	
	panic("trap_init() not implemented.");
  100f07:	c7 44 24 08 f8 2e 10 	movl   $0x102ef8,0x8(%esp)
  100f0e:	00 
  100f0f:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  100f16:	00 
  100f17:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  100f1e:	e8 06 f4 ff ff       	call   100329 <debug_panic>

00100f23 <trap_init>:
}

void
trap_init(void)
{
  100f23:	55                   	push   %ebp
  100f24:	89 e5                	mov    %esp,%ebp
  100f26:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  100f29:	e8 bb ff ff ff       	call   100ee9 <cpu_onboot>
  100f2e:	85 c0                	test   %eax,%eax
  100f30:	74 05                	je     100f37 <trap_init+0x14>
		trap_init_idt();
  100f32:	e8 ca ff ff ff       	call   100f01 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  100f37:	0f 01 1d 00 60 10 00 	lidtl  0x106000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  100f3e:	e8 a6 ff ff ff       	call   100ee9 <cpu_onboot>
  100f43:	85 c0                	test   %eax,%eax
  100f45:	74 05                	je     100f4c <trap_init+0x29>
		trap_check_kernel();
  100f47:	e8 62 02 00 00       	call   1011ae <trap_check_kernel>
}
  100f4c:	c9                   	leave  
  100f4d:	c3                   	ret    

00100f4e <trap_name>:

const char *trap_name(int trapno)
{
  100f4e:	55                   	push   %ebp
  100f4f:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  100f51:	8b 45 08             	mov    0x8(%ebp),%eax
  100f54:	83 f8 13             	cmp    $0x13,%eax
  100f57:	77 0c                	ja     100f65 <trap_name+0x17>
		return excnames[trapno];
  100f59:	8b 45 08             	mov    0x8(%ebp),%eax
  100f5c:	8b 04 85 c0 32 10 00 	mov    0x1032c0(,%eax,4),%eax
  100f63:	eb 05                	jmp    100f6a <trap_name+0x1c>
	return "(unknown trap)";
  100f65:	b8 21 2f 10 00       	mov    $0x102f21,%eax
}
  100f6a:	5d                   	pop    %ebp
  100f6b:	c3                   	ret    

00100f6c <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  100f6c:	55                   	push   %ebp
  100f6d:	89 e5                	mov    %esp,%ebp
  100f6f:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  100f72:	8b 45 08             	mov    0x8(%ebp),%eax
  100f75:	8b 00                	mov    (%eax),%eax
  100f77:	89 44 24 04          	mov    %eax,0x4(%esp)
  100f7b:	c7 04 24 30 2f 10 00 	movl   $0x102f30,(%esp)
  100f82:	e8 da 13 00 00       	call   102361 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  100f87:	8b 45 08             	mov    0x8(%ebp),%eax
  100f8a:	8b 40 04             	mov    0x4(%eax),%eax
  100f8d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100f91:	c7 04 24 3f 2f 10 00 	movl   $0x102f3f,(%esp)
  100f98:	e8 c4 13 00 00       	call   102361 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  100f9d:	8b 45 08             	mov    0x8(%ebp),%eax
  100fa0:	8b 40 08             	mov    0x8(%eax),%eax
  100fa3:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fa7:	c7 04 24 4e 2f 10 00 	movl   $0x102f4e,(%esp)
  100fae:	e8 ae 13 00 00       	call   102361 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  100fb3:	8b 45 08             	mov    0x8(%ebp),%eax
  100fb6:	8b 40 10             	mov    0x10(%eax),%eax
  100fb9:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fbd:	c7 04 24 5d 2f 10 00 	movl   $0x102f5d,(%esp)
  100fc4:	e8 98 13 00 00       	call   102361 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  100fc9:	8b 45 08             	mov    0x8(%ebp),%eax
  100fcc:	8b 40 14             	mov    0x14(%eax),%eax
  100fcf:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fd3:	c7 04 24 6c 2f 10 00 	movl   $0x102f6c,(%esp)
  100fda:	e8 82 13 00 00       	call   102361 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  100fdf:	8b 45 08             	mov    0x8(%ebp),%eax
  100fe2:	8b 40 18             	mov    0x18(%eax),%eax
  100fe5:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fe9:	c7 04 24 7b 2f 10 00 	movl   $0x102f7b,(%esp)
  100ff0:	e8 6c 13 00 00       	call   102361 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  100ff5:	8b 45 08             	mov    0x8(%ebp),%eax
  100ff8:	8b 40 1c             	mov    0x1c(%eax),%eax
  100ffb:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fff:	c7 04 24 8a 2f 10 00 	movl   $0x102f8a,(%esp)
  101006:	e8 56 13 00 00       	call   102361 <cprintf>
}
  10100b:	c9                   	leave  
  10100c:	c3                   	ret    

0010100d <trap_print>:

void
trap_print(trapframe *tf)
{
  10100d:	55                   	push   %ebp
  10100e:	89 e5                	mov    %esp,%ebp
  101010:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  101013:	8b 45 08             	mov    0x8(%ebp),%eax
  101016:	89 44 24 04          	mov    %eax,0x4(%esp)
  10101a:	c7 04 24 99 2f 10 00 	movl   $0x102f99,(%esp)
  101021:	e8 3b 13 00 00       	call   102361 <cprintf>
	trap_print_regs(&tf->regs);
  101026:	8b 45 08             	mov    0x8(%ebp),%eax
  101029:	89 04 24             	mov    %eax,(%esp)
  10102c:	e8 3b ff ff ff       	call   100f6c <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  101031:	8b 45 08             	mov    0x8(%ebp),%eax
  101034:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101038:	0f b7 c0             	movzwl %ax,%eax
  10103b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10103f:	c7 04 24 ab 2f 10 00 	movl   $0x102fab,(%esp)
  101046:	e8 16 13 00 00       	call   102361 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  10104b:	8b 45 08             	mov    0x8(%ebp),%eax
  10104e:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101052:	0f b7 c0             	movzwl %ax,%eax
  101055:	89 44 24 04          	mov    %eax,0x4(%esp)
  101059:	c7 04 24 be 2f 10 00 	movl   $0x102fbe,(%esp)
  101060:	e8 fc 12 00 00       	call   102361 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101065:	8b 45 08             	mov    0x8(%ebp),%eax
  101068:	8b 40 30             	mov    0x30(%eax),%eax
  10106b:	89 04 24             	mov    %eax,(%esp)
  10106e:	e8 db fe ff ff       	call   100f4e <trap_name>
  101073:	8b 55 08             	mov    0x8(%ebp),%edx
  101076:	8b 52 30             	mov    0x30(%edx),%edx
  101079:	89 44 24 08          	mov    %eax,0x8(%esp)
  10107d:	89 54 24 04          	mov    %edx,0x4(%esp)
  101081:	c7 04 24 d1 2f 10 00 	movl   $0x102fd1,(%esp)
  101088:	e8 d4 12 00 00       	call   102361 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  10108d:	8b 45 08             	mov    0x8(%ebp),%eax
  101090:	8b 40 34             	mov    0x34(%eax),%eax
  101093:	89 44 24 04          	mov    %eax,0x4(%esp)
  101097:	c7 04 24 e3 2f 10 00 	movl   $0x102fe3,(%esp)
  10109e:	e8 be 12 00 00       	call   102361 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1010a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1010a6:	8b 40 38             	mov    0x38(%eax),%eax
  1010a9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010ad:	c7 04 24 f2 2f 10 00 	movl   $0x102ff2,(%esp)
  1010b4:	e8 a8 12 00 00       	call   102361 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  1010b9:	8b 45 08             	mov    0x8(%ebp),%eax
  1010bc:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1010c0:	0f b7 c0             	movzwl %ax,%eax
  1010c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010c7:	c7 04 24 01 30 10 00 	movl   $0x103001,(%esp)
  1010ce:	e8 8e 12 00 00       	call   102361 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  1010d3:	8b 45 08             	mov    0x8(%ebp),%eax
  1010d6:	8b 40 40             	mov    0x40(%eax),%eax
  1010d9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010dd:	c7 04 24 14 30 10 00 	movl   $0x103014,(%esp)
  1010e4:	e8 78 12 00 00       	call   102361 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1010e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1010ec:	8b 40 44             	mov    0x44(%eax),%eax
  1010ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010f3:	c7 04 24 23 30 10 00 	movl   $0x103023,(%esp)
  1010fa:	e8 62 12 00 00       	call   102361 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1010ff:	8b 45 08             	mov    0x8(%ebp),%eax
  101102:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101106:	0f b7 c0             	movzwl %ax,%eax
  101109:	89 44 24 04          	mov    %eax,0x4(%esp)
  10110d:	c7 04 24 32 30 10 00 	movl   $0x103032,(%esp)
  101114:	e8 48 12 00 00       	call   102361 <cprintf>
}
  101119:	c9                   	leave  
  10111a:	c3                   	ret    

0010111b <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  10111b:	55                   	push   %ebp
  10111c:	89 e5                	mov    %esp,%ebp
  10111e:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  101121:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  101122:	e8 6f fd ff ff       	call   100e96 <cpu_cur>
  101127:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  10112a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10112d:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101133:	85 c0                	test   %eax,%eax
  101135:	74 1e                	je     101155 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  101137:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10113a:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  101140:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101143:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  101149:	89 44 24 04          	mov    %eax,0x4(%esp)
  10114d:	8b 45 08             	mov    0x8(%ebp),%eax
  101150:	89 04 24             	mov    %eax,(%esp)
  101153:	ff d2                	call   *%edx

	trap_print(tf);
  101155:	8b 45 08             	mov    0x8(%ebp),%eax
  101158:	89 04 24             	mov    %eax,(%esp)
  10115b:	e8 ad fe ff ff       	call   10100d <trap_print>
	panic("unhandled trap");
  101160:	c7 44 24 08 45 30 10 	movl   $0x103045,0x8(%esp)
  101167:	00 
  101168:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  10116f:	00 
  101170:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  101177:	e8 ad f1 ff ff       	call   100329 <debug_panic>

0010117c <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  10117c:	55                   	push   %ebp
  10117d:	89 e5                	mov    %esp,%ebp
  10117f:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101182:	8b 45 0c             	mov    0xc(%ebp),%eax
  101185:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101188:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10118b:	8b 00                	mov    (%eax),%eax
  10118d:	89 c2                	mov    %eax,%edx
  10118f:	8b 45 08             	mov    0x8(%ebp),%eax
  101192:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  101195:	8b 45 08             	mov    0x8(%ebp),%eax
  101198:	8b 40 30             	mov    0x30(%eax),%eax
  10119b:	89 c2                	mov    %eax,%edx
  10119d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011a0:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  1011a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1011a6:	89 04 24             	mov    %eax,(%esp)
  1011a9:	e8 32 03 00 00       	call   1014e0 <trap_return>

001011ae <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  1011ae:	55                   	push   %ebp
  1011af:	89 e5                	mov    %esp,%ebp
  1011b1:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1011b4:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  1011b7:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  1011bb:	0f b7 c0             	movzwl %ax,%eax
  1011be:	83 e0 03             	and    $0x3,%eax
  1011c1:	85 c0                	test   %eax,%eax
  1011c3:	74 24                	je     1011e9 <trap_check_kernel+0x3b>
  1011c5:	c7 44 24 0c 54 30 10 	movl   $0x103054,0xc(%esp)
  1011cc:	00 
  1011cd:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  1011d4:	00 
  1011d5:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
  1011dc:	00 
  1011dd:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  1011e4:	e8 40 f1 ff ff       	call   100329 <debug_panic>

	cpu *c = cpu_cur();
  1011e9:	e8 a8 fc ff ff       	call   100e96 <cpu_cur>
  1011ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  1011f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1011f4:	c7 80 a0 00 00 00 7c 	movl   $0x10117c,0xa0(%eax)
  1011fb:	11 10 00 
	trap_check(&c->recoverdata);
  1011fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101201:	05 a4 00 00 00       	add    $0xa4,%eax
  101206:	89 04 24             	mov    %eax,(%esp)
  101209:	e8 96 00 00 00       	call   1012a4 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  10120e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101211:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101218:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  10121b:	c7 04 24 6c 30 10 00 	movl   $0x10306c,(%esp)
  101222:	e8 3a 11 00 00       	call   102361 <cprintf>
}
  101227:	c9                   	leave  
  101228:	c3                   	ret    

00101229 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101229:	55                   	push   %ebp
  10122a:	89 e5                	mov    %esp,%ebp
  10122c:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10122f:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  101232:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101236:	0f b7 c0             	movzwl %ax,%eax
  101239:	83 e0 03             	and    $0x3,%eax
  10123c:	83 f8 03             	cmp    $0x3,%eax
  10123f:	74 24                	je     101265 <trap_check_user+0x3c>
  101241:	c7 44 24 0c 8c 30 10 	movl   $0x10308c,0xc(%esp)
  101248:	00 
  101249:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  101250:	00 
  101251:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  101258:	00 
  101259:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  101260:	e8 c4 f0 ff ff       	call   100329 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101265:	c7 45 f0 00 50 10 00 	movl   $0x105000,-0x10(%ebp)
	c->recover = trap_check_recover;
  10126c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10126f:	c7 80 a0 00 00 00 7c 	movl   $0x10117c,0xa0(%eax)
  101276:	11 10 00 
	trap_check(&c->recoverdata);
  101279:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10127c:	05 a4 00 00 00       	add    $0xa4,%eax
  101281:	89 04 24             	mov    %eax,(%esp)
  101284:	e8 1b 00 00 00       	call   1012a4 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101289:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10128c:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101293:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101296:	c7 04 24 a1 30 10 00 	movl   $0x1030a1,(%esp)
  10129d:	e8 bf 10 00 00       	call   102361 <cprintf>
}
  1012a2:	c9                   	leave  
  1012a3:	c3                   	ret    

001012a4 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  1012a4:	55                   	push   %ebp
  1012a5:	89 e5                	mov    %esp,%ebp
  1012a7:	57                   	push   %edi
  1012a8:	56                   	push   %esi
  1012a9:	53                   	push   %ebx
  1012aa:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  1012ad:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  1012b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1012b7:	8d 55 d8             	lea    -0x28(%ebp),%edx
  1012ba:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  1012bc:	c7 45 d8 ca 12 10 00 	movl   $0x1012ca,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1012c3:	b8 00 00 00 00       	mov    $0x0,%eax
  1012c8:	f7 f0                	div    %eax

001012ca <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1012ca:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1012cd:	85 c0                	test   %eax,%eax
  1012cf:	74 24                	je     1012f5 <after_div0+0x2b>
  1012d1:	c7 44 24 0c bf 30 10 	movl   $0x1030bf,0xc(%esp)
  1012d8:	00 
  1012d9:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  1012e0:	00 
  1012e1:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  1012e8:	00 
  1012e9:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  1012f0:	e8 34 f0 ff ff       	call   100329 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1012f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1012f8:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1012fd:	74 24                	je     101323 <after_div0+0x59>
  1012ff:	c7 44 24 0c d7 30 10 	movl   $0x1030d7,0xc(%esp)
  101306:	00 
  101307:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  10130e:	00 
  10130f:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  101316:	00 
  101317:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  10131e:	e8 06 f0 ff ff       	call   100329 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101323:	c7 45 d8 2b 13 10 00 	movl   $0x10132b,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  10132a:	cc                   	int3   

0010132b <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  10132b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10132e:	83 f8 03             	cmp    $0x3,%eax
  101331:	74 24                	je     101357 <after_breakpoint+0x2c>
  101333:	c7 44 24 0c ec 30 10 	movl   $0x1030ec,0xc(%esp)
  10133a:	00 
  10133b:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  101342:	00 
  101343:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  10134a:	00 
  10134b:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  101352:	e8 d2 ef ff ff       	call   100329 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101357:	c7 45 d8 66 13 10 00 	movl   $0x101366,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  10135e:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101363:	01 c0                	add    %eax,%eax
  101365:	ce                   	into   

00101366 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101366:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101369:	83 f8 04             	cmp    $0x4,%eax
  10136c:	74 24                	je     101392 <after_overflow+0x2c>
  10136e:	c7 44 24 0c 03 31 10 	movl   $0x103103,0xc(%esp)
  101375:	00 
  101376:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  10137d:	00 
  10137e:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  101385:	00 
  101386:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  10138d:	e8 97 ef ff ff       	call   100329 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101392:	c7 45 d8 af 13 10 00 	movl   $0x1013af,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  101399:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  1013a0:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  1013a7:	b8 00 00 00 00       	mov    $0x0,%eax
  1013ac:	62 45 d0             	bound  %eax,-0x30(%ebp)

001013af <after_bound>:
	assert(args.trapno == T_BOUND);
  1013af:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1013b2:	83 f8 05             	cmp    $0x5,%eax
  1013b5:	74 24                	je     1013db <after_bound+0x2c>
  1013b7:	c7 44 24 0c 1a 31 10 	movl   $0x10311a,0xc(%esp)
  1013be:	00 
  1013bf:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  1013c6:	00 
  1013c7:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  1013ce:	00 
  1013cf:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  1013d6:	e8 4e ef ff ff       	call   100329 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  1013db:	c7 45 d8 e4 13 10 00 	movl   $0x1013e4,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  1013e2:	0f 0b                	ud2    

001013e4 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  1013e4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1013e7:	83 f8 06             	cmp    $0x6,%eax
  1013ea:	74 24                	je     101410 <after_illegal+0x2c>
  1013ec:	c7 44 24 0c 31 31 10 	movl   $0x103131,0xc(%esp)
  1013f3:	00 
  1013f4:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  1013fb:	00 
  1013fc:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  101403:	00 
  101404:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  10140b:	e8 19 ef ff ff       	call   100329 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101410:	c7 45 d8 1e 14 10 00 	movl   $0x10141e,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101417:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10141c:	8e e0                	mov    %eax,%fs

0010141e <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  10141e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101421:	83 f8 0d             	cmp    $0xd,%eax
  101424:	74 24                	je     10144a <after_gpfault+0x2c>
  101426:	c7 44 24 0c 48 31 10 	movl   $0x103148,0xc(%esp)
  10142d:	00 
  10142e:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  101435:	00 
  101436:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  10143d:	00 
  10143e:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  101445:	e8 df ee ff ff       	call   100329 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10144a:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  10144d:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101451:	0f b7 c0             	movzwl %ax,%eax
  101454:	83 e0 03             	and    $0x3,%eax
  101457:	85 c0                	test   %eax,%eax
  101459:	74 3a                	je     101495 <after_priv+0x2c>
		args.reip = after_priv;
  10145b:	c7 45 d8 69 14 10 00 	movl   $0x101469,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101462:	0f 01 1d 00 60 10 00 	lidtl  0x106000

00101469 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101469:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10146c:	83 f8 0d             	cmp    $0xd,%eax
  10146f:	74 24                	je     101495 <after_priv+0x2c>
  101471:	c7 44 24 0c 48 31 10 	movl   $0x103148,0xc(%esp)
  101478:	00 
  101479:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  101480:	00 
  101481:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  101488:	00 
  101489:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  101490:	e8 94 ee ff ff       	call   100329 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101495:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101498:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  10149d:	74 24                	je     1014c3 <after_priv+0x5a>
  10149f:	c7 44 24 0c d7 30 10 	movl   $0x1030d7,0xc(%esp)
  1014a6:	00 
  1014a7:	c7 44 24 08 d6 2e 10 	movl   $0x102ed6,0x8(%esp)
  1014ae:	00 
  1014af:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
  1014b6:	00 
  1014b7:	c7 04 24 15 2f 10 00 	movl   $0x102f15,(%esp)
  1014be:	e8 66 ee ff ff       	call   100329 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  1014c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1014c6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1014cc:	83 c4 3c             	add    $0x3c,%esp
  1014cf:	5b                   	pop    %ebx
  1014d0:	5e                   	pop    %esi
  1014d1:	5f                   	pop    %edi
  1014d2:	5d                   	pop    %ebp
  1014d3:	c3                   	ret    
  1014d4:	66 90                	xchg   %ax,%ax
  1014d6:	66 90                	xchg   %ax,%ax
  1014d8:	66 90                	xchg   %ax,%ax
  1014da:	66 90                	xchg   %ax,%ax
  1014dc:	66 90                	xchg   %ax,%ax
  1014de:	66 90                	xchg   %ax,%ax

001014e0 <trap_return>:
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return:
/*
 * Lab 1: Your code here for trap_return
 */
1:	jmp	1b		// just spin
  1014e0:	eb fe                	jmp    1014e0 <trap_return>

001014e2 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  1014e2:	55                   	push   %ebp
  1014e3:	89 e5                	mov    %esp,%ebp
  1014e5:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  1014e8:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  1014ef:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1014f2:	0f b7 00             	movzwl (%eax),%eax
  1014f5:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  1014f9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1014fc:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  101501:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101504:	0f b7 00             	movzwl (%eax),%eax
  101507:	66 3d 5a a5          	cmp    $0xa55a,%ax
  10150b:	74 13                	je     101520 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  10150d:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  101514:	c7 05 60 7f 10 00 b4 	movl   $0x3b4,0x107f60
  10151b:	03 00 00 
  10151e:	eb 14                	jmp    101534 <video_init+0x52>
	} else {
		*cp = was;
  101520:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101523:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  101527:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  10152a:	c7 05 60 7f 10 00 d4 	movl   $0x3d4,0x107f60
  101531:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  101534:	a1 60 7f 10 00       	mov    0x107f60,%eax
  101539:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10153c:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101540:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  101544:	8b 55 e8             	mov    -0x18(%ebp),%edx
  101547:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  101548:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10154d:	83 c0 01             	add    $0x1,%eax
  101550:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101553:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101556:	89 c2                	mov    %eax,%edx
  101558:	ec                   	in     (%dx),%al
  101559:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10155c:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  101560:	0f b6 c0             	movzbl %al,%eax
  101563:	c1 e0 08             	shl    $0x8,%eax
  101566:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  101569:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10156e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101571:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101575:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101579:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10157c:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  10157d:	a1 60 7f 10 00       	mov    0x107f60,%eax
  101582:	83 c0 01             	add    $0x1,%eax
  101585:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101588:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10158b:	89 c2                	mov    %eax,%edx
  10158d:	ec                   	in     (%dx),%al
  10158e:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101591:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  101595:	0f b6 c0             	movzbl %al,%eax
  101598:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  10159b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10159e:	a3 64 7f 10 00       	mov    %eax,0x107f64
	crt_pos = pos;
  1015a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1015a6:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
}
  1015ac:	c9                   	leave  
  1015ad:	c3                   	ret    

001015ae <video_putc>:



void
video_putc(int c)
{
  1015ae:	55                   	push   %ebp
  1015af:	89 e5                	mov    %esp,%ebp
  1015b1:	53                   	push   %ebx
  1015b2:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  1015b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1015b8:	b0 00                	mov    $0x0,%al
  1015ba:	85 c0                	test   %eax,%eax
  1015bc:	75 07                	jne    1015c5 <video_putc+0x17>
		c |= 0x0700;
  1015be:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  1015c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1015c8:	25 ff 00 00 00       	and    $0xff,%eax
  1015cd:	83 f8 09             	cmp    $0x9,%eax
  1015d0:	0f 84 ae 00 00 00    	je     101684 <video_putc+0xd6>
  1015d6:	83 f8 09             	cmp    $0x9,%eax
  1015d9:	7f 0a                	jg     1015e5 <video_putc+0x37>
  1015db:	83 f8 08             	cmp    $0x8,%eax
  1015de:	74 14                	je     1015f4 <video_putc+0x46>
  1015e0:	e9 dd 00 00 00       	jmp    1016c2 <video_putc+0x114>
  1015e5:	83 f8 0a             	cmp    $0xa,%eax
  1015e8:	74 4e                	je     101638 <video_putc+0x8a>
  1015ea:	83 f8 0d             	cmp    $0xd,%eax
  1015ed:	74 59                	je     101648 <video_putc+0x9a>
  1015ef:	e9 ce 00 00 00       	jmp    1016c2 <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  1015f4:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1015fb:	66 85 c0             	test   %ax,%ax
  1015fe:	0f 84 e4 00 00 00    	je     1016e8 <video_putc+0x13a>
			crt_pos--;
  101604:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10160b:	83 e8 01             	sub    $0x1,%eax
  10160e:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  101614:	a1 64 7f 10 00       	mov    0x107f64,%eax
  101619:	0f b7 15 68 7f 10 00 	movzwl 0x107f68,%edx
  101620:	0f b7 d2             	movzwl %dx,%edx
  101623:	01 d2                	add    %edx,%edx
  101625:	8d 14 10             	lea    (%eax,%edx,1),%edx
  101628:	8b 45 08             	mov    0x8(%ebp),%eax
  10162b:	b0 00                	mov    $0x0,%al
  10162d:	83 c8 20             	or     $0x20,%eax
  101630:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  101633:	e9 b1 00 00 00       	jmp    1016e9 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  101638:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10163f:	83 c0 50             	add    $0x50,%eax
  101642:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  101648:	0f b7 1d 68 7f 10 00 	movzwl 0x107f68,%ebx
  10164f:	0f b7 0d 68 7f 10 00 	movzwl 0x107f68,%ecx
  101656:	0f b7 c1             	movzwl %cx,%eax
  101659:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  10165f:	c1 e8 10             	shr    $0x10,%eax
  101662:	89 c2                	mov    %eax,%edx
  101664:	66 c1 ea 06          	shr    $0x6,%dx
  101668:	89 d0                	mov    %edx,%eax
  10166a:	c1 e0 02             	shl    $0x2,%eax
  10166d:	01 d0                	add    %edx,%eax
  10166f:	c1 e0 04             	shl    $0x4,%eax
  101672:	89 ca                	mov    %ecx,%edx
  101674:	66 29 c2             	sub    %ax,%dx
  101677:	89 d8                	mov    %ebx,%eax
  101679:	66 29 d0             	sub    %dx,%ax
  10167c:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		break;
  101682:	eb 65                	jmp    1016e9 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  101684:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10168b:	e8 1e ff ff ff       	call   1015ae <video_putc>
		video_putc(' ');
  101690:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101697:	e8 12 ff ff ff       	call   1015ae <video_putc>
		video_putc(' ');
  10169c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1016a3:	e8 06 ff ff ff       	call   1015ae <video_putc>
		video_putc(' ');
  1016a8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1016af:	e8 fa fe ff ff       	call   1015ae <video_putc>
		video_putc(' ');
  1016b4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1016bb:	e8 ee fe ff ff       	call   1015ae <video_putc>
		break;
  1016c0:	eb 27                	jmp    1016e9 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  1016c2:	8b 15 64 7f 10 00    	mov    0x107f64,%edx
  1016c8:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1016cf:	0f b7 c8             	movzwl %ax,%ecx
  1016d2:	01 c9                	add    %ecx,%ecx
  1016d4:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  1016d7:	8b 55 08             	mov    0x8(%ebp),%edx
  1016da:	66 89 11             	mov    %dx,(%ecx)
  1016dd:	83 c0 01             	add    $0x1,%eax
  1016e0:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
  1016e6:	eb 01                	jmp    1016e9 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  1016e8:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  1016e9:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1016f0:	66 3d cf 07          	cmp    $0x7cf,%ax
  1016f4:	76 5b                	jbe    101751 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  1016f6:	a1 64 7f 10 00       	mov    0x107f64,%eax
  1016fb:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  101701:	a1 64 7f 10 00       	mov    0x107f64,%eax
  101706:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  10170d:	00 
  10170e:	89 54 24 04          	mov    %edx,0x4(%esp)
  101712:	89 04 24             	mov    %eax,(%esp)
  101715:	e8 a0 0e 00 00       	call   1025ba <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  10171a:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  101721:	eb 15                	jmp    101738 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  101723:	a1 64 7f 10 00       	mov    0x107f64,%eax
  101728:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10172b:	01 d2                	add    %edx,%edx
  10172d:	01 d0                	add    %edx,%eax
  10172f:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101734:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  101738:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  10173f:	7e e2                	jle    101723 <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  101741:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  101748:	83 e8 50             	sub    $0x50,%eax
  10174b:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  101751:	a1 60 7f 10 00       	mov    0x107f60,%eax
  101756:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101759:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10175d:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101761:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101764:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101765:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10176c:	66 c1 e8 08          	shr    $0x8,%ax
  101770:	0f b6 c0             	movzbl %al,%eax
  101773:	8b 15 60 7f 10 00    	mov    0x107f60,%edx
  101779:	83 c2 01             	add    $0x1,%edx
  10177c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10177f:	88 45 e3             	mov    %al,-0x1d(%ebp)
  101782:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101786:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101789:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  10178a:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10178f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101792:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  101796:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  10179a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10179d:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  10179e:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1017a5:	0f b6 c0             	movzbl %al,%eax
  1017a8:	8b 15 60 7f 10 00    	mov    0x107f60,%edx
  1017ae:	83 c2 01             	add    $0x1,%edx
  1017b1:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1017b4:	88 45 f3             	mov    %al,-0xd(%ebp)
  1017b7:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1017bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1017be:	ee                   	out    %al,(%dx)
}
  1017bf:	83 c4 44             	add    $0x44,%esp
  1017c2:	5b                   	pop    %ebx
  1017c3:	5d                   	pop    %ebp
  1017c4:	c3                   	ret    

001017c5 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  1017c5:	55                   	push   %ebp
  1017c6:	89 e5                	mov    %esp,%ebp
  1017c8:	83 ec 38             	sub    $0x38,%esp
  1017cb:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1017d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1017d5:	89 c2                	mov    %eax,%edx
  1017d7:	ec                   	in     (%dx),%al
  1017d8:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  1017db:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  1017df:	0f b6 c0             	movzbl %al,%eax
  1017e2:	83 e0 01             	and    $0x1,%eax
  1017e5:	85 c0                	test   %eax,%eax
  1017e7:	75 0a                	jne    1017f3 <kbd_proc_data+0x2e>
		return -1;
  1017e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1017ee:	e9 5a 01 00 00       	jmp    10194d <kbd_proc_data+0x188>
  1017f3:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1017fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1017fd:	89 c2                	mov    %eax,%edx
  1017ff:	ec                   	in     (%dx),%al
  101800:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  101803:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  101807:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  10180a:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  10180e:	75 17                	jne    101827 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  101810:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101815:	83 c8 40             	or     $0x40,%eax
  101818:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
		return 0;
  10181d:	b8 00 00 00 00       	mov    $0x0,%eax
  101822:	e9 26 01 00 00       	jmp    10194d <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  101827:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10182b:	84 c0                	test   %al,%al
  10182d:	79 47                	jns    101876 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  10182f:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101834:	83 e0 40             	and    $0x40,%eax
  101837:	85 c0                	test   %eax,%eax
  101839:	75 09                	jne    101844 <kbd_proc_data+0x7f>
  10183b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10183f:	83 e0 7f             	and    $0x7f,%eax
  101842:	eb 04                	jmp    101848 <kbd_proc_data+0x83>
  101844:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101848:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  10184b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10184f:	0f b6 80 20 60 10 00 	movzbl 0x106020(%eax),%eax
  101856:	83 c8 40             	or     $0x40,%eax
  101859:	0f b6 c0             	movzbl %al,%eax
  10185c:	f7 d0                	not    %eax
  10185e:	89 c2                	mov    %eax,%edx
  101860:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101865:	21 d0                	and    %edx,%eax
  101867:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
		return 0;
  10186c:	b8 00 00 00 00       	mov    $0x0,%eax
  101871:	e9 d7 00 00 00       	jmp    10194d <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  101876:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  10187b:	83 e0 40             	and    $0x40,%eax
  10187e:	85 c0                	test   %eax,%eax
  101880:	74 11                	je     101893 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  101882:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  101886:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  10188b:	83 e0 bf             	and    $0xffffffbf,%eax
  10188e:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
	}

	shift |= shiftcode[data];
  101893:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101897:	0f b6 80 20 60 10 00 	movzbl 0x106020(%eax),%eax
  10189e:	0f b6 d0             	movzbl %al,%edx
  1018a1:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018a6:	09 d0                	or     %edx,%eax
  1018a8:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
	shift ^= togglecode[data];
  1018ad:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1018b1:	0f b6 80 20 61 10 00 	movzbl 0x106120(%eax),%eax
  1018b8:	0f b6 d0             	movzbl %al,%edx
  1018bb:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018c0:	31 d0                	xor    %edx,%eax
  1018c2:	a3 6c 7f 10 00       	mov    %eax,0x107f6c

	c = charcode[shift & (CTL | SHIFT)][data];
  1018c7:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018cc:	83 e0 03             	and    $0x3,%eax
  1018cf:	8b 14 85 20 65 10 00 	mov    0x106520(,%eax,4),%edx
  1018d6:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1018da:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1018dd:	0f b6 00             	movzbl (%eax),%eax
  1018e0:	0f b6 c0             	movzbl %al,%eax
  1018e3:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  1018e6:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018eb:	83 e0 08             	and    $0x8,%eax
  1018ee:	85 c0                	test   %eax,%eax
  1018f0:	74 22                	je     101914 <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  1018f2:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  1018f6:	7e 0c                	jle    101904 <kbd_proc_data+0x13f>
  1018f8:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  1018fc:	7f 06                	jg     101904 <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  1018fe:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  101902:	eb 10                	jmp    101914 <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  101904:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  101908:	7e 0a                	jle    101914 <kbd_proc_data+0x14f>
  10190a:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  10190e:	7f 04                	jg     101914 <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  101910:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  101914:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101919:	f7 d0                	not    %eax
  10191b:	83 e0 06             	and    $0x6,%eax
  10191e:	85 c0                	test   %eax,%eax
  101920:	75 28                	jne    10194a <kbd_proc_data+0x185>
  101922:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  101929:	75 1f                	jne    10194a <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  10192b:	c7 04 24 10 33 10 00 	movl   $0x103310,(%esp)
  101932:	e8 2a 0a 00 00       	call   102361 <cprintf>
  101937:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  10193e:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101942:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101946:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101949:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  10194a:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  10194d:	c9                   	leave  
  10194e:	c3                   	ret    

0010194f <kbd_intr>:

void
kbd_intr(void)
{
  10194f:	55                   	push   %ebp
  101950:	89 e5                	mov    %esp,%ebp
  101952:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  101955:	c7 04 24 c5 17 10 00 	movl   $0x1017c5,(%esp)
  10195c:	e8 91 e8 ff ff       	call   1001f2 <cons_intr>
}
  101961:	c9                   	leave  
  101962:	c3                   	ret    

00101963 <kbd_init>:

void
kbd_init(void)
{
  101963:	55                   	push   %ebp
  101964:	89 e5                	mov    %esp,%ebp
}
  101966:	5d                   	pop    %ebp
  101967:	c3                   	ret    

00101968 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  101968:	55                   	push   %ebp
  101969:	89 e5                	mov    %esp,%ebp
  10196b:	83 ec 20             	sub    $0x20,%esp
  10196e:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101975:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101978:	89 c2                	mov    %eax,%edx
  10197a:	ec                   	in     (%dx),%al
  10197b:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  10197e:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101985:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101988:	89 c2                	mov    %eax,%edx
  10198a:	ec                   	in     (%dx),%al
  10198b:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  10198e:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101995:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101998:	89 c2                	mov    %eax,%edx
  10199a:	ec                   	in     (%dx),%al
  10199b:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  10199e:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1019a5:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1019a8:	89 c2                	mov    %eax,%edx
  1019aa:	ec                   	in     (%dx),%al
  1019ab:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  1019ae:	c9                   	leave  
  1019af:	c3                   	ret    

001019b0 <serial_proc_data>:

static int
serial_proc_data(void)
{
  1019b0:	55                   	push   %ebp
  1019b1:	89 e5                	mov    %esp,%ebp
  1019b3:	83 ec 10             	sub    $0x10,%esp
  1019b6:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  1019bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1019c0:	89 c2                	mov    %eax,%edx
  1019c2:	ec                   	in     (%dx),%al
  1019c3:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  1019c6:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  1019ca:	0f b6 c0             	movzbl %al,%eax
  1019cd:	83 e0 01             	and    $0x1,%eax
  1019d0:	85 c0                	test   %eax,%eax
  1019d2:	75 07                	jne    1019db <serial_proc_data+0x2b>
		return -1;
  1019d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1019d9:	eb 17                	jmp    1019f2 <serial_proc_data+0x42>
  1019db:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1019e2:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1019e5:	89 c2                	mov    %eax,%edx
  1019e7:	ec                   	in     (%dx),%al
  1019e8:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  1019eb:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  1019ef:	0f b6 c0             	movzbl %al,%eax
}
  1019f2:	c9                   	leave  
  1019f3:	c3                   	ret    

001019f4 <serial_intr>:

void
serial_intr(void)
{
  1019f4:	55                   	push   %ebp
  1019f5:	89 e5                	mov    %esp,%ebp
  1019f7:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  1019fa:	a1 80 7f 10 00       	mov    0x107f80,%eax
  1019ff:	85 c0                	test   %eax,%eax
  101a01:	74 0c                	je     101a0f <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  101a03:	c7 04 24 b0 19 10 00 	movl   $0x1019b0,(%esp)
  101a0a:	e8 e3 e7 ff ff       	call   1001f2 <cons_intr>
}
  101a0f:	c9                   	leave  
  101a10:	c3                   	ret    

00101a11 <serial_putc>:

void
serial_putc(int c)
{
  101a11:	55                   	push   %ebp
  101a12:	89 e5                	mov    %esp,%ebp
  101a14:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  101a17:	a1 80 7f 10 00       	mov    0x107f80,%eax
  101a1c:	85 c0                	test   %eax,%eax
  101a1e:	74 53                	je     101a73 <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  101a20:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  101a27:	eb 09                	jmp    101a32 <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  101a29:	e8 3a ff ff ff       	call   101968 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  101a2e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  101a32:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a39:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101a3c:	89 c2                	mov    %eax,%edx
  101a3e:	ec                   	in     (%dx),%al
  101a3f:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  101a42:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101a46:	0f b6 c0             	movzbl %al,%eax
  101a49:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  101a4c:	85 c0                	test   %eax,%eax
  101a4e:	75 09                	jne    101a59 <serial_putc+0x48>
  101a50:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  101a57:	7e d0                	jle    101a29 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  101a59:	8b 45 08             	mov    0x8(%ebp),%eax
  101a5c:	0f b6 c0             	movzbl %al,%eax
  101a5f:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  101a66:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101a69:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101a6d:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101a70:	ee                   	out    %al,(%dx)
  101a71:	eb 01                	jmp    101a74 <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  101a73:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  101a74:	c9                   	leave  
  101a75:	c3                   	ret    

00101a76 <serial_init>:

void
serial_init(void)
{
  101a76:	55                   	push   %ebp
  101a77:	89 e5                	mov    %esp,%ebp
  101a79:	83 ec 50             	sub    $0x50,%esp
  101a7c:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  101a83:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  101a87:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  101a8b:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  101a8e:	ee                   	out    %al,(%dx)
  101a8f:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  101a96:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  101a9a:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  101a9e:	8b 55 bc             	mov    -0x44(%ebp),%edx
  101aa1:	ee                   	out    %al,(%dx)
  101aa2:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  101aa9:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  101aad:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  101ab1:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  101ab4:	ee                   	out    %al,(%dx)
  101ab5:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  101abc:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  101ac0:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  101ac4:	8b 55 cc             	mov    -0x34(%ebp),%edx
  101ac7:	ee                   	out    %al,(%dx)
  101ac8:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  101acf:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  101ad3:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  101ad7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101ada:	ee                   	out    %al,(%dx)
  101adb:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  101ae2:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  101ae6:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101aea:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101aed:	ee                   	out    %al,(%dx)
  101aee:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  101af5:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  101af9:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101afd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101b00:	ee                   	out    %al,(%dx)
  101b01:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101b08:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101b0b:	89 c2                	mov    %eax,%edx
  101b0d:	ec                   	in     (%dx),%al
  101b0e:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101b11:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  101b15:	3c ff                	cmp    $0xff,%al
  101b17:	0f 95 c0             	setne  %al
  101b1a:	0f b6 c0             	movzbl %al,%eax
  101b1d:	a3 80 7f 10 00       	mov    %eax,0x107f80
  101b22:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101b29:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101b2c:	89 c2                	mov    %eax,%edx
  101b2e:	ec                   	in     (%dx),%al
  101b2f:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101b32:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101b39:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101b3c:	89 c2                	mov    %eax,%edx
  101b3e:	ec                   	in     (%dx),%al
  101b3f:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  101b42:	c9                   	leave  
  101b43:	c3                   	ret    

00101b44 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  101b44:	55                   	push   %ebp
  101b45:	89 e5                	mov    %esp,%ebp
  101b47:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101b4a:	8b 45 08             	mov    0x8(%ebp),%eax
  101b4d:	0f b6 c0             	movzbl %al,%eax
  101b50:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101b57:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101b5a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101b5e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101b61:	ee                   	out    %al,(%dx)
  101b62:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101b69:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101b6c:	89 c2                	mov    %eax,%edx
  101b6e:	ec                   	in     (%dx),%al
  101b6f:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101b72:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  101b76:	0f b6 c0             	movzbl %al,%eax
}
  101b79:	c9                   	leave  
  101b7a:	c3                   	ret    

00101b7b <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  101b7b:	55                   	push   %ebp
  101b7c:	89 e5                	mov    %esp,%ebp
  101b7e:	53                   	push   %ebx
  101b7f:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  101b82:	8b 45 08             	mov    0x8(%ebp),%eax
  101b85:	89 04 24             	mov    %eax,(%esp)
  101b88:	e8 b7 ff ff ff       	call   101b44 <nvram_read>
  101b8d:	89 c3                	mov    %eax,%ebx
  101b8f:	8b 45 08             	mov    0x8(%ebp),%eax
  101b92:	83 c0 01             	add    $0x1,%eax
  101b95:	89 04 24             	mov    %eax,(%esp)
  101b98:	e8 a7 ff ff ff       	call   101b44 <nvram_read>
  101b9d:	c1 e0 08             	shl    $0x8,%eax
  101ba0:	09 d8                	or     %ebx,%eax
}
  101ba2:	83 c4 04             	add    $0x4,%esp
  101ba5:	5b                   	pop    %ebx
  101ba6:	5d                   	pop    %ebp
  101ba7:	c3                   	ret    

00101ba8 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  101ba8:	55                   	push   %ebp
  101ba9:	89 e5                	mov    %esp,%ebp
  101bab:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101bae:	8b 45 08             	mov    0x8(%ebp),%eax
  101bb1:	0f b6 c0             	movzbl %al,%eax
  101bb4:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101bbb:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101bbe:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101bc2:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101bc5:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  101bc6:	8b 45 0c             	mov    0xc(%ebp),%eax
  101bc9:	0f b6 c0             	movzbl %al,%eax
  101bcc:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  101bd3:	88 45 fb             	mov    %al,-0x5(%ebp)
  101bd6:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101bda:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101bdd:	ee                   	out    %al,(%dx)
}
  101bde:	c9                   	leave  
  101bdf:	c3                   	ret    

00101be0 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  101be0:	55                   	push   %ebp
  101be1:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  101be3:	8b 45 08             	mov    0x8(%ebp),%eax
  101be6:	8b 40 18             	mov    0x18(%eax),%eax
  101be9:	83 e0 02             	and    $0x2,%eax
  101bec:	85 c0                	test   %eax,%eax
  101bee:	74 1c                	je     101c0c <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  101bf0:	8b 45 0c             	mov    0xc(%ebp),%eax
  101bf3:	8b 00                	mov    (%eax),%eax
  101bf5:	8d 50 08             	lea    0x8(%eax),%edx
  101bf8:	8b 45 0c             	mov    0xc(%ebp),%eax
  101bfb:	89 10                	mov    %edx,(%eax)
  101bfd:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c00:	8b 00                	mov    (%eax),%eax
  101c02:	83 e8 08             	sub    $0x8,%eax
  101c05:	8b 50 04             	mov    0x4(%eax),%edx
  101c08:	8b 00                	mov    (%eax),%eax
  101c0a:	eb 47                	jmp    101c53 <getuint+0x73>
	else if (st->flags & F_L)
  101c0c:	8b 45 08             	mov    0x8(%ebp),%eax
  101c0f:	8b 40 18             	mov    0x18(%eax),%eax
  101c12:	83 e0 01             	and    $0x1,%eax
  101c15:	84 c0                	test   %al,%al
  101c17:	74 1e                	je     101c37 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  101c19:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c1c:	8b 00                	mov    (%eax),%eax
  101c1e:	8d 50 04             	lea    0x4(%eax),%edx
  101c21:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c24:	89 10                	mov    %edx,(%eax)
  101c26:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c29:	8b 00                	mov    (%eax),%eax
  101c2b:	83 e8 04             	sub    $0x4,%eax
  101c2e:	8b 00                	mov    (%eax),%eax
  101c30:	ba 00 00 00 00       	mov    $0x0,%edx
  101c35:	eb 1c                	jmp    101c53 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  101c37:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c3a:	8b 00                	mov    (%eax),%eax
  101c3c:	8d 50 04             	lea    0x4(%eax),%edx
  101c3f:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c42:	89 10                	mov    %edx,(%eax)
  101c44:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c47:	8b 00                	mov    (%eax),%eax
  101c49:	83 e8 04             	sub    $0x4,%eax
  101c4c:	8b 00                	mov    (%eax),%eax
  101c4e:	ba 00 00 00 00       	mov    $0x0,%edx
}
  101c53:	5d                   	pop    %ebp
  101c54:	c3                   	ret    

00101c55 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  101c55:	55                   	push   %ebp
  101c56:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  101c58:	8b 45 08             	mov    0x8(%ebp),%eax
  101c5b:	8b 40 18             	mov    0x18(%eax),%eax
  101c5e:	83 e0 02             	and    $0x2,%eax
  101c61:	85 c0                	test   %eax,%eax
  101c63:	74 1c                	je     101c81 <getint+0x2c>
		return va_arg(*ap, long long);
  101c65:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c68:	8b 00                	mov    (%eax),%eax
  101c6a:	8d 50 08             	lea    0x8(%eax),%edx
  101c6d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c70:	89 10                	mov    %edx,(%eax)
  101c72:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c75:	8b 00                	mov    (%eax),%eax
  101c77:	83 e8 08             	sub    $0x8,%eax
  101c7a:	8b 50 04             	mov    0x4(%eax),%edx
  101c7d:	8b 00                	mov    (%eax),%eax
  101c7f:	eb 47                	jmp    101cc8 <getint+0x73>
	else if (st->flags & F_L)
  101c81:	8b 45 08             	mov    0x8(%ebp),%eax
  101c84:	8b 40 18             	mov    0x18(%eax),%eax
  101c87:	83 e0 01             	and    $0x1,%eax
  101c8a:	84 c0                	test   %al,%al
  101c8c:	74 1e                	je     101cac <getint+0x57>
		return va_arg(*ap, long);
  101c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c91:	8b 00                	mov    (%eax),%eax
  101c93:	8d 50 04             	lea    0x4(%eax),%edx
  101c96:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c99:	89 10                	mov    %edx,(%eax)
  101c9b:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c9e:	8b 00                	mov    (%eax),%eax
  101ca0:	83 e8 04             	sub    $0x4,%eax
  101ca3:	8b 00                	mov    (%eax),%eax
  101ca5:	89 c2                	mov    %eax,%edx
  101ca7:	c1 fa 1f             	sar    $0x1f,%edx
  101caa:	eb 1c                	jmp    101cc8 <getint+0x73>
	else
		return va_arg(*ap, int);
  101cac:	8b 45 0c             	mov    0xc(%ebp),%eax
  101caf:	8b 00                	mov    (%eax),%eax
  101cb1:	8d 50 04             	lea    0x4(%eax),%edx
  101cb4:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cb7:	89 10                	mov    %edx,(%eax)
  101cb9:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cbc:	8b 00                	mov    (%eax),%eax
  101cbe:	83 e8 04             	sub    $0x4,%eax
  101cc1:	8b 00                	mov    (%eax),%eax
  101cc3:	89 c2                	mov    %eax,%edx
  101cc5:	c1 fa 1f             	sar    $0x1f,%edx
}
  101cc8:	5d                   	pop    %ebp
  101cc9:	c3                   	ret    

00101cca <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  101cca:	55                   	push   %ebp
  101ccb:	89 e5                	mov    %esp,%ebp
  101ccd:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  101cd0:	eb 1a                	jmp    101cec <putpad+0x22>
		st->putch(st->padc, st->putdat);
  101cd2:	8b 45 08             	mov    0x8(%ebp),%eax
  101cd5:	8b 08                	mov    (%eax),%ecx
  101cd7:	8b 45 08             	mov    0x8(%ebp),%eax
  101cda:	8b 50 04             	mov    0x4(%eax),%edx
  101cdd:	8b 45 08             	mov    0x8(%ebp),%eax
  101ce0:	8b 40 08             	mov    0x8(%eax),%eax
  101ce3:	89 54 24 04          	mov    %edx,0x4(%esp)
  101ce7:	89 04 24             	mov    %eax,(%esp)
  101cea:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  101cec:	8b 45 08             	mov    0x8(%ebp),%eax
  101cef:	8b 40 0c             	mov    0xc(%eax),%eax
  101cf2:	8d 50 ff             	lea    -0x1(%eax),%edx
  101cf5:	8b 45 08             	mov    0x8(%ebp),%eax
  101cf8:	89 50 0c             	mov    %edx,0xc(%eax)
  101cfb:	8b 45 08             	mov    0x8(%ebp),%eax
  101cfe:	8b 40 0c             	mov    0xc(%eax),%eax
  101d01:	85 c0                	test   %eax,%eax
  101d03:	79 cd                	jns    101cd2 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  101d05:	c9                   	leave  
  101d06:	c3                   	ret    

00101d07 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  101d07:	55                   	push   %ebp
  101d08:	89 e5                	mov    %esp,%ebp
  101d0a:	53                   	push   %ebx
  101d0b:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  101d0e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  101d12:	79 18                	jns    101d2c <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  101d14:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101d1b:	00 
  101d1c:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d1f:	89 04 24             	mov    %eax,(%esp)
  101d22:	e8 e7 07 00 00       	call   10250e <strchr>
  101d27:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101d2a:	eb 2c                	jmp    101d58 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  101d2c:	8b 45 10             	mov    0x10(%ebp),%eax
  101d2f:	89 44 24 08          	mov    %eax,0x8(%esp)
  101d33:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101d3a:	00 
  101d3b:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d3e:	89 04 24             	mov    %eax,(%esp)
  101d41:	e8 cc 09 00 00       	call   102712 <memchr>
  101d46:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101d49:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101d4d:	75 09                	jne    101d58 <putstr+0x51>
		lim = str + maxlen;
  101d4f:	8b 45 10             	mov    0x10(%ebp),%eax
  101d52:	03 45 0c             	add    0xc(%ebp),%eax
  101d55:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  101d58:	8b 45 08             	mov    0x8(%ebp),%eax
  101d5b:	8b 40 0c             	mov    0xc(%eax),%eax
  101d5e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  101d61:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101d64:	89 cb                	mov    %ecx,%ebx
  101d66:	29 d3                	sub    %edx,%ebx
  101d68:	89 da                	mov    %ebx,%edx
  101d6a:	8d 14 10             	lea    (%eax,%edx,1),%edx
  101d6d:	8b 45 08             	mov    0x8(%ebp),%eax
  101d70:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  101d73:	8b 45 08             	mov    0x8(%ebp),%eax
  101d76:	8b 40 18             	mov    0x18(%eax),%eax
  101d79:	83 e0 10             	and    $0x10,%eax
  101d7c:	85 c0                	test   %eax,%eax
  101d7e:	75 32                	jne    101db2 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  101d80:	8b 45 08             	mov    0x8(%ebp),%eax
  101d83:	89 04 24             	mov    %eax,(%esp)
  101d86:	e8 3f ff ff ff       	call   101cca <putpad>
	while (str < lim) {
  101d8b:	eb 25                	jmp    101db2 <putstr+0xab>
		char ch = *str++;
  101d8d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d90:	0f b6 00             	movzbl (%eax),%eax
  101d93:	88 45 f7             	mov    %al,-0x9(%ebp)
  101d96:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  101d9a:	8b 45 08             	mov    0x8(%ebp),%eax
  101d9d:	8b 08                	mov    (%eax),%ecx
  101d9f:	8b 45 08             	mov    0x8(%ebp),%eax
  101da2:	8b 50 04             	mov    0x4(%eax),%edx
  101da5:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  101da9:	89 54 24 04          	mov    %edx,0x4(%esp)
  101dad:	89 04 24             	mov    %eax,(%esp)
  101db0:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  101db2:	8b 45 0c             	mov    0xc(%ebp),%eax
  101db5:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  101db8:	72 d3                	jb     101d8d <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  101dba:	8b 45 08             	mov    0x8(%ebp),%eax
  101dbd:	89 04 24             	mov    %eax,(%esp)
  101dc0:	e8 05 ff ff ff       	call   101cca <putpad>
}
  101dc5:	83 c4 24             	add    $0x24,%esp
  101dc8:	5b                   	pop    %ebx
  101dc9:	5d                   	pop    %ebp
  101dca:	c3                   	ret    

00101dcb <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  101dcb:	55                   	push   %ebp
  101dcc:	89 e5                	mov    %esp,%ebp
  101dce:	53                   	push   %ebx
  101dcf:	83 ec 24             	sub    $0x24,%esp
  101dd2:	8b 45 10             	mov    0x10(%ebp),%eax
  101dd5:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101dd8:	8b 45 14             	mov    0x14(%ebp),%eax
  101ddb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  101dde:	8b 45 08             	mov    0x8(%ebp),%eax
  101de1:	8b 40 1c             	mov    0x1c(%eax),%eax
  101de4:	89 c2                	mov    %eax,%edx
  101de6:	c1 fa 1f             	sar    $0x1f,%edx
  101de9:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  101dec:	77 4e                	ja     101e3c <genint+0x71>
  101dee:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  101df1:	72 05                	jb     101df8 <genint+0x2d>
  101df3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  101df6:	77 44                	ja     101e3c <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  101df8:	8b 45 08             	mov    0x8(%ebp),%eax
  101dfb:	8b 40 1c             	mov    0x1c(%eax),%eax
  101dfe:	89 c2                	mov    %eax,%edx
  101e00:	c1 fa 1f             	sar    $0x1f,%edx
  101e03:	89 44 24 08          	mov    %eax,0x8(%esp)
  101e07:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101e0b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e0e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101e11:	89 04 24             	mov    %eax,(%esp)
  101e14:	89 54 24 04          	mov    %edx,0x4(%esp)
  101e18:	e8 33 09 00 00       	call   102750 <__udivdi3>
  101e1d:	89 44 24 08          	mov    %eax,0x8(%esp)
  101e21:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101e25:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e28:	89 44 24 04          	mov    %eax,0x4(%esp)
  101e2c:	8b 45 08             	mov    0x8(%ebp),%eax
  101e2f:	89 04 24             	mov    %eax,(%esp)
  101e32:	e8 94 ff ff ff       	call   101dcb <genint>
  101e37:	89 45 0c             	mov    %eax,0xc(%ebp)
  101e3a:	eb 1b                	jmp    101e57 <genint+0x8c>
	else if (st->signc >= 0)
  101e3c:	8b 45 08             	mov    0x8(%ebp),%eax
  101e3f:	8b 40 14             	mov    0x14(%eax),%eax
  101e42:	85 c0                	test   %eax,%eax
  101e44:	78 11                	js     101e57 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  101e46:	8b 45 08             	mov    0x8(%ebp),%eax
  101e49:	8b 40 14             	mov    0x14(%eax),%eax
  101e4c:	89 c2                	mov    %eax,%edx
  101e4e:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e51:	88 10                	mov    %dl,(%eax)
  101e53:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  101e57:	8b 45 08             	mov    0x8(%ebp),%eax
  101e5a:	8b 40 1c             	mov    0x1c(%eax),%eax
  101e5d:	89 c1                	mov    %eax,%ecx
  101e5f:	89 c3                	mov    %eax,%ebx
  101e61:	c1 fb 1f             	sar    $0x1f,%ebx
  101e64:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e67:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101e6a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  101e6e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  101e72:	89 04 24             	mov    %eax,(%esp)
  101e75:	89 54 24 04          	mov    %edx,0x4(%esp)
  101e79:	e8 02 0a 00 00       	call   102880 <__umoddi3>
  101e7e:	05 1c 33 10 00       	add    $0x10331c,%eax
  101e83:	0f b6 10             	movzbl (%eax),%edx
  101e86:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e89:	88 10                	mov    %dl,(%eax)
  101e8b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  101e8f:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  101e92:	83 c4 24             	add    $0x24,%esp
  101e95:	5b                   	pop    %ebx
  101e96:	5d                   	pop    %ebp
  101e97:	c3                   	ret    

00101e98 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  101e98:	55                   	push   %ebp
  101e99:	89 e5                	mov    %esp,%ebp
  101e9b:	83 ec 58             	sub    $0x58,%esp
  101e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ea1:	89 45 c0             	mov    %eax,-0x40(%ebp)
  101ea4:	8b 45 10             	mov    0x10(%ebp),%eax
  101ea7:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  101eaa:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  101ead:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  101eb0:	8b 45 08             	mov    0x8(%ebp),%eax
  101eb3:	8b 55 14             	mov    0x14(%ebp),%edx
  101eb6:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  101eb9:	8b 45 c0             	mov    -0x40(%ebp),%eax
  101ebc:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  101ebf:	89 44 24 08          	mov    %eax,0x8(%esp)
  101ec3:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101ec7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101eca:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ece:	8b 45 08             	mov    0x8(%ebp),%eax
  101ed1:	89 04 24             	mov    %eax,(%esp)
  101ed4:	e8 f2 fe ff ff       	call   101dcb <genint>
  101ed9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  101edc:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101edf:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  101ee2:	89 d1                	mov    %edx,%ecx
  101ee4:	29 c1                	sub    %eax,%ecx
  101ee6:	89 c8                	mov    %ecx,%eax
  101ee8:	89 44 24 08          	mov    %eax,0x8(%esp)
  101eec:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  101eef:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ef3:	8b 45 08             	mov    0x8(%ebp),%eax
  101ef6:	89 04 24             	mov    %eax,(%esp)
  101ef9:	e8 09 fe ff ff       	call   101d07 <putstr>
}
  101efe:	c9                   	leave  
  101eff:	c3                   	ret    

00101f00 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  101f00:	55                   	push   %ebp
  101f01:	89 e5                	mov    %esp,%ebp
  101f03:	53                   	push   %ebx
  101f04:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  101f07:	8d 55 c8             	lea    -0x38(%ebp),%edx
  101f0a:	b9 00 00 00 00       	mov    $0x0,%ecx
  101f0f:	b8 20 00 00 00       	mov    $0x20,%eax
  101f14:	89 c3                	mov    %eax,%ebx
  101f16:	83 e3 fc             	and    $0xfffffffc,%ebx
  101f19:	b8 00 00 00 00       	mov    $0x0,%eax
  101f1e:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  101f21:	83 c0 04             	add    $0x4,%eax
  101f24:	39 d8                	cmp    %ebx,%eax
  101f26:	72 f6                	jb     101f1e <vprintfmt+0x1e>
  101f28:	01 c2                	add    %eax,%edx
  101f2a:	8b 45 08             	mov    0x8(%ebp),%eax
  101f2d:	89 45 c8             	mov    %eax,-0x38(%ebp)
  101f30:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f33:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  101f36:	eb 17                	jmp    101f4f <vprintfmt+0x4f>
			if (ch == '\0')
  101f38:	85 db                	test   %ebx,%ebx
  101f3a:	0f 84 52 03 00 00    	je     102292 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  101f40:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f43:	89 44 24 04          	mov    %eax,0x4(%esp)
  101f47:	89 1c 24             	mov    %ebx,(%esp)
  101f4a:	8b 45 08             	mov    0x8(%ebp),%eax
  101f4d:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  101f4f:	8b 45 10             	mov    0x10(%ebp),%eax
  101f52:	0f b6 00             	movzbl (%eax),%eax
  101f55:	0f b6 d8             	movzbl %al,%ebx
  101f58:	83 fb 25             	cmp    $0x25,%ebx
  101f5b:	0f 95 c0             	setne  %al
  101f5e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  101f62:	84 c0                	test   %al,%al
  101f64:	75 d2                	jne    101f38 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  101f66:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  101f6d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  101f74:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  101f7b:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  101f82:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  101f89:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  101f90:	eb 04                	jmp    101f96 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  101f92:	90                   	nop
  101f93:	eb 01                	jmp    101f96 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  101f95:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  101f96:	8b 45 10             	mov    0x10(%ebp),%eax
  101f99:	0f b6 00             	movzbl (%eax),%eax
  101f9c:	0f b6 d8             	movzbl %al,%ebx
  101f9f:	89 d8                	mov    %ebx,%eax
  101fa1:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  101fa5:	83 e8 20             	sub    $0x20,%eax
  101fa8:	83 f8 58             	cmp    $0x58,%eax
  101fab:	0f 87 b1 02 00 00    	ja     102262 <vprintfmt+0x362>
  101fb1:	8b 04 85 34 33 10 00 	mov    0x103334(,%eax,4),%eax
  101fb8:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  101fba:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101fbd:	83 c8 10             	or     $0x10,%eax
  101fc0:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  101fc3:	eb d1                	jmp    101f96 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  101fc5:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  101fcc:	eb c8                	jmp    101f96 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  101fce:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101fd1:	85 c0                	test   %eax,%eax
  101fd3:	79 bd                	jns    101f92 <vprintfmt+0x92>
				st.signc = ' ';
  101fd5:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  101fdc:	eb b8                	jmp    101f96 <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  101fde:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101fe1:	83 e0 08             	and    $0x8,%eax
  101fe4:	85 c0                	test   %eax,%eax
  101fe6:	75 07                	jne    101fef <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  101fe8:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  101fef:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  101ff6:	8b 55 d8             	mov    -0x28(%ebp),%edx
  101ff9:	89 d0                	mov    %edx,%eax
  101ffb:	c1 e0 02             	shl    $0x2,%eax
  101ffe:	01 d0                	add    %edx,%eax
  102000:	01 c0                	add    %eax,%eax
  102002:	01 d8                	add    %ebx,%eax
  102004:	83 e8 30             	sub    $0x30,%eax
  102007:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  10200a:	8b 45 10             	mov    0x10(%ebp),%eax
  10200d:	0f b6 00             	movzbl (%eax),%eax
  102010:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  102013:	83 fb 2f             	cmp    $0x2f,%ebx
  102016:	7e 21                	jle    102039 <vprintfmt+0x139>
  102018:	83 fb 39             	cmp    $0x39,%ebx
  10201b:	7f 1f                	jg     10203c <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10201d:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  102021:	eb d3                	jmp    101ff6 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  102023:	8b 45 14             	mov    0x14(%ebp),%eax
  102026:	83 c0 04             	add    $0x4,%eax
  102029:	89 45 14             	mov    %eax,0x14(%ebp)
  10202c:	8b 45 14             	mov    0x14(%ebp),%eax
  10202f:	83 e8 04             	sub    $0x4,%eax
  102032:	8b 00                	mov    (%eax),%eax
  102034:	89 45 d8             	mov    %eax,-0x28(%ebp)
  102037:	eb 04                	jmp    10203d <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  102039:	90                   	nop
  10203a:	eb 01                	jmp    10203d <vprintfmt+0x13d>
  10203c:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  10203d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102040:	83 e0 08             	and    $0x8,%eax
  102043:	85 c0                	test   %eax,%eax
  102045:	0f 85 4a ff ff ff    	jne    101f95 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  10204b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10204e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  102051:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  102058:	e9 39 ff ff ff       	jmp    101f96 <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  10205d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102060:	83 c8 08             	or     $0x8,%eax
  102063:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102066:	e9 2b ff ff ff       	jmp    101f96 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  10206b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10206e:	83 c8 04             	or     $0x4,%eax
  102071:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102074:	e9 1d ff ff ff       	jmp    101f96 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  102079:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10207c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10207f:	83 e0 01             	and    $0x1,%eax
  102082:	84 c0                	test   %al,%al
  102084:	74 07                	je     10208d <vprintfmt+0x18d>
  102086:	b8 02 00 00 00       	mov    $0x2,%eax
  10208b:	eb 05                	jmp    102092 <vprintfmt+0x192>
  10208d:	b8 01 00 00 00       	mov    $0x1,%eax
  102092:	09 d0                	or     %edx,%eax
  102094:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102097:	e9 fa fe ff ff       	jmp    101f96 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  10209c:	8b 45 14             	mov    0x14(%ebp),%eax
  10209f:	83 c0 04             	add    $0x4,%eax
  1020a2:	89 45 14             	mov    %eax,0x14(%ebp)
  1020a5:	8b 45 14             	mov    0x14(%ebp),%eax
  1020a8:	83 e8 04             	sub    $0x4,%eax
  1020ab:	8b 00                	mov    (%eax),%eax
  1020ad:	8b 55 0c             	mov    0xc(%ebp),%edx
  1020b0:	89 54 24 04          	mov    %edx,0x4(%esp)
  1020b4:	89 04 24             	mov    %eax,(%esp)
  1020b7:	8b 45 08             	mov    0x8(%ebp),%eax
  1020ba:	ff d0                	call   *%eax
			break;
  1020bc:	e9 cb 01 00 00       	jmp    10228c <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  1020c1:	8b 45 14             	mov    0x14(%ebp),%eax
  1020c4:	83 c0 04             	add    $0x4,%eax
  1020c7:	89 45 14             	mov    %eax,0x14(%ebp)
  1020ca:	8b 45 14             	mov    0x14(%ebp),%eax
  1020cd:	83 e8 04             	sub    $0x4,%eax
  1020d0:	8b 00                	mov    (%eax),%eax
  1020d2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1020d5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1020d9:	75 07                	jne    1020e2 <vprintfmt+0x1e2>
				s = "(null)";
  1020db:	c7 45 f4 2d 33 10 00 	movl   $0x10332d,-0xc(%ebp)
			putstr(&st, s, st.prec);
  1020e2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1020e5:	89 44 24 08          	mov    %eax,0x8(%esp)
  1020e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1020ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  1020f0:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1020f3:	89 04 24             	mov    %eax,(%esp)
  1020f6:	e8 0c fc ff ff       	call   101d07 <putstr>
			break;
  1020fb:	e9 8c 01 00 00       	jmp    10228c <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  102100:	8d 45 14             	lea    0x14(%ebp),%eax
  102103:	89 44 24 04          	mov    %eax,0x4(%esp)
  102107:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10210a:	89 04 24             	mov    %eax,(%esp)
  10210d:	e8 43 fb ff ff       	call   101c55 <getint>
  102112:	89 45 e8             	mov    %eax,-0x18(%ebp)
  102115:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  102118:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10211b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10211e:	85 d2                	test   %edx,%edx
  102120:	79 1a                	jns    10213c <vprintfmt+0x23c>
				num = -(intmax_t) num;
  102122:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102125:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102128:	f7 d8                	neg    %eax
  10212a:	83 d2 00             	adc    $0x0,%edx
  10212d:	f7 da                	neg    %edx
  10212f:	89 45 e8             	mov    %eax,-0x18(%ebp)
  102132:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  102135:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  10213c:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  102143:	00 
  102144:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102147:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10214a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10214e:	89 54 24 08          	mov    %edx,0x8(%esp)
  102152:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102155:	89 04 24             	mov    %eax,(%esp)
  102158:	e8 3b fd ff ff       	call   101e98 <putint>
			break;
  10215d:	e9 2a 01 00 00       	jmp    10228c <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  102162:	8d 45 14             	lea    0x14(%ebp),%eax
  102165:	89 44 24 04          	mov    %eax,0x4(%esp)
  102169:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10216c:	89 04 24             	mov    %eax,(%esp)
  10216f:	e8 6c fa ff ff       	call   101be0 <getuint>
  102174:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10217b:	00 
  10217c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102180:	89 54 24 08          	mov    %edx,0x8(%esp)
  102184:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102187:	89 04 24             	mov    %eax,(%esp)
  10218a:	e8 09 fd ff ff       	call   101e98 <putint>
			break;
  10218f:	e9 f8 00 00 00       	jmp    10228c <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  102194:	8d 45 14             	lea    0x14(%ebp),%eax
  102197:	89 44 24 04          	mov    %eax,0x4(%esp)
  10219b:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10219e:	89 04 24             	mov    %eax,(%esp)
  1021a1:	e8 3a fa ff ff       	call   101be0 <getuint>
  1021a6:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  1021ad:	00 
  1021ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021b2:	89 54 24 08          	mov    %edx,0x8(%esp)
  1021b6:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1021b9:	89 04 24             	mov    %eax,(%esp)
  1021bc:	e8 d7 fc ff ff       	call   101e98 <putint>
			break;
  1021c1:	e9 c6 00 00 00       	jmp    10228c <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  1021c6:	8d 45 14             	lea    0x14(%ebp),%eax
  1021c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021cd:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1021d0:	89 04 24             	mov    %eax,(%esp)
  1021d3:	e8 08 fa ff ff       	call   101be0 <getuint>
  1021d8:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1021df:	00 
  1021e0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021e4:	89 54 24 08          	mov    %edx,0x8(%esp)
  1021e8:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1021eb:	89 04 24             	mov    %eax,(%esp)
  1021ee:	e8 a5 fc ff ff       	call   101e98 <putint>
			break;
  1021f3:	e9 94 00 00 00       	jmp    10228c <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  1021f8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021fb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021ff:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  102206:	8b 45 08             	mov    0x8(%ebp),%eax
  102209:	ff d0                	call   *%eax
			putch('x', putdat);
  10220b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10220e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102212:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  102219:	8b 45 08             	mov    0x8(%ebp),%eax
  10221c:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  10221e:	8b 45 14             	mov    0x14(%ebp),%eax
  102221:	83 c0 04             	add    $0x4,%eax
  102224:	89 45 14             	mov    %eax,0x14(%ebp)
  102227:	8b 45 14             	mov    0x14(%ebp),%eax
  10222a:	83 e8 04             	sub    $0x4,%eax
  10222d:	8b 00                	mov    (%eax),%eax
  10222f:	ba 00 00 00 00       	mov    $0x0,%edx
  102234:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10223b:	00 
  10223c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102240:	89 54 24 08          	mov    %edx,0x8(%esp)
  102244:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102247:	89 04 24             	mov    %eax,(%esp)
  10224a:	e8 49 fc ff ff       	call   101e98 <putint>
			break;
  10224f:	eb 3b                	jmp    10228c <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  102251:	8b 45 0c             	mov    0xc(%ebp),%eax
  102254:	89 44 24 04          	mov    %eax,0x4(%esp)
  102258:	89 1c 24             	mov    %ebx,(%esp)
  10225b:	8b 45 08             	mov    0x8(%ebp),%eax
  10225e:	ff d0                	call   *%eax
			break;
  102260:	eb 2a                	jmp    10228c <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  102262:	8b 45 0c             	mov    0xc(%ebp),%eax
  102265:	89 44 24 04          	mov    %eax,0x4(%esp)
  102269:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  102270:	8b 45 08             	mov    0x8(%ebp),%eax
  102273:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  102275:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102279:	eb 04                	jmp    10227f <vprintfmt+0x37f>
  10227b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10227f:	8b 45 10             	mov    0x10(%ebp),%eax
  102282:	83 e8 01             	sub    $0x1,%eax
  102285:	0f b6 00             	movzbl (%eax),%eax
  102288:	3c 25                	cmp    $0x25,%al
  10228a:	75 ef                	jne    10227b <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  10228c:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10228d:	e9 bd fc ff ff       	jmp    101f4f <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  102292:	83 c4 44             	add    $0x44,%esp
  102295:	5b                   	pop    %ebx
  102296:	5d                   	pop    %ebp
  102297:	c3                   	ret    

00102298 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  102298:	55                   	push   %ebp
  102299:	89 e5                	mov    %esp,%ebp
  10229b:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  10229e:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022a1:	8b 00                	mov    (%eax),%eax
  1022a3:	8b 55 08             	mov    0x8(%ebp),%edx
  1022a6:	89 d1                	mov    %edx,%ecx
  1022a8:	8b 55 0c             	mov    0xc(%ebp),%edx
  1022ab:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  1022af:	8d 50 01             	lea    0x1(%eax),%edx
  1022b2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022b5:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  1022b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022ba:	8b 00                	mov    (%eax),%eax
  1022bc:	3d ff 00 00 00       	cmp    $0xff,%eax
  1022c1:	75 24                	jne    1022e7 <putch+0x4f>
		b->buf[b->idx] = 0;
  1022c3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022c6:	8b 00                	mov    (%eax),%eax
  1022c8:	8b 55 0c             	mov    0xc(%ebp),%edx
  1022cb:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  1022d0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022d3:	83 c0 08             	add    $0x8,%eax
  1022d6:	89 04 24             	mov    %eax,(%esp)
  1022d9:	e8 22 e0 ff ff       	call   100300 <cputs>
		b->idx = 0;
  1022de:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022e1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  1022e7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022ea:	8b 40 04             	mov    0x4(%eax),%eax
  1022ed:	8d 50 01             	lea    0x1(%eax),%edx
  1022f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022f3:	89 50 04             	mov    %edx,0x4(%eax)
}
  1022f6:	c9                   	leave  
  1022f7:	c3                   	ret    

001022f8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  1022f8:	55                   	push   %ebp
  1022f9:	89 e5                	mov    %esp,%ebp
  1022fb:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  102301:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  102308:	00 00 00 
	b.cnt = 0;
  10230b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  102312:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  102315:	b8 98 22 10 00       	mov    $0x102298,%eax
  10231a:	8b 55 0c             	mov    0xc(%ebp),%edx
  10231d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102321:	8b 55 08             	mov    0x8(%ebp),%edx
  102324:	89 54 24 08          	mov    %edx,0x8(%esp)
  102328:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  10232e:	89 54 24 04          	mov    %edx,0x4(%esp)
  102332:	89 04 24             	mov    %eax,(%esp)
  102335:	e8 c6 fb ff ff       	call   101f00 <vprintfmt>

	b.buf[b.idx] = 0;
  10233a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  102340:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  102347:	00 
	cputs(b.buf);
  102348:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  10234e:	83 c0 08             	add    $0x8,%eax
  102351:	89 04 24             	mov    %eax,(%esp)
  102354:	e8 a7 df ff ff       	call   100300 <cputs>

	return b.cnt;
  102359:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  10235f:	c9                   	leave  
  102360:	c3                   	ret    

00102361 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  102361:	55                   	push   %ebp
  102362:	89 e5                	mov    %esp,%ebp
  102364:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  102367:	8d 45 08             	lea    0x8(%ebp),%eax
  10236a:	83 c0 04             	add    $0x4,%eax
  10236d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  102370:	8b 45 08             	mov    0x8(%ebp),%eax
  102373:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102376:	89 54 24 04          	mov    %edx,0x4(%esp)
  10237a:	89 04 24             	mov    %eax,(%esp)
  10237d:	e8 76 ff ff ff       	call   1022f8 <vcprintf>
  102382:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  102385:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  102388:	c9                   	leave  
  102389:	c3                   	ret    

0010238a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  10238a:	55                   	push   %ebp
  10238b:	89 e5                	mov    %esp,%ebp
  10238d:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  102390:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  102397:	eb 08                	jmp    1023a1 <strlen+0x17>
		n++;
  102399:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  10239d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1023a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1023a4:	0f b6 00             	movzbl (%eax),%eax
  1023a7:	84 c0                	test   %al,%al
  1023a9:	75 ee                	jne    102399 <strlen+0xf>
		n++;
	return n;
  1023ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1023ae:	c9                   	leave  
  1023af:	c3                   	ret    

001023b0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  1023b0:	55                   	push   %ebp
  1023b1:	89 e5                	mov    %esp,%ebp
  1023b3:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  1023b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1023b9:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  1023bc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023bf:	0f b6 10             	movzbl (%eax),%edx
  1023c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1023c5:	88 10                	mov    %dl,(%eax)
  1023c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1023ca:	0f b6 00             	movzbl (%eax),%eax
  1023cd:	84 c0                	test   %al,%al
  1023cf:	0f 95 c0             	setne  %al
  1023d2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1023d6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  1023da:	84 c0                	test   %al,%al
  1023dc:	75 de                	jne    1023bc <strcpy+0xc>
		/* do nothing */;
	return ret;
  1023de:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1023e1:	c9                   	leave  
  1023e2:	c3                   	ret    

001023e3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  1023e3:	55                   	push   %ebp
  1023e4:	89 e5                	mov    %esp,%ebp
  1023e6:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  1023e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1023ec:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  1023ef:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1023f6:	eb 21                	jmp    102419 <strncpy+0x36>
		*dst++ = *src;
  1023f8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023fb:	0f b6 10             	movzbl (%eax),%edx
  1023fe:	8b 45 08             	mov    0x8(%ebp),%eax
  102401:	88 10                	mov    %dl,(%eax)
  102403:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  102407:	8b 45 0c             	mov    0xc(%ebp),%eax
  10240a:	0f b6 00             	movzbl (%eax),%eax
  10240d:	84 c0                	test   %al,%al
  10240f:	74 04                	je     102415 <strncpy+0x32>
			src++;
  102411:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  102415:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  102419:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10241c:	3b 45 10             	cmp    0x10(%ebp),%eax
  10241f:	72 d7                	jb     1023f8 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  102421:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102424:	c9                   	leave  
  102425:	c3                   	ret    

00102426 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  102426:	55                   	push   %ebp
  102427:	89 e5                	mov    %esp,%ebp
  102429:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  10242c:	8b 45 08             	mov    0x8(%ebp),%eax
  10242f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  102432:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102436:	74 2f                	je     102467 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  102438:	eb 13                	jmp    10244d <strlcpy+0x27>
			*dst++ = *src++;
  10243a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10243d:	0f b6 10             	movzbl (%eax),%edx
  102440:	8b 45 08             	mov    0x8(%ebp),%eax
  102443:	88 10                	mov    %dl,(%eax)
  102445:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102449:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  10244d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102451:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102455:	74 0a                	je     102461 <strlcpy+0x3b>
  102457:	8b 45 0c             	mov    0xc(%ebp),%eax
  10245a:	0f b6 00             	movzbl (%eax),%eax
  10245d:	84 c0                	test   %al,%al
  10245f:	75 d9                	jne    10243a <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  102461:	8b 45 08             	mov    0x8(%ebp),%eax
  102464:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  102467:	8b 55 08             	mov    0x8(%ebp),%edx
  10246a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10246d:	89 d1                	mov    %edx,%ecx
  10246f:	29 c1                	sub    %eax,%ecx
  102471:	89 c8                	mov    %ecx,%eax
}
  102473:	c9                   	leave  
  102474:	c3                   	ret    

00102475 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  102475:	55                   	push   %ebp
  102476:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  102478:	eb 08                	jmp    102482 <strcmp+0xd>
		p++, q++;
  10247a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10247e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  102482:	8b 45 08             	mov    0x8(%ebp),%eax
  102485:	0f b6 00             	movzbl (%eax),%eax
  102488:	84 c0                	test   %al,%al
  10248a:	74 10                	je     10249c <strcmp+0x27>
  10248c:	8b 45 08             	mov    0x8(%ebp),%eax
  10248f:	0f b6 10             	movzbl (%eax),%edx
  102492:	8b 45 0c             	mov    0xc(%ebp),%eax
  102495:	0f b6 00             	movzbl (%eax),%eax
  102498:	38 c2                	cmp    %al,%dl
  10249a:	74 de                	je     10247a <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  10249c:	8b 45 08             	mov    0x8(%ebp),%eax
  10249f:	0f b6 00             	movzbl (%eax),%eax
  1024a2:	0f b6 d0             	movzbl %al,%edx
  1024a5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024a8:	0f b6 00             	movzbl (%eax),%eax
  1024ab:	0f b6 c0             	movzbl %al,%eax
  1024ae:	89 d1                	mov    %edx,%ecx
  1024b0:	29 c1                	sub    %eax,%ecx
  1024b2:	89 c8                	mov    %ecx,%eax
}
  1024b4:	5d                   	pop    %ebp
  1024b5:	c3                   	ret    

001024b6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  1024b6:	55                   	push   %ebp
  1024b7:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  1024b9:	eb 0c                	jmp    1024c7 <strncmp+0x11>
		n--, p++, q++;
  1024bb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1024bf:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1024c3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  1024c7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1024cb:	74 1a                	je     1024e7 <strncmp+0x31>
  1024cd:	8b 45 08             	mov    0x8(%ebp),%eax
  1024d0:	0f b6 00             	movzbl (%eax),%eax
  1024d3:	84 c0                	test   %al,%al
  1024d5:	74 10                	je     1024e7 <strncmp+0x31>
  1024d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1024da:	0f b6 10             	movzbl (%eax),%edx
  1024dd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024e0:	0f b6 00             	movzbl (%eax),%eax
  1024e3:	38 c2                	cmp    %al,%dl
  1024e5:	74 d4                	je     1024bb <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  1024e7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1024eb:	75 07                	jne    1024f4 <strncmp+0x3e>
		return 0;
  1024ed:	b8 00 00 00 00       	mov    $0x0,%eax
  1024f2:	eb 18                	jmp    10250c <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  1024f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1024f7:	0f b6 00             	movzbl (%eax),%eax
  1024fa:	0f b6 d0             	movzbl %al,%edx
  1024fd:	8b 45 0c             	mov    0xc(%ebp),%eax
  102500:	0f b6 00             	movzbl (%eax),%eax
  102503:	0f b6 c0             	movzbl %al,%eax
  102506:	89 d1                	mov    %edx,%ecx
  102508:	29 c1                	sub    %eax,%ecx
  10250a:	89 c8                	mov    %ecx,%eax
}
  10250c:	5d                   	pop    %ebp
  10250d:	c3                   	ret    

0010250e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  10250e:	55                   	push   %ebp
  10250f:	89 e5                	mov    %esp,%ebp
  102511:	83 ec 04             	sub    $0x4,%esp
  102514:	8b 45 0c             	mov    0xc(%ebp),%eax
  102517:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  10251a:	eb 1a                	jmp    102536 <strchr+0x28>
		if (*s++ == 0)
  10251c:	8b 45 08             	mov    0x8(%ebp),%eax
  10251f:	0f b6 00             	movzbl (%eax),%eax
  102522:	84 c0                	test   %al,%al
  102524:	0f 94 c0             	sete   %al
  102527:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10252b:	84 c0                	test   %al,%al
  10252d:	74 07                	je     102536 <strchr+0x28>
			return NULL;
  10252f:	b8 00 00 00 00       	mov    $0x0,%eax
  102534:	eb 0e                	jmp    102544 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  102536:	8b 45 08             	mov    0x8(%ebp),%eax
  102539:	0f b6 00             	movzbl (%eax),%eax
  10253c:	3a 45 fc             	cmp    -0x4(%ebp),%al
  10253f:	75 db                	jne    10251c <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  102541:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102544:	c9                   	leave  
  102545:	c3                   	ret    

00102546 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  102546:	55                   	push   %ebp
  102547:	89 e5                	mov    %esp,%ebp
  102549:	57                   	push   %edi
  10254a:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  10254d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102551:	75 05                	jne    102558 <memset+0x12>
		return v;
  102553:	8b 45 08             	mov    0x8(%ebp),%eax
  102556:	eb 5c                	jmp    1025b4 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  102558:	8b 45 08             	mov    0x8(%ebp),%eax
  10255b:	83 e0 03             	and    $0x3,%eax
  10255e:	85 c0                	test   %eax,%eax
  102560:	75 41                	jne    1025a3 <memset+0x5d>
  102562:	8b 45 10             	mov    0x10(%ebp),%eax
  102565:	83 e0 03             	and    $0x3,%eax
  102568:	85 c0                	test   %eax,%eax
  10256a:	75 37                	jne    1025a3 <memset+0x5d>
		c &= 0xFF;
  10256c:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  102573:	8b 45 0c             	mov    0xc(%ebp),%eax
  102576:	89 c2                	mov    %eax,%edx
  102578:	c1 e2 18             	shl    $0x18,%edx
  10257b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10257e:	c1 e0 10             	shl    $0x10,%eax
  102581:	09 c2                	or     %eax,%edx
  102583:	8b 45 0c             	mov    0xc(%ebp),%eax
  102586:	c1 e0 08             	shl    $0x8,%eax
  102589:	09 d0                	or     %edx,%eax
  10258b:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  10258e:	8b 45 10             	mov    0x10(%ebp),%eax
  102591:	89 c1                	mov    %eax,%ecx
  102593:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  102596:	8b 55 08             	mov    0x8(%ebp),%edx
  102599:	8b 45 0c             	mov    0xc(%ebp),%eax
  10259c:	89 d7                	mov    %edx,%edi
  10259e:	fc                   	cld    
  10259f:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  1025a1:	eb 0e                	jmp    1025b1 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  1025a3:	8b 55 08             	mov    0x8(%ebp),%edx
  1025a6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025a9:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1025ac:	89 d7                	mov    %edx,%edi
  1025ae:	fc                   	cld    
  1025af:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  1025b1:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1025b4:	83 c4 10             	add    $0x10,%esp
  1025b7:	5f                   	pop    %edi
  1025b8:	5d                   	pop    %ebp
  1025b9:	c3                   	ret    

001025ba <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  1025ba:	55                   	push   %ebp
  1025bb:	89 e5                	mov    %esp,%ebp
  1025bd:	57                   	push   %edi
  1025be:	56                   	push   %esi
  1025bf:	53                   	push   %ebx
  1025c0:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  1025c3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  1025c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1025cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  1025cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1025d2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1025d5:	73 6e                	jae    102645 <memmove+0x8b>
  1025d7:	8b 45 10             	mov    0x10(%ebp),%eax
  1025da:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1025dd:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1025e0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1025e3:	76 60                	jbe    102645 <memmove+0x8b>
		s += n;
  1025e5:	8b 45 10             	mov    0x10(%ebp),%eax
  1025e8:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  1025eb:	8b 45 10             	mov    0x10(%ebp),%eax
  1025ee:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1025f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1025f4:	83 e0 03             	and    $0x3,%eax
  1025f7:	85 c0                	test   %eax,%eax
  1025f9:	75 2f                	jne    10262a <memmove+0x70>
  1025fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1025fe:	83 e0 03             	and    $0x3,%eax
  102601:	85 c0                	test   %eax,%eax
  102603:	75 25                	jne    10262a <memmove+0x70>
  102605:	8b 45 10             	mov    0x10(%ebp),%eax
  102608:	83 e0 03             	and    $0x3,%eax
  10260b:	85 c0                	test   %eax,%eax
  10260d:	75 1b                	jne    10262a <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  10260f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102612:	83 e8 04             	sub    $0x4,%eax
  102615:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102618:	83 ea 04             	sub    $0x4,%edx
  10261b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10261e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  102621:	89 c7                	mov    %eax,%edi
  102623:	89 d6                	mov    %edx,%esi
  102625:	fd                   	std    
  102626:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102628:	eb 18                	jmp    102642 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  10262a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10262d:	8d 50 ff             	lea    -0x1(%eax),%edx
  102630:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102633:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  102636:	8b 45 10             	mov    0x10(%ebp),%eax
  102639:	89 d7                	mov    %edx,%edi
  10263b:	89 de                	mov    %ebx,%esi
  10263d:	89 c1                	mov    %eax,%ecx
  10263f:	fd                   	std    
  102640:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  102642:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  102643:	eb 45                	jmp    10268a <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102645:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102648:	83 e0 03             	and    $0x3,%eax
  10264b:	85 c0                	test   %eax,%eax
  10264d:	75 2b                	jne    10267a <memmove+0xc0>
  10264f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102652:	83 e0 03             	and    $0x3,%eax
  102655:	85 c0                	test   %eax,%eax
  102657:	75 21                	jne    10267a <memmove+0xc0>
  102659:	8b 45 10             	mov    0x10(%ebp),%eax
  10265c:	83 e0 03             	and    $0x3,%eax
  10265f:	85 c0                	test   %eax,%eax
  102661:	75 17                	jne    10267a <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  102663:	8b 45 10             	mov    0x10(%ebp),%eax
  102666:	89 c1                	mov    %eax,%ecx
  102668:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  10266b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10266e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102671:	89 c7                	mov    %eax,%edi
  102673:	89 d6                	mov    %edx,%esi
  102675:	fc                   	cld    
  102676:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102678:	eb 10                	jmp    10268a <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  10267a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10267d:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102680:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102683:	89 c7                	mov    %eax,%edi
  102685:	89 d6                	mov    %edx,%esi
  102687:	fc                   	cld    
  102688:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  10268a:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10268d:	83 c4 10             	add    $0x10,%esp
  102690:	5b                   	pop    %ebx
  102691:	5e                   	pop    %esi
  102692:	5f                   	pop    %edi
  102693:	5d                   	pop    %ebp
  102694:	c3                   	ret    

00102695 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  102695:	55                   	push   %ebp
  102696:	89 e5                	mov    %esp,%ebp
  102698:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  10269b:	8b 45 10             	mov    0x10(%ebp),%eax
  10269e:	89 44 24 08          	mov    %eax,0x8(%esp)
  1026a2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026a5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1026a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1026ac:	89 04 24             	mov    %eax,(%esp)
  1026af:	e8 06 ff ff ff       	call   1025ba <memmove>
}
  1026b4:	c9                   	leave  
  1026b5:	c3                   	ret    

001026b6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  1026b6:	55                   	push   %ebp
  1026b7:	89 e5                	mov    %esp,%ebp
  1026b9:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  1026bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1026bf:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  1026c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026c5:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  1026c8:	eb 32                	jmp    1026fc <memcmp+0x46>
		if (*s1 != *s2)
  1026ca:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1026cd:	0f b6 10             	movzbl (%eax),%edx
  1026d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1026d3:	0f b6 00             	movzbl (%eax),%eax
  1026d6:	38 c2                	cmp    %al,%dl
  1026d8:	74 1a                	je     1026f4 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  1026da:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1026dd:	0f b6 00             	movzbl (%eax),%eax
  1026e0:	0f b6 d0             	movzbl %al,%edx
  1026e3:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1026e6:	0f b6 00             	movzbl (%eax),%eax
  1026e9:	0f b6 c0             	movzbl %al,%eax
  1026ec:	89 d1                	mov    %edx,%ecx
  1026ee:	29 c1                	sub    %eax,%ecx
  1026f0:	89 c8                	mov    %ecx,%eax
  1026f2:	eb 1c                	jmp    102710 <memcmp+0x5a>
		s1++, s2++;
  1026f4:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1026f8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  1026fc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102700:	0f 95 c0             	setne  %al
  102703:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102707:	84 c0                	test   %al,%al
  102709:	75 bf                	jne    1026ca <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  10270b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102710:	c9                   	leave  
  102711:	c3                   	ret    

00102712 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  102712:	55                   	push   %ebp
  102713:	89 e5                	mov    %esp,%ebp
  102715:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  102718:	8b 45 10             	mov    0x10(%ebp),%eax
  10271b:	8b 55 08             	mov    0x8(%ebp),%edx
  10271e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102721:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  102724:	eb 16                	jmp    10273c <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  102726:	8b 45 08             	mov    0x8(%ebp),%eax
  102729:	0f b6 10             	movzbl (%eax),%edx
  10272c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10272f:	38 c2                	cmp    %al,%dl
  102731:	75 05                	jne    102738 <memchr+0x26>
			return (void *) s;
  102733:	8b 45 08             	mov    0x8(%ebp),%eax
  102736:	eb 11                	jmp    102749 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  102738:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10273c:	8b 45 08             	mov    0x8(%ebp),%eax
  10273f:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  102742:	72 e2                	jb     102726 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  102744:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102749:	c9                   	leave  
  10274a:	c3                   	ret    
  10274b:	66 90                	xchg   %ax,%ax
  10274d:	66 90                	xchg   %ax,%ax
  10274f:	90                   	nop

00102750 <__udivdi3>:
  102750:	55                   	push   %ebp
  102751:	89 e5                	mov    %esp,%ebp
  102753:	57                   	push   %edi
  102754:	56                   	push   %esi
  102755:	83 ec 10             	sub    $0x10,%esp
  102758:	8b 45 14             	mov    0x14(%ebp),%eax
  10275b:	8b 55 08             	mov    0x8(%ebp),%edx
  10275e:	8b 75 10             	mov    0x10(%ebp),%esi
  102761:	8b 7d 0c             	mov    0xc(%ebp),%edi
  102764:	85 c0                	test   %eax,%eax
  102766:	89 55 f0             	mov    %edx,-0x10(%ebp)
  102769:	75 35                	jne    1027a0 <__udivdi3+0x50>
  10276b:	39 fe                	cmp    %edi,%esi
  10276d:	77 61                	ja     1027d0 <__udivdi3+0x80>
  10276f:	85 f6                	test   %esi,%esi
  102771:	75 0b                	jne    10277e <__udivdi3+0x2e>
  102773:	b8 01 00 00 00       	mov    $0x1,%eax
  102778:	31 d2                	xor    %edx,%edx
  10277a:	f7 f6                	div    %esi
  10277c:	89 c6                	mov    %eax,%esi
  10277e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  102781:	31 d2                	xor    %edx,%edx
  102783:	89 f8                	mov    %edi,%eax
  102785:	f7 f6                	div    %esi
  102787:	89 c7                	mov    %eax,%edi
  102789:	89 c8                	mov    %ecx,%eax
  10278b:	f7 f6                	div    %esi
  10278d:	89 c1                	mov    %eax,%ecx
  10278f:	89 fa                	mov    %edi,%edx
  102791:	89 c8                	mov    %ecx,%eax
  102793:	83 c4 10             	add    $0x10,%esp
  102796:	5e                   	pop    %esi
  102797:	5f                   	pop    %edi
  102798:	5d                   	pop    %ebp
  102799:	c3                   	ret    
  10279a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1027a0:	39 f8                	cmp    %edi,%eax
  1027a2:	77 1c                	ja     1027c0 <__udivdi3+0x70>
  1027a4:	0f bd d0             	bsr    %eax,%edx
  1027a7:	83 f2 1f             	xor    $0x1f,%edx
  1027aa:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1027ad:	75 39                	jne    1027e8 <__udivdi3+0x98>
  1027af:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  1027b2:	0f 86 a0 00 00 00    	jbe    102858 <__udivdi3+0x108>
  1027b8:	39 f8                	cmp    %edi,%eax
  1027ba:	0f 82 98 00 00 00    	jb     102858 <__udivdi3+0x108>
  1027c0:	31 ff                	xor    %edi,%edi
  1027c2:	31 c9                	xor    %ecx,%ecx
  1027c4:	89 c8                	mov    %ecx,%eax
  1027c6:	89 fa                	mov    %edi,%edx
  1027c8:	83 c4 10             	add    $0x10,%esp
  1027cb:	5e                   	pop    %esi
  1027cc:	5f                   	pop    %edi
  1027cd:	5d                   	pop    %ebp
  1027ce:	c3                   	ret    
  1027cf:	90                   	nop
  1027d0:	89 d1                	mov    %edx,%ecx
  1027d2:	89 fa                	mov    %edi,%edx
  1027d4:	89 c8                	mov    %ecx,%eax
  1027d6:	31 ff                	xor    %edi,%edi
  1027d8:	f7 f6                	div    %esi
  1027da:	89 c1                	mov    %eax,%ecx
  1027dc:	89 fa                	mov    %edi,%edx
  1027de:	89 c8                	mov    %ecx,%eax
  1027e0:	83 c4 10             	add    $0x10,%esp
  1027e3:	5e                   	pop    %esi
  1027e4:	5f                   	pop    %edi
  1027e5:	5d                   	pop    %ebp
  1027e6:	c3                   	ret    
  1027e7:	90                   	nop
  1027e8:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  1027ec:	89 f2                	mov    %esi,%edx
  1027ee:	d3 e0                	shl    %cl,%eax
  1027f0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1027f3:	b8 20 00 00 00       	mov    $0x20,%eax
  1027f8:	2b 45 f4             	sub    -0xc(%ebp),%eax
  1027fb:	89 c1                	mov    %eax,%ecx
  1027fd:	d3 ea                	shr    %cl,%edx
  1027ff:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102803:	0b 55 ec             	or     -0x14(%ebp),%edx
  102806:	d3 e6                	shl    %cl,%esi
  102808:	89 c1                	mov    %eax,%ecx
  10280a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  10280d:	89 fe                	mov    %edi,%esi
  10280f:	d3 ee                	shr    %cl,%esi
  102811:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102815:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102818:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10281b:	d3 e7                	shl    %cl,%edi
  10281d:	89 c1                	mov    %eax,%ecx
  10281f:	d3 ea                	shr    %cl,%edx
  102821:	09 d7                	or     %edx,%edi
  102823:	89 f2                	mov    %esi,%edx
  102825:	89 f8                	mov    %edi,%eax
  102827:	f7 75 ec             	divl   -0x14(%ebp)
  10282a:	89 d6                	mov    %edx,%esi
  10282c:	89 c7                	mov    %eax,%edi
  10282e:	f7 65 e8             	mull   -0x18(%ebp)
  102831:	39 d6                	cmp    %edx,%esi
  102833:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102836:	72 30                	jb     102868 <__udivdi3+0x118>
  102838:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10283b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10283f:	d3 e2                	shl    %cl,%edx
  102841:	39 c2                	cmp    %eax,%edx
  102843:	73 05                	jae    10284a <__udivdi3+0xfa>
  102845:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  102848:	74 1e                	je     102868 <__udivdi3+0x118>
  10284a:	89 f9                	mov    %edi,%ecx
  10284c:	31 ff                	xor    %edi,%edi
  10284e:	e9 71 ff ff ff       	jmp    1027c4 <__udivdi3+0x74>
  102853:	90                   	nop
  102854:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102858:	31 ff                	xor    %edi,%edi
  10285a:	b9 01 00 00 00       	mov    $0x1,%ecx
  10285f:	e9 60 ff ff ff       	jmp    1027c4 <__udivdi3+0x74>
  102864:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102868:	8d 4f ff             	lea    -0x1(%edi),%ecx
  10286b:	31 ff                	xor    %edi,%edi
  10286d:	89 c8                	mov    %ecx,%eax
  10286f:	89 fa                	mov    %edi,%edx
  102871:	83 c4 10             	add    $0x10,%esp
  102874:	5e                   	pop    %esi
  102875:	5f                   	pop    %edi
  102876:	5d                   	pop    %ebp
  102877:	c3                   	ret    
  102878:	66 90                	xchg   %ax,%ax
  10287a:	66 90                	xchg   %ax,%ax
  10287c:	66 90                	xchg   %ax,%ax
  10287e:	66 90                	xchg   %ax,%ax

00102880 <__umoddi3>:
  102880:	55                   	push   %ebp
  102881:	89 e5                	mov    %esp,%ebp
  102883:	57                   	push   %edi
  102884:	56                   	push   %esi
  102885:	83 ec 20             	sub    $0x20,%esp
  102888:	8b 55 14             	mov    0x14(%ebp),%edx
  10288b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10288e:	8b 7d 10             	mov    0x10(%ebp),%edi
  102891:	8b 75 0c             	mov    0xc(%ebp),%esi
  102894:	85 d2                	test   %edx,%edx
  102896:	89 c8                	mov    %ecx,%eax
  102898:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  10289b:	75 13                	jne    1028b0 <__umoddi3+0x30>
  10289d:	39 f7                	cmp    %esi,%edi
  10289f:	76 3f                	jbe    1028e0 <__umoddi3+0x60>
  1028a1:	89 f2                	mov    %esi,%edx
  1028a3:	f7 f7                	div    %edi
  1028a5:	89 d0                	mov    %edx,%eax
  1028a7:	31 d2                	xor    %edx,%edx
  1028a9:	83 c4 20             	add    $0x20,%esp
  1028ac:	5e                   	pop    %esi
  1028ad:	5f                   	pop    %edi
  1028ae:	5d                   	pop    %ebp
  1028af:	c3                   	ret    
  1028b0:	39 f2                	cmp    %esi,%edx
  1028b2:	77 4c                	ja     102900 <__umoddi3+0x80>
  1028b4:	0f bd ca             	bsr    %edx,%ecx
  1028b7:	83 f1 1f             	xor    $0x1f,%ecx
  1028ba:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  1028bd:	75 51                	jne    102910 <__umoddi3+0x90>
  1028bf:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  1028c2:	0f 87 e0 00 00 00    	ja     1029a8 <__umoddi3+0x128>
  1028c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028cb:	29 f8                	sub    %edi,%eax
  1028cd:	19 d6                	sbb    %edx,%esi
  1028cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1028d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028d5:	89 f2                	mov    %esi,%edx
  1028d7:	83 c4 20             	add    $0x20,%esp
  1028da:	5e                   	pop    %esi
  1028db:	5f                   	pop    %edi
  1028dc:	5d                   	pop    %ebp
  1028dd:	c3                   	ret    
  1028de:	66 90                	xchg   %ax,%ax
  1028e0:	85 ff                	test   %edi,%edi
  1028e2:	75 0b                	jne    1028ef <__umoddi3+0x6f>
  1028e4:	b8 01 00 00 00       	mov    $0x1,%eax
  1028e9:	31 d2                	xor    %edx,%edx
  1028eb:	f7 f7                	div    %edi
  1028ed:	89 c7                	mov    %eax,%edi
  1028ef:	89 f0                	mov    %esi,%eax
  1028f1:	31 d2                	xor    %edx,%edx
  1028f3:	f7 f7                	div    %edi
  1028f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028f8:	f7 f7                	div    %edi
  1028fa:	eb a9                	jmp    1028a5 <__umoddi3+0x25>
  1028fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102900:	89 c8                	mov    %ecx,%eax
  102902:	89 f2                	mov    %esi,%edx
  102904:	83 c4 20             	add    $0x20,%esp
  102907:	5e                   	pop    %esi
  102908:	5f                   	pop    %edi
  102909:	5d                   	pop    %ebp
  10290a:	c3                   	ret    
  10290b:	90                   	nop
  10290c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102910:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102914:	d3 e2                	shl    %cl,%edx
  102916:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102919:	ba 20 00 00 00       	mov    $0x20,%edx
  10291e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  102921:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102924:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102928:	89 fa                	mov    %edi,%edx
  10292a:	d3 ea                	shr    %cl,%edx
  10292c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102930:	0b 55 f4             	or     -0xc(%ebp),%edx
  102933:	d3 e7                	shl    %cl,%edi
  102935:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102939:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10293c:	89 f2                	mov    %esi,%edx
  10293e:	89 7d e8             	mov    %edi,-0x18(%ebp)
  102941:	89 c7                	mov    %eax,%edi
  102943:	d3 ea                	shr    %cl,%edx
  102945:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102949:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10294c:	89 c2                	mov    %eax,%edx
  10294e:	d3 e6                	shl    %cl,%esi
  102950:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102954:	d3 ea                	shr    %cl,%edx
  102956:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10295a:	09 d6                	or     %edx,%esi
  10295c:	89 f0                	mov    %esi,%eax
  10295e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  102961:	d3 e7                	shl    %cl,%edi
  102963:	89 f2                	mov    %esi,%edx
  102965:	f7 75 f4             	divl   -0xc(%ebp)
  102968:	89 d6                	mov    %edx,%esi
  10296a:	f7 65 e8             	mull   -0x18(%ebp)
  10296d:	39 d6                	cmp    %edx,%esi
  10296f:	72 2b                	jb     10299c <__umoddi3+0x11c>
  102971:	39 c7                	cmp    %eax,%edi
  102973:	72 23                	jb     102998 <__umoddi3+0x118>
  102975:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102979:	29 c7                	sub    %eax,%edi
  10297b:	19 d6                	sbb    %edx,%esi
  10297d:	89 f0                	mov    %esi,%eax
  10297f:	89 f2                	mov    %esi,%edx
  102981:	d3 ef                	shr    %cl,%edi
  102983:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102987:	d3 e0                	shl    %cl,%eax
  102989:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10298d:	09 f8                	or     %edi,%eax
  10298f:	d3 ea                	shr    %cl,%edx
  102991:	83 c4 20             	add    $0x20,%esp
  102994:	5e                   	pop    %esi
  102995:	5f                   	pop    %edi
  102996:	5d                   	pop    %ebp
  102997:	c3                   	ret    
  102998:	39 d6                	cmp    %edx,%esi
  10299a:	75 d9                	jne    102975 <__umoddi3+0xf5>
  10299c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  10299f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  1029a2:	eb d1                	jmp    102975 <__umoddi3+0xf5>
  1029a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1029a8:	39 f2                	cmp    %esi,%edx
  1029aa:	0f 82 18 ff ff ff    	jb     1028c8 <__umoddi3+0x48>
  1029b0:	e9 1d ff ff ff       	jmp    1028d2 <__umoddi3+0x52>
