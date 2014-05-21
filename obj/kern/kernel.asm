
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
  100050:	c7 44 24 0c a0 2d 10 	movl   $0x102da0,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 b6 2d 10 	movl   $0x102db6,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 cb 2d 10 00 	movl   $0x102dcb,(%esp)
  10006f:	e8 10 03 00 00       	call   100384 <debug_panic>
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
  1000a2:	ba 04 70 10 00       	mov    $0x107004,%edx
  1000a7:	b8 b0 55 10 00       	mov    $0x1055b0,%eax
  1000ac:	89 d1                	mov    %edx,%ecx
  1000ae:	29 c1                	sub    %eax,%ecx
  1000b0:	89 c8                	mov    %ecx,%eax
  1000b2:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bd:	00 
  1000be:	c7 04 24 b0 55 10 00 	movl   $0x1055b0,(%esp)
  1000c5:	e8 43 28 00 00       	call   10290d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000ca:	e8 44 02 00 00       	call   100313 <cons_init>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  1000cf:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  1000d6:	00 
  1000d7:	c7 04 24 d8 2d 10 00 	movl   $0x102dd8,(%esp)
  1000de:	e8 45 26 00 00       	call   102728 <cprintf>
	debug_check();
  1000e3:	e8 07 05 00 00       	call   1005ef <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000e8:	e8 66 0e 00 00       	call   100f53 <cpu_init>
	trap_init();
  1000ed:	e8 43 11 00 00       	call   101235 <trap_init>

	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.

	cprintf("before tt\n");
  1000f2:	c7 04 24 f3 2d 10 00 	movl   $0x102df3,(%esp)
  1000f9:	e8 2a 26 00 00       	call   102728 <cprintf>
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
	};
  1000fe:	8d 5d ac             	lea    -0x54(%ebp),%ebx
  100101:	b8 00 00 00 00       	mov    $0x0,%eax
  100106:	ba 13 00 00 00       	mov    $0x13,%edx
  10010b:	89 df                	mov    %ebx,%edi
  10010d:	89 d1                	mov    %edx,%ecx
  10010f:	f3 ab                	rep stos %eax,%es:(%edi)
  100111:	66 c7 45 cc 23 00    	movw   $0x23,-0x34(%ebp)
  100117:	66 c7 45 d0 23 00    	movw   $0x23,-0x30(%ebp)
  10011d:	66 c7 45 d4 23 00    	movw   $0x23,-0x2c(%ebp)
  100123:	66 c7 45 d8 23 00    	movw   $0x23,-0x28(%ebp)

	cprintf("before tt\n");

	trapframe tt = {
		cs: CPU_GDT_UCODE | 3,
		eip: (uint32_t)(user),
  100129:	b8 57 01 10 00       	mov    $0x100157,%eax
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
	};
  10012e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100131:	66 c7 45 e8 1b 00    	movw   $0x1b,-0x18(%ebp)
  100137:	c7 45 ec 00 30 00 00 	movl   $0x3000,-0x14(%ebp)
		fs: CPU_GDT_UDATA | 3,
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		
		ss: CPU_GDT_UDATA | 3,
		esp: (uint32_t)&user_stack[PAGESIZE],	
  10013e:	b8 c0 65 10 00       	mov    $0x1065c0,%eax
	};
  100143:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100146:	66 c7 45 f4 23 00    	movw   $0x23,-0xc(%ebp)
	
	trap_return(&tt);
  10014c:	8d 45 ac             	lea    -0x54(%ebp),%eax
  10014f:	89 04 24             	mov    %eax,(%esp)
  100152:	e8 29 4f 00 00       	call   105080 <trap_return>

00100157 <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  100157:	55                   	push   %ebp
  100158:	89 e5                	mov    %esp,%ebp
  10015a:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  10015d:	c7 04 24 fe 2d 10 00 	movl   $0x102dfe,(%esp)
  100164:	e8 bf 25 00 00       	call   102728 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100169:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  10016c:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  10016f:	89 c2                	mov    %eax,%edx
  100171:	b8 c0 55 10 00       	mov    $0x1055c0,%eax
  100176:	39 c2                	cmp    %eax,%edx
  100178:	77 24                	ja     10019e <user+0x47>
  10017a:	c7 44 24 0c 0c 2e 10 	movl   $0x102e0c,0xc(%esp)
  100181:	00 
  100182:	c7 44 24 08 b6 2d 10 	movl   $0x102db6,0x8(%esp)
  100189:	00 
  10018a:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  100191:	00 
  100192:	c7 04 24 33 2e 10 00 	movl   $0x102e33,(%esp)
  100199:	e8 e6 01 00 00       	call   100384 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10019e:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1001a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  1001a4:	89 c2                	mov    %eax,%edx
  1001a6:	b8 c0 65 10 00       	mov    $0x1065c0,%eax
  1001ab:	39 c2                	cmp    %eax,%edx
  1001ad:	72 24                	jb     1001d3 <user+0x7c>
  1001af:	c7 44 24 0c 40 2e 10 	movl   $0x102e40,0xc(%esp)
  1001b6:	00 
  1001b7:	c7 44 24 08 b6 2d 10 	movl   $0x102db6,0x8(%esp)
  1001be:	00 
  1001bf:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1001c6:	00 
  1001c7:	c7 04 24 33 2e 10 00 	movl   $0x102e33,(%esp)
  1001ce:	e8 b1 01 00 00       	call   100384 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  1001d3:	e8 63 13 00 00       	call   10153b <trap_check_user>

	done();
  1001d8:	e8 00 00 00 00       	call   1001dd <done>

001001dd <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  1001dd:	55                   	push   %ebp
  1001de:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  1001e0:	eb fe                	jmp    1001e0 <done+0x3>

001001e2 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1001e2:	55                   	push   %ebp
  1001e3:	89 e5                	mov    %esp,%ebp
  1001e5:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001e8:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1001eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1001ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1001f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1001f4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1001f9:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1001fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1001ff:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100205:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10020a:	74 24                	je     100230 <cpu_cur+0x4e>
  10020c:	c7 44 24 0c 78 2e 10 	movl   $0x102e78,0xc(%esp)
  100213:	00 
  100214:	c7 44 24 08 8e 2e 10 	movl   $0x102e8e,0x8(%esp)
  10021b:	00 
  10021c:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100223:	00 
  100224:	c7 04 24 a3 2e 10 00 	movl   $0x102ea3,(%esp)
  10022b:	e8 54 01 00 00       	call   100384 <debug_panic>
	return c;
  100230:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100233:	c9                   	leave  
  100234:	c3                   	ret    

00100235 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100235:	55                   	push   %ebp
  100236:	89 e5                	mov    %esp,%ebp
  100238:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10023b:	e8 a2 ff ff ff       	call   1001e2 <cpu_cur>
  100240:	3d 00 40 10 00       	cmp    $0x104000,%eax
  100245:	0f 94 c0             	sete   %al
  100248:	0f b6 c0             	movzbl %al,%eax
}
  10024b:	c9                   	leave  
  10024c:	c3                   	ret    

0010024d <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  10024d:	55                   	push   %ebp
  10024e:	89 e5                	mov    %esp,%ebp
  100250:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
  100253:	eb 35                	jmp    10028a <cons_intr+0x3d>
		if (c == 0)
  100255:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100259:	74 2e                	je     100289 <cons_intr+0x3c>
			continue;
		cons.buf[cons.wpos++] = c;
  10025b:	a1 c4 67 10 00       	mov    0x1067c4,%eax
  100260:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100263:	88 90 c0 65 10 00    	mov    %dl,0x1065c0(%eax)
  100269:	83 c0 01             	add    $0x1,%eax
  10026c:	a3 c4 67 10 00       	mov    %eax,0x1067c4
		if (cons.wpos == CONSBUFSIZE)
  100271:	a1 c4 67 10 00       	mov    0x1067c4,%eax
  100276:	3d 00 02 00 00       	cmp    $0x200,%eax
  10027b:	75 0d                	jne    10028a <cons_intr+0x3d>
			cons.wpos = 0;
  10027d:	c7 05 c4 67 10 00 00 	movl   $0x0,0x1067c4
  100284:	00 00 00 
  100287:	eb 01                	jmp    10028a <cons_intr+0x3d>
{
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  100289:	90                   	nop
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
  10028a:	8b 45 08             	mov    0x8(%ebp),%eax
  10028d:	ff d0                	call   *%eax
  10028f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100292:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  100296:	75 bd                	jne    100255 <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
  100298:	c9                   	leave  
  100299:	c3                   	ret    

0010029a <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  10029a:	55                   	push   %ebp
  10029b:	89 e5                	mov    %esp,%ebp
  10029d:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  1002a0:	e8 16 1b 00 00       	call   101dbb <serial_intr>
	kbd_intr();
  1002a5:	e8 6c 1a 00 00       	call   101d16 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  1002aa:	8b 15 c0 67 10 00    	mov    0x1067c0,%edx
  1002b0:	a1 c4 67 10 00       	mov    0x1067c4,%eax
  1002b5:	39 c2                	cmp    %eax,%edx
  1002b7:	74 35                	je     1002ee <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  1002b9:	a1 c0 67 10 00       	mov    0x1067c0,%eax
  1002be:	0f b6 90 c0 65 10 00 	movzbl 0x1065c0(%eax),%edx
  1002c5:	0f b6 d2             	movzbl %dl,%edx
  1002c8:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1002cb:	83 c0 01             	add    $0x1,%eax
  1002ce:	a3 c0 67 10 00       	mov    %eax,0x1067c0
		if (cons.rpos == CONSBUFSIZE)
  1002d3:	a1 c0 67 10 00       	mov    0x1067c0,%eax
  1002d8:	3d 00 02 00 00       	cmp    $0x200,%eax
  1002dd:	75 0a                	jne    1002e9 <cons_getc+0x4f>
			cons.rpos = 0;
  1002df:	c7 05 c0 67 10 00 00 	movl   $0x0,0x1067c0
  1002e6:	00 00 00 
		return c;
  1002e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1002ec:	eb 05                	jmp    1002f3 <cons_getc+0x59>
	}
	return 0;
  1002ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1002f3:	c9                   	leave  
  1002f4:	c3                   	ret    

001002f5 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  1002f5:	55                   	push   %ebp
  1002f6:	89 e5                	mov    %esp,%ebp
  1002f8:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  1002fb:	8b 45 08             	mov    0x8(%ebp),%eax
  1002fe:	89 04 24             	mov    %eax,(%esp)
  100301:	e8 d2 1a 00 00       	call   101dd8 <serial_putc>
	video_putc(c);
  100306:	8b 45 08             	mov    0x8(%ebp),%eax
  100309:	89 04 24             	mov    %eax,(%esp)
  10030c:	e8 64 16 00 00       	call   101975 <video_putc>
}
  100311:	c9                   	leave  
  100312:	c3                   	ret    

00100313 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100313:	55                   	push   %ebp
  100314:	89 e5                	mov    %esp,%ebp
  100316:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100319:	e8 17 ff ff ff       	call   100235 <cpu_onboot>
  10031e:	85 c0                	test   %eax,%eax
  100320:	74 36                	je     100358 <cons_init+0x45>
		return;

	video_init();
  100322:	e8 82 15 00 00       	call   1018a9 <video_init>
	kbd_init();
  100327:	e8 fe 19 00 00       	call   101d2a <kbd_init>
	serial_init();
  10032c:	e8 0c 1b 00 00       	call   101e3d <serial_init>

	if (!serial_exists)
  100331:	a1 00 70 10 00       	mov    0x107000,%eax
  100336:	85 c0                	test   %eax,%eax
  100338:	75 1f                	jne    100359 <cons_init+0x46>
		warn("Serial port does not exist!\n");
  10033a:	c7 44 24 08 b0 2e 10 	movl   $0x102eb0,0x8(%esp)
  100341:	00 
  100342:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  100349:	00 
  10034a:	c7 04 24 cd 2e 10 00 	movl   $0x102ecd,(%esp)
  100351:	e8 ed 00 00 00       	call   100443 <debug_warn>
  100356:	eb 01                	jmp    100359 <cons_init+0x46>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100358:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  100359:	c9                   	leave  
  10035a:	c3                   	ret    

0010035b <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  10035b:	55                   	push   %ebp
  10035c:	89 e5                	mov    %esp,%ebp
  10035e:	83 ec 28             	sub    $0x28,%esp
	char ch;
	while (*str)
  100361:	eb 15                	jmp    100378 <cputs+0x1d>
		cons_putc(*str++);
  100363:	8b 45 08             	mov    0x8(%ebp),%eax
  100366:	0f b6 00             	movzbl (%eax),%eax
  100369:	0f be c0             	movsbl %al,%eax
  10036c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100370:	89 04 24             	mov    %eax,(%esp)
  100373:	e8 7d ff ff ff       	call   1002f5 <cons_putc>
// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
	char ch;
	while (*str)
  100378:	8b 45 08             	mov    0x8(%ebp),%eax
  10037b:	0f b6 00             	movzbl (%eax),%eax
  10037e:	84 c0                	test   %al,%al
  100380:	75 e1                	jne    100363 <cputs+0x8>
		cons_putc(*str++);
}
  100382:	c9                   	leave  
  100383:	c3                   	ret    

00100384 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100384:	55                   	push   %ebp
  100385:	89 e5                	mov    %esp,%ebp
  100387:	83 ec 58             	sub    $0x58,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10038a:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  10038d:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  100391:	0f b7 c0             	movzwl %ax,%eax
  100394:	83 e0 03             	and    $0x3,%eax
  100397:	85 c0                	test   %eax,%eax
  100399:	75 15                	jne    1003b0 <debug_panic+0x2c>
		if (panicstr)
  10039b:	a1 c8 67 10 00       	mov    0x1067c8,%eax
  1003a0:	85 c0                	test   %eax,%eax
  1003a2:	0f 85 95 00 00 00    	jne    10043d <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  1003a8:	8b 45 10             	mov    0x10(%ebp),%eax
  1003ab:	a3 c8 67 10 00       	mov    %eax,0x1067c8
	}

	// First print the requested message
	va_start(ap, fmt);
  1003b0:	8d 45 10             	lea    0x10(%ebp),%eax
  1003b3:	83 c0 04             	add    $0x4,%eax
  1003b6:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  1003b9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1003bc:	89 44 24 08          	mov    %eax,0x8(%esp)
  1003c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1003c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003c7:	c7 04 24 d9 2e 10 00 	movl   $0x102ed9,(%esp)
  1003ce:	e8 55 23 00 00       	call   102728 <cprintf>
	vcprintf(fmt, ap);
  1003d3:	8b 45 10             	mov    0x10(%ebp),%eax
  1003d6:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1003d9:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003dd:	89 04 24             	mov    %eax,(%esp)
  1003e0:	e8 da 22 00 00       	call   1026bf <vcprintf>
	cprintf("\n");
  1003e5:	c7 04 24 f1 2e 10 00 	movl   $0x102ef1,(%esp)
  1003ec:	e8 37 23 00 00       	call   102728 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1003f1:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  1003f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1003f7:	8d 55 c0             	lea    -0x40(%ebp),%edx
  1003fa:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003fe:	89 04 24             	mov    %eax,(%esp)
  100401:	e8 86 00 00 00       	call   10048c <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  100406:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  10040d:	eb 1b                	jmp    10042a <debug_panic+0xa6>
		cprintf("  from %08x\n", eips[i]);
  10040f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100412:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  100416:	89 44 24 04          	mov    %eax,0x4(%esp)
  10041a:	c7 04 24 f3 2e 10 00 	movl   $0x102ef3,(%esp)
  100421:	e8 02 23 00 00       	call   102728 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  100426:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  10042a:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  10042e:	7f 0e                	jg     10043e <debug_panic+0xba>
  100430:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100433:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  100437:	85 c0                	test   %eax,%eax
  100439:	75 d4                	jne    10040f <debug_panic+0x8b>
  10043b:	eb 01                	jmp    10043e <debug_panic+0xba>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  10043d:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  10043e:	e8 9a fd ff ff       	call   1001dd <done>

00100443 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  100443:	55                   	push   %ebp
  100444:	89 e5                	mov    %esp,%ebp
  100446:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  100449:	8d 45 10             	lea    0x10(%ebp),%eax
  10044c:	83 c0 04             	add    $0x4,%eax
  10044f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100452:	8b 45 0c             	mov    0xc(%ebp),%eax
  100455:	89 44 24 08          	mov    %eax,0x8(%esp)
  100459:	8b 45 08             	mov    0x8(%ebp),%eax
  10045c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100460:	c7 04 24 00 2f 10 00 	movl   $0x102f00,(%esp)
  100467:	e8 bc 22 00 00       	call   102728 <cprintf>
	vcprintf(fmt, ap);
  10046c:	8b 45 10             	mov    0x10(%ebp),%eax
  10046f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100472:	89 54 24 04          	mov    %edx,0x4(%esp)
  100476:	89 04 24             	mov    %eax,(%esp)
  100479:	e8 41 22 00 00       	call   1026bf <vcprintf>
	cprintf("\n");
  10047e:	c7 04 24 f1 2e 10 00 	movl   $0x102ef1,(%esp)
  100485:	e8 9e 22 00 00       	call   102728 <cprintf>
	va_end(ap);
}
  10048a:	c9                   	leave  
  10048b:	c3                   	ret    

0010048c <debug_trace>:

// Riecord the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  10048c:	55                   	push   %ebp
  10048d:	89 e5                	mov    %esp,%ebp
  10048f:	83 ec 28             	sub    $0x28,%esp
	uint32_t* ebp_addr;
	uint32_t eip;

	ebp_addr = (uint32_t*) ebp;
  100492:	8b 45 08             	mov    0x8(%ebp),%eax
  100495:	89 45 e8             	mov    %eax,-0x18(%ebp)

	int x = 0;
  100498:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	cprintf("Stack backtrace:\n");
  10049f:	c7 04 24 1a 2f 10 00 	movl   $0x102f1a,(%esp)
  1004a6:	e8 7d 22 00 00       	call   102728 <cprintf>

	while(*ebp_addr >= 0)
	{

		eip = ebp_addr[1];
  1004ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1004ae:	83 c0 04             	add    $0x4,%eax
  1004b1:	8b 00                	mov    (%eax),%eax
  1004b3:	89 45 ec             	mov    %eax,-0x14(%ebp)
		eips[x++] = eip;
  1004b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004b9:	c1 e0 02             	shl    $0x2,%eax
  1004bc:	03 45 0c             	add    0xc(%ebp),%eax
  1004bf:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1004c2:	89 10                	mov    %edx,(%eax)
  1004c4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)

		cprintf("ebp 0x%08x eip 0x%08x", *ebp_addr, eip);
  1004c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1004cb:	8b 00                	mov    (%eax),%eax
  1004cd:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1004d0:	89 54 24 08          	mov    %edx,0x8(%esp)
  1004d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004d8:	c7 04 24 2c 2f 10 00 	movl   $0x102f2c,(%esp)
  1004df:	e8 44 22 00 00       	call   102728 <cprintf>

		int y = 0;
  1004e4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

		cprintf(" args");
  1004eb:	c7 04 24 42 2f 10 00 	movl   $0x102f42,(%esp)
  1004f2:	e8 31 22 00 00       	call   102728 <cprintf>

		for(; y < 5; y++)
  1004f7:	eb 22                	jmp    10051b <debug_trace+0x8f>
		{
			cprintf(" %08x", ebp_addr[2 + y]);
  1004f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004fc:	83 c0 02             	add    $0x2,%eax
  1004ff:	c1 e0 02             	shl    $0x2,%eax
  100502:	03 45 e8             	add    -0x18(%ebp),%eax
  100505:	8b 00                	mov    (%eax),%eax
  100507:	89 44 24 04          	mov    %eax,0x4(%esp)
  10050b:	c7 04 24 48 2f 10 00 	movl   $0x102f48,(%esp)
  100512:	e8 11 22 00 00       	call   102728 <cprintf>

		int y = 0;

		cprintf(" args");

		for(; y < 5; y++)
  100517:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10051b:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  10051f:	7e d8                	jle    1004f9 <debug_trace+0x6d>
		{
			cprintf(" %08x", ebp_addr[2 + y]);
		}

		cprintf("\n");
  100521:	c7 04 24 f1 2e 10 00 	movl   $0x102ef1,(%esp)
  100528:	e8 fb 21 00 00       	call   102728 <cprintf>

		if(*ebp_addr == 0)
  10052d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100530:	8b 00                	mov    (%eax),%eax
  100532:	85 c0                	test   %eax,%eax
  100534:	75 1d                	jne    100553 <debug_trace+0xc7>
		{
			for(; x < 10; x++)
  100536:	eb 13                	jmp    10054b <debug_trace+0xbf>
				eips[x] = 0;
  100538:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10053b:	c1 e0 02             	shl    $0x2,%eax
  10053e:	03 45 0c             	add    0xc(%ebp),%eax
  100541:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

		cprintf("\n");

		if(*ebp_addr == 0)
		{
			for(; x < 10; x++)
  100547:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10054b:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  10054f:	7e e7                	jle    100538 <debug_trace+0xac>
  100551:	eb 0d                	jmp    100560 <debug_trace+0xd4>
				eips[x] = 0;
			break;
		}

		ebp_addr = (uint32_t*) (*ebp_addr);
  100553:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100556:	8b 00                	mov    (%eax),%eax
  100558:	89 45 e8             	mov    %eax,-0x18(%ebp)
	}
  10055b:	e9 4b ff ff ff       	jmp    1004ab <debug_trace+0x1f>

	return;
	//panic("debug_trace not implemented");
}
  100560:	c9                   	leave  
  100561:	c3                   	ret    

00100562 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100562:	55                   	push   %ebp
  100563:	89 e5                	mov    %esp,%ebp
  100565:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100568:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  10056b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10056e:	8b 55 0c             	mov    0xc(%ebp),%edx
  100571:	89 54 24 04          	mov    %edx,0x4(%esp)
  100575:	89 04 24             	mov    %eax,(%esp)
  100578:	e8 0f ff ff ff       	call   10048c <debug_trace>
  10057d:	c9                   	leave  
  10057e:	c3                   	ret    

0010057f <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  10057f:	55                   	push   %ebp
  100580:	89 e5                	mov    %esp,%ebp
  100582:	83 ec 18             	sub    $0x18,%esp
  100585:	8b 45 08             	mov    0x8(%ebp),%eax
  100588:	83 e0 02             	and    $0x2,%eax
  10058b:	85 c0                	test   %eax,%eax
  10058d:	74 14                	je     1005a3 <f2+0x24>
  10058f:	8b 45 0c             	mov    0xc(%ebp),%eax
  100592:	89 44 24 04          	mov    %eax,0x4(%esp)
  100596:	8b 45 08             	mov    0x8(%ebp),%eax
  100599:	89 04 24             	mov    %eax,(%esp)
  10059c:	e8 c1 ff ff ff       	call   100562 <f3>
  1005a1:	eb 12                	jmp    1005b5 <f2+0x36>
  1005a3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005a6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005aa:	8b 45 08             	mov    0x8(%ebp),%eax
  1005ad:	89 04 24             	mov    %eax,(%esp)
  1005b0:	e8 ad ff ff ff       	call   100562 <f3>
  1005b5:	c9                   	leave  
  1005b6:	c3                   	ret    

001005b7 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  1005b7:	55                   	push   %ebp
  1005b8:	89 e5                	mov    %esp,%ebp
  1005ba:	83 ec 18             	sub    $0x18,%esp
  1005bd:	8b 45 08             	mov    0x8(%ebp),%eax
  1005c0:	83 e0 01             	and    $0x1,%eax
  1005c3:	84 c0                	test   %al,%al
  1005c5:	74 14                	je     1005db <f1+0x24>
  1005c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1005d1:	89 04 24             	mov    %eax,(%esp)
  1005d4:	e8 a6 ff ff ff       	call   10057f <f2>
  1005d9:	eb 12                	jmp    1005ed <f1+0x36>
  1005db:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1005e5:	89 04 24             	mov    %eax,(%esp)
  1005e8:	e8 92 ff ff ff       	call   10057f <f2>
  1005ed:	c9                   	leave  
  1005ee:	c3                   	ret    

001005ef <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  1005ef:	55                   	push   %ebp
  1005f0:	89 e5                	mov    %esp,%ebp
  1005f2:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1005f8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1005ff:	eb 29                	jmp    10062a <debug_check+0x3b>
		f1(i, eips[i]);
  100601:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  100607:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10060a:	89 d0                	mov    %edx,%eax
  10060c:	c1 e0 02             	shl    $0x2,%eax
  10060f:	01 d0                	add    %edx,%eax
  100611:	c1 e0 03             	shl    $0x3,%eax
  100614:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  100617:	89 44 24 04          	mov    %eax,0x4(%esp)
  10061b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10061e:	89 04 24             	mov    %eax,(%esp)
  100621:	e8 91 ff ff ff       	call   1005b7 <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100626:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10062a:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  10062e:	7e d1                	jle    100601 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100630:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100637:	e9 bc 00 00 00       	jmp    1006f8 <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  10063c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100643:	e9 a2 00 00 00       	jmp    1006ea <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  100648:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10064b:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  10064e:	89 d0                	mov    %edx,%eax
  100650:	c1 e0 02             	shl    $0x2,%eax
  100653:	01 d0                	add    %edx,%eax
  100655:	01 c0                	add    %eax,%eax
  100657:	01 c8                	add    %ecx,%eax
  100659:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100660:	85 c0                	test   %eax,%eax
  100662:	0f 95 c2             	setne  %dl
  100665:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  100669:	0f 9e c0             	setle  %al
  10066c:	31 d0                	xor    %edx,%eax
  10066e:	84 c0                	test   %al,%al
  100670:	74 24                	je     100696 <debug_check+0xa7>
  100672:	c7 44 24 0c 4e 2f 10 	movl   $0x102f4e,0xc(%esp)
  100679:	00 
  10067a:	c7 44 24 08 6b 2f 10 	movl   $0x102f6b,0x8(%esp)
  100681:	00 
  100682:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
  100689:	00 
  10068a:	c7 04 24 80 2f 10 00 	movl   $0x102f80,(%esp)
  100691:	e8 ee fc ff ff       	call   100384 <debug_panic>
			if (i >= 2)
  100696:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  10069a:	7e 4a                	jle    1006e6 <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  10069c:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10069f:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  1006a2:	89 d0                	mov    %edx,%eax
  1006a4:	c1 e0 02             	shl    $0x2,%eax
  1006a7:	01 d0                	add    %edx,%eax
  1006a9:	01 c0                	add    %eax,%eax
  1006ab:	01 c8                	add    %ecx,%eax
  1006ad:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  1006b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006b7:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  1006be:	39 c2                	cmp    %eax,%edx
  1006c0:	74 24                	je     1006e6 <debug_check+0xf7>
  1006c2:	c7 44 24 0c 8d 2f 10 	movl   $0x102f8d,0xc(%esp)
  1006c9:	00 
  1006ca:	c7 44 24 08 6b 2f 10 	movl   $0x102f6b,0x8(%esp)
  1006d1:	00 
  1006d2:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  1006d9:	00 
  1006da:	c7 04 24 80 2f 10 00 	movl   $0x102f80,(%esp)
  1006e1:	e8 9e fc ff ff       	call   100384 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1006e6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1006ea:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1006ee:	0f 8e 54 ff ff ff    	jle    100648 <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1006f4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1006f8:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  1006fc:	0f 8e 3a ff ff ff    	jle    10063c <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  100702:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  100708:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  10070e:	39 c2                	cmp    %eax,%edx
  100710:	74 24                	je     100736 <debug_check+0x147>
  100712:	c7 44 24 0c a6 2f 10 	movl   $0x102fa6,0xc(%esp)
  100719:	00 
  10071a:	c7 44 24 08 6b 2f 10 	movl   $0x102f6b,0x8(%esp)
  100721:	00 
  100722:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
  100729:	00 
  10072a:	c7 04 24 80 2f 10 00 	movl   $0x102f80,(%esp)
  100731:	e8 4e fc ff ff       	call   100384 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100736:	8b 55 a0             	mov    -0x60(%ebp),%edx
  100739:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10073c:	39 c2                	cmp    %eax,%edx
  10073e:	74 24                	je     100764 <debug_check+0x175>
  100740:	c7 44 24 0c bf 2f 10 	movl   $0x102fbf,0xc(%esp)
  100747:	00 
  100748:	c7 44 24 08 6b 2f 10 	movl   $0x102f6b,0x8(%esp)
  10074f:	00 
  100750:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  100757:	00 
  100758:	c7 04 24 80 2f 10 00 	movl   $0x102f80,(%esp)
  10075f:	e8 20 fc ff ff       	call   100384 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100764:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  10076a:	8b 45 a0             	mov    -0x60(%ebp),%eax
  10076d:	39 c2                	cmp    %eax,%edx
  10076f:	75 24                	jne    100795 <debug_check+0x1a6>
  100771:	c7 44 24 0c d8 2f 10 	movl   $0x102fd8,0xc(%esp)
  100778:	00 
  100779:	c7 44 24 08 6b 2f 10 	movl   $0x102f6b,0x8(%esp)
  100780:	00 
  100781:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  100788:	00 
  100789:	c7 04 24 80 2f 10 00 	movl   $0x102f80,(%esp)
  100790:	e8 ef fb ff ff       	call   100384 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100795:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  10079b:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  10079e:	39 c2                	cmp    %eax,%edx
  1007a0:	74 24                	je     1007c6 <debug_check+0x1d7>
  1007a2:	c7 44 24 0c f1 2f 10 	movl   $0x102ff1,0xc(%esp)
  1007a9:	00 
  1007aa:	c7 44 24 08 6b 2f 10 	movl   $0x102f6b,0x8(%esp)
  1007b1:	00 
  1007b2:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  1007b9:	00 
  1007ba:	c7 04 24 80 2f 10 00 	movl   $0x102f80,(%esp)
  1007c1:	e8 be fb ff ff       	call   100384 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  1007c6:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  1007cc:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1007cf:	39 c2                	cmp    %eax,%edx
  1007d1:	74 24                	je     1007f7 <debug_check+0x208>
  1007d3:	c7 44 24 0c 0a 30 10 	movl   $0x10300a,0xc(%esp)
  1007da:	00 
  1007db:	c7 44 24 08 6b 2f 10 	movl   $0x102f6b,0x8(%esp)
  1007e2:	00 
  1007e3:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  1007ea:	00 
  1007eb:	c7 04 24 80 2f 10 00 	movl   $0x102f80,(%esp)
  1007f2:	e8 8d fb ff ff       	call   100384 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  1007f7:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1007fd:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  100803:	39 c2                	cmp    %eax,%edx
  100805:	75 24                	jne    10082b <debug_check+0x23c>
  100807:	c7 44 24 0c 23 30 10 	movl   $0x103023,0xc(%esp)
  10080e:	00 
  10080f:	c7 44 24 08 6b 2f 10 	movl   $0x102f6b,0x8(%esp)
  100816:	00 
  100817:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  10081e:	00 
  10081f:	c7 04 24 80 2f 10 00 	movl   $0x102f80,(%esp)
  100826:	e8 59 fb ff ff       	call   100384 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  10082b:	c7 04 24 3c 30 10 00 	movl   $0x10303c,(%esp)
  100832:	e8 f1 1e 00 00       	call   102728 <cprintf>
}
  100837:	c9                   	leave  
  100838:	c3                   	ret    

00100839 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100839:	55                   	push   %ebp
  10083a:	89 e5                	mov    %esp,%ebp
  10083c:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10083f:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100842:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100845:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100848:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10084b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100850:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100853:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100856:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  10085c:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100861:	74 24                	je     100887 <cpu_cur+0x4e>
  100863:	c7 44 24 0c 58 30 10 	movl   $0x103058,0xc(%esp)
  10086a:	00 
  10086b:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100872:	00 
  100873:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10087a:	00 
  10087b:	c7 04 24 83 30 10 00 	movl   $0x103083,(%esp)
  100882:	e8 fd fa ff ff       	call   100384 <debug_panic>
	return c;
  100887:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10088a:	c9                   	leave  
  10088b:	c3                   	ret    

0010088c <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10088c:	55                   	push   %ebp
  10088d:	89 e5                	mov    %esp,%ebp
  10088f:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100892:	e8 a2 ff ff ff       	call   100839 <cpu_cur>
  100897:	3d 00 40 10 00       	cmp    $0x104000,%eax
  10089c:	0f 94 c0             	sete   %al
  10089f:	0f b6 c0             	movzbl %al,%eax
}
  1008a2:	c9                   	leave  
  1008a3:	c3                   	ret    

001008a4 <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  1008a4:	55                   	push   %ebp
  1008a5:	89 e5                	mov    %esp,%ebp
  1008a7:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1008aa:	e8 dd ff ff ff       	call   10088c <cpu_onboot>
  1008af:	85 c0                	test   %eax,%eax
  1008b1:	0f 84 2d 01 00 00    	je     1009e4 <mem_init+0x140>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  1008b7:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  1008be:	e8 7f 16 00 00       	call   101f42 <nvram_read16>
  1008c3:	c1 e0 0a             	shl    $0xa,%eax
  1008c6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1008c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1008cc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008d1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  1008d4:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  1008db:	e8 62 16 00 00       	call   101f42 <nvram_read16>
  1008e0:	c1 e0 0a             	shl    $0xa,%eax
  1008e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1008e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1008e9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	warn("Assuming we have 1GB of memory!");
  1008f1:	c7 44 24 08 90 30 10 	movl   $0x103090,0x8(%esp)
  1008f8:	00 
  1008f9:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  100900:	00 
  100901:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100908:	e8 36 fb ff ff       	call   100443 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  10090d:	c7 45 e4 00 00 f0 3f 	movl   $0x3ff00000,-0x1c(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100914:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100917:	05 00 00 10 00       	add    $0x100000,%eax
  10091c:	a3 f8 6f 10 00       	mov    %eax,0x106ff8

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100921:	a1 f8 6f 10 00       	mov    0x106ff8,%eax
  100926:	c1 e8 0c             	shr    $0xc,%eax
  100929:	a3 f4 6f 10 00       	mov    %eax,0x106ff4

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  10092e:	a1 f8 6f 10 00       	mov    0x106ff8,%eax
  100933:	c1 e8 0a             	shr    $0xa,%eax
  100936:	89 44 24 04          	mov    %eax,0x4(%esp)
  10093a:	c7 04 24 bc 30 10 00 	movl   $0x1030bc,(%esp)
  100941:	e8 e2 1d 00 00       	call   102728 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  100946:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100949:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  10094c:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  10094e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100951:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100954:	89 54 24 08          	mov    %edx,0x8(%esp)
  100958:	89 44 24 04          	mov    %eax,0x4(%esp)
  10095c:	c7 04 24 dd 30 10 00 	movl   $0x1030dd,(%esp)
  100963:	e8 c0 1d 00 00       	call   102728 <cprintf>
	//     Some of it is in use, some is free.
	//     Which pages hold the kernel and the pageinfo array?
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
  100968:	c7 45 e8 f0 6f 10 00 	movl   $0x106ff0,-0x18(%ebp)
	int i;
	for (i = 0; i < mem_npage; i++) {
  10096f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100976:	eb 3b                	jmp    1009b3 <mem_init+0x10f>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100978:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  10097d:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100980:	c1 e2 03             	shl    $0x3,%edx
  100983:	01 d0                	add    %edx,%eax
  100985:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  10098c:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100991:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100994:	c1 e2 03             	shl    $0x3,%edx
  100997:	8d 14 10             	lea    (%eax,%edx,1),%edx
  10099a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10099d:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  10099f:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  1009a4:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1009a7:	c1 e2 03             	shl    $0x3,%edx
  1009aa:	01 d0                	add    %edx,%eax
  1009ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
	int i;
	for (i = 0; i < mem_npage; i++) {
  1009af:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1009b3:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1009b6:	a1 f4 6f 10 00       	mov    0x106ff4,%eax
  1009bb:	39 c2                	cmp    %eax,%edx
  1009bd:	72 b9                	jb     100978 <mem_init+0xd4>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  1009bf:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1009c2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	panic("mem_init() not implemented");
  1009c8:	c7 44 24 08 f9 30 10 	movl   $0x1030f9,0x8(%esp)
  1009cf:	00 
  1009d0:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  1009d7:	00 
  1009d8:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  1009df:	e8 a0 f9 ff ff       	call   100384 <debug_panic>

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  1009e4:	c9                   	leave  
  1009e5:	c3                   	ret    

001009e6 <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  1009e6:	55                   	push   %ebp
  1009e7:	89 e5                	mov    %esp,%ebp
  1009e9:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	// Fill this function in.
	panic("mem_alloc not implemented.");
  1009ec:	c7 44 24 08 14 31 10 	movl   $0x103114,0x8(%esp)
  1009f3:	00 
  1009f4:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  1009fb:	00 
  1009fc:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100a03:	e8 7c f9 ff ff       	call   100384 <debug_panic>

00100a08 <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100a08:	55                   	push   %ebp
  100a09:	89 e5                	mov    %esp,%ebp
  100a0b:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	panic("mem_free not implemented.");
  100a0e:	c7 44 24 08 2f 31 10 	movl   $0x10312f,0x8(%esp)
  100a15:	00 
  100a16:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  100a1d:	00 
  100a1e:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100a25:	e8 5a f9 ff ff       	call   100384 <debug_panic>

00100a2a <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100a2a:	55                   	push   %ebp
  100a2b:	89 e5                	mov    %esp,%ebp
  100a2d:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100a30:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100a37:	a1 f0 6f 10 00       	mov    0x106ff0,%eax
  100a3c:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100a3f:	eb 38                	jmp    100a79 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100a41:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100a44:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100a49:	89 d1                	mov    %edx,%ecx
  100a4b:	29 c1                	sub    %eax,%ecx
  100a4d:	89 c8                	mov    %ecx,%eax
  100a4f:	c1 f8 03             	sar    $0x3,%eax
  100a52:	c1 e0 0c             	shl    $0xc,%eax
  100a55:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100a5c:	00 
  100a5d:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100a64:	00 
  100a65:	89 04 24             	mov    %eax,(%esp)
  100a68:	e8 a0 1e 00 00       	call   10290d <memset>
		freepages++;
  100a6d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100a71:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100a74:	8b 00                	mov    (%eax),%eax
  100a76:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100a79:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  100a7d:	75 c2                	jne    100a41 <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100a7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a82:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a86:	c7 04 24 49 31 10 00 	movl   $0x103149,(%esp)
  100a8d:	e8 96 1c 00 00       	call   102728 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100a92:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100a95:	a1 f4 6f 10 00       	mov    0x106ff4,%eax
  100a9a:	39 c2                	cmp    %eax,%edx
  100a9c:	72 24                	jb     100ac2 <mem_check+0x98>
  100a9e:	c7 44 24 0c 63 31 10 	movl   $0x103163,0xc(%esp)
  100aa5:	00 
  100aa6:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100aad:	00 
  100aae:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100ab5:	00 
  100ab6:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100abd:	e8 c2 f8 ff ff       	call   100384 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100ac2:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100ac9:	7f 24                	jg     100aef <mem_check+0xc5>
  100acb:	c7 44 24 0c 79 31 10 	movl   $0x103179,0xc(%esp)
  100ad2:	00 
  100ad3:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100ada:	00 
  100adb:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
  100ae2:	00 
  100ae3:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100aea:	e8 95 f8 ff ff       	call   100384 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100aef:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100af6:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100af9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100afc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100aff:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100b02:	e8 df fe ff ff       	call   1009e6 <mem_alloc>
  100b07:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100b0a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100b0e:	75 24                	jne    100b34 <mem_check+0x10a>
  100b10:	c7 44 24 0c 8b 31 10 	movl   $0x10318b,0xc(%esp)
  100b17:	00 
  100b18:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100b1f:	00 
  100b20:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  100b27:	00 
  100b28:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100b2f:	e8 50 f8 ff ff       	call   100384 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100b34:	e8 ad fe ff ff       	call   1009e6 <mem_alloc>
  100b39:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100b3c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100b40:	75 24                	jne    100b66 <mem_check+0x13c>
  100b42:	c7 44 24 0c 94 31 10 	movl   $0x103194,0xc(%esp)
  100b49:	00 
  100b4a:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100b51:	00 
  100b52:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100b59:	00 
  100b5a:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100b61:	e8 1e f8 ff ff       	call   100384 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100b66:	e8 7b fe ff ff       	call   1009e6 <mem_alloc>
  100b6b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100b6e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100b72:	75 24                	jne    100b98 <mem_check+0x16e>
  100b74:	c7 44 24 0c 9d 31 10 	movl   $0x10319d,0xc(%esp)
  100b7b:	00 
  100b7c:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100b83:	00 
  100b84:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  100b8b:	00 
  100b8c:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100b93:	e8 ec f7 ff ff       	call   100384 <debug_panic>

	assert(pp0);
  100b98:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100b9c:	75 24                	jne    100bc2 <mem_check+0x198>
  100b9e:	c7 44 24 0c a6 31 10 	movl   $0x1031a6,0xc(%esp)
  100ba5:	00 
  100ba6:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100bad:	00 
  100bae:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  100bb5:	00 
  100bb6:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100bbd:	e8 c2 f7 ff ff       	call   100384 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100bc2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100bc6:	74 08                	je     100bd0 <mem_check+0x1a6>
  100bc8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100bcb:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100bce:	75 24                	jne    100bf4 <mem_check+0x1ca>
  100bd0:	c7 44 24 0c aa 31 10 	movl   $0x1031aa,0xc(%esp)
  100bd7:	00 
  100bd8:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100bdf:	00 
  100be0:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100be7:	00 
  100be8:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100bef:	e8 90 f7 ff ff       	call   100384 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100bf4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100bf8:	74 10                	je     100c0a <mem_check+0x1e0>
  100bfa:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100bfd:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100c00:	74 08                	je     100c0a <mem_check+0x1e0>
  100c02:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100c05:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100c08:	75 24                	jne    100c2e <mem_check+0x204>
  100c0a:	c7 44 24 0c bc 31 10 	movl   $0x1031bc,0xc(%esp)
  100c11:	00 
  100c12:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100c19:	00 
  100c1a:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  100c21:	00 
  100c22:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100c29:	e8 56 f7 ff ff       	call   100384 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100c2e:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100c31:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100c36:	89 d1                	mov    %edx,%ecx
  100c38:	29 c1                	sub    %eax,%ecx
  100c3a:	89 c8                	mov    %ecx,%eax
  100c3c:	c1 f8 03             	sar    $0x3,%eax
  100c3f:	c1 e0 0c             	shl    $0xc,%eax
  100c42:	8b 15 f4 6f 10 00    	mov    0x106ff4,%edx
  100c48:	c1 e2 0c             	shl    $0xc,%edx
  100c4b:	39 d0                	cmp    %edx,%eax
  100c4d:	72 24                	jb     100c73 <mem_check+0x249>
  100c4f:	c7 44 24 0c dc 31 10 	movl   $0x1031dc,0xc(%esp)
  100c56:	00 
  100c57:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100c5e:	00 
  100c5f:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100c66:	00 
  100c67:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100c6e:	e8 11 f7 ff ff       	call   100384 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100c73:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100c76:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100c7b:	89 d1                	mov    %edx,%ecx
  100c7d:	29 c1                	sub    %eax,%ecx
  100c7f:	89 c8                	mov    %ecx,%eax
  100c81:	c1 f8 03             	sar    $0x3,%eax
  100c84:	c1 e0 0c             	shl    $0xc,%eax
  100c87:	8b 15 f4 6f 10 00    	mov    0x106ff4,%edx
  100c8d:	c1 e2 0c             	shl    $0xc,%edx
  100c90:	39 d0                	cmp    %edx,%eax
  100c92:	72 24                	jb     100cb8 <mem_check+0x28e>
  100c94:	c7 44 24 0c 04 32 10 	movl   $0x103204,0xc(%esp)
  100c9b:	00 
  100c9c:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100ca3:	00 
  100ca4:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100cab:	00 
  100cac:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100cb3:	e8 cc f6 ff ff       	call   100384 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100cb8:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100cbb:	a1 fc 6f 10 00       	mov    0x106ffc,%eax
  100cc0:	89 d1                	mov    %edx,%ecx
  100cc2:	29 c1                	sub    %eax,%ecx
  100cc4:	89 c8                	mov    %ecx,%eax
  100cc6:	c1 f8 03             	sar    $0x3,%eax
  100cc9:	c1 e0 0c             	shl    $0xc,%eax
  100ccc:	8b 15 f4 6f 10 00    	mov    0x106ff4,%edx
  100cd2:	c1 e2 0c             	shl    $0xc,%edx
  100cd5:	39 d0                	cmp    %edx,%eax
  100cd7:	72 24                	jb     100cfd <mem_check+0x2d3>
  100cd9:	c7 44 24 0c 2c 32 10 	movl   $0x10322c,0xc(%esp)
  100ce0:	00 
  100ce1:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100ce8:	00 
  100ce9:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100cf0:	00 
  100cf1:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100cf8:	e8 87 f6 ff ff       	call   100384 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100cfd:	a1 f0 6f 10 00       	mov    0x106ff0,%eax
  100d02:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100d05:	c7 05 f0 6f 10 00 00 	movl   $0x0,0x106ff0
  100d0c:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100d0f:	e8 d2 fc ff ff       	call   1009e6 <mem_alloc>
  100d14:	85 c0                	test   %eax,%eax
  100d16:	74 24                	je     100d3c <mem_check+0x312>
  100d18:	c7 44 24 0c 52 32 10 	movl   $0x103252,0xc(%esp)
  100d1f:	00 
  100d20:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100d27:	00 
  100d28:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  100d2f:	00 
  100d30:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100d37:	e8 48 f6 ff ff       	call   100384 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100d3c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100d3f:	89 04 24             	mov    %eax,(%esp)
  100d42:	e8 c1 fc ff ff       	call   100a08 <mem_free>
        mem_free(pp1);
  100d47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d4a:	89 04 24             	mov    %eax,(%esp)
  100d4d:	e8 b6 fc ff ff       	call   100a08 <mem_free>
        mem_free(pp2);
  100d52:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d55:	89 04 24             	mov    %eax,(%esp)
  100d58:	e8 ab fc ff ff       	call   100a08 <mem_free>
	pp0 = pp1 = pp2 = 0;
  100d5d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100d64:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100d67:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100d6a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100d6d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100d70:	e8 71 fc ff ff       	call   1009e6 <mem_alloc>
  100d75:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100d78:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100d7c:	75 24                	jne    100da2 <mem_check+0x378>
  100d7e:	c7 44 24 0c 8b 31 10 	movl   $0x10318b,0xc(%esp)
  100d85:	00 
  100d86:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100d8d:	00 
  100d8e:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  100d95:	00 
  100d96:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100d9d:	e8 e2 f5 ff ff       	call   100384 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100da2:	e8 3f fc ff ff       	call   1009e6 <mem_alloc>
  100da7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100daa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100dae:	75 24                	jne    100dd4 <mem_check+0x3aa>
  100db0:	c7 44 24 0c 94 31 10 	movl   $0x103194,0xc(%esp)
  100db7:	00 
  100db8:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100dbf:	00 
  100dc0:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  100dc7:	00 
  100dc8:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100dcf:	e8 b0 f5 ff ff       	call   100384 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100dd4:	e8 0d fc ff ff       	call   1009e6 <mem_alloc>
  100dd9:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100ddc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100de0:	75 24                	jne    100e06 <mem_check+0x3dc>
  100de2:	c7 44 24 0c 9d 31 10 	movl   $0x10319d,0xc(%esp)
  100de9:	00 
  100dea:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100df1:	00 
  100df2:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  100df9:	00 
  100dfa:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100e01:	e8 7e f5 ff ff       	call   100384 <debug_panic>
	assert(pp0);
  100e06:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100e0a:	75 24                	jne    100e30 <mem_check+0x406>
  100e0c:	c7 44 24 0c a6 31 10 	movl   $0x1031a6,0xc(%esp)
  100e13:	00 
  100e14:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100e1b:	00 
  100e1c:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
  100e23:	00 
  100e24:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100e2b:	e8 54 f5 ff ff       	call   100384 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100e30:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100e34:	74 08                	je     100e3e <mem_check+0x414>
  100e36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100e39:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100e3c:	75 24                	jne    100e62 <mem_check+0x438>
  100e3e:	c7 44 24 0c aa 31 10 	movl   $0x1031aa,0xc(%esp)
  100e45:	00 
  100e46:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100e4d:	00 
  100e4e:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  100e55:	00 
  100e56:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100e5d:	e8 22 f5 ff ff       	call   100384 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100e62:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100e66:	74 10                	je     100e78 <mem_check+0x44e>
  100e68:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e6b:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100e6e:	74 08                	je     100e78 <mem_check+0x44e>
  100e70:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e73:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100e76:	75 24                	jne    100e9c <mem_check+0x472>
  100e78:	c7 44 24 0c bc 31 10 	movl   $0x1031bc,0xc(%esp)
  100e7f:	00 
  100e80:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100e87:	00 
  100e88:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  100e8f:	00 
  100e90:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100e97:	e8 e8 f4 ff ff       	call   100384 <debug_panic>
	assert(mem_alloc() == 0);
  100e9c:	e8 45 fb ff ff       	call   1009e6 <mem_alloc>
  100ea1:	85 c0                	test   %eax,%eax
  100ea3:	74 24                	je     100ec9 <mem_check+0x49f>
  100ea5:	c7 44 24 0c 52 32 10 	movl   $0x103252,0xc(%esp)
  100eac:	00 
  100ead:	c7 44 24 08 6e 30 10 	movl   $0x10306e,0x8(%esp)
  100eb4:	00 
  100eb5:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  100ebc:	00 
  100ebd:	c7 04 24 b0 30 10 00 	movl   $0x1030b0,(%esp)
  100ec4:	e8 bb f4 ff ff       	call   100384 <debug_panic>

	// give free list back
	mem_freelist = fl;
  100ec9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100ecc:	a3 f0 6f 10 00       	mov    %eax,0x106ff0

	// free the pages we took
	mem_free(pp0);
  100ed1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100ed4:	89 04 24             	mov    %eax,(%esp)
  100ed7:	e8 2c fb ff ff       	call   100a08 <mem_free>
	mem_free(pp1);
  100edc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100edf:	89 04 24             	mov    %eax,(%esp)
  100ee2:	e8 21 fb ff ff       	call   100a08 <mem_free>
	mem_free(pp2);
  100ee7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100eea:	89 04 24             	mov    %eax,(%esp)
  100eed:	e8 16 fb ff ff       	call   100a08 <mem_free>

	cprintf("mem_check() succeeded!\n");
  100ef2:	c7 04 24 63 32 10 00 	movl   $0x103263,(%esp)
  100ef9:	e8 2a 18 00 00       	call   102728 <cprintf>
}
  100efe:	c9                   	leave  
  100eff:	c3                   	ret    

00100f00 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100f00:	55                   	push   %ebp
  100f01:	89 e5                	mov    %esp,%ebp
  100f03:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100f06:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100f09:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100f0c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100f0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f12:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100f17:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100f1a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100f1d:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100f23:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100f28:	74 24                	je     100f4e <cpu_cur+0x4e>
  100f2a:	c7 44 24 0c 7b 32 10 	movl   $0x10327b,0xc(%esp)
  100f31:	00 
  100f32:	c7 44 24 08 91 32 10 	movl   $0x103291,0x8(%esp)
  100f39:	00 
  100f3a:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100f41:	00 
  100f42:	c7 04 24 a6 32 10 00 	movl   $0x1032a6,(%esp)
  100f49:	e8 36 f4 ff ff       	call   100384 <debug_panic>
	return c;
  100f4e:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100f51:	c9                   	leave  
  100f52:	c3                   	ret    

00100f53 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  100f53:	55                   	push   %ebp
  100f54:	89 e5                	mov    %esp,%ebp
  100f56:	53                   	push   %ebx
  100f57:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  100f5a:	e8 a1 ff ff ff       	call   100f00 <cpu_cur>
  100f5f:	89 45 f0             	mov    %eax,-0x10(%ebp)

	c->tss.ts_ss0 = CPU_GDT_KDATA;
  100f62:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f65:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)
	c->tss.ts_esp0 = (uintptr_t)c->kstackhi; 
  100f6b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f6e:	05 00 10 00 00       	add    $0x1000,%eax
  100f73:	89 c2                	mov    %eax,%edx
  100f75:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f78:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->gdt[CPU_GDT_TSS>>3] = SEGDESC16(0, STS_T32A, (uintptr_t)(&c->tss), sizeof(c->tss) - 1, 0);
  100f7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f7e:	83 c0 38             	add    $0x38,%eax
  100f81:	89 c3                	mov    %eax,%ebx
  100f83:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f86:	83 c0 38             	add    $0x38,%eax
  100f89:	c1 e8 10             	shr    $0x10,%eax
  100f8c:	89 c1                	mov    %eax,%ecx
  100f8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f91:	83 c0 38             	add    $0x38,%eax
  100f94:	c1 e8 18             	shr    $0x18,%eax
  100f97:	89 c2                	mov    %eax,%edx
  100f99:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f9c:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  100fa2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fa5:	66 89 58 32          	mov    %bx,0x32(%eax)
  100fa9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fac:	88 48 34             	mov    %cl,0x34(%eax)
  100faf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fb2:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100fb6:	83 e1 f0             	and    $0xfffffff0,%ecx
  100fb9:	83 c9 09             	or     $0x9,%ecx
  100fbc:	88 48 35             	mov    %cl,0x35(%eax)
  100fbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fc2:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100fc6:	83 e1 ef             	and    $0xffffffef,%ecx
  100fc9:	88 48 35             	mov    %cl,0x35(%eax)
  100fcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fcf:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100fd3:	83 e1 9f             	and    $0xffffff9f,%ecx
  100fd6:	88 48 35             	mov    %cl,0x35(%eax)
  100fd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fdc:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  100fe0:	83 c9 80             	or     $0xffffff80,%ecx
  100fe3:	88 48 35             	mov    %cl,0x35(%eax)
  100fe6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100fe9:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100fed:	83 e1 f0             	and    $0xfffffff0,%ecx
  100ff0:	88 48 36             	mov    %cl,0x36(%eax)
  100ff3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100ff6:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  100ffa:	83 e1 ef             	and    $0xffffffef,%ecx
  100ffd:	88 48 36             	mov    %cl,0x36(%eax)
  101000:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101003:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101007:	83 e1 df             	and    $0xffffffdf,%ecx
  10100a:	88 48 36             	mov    %cl,0x36(%eax)
  10100d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101010:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101014:	83 c9 40             	or     $0x40,%ecx
  101017:	88 48 36             	mov    %cl,0x36(%eax)
  10101a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10101d:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101021:	83 e1 7f             	and    $0x7f,%ecx
  101024:	88 48 36             	mov    %cl,0x36(%eax)
  101027:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10102a:	88 50 37             	mov    %dl,0x37(%eax)


	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  10102d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101030:	66 c7 45 ea 37 00    	movw   $0x37,-0x16(%ebp)
  101036:	89 45 ec             	mov    %eax,-0x14(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  101039:	0f 01 55 ea          	lgdtl  -0x16(%ebp)
  10103d:	66 c7 45 f6 30 00    	movw   $0x30,-0xa(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  101043:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  101047:	0f 00 d8             	ltr    %ax
	ltr(CPU_GDT_TSS);
	
	// Reload all segment registers.
	//asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
	//asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  10104a:	b8 10 00 00 00       	mov    $0x10,%eax
  10104f:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  101051:	b8 10 00 00 00       	mov    $0x10,%eax
  101056:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  101058:	b8 10 00 00 00       	mov    $0x10,%eax
  10105d:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  10105f:	ea 66 10 10 00 08 00 	ljmp   $0x8,$0x101066

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  101066:	b8 00 00 00 00       	mov    $0x0,%eax
  10106b:	0f 00 d0             	lldt   %ax
}
  10106e:	83 c4 14             	add    $0x14,%esp
  101071:	5b                   	pop    %ebx
  101072:	5d                   	pop    %ebp
  101073:	c3                   	ret    

00101074 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101074:	55                   	push   %ebp
  101075:	89 e5                	mov    %esp,%ebp
  101077:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10107a:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10107d:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101080:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101083:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101086:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10108b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10108e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101091:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101097:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10109c:	74 24                	je     1010c2 <cpu_cur+0x4e>
  10109e:	c7 44 24 0c c0 32 10 	movl   $0x1032c0,0xc(%esp)
  1010a5:	00 
  1010a6:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  1010ad:	00 
  1010ae:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1010b5:	00 
  1010b6:	c7 04 24 eb 32 10 00 	movl   $0x1032eb,(%esp)
  1010bd:	e8 c2 f2 ff ff       	call   100384 <debug_panic>
	return c;
  1010c2:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1010c5:	c9                   	leave  
  1010c6:	c3                   	ret    

001010c7 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1010c7:	55                   	push   %ebp
  1010c8:	89 e5                	mov    %esp,%ebp
  1010ca:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1010cd:	e8 a2 ff ff ff       	call   101074 <cpu_cur>
  1010d2:	3d 00 40 10 00       	cmp    $0x104000,%eax
  1010d7:	0f 94 c0             	sete   %al
  1010da:	0f b6 c0             	movzbl %al,%eax
}
  1010dd:	c9                   	leave  
  1010de:	c3                   	ret    

001010df <trap_init_idt>:

extern uint32_t vectors[];

static void
trap_init_idt(void)
{
  1010df:	55                   	push   %ebp
  1010e0:	89 e5                	mov    %esp,%ebp
  1010e2:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  1010e5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1010ec:	e9 bc 00 00 00       	jmp    1011ad <trap_init_idt+0xce>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
  1010f1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1010f4:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1010f7:	8b 14 95 10 50 10 00 	mov    0x105010(,%edx,4),%edx
  1010fe:	66 89 14 c5 e0 67 10 	mov    %dx,0x1067e0(,%eax,8)
  101105:	00 
  101106:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101109:	66 c7 04 c5 e2 67 10 	movw   $0x8,0x1067e2(,%eax,8)
  101110:	00 08 00 
  101113:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101116:	0f b6 14 c5 e4 67 10 	movzbl 0x1067e4(,%eax,8),%edx
  10111d:	00 
  10111e:	83 e2 e0             	and    $0xffffffe0,%edx
  101121:	88 14 c5 e4 67 10 00 	mov    %dl,0x1067e4(,%eax,8)
  101128:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10112b:	0f b6 14 c5 e4 67 10 	movzbl 0x1067e4(,%eax,8),%edx
  101132:	00 
  101133:	83 e2 1f             	and    $0x1f,%edx
  101136:	88 14 c5 e4 67 10 00 	mov    %dl,0x1067e4(,%eax,8)
  10113d:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101140:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  101147:	00 
  101148:	83 ca 0f             	or     $0xf,%edx
  10114b:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  101152:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101155:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  10115c:	00 
  10115d:	83 e2 ef             	and    $0xffffffef,%edx
  101160:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  101167:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10116a:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  101171:	00 
  101172:	83 ca 60             	or     $0x60,%edx
  101175:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  10117c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10117f:	0f b6 14 c5 e5 67 10 	movzbl 0x1067e5(,%eax,8),%edx
  101186:	00 
  101187:	83 ca 80             	or     $0xffffff80,%edx
  10118a:	88 14 c5 e5 67 10 00 	mov    %dl,0x1067e5(,%eax,8)
  101191:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101194:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101197:	8b 14 95 10 50 10 00 	mov    0x105010(,%edx,4),%edx
  10119e:	c1 ea 10             	shr    $0x10,%edx
  1011a1:	66 89 14 c5 e6 67 10 	mov    %dx,0x1067e6(,%eax,8)
  1011a8:	00 
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  1011a9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1011ad:	83 7d fc 13          	cmpl   $0x13,-0x4(%ebp)
  1011b1:	0f 8e 3a ff ff ff    	jle    1010f1 <trap_init_idt+0x12>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
	}
	SETGATE(idt[30], 1, CPU_GDT_KCODE, vectors[30], 3);
  1011b7:	a1 88 50 10 00       	mov    0x105088,%eax
  1011bc:	66 a3 d0 68 10 00    	mov    %ax,0x1068d0
  1011c2:	66 c7 05 d2 68 10 00 	movw   $0x8,0x1068d2
  1011c9:	08 00 
  1011cb:	0f b6 05 d4 68 10 00 	movzbl 0x1068d4,%eax
  1011d2:	83 e0 e0             	and    $0xffffffe0,%eax
  1011d5:	a2 d4 68 10 00       	mov    %al,0x1068d4
  1011da:	0f b6 05 d4 68 10 00 	movzbl 0x1068d4,%eax
  1011e1:	83 e0 1f             	and    $0x1f,%eax
  1011e4:	a2 d4 68 10 00       	mov    %al,0x1068d4
  1011e9:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1011f0:	83 c8 0f             	or     $0xf,%eax
  1011f3:	a2 d5 68 10 00       	mov    %al,0x1068d5
  1011f8:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  1011ff:	83 e0 ef             	and    $0xffffffef,%eax
  101202:	a2 d5 68 10 00       	mov    %al,0x1068d5
  101207:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  10120e:	83 c8 60             	or     $0x60,%eax
  101211:	a2 d5 68 10 00       	mov    %al,0x1068d5
  101216:	0f b6 05 d5 68 10 00 	movzbl 0x1068d5,%eax
  10121d:	83 c8 80             	or     $0xffffff80,%eax
  101220:	a2 d5 68 10 00       	mov    %al,0x1068d5
  101225:	a1 88 50 10 00       	mov    0x105088,%eax
  10122a:	c1 e8 10             	shr    $0x10,%eax
  10122d:	66 a3 d6 68 10 00    	mov    %ax,0x1068d6
}
  101233:	c9                   	leave  
  101234:	c3                   	ret    

00101235 <trap_init>:

void
trap_init(void)
{
  101235:	55                   	push   %ebp
  101236:	89 e5                	mov    %esp,%ebp
  101238:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  10123b:	e8 87 fe ff ff       	call   1010c7 <cpu_onboot>
  101240:	85 c0                	test   %eax,%eax
  101242:	74 05                	je     101249 <trap_init+0x14>
		trap_init_idt();
  101244:	e8 96 fe ff ff       	call   1010df <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  101249:	0f 01 1d 00 50 10 00 	lidtl  0x105000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  101250:	e8 72 fe ff ff       	call   1010c7 <cpu_onboot>
  101255:	85 c0                	test   %eax,%eax
  101257:	74 05                	je     10125e <trap_init+0x29>
		trap_check_kernel();
  101259:	e8 62 02 00 00       	call   1014c0 <trap_check_kernel>
}
  10125e:	c9                   	leave  
  10125f:	c3                   	ret    

00101260 <trap_name>:

const char *trap_name(int trapno)
{
  101260:	55                   	push   %ebp
  101261:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101263:	8b 45 08             	mov    0x8(%ebp),%eax
  101266:	83 f8 13             	cmp    $0x13,%eax
  101269:	77 0c                	ja     101277 <trap_name+0x17>
		return excnames[trapno];
  10126b:	8b 45 08             	mov    0x8(%ebp),%eax
  10126e:	8b 04 85 a0 36 10 00 	mov    0x1036a0(,%eax,4),%eax
  101275:	eb 05                	jmp    10127c <trap_name+0x1c>
	return "(unknown trap)";
  101277:	b8 f8 32 10 00       	mov    $0x1032f8,%eax
}
  10127c:	5d                   	pop    %ebp
  10127d:	c3                   	ret    

0010127e <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  10127e:	55                   	push   %ebp
  10127f:	89 e5                	mov    %esp,%ebp
  101281:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  101284:	8b 45 08             	mov    0x8(%ebp),%eax
  101287:	8b 00                	mov    (%eax),%eax
  101289:	89 44 24 04          	mov    %eax,0x4(%esp)
  10128d:	c7 04 24 07 33 10 00 	movl   $0x103307,(%esp)
  101294:	e8 8f 14 00 00       	call   102728 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  101299:	8b 45 08             	mov    0x8(%ebp),%eax
  10129c:	8b 40 04             	mov    0x4(%eax),%eax
  10129f:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012a3:	c7 04 24 16 33 10 00 	movl   $0x103316,(%esp)
  1012aa:	e8 79 14 00 00       	call   102728 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  1012af:	8b 45 08             	mov    0x8(%ebp),%eax
  1012b2:	8b 40 08             	mov    0x8(%eax),%eax
  1012b5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012b9:	c7 04 24 25 33 10 00 	movl   $0x103325,(%esp)
  1012c0:	e8 63 14 00 00       	call   102728 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  1012c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1012c8:	8b 40 10             	mov    0x10(%eax),%eax
  1012cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012cf:	c7 04 24 34 33 10 00 	movl   $0x103334,(%esp)
  1012d6:	e8 4d 14 00 00       	call   102728 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  1012db:	8b 45 08             	mov    0x8(%ebp),%eax
  1012de:	8b 40 14             	mov    0x14(%eax),%eax
  1012e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012e5:	c7 04 24 43 33 10 00 	movl   $0x103343,(%esp)
  1012ec:	e8 37 14 00 00       	call   102728 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  1012f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1012f4:	8b 40 18             	mov    0x18(%eax),%eax
  1012f7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1012fb:	c7 04 24 52 33 10 00 	movl   $0x103352,(%esp)
  101302:	e8 21 14 00 00       	call   102728 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  101307:	8b 45 08             	mov    0x8(%ebp),%eax
  10130a:	8b 40 1c             	mov    0x1c(%eax),%eax
  10130d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101311:	c7 04 24 61 33 10 00 	movl   $0x103361,(%esp)
  101318:	e8 0b 14 00 00       	call   102728 <cprintf>
}
  10131d:	c9                   	leave  
  10131e:	c3                   	ret    

0010131f <trap_print>:

void
trap_print(trapframe *tf)
{
  10131f:	55                   	push   %ebp
  101320:	89 e5                	mov    %esp,%ebp
  101322:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  101325:	8b 45 08             	mov    0x8(%ebp),%eax
  101328:	89 44 24 04          	mov    %eax,0x4(%esp)
  10132c:	c7 04 24 70 33 10 00 	movl   $0x103370,(%esp)
  101333:	e8 f0 13 00 00       	call   102728 <cprintf>
	trap_print_regs(&tf->regs);
  101338:	8b 45 08             	mov    0x8(%ebp),%eax
  10133b:	89 04 24             	mov    %eax,(%esp)
  10133e:	e8 3b ff ff ff       	call   10127e <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  101343:	8b 45 08             	mov    0x8(%ebp),%eax
  101346:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  10134a:	0f b7 c0             	movzwl %ax,%eax
  10134d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101351:	c7 04 24 82 33 10 00 	movl   $0x103382,(%esp)
  101358:	e8 cb 13 00 00       	call   102728 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  10135d:	8b 45 08             	mov    0x8(%ebp),%eax
  101360:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101364:	0f b7 c0             	movzwl %ax,%eax
  101367:	89 44 24 04          	mov    %eax,0x4(%esp)
  10136b:	c7 04 24 95 33 10 00 	movl   $0x103395,(%esp)
  101372:	e8 b1 13 00 00       	call   102728 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101377:	8b 45 08             	mov    0x8(%ebp),%eax
  10137a:	8b 40 30             	mov    0x30(%eax),%eax
  10137d:	89 04 24             	mov    %eax,(%esp)
  101380:	e8 db fe ff ff       	call   101260 <trap_name>
  101385:	8b 55 08             	mov    0x8(%ebp),%edx
  101388:	8b 52 30             	mov    0x30(%edx),%edx
  10138b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10138f:	89 54 24 04          	mov    %edx,0x4(%esp)
  101393:	c7 04 24 a8 33 10 00 	movl   $0x1033a8,(%esp)
  10139a:	e8 89 13 00 00       	call   102728 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  10139f:	8b 45 08             	mov    0x8(%ebp),%eax
  1013a2:	8b 40 34             	mov    0x34(%eax),%eax
  1013a5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013a9:	c7 04 24 ba 33 10 00 	movl   $0x1033ba,(%esp)
  1013b0:	e8 73 13 00 00       	call   102728 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1013b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1013b8:	8b 40 38             	mov    0x38(%eax),%eax
  1013bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013bf:	c7 04 24 c9 33 10 00 	movl   $0x1033c9,(%esp)
  1013c6:	e8 5d 13 00 00       	call   102728 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  1013cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1013ce:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1013d2:	0f b7 c0             	movzwl %ax,%eax
  1013d5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013d9:	c7 04 24 d8 33 10 00 	movl   $0x1033d8,(%esp)
  1013e0:	e8 43 13 00 00       	call   102728 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  1013e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1013e8:	8b 40 40             	mov    0x40(%eax),%eax
  1013eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1013ef:	c7 04 24 eb 33 10 00 	movl   $0x1033eb,(%esp)
  1013f6:	e8 2d 13 00 00       	call   102728 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1013fb:	8b 45 08             	mov    0x8(%ebp),%eax
  1013fe:	8b 40 44             	mov    0x44(%eax),%eax
  101401:	89 44 24 04          	mov    %eax,0x4(%esp)
  101405:	c7 04 24 fa 33 10 00 	movl   $0x1033fa,(%esp)
  10140c:	e8 17 13 00 00       	call   102728 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  101411:	8b 45 08             	mov    0x8(%ebp),%eax
  101414:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101418:	0f b7 c0             	movzwl %ax,%eax
  10141b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10141f:	c7 04 24 09 34 10 00 	movl   $0x103409,(%esp)
  101426:	e8 fd 12 00 00       	call   102728 <cprintf>
}
  10142b:	c9                   	leave  
  10142c:	c3                   	ret    

0010142d <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  10142d:	55                   	push   %ebp
  10142e:	89 e5                	mov    %esp,%ebp
  101430:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  101433:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  101434:	e8 3b fc ff ff       	call   101074 <cpu_cur>
  101439:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  10143c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10143f:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101445:	85 c0                	test   %eax,%eax
  101447:	74 1e                	je     101467 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  101449:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10144c:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  101452:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101455:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  10145b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10145f:	8b 45 08             	mov    0x8(%ebp),%eax
  101462:	89 04 24             	mov    %eax,(%esp)
  101465:	ff d2                	call   *%edx

	trap_print(tf);
  101467:	8b 45 08             	mov    0x8(%ebp),%eax
  10146a:	89 04 24             	mov    %eax,(%esp)
  10146d:	e8 ad fe ff ff       	call   10131f <trap_print>
	panic("unhandled trap");
  101472:	c7 44 24 08 1c 34 10 	movl   $0x10341c,0x8(%esp)
  101479:	00 
  10147a:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  101481:	00 
  101482:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  101489:	e8 f6 ee ff ff       	call   100384 <debug_panic>

0010148e <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  10148e:	55                   	push   %ebp
  10148f:	89 e5                	mov    %esp,%ebp
  101491:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101494:	8b 45 0c             	mov    0xc(%ebp),%eax
  101497:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  10149a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10149d:	8b 00                	mov    (%eax),%eax
  10149f:	89 c2                	mov    %eax,%edx
  1014a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1014a4:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  1014a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1014aa:	8b 40 30             	mov    0x30(%eax),%eax
  1014ad:	89 c2                	mov    %eax,%edx
  1014af:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1014b2:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  1014b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1014b8:	89 04 24             	mov    %eax,(%esp)
  1014bb:	e8 c0 3b 00 00       	call   105080 <trap_return>

001014c0 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  1014c0:	55                   	push   %ebp
  1014c1:	89 e5                	mov    %esp,%ebp
  1014c3:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1014c6:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  1014c9:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  1014cd:	0f b7 c0             	movzwl %ax,%eax
  1014d0:	83 e0 03             	and    $0x3,%eax
  1014d3:	85 c0                	test   %eax,%eax
  1014d5:	74 24                	je     1014fb <trap_check_kernel+0x3b>
  1014d7:	c7 44 24 0c 37 34 10 	movl   $0x103437,0xc(%esp)
  1014de:	00 
  1014df:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  1014e6:	00 
  1014e7:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  1014ee:	00 
  1014ef:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  1014f6:	e8 89 ee ff ff       	call   100384 <debug_panic>

	cpu *c = cpu_cur();
  1014fb:	e8 74 fb ff ff       	call   101074 <cpu_cur>
  101500:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  101503:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101506:	c7 80 a0 00 00 00 8e 	movl   $0x10148e,0xa0(%eax)
  10150d:	14 10 00 
	trap_check(&c->recoverdata);
  101510:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101513:	05 a4 00 00 00       	add    $0xa4,%eax
  101518:	89 04 24             	mov    %eax,(%esp)
  10151b:	e8 96 00 00 00       	call   1015b6 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101520:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101523:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  10152a:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  10152d:	c7 04 24 4c 34 10 00 	movl   $0x10344c,(%esp)
  101534:	e8 ef 11 00 00       	call   102728 <cprintf>
}
  101539:	c9                   	leave  
  10153a:	c3                   	ret    

0010153b <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  10153b:	55                   	push   %ebp
  10153c:	89 e5                	mov    %esp,%ebp
  10153e:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101541:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  101544:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101548:	0f b7 c0             	movzwl %ax,%eax
  10154b:	83 e0 03             	and    $0x3,%eax
  10154e:	83 f8 03             	cmp    $0x3,%eax
  101551:	74 24                	je     101577 <trap_check_user+0x3c>
  101553:	c7 44 24 0c 6c 34 10 	movl   $0x10346c,0xc(%esp)
  10155a:	00 
  10155b:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  101562:	00 
  101563:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
  10156a:	00 
  10156b:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  101572:	e8 0d ee ff ff       	call   100384 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101577:	c7 45 f0 00 40 10 00 	movl   $0x104000,-0x10(%ebp)
	c->recover = trap_check_recover;
  10157e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101581:	c7 80 a0 00 00 00 8e 	movl   $0x10148e,0xa0(%eax)
  101588:	14 10 00 
	trap_check(&c->recoverdata);
  10158b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10158e:	05 a4 00 00 00       	add    $0xa4,%eax
  101593:	89 04 24             	mov    %eax,(%esp)
  101596:	e8 1b 00 00 00       	call   1015b6 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  10159b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10159e:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1015a5:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  1015a8:	c7 04 24 81 34 10 00 	movl   $0x103481,(%esp)
  1015af:	e8 74 11 00 00       	call   102728 <cprintf>
}
  1015b4:	c9                   	leave  
  1015b5:	c3                   	ret    

001015b6 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  1015b6:	55                   	push   %ebp
  1015b7:	89 e5                	mov    %esp,%ebp
  1015b9:	57                   	push   %edi
  1015ba:	56                   	push   %esi
  1015bb:	53                   	push   %ebx
  1015bc:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  1015bf:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  1015c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1015c9:	8d 55 d8             	lea    -0x28(%ebp),%edx
  1015cc:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  1015ce:	c7 45 d8 dc 15 10 00 	movl   $0x1015dc,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1015d5:	b8 00 00 00 00       	mov    $0x0,%eax
  1015da:	f7 f0                	div    %eax

001015dc <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1015dc:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1015df:	85 c0                	test   %eax,%eax
  1015e1:	74 24                	je     101607 <after_div0+0x2b>
  1015e3:	c7 44 24 0c 9f 34 10 	movl   $0x10349f,0xc(%esp)
  1015ea:	00 
  1015eb:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  1015f2:	00 
  1015f3:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  1015fa:	00 
  1015fb:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  101602:	e8 7d ed ff ff       	call   100384 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101607:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10160a:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  10160f:	74 24                	je     101635 <after_div0+0x59>
  101611:	c7 44 24 0c b7 34 10 	movl   $0x1034b7,0xc(%esp)
  101618:	00 
  101619:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  101620:	00 
  101621:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  101628:	00 
  101629:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  101630:	e8 4f ed ff ff       	call   100384 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101635:	c7 45 d8 3d 16 10 00 	movl   $0x10163d,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  10163c:	cc                   	int3   

0010163d <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  10163d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101640:	83 f8 03             	cmp    $0x3,%eax
  101643:	74 24                	je     101669 <after_breakpoint+0x2c>
  101645:	c7 44 24 0c cc 34 10 	movl   $0x1034cc,0xc(%esp)
  10164c:	00 
  10164d:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  101654:	00 
  101655:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  10165c:	00 
  10165d:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  101664:	e8 1b ed ff ff       	call   100384 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101669:	c7 45 d8 78 16 10 00 	movl   $0x101678,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101670:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101675:	01 c0                	add    %eax,%eax
  101677:	ce                   	into   

00101678 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101678:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10167b:	83 f8 04             	cmp    $0x4,%eax
  10167e:	74 24                	je     1016a4 <after_overflow+0x2c>
  101680:	c7 44 24 0c e3 34 10 	movl   $0x1034e3,0xc(%esp)
  101687:	00 
  101688:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  10168f:	00 
  101690:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  101697:	00 
  101698:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  10169f:	e8 e0 ec ff ff       	call   100384 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  1016a4:	c7 45 d8 c1 16 10 00 	movl   $0x1016c1,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  1016ab:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  1016b2:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  1016b9:	b8 00 00 00 00       	mov    $0x0,%eax
  1016be:	62 45 d0             	bound  %eax,-0x30(%ebp)

001016c1 <after_bound>:
	assert(args.trapno == T_BOUND);
  1016c1:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1016c4:	83 f8 05             	cmp    $0x5,%eax
  1016c7:	74 24                	je     1016ed <after_bound+0x2c>
  1016c9:	c7 44 24 0c fa 34 10 	movl   $0x1034fa,0xc(%esp)
  1016d0:	00 
  1016d1:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  1016d8:	00 
  1016d9:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  1016e0:	00 
  1016e1:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  1016e8:	e8 97 ec ff ff       	call   100384 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  1016ed:	c7 45 d8 f6 16 10 00 	movl   $0x1016f6,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  1016f4:	0f 0b                	ud2    

001016f6 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  1016f6:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1016f9:	83 f8 06             	cmp    $0x6,%eax
  1016fc:	74 24                	je     101722 <after_illegal+0x2c>
  1016fe:	c7 44 24 0c 11 35 10 	movl   $0x103511,0xc(%esp)
  101705:	00 
  101706:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  10170d:	00 
  10170e:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  101715:	00 
  101716:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  10171d:	e8 62 ec ff ff       	call   100384 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101722:	c7 45 d8 30 17 10 00 	movl   $0x101730,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101729:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10172e:	8e e0                	mov    %eax,%fs

00101730 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101730:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101733:	83 f8 0d             	cmp    $0xd,%eax
  101736:	74 24                	je     10175c <after_gpfault+0x2c>
  101738:	c7 44 24 0c 28 35 10 	movl   $0x103528,0xc(%esp)
  10173f:	00 
  101740:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  101747:	00 
  101748:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
  10174f:	00 
  101750:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  101757:	e8 28 ec ff ff       	call   100384 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10175c:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  10175f:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101763:	0f b7 c0             	movzwl %ax,%eax
  101766:	83 e0 03             	and    $0x3,%eax
  101769:	85 c0                	test   %eax,%eax
  10176b:	74 3a                	je     1017a7 <after_priv+0x2c>
		args.reip = after_priv;
  10176d:	c7 45 d8 7b 17 10 00 	movl   $0x10177b,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101774:	0f 01 1d 00 50 10 00 	lidtl  0x105000

0010177b <after_priv>:
		assert(args.trapno == T_GPFLT);
  10177b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10177e:	83 f8 0d             	cmp    $0xd,%eax
  101781:	74 24                	je     1017a7 <after_priv+0x2c>
  101783:	c7 44 24 0c 28 35 10 	movl   $0x103528,0xc(%esp)
  10178a:	00 
  10178b:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  101792:	00 
  101793:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
  10179a:	00 
  10179b:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  1017a2:	e8 dd eb ff ff       	call   100384 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  1017a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1017aa:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1017af:	74 24                	je     1017d5 <after_priv+0x5a>
  1017b1:	c7 44 24 0c b7 34 10 	movl   $0x1034b7,0xc(%esp)
  1017b8:	00 
  1017b9:	c7 44 24 08 d6 32 10 	movl   $0x1032d6,0x8(%esp)
  1017c0:	00 
  1017c1:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
  1017c8:	00 
  1017c9:	c7 04 24 2b 34 10 00 	movl   $0x10342b,(%esp)
  1017d0:	e8 af eb ff ff       	call   100384 <debug_panic>
	//cprintf("sfsfsfsfsfsfsfsfsf\n");
	*argsp = NULL;	// recovery mechanism not needed anymore
  1017d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1017d8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1017de:	83 c4 3c             	add    $0x3c,%esp
  1017e1:	5b                   	pop    %ebx
  1017e2:	5e                   	pop    %esi
  1017e3:	5f                   	pop    %edi
  1017e4:	5d                   	pop    %ebp
  1017e5:	c3                   	ret    

001017e6 <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  1017e6:	6a 00                	push   $0x0
  1017e8:	6a 00                	push   $0x0
  1017ea:	e9 75 38 00 00       	jmp    105064 <_alltraps>
  1017ef:	90                   	nop

001017f0 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  1017f0:	6a 00                	push   $0x0
  1017f2:	6a 01                	push   $0x1
  1017f4:	e9 6b 38 00 00       	jmp    105064 <_alltraps>
  1017f9:	90                   	nop

001017fa <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  1017fa:	6a 00                	push   $0x0
  1017fc:	6a 02                	push   $0x2
  1017fe:	e9 61 38 00 00       	jmp    105064 <_alltraps>
  101803:	90                   	nop

00101804 <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  101804:	6a 00                	push   $0x0
  101806:	6a 03                	push   $0x3
  101808:	e9 57 38 00 00       	jmp    105064 <_alltraps>
  10180d:	90                   	nop

0010180e <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  10180e:	6a 00                	push   $0x0
  101810:	6a 04                	push   $0x4
  101812:	e9 4d 38 00 00       	jmp    105064 <_alltraps>
  101817:	90                   	nop

00101818 <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  101818:	6a 00                	push   $0x0
  10181a:	6a 05                	push   $0x5
  10181c:	e9 43 38 00 00       	jmp    105064 <_alltraps>
  101821:	90                   	nop

00101822 <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  101822:	6a 00                	push   $0x0
  101824:	6a 06                	push   $0x6
  101826:	e9 39 38 00 00       	jmp    105064 <_alltraps>
  10182b:	90                   	nop

0010182c <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  10182c:	6a 00                	push   $0x0
  10182e:	6a 07                	push   $0x7
  101830:	e9 2f 38 00 00       	jmp    105064 <_alltraps>
  101835:	90                   	nop

00101836 <vector8>:
TRAPHANDLER(vector8, 8)
  101836:	6a 08                	push   $0x8
  101838:	e9 27 38 00 00       	jmp    105064 <_alltraps>
  10183d:	90                   	nop

0010183e <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  10183e:	6a 00                	push   $0x0
  101840:	6a 09                	push   $0x9
  101842:	e9 1d 38 00 00       	jmp    105064 <_alltraps>
  101847:	90                   	nop

00101848 <vector10>:
TRAPHANDLER(vector10, 10)
  101848:	6a 0a                	push   $0xa
  10184a:	e9 15 38 00 00       	jmp    105064 <_alltraps>
  10184f:	90                   	nop

00101850 <vector11>:
TRAPHANDLER(vector11, 11)
  101850:	6a 0b                	push   $0xb
  101852:	e9 0d 38 00 00       	jmp    105064 <_alltraps>
  101857:	90                   	nop

00101858 <vector12>:
TRAPHANDLER(vector12, 12)
  101858:	6a 0c                	push   $0xc
  10185a:	e9 05 38 00 00       	jmp    105064 <_alltraps>
  10185f:	90                   	nop

00101860 <vector13>:
TRAPHANDLER(vector13, 13)
  101860:	6a 0d                	push   $0xd
  101862:	e9 fd 37 00 00       	jmp    105064 <_alltraps>
  101867:	90                   	nop

00101868 <vector14>:
TRAPHANDLER(vector14, 14)
  101868:	6a 0e                	push   $0xe
  10186a:	e9 f5 37 00 00       	jmp    105064 <_alltraps>
  10186f:	90                   	nop

00101870 <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  101870:	6a 00                	push   $0x0
  101872:	6a 0f                	push   $0xf
  101874:	e9 eb 37 00 00       	jmp    105064 <_alltraps>
  101879:	90                   	nop

0010187a <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  10187a:	6a 00                	push   $0x0
  10187c:	6a 10                	push   $0x10
  10187e:	e9 e1 37 00 00       	jmp    105064 <_alltraps>
  101883:	90                   	nop

00101884 <vector17>:
TRAPHANDLER(vector17, 17)
  101884:	6a 11                	push   $0x11
  101886:	e9 d9 37 00 00       	jmp    105064 <_alltraps>
  10188b:	90                   	nop

0010188c <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  10188c:	6a 00                	push   $0x0
  10188e:	6a 12                	push   $0x12
  101890:	e9 cf 37 00 00       	jmp    105064 <_alltraps>
  101895:	90                   	nop

00101896 <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  101896:	6a 00                	push   $0x0
  101898:	6a 13                	push   $0x13
  10189a:	e9 c5 37 00 00       	jmp    105064 <_alltraps>
  10189f:	90                   	nop

001018a0 <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  1018a0:	6a 00                	push   $0x0
  1018a2:	6a 1e                	push   $0x1e
  1018a4:	e9 bb 37 00 00       	jmp    105064 <_alltraps>

001018a9 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  1018a9:	55                   	push   %ebp
  1018aa:	89 e5                	mov    %esp,%ebp
  1018ac:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  1018af:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  1018b6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1018b9:	0f b7 00             	movzwl (%eax),%eax
  1018bc:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  1018c0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1018c3:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  1018c8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1018cb:	0f b7 00             	movzwl (%eax),%eax
  1018ce:	66 3d 5a a5          	cmp    $0xa55a,%ax
  1018d2:	74 13                	je     1018e7 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  1018d4:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  1018db:	c7 05 e0 6f 10 00 b4 	movl   $0x3b4,0x106fe0
  1018e2:	03 00 00 
  1018e5:	eb 14                	jmp    1018fb <video_init+0x52>
	} else {
		*cp = was;
  1018e7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1018ea:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  1018ee:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  1018f1:	c7 05 e0 6f 10 00 d4 	movl   $0x3d4,0x106fe0
  1018f8:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  1018fb:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101900:	89 45 e8             	mov    %eax,-0x18(%ebp)
  101903:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101907:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  10190b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10190e:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  10190f:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101914:	83 c0 01             	add    $0x1,%eax
  101917:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10191a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10191d:	89 c2                	mov    %eax,%edx
  10191f:	ec                   	in     (%dx),%al
  101920:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  101923:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  101927:	0f b6 c0             	movzbl %al,%eax
  10192a:	c1 e0 08             	shl    $0x8,%eax
  10192d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  101930:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101935:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101938:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10193c:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101940:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101943:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  101944:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101949:	83 c0 01             	add    $0x1,%eax
  10194c:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10194f:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101952:	89 c2                	mov    %eax,%edx
  101954:	ec                   	in     (%dx),%al
  101955:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101958:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  10195c:	0f b6 c0             	movzbl %al,%eax
  10195f:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  101962:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101965:	a3 e4 6f 10 00       	mov    %eax,0x106fe4
	crt_pos = pos;
  10196a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10196d:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
}
  101973:	c9                   	leave  
  101974:	c3                   	ret    

00101975 <video_putc>:



void
video_putc(int c)
{
  101975:	55                   	push   %ebp
  101976:	89 e5                	mov    %esp,%ebp
  101978:	53                   	push   %ebx
  101979:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  10197c:	8b 45 08             	mov    0x8(%ebp),%eax
  10197f:	b0 00                	mov    $0x0,%al
  101981:	85 c0                	test   %eax,%eax
  101983:	75 07                	jne    10198c <video_putc+0x17>
		c |= 0x0700;
  101985:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  10198c:	8b 45 08             	mov    0x8(%ebp),%eax
  10198f:	25 ff 00 00 00       	and    $0xff,%eax
  101994:	83 f8 09             	cmp    $0x9,%eax
  101997:	0f 84 ae 00 00 00    	je     101a4b <video_putc+0xd6>
  10199d:	83 f8 09             	cmp    $0x9,%eax
  1019a0:	7f 0a                	jg     1019ac <video_putc+0x37>
  1019a2:	83 f8 08             	cmp    $0x8,%eax
  1019a5:	74 14                	je     1019bb <video_putc+0x46>
  1019a7:	e9 dd 00 00 00       	jmp    101a89 <video_putc+0x114>
  1019ac:	83 f8 0a             	cmp    $0xa,%eax
  1019af:	74 4e                	je     1019ff <video_putc+0x8a>
  1019b1:	83 f8 0d             	cmp    $0xd,%eax
  1019b4:	74 59                	je     101a0f <video_putc+0x9a>
  1019b6:	e9 ce 00 00 00       	jmp    101a89 <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  1019bb:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  1019c2:	66 85 c0             	test   %ax,%ax
  1019c5:	0f 84 e4 00 00 00    	je     101aaf <video_putc+0x13a>
			crt_pos--;
  1019cb:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  1019d2:	83 e8 01             	sub    $0x1,%eax
  1019d5:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  1019db:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  1019e0:	0f b7 15 e8 6f 10 00 	movzwl 0x106fe8,%edx
  1019e7:	0f b7 d2             	movzwl %dx,%edx
  1019ea:	01 d2                	add    %edx,%edx
  1019ec:	8d 14 10             	lea    (%eax,%edx,1),%edx
  1019ef:	8b 45 08             	mov    0x8(%ebp),%eax
  1019f2:	b0 00                	mov    $0x0,%al
  1019f4:	83 c8 20             	or     $0x20,%eax
  1019f7:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  1019fa:	e9 b1 00 00 00       	jmp    101ab0 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  1019ff:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101a06:	83 c0 50             	add    $0x50,%eax
  101a09:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  101a0f:	0f b7 1d e8 6f 10 00 	movzwl 0x106fe8,%ebx
  101a16:	0f b7 0d e8 6f 10 00 	movzwl 0x106fe8,%ecx
  101a1d:	0f b7 c1             	movzwl %cx,%eax
  101a20:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  101a26:	c1 e8 10             	shr    $0x10,%eax
  101a29:	89 c2                	mov    %eax,%edx
  101a2b:	66 c1 ea 06          	shr    $0x6,%dx
  101a2f:	89 d0                	mov    %edx,%eax
  101a31:	c1 e0 02             	shl    $0x2,%eax
  101a34:	01 d0                	add    %edx,%eax
  101a36:	c1 e0 04             	shl    $0x4,%eax
  101a39:	89 ca                	mov    %ecx,%edx
  101a3b:	66 29 c2             	sub    %ax,%dx
  101a3e:	89 d8                	mov    %ebx,%eax
  101a40:	66 29 d0             	sub    %dx,%ax
  101a43:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
		break;
  101a49:	eb 65                	jmp    101ab0 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  101a4b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101a52:	e8 1e ff ff ff       	call   101975 <video_putc>
		video_putc(' ');
  101a57:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101a5e:	e8 12 ff ff ff       	call   101975 <video_putc>
		video_putc(' ');
  101a63:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101a6a:	e8 06 ff ff ff       	call   101975 <video_putc>
		video_putc(' ');
  101a6f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101a76:	e8 fa fe ff ff       	call   101975 <video_putc>
		video_putc(' ');
  101a7b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101a82:	e8 ee fe ff ff       	call   101975 <video_putc>
		break;
  101a87:	eb 27                	jmp    101ab0 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  101a89:	8b 15 e4 6f 10 00    	mov    0x106fe4,%edx
  101a8f:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101a96:	0f b7 c8             	movzwl %ax,%ecx
  101a99:	01 c9                	add    %ecx,%ecx
  101a9b:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  101a9e:	8b 55 08             	mov    0x8(%ebp),%edx
  101aa1:	66 89 11             	mov    %dx,(%ecx)
  101aa4:	83 c0 01             	add    $0x1,%eax
  101aa7:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
  101aad:	eb 01                	jmp    101ab0 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  101aaf:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  101ab0:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101ab7:	66 3d cf 07          	cmp    $0x7cf,%ax
  101abb:	76 5b                	jbe    101b18 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  101abd:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101ac2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  101ac8:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101acd:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  101ad4:	00 
  101ad5:	89 54 24 04          	mov    %edx,0x4(%esp)
  101ad9:	89 04 24             	mov    %eax,(%esp)
  101adc:	e8 a0 0e 00 00       	call   102981 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101ae1:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  101ae8:	eb 15                	jmp    101aff <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  101aea:	a1 e4 6f 10 00       	mov    0x106fe4,%eax
  101aef:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101af2:	01 d2                	add    %edx,%edx
  101af4:	01 d0                	add    %edx,%eax
  101af6:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101afb:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  101aff:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  101b06:	7e e2                	jle    101aea <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  101b08:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101b0f:	83 e8 50             	sub    $0x50,%eax
  101b12:	66 a3 e8 6f 10 00    	mov    %ax,0x106fe8
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  101b18:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101b1d:	89 45 dc             	mov    %eax,-0x24(%ebp)
  101b20:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101b24:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101b28:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101b2b:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101b2c:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101b33:	66 c1 e8 08          	shr    $0x8,%ax
  101b37:	0f b6 c0             	movzbl %al,%eax
  101b3a:	8b 15 e0 6f 10 00    	mov    0x106fe0,%edx
  101b40:	83 c2 01             	add    $0x1,%edx
  101b43:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  101b46:	88 45 e3             	mov    %al,-0x1d(%ebp)
  101b49:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101b4d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101b50:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  101b51:	a1 e0 6f 10 00       	mov    0x106fe0,%eax
  101b56:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101b59:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  101b5d:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  101b61:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101b64:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  101b65:	0f b7 05 e8 6f 10 00 	movzwl 0x106fe8,%eax
  101b6c:	0f b6 c0             	movzbl %al,%eax
  101b6f:	8b 15 e0 6f 10 00    	mov    0x106fe0,%edx
  101b75:	83 c2 01             	add    $0x1,%edx
  101b78:	89 55 f4             	mov    %edx,-0xc(%ebp)
  101b7b:	88 45 f3             	mov    %al,-0xd(%ebp)
  101b7e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101b82:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101b85:	ee                   	out    %al,(%dx)
}
  101b86:	83 c4 44             	add    $0x44,%esp
  101b89:	5b                   	pop    %ebx
  101b8a:	5d                   	pop    %ebp
  101b8b:	c3                   	ret    

00101b8c <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  101b8c:	55                   	push   %ebp
  101b8d:	89 e5                	mov    %esp,%ebp
  101b8f:	83 ec 38             	sub    $0x38,%esp
  101b92:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101b99:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101b9c:	89 c2                	mov    %eax,%edx
  101b9e:	ec                   	in     (%dx),%al
  101b9f:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  101ba2:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  101ba6:	0f b6 c0             	movzbl %al,%eax
  101ba9:	83 e0 01             	and    $0x1,%eax
  101bac:	85 c0                	test   %eax,%eax
  101bae:	75 0a                	jne    101bba <kbd_proc_data+0x2e>
		return -1;
  101bb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101bb5:	e9 5a 01 00 00       	jmp    101d14 <kbd_proc_data+0x188>
  101bba:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101bc1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101bc4:	89 c2                	mov    %eax,%edx
  101bc6:	ec                   	in     (%dx),%al
  101bc7:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  101bca:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  101bce:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  101bd1:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  101bd5:	75 17                	jne    101bee <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  101bd7:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101bdc:	83 c8 40             	or     $0x40,%eax
  101bdf:	a3 ec 6f 10 00       	mov    %eax,0x106fec
		return 0;
  101be4:	b8 00 00 00 00       	mov    $0x0,%eax
  101be9:	e9 26 01 00 00       	jmp    101d14 <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  101bee:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101bf2:	84 c0                	test   %al,%al
  101bf4:	79 47                	jns    101c3d <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  101bf6:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101bfb:	83 e0 40             	and    $0x40,%eax
  101bfe:	85 c0                	test   %eax,%eax
  101c00:	75 09                	jne    101c0b <kbd_proc_data+0x7f>
  101c02:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101c06:	83 e0 7f             	and    $0x7f,%eax
  101c09:	eb 04                	jmp    101c0f <kbd_proc_data+0x83>
  101c0b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101c0f:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  101c12:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101c16:	0f b6 80 a0 50 10 00 	movzbl 0x1050a0(%eax),%eax
  101c1d:	83 c8 40             	or     $0x40,%eax
  101c20:	0f b6 c0             	movzbl %al,%eax
  101c23:	f7 d0                	not    %eax
  101c25:	89 c2                	mov    %eax,%edx
  101c27:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c2c:	21 d0                	and    %edx,%eax
  101c2e:	a3 ec 6f 10 00       	mov    %eax,0x106fec
		return 0;
  101c33:	b8 00 00 00 00       	mov    $0x0,%eax
  101c38:	e9 d7 00 00 00       	jmp    101d14 <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  101c3d:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c42:	83 e0 40             	and    $0x40,%eax
  101c45:	85 c0                	test   %eax,%eax
  101c47:	74 11                	je     101c5a <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  101c49:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  101c4d:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c52:	83 e0 bf             	and    $0xffffffbf,%eax
  101c55:	a3 ec 6f 10 00       	mov    %eax,0x106fec
	}

	shift |= shiftcode[data];
  101c5a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101c5e:	0f b6 80 a0 50 10 00 	movzbl 0x1050a0(%eax),%eax
  101c65:	0f b6 d0             	movzbl %al,%edx
  101c68:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c6d:	09 d0                	or     %edx,%eax
  101c6f:	a3 ec 6f 10 00       	mov    %eax,0x106fec
	shift ^= togglecode[data];
  101c74:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101c78:	0f b6 80 a0 51 10 00 	movzbl 0x1051a0(%eax),%eax
  101c7f:	0f b6 d0             	movzbl %al,%edx
  101c82:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c87:	31 d0                	xor    %edx,%eax
  101c89:	a3 ec 6f 10 00       	mov    %eax,0x106fec

	c = charcode[shift & (CTL | SHIFT)][data];
  101c8e:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101c93:	83 e0 03             	and    $0x3,%eax
  101c96:	8b 14 85 a0 55 10 00 	mov    0x1055a0(,%eax,4),%edx
  101c9d:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101ca1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  101ca4:	0f b6 00             	movzbl (%eax),%eax
  101ca7:	0f b6 c0             	movzbl %al,%eax
  101caa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  101cad:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101cb2:	83 e0 08             	and    $0x8,%eax
  101cb5:	85 c0                	test   %eax,%eax
  101cb7:	74 22                	je     101cdb <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  101cb9:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  101cbd:	7e 0c                	jle    101ccb <kbd_proc_data+0x13f>
  101cbf:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  101cc3:	7f 06                	jg     101ccb <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  101cc5:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  101cc9:	eb 10                	jmp    101cdb <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  101ccb:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  101ccf:	7e 0a                	jle    101cdb <kbd_proc_data+0x14f>
  101cd1:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  101cd5:	7f 04                	jg     101cdb <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  101cd7:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  101cdb:	a1 ec 6f 10 00       	mov    0x106fec,%eax
  101ce0:	f7 d0                	not    %eax
  101ce2:	83 e0 06             	and    $0x6,%eax
  101ce5:	85 c0                	test   %eax,%eax
  101ce7:	75 28                	jne    101d11 <kbd_proc_data+0x185>
  101ce9:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  101cf0:	75 1f                	jne    101d11 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  101cf2:	c7 04 24 f0 36 10 00 	movl   $0x1036f0,(%esp)
  101cf9:	e8 2a 0a 00 00       	call   102728 <cprintf>
  101cfe:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  101d05:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101d09:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101d0d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101d10:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  101d11:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  101d14:	c9                   	leave  
  101d15:	c3                   	ret    

00101d16 <kbd_intr>:

void
kbd_intr(void)
{
  101d16:	55                   	push   %ebp
  101d17:	89 e5                	mov    %esp,%ebp
  101d19:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  101d1c:	c7 04 24 8c 1b 10 00 	movl   $0x101b8c,(%esp)
  101d23:	e8 25 e5 ff ff       	call   10024d <cons_intr>
}
  101d28:	c9                   	leave  
  101d29:	c3                   	ret    

00101d2a <kbd_init>:

void
kbd_init(void)
{
  101d2a:	55                   	push   %ebp
  101d2b:	89 e5                	mov    %esp,%ebp
}
  101d2d:	5d                   	pop    %ebp
  101d2e:	c3                   	ret    

00101d2f <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  101d2f:	55                   	push   %ebp
  101d30:	89 e5                	mov    %esp,%ebp
  101d32:	83 ec 20             	sub    $0x20,%esp
  101d35:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101d3c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101d3f:	89 c2                	mov    %eax,%edx
  101d41:	ec                   	in     (%dx),%al
  101d42:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  101d45:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101d4c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101d4f:	89 c2                	mov    %eax,%edx
  101d51:	ec                   	in     (%dx),%al
  101d52:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101d55:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101d5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101d5f:	89 c2                	mov    %eax,%edx
  101d61:	ec                   	in     (%dx),%al
  101d62:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101d65:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101d6c:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101d6f:	89 c2                	mov    %eax,%edx
  101d71:	ec                   	in     (%dx),%al
  101d72:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  101d75:	c9                   	leave  
  101d76:	c3                   	ret    

00101d77 <serial_proc_data>:

static int
serial_proc_data(void)
{
  101d77:	55                   	push   %ebp
  101d78:	89 e5                	mov    %esp,%ebp
  101d7a:	83 ec 10             	sub    $0x10,%esp
  101d7d:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  101d84:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101d87:	89 c2                	mov    %eax,%edx
  101d89:	ec                   	in     (%dx),%al
  101d8a:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101d8d:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  101d91:	0f b6 c0             	movzbl %al,%eax
  101d94:	83 e0 01             	and    $0x1,%eax
  101d97:	85 c0                	test   %eax,%eax
  101d99:	75 07                	jne    101da2 <serial_proc_data+0x2b>
		return -1;
  101d9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101da0:	eb 17                	jmp    101db9 <serial_proc_data+0x42>
  101da2:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101da9:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101dac:	89 c2                	mov    %eax,%edx
  101dae:	ec                   	in     (%dx),%al
  101daf:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101db2:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  101db6:	0f b6 c0             	movzbl %al,%eax
}
  101db9:	c9                   	leave  
  101dba:	c3                   	ret    

00101dbb <serial_intr>:

void
serial_intr(void)
{
  101dbb:	55                   	push   %ebp
  101dbc:	89 e5                	mov    %esp,%ebp
  101dbe:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  101dc1:	a1 00 70 10 00       	mov    0x107000,%eax
  101dc6:	85 c0                	test   %eax,%eax
  101dc8:	74 0c                	je     101dd6 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  101dca:	c7 04 24 77 1d 10 00 	movl   $0x101d77,(%esp)
  101dd1:	e8 77 e4 ff ff       	call   10024d <cons_intr>
}
  101dd6:	c9                   	leave  
  101dd7:	c3                   	ret    

00101dd8 <serial_putc>:

void
serial_putc(int c)
{
  101dd8:	55                   	push   %ebp
  101dd9:	89 e5                	mov    %esp,%ebp
  101ddb:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  101dde:	a1 00 70 10 00       	mov    0x107000,%eax
  101de3:	85 c0                	test   %eax,%eax
  101de5:	74 53                	je     101e3a <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  101de7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  101dee:	eb 09                	jmp    101df9 <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  101df0:	e8 3a ff ff ff       	call   101d2f <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  101df5:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  101df9:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101e00:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101e03:	89 c2                	mov    %eax,%edx
  101e05:	ec                   	in     (%dx),%al
  101e06:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  101e09:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101e0d:	0f b6 c0             	movzbl %al,%eax
  101e10:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  101e13:	85 c0                	test   %eax,%eax
  101e15:	75 09                	jne    101e20 <serial_putc+0x48>
  101e17:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  101e1e:	7e d0                	jle    101df0 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  101e20:	8b 45 08             	mov    0x8(%ebp),%eax
  101e23:	0f b6 c0             	movzbl %al,%eax
  101e26:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  101e2d:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101e30:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101e34:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101e37:	ee                   	out    %al,(%dx)
  101e38:	eb 01                	jmp    101e3b <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  101e3a:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  101e3b:	c9                   	leave  
  101e3c:	c3                   	ret    

00101e3d <serial_init>:

void
serial_init(void)
{
  101e3d:	55                   	push   %ebp
  101e3e:	89 e5                	mov    %esp,%ebp
  101e40:	83 ec 50             	sub    $0x50,%esp
  101e43:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  101e4a:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  101e4e:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  101e52:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  101e55:	ee                   	out    %al,(%dx)
  101e56:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  101e5d:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  101e61:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  101e65:	8b 55 bc             	mov    -0x44(%ebp),%edx
  101e68:	ee                   	out    %al,(%dx)
  101e69:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  101e70:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  101e74:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  101e78:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  101e7b:	ee                   	out    %al,(%dx)
  101e7c:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  101e83:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  101e87:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  101e8b:	8b 55 cc             	mov    -0x34(%ebp),%edx
  101e8e:	ee                   	out    %al,(%dx)
  101e8f:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  101e96:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  101e9a:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  101e9e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  101ea1:	ee                   	out    %al,(%dx)
  101ea2:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  101ea9:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  101ead:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  101eb1:	8b 55 dc             	mov    -0x24(%ebp),%edx
  101eb4:	ee                   	out    %al,(%dx)
  101eb5:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  101ebc:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  101ec0:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  101ec4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  101ec7:	ee                   	out    %al,(%dx)
  101ec8:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ecf:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101ed2:	89 c2                	mov    %eax,%edx
  101ed4:	ec                   	in     (%dx),%al
  101ed5:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  101ed8:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  101edc:	3c ff                	cmp    $0xff,%al
  101ede:	0f 95 c0             	setne  %al
  101ee1:	0f b6 c0             	movzbl %al,%eax
  101ee4:	a3 00 70 10 00       	mov    %eax,0x107000
  101ee9:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ef0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101ef3:	89 c2                	mov    %eax,%edx
  101ef5:	ec                   	in     (%dx),%al
  101ef6:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  101ef9:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101f00:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101f03:	89 c2                	mov    %eax,%edx
  101f05:	ec                   	in     (%dx),%al
  101f06:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  101f09:	c9                   	leave  
  101f0a:	c3                   	ret    

00101f0b <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  101f0b:	55                   	push   %ebp
  101f0c:	89 e5                	mov    %esp,%ebp
  101f0e:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101f11:	8b 45 08             	mov    0x8(%ebp),%eax
  101f14:	0f b6 c0             	movzbl %al,%eax
  101f17:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101f1e:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101f21:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101f25:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101f28:	ee                   	out    %al,(%dx)
  101f29:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101f30:	8b 45 f8             	mov    -0x8(%ebp),%eax
  101f33:	89 c2                	mov    %eax,%edx
  101f35:	ec                   	in     (%dx),%al
  101f36:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  101f39:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  101f3d:	0f b6 c0             	movzbl %al,%eax
}
  101f40:	c9                   	leave  
  101f41:	c3                   	ret    

00101f42 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  101f42:	55                   	push   %ebp
  101f43:	89 e5                	mov    %esp,%ebp
  101f45:	53                   	push   %ebx
  101f46:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  101f49:	8b 45 08             	mov    0x8(%ebp),%eax
  101f4c:	89 04 24             	mov    %eax,(%esp)
  101f4f:	e8 b7 ff ff ff       	call   101f0b <nvram_read>
  101f54:	89 c3                	mov    %eax,%ebx
  101f56:	8b 45 08             	mov    0x8(%ebp),%eax
  101f59:	83 c0 01             	add    $0x1,%eax
  101f5c:	89 04 24             	mov    %eax,(%esp)
  101f5f:	e8 a7 ff ff ff       	call   101f0b <nvram_read>
  101f64:	c1 e0 08             	shl    $0x8,%eax
  101f67:	09 d8                	or     %ebx,%eax
}
  101f69:	83 c4 04             	add    $0x4,%esp
  101f6c:	5b                   	pop    %ebx
  101f6d:	5d                   	pop    %ebp
  101f6e:	c3                   	ret    

00101f6f <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  101f6f:	55                   	push   %ebp
  101f70:	89 e5                	mov    %esp,%ebp
  101f72:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101f75:	8b 45 08             	mov    0x8(%ebp),%eax
  101f78:	0f b6 c0             	movzbl %al,%eax
  101f7b:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  101f82:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101f85:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  101f89:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101f8c:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  101f8d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f90:	0f b6 c0             	movzbl %al,%eax
  101f93:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  101f9a:	88 45 fb             	mov    %al,-0x5(%ebp)
  101f9d:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  101fa1:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101fa4:	ee                   	out    %al,(%dx)
}
  101fa5:	c9                   	leave  
  101fa6:	c3                   	ret    

00101fa7 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  101fa7:	55                   	push   %ebp
  101fa8:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  101faa:	8b 45 08             	mov    0x8(%ebp),%eax
  101fad:	8b 40 18             	mov    0x18(%eax),%eax
  101fb0:	83 e0 02             	and    $0x2,%eax
  101fb3:	85 c0                	test   %eax,%eax
  101fb5:	74 1c                	je     101fd3 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  101fb7:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fba:	8b 00                	mov    (%eax),%eax
  101fbc:	8d 50 08             	lea    0x8(%eax),%edx
  101fbf:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fc2:	89 10                	mov    %edx,(%eax)
  101fc4:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fc7:	8b 00                	mov    (%eax),%eax
  101fc9:	83 e8 08             	sub    $0x8,%eax
  101fcc:	8b 50 04             	mov    0x4(%eax),%edx
  101fcf:	8b 00                	mov    (%eax),%eax
  101fd1:	eb 47                	jmp    10201a <getuint+0x73>
	else if (st->flags & F_L)
  101fd3:	8b 45 08             	mov    0x8(%ebp),%eax
  101fd6:	8b 40 18             	mov    0x18(%eax),%eax
  101fd9:	83 e0 01             	and    $0x1,%eax
  101fdc:	84 c0                	test   %al,%al
  101fde:	74 1e                	je     101ffe <getuint+0x57>
		return va_arg(*ap, unsigned long);
  101fe0:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fe3:	8b 00                	mov    (%eax),%eax
  101fe5:	8d 50 04             	lea    0x4(%eax),%edx
  101fe8:	8b 45 0c             	mov    0xc(%ebp),%eax
  101feb:	89 10                	mov    %edx,(%eax)
  101fed:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ff0:	8b 00                	mov    (%eax),%eax
  101ff2:	83 e8 04             	sub    $0x4,%eax
  101ff5:	8b 00                	mov    (%eax),%eax
  101ff7:	ba 00 00 00 00       	mov    $0x0,%edx
  101ffc:	eb 1c                	jmp    10201a <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  101ffe:	8b 45 0c             	mov    0xc(%ebp),%eax
  102001:	8b 00                	mov    (%eax),%eax
  102003:	8d 50 04             	lea    0x4(%eax),%edx
  102006:	8b 45 0c             	mov    0xc(%ebp),%eax
  102009:	89 10                	mov    %edx,(%eax)
  10200b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10200e:	8b 00                	mov    (%eax),%eax
  102010:	83 e8 04             	sub    $0x4,%eax
  102013:	8b 00                	mov    (%eax),%eax
  102015:	ba 00 00 00 00       	mov    $0x0,%edx
}
  10201a:	5d                   	pop    %ebp
  10201b:	c3                   	ret    

0010201c <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  10201c:	55                   	push   %ebp
  10201d:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  10201f:	8b 45 08             	mov    0x8(%ebp),%eax
  102022:	8b 40 18             	mov    0x18(%eax),%eax
  102025:	83 e0 02             	and    $0x2,%eax
  102028:	85 c0                	test   %eax,%eax
  10202a:	74 1c                	je     102048 <getint+0x2c>
		return va_arg(*ap, long long);
  10202c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10202f:	8b 00                	mov    (%eax),%eax
  102031:	8d 50 08             	lea    0x8(%eax),%edx
  102034:	8b 45 0c             	mov    0xc(%ebp),%eax
  102037:	89 10                	mov    %edx,(%eax)
  102039:	8b 45 0c             	mov    0xc(%ebp),%eax
  10203c:	8b 00                	mov    (%eax),%eax
  10203e:	83 e8 08             	sub    $0x8,%eax
  102041:	8b 50 04             	mov    0x4(%eax),%edx
  102044:	8b 00                	mov    (%eax),%eax
  102046:	eb 47                	jmp    10208f <getint+0x73>
	else if (st->flags & F_L)
  102048:	8b 45 08             	mov    0x8(%ebp),%eax
  10204b:	8b 40 18             	mov    0x18(%eax),%eax
  10204e:	83 e0 01             	and    $0x1,%eax
  102051:	84 c0                	test   %al,%al
  102053:	74 1e                	je     102073 <getint+0x57>
		return va_arg(*ap, long);
  102055:	8b 45 0c             	mov    0xc(%ebp),%eax
  102058:	8b 00                	mov    (%eax),%eax
  10205a:	8d 50 04             	lea    0x4(%eax),%edx
  10205d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102060:	89 10                	mov    %edx,(%eax)
  102062:	8b 45 0c             	mov    0xc(%ebp),%eax
  102065:	8b 00                	mov    (%eax),%eax
  102067:	83 e8 04             	sub    $0x4,%eax
  10206a:	8b 00                	mov    (%eax),%eax
  10206c:	89 c2                	mov    %eax,%edx
  10206e:	c1 fa 1f             	sar    $0x1f,%edx
  102071:	eb 1c                	jmp    10208f <getint+0x73>
	else
		return va_arg(*ap, int);
  102073:	8b 45 0c             	mov    0xc(%ebp),%eax
  102076:	8b 00                	mov    (%eax),%eax
  102078:	8d 50 04             	lea    0x4(%eax),%edx
  10207b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10207e:	89 10                	mov    %edx,(%eax)
  102080:	8b 45 0c             	mov    0xc(%ebp),%eax
  102083:	8b 00                	mov    (%eax),%eax
  102085:	83 e8 04             	sub    $0x4,%eax
  102088:	8b 00                	mov    (%eax),%eax
  10208a:	89 c2                	mov    %eax,%edx
  10208c:	c1 fa 1f             	sar    $0x1f,%edx
}
  10208f:	5d                   	pop    %ebp
  102090:	c3                   	ret    

00102091 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  102091:	55                   	push   %ebp
  102092:	89 e5                	mov    %esp,%ebp
  102094:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  102097:	eb 1a                	jmp    1020b3 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  102099:	8b 45 08             	mov    0x8(%ebp),%eax
  10209c:	8b 08                	mov    (%eax),%ecx
  10209e:	8b 45 08             	mov    0x8(%ebp),%eax
  1020a1:	8b 50 04             	mov    0x4(%eax),%edx
  1020a4:	8b 45 08             	mov    0x8(%ebp),%eax
  1020a7:	8b 40 08             	mov    0x8(%eax),%eax
  1020aa:	89 54 24 04          	mov    %edx,0x4(%esp)
  1020ae:	89 04 24             	mov    %eax,(%esp)
  1020b1:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  1020b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1020b6:	8b 40 0c             	mov    0xc(%eax),%eax
  1020b9:	8d 50 ff             	lea    -0x1(%eax),%edx
  1020bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1020bf:	89 50 0c             	mov    %edx,0xc(%eax)
  1020c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1020c5:	8b 40 0c             	mov    0xc(%eax),%eax
  1020c8:	85 c0                	test   %eax,%eax
  1020ca:	79 cd                	jns    102099 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  1020cc:	c9                   	leave  
  1020cd:	c3                   	ret    

001020ce <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  1020ce:	55                   	push   %ebp
  1020cf:	89 e5                	mov    %esp,%ebp
  1020d1:	53                   	push   %ebx
  1020d2:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  1020d5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1020d9:	79 18                	jns    1020f3 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  1020db:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1020e2:	00 
  1020e3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1020e6:	89 04 24             	mov    %eax,(%esp)
  1020e9:	e8 e7 07 00 00       	call   1028d5 <strchr>
  1020ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1020f1:	eb 2c                	jmp    10211f <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  1020f3:	8b 45 10             	mov    0x10(%ebp),%eax
  1020f6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1020fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102101:	00 
  102102:	8b 45 0c             	mov    0xc(%ebp),%eax
  102105:	89 04 24             	mov    %eax,(%esp)
  102108:	e8 cc 09 00 00       	call   102ad9 <memchr>
  10210d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102110:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  102114:	75 09                	jne    10211f <putstr+0x51>
		lim = str + maxlen;
  102116:	8b 45 10             	mov    0x10(%ebp),%eax
  102119:	03 45 0c             	add    0xc(%ebp),%eax
  10211c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  10211f:	8b 45 08             	mov    0x8(%ebp),%eax
  102122:	8b 40 0c             	mov    0xc(%eax),%eax
  102125:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  102128:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10212b:	89 cb                	mov    %ecx,%ebx
  10212d:	29 d3                	sub    %edx,%ebx
  10212f:	89 da                	mov    %ebx,%edx
  102131:	8d 14 10             	lea    (%eax,%edx,1),%edx
  102134:	8b 45 08             	mov    0x8(%ebp),%eax
  102137:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  10213a:	8b 45 08             	mov    0x8(%ebp),%eax
  10213d:	8b 40 18             	mov    0x18(%eax),%eax
  102140:	83 e0 10             	and    $0x10,%eax
  102143:	85 c0                	test   %eax,%eax
  102145:	75 32                	jne    102179 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  102147:	8b 45 08             	mov    0x8(%ebp),%eax
  10214a:	89 04 24             	mov    %eax,(%esp)
  10214d:	e8 3f ff ff ff       	call   102091 <putpad>
	while (str < lim) {
  102152:	eb 25                	jmp    102179 <putstr+0xab>
		char ch = *str++;
  102154:	8b 45 0c             	mov    0xc(%ebp),%eax
  102157:	0f b6 00             	movzbl (%eax),%eax
  10215a:	88 45 f7             	mov    %al,-0x9(%ebp)
  10215d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  102161:	8b 45 08             	mov    0x8(%ebp),%eax
  102164:	8b 08                	mov    (%eax),%ecx
  102166:	8b 45 08             	mov    0x8(%ebp),%eax
  102169:	8b 50 04             	mov    0x4(%eax),%edx
  10216c:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  102170:	89 54 24 04          	mov    %edx,0x4(%esp)
  102174:	89 04 24             	mov    %eax,(%esp)
  102177:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  102179:	8b 45 0c             	mov    0xc(%ebp),%eax
  10217c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10217f:	72 d3                	jb     102154 <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  102181:	8b 45 08             	mov    0x8(%ebp),%eax
  102184:	89 04 24             	mov    %eax,(%esp)
  102187:	e8 05 ff ff ff       	call   102091 <putpad>
}
  10218c:	83 c4 24             	add    $0x24,%esp
  10218f:	5b                   	pop    %ebx
  102190:	5d                   	pop    %ebp
  102191:	c3                   	ret    

00102192 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  102192:	55                   	push   %ebp
  102193:	89 e5                	mov    %esp,%ebp
  102195:	53                   	push   %ebx
  102196:	83 ec 24             	sub    $0x24,%esp
  102199:	8b 45 10             	mov    0x10(%ebp),%eax
  10219c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10219f:	8b 45 14             	mov    0x14(%ebp),%eax
  1021a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  1021a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1021a8:	8b 40 1c             	mov    0x1c(%eax),%eax
  1021ab:	89 c2                	mov    %eax,%edx
  1021ad:	c1 fa 1f             	sar    $0x1f,%edx
  1021b0:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  1021b3:	77 4e                	ja     102203 <genint+0x71>
  1021b5:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  1021b8:	72 05                	jb     1021bf <genint+0x2d>
  1021ba:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1021bd:	77 44                	ja     102203 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  1021bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1021c2:	8b 40 1c             	mov    0x1c(%eax),%eax
  1021c5:	89 c2                	mov    %eax,%edx
  1021c7:	c1 fa 1f             	sar    $0x1f,%edx
  1021ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  1021ce:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1021d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1021d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1021d8:	89 04 24             	mov    %eax,(%esp)
  1021db:	89 54 24 04          	mov    %edx,0x4(%esp)
  1021df:	e8 3c 09 00 00       	call   102b20 <__udivdi3>
  1021e4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1021e8:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1021ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1021f6:	89 04 24             	mov    %eax,(%esp)
  1021f9:	e8 94 ff ff ff       	call   102192 <genint>
  1021fe:	89 45 0c             	mov    %eax,0xc(%ebp)
  102201:	eb 1b                	jmp    10221e <genint+0x8c>
	else if (st->signc >= 0)
  102203:	8b 45 08             	mov    0x8(%ebp),%eax
  102206:	8b 40 14             	mov    0x14(%eax),%eax
  102209:	85 c0                	test   %eax,%eax
  10220b:	78 11                	js     10221e <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  10220d:	8b 45 08             	mov    0x8(%ebp),%eax
  102210:	8b 40 14             	mov    0x14(%eax),%eax
  102213:	89 c2                	mov    %eax,%edx
  102215:	8b 45 0c             	mov    0xc(%ebp),%eax
  102218:	88 10                	mov    %dl,(%eax)
  10221a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  10221e:	8b 45 08             	mov    0x8(%ebp),%eax
  102221:	8b 40 1c             	mov    0x1c(%eax),%eax
  102224:	89 c1                	mov    %eax,%ecx
  102226:	89 c3                	mov    %eax,%ebx
  102228:	c1 fb 1f             	sar    $0x1f,%ebx
  10222b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10222e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102231:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  102235:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  102239:	89 04 24             	mov    %eax,(%esp)
  10223c:	89 54 24 04          	mov    %edx,0x4(%esp)
  102240:	e8 0b 0a 00 00       	call   102c50 <__umoddi3>
  102245:	05 fc 36 10 00       	add    $0x1036fc,%eax
  10224a:	0f b6 10             	movzbl (%eax),%edx
  10224d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102250:	88 10                	mov    %dl,(%eax)
  102252:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  102256:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  102259:	83 c4 24             	add    $0x24,%esp
  10225c:	5b                   	pop    %ebx
  10225d:	5d                   	pop    %ebp
  10225e:	c3                   	ret    

0010225f <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  10225f:	55                   	push   %ebp
  102260:	89 e5                	mov    %esp,%ebp
  102262:	83 ec 58             	sub    $0x58,%esp
  102265:	8b 45 0c             	mov    0xc(%ebp),%eax
  102268:	89 45 c0             	mov    %eax,-0x40(%ebp)
  10226b:	8b 45 10             	mov    0x10(%ebp),%eax
  10226e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  102271:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  102274:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  102277:	8b 45 08             	mov    0x8(%ebp),%eax
  10227a:	8b 55 14             	mov    0x14(%ebp),%edx
  10227d:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  102280:	8b 45 c0             	mov    -0x40(%ebp),%eax
  102283:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  102286:	89 44 24 08          	mov    %eax,0x8(%esp)
  10228a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10228e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102291:	89 44 24 04          	mov    %eax,0x4(%esp)
  102295:	8b 45 08             	mov    0x8(%ebp),%eax
  102298:	89 04 24             	mov    %eax,(%esp)
  10229b:	e8 f2 fe ff ff       	call   102192 <genint>
  1022a0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  1022a3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1022a6:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1022a9:	89 d1                	mov    %edx,%ecx
  1022ab:	29 c1                	sub    %eax,%ecx
  1022ad:	89 c8                	mov    %ecx,%eax
  1022af:	89 44 24 08          	mov    %eax,0x8(%esp)
  1022b3:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1022b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1022bd:	89 04 24             	mov    %eax,(%esp)
  1022c0:	e8 09 fe ff ff       	call   1020ce <putstr>
}
  1022c5:	c9                   	leave  
  1022c6:	c3                   	ret    

001022c7 <vprintfmt>:
#endif	// ! PIOS_KERNEL

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  1022c7:	55                   	push   %ebp
  1022c8:	89 e5                	mov    %esp,%ebp
  1022ca:	53                   	push   %ebx
  1022cb:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  1022ce:	8d 55 c8             	lea    -0x38(%ebp),%edx
  1022d1:	b9 00 00 00 00       	mov    $0x0,%ecx
  1022d6:	b8 20 00 00 00       	mov    $0x20,%eax
  1022db:	89 c3                	mov    %eax,%ebx
  1022dd:	83 e3 fc             	and    $0xfffffffc,%ebx
  1022e0:	b8 00 00 00 00       	mov    $0x0,%eax
  1022e5:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  1022e8:	83 c0 04             	add    $0x4,%eax
  1022eb:	39 d8                	cmp    %ebx,%eax
  1022ed:	72 f6                	jb     1022e5 <vprintfmt+0x1e>
  1022ef:	01 c2                	add    %eax,%edx
  1022f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1022f4:	89 45 c8             	mov    %eax,-0x38(%ebp)
  1022f7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022fa:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1022fd:	eb 17                	jmp    102316 <vprintfmt+0x4f>
			if (ch == '\0')
  1022ff:	85 db                	test   %ebx,%ebx
  102301:	0f 84 52 03 00 00    	je     102659 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  102307:	8b 45 0c             	mov    0xc(%ebp),%eax
  10230a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10230e:	89 1c 24             	mov    %ebx,(%esp)
  102311:	8b 45 08             	mov    0x8(%ebp),%eax
  102314:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102316:	8b 45 10             	mov    0x10(%ebp),%eax
  102319:	0f b6 00             	movzbl (%eax),%eax
  10231c:	0f b6 d8             	movzbl %al,%ebx
  10231f:	83 fb 25             	cmp    $0x25,%ebx
  102322:	0f 95 c0             	setne  %al
  102325:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  102329:	84 c0                	test   %al,%al
  10232b:	75 d2                	jne    1022ff <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  10232d:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  102334:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  10233b:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  102342:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  102349:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  102350:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  102357:	eb 04                	jmp    10235d <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  102359:	90                   	nop
  10235a:	eb 01                	jmp    10235d <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  10235c:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  10235d:	8b 45 10             	mov    0x10(%ebp),%eax
  102360:	0f b6 00             	movzbl (%eax),%eax
  102363:	0f b6 d8             	movzbl %al,%ebx
  102366:	89 d8                	mov    %ebx,%eax
  102368:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10236c:	83 e8 20             	sub    $0x20,%eax
  10236f:	83 f8 58             	cmp    $0x58,%eax
  102372:	0f 87 b1 02 00 00    	ja     102629 <vprintfmt+0x362>
  102378:	8b 04 85 14 37 10 00 	mov    0x103714(,%eax,4),%eax
  10237f:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  102381:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102384:	83 c8 10             	or     $0x10,%eax
  102387:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10238a:	eb d1                	jmp    10235d <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  10238c:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  102393:	eb c8                	jmp    10235d <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  102395:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102398:	85 c0                	test   %eax,%eax
  10239a:	79 bd                	jns    102359 <vprintfmt+0x92>
				st.signc = ' ';
  10239c:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  1023a3:	eb b8                	jmp    10235d <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  1023a5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1023a8:	83 e0 08             	and    $0x8,%eax
  1023ab:	85 c0                	test   %eax,%eax
  1023ad:	75 07                	jne    1023b6 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  1023af:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1023b6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  1023bd:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1023c0:	89 d0                	mov    %edx,%eax
  1023c2:	c1 e0 02             	shl    $0x2,%eax
  1023c5:	01 d0                	add    %edx,%eax
  1023c7:	01 c0                	add    %eax,%eax
  1023c9:	01 d8                	add    %ebx,%eax
  1023cb:	83 e8 30             	sub    $0x30,%eax
  1023ce:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  1023d1:	8b 45 10             	mov    0x10(%ebp),%eax
  1023d4:	0f b6 00             	movzbl (%eax),%eax
  1023d7:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  1023da:	83 fb 2f             	cmp    $0x2f,%ebx
  1023dd:	7e 21                	jle    102400 <vprintfmt+0x139>
  1023df:	83 fb 39             	cmp    $0x39,%ebx
  1023e2:	7f 1f                	jg     102403 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  1023e4:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  1023e8:	eb d3                	jmp    1023bd <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  1023ea:	8b 45 14             	mov    0x14(%ebp),%eax
  1023ed:	83 c0 04             	add    $0x4,%eax
  1023f0:	89 45 14             	mov    %eax,0x14(%ebp)
  1023f3:	8b 45 14             	mov    0x14(%ebp),%eax
  1023f6:	83 e8 04             	sub    $0x4,%eax
  1023f9:	8b 00                	mov    (%eax),%eax
  1023fb:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1023fe:	eb 04                	jmp    102404 <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  102400:	90                   	nop
  102401:	eb 01                	jmp    102404 <vprintfmt+0x13d>
  102403:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  102404:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102407:	83 e0 08             	and    $0x8,%eax
  10240a:	85 c0                	test   %eax,%eax
  10240c:	0f 85 4a ff ff ff    	jne    10235c <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  102412:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102415:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  102418:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  10241f:	e9 39 ff ff ff       	jmp    10235d <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  102424:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102427:	83 c8 08             	or     $0x8,%eax
  10242a:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10242d:	e9 2b ff ff ff       	jmp    10235d <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  102432:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102435:	83 c8 04             	or     $0x4,%eax
  102438:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10243b:	e9 1d ff ff ff       	jmp    10235d <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  102440:	8b 55 e0             	mov    -0x20(%ebp),%edx
  102443:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102446:	83 e0 01             	and    $0x1,%eax
  102449:	84 c0                	test   %al,%al
  10244b:	74 07                	je     102454 <vprintfmt+0x18d>
  10244d:	b8 02 00 00 00       	mov    $0x2,%eax
  102452:	eb 05                	jmp    102459 <vprintfmt+0x192>
  102454:	b8 01 00 00 00       	mov    $0x1,%eax
  102459:	09 d0                	or     %edx,%eax
  10245b:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  10245e:	e9 fa fe ff ff       	jmp    10235d <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  102463:	8b 45 14             	mov    0x14(%ebp),%eax
  102466:	83 c0 04             	add    $0x4,%eax
  102469:	89 45 14             	mov    %eax,0x14(%ebp)
  10246c:	8b 45 14             	mov    0x14(%ebp),%eax
  10246f:	83 e8 04             	sub    $0x4,%eax
  102472:	8b 00                	mov    (%eax),%eax
  102474:	8b 55 0c             	mov    0xc(%ebp),%edx
  102477:	89 54 24 04          	mov    %edx,0x4(%esp)
  10247b:	89 04 24             	mov    %eax,(%esp)
  10247e:	8b 45 08             	mov    0x8(%ebp),%eax
  102481:	ff d0                	call   *%eax
			break;
  102483:	e9 cb 01 00 00       	jmp    102653 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  102488:	8b 45 14             	mov    0x14(%ebp),%eax
  10248b:	83 c0 04             	add    $0x4,%eax
  10248e:	89 45 14             	mov    %eax,0x14(%ebp)
  102491:	8b 45 14             	mov    0x14(%ebp),%eax
  102494:	83 e8 04             	sub    $0x4,%eax
  102497:	8b 00                	mov    (%eax),%eax
  102499:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10249c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1024a0:	75 07                	jne    1024a9 <vprintfmt+0x1e2>
				s = "(null)";
  1024a2:	c7 45 f4 0d 37 10 00 	movl   $0x10370d,-0xc(%ebp)
			putstr(&st, s, st.prec);
  1024a9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1024ac:	89 44 24 08          	mov    %eax,0x8(%esp)
  1024b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1024b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024b7:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1024ba:	89 04 24             	mov    %eax,(%esp)
  1024bd:	e8 0c fc ff ff       	call   1020ce <putstr>
			break;
  1024c2:	e9 8c 01 00 00       	jmp    102653 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  1024c7:	8d 45 14             	lea    0x14(%ebp),%eax
  1024ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024ce:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1024d1:	89 04 24             	mov    %eax,(%esp)
  1024d4:	e8 43 fb ff ff       	call   10201c <getint>
  1024d9:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1024dc:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  1024df:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1024e2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1024e5:	85 d2                	test   %edx,%edx
  1024e7:	79 1a                	jns    102503 <vprintfmt+0x23c>
				num = -(intmax_t) num;
  1024e9:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1024ec:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1024ef:	f7 d8                	neg    %eax
  1024f1:	83 d2 00             	adc    $0x0,%edx
  1024f4:	f7 da                	neg    %edx
  1024f6:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1024f9:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  1024fc:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  102503:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10250a:	00 
  10250b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10250e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102511:	89 44 24 04          	mov    %eax,0x4(%esp)
  102515:	89 54 24 08          	mov    %edx,0x8(%esp)
  102519:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10251c:	89 04 24             	mov    %eax,(%esp)
  10251f:	e8 3b fd ff ff       	call   10225f <putint>
			break;
  102524:	e9 2a 01 00 00       	jmp    102653 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  102529:	8d 45 14             	lea    0x14(%ebp),%eax
  10252c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102530:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102533:	89 04 24             	mov    %eax,(%esp)
  102536:	e8 6c fa ff ff       	call   101fa7 <getuint>
  10253b:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  102542:	00 
  102543:	89 44 24 04          	mov    %eax,0x4(%esp)
  102547:	89 54 24 08          	mov    %edx,0x8(%esp)
  10254b:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10254e:	89 04 24             	mov    %eax,(%esp)
  102551:	e8 09 fd ff ff       	call   10225f <putint>
			break;
  102556:	e9 f8 00 00 00       	jmp    102653 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  10255b:	8d 45 14             	lea    0x14(%ebp),%eax
  10255e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102562:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102565:	89 04 24             	mov    %eax,(%esp)
  102568:	e8 3a fa ff ff       	call   101fa7 <getuint>
  10256d:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  102574:	00 
  102575:	89 44 24 04          	mov    %eax,0x4(%esp)
  102579:	89 54 24 08          	mov    %edx,0x8(%esp)
  10257d:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102580:	89 04 24             	mov    %eax,(%esp)
  102583:	e8 d7 fc ff ff       	call   10225f <putint>
			break;
  102588:	e9 c6 00 00 00       	jmp    102653 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10258d:	8d 45 14             	lea    0x14(%ebp),%eax
  102590:	89 44 24 04          	mov    %eax,0x4(%esp)
  102594:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102597:	89 04 24             	mov    %eax,(%esp)
  10259a:	e8 08 fa ff ff       	call   101fa7 <getuint>
  10259f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1025a6:	00 
  1025a7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025ab:	89 54 24 08          	mov    %edx,0x8(%esp)
  1025af:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1025b2:	89 04 24             	mov    %eax,(%esp)
  1025b5:	e8 a5 fc ff ff       	call   10225f <putint>
			break;
  1025ba:	e9 94 00 00 00       	jmp    102653 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  1025bf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025c6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  1025cd:	8b 45 08             	mov    0x8(%ebp),%eax
  1025d0:	ff d0                	call   *%eax
			putch('x', putdat);
  1025d2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025d5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1025d9:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  1025e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1025e3:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  1025e5:	8b 45 14             	mov    0x14(%ebp),%eax
  1025e8:	83 c0 04             	add    $0x4,%eax
  1025eb:	89 45 14             	mov    %eax,0x14(%ebp)
  1025ee:	8b 45 14             	mov    0x14(%ebp),%eax
  1025f1:	83 e8 04             	sub    $0x4,%eax
  1025f4:	8b 00                	mov    (%eax),%eax
  1025f6:	ba 00 00 00 00       	mov    $0x0,%edx
  1025fb:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  102602:	00 
  102603:	89 44 24 04          	mov    %eax,0x4(%esp)
  102607:	89 54 24 08          	mov    %edx,0x8(%esp)
  10260b:	8d 45 c8             	lea    -0x38(%ebp),%eax
  10260e:	89 04 24             	mov    %eax,(%esp)
  102611:	e8 49 fc ff ff       	call   10225f <putint>
			break;
  102616:	eb 3b                	jmp    102653 <vprintfmt+0x38c>
		    }
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  102618:	8b 45 0c             	mov    0xc(%ebp),%eax
  10261b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10261f:	89 1c 24             	mov    %ebx,(%esp)
  102622:	8b 45 08             	mov    0x8(%ebp),%eax
  102625:	ff d0                	call   *%eax
			break;
  102627:	eb 2a                	jmp    102653 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  102629:	8b 45 0c             	mov    0xc(%ebp),%eax
  10262c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102630:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  102637:	8b 45 08             	mov    0x8(%ebp),%eax
  10263a:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  10263c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102640:	eb 04                	jmp    102646 <vprintfmt+0x37f>
  102642:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102646:	8b 45 10             	mov    0x10(%ebp),%eax
  102649:	83 e8 01             	sub    $0x1,%eax
  10264c:	0f b6 00             	movzbl (%eax),%eax
  10264f:	3c 25                	cmp    $0x25,%al
  102651:	75 ef                	jne    102642 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  102653:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102654:	e9 bd fc ff ff       	jmp    102316 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  102659:	83 c4 44             	add    $0x44,%esp
  10265c:	5b                   	pop    %ebx
  10265d:	5d                   	pop    %ebp
  10265e:	c3                   	ret    

0010265f <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  10265f:	55                   	push   %ebp
  102660:	89 e5                	mov    %esp,%ebp
  102662:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  102665:	8b 45 0c             	mov    0xc(%ebp),%eax
  102668:	8b 00                	mov    (%eax),%eax
  10266a:	8b 55 08             	mov    0x8(%ebp),%edx
  10266d:	89 d1                	mov    %edx,%ecx
  10266f:	8b 55 0c             	mov    0xc(%ebp),%edx
  102672:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  102676:	8d 50 01             	lea    0x1(%eax),%edx
  102679:	8b 45 0c             	mov    0xc(%ebp),%eax
  10267c:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  10267e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102681:	8b 00                	mov    (%eax),%eax
  102683:	3d ff 00 00 00       	cmp    $0xff,%eax
  102688:	75 24                	jne    1026ae <putch+0x4f>
		b->buf[b->idx] = 0;
  10268a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10268d:	8b 00                	mov    (%eax),%eax
  10268f:	8b 55 0c             	mov    0xc(%ebp),%edx
  102692:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  102697:	8b 45 0c             	mov    0xc(%ebp),%eax
  10269a:	83 c0 08             	add    $0x8,%eax
  10269d:	89 04 24             	mov    %eax,(%esp)
  1026a0:	e8 b6 dc ff ff       	call   10035b <cputs>
		b->idx = 0;
  1026a5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026a8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  1026ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026b1:	8b 40 04             	mov    0x4(%eax),%eax
  1026b4:	8d 50 01             	lea    0x1(%eax),%edx
  1026b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026ba:	89 50 04             	mov    %edx,0x4(%eax)
}
  1026bd:	c9                   	leave  
  1026be:	c3                   	ret    

001026bf <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  1026bf:	55                   	push   %ebp
  1026c0:	89 e5                	mov    %esp,%ebp
  1026c2:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  1026c8:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  1026cf:	00 00 00 
	b.cnt = 0;
  1026d2:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  1026d9:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  1026dc:	b8 5f 26 10 00       	mov    $0x10265f,%eax
  1026e1:	8b 55 0c             	mov    0xc(%ebp),%edx
  1026e4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1026e8:	8b 55 08             	mov    0x8(%ebp),%edx
  1026eb:	89 54 24 08          	mov    %edx,0x8(%esp)
  1026ef:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  1026f5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1026f9:	89 04 24             	mov    %eax,(%esp)
  1026fc:	e8 c6 fb ff ff       	call   1022c7 <vprintfmt>

	b.buf[b.idx] = 0;
  102701:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  102707:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  10270e:	00 
	cputs(b.buf);
  10270f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  102715:	83 c0 08             	add    $0x8,%eax
  102718:	89 04 24             	mov    %eax,(%esp)
  10271b:	e8 3b dc ff ff       	call   10035b <cputs>

	return b.cnt;
  102720:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  102726:	c9                   	leave  
  102727:	c3                   	ret    

00102728 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  102728:	55                   	push   %ebp
  102729:	89 e5                	mov    %esp,%ebp
  10272b:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  10272e:	8d 45 08             	lea    0x8(%ebp),%eax
  102731:	83 c0 04             	add    $0x4,%eax
  102734:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  102737:	8b 45 08             	mov    0x8(%ebp),%eax
  10273a:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10273d:	89 54 24 04          	mov    %edx,0x4(%esp)
  102741:	89 04 24             	mov    %eax,(%esp)
  102744:	e8 76 ff ff ff       	call   1026bf <vcprintf>
  102749:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  10274c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  10274f:	c9                   	leave  
  102750:	c3                   	ret    

00102751 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  102751:	55                   	push   %ebp
  102752:	89 e5                	mov    %esp,%ebp
  102754:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  102757:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  10275e:	eb 08                	jmp    102768 <strlen+0x17>
		n++;
  102760:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  102764:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102768:	8b 45 08             	mov    0x8(%ebp),%eax
  10276b:	0f b6 00             	movzbl (%eax),%eax
  10276e:	84 c0                	test   %al,%al
  102770:	75 ee                	jne    102760 <strlen+0xf>
		n++;
	return n;
  102772:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102775:	c9                   	leave  
  102776:	c3                   	ret    

00102777 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  102777:	55                   	push   %ebp
  102778:	89 e5                	mov    %esp,%ebp
  10277a:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  10277d:	8b 45 08             	mov    0x8(%ebp),%eax
  102780:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  102783:	8b 45 0c             	mov    0xc(%ebp),%eax
  102786:	0f b6 10             	movzbl (%eax),%edx
  102789:	8b 45 08             	mov    0x8(%ebp),%eax
  10278c:	88 10                	mov    %dl,(%eax)
  10278e:	8b 45 08             	mov    0x8(%ebp),%eax
  102791:	0f b6 00             	movzbl (%eax),%eax
  102794:	84 c0                	test   %al,%al
  102796:	0f 95 c0             	setne  %al
  102799:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10279d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  1027a1:	84 c0                	test   %al,%al
  1027a3:	75 de                	jne    102783 <strcpy+0xc>
		/* do nothing */;
	return ret;
  1027a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1027a8:	c9                   	leave  
  1027a9:	c3                   	ret    

001027aa <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  1027aa:	55                   	push   %ebp
  1027ab:	89 e5                	mov    %esp,%ebp
  1027ad:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  1027b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1027b3:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  1027b6:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1027bd:	eb 21                	jmp    1027e0 <strncpy+0x36>
		*dst++ = *src;
  1027bf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027c2:	0f b6 10             	movzbl (%eax),%edx
  1027c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1027c8:	88 10                	mov    %dl,(%eax)
  1027ca:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  1027ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027d1:	0f b6 00             	movzbl (%eax),%eax
  1027d4:	84 c0                	test   %al,%al
  1027d6:	74 04                	je     1027dc <strncpy+0x32>
			src++;
  1027d8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  1027dc:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1027e0:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1027e3:	3b 45 10             	cmp    0x10(%ebp),%eax
  1027e6:	72 d7                	jb     1027bf <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  1027e8:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1027eb:	c9                   	leave  
  1027ec:	c3                   	ret    

001027ed <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  1027ed:	55                   	push   %ebp
  1027ee:	89 e5                	mov    %esp,%ebp
  1027f0:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  1027f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1027f6:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  1027f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1027fd:	74 2f                	je     10282e <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  1027ff:	eb 13                	jmp    102814 <strlcpy+0x27>
			*dst++ = *src++;
  102801:	8b 45 0c             	mov    0xc(%ebp),%eax
  102804:	0f b6 10             	movzbl (%eax),%edx
  102807:	8b 45 08             	mov    0x8(%ebp),%eax
  10280a:	88 10                	mov    %dl,(%eax)
  10280c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102810:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  102814:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102818:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10281c:	74 0a                	je     102828 <strlcpy+0x3b>
  10281e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102821:	0f b6 00             	movzbl (%eax),%eax
  102824:	84 c0                	test   %al,%al
  102826:	75 d9                	jne    102801 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  102828:	8b 45 08             	mov    0x8(%ebp),%eax
  10282b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  10282e:	8b 55 08             	mov    0x8(%ebp),%edx
  102831:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102834:	89 d1                	mov    %edx,%ecx
  102836:	29 c1                	sub    %eax,%ecx
  102838:	89 c8                	mov    %ecx,%eax
}
  10283a:	c9                   	leave  
  10283b:	c3                   	ret    

0010283c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  10283c:	55                   	push   %ebp
  10283d:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  10283f:	eb 08                	jmp    102849 <strcmp+0xd>
		p++, q++;
  102841:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102845:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  102849:	8b 45 08             	mov    0x8(%ebp),%eax
  10284c:	0f b6 00             	movzbl (%eax),%eax
  10284f:	84 c0                	test   %al,%al
  102851:	74 10                	je     102863 <strcmp+0x27>
  102853:	8b 45 08             	mov    0x8(%ebp),%eax
  102856:	0f b6 10             	movzbl (%eax),%edx
  102859:	8b 45 0c             	mov    0xc(%ebp),%eax
  10285c:	0f b6 00             	movzbl (%eax),%eax
  10285f:	38 c2                	cmp    %al,%dl
  102861:	74 de                	je     102841 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  102863:	8b 45 08             	mov    0x8(%ebp),%eax
  102866:	0f b6 00             	movzbl (%eax),%eax
  102869:	0f b6 d0             	movzbl %al,%edx
  10286c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10286f:	0f b6 00             	movzbl (%eax),%eax
  102872:	0f b6 c0             	movzbl %al,%eax
  102875:	89 d1                	mov    %edx,%ecx
  102877:	29 c1                	sub    %eax,%ecx
  102879:	89 c8                	mov    %ecx,%eax
}
  10287b:	5d                   	pop    %ebp
  10287c:	c3                   	ret    

0010287d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  10287d:	55                   	push   %ebp
  10287e:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  102880:	eb 0c                	jmp    10288e <strncmp+0x11>
		n--, p++, q++;
  102882:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102886:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10288a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  10288e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102892:	74 1a                	je     1028ae <strncmp+0x31>
  102894:	8b 45 08             	mov    0x8(%ebp),%eax
  102897:	0f b6 00             	movzbl (%eax),%eax
  10289a:	84 c0                	test   %al,%al
  10289c:	74 10                	je     1028ae <strncmp+0x31>
  10289e:	8b 45 08             	mov    0x8(%ebp),%eax
  1028a1:	0f b6 10             	movzbl (%eax),%edx
  1028a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028a7:	0f b6 00             	movzbl (%eax),%eax
  1028aa:	38 c2                	cmp    %al,%dl
  1028ac:	74 d4                	je     102882 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  1028ae:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1028b2:	75 07                	jne    1028bb <strncmp+0x3e>
		return 0;
  1028b4:	b8 00 00 00 00       	mov    $0x0,%eax
  1028b9:	eb 18                	jmp    1028d3 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  1028bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1028be:	0f b6 00             	movzbl (%eax),%eax
  1028c1:	0f b6 d0             	movzbl %al,%edx
  1028c4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028c7:	0f b6 00             	movzbl (%eax),%eax
  1028ca:	0f b6 c0             	movzbl %al,%eax
  1028cd:	89 d1                	mov    %edx,%ecx
  1028cf:	29 c1                	sub    %eax,%ecx
  1028d1:	89 c8                	mov    %ecx,%eax
}
  1028d3:	5d                   	pop    %ebp
  1028d4:	c3                   	ret    

001028d5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  1028d5:	55                   	push   %ebp
  1028d6:	89 e5                	mov    %esp,%ebp
  1028d8:	83 ec 04             	sub    $0x4,%esp
  1028db:	8b 45 0c             	mov    0xc(%ebp),%eax
  1028de:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  1028e1:	eb 1a                	jmp    1028fd <strchr+0x28>
		if (*s++ == 0)
  1028e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1028e6:	0f b6 00             	movzbl (%eax),%eax
  1028e9:	84 c0                	test   %al,%al
  1028eb:	0f 94 c0             	sete   %al
  1028ee:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1028f2:	84 c0                	test   %al,%al
  1028f4:	74 07                	je     1028fd <strchr+0x28>
			return NULL;
  1028f6:	b8 00 00 00 00       	mov    $0x0,%eax
  1028fb:	eb 0e                	jmp    10290b <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  1028fd:	8b 45 08             	mov    0x8(%ebp),%eax
  102900:	0f b6 00             	movzbl (%eax),%eax
  102903:	3a 45 fc             	cmp    -0x4(%ebp),%al
  102906:	75 db                	jne    1028e3 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  102908:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10290b:	c9                   	leave  
  10290c:	c3                   	ret    

0010290d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  10290d:	55                   	push   %ebp
  10290e:	89 e5                	mov    %esp,%ebp
  102910:	57                   	push   %edi
  102911:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  102914:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102918:	75 05                	jne    10291f <memset+0x12>
		return v;
  10291a:	8b 45 08             	mov    0x8(%ebp),%eax
  10291d:	eb 5c                	jmp    10297b <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  10291f:	8b 45 08             	mov    0x8(%ebp),%eax
  102922:	83 e0 03             	and    $0x3,%eax
  102925:	85 c0                	test   %eax,%eax
  102927:	75 41                	jne    10296a <memset+0x5d>
  102929:	8b 45 10             	mov    0x10(%ebp),%eax
  10292c:	83 e0 03             	and    $0x3,%eax
  10292f:	85 c0                	test   %eax,%eax
  102931:	75 37                	jne    10296a <memset+0x5d>
		c &= 0xFF;
  102933:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  10293a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10293d:	89 c2                	mov    %eax,%edx
  10293f:	c1 e2 18             	shl    $0x18,%edx
  102942:	8b 45 0c             	mov    0xc(%ebp),%eax
  102945:	c1 e0 10             	shl    $0x10,%eax
  102948:	09 c2                	or     %eax,%edx
  10294a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10294d:	c1 e0 08             	shl    $0x8,%eax
  102950:	09 d0                	or     %edx,%eax
  102952:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  102955:	8b 45 10             	mov    0x10(%ebp),%eax
  102958:	89 c1                	mov    %eax,%ecx
  10295a:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  10295d:	8b 55 08             	mov    0x8(%ebp),%edx
  102960:	8b 45 0c             	mov    0xc(%ebp),%eax
  102963:	89 d7                	mov    %edx,%edi
  102965:	fc                   	cld    
  102966:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  102968:	eb 0e                	jmp    102978 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  10296a:	8b 55 08             	mov    0x8(%ebp),%edx
  10296d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102970:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102973:	89 d7                	mov    %edx,%edi
  102975:	fc                   	cld    
  102976:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  102978:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10297b:	83 c4 10             	add    $0x10,%esp
  10297e:	5f                   	pop    %edi
  10297f:	5d                   	pop    %ebp
  102980:	c3                   	ret    

00102981 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  102981:	55                   	push   %ebp
  102982:	89 e5                	mov    %esp,%ebp
  102984:	57                   	push   %edi
  102985:	56                   	push   %esi
  102986:	53                   	push   %ebx
  102987:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  10298a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10298d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  102990:	8b 45 08             	mov    0x8(%ebp),%eax
  102993:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  102996:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102999:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10299c:	73 6e                	jae    102a0c <memmove+0x8b>
  10299e:	8b 45 10             	mov    0x10(%ebp),%eax
  1029a1:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1029a4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1029a7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1029aa:	76 60                	jbe    102a0c <memmove+0x8b>
		s += n;
  1029ac:	8b 45 10             	mov    0x10(%ebp),%eax
  1029af:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  1029b2:	8b 45 10             	mov    0x10(%ebp),%eax
  1029b5:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1029b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1029bb:	83 e0 03             	and    $0x3,%eax
  1029be:	85 c0                	test   %eax,%eax
  1029c0:	75 2f                	jne    1029f1 <memmove+0x70>
  1029c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1029c5:	83 e0 03             	and    $0x3,%eax
  1029c8:	85 c0                	test   %eax,%eax
  1029ca:	75 25                	jne    1029f1 <memmove+0x70>
  1029cc:	8b 45 10             	mov    0x10(%ebp),%eax
  1029cf:	83 e0 03             	and    $0x3,%eax
  1029d2:	85 c0                	test   %eax,%eax
  1029d4:	75 1b                	jne    1029f1 <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  1029d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1029d9:	83 e8 04             	sub    $0x4,%eax
  1029dc:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1029df:	83 ea 04             	sub    $0x4,%edx
  1029e2:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1029e5:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  1029e8:	89 c7                	mov    %eax,%edi
  1029ea:	89 d6                	mov    %edx,%esi
  1029ec:	fd                   	std    
  1029ed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1029ef:	eb 18                	jmp    102a09 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  1029f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1029f4:	8d 50 ff             	lea    -0x1(%eax),%edx
  1029f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1029fa:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  1029fd:	8b 45 10             	mov    0x10(%ebp),%eax
  102a00:	89 d7                	mov    %edx,%edi
  102a02:	89 de                	mov    %ebx,%esi
  102a04:	89 c1                	mov    %eax,%ecx
  102a06:	fd                   	std    
  102a07:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  102a09:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  102a0a:	eb 45                	jmp    102a51 <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102a0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102a0f:	83 e0 03             	and    $0x3,%eax
  102a12:	85 c0                	test   %eax,%eax
  102a14:	75 2b                	jne    102a41 <memmove+0xc0>
  102a16:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a19:	83 e0 03             	and    $0x3,%eax
  102a1c:	85 c0                	test   %eax,%eax
  102a1e:	75 21                	jne    102a41 <memmove+0xc0>
  102a20:	8b 45 10             	mov    0x10(%ebp),%eax
  102a23:	83 e0 03             	and    $0x3,%eax
  102a26:	85 c0                	test   %eax,%eax
  102a28:	75 17                	jne    102a41 <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  102a2a:	8b 45 10             	mov    0x10(%ebp),%eax
  102a2d:	89 c1                	mov    %eax,%ecx
  102a2f:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  102a32:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a35:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102a38:	89 c7                	mov    %eax,%edi
  102a3a:	89 d6                	mov    %edx,%esi
  102a3c:	fc                   	cld    
  102a3d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102a3f:	eb 10                	jmp    102a51 <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  102a41:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a44:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102a47:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102a4a:	89 c7                	mov    %eax,%edi
  102a4c:	89 d6                	mov    %edx,%esi
  102a4e:	fc                   	cld    
  102a4f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  102a51:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102a54:	83 c4 10             	add    $0x10,%esp
  102a57:	5b                   	pop    %ebx
  102a58:	5e                   	pop    %esi
  102a59:	5f                   	pop    %edi
  102a5a:	5d                   	pop    %ebp
  102a5b:	c3                   	ret    

00102a5c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  102a5c:	55                   	push   %ebp
  102a5d:	89 e5                	mov    %esp,%ebp
  102a5f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  102a62:	8b 45 10             	mov    0x10(%ebp),%eax
  102a65:	89 44 24 08          	mov    %eax,0x8(%esp)
  102a69:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a6c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a70:	8b 45 08             	mov    0x8(%ebp),%eax
  102a73:	89 04 24             	mov    %eax,(%esp)
  102a76:	e8 06 ff ff ff       	call   102981 <memmove>
}
  102a7b:	c9                   	leave  
  102a7c:	c3                   	ret    

00102a7d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  102a7d:	55                   	push   %ebp
  102a7e:	89 e5                	mov    %esp,%ebp
  102a80:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  102a83:	8b 45 08             	mov    0x8(%ebp),%eax
  102a86:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  102a89:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a8c:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  102a8f:	eb 32                	jmp    102ac3 <memcmp+0x46>
		if (*s1 != *s2)
  102a91:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102a94:	0f b6 10             	movzbl (%eax),%edx
  102a97:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102a9a:	0f b6 00             	movzbl (%eax),%eax
  102a9d:	38 c2                	cmp    %al,%dl
  102a9f:	74 1a                	je     102abb <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  102aa1:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102aa4:	0f b6 00             	movzbl (%eax),%eax
  102aa7:	0f b6 d0             	movzbl %al,%edx
  102aaa:	8b 45 fc             	mov    -0x4(%ebp),%eax
  102aad:	0f b6 00             	movzbl (%eax),%eax
  102ab0:	0f b6 c0             	movzbl %al,%eax
  102ab3:	89 d1                	mov    %edx,%ecx
  102ab5:	29 c1                	sub    %eax,%ecx
  102ab7:	89 c8                	mov    %ecx,%eax
  102ab9:	eb 1c                	jmp    102ad7 <memcmp+0x5a>
		s1++, s2++;
  102abb:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  102abf:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  102ac3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102ac7:	0f 95 c0             	setne  %al
  102aca:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102ace:	84 c0                	test   %al,%al
  102ad0:	75 bf                	jne    102a91 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  102ad2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102ad7:	c9                   	leave  
  102ad8:	c3                   	ret    

00102ad9 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  102ad9:	55                   	push   %ebp
  102ada:	89 e5                	mov    %esp,%ebp
  102adc:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  102adf:	8b 45 10             	mov    0x10(%ebp),%eax
  102ae2:	8b 55 08             	mov    0x8(%ebp),%edx
  102ae5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102ae8:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  102aeb:	eb 16                	jmp    102b03 <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  102aed:	8b 45 08             	mov    0x8(%ebp),%eax
  102af0:	0f b6 10             	movzbl (%eax),%edx
  102af3:	8b 45 0c             	mov    0xc(%ebp),%eax
  102af6:	38 c2                	cmp    %al,%dl
  102af8:	75 05                	jne    102aff <memchr+0x26>
			return (void *) s;
  102afa:	8b 45 08             	mov    0x8(%ebp),%eax
  102afd:	eb 11                	jmp    102b10 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  102aff:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102b03:	8b 45 08             	mov    0x8(%ebp),%eax
  102b06:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  102b09:	72 e2                	jb     102aed <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  102b0b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102b10:	c9                   	leave  
  102b11:	c3                   	ret    
  102b12:	66 90                	xchg   %ax,%ax
  102b14:	66 90                	xchg   %ax,%ax
  102b16:	66 90                	xchg   %ax,%ax
  102b18:	66 90                	xchg   %ax,%ax
  102b1a:	66 90                	xchg   %ax,%ax
  102b1c:	66 90                	xchg   %ax,%ax
  102b1e:	66 90                	xchg   %ax,%ax

00102b20 <__udivdi3>:
  102b20:	55                   	push   %ebp
  102b21:	89 e5                	mov    %esp,%ebp
  102b23:	57                   	push   %edi
  102b24:	56                   	push   %esi
  102b25:	83 ec 10             	sub    $0x10,%esp
  102b28:	8b 45 14             	mov    0x14(%ebp),%eax
  102b2b:	8b 55 08             	mov    0x8(%ebp),%edx
  102b2e:	8b 75 10             	mov    0x10(%ebp),%esi
  102b31:	8b 7d 0c             	mov    0xc(%ebp),%edi
  102b34:	85 c0                	test   %eax,%eax
  102b36:	89 55 f0             	mov    %edx,-0x10(%ebp)
  102b39:	75 35                	jne    102b70 <__udivdi3+0x50>
  102b3b:	39 fe                	cmp    %edi,%esi
  102b3d:	77 61                	ja     102ba0 <__udivdi3+0x80>
  102b3f:	85 f6                	test   %esi,%esi
  102b41:	75 0b                	jne    102b4e <__udivdi3+0x2e>
  102b43:	b8 01 00 00 00       	mov    $0x1,%eax
  102b48:	31 d2                	xor    %edx,%edx
  102b4a:	f7 f6                	div    %esi
  102b4c:	89 c6                	mov    %eax,%esi
  102b4e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  102b51:	31 d2                	xor    %edx,%edx
  102b53:	89 f8                	mov    %edi,%eax
  102b55:	f7 f6                	div    %esi
  102b57:	89 c7                	mov    %eax,%edi
  102b59:	89 c8                	mov    %ecx,%eax
  102b5b:	f7 f6                	div    %esi
  102b5d:	89 c1                	mov    %eax,%ecx
  102b5f:	89 fa                	mov    %edi,%edx
  102b61:	89 c8                	mov    %ecx,%eax
  102b63:	83 c4 10             	add    $0x10,%esp
  102b66:	5e                   	pop    %esi
  102b67:	5f                   	pop    %edi
  102b68:	5d                   	pop    %ebp
  102b69:	c3                   	ret    
  102b6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  102b70:	39 f8                	cmp    %edi,%eax
  102b72:	77 1c                	ja     102b90 <__udivdi3+0x70>
  102b74:	0f bd d0             	bsr    %eax,%edx
  102b77:	83 f2 1f             	xor    $0x1f,%edx
  102b7a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102b7d:	75 39                	jne    102bb8 <__udivdi3+0x98>
  102b7f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  102b82:	0f 86 a0 00 00 00    	jbe    102c28 <__udivdi3+0x108>
  102b88:	39 f8                	cmp    %edi,%eax
  102b8a:	0f 82 98 00 00 00    	jb     102c28 <__udivdi3+0x108>
  102b90:	31 ff                	xor    %edi,%edi
  102b92:	31 c9                	xor    %ecx,%ecx
  102b94:	89 c8                	mov    %ecx,%eax
  102b96:	89 fa                	mov    %edi,%edx
  102b98:	83 c4 10             	add    $0x10,%esp
  102b9b:	5e                   	pop    %esi
  102b9c:	5f                   	pop    %edi
  102b9d:	5d                   	pop    %ebp
  102b9e:	c3                   	ret    
  102b9f:	90                   	nop
  102ba0:	89 d1                	mov    %edx,%ecx
  102ba2:	89 fa                	mov    %edi,%edx
  102ba4:	89 c8                	mov    %ecx,%eax
  102ba6:	31 ff                	xor    %edi,%edi
  102ba8:	f7 f6                	div    %esi
  102baa:	89 c1                	mov    %eax,%ecx
  102bac:	89 fa                	mov    %edi,%edx
  102bae:	89 c8                	mov    %ecx,%eax
  102bb0:	83 c4 10             	add    $0x10,%esp
  102bb3:	5e                   	pop    %esi
  102bb4:	5f                   	pop    %edi
  102bb5:	5d                   	pop    %ebp
  102bb6:	c3                   	ret    
  102bb7:	90                   	nop
  102bb8:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102bbc:	89 f2                	mov    %esi,%edx
  102bbe:	d3 e0                	shl    %cl,%eax
  102bc0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  102bc3:	b8 20 00 00 00       	mov    $0x20,%eax
  102bc8:	2b 45 f4             	sub    -0xc(%ebp),%eax
  102bcb:	89 c1                	mov    %eax,%ecx
  102bcd:	d3 ea                	shr    %cl,%edx
  102bcf:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102bd3:	0b 55 ec             	or     -0x14(%ebp),%edx
  102bd6:	d3 e6                	shl    %cl,%esi
  102bd8:	89 c1                	mov    %eax,%ecx
  102bda:	89 75 e8             	mov    %esi,-0x18(%ebp)
  102bdd:	89 fe                	mov    %edi,%esi
  102bdf:	d3 ee                	shr    %cl,%esi
  102be1:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102be5:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102be8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102beb:	d3 e7                	shl    %cl,%edi
  102bed:	89 c1                	mov    %eax,%ecx
  102bef:	d3 ea                	shr    %cl,%edx
  102bf1:	09 d7                	or     %edx,%edi
  102bf3:	89 f2                	mov    %esi,%edx
  102bf5:	89 f8                	mov    %edi,%eax
  102bf7:	f7 75 ec             	divl   -0x14(%ebp)
  102bfa:	89 d6                	mov    %edx,%esi
  102bfc:	89 c7                	mov    %eax,%edi
  102bfe:	f7 65 e8             	mull   -0x18(%ebp)
  102c01:	39 d6                	cmp    %edx,%esi
  102c03:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102c06:	72 30                	jb     102c38 <__udivdi3+0x118>
  102c08:	8b 55 f0             	mov    -0x10(%ebp),%edx
  102c0b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  102c0f:	d3 e2                	shl    %cl,%edx
  102c11:	39 c2                	cmp    %eax,%edx
  102c13:	73 05                	jae    102c1a <__udivdi3+0xfa>
  102c15:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  102c18:	74 1e                	je     102c38 <__udivdi3+0x118>
  102c1a:	89 f9                	mov    %edi,%ecx
  102c1c:	31 ff                	xor    %edi,%edi
  102c1e:	e9 71 ff ff ff       	jmp    102b94 <__udivdi3+0x74>
  102c23:	90                   	nop
  102c24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102c28:	31 ff                	xor    %edi,%edi
  102c2a:	b9 01 00 00 00       	mov    $0x1,%ecx
  102c2f:	e9 60 ff ff ff       	jmp    102b94 <__udivdi3+0x74>
  102c34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102c38:	8d 4f ff             	lea    -0x1(%edi),%ecx
  102c3b:	31 ff                	xor    %edi,%edi
  102c3d:	89 c8                	mov    %ecx,%eax
  102c3f:	89 fa                	mov    %edi,%edx
  102c41:	83 c4 10             	add    $0x10,%esp
  102c44:	5e                   	pop    %esi
  102c45:	5f                   	pop    %edi
  102c46:	5d                   	pop    %ebp
  102c47:	c3                   	ret    
  102c48:	66 90                	xchg   %ax,%ax
  102c4a:	66 90                	xchg   %ax,%ax
  102c4c:	66 90                	xchg   %ax,%ax
  102c4e:	66 90                	xchg   %ax,%ax

00102c50 <__umoddi3>:
  102c50:	55                   	push   %ebp
  102c51:	89 e5                	mov    %esp,%ebp
  102c53:	57                   	push   %edi
  102c54:	56                   	push   %esi
  102c55:	83 ec 20             	sub    $0x20,%esp
  102c58:	8b 55 14             	mov    0x14(%ebp),%edx
  102c5b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102c5e:	8b 7d 10             	mov    0x10(%ebp),%edi
  102c61:	8b 75 0c             	mov    0xc(%ebp),%esi
  102c64:	85 d2                	test   %edx,%edx
  102c66:	89 c8                	mov    %ecx,%eax
  102c68:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  102c6b:	75 13                	jne    102c80 <__umoddi3+0x30>
  102c6d:	39 f7                	cmp    %esi,%edi
  102c6f:	76 3f                	jbe    102cb0 <__umoddi3+0x60>
  102c71:	89 f2                	mov    %esi,%edx
  102c73:	f7 f7                	div    %edi
  102c75:	89 d0                	mov    %edx,%eax
  102c77:	31 d2                	xor    %edx,%edx
  102c79:	83 c4 20             	add    $0x20,%esp
  102c7c:	5e                   	pop    %esi
  102c7d:	5f                   	pop    %edi
  102c7e:	5d                   	pop    %ebp
  102c7f:	c3                   	ret    
  102c80:	39 f2                	cmp    %esi,%edx
  102c82:	77 4c                	ja     102cd0 <__umoddi3+0x80>
  102c84:	0f bd ca             	bsr    %edx,%ecx
  102c87:	83 f1 1f             	xor    $0x1f,%ecx
  102c8a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  102c8d:	75 51                	jne    102ce0 <__umoddi3+0x90>
  102c8f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  102c92:	0f 87 e0 00 00 00    	ja     102d78 <__umoddi3+0x128>
  102c98:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c9b:	29 f8                	sub    %edi,%eax
  102c9d:	19 d6                	sbb    %edx,%esi
  102c9f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102ca2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ca5:	89 f2                	mov    %esi,%edx
  102ca7:	83 c4 20             	add    $0x20,%esp
  102caa:	5e                   	pop    %esi
  102cab:	5f                   	pop    %edi
  102cac:	5d                   	pop    %ebp
  102cad:	c3                   	ret    
  102cae:	66 90                	xchg   %ax,%ax
  102cb0:	85 ff                	test   %edi,%edi
  102cb2:	75 0b                	jne    102cbf <__umoddi3+0x6f>
  102cb4:	b8 01 00 00 00       	mov    $0x1,%eax
  102cb9:	31 d2                	xor    %edx,%edx
  102cbb:	f7 f7                	div    %edi
  102cbd:	89 c7                	mov    %eax,%edi
  102cbf:	89 f0                	mov    %esi,%eax
  102cc1:	31 d2                	xor    %edx,%edx
  102cc3:	f7 f7                	div    %edi
  102cc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102cc8:	f7 f7                	div    %edi
  102cca:	eb a9                	jmp    102c75 <__umoddi3+0x25>
  102ccc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102cd0:	89 c8                	mov    %ecx,%eax
  102cd2:	89 f2                	mov    %esi,%edx
  102cd4:	83 c4 20             	add    $0x20,%esp
  102cd7:	5e                   	pop    %esi
  102cd8:	5f                   	pop    %edi
  102cd9:	5d                   	pop    %ebp
  102cda:	c3                   	ret    
  102cdb:	90                   	nop
  102cdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102ce0:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102ce4:	d3 e2                	shl    %cl,%edx
  102ce6:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102ce9:	ba 20 00 00 00       	mov    $0x20,%edx
  102cee:	2b 55 f0             	sub    -0x10(%ebp),%edx
  102cf1:	89 55 ec             	mov    %edx,-0x14(%ebp)
  102cf4:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102cf8:	89 fa                	mov    %edi,%edx
  102cfa:	d3 ea                	shr    %cl,%edx
  102cfc:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102d00:	0b 55 f4             	or     -0xc(%ebp),%edx
  102d03:	d3 e7                	shl    %cl,%edi
  102d05:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102d09:	89 55 f4             	mov    %edx,-0xc(%ebp)
  102d0c:	89 f2                	mov    %esi,%edx
  102d0e:	89 7d e8             	mov    %edi,-0x18(%ebp)
  102d11:	89 c7                	mov    %eax,%edi
  102d13:	d3 ea                	shr    %cl,%edx
  102d15:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102d19:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  102d1c:	89 c2                	mov    %eax,%edx
  102d1e:	d3 e6                	shl    %cl,%esi
  102d20:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102d24:	d3 ea                	shr    %cl,%edx
  102d26:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102d2a:	09 d6                	or     %edx,%esi
  102d2c:	89 f0                	mov    %esi,%eax
  102d2e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  102d31:	d3 e7                	shl    %cl,%edi
  102d33:	89 f2                	mov    %esi,%edx
  102d35:	f7 75 f4             	divl   -0xc(%ebp)
  102d38:	89 d6                	mov    %edx,%esi
  102d3a:	f7 65 e8             	mull   -0x18(%ebp)
  102d3d:	39 d6                	cmp    %edx,%esi
  102d3f:	72 2b                	jb     102d6c <__umoddi3+0x11c>
  102d41:	39 c7                	cmp    %eax,%edi
  102d43:	72 23                	jb     102d68 <__umoddi3+0x118>
  102d45:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102d49:	29 c7                	sub    %eax,%edi
  102d4b:	19 d6                	sbb    %edx,%esi
  102d4d:	89 f0                	mov    %esi,%eax
  102d4f:	89 f2                	mov    %esi,%edx
  102d51:	d3 ef                	shr    %cl,%edi
  102d53:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  102d57:	d3 e0                	shl    %cl,%eax
  102d59:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  102d5d:	09 f8                	or     %edi,%eax
  102d5f:	d3 ea                	shr    %cl,%edx
  102d61:	83 c4 20             	add    $0x20,%esp
  102d64:	5e                   	pop    %esi
  102d65:	5f                   	pop    %edi
  102d66:	5d                   	pop    %ebp
  102d67:	c3                   	ret    
  102d68:	39 d6                	cmp    %edx,%esi
  102d6a:	75 d9                	jne    102d45 <__umoddi3+0xf5>
  102d6c:	2b 45 e8             	sub    -0x18(%ebp),%eax
  102d6f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  102d72:	eb d1                	jmp    102d45 <__umoddi3+0xf5>
  102d74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  102d78:	39 f2                	cmp    %esi,%edx
  102d7a:	0f 82 18 ff ff ff    	jb     102c98 <__umoddi3+0x48>
  102d80:	e9 1d ff ff ff       	jmp    102ca2 <__umoddi3+0x52>
