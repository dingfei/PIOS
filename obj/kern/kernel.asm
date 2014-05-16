
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
  100050:	c7 44 24 0c 40 2d 10 	movl   $0x102d40,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 56 2d 10 	movl   $0x102d56,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 6b 2d 10 00 	movl   $0x102d6b,(%esp)
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
  1000c3:	e8 eb 27 00 00       	call   1028b3 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000c8:	e8 eb 01 00 00       	call   1002b8 <cons_init>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  1000cd:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  1000d4:	00 
  1000d5:	c7 04 24 78 2d 10 00 	movl   $0x102d78,(%esp)
  1000dc:	e8 ed 25 00 00       	call   1026ce <cprintf>
	debug_check();
  1000e1:	e8 ae 04 00 00       	call   100594 <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000e6:	e8 0d 0e 00 00       	call   100ef8 <cpu_init>
	trap_init();
  1000eb:	e8 ea 10 00 00       	call   1011da <trap_init>

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
  100102:	c7 04 24 93 2d 10 00 	movl   $0x102d93,(%esp)
  100109:	e8 c0 25 00 00       	call   1026ce <cprintf>

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
  10011f:	c7 44 24 0c a0 2d 10 	movl   $0x102da0,0xc(%esp)
  100126:	00 
  100127:	c7 44 24 08 56 2d 10 	movl   $0x102d56,0x8(%esp)
  10012e:	00 
  10012f:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100136:	00 
  100137:	c7 04 24 c7 2d 10 00 	movl   $0x102dc7,(%esp)
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
  100154:	c7 44 24 0c d4 2d 10 	movl   $0x102dd4,0xc(%esp)
  10015b:	00 
  10015c:	c7 44 24 08 56 2d 10 	movl   $0x102d56,0x8(%esp)
  100163:	00 
  100164:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  10016b:	00 
  10016c:	c7 04 24 c7 2d 10 00 	movl   $0x102dc7,(%esp)
  100173:	e8 b1 01 00 00       	call   100329 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  100178:	e8 63 13 00 00       	call   1014e0 <trap_check_user>

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
  1001b1:	c7 44 24 0c 0c 2e 10 	movl   $0x102e0c,0xc(%esp)
  1001b8:	00 
  1001b9:	c7 44 24 08 22 2e 10 	movl   $0x102e22,0x8(%esp)
  1001c0:	00 
  1001c1:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1001c8:	00 
  1001c9:	c7 04 24 37 2e 10 00 	movl   $0x102e37,(%esp)
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
  100245:	e8 17 1b 00 00       	call   101d61 <serial_intr>
	kbd_intr();
  10024a:	e8 6d 1a 00 00       	call   101cbc <kbd_intr>

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
  1002a6:	e8 d3 1a 00 00       	call   101d7e <serial_putc>
	video_putc(c);
  1002ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1002ae:	89 04 24             	mov    %eax,(%esp)
  1002b1:	e8 65 16 00 00       	call   10191b <video_putc>
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
  1002c7:	e8 83 15 00 00       	call   10184f <video_init>
	kbd_init();
  1002cc:	e8 ff 19 00 00       	call   101cd0 <kbd_init>
	serial_init();
  1002d1:	e8 0d 1b 00 00       	call   101de3 <serial_init>

	if (!serial_exists)
  1002d6:	a1 00 70 10 00       	mov    0x107000,%eax
  1002db:	85 c0                	test   %eax,%eax
  1002dd:	75 1f                	jne    1002fe <cons_init+0x46>
		warn("Serial port does not exist!\n");
  1002df:	c7 44 24 08 44 2e 10 	movl   $0x102e44,0x8(%esp)
  1002e6:	00 
  1002e7:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  1002ee:	00 
  1002ef:	c7 04 24 61 2e 10 00 	movl   $0x102e61,(%esp)
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
  10036c:	c7 04 24 6d 2e 10 00 	movl   $0x102e6d,(%esp)
  100373:	e8 56 23 00 00       	call   1026ce <cprintf>
	vcprintf(fmt, ap);
  100378:	8b 45 10             	mov    0x10(%ebp),%eax
  10037b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10037e:	89 54 24 04          	mov    %edx,0x4(%esp)
  100382:	89 04 24             	mov    %eax,(%esp)
  100385:	e8 db 22 00 00       	call   102665 <vcprintf>
	cprintf("\n");
  10038a:	c7 04 24 85 2e 10 00 	movl   $0x102e85,(%esp)
  100391:	e8 38 23 00 00       	call   1026ce <cprintf>

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
  1003bf:	c7 04 24 87 2e 10 00 	movl   $0x102e87,(%esp)
  1003c6:	e8 03 23 00 00       	call   1026ce <cprintf>
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
  100405:	c7 04 24 94 2e 10 00 	movl   $0x102e94,(%esp)
  10040c:	e8 bd 22 00 00       	call   1026ce <cprintf>
	vcprintf(fmt, ap);
  100411:	8b 45 10             	mov    0x10(%ebp),%eax
  100414:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100417:	89 54 24 04          	mov    %edx,0x4(%esp)
  10041b:	89 04 24             	mov    %eax,(%esp)
  10041e:	e8 42 22 00 00       	call   102665 <vcprintf>
	cprintf("\n");
  100423:	c7 04 24 85 2e 10 00 	movl   $0x102e85,(%esp)
  10042a:	e8 9f 22 00 00       	call   1026ce <cprintf>
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
  100444:	c7 04 24 ae 2e 10 00 	movl   $0x102eae,(%esp)
  10044b:	e8 7e 22 00 00       	call   1026ce <cprintf>

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
  10047d:	c7 04 24 c0 2e 10 00 	movl   $0x102ec0,(%esp)
  100484:	e8 45 22 00 00       	call   1026ce <cprintf>

		int y = 0;
  100489:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

		cprintf(" args");
  100490:	c7 04 24 d6 2e 10 00 	movl   $0x102ed6,(%esp)
  100497:	e8 32 22 00 00       	call   1026ce <cprintf>

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
  1004b0:	c7 04 24 dc 2e 10 00 	movl   $0x102edc,(%esp)
  1004b7:	e8 12 22 00 00       	call   1026ce <cprintf>

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
  1004c6:	c7 04 24 85 2e 10 00 	movl   $0x102e85,(%esp)
  1004cd:	e8 fc 21 00 00       	call   1026ce <cprintf>

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
  100617:	c7 44 24 0c e2 2e 10 	movl   $0x102ee2,0xc(%esp)
  10061e:	00 
  10061f:	c7 44 24 08 ff 2e 10 	movl   $0x102eff,0x8(%esp)
  100626:	00 
  100627:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
  10062e:	00 
  10062f:	c7 04 24 14 2f 10 00 	movl   $0x102f14,(%esp)
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
  100667:	c7 44 24 0c 21 2f 10 	movl   $0x102f21,0xc(%esp)
  10066e:	00 
  10066f:	c7 44 24 08 ff 2e 10 	movl   $0x102eff,0x8(%esp)
  100676:	00 
  100677:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  10067e:	00 
  10067f:	c7 04 24 14 2f 10 00 	movl   $0x102f14,(%esp)
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
  1006b7:	c7 44 24 0c 3a 2f 10 	movl   $0x102f3a,0xc(%esp)
  1006be:	00 
  1006bf:	c7 44 24 08 ff 2e 10 	movl   $0x102eff,0x8(%esp)
  1006c6:	00 
  1006c7:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
  1006ce:	00 
  1006cf:	c7 04 24 14 2f 10 00 	movl   $0x102f14,(%esp)
  1006d6:	e8 4e fc ff ff       	call   100329 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1006db:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1006de:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1006e1:	39 c2                	cmp    %eax,%edx
  1006e3:	74 24                	je     100709 <debug_check+0x175>
  1006e5:	c7 44 24 0c 53 2f 10 	movl   $0x102f53,0xc(%esp)
  1006ec:	00 
  1006ed:	c7 44 24 08 ff 2e 10 	movl   $0x102eff,0x8(%esp)
  1006f4:	00 
  1006f5:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  1006fc:	00 
  1006fd:	c7 04 24 14 2f 10 00 	movl   $0x102f14,(%esp)
  100704:	e8 20 fc ff ff       	call   100329 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100709:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  10070f:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100712:	39 c2                	cmp    %eax,%edx
  100714:	75 24                	jne    10073a <debug_check+0x1a6>
  100716:	c7 44 24 0c 6c 2f 10 	movl   $0x102f6c,0xc(%esp)
  10071d:	00 
  10071e:	c7 44 24 08 ff 2e 10 	movl   $0x102eff,0x8(%esp)
  100725:	00 
  100726:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  10072d:	00 
  10072e:	c7 04 24 14 2f 10 00 	movl   $0x102f14,(%esp)
  100735:	e8 ef fb ff ff       	call   100329 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  10073a:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100740:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100743:	39 c2                	cmp    %eax,%edx
  100745:	74 24                	je     10076b <debug_check+0x1d7>
  100747:	c7 44 24 0c 85 2f 10 	movl   $0x102f85,0xc(%esp)
  10074e:	00 
  10074f:	c7 44 24 08 ff 2e 10 	movl   $0x102eff,0x8(%esp)
  100756:	00 
  100757:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  10075e:	00 
  10075f:	c7 04 24 14 2f 10 00 	movl   $0x102f14,(%esp)
  100766:	e8 be fb ff ff       	call   100329 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10076b:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100771:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100774:	39 c2                	cmp    %eax,%edx
  100776:	74 24                	je     10079c <debug_check+0x208>
  100778:	c7 44 24 0c 9e 2f 10 	movl   $0x102f9e,0xc(%esp)
  10077f:	00 
  100780:	c7 44 24 08 ff 2e 10 	movl   $0x102eff,0x8(%esp)
  100787:	00 
  100788:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  10078f:	00 
  100790:	c7 04 24 14 2f 10 00 	movl   $0x102f14,(%esp)
  100797:	e8 8d fb ff ff       	call   100329 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  10079c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1007a2:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1007a8:	39 c2                	cmp    %eax,%edx
  1007aa:	75 24                	jne    1007d0 <debug_check+0x23c>
  1007ac:	c7 44 24 0c b7 2f 10 	movl   $0x102fb7,0xc(%esp)
  1007b3:	00 
  1007b4:	c7 44 24 08 ff 2e 10 	movl   $0x102eff,0x8(%esp)
  1007bb:	00 
  1007bc:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  1007c3:	00 
  1007c4:	c7 04 24 14 2f 10 00 	movl   $0x102f14,(%esp)
  1007cb:	e8 59 fb ff ff       	call   100329 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1007d0:	c7 04 24 d0 2f 10 00 	movl   $0x102fd0,(%esp)
  1007d7:	e8 f2 1e 00 00       	call   1026ce <cprintf>
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
  100808:	c7 44 24 0c ec 2f 10 	movl   $0x102fec,0xc(%esp)
  10080f:	00 
  100810:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100817:	00 
  100818:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10081f:	00 
  100820:	c7 04 24 17 30 10 00 	movl   $0x103017,(%esp)
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
  100863:	e8 80 16 00 00       	call   101ee8 <nvram_read16>
  100868:	c1 e0 0a             	shl    $0xa,%eax
  10086b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10086e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100871:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100876:	89 45 e0             	mov    %eax,-0x20(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100879:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100880:	e8 63 16 00 00       	call   101ee8 <nvram_read16>
  100885:	c1 e0 0a             	shl    $0xa,%eax
  100888:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10088b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10088e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100893:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	warn("Assuming we have 1GB of memory!");
  100896:	c7 44 24 08 24 30 10 	movl   $0x103024,0x8(%esp)
  10089d:	00 
  10089e:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  1008a5:	00 
  1008a6:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  1008df:	c7 04 24 50 30 10 00 	movl   $0x103050,(%esp)
  1008e6:	e8 e3 1d 00 00       	call   1026ce <cprintf>
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
  100901:	c7 04 24 71 30 10 00 	movl   $0x103071,(%esp)
  100908:	e8 c1 1d 00 00       	call   1026ce <cprintf>
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
  10096d:	c7 44 24 08 8d 30 10 	movl   $0x10308d,0x8(%esp)
  100974:	00 
  100975:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  10097c:	00 
  10097d:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100991:	c7 44 24 08 a8 30 10 	movl   $0x1030a8,0x8(%esp)
  100998:	00 
  100999:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  1009a0:	00 
  1009a1:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  1009b3:	c7 44 24 08 c3 30 10 	movl   $0x1030c3,0x8(%esp)
  1009ba:	00 
  1009bb:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  1009c2:	00 
  1009c3:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100a0d:	e8 a1 1e 00 00       	call   1028b3 <memset>
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
  100a2b:	c7 04 24 dd 30 10 00 	movl   $0x1030dd,(%esp)
  100a32:	e8 97 1c 00 00       	call   1026ce <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100a37:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100a3a:	a1 f4 6f 10 00       	mov    0x106ff4,%eax
  100a3f:	39 c2                	cmp    %eax,%edx
  100a41:	72 24                	jb     100a67 <mem_check+0x98>
  100a43:	c7 44 24 0c f7 30 10 	movl   $0x1030f7,0xc(%esp)
  100a4a:	00 
  100a4b:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100a52:	00 
  100a53:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100a5a:	00 
  100a5b:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100a62:	e8 c2 f8 ff ff       	call   100329 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100a67:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100a6e:	7f 24                	jg     100a94 <mem_check+0xc5>
  100a70:	c7 44 24 0c 0d 31 10 	movl   $0x10310d,0xc(%esp)
  100a77:	00 
  100a78:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100a7f:	00 
  100a80:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
  100a87:	00 
  100a88:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100ab5:	c7 44 24 0c 1f 31 10 	movl   $0x10311f,0xc(%esp)
  100abc:	00 
  100abd:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100ac4:	00 
  100ac5:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  100acc:	00 
  100acd:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100ad4:	e8 50 f8 ff ff       	call   100329 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100ad9:	e8 ad fe ff ff       	call   10098b <mem_alloc>
  100ade:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100ae1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100ae5:	75 24                	jne    100b0b <mem_check+0x13c>
  100ae7:	c7 44 24 0c 28 31 10 	movl   $0x103128,0xc(%esp)
  100aee:	00 
  100aef:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100af6:	00 
  100af7:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100afe:	00 
  100aff:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100b06:	e8 1e f8 ff ff       	call   100329 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100b0b:	e8 7b fe ff ff       	call   10098b <mem_alloc>
  100b10:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100b13:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100b17:	75 24                	jne    100b3d <mem_check+0x16e>
  100b19:	c7 44 24 0c 31 31 10 	movl   $0x103131,0xc(%esp)
  100b20:	00 
  100b21:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100b28:	00 
  100b29:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  100b30:	00 
  100b31:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100b38:	e8 ec f7 ff ff       	call   100329 <debug_panic>

	assert(pp0);
  100b3d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100b41:	75 24                	jne    100b67 <mem_check+0x198>
  100b43:	c7 44 24 0c 3a 31 10 	movl   $0x10313a,0xc(%esp)
  100b4a:	00 
  100b4b:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100b52:	00 
  100b53:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  100b5a:	00 
  100b5b:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100b62:	e8 c2 f7 ff ff       	call   100329 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100b67:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100b6b:	74 08                	je     100b75 <mem_check+0x1a6>
  100b6d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100b70:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100b73:	75 24                	jne    100b99 <mem_check+0x1ca>
  100b75:	c7 44 24 0c 3e 31 10 	movl   $0x10313e,0xc(%esp)
  100b7c:	00 
  100b7d:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100b84:	00 
  100b85:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100b8c:	00 
  100b8d:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100baf:	c7 44 24 0c 50 31 10 	movl   $0x103150,0xc(%esp)
  100bb6:	00 
  100bb7:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100bbe:	00 
  100bbf:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  100bc6:	00 
  100bc7:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100bf4:	c7 44 24 0c 70 31 10 	movl   $0x103170,0xc(%esp)
  100bfb:	00 
  100bfc:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100c03:	00 
  100c04:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100c0b:	00 
  100c0c:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100c39:	c7 44 24 0c 98 31 10 	movl   $0x103198,0xc(%esp)
  100c40:	00 
  100c41:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100c48:	00 
  100c49:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100c50:	00 
  100c51:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100c7e:	c7 44 24 0c c0 31 10 	movl   $0x1031c0,0xc(%esp)
  100c85:	00 
  100c86:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100c8d:	00 
  100c8e:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100c95:	00 
  100c96:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100cbd:	c7 44 24 0c e6 31 10 	movl   $0x1031e6,0xc(%esp)
  100cc4:	00 
  100cc5:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100ccc:	00 
  100ccd:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  100cd4:	00 
  100cd5:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100d23:	c7 44 24 0c 1f 31 10 	movl   $0x10311f,0xc(%esp)
  100d2a:	00 
  100d2b:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100d32:	00 
  100d33:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  100d3a:	00 
  100d3b:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100d42:	e8 e2 f5 ff ff       	call   100329 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100d47:	e8 3f fc ff ff       	call   10098b <mem_alloc>
  100d4c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d4f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100d53:	75 24                	jne    100d79 <mem_check+0x3aa>
  100d55:	c7 44 24 0c 28 31 10 	movl   $0x103128,0xc(%esp)
  100d5c:	00 
  100d5d:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100d64:	00 
  100d65:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  100d6c:	00 
  100d6d:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100d74:	e8 b0 f5 ff ff       	call   100329 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100d79:	e8 0d fc ff ff       	call   10098b <mem_alloc>
  100d7e:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100d81:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100d85:	75 24                	jne    100dab <mem_check+0x3dc>
  100d87:	c7 44 24 0c 31 31 10 	movl   $0x103131,0xc(%esp)
  100d8e:	00 
  100d8f:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100d96:	00 
  100d97:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  100d9e:	00 
  100d9f:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100da6:	e8 7e f5 ff ff       	call   100329 <debug_panic>
	assert(pp0);
  100dab:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100daf:	75 24                	jne    100dd5 <mem_check+0x406>
  100db1:	c7 44 24 0c 3a 31 10 	movl   $0x10313a,0xc(%esp)
  100db8:	00 
  100db9:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100dc0:	00 
  100dc1:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
  100dc8:	00 
  100dc9:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100dd0:	e8 54 f5 ff ff       	call   100329 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100dd5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100dd9:	74 08                	je     100de3 <mem_check+0x414>
  100ddb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100dde:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100de1:	75 24                	jne    100e07 <mem_check+0x438>
  100de3:	c7 44 24 0c 3e 31 10 	movl   $0x10313e,0xc(%esp)
  100dea:	00 
  100deb:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100df2:	00 
  100df3:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  100dfa:	00 
  100dfb:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100e1d:	c7 44 24 0c 50 31 10 	movl   $0x103150,0xc(%esp)
  100e24:	00 
  100e25:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100e2c:	00 
  100e2d:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  100e34:	00 
  100e35:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
  100e3c:	e8 e8 f4 ff ff       	call   100329 <debug_panic>
	assert(mem_alloc() == 0);
  100e41:	e8 45 fb ff ff       	call   10098b <mem_alloc>
  100e46:	85 c0                	test   %eax,%eax
  100e48:	74 24                	je     100e6e <mem_check+0x49f>
  100e4a:	c7 44 24 0c e6 31 10 	movl   $0x1031e6,0xc(%esp)
  100e51:	00 
  100e52:	c7 44 24 08 02 30 10 	movl   $0x103002,0x8(%esp)
  100e59:	00 
  100e5a:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  100e61:	00 
  100e62:	c7 04 24 44 30 10 00 	movl   $0x103044,(%esp)
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
  100e97:	c7 04 24 f7 31 10 00 	movl   $0x1031f7,(%esp)
  100e9e:	e8 2b 18 00 00       	call   1026ce <cprintf>
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
  100ecf:	c7 44 24 0c 0f 32 10 	movl   $0x10320f,0xc(%esp)
  100ed6:	00 
  100ed7:	c7 44 24 08 25 32 10 	movl   $0x103225,0x8(%esp)
  100ede:	00 
  100edf:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100ee6:	00 
  100ee7:	c7 04 24 3a 32 10 00 	movl   $0x10323a,(%esp)
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
  100efb:	53                   	push   %ebx
  100efc:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  100eff:	e8 a1 ff ff ff       	call   100ea5 <cpu_cur>
  100f04:	89 45 f0             	mov    %eax,-0x10(%ebp)

	c->tss.ts_ss0 = CPU_GDT_KDATA;
  100f07:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f0a:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)
	c->tss.ts_esp0 = (uintptr_t)c->kstackhi; 
  100f10:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f13:	05 00 10 00 00       	add    $0x1000,%eax
  100f18:	89 c2                	mov    %eax,%edx
  100f1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f1d:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->gdt[CPU_GDT_TSS>>3] = SEGDESC16(0, STS_T16A, (uintptr_t)(&c->tss), sizeof(c->tss) - 1, 0);
  100f20:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f23:	83 c0 38             	add    $0x38,%eax
  100f26:	89 c3                	mov    %eax,%ebx
  100f28:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f2b:	83 c0 38             	add    $0x38,%eax
  100f2e:	c1 e8 10             	shr    $0x10,%eax
  100f31:	89 c1                	mov    %eax,%ecx
  100f33:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f36:	83 c0 38             	add    $0x38,%eax
  100f39:	c1 e8 18             	shr    $0x18,%eax
  100f3c:	89 c2                	mov    %eax,%edx
  100f3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f41:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  100f47:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f4a:	66 89 58 32          	mov    %bx,0x32(%eax)
  100f4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f51:	88 48 34             	mov    %cl,0x34(%eax)
  100f54:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f57:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100f5b:	83 e1 f0             	and    $0xfffffff0,%ecx
  100f5e:	83 c9 01             	or     $0x1,%ecx
  100f61:	88 48 35             	mov    %cl,0x35(%eax)
  100f64:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f67:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100f6b:	83 e1 ef             	and    $0xffffffef,%ecx
  100f6e:	88 48 35             	mov    %cl,0x35(%eax)
  100f71:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f74:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100f78:	83 e1 9f             	and    $0xffffff9f,%ecx
  100f7b:	88 48 35             	mov    %cl,0x35(%eax)
  100f7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f81:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100f85:	83 c9 80             	or     $0xffffff80,%ecx
  100f88:	88 48 35             	mov    %cl,0x35(%eax)
  100f8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f8e:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100f92:	83 e1 f0             	and    $0xfffffff0,%ecx
  100f95:	88 48 36             	mov    %cl,0x36(%eax)
  100f98:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f9b:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100f9f:	83 e1 ef             	and    $0xffffffef,%ecx
  100fa2:	88 48 36             	mov    %cl,0x36(%eax)
  100fa5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fa8:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100fac:	83 e1 df             	and    $0xffffffdf,%ecx
  100faf:	88 48 36             	mov    %cl,0x36(%eax)
  100fb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fb5:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100fb9:	83 c9 40             	or     $0x40,%ecx
  100fbc:	88 48 36             	mov    %cl,0x36(%eax)
  100fbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fc2:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100fc6:	83 e1 7f             	and    $0x7f,%ecx
  100fc9:	88 48 36             	mov    %cl,0x36(%eax)
  100fcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fcf:	88 50 37             	mov    %dl,0x37(%eax)


	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  100fd2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fd5:	66 c7 45 ea 37 00    	movw   $0x37,-0x16(%ebp)
  100fdb:	89 45 ec             	mov    %eax,-0x14(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  100fde:	0f 01 55 ea          	lgdtl  -0x16(%ebp)
  100fe2:	66 c7 45 f6 30 00    	movw   $0x30,-0xa(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  100fe8:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  100fec:	0f 00 d8             	ltr    %ax
	ltr(CPU_GDT_TSS);

	// Reload all segment registers.
	//asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
	//asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  100fef:	b8 10 00 00 00       	mov    $0x10,%eax
  100ff4:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  100ff6:	b8 10 00 00 00       	mov    $0x10,%eax
  100ffb:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  100ffd:	b8 10 00 00 00       	mov    $0x10,%eax
  101002:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  101004:	ea 0b 10 10 00 08 00 	ljmp   $0x8,$0x10100b

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  10100b:	b8 00 00 00 00       	mov    $0x0,%eax
  101010:	0f 00 d0             	lldt   %ax
}
  101013:	83 c4 14             	add    $0x14,%esp
  101016:	5b                   	pop    %ebx
  101017:	5d                   	pop    %ebp
  101018:	c3                   	ret    

00101019 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101019:	55                   	push   %ebp
  10101a:	89 e5                	mov    %esp,%ebp
  10101c:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10101f:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101022:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101025:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101028:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10102b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101030:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101033:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101036:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  10103c:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101041:	74 24                	je     101067 <cpu_cur+0x4e>
  101043:	c7 44 24 0c 60 32 10 	movl   $0x103260,0xc(%esp)
  10104a:	00 
  10104b:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  101052:	00 
  101053:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10105a:	00 
  10105b:	c7 04 24 8b 32 10 00 	movl   $0x10328b,(%esp)
  101062:	e8 c2 f2 ff ff       	call   100329 <debug_panic>
	return c;
  101067:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10106a:	c9                   	leave  
  10106b:	c3                   	ret    

0010106c <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10106c:	55                   	push   %ebp
  10106d:	89 e5                	mov    %esp,%ebp
  10106f:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101072:	e8 a2 ff ff ff       	call   101019 <cpu_cur>
  101077:	3d 00 40 10 00       	cmp    $0x104000,%eax
  10107c:	0f 94 c0             	sete   %al
  10107f:	0f b6 c0             	movzbl %al,%eax
}
  101082:	c9                   	leave  
  101083:	c3                   	ret    

00101084 <trap_init_idt>:

extern uint32_t vectors[];

static void
trap_init_idt(void)
{
  101084:	55                   	push   %ebp
  101085:	89 e5                	mov    %esp,%ebp
  101087:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  10108a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  101091:	e9 bc 00 00 00       	jmp    101152 <trap_init_idt+0xce>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 0);
  101096:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101099:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10109c:	8b 14 95 10 50 10 00 	mov    0x105010(,%edx,4),%edx
  1010a3:	66 89 14 c5 e0 67 10 	mov    %dx,0x1067e0(,%eax,8)
  1010aa:	00 
  1010ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1010ae:	66 c7 04 c5 e2 67 10 	movw   $0x8,0x1067e2(,%eax,8)
  1010b5:	00 08 00 
  1010b8:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1010bb:	0f b6 14 c5 e4 67 10 	movzbl 0x1067e4(,%eax,8),%edx
  1010c2:	00 
  1010c3:	83 e2 e0             	and    $0xffffffe0,%edx
  1010c6:	88 14 c5 e4 67 10 00 	mov    %dl,0x1067e4(,%eax,8)
  1010cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1010d0:	0f b6 14 c5 e4 67 10 	movzbl 0x1067e4(,%eax,8),%edx
  1010d7:	00 
  1010d8:	83 e2 1f             	and    $0x1f,%edx
  1010db:	88 14 c5 e4 67 10 00 	mov    %dl,0x1067e4(,%eax,8)
  1010e2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1010e5:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  1010ec:	00 
  1010ed:	83 ca 0f             	or     $0xf,%edx
  1010f0:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  1010f7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1010fa:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  101101:	00 
  101102:	83 e2 ef             	and    $0xffffffef,%edx
  101105:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  10110c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10110f:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  101116:	00 
  101117:	83 e2 9f             	and    $0xffffff9f,%edx
  10111a:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  101121:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101124:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  10112b:	00 
  10112c:	83 ca 80             	or     $0xffffff80,%edx
  10112f:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  101136:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101139:	8b 55 fc             	mov    -0x4(%ebp),%edx
  10113c:	8b 14 95 10 50 10 00 	mov    0x105010(,%edx,4),%edx
  101143:	c1 ea 10             	shr    $0x10,%edx
  101146:	66 89 14 c5 e6 67 10 	mov    %dx,0x1067e6(,%eax,8)
  10114d:	00 
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  10114e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  101152:	83 7d fc 13          	cmpl   $0x13,-0x4(%ebp)
  101156:	0f 8e 3a ff ff ff    	jle    101096 <trap_init_idt+0x12>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 0);
	}
	SETGATE(idt[30], 1, CPU_GDT_KCODE, vectors[30], 0);
  10115c:	a1 88 50 10 00       	mov    0x105088,%eax
  101161:	66 a3 d0 68 10 00    	mov    %ax,0x1068d0
  101167:	66 c7 05 d2 68 10 00 	movw   $0x8,0x1068d2
  10116e:	08 00 
  101170:	0f b6 05 d4 68 10 00 	movzbl 0x1068d4,%eax
  101177:	83 e0 e0             	and    $0xffffffe0,%eax
  10117a:	a2 d4 68 10 00       	mov    %al,0x1068d4
  10117f:	0f b6 05 d4 68 10 00 	movzbl 0x1068d4,%eax
  101186:	83 e0 1f             	and    $0x1f,%eax
  101189:	a2 d4 68 10 00       	mov    %al,0x1068d4
  10118e:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  101195:	83 c8 0f             	or     $0xf,%eax
  101198:	a2 d5 68 10 00       	mov    %al,0x1068d5
  10119d:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1011a4:	83 e0 ef             	and    $0xffffffef,%eax
  1011a7:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1011ac:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1011b3:	83 e0 9f             	and    $0xffffff9f,%eax
  1011b6:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1011bb:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1011c2:	83 c8 80             	or     $0xffffff80,%eax
  1011c5:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1011ca:	a1 88 50 10 00       	mov    0x105088,%eax
  1011cf:	c1 e8 10             	shr    $0x10,%eax
  1011d2:	66 a3 d6 68 10 00    	mov    %ax,0x1068d6
}
  1011d8:	c9                   	leave  
  1011d9:	c3                   	ret    

001011da <trap_init>:

void
trap_init(void)
{
  1011da:	55                   	push   %ebp
  1011db:	89 e5                	mov    %esp,%ebp
  1011dd:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  1011e0:	e8 87 fe ff ff       	call   10106c <cpu_onboot>
  1011e5:	85 c0                	test   %eax,%eax
  1011e7:	74 05                	je     1011ee <trap_init+0x14>
		trap_init_idt();
  1011e9:	e8 96 fe ff ff       	call   101084 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  1011ee:	0f 01 1d 00 50 10 00 	lidtl  0x105000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  1011f5:	e8 72 fe ff ff       	call   10106c <cpu_onboot>
  1011fa:	85 c0                	test   %eax,%eax
  1011fc:	74 05                	je     101203 <trap_init+0x29>
		trap_check_kernel();
  1011fe:	e8 62 02 00 00       	call   101465 <trap_check_kernel>
}
  101203:	c9                   	leave  
  101204:	c3                   	ret    

00101205 <trap_name>:

const char *trap_name(int trapno)
{
  101205:	55                   	push   %ebp
  101206:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101208:	8b 45 08             	mov    0x8(%ebp),%eax
  10120b:	83 f8 13             	cmp    $0x13,%eax
  10120e:	77 0c                	ja     10121c <trap_name+0x17>
		return excnames[trapno];
  101210:	8b 45 08             	mov    0x8(%ebp),%eax
  101213:	8b 04 85 40 36 10 00 	mov    0x103640(,%eax,4),%eax
  10121a:	eb 05                	jmp    101221 <trap_name+0x1c>
	return "(unknown trap)";
  10121c:	b8 98 32 10 00       	mov    $0x103298,%eax
}
  101221:	5d                   	pop    %ebp
  101222:	c3                   	ret    

00101223 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101223:	55                   	push   %ebp
  101224:	89 e5                	mov    %esp,%ebp
  101226:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  101229:	8b 45 08             	mov    0x8(%ebp),%eax
  10122c:	8b 00                	mov    (%eax),%eax
  10122e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101232:	c7 04 24 a7 32 10 00 	movl   $0x1032a7,(%esp)
  101239:	e8 90 14 00 00       	call   1026ce <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  10123e:	8b 45 08             	mov    0x8(%ebp),%eax
  101241:	8b 40 04             	mov    0x4(%eax),%eax
  101244:	89 44 24 04          	mov    %eax,0x4(%esp)
  101248:	c7 04 24 b6 32 10 00 	movl   $0x1032b6,(%esp)
  10124f:	e8 7a 14 00 00       	call   1026ce <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101254:	8b 45 08             	mov    0x8(%ebp),%eax
  101257:	8b 40 08             	mov    0x8(%eax),%eax
  10125a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10125e:	c7 04 24 c5 32 10 00 	movl   $0x1032c5,(%esp)
  101265:	e8 64 14 00 00       	call   1026ce <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  10126a:	8b 45 08             	mov    0x8(%ebp),%eax
  10126d:	8b 40 10             	mov    0x10(%eax),%eax
  101270:	89 44 24 04          	mov    %eax,0x4(%esp)
  101274:	c7 04 24 d4 32 10 00 	movl   $0x1032d4,(%esp)
  10127b:	e8 4e 14 00 00       	call   1026ce <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101280:	8b 45 08             	mov    0x8(%ebp),%eax
  101283:	8b 40 14             	mov    0x14(%eax),%eax
  101286:	89 44 24 04          	mov    %eax,0x4(%esp)
  10128a:	c7 04 24 e3 32 10 00 	movl   $0x1032e3,(%esp)
  101291:	e8 38 14 00 00       	call   1026ce <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101296:	8b 45 08             	mov    0x8(%ebp),%eax
  101299:	8b 40 18             	mov    0x18(%eax),%eax
  10129c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012a0:	c7 04 24 f2 32 10 00 	movl   $0x1032f2,(%esp)
  1012a7:	e8 22 14 00 00       	call   1026ce <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1012ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1012af:	8b 40 1c             	mov    0x1c(%eax),%eax
  1012b2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012b6:	c7 04 24 01 33 10 00 	movl   $0x103301,(%esp)
  1012bd:	e8 0c 14 00 00       	call   1026ce <cprintf>
}
  1012c2:	c9                   	leave  
  1012c3:	c3                   	ret    

001012c4 <trap_print>:

void
trap_print(trapframe *tf)
{
  1012c4:	55                   	push   %ebp
  1012c5:	89 e5                	mov    %esp,%ebp
  1012c7:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  1012ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1012cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012d1:	c7 04 24 10 33 10 00 	movl   $0x103310,(%esp)
  1012d8:	e8 f1 13 00 00       	call   1026ce <cprintf>
	trap_print_regs(&tf->regs);
  1012dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1012e0:	89 04 24             	mov    %eax,(%esp)
  1012e3:	e8 3b ff ff ff       	call   101223 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  1012e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1012eb:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  1012ef:	0f b7 c0             	movzwl %ax,%eax
  1012f2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012f6:	c7 04 24 22 33 10 00 	movl   $0x103322,(%esp)
  1012fd:	e8 cc 13 00 00       	call   1026ce <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101302:	8b 45 08             	mov    0x8(%ebp),%eax
  101305:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101309:	0f b7 c0             	movzwl %ax,%eax
  10130c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101310:	c7 04 24 35 33 10 00 	movl   $0x103335,(%esp)
  101317:	e8 b2 13 00 00       	call   1026ce <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  10131c:	8b 45 08             	mov    0x8(%ebp),%eax
  10131f:	8b 40 30             	mov    0x30(%eax),%eax
  101322:	89 04 24             	mov    %eax,(%esp)
  101325:	e8 db fe ff ff       	call   101205 <trap_name>
  10132a:	8b 55 08             	mov    0x8(%ebp),%edx
  10132d:	8b 52 30             	mov    0x30(%edx),%edx
  101330:	89 44 24 08          	mov    %eax,0x8(%esp)
  101334:	89 54 24 04          	mov    %edx,0x4(%esp)
  101338:	c7 04 24 48 33 10 00 	movl   $0x103348,(%esp)
  10133f:	e8 8a 13 00 00       	call   1026ce <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101344:	8b 45 08             	mov    0x8(%ebp),%eax
  101347:	8b 40 34             	mov    0x34(%eax),%eax
  10134a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10134e:	c7 04 24 5a 33 10 00 	movl   $0x10335a,(%esp)
  101355:	e8 74 13 00 00       	call   1026ce <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  10135a:	8b 45 08             	mov    0x8(%ebp),%eax
  10135d:	8b 40 38             	mov    0x38(%eax),%eax
  101360:	89 44 24 04          	mov    %eax,0x4(%esp)
  101364:	c7 04 24 69 33 10 00 	movl   $0x103369,(%esp)
  10136b:	e8 5e 13 00 00       	call   1026ce <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101370:	8b 45 08             	mov    0x8(%ebp),%eax
  101373:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101377:	0f b7 c0             	movzwl %ax,%eax
  10137a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10137e:	c7 04 24 78 33 10 00 	movl   $0x103378,(%esp)
  101385:	e8 44 13 00 00       	call   1026ce <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  10138a:	8b 45 08             	mov    0x8(%ebp),%eax
  10138d:	8b 40 40             	mov    0x40(%eax),%eax
  101390:	89 44 24 04          	mov    %eax,0x4(%esp)
  101394:	c7 04 24 8b 33 10 00 	movl   $0x10338b,(%esp)
  10139b:	e8 2e 13 00 00       	call   1026ce <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1013a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1013a3:	8b 40 44             	mov    0x44(%eax),%eax
  1013a6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013aa:	c7 04 24 9a 33 10 00 	movl   $0x10339a,(%esp)
  1013b1:	e8 18 13 00 00       	call   1026ce <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1013b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1013b9:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1013bd:	0f b7 c0             	movzwl %ax,%eax
  1013c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013c4:	c7 04 24 a9 33 10 00 	movl   $0x1033a9,(%esp)
  1013cb:	e8 fe 12 00 00       	call   1026ce <cprintf>
}
  1013d0:	c9                   	leave  
  1013d1:	c3                   	ret    

001013d2 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  1013d2:	55                   	push   %ebp
  1013d3:	89 e5                	mov    %esp,%ebp
  1013d5:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  1013d8:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  1013d9:	e8 3b fc ff ff       	call   101019 <cpu_cur>
  1013de:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  1013e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1013e4:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1013ea:	85 c0                	test   %eax,%eax
  1013ec:	74 1e                	je     10140c <trap+0x3a>
		c->recover(tf, c->recoverdata);
  1013ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1013f1:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  1013f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1013fa:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  101400:	89 44 24 04          	mov    %eax,0x4(%esp)
  101404:	8b 45 08             	mov    0x8(%ebp),%eax
  101407:	89 04 24             	mov    %eax,(%esp)
  10140a:	ff d2                	call   *%edx

	trap_print(tf);
  10140c:	8b 45 08             	mov    0x8(%ebp),%eax
  10140f:	89 04 24             	mov    %eax,(%esp)
  101412:	e8 ad fe ff ff       	call   1012c4 <trap_print>
	panic("unhandled trap");
  101417:	c7 44 24 08 bc 33 10 	movl   $0x1033bc,0x8(%esp)
  10141e:	00 
  10141f:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  101426:	00 
  101427:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  10142e:	e8 f6 ee ff ff       	call   100329 <debug_panic>

00101433 <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101433:	55                   	push   %ebp
  101434:	89 e5                	mov    %esp,%ebp
  101436:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101439:	8b 45 0c             	mov    0xc(%ebp),%eax
  10143c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  10143f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101442:	8b 00                	mov    (%eax),%eax
  101444:	89 c2                	mov    %eax,%edx
  101446:	8b 45 08             	mov    0x8(%ebp),%eax
  101449:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  10144c:	8b 45 08             	mov    0x8(%ebp),%eax
  10144f:	8b 40 30             	mov    0x30(%eax),%eax
  101452:	89 c2                	mov    %eax,%edx
  101454:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101457:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  10145a:	8b 45 08             	mov    0x8(%ebp),%eax
  10145d:	89 04 24             	mov    %eax,(%esp)
  101460:	e8 1b 3c 00 00       	call   105080 <trap_return>

00101465 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101465:	55                   	push   %ebp
  101466:	89 e5                	mov    %esp,%ebp
  101468:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10146b:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  10146e:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  101472:	0f b7 c0             	movzwl %ax,%eax
  101475:	83 e0 03             	and    $0x3,%eax
  101478:	85 c0                	test   %eax,%eax
  10147a:	74 24                	je     1014a0 <trap_check_kernel+0x3b>
  10147c:	c7 44 24 0c d7 33 10 	movl   $0x1033d7,0xc(%esp)
  101483:	00 
  101484:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  10148b:	00 
  10148c:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  101493:	00 
  101494:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  10149b:	e8 89 ee ff ff       	call   100329 <debug_panic>

	cpu *c = cpu_cur();
  1014a0:	e8 74 fb ff ff       	call   101019 <cpu_cur>
  1014a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  1014a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014ab:	c7 80 a0 00 00 00 33 	movl   $0x101433,0xa0(%eax)
  1014b2:	14 10 00 
	trap_check(&c->recoverdata);
  1014b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014b8:	05 a4 00 00 00       	add    $0xa4,%eax
  1014bd:	89 04 24             	mov    %eax,(%esp)
  1014c0:	e8 96 00 00 00       	call   10155b <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1014c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014c8:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1014cf:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  1014d2:	c7 04 24 ec 33 10 00 	movl   $0x1033ec,(%esp)
  1014d9:	e8 f0 11 00 00       	call   1026ce <cprintf>
}
  1014de:	c9                   	leave  
  1014df:	c3                   	ret    

001014e0 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  1014e0:	55                   	push   %ebp
  1014e1:	89 e5                	mov    %esp,%ebp
  1014e3:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1014e6:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  1014e9:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  1014ed:	0f b7 c0             	movzwl %ax,%eax
  1014f0:	83 e0 03             	and    $0x3,%eax
  1014f3:	83 f8 03             	cmp    $0x3,%eax
  1014f6:	74 24                	je     10151c <trap_check_user+0x3c>
  1014f8:	c7 44 24 0c 0c 34 10 	movl   $0x10340c,0xc(%esp)
  1014ff:	00 
  101500:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  101507:	00 
  101508:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
  10150f:	00 
  101510:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  101517:	e8 0d ee ff ff       	call   100329 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  10151c:	c7 45 f0 00 40 10 00 	movl   $0x104000,-0x10(%ebp)
	c->recover = trap_check_recover;
  101523:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101526:	c7 80 a0 00 00 00 33 	movl   $0x101433,0xa0(%eax)
  10152d:	14 10 00 
	trap_check(&c->recoverdata);
  101530:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101533:	05 a4 00 00 00       	add    $0xa4,%eax
  101538:	89 04 24             	mov    %eax,(%esp)
  10153b:	e8 1b 00 00 00       	call   10155b <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101540:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101543:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  10154a:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  10154d:	c7 04 24 21 34 10 00 	movl   $0x103421,(%esp)
  101554:	e8 75 11 00 00       	call   1026ce <cprintf>
}
  101559:	c9                   	leave  
  10155a:	c3                   	ret    

0010155b <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  10155b:	55                   	push   %ebp
  10155c:	89 e5                	mov    %esp,%ebp
  10155e:	57                   	push   %edi
  10155f:	56                   	push   %esi
  101560:	53                   	push   %ebx
  101561:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101564:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  10156b:	8b 45 08             	mov    0x8(%ebp),%eax
  10156e:	8d 55 d8             	lea    -0x28(%ebp),%edx
  101571:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  101573:	c7 45 d8 81 15 10 00 	movl   $0x101581,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  10157a:	b8 00 00 00 00       	mov    $0x0,%eax
  10157f:	f7 f0                	div    %eax

00101581 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  101581:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101584:	85 c0                	test   %eax,%eax
  101586:	74 24                	je     1015ac <after_div0+0x2b>
  101588:	c7 44 24 0c 3f 34 10 	movl   $0x10343f,0xc(%esp)
  10158f:	00 
  101590:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  101597:	00 
  101598:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  10159f:	00 
  1015a0:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  1015a7:	e8 7d ed ff ff       	call   100329 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1015ac:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1015af:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1015b4:	74 24                	je     1015da <after_div0+0x59>
  1015b6:	c7 44 24 0c 57 34 10 	movl   $0x103457,0xc(%esp)
  1015bd:	00 
  1015be:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  1015c5:	00 
  1015c6:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  1015cd:	00 
  1015ce:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  1015d5:	e8 4f ed ff ff       	call   100329 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  1015da:	c7 45 d8 e2 15 10 00 	movl   $0x1015e2,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  1015e1:	cc                   	int3   

001015e2 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  1015e2:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1015e5:	83 f8 03             	cmp    $0x3,%eax
  1015e8:	74 24                	je     10160e <after_breakpoint+0x2c>
  1015ea:	c7 44 24 0c 6c 34 10 	movl   $0x10346c,0xc(%esp)
  1015f1:	00 
  1015f2:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  1015f9:	00 
  1015fa:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  101601:	00 
  101602:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  101609:	e8 1b ed ff ff       	call   100329 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  10160e:	c7 45 d8 1d 16 10 00 	movl   $0x10161d,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101615:	b8 00 00 00 70       	mov    $0x70000000,%eax
  10161a:	01 c0                	add    %eax,%eax
  10161c:	ce                   	into   

0010161d <after_overflow>:
	assert(args.trapno == T_OFLOW);
  10161d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101620:	83 f8 04             	cmp    $0x4,%eax
  101623:	74 24                	je     101649 <after_overflow+0x2c>
  101625:	c7 44 24 0c 83 34 10 	movl   $0x103483,0xc(%esp)
  10162c:	00 
  10162d:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  101634:	00 
  101635:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  10163c:	00 
  10163d:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  101644:	e8 e0 ec ff ff       	call   100329 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101649:	c7 45 d8 66 16 10 00 	movl   $0x101666,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  101650:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  101657:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  10165e:	b8 00 00 00 00       	mov    $0x0,%eax
  101663:	62 45 d0             	bound  %eax,-0x30(%ebp)

00101666 <after_bound>:
	assert(args.trapno == T_BOUND);
  101666:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101669:	83 f8 05             	cmp    $0x5,%eax
  10166c:	74 24                	je     101692 <after_bound+0x2c>
  10166e:	c7 44 24 0c 9a 34 10 	movl   $0x10349a,0xc(%esp)
  101675:	00 
  101676:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  10167d:	00 
  10167e:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  101685:	00 
  101686:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  10168d:	e8 97 ec ff ff       	call   100329 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  101692:	c7 45 d8 9b 16 10 00 	movl   $0x10169b,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101699:	0f 0b                	ud2    

0010169b <after_illegal>:
	assert(args.trapno == T_ILLOP);
  10169b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10169e:	83 f8 06             	cmp    $0x6,%eax
  1016a1:	74 24                	je     1016c7 <after_illegal+0x2c>
  1016a3:	c7 44 24 0c b1 34 10 	movl   $0x1034b1,0xc(%esp)
  1016aa:	00 
  1016ab:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  1016b2:	00 
  1016b3:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  1016ba:	00 
  1016bb:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  1016c2:	e8 62 ec ff ff       	call   100329 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  1016c7:	c7 45 d8 d5 16 10 00 	movl   $0x1016d5,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  1016ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1016d3:	8e e0                	mov    %eax,%fs

001016d5 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  1016d5:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1016d8:	83 f8 0d             	cmp    $0xd,%eax
  1016db:	74 24                	je     101701 <after_gpfault+0x2c>
  1016dd:	c7 44 24 0c c8 34 10 	movl   $0x1034c8,0xc(%esp)
  1016e4:	00 
  1016e5:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  1016ec:	00 
  1016ed:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
  1016f4:	00 
  1016f5:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  1016fc:	e8 28 ec ff ff       	call   100329 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101701:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  101704:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101708:	0f b7 c0             	movzwl %ax,%eax
  10170b:	83 e0 03             	and    $0x3,%eax
  10170e:	85 c0                	test   %eax,%eax
  101710:	74 3a                	je     10174c <after_priv+0x2c>
		args.reip = after_priv;
  101712:	c7 45 d8 20 17 10 00 	movl   $0x101720,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101719:	0f 01 1d 00 50 10 00 	lidtl  0x105000

00101720 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101720:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101723:	83 f8 0d             	cmp    $0xd,%eax
  101726:	74 24                	je     10174c <after_priv+0x2c>
  101728:	c7 44 24 0c c8 34 10 	movl   $0x1034c8,0xc(%esp)
  10172f:	00 
  101730:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  101737:	00 
  101738:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
  10173f:	00 
  101740:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  101747:	e8 dd eb ff ff       	call   100329 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  10174c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10174f:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101754:	74 24                	je     10177a <after_priv+0x5a>
  101756:	c7 44 24 0c 57 34 10 	movl   $0x103457,0xc(%esp)
  10175d:	00 
  10175e:	c7 44 24 08 76 32 10 	movl   $0x103276,0x8(%esp)
  101765:	00 
  101766:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
  10176d:	00 
  10176e:	c7 04 24 cb 33 10 00 	movl   $0x1033cb,(%esp)
  101775:	e8 af eb ff ff       	call   100329 <debug_panic>
	//cprintf("sfsfsfsfsfsfsfsfsf\n");
	*argsp = NULL;	// recovery mechanism not needed anymore
  10177a:	8b 45 08             	mov    0x8(%ebp),%eax
  10177d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  101783:	83 c4 3c             	add    $0x3c,%esp
  101786:	5b                   	pop    %ebx
  101787:	5e                   	pop    %esi
  101788:	5f                   	pop    %edi
  101789:	5d                   	pop    %ebp
  10178a:	c3                   	ret    
  10178b:	90                   	nop

0010178c <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  10178c:	6a 00                	push   $0x0
  10178e:	6a 00                	push   $0x0
  101790:	e9 cf 38 00 00       	jmp    105064 <_alltraps>
  101795:	90                   	nop

00101796 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  101796:	6a 00                	push   $0x0
  101798:	6a 01                	push   $0x1
  10179a:	e9 c5 38 00 00       	jmp    105064 <_alltraps>
  10179f:	90                   	nop

001017a0 <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  1017a0:	6a 00                	push   $0x0
  1017a2:	6a 02                	push   $0x2
  1017a4:	e9 bb 38 00 00       	jmp    105064 <_alltraps>
  1017a9:	90                   	nop

001017aa <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  1017aa:	6a 00                	push   $0x0
  1017ac:	6a 03                	push   $0x3
  1017ae:	e9 b1 38 00 00       	jmp    105064 <_alltraps>
  1017b3:	90                   	nop

001017b4 <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  1017b4:	6a 00                	push   $0x0
  1017b6:	6a 04                	push   $0x4
  1017b8:	e9 a7 38 00 00       	jmp    105064 <_alltraps>
  1017bd:	90                   	nop

001017be <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  1017be:	6a 00                	push   $0x0
  1017c0:	6a 05                	push   $0x5
  1017c2:	e9 9d 38 00 00       	jmp    105064 <_alltraps>
  1017c7:	90                   	nop

001017c8 <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  1017c8:	6a 00                	push   $0x0
  1017ca:	6a 06                	push   $0x6
  1017cc:	e9 93 38 00 00       	jmp    105064 <_alltraps>
  1017d1:	90                   	nop

001017d2 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  1017d2:	6a 00                	push   $0x0
  1017d4:	6a 07                	push   $0x7
  1017d6:	e9 89 38 00 00       	jmp    105064 <_alltraps>
  1017db:	90                   	nop

001017dc <vector8>:
TRAPHANDLER(vector8, 8)
  1017dc:	6a 08                	push   $0x8
  1017de:	e9 81 38 00 00       	jmp    105064 <_alltraps>
  1017e3:	90                   	nop

001017e4 <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  1017e4:	6a 00                	push   $0x0
  1017e6:	6a 09                	push   $0x9
  1017e8:	e9 77 38 00 00       	jmp    105064 <_alltraps>
  1017ed:	90                   	nop

001017ee <vector10>:
TRAPHANDLER(vector10, 10)
  1017ee:	6a 0a                	push   $0xa
  1017f0:	e9 6f 38 00 00       	jmp    105064 <_alltraps>
  1017f5:	90                   	nop

001017f6 <vector11>:
TRAPHANDLER(vector11, 11)
  1017f6:	6a 0b                	push   $0xb
  1017f8:	e9 67 38 00 00       	jmp    105064 <_alltraps>
  1017fd:	90                   	nop

001017fe <vector12>:
TRAPHANDLER(vector12, 12)
  1017fe:	6a 0c                	push   $0xc
  101800:	e9 5f 38 00 00       	jmp    105064 <_alltraps>
  101805:	90                   	nop

00101806 <vector13>:
TRAPHANDLER(vector13, 13)
  101806:	6a 0d                	push   $0xd
  101808:	e9 57 38 00 00       	jmp    105064 <_alltraps>
  10180d:	90                   	nop

0010180e <vector14>:
TRAPHANDLER(vector14, 14)
  10180e:	6a 0e                	push   $0xe
  101810:	e9 4f 38 00 00       	jmp    105064 <_alltraps>
  101815:	90                   	nop

00101816 <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101816:	6a 00                	push   $0x0
  101818:	6a 0f                	push   $0xf
  10181a:	e9 45 38 00 00       	jmp    105064 <_alltraps>
  10181f:	90                   	nop

00101820 <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  101820:	6a 00                	push   $0x0
  101822:	6a 10                	push   $0x10
  101824:	e9 3b 38 00 00       	jmp    105064 <_alltraps>
  101829:	90                   	nop

0010182a <vector17>:
TRAPHANDLER(vector17, 17)
  10182a:	6a 11                	push   $0x11
  10182c:	e9 33 38 00 00       	jmp    105064 <_alltraps>
  101831:	90                   	nop

00101832 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  101832:	6a 00                	push   $0x0
  101834:	6a 12                	push   $0x12
  101836:	e9 29 38 00 00       	jmp    105064 <_alltraps>
  10183b:	90                   	nop

0010183c <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  10183c:	6a 00                	push   $0x0
  10183e:	6a 13                	push   $0x13
  101840:	e9 1f 38 00 00       	jmp    105064 <_alltraps>
  101845:	90                   	nop

00101846 <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  101846:	6a 00                	push   $0x0
  101848:	6a 1e                	push   $0x1e
  10184a:	e9 15 38 00 00       	jmp    105064 <_alltraps>

0010184f <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  10184f:	55                   	push   %ebp
  101850:	89 e5                	mov    %esp,%ebp
  101852:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  101855:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  10185c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10185f:	0f b7 00             	movzwl (%eax),%eax
  101862:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  101866:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101869:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  10186e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101871:	0f b7 00             	movzwl (%eax),%eax
  101874:	66 3d 5a a5          	cmp    $0xa55a,%ax
  101878:	74 13                	je     10188d <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  10187a:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  101881:	c7 05 e0 6f 10 00 b4 	movl   $0x3b4,0x106fe0
  101888:	03 00 00 
  10188b:	eb 14                	jmp    1018a1 <video_init+0x52>
	} else {
		*cp = was;
  10188d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101890:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  101894:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  101897:	c7 05 e0 6f 10 00 d4 	movl   $0x3d4,0x106fe0
  10189e:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  1018a1:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1018a6:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1018a9:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1018ad:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1018b1:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1018b4:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  1018b5:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1018ba:	83 c0 01             	add    $0x1,%eax
  1018bd:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1018c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1018c3:	89 c2                	mov    %eax,%edx
  1018c5:	ec                   	in     (%dx),%al
  1018c6:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  1018c9:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  1018cd:	0f b6 c0             	movzbl %al,%eax
  1018d0:	c1 e0 08             	shl    $0x8,%eax
  1018d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  1018d6:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1018db:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1018de:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1018e2:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1018e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1018e9:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  1018ea:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  1018ef:	83 c0 01             	add    $0x1,%eax
  1018f2:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1018f5:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1018f8:	89 c2                	mov    %eax,%edx
  1018fa:	ec                   	in     (%dx),%al
  1018fb:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  1018fe:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  101902:	0f b6 c0             	movzbl %al,%eax
  101905:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  101908:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10190b:	a3 e4 6f 10 00       	mov    %eax,0x106fe4
	crt_pos = pos;
  101910:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101913:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
}
  101919:	c9                   	leave  
  10191a:	c3                   	ret    

0010191b <video_putc>:



void
video_putc(int c)
{
  10191b:	55                   	push   %ebp
  10191c:	89 e5                	mov    %esp,%ebp
  10191e:	53                   	push   %ebx
  10191f:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  101922:	8b 45 08             	mov    0x8(%ebp),%eax
  101925:	b0 00                	mov    $0x0,%al
  101927:	85 c0                	test   %eax,%eax
  101929:	75 07                	jne    101932 <video_putc+0x17>
		c |= 0x0700;
  10192b:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  101932:	8b 45 08             	mov    0x8(%ebp),%eax
  101935:	25 ff 00 00 00       	and    $0xff,%eax
  10193a:	83 f8 09             	cmp    $0x9,%eax
  10193d:	0f 84 ae 00 00 00    	je     1019f1 <video_putc+0xd6>
  101943:	83 f8 09             	cmp    $0x9,%eax
  101946:	7f 0a                	jg     101952 <video_putc+0x37>
  101948:	83 f8 08             	cmp    $0x8,%eax
  10194b:	74 14                	je     101961 <video_putc+0x46>
  10194d:	e9 dd 00 00 00       	jmp    101a2f <video_putc+0x114>
  101952:	83 f8 0a             	cmp    $0xa,%eax
  101955:	74 4e                	je     1019a5 <video_putc+0x8a>
  101957:	83 f8 0d             	cmp    $0xd,%eax
  10195a:	74 59                	je     1019b5 <video_putc+0x9a>
  10195c:	e9 ce 00 00 00       	jmp    101a2f <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  101961:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101968:	66 85 c0             	test   %ax,%ax
  10196b:	0f 84 e4 00 00 00    	je     101a55 <video_putc+0x13a>
			crt_pos--;
  101971:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101978:	83 e8 01             	sub    $0x1,%eax
  10197b:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  101981:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101986:	0f b7 15 e8 6f 10 00 	movzwl 0x106fe8,%edx
  10198d:	0f b7 d2             	movzwl %dx,%edx
  101990:	01 d2                	add    %edx,%edx
  101992:	8d 14 10             	lea    (%eax,%edx,1),%edx
  101995:	8b 45 08             	mov    0x8(%ebp),%eax
  101998:	b0 00                	mov    $0x0,%al
  10199a:	83 c8 20             	or     $0x20,%eax
  10199d:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  1019a0:	e9 b1 00 00 00       	jmp    101a56 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  1019a5:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  1019ac:	83 c0 50             	add    $0x50,%eax
  1019af:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  1019b5:	0f b7 1d e8 6f 10 00 	movzwl 0x106fe8,%ebx
  1019bc:	0f b7 0d e8 6f 10 00 	movzwl 0x106fe8,%ecx
  1019c3:	0f b7 c1             	movzwl %cx,%eax
  1019c6:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  1019cc:	c1 e8 10             	shr    $0x10,%eax
  1019cf:	89 c2                	mov    %eax,%edx
  1019d1:	66 c1 ea 06          	shr    $0x6,%dx
  1019d5:	89 d0                	mov    %edx,%eax
  1019d7:	c1 e0 02             	shl    $0x2,%eax
  1019da:	01 d0                	add    %edx,%eax
  1019dc:	c1 e0 04             	shl    $0x4,%eax
  1019df:	89 ca                	mov    %ecx,%edx
  1019e1:	66 29 c2             	sub    %ax,%dx
  1019e4:	89 d8                	mov    %ebx,%eax
  1019e6:	66 29 d0             	sub    %dx,%ax
  1019e9:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
		break;
  1019ef:	eb 65                	jmp    101a56 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  1019f1:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1019f8:	e8 1e ff ff ff       	call   10191b <video_putc>
		video_putc(' ');
  1019fd:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101a04:	e8 12 ff ff ff       	call   10191b <video_putc>
		video_putc(' ');
  101a09:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101a10:	e8 06 ff ff ff       	call   10191b <video_putc>
		video_putc(' ');
  101a15:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101a1c:	e8 fa fe ff ff       	call   10191b <video_putc>
		video_putc(' ');
  101a21:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101a28:	e8 ee fe ff ff       	call   10191b <video_putc>
		break;
  101a2d:	eb 27                	jmp    101a56 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  101a2f:	8b 15 e4 6f 10 00    	mov    0x106fe4,%edx
  101a35:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101a3c:	0f b7 c8             	movzwl %ax,%ecx
  101a3f:	01 c9                	add    %ecx,%ecx
  101a41:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  101a44:	8b 55 08             	mov    0x8(%ebp),%edx
  101a47:	66 89 11             	mov    %dx,(%ecx)
  101a4a:	83 c0 01             	add    $0x1,%eax
  101a4d:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
  101a53:	eb 01                	jmp    101a56 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  101a55:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  101a56:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101a5d:	66 3d cf 07          	cmp    $0x7cf,%ax
  101a61:	76 5b                	jbe    101abe <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  101a63:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101a68:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  101a6e:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101a73:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  101a7a:	00 
  101a7b:	89 54 24 04          	mov    %edx,0x4(%esp)
  101a7f:	89 04 24             	mov    %eax,(%esp)
  101a82:	e8 a0 0e 00 00       	call   102927 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101a87:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  101a8e:	eb 15                	jmp    101aa5 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  101a90:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101a95:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101a98:	01 d2                	add    %edx,%edx
  101a9a:	01 d0                	add    %edx,%eax
  101a9c:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101aa1:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  101aa5:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  101aac:	7e e2                	jle    101a90 <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  101aae:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101ab5:	83 e8 50             	sub    $0x50,%eax
  101ab8:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  101abe:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101ac3:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101ac6:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101aca:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101ace:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101ad1:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101ad2:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101ad9:	66 c1 e8 08          	shr    $0x8,%ax
  101add:	0f b6 c0             	movzbl %al,%eax
  101ae0:	8b 15 e0 6f 10 00    	mov    0x106fe0,%edx
  101ae6:	83 c2 01             	add    $0x1,%edx
  101ae9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  101aec:	88 45 e3             	mov    %al,-0x1d(%ebp)
  101aef:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101af3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101af6:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  101af7:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101afc:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101aff:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  101b03:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  101b07:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101b0a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  101b0b:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101b12:	0f b6 c0             	movzbl %al,%eax
  101b15:	8b 15 e0 6f 10 00    	mov    0x106fe0,%edx
  101b1b:	83 c2 01             	add    $0x1,%edx
  101b1e:	89 55 f4             	mov    %edx,-0xc(%ebp)
  101b21:	88 45 f3             	mov    %al,-0xd(%ebp)
  101b24:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101b28:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101b2b:	ee                   	out    %al,(%dx)
}
  101b2c:	83 c4 44             	add    $0x44,%esp
  101b2f:	5b                   	pop    %ebx
  101b30:	5d                   	pop    %ebp
  101b31:	c3                   	ret    

00101b32 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  101b32:	55                   	push   %ebp
  101b33:	89 e5                	mov    %esp,%ebp
  101b35:	83 ec 38             	sub    $0x38,%esp
  101b38:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101b3f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101b42:	89 c2                	mov    %eax,%edx
  101b44:	ec                   	in     (%dx),%al
  101b45:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  101b48:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  101b4c:	0f b6 c0             	movzbl %al,%eax
  101b4f:	83 e0 01             	and    $0x1,%eax
  101b52:	85 c0                	test   %eax,%eax
  101b54:	75 0a                	jne    101b60 <kbd_proc_data+0x2e>
		return -1;
  101b56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101b5b:	e9 5a 01 00 00       	jmp    101cba <kbd_proc_data+0x188>
  101b60:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101b67:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101b6a:	89 c2                	mov    %eax,%edx
  101b6c:	ec                   	in     (%dx),%al
  101b6d:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  101b70:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  101b74:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  101b77:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  101b7b:	75 17                	jne    101b94 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  101b7d:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101b82:	83 c8 40             	or     $0x40,%eax
  101b85:	a3 ec 6f 10 00       	mov    %eax,0x106fec
		return 0;
  101b8a:	b8 00 00 00 00       	mov    $0x0,%eax
  101b8f:	e9 26 01 00 00       	jmp    101cba <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  101b94:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101b98:	84 c0                	test   %al,%al
  101b9a:	79 47                	jns    101be3 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  101b9c:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101ba1:	83 e0 40             	and    $0x40,%eax
  101ba4:	85 c0                	test   %eax,%eax
  101ba6:	75 09                	jne    101bb1 <kbd_proc_data+0x7f>
  101ba8:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101bac:	83 e0 7f             	and    $0x7f,%eax
  101baf:	eb 04                	jmp    101bb5 <kbd_proc_data+0x83>
  101bb1:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101bb5:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  101bb8:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101bbc:	0f b6 80 a0 50 10 00 	movzbl 0x1050a0(%eax),%eax
  101bc3:	83 c8 40             	or     $0x40,%eax
  101bc6:	0f b6 c0             	movzbl %al,%eax
  101bc9:	f7 d0                	not    %eax
  101bcb:	89 c2                	mov    %eax,%edx
  101bcd:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101bd2:	21 d0                	and    %edx,%eax
  101bd4:	a3 ec 6f 10 00       	mov    %eax,0x106fec
		return 0;
  101bd9:	b8 00 00 00 00       	mov    $0x0,%eax
  101bde:	e9 d7 00 00 00       	jmp    101cba <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  101be3:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101be8:	83 e0 40             	and    $0x40,%eax
  101beb:	85 c0                	test   %eax,%eax
  101bed:	74 11                	je     101c00 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  101bef:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  101bf3:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101bf8:	83 e0 bf             	and    $0xffffffbf,%eax
  101bfb:	a3 ec 6f 10 00       	mov    %eax,0x106fec
	}

	shift |= shiftcode[data];
  101c00:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101c04:	0f b6 80 a0 50 10 00 	movzbl 0x1050a0(%eax),%eax
  101c0b:	0f b6 d0             	movzbl %al,%edx
  101c0e:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c13:	09 d0                	or     %edx,%eax
  101c15:	a3 ec 6f 10 00       	mov    %eax,0x106fec
	shift ^= togglecode[data];
  101c1a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101c1e:	0f b6 80 a0 51 10 00 	movzbl 0x1051a0(%eax),%eax
  101c25:	0f b6 d0             	movzbl %al,%edx
  101c28:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c2d:	31 d0                	xor    %edx,%eax
  101c2f:	a3 ec 6f 10 00       	mov    %eax,0x106fec

	c = charcode[shift & (CTL | SHIFT)][data];
  101c34:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c39:	83 e0 03             	and    $0x3,%eax
  101c3c:	8b 14 85 a0 55 10 00 	mov    0x1055a0(,%eax,4),%edx
  101c43:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101c47:	8d 04 02             	lea    (%edx,%eax,1),%eax
  101c4a:	0f b6 00             	movzbl (%eax),%eax
  101c4d:	0f b6 c0             	movzbl %al,%eax
  101c50:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  101c53:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c58:	83 e0 08             	and    $0x8,%eax
  101c5b:	85 c0                	test   %eax,%eax
  101c5d:	74 22                	je     101c81 <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  101c5f:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  101c63:	7e 0c                	jle    101c71 <kbd_proc_data+0x13f>
  101c65:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  101c69:	7f 06                	jg     101c71 <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  101c6b:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  101c6f:	eb 10                	jmp    101c81 <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  101c71:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  101c75:	7e 0a                	jle    101c81 <kbd_proc_data+0x14f>
  101c77:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  101c7b:	7f 04                	jg     101c81 <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  101c7d:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  101c81:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c86:	f7 d0                	not    %eax
  101c88:	83 e0 06             	and    $0x6,%eax
  101c8b:	85 c0                	test   %eax,%eax
  101c8d:	75 28                	jne    101cb7 <kbd_proc_data+0x185>
  101c8f:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  101c96:	75 1f                	jne    101cb7 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  101c98:	c7 04 24 90 36 10 00 	movl   $0x103690,(%esp)
  101c9f:	e8 2a 0a 00 00       	call   1026ce <cprintf>
  101ca4:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  101cab:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101caf:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101cb3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101cb6:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  101cb7:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  101cba:	c9                   	leave  
  101cbb:	c3                   	ret    

00101cbc <kbd_intr>:

void
kbd_intr(void)
{
  101cbc:	55                   	push   %ebp
  101cbd:	89 e5                	mov    %esp,%ebp
  101cbf:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  101cc2:	c7 04 24 32 1b 10 00 	movl   $0x101b32,(%esp)
  101cc9:	e8 24 e5 ff ff       	call   1001f2 <cons_intr>
}
  101cce:	c9                   	leave  
  101ccf:	c3                   	ret    

00101cd0 <kbd_init>:

void
kbd_init(void)
{
  101cd0:	55                   	push   %ebp
  101cd1:	89 e5                	mov    %esp,%ebp
}
  101cd3:	5d                   	pop    %ebp
  101cd4:	c3                   	ret    

00101cd5 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  101cd5:	55                   	push   %ebp
  101cd6:	89 e5                	mov    %esp,%ebp
  101cd8:	83 ec 20             	sub    $0x20,%esp
  101cdb:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ce2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101ce5:	89 c2                	mov    %eax,%edx
  101ce7:	ec                   	in     (%dx),%al
  101ce8:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  101ceb:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101cf2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101cf5:	89 c2                	mov    %eax,%edx
  101cf7:	ec                   	in     (%dx),%al
  101cf8:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101cfb:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101d02:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101d05:	89 c2                	mov    %eax,%edx
  101d07:	ec                   	in     (%dx),%al
  101d08:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101d0b:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101d12:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101d15:	89 c2                	mov    %eax,%edx
  101d17:	ec                   	in     (%dx),%al
  101d18:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  101d1b:	c9                   	leave  
  101d1c:	c3                   	ret    

00101d1d <serial_proc_data>:

static int
serial_proc_data(void)
{
  101d1d:	55                   	push   %ebp
  101d1e:	89 e5                	mov    %esp,%ebp
  101d20:	83 ec 10             	sub    $0x10,%esp
  101d23:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  101d2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101d2d:	89 c2                	mov    %eax,%edx
  101d2f:	ec                   	in     (%dx),%al
  101d30:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101d33:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  101d37:	0f b6 c0             	movzbl %al,%eax
  101d3a:	83 e0 01             	and    $0x1,%eax
  101d3d:	85 c0                	test   %eax,%eax
  101d3f:	75 07                	jne    101d48 <serial_proc_data+0x2b>
		return -1;
  101d41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101d46:	eb 17                	jmp    101d5f <serial_proc_data+0x42>
  101d48:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101d4f:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101d52:	89 c2                	mov    %eax,%edx
  101d54:	ec                   	in     (%dx),%al
  101d55:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101d58:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  101d5c:	0f b6 c0             	movzbl %al,%eax
}
  101d5f:	c9                   	leave  
  101d60:	c3                   	ret    

00101d61 <serial_intr>:

void
serial_intr(void)
{
  101d61:	55                   	push   %ebp
  101d62:	89 e5                	mov    %esp,%ebp
  101d64:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  101d67:	a1 00 70 10 00       	mov    0x107000,%eax
  101d6c:	85 c0                	test   %eax,%eax
  101d6e:	74 0c                	je     101d7c <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  101d70:	c7 04 24 1d 1d 10 00 	movl   $0x101d1d,(%esp)
  101d77:	e8 76 e4 ff ff       	call   1001f2 <cons_intr>
}
  101d7c:	c9                   	leave  
  101d7d:	c3                   	ret    

00101d7e <serial_putc>:

void
serial_putc(int c)
{
  101d7e:	55                   	push   %ebp
  101d7f:	89 e5                	mov    %esp,%ebp
  101d81:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  101d84:	a1 00 70 10 00       	mov    0x107000,%eax
  101d89:	85 c0                	test   %eax,%eax
  101d8b:	74 53                	je     101de0 <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  101d8d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  101d94:	eb 09                	jmp    101d9f <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  101d96:	e8 3a ff ff ff       	call   101cd5 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  101d9b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  101d9f:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101da6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101da9:	89 c2                	mov    %eax,%edx
  101dab:	ec                   	in     (%dx),%al
  101dac:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  101daf:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101db3:	0f b6 c0             	movzbl %al,%eax
  101db6:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  101db9:	85 c0                	test   %eax,%eax
  101dbb:	75 09                	jne    101dc6 <serial_putc+0x48>
  101dbd:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  101dc4:	7e d0                	jle    101d96 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  101dc6:	8b 45 08             	mov    0x8(%ebp),%eax
  101dc9:	0f b6 c0             	movzbl %al,%eax
  101dcc:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  101dd3:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101dd6:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101dda:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101ddd:	ee                   	out    %al,(%dx)
  101dde:	eb 01                	jmp    101de1 <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  101de0:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  101de1:	c9                   	leave  
  101de2:	c3                   	ret    

00101de3 <serial_init>:

void
serial_init(void)
{
  101de3:	55                   	push   %ebp
  101de4:	89 e5                	mov    %esp,%ebp
  101de6:	83 ec 50             	sub    $0x50,%esp
  101de9:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  101df0:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  101df4:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  101df8:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  101dfb:	ee                   	out    %al,(%dx)
  101dfc:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  101e03:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  101e07:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  101e0b:	8b 55 bc             	mov    -0x44(%ebp),%edx
  101e0e:	ee                   	out    %al,(%dx)
  101e0f:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  101e16:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  101e1a:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  101e1e:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  101e21:	ee                   	out    %al,(%dx)
  101e22:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  101e29:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  101e2d:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  101e31:	8b 55 cc             	mov    -0x34(%ebp),%edx
  101e34:	ee                   	out    %al,(%dx)
  101e35:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  101e3c:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  101e40:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  101e44:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101e47:	ee                   	out    %al,(%dx)
  101e48:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  101e4f:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  101e53:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101e57:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101e5a:	ee                   	out    %al,(%dx)
  101e5b:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  101e62:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  101e66:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101e6a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101e6d:	ee                   	out    %al,(%dx)
  101e6e:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101e75:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101e78:	89 c2                	mov    %eax,%edx
  101e7a:	ec                   	in     (%dx),%al
  101e7b:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101e7e:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  101e82:	3c ff                	cmp    $0xff,%al
  101e84:	0f 95 c0             	setne  %al
  101e87:	0f b6 c0             	movzbl %al,%eax
  101e8a:	a3 00 70 10 00       	mov    %eax,0x107000
  101e8f:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101e96:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e99:	89 c2                	mov    %eax,%edx
  101e9b:	ec                   	in     (%dx),%al
  101e9c:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101e9f:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ea6:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101ea9:	89 c2                	mov    %eax,%edx
  101eab:	ec                   	in     (%dx),%al
  101eac:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  101eaf:	c9                   	leave  
  101eb0:	c3                   	ret    

00101eb1 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  101eb1:	55                   	push   %ebp
  101eb2:	89 e5                	mov    %esp,%ebp
  101eb4:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101eb7:	8b 45 08             	mov    0x8(%ebp),%eax
  101eba:	0f b6 c0             	movzbl %al,%eax
  101ebd:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101ec4:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101ec7:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101ecb:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101ece:	ee                   	out    %al,(%dx)
  101ecf:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ed6:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101ed9:	89 c2                	mov    %eax,%edx
  101edb:	ec                   	in     (%dx),%al
  101edc:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101edf:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  101ee3:	0f b6 c0             	movzbl %al,%eax
}
  101ee6:	c9                   	leave  
  101ee7:	c3                   	ret    

00101ee8 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  101ee8:	55                   	push   %ebp
  101ee9:	89 e5                	mov    %esp,%ebp
  101eeb:	53                   	push   %ebx
  101eec:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  101eef:	8b 45 08             	mov    0x8(%ebp),%eax
  101ef2:	89 04 24             	mov    %eax,(%esp)
  101ef5:	e8 b7 ff ff ff       	call   101eb1 <nvram_read>
  101efa:	89 c3                	mov    %eax,%ebx
  101efc:	8b 45 08             	mov    0x8(%ebp),%eax
  101eff:	83 c0 01             	add    $0x1,%eax
  101f02:	89 04 24             	mov    %eax,(%esp)
  101f05:	e8 a7 ff ff ff       	call   101eb1 <nvram_read>
  101f0a:	c1 e0 08             	shl    $0x8,%eax
  101f0d:	09 d8                	or     %ebx,%eax
}
  101f0f:	83 c4 04             	add    $0x4,%esp
  101f12:	5b                   	pop    %ebx
  101f13:	5d                   	pop    %ebp
  101f14:	c3                   	ret    

00101f15 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  101f15:	55                   	push   %ebp
  101f16:	89 e5                	mov    %esp,%ebp
  101f18:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101f1b:	8b 45 08             	mov    0x8(%ebp),%eax
  101f1e:	0f b6 c0             	movzbl %al,%eax
  101f21:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101f28:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101f2b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101f2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101f32:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  101f33:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f36:	0f b6 c0             	movzbl %al,%eax
  101f39:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  101f40:	88 45 fb             	mov    %al,-0x5(%ebp)
  101f43:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101f47:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101f4a:	ee                   	out    %al,(%dx)
}
  101f4b:	c9                   	leave  
  101f4c:	c3                   	ret    

00101f4d <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  101f4d:	55                   	push   %ebp
  101f4e:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  101f50:	8b 45 08             	mov    0x8(%ebp),%eax
  101f53:	8b 40 18             	mov    0x18(%eax),%eax
  101f56:	83 e0 02             	and    $0x2,%eax
  101f59:	85 c0                	test   %eax,%eax
  101f5b:	74 1c                	je     101f79 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  101f5d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f60:	8b 00                	mov    (%eax),%eax
  101f62:	8d 50 08             	lea    0x8(%eax),%edx
  101f65:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f68:	89 10                	mov    %edx,(%eax)
  101f6a:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f6d:	8b 00                	mov    (%eax),%eax
  101f6f:	83 e8 08             	sub    $0x8,%eax
  101f72:	8b 50 04             	mov    0x4(%eax),%edx
  101f75:	8b 00                	mov    (%eax),%eax
  101f77:	eb 47                	jmp    101fc0 <getuint+0x73>
	else if (st->flags & F_L)
  101f79:	8b 45 08             	mov    0x8(%ebp),%eax
  101f7c:	8b 40 18             	mov    0x18(%eax),%eax
  101f7f:	83 e0 01             	and    $0x1,%eax
  101f82:	84 c0                	test   %al,%al
  101f84:	74 1e                	je     101fa4 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  101f86:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f89:	8b 00                	mov    (%eax),%eax
  101f8b:	8d 50 04             	lea    0x4(%eax),%edx
  101f8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f91:	89 10                	mov    %edx,(%eax)
  101f93:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f96:	8b 00                	mov    (%eax),%eax
  101f98:	83 e8 04             	sub    $0x4,%eax
  101f9b:	8b 00                	mov    (%eax),%eax
  101f9d:	ba 00 00 00 00       	mov    $0x0,%edx
  101fa2:	eb 1c                	jmp    101fc0 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  101fa4:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fa7:	8b 00                	mov    (%eax),%eax
  101fa9:	8d 50 04             	lea    0x4(%eax),%edx
  101fac:	8b 45 0c             	mov    0xc(%ebp),%eax
  101faf:	89 10                	mov    %edx,(%eax)
  101fb1:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fb4:	8b 00                	mov    (%eax),%eax
  101fb6:	83 e8 04             	sub    $0x4,%eax
  101fb9:	8b 00                	mov    (%eax),%eax
  101fbb:	ba 00 00 00 00       	mov    $0x0,%edx
}
  101fc0:	5d                   	pop    %ebp
  101fc1:	c3                   	ret    

00101fc2 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  101fc2:	55                   	push   %ebp
  101fc3:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  101fc5:	8b 45 08             	mov    0x8(%ebp),%eax
  101fc8:	8b 40 18             	mov    0x18(%eax),%eax
  101fcb:	83 e0 02             	and    $0x2,%eax
  101fce:	85 c0                	test   %eax,%eax
  101fd0:	74 1c                	je     101fee <getint+0x2c>
		return va_arg(*ap, long long);
  101fd2:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fd5:	8b 00                	mov    (%eax),%eax
  101fd7:	8d 50 08             	lea    0x8(%eax),%edx
  101fda:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fdd:	89 10                	mov    %edx,(%eax)
  101fdf:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fe2:	8b 00                	mov    (%eax),%eax
  101fe4:	83 e8 08             	sub    $0x8,%eax
  101fe7:	8b 50 04             	mov    0x4(%eax),%edx
  101fea:	8b 00                	mov    (%eax),%eax
  101fec:	eb 47                	jmp    102035 <getint+0x73>
	else if (st->flags & F_L)
  101fee:	8b 45 08             	mov    0x8(%ebp),%eax
  101ff1:	8b 40 18             	mov    0x18(%eax),%eax
  101ff4:	83 e0 01             	and    $0x1,%eax
  101ff7:	84 c0                	test   %al,%al
  101ff9:	74 1e                	je     102019 <getint+0x57>
		return va_arg(*ap, long);
  101ffb:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ffe:	8b 00                	mov    (%eax),%eax
  102000:	8d 50 04             	lea    0x4(%eax),%edx
  102003:	8b 45 0c             	mov    0xc(%ebp),%eax
  102006:	89 10                	mov    %edx,(%eax)
  102008:	8b 45 0c             	mov    0xc(%ebp),%eax
  10200b:	8b 00                	mov    (%eax),%eax
  10200d:	83 e8 04             	sub    $0x4,%eax
  102010:	8b 00                	mov    (%eax),%eax
  102012:	89 c2                	mov    %eax,%edx
  102014:	c1 fa 1f             	sar    $0x1f,%edx
  102017:	eb 1c                	jmp    102035 <getint+0x73>
	else
		return va_arg(*ap, int);
  102019:	8b 45 0c             	mov    0xc(%ebp),%eax
  10201c:	8b 00                	mov    (%eax),%eax
  10201e:	8d 50 04             	lea    0x4(%eax),%edx
  102021:	8b 45 0c             	mov    0xc(%ebp),%eax
  102024:	89 10                	mov    %edx,(%eax)
  102026:	8b 45 0c             	mov    0xc(%ebp),%eax
  102029:	8b 00                	mov    (%eax),%eax
  10202b:	83 e8 04             	sub    $0x4,%eax
  10202e:	8b 00                	mov    (%eax),%eax
  102030:	89 c2                	mov    %eax,%edx
  102032:	c1 fa 1f             	sar    $0x1f,%edx
}
  102035:	5d                   	pop    %ebp
  102036:	c3                   	ret    

00102037 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  102037:	55                   	push   %ebp
  102038:	89 e5                	mov    %esp,%ebp
  10203a:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  10203d:	eb 1a                	jmp    102059 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  10203f:	8b 45 08             	mov    0x8(%ebp),%eax
  102042:	8b 08                	mov    (%eax),%ecx
  102044:	8b 45 08             	mov    0x8(%ebp),%eax
  102047:	8b 50 04             	mov    0x4(%eax),%edx
  10204a:	8b 45 08             	mov    0x8(%ebp),%eax
  10204d:	8b 40 08             	mov    0x8(%eax),%eax
  102050:	89 54 24 04          	mov    %edx,0x4(%esp)
  102054:	89 04 24             	mov    %eax,(%esp)
  102057:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  102059:	8b 45 08             	mov    0x8(%ebp),%eax
  10205c:	8b 40 0c             	mov    0xc(%eax),%eax
  10205f:	8d 50 ff             	lea    -0x1(%eax),%edx
  102062:	8b 45 08             	mov    0x8(%ebp),%eax
  102065:	89 50 0c             	mov    %edx,0xc(%eax)
  102068:	8b 45 08             	mov    0x8(%ebp),%eax
  10206b:	8b 40 0c             	mov    0xc(%eax),%eax
  10206e:	85 c0                	test   %eax,%eax
  102070:	79 cd                	jns    10203f <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  102072:	c9                   	leave  
  102073:	c3                   	ret    

00102074 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  102074:	55                   	push   %ebp
  102075:	89 e5                	mov    %esp,%ebp
  102077:	53                   	push   %ebx
  102078:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  10207b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10207f:	79 18                	jns    102099 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  102081:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102088:	00 
  102089:	8b 45 0c             	mov    0xc(%ebp),%eax
  10208c:	89 04 24             	mov    %eax,(%esp)
  10208f:	e8 e7 07 00 00       	call   10287b <strchr>
  102094:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102097:	eb 2c                	jmp    1020c5 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  102099:	8b 45 10             	mov    0x10(%ebp),%eax
  10209c:	89 44 24 08          	mov    %eax,0x8(%esp)
  1020a0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1020a7:	00 
  1020a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020ab:	89 04 24             	mov    %eax,(%esp)
  1020ae:	e8 cc 09 00 00       	call   102a7f <memchr>
  1020b3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1020b6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1020ba:	75 09                	jne    1020c5 <putstr+0x51>
		lim = str + maxlen;
  1020bc:	8b 45 10             	mov    0x10(%ebp),%eax
  1020bf:	03 45 0c             	add    0xc(%ebp),%eax
  1020c2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  1020c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1020c8:	8b 40 0c             	mov    0xc(%eax),%eax
  1020cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  1020ce:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1020d1:	89 cb                	mov    %ecx,%ebx
  1020d3:	29 d3                	sub    %edx,%ebx
  1020d5:	89 da                	mov    %ebx,%edx
  1020d7:	8d 14 10             	lea    (%eax,%edx,1),%edx
  1020da:	8b 45 08             	mov    0x8(%ebp),%eax
  1020dd:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  1020e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1020e3:	8b 40 18             	mov    0x18(%eax),%eax
  1020e6:	83 e0 10             	and    $0x10,%eax
  1020e9:	85 c0                	test   %eax,%eax
  1020eb:	75 32                	jne    10211f <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  1020ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1020f0:	89 04 24             	mov    %eax,(%esp)
  1020f3:	e8 3f ff ff ff       	call   102037 <putpad>
	while (str < lim) {
  1020f8:	eb 25                	jmp    10211f <putstr+0xab>
		char ch = *str++;
  1020fa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020fd:	0f b6 00             	movzbl (%eax),%eax
  102100:	88 45 f7             	mov    %al,-0x9(%ebp)
  102103:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  102107:	8b 45 08             	mov    0x8(%ebp),%eax
  10210a:	8b 08                	mov    (%eax),%ecx
  10210c:	8b 45 08             	mov    0x8(%ebp),%eax
  10210f:	8b 50 04             	mov    0x4(%eax),%edx
  102112:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  102116:	89 54 24 04          	mov    %edx,0x4(%esp)
  10211a:	89 04 24             	mov    %eax,(%esp)
  10211d:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  10211f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102122:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102125:	72 d3                	jb     1020fa <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  102127:	8b 45 08             	mov    0x8(%ebp),%eax
  10212a:	89 04 24             	mov    %eax,(%esp)
  10212d:	e8 05 ff ff ff       	call   102037 <putpad>
}
  102132:	83 c4 24             	add    $0x24,%esp
  102135:	5b                   	pop    %ebx
  102136:	5d                   	pop    %ebp
  102137:	c3                   	ret    

00102138 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  102138:	55                   	push   %ebp
  102139:	89 e5                	mov    %esp,%ebp
  10213b:	53                   	push   %ebx
  10213c:	83 ec 24             	sub    $0x24,%esp
  10213f:	8b 45 10             	mov    0x10(%ebp),%eax
  102142:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102145:	8b 45 14             	mov    0x14(%ebp),%eax
  102148:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  10214b:	8b 45 08             	mov    0x8(%ebp),%eax
  10214e:	8b 40 1c             	mov    0x1c(%eax),%eax
  102151:	89 c2                	mov    %eax,%edx
  102153:	c1 fa 1f             	sar    $0x1f,%edx
  102156:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  102159:	77 4e                	ja     1021a9 <genint+0x71>
  10215b:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  10215e:	72 05                	jb     102165 <genint+0x2d>
  102160:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102163:	77 44                	ja     1021a9 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  102165:	8b 45 08             	mov    0x8(%ebp),%eax
  102168:	8b 40 1c             	mov    0x1c(%eax),%eax
  10216b:	89 c2                	mov    %eax,%edx
  10216d:	c1 fa 1f             	sar    $0x1f,%edx
  102170:	89 44 24 08          	mov    %eax,0x8(%esp)
  102174:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102178:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10217b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10217e:	89 04 24             	mov    %eax,(%esp)
  102181:	89 54 24 04          	mov    %edx,0x4(%esp)
  102185:	e8 36 09 00 00       	call   102ac0 <__udivdi3>
  10218a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10218e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102192:	8b 45 0c             	mov    0xc(%ebp),%eax
  102195:	89 44 24 04          	mov    %eax,0x4(%esp)
  102199:	8b 45 08             	mov    0x8(%ebp),%eax
  10219c:	89 04 24             	mov    %eax,(%esp)
  10219f:	e8 94 ff ff ff       	call   102138 <genint>
  1021a4:	89 45 0c             	mov    %eax,0xc(%ebp)
  1021a7:	eb 1b                	jmp    1021c4 <genint+0x8c>
	else if (st->signc >= 0)
  1021a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1021ac:	8b 40 14             	mov    0x14(%eax),%eax
  1021af:	85 c0                	test   %eax,%eax
  1021b1:	78 11                	js     1021c4 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  1021b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1021b6:	8b 40 14             	mov    0x14(%eax),%eax
  1021b9:	89 c2                	mov    %eax,%edx
  1021bb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021be:	88 10                	mov    %dl,(%eax)
  1021c0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  1021c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1021c7:	8b 40 1c             	mov    0x1c(%eax),%eax
  1021ca:	89 c1                	mov    %eax,%ecx
  1021cc:	89 c3                	mov    %eax,%ebx
  1021ce:	c1 fb 1f             	sar    $0x1f,%ebx
  1021d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1021d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1021d7:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1021db:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  1021df:	89 04 24             	mov    %eax,(%esp)
  1021e2:	89 54 24 04          	mov    %edx,0x4(%esp)
  1021e6:	e8 05 0a 00 00       	call   102bf0 <__umoddi3>
  1021eb:	05 9c 36 10 00       	add    $0x10369c,%eax
  1021f0:	0f b6 10             	movzbl (%eax),%edx
  1021f3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021f6:	88 10                	mov    %dl,(%eax)
  1021f8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  1021fc:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  1021ff:	83 c4 24             	add    $0x24,%esp
  102202:	5b                   	pop    %ebx
  102203:	5d                   	pop    %ebp
  102204:	c3                   	ret    

00102205 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  102205:	55                   	push   %ebp
  102206:	89 e5                	mov    %esp,%ebp
  102208:	83 ec 58             	sub    $0x58,%esp
  10220b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10220e:	89 45 c0             	mov    %eax,-0x40(%ebp)
  102211:	8b 45 10             	mov    0x10(%ebp),%eax
  102214:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  102217:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  10221a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  10221d:	8b 45 08             	mov    0x8(%ebp),%eax
  102220:	8b 55 14             	mov    0x14(%ebp),%edx
  102223:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  102226:	8b 45 c0             	mov    -0x40(%ebp),%eax
  102229:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  10222c:	89 44 24 08          	mov    %eax,0x8(%esp)
  102230:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102234:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102237:	89 44 24 04          	mov    %eax,0x4(%esp)
  10223b:	8b 45 08             	mov    0x8(%ebp),%eax
  10223e:	89 04 24             	mov    %eax,(%esp)
  102241:	e8 f2 fe ff ff       	call   102138 <genint>
  102246:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  102249:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10224c:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  10224f:	89 d1                	mov    %edx,%ecx
  102251:	29 c1                	sub    %eax,%ecx
  102253:	89 c8                	mov    %ecx,%eax
  102255:	89 44 24 08          	mov    %eax,0x8(%esp)
  102259:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  10225c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102260:	8b 45 08             	mov    0x8(%ebp),%eax
  102263:	89 04 24             	mov    %eax,(%esp)
  102266:	e8 09 fe ff ff       	call   102074 <putstr>
}
  10226b:	c9                   	leave  
  10226c:	c3                   	ret    

0010226d <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  10226d:	55                   	push   %ebp
  10226e:	89 e5                	mov    %esp,%ebp
  102270:	53                   	push   %ebx
  102271:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  102274:	8d 55 c8             	lea    -0x38(%ebp),%edx
  102277:	b9 00 00 00 00       	mov    $0x0,%ecx
  10227c:	b8 20 00 00 00       	mov    $0x20,%eax
  102281:	89 c3                	mov    %eax,%ebx
  102283:	83 e3 fc             	and    $0xfffffffc,%ebx
  102286:	b8 00 00 00 00       	mov    $0x0,%eax
  10228b:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  10228e:	83 c0 04             	add    $0x4,%eax
  102291:	39 d8                	cmp    %ebx,%eax
  102293:	72 f6                	jb     10228b <vprintfmt+0x1e>
  102295:	01 c2                	add    %eax,%edx
  102297:	8b 45 08             	mov    0x8(%ebp),%eax
  10229a:	89 45 c8             	mov    %eax,-0x38(%ebp)
  10229d:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022a0:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1022a3:	eb 17                	jmp    1022bc <vprintfmt+0x4f>
			if (ch == '\0')
  1022a5:	85 db                	test   %ebx,%ebx
  1022a7:	0f 84 52 03 00 00    	je     1025ff <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  1022ad:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022b0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022b4:	89 1c 24             	mov    %ebx,(%esp)
  1022b7:	8b 45 08             	mov    0x8(%ebp),%eax
  1022ba:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1022bc:	8b 45 10             	mov    0x10(%ebp),%eax
  1022bf:	0f b6 00             	movzbl (%eax),%eax
  1022c2:	0f b6 d8             	movzbl %al,%ebx
  1022c5:	83 fb 25             	cmp    $0x25,%ebx
  1022c8:	0f 95 c0             	setne  %al
  1022cb:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1022cf:	84 c0                	test   %al,%al
  1022d1:	75 d2                	jne    1022a5 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  1022d3:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  1022da:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  1022e1:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  1022e8:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  1022ef:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  1022f6:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  1022fd:	eb 04                	jmp    102303 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  1022ff:	90                   	nop
  102300:	eb 01                	jmp    102303 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  102302:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  102303:	8b 45 10             	mov    0x10(%ebp),%eax
  102306:	0f b6 00             	movzbl (%eax),%eax
  102309:	0f b6 d8             	movzbl %al,%ebx
  10230c:	89 d8                	mov    %ebx,%eax
  10230e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  102312:	83 e8 20             	sub    $0x20,%eax
  102315:	83 f8 58             	cmp    $0x58,%eax
  102318:	0f 87 b1 02 00 00    	ja     1025cf <vprintfmt+0x362>
  10231e:	8b 04 85 b4 36 10 00 	mov    0x1036b4(,%eax,4),%eax
  102325:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  102327:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10232a:	83 c8 10             	or     $0x10,%eax
  10232d:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102330:	eb d1                	jmp    102303 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  102332:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  102339:	eb c8                	jmp    102303 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  10233b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10233e:	85 c0                	test   %eax,%eax
  102340:	79 bd                	jns    1022ff <vprintfmt+0x92>
				st.signc = ' ';
  102342:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  102349:	eb b8                	jmp    102303 <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  10234b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10234e:	83 e0 08             	and    $0x8,%eax
  102351:	85 c0                	test   %eax,%eax
  102353:	75 07                	jne    10235c <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  102355:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10235c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  102363:	8b 55 d8             	mov    -0x28(%ebp),%edx
  102366:	89 d0                	mov    %edx,%eax
  102368:	c1 e0 02             	shl    $0x2,%eax
  10236b:	01 d0                	add    %edx,%eax
  10236d:	01 c0                	add    %eax,%eax
  10236f:	01 d8                	add    %ebx,%eax
  102371:	83 e8 30             	sub    $0x30,%eax
  102374:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  102377:	8b 45 10             	mov    0x10(%ebp),%eax
  10237a:	0f b6 00             	movzbl (%eax),%eax
  10237d:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  102380:	83 fb 2f             	cmp    $0x2f,%ebx
  102383:	7e 21                	jle    1023a6 <vprintfmt+0x139>
  102385:	83 fb 39             	cmp    $0x39,%ebx
  102388:	7f 1f                	jg     1023a9 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10238a:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  10238e:	eb d3                	jmp    102363 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  102390:	8b 45 14             	mov    0x14(%ebp),%eax
  102393:	83 c0 04             	add    $0x4,%eax
  102396:	89 45 14             	mov    %eax,0x14(%ebp)
  102399:	8b 45 14             	mov    0x14(%ebp),%eax
  10239c:	83 e8 04             	sub    $0x4,%eax
  10239f:	8b 00                	mov    (%eax),%eax
  1023a1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1023a4:	eb 04                	jmp    1023aa <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  1023a6:	90                   	nop
  1023a7:	eb 01                	jmp    1023aa <vprintfmt+0x13d>
  1023a9:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  1023aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1023ad:	83 e0 08             	and    $0x8,%eax
  1023b0:	85 c0                	test   %eax,%eax
  1023b2:	0f 85 4a ff ff ff    	jne    102302 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  1023b8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1023bb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  1023be:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  1023c5:	e9 39 ff ff ff       	jmp    102303 <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  1023ca:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1023cd:	83 c8 08             	or     $0x8,%eax
  1023d0:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1023d3:	e9 2b ff ff ff       	jmp    102303 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  1023d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1023db:	83 c8 04             	or     $0x4,%eax
  1023de:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1023e1:	e9 1d ff ff ff       	jmp    102303 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  1023e6:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1023e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1023ec:	83 e0 01             	and    $0x1,%eax
  1023ef:	84 c0                	test   %al,%al
  1023f1:	74 07                	je     1023fa <vprintfmt+0x18d>
  1023f3:	b8 02 00 00 00       	mov    $0x2,%eax
  1023f8:	eb 05                	jmp    1023ff <vprintfmt+0x192>
  1023fa:	b8 01 00 00 00       	mov    $0x1,%eax
  1023ff:	09 d0                	or     %edx,%eax
  102401:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  102404:	e9 fa fe ff ff       	jmp    102303 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  102409:	8b 45 14             	mov    0x14(%ebp),%eax
  10240c:	83 c0 04             	add    $0x4,%eax
  10240f:	89 45 14             	mov    %eax,0x14(%ebp)
  102412:	8b 45 14             	mov    0x14(%ebp),%eax
  102415:	83 e8 04             	sub    $0x4,%eax
  102418:	8b 00                	mov    (%eax),%eax
  10241a:	8b 55 0c             	mov    0xc(%ebp),%edx
  10241d:	89 54 24 04          	mov    %edx,0x4(%esp)
  102421:	89 04 24             	mov    %eax,(%esp)
  102424:	8b 45 08             	mov    0x8(%ebp),%eax
  102427:	ff d0                	call   *%eax
			break;
  102429:	e9 cb 01 00 00       	jmp    1025f9 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  10242e:	8b 45 14             	mov    0x14(%ebp),%eax
  102431:	83 c0 04             	add    $0x4,%eax
  102434:	89 45 14             	mov    %eax,0x14(%ebp)
  102437:	8b 45 14             	mov    0x14(%ebp),%eax
  10243a:	83 e8 04             	sub    $0x4,%eax
  10243d:	8b 00                	mov    (%eax),%eax
  10243f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102442:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102446:	75 07                	jne    10244f <vprintfmt+0x1e2>
				s = "(null)";
  102448:	c7 45 f4 ad 36 10 00 	movl   $0x1036ad,-0xc(%ebp)
			putstr(&st, s, st.prec);
  10244f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102452:	89 44 24 08          	mov    %eax,0x8(%esp)
  102456:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102459:	89 44 24 04          	mov    %eax,0x4(%esp)
  10245d:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102460:	89 04 24             	mov    %eax,(%esp)
  102463:	e8 0c fc ff ff       	call   102074 <putstr>
			break;
  102468:	e9 8c 01 00 00       	jmp    1025f9 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  10246d:	8d 45 14             	lea    0x14(%ebp),%eax
  102470:	89 44 24 04          	mov    %eax,0x4(%esp)
  102474:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102477:	89 04 24             	mov    %eax,(%esp)
  10247a:	e8 43 fb ff ff       	call   101fc2 <getint>
  10247f:	89 45 e8             	mov    %eax,-0x18(%ebp)
  102482:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  102485:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102488:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10248b:	85 d2                	test   %edx,%edx
  10248d:	79 1a                	jns    1024a9 <vprintfmt+0x23c>
				num = -(intmax_t) num;
  10248f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102492:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102495:	f7 d8                	neg    %eax
  102497:	83 d2 00             	adc    $0x0,%edx
  10249a:	f7 da                	neg    %edx
  10249c:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10249f:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  1024a2:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  1024a9:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1024b0:	00 
  1024b1:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1024b4:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1024b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024bb:	89 54 24 08          	mov    %edx,0x8(%esp)
  1024bf:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1024c2:	89 04 24             	mov    %eax,(%esp)
  1024c5:	e8 3b fd ff ff       	call   102205 <putint>
			break;
  1024ca:	e9 2a 01 00 00       	jmp    1025f9 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  1024cf:	8d 45 14             	lea    0x14(%ebp),%eax
  1024d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024d6:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1024d9:	89 04 24             	mov    %eax,(%esp)
  1024dc:	e8 6c fa ff ff       	call   101f4d <getuint>
  1024e1:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1024e8:	00 
  1024e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024ed:	89 54 24 08          	mov    %edx,0x8(%esp)
  1024f1:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1024f4:	89 04 24             	mov    %eax,(%esp)
  1024f7:	e8 09 fd ff ff       	call   102205 <putint>
			break;
  1024fc:	e9 f8 00 00 00       	jmp    1025f9 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  102501:	8d 45 14             	lea    0x14(%ebp),%eax
  102504:	89 44 24 04          	mov    %eax,0x4(%esp)
  102508:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10250b:	89 04 24             	mov    %eax,(%esp)
  10250e:	e8 3a fa ff ff       	call   101f4d <getuint>
  102513:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  10251a:	00 
  10251b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10251f:	89 54 24 08          	mov    %edx,0x8(%esp)
  102523:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102526:	89 04 24             	mov    %eax,(%esp)
  102529:	e8 d7 fc ff ff       	call   102205 <putint>
			break;
  10252e:	e9 c6 00 00 00       	jmp    1025f9 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  102533:	8d 45 14             	lea    0x14(%ebp),%eax
  102536:	89 44 24 04          	mov    %eax,0x4(%esp)
  10253a:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10253d:	89 04 24             	mov    %eax,(%esp)
  102540:	e8 08 fa ff ff       	call   101f4d <getuint>
  102545:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10254c:	00 
  10254d:	89 44 24 04          	mov    %eax,0x4(%esp)
  102551:	89 54 24 08          	mov    %edx,0x8(%esp)
  102555:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102558:	89 04 24             	mov    %eax,(%esp)
  10255b:	e8 a5 fc ff ff       	call   102205 <putint>
			break;
  102560:	e9 94 00 00 00       	jmp    1025f9 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  102565:	8b 45 0c             	mov    0xc(%ebp),%eax
  102568:	89 44 24 04          	mov    %eax,0x4(%esp)
  10256c:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  102573:	8b 45 08             	mov    0x8(%ebp),%eax
  102576:	ff d0                	call   *%eax
			putch('x', putdat);
  102578:	8b 45 0c             	mov    0xc(%ebp),%eax
  10257b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10257f:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  102586:	8b 45 08             	mov    0x8(%ebp),%eax
  102589:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  10258b:	8b 45 14             	mov    0x14(%ebp),%eax
  10258e:	83 c0 04             	add    $0x4,%eax
  102591:	89 45 14             	mov    %eax,0x14(%ebp)
  102594:	8b 45 14             	mov    0x14(%ebp),%eax
  102597:	83 e8 04             	sub    $0x4,%eax
  10259a:	8b 00                	mov    (%eax),%eax
  10259c:	ba 00 00 00 00       	mov    $0x0,%edx
  1025a1:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1025a8:	00 
  1025a9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025ad:	89 54 24 08          	mov    %edx,0x8(%esp)
  1025b1:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1025b4:	89 04 24             	mov    %eax,(%esp)
  1025b7:	e8 49 fc ff ff       	call   102205 <putint>
			break;
  1025bc:	eb 3b                	jmp    1025f9 <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  1025be:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025c5:	89 1c 24             	mov    %ebx,(%esp)
  1025c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1025cb:	ff d0                	call   *%eax
			break;
  1025cd:	eb 2a                	jmp    1025f9 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1025cf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025d6:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  1025dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1025e0:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  1025e2:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1025e6:	eb 04                	jmp    1025ec <vprintfmt+0x37f>
  1025e8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1025ec:	8b 45 10             	mov    0x10(%ebp),%eax
  1025ef:	83 e8 01             	sub    $0x1,%eax
  1025f2:	0f b6 00             	movzbl (%eax),%eax
  1025f5:	3c 25                	cmp    $0x25,%al
  1025f7:	75 ef                	jne    1025e8 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  1025f9:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1025fa:	e9 bd fc ff ff       	jmp    1022bc <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  1025ff:	83 c4 44             	add    $0x44,%esp
  102602:	5b                   	pop    %ebx
  102603:	5d                   	pop    %ebp
  102604:	c3                   	ret    

00102605 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  102605:	55                   	push   %ebp
  102606:	89 e5                	mov    %esp,%ebp
  102608:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  10260b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10260e:	8b 00                	mov    (%eax),%eax
  102610:	8b 55 08             	mov    0x8(%ebp),%edx
  102613:	89 d1                	mov    %edx,%ecx
  102615:	8b 55 0c             	mov    0xc(%ebp),%edx
  102618:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  10261c:	8d 50 01             	lea    0x1(%eax),%edx
  10261f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102622:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  102624:	8b 45 0c             	mov    0xc(%ebp),%eax
  102627:	8b 00                	mov    (%eax),%eax
  102629:	3d ff 00 00 00       	cmp    $0xff,%eax
  10262e:	75 24                	jne    102654 <putch+0x4f>
		b->buf[b->idx] = 0;
  102630:	8b 45 0c             	mov    0xc(%ebp),%eax
  102633:	8b 00                	mov    (%eax),%eax
  102635:	8b 55 0c             	mov    0xc(%ebp),%edx
  102638:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  10263d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102640:	83 c0 08             	add    $0x8,%eax
  102643:	89 04 24             	mov    %eax,(%esp)
  102646:	e8 b5 dc ff ff       	call   100300 <cputs>
		b->idx = 0;
  10264b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10264e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  102654:	8b 45 0c             	mov    0xc(%ebp),%eax
  102657:	8b 40 04             	mov    0x4(%eax),%eax
  10265a:	8d 50 01             	lea    0x1(%eax),%edx
  10265d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102660:	89 50 04             	mov    %edx,0x4(%eax)
}
  102663:	c9                   	leave  
  102664:	c3                   	ret    

00102665 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  102665:	55                   	push   %ebp
  102666:	89 e5                	mov    %esp,%ebp
  102668:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  10266e:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  102675:	00 00 00 
	b.cnt = 0;
  102678:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  10267f:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  102682:	b8 05 26 10 00       	mov    $0x102605,%eax
  102687:	8b 55 0c             	mov    0xc(%ebp),%edx
  10268a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10268e:	8b 55 08             	mov    0x8(%ebp),%edx
  102691:	89 54 24 08          	mov    %edx,0x8(%esp)
  102695:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  10269b:	89 54 24 04          	mov    %edx,0x4(%esp)
  10269f:	89 04 24             	mov    %eax,(%esp)
  1026a2:	e8 c6 fb ff ff       	call   10226d <vprintfmt>

	b.buf[b.idx] = 0;
  1026a7:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  1026ad:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  1026b4:	00 
	cputs(b.buf);
  1026b5:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1026bb:	83 c0 08             	add    $0x8,%eax
  1026be:	89 04 24             	mov    %eax,(%esp)
  1026c1:	e8 3a dc ff ff       	call   100300 <cputs>

	return b.cnt;
  1026c6:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  1026cc:	c9                   	leave  
  1026cd:	c3                   	ret    

001026ce <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1026ce:	55                   	push   %ebp
  1026cf:	89 e5                	mov    %esp,%ebp
  1026d1:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  1026d4:	8d 45 08             	lea    0x8(%ebp),%eax
  1026d7:	83 c0 04             	add    $0x4,%eax
  1026da:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  1026dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1026e0:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1026e3:	89 54 24 04          	mov    %edx,0x4(%esp)
  1026e7:	89 04 24             	mov    %eax,(%esp)
  1026ea:	e8 76 ff ff ff       	call   102665 <vcprintf>
  1026ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  1026f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  1026f5:	c9                   	leave  
  1026f6:	c3                   	ret    

001026f7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  1026f7:	55                   	push   %ebp
  1026f8:	89 e5                	mov    %esp,%ebp
  1026fa:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  1026fd:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  102704:	eb 08                	jmp    10270e <strlen+0x17>
		n++;
  102706:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  10270a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10270e:	8b 45 08             	mov    0x8(%ebp),%eax
  102711:	0f b6 00             	movzbl (%eax),%eax
  102714:	84 c0                	test   %al,%al
  102716:	75 ee                	jne    102706 <strlen+0xf>
		n++;
	return n;
  102718:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10271b:	c9                   	leave  
  10271c:	c3                   	ret    

0010271d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  10271d:	55                   	push   %ebp
  10271e:	89 e5                	mov    %esp,%ebp
  102720:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  102723:	8b 45 08             	mov    0x8(%ebp),%eax
  102726:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  102729:	8b 45 0c             	mov    0xc(%ebp),%eax
  10272c:	0f b6 10             	movzbl (%eax),%edx
  10272f:	8b 45 08             	mov    0x8(%ebp),%eax
  102732:	88 10                	mov    %dl,(%eax)
  102734:	8b 45 08             	mov    0x8(%ebp),%eax
  102737:	0f b6 00             	movzbl (%eax),%eax
  10273a:	84 c0                	test   %al,%al
  10273c:	0f 95 c0             	setne  %al
  10273f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102743:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  102747:	84 c0                	test   %al,%al
  102749:	75 de                	jne    102729 <strcpy+0xc>
		/* do nothing */;
	return ret;
  10274b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10274e:	c9                   	leave  
  10274f:	c3                   	ret    

00102750 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  102750:	55                   	push   %ebp
  102751:	89 e5                	mov    %esp,%ebp
  102753:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  102756:	8b 45 08             	mov    0x8(%ebp),%eax
  102759:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  10275c:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  102763:	eb 21                	jmp    102786 <strncpy+0x36>
		*dst++ = *src;
  102765:	8b 45 0c             	mov    0xc(%ebp),%eax
  102768:	0f b6 10             	movzbl (%eax),%edx
  10276b:	8b 45 08             	mov    0x8(%ebp),%eax
  10276e:	88 10                	mov    %dl,(%eax)
  102770:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  102774:	8b 45 0c             	mov    0xc(%ebp),%eax
  102777:	0f b6 00             	movzbl (%eax),%eax
  10277a:	84 c0                	test   %al,%al
  10277c:	74 04                	je     102782 <strncpy+0x32>
			src++;
  10277e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  102782:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  102786:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102789:	3b 45 10             	cmp    0x10(%ebp),%eax
  10278c:	72 d7                	jb     102765 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  10278e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102791:	c9                   	leave  
  102792:	c3                   	ret    

00102793 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  102793:	55                   	push   %ebp
  102794:	89 e5                	mov    %esp,%ebp
  102796:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  102799:	8b 45 08             	mov    0x8(%ebp),%eax
  10279c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  10279f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1027a3:	74 2f                	je     1027d4 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  1027a5:	eb 13                	jmp    1027ba <strlcpy+0x27>
			*dst++ = *src++;
  1027a7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027aa:	0f b6 10             	movzbl (%eax),%edx
  1027ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1027b0:	88 10                	mov    %dl,(%eax)
  1027b2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1027b6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  1027ba:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1027be:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1027c2:	74 0a                	je     1027ce <strlcpy+0x3b>
  1027c4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027c7:	0f b6 00             	movzbl (%eax),%eax
  1027ca:	84 c0                	test   %al,%al
  1027cc:	75 d9                	jne    1027a7 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  1027ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1027d1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  1027d4:	8b 55 08             	mov    0x8(%ebp),%edx
  1027d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1027da:	89 d1                	mov    %edx,%ecx
  1027dc:	29 c1                	sub    %eax,%ecx
  1027de:	89 c8                	mov    %ecx,%eax
}
  1027e0:	c9                   	leave  
  1027e1:	c3                   	ret    

001027e2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  1027e2:	55                   	push   %ebp
  1027e3:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  1027e5:	eb 08                	jmp    1027ef <strcmp+0xd>
		p++, q++;
  1027e7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1027eb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  1027ef:	8b 45 08             	mov    0x8(%ebp),%eax
  1027f2:	0f b6 00             	movzbl (%eax),%eax
  1027f5:	84 c0                	test   %al,%al
  1027f7:	74 10                	je     102809 <strcmp+0x27>
  1027f9:	8b 45 08             	mov    0x8(%ebp),%eax
  1027fc:	0f b6 10             	movzbl (%eax),%edx
  1027ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  102802:	0f b6 00             	movzbl (%eax),%eax
  102805:	38 c2                	cmp    %al,%dl
  102807:	74 de                	je     1027e7 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  102809:	8b 45 08             	mov    0x8(%ebp),%eax
  10280c:	0f b6 00             	movzbl (%eax),%eax
  10280f:	0f b6 d0             	movzbl %al,%edx
  102812:	8b 45 0c             	mov    0xc(%ebp),%eax
  102815:	0f b6 00             	movzbl (%eax),%eax
  102818:	0f b6 c0             	movzbl %al,%eax
  10281b:	89 d1                	mov    %edx,%ecx
  10281d:	29 c1                	sub    %eax,%ecx
  10281f:	89 c8                	mov    %ecx,%eax
}
  102821:	5d                   	pop    %ebp
  102822:	c3                   	ret    

00102823 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  102823:	55                   	push   %ebp
  102824:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  102826:	eb 0c                	jmp    102834 <strncmp+0x11>
		n--, p++, q++;
  102828:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10282c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102830:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  102834:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102838:	74 1a                	je     102854 <strncmp+0x31>
  10283a:	8b 45 08             	mov    0x8(%ebp),%eax
  10283d:	0f b6 00             	movzbl (%eax),%eax
  102840:	84 c0                	test   %al,%al
  102842:	74 10                	je     102854 <strncmp+0x31>
  102844:	8b 45 08             	mov    0x8(%ebp),%eax
  102847:	0f b6 10             	movzbl (%eax),%edx
  10284a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10284d:	0f b6 00             	movzbl (%eax),%eax
  102850:	38 c2                	cmp    %al,%dl
  102852:	74 d4                	je     102828 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  102854:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102858:	75 07                	jne    102861 <strncmp+0x3e>
		return 0;
  10285a:	b8 00 00 00 00       	mov    $0x0,%eax
  10285f:	eb 18                	jmp    102879 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  102861:	8b 45 08             	mov    0x8(%ebp),%eax
  102864:	0f b6 00             	movzbl (%eax),%eax
  102867:	0f b6 d0             	movzbl %al,%edx
  10286a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10286d:	0f b6 00             	movzbl (%eax),%eax
  102870:	0f b6 c0             	movzbl %al,%eax
  102873:	89 d1                	mov    %edx,%ecx
  102875:	29 c1                	sub    %eax,%ecx
  102877:	89 c8                	mov    %ecx,%eax
}
  102879:	5d                   	pop    %ebp
  10287a:	c3                   	ret    

0010287b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  10287b:	55                   	push   %ebp
  10287c:	89 e5                	mov    %esp,%ebp
  10287e:	83 ec 04             	sub    $0x4,%esp
  102881:	8b 45 0c             	mov    0xc(%ebp),%eax
  102884:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  102887:	eb 1a                	jmp    1028a3 <strchr+0x28>
		if (*s++ == 0)
  102889:	8b 45 08             	mov    0x8(%ebp),%eax
  10288c:	0f b6 00             	movzbl (%eax),%eax
  10288f:	84 c0                	test   %al,%al
  102891:	0f 94 c0             	sete   %al
  102894:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102898:	84 c0                	test   %al,%al
  10289a:	74 07                	je     1028a3 <strchr+0x28>
			return NULL;
  10289c:	b8 00 00 00 00       	mov    $0x0,%eax
  1028a1:	eb 0e                	jmp    1028b1 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  1028a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1028a6:	0f b6 00             	movzbl (%eax),%eax
  1028a9:	3a 45 fc             	cmp    -0x4(%ebp),%al
  1028ac:	75 db                	jne    102889 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  1028ae:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1028b1:	c9                   	leave  
  1028b2:	c3                   	ret    

001028b3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  1028b3:	55                   	push   %ebp
  1028b4:	89 e5                	mov    %esp,%ebp
  1028b6:	57                   	push   %edi
  1028b7:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  1028ba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1028be:	75 05                	jne    1028c5 <memset+0x12>
		return v;
  1028c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1028c3:	eb 5c                	jmp    102921 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  1028c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1028c8:	83 e0 03             	and    $0x3,%eax
  1028cb:	85 c0                	test   %eax,%eax
  1028cd:	75 41                	jne    102910 <memset+0x5d>
  1028cf:	8b 45 10             	mov    0x10(%ebp),%eax
  1028d2:	83 e0 03             	and    $0x3,%eax
  1028d5:	85 c0                	test   %eax,%eax
  1028d7:	75 37                	jne    102910 <memset+0x5d>
		c &= 0xFF;
  1028d9:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  1028e0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028e3:	89 c2                	mov    %eax,%edx
  1028e5:	c1 e2 18             	shl    $0x18,%edx
  1028e8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028eb:	c1 e0 10             	shl    $0x10,%eax
  1028ee:	09 c2                	or     %eax,%edx
  1028f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028f3:	c1 e0 08             	shl    $0x8,%eax
  1028f6:	09 d0                	or     %edx,%eax
  1028f8:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  1028fb:	8b 45 10             	mov    0x10(%ebp),%eax
  1028fe:	89 c1                	mov    %eax,%ecx
  102900:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  102903:	8b 55 08             	mov    0x8(%ebp),%edx
  102906:	8b 45 0c             	mov    0xc(%ebp),%eax
  102909:	89 d7                	mov    %edx,%edi
  10290b:	fc                   	cld    
  10290c:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  10290e:	eb 0e                	jmp    10291e <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  102910:	8b 55 08             	mov    0x8(%ebp),%edx
  102913:	8b 45 0c             	mov    0xc(%ebp),%eax
  102916:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102919:	89 d7                	mov    %edx,%edi
  10291b:	fc                   	cld    
  10291c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  10291e:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102921:	83 c4 10             	add    $0x10,%esp
  102924:	5f                   	pop    %edi
  102925:	5d                   	pop    %ebp
  102926:	c3                   	ret    

00102927 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  102927:	55                   	push   %ebp
  102928:	89 e5                	mov    %esp,%ebp
  10292a:	57                   	push   %edi
  10292b:	56                   	push   %esi
  10292c:	53                   	push   %ebx
  10292d:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  102930:	8b 45 0c             	mov    0xc(%ebp),%eax
  102933:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  102936:	8b 45 08             	mov    0x8(%ebp),%eax
  102939:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  10293c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10293f:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102942:	73 6e                	jae    1029b2 <memmove+0x8b>
  102944:	8b 45 10             	mov    0x10(%ebp),%eax
  102947:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10294a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10294d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102950:	76 60                	jbe    1029b2 <memmove+0x8b>
		s += n;
  102952:	8b 45 10             	mov    0x10(%ebp),%eax
  102955:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  102958:	8b 45 10             	mov    0x10(%ebp),%eax
  10295b:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10295e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102961:	83 e0 03             	and    $0x3,%eax
  102964:	85 c0                	test   %eax,%eax
  102966:	75 2f                	jne    102997 <memmove+0x70>
  102968:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10296b:	83 e0 03             	and    $0x3,%eax
  10296e:	85 c0                	test   %eax,%eax
  102970:	75 25                	jne    102997 <memmove+0x70>
  102972:	8b 45 10             	mov    0x10(%ebp),%eax
  102975:	83 e0 03             	and    $0x3,%eax
  102978:	85 c0                	test   %eax,%eax
  10297a:	75 1b                	jne    102997 <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  10297c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10297f:	83 e8 04             	sub    $0x4,%eax
  102982:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102985:	83 ea 04             	sub    $0x4,%edx
  102988:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10298b:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  10298e:	89 c7                	mov    %eax,%edi
  102990:	89 d6                	mov    %edx,%esi
  102992:	fd                   	std    
  102993:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102995:	eb 18                	jmp    1029af <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  102997:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10299a:	8d 50 ff             	lea    -0x1(%eax),%edx
  10299d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1029a0:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  1029a3:	8b 45 10             	mov    0x10(%ebp),%eax
  1029a6:	89 d7                	mov    %edx,%edi
  1029a8:	89 de                	mov    %ebx,%esi
  1029aa:	89 c1                	mov    %eax,%ecx
  1029ac:	fd                   	std    
  1029ad:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  1029af:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  1029b0:	eb 45                	jmp    1029f7 <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1029b2:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1029b5:	83 e0 03             	and    $0x3,%eax
  1029b8:	85 c0                	test   %eax,%eax
  1029ba:	75 2b                	jne    1029e7 <memmove+0xc0>
  1029bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1029bf:	83 e0 03             	and    $0x3,%eax
  1029c2:	85 c0                	test   %eax,%eax
  1029c4:	75 21                	jne    1029e7 <memmove+0xc0>
  1029c6:	8b 45 10             	mov    0x10(%ebp),%eax
  1029c9:	83 e0 03             	and    $0x3,%eax
  1029cc:	85 c0                	test   %eax,%eax
  1029ce:	75 17                	jne    1029e7 <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  1029d0:	8b 45 10             	mov    0x10(%ebp),%eax
  1029d3:	89 c1                	mov    %eax,%ecx
  1029d5:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  1029d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1029db:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1029de:	89 c7                	mov    %eax,%edi
  1029e0:	89 d6                	mov    %edx,%esi
  1029e2:	fc                   	cld    
  1029e3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1029e5:	eb 10                	jmp    1029f7 <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  1029e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1029ea:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1029ed:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1029f0:	89 c7                	mov    %eax,%edi
  1029f2:	89 d6                	mov    %edx,%esi
  1029f4:	fc                   	cld    
  1029f5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  1029f7:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1029fa:	83 c4 10             	add    $0x10,%esp
  1029fd:	5b                   	pop    %ebx
  1029fe:	5e                   	pop    %esi
  1029ff:	5f                   	pop    %edi
  102a00:	5d                   	pop    %ebp
  102a01:	c3                   	ret    

00102a02 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  102a02:	55                   	push   %ebp
  102a03:	89 e5                	mov    %esp,%ebp
  102a05:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  102a08:	8b 45 10             	mov    0x10(%ebp),%eax
  102a0b:	89 44 24 08          	mov    %eax,0x8(%esp)
  102a0f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a12:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a16:	8b 45 08             	mov    0x8(%ebp),%eax
  102a19:	89 04 24             	mov    %eax,(%esp)
  102a1c:	e8 06 ff ff ff       	call   102927 <memmove>
}
  102a21:	c9                   	leave  
  102a22:	c3                   	ret    

00102a23 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  102a23:	55                   	push   %ebp
  102a24:	89 e5                	mov    %esp,%ebp
  102a26:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  102a29:	8b 45 08             	mov    0x8(%ebp),%eax
  102a2c:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  102a2f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a32:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  102a35:	eb 32                	jmp    102a69 <memcmp+0x46>
		if (*s1 != *s2)
  102a37:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102a3a:	0f b6 10             	movzbl (%eax),%edx
  102a3d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102a40:	0f b6 00             	movzbl (%eax),%eax
  102a43:	38 c2                	cmp    %al,%dl
  102a45:	74 1a                	je     102a61 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  102a47:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102a4a:	0f b6 00             	movzbl (%eax),%eax
  102a4d:	0f b6 d0             	movzbl %al,%edx
  102a50:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102a53:	0f b6 00             	movzbl (%eax),%eax
  102a56:	0f b6 c0             	movzbl %al,%eax
  102a59:	89 d1                	mov    %edx,%ecx
  102a5b:	29 c1                	sub    %eax,%ecx
  102a5d:	89 c8                	mov    %ecx,%eax
  102a5f:	eb 1c                	jmp    102a7d <memcmp+0x5a>
		s1++, s2++;
  102a61:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  102a65:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  102a69:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102a6d:	0f 95 c0             	setne  %al
  102a70:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102a74:	84 c0                	test   %al,%al
  102a76:	75 bf                	jne    102a37 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  102a78:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102a7d:	c9                   	leave  
  102a7e:	c3                   	ret    

00102a7f <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  102a7f:	55                   	push   %ebp
  102a80:	89 e5                	mov    %esp,%ebp
  102a82:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  102a85:	8b 45 10             	mov    0x10(%ebp),%eax
  102a88:	8b 55 08             	mov    0x8(%ebp),%edx
  102a8b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102a8e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  102a91:	eb 16                	jmp    102aa9 <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  102a93:	8b 45 08             	mov    0x8(%ebp),%eax
  102a96:	0f b6 10             	movzbl (%eax),%edx
  102a99:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a9c:	38 c2                	cmp    %al,%dl
  102a9e:	75 05                	jne    102aa5 <memchr+0x26>
			return (void *) s;
  102aa0:	8b 45 08             	mov    0x8(%ebp),%eax
  102aa3:	eb 11                	jmp    102ab6 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  102aa5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102aa9:	8b 45 08             	mov    0x8(%ebp),%eax
  102aac:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  102aaf:	72 e2                	jb     102a93 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  102ab1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102ab6:	c9                   	leave  
  102ab7:	c3                   	ret    
  102ab8:	66 90                	xchg   %ax,%ax
  102aba:	66 90                	xchg   %ax,%ax
  102abc:	66 90                	xchg   %ax,%ax
  102abe:	66 90                	xchg   %ax,%ax

00102ac0 <__udivdi3>:
  102ac0:	55                   	push   %ebp
  102ac1:	89 e5                	mov    %esp,%ebp
  102ac3:	57                   	push   %edi
  102ac4:	56                   	push   %esi
  102ac5:	83 ec 10             	sub    $0x10,%esp
  102ac8:	8b 45 14             	mov    0x14(%ebp),%eax
  102acb:	8b 55 08             	mov    0x8(%ebp),%edx
  102ace:	8b 75 10             	mov    0x10(%ebp),%esi
  102ad1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  102ad4:	85 c0                	test   %eax,%eax
  102ad6:	89 55 f0             	mov    %edx,-0x10(%ebp)
  102ad9:	75 35                	jne    102b10 <__udivdi3+0x50>
  102adb:	39 fe                	cmp    %edi,%esi
  102add:	77 61                	ja     102b40 <__udivdi3+0x80>
  102adf:	85 f6                	test   %esi,%esi
  102ae1:	75 0b                	jne    102aee <__udivdi3+0x2e>
  102ae3:	b8 01 00 00 00       	mov    $0x1,%eax
  102ae8:	31 d2                	xor    %edx,%edx
  102aea:	f7 f6                	div    %esi
  102aec:	89 c6                	mov    %eax,%esi
  102aee:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  102af1:	31 d2                	xor    %edx,%edx
  102af3:	89 f8                	mov    %edi,%eax
  102af5:	f7 f6                	div    %esi
  102af7:	89 c7                	mov    %eax,%edi
  102af9:	89 c8                	mov    %ecx,%eax
  102afb:	f7 f6                	div    %esi
  102afd:	89 c1                	mov    %eax,%ecx
  102aff:	89 fa                	mov    %edi,%edx
  102b01:	89 c8                	mov    %ecx,%eax
  102b03:	83 c4 10             	add    $0x10,%esp
  102b06:	5e                   	pop    %esi
  102b07:	5f                   	pop    %edi
  102b08:	5d                   	pop    %ebp
  102b09:	c3                   	ret    
  102b0a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102b10:	39 f8                	cmp    %edi,%eax
  102b12:	77 1c                	ja     102b30 <__udivdi3+0x70>
  102b14:	0f bd d0             	bsr    %eax,%edx
  102b17:	83 f2 1f             	xor    $0x1f,%edx
  102b1a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102b1d:	75 39                	jne    102b58 <__udivdi3+0x98>
  102b1f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  102b22:	0f 86 a0 00 00 00    	jbe    102bc8 <__udivdi3+0x108>
  102b28:	39 f8                	cmp    %edi,%eax
  102b2a:	0f 82 98 00 00 00    	jb     102bc8 <__udivdi3+0x108>
  102b30:	31 ff                	xor    %edi,%edi
  102b32:	31 c9                	xor    %ecx,%ecx
  102b34:	89 c8                	mov    %ecx,%eax
  102b36:	89 fa                	mov    %edi,%edx
  102b38:	83 c4 10             	add    $0x10,%esp
  102b3b:	5e                   	pop    %esi
  102b3c:	5f                   	pop    %edi
  102b3d:	5d                   	pop    %ebp
  102b3e:	c3                   	ret    
  102b3f:	90                   	nop
  102b40:	89 d1                	mov    %edx,%ecx
  102b42:	89 fa                	mov    %edi,%edx
  102b44:	89 c8                	mov    %ecx,%eax
  102b46:	31 ff                	xor    %edi,%edi
  102b48:	f7 f6                	div    %esi
  102b4a:	89 c1                	mov    %eax,%ecx
  102b4c:	89 fa                	mov    %edi,%edx
  102b4e:	89 c8                	mov    %ecx,%eax
  102b50:	83 c4 10             	add    $0x10,%esp
  102b53:	5e                   	pop    %esi
  102b54:	5f                   	pop    %edi
  102b55:	5d                   	pop    %ebp
  102b56:	c3                   	ret    
  102b57:	90                   	nop
  102b58:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102b5c:	89 f2                	mov    %esi,%edx
  102b5e:	d3 e0                	shl    %cl,%eax
  102b60:	89 45 ec             	mov    %eax,-0x14(%ebp)
  102b63:	b8 20 00 00 00       	mov    $0x20,%eax
  102b68:	2b 45 f4             	sub    -0xc(%ebp),%eax
  102b6b:	89 c1                	mov    %eax,%ecx
  102b6d:	d3 ea                	shr    %cl,%edx
  102b6f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102b73:	0b 55 ec             	or     -0x14(%ebp),%edx
  102b76:	d3 e6                	shl    %cl,%esi
  102b78:	89 c1                	mov    %eax,%ecx
  102b7a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  102b7d:	89 fe                	mov    %edi,%esi
  102b7f:	d3 ee                	shr    %cl,%esi
  102b81:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102b85:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102b88:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102b8b:	d3 e7                	shl    %cl,%edi
  102b8d:	89 c1                	mov    %eax,%ecx
  102b8f:	d3 ea                	shr    %cl,%edx
  102b91:	09 d7                	or     %edx,%edi
  102b93:	89 f2                	mov    %esi,%edx
  102b95:	89 f8                	mov    %edi,%eax
  102b97:	f7 75 ec             	divl   -0x14(%ebp)
  102b9a:	89 d6                	mov    %edx,%esi
  102b9c:	89 c7                	mov    %eax,%edi
  102b9e:	f7 65 e8             	mull   -0x18(%ebp)
  102ba1:	39 d6                	cmp    %edx,%esi
  102ba3:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102ba6:	72 30                	jb     102bd8 <__udivdi3+0x118>
  102ba8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102bab:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102baf:	d3 e2                	shl    %cl,%edx
  102bb1:	39 c2                	cmp    %eax,%edx
  102bb3:	73 05                	jae    102bba <__udivdi3+0xfa>
  102bb5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  102bb8:	74 1e                	je     102bd8 <__udivdi3+0x118>
  102bba:	89 f9                	mov    %edi,%ecx
  102bbc:	31 ff                	xor    %edi,%edi
  102bbe:	e9 71 ff ff ff       	jmp    102b34 <__udivdi3+0x74>
  102bc3:	90                   	nop
  102bc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102bc8:	31 ff                	xor    %edi,%edi
  102bca:	b9 01 00 00 00       	mov    $0x1,%ecx
  102bcf:	e9 60 ff ff ff       	jmp    102b34 <__udivdi3+0x74>
  102bd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102bd8:	8d 4f ff             	lea    -0x1(%edi),%ecx
  102bdb:	31 ff                	xor    %edi,%edi
  102bdd:	89 c8                	mov    %ecx,%eax
  102bdf:	89 fa                	mov    %edi,%edx
  102be1:	83 c4 10             	add    $0x10,%esp
  102be4:	5e                   	pop    %esi
  102be5:	5f                   	pop    %edi
  102be6:	5d                   	pop    %ebp
  102be7:	c3                   	ret    
  102be8:	66 90                	xchg   %ax,%ax
  102bea:	66 90                	xchg   %ax,%ax
  102bec:	66 90                	xchg   %ax,%ax
  102bee:	66 90                	xchg   %ax,%ax

00102bf0 <__umoddi3>:
  102bf0:	55                   	push   %ebp
  102bf1:	89 e5                	mov    %esp,%ebp
  102bf3:	57                   	push   %edi
  102bf4:	56                   	push   %esi
  102bf5:	83 ec 20             	sub    $0x20,%esp
  102bf8:	8b 55 14             	mov    0x14(%ebp),%edx
  102bfb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102bfe:	8b 7d 10             	mov    0x10(%ebp),%edi
  102c01:	8b 75 0c             	mov    0xc(%ebp),%esi
  102c04:	85 d2                	test   %edx,%edx
  102c06:	89 c8                	mov    %ecx,%eax
  102c08:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  102c0b:	75 13                	jne    102c20 <__umoddi3+0x30>
  102c0d:	39 f7                	cmp    %esi,%edi
  102c0f:	76 3f                	jbe    102c50 <__umoddi3+0x60>
  102c11:	89 f2                	mov    %esi,%edx
  102c13:	f7 f7                	div    %edi
  102c15:	89 d0                	mov    %edx,%eax
  102c17:	31 d2                	xor    %edx,%edx
  102c19:	83 c4 20             	add    $0x20,%esp
  102c1c:	5e                   	pop    %esi
  102c1d:	5f                   	pop    %edi
  102c1e:	5d                   	pop    %ebp
  102c1f:	c3                   	ret    
  102c20:	39 f2                	cmp    %esi,%edx
  102c22:	77 4c                	ja     102c70 <__umoddi3+0x80>
  102c24:	0f bd ca             	bsr    %edx,%ecx
  102c27:	83 f1 1f             	xor    $0x1f,%ecx
  102c2a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  102c2d:	75 51                	jne    102c80 <__umoddi3+0x90>
  102c2f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  102c32:	0f 87 e0 00 00 00    	ja     102d18 <__umoddi3+0x128>
  102c38:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c3b:	29 f8                	sub    %edi,%eax
  102c3d:	19 d6                	sbb    %edx,%esi
  102c3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102c42:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c45:	89 f2                	mov    %esi,%edx
  102c47:	83 c4 20             	add    $0x20,%esp
  102c4a:	5e                   	pop    %esi
  102c4b:	5f                   	pop    %edi
  102c4c:	5d                   	pop    %ebp
  102c4d:	c3                   	ret    
  102c4e:	66 90                	xchg   %ax,%ax
  102c50:	85 ff                	test   %edi,%edi
  102c52:	75 0b                	jne    102c5f <__umoddi3+0x6f>
  102c54:	b8 01 00 00 00       	mov    $0x1,%eax
  102c59:	31 d2                	xor    %edx,%edx
  102c5b:	f7 f7                	div    %edi
  102c5d:	89 c7                	mov    %eax,%edi
  102c5f:	89 f0                	mov    %esi,%eax
  102c61:	31 d2                	xor    %edx,%edx
  102c63:	f7 f7                	div    %edi
  102c65:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c68:	f7 f7                	div    %edi
  102c6a:	eb a9                	jmp    102c15 <__umoddi3+0x25>
  102c6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102c70:	89 c8                	mov    %ecx,%eax
  102c72:	89 f2                	mov    %esi,%edx
  102c74:	83 c4 20             	add    $0x20,%esp
  102c77:	5e                   	pop    %esi
  102c78:	5f                   	pop    %edi
  102c79:	5d                   	pop    %ebp
  102c7a:	c3                   	ret    
  102c7b:	90                   	nop
  102c7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102c80:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102c84:	d3 e2                	shl    %cl,%edx
  102c86:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102c89:	ba 20 00 00 00       	mov    $0x20,%edx
  102c8e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  102c91:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102c94:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102c98:	89 fa                	mov    %edi,%edx
  102c9a:	d3 ea                	shr    %cl,%edx
  102c9c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102ca0:	0b 55 f4             	or     -0xc(%ebp),%edx
  102ca3:	d3 e7                	shl    %cl,%edi
  102ca5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102ca9:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102cac:	89 f2                	mov    %esi,%edx
  102cae:	89 7d e8             	mov    %edi,-0x18(%ebp)
  102cb1:	89 c7                	mov    %eax,%edi
  102cb3:	d3 ea                	shr    %cl,%edx
  102cb5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102cb9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  102cbc:	89 c2                	mov    %eax,%edx
  102cbe:	d3 e6                	shl    %cl,%esi
  102cc0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102cc4:	d3 ea                	shr    %cl,%edx
  102cc6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102cca:	09 d6                	or     %edx,%esi
  102ccc:	89 f0                	mov    %esi,%eax
  102cce:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  102cd1:	d3 e7                	shl    %cl,%edi
  102cd3:	89 f2                	mov    %esi,%edx
  102cd5:	f7 75 f4             	divl   -0xc(%ebp)
  102cd8:	89 d6                	mov    %edx,%esi
  102cda:	f7 65 e8             	mull   -0x18(%ebp)
  102cdd:	39 d6                	cmp    %edx,%esi
  102cdf:	72 2b                	jb     102d0c <__umoddi3+0x11c>
  102ce1:	39 c7                	cmp    %eax,%edi
  102ce3:	72 23                	jb     102d08 <__umoddi3+0x118>
  102ce5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102ce9:	29 c7                	sub    %eax,%edi
  102ceb:	19 d6                	sbb    %edx,%esi
  102ced:	89 f0                	mov    %esi,%eax
  102cef:	89 f2                	mov    %esi,%edx
  102cf1:	d3 ef                	shr    %cl,%edi
  102cf3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102cf7:	d3 e0                	shl    %cl,%eax
  102cf9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102cfd:	09 f8                	or     %edi,%eax
  102cff:	d3 ea                	shr    %cl,%edx
  102d01:	83 c4 20             	add    $0x20,%esp
  102d04:	5e                   	pop    %esi
  102d05:	5f                   	pop    %edi
  102d06:	5d                   	pop    %ebp
  102d07:	c3                   	ret    
  102d08:	39 d6                	cmp    %edx,%esi
  102d0a:	75 d9                	jne    102ce5 <__umoddi3+0xf5>
  102d0c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  102d0f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  102d12:	eb d1                	jmp    102ce5 <__umoddi3+0xf5>
  102d14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102d18:	39 f2                	cmp    %esi,%edx
  102d1a:	0f 82 18 ff ff ff    	jb     102c38 <__umoddi3+0x48>
  102d20:	e9 1d ff ff ff       	jmp    102c42 <__umoddi3+0x52>
