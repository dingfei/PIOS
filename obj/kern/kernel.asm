
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
  100050:	c7 44 24 0c 80 2a 10 	movl   $0x102a80,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 96 2a 10 	movl   $0x102a96,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 ab 2a 10 00 	movl   $0x102aab,(%esp)
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
  1000c3:	e8 2e 25 00 00       	call   1025f6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000c8:	e8 eb 01 00 00       	call   1002b8 <cons_init>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  1000cd:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  1000d4:	00 
  1000d5:	c7 04 24 b8 2a 10 00 	movl   $0x102ab8,(%esp)
  1000dc:	e8 30 23 00 00       	call   102411 <cprintf>
	debug_check();
  1000e1:	e8 ae 04 00 00       	call   100594 <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000e6:	e8 0d 0e 00 00       	call   100ef8 <cpu_init>
	trap_init();
  1000eb:	e8 e7 0e 00 00       	call   100fd7 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000f0:	e8 54 07 00 00       	call   100849 <mem_init>


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
  100102:	c7 04 24 d3 2a 10 00 	movl   $0x102ad3,(%esp)
  100109:	e8 03 23 00 00       	call   102411 <cprintf>

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
  10011f:	c7 44 24 0c e0 2a 10 	movl   $0x102ae0,0xc(%esp)
  100126:	00 
  100127:	c7 44 24 08 96 2a 10 	movl   $0x102a96,0x8(%esp)
  10012e:	00 
  10012f:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100136:	00 
  100137:	c7 04 24 07 2b 10 00 	movl   $0x102b07,(%esp)
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
  100154:	c7 44 24 0c 14 2b 10 	movl   $0x102b14,0xc(%esp)
  10015b:	00 
  10015c:	c7 44 24 08 96 2a 10 	movl   $0x102a96,0x8(%esp)
  100163:	00 
  100164:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  10016b:	00 
  10016c:	c7 04 24 07 2b 10 00 	movl   $0x102b07,(%esp)
  100173:	e8 b1 01 00 00       	call   100329 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  100178:	e8 60 11 00 00       	call   1012dd <trap_check_user>

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
  1001b1:	c7 44 24 0c 4c 2b 10 	movl   $0x102b4c,0xc(%esp)
  1001b8:	00 
  1001b9:	c7 44 24 08 62 2b 10 	movl   $0x102b62,0x8(%esp)
  1001c0:	00 
  1001c1:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1001c8:	00 
  1001c9:	c7 04 24 77 2b 10 00 	movl   $0x102b77,(%esp)
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
  100245:	e8 5a 18 00 00       	call   101aa4 <serial_intr>
	kbd_intr();
  10024a:	e8 b0 17 00 00       	call   1019ff <kbd_intr>

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
  1002a6:	e8 16 18 00 00       	call   101ac1 <serial_putc>
	video_putc(c);
  1002ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1002ae:	89 04 24             	mov    %eax,(%esp)
  1002b1:	e8 a8 13 00 00       	call   10165e <video_putc>
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
  1002c7:	e8 c6 12 00 00       	call   101592 <video_init>
	kbd_init();
  1002cc:	e8 42 17 00 00       	call   101a13 <kbd_init>
	serial_init();
  1002d1:	e8 50 18 00 00       	call   101b26 <serial_init>

	if (!serial_exists)
  1002d6:	a1 80 7f 10 00       	mov    0x107f80,%eax
  1002db:	85 c0                	test   %eax,%eax
  1002dd:	75 1f                	jne    1002fe <cons_init+0x46>
		warn("Serial port does not exist!\n");
  1002df:	c7 44 24 08 84 2b 10 	movl   $0x102b84,0x8(%esp)
  1002e6:	00 
  1002e7:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  1002ee:	00 
  1002ef:	c7 04 24 a1 2b 10 00 	movl   $0x102ba1,(%esp)
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
  10036c:	c7 04 24 ad 2b 10 00 	movl   $0x102bad,(%esp)
  100373:	e8 99 20 00 00       	call   102411 <cprintf>
	vcprintf(fmt, ap);
  100378:	8b 45 10             	mov    0x10(%ebp),%eax
  10037b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10037e:	89 54 24 04          	mov    %edx,0x4(%esp)
  100382:	89 04 24             	mov    %eax,(%esp)
  100385:	e8 1e 20 00 00       	call   1023a8 <vcprintf>
	cprintf("\n");
  10038a:	c7 04 24 c5 2b 10 00 	movl   $0x102bc5,(%esp)
  100391:	e8 7b 20 00 00       	call   102411 <cprintf>

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
  1003bf:	c7 04 24 c7 2b 10 00 	movl   $0x102bc7,(%esp)
  1003c6:	e8 46 20 00 00       	call   102411 <cprintf>
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
  100405:	c7 04 24 d4 2b 10 00 	movl   $0x102bd4,(%esp)
  10040c:	e8 00 20 00 00       	call   102411 <cprintf>
	vcprintf(fmt, ap);
  100411:	8b 45 10             	mov    0x10(%ebp),%eax
  100414:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100417:	89 54 24 04          	mov    %edx,0x4(%esp)
  10041b:	89 04 24             	mov    %eax,(%esp)
  10041e:	e8 85 1f 00 00       	call   1023a8 <vcprintf>
	cprintf("\n");
  100423:	c7 04 24 c5 2b 10 00 	movl   $0x102bc5,(%esp)
  10042a:	e8 e2 1f 00 00       	call   102411 <cprintf>
	va_end(ap);
}
  10042f:	c9                   	leave  
  100430:	c3                   	ret    

00100431 <debug_trace>:

// Riecord the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100431:	55                   	push   %ebp
  100432:	89 e5                	mov    %esp,%ebp
  100434:	83 ec 28             	sub    $0x28,%esp
	uint32_t* ebp_addr;
	uint32_t eip;

	ebp_addr = (uint32_t*) ebp;
  100437:	8b 45 08             	mov    0x8(%ebp),%eax
  10043a:	89 45 e8             	mov    %eax,-0x18(%ebp)

	int x = 0;
  10043d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	cprintf("Stack backtrace:\n");
  100444:	c7 04 24 ee 2b 10 00 	movl   $0x102bee,(%esp)
  10044b:	e8 c1 1f 00 00       	call   102411 <cprintf>

	while(*ebp_addr >= 0)
	{

		eip = ebp_addr[1];
  100450:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100453:	83 c0 04             	add    $0x4,%eax
  100456:	8b 00                	mov    (%eax),%eax
  100458:	89 45 ec             	mov    %eax,-0x14(%ebp)
		eips[x++] = eip;
  10045b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10045e:	c1 e0 02             	shl    $0x2,%eax
  100461:	03 45 0c             	add    0xc(%ebp),%eax
  100464:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100467:	89 10                	mov    %edx,(%eax)
  100469:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)

		cprintf("ebp 0x%08x eip 0x%08x", *ebp_addr, eip);
  10046d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100470:	8b 00                	mov    (%eax),%eax
  100472:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100475:	89 54 24 08          	mov    %edx,0x8(%esp)
  100479:	89 44 24 04          	mov    %eax,0x4(%esp)
  10047d:	c7 04 24 00 2c 10 00 	movl   $0x102c00,(%esp)
  100484:	e8 88 1f 00 00       	call   102411 <cprintf>

		int y = 0;
  100489:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

		cprintf(" args");
  100490:	c7 04 24 16 2c 10 00 	movl   $0x102c16,(%esp)
  100497:	e8 75 1f 00 00       	call   102411 <cprintf>

		for(; y < 5; y++)
  10049c:	eb 22                	jmp    1004c0 <debug_trace+0x8f>
		{
			cprintf(" %08x", ebp_addr[2 + y]);
  10049e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004a1:	83 c0 02             	add    $0x2,%eax
  1004a4:	c1 e0 02             	shl    $0x2,%eax
  1004a7:	03 45 e8             	add    -0x18(%ebp),%eax
  1004aa:	8b 00                	mov    (%eax),%eax
  1004ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004b0:	c7 04 24 1c 2c 10 00 	movl   $0x102c1c,(%esp)
  1004b7:	e8 55 1f 00 00       	call   102411 <cprintf>

		int y = 0;

		cprintf(" args");

		for(; y < 5; y++)
  1004bc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1004c0:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  1004c4:	7e d8                	jle    10049e <debug_trace+0x6d>
		{
			cprintf(" %08x", ebp_addr[2 + y]);
		}

		cprintf("\n");
  1004c6:	c7 04 24 c5 2b 10 00 	movl   $0x102bc5,(%esp)
  1004cd:	e8 3f 1f 00 00       	call   102411 <cprintf>

		if(*ebp_addr == 0)
  1004d2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1004d5:	8b 00                	mov    (%eax),%eax
  1004d7:	85 c0                	test   %eax,%eax
  1004d9:	75 1d                	jne    1004f8 <debug_trace+0xc7>
		{
			for(; x < 10; x++)
  1004db:	eb 13                	jmp    1004f0 <debug_trace+0xbf>
				eips[x] = 0;
  1004dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004e0:	c1 e0 02             	shl    $0x2,%eax
  1004e3:	03 45 0c             	add    0xc(%ebp),%eax
  1004e6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

		cprintf("\n");

		if(*ebp_addr == 0)
		{
			for(; x < 10; x++)
  1004ec:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1004f0:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  1004f4:	7e e7                	jle    1004dd <debug_trace+0xac>
  1004f6:	eb 0d                	jmp    100505 <debug_trace+0xd4>
				eips[x] = 0;
			break;
		}

		ebp_addr = (uint32_t*) (*ebp_addr);
  1004f8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1004fb:	8b 00                	mov    (%eax),%eax
  1004fd:	89 45 e8             	mov    %eax,-0x18(%ebp)
	}
  100500:	e9 4b ff ff ff       	jmp    100450 <debug_trace+0x1f>

	return;
	//panic("debug_trace not implemented");
}
  100505:	c9                   	leave  
  100506:	c3                   	ret    

00100507 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100507:	55                   	push   %ebp
  100508:	89 e5                	mov    %esp,%ebp
  10050a:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10050d:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  100510:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100513:	8b 55 0c             	mov    0xc(%ebp),%edx
  100516:	89 54 24 04          	mov    %edx,0x4(%esp)
  10051a:	89 04 24             	mov    %eax,(%esp)
  10051d:	e8 0f ff ff ff       	call   100431 <debug_trace>
  100522:	c9                   	leave  
  100523:	c3                   	ret    

00100524 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100524:	55                   	push   %ebp
  100525:	89 e5                	mov    %esp,%ebp
  100527:	83 ec 18             	sub    $0x18,%esp
  10052a:	8b 45 08             	mov    0x8(%ebp),%eax
  10052d:	83 e0 02             	and    $0x2,%eax
  100530:	85 c0                	test   %eax,%eax
  100532:	74 14                	je     100548 <f2+0x24>
  100534:	8b 45 0c             	mov    0xc(%ebp),%eax
  100537:	89 44 24 04          	mov    %eax,0x4(%esp)
  10053b:	8b 45 08             	mov    0x8(%ebp),%eax
  10053e:	89 04 24             	mov    %eax,(%esp)
  100541:	e8 c1 ff ff ff       	call   100507 <f3>
  100546:	eb 12                	jmp    10055a <f2+0x36>
  100548:	8b 45 0c             	mov    0xc(%ebp),%eax
  10054b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10054f:	8b 45 08             	mov    0x8(%ebp),%eax
  100552:	89 04 24             	mov    %eax,(%esp)
  100555:	e8 ad ff ff ff       	call   100507 <f3>
  10055a:	c9                   	leave  
  10055b:	c3                   	ret    

0010055c <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  10055c:	55                   	push   %ebp
  10055d:	89 e5                	mov    %esp,%ebp
  10055f:	83 ec 18             	sub    $0x18,%esp
  100562:	8b 45 08             	mov    0x8(%ebp),%eax
  100565:	83 e0 01             	and    $0x1,%eax
  100568:	84 c0                	test   %al,%al
  10056a:	74 14                	je     100580 <f1+0x24>
  10056c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10056f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100573:	8b 45 08             	mov    0x8(%ebp),%eax
  100576:	89 04 24             	mov    %eax,(%esp)
  100579:	e8 a6 ff ff ff       	call   100524 <f2>
  10057e:	eb 12                	jmp    100592 <f1+0x36>
  100580:	8b 45 0c             	mov    0xc(%ebp),%eax
  100583:	89 44 24 04          	mov    %eax,0x4(%esp)
  100587:	8b 45 08             	mov    0x8(%ebp),%eax
  10058a:	89 04 24             	mov    %eax,(%esp)
  10058d:	e8 92 ff ff ff       	call   100524 <f2>
  100592:	c9                   	leave  
  100593:	c3                   	ret    

00100594 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100594:	55                   	push   %ebp
  100595:	89 e5                	mov    %esp,%ebp
  100597:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  10059d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1005a4:	eb 29                	jmp    1005cf <debug_check+0x3b>
		f1(i, eips[i]);
  1005a6:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  1005ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1005af:	89 d0                	mov    %edx,%eax
  1005b1:	c1 e0 02             	shl    $0x2,%eax
  1005b4:	01 d0                	add    %edx,%eax
  1005b6:	c1 e0 03             	shl    $0x3,%eax
  1005b9:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  1005bc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1005c3:	89 04 24             	mov    %eax,(%esp)
  1005c6:	e8 91 ff ff ff       	call   10055c <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1005cb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1005cf:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  1005d3:	7e d1                	jle    1005a6 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1005d5:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1005dc:	e9 bc 00 00 00       	jmp    10069d <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1005e1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1005e8:	e9 a2 00 00 00       	jmp    10068f <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  1005ed:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1005f0:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  1005f3:	89 d0                	mov    %edx,%eax
  1005f5:	c1 e0 02             	shl    $0x2,%eax
  1005f8:	01 d0                	add    %edx,%eax
  1005fa:	01 c0                	add    %eax,%eax
  1005fc:	01 c8                	add    %ecx,%eax
  1005fe:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100605:	85 c0                	test   %eax,%eax
  100607:	0f 95 c2             	setne  %dl
  10060a:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  10060e:	0f 9e c0             	setle  %al
  100611:	31 d0                	xor    %edx,%eax
  100613:	84 c0                	test   %al,%al
  100615:	74 24                	je     10063b <debug_check+0xa7>
  100617:	c7 44 24 0c 22 2c 10 	movl   $0x102c22,0xc(%esp)
  10061e:	00 
  10061f:	c7 44 24 08 3f 2c 10 	movl   $0x102c3f,0x8(%esp)
  100626:	00 
  100627:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
  10062e:	00 
  10062f:	c7 04 24 54 2c 10 00 	movl   $0x102c54,(%esp)
  100636:	e8 ee fc ff ff       	call   100329 <debug_panic>
			if (i >= 2)
  10063b:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  10063f:	7e 4a                	jle    10068b <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  100641:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100644:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100647:	89 d0                	mov    %edx,%eax
  100649:	c1 e0 02             	shl    $0x2,%eax
  10064c:	01 d0                	add    %edx,%eax
  10064e:	01 c0                	add    %eax,%eax
  100650:	01 c8                	add    %ecx,%eax
  100652:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  100659:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10065c:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100663:	39 c2                	cmp    %eax,%edx
  100665:	74 24                	je     10068b <debug_check+0xf7>
  100667:	c7 44 24 0c 61 2c 10 	movl   $0x102c61,0xc(%esp)
  10066e:	00 
  10066f:	c7 44 24 08 3f 2c 10 	movl   $0x102c3f,0x8(%esp)
  100676:	00 
  100677:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  10067e:	00 
  10067f:	c7 04 24 54 2c 10 00 	movl   $0x102c54,(%esp)
  100686:	e8 9e fc ff ff       	call   100329 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  10068b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10068f:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100693:	0f 8e 54 ff ff ff    	jle    1005ed <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100699:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10069d:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  1006a1:	0f 8e 3a ff ff ff    	jle    1005e1 <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  1006a7:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  1006ad:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  1006b3:	39 c2                	cmp    %eax,%edx
  1006b5:	74 24                	je     1006db <debug_check+0x147>
  1006b7:	c7 44 24 0c 7a 2c 10 	movl   $0x102c7a,0xc(%esp)
  1006be:	00 
  1006bf:	c7 44 24 08 3f 2c 10 	movl   $0x102c3f,0x8(%esp)
  1006c6:	00 
  1006c7:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
  1006ce:	00 
  1006cf:	c7 04 24 54 2c 10 00 	movl   $0x102c54,(%esp)
  1006d6:	e8 4e fc ff ff       	call   100329 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1006db:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1006de:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1006e1:	39 c2                	cmp    %eax,%edx
  1006e3:	74 24                	je     100709 <debug_check+0x175>
  1006e5:	c7 44 24 0c 93 2c 10 	movl   $0x102c93,0xc(%esp)
  1006ec:	00 
  1006ed:	c7 44 24 08 3f 2c 10 	movl   $0x102c3f,0x8(%esp)
  1006f4:	00 
  1006f5:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  1006fc:	00 
  1006fd:	c7 04 24 54 2c 10 00 	movl   $0x102c54,(%esp)
  100704:	e8 20 fc ff ff       	call   100329 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100709:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  10070f:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100712:	39 c2                	cmp    %eax,%edx
  100714:	75 24                	jne    10073a <debug_check+0x1a6>
  100716:	c7 44 24 0c ac 2c 10 	movl   $0x102cac,0xc(%esp)
  10071d:	00 
  10071e:	c7 44 24 08 3f 2c 10 	movl   $0x102c3f,0x8(%esp)
  100725:	00 
  100726:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  10072d:	00 
  10072e:	c7 04 24 54 2c 10 00 	movl   $0x102c54,(%esp)
  100735:	e8 ef fb ff ff       	call   100329 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10073a:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100740:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100743:	39 c2                	cmp    %eax,%edx
  100745:	74 24                	je     10076b <debug_check+0x1d7>
  100747:	c7 44 24 0c c5 2c 10 	movl   $0x102cc5,0xc(%esp)
  10074e:	00 
  10074f:	c7 44 24 08 3f 2c 10 	movl   $0x102c3f,0x8(%esp)
  100756:	00 
  100757:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  10075e:	00 
  10075f:	c7 04 24 54 2c 10 00 	movl   $0x102c54,(%esp)
  100766:	e8 be fb ff ff       	call   100329 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10076b:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100771:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100774:	39 c2                	cmp    %eax,%edx
  100776:	74 24                	je     10079c <debug_check+0x208>
  100778:	c7 44 24 0c de 2c 10 	movl   $0x102cde,0xc(%esp)
  10077f:	00 
  100780:	c7 44 24 08 3f 2c 10 	movl   $0x102c3f,0x8(%esp)
  100787:	00 
  100788:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  10078f:	00 
  100790:	c7 04 24 54 2c 10 00 	movl   $0x102c54,(%esp)
  100797:	e8 8d fb ff ff       	call   100329 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10079c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1007a2:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1007a8:	39 c2                	cmp    %eax,%edx
  1007aa:	75 24                	jne    1007d0 <debug_check+0x23c>
  1007ac:	c7 44 24 0c f7 2c 10 	movl   $0x102cf7,0xc(%esp)
  1007b3:	00 
  1007b4:	c7 44 24 08 3f 2c 10 	movl   $0x102c3f,0x8(%esp)
  1007bb:	00 
  1007bc:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  1007c3:	00 
  1007c4:	c7 04 24 54 2c 10 00 	movl   $0x102c54,(%esp)
  1007cb:	e8 59 fb ff ff       	call   100329 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1007d0:	c7 04 24 10 2d 10 00 	movl   $0x102d10,(%esp)
  1007d7:	e8 35 1c 00 00       	call   102411 <cprintf>
}
  1007dc:	c9                   	leave  
  1007dd:	c3                   	ret    

001007de <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1007de:	55                   	push   %ebp
  1007df:	89 e5                	mov    %esp,%ebp
  1007e1:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1007e4:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1007e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1007ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1007ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1007f0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1007f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1007f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1007fb:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100801:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100806:	74 24                	je     10082c <cpu_cur+0x4e>
  100808:	c7 44 24 0c 2c 2d 10 	movl   $0x102d2c,0xc(%esp)
  10080f:	00 
  100810:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100817:	00 
  100818:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10081f:	00 
  100820:	c7 04 24 57 2d 10 00 	movl   $0x102d57,(%esp)
  100827:	e8 fd fa ff ff       	call   100329 <debug_panic>
	return c;
  10082c:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10082f:	c9                   	leave  
  100830:	c3                   	ret    

00100831 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100831:	55                   	push   %ebp
  100832:	89 e5                	mov    %esp,%ebp
  100834:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100837:	e8 a2 ff ff ff       	call   1007de <cpu_cur>
  10083c:	3d 00 50 10 00       	cmp    $0x105000,%eax
  100841:	0f 94 c0             	sete   %al
  100844:	0f b6 c0             	movzbl %al,%eax
}
  100847:	c9                   	leave  
  100848:	c3                   	ret    

00100849 <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  100849:	55                   	push   %ebp
  10084a:	89 e5                	mov    %esp,%ebp
  10084c:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10084f:	e8 dd ff ff ff       	call   100831 <cpu_onboot>
  100854:	85 c0                	test   %eax,%eax
  100856:	0f 84 2d 01 00 00    	je     100989 <mem_init+0x140>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  10085c:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100863:	e8 c3 13 00 00       	call   101c2b <nvram_read16>
  100868:	c1 e0 0a             	shl    $0xa,%eax
  10086b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10086e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100871:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100876:	89 45 e0             	mov    %eax,-0x20(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100879:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100880:	e8 a6 13 00 00       	call   101c2b <nvram_read16>
  100885:	c1 e0 0a             	shl    $0xa,%eax
  100888:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10088b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10088e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100893:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	warn("Assuming we have 1GB of memory!");
  100896:	c7 44 24 08 64 2d 10 	movl   $0x102d64,0x8(%esp)
  10089d:	00 
  10089e:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  1008a5:	00 
  1008a6:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  1008ad:	e8 36 fb ff ff       	call   1003e8 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1008b2:	c7 45 e4 00 00 f0 3f 	movl   $0x3ff00000,-0x1c(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1008b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1008bc:	05 00 00 10 00       	add    $0x100000,%eax
  1008c1:	a3 78 7f 10 00       	mov    %eax,0x107f78

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1008c6:	a1 78 7f 10 00       	mov    0x107f78,%eax
  1008cb:	c1 e8 0c             	shr    $0xc,%eax
  1008ce:	a3 74 7f 10 00       	mov    %eax,0x107f74

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  1008d3:	a1 78 7f 10 00       	mov    0x107f78,%eax
  1008d8:	c1 e8 0a             	shr    $0xa,%eax
  1008db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1008df:	c7 04 24 90 2d 10 00 	movl   $0x102d90,(%esp)
  1008e6:	e8 26 1b 00 00       	call   102411 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  1008eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1008ee:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  1008f1:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  1008f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1008f6:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  1008f9:	89 54 24 08          	mov    %edx,0x8(%esp)
  1008fd:	89 44 24 04          	mov    %eax,0x4(%esp)
  100901:	c7 04 24 b1 2d 10 00 	movl   $0x102db1,(%esp)
  100908:	e8 04 1b 00 00       	call   102411 <cprintf>
	//     Some of it is in use, some is free.
	//     Which pages hold the kernel and the pageinfo array?
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
  10090d:	c7 45 e8 70 7f 10 00 	movl   $0x107f70,-0x18(%ebp)
	int i;
	for (i = 0; i < mem_npage; i++) {
  100914:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  10091b:	eb 3b                	jmp    100958 <mem_init+0x10f>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  10091d:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100922:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100925:	c1 e2 03             	shl    $0x3,%edx
  100928:	01 d0                	add    %edx,%eax
  10092a:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100931:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100936:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100939:	c1 e2 03             	shl    $0x3,%edx
  10093c:	8d 14 10             	lea    (%eax,%edx,1),%edx
  10093f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100942:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100944:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100949:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10094c:	c1 e2 03             	shl    $0x3,%edx
  10094f:	01 d0                	add    %edx,%eax
  100951:	89 45 e8             	mov    %eax,-0x18(%ebp)
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
	int i;
	for (i = 0; i < mem_npage; i++) {
  100954:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100958:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10095b:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100960:	39 c2                	cmp    %eax,%edx
  100962:	72 b9                	jb     10091d <mem_init+0xd4>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100964:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100967:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	panic("mem_init() not implemented");
  10096d:	c7 44 24 08 cd 2d 10 	movl   $0x102dcd,0x8(%esp)
  100974:	00 
  100975:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  10097c:	00 
  10097d:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100984:	e8 a0 f9 ff ff       	call   100329 <debug_panic>

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100989:	c9                   	leave  
  10098a:	c3                   	ret    

0010098b <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  10098b:	55                   	push   %ebp
  10098c:	89 e5                	mov    %esp,%ebp
  10098e:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	// Fill this function in.
	panic("mem_alloc not implemented.");
  100991:	c7 44 24 08 e8 2d 10 	movl   $0x102de8,0x8(%esp)
  100998:	00 
  100999:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  1009a0:	00 
  1009a1:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  1009a8:	e8 7c f9 ff ff       	call   100329 <debug_panic>

001009ad <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  1009ad:	55                   	push   %ebp
  1009ae:	89 e5                	mov    %esp,%ebp
  1009b0:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	panic("mem_free not implemented.");
  1009b3:	c7 44 24 08 03 2e 10 	movl   $0x102e03,0x8(%esp)
  1009ba:	00 
  1009bb:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  1009c2:	00 
  1009c3:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  1009ca:	e8 5a f9 ff ff       	call   100329 <debug_panic>

001009cf <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  1009cf:	55                   	push   %ebp
  1009d0:	89 e5                	mov    %esp,%ebp
  1009d2:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  1009d5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  1009dc:	a1 70 7f 10 00       	mov    0x107f70,%eax
  1009e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1009e4:	eb 38                	jmp    100a1e <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  1009e6:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1009e9:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  1009ee:	89 d1                	mov    %edx,%ecx
  1009f0:	29 c1                	sub    %eax,%ecx
  1009f2:	89 c8                	mov    %ecx,%eax
  1009f4:	c1 f8 03             	sar    $0x3,%eax
  1009f7:	c1 e0 0c             	shl    $0xc,%eax
  1009fa:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100a01:	00 
  100a02:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100a09:	00 
  100a0a:	89 04 24             	mov    %eax,(%esp)
  100a0d:	e8 e4 1b 00 00       	call   1025f6 <memset>
		freepages++;
  100a12:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100a16:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100a19:	8b 00                	mov    (%eax),%eax
  100a1b:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100a1e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  100a22:	75 c2                	jne    1009e6 <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100a24:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a27:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a2b:	c7 04 24 1d 2e 10 00 	movl   $0x102e1d,(%esp)
  100a32:	e8 da 19 00 00       	call   102411 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100a37:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100a3a:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100a3f:	39 c2                	cmp    %eax,%edx
  100a41:	72 24                	jb     100a67 <mem_check+0x98>
  100a43:	c7 44 24 0c 37 2e 10 	movl   $0x102e37,0xc(%esp)
  100a4a:	00 
  100a4b:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100a52:	00 
  100a53:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100a5a:	00 
  100a5b:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100a62:	e8 c2 f8 ff ff       	call   100329 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100a67:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100a6e:	7f 24                	jg     100a94 <mem_check+0xc5>
  100a70:	c7 44 24 0c 4d 2e 10 	movl   $0x102e4d,0xc(%esp)
  100a77:	00 
  100a78:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100a7f:	00 
  100a80:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
  100a87:	00 
  100a88:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100a8f:	e8 95 f8 ff ff       	call   100329 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100a94:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100a9b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100a9e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100aa1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100aa4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100aa7:	e8 df fe ff ff       	call   10098b <mem_alloc>
  100aac:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100aaf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100ab3:	75 24                	jne    100ad9 <mem_check+0x10a>
  100ab5:	c7 44 24 0c 5f 2e 10 	movl   $0x102e5f,0xc(%esp)
  100abc:	00 
  100abd:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100ac4:	00 
  100ac5:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  100acc:	00 
  100acd:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100ad4:	e8 50 f8 ff ff       	call   100329 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100ad9:	e8 ad fe ff ff       	call   10098b <mem_alloc>
  100ade:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100ae1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100ae5:	75 24                	jne    100b0b <mem_check+0x13c>
  100ae7:	c7 44 24 0c 68 2e 10 	movl   $0x102e68,0xc(%esp)
  100aee:	00 
  100aef:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100af6:	00 
  100af7:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100afe:	00 
  100aff:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100b06:	e8 1e f8 ff ff       	call   100329 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100b0b:	e8 7b fe ff ff       	call   10098b <mem_alloc>
  100b10:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100b13:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100b17:	75 24                	jne    100b3d <mem_check+0x16e>
  100b19:	c7 44 24 0c 71 2e 10 	movl   $0x102e71,0xc(%esp)
  100b20:	00 
  100b21:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100b28:	00 
  100b29:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  100b30:	00 
  100b31:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100b38:	e8 ec f7 ff ff       	call   100329 <debug_panic>

	assert(pp0);
  100b3d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100b41:	75 24                	jne    100b67 <mem_check+0x198>
  100b43:	c7 44 24 0c 7a 2e 10 	movl   $0x102e7a,0xc(%esp)
  100b4a:	00 
  100b4b:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100b52:	00 
  100b53:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  100b5a:	00 
  100b5b:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100b62:	e8 c2 f7 ff ff       	call   100329 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100b67:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100b6b:	74 08                	je     100b75 <mem_check+0x1a6>
  100b6d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100b70:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100b73:	75 24                	jne    100b99 <mem_check+0x1ca>
  100b75:	c7 44 24 0c 7e 2e 10 	movl   $0x102e7e,0xc(%esp)
  100b7c:	00 
  100b7d:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100b84:	00 
  100b85:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100b8c:	00 
  100b8d:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100b94:	e8 90 f7 ff ff       	call   100329 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100b99:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100b9d:	74 10                	je     100baf <mem_check+0x1e0>
  100b9f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ba2:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100ba5:	74 08                	je     100baf <mem_check+0x1e0>
  100ba7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100baa:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100bad:	75 24                	jne    100bd3 <mem_check+0x204>
  100baf:	c7 44 24 0c 90 2e 10 	movl   $0x102e90,0xc(%esp)
  100bb6:	00 
  100bb7:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100bbe:	00 
  100bbf:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  100bc6:	00 
  100bc7:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100bce:	e8 56 f7 ff ff       	call   100329 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100bd3:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100bd6:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100bdb:	89 d1                	mov    %edx,%ecx
  100bdd:	29 c1                	sub    %eax,%ecx
  100bdf:	89 c8                	mov    %ecx,%eax
  100be1:	c1 f8 03             	sar    $0x3,%eax
  100be4:	c1 e0 0c             	shl    $0xc,%eax
  100be7:	8b 15 74 7f 10 00    	mov    0x107f74,%edx
  100bed:	c1 e2 0c             	shl    $0xc,%edx
  100bf0:	39 d0                	cmp    %edx,%eax
  100bf2:	72 24                	jb     100c18 <mem_check+0x249>
  100bf4:	c7 44 24 0c b0 2e 10 	movl   $0x102eb0,0xc(%esp)
  100bfb:	00 
  100bfc:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100c03:	00 
  100c04:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100c0b:	00 
  100c0c:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100c13:	e8 11 f7 ff ff       	call   100329 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100c18:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100c1b:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100c20:	89 d1                	mov    %edx,%ecx
  100c22:	29 c1                	sub    %eax,%ecx
  100c24:	89 c8                	mov    %ecx,%eax
  100c26:	c1 f8 03             	sar    $0x3,%eax
  100c29:	c1 e0 0c             	shl    $0xc,%eax
  100c2c:	8b 15 74 7f 10 00    	mov    0x107f74,%edx
  100c32:	c1 e2 0c             	shl    $0xc,%edx
  100c35:	39 d0                	cmp    %edx,%eax
  100c37:	72 24                	jb     100c5d <mem_check+0x28e>
  100c39:	c7 44 24 0c d8 2e 10 	movl   $0x102ed8,0xc(%esp)
  100c40:	00 
  100c41:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100c48:	00 
  100c49:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100c50:	00 
  100c51:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100c58:	e8 cc f6 ff ff       	call   100329 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100c5d:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100c60:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100c65:	89 d1                	mov    %edx,%ecx
  100c67:	29 c1                	sub    %eax,%ecx
  100c69:	89 c8                	mov    %ecx,%eax
  100c6b:	c1 f8 03             	sar    $0x3,%eax
  100c6e:	c1 e0 0c             	shl    $0xc,%eax
  100c71:	8b 15 74 7f 10 00    	mov    0x107f74,%edx
  100c77:	c1 e2 0c             	shl    $0xc,%edx
  100c7a:	39 d0                	cmp    %edx,%eax
  100c7c:	72 24                	jb     100ca2 <mem_check+0x2d3>
  100c7e:	c7 44 24 0c 00 2f 10 	movl   $0x102f00,0xc(%esp)
  100c85:	00 
  100c86:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100c8d:	00 
  100c8e:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100c95:	00 
  100c96:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100c9d:	e8 87 f6 ff ff       	call   100329 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100ca2:	a1 70 7f 10 00       	mov    0x107f70,%eax
  100ca7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100caa:	c7 05 70 7f 10 00 00 	movl   $0x0,0x107f70
  100cb1:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100cb4:	e8 d2 fc ff ff       	call   10098b <mem_alloc>
  100cb9:	85 c0                	test   %eax,%eax
  100cbb:	74 24                	je     100ce1 <mem_check+0x312>
  100cbd:	c7 44 24 0c 26 2f 10 	movl   $0x102f26,0xc(%esp)
  100cc4:	00 
  100cc5:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100ccc:	00 
  100ccd:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  100cd4:	00 
  100cd5:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100cdc:	e8 48 f6 ff ff       	call   100329 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100ce1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100ce4:	89 04 24             	mov    %eax,(%esp)
  100ce7:	e8 c1 fc ff ff       	call   1009ad <mem_free>
        mem_free(pp1);
  100cec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100cef:	89 04 24             	mov    %eax,(%esp)
  100cf2:	e8 b6 fc ff ff       	call   1009ad <mem_free>
        mem_free(pp2);
  100cf7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100cfa:	89 04 24             	mov    %eax,(%esp)
  100cfd:	e8 ab fc ff ff       	call   1009ad <mem_free>
	pp0 = pp1 = pp2 = 0;
  100d02:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100d09:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d0c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d0f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d12:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100d15:	e8 71 fc ff ff       	call   10098b <mem_alloc>
  100d1a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100d1d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100d21:	75 24                	jne    100d47 <mem_check+0x378>
  100d23:	c7 44 24 0c 5f 2e 10 	movl   $0x102e5f,0xc(%esp)
  100d2a:	00 
  100d2b:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100d32:	00 
  100d33:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  100d3a:	00 
  100d3b:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100d42:	e8 e2 f5 ff ff       	call   100329 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100d47:	e8 3f fc ff ff       	call   10098b <mem_alloc>
  100d4c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d4f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d53:	75 24                	jne    100d79 <mem_check+0x3aa>
  100d55:	c7 44 24 0c 68 2e 10 	movl   $0x102e68,0xc(%esp)
  100d5c:	00 
  100d5d:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100d64:	00 
  100d65:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  100d6c:	00 
  100d6d:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100d74:	e8 b0 f5 ff ff       	call   100329 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100d79:	e8 0d fc ff ff       	call   10098b <mem_alloc>
  100d7e:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100d81:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d85:	75 24                	jne    100dab <mem_check+0x3dc>
  100d87:	c7 44 24 0c 71 2e 10 	movl   $0x102e71,0xc(%esp)
  100d8e:	00 
  100d8f:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100d96:	00 
  100d97:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  100d9e:	00 
  100d9f:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100da6:	e8 7e f5 ff ff       	call   100329 <debug_panic>
	assert(pp0);
  100dab:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100daf:	75 24                	jne    100dd5 <mem_check+0x406>
  100db1:	c7 44 24 0c 7a 2e 10 	movl   $0x102e7a,0xc(%esp)
  100db8:	00 
  100db9:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100dc0:	00 
  100dc1:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
  100dc8:	00 
  100dc9:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100dd0:	e8 54 f5 ff ff       	call   100329 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100dd5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100dd9:	74 08                	je     100de3 <mem_check+0x414>
  100ddb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100dde:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100de1:	75 24                	jne    100e07 <mem_check+0x438>
  100de3:	c7 44 24 0c 7e 2e 10 	movl   $0x102e7e,0xc(%esp)
  100dea:	00 
  100deb:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100df2:	00 
  100df3:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  100dfa:	00 
  100dfb:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100e02:	e8 22 f5 ff ff       	call   100329 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100e07:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100e0b:	74 10                	je     100e1d <mem_check+0x44e>
  100e0d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e10:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100e13:	74 08                	je     100e1d <mem_check+0x44e>
  100e15:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e18:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100e1b:	75 24                	jne    100e41 <mem_check+0x472>
  100e1d:	c7 44 24 0c 90 2e 10 	movl   $0x102e90,0xc(%esp)
  100e24:	00 
  100e25:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100e2c:	00 
  100e2d:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  100e34:	00 
  100e35:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100e3c:	e8 e8 f4 ff ff       	call   100329 <debug_panic>
	assert(mem_alloc() == 0);
  100e41:	e8 45 fb ff ff       	call   10098b <mem_alloc>
  100e46:	85 c0                	test   %eax,%eax
  100e48:	74 24                	je     100e6e <mem_check+0x49f>
  100e4a:	c7 44 24 0c 26 2f 10 	movl   $0x102f26,0xc(%esp)
  100e51:	00 
  100e52:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  100e59:	00 
  100e5a:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  100e61:	00 
  100e62:	c7 04 24 84 2d 10 00 	movl   $0x102d84,(%esp)
  100e69:	e8 bb f4 ff ff       	call   100329 <debug_panic>

	// give free list back
	mem_freelist = fl;
  100e6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e71:	a3 70 7f 10 00       	mov    %eax,0x107f70

	// free the pages we took
	mem_free(pp0);
  100e76:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100e79:	89 04 24             	mov    %eax,(%esp)
  100e7c:	e8 2c fb ff ff       	call   1009ad <mem_free>
	mem_free(pp1);
  100e81:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100e84:	89 04 24             	mov    %eax,(%esp)
  100e87:	e8 21 fb ff ff       	call   1009ad <mem_free>
	mem_free(pp2);
  100e8c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e8f:	89 04 24             	mov    %eax,(%esp)
  100e92:	e8 16 fb ff ff       	call   1009ad <mem_free>

	cprintf("mem_check() succeeded!\n");
  100e97:	c7 04 24 37 2f 10 00 	movl   $0x102f37,(%esp)
  100e9e:	e8 6e 15 00 00       	call   102411 <cprintf>
}
  100ea3:	c9                   	leave  
  100ea4:	c3                   	ret    

00100ea5 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100ea5:	55                   	push   %ebp
  100ea6:	89 e5                	mov    %esp,%ebp
  100ea8:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100eab:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100eae:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100eb1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100eb4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100eb7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100ebc:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100ebf:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100ec2:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100ec8:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100ecd:	74 24                	je     100ef3 <cpu_cur+0x4e>
  100ecf:	c7 44 24 0c 4f 2f 10 	movl   $0x102f4f,0xc(%esp)
  100ed6:	00 
  100ed7:	c7 44 24 08 65 2f 10 	movl   $0x102f65,0x8(%esp)
  100ede:	00 
  100edf:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100ee6:	00 
  100ee7:	c7 04 24 7a 2f 10 00 	movl   $0x102f7a,(%esp)
  100eee:	e8 36 f4 ff ff       	call   100329 <debug_panic>
	return c;
  100ef3:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100ef6:	c9                   	leave  
  100ef7:	c3                   	ret    

00100ef8 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  100ef8:	55                   	push   %ebp
  100ef9:	89 e5                	mov    %esp,%ebp
  100efb:	83 ec 18             	sub    $0x18,%esp
	cpu *c = cpu_cur();
  100efe:	e8 a2 ff ff ff       	call   100ea5 <cpu_cur>
  100f03:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  100f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f09:	66 c7 45 ee 37 00    	movw   $0x37,-0x12(%ebp)
  100f0f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  100f12:	0f 01 55 ee          	lgdtl  -0x12(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  100f16:	b8 23 00 00 00       	mov    $0x23,%eax
  100f1b:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  100f1d:	b8 23 00 00 00       	mov    $0x23,%eax
  100f22:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  100f24:	b8 10 00 00 00       	mov    $0x10,%eax
  100f29:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  100f2b:	b8 10 00 00 00       	mov    $0x10,%eax
  100f30:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  100f32:	b8 10 00 00 00       	mov    $0x10,%eax
  100f37:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  100f39:	ea 40 0f 10 00 08 00 	ljmp   $0x8,$0x100f40

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  100f40:	b8 00 00 00 00       	mov    $0x0,%eax
  100f45:	0f 00 d0             	lldt   %ax
}
  100f48:	c9                   	leave  
  100f49:	c3                   	ret    

00100f4a <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100f4a:	55                   	push   %ebp
  100f4b:	89 e5                	mov    %esp,%ebp
  100f4d:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100f50:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100f53:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100f56:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100f59:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f5c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100f61:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100f64:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100f67:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100f6d:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100f72:	74 24                	je     100f98 <cpu_cur+0x4e>
  100f74:	c7 44 24 0c a0 2f 10 	movl   $0x102fa0,0xc(%esp)
  100f7b:	00 
  100f7c:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  100f83:	00 
  100f84:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100f8b:	00 
  100f8c:	c7 04 24 cb 2f 10 00 	movl   $0x102fcb,(%esp)
  100f93:	e8 91 f3 ff ff       	call   100329 <debug_panic>
	return c;
  100f98:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100f9b:	c9                   	leave  
  100f9c:	c3                   	ret    

00100f9d <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100f9d:	55                   	push   %ebp
  100f9e:	89 e5                	mov    %esp,%ebp
  100fa0:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100fa3:	e8 a2 ff ff ff       	call   100f4a <cpu_cur>
  100fa8:	3d 00 50 10 00       	cmp    $0x105000,%eax
  100fad:	0f 94 c0             	sete   %al
  100fb0:	0f b6 c0             	movzbl %al,%eax
}
  100fb3:	c9                   	leave  
  100fb4:	c3                   	ret    

00100fb5 <trap_init_idt>:
};


static void
trap_init_idt(void)
{
  100fb5:	55                   	push   %ebp
  100fb6:	89 e5                	mov    %esp,%ebp
  100fb8:	83 ec 18             	sub    $0x18,%esp
	extern segdesc gdt[];
	
	panic("trap_init() not implemented.");
  100fbb:	c7 44 24 08 d8 2f 10 	movl   $0x102fd8,0x8(%esp)
  100fc2:	00 
  100fc3:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  100fca:	00 
  100fcb:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  100fd2:	e8 52 f3 ff ff       	call   100329 <debug_panic>

00100fd7 <trap_init>:
}

void
trap_init(void)
{
  100fd7:	55                   	push   %ebp
  100fd8:	89 e5                	mov    %esp,%ebp
  100fda:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  100fdd:	e8 bb ff ff ff       	call   100f9d <cpu_onboot>
  100fe2:	85 c0                	test   %eax,%eax
  100fe4:	74 05                	je     100feb <trap_init+0x14>
		trap_init_idt();
  100fe6:	e8 ca ff ff ff       	call   100fb5 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  100feb:	0f 01 1d 00 60 10 00 	lidtl  0x106000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  100ff2:	e8 a6 ff ff ff       	call   100f9d <cpu_onboot>
  100ff7:	85 c0                	test   %eax,%eax
  100ff9:	74 05                	je     101000 <trap_init+0x29>
		trap_check_kernel();
  100ffb:	e8 62 02 00 00       	call   101262 <trap_check_kernel>
}
  101000:	c9                   	leave  
  101001:	c3                   	ret    

00101002 <trap_name>:

const char *trap_name(int trapno)
{
  101002:	55                   	push   %ebp
  101003:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101005:	8b 45 08             	mov    0x8(%ebp),%eax
  101008:	83 f8 13             	cmp    $0x13,%eax
  10100b:	77 0c                	ja     101019 <trap_name+0x17>
		return excnames[trapno];
  10100d:	8b 45 08             	mov    0x8(%ebp),%eax
  101010:	8b 04 85 a0 33 10 00 	mov    0x1033a0(,%eax,4),%eax
  101017:	eb 05                	jmp    10101e <trap_name+0x1c>
	return "(unknown trap)";
  101019:	b8 01 30 10 00       	mov    $0x103001,%eax
}
  10101e:	5d                   	pop    %ebp
  10101f:	c3                   	ret    

00101020 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101020:	55                   	push   %ebp
  101021:	89 e5                	mov    %esp,%ebp
  101023:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  101026:	8b 45 08             	mov    0x8(%ebp),%eax
  101029:	8b 00                	mov    (%eax),%eax
  10102b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10102f:	c7 04 24 10 30 10 00 	movl   $0x103010,(%esp)
  101036:	e8 d6 13 00 00       	call   102411 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  10103b:	8b 45 08             	mov    0x8(%ebp),%eax
  10103e:	8b 40 04             	mov    0x4(%eax),%eax
  101041:	89 44 24 04          	mov    %eax,0x4(%esp)
  101045:	c7 04 24 1f 30 10 00 	movl   $0x10301f,(%esp)
  10104c:	e8 c0 13 00 00       	call   102411 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101051:	8b 45 08             	mov    0x8(%ebp),%eax
  101054:	8b 40 08             	mov    0x8(%eax),%eax
  101057:	89 44 24 04          	mov    %eax,0x4(%esp)
  10105b:	c7 04 24 2e 30 10 00 	movl   $0x10302e,(%esp)
  101062:	e8 aa 13 00 00       	call   102411 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  101067:	8b 45 08             	mov    0x8(%ebp),%eax
  10106a:	8b 40 10             	mov    0x10(%eax),%eax
  10106d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101071:	c7 04 24 3d 30 10 00 	movl   $0x10303d,(%esp)
  101078:	e8 94 13 00 00       	call   102411 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  10107d:	8b 45 08             	mov    0x8(%ebp),%eax
  101080:	8b 40 14             	mov    0x14(%eax),%eax
  101083:	89 44 24 04          	mov    %eax,0x4(%esp)
  101087:	c7 04 24 4c 30 10 00 	movl   $0x10304c,(%esp)
  10108e:	e8 7e 13 00 00       	call   102411 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101093:	8b 45 08             	mov    0x8(%ebp),%eax
  101096:	8b 40 18             	mov    0x18(%eax),%eax
  101099:	89 44 24 04          	mov    %eax,0x4(%esp)
  10109d:	c7 04 24 5b 30 10 00 	movl   $0x10305b,(%esp)
  1010a4:	e8 68 13 00 00       	call   102411 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1010a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1010ac:	8b 40 1c             	mov    0x1c(%eax),%eax
  1010af:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010b3:	c7 04 24 6a 30 10 00 	movl   $0x10306a,(%esp)
  1010ba:	e8 52 13 00 00       	call   102411 <cprintf>
}
  1010bf:	c9                   	leave  
  1010c0:	c3                   	ret    

001010c1 <trap_print>:

void
trap_print(trapframe *tf)
{
  1010c1:	55                   	push   %ebp
  1010c2:	89 e5                	mov    %esp,%ebp
  1010c4:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  1010c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1010ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010ce:	c7 04 24 79 30 10 00 	movl   $0x103079,(%esp)
  1010d5:	e8 37 13 00 00       	call   102411 <cprintf>
	trap_print_regs(&tf->regs);
  1010da:	8b 45 08             	mov    0x8(%ebp),%eax
  1010dd:	89 04 24             	mov    %eax,(%esp)
  1010e0:	e8 3b ff ff ff       	call   101020 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  1010e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1010e8:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  1010ec:	0f b7 c0             	movzwl %ax,%eax
  1010ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010f3:	c7 04 24 8b 30 10 00 	movl   $0x10308b,(%esp)
  1010fa:	e8 12 13 00 00       	call   102411 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  1010ff:	8b 45 08             	mov    0x8(%ebp),%eax
  101102:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101106:	0f b7 c0             	movzwl %ax,%eax
  101109:	89 44 24 04          	mov    %eax,0x4(%esp)
  10110d:	c7 04 24 9e 30 10 00 	movl   $0x10309e,(%esp)
  101114:	e8 f8 12 00 00       	call   102411 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101119:	8b 45 08             	mov    0x8(%ebp),%eax
  10111c:	8b 40 30             	mov    0x30(%eax),%eax
  10111f:	89 04 24             	mov    %eax,(%esp)
  101122:	e8 db fe ff ff       	call   101002 <trap_name>
  101127:	8b 55 08             	mov    0x8(%ebp),%edx
  10112a:	8b 52 30             	mov    0x30(%edx),%edx
  10112d:	89 44 24 08          	mov    %eax,0x8(%esp)
  101131:	89 54 24 04          	mov    %edx,0x4(%esp)
  101135:	c7 04 24 b1 30 10 00 	movl   $0x1030b1,(%esp)
  10113c:	e8 d0 12 00 00       	call   102411 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101141:	8b 45 08             	mov    0x8(%ebp),%eax
  101144:	8b 40 34             	mov    0x34(%eax),%eax
  101147:	89 44 24 04          	mov    %eax,0x4(%esp)
  10114b:	c7 04 24 c3 30 10 00 	movl   $0x1030c3,(%esp)
  101152:	e8 ba 12 00 00       	call   102411 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  101157:	8b 45 08             	mov    0x8(%ebp),%eax
  10115a:	8b 40 38             	mov    0x38(%eax),%eax
  10115d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101161:	c7 04 24 d2 30 10 00 	movl   $0x1030d2,(%esp)
  101168:	e8 a4 12 00 00       	call   102411 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  10116d:	8b 45 08             	mov    0x8(%ebp),%eax
  101170:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101174:	0f b7 c0             	movzwl %ax,%eax
  101177:	89 44 24 04          	mov    %eax,0x4(%esp)
  10117b:	c7 04 24 e1 30 10 00 	movl   $0x1030e1,(%esp)
  101182:	e8 8a 12 00 00       	call   102411 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  101187:	8b 45 08             	mov    0x8(%ebp),%eax
  10118a:	8b 40 40             	mov    0x40(%eax),%eax
  10118d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101191:	c7 04 24 f4 30 10 00 	movl   $0x1030f4,(%esp)
  101198:	e8 74 12 00 00       	call   102411 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  10119d:	8b 45 08             	mov    0x8(%ebp),%eax
  1011a0:	8b 40 44             	mov    0x44(%eax),%eax
  1011a3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011a7:	c7 04 24 03 31 10 00 	movl   $0x103103,(%esp)
  1011ae:	e8 5e 12 00 00       	call   102411 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1011b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1011b6:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1011ba:	0f b7 c0             	movzwl %ax,%eax
  1011bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011c1:	c7 04 24 12 31 10 00 	movl   $0x103112,(%esp)
  1011c8:	e8 44 12 00 00       	call   102411 <cprintf>
}
  1011cd:	c9                   	leave  
  1011ce:	c3                   	ret    

001011cf <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  1011cf:	55                   	push   %ebp
  1011d0:	89 e5                	mov    %esp,%ebp
  1011d2:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  1011d5:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  1011d6:	e8 6f fd ff ff       	call   100f4a <cpu_cur>
  1011db:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  1011de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011e1:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1011e7:	85 c0                	test   %eax,%eax
  1011e9:	74 1e                	je     101209 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  1011eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011ee:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  1011f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1011f7:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  1011fd:	89 44 24 04          	mov    %eax,0x4(%esp)
  101201:	8b 45 08             	mov    0x8(%ebp),%eax
  101204:	89 04 24             	mov    %eax,(%esp)
  101207:	ff d2                	call   *%edx

	trap_print(tf);
  101209:	8b 45 08             	mov    0x8(%ebp),%eax
  10120c:	89 04 24             	mov    %eax,(%esp)
  10120f:	e8 ad fe ff ff       	call   1010c1 <trap_print>
	panic("unhandled trap");
  101214:	c7 44 24 08 25 31 10 	movl   $0x103125,0x8(%esp)
  10121b:	00 
  10121c:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  101223:	00 
  101224:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  10122b:	e8 f9 f0 ff ff       	call   100329 <debug_panic>

00101230 <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101230:	55                   	push   %ebp
  101231:	89 e5                	mov    %esp,%ebp
  101233:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101236:	8b 45 0c             	mov    0xc(%ebp),%eax
  101239:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  10123c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10123f:	8b 00                	mov    (%eax),%eax
  101241:	89 c2                	mov    %eax,%edx
  101243:	8b 45 08             	mov    0x8(%ebp),%eax
  101246:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  101249:	8b 45 08             	mov    0x8(%ebp),%eax
  10124c:	8b 40 30             	mov    0x30(%eax),%eax
  10124f:	89 c2                	mov    %eax,%edx
  101251:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101254:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  101257:	8b 45 08             	mov    0x8(%ebp),%eax
  10125a:	89 04 24             	mov    %eax,(%esp)
  10125d:	e8 2e 03 00 00       	call   101590 <trap_return>

00101262 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101262:	55                   	push   %ebp
  101263:	89 e5                	mov    %esp,%ebp
  101265:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101268:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  10126b:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  10126f:	0f b7 c0             	movzwl %ax,%eax
  101272:	83 e0 03             	and    $0x3,%eax
  101275:	85 c0                	test   %eax,%eax
  101277:	74 24                	je     10129d <trap_check_kernel+0x3b>
  101279:	c7 44 24 0c 34 31 10 	movl   $0x103134,0xc(%esp)
  101280:	00 
  101281:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  101288:	00 
  101289:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
  101290:	00 
  101291:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  101298:	e8 8c f0 ff ff       	call   100329 <debug_panic>

	cpu *c = cpu_cur();
  10129d:	e8 a8 fc ff ff       	call   100f4a <cpu_cur>
  1012a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  1012a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012a8:	c7 80 a0 00 00 00 30 	movl   $0x101230,0xa0(%eax)
  1012af:	12 10 00 
	trap_check(&c->recoverdata);
  1012b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012b5:	05 a4 00 00 00       	add    $0xa4,%eax
  1012ba:	89 04 24             	mov    %eax,(%esp)
  1012bd:	e8 96 00 00 00       	call   101358 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1012c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012c5:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1012cc:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  1012cf:	c7 04 24 4c 31 10 00 	movl   $0x10314c,(%esp)
  1012d6:	e8 36 11 00 00       	call   102411 <cprintf>
}
  1012db:	c9                   	leave  
  1012dc:	c3                   	ret    

001012dd <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  1012dd:	55                   	push   %ebp
  1012de:	89 e5                	mov    %esp,%ebp
  1012e0:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1012e3:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  1012e6:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  1012ea:	0f b7 c0             	movzwl %ax,%eax
  1012ed:	83 e0 03             	and    $0x3,%eax
  1012f0:	83 f8 03             	cmp    $0x3,%eax
  1012f3:	74 24                	je     101319 <trap_check_user+0x3c>
  1012f5:	c7 44 24 0c 6c 31 10 	movl   $0x10316c,0xc(%esp)
  1012fc:	00 
  1012fd:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  101304:	00 
  101305:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  10130c:	00 
  10130d:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  101314:	e8 10 f0 ff ff       	call   100329 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101319:	c7 45 f0 00 50 10 00 	movl   $0x105000,-0x10(%ebp)
	c->recover = trap_check_recover;
  101320:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101323:	c7 80 a0 00 00 00 30 	movl   $0x101230,0xa0(%eax)
  10132a:	12 10 00 
	trap_check(&c->recoverdata);
  10132d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101330:	05 a4 00 00 00       	add    $0xa4,%eax
  101335:	89 04 24             	mov    %eax,(%esp)
  101338:	e8 1b 00 00 00       	call   101358 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  10133d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101340:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101347:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  10134a:	c7 04 24 81 31 10 00 	movl   $0x103181,(%esp)
  101351:	e8 bb 10 00 00       	call   102411 <cprintf>
}
  101356:	c9                   	leave  
  101357:	c3                   	ret    

00101358 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  101358:	55                   	push   %ebp
  101359:	89 e5                	mov    %esp,%ebp
  10135b:	57                   	push   %edi
  10135c:	56                   	push   %esi
  10135d:	53                   	push   %ebx
  10135e:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101361:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101368:	8b 45 08             	mov    0x8(%ebp),%eax
  10136b:	8d 55 d8             	lea    -0x28(%ebp),%edx
  10136e:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  101370:	c7 45 d8 7e 13 10 00 	movl   $0x10137e,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101377:	b8 00 00 00 00       	mov    $0x0,%eax
  10137c:	f7 f0                	div    %eax

0010137e <after_div0>:
	assert(args.trapno == T_DIVIDE);
  10137e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101381:	85 c0                	test   %eax,%eax
  101383:	74 24                	je     1013a9 <after_div0+0x2b>
  101385:	c7 44 24 0c 9f 31 10 	movl   $0x10319f,0xc(%esp)
  10138c:	00 
  10138d:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  101394:	00 
  101395:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  10139c:	00 
  10139d:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  1013a4:	e8 80 ef ff ff       	call   100329 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1013a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1013ac:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1013b1:	74 24                	je     1013d7 <after_div0+0x59>
  1013b3:	c7 44 24 0c b7 31 10 	movl   $0x1031b7,0xc(%esp)
  1013ba:	00 
  1013bb:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  1013c2:	00 
  1013c3:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  1013ca:	00 
  1013cb:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  1013d2:	e8 52 ef ff ff       	call   100329 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  1013d7:	c7 45 d8 df 13 10 00 	movl   $0x1013df,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  1013de:	cc                   	int3   

001013df <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  1013df:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1013e2:	83 f8 03             	cmp    $0x3,%eax
  1013e5:	74 24                	je     10140b <after_breakpoint+0x2c>
  1013e7:	c7 44 24 0c cc 31 10 	movl   $0x1031cc,0xc(%esp)
  1013ee:	00 
  1013ef:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  1013f6:	00 
  1013f7:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  1013fe:	00 
  1013ff:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  101406:	e8 1e ef ff ff       	call   100329 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  10140b:	c7 45 d8 1a 14 10 00 	movl   $0x10141a,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101412:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101417:	01 c0                	add    %eax,%eax
  101419:	ce                   	into   

0010141a <after_overflow>:
	assert(args.trapno == T_OFLOW);
  10141a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10141d:	83 f8 04             	cmp    $0x4,%eax
  101420:	74 24                	je     101446 <after_overflow+0x2c>
  101422:	c7 44 24 0c e3 31 10 	movl   $0x1031e3,0xc(%esp)
  101429:	00 
  10142a:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  101431:	00 
  101432:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  101439:	00 
  10143a:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  101441:	e8 e3 ee ff ff       	call   100329 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101446:	c7 45 d8 63 14 10 00 	movl   $0x101463,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  10144d:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101454:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  10145b:	b8 00 00 00 00       	mov    $0x0,%eax
  101460:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101463 <after_bound>:
	assert(args.trapno == T_BOUND);
  101463:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101466:	83 f8 05             	cmp    $0x5,%eax
  101469:	74 24                	je     10148f <after_bound+0x2c>
  10146b:	c7 44 24 0c fa 31 10 	movl   $0x1031fa,0xc(%esp)
  101472:	00 
  101473:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  10147a:	00 
  10147b:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  101482:	00 
  101483:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  10148a:	e8 9a ee ff ff       	call   100329 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  10148f:	c7 45 d8 98 14 10 00 	movl   $0x101498,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101496:	0f 0b                	ud2    

00101498 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101498:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10149b:	83 f8 06             	cmp    $0x6,%eax
  10149e:	74 24                	je     1014c4 <after_illegal+0x2c>
  1014a0:	c7 44 24 0c 11 32 10 	movl   $0x103211,0xc(%esp)
  1014a7:	00 
  1014a8:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  1014af:	00 
  1014b0:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  1014b7:	00 
  1014b8:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  1014bf:	e8 65 ee ff ff       	call   100329 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  1014c4:	c7 45 d8 d2 14 10 00 	movl   $0x1014d2,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  1014cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1014d0:	8e e0                	mov    %eax,%fs

001014d2 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  1014d2:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1014d5:	83 f8 0d             	cmp    $0xd,%eax
  1014d8:	74 24                	je     1014fe <after_gpfault+0x2c>
  1014da:	c7 44 24 0c 28 32 10 	movl   $0x103228,0xc(%esp)
  1014e1:	00 
  1014e2:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  1014e9:	00 
  1014ea:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  1014f1:	00 
  1014f2:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  1014f9:	e8 2b ee ff ff       	call   100329 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1014fe:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  101501:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101505:	0f b7 c0             	movzwl %ax,%eax
  101508:	83 e0 03             	and    $0x3,%eax
  10150b:	85 c0                	test   %eax,%eax
  10150d:	74 3a                	je     101549 <after_priv+0x2c>
		args.reip = after_priv;
  10150f:	c7 45 d8 1d 15 10 00 	movl   $0x10151d,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101516:	0f 01 1d 00 60 10 00 	lidtl  0x106000

0010151d <after_priv>:
		assert(args.trapno == T_GPFLT);
  10151d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101520:	83 f8 0d             	cmp    $0xd,%eax
  101523:	74 24                	je     101549 <after_priv+0x2c>
  101525:	c7 44 24 0c 28 32 10 	movl   $0x103228,0xc(%esp)
  10152c:	00 
  10152d:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  101534:	00 
  101535:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  10153c:	00 
  10153d:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  101544:	e8 e0 ed ff ff       	call   100329 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101549:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10154c:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101551:	74 24                	je     101577 <after_priv+0x5a>
  101553:	c7 44 24 0c b7 31 10 	movl   $0x1031b7,0xc(%esp)
  10155a:	00 
  10155b:	c7 44 24 08 b6 2f 10 	movl   $0x102fb6,0x8(%esp)
  101562:	00 
  101563:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
  10156a:	00 
  10156b:	c7 04 24 f5 2f 10 00 	movl   $0x102ff5,(%esp)
  101572:	e8 b2 ed ff ff       	call   100329 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  101577:	8b 45 08             	mov    0x8(%ebp),%eax
  10157a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101580:	83 c4 3c             	add    $0x3c,%esp
  101583:	5b                   	pop    %ebx
  101584:	5e                   	pop    %esi
  101585:	5f                   	pop    %edi
  101586:	5d                   	pop    %ebp
  101587:	c3                   	ret    
  101588:	66 90                	xchg   %ax,%ax
  10158a:	66 90                	xchg   %ax,%ax
  10158c:	66 90                	xchg   %ax,%ax
  10158e:	66 90                	xchg   %ax,%ax

00101590 <trap_return>:
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return:
/*
 * Lab 1: Your code here for trap_return
 */
1:	jmp	1b		// just spin
  101590:	eb fe                	jmp    101590 <trap_return>

00101592 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  101592:	55                   	push   %ebp
  101593:	89 e5                	mov    %esp,%ebp
  101595:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  101598:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  10159f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1015a2:	0f b7 00             	movzwl (%eax),%eax
  1015a5:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  1015a9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1015ac:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  1015b1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1015b4:	0f b7 00             	movzwl (%eax),%eax
  1015b7:	66 3d 5a a5          	cmp    $0xa55a,%ax
  1015bb:	74 13                	je     1015d0 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  1015bd:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  1015c4:	c7 05 60 7f 10 00 b4 	movl   $0x3b4,0x107f60
  1015cb:	03 00 00 
  1015ce:	eb 14                	jmp    1015e4 <video_init+0x52>
	} else {
		*cp = was;
  1015d0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1015d3:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  1015d7:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  1015da:	c7 05 60 7f 10 00 d4 	movl   $0x3d4,0x107f60
  1015e1:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  1015e4:	a1 60 7f 10 00       	mov    0x107f60,%eax
  1015e9:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1015ec:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1015f0:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1015f4:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1015f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  1015f8:	a1 60 7f 10 00       	mov    0x107f60,%eax
  1015fd:	83 c0 01             	add    $0x1,%eax
  101600:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101603:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101606:	89 c2                	mov    %eax,%edx
  101608:	ec                   	in     (%dx),%al
  101609:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10160c:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  101610:	0f b6 c0             	movzbl %al,%eax
  101613:	c1 e0 08             	shl    $0x8,%eax
  101616:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  101619:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10161e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101621:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101625:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101629:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10162c:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  10162d:	a1 60 7f 10 00       	mov    0x107f60,%eax
  101632:	83 c0 01             	add    $0x1,%eax
  101635:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101638:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10163b:	89 c2                	mov    %eax,%edx
  10163d:	ec                   	in     (%dx),%al
  10163e:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101641:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  101645:	0f b6 c0             	movzbl %al,%eax
  101648:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  10164b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10164e:	a3 64 7f 10 00       	mov    %eax,0x107f64
	crt_pos = pos;
  101653:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101656:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
}
  10165c:	c9                   	leave  
  10165d:	c3                   	ret    

0010165e <video_putc>:



void
video_putc(int c)
{
  10165e:	55                   	push   %ebp
  10165f:	89 e5                	mov    %esp,%ebp
  101661:	53                   	push   %ebx
  101662:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  101665:	8b 45 08             	mov    0x8(%ebp),%eax
  101668:	b0 00                	mov    $0x0,%al
  10166a:	85 c0                	test   %eax,%eax
  10166c:	75 07                	jne    101675 <video_putc+0x17>
		c |= 0x0700;
  10166e:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  101675:	8b 45 08             	mov    0x8(%ebp),%eax
  101678:	25 ff 00 00 00       	and    $0xff,%eax
  10167d:	83 f8 09             	cmp    $0x9,%eax
  101680:	0f 84 ae 00 00 00    	je     101734 <video_putc+0xd6>
  101686:	83 f8 09             	cmp    $0x9,%eax
  101689:	7f 0a                	jg     101695 <video_putc+0x37>
  10168b:	83 f8 08             	cmp    $0x8,%eax
  10168e:	74 14                	je     1016a4 <video_putc+0x46>
  101690:	e9 dd 00 00 00       	jmp    101772 <video_putc+0x114>
  101695:	83 f8 0a             	cmp    $0xa,%eax
  101698:	74 4e                	je     1016e8 <video_putc+0x8a>
  10169a:	83 f8 0d             	cmp    $0xd,%eax
  10169d:	74 59                	je     1016f8 <video_putc+0x9a>
  10169f:	e9 ce 00 00 00       	jmp    101772 <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  1016a4:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1016ab:	66 85 c0             	test   %ax,%ax
  1016ae:	0f 84 e4 00 00 00    	je     101798 <video_putc+0x13a>
			crt_pos--;
  1016b4:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1016bb:	83 e8 01             	sub    $0x1,%eax
  1016be:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  1016c4:	a1 64 7f 10 00       	mov    0x107f64,%eax
  1016c9:	0f b7 15 68 7f 10 00 	movzwl 0x107f68,%edx
  1016d0:	0f b7 d2             	movzwl %dx,%edx
  1016d3:	01 d2                	add    %edx,%edx
  1016d5:	8d 14 10             	lea    (%eax,%edx,1),%edx
  1016d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1016db:	b0 00                	mov    $0x0,%al
  1016dd:	83 c8 20             	or     $0x20,%eax
  1016e0:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  1016e3:	e9 b1 00 00 00       	jmp    101799 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  1016e8:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1016ef:	83 c0 50             	add    $0x50,%eax
  1016f2:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  1016f8:	0f b7 1d 68 7f 10 00 	movzwl 0x107f68,%ebx
  1016ff:	0f b7 0d 68 7f 10 00 	movzwl 0x107f68,%ecx
  101706:	0f b7 c1             	movzwl %cx,%eax
  101709:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  10170f:	c1 e8 10             	shr    $0x10,%eax
  101712:	89 c2                	mov    %eax,%edx
  101714:	66 c1 ea 06          	shr    $0x6,%dx
  101718:	89 d0                	mov    %edx,%eax
  10171a:	c1 e0 02             	shl    $0x2,%eax
  10171d:	01 d0                	add    %edx,%eax
  10171f:	c1 e0 04             	shl    $0x4,%eax
  101722:	89 ca                	mov    %ecx,%edx
  101724:	66 29 c2             	sub    %ax,%dx
  101727:	89 d8                	mov    %ebx,%eax
  101729:	66 29 d0             	sub    %dx,%ax
  10172c:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		break;
  101732:	eb 65                	jmp    101799 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  101734:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10173b:	e8 1e ff ff ff       	call   10165e <video_putc>
		video_putc(' ');
  101740:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101747:	e8 12 ff ff ff       	call   10165e <video_putc>
		video_putc(' ');
  10174c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101753:	e8 06 ff ff ff       	call   10165e <video_putc>
		video_putc(' ');
  101758:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10175f:	e8 fa fe ff ff       	call   10165e <video_putc>
		video_putc(' ');
  101764:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10176b:	e8 ee fe ff ff       	call   10165e <video_putc>
		break;
  101770:	eb 27                	jmp    101799 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  101772:	8b 15 64 7f 10 00    	mov    0x107f64,%edx
  101778:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10177f:	0f b7 c8             	movzwl %ax,%ecx
  101782:	01 c9                	add    %ecx,%ecx
  101784:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  101787:	8b 55 08             	mov    0x8(%ebp),%edx
  10178a:	66 89 11             	mov    %dx,(%ecx)
  10178d:	83 c0 01             	add    $0x1,%eax
  101790:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
  101796:	eb 01                	jmp    101799 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  101798:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  101799:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1017a0:	66 3d cf 07          	cmp    $0x7cf,%ax
  1017a4:	76 5b                	jbe    101801 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  1017a6:	a1 64 7f 10 00       	mov    0x107f64,%eax
  1017ab:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  1017b1:	a1 64 7f 10 00       	mov    0x107f64,%eax
  1017b6:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  1017bd:	00 
  1017be:	89 54 24 04          	mov    %edx,0x4(%esp)
  1017c2:	89 04 24             	mov    %eax,(%esp)
  1017c5:	e8 a0 0e 00 00       	call   10266a <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  1017ca:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  1017d1:	eb 15                	jmp    1017e8 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  1017d3:	a1 64 7f 10 00       	mov    0x107f64,%eax
  1017d8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1017db:	01 d2                	add    %edx,%edx
  1017dd:	01 d0                	add    %edx,%eax
  1017df:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  1017e4:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  1017e8:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  1017ef:	7e e2                	jle    1017d3 <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  1017f1:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1017f8:	83 e8 50             	sub    $0x50,%eax
  1017fb:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  101801:	a1 60 7f 10 00       	mov    0x107f60,%eax
  101806:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101809:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10180d:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101811:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101814:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101815:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10181c:	66 c1 e8 08          	shr    $0x8,%ax
  101820:	0f b6 c0             	movzbl %al,%eax
  101823:	8b 15 60 7f 10 00    	mov    0x107f60,%edx
  101829:	83 c2 01             	add    $0x1,%edx
  10182c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10182f:	88 45 e3             	mov    %al,-0x1d(%ebp)
  101832:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101836:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101839:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  10183a:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10183f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101842:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  101846:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  10184a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10184d:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  10184e:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  101855:	0f b6 c0             	movzbl %al,%eax
  101858:	8b 15 60 7f 10 00    	mov    0x107f60,%edx
  10185e:	83 c2 01             	add    $0x1,%edx
  101861:	89 55 f4             	mov    %edx,-0xc(%ebp)
  101864:	88 45 f3             	mov    %al,-0xd(%ebp)
  101867:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10186b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10186e:	ee                   	out    %al,(%dx)
}
  10186f:	83 c4 44             	add    $0x44,%esp
  101872:	5b                   	pop    %ebx
  101873:	5d                   	pop    %ebp
  101874:	c3                   	ret    

00101875 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  101875:	55                   	push   %ebp
  101876:	89 e5                	mov    %esp,%ebp
  101878:	83 ec 38             	sub    $0x38,%esp
  10187b:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101882:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101885:	89 c2                	mov    %eax,%edx
  101887:	ec                   	in     (%dx),%al
  101888:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  10188b:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  10188f:	0f b6 c0             	movzbl %al,%eax
  101892:	83 e0 01             	and    $0x1,%eax
  101895:	85 c0                	test   %eax,%eax
  101897:	75 0a                	jne    1018a3 <kbd_proc_data+0x2e>
		return -1;
  101899:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10189e:	e9 5a 01 00 00       	jmp    1019fd <kbd_proc_data+0x188>
  1018a3:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1018aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1018ad:	89 c2                	mov    %eax,%edx
  1018af:	ec                   	in     (%dx),%al
  1018b0:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  1018b3:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  1018b7:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  1018ba:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  1018be:	75 17                	jne    1018d7 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  1018c0:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018c5:	83 c8 40             	or     $0x40,%eax
  1018c8:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
		return 0;
  1018cd:	b8 00 00 00 00       	mov    $0x0,%eax
  1018d2:	e9 26 01 00 00       	jmp    1019fd <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  1018d7:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1018db:	84 c0                	test   %al,%al
  1018dd:	79 47                	jns    101926 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  1018df:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018e4:	83 e0 40             	and    $0x40,%eax
  1018e7:	85 c0                	test   %eax,%eax
  1018e9:	75 09                	jne    1018f4 <kbd_proc_data+0x7f>
  1018eb:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1018ef:	83 e0 7f             	and    $0x7f,%eax
  1018f2:	eb 04                	jmp    1018f8 <kbd_proc_data+0x83>
  1018f4:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1018f8:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  1018fb:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1018ff:	0f b6 80 20 60 10 00 	movzbl 0x106020(%eax),%eax
  101906:	83 c8 40             	or     $0x40,%eax
  101909:	0f b6 c0             	movzbl %al,%eax
  10190c:	f7 d0                	not    %eax
  10190e:	89 c2                	mov    %eax,%edx
  101910:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101915:	21 d0                	and    %edx,%eax
  101917:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
		return 0;
  10191c:	b8 00 00 00 00       	mov    $0x0,%eax
  101921:	e9 d7 00 00 00       	jmp    1019fd <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  101926:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  10192b:	83 e0 40             	and    $0x40,%eax
  10192e:	85 c0                	test   %eax,%eax
  101930:	74 11                	je     101943 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  101932:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  101936:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  10193b:	83 e0 bf             	and    $0xffffffbf,%eax
  10193e:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
	}

	shift |= shiftcode[data];
  101943:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101947:	0f b6 80 20 60 10 00 	movzbl 0x106020(%eax),%eax
  10194e:	0f b6 d0             	movzbl %al,%edx
  101951:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101956:	09 d0                	or     %edx,%eax
  101958:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
	shift ^= togglecode[data];
  10195d:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101961:	0f b6 80 20 61 10 00 	movzbl 0x106120(%eax),%eax
  101968:	0f b6 d0             	movzbl %al,%edx
  10196b:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101970:	31 d0                	xor    %edx,%eax
  101972:	a3 6c 7f 10 00       	mov    %eax,0x107f6c

	c = charcode[shift & (CTL | SHIFT)][data];
  101977:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  10197c:	83 e0 03             	and    $0x3,%eax
  10197f:	8b 14 85 20 65 10 00 	mov    0x106520(,%eax,4),%edx
  101986:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10198a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10198d:	0f b6 00             	movzbl (%eax),%eax
  101990:	0f b6 c0             	movzbl %al,%eax
  101993:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  101996:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  10199b:	83 e0 08             	and    $0x8,%eax
  10199e:	85 c0                	test   %eax,%eax
  1019a0:	74 22                	je     1019c4 <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  1019a2:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  1019a6:	7e 0c                	jle    1019b4 <kbd_proc_data+0x13f>
  1019a8:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  1019ac:	7f 06                	jg     1019b4 <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  1019ae:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  1019b2:	eb 10                	jmp    1019c4 <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  1019b4:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  1019b8:	7e 0a                	jle    1019c4 <kbd_proc_data+0x14f>
  1019ba:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  1019be:	7f 04                	jg     1019c4 <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  1019c0:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  1019c4:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1019c9:	f7 d0                	not    %eax
  1019cb:	83 e0 06             	and    $0x6,%eax
  1019ce:	85 c0                	test   %eax,%eax
  1019d0:	75 28                	jne    1019fa <kbd_proc_data+0x185>
  1019d2:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  1019d9:	75 1f                	jne    1019fa <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  1019db:	c7 04 24 f0 33 10 00 	movl   $0x1033f0,(%esp)
  1019e2:	e8 2a 0a 00 00       	call   102411 <cprintf>
  1019e7:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  1019ee:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1019f2:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1019f6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1019f9:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  1019fa:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  1019fd:	c9                   	leave  
  1019fe:	c3                   	ret    

001019ff <kbd_intr>:

void
kbd_intr(void)
{
  1019ff:	55                   	push   %ebp
  101a00:	89 e5                	mov    %esp,%ebp
  101a02:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  101a05:	c7 04 24 75 18 10 00 	movl   $0x101875,(%esp)
  101a0c:	e8 e1 e7 ff ff       	call   1001f2 <cons_intr>
}
  101a11:	c9                   	leave  
  101a12:	c3                   	ret    

00101a13 <kbd_init>:

void
kbd_init(void)
{
  101a13:	55                   	push   %ebp
  101a14:	89 e5                	mov    %esp,%ebp
}
  101a16:	5d                   	pop    %ebp
  101a17:	c3                   	ret    

00101a18 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  101a18:	55                   	push   %ebp
  101a19:	89 e5                	mov    %esp,%ebp
  101a1b:	83 ec 20             	sub    $0x20,%esp
  101a1e:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a25:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101a28:	89 c2                	mov    %eax,%edx
  101a2a:	ec                   	in     (%dx),%al
  101a2b:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  101a2e:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a35:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101a38:	89 c2                	mov    %eax,%edx
  101a3a:	ec                   	in     (%dx),%al
  101a3b:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101a3e:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a45:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101a48:	89 c2                	mov    %eax,%edx
  101a4a:	ec                   	in     (%dx),%al
  101a4b:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101a4e:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a55:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101a58:	89 c2                	mov    %eax,%edx
  101a5a:	ec                   	in     (%dx),%al
  101a5b:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  101a5e:	c9                   	leave  
  101a5f:	c3                   	ret    

00101a60 <serial_proc_data>:

static int
serial_proc_data(void)
{
  101a60:	55                   	push   %ebp
  101a61:	89 e5                	mov    %esp,%ebp
  101a63:	83 ec 10             	sub    $0x10,%esp
  101a66:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  101a6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101a70:	89 c2                	mov    %eax,%edx
  101a72:	ec                   	in     (%dx),%al
  101a73:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101a76:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  101a7a:	0f b6 c0             	movzbl %al,%eax
  101a7d:	83 e0 01             	and    $0x1,%eax
  101a80:	85 c0                	test   %eax,%eax
  101a82:	75 07                	jne    101a8b <serial_proc_data+0x2b>
		return -1;
  101a84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101a89:	eb 17                	jmp    101aa2 <serial_proc_data+0x42>
  101a8b:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a92:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101a95:	89 c2                	mov    %eax,%edx
  101a97:	ec                   	in     (%dx),%al
  101a98:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101a9b:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  101a9f:	0f b6 c0             	movzbl %al,%eax
}
  101aa2:	c9                   	leave  
  101aa3:	c3                   	ret    

00101aa4 <serial_intr>:

void
serial_intr(void)
{
  101aa4:	55                   	push   %ebp
  101aa5:	89 e5                	mov    %esp,%ebp
  101aa7:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  101aaa:	a1 80 7f 10 00       	mov    0x107f80,%eax
  101aaf:	85 c0                	test   %eax,%eax
  101ab1:	74 0c                	je     101abf <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  101ab3:	c7 04 24 60 1a 10 00 	movl   $0x101a60,(%esp)
  101aba:	e8 33 e7 ff ff       	call   1001f2 <cons_intr>
}
  101abf:	c9                   	leave  
  101ac0:	c3                   	ret    

00101ac1 <serial_putc>:

void
serial_putc(int c)
{
  101ac1:	55                   	push   %ebp
  101ac2:	89 e5                	mov    %esp,%ebp
  101ac4:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  101ac7:	a1 80 7f 10 00       	mov    0x107f80,%eax
  101acc:	85 c0                	test   %eax,%eax
  101ace:	74 53                	je     101b23 <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  101ad0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  101ad7:	eb 09                	jmp    101ae2 <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  101ad9:	e8 3a ff ff ff       	call   101a18 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  101ade:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  101ae2:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ae9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101aec:	89 c2                	mov    %eax,%edx
  101aee:	ec                   	in     (%dx),%al
  101aef:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  101af2:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101af6:	0f b6 c0             	movzbl %al,%eax
  101af9:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  101afc:	85 c0                	test   %eax,%eax
  101afe:	75 09                	jne    101b09 <serial_putc+0x48>
  101b00:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  101b07:	7e d0                	jle    101ad9 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  101b09:	8b 45 08             	mov    0x8(%ebp),%eax
  101b0c:	0f b6 c0             	movzbl %al,%eax
  101b0f:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  101b16:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101b19:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101b1d:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101b20:	ee                   	out    %al,(%dx)
  101b21:	eb 01                	jmp    101b24 <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  101b23:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  101b24:	c9                   	leave  
  101b25:	c3                   	ret    

00101b26 <serial_init>:

void
serial_init(void)
{
  101b26:	55                   	push   %ebp
  101b27:	89 e5                	mov    %esp,%ebp
  101b29:	83 ec 50             	sub    $0x50,%esp
  101b2c:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  101b33:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  101b37:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  101b3b:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  101b3e:	ee                   	out    %al,(%dx)
  101b3f:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  101b46:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  101b4a:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  101b4e:	8b 55 bc             	mov    -0x44(%ebp),%edx
  101b51:	ee                   	out    %al,(%dx)
  101b52:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  101b59:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  101b5d:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  101b61:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  101b64:	ee                   	out    %al,(%dx)
  101b65:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  101b6c:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  101b70:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  101b74:	8b 55 cc             	mov    -0x34(%ebp),%edx
  101b77:	ee                   	out    %al,(%dx)
  101b78:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  101b7f:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  101b83:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  101b87:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101b8a:	ee                   	out    %al,(%dx)
  101b8b:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  101b92:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  101b96:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101b9a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101b9d:	ee                   	out    %al,(%dx)
  101b9e:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  101ba5:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  101ba9:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101bad:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101bb0:	ee                   	out    %al,(%dx)
  101bb1:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101bb8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101bbb:	89 c2                	mov    %eax,%edx
  101bbd:	ec                   	in     (%dx),%al
  101bbe:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101bc1:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  101bc5:	3c ff                	cmp    $0xff,%al
  101bc7:	0f 95 c0             	setne  %al
  101bca:	0f b6 c0             	movzbl %al,%eax
  101bcd:	a3 80 7f 10 00       	mov    %eax,0x107f80
  101bd2:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101bd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101bdc:	89 c2                	mov    %eax,%edx
  101bde:	ec                   	in     (%dx),%al
  101bdf:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101be2:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101be9:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101bec:	89 c2                	mov    %eax,%edx
  101bee:	ec                   	in     (%dx),%al
  101bef:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  101bf2:	c9                   	leave  
  101bf3:	c3                   	ret    

00101bf4 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  101bf4:	55                   	push   %ebp
  101bf5:	89 e5                	mov    %esp,%ebp
  101bf7:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101bfa:	8b 45 08             	mov    0x8(%ebp),%eax
  101bfd:	0f b6 c0             	movzbl %al,%eax
  101c00:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101c07:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101c0a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101c0e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101c11:	ee                   	out    %al,(%dx)
  101c12:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101c19:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101c1c:	89 c2                	mov    %eax,%edx
  101c1e:	ec                   	in     (%dx),%al
  101c1f:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101c22:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  101c26:	0f b6 c0             	movzbl %al,%eax
}
  101c29:	c9                   	leave  
  101c2a:	c3                   	ret    

00101c2b <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  101c2b:	55                   	push   %ebp
  101c2c:	89 e5                	mov    %esp,%ebp
  101c2e:	53                   	push   %ebx
  101c2f:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  101c32:	8b 45 08             	mov    0x8(%ebp),%eax
  101c35:	89 04 24             	mov    %eax,(%esp)
  101c38:	e8 b7 ff ff ff       	call   101bf4 <nvram_read>
  101c3d:	89 c3                	mov    %eax,%ebx
  101c3f:	8b 45 08             	mov    0x8(%ebp),%eax
  101c42:	83 c0 01             	add    $0x1,%eax
  101c45:	89 04 24             	mov    %eax,(%esp)
  101c48:	e8 a7 ff ff ff       	call   101bf4 <nvram_read>
  101c4d:	c1 e0 08             	shl    $0x8,%eax
  101c50:	09 d8                	or     %ebx,%eax
}
  101c52:	83 c4 04             	add    $0x4,%esp
  101c55:	5b                   	pop    %ebx
  101c56:	5d                   	pop    %ebp
  101c57:	c3                   	ret    

00101c58 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  101c58:	55                   	push   %ebp
  101c59:	89 e5                	mov    %esp,%ebp
  101c5b:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101c5e:	8b 45 08             	mov    0x8(%ebp),%eax
  101c61:	0f b6 c0             	movzbl %al,%eax
  101c64:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101c6b:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101c6e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101c72:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101c75:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  101c76:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c79:	0f b6 c0             	movzbl %al,%eax
  101c7c:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  101c83:	88 45 fb             	mov    %al,-0x5(%ebp)
  101c86:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101c8a:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101c8d:	ee                   	out    %al,(%dx)
}
  101c8e:	c9                   	leave  
  101c8f:	c3                   	ret    

00101c90 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  101c90:	55                   	push   %ebp
  101c91:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  101c93:	8b 45 08             	mov    0x8(%ebp),%eax
  101c96:	8b 40 18             	mov    0x18(%eax),%eax
  101c99:	83 e0 02             	and    $0x2,%eax
  101c9c:	85 c0                	test   %eax,%eax
  101c9e:	74 1c                	je     101cbc <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  101ca0:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ca3:	8b 00                	mov    (%eax),%eax
  101ca5:	8d 50 08             	lea    0x8(%eax),%edx
  101ca8:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cab:	89 10                	mov    %edx,(%eax)
  101cad:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cb0:	8b 00                	mov    (%eax),%eax
  101cb2:	83 e8 08             	sub    $0x8,%eax
  101cb5:	8b 50 04             	mov    0x4(%eax),%edx
  101cb8:	8b 00                	mov    (%eax),%eax
  101cba:	eb 47                	jmp    101d03 <getuint+0x73>
	else if (st->flags & F_L)
  101cbc:	8b 45 08             	mov    0x8(%ebp),%eax
  101cbf:	8b 40 18             	mov    0x18(%eax),%eax
  101cc2:	83 e0 01             	and    $0x1,%eax
  101cc5:	84 c0                	test   %al,%al
  101cc7:	74 1e                	je     101ce7 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  101cc9:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ccc:	8b 00                	mov    (%eax),%eax
  101cce:	8d 50 04             	lea    0x4(%eax),%edx
  101cd1:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cd4:	89 10                	mov    %edx,(%eax)
  101cd6:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cd9:	8b 00                	mov    (%eax),%eax
  101cdb:	83 e8 04             	sub    $0x4,%eax
  101cde:	8b 00                	mov    (%eax),%eax
  101ce0:	ba 00 00 00 00       	mov    $0x0,%edx
  101ce5:	eb 1c                	jmp    101d03 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  101ce7:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cea:	8b 00                	mov    (%eax),%eax
  101cec:	8d 50 04             	lea    0x4(%eax),%edx
  101cef:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cf2:	89 10                	mov    %edx,(%eax)
  101cf4:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cf7:	8b 00                	mov    (%eax),%eax
  101cf9:	83 e8 04             	sub    $0x4,%eax
  101cfc:	8b 00                	mov    (%eax),%eax
  101cfe:	ba 00 00 00 00       	mov    $0x0,%edx
}
  101d03:	5d                   	pop    %ebp
  101d04:	c3                   	ret    

00101d05 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  101d05:	55                   	push   %ebp
  101d06:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  101d08:	8b 45 08             	mov    0x8(%ebp),%eax
  101d0b:	8b 40 18             	mov    0x18(%eax),%eax
  101d0e:	83 e0 02             	and    $0x2,%eax
  101d11:	85 c0                	test   %eax,%eax
  101d13:	74 1c                	je     101d31 <getint+0x2c>
		return va_arg(*ap, long long);
  101d15:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d18:	8b 00                	mov    (%eax),%eax
  101d1a:	8d 50 08             	lea    0x8(%eax),%edx
  101d1d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d20:	89 10                	mov    %edx,(%eax)
  101d22:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d25:	8b 00                	mov    (%eax),%eax
  101d27:	83 e8 08             	sub    $0x8,%eax
  101d2a:	8b 50 04             	mov    0x4(%eax),%edx
  101d2d:	8b 00                	mov    (%eax),%eax
  101d2f:	eb 47                	jmp    101d78 <getint+0x73>
	else if (st->flags & F_L)
  101d31:	8b 45 08             	mov    0x8(%ebp),%eax
  101d34:	8b 40 18             	mov    0x18(%eax),%eax
  101d37:	83 e0 01             	and    $0x1,%eax
  101d3a:	84 c0                	test   %al,%al
  101d3c:	74 1e                	je     101d5c <getint+0x57>
		return va_arg(*ap, long);
  101d3e:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d41:	8b 00                	mov    (%eax),%eax
  101d43:	8d 50 04             	lea    0x4(%eax),%edx
  101d46:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d49:	89 10                	mov    %edx,(%eax)
  101d4b:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d4e:	8b 00                	mov    (%eax),%eax
  101d50:	83 e8 04             	sub    $0x4,%eax
  101d53:	8b 00                	mov    (%eax),%eax
  101d55:	89 c2                	mov    %eax,%edx
  101d57:	c1 fa 1f             	sar    $0x1f,%edx
  101d5a:	eb 1c                	jmp    101d78 <getint+0x73>
	else
		return va_arg(*ap, int);
  101d5c:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d5f:	8b 00                	mov    (%eax),%eax
  101d61:	8d 50 04             	lea    0x4(%eax),%edx
  101d64:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d67:	89 10                	mov    %edx,(%eax)
  101d69:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d6c:	8b 00                	mov    (%eax),%eax
  101d6e:	83 e8 04             	sub    $0x4,%eax
  101d71:	8b 00                	mov    (%eax),%eax
  101d73:	89 c2                	mov    %eax,%edx
  101d75:	c1 fa 1f             	sar    $0x1f,%edx
}
  101d78:	5d                   	pop    %ebp
  101d79:	c3                   	ret    

00101d7a <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  101d7a:	55                   	push   %ebp
  101d7b:	89 e5                	mov    %esp,%ebp
  101d7d:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  101d80:	eb 1a                	jmp    101d9c <putpad+0x22>
		st->putch(st->padc, st->putdat);
  101d82:	8b 45 08             	mov    0x8(%ebp),%eax
  101d85:	8b 08                	mov    (%eax),%ecx
  101d87:	8b 45 08             	mov    0x8(%ebp),%eax
  101d8a:	8b 50 04             	mov    0x4(%eax),%edx
  101d8d:	8b 45 08             	mov    0x8(%ebp),%eax
  101d90:	8b 40 08             	mov    0x8(%eax),%eax
  101d93:	89 54 24 04          	mov    %edx,0x4(%esp)
  101d97:	89 04 24             	mov    %eax,(%esp)
  101d9a:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  101d9c:	8b 45 08             	mov    0x8(%ebp),%eax
  101d9f:	8b 40 0c             	mov    0xc(%eax),%eax
  101da2:	8d 50 ff             	lea    -0x1(%eax),%edx
  101da5:	8b 45 08             	mov    0x8(%ebp),%eax
  101da8:	89 50 0c             	mov    %edx,0xc(%eax)
  101dab:	8b 45 08             	mov    0x8(%ebp),%eax
  101dae:	8b 40 0c             	mov    0xc(%eax),%eax
  101db1:	85 c0                	test   %eax,%eax
  101db3:	79 cd                	jns    101d82 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  101db5:	c9                   	leave  
  101db6:	c3                   	ret    

00101db7 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  101db7:	55                   	push   %ebp
  101db8:	89 e5                	mov    %esp,%ebp
  101dba:	53                   	push   %ebx
  101dbb:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  101dbe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  101dc2:	79 18                	jns    101ddc <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  101dc4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101dcb:	00 
  101dcc:	8b 45 0c             	mov    0xc(%ebp),%eax
  101dcf:	89 04 24             	mov    %eax,(%esp)
  101dd2:	e8 e7 07 00 00       	call   1025be <strchr>
  101dd7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101dda:	eb 2c                	jmp    101e08 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  101ddc:	8b 45 10             	mov    0x10(%ebp),%eax
  101ddf:	89 44 24 08          	mov    %eax,0x8(%esp)
  101de3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101dea:	00 
  101deb:	8b 45 0c             	mov    0xc(%ebp),%eax
  101dee:	89 04 24             	mov    %eax,(%esp)
  101df1:	e8 cc 09 00 00       	call   1027c2 <memchr>
  101df6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101df9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101dfd:	75 09                	jne    101e08 <putstr+0x51>
		lim = str + maxlen;
  101dff:	8b 45 10             	mov    0x10(%ebp),%eax
  101e02:	03 45 0c             	add    0xc(%ebp),%eax
  101e05:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  101e08:	8b 45 08             	mov    0x8(%ebp),%eax
  101e0b:	8b 40 0c             	mov    0xc(%eax),%eax
  101e0e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  101e11:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101e14:	89 cb                	mov    %ecx,%ebx
  101e16:	29 d3                	sub    %edx,%ebx
  101e18:	89 da                	mov    %ebx,%edx
  101e1a:	8d 14 10             	lea    (%eax,%edx,1),%edx
  101e1d:	8b 45 08             	mov    0x8(%ebp),%eax
  101e20:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  101e23:	8b 45 08             	mov    0x8(%ebp),%eax
  101e26:	8b 40 18             	mov    0x18(%eax),%eax
  101e29:	83 e0 10             	and    $0x10,%eax
  101e2c:	85 c0                	test   %eax,%eax
  101e2e:	75 32                	jne    101e62 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  101e30:	8b 45 08             	mov    0x8(%ebp),%eax
  101e33:	89 04 24             	mov    %eax,(%esp)
  101e36:	e8 3f ff ff ff       	call   101d7a <putpad>
	while (str < lim) {
  101e3b:	eb 25                	jmp    101e62 <putstr+0xab>
		char ch = *str++;
  101e3d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e40:	0f b6 00             	movzbl (%eax),%eax
  101e43:	88 45 f7             	mov    %al,-0x9(%ebp)
  101e46:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  101e4a:	8b 45 08             	mov    0x8(%ebp),%eax
  101e4d:	8b 08                	mov    (%eax),%ecx
  101e4f:	8b 45 08             	mov    0x8(%ebp),%eax
  101e52:	8b 50 04             	mov    0x4(%eax),%edx
  101e55:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  101e59:	89 54 24 04          	mov    %edx,0x4(%esp)
  101e5d:	89 04 24             	mov    %eax,(%esp)
  101e60:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  101e62:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e65:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  101e68:	72 d3                	jb     101e3d <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  101e6a:	8b 45 08             	mov    0x8(%ebp),%eax
  101e6d:	89 04 24             	mov    %eax,(%esp)
  101e70:	e8 05 ff ff ff       	call   101d7a <putpad>
}
  101e75:	83 c4 24             	add    $0x24,%esp
  101e78:	5b                   	pop    %ebx
  101e79:	5d                   	pop    %ebp
  101e7a:	c3                   	ret    

00101e7b <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  101e7b:	55                   	push   %ebp
  101e7c:	89 e5                	mov    %esp,%ebp
  101e7e:	53                   	push   %ebx
  101e7f:	83 ec 24             	sub    $0x24,%esp
  101e82:	8b 45 10             	mov    0x10(%ebp),%eax
  101e85:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101e88:	8b 45 14             	mov    0x14(%ebp),%eax
  101e8b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  101e8e:	8b 45 08             	mov    0x8(%ebp),%eax
  101e91:	8b 40 1c             	mov    0x1c(%eax),%eax
  101e94:	89 c2                	mov    %eax,%edx
  101e96:	c1 fa 1f             	sar    $0x1f,%edx
  101e99:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  101e9c:	77 4e                	ja     101eec <genint+0x71>
  101e9e:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  101ea1:	72 05                	jb     101ea8 <genint+0x2d>
  101ea3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  101ea6:	77 44                	ja     101eec <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  101ea8:	8b 45 08             	mov    0x8(%ebp),%eax
  101eab:	8b 40 1c             	mov    0x1c(%eax),%eax
  101eae:	89 c2                	mov    %eax,%edx
  101eb0:	c1 fa 1f             	sar    $0x1f,%edx
  101eb3:	89 44 24 08          	mov    %eax,0x8(%esp)
  101eb7:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101ebb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101ebe:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101ec1:	89 04 24             	mov    %eax,(%esp)
  101ec4:	89 54 24 04          	mov    %edx,0x4(%esp)
  101ec8:	e8 33 09 00 00       	call   102800 <__udivdi3>
  101ecd:	89 44 24 08          	mov    %eax,0x8(%esp)
  101ed1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101ed5:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ed8:	89 44 24 04          	mov    %eax,0x4(%esp)
  101edc:	8b 45 08             	mov    0x8(%ebp),%eax
  101edf:	89 04 24             	mov    %eax,(%esp)
  101ee2:	e8 94 ff ff ff       	call   101e7b <genint>
  101ee7:	89 45 0c             	mov    %eax,0xc(%ebp)
  101eea:	eb 1b                	jmp    101f07 <genint+0x8c>
	else if (st->signc >= 0)
  101eec:	8b 45 08             	mov    0x8(%ebp),%eax
  101eef:	8b 40 14             	mov    0x14(%eax),%eax
  101ef2:	85 c0                	test   %eax,%eax
  101ef4:	78 11                	js     101f07 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  101ef6:	8b 45 08             	mov    0x8(%ebp),%eax
  101ef9:	8b 40 14             	mov    0x14(%eax),%eax
  101efc:	89 c2                	mov    %eax,%edx
  101efe:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f01:	88 10                	mov    %dl,(%eax)
  101f03:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  101f07:	8b 45 08             	mov    0x8(%ebp),%eax
  101f0a:	8b 40 1c             	mov    0x1c(%eax),%eax
  101f0d:	89 c1                	mov    %eax,%ecx
  101f0f:	89 c3                	mov    %eax,%ebx
  101f11:	c1 fb 1f             	sar    $0x1f,%ebx
  101f14:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101f17:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101f1a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  101f1e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  101f22:	89 04 24             	mov    %eax,(%esp)
  101f25:	89 54 24 04          	mov    %edx,0x4(%esp)
  101f29:	e8 02 0a 00 00       	call   102930 <__umoddi3>
  101f2e:	05 fc 33 10 00       	add    $0x1033fc,%eax
  101f33:	0f b6 10             	movzbl (%eax),%edx
  101f36:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f39:	88 10                	mov    %dl,(%eax)
  101f3b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  101f3f:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  101f42:	83 c4 24             	add    $0x24,%esp
  101f45:	5b                   	pop    %ebx
  101f46:	5d                   	pop    %ebp
  101f47:	c3                   	ret    

00101f48 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  101f48:	55                   	push   %ebp
  101f49:	89 e5                	mov    %esp,%ebp
  101f4b:	83 ec 58             	sub    $0x58,%esp
  101f4e:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f51:	89 45 c0             	mov    %eax,-0x40(%ebp)
  101f54:	8b 45 10             	mov    0x10(%ebp),%eax
  101f57:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  101f5a:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  101f5d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  101f60:	8b 45 08             	mov    0x8(%ebp),%eax
  101f63:	8b 55 14             	mov    0x14(%ebp),%edx
  101f66:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  101f69:	8b 45 c0             	mov    -0x40(%ebp),%eax
  101f6c:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  101f6f:	89 44 24 08          	mov    %eax,0x8(%esp)
  101f73:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101f77:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101f7e:	8b 45 08             	mov    0x8(%ebp),%eax
  101f81:	89 04 24             	mov    %eax,(%esp)
  101f84:	e8 f2 fe ff ff       	call   101e7b <genint>
  101f89:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  101f8c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101f8f:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  101f92:	89 d1                	mov    %edx,%ecx
  101f94:	29 c1                	sub    %eax,%ecx
  101f96:	89 c8                	mov    %ecx,%eax
  101f98:	89 44 24 08          	mov    %eax,0x8(%esp)
  101f9c:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  101f9f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101fa3:	8b 45 08             	mov    0x8(%ebp),%eax
  101fa6:	89 04 24             	mov    %eax,(%esp)
  101fa9:	e8 09 fe ff ff       	call   101db7 <putstr>
}
  101fae:	c9                   	leave  
  101faf:	c3                   	ret    

00101fb0 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  101fb0:	55                   	push   %ebp
  101fb1:	89 e5                	mov    %esp,%ebp
  101fb3:	53                   	push   %ebx
  101fb4:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  101fb7:	8d 55 c8             	lea    -0x38(%ebp),%edx
  101fba:	b9 00 00 00 00       	mov    $0x0,%ecx
  101fbf:	b8 20 00 00 00       	mov    $0x20,%eax
  101fc4:	89 c3                	mov    %eax,%ebx
  101fc6:	83 e3 fc             	and    $0xfffffffc,%ebx
  101fc9:	b8 00 00 00 00       	mov    $0x0,%eax
  101fce:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  101fd1:	83 c0 04             	add    $0x4,%eax
  101fd4:	39 d8                	cmp    %ebx,%eax
  101fd6:	72 f6                	jb     101fce <vprintfmt+0x1e>
  101fd8:	01 c2                	add    %eax,%edx
  101fda:	8b 45 08             	mov    0x8(%ebp),%eax
  101fdd:	89 45 c8             	mov    %eax,-0x38(%ebp)
  101fe0:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fe3:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  101fe6:	eb 17                	jmp    101fff <vprintfmt+0x4f>
			if (ch == '\0')
  101fe8:	85 db                	test   %ebx,%ebx
  101fea:	0f 84 52 03 00 00    	je     102342 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  101ff0:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ff3:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ff7:	89 1c 24             	mov    %ebx,(%esp)
  101ffa:	8b 45 08             	mov    0x8(%ebp),%eax
  101ffd:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  101fff:	8b 45 10             	mov    0x10(%ebp),%eax
  102002:	0f b6 00             	movzbl (%eax),%eax
  102005:	0f b6 d8             	movzbl %al,%ebx
  102008:	83 fb 25             	cmp    $0x25,%ebx
  10200b:	0f 95 c0             	setne  %al
  10200e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  102012:	84 c0                	test   %al,%al
  102014:	75 d2                	jne    101fe8 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  102016:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  10201d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  102024:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  10202b:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  102032:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  102039:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  102040:	eb 04                	jmp    102046 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  102042:	90                   	nop
  102043:	eb 01                	jmp    102046 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  102045:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  102046:	8b 45 10             	mov    0x10(%ebp),%eax
  102049:	0f b6 00             	movzbl (%eax),%eax
  10204c:	0f b6 d8             	movzbl %al,%ebx
  10204f:	89 d8                	mov    %ebx,%eax
  102051:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  102055:	83 e8 20             	sub    $0x20,%eax
  102058:	83 f8 58             	cmp    $0x58,%eax
  10205b:	0f 87 b1 02 00 00    	ja     102312 <vprintfmt+0x362>
  102061:	8b 04 85 14 34 10 00 	mov    0x103414(,%eax,4),%eax
  102068:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  10206a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10206d:	83 c8 10             	or     $0x10,%eax
  102070:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102073:	eb d1                	jmp    102046 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  102075:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  10207c:	eb c8                	jmp    102046 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  10207e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102081:	85 c0                	test   %eax,%eax
  102083:	79 bd                	jns    102042 <vprintfmt+0x92>
				st.signc = ' ';
  102085:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  10208c:	eb b8                	jmp    102046 <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  10208e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102091:	83 e0 08             	and    $0x8,%eax
  102094:	85 c0                	test   %eax,%eax
  102096:	75 07                	jne    10209f <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  102098:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10209f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  1020a6:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1020a9:	89 d0                	mov    %edx,%eax
  1020ab:	c1 e0 02             	shl    $0x2,%eax
  1020ae:	01 d0                	add    %edx,%eax
  1020b0:	01 c0                	add    %eax,%eax
  1020b2:	01 d8                	add    %ebx,%eax
  1020b4:	83 e8 30             	sub    $0x30,%eax
  1020b7:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  1020ba:	8b 45 10             	mov    0x10(%ebp),%eax
  1020bd:	0f b6 00             	movzbl (%eax),%eax
  1020c0:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  1020c3:	83 fb 2f             	cmp    $0x2f,%ebx
  1020c6:	7e 21                	jle    1020e9 <vprintfmt+0x139>
  1020c8:	83 fb 39             	cmp    $0x39,%ebx
  1020cb:	7f 1f                	jg     1020ec <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1020cd:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  1020d1:	eb d3                	jmp    1020a6 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  1020d3:	8b 45 14             	mov    0x14(%ebp),%eax
  1020d6:	83 c0 04             	add    $0x4,%eax
  1020d9:	89 45 14             	mov    %eax,0x14(%ebp)
  1020dc:	8b 45 14             	mov    0x14(%ebp),%eax
  1020df:	83 e8 04             	sub    $0x4,%eax
  1020e2:	8b 00                	mov    (%eax),%eax
  1020e4:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1020e7:	eb 04                	jmp    1020ed <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  1020e9:	90                   	nop
  1020ea:	eb 01                	jmp    1020ed <vprintfmt+0x13d>
  1020ec:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  1020ed:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1020f0:	83 e0 08             	and    $0x8,%eax
  1020f3:	85 c0                	test   %eax,%eax
  1020f5:	0f 85 4a ff ff ff    	jne    102045 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  1020fb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1020fe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  102101:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  102108:	e9 39 ff ff ff       	jmp    102046 <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  10210d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102110:	83 c8 08             	or     $0x8,%eax
  102113:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102116:	e9 2b ff ff ff       	jmp    102046 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  10211b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10211e:	83 c8 04             	or     $0x4,%eax
  102121:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102124:	e9 1d ff ff ff       	jmp    102046 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  102129:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10212c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10212f:	83 e0 01             	and    $0x1,%eax
  102132:	84 c0                	test   %al,%al
  102134:	74 07                	je     10213d <vprintfmt+0x18d>
  102136:	b8 02 00 00 00       	mov    $0x2,%eax
  10213b:	eb 05                	jmp    102142 <vprintfmt+0x192>
  10213d:	b8 01 00 00 00       	mov    $0x1,%eax
  102142:	09 d0                	or     %edx,%eax
  102144:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102147:	e9 fa fe ff ff       	jmp    102046 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  10214c:	8b 45 14             	mov    0x14(%ebp),%eax
  10214f:	83 c0 04             	add    $0x4,%eax
  102152:	89 45 14             	mov    %eax,0x14(%ebp)
  102155:	8b 45 14             	mov    0x14(%ebp),%eax
  102158:	83 e8 04             	sub    $0x4,%eax
  10215b:	8b 00                	mov    (%eax),%eax
  10215d:	8b 55 0c             	mov    0xc(%ebp),%edx
  102160:	89 54 24 04          	mov    %edx,0x4(%esp)
  102164:	89 04 24             	mov    %eax,(%esp)
  102167:	8b 45 08             	mov    0x8(%ebp),%eax
  10216a:	ff d0                	call   *%eax
			break;
  10216c:	e9 cb 01 00 00       	jmp    10233c <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  102171:	8b 45 14             	mov    0x14(%ebp),%eax
  102174:	83 c0 04             	add    $0x4,%eax
  102177:	89 45 14             	mov    %eax,0x14(%ebp)
  10217a:	8b 45 14             	mov    0x14(%ebp),%eax
  10217d:	83 e8 04             	sub    $0x4,%eax
  102180:	8b 00                	mov    (%eax),%eax
  102182:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102185:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102189:	75 07                	jne    102192 <vprintfmt+0x1e2>
				s = "(null)";
  10218b:	c7 45 f4 0d 34 10 00 	movl   $0x10340d,-0xc(%ebp)
			putstr(&st, s, st.prec);
  102192:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102195:	89 44 24 08          	mov    %eax,0x8(%esp)
  102199:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10219c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021a0:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1021a3:	89 04 24             	mov    %eax,(%esp)
  1021a6:	e8 0c fc ff ff       	call   101db7 <putstr>
			break;
  1021ab:	e9 8c 01 00 00       	jmp    10233c <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  1021b0:	8d 45 14             	lea    0x14(%ebp),%eax
  1021b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021b7:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1021ba:	89 04 24             	mov    %eax,(%esp)
  1021bd:	e8 43 fb ff ff       	call   101d05 <getint>
  1021c2:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1021c5:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  1021c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1021cb:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1021ce:	85 d2                	test   %edx,%edx
  1021d0:	79 1a                	jns    1021ec <vprintfmt+0x23c>
				num = -(intmax_t) num;
  1021d2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1021d5:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1021d8:	f7 d8                	neg    %eax
  1021da:	83 d2 00             	adc    $0x0,%edx
  1021dd:	f7 da                	neg    %edx
  1021df:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1021e2:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  1021e5:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  1021ec:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1021f3:	00 
  1021f4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1021f7:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1021fa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021fe:	89 54 24 08          	mov    %edx,0x8(%esp)
  102202:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102205:	89 04 24             	mov    %eax,(%esp)
  102208:	e8 3b fd ff ff       	call   101f48 <putint>
			break;
  10220d:	e9 2a 01 00 00       	jmp    10233c <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  102212:	8d 45 14             	lea    0x14(%ebp),%eax
  102215:	89 44 24 04          	mov    %eax,0x4(%esp)
  102219:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10221c:	89 04 24             	mov    %eax,(%esp)
  10221f:	e8 6c fa ff ff       	call   101c90 <getuint>
  102224:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10222b:	00 
  10222c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102230:	89 54 24 08          	mov    %edx,0x8(%esp)
  102234:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102237:	89 04 24             	mov    %eax,(%esp)
  10223a:	e8 09 fd ff ff       	call   101f48 <putint>
			break;
  10223f:	e9 f8 00 00 00       	jmp    10233c <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  102244:	8d 45 14             	lea    0x14(%ebp),%eax
  102247:	89 44 24 04          	mov    %eax,0x4(%esp)
  10224b:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10224e:	89 04 24             	mov    %eax,(%esp)
  102251:	e8 3a fa ff ff       	call   101c90 <getuint>
  102256:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  10225d:	00 
  10225e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102262:	89 54 24 08          	mov    %edx,0x8(%esp)
  102266:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102269:	89 04 24             	mov    %eax,(%esp)
  10226c:	e8 d7 fc ff ff       	call   101f48 <putint>
			break;
  102271:	e9 c6 00 00 00       	jmp    10233c <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  102276:	8d 45 14             	lea    0x14(%ebp),%eax
  102279:	89 44 24 04          	mov    %eax,0x4(%esp)
  10227d:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102280:	89 04 24             	mov    %eax,(%esp)
  102283:	e8 08 fa ff ff       	call   101c90 <getuint>
  102288:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10228f:	00 
  102290:	89 44 24 04          	mov    %eax,0x4(%esp)
  102294:	89 54 24 08          	mov    %edx,0x8(%esp)
  102298:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10229b:	89 04 24             	mov    %eax,(%esp)
  10229e:	e8 a5 fc ff ff       	call   101f48 <putint>
			break;
  1022a3:	e9 94 00 00 00       	jmp    10233c <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  1022a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022af:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  1022b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1022b9:	ff d0                	call   *%eax
			putch('x', putdat);
  1022bb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022be:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022c2:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  1022c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1022cc:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  1022ce:	8b 45 14             	mov    0x14(%ebp),%eax
  1022d1:	83 c0 04             	add    $0x4,%eax
  1022d4:	89 45 14             	mov    %eax,0x14(%ebp)
  1022d7:	8b 45 14             	mov    0x14(%ebp),%eax
  1022da:	83 e8 04             	sub    $0x4,%eax
  1022dd:	8b 00                	mov    (%eax),%eax
  1022df:	ba 00 00 00 00       	mov    $0x0,%edx
  1022e4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1022eb:	00 
  1022ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022f0:	89 54 24 08          	mov    %edx,0x8(%esp)
  1022f4:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1022f7:	89 04 24             	mov    %eax,(%esp)
  1022fa:	e8 49 fc ff ff       	call   101f48 <putint>
			break;
  1022ff:	eb 3b                	jmp    10233c <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  102301:	8b 45 0c             	mov    0xc(%ebp),%eax
  102304:	89 44 24 04          	mov    %eax,0x4(%esp)
  102308:	89 1c 24             	mov    %ebx,(%esp)
  10230b:	8b 45 08             	mov    0x8(%ebp),%eax
  10230e:	ff d0                	call   *%eax
			break;
  102310:	eb 2a                	jmp    10233c <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  102312:	8b 45 0c             	mov    0xc(%ebp),%eax
  102315:	89 44 24 04          	mov    %eax,0x4(%esp)
  102319:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  102320:	8b 45 08             	mov    0x8(%ebp),%eax
  102323:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  102325:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102329:	eb 04                	jmp    10232f <vprintfmt+0x37f>
  10232b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10232f:	8b 45 10             	mov    0x10(%ebp),%eax
  102332:	83 e8 01             	sub    $0x1,%eax
  102335:	0f b6 00             	movzbl (%eax),%eax
  102338:	3c 25                	cmp    $0x25,%al
  10233a:	75 ef                	jne    10232b <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  10233c:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10233d:	e9 bd fc ff ff       	jmp    101fff <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  102342:	83 c4 44             	add    $0x44,%esp
  102345:	5b                   	pop    %ebx
  102346:	5d                   	pop    %ebp
  102347:	c3                   	ret    

00102348 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  102348:	55                   	push   %ebp
  102349:	89 e5                	mov    %esp,%ebp
  10234b:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  10234e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102351:	8b 00                	mov    (%eax),%eax
  102353:	8b 55 08             	mov    0x8(%ebp),%edx
  102356:	89 d1                	mov    %edx,%ecx
  102358:	8b 55 0c             	mov    0xc(%ebp),%edx
  10235b:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  10235f:	8d 50 01             	lea    0x1(%eax),%edx
  102362:	8b 45 0c             	mov    0xc(%ebp),%eax
  102365:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  102367:	8b 45 0c             	mov    0xc(%ebp),%eax
  10236a:	8b 00                	mov    (%eax),%eax
  10236c:	3d ff 00 00 00       	cmp    $0xff,%eax
  102371:	75 24                	jne    102397 <putch+0x4f>
		b->buf[b->idx] = 0;
  102373:	8b 45 0c             	mov    0xc(%ebp),%eax
  102376:	8b 00                	mov    (%eax),%eax
  102378:	8b 55 0c             	mov    0xc(%ebp),%edx
  10237b:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  102380:	8b 45 0c             	mov    0xc(%ebp),%eax
  102383:	83 c0 08             	add    $0x8,%eax
  102386:	89 04 24             	mov    %eax,(%esp)
  102389:	e8 72 df ff ff       	call   100300 <cputs>
		b->idx = 0;
  10238e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102391:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  102397:	8b 45 0c             	mov    0xc(%ebp),%eax
  10239a:	8b 40 04             	mov    0x4(%eax),%eax
  10239d:	8d 50 01             	lea    0x1(%eax),%edx
  1023a0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023a3:	89 50 04             	mov    %edx,0x4(%eax)
}
  1023a6:	c9                   	leave  
  1023a7:	c3                   	ret    

001023a8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  1023a8:	55                   	push   %ebp
  1023a9:	89 e5                	mov    %esp,%ebp
  1023ab:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  1023b1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  1023b8:	00 00 00 
	b.cnt = 0;
  1023bb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  1023c2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  1023c5:	b8 48 23 10 00       	mov    $0x102348,%eax
  1023ca:	8b 55 0c             	mov    0xc(%ebp),%edx
  1023cd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1023d1:	8b 55 08             	mov    0x8(%ebp),%edx
  1023d4:	89 54 24 08          	mov    %edx,0x8(%esp)
  1023d8:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  1023de:	89 54 24 04          	mov    %edx,0x4(%esp)
  1023e2:	89 04 24             	mov    %eax,(%esp)
  1023e5:	e8 c6 fb ff ff       	call   101fb0 <vprintfmt>

	b.buf[b.idx] = 0;
  1023ea:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  1023f0:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  1023f7:	00 
	cputs(b.buf);
  1023f8:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1023fe:	83 c0 08             	add    $0x8,%eax
  102401:	89 04 24             	mov    %eax,(%esp)
  102404:	e8 f7 de ff ff       	call   100300 <cputs>

	return b.cnt;
  102409:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  10240f:	c9                   	leave  
  102410:	c3                   	ret    

00102411 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  102411:	55                   	push   %ebp
  102412:	89 e5                	mov    %esp,%ebp
  102414:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  102417:	8d 45 08             	lea    0x8(%ebp),%eax
  10241a:	83 c0 04             	add    $0x4,%eax
  10241d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  102420:	8b 45 08             	mov    0x8(%ebp),%eax
  102423:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102426:	89 54 24 04          	mov    %edx,0x4(%esp)
  10242a:	89 04 24             	mov    %eax,(%esp)
  10242d:	e8 76 ff ff ff       	call   1023a8 <vcprintf>
  102432:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  102435:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  102438:	c9                   	leave  
  102439:	c3                   	ret    

0010243a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  10243a:	55                   	push   %ebp
  10243b:	89 e5                	mov    %esp,%ebp
  10243d:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  102440:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  102447:	eb 08                	jmp    102451 <strlen+0x17>
		n++;
  102449:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  10244d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102451:	8b 45 08             	mov    0x8(%ebp),%eax
  102454:	0f b6 00             	movzbl (%eax),%eax
  102457:	84 c0                	test   %al,%al
  102459:	75 ee                	jne    102449 <strlen+0xf>
		n++;
	return n;
  10245b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10245e:	c9                   	leave  
  10245f:	c3                   	ret    

00102460 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  102460:	55                   	push   %ebp
  102461:	89 e5                	mov    %esp,%ebp
  102463:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  102466:	8b 45 08             	mov    0x8(%ebp),%eax
  102469:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  10246c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10246f:	0f b6 10             	movzbl (%eax),%edx
  102472:	8b 45 08             	mov    0x8(%ebp),%eax
  102475:	88 10                	mov    %dl,(%eax)
  102477:	8b 45 08             	mov    0x8(%ebp),%eax
  10247a:	0f b6 00             	movzbl (%eax),%eax
  10247d:	84 c0                	test   %al,%al
  10247f:	0f 95 c0             	setne  %al
  102482:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102486:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10248a:	84 c0                	test   %al,%al
  10248c:	75 de                	jne    10246c <strcpy+0xc>
		/* do nothing */;
	return ret;
  10248e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102491:	c9                   	leave  
  102492:	c3                   	ret    

00102493 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  102493:	55                   	push   %ebp
  102494:	89 e5                	mov    %esp,%ebp
  102496:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  102499:	8b 45 08             	mov    0x8(%ebp),%eax
  10249c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  10249f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1024a6:	eb 21                	jmp    1024c9 <strncpy+0x36>
		*dst++ = *src;
  1024a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024ab:	0f b6 10             	movzbl (%eax),%edx
  1024ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1024b1:	88 10                	mov    %dl,(%eax)
  1024b3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  1024b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024ba:	0f b6 00             	movzbl (%eax),%eax
  1024bd:	84 c0                	test   %al,%al
  1024bf:	74 04                	je     1024c5 <strncpy+0x32>
			src++;
  1024c1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  1024c5:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1024c9:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1024cc:	3b 45 10             	cmp    0x10(%ebp),%eax
  1024cf:	72 d7                	jb     1024a8 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  1024d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1024d4:	c9                   	leave  
  1024d5:	c3                   	ret    

001024d6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  1024d6:	55                   	push   %ebp
  1024d7:	89 e5                	mov    %esp,%ebp
  1024d9:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  1024dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1024df:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  1024e2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1024e6:	74 2f                	je     102517 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  1024e8:	eb 13                	jmp    1024fd <strlcpy+0x27>
			*dst++ = *src++;
  1024ea:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024ed:	0f b6 10             	movzbl (%eax),%edx
  1024f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1024f3:	88 10                	mov    %dl,(%eax)
  1024f5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1024f9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  1024fd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102501:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102505:	74 0a                	je     102511 <strlcpy+0x3b>
  102507:	8b 45 0c             	mov    0xc(%ebp),%eax
  10250a:	0f b6 00             	movzbl (%eax),%eax
  10250d:	84 c0                	test   %al,%al
  10250f:	75 d9                	jne    1024ea <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  102511:	8b 45 08             	mov    0x8(%ebp),%eax
  102514:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  102517:	8b 55 08             	mov    0x8(%ebp),%edx
  10251a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10251d:	89 d1                	mov    %edx,%ecx
  10251f:	29 c1                	sub    %eax,%ecx
  102521:	89 c8                	mov    %ecx,%eax
}
  102523:	c9                   	leave  
  102524:	c3                   	ret    

00102525 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  102525:	55                   	push   %ebp
  102526:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  102528:	eb 08                	jmp    102532 <strcmp+0xd>
		p++, q++;
  10252a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10252e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  102532:	8b 45 08             	mov    0x8(%ebp),%eax
  102535:	0f b6 00             	movzbl (%eax),%eax
  102538:	84 c0                	test   %al,%al
  10253a:	74 10                	je     10254c <strcmp+0x27>
  10253c:	8b 45 08             	mov    0x8(%ebp),%eax
  10253f:	0f b6 10             	movzbl (%eax),%edx
  102542:	8b 45 0c             	mov    0xc(%ebp),%eax
  102545:	0f b6 00             	movzbl (%eax),%eax
  102548:	38 c2                	cmp    %al,%dl
  10254a:	74 de                	je     10252a <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  10254c:	8b 45 08             	mov    0x8(%ebp),%eax
  10254f:	0f b6 00             	movzbl (%eax),%eax
  102552:	0f b6 d0             	movzbl %al,%edx
  102555:	8b 45 0c             	mov    0xc(%ebp),%eax
  102558:	0f b6 00             	movzbl (%eax),%eax
  10255b:	0f b6 c0             	movzbl %al,%eax
  10255e:	89 d1                	mov    %edx,%ecx
  102560:	29 c1                	sub    %eax,%ecx
  102562:	89 c8                	mov    %ecx,%eax
}
  102564:	5d                   	pop    %ebp
  102565:	c3                   	ret    

00102566 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  102566:	55                   	push   %ebp
  102567:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  102569:	eb 0c                	jmp    102577 <strncmp+0x11>
		n--, p++, q++;
  10256b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10256f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102573:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  102577:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10257b:	74 1a                	je     102597 <strncmp+0x31>
  10257d:	8b 45 08             	mov    0x8(%ebp),%eax
  102580:	0f b6 00             	movzbl (%eax),%eax
  102583:	84 c0                	test   %al,%al
  102585:	74 10                	je     102597 <strncmp+0x31>
  102587:	8b 45 08             	mov    0x8(%ebp),%eax
  10258a:	0f b6 10             	movzbl (%eax),%edx
  10258d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102590:	0f b6 00             	movzbl (%eax),%eax
  102593:	38 c2                	cmp    %al,%dl
  102595:	74 d4                	je     10256b <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  102597:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10259b:	75 07                	jne    1025a4 <strncmp+0x3e>
		return 0;
  10259d:	b8 00 00 00 00       	mov    $0x0,%eax
  1025a2:	eb 18                	jmp    1025bc <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  1025a4:	8b 45 08             	mov    0x8(%ebp),%eax
  1025a7:	0f b6 00             	movzbl (%eax),%eax
  1025aa:	0f b6 d0             	movzbl %al,%edx
  1025ad:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025b0:	0f b6 00             	movzbl (%eax),%eax
  1025b3:	0f b6 c0             	movzbl %al,%eax
  1025b6:	89 d1                	mov    %edx,%ecx
  1025b8:	29 c1                	sub    %eax,%ecx
  1025ba:	89 c8                	mov    %ecx,%eax
}
  1025bc:	5d                   	pop    %ebp
  1025bd:	c3                   	ret    

001025be <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  1025be:	55                   	push   %ebp
  1025bf:	89 e5                	mov    %esp,%ebp
  1025c1:	83 ec 04             	sub    $0x4,%esp
  1025c4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025c7:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  1025ca:	eb 1a                	jmp    1025e6 <strchr+0x28>
		if (*s++ == 0)
  1025cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1025cf:	0f b6 00             	movzbl (%eax),%eax
  1025d2:	84 c0                	test   %al,%al
  1025d4:	0f 94 c0             	sete   %al
  1025d7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1025db:	84 c0                	test   %al,%al
  1025dd:	74 07                	je     1025e6 <strchr+0x28>
			return NULL;
  1025df:	b8 00 00 00 00       	mov    $0x0,%eax
  1025e4:	eb 0e                	jmp    1025f4 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  1025e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1025e9:	0f b6 00             	movzbl (%eax),%eax
  1025ec:	3a 45 fc             	cmp    -0x4(%ebp),%al
  1025ef:	75 db                	jne    1025cc <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  1025f1:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1025f4:	c9                   	leave  
  1025f5:	c3                   	ret    

001025f6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  1025f6:	55                   	push   %ebp
  1025f7:	89 e5                	mov    %esp,%ebp
  1025f9:	57                   	push   %edi
  1025fa:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  1025fd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102601:	75 05                	jne    102608 <memset+0x12>
		return v;
  102603:	8b 45 08             	mov    0x8(%ebp),%eax
  102606:	eb 5c                	jmp    102664 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  102608:	8b 45 08             	mov    0x8(%ebp),%eax
  10260b:	83 e0 03             	and    $0x3,%eax
  10260e:	85 c0                	test   %eax,%eax
  102610:	75 41                	jne    102653 <memset+0x5d>
  102612:	8b 45 10             	mov    0x10(%ebp),%eax
  102615:	83 e0 03             	and    $0x3,%eax
  102618:	85 c0                	test   %eax,%eax
  10261a:	75 37                	jne    102653 <memset+0x5d>
		c &= 0xFF;
  10261c:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  102623:	8b 45 0c             	mov    0xc(%ebp),%eax
  102626:	89 c2                	mov    %eax,%edx
  102628:	c1 e2 18             	shl    $0x18,%edx
  10262b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10262e:	c1 e0 10             	shl    $0x10,%eax
  102631:	09 c2                	or     %eax,%edx
  102633:	8b 45 0c             	mov    0xc(%ebp),%eax
  102636:	c1 e0 08             	shl    $0x8,%eax
  102639:	09 d0                	or     %edx,%eax
  10263b:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  10263e:	8b 45 10             	mov    0x10(%ebp),%eax
  102641:	89 c1                	mov    %eax,%ecx
  102643:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  102646:	8b 55 08             	mov    0x8(%ebp),%edx
  102649:	8b 45 0c             	mov    0xc(%ebp),%eax
  10264c:	89 d7                	mov    %edx,%edi
  10264e:	fc                   	cld    
  10264f:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  102651:	eb 0e                	jmp    102661 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  102653:	8b 55 08             	mov    0x8(%ebp),%edx
  102656:	8b 45 0c             	mov    0xc(%ebp),%eax
  102659:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10265c:	89 d7                	mov    %edx,%edi
  10265e:	fc                   	cld    
  10265f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  102661:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102664:	83 c4 10             	add    $0x10,%esp
  102667:	5f                   	pop    %edi
  102668:	5d                   	pop    %ebp
  102669:	c3                   	ret    

0010266a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  10266a:	55                   	push   %ebp
  10266b:	89 e5                	mov    %esp,%ebp
  10266d:	57                   	push   %edi
  10266e:	56                   	push   %esi
  10266f:	53                   	push   %ebx
  102670:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  102673:	8b 45 0c             	mov    0xc(%ebp),%eax
  102676:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  102679:	8b 45 08             	mov    0x8(%ebp),%eax
  10267c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  10267f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102682:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102685:	73 6e                	jae    1026f5 <memmove+0x8b>
  102687:	8b 45 10             	mov    0x10(%ebp),%eax
  10268a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10268d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102690:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102693:	76 60                	jbe    1026f5 <memmove+0x8b>
		s += n;
  102695:	8b 45 10             	mov    0x10(%ebp),%eax
  102698:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  10269b:	8b 45 10             	mov    0x10(%ebp),%eax
  10269e:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1026a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1026a4:	83 e0 03             	and    $0x3,%eax
  1026a7:	85 c0                	test   %eax,%eax
  1026a9:	75 2f                	jne    1026da <memmove+0x70>
  1026ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1026ae:	83 e0 03             	and    $0x3,%eax
  1026b1:	85 c0                	test   %eax,%eax
  1026b3:	75 25                	jne    1026da <memmove+0x70>
  1026b5:	8b 45 10             	mov    0x10(%ebp),%eax
  1026b8:	83 e0 03             	and    $0x3,%eax
  1026bb:	85 c0                	test   %eax,%eax
  1026bd:	75 1b                	jne    1026da <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  1026bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1026c2:	83 e8 04             	sub    $0x4,%eax
  1026c5:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1026c8:	83 ea 04             	sub    $0x4,%edx
  1026cb:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1026ce:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  1026d1:	89 c7                	mov    %eax,%edi
  1026d3:	89 d6                	mov    %edx,%esi
  1026d5:	fd                   	std    
  1026d6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1026d8:	eb 18                	jmp    1026f2 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  1026da:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1026dd:	8d 50 ff             	lea    -0x1(%eax),%edx
  1026e0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1026e3:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  1026e6:	8b 45 10             	mov    0x10(%ebp),%eax
  1026e9:	89 d7                	mov    %edx,%edi
  1026eb:	89 de                	mov    %ebx,%esi
  1026ed:	89 c1                	mov    %eax,%ecx
  1026ef:	fd                   	std    
  1026f0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  1026f2:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  1026f3:	eb 45                	jmp    10273a <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1026f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1026f8:	83 e0 03             	and    $0x3,%eax
  1026fb:	85 c0                	test   %eax,%eax
  1026fd:	75 2b                	jne    10272a <memmove+0xc0>
  1026ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102702:	83 e0 03             	and    $0x3,%eax
  102705:	85 c0                	test   %eax,%eax
  102707:	75 21                	jne    10272a <memmove+0xc0>
  102709:	8b 45 10             	mov    0x10(%ebp),%eax
  10270c:	83 e0 03             	and    $0x3,%eax
  10270f:	85 c0                	test   %eax,%eax
  102711:	75 17                	jne    10272a <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  102713:	8b 45 10             	mov    0x10(%ebp),%eax
  102716:	89 c1                	mov    %eax,%ecx
  102718:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  10271b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10271e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102721:	89 c7                	mov    %eax,%edi
  102723:	89 d6                	mov    %edx,%esi
  102725:	fc                   	cld    
  102726:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102728:	eb 10                	jmp    10273a <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  10272a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10272d:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102730:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102733:	89 c7                	mov    %eax,%edi
  102735:	89 d6                	mov    %edx,%esi
  102737:	fc                   	cld    
  102738:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  10273a:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10273d:	83 c4 10             	add    $0x10,%esp
  102740:	5b                   	pop    %ebx
  102741:	5e                   	pop    %esi
  102742:	5f                   	pop    %edi
  102743:	5d                   	pop    %ebp
  102744:	c3                   	ret    

00102745 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  102745:	55                   	push   %ebp
  102746:	89 e5                	mov    %esp,%ebp
  102748:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  10274b:	8b 45 10             	mov    0x10(%ebp),%eax
  10274e:	89 44 24 08          	mov    %eax,0x8(%esp)
  102752:	8b 45 0c             	mov    0xc(%ebp),%eax
  102755:	89 44 24 04          	mov    %eax,0x4(%esp)
  102759:	8b 45 08             	mov    0x8(%ebp),%eax
  10275c:	89 04 24             	mov    %eax,(%esp)
  10275f:	e8 06 ff ff ff       	call   10266a <memmove>
}
  102764:	c9                   	leave  
  102765:	c3                   	ret    

00102766 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  102766:	55                   	push   %ebp
  102767:	89 e5                	mov    %esp,%ebp
  102769:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  10276c:	8b 45 08             	mov    0x8(%ebp),%eax
  10276f:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  102772:	8b 45 0c             	mov    0xc(%ebp),%eax
  102775:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  102778:	eb 32                	jmp    1027ac <memcmp+0x46>
		if (*s1 != *s2)
  10277a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10277d:	0f b6 10             	movzbl (%eax),%edx
  102780:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102783:	0f b6 00             	movzbl (%eax),%eax
  102786:	38 c2                	cmp    %al,%dl
  102788:	74 1a                	je     1027a4 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  10278a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10278d:	0f b6 00             	movzbl (%eax),%eax
  102790:	0f b6 d0             	movzbl %al,%edx
  102793:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102796:	0f b6 00             	movzbl (%eax),%eax
  102799:	0f b6 c0             	movzbl %al,%eax
  10279c:	89 d1                	mov    %edx,%ecx
  10279e:	29 c1                	sub    %eax,%ecx
  1027a0:	89 c8                	mov    %ecx,%eax
  1027a2:	eb 1c                	jmp    1027c0 <memcmp+0x5a>
		s1++, s2++;
  1027a4:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1027a8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  1027ac:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1027b0:	0f 95 c0             	setne  %al
  1027b3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1027b7:	84 c0                	test   %al,%al
  1027b9:	75 bf                	jne    10277a <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  1027bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1027c0:	c9                   	leave  
  1027c1:	c3                   	ret    

001027c2 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  1027c2:	55                   	push   %ebp
  1027c3:	89 e5                	mov    %esp,%ebp
  1027c5:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  1027c8:	8b 45 10             	mov    0x10(%ebp),%eax
  1027cb:	8b 55 08             	mov    0x8(%ebp),%edx
  1027ce:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1027d1:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  1027d4:	eb 16                	jmp    1027ec <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  1027d6:	8b 45 08             	mov    0x8(%ebp),%eax
  1027d9:	0f b6 10             	movzbl (%eax),%edx
  1027dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027df:	38 c2                	cmp    %al,%dl
  1027e1:	75 05                	jne    1027e8 <memchr+0x26>
			return (void *) s;
  1027e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1027e6:	eb 11                	jmp    1027f9 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  1027e8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1027ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1027ef:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  1027f2:	72 e2                	jb     1027d6 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  1027f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1027f9:	c9                   	leave  
  1027fa:	c3                   	ret    
  1027fb:	66 90                	xchg   %ax,%ax
  1027fd:	66 90                	xchg   %ax,%ax
  1027ff:	90                   	nop

00102800 <__udivdi3>:
  102800:	55                   	push   %ebp
  102801:	89 e5                	mov    %esp,%ebp
  102803:	57                   	push   %edi
  102804:	56                   	push   %esi
  102805:	83 ec 10             	sub    $0x10,%esp
  102808:	8b 45 14             	mov    0x14(%ebp),%eax
  10280b:	8b 55 08             	mov    0x8(%ebp),%edx
  10280e:	8b 75 10             	mov    0x10(%ebp),%esi
  102811:	8b 7d 0c             	mov    0xc(%ebp),%edi
  102814:	85 c0                	test   %eax,%eax
  102816:	89 55 f0             	mov    %edx,-0x10(%ebp)
  102819:	75 35                	jne    102850 <__udivdi3+0x50>
  10281b:	39 fe                	cmp    %edi,%esi
  10281d:	77 61                	ja     102880 <__udivdi3+0x80>
  10281f:	85 f6                	test   %esi,%esi
  102821:	75 0b                	jne    10282e <__udivdi3+0x2e>
  102823:	b8 01 00 00 00       	mov    $0x1,%eax
  102828:	31 d2                	xor    %edx,%edx
  10282a:	f7 f6                	div    %esi
  10282c:	89 c6                	mov    %eax,%esi
  10282e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  102831:	31 d2                	xor    %edx,%edx
  102833:	89 f8                	mov    %edi,%eax
  102835:	f7 f6                	div    %esi
  102837:	89 c7                	mov    %eax,%edi
  102839:	89 c8                	mov    %ecx,%eax
  10283b:	f7 f6                	div    %esi
  10283d:	89 c1                	mov    %eax,%ecx
  10283f:	89 fa                	mov    %edi,%edx
  102841:	89 c8                	mov    %ecx,%eax
  102843:	83 c4 10             	add    $0x10,%esp
  102846:	5e                   	pop    %esi
  102847:	5f                   	pop    %edi
  102848:	5d                   	pop    %ebp
  102849:	c3                   	ret    
  10284a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102850:	39 f8                	cmp    %edi,%eax
  102852:	77 1c                	ja     102870 <__udivdi3+0x70>
  102854:	0f bd d0             	bsr    %eax,%edx
  102857:	83 f2 1f             	xor    $0x1f,%edx
  10285a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10285d:	75 39                	jne    102898 <__udivdi3+0x98>
  10285f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  102862:	0f 86 a0 00 00 00    	jbe    102908 <__udivdi3+0x108>
  102868:	39 f8                	cmp    %edi,%eax
  10286a:	0f 82 98 00 00 00    	jb     102908 <__udivdi3+0x108>
  102870:	31 ff                	xor    %edi,%edi
  102872:	31 c9                	xor    %ecx,%ecx
  102874:	89 c8                	mov    %ecx,%eax
  102876:	89 fa                	mov    %edi,%edx
  102878:	83 c4 10             	add    $0x10,%esp
  10287b:	5e                   	pop    %esi
  10287c:	5f                   	pop    %edi
  10287d:	5d                   	pop    %ebp
  10287e:	c3                   	ret    
  10287f:	90                   	nop
  102880:	89 d1                	mov    %edx,%ecx
  102882:	89 fa                	mov    %edi,%edx
  102884:	89 c8                	mov    %ecx,%eax
  102886:	31 ff                	xor    %edi,%edi
  102888:	f7 f6                	div    %esi
  10288a:	89 c1                	mov    %eax,%ecx
  10288c:	89 fa                	mov    %edi,%edx
  10288e:	89 c8                	mov    %ecx,%eax
  102890:	83 c4 10             	add    $0x10,%esp
  102893:	5e                   	pop    %esi
  102894:	5f                   	pop    %edi
  102895:	5d                   	pop    %ebp
  102896:	c3                   	ret    
  102897:	90                   	nop
  102898:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10289c:	89 f2                	mov    %esi,%edx
  10289e:	d3 e0                	shl    %cl,%eax
  1028a0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1028a3:	b8 20 00 00 00       	mov    $0x20,%eax
  1028a8:	2b 45 f4             	sub    -0xc(%ebp),%eax
  1028ab:	89 c1                	mov    %eax,%ecx
  1028ad:	d3 ea                	shr    %cl,%edx
  1028af:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  1028b3:	0b 55 ec             	or     -0x14(%ebp),%edx
  1028b6:	d3 e6                	shl    %cl,%esi
  1028b8:	89 c1                	mov    %eax,%ecx
  1028ba:	89 75 e8             	mov    %esi,-0x18(%ebp)
  1028bd:	89 fe                	mov    %edi,%esi
  1028bf:	d3 ee                	shr    %cl,%esi
  1028c1:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  1028c5:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1028c8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1028cb:	d3 e7                	shl    %cl,%edi
  1028cd:	89 c1                	mov    %eax,%ecx
  1028cf:	d3 ea                	shr    %cl,%edx
  1028d1:	09 d7                	or     %edx,%edi
  1028d3:	89 f2                	mov    %esi,%edx
  1028d5:	89 f8                	mov    %edi,%eax
  1028d7:	f7 75 ec             	divl   -0x14(%ebp)
  1028da:	89 d6                	mov    %edx,%esi
  1028dc:	89 c7                	mov    %eax,%edi
  1028de:	f7 65 e8             	mull   -0x18(%ebp)
  1028e1:	39 d6                	cmp    %edx,%esi
  1028e3:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1028e6:	72 30                	jb     102918 <__udivdi3+0x118>
  1028e8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1028eb:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  1028ef:	d3 e2                	shl    %cl,%edx
  1028f1:	39 c2                	cmp    %eax,%edx
  1028f3:	73 05                	jae    1028fa <__udivdi3+0xfa>
  1028f5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  1028f8:	74 1e                	je     102918 <__udivdi3+0x118>
  1028fa:	89 f9                	mov    %edi,%ecx
  1028fc:	31 ff                	xor    %edi,%edi
  1028fe:	e9 71 ff ff ff       	jmp    102874 <__udivdi3+0x74>
  102903:	90                   	nop
  102904:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102908:	31 ff                	xor    %edi,%edi
  10290a:	b9 01 00 00 00       	mov    $0x1,%ecx
  10290f:	e9 60 ff ff ff       	jmp    102874 <__udivdi3+0x74>
  102914:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102918:	8d 4f ff             	lea    -0x1(%edi),%ecx
  10291b:	31 ff                	xor    %edi,%edi
  10291d:	89 c8                	mov    %ecx,%eax
  10291f:	89 fa                	mov    %edi,%edx
  102921:	83 c4 10             	add    $0x10,%esp
  102924:	5e                   	pop    %esi
  102925:	5f                   	pop    %edi
  102926:	5d                   	pop    %ebp
  102927:	c3                   	ret    
  102928:	66 90                	xchg   %ax,%ax
  10292a:	66 90                	xchg   %ax,%ax
  10292c:	66 90                	xchg   %ax,%ax
  10292e:	66 90                	xchg   %ax,%ax

00102930 <__umoddi3>:
  102930:	55                   	push   %ebp
  102931:	89 e5                	mov    %esp,%ebp
  102933:	57                   	push   %edi
  102934:	56                   	push   %esi
  102935:	83 ec 20             	sub    $0x20,%esp
  102938:	8b 55 14             	mov    0x14(%ebp),%edx
  10293b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10293e:	8b 7d 10             	mov    0x10(%ebp),%edi
  102941:	8b 75 0c             	mov    0xc(%ebp),%esi
  102944:	85 d2                	test   %edx,%edx
  102946:	89 c8                	mov    %ecx,%eax
  102948:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  10294b:	75 13                	jne    102960 <__umoddi3+0x30>
  10294d:	39 f7                	cmp    %esi,%edi
  10294f:	76 3f                	jbe    102990 <__umoddi3+0x60>
  102951:	89 f2                	mov    %esi,%edx
  102953:	f7 f7                	div    %edi
  102955:	89 d0                	mov    %edx,%eax
  102957:	31 d2                	xor    %edx,%edx
  102959:	83 c4 20             	add    $0x20,%esp
  10295c:	5e                   	pop    %esi
  10295d:	5f                   	pop    %edi
  10295e:	5d                   	pop    %ebp
  10295f:	c3                   	ret    
  102960:	39 f2                	cmp    %esi,%edx
  102962:	77 4c                	ja     1029b0 <__umoddi3+0x80>
  102964:	0f bd ca             	bsr    %edx,%ecx
  102967:	83 f1 1f             	xor    $0x1f,%ecx
  10296a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  10296d:	75 51                	jne    1029c0 <__umoddi3+0x90>
  10296f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  102972:	0f 87 e0 00 00 00    	ja     102a58 <__umoddi3+0x128>
  102978:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10297b:	29 f8                	sub    %edi,%eax
  10297d:	19 d6                	sbb    %edx,%esi
  10297f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102982:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102985:	89 f2                	mov    %esi,%edx
  102987:	83 c4 20             	add    $0x20,%esp
  10298a:	5e                   	pop    %esi
  10298b:	5f                   	pop    %edi
  10298c:	5d                   	pop    %ebp
  10298d:	c3                   	ret    
  10298e:	66 90                	xchg   %ax,%ax
  102990:	85 ff                	test   %edi,%edi
  102992:	75 0b                	jne    10299f <__umoddi3+0x6f>
  102994:	b8 01 00 00 00       	mov    $0x1,%eax
  102999:	31 d2                	xor    %edx,%edx
  10299b:	f7 f7                	div    %edi
  10299d:	89 c7                	mov    %eax,%edi
  10299f:	89 f0                	mov    %esi,%eax
  1029a1:	31 d2                	xor    %edx,%edx
  1029a3:	f7 f7                	div    %edi
  1029a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1029a8:	f7 f7                	div    %edi
  1029aa:	eb a9                	jmp    102955 <__umoddi3+0x25>
  1029ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1029b0:	89 c8                	mov    %ecx,%eax
  1029b2:	89 f2                	mov    %esi,%edx
  1029b4:	83 c4 20             	add    $0x20,%esp
  1029b7:	5e                   	pop    %esi
  1029b8:	5f                   	pop    %edi
  1029b9:	5d                   	pop    %ebp
  1029ba:	c3                   	ret    
  1029bb:	90                   	nop
  1029bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1029c0:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1029c4:	d3 e2                	shl    %cl,%edx
  1029c6:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1029c9:	ba 20 00 00 00       	mov    $0x20,%edx
  1029ce:	2b 55 f0             	sub    -0x10(%ebp),%edx
  1029d1:	89 55 ec             	mov    %edx,-0x14(%ebp)
  1029d4:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1029d8:	89 fa                	mov    %edi,%edx
  1029da:	d3 ea                	shr    %cl,%edx
  1029dc:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1029e0:	0b 55 f4             	or     -0xc(%ebp),%edx
  1029e3:	d3 e7                	shl    %cl,%edi
  1029e5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1029e9:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1029ec:	89 f2                	mov    %esi,%edx
  1029ee:	89 7d e8             	mov    %edi,-0x18(%ebp)
  1029f1:	89 c7                	mov    %eax,%edi
  1029f3:	d3 ea                	shr    %cl,%edx
  1029f5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1029f9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1029fc:	89 c2                	mov    %eax,%edx
  1029fe:	d3 e6                	shl    %cl,%esi
  102a00:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102a04:	d3 ea                	shr    %cl,%edx
  102a06:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102a0a:	09 d6                	or     %edx,%esi
  102a0c:	89 f0                	mov    %esi,%eax
  102a0e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  102a11:	d3 e7                	shl    %cl,%edi
  102a13:	89 f2                	mov    %esi,%edx
  102a15:	f7 75 f4             	divl   -0xc(%ebp)
  102a18:	89 d6                	mov    %edx,%esi
  102a1a:	f7 65 e8             	mull   -0x18(%ebp)
  102a1d:	39 d6                	cmp    %edx,%esi
  102a1f:	72 2b                	jb     102a4c <__umoddi3+0x11c>
  102a21:	39 c7                	cmp    %eax,%edi
  102a23:	72 23                	jb     102a48 <__umoddi3+0x118>
  102a25:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102a29:	29 c7                	sub    %eax,%edi
  102a2b:	19 d6                	sbb    %edx,%esi
  102a2d:	89 f0                	mov    %esi,%eax
  102a2f:	89 f2                	mov    %esi,%edx
  102a31:	d3 ef                	shr    %cl,%edi
  102a33:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102a37:	d3 e0                	shl    %cl,%eax
  102a39:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102a3d:	09 f8                	or     %edi,%eax
  102a3f:	d3 ea                	shr    %cl,%edx
  102a41:	83 c4 20             	add    $0x20,%esp
  102a44:	5e                   	pop    %esi
  102a45:	5f                   	pop    %edi
  102a46:	5d                   	pop    %ebp
  102a47:	c3                   	ret    
  102a48:	39 d6                	cmp    %edx,%esi
  102a4a:	75 d9                	jne    102a25 <__umoddi3+0xf5>
  102a4c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  102a4f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  102a52:	eb d1                	jmp    102a25 <__umoddi3+0xf5>
  102a54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102a58:	39 f2                	cmp    %esi,%edx
  102a5a:	0f 82 18 ff ff ff    	jb     102978 <__umoddi3+0x48>
  102a60:	e9 1d ff ff ff       	jmp    102982 <__umoddi3+0x52>
