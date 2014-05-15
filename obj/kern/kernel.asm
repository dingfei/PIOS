
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
  100050:	c7 44 24 0c 60 2c 10 	movl   $0x102c60,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 76 2c 10 	movl   $0x102c76,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 8b 2c 10 00 	movl   $0x102c8b,(%esp)
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
  1000a0:	ba 04 70 10 00       	mov    $0x107004,%edx
  1000a5:	b8 b0 55 10 00       	mov    $0x1055b0,%eax
  1000aa:	89 d1                	mov    %edx,%ecx
  1000ac:	29 c1                	sub    %eax,%ecx
  1000ae:	89 c8                	mov    %ecx,%eax
  1000b0:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bb:	00 
  1000bc:	c7 04 24 b0 55 10 00 	movl   $0x1055b0,(%esp)
  1000c3:	e8 19 27 00 00       	call   1027e1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000c8:	e8 eb 01 00 00       	call   1002b8 <cons_init>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  1000cd:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  1000d4:	00 
  1000d5:	c7 04 24 98 2c 10 00 	movl   $0x102c98,(%esp)
  1000dc:	e8 1b 25 00 00       	call   1025fc <cprintf>
	debug_check();
  1000e1:	e8 ae 04 00 00       	call   100594 <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000e6:	e8 0d 0e 00 00       	call   100ef8 <cpu_init>
	trap_init();
  1000eb:	e8 0d 10 00 00       	call   1010fd <trap_init>

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
  100102:	c7 04 24 b3 2c 10 00 	movl   $0x102cb3,(%esp)
  100109:	e8 ee 24 00 00       	call   1025fc <cprintf>

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
  100116:	b8 c0 55 10 00       	mov    $0x1055c0,%eax
  10011b:	39 c2                	cmp    %eax,%edx
  10011d:	77 24                	ja     100143 <user+0x47>
  10011f:	c7 44 24 0c c0 2c 10 	movl   $0x102cc0,0xc(%esp)
  100126:	00 
  100127:	c7 44 24 08 76 2c 10 	movl   $0x102c76,0x8(%esp)
  10012e:	00 
  10012f:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100136:	00 
  100137:	c7 04 24 e7 2c 10 00 	movl   $0x102ce7,(%esp)
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
  10014b:	b8 c0 65 10 00       	mov    $0x1065c0,%eax
  100150:	39 c2                	cmp    %eax,%edx
  100152:	72 24                	jb     100178 <user+0x7c>
  100154:	c7 44 24 0c f4 2c 10 	movl   $0x102cf4,0xc(%esp)
  10015b:	00 
  10015c:	c7 44 24 08 76 2c 10 	movl   $0x102c76,0x8(%esp)
  100163:	00 
  100164:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  10016b:	00 
  10016c:	c7 04 24 e7 2c 10 00 	movl   $0x102ce7,(%esp)
  100173:	e8 b1 01 00 00       	call   100329 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  100178:	e8 86 12 00 00       	call   101403 <trap_check_user>

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
  1001b1:	c7 44 24 0c 2c 2d 10 	movl   $0x102d2c,0xc(%esp)
  1001b8:	00 
  1001b9:	c7 44 24 08 42 2d 10 	movl   $0x102d42,0x8(%esp)
  1001c0:	00 
  1001c1:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1001c8:	00 
  1001c9:	c7 04 24 57 2d 10 00 	movl   $0x102d57,(%esp)
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
  1001e5:	3d 00 40 10 00       	cmp    $0x104000,%eax
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
  100200:	a1 c4 67 10 00       	mov    0x1067c4,%eax
  100205:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100208:	88 90 c0 65 10 00    	mov    %dl,0x1065c0(%eax)
  10020e:	83 c0 01             	add    $0x1,%eax
  100211:	a3 c4 67 10 00       	mov    %eax,0x1067c4
		if (cons.wpos == CONSBUFSIZE)
  100216:	a1 c4 67 10 00       	mov    0x1067c4,%eax
  10021b:	3d 00 02 00 00       	cmp    $0x200,%eax
  100220:	75 0d                	jne    10022f <cons_intr+0x3d>
			cons.wpos = 0;
  100222:	c7 05 c4 67 10 00 00 	movl   $0x0,0x1067c4
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
  100245:	e8 45 1a 00 00       	call   101c8f <serial_intr>
	kbd_intr();
  10024a:	e8 9b 19 00 00       	call   101bea <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  10024f:	8b 15 c0 67 10 00    	mov    0x1067c0,%edx
  100255:	a1 c4 67 10 00       	mov    0x1067c4,%eax
  10025a:	39 c2                	cmp    %eax,%edx
  10025c:	74 35                	je     100293 <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  10025e:	a1 c0 67 10 00       	mov    0x1067c0,%eax
  100263:	0f b6 90 c0 65 10 00 	movzbl 0x1065c0(%eax),%edx
  10026a:	0f b6 d2             	movzbl %dl,%edx
  10026d:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100270:	83 c0 01             	add    $0x1,%eax
  100273:	a3 c0 67 10 00       	mov    %eax,0x1067c0
		if (cons.rpos == CONSBUFSIZE)
  100278:	a1 c0 67 10 00       	mov    0x1067c0,%eax
  10027d:	3d 00 02 00 00       	cmp    $0x200,%eax
  100282:	75 0a                	jne    10028e <cons_getc+0x4f>
			cons.rpos = 0;
  100284:	c7 05 c0 67 10 00 00 	movl   $0x0,0x1067c0
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
  1002a6:	e8 01 1a 00 00       	call   101cac <serial_putc>
	video_putc(c);
  1002ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1002ae:	89 04 24             	mov    %eax,(%esp)
  1002b1:	e8 93 15 00 00       	call   101849 <video_putc>
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
  1002c7:	e8 b1 14 00 00       	call   10177d <video_init>
	kbd_init();
  1002cc:	e8 2d 19 00 00       	call   101bfe <kbd_init>
	serial_init();
  1002d1:	e8 3b 1a 00 00       	call   101d11 <serial_init>

	if (!serial_exists)
  1002d6:	a1 00 70 10 00       	mov    0x107000,%eax
  1002db:	85 c0                	test   %eax,%eax
  1002dd:	75 1f                	jne    1002fe <cons_init+0x46>
		warn("Serial port does not exist!\n");
  1002df:	c7 44 24 08 64 2d 10 	movl   $0x102d64,0x8(%esp)
  1002e6:	00 
  1002e7:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  1002ee:	00 
  1002ef:	c7 04 24 81 2d 10 00 	movl   $0x102d81,(%esp)
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
  100340:	a1 c8 67 10 00       	mov    0x1067c8,%eax
  100345:	85 c0                	test   %eax,%eax
  100347:	0f 85 95 00 00 00    	jne    1003e2 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  10034d:	8b 45 10             	mov    0x10(%ebp),%eax
  100350:	a3 c8 67 10 00       	mov    %eax,0x1067c8
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
  10036c:	c7 04 24 8d 2d 10 00 	movl   $0x102d8d,(%esp)
  100373:	e8 84 22 00 00       	call   1025fc <cprintf>
	vcprintf(fmt, ap);
  100378:	8b 45 10             	mov    0x10(%ebp),%eax
  10037b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10037e:	89 54 24 04          	mov    %edx,0x4(%esp)
  100382:	89 04 24             	mov    %eax,(%esp)
  100385:	e8 09 22 00 00       	call   102593 <vcprintf>
	cprintf("\n");
  10038a:	c7 04 24 a5 2d 10 00 	movl   $0x102da5,(%esp)
  100391:	e8 66 22 00 00       	call   1025fc <cprintf>

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
  1003bf:	c7 04 24 a7 2d 10 00 	movl   $0x102da7,(%esp)
  1003c6:	e8 31 22 00 00       	call   1025fc <cprintf>
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
  100405:	c7 04 24 b4 2d 10 00 	movl   $0x102db4,(%esp)
  10040c:	e8 eb 21 00 00       	call   1025fc <cprintf>
	vcprintf(fmt, ap);
  100411:	8b 45 10             	mov    0x10(%ebp),%eax
  100414:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100417:	89 54 24 04          	mov    %edx,0x4(%esp)
  10041b:	89 04 24             	mov    %eax,(%esp)
  10041e:	e8 70 21 00 00       	call   102593 <vcprintf>
	cprintf("\n");
  100423:	c7 04 24 a5 2d 10 00 	movl   $0x102da5,(%esp)
  10042a:	e8 cd 21 00 00       	call   1025fc <cprintf>
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
  100444:	c7 04 24 ce 2d 10 00 	movl   $0x102dce,(%esp)
  10044b:	e8 ac 21 00 00       	call   1025fc <cprintf>

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
  10047d:	c7 04 24 e0 2d 10 00 	movl   $0x102de0,(%esp)
  100484:	e8 73 21 00 00       	call   1025fc <cprintf>

		int y = 0;
  100489:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

		cprintf(" args");
  100490:	c7 04 24 f6 2d 10 00 	movl   $0x102df6,(%esp)
  100497:	e8 60 21 00 00       	call   1025fc <cprintf>

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
  1004b0:	c7 04 24 fc 2d 10 00 	movl   $0x102dfc,(%esp)
  1004b7:	e8 40 21 00 00       	call   1025fc <cprintf>

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
  1004c6:	c7 04 24 a5 2d 10 00 	movl   $0x102da5,(%esp)
  1004cd:	e8 2a 21 00 00       	call   1025fc <cprintf>

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
  100617:	c7 44 24 0c 02 2e 10 	movl   $0x102e02,0xc(%esp)
  10061e:	00 
  10061f:	c7 44 24 08 1f 2e 10 	movl   $0x102e1f,0x8(%esp)
  100626:	00 
  100627:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
  10062e:	00 
  10062f:	c7 04 24 34 2e 10 00 	movl   $0x102e34,(%esp)
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
  100667:	c7 44 24 0c 41 2e 10 	movl   $0x102e41,0xc(%esp)
  10066e:	00 
  10066f:	c7 44 24 08 1f 2e 10 	movl   $0x102e1f,0x8(%esp)
  100676:	00 
  100677:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  10067e:	00 
  10067f:	c7 04 24 34 2e 10 00 	movl   $0x102e34,(%esp)
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
  1006b7:	c7 44 24 0c 5a 2e 10 	movl   $0x102e5a,0xc(%esp)
  1006be:	00 
  1006bf:	c7 44 24 08 1f 2e 10 	movl   $0x102e1f,0x8(%esp)
  1006c6:	00 
  1006c7:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
  1006ce:	00 
  1006cf:	c7 04 24 34 2e 10 00 	movl   $0x102e34,(%esp)
  1006d6:	e8 4e fc ff ff       	call   100329 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1006db:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1006de:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1006e1:	39 c2                	cmp    %eax,%edx
  1006e3:	74 24                	je     100709 <debug_check+0x175>
  1006e5:	c7 44 24 0c 73 2e 10 	movl   $0x102e73,0xc(%esp)
  1006ec:	00 
  1006ed:	c7 44 24 08 1f 2e 10 	movl   $0x102e1f,0x8(%esp)
  1006f4:	00 
  1006f5:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  1006fc:	00 
  1006fd:	c7 04 24 34 2e 10 00 	movl   $0x102e34,(%esp)
  100704:	e8 20 fc ff ff       	call   100329 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100709:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  10070f:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100712:	39 c2                	cmp    %eax,%edx
  100714:	75 24                	jne    10073a <debug_check+0x1a6>
  100716:	c7 44 24 0c 8c 2e 10 	movl   $0x102e8c,0xc(%esp)
  10071d:	00 
  10071e:	c7 44 24 08 1f 2e 10 	movl   $0x102e1f,0x8(%esp)
  100725:	00 
  100726:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  10072d:	00 
  10072e:	c7 04 24 34 2e 10 00 	movl   $0x102e34,(%esp)
  100735:	e8 ef fb ff ff       	call   100329 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10073a:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100740:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100743:	39 c2                	cmp    %eax,%edx
  100745:	74 24                	je     10076b <debug_check+0x1d7>
  100747:	c7 44 24 0c a5 2e 10 	movl   $0x102ea5,0xc(%esp)
  10074e:	00 
  10074f:	c7 44 24 08 1f 2e 10 	movl   $0x102e1f,0x8(%esp)
  100756:	00 
  100757:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  10075e:	00 
  10075f:	c7 04 24 34 2e 10 00 	movl   $0x102e34,(%esp)
  100766:	e8 be fb ff ff       	call   100329 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10076b:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100771:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100774:	39 c2                	cmp    %eax,%edx
  100776:	74 24                	je     10079c <debug_check+0x208>
  100778:	c7 44 24 0c be 2e 10 	movl   $0x102ebe,0xc(%esp)
  10077f:	00 
  100780:	c7 44 24 08 1f 2e 10 	movl   $0x102e1f,0x8(%esp)
  100787:	00 
  100788:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  10078f:	00 
  100790:	c7 04 24 34 2e 10 00 	movl   $0x102e34,(%esp)
  100797:	e8 8d fb ff ff       	call   100329 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10079c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1007a2:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1007a8:	39 c2                	cmp    %eax,%edx
  1007aa:	75 24                	jne    1007d0 <debug_check+0x23c>
  1007ac:	c7 44 24 0c d7 2e 10 	movl   $0x102ed7,0xc(%esp)
  1007b3:	00 
  1007b4:	c7 44 24 08 1f 2e 10 	movl   $0x102e1f,0x8(%esp)
  1007bb:	00 
  1007bc:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  1007c3:	00 
  1007c4:	c7 04 24 34 2e 10 00 	movl   $0x102e34,(%esp)
  1007cb:	e8 59 fb ff ff       	call   100329 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1007d0:	c7 04 24 f0 2e 10 00 	movl   $0x102ef0,(%esp)
  1007d7:	e8 20 1e 00 00       	call   1025fc <cprintf>
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
  100808:	c7 44 24 0c 0c 2f 10 	movl   $0x102f0c,0xc(%esp)
  10080f:	00 
  100810:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100817:	00 
  100818:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10081f:	00 
  100820:	c7 04 24 37 2f 10 00 	movl   $0x102f37,(%esp)
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
  10083c:	3d 00 40 10 00       	cmp    $0x104000,%eax
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
  100863:	e8 ae 15 00 00       	call   101e16 <nvram_read16>
  100868:	c1 e0 0a             	shl    $0xa,%eax
  10086b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10086e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100871:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100876:	89 45 e0             	mov    %eax,-0x20(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100879:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100880:	e8 91 15 00 00       	call   101e16 <nvram_read16>
  100885:	c1 e0 0a             	shl    $0xa,%eax
  100888:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10088b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10088e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100893:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	warn("Assuming we have 1GB of memory!");
  100896:	c7 44 24 08 44 2f 10 	movl   $0x102f44,0x8(%esp)
  10089d:	00 
  10089e:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  1008a5:	00 
  1008a6:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  1008ad:	e8 36 fb ff ff       	call   1003e8 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1008b2:	c7 45 e4 00 00 f0 3f 	movl   $0x3ff00000,-0x1c(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1008b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1008bc:	05 00 00 10 00       	add    $0x100000,%eax
  1008c1:	a3 f8 6f 10 00       	mov    %eax,0x106ff8

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1008c6:	a1 f8 6f 10 00       	mov    0x106ff8,%eax
  1008cb:	c1 e8 0c             	shr    $0xc,%eax
  1008ce:	a3 f4 6f 10 00       	mov    %eax,0x106ff4

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  1008d3:	a1 f8 6f 10 00       	mov    0x106ff8,%eax
  1008d8:	c1 e8 0a             	shr    $0xa,%eax
  1008db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1008df:	c7 04 24 70 2f 10 00 	movl   $0x102f70,(%esp)
  1008e6:	e8 11 1d 00 00       	call   1025fc <cprintf>
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
  100901:	c7 04 24 91 2f 10 00 	movl   $0x102f91,(%esp)
  100908:	e8 ef 1c 00 00       	call   1025fc <cprintf>
	//     Some of it is in use, some is free.
	//     Which pages hold the kernel and the pageinfo array?
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
  10090d:	c7 45 e8 f0 6f 10 00 	movl   $0x106ff0,-0x18(%ebp)
	int i;
	for (i = 0; i < mem_npage; i++) {
  100914:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  10091b:	eb 3b                	jmp    100958 <mem_init+0x10f>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  10091d:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100922:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100925:	c1 e2 03             	shl    $0x3,%edx
  100928:	01 d0                	add    %edx,%eax
  10092a:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100931:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100936:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100939:	c1 e2 03             	shl    $0x3,%edx
  10093c:	8d 14 10             	lea    (%eax,%edx,1),%edx
  10093f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100942:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100944:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
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
  10095b:	a1 f4 6f 10 00       	mov    0x106ff4,%eax
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
  10096d:	c7 44 24 08 ad 2f 10 	movl   $0x102fad,0x8(%esp)
  100974:	00 
  100975:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  10097c:	00 
  10097d:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
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
  100991:	c7 44 24 08 c8 2f 10 	movl   $0x102fc8,0x8(%esp)
  100998:	00 
  100999:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  1009a0:	00 
  1009a1:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
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
  1009b3:	c7 44 24 08 e3 2f 10 	movl   $0x102fe3,0x8(%esp)
  1009ba:	00 
  1009bb:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  1009c2:	00 
  1009c3:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
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
  1009dc:	a1 f0 6f 10 00       	mov    0x106ff0,%eax
  1009e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1009e4:	eb 38                	jmp    100a1e <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  1009e6:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1009e9:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
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
  100a0d:	e8 cf 1d 00 00       	call   1027e1 <memset>
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
  100a2b:	c7 04 24 fd 2f 10 00 	movl   $0x102ffd,(%esp)
  100a32:	e8 c5 1b 00 00       	call   1025fc <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100a37:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100a3a:	a1 f4 6f 10 00       	mov    0x106ff4,%eax
  100a3f:	39 c2                	cmp    %eax,%edx
  100a41:	72 24                	jb     100a67 <mem_check+0x98>
  100a43:	c7 44 24 0c 17 30 10 	movl   $0x103017,0xc(%esp)
  100a4a:	00 
  100a4b:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100a52:	00 
  100a53:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100a5a:	00 
  100a5b:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100a62:	e8 c2 f8 ff ff       	call   100329 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100a67:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100a6e:	7f 24                	jg     100a94 <mem_check+0xc5>
  100a70:	c7 44 24 0c 2d 30 10 	movl   $0x10302d,0xc(%esp)
  100a77:	00 
  100a78:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100a7f:	00 
  100a80:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
  100a87:	00 
  100a88:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
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
  100ab5:	c7 44 24 0c 3f 30 10 	movl   $0x10303f,0xc(%esp)
  100abc:	00 
  100abd:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100ac4:	00 
  100ac5:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  100acc:	00 
  100acd:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100ad4:	e8 50 f8 ff ff       	call   100329 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100ad9:	e8 ad fe ff ff       	call   10098b <mem_alloc>
  100ade:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100ae1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100ae5:	75 24                	jne    100b0b <mem_check+0x13c>
  100ae7:	c7 44 24 0c 48 30 10 	movl   $0x103048,0xc(%esp)
  100aee:	00 
  100aef:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100af6:	00 
  100af7:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100afe:	00 
  100aff:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100b06:	e8 1e f8 ff ff       	call   100329 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100b0b:	e8 7b fe ff ff       	call   10098b <mem_alloc>
  100b10:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100b13:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100b17:	75 24                	jne    100b3d <mem_check+0x16e>
  100b19:	c7 44 24 0c 51 30 10 	movl   $0x103051,0xc(%esp)
  100b20:	00 
  100b21:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100b28:	00 
  100b29:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  100b30:	00 
  100b31:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100b38:	e8 ec f7 ff ff       	call   100329 <debug_panic>

	assert(pp0);
  100b3d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100b41:	75 24                	jne    100b67 <mem_check+0x198>
  100b43:	c7 44 24 0c 5a 30 10 	movl   $0x10305a,0xc(%esp)
  100b4a:	00 
  100b4b:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100b52:	00 
  100b53:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  100b5a:	00 
  100b5b:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100b62:	e8 c2 f7 ff ff       	call   100329 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100b67:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100b6b:	74 08                	je     100b75 <mem_check+0x1a6>
  100b6d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100b70:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100b73:	75 24                	jne    100b99 <mem_check+0x1ca>
  100b75:	c7 44 24 0c 5e 30 10 	movl   $0x10305e,0xc(%esp)
  100b7c:	00 
  100b7d:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100b84:	00 
  100b85:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100b8c:	00 
  100b8d:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
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
  100baf:	c7 44 24 0c 70 30 10 	movl   $0x103070,0xc(%esp)
  100bb6:	00 
  100bb7:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100bbe:	00 
  100bbf:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  100bc6:	00 
  100bc7:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100bce:	e8 56 f7 ff ff       	call   100329 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100bd3:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100bd6:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100bdb:	89 d1                	mov    %edx,%ecx
  100bdd:	29 c1                	sub    %eax,%ecx
  100bdf:	89 c8                	mov    %ecx,%eax
  100be1:	c1 f8 03             	sar    $0x3,%eax
  100be4:	c1 e0 0c             	shl    $0xc,%eax
  100be7:	8b 15 f4 6f 10 00    	mov    0x106ff4,%edx
  100bed:	c1 e2 0c             	shl    $0xc,%edx
  100bf0:	39 d0                	cmp    %edx,%eax
  100bf2:	72 24                	jb     100c18 <mem_check+0x249>
  100bf4:	c7 44 24 0c 90 30 10 	movl   $0x103090,0xc(%esp)
  100bfb:	00 
  100bfc:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100c03:	00 
  100c04:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100c0b:	00 
  100c0c:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100c13:	e8 11 f7 ff ff       	call   100329 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100c18:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100c1b:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100c20:	89 d1                	mov    %edx,%ecx
  100c22:	29 c1                	sub    %eax,%ecx
  100c24:	89 c8                	mov    %ecx,%eax
  100c26:	c1 f8 03             	sar    $0x3,%eax
  100c29:	c1 e0 0c             	shl    $0xc,%eax
  100c2c:	8b 15 f4 6f 10 00    	mov    0x106ff4,%edx
  100c32:	c1 e2 0c             	shl    $0xc,%edx
  100c35:	39 d0                	cmp    %edx,%eax
  100c37:	72 24                	jb     100c5d <mem_check+0x28e>
  100c39:	c7 44 24 0c b8 30 10 	movl   $0x1030b8,0xc(%esp)
  100c40:	00 
  100c41:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100c48:	00 
  100c49:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100c50:	00 
  100c51:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100c58:	e8 cc f6 ff ff       	call   100329 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100c5d:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100c60:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100c65:	89 d1                	mov    %edx,%ecx
  100c67:	29 c1                	sub    %eax,%ecx
  100c69:	89 c8                	mov    %ecx,%eax
  100c6b:	c1 f8 03             	sar    $0x3,%eax
  100c6e:	c1 e0 0c             	shl    $0xc,%eax
  100c71:	8b 15 f4 6f 10 00    	mov    0x106ff4,%edx
  100c77:	c1 e2 0c             	shl    $0xc,%edx
  100c7a:	39 d0                	cmp    %edx,%eax
  100c7c:	72 24                	jb     100ca2 <mem_check+0x2d3>
  100c7e:	c7 44 24 0c e0 30 10 	movl   $0x1030e0,0xc(%esp)
  100c85:	00 
  100c86:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100c8d:	00 
  100c8e:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100c95:	00 
  100c96:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100c9d:	e8 87 f6 ff ff       	call   100329 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100ca2:	a1 f0 6f 10 00       	mov    0x106ff0,%eax
  100ca7:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100caa:	c7 05 f0 6f 10 00 00 	movl   $0x0,0x106ff0
  100cb1:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100cb4:	e8 d2 fc ff ff       	call   10098b <mem_alloc>
  100cb9:	85 c0                	test   %eax,%eax
  100cbb:	74 24                	je     100ce1 <mem_check+0x312>
  100cbd:	c7 44 24 0c 06 31 10 	movl   $0x103106,0xc(%esp)
  100cc4:	00 
  100cc5:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100ccc:	00 
  100ccd:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  100cd4:	00 
  100cd5:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
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
  100d23:	c7 44 24 0c 3f 30 10 	movl   $0x10303f,0xc(%esp)
  100d2a:	00 
  100d2b:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100d32:	00 
  100d33:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  100d3a:	00 
  100d3b:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100d42:	e8 e2 f5 ff ff       	call   100329 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100d47:	e8 3f fc ff ff       	call   10098b <mem_alloc>
  100d4c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d4f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d53:	75 24                	jne    100d79 <mem_check+0x3aa>
  100d55:	c7 44 24 0c 48 30 10 	movl   $0x103048,0xc(%esp)
  100d5c:	00 
  100d5d:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100d64:	00 
  100d65:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  100d6c:	00 
  100d6d:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100d74:	e8 b0 f5 ff ff       	call   100329 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100d79:	e8 0d fc ff ff       	call   10098b <mem_alloc>
  100d7e:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100d81:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d85:	75 24                	jne    100dab <mem_check+0x3dc>
  100d87:	c7 44 24 0c 51 30 10 	movl   $0x103051,0xc(%esp)
  100d8e:	00 
  100d8f:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100d96:	00 
  100d97:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  100d9e:	00 
  100d9f:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100da6:	e8 7e f5 ff ff       	call   100329 <debug_panic>
	assert(pp0);
  100dab:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100daf:	75 24                	jne    100dd5 <mem_check+0x406>
  100db1:	c7 44 24 0c 5a 30 10 	movl   $0x10305a,0xc(%esp)
  100db8:	00 
  100db9:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100dc0:	00 
  100dc1:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
  100dc8:	00 
  100dc9:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100dd0:	e8 54 f5 ff ff       	call   100329 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100dd5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100dd9:	74 08                	je     100de3 <mem_check+0x414>
  100ddb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100dde:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100de1:	75 24                	jne    100e07 <mem_check+0x438>
  100de3:	c7 44 24 0c 5e 30 10 	movl   $0x10305e,0xc(%esp)
  100dea:	00 
  100deb:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100df2:	00 
  100df3:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  100dfa:	00 
  100dfb:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
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
  100e1d:	c7 44 24 0c 70 30 10 	movl   $0x103070,0xc(%esp)
  100e24:	00 
  100e25:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100e2c:	00 
  100e2d:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  100e34:	00 
  100e35:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100e3c:	e8 e8 f4 ff ff       	call   100329 <debug_panic>
	assert(mem_alloc() == 0);
  100e41:	e8 45 fb ff ff       	call   10098b <mem_alloc>
  100e46:	85 c0                	test   %eax,%eax
  100e48:	74 24                	je     100e6e <mem_check+0x49f>
  100e4a:	c7 44 24 0c 06 31 10 	movl   $0x103106,0xc(%esp)
  100e51:	00 
  100e52:	c7 44 24 08 22 2f 10 	movl   $0x102f22,0x8(%esp)
  100e59:	00 
  100e5a:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  100e61:	00 
  100e62:	c7 04 24 64 2f 10 00 	movl   $0x102f64,(%esp)
  100e69:	e8 bb f4 ff ff       	call   100329 <debug_panic>

	// give free list back
	mem_freelist = fl;
  100e6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e71:	a3 f0 6f 10 00       	mov    %eax,0x106ff0

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
  100e97:	c7 04 24 17 31 10 00 	movl   $0x103117,(%esp)
  100e9e:	e8 59 17 00 00       	call   1025fc <cprintf>
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
  100ecf:	c7 44 24 0c 2f 31 10 	movl   $0x10312f,0xc(%esp)
  100ed6:	00 
  100ed7:	c7 44 24 08 45 31 10 	movl   $0x103145,0x8(%esp)
  100ede:	00 
  100edf:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100ee6:	00 
  100ee7:	c7 04 24 5a 31 10 00 	movl   $0x10315a,(%esp)
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
	//asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
	//asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  100f16:	b8 10 00 00 00       	mov    $0x10,%eax
  100f1b:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  100f1d:	b8 10 00 00 00       	mov    $0x10,%eax
  100f22:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  100f24:	b8 10 00 00 00       	mov    $0x10,%eax
  100f29:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  100f2b:	ea 32 0f 10 00 08 00 	ljmp   $0x8,$0x100f32

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  100f32:	b8 00 00 00 00       	mov    $0x0,%eax
  100f37:	0f 00 d0             	lldt   %ax
}
  100f3a:	c9                   	leave  
  100f3b:	c3                   	ret    

00100f3c <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100f3c:	55                   	push   %ebp
  100f3d:	89 e5                	mov    %esp,%ebp
  100f3f:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100f42:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100f45:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100f48:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100f4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f4e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100f53:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100f56:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100f59:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100f5f:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100f64:	74 24                	je     100f8a <cpu_cur+0x4e>
  100f66:	c7 44 24 0c 80 31 10 	movl   $0x103180,0xc(%esp)
  100f6d:	00 
  100f6e:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  100f75:	00 
  100f76:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100f7d:	00 
  100f7e:	c7 04 24 ab 31 10 00 	movl   $0x1031ab,(%esp)
  100f85:	e8 9f f3 ff ff       	call   100329 <debug_panic>
	return c;
  100f8a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100f8d:	c9                   	leave  
  100f8e:	c3                   	ret    

00100f8f <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100f8f:	55                   	push   %ebp
  100f90:	89 e5                	mov    %esp,%ebp
  100f92:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100f95:	e8 a2 ff ff ff       	call   100f3c <cpu_cur>
  100f9a:	3d 00 40 10 00       	cmp    $0x104000,%eax
  100f9f:	0f 94 c0             	sete   %al
  100fa2:	0f b6 c0             	movzbl %al,%eax
}
  100fa5:	c9                   	leave  
  100fa6:	c3                   	ret    

00100fa7 <trap_init_idt>:

extern uint32_t vectors[];

static void
trap_init_idt(void)
{
  100fa7:	55                   	push   %ebp
  100fa8:	89 e5                	mov    %esp,%ebp
  100faa:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  100fad:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  100fb4:	e9 bc 00 00 00       	jmp    101075 <trap_init_idt+0xce>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 0);
  100fb9:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100fbc:	8b 55 fc             	mov    -0x4(%ebp),%edx
  100fbf:	8b 14 95 10 50 10 00 	mov    0x105010(,%edx,4),%edx
  100fc6:	66 89 14 c5 e0 67 10 	mov    %dx,0x1067e0(,%eax,8)
  100fcd:	00 
  100fce:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100fd1:	66 c7 04 c5 e2 67 10 	movw   $0x8,0x1067e2(,%eax,8)
  100fd8:	00 08 00 
  100fdb:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100fde:	0f b6 14 c5 e4 67 10 	movzbl 0x1067e4(,%eax,8),%edx
  100fe5:	00 
  100fe6:	83 e2 e0             	and    $0xffffffe0,%edx
  100fe9:	88 14 c5 e4 67 10 00 	mov    %dl,0x1067e4(,%eax,8)
  100ff0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100ff3:	0f b6 14 c5 e4 67 10 	movzbl 0x1067e4(,%eax,8),%edx
  100ffa:	00 
  100ffb:	83 e2 1f             	and    $0x1f,%edx
  100ffe:	88 14 c5 e4 67 10 00 	mov    %dl,0x1067e4(,%eax,8)
  101005:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101008:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  10100f:	00 
  101010:	83 ca 0f             	or     $0xf,%edx
  101013:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  10101a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10101d:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  101024:	00 
  101025:	83 e2 ef             	and    $0xffffffef,%edx
  101028:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  10102f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101032:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  101039:	00 
  10103a:	83 e2 9f             	and    $0xffffff9f,%edx
  10103d:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  101044:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101047:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  10104e:	00 
  10104f:	83 ca 80             	or     $0xffffff80,%edx
  101052:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  101059:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10105c:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10105f:	8b 14 95 10 50 10 00 	mov    0x105010(,%edx,4),%edx
  101066:	c1 ea 10             	shr    $0x10,%edx
  101069:	66 89 14 c5 e6 67 10 	mov    %dx,0x1067e6(,%eax,8)
  101070:	00 
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  101071:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  101075:	83 7d fc 13          	cmpl   $0x13,-0x4(%ebp)
  101079:	0f 8e 3a ff ff ff    	jle    100fb9 <trap_init_idt+0x12>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 0);
	}
	SETGATE(idt[30], 1, CPU_GDT_KCODE, vectors[30], 0);
  10107f:	a1 88 50 10 00       	mov    0x105088,%eax
  101084:	66 a3 d0 68 10 00    	mov    %ax,0x1068d0
  10108a:	66 c7 05 d2 68 10 00 	movw   $0x8,0x1068d2
  101091:	08 00 
  101093:	0f b6 05 d4 68 10 00 	movzbl 0x1068d4,%eax
  10109a:	83 e0 e0             	and    $0xffffffe0,%eax
  10109d:	a2 d4 68 10 00       	mov    %al,0x1068d4
  1010a2:	0f b6 05 d4 68 10 00 	movzbl 0x1068d4,%eax
  1010a9:	83 e0 1f             	and    $0x1f,%eax
  1010ac:	a2 d4 68 10 00       	mov    %al,0x1068d4
  1010b1:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1010b8:	83 c8 0f             	or     $0xf,%eax
  1010bb:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1010c0:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1010c7:	83 e0 ef             	and    $0xffffffef,%eax
  1010ca:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1010cf:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1010d6:	83 e0 9f             	and    $0xffffff9f,%eax
  1010d9:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1010de:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1010e5:	83 c8 80             	or     $0xffffff80,%eax
  1010e8:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1010ed:	a1 88 50 10 00       	mov    0x105088,%eax
  1010f2:	c1 e8 10             	shr    $0x10,%eax
  1010f5:	66 a3 d6 68 10 00    	mov    %ax,0x1068d6
}
  1010fb:	c9                   	leave  
  1010fc:	c3                   	ret    

001010fd <trap_init>:

void
trap_init(void)
{
  1010fd:	55                   	push   %ebp
  1010fe:	89 e5                	mov    %esp,%ebp
  101100:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  101103:	e8 87 fe ff ff       	call   100f8f <cpu_onboot>
  101108:	85 c0                	test   %eax,%eax
  10110a:	74 05                	je     101111 <trap_init+0x14>
		trap_init_idt();
  10110c:	e8 96 fe ff ff       	call   100fa7 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  101111:	0f 01 1d 00 50 10 00 	lidtl  0x105000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  101118:	e8 72 fe ff ff       	call   100f8f <cpu_onboot>
  10111d:	85 c0                	test   %eax,%eax
  10111f:	74 05                	je     101126 <trap_init+0x29>
		trap_check_kernel();
  101121:	e8 62 02 00 00       	call   101388 <trap_check_kernel>
}
  101126:	c9                   	leave  
  101127:	c3                   	ret    

00101128 <trap_name>:

const char *trap_name(int trapno)
{
  101128:	55                   	push   %ebp
  101129:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  10112b:	8b 45 08             	mov    0x8(%ebp),%eax
  10112e:	83 f8 13             	cmp    $0x13,%eax
  101131:	77 0c                	ja     10113f <trap_name+0x17>
		return excnames[trapno];
  101133:	8b 45 08             	mov    0x8(%ebp),%eax
  101136:	8b 04 85 60 35 10 00 	mov    0x103560(,%eax,4),%eax
  10113d:	eb 05                	jmp    101144 <trap_name+0x1c>
	return "(unknown trap)";
  10113f:	b8 b8 31 10 00       	mov    $0x1031b8,%eax
}
  101144:	5d                   	pop    %ebp
  101145:	c3                   	ret    

00101146 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101146:	55                   	push   %ebp
  101147:	89 e5                	mov    %esp,%ebp
  101149:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  10114c:	8b 45 08             	mov    0x8(%ebp),%eax
  10114f:	8b 00                	mov    (%eax),%eax
  101151:	89 44 24 04          	mov    %eax,0x4(%esp)
  101155:	c7 04 24 c7 31 10 00 	movl   $0x1031c7,(%esp)
  10115c:	e8 9b 14 00 00       	call   1025fc <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  101161:	8b 45 08             	mov    0x8(%ebp),%eax
  101164:	8b 40 04             	mov    0x4(%eax),%eax
  101167:	89 44 24 04          	mov    %eax,0x4(%esp)
  10116b:	c7 04 24 d6 31 10 00 	movl   $0x1031d6,(%esp)
  101172:	e8 85 14 00 00       	call   1025fc <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101177:	8b 45 08             	mov    0x8(%ebp),%eax
  10117a:	8b 40 08             	mov    0x8(%eax),%eax
  10117d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101181:	c7 04 24 e5 31 10 00 	movl   $0x1031e5,(%esp)
  101188:	e8 6f 14 00 00       	call   1025fc <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  10118d:	8b 45 08             	mov    0x8(%ebp),%eax
  101190:	8b 40 10             	mov    0x10(%eax),%eax
  101193:	89 44 24 04          	mov    %eax,0x4(%esp)
  101197:	c7 04 24 f4 31 10 00 	movl   $0x1031f4,(%esp)
  10119e:	e8 59 14 00 00       	call   1025fc <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  1011a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1011a6:	8b 40 14             	mov    0x14(%eax),%eax
  1011a9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011ad:	c7 04 24 03 32 10 00 	movl   $0x103203,(%esp)
  1011b4:	e8 43 14 00 00       	call   1025fc <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  1011b9:	8b 45 08             	mov    0x8(%ebp),%eax
  1011bc:	8b 40 18             	mov    0x18(%eax),%eax
  1011bf:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011c3:	c7 04 24 12 32 10 00 	movl   $0x103212,(%esp)
  1011ca:	e8 2d 14 00 00       	call   1025fc <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1011cf:	8b 45 08             	mov    0x8(%ebp),%eax
  1011d2:	8b 40 1c             	mov    0x1c(%eax),%eax
  1011d5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011d9:	c7 04 24 21 32 10 00 	movl   $0x103221,(%esp)
  1011e0:	e8 17 14 00 00       	call   1025fc <cprintf>
}
  1011e5:	c9                   	leave  
  1011e6:	c3                   	ret    

001011e7 <trap_print>:

void
trap_print(trapframe *tf)
{
  1011e7:	55                   	push   %ebp
  1011e8:	89 e5                	mov    %esp,%ebp
  1011ea:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  1011ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1011f0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011f4:	c7 04 24 30 32 10 00 	movl   $0x103230,(%esp)
  1011fb:	e8 fc 13 00 00       	call   1025fc <cprintf>
	trap_print_regs(&tf->regs);
  101200:	8b 45 08             	mov    0x8(%ebp),%eax
  101203:	89 04 24             	mov    %eax,(%esp)
  101206:	e8 3b ff ff ff       	call   101146 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  10120b:	8b 45 08             	mov    0x8(%ebp),%eax
  10120e:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101212:	0f b7 c0             	movzwl %ax,%eax
  101215:	89 44 24 04          	mov    %eax,0x4(%esp)
  101219:	c7 04 24 42 32 10 00 	movl   $0x103242,(%esp)
  101220:	e8 d7 13 00 00       	call   1025fc <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101225:	8b 45 08             	mov    0x8(%ebp),%eax
  101228:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10122c:	0f b7 c0             	movzwl %ax,%eax
  10122f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101233:	c7 04 24 55 32 10 00 	movl   $0x103255,(%esp)
  10123a:	e8 bd 13 00 00       	call   1025fc <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  10123f:	8b 45 08             	mov    0x8(%ebp),%eax
  101242:	8b 40 30             	mov    0x30(%eax),%eax
  101245:	89 04 24             	mov    %eax,(%esp)
  101248:	e8 db fe ff ff       	call   101128 <trap_name>
  10124d:	8b 55 08             	mov    0x8(%ebp),%edx
  101250:	8b 52 30             	mov    0x30(%edx),%edx
  101253:	89 44 24 08          	mov    %eax,0x8(%esp)
  101257:	89 54 24 04          	mov    %edx,0x4(%esp)
  10125b:	c7 04 24 68 32 10 00 	movl   $0x103268,(%esp)
  101262:	e8 95 13 00 00       	call   1025fc <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101267:	8b 45 08             	mov    0x8(%ebp),%eax
  10126a:	8b 40 34             	mov    0x34(%eax),%eax
  10126d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101271:	c7 04 24 7a 32 10 00 	movl   $0x10327a,(%esp)
  101278:	e8 7f 13 00 00       	call   1025fc <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  10127d:	8b 45 08             	mov    0x8(%ebp),%eax
  101280:	8b 40 38             	mov    0x38(%eax),%eax
  101283:	89 44 24 04          	mov    %eax,0x4(%esp)
  101287:	c7 04 24 89 32 10 00 	movl   $0x103289,(%esp)
  10128e:	e8 69 13 00 00       	call   1025fc <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101293:	8b 45 08             	mov    0x8(%ebp),%eax
  101296:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10129a:	0f b7 c0             	movzwl %ax,%eax
  10129d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012a1:	c7 04 24 98 32 10 00 	movl   $0x103298,(%esp)
  1012a8:	e8 4f 13 00 00       	call   1025fc <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  1012ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1012b0:	8b 40 40             	mov    0x40(%eax),%eax
  1012b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012b7:	c7 04 24 ab 32 10 00 	movl   $0x1032ab,(%esp)
  1012be:	e8 39 13 00 00       	call   1025fc <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1012c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1012c6:	8b 40 44             	mov    0x44(%eax),%eax
  1012c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012cd:	c7 04 24 ba 32 10 00 	movl   $0x1032ba,(%esp)
  1012d4:	e8 23 13 00 00       	call   1025fc <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1012d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1012dc:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1012e0:	0f b7 c0             	movzwl %ax,%eax
  1012e3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012e7:	c7 04 24 c9 32 10 00 	movl   $0x1032c9,(%esp)
  1012ee:	e8 09 13 00 00       	call   1025fc <cprintf>
}
  1012f3:	c9                   	leave  
  1012f4:	c3                   	ret    

001012f5 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  1012f5:	55                   	push   %ebp
  1012f6:	89 e5                	mov    %esp,%ebp
  1012f8:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  1012fb:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  1012fc:	e8 3b fc ff ff       	call   100f3c <cpu_cur>
  101301:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  101304:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101307:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10130d:	85 c0                	test   %eax,%eax
  10130f:	74 1e                	je     10132f <trap+0x3a>
		c->recover(tf, c->recoverdata);
  101311:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101314:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  10131a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10131d:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  101323:	89 44 24 04          	mov    %eax,0x4(%esp)
  101327:	8b 45 08             	mov    0x8(%ebp),%eax
  10132a:	89 04 24             	mov    %eax,(%esp)
  10132d:	ff d2                	call   *%edx

	trap_print(tf);
  10132f:	8b 45 08             	mov    0x8(%ebp),%eax
  101332:	89 04 24             	mov    %eax,(%esp)
  101335:	e8 ad fe ff ff       	call   1011e7 <trap_print>
	panic("unhandled trap");
  10133a:	c7 44 24 08 dc 32 10 	movl   $0x1032dc,0x8(%esp)
  101341:	00 
  101342:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  101349:	00 
  10134a:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  101351:	e8 d3 ef ff ff       	call   100329 <debug_panic>

00101356 <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101356:	55                   	push   %ebp
  101357:	89 e5                	mov    %esp,%ebp
  101359:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  10135c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10135f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101362:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101365:	8b 00                	mov    (%eax),%eax
  101367:	89 c2                	mov    %eax,%edx
  101369:	8b 45 08             	mov    0x8(%ebp),%eax
  10136c:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  10136f:	8b 45 08             	mov    0x8(%ebp),%eax
  101372:	8b 40 30             	mov    0x30(%eax),%eax
  101375:	89 c2                	mov    %eax,%edx
  101377:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10137a:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  10137d:	8b 45 08             	mov    0x8(%ebp),%eax
  101380:	89 04 24             	mov    %eax,(%esp)
  101383:	e8 f8 3c 00 00       	call   105080 <trap_return>

00101388 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101388:	55                   	push   %ebp
  101389:	89 e5                	mov    %esp,%ebp
  10138b:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10138e:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  101391:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  101395:	0f b7 c0             	movzwl %ax,%eax
  101398:	83 e0 03             	and    $0x3,%eax
  10139b:	85 c0                	test   %eax,%eax
  10139d:	74 24                	je     1013c3 <trap_check_kernel+0x3b>
  10139f:	c7 44 24 0c f7 32 10 	movl   $0x1032f7,0xc(%esp)
  1013a6:	00 
  1013a7:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  1013ae:	00 
  1013af:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  1013b6:	00 
  1013b7:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  1013be:	e8 66 ef ff ff       	call   100329 <debug_panic>

	cpu *c = cpu_cur();
  1013c3:	e8 74 fb ff ff       	call   100f3c <cpu_cur>
  1013c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  1013cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1013ce:	c7 80 a0 00 00 00 56 	movl   $0x101356,0xa0(%eax)
  1013d5:	13 10 00 
	trap_check(&c->recoverdata);
  1013d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1013db:	05 a4 00 00 00       	add    $0xa4,%eax
  1013e0:	89 04 24             	mov    %eax,(%esp)
  1013e3:	e8 96 00 00 00       	call   10147e <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1013e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1013eb:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1013f2:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  1013f5:	c7 04 24 0c 33 10 00 	movl   $0x10330c,(%esp)
  1013fc:	e8 fb 11 00 00       	call   1025fc <cprintf>
}
  101401:	c9                   	leave  
  101402:	c3                   	ret    

00101403 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101403:	55                   	push   %ebp
  101404:	89 e5                	mov    %esp,%ebp
  101406:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101409:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  10140c:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101410:	0f b7 c0             	movzwl %ax,%eax
  101413:	83 e0 03             	and    $0x3,%eax
  101416:	83 f8 03             	cmp    $0x3,%eax
  101419:	74 24                	je     10143f <trap_check_user+0x3c>
  10141b:	c7 44 24 0c 2c 33 10 	movl   $0x10332c,0xc(%esp)
  101422:	00 
  101423:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  10142a:	00 
  10142b:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
  101432:	00 
  101433:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  10143a:	e8 ea ee ff ff       	call   100329 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  10143f:	c7 45 f0 00 40 10 00 	movl   $0x104000,-0x10(%ebp)
	c->recover = trap_check_recover;
  101446:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101449:	c7 80 a0 00 00 00 56 	movl   $0x101356,0xa0(%eax)
  101450:	13 10 00 
	trap_check(&c->recoverdata);
  101453:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101456:	05 a4 00 00 00       	add    $0xa4,%eax
  10145b:	89 04 24             	mov    %eax,(%esp)
  10145e:	e8 1b 00 00 00       	call   10147e <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101463:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101466:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  10146d:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101470:	c7 04 24 41 33 10 00 	movl   $0x103341,(%esp)
  101477:	e8 80 11 00 00       	call   1025fc <cprintf>
}
  10147c:	c9                   	leave  
  10147d:	c3                   	ret    

0010147e <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  10147e:	55                   	push   %ebp
  10147f:	89 e5                	mov    %esp,%ebp
  101481:	57                   	push   %edi
  101482:	56                   	push   %esi
  101483:	53                   	push   %ebx
  101484:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101487:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  10148e:	8b 45 08             	mov    0x8(%ebp),%eax
  101491:	8d 55 d8             	lea    -0x28(%ebp),%edx
  101494:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  101496:	c7 45 d8 a4 14 10 00 	movl   $0x1014a4,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  10149d:	b8 00 00 00 00       	mov    $0x0,%eax
  1014a2:	f7 f0                	div    %eax

001014a4 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1014a4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1014a7:	85 c0                	test   %eax,%eax
  1014a9:	74 24                	je     1014cf <after_div0+0x2b>
  1014ab:	c7 44 24 0c 5f 33 10 	movl   $0x10335f,0xc(%esp)
  1014b2:	00 
  1014b3:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  1014ba:	00 
  1014bb:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  1014c2:	00 
  1014c3:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  1014ca:	e8 5a ee ff ff       	call   100329 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1014cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1014d2:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1014d7:	74 24                	je     1014fd <after_div0+0x59>
  1014d9:	c7 44 24 0c 77 33 10 	movl   $0x103377,0xc(%esp)
  1014e0:	00 
  1014e1:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  1014e8:	00 
  1014e9:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  1014f0:	00 
  1014f1:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  1014f8:	e8 2c ee ff ff       	call   100329 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  1014fd:	c7 45 d8 05 15 10 00 	movl   $0x101505,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  101504:	cc                   	int3   

00101505 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101505:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101508:	83 f8 03             	cmp    $0x3,%eax
  10150b:	74 24                	je     101531 <after_breakpoint+0x2c>
  10150d:	c7 44 24 0c 8c 33 10 	movl   $0x10338c,0xc(%esp)
  101514:	00 
  101515:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  10151c:	00 
  10151d:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  101524:	00 
  101525:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  10152c:	e8 f8 ed ff ff       	call   100329 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101531:	c7 45 d8 40 15 10 00 	movl   $0x101540,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101538:	b8 00 00 00 70       	mov    $0x70000000,%eax
  10153d:	01 c0                	add    %eax,%eax
  10153f:	ce                   	into   

00101540 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101540:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101543:	83 f8 04             	cmp    $0x4,%eax
  101546:	74 24                	je     10156c <after_overflow+0x2c>
  101548:	c7 44 24 0c a3 33 10 	movl   $0x1033a3,0xc(%esp)
  10154f:	00 
  101550:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  101557:	00 
  101558:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  10155f:	00 
  101560:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  101567:	e8 bd ed ff ff       	call   100329 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  10156c:	c7 45 d8 89 15 10 00 	movl   $0x101589,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  101573:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  10157a:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  101581:	b8 00 00 00 00       	mov    $0x0,%eax
  101586:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101589 <after_bound>:
	assert(args.trapno == T_BOUND);
  101589:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10158c:	83 f8 05             	cmp    $0x5,%eax
  10158f:	74 24                	je     1015b5 <after_bound+0x2c>
  101591:	c7 44 24 0c ba 33 10 	movl   $0x1033ba,0xc(%esp)
  101598:	00 
  101599:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  1015a0:	00 
  1015a1:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  1015a8:	00 
  1015a9:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  1015b0:	e8 74 ed ff ff       	call   100329 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  1015b5:	c7 45 d8 be 15 10 00 	movl   $0x1015be,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  1015bc:	0f 0b                	ud2    

001015be <after_illegal>:
	assert(args.trapno == T_ILLOP);
  1015be:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1015c1:	83 f8 06             	cmp    $0x6,%eax
  1015c4:	74 24                	je     1015ea <after_illegal+0x2c>
  1015c6:	c7 44 24 0c d1 33 10 	movl   $0x1033d1,0xc(%esp)
  1015cd:	00 
  1015ce:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  1015d5:	00 
  1015d6:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  1015dd:	00 
  1015de:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  1015e5:	e8 3f ed ff ff       	call   100329 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  1015ea:	c7 45 d8 f8 15 10 00 	movl   $0x1015f8,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  1015f1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1015f6:	8e e0                	mov    %eax,%fs

001015f8 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  1015f8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1015fb:	83 f8 0d             	cmp    $0xd,%eax
  1015fe:	74 24                	je     101624 <after_gpfault+0x2c>
  101600:	c7 44 24 0c e8 33 10 	movl   $0x1033e8,0xc(%esp)
  101607:	00 
  101608:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  10160f:	00 
  101610:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
  101617:	00 
  101618:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  10161f:	e8 05 ed ff ff       	call   100329 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101624:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  101627:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  10162b:	0f b7 c0             	movzwl %ax,%eax
  10162e:	83 e0 03             	and    $0x3,%eax
  101631:	85 c0                	test   %eax,%eax
  101633:	74 3a                	je     10166f <after_priv+0x2c>
		args.reip = after_priv;
  101635:	c7 45 d8 43 16 10 00 	movl   $0x101643,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  10163c:	0f 01 1d 00 50 10 00 	lidtl  0x105000

00101643 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101643:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101646:	83 f8 0d             	cmp    $0xd,%eax
  101649:	74 24                	je     10166f <after_priv+0x2c>
  10164b:	c7 44 24 0c e8 33 10 	movl   $0x1033e8,0xc(%esp)
  101652:	00 
  101653:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  10165a:	00 
  10165b:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
  101662:	00 
  101663:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  10166a:	e8 ba ec ff ff       	call   100329 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  10166f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101672:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101677:	74 24                	je     10169d <after_priv+0x5a>
  101679:	c7 44 24 0c 77 33 10 	movl   $0x103377,0xc(%esp)
  101680:	00 
  101681:	c7 44 24 08 96 31 10 	movl   $0x103196,0x8(%esp)
  101688:	00 
  101689:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
  101690:	00 
  101691:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  101698:	e8 8c ec ff ff       	call   100329 <debug_panic>
	cprintf("sfsfsfsfsfsfsfsfsf\n");
  10169d:	c7 04 24 ff 33 10 00 	movl   $0x1033ff,(%esp)
  1016a4:	e8 53 0f 00 00       	call   1025fc <cprintf>
	*argsp = NULL;	// recovery mechanism not needed anymore
  1016a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1016ac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1016b2:	83 c4 3c             	add    $0x3c,%esp
  1016b5:	5b                   	pop    %ebx
  1016b6:	5e                   	pop    %esi
  1016b7:	5f                   	pop    %edi
  1016b8:	5d                   	pop    %ebp
  1016b9:	c3                   	ret    

001016ba <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  1016ba:	6a 00                	push   $0x0
  1016bc:	6a 00                	push   $0x0
  1016be:	e9 a1 39 00 00       	jmp    105064 <_alltraps>
  1016c3:	90                   	nop

001016c4 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  1016c4:	6a 00                	push   $0x0
  1016c6:	6a 01                	push   $0x1
  1016c8:	e9 97 39 00 00       	jmp    105064 <_alltraps>
  1016cd:	90                   	nop

001016ce <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  1016ce:	6a 00                	push   $0x0
  1016d0:	6a 02                	push   $0x2
  1016d2:	e9 8d 39 00 00       	jmp    105064 <_alltraps>
  1016d7:	90                   	nop

001016d8 <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  1016d8:	6a 00                	push   $0x0
  1016da:	6a 03                	push   $0x3
  1016dc:	e9 83 39 00 00       	jmp    105064 <_alltraps>
  1016e1:	90                   	nop

001016e2 <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  1016e2:	6a 00                	push   $0x0
  1016e4:	6a 04                	push   $0x4
  1016e6:	e9 79 39 00 00       	jmp    105064 <_alltraps>
  1016eb:	90                   	nop

001016ec <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  1016ec:	6a 00                	push   $0x0
  1016ee:	6a 05                	push   $0x5
  1016f0:	e9 6f 39 00 00       	jmp    105064 <_alltraps>
  1016f5:	90                   	nop

001016f6 <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  1016f6:	6a 00                	push   $0x0
  1016f8:	6a 06                	push   $0x6
  1016fa:	e9 65 39 00 00       	jmp    105064 <_alltraps>
  1016ff:	90                   	nop

00101700 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  101700:	6a 00                	push   $0x0
  101702:	6a 07                	push   $0x7
  101704:	e9 5b 39 00 00       	jmp    105064 <_alltraps>
  101709:	90                   	nop

0010170a <vector8>:
TRAPHANDLER(vector8, 8)
  10170a:	6a 08                	push   $0x8
  10170c:	e9 53 39 00 00       	jmp    105064 <_alltraps>
  101711:	90                   	nop

00101712 <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  101712:	6a 00                	push   $0x0
  101714:	6a 09                	push   $0x9
  101716:	e9 49 39 00 00       	jmp    105064 <_alltraps>
  10171b:	90                   	nop

0010171c <vector10>:
TRAPHANDLER(vector10, 10)
  10171c:	6a 0a                	push   $0xa
  10171e:	e9 41 39 00 00       	jmp    105064 <_alltraps>
  101723:	90                   	nop

00101724 <vector11>:
TRAPHANDLER(vector11, 11)
  101724:	6a 0b                	push   $0xb
  101726:	e9 39 39 00 00       	jmp    105064 <_alltraps>
  10172b:	90                   	nop

0010172c <vector12>:
TRAPHANDLER(vector12, 12)
  10172c:	6a 0c                	push   $0xc
  10172e:	e9 31 39 00 00       	jmp    105064 <_alltraps>
  101733:	90                   	nop

00101734 <vector13>:
TRAPHANDLER(vector13, 13)
  101734:	6a 0d                	push   $0xd
  101736:	e9 29 39 00 00       	jmp    105064 <_alltraps>
  10173b:	90                   	nop

0010173c <vector14>:
TRAPHANDLER(vector14, 14)
  10173c:	6a 0e                	push   $0xe
  10173e:	e9 21 39 00 00       	jmp    105064 <_alltraps>
  101743:	90                   	nop

00101744 <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101744:	6a 00                	push   $0x0
  101746:	6a 0f                	push   $0xf
  101748:	e9 17 39 00 00       	jmp    105064 <_alltraps>
  10174d:	90                   	nop

0010174e <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  10174e:	6a 00                	push   $0x0
  101750:	6a 10                	push   $0x10
  101752:	e9 0d 39 00 00       	jmp    105064 <_alltraps>
  101757:	90                   	nop

00101758 <vector17>:
TRAPHANDLER(vector17, 17)
  101758:	6a 11                	push   $0x11
  10175a:	e9 05 39 00 00       	jmp    105064 <_alltraps>
  10175f:	90                   	nop

00101760 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  101760:	6a 00                	push   $0x0
  101762:	6a 12                	push   $0x12
  101764:	e9 fb 38 00 00       	jmp    105064 <_alltraps>
  101769:	90                   	nop

0010176a <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  10176a:	6a 00                	push   $0x0
  10176c:	6a 13                	push   $0x13
  10176e:	e9 f1 38 00 00       	jmp    105064 <_alltraps>
  101773:	90                   	nop

00101774 <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101774:	6a 00                	push   $0x0
  101776:	6a 1e                	push   $0x1e
  101778:	e9 e7 38 00 00       	jmp    105064 <_alltraps>

0010177d <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  10177d:	55                   	push   %ebp
  10177e:	89 e5                	mov    %esp,%ebp
  101780:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  101783:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  10178a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10178d:	0f b7 00             	movzwl (%eax),%eax
  101790:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  101794:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101797:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  10179c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10179f:	0f b7 00             	movzwl (%eax),%eax
  1017a2:	66 3d 5a a5          	cmp    $0xa55a,%ax
  1017a6:	74 13                	je     1017bb <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  1017a8:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  1017af:	c7 05 e0 6f 10 00 b4 	movl   $0x3b4,0x106fe0
  1017b6:	03 00 00 
  1017b9:	eb 14                	jmp    1017cf <video_init+0x52>
	} else {
		*cp = was;
  1017bb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1017be:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  1017c2:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  1017c5:	c7 05 e0 6f 10 00 d4 	movl   $0x3d4,0x106fe0
  1017cc:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  1017cf:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1017d4:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1017d7:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1017db:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1017df:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1017e2:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  1017e3:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1017e8:	83 c0 01             	add    $0x1,%eax
  1017eb:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1017ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1017f1:	89 c2                	mov    %eax,%edx
  1017f3:	ec                   	in     (%dx),%al
  1017f4:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  1017f7:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  1017fb:	0f b6 c0             	movzbl %al,%eax
  1017fe:	c1 e0 08             	shl    $0x8,%eax
  101801:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  101804:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101809:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10180c:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101810:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101814:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101817:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  101818:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  10181d:	83 c0 01             	add    $0x1,%eax
  101820:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101823:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101826:	89 c2                	mov    %eax,%edx
  101828:	ec                   	in     (%dx),%al
  101829:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  10182c:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  101830:	0f b6 c0             	movzbl %al,%eax
  101833:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  101836:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101839:	a3 e4 6f 10 00       	mov    %eax,0x106fe4
	crt_pos = pos;
  10183e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101841:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
}
  101847:	c9                   	leave  
  101848:	c3                   	ret    

00101849 <video_putc>:



void
video_putc(int c)
{
  101849:	55                   	push   %ebp
  10184a:	89 e5                	mov    %esp,%ebp
  10184c:	53                   	push   %ebx
  10184d:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  101850:	8b 45 08             	mov    0x8(%ebp),%eax
  101853:	b0 00                	mov    $0x0,%al
  101855:	85 c0                	test   %eax,%eax
  101857:	75 07                	jne    101860 <video_putc+0x17>
		c |= 0x0700;
  101859:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  101860:	8b 45 08             	mov    0x8(%ebp),%eax
  101863:	25 ff 00 00 00       	and    $0xff,%eax
  101868:	83 f8 09             	cmp    $0x9,%eax
  10186b:	0f 84 ae 00 00 00    	je     10191f <video_putc+0xd6>
  101871:	83 f8 09             	cmp    $0x9,%eax
  101874:	7f 0a                	jg     101880 <video_putc+0x37>
  101876:	83 f8 08             	cmp    $0x8,%eax
  101879:	74 14                	je     10188f <video_putc+0x46>
  10187b:	e9 dd 00 00 00       	jmp    10195d <video_putc+0x114>
  101880:	83 f8 0a             	cmp    $0xa,%eax
  101883:	74 4e                	je     1018d3 <video_putc+0x8a>
  101885:	83 f8 0d             	cmp    $0xd,%eax
  101888:	74 59                	je     1018e3 <video_putc+0x9a>
  10188a:	e9 ce 00 00 00       	jmp    10195d <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  10188f:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101896:	66 85 c0             	test   %ax,%ax
  101899:	0f 84 e4 00 00 00    	je     101983 <video_putc+0x13a>
			crt_pos--;
  10189f:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  1018a6:	83 e8 01             	sub    $0x1,%eax
  1018a9:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  1018af:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  1018b4:	0f b7 15 e8 6f 10 00 	movzwl 0x106fe8,%edx
  1018bb:	0f b7 d2             	movzwl %dx,%edx
  1018be:	01 d2                	add    %edx,%edx
  1018c0:	8d 14 10             	lea    (%eax,%edx,1),%edx
  1018c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1018c6:	b0 00                	mov    $0x0,%al
  1018c8:	83 c8 20             	or     $0x20,%eax
  1018cb:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  1018ce:	e9 b1 00 00 00       	jmp    101984 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  1018d3:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  1018da:	83 c0 50             	add    $0x50,%eax
  1018dd:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  1018e3:	0f b7 1d e8 6f 10 00 	movzwl 0x106fe8,%ebx
  1018ea:	0f b7 0d e8 6f 10 00 	movzwl 0x106fe8,%ecx
  1018f1:	0f b7 c1             	movzwl %cx,%eax
  1018f4:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  1018fa:	c1 e8 10             	shr    $0x10,%eax
  1018fd:	89 c2                	mov    %eax,%edx
  1018ff:	66 c1 ea 06          	shr    $0x6,%dx
  101903:	89 d0                	mov    %edx,%eax
  101905:	c1 e0 02             	shl    $0x2,%eax
  101908:	01 d0                	add    %edx,%eax
  10190a:	c1 e0 04             	shl    $0x4,%eax
  10190d:	89 ca                	mov    %ecx,%edx
  10190f:	66 29 c2             	sub    %ax,%dx
  101912:	89 d8                	mov    %ebx,%eax
  101914:	66 29 d0             	sub    %dx,%ax
  101917:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
		break;
  10191d:	eb 65                	jmp    101984 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  10191f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101926:	e8 1e ff ff ff       	call   101849 <video_putc>
		video_putc(' ');
  10192b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101932:	e8 12 ff ff ff       	call   101849 <video_putc>
		video_putc(' ');
  101937:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10193e:	e8 06 ff ff ff       	call   101849 <video_putc>
		video_putc(' ');
  101943:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10194a:	e8 fa fe ff ff       	call   101849 <video_putc>
		video_putc(' ');
  10194f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101956:	e8 ee fe ff ff       	call   101849 <video_putc>
		break;
  10195b:	eb 27                	jmp    101984 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  10195d:	8b 15 e4 6f 10 00    	mov    0x106fe4,%edx
  101963:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  10196a:	0f b7 c8             	movzwl %ax,%ecx
  10196d:	01 c9                	add    %ecx,%ecx
  10196f:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  101972:	8b 55 08             	mov    0x8(%ebp),%edx
  101975:	66 89 11             	mov    %dx,(%ecx)
  101978:	83 c0 01             	add    $0x1,%eax
  10197b:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
  101981:	eb 01                	jmp    101984 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  101983:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  101984:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  10198b:	66 3d cf 07          	cmp    $0x7cf,%ax
  10198f:	76 5b                	jbe    1019ec <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  101991:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101996:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  10199c:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  1019a1:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  1019a8:	00 
  1019a9:	89 54 24 04          	mov    %edx,0x4(%esp)
  1019ad:	89 04 24             	mov    %eax,(%esp)
  1019b0:	e8 a0 0e 00 00       	call   102855 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  1019b5:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  1019bc:	eb 15                	jmp    1019d3 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  1019be:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  1019c3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1019c6:	01 d2                	add    %edx,%edx
  1019c8:	01 d0                	add    %edx,%eax
  1019ca:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  1019cf:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  1019d3:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  1019da:	7e e2                	jle    1019be <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  1019dc:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  1019e3:	83 e8 50             	sub    $0x50,%eax
  1019e6:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  1019ec:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1019f1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1019f4:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1019f8:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  1019fc:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1019ff:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101a00:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101a07:	66 c1 e8 08          	shr    $0x8,%ax
  101a0b:	0f b6 c0             	movzbl %al,%eax
  101a0e:	8b 15 e0 6f 10 00    	mov    0x106fe0,%edx
  101a14:	83 c2 01             	add    $0x1,%edx
  101a17:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  101a1a:	88 45 e3             	mov    %al,-0x1d(%ebp)
  101a1d:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101a21:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101a24:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  101a25:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101a2a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101a2d:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  101a31:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  101a35:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101a38:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  101a39:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101a40:	0f b6 c0             	movzbl %al,%eax
  101a43:	8b 15 e0 6f 10 00    	mov    0x106fe0,%edx
  101a49:	83 c2 01             	add    $0x1,%edx
  101a4c:	89 55 f4             	mov    %edx,-0xc(%ebp)
  101a4f:	88 45 f3             	mov    %al,-0xd(%ebp)
  101a52:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101a56:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101a59:	ee                   	out    %al,(%dx)
}
  101a5a:	83 c4 44             	add    $0x44,%esp
  101a5d:	5b                   	pop    %ebx
  101a5e:	5d                   	pop    %ebp
  101a5f:	c3                   	ret    

00101a60 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  101a60:	55                   	push   %ebp
  101a61:	89 e5                	mov    %esp,%ebp
  101a63:	83 ec 38             	sub    $0x38,%esp
  101a66:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a6d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101a70:	89 c2                	mov    %eax,%edx
  101a72:	ec                   	in     (%dx),%al
  101a73:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  101a76:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  101a7a:	0f b6 c0             	movzbl %al,%eax
  101a7d:	83 e0 01             	and    $0x1,%eax
  101a80:	85 c0                	test   %eax,%eax
  101a82:	75 0a                	jne    101a8e <kbd_proc_data+0x2e>
		return -1;
  101a84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101a89:	e9 5a 01 00 00       	jmp    101be8 <kbd_proc_data+0x188>
  101a8e:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a95:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101a98:	89 c2                	mov    %eax,%edx
  101a9a:	ec                   	in     (%dx),%al
  101a9b:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  101a9e:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  101aa2:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  101aa5:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  101aa9:	75 17                	jne    101ac2 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  101aab:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101ab0:	83 c8 40             	or     $0x40,%eax
  101ab3:	a3 ec 6f 10 00       	mov    %eax,0x106fec
		return 0;
  101ab8:	b8 00 00 00 00       	mov    $0x0,%eax
  101abd:	e9 26 01 00 00       	jmp    101be8 <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  101ac2:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101ac6:	84 c0                	test   %al,%al
  101ac8:	79 47                	jns    101b11 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  101aca:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101acf:	83 e0 40             	and    $0x40,%eax
  101ad2:	85 c0                	test   %eax,%eax
  101ad4:	75 09                	jne    101adf <kbd_proc_data+0x7f>
  101ad6:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101ada:	83 e0 7f             	and    $0x7f,%eax
  101add:	eb 04                	jmp    101ae3 <kbd_proc_data+0x83>
  101adf:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101ae3:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  101ae6:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101aea:	0f b6 80 a0 50 10 00 	movzbl 0x1050a0(%eax),%eax
  101af1:	83 c8 40             	or     $0x40,%eax
  101af4:	0f b6 c0             	movzbl %al,%eax
  101af7:	f7 d0                	not    %eax
  101af9:	89 c2                	mov    %eax,%edx
  101afb:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101b00:	21 d0                	and    %edx,%eax
  101b02:	a3 ec 6f 10 00       	mov    %eax,0x106fec
		return 0;
  101b07:	b8 00 00 00 00       	mov    $0x0,%eax
  101b0c:	e9 d7 00 00 00       	jmp    101be8 <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  101b11:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101b16:	83 e0 40             	and    $0x40,%eax
  101b19:	85 c0                	test   %eax,%eax
  101b1b:	74 11                	je     101b2e <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  101b1d:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  101b21:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101b26:	83 e0 bf             	and    $0xffffffbf,%eax
  101b29:	a3 ec 6f 10 00       	mov    %eax,0x106fec
	}

	shift |= shiftcode[data];
  101b2e:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101b32:	0f b6 80 a0 50 10 00 	movzbl 0x1050a0(%eax),%eax
  101b39:	0f b6 d0             	movzbl %al,%edx
  101b3c:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101b41:	09 d0                	or     %edx,%eax
  101b43:	a3 ec 6f 10 00       	mov    %eax,0x106fec
	shift ^= togglecode[data];
  101b48:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101b4c:	0f b6 80 a0 51 10 00 	movzbl 0x1051a0(%eax),%eax
  101b53:	0f b6 d0             	movzbl %al,%edx
  101b56:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101b5b:	31 d0                	xor    %edx,%eax
  101b5d:	a3 ec 6f 10 00       	mov    %eax,0x106fec

	c = charcode[shift & (CTL | SHIFT)][data];
  101b62:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101b67:	83 e0 03             	and    $0x3,%eax
  101b6a:	8b 14 85 a0 55 10 00 	mov    0x1055a0(,%eax,4),%edx
  101b71:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101b75:	8d 04 02             	lea    (%edx,%eax,1),%eax
  101b78:	0f b6 00             	movzbl (%eax),%eax
  101b7b:	0f b6 c0             	movzbl %al,%eax
  101b7e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  101b81:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101b86:	83 e0 08             	and    $0x8,%eax
  101b89:	85 c0                	test   %eax,%eax
  101b8b:	74 22                	je     101baf <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  101b8d:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  101b91:	7e 0c                	jle    101b9f <kbd_proc_data+0x13f>
  101b93:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  101b97:	7f 06                	jg     101b9f <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  101b99:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  101b9d:	eb 10                	jmp    101baf <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  101b9f:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  101ba3:	7e 0a                	jle    101baf <kbd_proc_data+0x14f>
  101ba5:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  101ba9:	7f 04                	jg     101baf <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  101bab:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  101baf:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101bb4:	f7 d0                	not    %eax
  101bb6:	83 e0 06             	and    $0x6,%eax
  101bb9:	85 c0                	test   %eax,%eax
  101bbb:	75 28                	jne    101be5 <kbd_proc_data+0x185>
  101bbd:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  101bc4:	75 1f                	jne    101be5 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  101bc6:	c7 04 24 b0 35 10 00 	movl   $0x1035b0,(%esp)
  101bcd:	e8 2a 0a 00 00       	call   1025fc <cprintf>
  101bd2:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  101bd9:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101bdd:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101be1:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101be4:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  101be5:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  101be8:	c9                   	leave  
  101be9:	c3                   	ret    

00101bea <kbd_intr>:

void
kbd_intr(void)
{
  101bea:	55                   	push   %ebp
  101beb:	89 e5                	mov    %esp,%ebp
  101bed:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  101bf0:	c7 04 24 60 1a 10 00 	movl   $0x101a60,(%esp)
  101bf7:	e8 f6 e5 ff ff       	call   1001f2 <cons_intr>
}
  101bfc:	c9                   	leave  
  101bfd:	c3                   	ret    

00101bfe <kbd_init>:

void
kbd_init(void)
{
  101bfe:	55                   	push   %ebp
  101bff:	89 e5                	mov    %esp,%ebp
}
  101c01:	5d                   	pop    %ebp
  101c02:	c3                   	ret    

00101c03 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  101c03:	55                   	push   %ebp
  101c04:	89 e5                	mov    %esp,%ebp
  101c06:	83 ec 20             	sub    $0x20,%esp
  101c09:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101c10:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101c13:	89 c2                	mov    %eax,%edx
  101c15:	ec                   	in     (%dx),%al
  101c16:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  101c19:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101c20:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101c23:	89 c2                	mov    %eax,%edx
  101c25:	ec                   	in     (%dx),%al
  101c26:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101c29:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101c30:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101c33:	89 c2                	mov    %eax,%edx
  101c35:	ec                   	in     (%dx),%al
  101c36:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101c39:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101c40:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101c43:	89 c2                	mov    %eax,%edx
  101c45:	ec                   	in     (%dx),%al
  101c46:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  101c49:	c9                   	leave  
  101c4a:	c3                   	ret    

00101c4b <serial_proc_data>:

static int
serial_proc_data(void)
{
  101c4b:	55                   	push   %ebp
  101c4c:	89 e5                	mov    %esp,%ebp
  101c4e:	83 ec 10             	sub    $0x10,%esp
  101c51:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  101c58:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101c5b:	89 c2                	mov    %eax,%edx
  101c5d:	ec                   	in     (%dx),%al
  101c5e:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101c61:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  101c65:	0f b6 c0             	movzbl %al,%eax
  101c68:	83 e0 01             	and    $0x1,%eax
  101c6b:	85 c0                	test   %eax,%eax
  101c6d:	75 07                	jne    101c76 <serial_proc_data+0x2b>
		return -1;
  101c6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101c74:	eb 17                	jmp    101c8d <serial_proc_data+0x42>
  101c76:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101c7d:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101c80:	89 c2                	mov    %eax,%edx
  101c82:	ec                   	in     (%dx),%al
  101c83:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101c86:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  101c8a:	0f b6 c0             	movzbl %al,%eax
}
  101c8d:	c9                   	leave  
  101c8e:	c3                   	ret    

00101c8f <serial_intr>:

void
serial_intr(void)
{
  101c8f:	55                   	push   %ebp
  101c90:	89 e5                	mov    %esp,%ebp
  101c92:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  101c95:	a1 00 70 10 00       	mov    0x107000,%eax
  101c9a:	85 c0                	test   %eax,%eax
  101c9c:	74 0c                	je     101caa <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  101c9e:	c7 04 24 4b 1c 10 00 	movl   $0x101c4b,(%esp)
  101ca5:	e8 48 e5 ff ff       	call   1001f2 <cons_intr>
}
  101caa:	c9                   	leave  
  101cab:	c3                   	ret    

00101cac <serial_putc>:

void
serial_putc(int c)
{
  101cac:	55                   	push   %ebp
  101cad:	89 e5                	mov    %esp,%ebp
  101caf:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  101cb2:	a1 00 70 10 00       	mov    0x107000,%eax
  101cb7:	85 c0                	test   %eax,%eax
  101cb9:	74 53                	je     101d0e <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  101cbb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  101cc2:	eb 09                	jmp    101ccd <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  101cc4:	e8 3a ff ff ff       	call   101c03 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  101cc9:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  101ccd:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101cd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101cd7:	89 c2                	mov    %eax,%edx
  101cd9:	ec                   	in     (%dx),%al
  101cda:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  101cdd:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101ce1:	0f b6 c0             	movzbl %al,%eax
  101ce4:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  101ce7:	85 c0                	test   %eax,%eax
  101ce9:	75 09                	jne    101cf4 <serial_putc+0x48>
  101ceb:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  101cf2:	7e d0                	jle    101cc4 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  101cf4:	8b 45 08             	mov    0x8(%ebp),%eax
  101cf7:	0f b6 c0             	movzbl %al,%eax
  101cfa:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  101d01:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101d04:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101d08:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101d0b:	ee                   	out    %al,(%dx)
  101d0c:	eb 01                	jmp    101d0f <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  101d0e:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  101d0f:	c9                   	leave  
  101d10:	c3                   	ret    

00101d11 <serial_init>:

void
serial_init(void)
{
  101d11:	55                   	push   %ebp
  101d12:	89 e5                	mov    %esp,%ebp
  101d14:	83 ec 50             	sub    $0x50,%esp
  101d17:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  101d1e:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  101d22:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  101d26:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  101d29:	ee                   	out    %al,(%dx)
  101d2a:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  101d31:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  101d35:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  101d39:	8b 55 bc             	mov    -0x44(%ebp),%edx
  101d3c:	ee                   	out    %al,(%dx)
  101d3d:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  101d44:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  101d48:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  101d4c:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  101d4f:	ee                   	out    %al,(%dx)
  101d50:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  101d57:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  101d5b:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  101d5f:	8b 55 cc             	mov    -0x34(%ebp),%edx
  101d62:	ee                   	out    %al,(%dx)
  101d63:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  101d6a:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  101d6e:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  101d72:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101d75:	ee                   	out    %al,(%dx)
  101d76:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  101d7d:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  101d81:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101d85:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101d88:	ee                   	out    %al,(%dx)
  101d89:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  101d90:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  101d94:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101d98:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101d9b:	ee                   	out    %al,(%dx)
  101d9c:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101da3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101da6:	89 c2                	mov    %eax,%edx
  101da8:	ec                   	in     (%dx),%al
  101da9:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101dac:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  101db0:	3c ff                	cmp    $0xff,%al
  101db2:	0f 95 c0             	setne  %al
  101db5:	0f b6 c0             	movzbl %al,%eax
  101db8:	a3 00 70 10 00       	mov    %eax,0x107000
  101dbd:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101dc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101dc7:	89 c2                	mov    %eax,%edx
  101dc9:	ec                   	in     (%dx),%al
  101dca:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101dcd:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101dd4:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101dd7:	89 c2                	mov    %eax,%edx
  101dd9:	ec                   	in     (%dx),%al
  101dda:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  101ddd:	c9                   	leave  
  101dde:	c3                   	ret    

00101ddf <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  101ddf:	55                   	push   %ebp
  101de0:	89 e5                	mov    %esp,%ebp
  101de2:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101de5:	8b 45 08             	mov    0x8(%ebp),%eax
  101de8:	0f b6 c0             	movzbl %al,%eax
  101deb:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101df2:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101df5:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101df9:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101dfc:	ee                   	out    %al,(%dx)
  101dfd:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101e04:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101e07:	89 c2                	mov    %eax,%edx
  101e09:	ec                   	in     (%dx),%al
  101e0a:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101e0d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  101e11:	0f b6 c0             	movzbl %al,%eax
}
  101e14:	c9                   	leave  
  101e15:	c3                   	ret    

00101e16 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  101e16:	55                   	push   %ebp
  101e17:	89 e5                	mov    %esp,%ebp
  101e19:	53                   	push   %ebx
  101e1a:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  101e1d:	8b 45 08             	mov    0x8(%ebp),%eax
  101e20:	89 04 24             	mov    %eax,(%esp)
  101e23:	e8 b7 ff ff ff       	call   101ddf <nvram_read>
  101e28:	89 c3                	mov    %eax,%ebx
  101e2a:	8b 45 08             	mov    0x8(%ebp),%eax
  101e2d:	83 c0 01             	add    $0x1,%eax
  101e30:	89 04 24             	mov    %eax,(%esp)
  101e33:	e8 a7 ff ff ff       	call   101ddf <nvram_read>
  101e38:	c1 e0 08             	shl    $0x8,%eax
  101e3b:	09 d8                	or     %ebx,%eax
}
  101e3d:	83 c4 04             	add    $0x4,%esp
  101e40:	5b                   	pop    %ebx
  101e41:	5d                   	pop    %ebp
  101e42:	c3                   	ret    

00101e43 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  101e43:	55                   	push   %ebp
  101e44:	89 e5                	mov    %esp,%ebp
  101e46:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101e49:	8b 45 08             	mov    0x8(%ebp),%eax
  101e4c:	0f b6 c0             	movzbl %al,%eax
  101e4f:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101e56:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101e59:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101e5d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101e60:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  101e61:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e64:	0f b6 c0             	movzbl %al,%eax
  101e67:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  101e6e:	88 45 fb             	mov    %al,-0x5(%ebp)
  101e71:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101e75:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101e78:	ee                   	out    %al,(%dx)
}
  101e79:	c9                   	leave  
  101e7a:	c3                   	ret    

00101e7b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  101e7b:	55                   	push   %ebp
  101e7c:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  101e7e:	8b 45 08             	mov    0x8(%ebp),%eax
  101e81:	8b 40 18             	mov    0x18(%eax),%eax
  101e84:	83 e0 02             	and    $0x2,%eax
  101e87:	85 c0                	test   %eax,%eax
  101e89:	74 1c                	je     101ea7 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  101e8b:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e8e:	8b 00                	mov    (%eax),%eax
  101e90:	8d 50 08             	lea    0x8(%eax),%edx
  101e93:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e96:	89 10                	mov    %edx,(%eax)
  101e98:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e9b:	8b 00                	mov    (%eax),%eax
  101e9d:	83 e8 08             	sub    $0x8,%eax
  101ea0:	8b 50 04             	mov    0x4(%eax),%edx
  101ea3:	8b 00                	mov    (%eax),%eax
  101ea5:	eb 47                	jmp    101eee <getuint+0x73>
	else if (st->flags & F_L)
  101ea7:	8b 45 08             	mov    0x8(%ebp),%eax
  101eaa:	8b 40 18             	mov    0x18(%eax),%eax
  101ead:	83 e0 01             	and    $0x1,%eax
  101eb0:	84 c0                	test   %al,%al
  101eb2:	74 1e                	je     101ed2 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  101eb4:	8b 45 0c             	mov    0xc(%ebp),%eax
  101eb7:	8b 00                	mov    (%eax),%eax
  101eb9:	8d 50 04             	lea    0x4(%eax),%edx
  101ebc:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ebf:	89 10                	mov    %edx,(%eax)
  101ec1:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ec4:	8b 00                	mov    (%eax),%eax
  101ec6:	83 e8 04             	sub    $0x4,%eax
  101ec9:	8b 00                	mov    (%eax),%eax
  101ecb:	ba 00 00 00 00       	mov    $0x0,%edx
  101ed0:	eb 1c                	jmp    101eee <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  101ed2:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ed5:	8b 00                	mov    (%eax),%eax
  101ed7:	8d 50 04             	lea    0x4(%eax),%edx
  101eda:	8b 45 0c             	mov    0xc(%ebp),%eax
  101edd:	89 10                	mov    %edx,(%eax)
  101edf:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ee2:	8b 00                	mov    (%eax),%eax
  101ee4:	83 e8 04             	sub    $0x4,%eax
  101ee7:	8b 00                	mov    (%eax),%eax
  101ee9:	ba 00 00 00 00       	mov    $0x0,%edx
}
  101eee:	5d                   	pop    %ebp
  101eef:	c3                   	ret    

00101ef0 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  101ef0:	55                   	push   %ebp
  101ef1:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  101ef3:	8b 45 08             	mov    0x8(%ebp),%eax
  101ef6:	8b 40 18             	mov    0x18(%eax),%eax
  101ef9:	83 e0 02             	and    $0x2,%eax
  101efc:	85 c0                	test   %eax,%eax
  101efe:	74 1c                	je     101f1c <getint+0x2c>
		return va_arg(*ap, long long);
  101f00:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f03:	8b 00                	mov    (%eax),%eax
  101f05:	8d 50 08             	lea    0x8(%eax),%edx
  101f08:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f0b:	89 10                	mov    %edx,(%eax)
  101f0d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f10:	8b 00                	mov    (%eax),%eax
  101f12:	83 e8 08             	sub    $0x8,%eax
  101f15:	8b 50 04             	mov    0x4(%eax),%edx
  101f18:	8b 00                	mov    (%eax),%eax
  101f1a:	eb 47                	jmp    101f63 <getint+0x73>
	else if (st->flags & F_L)
  101f1c:	8b 45 08             	mov    0x8(%ebp),%eax
  101f1f:	8b 40 18             	mov    0x18(%eax),%eax
  101f22:	83 e0 01             	and    $0x1,%eax
  101f25:	84 c0                	test   %al,%al
  101f27:	74 1e                	je     101f47 <getint+0x57>
		return va_arg(*ap, long);
  101f29:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f2c:	8b 00                	mov    (%eax),%eax
  101f2e:	8d 50 04             	lea    0x4(%eax),%edx
  101f31:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f34:	89 10                	mov    %edx,(%eax)
  101f36:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f39:	8b 00                	mov    (%eax),%eax
  101f3b:	83 e8 04             	sub    $0x4,%eax
  101f3e:	8b 00                	mov    (%eax),%eax
  101f40:	89 c2                	mov    %eax,%edx
  101f42:	c1 fa 1f             	sar    $0x1f,%edx
  101f45:	eb 1c                	jmp    101f63 <getint+0x73>
	else
		return va_arg(*ap, int);
  101f47:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f4a:	8b 00                	mov    (%eax),%eax
  101f4c:	8d 50 04             	lea    0x4(%eax),%edx
  101f4f:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f52:	89 10                	mov    %edx,(%eax)
  101f54:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f57:	8b 00                	mov    (%eax),%eax
  101f59:	83 e8 04             	sub    $0x4,%eax
  101f5c:	8b 00                	mov    (%eax),%eax
  101f5e:	89 c2                	mov    %eax,%edx
  101f60:	c1 fa 1f             	sar    $0x1f,%edx
}
  101f63:	5d                   	pop    %ebp
  101f64:	c3                   	ret    

00101f65 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  101f65:	55                   	push   %ebp
  101f66:	89 e5                	mov    %esp,%ebp
  101f68:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  101f6b:	eb 1a                	jmp    101f87 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  101f6d:	8b 45 08             	mov    0x8(%ebp),%eax
  101f70:	8b 08                	mov    (%eax),%ecx
  101f72:	8b 45 08             	mov    0x8(%ebp),%eax
  101f75:	8b 50 04             	mov    0x4(%eax),%edx
  101f78:	8b 45 08             	mov    0x8(%ebp),%eax
  101f7b:	8b 40 08             	mov    0x8(%eax),%eax
  101f7e:	89 54 24 04          	mov    %edx,0x4(%esp)
  101f82:	89 04 24             	mov    %eax,(%esp)
  101f85:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  101f87:	8b 45 08             	mov    0x8(%ebp),%eax
  101f8a:	8b 40 0c             	mov    0xc(%eax),%eax
  101f8d:	8d 50 ff             	lea    -0x1(%eax),%edx
  101f90:	8b 45 08             	mov    0x8(%ebp),%eax
  101f93:	89 50 0c             	mov    %edx,0xc(%eax)
  101f96:	8b 45 08             	mov    0x8(%ebp),%eax
  101f99:	8b 40 0c             	mov    0xc(%eax),%eax
  101f9c:	85 c0                	test   %eax,%eax
  101f9e:	79 cd                	jns    101f6d <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  101fa0:	c9                   	leave  
  101fa1:	c3                   	ret    

00101fa2 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  101fa2:	55                   	push   %ebp
  101fa3:	89 e5                	mov    %esp,%ebp
  101fa5:	53                   	push   %ebx
  101fa6:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  101fa9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  101fad:	79 18                	jns    101fc7 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  101faf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101fb6:	00 
  101fb7:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fba:	89 04 24             	mov    %eax,(%esp)
  101fbd:	e8 e7 07 00 00       	call   1027a9 <strchr>
  101fc2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101fc5:	eb 2c                	jmp    101ff3 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  101fc7:	8b 45 10             	mov    0x10(%ebp),%eax
  101fca:	89 44 24 08          	mov    %eax,0x8(%esp)
  101fce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101fd5:	00 
  101fd6:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fd9:	89 04 24             	mov    %eax,(%esp)
  101fdc:	e8 cc 09 00 00       	call   1029ad <memchr>
  101fe1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101fe4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  101fe8:	75 09                	jne    101ff3 <putstr+0x51>
		lim = str + maxlen;
  101fea:	8b 45 10             	mov    0x10(%ebp),%eax
  101fed:	03 45 0c             	add    0xc(%ebp),%eax
  101ff0:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  101ff3:	8b 45 08             	mov    0x8(%ebp),%eax
  101ff6:	8b 40 0c             	mov    0xc(%eax),%eax
  101ff9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  101ffc:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101fff:	89 cb                	mov    %ecx,%ebx
  102001:	29 d3                	sub    %edx,%ebx
  102003:	89 da                	mov    %ebx,%edx
  102005:	8d 14 10             	lea    (%eax,%edx,1),%edx
  102008:	8b 45 08             	mov    0x8(%ebp),%eax
  10200b:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  10200e:	8b 45 08             	mov    0x8(%ebp),%eax
  102011:	8b 40 18             	mov    0x18(%eax),%eax
  102014:	83 e0 10             	and    $0x10,%eax
  102017:	85 c0                	test   %eax,%eax
  102019:	75 32                	jne    10204d <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  10201b:	8b 45 08             	mov    0x8(%ebp),%eax
  10201e:	89 04 24             	mov    %eax,(%esp)
  102021:	e8 3f ff ff ff       	call   101f65 <putpad>
	while (str < lim) {
  102026:	eb 25                	jmp    10204d <putstr+0xab>
		char ch = *str++;
  102028:	8b 45 0c             	mov    0xc(%ebp),%eax
  10202b:	0f b6 00             	movzbl (%eax),%eax
  10202e:	88 45 f7             	mov    %al,-0x9(%ebp)
  102031:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  102035:	8b 45 08             	mov    0x8(%ebp),%eax
  102038:	8b 08                	mov    (%eax),%ecx
  10203a:	8b 45 08             	mov    0x8(%ebp),%eax
  10203d:	8b 50 04             	mov    0x4(%eax),%edx
  102040:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  102044:	89 54 24 04          	mov    %edx,0x4(%esp)
  102048:	89 04 24             	mov    %eax,(%esp)
  10204b:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  10204d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102050:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102053:	72 d3                	jb     102028 <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  102055:	8b 45 08             	mov    0x8(%ebp),%eax
  102058:	89 04 24             	mov    %eax,(%esp)
  10205b:	e8 05 ff ff ff       	call   101f65 <putpad>
}
  102060:	83 c4 24             	add    $0x24,%esp
  102063:	5b                   	pop    %ebx
  102064:	5d                   	pop    %ebp
  102065:	c3                   	ret    

00102066 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  102066:	55                   	push   %ebp
  102067:	89 e5                	mov    %esp,%ebp
  102069:	53                   	push   %ebx
  10206a:	83 ec 24             	sub    $0x24,%esp
  10206d:	8b 45 10             	mov    0x10(%ebp),%eax
  102070:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102073:	8b 45 14             	mov    0x14(%ebp),%eax
  102076:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  102079:	8b 45 08             	mov    0x8(%ebp),%eax
  10207c:	8b 40 1c             	mov    0x1c(%eax),%eax
  10207f:	89 c2                	mov    %eax,%edx
  102081:	c1 fa 1f             	sar    $0x1f,%edx
  102084:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  102087:	77 4e                	ja     1020d7 <genint+0x71>
  102089:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  10208c:	72 05                	jb     102093 <genint+0x2d>
  10208e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102091:	77 44                	ja     1020d7 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  102093:	8b 45 08             	mov    0x8(%ebp),%eax
  102096:	8b 40 1c             	mov    0x1c(%eax),%eax
  102099:	89 c2                	mov    %eax,%edx
  10209b:	c1 fa 1f             	sar    $0x1f,%edx
  10209e:	89 44 24 08          	mov    %eax,0x8(%esp)
  1020a2:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1020a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1020a9:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1020ac:	89 04 24             	mov    %eax,(%esp)
  1020af:	89 54 24 04          	mov    %edx,0x4(%esp)
  1020b3:	e8 38 09 00 00       	call   1029f0 <__udivdi3>
  1020b8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1020bc:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1020c0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1020c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1020ca:	89 04 24             	mov    %eax,(%esp)
  1020cd:	e8 94 ff ff ff       	call   102066 <genint>
  1020d2:	89 45 0c             	mov    %eax,0xc(%ebp)
  1020d5:	eb 1b                	jmp    1020f2 <genint+0x8c>
	else if (st->signc >= 0)
  1020d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1020da:	8b 40 14             	mov    0x14(%eax),%eax
  1020dd:	85 c0                	test   %eax,%eax
  1020df:	78 11                	js     1020f2 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  1020e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1020e4:	8b 40 14             	mov    0x14(%eax),%eax
  1020e7:	89 c2                	mov    %eax,%edx
  1020e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020ec:	88 10                	mov    %dl,(%eax)
  1020ee:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  1020f2:	8b 45 08             	mov    0x8(%ebp),%eax
  1020f5:	8b 40 1c             	mov    0x1c(%eax),%eax
  1020f8:	89 c1                	mov    %eax,%ecx
  1020fa:	89 c3                	mov    %eax,%ebx
  1020fc:	c1 fb 1f             	sar    $0x1f,%ebx
  1020ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102102:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102105:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  102109:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  10210d:	89 04 24             	mov    %eax,(%esp)
  102110:	89 54 24 04          	mov    %edx,0x4(%esp)
  102114:	e8 07 0a 00 00       	call   102b20 <__umoddi3>
  102119:	05 bc 35 10 00       	add    $0x1035bc,%eax
  10211e:	0f b6 10             	movzbl (%eax),%edx
  102121:	8b 45 0c             	mov    0xc(%ebp),%eax
  102124:	88 10                	mov    %dl,(%eax)
  102126:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  10212a:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  10212d:	83 c4 24             	add    $0x24,%esp
  102130:	5b                   	pop    %ebx
  102131:	5d                   	pop    %ebp
  102132:	c3                   	ret    

00102133 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  102133:	55                   	push   %ebp
  102134:	89 e5                	mov    %esp,%ebp
  102136:	83 ec 58             	sub    $0x58,%esp
  102139:	8b 45 0c             	mov    0xc(%ebp),%eax
  10213c:	89 45 c0             	mov    %eax,-0x40(%ebp)
  10213f:	8b 45 10             	mov    0x10(%ebp),%eax
  102142:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  102145:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  102148:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  10214b:	8b 45 08             	mov    0x8(%ebp),%eax
  10214e:	8b 55 14             	mov    0x14(%ebp),%edx
  102151:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  102154:	8b 45 c0             	mov    -0x40(%ebp),%eax
  102157:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  10215a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10215e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102162:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102165:	89 44 24 04          	mov    %eax,0x4(%esp)
  102169:	8b 45 08             	mov    0x8(%ebp),%eax
  10216c:	89 04 24             	mov    %eax,(%esp)
  10216f:	e8 f2 fe ff ff       	call   102066 <genint>
  102174:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  102177:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10217a:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  10217d:	89 d1                	mov    %edx,%ecx
  10217f:	29 c1                	sub    %eax,%ecx
  102181:	89 c8                	mov    %ecx,%eax
  102183:	89 44 24 08          	mov    %eax,0x8(%esp)
  102187:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  10218a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10218e:	8b 45 08             	mov    0x8(%ebp),%eax
  102191:	89 04 24             	mov    %eax,(%esp)
  102194:	e8 09 fe ff ff       	call   101fa2 <putstr>
}
  102199:	c9                   	leave  
  10219a:	c3                   	ret    

0010219b <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  10219b:	55                   	push   %ebp
  10219c:	89 e5                	mov    %esp,%ebp
  10219e:	53                   	push   %ebx
  10219f:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  1021a2:	8d 55 c8             	lea    -0x38(%ebp),%edx
  1021a5:	b9 00 00 00 00       	mov    $0x0,%ecx
  1021aa:	b8 20 00 00 00       	mov    $0x20,%eax
  1021af:	89 c3                	mov    %eax,%ebx
  1021b1:	83 e3 fc             	and    $0xfffffffc,%ebx
  1021b4:	b8 00 00 00 00       	mov    $0x0,%eax
  1021b9:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  1021bc:	83 c0 04             	add    $0x4,%eax
  1021bf:	39 d8                	cmp    %ebx,%eax
  1021c1:	72 f6                	jb     1021b9 <vprintfmt+0x1e>
  1021c3:	01 c2                	add    %eax,%edx
  1021c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1021c8:	89 45 c8             	mov    %eax,-0x38(%ebp)
  1021cb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021ce:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1021d1:	eb 17                	jmp    1021ea <vprintfmt+0x4f>
			if (ch == '\0')
  1021d3:	85 db                	test   %ebx,%ebx
  1021d5:	0f 84 52 03 00 00    	je     10252d <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  1021db:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021e2:	89 1c 24             	mov    %ebx,(%esp)
  1021e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1021e8:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1021ea:	8b 45 10             	mov    0x10(%ebp),%eax
  1021ed:	0f b6 00             	movzbl (%eax),%eax
  1021f0:	0f b6 d8             	movzbl %al,%ebx
  1021f3:	83 fb 25             	cmp    $0x25,%ebx
  1021f6:	0f 95 c0             	setne  %al
  1021f9:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1021fd:	84 c0                	test   %al,%al
  1021ff:	75 d2                	jne    1021d3 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  102201:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  102208:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  10220f:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  102216:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  10221d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  102224:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  10222b:	eb 04                	jmp    102231 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  10222d:	90                   	nop
  10222e:	eb 01                	jmp    102231 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  102230:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  102231:	8b 45 10             	mov    0x10(%ebp),%eax
  102234:	0f b6 00             	movzbl (%eax),%eax
  102237:	0f b6 d8             	movzbl %al,%ebx
  10223a:	89 d8                	mov    %ebx,%eax
  10223c:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  102240:	83 e8 20             	sub    $0x20,%eax
  102243:	83 f8 58             	cmp    $0x58,%eax
  102246:	0f 87 b1 02 00 00    	ja     1024fd <vprintfmt+0x362>
  10224c:	8b 04 85 d4 35 10 00 	mov    0x1035d4(,%eax,4),%eax
  102253:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  102255:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102258:	83 c8 10             	or     $0x10,%eax
  10225b:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10225e:	eb d1                	jmp    102231 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  102260:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  102267:	eb c8                	jmp    102231 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  102269:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10226c:	85 c0                	test   %eax,%eax
  10226e:	79 bd                	jns    10222d <vprintfmt+0x92>
				st.signc = ' ';
  102270:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  102277:	eb b8                	jmp    102231 <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  102279:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10227c:	83 e0 08             	and    $0x8,%eax
  10227f:	85 c0                	test   %eax,%eax
  102281:	75 07                	jne    10228a <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  102283:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10228a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  102291:	8b 55 d8             	mov    -0x28(%ebp),%edx
  102294:	89 d0                	mov    %edx,%eax
  102296:	c1 e0 02             	shl    $0x2,%eax
  102299:	01 d0                	add    %edx,%eax
  10229b:	01 c0                	add    %eax,%eax
  10229d:	01 d8                	add    %ebx,%eax
  10229f:	83 e8 30             	sub    $0x30,%eax
  1022a2:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  1022a5:	8b 45 10             	mov    0x10(%ebp),%eax
  1022a8:	0f b6 00             	movzbl (%eax),%eax
  1022ab:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  1022ae:	83 fb 2f             	cmp    $0x2f,%ebx
  1022b1:	7e 21                	jle    1022d4 <vprintfmt+0x139>
  1022b3:	83 fb 39             	cmp    $0x39,%ebx
  1022b6:	7f 1f                	jg     1022d7 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1022b8:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  1022bc:	eb d3                	jmp    102291 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  1022be:	8b 45 14             	mov    0x14(%ebp),%eax
  1022c1:	83 c0 04             	add    $0x4,%eax
  1022c4:	89 45 14             	mov    %eax,0x14(%ebp)
  1022c7:	8b 45 14             	mov    0x14(%ebp),%eax
  1022ca:	83 e8 04             	sub    $0x4,%eax
  1022cd:	8b 00                	mov    (%eax),%eax
  1022cf:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1022d2:	eb 04                	jmp    1022d8 <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  1022d4:	90                   	nop
  1022d5:	eb 01                	jmp    1022d8 <vprintfmt+0x13d>
  1022d7:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  1022d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1022db:	83 e0 08             	and    $0x8,%eax
  1022de:	85 c0                	test   %eax,%eax
  1022e0:	0f 85 4a ff ff ff    	jne    102230 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  1022e6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1022e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  1022ec:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  1022f3:	e9 39 ff ff ff       	jmp    102231 <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  1022f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1022fb:	83 c8 08             	or     $0x8,%eax
  1022fe:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102301:	e9 2b ff ff ff       	jmp    102231 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  102306:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102309:	83 c8 04             	or     $0x4,%eax
  10230c:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10230f:	e9 1d ff ff ff       	jmp    102231 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  102314:	8b 55 e0             	mov    -0x20(%ebp),%edx
  102317:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10231a:	83 e0 01             	and    $0x1,%eax
  10231d:	84 c0                	test   %al,%al
  10231f:	74 07                	je     102328 <vprintfmt+0x18d>
  102321:	b8 02 00 00 00       	mov    $0x2,%eax
  102326:	eb 05                	jmp    10232d <vprintfmt+0x192>
  102328:	b8 01 00 00 00       	mov    $0x1,%eax
  10232d:	09 d0                	or     %edx,%eax
  10232f:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102332:	e9 fa fe ff ff       	jmp    102231 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  102337:	8b 45 14             	mov    0x14(%ebp),%eax
  10233a:	83 c0 04             	add    $0x4,%eax
  10233d:	89 45 14             	mov    %eax,0x14(%ebp)
  102340:	8b 45 14             	mov    0x14(%ebp),%eax
  102343:	83 e8 04             	sub    $0x4,%eax
  102346:	8b 00                	mov    (%eax),%eax
  102348:	8b 55 0c             	mov    0xc(%ebp),%edx
  10234b:	89 54 24 04          	mov    %edx,0x4(%esp)
  10234f:	89 04 24             	mov    %eax,(%esp)
  102352:	8b 45 08             	mov    0x8(%ebp),%eax
  102355:	ff d0                	call   *%eax
			break;
  102357:	e9 cb 01 00 00       	jmp    102527 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  10235c:	8b 45 14             	mov    0x14(%ebp),%eax
  10235f:	83 c0 04             	add    $0x4,%eax
  102362:	89 45 14             	mov    %eax,0x14(%ebp)
  102365:	8b 45 14             	mov    0x14(%ebp),%eax
  102368:	83 e8 04             	sub    $0x4,%eax
  10236b:	8b 00                	mov    (%eax),%eax
  10236d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102370:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102374:	75 07                	jne    10237d <vprintfmt+0x1e2>
				s = "(null)";
  102376:	c7 45 f4 cd 35 10 00 	movl   $0x1035cd,-0xc(%ebp)
			putstr(&st, s, st.prec);
  10237d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102380:	89 44 24 08          	mov    %eax,0x8(%esp)
  102384:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102387:	89 44 24 04          	mov    %eax,0x4(%esp)
  10238b:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10238e:	89 04 24             	mov    %eax,(%esp)
  102391:	e8 0c fc ff ff       	call   101fa2 <putstr>
			break;
  102396:	e9 8c 01 00 00       	jmp    102527 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  10239b:	8d 45 14             	lea    0x14(%ebp),%eax
  10239e:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023a2:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1023a5:	89 04 24             	mov    %eax,(%esp)
  1023a8:	e8 43 fb ff ff       	call   101ef0 <getint>
  1023ad:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1023b0:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  1023b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1023b6:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1023b9:	85 d2                	test   %edx,%edx
  1023bb:	79 1a                	jns    1023d7 <vprintfmt+0x23c>
				num = -(intmax_t) num;
  1023bd:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1023c0:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1023c3:	f7 d8                	neg    %eax
  1023c5:	83 d2 00             	adc    $0x0,%edx
  1023c8:	f7 da                	neg    %edx
  1023ca:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1023cd:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  1023d0:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  1023d7:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1023de:	00 
  1023df:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1023e2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1023e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023e9:	89 54 24 08          	mov    %edx,0x8(%esp)
  1023ed:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1023f0:	89 04 24             	mov    %eax,(%esp)
  1023f3:	e8 3b fd ff ff       	call   102133 <putint>
			break;
  1023f8:	e9 2a 01 00 00       	jmp    102527 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  1023fd:	8d 45 14             	lea    0x14(%ebp),%eax
  102400:	89 44 24 04          	mov    %eax,0x4(%esp)
  102404:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102407:	89 04 24             	mov    %eax,(%esp)
  10240a:	e8 6c fa ff ff       	call   101e7b <getuint>
  10240f:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  102416:	00 
  102417:	89 44 24 04          	mov    %eax,0x4(%esp)
  10241b:	89 54 24 08          	mov    %edx,0x8(%esp)
  10241f:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102422:	89 04 24             	mov    %eax,(%esp)
  102425:	e8 09 fd ff ff       	call   102133 <putint>
			break;
  10242a:	e9 f8 00 00 00       	jmp    102527 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  10242f:	8d 45 14             	lea    0x14(%ebp),%eax
  102432:	89 44 24 04          	mov    %eax,0x4(%esp)
  102436:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102439:	89 04 24             	mov    %eax,(%esp)
  10243c:	e8 3a fa ff ff       	call   101e7b <getuint>
  102441:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  102448:	00 
  102449:	89 44 24 04          	mov    %eax,0x4(%esp)
  10244d:	89 54 24 08          	mov    %edx,0x8(%esp)
  102451:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102454:	89 04 24             	mov    %eax,(%esp)
  102457:	e8 d7 fc ff ff       	call   102133 <putint>
			break;
  10245c:	e9 c6 00 00 00       	jmp    102527 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  102461:	8d 45 14             	lea    0x14(%ebp),%eax
  102464:	89 44 24 04          	mov    %eax,0x4(%esp)
  102468:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10246b:	89 04 24             	mov    %eax,(%esp)
  10246e:	e8 08 fa ff ff       	call   101e7b <getuint>
  102473:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10247a:	00 
  10247b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10247f:	89 54 24 08          	mov    %edx,0x8(%esp)
  102483:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102486:	89 04 24             	mov    %eax,(%esp)
  102489:	e8 a5 fc ff ff       	call   102133 <putint>
			break;
  10248e:	e9 94 00 00 00       	jmp    102527 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  102493:	8b 45 0c             	mov    0xc(%ebp),%eax
  102496:	89 44 24 04          	mov    %eax,0x4(%esp)
  10249a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  1024a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1024a4:	ff d0                	call   *%eax
			putch('x', putdat);
  1024a6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024a9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024ad:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  1024b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1024b7:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  1024b9:	8b 45 14             	mov    0x14(%ebp),%eax
  1024bc:	83 c0 04             	add    $0x4,%eax
  1024bf:	89 45 14             	mov    %eax,0x14(%ebp)
  1024c2:	8b 45 14             	mov    0x14(%ebp),%eax
  1024c5:	83 e8 04             	sub    $0x4,%eax
  1024c8:	8b 00                	mov    (%eax),%eax
  1024ca:	ba 00 00 00 00       	mov    $0x0,%edx
  1024cf:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1024d6:	00 
  1024d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024db:	89 54 24 08          	mov    %edx,0x8(%esp)
  1024df:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1024e2:	89 04 24             	mov    %eax,(%esp)
  1024e5:	e8 49 fc ff ff       	call   102133 <putint>
			break;
  1024ea:	eb 3b                	jmp    102527 <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  1024ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024f3:	89 1c 24             	mov    %ebx,(%esp)
  1024f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1024f9:	ff d0                	call   *%eax
			break;
  1024fb:	eb 2a                	jmp    102527 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1024fd:	8b 45 0c             	mov    0xc(%ebp),%eax
  102500:	89 44 24 04          	mov    %eax,0x4(%esp)
  102504:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  10250b:	8b 45 08             	mov    0x8(%ebp),%eax
  10250e:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  102510:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102514:	eb 04                	jmp    10251a <vprintfmt+0x37f>
  102516:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10251a:	8b 45 10             	mov    0x10(%ebp),%eax
  10251d:	83 e8 01             	sub    $0x1,%eax
  102520:	0f b6 00             	movzbl (%eax),%eax
  102523:	3c 25                	cmp    $0x25,%al
  102525:	75 ef                	jne    102516 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  102527:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102528:	e9 bd fc ff ff       	jmp    1021ea <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  10252d:	83 c4 44             	add    $0x44,%esp
  102530:	5b                   	pop    %ebx
  102531:	5d                   	pop    %ebp
  102532:	c3                   	ret    

00102533 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  102533:	55                   	push   %ebp
  102534:	89 e5                	mov    %esp,%ebp
  102536:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  102539:	8b 45 0c             	mov    0xc(%ebp),%eax
  10253c:	8b 00                	mov    (%eax),%eax
  10253e:	8b 55 08             	mov    0x8(%ebp),%edx
  102541:	89 d1                	mov    %edx,%ecx
  102543:	8b 55 0c             	mov    0xc(%ebp),%edx
  102546:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  10254a:	8d 50 01             	lea    0x1(%eax),%edx
  10254d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102550:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  102552:	8b 45 0c             	mov    0xc(%ebp),%eax
  102555:	8b 00                	mov    (%eax),%eax
  102557:	3d ff 00 00 00       	cmp    $0xff,%eax
  10255c:	75 24                	jne    102582 <putch+0x4f>
		b->buf[b->idx] = 0;
  10255e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102561:	8b 00                	mov    (%eax),%eax
  102563:	8b 55 0c             	mov    0xc(%ebp),%edx
  102566:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  10256b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10256e:	83 c0 08             	add    $0x8,%eax
  102571:	89 04 24             	mov    %eax,(%esp)
  102574:	e8 87 dd ff ff       	call   100300 <cputs>
		b->idx = 0;
  102579:	8b 45 0c             	mov    0xc(%ebp),%eax
  10257c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  102582:	8b 45 0c             	mov    0xc(%ebp),%eax
  102585:	8b 40 04             	mov    0x4(%eax),%eax
  102588:	8d 50 01             	lea    0x1(%eax),%edx
  10258b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10258e:	89 50 04             	mov    %edx,0x4(%eax)
}
  102591:	c9                   	leave  
  102592:	c3                   	ret    

00102593 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  102593:	55                   	push   %ebp
  102594:	89 e5                	mov    %esp,%ebp
  102596:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  10259c:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  1025a3:	00 00 00 
	b.cnt = 0;
  1025a6:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  1025ad:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  1025b0:	b8 33 25 10 00       	mov    $0x102533,%eax
  1025b5:	8b 55 0c             	mov    0xc(%ebp),%edx
  1025b8:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1025bc:	8b 55 08             	mov    0x8(%ebp),%edx
  1025bf:	89 54 24 08          	mov    %edx,0x8(%esp)
  1025c3:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  1025c9:	89 54 24 04          	mov    %edx,0x4(%esp)
  1025cd:	89 04 24             	mov    %eax,(%esp)
  1025d0:	e8 c6 fb ff ff       	call   10219b <vprintfmt>

	b.buf[b.idx] = 0;
  1025d5:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  1025db:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  1025e2:	00 
	cputs(b.buf);
  1025e3:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1025e9:	83 c0 08             	add    $0x8,%eax
  1025ec:	89 04 24             	mov    %eax,(%esp)
  1025ef:	e8 0c dd ff ff       	call   100300 <cputs>

	return b.cnt;
  1025f4:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  1025fa:	c9                   	leave  
  1025fb:	c3                   	ret    

001025fc <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1025fc:	55                   	push   %ebp
  1025fd:	89 e5                	mov    %esp,%ebp
  1025ff:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  102602:	8d 45 08             	lea    0x8(%ebp),%eax
  102605:	83 c0 04             	add    $0x4,%eax
  102608:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  10260b:	8b 45 08             	mov    0x8(%ebp),%eax
  10260e:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102611:	89 54 24 04          	mov    %edx,0x4(%esp)
  102615:	89 04 24             	mov    %eax,(%esp)
  102618:	e8 76 ff ff ff       	call   102593 <vcprintf>
  10261d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  102620:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  102623:	c9                   	leave  
  102624:	c3                   	ret    

00102625 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  102625:	55                   	push   %ebp
  102626:	89 e5                	mov    %esp,%ebp
  102628:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  10262b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  102632:	eb 08                	jmp    10263c <strlen+0x17>
		n++;
  102634:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  102638:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10263c:	8b 45 08             	mov    0x8(%ebp),%eax
  10263f:	0f b6 00             	movzbl (%eax),%eax
  102642:	84 c0                	test   %al,%al
  102644:	75 ee                	jne    102634 <strlen+0xf>
		n++;
	return n;
  102646:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102649:	c9                   	leave  
  10264a:	c3                   	ret    

0010264b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  10264b:	55                   	push   %ebp
  10264c:	89 e5                	mov    %esp,%ebp
  10264e:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  102651:	8b 45 08             	mov    0x8(%ebp),%eax
  102654:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  102657:	8b 45 0c             	mov    0xc(%ebp),%eax
  10265a:	0f b6 10             	movzbl (%eax),%edx
  10265d:	8b 45 08             	mov    0x8(%ebp),%eax
  102660:	88 10                	mov    %dl,(%eax)
  102662:	8b 45 08             	mov    0x8(%ebp),%eax
  102665:	0f b6 00             	movzbl (%eax),%eax
  102668:	84 c0                	test   %al,%al
  10266a:	0f 95 c0             	setne  %al
  10266d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102671:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  102675:	84 c0                	test   %al,%al
  102677:	75 de                	jne    102657 <strcpy+0xc>
		/* do nothing */;
	return ret;
  102679:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10267c:	c9                   	leave  
  10267d:	c3                   	ret    

0010267e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  10267e:	55                   	push   %ebp
  10267f:	89 e5                	mov    %esp,%ebp
  102681:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  102684:	8b 45 08             	mov    0x8(%ebp),%eax
  102687:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  10268a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  102691:	eb 21                	jmp    1026b4 <strncpy+0x36>
		*dst++ = *src;
  102693:	8b 45 0c             	mov    0xc(%ebp),%eax
  102696:	0f b6 10             	movzbl (%eax),%edx
  102699:	8b 45 08             	mov    0x8(%ebp),%eax
  10269c:	88 10                	mov    %dl,(%eax)
  10269e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  1026a2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026a5:	0f b6 00             	movzbl (%eax),%eax
  1026a8:	84 c0                	test   %al,%al
  1026aa:	74 04                	je     1026b0 <strncpy+0x32>
			src++;
  1026ac:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  1026b0:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1026b4:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1026b7:	3b 45 10             	cmp    0x10(%ebp),%eax
  1026ba:	72 d7                	jb     102693 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  1026bc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1026bf:	c9                   	leave  
  1026c0:	c3                   	ret    

001026c1 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  1026c1:	55                   	push   %ebp
  1026c2:	89 e5                	mov    %esp,%ebp
  1026c4:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  1026c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1026ca:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  1026cd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1026d1:	74 2f                	je     102702 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  1026d3:	eb 13                	jmp    1026e8 <strlcpy+0x27>
			*dst++ = *src++;
  1026d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026d8:	0f b6 10             	movzbl (%eax),%edx
  1026db:	8b 45 08             	mov    0x8(%ebp),%eax
  1026de:	88 10                	mov    %dl,(%eax)
  1026e0:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1026e4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  1026e8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1026ec:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1026f0:	74 0a                	je     1026fc <strlcpy+0x3b>
  1026f2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026f5:	0f b6 00             	movzbl (%eax),%eax
  1026f8:	84 c0                	test   %al,%al
  1026fa:	75 d9                	jne    1026d5 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  1026fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1026ff:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  102702:	8b 55 08             	mov    0x8(%ebp),%edx
  102705:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102708:	89 d1                	mov    %edx,%ecx
  10270a:	29 c1                	sub    %eax,%ecx
  10270c:	89 c8                	mov    %ecx,%eax
}
  10270e:	c9                   	leave  
  10270f:	c3                   	ret    

00102710 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  102710:	55                   	push   %ebp
  102711:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  102713:	eb 08                	jmp    10271d <strcmp+0xd>
		p++, q++;
  102715:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102719:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  10271d:	8b 45 08             	mov    0x8(%ebp),%eax
  102720:	0f b6 00             	movzbl (%eax),%eax
  102723:	84 c0                	test   %al,%al
  102725:	74 10                	je     102737 <strcmp+0x27>
  102727:	8b 45 08             	mov    0x8(%ebp),%eax
  10272a:	0f b6 10             	movzbl (%eax),%edx
  10272d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102730:	0f b6 00             	movzbl (%eax),%eax
  102733:	38 c2                	cmp    %al,%dl
  102735:	74 de                	je     102715 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  102737:	8b 45 08             	mov    0x8(%ebp),%eax
  10273a:	0f b6 00             	movzbl (%eax),%eax
  10273d:	0f b6 d0             	movzbl %al,%edx
  102740:	8b 45 0c             	mov    0xc(%ebp),%eax
  102743:	0f b6 00             	movzbl (%eax),%eax
  102746:	0f b6 c0             	movzbl %al,%eax
  102749:	89 d1                	mov    %edx,%ecx
  10274b:	29 c1                	sub    %eax,%ecx
  10274d:	89 c8                	mov    %ecx,%eax
}
  10274f:	5d                   	pop    %ebp
  102750:	c3                   	ret    

00102751 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  102751:	55                   	push   %ebp
  102752:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  102754:	eb 0c                	jmp    102762 <strncmp+0x11>
		n--, p++, q++;
  102756:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10275a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10275e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  102762:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102766:	74 1a                	je     102782 <strncmp+0x31>
  102768:	8b 45 08             	mov    0x8(%ebp),%eax
  10276b:	0f b6 00             	movzbl (%eax),%eax
  10276e:	84 c0                	test   %al,%al
  102770:	74 10                	je     102782 <strncmp+0x31>
  102772:	8b 45 08             	mov    0x8(%ebp),%eax
  102775:	0f b6 10             	movzbl (%eax),%edx
  102778:	8b 45 0c             	mov    0xc(%ebp),%eax
  10277b:	0f b6 00             	movzbl (%eax),%eax
  10277e:	38 c2                	cmp    %al,%dl
  102780:	74 d4                	je     102756 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  102782:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102786:	75 07                	jne    10278f <strncmp+0x3e>
		return 0;
  102788:	b8 00 00 00 00       	mov    $0x0,%eax
  10278d:	eb 18                	jmp    1027a7 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  10278f:	8b 45 08             	mov    0x8(%ebp),%eax
  102792:	0f b6 00             	movzbl (%eax),%eax
  102795:	0f b6 d0             	movzbl %al,%edx
  102798:	8b 45 0c             	mov    0xc(%ebp),%eax
  10279b:	0f b6 00             	movzbl (%eax),%eax
  10279e:	0f b6 c0             	movzbl %al,%eax
  1027a1:	89 d1                	mov    %edx,%ecx
  1027a3:	29 c1                	sub    %eax,%ecx
  1027a5:	89 c8                	mov    %ecx,%eax
}
  1027a7:	5d                   	pop    %ebp
  1027a8:	c3                   	ret    

001027a9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  1027a9:	55                   	push   %ebp
  1027aa:	89 e5                	mov    %esp,%ebp
  1027ac:	83 ec 04             	sub    $0x4,%esp
  1027af:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027b2:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  1027b5:	eb 1a                	jmp    1027d1 <strchr+0x28>
		if (*s++ == 0)
  1027b7:	8b 45 08             	mov    0x8(%ebp),%eax
  1027ba:	0f b6 00             	movzbl (%eax),%eax
  1027bd:	84 c0                	test   %al,%al
  1027bf:	0f 94 c0             	sete   %al
  1027c2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1027c6:	84 c0                	test   %al,%al
  1027c8:	74 07                	je     1027d1 <strchr+0x28>
			return NULL;
  1027ca:	b8 00 00 00 00       	mov    $0x0,%eax
  1027cf:	eb 0e                	jmp    1027df <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  1027d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1027d4:	0f b6 00             	movzbl (%eax),%eax
  1027d7:	3a 45 fc             	cmp    -0x4(%ebp),%al
  1027da:	75 db                	jne    1027b7 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  1027dc:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1027df:	c9                   	leave  
  1027e0:	c3                   	ret    

001027e1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  1027e1:	55                   	push   %ebp
  1027e2:	89 e5                	mov    %esp,%ebp
  1027e4:	57                   	push   %edi
  1027e5:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  1027e8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1027ec:	75 05                	jne    1027f3 <memset+0x12>
		return v;
  1027ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1027f1:	eb 5c                	jmp    10284f <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  1027f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1027f6:	83 e0 03             	and    $0x3,%eax
  1027f9:	85 c0                	test   %eax,%eax
  1027fb:	75 41                	jne    10283e <memset+0x5d>
  1027fd:	8b 45 10             	mov    0x10(%ebp),%eax
  102800:	83 e0 03             	and    $0x3,%eax
  102803:	85 c0                	test   %eax,%eax
  102805:	75 37                	jne    10283e <memset+0x5d>
		c &= 0xFF;
  102807:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  10280e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102811:	89 c2                	mov    %eax,%edx
  102813:	c1 e2 18             	shl    $0x18,%edx
  102816:	8b 45 0c             	mov    0xc(%ebp),%eax
  102819:	c1 e0 10             	shl    $0x10,%eax
  10281c:	09 c2                	or     %eax,%edx
  10281e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102821:	c1 e0 08             	shl    $0x8,%eax
  102824:	09 d0                	or     %edx,%eax
  102826:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  102829:	8b 45 10             	mov    0x10(%ebp),%eax
  10282c:	89 c1                	mov    %eax,%ecx
  10282e:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  102831:	8b 55 08             	mov    0x8(%ebp),%edx
  102834:	8b 45 0c             	mov    0xc(%ebp),%eax
  102837:	89 d7                	mov    %edx,%edi
  102839:	fc                   	cld    
  10283a:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  10283c:	eb 0e                	jmp    10284c <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  10283e:	8b 55 08             	mov    0x8(%ebp),%edx
  102841:	8b 45 0c             	mov    0xc(%ebp),%eax
  102844:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102847:	89 d7                	mov    %edx,%edi
  102849:	fc                   	cld    
  10284a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  10284c:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10284f:	83 c4 10             	add    $0x10,%esp
  102852:	5f                   	pop    %edi
  102853:	5d                   	pop    %ebp
  102854:	c3                   	ret    

00102855 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  102855:	55                   	push   %ebp
  102856:	89 e5                	mov    %esp,%ebp
  102858:	57                   	push   %edi
  102859:	56                   	push   %esi
  10285a:	53                   	push   %ebx
  10285b:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  10285e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102861:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  102864:	8b 45 08             	mov    0x8(%ebp),%eax
  102867:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  10286a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10286d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102870:	73 6e                	jae    1028e0 <memmove+0x8b>
  102872:	8b 45 10             	mov    0x10(%ebp),%eax
  102875:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102878:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10287b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10287e:	76 60                	jbe    1028e0 <memmove+0x8b>
		s += n;
  102880:	8b 45 10             	mov    0x10(%ebp),%eax
  102883:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  102886:	8b 45 10             	mov    0x10(%ebp),%eax
  102889:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10288c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10288f:	83 e0 03             	and    $0x3,%eax
  102892:	85 c0                	test   %eax,%eax
  102894:	75 2f                	jne    1028c5 <memmove+0x70>
  102896:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102899:	83 e0 03             	and    $0x3,%eax
  10289c:	85 c0                	test   %eax,%eax
  10289e:	75 25                	jne    1028c5 <memmove+0x70>
  1028a0:	8b 45 10             	mov    0x10(%ebp),%eax
  1028a3:	83 e0 03             	and    $0x3,%eax
  1028a6:	85 c0                	test   %eax,%eax
  1028a8:	75 1b                	jne    1028c5 <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  1028aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028ad:	83 e8 04             	sub    $0x4,%eax
  1028b0:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1028b3:	83 ea 04             	sub    $0x4,%edx
  1028b6:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1028b9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  1028bc:	89 c7                	mov    %eax,%edi
  1028be:	89 d6                	mov    %edx,%esi
  1028c0:	fd                   	std    
  1028c1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1028c3:	eb 18                	jmp    1028dd <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  1028c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028c8:	8d 50 ff             	lea    -0x1(%eax),%edx
  1028cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1028ce:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  1028d1:	8b 45 10             	mov    0x10(%ebp),%eax
  1028d4:	89 d7                	mov    %edx,%edi
  1028d6:	89 de                	mov    %ebx,%esi
  1028d8:	89 c1                	mov    %eax,%ecx
  1028da:	fd                   	std    
  1028db:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  1028dd:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  1028de:	eb 45                	jmp    102925 <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1028e0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1028e3:	83 e0 03             	and    $0x3,%eax
  1028e6:	85 c0                	test   %eax,%eax
  1028e8:	75 2b                	jne    102915 <memmove+0xc0>
  1028ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028ed:	83 e0 03             	and    $0x3,%eax
  1028f0:	85 c0                	test   %eax,%eax
  1028f2:	75 21                	jne    102915 <memmove+0xc0>
  1028f4:	8b 45 10             	mov    0x10(%ebp),%eax
  1028f7:	83 e0 03             	and    $0x3,%eax
  1028fa:	85 c0                	test   %eax,%eax
  1028fc:	75 17                	jne    102915 <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  1028fe:	8b 45 10             	mov    0x10(%ebp),%eax
  102901:	89 c1                	mov    %eax,%ecx
  102903:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  102906:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102909:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10290c:	89 c7                	mov    %eax,%edi
  10290e:	89 d6                	mov    %edx,%esi
  102910:	fc                   	cld    
  102911:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102913:	eb 10                	jmp    102925 <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  102915:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102918:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10291b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10291e:	89 c7                	mov    %eax,%edi
  102920:	89 d6                	mov    %edx,%esi
  102922:	fc                   	cld    
  102923:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  102925:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102928:	83 c4 10             	add    $0x10,%esp
  10292b:	5b                   	pop    %ebx
  10292c:	5e                   	pop    %esi
  10292d:	5f                   	pop    %edi
  10292e:	5d                   	pop    %ebp
  10292f:	c3                   	ret    

00102930 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  102930:	55                   	push   %ebp
  102931:	89 e5                	mov    %esp,%ebp
  102933:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  102936:	8b 45 10             	mov    0x10(%ebp),%eax
  102939:	89 44 24 08          	mov    %eax,0x8(%esp)
  10293d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102940:	89 44 24 04          	mov    %eax,0x4(%esp)
  102944:	8b 45 08             	mov    0x8(%ebp),%eax
  102947:	89 04 24             	mov    %eax,(%esp)
  10294a:	e8 06 ff ff ff       	call   102855 <memmove>
}
  10294f:	c9                   	leave  
  102950:	c3                   	ret    

00102951 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  102951:	55                   	push   %ebp
  102952:	89 e5                	mov    %esp,%ebp
  102954:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  102957:	8b 45 08             	mov    0x8(%ebp),%eax
  10295a:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  10295d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102960:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  102963:	eb 32                	jmp    102997 <memcmp+0x46>
		if (*s1 != *s2)
  102965:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102968:	0f b6 10             	movzbl (%eax),%edx
  10296b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10296e:	0f b6 00             	movzbl (%eax),%eax
  102971:	38 c2                	cmp    %al,%dl
  102973:	74 1a                	je     10298f <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  102975:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102978:	0f b6 00             	movzbl (%eax),%eax
  10297b:	0f b6 d0             	movzbl %al,%edx
  10297e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102981:	0f b6 00             	movzbl (%eax),%eax
  102984:	0f b6 c0             	movzbl %al,%eax
  102987:	89 d1                	mov    %edx,%ecx
  102989:	29 c1                	sub    %eax,%ecx
  10298b:	89 c8                	mov    %ecx,%eax
  10298d:	eb 1c                	jmp    1029ab <memcmp+0x5a>
		s1++, s2++;
  10298f:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  102993:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  102997:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10299b:	0f 95 c0             	setne  %al
  10299e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1029a2:	84 c0                	test   %al,%al
  1029a4:	75 bf                	jne    102965 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  1029a6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1029ab:	c9                   	leave  
  1029ac:	c3                   	ret    

001029ad <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  1029ad:	55                   	push   %ebp
  1029ae:	89 e5                	mov    %esp,%ebp
  1029b0:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  1029b3:	8b 45 10             	mov    0x10(%ebp),%eax
  1029b6:	8b 55 08             	mov    0x8(%ebp),%edx
  1029b9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1029bc:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  1029bf:	eb 16                	jmp    1029d7 <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  1029c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1029c4:	0f b6 10             	movzbl (%eax),%edx
  1029c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1029ca:	38 c2                	cmp    %al,%dl
  1029cc:	75 05                	jne    1029d3 <memchr+0x26>
			return (void *) s;
  1029ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1029d1:	eb 11                	jmp    1029e4 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  1029d3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1029d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1029da:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  1029dd:	72 e2                	jb     1029c1 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  1029df:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1029e4:	c9                   	leave  
  1029e5:	c3                   	ret    
  1029e6:	66 90                	xchg   %ax,%ax
  1029e8:	66 90                	xchg   %ax,%ax
  1029ea:	66 90                	xchg   %ax,%ax
  1029ec:	66 90                	xchg   %ax,%ax
  1029ee:	66 90                	xchg   %ax,%ax

001029f0 <__udivdi3>:
  1029f0:	55                   	push   %ebp
  1029f1:	89 e5                	mov    %esp,%ebp
  1029f3:	57                   	push   %edi
  1029f4:	56                   	push   %esi
  1029f5:	83 ec 10             	sub    $0x10,%esp
  1029f8:	8b 45 14             	mov    0x14(%ebp),%eax
  1029fb:	8b 55 08             	mov    0x8(%ebp),%edx
  1029fe:	8b 75 10             	mov    0x10(%ebp),%esi
  102a01:	8b 7d 0c             	mov    0xc(%ebp),%edi
  102a04:	85 c0                	test   %eax,%eax
  102a06:	89 55 f0             	mov    %edx,-0x10(%ebp)
  102a09:	75 35                	jne    102a40 <__udivdi3+0x50>
  102a0b:	39 fe                	cmp    %edi,%esi
  102a0d:	77 61                	ja     102a70 <__udivdi3+0x80>
  102a0f:	85 f6                	test   %esi,%esi
  102a11:	75 0b                	jne    102a1e <__udivdi3+0x2e>
  102a13:	b8 01 00 00 00       	mov    $0x1,%eax
  102a18:	31 d2                	xor    %edx,%edx
  102a1a:	f7 f6                	div    %esi
  102a1c:	89 c6                	mov    %eax,%esi
  102a1e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  102a21:	31 d2                	xor    %edx,%edx
  102a23:	89 f8                	mov    %edi,%eax
  102a25:	f7 f6                	div    %esi
  102a27:	89 c7                	mov    %eax,%edi
  102a29:	89 c8                	mov    %ecx,%eax
  102a2b:	f7 f6                	div    %esi
  102a2d:	89 c1                	mov    %eax,%ecx
  102a2f:	89 fa                	mov    %edi,%edx
  102a31:	89 c8                	mov    %ecx,%eax
  102a33:	83 c4 10             	add    $0x10,%esp
  102a36:	5e                   	pop    %esi
  102a37:	5f                   	pop    %edi
  102a38:	5d                   	pop    %ebp
  102a39:	c3                   	ret    
  102a3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102a40:	39 f8                	cmp    %edi,%eax
  102a42:	77 1c                	ja     102a60 <__udivdi3+0x70>
  102a44:	0f bd d0             	bsr    %eax,%edx
  102a47:	83 f2 1f             	xor    $0x1f,%edx
  102a4a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102a4d:	75 39                	jne    102a88 <__udivdi3+0x98>
  102a4f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  102a52:	0f 86 a0 00 00 00    	jbe    102af8 <__udivdi3+0x108>
  102a58:	39 f8                	cmp    %edi,%eax
  102a5a:	0f 82 98 00 00 00    	jb     102af8 <__udivdi3+0x108>
  102a60:	31 ff                	xor    %edi,%edi
  102a62:	31 c9                	xor    %ecx,%ecx
  102a64:	89 c8                	mov    %ecx,%eax
  102a66:	89 fa                	mov    %edi,%edx
  102a68:	83 c4 10             	add    $0x10,%esp
  102a6b:	5e                   	pop    %esi
  102a6c:	5f                   	pop    %edi
  102a6d:	5d                   	pop    %ebp
  102a6e:	c3                   	ret    
  102a6f:	90                   	nop
  102a70:	89 d1                	mov    %edx,%ecx
  102a72:	89 fa                	mov    %edi,%edx
  102a74:	89 c8                	mov    %ecx,%eax
  102a76:	31 ff                	xor    %edi,%edi
  102a78:	f7 f6                	div    %esi
  102a7a:	89 c1                	mov    %eax,%ecx
  102a7c:	89 fa                	mov    %edi,%edx
  102a7e:	89 c8                	mov    %ecx,%eax
  102a80:	83 c4 10             	add    $0x10,%esp
  102a83:	5e                   	pop    %esi
  102a84:	5f                   	pop    %edi
  102a85:	5d                   	pop    %ebp
  102a86:	c3                   	ret    
  102a87:	90                   	nop
  102a88:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102a8c:	89 f2                	mov    %esi,%edx
  102a8e:	d3 e0                	shl    %cl,%eax
  102a90:	89 45 ec             	mov    %eax,-0x14(%ebp)
  102a93:	b8 20 00 00 00       	mov    $0x20,%eax
  102a98:	2b 45 f4             	sub    -0xc(%ebp),%eax
  102a9b:	89 c1                	mov    %eax,%ecx
  102a9d:	d3 ea                	shr    %cl,%edx
  102a9f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102aa3:	0b 55 ec             	or     -0x14(%ebp),%edx
  102aa6:	d3 e6                	shl    %cl,%esi
  102aa8:	89 c1                	mov    %eax,%ecx
  102aaa:	89 75 e8             	mov    %esi,-0x18(%ebp)
  102aad:	89 fe                	mov    %edi,%esi
  102aaf:	d3 ee                	shr    %cl,%esi
  102ab1:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102ab5:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102ab8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102abb:	d3 e7                	shl    %cl,%edi
  102abd:	89 c1                	mov    %eax,%ecx
  102abf:	d3 ea                	shr    %cl,%edx
  102ac1:	09 d7                	or     %edx,%edi
  102ac3:	89 f2                	mov    %esi,%edx
  102ac5:	89 f8                	mov    %edi,%eax
  102ac7:	f7 75 ec             	divl   -0x14(%ebp)
  102aca:	89 d6                	mov    %edx,%esi
  102acc:	89 c7                	mov    %eax,%edi
  102ace:	f7 65 e8             	mull   -0x18(%ebp)
  102ad1:	39 d6                	cmp    %edx,%esi
  102ad3:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102ad6:	72 30                	jb     102b08 <__udivdi3+0x118>
  102ad8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102adb:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102adf:	d3 e2                	shl    %cl,%edx
  102ae1:	39 c2                	cmp    %eax,%edx
  102ae3:	73 05                	jae    102aea <__udivdi3+0xfa>
  102ae5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  102ae8:	74 1e                	je     102b08 <__udivdi3+0x118>
  102aea:	89 f9                	mov    %edi,%ecx
  102aec:	31 ff                	xor    %edi,%edi
  102aee:	e9 71 ff ff ff       	jmp    102a64 <__udivdi3+0x74>
  102af3:	90                   	nop
  102af4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102af8:	31 ff                	xor    %edi,%edi
  102afa:	b9 01 00 00 00       	mov    $0x1,%ecx
  102aff:	e9 60 ff ff ff       	jmp    102a64 <__udivdi3+0x74>
  102b04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102b08:	8d 4f ff             	lea    -0x1(%edi),%ecx
  102b0b:	31 ff                	xor    %edi,%edi
  102b0d:	89 c8                	mov    %ecx,%eax
  102b0f:	89 fa                	mov    %edi,%edx
  102b11:	83 c4 10             	add    $0x10,%esp
  102b14:	5e                   	pop    %esi
  102b15:	5f                   	pop    %edi
  102b16:	5d                   	pop    %ebp
  102b17:	c3                   	ret    
  102b18:	66 90                	xchg   %ax,%ax
  102b1a:	66 90                	xchg   %ax,%ax
  102b1c:	66 90                	xchg   %ax,%ax
  102b1e:	66 90                	xchg   %ax,%ax

00102b20 <__umoddi3>:
  102b20:	55                   	push   %ebp
  102b21:	89 e5                	mov    %esp,%ebp
  102b23:	57                   	push   %edi
  102b24:	56                   	push   %esi
  102b25:	83 ec 20             	sub    $0x20,%esp
  102b28:	8b 55 14             	mov    0x14(%ebp),%edx
  102b2b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102b2e:	8b 7d 10             	mov    0x10(%ebp),%edi
  102b31:	8b 75 0c             	mov    0xc(%ebp),%esi
  102b34:	85 d2                	test   %edx,%edx
  102b36:	89 c8                	mov    %ecx,%eax
  102b38:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  102b3b:	75 13                	jne    102b50 <__umoddi3+0x30>
  102b3d:	39 f7                	cmp    %esi,%edi
  102b3f:	76 3f                	jbe    102b80 <__umoddi3+0x60>
  102b41:	89 f2                	mov    %esi,%edx
  102b43:	f7 f7                	div    %edi
  102b45:	89 d0                	mov    %edx,%eax
  102b47:	31 d2                	xor    %edx,%edx
  102b49:	83 c4 20             	add    $0x20,%esp
  102b4c:	5e                   	pop    %esi
  102b4d:	5f                   	pop    %edi
  102b4e:	5d                   	pop    %ebp
  102b4f:	c3                   	ret    
  102b50:	39 f2                	cmp    %esi,%edx
  102b52:	77 4c                	ja     102ba0 <__umoddi3+0x80>
  102b54:	0f bd ca             	bsr    %edx,%ecx
  102b57:	83 f1 1f             	xor    $0x1f,%ecx
  102b5a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  102b5d:	75 51                	jne    102bb0 <__umoddi3+0x90>
  102b5f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  102b62:	0f 87 e0 00 00 00    	ja     102c48 <__umoddi3+0x128>
  102b68:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b6b:	29 f8                	sub    %edi,%eax
  102b6d:	19 d6                	sbb    %edx,%esi
  102b6f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102b72:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b75:	89 f2                	mov    %esi,%edx
  102b77:	83 c4 20             	add    $0x20,%esp
  102b7a:	5e                   	pop    %esi
  102b7b:	5f                   	pop    %edi
  102b7c:	5d                   	pop    %ebp
  102b7d:	c3                   	ret    
  102b7e:	66 90                	xchg   %ax,%ax
  102b80:	85 ff                	test   %edi,%edi
  102b82:	75 0b                	jne    102b8f <__umoddi3+0x6f>
  102b84:	b8 01 00 00 00       	mov    $0x1,%eax
  102b89:	31 d2                	xor    %edx,%edx
  102b8b:	f7 f7                	div    %edi
  102b8d:	89 c7                	mov    %eax,%edi
  102b8f:	89 f0                	mov    %esi,%eax
  102b91:	31 d2                	xor    %edx,%edx
  102b93:	f7 f7                	div    %edi
  102b95:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102b98:	f7 f7                	div    %edi
  102b9a:	eb a9                	jmp    102b45 <__umoddi3+0x25>
  102b9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102ba0:	89 c8                	mov    %ecx,%eax
  102ba2:	89 f2                	mov    %esi,%edx
  102ba4:	83 c4 20             	add    $0x20,%esp
  102ba7:	5e                   	pop    %esi
  102ba8:	5f                   	pop    %edi
  102ba9:	5d                   	pop    %ebp
  102baa:	c3                   	ret    
  102bab:	90                   	nop
  102bac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102bb0:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102bb4:	d3 e2                	shl    %cl,%edx
  102bb6:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102bb9:	ba 20 00 00 00       	mov    $0x20,%edx
  102bbe:	2b 55 f0             	sub    -0x10(%ebp),%edx
  102bc1:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102bc4:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102bc8:	89 fa                	mov    %edi,%edx
  102bca:	d3 ea                	shr    %cl,%edx
  102bcc:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102bd0:	0b 55 f4             	or     -0xc(%ebp),%edx
  102bd3:	d3 e7                	shl    %cl,%edi
  102bd5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102bd9:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102bdc:	89 f2                	mov    %esi,%edx
  102bde:	89 7d e8             	mov    %edi,-0x18(%ebp)
  102be1:	89 c7                	mov    %eax,%edi
  102be3:	d3 ea                	shr    %cl,%edx
  102be5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102be9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  102bec:	89 c2                	mov    %eax,%edx
  102bee:	d3 e6                	shl    %cl,%esi
  102bf0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102bf4:	d3 ea                	shr    %cl,%edx
  102bf6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102bfa:	09 d6                	or     %edx,%esi
  102bfc:	89 f0                	mov    %esi,%eax
  102bfe:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  102c01:	d3 e7                	shl    %cl,%edi
  102c03:	89 f2                	mov    %esi,%edx
  102c05:	f7 75 f4             	divl   -0xc(%ebp)
  102c08:	89 d6                	mov    %edx,%esi
  102c0a:	f7 65 e8             	mull   -0x18(%ebp)
  102c0d:	39 d6                	cmp    %edx,%esi
  102c0f:	72 2b                	jb     102c3c <__umoddi3+0x11c>
  102c11:	39 c7                	cmp    %eax,%edi
  102c13:	72 23                	jb     102c38 <__umoddi3+0x118>
  102c15:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102c19:	29 c7                	sub    %eax,%edi
  102c1b:	19 d6                	sbb    %edx,%esi
  102c1d:	89 f0                	mov    %esi,%eax
  102c1f:	89 f2                	mov    %esi,%edx
  102c21:	d3 ef                	shr    %cl,%edi
  102c23:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102c27:	d3 e0                	shl    %cl,%eax
  102c29:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102c2d:	09 f8                	or     %edi,%eax
  102c2f:	d3 ea                	shr    %cl,%edx
  102c31:	83 c4 20             	add    $0x20,%esp
  102c34:	5e                   	pop    %esi
  102c35:	5f                   	pop    %edi
  102c36:	5d                   	pop    %ebp
  102c37:	c3                   	ret    
  102c38:	39 d6                	cmp    %edx,%esi
  102c3a:	75 d9                	jne    102c15 <__umoddi3+0xf5>
  102c3c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  102c3f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  102c42:	eb d1                	jmp    102c15 <__umoddi3+0xf5>
  102c44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102c48:	39 f2                	cmp    %esi,%edx
  102c4a:	0f 82 18 ff ff ff    	jb     102b68 <__umoddi3+0x48>
  102c50:	e9 1d ff ff ff       	jmp    102b72 <__umoddi3+0x52>
