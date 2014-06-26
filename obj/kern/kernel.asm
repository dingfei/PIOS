
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
  100050:	c7 44 24 0c 00 86 10 	movl   $0x108600,0xc(%esp)
  100057:	00 
  100058:	c7 44 24 08 16 86 10 	movl   $0x108616,0x8(%esp)
  10005f:	00 
  100060:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100067:	00 
  100068:	c7 04 24 2b 86 10 00 	movl   $0x10862b,(%esp)
  10006f:	e8 ba 07 00 00       	call   10082e <debug_panic>
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
  100095:	83 ec 24             	sub    $0x24,%esp
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
  1000a6:	b8 ac 85 11 00       	mov    $0x1185ac,%eax
  1000ab:	89 d1                	mov    %edx,%ecx
  1000ad:	29 c1                	sub    %eax,%ecx
  1000af:	89 c8                	mov    %ecx,%eax
  1000b1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000bc:	00 
  1000bd:	c7 04 24 ac 85 11 00 	movl   $0x1185ac,(%esp)
  1000c4:	e8 ad 80 00 00       	call   108176 <memset>
	//cprintf("1\n");

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000c9:	e8 73 06 00 00       	call   100741 <cons_init>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	//cprintf("1\n");
	cpu_init();
  1000ce:	e8 de 13 00 00       	call   1014b1 <cpu_init>
	//cprintf("1\n");
	trap_init();
  1000d3:	e8 22 19 00 00       	call   1019fa <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000d8:	e8 0b 0c 00 00       	call   100ce8 <mem_init>

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  1000dd:	e8 97 ff ff ff       	call   100079 <cpu_onboot>
  1000e2:	85 c0                	test   %eax,%eax
  1000e4:	74 05                	je     1000eb <init+0x5a>
		spinlock_check();
  1000e6:	e8 4c 27 00 00       	call   102837 <spinlock_check>

	// Initialize the paged virtual memory system.
	pmap_init();
  1000eb:	e8 d4 40 00 00       	call   1041c4 <pmap_init>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000f0:	e8 e2 23 00 00       	call   1024d7 <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000f5:	e8 84 6f 00 00       	call   10707e <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000fa:	e8 b2 75 00 00       	call   1076b1 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000ff:	e8 5d 72 00 00       	call   107361 <lapic_init>
		// Initialize the process management code.
	proc_init();
  100104:	e8 79 2d 00 00       	call   102e82 <proc_init>
	cpu_bootothers();	// Get other processors started
  100109:	e8 72 15 00 00       	call   101680 <cpu_bootothers>
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
  100117:	bb 38 86 10 00       	mov    $0x108638,%ebx
  10011c:	eb 05                	jmp    100123 <init+0x92>
  10011e:	bb 3b 86 10 00       	mov    $0x10863b,%ebx
  100123:	e8 fe fe ff ff       	call   100026 <cpu_cur>
  100128:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10012f:	0f b6 c0             	movzbl %al,%eax
  100132:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  100136:	89 44 24 04          	mov    %eax,0x4(%esp)
  10013a:	c7 04 24 3e 86 10 00 	movl   $0x10863e,(%esp)
  100141:	e8 4b 7e 00 00       	call   107f91 <cprintf>
		proc_ready(proc_root);	
	}
	*/

	
	if(cpu_onboot()){
  100146:	e8 2e ff ff ff       	call   100079 <cpu_onboot>
  10014b:	85 c0                	test   %eax,%eax
  10014d:	0f 84 e8 00 00 00    	je     10023b <init+0x1aa>
		proc_root = proc_alloc(&proc_null, 0);
  100153:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10015a:	00 
  10015b:	c7 04 24 80 ed 31 00 	movl   $0x31ed80,(%esp)
  100162:	e8 69 2d 00 00       	call   102ed0 <proc_alloc>
  100167:	a3 84 f4 31 00       	mov    %eax,0x31f484
		elf_binary_loader(ROOTEXE_START, proc_root->pdir);
  10016c:	a1 84 f4 31 00       	mov    0x31f484,%eax
  100171:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  100177:	89 44 24 04          	mov    %eax,0x4(%esp)
  10017b:	c7 04 24 32 c6 10 00 	movl   $0x10c632,(%esp)
  100182:	e8 b9 00 00 00       	call   100240 <elf_binary_loader>
		memset(mem_ptr(VM_USERHI - PAGESIZE), 0, PAGESIZE);
  100187:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10018e:	00 
  10018f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100196:	00 
  100197:	c7 04 24 00 f0 ff ef 	movl   $0xeffff000,(%esp)
  10019e:	e8 d3 7f 00 00       	call   108176 <memset>
		proc_root->sv.tf.eip = (uint32_t)(0x40000100);
  1001a3:	a1 84 f4 31 00       	mov    0x31f484,%eax
  1001a8:	c7 80 88 04 00 00 00 	movl   $0x40000100,0x488(%eax)
  1001af:	01 00 40 
		proc_root->sv.tf.esp = (uint32_t)(VM_USERHI -1);
  1001b2:	a1 84 f4 31 00       	mov    0x31f484,%eax
  1001b7:	c7 80 94 04 00 00 ff 	movl   $0xefffffff,0x494(%eax)
  1001be:	ff ff ef 
		proc_root->sv.tf.eflags = FL_IOPL_3;
  1001c1:	a1 84 f4 31 00       	mov    0x31f484,%eax
  1001c6:	c7 80 90 04 00 00 00 	movl   $0x3000,0x490(%eax)
  1001cd:	30 00 00 
		proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
  1001d0:	a1 84 f4 31 00       	mov    0x31f484,%eax
  1001d5:	66 c7 80 70 04 00 00 	movw   $0x23,0x470(%eax)
  1001dc:	23 00 
		proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;
  1001de:	a1 84 f4 31 00       	mov    0x31f484,%eax
  1001e3:	66 c7 80 74 04 00 00 	movw   $0x23,0x474(%eax)
  1001ea:	23 00 

		pte_t* pte = pmap_walk(proc_root->pdir, 0x40000100, 0);
  1001ec:	a1 84 f4 31 00       	mov    0x31f484,%eax
  1001f1:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1001f7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1001fe:	00 
  1001ff:	c7 44 24 04 00 01 00 	movl   $0x40000100,0x4(%esp)
  100206:	40 
  100207:	89 04 24             	mov    %eax,(%esp)
  10020a:	e8 be 43 00 00       	call   1045cd <pmap_walk>
  10020f:	89 45 f4             	mov    %eax,-0xc(%ebp)
		cprintf("0x40000100's pte is %x @ %p\n", *pte, pte);
  100212:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100215:	8b 00                	mov    (%eax),%eax
  100217:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10021a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10021e:	89 44 24 04          	mov    %eax,0x4(%esp)
  100222:	c7 04 24 56 86 10 00 	movl   $0x108656,(%esp)
  100229:	e8 63 7d 00 00       	call   107f91 <cprintf>

		proc_ready(proc_root);	
  10022e:	a1 84 f4 31 00       	mov    0x31f484,%eax
  100233:	89 04 24             	mov    %eax,(%esp)
  100236:	e8 8b 2e 00 00       	call   1030c6 <proc_ready>
	}

	
	proc_sched();
  10023b:	e8 04 31 00 00       	call   103344 <proc_sched>

00100240 <elf_binary_loader>:
}


void
elf_binary_loader(char* elf, pde_t* pdir)
{
  100240:	55                   	push   %ebp
  100241:	89 e5                	mov    %esp,%ebp
  100243:	83 ec 58             	sub    $0x58,%esp
	cprintf("======================elf load begin!\n");
  100246:	c7 04 24 74 86 10 00 	movl   $0x108674,(%esp)
  10024d:	e8 3f 7d 00 00       	call   107f91 <cprintf>

	elfhdr* eh = (elfhdr*)elf;
  100252:	8b 45 08             	mov    0x8(%ebp),%eax
  100255:	89 45 bc             	mov    %eax,-0x44(%ebp)
	
	sechdr* sh_start = (sechdr*)(elf + eh->e_shoff);
  100258:	8b 55 08             	mov    0x8(%ebp),%edx
  10025b:	8b 45 bc             	mov    -0x44(%ebp),%eax
  10025e:	8b 40 20             	mov    0x20(%eax),%eax
  100261:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100264:	89 45 c0             	mov    %eax,-0x40(%ebp)
	uint16_t shnum = eh->e_shnum;
  100267:	8b 45 bc             	mov    -0x44(%ebp),%eax
  10026a:	0f b7 40 30          	movzwl 0x30(%eax),%eax
  10026e:	66 89 45 c4          	mov    %ax,-0x3c(%ebp)
	uint16_t i = 0;
  100272:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
	sechdr* sh = sh_start;
  100278:	8b 45 c0             	mov    -0x40(%ebp),%eax
  10027b:	89 45 c8             	mov    %eax,-0x38(%ebp)

	lcr3(mem_phys(pdir));
  10027e:	8b 45 0c             	mov    0xc(%ebp),%eax
  100281:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  100284:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100287:	0f 22 d8             	mov    %eax,%cr3

	// first, alloc pages for each sections according to the section header
	//cprintf("tag1=======================\n", i);

	for(; i < shnum; i++, sh++){
  10028a:	e9 e3 00 00 00       	jmp    100372 <elf_binary_loader+0x132>
		//cprintf("i = %d =======================\n", i);
			if ((sh->sh_type != ELF_SHT_PROGBITS) &&
  10028f:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100292:	8b 40 04             	mov    0x4(%eax),%eax
  100295:	83 f8 01             	cmp    $0x1,%eax
  100298:	74 0f                	je     1002a9 <elf_binary_loader+0x69>
					(sh->sh_type != ELF_SHT_NOBITS)) {
  10029a:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10029d:	8b 40 04             	mov    0x4(%eax),%eax
	// first, alloc pages for each sections according to the section header
	//cprintf("tag1=======================\n", i);

	for(; i < shnum; i++, sh++){
		//cprintf("i = %d =======================\n", i);
			if ((sh->sh_type != ELF_SHT_PROGBITS) &&
  1002a0:	83 f8 08             	cmp    $0x8,%eax
  1002a3:	0f 85 bc 00 00 00    	jne    100365 <elf_binary_loader+0x125>
					(sh->sh_type != ELF_SHT_NOBITS)) {
						continue;
			}
			
			if (sh->sh_addr == 0x0) {
  1002a9:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1002ac:	8b 40 0c             	mov    0xc(%eax),%eax
  1002af:	85 c0                	test   %eax,%eax
  1002b1:	0f 84 b1 00 00 00    	je     100368 <elf_binary_loader+0x128>
				continue;
			}

		uint32_t va_start_page = sh->sh_addr & ~0xfff;
  1002b7:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1002ba:	8b 40 0c             	mov    0xc(%eax),%eax
  1002bd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1002c2:	89 45 cc             	mov    %eax,-0x34(%ebp)
		uint32_t va_end_page = (sh->sh_addr + sh->sh_size) & ~0xfff;
  1002c5:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1002c8:	8b 50 0c             	mov    0xc(%eax),%edx
  1002cb:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1002ce:	8b 40 14             	mov    0x14(%eax),%eax
  1002d1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1002d4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1002d9:	89 45 d0             	mov    %eax,-0x30(%ebp)
		uint32_t va = va_start_page;
  1002dc:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1002df:	89 45 d4             	mov    %eax,-0x2c(%ebp)

		cprintf("va_start_page = %x, va_end_page = %x\n", va_start_page, va_end_page);
  1002e2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1002e5:	89 44 24 08          	mov    %eax,0x8(%esp)
  1002e9:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1002ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  1002f0:	c7 04 24 9c 86 10 00 	movl   $0x10869c,(%esp)
  1002f7:	e8 95 7c 00 00       	call   107f91 <cprintf>

		for(; va <= va_end_page; va += PAGESIZE){
  1002fc:	eb 5d                	jmp    10035b <elf_binary_loader+0x11b>
			cprintf("va = %x\n", va);
  1002fe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100301:	89 44 24 04          	mov    %eax,0x4(%esp)
  100305:	c7 04 24 c2 86 10 00 	movl   $0x1086c2,(%esp)
  10030c:	e8 80 7c 00 00       	call   107f91 <cprintf>
			if(!pmap_insert(pdir, mem_alloc(), va, PTE_W | PTE_U))
  100311:	e8 a4 0b 00 00       	call   100eba <mem_alloc>
  100316:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  10031d:	00 
  10031e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  100321:	89 54 24 08          	mov    %edx,0x8(%esp)
  100325:	89 44 24 04          	mov    %eax,0x4(%esp)
  100329:	8b 45 0c             	mov    0xc(%ebp),%eax
  10032c:	89 04 24             	mov    %eax,(%esp)
  10032f:	e8 94 44 00 00       	call   1047c8 <pmap_insert>
  100334:	85 c0                	test   %eax,%eax
  100336:	75 1c                	jne    100354 <elf_binary_loader+0x114>
				panic("in elf loader: pmap_insert failed!\n");
  100338:	c7 44 24 08 cc 86 10 	movl   $0x1086cc,0x8(%esp)
  10033f:	00 
  100340:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
  100347:	00 
  100348:	c7 04 24 f0 86 10 00 	movl   $0x1086f0,(%esp)
  10034f:	e8 da 04 00 00       	call   10082e <debug_panic>
		uint32_t va_end_page = (sh->sh_addr + sh->sh_size) & ~0xfff;
		uint32_t va = va_start_page;

		cprintf("va_start_page = %x, va_end_page = %x\n", va_start_page, va_end_page);

		for(; va <= va_end_page; va += PAGESIZE){
  100354:	81 45 d4 00 10 00 00 	addl   $0x1000,-0x2c(%ebp)
  10035b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10035e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  100361:	76 9b                	jbe    1002fe <elf_binary_loader+0xbe>
  100363:	eb 04                	jmp    100369 <elf_binary_loader+0x129>

	for(; i < shnum; i++, sh++){
		//cprintf("i = %d =======================\n", i);
			if ((sh->sh_type != ELF_SHT_PROGBITS) &&
					(sh->sh_type != ELF_SHT_NOBITS)) {
						continue;
  100365:	90                   	nop
  100366:	eb 01                	jmp    100369 <elf_binary_loader+0x129>
			}
			
			if (sh->sh_addr == 0x0) {
				continue;
  100368:	90                   	nop
	lcr3(mem_phys(pdir));

	// first, alloc pages for each sections according to the section header
	//cprintf("tag1=======================\n", i);

	for(; i < shnum; i++, sh++){
  100369:	66 83 45 c6 01       	addw   $0x1,-0x3a(%ebp)
  10036e:	83 45 c8 28          	addl   $0x28,-0x38(%ebp)
  100372:	0f b7 45 c6          	movzwl -0x3a(%ebp),%eax
  100376:	66 3b 45 c4          	cmp    -0x3c(%ebp),%ax
  10037a:	0f 82 0f ff ff ff    	jb     10028f <elf_binary_loader+0x4f>
	}

	//then, write data into pages according to the context of the sections
	//cprintf("tag2=======================\n", i);

	sh = sh_start;
  100380:	8b 45 c0             	mov    -0x40(%ebp),%eax
  100383:	89 45 c8             	mov    %eax,-0x38(%ebp)
	i = 0;
  100386:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
	for(; i < shnum; i++, sh++){
  10038c:	e9 90 00 00 00       	jmp    100421 <elf_binary_loader+0x1e1>
		if ((sh->sh_type != ELF_SHT_PROGBITS) &&
  100391:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100394:	8b 40 04             	mov    0x4(%eax),%eax
  100397:	83 f8 01             	cmp    $0x1,%eax
  10039a:	74 0b                	je     1003a7 <elf_binary_loader+0x167>
				(sh->sh_type != ELF_SHT_NOBITS)) {
  10039c:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10039f:	8b 40 04             	mov    0x4(%eax),%eax
	//cprintf("tag2=======================\n", i);

	sh = sh_start;
	i = 0;
	for(; i < shnum; i++, sh++){
		if ((sh->sh_type != ELF_SHT_PROGBITS) &&
  1003a2:	83 f8 08             	cmp    $0x8,%eax
  1003a5:	75 6d                	jne    100414 <elf_binary_loader+0x1d4>
				(sh->sh_type != ELF_SHT_NOBITS)) {
					continue;
		}
			
		if (sh->sh_addr == 0x0) {
  1003a7:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1003aa:	8b 40 0c             	mov    0xc(%eax),%eax
  1003ad:	85 c0                	test   %eax,%eax
  1003af:	74 66                	je     100417 <elf_binary_loader+0x1d7>
			continue;
		}
		
		uint32_t sec_start = (uint32_t)elf + sh->sh_offset;
  1003b1:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1003b4:	8b 50 10             	mov    0x10(%eax),%edx
  1003b7:	8b 45 08             	mov    0x8(%ebp),%eax
  1003ba:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1003bd:	89 45 d8             	mov    %eax,-0x28(%ebp)
		uint32_t sec_size = sh->sh_size;
  1003c0:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1003c3:	8b 40 14             	mov    0x14(%eax),%eax
  1003c6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		uint32_t va_start = sh->sh_addr;
  1003c9:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1003cc:	8b 40 0c             	mov    0xc(%eax),%eax
  1003cf:	89 45 e0             	mov    %eax,-0x20(%ebp)
		
		if(sh->sh_type == ELF_SHT_PROGBITS)
  1003d2:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1003d5:	8b 40 04             	mov    0x4(%eax),%eax
  1003d8:	83 f8 01             	cmp    $0x1,%eax
  1003db:	75 1b                	jne    1003f8 <elf_binary_loader+0x1b8>
			memcpy((char*)va_start, (char*)sec_start, sec_size);
  1003dd:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1003e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1003e3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1003e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1003ea:	89 54 24 04          	mov    %edx,0x4(%esp)
  1003ee:	89 04 24             	mov    %eax,(%esp)
  1003f1:	e8 cf 7e 00 00       	call   1082c5 <memcpy>
  1003f6:	eb 20                	jmp    100418 <elf_binary_loader+0x1d8>
		else 
			memset((char*)va_start, 0, sec_size);
  1003f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1003fb:	8b 55 dc             	mov    -0x24(%ebp),%edx
  1003fe:	89 54 24 08          	mov    %edx,0x8(%esp)
  100402:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100409:	00 
  10040a:	89 04 24             	mov    %eax,(%esp)
  10040d:	e8 64 7d 00 00       	call   108176 <memset>
  100412:	eb 04                	jmp    100418 <elf_binary_loader+0x1d8>
	sh = sh_start;
	i = 0;
	for(; i < shnum; i++, sh++){
		if ((sh->sh_type != ELF_SHT_PROGBITS) &&
				(sh->sh_type != ELF_SHT_NOBITS)) {
					continue;
  100414:	90                   	nop
  100415:	eb 01                	jmp    100418 <elf_binary_loader+0x1d8>
		}
			
		if (sh->sh_addr == 0x0) {
			continue;
  100417:	90                   	nop
	//then, write data into pages according to the context of the sections
	//cprintf("tag2=======================\n", i);

	sh = sh_start;
	i = 0;
	for(; i < shnum; i++, sh++){
  100418:	66 83 45 c6 01       	addw   $0x1,-0x3a(%ebp)
  10041d:	83 45 c8 28          	addl   $0x28,-0x38(%ebp)
  100421:	0f b7 45 c6          	movzwl -0x3a(%ebp),%eax
  100425:	66 3b 45 c4          	cmp    -0x3c(%ebp),%ax
  100429:	0f 82 62 ff ff ff    	jb     100391 <elf_binary_loader+0x151>
	}

	//last, set flags correctly to each page
	//cprintf("tag3=======================\n", i);

	sh = sh_start;
  10042f:	8b 45 c0             	mov    -0x40(%ebp),%eax
  100432:	89 45 c8             	mov    %eax,-0x38(%ebp)
	i = 0;
  100435:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
	for(; i < shnum; i++, sh++){
  10043b:	e9 d2 00 00 00       	jmp    100512 <elf_binary_loader+0x2d2>
		//cprintf("in tag3 i = %d\n", i);
		if ((sh->sh_type != ELF_SHT_PROGBITS) &&
  100440:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100443:	8b 40 04             	mov    0x4(%eax),%eax
  100446:	83 f8 01             	cmp    $0x1,%eax
  100449:	74 0f                	je     10045a <elf_binary_loader+0x21a>
				(sh->sh_type != ELF_SHT_NOBITS)) {
  10044b:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10044e:	8b 40 04             	mov    0x4(%eax),%eax

	sh = sh_start;
	i = 0;
	for(; i < shnum; i++, sh++){
		//cprintf("in tag3 i = %d\n", i);
		if ((sh->sh_type != ELF_SHT_PROGBITS) &&
  100451:	83 f8 08             	cmp    $0x8,%eax
  100454:	0f 85 ab 00 00 00    	jne    100505 <elf_binary_loader+0x2c5>
				(sh->sh_type != ELF_SHT_NOBITS)) {
					continue;
		}
			
		if (sh->sh_addr == 0x0) {
  10045a:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10045d:	8b 40 0c             	mov    0xc(%eax),%eax
  100460:	85 c0                	test   %eax,%eax
  100462:	0f 84 a0 00 00 00    	je     100508 <elf_binary_loader+0x2c8>
			continue;
		}


		// if this section is Read-Only
		if(!(sh->sh_flags & ELF_SHF_WRITE)){
  100468:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10046b:	8b 40 08             	mov    0x8(%eax),%eax
  10046e:	83 e0 01             	and    $0x1,%eax
  100471:	85 c0                	test   %eax,%eax
  100473:	0f 85 90 00 00 00    	jne    100509 <elf_binary_loader+0x2c9>
			uint32_t va_start_page = sh->sh_addr & ~0xfff;
  100479:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10047c:	8b 40 0c             	mov    0xc(%eax),%eax
  10047f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100484:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			uint32_t va_end_page = (sh->sh_addr + sh->sh_size) & ~0xfff;
  100487:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10048a:	8b 50 0c             	mov    0xc(%eax),%edx
  10048d:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100490:	8b 40 14             	mov    0x14(%eax),%eax
  100493:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100496:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10049b:	89 45 e8             	mov    %eax,-0x18(%ebp)
			uint32_t va = va_start_page;
  10049e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1004a1:	89 45 ec             	mov    %eax,-0x14(%ebp)
			
			pte_t* pte;

			for(; va <= va_end_page; va += PAGESIZE){
  1004a4:	eb 55                	jmp    1004fb <elf_binary_loader+0x2bb>
				pte = pmap_walk(pdir, va, 0);
  1004a6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1004ad:	00 
  1004ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1004b1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004b5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004b8:	89 04 24             	mov    %eax,(%esp)
  1004bb:	e8 0d 41 00 00       	call   1045cd <pmap_walk>
  1004c0:	89 45 f0             	mov    %eax,-0x10(%ebp)

				if(!pte)
  1004c3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1004c7:	75 1c                	jne    1004e5 <elf_binary_loader+0x2a5>
					panic("in elf loader: pmap_walk failed!\n");
  1004c9:	c7 44 24 08 fc 86 10 	movl   $0x1086fc,0x8(%esp)
  1004d0:	00 
  1004d1:	c7 44 24 04 fa 00 00 	movl   $0xfa,0x4(%esp)
  1004d8:	00 
  1004d9:	c7 04 24 f0 86 10 00 	movl   $0x1086f0,(%esp)
  1004e0:	e8 49 03 00 00       	call   10082e <debug_panic>

				*pte &= ~PTE_W;
  1004e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004e8:	8b 00                	mov    (%eax),%eax
  1004ea:	89 c2                	mov    %eax,%edx
  1004ec:	83 e2 fd             	and    $0xfffffffd,%edx
  1004ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1004f2:	89 10                	mov    %edx,(%eax)
			uint32_t va_end_page = (sh->sh_addr + sh->sh_size) & ~0xfff;
			uint32_t va = va_start_page;
			
			pte_t* pte;

			for(; va <= va_end_page; va += PAGESIZE){
  1004f4:	81 45 ec 00 10 00 00 	addl   $0x1000,-0x14(%ebp)
  1004fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1004fe:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  100501:	76 a3                	jbe    1004a6 <elf_binary_loader+0x266>
  100503:	eb 04                	jmp    100509 <elf_binary_loader+0x2c9>
	i = 0;
	for(; i < shnum; i++, sh++){
		//cprintf("in tag3 i = %d\n", i);
		if ((sh->sh_type != ELF_SHT_PROGBITS) &&
				(sh->sh_type != ELF_SHT_NOBITS)) {
					continue;
  100505:	90                   	nop
  100506:	eb 01                	jmp    100509 <elf_binary_loader+0x2c9>
		}
			
		if (sh->sh_addr == 0x0) {
			continue;
  100508:	90                   	nop
	//last, set flags correctly to each page
	//cprintf("tag3=======================\n", i);

	sh = sh_start;
	i = 0;
	for(; i < shnum; i++, sh++){
  100509:	66 83 45 c6 01       	addw   $0x1,-0x3a(%ebp)
  10050e:	83 45 c8 28          	addl   $0x28,-0x38(%ebp)
  100512:	0f b7 45 c6          	movzwl -0x3a(%ebp),%eax
  100516:	66 3b 45 c4          	cmp    -0x3c(%ebp),%ax
  10051a:	0f 82 20 ff ff ff    	jb     100440 <elf_binary_loader+0x200>
			}
		}
	}

	//cprintf("tag4=======================\n", i);
	if(!pmap_insert(pdir, mem_alloc(), VM_USERHI - PAGESIZE, PTE_W | PTE_U | PTE_P))
  100520:	e8 95 09 00 00       	call   100eba <mem_alloc>
  100525:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
  10052c:	00 
  10052d:	c7 44 24 08 00 f0 ff 	movl   $0xeffff000,0x8(%esp)
  100534:	ef 
  100535:	89 44 24 04          	mov    %eax,0x4(%esp)
  100539:	8b 45 0c             	mov    0xc(%ebp),%eax
  10053c:	89 04 24             	mov    %eax,(%esp)
  10053f:	e8 84 42 00 00       	call   1047c8 <pmap_insert>
  100544:	85 c0                	test   %eax,%eax
  100546:	75 1c                	jne    100564 <elf_binary_loader+0x324>
		panic("in elf loader: STACK alloc failed!\n");
  100548:	c7 44 24 08 20 87 10 	movl   $0x108720,0x8(%esp)
  10054f:	00 
  100550:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  100557:	00 
  100558:	c7 04 24 f0 86 10 00 	movl   $0x1086f0,(%esp)
  10055f:	e8 ca 02 00 00       	call   10082e <debug_panic>

	

	cprintf("==================elf load done!\n");
  100564:	c7 04 24 44 87 10 00 	movl   $0x108744,(%esp)
  10056b:	e8 21 7a 00 00       	call   107f91 <cprintf>

	return;

}
  100570:	c9                   	leave  
  100571:	c3                   	ret    

00100572 <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  100572:	55                   	push   %ebp
  100573:	89 e5                	mov    %esp,%ebp
  100575:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  100578:	c7 04 24 66 87 10 00 	movl   $0x108766,(%esp)
  10057f:	e8 0d 7a 00 00       	call   107f91 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100584:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  100587:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  10058a:	89 c2                	mov    %eax,%edx
  10058c:	b8 00 90 11 00       	mov    $0x119000,%eax
  100591:	39 c2                	cmp    %eax,%edx
  100593:	77 24                	ja     1005b9 <user+0x47>
  100595:	c7 44 24 0c 74 87 10 	movl   $0x108774,0xc(%esp)
  10059c:	00 
  10059d:	c7 44 24 08 16 86 10 	movl   $0x108616,0x8(%esp)
  1005a4:	00 
  1005a5:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
  1005ac:	00 
  1005ad:	c7 04 24 f0 86 10 00 	movl   $0x1086f0,(%esp)
  1005b4:	e8 75 02 00 00       	call   10082e <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1005b9:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1005bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  1005bf:	89 c2                	mov    %eax,%edx
  1005c1:	b8 00 a0 11 00       	mov    $0x11a000,%eax
  1005c6:	39 c2                	cmp    %eax,%edx
  1005c8:	72 24                	jb     1005ee <user+0x7c>
  1005ca:	c7 44 24 0c 9c 87 10 	movl   $0x10879c,0xc(%esp)
  1005d1:	00 
  1005d2:	c7 44 24 08 16 86 10 	movl   $0x108616,0x8(%esp)
  1005d9:	00 
  1005da:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
  1005e1:	00 
  1005e2:	c7 04 24 f0 86 10 00 	movl   $0x1086f0,(%esp)
  1005e9:	e8 40 02 00 00       	call   10082e <debug_panic>


	done();
  1005ee:	e8 00 00 00 00       	call   1005f3 <done>

001005f3 <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  1005f3:	55                   	push   %ebp
  1005f4:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  1005f6:	eb fe                	jmp    1005f6 <done+0x3>

001005f8 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1005f8:	55                   	push   %ebp
  1005f9:	89 e5                	mov    %esp,%ebp
  1005fb:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1005fe:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100601:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100604:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100607:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10060a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10060f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100612:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100615:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10061b:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100620:	74 24                	je     100646 <cpu_cur+0x4e>
  100622:	c7 44 24 0c d4 87 10 	movl   $0x1087d4,0xc(%esp)
  100629:	00 
  10062a:	c7 44 24 08 ea 87 10 	movl   $0x1087ea,0x8(%esp)
  100631:	00 
  100632:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100639:	00 
  10063a:	c7 04 24 ff 87 10 00 	movl   $0x1087ff,(%esp)
  100641:	e8 e8 01 00 00       	call   10082e <debug_panic>
	return c;
  100646:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100649:	c9                   	leave  
  10064a:	c3                   	ret    

0010064b <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10064b:	55                   	push   %ebp
  10064c:	89 e5                	mov    %esp,%ebp
  10064e:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100651:	e8 a2 ff ff ff       	call   1005f8 <cpu_cur>
  100656:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  10065b:	0f 94 c0             	sete   %al
  10065e:	0f b6 c0             	movzbl %al,%eax
}
  100661:	c9                   	leave  
  100662:	c3                   	ret    

00100663 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  100663:	55                   	push   %ebp
  100664:	89 e5                	mov    %esp,%ebp
  100666:	83 ec 28             	sub    $0x28,%esp
	int c;

	spinlock_acquire(&cons_lock);
  100669:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  100670:	e8 8e 20 00 00       	call   102703 <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  100675:	eb 35                	jmp    1006ac <cons_intr+0x49>
		if (c == 0)
  100677:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10067b:	74 2e                	je     1006ab <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  10067d:	a1 04 a2 11 00       	mov    0x11a204,%eax
  100682:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100685:	88 90 00 a0 11 00    	mov    %dl,0x11a000(%eax)
  10068b:	83 c0 01             	add    $0x1,%eax
  10068e:	a3 04 a2 11 00       	mov    %eax,0x11a204
		if (cons.wpos == CONSBUFSIZE)
  100693:	a1 04 a2 11 00       	mov    0x11a204,%eax
  100698:	3d 00 02 00 00       	cmp    $0x200,%eax
  10069d:	75 0d                	jne    1006ac <cons_intr+0x49>
			cons.wpos = 0;
  10069f:	c7 05 04 a2 11 00 00 	movl   $0x0,0x11a204
  1006a6:	00 00 00 
  1006a9:	eb 01                	jmp    1006ac <cons_intr+0x49>
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  1006ab:	90                   	nop
cons_intr(int (*proc)(void))
{
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
  1006ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1006af:	ff d0                	call   *%eax
  1006b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1006b4:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  1006b8:	75 bd                	jne    100677 <cons_intr+0x14>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
	spinlock_release(&cons_lock);
  1006ba:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  1006c1:	e8 aa 20 00 00       	call   102770 <spinlock_release>

}
  1006c6:	c9                   	leave  
  1006c7:	c3                   	ret    

001006c8 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  1006c8:	55                   	push   %ebp
  1006c9:	89 e5                	mov    %esp,%ebp
  1006cb:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  1006ce:	e8 5b 68 00 00       	call   106f2e <serial_intr>
	kbd_intr();
  1006d3:	e8 b1 67 00 00       	call   106e89 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  1006d8:	8b 15 00 a2 11 00    	mov    0x11a200,%edx
  1006de:	a1 04 a2 11 00       	mov    0x11a204,%eax
  1006e3:	39 c2                	cmp    %eax,%edx
  1006e5:	74 35                	je     10071c <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  1006e7:	a1 00 a2 11 00       	mov    0x11a200,%eax
  1006ec:	0f b6 90 00 a0 11 00 	movzbl 0x11a000(%eax),%edx
  1006f3:	0f b6 d2             	movzbl %dl,%edx
  1006f6:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1006f9:	83 c0 01             	add    $0x1,%eax
  1006fc:	a3 00 a2 11 00       	mov    %eax,0x11a200
		if (cons.rpos == CONSBUFSIZE)
  100701:	a1 00 a2 11 00       	mov    0x11a200,%eax
  100706:	3d 00 02 00 00       	cmp    $0x200,%eax
  10070b:	75 0a                	jne    100717 <cons_getc+0x4f>
			cons.rpos = 0;
  10070d:	c7 05 00 a2 11 00 00 	movl   $0x0,0x11a200
  100714:	00 00 00 
		return c;
  100717:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10071a:	eb 05                	jmp    100721 <cons_getc+0x59>
	}
	return 0;
  10071c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100721:	c9                   	leave  
  100722:	c3                   	ret    

00100723 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  100723:	55                   	push   %ebp
  100724:	89 e5                	mov    %esp,%ebp
  100726:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  100729:	8b 45 08             	mov    0x8(%ebp),%eax
  10072c:	89 04 24             	mov    %eax,(%esp)
  10072f:	e8 17 68 00 00       	call   106f4b <serial_putc>
	video_putc(c);
  100734:	8b 45 08             	mov    0x8(%ebp),%eax
  100737:	89 04 24             	mov    %eax,(%esp)
  10073a:	e8 a9 63 00 00       	call   106ae8 <video_putc>
}
  10073f:	c9                   	leave  
  100740:	c3                   	ret    

00100741 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100741:	55                   	push   %ebp
  100742:	89 e5                	mov    %esp,%ebp
  100744:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100747:	e8 ff fe ff ff       	call   10064b <cpu_onboot>
  10074c:	85 c0                	test   %eax,%eax
  10074e:	74 52                	je     1007a2 <cons_init+0x61>
		return;

	spinlock_init(&cons_lock);
  100750:	c7 44 24 08 6a 00 00 	movl   $0x6a,0x8(%esp)
  100757:	00 
  100758:	c7 44 24 04 0c 88 10 	movl   $0x10880c,0x4(%esp)
  10075f:	00 
  100760:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  100767:	e8 63 1f 00 00       	call   1026cf <spinlock_init_>
	video_init();
  10076c:	e8 ab 62 00 00       	call   106a1c <video_init>
	kbd_init();
  100771:	e8 27 67 00 00       	call   106e9d <kbd_init>
	serial_init();
  100776:	e8 35 68 00 00       	call   106fb0 <serial_init>

	if (!serial_exists)
  10077b:	a1 00 20 32 00       	mov    0x322000,%eax
  100780:	85 c0                	test   %eax,%eax
  100782:	75 1f                	jne    1007a3 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  100784:	c7 44 24 08 18 88 10 	movl   $0x108818,0x8(%esp)
  10078b:	00 
  10078c:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  100793:	00 
  100794:	c7 04 24 0c 88 10 00 	movl   $0x10880c,(%esp)
  10079b:	e8 4d 01 00 00       	call   1008ed <debug_warn>
  1007a0:	eb 01                	jmp    1007a3 <cons_init+0x62>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  1007a2:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  1007a3:	c9                   	leave  
  1007a4:	c3                   	ret    

001007a5 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  1007a5:	55                   	push   %ebp
  1007a6:	89 e5                	mov    %esp,%ebp
  1007a8:	53                   	push   %ebx
  1007a9:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1007ac:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  1007af:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	if (read_cs() & 3)
  1007b3:	0f b7 c0             	movzwl %ax,%eax
  1007b6:	83 e0 03             	and    $0x3,%eax
  1007b9:	85 c0                	test   %eax,%eax
  1007bb:	74 14                	je     1007d1 <cputs+0x2c>
  1007bd:	8b 45 08             	mov    0x8(%ebp),%eax
  1007c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  1007c3:	b8 00 00 00 00       	mov    $0x0,%eax
  1007c8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1007cb:	89 d3                	mov    %edx,%ebx
  1007cd:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  1007cf:	eb 57                	jmp    100828 <cputs+0x83>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  1007d1:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  1007d8:	e8 ed 1f 00 00       	call   1027ca <spinlock_holding>
  1007dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!already)
  1007e0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1007e4:	75 25                	jne    10080b <cputs+0x66>
		spinlock_acquire(&cons_lock);
  1007e6:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  1007ed:	e8 11 1f 00 00       	call   102703 <spinlock_acquire>

	char ch;
	while (*str)
  1007f2:	eb 18                	jmp    10080c <cputs+0x67>
		cons_putc(*str++);
  1007f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1007f7:	0f b6 00             	movzbl (%eax),%eax
  1007fa:	0f be c0             	movsbl %al,%eax
  1007fd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100801:	89 04 24             	mov    %eax,(%esp)
  100804:	e8 1a ff ff ff       	call   100723 <cons_putc>
  100809:	eb 01                	jmp    10080c <cputs+0x67>
	bool already = spinlock_holding(&cons_lock);
	if (!already)
		spinlock_acquire(&cons_lock);

	char ch;
	while (*str)
  10080b:	90                   	nop
  10080c:	8b 45 08             	mov    0x8(%ebp),%eax
  10080f:	0f b6 00             	movzbl (%eax),%eax
  100812:	84 c0                	test   %al,%al
  100814:	75 de                	jne    1007f4 <cputs+0x4f>
		cons_putc(*str++);

	if (!already)
  100816:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10081a:	75 0c                	jne    100828 <cputs+0x83>
		spinlock_release(&cons_lock);
  10081c:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  100823:	e8 48 1f 00 00       	call   102770 <spinlock_release>
}
  100828:	83 c4 24             	add    $0x24,%esp
  10082b:	5b                   	pop    %ebx
  10082c:	5d                   	pop    %ebp
  10082d:	c3                   	ret    

0010082e <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  10082e:	55                   	push   %ebp
  10082f:	89 e5                	mov    %esp,%ebp
  100831:	83 ec 58             	sub    $0x58,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  100834:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  100837:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  10083b:	0f b7 c0             	movzwl %ax,%eax
  10083e:	83 e0 03             	and    $0x3,%eax
  100841:	85 c0                	test   %eax,%eax
  100843:	75 15                	jne    10085a <debug_panic+0x2c>
		if (panicstr)
  100845:	a1 08 a2 11 00       	mov    0x11a208,%eax
  10084a:	85 c0                	test   %eax,%eax
  10084c:	0f 85 95 00 00 00    	jne    1008e7 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  100852:	8b 45 10             	mov    0x10(%ebp),%eax
  100855:	a3 08 a2 11 00       	mov    %eax,0x11a208
	}

	// First print the requested message
	va_start(ap, fmt);
  10085a:	8d 45 10             	lea    0x10(%ebp),%eax
  10085d:	83 c0 04             	add    $0x4,%eax
  100860:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  100863:	8b 45 0c             	mov    0xc(%ebp),%eax
  100866:	89 44 24 08          	mov    %eax,0x8(%esp)
  10086a:	8b 45 08             	mov    0x8(%ebp),%eax
  10086d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100871:	c7 04 24 35 88 10 00 	movl   $0x108835,(%esp)
  100878:	e8 14 77 00 00       	call   107f91 <cprintf>
	vcprintf(fmt, ap);
  10087d:	8b 45 10             	mov    0x10(%ebp),%eax
  100880:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100883:	89 54 24 04          	mov    %edx,0x4(%esp)
  100887:	89 04 24             	mov    %eax,(%esp)
  10088a:	e8 99 76 00 00       	call   107f28 <vcprintf>
	cprintf("\n");
  10088f:	c7 04 24 4d 88 10 00 	movl   $0x10884d,(%esp)
  100896:	e8 f6 76 00 00       	call   107f91 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10089b:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  10089e:	8b 45 f4             	mov    -0xc(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1008a1:	8d 55 c0             	lea    -0x40(%ebp),%edx
  1008a4:	89 54 24 04          	mov    %edx,0x4(%esp)
  1008a8:	89 04 24             	mov    %eax,(%esp)
  1008ab:	e8 86 00 00 00       	call   100936 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1008b0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1008b7:	eb 1b                	jmp    1008d4 <debug_panic+0xa6>
		cprintf("  from %08x\n", eips[i]);
  1008b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1008bc:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1008c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1008c4:	c7 04 24 4f 88 10 00 	movl   $0x10884f,(%esp)
  1008cb:	e8 c1 76 00 00       	call   107f91 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1008d0:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1008d4:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  1008d8:	7f 0e                	jg     1008e8 <debug_panic+0xba>
  1008da:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1008dd:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1008e1:	85 c0                	test   %eax,%eax
  1008e3:	75 d4                	jne    1008b9 <debug_panic+0x8b>
  1008e5:	eb 01                	jmp    1008e8 <debug_panic+0xba>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  1008e7:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  1008e8:	e8 06 fd ff ff       	call   1005f3 <done>

001008ed <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  1008ed:	55                   	push   %ebp
  1008ee:	89 e5                	mov    %esp,%ebp
  1008f0:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  1008f3:	8d 45 10             	lea    0x10(%ebp),%eax
  1008f6:	83 c0 04             	add    $0x4,%eax
  1008f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  1008fc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1008ff:	89 44 24 08          	mov    %eax,0x8(%esp)
  100903:	8b 45 08             	mov    0x8(%ebp),%eax
  100906:	89 44 24 04          	mov    %eax,0x4(%esp)
  10090a:	c7 04 24 5c 88 10 00 	movl   $0x10885c,(%esp)
  100911:	e8 7b 76 00 00       	call   107f91 <cprintf>
	vcprintf(fmt, ap);
  100916:	8b 45 10             	mov    0x10(%ebp),%eax
  100919:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10091c:	89 54 24 04          	mov    %edx,0x4(%esp)
  100920:	89 04 24             	mov    %eax,(%esp)
  100923:	e8 00 76 00 00       	call   107f28 <vcprintf>
	cprintf("\n");
  100928:	c7 04 24 4d 88 10 00 	movl   $0x10884d,(%esp)
  10092f:	e8 5d 76 00 00       	call   107f91 <cprintf>
	va_end(ap);
}
  100934:	c9                   	leave  
  100935:	c3                   	ret    

00100936 <debug_trace>:

// Riecord the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100936:	55                   	push   %ebp
  100937:	89 e5                	mov    %esp,%ebp
  100939:	83 ec 10             	sub    $0x10,%esp

	return;*/
	//panic("debug_trace not implemented");

	int i ,j;
	uint32_t *cur_epb = (uint32_t *)ebp;
  10093c:	8b 45 08             	mov    0x8(%ebp),%eax
  10093f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	//cprintf("Stack backtrace:\n");
	for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  100942:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100949:	eb 32                	jmp    10097d <debug_trace+0x47>
		//cprintf("  ebp %08x eip %08x args",cur_epb[0],cur_epb[1]);
		eips[i] = cur_epb[1];
  10094b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10094e:	c1 e0 02             	shl    $0x2,%eax
  100951:	03 45 0c             	add    0xc(%ebp),%eax
  100954:	8b 55 fc             	mov    -0x4(%ebp),%edx
  100957:	83 c2 04             	add    $0x4,%edx
  10095a:	8b 12                	mov    (%edx),%edx
  10095c:	89 10                	mov    %edx,(%eax)
		for(j = 0; j < 5; j++) {
  10095e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  100965:	eb 04                	jmp    10096b <debug_trace+0x35>
  100967:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  10096b:	83 7d f8 04          	cmpl   $0x4,-0x8(%ebp)
  10096f:	7e f6                	jle    100967 <debug_trace+0x31>
			//makecprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");make
		cur_epb = (uint32_t *)(*cur_epb);
  100971:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100974:	8b 00                	mov    (%eax),%eax
  100976:	89 45 fc             	mov    %eax,-0x4(%ebp)
	//panic("debug_trace not implemented");

	int i ,j;
	uint32_t *cur_epb = (uint32_t *)ebp;
	//cprintf("Stack backtrace:\n");
	for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  100979:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10097d:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100981:	7f 1b                	jg     10099e <debug_trace+0x68>
  100983:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  100987:	75 c2                	jne    10094b <debug_trace+0x15>
			//makecprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");make
		cur_epb = (uint32_t *)(*cur_epb);
	}
	for(; i < DEBUG_TRACEFRAMES ; i++) {
  100989:	eb 13                	jmp    10099e <debug_trace+0x68>
		eips[i] = 0;
  10098b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10098e:	c1 e0 02             	shl    $0x2,%eax
  100991:	03 45 0c             	add    0xc(%ebp),%eax
  100994:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			//makecprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");make
		cur_epb = (uint32_t *)(*cur_epb);
	}
	for(; i < DEBUG_TRACEFRAMES ; i++) {
  10099a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10099e:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1009a2:	7e e7                	jle    10098b <debug_trace+0x55>
		eips[i] = 0;
	}
	/*
	for(i = 0; i < DEBUG_TRACEFRAMES ; i++) {
		cprintf("eip %x\n",eips[i]);			}*/
}
  1009a4:	c9                   	leave  
  1009a5:	c3                   	ret    

001009a6 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  1009a6:	55                   	push   %ebp
  1009a7:	89 e5                	mov    %esp,%ebp
  1009a9:	83 ec 18             	sub    $0x18,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1009ac:	89 6d fc             	mov    %ebp,-0x4(%ebp)
        return ebp;
  1009af:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1009b2:	8b 55 0c             	mov    0xc(%ebp),%edx
  1009b5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1009b9:	89 04 24             	mov    %eax,(%esp)
  1009bc:	e8 75 ff ff ff       	call   100936 <debug_trace>
  1009c1:	c9                   	leave  
  1009c2:	c3                   	ret    

001009c3 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  1009c3:	55                   	push   %ebp
  1009c4:	89 e5                	mov    %esp,%ebp
  1009c6:	83 ec 08             	sub    $0x8,%esp
  1009c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1009cc:	83 e0 02             	and    $0x2,%eax
  1009cf:	85 c0                	test   %eax,%eax
  1009d1:	74 14                	je     1009e7 <f2+0x24>
  1009d3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1009d6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009da:	8b 45 08             	mov    0x8(%ebp),%eax
  1009dd:	89 04 24             	mov    %eax,(%esp)
  1009e0:	e8 c1 ff ff ff       	call   1009a6 <f3>
  1009e5:	eb 12                	jmp    1009f9 <f2+0x36>
  1009e7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1009ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1009f1:	89 04 24             	mov    %eax,(%esp)
  1009f4:	e8 ad ff ff ff       	call   1009a6 <f3>
  1009f9:	c9                   	leave  
  1009fa:	c3                   	ret    

001009fb <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  1009fb:	55                   	push   %ebp
  1009fc:	89 e5                	mov    %esp,%ebp
  1009fe:	83 ec 08             	sub    $0x8,%esp
  100a01:	8b 45 08             	mov    0x8(%ebp),%eax
  100a04:	83 e0 01             	and    $0x1,%eax
  100a07:	84 c0                	test   %al,%al
  100a09:	74 14                	je     100a1f <f1+0x24>
  100a0b:	8b 45 0c             	mov    0xc(%ebp),%eax
  100a0e:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a12:	8b 45 08             	mov    0x8(%ebp),%eax
  100a15:	89 04 24             	mov    %eax,(%esp)
  100a18:	e8 a6 ff ff ff       	call   1009c3 <f2>
  100a1d:	eb 12                	jmp    100a31 <f1+0x36>
  100a1f:	8b 45 0c             	mov    0xc(%ebp),%eax
  100a22:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a26:	8b 45 08             	mov    0x8(%ebp),%eax
  100a29:	89 04 24             	mov    %eax,(%esp)
  100a2c:	e8 92 ff ff ff       	call   1009c3 <f2>
  100a31:	c9                   	leave  
  100a32:	c3                   	ret    

00100a33 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100a33:	55                   	push   %ebp
  100a34:	89 e5                	mov    %esp,%ebp
  100a36:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100a3c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100a43:	eb 29                	jmp    100a6e <debug_check+0x3b>
		f1(i, eips[i]);
  100a45:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  100a4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100a4e:	89 d0                	mov    %edx,%eax
  100a50:	c1 e0 02             	shl    $0x2,%eax
  100a53:	01 d0                	add    %edx,%eax
  100a55:	c1 e0 03             	shl    $0x3,%eax
  100a58:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  100a5b:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a62:	89 04 24             	mov    %eax,(%esp)
  100a65:	e8 91 ff ff ff       	call   1009fb <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100a6a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100a6e:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  100a72:	7e d1                	jle    100a45 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100a74:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100a7b:	e9 bc 00 00 00       	jmp    100b3c <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100a80:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100a87:	e9 a2 00 00 00       	jmp    100b2e <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  100a8c:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100a8f:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100a92:	89 d0                	mov    %edx,%eax
  100a94:	c1 e0 02             	shl    $0x2,%eax
  100a97:	01 d0                	add    %edx,%eax
  100a99:	01 c0                	add    %eax,%eax
  100a9b:	01 c8                	add    %ecx,%eax
  100a9d:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100aa4:	85 c0                	test   %eax,%eax
  100aa6:	0f 95 c2             	setne  %dl
  100aa9:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  100aad:	0f 9e c0             	setle  %al
  100ab0:	31 d0                	xor    %edx,%eax
  100ab2:	84 c0                	test   %al,%al
  100ab4:	74 24                	je     100ada <debug_check+0xa7>
  100ab6:	c7 44 24 0c 76 88 10 	movl   $0x108876,0xc(%esp)
  100abd:	00 
  100abe:	c7 44 24 08 93 88 10 	movl   $0x108893,0x8(%esp)
  100ac5:	00 
  100ac6:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100acd:	00 
  100ace:	c7 04 24 a8 88 10 00 	movl   $0x1088a8,(%esp)
  100ad5:	e8 54 fd ff ff       	call   10082e <debug_panic>
			if (i >= 2)
  100ada:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  100ade:	7e 4a                	jle    100b2a <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  100ae0:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100ae3:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100ae6:	89 d0                	mov    %edx,%eax
  100ae8:	c1 e0 02             	shl    $0x2,%eax
  100aeb:	01 d0                	add    %edx,%eax
  100aed:	01 c0                	add    %eax,%eax
  100aef:	01 c8                	add    %ecx,%eax
  100af1:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  100af8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100afb:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100b02:	39 c2                	cmp    %eax,%edx
  100b04:	74 24                	je     100b2a <debug_check+0xf7>
  100b06:	c7 44 24 0c b5 88 10 	movl   $0x1088b5,0xc(%esp)
  100b0d:	00 
  100b0e:	c7 44 24 08 93 88 10 	movl   $0x108893,0x8(%esp)
  100b15:	00 
  100b16:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  100b1d:	00 
  100b1e:	c7 04 24 a8 88 10 00 	movl   $0x1088a8,(%esp)
  100b25:	e8 04 fd ff ff       	call   10082e <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100b2a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100b2e:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  100b32:	0f 8e 54 ff ff ff    	jle    100a8c <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100b38:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100b3c:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  100b40:	0f 8e 3a ff ff ff    	jle    100a80 <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  100b46:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  100b4c:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  100b52:	39 c2                	cmp    %eax,%edx
  100b54:	74 24                	je     100b7a <debug_check+0x147>
  100b56:	c7 44 24 0c ce 88 10 	movl   $0x1088ce,0xc(%esp)
  100b5d:	00 
  100b5e:	c7 44 24 08 93 88 10 	movl   $0x108893,0x8(%esp)
  100b65:	00 
  100b66:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100b6d:	00 
  100b6e:	c7 04 24 a8 88 10 00 	movl   $0x1088a8,(%esp)
  100b75:	e8 b4 fc ff ff       	call   10082e <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100b7a:	8b 55 a0             	mov    -0x60(%ebp),%edx
  100b7d:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100b80:	39 c2                	cmp    %eax,%edx
  100b82:	74 24                	je     100ba8 <debug_check+0x175>
  100b84:	c7 44 24 0c e7 88 10 	movl   $0x1088e7,0xc(%esp)
  100b8b:	00 
  100b8c:	c7 44 24 08 93 88 10 	movl   $0x108893,0x8(%esp)
  100b93:	00 
  100b94:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  100b9b:	00 
  100b9c:	c7 04 24 a8 88 10 00 	movl   $0x1088a8,(%esp)
  100ba3:	e8 86 fc ff ff       	call   10082e <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100ba8:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100bae:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100bb1:	39 c2                	cmp    %eax,%edx
  100bb3:	75 24                	jne    100bd9 <debug_check+0x1a6>
  100bb5:	c7 44 24 0c 00 89 10 	movl   $0x108900,0xc(%esp)
  100bbc:	00 
  100bbd:	c7 44 24 08 93 88 10 	movl   $0x108893,0x8(%esp)
  100bc4:	00 
  100bc5:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100bcc:	00 
  100bcd:	c7 04 24 a8 88 10 00 	movl   $0x1088a8,(%esp)
  100bd4:	e8 55 fc ff ff       	call   10082e <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100bd9:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100bdf:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100be2:	39 c2                	cmp    %eax,%edx
  100be4:	74 24                	je     100c0a <debug_check+0x1d7>
  100be6:	c7 44 24 0c 19 89 10 	movl   $0x108919,0xc(%esp)
  100bed:	00 
  100bee:	c7 44 24 08 93 88 10 	movl   $0x108893,0x8(%esp)
  100bf5:	00 
  100bf6:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100bfd:	00 
  100bfe:	c7 04 24 a8 88 10 00 	movl   $0x1088a8,(%esp)
  100c05:	e8 24 fc ff ff       	call   10082e <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  100c0a:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100c10:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100c13:	39 c2                	cmp    %eax,%edx
  100c15:	74 24                	je     100c3b <debug_check+0x208>
  100c17:	c7 44 24 0c 32 89 10 	movl   $0x108932,0xc(%esp)
  100c1e:	00 
  100c1f:	c7 44 24 08 93 88 10 	movl   $0x108893,0x8(%esp)
  100c26:	00 
  100c27:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100c2e:	00 
  100c2f:	c7 04 24 a8 88 10 00 	movl   $0x1088a8,(%esp)
  100c36:	e8 f3 fb ff ff       	call   10082e <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  100c3b:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100c41:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  100c47:	39 c2                	cmp    %eax,%edx
  100c49:	75 24                	jne    100c6f <debug_check+0x23c>
  100c4b:	c7 44 24 0c 4b 89 10 	movl   $0x10894b,0xc(%esp)
  100c52:	00 
  100c53:	c7 44 24 08 93 88 10 	movl   $0x108893,0x8(%esp)
  100c5a:	00 
  100c5b:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  100c62:	00 
  100c63:	c7 04 24 a8 88 10 00 	movl   $0x1088a8,(%esp)
  100c6a:	e8 bf fb ff ff       	call   10082e <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100c6f:	c7 04 24 64 89 10 00 	movl   $0x108964,(%esp)
  100c76:	e8 16 73 00 00       	call   107f91 <cprintf>
}
  100c7b:	c9                   	leave  
  100c7c:	c3                   	ret    

00100c7d <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100c7d:	55                   	push   %ebp
  100c7e:	89 e5                	mov    %esp,%ebp
  100c80:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100c83:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100c86:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100c89:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100c8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100c8f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100c94:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100c97:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100c9a:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100ca0:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100ca5:	74 24                	je     100ccb <cpu_cur+0x4e>
  100ca7:	c7 44 24 0c 80 89 10 	movl   $0x108980,0xc(%esp)
  100cae:	00 
  100caf:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  100cb6:	00 
  100cb7:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100cbe:	00 
  100cbf:	c7 04 24 ab 89 10 00 	movl   $0x1089ab,(%esp)
  100cc6:	e8 63 fb ff ff       	call   10082e <debug_panic>
	return c;
  100ccb:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100cce:	c9                   	leave  
  100ccf:	c3                   	ret    

00100cd0 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100cd0:	55                   	push   %ebp
  100cd1:	89 e5                	mov    %esp,%ebp
  100cd3:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100cd6:	e8 a2 ff ff ff       	call   100c7d <cpu_cur>
  100cdb:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  100ce0:	0f 94 c0             	sete   %al
  100ce3:	0f b6 c0             	movzbl %al,%eax
}
  100ce6:	c9                   	leave  
  100ce7:	c3                   	ret    

00100ce8 <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  100ce8:	55                   	push   %ebp
  100ce9:	89 e5                	mov    %esp,%ebp
  100ceb:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100cee:	e8 dd ff ff ff       	call   100cd0 <cpu_onboot>
  100cf3:	85 c0                	test   %eax,%eax
  100cf5:	0f 84 bc 01 00 00    	je     100eb7 <mem_init+0x1cf>
		return;

	
	spinlock_init(&mem_spinlock);
  100cfb:	c7 44 24 08 2e 00 00 	movl   $0x2e,0x8(%esp)
  100d02:	00 
  100d03:	c7 44 24 04 b8 89 10 	movl   $0x1089b8,0x4(%esp)
  100d0a:	00 
  100d0b:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
  100d12:	e8 b8 19 00 00       	call   1026cf <spinlock_init_>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100d17:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100d1e:	e8 64 65 00 00       	call   107287 <nvram_read16>
  100d23:	c1 e0 0a             	shl    $0xa,%eax
  100d26:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100d29:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100d2c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100d31:	89 45 dc             	mov    %eax,-0x24(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100d34:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100d3b:	e8 47 65 00 00       	call   107287 <nvram_read16>
  100d40:	c1 e0 0a             	shl    $0xa,%eax
  100d43:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100d46:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100d49:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100d4e:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  100d51:	c7 44 24 08 c4 89 10 	movl   $0x1089c4,0x8(%esp)
  100d58:	00 
  100d59:	c7 44 24 04 39 00 00 	movl   $0x39,0x4(%esp)
  100d60:	00 
  100d61:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  100d68:	e8 80 fb ff ff       	call   1008ed <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100d6d:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100d74:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100d77:	05 00 00 10 00       	add    $0x100000,%eax
  100d7c:	a3 08 ed 11 00       	mov    %eax,0x11ed08

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100d81:	a1 08 ed 11 00       	mov    0x11ed08,%eax
  100d86:	c1 e8 0c             	shr    $0xc,%eax
  100d89:	a3 04 ed 11 00       	mov    %eax,0x11ed04

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100d8e:	a1 08 ed 11 00       	mov    0x11ed08,%eax
  100d93:	c1 e8 0a             	shr    $0xa,%eax
  100d96:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d9a:	c7 04 24 e4 89 10 00 	movl   $0x1089e4,(%esp)
  100da1:	e8 eb 71 00 00       	call   107f91 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  100da6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100da9:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100dac:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  100dae:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100db1:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100db4:	89 54 24 08          	mov    %edx,0x8(%esp)
  100db8:	89 44 24 04          	mov    %eax,0x4(%esp)
  100dbc:	c7 04 24 05 8a 10 00 	movl   $0x108a05,(%esp)
  100dc3:	e8 c9 71 00 00       	call   107f91 <cprintf>


	extern char start[], end[];
	uint32_t page_start;
	
	pageinfo **freetail = &mem_freelist;
  100dc8:	c7 45 e8 00 ed 11 00 	movl   $0x11ed00,-0x18(%ebp)
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
  100dcf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100dd6:	00 
  100dd7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100dde:	00 
  100ddf:	c7 04 24 20 ed 11 00 	movl   $0x11ed20,(%esp)
  100de6:	e8 8b 73 00 00       	call   108176 <memset>
	mem_pageinfo = spc_for_pi;
  100deb:	c7 05 58 ed 31 00 20 	movl   $0x11ed20,0x31ed58
  100df2:	ed 11 00 
	int i;
	for (i = 0; i < mem_npage; i++) {
  100df5:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100dfc:	e9 96 00 00 00       	jmp    100e97 <mem_init+0x1af>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100e01:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  100e06:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100e09:	c1 e2 03             	shl    $0x3,%edx
  100e0c:	01 d0                	add    %edx,%eax
  100e0e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		if(i == 0 || i == 1)
  100e15:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  100e19:	74 6e                	je     100e89 <mem_init+0x1a1>
  100e1b:	83 7d ec 01          	cmpl   $0x1,-0x14(%ebp)
  100e1f:	74 6b                	je     100e8c <mem_init+0x1a4>
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);
  100e21:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e24:	c1 e0 03             	shl    $0x3,%eax
  100e27:	c1 f8 03             	sar    $0x3,%eax
  100e2a:	c1 e0 0c             	shl    $0xc,%eax
  100e2d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100e30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100e33:	05 00 10 00 00       	add    $0x1000,%eax
  100e38:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  100e3d:	76 09                	jbe    100e48 <mem_init+0x160>
  100e3f:	81 7d e4 ff ff 0f 00 	cmpl   $0xfffff,-0x1c(%ebp)
  100e46:	76 47                	jbe    100e8f <mem_init+0x1a7>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  100e48:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100e4b:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
  100e51:	b8 0c 00 10 00       	mov    $0x10000c,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100e56:	39 c2                	cmp    %eax,%edx
  100e58:	72 0a                	jb     100e64 <mem_init+0x17c>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
  100e5a:	b8 08 20 32 00       	mov    $0x322008,%eax
		if(i == 0 || i == 1)
			continue;

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
  100e5f:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
  100e62:	72 2e                	jb     100e92 <mem_init+0x1aa>
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;


		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100e64:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  100e69:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100e6c:	c1 e2 03             	shl    $0x3,%edx
  100e6f:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100e72:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100e75:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100e77:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  100e7c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100e7f:	c1 e2 03             	shl    $0x3,%edx
  100e82:	01 d0                	add    %edx,%eax
  100e84:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100e87:	eb 0a                	jmp    100e93 <mem_init+0x1ab>
	for (i = 0; i < mem_npage; i++) {
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;

		if(i == 0 || i == 1)
			continue;
  100e89:	90                   	nop
  100e8a:	eb 07                	jmp    100e93 <mem_init+0x1ab>
  100e8c:	90                   	nop
  100e8d:	eb 04                	jmp    100e93 <mem_init+0x1ab>

		page_start = mem_pi2phys(mem_pageinfo + i);

		if((page_start + PAGESIZE  >= MEM_IO && page_start < MEM_EXT)
			|| (page_start + PAGESIZE >= (uint32_t)start && page_start < (uint32_t)end))
			continue;
  100e8f:	90                   	nop
  100e90:	eb 01                	jmp    100e93 <mem_init+0x1ab>
  100e92:	90                   	nop
	
	pageinfo **freetail = &mem_freelist;
	memset(spc_for_pi, 0, sizeof(pageinfo)*1024*1024*1024/PAGESIZE);
	mem_pageinfo = spc_for_pi;
	int i;
	for (i = 0; i < mem_npage; i++) {
  100e93:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  100e97:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100e9a:	a1 04 ed 11 00       	mov    0x11ed04,%eax
  100e9f:	39 c2                	cmp    %eax,%edx
  100ea1:	0f 82 5a ff ff ff    	jb     100e01 <mem_init+0x119>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100ea7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100eaa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100eb0:	e8 a1 00 00 00       	call   100f56 <mem_check>
  100eb5:	eb 01                	jmp    100eb8 <mem_init+0x1d0>

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100eb7:	90                   	nop
	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100eb8:	c9                   	leave  
  100eb9:	c3                   	ret    

00100eba <mem_alloc>:



pageinfo *
mem_alloc(void)
{
  100eba:	55                   	push   %ebp
  100ebb:	89 e5                	mov    %esp,%ebp
  100ebd:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
	// Fill this function in.
	//panic("mem_alloc not implemented.");

	if(mem_freelist == NULL)
  100ec0:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  100ec5:	85 c0                	test   %eax,%eax
  100ec7:	75 07                	jne    100ed0 <mem_alloc+0x16>
		return NULL;
  100ec9:	b8 00 00 00 00       	mov    $0x0,%eax
  100ece:	eb 2f                	jmp    100eff <mem_alloc+0x45>

	spinlock_acquire(&mem_spinlock);
  100ed0:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
  100ed7:	e8 27 18 00 00       	call   102703 <spinlock_acquire>
	pageinfo* r = mem_freelist;
  100edc:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  100ee1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = mem_freelist->free_next;
  100ee4:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  100ee9:	8b 00                	mov    (%eax),%eax
  100eeb:	a3 00 ed 11 00       	mov    %eax,0x11ed00
	spinlock_release(&mem_spinlock);
  100ef0:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
  100ef7:	e8 74 18 00 00       	call   102770 <spinlock_release>
	return r;
  100efc:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100eff:	c9                   	leave  
  100f00:	c3                   	ret    

00100f01 <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100f01:	55                   	push   %ebp
  100f02:	89 e5                	mov    %esp,%ebp
  100f04:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");

	if(pi == NULL)
  100f07:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  100f0b:	75 1c                	jne    100f29 <mem_free+0x28>
		panic("null for page which to be freed!"); 
  100f0d:	c7 44 24 08 24 8a 10 	movl   $0x108a24,0x8(%esp)
  100f14:	00 
  100f15:	c7 44 24 04 ab 00 00 	movl   $0xab,0x4(%esp)
  100f1c:	00 
  100f1d:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  100f24:	e8 05 f9 ff ff       	call   10082e <debug_panic>

	spinlock_acquire(&mem_spinlock);
  100f29:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
  100f30:	e8 ce 17 00 00       	call   102703 <spinlock_acquire>
	pi->free_next = mem_freelist;
  100f35:	8b 15 00 ed 11 00    	mov    0x11ed00,%edx
  100f3b:	8b 45 08             	mov    0x8(%ebp),%eax
  100f3e:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100f40:	8b 45 08             	mov    0x8(%ebp),%eax
  100f43:	a3 00 ed 11 00       	mov    %eax,0x11ed00
	spinlock_release(&mem_spinlock);
  100f48:	c7 04 24 20 ed 31 00 	movl   $0x31ed20,(%esp)
  100f4f:	e8 1c 18 00 00       	call   102770 <spinlock_release>
	
}
  100f54:	c9                   	leave  
  100f55:	c3                   	ret    

00100f56 <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100f56:	55                   	push   %ebp
  100f57:	89 e5                	mov    %esp,%ebp
  100f59:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100f5c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100f63:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  100f68:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100f6b:	eb 38                	jmp    100fa5 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100f6d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100f70:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  100f75:	89 d1                	mov    %edx,%ecx
  100f77:	29 c1                	sub    %eax,%ecx
  100f79:	89 c8                	mov    %ecx,%eax
  100f7b:	c1 f8 03             	sar    $0x3,%eax
  100f7e:	c1 e0 0c             	shl    $0xc,%eax
  100f81:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100f88:	00 
  100f89:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100f90:	00 
  100f91:	89 04 24             	mov    %eax,(%esp)
  100f94:	e8 dd 71 00 00       	call   108176 <memset>
		freepages++;
  100f99:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100f9d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100fa0:	8b 00                	mov    (%eax),%eax
  100fa2:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100fa5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  100fa9:	75 c2                	jne    100f6d <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100fab:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100fae:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fb2:	c7 04 24 45 8a 10 00 	movl   $0x108a45,(%esp)
  100fb9:	e8 d3 6f 00 00       	call   107f91 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100fbe:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100fc1:	a1 04 ed 11 00       	mov    0x11ed04,%eax
  100fc6:	39 c2                	cmp    %eax,%edx
  100fc8:	72 24                	jb     100fee <mem_check+0x98>
  100fca:	c7 44 24 0c 5f 8a 10 	movl   $0x108a5f,0xc(%esp)
  100fd1:	00 
  100fd2:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  100fd9:	00 
  100fda:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  100fe1:	00 
  100fe2:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  100fe9:	e8 40 f8 ff ff       	call   10082e <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100fee:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100ff5:	7f 24                	jg     10101b <mem_check+0xc5>
  100ff7:	c7 44 24 0c 75 8a 10 	movl   $0x108a75,0xc(%esp)
  100ffe:	00 
  100fff:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  101006:	00 
  101007:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  10100e:	00 
  10100f:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  101016:	e8 13 f8 ff ff       	call   10082e <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  10101b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  101022:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101025:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101028:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10102b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  10102e:	e8 87 fe ff ff       	call   100eba <mem_alloc>
  101033:	89 45 e0             	mov    %eax,-0x20(%ebp)
  101036:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  10103a:	75 24                	jne    101060 <mem_check+0x10a>
  10103c:	c7 44 24 0c 87 8a 10 	movl   $0x108a87,0xc(%esp)
  101043:	00 
  101044:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  10104b:	00 
  10104c:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  101053:	00 
  101054:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  10105b:	e8 ce f7 ff ff       	call   10082e <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  101060:	e8 55 fe ff ff       	call   100eba <mem_alloc>
  101065:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101068:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10106c:	75 24                	jne    101092 <mem_check+0x13c>
  10106e:	c7 44 24 0c 90 8a 10 	movl   $0x108a90,0xc(%esp)
  101075:	00 
  101076:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  10107d:	00 
  10107e:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  101085:	00 
  101086:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  10108d:	e8 9c f7 ff ff       	call   10082e <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  101092:	e8 23 fe ff ff       	call   100eba <mem_alloc>
  101097:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10109a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  10109e:	75 24                	jne    1010c4 <mem_check+0x16e>
  1010a0:	c7 44 24 0c 99 8a 10 	movl   $0x108a99,0xc(%esp)
  1010a7:	00 
  1010a8:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  1010af:	00 
  1010b0:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  1010b7:	00 
  1010b8:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  1010bf:	e8 6a f7 ff ff       	call   10082e <debug_panic>

	assert(pp0);
  1010c4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  1010c8:	75 24                	jne    1010ee <mem_check+0x198>
  1010ca:	c7 44 24 0c a2 8a 10 	movl   $0x108aa2,0xc(%esp)
  1010d1:	00 
  1010d2:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  1010d9:	00 
  1010da:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  1010e1:	00 
  1010e2:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  1010e9:	e8 40 f7 ff ff       	call   10082e <debug_panic>
	assert(pp1 && pp1 != pp0);
  1010ee:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  1010f2:	74 08                	je     1010fc <mem_check+0x1a6>
  1010f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1010f7:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  1010fa:	75 24                	jne    101120 <mem_check+0x1ca>
  1010fc:	c7 44 24 0c a6 8a 10 	movl   $0x108aa6,0xc(%esp)
  101103:	00 
  101104:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  10110b:	00 
  10110c:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  101113:	00 
  101114:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  10111b:	e8 0e f7 ff ff       	call   10082e <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  101120:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  101124:	74 10                	je     101136 <mem_check+0x1e0>
  101126:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101129:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  10112c:	74 08                	je     101136 <mem_check+0x1e0>
  10112e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101131:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  101134:	75 24                	jne    10115a <mem_check+0x204>
  101136:	c7 44 24 0c b8 8a 10 	movl   $0x108ab8,0xc(%esp)
  10113d:	00 
  10113e:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  101145:	00 
  101146:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  10114d:	00 
  10114e:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  101155:	e8 d4 f6 ff ff       	call   10082e <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  10115a:	8b 55 e0             	mov    -0x20(%ebp),%edx
  10115d:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  101162:	89 d1                	mov    %edx,%ecx
  101164:	29 c1                	sub    %eax,%ecx
  101166:	89 c8                	mov    %ecx,%eax
  101168:	c1 f8 03             	sar    $0x3,%eax
  10116b:	c1 e0 0c             	shl    $0xc,%eax
  10116e:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  101174:	c1 e2 0c             	shl    $0xc,%edx
  101177:	39 d0                	cmp    %edx,%eax
  101179:	72 24                	jb     10119f <mem_check+0x249>
  10117b:	c7 44 24 0c d8 8a 10 	movl   $0x108ad8,0xc(%esp)
  101182:	00 
  101183:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  10118a:	00 
  10118b:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  101192:	00 
  101193:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  10119a:	e8 8f f6 ff ff       	call   10082e <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  10119f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1011a2:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1011a7:	89 d1                	mov    %edx,%ecx
  1011a9:	29 c1                	sub    %eax,%ecx
  1011ab:	89 c8                	mov    %ecx,%eax
  1011ad:	c1 f8 03             	sar    $0x3,%eax
  1011b0:	c1 e0 0c             	shl    $0xc,%eax
  1011b3:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  1011b9:	c1 e2 0c             	shl    $0xc,%edx
  1011bc:	39 d0                	cmp    %edx,%eax
  1011be:	72 24                	jb     1011e4 <mem_check+0x28e>
  1011c0:	c7 44 24 0c 00 8b 10 	movl   $0x108b00,0xc(%esp)
  1011c7:	00 
  1011c8:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  1011cf:	00 
  1011d0:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  1011d7:	00 
  1011d8:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  1011df:	e8 4a f6 ff ff       	call   10082e <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  1011e4:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1011e7:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1011ec:	89 d1                	mov    %edx,%ecx
  1011ee:	29 c1                	sub    %eax,%ecx
  1011f0:	89 c8                	mov    %ecx,%eax
  1011f2:	c1 f8 03             	sar    $0x3,%eax
  1011f5:	c1 e0 0c             	shl    $0xc,%eax
  1011f8:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  1011fe:	c1 e2 0c             	shl    $0xc,%edx
  101201:	39 d0                	cmp    %edx,%eax
  101203:	72 24                	jb     101229 <mem_check+0x2d3>
  101205:	c7 44 24 0c 28 8b 10 	movl   $0x108b28,0xc(%esp)
  10120c:	00 
  10120d:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  101214:	00 
  101215:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  10121c:	00 
  10121d:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  101224:	e8 05 f6 ff ff       	call   10082e <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  101229:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  10122e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  101231:	c7 05 00 ed 11 00 00 	movl   $0x0,0x11ed00
  101238:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  10123b:	e8 7a fc ff ff       	call   100eba <mem_alloc>
  101240:	85 c0                	test   %eax,%eax
  101242:	74 24                	je     101268 <mem_check+0x312>
  101244:	c7 44 24 0c 4e 8b 10 	movl   $0x108b4e,0xc(%esp)
  10124b:	00 
  10124c:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  101253:	00 
  101254:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  10125b:	00 
  10125c:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  101263:	e8 c6 f5 ff ff       	call   10082e <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  101268:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10126b:	89 04 24             	mov    %eax,(%esp)
  10126e:	e8 8e fc ff ff       	call   100f01 <mem_free>
        mem_free(pp1);
  101273:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101276:	89 04 24             	mov    %eax,(%esp)
  101279:	e8 83 fc ff ff       	call   100f01 <mem_free>
        mem_free(pp2);
  10127e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101281:	89 04 24             	mov    %eax,(%esp)
  101284:	e8 78 fc ff ff       	call   100f01 <mem_free>
	pp0 = pp1 = pp2 = 0;
  101289:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  101290:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101293:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101296:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101299:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  10129c:	e8 19 fc ff ff       	call   100eba <mem_alloc>
  1012a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  1012a4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  1012a8:	75 24                	jne    1012ce <mem_check+0x378>
  1012aa:	c7 44 24 0c 87 8a 10 	movl   $0x108a87,0xc(%esp)
  1012b1:	00 
  1012b2:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  1012b9:	00 
  1012ba:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  1012c1:	00 
  1012c2:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  1012c9:	e8 60 f5 ff ff       	call   10082e <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  1012ce:	e8 e7 fb ff ff       	call   100eba <mem_alloc>
  1012d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1012d6:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  1012da:	75 24                	jne    101300 <mem_check+0x3aa>
  1012dc:	c7 44 24 0c 90 8a 10 	movl   $0x108a90,0xc(%esp)
  1012e3:	00 
  1012e4:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  1012eb:	00 
  1012ec:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  1012f3:	00 
  1012f4:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  1012fb:	e8 2e f5 ff ff       	call   10082e <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  101300:	e8 b5 fb ff ff       	call   100eba <mem_alloc>
  101305:	89 45 e8             	mov    %eax,-0x18(%ebp)
  101308:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  10130c:	75 24                	jne    101332 <mem_check+0x3dc>
  10130e:	c7 44 24 0c 99 8a 10 	movl   $0x108a99,0xc(%esp)
  101315:	00 
  101316:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  10131d:	00 
  10131e:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  101325:	00 
  101326:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  10132d:	e8 fc f4 ff ff       	call   10082e <debug_panic>
	assert(pp0);
  101332:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  101336:	75 24                	jne    10135c <mem_check+0x406>
  101338:	c7 44 24 0c a2 8a 10 	movl   $0x108aa2,0xc(%esp)
  10133f:	00 
  101340:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  101347:	00 
  101348:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
  10134f:	00 
  101350:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  101357:	e8 d2 f4 ff ff       	call   10082e <debug_panic>
	assert(pp1 && pp1 != pp0);
  10135c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  101360:	74 08                	je     10136a <mem_check+0x414>
  101362:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101365:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  101368:	75 24                	jne    10138e <mem_check+0x438>
  10136a:	c7 44 24 0c a6 8a 10 	movl   $0x108aa6,0xc(%esp)
  101371:	00 
  101372:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  101379:	00 
  10137a:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  101381:	00 
  101382:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  101389:	e8 a0 f4 ff ff       	call   10082e <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  10138e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  101392:	74 10                	je     1013a4 <mem_check+0x44e>
  101394:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101397:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  10139a:	74 08                	je     1013a4 <mem_check+0x44e>
  10139c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10139f:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  1013a2:	75 24                	jne    1013c8 <mem_check+0x472>
  1013a4:	c7 44 24 0c b8 8a 10 	movl   $0x108ab8,0xc(%esp)
  1013ab:	00 
  1013ac:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  1013b3:	00 
  1013b4:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
  1013bb:	00 
  1013bc:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  1013c3:	e8 66 f4 ff ff       	call   10082e <debug_panic>
	assert(mem_alloc() == 0);
  1013c8:	e8 ed fa ff ff       	call   100eba <mem_alloc>
  1013cd:	85 c0                	test   %eax,%eax
  1013cf:	74 24                	je     1013f5 <mem_check+0x49f>
  1013d1:	c7 44 24 0c 4e 8b 10 	movl   $0x108b4e,0xc(%esp)
  1013d8:	00 
  1013d9:	c7 44 24 08 96 89 10 	movl   $0x108996,0x8(%esp)
  1013e0:	00 
  1013e1:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  1013e8:	00 
  1013e9:	c7 04 24 b8 89 10 00 	movl   $0x1089b8,(%esp)
  1013f0:	e8 39 f4 ff ff       	call   10082e <debug_panic>

	// give free list back
	mem_freelist = fl;
  1013f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1013f8:	a3 00 ed 11 00       	mov    %eax,0x11ed00

	// free the pages we took
	mem_free(pp0);
  1013fd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101400:	89 04 24             	mov    %eax,(%esp)
  101403:	e8 f9 fa ff ff       	call   100f01 <mem_free>
	mem_free(pp1);
  101408:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10140b:	89 04 24             	mov    %eax,(%esp)
  10140e:	e8 ee fa ff ff       	call   100f01 <mem_free>
	mem_free(pp2);
  101413:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101416:	89 04 24             	mov    %eax,(%esp)
  101419:	e8 e3 fa ff ff       	call   100f01 <mem_free>

	cprintf("mem_check() succeeded!\n");
  10141e:	c7 04 24 5f 8b 10 00 	movl   $0x108b5f,(%esp)
  101425:	e8 67 6b 00 00       	call   107f91 <cprintf>
}
  10142a:	c9                   	leave  
  10142b:	c3                   	ret    

0010142c <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10142c:	55                   	push   %ebp
  10142d:	89 e5                	mov    %esp,%ebp
  10142f:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101432:	8b 55 08             	mov    0x8(%ebp),%edx
  101435:	8b 45 0c             	mov    0xc(%ebp),%eax
  101438:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10143b:	f0 87 02             	lock xchg %eax,(%edx)
  10143e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  101441:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  101444:	c9                   	leave  
  101445:	c3                   	ret    

00101446 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101446:	55                   	push   %ebp
  101447:	89 e5                	mov    %esp,%ebp
  101449:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10144c:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10144f:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101452:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101455:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101458:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10145d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101460:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101463:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101469:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10146e:	74 24                	je     101494 <cpu_cur+0x4e>
  101470:	c7 44 24 0c 77 8b 10 	movl   $0x108b77,0xc(%esp)
  101477:	00 
  101478:	c7 44 24 08 8d 8b 10 	movl   $0x108b8d,0x8(%esp)
  10147f:	00 
  101480:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101487:	00 
  101488:	c7 04 24 a2 8b 10 00 	movl   $0x108ba2,(%esp)
  10148f:	e8 9a f3 ff ff       	call   10082e <debug_panic>
	return c;
  101494:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101497:	c9                   	leave  
  101498:	c3                   	ret    

00101499 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101499:	55                   	push   %ebp
  10149a:	89 e5                	mov    %esp,%ebp
  10149c:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10149f:	e8 a2 ff ff ff       	call   101446 <cpu_cur>
  1014a4:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  1014a9:	0f 94 c0             	sete   %al
  1014ac:	0f b6 c0             	movzbl %al,%eax
}
  1014af:	c9                   	leave  
  1014b0:	c3                   	ret    

001014b1 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  1014b1:	55                   	push   %ebp
  1014b2:	89 e5                	mov    %esp,%ebp
  1014b4:	53                   	push   %ebx
  1014b5:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  1014b8:	e8 89 ff ff ff       	call   101446 <cpu_cur>
  1014bd:	89 45 f0             	mov    %eax,-0x10(%ebp)

	c->tss.ts_ss0 = CPU_GDT_KDATA;
  1014c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014c3:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)
	c->tss.ts_esp0 = (uintptr_t)c->kstackhi; 
  1014c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014cc:	05 00 10 00 00       	add    $0x1000,%eax
  1014d1:	89 c2                	mov    %eax,%edx
  1014d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014d6:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->gdt[CPU_GDT_TSS>>3] = SEGDESC16(0, STS_T32A, (uintptr_t)(&c->tss), sizeof(c->tss) - 1, 0);
  1014d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014dc:	83 c0 38             	add    $0x38,%eax
  1014df:	89 c3                	mov    %eax,%ebx
  1014e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014e4:	83 c0 38             	add    $0x38,%eax
  1014e7:	c1 e8 10             	shr    $0x10,%eax
  1014ea:	89 c1                	mov    %eax,%ecx
  1014ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014ef:	83 c0 38             	add    $0x38,%eax
  1014f2:	c1 e8 18             	shr    $0x18,%eax
  1014f5:	89 c2                	mov    %eax,%edx
  1014f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014fa:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  101500:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101503:	66 89 58 32          	mov    %bx,0x32(%eax)
  101507:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10150a:	88 48 34             	mov    %cl,0x34(%eax)
  10150d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101510:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101514:	83 e1 f0             	and    $0xfffffff0,%ecx
  101517:	83 c9 09             	or     $0x9,%ecx
  10151a:	88 48 35             	mov    %cl,0x35(%eax)
  10151d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101520:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101524:	83 e1 ef             	and    $0xffffffef,%ecx
  101527:	88 48 35             	mov    %cl,0x35(%eax)
  10152a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10152d:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101531:	83 e1 9f             	and    $0xffffff9f,%ecx
  101534:	88 48 35             	mov    %cl,0x35(%eax)
  101537:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10153a:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  10153e:	83 c9 80             	or     $0xffffff80,%ecx
  101541:	88 48 35             	mov    %cl,0x35(%eax)
  101544:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101547:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10154b:	83 e1 f0             	and    $0xfffffff0,%ecx
  10154e:	88 48 36             	mov    %cl,0x36(%eax)
  101551:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101554:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101558:	83 e1 ef             	and    $0xffffffef,%ecx
  10155b:	88 48 36             	mov    %cl,0x36(%eax)
  10155e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101561:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101565:	83 e1 df             	and    $0xffffffdf,%ecx
  101568:	88 48 36             	mov    %cl,0x36(%eax)
  10156b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10156e:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101572:	83 c9 40             	or     $0x40,%ecx
  101575:	88 48 36             	mov    %cl,0x36(%eax)
  101578:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10157b:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10157f:	83 e1 7f             	and    $0x7f,%ecx
  101582:	88 48 36             	mov    %cl,0x36(%eax)
  101585:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101588:	88 50 37             	mov    %dl,0x37(%eax)


	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  10158b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10158e:	66 c7 45 ea 37 00    	movw   $0x37,-0x16(%ebp)
  101594:	89 45 ec             	mov    %eax,-0x14(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  101597:	0f 01 55 ea          	lgdtl  -0x16(%ebp)
  10159b:	66 c7 45 f6 30 00    	movw   $0x30,-0xa(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1015a1:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  1015a5:	0f 00 d8             	ltr    %ax
	ltr(CPU_GDT_TSS);
	
	// Reload all segment registers.
	//asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
	//asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1015a8:	b8 10 00 00 00       	mov    $0x10,%eax
  1015ad:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  1015af:	b8 10 00 00 00       	mov    $0x10,%eax
  1015b4:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1015b6:	b8 10 00 00 00       	mov    $0x10,%eax
  1015bb:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  1015bd:	ea c4 15 10 00 08 00 	ljmp   $0x8,$0x1015c4

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  1015c4:	b8 00 00 00 00       	mov    $0x0,%eax
  1015c9:	0f 00 d0             	lldt   %ax
}
  1015cc:	83 c4 14             	add    $0x14,%esp
  1015cf:	5b                   	pop    %ebx
  1015d0:	5d                   	pop    %ebp
  1015d1:	c3                   	ret    

001015d2 <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  1015d2:	55                   	push   %ebp
  1015d3:	89 e5                	mov    %esp,%ebp
  1015d5:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  1015d8:	e8 dd f8 ff ff       	call   100eba <mem_alloc>
  1015dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  1015e0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1015e4:	75 24                	jne    10160a <cpu_alloc+0x38>
  1015e6:	c7 44 24 0c af 8b 10 	movl   $0x108baf,0xc(%esp)
  1015ed:	00 
  1015ee:	c7 44 24 08 8d 8b 10 	movl   $0x108b8d,0x8(%esp)
  1015f5:	00 
  1015f6:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  1015fd:	00 
  1015fe:	c7 04 24 b7 8b 10 00 	movl   $0x108bb7,(%esp)
  101605:	e8 24 f2 ff ff       	call   10082e <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  10160a:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10160d:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  101612:	89 d1                	mov    %edx,%ecx
  101614:	29 c1                	sub    %eax,%ecx
  101616:	89 c8                	mov    %ecx,%eax
  101618:	c1 f8 03             	sar    $0x3,%eax
  10161b:	c1 e0 0c             	shl    $0xc,%eax
  10161e:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  101621:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  101628:	00 
  101629:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101630:	00 
  101631:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101634:	89 04 24             	mov    %eax,(%esp)
  101637:	e8 3a 6b 00 00       	call   108176 <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  10163c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10163f:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101646:	00 
  101647:	c7 44 24 04 00 b0 10 	movl   $0x10b000,0x4(%esp)
  10164e:	00 
  10164f:	89 04 24             	mov    %eax,(%esp)
  101652:	e8 93 6b 00 00       	call   1081ea <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  101657:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10165a:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  101661:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  101664:	a1 00 c0 10 00       	mov    0x10c000,%eax
  101669:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10166c:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  10166e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101671:	05 a8 00 00 00       	add    $0xa8,%eax
  101676:	a3 00 c0 10 00       	mov    %eax,0x10c000

	return c;
  10167b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  10167e:	c9                   	leave  
  10167f:	c3                   	ret    

00101680 <cpu_bootothers>:

void
cpu_bootothers(void)
{
  101680:	55                   	push   %ebp
  101681:	89 e5                	mov    %esp,%ebp
  101683:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  101686:	e8 0e fe ff ff       	call   101499 <cpu_onboot>
  10168b:	85 c0                	test   %eax,%eax
  10168d:	75 1f                	jne    1016ae <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  10168f:	e8 b2 fd ff ff       	call   101446 <cpu_cur>
  101694:	05 b0 00 00 00       	add    $0xb0,%eax
  101699:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1016a0:	00 
  1016a1:	89 04 24             	mov    %eax,(%esp)
  1016a4:	e8 83 fd ff ff       	call   10142c <xchg>
		return;
  1016a9:	e9 91 00 00 00       	jmp    10173f <cpu_bootothers+0xbf>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  1016ae:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  1016b5:	b8 6a 00 00 00       	mov    $0x6a,%eax
  1016ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  1016be:	c7 44 24 04 42 85 11 	movl   $0x118542,0x4(%esp)
  1016c5:	00 
  1016c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1016c9:	89 04 24             	mov    %eax,(%esp)
  1016cc:	e8 19 6b 00 00       	call   1081ea <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  1016d1:	c7 45 f4 00 b0 10 00 	movl   $0x10b000,-0xc(%ebp)
  1016d8:	eb 5f                	jmp    101739 <cpu_bootothers+0xb9>
		if(c == cpu_cur())  // We''ve started already.
  1016da:	e8 67 fd ff ff       	call   101446 <cpu_cur>
  1016df:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1016e2:	74 48                	je     10172c <cpu_bootothers+0xac>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  1016e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1016e7:	83 e8 04             	sub    $0x4,%eax
  1016ea:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1016ed:	81 c2 00 10 00 00    	add    $0x1000,%edx
  1016f3:	89 10                	mov    %edx,(%eax)
		*(void**)(code-8) = init;
  1016f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1016f8:	83 e8 08             	sub    $0x8,%eax
  1016fb:	c7 00 91 00 10 00    	movl   $0x100091,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  101701:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101704:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101707:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10170e:	0f b6 c0             	movzbl %al,%eax
  101711:	89 54 24 04          	mov    %edx,0x4(%esp)
  101715:	89 04 24             	mov    %eax,(%esp)
  101718:	e8 6b 5e 00 00       	call   107588 <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  10171d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101720:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  101726:	85 c0                	test   %eax,%eax
  101728:	74 f3                	je     10171d <cpu_bootothers+0x9d>
  10172a:	eb 01                	jmp    10172d <cpu_bootothers+0xad>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
		if(c == cpu_cur())  // We''ve started already.
			continue;
  10172c:	90                   	nop
	uint8_t *code = (uint8_t*)0x1000;
	memmove(code, _binary_obj_boot_bootother_start,
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  10172d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101730:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101736:	89 45 f4             	mov    %eax,-0xc(%ebp)
  101739:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10173d:	75 9b                	jne    1016da <cpu_bootothers+0x5a>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
			;
	}
}
  10173f:	c9                   	leave  
  101740:	c3                   	ret    

00101741 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101741:	55                   	push   %ebp
  101742:	89 e5                	mov    %esp,%ebp
  101744:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101747:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10174a:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10174d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101750:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101753:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101758:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10175b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10175e:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101764:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101769:	74 24                	je     10178f <cpu_cur+0x4e>
  10176b:	c7 44 24 0c e0 8b 10 	movl   $0x108be0,0xc(%esp)
  101772:	00 
  101773:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  10177a:	00 
  10177b:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101782:	00 
  101783:	c7 04 24 0b 8c 10 00 	movl   $0x108c0b,(%esp)
  10178a:	e8 9f f0 ff ff       	call   10082e <debug_panic>
	return c;
  10178f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101792:	c9                   	leave  
  101793:	c3                   	ret    

00101794 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101794:	55                   	push   %ebp
  101795:	89 e5                	mov    %esp,%ebp
  101797:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10179a:	e8 a2 ff ff ff       	call   101741 <cpu_cur>
  10179f:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  1017a4:	0f 94 c0             	sete   %al
  1017a7:	0f b6 c0             	movzbl %al,%eax
}
  1017aa:	c9                   	leave  
  1017ab:	c3                   	ret    

001017ac <trap_init_idt>:

extern uint32_t vectors[];

static void
trap_init_idt(void)
{
  1017ac:	55                   	push   %ebp
  1017ad:	89 e5                	mov    %esp,%ebp
  1017af:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  1017b2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1017b9:	e9 bc 00 00 00       	jmp    10187a <trap_init_idt+0xce>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
  1017be:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1017c1:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1017c4:	8b 14 95 10 c0 10 00 	mov    0x10c010(,%edx,4),%edx
  1017cb:	66 89 14 c5 20 a2 11 	mov    %dx,0x11a220(,%eax,8)
  1017d2:	00 
  1017d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1017d6:	66 c7 04 c5 22 a2 11 	movw   $0x8,0x11a222(,%eax,8)
  1017dd:	00 08 00 
  1017e0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1017e3:	0f b6 14 c5 24 a2 11 	movzbl 0x11a224(,%eax,8),%edx
  1017ea:	00 
  1017eb:	83 e2 e0             	and    $0xffffffe0,%edx
  1017ee:	88 14 c5 24 a2 11 00 	mov    %dl,0x11a224(,%eax,8)
  1017f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1017f8:	0f b6 14 c5 24 a2 11 	movzbl 0x11a224(,%eax,8),%edx
  1017ff:	00 
  101800:	83 e2 1f             	and    $0x1f,%edx
  101803:	88 14 c5 24 a2 11 00 	mov    %dl,0x11a224(,%eax,8)
  10180a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10180d:	0f b6 14 c5 25 a2 11 	movzbl 0x11a225(,%eax,8),%edx
  101814:	00 
  101815:	83 ca 0f             	or     $0xf,%edx
  101818:	88 14 c5 25 a2 11 00 	mov    %dl,0x11a225(,%eax,8)
  10181f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101822:	0f b6 14 c5 25 a2 11 	movzbl 0x11a225(,%eax,8),%edx
  101829:	00 
  10182a:	83 e2 ef             	and    $0xffffffef,%edx
  10182d:	88 14 c5 25 a2 11 00 	mov    %dl,0x11a225(,%eax,8)
  101834:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101837:	0f b6 14 c5 25 a2 11 	movzbl 0x11a225(,%eax,8),%edx
  10183e:	00 
  10183f:	83 ca 60             	or     $0x60,%edx
  101842:	88 14 c5 25 a2 11 00 	mov    %dl,0x11a225(,%eax,8)
  101849:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10184c:	0f b6 14 c5 25 a2 11 	movzbl 0x11a225(,%eax,8),%edx
  101853:	00 
  101854:	83 ca 80             	or     $0xffffff80,%edx
  101857:	88 14 c5 25 a2 11 00 	mov    %dl,0x11a225(,%eax,8)
  10185e:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101861:	8b 55 fc             	mov    -0x4(%ebp),%edx
  101864:	8b 14 95 10 c0 10 00 	mov    0x10c010(,%edx,4),%edx
  10186b:	c1 ea 10             	shr    $0x10,%edx
  10186e:	66 89 14 c5 26 a2 11 	mov    %dx,0x11a226(,%eax,8)
  101875:	00 
	extern segdesc gdt[];
	
	//panic("trap_init() not implemented.");
	int i;

	for(i = 0; i < 20; i++)
  101876:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  10187a:	83 7d fc 13          	cmpl   $0x13,-0x4(%ebp)
  10187e:	0f 8e 3a ff ff ff    	jle    1017be <trap_init_idt+0x12>
	{
		SETGATE(idt[i], 1, CPU_GDT_KCODE, vectors[i], 3);
	}
	SETGATE(idt[T_SECEV], 1, CPU_GDT_KCODE, vectors[T_SECEV], 3);
  101884:	a1 88 c0 10 00       	mov    0x10c088,%eax
  101889:	66 a3 10 a3 11 00    	mov    %ax,0x11a310
  10188f:	66 c7 05 12 a3 11 00 	movw   $0x8,0x11a312
  101896:	08 00 
  101898:	0f b6 05 14 a3 11 00 	movzbl 0x11a314,%eax
  10189f:	83 e0 e0             	and    $0xffffffe0,%eax
  1018a2:	a2 14 a3 11 00       	mov    %al,0x11a314
  1018a7:	0f b6 05 14 a3 11 00 	movzbl 0x11a314,%eax
  1018ae:	83 e0 1f             	and    $0x1f,%eax
  1018b1:	a2 14 a3 11 00       	mov    %al,0x11a314
  1018b6:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  1018bd:	83 c8 0f             	or     $0xf,%eax
  1018c0:	a2 15 a3 11 00       	mov    %al,0x11a315
  1018c5:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  1018cc:	83 e0 ef             	and    $0xffffffef,%eax
  1018cf:	a2 15 a3 11 00       	mov    %al,0x11a315
  1018d4:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  1018db:	83 c8 60             	or     $0x60,%eax
  1018de:	a2 15 a3 11 00       	mov    %al,0x11a315
  1018e3:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  1018ea:	83 c8 80             	or     $0xffffff80,%eax
  1018ed:	a2 15 a3 11 00       	mov    %al,0x11a315
  1018f2:	a1 88 c0 10 00       	mov    0x10c088,%eax
  1018f7:	c1 e8 10             	shr    $0x10,%eax
  1018fa:	66 a3 16 a3 11 00    	mov    %ax,0x11a316
	SETGATE(idt[T_SYSCALL], 1, CPU_GDT_KCODE, vectors[T_SYSCALL], 3);
  101900:	a1 d0 c0 10 00       	mov    0x10c0d0,%eax
  101905:	66 a3 a0 a3 11 00    	mov    %ax,0x11a3a0
  10190b:	66 c7 05 a2 a3 11 00 	movw   $0x8,0x11a3a2
  101912:	08 00 
  101914:	0f b6 05 a4 a3 11 00 	movzbl 0x11a3a4,%eax
  10191b:	83 e0 e0             	and    $0xffffffe0,%eax
  10191e:	a2 a4 a3 11 00       	mov    %al,0x11a3a4
  101923:	0f b6 05 a4 a3 11 00 	movzbl 0x11a3a4,%eax
  10192a:	83 e0 1f             	and    $0x1f,%eax
  10192d:	a2 a4 a3 11 00       	mov    %al,0x11a3a4
  101932:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  101939:	83 c8 0f             	or     $0xf,%eax
  10193c:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  101941:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  101948:	83 e0 ef             	and    $0xffffffef,%eax
  10194b:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  101950:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  101957:	83 c8 60             	or     $0x60,%eax
  10195a:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  10195f:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  101966:	83 c8 80             	or     $0xffffff80,%eax
  101969:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  10196e:	a1 d0 c0 10 00       	mov    0x10c0d0,%eax
  101973:	c1 e8 10             	shr    $0x10,%eax
  101976:	66 a3 a6 a3 11 00    	mov    %ax,0x11a3a6
	SETGATE(idt[T_LTIMER], 1, CPU_GDT_KCODE, vectors[T_LTIMER], 3);
  10197c:	a1 d4 c0 10 00       	mov    0x10c0d4,%eax
  101981:	66 a3 a8 a3 11 00    	mov    %ax,0x11a3a8
  101987:	66 c7 05 aa a3 11 00 	movw   $0x8,0x11a3aa
  10198e:	08 00 
  101990:	0f b6 05 ac a3 11 00 	movzbl 0x11a3ac,%eax
  101997:	83 e0 e0             	and    $0xffffffe0,%eax
  10199a:	a2 ac a3 11 00       	mov    %al,0x11a3ac
  10199f:	0f b6 05 ac a3 11 00 	movzbl 0x11a3ac,%eax
  1019a6:	83 e0 1f             	and    $0x1f,%eax
  1019a9:	a2 ac a3 11 00       	mov    %al,0x11a3ac
  1019ae:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  1019b5:	83 c8 0f             	or     $0xf,%eax
  1019b8:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  1019bd:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  1019c4:	83 e0 ef             	and    $0xffffffef,%eax
  1019c7:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  1019cc:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  1019d3:	83 c8 60             	or     $0x60,%eax
  1019d6:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  1019db:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  1019e2:	83 c8 80             	or     $0xffffff80,%eax
  1019e5:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  1019ea:	a1 d4 c0 10 00       	mov    0x10c0d4,%eax
  1019ef:	c1 e8 10             	shr    $0x10,%eax
  1019f2:	66 a3 ae a3 11 00    	mov    %ax,0x11a3ae
}
  1019f8:	c9                   	leave  
  1019f9:	c3                   	ret    

001019fa <trap_init>:

void
trap_init(void)
{
  1019fa:	55                   	push   %ebp
  1019fb:	89 e5                	mov    %esp,%ebp
  1019fd:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  101a00:	e8 8f fd ff ff       	call   101794 <cpu_onboot>
  101a05:	85 c0                	test   %eax,%eax
  101a07:	74 05                	je     101a0e <trap_init+0x14>
		trap_init_idt();
  101a09:	e8 9e fd ff ff       	call   1017ac <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  101a0e:	0f 01 1d 04 c0 10 00 	lidtl  0x10c004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  101a15:	e8 7a fd ff ff       	call   101794 <cpu_onboot>
  101a1a:	85 c0                	test   %eax,%eax
  101a1c:	74 05                	je     101a23 <trap_init+0x29>
		trap_check_kernel();
  101a1e:	e8 0b 03 00 00       	call   101d2e <trap_check_kernel>
}
  101a23:	c9                   	leave  
  101a24:	c3                   	ret    

00101a25 <trap_name>:

const char *trap_name(int trapno)
{
  101a25:	55                   	push   %ebp
  101a26:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101a28:	8b 45 08             	mov    0x8(%ebp),%eax
  101a2b:	83 f8 13             	cmp    $0x13,%eax
  101a2e:	77 0c                	ja     101a3c <trap_name+0x17>
		return excnames[trapno];
  101a30:	8b 45 08             	mov    0x8(%ebp),%eax
  101a33:	8b 04 85 40 90 10 00 	mov    0x109040(,%eax,4),%eax
  101a3a:	eb 25                	jmp    101a61 <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  101a3c:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  101a40:	75 07                	jne    101a49 <trap_name+0x24>
		return "System call";
  101a42:	b8 18 8c 10 00       	mov    $0x108c18,%eax
  101a47:	eb 18                	jmp    101a61 <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  101a49:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  101a4d:	7e 0d                	jle    101a5c <trap_name+0x37>
  101a4f:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  101a53:	7f 07                	jg     101a5c <trap_name+0x37>
		return "Hardware Interrupt";
  101a55:	b8 24 8c 10 00       	mov    $0x108c24,%eax
  101a5a:	eb 05                	jmp    101a61 <trap_name+0x3c>
	return "(unknown trap)";
  101a5c:	b8 37 8c 10 00       	mov    $0x108c37,%eax
}
  101a61:	5d                   	pop    %ebp
  101a62:	c3                   	ret    

00101a63 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101a63:	55                   	push   %ebp
  101a64:	89 e5                	mov    %esp,%ebp
  101a66:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  101a69:	8b 45 08             	mov    0x8(%ebp),%eax
  101a6c:	8b 00                	mov    (%eax),%eax
  101a6e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a72:	c7 04 24 46 8c 10 00 	movl   $0x108c46,(%esp)
  101a79:	e8 13 65 00 00       	call   107f91 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  101a7e:	8b 45 08             	mov    0x8(%ebp),%eax
  101a81:	8b 40 04             	mov    0x4(%eax),%eax
  101a84:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a88:	c7 04 24 55 8c 10 00 	movl   $0x108c55,(%esp)
  101a8f:	e8 fd 64 00 00       	call   107f91 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101a94:	8b 45 08             	mov    0x8(%ebp),%eax
  101a97:	8b 40 08             	mov    0x8(%eax),%eax
  101a9a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101a9e:	c7 04 24 64 8c 10 00 	movl   $0x108c64,(%esp)
  101aa5:	e8 e7 64 00 00       	call   107f91 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  101aaa:	8b 45 08             	mov    0x8(%ebp),%eax
  101aad:	8b 40 10             	mov    0x10(%eax),%eax
  101ab0:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ab4:	c7 04 24 73 8c 10 00 	movl   $0x108c73,(%esp)
  101abb:	e8 d1 64 00 00       	call   107f91 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101ac0:	8b 45 08             	mov    0x8(%ebp),%eax
  101ac3:	8b 40 14             	mov    0x14(%eax),%eax
  101ac6:	89 44 24 04          	mov    %eax,0x4(%esp)
  101aca:	c7 04 24 82 8c 10 00 	movl   $0x108c82,(%esp)
  101ad1:	e8 bb 64 00 00       	call   107f91 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101ad6:	8b 45 08             	mov    0x8(%ebp),%eax
  101ad9:	8b 40 18             	mov    0x18(%eax),%eax
  101adc:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ae0:	c7 04 24 91 8c 10 00 	movl   $0x108c91,(%esp)
  101ae7:	e8 a5 64 00 00       	call   107f91 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  101aec:	8b 45 08             	mov    0x8(%ebp),%eax
  101aef:	8b 40 1c             	mov    0x1c(%eax),%eax
  101af2:	89 44 24 04          	mov    %eax,0x4(%esp)
  101af6:	c7 04 24 a0 8c 10 00 	movl   $0x108ca0,(%esp)
  101afd:	e8 8f 64 00 00       	call   107f91 <cprintf>
}
  101b02:	c9                   	leave  
  101b03:	c3                   	ret    

00101b04 <trap_print>:

void
trap_print(trapframe *tf)
{
  101b04:	55                   	push   %ebp
  101b05:	89 e5                	mov    %esp,%ebp
  101b07:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  101b0a:	8b 45 08             	mov    0x8(%ebp),%eax
  101b0d:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b11:	c7 04 24 af 8c 10 00 	movl   $0x108caf,(%esp)
  101b18:	e8 74 64 00 00       	call   107f91 <cprintf>
	trap_print_regs(&tf->regs);
  101b1d:	8b 45 08             	mov    0x8(%ebp),%eax
  101b20:	89 04 24             	mov    %eax,(%esp)
  101b23:	e8 3b ff ff ff       	call   101a63 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  101b28:	8b 45 08             	mov    0x8(%ebp),%eax
  101b2b:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101b2f:	0f b7 c0             	movzwl %ax,%eax
  101b32:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b36:	c7 04 24 c1 8c 10 00 	movl   $0x108cc1,(%esp)
  101b3d:	e8 4f 64 00 00       	call   107f91 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101b42:	8b 45 08             	mov    0x8(%ebp),%eax
  101b45:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101b49:	0f b7 c0             	movzwl %ax,%eax
  101b4c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b50:	c7 04 24 d4 8c 10 00 	movl   $0x108cd4,(%esp)
  101b57:	e8 35 64 00 00       	call   107f91 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101b5c:	8b 45 08             	mov    0x8(%ebp),%eax
  101b5f:	8b 40 30             	mov    0x30(%eax),%eax
  101b62:	89 04 24             	mov    %eax,(%esp)
  101b65:	e8 bb fe ff ff       	call   101a25 <trap_name>
  101b6a:	8b 55 08             	mov    0x8(%ebp),%edx
  101b6d:	8b 52 30             	mov    0x30(%edx),%edx
  101b70:	89 44 24 08          	mov    %eax,0x8(%esp)
  101b74:	89 54 24 04          	mov    %edx,0x4(%esp)
  101b78:	c7 04 24 e7 8c 10 00 	movl   $0x108ce7,(%esp)
  101b7f:	e8 0d 64 00 00       	call   107f91 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101b84:	8b 45 08             	mov    0x8(%ebp),%eax
  101b87:	8b 40 34             	mov    0x34(%eax),%eax
  101b8a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101b8e:	c7 04 24 f9 8c 10 00 	movl   $0x108cf9,(%esp)
  101b95:	e8 f7 63 00 00       	call   107f91 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  101b9a:	8b 45 08             	mov    0x8(%ebp),%eax
  101b9d:	8b 40 38             	mov    0x38(%eax),%eax
  101ba0:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ba4:	c7 04 24 08 8d 10 00 	movl   $0x108d08,(%esp)
  101bab:	e8 e1 63 00 00       	call   107f91 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101bb0:	8b 45 08             	mov    0x8(%ebp),%eax
  101bb3:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101bb7:	0f b7 c0             	movzwl %ax,%eax
  101bba:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bbe:	c7 04 24 17 8d 10 00 	movl   $0x108d17,(%esp)
  101bc5:	e8 c7 63 00 00       	call   107f91 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  101bca:	8b 45 08             	mov    0x8(%ebp),%eax
  101bcd:	8b 40 40             	mov    0x40(%eax),%eax
  101bd0:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bd4:	c7 04 24 2a 8d 10 00 	movl   $0x108d2a,(%esp)
  101bdb:	e8 b1 63 00 00       	call   107f91 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  101be0:	8b 45 08             	mov    0x8(%ebp),%eax
  101be3:	8b 40 44             	mov    0x44(%eax),%eax
  101be6:	89 44 24 04          	mov    %eax,0x4(%esp)
  101bea:	c7 04 24 39 8d 10 00 	movl   $0x108d39,(%esp)
  101bf1:	e8 9b 63 00 00       	call   107f91 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  101bf6:	8b 45 08             	mov    0x8(%ebp),%eax
  101bf9:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101bfd:	0f b7 c0             	movzwl %ax,%eax
  101c00:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c04:	c7 04 24 48 8d 10 00 	movl   $0x108d48,(%esp)
  101c0b:	e8 81 63 00 00       	call   107f91 <cprintf>
}
  101c10:	c9                   	leave  
  101c11:	c3                   	ret    

00101c12 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  101c12:	55                   	push   %ebp
  101c13:	89 e5                	mov    %esp,%ebp
  101c15:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  101c18:	fc                   	cld    

// Disable external device interrupts.
static gcc_inline void
cli(void)
{
	asm volatile("cli");
  101c19:	fa                   	cli    
	cli();

	//cprintf("process %p is in trap(), trapno == %d\n", proc_cur(), tf->trapno);

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  101c1a:	e8 22 fb ff ff       	call   101741 <cpu_cur>
  101c1f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover){
  101c22:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c25:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101c2b:	85 c0                	test   %eax,%eax
  101c2d:	74 1e                	je     101c4d <trap+0x3b>
		//cprintf("before c->recover()\n");
		c->recover(tf, c->recoverdata);}
  101c2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c32:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  101c38:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101c3b:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  101c41:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c45:	8b 45 08             	mov    0x8(%ebp),%eax
  101c48:	89 04 24             	mov    %eax,(%esp)
  101c4b:	ff d2                	call   *%edx

	// Lab 2: your trap handling code here!
	if(tf->trapno == T_SYSCALL){
  101c4d:	8b 45 08             	mov    0x8(%ebp),%eax
  101c50:	8b 40 30             	mov    0x30(%eax),%eax
  101c53:	83 f8 30             	cmp    $0x30,%eax
  101c56:	75 0b                	jne    101c63 <trap+0x51>
		syscall(tf);
  101c58:	8b 45 08             	mov    0x8(%ebp),%eax
  101c5b:	89 04 24             	mov    %eax,(%esp)
  101c5e:	e8 4d 24 00 00       	call   1040b0 <syscall>
		//panic("unhandler system call\n");
	}

    
	switch(tf->trapno){
  101c63:	8b 45 08             	mov    0x8(%ebp),%eax
  101c66:	8b 40 30             	mov    0x30(%eax),%eax
  101c69:	83 f8 27             	cmp    $0x27,%eax
  101c6c:	74 1c                	je     101c8a <trap+0x78>
  101c6e:	83 f8 31             	cmp    $0x31,%eax
  101c71:	74 07                	je     101c7a <trap+0x68>
  101c73:	83 f8 0e             	cmp    $0xe,%eax
  101c76:	74 2e                	je     101ca6 <trap+0x94>
  101c78:	eb 6f                	jmp    101ce9 <trap+0xd7>
		case T_LTIMER:
			//cprintf("T_LTIMER proc: 0x%x\n",proc_cur());
			lapic_eoi();
  101c7a:	e8 7a 58 00 00       	call   1074f9 <lapic_eoi>
			proc_yield(tf);
  101c7f:	8b 45 08             	mov    0x8(%ebp),%eax
  101c82:	89 04 24             	mov    %eax,(%esp)
  101c85:	e8 69 18 00 00       	call   1034f3 <proc_yield>
			break;
		case T_IRQ0 + IRQ_SPURIOUS:
			panic(" IRQ_SPURIOUS ");
  101c8a:	c7 44 24 08 5b 8d 10 	movl   $0x108d5b,0x8(%esp)
  101c91:	00 
  101c92:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  101c99:	00 
  101c9a:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101ca1:	e8 88 eb ff ff       	call   10082e <debug_panic>
		case T_PGFLT:
			if(spinlock_holding(&cons_lock))
  101ca6:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  101cad:	e8 18 0b 00 00       	call   1027ca <spinlock_holding>
  101cb2:	85 c0                	test   %eax,%eax
  101cb4:	74 0c                	je     101cc2 <trap+0xb0>
				spinlock_release(&cons_lock);
  101cb6:	c7 04 24 c0 ec 11 00 	movl   $0x11ecc0,(%esp)
  101cbd:	e8 ae 0a 00 00       	call   102770 <spinlock_release>
			trap_print(tf);
  101cc2:	8b 45 08             	mov    0x8(%ebp),%eax
  101cc5:	89 04 24             	mov    %eax,(%esp)
  101cc8:	e8 37 fe ff ff       	call   101b04 <trap_print>
			panic(" Page Fault ");
  101ccd:	c7 44 24 08 76 8d 10 	movl   $0x108d76,0x8(%esp)
  101cd4:	00 
  101cd5:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  101cdc:	00 
  101cdd:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101ce4:	e8 45 eb ff ff       	call   10082e <debug_panic>

		default:
			proc_ret(tf, -1);
  101ce9:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  101cf0:	ff 
  101cf1:	8b 45 08             	mov    0x8(%ebp),%eax
  101cf4:	89 04 24             	mov    %eax,(%esp)
  101cf7:	e8 35 18 00 00       	call   103531 <proc_ret>

00101cfc <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101cfc:	55                   	push   %ebp
  101cfd:	89 e5                	mov    %esp,%ebp
  101cff:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101d02:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d05:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101d08:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101d0b:	8b 00                	mov    (%eax),%eax
  101d0d:	89 c2                	mov    %eax,%edx
  101d0f:	8b 45 08             	mov    0x8(%ebp),%eax
  101d12:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  101d15:	8b 45 08             	mov    0x8(%ebp),%eax
  101d18:	8b 40 30             	mov    0x30(%eax),%eax
  101d1b:	89 c2                	mov    %eax,%edx
  101d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101d20:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  101d23:	8b 45 08             	mov    0x8(%ebp),%eax
  101d26:	89 04 24             	mov    %eax,(%esp)
  101d29:	e8 c2 a3 00 00       	call   10c0f0 <trap_return>

00101d2e <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  101d2e:	55                   	push   %ebp
  101d2f:	89 e5                	mov    %esp,%ebp
  101d31:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101d34:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  101d37:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  101d3b:	0f b7 c0             	movzwl %ax,%eax
  101d3e:	83 e0 03             	and    $0x3,%eax
  101d41:	85 c0                	test   %eax,%eax
  101d43:	74 24                	je     101d69 <trap_check_kernel+0x3b>
  101d45:	c7 44 24 0c 83 8d 10 	movl   $0x108d83,0xc(%esp)
  101d4c:	00 
  101d4d:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  101d54:	00 
  101d55:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  101d5c:	00 
  101d5d:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101d64:	e8 c5 ea ff ff       	call   10082e <debug_panic>

	cpu *c = cpu_cur();
  101d69:	e8 d3 f9 ff ff       	call   101741 <cpu_cur>
  101d6e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  101d71:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101d74:	c7 80 a0 00 00 00 fc 	movl   $0x101cfc,0xa0(%eax)
  101d7b:	1c 10 00 
	trap_check(&c->recoverdata);
  101d7e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101d81:	05 a4 00 00 00       	add    $0xa4,%eax
  101d86:	89 04 24             	mov    %eax,(%esp)
  101d89:	e8 96 00 00 00       	call   101e24 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101d8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101d91:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101d98:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  101d9b:	c7 04 24 98 8d 10 00 	movl   $0x108d98,(%esp)
  101da2:	e8 ea 61 00 00       	call   107f91 <cprintf>
}
  101da7:	c9                   	leave  
  101da8:	c3                   	ret    

00101da9 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101da9:	55                   	push   %ebp
  101daa:	89 e5                	mov    %esp,%ebp
  101dac:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101daf:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  101db2:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101db6:	0f b7 c0             	movzwl %ax,%eax
  101db9:	83 e0 03             	and    $0x3,%eax
  101dbc:	83 f8 03             	cmp    $0x3,%eax
  101dbf:	74 24                	je     101de5 <trap_check_user+0x3c>
  101dc1:	c7 44 24 0c b8 8d 10 	movl   $0x108db8,0xc(%esp)
  101dc8:	00 
  101dc9:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  101dd0:	00 
  101dd1:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
  101dd8:	00 
  101dd9:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101de0:	e8 49 ea ff ff       	call   10082e <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101de5:	c7 45 f0 00 b0 10 00 	movl   $0x10b000,-0x10(%ebp)
	c->recover = trap_check_recover;
  101dec:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101def:	c7 80 a0 00 00 00 fc 	movl   $0x101cfc,0xa0(%eax)
  101df6:	1c 10 00 
	trap_check(&c->recoverdata);
  101df9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101dfc:	05 a4 00 00 00       	add    $0xa4,%eax
  101e01:	89 04 24             	mov    %eax,(%esp)
  101e04:	e8 1b 00 00 00       	call   101e24 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101e09:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101e0c:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101e13:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101e16:	c7 04 24 cd 8d 10 00 	movl   $0x108dcd,(%esp)
  101e1d:	e8 6f 61 00 00       	call   107f91 <cprintf>
}
  101e22:	c9                   	leave  
  101e23:	c3                   	ret    

00101e24 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  101e24:	55                   	push   %ebp
  101e25:	89 e5                	mov    %esp,%ebp
  101e27:	57                   	push   %edi
  101e28:	56                   	push   %esi
  101e29:	53                   	push   %ebx
  101e2a:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  101e2d:	c7 45 dc ce fa ed fe 	movl   $0xfeedface,-0x24(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101e34:	8b 45 08             	mov    0x8(%ebp),%eax
  101e37:	8d 55 d4             	lea    -0x2c(%ebp),%edx
  101e3a:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address or a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  101e3c:	c7 45 d4 73 1e 10 00 	movl   $0x101e73,-0x2c(%ebp)
	cprintf("1. &args.trapno == %x\n", &args);
  101e43:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  101e46:	89 44 24 04          	mov    %eax,0x4(%esp)
  101e4a:	c7 04 24 eb 8d 10 00 	movl   $0x108deb,(%esp)
  101e51:	e8 3b 61 00 00       	call   107f91 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101e56:	89 65 e0             	mov    %esp,-0x20(%ebp)
        return esp;
  101e59:	8b 45 e0             	mov    -0x20(%ebp),%eax
	cprintf(">>>>>>>>>>in trap_check : esp : 0x%x\n",read_esp());
  101e5c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101e60:	c7 04 24 04 8e 10 00 	movl   $0x108e04,(%esp)
  101e67:	e8 25 61 00 00       	call   107f91 <cprintf>
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  101e6c:	b8 00 00 00 00       	mov    $0x0,%eax
  101e71:	f7 f0                	div    %eax

00101e73 <after_div0>:
	cprintf("2. &args.trapno == %x\n", &args);
  101e73:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  101e76:	89 44 24 04          	mov    %eax,0x4(%esp)
  101e7a:	c7 04 24 2a 8e 10 00 	movl   $0x108e2a,(%esp)
  101e81:	e8 0b 61 00 00       	call   107f91 <cprintf>
	assert(args.trapno == T_DIVIDE);
  101e86:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101e89:	85 c0                	test   %eax,%eax
  101e8b:	74 24                	je     101eb1 <after_div0+0x3e>
  101e8d:	c7 44 24 0c 41 8e 10 	movl   $0x108e41,0xc(%esp)
  101e94:	00 
  101e95:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  101e9c:	00 
  101e9d:	c7 44 24 04 fe 00 00 	movl   $0xfe,0x4(%esp)
  101ea4:	00 
  101ea5:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101eac:	e8 7d e9 ff ff       	call   10082e <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101eb1:	8b 45 dc             	mov    -0x24(%ebp),%eax
  101eb4:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101eb9:	74 24                	je     101edf <after_div0+0x6c>
  101ebb:	c7 44 24 0c 59 8e 10 	movl   $0x108e59,0xc(%esp)
  101ec2:	00 
  101ec3:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  101eca:	00 
  101ecb:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  101ed2:	00 
  101ed3:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101eda:	e8 4f e9 ff ff       	call   10082e <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101edf:	c7 45 d4 e7 1e 10 00 	movl   $0x101ee7,-0x2c(%ebp)
	asm volatile("int3; after_breakpoint:");
  101ee6:	cc                   	int3   

00101ee7 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101ee7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101eea:	83 f8 03             	cmp    $0x3,%eax
  101eed:	74 24                	je     101f13 <after_breakpoint+0x2c>
  101eef:	c7 44 24 0c 6e 8e 10 	movl   $0x108e6e,0xc(%esp)
  101ef6:	00 
  101ef7:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  101efe:	00 
  101eff:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
  101f06:	00 
  101f07:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101f0e:	e8 1b e9 ff ff       	call   10082e <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101f13:	c7 45 d4 22 1f 10 00 	movl   $0x101f22,-0x2c(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101f1a:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101f1f:	01 c0                	add    %eax,%eax
  101f21:	ce                   	into   

00101f22 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101f22:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101f25:	83 f8 04             	cmp    $0x4,%eax
  101f28:	74 24                	je     101f4e <after_overflow+0x2c>
  101f2a:	c7 44 24 0c 85 8e 10 	movl   $0x108e85,0xc(%esp)
  101f31:	00 
  101f32:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  101f39:	00 
  101f3a:	c7 44 24 04 0d 01 00 	movl   $0x10d,0x4(%esp)
  101f41:	00 
  101f42:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101f49:	e8 e0 e8 ff ff       	call   10082e <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101f4e:	c7 45 d4 6b 1f 10 00 	movl   $0x101f6b,-0x2c(%ebp)
	int bounds[2] = { 1, 3 };
  101f55:	c7 45 cc 01 00 00 00 	movl   $0x1,-0x34(%ebp)
  101f5c:	c7 45 d0 03 00 00 00 	movl   $0x3,-0x30(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  101f63:	b8 00 00 00 00       	mov    $0x0,%eax
  101f68:	62 45 cc             	bound  %eax,-0x34(%ebp)

00101f6b <after_bound>:
	assert(args.trapno == T_BOUND);
  101f6b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101f6e:	83 f8 05             	cmp    $0x5,%eax
  101f71:	74 24                	je     101f97 <after_bound+0x2c>
  101f73:	c7 44 24 0c 9c 8e 10 	movl   $0x108e9c,0xc(%esp)
  101f7a:	00 
  101f7b:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  101f82:	00 
  101f83:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
  101f8a:	00 
  101f8b:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101f92:	e8 97 e8 ff ff       	call   10082e <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  101f97:	c7 45 d4 a0 1f 10 00 	movl   $0x101fa0,-0x2c(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  101f9e:	0f 0b                	ud2    

00101fa0 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  101fa0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101fa3:	83 f8 06             	cmp    $0x6,%eax
  101fa6:	74 24                	je     101fcc <after_illegal+0x2c>
  101fa8:	c7 44 24 0c b3 8e 10 	movl   $0x108eb3,0xc(%esp)
  101faf:	00 
  101fb0:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  101fb7:	00 
  101fb8:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  101fbf:	00 
  101fc0:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  101fc7:	e8 62 e8 ff ff       	call   10082e <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  101fcc:	c7 45 d4 da 1f 10 00 	movl   $0x101fda,-0x2c(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101fd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101fd8:	8e e0                	mov    %eax,%fs

00101fda <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101fda:	8b 45 d8             	mov    -0x28(%ebp),%eax
  101fdd:	83 f8 0d             	cmp    $0xd,%eax
  101fe0:	74 24                	je     102006 <after_gpfault+0x2c>
  101fe2:	c7 44 24 0c ca 8e 10 	movl   $0x108eca,0xc(%esp)
  101fe9:	00 
  101fea:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  101ff1:	00 
  101ff2:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
  101ff9:	00 
  101ffa:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  102001:	e8 28 e8 ff ff       	call   10082e <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  102006:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  102009:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  10200d:	0f b7 c0             	movzwl %ax,%eax
  102010:	83 e0 03             	and    $0x3,%eax
  102013:	85 c0                	test   %eax,%eax
  102015:	74 3a                	je     102051 <after_priv+0x2c>
		args.reip = after_priv;
  102017:	c7 45 d4 25 20 10 00 	movl   $0x102025,-0x2c(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  10201e:	0f 01 1d 04 c0 10 00 	lidtl  0x10c004

00102025 <after_priv>:
		assert(args.trapno == T_GPFLT);
  102025:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102028:	83 f8 0d             	cmp    $0xd,%eax
  10202b:	74 24                	je     102051 <after_priv+0x2c>
  10202d:	c7 44 24 0c ca 8e 10 	movl   $0x108eca,0xc(%esp)
  102034:	00 
  102035:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  10203c:	00 
  10203d:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
  102044:	00 
  102045:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  10204c:	e8 dd e7 ff ff       	call   10082e <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  102051:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102054:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  102059:	74 24                	je     10207f <after_priv+0x5a>
  10205b:	c7 44 24 0c 59 8e 10 	movl   $0x108e59,0xc(%esp)
  102062:	00 
  102063:	c7 44 24 08 f6 8b 10 	movl   $0x108bf6,0x8(%esp)
  10206a:	00 
  10206b:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  102072:	00 
  102073:	c7 04 24 6a 8d 10 00 	movl   $0x108d6a,(%esp)
  10207a:	e8 af e7 ff ff       	call   10082e <debug_panic>
	//cprintf("sfsfsfsfsfsfsfsfsf\n");
	*argsp = NULL;	// recovery mechanism not needed anymore
  10207f:	8b 45 08             	mov    0x8(%ebp),%eax
  102082:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  102088:	83 c4 3c             	add    $0x3c,%esp
  10208b:	5b                   	pop    %ebx
  10208c:	5e                   	pop    %esi
  10208d:	5f                   	pop    %edi
  10208e:	5d                   	pop    %ebp
  10208f:	c3                   	ret    

00102090 <vector0>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(vector0, 0)
  102090:	6a 00                	push   $0x0
  102092:	6a 00                	push   $0x0
  102094:	e9 3f a0 00 00       	jmp    10c0d8 <_alltraps>
  102099:	90                   	nop

0010209a <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  10209a:	6a 00                	push   $0x0
  10209c:	6a 01                	push   $0x1
  10209e:	e9 35 a0 00 00       	jmp    10c0d8 <_alltraps>
  1020a3:	90                   	nop

001020a4 <vector2>:
TRAPHANDLER_NOEC(vector2, 2)
  1020a4:	6a 00                	push   $0x0
  1020a6:	6a 02                	push   $0x2
  1020a8:	e9 2b a0 00 00       	jmp    10c0d8 <_alltraps>
  1020ad:	90                   	nop

001020ae <vector3>:
TRAPHANDLER_NOEC(vector3, 3)
  1020ae:	6a 00                	push   $0x0
  1020b0:	6a 03                	push   $0x3
  1020b2:	e9 21 a0 00 00       	jmp    10c0d8 <_alltraps>
  1020b7:	90                   	nop

001020b8 <vector4>:
TRAPHANDLER_NOEC(vector4, 4)
  1020b8:	6a 00                	push   $0x0
  1020ba:	6a 04                	push   $0x4
  1020bc:	e9 17 a0 00 00       	jmp    10c0d8 <_alltraps>
  1020c1:	90                   	nop

001020c2 <vector5>:
TRAPHANDLER_NOEC(vector5, 5)
  1020c2:	6a 00                	push   $0x0
  1020c4:	6a 05                	push   $0x5
  1020c6:	e9 0d a0 00 00       	jmp    10c0d8 <_alltraps>
  1020cb:	90                   	nop

001020cc <vector6>:
TRAPHANDLER_NOEC(vector6, 6)
  1020cc:	6a 00                	push   $0x0
  1020ce:	6a 06                	push   $0x6
  1020d0:	e9 03 a0 00 00       	jmp    10c0d8 <_alltraps>
  1020d5:	90                   	nop

001020d6 <vector7>:
TRAPHANDLER_NOEC(vector7, 7)
  1020d6:	6a 00                	push   $0x0
  1020d8:	6a 07                	push   $0x7
  1020da:	e9 f9 9f 00 00       	jmp    10c0d8 <_alltraps>
  1020df:	90                   	nop

001020e0 <vector8>:
TRAPHANDLER(vector8, 8)
  1020e0:	6a 08                	push   $0x8
  1020e2:	e9 f1 9f 00 00       	jmp    10c0d8 <_alltraps>
  1020e7:	90                   	nop

001020e8 <vector9>:
TRAPHANDLER_NOEC(vector9, 9)
  1020e8:	6a 00                	push   $0x0
  1020ea:	6a 09                	push   $0x9
  1020ec:	e9 e7 9f 00 00       	jmp    10c0d8 <_alltraps>
  1020f1:	90                   	nop

001020f2 <vector10>:
TRAPHANDLER(vector10, 10)
  1020f2:	6a 0a                	push   $0xa
  1020f4:	e9 df 9f 00 00       	jmp    10c0d8 <_alltraps>
  1020f9:	90                   	nop

001020fa <vector11>:
TRAPHANDLER(vector11, 11)
  1020fa:	6a 0b                	push   $0xb
  1020fc:	e9 d7 9f 00 00       	jmp    10c0d8 <_alltraps>
  102101:	90                   	nop

00102102 <vector12>:
TRAPHANDLER(vector12, 12)
  102102:	6a 0c                	push   $0xc
  102104:	e9 cf 9f 00 00       	jmp    10c0d8 <_alltraps>
  102109:	90                   	nop

0010210a <vector13>:
TRAPHANDLER(vector13, 13)
  10210a:	6a 0d                	push   $0xd
  10210c:	e9 c7 9f 00 00       	jmp    10c0d8 <_alltraps>
  102111:	90                   	nop

00102112 <vector14>:
TRAPHANDLER(vector14, 14)
  102112:	6a 0e                	push   $0xe
  102114:	e9 bf 9f 00 00       	jmp    10c0d8 <_alltraps>
  102119:	90                   	nop

0010211a <vector15>:
TRAPHANDLER_NOEC(vector15, 15)
  10211a:	6a 00                	push   $0x0
  10211c:	6a 0f                	push   $0xf
  10211e:	e9 b5 9f 00 00       	jmp    10c0d8 <_alltraps>
  102123:	90                   	nop

00102124 <vector16>:
TRAPHANDLER_NOEC(vector16, 16)
  102124:	6a 00                	push   $0x0
  102126:	6a 10                	push   $0x10
  102128:	e9 ab 9f 00 00       	jmp    10c0d8 <_alltraps>
  10212d:	90                   	nop

0010212e <vector17>:
TRAPHANDLER(vector17, 17)
  10212e:	6a 11                	push   $0x11
  102130:	e9 a3 9f 00 00       	jmp    10c0d8 <_alltraps>
  102135:	90                   	nop

00102136 <vector18>:
TRAPHANDLER_NOEC(vector18, 18)
  102136:	6a 00                	push   $0x0
  102138:	6a 12                	push   $0x12
  10213a:	e9 99 9f 00 00       	jmp    10c0d8 <_alltraps>
  10213f:	90                   	nop

00102140 <vector19>:
TRAPHANDLER_NOEC(vector19, 19)
  102140:	6a 00                	push   $0x0
  102142:	6a 13                	push   $0x13
  102144:	e9 8f 9f 00 00       	jmp    10c0d8 <_alltraps>
  102149:	90                   	nop

0010214a <vector20>:
TRAPHANDLER_NOEC(vector20, 20)
  10214a:	6a 00                	push   $0x0
  10214c:	6a 14                	push   $0x14
  10214e:	e9 85 9f 00 00       	jmp    10c0d8 <_alltraps>
  102153:	90                   	nop

00102154 <vector21>:
TRAPHANDLER_NOEC(vector21, 21)
  102154:	6a 00                	push   $0x0
  102156:	6a 15                	push   $0x15
  102158:	e9 7b 9f 00 00       	jmp    10c0d8 <_alltraps>
  10215d:	90                   	nop

0010215e <vector22>:
TRAPHANDLER_NOEC(vector22, 22)
  10215e:	6a 00                	push   $0x0
  102160:	6a 16                	push   $0x16
  102162:	e9 71 9f 00 00       	jmp    10c0d8 <_alltraps>
  102167:	90                   	nop

00102168 <vector23>:
TRAPHANDLER_NOEC(vector23, 23)
  102168:	6a 00                	push   $0x0
  10216a:	6a 17                	push   $0x17
  10216c:	e9 67 9f 00 00       	jmp    10c0d8 <_alltraps>
  102171:	90                   	nop

00102172 <vector24>:
TRAPHANDLER_NOEC(vector24, 24)
  102172:	6a 00                	push   $0x0
  102174:	6a 18                	push   $0x18
  102176:	e9 5d 9f 00 00       	jmp    10c0d8 <_alltraps>
  10217b:	90                   	nop

0010217c <vector25>:
TRAPHANDLER_NOEC(vector25, 25)
  10217c:	6a 00                	push   $0x0
  10217e:	6a 19                	push   $0x19
  102180:	e9 53 9f 00 00       	jmp    10c0d8 <_alltraps>
  102185:	90                   	nop

00102186 <vector26>:
TRAPHANDLER_NOEC(vector26, 26)
  102186:	6a 00                	push   $0x0
  102188:	6a 1a                	push   $0x1a
  10218a:	e9 49 9f 00 00       	jmp    10c0d8 <_alltraps>
  10218f:	90                   	nop

00102190 <vector27>:
TRAPHANDLER_NOEC(vector27, 27)
  102190:	6a 00                	push   $0x0
  102192:	6a 1b                	push   $0x1b
  102194:	e9 3f 9f 00 00       	jmp    10c0d8 <_alltraps>
  102199:	90                   	nop

0010219a <vector28>:
TRAPHANDLER_NOEC(vector28, 28)
  10219a:	6a 00                	push   $0x0
  10219c:	6a 1c                	push   $0x1c
  10219e:	e9 35 9f 00 00       	jmp    10c0d8 <_alltraps>
  1021a3:	90                   	nop

001021a4 <vector29>:
TRAPHANDLER_NOEC(vector29, 29)
  1021a4:	6a 00                	push   $0x0
  1021a6:	6a 1d                	push   $0x1d
  1021a8:	e9 2b 9f 00 00       	jmp    10c0d8 <_alltraps>
  1021ad:	90                   	nop

001021ae <vector30>:
TRAPHANDLER_NOEC(vector30, 30)
  1021ae:	6a 00                	push   $0x0
  1021b0:	6a 1e                	push   $0x1e
  1021b2:	e9 21 9f 00 00       	jmp    10c0d8 <_alltraps>
  1021b7:	90                   	nop

001021b8 <vector31>:
TRAPHANDLER_NOEC(vector31, 31)
  1021b8:	6a 00                	push   $0x0
  1021ba:	6a 1f                	push   $0x1f
  1021bc:	e9 17 9f 00 00       	jmp    10c0d8 <_alltraps>
  1021c1:	90                   	nop

001021c2 <vector32>:
TRAPHANDLER_NOEC(vector32, 32)
  1021c2:	6a 00                	push   $0x0
  1021c4:	6a 20                	push   $0x20
  1021c6:	e9 0d 9f 00 00       	jmp    10c0d8 <_alltraps>
  1021cb:	90                   	nop

001021cc <vector33>:
TRAPHANDLER_NOEC(vector33, 33)
  1021cc:	6a 00                	push   $0x0
  1021ce:	6a 21                	push   $0x21
  1021d0:	e9 03 9f 00 00       	jmp    10c0d8 <_alltraps>
  1021d5:	90                   	nop

001021d6 <vector34>:
TRAPHANDLER_NOEC(vector34, 34)
  1021d6:	6a 00                	push   $0x0
  1021d8:	6a 22                	push   $0x22
  1021da:	e9 f9 9e 00 00       	jmp    10c0d8 <_alltraps>
  1021df:	90                   	nop

001021e0 <vector35>:
TRAPHANDLER_NOEC(vector35, 35)
  1021e0:	6a 00                	push   $0x0
  1021e2:	6a 23                	push   $0x23
  1021e4:	e9 ef 9e 00 00       	jmp    10c0d8 <_alltraps>
  1021e9:	90                   	nop

001021ea <vector36>:
TRAPHANDLER_NOEC(vector36, 36)
  1021ea:	6a 00                	push   $0x0
  1021ec:	6a 24                	push   $0x24
  1021ee:	e9 e5 9e 00 00       	jmp    10c0d8 <_alltraps>
  1021f3:	90                   	nop

001021f4 <vector37>:
TRAPHANDLER_NOEC(vector37, 37)
  1021f4:	6a 00                	push   $0x0
  1021f6:	6a 25                	push   $0x25
  1021f8:	e9 db 9e 00 00       	jmp    10c0d8 <_alltraps>
  1021fd:	90                   	nop

001021fe <vector38>:
TRAPHANDLER_NOEC(vector38, 38)
  1021fe:	6a 00                	push   $0x0
  102200:	6a 26                	push   $0x26
  102202:	e9 d1 9e 00 00       	jmp    10c0d8 <_alltraps>
  102207:	90                   	nop

00102208 <vector39>:
TRAPHANDLER_NOEC(vector39, 39)
  102208:	6a 00                	push   $0x0
  10220a:	6a 27                	push   $0x27
  10220c:	e9 c7 9e 00 00       	jmp    10c0d8 <_alltraps>
  102211:	90                   	nop

00102212 <vector40>:
TRAPHANDLER_NOEC(vector40, 40)
  102212:	6a 00                	push   $0x0
  102214:	6a 28                	push   $0x28
  102216:	e9 bd 9e 00 00       	jmp    10c0d8 <_alltraps>
  10221b:	90                   	nop

0010221c <vector41>:
TRAPHANDLER_NOEC(vector41, 41)
  10221c:	6a 00                	push   $0x0
  10221e:	6a 29                	push   $0x29
  102220:	e9 b3 9e 00 00       	jmp    10c0d8 <_alltraps>
  102225:	90                   	nop

00102226 <vector42>:
TRAPHANDLER_NOEC(vector42, 42)
  102226:	6a 00                	push   $0x0
  102228:	6a 2a                	push   $0x2a
  10222a:	e9 a9 9e 00 00       	jmp    10c0d8 <_alltraps>
  10222f:	90                   	nop

00102230 <vector43>:
TRAPHANDLER_NOEC(vector43, 43)
  102230:	6a 00                	push   $0x0
  102232:	6a 2b                	push   $0x2b
  102234:	e9 9f 9e 00 00       	jmp    10c0d8 <_alltraps>
  102239:	90                   	nop

0010223a <vector44>:
TRAPHANDLER_NOEC(vector44, 44)
  10223a:	6a 00                	push   $0x0
  10223c:	6a 2c                	push   $0x2c
  10223e:	e9 95 9e 00 00       	jmp    10c0d8 <_alltraps>
  102243:	90                   	nop

00102244 <vector45>:
TRAPHANDLER_NOEC(vector45, 45)
  102244:	6a 00                	push   $0x0
  102246:	6a 2d                	push   $0x2d
  102248:	e9 8b 9e 00 00       	jmp    10c0d8 <_alltraps>
  10224d:	90                   	nop

0010224e <vector46>:
TRAPHANDLER_NOEC(vector46, 46)
  10224e:	6a 00                	push   $0x0
  102250:	6a 2e                	push   $0x2e
  102252:	e9 81 9e 00 00       	jmp    10c0d8 <_alltraps>
  102257:	90                   	nop

00102258 <vector47>:
TRAPHANDLER_NOEC(vector47, 47)
  102258:	6a 00                	push   $0x0
  10225a:	6a 2f                	push   $0x2f
  10225c:	e9 77 9e 00 00       	jmp    10c0d8 <_alltraps>
  102261:	90                   	nop

00102262 <vector48>:
TRAPHANDLER_NOEC(vector48, 48)
  102262:	6a 00                	push   $0x0
  102264:	6a 30                	push   $0x30
  102266:	e9 6d 9e 00 00       	jmp    10c0d8 <_alltraps>
  10226b:	90                   	nop

0010226c <vector49>:
TRAPHANDLER_NOEC(vector49, 49)
  10226c:	6a 00                	push   $0x0
  10226e:	6a 31                	push   $0x31
  102270:	e9 63 9e 00 00       	jmp    10c0d8 <_alltraps>

00102275 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102275:	55                   	push   %ebp
  102276:	89 e5                	mov    %esp,%ebp
  102278:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10227b:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10227e:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102281:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102284:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102287:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10228c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10228f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102292:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102298:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10229d:	74 24                	je     1022c3 <cpu_cur+0x4e>
  10229f:	c7 44 24 0c 90 90 10 	movl   $0x109090,0xc(%esp)
  1022a6:	00 
  1022a7:	c7 44 24 08 a6 90 10 	movl   $0x1090a6,0x8(%esp)
  1022ae:	00 
  1022af:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1022b6:	00 
  1022b7:	c7 04 24 bb 90 10 00 	movl   $0x1090bb,(%esp)
  1022be:	e8 6b e5 ff ff       	call   10082e <debug_panic>
	return c;
  1022c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1022c6:	c9                   	leave  
  1022c7:	c3                   	ret    

001022c8 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1022c8:	55                   	push   %ebp
  1022c9:	89 e5                	mov    %esp,%ebp
  1022cb:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1022ce:	e8 a2 ff ff ff       	call   102275 <cpu_cur>
  1022d3:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  1022d8:	0f 94 c0             	sete   %al
  1022db:	0f b6 c0             	movzbl %al,%eax
}
  1022de:	c9                   	leave  
  1022df:	c3                   	ret    

001022e0 <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  1022e0:	55                   	push   %ebp
  1022e1:	89 e5                	mov    %esp,%ebp
  1022e3:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  1022e6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	for (i = 0; i < len; i++)
  1022ed:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  1022f4:	eb 13                	jmp    102309 <sum+0x29>
		sum += addr[i];
  1022f6:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1022f9:	03 45 08             	add    0x8(%ebp),%eax
  1022fc:	0f b6 00             	movzbl (%eax),%eax
  1022ff:	0f b6 c0             	movzbl %al,%eax
  102302:	01 45 fc             	add    %eax,-0x4(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  102305:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  102309:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10230c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10230f:	7c e5                	jl     1022f6 <sum+0x16>
		sum += addr[i];
	return sum;
  102311:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102314:	c9                   	leave  
  102315:	c3                   	ret    

00102316 <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  102316:	55                   	push   %ebp
  102317:	89 e5                	mov    %esp,%ebp
  102319:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  10231c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10231f:	03 45 08             	add    0x8(%ebp),%eax
  102322:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  102325:	8b 45 08             	mov    0x8(%ebp),%eax
  102328:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10232b:	eb 3f                	jmp    10236c <mpsearch1+0x56>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  10232d:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  102334:	00 
  102335:	c7 44 24 04 c8 90 10 	movl   $0x1090c8,0x4(%esp)
  10233c:	00 
  10233d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102340:	89 04 24             	mov    %eax,(%esp)
  102343:	e8 9e 5f 00 00       	call   1082e6 <memcmp>
  102348:	85 c0                	test   %eax,%eax
  10234a:	75 1c                	jne    102368 <mpsearch1+0x52>
  10234c:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  102353:	00 
  102354:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102357:	89 04 24             	mov    %eax,(%esp)
  10235a:	e8 81 ff ff ff       	call   1022e0 <sum>
  10235f:	84 c0                	test   %al,%al
  102361:	75 05                	jne    102368 <mpsearch1+0x52>
			return (struct mp *) p;
  102363:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102366:	eb 11                	jmp    102379 <mpsearch1+0x63>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  102368:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  10236c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10236f:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102372:	72 b9                	jb     10232d <mpsearch1+0x17>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  102374:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102379:	c9                   	leave  
  10237a:	c3                   	ret    

0010237b <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  10237b:	55                   	push   %ebp
  10237c:	89 e5                	mov    %esp,%ebp
  10237e:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  102381:	c7 45 ec 00 04 00 00 	movl   $0x400,-0x14(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  102388:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10238b:	83 c0 0f             	add    $0xf,%eax
  10238e:	0f b6 00             	movzbl (%eax),%eax
  102391:	0f b6 c0             	movzbl %al,%eax
  102394:	89 c2                	mov    %eax,%edx
  102396:	c1 e2 08             	shl    $0x8,%edx
  102399:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10239c:	83 c0 0e             	add    $0xe,%eax
  10239f:	0f b6 00             	movzbl (%eax),%eax
  1023a2:	0f b6 c0             	movzbl %al,%eax
  1023a5:	09 d0                	or     %edx,%eax
  1023a7:	c1 e0 04             	shl    $0x4,%eax
  1023aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1023ad:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1023b1:	74 21                	je     1023d4 <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  1023b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1023b6:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  1023bd:	00 
  1023be:	89 04 24             	mov    %eax,(%esp)
  1023c1:	e8 50 ff ff ff       	call   102316 <mpsearch1>
  1023c6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1023c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1023cd:	74 50                	je     10241f <mpsearch+0xa4>
			return mp;
  1023cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1023d2:	eb 5f                	jmp    102433 <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  1023d4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1023d7:	83 c0 14             	add    $0x14,%eax
  1023da:	0f b6 00             	movzbl (%eax),%eax
  1023dd:	0f b6 c0             	movzbl %al,%eax
  1023e0:	89 c2                	mov    %eax,%edx
  1023e2:	c1 e2 08             	shl    $0x8,%edx
  1023e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1023e8:	83 c0 13             	add    $0x13,%eax
  1023eb:	0f b6 00             	movzbl (%eax),%eax
  1023ee:	0f b6 c0             	movzbl %al,%eax
  1023f1:	09 d0                	or     %edx,%eax
  1023f3:	c1 e0 0a             	shl    $0xa,%eax
  1023f6:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  1023f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1023fc:	2d 00 04 00 00       	sub    $0x400,%eax
  102401:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  102408:	00 
  102409:	89 04 24             	mov    %eax,(%esp)
  10240c:	e8 05 ff ff ff       	call   102316 <mpsearch1>
  102411:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102414:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102418:	74 05                	je     10241f <mpsearch+0xa4>
			return mp;
  10241a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10241d:	eb 14                	jmp    102433 <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  10241f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  102426:	00 
  102427:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  10242e:	e8 e3 fe ff ff       	call   102316 <mpsearch1>
}
  102433:	c9                   	leave  
  102434:	c3                   	ret    

00102435 <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  102435:	55                   	push   %ebp
  102436:	89 e5                	mov    %esp,%ebp
  102438:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  10243b:	e8 3b ff ff ff       	call   10237b <mpsearch>
  102440:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102443:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102447:	74 0a                	je     102453 <mpconfig+0x1e>
  102449:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10244c:	8b 40 04             	mov    0x4(%eax),%eax
  10244f:	85 c0                	test   %eax,%eax
  102451:	75 07                	jne    10245a <mpconfig+0x25>
		return 0;
  102453:	b8 00 00 00 00       	mov    $0x0,%eax
  102458:	eb 7b                	jmp    1024d5 <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  10245a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10245d:	8b 40 04             	mov    0x4(%eax),%eax
  102460:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  102463:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  10246a:	00 
  10246b:	c7 44 24 04 cd 90 10 	movl   $0x1090cd,0x4(%esp)
  102472:	00 
  102473:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102476:	89 04 24             	mov    %eax,(%esp)
  102479:	e8 68 5e 00 00       	call   1082e6 <memcmp>
  10247e:	85 c0                	test   %eax,%eax
  102480:	74 07                	je     102489 <mpconfig+0x54>
		return 0;
  102482:	b8 00 00 00 00       	mov    $0x0,%eax
  102487:	eb 4c                	jmp    1024d5 <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  102489:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10248c:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102490:	3c 01                	cmp    $0x1,%al
  102492:	74 12                	je     1024a6 <mpconfig+0x71>
  102494:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102497:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  10249b:	3c 04                	cmp    $0x4,%al
  10249d:	74 07                	je     1024a6 <mpconfig+0x71>
		return 0;
  10249f:	b8 00 00 00 00       	mov    $0x0,%eax
  1024a4:	eb 2f                	jmp    1024d5 <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  1024a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1024a9:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  1024ad:	0f b7 d0             	movzwl %ax,%edx
  1024b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1024b3:	89 54 24 04          	mov    %edx,0x4(%esp)
  1024b7:	89 04 24             	mov    %eax,(%esp)
  1024ba:	e8 21 fe ff ff       	call   1022e0 <sum>
  1024bf:	84 c0                	test   %al,%al
  1024c1:	74 07                	je     1024ca <mpconfig+0x95>
		return 0;
  1024c3:	b8 00 00 00 00       	mov    $0x0,%eax
  1024c8:	eb 0b                	jmp    1024d5 <mpconfig+0xa0>
       *pmp = mp;
  1024ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1024cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1024d0:	89 10                	mov    %edx,(%eax)
	return conf;
  1024d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1024d5:	c9                   	leave  
  1024d6:	c3                   	ret    

001024d7 <mp_init>:

void
mp_init(void)
{
  1024d7:	55                   	push   %ebp
  1024d8:	89 e5                	mov    %esp,%ebp
  1024da:	83 ec 48             	sub    $0x48,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  1024dd:	e8 e6 fd ff ff       	call   1022c8 <cpu_onboot>
  1024e2:	85 c0                	test   %eax,%eax
  1024e4:	0f 84 72 01 00 00    	je     10265c <mp_init+0x185>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  1024ea:	8d 45 c8             	lea    -0x38(%ebp),%eax
  1024ed:	89 04 24             	mov    %eax,(%esp)
  1024f0:	e8 40 ff ff ff       	call   102435 <mpconfig>
  1024f5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  1024f8:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  1024fc:	0f 84 5d 01 00 00    	je     10265f <mp_init+0x188>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  102502:	c7 05 64 ed 31 00 01 	movl   $0x1,0x31ed64
  102509:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  10250c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10250f:	8b 40 24             	mov    0x24(%eax),%eax
  102512:	a3 04 20 32 00       	mov    %eax,0x322004
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  102517:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10251a:	83 c0 2c             	add    $0x2c,%eax
  10251d:	89 45 cc             	mov    %eax,-0x34(%ebp)
  102520:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102523:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102526:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  10252a:	0f b7 c0             	movzwl %ax,%eax
  10252d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102530:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102533:	e9 cc 00 00 00       	jmp    102604 <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  102538:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10253b:	0f b6 00             	movzbl (%eax),%eax
  10253e:	0f b6 c0             	movzbl %al,%eax
  102541:	83 f8 04             	cmp    $0x4,%eax
  102544:	0f 87 90 00 00 00    	ja     1025da <mp_init+0x103>
  10254a:	8b 04 85 00 91 10 00 	mov    0x109100(,%eax,4),%eax
  102551:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  102553:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102556:	89 45 d8             	mov    %eax,-0x28(%ebp)
			p += sizeof(struct mpproc);
  102559:	83 45 cc 14          	addl   $0x14,-0x34(%ebp)
			if (!(proc->flags & MPENAB))
  10255d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102560:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102564:	0f b6 c0             	movzbl %al,%eax
  102567:	83 e0 01             	and    $0x1,%eax
  10256a:	85 c0                	test   %eax,%eax
  10256c:	0f 84 91 00 00 00    	je     102603 <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  102572:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102575:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102579:	0f b6 c0             	movzbl %al,%eax
  10257c:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  10257f:	85 c0                	test   %eax,%eax
  102581:	75 07                	jne    10258a <mp_init+0xb3>
  102583:	e8 4a f0 ff ff       	call   1015d2 <cpu_alloc>
  102588:	eb 05                	jmp    10258f <mp_init+0xb8>
  10258a:	b8 00 b0 10 00       	mov    $0x10b000,%eax
  10258f:	89 45 e0             	mov    %eax,-0x20(%ebp)
			c->id = proc->apicid;
  102592:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102595:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  102599:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10259c:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  1025a2:	a1 68 ed 31 00       	mov    0x31ed68,%eax
  1025a7:	83 c0 01             	add    $0x1,%eax
  1025aa:	a3 68 ed 31 00       	mov    %eax,0x31ed68
			continue;
  1025af:	eb 53                	jmp    102604 <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  1025b1:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1025b4:	89 45 dc             	mov    %eax,-0x24(%ebp)
			p += sizeof(struct mpioapic);
  1025b7:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			ioapicid = mpio->apicno;
  1025bb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1025be:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  1025c2:	a2 5c ed 31 00       	mov    %al,0x31ed5c
			ioapic = (struct ioapic *) mpio->addr;
  1025c7:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1025ca:	8b 40 04             	mov    0x4(%eax),%eax
  1025cd:	a3 60 ed 31 00       	mov    %eax,0x31ed60
			continue;
  1025d2:	eb 30                	jmp    102604 <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  1025d4:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			continue;
  1025d8:	eb 2a                	jmp    102604 <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  1025da:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1025dd:	0f b6 00             	movzbl (%eax),%eax
  1025e0:	0f b6 c0             	movzbl %al,%eax
  1025e3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1025e7:	c7 44 24 08 d4 90 10 	movl   $0x1090d4,0x8(%esp)
  1025ee:	00 
  1025ef:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  1025f6:	00 
  1025f7:	c7 04 24 f4 90 10 00 	movl   $0x1090f4,(%esp)
  1025fe:	e8 2b e2 ff ff       	call   10082e <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  102603:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  102604:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102607:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10260a:	0f 82 28 ff ff ff    	jb     102538 <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  102610:	8b 45 c8             	mov    -0x38(%ebp),%eax
  102613:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  102617:	84 c0                	test   %al,%al
  102619:	74 45                	je     102660 <mp_init+0x189>
  10261b:	c7 45 e8 22 00 00 00 	movl   $0x22,-0x18(%ebp)
  102622:	c6 45 e7 70          	movb   $0x70,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102626:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  10262a:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10262d:	ee                   	out    %al,(%dx)
  10262e:	c7 45 ec 23 00 00 00 	movl   $0x23,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102635:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102638:	89 c2                	mov    %eax,%edx
  10263a:	ec                   	in     (%dx),%al
  10263b:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10263e:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  102642:	83 c8 01             	or     $0x1,%eax
  102645:	0f b6 c0             	movzbl %al,%eax
  102648:	c7 45 f4 23 00 00 00 	movl   $0x23,-0xc(%ebp)
  10264f:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102652:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  102656:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102659:	ee                   	out    %al,(%dx)
  10265a:	eb 04                	jmp    102660 <mp_init+0x189>
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  10265c:	90                   	nop
  10265d:	eb 01                	jmp    102660 <mp_init+0x189>

	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.
  10265f:	90                   	nop
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
	}
}
  102660:	c9                   	leave  
  102661:	c3                   	ret    

00102662 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  102662:	55                   	push   %ebp
  102663:	89 e5                	mov    %esp,%ebp
  102665:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102668:	8b 55 08             	mov    0x8(%ebp),%edx
  10266b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10266e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102671:	f0 87 02             	lock xchg %eax,(%edx)
  102674:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102677:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  10267a:	c9                   	leave  
  10267b:	c3                   	ret    

0010267c <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10267c:	55                   	push   %ebp
  10267d:	89 e5                	mov    %esp,%ebp
  10267f:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102682:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  102685:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102688:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10268b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10268e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102693:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  102696:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102699:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10269f:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1026a4:	74 24                	je     1026ca <cpu_cur+0x4e>
  1026a6:	c7 44 24 0c 14 91 10 	movl   $0x109114,0xc(%esp)
  1026ad:	00 
  1026ae:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  1026b5:	00 
  1026b6:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1026bd:	00 
  1026be:	c7 04 24 3f 91 10 00 	movl   $0x10913f,(%esp)
  1026c5:	e8 64 e1 ff ff       	call   10082e <debug_panic>
	return c;
  1026ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1026cd:	c9                   	leave  
  1026ce:	c3                   	ret    

001026cf <spinlock_init_>:
#include <kern/cons.h>


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  1026cf:	55                   	push   %ebp
  1026d0:	89 e5                	mov    %esp,%ebp
	lk->locked = 0;
  1026d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1026d5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	lk->file = file;
  1026db:	8b 45 08             	mov    0x8(%ebp),%eax
  1026de:	8b 55 0c             	mov    0xc(%ebp),%edx
  1026e1:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  1026e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1026e7:	8b 55 10             	mov    0x10(%ebp),%edx
  1026ea:	89 50 08             	mov    %edx,0x8(%eax)
	lk->cpu = NULL;
  1026ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1026f0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	lk->eips[0] = 0;
  1026f7:	8b 45 08             	mov    0x8(%ebp),%eax
  1026fa:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
}
  102701:	5d                   	pop    %ebp
  102702:	c3                   	ret    

00102703 <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  102703:	55                   	push   %ebp
  102704:	89 e5                	mov    %esp,%ebp
  102706:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in sa\n");

	if(spinlock_holding(lk)){
  102709:	8b 45 08             	mov    0x8(%ebp),%eax
  10270c:	89 04 24             	mov    %eax,(%esp)
  10270f:	e8 b6 00 00 00       	call   1027ca <spinlock_holding>
  102714:	85 c0                	test   %eax,%eax
  102716:	74 1c                	je     102734 <spinlock_acquire+0x31>
		//cprintf("acquire\n");
		//cprintf("file = %s, line = %d, cpu = %d\n", lk->file, lk->line, lk->cpu->id);
		panic("acquire");
  102718:	c7 44 24 08 4c 91 10 	movl   $0x10914c,0x8(%esp)
  10271f:	00 
  102720:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
  102727:	00 
  102728:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  10272f:	e8 fa e0 ff ff       	call   10082e <debug_panic>
	}

	while(xchg(&lk->locked, 1) !=0)
  102734:	8b 45 08             	mov    0x8(%ebp),%eax
  102737:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10273e:	00 
  10273f:	89 04 24             	mov    %eax,(%esp)
  102742:	e8 1b ff ff ff       	call   102662 <xchg>
  102747:	85 c0                	test   %eax,%eax
  102749:	75 e9                	jne    102734 <spinlock_acquire+0x31>
		{//cprintf("in xchg\n")
		;}

	lk->cpu = cpu_cur();
  10274b:	e8 2c ff ff ff       	call   10267c <cpu_cur>
  102750:	8b 55 08             	mov    0x8(%ebp),%edx
  102753:	89 42 0c             	mov    %eax,0xc(%edx)

	//cprintf("before dt\n");
	debug_trace(read_ebp(), lk->eips);
  102756:	8b 45 08             	mov    0x8(%ebp),%eax
  102759:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10275c:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  10275f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102762:	89 54 24 04          	mov    %edx,0x4(%esp)
  102766:	89 04 24             	mov    %eax,(%esp)
  102769:	e8 c8 e1 ff ff       	call   100936 <debug_trace>
	//cprintf("after dt\n");

	//cprintf("after sa\n");

	//cprintf("acquire lock num: %d on cpu: %d\n", lk->number, lk->cpu->id);
}
  10276e:	c9                   	leave  
  10276f:	c3                   	ret    

00102770 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  102770:	55                   	push   %ebp
  102771:	89 e5                	mov    %esp,%ebp
  102773:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk))
  102776:	8b 45 08             	mov    0x8(%ebp),%eax
  102779:	89 04 24             	mov    %eax,(%esp)
  10277c:	e8 49 00 00 00       	call   1027ca <spinlock_holding>
  102781:	85 c0                	test   %eax,%eax
  102783:	75 1c                	jne    1027a1 <spinlock_release+0x31>
		panic("release");
  102785:	c7 44 24 08 64 91 10 	movl   $0x109164,0x8(%esp)
  10278c:	00 
  10278d:	c7 44 24 04 40 00 00 	movl   $0x40,0x4(%esp)
  102794:	00 
  102795:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  10279c:	e8 8d e0 ff ff       	call   10082e <debug_panic>

	lk->cpu = NULL;
  1027a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1027a4:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	xchg(&lk->locked, 0);
  1027ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1027ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1027b5:	00 
  1027b6:	89 04 24             	mov    %eax,(%esp)
  1027b9:	e8 a4 fe ff ff       	call   102662 <xchg>

	lk->eips[0] = 0;
  1027be:	8b 45 08             	mov    0x8(%ebp),%eax
  1027c1:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)

	//cprintf("release lock num: %d on cpu: %d\n", lk->number, lk->cpu->id);
}
  1027c8:	c9                   	leave  
  1027c9:	c3                   	ret    

001027ca <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  1027ca:	55                   	push   %ebp
  1027cb:	89 e5                	mov    %esp,%ebp
  1027cd:	53                   	push   %ebx
  1027ce:	83 ec 04             	sub    $0x4,%esp
	return (lock->cpu == cpu_cur()) && (lock->locked);
  1027d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1027d4:	8b 58 0c             	mov    0xc(%eax),%ebx
  1027d7:	e8 a0 fe ff ff       	call   10267c <cpu_cur>
  1027dc:	39 c3                	cmp    %eax,%ebx
  1027de:	75 10                	jne    1027f0 <spinlock_holding+0x26>
  1027e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1027e3:	8b 00                	mov    (%eax),%eax
  1027e5:	85 c0                	test   %eax,%eax
  1027e7:	74 07                	je     1027f0 <spinlock_holding+0x26>
  1027e9:	b8 01 00 00 00       	mov    $0x1,%eax
  1027ee:	eb 05                	jmp    1027f5 <spinlock_holding+0x2b>
  1027f0:	b8 00 00 00 00       	mov    $0x0,%eax
	//panic("spinlock_holding() not implemented");
}
  1027f5:	83 c4 04             	add    $0x4,%esp
  1027f8:	5b                   	pop    %ebx
  1027f9:	5d                   	pop    %ebp
  1027fa:	c3                   	ret    

001027fb <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  1027fb:	55                   	push   %ebp
  1027fc:	89 e5                	mov    %esp,%ebp
  1027fe:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  102801:	8b 45 08             	mov    0x8(%ebp),%eax
  102804:	85 c0                	test   %eax,%eax
  102806:	75 12                	jne    10281a <spinlock_godeep+0x1f>
  102808:	8b 45 0c             	mov    0xc(%ebp),%eax
  10280b:	89 04 24             	mov    %eax,(%esp)
  10280e:	e8 f0 fe ff ff       	call   102703 <spinlock_acquire>
  102813:	b8 01 00 00 00       	mov    $0x1,%eax
  102818:	eb 1b                	jmp    102835 <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  10281a:	8b 45 08             	mov    0x8(%ebp),%eax
  10281d:	8d 50 ff             	lea    -0x1(%eax),%edx
  102820:	8b 45 0c             	mov    0xc(%ebp),%eax
  102823:	89 44 24 04          	mov    %eax,0x4(%esp)
  102827:	89 14 24             	mov    %edx,(%esp)
  10282a:	e8 cc ff ff ff       	call   1027fb <spinlock_godeep>
  10282f:	8b 55 08             	mov    0x8(%ebp),%edx
  102832:	0f af c2             	imul   %edx,%eax
}
  102835:	c9                   	leave  
  102836:	c3                   	ret    

00102837 <spinlock_check>:



void spinlock_check()
{
  102837:	55                   	push   %ebp
  102838:	89 e5                	mov    %esp,%ebp
  10283a:	57                   	push   %edi
  10283b:	56                   	push   %esi
  10283c:	53                   	push   %ebx
  10283d:	83 ec 5c             	sub    $0x5c,%esp
  102840:	89 e0                	mov    %esp,%eax
  102842:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	const int NUMLOCKS=10;
  102845:	c7 45 d0 0a 00 00 00 	movl   $0xa,-0x30(%ebp)
	const int NUMRUNS=5;
  10284c:	c7 45 d4 05 00 00 00 	movl   $0x5,-0x2c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  102853:	c7 45 e4 6c 91 10 00 	movl   $0x10916c,-0x1c(%ebp)
	spinlock locks[NUMLOCKS];
  10285a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10285d:	83 e8 01             	sub    $0x1,%eax
  102860:	89 45 c8             	mov    %eax,-0x38(%ebp)
  102863:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102866:	ba 00 00 00 00       	mov    $0x0,%edx
  10286b:	89 c1                	mov    %eax,%ecx
  10286d:	80 e5 ff             	and    $0xff,%ch
  102870:	89 d3                	mov    %edx,%ebx
  102872:	83 e3 0f             	and    $0xf,%ebx
  102875:	89 c8                	mov    %ecx,%eax
  102877:	89 da                	mov    %ebx,%edx
  102879:	69 da c0 01 00 00    	imul   $0x1c0,%edx,%ebx
  10287f:	6b c8 00             	imul   $0x0,%eax,%ecx
  102882:	01 cb                	add    %ecx,%ebx
  102884:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102889:	f7 e1                	mul    %ecx
  10288b:	01 d3                	add    %edx,%ebx
  10288d:	89 da                	mov    %ebx,%edx
  10288f:	89 c6                	mov    %eax,%esi
  102891:	83 e6 ff             	and    $0xffffffff,%esi
  102894:	89 d7                	mov    %edx,%edi
  102896:	83 e7 0f             	and    $0xf,%edi
  102899:	89 f0                	mov    %esi,%eax
  10289b:	89 fa                	mov    %edi,%edx
  10289d:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1028a0:	c1 e0 03             	shl    $0x3,%eax
  1028a3:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1028a6:	ba 00 00 00 00       	mov    $0x0,%edx
  1028ab:	89 c1                	mov    %eax,%ecx
  1028ad:	80 e5 ff             	and    $0xff,%ch
  1028b0:	89 4d b8             	mov    %ecx,-0x48(%ebp)
  1028b3:	89 d3                	mov    %edx,%ebx
  1028b5:	83 e3 0f             	and    $0xf,%ebx
  1028b8:	89 5d bc             	mov    %ebx,-0x44(%ebp)
  1028bb:	8b 45 b8             	mov    -0x48(%ebp),%eax
  1028be:	8b 55 bc             	mov    -0x44(%ebp),%edx
  1028c1:	69 ca c0 01 00 00    	imul   $0x1c0,%edx,%ecx
  1028c7:	6b d8 00             	imul   $0x0,%eax,%ebx
  1028ca:	01 d9                	add    %ebx,%ecx
  1028cc:	bb c0 01 00 00       	mov    $0x1c0,%ebx
  1028d1:	f7 e3                	mul    %ebx
  1028d3:	01 d1                	add    %edx,%ecx
  1028d5:	89 ca                	mov    %ecx,%edx
  1028d7:	89 c1                	mov    %eax,%ecx
  1028d9:	80 e5 ff             	and    $0xff,%ch
  1028dc:	89 4d b0             	mov    %ecx,-0x50(%ebp)
  1028df:	89 d3                	mov    %edx,%ebx
  1028e1:	83 e3 0f             	and    $0xf,%ebx
  1028e4:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
  1028e7:	8b 45 b0             	mov    -0x50(%ebp),%eax
  1028ea:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  1028ed:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1028f0:	c1 e0 03             	shl    $0x3,%eax
  1028f3:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1028fa:	89 d1                	mov    %edx,%ecx
  1028fc:	29 c1                	sub    %eax,%ecx
  1028fe:	89 c8                	mov    %ecx,%eax
  102900:	83 c0 0f             	add    $0xf,%eax
  102903:	83 c0 0f             	add    $0xf,%eax
  102906:	c1 e8 04             	shr    $0x4,%eax
  102909:	c1 e0 04             	shl    $0x4,%eax
  10290c:	29 c4                	sub    %eax,%esp
  10290e:	8d 44 24 10          	lea    0x10(%esp),%eax
  102912:	83 c0 0f             	add    $0xf,%eax
  102915:	c1 e8 04             	shr    $0x4,%eax
  102918:	c1 e0 04             	shl    $0x4,%eax
  10291b:	89 45 cc             	mov    %eax,-0x34(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  10291e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102925:	eb 33                	jmp    10295a <spinlock_check+0x123>
  102927:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10292a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10292d:	c1 e0 03             	shl    $0x3,%eax
  102930:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102937:	89 cb                	mov    %ecx,%ebx
  102939:	29 c3                	sub    %eax,%ebx
  10293b:	89 d8                	mov    %ebx,%eax
  10293d:	01 c2                	add    %eax,%edx
  10293f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102946:	00 
  102947:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10294a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10294e:	89 14 24             	mov    %edx,(%esp)
  102951:	e8 79 fd ff ff       	call   1026cf <spinlock_init_>
  102956:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10295a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10295d:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102960:	7c c5                	jl     102927 <spinlock_check+0xf0>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  102962:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102969:	eb 46                	jmp    1029b1 <spinlock_check+0x17a>
  10296b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10296e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102971:	c1 e0 03             	shl    $0x3,%eax
  102974:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10297b:	29 c2                	sub    %eax,%edx
  10297d:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  102980:	83 c0 0c             	add    $0xc,%eax
  102983:	8b 00                	mov    (%eax),%eax
  102985:	85 c0                	test   %eax,%eax
  102987:	74 24                	je     1029ad <spinlock_check+0x176>
  102989:	c7 44 24 0c 7b 91 10 	movl   $0x10917b,0xc(%esp)
  102990:	00 
  102991:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  102998:	00 
  102999:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1029a0:	00 
  1029a1:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  1029a8:	e8 81 de ff ff       	call   10082e <debug_panic>
  1029ad:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1029b1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1029b4:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1029b7:	7c b2                	jl     10296b <spinlock_check+0x134>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  1029b9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1029c0:	eb 47                	jmp    102a09 <spinlock_check+0x1d2>
  1029c2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1029c5:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1029c8:	c1 e0 03             	shl    $0x3,%eax
  1029cb:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1029d2:	29 c2                	sub    %eax,%edx
  1029d4:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1029d7:	83 c0 04             	add    $0x4,%eax
  1029da:	8b 00                	mov    (%eax),%eax
  1029dc:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  1029df:	74 24                	je     102a05 <spinlock_check+0x1ce>
  1029e1:	c7 44 24 0c 8e 91 10 	movl   $0x10918e,0xc(%esp)
  1029e8:	00 
  1029e9:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  1029f0:	00 
  1029f1:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  1029f8:	00 
  1029f9:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  102a00:	e8 29 de ff ff       	call   10082e <debug_panic>
  102a05:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102a09:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102a0c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102a0f:	7c b1                	jl     1029c2 <spinlock_check+0x18b>

	for (run=0;run<NUMRUNS;run++) 
  102a11:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  102a18:	e9 25 03 00 00       	jmp    102d42 <spinlock_check+0x50b>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  102a1d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102a24:	eb 3f                	jmp    102a65 <spinlock_check+0x22e>
		{
			cprintf("%d\n", i);
  102a26:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102a29:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a2d:	c7 04 24 a2 91 10 00 	movl   $0x1091a2,(%esp)
  102a34:	e8 58 55 00 00       	call   107f91 <cprintf>
			spinlock_godeep(i, &locks[i]);
  102a39:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102a3c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102a3f:	c1 e0 03             	shl    $0x3,%eax
  102a42:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102a49:	89 cb                	mov    %ecx,%ebx
  102a4b:	29 c3                	sub    %eax,%ebx
  102a4d:	89 d8                	mov    %ebx,%eax
  102a4f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102a52:	89 44 24 04          	mov    %eax,0x4(%esp)
  102a56:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102a59:	89 04 24             	mov    %eax,(%esp)
  102a5c:	e8 9a fd ff ff       	call   1027fb <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  102a61:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102a65:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102a68:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102a6b:	7c b9                	jl     102a26 <spinlock_check+0x1ef>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  102a6d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102a74:	eb 4b                	jmp    102ac1 <spinlock_check+0x28a>
			assert(locks[i].cpu == cpu_cur());
  102a76:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102a79:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102a7c:	c1 e0 03             	shl    $0x3,%eax
  102a7f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102a86:	29 c2                	sub    %eax,%edx
  102a88:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  102a8b:	83 c0 0c             	add    $0xc,%eax
  102a8e:	8b 18                	mov    (%eax),%ebx
  102a90:	e8 e7 fb ff ff       	call   10267c <cpu_cur>
  102a95:	39 c3                	cmp    %eax,%ebx
  102a97:	74 24                	je     102abd <spinlock_check+0x286>
  102a99:	c7 44 24 0c a6 91 10 	movl   $0x1091a6,0xc(%esp)
  102aa0:	00 
  102aa1:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  102aa8:	00 
  102aa9:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  102ab0:	00 
  102ab1:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  102ab8:	e8 71 dd ff ff       	call   10082e <debug_panic>
			cprintf("%d\n", i);
			spinlock_godeep(i, &locks[i]);
		}

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  102abd:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102ac1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102ac4:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102ac7:	7c ad                	jl     102a76 <spinlock_check+0x23f>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102ac9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102ad0:	eb 4d                	jmp    102b1f <spinlock_check+0x2e8>
			assert(spinlock_holding(&locks[i]) != 0);
  102ad2:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102ad5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102ad8:	c1 e0 03             	shl    $0x3,%eax
  102adb:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102ae2:	89 cb                	mov    %ecx,%ebx
  102ae4:	29 c3                	sub    %eax,%ebx
  102ae6:	89 d8                	mov    %ebx,%eax
  102ae8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102aeb:	89 04 24             	mov    %eax,(%esp)
  102aee:	e8 d7 fc ff ff       	call   1027ca <spinlock_holding>
  102af3:	85 c0                	test   %eax,%eax
  102af5:	75 24                	jne    102b1b <spinlock_check+0x2e4>
  102af7:	c7 44 24 0c c0 91 10 	movl   $0x1091c0,0xc(%esp)
  102afe:	00 
  102aff:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  102b06:	00 
  102b07:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  102b0e:	00 
  102b0f:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  102b16:	e8 13 dd ff ff       	call   10082e <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102b1b:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102b1f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102b22:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102b25:	7c ab                	jl     102ad2 <spinlock_check+0x29b>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  102b27:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102b2e:	e9 bd 00 00 00       	jmp    102bf0 <spinlock_check+0x3b9>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102b33:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  102b3a:	e9 9b 00 00 00       	jmp    102bda <spinlock_check+0x3a3>
			{
				assert(locks[i].eips[j] >=
  102b3f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102b42:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  102b45:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102b48:	01 c0                	add    %eax,%eax
  102b4a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102b51:	29 c2                	sub    %eax,%edx
  102b53:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  102b56:	83 c0 04             	add    $0x4,%eax
  102b59:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  102b5c:	b8 fb 27 10 00       	mov    $0x1027fb,%eax
  102b61:	39 c2                	cmp    %eax,%edx
  102b63:	73 24                	jae    102b89 <spinlock_check+0x352>
  102b65:	c7 44 24 0c e4 91 10 	movl   $0x1091e4,0xc(%esp)
  102b6c:	00 
  102b6d:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  102b74:	00 
  102b75:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  102b7c:	00 
  102b7d:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  102b84:	e8 a5 dc ff ff       	call   10082e <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  102b89:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102b8c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  102b8f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102b92:	01 c0                	add    %eax,%eax
  102b94:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102b9b:	29 c2                	sub    %eax,%edx
  102b9d:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  102ba0:	83 c0 04             	add    $0x4,%eax
  102ba3:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  102ba6:	ba fb 27 10 00       	mov    $0x1027fb,%edx
  102bab:	83 c2 64             	add    $0x64,%edx
  102bae:	39 d0                	cmp    %edx,%eax
  102bb0:	72 24                	jb     102bd6 <spinlock_check+0x39f>
  102bb2:	c7 44 24 0c 14 92 10 	movl   $0x109214,0xc(%esp)
  102bb9:	00 
  102bba:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  102bc1:	00 
  102bc2:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
  102bc9:	00 
  102bca:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  102bd1:	e8 58 dc ff ff       	call   10082e <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102bd6:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  102bda:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102bdd:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  102be0:	7f 0a                	jg     102bec <spinlock_check+0x3b5>
  102be2:	83 7d dc 09          	cmpl   $0x9,-0x24(%ebp)
  102be6:	0f 8e 53 ff ff ff    	jle    102b3f <spinlock_check+0x308>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  102bec:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102bf0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102bf3:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102bf6:	0f 8c 37 ff ff ff    	jl     102b33 <spinlock_check+0x2fc>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  102bfc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102c03:	eb 25                	jmp    102c2a <spinlock_check+0x3f3>
  102c05:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102c08:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102c0b:	c1 e0 03             	shl    $0x3,%eax
  102c0e:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102c15:	89 cb                	mov    %ecx,%ebx
  102c17:	29 c3                	sub    %eax,%ebx
  102c19:	89 d8                	mov    %ebx,%eax
  102c1b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102c1e:	89 04 24             	mov    %eax,(%esp)
  102c21:	e8 4a fb ff ff       	call   102770 <spinlock_release>
  102c26:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102c2a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102c2d:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102c30:	7c d3                	jl     102c05 <spinlock_check+0x3ce>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  102c32:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102c39:	eb 46                	jmp    102c81 <spinlock_check+0x44a>
  102c3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102c3e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102c41:	c1 e0 03             	shl    $0x3,%eax
  102c44:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102c4b:	29 c2                	sub    %eax,%edx
  102c4d:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  102c50:	83 c0 0c             	add    $0xc,%eax
  102c53:	8b 00                	mov    (%eax),%eax
  102c55:	85 c0                	test   %eax,%eax
  102c57:	74 24                	je     102c7d <spinlock_check+0x446>
  102c59:	c7 44 24 0c 45 92 10 	movl   $0x109245,0xc(%esp)
  102c60:	00 
  102c61:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  102c68:	00 
  102c69:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  102c70:	00 
  102c71:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  102c78:	e8 b1 db ff ff       	call   10082e <debug_panic>
  102c7d:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102c81:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102c84:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102c87:	7c b2                	jl     102c3b <spinlock_check+0x404>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  102c89:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102c90:	eb 46                	jmp    102cd8 <spinlock_check+0x4a1>
  102c92:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102c95:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  102c98:	c1 e0 03             	shl    $0x3,%eax
  102c9b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102ca2:	29 c2                	sub    %eax,%edx
  102ca4:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  102ca7:	83 c0 10             	add    $0x10,%eax
  102caa:	8b 00                	mov    (%eax),%eax
  102cac:	85 c0                	test   %eax,%eax
  102cae:	74 24                	je     102cd4 <spinlock_check+0x49d>
  102cb0:	c7 44 24 0c 5a 92 10 	movl   $0x10925a,0xc(%esp)
  102cb7:	00 
  102cb8:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  102cbf:	00 
  102cc0:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  102cc7:	00 
  102cc8:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  102ccf:	e8 5a db ff ff       	call   10082e <debug_panic>
  102cd4:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102cd8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102cdb:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102cde:	7c b2                	jl     102c92 <spinlock_check+0x45b>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  102ce0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102ce7:	eb 4d                	jmp    102d36 <spinlock_check+0x4ff>
  102ce9:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102cec:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102cef:	c1 e0 03             	shl    $0x3,%eax
  102cf2:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102cf9:	89 cb                	mov    %ecx,%ebx
  102cfb:	29 c3                	sub    %eax,%ebx
  102cfd:	89 d8                	mov    %ebx,%eax
  102cff:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102d02:	89 04 24             	mov    %eax,(%esp)
  102d05:	e8 c0 fa ff ff       	call   1027ca <spinlock_holding>
  102d0a:	85 c0                	test   %eax,%eax
  102d0c:	74 24                	je     102d32 <spinlock_check+0x4fb>
  102d0e:	c7 44 24 0c 70 92 10 	movl   $0x109270,0xc(%esp)
  102d15:	00 
  102d16:	c7 44 24 08 2a 91 10 	movl   $0x10912a,0x8(%esp)
  102d1d:	00 
  102d1e:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  102d25:	00 
  102d26:	c7 04 24 54 91 10 00 	movl   $0x109154,(%esp)
  102d2d:	e8 fc da ff ff       	call   10082e <debug_panic>
  102d32:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102d36:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102d39:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102d3c:	7c ab                	jl     102ce9 <spinlock_check+0x4b2>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  102d3e:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  102d42:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102d45:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  102d48:	0f 8c cf fc ff ff    	jl     102a1d <spinlock_check+0x1e6>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  102d4e:	c7 04 24 91 92 10 00 	movl   $0x109291,(%esp)
  102d55:	e8 37 52 00 00       	call   107f91 <cprintf>
  102d5a:	8b 65 c4             	mov    -0x3c(%ebp),%esp
}
  102d5d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  102d60:	83 c4 00             	add    $0x0,%esp
  102d63:	5b                   	pop    %ebx
  102d64:	5e                   	pop    %esi
  102d65:	5f                   	pop    %edi
  102d66:	5d                   	pop    %ebp
  102d67:	c3                   	ret    

00102d68 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  102d68:	55                   	push   %ebp
  102d69:	89 e5                	mov    %esp,%ebp
  102d6b:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102d6e:	8b 55 08             	mov    0x8(%ebp),%edx
  102d71:	8b 45 0c             	mov    0xc(%ebp),%eax
  102d74:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102d77:	f0 87 02             	lock xchg %eax,(%edx)
  102d7a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102d7d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102d80:	c9                   	leave  
  102d81:	c3                   	ret    

00102d82 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  102d82:	55                   	push   %ebp
  102d83:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  102d85:	8b 45 08             	mov    0x8(%ebp),%eax
  102d88:	8b 55 0c             	mov    0xc(%ebp),%edx
  102d8b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102d8e:	f0 01 10             	lock add %edx,(%eax)
}
  102d91:	5d                   	pop    %ebp
  102d92:	c3                   	ret    

00102d93 <pause>:
	return result;
}

static inline void
pause(void)
{
  102d93:	55                   	push   %ebp
  102d94:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  102d96:	f3 90                	pause  
}
  102d98:	5d                   	pop    %ebp
  102d99:	c3                   	ret    

00102d9a <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102d9a:	55                   	push   %ebp
  102d9b:	89 e5                	mov    %esp,%ebp
  102d9d:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102da0:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  102da3:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102da6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102da9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102dac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102db1:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  102db4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102db7:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102dbd:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102dc2:	74 24                	je     102de8 <cpu_cur+0x4e>
  102dc4:	c7 44 24 0c b0 92 10 	movl   $0x1092b0,0xc(%esp)
  102dcb:	00 
  102dcc:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  102dd3:	00 
  102dd4:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102ddb:	00 
  102ddc:	c7 04 24 db 92 10 00 	movl   $0x1092db,(%esp)
  102de3:	e8 46 da ff ff       	call   10082e <debug_panic>
	return c;
  102de8:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  102deb:	c9                   	leave  
  102dec:	c3                   	ret    

00102ded <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102ded:	55                   	push   %ebp
  102dee:	89 e5                	mov    %esp,%ebp
  102df0:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102df3:	e8 a2 ff ff ff       	call   102d9a <cpu_cur>
  102df8:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  102dfd:	0f 94 c0             	sete   %al
  102e00:	0f b6 c0             	movzbl %al,%eax
}
  102e03:	c9                   	leave  
  102e04:	c3                   	ret    

00102e05 <proc_print>:



void
proc_print(TYPE ty, proc* p)
{
  102e05:	55                   	push   %ebp
  102e06:	89 e5                	mov    %esp,%ebp
  102e08:	53                   	push   %ebx
  102e09:	83 ec 14             	sub    $0x14,%esp
	if(ty == ACQUIRE)
  102e0c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  102e10:	75 0e                	jne    102e20 <proc_print+0x1b>
		cprintf("acquire lock ");
  102e12:	c7 04 24 e8 92 10 00 	movl   $0x1092e8,(%esp)
  102e19:	e8 73 51 00 00       	call   107f91 <cprintf>
  102e1e:	eb 0c                	jmp    102e2c <proc_print+0x27>
	else
		cprintf("release lock ");
  102e20:	c7 04 24 f6 92 10 00 	movl   $0x1092f6,(%esp)
  102e27:	e8 65 51 00 00       	call   107f91 <cprintf>
	if(p != NULL)
  102e2c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  102e30:	74 2b                	je     102e5d <proc_print+0x58>
		cprintf("on cpu %d, process %d\n", cpu_cur()->id, p->num);
  102e32:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e35:	8b 58 38             	mov    0x38(%eax),%ebx
  102e38:	e8 5d ff ff ff       	call   102d9a <cpu_cur>
  102e3d:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  102e44:	0f b6 c0             	movzbl %al,%eax
  102e47:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  102e4b:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e4f:	c7 04 24 04 93 10 00 	movl   $0x109304,(%esp)
  102e56:	e8 36 51 00 00       	call   107f91 <cprintf>
  102e5b:	eb 1f                	jmp    102e7c <proc_print+0x77>
	else
		cprintf("on cpu %d\n", cpu_cur()->id);
  102e5d:	e8 38 ff ff ff       	call   102d9a <cpu_cur>
  102e62:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  102e69:	0f b6 c0             	movzbl %al,%eax
  102e6c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e70:	c7 04 24 1b 93 10 00 	movl   $0x10931b,(%esp)
  102e77:	e8 15 51 00 00       	call   107f91 <cprintf>
}
  102e7c:	83 c4 14             	add    $0x14,%esp
  102e7f:	5b                   	pop    %ebx
  102e80:	5d                   	pop    %ebp
  102e81:	c3                   	ret    

00102e82 <proc_init>:



void
proc_init(void)
{
  102e82:	55                   	push   %ebp
  102e83:	89 e5                	mov    %esp,%ebp
  102e85:	83 ec 18             	sub    $0x18,%esp
	
	if (!cpu_onboot())
  102e88:	e8 60 ff ff ff       	call   102ded <cpu_onboot>
  102e8d:	85 c0                	test   %eax,%eax
  102e8f:	74 3c                	je     102ecd <proc_init+0x4b>
		return;
	
	//cprintf("in proc_init, current cpu:%d\n", cpu_cur()->id);

	spinlock_init(&queue.lock);
  102e91:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  102e98:	00 
  102e99:	c7 44 24 04 26 93 10 	movl   $0x109326,0x4(%esp)
  102ea0:	00 
  102ea1:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  102ea8:	e8 22 f8 ff ff       	call   1026cf <spinlock_init_>

	queue.count= 0;
  102ead:	c7 05 78 f4 31 00 00 	movl   $0x0,0x31f478
  102eb4:	00 00 00 
	queue.head = NULL;
  102eb7:	c7 05 7c f4 31 00 00 	movl   $0x0,0x31f47c
  102ebe:	00 00 00 
	queue.tail= NULL;
  102ec1:	c7 05 80 f4 31 00 00 	movl   $0x0,0x31f480
  102ec8:	00 00 00 
  102ecb:	eb 01                	jmp    102ece <proc_init+0x4c>
void
proc_init(void)
{
	
	if (!cpu_onboot())
		return;
  102ecd:	90                   	nop
	queue.head = NULL;
	queue.tail= NULL;
	
	
	// your module initialization code here
}
  102ece:	c9                   	leave  
  102ecf:	c3                   	ret    

00102ed0 <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  102ed0:	55                   	push   %ebp
  102ed1:	89 e5                	mov    %esp,%ebp
  102ed3:	83 ec 28             	sub    $0x28,%esp

	//cprintf("in proc_alloc\n");
	
	pageinfo *pi = mem_alloc();
  102ed6:	e8 df df ff ff       	call   100eba <mem_alloc>
  102edb:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!pi)
  102ede:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  102ee2:	75 0a                	jne    102eee <proc_alloc+0x1e>
		return NULL;
  102ee4:	b8 00 00 00 00       	mov    $0x0,%eax
  102ee9:	e9 d6 01 00 00       	jmp    1030c4 <proc_alloc+0x1f4>
  102eee:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102ef1:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  102ef4:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102ef9:	83 c0 08             	add    $0x8,%eax
  102efc:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102eff:	76 15                	jbe    102f16 <proc_alloc+0x46>
  102f01:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102f06:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  102f0c:	c1 e2 03             	shl    $0x3,%edx
  102f0f:	01 d0                	add    %edx,%eax
  102f11:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102f14:	72 24                	jb     102f3a <proc_alloc+0x6a>
  102f16:	c7 44 24 0c 34 93 10 	movl   $0x109334,0xc(%esp)
  102f1d:	00 
  102f1e:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  102f25:	00 
  102f26:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  102f2d:	00 
  102f2e:	c7 04 24 6b 93 10 00 	movl   $0x10936b,(%esp)
  102f35:	e8 f4 d8 ff ff       	call   10082e <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  102f3a:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102f3f:	ba 00 10 32 00       	mov    $0x321000,%edx
  102f44:	c1 ea 0c             	shr    $0xc,%edx
  102f47:	c1 e2 03             	shl    $0x3,%edx
  102f4a:	01 d0                	add    %edx,%eax
  102f4c:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102f4f:	75 24                	jne    102f75 <proc_alloc+0xa5>
  102f51:	c7 44 24 0c 78 93 10 	movl   $0x109378,0xc(%esp)
  102f58:	00 
  102f59:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  102f60:	00 
  102f61:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  102f68:	00 
  102f69:	c7 04 24 6b 93 10 00 	movl   $0x10936b,(%esp)
  102f70:	e8 b9 d8 ff ff       	call   10082e <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  102f75:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102f7a:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  102f7f:	c1 ea 0c             	shr    $0xc,%edx
  102f82:	c1 e2 03             	shl    $0x3,%edx
  102f85:	01 d0                	add    %edx,%eax
  102f87:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102f8a:	72 3b                	jb     102fc7 <proc_alloc+0xf7>
  102f8c:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102f91:	ba 07 20 32 00       	mov    $0x322007,%edx
  102f96:	c1 ea 0c             	shr    $0xc,%edx
  102f99:	c1 e2 03             	shl    $0x3,%edx
  102f9c:	01 d0                	add    %edx,%eax
  102f9e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  102fa1:	77 24                	ja     102fc7 <proc_alloc+0xf7>
  102fa3:	c7 44 24 0c 94 93 10 	movl   $0x109394,0xc(%esp)
  102faa:	00 
  102fab:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  102fb2:	00 
  102fb3:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  102fba:	00 
  102fbb:	c7 04 24 6b 93 10 00 	movl   $0x10936b,(%esp)
  102fc2:	e8 67 d8 ff ff       	call   10082e <debug_panic>

	lockadd(&pi->refcount, 1);
  102fc7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102fca:	83 c0 04             	add    $0x4,%eax
  102fcd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102fd4:	00 
  102fd5:	89 04 24             	mov    %eax,(%esp)
  102fd8:	e8 a5 fd ff ff       	call   102d82 <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  102fdd:	8b 55 ec             	mov    -0x14(%ebp),%edx
  102fe0:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  102fe5:	89 d1                	mov    %edx,%ecx
  102fe7:	29 c1                	sub    %eax,%ecx
  102fe9:	89 c8                	mov    %ecx,%eax
  102feb:	c1 f8 03             	sar    $0x3,%eax
  102fee:	c1 e0 0c             	shl    $0xc,%eax
  102ff1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  102ff4:	c7 44 24 08 b0 06 00 	movl   $0x6b0,0x8(%esp)
  102ffb:	00 
  102ffc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103003:	00 
  103004:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103007:	89 04 24             	mov    %eax,(%esp)
  10300a:	e8 67 51 00 00       	call   108176 <memset>

	spinlock_init(&cp->lock);
  10300f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103012:	c7 44 24 08 52 00 00 	movl   $0x52,0x8(%esp)
  103019:	00 
  10301a:	c7 44 24 04 26 93 10 	movl   $0x109326,0x4(%esp)
  103021:	00 
  103022:	89 04 24             	mov    %eax,(%esp)
  103025:	e8 a5 f6 ff ff       	call   1026cf <spinlock_init_>
	cp->parent = p;
  10302a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10302d:	8b 55 08             	mov    0x8(%ebp),%edx
  103030:	89 50 3c             	mov    %edx,0x3c(%eax)
	cp->state = PROC_STOP;
  103033:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103036:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  10303d:	00 00 00 

	cp->num = count++;
  103040:	a1 20 aa 11 00       	mov    0x11aa20,%eax
  103045:	8b 55 f0             	mov    -0x10(%ebp),%edx
  103048:	89 42 38             	mov    %eax,0x38(%edx)
  10304b:	83 c0 01             	add    $0x1,%eax
  10304e:	a3 20 aa 11 00       	mov    %eax,0x11aa20

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  103053:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103056:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  10305d:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  10305f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103062:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  103069:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  10306b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10306e:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  103075:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  103077:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10307a:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  103081:	23 00 

	cp->sv.tf.eflags = FL_IF;
  103083:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103086:	c7 80 90 04 00 00 00 	movl   $0x200,0x490(%eax)
  10308d:	02 00 00 

	if (p)
  103090:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103094:	74 0f                	je     1030a5 <proc_alloc+0x1d5>
		p->child[cn] = cp;
  103096:	8b 55 0c             	mov    0xc(%ebp),%edx
  103099:	8b 45 08             	mov    0x8(%ebp),%eax
  10309c:	8d 4a 10             	lea    0x10(%edx),%ecx
  10309f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1030a2:	89 14 88             	mov    %edx,(%eax,%ecx,4)

	cp->pdir = pmap_newpdir();
  1030a5:	e8 fb 11 00 00       	call   1042a5 <pmap_newpdir>
  1030aa:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1030ad:	89 82 a0 06 00 00    	mov    %eax,0x6a0(%edx)
	cp->rpdir = pmap_newpdir();
  1030b3:	e8 ed 11 00 00       	call   1042a5 <pmap_newpdir>
  1030b8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1030bb:	89 82 a4 06 00 00    	mov    %eax,0x6a4(%edx)
	
	return cp;
  1030c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1030c4:	c9                   	leave  
  1030c5:	c3                   	ret    

001030c6 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  1030c6:	55                   	push   %ebp
  1030c7:	89 e5                	mov    %esp,%ebp
  1030c9:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_ready not implemented");

 	cprintf("proc %p is in ready, cur cpu is %d\n", p, cpu_cur()->id);
  1030cc:	e8 c9 fc ff ff       	call   102d9a <cpu_cur>
  1030d1:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1030d8:	0f b6 c0             	movzbl %al,%eax
  1030db:	89 44 24 08          	mov    %eax,0x8(%esp)
  1030df:	8b 45 08             	mov    0x8(%ebp),%eax
  1030e2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1030e6:	c7 04 24 c8 93 10 00 	movl   $0x1093c8,(%esp)
  1030ed:	e8 9f 4e 00 00       	call   107f91 <cprintf>
	if(p == NULL)
  1030f2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1030f6:	75 1c                	jne    103114 <proc_ready+0x4e>
		panic("proc_ready's p is null!");
  1030f8:	c7 44 24 08 ec 93 10 	movl   $0x1093ec,0x8(%esp)
  1030ff:	00 
  103100:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  103107:	00 
  103108:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  10310f:	e8 1a d7 ff ff       	call   10082e <debug_panic>
	
	assert(p->state != PROC_READY);
  103114:	8b 45 08             	mov    0x8(%ebp),%eax
  103117:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  10311d:	83 f8 01             	cmp    $0x1,%eax
  103120:	75 24                	jne    103146 <proc_ready+0x80>
  103122:	c7 44 24 0c 04 94 10 	movl   $0x109404,0xc(%esp)
  103129:	00 
  10312a:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  103131:	00 
  103132:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  103139:	00 
  10313a:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  103141:	e8 e8 d6 ff ff       	call   10082e <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  103146:	8b 45 08             	mov    0x8(%ebp),%eax
  103149:	89 04 24             	mov    %eax,(%esp)
  10314c:	e8 b2 f5 ff ff       	call   102703 <spinlock_acquire>
	p->state = PROC_READY;
  103151:	8b 45 08             	mov    0x8(%ebp),%eax
  103154:	c7 80 40 04 00 00 01 	movl   $0x1,0x440(%eax)
  10315b:	00 00 00 
	spinlock_acquire(&queue.lock);
  10315e:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  103165:	e8 99 f5 ff ff       	call   102703 <spinlock_acquire>
	// if there is no proc in queue now
	if(queue.count == 0){
  10316a:	a1 78 f4 31 00       	mov    0x31f478,%eax
  10316f:	85 c0                	test   %eax,%eax
  103171:	75 1f                	jne    103192 <proc_ready+0xcc>
		//cprintf("in ready = 0\n");
		queue.count++;
  103173:	a1 78 f4 31 00       	mov    0x31f478,%eax
  103178:	83 c0 01             	add    $0x1,%eax
  10317b:	a3 78 f4 31 00       	mov    %eax,0x31f478
		queue.head = p;
  103180:	8b 45 08             	mov    0x8(%ebp),%eax
  103183:	a3 7c f4 31 00       	mov    %eax,0x31f47c
		queue.tail = p;
  103188:	8b 45 08             	mov    0x8(%ebp),%eax
  10318b:	a3 80 f4 31 00       	mov    %eax,0x31f480
  103190:	eb 24                	jmp    1031b6 <proc_ready+0xf0>
	}

	// insert it to the head of the queue
	else{
		//cprintf("in ready != 0\n");
		p->readynext = queue.head;
  103192:	8b 15 7c f4 31 00    	mov    0x31f47c,%edx
  103198:	8b 45 08             	mov    0x8(%ebp),%eax
  10319b:	89 90 44 04 00 00    	mov    %edx,0x444(%eax)
		queue.head = p;
  1031a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1031a4:	a3 7c f4 31 00       	mov    %eax,0x31f47c
		queue.count += 1;
  1031a9:	a1 78 f4 31 00       	mov    0x31f478,%eax
  1031ae:	83 c0 01             	add    $0x1,%eax
  1031b1:	a3 78 f4 31 00       	mov    %eax,0x31f478
		//spinlock_release(&queue.lock);
		//proc_print(RELEASE, p);
		//spinlock_release(&p->lock);
	}

	spinlock_release(&p->lock);
  1031b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1031b9:	89 04 24             	mov    %eax,(%esp)
  1031bc:	e8 af f5 ff ff       	call   102770 <spinlock_release>
	spinlock_release(&queue.lock);
  1031c1:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  1031c8:	e8 a3 f5 ff ff       	call   102770 <spinlock_release>
	return;
	
}
  1031cd:	c9                   	leave  
  1031ce:	c3                   	ret    

001031cf <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  1031cf:	55                   	push   %ebp
  1031d0:	89 e5                	mov    %esp,%ebp
  1031d2:	83 ec 18             	sub    $0x18,%esp
	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  1031d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1031d8:	89 04 24             	mov    %eax,(%esp)
  1031db:	e8 23 f5 ff ff       	call   102703 <spinlock_acquire>

	switch(entry){
  1031e0:	8b 45 10             	mov    0x10(%ebp),%eax
  1031e3:	85 c0                	test   %eax,%eax
  1031e5:	74 2c                	je     103213 <proc_save+0x44>
  1031e7:	83 f8 01             	cmp    $0x1,%eax
  1031ea:	74 36                	je     103222 <proc_save+0x53>
  1031ec:	83 f8 ff             	cmp    $0xffffffff,%eax
  1031ef:	75 53                	jne    103244 <proc_save+0x75>
		case -1:		
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  1031f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1031f4:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  1031fa:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  103201:	00 
  103202:	8b 45 0c             	mov    0xc(%ebp),%eax
  103205:	89 44 24 04          	mov    %eax,0x4(%esp)
  103209:	89 14 24             	mov    %edx,(%esp)
  10320c:	e8 d9 4f 00 00       	call   1081ea <memmove>
			break;
  103211:	eb 4d                	jmp    103260 <proc_save+0x91>
		case 0:
			tf->eip = (uintptr_t)((char*)tf->eip - 2);
  103213:	8b 45 0c             	mov    0xc(%ebp),%eax
  103216:	8b 40 38             	mov    0x38(%eax),%eax
  103219:	8d 50 fe             	lea    -0x2(%eax),%edx
  10321c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10321f:	89 50 38             	mov    %edx,0x38(%eax)
		case 1:
			memmove(&(p->sv.tf), tf, sizeof(trapframe));
  103222:	8b 45 08             	mov    0x8(%ebp),%eax
  103225:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  10322b:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  103232:	00 
  103233:	8b 45 0c             	mov    0xc(%ebp),%eax
  103236:	89 44 24 04          	mov    %eax,0x4(%esp)
  10323a:	89 14 24             	mov    %edx,(%esp)
  10323d:	e8 a8 4f 00 00       	call   1081ea <memmove>
			break;
  103242:	eb 1c                	jmp    103260 <proc_save+0x91>
		default:
			panic("wrong entry!\n");
  103244:	c7 44 24 08 1b 94 10 	movl   $0x10941b,0x8(%esp)
  10324b:	00 
  10324c:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
  103253:	00 
  103254:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  10325b:	e8 ce d5 ff ff       	call   10082e <debug_panic>
	}

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  103260:	8b 45 08             	mov    0x8(%ebp),%eax
  103263:	89 04 24             	mov    %eax,(%esp)
  103266:	e8 05 f5 ff ff       	call   102770 <spinlock_release>
}
  10326b:	c9                   	leave  
  10326c:	c3                   	ret    

0010326d <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  10326d:	55                   	push   %ebp
  10326e:	89 e5                	mov    %esp,%ebp
  103270:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");

	if(p == NULL || p->state != PROC_RUN)
  103273:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103277:	74 0e                	je     103287 <proc_wait+0x1a>
  103279:	8b 45 08             	mov    0x8(%ebp),%eax
  10327c:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103282:	83 f8 02             	cmp    $0x2,%eax
  103285:	74 1c                	je     1032a3 <proc_wait+0x36>
		panic("parent proc is not running!");
  103287:	c7 44 24 08 29 94 10 	movl   $0x109429,0x8(%esp)
  10328e:	00 
  10328f:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
  103296:	00 
  103297:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  10329e:	e8 8b d5 ff ff       	call   10082e <debug_panic>
	if(cp == NULL)
  1032a3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1032a7:	75 1c                	jne    1032c5 <proc_wait+0x58>
		panic("no child proc!");
  1032a9:	c7 44 24 08 45 94 10 	movl   $0x109445,0x8(%esp)
  1032b0:	00 
  1032b1:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
  1032b8:	00 
  1032b9:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  1032c0:	e8 69 d5 ff ff       	call   10082e <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  1032c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1032c8:	89 04 24             	mov    %eax,(%esp)
  1032cb:	e8 33 f4 ff ff       	call   102703 <spinlock_acquire>
	p->state = PROC_WAIT;
  1032d0:	8b 45 08             	mov    0x8(%ebp),%eax
  1032d3:	c7 80 40 04 00 00 03 	movl   $0x3,0x440(%eax)
  1032da:	00 00 00 
	p->waitchild = cp;
  1032dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1032e0:	8b 55 0c             	mov    0xc(%ebp),%edx
  1032e3:	89 90 4c 04 00 00    	mov    %edx,0x44c(%eax)
	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  1032e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1032ec:	89 04 24             	mov    %eax,(%esp)
  1032ef:	e8 7c f4 ff ff       	call   102770 <spinlock_release>
	
	proc_save(p, tf, 0);
  1032f4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1032fb:	00 
  1032fc:	8b 45 10             	mov    0x10(%ebp),%eax
  1032ff:	89 44 24 04          	mov    %eax,0x4(%esp)
  103303:	8b 45 08             	mov    0x8(%ebp),%eax
  103306:	89 04 24             	mov    %eax,(%esp)
  103309:	e8 c1 fe ff ff       	call   1031cf <proc_save>

	assert(cp->state != PROC_STOP);
  10330e:	8b 45 0c             	mov    0xc(%ebp),%eax
  103311:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103317:	85 c0                	test   %eax,%eax
  103319:	75 24                	jne    10333f <proc_wait+0xd2>
  10331b:	c7 44 24 0c 54 94 10 	movl   $0x109454,0xc(%esp)
  103322:	00 
  103323:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  10332a:	00 
  10332b:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  103332:	00 
  103333:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  10333a:	e8 ef d4 ff ff       	call   10082e <debug_panic>
	
	proc_sched();
  10333f:	e8 00 00 00 00       	call   103344 <proc_sched>

00103344 <proc_sched>:
	
}

void gcc_noreturn
proc_sched(void)
{
  103344:	55                   	push   %ebp
  103345:	89 e5                	mov    %esp,%ebp
  103347:	83 ec 28             	sub    $0x28,%esp
			
		// if there is no ready process in queue
		// just wait

		//proc_print(ACQUIRE, NULL);
		spinlock_acquire(&queue.lock);
  10334a:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  103351:	e8 ad f3 ff ff       	call   102703 <spinlock_acquire>

		if(queue.count != 0){
  103356:	a1 78 f4 31 00       	mov    0x31f478,%eax
  10335b:	85 c0                	test   %eax,%eax
  10335d:	0f 84 8e 00 00 00    	je     1033f1 <proc_sched+0xad>
			// if there is just one ready process
			if(queue.count == 1){
  103363:	a1 78 f4 31 00       	mov    0x31f478,%eax
  103368:	83 f8 01             	cmp    $0x1,%eax
  10336b:	75 28                	jne    103395 <proc_sched+0x51>
				//cprintf("in sched queue.count == 1\n");
				run = queue.head;
  10336d:	a1 7c f4 31 00       	mov    0x31f47c,%eax
  103372:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.head = queue.tail = NULL;
  103375:	c7 05 80 f4 31 00 00 	movl   $0x0,0x31f480
  10337c:	00 00 00 
  10337f:	a1 80 f4 31 00       	mov    0x31f480,%eax
  103384:	a3 7c f4 31 00       	mov    %eax,0x31f47c
				queue.count = 0;	
  103389:	c7 05 78 f4 31 00 00 	movl   $0x0,0x31f478
  103390:	00 00 00 
  103393:	eb 45                	jmp    1033da <proc_sched+0x96>
			
			
			// if there is more than one ready processes
			else{
				//cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
  103395:	a1 7c f4 31 00       	mov    0x31f47c,%eax
  10339a:	89 45 f4             	mov    %eax,-0xc(%ebp)
				while(before_tail->readynext != queue.tail){
  10339d:	eb 0c                	jmp    1033ab <proc_sched+0x67>
					before_tail = before_tail->readynext;
  10339f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1033a2:	8b 80 44 04 00 00    	mov    0x444(%eax),%eax
  1033a8:	89 45 f4             	mov    %eax,-0xc(%ebp)
			
			// if there is more than one ready processes
			else{
				//cprintf("in sched queue.count > 1\n");
				proc* before_tail = queue.head;
				while(before_tail->readynext != queue.tail){
  1033ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1033ae:	8b 90 44 04 00 00    	mov    0x444(%eax),%edx
  1033b4:	a1 80 f4 31 00       	mov    0x31f480,%eax
  1033b9:	39 c2                	cmp    %eax,%edx
  1033bb:	75 e2                	jne    10339f <proc_sched+0x5b>
					before_tail = before_tail->readynext;
				}	
				run = queue.tail;
  1033bd:	a1 80 f4 31 00       	mov    0x31f480,%eax
  1033c2:	89 45 f0             	mov    %eax,-0x10(%ebp)
				queue.tail = before_tail;
  1033c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1033c8:	a3 80 f4 31 00       	mov    %eax,0x31f480
				queue.count--;				
  1033cd:	a1 78 f4 31 00       	mov    0x31f478,%eax
  1033d2:	83 e8 01             	sub    $0x1,%eax
  1033d5:	a3 78 f4 31 00       	mov    %eax,0x31f478
				queue.count--;
			}
			*/
			
	
			spinlock_release(&queue.lock);
  1033da:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  1033e1:	e8 8a f3 ff ff       	call   102770 <spinlock_release>
			proc_run(run);
  1033e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1033e9:	89 04 24             	mov    %eax,(%esp)
  1033ec:	e8 16 00 00 00       	call   103407 <proc_run>
		}
		spinlock_release(&queue.lock);
  1033f1:	c7 04 24 40 f4 31 00 	movl   $0x31f440,(%esp)
  1033f8:	e8 73 f3 ff ff       	call   102770 <spinlock_release>
		pause();
  1033fd:	e8 91 f9 ff ff       	call   102d93 <pause>
	}
  103402:	e9 43 ff ff ff       	jmp    10334a <proc_sched+0x6>

00103407 <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  103407:	55                   	push   %ebp
  103408:	89 e5                	mov    %esp,%ebp
  10340a:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");

	cprintf("proc %x is running on cpu:%d\n", p, cpu_cur()->id);
  10340d:	e8 88 f9 ff ff       	call   102d9a <cpu_cur>
  103412:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  103419:	0f b6 c0             	movzbl %al,%eax
  10341c:	89 44 24 08          	mov    %eax,0x8(%esp)
  103420:	8b 45 08             	mov    0x8(%ebp),%eax
  103423:	89 44 24 04          	mov    %eax,0x4(%esp)
  103427:	c7 04 24 6b 94 10 00 	movl   $0x10946b,(%esp)
  10342e:	e8 5e 4b 00 00       	call   107f91 <cprintf>
	
	if(p == NULL)
  103433:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103437:	75 1c                	jne    103455 <proc_run+0x4e>
		panic("proc_run's p is null!");
  103439:	c7 44 24 08 89 94 10 	movl   $0x109489,0x8(%esp)
  103440:	00 
  103441:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
  103448:	00 
  103449:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  103450:	e8 d9 d3 ff ff       	call   10082e <debug_panic>

	assert(p->state == PROC_READY);
  103455:	8b 45 08             	mov    0x8(%ebp),%eax
  103458:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  10345e:	83 f8 01             	cmp    $0x1,%eax
  103461:	74 24                	je     103487 <proc_run+0x80>
  103463:	c7 44 24 0c 9f 94 10 	movl   $0x10949f,0xc(%esp)
  10346a:	00 
  10346b:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  103472:	00 
  103473:	c7 44 24 04 18 01 00 	movl   $0x118,0x4(%esp)
  10347a:	00 
  10347b:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  103482:	e8 a7 d3 ff ff       	call   10082e <debug_panic>

	//proc_print(ACQUIRE, p);
	spinlock_acquire(&p->lock);
  103487:	8b 45 08             	mov    0x8(%ebp),%eax
  10348a:	89 04 24             	mov    %eax,(%esp)
  10348d:	e8 71 f2 ff ff       	call   102703 <spinlock_acquire>

	cpu* c = cpu_cur();
  103492:	e8 03 f9 ff ff       	call   102d9a <cpu_cur>
  103497:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->proc = p;
  10349a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10349d:	8b 55 08             	mov    0x8(%ebp),%edx
  1034a0:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	p->state = PROC_RUN;
  1034a6:	8b 45 08             	mov    0x8(%ebp),%eax
  1034a9:	c7 80 40 04 00 00 02 	movl   $0x2,0x440(%eax)
  1034b0:	00 00 00 
	p->runcpu = c;
  1034b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1034b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1034b9:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)

	//proc_print(RELEASE, p);
	spinlock_release(&p->lock);
  1034bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1034c2:	89 04 24             	mov    %eax,(%esp)
  1034c5:	e8 a6 f2 ff ff       	call   102770 <spinlock_release>

	cprintf("eip = %x\n", p->sv.tf.eip);
  1034ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1034cd:	8b 80 88 04 00 00    	mov    0x488(%eax),%eax
  1034d3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1034d7:	c7 04 24 b6 94 10 00 	movl   $0x1094b6,(%esp)
  1034de:	e8 ae 4a 00 00       	call   107f91 <cprintf>
	
	trap_return(&p->sv.tf);
  1034e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1034e6:	05 50 04 00 00       	add    $0x450,%eax
  1034eb:	89 04 24             	mov    %eax,(%esp)
  1034ee:	e8 fd 8b 00 00       	call   10c0f0 <trap_return>

001034f3 <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  1034f3:	55                   	push   %ebp
  1034f4:	89 e5                	mov    %esp,%ebp
  1034f6:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_yield not implemented");

 	//cprintf("in yield\n");
	proc* cur_proc = cpu_cur()->proc;
  1034f9:	e8 9c f8 ff ff       	call   102d9a <cpu_cur>
  1034fe:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103504:	89 45 f4             	mov    %eax,-0xc(%ebp)
	proc_save(cur_proc, tf, 1);
  103507:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10350e:	00 
  10350f:	8b 45 08             	mov    0x8(%ebp),%eax
  103512:	89 44 24 04          	mov    %eax,0x4(%esp)
  103516:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103519:	89 04 24             	mov    %eax,(%esp)
  10351c:	e8 ae fc ff ff       	call   1031cf <proc_save>
	proc_ready(cur_proc);
  103521:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103524:	89 04 24             	mov    %eax,(%esp)
  103527:	e8 9a fb ff ff       	call   1030c6 <proc_ready>
	proc_sched();
  10352c:	e8 13 fe ff ff       	call   103344 <proc_sched>

00103531 <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  103531:	55                   	push   %ebp
  103532:	89 e5                	mov    %esp,%ebp
  103534:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_ret not implemented");

	proc* proc_child = proc_cur();
  103537:	e8 5e f8 ff ff       	call   102d9a <cpu_cur>
  10353c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103542:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_parent = proc_child->parent;
  103545:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103548:	8b 40 3c             	mov    0x3c(%eax),%eax
  10354b:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child->state != PROC_STOP);
  10354e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103551:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103557:	85 c0                	test   %eax,%eax
  103559:	75 24                	jne    10357f <proc_ret+0x4e>
  10355b:	c7 44 24 0c c0 94 10 	movl   $0x1094c0,0xc(%esp)
  103562:	00 
  103563:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  10356a:	00 
  10356b:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
  103572:	00 
  103573:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  10357a:	e8 af d2 ff ff       	call   10082e <debug_panic>

	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  10357f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103582:	89 04 24             	mov    %eax,(%esp)
  103585:	e8 79 f1 ff ff       	call   102703 <spinlock_acquire>
	proc_child->state = PROC_STOP;
  10358a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10358d:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  103594:	00 00 00 
	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  103597:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10359a:	89 04 24             	mov    %eax,(%esp)
  10359d:	e8 ce f1 ff ff       	call   102770 <spinlock_release>

	proc_save(proc_child, tf, entry);
  1035a2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1035a5:	89 44 24 08          	mov    %eax,0x8(%esp)
  1035a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1035ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1035b3:	89 04 24             	mov    %eax,(%esp)
  1035b6:	e8 14 fc ff ff       	call   1031cf <proc_save>

	if((proc_parent->state == PROC_WAIT) && (proc_parent->waitchild == proc_child) )
  1035bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035be:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  1035c4:	83 f8 03             	cmp    $0x3,%eax
  1035c7:	75 19                	jne    1035e2 <proc_ret+0xb1>
  1035c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035cc:	8b 80 4c 04 00 00    	mov    0x44c(%eax),%eax
  1035d2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1035d5:	75 0b                	jne    1035e2 <proc_ret+0xb1>
		proc_ready(proc_parent);
  1035d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035da:	89 04 24             	mov    %eax,(%esp)
  1035dd:	e8 e4 fa ff ff       	call   1030c6 <proc_ready>

	proc_sched();
  1035e2:	e8 5d fd ff ff       	call   103344 <proc_sched>

001035e7 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  1035e7:	55                   	push   %ebp
  1035e8:	89 e5                	mov    %esp,%ebp
  1035ea:	57                   	push   %edi
  1035eb:	56                   	push   %esi
  1035ec:	53                   	push   %ebx
  1035ed:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  1035f3:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  1035fa:	00 00 00 
  1035fd:	e9 06 01 00 00       	jmp    103708 <proc_check+0x121>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  103602:	b8 90 ac 11 00       	mov    $0x11ac90,%eax
  103607:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  10360d:	83 c2 01             	add    $0x1,%edx
  103610:	c1 e2 0c             	shl    $0xc,%edx
  103613:	01 d0                	add    %edx,%eax
  103615:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		*--esp = i;	// push argument to child() function
  10361b:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  103622:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  103628:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  10362e:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  103630:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  103637:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  10363d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  103643:	b8 20 3b 10 00       	mov    $0x103b20,%eax
  103648:	a3 78 aa 11 00       	mov    %eax,0x11aa78
		child_state.tf.esp = (uint32_t) esp;
  10364d:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  103653:	a3 84 aa 11 00       	mov    %eax,0x11aa84

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  103658:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10365e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103662:	c7 04 24 df 94 10 00 	movl   $0x1094df,(%esp)
  103669:	e8 23 49 00 00       	call   107f91 <cprintf>

		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  10366e:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103674:	0f b7 d0             	movzwl %ax,%edx
  103677:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  10367e:	7f 07                	jg     103687 <proc_check+0xa0>
  103680:	b8 10 10 00 00       	mov    $0x1010,%eax
  103685:	eb 05                	jmp    10368c <proc_check+0xa5>
  103687:	b8 00 10 00 00       	mov    $0x1000,%eax
  10368c:	89 85 54 ff ff ff    	mov    %eax,-0xac(%ebp)
  103692:	66 89 95 52 ff ff ff 	mov    %dx,-0xae(%ebp)
  103699:	c7 85 4c ff ff ff 40 	movl   $0x11aa40,-0xb4(%ebp)
  1036a0:	aa 11 00 
  1036a3:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
  1036aa:	00 00 00 
  1036ad:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
  1036b4:	00 00 00 
  1036b7:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
  1036be:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1036c1:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
  1036c7:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1036ca:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
  1036d0:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
  1036d7:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
  1036dd:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
  1036e3:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
  1036e9:	cd 30                	int    $0x30
			NULL, NULL, 0);
		
		cprintf("i == %d complete!\n", i);
  1036eb:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1036f1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036f5:	c7 04 24 f2 94 10 00 	movl   $0x1094f2,(%esp)
  1036fc:	e8 90 48 00 00       	call   107f91 <cprintf>
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  103701:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103708:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  10370f:	0f 8e ed fe ff ff    	jle    103602 <proc_check+0x1b>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  103715:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10371c:	00 00 00 
  10371f:	e9 89 00 00 00       	jmp    1037ad <proc_check+0x1c6>
		cprintf("waiting for child %d\n", i);
  103724:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  10372a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10372e:	c7 04 24 05 95 10 00 	movl   $0x109505,(%esp)
  103735:	e8 57 48 00 00       	call   107f91 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10373a:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103740:	0f b7 c0             	movzwl %ax,%eax
  103743:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
  10374a:	10 00 00 
  10374d:	66 89 85 6a ff ff ff 	mov    %ax,-0x96(%ebp)
  103754:	c7 85 64 ff ff ff 40 	movl   $0x11aa40,-0x9c(%ebp)
  10375b:	aa 11 00 
  10375e:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
  103765:	00 00 00 
  103768:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
  10376f:	00 00 00 
  103772:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
  103779:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10377c:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
  103782:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103785:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
  10378b:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
  103792:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
  103798:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
  10379e:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
  1037a4:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  1037a6:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  1037ad:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  1037b4:	0f 8e 6a ff ff ff    	jle    103724 <proc_check+0x13d>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  1037ba:	c7 04 24 1c 95 10 00 	movl   $0x10951c,(%esp)
  1037c1:	e8 cb 47 00 00       	call   107f91 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  1037c6:	c7 04 24 44 95 10 00 	movl   $0x109544,(%esp)
  1037cd:	e8 bf 47 00 00       	call   107f91 <cprintf>
	for (i = 0; i < 4; i++) {
  1037d2:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  1037d9:	00 00 00 
  1037dc:	eb 7d                	jmp    10385b <proc_check+0x274>
		cprintf("spawning child %d\n", i);
  1037de:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1037e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1037e8:	c7 04 24 df 94 10 00 	movl   $0x1094df,(%esp)
  1037ef:	e8 9d 47 00 00       	call   107f91 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  1037f4:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1037fa:	0f b7 c0             	movzwl %ax,%eax
  1037fd:	c7 45 84 10 00 00 00 	movl   $0x10,-0x7c(%ebp)
  103804:	66 89 45 82          	mov    %ax,-0x7e(%ebp)
  103808:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  10380f:	00 00 00 
  103812:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
  103819:	00 00 00 
  10381c:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
  103823:	00 00 00 
  103826:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
  10382d:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103830:	8b 45 84             	mov    -0x7c(%ebp),%eax
  103833:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103836:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
  10383c:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
  103840:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
  103846:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
  10384c:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
  103852:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  103854:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  10385b:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103862:	0f 8e 76 ff ff ff    	jle    1037de <proc_check+0x1f7>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
  103868:	c7 04 24 68 95 10 00 	movl   $0x109568,(%esp)
  10386f:	e8 1d 47 00 00       	call   107f91 <cprintf>
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103874:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  10387b:	00 00 00 
  10387e:	eb 4f                	jmp    1038cf <proc_check+0x2e8>
		sys_get(0, i, NULL, NULL, NULL, 0);
  103880:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103886:	0f b7 c0             	movzwl %ax,%eax
  103889:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  103890:	66 89 45 9a          	mov    %ax,-0x66(%ebp)
  103894:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
  10389b:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  1038a2:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
  1038a9:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1038b0:	8b 45 9c             	mov    -0x64(%ebp),%eax
  1038b3:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1038b6:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
  1038b9:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
  1038bd:	8b 75 90             	mov    -0x70(%ebp),%esi
  1038c0:	8b 7d 8c             	mov    -0x74(%ebp),%edi
  1038c3:	8b 4d 88             	mov    -0x78(%ebp),%ecx
  1038c6:	cd 30                	int    $0x30
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	cprintf("Wait for all 4 children to complete.\n");
	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  1038c8:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  1038cf:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  1038d6:	7e a8                	jle    103880 <proc_check+0x299>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  1038d8:	c7 04 24 90 95 10 00 	movl   $0x109590,(%esp)
  1038df:	e8 ad 46 00 00       	call   107f91 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  1038e4:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  1038eb:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  1038ee:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1038f4:	0f b7 c0             	movzwl %ax,%eax
  1038f7:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
  1038fe:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
  103902:	c7 45 ac 40 aa 11 00 	movl   $0x11aa40,-0x54(%ebp)
  103909:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  103910:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  103917:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10391e:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  103921:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103924:	8b 5d ac             	mov    -0x54(%ebp),%ebx
  103927:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
  10392b:	8b 75 a8             	mov    -0x58(%ebp),%esi
  10392e:	8b 7d a4             	mov    -0x5c(%ebp),%edi
  103931:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  103934:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  103936:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  10393b:	85 c0                	test   %eax,%eax
  10393d:	74 24                	je     103963 <proc_check+0x37c>
  10393f:	c7 44 24 0c b5 95 10 	movl   $0x1095b5,0xc(%esp)
  103946:	00 
  103947:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  10394e:	00 
  10394f:	c7 44 24 04 96 01 00 	movl   $0x196,0x4(%esp)
  103956:	00 
  103957:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  10395e:	e8 cb ce ff ff       	call   10082e <debug_panic>
	cprintf("============== tag 1 \n");
  103963:	c7 04 24 c7 95 10 00 	movl   $0x1095c7,(%esp)
  10396a:	e8 22 46 00 00       	call   107f91 <cprintf>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  10396f:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103975:	0f b7 c0             	movzwl %ax,%eax
  103978:	c7 45 cc 10 10 00 00 	movl   $0x1010,-0x34(%ebp)
  10397f:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
  103983:	c7 45 c4 40 aa 11 00 	movl   $0x11aa40,-0x3c(%ebp)
  10398a:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
  103991:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  103998:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  10399f:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1039a2:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1039a5:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
  1039a8:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  1039ac:	8b 75 c0             	mov    -0x40(%ebp),%esi
  1039af:	8b 7d bc             	mov    -0x44(%ebp),%edi
  1039b2:	8b 4d b8             	mov    -0x48(%ebp),%ecx
  1039b5:	cd 30                	int    $0x30
		//cprintf("(1). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  1039b7:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  1039bd:	0f b7 c0             	movzwl %ax,%eax
  1039c0:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  1039c7:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
  1039cb:	c7 45 dc 40 aa 11 00 	movl   $0x11aa40,-0x24(%ebp)
  1039d2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1039d9:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  1039e0:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1039e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1039ea:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1039ed:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  1039f0:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  1039f4:	8b 75 d8             	mov    -0x28(%ebp),%esi
  1039f7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  1039fa:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  1039fd:	cd 30                	int    $0x30
		//cprintf("(2). child_state.tf.trapno = %d\n", child_state.tf.trapno);
		cprintf("recovargs 0x%x\n",recovargs);
  1039ff:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  103a04:	89 44 24 04          	mov    %eax,0x4(%esp)
  103a08:	c7 04 24 de 95 10 00 	movl   $0x1095de,(%esp)
  103a0f:	e8 7d 45 00 00       	call   107f91 <cprintf>
		
		if (recovargs) {	// trap recovery needed
  103a14:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  103a19:	85 c0                	test   %eax,%eax
  103a1b:	74 55                	je     103a72 <proc_check+0x48b>
			cprintf("i = %d\n", i);
  103a1d:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103a23:	89 44 24 04          	mov    %eax,0x4(%esp)
  103a27:	c7 04 24 ee 95 10 00 	movl   $0x1095ee,(%esp)
  103a2e:	e8 5e 45 00 00       	call   107f91 <cprintf>
			trap_check_args *argss = recovargs;
  103a33:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  103a38:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)
			cprintf("recover from trap %d\n",
  103a3e:	a1 70 aa 11 00       	mov    0x11aa70,%eax
  103a43:	89 44 24 04          	mov    %eax,0x4(%esp)
  103a47:	c7 04 24 f6 95 10 00 	movl   $0x1095f6,(%esp)
  103a4e:	e8 3e 45 00 00       	call   107f91 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) argss->reip;
  103a53:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  103a59:	8b 00                	mov    (%eax),%eax
  103a5b:	a3 78 aa 11 00       	mov    %eax,0x11aa78
			argss->trapno = child_state.tf.trapno;
  103a60:	a1 70 aa 11 00       	mov    0x11aa70,%eax
  103a65:	89 c2                	mov    %eax,%edx
  103a67:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  103a6d:	89 50 04             	mov    %edx,0x4(%eax)
  103a70:	eb 2e                	jmp    103aa0 <proc_check+0x4b9>
			//cprintf(">>>>>args->trapno = %d, child_state.tf.trapno = %d\n", 
			//	args->trapno, child_state.tf.trapno);
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  103a72:	a1 70 aa 11 00       	mov    0x11aa70,%eax
  103a77:	83 f8 30             	cmp    $0x30,%eax
  103a7a:	74 24                	je     103aa0 <proc_check+0x4b9>
  103a7c:	c7 44 24 0c 0c 96 10 	movl   $0x10960c,0xc(%esp)
  103a83:	00 
  103a84:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  103a8b:	00 
  103a8c:	c7 44 24 04 a9 01 00 	movl   $0x1a9,0x4(%esp)
  103a93:	00 
  103a94:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  103a9b:	e8 8e cd ff ff       	call   10082e <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  103aa0:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103aa6:	8d 50 01             	lea    0x1(%eax),%edx
  103aa9:	89 d0                	mov    %edx,%eax
  103aab:	c1 f8 1f             	sar    $0x1f,%eax
  103aae:	c1 e8 1e             	shr    $0x1e,%eax
  103ab1:	01 c2                	add    %eax,%edx
  103ab3:	83 e2 03             	and    $0x3,%edx
  103ab6:	89 d1                	mov    %edx,%ecx
  103ab8:	29 c1                	sub    %eax,%ecx
  103aba:	89 c8                	mov    %ecx,%eax
  103abc:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  103ac2:	a1 70 aa 11 00       	mov    0x11aa70,%eax
  103ac7:	83 f8 30             	cmp    $0x30,%eax
  103aca:	0f 85 9f fe ff ff    	jne    10396f <proc_check+0x388>
	assert(recovargs == NULL);
  103ad0:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  103ad5:	85 c0                	test   %eax,%eax
  103ad7:	74 24                	je     103afd <proc_check+0x516>
  103ad9:	c7 44 24 0c b5 95 10 	movl   $0x1095b5,0xc(%esp)
  103ae0:	00 
  103ae1:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  103ae8:	00 
  103ae9:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
  103af0:	00 
  103af1:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  103af8:	e8 31 cd ff ff       	call   10082e <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  103afd:	c7 04 24 30 96 10 00 	movl   $0x109630,(%esp)
  103b04:	e8 88 44 00 00       	call   107f91 <cprintf>

	cprintf("proc_check() succeeded!\n");
  103b09:	c7 04 24 5d 96 10 00 	movl   $0x10965d,(%esp)
  103b10:	e8 7c 44 00 00       	call   107f91 <cprintf>
}
  103b15:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  103b1b:	5b                   	pop    %ebx
  103b1c:	5e                   	pop    %esi
  103b1d:	5f                   	pop    %edi
  103b1e:	5d                   	pop    %ebp
  103b1f:	c3                   	ret    

00103b20 <child>:

static void child(int n)
{
  103b20:	55                   	push   %ebp
  103b21:	89 e5                	mov    %esp,%ebp
  103b23:	83 ec 28             	sub    $0x28,%esp
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  103b26:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  103b2a:	7f 64                	jg     103b90 <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  103b2c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  103b33:	eb 4e                	jmp    103b83 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  103b35:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103b38:	89 44 24 08          	mov    %eax,0x8(%esp)
  103b3c:	8b 45 08             	mov    0x8(%ebp),%eax
  103b3f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b43:	c7 04 24 76 96 10 00 	movl   $0x109676,(%esp)
  103b4a:	e8 42 44 00 00       	call   107f91 <cprintf>
			while (pingpong != n){
  103b4f:	eb 05                	jmp    103b56 <child+0x36>
				//cprintf("in pingpong = %d\n", pingpong);
				pause();
  103b51:	e8 3d f2 ff ff       	call   102d93 <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n){
  103b56:	8b 55 08             	mov    0x8(%ebp),%edx
  103b59:	a1 90 ec 11 00       	mov    0x11ec90,%eax
  103b5e:	39 c2                	cmp    %eax,%edx
  103b60:	75 ef                	jne    103b51 <child+0x31>
				//cprintf("in pingpong = %d\n", pingpong);
				pause();
			}
			xchg(&pingpong, !pingpong);
  103b62:	a1 90 ec 11 00       	mov    0x11ec90,%eax
  103b67:	85 c0                	test   %eax,%eax
  103b69:	0f 94 c0             	sete   %al
  103b6c:	0f b6 c0             	movzbl %al,%eax
  103b6f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b73:	c7 04 24 90 ec 11 00 	movl   $0x11ec90,(%esp)
  103b7a:	e8 e9 f1 ff ff       	call   102d68 <xchg>
{
	//cprintf("in child()s\n");
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  103b7f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  103b83:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  103b87:	7e ac                	jle    103b35 <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  103b89:	b8 03 00 00 00       	mov    $0x3,%eax
  103b8e:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103b90:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103b97:	eb 47                	jmp    103be0 <child+0xc0>
		//cprintf("in child %d count %d\n", n, i);
		cprintf("child num:%d\n", queue.count);
  103b99:	a1 78 f4 31 00       	mov    0x31f478,%eax
  103b9e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103ba2:	c7 04 24 8c 96 10 00 	movl   $0x10968c,(%esp)
  103ba9:	e8 e3 43 00 00       	call   107f91 <cprintf>
		
		while (pingpong != n){
  103bae:	eb 05                	jmp    103bb5 <child+0x95>
			//cprintf("in pingpong = %d\n", pingpong);
			pause();
  103bb0:	e8 de f1 ff ff       	call   102d93 <pause>
	int i;
	for (i = 0; i < 10; i++) {
		//cprintf("in child %d count %d\n", n, i);
		cprintf("child num:%d\n", queue.count);
		
		while (pingpong != n){
  103bb5:	8b 55 08             	mov    0x8(%ebp),%edx
  103bb8:	a1 90 ec 11 00       	mov    0x11ec90,%eax
  103bbd:	39 c2                	cmp    %eax,%edx
  103bbf:	75 ef                	jne    103bb0 <child+0x90>
			//cprintf("in pingpong = %d\n", pingpong);
			pause();
		}
		xchg(&pingpong, (pingpong + 1) % 4);
  103bc1:	a1 90 ec 11 00       	mov    0x11ec90,%eax
  103bc6:	83 c0 01             	add    $0x1,%eax
  103bc9:	83 e0 03             	and    $0x3,%eax
  103bcc:	89 44 24 04          	mov    %eax,0x4(%esp)
  103bd0:	c7 04 24 90 ec 11 00 	movl   $0x11ec90,(%esp)
  103bd7:	e8 8c f1 ff ff       	call   102d68 <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103bdc:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103be0:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  103be4:	7e b3                	jle    103b99 <child+0x79>
  103be6:	b8 03 00 00 00       	mov    $0x3,%eax
  103beb:	cd 30                	int    $0x30
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...

	cprintf("child get last test\n");
  103bed:	c7 04 24 9a 96 10 00 	movl   $0x10969a,(%esp)
  103bf4:	e8 98 43 00 00       	call   107f91 <cprintf>
	if (n == 0) {
  103bf9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103bfd:	75 6d                	jne    103c6c <child+0x14c>
		assert(recovargs == NULL);
  103bff:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  103c04:	85 c0                	test   %eax,%eax
  103c06:	74 24                	je     103c2c <child+0x10c>
  103c08:	c7 44 24 0c b5 95 10 	movl   $0x1095b5,0xc(%esp)
  103c0f:	00 
  103c10:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  103c17:	00 
  103c18:	c7 44 24 04 d9 01 00 	movl   $0x1d9,0x4(%esp)
  103c1f:	00 
  103c20:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  103c27:	e8 02 cc ff ff       	call   10082e <debug_panic>
		trap_check(&recovargs);
  103c2c:	c7 04 24 94 ec 11 00 	movl   $0x11ec94,(%esp)
  103c33:	e8 ec e1 ff ff       	call   101e24 <trap_check>
		assert(recovargs == NULL);
  103c38:	a1 94 ec 11 00       	mov    0x11ec94,%eax
  103c3d:	85 c0                	test   %eax,%eax
  103c3f:	74 24                	je     103c65 <child+0x145>
  103c41:	c7 44 24 0c b5 95 10 	movl   $0x1095b5,0xc(%esp)
  103c48:	00 
  103c49:	c7 44 24 08 c6 92 10 	movl   $0x1092c6,0x8(%esp)
  103c50:	00 
  103c51:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
  103c58:	00 
  103c59:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  103c60:	e8 c9 cb ff ff       	call   10082e <debug_panic>
  103c65:	b8 03 00 00 00       	mov    $0x3,%eax
  103c6a:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  103c6c:	c7 44 24 08 b0 96 10 	movl   $0x1096b0,0x8(%esp)
  103c73:	00 
  103c74:	c7 44 24 04 df 01 00 	movl   $0x1df,0x4(%esp)
  103c7b:	00 
  103c7c:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  103c83:	e8 a6 cb ff ff       	call   10082e <debug_panic>

00103c88 <grandchild>:
}

static void grandchild(int n)
{
  103c88:	55                   	push   %ebp
  103c89:	89 e5                	mov    %esp,%ebp
  103c8b:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  103c8e:	c7 44 24 08 d4 96 10 	movl   $0x1096d4,0x8(%esp)
  103c95:	00 
  103c96:	c7 44 24 04 e4 01 00 	movl   $0x1e4,0x4(%esp)
  103c9d:	00 
  103c9e:	c7 04 24 26 93 10 00 	movl   $0x109326,(%esp)
  103ca5:	e8 84 cb ff ff       	call   10082e <debug_panic>

00103caa <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103caa:	55                   	push   %ebp
  103cab:	89 e5                	mov    %esp,%ebp
  103cad:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103cb0:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  103cb3:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103cb6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103cb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103cbc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103cc1:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  103cc4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103cc7:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103ccd:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103cd2:	74 24                	je     103cf8 <cpu_cur+0x4e>
  103cd4:	c7 44 24 0c 00 97 10 	movl   $0x109700,0xc(%esp)
  103cdb:	00 
  103cdc:	c7 44 24 08 16 97 10 	movl   $0x109716,0x8(%esp)
  103ce3:	00 
  103ce4:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103ceb:	00 
  103cec:	c7 04 24 2b 97 10 00 	movl   $0x10972b,(%esp)
  103cf3:	e8 36 cb ff ff       	call   10082e <debug_panic>
	return c;
  103cf8:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103cfb:	c9                   	leave  
  103cfc:	c3                   	ret    

00103cfd <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  103cfd:	55                   	push   %ebp
  103cfe:	89 e5                	mov    %esp,%ebp
  103d00:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  103d03:	c7 44 24 08 38 97 10 	movl   $0x109738,0x8(%esp)
  103d0a:	00 
  103d0b:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  103d12:	00 
  103d13:	c7 04 24 53 97 10 00 	movl   $0x109753,(%esp)
  103d1a:	e8 0f cb ff ff       	call   10082e <debug_panic>

00103d1f <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  103d1f:	55                   	push   %ebp
  103d20:	89 e5                	mov    %esp,%ebp
  103d22:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  103d25:	c7 44 24 08 62 97 10 	movl   $0x109762,0x8(%esp)
  103d2c:	00 
  103d2d:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  103d34:	00 
  103d35:	c7 04 24 53 97 10 00 	movl   $0x109753,(%esp)
  103d3c:	e8 ed ca ff ff       	call   10082e <debug_panic>

00103d41 <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  103d41:	55                   	push   %ebp
  103d42:	89 e5                	mov    %esp,%ebp
  103d44:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  103d47:	c7 44 24 08 80 97 10 	movl   $0x109780,0x8(%esp)
  103d4e:	00 
  103d4f:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  103d56:	00 
  103d57:	c7 04 24 53 97 10 00 	movl   $0x109753,(%esp)
  103d5e:	e8 cb ca ff ff       	call   10082e <debug_panic>

00103d63 <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  103d63:	55                   	push   %ebp
  103d64:	89 e5                	mov    %esp,%ebp
  103d66:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  103d69:	8b 45 18             	mov    0x18(%ebp),%eax
  103d6c:	89 44 24 08          	mov    %eax,0x8(%esp)
  103d70:	8b 45 14             	mov    0x14(%ebp),%eax
  103d73:	89 44 24 04          	mov    %eax,0x4(%esp)
  103d77:	8b 45 08             	mov    0x8(%ebp),%eax
  103d7a:	89 04 24             	mov    %eax,(%esp)
  103d7d:	e8 bf ff ff ff       	call   103d41 <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  103d82:	c7 44 24 08 9c 97 10 	movl   $0x10979c,0x8(%esp)
  103d89:	00 
  103d8a:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  103d91:	00 
  103d92:	c7 04 24 53 97 10 00 	movl   $0x109753,(%esp)
  103d99:	e8 90 ca ff ff       	call   10082e <debug_panic>

00103d9e <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  103d9e:	55                   	push   %ebp
  103d9f:	89 e5                	mov    %esp,%ebp
  103da1:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  103da4:	8b 45 08             	mov    0x8(%ebp),%eax
  103da7:	8b 40 10             	mov    0x10(%eax),%eax
  103daa:	89 44 24 04          	mov    %eax,0x4(%esp)
  103dae:	c7 04 24 c0 97 10 00 	movl   $0x1097c0,(%esp)
  103db5:	e8 d7 41 00 00       	call   107f91 <cprintf>

	trap_return(tf);	// syscall completed
  103dba:	8b 45 08             	mov    0x8(%ebp),%eax
  103dbd:	89 04 24             	mov    %eax,(%esp)
  103dc0:	e8 2b 83 00 00       	call   10c0f0 <trap_return>

00103dc5 <do_put>:
}


static void
do_put(trapframe *tf, uint32_t cmd)
{	
  103dc5:	55                   	push   %ebp
  103dc6:	89 e5                	mov    %esp,%ebp
  103dc8:	83 ec 28             	sub    $0x28,%esp
	cprintf("process %p is in do_put()\n", proc_cur());
  103dcb:	e8 da fe ff ff       	call   103caa <cpu_cur>
  103dd0:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103dd6:	89 44 24 04          	mov    %eax,0x4(%esp)
  103dda:	c7 04 24 c3 97 10 00 	movl   $0x1097c3,(%esp)
  103de1:	e8 ab 41 00 00       	call   107f91 <cprintf>
	
	procstate* ps = (procstate*)tf->regs.ebx;
  103de6:	8b 45 08             	mov    0x8(%ebp),%eax
  103de9:	8b 40 10             	mov    0x10(%eax),%eax
  103dec:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint16_t child_num = tf->regs.edx;
  103def:	8b 45 08             	mov    0x8(%ebp),%eax
  103df2:	8b 40 14             	mov    0x14(%eax),%eax
  103df5:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
	proc* proc_parent = proc_cur();
  103df9:	e8 ac fe ff ff       	call   103caa <cpu_cur>
  103dfe:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103e04:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103e07:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
  103e0b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103e0e:	83 c2 10             	add    $0x10,%edx
  103e11:	8b 04 90             	mov    (%eax,%edx,4),%eax
  103e14:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(proc_child == NULL){
  103e17:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103e1b:	75 38                	jne    103e55 <do_put+0x90>
		proc_child = proc_alloc(proc_parent, child_num);
  103e1d:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
  103e21:	89 44 24 04          	mov    %eax,0x4(%esp)
  103e25:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103e28:	89 04 24             	mov    %eax,(%esp)
  103e2b:	e8 a0 f0 ff ff       	call   102ed0 <proc_alloc>
  103e30:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if(proc_child == NULL)
  103e33:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103e37:	75 1c                	jne    103e55 <do_put+0x90>
			panic("no child proc!");
  103e39:	c7 44 24 08 de 97 10 	movl   $0x1097de,0x8(%esp)
  103e40:	00 
  103e41:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
  103e48:	00 
  103e49:	c7 04 24 53 97 10 00 	movl   $0x109753,(%esp)
  103e50:	e8 d9 c9 ff ff       	call   10082e <debug_panic>
	}
	
	//proc_print(ACQUIRE, proc_child);
	spinlock_acquire(&proc_child->lock);
  103e55:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e58:	89 04 24             	mov    %eax,(%esp)
  103e5b:	e8 a3 e8 ff ff       	call   102703 <spinlock_acquire>
	if(proc_child->state != PROC_STOP){
  103e60:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e63:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103e69:	85 c0                	test   %eax,%eax
  103e6b:	74 24                	je     103e91 <do_put+0xcc>
		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  103e6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e70:	89 04 24             	mov    %eax,(%esp)
  103e73:	e8 f8 e8 ff ff       	call   102770 <spinlock_release>
		proc_wait(proc_parent, proc_child, tf);
  103e78:	8b 45 08             	mov    0x8(%ebp),%eax
  103e7b:	89 44 24 08          	mov    %eax,0x8(%esp)
  103e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e82:	89 44 24 04          	mov    %eax,0x4(%esp)
  103e86:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103e89:	89 04 24             	mov    %eax,(%esp)
  103e8c:	e8 dc f3 ff ff       	call   10326d <proc_wait>
	}

	//proc_print(RELEASE, proc_child);
	spinlock_release(&proc_child->lock);
  103e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e94:	89 04 24             	mov    %eax,(%esp)
  103e97:	e8 d4 e8 ff ff       	call   102770 <spinlock_release>

	if(tf->regs.eax & SYS_REGS){	
  103e9c:	8b 45 08             	mov    0x8(%ebp),%eax
  103e9f:	8b 40 1c             	mov    0x1c(%eax),%eax
  103ea2:	25 00 10 00 00       	and    $0x1000,%eax
  103ea7:	85 c0                	test   %eax,%eax
  103ea9:	0f 84 c4 00 00 00    	je     103f73 <do_put+0x1ae>
		//proc_print(ACQUIRE, proc_child);
		spinlock_acquire(&proc_child->lock);
  103eaf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103eb2:	89 04 24             	mov    %eax,(%esp)
  103eb5:	e8 49 e8 ff ff       	call   102703 <spinlock_acquire>
		/*
		if(((proc_child->sv.tf.eflags ^ ps->tf.eflags) | FL_USER) != FL_USER)
			panic("illegal modification of eflags!");
		*/
		
		proc_child->sv.tf.eip = ps->tf.eip;
  103eba:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103ebd:	8b 50 38             	mov    0x38(%eax),%edx
  103ec0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ec3:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_child->sv.tf.esp = ps->tf.esp;
  103ec9:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103ecc:	8b 50 44             	mov    0x44(%eax),%edx
  103ecf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ed2:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
  103ed8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103edb:	8b 50 08             	mov    0x8(%eax),%edx
  103ede:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103ee1:	89 90 58 04 00 00    	mov    %edx,0x458(%eax)
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
  103ee7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103eea:	8b 40 44             	mov    0x44(%eax),%eax
  103eed:	89 44 24 04          	mov    %eax,0x4(%esp)
  103ef1:	c7 04 24 f0 97 10 00 	movl   $0x1097f0,(%esp)
  103ef8:	e8 94 40 00 00       	call   107f91 <cprintf>
		proc_child->sv.tf.trapno = ps->tf.trapno;
  103efd:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103f00:	8b 50 30             	mov    0x30(%eax),%edx
  103f03:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f06:	89 90 80 04 00 00    	mov    %edx,0x480(%eax)

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
  103f0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f0f:	0f b7 80 8c 04 00 00 	movzwl 0x48c(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103f16:	66 83 f8 1b          	cmp    $0x1b,%ax
  103f1a:	75 30                	jne    103f4c <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
  103f1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f1f:	0f b7 80 7c 04 00 00 	movzwl 0x47c(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103f26:	66 83 f8 23          	cmp    $0x23,%ax
  103f2a:	75 20                	jne    103f4c <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103f2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f2f:	0f b7 80 78 04 00 00 	movzwl 0x478(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103f36:	66 83 f8 23          	cmp    $0x23,%ax
  103f3a:	75 10                	jne    103f4c <do_put+0x187>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
  103f3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f3f:	0f b7 80 98 04 00 00 	movzwl 0x498(%eax),%eax
		proc_child->sv.tf.esp = ps->tf.esp;
		proc_child->sv.tf.regs.ebp=  ps->tf.regs.ebp;
		cprintf(">>>>>>>>>>in do_put : esp : 0x%x\n",ps->tf.esp);
		proc_child->sv.tf.trapno = ps->tf.trapno;

		if(proc_child->sv.tf.cs != (CPU_GDT_UCODE | 3)
  103f46:	66 83 f8 23          	cmp    $0x23,%ax
  103f4a:	74 1c                	je     103f68 <do_put+0x1a3>
			|| proc_child->sv.tf.ds != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.es != (CPU_GDT_UDATA | 3)
			|| proc_child->sv.tf.ss != (CPU_GDT_UDATA | 3))
			panic("wrong segment regs values!");
  103f4c:	c7 44 24 08 12 98 10 	movl   $0x109812,0x8(%esp)
  103f53:	00 
  103f54:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  103f5b:	00 
  103f5c:	c7 04 24 53 97 10 00 	movl   $0x109753,(%esp)
  103f63:	e8 c6 c8 ff ff       	call   10082e <debug_panic>

		//proc_print(RELEASE, proc_child);
		spinlock_release(&proc_child->lock);
  103f68:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f6b:	89 04 24             	mov    %eax,(%esp)
  103f6e:	e8 fd e7 ff ff       	call   102770 <spinlock_release>
	}
    if(tf->regs.eax & SYS_START){
  103f73:	8b 45 08             	mov    0x8(%ebp),%eax
  103f76:	8b 40 1c             	mov    0x1c(%eax),%eax
  103f79:	83 e0 10             	and    $0x10,%eax
  103f7c:	85 c0                	test   %eax,%eax
  103f7e:	74 0b                	je     103f8b <do_put+0x1c6>
		//cprintf("in SYS_START\n");
		proc_ready(proc_child);
  103f80:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f83:	89 04 24             	mov    %eax,(%esp)
  103f86:	e8 3b f1 ff ff       	call   1030c6 <proc_ready>
	}
	
	trap_return(tf);
  103f8b:	8b 45 08             	mov    0x8(%ebp),%eax
  103f8e:	89 04 24             	mov    %eax,(%esp)
  103f91:	e8 5a 81 00 00       	call   10c0f0 <trap_return>

00103f96 <do_get>:
}

static void
do_get(trapframe *tf, uint32_t cmd)
{	
  103f96:	55                   	push   %ebp
  103f97:	89 e5                	mov    %esp,%ebp
  103f99:	83 ec 28             	sub    $0x28,%esp
	cprintf("process %p is in do_get()\n", proc_cur());
  103f9c:	e8 09 fd ff ff       	call   103caa <cpu_cur>
  103fa1:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103fa7:	89 44 24 04          	mov    %eax,0x4(%esp)
  103fab:	c7 04 24 2d 98 10 00 	movl   $0x10982d,(%esp)
  103fb2:	e8 da 3f 00 00       	call   107f91 <cprintf>
	
	procstate* ps = (procstate*)tf->regs.ebx;
  103fb7:	8b 45 08             	mov    0x8(%ebp),%eax
  103fba:	8b 40 10             	mov    0x10(%eax),%eax
  103fbd:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int child_num = (int)tf->regs.edx;
  103fc0:	8b 45 08             	mov    0x8(%ebp),%eax
  103fc3:	8b 40 14             	mov    0x14(%eax),%eax
  103fc6:	89 45 ec             	mov    %eax,-0x14(%ebp)
	proc* proc_parent = proc_cur();
  103fc9:	e8 dc fc ff ff       	call   103caa <cpu_cur>
  103fce:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103fd4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* proc_child = proc_parent->child[child_num];
  103fd7:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103fda:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103fdd:	83 c2 10             	add    $0x10,%edx
  103fe0:	8b 04 90             	mov    (%eax,%edx,4),%eax
  103fe3:	89 45 f4             	mov    %eax,-0xc(%ebp)

	assert(proc_child != NULL);
  103fe6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103fea:	75 24                	jne    104010 <do_get+0x7a>
  103fec:	c7 44 24 0c 48 98 10 	movl   $0x109848,0xc(%esp)
  103ff3:	00 
  103ff4:	c7 44 24 08 16 97 10 	movl   $0x109716,0x8(%esp)
  103ffb:	00 
  103ffc:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  104003:	00 
  104004:	c7 04 24 53 97 10 00 	movl   $0x109753,(%esp)
  10400b:	e8 1e c8 ff ff       	call   10082e <debug_panic>

	if(proc_child->state != PROC_STOP){
  104010:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104013:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  104019:	85 c0                	test   %eax,%eax
  10401b:	74 25                	je     104042 <do_get+0xac>
		cprintf("into proc_wait\n");
  10401d:	c7 04 24 5b 98 10 00 	movl   $0x10985b,(%esp)
  104024:	e8 68 3f 00 00       	call   107f91 <cprintf>
		proc_wait(proc_parent, proc_child, tf);}
  104029:	8b 45 08             	mov    0x8(%ebp),%eax
  10402c:	89 44 24 08          	mov    %eax,0x8(%esp)
  104030:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104033:	89 44 24 04          	mov    %eax,0x4(%esp)
  104037:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10403a:	89 04 24             	mov    %eax,(%esp)
  10403d:	e8 2b f2 ff ff       	call   10326d <proc_wait>

	if(tf->regs.eax & SYS_REGS){
  104042:	8b 45 08             	mov    0x8(%ebp),%eax
  104045:	8b 40 1c             	mov    0x1c(%eax),%eax
  104048:	25 00 10 00 00       	and    $0x1000,%eax
  10404d:	85 c0                	test   %eax,%eax
  10404f:	74 20                	je     104071 <do_get+0xdb>
		memmove(&(ps->tf), &(proc_child->sv.tf), sizeof(trapframe));
  104051:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104054:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  10405a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10405d:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  104064:	00 
  104065:	89 54 24 04          	mov    %edx,0x4(%esp)
  104069:	89 04 24             	mov    %eax,(%esp)
  10406c:	e8 79 41 00 00       	call   1081ea <memmove>
	}
	
	trap_return(tf);
  104071:	8b 45 08             	mov    0x8(%ebp),%eax
  104074:	89 04 24             	mov    %eax,(%esp)
  104077:	e8 74 80 00 00       	call   10c0f0 <trap_return>

0010407c <do_ret>:
}

static void
do_ret(trapframe *tf, uint32_t cmd)
{	
  10407c:	55                   	push   %ebp
  10407d:	89 e5                	mov    %esp,%ebp
  10407f:	83 ec 18             	sub    $0x18,%esp
	cprintf("process %p is in do_ret()\n", proc_cur());
  104082:	e8 23 fc ff ff       	call   103caa <cpu_cur>
  104087:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10408d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104091:	c7 04 24 6b 98 10 00 	movl   $0x10986b,(%esp)
  104098:	e8 f4 3e 00 00       	call   107f91 <cprintf>
	proc_ret(tf, 1);
  10409d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1040a4:	00 
  1040a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1040a8:	89 04 24             	mov    %eax,(%esp)
  1040ab:	e8 81 f4 ff ff       	call   103531 <proc_ret>

001040b0 <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  1040b0:	55                   	push   %ebp
  1040b1:	89 e5                	mov    %esp,%ebp
  1040b3:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  1040b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1040b9:	8b 40 1c             	mov    0x1c(%eax),%eax
  1040bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  1040bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1040c2:	83 e0 0f             	and    $0xf,%eax
  1040c5:	83 f8 01             	cmp    $0x1,%eax
  1040c8:	74 25                	je     1040ef <syscall+0x3f>
  1040ca:	83 f8 01             	cmp    $0x1,%eax
  1040cd:	72 0c                	jb     1040db <syscall+0x2b>
  1040cf:	83 f8 02             	cmp    $0x2,%eax
  1040d2:	74 2f                	je     104103 <syscall+0x53>
  1040d4:	83 f8 03             	cmp    $0x3,%eax
  1040d7:	74 3e                	je     104117 <syscall+0x67>
	case SYS_PUT:	 do_put(tf, cmd); break;
	case SYS_GET:	 do_get(tf, cmd); break;
	case SYS_RET:	 do_ret(tf, cmd); break;
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
  1040d9:	eb 4f                	jmp    10412a <syscall+0x7a>
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:	 do_cputs(tf, cmd); break;
  1040db:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1040de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1040e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1040e5:	89 04 24             	mov    %eax,(%esp)
  1040e8:	e8 b1 fc ff ff       	call   103d9e <do_cputs>
  1040ed:	eb 3b                	jmp    10412a <syscall+0x7a>
	case SYS_PUT:	 do_put(tf, cmd); break;
  1040ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1040f2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1040f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1040f9:	89 04 24             	mov    %eax,(%esp)
  1040fc:	e8 c4 fc ff ff       	call   103dc5 <do_put>
  104101:	eb 27                	jmp    10412a <syscall+0x7a>
	case SYS_GET:	 do_get(tf, cmd); break;
  104103:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104106:	89 44 24 04          	mov    %eax,0x4(%esp)
  10410a:	8b 45 08             	mov    0x8(%ebp),%eax
  10410d:	89 04 24             	mov    %eax,(%esp)
  104110:	e8 81 fe ff ff       	call   103f96 <do_get>
  104115:	eb 13                	jmp    10412a <syscall+0x7a>
	case SYS_RET:	 do_ret(tf, cmd); break;
  104117:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10411a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10411e:	8b 45 08             	mov    0x8(%ebp),%eax
  104121:	89 04 24             	mov    %eax,(%esp)
  104124:	e8 53 ff ff ff       	call   10407c <do_ret>
  104129:	90                   	nop
	
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
	}
}
  10412a:	c9                   	leave  
  10412b:	c3                   	ret    

0010412c <lockadd>:
}

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  10412c:	55                   	push   %ebp
  10412d:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  10412f:	8b 45 08             	mov    0x8(%ebp),%eax
  104132:	8b 55 0c             	mov    0xc(%ebp),%edx
  104135:	8b 4d 08             	mov    0x8(%ebp),%ecx
  104138:	f0 01 10             	lock add %edx,(%eax)
}
  10413b:	5d                   	pop    %ebp
  10413c:	c3                   	ret    

0010413d <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  10413d:	55                   	push   %ebp
  10413e:	89 e5                	mov    %esp,%ebp
  104140:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  104143:	8b 45 08             	mov    0x8(%ebp),%eax
  104146:	8b 55 0c             	mov    0xc(%ebp),%edx
  104149:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10414c:	f0 01 10             	lock add %edx,(%eax)
  10414f:	0f 94 45 ff          	sete   -0x1(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  104153:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
  104157:	c9                   	leave  
  104158:	c3                   	ret    

00104159 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  104159:	55                   	push   %ebp
  10415a:	89 e5                	mov    %esp,%ebp
  10415c:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10415f:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  104162:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  104165:	89 45 f0             	mov    %eax,-0x10(%ebp)
  104168:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10416b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104170:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  104173:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104176:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10417c:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  104181:	74 24                	je     1041a7 <cpu_cur+0x4e>
  104183:	c7 44 24 0c 88 98 10 	movl   $0x109888,0xc(%esp)
  10418a:	00 
  10418b:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104192:	00 
  104193:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10419a:	00 
  10419b:	c7 04 24 b3 98 10 00 	movl   $0x1098b3,(%esp)
  1041a2:	e8 87 c6 ff ff       	call   10082e <debug_panic>
	return c;
  1041a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1041aa:	c9                   	leave  
  1041ab:	c3                   	ret    

001041ac <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1041ac:	55                   	push   %ebp
  1041ad:	89 e5                	mov    %esp,%ebp
  1041af:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1041b2:	e8 a2 ff ff ff       	call   104159 <cpu_cur>
  1041b7:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  1041bc:	0f 94 c0             	sete   %al
  1041bf:	0f b6 c0             	movzbl %al,%eax
}
  1041c2:	c9                   	leave  
  1041c3:	c3                   	ret    

001041c4 <pmap_init>:
// (addresses outside of the range between VM_USERLO and VM_USERHI).
// The user part of the address space remains all PTE_ZERO until later.
//
void
pmap_init(void)
{
  1041c4:	55                   	push   %ebp
  1041c5:	89 e5                	mov    %esp,%ebp
  1041c7:	83 ec 48             	sub    $0x48,%esp
	if (cpu_onboot()) {
  1041ca:	e8 dd ff ff ff       	call   1041ac <cpu_onboot>
  1041cf:	85 c0                	test   %eax,%eax
  1041d1:	74 5a                	je     10422d <pmap_init+0x69>

		
		uint32_t va;
		int i;

		for(i = 0, va = 0; i < 1024; i++, va += PTSIZE){
  1041d3:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  1041da:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  1041e1:	eb 41                	jmp    104224 <pmap_init+0x60>
			if(va >= VM_USERLO && va < VM_USERHI){
  1041e3:	81 7d dc ff ff ff 3f 	cmpl   $0x3fffffff,-0x24(%ebp)
  1041ea:	76 1a                	jbe    104206 <pmap_init+0x42>
  1041ec:	81 7d dc ff ff ff ef 	cmpl   $0xefffffff,-0x24(%ebp)
  1041f3:	77 11                	ja     104206 <pmap_init+0x42>
				pmap_bootpdir[i] = PTE_ZERO;
  1041f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1041f8:	ba 00 10 32 00       	mov    $0x321000,%edx
  1041fd:	89 14 85 00 00 32 00 	mov    %edx,0x320000(,%eax,4)
		
		uint32_t va;
		int i;

		for(i = 0, va = 0; i < 1024; i++, va += PTSIZE){
			if(va >= VM_USERLO && va < VM_USERHI){
  104204:	eb 13                	jmp    104219 <pmap_init+0x55>
				pmap_bootpdir[i] = PTE_ZERO;
				//cprintf("pmap_bootpdir[%d] = %x\n", i, pmap_bootpdir[i]);
			}
			else{
				pmap_bootpdir[i] = va | PTE_P | PTE_W | PTE_PS | PTE_G;
  104206:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104209:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10420c:	81 ca 83 01 00 00    	or     $0x183,%edx
  104212:	89 14 85 00 00 32 00 	mov    %edx,0x320000(,%eax,4)

		
		uint32_t va;
		int i;

		for(i = 0, va = 0; i < 1024; i++, va += PTSIZE){
  104219:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  10421d:	81 45 dc 00 00 40 00 	addl   $0x400000,-0x24(%ebp)
  104224:	81 7d e0 ff 03 00 00 	cmpl   $0x3ff,-0x20(%ebp)
  10422b:	7e b6                	jle    1041e3 <pmap_init+0x1f>

static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
  10422d:	0f 20 e0             	mov    %cr4,%eax
  104230:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	return cr4;
  104233:	8b 45 e4             	mov    -0x1c(%ebp),%eax
	// where LA == PA according to the page mapping structures.
	// In PIOS this is always the case for the kernel's address space,
	// so we don't have to play any special tricks as in other kernels.

	// Enable 4MB pages and global pages.
	uint32_t cr4 = rcr4();
  104236:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	cr4 |= CR4_PSE | CR4_PGE;
  104239:	81 4d d4 90 00 00 00 	orl    $0x90,-0x2c(%ebp)
  104240:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104243:	89 45 e8             	mov    %eax,-0x18(%ebp)
}

static gcc_inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
  104246:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104249:	0f 22 e0             	mov    %eax,%cr4
	lcr4(cr4);

	// Install the bootstrap page directory into the PDBR.
	lcr3(mem_phys(pmap_bootpdir));
  10424c:	b8 00 00 32 00       	mov    $0x320000,%eax
  104251:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  104254:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104257:	0f 22 d8             	mov    %eax,%cr3

static gcc_inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
  10425a:	0f 20 c0             	mov    %cr0,%eax
  10425d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return val;
  104260:	8b 45 f0             	mov    -0x10(%ebp),%eax

	// Turn on paging.
	uint32_t cr0 = rcr0();
  104263:	89 45 d8             	mov    %eax,-0x28(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_MP|CR0_TS;
  104266:	81 4d d8 2b 00 05 80 	orl    $0x8005002b,-0x28(%ebp)
	cr0 &= ~(CR0_EM);
  10426d:	83 65 d8 fb          	andl   $0xfffffffb,-0x28(%ebp)

	cprintf("before lcr0\n");
  104271:	c7 04 24 c0 98 10 00 	movl   $0x1098c0,(%esp)
  104278:	e8 14 3d 00 00       	call   107f91 <cprintf>
  10427d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104280:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
  104283:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104286:	0f 22 c0             	mov    %eax,%cr0
	lcr0(cr0);
	cprintf("after lcr0\n");
  104289:	c7 04 24 cd 98 10 00 	movl   $0x1098cd,(%esp)
  104290:	e8 fc 3c 00 00       	call   107f91 <cprintf>

	// If we survived the lcr0, we're running with paging enabled.
	// Now check the page table management functions below.
	if (cpu_onboot()){
  104295:	e8 12 ff ff ff       	call   1041ac <cpu_onboot>
  10429a:	85 c0                	test   %eax,%eax
  10429c:	74 05                	je     1042a3 <pmap_init+0xdf>
		pmap_check();
  10429e:	e8 1d 10 00 00       	call   1052c0 <pmap_check>
	}
}
  1042a3:	c9                   	leave  
  1042a4:	c3                   	ret    

001042a5 <pmap_newpdir>:
// Allocate a new page directory, initialized from the bootstrap pdir.
// Returns the new pdir with a reference count of 1.
//
pte_t *
pmap_newpdir(void)
{
  1042a5:	55                   	push   %ebp
  1042a6:	89 e5                	mov    %esp,%ebp
  1042a8:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  1042ab:	e8 0a cc ff ff       	call   100eba <mem_alloc>
  1042b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (pi == NULL)
  1042b3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1042b7:	75 0a                	jne    1042c3 <pmap_newpdir+0x1e>
		return NULL;
  1042b9:	b8 00 00 00 00       	mov    $0x0,%eax
  1042be:	e9 24 01 00 00       	jmp    1043e7 <pmap_newpdir+0x142>
  1042c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1042c6:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1042c9:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1042ce:	83 c0 08             	add    $0x8,%eax
  1042d1:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1042d4:	76 15                	jbe    1042eb <pmap_newpdir+0x46>
  1042d6:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1042db:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  1042e1:	c1 e2 03             	shl    $0x3,%edx
  1042e4:	01 d0                	add    %edx,%eax
  1042e6:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1042e9:	72 24                	jb     10430f <pmap_newpdir+0x6a>
  1042eb:	c7 44 24 0c dc 98 10 	movl   $0x1098dc,0xc(%esp)
  1042f2:	00 
  1042f3:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1042fa:	00 
  1042fb:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  104302:	00 
  104303:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  10430a:	e8 1f c5 ff ff       	call   10082e <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10430f:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104314:	ba 00 10 32 00       	mov    $0x321000,%edx
  104319:	c1 ea 0c             	shr    $0xc,%edx
  10431c:	c1 e2 03             	shl    $0x3,%edx
  10431f:	01 d0                	add    %edx,%eax
  104321:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104324:	75 24                	jne    10434a <pmap_newpdir+0xa5>
  104326:	c7 44 24 0c 20 99 10 	movl   $0x109920,0xc(%esp)
  10432d:	00 
  10432e:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104335:	00 
  104336:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  10433d:	00 
  10433e:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104345:	e8 e4 c4 ff ff       	call   10082e <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10434a:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10434f:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104354:	c1 ea 0c             	shr    $0xc,%edx
  104357:	c1 e2 03             	shl    $0x3,%edx
  10435a:	01 d0                	add    %edx,%eax
  10435c:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10435f:	72 3b                	jb     10439c <pmap_newpdir+0xf7>
  104361:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104366:	ba 07 20 32 00       	mov    $0x322007,%edx
  10436b:	c1 ea 0c             	shr    $0xc,%edx
  10436e:	c1 e2 03             	shl    $0x3,%edx
  104371:	01 d0                	add    %edx,%eax
  104373:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104376:	77 24                	ja     10439c <pmap_newpdir+0xf7>
  104378:	c7 44 24 0c 3c 99 10 	movl   $0x10993c,0xc(%esp)
  10437f:	00 
  104380:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104387:	00 
  104388:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  10438f:	00 
  104390:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104397:	e8 92 c4 ff ff       	call   10082e <debug_panic>

	lockadd(&pi->refcount, 1);
  10439c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10439f:	83 c0 04             	add    $0x4,%eax
  1043a2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1043a9:	00 
  1043aa:	89 04 24             	mov    %eax,(%esp)
  1043ad:	e8 7a fd ff ff       	call   10412c <lockadd>
	mem_incref(pi);
	pte_t *pdir = mem_pi2ptr(pi);
  1043b2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1043b5:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1043ba:	89 d1                	mov    %edx,%ecx
  1043bc:	29 c1                	sub    %eax,%ecx
  1043be:	89 c8                	mov    %ecx,%eax
  1043c0:	c1 f8 03             	sar    $0x3,%eax
  1043c3:	c1 e0 0c             	shl    $0xc,%eax
  1043c6:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Initialize it from the bootstrap page directory
	assert(sizeof(pmap_bootpdir) == PAGESIZE);
	memmove(pdir, pmap_bootpdir, PAGESIZE);
  1043c9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1043d0:	00 
  1043d1:	c7 44 24 04 00 00 32 	movl   $0x320000,0x4(%esp)
  1043d8:	00 
  1043d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1043dc:	89 04 24             	mov    %eax,(%esp)
  1043df:	e8 06 3e 00 00       	call   1081ea <memmove>

	return pdir;
  1043e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1043e7:	c9                   	leave  
  1043e8:	c3                   	ret    

001043e9 <pmap_freepdir>:

// Free a page directory, and all page tables and mappings it may contain.
void
pmap_freepdir(pageinfo *pdirpi)
{
  1043e9:	55                   	push   %ebp
  1043ea:	89 e5                	mov    %esp,%ebp
  1043ec:	83 ec 18             	sub    $0x18,%esp
	pmap_remove(mem_pi2ptr(pdirpi), VM_USERLO, VM_USERHI-VM_USERLO);
  1043ef:	8b 55 08             	mov    0x8(%ebp),%edx
  1043f2:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1043f7:	89 d1                	mov    %edx,%ecx
  1043f9:	29 c1                	sub    %eax,%ecx
  1043fb:	89 c8                	mov    %ecx,%eax
  1043fd:	c1 f8 03             	sar    $0x3,%eax
  104400:	c1 e0 0c             	shl    $0xc,%eax
  104403:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  10440a:	b0 
  10440b:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  104412:	40 
  104413:	89 04 24             	mov    %eax,(%esp)
  104416:	e8 69 05 00 00       	call   104984 <pmap_remove>
	mem_free(pdirpi);
  10441b:	8b 45 08             	mov    0x8(%ebp),%eax
  10441e:	89 04 24             	mov    %eax,(%esp)
  104421:	e8 db ca ff ff       	call   100f01 <mem_free>
}
  104426:	c9                   	leave  
  104427:	c3                   	ret    

00104428 <pmap_freeptab>:

// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
  104428:	55                   	push   %ebp
  104429:	89 e5                	mov    %esp,%ebp
  10442b:	83 ec 38             	sub    $0x38,%esp
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
  10442e:	8b 55 08             	mov    0x8(%ebp),%edx
  104431:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104436:	89 d1                	mov    %edx,%ecx
  104438:	29 c1                	sub    %eax,%ecx
  10443a:	89 c8                	mov    %ecx,%eax
  10443c:	c1 f8 03             	sar    $0x3,%eax
  10443f:	c1 e0 0c             	shl    $0xc,%eax
  104442:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  104445:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104448:	05 00 10 00 00       	add    $0x1000,%eax
  10444d:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (; pte < ptelim; pte++) {
  104450:	e9 5f 01 00 00       	jmp    1045b4 <pmap_freeptab+0x18c>
		uint32_t pgaddr = PGADDR(*pte);
  104455:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104458:	8b 00                	mov    (%eax),%eax
  10445a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10445f:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (pgaddr != PTE_ZERO)
  104462:	b8 00 10 32 00       	mov    $0x321000,%eax
  104467:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  10446a:	0f 84 40 01 00 00    	je     1045b0 <pmap_freeptab+0x188>
			mem_decref(mem_phys2pi(pgaddr), mem_free);
  104470:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104475:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104478:	c1 ea 0c             	shr    $0xc,%edx
  10447b:	c1 e2 03             	shl    $0x3,%edx
  10447e:	01 d0                	add    %edx,%eax
  104480:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104483:	c7 45 f0 01 0f 10 00 	movl   $0x100f01,-0x10(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10448a:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10448f:	83 c0 08             	add    $0x8,%eax
  104492:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104495:	76 15                	jbe    1044ac <pmap_freeptab+0x84>
  104497:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10449c:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  1044a2:	c1 e2 03             	shl    $0x3,%edx
  1044a5:	01 d0                	add    %edx,%eax
  1044a7:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1044aa:	72 24                	jb     1044d0 <pmap_freeptab+0xa8>
  1044ac:	c7 44 24 0c dc 98 10 	movl   $0x1098dc,0xc(%esp)
  1044b3:	00 
  1044b4:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1044bb:	00 
  1044bc:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1044c3:	00 
  1044c4:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  1044cb:	e8 5e c3 ff ff       	call   10082e <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1044d0:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1044d5:	ba 00 10 32 00       	mov    $0x321000,%edx
  1044da:	c1 ea 0c             	shr    $0xc,%edx
  1044dd:	c1 e2 03             	shl    $0x3,%edx
  1044e0:	01 d0                	add    %edx,%eax
  1044e2:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1044e5:	75 24                	jne    10450b <pmap_freeptab+0xe3>
  1044e7:	c7 44 24 0c 20 99 10 	movl   $0x109920,0xc(%esp)
  1044ee:	00 
  1044ef:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1044f6:	00 
  1044f7:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1044fe:	00 
  1044ff:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104506:	e8 23 c3 ff ff       	call   10082e <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10450b:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104510:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104515:	c1 ea 0c             	shr    $0xc,%edx
  104518:	c1 e2 03             	shl    $0x3,%edx
  10451b:	01 d0                	add    %edx,%eax
  10451d:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104520:	72 3b                	jb     10455d <pmap_freeptab+0x135>
  104522:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104527:	ba 07 20 32 00       	mov    $0x322007,%edx
  10452c:	c1 ea 0c             	shr    $0xc,%edx
  10452f:	c1 e2 03             	shl    $0x3,%edx
  104532:	01 d0                	add    %edx,%eax
  104534:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104537:	77 24                	ja     10455d <pmap_freeptab+0x135>
  104539:	c7 44 24 0c 3c 99 10 	movl   $0x10993c,0xc(%esp)
  104540:	00 
  104541:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104548:	00 
  104549:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  104550:	00 
  104551:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104558:	e8 d1 c2 ff ff       	call   10082e <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10455d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104560:	83 c0 04             	add    $0x4,%eax
  104563:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  10456a:	ff 
  10456b:	89 04 24             	mov    %eax,(%esp)
  10456e:	e8 ca fb ff ff       	call   10413d <lockaddz>
  104573:	84 c0                	test   %al,%al
  104575:	74 0b                	je     104582 <pmap_freeptab+0x15a>
			freefun(pi);
  104577:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10457a:	89 04 24             	mov    %eax,(%esp)
  10457d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104580:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  104582:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104585:	8b 40 04             	mov    0x4(%eax),%eax
  104588:	85 c0                	test   %eax,%eax
  10458a:	79 24                	jns    1045b0 <pmap_freeptab+0x188>
  10458c:	c7 44 24 0c 6d 99 10 	movl   $0x10996d,0xc(%esp)
  104593:	00 
  104594:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10459b:	00 
  10459c:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1045a3:	00 
  1045a4:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  1045ab:	e8 7e c2 ff ff       	call   10082e <debug_panic>
// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
	for (; pte < ptelim; pte++) {
  1045b0:	83 45 e4 04          	addl   $0x4,-0x1c(%ebp)
  1045b4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1045b7:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1045ba:	0f 82 95 fe ff ff    	jb     104455 <pmap_freeptab+0x2d>
		uint32_t pgaddr = PGADDR(*pte);
		if (pgaddr != PTE_ZERO)
			mem_decref(mem_phys2pi(pgaddr), mem_free);
	}
	mem_free(ptabpi);
  1045c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1045c3:	89 04 24             	mov    %eax,(%esp)
  1045c6:	e8 36 c9 ff ff       	call   100f01 <mem_free>
}
  1045cb:	c9                   	leave  
  1045cc:	c3                   	ret    

001045cd <pmap_walk>:
// Hint 2: the x86 MMU checks permission bits in both the page directory
// and the page table, so it's safe to leave some page permissions
// more permissive than strictly necessary.
pte_t *
pmap_walk(pde_t *pdir, uint32_t va, bool writing)
{
  1045cd:	55                   	push   %ebp
  1045ce:	89 e5                	mov    %esp,%ebp
  1045d0:	83 ec 38             	sub    $0x38,%esp
	assert(va >= VM_USERLO && va < VM_USERHI);
  1045d3:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1045da:	76 09                	jbe    1045e5 <pmap_walk+0x18>
  1045dc:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1045e3:	76 24                	jbe    104609 <pmap_walk+0x3c>
  1045e5:	c7 44 24 0c 80 99 10 	movl   $0x109980,0xc(%esp)
  1045ec:	00 
  1045ed:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1045f4:	00 
  1045f5:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  1045fc:	00 
  1045fd:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104604:	e8 25 c2 ff ff       	call   10082e <debug_panic>
	// Fill in this function

	pde_t* pde;
	pte_t* pte;

	pde = &pdir[PDX(va)];
  104609:	8b 45 0c             	mov    0xc(%ebp),%eax
  10460c:	c1 e8 16             	shr    $0x16,%eax
  10460f:	c1 e0 02             	shl    $0x2,%eax
  104612:	03 45 08             	add    0x8(%ebp),%eax
  104615:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	if(*pde == PTE_ZERO){
  104618:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10461b:	8b 10                	mov    (%eax),%edx
  10461d:	b8 00 10 32 00       	mov    $0x321000,%eax
  104622:	39 c2                	cmp    %eax,%edx
  104624:	0f 85 7e 01 00 00    	jne    1047a8 <pmap_walk+0x1db>
		if(writing == 0)
  10462a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10462e:	75 0a                	jne    10463a <pmap_walk+0x6d>
			return NULL;
  104630:	b8 00 00 00 00       	mov    $0x0,%eax
  104635:	e9 8c 01 00 00       	jmp    1047c6 <pmap_walk+0x1f9>
		else{
			pageinfo* pi = mem_alloc();
  10463a:	e8 7b c8 ff ff       	call   100eba <mem_alloc>
  10463f:	89 45 ec             	mov    %eax,-0x14(%ebp)
			
			if(pi== NULL){
  104642:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  104646:	75 0a                	jne    104652 <pmap_walk+0x85>
				return NULL;}
  104648:	b8 00 00 00 00       	mov    $0x0,%eax
  10464d:	e9 74 01 00 00       	jmp    1047c6 <pmap_walk+0x1f9>
			
			memset(pi, 0 ,sizeof(PAGESIZE));
  104652:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  104659:	00 
  10465a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104661:	00 
  104662:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104665:	89 04 24             	mov    %eax,(%esp)
  104668:	e8 09 3b 00 00       	call   108176 <memset>
  10466d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104670:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104673:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104678:	83 c0 08             	add    $0x8,%eax
  10467b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10467e:	76 15                	jbe    104695 <pmap_walk+0xc8>
  104680:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104685:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  10468b:	c1 e2 03             	shl    $0x3,%edx
  10468e:	01 d0                	add    %edx,%eax
  104690:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104693:	72 24                	jb     1046b9 <pmap_walk+0xec>
  104695:	c7 44 24 0c dc 98 10 	movl   $0x1098dc,0xc(%esp)
  10469c:	00 
  10469d:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1046a4:	00 
  1046a5:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1046ac:	00 
  1046ad:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  1046b4:	e8 75 c1 ff ff       	call   10082e <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1046b9:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1046be:	ba 00 10 32 00       	mov    $0x321000,%edx
  1046c3:	c1 ea 0c             	shr    $0xc,%edx
  1046c6:	c1 e2 03             	shl    $0x3,%edx
  1046c9:	01 d0                	add    %edx,%eax
  1046cb:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1046ce:	75 24                	jne    1046f4 <pmap_walk+0x127>
  1046d0:	c7 44 24 0c 20 99 10 	movl   $0x109920,0xc(%esp)
  1046d7:	00 
  1046d8:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1046df:	00 
  1046e0:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  1046e7:	00 
  1046e8:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  1046ef:	e8 3a c1 ff ff       	call   10082e <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1046f4:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1046f9:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  1046fe:	c1 ea 0c             	shr    $0xc,%edx
  104701:	c1 e2 03             	shl    $0x3,%edx
  104704:	01 d0                	add    %edx,%eax
  104706:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104709:	72 3b                	jb     104746 <pmap_walk+0x179>
  10470b:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104710:	ba 07 20 32 00       	mov    $0x322007,%edx
  104715:	c1 ea 0c             	shr    $0xc,%edx
  104718:	c1 e2 03             	shl    $0x3,%edx
  10471b:	01 d0                	add    %edx,%eax
  10471d:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104720:	77 24                	ja     104746 <pmap_walk+0x179>
  104722:	c7 44 24 0c 3c 99 10 	movl   $0x10993c,0xc(%esp)
  104729:	00 
  10472a:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104731:	00 
  104732:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  104739:	00 
  10473a:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104741:	e8 e8 c0 ff ff       	call   10082e <debug_panic>

	lockadd(&pi->refcount, 1);
  104746:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104749:	83 c0 04             	add    $0x4,%eax
  10474c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104753:	00 
  104754:	89 04 24             	mov    %eax,(%esp)
  104757:	e8 d0 f9 ff ff       	call   10412c <lockadd>
			mem_incref(pi);
			pte = (pte_t*)(mem_pi2ptr(pi));
  10475c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10475f:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104764:	89 d1                	mov    %edx,%ecx
  104766:	29 c1                	sub    %eax,%ecx
  104768:	89 c8                	mov    %ecx,%eax
  10476a:	c1 f8 03             	sar    $0x3,%eax
  10476d:	c1 e0 0c             	shl    $0xc,%eax
  104770:	89 45 e8             	mov    %eax,-0x18(%ebp)
			int i = 0;
  104773:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

			
			for(; i < NPTENTRIES; i++){
  10477a:	eb 14                	jmp    104790 <pmap_walk+0x1c3>
				pte[i] = PTE_ZERO;
  10477c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10477f:	c1 e0 02             	shl    $0x2,%eax
  104782:	03 45 e8             	add    -0x18(%ebp),%eax
  104785:	ba 00 10 32 00       	mov    $0x321000,%edx
  10478a:	89 10                	mov    %edx,(%eax)
			mem_incref(pi);
			pte = (pte_t*)(mem_pi2ptr(pi));
			int i = 0;

			
			for(; i < NPTENTRIES; i++){
  10478c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  104790:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
  104797:	7e e3                	jle    10477c <pmap_walk+0x1af>
				pte[i] = PTE_ZERO;
			}


			*pde = mem_phys(pte) | PTE_P | PTE_W | PTE_U; 
  104799:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10479c:	89 c2                	mov    %eax,%edx
  10479e:	83 ca 07             	or     $0x7,%edx
  1047a1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047a4:	89 10                	mov    %edx,(%eax)
  1047a6:	eb 0d                	jmp    1047b5 <pmap_walk+0x1e8>
			memcpy(page_table, pgtab, sizeof(PAGESIZE));
			*pde |= PTE_W;
			*/
		}
		
		pte = (pte_t*)PGADDR(*pde);
  1047a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1047ab:	8b 00                	mov    (%eax),%eax
  1047ad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1047b2:	89 45 e8             	mov    %eax,-0x18(%ebp)
		
		//pte[PTX(va)] |= PTE_U;
	}


	return &pte[PTX(va)];
  1047b5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047b8:	c1 e8 0c             	shr    $0xc,%eax
  1047bb:	25 ff 03 00 00       	and    $0x3ff,%eax
  1047c0:	c1 e0 02             	shl    $0x2,%eax
  1047c3:	03 45 e8             	add    -0x18(%ebp),%eax
}
  1047c6:	c9                   	leave  
  1047c7:	c3                   	ret    

001047c8 <pmap_insert>:
//
// Hint: The reference solution uses pmap_walk, pmap_remove, and mem_pi2phys.
//
pte_t *
pmap_insert(pde_t *pdir, pageinfo *pi, uint32_t va, int perm)
{
  1047c8:	55                   	push   %ebp
  1047c9:	89 e5                	mov    %esp,%ebp
  1047cb:	53                   	push   %ebx
  1047cc:	83 ec 24             	sub    $0x24,%esp

	// get pte from pdir
	
	//cprintf("in insert pi: %p, pi->refcount = %d\n", pi, pi->refcount);

	pte_t* pte = pmap_walk(pdir, va, 1);
  1047cf:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1047d6:	00 
  1047d7:	8b 45 10             	mov    0x10(%ebp),%eax
  1047da:	89 44 24 04          	mov    %eax,0x4(%esp)
  1047de:	8b 45 08             	mov    0x8(%ebp),%eax
  1047e1:	89 04 24             	mov    %eax,(%esp)
  1047e4:	e8 e4 fd ff ff       	call   1045cd <pmap_walk>
  1047e9:	89 45 ec             	mov    %eax,-0x14(%ebp)


	if(pte == NULL)
  1047ec:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1047f0:	75 0a                	jne    1047fc <pmap_insert+0x34>
		return NULL;
  1047f2:	b8 00 00 00 00       	mov    $0x0,%eax
  1047f7:	e9 82 01 00 00       	jmp    10497e <pmap_insert+0x1b6>


	// if pte has been mapped
	if(*pte != PTE_ZERO){
  1047fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1047ff:	8b 10                	mov    (%eax),%edx
  104801:	b8 00 10 32 00       	mov    $0x321000,%eax
  104806:	39 c2                	cmp    %eax,%edx
  104808:	74 61                	je     10486b <pmap_insert+0xa3>
		// if va has mapped to another pi, remove that pi 
		if(PGADDR(*pte) != mem_pi2phys(pi)){
  10480a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10480d:	8b 00                	mov    (%eax),%eax
  10480f:	89 c1                	mov    %eax,%ecx
  104811:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  104817:	8b 55 0c             	mov    0xc(%ebp),%edx
  10481a:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10481f:	89 d3                	mov    %edx,%ebx
  104821:	29 c3                	sub    %eax,%ebx
  104823:	89 d8                	mov    %ebx,%eax
  104825:	c1 f8 03             	sar    $0x3,%eax
  104828:	c1 e0 0c             	shl    $0xc,%eax
  10482b:	39 c1                	cmp    %eax,%ecx
  10482d:	74 25                	je     104854 <pmap_insert+0x8c>
			//cprintf("in remove\n");
			uint32_t vap = va & ~PAGESHIFT;
  10482f:	8b 45 10             	mov    0x10(%ebp),%eax
  104832:	83 e0 f3             	and    $0xfffffff3,%eax
  104835:	89 45 f0             	mov    %eax,-0x10(%ebp)
			pmap_remove(pdir, vap, PAGESIZE);
  104838:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10483f:	00 
  104840:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104843:	89 44 24 04          	mov    %eax,0x4(%esp)
  104847:	8b 45 08             	mov    0x8(%ebp),%eax
  10484a:	89 04 24             	mov    %eax,(%esp)
  10484d:	e8 32 01 00 00       	call   104984 <pmap_remove>
  104852:	eb 17                	jmp    10486b <pmap_insert+0xa3>
		}
		// if va has mapped to the pi that we want to map
		else{
			//mem_incref(pi);
			//cprintf("---------------\n");
			*pte |= perm;
  104854:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104857:	8b 10                	mov    (%eax),%edx
  104859:	8b 45 14             	mov    0x14(%ebp),%eax
  10485c:	09 c2                	or     %eax,%edx
  10485e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104861:	89 10                	mov    %edx,(%eax)
			return pte;
  104863:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104866:	e9 13 01 00 00       	jmp    10497e <pmap_insert+0x1b6>
		}
	}

	// if pte is null, map it
	
	*pte = mem_pi2phys(pi) | perm | PTE_P;
  10486b:	8b 55 0c             	mov    0xc(%ebp),%edx
  10486e:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104873:	89 d1                	mov    %edx,%ecx
  104875:	29 c1                	sub    %eax,%ecx
  104877:	89 c8                	mov    %ecx,%eax
  104879:	c1 f8 03             	sar    $0x3,%eax
  10487c:	c1 e0 0c             	shl    $0xc,%eax
  10487f:	0b 45 14             	or     0x14(%ebp),%eax
  104882:	83 c8 01             	or     $0x1,%eax
  104885:	89 c2                	mov    %eax,%edx
  104887:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10488a:	89 10                	mov    %edx,(%eax)
  10488c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10488f:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104892:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104897:	83 c0 08             	add    $0x8,%eax
  10489a:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10489d:	76 15                	jbe    1048b4 <pmap_insert+0xec>
  10489f:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1048a4:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  1048aa:	c1 e2 03             	shl    $0x3,%edx
  1048ad:	01 d0                	add    %edx,%eax
  1048af:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1048b2:	72 24                	jb     1048d8 <pmap_insert+0x110>
  1048b4:	c7 44 24 0c dc 98 10 	movl   $0x1098dc,0xc(%esp)
  1048bb:	00 
  1048bc:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1048c3:	00 
  1048c4:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1048cb:	00 
  1048cc:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  1048d3:	e8 56 bf ff ff       	call   10082e <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1048d8:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1048dd:	ba 00 10 32 00       	mov    $0x321000,%edx
  1048e2:	c1 ea 0c             	shr    $0xc,%edx
  1048e5:	c1 e2 03             	shl    $0x3,%edx
  1048e8:	01 d0                	add    %edx,%eax
  1048ea:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1048ed:	75 24                	jne    104913 <pmap_insert+0x14b>
  1048ef:	c7 44 24 0c 20 99 10 	movl   $0x109920,0xc(%esp)
  1048f6:	00 
  1048f7:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1048fe:	00 
  1048ff:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  104906:	00 
  104907:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  10490e:	e8 1b bf ff ff       	call   10082e <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104913:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104918:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  10491d:	c1 ea 0c             	shr    $0xc,%edx
  104920:	c1 e2 03             	shl    $0x3,%edx
  104923:	01 d0                	add    %edx,%eax
  104925:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104928:	72 3b                	jb     104965 <pmap_insert+0x19d>
  10492a:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  10492f:	ba 07 20 32 00       	mov    $0x322007,%edx
  104934:	c1 ea 0c             	shr    $0xc,%edx
  104937:	c1 e2 03             	shl    $0x3,%edx
  10493a:	01 d0                	add    %edx,%eax
  10493c:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10493f:	77 24                	ja     104965 <pmap_insert+0x19d>
  104941:	c7 44 24 0c 3c 99 10 	movl   $0x10993c,0xc(%esp)
  104948:	00 
  104949:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104950:	00 
  104951:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  104958:	00 
  104959:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104960:	e8 c9 be ff ff       	call   10082e <debug_panic>

	lockadd(&pi->refcount, 1);
  104965:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104968:	83 c0 04             	add    $0x4,%eax
  10496b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104972:	00 
  104973:	89 04 24             	mov    %eax,(%esp)
  104976:	e8 b1 f7 ff ff       	call   10412c <lockadd>
	mem_incref(pi);


	//cprintf("out insert pi: %p, pi->refcount = %d\n", pi, pi->refcount);
	
	return pte;
  10497b:	8b 45 ec             	mov    -0x14(%ebp),%eax
	
}
  10497e:	83 c4 24             	add    $0x24,%esp
  104981:	5b                   	pop    %ebx
  104982:	5d                   	pop    %ebp
  104983:	c3                   	ret    

00104984 <pmap_remove>:
// Hint: The TA solution is implemented using pmap_lookup,
// 	pmap_inval, and mem_decref.
//
void
pmap_remove(pde_t *pdir, uint32_t va, size_t size)
{
  104984:	55                   	push   %ebp
  104985:	89 e5                	mov    %esp,%ebp
  104987:	83 ec 48             	sub    $0x48,%esp
	assert(PGOFF(size) == 0);	// must be page-aligned
  10498a:	8b 45 10             	mov    0x10(%ebp),%eax
  10498d:	25 ff 0f 00 00       	and    $0xfff,%eax
  104992:	85 c0                	test   %eax,%eax
  104994:	74 24                	je     1049ba <pmap_remove+0x36>
  104996:	c7 44 24 0c ae 99 10 	movl   $0x1099ae,0xc(%esp)
  10499d:	00 
  10499e:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1049a5:	00 
  1049a6:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
  1049ad:	00 
  1049ae:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1049b5:	e8 74 be ff ff       	call   10082e <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  1049ba:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1049c1:	76 09                	jbe    1049cc <pmap_remove+0x48>
  1049c3:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1049ca:	76 24                	jbe    1049f0 <pmap_remove+0x6c>
  1049cc:	c7 44 24 0c 80 99 10 	movl   $0x109980,0xc(%esp)
  1049d3:	00 
  1049d4:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1049db:	00 
  1049dc:	c7 44 24 04 49 01 00 	movl   $0x149,0x4(%esp)
  1049e3:	00 
  1049e4:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1049eb:	e8 3e be ff ff       	call   10082e <debug_panic>
	assert(size <= VM_USERHI - va);
  1049f0:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1049f5:	2b 45 0c             	sub    0xc(%ebp),%eax
  1049f8:	3b 45 10             	cmp    0x10(%ebp),%eax
  1049fb:	73 24                	jae    104a21 <pmap_remove+0x9d>
  1049fd:	c7 44 24 0c bf 99 10 	movl   $0x1099bf,0xc(%esp)
  104a04:	00 
  104a05:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104a0c:	00 
  104a0d:	c7 44 24 04 4a 01 00 	movl   $0x14a,0x4(%esp)
  104a14:	00 
  104a15:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104a1c:	e8 0d be ff ff       	call   10082e <debug_panic>
	// Fill in this function

	pte_t* pte;
	pageinfo* pi;

	uint32_t count = size/PAGESIZE;
  104a21:	8b 45 10             	mov    0x10(%ebp),%eax
  104a24:	c1 e8 0c             	shr    $0xc,%eax
  104a27:	89 45 d0             	mov    %eax,-0x30(%ebp)


	uint32_t i = 0;
  104a2a:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
	uint32_t start = va;
  104a31:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a34:	89 45 d8             	mov    %eax,-0x28(%ebp)

	bool flag_4M = false;
  104a37:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)

	for(; i < count; i++, start += PAGESIZE){ 
  104a3e:	e9 68 03 00 00       	jmp    104dab <pmap_remove+0x427>
		//cprintf("start = %x\n", start);

		if(PTOFF(start) == 0x0){
  104a43:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104a46:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104a4b:	85 c0                	test   %eax,%eax
  104a4d:	75 07                	jne    104a56 <pmap_remove+0xd2>
			//cprintf("va start at n * 4M, va = %x\n", start);
			flag_4M = true;
  104a4f:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
		}
		
		pte = pmap_walk(pdir, start, 0);
  104a56:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104a5d:	00 
  104a5e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104a61:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a65:	8b 45 08             	mov    0x8(%ebp),%eax
  104a68:	89 04 24             	mov    %eax,(%esp)
  104a6b:	e8 5d fb ff ff       	call   1045cd <pmap_walk>
  104a70:	89 45 c8             	mov    %eax,-0x38(%ebp)
		
		if((*pte != PTE_ZERO) && (pte != NULL)){
  104a73:	8b 45 c8             	mov    -0x38(%ebp),%eax
  104a76:	8b 10                	mov    (%eax),%edx
  104a78:	b8 00 10 32 00       	mov    $0x321000,%eax
  104a7d:	39 c2                	cmp    %eax,%edx
  104a7f:	0f 84 63 01 00 00    	je     104be8 <pmap_remove+0x264>
  104a85:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
  104a89:	0f 84 59 01 00 00    	je     104be8 <pmap_remove+0x264>
			//cprintf("act delete\n");	
			pi = mem_phys2pi(PGADDR(*pte));
  104a8f:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  104a95:	8b 45 c8             	mov    -0x38(%ebp),%eax
  104a98:	8b 00                	mov    (%eax),%eax
  104a9a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104a9f:	c1 e8 0c             	shr    $0xc,%eax
  104aa2:	c1 e0 03             	shl    $0x3,%eax
  104aa5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104aa8:	89 45 cc             	mov    %eax,-0x34(%ebp)
  104aab:	8b 45 cc             	mov    -0x34(%ebp),%eax
  104aae:	89 45 ec             	mov    %eax,-0x14(%ebp)
  104ab1:	c7 45 e8 01 0f 10 00 	movl   $0x100f01,-0x18(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104ab8:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104abd:	83 c0 08             	add    $0x8,%eax
  104ac0:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104ac3:	76 15                	jbe    104ada <pmap_remove+0x156>
  104ac5:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104aca:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  104ad0:	c1 e2 03             	shl    $0x3,%edx
  104ad3:	01 d0                	add    %edx,%eax
  104ad5:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104ad8:	72 24                	jb     104afe <pmap_remove+0x17a>
  104ada:	c7 44 24 0c dc 98 10 	movl   $0x1098dc,0xc(%esp)
  104ae1:	00 
  104ae2:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104ae9:	00 
  104aea:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  104af1:	00 
  104af2:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104af9:	e8 30 bd ff ff       	call   10082e <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  104afe:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104b03:	ba 00 10 32 00       	mov    $0x321000,%edx
  104b08:	c1 ea 0c             	shr    $0xc,%edx
  104b0b:	c1 e2 03             	shl    $0x3,%edx
  104b0e:	01 d0                	add    %edx,%eax
  104b10:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104b13:	75 24                	jne    104b39 <pmap_remove+0x1b5>
  104b15:	c7 44 24 0c 20 99 10 	movl   $0x109920,0xc(%esp)
  104b1c:	00 
  104b1d:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104b24:	00 
  104b25:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  104b2c:	00 
  104b2d:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104b34:	e8 f5 bc ff ff       	call   10082e <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104b39:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104b3e:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104b43:	c1 ea 0c             	shr    $0xc,%edx
  104b46:	c1 e2 03             	shl    $0x3,%edx
  104b49:	01 d0                	add    %edx,%eax
  104b4b:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104b4e:	72 3b                	jb     104b8b <pmap_remove+0x207>
  104b50:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104b55:	ba 07 20 32 00       	mov    $0x322007,%edx
  104b5a:	c1 ea 0c             	shr    $0xc,%edx
  104b5d:	c1 e2 03             	shl    $0x3,%edx
  104b60:	01 d0                	add    %edx,%eax
  104b62:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104b65:	77 24                	ja     104b8b <pmap_remove+0x207>
  104b67:	c7 44 24 0c 3c 99 10 	movl   $0x10993c,0xc(%esp)
  104b6e:	00 
  104b6f:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104b76:	00 
  104b77:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  104b7e:	00 
  104b7f:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104b86:	e8 a3 bc ff ff       	call   10082e <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  104b8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104b8e:	83 c0 04             	add    $0x4,%eax
  104b91:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  104b98:	ff 
  104b99:	89 04 24             	mov    %eax,(%esp)
  104b9c:	e8 9c f5 ff ff       	call   10413d <lockaddz>
  104ba1:	84 c0                	test   %al,%al
  104ba3:	74 0b                	je     104bb0 <pmap_remove+0x22c>
			freefun(pi);
  104ba5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104ba8:	89 04 24             	mov    %eax,(%esp)
  104bab:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104bae:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  104bb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104bb3:	8b 40 04             	mov    0x4(%eax),%eax
  104bb6:	85 c0                	test   %eax,%eax
  104bb8:	79 24                	jns    104bde <pmap_remove+0x25a>
  104bba:	c7 44 24 0c 6d 99 10 	movl   $0x10996d,0xc(%esp)
  104bc1:	00 
  104bc2:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104bc9:	00 
  104bca:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  104bd1:	00 
  104bd2:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104bd9:	e8 50 bc ff ff       	call   10082e <debug_panic>
			mem_decref(pi, mem_free);
			*pte = PTE_ZERO;
  104bde:	ba 00 10 32 00       	mov    $0x321000,%edx
  104be3:	8b 45 c8             	mov    -0x38(%ebp),%eax
  104be6:	89 10                	mov    %edx,(%eax)
		}

		//cprintf("flag_4M = %d, va = %x\n", flag_4M, start);

		if((PTOFF(start) == 0x3ff000) && flag_4M){
  104be8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104beb:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104bf0:	3d 00 f0 3f 00       	cmp    $0x3ff000,%eax
  104bf5:	0f 85 8b 01 00 00    	jne    104d86 <pmap_remove+0x402>
  104bfb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  104bff:	0f 84 81 01 00 00    	je     104d86 <pmap_remove+0x402>
			//cprintf("=======delete PDE\n");
			flag_4M = false;
  104c05:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
			pde_t* pde = &pdir[PDX(start)];
  104c0c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104c0f:	c1 e8 16             	shr    $0x16,%eax
  104c12:	c1 e0 02             	shl    $0x2,%eax
  104c15:	03 45 08             	add    0x8(%ebp),%eax
  104c18:	89 45 e0             	mov    %eax,-0x20(%ebp)
			if(*pde != PTE_ZERO){
  104c1b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104c1e:	8b 10                	mov    (%eax),%edx
  104c20:	b8 00 10 32 00       	mov    $0x321000,%eax
  104c25:	39 c2                	cmp    %eax,%edx
  104c27:	0f 84 59 01 00 00    	je     104d86 <pmap_remove+0x402>
				pageinfo* pi = mem_phys2pi(PGADDR(*pde));
  104c2d:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  104c33:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104c36:	8b 00                	mov    (%eax),%eax
  104c38:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104c3d:	c1 e8 0c             	shr    $0xc,%eax
  104c40:	c1 e0 03             	shl    $0x3,%eax
  104c43:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104c46:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  104c49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104c4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104c4f:	c7 45 f0 01 0f 10 00 	movl   $0x100f01,-0x10(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104c56:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104c5b:	83 c0 08             	add    $0x8,%eax
  104c5e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104c61:	76 15                	jbe    104c78 <pmap_remove+0x2f4>
  104c63:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104c68:	8b 15 04 ed 11 00    	mov    0x11ed04,%edx
  104c6e:	c1 e2 03             	shl    $0x3,%edx
  104c71:	01 d0                	add    %edx,%eax
  104c73:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104c76:	72 24                	jb     104c9c <pmap_remove+0x318>
  104c78:	c7 44 24 0c dc 98 10 	movl   $0x1098dc,0xc(%esp)
  104c7f:	00 
  104c80:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104c87:	00 
  104c88:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  104c8f:	00 
  104c90:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104c97:	e8 92 bb ff ff       	call   10082e <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  104c9c:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104ca1:	ba 00 10 32 00       	mov    $0x321000,%edx
  104ca6:	c1 ea 0c             	shr    $0xc,%edx
  104ca9:	c1 e2 03             	shl    $0x3,%edx
  104cac:	01 d0                	add    %edx,%eax
  104cae:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104cb1:	75 24                	jne    104cd7 <pmap_remove+0x353>
  104cb3:	c7 44 24 0c 20 99 10 	movl   $0x109920,0xc(%esp)
  104cba:	00 
  104cbb:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104cc2:	00 
  104cc3:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  104cca:	00 
  104ccb:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104cd2:	e8 57 bb ff ff       	call   10082e <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104cd7:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104cdc:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104ce1:	c1 ea 0c             	shr    $0xc,%edx
  104ce4:	c1 e2 03             	shl    $0x3,%edx
  104ce7:	01 d0                	add    %edx,%eax
  104ce9:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104cec:	72 3b                	jb     104d29 <pmap_remove+0x3a5>
  104cee:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  104cf3:	ba 07 20 32 00       	mov    $0x322007,%edx
  104cf8:	c1 ea 0c             	shr    $0xc,%edx
  104cfb:	c1 e2 03             	shl    $0x3,%edx
  104cfe:	01 d0                	add    %edx,%eax
  104d00:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104d03:	77 24                	ja     104d29 <pmap_remove+0x3a5>
  104d05:	c7 44 24 0c 3c 99 10 	movl   $0x10993c,0xc(%esp)
  104d0c:	00 
  104d0d:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104d14:	00 
  104d15:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  104d1c:	00 
  104d1d:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104d24:	e8 05 bb ff ff       	call   10082e <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  104d29:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104d2c:	83 c0 04             	add    $0x4,%eax
  104d2f:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  104d36:	ff 
  104d37:	89 04 24             	mov    %eax,(%esp)
  104d3a:	e8 fe f3 ff ff       	call   10413d <lockaddz>
  104d3f:	84 c0                	test   %al,%al
  104d41:	74 0b                	je     104d4e <pmap_remove+0x3ca>
			freefun(pi);
  104d43:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104d46:	89 04 24             	mov    %eax,(%esp)
  104d49:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104d4c:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  104d4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104d51:	8b 40 04             	mov    0x4(%eax),%eax
  104d54:	85 c0                	test   %eax,%eax
  104d56:	79 24                	jns    104d7c <pmap_remove+0x3f8>
  104d58:	c7 44 24 0c 6d 99 10 	movl   $0x10996d,0xc(%esp)
  104d5f:	00 
  104d60:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104d67:	00 
  104d68:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  104d6f:	00 
  104d70:	c7 04 24 13 99 10 00 	movl   $0x109913,(%esp)
  104d77:	e8 b2 ba ff ff       	call   10082e <debug_panic>
				mem_decref(pi, mem_free);
				*pde = PTE_ZERO;
  104d7c:	ba 00 10 32 00       	mov    $0x321000,%edx
  104d81:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104d84:	89 10                	mov    %edx,(%eax)
			}
		}

		pmap_inval(pdir, start, PAGESIZE);
  104d86:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  104d8d:	00 
  104d8e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104d91:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d95:	8b 45 08             	mov    0x8(%ebp),%eax
  104d98:	89 04 24             	mov    %eax,(%esp)
  104d9b:	e8 19 00 00 00       	call   104db9 <pmap_inval>
	uint32_t i = 0;
	uint32_t start = va;

	bool flag_4M = false;

	for(; i < count; i++, start += PAGESIZE){ 
  104da0:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  104da4:	81 45 d8 00 10 00 00 	addl   $0x1000,-0x28(%ebp)
  104dab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104dae:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  104db1:	0f 82 8c fc ff ff    	jb     104a43 <pmap_remove+0xbf>

		pmap_inval(pdir, start, PAGESIZE);

	}
	
}
  104db7:	c9                   	leave  
  104db8:	c3                   	ret    

00104db9 <pmap_inval>:
// but only if the page tables being edited are the ones
// currently in use by the processor.
//
void
pmap_inval(pde_t *pdir, uint32_t va, size_t size)
{
  104db9:	55                   	push   %ebp
  104dba:	89 e5                	mov    %esp,%ebp
  104dbc:	83 ec 18             	sub    $0x18,%esp
	// Flush the entry only if we're modifying the current address space.
	proc *p = proc_cur();
  104dbf:	e8 95 f3 ff ff       	call   104159 <cpu_cur>
  104dc4:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104dca:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (p == NULL || p->pdir == pdir) {
  104dcd:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  104dd1:	74 0e                	je     104de1 <pmap_inval+0x28>
  104dd3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104dd6:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  104ddc:	3b 45 08             	cmp    0x8(%ebp),%eax
  104ddf:	75 23                	jne    104e04 <pmap_inval+0x4b>
		if (size == PAGESIZE)
  104de1:	81 7d 10 00 10 00 00 	cmpl   $0x1000,0x10(%ebp)
  104de8:	75 0e                	jne    104df8 <pmap_inval+0x3f>
			invlpg(mem_ptr(va));	// invalidate one page
  104dea:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ded:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static gcc_inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
  104df0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104df3:	0f 01 38             	invlpg (%eax)
  104df6:	eb 0c                	jmp    104e04 <pmap_inval+0x4b>
		else
			lcr3(mem_phys(pdir));	// invalidate everything
  104df8:	8b 45 08             	mov    0x8(%ebp),%eax
  104dfb:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  104dfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104e01:	0f 22 d8             	mov    %eax,%cr3
	}
}
  104e04:	c9                   	leave  
  104e05:	c3                   	ret    

00104e06 <pmap_copy>:
// Returns true if successfull, false if not enough memory for copy.
//
int
pmap_copy(pde_t *spdir, uint32_t sva, pde_t *dpdir, uint32_t dva,
		size_t size)
{
  104e06:	55                   	push   %ebp
  104e07:	89 e5                	mov    %esp,%ebp
  104e09:	83 ec 18             	sub    $0x18,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  104e0c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e0f:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104e14:	85 c0                	test   %eax,%eax
  104e16:	74 24                	je     104e3c <pmap_copy+0x36>
  104e18:	c7 44 24 0c d6 99 10 	movl   $0x1099d6,0xc(%esp)
  104e1f:	00 
  104e20:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104e27:	00 
  104e28:	c7 44 24 04 99 01 00 	movl   $0x199,0x4(%esp)
  104e2f:	00 
  104e30:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104e37:	e8 f2 b9 ff ff       	call   10082e <debug_panic>
	assert(PTOFF(dva) == 0);
  104e3c:	8b 45 14             	mov    0x14(%ebp),%eax
  104e3f:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104e44:	85 c0                	test   %eax,%eax
  104e46:	74 24                	je     104e6c <pmap_copy+0x66>
  104e48:	c7 44 24 0c e6 99 10 	movl   $0x1099e6,0xc(%esp)
  104e4f:	00 
  104e50:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104e57:	00 
  104e58:	c7 44 24 04 9a 01 00 	movl   $0x19a,0x4(%esp)
  104e5f:	00 
  104e60:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104e67:	e8 c2 b9 ff ff       	call   10082e <debug_panic>
	assert(PTOFF(size) == 0);
  104e6c:	8b 45 18             	mov    0x18(%ebp),%eax
  104e6f:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104e74:	85 c0                	test   %eax,%eax
  104e76:	74 24                	je     104e9c <pmap_copy+0x96>
  104e78:	c7 44 24 0c f6 99 10 	movl   $0x1099f6,0xc(%esp)
  104e7f:	00 
  104e80:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104e87:	00 
  104e88:	c7 44 24 04 9b 01 00 	movl   $0x19b,0x4(%esp)
  104e8f:	00 
  104e90:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104e97:	e8 92 b9 ff ff       	call   10082e <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  104e9c:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104ea3:	76 09                	jbe    104eae <pmap_copy+0xa8>
  104ea5:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  104eac:	76 24                	jbe    104ed2 <pmap_copy+0xcc>
  104eae:	c7 44 24 0c 08 9a 10 	movl   $0x109a08,0xc(%esp)
  104eb5:	00 
  104eb6:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104ebd:	00 
  104ebe:	c7 44 24 04 9c 01 00 	movl   $0x19c,0x4(%esp)
  104ec5:	00 
  104ec6:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104ecd:	e8 5c b9 ff ff       	call   10082e <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  104ed2:	81 7d 14 ff ff ff 3f 	cmpl   $0x3fffffff,0x14(%ebp)
  104ed9:	76 09                	jbe    104ee4 <pmap_copy+0xde>
  104edb:	81 7d 14 ff ff ff ef 	cmpl   $0xefffffff,0x14(%ebp)
  104ee2:	76 24                	jbe    104f08 <pmap_copy+0x102>
  104ee4:	c7 44 24 0c 2c 9a 10 	movl   $0x109a2c,0xc(%esp)
  104eeb:	00 
  104eec:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104ef3:	00 
  104ef4:	c7 44 24 04 9d 01 00 	movl   $0x19d,0x4(%esp)
  104efb:	00 
  104efc:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104f03:	e8 26 b9 ff ff       	call   10082e <debug_panic>
	assert(size <= VM_USERHI - sva);
  104f08:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104f0d:	2b 45 0c             	sub    0xc(%ebp),%eax
  104f10:	3b 45 18             	cmp    0x18(%ebp),%eax
  104f13:	73 24                	jae    104f39 <pmap_copy+0x133>
  104f15:	c7 44 24 0c 50 9a 10 	movl   $0x109a50,0xc(%esp)
  104f1c:	00 
  104f1d:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104f24:	00 
  104f25:	c7 44 24 04 9e 01 00 	movl   $0x19e,0x4(%esp)
  104f2c:	00 
  104f2d:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104f34:	e8 f5 b8 ff ff       	call   10082e <debug_panic>
	assert(size <= VM_USERHI - dva);
  104f39:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104f3e:	2b 45 14             	sub    0x14(%ebp),%eax
  104f41:	3b 45 18             	cmp    0x18(%ebp),%eax
  104f44:	73 24                	jae    104f6a <pmap_copy+0x164>
  104f46:	c7 44 24 0c 68 9a 10 	movl   $0x109a68,0xc(%esp)
  104f4d:	00 
  104f4e:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104f55:	00 
  104f56:	c7 44 24 04 9f 01 00 	movl   $0x19f,0x4(%esp)
  104f5d:	00 
  104f5e:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104f65:	e8 c4 b8 ff ff       	call   10082e <debug_panic>

	panic("pmap_copy() not implemented");
  104f6a:	c7 44 24 08 80 9a 10 	movl   $0x109a80,0x8(%esp)
  104f71:	00 
  104f72:	c7 44 24 04 a1 01 00 	movl   $0x1a1,0x4(%esp)
  104f79:	00 
  104f7a:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104f81:	e8 a8 b8 ff ff       	call   10082e <debug_panic>

00104f86 <pmap_pagefault>:
// If the fault wasn't due to the kernel's copy on write optimization,
// however, this function just returns so the trap gets blamed on the user.
//
void
pmap_pagefault(trapframe *tf)
{
  104f86:	55                   	push   %ebp
  104f87:	89 e5                	mov    %esp,%ebp
  104f89:	83 ec 10             	sub    $0x10,%esp

static gcc_inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
  104f8c:	0f 20 d0             	mov    %cr2,%eax
  104f8f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	return val;
  104f92:	8b 45 fc             	mov    -0x4(%ebp),%eax
	// Read processor's CR2 register to find the faulting linear address.
	uint32_t fva = rcr2();
  104f95:	89 45 f8             	mov    %eax,-0x8(%ebp)
	//cprintf("pmap_pagefault fva %x eip %x\n", fva, tf->eip);

	// Fill in the rest of this code.
}
  104f98:	c9                   	leave  
  104f99:	c3                   	ret    

00104f9a <pmap_mergepage>:
// print a warning to the console and remove the page from the destination.
// If the destination page is read-shared, be sure to copy it before modifying!
//
void
pmap_mergepage(pte_t *rpte, pte_t *spte, pte_t *dpte, uint32_t dva)
{
  104f9a:	55                   	push   %ebp
  104f9b:	89 e5                	mov    %esp,%ebp
  104f9d:	83 ec 18             	sub    $0x18,%esp
	panic("pmap_mergepage() not implemented");
  104fa0:	c7 44 24 08 9c 9a 10 	movl   $0x109a9c,0x8(%esp)
  104fa7:	00 
  104fa8:	c7 44 24 04 bf 01 00 	movl   $0x1bf,0x4(%esp)
  104faf:	00 
  104fb0:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104fb7:	e8 72 b8 ff ff       	call   10082e <debug_panic>

00104fbc <pmap_merge>:
// and a source address space spdir into a destination address space dpdir.
//
int
pmap_merge(pde_t *rpdir, pde_t *spdir, uint32_t sva,
		pde_t *dpdir, uint32_t dva, size_t size)
{
  104fbc:	55                   	push   %ebp
  104fbd:	89 e5                	mov    %esp,%ebp
  104fbf:	83 ec 18             	sub    $0x18,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  104fc2:	8b 45 10             	mov    0x10(%ebp),%eax
  104fc5:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104fca:	85 c0                	test   %eax,%eax
  104fcc:	74 24                	je     104ff2 <pmap_merge+0x36>
  104fce:	c7 44 24 0c d6 99 10 	movl   $0x1099d6,0xc(%esp)
  104fd5:	00 
  104fd6:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  104fdd:	00 
  104fde:	c7 44 24 04 ca 01 00 	movl   $0x1ca,0x4(%esp)
  104fe5:	00 
  104fe6:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  104fed:	e8 3c b8 ff ff       	call   10082e <debug_panic>
	assert(PTOFF(dva) == 0);
  104ff2:	8b 45 18             	mov    0x18(%ebp),%eax
  104ff5:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104ffa:	85 c0                	test   %eax,%eax
  104ffc:	74 24                	je     105022 <pmap_merge+0x66>
  104ffe:	c7 44 24 0c e6 99 10 	movl   $0x1099e6,0xc(%esp)
  105005:	00 
  105006:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10500d:	00 
  10500e:	c7 44 24 04 cb 01 00 	movl   $0x1cb,0x4(%esp)
  105015:	00 
  105016:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10501d:	e8 0c b8 ff ff       	call   10082e <debug_panic>
	assert(PTOFF(size) == 0);
  105022:	8b 45 1c             	mov    0x1c(%ebp),%eax
  105025:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10502a:	85 c0                	test   %eax,%eax
  10502c:	74 24                	je     105052 <pmap_merge+0x96>
  10502e:	c7 44 24 0c f6 99 10 	movl   $0x1099f6,0xc(%esp)
  105035:	00 
  105036:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10503d:	00 
  10503e:	c7 44 24 04 cc 01 00 	movl   $0x1cc,0x4(%esp)
  105045:	00 
  105046:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10504d:	e8 dc b7 ff ff       	call   10082e <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  105052:	81 7d 10 ff ff ff 3f 	cmpl   $0x3fffffff,0x10(%ebp)
  105059:	76 09                	jbe    105064 <pmap_merge+0xa8>
  10505b:	81 7d 10 ff ff ff ef 	cmpl   $0xefffffff,0x10(%ebp)
  105062:	76 24                	jbe    105088 <pmap_merge+0xcc>
  105064:	c7 44 24 0c 08 9a 10 	movl   $0x109a08,0xc(%esp)
  10506b:	00 
  10506c:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105073:	00 
  105074:	c7 44 24 04 cd 01 00 	movl   $0x1cd,0x4(%esp)
  10507b:	00 
  10507c:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105083:	e8 a6 b7 ff ff       	call   10082e <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  105088:	81 7d 18 ff ff ff 3f 	cmpl   $0x3fffffff,0x18(%ebp)
  10508f:	76 09                	jbe    10509a <pmap_merge+0xde>
  105091:	81 7d 18 ff ff ff ef 	cmpl   $0xefffffff,0x18(%ebp)
  105098:	76 24                	jbe    1050be <pmap_merge+0x102>
  10509a:	c7 44 24 0c 2c 9a 10 	movl   $0x109a2c,0xc(%esp)
  1050a1:	00 
  1050a2:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1050a9:	00 
  1050aa:	c7 44 24 04 ce 01 00 	movl   $0x1ce,0x4(%esp)
  1050b1:	00 
  1050b2:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1050b9:	e8 70 b7 ff ff       	call   10082e <debug_panic>
	assert(size <= VM_USERHI - sva);
  1050be:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1050c3:	2b 45 10             	sub    0x10(%ebp),%eax
  1050c6:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  1050c9:	73 24                	jae    1050ef <pmap_merge+0x133>
  1050cb:	c7 44 24 0c 50 9a 10 	movl   $0x109a50,0xc(%esp)
  1050d2:	00 
  1050d3:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1050da:	00 
  1050db:	c7 44 24 04 cf 01 00 	movl   $0x1cf,0x4(%esp)
  1050e2:	00 
  1050e3:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1050ea:	e8 3f b7 ff ff       	call   10082e <debug_panic>
	assert(size <= VM_USERHI - dva);
  1050ef:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1050f4:	2b 45 18             	sub    0x18(%ebp),%eax
  1050f7:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  1050fa:	73 24                	jae    105120 <pmap_merge+0x164>
  1050fc:	c7 44 24 0c 68 9a 10 	movl   $0x109a68,0xc(%esp)
  105103:	00 
  105104:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10510b:	00 
  10510c:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
  105113:	00 
  105114:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10511b:	e8 0e b7 ff ff       	call   10082e <debug_panic>

	panic("pmap_merge() not implemented");
  105120:	c7 44 24 08 bd 9a 10 	movl   $0x109abd,0x8(%esp)
  105127:	00 
  105128:	c7 44 24 04 d2 01 00 	movl   $0x1d2,0x4(%esp)
  10512f:	00 
  105130:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105137:	e8 f2 b6 ff ff       	call   10082e <debug_panic>

0010513c <pmap_setperm>:
// If the user gives SYS_WRITE permission to a PTE_ZERO mapping,
// the page fault handler copies the zero page when the first write occurs.
//
int
pmap_setperm(pde_t *pdir, uint32_t va, uint32_t size, int perm)
{
  10513c:	55                   	push   %ebp
  10513d:	89 e5                	mov    %esp,%ebp
  10513f:	83 ec 18             	sub    $0x18,%esp
	assert(PGOFF(va) == 0);
  105142:	8b 45 0c             	mov    0xc(%ebp),%eax
  105145:	25 ff 0f 00 00       	and    $0xfff,%eax
  10514a:	85 c0                	test   %eax,%eax
  10514c:	74 24                	je     105172 <pmap_setperm+0x36>
  10514e:	c7 44 24 0c da 9a 10 	movl   $0x109ada,0xc(%esp)
  105155:	00 
  105156:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10515d:	00 
  10515e:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
  105165:	00 
  105166:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10516d:	e8 bc b6 ff ff       	call   10082e <debug_panic>
	assert(PGOFF(size) == 0);
  105172:	8b 45 10             	mov    0x10(%ebp),%eax
  105175:	25 ff 0f 00 00       	and    $0xfff,%eax
  10517a:	85 c0                	test   %eax,%eax
  10517c:	74 24                	je     1051a2 <pmap_setperm+0x66>
  10517e:	c7 44 24 0c ae 99 10 	movl   $0x1099ae,0xc(%esp)
  105185:	00 
  105186:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10518d:	00 
  10518e:	c7 44 24 04 e1 01 00 	movl   $0x1e1,0x4(%esp)
  105195:	00 
  105196:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10519d:	e8 8c b6 ff ff       	call   10082e <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  1051a2:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1051a9:	76 09                	jbe    1051b4 <pmap_setperm+0x78>
  1051ab:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1051b2:	76 24                	jbe    1051d8 <pmap_setperm+0x9c>
  1051b4:	c7 44 24 0c 80 99 10 	movl   $0x109980,0xc(%esp)
  1051bb:	00 
  1051bc:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1051c3:	00 
  1051c4:	c7 44 24 04 e2 01 00 	movl   $0x1e2,0x4(%esp)
  1051cb:	00 
  1051cc:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1051d3:	e8 56 b6 ff ff       	call   10082e <debug_panic>
	assert(size <= VM_USERHI - va);
  1051d8:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1051dd:	2b 45 0c             	sub    0xc(%ebp),%eax
  1051e0:	3b 45 10             	cmp    0x10(%ebp),%eax
  1051e3:	73 24                	jae    105209 <pmap_setperm+0xcd>
  1051e5:	c7 44 24 0c bf 99 10 	movl   $0x1099bf,0xc(%esp)
  1051ec:	00 
  1051ed:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1051f4:	00 
  1051f5:	c7 44 24 04 e3 01 00 	movl   $0x1e3,0x4(%esp)
  1051fc:	00 
  1051fd:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105204:	e8 25 b6 ff ff       	call   10082e <debug_panic>
	assert((perm & ~(SYS_RW)) == 0);
  105209:	8b 45 14             	mov    0x14(%ebp),%eax
  10520c:	80 e4 f9             	and    $0xf9,%ah
  10520f:	85 c0                	test   %eax,%eax
  105211:	74 24                	je     105237 <pmap_setperm+0xfb>
  105213:	c7 44 24 0c e9 9a 10 	movl   $0x109ae9,0xc(%esp)
  10521a:	00 
  10521b:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105222:	00 
  105223:	c7 44 24 04 e4 01 00 	movl   $0x1e4,0x4(%esp)
  10522a:	00 
  10522b:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105232:	e8 f7 b5 ff ff       	call   10082e <debug_panic>

	panic("pmap_merge() not implemented");
  105237:	c7 44 24 08 bd 9a 10 	movl   $0x109abd,0x8(%esp)
  10523e:	00 
  10523f:	c7 44 24 04 e6 01 00 	movl   $0x1e6,0x4(%esp)
  105246:	00 
  105247:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10524e:	e8 db b5 ff ff       	call   10082e <debug_panic>

00105253 <va2pa>:
// this functionality for us!  We define our own version to help check
// the pmap_check() function; it shouldn't be used elsewhere.
//
static uint32_t
va2pa(pde_t *pdir, uintptr_t va)
{
  105253:	55                   	push   %ebp
  105254:	89 e5                	mov    %esp,%ebp
  105256:	83 ec 10             	sub    $0x10,%esp
	pdir = &pdir[PDX(va)];
  105259:	8b 45 0c             	mov    0xc(%ebp),%eax
  10525c:	c1 e8 16             	shr    $0x16,%eax
  10525f:	c1 e0 02             	shl    $0x2,%eax
  105262:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pdir & PTE_P))
  105265:	8b 45 08             	mov    0x8(%ebp),%eax
  105268:	8b 00                	mov    (%eax),%eax
  10526a:	83 e0 01             	and    $0x1,%eax
  10526d:	85 c0                	test   %eax,%eax
  10526f:	75 07                	jne    105278 <va2pa+0x25>
		return ~0;
  105271:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  105276:	eb 46                	jmp    1052be <va2pa+0x6b>
	pte_t *ptab = mem_ptr(PGADDR(*pdir));
  105278:	8b 45 08             	mov    0x8(%ebp),%eax
  10527b:	8b 00                	mov    (%eax),%eax
  10527d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105282:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (!(ptab[PTX(va)] & PTE_P))
  105285:	8b 45 0c             	mov    0xc(%ebp),%eax
  105288:	c1 e8 0c             	shr    $0xc,%eax
  10528b:	25 ff 03 00 00       	and    $0x3ff,%eax
  105290:	c1 e0 02             	shl    $0x2,%eax
  105293:	03 45 fc             	add    -0x4(%ebp),%eax
  105296:	8b 00                	mov    (%eax),%eax
  105298:	83 e0 01             	and    $0x1,%eax
  10529b:	85 c0                	test   %eax,%eax
  10529d:	75 07                	jne    1052a6 <va2pa+0x53>
		return ~0;
  10529f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1052a4:	eb 18                	jmp    1052be <va2pa+0x6b>
	return PGADDR(ptab[PTX(va)]);
  1052a6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1052a9:	c1 e8 0c             	shr    $0xc,%eax
  1052ac:	25 ff 03 00 00       	and    $0x3ff,%eax
  1052b1:	c1 e0 02             	shl    $0x2,%eax
  1052b4:	03 45 fc             	add    -0x4(%ebp),%eax
  1052b7:	8b 00                	mov    (%eax),%eax
  1052b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
  1052be:	c9                   	leave  
  1052bf:	c3                   	ret    

001052c0 <pmap_check>:

// check pmap_insert, pmap_remove, &c
void
pmap_check(void)
{
  1052c0:	55                   	push   %ebp
  1052c1:	89 e5                	mov    %esp,%ebp
  1052c3:	53                   	push   %ebx
  1052c4:	83 ec 44             	sub    $0x44,%esp

	cprintf("into pmap_check()\n");
  1052c7:	c7 04 24 01 9b 10 00 	movl   $0x109b01,(%esp)
  1052ce:	e8 be 2c 00 00       	call   107f91 <cprintf>
	pageinfo *fl;
	pte_t *ptep, *ptep1;
	int i;

	// should be able to allocate three pages
	pi0 = pi1 = pi2 = 0;
  1052d3:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  1052da:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1052dd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  1052e0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1052e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	pi0 = mem_alloc();
  1052e6:	e8 cf bb ff ff       	call   100eba <mem_alloc>
  1052eb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	pi1 = mem_alloc();
  1052ee:	e8 c7 bb ff ff       	call   100eba <mem_alloc>
  1052f3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	pi2 = mem_alloc();
  1052f6:	e8 bf bb ff ff       	call   100eba <mem_alloc>
  1052fb:	89 45 dc             	mov    %eax,-0x24(%ebp)
	pi3 = mem_alloc();
  1052fe:	e8 b7 bb ff ff       	call   100eba <mem_alloc>
  105303:	89 45 e0             	mov    %eax,-0x20(%ebp)

	assert(pi0);
  105306:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  10530a:	75 24                	jne    105330 <pmap_check+0x70>
  10530c:	c7 44 24 0c 14 9b 10 	movl   $0x109b14,0xc(%esp)
  105313:	00 
  105314:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10531b:	00 
  10531c:	c7 44 24 04 0f 02 00 	movl   $0x20f,0x4(%esp)
  105323:	00 
  105324:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10532b:	e8 fe b4 ff ff       	call   10082e <debug_panic>
	assert(pi1 && pi1 != pi0);
  105330:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  105334:	74 08                	je     10533e <pmap_check+0x7e>
  105336:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105339:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  10533c:	75 24                	jne    105362 <pmap_check+0xa2>
  10533e:	c7 44 24 0c 18 9b 10 	movl   $0x109b18,0xc(%esp)
  105345:	00 
  105346:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10534d:	00 
  10534e:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
  105355:	00 
  105356:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10535d:	e8 cc b4 ff ff       	call   10082e <debug_panic>
	assert(pi2 && pi2 != pi1 && pi2 != pi0);
  105362:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  105366:	74 10                	je     105378 <pmap_check+0xb8>
  105368:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10536b:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  10536e:	74 08                	je     105378 <pmap_check+0xb8>
  105370:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105373:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  105376:	75 24                	jne    10539c <pmap_check+0xdc>
  105378:	c7 44 24 0c 2c 9b 10 	movl   $0x109b2c,0xc(%esp)
  10537f:	00 
  105380:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105387:	00 
  105388:	c7 44 24 04 11 02 00 	movl   $0x211,0x4(%esp)
  10538f:	00 
  105390:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105397:	e8 92 b4 ff ff       	call   10082e <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  10539c:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  1053a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	mem_freelist = NULL;
  1053a4:	c7 05 00 ed 11 00 00 	movl   $0x0,0x11ed00
  1053ab:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == NULL);
  1053ae:	e8 07 bb ff ff       	call   100eba <mem_alloc>
  1053b3:	85 c0                	test   %eax,%eax
  1053b5:	74 24                	je     1053db <pmap_check+0x11b>
  1053b7:	c7 44 24 0c 4c 9b 10 	movl   $0x109b4c,0xc(%esp)
  1053be:	00 
  1053bf:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1053c6:	00 
  1053c7:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
  1053ce:	00 
  1053cf:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1053d6:	e8 53 b4 ff ff       	call   10082e <debug_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) == NULL);
  1053db:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1053e2:	00 
  1053e3:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  1053ea:	40 
  1053eb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1053ee:	89 44 24 04          	mov    %eax,0x4(%esp)
  1053f2:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1053f9:	e8 ca f3 ff ff       	call   1047c8 <pmap_insert>
  1053fe:	85 c0                	test   %eax,%eax
  105400:	74 24                	je     105426 <pmap_check+0x166>
  105402:	c7 44 24 0c 60 9b 10 	movl   $0x109b60,0xc(%esp)
  105409:	00 
  10540a:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105411:	00 
  105412:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
  105419:	00 
  10541a:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105421:	e8 08 b4 ff ff       	call   10082e <debug_panic>

	// free pi0 and try again: pi0 should be used for page table
	mem_free(pi0);
  105426:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105429:	89 04 24             	mov    %eax,(%esp)
  10542c:	e8 d0 ba ff ff       	call   100f01 <mem_free>

	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) != NULL);
  105431:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105438:	00 
  105439:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  105440:	40 
  105441:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105444:	89 44 24 04          	mov    %eax,0x4(%esp)
  105448:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10544f:	e8 74 f3 ff ff       	call   1047c8 <pmap_insert>
  105454:	85 c0                	test   %eax,%eax
  105456:	75 24                	jne    10547c <pmap_check+0x1bc>
  105458:	c7 44 24 0c 98 9b 10 	movl   $0x109b98,0xc(%esp)
  10545f:	00 
  105460:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105467:	00 
  105468:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
  10546f:	00 
  105470:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105477:	e8 b2 b3 ff ff       	call   10082e <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi0));
  10547c:	a1 00 04 32 00       	mov    0x320400,%eax
  105481:	89 c1                	mov    %eax,%ecx
  105483:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  105489:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10548c:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  105491:	89 d3                	mov    %edx,%ebx
  105493:	29 c3                	sub    %eax,%ebx
  105495:	89 d8                	mov    %ebx,%eax
  105497:	c1 f8 03             	sar    $0x3,%eax
  10549a:	c1 e0 0c             	shl    $0xc,%eax
  10549d:	39 c1                	cmp    %eax,%ecx
  10549f:	74 24                	je     1054c5 <pmap_check+0x205>
  1054a1:	c7 44 24 0c d0 9b 10 	movl   $0x109bd0,0xc(%esp)
  1054a8:	00 
  1054a9:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1054b0:	00 
  1054b1:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
  1054b8:	00 
  1054b9:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1054c0:	e8 69 b3 ff ff       	call   10082e <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO) == mem_pi2phys(pi1));
  1054c5:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1054cc:	40 
  1054cd:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1054d4:	e8 7a fd ff ff       	call   105253 <va2pa>
  1054d9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1054dc:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  1054e2:	89 cb                	mov    %ecx,%ebx
  1054e4:	29 d3                	sub    %edx,%ebx
  1054e6:	89 da                	mov    %ebx,%edx
  1054e8:	c1 fa 03             	sar    $0x3,%edx
  1054eb:	c1 e2 0c             	shl    $0xc,%edx
  1054ee:	39 d0                	cmp    %edx,%eax
  1054f0:	74 24                	je     105516 <pmap_check+0x256>
  1054f2:	c7 44 24 0c 0c 9c 10 	movl   $0x109c0c,0xc(%esp)
  1054f9:	00 
  1054fa:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105501:	00 
  105502:	c7 44 24 04 22 02 00 	movl   $0x222,0x4(%esp)
  105509:	00 
  10550a:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105511:	e8 18 b3 ff ff       	call   10082e <debug_panic>


	assert(pi1->refcount == 1);
  105516:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105519:	8b 40 04             	mov    0x4(%eax),%eax
  10551c:	83 f8 01             	cmp    $0x1,%eax
  10551f:	74 24                	je     105545 <pmap_check+0x285>
  105521:	c7 44 24 0c 40 9c 10 	movl   $0x109c40,0xc(%esp)
  105528:	00 
  105529:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105530:	00 
  105531:	c7 44 24 04 25 02 00 	movl   $0x225,0x4(%esp)
  105538:	00 
  105539:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105540:	e8 e9 b2 ff ff       	call   10082e <debug_panic>
	assert(pi0->refcount == 1);
  105545:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105548:	8b 40 04             	mov    0x4(%eax),%eax
  10554b:	83 f8 01             	cmp    $0x1,%eax
  10554e:	74 24                	je     105574 <pmap_check+0x2b4>
  105550:	c7 44 24 0c 53 9c 10 	movl   $0x109c53,0xc(%esp)
  105557:	00 
  105558:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10555f:	00 
  105560:	c7 44 24 04 26 02 00 	movl   $0x226,0x4(%esp)
  105567:	00 
  105568:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10556f:	e8 ba b2 ff ff       	call   10082e <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because pi0 is already allocated for page table

	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  105574:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10557b:	00 
  10557c:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  105583:	40 
  105584:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105587:	89 44 24 04          	mov    %eax,0x4(%esp)
  10558b:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105592:	e8 31 f2 ff ff       	call   1047c8 <pmap_insert>
  105597:	85 c0                	test   %eax,%eax
  105599:	75 24                	jne    1055bf <pmap_check+0x2ff>
  10559b:	c7 44 24 0c 68 9c 10 	movl   $0x109c68,0xc(%esp)
  1055a2:	00 
  1055a3:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1055aa:	00 
  1055ab:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
  1055b2:	00 
  1055b3:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1055ba:	e8 6f b2 ff ff       	call   10082e <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  1055bf:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1055c6:	40 
  1055c7:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1055ce:	e8 80 fc ff ff       	call   105253 <va2pa>
  1055d3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1055d6:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  1055dc:	89 cb                	mov    %ecx,%ebx
  1055de:	29 d3                	sub    %edx,%ebx
  1055e0:	89 da                	mov    %ebx,%edx
  1055e2:	c1 fa 03             	sar    $0x3,%edx
  1055e5:	c1 e2 0c             	shl    $0xc,%edx
  1055e8:	39 d0                	cmp    %edx,%eax
  1055ea:	74 24                	je     105610 <pmap_check+0x350>
  1055ec:	c7 44 24 0c a0 9c 10 	movl   $0x109ca0,0xc(%esp)
  1055f3:	00 
  1055f4:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1055fb:	00 
  1055fc:	c7 44 24 04 2c 02 00 	movl   $0x22c,0x4(%esp)
  105603:	00 
  105604:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10560b:	e8 1e b2 ff ff       	call   10082e <debug_panic>
	assert(pi2->refcount == 1);
  105610:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105613:	8b 40 04             	mov    0x4(%eax),%eax
  105616:	83 f8 01             	cmp    $0x1,%eax
  105619:	74 24                	je     10563f <pmap_check+0x37f>
  10561b:	c7 44 24 0c dd 9c 10 	movl   $0x109cdd,0xc(%esp)
  105622:	00 
  105623:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10562a:	00 
  10562b:	c7 44 24 04 2d 02 00 	movl   $0x22d,0x4(%esp)
  105632:	00 
  105633:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10563a:	e8 ef b1 ff ff       	call   10082e <debug_panic>

	// should be no free memory
	assert(mem_alloc() == NULL);
  10563f:	e8 76 b8 ff ff       	call   100eba <mem_alloc>
  105644:	85 c0                	test   %eax,%eax
  105646:	74 24                	je     10566c <pmap_check+0x3ac>
  105648:	c7 44 24 0c 4c 9b 10 	movl   $0x109b4c,0xc(%esp)
  10564f:	00 
  105650:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105657:	00 
  105658:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
  10565f:	00 
  105660:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105667:	e8 c2 b1 ff ff       	call   10082e <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because it's already there
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  10566c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105673:	00 
  105674:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  10567b:	40 
  10567c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10567f:	89 44 24 04          	mov    %eax,0x4(%esp)
  105683:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10568a:	e8 39 f1 ff ff       	call   1047c8 <pmap_insert>
  10568f:	85 c0                	test   %eax,%eax
  105691:	75 24                	jne    1056b7 <pmap_check+0x3f7>
  105693:	c7 44 24 0c 68 9c 10 	movl   $0x109c68,0xc(%esp)
  10569a:	00 
  10569b:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1056a2:	00 
  1056a3:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
  1056aa:	00 
  1056ab:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1056b2:	e8 77 b1 ff ff       	call   10082e <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  1056b7:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1056be:	40 
  1056bf:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1056c6:	e8 88 fb ff ff       	call   105253 <va2pa>
  1056cb:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1056ce:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  1056d4:	89 cb                	mov    %ecx,%ebx
  1056d6:	29 d3                	sub    %edx,%ebx
  1056d8:	89 da                	mov    %ebx,%edx
  1056da:	c1 fa 03             	sar    $0x3,%edx
  1056dd:	c1 e2 0c             	shl    $0xc,%edx
  1056e0:	39 d0                	cmp    %edx,%eax
  1056e2:	74 24                	je     105708 <pmap_check+0x448>
  1056e4:	c7 44 24 0c a0 9c 10 	movl   $0x109ca0,0xc(%esp)
  1056eb:	00 
  1056ec:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1056f3:	00 
  1056f4:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
  1056fb:	00 
  1056fc:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105703:	e8 26 b1 ff ff       	call   10082e <debug_panic>
	assert(pi2->refcount == 1);
  105708:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10570b:	8b 40 04             	mov    0x4(%eax),%eax
  10570e:	83 f8 01             	cmp    $0x1,%eax
  105711:	74 24                	je     105737 <pmap_check+0x477>
  105713:	c7 44 24 0c dd 9c 10 	movl   $0x109cdd,0xc(%esp)
  10571a:	00 
  10571b:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105722:	00 
  105723:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
  10572a:	00 
  10572b:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105732:	e8 f7 b0 ff ff       	call   10082e <debug_panic>

	// pi2 should NOT be on the free list
	// could hapien in ref counts are handled slopiily in pmap_insert
	assert(mem_alloc() == NULL);
  105737:	e8 7e b7 ff ff       	call   100eba <mem_alloc>
  10573c:	85 c0                	test   %eax,%eax
  10573e:	74 24                	je     105764 <pmap_check+0x4a4>
  105740:	c7 44 24 0c 4c 9b 10 	movl   $0x109b4c,0xc(%esp)
  105747:	00 
  105748:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10574f:	00 
  105750:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
  105757:	00 
  105758:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10575f:	e8 ca b0 ff ff       	call   10082e <debug_panic>

	// check that pmap_walk returns a pointer to the pte
	ptep = mem_ptr(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PAGESIZE)]));
  105764:	a1 00 04 32 00       	mov    0x320400,%eax
  105769:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10576e:	89 45 e8             	mov    %eax,-0x18(%ebp)
	assert(pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0)
  105771:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105778:	00 
  105779:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105780:	40 
  105781:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105788:	e8 40 ee ff ff       	call   1045cd <pmap_walk>
  10578d:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105790:	83 c2 04             	add    $0x4,%edx
  105793:	39 d0                	cmp    %edx,%eax
  105795:	74 24                	je     1057bb <pmap_check+0x4fb>
  105797:	c7 44 24 0c f0 9c 10 	movl   $0x109cf0,0xc(%esp)
  10579e:	00 
  10579f:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1057a6:	00 
  1057a7:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
  1057ae:	00 
  1057af:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1057b6:	e8 73 b0 ff ff       	call   10082e <debug_panic>
		== ptep+PTX(VM_USERLO+PAGESIZE));

	// should be able to change permissions too.
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, PTE_U));
  1057bb:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  1057c2:	00 
  1057c3:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  1057ca:	40 
  1057cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1057ce:	89 44 24 04          	mov    %eax,0x4(%esp)
  1057d2:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1057d9:	e8 ea ef ff ff       	call   1047c8 <pmap_insert>
  1057de:	85 c0                	test   %eax,%eax
  1057e0:	75 24                	jne    105806 <pmap_check+0x546>
  1057e2:	c7 44 24 0c 40 9d 10 	movl   $0x109d40,0xc(%esp)
  1057e9:	00 
  1057ea:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1057f1:	00 
  1057f2:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
  1057f9:	00 
  1057fa:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105801:	e8 28 b0 ff ff       	call   10082e <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  105806:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10580d:	40 
  10580e:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105815:	e8 39 fa ff ff       	call   105253 <va2pa>
  10581a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  10581d:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  105823:	89 cb                	mov    %ecx,%ebx
  105825:	29 d3                	sub    %edx,%ebx
  105827:	89 da                	mov    %ebx,%edx
  105829:	c1 fa 03             	sar    $0x3,%edx
  10582c:	c1 e2 0c             	shl    $0xc,%edx
  10582f:	39 d0                	cmp    %edx,%eax
  105831:	74 24                	je     105857 <pmap_check+0x597>
  105833:	c7 44 24 0c a0 9c 10 	movl   $0x109ca0,0xc(%esp)
  10583a:	00 
  10583b:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105842:	00 
  105843:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
  10584a:	00 
  10584b:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105852:	e8 d7 af ff ff       	call   10082e <debug_panic>
	assert(pi2->refcount == 1);
  105857:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10585a:	8b 40 04             	mov    0x4(%eax),%eax
  10585d:	83 f8 01             	cmp    $0x1,%eax
  105860:	74 24                	je     105886 <pmap_check+0x5c6>
  105862:	c7 44 24 0c dd 9c 10 	movl   $0x109cdd,0xc(%esp)
  105869:	00 
  10586a:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105871:	00 
  105872:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
  105879:	00 
  10587a:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105881:	e8 a8 af ff ff       	call   10082e <debug_panic>
	assert(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U);
  105886:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10588d:	00 
  10588e:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105895:	40 
  105896:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10589d:	e8 2b ed ff ff       	call   1045cd <pmap_walk>
  1058a2:	8b 00                	mov    (%eax),%eax
  1058a4:	83 e0 04             	and    $0x4,%eax
  1058a7:	85 c0                	test   %eax,%eax
  1058a9:	75 24                	jne    1058cf <pmap_check+0x60f>
  1058ab:	c7 44 24 0c 7c 9d 10 	movl   $0x109d7c,0xc(%esp)
  1058b2:	00 
  1058b3:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1058ba:	00 
  1058bb:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
  1058c2:	00 
  1058c3:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1058ca:	e8 5f af ff ff       	call   10082e <debug_panic>
	assert(pmap_bootpdir[PDX(VM_USERLO)] & PTE_U);
  1058cf:	a1 00 04 32 00       	mov    0x320400,%eax
  1058d4:	83 e0 04             	and    $0x4,%eax
  1058d7:	85 c0                	test   %eax,%eax
  1058d9:	75 24                	jne    1058ff <pmap_check+0x63f>
  1058db:	c7 44 24 0c b8 9d 10 	movl   $0x109db8,0xc(%esp)
  1058e2:	00 
  1058e3:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1058ea:	00 
  1058eb:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
  1058f2:	00 
  1058f3:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1058fa:	e8 2f af ff ff       	call   10082e <debug_panic>
	
	// should not be able to map at VM_USERLO+PTSIZE
	// because we need a free page for a page table
	assert(pmap_insert(pmap_bootpdir, pi0, VM_USERLO+PTSIZE, 0) == NULL);
  1058ff:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105906:	00 
  105907:	c7 44 24 08 00 00 40 	movl   $0x40400000,0x8(%esp)
  10590e:	40 
  10590f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105912:	89 44 24 04          	mov    %eax,0x4(%esp)
  105916:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10591d:	e8 a6 ee ff ff       	call   1047c8 <pmap_insert>
  105922:	85 c0                	test   %eax,%eax
  105924:	74 24                	je     10594a <pmap_check+0x68a>
  105926:	c7 44 24 0c e0 9d 10 	movl   $0x109de0,0xc(%esp)
  10592d:	00 
  10592e:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105935:	00 
  105936:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
  10593d:	00 
  10593e:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105945:	e8 e4 ae ff ff       	call   10082e <debug_panic>

	// insert pi1 at VM_USERLO+PAGESIZE (replacing pi2)
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO+PAGESIZE, 0));
  10594a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105951:	00 
  105952:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  105959:	40 
  10595a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10595d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105961:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105968:	e8 5b ee ff ff       	call   1047c8 <pmap_insert>
  10596d:	85 c0                	test   %eax,%eax
  10596f:	75 24                	jne    105995 <pmap_check+0x6d5>
  105971:	c7 44 24 0c 20 9e 10 	movl   $0x109e20,0xc(%esp)
  105978:	00 
  105979:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105980:	00 
  105981:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
  105988:	00 
  105989:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105990:	e8 99 ae ff ff       	call   10082e <debug_panic>
	assert(!(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U));
  105995:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10599c:	00 
  10599d:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1059a4:	40 
  1059a5:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1059ac:	e8 1c ec ff ff       	call   1045cd <pmap_walk>
  1059b1:	8b 00                	mov    (%eax),%eax
  1059b3:	83 e0 04             	and    $0x4,%eax
  1059b6:	85 c0                	test   %eax,%eax
  1059b8:	74 24                	je     1059de <pmap_check+0x71e>
  1059ba:	c7 44 24 0c 58 9e 10 	movl   $0x109e58,0xc(%esp)
  1059c1:	00 
  1059c2:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1059c9:	00 
  1059ca:	c7 44 24 04 4e 02 00 	movl   $0x24e,0x4(%esp)
  1059d1:	00 
  1059d2:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1059d9:	e8 50 ae ff ff       	call   10082e <debug_panic>

	// should have pi1 at both +0 and +PAGESIZE, pi2 nowhere, ...
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == mem_pi2phys(pi1));
  1059de:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1059e5:	40 
  1059e6:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1059ed:	e8 61 f8 ff ff       	call   105253 <va2pa>
  1059f2:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1059f5:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  1059fb:	89 cb                	mov    %ecx,%ebx
  1059fd:	29 d3                	sub    %edx,%ebx
  1059ff:	89 da                	mov    %ebx,%edx
  105a01:	c1 fa 03             	sar    $0x3,%edx
  105a04:	c1 e2 0c             	shl    $0xc,%edx
  105a07:	39 d0                	cmp    %edx,%eax
  105a09:	74 24                	je     105a2f <pmap_check+0x76f>
  105a0b:	c7 44 24 0c 94 9e 10 	movl   $0x109e94,0xc(%esp)
  105a12:	00 
  105a13:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105a1a:	00 
  105a1b:	c7 44 24 04 51 02 00 	movl   $0x251,0x4(%esp)
  105a22:	00 
  105a23:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105a2a:	e8 ff ad ff ff       	call   10082e <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  105a2f:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105a36:	40 
  105a37:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105a3e:	e8 10 f8 ff ff       	call   105253 <va2pa>
  105a43:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  105a46:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  105a4c:	89 cb                	mov    %ecx,%ebx
  105a4e:	29 d3                	sub    %edx,%ebx
  105a50:	89 da                	mov    %ebx,%edx
  105a52:	c1 fa 03             	sar    $0x3,%edx
  105a55:	c1 e2 0c             	shl    $0xc,%edx
  105a58:	39 d0                	cmp    %edx,%eax
  105a5a:	74 24                	je     105a80 <pmap_check+0x7c0>
  105a5c:	c7 44 24 0c cc 9e 10 	movl   $0x109ecc,0xc(%esp)
  105a63:	00 
  105a64:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105a6b:	00 
  105a6c:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
  105a73:	00 
  105a74:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105a7b:	e8 ae ad ff ff       	call   10082e <debug_panic>
	// ... and ref counts should reflect this
	assert(pi1->refcount == 2);
  105a80:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105a83:	8b 40 04             	mov    0x4(%eax),%eax
  105a86:	83 f8 02             	cmp    $0x2,%eax
  105a89:	74 24                	je     105aaf <pmap_check+0x7ef>
  105a8b:	c7 44 24 0c 09 9f 10 	movl   $0x109f09,0xc(%esp)
  105a92:	00 
  105a93:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105a9a:	00 
  105a9b:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
  105aa2:	00 
  105aa3:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105aaa:	e8 7f ad ff ff       	call   10082e <debug_panic>
	assert(pi2->refcount == 0);
  105aaf:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105ab2:	8b 40 04             	mov    0x4(%eax),%eax
  105ab5:	85 c0                	test   %eax,%eax
  105ab7:	74 24                	je     105add <pmap_check+0x81d>
  105ab9:	c7 44 24 0c 1c 9f 10 	movl   $0x109f1c,0xc(%esp)
  105ac0:	00 
  105ac1:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105ac8:	00 
  105ac9:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
  105ad0:	00 
  105ad1:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105ad8:	e8 51 ad ff ff       	call   10082e <debug_panic>

	// pi2 should be returned by mem_alloc
	assert(mem_alloc() == pi2);
  105add:	e8 d8 b3 ff ff       	call   100eba <mem_alloc>
  105ae2:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  105ae5:	74 24                	je     105b0b <pmap_check+0x84b>
  105ae7:	c7 44 24 0c 2f 9f 10 	movl   $0x109f2f,0xc(%esp)
  105aee:	00 
  105aef:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105af6:	00 
  105af7:	c7 44 24 04 58 02 00 	movl   $0x258,0x4(%esp)
  105afe:	00 
  105aff:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105b06:	e8 23 ad ff ff       	call   10082e <debug_panic>

	// unmapping pi1 at VM_USERLO+0 should keep pi1 at +PAGESIZE
	pmap_remove(pmap_bootpdir, VM_USERLO+0, PAGESIZE);
  105b0b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105b12:	00 
  105b13:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105b1a:	40 
  105b1b:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105b22:	e8 5d ee ff ff       	call   104984 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  105b27:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105b2e:	40 
  105b2f:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105b36:	e8 18 f7 ff ff       	call   105253 <va2pa>
  105b3b:	83 f8 ff             	cmp    $0xffffffff,%eax
  105b3e:	74 24                	je     105b64 <pmap_check+0x8a4>
  105b40:	c7 44 24 0c 44 9f 10 	movl   $0x109f44,0xc(%esp)
  105b47:	00 
  105b48:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105b4f:	00 
  105b50:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
  105b57:	00 
  105b58:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105b5f:	e8 ca ac ff ff       	call   10082e <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  105b64:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105b6b:	40 
  105b6c:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105b73:	e8 db f6 ff ff       	call   105253 <va2pa>
  105b78:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  105b7b:	8b 15 58 ed 31 00    	mov    0x31ed58,%edx
  105b81:	89 cb                	mov    %ecx,%ebx
  105b83:	29 d3                	sub    %edx,%ebx
  105b85:	89 da                	mov    %ebx,%edx
  105b87:	c1 fa 03             	sar    $0x3,%edx
  105b8a:	c1 e2 0c             	shl    $0xc,%edx
  105b8d:	39 d0                	cmp    %edx,%eax
  105b8f:	74 24                	je     105bb5 <pmap_check+0x8f5>
  105b91:	c7 44 24 0c cc 9e 10 	movl   $0x109ecc,0xc(%esp)
  105b98:	00 
  105b99:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105ba0:	00 
  105ba1:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
  105ba8:	00 
  105ba9:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105bb0:	e8 79 ac ff ff       	call   10082e <debug_panic>
	assert(pi1->refcount == 1);
  105bb5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105bb8:	8b 40 04             	mov    0x4(%eax),%eax
  105bbb:	83 f8 01             	cmp    $0x1,%eax
  105bbe:	74 24                	je     105be4 <pmap_check+0x924>
  105bc0:	c7 44 24 0c 40 9c 10 	movl   $0x109c40,0xc(%esp)
  105bc7:	00 
  105bc8:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105bcf:	00 
  105bd0:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
  105bd7:	00 
  105bd8:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105bdf:	e8 4a ac ff ff       	call   10082e <debug_panic>
	assert(pi2->refcount == 0);
  105be4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105be7:	8b 40 04             	mov    0x4(%eax),%eax
  105bea:	85 c0                	test   %eax,%eax
  105bec:	74 24                	je     105c12 <pmap_check+0x952>
  105bee:	c7 44 24 0c 1c 9f 10 	movl   $0x109f1c,0xc(%esp)
  105bf5:	00 
  105bf6:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105bfd:	00 
  105bfe:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
  105c05:	00 
  105c06:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105c0d:	e8 1c ac ff ff       	call   10082e <debug_panic>
	assert(mem_alloc() == NULL);	// still should have no pages free
  105c12:	e8 a3 b2 ff ff       	call   100eba <mem_alloc>
  105c17:	85 c0                	test   %eax,%eax
  105c19:	74 24                	je     105c3f <pmap_check+0x97f>
  105c1b:	c7 44 24 0c 4c 9b 10 	movl   $0x109b4c,0xc(%esp)
  105c22:	00 
  105c23:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105c2a:	00 
  105c2b:	c7 44 24 04 60 02 00 	movl   $0x260,0x4(%esp)
  105c32:	00 
  105c33:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105c3a:	e8 ef ab ff ff       	call   10082e <debug_panic>

	// unmapping pi1 at VM_USERLO+PAGESIZE should free it
	pmap_remove(pmap_bootpdir, VM_USERLO+PAGESIZE, PAGESIZE);
  105c3f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105c46:	00 
  105c47:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105c4e:	40 
  105c4f:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105c56:	e8 29 ed ff ff       	call   104984 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  105c5b:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105c62:	40 
  105c63:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105c6a:	e8 e4 f5 ff ff       	call   105253 <va2pa>
  105c6f:	83 f8 ff             	cmp    $0xffffffff,%eax
  105c72:	74 24                	je     105c98 <pmap_check+0x9d8>
  105c74:	c7 44 24 0c 44 9f 10 	movl   $0x109f44,0xc(%esp)
  105c7b:	00 
  105c7c:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105c83:	00 
  105c84:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
  105c8b:	00 
  105c8c:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105c93:	e8 96 ab ff ff       	call   10082e <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == ~0);
  105c98:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105c9f:	40 
  105ca0:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105ca7:	e8 a7 f5 ff ff       	call   105253 <va2pa>
  105cac:	83 f8 ff             	cmp    $0xffffffff,%eax
  105caf:	74 24                	je     105cd5 <pmap_check+0xa15>
  105cb1:	c7 44 24 0c 6c 9f 10 	movl   $0x109f6c,0xc(%esp)
  105cb8:	00 
  105cb9:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105cc0:	00 
  105cc1:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
  105cc8:	00 
  105cc9:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105cd0:	e8 59 ab ff ff       	call   10082e <debug_panic>
	assert(pi1->refcount == 0);
  105cd5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105cd8:	8b 40 04             	mov    0x4(%eax),%eax
  105cdb:	85 c0                	test   %eax,%eax
  105cdd:	74 24                	je     105d03 <pmap_check+0xa43>
  105cdf:	c7 44 24 0c 9b 9f 10 	movl   $0x109f9b,0xc(%esp)
  105ce6:	00 
  105ce7:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105cee:	00 
  105cef:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
  105cf6:	00 
  105cf7:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105cfe:	e8 2b ab ff ff       	call   10082e <debug_panic>
	assert(pi2->refcount == 0);
  105d03:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105d06:	8b 40 04             	mov    0x4(%eax),%eax
  105d09:	85 c0                	test   %eax,%eax
  105d0b:	74 24                	je     105d31 <pmap_check+0xa71>
  105d0d:	c7 44 24 0c 1c 9f 10 	movl   $0x109f1c,0xc(%esp)
  105d14:	00 
  105d15:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105d1c:	00 
  105d1d:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
  105d24:	00 
  105d25:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105d2c:	e8 fd aa ff ff       	call   10082e <debug_panic>

	// so it should be returned by page_alloc
	assert(mem_alloc() == pi1);
  105d31:	e8 84 b1 ff ff       	call   100eba <mem_alloc>
  105d36:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  105d39:	74 24                	je     105d5f <pmap_check+0xa9f>
  105d3b:	c7 44 24 0c ae 9f 10 	movl   $0x109fae,0xc(%esp)
  105d42:	00 
  105d43:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105d4a:	00 
  105d4b:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
  105d52:	00 
  105d53:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105d5a:	e8 cf aa ff ff       	call   10082e <debug_panic>

	// should once again have no free memory
	assert(mem_alloc() == NULL);
  105d5f:	e8 56 b1 ff ff       	call   100eba <mem_alloc>
  105d64:	85 c0                	test   %eax,%eax
  105d66:	74 24                	je     105d8c <pmap_check+0xacc>
  105d68:	c7 44 24 0c 4c 9b 10 	movl   $0x109b4c,0xc(%esp)
  105d6f:	00 
  105d70:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105d77:	00 
  105d78:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
  105d7f:	00 
  105d80:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105d87:	e8 a2 aa ff ff       	call   10082e <debug_panic>

	// should be able to pmap_insert to change a page
	// and see the new data immediately.
	memset(mem_pi2ptr(pi1), 1, PAGESIZE);
  105d8c:	8b 55 d8             	mov    -0x28(%ebp),%edx
  105d8f:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  105d94:	89 d1                	mov    %edx,%ecx
  105d96:	29 c1                	sub    %eax,%ecx
  105d98:	89 c8                	mov    %ecx,%eax
  105d9a:	c1 f8 03             	sar    $0x3,%eax
  105d9d:	c1 e0 0c             	shl    $0xc,%eax
  105da0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105da7:	00 
  105da8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105daf:	00 
  105db0:	89 04 24             	mov    %eax,(%esp)
  105db3:	e8 be 23 00 00       	call   108176 <memset>
	memset(mem_pi2ptr(pi2), 2, PAGESIZE);
  105db8:	8b 55 dc             	mov    -0x24(%ebp),%edx
  105dbb:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  105dc0:	89 d3                	mov    %edx,%ebx
  105dc2:	29 c3                	sub    %eax,%ebx
  105dc4:	89 d8                	mov    %ebx,%eax
  105dc6:	c1 f8 03             	sar    $0x3,%eax
  105dc9:	c1 e0 0c             	shl    $0xc,%eax
  105dcc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105dd3:	00 
  105dd4:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  105ddb:	00 
  105ddc:	89 04 24             	mov    %eax,(%esp)
  105ddf:	e8 92 23 00 00       	call   108176 <memset>
	pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0);
  105de4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105deb:	00 
  105dec:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  105df3:	40 
  105df4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105df7:	89 44 24 04          	mov    %eax,0x4(%esp)
  105dfb:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105e02:	e8 c1 e9 ff ff       	call   1047c8 <pmap_insert>
	assert(pi1->refcount == 1);
  105e07:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105e0a:	8b 40 04             	mov    0x4(%eax),%eax
  105e0d:	83 f8 01             	cmp    $0x1,%eax
  105e10:	74 24                	je     105e36 <pmap_check+0xb76>
  105e12:	c7 44 24 0c 40 9c 10 	movl   $0x109c40,0xc(%esp)
  105e19:	00 
  105e1a:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105e21:	00 
  105e22:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
  105e29:	00 
  105e2a:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105e31:	e8 f8 a9 ff ff       	call   10082e <debug_panic>
	assert(*(int*)VM_USERLO == 0x01010101);
  105e36:	b8 00 00 00 40       	mov    $0x40000000,%eax
  105e3b:	8b 00                	mov    (%eax),%eax
  105e3d:	3d 01 01 01 01       	cmp    $0x1010101,%eax
  105e42:	74 24                	je     105e68 <pmap_check+0xba8>
  105e44:	c7 44 24 0c c4 9f 10 	movl   $0x109fc4,0xc(%esp)
  105e4b:	00 
  105e4c:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105e53:	00 
  105e54:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
  105e5b:	00 
  105e5c:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105e63:	e8 c6 a9 ff ff       	call   10082e <debug_panic>
	//cprintf("===================wrong here:\n");
	pmap_insert(pmap_bootpdir, pi2, VM_USERLO, 0);
  105e68:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105e6f:	00 
  105e70:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  105e77:	40 
  105e78:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105e7b:	89 44 24 04          	mov    %eax,0x4(%esp)
  105e7f:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105e86:	e8 3d e9 ff ff       	call   1047c8 <pmap_insert>
	assert(*(int*)VM_USERLO == 0x02020202);
  105e8b:	b8 00 00 00 40       	mov    $0x40000000,%eax
  105e90:	8b 00                	mov    (%eax),%eax
  105e92:	3d 02 02 02 02       	cmp    $0x2020202,%eax
  105e97:	74 24                	je     105ebd <pmap_check+0xbfd>
  105e99:	c7 44 24 0c e4 9f 10 	movl   $0x109fe4,0xc(%esp)
  105ea0:	00 
  105ea1:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105ea8:	00 
  105ea9:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
  105eb0:	00 
  105eb1:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105eb8:	e8 71 a9 ff ff       	call   10082e <debug_panic>
	assert(pi2->refcount == 1);
  105ebd:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105ec0:	8b 40 04             	mov    0x4(%eax),%eax
  105ec3:	83 f8 01             	cmp    $0x1,%eax
  105ec6:	74 24                	je     105eec <pmap_check+0xc2c>
  105ec8:	c7 44 24 0c dd 9c 10 	movl   $0x109cdd,0xc(%esp)
  105ecf:	00 
  105ed0:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105ed7:	00 
  105ed8:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
  105edf:	00 
  105ee0:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105ee7:	e8 42 a9 ff ff       	call   10082e <debug_panic>
	assert(pi1->refcount == 0);
  105eec:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105eef:	8b 40 04             	mov    0x4(%eax),%eax
  105ef2:	85 c0                	test   %eax,%eax
  105ef4:	74 24                	je     105f1a <pmap_check+0xc5a>
  105ef6:	c7 44 24 0c 9b 9f 10 	movl   $0x109f9b,0xc(%esp)
  105efd:	00 
  105efe:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105f05:	00 
  105f06:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
  105f0d:	00 
  105f0e:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105f15:	e8 14 a9 ff ff       	call   10082e <debug_panic>
	assert(mem_alloc() == pi1);
  105f1a:	e8 9b af ff ff       	call   100eba <mem_alloc>
  105f1f:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  105f22:	74 24                	je     105f48 <pmap_check+0xc88>
  105f24:	c7 44 24 0c ae 9f 10 	movl   $0x109fae,0xc(%esp)
  105f2b:	00 
  105f2c:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105f33:	00 
  105f34:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
  105f3b:	00 
  105f3c:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105f43:	e8 e6 a8 ff ff       	call   10082e <debug_panic>
	pmap_remove(pmap_bootpdir, VM_USERLO, PAGESIZE);
  105f48:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105f4f:	00 
  105f50:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105f57:	40 
  105f58:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105f5f:	e8 20 ea ff ff       	call   104984 <pmap_remove>
	assert(pi2->refcount == 0);
  105f64:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105f67:	8b 40 04             	mov    0x4(%eax),%eax
  105f6a:	85 c0                	test   %eax,%eax
  105f6c:	74 24                	je     105f92 <pmap_check+0xcd2>
  105f6e:	c7 44 24 0c 1c 9f 10 	movl   $0x109f1c,0xc(%esp)
  105f75:	00 
  105f76:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105f7d:	00 
  105f7e:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
  105f85:	00 
  105f86:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105f8d:	e8 9c a8 ff ff       	call   10082e <debug_panic>
	assert(mem_alloc() == pi2);
  105f92:	e8 23 af ff ff       	call   100eba <mem_alloc>
  105f97:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  105f9a:	74 24                	je     105fc0 <pmap_check+0xd00>
  105f9c:	c7 44 24 0c 2f 9f 10 	movl   $0x109f2f,0xc(%esp)
  105fa3:	00 
  105fa4:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105fab:	00 
  105fac:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
  105fb3:	00 
  105fb4:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  105fbb:	e8 6e a8 ff ff       	call   10082e <debug_panic>

	// now use a pmap_remove on a large region to take pi0 back
	//cprintf("===================wrong here:\n");
	pmap_remove(pmap_bootpdir, VM_USERLO, VM_USERHI-VM_USERLO);
  105fc0:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  105fc7:	b0 
  105fc8:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105fcf:	40 
  105fd0:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  105fd7:	e8 a8 e9 ff ff       	call   104984 <pmap_remove>
	assert(pmap_bootpdir[PDX(VM_USERLO)] == PTE_ZERO);
  105fdc:	8b 15 00 04 32 00    	mov    0x320400,%edx
  105fe2:	b8 00 10 32 00       	mov    $0x321000,%eax
  105fe7:	39 c2                	cmp    %eax,%edx
  105fe9:	74 24                	je     10600f <pmap_check+0xd4f>
  105feb:	c7 44 24 0c 04 a0 10 	movl   $0x10a004,0xc(%esp)
  105ff2:	00 
  105ff3:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  105ffa:	00 
  105ffb:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
  106002:	00 
  106003:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10600a:	e8 1f a8 ff ff       	call   10082e <debug_panic>
	assert(pi0->refcount == 0);
  10600f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106012:	8b 40 04             	mov    0x4(%eax),%eax
  106015:	85 c0                	test   %eax,%eax
  106017:	74 24                	je     10603d <pmap_check+0xd7d>
  106019:	c7 44 24 0c 2e a0 10 	movl   $0x10a02e,0xc(%esp)
  106020:	00 
  106021:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106028:	00 
  106029:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
  106030:	00 
  106031:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106038:	e8 f1 a7 ff ff       	call   10082e <debug_panic>
	assert(mem_alloc() == pi0);
  10603d:	e8 78 ae ff ff       	call   100eba <mem_alloc>
  106042:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  106045:	74 24                	je     10606b <pmap_check+0xdab>
  106047:	c7 44 24 0c 41 a0 10 	movl   $0x10a041,0xc(%esp)
  10604e:	00 
  10604f:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106056:	00 
  106057:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
  10605e:	00 
  10605f:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106066:	e8 c3 a7 ff ff       	call   10082e <debug_panic>
	assert(mem_freelist == NULL);
  10606b:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  106070:	85 c0                	test   %eax,%eax
  106072:	74 24                	je     106098 <pmap_check+0xdd8>
  106074:	c7 44 24 0c 54 a0 10 	movl   $0x10a054,0xc(%esp)
  10607b:	00 
  10607c:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106083:	00 
  106084:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
  10608b:	00 
  10608c:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106093:	e8 96 a7 ff ff       	call   10082e <debug_panic>

	// test pmap_remove with large, non-ptable-aligned regions
	mem_free(pi1);
  106098:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10609b:	89 04 24             	mov    %eax,(%esp)
  10609e:	e8 5e ae ff ff       	call   100f01 <mem_free>
	uintptr_t va = VM_USERLO;
  1060a3:	c7 45 f4 00 00 00 40 	movl   $0x40000000,-0xc(%ebp)
	assert(pmap_insert(pmap_bootpdir, pi0, va, 0));
  1060aa:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1060b1:	00 
  1060b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1060b5:	89 44 24 08          	mov    %eax,0x8(%esp)
  1060b9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1060bc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1060c0:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1060c7:	e8 fc e6 ff ff       	call   1047c8 <pmap_insert>
  1060cc:	85 c0                	test   %eax,%eax
  1060ce:	75 24                	jne    1060f4 <pmap_check+0xe34>
  1060d0:	c7 44 24 0c 6c a0 10 	movl   $0x10a06c,0xc(%esp)
  1060d7:	00 
  1060d8:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1060df:	00 
  1060e0:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
  1060e7:	00 
  1060e8:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1060ef:	e8 3a a7 ff ff       	call   10082e <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PAGESIZE, 0));
  1060f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1060f7:	05 00 10 00 00       	add    $0x1000,%eax
  1060fc:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106103:	00 
  106104:	89 44 24 08          	mov    %eax,0x8(%esp)
  106108:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10610b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10610f:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106116:	e8 ad e6 ff ff       	call   1047c8 <pmap_insert>
  10611b:	85 c0                	test   %eax,%eax
  10611d:	75 24                	jne    106143 <pmap_check+0xe83>
  10611f:	c7 44 24 0c 94 a0 10 	movl   $0x10a094,0xc(%esp)
  106126:	00 
  106127:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10612e:	00 
  10612f:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
  106136:	00 
  106137:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10613e:	e8 eb a6 ff ff       	call   10082e <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE-PAGESIZE, 0));
  106143:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106146:	05 00 f0 3f 00       	add    $0x3ff000,%eax
  10614b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106152:	00 
  106153:	89 44 24 08          	mov    %eax,0x8(%esp)
  106157:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10615a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10615e:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106165:	e8 5e e6 ff ff       	call   1047c8 <pmap_insert>
  10616a:	85 c0                	test   %eax,%eax
  10616c:	75 24                	jne    106192 <pmap_check+0xed2>
  10616e:	c7 44 24 0c c4 a0 10 	movl   $0x10a0c4,0xc(%esp)
  106175:	00 
  106176:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10617d:	00 
  10617e:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
  106185:	00 
  106186:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10618d:	e8 9c a6 ff ff       	call   10082e <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi1));
  106192:	a1 00 04 32 00       	mov    0x320400,%eax
  106197:	89 c1                	mov    %eax,%ecx
  106199:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  10619f:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1061a2:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1061a7:	89 d3                	mov    %edx,%ebx
  1061a9:	29 c3                	sub    %eax,%ebx
  1061ab:	89 d8                	mov    %ebx,%eax
  1061ad:	c1 f8 03             	sar    $0x3,%eax
  1061b0:	c1 e0 0c             	shl    $0xc,%eax
  1061b3:	39 c1                	cmp    %eax,%ecx
  1061b5:	74 24                	je     1061db <pmap_check+0xf1b>
  1061b7:	c7 44 24 0c fc a0 10 	movl   $0x10a0fc,0xc(%esp)
  1061be:	00 
  1061bf:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1061c6:	00 
  1061c7:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
  1061ce:	00 
  1061cf:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1061d6:	e8 53 a6 ff ff       	call   10082e <debug_panic>
	assert(mem_freelist == NULL);
  1061db:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  1061e0:	85 c0                	test   %eax,%eax
  1061e2:	74 24                	je     106208 <pmap_check+0xf48>
  1061e4:	c7 44 24 0c 54 a0 10 	movl   $0x10a054,0xc(%esp)
  1061eb:	00 
  1061ec:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1061f3:	00 
  1061f4:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
  1061fb:	00 
  1061fc:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106203:	e8 26 a6 ff ff       	call   10082e <debug_panic>
	mem_free(pi2);
  106208:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10620b:	89 04 24             	mov    %eax,(%esp)
  10620e:	e8 ee ac ff ff       	call   100f01 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE, 0));
  106213:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106216:	05 00 00 40 00       	add    $0x400000,%eax
  10621b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106222:	00 
  106223:	89 44 24 08          	mov    %eax,0x8(%esp)
  106227:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10622a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10622e:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106235:	e8 8e e5 ff ff       	call   1047c8 <pmap_insert>
  10623a:	85 c0                	test   %eax,%eax
  10623c:	75 24                	jne    106262 <pmap_check+0xfa2>
  10623e:	c7 44 24 0c 38 a1 10 	movl   $0x10a138,0xc(%esp)
  106245:	00 
  106246:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10624d:	00 
  10624e:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
  106255:	00 
  106256:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10625d:	e8 cc a5 ff ff       	call   10082e <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE+PAGESIZE, 0));
  106262:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106265:	05 00 10 40 00       	add    $0x401000,%eax
  10626a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106271:	00 
  106272:	89 44 24 08          	mov    %eax,0x8(%esp)
  106276:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106279:	89 44 24 04          	mov    %eax,0x4(%esp)
  10627d:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106284:	e8 3f e5 ff ff       	call   1047c8 <pmap_insert>
  106289:	85 c0                	test   %eax,%eax
  10628b:	75 24                	jne    1062b1 <pmap_check+0xff1>
  10628d:	c7 44 24 0c 68 a1 10 	movl   $0x10a168,0xc(%esp)
  106294:	00 
  106295:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10629c:	00 
  10629d:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
  1062a4:	00 
  1062a5:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1062ac:	e8 7d a5 ff ff       	call   10082e <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2-PAGESIZE, 0));
  1062b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1062b4:	05 00 f0 7f 00       	add    $0x7ff000,%eax
  1062b9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1062c0:	00 
  1062c1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1062c5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1062c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1062cc:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1062d3:	e8 f0 e4 ff ff       	call   1047c8 <pmap_insert>
  1062d8:	85 c0                	test   %eax,%eax
  1062da:	75 24                	jne    106300 <pmap_check+0x1040>
  1062dc:	c7 44 24 0c a0 a1 10 	movl   $0x10a1a0,0xc(%esp)
  1062e3:	00 
  1062e4:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1062eb:	00 
  1062ec:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
  1062f3:	00 
  1062f4:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1062fb:	e8 2e a5 ff ff       	call   10082e <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE)])
  106300:	a1 04 04 32 00       	mov    0x320404,%eax
  106305:	89 c1                	mov    %eax,%ecx
  106307:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  10630d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106310:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  106315:	89 d3                	mov    %edx,%ebx
  106317:	29 c3                	sub    %eax,%ebx
  106319:	89 d8                	mov    %ebx,%eax
  10631b:	c1 f8 03             	sar    $0x3,%eax
  10631e:	c1 e0 0c             	shl    $0xc,%eax
  106321:	39 c1                	cmp    %eax,%ecx
  106323:	74 24                	je     106349 <pmap_check+0x1089>
  106325:	c7 44 24 0c dc a1 10 	movl   $0x10a1dc,0xc(%esp)
  10632c:	00 
  10632d:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106334:	00 
  106335:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
  10633c:	00 
  10633d:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106344:	e8 e5 a4 ff ff       	call   10082e <debug_panic>
		== mem_pi2phys(pi2));
	assert(mem_freelist == NULL);
  106349:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  10634e:	85 c0                	test   %eax,%eax
  106350:	74 24                	je     106376 <pmap_check+0x10b6>
  106352:	c7 44 24 0c 54 a0 10 	movl   $0x10a054,0xc(%esp)
  106359:	00 
  10635a:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106361:	00 
  106362:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
  106369:	00 
  10636a:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106371:	e8 b8 a4 ff ff       	call   10082e <debug_panic>
	mem_free(pi3);
  106376:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106379:	89 04 24             	mov    %eax,(%esp)
  10637c:	e8 80 ab ff ff       	call   100f01 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2, 0));
  106381:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106384:	05 00 00 80 00       	add    $0x800000,%eax
  106389:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106390:	00 
  106391:	89 44 24 08          	mov    %eax,0x8(%esp)
  106395:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106398:	89 44 24 04          	mov    %eax,0x4(%esp)
  10639c:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1063a3:	e8 20 e4 ff ff       	call   1047c8 <pmap_insert>
  1063a8:	85 c0                	test   %eax,%eax
  1063aa:	75 24                	jne    1063d0 <pmap_check+0x1110>
  1063ac:	c7 44 24 0c 20 a2 10 	movl   $0x10a220,0xc(%esp)
  1063b3:	00 
  1063b4:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1063bb:	00 
  1063bc:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
  1063c3:	00 
  1063c4:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1063cb:	e8 5e a4 ff ff       	call   10082e <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2+PAGESIZE, 0));
  1063d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1063d3:	05 00 10 80 00       	add    $0x801000,%eax
  1063d8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1063df:	00 
  1063e0:	89 44 24 08          	mov    %eax,0x8(%esp)
  1063e4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1063e7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1063eb:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1063f2:	e8 d1 e3 ff ff       	call   1047c8 <pmap_insert>
  1063f7:	85 c0                	test   %eax,%eax
  1063f9:	75 24                	jne    10641f <pmap_check+0x115f>
  1063fb:	c7 44 24 0c 50 a2 10 	movl   $0x10a250,0xc(%esp)
  106402:	00 
  106403:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10640a:	00 
  10640b:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
  106412:	00 
  106413:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10641a:	e8 0f a4 ff ff       	call   10082e <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE*2, 0));
  10641f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106422:	05 00 e0 bf 00       	add    $0xbfe000,%eax
  106427:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10642e:	00 
  10642f:	89 44 24 08          	mov    %eax,0x8(%esp)
  106433:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106436:	89 44 24 04          	mov    %eax,0x4(%esp)
  10643a:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106441:	e8 82 e3 ff ff       	call   1047c8 <pmap_insert>
  106446:	85 c0                	test   %eax,%eax
  106448:	75 24                	jne    10646e <pmap_check+0x11ae>
  10644a:	c7 44 24 0c 8c a2 10 	movl   $0x10a28c,0xc(%esp)
  106451:	00 
  106452:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106459:	00 
  10645a:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
  106461:	00 
  106462:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106469:	e8 c0 a3 ff ff       	call   10082e <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE, 0));
  10646e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106471:	05 00 f0 bf 00       	add    $0xbff000,%eax
  106476:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10647d:	00 
  10647e:	89 44 24 08          	mov    %eax,0x8(%esp)
  106482:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106485:	89 44 24 04          	mov    %eax,0x4(%esp)
  106489:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106490:	e8 33 e3 ff ff       	call   1047c8 <pmap_insert>
  106495:	85 c0                	test   %eax,%eax
  106497:	75 24                	jne    1064bd <pmap_check+0x11fd>
  106499:	c7 44 24 0c c8 a2 10 	movl   $0x10a2c8,0xc(%esp)
  1064a0:	00 
  1064a1:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1064a8:	00 
  1064a9:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
  1064b0:	00 
  1064b1:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1064b8:	e8 71 a3 ff ff       	call   10082e <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE*2)])
  1064bd:	a1 08 04 32 00       	mov    0x320408,%eax
  1064c2:	89 c1                	mov    %eax,%ecx
  1064c4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1064ca:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1064cd:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  1064d2:	89 d3                	mov    %edx,%ebx
  1064d4:	29 c3                	sub    %eax,%ebx
  1064d6:	89 d8                	mov    %ebx,%eax
  1064d8:	c1 f8 03             	sar    $0x3,%eax
  1064db:	c1 e0 0c             	shl    $0xc,%eax
  1064de:	39 c1                	cmp    %eax,%ecx
  1064e0:	74 24                	je     106506 <pmap_check+0x1246>
  1064e2:	c7 44 24 0c 04 a3 10 	movl   $0x10a304,0xc(%esp)
  1064e9:	00 
  1064ea:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1064f1:	00 
  1064f2:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
  1064f9:	00 
  1064fa:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106501:	e8 28 a3 ff ff       	call   10082e <debug_panic>
		== mem_pi2phys(pi3));
	assert(mem_freelist == NULL);
  106506:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  10650b:	85 c0                	test   %eax,%eax
  10650d:	74 24                	je     106533 <pmap_check+0x1273>
  10650f:	c7 44 24 0c 54 a0 10 	movl   $0x10a054,0xc(%esp)
  106516:	00 
  106517:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10651e:	00 
  10651f:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
  106526:	00 
  106527:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10652e:	e8 fb a2 ff ff       	call   10082e <debug_panic>
	assert(pi0->refcount == 10);
  106533:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106536:	8b 40 04             	mov    0x4(%eax),%eax
  106539:	83 f8 0a             	cmp    $0xa,%eax
  10653c:	74 24                	je     106562 <pmap_check+0x12a2>
  10653e:	c7 44 24 0c 47 a3 10 	movl   $0x10a347,0xc(%esp)
  106545:	00 
  106546:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10654d:	00 
  10654e:	c7 44 24 04 9f 02 00 	movl   $0x29f,0x4(%esp)
  106555:	00 
  106556:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10655d:	e8 cc a2 ff ff       	call   10082e <debug_panic>
	assert(pi1->refcount == 1);
  106562:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106565:	8b 40 04             	mov    0x4(%eax),%eax
  106568:	83 f8 01             	cmp    $0x1,%eax
  10656b:	74 24                	je     106591 <pmap_check+0x12d1>
  10656d:	c7 44 24 0c 40 9c 10 	movl   $0x109c40,0xc(%esp)
  106574:	00 
  106575:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10657c:	00 
  10657d:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
  106584:	00 
  106585:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10658c:	e8 9d a2 ff ff       	call   10082e <debug_panic>
	assert(pi2->refcount == 1);
  106591:	8b 45 dc             	mov    -0x24(%ebp),%eax
  106594:	8b 40 04             	mov    0x4(%eax),%eax
  106597:	83 f8 01             	cmp    $0x1,%eax
  10659a:	74 24                	je     1065c0 <pmap_check+0x1300>
  10659c:	c7 44 24 0c dd 9c 10 	movl   $0x109cdd,0xc(%esp)
  1065a3:	00 
  1065a4:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1065ab:	00 
  1065ac:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
  1065b3:	00 
  1065b4:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1065bb:	e8 6e a2 ff ff       	call   10082e <debug_panic>
	assert(pi3->refcount == 1);
  1065c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1065c3:	8b 40 04             	mov    0x4(%eax),%eax
  1065c6:	83 f8 01             	cmp    $0x1,%eax
  1065c9:	74 24                	je     1065ef <pmap_check+0x132f>
  1065cb:	c7 44 24 0c 5b a3 10 	movl   $0x10a35b,0xc(%esp)
  1065d2:	00 
  1065d3:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1065da:	00 
  1065db:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
  1065e2:	00 
  1065e3:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1065ea:	e8 3f a2 ff ff       	call   10082e <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3-PAGESIZE*2);
  1065ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1065f2:	05 00 10 00 00       	add    $0x1000,%eax
  1065f7:	c7 44 24 08 00 e0 bf 	movl   $0xbfe000,0x8(%esp)
  1065fe:	00 
  1065ff:	89 44 24 04          	mov    %eax,0x4(%esp)
  106603:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  10660a:	e8 75 e3 ff ff       	call   104984 <pmap_remove>
	assert(pi0->refcount == 2);
  10660f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106612:	8b 40 04             	mov    0x4(%eax),%eax
  106615:	83 f8 02             	cmp    $0x2,%eax
  106618:	74 24                	je     10663e <pmap_check+0x137e>
  10661a:	c7 44 24 0c 6e a3 10 	movl   $0x10a36e,0xc(%esp)
  106621:	00 
  106622:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106629:	00 
  10662a:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
  106631:	00 
  106632:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106639:	e8 f0 a1 ff ff       	call   10082e <debug_panic>
	assert(pi2->refcount == 0); assert(mem_alloc() == pi2);
  10663e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  106641:	8b 40 04             	mov    0x4(%eax),%eax
  106644:	85 c0                	test   %eax,%eax
  106646:	74 24                	je     10666c <pmap_check+0x13ac>
  106648:	c7 44 24 0c 1c 9f 10 	movl   $0x109f1c,0xc(%esp)
  10664f:	00 
  106650:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106657:	00 
  106658:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
  10665f:	00 
  106660:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106667:	e8 c2 a1 ff ff       	call   10082e <debug_panic>
  10666c:	e8 49 a8 ff ff       	call   100eba <mem_alloc>
  106671:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  106674:	74 24                	je     10669a <pmap_check+0x13da>
  106676:	c7 44 24 0c 2f 9f 10 	movl   $0x109f2f,0xc(%esp)
  10667d:	00 
  10667e:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106685:	00 
  106686:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
  10668d:	00 
  10668e:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106695:	e8 94 a1 ff ff       	call   10082e <debug_panic>
	assert(mem_freelist == NULL);
  10669a:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  10669f:	85 c0                	test   %eax,%eax
  1066a1:	74 24                	je     1066c7 <pmap_check+0x1407>
  1066a3:	c7 44 24 0c 54 a0 10 	movl   $0x10a054,0xc(%esp)
  1066aa:	00 
  1066ab:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1066b2:	00 
  1066b3:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
  1066ba:	00 
  1066bb:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1066c2:	e8 67 a1 ff ff       	call   10082e <debug_panic>
	pmap_remove(pmap_bootpdir, va, PTSIZE*3-PAGESIZE);
  1066c7:	c7 44 24 08 00 f0 bf 	movl   $0xbff000,0x8(%esp)
  1066ce:	00 
  1066cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1066d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1066d6:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1066dd:	e8 a2 e2 ff ff       	call   104984 <pmap_remove>
	assert(pi0->refcount == 1);
  1066e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1066e5:	8b 40 04             	mov    0x4(%eax),%eax
  1066e8:	83 f8 01             	cmp    $0x1,%eax
  1066eb:	74 24                	je     106711 <pmap_check+0x1451>
  1066ed:	c7 44 24 0c 53 9c 10 	movl   $0x109c53,0xc(%esp)
  1066f4:	00 
  1066f5:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1066fc:	00 
  1066fd:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
  106704:	00 
  106705:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10670c:	e8 1d a1 ff ff       	call   10082e <debug_panic>
	assert(pi1->refcount == 0); assert(mem_alloc() == pi1);
  106711:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106714:	8b 40 04             	mov    0x4(%eax),%eax
  106717:	85 c0                	test   %eax,%eax
  106719:	74 24                	je     10673f <pmap_check+0x147f>
  10671b:	c7 44 24 0c 9b 9f 10 	movl   $0x109f9b,0xc(%esp)
  106722:	00 
  106723:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  10672a:	00 
  10672b:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
  106732:	00 
  106733:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  10673a:	e8 ef a0 ff ff       	call   10082e <debug_panic>
  10673f:	e8 76 a7 ff ff       	call   100eba <mem_alloc>
  106744:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  106747:	74 24                	je     10676d <pmap_check+0x14ad>
  106749:	c7 44 24 0c ae 9f 10 	movl   $0x109fae,0xc(%esp)
  106750:	00 
  106751:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106758:	00 
  106759:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
  106760:	00 
  106761:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106768:	e8 c1 a0 ff ff       	call   10082e <debug_panic>
	assert(mem_freelist == NULL);
  10676d:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  106772:	85 c0                	test   %eax,%eax
  106774:	74 24                	je     10679a <pmap_check+0x14da>
  106776:	c7 44 24 0c 54 a0 10 	movl   $0x10a054,0xc(%esp)
  10677d:	00 
  10677e:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106785:	00 
  106786:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
  10678d:	00 
  10678e:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106795:	e8 94 a0 ff ff       	call   10082e <debug_panic>
	pmap_remove(pmap_bootpdir, va+PTSIZE*3-PAGESIZE, PAGESIZE);
  10679a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10679d:	05 00 f0 bf 00       	add    $0xbff000,%eax
  1067a2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1067a9:	00 
  1067aa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1067ae:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  1067b5:	e8 ca e1 ff ff       	call   104984 <pmap_remove>
	assert(pi0->refcount == 0);	// pi3 might or might not also be freed
  1067ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1067bd:	8b 40 04             	mov    0x4(%eax),%eax
  1067c0:	85 c0                	test   %eax,%eax
  1067c2:	74 24                	je     1067e8 <pmap_check+0x1528>
  1067c4:	c7 44 24 0c 2e a0 10 	movl   $0x10a02e,0xc(%esp)
  1067cb:	00 
  1067cc:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1067d3:	00 
  1067d4:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
  1067db:	00 
  1067dc:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1067e3:	e8 46 a0 ff ff       	call   10082e <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3);
  1067e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1067eb:	05 00 10 00 00       	add    $0x1000,%eax
  1067f0:	c7 44 24 08 00 00 c0 	movl   $0xc00000,0x8(%esp)
  1067f7:	00 
  1067f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1067fc:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106803:	e8 7c e1 ff ff       	call   104984 <pmap_remove>
	assert(pi3->refcount == 0);
  106808:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10680b:	8b 40 04             	mov    0x4(%eax),%eax
  10680e:	85 c0                	test   %eax,%eax
  106810:	74 24                	je     106836 <pmap_check+0x1576>
  106812:	c7 44 24 0c 81 a3 10 	movl   $0x10a381,0xc(%esp)
  106819:	00 
  10681a:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106821:	00 
  106822:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
  106829:	00 
  10682a:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106831:	e8 f8 9f ff ff       	call   10082e <debug_panic>
	mem_alloc(); mem_alloc();	// collect pi0 and pi3
  106836:	e8 7f a6 ff ff       	call   100eba <mem_alloc>
  10683b:	e8 7a a6 ff ff       	call   100eba <mem_alloc>
	assert(mem_freelist == NULL);
  106840:	a1 00 ed 11 00       	mov    0x11ed00,%eax
  106845:	85 c0                	test   %eax,%eax
  106847:	74 24                	je     10686d <pmap_check+0x15ad>
  106849:	c7 44 24 0c 54 a0 10 	movl   $0x10a054,0xc(%esp)
  106850:	00 
  106851:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  106858:	00 
  106859:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
  106860:	00 
  106861:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  106868:	e8 c1 9f ff ff       	call   10082e <debug_panic>

	// check pointer arithmetic in pmap_walk
	mem_free(pi0);
  10686d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106870:	89 04 24             	mov    %eax,(%esp)
  106873:	e8 89 a6 ff ff       	call   100f01 <mem_free>
	va = VM_USERLO + PAGESIZE*NPTENTRIES + PAGESIZE;
  106878:	c7 45 f4 00 10 40 40 	movl   $0x40401000,-0xc(%ebp)
	ptep = pmap_walk(pmap_bootpdir, va, 1);
  10687f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106886:	00 
  106887:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10688a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10688e:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106895:	e8 33 dd ff ff       	call   1045cd <pmap_walk>
  10689a:	89 45 e8             	mov    %eax,-0x18(%ebp)
	ptep1 = mem_ptr(PGADDR(pmap_bootpdir[PDX(va)]));
  10689d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1068a0:	c1 e8 16             	shr    $0x16,%eax
  1068a3:	8b 04 85 00 00 32 00 	mov    0x320000(,%eax,4),%eax
  1068aa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1068af:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(ptep == ptep1 + PTX(va));
  1068b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1068b5:	c1 e8 0c             	shr    $0xc,%eax
  1068b8:	25 ff 03 00 00       	and    $0x3ff,%eax
  1068bd:	c1 e0 02             	shl    $0x2,%eax
  1068c0:	03 45 ec             	add    -0x14(%ebp),%eax
  1068c3:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1068c6:	74 24                	je     1068ec <pmap_check+0x162c>
  1068c8:	c7 44 24 0c 94 a3 10 	movl   $0x10a394,0xc(%esp)
  1068cf:	00 
  1068d0:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1068d7:	00 
  1068d8:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
  1068df:	00 
  1068e0:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1068e7:	e8 42 9f ff ff       	call   10082e <debug_panic>
	pmap_bootpdir[PDX(va)] = PTE_ZERO;
  1068ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1068ef:	89 c2                	mov    %eax,%edx
  1068f1:	c1 ea 16             	shr    $0x16,%edx
  1068f4:	b8 00 10 32 00       	mov    $0x321000,%eax
  1068f9:	89 04 95 00 00 32 00 	mov    %eax,0x320000(,%edx,4)
	pi0->refcount = 0;
  106900:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106903:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
  10690a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10690d:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  106912:	89 d1                	mov    %edx,%ecx
  106914:	29 c1                	sub    %eax,%ecx
  106916:	89 c8                	mov    %ecx,%eax
  106918:	c1 f8 03             	sar    $0x3,%eax
  10691b:	c1 e0 0c             	shl    $0xc,%eax
  10691e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  106925:	00 
  106926:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  10692d:	00 
  10692e:	89 04 24             	mov    %eax,(%esp)
  106931:	e8 40 18 00 00       	call   108176 <memset>
	mem_free(pi0);
  106936:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106939:	89 04 24             	mov    %eax,(%esp)
  10693c:	e8 c0 a5 ff ff       	call   100f01 <mem_free>
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
  106941:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106948:	00 
  106949:	c7 44 24 04 00 f0 ff 	movl   $0xeffff000,0x4(%esp)
  106950:	ef 
  106951:	c7 04 24 00 00 32 00 	movl   $0x320000,(%esp)
  106958:	e8 70 dc ff ff       	call   1045cd <pmap_walk>
	ptep = mem_pi2ptr(pi0);
  10695d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106960:	a1 58 ed 31 00       	mov    0x31ed58,%eax
  106965:	89 d3                	mov    %edx,%ebx
  106967:	29 c3                	sub    %eax,%ebx
  106969:	89 d8                	mov    %ebx,%eax
  10696b:	c1 f8 03             	sar    $0x3,%eax
  10696e:	c1 e0 0c             	shl    $0xc,%eax
  106971:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for(i=0; i<NPTENTRIES; i++)
  106974:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  10697b:	eb 3c                	jmp    1069b9 <pmap_check+0x16f9>
		assert(ptep[i] == PTE_ZERO);
  10697d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106980:	c1 e0 02             	shl    $0x2,%eax
  106983:	03 45 e8             	add    -0x18(%ebp),%eax
  106986:	8b 10                	mov    (%eax),%edx
  106988:	b8 00 10 32 00       	mov    $0x321000,%eax
  10698d:	39 c2                	cmp    %eax,%edx
  10698f:	74 24                	je     1069b5 <pmap_check+0x16f5>
  106991:	c7 44 24 0c ac a3 10 	movl   $0x10a3ac,0xc(%esp)
  106998:	00 
  106999:	c7 44 24 08 9e 98 10 	movl   $0x10989e,0x8(%esp)
  1069a0:	00 
  1069a1:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
  1069a8:	00 
  1069a9:	c7 04 24 a2 99 10 00 	movl   $0x1099a2,(%esp)
  1069b0:	e8 79 9e ff ff       	call   10082e <debug_panic>
	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
	mem_free(pi0);
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
	ptep = mem_pi2ptr(pi0);
	for(i=0; i<NPTENTRIES; i++)
  1069b5:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1069b9:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
  1069c0:	7e bb                	jle    10697d <pmap_check+0x16bd>
		assert(ptep[i] == PTE_ZERO);
	pmap_bootpdir[PDX(VM_USERHI-PAGESIZE)] = PTE_ZERO;
  1069c2:	b8 00 10 32 00       	mov    $0x321000,%eax
  1069c7:	a3 fc 0e 32 00       	mov    %eax,0x320efc
	pi0->refcount = 0;
  1069cc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1069cf:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// give free list back
	mem_freelist = fl;
  1069d6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1069d9:	a3 00 ed 11 00       	mov    %eax,0x11ed00

	// free the pages we filched
	mem_free(pi0);
  1069de:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1069e1:	89 04 24             	mov    %eax,(%esp)
  1069e4:	e8 18 a5 ff ff       	call   100f01 <mem_free>
	mem_free(pi1);
  1069e9:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1069ec:	89 04 24             	mov    %eax,(%esp)
  1069ef:	e8 0d a5 ff ff       	call   100f01 <mem_free>
	mem_free(pi2);
  1069f4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1069f7:	89 04 24             	mov    %eax,(%esp)
  1069fa:	e8 02 a5 ff ff       	call   100f01 <mem_free>
	mem_free(pi3);
  1069ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106a02:	89 04 24             	mov    %eax,(%esp)
  106a05:	e8 f7 a4 ff ff       	call   100f01 <mem_free>

	cprintf("pmap_check() succeeded!\n");
  106a0a:	c7 04 24 c0 a3 10 00 	movl   $0x10a3c0,(%esp)
  106a11:	e8 7b 15 00 00       	call   107f91 <cprintf>
}
  106a16:	83 c4 44             	add    $0x44,%esp
  106a19:	5b                   	pop    %ebx
  106a1a:	5d                   	pop    %ebp
  106a1b:	c3                   	ret    

00106a1c <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  106a1c:	55                   	push   %ebp
  106a1d:	89 e5                	mov    %esp,%ebp
  106a1f:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  106a22:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  106a29:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106a2c:	0f b7 00             	movzwl (%eax),%eax
  106a2f:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  106a33:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106a36:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  106a3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106a3e:	0f b7 00             	movzwl (%eax),%eax
  106a41:	66 3d 5a a5          	cmp    $0xa55a,%ax
  106a45:	74 13                	je     106a5a <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  106a47:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  106a4e:	c7 05 98 ec 11 00 b4 	movl   $0x3b4,0x11ec98
  106a55:	03 00 00 
  106a58:	eb 14                	jmp    106a6e <video_init+0x52>
	} else {
		*cp = was;
  106a5a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106a5d:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  106a61:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  106a64:	c7 05 98 ec 11 00 d4 	movl   $0x3d4,0x11ec98
  106a6b:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  106a6e:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106a73:	89 45 e8             	mov    %eax,-0x18(%ebp)
  106a76:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106a7a:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  106a7e:	8b 55 e8             	mov    -0x18(%ebp),%edx
  106a81:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  106a82:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106a87:	83 c0 01             	add    $0x1,%eax
  106a8a:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106a8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106a90:	89 c2                	mov    %eax,%edx
  106a92:	ec                   	in     (%dx),%al
  106a93:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  106a96:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  106a9a:	0f b6 c0             	movzbl %al,%eax
  106a9d:	c1 e0 08             	shl    $0x8,%eax
  106aa0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  106aa3:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106aa8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  106aab:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106aaf:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106ab3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106ab6:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  106ab7:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106abc:	83 c0 01             	add    $0x1,%eax
  106abf:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106ac2:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106ac5:	89 c2                	mov    %eax,%edx
  106ac7:	ec                   	in     (%dx),%al
  106ac8:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  106acb:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  106acf:	0f b6 c0             	movzbl %al,%eax
  106ad2:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  106ad5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106ad8:	a3 9c ec 11 00       	mov    %eax,0x11ec9c
	crt_pos = pos;
  106add:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106ae0:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
}
  106ae6:	c9                   	leave  
  106ae7:	c3                   	ret    

00106ae8 <video_putc>:



void
video_putc(int c)
{
  106ae8:	55                   	push   %ebp
  106ae9:	89 e5                	mov    %esp,%ebp
  106aeb:	53                   	push   %ebx
  106aec:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  106aef:	8b 45 08             	mov    0x8(%ebp),%eax
  106af2:	b0 00                	mov    $0x0,%al
  106af4:	85 c0                	test   %eax,%eax
  106af6:	75 07                	jne    106aff <video_putc+0x17>
		c |= 0x0700;
  106af8:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  106aff:	8b 45 08             	mov    0x8(%ebp),%eax
  106b02:	25 ff 00 00 00       	and    $0xff,%eax
  106b07:	83 f8 09             	cmp    $0x9,%eax
  106b0a:	0f 84 ae 00 00 00    	je     106bbe <video_putc+0xd6>
  106b10:	83 f8 09             	cmp    $0x9,%eax
  106b13:	7f 0a                	jg     106b1f <video_putc+0x37>
  106b15:	83 f8 08             	cmp    $0x8,%eax
  106b18:	74 14                	je     106b2e <video_putc+0x46>
  106b1a:	e9 dd 00 00 00       	jmp    106bfc <video_putc+0x114>
  106b1f:	83 f8 0a             	cmp    $0xa,%eax
  106b22:	74 4e                	je     106b72 <video_putc+0x8a>
  106b24:	83 f8 0d             	cmp    $0xd,%eax
  106b27:	74 59                	je     106b82 <video_putc+0x9a>
  106b29:	e9 ce 00 00 00       	jmp    106bfc <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  106b2e:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106b35:	66 85 c0             	test   %ax,%ax
  106b38:	0f 84 e4 00 00 00    	je     106c22 <video_putc+0x13a>
			crt_pos--;
  106b3e:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106b45:	83 e8 01             	sub    $0x1,%eax
  106b48:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  106b4e:	a1 9c ec 11 00       	mov    0x11ec9c,%eax
  106b53:	0f b7 15 a0 ec 11 00 	movzwl 0x11eca0,%edx
  106b5a:	0f b7 d2             	movzwl %dx,%edx
  106b5d:	01 d2                	add    %edx,%edx
  106b5f:	8d 14 10             	lea    (%eax,%edx,1),%edx
  106b62:	8b 45 08             	mov    0x8(%ebp),%eax
  106b65:	b0 00                	mov    $0x0,%al
  106b67:	83 c8 20             	or     $0x20,%eax
  106b6a:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  106b6d:	e9 b1 00 00 00       	jmp    106c23 <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  106b72:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106b79:	83 c0 50             	add    $0x50,%eax
  106b7c:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  106b82:	0f b7 1d a0 ec 11 00 	movzwl 0x11eca0,%ebx
  106b89:	0f b7 0d a0 ec 11 00 	movzwl 0x11eca0,%ecx
  106b90:	0f b7 c1             	movzwl %cx,%eax
  106b93:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  106b99:	c1 e8 10             	shr    $0x10,%eax
  106b9c:	89 c2                	mov    %eax,%edx
  106b9e:	66 c1 ea 06          	shr    $0x6,%dx
  106ba2:	89 d0                	mov    %edx,%eax
  106ba4:	c1 e0 02             	shl    $0x2,%eax
  106ba7:	01 d0                	add    %edx,%eax
  106ba9:	c1 e0 04             	shl    $0x4,%eax
  106bac:	89 ca                	mov    %ecx,%edx
  106bae:	66 29 c2             	sub    %ax,%dx
  106bb1:	89 d8                	mov    %ebx,%eax
  106bb3:	66 29 d0             	sub    %dx,%ax
  106bb6:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
		break;
  106bbc:	eb 65                	jmp    106c23 <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  106bbe:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  106bc5:	e8 1e ff ff ff       	call   106ae8 <video_putc>
		video_putc(' ');
  106bca:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  106bd1:	e8 12 ff ff ff       	call   106ae8 <video_putc>
		video_putc(' ');
  106bd6:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  106bdd:	e8 06 ff ff ff       	call   106ae8 <video_putc>
		video_putc(' ');
  106be2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  106be9:	e8 fa fe ff ff       	call   106ae8 <video_putc>
		video_putc(' ');
  106bee:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  106bf5:	e8 ee fe ff ff       	call   106ae8 <video_putc>
		break;
  106bfa:	eb 27                	jmp    106c23 <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  106bfc:	8b 15 9c ec 11 00    	mov    0x11ec9c,%edx
  106c02:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106c09:	0f b7 c8             	movzwl %ax,%ecx
  106c0c:	01 c9                	add    %ecx,%ecx
  106c0e:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  106c11:	8b 55 08             	mov    0x8(%ebp),%edx
  106c14:	66 89 11             	mov    %dx,(%ecx)
  106c17:	83 c0 01             	add    $0x1,%eax
  106c1a:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
  106c20:	eb 01                	jmp    106c23 <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  106c22:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  106c23:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106c2a:	66 3d cf 07          	cmp    $0x7cf,%ax
  106c2e:	76 5b                	jbe    106c8b <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  106c30:	a1 9c ec 11 00       	mov    0x11ec9c,%eax
  106c35:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  106c3b:	a1 9c ec 11 00       	mov    0x11ec9c,%eax
  106c40:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  106c47:	00 
  106c48:	89 54 24 04          	mov    %edx,0x4(%esp)
  106c4c:	89 04 24             	mov    %eax,(%esp)
  106c4f:	e8 96 15 00 00       	call   1081ea <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  106c54:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  106c5b:	eb 15                	jmp    106c72 <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  106c5d:	a1 9c ec 11 00       	mov    0x11ec9c,%eax
  106c62:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106c65:	01 d2                	add    %edx,%edx
  106c67:	01 d0                	add    %edx,%eax
  106c69:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  106c6e:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  106c72:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  106c79:	7e e2                	jle    106c5d <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  106c7b:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106c82:	83 e8 50             	sub    $0x50,%eax
  106c85:	66 a3 a0 ec 11 00    	mov    %ax,0x11eca0
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  106c8b:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106c90:	89 45 dc             	mov    %eax,-0x24(%ebp)
  106c93:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106c97:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  106c9b:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106c9e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  106c9f:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106ca6:	66 c1 e8 08          	shr    $0x8,%ax
  106caa:	0f b6 c0             	movzbl %al,%eax
  106cad:	8b 15 98 ec 11 00    	mov    0x11ec98,%edx
  106cb3:	83 c2 01             	add    $0x1,%edx
  106cb6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  106cb9:	88 45 e3             	mov    %al,-0x1d(%ebp)
  106cbc:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106cc0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  106cc3:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  106cc4:	a1 98 ec 11 00       	mov    0x11ec98,%eax
  106cc9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  106ccc:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  106cd0:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  106cd4:	8b 55 ec             	mov    -0x14(%ebp),%edx
  106cd7:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  106cd8:	0f b7 05 a0 ec 11 00 	movzwl 0x11eca0,%eax
  106cdf:	0f b6 c0             	movzbl %al,%eax
  106ce2:	8b 15 98 ec 11 00    	mov    0x11ec98,%edx
  106ce8:	83 c2 01             	add    $0x1,%edx
  106ceb:	89 55 f4             	mov    %edx,-0xc(%ebp)
  106cee:	88 45 f3             	mov    %al,-0xd(%ebp)
  106cf1:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106cf5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106cf8:	ee                   	out    %al,(%dx)
}
  106cf9:	83 c4 44             	add    $0x44,%esp
  106cfc:	5b                   	pop    %ebx
  106cfd:	5d                   	pop    %ebp
  106cfe:	c3                   	ret    

00106cff <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  106cff:	55                   	push   %ebp
  106d00:	89 e5                	mov    %esp,%ebp
  106d02:	83 ec 38             	sub    $0x38,%esp
  106d05:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106d0c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106d0f:	89 c2                	mov    %eax,%edx
  106d11:	ec                   	in     (%dx),%al
  106d12:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  106d15:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  106d19:	0f b6 c0             	movzbl %al,%eax
  106d1c:	83 e0 01             	and    $0x1,%eax
  106d1f:	85 c0                	test   %eax,%eax
  106d21:	75 0a                	jne    106d2d <kbd_proc_data+0x2e>
		return -1;
  106d23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  106d28:	e9 5a 01 00 00       	jmp    106e87 <kbd_proc_data+0x188>
  106d2d:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106d34:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106d37:	89 c2                	mov    %eax,%edx
  106d39:	ec                   	in     (%dx),%al
  106d3a:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  106d3d:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  106d41:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  106d44:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  106d48:	75 17                	jne    106d61 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  106d4a:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106d4f:	83 c8 40             	or     $0x40,%eax
  106d52:	a3 a4 ec 11 00       	mov    %eax,0x11eca4
		return 0;
  106d57:	b8 00 00 00 00       	mov    $0x0,%eax
  106d5c:	e9 26 01 00 00       	jmp    106e87 <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  106d61:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106d65:	84 c0                	test   %al,%al
  106d67:	79 47                	jns    106db0 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  106d69:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106d6e:	83 e0 40             	and    $0x40,%eax
  106d71:	85 c0                	test   %eax,%eax
  106d73:	75 09                	jne    106d7e <kbd_proc_data+0x7f>
  106d75:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106d79:	83 e0 7f             	and    $0x7f,%eax
  106d7c:	eb 04                	jmp    106d82 <kbd_proc_data+0x83>
  106d7e:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106d82:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  106d85:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106d89:	0f b6 80 20 c1 10 00 	movzbl 0x10c120(%eax),%eax
  106d90:	83 c8 40             	or     $0x40,%eax
  106d93:	0f b6 c0             	movzbl %al,%eax
  106d96:	f7 d0                	not    %eax
  106d98:	89 c2                	mov    %eax,%edx
  106d9a:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106d9f:	21 d0                	and    %edx,%eax
  106da1:	a3 a4 ec 11 00       	mov    %eax,0x11eca4
		return 0;
  106da6:	b8 00 00 00 00       	mov    $0x0,%eax
  106dab:	e9 d7 00 00 00       	jmp    106e87 <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  106db0:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106db5:	83 e0 40             	and    $0x40,%eax
  106db8:	85 c0                	test   %eax,%eax
  106dba:	74 11                	je     106dcd <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  106dbc:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  106dc0:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106dc5:	83 e0 bf             	and    $0xffffffbf,%eax
  106dc8:	a3 a4 ec 11 00       	mov    %eax,0x11eca4
	}

	shift |= shiftcode[data];
  106dcd:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106dd1:	0f b6 80 20 c1 10 00 	movzbl 0x10c120(%eax),%eax
  106dd8:	0f b6 d0             	movzbl %al,%edx
  106ddb:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106de0:	09 d0                	or     %edx,%eax
  106de2:	a3 a4 ec 11 00       	mov    %eax,0x11eca4
	shift ^= togglecode[data];
  106de7:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106deb:	0f b6 80 20 c2 10 00 	movzbl 0x10c220(%eax),%eax
  106df2:	0f b6 d0             	movzbl %al,%edx
  106df5:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106dfa:	31 d0                	xor    %edx,%eax
  106dfc:	a3 a4 ec 11 00       	mov    %eax,0x11eca4

	c = charcode[shift & (CTL | SHIFT)][data];
  106e01:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106e06:	83 e0 03             	and    $0x3,%eax
  106e09:	8b 14 85 20 c6 10 00 	mov    0x10c620(,%eax,4),%edx
  106e10:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106e14:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106e17:	0f b6 00             	movzbl (%eax),%eax
  106e1a:	0f b6 c0             	movzbl %al,%eax
  106e1d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  106e20:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106e25:	83 e0 08             	and    $0x8,%eax
  106e28:	85 c0                	test   %eax,%eax
  106e2a:	74 22                	je     106e4e <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  106e2c:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  106e30:	7e 0c                	jle    106e3e <kbd_proc_data+0x13f>
  106e32:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  106e36:	7f 06                	jg     106e3e <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  106e38:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  106e3c:	eb 10                	jmp    106e4e <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  106e3e:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  106e42:	7e 0a                	jle    106e4e <kbd_proc_data+0x14f>
  106e44:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  106e48:	7f 04                	jg     106e4e <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  106e4a:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  106e4e:	a1 a4 ec 11 00       	mov    0x11eca4,%eax
  106e53:	f7 d0                	not    %eax
  106e55:	83 e0 06             	and    $0x6,%eax
  106e58:	85 c0                	test   %eax,%eax
  106e5a:	75 28                	jne    106e84 <kbd_proc_data+0x185>
  106e5c:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  106e63:	75 1f                	jne    106e84 <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  106e65:	c7 04 24 d9 a3 10 00 	movl   $0x10a3d9,(%esp)
  106e6c:	e8 20 11 00 00       	call   107f91 <cprintf>
  106e71:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  106e78:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106e7c:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106e80:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106e83:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  106e84:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  106e87:	c9                   	leave  
  106e88:	c3                   	ret    

00106e89 <kbd_intr>:

void
kbd_intr(void)
{
  106e89:	55                   	push   %ebp
  106e8a:	89 e5                	mov    %esp,%ebp
  106e8c:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  106e8f:	c7 04 24 ff 6c 10 00 	movl   $0x106cff,(%esp)
  106e96:	e8 c8 97 ff ff       	call   100663 <cons_intr>
}
  106e9b:	c9                   	leave  
  106e9c:	c3                   	ret    

00106e9d <kbd_init>:

void
kbd_init(void)
{
  106e9d:	55                   	push   %ebp
  106e9e:	89 e5                	mov    %esp,%ebp
}
  106ea0:	5d                   	pop    %ebp
  106ea1:	c3                   	ret    

00106ea2 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  106ea2:	55                   	push   %ebp
  106ea3:	89 e5                	mov    %esp,%ebp
  106ea5:	83 ec 20             	sub    $0x20,%esp
  106ea8:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106eaf:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106eb2:	89 c2                	mov    %eax,%edx
  106eb4:	ec                   	in     (%dx),%al
  106eb5:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  106eb8:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106ebf:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106ec2:	89 c2                	mov    %eax,%edx
  106ec4:	ec                   	in     (%dx),%al
  106ec5:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  106ec8:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106ecf:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106ed2:	89 c2                	mov    %eax,%edx
  106ed4:	ec                   	in     (%dx),%al
  106ed5:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  106ed8:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106edf:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106ee2:	89 c2                	mov    %eax,%edx
  106ee4:	ec                   	in     (%dx),%al
  106ee5:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  106ee8:	c9                   	leave  
  106ee9:	c3                   	ret    

00106eea <serial_proc_data>:

static int
serial_proc_data(void)
{
  106eea:	55                   	push   %ebp
  106eeb:	89 e5                	mov    %esp,%ebp
  106eed:	83 ec 10             	sub    $0x10,%esp
  106ef0:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  106ef7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106efa:	89 c2                	mov    %eax,%edx
  106efc:	ec                   	in     (%dx),%al
  106efd:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  106f00:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  106f04:	0f b6 c0             	movzbl %al,%eax
  106f07:	83 e0 01             	and    $0x1,%eax
  106f0a:	85 c0                	test   %eax,%eax
  106f0c:	75 07                	jne    106f15 <serial_proc_data+0x2b>
		return -1;
  106f0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  106f13:	eb 17                	jmp    106f2c <serial_proc_data+0x42>
  106f15:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106f1c:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106f1f:	89 c2                	mov    %eax,%edx
  106f21:	ec                   	in     (%dx),%al
  106f22:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  106f25:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  106f29:	0f b6 c0             	movzbl %al,%eax
}
  106f2c:	c9                   	leave  
  106f2d:	c3                   	ret    

00106f2e <serial_intr>:

void
serial_intr(void)
{
  106f2e:	55                   	push   %ebp
  106f2f:	89 e5                	mov    %esp,%ebp
  106f31:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  106f34:	a1 00 20 32 00       	mov    0x322000,%eax
  106f39:	85 c0                	test   %eax,%eax
  106f3b:	74 0c                	je     106f49 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  106f3d:	c7 04 24 ea 6e 10 00 	movl   $0x106eea,(%esp)
  106f44:	e8 1a 97 ff ff       	call   100663 <cons_intr>
}
  106f49:	c9                   	leave  
  106f4a:	c3                   	ret    

00106f4b <serial_putc>:

void
serial_putc(int c)
{
  106f4b:	55                   	push   %ebp
  106f4c:	89 e5                	mov    %esp,%ebp
  106f4e:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  106f51:	a1 00 20 32 00       	mov    0x322000,%eax
  106f56:	85 c0                	test   %eax,%eax
  106f58:	74 53                	je     106fad <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  106f5a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  106f61:	eb 09                	jmp    106f6c <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  106f63:	e8 3a ff ff ff       	call   106ea2 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  106f68:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  106f6c:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106f73:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106f76:	89 c2                	mov    %eax,%edx
  106f78:	ec                   	in     (%dx),%al
  106f79:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  106f7c:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  106f80:	0f b6 c0             	movzbl %al,%eax
  106f83:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  106f86:	85 c0                	test   %eax,%eax
  106f88:	75 09                	jne    106f93 <serial_putc+0x48>
  106f8a:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  106f91:	7e d0                	jle    106f63 <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  106f93:	8b 45 08             	mov    0x8(%ebp),%eax
  106f96:	0f b6 c0             	movzbl %al,%eax
  106f99:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  106fa0:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106fa3:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106fa7:	8b 55 fc             	mov    -0x4(%ebp),%edx
  106faa:	ee                   	out    %al,(%dx)
  106fab:	eb 01                	jmp    106fae <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  106fad:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  106fae:	c9                   	leave  
  106faf:	c3                   	ret    

00106fb0 <serial_init>:

void
serial_init(void)
{
  106fb0:	55                   	push   %ebp
  106fb1:	89 e5                	mov    %esp,%ebp
  106fb3:	83 ec 50             	sub    $0x50,%esp
  106fb6:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  106fbd:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  106fc1:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  106fc5:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  106fc8:	ee                   	out    %al,(%dx)
  106fc9:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  106fd0:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  106fd4:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  106fd8:	8b 55 bc             	mov    -0x44(%ebp),%edx
  106fdb:	ee                   	out    %al,(%dx)
  106fdc:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  106fe3:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  106fe7:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  106feb:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  106fee:	ee                   	out    %al,(%dx)
  106fef:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  106ff6:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  106ffa:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  106ffe:	8b 55 cc             	mov    -0x34(%ebp),%edx
  107001:	ee                   	out    %al,(%dx)
  107002:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  107009:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  10700d:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  107011:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  107014:	ee                   	out    %al,(%dx)
  107015:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  10701c:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  107020:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  107024:	8b 55 dc             	mov    -0x24(%ebp),%edx
  107027:	ee                   	out    %al,(%dx)
  107028:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  10702f:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  107033:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  107037:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10703a:	ee                   	out    %al,(%dx)
  10703b:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  107042:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107045:	89 c2                	mov    %eax,%edx
  107047:	ec                   	in     (%dx),%al
  107048:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  10704b:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  10704f:	3c ff                	cmp    $0xff,%al
  107051:	0f 95 c0             	setne  %al
  107054:	0f b6 c0             	movzbl %al,%eax
  107057:	a3 00 20 32 00       	mov    %eax,0x322000
  10705c:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  107063:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107066:	89 c2                	mov    %eax,%edx
  107068:	ec                   	in     (%dx),%al
  107069:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  10706c:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  107073:	8b 45 f8             	mov    -0x8(%ebp),%eax
  107076:	89 c2                	mov    %eax,%edx
  107078:	ec                   	in     (%dx),%al
  107079:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  10707c:	c9                   	leave  
  10707d:	c3                   	ret    

0010707e <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  10707e:	55                   	push   %ebp
  10707f:	89 e5                	mov    %esp,%ebp
  107081:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  107087:	a1 a8 ec 11 00       	mov    0x11eca8,%eax
  10708c:	85 c0                	test   %eax,%eax
  10708e:	0f 85 35 01 00 00    	jne    1071c9 <pic_init+0x14b>
		return;
	didinit = 1;
  107094:	c7 05 a8 ec 11 00 01 	movl   $0x1,0x11eca8
  10709b:	00 00 00 
  10709e:	c7 45 8c 21 00 00 00 	movl   $0x21,-0x74(%ebp)
  1070a5:	c6 45 8b ff          	movb   $0xff,-0x75(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1070a9:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  1070ad:	8b 55 8c             	mov    -0x74(%ebp),%edx
  1070b0:	ee                   	out    %al,(%dx)
  1070b1:	c7 45 94 a1 00 00 00 	movl   $0xa1,-0x6c(%ebp)
  1070b8:	c6 45 93 ff          	movb   $0xff,-0x6d(%ebp)
  1070bc:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  1070c0:	8b 55 94             	mov    -0x6c(%ebp),%edx
  1070c3:	ee                   	out    %al,(%dx)
  1070c4:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  1070cb:	c6 45 9b 11          	movb   $0x11,-0x65(%ebp)
  1070cf:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  1070d3:	8b 55 9c             	mov    -0x64(%ebp),%edx
  1070d6:	ee                   	out    %al,(%dx)
  1070d7:	c7 45 a4 21 00 00 00 	movl   $0x21,-0x5c(%ebp)
  1070de:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
  1070e2:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  1070e6:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  1070e9:	ee                   	out    %al,(%dx)
  1070ea:	c7 45 ac 21 00 00 00 	movl   $0x21,-0x54(%ebp)
  1070f1:	c6 45 ab 04          	movb   $0x4,-0x55(%ebp)
  1070f5:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  1070f9:	8b 55 ac             	mov    -0x54(%ebp),%edx
  1070fc:	ee                   	out    %al,(%dx)
  1070fd:	c7 45 b4 21 00 00 00 	movl   $0x21,-0x4c(%ebp)
  107104:	c6 45 b3 03          	movb   $0x3,-0x4d(%ebp)
  107108:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  10710c:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  10710f:	ee                   	out    %al,(%dx)
  107110:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
  107117:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
  10711b:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  10711f:	8b 55 bc             	mov    -0x44(%ebp),%edx
  107122:	ee                   	out    %al,(%dx)
  107123:	c7 45 c4 a1 00 00 00 	movl   $0xa1,-0x3c(%ebp)
  10712a:	c6 45 c3 28          	movb   $0x28,-0x3d(%ebp)
  10712e:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  107132:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  107135:	ee                   	out    %al,(%dx)
  107136:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
  10713d:	c6 45 cb 02          	movb   $0x2,-0x35(%ebp)
  107141:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  107145:	8b 55 cc             	mov    -0x34(%ebp),%edx
  107148:	ee                   	out    %al,(%dx)
  107149:	c7 45 d4 a1 00 00 00 	movl   $0xa1,-0x2c(%ebp)
  107150:	c6 45 d3 01          	movb   $0x1,-0x2d(%ebp)
  107154:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  107158:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10715b:	ee                   	out    %al,(%dx)
  10715c:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
  107163:	c6 45 db 68          	movb   $0x68,-0x25(%ebp)
  107167:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  10716b:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10716e:	ee                   	out    %al,(%dx)
  10716f:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  107176:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  10717a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10717e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  107181:	ee                   	out    %al,(%dx)
  107182:	c7 45 ec a0 00 00 00 	movl   $0xa0,-0x14(%ebp)
  107189:	c6 45 eb 68          	movb   $0x68,-0x15(%ebp)
  10718d:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  107191:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107194:	ee                   	out    %al,(%dx)
  107195:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
  10719c:	c6 45 f3 0a          	movb   $0xa,-0xd(%ebp)
  1071a0:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1071a4:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1071a7:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  1071a8:	0f b7 05 30 c6 10 00 	movzwl 0x10c630,%eax
  1071af:	66 83 f8 ff          	cmp    $0xffff,%ax
  1071b3:	74 15                	je     1071ca <pic_init+0x14c>
		pic_setmask(irqmask);
  1071b5:	0f b7 05 30 c6 10 00 	movzwl 0x10c630,%eax
  1071bc:	0f b7 c0             	movzwl %ax,%eax
  1071bf:	89 04 24             	mov    %eax,(%esp)
  1071c2:	e8 05 00 00 00       	call   1071cc <pic_setmask>
  1071c7:	eb 01                	jmp    1071ca <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  1071c9:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  1071ca:	c9                   	leave  
  1071cb:	c3                   	ret    

001071cc <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  1071cc:	55                   	push   %ebp
  1071cd:	89 e5                	mov    %esp,%ebp
  1071cf:	83 ec 14             	sub    $0x14,%esp
  1071d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1071d5:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  1071d9:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1071dd:	66 a3 30 c6 10 00    	mov    %ax,0x10c630
	outb(IO_PIC1+1, (char)mask);
  1071e3:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  1071e7:	0f b6 c0             	movzbl %al,%eax
  1071ea:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  1071f1:	88 45 f3             	mov    %al,-0xd(%ebp)
  1071f4:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1071f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1071fb:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  1071fc:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  107200:	66 c1 e8 08          	shr    $0x8,%ax
  107204:	0f b6 c0             	movzbl %al,%eax
  107207:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
  10720e:	88 45 fb             	mov    %al,-0x5(%ebp)
  107211:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  107215:	8b 55 fc             	mov    -0x4(%ebp),%edx
  107218:	ee                   	out    %al,(%dx)
}
  107219:	c9                   	leave  
  10721a:	c3                   	ret    

0010721b <pic_enable>:

void
pic_enable(int irq)
{
  10721b:	55                   	push   %ebp
  10721c:	89 e5                	mov    %esp,%ebp
  10721e:	53                   	push   %ebx
  10721f:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  107222:	8b 45 08             	mov    0x8(%ebp),%eax
  107225:	ba 01 00 00 00       	mov    $0x1,%edx
  10722a:	89 d3                	mov    %edx,%ebx
  10722c:	89 c1                	mov    %eax,%ecx
  10722e:	d3 e3                	shl    %cl,%ebx
  107230:	89 d8                	mov    %ebx,%eax
  107232:	89 c2                	mov    %eax,%edx
  107234:	f7 d2                	not    %edx
  107236:	0f b7 05 30 c6 10 00 	movzwl 0x10c630,%eax
  10723d:	21 d0                	and    %edx,%eax
  10723f:	0f b7 c0             	movzwl %ax,%eax
  107242:	89 04 24             	mov    %eax,(%esp)
  107245:	e8 82 ff ff ff       	call   1071cc <pic_setmask>
}
  10724a:	83 c4 04             	add    $0x4,%esp
  10724d:	5b                   	pop    %ebx
  10724e:	5d                   	pop    %ebp
  10724f:	c3                   	ret    

00107250 <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  107250:	55                   	push   %ebp
  107251:	89 e5                	mov    %esp,%ebp
  107253:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  107256:	8b 45 08             	mov    0x8(%ebp),%eax
  107259:	0f b6 c0             	movzbl %al,%eax
  10725c:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  107263:	88 45 f3             	mov    %al,-0xd(%ebp)
  107266:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10726a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10726d:	ee                   	out    %al,(%dx)
  10726e:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  107275:	8b 45 f8             	mov    -0x8(%ebp),%eax
  107278:	89 c2                	mov    %eax,%edx
  10727a:	ec                   	in     (%dx),%al
  10727b:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  10727e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  107282:	0f b6 c0             	movzbl %al,%eax
}
  107285:	c9                   	leave  
  107286:	c3                   	ret    

00107287 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  107287:	55                   	push   %ebp
  107288:	89 e5                	mov    %esp,%ebp
  10728a:	53                   	push   %ebx
  10728b:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  10728e:	8b 45 08             	mov    0x8(%ebp),%eax
  107291:	89 04 24             	mov    %eax,(%esp)
  107294:	e8 b7 ff ff ff       	call   107250 <nvram_read>
  107299:	89 c3                	mov    %eax,%ebx
  10729b:	8b 45 08             	mov    0x8(%ebp),%eax
  10729e:	83 c0 01             	add    $0x1,%eax
  1072a1:	89 04 24             	mov    %eax,(%esp)
  1072a4:	e8 a7 ff ff ff       	call   107250 <nvram_read>
  1072a9:	c1 e0 08             	shl    $0x8,%eax
  1072ac:	09 d8                	or     %ebx,%eax
}
  1072ae:	83 c4 04             	add    $0x4,%esp
  1072b1:	5b                   	pop    %ebx
  1072b2:	5d                   	pop    %ebp
  1072b3:	c3                   	ret    

001072b4 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  1072b4:	55                   	push   %ebp
  1072b5:	89 e5                	mov    %esp,%ebp
  1072b7:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  1072ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1072bd:	0f b6 c0             	movzbl %al,%eax
  1072c0:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  1072c7:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1072ca:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1072ce:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1072d1:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  1072d2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1072d5:	0f b6 c0             	movzbl %al,%eax
  1072d8:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  1072df:	88 45 fb             	mov    %al,-0x5(%ebp)
  1072e2:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1072e6:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1072e9:	ee                   	out    %al,(%dx)
}
  1072ea:	c9                   	leave  
  1072eb:	c3                   	ret    

001072ec <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1072ec:	55                   	push   %ebp
  1072ed:	89 e5                	mov    %esp,%ebp
  1072ef:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1072f2:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1072f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1072f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1072fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1072fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107303:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  107306:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107309:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10730f:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  107314:	74 24                	je     10733a <cpu_cur+0x4e>
  107316:	c7 44 24 0c e5 a3 10 	movl   $0x10a3e5,0xc(%esp)
  10731d:	00 
  10731e:	c7 44 24 08 fb a3 10 	movl   $0x10a3fb,0x8(%esp)
  107325:	00 
  107326:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10732d:	00 
  10732e:	c7 04 24 10 a4 10 00 	movl   $0x10a410,(%esp)
  107335:	e8 f4 94 ff ff       	call   10082e <debug_panic>
	return c;
  10733a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10733d:	c9                   	leave  
  10733e:	c3                   	ret    

0010733f <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  10733f:	55                   	push   %ebp
  107340:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  107342:	a1 04 20 32 00       	mov    0x322004,%eax
  107347:	8b 55 08             	mov    0x8(%ebp),%edx
  10734a:	c1 e2 02             	shl    $0x2,%edx
  10734d:	8d 14 10             	lea    (%eax,%edx,1),%edx
  107350:	8b 45 0c             	mov    0xc(%ebp),%eax
  107353:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  107355:	a1 04 20 32 00       	mov    0x322004,%eax
  10735a:	83 c0 20             	add    $0x20,%eax
  10735d:	8b 00                	mov    (%eax),%eax
}
  10735f:	5d                   	pop    %ebp
  107360:	c3                   	ret    

00107361 <lapic_init>:

void
lapic_init()
{
  107361:	55                   	push   %ebp
  107362:	89 e5                	mov    %esp,%ebp
  107364:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  107367:	a1 04 20 32 00       	mov    0x322004,%eax
  10736c:	85 c0                	test   %eax,%eax
  10736e:	0f 84 82 01 00 00    	je     1074f6 <lapic_init+0x195>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  107374:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  10737b:	00 
  10737c:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  107383:	e8 b7 ff ff ff       	call   10733f <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  107388:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  10738f:	00 
  107390:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  107397:	e8 a3 ff ff ff       	call   10733f <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  10739c:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  1073a3:	00 
  1073a4:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1073ab:	e8 8f ff ff ff       	call   10733f <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  1073b0:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  1073b7:	00 
  1073b8:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  1073bf:	e8 7b ff ff ff       	call   10733f <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  1073c4:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1073cb:	00 
  1073cc:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  1073d3:	e8 67 ff ff ff       	call   10733f <lapicw>
	lapicw(LINT1, MASKED);
  1073d8:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1073df:	00 
  1073e0:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  1073e7:	e8 53 ff ff ff       	call   10733f <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  1073ec:	a1 04 20 32 00       	mov    0x322004,%eax
  1073f1:	83 c0 30             	add    $0x30,%eax
  1073f4:	8b 00                	mov    (%eax),%eax
  1073f6:	c1 e8 10             	shr    $0x10,%eax
  1073f9:	25 ff 00 00 00       	and    $0xff,%eax
  1073fe:	83 f8 03             	cmp    $0x3,%eax
  107401:	76 14                	jbe    107417 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  107403:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10740a:	00 
  10740b:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  107412:	e8 28 ff ff ff       	call   10733f <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  107417:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  10741e:	00 
  10741f:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  107426:	e8 14 ff ff ff       	call   10733f <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  10742b:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  107432:	ff 
  107433:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  10743a:	e8 00 ff ff ff       	call   10733f <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  10743f:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  107446:	f0 
  107447:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  10744e:	e8 ec fe ff ff       	call   10733f <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  107453:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10745a:	00 
  10745b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  107462:	e8 d8 fe ff ff       	call   10733f <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  107467:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10746e:	00 
  10746f:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  107476:	e8 c4 fe ff ff       	call   10733f <lapicw>
	lapicw(ESR, 0);
  10747b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107482:	00 
  107483:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10748a:	e8 b0 fe ff ff       	call   10733f <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  10748f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107496:	00 
  107497:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10749e:	e8 9c fe ff ff       	call   10733f <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  1074a3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1074aa:	00 
  1074ab:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1074b2:	e8 88 fe ff ff       	call   10733f <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  1074b7:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  1074be:	00 
  1074bf:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1074c6:	e8 74 fe ff ff       	call   10733f <lapicw>
	while(lapic[ICRLO] & DELIVS)
  1074cb:	a1 04 20 32 00       	mov    0x322004,%eax
  1074d0:	05 00 03 00 00       	add    $0x300,%eax
  1074d5:	8b 00                	mov    (%eax),%eax
  1074d7:	25 00 10 00 00       	and    $0x1000,%eax
  1074dc:	85 c0                	test   %eax,%eax
  1074de:	75 eb                	jne    1074cb <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  1074e0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1074e7:	00 
  1074e8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1074ef:	e8 4b fe ff ff       	call   10733f <lapicw>
  1074f4:	eb 01                	jmp    1074f7 <lapic_init+0x196>

void
lapic_init()
{
	if (!lapic) 
		return;
  1074f6:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  1074f7:	c9                   	leave  
  1074f8:	c3                   	ret    

001074f9 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  1074f9:	55                   	push   %ebp
  1074fa:	89 e5                	mov    %esp,%ebp
  1074fc:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  1074ff:	a1 04 20 32 00       	mov    0x322004,%eax
  107504:	85 c0                	test   %eax,%eax
  107506:	74 14                	je     10751c <lapic_eoi+0x23>
		lapicw(EOI, 0);
  107508:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10750f:	00 
  107510:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  107517:	e8 23 fe ff ff       	call   10733f <lapicw>
}
  10751c:	c9                   	leave  
  10751d:	c3                   	ret    

0010751e <lapic_errintr>:

void lapic_errintr(void)
{
  10751e:	55                   	push   %ebp
  10751f:	89 e5                	mov    %esp,%ebp
  107521:	53                   	push   %ebx
  107522:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  107525:	e8 cf ff ff ff       	call   1074f9 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  10752a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107531:	00 
  107532:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  107539:	e8 01 fe ff ff       	call   10733f <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  10753e:	a1 04 20 32 00       	mov    0x322004,%eax
  107543:	05 80 02 00 00       	add    $0x280,%eax
  107548:	8b 18                	mov    (%eax),%ebx
  10754a:	e8 9d fd ff ff       	call   1072ec <cpu_cur>
  10754f:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  107556:	0f b6 c0             	movzbl %al,%eax
  107559:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  10755d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  107561:	c7 44 24 08 1d a4 10 	movl   $0x10a41d,0x8(%esp)
  107568:	00 
  107569:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  107570:	00 
  107571:	c7 04 24 37 a4 10 00 	movl   $0x10a437,(%esp)
  107578:	e8 70 93 ff ff       	call   1008ed <debug_warn>
}
  10757d:	83 c4 24             	add    $0x24,%esp
  107580:	5b                   	pop    %ebx
  107581:	5d                   	pop    %ebp
  107582:	c3                   	ret    

00107583 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  107583:	55                   	push   %ebp
  107584:	89 e5                	mov    %esp,%ebp
}
  107586:	5d                   	pop    %ebp
  107587:	c3                   	ret    

00107588 <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  107588:	55                   	push   %ebp
  107589:	89 e5                	mov    %esp,%ebp
  10758b:	83 ec 2c             	sub    $0x2c,%esp
  10758e:	8b 45 08             	mov    0x8(%ebp),%eax
  107591:	88 45 dc             	mov    %al,-0x24(%ebp)
  107594:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  10759b:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10759f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1075a3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1075a6:	ee                   	out    %al,(%dx)
  1075a7:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  1075ae:	c6 45 fb 0a          	movb   $0xa,-0x5(%ebp)
  1075b2:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1075b6:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1075b9:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  1075ba:	c7 45 ec 67 04 00 00 	movl   $0x467,-0x14(%ebp)
	wrv[0] = 0;
  1075c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1075c4:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  1075c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1075cc:	8d 50 02             	lea    0x2(%eax),%edx
  1075cf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075d2:	c1 e8 04             	shr    $0x4,%eax
  1075d5:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  1075d8:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  1075dc:	c1 e0 18             	shl    $0x18,%eax
  1075df:	89 44 24 04          	mov    %eax,0x4(%esp)
  1075e3:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1075ea:	e8 50 fd ff ff       	call   10733f <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  1075ef:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  1075f6:	00 
  1075f7:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1075fe:	e8 3c fd ff ff       	call   10733f <lapicw>
	microdelay(200);
  107603:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10760a:	e8 74 ff ff ff       	call   107583 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  10760f:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  107616:	00 
  107617:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10761e:	e8 1c fd ff ff       	call   10733f <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  107623:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  10762a:	e8 54 ff ff ff       	call   107583 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  10762f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  107636:	eb 40                	jmp    107678 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  107638:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  10763c:	c1 e0 18             	shl    $0x18,%eax
  10763f:	89 44 24 04          	mov    %eax,0x4(%esp)
  107643:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10764a:	e8 f0 fc ff ff       	call   10733f <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  10764f:	8b 45 0c             	mov    0xc(%ebp),%eax
  107652:	c1 e8 0c             	shr    $0xc,%eax
  107655:	80 cc 06             	or     $0x6,%ah
  107658:	89 44 24 04          	mov    %eax,0x4(%esp)
  10765c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  107663:	e8 d7 fc ff ff       	call   10733f <lapicw>
		microdelay(200);
  107668:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10766f:	e8 0f ff ff ff       	call   107583 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  107674:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  107678:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
  10767c:	7e ba                	jle    107638 <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  10767e:	c9                   	leave  
  10767f:	c3                   	ret    

00107680 <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  107680:	55                   	push   %ebp
  107681:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  107683:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  107688:	8b 55 08             	mov    0x8(%ebp),%edx
  10768b:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  10768d:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  107692:	8b 40 10             	mov    0x10(%eax),%eax
}
  107695:	5d                   	pop    %ebp
  107696:	c3                   	ret    

00107697 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  107697:	55                   	push   %ebp
  107698:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10769a:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  10769f:	8b 55 08             	mov    0x8(%ebp),%edx
  1076a2:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  1076a4:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  1076a9:	8b 55 0c             	mov    0xc(%ebp),%edx
  1076ac:	89 50 10             	mov    %edx,0x10(%eax)
}
  1076af:	5d                   	pop    %ebp
  1076b0:	c3                   	ret    

001076b1 <ioapic_init>:

void
ioapic_init(void)
{
  1076b1:	55                   	push   %ebp
  1076b2:	89 e5                	mov    %esp,%ebp
  1076b4:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  1076b7:	a1 64 ed 31 00       	mov    0x31ed64,%eax
  1076bc:	85 c0                	test   %eax,%eax
  1076be:	0f 84 fd 00 00 00    	je     1077c1 <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  1076c4:	a1 60 ed 31 00       	mov    0x31ed60,%eax
  1076c9:	85 c0                	test   %eax,%eax
  1076cb:	75 0a                	jne    1076d7 <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  1076cd:	c7 05 60 ed 31 00 00 	movl   $0xfec00000,0x31ed60
  1076d4:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  1076d7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1076de:	e8 9d ff ff ff       	call   107680 <ioapic_read>
  1076e3:	c1 e8 10             	shr    $0x10,%eax
  1076e6:	25 ff 00 00 00       	and    $0xff,%eax
  1076eb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  1076ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1076f5:	e8 86 ff ff ff       	call   107680 <ioapic_read>
  1076fa:	c1 e8 18             	shr    $0x18,%eax
  1076fd:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  107700:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  107704:	75 2a                	jne    107730 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  107706:	0f b6 05 5c ed 31 00 	movzbl 0x31ed5c,%eax
  10770d:	0f b6 c0             	movzbl %al,%eax
  107710:	c1 e0 18             	shl    $0x18,%eax
  107713:	89 44 24 04          	mov    %eax,0x4(%esp)
  107717:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10771e:	e8 74 ff ff ff       	call   107697 <ioapic_write>
		id = ioapicid;
  107723:	0f b6 05 5c ed 31 00 	movzbl 0x31ed5c,%eax
  10772a:	0f b6 c0             	movzbl %al,%eax
  10772d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  107730:	0f b6 05 5c ed 31 00 	movzbl 0x31ed5c,%eax
  107737:	0f b6 c0             	movzbl %al,%eax
  10773a:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10773d:	74 31                	je     107770 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  10773f:	0f b6 05 5c ed 31 00 	movzbl 0x31ed5c,%eax
  107746:	0f b6 c0             	movzbl %al,%eax
  107749:	89 44 24 10          	mov    %eax,0x10(%esp)
  10774d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107750:	89 44 24 0c          	mov    %eax,0xc(%esp)
  107754:	c7 44 24 08 44 a4 10 	movl   $0x10a444,0x8(%esp)
  10775b:	00 
  10775c:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  107763:	00 
  107764:	c7 04 24 65 a4 10 00 	movl   $0x10a465,(%esp)
  10776b:	e8 7d 91 ff ff       	call   1008ed <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  107770:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  107777:	eb 3e                	jmp    1077b7 <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  107779:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10777c:	83 c0 20             	add    $0x20,%eax
  10777f:	0d 00 00 01 00       	or     $0x10000,%eax
  107784:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107787:	83 c2 08             	add    $0x8,%edx
  10778a:	01 d2                	add    %edx,%edx
  10778c:	89 44 24 04          	mov    %eax,0x4(%esp)
  107790:	89 14 24             	mov    %edx,(%esp)
  107793:	e8 ff fe ff ff       	call   107697 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  107798:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10779b:	83 c0 08             	add    $0x8,%eax
  10779e:	01 c0                	add    %eax,%eax
  1077a0:	83 c0 01             	add    $0x1,%eax
  1077a3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1077aa:	00 
  1077ab:	89 04 24             	mov    %eax,(%esp)
  1077ae:	e8 e4 fe ff ff       	call   107697 <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  1077b3:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1077b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1077ba:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1077bd:	7e ba                	jle    107779 <ioapic_init+0xc8>
  1077bf:	eb 01                	jmp    1077c2 <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  1077c1:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  1077c2:	c9                   	leave  
  1077c3:	c3                   	ret    

001077c4 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  1077c4:	55                   	push   %ebp
  1077c5:	89 e5                	mov    %esp,%ebp
  1077c7:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  1077ca:	a1 64 ed 31 00       	mov    0x31ed64,%eax
  1077cf:	85 c0                	test   %eax,%eax
  1077d1:	74 3a                	je     10780d <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  1077d3:	8b 45 08             	mov    0x8(%ebp),%eax
  1077d6:	83 c0 20             	add    $0x20,%eax
  1077d9:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  1077dc:	8b 55 08             	mov    0x8(%ebp),%edx
  1077df:	83 c2 08             	add    $0x8,%edx
  1077e2:	01 d2                	add    %edx,%edx
  1077e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1077e8:	89 14 24             	mov    %edx,(%esp)
  1077eb:	e8 a7 fe ff ff       	call   107697 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  1077f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1077f3:	83 c0 08             	add    $0x8,%eax
  1077f6:	01 c0                	add    %eax,%eax
  1077f8:	83 c0 01             	add    $0x1,%eax
  1077fb:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  107802:	ff 
  107803:	89 04 24             	mov    %eax,(%esp)
  107806:	e8 8c fe ff ff       	call   107697 <ioapic_write>
  10780b:	eb 01                	jmp    10780e <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  10780d:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  10780e:	c9                   	leave  
  10780f:	c3                   	ret    

00107810 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  107810:	55                   	push   %ebp
  107811:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  107813:	8b 45 08             	mov    0x8(%ebp),%eax
  107816:	8b 40 18             	mov    0x18(%eax),%eax
  107819:	83 e0 02             	and    $0x2,%eax
  10781c:	85 c0                	test   %eax,%eax
  10781e:	74 1c                	je     10783c <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  107820:	8b 45 0c             	mov    0xc(%ebp),%eax
  107823:	8b 00                	mov    (%eax),%eax
  107825:	8d 50 08             	lea    0x8(%eax),%edx
  107828:	8b 45 0c             	mov    0xc(%ebp),%eax
  10782b:	89 10                	mov    %edx,(%eax)
  10782d:	8b 45 0c             	mov    0xc(%ebp),%eax
  107830:	8b 00                	mov    (%eax),%eax
  107832:	83 e8 08             	sub    $0x8,%eax
  107835:	8b 50 04             	mov    0x4(%eax),%edx
  107838:	8b 00                	mov    (%eax),%eax
  10783a:	eb 47                	jmp    107883 <getuint+0x73>
	else if (st->flags & F_L)
  10783c:	8b 45 08             	mov    0x8(%ebp),%eax
  10783f:	8b 40 18             	mov    0x18(%eax),%eax
  107842:	83 e0 01             	and    $0x1,%eax
  107845:	84 c0                	test   %al,%al
  107847:	74 1e                	je     107867 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  107849:	8b 45 0c             	mov    0xc(%ebp),%eax
  10784c:	8b 00                	mov    (%eax),%eax
  10784e:	8d 50 04             	lea    0x4(%eax),%edx
  107851:	8b 45 0c             	mov    0xc(%ebp),%eax
  107854:	89 10                	mov    %edx,(%eax)
  107856:	8b 45 0c             	mov    0xc(%ebp),%eax
  107859:	8b 00                	mov    (%eax),%eax
  10785b:	83 e8 04             	sub    $0x4,%eax
  10785e:	8b 00                	mov    (%eax),%eax
  107860:	ba 00 00 00 00       	mov    $0x0,%edx
  107865:	eb 1c                	jmp    107883 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  107867:	8b 45 0c             	mov    0xc(%ebp),%eax
  10786a:	8b 00                	mov    (%eax),%eax
  10786c:	8d 50 04             	lea    0x4(%eax),%edx
  10786f:	8b 45 0c             	mov    0xc(%ebp),%eax
  107872:	89 10                	mov    %edx,(%eax)
  107874:	8b 45 0c             	mov    0xc(%ebp),%eax
  107877:	8b 00                	mov    (%eax),%eax
  107879:	83 e8 04             	sub    $0x4,%eax
  10787c:	8b 00                	mov    (%eax),%eax
  10787e:	ba 00 00 00 00       	mov    $0x0,%edx
}
  107883:	5d                   	pop    %ebp
  107884:	c3                   	ret    

00107885 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  107885:	55                   	push   %ebp
  107886:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  107888:	8b 45 08             	mov    0x8(%ebp),%eax
  10788b:	8b 40 18             	mov    0x18(%eax),%eax
  10788e:	83 e0 02             	and    $0x2,%eax
  107891:	85 c0                	test   %eax,%eax
  107893:	74 1c                	je     1078b1 <getint+0x2c>
		return va_arg(*ap, long long);
  107895:	8b 45 0c             	mov    0xc(%ebp),%eax
  107898:	8b 00                	mov    (%eax),%eax
  10789a:	8d 50 08             	lea    0x8(%eax),%edx
  10789d:	8b 45 0c             	mov    0xc(%ebp),%eax
  1078a0:	89 10                	mov    %edx,(%eax)
  1078a2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1078a5:	8b 00                	mov    (%eax),%eax
  1078a7:	83 e8 08             	sub    $0x8,%eax
  1078aa:	8b 50 04             	mov    0x4(%eax),%edx
  1078ad:	8b 00                	mov    (%eax),%eax
  1078af:	eb 47                	jmp    1078f8 <getint+0x73>
	else if (st->flags & F_L)
  1078b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1078b4:	8b 40 18             	mov    0x18(%eax),%eax
  1078b7:	83 e0 01             	and    $0x1,%eax
  1078ba:	84 c0                	test   %al,%al
  1078bc:	74 1e                	je     1078dc <getint+0x57>
		return va_arg(*ap, long);
  1078be:	8b 45 0c             	mov    0xc(%ebp),%eax
  1078c1:	8b 00                	mov    (%eax),%eax
  1078c3:	8d 50 04             	lea    0x4(%eax),%edx
  1078c6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1078c9:	89 10                	mov    %edx,(%eax)
  1078cb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1078ce:	8b 00                	mov    (%eax),%eax
  1078d0:	83 e8 04             	sub    $0x4,%eax
  1078d3:	8b 00                	mov    (%eax),%eax
  1078d5:	89 c2                	mov    %eax,%edx
  1078d7:	c1 fa 1f             	sar    $0x1f,%edx
  1078da:	eb 1c                	jmp    1078f8 <getint+0x73>
	else
		return va_arg(*ap, int);
  1078dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1078df:	8b 00                	mov    (%eax),%eax
  1078e1:	8d 50 04             	lea    0x4(%eax),%edx
  1078e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1078e7:	89 10                	mov    %edx,(%eax)
  1078e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1078ec:	8b 00                	mov    (%eax),%eax
  1078ee:	83 e8 04             	sub    $0x4,%eax
  1078f1:	8b 00                	mov    (%eax),%eax
  1078f3:	89 c2                	mov    %eax,%edx
  1078f5:	c1 fa 1f             	sar    $0x1f,%edx
}
  1078f8:	5d                   	pop    %ebp
  1078f9:	c3                   	ret    

001078fa <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  1078fa:	55                   	push   %ebp
  1078fb:	89 e5                	mov    %esp,%ebp
  1078fd:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  107900:	eb 1a                	jmp    10791c <putpad+0x22>
		st->putch(st->padc, st->putdat);
  107902:	8b 45 08             	mov    0x8(%ebp),%eax
  107905:	8b 08                	mov    (%eax),%ecx
  107907:	8b 45 08             	mov    0x8(%ebp),%eax
  10790a:	8b 50 04             	mov    0x4(%eax),%edx
  10790d:	8b 45 08             	mov    0x8(%ebp),%eax
  107910:	8b 40 08             	mov    0x8(%eax),%eax
  107913:	89 54 24 04          	mov    %edx,0x4(%esp)
  107917:	89 04 24             	mov    %eax,(%esp)
  10791a:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  10791c:	8b 45 08             	mov    0x8(%ebp),%eax
  10791f:	8b 40 0c             	mov    0xc(%eax),%eax
  107922:	8d 50 ff             	lea    -0x1(%eax),%edx
  107925:	8b 45 08             	mov    0x8(%ebp),%eax
  107928:	89 50 0c             	mov    %edx,0xc(%eax)
  10792b:	8b 45 08             	mov    0x8(%ebp),%eax
  10792e:	8b 40 0c             	mov    0xc(%eax),%eax
  107931:	85 c0                	test   %eax,%eax
  107933:	79 cd                	jns    107902 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  107935:	c9                   	leave  
  107936:	c3                   	ret    

00107937 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  107937:	55                   	push   %ebp
  107938:	89 e5                	mov    %esp,%ebp
  10793a:	53                   	push   %ebx
  10793b:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  10793e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107942:	79 18                	jns    10795c <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  107944:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10794b:	00 
  10794c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10794f:	89 04 24             	mov    %eax,(%esp)
  107952:	e8 e7 07 00 00       	call   10813e <strchr>
  107957:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10795a:	eb 2c                	jmp    107988 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  10795c:	8b 45 10             	mov    0x10(%ebp),%eax
  10795f:	89 44 24 08          	mov    %eax,0x8(%esp)
  107963:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10796a:	00 
  10796b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10796e:	89 04 24             	mov    %eax,(%esp)
  107971:	e8 cc 09 00 00       	call   108342 <memchr>
  107976:	89 45 f0             	mov    %eax,-0x10(%ebp)
  107979:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  10797d:	75 09                	jne    107988 <putstr+0x51>
		lim = str + maxlen;
  10797f:	8b 45 10             	mov    0x10(%ebp),%eax
  107982:	03 45 0c             	add    0xc(%ebp),%eax
  107985:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  107988:	8b 45 08             	mov    0x8(%ebp),%eax
  10798b:	8b 40 0c             	mov    0xc(%eax),%eax
  10798e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  107991:	8b 55 f0             	mov    -0x10(%ebp),%edx
  107994:	89 cb                	mov    %ecx,%ebx
  107996:	29 d3                	sub    %edx,%ebx
  107998:	89 da                	mov    %ebx,%edx
  10799a:	8d 14 10             	lea    (%eax,%edx,1),%edx
  10799d:	8b 45 08             	mov    0x8(%ebp),%eax
  1079a0:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  1079a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1079a6:	8b 40 18             	mov    0x18(%eax),%eax
  1079a9:	83 e0 10             	and    $0x10,%eax
  1079ac:	85 c0                	test   %eax,%eax
  1079ae:	75 32                	jne    1079e2 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  1079b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1079b3:	89 04 24             	mov    %eax,(%esp)
  1079b6:	e8 3f ff ff ff       	call   1078fa <putpad>
	while (str < lim) {
  1079bb:	eb 25                	jmp    1079e2 <putstr+0xab>
		char ch = *str++;
  1079bd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1079c0:	0f b6 00             	movzbl (%eax),%eax
  1079c3:	88 45 f7             	mov    %al,-0x9(%ebp)
  1079c6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  1079ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1079cd:	8b 08                	mov    (%eax),%ecx
  1079cf:	8b 45 08             	mov    0x8(%ebp),%eax
  1079d2:	8b 50 04             	mov    0x4(%eax),%edx
  1079d5:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  1079d9:	89 54 24 04          	mov    %edx,0x4(%esp)
  1079dd:	89 04 24             	mov    %eax,(%esp)
  1079e0:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  1079e2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1079e5:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1079e8:	72 d3                	jb     1079bd <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  1079ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1079ed:	89 04 24             	mov    %eax,(%esp)
  1079f0:	e8 05 ff ff ff       	call   1078fa <putpad>
}
  1079f5:	83 c4 24             	add    $0x24,%esp
  1079f8:	5b                   	pop    %ebx
  1079f9:	5d                   	pop    %ebp
  1079fa:	c3                   	ret    

001079fb <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  1079fb:	55                   	push   %ebp
  1079fc:	89 e5                	mov    %esp,%ebp
  1079fe:	53                   	push   %ebx
  1079ff:	83 ec 24             	sub    $0x24,%esp
  107a02:	8b 45 10             	mov    0x10(%ebp),%eax
  107a05:	89 45 f0             	mov    %eax,-0x10(%ebp)
  107a08:	8b 45 14             	mov    0x14(%ebp),%eax
  107a0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  107a0e:	8b 45 08             	mov    0x8(%ebp),%eax
  107a11:	8b 40 1c             	mov    0x1c(%eax),%eax
  107a14:	89 c2                	mov    %eax,%edx
  107a16:	c1 fa 1f             	sar    $0x1f,%edx
  107a19:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  107a1c:	77 4e                	ja     107a6c <genint+0x71>
  107a1e:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  107a21:	72 05                	jb     107a28 <genint+0x2d>
  107a23:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  107a26:	77 44                	ja     107a6c <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  107a28:	8b 45 08             	mov    0x8(%ebp),%eax
  107a2b:	8b 40 1c             	mov    0x1c(%eax),%eax
  107a2e:	89 c2                	mov    %eax,%edx
  107a30:	c1 fa 1f             	sar    $0x1f,%edx
  107a33:	89 44 24 08          	mov    %eax,0x8(%esp)
  107a37:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107a3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107a3e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  107a41:	89 04 24             	mov    %eax,(%esp)
  107a44:	89 54 24 04          	mov    %edx,0x4(%esp)
  107a48:	e8 33 09 00 00       	call   108380 <__udivdi3>
  107a4d:	89 44 24 08          	mov    %eax,0x8(%esp)
  107a51:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107a55:	8b 45 0c             	mov    0xc(%ebp),%eax
  107a58:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a5c:	8b 45 08             	mov    0x8(%ebp),%eax
  107a5f:	89 04 24             	mov    %eax,(%esp)
  107a62:	e8 94 ff ff ff       	call   1079fb <genint>
  107a67:	89 45 0c             	mov    %eax,0xc(%ebp)
  107a6a:	eb 1b                	jmp    107a87 <genint+0x8c>
	else if (st->signc >= 0)
  107a6c:	8b 45 08             	mov    0x8(%ebp),%eax
  107a6f:	8b 40 14             	mov    0x14(%eax),%eax
  107a72:	85 c0                	test   %eax,%eax
  107a74:	78 11                	js     107a87 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  107a76:	8b 45 08             	mov    0x8(%ebp),%eax
  107a79:	8b 40 14             	mov    0x14(%eax),%eax
  107a7c:	89 c2                	mov    %eax,%edx
  107a7e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107a81:	88 10                	mov    %dl,(%eax)
  107a83:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  107a87:	8b 45 08             	mov    0x8(%ebp),%eax
  107a8a:	8b 40 1c             	mov    0x1c(%eax),%eax
  107a8d:	89 c1                	mov    %eax,%ecx
  107a8f:	89 c3                	mov    %eax,%ebx
  107a91:	c1 fb 1f             	sar    $0x1f,%ebx
  107a94:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107a97:	8b 55 f4             	mov    -0xc(%ebp),%edx
  107a9a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  107a9e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  107aa2:	89 04 24             	mov    %eax,(%esp)
  107aa5:	89 54 24 04          	mov    %edx,0x4(%esp)
  107aa9:	e8 02 0a 00 00       	call   1084b0 <__umoddi3>
  107aae:	05 74 a4 10 00       	add    $0x10a474,%eax
  107ab3:	0f b6 10             	movzbl (%eax),%edx
  107ab6:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ab9:	88 10                	mov    %dl,(%eax)
  107abb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  107abf:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  107ac2:	83 c4 24             	add    $0x24,%esp
  107ac5:	5b                   	pop    %ebx
  107ac6:	5d                   	pop    %ebp
  107ac7:	c3                   	ret    

00107ac8 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  107ac8:	55                   	push   %ebp
  107ac9:	89 e5                	mov    %esp,%ebp
  107acb:	83 ec 58             	sub    $0x58,%esp
  107ace:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ad1:	89 45 c0             	mov    %eax,-0x40(%ebp)
  107ad4:	8b 45 10             	mov    0x10(%ebp),%eax
  107ad7:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  107ada:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  107add:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  107ae0:	8b 45 08             	mov    0x8(%ebp),%eax
  107ae3:	8b 55 14             	mov    0x14(%ebp),%edx
  107ae6:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  107ae9:	8b 45 c0             	mov    -0x40(%ebp),%eax
  107aec:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  107aef:	89 44 24 08          	mov    %eax,0x8(%esp)
  107af3:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  107afa:	89 44 24 04          	mov    %eax,0x4(%esp)
  107afe:	8b 45 08             	mov    0x8(%ebp),%eax
  107b01:	89 04 24             	mov    %eax,(%esp)
  107b04:	e8 f2 fe ff ff       	call   1079fb <genint>
  107b09:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  107b0c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  107b0f:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  107b12:	89 d1                	mov    %edx,%ecx
  107b14:	29 c1                	sub    %eax,%ecx
  107b16:	89 c8                	mov    %ecx,%eax
  107b18:	89 44 24 08          	mov    %eax,0x8(%esp)
  107b1c:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  107b1f:	89 44 24 04          	mov    %eax,0x4(%esp)
  107b23:	8b 45 08             	mov    0x8(%ebp),%eax
  107b26:	89 04 24             	mov    %eax,(%esp)
  107b29:	e8 09 fe ff ff       	call   107937 <putstr>
}
  107b2e:	c9                   	leave  
  107b2f:	c3                   	ret    

00107b30 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  107b30:	55                   	push   %ebp
  107b31:	89 e5                	mov    %esp,%ebp
  107b33:	53                   	push   %ebx
  107b34:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  107b37:	8d 55 c8             	lea    -0x38(%ebp),%edx
  107b3a:	b9 00 00 00 00       	mov    $0x0,%ecx
  107b3f:	b8 20 00 00 00       	mov    $0x20,%eax
  107b44:	89 c3                	mov    %eax,%ebx
  107b46:	83 e3 fc             	and    $0xfffffffc,%ebx
  107b49:	b8 00 00 00 00       	mov    $0x0,%eax
  107b4e:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  107b51:	83 c0 04             	add    $0x4,%eax
  107b54:	39 d8                	cmp    %ebx,%eax
  107b56:	72 f6                	jb     107b4e <vprintfmt+0x1e>
  107b58:	01 c2                	add    %eax,%edx
  107b5a:	8b 45 08             	mov    0x8(%ebp),%eax
  107b5d:	89 45 c8             	mov    %eax,-0x38(%ebp)
  107b60:	8b 45 0c             	mov    0xc(%ebp),%eax
  107b63:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  107b66:	eb 17                	jmp    107b7f <vprintfmt+0x4f>
			if (ch == '\0')
  107b68:	85 db                	test   %ebx,%ebx
  107b6a:	0f 84 52 03 00 00    	je     107ec2 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  107b70:	8b 45 0c             	mov    0xc(%ebp),%eax
  107b73:	89 44 24 04          	mov    %eax,0x4(%esp)
  107b77:	89 1c 24             	mov    %ebx,(%esp)
  107b7a:	8b 45 08             	mov    0x8(%ebp),%eax
  107b7d:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  107b7f:	8b 45 10             	mov    0x10(%ebp),%eax
  107b82:	0f b6 00             	movzbl (%eax),%eax
  107b85:	0f b6 d8             	movzbl %al,%ebx
  107b88:	83 fb 25             	cmp    $0x25,%ebx
  107b8b:	0f 95 c0             	setne  %al
  107b8e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  107b92:	84 c0                	test   %al,%al
  107b94:	75 d2                	jne    107b68 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  107b96:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  107b9d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  107ba4:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  107bab:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  107bb2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  107bb9:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  107bc0:	eb 04                	jmp    107bc6 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  107bc2:	90                   	nop
  107bc3:	eb 01                	jmp    107bc6 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  107bc5:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  107bc6:	8b 45 10             	mov    0x10(%ebp),%eax
  107bc9:	0f b6 00             	movzbl (%eax),%eax
  107bcc:	0f b6 d8             	movzbl %al,%ebx
  107bcf:	89 d8                	mov    %ebx,%eax
  107bd1:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  107bd5:	83 e8 20             	sub    $0x20,%eax
  107bd8:	83 f8 58             	cmp    $0x58,%eax
  107bdb:	0f 87 b1 02 00 00    	ja     107e92 <vprintfmt+0x362>
  107be1:	8b 04 85 8c a4 10 00 	mov    0x10a48c(,%eax,4),%eax
  107be8:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  107bea:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107bed:	83 c8 10             	or     $0x10,%eax
  107bf0:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107bf3:	eb d1                	jmp    107bc6 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  107bf5:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  107bfc:	eb c8                	jmp    107bc6 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  107bfe:	8b 45 dc             	mov    -0x24(%ebp),%eax
  107c01:	85 c0                	test   %eax,%eax
  107c03:	79 bd                	jns    107bc2 <vprintfmt+0x92>
				st.signc = ' ';
  107c05:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  107c0c:	eb b8                	jmp    107bc6 <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  107c0e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107c11:	83 e0 08             	and    $0x8,%eax
  107c14:	85 c0                	test   %eax,%eax
  107c16:	75 07                	jne    107c1f <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  107c18:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  107c1f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  107c26:	8b 55 d8             	mov    -0x28(%ebp),%edx
  107c29:	89 d0                	mov    %edx,%eax
  107c2b:	c1 e0 02             	shl    $0x2,%eax
  107c2e:	01 d0                	add    %edx,%eax
  107c30:	01 c0                	add    %eax,%eax
  107c32:	01 d8                	add    %ebx,%eax
  107c34:	83 e8 30             	sub    $0x30,%eax
  107c37:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  107c3a:	8b 45 10             	mov    0x10(%ebp),%eax
  107c3d:	0f b6 00             	movzbl (%eax),%eax
  107c40:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  107c43:	83 fb 2f             	cmp    $0x2f,%ebx
  107c46:	7e 21                	jle    107c69 <vprintfmt+0x139>
  107c48:	83 fb 39             	cmp    $0x39,%ebx
  107c4b:	7f 1f                	jg     107c6c <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  107c4d:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  107c51:	eb d3                	jmp    107c26 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  107c53:	8b 45 14             	mov    0x14(%ebp),%eax
  107c56:	83 c0 04             	add    $0x4,%eax
  107c59:	89 45 14             	mov    %eax,0x14(%ebp)
  107c5c:	8b 45 14             	mov    0x14(%ebp),%eax
  107c5f:	83 e8 04             	sub    $0x4,%eax
  107c62:	8b 00                	mov    (%eax),%eax
  107c64:	89 45 d8             	mov    %eax,-0x28(%ebp)
  107c67:	eb 04                	jmp    107c6d <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  107c69:	90                   	nop
  107c6a:	eb 01                	jmp    107c6d <vprintfmt+0x13d>
  107c6c:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  107c6d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107c70:	83 e0 08             	and    $0x8,%eax
  107c73:	85 c0                	test   %eax,%eax
  107c75:	0f 85 4a ff ff ff    	jne    107bc5 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  107c7b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107c7e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  107c81:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  107c88:	e9 39 ff ff ff       	jmp    107bc6 <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  107c8d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107c90:	83 c8 08             	or     $0x8,%eax
  107c93:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107c96:	e9 2b ff ff ff       	jmp    107bc6 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  107c9b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107c9e:	83 c8 04             	or     $0x4,%eax
  107ca1:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107ca4:	e9 1d ff ff ff       	jmp    107bc6 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  107ca9:	8b 55 e0             	mov    -0x20(%ebp),%edx
  107cac:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107caf:	83 e0 01             	and    $0x1,%eax
  107cb2:	84 c0                	test   %al,%al
  107cb4:	74 07                	je     107cbd <vprintfmt+0x18d>
  107cb6:	b8 02 00 00 00       	mov    $0x2,%eax
  107cbb:	eb 05                	jmp    107cc2 <vprintfmt+0x192>
  107cbd:	b8 01 00 00 00       	mov    $0x1,%eax
  107cc2:	09 d0                	or     %edx,%eax
  107cc4:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107cc7:	e9 fa fe ff ff       	jmp    107bc6 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  107ccc:	8b 45 14             	mov    0x14(%ebp),%eax
  107ccf:	83 c0 04             	add    $0x4,%eax
  107cd2:	89 45 14             	mov    %eax,0x14(%ebp)
  107cd5:	8b 45 14             	mov    0x14(%ebp),%eax
  107cd8:	83 e8 04             	sub    $0x4,%eax
  107cdb:	8b 00                	mov    (%eax),%eax
  107cdd:	8b 55 0c             	mov    0xc(%ebp),%edx
  107ce0:	89 54 24 04          	mov    %edx,0x4(%esp)
  107ce4:	89 04 24             	mov    %eax,(%esp)
  107ce7:	8b 45 08             	mov    0x8(%ebp),%eax
  107cea:	ff d0                	call   *%eax
			break;
  107cec:	e9 cb 01 00 00       	jmp    107ebc <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  107cf1:	8b 45 14             	mov    0x14(%ebp),%eax
  107cf4:	83 c0 04             	add    $0x4,%eax
  107cf7:	89 45 14             	mov    %eax,0x14(%ebp)
  107cfa:	8b 45 14             	mov    0x14(%ebp),%eax
  107cfd:	83 e8 04             	sub    $0x4,%eax
  107d00:	8b 00                	mov    (%eax),%eax
  107d02:	89 45 f4             	mov    %eax,-0xc(%ebp)
  107d05:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  107d09:	75 07                	jne    107d12 <vprintfmt+0x1e2>
				s = "(null)";
  107d0b:	c7 45 f4 85 a4 10 00 	movl   $0x10a485,-0xc(%ebp)
			putstr(&st, s, st.prec);
  107d12:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107d15:	89 44 24 08          	mov    %eax,0x8(%esp)
  107d19:	8b 45 f4             	mov    -0xc(%ebp),%eax
  107d1c:	89 44 24 04          	mov    %eax,0x4(%esp)
  107d20:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107d23:	89 04 24             	mov    %eax,(%esp)
  107d26:	e8 0c fc ff ff       	call   107937 <putstr>
			break;
  107d2b:	e9 8c 01 00 00       	jmp    107ebc <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  107d30:	8d 45 14             	lea    0x14(%ebp),%eax
  107d33:	89 44 24 04          	mov    %eax,0x4(%esp)
  107d37:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107d3a:	89 04 24             	mov    %eax,(%esp)
  107d3d:	e8 43 fb ff ff       	call   107885 <getint>
  107d42:	89 45 e8             	mov    %eax,-0x18(%ebp)
  107d45:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  107d48:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107d4b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107d4e:	85 d2                	test   %edx,%edx
  107d50:	79 1a                	jns    107d6c <vprintfmt+0x23c>
				num = -(intmax_t) num;
  107d52:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107d55:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107d58:	f7 d8                	neg    %eax
  107d5a:	83 d2 00             	adc    $0x0,%edx
  107d5d:	f7 da                	neg    %edx
  107d5f:	89 45 e8             	mov    %eax,-0x18(%ebp)
  107d62:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  107d65:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  107d6c:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  107d73:	00 
  107d74:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107d77:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107d7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  107d7e:	89 54 24 08          	mov    %edx,0x8(%esp)
  107d82:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107d85:	89 04 24             	mov    %eax,(%esp)
  107d88:	e8 3b fd ff ff       	call   107ac8 <putint>
			break;
  107d8d:	e9 2a 01 00 00       	jmp    107ebc <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  107d92:	8d 45 14             	lea    0x14(%ebp),%eax
  107d95:	89 44 24 04          	mov    %eax,0x4(%esp)
  107d99:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107d9c:	89 04 24             	mov    %eax,(%esp)
  107d9f:	e8 6c fa ff ff       	call   107810 <getuint>
  107da4:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  107dab:	00 
  107dac:	89 44 24 04          	mov    %eax,0x4(%esp)
  107db0:	89 54 24 08          	mov    %edx,0x8(%esp)
  107db4:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107db7:	89 04 24             	mov    %eax,(%esp)
  107dba:	e8 09 fd ff ff       	call   107ac8 <putint>
			break;
  107dbf:	e9 f8 00 00 00       	jmp    107ebc <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  107dc4:	8d 45 14             	lea    0x14(%ebp),%eax
  107dc7:	89 44 24 04          	mov    %eax,0x4(%esp)
  107dcb:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107dce:	89 04 24             	mov    %eax,(%esp)
  107dd1:	e8 3a fa ff ff       	call   107810 <getuint>
  107dd6:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  107ddd:	00 
  107dde:	89 44 24 04          	mov    %eax,0x4(%esp)
  107de2:	89 54 24 08          	mov    %edx,0x8(%esp)
  107de6:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107de9:	89 04 24             	mov    %eax,(%esp)
  107dec:	e8 d7 fc ff ff       	call   107ac8 <putint>
			break;
  107df1:	e9 c6 00 00 00       	jmp    107ebc <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  107df6:	8d 45 14             	lea    0x14(%ebp),%eax
  107df9:	89 44 24 04          	mov    %eax,0x4(%esp)
  107dfd:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107e00:	89 04 24             	mov    %eax,(%esp)
  107e03:	e8 08 fa ff ff       	call   107810 <getuint>
  107e08:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  107e0f:	00 
  107e10:	89 44 24 04          	mov    %eax,0x4(%esp)
  107e14:	89 54 24 08          	mov    %edx,0x8(%esp)
  107e18:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107e1b:	89 04 24             	mov    %eax,(%esp)
  107e1e:	e8 a5 fc ff ff       	call   107ac8 <putint>
			break;
  107e23:	e9 94 00 00 00       	jmp    107ebc <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  107e28:	8b 45 0c             	mov    0xc(%ebp),%eax
  107e2b:	89 44 24 04          	mov    %eax,0x4(%esp)
  107e2f:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  107e36:	8b 45 08             	mov    0x8(%ebp),%eax
  107e39:	ff d0                	call   *%eax
			putch('x', putdat);
  107e3b:	8b 45 0c             	mov    0xc(%ebp),%eax
  107e3e:	89 44 24 04          	mov    %eax,0x4(%esp)
  107e42:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  107e49:	8b 45 08             	mov    0x8(%ebp),%eax
  107e4c:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  107e4e:	8b 45 14             	mov    0x14(%ebp),%eax
  107e51:	83 c0 04             	add    $0x4,%eax
  107e54:	89 45 14             	mov    %eax,0x14(%ebp)
  107e57:	8b 45 14             	mov    0x14(%ebp),%eax
  107e5a:	83 e8 04             	sub    $0x4,%eax
  107e5d:	8b 00                	mov    (%eax),%eax
  107e5f:	ba 00 00 00 00       	mov    $0x0,%edx
  107e64:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  107e6b:	00 
  107e6c:	89 44 24 04          	mov    %eax,0x4(%esp)
  107e70:	89 54 24 08          	mov    %edx,0x8(%esp)
  107e74:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107e77:	89 04 24             	mov    %eax,(%esp)
  107e7a:	e8 49 fc ff ff       	call   107ac8 <putint>
			break;
  107e7f:	eb 3b                	jmp    107ebc <vprintfmt+0x38c>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
  107e81:	8b 45 0c             	mov    0xc(%ebp),%eax
  107e84:	89 44 24 04          	mov    %eax,0x4(%esp)
  107e88:	89 1c 24             	mov    %ebx,(%esp)
  107e8b:	8b 45 08             	mov    0x8(%ebp),%eax
  107e8e:	ff d0                	call   *%eax
			break;
  107e90:	eb 2a                	jmp    107ebc <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  107e92:	8b 45 0c             	mov    0xc(%ebp),%eax
  107e95:	89 44 24 04          	mov    %eax,0x4(%esp)
  107e99:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  107ea0:	8b 45 08             	mov    0x8(%ebp),%eax
  107ea3:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  107ea5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107ea9:	eb 04                	jmp    107eaf <vprintfmt+0x37f>
  107eab:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107eaf:	8b 45 10             	mov    0x10(%ebp),%eax
  107eb2:	83 e8 01             	sub    $0x1,%eax
  107eb5:	0f b6 00             	movzbl (%eax),%eax
  107eb8:	3c 25                	cmp    $0x25,%al
  107eba:	75 ef                	jne    107eab <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  107ebc:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  107ebd:	e9 bd fc ff ff       	jmp    107b7f <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  107ec2:	83 c4 44             	add    $0x44,%esp
  107ec5:	5b                   	pop    %ebx
  107ec6:	5d                   	pop    %ebp
  107ec7:	c3                   	ret    

00107ec8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  107ec8:	55                   	push   %ebp
  107ec9:	89 e5                	mov    %esp,%ebp
  107ecb:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  107ece:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ed1:	8b 00                	mov    (%eax),%eax
  107ed3:	8b 55 08             	mov    0x8(%ebp),%edx
  107ed6:	89 d1                	mov    %edx,%ecx
  107ed8:	8b 55 0c             	mov    0xc(%ebp),%edx
  107edb:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  107edf:	8d 50 01             	lea    0x1(%eax),%edx
  107ee2:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ee5:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  107ee7:	8b 45 0c             	mov    0xc(%ebp),%eax
  107eea:	8b 00                	mov    (%eax),%eax
  107eec:	3d ff 00 00 00       	cmp    $0xff,%eax
  107ef1:	75 24                	jne    107f17 <putch+0x4f>
		b->buf[b->idx] = 0;
  107ef3:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ef6:	8b 00                	mov    (%eax),%eax
  107ef8:	8b 55 0c             	mov    0xc(%ebp),%edx
  107efb:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  107f00:	8b 45 0c             	mov    0xc(%ebp),%eax
  107f03:	83 c0 08             	add    $0x8,%eax
  107f06:	89 04 24             	mov    %eax,(%esp)
  107f09:	e8 97 88 ff ff       	call   1007a5 <cputs>
		b->idx = 0;
  107f0e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107f11:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  107f17:	8b 45 0c             	mov    0xc(%ebp),%eax
  107f1a:	8b 40 04             	mov    0x4(%eax),%eax
  107f1d:	8d 50 01             	lea    0x1(%eax),%edx
  107f20:	8b 45 0c             	mov    0xc(%ebp),%eax
  107f23:	89 50 04             	mov    %edx,0x4(%eax)
}
  107f26:	c9                   	leave  
  107f27:	c3                   	ret    

00107f28 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  107f28:	55                   	push   %ebp
  107f29:	89 e5                	mov    %esp,%ebp
  107f2b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  107f31:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  107f38:	00 00 00 
	b.cnt = 0;
  107f3b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  107f42:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  107f45:	b8 c8 7e 10 00       	mov    $0x107ec8,%eax
  107f4a:	8b 55 0c             	mov    0xc(%ebp),%edx
  107f4d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107f51:	8b 55 08             	mov    0x8(%ebp),%edx
  107f54:	89 54 24 08          	mov    %edx,0x8(%esp)
  107f58:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  107f5e:	89 54 24 04          	mov    %edx,0x4(%esp)
  107f62:	89 04 24             	mov    %eax,(%esp)
  107f65:	e8 c6 fb ff ff       	call   107b30 <vprintfmt>

	b.buf[b.idx] = 0;
  107f6a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  107f70:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  107f77:	00 
	cputs(b.buf);
  107f78:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  107f7e:	83 c0 08             	add    $0x8,%eax
  107f81:	89 04 24             	mov    %eax,(%esp)
  107f84:	e8 1c 88 ff ff       	call   1007a5 <cputs>

	return b.cnt;
  107f89:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  107f8f:	c9                   	leave  
  107f90:	c3                   	ret    

00107f91 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  107f91:	55                   	push   %ebp
  107f92:	89 e5                	mov    %esp,%ebp
  107f94:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  107f97:	8d 45 08             	lea    0x8(%ebp),%eax
  107f9a:	83 c0 04             	add    $0x4,%eax
  107f9d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  107fa0:	8b 45 08             	mov    0x8(%ebp),%eax
  107fa3:	8b 55 f0             	mov    -0x10(%ebp),%edx
  107fa6:	89 54 24 04          	mov    %edx,0x4(%esp)
  107faa:	89 04 24             	mov    %eax,(%esp)
  107fad:	e8 76 ff ff ff       	call   107f28 <vcprintf>
  107fb2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  107fb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  107fb8:	c9                   	leave  
  107fb9:	c3                   	ret    

00107fba <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  107fba:	55                   	push   %ebp
  107fbb:	89 e5                	mov    %esp,%ebp
  107fbd:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  107fc0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  107fc7:	eb 08                	jmp    107fd1 <strlen+0x17>
		n++;
  107fc9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  107fcd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107fd1:	8b 45 08             	mov    0x8(%ebp),%eax
  107fd4:	0f b6 00             	movzbl (%eax),%eax
  107fd7:	84 c0                	test   %al,%al
  107fd9:	75 ee                	jne    107fc9 <strlen+0xf>
		n++;
	return n;
  107fdb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  107fde:	c9                   	leave  
  107fdf:	c3                   	ret    

00107fe0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  107fe0:	55                   	push   %ebp
  107fe1:	89 e5                	mov    %esp,%ebp
  107fe3:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  107fe6:	8b 45 08             	mov    0x8(%ebp),%eax
  107fe9:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  107fec:	8b 45 0c             	mov    0xc(%ebp),%eax
  107fef:	0f b6 10             	movzbl (%eax),%edx
  107ff2:	8b 45 08             	mov    0x8(%ebp),%eax
  107ff5:	88 10                	mov    %dl,(%eax)
  107ff7:	8b 45 08             	mov    0x8(%ebp),%eax
  107ffa:	0f b6 00             	movzbl (%eax),%eax
  107ffd:	84 c0                	test   %al,%al
  107fff:	0f 95 c0             	setne  %al
  108002:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  108006:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10800a:	84 c0                	test   %al,%al
  10800c:	75 de                	jne    107fec <strcpy+0xc>
		/* do nothing */;
	return ret;
  10800e:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  108011:	c9                   	leave  
  108012:	c3                   	ret    

00108013 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  108013:	55                   	push   %ebp
  108014:	89 e5                	mov    %esp,%ebp
  108016:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  108019:	8b 45 08             	mov    0x8(%ebp),%eax
  10801c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  10801f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  108026:	eb 21                	jmp    108049 <strncpy+0x36>
		*dst++ = *src;
  108028:	8b 45 0c             	mov    0xc(%ebp),%eax
  10802b:	0f b6 10             	movzbl (%eax),%edx
  10802e:	8b 45 08             	mov    0x8(%ebp),%eax
  108031:	88 10                	mov    %dl,(%eax)
  108033:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  108037:	8b 45 0c             	mov    0xc(%ebp),%eax
  10803a:	0f b6 00             	movzbl (%eax),%eax
  10803d:	84 c0                	test   %al,%al
  10803f:	74 04                	je     108045 <strncpy+0x32>
			src++;
  108041:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  108045:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  108049:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10804c:	3b 45 10             	cmp    0x10(%ebp),%eax
  10804f:	72 d7                	jb     108028 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  108051:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  108054:	c9                   	leave  
  108055:	c3                   	ret    

00108056 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  108056:	55                   	push   %ebp
  108057:	89 e5                	mov    %esp,%ebp
  108059:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  10805c:	8b 45 08             	mov    0x8(%ebp),%eax
  10805f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  108062:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  108066:	74 2f                	je     108097 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  108068:	eb 13                	jmp    10807d <strlcpy+0x27>
			*dst++ = *src++;
  10806a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10806d:	0f b6 10             	movzbl (%eax),%edx
  108070:	8b 45 08             	mov    0x8(%ebp),%eax
  108073:	88 10                	mov    %dl,(%eax)
  108075:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  108079:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  10807d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  108081:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  108085:	74 0a                	je     108091 <strlcpy+0x3b>
  108087:	8b 45 0c             	mov    0xc(%ebp),%eax
  10808a:	0f b6 00             	movzbl (%eax),%eax
  10808d:	84 c0                	test   %al,%al
  10808f:	75 d9                	jne    10806a <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  108091:	8b 45 08             	mov    0x8(%ebp),%eax
  108094:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  108097:	8b 55 08             	mov    0x8(%ebp),%edx
  10809a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10809d:	89 d1                	mov    %edx,%ecx
  10809f:	29 c1                	sub    %eax,%ecx
  1080a1:	89 c8                	mov    %ecx,%eax
}
  1080a3:	c9                   	leave  
  1080a4:	c3                   	ret    

001080a5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  1080a5:	55                   	push   %ebp
  1080a6:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  1080a8:	eb 08                	jmp    1080b2 <strcmp+0xd>
		p++, q++;
  1080aa:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1080ae:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  1080b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1080b5:	0f b6 00             	movzbl (%eax),%eax
  1080b8:	84 c0                	test   %al,%al
  1080ba:	74 10                	je     1080cc <strcmp+0x27>
  1080bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1080bf:	0f b6 10             	movzbl (%eax),%edx
  1080c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1080c5:	0f b6 00             	movzbl (%eax),%eax
  1080c8:	38 c2                	cmp    %al,%dl
  1080ca:	74 de                	je     1080aa <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  1080cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1080cf:	0f b6 00             	movzbl (%eax),%eax
  1080d2:	0f b6 d0             	movzbl %al,%edx
  1080d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1080d8:	0f b6 00             	movzbl (%eax),%eax
  1080db:	0f b6 c0             	movzbl %al,%eax
  1080de:	89 d1                	mov    %edx,%ecx
  1080e0:	29 c1                	sub    %eax,%ecx
  1080e2:	89 c8                	mov    %ecx,%eax
}
  1080e4:	5d                   	pop    %ebp
  1080e5:	c3                   	ret    

001080e6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  1080e6:	55                   	push   %ebp
  1080e7:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  1080e9:	eb 0c                	jmp    1080f7 <strncmp+0x11>
		n--, p++, q++;
  1080eb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1080ef:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1080f3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  1080f7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1080fb:	74 1a                	je     108117 <strncmp+0x31>
  1080fd:	8b 45 08             	mov    0x8(%ebp),%eax
  108100:	0f b6 00             	movzbl (%eax),%eax
  108103:	84 c0                	test   %al,%al
  108105:	74 10                	je     108117 <strncmp+0x31>
  108107:	8b 45 08             	mov    0x8(%ebp),%eax
  10810a:	0f b6 10             	movzbl (%eax),%edx
  10810d:	8b 45 0c             	mov    0xc(%ebp),%eax
  108110:	0f b6 00             	movzbl (%eax),%eax
  108113:	38 c2                	cmp    %al,%dl
  108115:	74 d4                	je     1080eb <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  108117:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10811b:	75 07                	jne    108124 <strncmp+0x3e>
		return 0;
  10811d:	b8 00 00 00 00       	mov    $0x0,%eax
  108122:	eb 18                	jmp    10813c <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  108124:	8b 45 08             	mov    0x8(%ebp),%eax
  108127:	0f b6 00             	movzbl (%eax),%eax
  10812a:	0f b6 d0             	movzbl %al,%edx
  10812d:	8b 45 0c             	mov    0xc(%ebp),%eax
  108130:	0f b6 00             	movzbl (%eax),%eax
  108133:	0f b6 c0             	movzbl %al,%eax
  108136:	89 d1                	mov    %edx,%ecx
  108138:	29 c1                	sub    %eax,%ecx
  10813a:	89 c8                	mov    %ecx,%eax
}
  10813c:	5d                   	pop    %ebp
  10813d:	c3                   	ret    

0010813e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  10813e:	55                   	push   %ebp
  10813f:	89 e5                	mov    %esp,%ebp
  108141:	83 ec 04             	sub    $0x4,%esp
  108144:	8b 45 0c             	mov    0xc(%ebp),%eax
  108147:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  10814a:	eb 1a                	jmp    108166 <strchr+0x28>
		if (*s++ == 0)
  10814c:	8b 45 08             	mov    0x8(%ebp),%eax
  10814f:	0f b6 00             	movzbl (%eax),%eax
  108152:	84 c0                	test   %al,%al
  108154:	0f 94 c0             	sete   %al
  108157:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10815b:	84 c0                	test   %al,%al
  10815d:	74 07                	je     108166 <strchr+0x28>
			return NULL;
  10815f:	b8 00 00 00 00       	mov    $0x0,%eax
  108164:	eb 0e                	jmp    108174 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  108166:	8b 45 08             	mov    0x8(%ebp),%eax
  108169:	0f b6 00             	movzbl (%eax),%eax
  10816c:	3a 45 fc             	cmp    -0x4(%ebp),%al
  10816f:	75 db                	jne    10814c <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  108171:	8b 45 08             	mov    0x8(%ebp),%eax
}
  108174:	c9                   	leave  
  108175:	c3                   	ret    

00108176 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  108176:	55                   	push   %ebp
  108177:	89 e5                	mov    %esp,%ebp
  108179:	57                   	push   %edi
  10817a:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  10817d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  108181:	75 05                	jne    108188 <memset+0x12>
		return v;
  108183:	8b 45 08             	mov    0x8(%ebp),%eax
  108186:	eb 5c                	jmp    1081e4 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  108188:	8b 45 08             	mov    0x8(%ebp),%eax
  10818b:	83 e0 03             	and    $0x3,%eax
  10818e:	85 c0                	test   %eax,%eax
  108190:	75 41                	jne    1081d3 <memset+0x5d>
  108192:	8b 45 10             	mov    0x10(%ebp),%eax
  108195:	83 e0 03             	and    $0x3,%eax
  108198:	85 c0                	test   %eax,%eax
  10819a:	75 37                	jne    1081d3 <memset+0x5d>
		c &= 0xFF;
  10819c:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  1081a3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081a6:	89 c2                	mov    %eax,%edx
  1081a8:	c1 e2 18             	shl    $0x18,%edx
  1081ab:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081ae:	c1 e0 10             	shl    $0x10,%eax
  1081b1:	09 c2                	or     %eax,%edx
  1081b3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081b6:	c1 e0 08             	shl    $0x8,%eax
  1081b9:	09 d0                	or     %edx,%eax
  1081bb:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  1081be:	8b 45 10             	mov    0x10(%ebp),%eax
  1081c1:	89 c1                	mov    %eax,%ecx
  1081c3:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  1081c6:	8b 55 08             	mov    0x8(%ebp),%edx
  1081c9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081cc:	89 d7                	mov    %edx,%edi
  1081ce:	fc                   	cld    
  1081cf:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  1081d1:	eb 0e                	jmp    1081e1 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  1081d3:	8b 55 08             	mov    0x8(%ebp),%edx
  1081d6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081d9:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1081dc:	89 d7                	mov    %edx,%edi
  1081de:	fc                   	cld    
  1081df:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  1081e1:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1081e4:	83 c4 10             	add    $0x10,%esp
  1081e7:	5f                   	pop    %edi
  1081e8:	5d                   	pop    %ebp
  1081e9:	c3                   	ret    

001081ea <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  1081ea:	55                   	push   %ebp
  1081eb:	89 e5                	mov    %esp,%ebp
  1081ed:	57                   	push   %edi
  1081ee:	56                   	push   %esi
  1081ef:	53                   	push   %ebx
  1081f0:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  1081f3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081f6:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  1081f9:	8b 45 08             	mov    0x8(%ebp),%eax
  1081fc:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  1081ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
  108202:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  108205:	73 6e                	jae    108275 <memmove+0x8b>
  108207:	8b 45 10             	mov    0x10(%ebp),%eax
  10820a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10820d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  108210:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  108213:	76 60                	jbe    108275 <memmove+0x8b>
		s += n;
  108215:	8b 45 10             	mov    0x10(%ebp),%eax
  108218:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  10821b:	8b 45 10             	mov    0x10(%ebp),%eax
  10821e:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  108221:	8b 45 ec             	mov    -0x14(%ebp),%eax
  108224:	83 e0 03             	and    $0x3,%eax
  108227:	85 c0                	test   %eax,%eax
  108229:	75 2f                	jne    10825a <memmove+0x70>
  10822b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10822e:	83 e0 03             	and    $0x3,%eax
  108231:	85 c0                	test   %eax,%eax
  108233:	75 25                	jne    10825a <memmove+0x70>
  108235:	8b 45 10             	mov    0x10(%ebp),%eax
  108238:	83 e0 03             	and    $0x3,%eax
  10823b:	85 c0                	test   %eax,%eax
  10823d:	75 1b                	jne    10825a <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  10823f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  108242:	83 e8 04             	sub    $0x4,%eax
  108245:	8b 55 ec             	mov    -0x14(%ebp),%edx
  108248:	83 ea 04             	sub    $0x4,%edx
  10824b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10824e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  108251:	89 c7                	mov    %eax,%edi
  108253:	89 d6                	mov    %edx,%esi
  108255:	fd                   	std    
  108256:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  108258:	eb 18                	jmp    108272 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  10825a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10825d:	8d 50 ff             	lea    -0x1(%eax),%edx
  108260:	8b 45 ec             	mov    -0x14(%ebp),%eax
  108263:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  108266:	8b 45 10             	mov    0x10(%ebp),%eax
  108269:	89 d7                	mov    %edx,%edi
  10826b:	89 de                	mov    %ebx,%esi
  10826d:	89 c1                	mov    %eax,%ecx
  10826f:	fd                   	std    
  108270:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  108272:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  108273:	eb 45                	jmp    1082ba <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  108275:	8b 45 ec             	mov    -0x14(%ebp),%eax
  108278:	83 e0 03             	and    $0x3,%eax
  10827b:	85 c0                	test   %eax,%eax
  10827d:	75 2b                	jne    1082aa <memmove+0xc0>
  10827f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  108282:	83 e0 03             	and    $0x3,%eax
  108285:	85 c0                	test   %eax,%eax
  108287:	75 21                	jne    1082aa <memmove+0xc0>
  108289:	8b 45 10             	mov    0x10(%ebp),%eax
  10828c:	83 e0 03             	and    $0x3,%eax
  10828f:	85 c0                	test   %eax,%eax
  108291:	75 17                	jne    1082aa <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  108293:	8b 45 10             	mov    0x10(%ebp),%eax
  108296:	89 c1                	mov    %eax,%ecx
  108298:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  10829b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10829e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1082a1:	89 c7                	mov    %eax,%edi
  1082a3:	89 d6                	mov    %edx,%esi
  1082a5:	fc                   	cld    
  1082a6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1082a8:	eb 10                	jmp    1082ba <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  1082aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1082ad:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1082b0:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1082b3:	89 c7                	mov    %eax,%edi
  1082b5:	89 d6                	mov    %edx,%esi
  1082b7:	fc                   	cld    
  1082b8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  1082ba:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1082bd:	83 c4 10             	add    $0x10,%esp
  1082c0:	5b                   	pop    %ebx
  1082c1:	5e                   	pop    %esi
  1082c2:	5f                   	pop    %edi
  1082c3:	5d                   	pop    %ebp
  1082c4:	c3                   	ret    

001082c5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  1082c5:	55                   	push   %ebp
  1082c6:	89 e5                	mov    %esp,%ebp
  1082c8:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  1082cb:	8b 45 10             	mov    0x10(%ebp),%eax
  1082ce:	89 44 24 08          	mov    %eax,0x8(%esp)
  1082d2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1082d5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1082d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1082dc:	89 04 24             	mov    %eax,(%esp)
  1082df:	e8 06 ff ff ff       	call   1081ea <memmove>
}
  1082e4:	c9                   	leave  
  1082e5:	c3                   	ret    

001082e6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  1082e6:	55                   	push   %ebp
  1082e7:	89 e5                	mov    %esp,%ebp
  1082e9:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  1082ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1082ef:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  1082f2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1082f5:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  1082f8:	eb 32                	jmp    10832c <memcmp+0x46>
		if (*s1 != *s2)
  1082fa:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1082fd:	0f b6 10             	movzbl (%eax),%edx
  108300:	8b 45 fc             	mov    -0x4(%ebp),%eax
  108303:	0f b6 00             	movzbl (%eax),%eax
  108306:	38 c2                	cmp    %al,%dl
  108308:	74 1a                	je     108324 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  10830a:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10830d:	0f b6 00             	movzbl (%eax),%eax
  108310:	0f b6 d0             	movzbl %al,%edx
  108313:	8b 45 fc             	mov    -0x4(%ebp),%eax
  108316:	0f b6 00             	movzbl (%eax),%eax
  108319:	0f b6 c0             	movzbl %al,%eax
  10831c:	89 d1                	mov    %edx,%ecx
  10831e:	29 c1                	sub    %eax,%ecx
  108320:	89 c8                	mov    %ecx,%eax
  108322:	eb 1c                	jmp    108340 <memcmp+0x5a>
		s1++, s2++;
  108324:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  108328:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  10832c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  108330:	0f 95 c0             	setne  %al
  108333:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  108337:	84 c0                	test   %al,%al
  108339:	75 bf                	jne    1082fa <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  10833b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  108340:	c9                   	leave  
  108341:	c3                   	ret    

00108342 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  108342:	55                   	push   %ebp
  108343:	89 e5                	mov    %esp,%ebp
  108345:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  108348:	8b 45 10             	mov    0x10(%ebp),%eax
  10834b:	8b 55 08             	mov    0x8(%ebp),%edx
  10834e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  108351:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  108354:	eb 16                	jmp    10836c <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  108356:	8b 45 08             	mov    0x8(%ebp),%eax
  108359:	0f b6 10             	movzbl (%eax),%edx
  10835c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10835f:	38 c2                	cmp    %al,%dl
  108361:	75 05                	jne    108368 <memchr+0x26>
			return (void *) s;
  108363:	8b 45 08             	mov    0x8(%ebp),%eax
  108366:	eb 11                	jmp    108379 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  108368:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10836c:	8b 45 08             	mov    0x8(%ebp),%eax
  10836f:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  108372:	72 e2                	jb     108356 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  108374:	b8 00 00 00 00       	mov    $0x0,%eax
}
  108379:	c9                   	leave  
  10837a:	c3                   	ret    
  10837b:	66 90                	xchg   %ax,%ax
  10837d:	66 90                	xchg   %ax,%ax
  10837f:	90                   	nop

00108380 <__udivdi3>:
  108380:	55                   	push   %ebp
  108381:	89 e5                	mov    %esp,%ebp
  108383:	57                   	push   %edi
  108384:	56                   	push   %esi
  108385:	83 ec 10             	sub    $0x10,%esp
  108388:	8b 45 14             	mov    0x14(%ebp),%eax
  10838b:	8b 55 08             	mov    0x8(%ebp),%edx
  10838e:	8b 75 10             	mov    0x10(%ebp),%esi
  108391:	8b 7d 0c             	mov    0xc(%ebp),%edi
  108394:	85 c0                	test   %eax,%eax
  108396:	89 55 f0             	mov    %edx,-0x10(%ebp)
  108399:	75 35                	jne    1083d0 <__udivdi3+0x50>
  10839b:	39 fe                	cmp    %edi,%esi
  10839d:	77 61                	ja     108400 <__udivdi3+0x80>
  10839f:	85 f6                	test   %esi,%esi
  1083a1:	75 0b                	jne    1083ae <__udivdi3+0x2e>
  1083a3:	b8 01 00 00 00       	mov    $0x1,%eax
  1083a8:	31 d2                	xor    %edx,%edx
  1083aa:	f7 f6                	div    %esi
  1083ac:	89 c6                	mov    %eax,%esi
  1083ae:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1083b1:	31 d2                	xor    %edx,%edx
  1083b3:	89 f8                	mov    %edi,%eax
  1083b5:	f7 f6                	div    %esi
  1083b7:	89 c7                	mov    %eax,%edi
  1083b9:	89 c8                	mov    %ecx,%eax
  1083bb:	f7 f6                	div    %esi
  1083bd:	89 c1                	mov    %eax,%ecx
  1083bf:	89 fa                	mov    %edi,%edx
  1083c1:	89 c8                	mov    %ecx,%eax
  1083c3:	83 c4 10             	add    $0x10,%esp
  1083c6:	5e                   	pop    %esi
  1083c7:	5f                   	pop    %edi
  1083c8:	5d                   	pop    %ebp
  1083c9:	c3                   	ret    
  1083ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1083d0:	39 f8                	cmp    %edi,%eax
  1083d2:	77 1c                	ja     1083f0 <__udivdi3+0x70>
  1083d4:	0f bd d0             	bsr    %eax,%edx
  1083d7:	83 f2 1f             	xor    $0x1f,%edx
  1083da:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1083dd:	75 39                	jne    108418 <__udivdi3+0x98>
  1083df:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  1083e2:	0f 86 a0 00 00 00    	jbe    108488 <__udivdi3+0x108>
  1083e8:	39 f8                	cmp    %edi,%eax
  1083ea:	0f 82 98 00 00 00    	jb     108488 <__udivdi3+0x108>
  1083f0:	31 ff                	xor    %edi,%edi
  1083f2:	31 c9                	xor    %ecx,%ecx
  1083f4:	89 c8                	mov    %ecx,%eax
  1083f6:	89 fa                	mov    %edi,%edx
  1083f8:	83 c4 10             	add    $0x10,%esp
  1083fb:	5e                   	pop    %esi
  1083fc:	5f                   	pop    %edi
  1083fd:	5d                   	pop    %ebp
  1083fe:	c3                   	ret    
  1083ff:	90                   	nop
  108400:	89 d1                	mov    %edx,%ecx
  108402:	89 fa                	mov    %edi,%edx
  108404:	89 c8                	mov    %ecx,%eax
  108406:	31 ff                	xor    %edi,%edi
  108408:	f7 f6                	div    %esi
  10840a:	89 c1                	mov    %eax,%ecx
  10840c:	89 fa                	mov    %edi,%edx
  10840e:	89 c8                	mov    %ecx,%eax
  108410:	83 c4 10             	add    $0x10,%esp
  108413:	5e                   	pop    %esi
  108414:	5f                   	pop    %edi
  108415:	5d                   	pop    %ebp
  108416:	c3                   	ret    
  108417:	90                   	nop
  108418:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10841c:	89 f2                	mov    %esi,%edx
  10841e:	d3 e0                	shl    %cl,%eax
  108420:	89 45 ec             	mov    %eax,-0x14(%ebp)
  108423:	b8 20 00 00 00       	mov    $0x20,%eax
  108428:	2b 45 f4             	sub    -0xc(%ebp),%eax
  10842b:	89 c1                	mov    %eax,%ecx
  10842d:	d3 ea                	shr    %cl,%edx
  10842f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  108433:	0b 55 ec             	or     -0x14(%ebp),%edx
  108436:	d3 e6                	shl    %cl,%esi
  108438:	89 c1                	mov    %eax,%ecx
  10843a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  10843d:	89 fe                	mov    %edi,%esi
  10843f:	d3 ee                	shr    %cl,%esi
  108441:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  108445:	89 55 ec             	mov    %edx,-0x14(%ebp)
  108448:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10844b:	d3 e7                	shl    %cl,%edi
  10844d:	89 c1                	mov    %eax,%ecx
  10844f:	d3 ea                	shr    %cl,%edx
  108451:	09 d7                	or     %edx,%edi
  108453:	89 f2                	mov    %esi,%edx
  108455:	89 f8                	mov    %edi,%eax
  108457:	f7 75 ec             	divl   -0x14(%ebp)
  10845a:	89 d6                	mov    %edx,%esi
  10845c:	89 c7                	mov    %eax,%edi
  10845e:	f7 65 e8             	mull   -0x18(%ebp)
  108461:	39 d6                	cmp    %edx,%esi
  108463:	89 55 ec             	mov    %edx,-0x14(%ebp)
  108466:	72 30                	jb     108498 <__udivdi3+0x118>
  108468:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10846b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10846f:	d3 e2                	shl    %cl,%edx
  108471:	39 c2                	cmp    %eax,%edx
  108473:	73 05                	jae    10847a <__udivdi3+0xfa>
  108475:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  108478:	74 1e                	je     108498 <__udivdi3+0x118>
  10847a:	89 f9                	mov    %edi,%ecx
  10847c:	31 ff                	xor    %edi,%edi
  10847e:	e9 71 ff ff ff       	jmp    1083f4 <__udivdi3+0x74>
  108483:	90                   	nop
  108484:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108488:	31 ff                	xor    %edi,%edi
  10848a:	b9 01 00 00 00       	mov    $0x1,%ecx
  10848f:	e9 60 ff ff ff       	jmp    1083f4 <__udivdi3+0x74>
  108494:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108498:	8d 4f ff             	lea    -0x1(%edi),%ecx
  10849b:	31 ff                	xor    %edi,%edi
  10849d:	89 c8                	mov    %ecx,%eax
  10849f:	89 fa                	mov    %edi,%edx
  1084a1:	83 c4 10             	add    $0x10,%esp
  1084a4:	5e                   	pop    %esi
  1084a5:	5f                   	pop    %edi
  1084a6:	5d                   	pop    %ebp
  1084a7:	c3                   	ret    
  1084a8:	66 90                	xchg   %ax,%ax
  1084aa:	66 90                	xchg   %ax,%ax
  1084ac:	66 90                	xchg   %ax,%ax
  1084ae:	66 90                	xchg   %ax,%ax

001084b0 <__umoddi3>:
  1084b0:	55                   	push   %ebp
  1084b1:	89 e5                	mov    %esp,%ebp
  1084b3:	57                   	push   %edi
  1084b4:	56                   	push   %esi
  1084b5:	83 ec 20             	sub    $0x20,%esp
  1084b8:	8b 55 14             	mov    0x14(%ebp),%edx
  1084bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1084be:	8b 7d 10             	mov    0x10(%ebp),%edi
  1084c1:	8b 75 0c             	mov    0xc(%ebp),%esi
  1084c4:	85 d2                	test   %edx,%edx
  1084c6:	89 c8                	mov    %ecx,%eax
  1084c8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  1084cb:	75 13                	jne    1084e0 <__umoddi3+0x30>
  1084cd:	39 f7                	cmp    %esi,%edi
  1084cf:	76 3f                	jbe    108510 <__umoddi3+0x60>
  1084d1:	89 f2                	mov    %esi,%edx
  1084d3:	f7 f7                	div    %edi
  1084d5:	89 d0                	mov    %edx,%eax
  1084d7:	31 d2                	xor    %edx,%edx
  1084d9:	83 c4 20             	add    $0x20,%esp
  1084dc:	5e                   	pop    %esi
  1084dd:	5f                   	pop    %edi
  1084de:	5d                   	pop    %ebp
  1084df:	c3                   	ret    
  1084e0:	39 f2                	cmp    %esi,%edx
  1084e2:	77 4c                	ja     108530 <__umoddi3+0x80>
  1084e4:	0f bd ca             	bsr    %edx,%ecx
  1084e7:	83 f1 1f             	xor    $0x1f,%ecx
  1084ea:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  1084ed:	75 51                	jne    108540 <__umoddi3+0x90>
  1084ef:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  1084f2:	0f 87 e0 00 00 00    	ja     1085d8 <__umoddi3+0x128>
  1084f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1084fb:	29 f8                	sub    %edi,%eax
  1084fd:	19 d6                	sbb    %edx,%esi
  1084ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
  108502:	8b 45 f4             	mov    -0xc(%ebp),%eax
  108505:	89 f2                	mov    %esi,%edx
  108507:	83 c4 20             	add    $0x20,%esp
  10850a:	5e                   	pop    %esi
  10850b:	5f                   	pop    %edi
  10850c:	5d                   	pop    %ebp
  10850d:	c3                   	ret    
  10850e:	66 90                	xchg   %ax,%ax
  108510:	85 ff                	test   %edi,%edi
  108512:	75 0b                	jne    10851f <__umoddi3+0x6f>
  108514:	b8 01 00 00 00       	mov    $0x1,%eax
  108519:	31 d2                	xor    %edx,%edx
  10851b:	f7 f7                	div    %edi
  10851d:	89 c7                	mov    %eax,%edi
  10851f:	89 f0                	mov    %esi,%eax
  108521:	31 d2                	xor    %edx,%edx
  108523:	f7 f7                	div    %edi
  108525:	8b 45 f4             	mov    -0xc(%ebp),%eax
  108528:	f7 f7                	div    %edi
  10852a:	eb a9                	jmp    1084d5 <__umoddi3+0x25>
  10852c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108530:	89 c8                	mov    %ecx,%eax
  108532:	89 f2                	mov    %esi,%edx
  108534:	83 c4 20             	add    $0x20,%esp
  108537:	5e                   	pop    %esi
  108538:	5f                   	pop    %edi
  108539:	5d                   	pop    %ebp
  10853a:	c3                   	ret    
  10853b:	90                   	nop
  10853c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108540:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108544:	d3 e2                	shl    %cl,%edx
  108546:	89 55 f4             	mov    %edx,-0xc(%ebp)
  108549:	ba 20 00 00 00       	mov    $0x20,%edx
  10854e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  108551:	89 55 ec             	mov    %edx,-0x14(%ebp)
  108554:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108558:	89 fa                	mov    %edi,%edx
  10855a:	d3 ea                	shr    %cl,%edx
  10855c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108560:	0b 55 f4             	or     -0xc(%ebp),%edx
  108563:	d3 e7                	shl    %cl,%edi
  108565:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108569:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10856c:	89 f2                	mov    %esi,%edx
  10856e:	89 7d e8             	mov    %edi,-0x18(%ebp)
  108571:	89 c7                	mov    %eax,%edi
  108573:	d3 ea                	shr    %cl,%edx
  108575:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108579:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10857c:	89 c2                	mov    %eax,%edx
  10857e:	d3 e6                	shl    %cl,%esi
  108580:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108584:	d3 ea                	shr    %cl,%edx
  108586:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10858a:	09 d6                	or     %edx,%esi
  10858c:	89 f0                	mov    %esi,%eax
  10858e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  108591:	d3 e7                	shl    %cl,%edi
  108593:	89 f2                	mov    %esi,%edx
  108595:	f7 75 f4             	divl   -0xc(%ebp)
  108598:	89 d6                	mov    %edx,%esi
  10859a:	f7 65 e8             	mull   -0x18(%ebp)
  10859d:	39 d6                	cmp    %edx,%esi
  10859f:	72 2b                	jb     1085cc <__umoddi3+0x11c>
  1085a1:	39 c7                	cmp    %eax,%edi
  1085a3:	72 23                	jb     1085c8 <__umoddi3+0x118>
  1085a5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1085a9:	29 c7                	sub    %eax,%edi
  1085ab:	19 d6                	sbb    %edx,%esi
  1085ad:	89 f0                	mov    %esi,%eax
  1085af:	89 f2                	mov    %esi,%edx
  1085b1:	d3 ef                	shr    %cl,%edi
  1085b3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1085b7:	d3 e0                	shl    %cl,%eax
  1085b9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1085bd:	09 f8                	or     %edi,%eax
  1085bf:	d3 ea                	shr    %cl,%edx
  1085c1:	83 c4 20             	add    $0x20,%esp
  1085c4:	5e                   	pop    %esi
  1085c5:	5f                   	pop    %edi
  1085c6:	5d                   	pop    %ebp
  1085c7:	c3                   	ret    
  1085c8:	39 d6                	cmp    %edx,%esi
  1085ca:	75 d9                	jne    1085a5 <__umoddi3+0xf5>
  1085cc:	2b 45 e8             	sub    -0x18(%ebp),%eax
  1085cf:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  1085d2:	eb d1                	jmp    1085a5 <__umoddi3+0xf5>
  1085d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1085d8:	39 f2                	cmp    %esi,%edx
  1085da:	0f 82 18 ff ff ff    	jb     1084f8 <__umoddi3+0x48>
  1085e0:	e9 1d ff ff ff       	jmp    108502 <__umoddi3+0x52>
